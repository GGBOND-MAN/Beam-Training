function [w, theta_1,theta_2] = delay_angle_beam(Nt, theta_max, theta_min, B, fc, M, d)
c = 3e8;
%lambda_c = c/fc;
%Tc = 1/fc;
f = zeros(1, M);
for m= 1:M
    f(m)=fc+B/(M)*(m-1-(M-1)/2);
end
k = 2 * pi * f / c;
kc = 2 * pi * fc / c;
nn = (-(Nt - 1)/2:1:(Nt-1)/2)';

%% theta
fL = fc - B/2;
fH = fc + B/2;
theta_2 = (sin(theta_max)-sin(theta_min))/(fc/fH-fc/fL);
theta_1 = sin(theta_max)-theta_2*fc/fH;

%% delay
w = zeros(Nt,  M);

for m = 1:M
   w(:,  m) = 1/sqrt(Nt) * exp( - 1j * k(m) * (  nn * d * theta_1 ) -1j*kc*(  nn * d * theta_2 ));
end
end

