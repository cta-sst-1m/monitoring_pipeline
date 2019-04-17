#!/bin/bash
#SBATCH --job-name=hillas_concatenate
#SBATCH --time=1:00:00
#SBATCH --partition=mono,dpnc,mono-shared
#SBATCH --output=batch_output/hillas_concatenate-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=2G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4
source /home/reniery/cron/monitoring_setup.sh

# we remove arguments after reading them to only keep the list of intermaediate files at the end
output_file=$1
shift
intermediate_outpouts=$@

echo "create $output_file from $intermediate_outpouts"
cd ${digicampipe_dir}
python -u $digicampipe_dir/digicampipe/scripts/concatenate.py $output_file $intermediate_outpouts

echo "done"
if [ -f ${output_file} ]; then
    exit 0
else
    exit -1
fi
