#!/usr/bin/env python3
"""
Option B — Section V core contribution (fast proof-of-concept).

Two-stage active beam training: Stage-1 coarse search localises the user to an
uncertainty region Ω={θ∈[θ0±Δθ], r∈[r0±Δr]}; Stage-2 designs the beam-split
TRAINING codewords to minimise the sensing CRLB over Ω under a communication
array-gain floor.  The dominant design lever is the *concentration* of the
beam-split sweep: the baseline codebook sweeps the WHOLE angle-range space
(θ2≈15), wasting most subcarrier energy outside Ω; once Ω is known, the sweep
span can be shrunk to cover just Ω, concentrating all M subcarriers on the user
→ higher Fisher information → lower CRLB, at higher communication gain.

We sweep the coverage width w (angle-sweep span of the effective beam-split
focus) from tight (≈Ω extent) to broad (baseline) and report worst-Ω √CRLB and
worst-Ω comm gain. Noise is FIXED absolute so concentration genuinely helps.
CRLB via the validated semi-closed-form FIM (crlb_closed_form).
"""
import os, numpy as np
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
import crlb_closed_form as cf

SNR_dB = 10.0
SIGMA2 = 10**(-SNR_dB/10)                 # fixed absolute noise
th0 = np.radians(11.54); r0 = 20.0
dth = np.radians(1.0);  dr = 2.0
OMEGA = [(t, r) for t in th0+np.linspace(-dth, dth, 3) for r in r0+np.linspace(-dr, dr, 3)]
vth0 = np.sin(th0); a0 = np.cos(th0)**2/(2*r0)              # Ω centre in (ϑ,α)

# frequency-ratio range of the beam-split sweep  (ϑ_eff(m)=θ1+(fc/fm)θ2)
ratio = cf.fc/cf.fm; rmin, rmax, rmid = ratio.min(), ratio.max(), ratio.mean()
dspan = rmax - rmin
# Ω extents in (ϑ,α)
vext = np.cos(th0)*(2*dth); aext = abs(np.cos(th0)**2/(2*(r0-dr)) - np.cos(th0)**2/(2*(r0+dr)))

def focused_codebook(wv):
    """Beam-split codebook whose effective focus sweeps an angle span wv (and a
    proportional α span) centred on Ω. wv→Ω-extent = tight focus; wv large = baseline-like."""
    wa = wv*(aext/vext)                                     # proportional α coverage
    th2 = wv/dspan;  th1 = vth0 - rmid*th2
    al2 = wa/dspan;  al1 = a0  - rmid*al2
    P = np.array([[th1, al1, th2, al2],                     # pilot 0
                  [th1, al1, th2, al2]])                    # pilot 1 (same focus)
    return cf.codebook_free(P)

def best_gain(W, t, r):
    H = cf.channel(t, r)
    return max(np.abs(np.einsum('mn,nm->m', H, W[:, s, :])).max()**2 for s in range(cf.k0))

def worstΩ(W):
    crs = [cf.fim_closed(W, t, r, 1.0, SNR_dB, sigma2=SIGMA2)[:2] for t, r in OMEGA]
    tt = max(c[0] for c in crs)**.5; rr = max(c[1] for c in crs)**.5
    gg = min(best_gain(W, t, r) for t, r in OMEGA)
    return np.degrees(tt), rr*1e3, gg

# baseline (space-covering) codebook
tb, rb, gb = worstΩ(cf.codebook())
print("=== Section V proof-of-concept: sensing-optimal (Ω-focused) training codebook ===")
print(f"Ω: θ0=11.54°±1°, r0=20±2 m (9 pts) | fixed SNR_ref={SNR_dB} dB")
print(f"[baseline sweep] worst-Ω √CRLBθ={tb:.3e} deg | √CRLBr={rb:.3e} mm | comm gain={gb:.3f}")
print(f"Ω angle extent≈{vext:.3f} (ϑ) ; baseline sweep span≈{15*dspan:.2f} (ϑ)\n")

widths = np.geomspace(vext*0.8, 15*dspan, 22)
res = np.array([worstΩ(focused_codebook(w)) for w in widths])   # cols: √CRLBθ[deg], √CRLBr[mm], gain
# best feasible focus (comm gain >= baseline) minimising range CRLB
feas = res[:, 2] >= gb
kbest = np.where(feas)[0][np.argmin(res[feas, 1])]
tbest, rbest, gbest = res[kbest]
print(f"best Ω-focused (gain≥baseline): width={widths[kbest]:.3f} | √CRLBθ={tbest:.3e} deg | "
      f"√CRLBr={rbest:.3e} mm | gain={gbest:.3f}")
print(f"  -> range CRLB improvement {rb/rbest:.2f}× | angle CRLB improvement {tb/tbest:.2f}× | "
      f"gain {gb:.2f}->{gbest:.2f}")

fig, ax = plt.subplots(1, 2, figsize=(11.5, 4.3))
ax[0].semilogx(widths, res[:, 1], 'o-', label='Ω-focused codebook')
ax[0].axhline(rb, ls='--', c='k', label='baseline (space-covering)')
ax[0].axvline(vext, ls=':', c='g', label='Ω angle extent')
ax[0].set(xlabel='beam-split coverage width  w  (ϑ span)', ylabel='worst-Ω √CRLB range [mm]',
          title='Concentrate the sweep on Ω → lower range CRLB'); ax[0].grid(alpha=.3, which='both'); ax[0].legend()
ax[1].plot(res[:, 2], res[:, 1], 'o-', label='trade-off (vary w)')
ax[1].scatter([gb], [rb], c='k', marker='*', s=160, zorder=5, label='baseline')
ax[1].scatter([gbest], [rbest], c='r', marker='D', s=70, zorder=5, label='chosen design')
ax[1].set(xlabel='worst-Ω communication array gain', ylabel='worst-Ω √CRLB range [mm]',
          title='Communication–sensing trade-off'); ax[1].grid(alpha=.3); ax[1].legend()
fig.suptitle('Option B §V — Ω-focused sensing-optimal beam-split training codebook (semi-closed CRLB)')
fig.tight_layout()
outp = os.path.join(os.path.dirname(os.path.abspath(__file__)), "crlb_pareto.png")
fig.savefig(outp, dpi=130); print("saved ->", outp)
