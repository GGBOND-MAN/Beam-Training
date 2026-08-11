This simulation code package is mainly used to reproduce the results of the following paper [1]:

[1] T. Zheng, M. Cui, Z. Wu and L. Dai, “Near-field wideband beam training based on distance-dependent beam split,” IEEE Trans. Wireless Commun., vol. 24, no. 2, pp. 1278-1292, Feb. 2025.
*********************************************************************************************************************************
If you use this simulation code package in any way, please cite the original paper [1] above. 
 
The author in charge of this simulation code pacakge is: Tianyue Zheng (email: zhengty22@mails.tsinghua.edu.cn).

Reference: We highly respect reproducible research, so we try to provide the simulation codes for our published papers 
( more information can be found at: 
http://oa.ee.tsinghua.edu.cn/dailinglong/publications/publications.html )

Please note that the MATLAB R2020a is used for this simulation code package,  
and there may be some imcompatibility problems among different MATLAB versions. 

Copyright reserved by the Broadband Communications and Signal Processing Laboratory (led by Dr. Linglong Dai), 
Beijing National Research Center for Information Science and Technology (BNRist), 
Department of Electronic Engineering, Tsinghua University, Beijing 100084, China. 

*********************************************************************************************************************************
Abstract of the paper: 

Near-field beam training is essential for acquiring channel state information in 6G extremely large-scale multiple input multiple output (XL-MIMO) systems. To achieve low-overhead beam training, existing method has been proposed to leverage the near-field beam split effect, which deploys true-time-delay arrays to simultaneously search multiple angles of the entire angular range in a distance ring with a single pilot. However, the method still requires exhaustive search in the distance domain, which limits its efficiency.  To address the problem, we propose a distance-dependent beam-split-based beam training method to further reduce the training overheads.  Specifically, we first reveal the new phenomenon of distance-dependent beam split, where by manipulating the configurations of time-delay and phase-shift, beams at different frequencies can simultaneously scan the angular domain in multiple distance rings.  Leveraging the phenomenon, we propose a near-field beam training method where both different angles and distances can simultaneously be searched in one time slot. Thus, a few pilots are capable of covering the whole angle-distance space for wideband XL-MIMO. Theoretical analysis and numerical simulations are also displayed to verify the superiority of the proposed method on beamforming gain and training overhead.
*********************************************************************************************************************************
How to use this simulation code package?

1. Fig. 6 in this paper can be obtained by running "distance_dependent_beam_split.m".
2. Fig. 7 in this paper can be obtained by running "Rate_snr.m".
3. Fig. 8 in this paper can be obtained by running "Rate_overhead.m".
4. Fig. 9 in this paper can be obtained by running "CDF_array_gain.m".
5. Fig. 10 in this paper can be obtained by running "Rate_distance.m".
*********************************************************************************************************************************
Enjoy the reproducible research!