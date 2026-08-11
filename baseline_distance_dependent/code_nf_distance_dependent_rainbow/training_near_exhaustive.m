function [rate_near_nb,array] = training_near_exhaustive(D2, S2,  hc, w_phase_near,SNR_t, SNR_dB, Q, M, overhead_max)

overhead = D2 * S2;
overhead = min([overhead, overhead_max]);
%% 高信噪比模式，仅适用于overhead图
rate_near_nb = zeros(overhead, 1);

for idx = 1 : overhead
        s = ceil(idx / D2) ; %distance 
        a = idx - ( s - 1 )*D2; % direction
        % 接受信号增益
        % 计算速率
        wc_near_nb = w_phase_near(:, a, s);
        %norm(wc_near_nb )
        array_gain = abs(hc * wc_near_nb)^2;
        temp = log2(1 + SNR_t * array_gain);
        if idx == 1
            rate_near_nb(idx) = temp;
            array = array_gain;
        else
            rate_near_nb(idx) = max([rate_near_nb(idx-1); temp]);
            array = max([array; array_gain]);
        end
end

end

