#!/usr/bin/env python3
"""
Option B §V — penalty/scalarization + block-coordinate-descent (BCD) optimizer
for the CRLB-optimal beam-split TRAINING codebook, and the formal
communication-sensing Pareto frontier.

Mirrors the DPP-ISAC competitor's solution structure (BCD that decouples the
TTD 'delay' block from the PS 'phase' block), applied to our TRAINING-codebook
active-experiment-design problem over an uncertainty region Ω.

The genuine trade-off is: concentrate the beam-split sweep for high communication
array GAIN, vs. diversify the looks across Ω for better SENSING conditioning
(lower worst-case CRLB). We scalarize
    Phi(C; mu) = max_{(θ,r)∈Ω}[CRLBθ/σθ0² + CRLBr/σr0²]  −  mu · min_{Ω} G(θ,r;C)
and sweep the weight mu (mu=0 -> sensing-optimal; large mu -> gain-optimal),
solving each by BCD (alternate Nelder-Mead over the TTD block and the PS block).
CRLB via the validated semi-closed-form FIM.
"""
import os, numpy as np
from scipy.optimize import minimize
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
import crlb_closed_form as cf

SNR_dB = 10.0; SIGMA2 = 10**(-SNR_dB/10)
th0 = np.radians(11.54); r0 = 20.0; dth = np.radians(1.0); dr = 2.0
OMEGA = [(t, r) for t in th0+np.linspace(-dth, dth, 3) for r in r0+np.linspace(-dr, dr, 3)]
vth0 = np.sin(th0); a0 = np.cos(th0)**2/(2*r0)
ratio = cf.fc/cf.fm; dspan = ratio.max()-ratio.min(); rmid = ratio.mean()
vext = np.cos(th0)*2*dth
aext = abs(np.cos(th0)**2/(2*(r0-dr)) - np.cos(th0)**2/(2*(r0+dr)))

Wb = cf.codebook()
ct0, cr0, _ = cf.fim_closed(Wb, th0, r0, 1.0, SNR_dB, sigma2=SIGMA2)
s_th, s_r = ct0, cr0

def best_gain(W, t, r):
    H = cf.channel(t, r)
    return max(np.abs(np.einsum('mn,nm->m', H, W[:, s, :])).max()**2 for s in range(cf.k0))

def sens_gain(x):
    W = cf.codebook_free(x.reshape(cf.k0, 4)); sens = 0.0; gmin = np.inf; ctm = 0; crm = 0
    for t, r in OMEGA:
        ctv, crv, _ = cf.fim_closed(W, t, r, 1.0, SNR_dB, sigma2=SIGMA2)
        sens = max(sens, ctv/s_th + crv/s_r); ctm = max(ctm, ctv); crm = max(crm, crv)
        gmin = min(gmin, best_gain(W, t, r))
    return sens, gmin, np.degrees(np.sqrt(ctm)), np.sqrt(crm)*1e3

def phi(x, mu):
    s, g, _, _ = sens_gain(x); return s - mu*g

TTD = [0, 1, 4, 5]; PS = [2, 3, 6, 7]
def bcd(x0, mu, outer=4):
    x = x0.copy()
    for _ in range(outer):
        for blk in (TTD, PS):
            def sub(v):
                xx = x.copy(); xx[blk] = v; return phi(xx, mu)
            r = minimize(sub, x[blk], method='Nelder-Mead',
                         options=dict(xatol=1e-3, fatol=1e-6, maxiter=500))
            x[blk] = r.x
    return x

# diverse 2-tile focused warm start (each pilot covers half of Omega)
rows = []
for s in range(cf.k0):
    w = vext/cf.k0; wa = aext/cf.k0
    cs = vth0 - vext/2 + (s+0.5)*w; ac = a0 - aext/2 + (s+0.5)*wa
    t2 = w/dspan; t1 = cs - rmid*t2; a2 = wa/dspan; a1 = ac - rmid*a2
    rows.append([t1, a1, t2, a2])
x0 = np.array(rows).ravel()

mus = [0.0, 0.5, 1.0, 2.0, 4.0, 8.0]
print("=== §V penalty+BCD optimizer — communication-sensing Pareto ===")
sb, gb, tb, rb = sens_gain(cf.BASE_FREE.ravel().astype(float))
print(f"[baseline] gain={gb:.3f} | worst-Ω √CRLBr={rb:.3f} mm | √CRLBθ={tb:.4f} deg")
x = x0.copy(); pareto = []
for mu in mus:
    x = bcd(x, mu)
    s, g, tt, rr = sens_gain(x)
    pareto.append((g, rr, tt))
    print(f"mu={mu:4.1f} -> gain={g:.3f} | worst-Ω √CRLBr={rr:.3f} mm | √CRLBθ={tt:.4f} deg")
pareto = np.array(pareto)

order = np.argsort(pareto[:,0])
fig, ax = plt.subplots(1, 2, figsize=(11.5, 4.3))
ax[0].plot(pareto[order,0], pareto[order,1], 'o-', label='penalty+BCD Pareto')
ax[0].scatter([gb],[rb], c='k', marker='*', s=170, zorder=5, label='baseline')
ax[0].set(xlabel='worst-$\\Omega$ communication array gain',
          ylabel='worst-$\\Omega$ $\\sqrt{\\mathrm{CRLB}}_r$ [mm]',
          title='Communication-sensing Pareto (range)'); ax[0].grid(alpha=.3); ax[0].legend()
ax[1].plot(pareto[order,0], pareto[order,2], 'o-', label='penalty+BCD Pareto')
ax[1].scatter([gb],[tb], c='k', marker='*', s=170, zorder=5, label='baseline')
ax[1].set(xlabel='worst-$\\Omega$ communication array gain',
          ylabel='worst-$\\Omega$ $\\sqrt{\\mathrm{CRLB}}_\\theta$ [deg]',
          title='Communication-sensing Pareto (angle)'); ax[1].grid(alpha=.3); ax[1].legend()
fig.suptitle('Option B §V — penalty+BCD CRLB-optimal training codebook: comm-sensing Pareto')
fig.tight_layout()
outp = os.path.join(os.path.dirname(os.path.abspath(__file__)), "crlb_bcd_pareto.png")
fig.savefig(outp, dpi=130); print("saved ->", outp)
