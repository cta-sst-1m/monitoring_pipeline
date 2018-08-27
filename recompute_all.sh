#!/bin/bash
#SBATCH --job-name=test_pipeline
#SBATCH --time=8:00:00
#SBATCH --partition=mono,dpnc
#SBATCH --output=slurm-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=10G
#find all existing data and process them all.

#-links 2 filters for those that have two (hard) links to their name. Only match deepest directory (containing . and ..)
days_data=$(find /sst1m/raw/2018/ -type d -links 2)

for day in ${days_data}; do
    /home/reniery/cron/test_pipeline.sh $day
done
