function results = run_crlb_experiment(mode)
% RUN_CRLB_EXPERIMENT  Foundation script for Option B.
%
% Computes the Cramer-Rao Lower Bound (CRLB) for jointly estimating a
% near-field user's angle (theta) and range (r) from a distance-dependent
% beam-split TRAINING codebook, and (optionally) validates the bound with a
% Monte-Carlo maximum-likelihood estimator.
%
% It REUSES the baseline model functions unchanged:
%   near_field_channel.m   -> exact spherical-wave channel, per subcarrier
%   delay_polar_2d.m       -> distance-dependent beam-split codebook
%
% Design variables of Option B are the codebook parameters
%   (theta1, alpha1)  TTD term   (scales with k_m = 2*pi*f_m/c)
%   (theta2, alpha2)  PS  term   (scales with k_c = 2*pi*f_c/c)
% The per-subcarrier effective focus they induce is
%   sin_theta_eff(m) = theta1 + (fc/f_m)*theta2   (wrapped into [-1,1])
%   alpha_eff(m)     = alpha1 + (fc/f_m)*alpha2
% i.e. different subcarriers focus at different (angle, distance) -> a single
% pilot scans the angle-distance plane. Optimizing (theta1,alpha1,theta2,
% alpha2) to minimise the CRLB below is the core of Option B.
%
% Usage:
%   results = run_crlb_experiment();        % single-point CRLB report
%   results = run_crlb_experiment("snr");   % + Monte-Carlo RMSE vs SNR plot
%
% NOTE: written to be model-consistent with the baseline; run it in MATLAB to
% verify numerically.

if nargin < 1 || strlength(mode) == 0
    mode = "point";
end

%% -- put baseline model functions on the path ------------------------------
basedir = fileparts(mfilename('fullpath'));
addpath(fullfile(basedir, '..', 'baseline_distance_dependent', ...
    'code_nf_distance_dependent_rainbow'));

%% -- system parameters (aligned with distance_dependent_beam_split.m) ------
c   = 3e8;
sys.Nt = 128;            % number of antennas
sys.fc = 10e9;          % carrier frequency [Hz]
sys.B  = 2e9;           % bandwidth [Hz]
sys.M  = 512;           % number of subcarriers
sys.d  = (c/sys.fc)/2;  % half-wavelength element spacing
sys.k0 = 2;             % number of beam-split groups (= number of pilots)

% distance-dependent beam-split codebook design variables (baseline example)
cb.theta1 = -31;   cb.theta2 = 15;      % linear (angle) TTD / PS coefficients
cb.alpha1 = -0.454; cb.alpha2 = 0.5;    % quadratic (curvature) TTD / PS coeff.

% ground-truth user location (physical): angle in rad, range in metres
user.theta = asin(0.2);   % ~11.5 deg off broadside  (sin_theta = 0.2)
user.r     = 20;          % 20 m  -> alpha = cos^2(theta)/(2r) ~ 0.024 (in range)
user.beta  = 1;           % complex path gain (|beta| = 1 for the demo)

% build the training codebook once: W is (Nt x k0 x M)
W = delay_polar_2d(sys.Nt, sys.B, sys.fc, sys.M, sys.d, ...
    cb.theta1, cb.theta2, cb.alpha1, cb.alpha2, sys.k0);

%% -- single-point CRLB at a chosen SNR -------------------------------------
snr_dB_point = 10;
[crlb, aux] = compute_crlb(W, sys, user, snr_dB_point);

fprintf('\n===== CRLB report (SNR = %g dB) =====\n', snr_dB_point);
fprintf('User: sin(theta) = %.3f (%.2f deg), r = %.2f m\n', ...
    sin(user.theta), user.theta*180/pi, user.r);
fprintf('Best-beam array gain over the codebook : %.3f\n', aux.bestGain);
fprintf('CRLB angle std  : %.4e rad  (%.4e deg)\n', ...
    sqrt(crlb.theta), sqrt(crlb.theta)*180/pi);
fprintf('CRLB range std  : %.4e m\n', sqrt(crlb.r));

results.sys  = sys;
results.cb   = cb;
results.user = user;
results.crlb = crlb;
results.aux  = aux;

%% -- optional: Monte-Carlo validation of the bound vs SNR ------------------
if strcmpi(mode, "snr")
    snr_dB  = 0:5:25;
    nTrials = 200;
    rmse_theta = zeros(size(snr_dB));  crlb_theta = zeros(size(snr_dB));
    rmse_r     = zeros(size(snr_dB));  crlb_r     = zeros(size(snr_dB));

    % estimator search grid (kept modest for speed)
    thetaAxis = asin(linspace(sin(user.theta)-0.05, sin(user.theta)+0.05, 41));
    rAxis     = linspace(user.r-4, user.r+4, 41);
    [TH, RR]  = ndgrid(thetaAxis, rAxis);
    thetaList = TH(:);  rList = RR(:);  Ngrid = numel(thetaList);

    % PRECOMPUTE the grid basis ONCE (noise- and SNR-independent):
    % UgridH(g,:) = u_g'  where u_g is the noiseless template at grid point g
    L = sys.k0 * sys.M;
    UgridH = zeros(Ngrid, L);
    Unorm  = zeros(Ngrid, 1);
    for g = 1:Ngrid
        uv = build_basis(sys, W, thetaList(g), rList(g));   % L x 1
        UgridH(g,:) = uv';
        Unorm(g)    = real(uv' * uv);
    end

    for i = 1:numel(snr_dB)
        [cb_i, aux_i] = compute_crlb(W, sys, user, snr_dB(i));
        crlb_theta(i) = sqrt(cb_i.theta);
        crlb_r(i)     = sqrt(cb_i.r);

        errT = zeros(nTrials,1);  errR = zeros(nTrials,1);
        mu0v = aux_i.mu0(:);
        for t = 1:nTrials
            yv = mu0v + sqrt(aux_i.sigma2/2)*(randn(L,1) + 1j*randn(L,1));
            metric = abs(UgridH * yv).^2 ./ Unorm;   % matched-filter / GLRT
            [~, gBest] = max(metric);
            errT(t) = thetaList(gBest) - user.theta;
            errR(t) = rList(gBest)     - user.r;
        end
        rmse_theta(i) = sqrt(mean(errT.^2));
        rmse_r(i)     = sqrt(mean(errR.^2));
        fprintf('SNR %2d dB | RMSE theta %.3e (CRLB %.3e) | RMSE r %.3e (CRLB %.3e)\n', ...
            snr_dB(i), rmse_theta(i), crlb_theta(i), rmse_r(i), crlb_r(i));
    end

    figure('Name','CRLB validation');
    subplot(1,2,1);
    semilogy(snr_dB, rmse_theta*180/pi, 'o-', snr_dB, crlb_theta*180/pi, '--');
    grid on; xlabel('SNR [dB]'); ylabel('angle RMSE / CRLB [deg]');
    legend('ML RMSE','sqrt(CRLB)'); title('Angle estimation');
    subplot(1,2,2);
    semilogy(snr_dB, rmse_r, 'o-', snr_dB, crlb_r, '--');
    grid on; xlabel('SNR [dB]'); ylabel('range RMSE / CRLB [m]');
    legend('ML RMSE','sqrt(CRLB)'); title('Range estimation');

    results.snr_dB     = snr_dB;
    results.rmse_theta = rmse_theta;   results.crlb_theta = crlb_theta;
    results.rmse_r     = rmse_r;       results.crlb_r     = crlb_r;
end
end

% =========================================================================
function [crlb, aux] = compute_crlb(W, sys, user, snr_dB)
% FIM/CRLB for parameters [theta, r, Re(beta), Im(beta)] from all (pilot,
% subcarrier) observations. Channel derivatives use central finite
% differences on the exact near_field_channel model.

M = sys.M; k0 = sys.k0;

H0  = channel_rows(sys, user.r, user.theta);          % M x Nt
dTheta = 1e-6; dR = 1e-4;
Hth = (channel_rows(sys, user.r, user.theta+dTheta) ...
     - channel_rows(sys, user.r, user.theta-dTheta)) / (2*dTheta);
Hr  = (channel_rows(sys, user.r+dR, user.theta) ...
     - channel_rows(sys, user.r-dR, user.theta)) / (2*dR);

mu0  = zeros(k0, M);  dTh = zeros(k0, M);
dRr  = zeros(k0, M);  dReB = zeros(k0, M);  dImB = zeros(k0, M);
for s = 1:k0
    for m = 1:M
        w = W(:, s, m);
        base       = H0(m,:) * w;
        mu0(s,m)   = user.beta * base;
        dTh(s,m)   = user.beta * (Hth(m,:) * w);
        dRr(s,m)   = user.beta * (Hr(m,:)  * w);
        dReB(s,m)  = base;                     % d mu / d Re(beta)
        dImB(s,m)  = 1j * base;                % d mu / d Im(beta)
    end
end

sigPow = mean(abs(mu0(:)).^2);
sigma2 = sigPow / 10^(snr_dB/10);

D = [dTh(:), dRr(:), dReB(:), dImB(:)];        % (k0*M) x 4
J = (2/sigma2) * real(D' * D);                 % Fisher information
C = inv(J);

crlb.theta   = C(1,1);
crlb.r       = C(2,2);
aux.mu0      = mu0;
aux.sigma2   = sigma2;
aux.bestGain = max(abs(mu0(:)).^2) / abs(user.beta)^2;
aux.FIM      = J;
aux.CRB      = C;
end

% =========================================================================
function uv = build_basis(sys, W, theta, r)
% Noiseless observation template (L x 1) for a hypothesised (theta, r):
% u(s,m) = channel_row_m * beamformer_{s,m}.
H = channel_rows(sys, r, theta);
u = zeros(sys.k0, sys.M);
for s = 1:sys.k0
    for m = 1:sys.M
        u(s,m) = H(m,:) * W(:,s,m);
    end
end
uv = u(:);
end

% =========================================================================
function H = channel_rows(sys, r, theta)
% Wrapper around baseline near_field_channel: returns the M x Nt matrix whose
% m-th row is the propagation channel to the user on subcarrier m.
H = near_field_channel(sys.Nt, sys.d, sys.fc, sys.B, sys.M, r, theta);
end
