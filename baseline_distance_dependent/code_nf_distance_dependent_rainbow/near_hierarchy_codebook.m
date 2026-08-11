clc; 
clear all
close all


N = 256; % the number of the antennas at the BS

c = 3e8; %the speed of light
fc = 30e9; % the frequency
lambda = c/fc; %the wave length
d = 0.5*lambda; % the antenna spacing lambda/2

%Rayleigh_dis = 2 * (N*d)^2/lambda


%%% 生成普通近场码本
rho_min = 3;
%rho_max = Rayleigh_dis*0.375;
s = 1;
uniform = 1;
delta = 1.32;
grid_r = 16;
%theta_min = -pi / 3;
%theta_max =  pi / 3;

[near_codebook,po_label,theta,r] = generate_near_field_codebook2(N, s, d, lambda, delta, rho_min, uniform,grid_r);
near_codebook = near_codebook';

overhead_max = size(near_codebook,1);

[near_codebook_W1,recordW1] = GS_wb_design_withCIN_512(fc,near_codebook,1,po_label,theta,r);
[near_codebook_W2,recordW2] = GS_wb_design_withCIN_512(fc,near_codebook,2,po_label,theta,r);

save near_codebook_W3.mat near_codebook
save po_label.mat po_label
save near_codebook_W1.mat near_codebook_W1
save near_codebook_W2.mat near_codebook_W2
save recordW1.mat recordW1
save recordW2.mat recordW2