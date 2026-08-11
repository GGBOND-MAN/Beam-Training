function [dict, label, theta, r] = generate_near_field_codebook2(N, s, d, lambda_c, delta, rho_min,uniform,grid_r)
    c = 3e8;
    fc = c/lambda_c;
    theta = -1 + 2/N : 2/N : 1;
    S = length(theta);
    dict = cell(S, 1);
    label = cell(S, 1);
    Z = (N * d)^2 / 2 / lambda_c/delta;
    %kmin = floor(Z/rho_max) + 1;
    
     if uniform == 1
            kmax = grid_r-1;  %%%距离均匀划分的格点数
            r = zeros(1, grid_r);
            %r(:,1) = 200 * N^2 * d^2 / lambda_c;
            r(:,1) = 500;
            r(:,2:end) = (kmax:-1:1)*Z/kmax;
     end
     
%      r = sort(r);
     
     for idx = 1:grid_r  
            dict{idx} = zeros(N, S);
            label{idx} = zeros(2, S);
        for t = 1 : S          
            dict{idx}(:, t) = sqrt(N)*near_field_manifold( N, d, fc, r(idx), asin(theta(t)) );
            label{idx}(:, t) = [theta(t), r(idx)]';
        end
    end
    dict_cell = dict;
    label_cell = label;
    dict = merge(dict, grid_r, N);
    label = merge(label,grid_r, 2);
end

function B = merge(A, N, Q)
    S = zeros(1, N);
    for idx = 1:N
        S(idx) = size(A{idx}, 2);
    end
    B = zeros(Q, sum(S));
    for idx = 1:N
        B(:, sum(S(1:idx)) - S(idx) + 1: sum(S(1:idx))) = A{idx};
    end
end