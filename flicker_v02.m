clc
close all

path= "C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR\input";
file_name = "total_fd.txt";
flicker_tag = "flicker_tag.txt";
total_fd = zeros(300, 519);
good_fd = zeros(64, 512);
light_fd = zeros(102, 512); 
bad_fd = zeros(34, 512);
good_std = zeros(300,2);
light_std = zeros(300,2);
bad_std = zeros(300,2);
good_list = zeros(164, 1);
light_list = zeros(102,1);
bad_list = zeros(34,1);

p1 = 1;
p2 = 1;
p3 = 1;

fid = fopen(fullfile(path, file_name), "r");
data = fgetl(fid);
fid2 = fopen(fullfile(path, flicker_tag), "r");
data2 = fgetl(fid2);
i=1;
while(ischar(data))
    c = strsplit(data, "\t");
    d = strsplit(data2, "\t");
    total_fd(i, 1) = str2double(c(1));
    total_fd(i, 2) = str2double(d(2));
    total_fd(i, 3:7) = str2double(c(2:6));
    total_fd(i, 8: end) = str2double(c(12:523));
    %non-flicker
     if total_fd(i, 2) == 0
         good_list(p1) = i;
         good_fd(p1, :) =  total_fd(i, 8:end);
         p1 = p1+1;
     elseif total_fd(i, 2) == 2
         bad_list(p2) = i;
         bad_fd(p2, :) =  total_fd(i, 8:end);
         p2 = p2+1;
     else
         light_list(p3) = i;
         light_fd(p3, :) =  total_fd(i, 8:end);
         p3 = p3+1;
     end
     i = i+1;
     data = fgetl(fid);
     data2 = fgetl(fid2);
end



% img_array = readRAW(folder, filename, size, imgX, imgY, invert);
% [PD_img, FD_img, TTS_img] = HDRframe(img_array, imgX, imgY)
% [fd_frame_statistic, fd_row_profile_statistic, fd_col_profile_statistic, fd_row_profile, fd_col_profile]=ImageStatistic(FD_img, 512, 512);
% %total_fd(i, 1) = frame_id;
% total_fd(i, 3:7) = fd_row_profile_statistic;
% total_fd(i, 8:end) = fd_row_profile;



baseline_n = 20;
[baseine_log, good_ref, baseline_fs, good_n] = baselineSet(total_fd, baseline_n);
[unit_fs, out_result, total_std_diff]  = FlickerStrength(total_fd, good_ref, baseline_fs);
path = "C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR";
filename = "flickerStrengthTag_std.png";
%only total_fd(:,2) has tag information
debugPlot(out_result, good_n, total_std_diff, total_fd, path, filename, baseline_n);


   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% input: file folder, filename, file size, image width (x), image height (y) and is it invert image
% invert image means 
% output image 2D array , (row , column), 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img_array = readRAW(folder, filename, size, imgX, imgY, invert)
    strfind(filename, ".");
    fn = convertStringsToChars(filename);
    file_type = fn(strfind(fn, ".")+1:end);
    if strcmp(file_type, "png")
        img_array = imread(fullfile(folder, filename));
        img_array = img_array/64;
        if invert
            img_array = 1023 - img_array;
        end        
    else
        bit_dep = 8*(size / (imgX*imgY));
        fid = fopen(fullfile(folder, filename), "r");
        if bit_dep ==8
            img_array = fread(fid, [imgX, imgY], 'uint8');
        elseif bit_dep ==16
            img_array = fread(fid, [imgX, imgY], 'uint16');
            if invert
                img_array = 1023 - img_array;
            end
        elseif bit_dep ==10
            img_array_8b = fread(fid, [(imgX*bit_dep/8), imgY], 'uint8');
            img_temp_array = zeros(imgX, imgY);
            img_array =  zeros(imgX, imgY);
            for i = 1:5: imgX*bit_dep/8
               index = 4*((i-1)/5)+1;
               img_temp_array(index, :) = img_array_8b(i, :);
               img_temp_array(index+1, :) = img_array_8b(i+1, :);
               img_temp_array(index+2, :) = img_array_8b(i+2, :);
               img_temp_array(index+3, :) = img_array_8b(i+3, :);
               p1_flag = bitand(img_array_8b(i+4,:), 3);
               p2_flag = bitand(img_array_8b(i+4, :), 12);
               p3_flag = bitand(img_array_8b(i+4, :), 48);
               p4_flag = bitand(img_array_8b(i+4, :), 192);
               img_array(index, :) = p1_flag*256+img_temp_array(index, :);
               img_array(index+1, :) = bitshift(p2_flag, -2)*256+img_temp_array(index+1, :);
               img_array(index+2, :) = bitshift(p3_flag, -4)*256+img_temp_array(index+2, :);
               img_array(index+3, :) = bitshift(p4_flag, -6)*256+img_temp_array(index+3, :);
            end
            if invert
                img_array = 1023 - img_array;
            end            
        end
        fclose(fid);
    end
%     %debug  ----Start----
%     if ~strcmp(file_type, "png")
%         imwrite(uint16(img_array'*256), fullfile(folder, strrep(filename, file_type, 'png')));
%     else
%         imwrite(uint16(img_array'*256), fullfile(folder, strrep(filename, ".png", '_invert.png')));
%     end 
%     %debug  ----End----
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Astoria HAR include PD, FD and TTS
% this function will paser 3 ADC images for analysis
% input image data format is 10-bit,2 bytes image
% image signal need to be dark as small value, saturated as big value
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PD_img, FD_img, TTS_img] = HDRframe(img_array, imgX, imgY)
    PD_img =  zeros(imgX, imgY);
    FD_img =  zeros(imgX, imgY);
    TTS_img =  zeros(imgX, imgY);
    for i = 1: imgX
        for j = 1: imgY
            if img_array(i, j) < 512
                PD_img(i, j) = img_array(i, j);
                FD_img(i, j) = 512;
                TTS_img(i, j) = 768;
            elseif img_array(i, j) >= 768
                PD_img(i, j) = 0;
                FD_img(i, j) = 512;
                TTS_img(i, j) = img_array(i, j);                
            else
                PD_img(i, j) = 0;
                FD_img(i, j) = img_array(i, j);
                TTS_img(i, j) = 768;                 
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% frame_statistic = [mean, std, max, min, median]
% row_profile
% row_profile_statistic = [mean, std, max, min, median]
% col_profile
% col_profile_statistic = [mean, std, max, min, median]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [frame_statistic, row_profile_statistic, col_profile_statistic, row_profile, col_profile]=ImageStatistic(img, imgX, imgY)
    %matlab read image as [row, column] in raw
    %statistic array [mean, std, max, min, median]
    frame_statistic = zeros(1, 5);
    row_profile_statistic = zeros(1, 5);
    col_profile_statistic = zeros(1, 5);
    frame_statistic(1) = mean2(img);
    frame_statistic(2) = std(img, [], 'all');
    frame_statistic(3) = max(img, [], 'all');
    frame_statistic(4) = min(img, [], 'all');
    frame_statistic(5) = median(img, 'all');
    %for row profile
    row_profile = mean(img);
    row_profile_statistic(1) = mean(row_profile);
    row_profile_statistic(2) = std(row_profile);
    row_profile_statistic(3) = max(row_profile);
    row_profile_statistic(4) = min(row_profile);
    row_profile_statistic(5) = median(row_profile);    
    %for column profile
    col_profile = mean(img');
    col_profile_statistic(1) = mean(col_profile);
    col_profile_statistic(2) = std(col_profile);
    col_profile_statistic(3) = max(col_profile);
    col_profile_statistic(4) = min(col_profile);
    col_profile_statistic(5) = median(col_profile);      
end


function [baseine_log, good_ref, baseline_fs, good_n] = baselineSet(total_fd, baseline_n)
    good_n = zeros(baseline_n, 1);
    good_n = good_n -1;
    j = 1;
    good_ref = zeros(1, 512);
    start = 11;
    baseline_flage = 1;
    i = start+1;
    start_g = 0;
    baseline_fs = 0;
    while baseline_flage
        while i < 300 && good_n(baseline_n) < 0
            temp_diff_rp = total_fd(i, 8:end) - total_fd(start, 8:end);
            k = std(temp_diff_rp);
            p = abs(mean(temp_diff_rp));
            if k < 0.25 && p < 0.5 && k > 0 && p > 0
                start_g =1;
                good_n(j) = i;
                good_ref = good_ref + total_fd(good_n(j), 8:end);
                j = j+1;
                if j == baseline_n+1
                    i = 300;
                end
            elseif p > 0.5 && start_g == 0
                start = start+1;
                i = 300;
            end
            i = i+1;
        end
        i = start+1;
        good_ref = good_ref/baseline_n;
        %baseline threshold 
        good_frame_diff = good_ref - total_fd(start, 8:end);
        good_frame_diffstd = std(good_frame_diff);
        good_frame_diffmean =abs(mean(good_frame_diff));
        if good_frame_diffstd < 0.25 && good_frame_diffmean < 0.5
            baseline_flage = 0;
            baseline_fs = good_frame_diffmean + 3*good_frame_diffstd;
            baseine_log = sprintf("baseline threshold: %f, from %d good frames, diff with %d-th frame, \t %f %f", baseline_fs, baseline_n, start, good_frame_diffmean, good_frame_diffstd);
            disp(baseine_log);
        end
    end
end
%flicker dtrength
function [unit_fs, out_result, total_std_diff] = FlickerStrength(total_fd, good_ref, baseline_fs)
    total_std_diff = zeros(300, 3);
    for i = 1: 300
         temp_diff_rp = total_fd(i, 8:end)-good_ref;
         k = std(temp_diff_rp);
         p = mean(temp_diff_rp);
         total_std_diff(i, 1) = k;
         total_std_diff(i, 2) = p; 
         total_std_diff(i, 3) = p+3*k; 
    end
    unit_std = std(total_std_diff(:, 1));
    unit_mean = mean(total_std_diff(:, 1));
    unit_fs = unit_mean+3*unit_std;
    result = "";
    if unit_fs > baseline_fs
        result = "fail";
    else
        result = "pass";
    end
    out_result = sprintf("this unit flicker strength is %f, threshold is %f\nflicker testing %s", unit_fs, baseline_fs, result);
end
%debug
function debugPlot(out_result, good_n,total_std_diff, total_fd, path, filename, baseline_n)
    good_fs = zeros(300, 1);
    light_fs = zeros(300,1);
    bad_fs = zeros(300,1);
    baseline_fs = zeros(300,1);
    for i = 1:baseline_n
        total_fd(good_n(i), 2) = 4;
    end
    good_fs = -1;
    light_fs = -1;
    bad_fs = -1;
    baseline_fs = -1;
    for i = 1: 300
         if total_fd(i, 2) == 0
            good_fs(i) = total_std_diff(i, 3);    
         elseif total_fd(i, 2) == 2
            bad_fs(i) = total_std_diff(i, 3);    
         elseif total_fd(i, 2) == 1
            light_fs(i) = total_std_diff(i, 3); 
         else
            baseline_fs(i) =  total_std_diff(i, 3);
         end    
    end



    figure(1)
    title(out_result);
    hold on
    plot(baseline_fs, '*');
    hold on
    plot(good_fs, 'x');
    hold on
    plot(light_fs, 'o');
    hold on
    plot(bad_fs, '^');
    hold on
    ylim([0.05 20]);
    ylabel("flicker strength");
    xlabel("frame #");
    legend({'baseline','good', 'thin flicker', 'thick flicker'},'Location','northeast');
    hold on
    saveas(gcf, fullfile(path,filename));
    close all
end