P = double(rgb2gray(imread('vessel_and_catheter.png')));
%a
imshow(P, []);
title("Phantom");

%b
theta = 0:0.25:180;
[R, xp] = radon(P, theta);

figure;
imshow(R,[], 'XData', theta);
title("Sinogram");
xlabel('\theta (degrees)')
ylabel('L')
axis on;

recon = iradon(R, theta);

figure;
imshow(recon, []);
title("Reconstructed image");

%c
proj0 = R(:,find(theta == 0));
proj45 = R(:,find(theta == 45));
proj90 = R(:,find(theta == 90));
proj135 = R(:,find(theta == 135));

figure;
plot(proj0);
title("Projection at 0 degrees");
xlim tight;

figure;
plot(proj45);
title("Projection at 45 degrees");
xlim tight;

figure;
plot(proj90);
title("Projection at 90 degrees");
xlim tight;

figure;
plot(proj135);
title("Projection at 135 degrees");
xlim tight;

%d
theta_less = 0:2:180;
R_less = radon(P, theta_less);
figure;
imshow(R_less, [], 'XData', theta_less);
title("Sinogram with fewer projections");
xlabel('\theta (degrees)')
ylabel('L')
axis on;

recon_alias = iradon(R_less, theta_less);

figure;
imshow(recon_alias, []);
title("Reconstructed image with streak artifact");
%this is called streak artifact

%e
recon_default = iradon(R, theta, 'linear');
figure;
imshow(recon_default, []);
title("Ram-Lak filter");

recon_hamming = iradon(R, theta, 'linear', 'Hamming');
figure;
imshow(recon_hamming, []);
title("Hamming filter");

recon_nothing = iradon(R, theta, 'linear', 'none');
figure;
imshow(recon_nothing, []);
title("No filter");

%f
recon_default_alias = iradon(R_less, theta_less, 'linear');
figure;
imshow(recon_default_alias, []);
title("Ram-Lak filter with fewer projections");

recon_hamming_alias = iradon(R_less, theta_less, 'linear', 'Hamming');
figure;
imshow(recon_hamming_alias, []);
title("Hamming filter with fewer projections");

recon_nothing_alias = iradon(R_less, theta_less, 'linear', 'none');
figure;
imshow(recon_nothing_alias, []);
title("No filter with fewer projections");