#!/usr/bin/env python3
"""
Option B — three-way overhead↔accuracy comparison:
  (i)  Exhaustive 2-D polar search   — T phase-shifter-focused polar codewords
       tiling Omega (no beam split; the classical high-overhead near-field
       baseline), evaluated under the SAME off-grid ML / semi-closed CRLB;
  (ii) Baseline beam split           — space-covering distance-dependent sweep;
  (iii)Proposed                      — CRLB-optimal (Omega-focused) beam split.
All reuse the baseline delay_polar_2d channel model. Fixed absolute noise.
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
vext = np.cos(th0)*2*dth
aext = abs(np.cos(th0)**2/(2*(r0-dr)) - np.cos(th0)**2/(2*(r0+dr)))

def cw(t1, a1, t2, a2):
    ncol = nn.reshape(-1, 1)
    return 1/np.sqrt(Nt)*np.exp(-1j*km[None, :]*(ncol*d*t1-ncol**2*d**2*a1)
                                -1j*kc*(ncol*d*t2-ncol**2*d**2*a2))     # Nt x M

def channel(theta, r):
    rn = np.sqrt(r**2+(nn*d)**2-2*r*nn*d*np.sin(theta))
    return np.exp(-1j*np.outer(km, rn))/np.sqrt(Nt)

def fim(Wl, theta, r, subc=None):
    # subc = subcarrier index subset to observe (None -> all M, wideband).
    # Narrowband exhaustive polar search observes ONE subcarrier per pilot.
    idx = np.arange(M) if subc is None else np.asarray(subc)
    H = channel(theta, r); st, ct = np.sin(theta), np.cos(theta); D = []
    for Ws in Wl:
        g = (H*Ws.T)[idx]; kmi = km[idx]
        G0 = g.sum(1); G1 = (g*nn).sum(1); G2 = (g*nn**2).sum(1)
        D.append(np.column_stack([1j*kmi*(d*ct*G1+(d**2*ct*st/r)*G2),
                                  -1j*kmi*(G0-(d**2*ct**2/(2*r**2))*G2), G0, 1j*G0]))
    D = np.vstack(D); J = (2/SIGMA2)*np.real(D.conj().T@D)
    try: C = np.linalg.inv(J)
    except np.linalg.LinAlgError: return np.inf, np.inf
    if np.min(np.linalg.eigvalsh(J)) <= 0: return np.inf, np.inf
    return C[0, 0], C[1, 1]

def best_gain(Wl, theta, r):
    H = channel(theta, r)
    return max(np.abs(np.einsum('mn,nm->m', H, Ws)).max()**2 for Ws in Wl)

def worstO(Wl, subc=None):
    cs = [fim(Wl, t, r, subc) for t, r in OMEGA]
    return max(c[0] for c in cs)**.5, max(c[1] for c in cs)**.5, min(best_gain(Wl, t, r) for t, r in OMEGA)

MC = M//2   # center subcarrier for the narrowband exhaustive polar search

def baseline_T(T):
    return [cw(-31-s*(2/T), -0.454, 15, 0.5) for s in range(T)]

def proposed_T(T):                 # Omega-focused beam split, T tiles
    Wl = []
    for s in range(T):
        w = vext/T; wa = aext/T
        cs = vth0-vext/2+(s+0.5)*w; ac = a0-aext/2+(s+0.5)*wa
        t2 = w/dspan; t1 = cs-rmid*t2; a2 = wa/dspan; a1 = ac-rmid*a2
        Wl.append(cw(t1, a1, t2, a2))
    return Wl

def exhaustive_polar_T(T):         # T PS-focused polar beams tiling Omega (no beam split)
    a = int(round(np.sqrt(T))); b = int(np.ceil(T/max(a, 1))); a = max(a, 1)
    vs = vth0-vext/2 + (np.arange(a)+0.5)*(vext/a)
    as_ = a0-aext/2 + (np.arange(b)+0.5)*(aext/b)
    cells = [(v, al) for v in vs for al in as_][:T]
    return [cw(0.0, 0.0, v, al) for v, al in cells]   # theta1=alpha1=0 -> pure PS focus

Ts = np.array([1, 2, 3, 4, 6, 8, 12, 16])
# beam-split methods: wideband (M subcarrier looks per pilot)
bas = np.array([worstO(baseline_T(T)) for T in Ts])
pro = np.array([worstO(proposed_T(T)) for T in Ts])
# exhaustive 2D polar: NARROWBAND (1 look/pilot, center subcarrier); needs T>=4 to be identifiable
exh = np.array([worstO(exhaustive_polar_T(T), subc=[MC]) for T in Ts])

print("=== 3-way overhead vs worst-Omega range CRLB [mm] (exhaustive = narrowband) ===")
print(f"{'T':>3} | {'exh.polar(NB)':>13} | {'baseline BS':>12} | {'proposed':>10}")
for i, T in enumerate(Ts):
    e = exh[i,1]*1e3; es = f'{e:13.3f}' if np.isfinite(e) else f'{"inf(rank<4)":>13}'
    print(f"{T:>3} | {es} | {bas[i,1]*1e3:>12.3f} | {pro[i,1]*1e3:>10.3f}")

def slots(a, tgt=5.0):
    k = np.where(a[:,1]*1e3 <= tgt)[0]; return int(Ts[k[0]]) if len(k) else None
print(f"\nNOTE: exhaustive polar also needs O(N_theta*S) pilots to SWEEP the full space "
      f"with no coarse prior; N_theta*S ~ {Nt}*S (hundreds-thousands).")
print(f"pilots to reach 5 mm (given the region):  exhaustive(NB)={slots(exh)}  baseline={slots(bas)}  proposed={slots(pro)}")

print("\nangle CRLB [deg] (angle is fine narrowband; only RANGE needs bandwidth):")
for i, T in enumerate(Ts):
    e = np.degrees(exh[i,0])
    print(f"  T={T:>2}  exh(NB)={e:.4f}" if np.isfinite(e) else f"  T={T:>2}  exh(NB)=inf", end='')
    print(f"  baseline={np.degrees(bas[i,0]):.4f}  proposed={np.degrees(pro[i,0]):.4f}")

def cleanplot(ax, x, y, mask=None, **kw):
    m = np.isfinite(y) if mask is None else (np.isfinite(y) & mask)
    ax.loglog(x[m], y[m], **kw)
Tsx = Ts.astype(float)
exh_ok = (exh[:,1]*1e3) < 1e4   # drop rank-deficient / absurd (>10 m) exhaustive points
fig, ax = plt.subplots(1, 2, figsize=(11.5, 4.3))
cleanplot(ax[0], Tsx, exh[:,1]*1e3, mask=exh_ok, marker='^', ls=':', label='exhaustive 2D polar (narrowband)')
cleanplot(ax[0], Tsx, bas[:,1]*1e3, marker='o', ls='--', label='baseline beam split (wideband)')
cleanplot(ax[0], Tsx, pro[:,1]*1e3, marker='s', ls='-', label='proposed (CRLB-optimal)')
ax[0].axhline(5, color='r', ls='-.', lw=1, label='5 mm target')
ax[0].set(xlabel='refinement pilots T', ylabel='worst-$\\Omega$ $\\sqrt{CRLB}_r$ [mm]',
          title='RANGE CRLB vs pilots (bandwidth matters)'); ax[0].grid(alpha=.3, which='both'); ax[0].legend(fontsize=8)
cleanplot(ax[1], Tsx, np.degrees(exh[:,0]), mask=exh_ok, marker='^', ls=':', label='exhaustive 2D polar (NB)')
cleanplot(ax[1], Tsx, np.degrees(bas[:,0]), marker='o', ls='--', label='baseline beam split')
cleanplot(ax[1], Tsx, np.degrees(pro[:,0]), marker='s', ls='-', label='proposed')
ax[1].set(xlabel='refinement pilots T', ylabel='worst-$\\Omega$ $\\sqrt{CRLB}_\\theta$ [deg]',
          title='ANGLE CRLB vs pilots'); ax[1].grid(alpha=.3, which='both'); ax[1].legend(fontsize=8)
fig.suptitle('Option B — exhaustive 2D polar (narrowband) vs beam-split baseline vs proposed')
fig.tight_layout()
outp = os.path.join(os.path.dirname(os.path.abspath(__file__)), "crlb_baselines.png")
fig.savefig(outp, dpi=130); print("saved ->", outp)
