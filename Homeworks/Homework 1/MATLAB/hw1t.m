P = phantom("Modified Shepp-Logan",500);

%%
%part a

figure;
imshow(P);
title("Figure 5.1.1 Phantom in spatial domain");

spectrum = fft2c(P);

figure;
imshow(log(abs(spectrum)+1), []);
title("Figure 5.1.2 Magnitude of the spectral domain");

%%
%part b

%i
basis = linspace(-10,10,500);

x1 = (1-abs(basis/3)).*(abs(basis) <= 3);
y1 = (1-abs(basis/8)).*(abs(basis) <= 8);

[X1, Y1] = meshgrid(x1, y1);

%h1
h1 = X1.*Y1;
figure;
imshow(h1);
title("Figure 5.2.1 PSF h_1");

%H1
H1 = fft2c(h1);
figure;
imshow(log(abs(H1)+1), []);
title("Figure 5.2.2 Transfer function |H_1|");

%%
%ii
basis = linspace(-6,6,500);

x2 = (1/(2*pi)).*(exp(-(basis.^2)./2));
y2 = (1/(2*pi)).*(exp(-(basis.^2)./2));

[X2, Y2] = meshgrid(x2, y2);

%h2
h2 = X2.*Y2;
figure;
imshow(h2, []);
title("Figure 5.3.1 PSF h_2");

%H2
H2 = fft2c(h2);
figure;
imshow(log(abs(H2)+1), []);
title("Figure 5.3.2 Transfer function |H_2|");

%%
%iii
basis = linspace(-10,10,500);

x3 = sinc(basis/8);
y3 = sinc(basis/3);

[X3, Y3] = meshgrid(x3, y3);

%h3
h3 = X3.*Y3;
figure;
imshow(h3, []);
title("Figure 5.4.1 PSF h_3");

%H3
H3 = fft2c(h3);
figure;
imshow(log(abs(H3)+1), []);
title("Figure 5.4.2 Transfer function |H_3|");

%%
%part c

%first imaging system
spectrum1 = spectrum.*H1;

figure;
imshow(log(abs(spectrum1)+1), []);
title("Figure 5.5.1 Output of system 1 in the spectral domain (magnitude)");

output1 = ifft2c(spectrum1);

figure;
imshow(output1, []);
title("Figure 5.5.2 Output image of system 1");

%%
%second imaging system
spectrum2 = spectrum.*H2;

figure;
imshow(log(abs(spectrum2)+1), []);
title("Figure 5.6.1 Output of system 2 in the spectral domain (magnitude)");

output2 = ifft2c(spectrum2);

figure;
imshow(output2, []);
title("Figure 5.6.2 Output image of system 2");

%%
%third imaging system
spectrum3 = spectrum.*H3;

figure;
imshow(log(abs(spectrum3)+1), []);
title("Figure 5.7.1 Output of system 3 in the spectral domain (magnitude)");

output3 = ifft2c(spectrum3);

figure;
imshow(output3, []);
title("Figure 5.7.2 Output image of system 3");