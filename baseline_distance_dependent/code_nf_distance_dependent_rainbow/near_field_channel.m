function [H, hc] = near_field_channel(Nt, d, fc, B, M, r, theta)

H = zeros( M + 1, Nt);
nn = -(Nt-1)/2:1:(Nt-1)/2;
c = 3e8;


for m = 1:M+1
   if m == M+1
        f = fc;
   else
        f=fc+B/(M)*(m-1-(M-1)/2);
   end


   at = near_field_manifold( Nt, d, f, r, theta );
   H(m, :) = exp(-1j*2*pi*f*r/c) * at;
 
end

hc = H(M+1,:);
H = H(1:M,:);
end

