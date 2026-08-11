clear all;clc;
Nt = 256;
fc = 30e9;
c = 3e8;
B = 5e9;
lambda_c = c/fc;
d = lambda_c / 2;
M = 1024;
Q = 1;
f = zeros(1, M);
N_iter = 20;
for m= 1:M
    f(m)=fc+B/(M)*(m-1-(M-1)/2);
end
theta_min = -pi / 3;
theta_max =  pi / 3;

%% 远场宽带码字
[w_delay_far, theta1_far,theta2_far] = delay_angle_beam(Nt,theta_max, theta_min, B, fc, M, d);
overhead1 = 1;

%% 近场宽带码字
rho_min = 5;
delta = 1.32;
[w_delay_near, theta1_near,theta2_near, alpha_near] = delay_polar_beam(Nt, theta_max, theta_min, B, fc, M, d, rho_min, delta);
S = size(alpha_near, 1);
overhead2 = S;

%% 近场窄带码字
s = 1;
[w_phase_near, sin_theta_near_nb, r_near_nb] = PolarCode(Nt, s, d, lambda_c, delta, rho_min, theta_min, theta_max);
w_phase_near = conj(w_phase_near);
D2 = length(sin_theta_near_nb);
S2 = length(r_near_nb);
overhead3 = S2*D2;

%% 近场分层码本
load('near_codebook_W1.mat') %第一层
load('recordW1.mat')
load('near_codebook_W2.mat') %第二层
load('recordW2.mat') 
load('near_codebook_W3.mat') %第三层
load('po_label.mat') 
overhead5 = 32*4+8+4;

%% 近场两阶段
m=5;
overhead6 = S2*m+D2;

%% 跳变彩虹码字
k = 3;
theta1 = 349/11; theta2 = -30;
alpha1 = -427/800; alpha2 = 1859/3200;
focus_loc = cal_loc(fc,f,theta1,theta2,alpha1,alpha2,M,k);
w_2D_near = delay_polar_2d(Nt, B, fc, M, d,theta1,theta2,alpha1,alpha2,k);
overhead4 = k;

%%  match filter 
g1 = 1024; g1_list = linspace(sin(theta_min),sin(theta_max),g1);
g2 = 10;  g2_list = linspace(1/400,1/10,g2);
match_y = zeros(g1,g2,k,M,Q);
parfor i =1:g1
    for j = 1:g2
        w_near = TTD_beam(Nt, B, fc, M, d, g1_list(i), g2_list(j));
        mf=w_near';
        for t = 1:k
            y_near = zeros(M,Q);
            for m = 1:M
                a_mf = mf(m, :);
                temp = repmat( a_mf * w_2D_near(:, t, m), [1, Q] );
                y_near(m, :) =  temp;
            end
            y_near = abs( sum( y_near, 2 ) ).^2;
            match_y(i,j,t,:,:) = y_near;
        end
    end
end

%% 合速率参数
overhead = 1: max([overhead1, overhead2, overhead3,overhead4,overhead5,overhead6]);
overhead_max = length(overhead);
array_far = zeros(1,N_iter);
array_near_ex = zeros(1,N_iter);
array_near_hier = zeros(1,N_iter);
array_near_2stage = zeros(1,N_iter);
array_near_1d = zeros(1,N_iter);
array_near_2d = zeros(1,N_iter);
array_near_match = zeros(1,N_iter);
Rmin = 5;
Rmax = 30;
N_iter = 1000;
SNR_dB = 15;
SNR_t = 10^(SNR_dB/10);
for i_iter = 1:N_iter
    r = Rmin + rand * (Rmax - Rmin);
    theta = theta_min + rand * (theta_max - theta_min);
    [h, hc] = near_field_channel(Nt, d, fc, B, M, r, theta);
    
    %% 近场1D彩虹
    [rate_near_iter,array] = training_near_rainbow(Nt, B, fc, f, M, d, S, h, w_delay_near, alpha_near, SNR_t, SNR_dB, Q,theta1_near,theta2_near);
    array_near_1d(1, i_iter) = array;
    
    %% 远场彩虹
    [rate_far_iter,array] = training_far_rainbow(Nt, B, fc,f, M, d, h, w_delay_far,theta1_far,theta2_far, SNR_t, SNR_dB, Q);
    array_far(1, i_iter) = array;
    
    %% 近场遍历
    [rate_near_ex_iter,array] = training_near_exhaustive(D2, S2,  hc, w_phase_near,SNR_t, SNR_dB, Q, M, overhead_max);
    array_near_ex(1, i_iter) = array;
    
    %% match_filter + 近场2D彩虹
    [rate_near_iter_match,array] = training_near_rainbow_match(Nt, B, fc, f, M, d, h, w_2D_near,focus_loc, SNR_t, SNR_dB, Q,k,match_y,g1_list,g2_list);
    array_near_match(1, i_iter) = array;
    
    %% 近场分层
    [rate_near_hier_iter,array] = training_near_hier(hc,near_codebook_W1,near_codebook_W2,near_codebook,recordW1,recordW2,po_label,SNR_t, SNR_dB, M, overhead_max);
    array_near_hier(1, i_iter) = array;
    
    %% 近场两阶段
    [rate_near_2stage_iter,array] = training_near_2stage(D2, S2,hc,w_phase_near,SNR_t, SNR_dB, M, overhead_max);
    array_near_2stage(1, i_iter) = array;
end

%% calculate cdf
cdf=0:0.05:1;
cdf_far = zeros(length(cdf),1);
cdf_near_ex =zeros(length(cdf),1);
cdf_near_hier =zeros(length(cdf),1);
cdf_near_2stage =zeros(length(cdf),1);
cdf_near_1d =zeros(length(cdf),1);
cdf_near_2d = zeros(length(cdf),1);
cdf_near_match = zeros(length(cdf),1);
for i =1:length(cdf)
    cdf_far(i) = length(find(array_far<cdf(i)))/N_iter;
    cdf_near_ex(i) = length(find(array_near_ex<cdf(i)))/N_iter;
    cdf_near_hier(i)=length(find(array_near_hier<cdf(i)))/N_iter;
    cdf_near_2stage(i)=length(find(array_near_2stage<cdf(i)))/N_iter;
    cdf_near_1d(i)=length(find(array_near_1d<cdf(i)))/N_iter;
    cdf_near_2d(i)=length(find(array_near_2d<cdf(i)))/N_iter;
    cdf_near_match(i)=length(find(array_near_match<cdf(i)))/N_iter;
end

%% 
C = linspecer(7);
maker_num = 25;
figure; hold on; box on; grid on;
p2 = Plot(cdf, cdf_near_1d,maker_num, '-o','color', C(6, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p3 = Plot(cdf, cdf_near_2stage,maker_num, '-s','color', C(3, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p4 = Plot(cdf, cdf_far,maker_num, '-d', 'color', C(4, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p5 = Plot(cdf, cdf_near_ex,maker_num, '-+', 'color', C(5, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p6 = Plot(cdf, cdf_near_match,maker_num, '->', 'color', C(1, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p7 = Plot(cdf, cdf_near_hier,maker_num, '->', 'color', C(7, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
legend([p6,p4,p2,p3,p5,p7],{'Proposed beam training with match filter', 'Far-field rainbow based training','Near-field rainbow based training','Inference from far-field beam training', 'Exhaustive training','Near-field hierarchical training'}, 'interpreter', 'latex', 'fontsize', 12);
xlabel('Normalized array gain', 'fontsize', 14, 'interpreter', 'latex')
ylabel('CDF', 'fontsize', 14, 'interpreter', 'latex')



