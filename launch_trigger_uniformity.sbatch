#!/bin/bash
#SBATCH --job-name=trigger_uniformity
#SBATCH --time=12:00:00
#SBATCH --partition=mono,dpnc
#SBATCH --output=batch_output/trigger_uniformity-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=2G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4

# get path of the monitoring pipeline, data location and digicampipe
source /home/reniery/cron/monitoring_setup.sh

# we remove arguments after reading them to only keep the list of files at the end
uniformity_plot=$1
shift
files=$@

echo "uniformity_plot: ${uniformity_plot}"
echo "files: $files"

if [ -z "$files" ]; then
    echo "no file to analyze !, exiting..."
    exit
fi

cd ${digicampipe_dir}

echo "python -u digicampipe/scripts/trigger_uniformity.py --plot=${uniformity_plot} --disable_bar ${files}"

python -u digicampipe/scripts/trigger_uniformity.py --plot=${uniformity_plot} --disable_bar ${files}

echo "done"
