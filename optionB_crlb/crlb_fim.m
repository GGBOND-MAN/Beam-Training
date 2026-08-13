function [crlb_theta, crlb_r, J] = crlb_fim(W, sys, theta, r, beta, sigma2)
%CRLB_FIM  Semi-closed-form near-field angle/range CRLB for a beam-split
%          TRAINING codebook (Option B, Section IV).
%
%   [crlb_theta, crlb_r, J] = crlb_fim(W, sys, theta, r, beta, sigma2)
%
%   Reuses the baseline exact spherical-wave channel near_field_channel.m.
%   The derivative of every observation mu_{s,m}=beta*sum_n h_m(n) w_{s,m}(n)
%   is a closed form of three per-beam antenna moments
%       G0=sum_n g, G1=sum_n n g, G2=sum_n n^2 g ,   g=h_m(n) w_{s,m}(n):
%       d mu/d theta = j*beta*k_m*( d cos th * G1 + d^2 cos th sin th / r * G2 )
%       d mu/d r     = -j*beta*k_m*( G0 - d^2 cos^2 th /(2 r^2) * G2 )
%       d mu/d Re b  = G0 ,   d mu/d Im b = j G0 .
%   FIM: J = (2/sigma2) * sum_{s,m} Re{ D^H D } over eta=[theta,r,Re b,Im b].
%
%   W      : Nt x P x M training codebook (P = number of pilots/slots)
%   sys    : struct with fields Nt, fc, B, M, d
%   sigma2 : FIXED absolute noise variance (per complex sample)

c  = 3e8;
Nt = sys.Nt;  M = sys.M;  P = size(W, 2);
nn = (-(Nt-1)/2 : (Nt-1)/2).';                       % Nt x 1
fm = sys.fc + sys.B/M * ((1:M) - 1 - (M-1)/2);       % 1 x M
km = (2*pi*fm/c).';                                  % M x 1

H  = near_field_channel(Nt, sys.d, sys.fc, sys.B, sys.M, r, theta);  % M x Nt
st = sin(theta);  ct = cos(theta);

D = zeros(P*M, 4);
for s = 1:P
    Ws = reshape(W(:, s, :), Nt, M);                 % Nt x M
    g  = (H.') .* Ws;                                % Nt x M  = h_m(n) w_{s,m}(n)
    G0 = sum(g, 1).';                                % M x 1
    G1 = sum(nn .* g, 1).';
    G2 = sum(nn.^2 .* g, 1).';
    dth = 1j*beta*km .* ( sys.d*ct*G1 + (sys.d^2*ct*st/r)*G2 );
    dr  = -1j*beta*km .* ( G0 - (sys.d^2*ct^2/(2*r^2))*G2 );
    D((s-1)*M+1 : s*M, :) = [dth, dr, G0, 1j*G0];
end

J = (2/sigma2) * real(D' * D);
C = inv(J);
crlb_theta = C(1,1);
crlb_r     = C(2,2);
end
