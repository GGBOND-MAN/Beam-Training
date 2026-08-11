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
Rmin = 5;
Rmax = 30;
theta_min = -pi / 3;
theta_max =  pi / 3;

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
SNR_dB_list=[-4:2:20];
SNR_list = 10.^(SNR_dB_list/10.);
SNR_len = length(SNR_dB_list);
N_iter = 200;
rate_near_2d  = zeros(length(SNR_list),N_iter);
rate_elip = zeros(length(SNR_list),N_iter);
rate_rate_near_match = zeros(length(SNR_list),N_iter);
rate_opt = zeros(length(SNR_list),N_iter);
rate_near_match= zeros(length(SNR_list),N_iter);
for idx = 1:SNR_len
    SNR_dB = SNR_dB_list(idx);
    SNR_t = SNR_list(idx);
    for i_iter = 1:N_iter
        i_iter
        r = Rmin + rand * (Rmax - Rmin);
        theta = theta_min + rand * (theta_max - theta_min);
        [h, hc] = near_field_channel(Nt, d, fc, B, M, r, theta);
        %% 近场2D彩虹
        rate_near_iter_2d = training_near_rainbow_2d(Nt, B, fc, f, M, d, h, w_2D_near,focus_loc, SNR_t, SNR_dB, Q,k);
        rate_near_2d(idx, i_iter) = rate_near_iter_2d(k);
        %% match_filter + 近场2D彩虹
        rate_near_iter_match = training_near_rainbow_match(Nt, B, fc, f, M, d, h, w_2D_near,focus_loc, SNR_t, SNR_dB, Q,k,match_y,g1_list,g2_list);
        rate_near_match(idx, i_iter) = rate_near_iter_match(k);
        %% 椭圆相交
        rate_elip_iter = training_near_rainbow_elip(Nt, B, fc, f, M, d, h, w_2D_near,focus_loc, SNR_t, SNR_dB, Q,k);
        rate_elip(idx, i_iter) = rate_elip_iter(k);
        %% 理论上界
        wc_opt = exp(1j*angle(hc'))/sqrt(Nt);
        array_gain = abs(hc * wc_opt)^2;
        rate_opt(idx, i_iter) = log2(1 + SNR_t * array_gain);
    end
end
rate_near_2d = mean(rate_near_2d,2);
rate_near_match = mean(rate_near_match,2);
rate_opt = mean(rate_opt,2);
rate_elip = mean(rate_elip,2);
%% 
C = linspecer(8);
maker_num = 25;
figure; hold on; box on; grid on;
p1 = plot(SNR_dB_list(1:SNR_len), rate_opt(1:SNR_len), '--', 'color',C(2, :) , 'Linewidth', 1.6,'MarkerFaceColor','w');
p2 = Plot(SNR_dB_list(1:SNR_len), rate_near_2d(1:SNR_len),maker_num, '-s','color', C(3, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p3 = Plot(SNR_dB_list(1:SNR_len), rate_near_match(1:SNR_len),maker_num, '->', 'color', C(6, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
p4 = Plot(SNR_dB_list(1:SNR_len), rate_elip(1:SNR_len),maker_num, '-s', 'color', C(7, :), 'Linewidth', 1.6,'MarkerFaceColor','w');
xlabel('SNR', 'fontsize', 14, 'interpreter', 'latex')
ylabel('Average Rate (bit/s/Hz)', 'fontsize', 14, 'interpreter', 'latex')
legend([p1,p2,p3,p4],{'Perfect CSI',  'Proposed beam training', ...
     'Proposed beam training with match filter','Proposed beam training with auxiliary beam '}, 'interpreter', 'latex', 'fontsize', 12);
ylim([0, max(rate_opt)*1.08])