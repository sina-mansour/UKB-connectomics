# UK Biobank Connectomes Repository

Welcome to the UK Biobank Connectomes repository, a resource for the "Connectomes for 40,000 UK Biobank participants" project. This repository contains scripts and resources related to the project.

## Article Reference
- **Title:** Connectomes for 40,000 UK Biobank participants: A multi-modal, multi-scale brain network resource
- **Authors:** Mansour L, S., Di Biase, M. A., Smith, R. E., Zalesky, A., & Seguin, C.
- **Year:** 2023
- **Preprint:** [bioRxiv](https://doi.org/10.1101/2023.03.10.532036) [![DOI:10.1101/2023.03.10.532036](http://img.shields.io/badge/DOI-10.1101/2023.03.10.532036-B31B1B.svg)](https://doi.org/10.1101/2023.03.10.532036)

> **Citation:**
> Mansour L, S., Di Biase, M. A., Smith, R. E., Zalesky, A., & Seguin, C. (2023). Connectomes for 40,000 UK Biobank participants: A multi-modal, multi-scale brain network resource. *bioRxiv*, 2023-03.

## Repository Sections

### Connectivity Mapping Pipeline
- An automation SLURM pipeline to carry out the connectome mapping pipeline for UK Biobank imaging sessions from start to finish. [Explore the pipeline script](https://github.com/sina-mansour/UKB-connectomics/blob/main/scripts/bash/smart_zip_run_automization.sh).

### Individual Parcellations and Connectomes
- A complete pipeline to map individual parcellations, functional time series, and structural connectomes for a single imaging session, implemented as an embarrassingly parallel workload. [Access the pipeline script](https://github.com/sina-mansour/UKB-connectomics/blob/main/scripts/bash/UKB_connectivity_mapping_pipeline.sh).

### Tractography Pipeline
- Inspect the tractography pipeline script: [Tractography Script](https://github.com/sina-mansour/UKB-connectomics/blob/main/scripts/bash/probabilistic_tractography_native_space.sh). Note that our scripts uses [new MRtrix features](https://github.com/orgs/MRtrix3/projects/5/views/1) that were implemented to address computational demands of this project. You can use the exact same version of MRtrix3 as used by our pipeline via building the source code as detailed [here](https://github.com/sina-mansour/UKB-connectomics/blob/main/scripts/bash/mrtrix_installation.sh).

### Connectivity matrices from streamlines
- A collection of [bash](https://github.com/sina-mansour/UKB-connectomics/blob/main/scripts/bash/map_structural_connectivity.sh), [Matlab](https://github.com/sina-mansour/UKB-connectomics/blob/main/scripts/matlab/tck2connectome.m), and [Python](https://github.com/sina-mansour/UKB-connectomics/blob/main/scripts/python/tck2connectome.py) scripts for generating approximately 1000 alternative connectomes using various parcellations and connectivity metrics, complementing the pre-computed connectomes.

### Additional Scripts
- All pipeline scripts are made publicly available in this repository. [View additional scripts](https://github.com/sina-mansour/UKB-connectomics/tree/main/scripts).


---

### Software dependencies:

The connectivity mapping pipeline makes use of the following software packages:

- [**FreeSurfer**](https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurfer): version 7.1.1
- [**FSL**](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki): version 6.0.3
- [**MRtrix3**](https://www.mrtrix.org/): Built from source ([commit `eeab681`](https://github.com/MRtrix3/mrtrix3/commit/eeab681), see [this](https://github.com/sina-mansour/UKB-connectomics/blob/main/scripts/bash/mrtrix_installation.sh))

The following Python packages were additionally utilized:
- [**NumPy**](https://numpy.org/)
- [**SciPy**](https://scipy.org/)
- [**Pandas**](https://pandas.pydata.org/)
- [**NiBabel**](https://nipy.org/nibabel/gettingstarted.html)

---

Feel free to explore and utilize these resources for your research projects. If you have any questions or need assistance, please don't hesitate to reach out.

[![sina \[dot\] mansour \[dot\] lakouraj \[at\] gmail](https://img.shields.io/badge/Contact-sina%20[dot]%20mansour%20[dot]%20lakouraj%20[at]%20gmail-blue)](https://sina-mansour.github.io/)
