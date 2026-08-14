# Cramér–Rao-Bound-Optimal Beam-Split Training Codebook for Near-Field XL-MIMO: Active Experiment Design for Joint Beam Alignment and User Localization

> **初稿 (v0.1, 2026-08-12).** 目标期刊：IEEE TWC / TCOM。记号与代码 (`baseline_distance_dependent/…`, `optionB_crlb/…`) 严格对齐；所有仿真数字来自本仓库脚本。英文正文便于直接转 IEEEtran；数学用 LaTeX 记号。

---

## Abstract

Extremely large-scale MIMO (XL-MIMO) at high carrier frequencies pushes users into the *near field*, where beam training must resolve **both** angle and distance, and wide bandwidth makes the array response frequency-dependent (beam split). Distance-dependent beam-split training codebooks exploit this beam split to cover the angle–distance plane with very few pilots, and because each training scan already produces an angle–distance estimate, the training phase is *intrinsically a localization*. Yet existing designs treat the codebook as a fixed sweeping pattern and never characterize, let alone optimize, the *estimation-theoretic* quality of the training waveform. This paper closes that gap. **First**, we derive a semi-closed-form Cramér–Rao bound (CRB) for joint angle/distance estimation from a distance-dependent beam-split *training* waveform, expressed through three per-beam antenna moments and validated against the exact spherical-wave model to within 0.2%. **Second**, casting initial access as *active experiment design*, we optimize the training codebook to minimize the worst-case CRB over a coarse-stage uncertainty region subject to a communication array-gain constraint, solved by a penalty + block-coordinate-descent (BCD) algorithm that decouples the true-time-delay (TTD) and phase-shifter (PS) blocks; sweeping the trade-off weight yields the communication–sensing Pareto frontier. **Third**, exploiting the additivity of Fisher information over training slots, we establish a **training-overhead ↔ localization-CRB scaling law** and the minimum overhead to reach a target accuracy. Simulations show the CRB-optimal codebook lowers the worst-case angle/distance CRB by about **4×** over the space-covering baseline while *raising* the communication gain, and reaches a 5 mm ranging target with **75% fewer** training slots. We further show that our design is *orthogonal* to recent near-field wideband ISAC CRB-optimization works, which design **data-phase precoders for a known target**, whereas we design the **training codebook for an unknown user during initial access**.

**Index Terms**—Near-field, XL-MIMO, beam training, beam split, true-time-delay, Cramér–Rao bound, integrated sensing and communication, active experiment design.

---

## I. Introduction

### A. Background and Motivation
Extremely large-scale antenna arrays combined with mmWave/THz bandwidths are a cornerstone of 6G. Two physical effects fundamentally reshape beam management. (i) The **near-field** effect: when the user lies within the Rayleigh distance, the wavefront is spherical, so the array steering vector depends on **both** the angle $\theta$ and the distance $r$; beam training must therefore search a two-dimensional angle–distance space, and the overhead of exhaustive polar-domain search is prohibitive. (ii) The **beam-split** effect: over a wide band, a phase-shifter-only beamformer points different subcarriers to different locations. True-time-delay (TTD)–aided architectures turn this bug into a feature—*distance-dependent beam split* [Zheng] steers different subcarriers to different (angle, distance) pairs, so a single wideband pilot sweeps a whole locus of the angle–distance plane, giving the lowest-overhead near-field training known to date.

A key but under-exploited observation is that **near-field beam training is localization**: each scan returns an $(\hat\theta,\hat r)$. This makes the training phase a natural, "for-free" integrated sensing and communication (ISAC) opportunity. However, the literature designs distance-dependent beam-split codebooks as fixed sweeping patterns chosen for *coverage*, and evaluates them by beamforming gain or achievable rate—**never** by an estimation-theoretic bound. Consequently three questions are open: *(Q1) What is the fundamental angle/distance accuracy limit (CRB) of such a training waveform? (Q2) How should the codebook be designed to approach that limit, and what is the communication–sensing trade-off? (Q3) How does localization accuracy scale with training overhead, and what is the minimum overhead for a target accuracy?* This paper answers Q1–Q3.

### B. Related Work and the Precise Gap
**Near-field beam training.** Polar-domain hierarchical search [Lu&Dai], fast two-stage DFT search [Fast], DFT-codebook angle–range estimation [Wu&You], sparse-DFT [SparseDFT], near-field rainbow [Cui&Dai], and distance-dependent beam split [Zheng] progressively reduce overhead. A recent wavenumber-domain design (*Pattern Zooming*) attains few-pilot localization via a closed-form geometric estimator. **All of these provide a codebook and/or estimator but no CRB, no bound-optimal codebook design, and no communication–sensing trade-off.**

**Near-field CRB and ISAC.** Near-field sensing CRBs have been derived for XL-MIMO [Wang-Xiao-Zeng]; CRB-optimal *transmit beamforming* for joint radar-communication was pioneered in the far field [F. Liu], and recently extended to **near-field wideband ISAC with delay-phase precoding** [Zhang-Wei, WCL'25], which derives closed-form angle/distance CRB and minimizes it subject to a communication-rate constraint via penalty + BCD. **These works design a data-phase precoder for a target whose location is (assumed) known; the sensed target and the served communication user are distinct entities.** They contain no notion of a training codebook, pilot overhead, or initial access.

**The gap this paper fills.** No prior work (a) derives the CRB of a distance-dependent beam-split *training* waveform, (b) designs the *training codebook* to minimize that bound under location uncertainty, or (c) characterizes the *training-overhead–accuracy* scaling. Crucially, our problem is **active experiment design during initial access**: the user location is *unknown* and is exactly what the training must estimate—fundamentally different from designing a precoder for a known target.

### C. Contributions
1. **Semi-closed-form training CRB (Sec. III).** We derive the Fisher information matrix (FIM) for joint $(\theta,r)$ estimation from a distance-dependent beam-split training waveform. Exploiting the linearity of the near-field phase in $(\vartheta,\alpha)=(\sin\theta,\cos^2\theta/2r)$, the score reduces to three per-beam antenna moments $\{G^{(0)},G^{(1)},G^{(2)}\}$, yielding closed-form CRB expressions in the codebook parameters. The bound matches the exact spherical-wave FIM within 0.02–0.18%.
2. **CRB-optimal codebook via active experiment design (Sec. IV).** We formulate stage-2 training as minimizing the worst-case CRB over a coarse-stage uncertainty region $\Omega$, subject to a communication array-gain floor, and solve it with a penalty + BCD algorithm that decouples the TTD ("delay") and PS ("phase") blocks. Sweeping the trade-off weight traces the **communication–sensing Pareto frontier**.
3. **Training-overhead ↔ localization-CRB scaling law (Sec. V).** Using the additivity of Fisher information over slots, $\mathbf J(T)=\sum_{s=1}^{T}\mathbf J_s$, we show $\sqrt{\mathrm{CRB}}\!\propto\!T^{-1/2}$ for informative looks and give the minimum overhead $T^\star(\varepsilon)$ to reach accuracy $\varepsilon$; the CRB-optimal codebook further concentrates and is provably steeper.
4. **Benchmarking and a clean novelty boundary (Sec. VI).** Numerically, existing training+localization schemes sit away from the CRB, whereas the proposed codebook approaches it; the optimal design lowers worst-case angle/distance CRB by ~4× while raising communication gain, and saves ~75% training overhead at a fixed ranging accuracy. We make explicit that this is a *training-codebook / initial-access* contribution, orthogonal to *data-phase ISAC precoders*.

*Notation.* Bold lower/upper case denote vectors/matrices; $(\cdot)^{\!*},(\cdot)^{\!\top},(\cdot)^{\!H}$ are conjugate, transpose, Hermitian; $\Re\{\cdot\},\Im\{\cdot\}$ real/imag parts; $\mathcal{CN}(0,\sigma^2)$ circularly symmetric complex Gaussian.

---

## II. System Model

### A. Array and Wideband Waveform
A base station (BS) with an $N_t$-element uniform linear array (ULA), element spacing $d=\lambda_c/2$, serves a single-antenna user in the near field. Antenna indices are $n\in\{-\tfrac{N_t-1}{2},\dots,\tfrac{N_t-1}{2}\}$. The system uses OFDM with $M$ subcarriers; the $m$-th subcarrier frequency and wavenumber are
$$
f_m=f_c+\tfrac{B}{M}\!\Big(m-1-\tfrac{M-1}{2}\Big),\qquad k_m=\tfrac{2\pi f_m}{c},\quad m=1,\dots,M,
$$
with carrier $f_c$, bandwidth $B$. (Running example: $N_t{=}128$, $f_c{=}10$ GHz, $B{=}2$ GHz, $M{=}512$.)

### B. Near-Field Channel (exact and polar approximation)
For a user at $(\theta,r)$ (angle from broadside, range to array center), the exact spherical-wave array response on subcarrier $m$ is
$$
[\mathbf a(f_m;\theta,r)]_n=\tfrac{1}{\sqrt{N_t}}\,e^{-j k_m (r_n-r)},\qquad r_n=\sqrt{r^2+(nd)^2-2rnd\sin\theta},
$$
and the propagation channel row used throughout is $\mathbf h_m=\beta\,[\,e^{-j k_m r_n}/\sqrt{N_t}\,]_n$ up to the complex path gain $\beta$ (absorbing $e^{-j2\pi f_m r/c}$). The second-order (Fresnel) expansion
$$
r_n-r\approx -nd\sin\theta+\tfrac{(nd)^2\cos^2\theta}{2r}\;\Longrightarrow\;
\boxed{\ \vartheta\triangleq\sin\theta,\quad \alpha\triangleq\tfrac{\cos^2\theta}{2r}\ }
$$
makes the phase **linear** in $(\vartheta,\alpha)$—the key property enabling the closed-form CRB of Sec. III. The range is recovered by $r=\cos^2\theta/(2\alpha)=(1-\vartheta^2)/(2\alpha)$.

### C. Dual-Function (Distance-Dependent Beam-Split) Training Codebook
The stage-2 training codebook consists of $P$ codewords ($P$ pilot slots). Codeword $s$ uses a TTD term (frequency-dependent) plus a PS term (frequency-flat):
$$
[\mathbf w_{s,m}(\boldsymbol\phi_s)]_n=\tfrac{1}{\sqrt{N_t}}\exp\!\Big(-jk_m\underbrace{(nd\,\theta_1^{(s)}-n^2d^2\alpha_1^{(s)})}_{\text{TTD (per subcarrier)}}-jk_c\underbrace{(nd\,\theta_2^{(s)}-n^2d^2\alpha_2^{(s)})}_{\text{PS (fixed at }f_c)}\Big),
$$
with **design variables** $\boldsymbol\phi_s=(\theta_1^{(s)},\alpha_1^{(s)},\theta_2^{(s)},\alpha_2^{(s)})$. The TTD block sets the beam-split trajectory; the PS block sets the base focus. The per-subcarrier effective focus is $\vartheta_{\mathrm{eff}}(m)=\theta_1+\tfrac{f_c}{f_m}\theta_2$, $\alpha_{\mathrm{eff}}(m)=\alpha_1+\tfrac{f_c}{f_m}\alpha_2$: different subcarriers focus at different $(\theta,r)$, so one pilot scans a locus of the angle–distance plane. (This is exactly `delay_polar_2d.m`.)

### D. Observation Model and Metrics
During pilot $s$, subcarrier $m$, the user receives
$$
y_{s,m}=\beta\,\mathbf h_m^{\!\top}\mathbf w_{s,m}(\boldsymbol\phi_s)+n_{s,m},\quad n_{s,m}\sim\mathcal{CN}(0,\sigma^2),
$$
i.e. mean $\mu_{s,m}(\boldsymbol\eta)=\beta\sum_n [\mathbf h_m]_n[\mathbf w_{s,m}]_n$ with unknowns $\boldsymbol\eta=[\theta,r,\Re\beta,\Im\beta]^\top$.
- **Communication metric:** best-beam array gain $G(\theta,r;\{\boldsymbol\phi_s\})=\max_{s,m}|\mathbf h_m^{\!\top}\mathbf w_{s,m}|^2$ (unit-norm $\mathbf h_m,\mathbf w_{s,m}$, so $G\in[0,1]$).
- **Sensing metric:** the CRB of estimating $(\theta,r)$ from $\{y_{s,m}\}$ (Sec. III).

### E. Two-Stage Active Beam Training
Stage 1 (coarse) uses a low-overhead beam-split scan to localize the user to an **uncertainty region** $\Omega=\{\theta\in[\hat\theta\pm\Delta_\theta],\,r\in[\hat r\pm\Delta_r]\}$. Stage 2 (this paper) designs $\{\boldsymbol\phi_s\}$ **knowing only $\Omega$** to minimize the worst-case CRB over $\Omega$ while preserving communication gain—an *optimal experiment design* problem, since the user location is unknown and is precisely the quantity to be estimated.

---

## III. Semi-Closed-Form Cramér–Rao Bound *(drafted — validated in code)*

Under the Gaussian model, the FIM is $[\mathbf J]_{ab}=\tfrac{2}{\sigma^2}\sum_{s,m}\Re\{\partial_a\mu_{s,m}^{*}\,\partial_b\mu_{s,m}\}$. Define the three per-beam antenna moments of $g_{s,m}(n)\triangleq[\mathbf h_m]_n[\mathbf w_{s,m}]_n$:
$$
G^{(0)}_{s,m}=\sum_n g_{s,m}(n),\quad G^{(1)}_{s,m}=\sum_n n\,g_{s,m}(n),\quad G^{(2)}_{s,m}=\sum_n n^2 g_{s,m}(n).
$$
Using the Fresnel expansion (phase linear in $\vartheta,\alpha$), the scores are closed-form:
$$
\partial_\theta\mu_{s,m}=j\beta k_m\!\Big[d\cos\theta\,G^{(1)}_{s,m}+\tfrac{d^2\cos\theta\sin\theta}{r}G^{(2)}_{s,m}\Big],\;\;
\partial_r\mu_{s,m}=-j\beta k_m\!\Big[G^{(0)}_{s,m}-\tfrac{d^2\cos^2\theta}{2r^2}G^{(2)}_{s,m}\Big],
$$
$\partial_{\Re\beta}\mu=G^{(0)},\ \partial_{\Im\beta}\mu=jG^{(0)}$. Assembling the $4\times4$ FIM and inverting gives $\mathrm{CRB}(\theta)=[\mathbf J^{-1}]_{11}$, $\mathrm{CRB}(r)=[\mathbf J^{-1}]_{22}$. **Physical reading:** $G^{(1)}$ (weight $\propto k_m n$) carries angle; $G^{(2)}$ (weight $\propto k_m n^2$) carries near-field curvature (range); the cross-subcarrier $k_m$-dependence of $G^{(0)}$ carries time-of-flight ranging—explaining sub-mm range bounds at $B{=}2$ GHz. **Validation:** against the exact spherical-wave finite-difference FIM at five $(\theta,r)$ points ($\theta\in[-20^\circ,30^\circ]$, $r\in[10,40]$ m), the semi-closed $\sqrt{\mathrm{CRB}}$ matches to **0.02–0.18%** (`crlb_closed_form.py`). This makes the closed form a fast, differentiable objective for Sec. IV.

---

## IV. CRB-Optimal Training Codebook Design *(drafted)*

**Problem.** Given $\Omega$, solve the min–max
$$
\min_{\{\boldsymbol\phi_s\}}\ \max_{(\theta,r)\in\Omega}\Big[\tfrac{\mathrm{CRB}_\theta}{\sigma_{\theta_0}^2}+\tfrac{\mathrm{CRB}_r}{\sigma_{r_0}^2}\Big]
\quad\text{s.t.}\quad \min_{(\theta,r)\in\Omega}G(\theta,r;\{\boldsymbol\phi_s\})\ge\gamma .
$$
Because Fisher information scales with the training energy delivered to the user, concentrating the beam-split sweep onto $\Omega$ lowers the CRB; covering all of $\Omega$ (worst case) enforces diversity of looks.

**Algorithm (penalty + BCD).** We scalarize the trade-off, $\Phi(\{\boldsymbol\phi_s\};\mu)=\max_\Omega[\cdots]-\mu\min_\Omega G$, and minimize by **block coordinate descent** over the physically decoupled **TTD block** $\{(\theta_1,\alpha_1)_s\}$ and **PS block** $\{(\theta_2,\alpha_2)_s\}$ (each block by a low-dimensional local search). Sweeping $\mu$ (from sensing-optimal $\mu{=}0$ to gain-optimal) traces the communication–sensing Pareto frontier. *We deliberately adopt the same penalty+BCD machinery as the data-phase ISAC-precoder literature, to isolate the novelty in the **problem** (training codebook, unknown user, active experiment design) rather than the method.*

**Result (Sec. VI, Table II).** The optimized codebook dominates the space-covering baseline across the whole frontier: worst-case range/angle CRB fall by ~4× (6.34→1.46 mm; 0.0396°→0.0106°) while worst-case communication gain rises 0.64→0.94.

---

## V. Training Overhead ↔ Localization CRB Scaling *(drafted)*

Fisher information is **additive** over training slots, $\mathbf J(T)=\sum_{s=1}^{T}\mathbf J_s\succeq 0$, so each added beam-split codeword monotonically lowers the CRB. For $T$ informative looks over $\Omega$ the sensing information grows approximately linearly, giving the scaling law
$$
\sqrt{\mathrm{CRB}(\theta)},\ \sqrt{\mathrm{CRB}(r)}\ \propto\ T^{-1/2},
$$
and hence a minimum overhead $T^\star(\varepsilon)\!\approx\!\mathrm{CRB}_1/\varepsilon^2$ to reach accuracy $\varepsilon$. A CRB-optimal codebook additionally concentrates each slot ($\propto T$), so its exponent is steeper than $-1/2$. **Result (Sec. VI):** the measured exponents are $-0.53$ (baseline, confirming additivity) and $-0.83$ (optimal); to reach a 5 mm ranging target the baseline needs $T{=}4$ slots while the optimal codebook needs $T{=}1$—a **75% overhead saving** (equivalently ~3× accuracy at fixed overhead). This overhead–accuracy axis exists only for a *training* framework and is absent from precoder-based ISAC.

---

## VI. Simulation Results *(drafted — numbers from repo scripts)*

*Setup:* $N_t{=}128$, $f_c{=}10$ GHz, $B{=}2$ GHz, $M{=}512$, $d=\lambda_c/2$; $\Omega$ centered at $(\theta_0,r_0)=(11.54^\circ,20\,\text{m})$ with $\Delta_\theta{=}1^\circ,\Delta_r{=}2$ m; reference SNR 10 dB.

- **Fig. 1 (CRB validation, `crlb_validation`)**: Monte-Carlo ML RMSE tracks $\sqrt{\mathrm{CRB}}$ over 0–25 dB for both angle and range (efficient estimator; the bound is tight).
- **Table II / Fig. 2 (design + Pareto, `crlb_bcd_pareto`)**: baseline vs penalty+BCD frontier; ~4× CRB reduction with higher gain; the trade-off appears at the high-gain end.
- **Fig. 3 (overhead scaling, `crlb_overhead`)**: $\sqrt{\mathrm{CRB}}$ vs $T$ with $T^{-1/2}$ reference; 75% overhead saving at 5 mm.
- **Fig. 4 (two baselines, `crlb_baselines`)**: vs the classical **exhaustive 2-D polar search** (narrowband, one look per codeword, O($N_\theta S$) pilots). It is stuck at **metre-level** range (no time-of-flight; near-field ranging then rests only on weak wavefront curvature) — ~$10^3\times$ worse than wideband beam split — and worse in angle too (fewer total looks). This isolates the bandwidth advantage: a wideband beam-split pilot multiplexes $M$ subcarrier looks, so mm ranging is reached with $O(\text{few})$ pilots vs $O(N_\theta S)$ for exhaustive polar. Summary of the two baselines vs proposed:

| Method | Bandwidth | Range CRB √ (worst-$\Omega$) | Full-space overhead |
|---|---|---|---|
| Exhaustive 2-D polar search | narrowband | ~2.5 m (floor) | $O(N_\theta S)\!\approx\!10^2$–$10^3$ |
| Baseline beam split | wideband | 6.34 mm | $O(\text{few})$ |
| Proposed | wideband | 1.46 mm | $O(\text{few})$ |

**Table II (worst-$\Omega$, SNR ref 10 dB).**

| Design | $\sqrt{\mathrm{CRB}_r}$ | $\sqrt{\mathrm{CRB}_\theta}$ | comm. gain |
|---|---|---|---|
| Baseline (space-covering) | 6.34 mm | 0.0396° | 0.639 |
| Proposed, $\mu{=}0$ (sensing-opt.) | 1.58 mm | 0.0098° | 0.618 |
| Proposed, $\mu{=}0.5$ (knee) | **1.46 mm** | 0.0106° | **0.940** |
| Proposed, $\mu{=}8$ (gain-opt.) | 1.64 mm | 0.0112° | 0.954 |

---

## VII. Conclusion *(drafted)*
We established the estimation-theoretic limits of near-field wideband beam-split *training* waveforms and turned them into a design principle: a semi-closed-form CRB, a CRB-optimal training codebook obtained by active experiment design over the coarse-stage uncertainty region with a communication–sensing Pareto, and an overhead–accuracy scaling law. The design cuts worst-case localization CRB by ~4× and training overhead by ~75% while improving communication gain. The framework is orthogonal to data-phase ISAC precoders and re-frames low-overhead near-field beam training as optimal experiment design. Future work: extended/NLoS targets, hardware-limited (quantized/finite-range) TTD, and the multi-user codebook.

---

## References (real, to be formatted in IEEEtran)
- [Zheng] Y. Zheng *et al.*, "Near-Field Wideband Beam Training Based on Distance-Dependent Beam Split," *IEEE TWC*, 2024/25. arXiv:2406.07989.
- [Cui&Dai] M. Cui, L. Dai *et al.*, "Near-Field Rainbow: Wideband Beam Training for XL-MIMO," *IEEE TWC*, 2023. arXiv:2205.03543.
- [Lu&Dai] Y. Lu, L. Dai *et al.*, "Hierarchical Beam Training for XL-MIMO: From Far-Field to Near-Field," arXiv:2212.14705.
- [Fast] H. Zhang, X. Wu, C. You *et al.*, "Fast Near-Field Beam Training," *IEEE WCL*, 2022. arXiv:2209.14798.
- [Wu&You] X. Wu, C. You *et al.*, "Near-Field Beam Training: Joint Angle and Range Estimation with DFT Codebook," arXiv:2309.11872.
- [Wang-Xiao-Zeng] H. Wang, Z. Xiao, Y. Zeng, "Cramér-Rao Bounds for Near-Field Sensing with XL-MIMO," *IEEE TSP*, 2024. arXiv:2303.05736.
- [F. Liu] F. Liu *et al.*, "Cramér-Rao Bound Optimization for Joint Radar-Communication Beamforming," *IEEE TSP*, vol. 70, 2022.
- [Luo&Gao] H. Luo, F. Gao *et al.*, "Beam Squint Assisted User Localization in Near-Field ISAC," *IEEE TWC*, 2024. arXiv:2309.14012.
- [Zhang-Wei] Z. Zhang, Z. Wei, Z. Xu, H. Zeng, X. Zhu, "Cramér-Rao Bound Optimization for Near-Field Wideband ISAC: Delay-Phase Precoding for Beam Squint Mitigation," *IEEE WCL*, 14(11):3794–3798, 2025.
- [Pattern Zooming] Weng *et al.*, "Pattern Zooming: Near-Field Wideband Beam Training with Wavenumber-Domain Codebook," 2026. arXiv:2608.03615.
- [Survey] "Recent Advances in Near-Field Beam Training and Channel Estimation for XL-MIMO," 2025. arXiv:2504.05578.
