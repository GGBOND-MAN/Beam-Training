function results = run_overhead()
%RUN_OVERHEAD  Option B second pillar: training-overhead T vs localization CRLB.
%   Reuses baseline delay_polar_2d.m / near_field_channel.m. MATLAB + Octave.
%
%   Fisher information is ADDITIVE over training slots, J(T)=sum_s J_s, so more
%   beam-split codewords lower the CRLB: sqrt(CRLB) ~ T^{-1/2} for T informative
%   looks; the CRLB-optimal (Omega-focused) codebook is steeper (it also
%   concentrates), reaching a target accuracy with far fewer slots.

c = 3e8;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'baseline_distance_dependent', ...
    'code_nf_distance_dependent_rainbow'));

sys.Nt = 128; sys.fc = 10e9; sys.B = 2e9; sys.M = 512; sys.d = (c/sys.fc)/2;
SNR_dB = 10; sigma2 = 10^(-SNR_dB/10);
th0 = deg2rad(11.54); r0 = 20; dth = deg2rad(1); dr = 2;
[TT, RR] = ndgrid(th0+linspace(-dth,dth,3), r0+linspace(-dr,dr,3));
Omega = [TT(:), RR(:)];
vth0 = sin(th0); a0 = cos(th0)^2/(2*r0);
fm = sys.fc + sys.B/sys.M*((1:sys.M)-1-(sys.M-1)/2);  ratio = sys.fc./fm;
dspan = max(ratio)-min(ratio); rmid = mean(ratio);
vext = cos(th0)*2*dth;
aext = abs(cos(th0)^2/(2*(r0-dr)) - cos(th0)^2/(2*(r0+dr)));

Ts = 1:8;
base = zeros(numel(Ts),3); foc = base;   % [sqrtCRLBth(rad), sqrtCRLBr(m), gain]
for i = 1:numel(Ts)
    [base(i,1),base(i,2),base(i,3)] = worstOmega(baseline_T(sys,Ts(i)), sys, Omega, sigma2);
    [foc(i,1), foc(i,2), foc(i,3)]  = worstOmega(focused_T(sys,Ts(i),vth0,a0,vext,aext,dspan,rmid), sys, Omega, sigma2);
end

fprintf('=== 2nd pillar: overhead T vs worst-Omega localization CRLB ===\n');
fprintf(' T | baseline sqrtCRLBr[mm]  gain | focused sqrtCRLBr[mm]  gain\n');
for i = 1:numel(Ts)
    fprintf('%2d | %18.3f  %5.3f | %18.3f  %5.3f\n', ...
        Ts(i), base(i,2)*1e3, base(i,3), foc(i,2)*1e3, foc(i,3));
end
pb = polyfit(log(Ts(:)), log(base(:,2)), 1);
pf = polyfit(log(Ts(:)), log(foc(:,2)),  1);
fprintf('scaling: baseline p=%.2f | focused p=%.2f (theory -0.5)\n', pb(1), pf(1));
tgt = 5.0;
Tb = firstle(base(:,2)*1e3, tgt, Ts);  Tf = firstle(foc(:,2)*1e3, tgt, Ts);
fprintf('slots to reach %.0f mm: baseline=%d, focused=%d -> overhead saving %.0f%%\n', ...
    tgt, Tb, Tf, (1-Tf/Tb)*100);
results.Ts = Ts; results.base = base; results.foc = foc;

setpub();
fig = figure('Position',[100 100 980 380],'Color','w');
subplot(1,2,1);
loglog(Ts, base(:,2)*1e3, 'o--','DisplayName','baseline (space-covering)'); hold on;
loglog(Ts, foc(:,2)*1e3,  's-', 'DisplayName','CRLB-optimal (\Omega-focused)');
loglog(Ts, foc(1,2)*1e3./sqrt(Ts), 'k:','DisplayName','T^{-1/2} reference');
grid on; xlabel('training overhead T (beam-split slots)','Interpreter','tex');
ylabel('worst-\Omega range CRLB^{1/2} [mm]','Interpreter','tex');
title('Localization CRLB vs training overhead','Interpreter','tex');
hleg=legend('show'); set(hleg,'Interpreter','tex','Location','southwest');
subplot(1,2,2);
semilogy(Ts, rad2deg(base(:,1)), 'o--','DisplayName','baseline'); hold on;
semilogy(Ts, rad2deg(foc(:,1)),  's-', 'DisplayName','\Omega-focused');
grid on; xlabel('training overhead T','Interpreter','tex');
ylabel('worst-\Omega angle CRLB^{1/2} [deg]','Interpreter','tex');
title('Angle CRLB vs overhead','Interpreter','tex');
hleg=legend('show'); set(hleg,'Interpreter','tex','Location','northeast');
savepub(fig, fullfile(here, 'fig_overhead'));
end

% ===================================================================
function W = baseline_T(sys, T)   % space-covering sweep, T slots
W = zeros(sys.Nt, T, sys.M);
for s = 1:T
    w1 = delay_polar_2d(sys.Nt, sys.B, sys.fc, sys.M, sys.d, -31-(s-1)*(2/T), 15, -0.454, 0.5, 1);
    W(:,s,:) = w1;
end
end

function W = focused_T(sys, T, vth0, a0, vext, aext, dspan, rmid)  % T slots tiling Omega
W = zeros(sys.Nt, T, sys.M);
for s = 1:T
    w = vext/T; wa = aext/T;
    csub  = vth0 - vext/2 + (s-0.5)*w;
    acsub = a0   - aext/2 + (s-0.5)*wa;
    t2 = w/dspan;  t1 = csub  - rmid*t2;
    a2 = wa/dspan; a1 = acsub - rmid*a2;
    W(:,s,:) = delay_polar_2d(sys.Nt, sys.B, sys.fc, sys.M, sys.d, t1, t2, a1, a2, 1);
end
end

function [tt, rr, gg] = worstOmega(W, sys, Omega, sigma2)
ct = zeros(size(Omega,1),1); cr = ct; gn = ct;
for q = 1:size(Omega,1)
    [ct(q), cr(q)] = crlb_fim(W, sys, Omega(q,1), Omega(q,2), 1, sigma2);
    gn(q) = best_gain(W, sys, Omega(q,1), Omega(q,2));
end
tt = sqrt(max(ct)); rr = sqrt(max(cr)); gg = min(gn);
end

function g = best_gain(W, sys, theta, r)
H = near_field_channel(sys.Nt, sys.d, sys.fc, sys.B, sys.M, r, theta);
g = 0;
for s = 1:size(W,2)
    Ws = reshape(W(:,s,:), sys.Nt, sys.M);
    g = max(g, max(abs(sum((H.').*Ws, 1)).^2));
end
end

function T = firstle(vals, tgt, Ts)
k = find(vals <= tgt, 1, 'first');
if isempty(k), T = Inf; else, T = Ts(k); end
end

function setpub()
set(0,'defaultAxesFontSize',12,'defaultLineLineWidth',1.7,'defaultAxesFontName','Helvetica');
end
function savepub(fig, base)
try, exportgraphics(fig, [base '.pdf'], 'ContentType','vector'); catch, end
print(fig, [base '.png'], '-dpng', '-r200');
fprintf('saved -> %s.png\n', base);
end
