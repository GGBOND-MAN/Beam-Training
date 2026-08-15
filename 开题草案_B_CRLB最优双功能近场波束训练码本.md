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
| 🔴 **DPP-ISAC（最危险）**：H. …，"CRB Optimization for Near-Field Wideband ISAC: Delay-Phase Precoding for Beam Squint Mitigation," **IEEE WCL 2025, 14(11):3794-3798** | **近场宽带 + TTD/延迟-相位预编码 + 角/距 CRB 闭式 + min CRB s.t. 通信速率 + 通感折中**（penalty+BCD）——**几乎命中 B 的三支柱** | **不是训练码本**：它是**数据阶段、面向已知/已跟踪目标的发射预编码器**；无初始接入、无不确定域上的主动实验设计、无 beam-split 训练扫描 | ⚠️ **必读**（仅读到摘要/元数据） |
| **Pattern Zooming**（arXiv:2608.03615, 2026, BUPT） | 宽带 + TD 波束扫描 + 波数域(DFT类)码本 + 角距**闭式几何估计器**；性能仅用 **RMSE** 实测 | 无 CRLB/统计下界、无码本最优设计、无通感折中（全文无 Cramér/CRB）；波数域码本（非极坐标/beam-split） | ✅ 2026-08-11 |
| **Luo & Gao (TWC 2024) / arXiv:2309.14012 + 2509.14850** | beam-squint + MUSIC 角距定位（**估计器**）；机制最近（也用 TTD 控 squint 让不同子载波指向不同角/距） | 无码本最优设计、无通感折中 | ⚠️ 待读（PDF 已入库） |
| **Pilot-Efficient**（Parvini 等, TU Dresden, **IEEE OJ-COMS 2026**, DOI 10.1109/OJCOMS.2026.3690933） | **窄带**；紧凑近场码本（用多用户干扰+空间相关降码本规模）+ 三阶段训练：子阵分层搜 AoD → **GILS 几何交叉最小二乘**融合定位 → 位置映射到码字 | 无 CRB/Fisher（全文 0 命中）、无 TTD/beam-split、无通感折中；码本目标是**降规模/抗干扰/省导频**，不是最小化估计界 | ✅ 2026-08-11 |

> ✅ **Pilot-Efficient 已核实（2026-08-11 读全文 17 页）**：它与 B 的表面重叠（标题含 "Codebook Design" + 用到定位）是假象——它是**窄带、面向多用户降开销/抗干扰**的码本 + GILS 定位当"选码字的手段"，**没有 CRLB、没有 beam-split、没有通感折中**。反而是 B 的好**动机/基线**："已有近场码本设计只优化规模/干扰/开销，无人刻画或优化感知 CRLB，也无人给通感折中"。

**共同空档（= B 的立足点）：没有一篇 (a) 推导该类波形的角/距 CRLB，(b) 按最小化 CRLB 去设计训练码本，(c) 给出通信-感知折中。**（Pattern Zooming 与 Pilot-Efficient 均已逐字核实确认不做这三点。）

> 🔴 **2026-08-11 新增风险预警（诚实评估）**：检索发现 **IEEE WCL 2025 的 DPP-ISAC 竞品**（Z. Zhang, Z. Wei, Z. Xu, H. Zeng, X. Zhu, WCL 14(11):3794-3798）已在**近场宽带 TTD** 下做了"CRB(角/距)闭式 + 最小化 + 通感折中"——这**压缩了 B 的新意余量**：B 不能再宣称"首个近场宽带 TTD 的 CRB 最优 ISAC 波形"。**B 存活的唯一防线收窄为**："**波束训练码本 / 初始接入 / 不确定域上的主动实验设计**"——即设计的是位置未知时的**训练扫描波形**（非已知目标的数据预编码器）。
>
> ✅✅ **2026-08-12 最终判决（已读全文 5 页，100% 确认）：防线守得住。** 作者 Zhide Zhang, Zhongxiang Wei, Zhixiang Xu, Haiyong Zeng, Xu Zhu（HIT-Shenzhen/Tongji），LWC.2025.3605391。全文关键词实测：**beam training / codebook / initial access / pilot / beam sweep / channel estimation 各 0 次**；precod 12 次、target 24 次。它是：BS 服务**单天线下行用户**、**同时感知一个（独立的）目标**；优化变量 = **DPP 数据预编码器**（PS 权 $\mathbf F$ + TTD 时延 $\mathbf t$，作用在 OFDM 数据符号 $s_{m,n}$ 上）；目标 = min **目标位置** CRB s.t. **用户通信 QoS**；penalty+BCD 求解。**与 B 的四条硬切割（可直接写进 Introduction）：**
>
> | 维度 | WCL 2025 DPP-ISAC | 你的 B |
> |---|---|---|
> | **对象** | DPP **数据预编码器** $(\mathbf F,\mathbf t)$（连续矩阵） | **训练码本**：$P$ 个 beam-split 扫描码字 $(\theta_1,\alpha_1,\theta_2,\alpha_2)_s$ |
> | **阶段/场景** | 数据传输阶段，**目标位置已知**（为其设计预编码器） | **初始接入/波束训练**，**用户位置未知**，正要发现 |
> | **任务** | 已知位置下的波形优化 | **不确定域 $\Omega$ 上的主动实验设计**（下一组训练波束扫哪最信息量大） |
> | **通感对象** | 通信用户与感知目标是**两个不同实体**（服务用户+感知目标） | 通信与感知是**同一个用户**（训练即定位，真·双功能） |
>
> 其"感知性能 ∝ 各子载波在目标处波束增益的加权和"与 B 的机制同源，但**用在已知目标上**；B 把它用在**未知用户的训练码本主动设计**上。整个近场宽带 ISAC-CRB 论文簇（DPP-ISAC / Fan Liu / 2311.05372 / 2302.01153 / 2412.13532 / 2603.27726）**全是预编码器或界分析，无一做训练码本 / 初始接入主动设计** → 这条线 B **独占**。（该预警与判决采纳自用户 ChatGPT 讨论里的提醒，详见第九节末分析。）

**两篇"帮手"论文（非竞品，已读原文，用作方法论母版与优化工具）：**
- **Fan Liu et al., "Cramér-Rao Bound Optimization for Joint Radar-Communication Beamforming," TSP 2022** —— 把 CRB 当设计目标的**母版**：其问题 (19) = `min CRB  s.t. 每用户 SINR γ_k ≥ Γ_k + 发射功率预算`（单用户闭式解、多用户 SDR 全局最优）。B 直接抄这个骨架，把变量换成码本参数 (θ₁,α₁,θ₂,α₂)、把 SINR 约束换成通信阵列增益约束。它是**远场、窄带、纯波束成形**——正好把"近场 + 宽带 beam-split 训练码本"整块留给 B。
- **Xu Shi et al., "Spatial-Chirp Codebook-Based Hierarchical Beam Training," TWC 2023**（arXiv:2210.03345）—— 窄带纯训练、无 CRB、无定位；本文只用作**优化工具来源**（流形优化 + 交替最小化），可搬到 B 第五节的码本参数优化。

**四点贡献（两支柱，写进 Introduction）**：
1. **理论极限**（半闭式）：首次推导近场宽带 distance-dependent beam-split **训练**波形下角度/距离估计的 CRLB，写成 TTD/PS 码本参数 (θ₁,α₁,θ₂,α₂) 的显式函数（三阶天线矩 G⁰/G¹/G²，已数值验证 0.02–0.18%）。
2. **最优设计 + 通感折中**（支柱一）：以**不确定域 Ω 上最坏情况 CRLB**为目标做**主动实验设计**（非已知目标预编码器），其产物是**由 beam-split 物理关系把 Ω 映射成的几何暖启动码本**——消融证明精度主要来自这一步物理初始化（仅暖启动即到 2.07 mm，penalty+BCD 精修再降 1.4× 到 1.47 mm，且景观良性/单块即足）；加通信增益约束 → 通感 Pareto，角/距 CRLB 同降 ~4× 且增益从 0.64 升到 0.94。
3. **训练开销↔定位精度标度律**（支柱二，冲主刊）：把定位 CRLB 刻画为训练开销 T 的显式标度（baseline ∝T⁻⁰·⁵³验证可加性、最优∝T⁻⁰·⁸³），给最小开销 T\*(ε)；证明固定精度下**训练开销省 ~75%**。
4. **对标**：证明现有训练+定位方案（Pattern Zooming / GILS / beam-squint MUSIC）离 CRLB 尚有差距，所提最优码本可逼近该界。

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
**半闭式核心（三阶矩表示，已在代码中数值验证）。** 关键观察：把每个波束的天线积
$g_{s,m}(n)\triangleq h_m(n)\,w_{s,m}(n)$（$h_m(n)$ 精确球面波信道行，$w_{s,m}$ 码字）只需三个
**对天线序号的加权矩**就能把导数写成闭式（无需有限差分、无需二维网格）：
$$
G^{(0)}_{s,m}=\sum_n g_{s,m}(n),\quad
G^{(1)}_{s,m}=\sum_n n\,g_{s,m}(n),\quad
G^{(2)}_{s,m}=\sum_n n^2 g_{s,m}(n).
$$
利用 Fresnel/极坐标展开 $r_n\approx r-nd\sin\theta+\tfrac{n^2d^2\cos^2\theta}{2r}$（相位对 $\vartheta=\sin\theta,\ \alpha=\cos^2\theta/(2r)$ 线性），直接对 $(\theta,r)$ 求导得
$$
\boxed{\;
\frac{\partial \mu_{s,m}}{\partial\theta}=j\beta k_m\Big[d\cos\theta\,G^{(1)}_{s,m}+\tfrac{d^2\cos\theta\sin\theta}{r}\,G^{(2)}_{s,m}\Big],\quad
\frac{\partial \mu_{s,m}}{\partial r}=-j\beta k_m\Big[G^{(0)}_{s,m}-\tfrac{d^2\cos^2\theta}{2r^2}\,G^{(2)}_{s,m}\Big]\;}
$$
以及 $\partial\mu/\partial\Re\beta=G^{(0)}_{s,m},\ \partial\mu/\partial\Im\beta=jG^{(0)}_{s,m}$。把这四个导数代入上面的 FIM 求和即得 $4\times4$ 矩阵 $\mathbf J(\theta,r;\{\boldsymbol\phi_s\})$（对 $\beta$ 的两维即"消冗余参数"），
$$
\mathrm{CRLB}(\theta)=[\mathbf J^{-1}]_{11},\qquad \mathrm{CRLB}(r)=[\mathbf J^{-1}]_{22}.
$$
**物理含义**：$G^{(1)}$（权 $\propto k_m n$）承载角度信息、$G^{(2)}$（权 $\propto k_m n^2$）承载近场曲率(距离)信息、$G^{(0)}$ 里跨子载波的 $k_m$ 依赖承载 TOF(时延)测距——这解释了为何 2 GHz 带宽下距离 CRLB 可达亚毫米级。

> **数值验证（已跑通，`optionB_crlb/crlb_closed_form.py`）**：上式半闭式 FIM 与对**精确** $r_n$ 做中心差分的 FIM 在 5 个测试点（$\theta\in[-20^\circ,30^\circ],\ r\in[10,40]$ m）逐一对照，$\sqrt{\mathrm{CRLB}}$ **相对误差 0.02%–0.18%**（角度）与 **≈0.02%**（距离）。即：Fresnel 近似导数几乎无损，半闭式可直接当作第五节优化的**快速可微目标**。这一"半闭式↔精确"对照本身就是论文里一个干净的小贡献点。

> **推导可对照的模板**（照抄结构、换成你的 $\mathbf w_{s,m}$ 即可）：
> - F. Liu et al., "CRB Optimization for Joint Radar-Communication Beamforming," TSP 2022（把 CRLB 当设计目标的范式）
> - H. Wang, Z. Xiao, Y. Zeng, "CRBs for Near-Field Sensing with XL-MIMO," TSP 2024（近场角/距 CRB 闭式）
> - Hua & Xu, "Near-Field 3D Localization via MIMO Radar: CRB and Estimator," arXiv:2305.10986

**注**：可先用极坐标近似相位得闭式 CRLB（好看、好写），再用**精确** $r_n$（`near_field_manifold.m`）数值验证——近距离下精确幅相更准（Hua/Xu 已指出），这个对照本身可作为一个小贡献点。

---

## 五、感知最优码本设计问题

**两阶段主动波束训练（这是与所有 ISAC 预编码器竞品的硬切割点）。** 不做"已知真值 $(\theta,r)$ 下的单点 CRLB 最小化"——那会被审稿人一句"位置都知道了还训练什么"打回。改成**主动实验设计（optimal experiment design）**：
- **阶段一（粗）**：用现有低开销 beam-split 扫描把用户粗定位到一个**不确定域** $\Omega=\{\theta\in[\hat\theta\pm\Delta_\theta],\ r\in[\hat r\pm\Delta_r]\}$。
- **阶段二（精，本节设计）**：在**仅知 $\Omega$** 的前提下，联合设计 $P=k_0$ 个 beam-split 训练码字 $\{\boldsymbol\phi_s\}$，使**最坏情况**感知 CRLB 最小、同时保通信增益：
$$
\min_{\{\boldsymbol\phi_s\}_{s=1}^{P}}\ \ \max_{(\theta,r)\in\Omega}\ \Big[\tfrac{\mathrm{CRLB}_\theta}{\sigma_{\theta_0}^2}+\tfrac{\mathrm{CRLB}_r}{\sigma_{r_0}^2}\Big]
\quad\text{s.t.}\quad
\min_{(\theta,r)\in\Omega} G(\theta,r;\{\boldsymbol\phi_s\})\ge \gamma,\ \ P\le P_{\max}.
$$
（也可用区域平均/Bayesian CRLB $\int_\Omega \operatorname{tr}\tilde{\mathbf J}^{-1}\,\mathrm d\pi$ 代替最坏情况。）**关键设计杠杆**：噪声取**固定绝对值**后，把 beam-split 扫描从"扫满整个角-距空间"收窄到"只覆盖 $\Omega$"，就能把原本浪费在 $\Omega$ 外的子载波能量**集中到用户**上 → Fisher 信息↑ → CRLB↓。

**（主线）本节的产物不是某个黑箱优化解，而是一条物理设计链**：初始接入时位置未知 → 阶段一把用户锁进不确定域 $\Omega$ → 阶段二用 beam-split 物理关系 $\vartheta_{\mathrm{eff}}(m)=\theta_1+(f_c/f_m)\theta_2$ 把 $\Omega$ **直接映射**成一组"焦点扫过 $\Omega$"的训练码字（下称**几何暖启动**）。这组暖启动码本就是**两阶段主动实验设计的输出**，也是——如后文消融所证——**精度的真正来源**；随后的 penalty+BCD 只是在其上的良性精修。全节请按这条主线读：*暖启动是主角，优化器是配角*。

**已跑通的概念验证（`optionB_crlb/crlb_codebook_opt.py`，用第四节半闭式 CRLB 作目标）**：$\Omega$ 取 $\theta_0=11.54^\circ\pm1^\circ,\ r_0=20\pm2$ m；把扫描收窄到 $\Omega$ 尺度后，相对空间覆盖 baseline：

| 码本 | worst-$\Omega$ $\sqrt{\mathrm{CRLB}_\theta}$ | worst-$\Omega$ $\sqrt{\mathrm{CRLB}_r}$ | worst-$\Omega$ 通信增益 |
|---|---|---|---|
| baseline（扫满全空间） | 0.0396° | 6.34 mm | 0.639 |
| **$\Omega$-聚焦（本节设计）** | **0.0111°（↓3.57×）** | **2.39 mm（↓2.65×）** | **0.659（↑）** |

即：所设计码本在**不牺牲、反而略升通信增益**的同时，把角/距 CRLB 同时压低约 2.6–3.6 倍（图 `optionB_crlb/crlb_pareto.png`：收窄扫描→CRLB 单调下降，且折中曲线上"聚焦设计"点**同时优于** baseline 的增益与 CRLB）。

**精修优化器（penalty + BCD，接在几何暖启动之上，已实现并出 Pareto）**：把上面的物理初值升级为完整解法——**从几何暖启动出发**、对码字参数做 penalty+BCD 精修；解法**刻意对标 DPP-ISAC 竞品的 penalty+BCD 结构**，以强调"同样的解法工具、不同的问题（训练码本 vs 数据预编码器），且精度主要来自我们特有的物理暖启动、而非解法本身"。设计变量按物理分两块——**TTD 块** $\{(\theta_1,\alpha_1)_s\}$（随频率、定 beam-split 轨迹）与 **PS 块** $\{(\theta_2,\alpha_2)_s\}$（随载频固定、定基准聚焦点）；标量化
$$
\Phi(\{\boldsymbol\phi_s\};\mu)=\max_{(\theta,r)\in\Omega}\Big[\tfrac{\mathrm{CRLB}_\theta}{\sigma_{\theta_0}^2}+\tfrac{\mathrm{CRLB}_r}{\sigma_{r_0}^2}\Big]-\mu\cdot\min_{(\theta,r)\in\Omega}G(\theta,r),
$$
**BCD 交替**优化 TTD 块与 PS 块（各块用 fminsearch/一维搜索），**扫描权重 $\mu$**（$\mu=0$ 感知最优；$\mu$ 大→通信增益最优）得**通信-感知 Pareto 前沿**——期刊主打图。

**已跑通结果**（`optionB_crlb/crlb_bcd.py`（NumPy）与 `run_codebook_bcd.m`（MATLAB，复用 `crlb_fim.m`/baseline），图 `crlb_bcd_pareto.png`）：

| 设计 | worst-$\Omega$ $\sqrt{\mathrm{CRLB}_r}$ | worst-$\Omega$ $\sqrt{\mathrm{CRLB}_\theta}$ | worst-$\Omega$ 通信增益 |
|---|---|---|---|
| baseline（扫满全空间） | 6.34 mm | 0.0396° | 0.639 |
| BCD，$\mu=0$（感知最优） | **1.58 mm** | **0.0098°** | 0.618 |
| BCD，$\mu=0.5$（拐点，通感双优） | **1.46 mm** | 0.0106° | **0.940** |
| BCD，$\mu=8$（增益最优） | 1.64 mm | 0.0112° | **0.954** |

即：**penalty+BCD 优化后的训练码本在整条前沿上都全面压制 baseline**——角/距 CRLB 同时降 **~4×**（6.34→1.46 mm、0.0396→0.0106°），通信增益还从 0.64 升到 **0.94–0.95**；$\mu$ 从 0 增大时增益 0.62→0.95、CRLB 轻微上升 1.46→1.64 mm，勾出通信-感知折中的高增益端。

**消融实验（`optionB_crlb/crlb_ablation.py` / `run_ablation.m`，图 `crlb_ablation.png`；NumPy↔Octave 交叉验证）**：为厘清"精度到底来自哪个环节"，把 §5 优化器的两个**可拆环节**逐一移除（全部在 $\mu=0.5$、同一 CRLB 下）：① 几何**暖启动**（由 beam-split 关系 $\vartheta_{\mathrm{eff}}(m)=\theta_1+(f_c/f_m)\theta_2$ 推出的 $\Omega$-聚焦初值）；② penalty+BCD **精修**（TTD 块 + PS 块）。

| 变体（$\mu=0.5$） | worst-$\Omega$ $\sqrt{\mathrm{CRLB}_r}$ | $\sqrt{\mathrm{CRLB}_\theta}$ | 通信增益 |
|---|---|---|---|
| baseline（扫满全空间） | 6.34 mm | 0.0396° | 0.639 |
| 朴素 BCD（**无暖启动**，从 baseline 出发） | 4.84 mm | 0.0358° | 0.957 |
| **仅暖启动**（$\Omega$-聚焦初值，不精修） | 2.07 mm | 0.0128° | 0.890 |
| 暖启动 + 仅 PS 块 | 1.47 mm | 0.0110° | 0.938 |
| 暖启动 + 仅 TTD 块 | 1.46 mm | 0.0107° | 0.940 |
| **暖启动 + 完整 BCD（所提）** | **1.47 mm** | **0.0107°** | **0.942** |

> **诚实结论（务必按数据写，不要拔高成"两块缺一不可"）**：真正决定精度的是**几何暖启动**。不给暖启动、直接从"扫满全空间"跑 penalty+BCD，会**卡在坏的局部盆地（4.84 mm，比所提差 3.3×）**；仅凭几何暖启动（完全不精修）就已到 **2.07 mm**，再经 penalty+BCD 精修**又快 1.4× 到 1.47 mm**。而**给定暖启动后**，只优化 TTD 块、只优化 PS 块、或两块联合，**都收敛到同一最优（相差仅 0.01 mm）**——延迟-相位码本在最优点附近"最后一公里"景观良性、**单块即足**。写论文时如实陈述：*精度来自物理推导的初始化，而非分块交替本身*；把"暖启动决定性 + 优化景观良性/可复现"作为正面卖点，同时坦诚"最优点附近两块冗余"这一负面结果——这比虚构"两块必要"更经得起审稿。

> **（主线落点）把上面两段合起来看**：B 相对 DPP-ISAC 竞品的真正区分，**不在"有没有 penalty+BCD"（竞品也有），而在"位置未知 → $\Omega$ → beam-split 物理暖启动"这条主动实验设计链**——竞品是已知目标的数据预编码器，根本没有这条链。消融把这点坐实成一句可直接写进 Introduction 的话：*所提码本的精度增益（$6.34\to1.47$ mm，↓4.3×）主要来自两阶段主动实验设计所产生的**几何暖启动**，penalty+BCD 精修只贡献最后 1.4×，且优化景观良性、单块即可复现*。这比"我们有个更好的优化器"更难被一句话打回，也把 B 的卖点从"解法"稳稳落到"**物理推导的主动实验设计**"上。

> **硬切割（审稿人必问，务必写清）**：近场宽带 TTD 的 **"CRB 最优 ISAC 预编码器"** 已被 [WCL 2025 DPP 竞品](#) 与 Fan Liu(TSP'22)/arXiv:2311.05372 做过——但它们都是**数据阶段、面向已知/已跟踪目标的发射预编码器**。B 是**初始接入阶段的波束训练码本**：用户位置**未知**，在**不确定域 $\Omega$ 上做主动实验设计**，设计的是"下一组训练波束扫到哪里最能提取 $(\theta,r)$ 的 Fisher 信息"。对象（训练码本 vs 数据预编码器）、场景（位置未知的初始接入 vs 已知目标）、贡献（active experiment design vs 波形优化）都不同。**注**：B **刻意采用与竞品相同的 penalty+BCD 解法**，正是为了让审稿人聚焦到"问题不同"而非"方法不同"。**这是 B 在 CRB-ISAC 已拥挤下仍成立的关键，也是必须守住的唯一防线。**

---

## 五之二、第二支柱：训练开销 ↔ 定位 CRLB 折中（把 B 顶到主刊水位）

**为什么加这条**：光靠"训练码本 vs 预编码器"的切割，主刊审稿人可能嫌薄。加上"**训练开销—定位精度**的理论折中"能补足深度，而且它是个**只有"训练"框架才有、"预编码器"框架根本没有**的量纲（预编码器没有导频/开销概念）——所以第二支柱**又一次**把 B 和所有 ISAC-预编码器竞品分开。

**核心理论（干净、可写闭式）**：FIM 对训练时隙**可加**，
$$
\mathbf J(T)=\sum_{s=1}^{T}\mathbf J_s(\{\boldsymbol\phi_s\}),\qquad \mathbf J_s\succeq 0,
$$
故每加一个 beam-split 训练码字（时隙），CRLB **单调下降**。当 $T$ 个码字是对 $\Omega$ 的"有效独立观测"时，感知信息近似线性增长 → **$\sqrt{\mathrm{CRLB}}\propto T^{-1/2}$**；而 **CRLB 最优码本**在增加时隙的同时**收窄每个时隙的覆盖**（集中度 $\propto T$），使 $\mathbf J(T)$ 增长更快 → 标度更陡。达到目标精度 $\varepsilon$ 所需**最小训练开销** $T^\star(\varepsilon)$ 因此远小于启发式码本。

**已跑通的量化（`optionB_crlb/crlb_overhead.py`，图 `crlb_overhead.png`）**：$\Omega=\theta_0=11.54^\circ\pm1^\circ,\ r_0=20\pm2$ m，固定每时隙功率、绝对噪声：

| 训练开销 $T$（beam-split 时隙数） | baseline（扫满全空间）worst-$\Omega$ $\sqrt{\mathrm{CRLB}_r}$ | **$\Omega$-聚焦最优** |
|---|---|---|
| 1 | 10.40 mm | **3.46 mm** |
| 2 | 6.34 mm | **2.07 mm** |
| 4 | 4.78 mm | **0.95 mm** |
| 8 | 3.30 mm | **0.64 mm** |

- **标度律实测**：baseline $\sqrt{\mathrm{CRLB}_r}\propto T^{-0.53}$（**验证了 $T^{-1/2}$ 可加性理论**）；$\Omega$-聚焦最优 $\propto T^{-0.83}$（更陡，因兼有"集中"增益）。
- **固定精度下的开销节省**：达到 $\sqrt{\mathrm{CRLB}_r}\le 5$ mm，baseline 需 **$T=4$** 时隙，最优码本仅需 **$T=1$** → **训练开销省 75%**（等价地：固定开销下角/距精度提升 ~3×）。

**第二支柱的贡献句（写进 contributions）**：*首次把近场 beam-split 训练码本的角/距定位 CRLB 刻画为训练开销 $T$ 的显式标度律 $\mathrm{CRLB}\!\sim\!T^{-1}$，并给出达到目标定位精度的最小开销 $T^\star(\varepsilon)$；证明所提 CRLB 最优码本在固定精度下把训练开销降低约 75%（固定开销下精度提升约 3 倍）。* 这把 B 的"低开销训练"血统（Zheng distance-dependent beam-split 基线）直接接到"定位精度极限"上，是 ISAC-预编码器路线完全没有的维度。

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
