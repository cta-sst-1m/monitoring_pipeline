#!/bin/bash
#SBATCH --job-name=test_pipeline
#SBATCH --time=2:00:00
#SBATCH --partition=mono,dpnc
#SBATCH --output=batch_output/test_pipeline-%J.out
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

dest_dir="${monitoring_dir}/${year}/${month}/${day}";
mkdir -p ${dest_dir}/batch_output;

cd ${dest_dir};
echo "analyzing zfits headers to get the type of runs and sources"
runs=$(python ${monitoring_dir}/get_runs.py ${raw_files});

run=0
echo "#run_idx dark_file param_file analyze_log output_dir files"> ${dest_dir}/runs.txt
if [ ! -e ${dest_dir}/dark_runs.txt ] ;then
    echo "#input_files dark_file"> ${dest_dir}/dark_runs.txt; 
fi
param_file="digicampipe/tests/resources/calibration_20180814.yml";
all_files="";
while read -r line; do
    run=$((run+1));
    IFS=',' read -r -a array <<< "${line}";
    dark=${array[0]};
    files=${array[1]};
    all_files="${all_files} ${files}";
    echo "!!! RUN $run !!!";
    echo "dark files: $dark";
    echo "science files: $files";
    if [ -z "$files" ]; then
        echo "no file to analyze !, passing run $run";
        continue;
    fi
    if [ -z "$(grep $dark ${dest_dir}/dark_runs.txt)" ]; then
        # analyze dark
        dark_file="${dest_dir}/raw_histo_${year}_${month}_${day}.pk";
        i=0;
        while [ -f ${dark_file} ]; do
            i=$((i+1));
            dark_file="$(echo ${dark_file}| sed 's|-[0-9]*\.pk$||'| sed 's|\.pk$||')-$i.pk";
        done
        echo "runnig dark analysis:";
        echo "digicam-raw -o ${dark_file} -c $dark";
        digicam-raw -o ${dark_file} -c $dark;
        if [ -f ${dark_file} ]; then
            echo "dark analysis is done";
        else
            echo "ERROR: output file ${dark_file} was not created. Exit";
            exit;
        fi
        echo "$dark $dark_file">> ${dest_dir}/dark_runs.txt
    else
        dark_file=$(grep $dark ${dest_dir}/dark_runs.txt| sed 's|.* \([^ ]*\)|\1|');
        echo "using $dark_file instead of analyzing dark";
    fi
    # data quality
    echo "runing data quality";
    output_fits="${dest_dir}/history_${year}_${month}_${day}_run${run}.fits";
    output_hist="${dest_dir}/histogram_${year}_${month}_${day}_run${run}.pk";
    rate_plot="${dest_dir}/rate_${year}_${month}_${day}_run${run}.png";
    baseline_plot="${dest_dir}/baseline_${year}_${month}_${day}_run${run}.png";
    time_step=1e9;
    sbatch ${monitoring_dir}/launch_data_quality.sbatch ${run} ${dark_file} ${output_fits} ${output_hist} ${rate_plot} ${baseline_plot} ${time_step} ${param_file} ${files};
   
    # trigger uniformity
    echo "runing trigger uniformity"
    uniformity_plot="${dest_dir}/trigger_uniformity_${year}_${month}_${day}_run${run}.png";
    sbatch ${monitoring_dir}/launch_trigger_uniformity.sbatch ${uniformity_plot} ${files};

    # analyze data
    echo "running pipeline";
    output_file="${dest_dir}/hillas_${year}_${month}_${day}_run${run}.fits";
    sbatch ${monitoring_dir}/launch_analyze_run.sbatch ${run} ${dark_file} ${param_file} ${output_file} ${files};

    echo "${run} ${dark_file} ${param_file} ${output_file} ${files}">>${dest_dir}/runs.txt;
done <<< "$runs"

if [[ $run > 1 ]]; then 
    # trigger uniformity for all data files
    echo "runing trigger uniformity for all shift: $all_files";
    uniformity_plot="${dest_dir}/trigger_uniformity_${year}_${month}_${day}_all.png";
    sbatch ${monitoring_dir}/launch_trigger_uniformity.sbatch ${uniformity_plot} ${all_files};
fi

#get bursts
echo "runing get burst on $files_dir folder"
sbatch ${monitoring_dir}/get_bursts.sh $files_dir
