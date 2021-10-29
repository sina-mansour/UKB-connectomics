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
)

echo ${files[*]}
