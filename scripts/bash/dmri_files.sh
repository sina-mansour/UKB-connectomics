#!/bin/bash

main_dir=$1
ukb_subjects_dir=$2
ukb_subject_id=$3
ukb_instance=$4

script_dir="${main_dir}/scripts"
template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"
output_dir="${main_dir}/data/output"

files=(
	# Cortical fMRI files
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Glasser.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n100p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n200p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n300p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n400p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n500p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n600p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n700p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n800p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n900p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer7n1000p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n100p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n200p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n300p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n400p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n500p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n600p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n700p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n800p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n900p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Schaefer17n1000p.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.aparc.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.aparc.a2009s.csv.gz"
	# Subcortical fMRI files
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Tian_Subcortex_S1_3T.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Tian_Subcortex_S2_3T.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Tian_Subcortex_S3_3T.csv.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Tian_Subcortex_S4_3T.csv.gz"
	# Global signal fMRI file
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/fMRI/fMRI.Tian_Subcortex_S1_3T.csv.gz"

	# stats
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/stats/sift_stats.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/stats/tracks_10M_stats.json"
	# per-streamline metrics
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_NODDI_ICVF_mean.npy"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_0.001xS0_mean.npy"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_FA_mean.npy"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/sift_weights.npy"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_length.npy"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_MO_mean.npy"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_1000xMD_mean.npy"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_NODDI_OD_mean.npy"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_NODDI_ISOVF_mean.npy"
	# endpoints
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/endpoints/tracks_10M_endpoints.npy"
	# connectomes
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n200p+Tian_Subcortex_S1_3T/connectome_mean_length_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n200p+Tian_Subcortex_S1_3T/connectome_sift2_fbc_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n200p+Tian_Subcortex_S1_3T/connectome_mean_FA_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n200p+Tian_Subcortex_S1_3T/connectome_streamline_count_10M.csv"

	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Glasser+Tian_Subcortex_S1_3T/connectome_mean_length_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Glasser+Tian_Subcortex_S1_3T/connectome_sift2_fbc_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Glasser+Tian_Subcortex_S1_3T/connectome_mean_FA_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Glasser+Tian_Subcortex_S1_3T/connectome_streamline_count_10M.csv"

	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/aparc.a2009s+Tian_Subcortex_S1_3T/connectome_mean_length_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/aparc.a2009s+Tian_Subcortex_S1_3T/connectome_sift2_fbc_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/aparc.a2009s+Tian_Subcortex_S1_3T/connectome_mean_FA_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/aparc.a2009s+Tian_Subcortex_S1_3T/connectome_streamline_count_10M.csv"

	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n500p+Tian_Subcortex_S4_3T/connectome_mean_length_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n500p+Tian_Subcortex_S4_3T/connectome_sift2_fbc_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n500p+Tian_Subcortex_S4_3T/connectome_mean_FA_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n500p+Tian_Subcortex_S4_3T/connectome_streamline_count_10M.csv"

	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Glasser+Tian_Subcortex_S4_3T/connectome_mean_length_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Glasser+Tian_Subcortex_S4_3T/connectome_sift2_fbc_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Glasser+Tian_Subcortex_S4_3T/connectome_mean_FA_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Glasser+Tian_Subcortex_S4_3T/connectome_streamline_count_10M.csv"

	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n1000p+Tian_Subcortex_S4_3T/connectome_mean_length_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n1000p+Tian_Subcortex_S4_3T/connectome_sift2_fbc_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n1000p+Tian_Subcortex_S4_3T/connectome_mean_FA_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/Schaefer7n1000p+Tian_Subcortex_S4_3T/connectome_streamline_count_10M.csv"

	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/aparc+Tian_Subcortex_S1_3T/connectome_mean_length_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/aparc+Tian_Subcortex_S1_3T/connectome_sift2_fbc_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/aparc+Tian_Subcortex_S1_3T/connectome_mean_FA_10M.csv"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/aparc+Tian_Subcortex_S1_3T/connectome_streamline_count_10M.csv"
	# atlases
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.Tian_Subcortex_S1_3T.nii.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.Schaefer7n200p.nii.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.Tian_Subcortex_S4_3T.nii.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.Glasser.nii.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.Schaefer7n500p.nii.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.aparc.nii.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.aparc.a2009s.nii.gz"
	"${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.Schaefer7n1000p.nii.gz"

)

echo ${files[*]}
