

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