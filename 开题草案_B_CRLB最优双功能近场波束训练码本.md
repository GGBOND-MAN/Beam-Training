# 开题草案（方案 B，重塑版）：近场宽带 beam-split 训练波形的 CRLB 极限与感知最优码本设计

> 一句话定位：**为 distance-dependent beam split 训练波形建立角度/距离估计的 CRLB 理论极限，并反过来设计 CRLB 最优的 TTD/PS 码本；同一套低开销训练波形因此同时逼近感知极限（定位）与通信增益，给出通信-感知折中。**
>
> ⚠️ 卖点**不是**"能边训练边定位"（该点已被 Pattern Zooming / Pilot-Efficient / beam-squint MUSIC 占）——而是"给出该类波形的 **性能极限 + 最优设计 + 折中**"。竞品都只给估计器，没给界，也没做最优设计。
>
> 目标期刊：IEEE TWC / TCOM（主刊）。预期周期：2–3 个月出完整初稿。
> 本草案的记号与你 baseline 代码（`baseline_distance_dependent/code_nf_distance_dependent_rainbow`）严格对齐。

---

## 一、研究 gap 与新颖性防御（最重要，先看这个）

"近场宽带训练 + 少导频角距定位"这块 2026 年迅速变热，有几篇必须切割的竞品（✅=已逐字读原文核实，⚠️=未读到正文/描述待核实）：

| 竞品 | 做了什么 | 没做什么（= 你的空档） | 核实 |
|---|---|---|---|
| **Pattern Zooming**（arXiv:2608.03615, 2026, BUPT） | 宽带 + TD 波束扫描 + 波数域(DFT类)码本 + 角距**闭式几何估计器**；性能仅用 **RMSE** 实测 | 无 CRLB/统计下界、无码本最优设计、无通感折中（全文无 Cramér/CRB）；波数域码本（非极坐标/beam-split） | ✅ 2026-08-11 |
| **Luo & Gao (TWC 2024) / arXiv:2309.14012 + 2509.14850** | beam-squint + MUSIC 角距定位（**估计器**）；机制最近（也用 TTD 控 squint 让不同子载波指向不同角/距） | 无码本最优设计、无通感折中 | ⚠️ 待读（PDF 已入库） |
| **Pilot-Efficient**（Parvini 等, TU Dresden, **IEEE OJ-COMS 2026**, DOI 10.1109/OJCOMS.2026.3690933） | **窄带**；紧凑近场码本（用多用户干扰+空间相关降码本规模）+ 三阶段训练：子阵分层搜 AoD → **GILS 几何交叉最小二乘**融合定位 → 位置映射到码字 | 无 CRB/Fisher（全文 0 命中）、无 TTD/beam-split、无通感折中；码本目标是**降规模/抗干扰/省导频**，不是最小化估计界 | ✅ 2026-08-11 |

> ✅ **Pilot-Efficient 已核实（2026-08-11 读全文 17 页）**：它与 B 的表面重叠（标题含 "Codebook Design" + 用到定位）是假象——它是**窄带、面向多用户降开销/抗干扰**的码本 + GILS 定位当"选码字的手段"，**没有 CRLB、没有 beam-split、没有通感折中**。反而是 B 的好**动机/基线**："已有近场码本设计只优化规模/干扰/开销，无人刻画或优化感知 CRLB，也无人给通感折中"。

**共同空档（= B 的立足点）：没有一篇 (a) 推导该类波形的角/距 CRLB，(b) 按最小化 CRLB 去设计训练码本，(c) 给出通信-感知折中。**（Pattern Zooming 与 Pilot-Efficient 均已逐字核实确认不做这三点。）

**两篇"帮手"论文（非竞品，已读原文，用作方法论母版与优化工具）：**
- **Fan Liu et al., "Cramér-Rao Bound Optimization for Joint Radar-Communication Beamforming," TSP 2022** —— 把 CRB 当设计目标的**母版**：其问题 (19) = `min CRB  s.t. 每用户 SINR γ_k ≥ Γ_k + 发射功率预算`（单用户闭式解、多用户 SDR 全局最优）。B 直接抄这个骨架，把变量换成码本参数 (θ₁,α₁,θ₂,α₂)、把 SINR 约束换成通信阵列增益约束。它是**远场、窄带、纯波束成形**——正好把"近场 + 宽带 beam-split 训练码本"整块留给 B。
- **Xu Shi et al., "Spatial-Chirp Codebook-Based Hierarchical Beam Training," TWC 2023**（arXiv:2210.03345）—— 窄带纯训练、无 CRB、无定位；本文只用作**优化工具来源**（流形优化 + 交替最小化），可搬到 B 第五节的码本参数优化。

**三句话卖点**（写进 Introduction 的 contributions）：
1. **理论极限**：首次推导近场宽带 distance-dependent beam-split 训练波形下角度/距离估计的 CRLB，写成 TTD/PS 码本参数 (θ₁,α₁,θ₂,α₂) 的显式函数。
2. **最优设计**：以最小化 CRLB 为目标优化码本参数（感知最优码本），并加通信阵列增益约束 → **通信-感知 Pareto 折中**。
3. **对标**：证明现有训练+定位方案（Pattern Zooming / GILS / beam-squint MUSIC）离 CRLB 尚有差距，所提最优码本可逼近该界。

> 与 Pattern Zooming 的**硬切割**（审稿人必问）：它用波数域 DFT 码本 + "pattern zooming"效应 + 闭式**估计器**，目标是估位置；你用极坐标/distance-dependent beam-split 码本 + **CRLB 界** + **最优化设计** + **通感折中**，目标是刻画极限并最优设计波形。二者码本、贡献类型、目标都不同。

---

## 二、系统模型（与代码记号对齐）

**阵列与波形**（对应 `distance_dependent_beam_split.m`）：
- ULA，$N_t$ 根天线（如 128），天线序号 $n \in \{-(N_t-1)/2,\dots,(N_t-1)/2\}$，间距 $d=\lambda_c/2$。
- 载频 $f_c$（如 10 GHz），带宽 $B$（如 2 GHz），OFDM 子载波数 $M$（如 512）。
- 子载波频率 $f_m = f_c + \frac{B}{M}\left(m-1-\frac{M-1}{2}\right),\ m=1,\dots,M$，波数 $k_m = 2\pi f_m/c$。

**近场阵列流形**（对应 `near_field_manifold.m`，精确球面波）：
$$
\mathbf a(f_m;\theta,r)=\frac{1}{\sqrt{N_t}}\Big[e^{-j2\pi f_m (r_n-r)/c}\Big]_{n},\quad
r_n=\sqrt{r^2+(nd)^2-2rnd\sin\theta}.
$$
二阶泰勒近似给出代码里用的"极坐标"参数化：
$$
r_n-r \approx -nd\sin\theta+\frac{(nd)^2\cos^2\theta}{2r}
\;\Longrightarrow\;
\boxed{\ \vartheta\triangleq\sin\theta\in[-1,1],\quad \alpha\triangleq\frac{\cos^2\theta}{2r}\ }
$$
即代码里的 `theta`＝$\vartheta=\sin\theta$，`alpha`＝$\alpha$，距离由 $r=\cos^2\theta/(2\alpha)$ 反解。**关键性质：流形相位对 $(\vartheta,\alpha)$ 均为线性 → FIM 近似闭式。**

**双功能码本 / 波束成形器**（对应 `delay_polar_2d.m`），第 $s$ 组、第 $m$ 子载波：
$$
\mathbf w_{s,m}(\boldsymbol\phi_s)=\frac{1}{\sqrt{N_t}}\exp\!\Big(-jk_m\underbrace{(nd\,\theta_1^{(s)}-n^2d^2\alpha_1^{(s)})}_{\text{TTD（随频率）}}
-jk_c\underbrace{(nd\,\theta_2^{(s)}-n^2d^2\alpha_2^{(s)})}_{\text{移相器（随载频固定）}}\Big).
$$
**设计变量** $\boldsymbol\phi_s=(\theta_1^{(s)},\alpha_1^{(s)},\theta_2^{(s)},\alpha_2^{(s)})$，共 $P$ 个导频/组 $s=1,\dots,P$。TTD 部分决定 beam split 轨迹，移相器部分决定基准聚焦点。

**（可选，抬高层次）硬件约束**：TTD 时延范围/量化、移相器比特——若加上就与"硬件可实现"挂钩，但**不是主线**，主线是 CRLB 最优设计。

---

## 三、双功能观测模型

单用户位于 $(\theta_u,r_u)\leftrightarrow(\vartheta_u,\alpha_u)$。下行波束训练：第 $s$ 导频、第 $m$ 子载波，用户接收
$$
y_{s,m}=\sqrt{P_t}\,\beta\,\mathbf a^{H}(f_m;\vartheta_u,\alpha_u)\,\mathbf w_{s,m}(\boldsymbol\phi_s)\,x_{s,m}+n_{s,m},\quad n_{s,m}\sim\mathcal{CN}(0,\sigma^2),
$$
其中 $\beta$ 为复增益（含 $e^{-j2\pi f r_u/c}$ 与路径增益）。

- **通信侧指标**：最优波束的阵列增益 $G(\boldsymbol\phi)=\max_{s,m}|\mathbf a^H\mathbf w_{s,m}|^2$（对应你现有 `CDF_array_gain.m` / `Rate_*` 的量）。
- **感知侧指标**：从 $\{y_{s,m}\}$ 估计 $(\vartheta_u,\alpha_u)$ 的 CRLB（下节）。

---

## 四、Fisher 信息矩阵 / CRLB 推导框架

未知参数 $\boldsymbol\eta=[\vartheta_u,\ \alpha_u,\ \Re\beta,\ \Im\beta]^\top$。噪声均值
$\mu_{s,m}(\boldsymbol\eta)=\sqrt{P_t}\,\beta\,\mathbf a^{H}(f_m;\vartheta_u,\alpha_u)\mathbf w_{s,m}$。高斯观测下 FIM：
$$
[\mathbf J]_{ab}=\frac{2}{\sigma^2}\sum_{s=1}^{P}\sum_{m=1}^{M}\Re\!\left\{\frac{\partial \mu_{s,m}^*}{\partial \eta_a}\frac{\partial \mu_{s,m}}{\partial \eta_b}\right\}.
$$
利用相位线性性，$a_n=\frac{1}{\sqrt{N_t}}e^{j\varphi_n}$，$\varphi_n=-k_m(nd\,\vartheta-n^2d^2\alpha)$（符号依代码约定）：
$$
\frac{\partial a_n}{\partial\vartheta}=a_n\cdot j(-k_m nd),\qquad
\frac{\partial a_n}{\partial\alpha}=a_n\cdot j(k_m n^2d^2).
$$
于是 $\partial\mu/\partial\vartheta,\ \partial\mu/\partial\alpha$ 都是**对天线序号加权求和**（权 $\propto k_m n$ 和 $k_m n^2$）的闭式表达。分块 FIM
$\mathbf J=\begin{bmatrix}\mathbf J_{\eta\eta}&\mathbf J_{\eta\beta}\\ \mathbf J_{\beta\eta}&\mathbf J_{\beta\beta}\end{bmatrix}$，
消去冗余参数 $\beta$ 得等效 $2\times2$ 信息矩阵
$\tilde{\mathbf J}=\mathbf J_{\eta\eta}-\mathbf J_{\eta\beta}\mathbf J_{\beta\beta}^{-1}\mathbf J_{\beta\eta}$，
$$
\mathrm{CRLB}(\vartheta_u)=[\tilde{\mathbf J}^{-1}]_{11},\quad
\mathrm{CRLB}(\alpha_u)=[\tilde{\mathbf J}^{-1}]_{22}.
$$
距离 CRLB 由 $r=\cos^2\theta/(2\alpha)$ 经 Jacobian 变换：$\mathrm{CRLB}(r)\approx\left(\frac{\partial r}{\partial\alpha}\right)^2\mathrm{CRLB}(\alpha)+\dots$

> **推导可对照的模板**（照抄结构、换成你的 $\mathbf w_{s,m}$ 即可）：
> - F. Liu et al., "CRB Optimization for Joint Radar-Communication Beamforming," TSP 2022（把 CRLB 当设计目标的范式）
> - H. Wang, Z. Xiao, Y. Zeng, "CRBs for Near-Field Sensing with XL-MIMO," TSP 2024（近场角/距 CRB 闭式）
> - Hua & Xu, "Near-Field 3D Localization via MIMO Radar: CRB and Estimator," arXiv:2305.10986

**注**：可先用极坐标近似相位得闭式 CRLB（好看、好写），再用**精确** $r_n$（`near_field_manifold.m`）数值验证——近距离下精确幅相更准（Hua/Xu 已指出），这个对照本身可作为一个小贡献点。

---

## 五、感知最优码本设计问题

在保证通信训练功能（阵列增益 / 覆盖）的前提下，优化码本参数把定位 CRLB 压到最小：
$$
\min_{\{\boldsymbol\phi_s\}_{s=1}^{P}}\ \ \max_{(\vartheta,\alpha)\in\mathcal R}\ \operatorname{tr}\big(\tilde{\mathbf J}^{-1}(\vartheta,\alpha;\{\boldsymbol\phi_s\})\big)
\quad\text{s.t.}\quad
\underbrace{G(\{\boldsymbol\phi_s\})\ge \gamma}_{\text{通信增益约束}},\ \
\underbrace{\text{覆盖整个 }\mathcal R}_{\text{训练功能}},\ \
P\le P_{\max}.
$$
- **通信-感知折中**：扫描约束门限 $\gamma$（或用权重 $\lambda\cdot\text{CRLB}+(1-\lambda)\cdot(-G)$），画出 **CRLB–阵列增益** Pareto 前沿——这是期刊里最出彩的一张图。
- **求解思路**（由易到难，先能出图）：
  1. **参数化搜索/网格**：$(\theta_1,\alpha_1,\theta_2,\alpha_2)$ 维度低，先粗网格 + 局部细化，直接出 baseline 对比与折中曲线。
  2. **梯度/流形优化**：CRLB 对 $\boldsymbol\phi$ 可微，用 fmincon / manopt 做局部最优。
  3. （可选）**交替优化**：训练覆盖约束与 CRLB 目标交替。

---

## 六、仿真实验清单（全部静态蒙特卡洛，跑得快）

对应你已有脚本，最小改动即可复用（`near_field_channel.m`、`delay_polar_2d.m`、`CDF_array_gain.m`、`Rate_*`）：

1. **CRLB 验证**：所提估计器的 RMSE vs SNR，叠加 CRLB 曲线（角度、距离各一张）。
2. **码本对比 / 对标竞品**：所提"感知最优码本" vs Zheng 原始 distance-dependent 码本、Pattern Zooming（波数域）、GILS（子阵三角化）、beam-squint MUSIC，在相同导频开销下的定位 RMSE，统一叠加 CRLB 曲线（凸显各方案离界的差距 → 这是重塑后 B 的招牌图）。
3. **通信-感知折中**：CRLB–阵列增益 Pareto 前沿（不同 $\gamma$ 或 $\lambda$）。
4. **开销对比**：定位精度 vs 导频数 $P$；对标穷举/二维扫描的开销。
5. **鲁棒性**：距离、角度扫描范围、$N_t$、$B$ 对 CRLB 的影响；近距离下极坐标近似 vs 精确流形的偏差。
6. （可选）硬件非理想：TTD 量化/范围对 CRLB 的退化。

---

## 七、里程碑与时间线（目标 2–3 个月初稿）

| 周 | 任务 |
|---|---|
| 1–2 | 精读第一梯队 3–4 篇（见下）；跑通并吃透 baseline 出图 |
| 3–4 | 写出观测模型 + FIM 推导（极坐标近似闭式）；MATLAB 数值验证 CRLB |
| 5–6 | 实现感知最优码本（先网格后梯度）；出实验 1–3 |
| 7–8 | 出实验 4–6；整理通信-感知折中主图 |
| 9–12 | 写作：Introduction（含竞品切割）、系统模型、CRLB、优化、仿真、结论；内部修改 |

---

## 八、精读清单（真实文献，分梯队）

**第一梯队（必读，1–2 周内看完，直接决定你能不能写）**
1. **Zheng et al., "Near-Field Wideband Beam Training Based on Distance-Dependent Beam Split," IEEE TWC, vol.24, no.2, Feb 2025**（arXiv:2406.07989）— 你的基石，代码就是它。
2. **F. Liu, Y.-F. Liu, A. Li, C. Masouros, Y. C. Eldar, "Cramér-Rao Bound Optimization for Joint Radar-Communication Beamforming," IEEE TSP, vol.70, 2022** — "把 CRLB 当设计目标"的范式，B 的方法论母版。
3. **H. Wang, Z. Xiao, Y. Zeng, "Cramér-Rao Bounds for Near-Field Sensing with Extremely Large-Scale MIMO," IEEE TSP, 2024** — 近场角/距 CRB 的闭式推导模板。
4. **H. Luo, F. Gao, W. Yuan, S. Zhang, "Beam Squint Assisted User Localization in Near-Field ISAC," IEEE TWC, vol.23, no.5, 2024** + **arXiv:2509.14850** — 两个直接竞品，读它们**就是为了写清楚你和它们的区别**。

**第二梯队（写到对应章节时再查，不必先通读）**
5. H. Hua, T. X. Han, J. Xu, "MIMO Integrated Sensing and Communication: CRB-Rate Tradeoff," IEEE TWC, 2024 — 通信-感知折中的经典框架。
6. H. Hua, J. Xu, R. Zhang, "Near-Field ISAC with Extremely Large-Scale Antenna Array," arXiv:2407.17237 — 近场 ISAC 折中。
7. Hua & Xu, "Near-Field 3D Localization via MIMO Radar: CRB and Estimator Design," arXiv:2305.10986 — 估计器 + CRB 对照。
8. M. Cui, L. Dai, "Near-Field Wideband Beamforming for XL Antenna Arrays," IEEE TWC, 2024（arXiv:2109.10054）— TTD/DPP 架构。
9. C. Meng et al., "Near-Field Hybrid Beamforming for Modular XL-MIMO ISAC," IEEE TCOM, Nov 2025（arXiv:2406.12323）— 近场 ISAC 波束成形近况。

**背景/综述（选读）**
10. "Recent Advances in Near-Field Beam Training and Channel Estimation for XL-MIMO," arXiv:2504.05578。
11. "A Tutorial on Near-Field XL-MIMO Communications Towards 6G," arXiv:2310.11044。

**训练码本基线 / 工具（用户新上传的三篇，用于对比与借工具，非竞品）**
12. **X. Shi, J. Wang, Z. Sun, J. Song, "Spatial-Chirp Codebook-Based Hierarchical Beam Training for XL Massive MIMO," IEEE TWC, 2023**（arXiv:2210.03345）— 借它的**流形优化 + 交替最小化**码本设计框架用于第五节 CRLB 最优码本；同时作训练开销基线。
13. **C. Weng et al., "Pattern Zooming: Near-Field Wideband Beam Training with Wavenumber-Domain Codebook," 2026**（arXiv:2608.03615）— 最新宽带近场训练基线（纯训练，无感知），作对比。
14. **"Pilot-Efficient Beam Training and Codebook Design for Near-Field XL-MIMO Systems"**（待核实）— 标题与 B 最接近，**优先精读其贡献列表**确认是否涉及感知/CRLB；若仅通信训练码本则不冲突。

---

## 九、主要风险与应对

| 风险 | 应对 |
|---|---|
| 新颖性被质疑（beam-squint 定位已有） | 第一节的防御表；标题/贡献强调"**训练码本设计** + **双功能** + **CRLB 最优**"，不写成"又一个定位方法" |
| CRLB 推导卡壳 | 先用极坐标近似拿闭式（相位线性→好推）；对照第一梯队 2、3 的模板 |
| 优化难收敛 | 先网格搜索保证出图，再上梯度/manopt 当加分项 |
| 折中不明显 | 调 $N_t$、$B$、扫描范围找到 CRLB 与增益真正冲突的工作区 |
