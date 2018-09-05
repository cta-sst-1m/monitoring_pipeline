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

year=""
month=""
day=""
if [[ $# == 0 ]]; then
    year=$(ls /sst1m/raw/ -t| head -n 1);
    year_dir="/sst1m/raw/${year}/";
    month=$(ls ${year_dir} -t| head -n 1);
    month_dir="${year_dir}$month/";
    day=$(ls ${month_dir} -t | head -n 1);
    day_dir="${month_dir}$day/";
    files_dir="${day_dir}$(ls ${day_dir} -t| head -n 1)/";
    echo "no path given, using last directory: ${files_dir}";
elif [[ $# == 1 ]]; then
    files_dir=$1;
    #keep only the part with the date
    date_dir=$(echo $files_dir | sed 's|.*/\(20[0-9]\{2\}/[0-9]\{2\}/[0-9]\{2\}\)/\?.*|\1|' | tr -s '/' ' ');
    read -r -a array <<< "${date_dir}";
    year=${array[0]};
    month=${array[1]};
    day=${array[2]};
    echo "extracting date form path $files_dir";
    echo "year: $year";
    echo "month: $month";
    echo "day: $day";
else
    echo "error: $# arguments";
    echo "usage: $0 path_to_zfits";
    exit;
fi

raw_files=$(find ${files_dir}* | grep ".fits.fz" |sort);

dest_dir="/home/reniery/cron/${year}/${month}/${day}";
mkdir -p ${dest_dir}/batch_output;

cd ${dest_dir};
runs=$(python /home/reniery/cron/get_runs.py ${raw_files});

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
    sbatch /home/reniery/cron/launch_data_quality.sbatch ${run} ${dark_file} ${output_fits} ${output_hist} ${rate_plot} ${baseline_plot} ${time_step} ${param_file} ${files};
   
    # trigger uniformity
    echo "runing trigger uniformity"
    uniformity_plot="${dest_dir}/trigger_uniformity_${year}_${month}_${day}_run${run}.png";
    sbatch /home/reniery/cron/launch_trigger_uniformity.sbatch ${uniformity_plot} ${files};

    # analyze data
    echo "running pipeline";
    output_file="${dest_dir}/hillas_${year}_${month}_${day}_run${run}.fits";
    sbatch /home/reniery/cron/launch_analyze_run.sbatch ${run} ${dark_file} ${param_file} ${output_file} ${files};

    echo "${run} ${dark_file} ${param_file} ${output_file} ${files}">>${dest_dir}/runs.txt;
done <<< "$runs"

# trigger uniformity for all data files
echo "runing trigger uniformity for all shift: $all_files";
uniformity_plot="${dest_dir}/trigger_uniformity_${year}_${month}_${day}_all.png";
sbatch /home/reniery/cron/launch_trigger_uniformity.sbatch ${uniformity_plot} ${all_files};
