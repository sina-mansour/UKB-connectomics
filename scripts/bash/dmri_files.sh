#!/bin/bash

files=(
	# stats
	"tractography/stats/sift_stats.csv"
	"tractography/stats/tracks_10M_stats.json"
	# per-streamline metrics
	"tractography/metrics/streamline_metric_NODDI_ICVF_mean.npy"
	"tractography/metrics/streamline_metric_0.001xS0_mean.npy"
	"tractography/metrics/streamline_metric_FA_mean.npy"
	"tractography/metrics/sift_weights.npy"
	"tractography/metrics/streamline_metric_length.npy"
	"tractography/metrics/streamline_metric_MO_mean.npy"
	"tractography/metrics/streamline_metric_1000xMD_mean.npy"
	"tractography/metrics/streamline_metric_NODDI_OD_mean.npy"
	"tractography/metrics/streamline_metric_NODDI_ISOVF_mean.npy"
	# endpoints
	"tractography/endpoints/tracks_10M_endpoints.npy"
	# connectomes
	"tractography/connectomes/Schaefer7n200p+Tian_Subcortex_S1_3T/connectome_mean_length_10M.csv"
	"tractography/connectomes/Schaefer7n200p+Tian_Subcortex_S1_3T/connectome_sift2_fbc_10M.csv"
	"tractography/connectomes/Schaefer7n200p+Tian_Subcortex_S1_3T/connectome_mean_FA_10M.csv"
	"tractography/connectomes/Schaefer7n200p+Tian_Subcortex_S1_3T/connectome_streamline_count_10M.csv"

	"tractography/connectomes/Glasser+Tian_Subcortex_S1_3T/connectome_mean_length_10M.csv"
	"tractography/connectomes/Glasser+Tian_Subcortex_S1_3T/connectome_sift2_fbc_10M.csv"
	"tractography/connectomes/Glasser+Tian_Subcortex_S1_3T/connectome_mean_FA_10M.csv"
	"tractography/connectomes/Glasser+Tian_Subcortex_S1_3T/connectome_streamline_count_10M.csv"

	"tractography/connectomes/aparc.a2009s+Tian_Subcortex_S1_3T/connectome_mean_length_10M.csv"
	"tractography/connectomes/aparc.a2009s+Tian_Subcortex_S1_3T/connectome_sift2_fbc_10M.csv"
	"tractography/connectomes/aparc.a2009s+Tian_Subcortex_S1_3T/connectome_mean_FA_10M.csv"
	"tractography/connectomes/aparc.a2009s+Tian_Subcortex_S1_3T/connectome_streamline_count_10M.csv"

	"tractography/connectomes/Schaefer7n500p+Tian_Subcortex_S4_3T/connectome_mean_length_10M.csv"
	"tractography/connectomes/Schaefer7n500p+Tian_Subcortex_S4_3T/connectome_sift2_fbc_10M.csv"
	"tractography/connectomes/Schaefer7n500p+Tian_Subcortex_S4_3T/connectome_mean_FA_10M.csv"
	"tractography/connectomes/Schaefer7n500p+Tian_Subcortex_S4_3T/connectome_streamline_count_10M.csv"

	"tractography/connectomes/Glasser+Tian_Subcortex_S4_3T/connectome_mean_length_10M.csv"
	"tractography/connectomes/Glasser+Tian_Subcortex_S4_3T/connectome_sift2_fbc_10M.csv"
	"tractography/connectomes/Glasser+Tian_Subcortex_S4_3T/connectome_mean_FA_10M.csv"
	"tractography/connectomes/Glasser+Tian_Subcortex_S4_3T/connectome_streamline_count_10M.csv"

	"tractography/connectomes/Schaefer7n1000p+Tian_Subcortex_S4_3T/connectome_mean_length_10M.csv"
	"tractography/connectomes/Schaefer7n1000p+Tian_Subcortex_S4_3T/connectome_sift2_fbc_10M.csv"
	"tractography/connectomes/Schaefer7n1000p+Tian_Subcortex_S4_3T/connectome_mean_FA_10M.csv"
	"tractography/connectomes/Schaefer7n1000p+Tian_Subcortex_S4_3T/connectome_streamline_count_10M.csv"

	"tractography/connectomes/aparc+Tian_Subcortex_S1_3T/connectome_mean_length_10M.csv"
	"tractography/connectomes/aparc+Tian_Subcortex_S1_3T/connectome_sift2_fbc_10M.csv"
	"tractography/connectomes/aparc+Tian_Subcortex_S1_3T/connectome_mean_FA_10M.csv"
	"tractography/connectomes/aparc+Tian_Subcortex_S1_3T/connectome_streamline_count_10M.csv"
	# atlases
	"tractography/atlases/native.dMRI_space.Tian_Subcortex_S1_3T.nii.gz"
	"tractography/atlases/native.dMRI_space.Schaefer7n200p.nii.gz"
	"tractography/atlases/native.dMRI_space.Tian_Subcortex_S4_3T.nii.gz"
	"tractography/atlases/native.dMRI_space.Glasser.nii.gz"
	"tractography/atlases/native.dMRI_space.Schaefer7n500p.nii.gz"
	"tractography/atlases/native.dMRI_space.aparc.nii.gz"
	"tractography/atlases/native.dMRI_space.aparc.a2009s.nii.gz"
	"tractography/atlases/native.dMRI_space.Schaefer7n1000p.nii.gz"
)

echo ${files[*]}
