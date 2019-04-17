#!/bin/bash
#SBATCH --job-name=rm_temp
#SBATCH --time=0:10:00
#SBATCH --partition=mono,dpnc,mono-shared
#SBATCH --output=batch_output/rm_temp-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=1G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4
source /home/reniery/cron/monitoring_setup.sh

echo "removing $@"
rm $@

echo "done"

