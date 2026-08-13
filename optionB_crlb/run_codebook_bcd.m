function results = run_codebook_bcd()
%RUN_CODEBOOK_BCD  Option B Section V: penalty/scalarization + block-coordinate
%   -descent (BCD) optimizer for the CRLB-optimal beam-split TRAINING codebook,
%   and the formal communication-sensing Pareto frontier. Reuses baseline
%   delay_polar_2d.m / near_field_channel.m and crlb_fim.m. MATLAB + Octave.
%
%   Mirrors the DPP-ISAC competitor's solution structure (BCD decoupling the TTD
%   'delay' block from the PS 'phase' block), applied to our TRAINING-codebook
%   active-experiment-design problem over Omega. The trade-off: concentrate the
%   sweep for high comm array GAIN vs. diversify looks across Omega for better
%   SENSING conditioning (lower worst-case CRLB). Scalarize
%     Phi(C;mu) = max_Omega[CRLBth/sth0+CRLBr/sr0] - mu * min_Omega G(th,r;C)
%   and sweep mu (mu=0 sensing-optimal; large mu gain-optimal), solving each by
%   BCD (alternate fminsearch over the TTD block and the PS block).

c = 3e8;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'baseline_distance_dependent', ...
    'code_nf_distance_dependent_rainbow'));

S.sys.Nt=128; S.sys.fc=10e9; S.sys.B=2e9; S.sys.M=512; S.sys.d=(c/S.sys.fc)/2;
S.P=2; SNR_dB=10; S.sigma2=10^(-SNR_dB/10);
th0=deg2rad(11.54); r0=20; dth=deg2rad(1); dr=2;
[TT,RR]=ndgrid(th0+linspace(-dth,dth,3), r0+linspace(-dr,dr,3)); S.Omega=[TT(:),RR(:)];
vth0=sin(th0); a0=cos(th0)^2/(2*r0);
fm=S.sys.fc+S.sys.B/S.sys.M*((1:S.sys.M)-1-(S.sys.M-1)/2); ratio=S.sys.fc./fm;
dspan=max(ratio)-min(ratio); rmid=mean(ratio);
vext=cos(th0)*2*dth; aext=abs(cos(th0)^2/(2*(r0-dr))-cos(th0)^2/(2*(r0+dr)));

Wb=delay_polar_2d(S.sys.Nt,S.sys.B,S.sys.fc,S.sys.M,S.sys.d,-31,15,-0.454,0.5,S.P);
[S.s_th,S.s_r]=crlb_fim(Wb,S.sys,th0,r0,1,S.sigma2);
[~,gb,rb,tb]=metrics(S,[-31 -0.454 15 0.5;-32 -0.454 15 0.5]);
fprintf('=== Section V penalty+BCD optimizer: comm-sensing Pareto ===\n');
fprintf('[baseline] gain=%.3f | worstOmega sqrtCRLBr=%.3f mm | sqrtCRLBth=%.4f deg\n', gb, rb, tb);

% diverse 2-tile focused warm start
x=zeros(1,4*S.P);
for s=1:S.P
    w=vext/S.P; wa=aext/S.P;
    cs=vth0-vext/2+(s-0.5)*w; ac=a0-aext/2+(s-0.5)*wa;
    t2=w/dspan; t1=cs-rmid*t2; a2=wa/dspan; a1=ac-rmid*a2;
    x((s-1)*4+(1:4))=[t1 a1 t2 a2];
end

TTDblk=[1 2 5 6]; PSblk=[3 4 7 8];
mus=[0 0.5 1 2 4 8]; par=zeros(numel(mus),3);
for im=1:numel(mus)
    mu=mus(im);
    for outer=1:4
        for blk={TTDblk,PSblk}
            b=blk{1};
            sub=@(v) phi(setidx(x,b,v), S, mu);
            opt=optimset('TolX',1e-3,'TolFun',1e-6,'MaxFunEvals',500,'Display','off');
            x=setidx(x,b,fminsearch(sub,x(b),opt));
        end
    end
    [~,g,rr,tt]=metrics(S, reshape(x,4,S.P).');
    par(im,:)=[g,rr,tt];
    fprintf('mu=%4.1f -> gain=%.3f | worstOmega sqrtCRLBr=%.3f mm | sqrtCRLBth=%.4f deg\n',mu,g,rr,tt);
end
results.mus=mus; results.pareto=par; results.baseline=[gb,rb,tb];

[~,ord]=sort(par(:,1));
setpub(); fig=figure('Position',[100 100 980 380],'Color','w');
subplot(1,2,1);
plot(par(ord,1),par(ord,2),'o-','DisplayName','penalty+BCD Pareto'); hold on;
plot(gb,rb,'kp','MarkerSize',13,'MarkerFaceColor','k','DisplayName','baseline'); grid on;
xlabel('worst-\Omega communication array gain','Interpreter','tex');
ylabel('worst-\Omega range CRLB^{1/2} [mm]','Interpreter','tex');
title('Communication-sensing Pareto (range)','Interpreter','tex');
hleg=legend('show'); set(hleg,'Interpreter','tex','Location','northeast');
subplot(1,2,2);
plot(par(ord,1),par(ord,3),'o-','DisplayName','penalty+BCD Pareto'); hold on;
plot(gb,tb,'kp','MarkerSize',13,'MarkerFaceColor','k','DisplayName','baseline'); grid on;
xlabel('worst-\Omega communication array gain','Interpreter','tex');
ylabel('worst-\Omega angle CRLB^{1/2} [deg]','Interpreter','tex');
title('Communication-sensing Pareto (angle)','Interpreter','tex');
hleg=legend('show'); set(hleg,'Interpreter','tex','Location','northeast');
savepub(fig, fullfile(here,'fig_codebook_bcd'));
end

% ===================================================================
function W = build_cb(sys, Pm)
P=size(Pm,1); W=zeros(sys.Nt,P,sys.M);
for s=1:P
    W(:,s,:)=delay_polar_2d(sys.Nt,sys.B,sys.fc,sys.M,sys.d,Pm(s,1),Pm(s,3),Pm(s,2),Pm(s,4),1);
end
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

function v = phi(x, S, mu)
[sens,gmin]=metrics(S, reshape(x,4,S.P).'); v=sens - mu*gmin;
end

function g = best_gain(W, sys, theta, r)
H=near_field_channel(sys.Nt,sys.d,sys.fc,sys.B,sys.M,r,theta); g=0;
for s=1:size(W,2)
    Ws=reshape(W(:,s,:),sys.Nt,sys.M); g=max(g,max(abs(sum((H.').*Ws,1)).^2));
end
end

function x=setidx(x,idx,v), x(idx)=v; end
function setpub(), set(0,'defaultAxesFontSize',12,'defaultLineLineWidth',1.7); end
function savepub(fig,base)
try, exportgraphics(fig,[base '.pdf'],'ContentType','vector'); catch, end
print(fig,[base '.png'],'-dpng','-r200'); fprintf('saved -> %s.png\n',base);
end
