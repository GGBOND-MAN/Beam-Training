#!/usr/bin/env python3
"""
Option B — Second pillar: TRAINING-OVERHEAD ↔ LOCALIZATION-CRLB trade-off.

Because the Fisher information is ADDITIVE over training slots,
    J(T) = Σ_{s=1}^{T} J_s ,
adding beam-split training codewords (slots) monotonically lowers the CRLB.
For T informative looks over the uncertainty region Ω the sensing information
grows ~linearly, so √CRLB ∝ T^{-1/2}. The CRLB-optimal (Ω-focused) codebook
reaches a target accuracy with far fewer slots than the space-covering
baseline — i.e. an overhead saving at fixed accuracy. This script quantifies
that curve (fixed per-slot power, absolute noise; semi-closed-form FIM).
"""
import os, numpy as np
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt

c = 3e8; Nt, fc, B, M = 128, 10e9, 2e9, 512
d = (c/fc)/2; nn = np.arange(-(Nt-1)/2, (Nt-1)/2+1)
fm = fc + B/M*(np.arange(1, M+1)-1-(M-1)/2); km = 2*np.pi*fm/c; kc = 2*np.pi*fc/c
SNR_dB = 10.0; SIGMA2 = 10**(-SNR_dB/10)

th0 = np.radians(11.54); r0 = 20.0; dth = np.radians(1.0); dr = 2.0
OMEGA = [(t, r) for t in th0+np.linspace(-dth, dth, 3) for r in r0+np.linspace(-dr, dr, 3)]
vth0 = np.sin(th0); a0 = np.cos(th0)**2/(2*r0)
ratio = fc/fm; dspan = ratio.max()-ratio.min(); rmid = ratio.mean()
vext = np.cos(th0)*2*dth; aext = abs(np.cos(th0)**2/(2*(r0-dr))-np.cos(th0)**2/(2*(r0+dr)))

def cw(t1, a1, t2, a2):
    ncol = nn.reshape(-1, 1)
    return 1/np.sqrt(Nt)*np.exp(-1j*km[None, :]*(ncol*d*t1-ncol**2*d**2*a1)
                                -1j*kc*(ncol*d*t2-ncol**2*d**2*a2))     # Nt x M

def channel(theta, r):
    rn = np.sqrt(r**2+(nn*d)**2-2*r*nn*d*np.sin(theta))
    return np.exp(-1j*np.outer(km, rn))/np.sqrt(Nt)                      # M x Nt

def fim(Wlist, theta, r):
    """semi-closed FIM summed over all training slots; Wlist: list of (Nt x M)."""
    H = channel(theta, r); st, ct = np.sin(theta), np.cos(theta)
    D = []
    for Ws in Wlist:
        g = H*Ws.T                                                      # M x Nt
        G0 = g.sum(1); G1 = (g*nn).sum(1); G2 = (g*nn**2).sum(1)
        dth_ = 1j*km*(d*ct*G1+(d**2*ct*st/r)*G2)
        dr_ = -1j*km*(G0-(d**2*ct**2/(2*r**2))*G2)
        D.append(np.column_stack([dth_, dr_, G0, 1j*G0]))
    D = np.vstack(D)
    J = (2/SIGMA2)*np.real(D.conj().T @ D)
    C = np.linalg.inv(J); return C[0, 0], C[1, 1]

def best_gain(Wlist, theta, r):
    H = channel(theta, r)
    return max(np.abs(np.einsum('mn,nm->m', H, Ws)).max()**2 for Ws in Wlist)

def worstΩ(Wlist):
    cs = [fim(Wlist, t, r) for t, r in OMEGA]
    return max(c[0] for c in cs)**.5, max(c[1] for c in cs)**.5, min(best_gain(Wlist, t, r) for t, r in OMEGA)

def baseline_T(T):                       # space-covering sweep, T slots
    return [cw(-31 - s*(2/T), -0.454, 15, 0.5) for s in range(T)]

def focused_T(T):                        # Ω-focused, T slots tiling Ω angle span
    Wl = []
    for s in range(T):
        # each slot focuses a 1/T-width tile of Ω (concentration ∝ T)
        w = vext/T; wa = aext/T
        csub = vth0 - vext/2 + (s+0.5)*w
        acsub = a0 - aext/2 + (s+0.5)*wa
        t2 = w/dspan; t1 = csub - rmid*t2
        a2 = wa/dspan; a1 = acsub - rmid*a2
        Wl.append(cw(t1, a1, t2, a2))
    return Wl

Ts = np.arange(1, 9)
base = np.array([worstΩ(baseline_T(T)) for T in Ts])     # √CRLBθ[rad],√CRLBr[m],gain
foc  = np.array([worstΩ(focused_T(T)) for T in Ts])

print("=== Second pillar: training-overhead T vs worst-Ω localization CRLB ===")
print(f"{'T':>2} | {'baseline √CRLBr[mm]':>20} {'gain':>6} | {'Ω-focused √CRLBr[mm]':>20} {'gain':>6}")
for i, T in enumerate(Ts):
    print(f"{T:>2} | {base[i,1]*1e3:>20.3f} {base[i,2]:>6.3f} | {foc[i,1]*1e3:>20.3f} {foc[i,2]:>6.3f}")

# 1/sqrt(T) scaling check on the focused design (fit √CRLBr = a * T^p)
p_foc = np.polyfit(np.log(Ts), np.log(foc[:,1]), 1)[0]
p_base = np.polyfit(np.log(Ts), np.log(base[:,1]), 1)[0]
print(f"\nscaling exponent (√CRLBr ∝ T^p):  focused p={p_foc:.2f}  baseline p={p_base:.2f}  (theory -0.5)")

# overhead saving at a fixed target range accuracy
target_mm = 5.0
def slots_needed(arr):
    ok = np.where(arr[:,1]*1e3 <= target_mm)[0]
    return Ts[ok[0]] if len(ok) else np.inf
Tb, Tf = slots_needed(base), slots_needed(foc)
print(f"slots to reach {target_mm} mm range accuracy:  baseline={Tb}  Ω-focused={Tf}  "
      f"-> overhead saving {(1-Tf/Tb)*100:.0f}%" if np.isfinite(Tb) and np.isfinite(Tf) else
      f"slots to reach {target_mm} mm: baseline={Tb}, focused={Tf}")

fig, ax = plt.subplots(1, 2, figsize=(11.5, 4.3))
ax[0].loglog(Ts, base[:,1]*1e3, 'o--', label='baseline (space-covering)')
ax[0].loglog(Ts, foc[:,1]*1e3, 's-', label='CRLB-optimal (Ω-focused)')
ax[0].loglog(Ts, foc[0,1]*1e3/np.sqrt(Ts), 'k:', label=r'$T^{-1/2}$ reference')
ax[0].axhline(target_mm, color='r', ls='-.', lw=1, label=f'{target_mm:.0f} mm target')
ax[0].set(xlabel='training overhead  T  (# beam-split slots)', ylabel='worst-Ω √CRLB range [mm]',
          title='Localization CRLB vs training overhead'); ax[0].grid(alpha=.3, which='both'); ax[0].legend(fontsize=8)
ax[1].semilogy(Ts, np.degrees(base[:,0]), 'o--', label='baseline')
ax[1].semilogy(Ts, np.degrees(foc[:,0]), 's-', label='Ω-focused')
ax[1].set(xlabel='training overhead  T', ylabel='worst-Ω √CRLB angle [deg]',
          title='Angle CRLB vs overhead'); ax[1].grid(alpha=.3, which='both'); ax[1].legend(fontsize=8)
fig.suptitle('Option B — 2nd pillar: overhead–accuracy trade-off of the training codebook')
fig.tight_layout()
outp = os.path.join(os.path.dirname(os.path.abspath(__file__)), "crlb_overhead.png")
fig.savefig(outp, dpi=130); print("saved ->", outp)
