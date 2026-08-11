# 方案 B 必读清单（补充下载的论文）

这些是方案 B（CRLB 最优双功能近场波束训练码本）需要、但项目根目录原本没有的论文。
仓库根目录已有的另 4 篇（Distance-Dependent Beam Split、Fan Liu CRB、Pattern Zooming、
Spatial-Chirp、Rainbow、综述 2504.05578 等）不在此列。所有条目 arXiv 号均已核实真实可查。

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

## 仍缺（需你提供）
- **Pilot-Efficient Beam Training and Codebook Design for Near-Field XL-MIMO Systems**（Parvini 等，据称 OJ-COMS 2026）——公网查无正文，是唯一未核实的潜在竞品（标题含 "Codebook Design"）。拿到 PDF 后须逐条确认它有没有做 (a) CRLB、(b) 按界最优设计码本、(c) 通感折中。
