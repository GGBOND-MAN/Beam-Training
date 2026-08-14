function results = run_baselines()
%RUN_BASELINES  Option B: overhead vs accuracy for THREE methods —
%   (i)  exhaustive 2-D polar search  (NARROWBAND: 1 look/pilot, no beam split;
%        the classical high-overhead near-field baseline),
%   (ii) baseline beam split          (wideband space-covering sweep),
%   (iii)proposed                     (CRLB-optimal Omega-focused beam split).
%   Reuses delay_polar_2d.m / near_field_channel.m / crlb_fim.m. MATLAB + Octave.
%
%   Key point: a wideband beam-split pilot gives M subcarrier looks (time-of-
%   flight ranging), while an exhaustive polar codeword is narrowband (1 look).
%   Exhaustive polar therefore cannot range below ~metres and needs O(N_theta*S)
%   pilots to sweep the whole space with no coarse prior.

c = 3e8;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'baseline_distance_dependent', ...
    'code_nf_distance_dependent_rainbow'));

sys.Nt=128; sys.fc=10e9; sys.B=2e9; sys.M=512; sys.d=(c/sys.fc)/2;
SNR_dB=10; sigma2=10^(-SNR_dB/10);  MC=round(sys.M/2);
th0=deg2rad(11.54); r0=20; dth=deg2rad(1); dr=2;
[TT,RR]=ndgrid(th0+linspace(-dth,dth,3), r0+linspace(-dr,dr,3)); Omega=[TT(:),RR(:)];
vth0=sin(th0); a0=cos(th0)^2/(2*r0);
fm=sys.fc+sys.B/sys.M*((1:sys.M)-1-(sys.M-1)/2); ratio=sys.fc./fm;
dspan=max(ratio)-min(ratio); rmid=mean(ratio);
vext=cos(th0)*2*dth; aext=abs(cos(th0)^2/(2*(r0-dr))-cos(th0)^2/(2*(r0+dr)));

Ts=[1 2 3 4 6 8 12 16];
exh=nan(numel(Ts),2); bas=exh; pro=exh;   % [sqrtCRLBth(deg), sqrtCRLBr(mm)]
for i=1:numel(Ts)
    [tb,rb]=worstO(baseline_cb(sys,Ts(i)),      sys,Omega,sigma2,[]);   bas(i,:)=[rad2deg(tb), rb*1e3];
    [tp,rp]=worstO(proposed_cb(sys,Ts(i),vth0,a0,vext,aext,dspan,rmid), sys,Omega,sigma2,[]); pro(i,:)=[rad2deg(tp), rp*1e3];
    [te,re]=worstO(exhaustive_cb(sys,Ts(i),vth0,a0,vext,aext),          sys,Omega,sigma2,MC);  exh(i,:)=[rad2deg(te), re*1e3];
end

fprintf('=== overhead vs worst-Omega range CRLB [mm] (exhaustive = narrowband) ===\n');
fprintf('%3s | %13s | %12s | %10s\n','T','exh.polar(NB)','baseline BS','proposed');
for i=1:numel(Ts)
    fprintf('%3d | %13.3f | %12.3f | %10.3f\n', Ts(i), exh(i,2), bas(i,2), pro(i,2));
end
fprintf('NOTE: exhaustive polar also needs O(N_theta*S) pilots to sweep full space (~%d*S).\n', sys.Nt);
results.Ts=Ts; results.exh=exh; results.bas=bas; results.pro=pro;

setpub(); fig=figure('Position',[100 100 990 390],'Color','w');
ok = exh(:,2) < 1e4;   % drop rank-deficient / >10 m exhaustive points
subplot(1,2,1);
loglog(Ts(ok),exh(ok,2),'^:','DisplayName','exhaustive 2D polar (narrowband)'); hold on;
loglog(Ts,bas(:,2),'o--','DisplayName','baseline beam split (wideband)');
loglog(Ts,pro(:,2),'s-','DisplayName','proposed (CRLB-optimal)');
yline_(5,'r-.','5 mm target'); grid on;
xlabel('refinement pilots T','Interpreter','tex');
ylabel('worst-\Omega range CRLB^{1/2} [mm]','Interpreter','tex');
title('RANGE CRLB vs pilots (bandwidth matters)','Interpreter','tex');
hleg=legend('show'); set(hleg,'Interpreter','tex','Location','southwest','FontSize',8);
subplot(1,2,2);
loglog(Ts(ok),exh(ok,1),'^:','DisplayName','exhaustive 2D polar (NB)'); hold on;
loglog(Ts,bas(:,1),'o--','DisplayName','baseline beam split');
loglog(Ts,pro(:,1),'s-','DisplayName','proposed'); grid on;
xlabel('refinement pilots T','Interpreter','tex');
ylabel('worst-\Omega angle CRLB^{1/2} [deg]','Interpreter','tex');
title('ANGLE CRLB vs pilots','Interpreter','tex');
hleg=legend('show'); set(hleg,'Interpreter','tex','Location','southwest','FontSize',8);
savepub(fig, fullfile(here,'fig_baselines'));
end

% ===================================================================
function W = baseline_cb(sys,T)
W=zeros(sys.Nt,T,sys.M);
for s=1:T, W(:,s,:)=delay_polar_2d(sys.Nt,sys.B,sys.fc,sys.M,sys.d,-31-(s-1)*(2/T),15,-0.454,0.5,1); end
end
function W = proposed_cb(sys,T,vth0,a0,vext,aext,dspan,rmid)
W=zeros(sys.Nt,T,sys.M);
for s=1:T
    w=vext/T; wa=aext/T; cs=vth0-vext/2+(s-0.5)*w; ac=a0-aext/2+(s-0.5)*wa;
    t2=w/dspan; t1=cs-rmid*t2; a2=wa/dspan; a1=ac-rmid*a2;
    W(:,s,:)=delay_polar_2d(sys.Nt,sys.B,sys.fc,sys.M,sys.d,t1,t2,a1,a2,1);
end
end
function W = exhaustive_cb(sys,T,vth0,a0,vext,aext)   % T PS-focused polar beams tiling Omega
a=max(round(sqrt(T)),1); b=ceil(T/a);
vs=vth0-vext/2+((1:a)-0.5)*(vext/a); as_=a0-aext/2+((1:b)-0.5)*(aext/b);
cells=zeros(a*b,2); k=0; for iv=1:a, for ia=1:b, k=k+1; cells(k,:)=[vs(iv) as_(ia)]; end; end
cells=cells(1:T,:); W=zeros(sys.Nt,T,sys.M);
for s=1:T, W(:,s,:)=delay_polar_2d(sys.Nt,sys.B,sys.fc,sys.M,sys.d,0,cells(s,1),0,cells(s,2),1); end
end

function [tt,rr] = worstO(W,sys,Omega,sigma2,subc)
ct=zeros(size(Omega,1),1); cr=ct;
for q=1:size(Omega,1)
    [ct(q),cr(q)]=crlb_fim(W,sys,Omega(q,1),Omega(q,2),1,sigma2,subc);
end
tt=sqrt(max(ct)); rr=sqrt(max(cr));
end

function setpub(), set(0,'defaultAxesFontSize',12,'defaultLineLineWidth',1.7); end
function yline_(y,style,name), xl=xlim; plot(xl,[y y],style,'DisplayName',name); end
function savepub(fig,base)
try, exportgraphics(fig,[base '.pdf'],'ContentType','vector'); catch, end
print(fig,[base '.png'],'-dpng','-r200'); fprintf('saved -> %s.png\n',base);
end
