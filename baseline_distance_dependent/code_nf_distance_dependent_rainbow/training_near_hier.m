function [rate_near_hier,array_gain] = training_near_hier(h,near_codebook_W1,near_codebook_W2,near_codebook,recordW1,recordW2,po_label,SNR_t, SNR_dB, M, overhead_max)
    array_gain = 0;array_gain_1 = 0;array_gain_2 = 0;
    %temp = abs(near_codebook*h.');
    %[m,p]=max(temp)
    %%%% level one
    i_max_1 = 0;
    overhead1 = size(near_codebook_W1,1);
    for i =1:size(near_codebook_W1,1)
        a =near_codebook_W1(i,:)/norm(near_codebook_W1(i,:));
        %norm(a)
        if array_gain_1<=abs(a*h.')^2
            array_gain_1=max(array_gain_1,abs(a*h.')^2);
            i_max_1 = i;
        end
        rate_near_hier(i) =  log2(1 + SNR_t * array_gain_1);
    end
    po1 = recordW1(:,i_max_1);
    
    order1_themin = find(recordW2(1,:)>=po1(1));
    order1_themax = find(recordW2(2,:)<=po1(2));
    order1_rmin = find(recordW2(3,:)>=po1(3));
    order1_rmax = find(recordW2(4,:)<=po1(4));
    
    order1 = intersect(order1_themin,order1_themax);
    order1 = intersect(order1,order1_rmin);
    order1 = intersect(order1,order1_rmax);

    %%%% level two
    array_gain_2 = array_gain_1;
    near_codebook2 = near_codebook_W2(order1,:);
    overhead2 = size(near_codebook2,1);
    record2 = recordW2(:,order1);
    i_max_2 = 0;
    for i =1:size(near_codebook2,1)
        a = near_codebook2(i,:)/norm(near_codebook2(i,:));
        if array_gain_2<=abs(a*h.')^2
            array_gain_2=max(array_gain_2,abs(a*h.')^2);
            i_max_2 = i;
        end
        rate_near_hier(overhead1+i) =  log2(1 + SNR_t * array_gain_2);
    end
    if i_max_2==0
        i_max_2 = 1;
    end
    po2 = record2(:,i_max_2);
   
   
    order3_the = find((po_label(1,:)>=po2(1))&(po_label(1,:)<=po2(2)));
    order3_r = find((po_label(2,:)>=po2(3))&(po_label(2,:)<=po2(4)));
    order3 = intersect(order3_the,order3_r);
% 

    %%% level three
    array_gain = array_gain_2;
    near_codebook4 = near_codebook(order3,:);
    overhead3 = size(near_codebook4,1);
    record4 = po_label(:,order3);
    i_max = 0;
    for i =1:size(near_codebook4,1)
        a=near_codebook4(i,:)/norm(near_codebook4(i,:));
        if array_gain<=abs(a*h.')^2
            array_gain=max(array_gain,abs(a*h.')^2);
            i_max = i;
        end
        rate_near_hier(overhead1+overhead2+i) =  log2(1 + SNR_t * array_gain);
    end
end
