#!/usr/bin/env python3
"""
Option B §V — ablation: is each block of the penalty+BCD codebook optimizer
necessary? Design variables split into the TTD ("delay", frequency-dependent
beam-split trajectory) block {(theta1,alpha1)_s} and the PS ("phase", frequency-
flat base focus) block {(theta2,alpha2)_s}. We compare, at the trade-off knee
(mu=0.5), optimizing:
  (1) Full BCD  (TTD + PS),
  (2) TTD-only  (PS frozen at the focused init),
  (3) PS-only   (TTD frozen at the focused init),
  (4) No opt.   (focused warm-start, neither optimized),
  (5) Baseline  (space-covering codebook),
under the SAME semi-closed CRLB. Removing either block should degrade a
different axis -> both are necessary.
"""
import os, numpy as np
from scipy.optimize import minimize
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
import crlb_closed_form as cf

SNR_dB = 10.0; SIGMA2 = 10**(-SNR_dB/10); MU = 0.5
th0 = np.radians(11.54); r0 = 20.0; dth = np.radians(1.0); dr = 2.0
OMEGA = [(t, r) for t in th0+np.linspace(-dth, dth, 3) for r in r0+np.linspace(-dr, dr, 3)]
vth0 = np.sin(th0); a0 = np.cos(th0)**2/(2*r0)
ratio = cf.fc/cf.fm; dspan = ratio.max()-ratio.min(); rmid = ratio.mean()
vext = np.cos(th0)*2*dth; aext = abs(np.cos(th0)**2/(2*(r0-dr))-np.cos(th0)**2/(2*(r0+dr)))

Wb = cf.codebook()
s_th, s_r = cf.fim_closed(Wb, th0, r0, 1.0, SNR_dB, sigma2=SIGMA2)[:2]

def best_gain(W, t, r):
    H = cf.channel(t, r)
    return max(np.abs(np.einsum('mn,nm->m', H, W[:, s, :])).max()**2 for s in range(cf.k0))

def metr(x):
    W = cf.codebook_free(x.reshape(cf.k0, 4)); sens = 0; g = np.inf; ctm = crm = 0
    for t, r in OMEGA:
        ct, crr, _ = cf.fim_closed(W, t, r, 1.0, SNR_dB, sigma2=SIGMA2)
        sens = max(sens, ct/s_th+crr/s_r); ctm = max(ctm, ct); crm = max(crm, crr)
        g = min(g, best_gain(W, t, r))
    return sens, g, np.degrees(np.sqrt(ctm)), np.sqrt(crm)*1e3

def phi(x, mu): s, g, _, _ = metr(x); return s - mu*g

TTD = [0, 1, 4, 5]; PS = [2, 3, 6, 7]
def bcd(x0, blocks, outer=5):
    x = x0.copy()
    for _ in range(outer):
        for blk in blocks:
            def sub(v):
                xx = x.copy(); xx[blk] = v; return phi(xx, MU)
            x[blk] = minimize(sub, x[blk], method='Nelder-Mead',
                              options=dict(xatol=1e-3, fatol=1e-6, maxiter=500)).x
    return x

# focused 2-tile warm start
rows = []
for s in range(cf.k0):
    w = vext/cf.k0; wa = aext/cf.k0
    cs = vth0-vext/2+(s+0.5)*w; ac = a0-aext/2+(s+0.5)*wa
    t2 = w/dspan; t1 = cs-rmid*t2; a2 = wa/dspan; a1 = ac-rmid*a2
    rows.append([t1, a1, t2, a2])
x0 = np.array(rows).ravel()

variants = [
    ("Baseline (space-cover)", cf.BASE_FREE.ravel().astype(float)),
    ("No opt (focused init)",  x0),
    ("PS-only (freeze TTD)",   bcd(x0, [PS])),
    ("TTD-only (freeze PS)",   bcd(x0, [TTD])),
    ("Full BCD (TTD+PS)",      bcd(x0, [TTD, PS])),
]
print(f"=== Ablation of the BCD blocks (mu={MU}) ===")
print(f"{'variant':>24} | {'sqrtCRLBr[mm]':>13} | {'sqrtCRLBth[deg]':>15} | {'gain':>6}")
rows_out = []
for name, x in variants:
    s, g, tt, rr = metr(x)
    rows_out.append((name, rr, tt, g)); print(f"{name:>24} | {rr:>13.3f} | {tt:>15.4f} | {g:>6.3f}")

labels = [r[0] for r in rows_out]; rr = np.array([r[1] for r in rows_out])
tt = np.array([r[2] for r in rows_out]); gg = np.array([r[3] for r in rows_out])
xpos = np.arange(len(labels)); col = ['#8a95a3', '#b0a06a', '#e0894a', '#4c9be8', '#2563a8']
fig, ax = plt.subplots(1, 3, figsize=(13, 4.0))
for a, val, ttl, unit in [(ax[0], rr, 'worst-$\\Omega$ range CRLB', 'mm'),
                          (ax[1], tt, 'worst-$\\Omega$ angle CRLB', 'deg'),
                          (ax[2], gg, 'worst-$\\Omega$ comm. gain', '')]:
    a.bar(xpos, val, color=col); a.set_xticks(xpos); a.set_xticklabels(labels, rotation=32, ha='right', fontsize=8)
    a.set_title(ttl, fontsize=11); a.set_ylabel(unit); a.grid(axis='y', alpha=.3)
    if unit != '': a.set_yscale('log') if val.max()/max(val.min(),1e-9) > 12 else None
fig.suptitle('Option B §V — ablation: both TTD and PS blocks are necessary')
fig.tight_layout()
outp = os.path.join(os.path.dirname(os.path.abspath(__file__)), "crlb_ablation.png")
fig.savefig(outp, dpi=130); print("saved ->", outp)
