%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% input: file folder, filename, file size, image width (x), image height (y) and is it invert image
% invert image means 
% output image 2D array , (row , column), 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img_10b_noninvert] = MetaRAWconvert(folder, filename, size, imgX, imgY, invert)
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
    img_10b_noninvert = img_array;
end