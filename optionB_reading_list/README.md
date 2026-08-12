# 方案 B 必读清单（补充下载的论文）

这些是方案 B（CRLB 最优双功能近场波束训练码本）需要、但项目根目录原本没有的论文。
仓库根目录已有的另 4 篇（Distance-Dependent Beam Split、Fan Liu CRB、Pattern Zooming、
Spatial-Chirp、Rainbow、综述 2504.05578 等）不在此列。所有条目 arXiv 号均已核实真实可查。

## 🔴🔴 最高优先（新发现的最危险竞品，动手前必读全文）

- **"Cramér-Rao Bound Optimization for Near-Field Wideband ISAC: Delay-Phase Precoding for Beam Squint Mitigation," IEEE Wireless Communications Letters, vol. 14, no. 11, pp. 3794–3798, 2025.** —— IEEE Xplore 获取（疑似无 arXiv 版，需下载后传进仓库）。**近场宽带 + TTD/DPP + 角距 CRB 闭式 + min CRB s.t. 通信 + penalty/BCD + 通感折中**，几乎命中 B 三支柱。**它是数据阶段的 ISAC 发射预编码器，不是初始接入的训练码本**——B 的唯一防线就是这条切割，动手前务必逐字确认它没碰"训练码本 / 不确定域主动实验设计"。

## 🔴 第一梯队（必读，决定能否动笔）

| 文件 | 论文 | 为什么读 |
|---|---|---|
| `CRB_NearField_Sensing_XL-MIMO_Wang2024_2303.05736.pdf` | H. Wang, Z. Xiao, Y. Zeng, "Cramér-Rao Bounds for Near-Field Sensing with XL-MIMO," **IEEE TSP 2024** (arXiv:2303.05736) | **近场角/距 CRB 的闭式推导模板**。B 第三节的 FIM/CRLB 推导直接对着它写（球面波模型下角度、距离的 CRB 闭式）。 |
| `Beam_Squint_Assisted_User_Localization_NearField_ISAC_LuoGao2024_2309.14012.pdf` | H. Luo, F. Gao, W. Yuan, S. Zhang, "Beam Squint Assisted User Localization in Near-Field ISAC," **IEEE TWC 2024** (arXiv:2309.14012) | **机制最接近的直接竞品**：同样用 TTD 控 beam squint 让不同子载波指向不同角/距。读它是为了写清切割——它是"估计器/定位算法"，B 是"CRLB 界 + 最优码本设计 + 通感折中"。 |

## 🟢 盯防（2026 新出，动手前后各查一次，防被抢先）

| 文件 | 论文 | 盯什么 |
|---|---|---|
| `CRB_Optimization_NearField_ISAC_Extended_Targets_2604.18166.pdf` | Z. Zhao et al., "Cramér-Rao Bound Optimization for Near-Field ISAC with Extended Targets," 2026 (arXiv:2604.18166) | 标题和 B 很近。确认它做的是**感知波束成形**（扩展目标），而非 **beam-split 训练码本**——若如此则不撞车。 |
| `Wideband_Compressed-Domain_CRB_NearField_XL-MIMO_2604.08531.pdf` | R. V. Şenyuva, "Wideband Compressed-Domain Cramér–Rao Bounds for Near-Field XL-MIMO," 2026 (arXiv:2604.08531) | 宽带近场 CRB 的最新推导，看它的界分解是否与 B 的推导重叠或可借用。 |

## ✅ 已核实、已入库（原"仍缺"项）
- **Pilot-Efficient Beam Training and Codebook Design for Near-Field XL-MIMO Systems**（Parvini, Banerjee, Khan, Nimr, Fettweis, TU Dresden, **IEEE OJ-COMS 2026**, DOI 10.1109/OJCOMS.2026.3690933）——PDF 在仓库根目录。**2026-08-11 读全文核实：不威胁 B。** 它是**窄带**紧凑近场码本（用多用户干扰+空间相关降码本规模）+ 三阶段训练（子阵分层搜 AoD → GILS 几何交叉最小二乘定位 → 位置映射到码字）；**无 CRLB、无 beam-split/TTD、无通感折中**，码本目标是降规模/抗干扰/省导频。→ 当 B 的动机/基线用（"已有近场码本只优化开销/干扰，无人做感知 CRLB 与通感折中"）。至此 B 的三支柱空档对所有已知竞品均已核实成立。
