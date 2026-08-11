function rate_near=training_near_rainbow_elip(Nt, B, fc, f, M, d, h, w_2D_near,focus_loc, SNR_t, SNR_dB, Q,k0)
    c = 3e8;
    rate_near = zeros(k0, 1);
    for idx = 1:k0
        y_near = zeros(M,Q);
        for m = 1:M
            temp = awgn( repmat( h(m, :) * w_2D_near(:, idx, m), [1, Q] ), SNR_dB*2/sqrt(3));
            %temp = repmat( h(m, :) * w_2D_near(:, idx, m), [1, Q] );
            y_near(m, :) =  temp;
        end
        y_near = abs( sum( y_near, 2 ) );

        % 计算有效近场角度和距离
        y_can = maxk(y_near,2);
        for n =1:2
            idxy=find(y_near==y_can(n));
            t_all(n) = focus_loc(idxy,1,idx);
            a_all(n) = focus_loc(idxy,2,idx);
            a1(n) = 1/24*Nt^2*pi^2*f(idxy)^2/fc^2;
            lambda = c/f(idxy);
            a2(n) = 1/90*Nt^4*pi^2*d^4/lambda^2;
        end
        %theta_hat_near = focus_loc(i,1,idx);
        %r_hat_near = (1-theta_hat_near^2) / 2 / focus_loc(i,2,idx);
        syms x y
        %[x,y]=solve(num2str(a1(1))*(x-num2str(t_all(1)))^2+num2str(a2(1))*(y-num2str(a_all(1)))^2==1-num2str(y_can(1)), num2str(a1(2))*(x-num2str(t_all(2)))^2+num2str(a2(2))*(y-num2str(a_all(2)))^2==1-num2str(y_can(2)),x,y);
        %ezplot(x^2+y^2==1);
        %hold on ;
        %ezplot(a1(2)*(x-t_all(2))^2+a2(2)*(y-a_all(2))^2==1-y_can(2));
        [x,y]=solve(a1(1)*(x-t_all(1))^2+a2(1)*(y-a_all(1))^2==1-y_can(1),a1(2)*(x-t_all(2))^2+a2(2)*(y-a_all(2))^2==1-y_can(2),x,y);
        x=double(x);y=double(y);
        mask = ~any(imag(x), 2) | ~any(imag(y), 2);
        x = x(mask); y = y(mask);
        % 计算速率
        if length(x)==2
            w_near = TTD_beam(Nt, B, fc, M, d, x(1), y(1));
            temp1 = 0;
            for m = 1:M
                temp1 = temp1 + log2(1 + SNR_t * abs(h(m, :) * w_near(:, m))^2 ) / M;
            end
            w_near = TTD_beam(Nt, B, fc, M, d, x(2), y(2));
            temp2 = 0;
            for m = 1:M
                temp2 = temp2 + log2(1 + SNR_t * abs(h(m, :) * w_near(:, m))^2 ) / M;
            end
            temp=max(temp1,temp2);
        else
            w_near = TTD_beam(Nt, B, fc, M, d, t_all(1), a_all(1));
            temp = 0;
            for m = 1:M
                temp = temp + log2(1 + SNR_t * abs(h(m, :) * w_near(:, m))^2 ) / M;
            end 
        end
        if idx == 1
           rate_near(idx) = temp;
        else
           rate_near(idx) = max([rate_near(idx-1); temp]);
        end         
    end
end