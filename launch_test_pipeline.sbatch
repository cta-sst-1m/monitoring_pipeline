#!/bin/bash
#SBATCH --job-name=test_pipeline
#SBATCH --time=8:00:00
#SBATCH --partition=mono,dpnc
#SBATCH --output=slurm-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=10G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4

dark_file=$1
shift
param_file=$1
shift
output_file=$1
shift
files=$@

echo "dark_file: $dark_file"
echo "param_file: $param_file"
echo "output_file: $output_file"
echo "files: $files"

if [ -z "$files" ]; then
    echo "no file to analyze !, exiting..."
    exit
fi

cd /home/reniery/ctasoft/digicampipe/

python -u digicampipe/scripts/pipeline.py -o ~/cron --dark ${dark_file} -c ${files} --parameters=${param_file}
mv ~/cron/hillas.fits ${output_file}

