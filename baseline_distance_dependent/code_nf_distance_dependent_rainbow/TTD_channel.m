function w = TTD_channel(Nt, B, fc, M, d, sin_theta1, alpha1)
c = 3e8;
lambda_c = c/fc;
Tc = 1/fc;
f = zeros(1, M);
for m= 1:M
    f(m)=fc+B/(M)*(m-1-(M-1)/2);
end
delta_n = (-(Nt - 1)/2:1:(Nt-1)/2)';


%% delay 
delay = delta_n * d * sin_theta1 - (delta_n * d).^ 2 * alpha1;
r = (1-sin_theta1.^2)/2/alpha1;

w = zeros(Nt, M);
k = 2 * pi * f / c;
for m = 1:M
   w(:, m) = 1/sqrt(Nt) * exp(1j*2*pi*f(m)*r/c) * exp( -1j * k(m) * delay );
end

end