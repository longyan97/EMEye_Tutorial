%% 
% This demo shows a simplfied version of the EM Eye image reconstrction
% process using simulated EM waveform generated from a RAW image captured
% by the RPI camera v1.  



%% Step 1: Prepare the image data. 
% There is already a sample image in the ./data folder. If you want to
% prepare you own image data, you need to: 
% First, take a jpg of rpi camera that contains RAW data using the command. Note it is full sensor resolution 
% Second, extract the RAW image from jpg using: raspi_dng.exe in.jpg out.dng, raspi_dng is provided in ./util 
 

%% Step 2: Simulate the transmitted bits and EM waveform from given RAW image

addpath('./util')

fs = 1e9;                    % simulation sample rate
np = 33e6;                   % simulated sample points (1 frame)

res_csi = f_csi_time2bit(np, fs);         % CSI indexing
 
dat_org = zeros(np, 1);                   % stores the bit waveform transmitted 

idx = 1:np;
valid_idx = res_csi.valid(idx) == 1;
dat_org(~valid_idx) = 5;                  % unimportant value of blanking voltage

% Adjust indexing. Not important. 
row = res_csi.i_r(idx) + 1; 
col0 = res_csi.i_c0(idx) + 1;
bit0 = res_csi.i_b0(idx) + 1;
col1 = res_csi.i_c1(idx) + 1;
bit1 = res_csi.i_b1(idx) + 1;

% Get the index of transmitted bits on the two wires 
ind0 = sub2ind([1080,1920,10], row(valid_idx), col0(valid_idx), bit0(valid_idx));
ind1 = sub2ind([1080,1920,10], row(valid_idx), col1(valid_idx), bit1(valid_idx));


% Decoding the RAW image taken by rpi cam v1
ww = 2592;
hh = 1944;
offset = 54102/2;
name = './data/room.dng';
ii = fopen(name);  
data = fread(ii, '*ubit16', 0, 'b');     % Endian, can be either l or b, computer-dependent 
fclose(ii);
data = data(1+offset:offset+ww*hh);
data = permute(reshape(data, ww, hh), [2,1,3]);
data_1080p = data(433:1512, 337:2256);

% Covert RAW image to binary
data_bi = de2bi(data_1080p(:), 16, 'left-msb'); 
data_bi = data_bi(:,10:-1:1);   % LSB transmitted first
data_bi = double(data_bi);
data_bi = reshape(data_bi, 1080, 1920, []);


% Plot the decoded RAW image within the 1080p area
% Compare it with the binary to double check if the decoding is correct
% If you get a gray noisy image, try adjusting 'l' and 'b'
figure; imshow(data_1080p); 

disp_img = reshape(bi2de(reshape(data_bi, [], 10)), 1080, 1920);
disp_img = disp_img / max(disp_img(:));
figure; imshow( disp_img ); 


% Finally, get the transmitted bits on the two wires
line0 = data_bi(ind0);
line1 = data_bi(ind1);

% This is the simultaed EM waveform transmitted 
% The waveform can be any linear combination of the two wires'
% bits, subjected to other transfer functions that are dependent on the actal 
% environmental conditions. For simplicity, you may just
% use line0 + line1 or line0 to represent the waveform. 

dat_org(valid_idx) = line0 + line1; 

figure; plot(dat_org(1:8.5e4))     % Plots the first three rows transmitted 


%% Step 3: Reconstruct the image from the bit stream 

% Here we are demodulating the reconstructing the simulated EM data stored
% in dat_org. Note that dat_org can be replaced with real EM data if you
% collect it with a o-scope like a PicoScope with a 1 GHz sampe rate. The
% process below simulates the IQ demodulation of USRP and image
% reconstruction procedure. Note that besides IQ amplitude demod, other
% demod methods such as envelope detection can also be used. 

fc = 255e6;        % demod center frequency, tunable  
fb = 20e6;         % demod bandwidth (two-sided), tunable
z = iqdemod(dat_org, fc, fb, fs);

emhead =  1;       % where the transmission starts 

fnum = 1;          % number of frames
rolnum = 1080;     % number of rows of each recon, fixed, equals the value of RAW image 
colnum = 800;      % number of columns, tunable, should be smaller than the RAW image

% Below are the measured transmission blanking parameters 
frm_sep = 33311675;
row_len = 26200;
row_sep = 29590;    
col_len = floor(row_len/colnum);
col_sep = col_len;

% stores the image stream recon from amplitude demod signals
recimg_am = zeros(fnum, rolnum, colnum);

for i_frm = 1:fnum
    frame_start = (i_frm-1)*frm_sep + emhead;
    for i_rol = 1:rolnum
        disp(['frame ', num2str(i_frm), ' rol ', num2str(i_rol)])
        row_start = (i_rol-1)*row_sep + frame_start;
        for i_col = 1:colnum
            col_start = round((i_col-1)*col_sep + row_start);
            col_end = round((i_col-1)*col_sep + row_start + col_len);
            
            seg = z(col_start:col_end);
            recimg_am(i_frm, i_rol, i_col) = median(seg);
        end
    end
end


recimg_all = {recimg_am};
names = {'Amplitude Demod'};
for i = 1:length(recimg_all)
    recimg = recimg_all{i};
    recimg = squeeze(mean(recimg, 1));
    recimg = recimg(:,1:722);
    recimg = imresize(recimg, [480, 640]);
%     recimg = 1 - recimg;       % if it needs polarity inversion 
    recimg = histeq(recimg);
    figure; imshow(recimg); title([names{i}, '  num of col: ', num2str(colnum), ...
        ', fc=', num2str(fc/1e6), ', fb=', num2str(fb/1e6)])
end

