#!/bin/bash

#SBATCH --job-name=launch_simulation
#SBATCH --output=launch_simulation.out
#SBATCH --partition=s_standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=36
#SBATCH --mem=4G

set -e

BuildDirectory="/home/$USER/tsunami/Tsunami-Simulation/build"
ScriptDirectory="/home/$USER/tsunami/Tsunami-Simulation"

# Loading cmake to launch this task
echo "Loading needed modules"
module load tools/cmake/3.22.2
module load libs/netcdf/4.6.1-gcc-7.3.0
module load compiler/gcc/11.2.0
module load compiler/intel/2020-Update2


# Cleaning up Build Directory
echo "Cleaning up Build Directory"
rm -rf "$BuildDirectory"
mkdir "$BuildDirectory"
cd "$BuildDirectory"

# Setting up cmake
echo "Setting up cmake"
# intel compiler can only be used without io
#CC="/cluster/intel/parallel_studio_xe_2020.2.108/compilers_and_libraries_2020/linux/bin/intel64/icc" \
#CXX="/cluster/intel/parallel_studio_xe_2020.2.108/compilers_and_libraries_2020/linux/bin/intel64/icpc" \
# Options: -D REPORT=ON
cmake .. -DCMAKE_BUILD_TYPE=Release

# Compiling c++
# Options:
#   --config: Release, Debug
#   --target: simulation, sanitize, test, sanitize_test, test_middle_states
echo "Building the project"
cmake --build . --target simulation -j 36

#creating ouput directory
directory=/beegfs/$USER/$(date +"%F_%H-%M")
mkdir $directory

# Coping requiered resources for this job
echo "Copying files to $directory"
cp simulation $directory/simulation
mkdir $directory/resources
cp -R resources/* $directory/resources/

echo "Launching the job"
sbatch -D "$directory" "$ScriptDirectory"/simulation.sh
