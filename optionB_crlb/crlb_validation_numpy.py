#!/usr/bin/env python3
"""
Option B CRLB validation (NumPy) v2 — vectorized + OFF-GRID ML refinement.
Fixes the degenerate 'RMSE=0' harness: coarse grid gives the basin, then a
continuous Nelder-Mead refine on the concentrated (beta-profiled) likelihood
lets the estimate track the sub-mm / sub-mrad CRLB.
"""
import os
import numpy as np
from scipy.optimize import minimize
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt

c = 3e8
Nt, fc, B, M, k0 = 128, 10e9, 2e9, 512, 2
d = (c/fc)/2
theta1, theta2, alpha1, alpha2 = -31, 15, -0.454, 0.5
u_theta, u_r, u_beta = np.arcsin(0.2), 20.0, 1.0
nn = np.arange(-(Nt-1)/2, (Nt-1)/2 + 1)
f = fc + B/M*(np.arange(1, M+1)-1-(M-1)/2)          # M

def delay_polar_2d():
    k = 2*np.pi*f/c; kc = 2*np.pi*fc/c; nc = nn.reshape(-1, 1)
    w = np.zeros((Nt, k0, M), dtype=complex); t1 = theta1
    for s in range(k0):
        w[:, s, :] = 1/np.sqrt(Nt)*np.exp(
            -1j*k[None, :]*(nc*d*t1 - nc**2*d**2*alpha1)
            -1j*kc*(nc*d*theta2 - nc**2*d**2*alpha2))
        t1 = t1 - 2/k0
    return w
W = delay_polar_2d()
Wsm = [W[:, s, :] for s in range(k0)]               # each Nt x M

def template(theta, r):
    """Vectorized noiseless observation vector u (length k0*M), col-major."""
    rn = np.sqrt(r**2 + (nn*d)**2 - 2*r*nn*d*np.sin(theta))      # Nt
    H = np.exp(-1j*2*np.pi/c*np.outer(f, rn))/np.sqrt(Nt)        # M x Nt
    u = np.empty((k0, M), dtype=complex)
    for s in range(k0):
        u[s] = np.einsum('mn,nm->m', H, Wsm[s])
    return u.ravel(order='F')

def compute_crlb(snr_dB):
    dTheta, dR = 1e-6, 1e-4
    u0 = template(u_theta, u_r)
    dTh = (template(u_theta+dTheta, u_r) - template(u_theta-dTheta, u_r))/(2*dTheta)
    dRr = (template(u_theta, u_r+dR)     - template(u_theta, u_r-dR))/(2*dR)
    mu0 = u_beta*u0; dThv = u_beta*dTh; dRrv = u_beta*dRr
    D = np.column_stack([dThv, dRrv, u0, 1j*u0])    # d mu / d[theta,r,ReB,ImB]
    sigma2 = np.mean(np.abs(mu0)**2)/10**(snr_dB/10)
    J = (2/sigma2)*np.real(D.conj().T @ D)
    C = np.linalg.inv(J)
    return C[0, 0], C[1, 1], mu0, sigma2, np.linalg.cond(J)

ct, cr, mu0, sig2, cond = compute_crlb(10)
print("===== CRLB report (SNR = 10 dB) =====")
print(f"User: sin(theta)={np.sin(u_theta):.3f} ({np.degrees(u_theta):.2f} deg), r={u_r} m")
print(f"FIM cond = {cond:.2e} | CRLB angle std = {np.degrees(np.sqrt(ct)):.4e} deg | "
      f"CRLB range std = {np.sqrt(cr)*1e3:.4e} mm")

# ---------- Monte-Carlo with off-grid ML refinement ----------
snr_dB = np.arange(0, 26, 5); nTr = 100
# coarse grid (basin finder)
gt = np.arcsin(np.linspace(np.sin(u_theta)-0.05, np.sin(u_theta)+0.05, 41))
gr = np.linspace(u_r-4, u_r+4, 41)
TH, RR = np.meshgrid(gt, gr, indexing='ij')
gth, grr = TH.ravel(), RR.ravel()
Ug = np.array([template(gth[i], grr[i]) for i in range(gth.size)])   # Ngrid x L
Ugn = np.sum(np.abs(Ug)**2, axis=1)
sT, sR = 1e-4, 1e-3                                    # optimizer scaling

def neg_ll(p, y):
    u = template(u_theta+p[0]*sT, u_r+p[1]*sR)
    return -np.abs(np.vdot(u, y))**2/np.real(np.vdot(u, u))

rng = np.random.default_rng(0)
rmse_t = np.zeros(len(snr_dB)); crlb_t = np.zeros(len(snr_dB))
rmse_r = np.zeros(len(snr_dB)); crlb_r = np.zeros(len(snr_dB))
for i, s_dB in enumerate(snr_dB):
    ct, cr, mu0, sig2, _ = compute_crlb(s_dB)
    crlb_t[i], crlb_r[i] = np.sqrt(ct), np.sqrt(cr)
    L = mu0.size; eT = np.zeros(nTr); eR = np.zeros(nTr)
    for t in range(nTr):
        y = mu0 + np.sqrt(sig2/2)*(rng.standard_normal(L)+1j*rng.standard_normal(L))
        gB = np.argmax(np.abs(Ug @ y.conj())**2/Ugn)   # coarse basin
        p0 = [(gth[gB]-u_theta)/sT, (grr[gB]-u_r)/sR]
        res = minimize(neg_ll, p0, args=(y,), method='Nelder-Mead',
                       options=dict(xatol=5e-3, fatol=1e-11, maxiter=250))
        eT[t] = res.x[0]*sT; eR[t] = res.x[1]*sR
    rmse_t[i] = np.sqrt(np.mean(eT**2)); rmse_r[i] = np.sqrt(np.mean(eR**2))
    print(flush=True) if False else None; print(f"SNR {s_dB:3d} dB | RMSE th {np.degrees(rmse_t[i]):.3e} deg "
          f"(CRLB {np.degrees(crlb_t[i]):.3e}) | RMSE r {rmse_r[i]*1e3:.3e} mm "
          f"(CRLB {crlb_r[i]*1e3:.3e})", flush=True)

fig, ax = plt.subplots(1, 2, figsize=(11, 4.2))
ax[0].semilogy(snr_dB, np.degrees(rmse_t), 'o-', label='ML RMSE')
ax[0].semilogy(snr_dB, np.degrees(crlb_t), 'k--', label='sqrt(CRLB)')
ax[0].set(xlabel='SNR [dB]', ylabel='angle RMSE / CRLB [deg]', title='Angle estimation')
ax[1].semilogy(snr_dB, np.array(rmse_r)*1e3, 'o-', label='ML RMSE')
ax[1].semilogy(snr_dB, np.array(crlb_r)*1e3, 'k--', label='sqrt(CRLB)')
ax[1].set(xlabel='SNR [dB]', ylabel='range RMSE / CRLB [mm]', title='Range estimation')
for a in ax: a.grid(True, which='both', alpha=.3); a.legend()
fig.suptitle('Option B — CRLB validation for distance-dependent beam-split training codebook '
             '(off-grid ML, NumPy)')
fig.tight_layout()
outp=os.path.join(os.path.dirname(os.path.abspath(__file__)), "crlb_validation.png")
fig.savefig(outp, dpi=130); print("saved ->", outp)
