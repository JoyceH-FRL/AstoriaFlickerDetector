clc
close all
cd("")
file_input = "input_fd_rowporfile.txt";
file_input_std = "input_fd_std_rowporfile.txt";

fid = fopen(file_input, "r");
fid2 = fopen(file_input_std, "r");
rp = fgetl(fid);
rstd = fgetl(fid2);
s = strfind(rp, '	');
s2 = strfind(rstd, '	');
good_ref = zeros(1, 512);
good_rowSNR = zeros(1, 512);
good_frameN = rp(6:9);
total_rp = zeros(300,512);
total_rstd = zeros(300,512);
total_frameN = zeros(1,300);
flicker_frame = zeros(1,300);
for j = 1: 511
    good_ref(j) = str2num(rp(s(j+1)+1:s(j+2)-1));
    good_rowSNR(j) = str2num(rstd(s2(j+1)+1:s2(j+2)-1));
end
%%%%%%% Find Good Frame %%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i = 1;
while ischar(rp) && i <= 300
    rp =  fgetl(fid);
    s = strfind(rp, '	');
    total_frameN(i) = str2num(rp(6:9));
    rstd = fgetl(fid2);    
    s2 = strfind(rstd, '	');  
    for j = 1: 511
        total_rp(i, j) = str2num(rp(s(j+1)+1:s(j+2)-1)); 
        total_rp(i, j) = total_rp(i, j) - good_ref(j); %mark for method2
        total_rstd(i, j) = str2num(rstd(s2(j+1)+1:s2(j+2)-1));         
    end 
    i = i+1;
end
fclose(fid);
fclose(fid2);
j_start = 1;
j_end = 512;
fid_sta = fopen("C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR\output\rp_sta.txt", "w+");
%method 2
mean_300 = mean(total_rp(:, 1:511)');
std_300 = std(total_rp(:, 1:511)');
max_300 = max(total_rp(:, 1:511)');
min_300 = min(total_rp(:, 1:511)');
median_300 = median(total_rp(:, 1:511)');


for i = 1: 300
    %method 1
%     j=1;
%     while  j <=j_end-15
%         count = 0;
%         for p = j:j+15
%             if abs(total_rp(i, p)) >= 3
%                 count = count+1;
%                 while count >= 10 && flicker_frame(i) ==0
%                     flicker_frame(i) = total_frameN(i);
%                 end
%             end
%         end
%         j = j+1;
%     end

%     %method 2
    figure(i)
    title(strcat("Frame#", num2str(total_frameN(i))));
    yyaxis right 
    a = total_rp(i, :);
    plot(a);
    ylim([-25, 25]);
    yticks([-25 -20 -15 -10 -5:1:5 10 15 20 25]);
    xlim([1, 511]);    
    hold on
    yyaxis left 
    b = total_rp(i, :)+good_ref;
    plot(b);
    ylim([512, 572]);
    yticks(512:5:572);
    xlim([1, 511]);
    xticks(1:32:511);
    legend({'row mean','row mean diff'}, 'Location','northeast'); 
    hold on
    
    
    mid_diff = max(abs(max_300(i) - median_300(i)), abs(min_300(i) - median_300(i)));
    mean_diff = max(abs(max_300(i) - mean_300(i)), abs(min_300(i) - mean_300(i)));
    maxmin = max_300(i) - min_300(i);
    info_rp = fprintf(fid_sta, "%d\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t", total_frameN(i), mean_300(i), std_300(i), max_300(i), min_300(i), median_300(i), mid_diff, mean_diff);
    if maxmin >= 5
        flicker_frame(i) = total_frameN(i);
        info_rp = fprintf(fid_sta, "1\n");
    else
        info_rp = fprintf(fid_sta, "\n");
    end
    
    %methold 3
    %win_size = 5;
%     grad = zeros(1, 512);
%     for j = 1: 509
%         if total_rp(i, j) - total_rp(i, j+1) > 0
%             grad(j+1) = -1;
%         else
%             grad(j+1) = +1;
%         end
%     end
%     j = 3;
%     indx = 2;
%     while j < 511
%         if grad(j) + grad(j-1) == 0
%             grad(j-1) = (total_rp(i, indx)-total_rp(i, j))/(indx-j);
%             indx = j;
%         end
%         j = j+1;            
%     end
%     for j = 1: 512
%         if grad(j) == -1 || grad(j) == 1
%             grad(j) = 0;
%         end
%     end
    %method 4
%     grad = zeros(1, 512);
%     win_size = 4;
%     for j = 1: win_size: 511-win_size
%         end_indx = min(j+win_size-1, 511);
%         grad(j) = mean(total_rp(i, j: end_indx));
%     end
%     win_size_2 = win_size^2;
%     for j = 1:win_size_2: 511-win_size_2
%         end_indx = min(j+win_size_2-1, 511);
%         grad(j) = mean(grad(j: end_indx)); 
%         for p = j+1 : end_indx
%             grad(j) = 0;
%         end
%     end
%     win_size_3 = win_size_2^2;
%     for j = 1:win_size_3: 511-win_size_3
%         end_indx = min(j+win_size_3-1, 511);
%         grad(j) = mean(grad(j: end_indx)); 
%         for p = j+1 : end_indx
%             grad(j) = 0;
%         end
%     end
%     
%     max_grad = max(grad);
%     min_grad = min(grad);
%     
%     info_rp = fprintf(fid_sta, "%d\t%f\t%f\t", total_frameN(i), max_grad, min_grad);
%     for j = 1:win_size_3: 511-win_size_3
%         info_rp = fprintf(fid_sta, "%f\t", grad(j));
%     end
%     
%     
%     if abs(max_grad) >= 1 || abs(min_grad) >1
%         flicker_frame(i) = total_frameN(i);
%         info_rp = fprintf(fid_sta, "1\n");
%     else
%         info_rp = fprintf(fid_sta, "\n");
%     end
%     
% 
%     figure(i)
%     title(strcat("Frame#", num2str(total_frameN(i))));
%     yyaxis right 
%     a = total_rp(i, :);
%     plot(a);
%     ylim([-25, 25]);
%     yticks([-25 -20 -15 -10 -5:1:5 10 15 20 25]);
%     xlim([1, 511]);    
%     hold on    
%     yyaxis left 
%     plot(grad);
%     ylim([-3, 3]);
%     yticks(-3:0.3:3);
%     xlim([1, 511]);
%     xticks(1:32:511);
%     legend({'row mean diff gradient','row mean diff'}, 'Location','northeast'); 
%     hold on
    outputFDminpath = "C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR\output\FD_min456";
    %f = dir(fullfile(outputFDminpath, strcat("*_", num2str(total_frameN(i)), "_*.png")));      
%     figure(i)
%     saveas(gcf, fullfile(outputFDminpath, strcat("gradient3_", num2str(total_frameN(i)), '.png')));     

    
    
    outputpath = "C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR\output";
    outputFDminpath = "C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR\output\FD_min456";
    f = dir(fullfile(outputFDminpath, strcat("*_", num2str(total_frameN(i)), "_*.png")));  
    
    if flicker_frame(i) > 0
        copyfile(fullfile(outputFDminpath, f.name), strrep(f.folder, "\FD_min456", "\flicker_maxmin"));
         figure(i)
         saveas(gcf, fullfile(strrep(f.folder, "\FD_min456", "\flicker_maxmin"), strcat("flicker_manmin_", num2str(total_frameN(i)), '.png'))); 
  
    else
        copyfile(fullfile(outputFDminpath, f.name), strrep(f.folder, "\FD_min456", "\nonflicker_maxmin"));
         figure(i)
         saveas(gcf, fullfile(strrep(f.folder, "\FD_min456", "\nonflicker_maxmin"), strcat("nonflicker_maxmin_", num2str(total_frameN(i)), '.png')));
       
    end
end

fclose(fid_sta);
close all


flicker_path = "C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR\output\flicker_maxmin";

flicker_png = dir(fullfile(flicker_path,"FS_R_*.png"));
flicker_std_plot_png = dir(fullfile(flicker_path,"flicker_manmin_*.png"));
n = length(flicker_png);
writerObj = VideoWriter(fullfile(flicker_path,"output_flicker.avi"), 'Motion JPEG AVI');
writerObj.Quality = 80;
writerObj.FrameRate = 5;
open(writerObj);
% write the frames to the video
for i=1:n
    img = fullfile(flicker_png(i).folder, flicker_png(i).name) ; 
    I = imread(img) ; 
    subplot(1, 2, 1);
    imshow(I) ; 
    img4 = fullfile(flicker_std_plot_png(i).folder, flicker_std_plot_png(i).name) ; 
    I4 = imread(img4) ; 
    subplot(1, 2, 2);
    imshow(I4) ;    
    x0=0;
    y0=0;
    width=1800;
    height=900;    
    set(gcf,'position',[x0,y0,width,height])      
    F = getframe(gcf) ;
    writeVideo(writerObj, F);
    %disp(i);
end
% close the writer object
close(writerObj);
close all

nonflicker_path = "C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR\output\nonflicker_maxmin";

nonflicker_png = dir(fullfile(nonflicker_path,"FS_R_*.png"));
%nonflicker_plot_png = dir(fullfile(nonflicker_path,"nonflicker_2*.png"));
nonflicker_snr_plot_png = dir(fullfile(nonflicker_path,"nonflicker_maxmin_*.png"));
n = length(nonflicker_png);
writerObj2 = VideoWriter(fullfile(nonflicker_path,"output_nonflicker.avi"), 'Motion JPEG AVI');
writerObj2.Quality = 80;
writerObj2.FrameRate = 5;
open(writerObj2);
% write the frames to the video
for i=1:n
    img = fullfile(nonflicker_png(i).folder, nonflicker_png(i).name) ; 
    I = imread(img) ; 
    subplot(1, 2, 1);    
    imshow(I) ; 
%     img2 = fullfile(nonflicker_plot_png(i).folder, nonflicker_plot_png(i).name) ; 
%     I2 = imread(img2) ; 
%     subplot(2, 2, 2);
%     imshow(I2) ;
    img4 = fullfile(nonflicker_snr_plot_png(i).folder, nonflicker_snr_plot_png(i).name) ; 
    I4 = imread(img4) ; 
    subplot(1, 2, 2);
    imshow(I4) ;     
    x0=0;
    y0=0;
    width=1800;
    height=900;    
    set(gcf,'position',[x0,y0,width,height])        
    F = getframe(gcf) ;
    writeVideo(writerObj2, F);
    disp(nonflicker_snr_plot_png(i).name);
end
% close the writer object
close(writerObj2);
close all
