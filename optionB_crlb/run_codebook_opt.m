function results = run_codebook_opt()
%RUN_CODEBOOK_OPT  Option B Section V: sensing-optimal (Omega-focused)
%   distance-dependent beam-split TRAINING codebook, and the
%   communication-sensing trade-off. Reuses baseline delay_polar_2d.m /
%   near_field_channel.m. Runs in MATLAB (R2016b+) and GNU Octave.
%
%   Two-stage active beam training: stage-1 coarse search localises the user
%   to an uncertainty region Omega; stage-2 focuses the beam-split sweep onto
%   Omega, concentrating training energy -> higher Fisher info -> lower CRLB.
%   Noise is FIXED absolute so concentration genuinely helps.

c = 3e8;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'baseline_distance_dependent', ...
    'code_nf_distance_dependent_rainbow'));

sys.Nt = 128; sys.fc = 10e9; sys.B = 2e9; sys.M = 512; sys.d = (c/sys.fc)/2;
k0 = 2;  SNR_dB = 10;  sigma2 = 10^(-SNR_dB/10);

th0 = deg2rad(11.54); r0 = 20; dth = deg2rad(1); dr = 2;
[TT, RR] = ndgrid(th0+linspace(-dth,dth,3), r0+linspace(-dr,dr,3));
Omega = [TT(:), RR(:)];

vth0 = sin(th0); a0 = cos(th0)^2/(2*r0);
fm = sys.fc + sys.B/sys.M*((1:sys.M)-1-(sys.M-1)/2);  ratio = sys.fc./fm;
dspan = max(ratio)-min(ratio); rmid = mean(ratio);
vext = cos(th0)*2*dth;
aext = abs(cos(th0)^2/(2*(r0-dr)) - cos(th0)^2/(2*(r0+dr)));

% --- baseline (space-covering) codebook ---
Wb = delay_polar_2d(sys.Nt, sys.B, sys.fc, sys.M, sys.d, -31, 15, -0.454, 0.5, k0);
[tb, rb, gb] = worstOmega(Wb, sys, Omega, sigma2);
fprintf('=== Section V: Omega-focused sensing-optimal training codebook ===\n');
fprintf('[baseline ] worstOmega sqrtCRLBth=%.3e deg | sqrtCRLBr=%.3e mm | gain=%.3f\n', ...
    rad2deg(tb), rb*1e3, gb);

% --- sweep the coverage width: broad (baseline-like) -> tight (focused on Omega) ---
widths = logspace(log10(vext*0.8), log10(15*dspan), 22);
res = zeros(numel(widths), 3);   % [sqrtCRLBth(deg), sqrtCRLBr(mm), gain]
for i = 1:numel(widths)
    Wf = focused_cb(sys, widths(i), vth0, a0, vext, aext, dspan, rmid, k0);
    [tt, rr, gg] = worstOmega(Wf, sys, Omega, sigma2);
    res(i,:) = [rad2deg(tt), rr*1e3, gg];
end
feas = res(:,3) >= gb; idx = find(feas);
[~, jj] = min(res(idx,2)); kbest = idx(jj);
fprintf('[optimised] worstOmega sqrtCRLBth=%.3e deg | sqrtCRLBr=%.3e mm | gain=%.3f\n', ...
    res(kbest,1), res(kbest,2), res(kbest,3));
fprintf('  angle CRLB improvement %.2fx | range CRLB improvement %.2fx | gain %.2f->%.2f\n', ...
    rad2deg(tb)/res(kbest,1), rb*1e3/res(kbest,2), gb, res(kbest,3));

results.widths = widths; results.res = res; results.baseline = [rad2deg(tb), rb*1e3, gb];

% --- publication figure ---
setpub();
fig = figure('Position',[100 100 980 380],'Color','w');
subplot(1,2,1);
loglog(widths, res(:,2), 'o-', 'DisplayName','\Omega-focused codebook'); hold on;
yline_(rb*1e3, 'k--', 'baseline'); xline_(vext, 'g:', '\Omega extent');
grid on; xlabel('beam-split coverage width w (\vartheta span)','Interpreter','tex');
ylabel('worst-\Omega range CRLB^{1/2} [mm]','Interpreter','tex');
title('Concentrate sweep on \Omega \rightarrow lower CRLB','Interpreter','tex');
hleg=legend('show'); set(hleg,'Interpreter','tex','Location','northwest');
subplot(1,2,2);
plot(res(:,3), res(:,2), 'o-', 'DisplayName','trade-off (vary w)'); hold on;
plot(gb, rb*1e3, 'kp', 'MarkerSize',13,'MarkerFaceColor','k','DisplayName','baseline');
plot(res(kbest,3), res(kbest,2), 'rd','MarkerSize',9,'MarkerFaceColor','r','DisplayName','chosen design');
grid on; xlabel('worst-\Omega communication array gain','Interpreter','tex');
ylabel('worst-\Omega range CRLB^{1/2} [mm]','Interpreter','tex');
title('Communication-sensing trade-off','Interpreter','tex');
hleg=legend('show'); set(hleg,'Interpreter','tex','Location','northeast');
savepub(fig, fullfile(here, 'fig_codebook_opt'));
end

% ===================================================================
function W = focused_cb(sys, w, vth0, a0, vext, aext, dspan, rmid, P)
wa = w*(aext/vext);
t2 = w/dspan;  t1 = vth0 - rmid*t2;
a2 = wa/dspan; a1 = a0 - rmid*a2;
w1 = delay_polar_2d(sys.Nt, sys.B, sys.fc, sys.M, sys.d, t1, t2, a1, a2, 1); % Nt x1x M
W  = repmat(w1, [1, P, 1]);
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
H = near_field_channel(sys.Nt, sys.d, sys.fc, sys.B, sys.M, r, theta); % M x Nt
g = 0;
for s = 1:size(W,2)
    Ws = reshape(W(:,s,:), sys.Nt, sys.M);
    g = max(g, max(abs(sum((H.').*Ws, 1)).^2));
end
end

% ---- publication-style plotting helpers (MATLAB + Octave) ----
function setpub()
set(0,'defaultAxesFontSize',12,'defaultLineLineWidth',1.7,'defaultAxesFontName','Helvetica');
end
function savepub(fig, base)
try  % MATLAB vector PDF
    exportgraphics(fig, [base '.pdf'], 'ContentType','vector');
catch % Octave / older MATLAB
end
print(fig, [base '.png'], '-dpng', '-r200');
fprintf('saved -> %s.png\n', base);
end
function yline_(y, style, name)
xl = xlim; plot(xl, [y y], style, 'DisplayName', name);
end
function xline_(x, style, name)
yl = ylim; plot([x x], yl, style, 'DisplayName', name);
end
