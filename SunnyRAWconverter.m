%input file folder, file name, image width and image height
function [img_10b_noninvert] = SunnyRAWconverter(path, file, imgX, imgY)
    fid = fopen(fullfile(path, file), "r");
    img = fread(fid, [imgX, imgY], 'uint16');
    fclose(fid);
    %new_img = 1023 - img(:, 33:544); 
    LB_new_img = bitshift((1023 - img(:, 33:544)), -2);
    HB_new_img = bitand((1023 - img(:, 33:544)), 3);
    img_10b_noninvert = LB_new_img + HB_new_img*256;
end