#!/usr/bin/env python3
"""
Semi-closed-form near-field angle/range FIM for the distance-dependent
beam-split TRAINING codebook (Option B, Section III), plus a numerical check
against the exact finite-difference FIM.

Key identity (Fresnel / polar expansion, r_n ≈ r − n d sinθ + n²d² cos²θ/(2r)):
the derivative of every observation μ_{s,m}=β Σ_n h_m(n) w_{s,m}(n) w.r.t. the
sensing parameters is a closed-form function of just THREE per-beam antenna
moments
    G0_{s,m}=Σ_n g_{s,m}(n),  G1_{s,m}=Σ_n n g_{s,m}(n),  G2_{s,m}=Σ_n n² g_{s,m}(n),
with g_{s,m}(n)=h_m(n) w_{s,m}(n).  Then
    ∂μ/∂θ = j β k_m [ d cosθ · G1 + (d² cosθ sinθ / r) · G2 ]
    ∂μ/∂r = −j β k_m [ G0 − (d² cos²θ /(2r²)) · G2 ]
    ∂μ/∂Reβ = G0 ,   ∂μ/∂Imβ = j G0 ,
and  J = (2/σ²) Σ_{s,m} Re{ d_a* d_b }  (4×4 over [θ,r,Reβ,Imβ]).
No finite differences, no 2-D grid — this is the objective used for codebook
optimisation in Section V.
"""
import numpy as np

c = 3e8
Nt, fc, B, M, k0 = 128, 10e9, 2e9, 512, 2
d = (c/fc)/2
nn = np.arange(-(Nt-1)/2, (Nt-1)/2 + 1)
fm = fc + B/M*(np.arange(1, M+1)-1-(M-1)/2)
km = 2*np.pi*fm/c
kc = 2*np.pi*fc/c

def codebook(theta1=-31., theta2=15., alpha1=-0.454, alpha2=0.5):
    nc = nn.reshape(-1, 1); w = np.zeros((Nt, k0, M), dtype=complex); t1 = theta1
    for s in range(k0):
        w[:, s, :] = 1/np.sqrt(Nt)*np.exp(-1j*km[None, :]*(nc*d*t1 - nc**2*d**2*alpha1)
                                          -1j*kc*(nc*d*theta2 - nc**2*d**2*alpha2))
        t1 = t1 - 2/k0
    return w

def codebook_free(P):
    """Per-pilot codebook: P has shape (k0,4) rows (theta1_s, alpha1_s, theta2_s,
    alpha2_s) — each of the k0 training codewords designed independently (no
    forced sweep coupling). This is the Stage-2 design variable of Section V."""
    nc = nn.reshape(-1, 1); w = np.zeros((Nt, k0, M), dtype=complex)
    for s in range(k0):
        t1, a1, t2, a2 = P[s]
        w[:, s, :] = 1/np.sqrt(Nt)*np.exp(-1j*km[None, :]*(nc*d*t1 - nc**2*d**2*a1)
                                          -1j*kc*(nc*d*t2 - nc**2*d**2*a2))
    return w

BASE_FREE = np.array([[-31., -0.454, 15., 0.5],      # baseline expanded to per-pilot
                      [-32., -0.454, 15., 0.5]])      # (pilot 1: theta1 -= 2/k0)

def channel(theta, r):
    """Exact spherical-wave channel rows h_m(n), shape (M, Nt) — matches baseline."""
    rn = np.sqrt(r**2 + (nn*d)**2 - 2*r*nn*d*np.sin(theta))     # Nt
    return np.exp(-1j*np.outer(km, rn))/np.sqrt(Nt)            # M x Nt

# ---------- (A) semi-closed-form FIM via moments ----------
def fim_closed(W, theta, r, beta, snr_dB, sigma2=None):
    # sigma2=None  -> noise renormalised to this codebook's mean received power
    #                 (SNR-referenced; use for the CRLB-vs-SNR validation plots);
    # sigma2 given -> FIXED absolute noise (use for codebook DESIGN, so that a
    #                 codebook focusing more energy on the user lowers the CRLB).
    H = channel(theta, r)                                      # M x Nt
    G0 = np.empty((k0, M), complex); G1 = np.empty((k0, M), complex); G2 = np.empty((k0, M), complex)
    for s in range(k0):
        g = H * W[:, s, :].T                                  # M x Nt  (h_m(n) w_{s,m}(n))
        G0[s] = g.sum(1); G1[s] = (g*nn).sum(1); G2[s] = (g*nn**2).sum(1)
    st, ct = np.sin(theta), np.cos(theta)
    dth = 1j*beta*km[None, :]*(d*ct*G1 + (d**2*ct*st/r)*G2)    # ∂μ/∂θ
    dr  = -1j*beta*km[None, :]*(G0 - (d**2*ct**2/(2*r**2))*G2) # ∂μ/∂r
    dRe = G0.copy(); dIm = 1j*G0                                # ∂μ/∂Reβ, ∂μ/∂Imβ
    mu0 = beta*G0
    if sigma2 is None:
        sigma2 = np.mean(np.abs(mu0)**2)/10**(snr_dB/10)
    D = np.column_stack([dth.ravel(), dr.ravel(), dRe.ravel(), dIm.ravel()])
    J = (2/sigma2)*np.real(D.conj().T @ D)
    C = np.linalg.inv(J)
    return C[0, 0], C[1, 1], J

# ---------- (B) exact finite-difference FIM (θ,r) for validation ----------
def fim_exact_fd(W, theta, r, beta, snr_dB):
    def mu(th, rr):
        H = channel(th, rr); out = np.empty((k0, M), complex)
        for s in range(k0): out[s] = (H * W[:, s, :].T).sum(1)
        return beta*out
    dTheta, dR = 1e-6, 1e-4
    mu0 = mu(theta, r)
    dth = (mu(theta+dTheta, r) - mu(theta-dTheta, r))/(2*dTheta)
    dr  = (mu(theta, r+dR)     - mu(theta, r-dR))/(2*dR)
    base = mu0/beta
    sigma2 = np.mean(np.abs(mu0)**2)/10**(snr_dB/10)
    D = np.column_stack([dth.ravel(), dr.ravel(), base.ravel(), (1j*base).ravel()])
    J = (2/sigma2)*np.real(D.conj().T @ D)
    C = np.linalg.inv(J)
    return C[0, 0], C[1, 1], J

if __name__ == "__main__":
    W = codebook()
    print("=== Section III validation: semi-closed-form vs exact finite-difference FIM ===")
    print(f"{'(θ[deg], r[m])':>16} | {'√CRLB_θ closed':>15} {'exact':>11} {'rel.err':>9} | "
          f"{'√CRLB_r closed':>15} {'exact':>11} {'rel.err':>9}")
    for th_deg, r in [(11.54, 20), (0.0, 15), (30.0, 25), (-20.0, 10), (5.0, 40)]:
        th = np.radians(th_deg)
        ct_, cr_, _ = fim_closed(W, th, r, 1.0, 10)
        cte, cre, _ = fim_exact_fd(W, th, r, 1.0, 10)
        et = abs(np.sqrt(ct_)-np.sqrt(cte))/np.sqrt(cte)
        er = abs(np.sqrt(cr_)-np.sqrt(cre))/np.sqrt(cre)
        print(f"({th_deg:6.2f},{r:5.1f}) | {np.degrees(np.sqrt(ct_)):15.4e} "
              f"{np.degrees(np.sqrt(cte)):11.4e} {et:9.2%} | "
              f"{np.sqrt(cr_)*1e3:12.4e}mm {np.sqrt(cre)*1e3:8.4e}mm {er:9.2%}")
