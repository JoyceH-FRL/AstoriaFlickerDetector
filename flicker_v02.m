clear all
close all


data_n = 0;
baseline_n = 20;
imgX = 512;
imgY = 512;

image_folder = input("test image folder:\n", 's');
data_type = input("test image data type, default is '*.raw' :\n", 's');%"*.dat";
module_ID = input("module ID:\n", 's');
%imgX = input("image width, default is 512:\n");
%imgY = input("imagr height without OB, default is 512:\n");
input_source = input("Meta raw data(1) or Sunny raw data(2):\n");

if strlength(image_folder) ==0
    disp("run default data set");
    image_folder = path();%"C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR\input";
    data_type = "*.raw";
    module_ID = "P8K209_W22X28Y4";
    imgX = 512;
    imgY = 512;
    baseline_n = 20;
end

test_files = dir(fullfile(image_folder, data_type));
n_test_files = size(test_files);
data_n = n_test_files(1);
total_fd = zeros(data_n, 7+imgY);



for i = 1 : data_n
    if input_source == 1
        img_array = MetaRAWconvert(image_folder, test_files(i).name, test_files(i).bytes, imgX, imgY, 1);
    elseif input_source == 2
        img_array = SunnyRAWconverter(image_folder, test_files(i).name, imgX, imgY+32);
    end
    [PD_img, FD_img, TTS_img] = AstoriaHDRframe(img_array, imgX, imgY);
    [fd_frame_statistic, fd_row_profile_statistic, fd_col_profile_statistic, fd_row_profile, fd_col_profile]=ImageStatistic(FD_img, imgX, imgY);
    total_fd(i, 3:7) = fd_row_profile_statistic;
    total_fd(i, 8:end) = fd_row_profile;    
end
[baseine_log, good_ref, baseline_fs, baseline_fs_1, good_n, total_fd] = baselineSet(total_fd, baseline_n, data_n, imgY);
[unit_fs, unit_rowTemp_fs, out_result_rtemp, out_result_rtotal, total_std_diff, total_fd, flickerRatio, avg_unit_fs]  = FlickerStrength(total_fd, good_ref, baseline_fs, baseline_fs_1, data_n, imgY);

fid  = fopen(fullfile(image_folder, strcat(module_ID, "_flickerTestingLog.txt")), "w+");
fprintf(fid, "%s flicker testing log\n", module_ID);
fprintf(fid, "===============================================\n");
fprintf(fid, "row temp noise of diff frame\n");
fprintf(fid, "unit flicker strength\tbaseline threshold\tResult\n");
if unit_rowTemp_fs > baseline_fs_1
    result = "fail";
else
    result = "pass";
end
fprintf(fid, "%f\t%f\t%s\n",  unit_rowTemp_fs, baseline_fs_1, result); 
fprintf(fid, "===============================================\n");

fprintf(fid, "row total noise of diff frame\n");
fprintf(fid, "unit max flicker strength\taverage flicker strength\tbaseline threshold\tflicker in 100 frames number\n");
fprintf(fid, "%f\t%f\t%f\t%f\n", unit_fs, avg_unit_fs, baseline_fs, flickerRatio);
fprintf(fid, "===============================================\n");
fprintf(fid, "frame type 0: good frame, 1 : flicker frame, 4: baseline frame\n");
fprintf(fid, "#frame\ttype\trow total noise of each diff frame\trow peak of diff frame\n");
for i = 1: data_n
    fprintf(fid, "%d\t%d\t%f\t%f\n", i, total_fd(i, 2), total_std_diff(i, 3), total_std_diff(i, 4).*total_std_diff(i, 5));
end
fclose(fid);
final_info = sprintf("%s flicker test %s\n%s complete", module_ID, result, fullfile(image_folder, strcat(module_ID, "_flickerTestingLog.txt")));
disp(final_info);



%path = "C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR";
%filename = "flickerStrengthTag_std.png";
%debugPlot(out_result_rtemp, out_result_rtotal, good_n, total_std_diff, total_fd, path, filename, baseline_n, data_n);







function [baseine_log, good_ref, baseline_fs, baseline_rowTemp_fs, good_n, total_fd] = baselineSet(total_fd, baseline_n, data_n, imgY)
    good_n = zeros(baseline_n, 1);
    good_n = good_n -1;
    j = 1;
    good_ref = zeros(1, imgY);
    start = 1;
    baseline_flage = 1;
    i = start+1;
    start_g = 0;
    baseline_fs = 0;
    while baseline_flage
        while i < data_n && good_n(baseline_n) < 0
            temp_diff_rp = total_fd(i, 8:end) - total_fd(start, 8:end);
            k = std(temp_diff_rp);
            p = abs(mean(temp_diff_rp));
            if k < 0.25 && p < 0.5 && k > 0 && p > 0
                start_g =1;
                good_n(j) = i;
                good_ref = good_ref + total_fd(good_n(j), 8:end);
                j = j+1;
                if j == baseline_n+1
                    i = data_n;
                end
            elseif p > 0.5 && start_g == 0
                start = start+1;
                i = data_n;
            end
            i = i+1;
        end
        i = start+1;
        good_ref = good_ref/baseline_n;
        %frame baseline threshold 
        baseline_rowTotal = zeros(baseline_n+1, 3);
        for t = 1: baseline_n
            temp = total_fd(good_n(t), 8:end) - good_ref;
            baseline_rowTotal(t, 1) = std(temp);
            baseline_rowTotal(t, 2) = abs(mean(temp));
            baseline_rowTotal(t, 3) = baseline_rowTotal(t, 2) + 3*baseline_rowTotal(t, 1);
            total_fd(good_n(t), 2) = 4;
        end
        baseline_rowTotal(baseline_n+1, 1) = std(total_fd(start, 8:end) - good_ref);
        baseline_rowTotal(baseline_n+1, 2) = mean(total_fd(start, 8:end) - good_ref); 
        baseline_rowTotal(baseline_n+1, 3) = baseline_rowTotal(baseline_n+1, 2) + 3* baseline_rowTotal(baseline_n+1, 1);
        %std of std
        k = std(baseline_rowTotal(:, 1));
        %mean of std
        p = mean(baseline_rowTotal(:, 1));
        if k < 0.25 && p < 0.5
            baseline_flage = 0;
            baseline_fs = max(abs(baseline_rowTotal(:, 3)));
            baseine_log = sprintf("baseline frame (row total noise) threshold: %f, from %d good frames\nmean of std of diff frame %f \nstd of std of diff frame %f", baseline_fs, baseline_n, p, k);
            %disp(baseine_log);
        end
        %unit baseline_rowTemp_fs
        baseline_rowTemp = zeros(512, 1);
        for m = 1: imgY
            temp = zeros(baseline_n,1);
            for t = 1: baseline_n
                temp(t) = total_fd(good_n(t), m+7) - good_ref(m);
            end
            baseline_rowTemp(m) = std(temp);
        end
        baseline_rowTemp_fs = mean(baseline_rowTemp)+3*std(baseline_rowTemp);
        baseine_log = sprintf("baseline unit (row temp noise) threshold: %f, from %d good frames\nmean of std of diff row profile %f \nstd of std of diff row profile %f", baseline_rowTemp_fs, baseline_n, mean(baseline_rowTemp), std(baseline_rowTemp));
        %disp(baseine_log);
    end
end
%flicker dtrength
function [unit_fs, unit_rowTemp_fs, out_result_rtemp, out_result_rtotal, total_std_diff, total_fd, flickerRatio, avg_unit_fs] = FlickerStrength(total_fd, good_ref, baseline_fs, baseline_rowTemp_fs, data_n, imgY)
    %total dat set statistic of row profile pre diff frame
    % 1: std of row profile pre diff frame
    % 2: mean of row profile pre diff frame
    % 3: flicker strength of row profile pre diff frame
    % 4: peak value of row profile pre diff frame
    % 5: peak value direction (+/-)
    % unit : whole dats set (ie. 300 frames)
    % 
    total_std_diff = zeros(data_n, 5);
    n_flicker = 0;

    for i = 1: data_n
         %row profil 1x512
         temp_diff_rp = total_fd(i, 8:end)-good_ref;
         %std of row profile pre diff frame
         k = std(temp_diff_rp);
         %mean of row profile pre diff frame
         p = mean(temp_diff_rp);
         total_std_diff(i, 1) = k;
         total_std_diff(i, 2) = abs(p); 
         total_std_diff(i, 3) = p+3*k;
         if total_std_diff(i, 3) > baseline_fs
             total_fd(i, 2) = 1;
             n_flicker = n_flicker+1;
         end
         total_std_diff(i, 4) = max(max(temp_diff_rp), abs(min(temp_diff_rp)));
         if abs(min(temp_diff_rp)) >  max(temp_diff_rp)
             total_std_diff(i, 5) = -1;
         else
             total_std_diff(i, 5) = 1;
         end    
    end
    %total row noise
    % std of std of row profile pre diff frame
    unit_std = std(total_std_diff(:, 1));
    % mean of std of row profile pre diff frame
    unit_mean = mean(total_std_diff(:, 1));
    unit_fs = max(total_std_diff(:, 3));%unit_mean+3*unit_std;
    
    result_rtotal = "";
    if unit_fs > baseline_fs
        result_rtotal = "fail";
    else
        result_rtotal = "pass";
    end
    flickerRatio = 100*(n_flicker/data_n);
    avg_unit_fs = mean(total_std_diff(:, 3));
    s0 = sprintf("row total noise of diff frame\n");
    s1 = sprintf("this unit max flicker strength is %f, threshold is %f\nflicker testing %s, flicker ratio: %f", unit_fs, baseline_fs, result_rtotal, flickerRatio);
    s2 = '%';
    s3 = sprintf(",average flicker strength: %f", avg_unit_fs);
    out_result_rtotal = strcat(s0, s1, s2, s3);%sprintf("this unit max flicker strength is %f, threshold is %f\nflicker testing %s, flicker ratio: %fp, average flicker strength: %f", unit_fs, baseline_fs, result_rtotal, 100*(n_flicker/data_n), mean(total_std_diff(:, 3)));
    %disp(out_result_rtotal);    
    
    %row temp noise
    %std cross each row in whole data set 
    total_rowTemp = zeros(imgY, 2);    
    for i = 1: imgY
         %row temp noise of row profile pre diff frame
         temp_rowTemp = total_fd(:, i+7)-good_ref(i);
         k = std(temp_rowTemp);
         p = mean(temp_rowTemp);  
         total_rowTemp(i, 1) = k;
         total_rowTemp(i, 2) = p;
    end
   
    unit_rowTemp_std = std(total_rowTemp(:, 1));
    unit_rowTemp_mean= mean(total_rowTemp(:, 1));
    unit_rowTemp_fs = unit_rowTemp_mean+3*unit_rowTemp_std;    
    
    
    result_rtemp = "";
    if unit_rowTemp_fs > baseline_rowTemp_fs
        result_rtemp = "fail";
    else
        result_rtemp = "pass";
    end
    out_result_rtemp = sprintf("this unit flicker strength (row temp noise)is %f, threshold is %f\nflicker testing %s", unit_rowTemp_fs, baseline_rowTemp_fs, result_rtemp);
    %disp(out_result_rtemp);


end
%debug
function debugPlot(out_result, out_result2, good_n,total_std_diff, total_fd, path, filename, baseline_n, data_n)
    good_fs = zeros(data_n, 1);
    light_fs = zeros(data_n, 1);
    light_peak = zeros(data_n, 1);
    bad_fs = zeros(data_n, 1);
    baseline_fsc = zeros(data_n, 1);
    baseline_peak = zeros(data_n, 1);
    good_peak = zeros(data_n, 1);
    for i = 1:baseline_n
        total_fd(good_n(i), 2) = 4;
    end
    good_fs = good_fs-1;
    light_fs = light_fs-1;
    bad_fs = light_fs-1;
    baseline_fsc = light_fs-1;
    for i = 1: data_n
         if total_fd(i, 2) == 0
            good_fs(i) = total_std_diff(i, 3);    
            good_peak(i) = total_std_diff(i, 4);
         elseif total_fd(i, 2) == 2
            bad_fs(i) = total_std_diff(i, 3);    
         elseif total_fd(i, 2) == 1
            light_fs(i) = total_std_diff(i, 3); 
            light_peak(i) = total_std_diff(i, 4);
         elseif total_fd(i, 2) == 4
            baseline_fsc(i) =  total_std_diff(i, 3);
            baseline_peak(i) = total_std_diff(i, 4);
         end    
    end



    figure(1)
    title(out_result);
    hold on
    plot(baseline_fsc, '*');
    hold on
    plot(good_fs, 'x');
    hold on
    plot(light_fs, 'o');
    hold on
    %plot(bad_fs, '^');
    %hold on
    ylim([0.02 20]);
    ylabel("flicker strength/diff peak");  
    hold on

    plot(baseline_peak, 'rd');
    hold on
    plot(good_peak, 'gs');
    hold on
    plot(light_peak, 'bh');
    hold on
    xlabel("frame #");
    tick = [0 0.5 1 1.5 2 3 4 5 6 7 8 9 10 12 14 16 18 20];
    yticks(tick);    
    %legend({'baseline','good', 'thin flicker', 'thick flicker'},'Location','northeast');
    legend({'baseline flicker strength','good frame flicker strangth', 'flicker frame flicker strength', 'baseline peak', 'good peak', 'flicker peak'},'Location','northeast');  

    hold on
    saveas(gcf, fullfile(path,filename));    
    
    figure(4)
    title(out_result);
    hold on
    plot(baseline_fsc, '*');
    hold on
    plot(good_fs, 'x');
    hold on
    plot(light_fs, 'o');
    ylim([0.01 3]);
    ylabel("flicker strength/diff peak");  
    hold on

    plot(baseline_peak, 'rd');
    hold on
    plot(good_peak, 'gs');
    hold on
    plot(light_peak, 'bh');
    hold on
    xlabel("frame #");
    tick = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2 2.5 3];
    yticks(tick);    
    legend({'baseline flicker strength','good frame flicker strangth', 'flicker frame flicker strength', 'baseline peak', 'good peak', 'flicker peak'},'Location','northeast');  

    hold on
    saveas(gcf, fullfile(path,strrep(filename, ".png", "zoomin.png"))); 
    
    figure(2)
    title(out_result2);
    hold on
    scatter(good_fs, good_peak, 'go');
    hold on
    scatter(light_fs, light_peak, 'rs');
    hold on
    scatter(baseline_fsc,baseline_peak, 'bh');
    xlabel("flicker strength");
    ylabel("diff peak");
    ylim([0.01 20]);
    xlim([0.01 20]);
    tick = [0 0.5 1 1.5 2 3 4 5 6 7 8 9 10 12 14 16 18 20];
    xticks(tick);
    yticks(tick);
    hold on
    legend({'good', 'flicker', 'baseline'},'Location','southeast');  
    saveas(gcf, fullfile(path,"fs and peak.png"));    
    
    figure(3)
    title(out_result2);
    hold on
    scatter(good_fs, good_peak, 'go');
    hold on
    scatter(light_fs, light_peak, 'rs');
    hold on
    scatter(baseline_fsc,baseline_peak, 'bh');
    xlabel("flicker strength");
    ylabel("diff peak");
    ylim([0 2]);
    xlim([0 2]);
    tick = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2];
    xticks(tick);
    yticks(tick);
    hold on
    legend({'good', 'flicker', 'baseline'},'Location','southeast');  
    saveas(gcf, fullfile(path,"fs and peak zoom in.png"));   
    
    

    
    close all
end