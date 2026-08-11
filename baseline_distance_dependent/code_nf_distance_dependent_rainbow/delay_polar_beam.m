function [w, theta_1,theta_2, alpha] = delay_polar_beam(Nt, theta_max, theta_min, B, fc, M, d, rho_min, delta)
c = 3e8;
lambda_c = c/fc;
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


%% r
Z_delta = Nt^2 * d^2 / 2 / delta^2 / lambda_c;
S = floor(Z_delta / rho_min) + 1;
r_list = zeros(S, 1);
for s = 1:S
    if s == 1
        r_list(s) = 2 * Nt^2 * d^2 / lambda_c;
    else
        r_list(s) = Z_delta / (s - 1);
    end
end
alpha = 1./ 2 ./ r_list;


%% delay
w = zeros(Nt, S, M);
for s = 1:S
    for m = 1:M
       w(:, s, m) = 1/sqrt(Nt) * exp( - 1j * k(m) * (  nn * d * theta_1 - nn.^2 * d.^2 * alpha(s) )-1j*kc*(  nn * d * theta_2 ));
    end
end

end

