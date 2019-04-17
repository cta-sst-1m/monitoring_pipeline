#!/bin/bash
#SBATCH --job-name=dark_run
#SBATCH --time=1:00:00
#SBATCH --partition=mono,dpnc,mono-shared
#SBATCH --output=batch_output/dark_run-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=2G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4
source /home/reniery/cron/monitoring_setup.sh

# we remove arguments after reading them to only keep the list of input files at the end
dark_file=$1
shift
input_files=$@

cd $digicampipe_dir
python -u $digicampipe_dir/digicampipe/scripts/raw.py -o ${dark_file} --disable_bar -c ${input_files}

echo "done"
if [ -f ${dark_file} ]; then
    exit 0
else
    exit -1
fi
