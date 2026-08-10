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

**竞品复核（2026-08-09 读了用户新上传的三篇，在 `extracted/` 有提取文本）：**
- **Pattern Zooming**（arXiv:2608.03615, 2026, BUPT）：宽带 + Full-TTD + 少导频 + 角距**闭式定位**。**B 的"训练即定位"headline 基本被它占**，是最强竞品。但它没有 CRLB、没有码本最优设计、没有通感折中，用波数域 DFT 码本（B 用极坐标/beam-split 码本）。
- **Pilot-Efficient**（Parvini 等，IEEE OJ-COMS 2026）：窄带，子阵三角化 GILS 定位 + 干扰感知码本采样。无 TTD/beam-split/CRLB。
- **Spatial-Chirp**（Shi 等，TWC 2023, arXiv:2210.03345）：窄带分层 chirp 码本 + 流形优化；纯训练，当基线/借优化工具。

**因此 B 需重新收窄卖点**：从"边训练边定位"（已被占）→ **"近场宽带 beam-split 训练波形的 CRLB 极限 + CRLB 最优码本设计 + 通信-感知折中"**（这三点上述竞品都没做）。把三篇竞品当动机与基线。若嫌新意余量薄，备选是**波束跟踪**（最不拥挤，但更慢）。

CRLB 脚本已写好并修好性能问题：`optionB_crlb/run_crlb_experiment.m`（复用 near_field_channel / delay_polar_2d）。代码基线在 `baseline_distance_dependent/code_nf_distance_dependent_rainbow`。相关背景见 [[matlab-agentic-setup]]、[[pdf-extraction-pymupdf]]。
