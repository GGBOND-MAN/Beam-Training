function [W,record2] = GS_wb_design_withCIN_512(f,codebook_o,L,label,theta,r)
% widebeam design with codebook as input

codebook = codebook_o.';%原码本
c= 3e8;
lambda = c/f;
N = size(codebook,1);
AbG = codebook;
A = AbG; 
B = A'*pinv(A*A')*A;
R = [real(B),-imag(B);imag(B),real(B)]; 

%theta = sin(theta_min) : 2/(s * N) : sin(theta_max);
%r = label(2,1:grid_r);
%num_subfig = 3;
%g = zeros(num_subfig, length(r), length(theta));       
        
if L == 1
    size_theta = 32; size_r = 4;size_W_codebook =  size_theta*size_r; 
elseif L == 2
    size_theta = 64;size_r = 16;size_W_codebook =  size_theta*size_r;    
end

record2 = zeros(4,size_W_codebook);


if L~=999
    
       num_theta = max(256/size_theta,1);
       num_r = max(16/size_r,1);
        
    for i_sam = 1:size_W_codebook
       
        
        i_sam  %%%% 
        if i_sam ~=8888
       
        index_r = ceil((i_sam)/size_theta);
        index_theta = mod(i_sam,size_theta);
        if index_theta == 0
            index_theta = size_theta;
        end
        
        range_r = r((index_r-1)*num_r+1:index_r*num_r);
        range_theta = theta((index_theta-1)*num_theta+1:index_theta*num_theta);
        
        record2(1:2,i_sam)=[min(range_theta),max(range_theta)];
        record2(3:4,i_sam)=[min(range_r),max(range_r)];
        
        order_r = find((min(range_r)<=label(2,:))&(label(2,:)<=max(range_r)));
        order_theta = find((min(range_theta)<=label(1,:))&(label(1,:)<=max(range_theta)));
        
        order_g = intersect(order_r,order_theta);
                
        g02 = zeros(size(AbG,2),1); 
        
        g02(order_g) = 1;
        g = g02;
        gModulus = abs(g); 

            g_temp = g;
    
    for iter = 1:20       
        v_temp=pinv(AbG*AbG')*AbG*g_temp;
        g_temp = gModulus.*exp(1j*angle(AbG'*v_temp));
    end
      
    w=pinv(AbG*AbG')*AbG*g_temp/norm(pinv(AbG*AbG')*AbG*g_temp,'fro');%根据式（19）和式（30）得到理想码字w，维度与基站天线数一致
        
   %[wp,~]=AltMinFS(w,100,5); 
   W(i_sam,:) = w;
    end
end
end



