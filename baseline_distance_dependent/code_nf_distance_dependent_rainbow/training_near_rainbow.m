function [rate_near,array] = training_near_rainbow(Nt, B, fc, f, M, d, S, h, w_delay_near, alpha_near, SNR_t, SNR_dB, Q,theta1_near,theta2_near)
    rate_near = zeros(S, 1);
    for idx = 1:S
        y_near = zeros(M,Q);
        for m = 1:M
            temp = awgn( repmat( h(m, :) * w_delay_near(:, idx, m), [1, Q] ), SNR_dB);
            y_near(m, :) =  temp;
        end
        y_near = abs( sum( y_near, 2 ) ).^2;

        % 计算有效近场角度和距离
        [~, i] = max(y_near);

        theta_hat_near = asin( theta1_near+theta2_near * fc / f(i) );
        r_hat_near = cos(theta_hat_near)^2 / 2 / alpha_near(idx);


        % 计算速率
        w_near = TTD_beam(Nt, B, fc, M, d, sin(theta_hat_near), alpha_near(idx));
        temp = 0;
        array_temp = 0;
        for m = 1:M
            temp = temp + log2(1 + SNR_t * abs(h(m, :) * w_near(:, m))^2 ) / M;
            array_temp = array_temp + abs(h(m, :) * w_near(:, m))^2 / M;
        end
        if idx == 1
           rate_near(idx) = temp;
           array = array_temp;
        else
           rate_near(idx) = max([rate_near(idx-1); temp]);
           array = max([array;array_temp]);
        end         
    end
end