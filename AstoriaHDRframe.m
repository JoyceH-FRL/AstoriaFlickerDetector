%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Astoria HAR include PD, FD and TTS
% this function will paser 3 ADC images for analysis
% input image data format is 10-bit,2 bytes image
% image signal need to be dark as small value, saturated as big value
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [PD_img, FD_img, TTS_img] = AstoriaHDRframe(img_array, imgX, imgY)
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