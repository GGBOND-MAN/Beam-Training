function [rate_far,array] = training_far_rainbow(Nt, B, fc,f, M, d, h, w_delay_far,theta1,theta2, SNR_t, SNR_dB, Q)
    rate_far = 0;
    array = 0;
    y_far = zeros(M,Q);
    for m = 1:M
       temp = awgn( repmat( h(m, :) * w_delay_far(:, m), [1, Q] ), SNR_dB);
       y_far(m, :) =  temp;
    end
    y_far = abs(sum( y_far, 2 )).^2;
    % 计算topk远场角度
    [v_far, i] = max(  y_far );
    theta_hat_far = asin( theta1+theta2 * fc / f(i) );

    % 计算速率
    w_far = TTD_beam(Nt, B, fc, M, d, sin(theta_hat_far), 0);
    for m = 1:M
        rate_far = rate_far + log2(1 + SNR_t * abs(h(m, :) * w_far(:, m))^2 ) / M;
        array = array + abs(h(m, :) * w_far(:, m))^2 / M;
    end
end