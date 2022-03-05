#!/bin/bash

# This script was used to install the UKB-specific release branch of mrtrix software:
# https://github.com/MRtrix3/mrtrix3/tree/ukb
#

# some colors for fancy logging :D
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

UKB_DIR="$(dirname "$(dirname "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )")")"
install_dir="${UKB_DIR}/lib"

cd $install_dir

if [ -d "${install_dir}/mrtrix3" ]; then
	echo -e "${GREEN}[INFO]${NC} `date`: Removing directory for a fresh install"
	rm -rf "${install_dir}/mrtrix3"
fi

# dependencies
# sudo apt-get install git g++ python libeigen3-dev zlib1g-dev libqt5opengl5-dev libqt5svg5-dev libgl1-mesa-dev libfftw3-dev libtiff5-dev libpng-dev

# clone repository
echo -e "${GREEN}[INFO]${NC} `date`: Cloning mrtrix3 repository"
git clone https://github.com/MRtrix3/mrtrix3.git

# configuration
echo -e "${GREEN}[INFO]${NC} `date`: Configuring the ukb release"
cd mrtrix3
git checkout ukb
./configure
# on spartan:
# ./configure -static -nogui
# see https://mrtrix.readthedocs.io/en/3.0_rc3/installation/linux_install.html#static-build

# building binaries
echo -e "${GREEN}[INFO]${NC} `date`: Building the binaries"
./build