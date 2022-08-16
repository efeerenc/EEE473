%% HW 2
x_val = linspace(-0.3,0.3,512);

%% empty intensities
intensity_1 = [];
intensity_2 = [];           

%% generate intensities
% by the way, code runs poorly because i had some problems while
% vectorizing it, so instead of debugging it i just used two for loops, it
% takes max 1 mins to compile.
for i = 1:size(x_val,2)

    fun1 = @(z) rectangularPulse((z-0.55)/0.1)*rectangularPulse(z*x_val(i)/((2*z/sqrt(3))-(1/sqrt(3))));
    fun2 = @(z) rectangularPulse((z-0.85)/0.1)*rectangularPulse(z*x_val(i)/((2*z/sqrt(3))-(16/(10*sqrt(3)))));
    
    intensity_1(end+1) = ((1/(1+(x_val(i))^2))^(3/2)).*exp((-10/((1/(1+(x_val(i))^2))^(1/2)))*integral(fun1,0,1));
    intensity_2(end+1) = ((1/(1+(x_val(i))^2))^(3/2)).*exp((-10/((1/(1+(x_val(i))^2))^(1/2)))*integral(fun2,0,1));
 
end

%% figures
figure;
plot(x_val, intensity_1);
xlabel("x (m)");
ylabel("I_d(x,0)/I_0");
title("First normalized intensity profile");

figure;
plot(x_val, intensity_2);
xlabel("x (m)");
ylabel("I_d(x,0)/I_0");
title("Second normalized intensity profile");

