#!/bin/bash
#SBATCH --job-name=hillas_compute
#SBATCH --time=8:00:00
#SBATCH --partition=mono,dpnc
#SBATCH --output=batch_output/hillas_compute-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=4G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4

# we remove arguments after reading them to only keep the list of files at the end
run=$1
shift
dark_file=$1
shift
param_file=$1
shift
output_file=$1
shift
files=$@

echo "run: $run"
echo "dark_file: $dark_file"
echo "param_file: $param_file"
echo "output_file: $output_file"
echo "files: $files"

if [ -z "$files" ]; then
    echo "no file to analyze !, exiting..."
    exit
fi

cd /home/reniery/ctasoft/digicampipe/

python -u digicampipe/scripts/pipeline.py -o ${output_file} --dark ${dark_file} --parameters=${param_file} -c ${files} 


