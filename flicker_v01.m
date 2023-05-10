clc
close all

%snsorRAW input in ISPM
seneorRawpath = "C:\Users\joycehung\OneDrive - Facebook\Desktop\input\300frames_BR\input";
files = dir(fullfile(seneorRawpath, "*.dat"));

fid_total = fopen(fullfile(seneorRawpath, "total_statistic.txt"), "w+");
fprintf(fid_total, "frame#\tpd_mean\tpd_std\tpd_max\tpd_min\tpd_mid\tpdr_mean\tpdr_std\tpdr_max\tpdr_min\tpdr_mid\tpdc_mean\tpdc_std\tpdc_max\tpdc_min\tpdc_mid\t");
fprintf(fid_total, "fd_mean\tfd_std\tfd_max\tfd_min\tfd_mid\tfdr_mean\tfdr_std\tfdr_max\tfdr_min\tfdr_mid\tfdc_mean\tfdc_std\tfdc_max\tfdc_min\tfdc_mid\t");
fprintf(fid_total, "tts_mean\ttts_std\ttts_max\ttts_min\ttts_mid\tttsr_mean\tttsr_std\tttsr_max\tttsr_min\tttsr_mid\tttsc_mean\tttsc_std\tttsc_max\tttsc_min\tttsc_mid\n");
fid_row = fopen(fullfile(seneorRawpath, "total_rowprofile.txt"), "w+");
fid_col = fopen(fullfile(seneorRawpath, "total_colprofile.txt"), "w+");
fid_allpd = fopen(fullfile(seneorRawpath, "total_pd.txt"), "w+");
fid_allfd = fopen(fullfile(seneorRawpath, "total_fd.txt"), "w+");
fid_alltts = fopen(fullfile(seneorRawpath, "total_tts.txt"), "w+");

%fname = "FS_R_2726_288411790733_unpacked_10b_2023-03-29_15h48m13s.dat";
n = size(files);
img_n1 = -1;
img_n2 = -1;
imgn1_fdrp = {};
imgn2_fdrp = {};
good_frame = -1;
good_fdrp = {};
frame_n = zeros(n(1), 1); 
diff_fdrp = zeros(n(1), 512);

for i = 1: n(1)
    %img_array = readRAW(seneorRawpath, fname, 524288, 512, 512, 1);

    img_array = readRAW(seneorRawpath, files(i).name, files(i).bytes, 512, 512, 1);
    [PD, FD, TTS] = HDRframe(img_array, 512, 512);
%     %debug  ----Start----
%     imwrite(uint16(PD'*64), fullfile(seneorRawpath, "pd.png"));
%     imwrite(uint16(FD'*64), fullfile(seneorRawpath, "fd.png"));
%     imwrite(uint16(TTS'*64), fullfile(seneorRawpath, "tts.png"));
%     %debug  ----End----    
    %PD
    [pd_frame_statistic, pd_row_profile_statistic, pd_col_profile_statistic, pd_row_profile, pd_col_profile]=ImageStatistic(PD, 512, 512);
    [fd_frame_statistic, fd_row_profile_statistic, fd_col_profile_statistic, fd_row_profile, fd_col_profile]=ImageStatistic(FD, 512, 512);
    [tts_frame_statistic, tts_row_profile_statistic, tts_col_profile_statistic, tts_row_profile, tts_col_profile]=ImageStatistic(TTS, 512, 512);
    s = files(i).name;
    frame_n(i, 1) = str2num(s(6:9));
    
    fid_pd = fopen(fullfile(seneorRawpath, strcat(s(6:9), "_pd.txt")), "w+");
    fprintf(fid_pd, "%f\t", pd_frame_statistic);
    fprintf(fid_pd, "\n");
    fprintf(fid_pd, "%f\t", pd_row_profile_statistic);
    fprintf(fid_pd, "\n");
    fprintf(fid_pd, "%f\t", pd_row_profile);
    fprintf(fid_pd, "\n");
    fprintf(fid_pd, "%f\t", pd_col_profile_statistic);
    fprintf(fid_pd, "\n");
    fprintf(fid_pd, "%f\t", pd_col_profile);
    fclose(fid_pd);

    fid_fd = fopen(fullfile(seneorRawpath, strcat(s(6:9), "_fd.txt")), "w+");
    fprintf(fid_fd, "%f\t", fd_frame_statistic);
    fprintf(fid_fd, "\n");
    fprintf(fid_fd, "%f\t", fd_row_profile_statistic);
    fprintf(fid_fd, "\n");
    fprintf(fid_fd, "%f\t", fd_row_profile);
    fprintf(fid_fd, "\n");
    fprintf(fid_fd, "%f\t", fd_col_profile_statistic);
    fprintf(fid_fd, "\n");
    fprintf(fid_fd, "%f\t", fd_col_profile);
    fclose(fid_fd);
    
    diff_fdrp(i, :) = fd_row_profile;
    
    fid_tts = fopen(fullfile(seneorRawpath, strcat(s(6:9), "_tts.txt")), "w+");
    fprintf(fid_tts, "%f\t", tts_frame_statistic);
    fprintf(fid_tts, "\n");
    fprintf(fid_tts, "%f\t", tts_row_profile_statistic);
    fprintf(fid_tts, "\n");
    fprintf(fid_tts, "%f\t", tts_row_profile);
    fprintf(fid_tts, "\n");
    fprintf(fid_tts, "%f\t", tts_col_profile_statistic);
    fprintf(fid_tts, "\n");
    fprintf(fid_tts, "%f\t", tts_col_profile);
    fclose(fid_tts);
    
    %---- find good fram Start----
    while i == 1 && img_n1 < 0
       img_n1 =  frame_n(i, 1);
       imgn1_fdrp = fd_row_profile;
    end
    if i >= 2 && i <= n(1)-1 && good_frame < 0
        img_n2 = frame_n(i, 1);
        imgn2_fdrp = fd_row_profile;
        n = findgoodframe(img_n1, imgn1_fdrp,img_n2, imgn2_fdrp);
        if n == img_n2
            good_frame = n;
            good_fdrp = imgn2_fdrp;
        end 
    end  
    %---- find good fram End----    
    
    %debug format ----Start----
%     fprintf(fid_total, "%s\t", s(6:9));
%     fprintf(fid_total, "%f\t", pd_frame_statistic);
%     fprintf(fid_total, "%f\t", pd_row_profile_statistic);
%     fprintf(fid_total, "%f\t", pd_col_profile_statistic);
%     fprintf(fid_total, "%f\t", fd_frame_statistic);
%     fprintf(fid_total, "%f\t", fd_row_profile_statistic);
%     fprintf(fid_total, "%f\t", fd_col_profile_statistic);
%     fprintf(fid_total, "%f\t", tts_frame_statistic);
%     fprintf(fid_total, "%f\t", tts_row_profile_statistic);
%     fprintf(fid_total, "%f\t", tts_col_profile_statistic);
%     fprintf(fid_total, "\n");
%     
%     fprintf(fid_row,"%s_PD\t", s(6:9));
%     fprintf(fid_row, "%f\t", pd_row_profile);
%     fprintf(fid_row, "\n");      
%     fprintf(fid_row,"%s_FD\t", s(6:9));
%     fprintf(fid_row, "%f\t", fd_row_profile);
%     fprintf(fid_row, "\n");      
%     fprintf(fid_row,"%s_TTS\t", s(6:9));
%     fprintf(fid_row, "%f\t", tts_row_profile);
%     fprintf(fid_row, "\n");        
%     
%     fprintf(fid_col,"%s_PD\t", s(6:9));
%     fprintf(fid_col, "%f\t", pd_col_profile);
%     fprintf(fid_col, "\n");    
%     fprintf(fid_col,"%s_FD\t", s(6:9));
%     fprintf(fid_col, "%f\t", fd_col_profile);
%     fprintf(fid_col, "\n");        
%     fprintf(fid_col,"%s_TTS\t", s(6:9));
%     fprintf(fid_col, "%f\t", tts_col_profile); 
%     fprintf(fid_col, "\n");   
%     
%     fprintf(fid_allpd,"%s\t", s(6:9));    
%     fprintf(fid_allpd, "%f\t%f\t", pd_row_profile_statistic, pd_col_profile_statistic);
%     fprintf(fid_allpd, "%f\t", pd_row_profile);
%     fprintf(fid_allpd, "%f\t", pd_col_profile);
%     fprintf(fid_allpd, "\n");

    fprintf(fid_allfd,"%s\t", s(6:9));    
    fprintf(fid_allfd, "%f\t%f\t", fd_row_profile_statistic, fd_col_profile_statistic);
    fprintf(fid_allfd, "%f\t", fd_row_profile);
    fprintf(fid_allfd, "%f\t", fd_col_profile);
    fprintf(fid_allfd, "\n");
    
%     fprintf(fid_alltts,"%s\t", s(6:9));    
%     fprintf(fid_alltts, "%f\t%f\t", tts_row_profile_statistic, tts_col_profile_statistic);
%     fprintf(fid_alltts, "%f\t", tts_row_profile);
%     fprintf(fid_alltts, "%f\t", tts_col_profile);
%     fprintf(fid_alltts, "\n");    
    %debug format ----End----
    
end
fclose(fid_total);
fclose(fid_row);
fclose(fid_col);
fclose(fid_allpd);
fclose(fid_allfd);
fclose(fid_alltts);

% get diff row profile
fid_difffdrp = fopen(fullfile(seneorRawpath, "total_fdrodiff.txt"), "w+");
fid_difffdrp_grad = fopen(fullfile(seneorRawpath, "total_fdrodiff_gradient.txt"), "w+");

n = size(files);
for i = 1: n(1)
    diff_fdrp(i, :) = diff_fdrp(i, :) - good_fdrp;
    temp_rp = diff_fdrp(i, :);
    diff_fdrp_mean = mean(temp_rp);
    diff_fdrp_std = std(temp_rp);
    diff_fdrp_max = max(temp_rp);
    diff_fdrp_min = min(temp_rp);
    diff_fdrp_mid = median(temp_rp);
    %gradient
    grad_1_rp  = zeros(1, 512/(4^1));
    grad_2_rp  = zeros(1, 512/(4^2));
    grad_3_rp  = zeros(1, 512/(4^3));
    for j = 1: 4: 512
        grad_1_rp(1+((j-1)/4)) = (temp_rp(j) - temp_rp(j+3))/4; 
    end
    for j = 1: 4: 512/(4^1)
        grad_2_rp(1+((j-1)/4)) = (grad_1_rp(j) - grad_1_rp(j+3))/4;
    end
    for j = 1: 4: 512/(4^2)
        grad_3_rp(1+((j-1)/4)) = (grad_2_rp(j) - grad_2_rp(j+3))/4;
    end
    gardient3_mean = mean(grad_3_rp);
    gardient3_std = std(grad_3_rp);
    gardient3_max = max(grad_3_rp);
    gardient3_min = min(grad_3_rp);
    gardient3_mid = median(grad_3_rp);    
    fprintf(fid_difffdrp_grad, "%d\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t", frame_n(i, 1), gardient3_mean, gardient3_std, gardient3_max, gardient3_min,gardient3_mid, max(abs(gardient3_max), abs(gardient3_min)), grad_3_rp);
    fprintf(fid_difffdrp_grad, "\n");    
    fprintf(fid_difffdrp, "%d\t%f\t%f\t%f\t%f\t%f\t%f\t", frame_n(i, 1), diff_fdrp_mean, diff_fdrp_std, diff_fdrp_max, diff_fdrp_min, diff_fdrp_mid, temp_rp);
    fprintf(fid_difffdrp, "\n");
end
fclose(fid_difffdrp);
fclose(fid_difffdrp_grad);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% input: image array
% output 3Q image
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
% input: file folder, filename, file size, image width (x), image
% height (y) and is it invert image
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
%%%%%%% Find Good Frame %%%%%%%%%%

function n_gframe = findgoodframe(img1_nF, img1_rp, img2_nF, img2_rp)
    std_threshold = 0.25;
    diff_rp = img1_rp - img2_rp;
    diff_std = std(diff_rp);
    if abs(diff_std) < std_threshold
        n_gframe = img2_nF;
    else
        n_gframe = img1_nF;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
