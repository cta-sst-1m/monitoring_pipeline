#!/bin/bash
#SBATCH --job-name=bursts
#SBATCH --time=12:00:00
#SBATCH --partition=mono,dpnc
#SBATCH --output=batch_output/bursts-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=2G
# Cron job to pre-analyse and check quality of a night data.
# if no argument is given, default to the last night observed, otherwise it expects 1 argument: the directory containing the fits.fz files to be analyzed.


source /etc/profile.d/z00_lmod.sh
module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4

# get path of the monitoring pipeline, data location and digicampipe
source /home/reniery/cron/monitoring_setup.sh

#get date and data path 
. ${monitoring_dir}/get_data_dir.sh $@ 

raw_files=$(find ${files_dir}* | grep ".fits.fz" |sort);

dest_dir="${analyzed_dir}/${year}/${month}/${day}";
mkdir -p ${dest_dir}/batch_output;

cd ${dest_dir};
runs=$(python ${monitoring_dir}/get_runs.py ${raw_files});

run=0
all_files="";
while read -r line; do
    run=$((run+1));
    IFS=',' read -r -a array <<< "${line}";
    dark=${array[0]};
    files=${array[1]};
    all_files="${all_files} ${files}";
done <<< "$runs"

# data quality for all data files
echo "runing get_bursts";
cd ${digicampipe_dir};
plot_baseline="${dest_dir}/baseline_${year}${month}${day}_all.png"
output_file="${dest_dir}/bursts_${year}${month}${day}.txt"
video_prefix="${dest_dir}/burst_${year}${month}${day}"
#python digicampipe/scripts/get_burst.py --threshold_lsb=10.0 --plot_baseline=${plot_baseline} --output=${output_file} --video_prefix=${video_prefix} ${all_files};
python digicampipe/scripts/get_burst.py --threshold_lsb=10.0 --plot_baseline=${plot_baseline} --output=${output_file} --video_prefix=none --disable_bar ${all_files};
echo "done"
