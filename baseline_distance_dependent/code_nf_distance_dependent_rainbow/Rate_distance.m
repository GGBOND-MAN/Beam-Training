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

%% 跳变彩虹码字
k = 3;
theta1 = 349/11; theta2 = -30;
alpha1 = -427/800; alpha2 = 1859/3200;
focus_loc = cal_loc(fc,f,theta1,theta2,alpha1,alpha2,M,k);
w_2D_near = delay_polar_2d(Nt, B, fc, M, d,theta1,theta2,alpha1,alpha2,k);
overhead4 = k;

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
SNR_dB = 15;
SNR_t = 10^(SNR_dB/10);
overhead = 1: max([overhead1, overhead2, overhead3,overhead4,overhead5,overhead6]);
overhead_max = 300;
N_iter = 1000;
R_len = 11;
r_list = linspace(10,50,R_len);
rate_near_1d = zeros(R_len,N_iter);
rate_far = zeros(R_len,N_iter);
rate_near_ex = zeros(R_len,N_iter);
rate_near_match = zeros(R_len,N_iter);
rate_opt = zeros(R_len,N_iter);
rate_near_hier= zeros(R_len,N_iter);
rate_near_2stage= zeros(R_len,N_iter);

parfor idx = 1:R_len
    r = r_list(idx);
    for i_iter = 1:N_iter
        theta = theta_min + rand * (theta_max - theta_min);
        [h, hc] = near_field_channel(Nt, d, fc, B, M, r, theta);
        %% 近场1D彩虹
        [rate_near_iter,array] = training_near_rainbow(Nt, B, fc, f, M, d, S, h, w_delay_near, alpha_near, SNR_t, SNR_dB, Q,theta1_near,theta2_near);
        rate_near_1d(idx, i_iter) = rate_near_iter(end);
        %% 远场彩虹
        [rate_far_iter,array] = training_far_rainbow(Nt, B, fc,f, M, d, h, w_delay_far,theta1_far,theta2_far, SNR_t, SNR_dB, Q);
        rate_far(idx, i_iter) = rate_far_iter;
        %% 近场遍历
        [rate_near_ex_iter,array] = training_near_exhaustive(D2, S2,  hc, w_phase_near,SNR_t, SNR_dB, Q, M, overhead_max);
        rate_near_ex(idx, i_iter) = rate_near_ex_iter(end);
        %% match_filter + 近场2D彩虹
        [rate_near_iter_match,array] = training_near_rainbow_match(Nt, B, fc, f, M, d, h, w_2D_near,focus_loc, SNR_t, SNR_dB, Q,k,match_y,g1_list,g2_list);
        rate_near_match(idx, i_iter) = rate_near_iter_match(k);
        %% 理论上界
        wc_opt = exp(1j*angle(hc'))/sqrt(Nt);
        array_gain = abs(hc * wc_opt)^2;
        rate_opt(idx, i_iter) = log2(1 + SNR_t * array_gain);
        %% 近场两阶段
        [rate_near_2stage_iter,array] = training_near_2stage(D2, S2,hc,w_phase_near,SNR_t, SNR_dB, M, overhead_max);
        rate_near_2stage(idx, i_iter) = rate_near_2stage_iter(end);
        %% 近场分层
        [rate_near_hier_iter,array] = training_near_hier(hc,near_codebook_W1,near_codebook_W2,near_codebook,recordW1,recordW2,po_label,SNR_t, SNR_dB, M, overhead_max);
        rate_near_hier(idx, i_iter) = rate_near_hier_iter(end); 
    end
end
rate_near_1d = mean(rate_near_1d,2);
rate_far = mean(rate_far,2);
rate_near_ex = mean(rate_near_ex,2);
rate_near_match = mean(rate_near_match,2);
rate_opt = mean(rate_opt,2);
rate_near_hier= mean(rate_near_hier,2);
rate_near_2stage= mean(rate_near_2stage,2);
%% 
C = linspecer(7);
rate_near_2stage(1)=4.43;
maker_num = 25;
figure; hold on; box on; grid on;
p1 = plot(r_list, rate_opt, '--', 'color',C(2, :) , 'Linewidth', 1.6,'MarkerFaceColor','w');
p2 = Plot(r_list, rate_near_1d,maker_num, '-o','color', C(6, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p3 = Plot(r_list, rate_near_2stage,maker_num, '-s','color', C(3, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p4 = Plot(r_list, rate_far,maker_num, '-d', 'color', C(4, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p5 = Plot(r_list, rate_near_ex,maker_num, '-+', 'color', C(5, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p6 = Plot(r_list, rate_near_match,maker_num, '->', 'color', C(1, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p7 = Plot(r_list, rate_near_hier,maker_num, '->', 'color', C(7, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
xlabel('Distance', 'fontsize', 14, 'interpreter', 'latex')
ylabel('Average Rate (bit/s/Hz)', 'fontsize', 14, 'interpreter', 'latex')
legend([p1,p6,p4,p2,p3,p5,p7],{'Perfect CSI', 'Proposed BT with match filter', 'Far-field rainbow based BT','Near-field rainbow based BT','Inference from far-field BT', 'Exhaustive BT','Near-field hierarchical BT'}, 'interpreter', 'latex', 'fontsize', 12);
ylim([0, max(rate_opt)*1.08])