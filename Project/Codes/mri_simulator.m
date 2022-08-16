% EEE 473/573 Medical Imaging Term Project
% MRI Simulator
% Efe Eren Ceyani 21903359
% Batuhan Uykulu 21802986
% Mert Altunsoy 22101161

%% Simulation
%%%%%%%%%%%%%%%%%%%%%%%% Control simulation parameters from here, then
%%%%%%%%%%%%%%%%%%%%%%%% execute the program.

contrast = "T2"; % Possible choices: "T1", "T2", "PD".

% Non-ideal conditions:
b_inhomogeneity = false;
t2_star = false;

noise = false;
noise_mean = 0;
noise_variance = 10^(-58); % Suggested range for the variance: 10^(-60) - 10^(-58).
rect_x = 100;
rect_y = 100;

% Artifacts.
spike_noise = false;
spike_noise_array = [100 100];
spike_noise_strength = 10^(-24); % Advised range for exponential: -25 to -20.

wrap_around = false;
wrap_around_strength_x = 0.75; % Ranges from 0 to 1. 1 --> Nothing changes |||| close to 0 --> a lot of wrapping.
wrap_around_strength_y = 0.75;
wrap_around_x = true;
wrap_around_y = false;

% Scanning parameters are from the course book.
% Short TE, Medium TR.
T1_TE = 15;
T1_TR = 600;

% Medium TE, Long TR.
T2_TE = 100;
T2_TR = 6000;

% Short TE, Long TR.
PD_TE = 15;
PD_TR = 6000;

% Scanning parameters for T2_star.
T2_STAR_TE = 30;
T2_STAR_TR = 3500;

% You may change fov's to observe wrap-around artifact but it is better to
% change it from the settings of wrap_around.
fov_x = 181; 
fov_y = 217;
flip_angle = pi/2; % We haven't tried another value other than pi/2.
slice_center = 90; % Possible choices: 1-181. Default is 90.
slice_thickness = 1; % Possible choices: 1, 3, 5 (unit is mm).


%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize Parameters

% General NMR & MRI parameters:
B0 = 1.5; % Tesla.
BOLTZMANN = 1.381*10^(-23); % Joule/Kelvin.
GYRO = 42.58*10^6; % MHz/Tesla, for 1H.
PLANCK = 6.626*10^(-34); % Joule-seconds.
TEMPERATURE = 4; % Kelvin.
SAMPLING_FREQ = 100000; % Hz.

% Normal brain model: https://brainweb.bic.mni.mcgill.ca/brainweb/anatomic_normal.html
% In total there are 10 types of tissues (ranging from 0 to 9)
% In order, these are the brain tissue labels:
% Background, CSF, Grey Matter, White Matter, Fat, Muscle/Skin, Skin
% Skull, Glial Matter, and Connective.
% For these tissues, T1, T2, T2*, and PD can be found in:
% https://brainweb.bic.mni.mcgill.ca/brainweb/tissue_mr_parameters.txt
T1_VAL = [0, 2569, 833, 500, 350, 900, 2569, 0, 833, 500];
T2_VAL = [0, 329, 83, 70, 70, 47, 329, 0, 83, 70];
T2_STAR_VAL = [0, 58, 69, 61, 58, 30, 58, 0, 69, 61];
PD_VAL = [0, 1, 0.86, 0.77, 1, 1, 1, 0, 0.86, 0.77];

%% Load Data

% Load the data using 'loadminc.m'.
% Written by: Laszlo Balkay
% https://www.mathworks.com/matlabcentral/fileexchange/32644-loadminc
[data, scan_info] = loadminc('phantom_1.0mm_normal_crisp.mnc');

% Initialize contrast maps with the size of the original data.
brain_map = zeros(size(data));
T1_map = zeros(size(data));
T2_map = zeros(size(data));
PD_map = zeros(size(data));

% Choose imaging contrast.
switch contrast
    case "T1"
        contrast_val = T1_VAL;
        TE_scan = T1_TE;
        TR_scan = T1_TR;
    case "T2"
        contrast_val = T2_VAL;
        TE_scan = T2_TE;
        TR_scan = T2_TR;
    case "PD"
        contrast_val = PD_VAL;
        TE_scan = PD_TE;
        TR_scan = PD_TR;
end

% Create the proper time decay map corresponding to the chosen contrast.
for tissue_label = 1:10
    brain_map(data==tissue_label-1) = contrast_val(tissue_label);
    T1_map(data==tissue_label-1) = T1_VAL(tissue_label);
    T2_map(data==tissue_label-1) = T2_VAL(tissue_label);
    PD_map(data==tissue_label-1) = PD_VAL(tissue_label);
end

%% Slice Selection

% Create ideal rectangular pulse centered around slice_center, with 
% width of slice_thickness, and amplitude of flip_angle.
z_s = linspace(0,size(brain_map, 3),size(brain_map, 3));

rectangular = zeros(size(brain_map, 3));
rectangular(abs(z_s-slice_center)./(slice_thickness) <= (1/2)) = flip_angle;

% Choose slice using the RF pulse.
% "rectangular" array has the flip angles of each location and the ones which
% are larger than 0 are selected.
brain_map_sliced = brain_map(:,:,rectangular > 0);
T1_map = T1_map(:,:,rectangular > 0);
T2_map = T2_map(:,:,rectangular > 0);
PD_map = PD_map(:,:,rectangular > 0);

%% K-space Acquisition

% Initialize k-space matrix. Unless the FOV is altered, x-space will range
% between -90 and 90, and y-space will range between -108 and 108. These
% values come from the size of the dataset.
xspace = linspace(-(size(brain_map, 2)-1)/2, (size(brain_map, 2)-1)/2, size(brain_map, 2));
yspace = linspace(-(size(brain_map, 1)-1)/2, (size(brain_map, 1)-1)/2, size(brain_map, 1));
[kx, ky] = meshgrid(xspace, yspace);

% Wrap around artifact.
% Essentially, this statement modifies the FOV value.
if wrap_around
    if wrap_around_x
        fov_x = round(fov_x*wrap_around_strength_x);
    end
    if wrap_around_y
        fov_y = round(fov_y*wrap_around_strength_y);
    end
end

% Now, we can find proper gradient values since we have FOV values.
% Readout and phase encoding gradient value.
% From lecture note 13, page 18.
G_x_value = SAMPLING_FREQ/(GYRO*fov_x);
A_y = 1/(GYRO*fov_y);

% T2_star.
% Same procedures were used, so no explanation.
if t2_star
    T2_star_map = zeros(size(data));
    for tissue_label = 1:10
        T2_star_map(data==tissue_label-1) = T2_STAR_VAL(tissue_label);
    end
    T2_star_map = T2_star_map(:,:,rectangular>0);
    T2_map = T2_star_map;
    if contrast == "T2"
        TE_scan = T2_STAR_TE;
        TR_scan = T2_STAR_TR;
    end
end

% Effective spin density.
if b_inhomogeneity
    % Load the magnetic inhomogeneity model.
    % We had found three different magnetic fields for each contrast
    % mechanism, however, using any of the fields for any of the contrast
    % would work fine.
    switch contrast
        case "T1"
            b_matrix = loadminc("t1_inhomogeneity.mnc");
        case "T2"
            b_matrix = loadminc("t2_inhomogeneity.mnc");
        case "PD"
            b_matrix = loadminc("pd_inhomogeneity.mnc");
    end
    % Acquire the correct slice of the inhomogeneous magnetic field.
    b_matrix = b_matrix(:,:,rectangular>0);
    % Calculate magnetization with inhomogeneous magnetic field.
    M0 = ((abs(b_matrix).*((2*pi*GYRO)^2)*(PLANCK^2))/(4*BOLTZMANN*TEMPERATURE)).*PD_map;
    % Calculate effective spin density with respect to the new
    % magnetization.
    esd = M0.*sin(flip_angle).*(exp(-TE_scan./T2_map)).*(1-exp(-TR_scan./T1_map))./(1-cos(flip_angle)*exp(-TR_scan./T1_map));
else
    % Calculate Magnetization
    M0 = ((B0*((2*pi*GYRO)^2)*(PLANCK^2))/(4*BOLTZMANN*TEMPERATURE)).*PD_map;
    % Calculate effective spin density.
    esd = M0.*sin(flip_angle).*(exp(-TE_scan./T2_map)).*(1-exp(-TR_scan./T1_map))./(1-cos(flip_angle)*exp(-TR_scan./T1_map));
end

% View effective spin density.
figure;
imshow(esd(:,:,1), []);
title("Effective spin density");

% Noise.
if noise
    % Creates noised image with desired mean & variance.
    esd_noise = imnoise(esd, "gaussian", noise_mean, noise_variance);
    figure;
    imshow(esd_noise(:,:,1), []);
    title("Effective spin density with Gaussian noise");
    % Switch to noisy effective spin density.
    esd = esd_noise;
end

% Initialize baseband array.
baseband = zeros(fov_y, fov_x);

% Acquire baseband signal.
% For every y-space element,
for y = 1:fov_y
    % For every x-space element,
    for x = 1:fov_x     
        % Calculate the corresponding baseband signal coming from the
        % effective spin density.
        baseband(y, x) = sum(sum(esd.*exp(-1i*2*pi*GYRO*(G_x_value*(kx.*x/SAMPLING_FREQ - fov_x/(2*SAMPLING_FREQ)) + A_y*ky.*(y-fov_y/2)))));
    end
end

% Organize the k-space array.
kspace = fftshift(baseband, 2);

% Spike noise artifact.
if spike_noise
    for index = 1:size(spike_noise_array, 1)
        % Update points in the k-space according to the simulation
        % parameters.
        spike_point_u = spike_noise_array(2*(index-1)+1);
        spike_point_v = spike_noise_array(2*(index-1)+2);        
        kspace(spike_point_u, spike_point_v) = kspace(spike_point_u, spike_point_v) + spike_noise_strength;
    end
end

% View k-space.
figure;
imshow(log(abs(kspace)), []);
title("K-space data");

%% Image Reconstruction
% Take the inverse 2D-FT of k-space.
image = ifftshift(ifft2(kspace));
figure;
imshow(abs(image), []);
title("Reconstructed image");

if noise
    if wrap_around
        % Rebuild k-space with the updated FOV.
        % This step is essential if the user wants to run noise and
        % wrap_around at the same time.
        xspace = linspace(-round((fov_x-1)/2), round((fov_x-1)/2), fov_x);
        yspace = linspace(-round((fov_y-1)/2), round((fov_y-1)/2), fov_y);
        [kx, ky] = meshgrid(xspace, yspace);
    end
    xdim = abs(xspace) <= rect_x/2;
    ydim = abs(yspace) <= rect_y/2;
    
    % Create a rectangular filter.
    [xrect, yrect] = meshgrid(xdim, ydim);
    rect_filter = (xrect == 1).*(yrect==1);
    
    % Apply filter.
    kspace_filtered = kspace.*rect_filter;
    
    figure;
    imshow(log(abs(kspace_filtered)), []);
    title("K-space passed through a low pass filter");
    
    % Recontruct the filtered image
    image_filtered = ifftshift(ifft2(kspace_filtered));
    
    figure;
    imshow(abs(image_filtered), []);
    title("Reconstructed image using the filtered k-space");
    
end