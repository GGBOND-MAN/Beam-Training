function [rate_near_nb,array] = training_near_2stage(D2, S2,hc,w_phase_near,SNR_t, SNR_dB, M, overhead_max)
m=5;
overhead = D2 + S2*m;
rate_near_nb = zeros(overhead, 1);
array_temp=zeros(D2, 1);
array =0;
%远场估计角度
for idx = 1 : D2
    wc_near_nb = w_phase_near(:, idx, 1);
    %wc_near_nb = w_far(:, idx);
    array_gain = abs(hc * wc_near_nb)^2;
    array_temp(idx)=array_gain;
    temp = log2(1 + SNR_t * array_gain);
    if idx == 1
        rate_near_nb(idx) = temp;
        i_max = 1;
    elseif rate_near_nb(idx-1)>temp
        rate_near_nb(idx) = max([rate_near_nb(idx-1); temp]);
    else
        rate_near_nb(idx) = max([rate_near_nb(idx-1); temp]);
        i_max = idx;
    end
end
%近场估计距离
[A,index]=sort(array_temp,'descend');
candidate_index = index(1:m,1);
for j =1:m
for idx = 1 : S2
    wc_near_nb = w_phase_near(:, candidate_index(j), idx);
    array_gain = abs(hc * wc_near_nb)^2;
    temp = log2(1 + SNR_t * array_gain);
    rate_near_nb(idx+D2+(j-1)*S2) = max([rate_near_nb(idx-1+D2+(j-1)*S2); temp]);
    array =max([array;array_gain]);
end
end
end