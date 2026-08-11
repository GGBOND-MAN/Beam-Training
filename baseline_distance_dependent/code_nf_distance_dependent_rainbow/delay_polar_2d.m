function [w] = delay_polar_2d(Nt, B, fc, M, d,theta1,theta2,alpha1,alpha2,k0)
c = 3e8;
lambda_c = c/fc;
f = zeros(1, M);
for m= 1:M
    f(m)=fc+B/(M)*(m-1-(M-1)/2);
end
k = 2 * pi * f / c;
kc = 2 * pi * fc / c;
nn = (-(Nt - 1)/2:1:(Nt-1)/2)';
%% delay
w = zeros(Nt,k0,M);
for s = 1:k0
    for m = 1:M
       w(:, s, m) = 1/sqrt(Nt) * exp( - 1j * k(m) * (  nn * d * theta1 - nn.^2 * d.^2 * alpha1 )-1j*kc*(  nn * d * theta2 - nn.^2 * d.^2 * alpha2));
    end
    theta1 = theta1-2/k0;
end
end