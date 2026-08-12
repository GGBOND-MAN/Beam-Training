---
name: research-direction-optionb
description: Chosen research direction for the near-field beam training project — Option B (CRLB-optimal dual-function training codebook)
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f66d4ab-891d-45e9-891c-3d2a33cab17c
  modified: 2026-08-09T13:25:25.187Z
---

用户是研究近场波束训练（Near-Field Beam Training, XL-MIMO）的研究生，目标是快出成果发**期刊**（TWC/TCOM 级）。经过 2026-08-09 的讨论，已确定研究方向为 **方案 B**：

**CRLB 最优的双功能近场波束训练码本** —— 把 Zheng 等人的 distance-dependent beam split 训练码本重新设计成 CRLB 最优的 ISAC 波形，一次低开销扫描既训练通信波束、又定位用户，并给出通信-感知折中。

要点：
- 完整开题草案在项目目录 `开题草案_B_CRLB最优双功能近场波束训练码本.md`（系统模型、FIM/CRLB 推导框架、码本优化、仿真清单、精读清单、时间线）。
- 设计变量：码本参数 (θ₁,α₁,θ₂,α₂)，对应 baseline 代码 `delay_polar_2d.m`。α=cos²θ/(2r)，相位对 (sinθ,α) 线性 → FIM 近似闭式。
- **必须切割的直接竞品**：Luo & Gao "Beam Squint Assisted User Localization in Near-Field ISAC" (TWC 2024) 与 arXiv:2509.14850。卖点收窄到"训练码本设计 + 双功能 + CRLB 最优"，不要写成"又一个定位方法"。
- **已放弃**的方向：ChatGPT 建议的 `limited_ttd_extension`（受限 TTD 硬件感知），因结果半赢半输（只有 coarse-to-fine 赢，delay-aware grouping / group diversity 输），不足以撑期刊。
- 备选（未选）：波束跟踪（上限更高但慢，可作为 B 之后的第二篇）。

**竞品复核（2026-08-11 逐字读了用户传进仓库 origin/main 的三篇 PDF，PyMuPDF 提取全文）：**
- **Pattern Zooming**（arXiv:2608.03615, 2026, BUPT）✅已核实：宽带 + TD 波束扫描 + 波数域(DFT类)码本 + 角距**闭式几何估计器**，性能仅用 RMSE 实测。**全文无 Cramér/CRB**、无码本最优设计、无通感折中（tradeoff 命中 0）。是最强竞品（占"训练即定位"headline），但 B 的三支柱它全没做 → B 安全。
- **Spatial-Chirp**（Shi 等，TWC 2023, arXiv:2210.03345）✅已核实：窄带分层 chirp 码本 + 流形优化 + 交替最小化；无 CRB、无定位（"localization"仅出现在引言分类和参考文献里）。**非竞品**，当基线 + 借优化工具。
- **Cramér-Rao Bound Optimization for JRC Beamforming**（Fan Liu 等, TSP 2022）✅已核实：这是用户第三篇（不是 Pilot-Efficient）。远场 DFRC 波束成形，min CRB s.t. SINR+功率（问题19）。**这是 B 的方法论母版/骨架**，非竞品。
- **Pilot-Efficient**（Parvini 等, TU Dresden, IEEE OJ-COMS 2026, DOI 10.1109/OJCOMS.2026.3690933）✅**已核实**（2026-08-11 读全文 17 页, 用户传进仓库根目录）：**窄带**紧凑近场码本(用多用户干扰+空间相关降码本规模) + 三阶段训练(子阵分层搜 AoD → GILS 几何交叉最小二乘融合定位 → 位置映射到码字)。**无 CRB/Fisher(全文0命中)、无 TTD/beam-split、无通感折中**;码本目标是降规模/抗干扰/省导频。→ **不威胁 B**,反而当动机/基线("已有码本只优化开销/干扰,无人做感知CRLB")。至此 B 的残留风险全部清除。

- 🔴 **DPP-ISAC（最危险竞品，2026-08-11 检索发现）**：*"CRB Optimization for Near-Field Wideband ISAC: Delay-Phase Precoding for Beam Squint Mitigation," IEEE WCL 2025, 14(11):3794-3798*。近场宽带+TTD/DPP+角距CRB闭式+min CRB s.t.通信+penalty/BCD+通感折中——**几乎命中B三支柱**。但它是**数据阶段、已知/已跟踪目标的发射预编码器**，非初始接入的训练码本。⚠️仅读到摘要，**动手前必读全文**。→ **B新意余量被压缩**：不能再宣称"首个近场宽带TTD CRB最优ISAC波形"；唯一防线收窄为**"波束训练码本/初始接入/不确定域Ω上的主动实验设计"**（active experiment design，位置未知时设计训练扫描波形）。相关：Fan Liu TSP'22、arXiv:2311.05372、2302.01153 也都是ISAC预编码器（非训练码本）。

**因此 B 需重新收窄卖点**：从"边训练边定位"（已被占）→ 再从"近场宽带CRB最优ISAC"（被 DPP-ISAC 占）→ **"位置未知初始接入下、不确定域上的 CRLB 最优 beam-split 训练码本（两阶段主动实验设计）+ 通感折中"**。若嫌新意余量薄，备选是**波束跟踪**（最不拥挤，但更慢）。

**CRLB 脚本状态（2026-08-11 复核）**：`optionB_crlb/run_crlb_experiment.m` FIM/导数/估计器数学正确，签名与 baseline 对齐；但**蒙特卡洛验证 harness 有缺陷**——搜索网格步长(~0.2m)比 CRLB(~0.5mm)粗约 350×、且真值落在网格节点上，导致 MC RMSE 恒为 0（图退化，无法验证界）。修法：真值离网格 + **off-grid 连续 ML 细化**（先粗网格定 basin，再 Nelder-Mead/Gauss-Newton 细化）。已用 NumPy 独立复现验证（`optionB_crlb/crlb_validation_numpy.py`）。本机无 MATLAB/Octave（Linux 云端；用户真机是 Windows R2024b）。代码基线已从 zip 解压到 `baseline_distance_dependent/code_nf_distance_dependent_rainbow`。

**§3/§4 半闭式 CRLB（2026-08-11 已推导+验证，`optionB_crlb/crlb_closed_form.py`）**：把每波束天线积的三阶矩 G0=Σg, G1=Σn·g, G2=Σn²·g（g=h_m(n)w_{s,m}(n)）代入 Fresnel 展开，得 ∂μ/∂θ、∂μ/∂r 的闭式（G1↔角度、G2↔近场曲率/距离、G0跨子载波↔TOF测距）。半闭式FIM vs 精确有限差分FIM，5点相对误差 0.02%–0.18%。

**§5 感知最优码本（2026-08-11 概念验证，`optionB_crlb/crlb_codebook_opt.py`，图 crlb_pareto.png）**：两阶段主动实验设计——阶段一粗定位得不确定域Ω，阶段二 min-max_Ω CRLB s.t. 通信增益。固定绝对噪声下把 beam-split 扫描从"扫满全空间"收窄到"只覆盖Ω"，worst-Ω 角/距 CRLB 同时↓3.57×/2.65×，通信增益 0.639→0.659（不降反升）。核心卖点=训练码本的主动实验设计，切割 DPP-ISAC 数据预编码器。相关背景见 [[matlab-agentic-setup]]、[[pdf-extraction-pymupdf]]。
