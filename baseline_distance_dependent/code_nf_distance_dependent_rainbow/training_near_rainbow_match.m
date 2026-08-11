function [rate_near,array] = training_near_rainbow_match(Nt, B, fc, f, M, d, h, w_2D_near,focus_loc, SNR_t, SNR_dB, Q,k0,match_y,g1_list,g2_list)
    rate_near = zeros(k0, 1);
    y_all = zeros(k0,M,Q);
    for idx = 1:k0
        y_near = zeros(M,Q);
        for m = 1:M
            temp = awgn( repmat( h(m, :) * w_2D_near(:, idx, m), [1, Q] ), SNR_dB*2/sqrt(3));
            %temp = repmat( h(m, :) * w_2D_near(:, idx, m), [1, Q] );
            y_near(m, :) =  temp;
        end
        y_near = abs( sum( y_near, 2 ) ).^2;
        y_all(idx,:,:)=y_near;

        % 计算有效近场角度和距�?
        %[~, i] = max(y_near);

        %theta_hat_near = focus_loc(i,1,idx);
        %r_hat_near = (1-theta_hat_near^2) / 2 / focus_loc(i,2,idx);
        g1=length(g1_list);g2=length(g2_list);
        match_sel = zeros(g1,g2);
        for i = 1:g1
            for j = 1:g2
                r_1 = reshape(y_all(1:idx,:,:),idx,M,Q);
                r_2 = reshape(match_y(i,j,1:idx,:,:),idx,M,Q);
                tem = r_1.* r_2;
                match_sel(i,j)=sum(tem(:));
            end
        end
        [idxx,idxy]=find(match_sel==max(max(match_sel)));
        theta_hat = g1_list(idxx);
        alpha_hat = g2_list(idxy);
        %mesh(g2_list,g1_list,abs(match_sel));
        %mesh(g2_list,g1_list,match_sel);


        % 计算速率
        w_near = TTD_beam(Nt, B, fc, M, d, theta_hat, alpha_hat);
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