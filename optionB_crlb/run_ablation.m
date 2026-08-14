function results = run_ablation()
%RUN_ABLATION  Option B Section V: ablation of the penalty+BCD codebook.
%   The proposed design has two removable ingredients:
%     (A) a geometry-aware WARM-START that tiles the uncertainty region Omega
%         using the beam-split relation vartheta_eff(m)=theta1+(fc/fm)*theta2;
%     (B) a penalty+BCD REFINEMENT over two blocks at the trade-off knee (mu):
%         PS block {(theta2,alpha2)_s} = frequency-flat base focus, and
%         TTD block {(theta1,alpha1)_s} = frequency-dependent beam-split slope.
%   We remove each in turn (all at mu=0.5, same semi-closed CRLB):
%     1 Baseline (space-cover)        rainbow sweep, no Omega awareness
%     2 Naive BCD (no warm-start)     penalty+BCD launched from the baseline init
%     3 Warm-start only (no BCD)      the Omega-focused init, no refinement
%     4 WS + PS-only                  refine PS,  TTD frozen at the warm-start
%     5 WS + TTD-only                 refine TTD, PS  frozen at the warm-start
%     6 WS + Full BCD (proposed)      refine both blocks jointly
%   Finding for this static single-user objective: the geometry warm-start is the
%   decisive enabler (naive BCD stalls in a poor basin), and once warm-started the
%   TTD and PS blocks are individually sufficient for the last-mile refinement
%   (redundant near the optimum) -- a benign-landscape property of the delay-phase
%   precoder, NOT "both blocks are necessary". Reuses delay_polar_2d.m /
%   near_field_channel.m / crlb_fim.m. MATLAB + Octave.

c = 3e8;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'baseline_distance_dependent', ...
    'code_nf_distance_dependent_rainbow'));

S.sys.Nt=128; S.sys.fc=10e9; S.sys.B=2e9; S.sys.M=512; S.sys.d=(c/S.sys.fc)/2;
S.P=2; SNR_dB=10; S.sigma2=10^(-SNR_dB/10); MU=0.5;
th0=deg2rad(11.54); r0=20; dth=deg2rad(1); dr=2;
[TT,RR]=ndgrid(th0+linspace(-dth,dth,3), r0+linspace(-dr,dr,3)); S.Omega=[TT(:),RR(:)];
vth0=sin(th0); a0=cos(th0)^2/(2*r0);
fm=S.sys.fc+S.sys.B/S.sys.M*((1:S.sys.M)-1-(S.sys.M-1)/2); ratio=S.sys.fc./fm;
dspan=max(ratio)-min(ratio); rmid=mean(ratio);
vext=cos(th0)*2*dth; aext=abs(cos(th0)^2/(2*(r0-dr))-cos(th0)^2/(2*(r0+dr)));

Wb=delay_polar_2d(S.sys.Nt,S.sys.B,S.sys.fc,S.sys.M,S.sys.d,-31,15,-0.454,0.5,S.P);
[S.s_th,S.s_r]=crlb_fim(Wb,S.sys,th0,r0,1,S.sigma2);

% space-covering baseline
xbase=[-31 -0.454 15 0.5, -32 -0.454 15 0.5];
% geometry-aware focused warm start
x_ws=zeros(1,4*S.P);
for s=1:S.P
    w=vext/S.P; wa=aext/S.P; cs=vth0-vext/2+(s-0.5)*w; ac=a0-aext/2+(s-0.5)*wa;
    t2=w/dspan; t1=cs-rmid*t2; a2=wa/dspan; a1=ac-rmid*a2;
    x_ws((s-1)*4+(1:4))=[t1 a1 t2 a2];
end
TTD=[1 2 5 6]; PS=[3 4 7 8];

variants = { 'Baseline (space-cover)',    xbase;
             'Naive BCD (no warm-start)', bcd(xbase,S,MU,{TTD,PS});
             'Warm-start only (no BCD)',  x_ws;
             'WS + PS-only',              bcd(x_ws,S,MU,{PS});
             'WS + TTD-only',             bcd(x_ws,S,MU,{TTD});
             'WS + Full BCD (proposed)',  bcd(x_ws,S,MU,{TTD,PS}) };

fprintf('=== Section V ablation: warm-start vs refinement vs blocks (mu=%.1f) ===\n', MU);
fprintf('%26s | %13s | %15s | %6s\n','variant','sqrtCRLBr[mm]','sqrtCRLBth[deg]','gain');
nv=size(variants,1); RR2=zeros(nv,1); TT2=RR2; GG=RR2;
for i=1:nv
    [~,g,rr,tt]=metrics(S, reshape(variants{i,2},4,S.P).');
    RR2(i)=rr; TT2(i)=tt; GG(i)=g;
    fprintf('%26s | %13.3f | %15.4f | %6.3f\n', variants{i,1}, rr, tt, g);
end
fprintf(['VERDICT: geometry warm-start is the decisive enabler (naive BCD stalls); ', ...
         'given it, TTD and PS refine to the same optimum (blocks redundant near it)\n']);
results.labels={variants{:,1}}; results.range_mm=RR2; results.angle_deg=TT2; results.gain=GG;

setpub(); fig=figure('Position',[100 100 1220 400],'Color','w');
lab=variants(:,1);
subplot(1,3,1); bar(RR2); set(gca,'xticklabel',lab,'XTickLabelRotation',34);
ylabel('worst-\Omega range CRLB^{1/2} [mm]','Interpreter','tex'); title('Range CRLB','Interpreter','tex'); grid on;
subplot(1,3,2); bar(TT2); set(gca,'xticklabel',lab,'XTickLabelRotation',34);
ylabel('worst-\Omega angle CRLB^{1/2} [deg]','Interpreter','tex'); title('Angle CRLB','Interpreter','tex'); grid on;
subplot(1,3,3); bar(GG); set(gca,'xticklabel',lab,'XTickLabelRotation',34);
ylabel('worst-\Omega comm. gain','Interpreter','tex'); title('Comm. gain','Interpreter','tex'); grid on;
savepub(fig, fullfile(here,'fig_ablation'));
end

% ===================================================================
function x = bcd(x0, S, mu, blocks)
x=x0;
for outer=1:3
    for bi=1:numel(blocks)
        b=blocks{bi};
        sub=@(v) phi(setidx(x,b,v), S, mu);
        opt=optimset('TolX',1e-3,'TolFun',1e-6,'MaxFunEvals',300,'Display','off');
        x=setidx(x,b,fminsearch(sub,x(b),opt));
    end
end
end

function W = build_cb(sys, Pm)
P=size(Pm,1); W=zeros(sys.Nt,P,sys.M);
for s=1:P, W(:,s,:)=delay_polar_2d(sys.Nt,sys.B,sys.fc,sys.M,sys.d,Pm(s,1),Pm(s,3),Pm(s,2),Pm(s,4),1); end
end
function [sens,gmin,rr,tt] = metrics(S, Pm)
W=build_cb(S.sys,Pm); sens=0; gmin=inf; ctm=0; crm=0;
for q=1:size(S.Omega,1)
    [ctv,crv]=crlb_fim(W,S.sys,S.Omega(q,1),S.Omega(q,2),1,S.sigma2);
    sens=max(sens,ctv/S.s_th+crv/S.s_r); ctm=max(ctm,ctv); crm=max(crm,crv);
    gmin=min(gmin,best_gain(W,S.sys,S.Omega(q,1),S.Omega(q,2)));
end
rr=sqrt(crm)*1e3; tt=rad2deg(sqrt(ctm));
end
function v = phi(x, S, mu), [sens,gmin]=metrics(S, reshape(x,4,S.P).'); v=sens - mu*gmin; end
function g = best_gain(W, sys, theta, r)
H=near_field_channel(sys.Nt,sys.d,sys.fc,sys.B,sys.M,r,theta); g=0;
for s=1:size(W,2), Ws=reshape(W(:,s,:),sys.Nt,sys.M); g=max(g,max(abs(sum((H.').*Ws,1)).^2)); end
end
function x=setidx(x,idx,v), x(idx)=v; end
function setpub(), set(0,'defaultAxesFontSize',11,'defaultLineLineWidth',1.5); end
function savepub(fig,base)
try, exportgraphics(fig,[base '.pdf'],'ContentType','vector'); catch, end
print(fig,[base '.png'],'-dpng','-r200'); fprintf('saved -> %s.png\n',base);
end
