#!/bin/bash
#SBATCH --job-name=clocked_histo
#SBATCH --time=8:00:00
#SBATCH --partition=mono,dpnc
#SBATCH --output=batch_output/clocked_histo-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=4G
# Cron job to analyze clocked trigger .
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
echo "analyzing zfits headers to get the type of runs and sources"
runs=$(python ${monitoring_dir}/get_runs.py ${raw_files});

run=0
param_file="digicampipe/tests/resources/calibration_20180814.yml";
all_files="";
while read -r line; do
    run=$((run+1));
    IFS=',' read -r -a array <<< "${line}";
    dark=${array[0]};
    files=${array[1]};
    all_files="${all_files} ${files}";
done <<< "$runs"

# create one histogram per science fits file
for input_file in $all_files; do
    input_base="${input_file##*/}";
    output_file="${dest_dir}/clocked_raw_${input_base%.fits.fz}.pk";
    if [ -e $output_file ]; then 
        echo "skiping $input_file as $output_file exists"
        continue;
    fi
    echo "runing digicam-raw on $input_file to create $output_file";
    digicam-raw -o ${output_file} --event_types=8 -c ${input_file};
done
