function rate_near = training_near_rainbow_2d(Nt, B, fc, f, M, d, h, w_2D_near,focus_loc, SNR_t, SNR_dB, Q,k0)
    rate_near = zeros(k0, 1);
    for idx = 1:k0
        y_near = zeros(M,Q);
        for m = 1:M
            temp = awgn( repmat( h(m, :) * w_2D_near(:, idx, m), [1, Q] ), SNR_dB*2/sqrt(3));
            %temp = repmat( h(m, :) * w_2D_near(:, idx, m), [1, Q] );
            y_near(m, :) =  temp;
        end
        y_near = abs( sum( y_near, 2 ) ).^2;

        % 计算有效近场角度和距离
        [~, i] = max(y_near);

        theta_hat_near = focus_loc(i,1,idx);
        r_hat_near = (1-theta_hat_near^2) / 2 / focus_loc(i,2,idx);


        % 计算速率
        w_near = TTD_beam(Nt, B, fc, M, d, focus_loc(i,1,idx), focus_loc(i,2,idx));
        temp = 0;
        for m = 1:M
            temp = temp + log2(1 + SNR_t * abs(h(m, :) * w_near(:, m))^2 ) / M;
        end
        if idx == 1
           rate_near(idx) = temp;
        else
           rate_near(idx) = max([rate_near(idx-1); temp]);
        end         
    end
end