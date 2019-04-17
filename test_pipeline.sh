#!/bin/bash
#SBATCH --job-name=test_pipeline
#SBATCH --time=0:15:00
#SBATCH --partition=mono,dpnc,mono-shared,debug
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

dest_dir="${analyzed_dir}/${year}/${month}/${day}";
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
    printf -v run_txt "%03d" $run
    IFS=',' read -r -a array <<< "${line}";
    dark=${array[0]};
    files=${array[1]};
    all_files="${all_files} ${files}";
    echo "!!! RUN $run_txt !!!";
    echo "dark files: $dark";
    echo "science files: $files";
    if [ -z "$files" ]; then
        echo "no file to analyze !, passing run $run_txt";
        continue;
    fi
    if [ -z "$(grep $dark ${dest_dir}/dark_runs.txt)" ]; then
        # register dark run
        echo "did not find dark histogram for: $dark"
        dark_file="${dest_dir}/raw_histo_${year}_${month}_${day}.pk";
        i=0;
        while [ -n "$(grep $dark_file ${dest_dir}/dark_runs.txt)" ]; do
            i=$((i+1));
            dark_file="$(echo ${dark_file}| sed 's|-[0-9]*\.pk$||'| sed 's|\.pk$||')-$i.pk";
        done
        echo "$dark $dark_file">> ${dest_dir}/dark_runs.txt
    else
        dark_file=$(grep $dark ${dest_dir}/dark_runs.txt| sed 's|.* \([^ ]*\)|\1|');
        echo "find $dark_file for: $dark"
    fi
    if [[ ! -f $dark_file ]]; then
        echo "did not find $dark_file, dark_file of the previous run: '$dark_file_run'"
        if [[ $dark_file_run != $dark_file ]]; then
            # analyze dark run
            echo "runnig dark analysis:";
            dark_run=$(sbatch --parsable  ${monitoring_dir}/launch_dark_run.sbatch ${dark_file} ${dark});
            echo "Submitted batch job ${dark_run}";
            dark_file_run=${dark_file}
        else
            echo "dark analysis for $dark_file already running as job ${dark_run}";
        fi
        dark_run_dep="--dependency=afterok:${dark_run}"
    else
        dark_run_dep=""
        echo "using $dark_file instead of analyzing dark";
    fi
    # data quality
    echo "runing data quality";
    output_fits="${dest_dir}/history_${year}_${month}_${day}_run${run_txt}.fits";
    output_hist="${dest_dir}/histogram_${year}_${month}_${day}_run${run_txt}.pk";
    rate_plot="${dest_dir}/rate_${year}_${month}_${day}_run${run_txt}.png";
    baseline_plot="${dest_dir}/baseline_${year}_${month}_${day}_run${run_txt}.png";
    time_step=1e9;
    sbatch ${dark_run_dep} ${monitoring_dir}/launch_data_quality.sbatch ${run_txt} ${dark_file} ${output_fits} ${output_hist} ${rate_plot} ${baseline_plot} ${time_step} ${param_file} ${aux_dir} ${files};
   
    # trigger uniformity
    echo "runing trigger uniformity"
    uniformity_plot="${dest_dir}/trigger_uniformity_${year}_${month}_${day}_run${run_txt}.png";
    sbatch ${monitoring_dir}/launch_trigger_uniformity.sbatch ${uniformity_plot} ${files};

    # analyze data
    echo "running pipeline";
    for thr1 in $(seq 20 5 30); do
        for thr2 in $(seq 10 5 $thr1); do
            mkdir -p "${dest_dir}/thr${thr1}-${thr2}"
            output_file="${dest_dir}/thr${thr1}-${thr2}/hillas_${year}_${month}_${day}_run${run_txt}.fits";
            events_example_file="${dest_dir}/thr${thr1}-${thr2}/examples_${year}_${month}_${day}_run${run_txt}.png";
            sbatch ${dark_run_dep} ${monitoring_dir}/launch_pipeline.sbatch ${run_txt} ${dark_file} ${param_file} ${output_file} $thr1 $thr2 ${events_example_file} ${files};
        done
    done
    echo "${run_txt} ${dark_file} ${param_file} ${output_file} ${files}">>${dest_dir}/runs.txt;
done <<< "$runs"

if [[ $run > 1 ]]; then 
    # trigger uniformity for all data files
    echo "runing trigger uniformity for all shift: $all_files";
    uniformity_plot="${dest_dir}/trigger_uniformity_${year}_${month}_${day}_all.png";
    sbatch ${monitoring_dir}/launch_trigger_uniformity.sbatch ${uniformity_plot} ${all_files};
    sleep 0.1
fi

#get bursts
echo "runing get burst on $files_dir folder:"
sbatch ${monitoring_dir}/get_bursts.sh $files_dir

echo "done"
