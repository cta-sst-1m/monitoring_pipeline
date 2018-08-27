#!/bin/bash
#Cron job to pre-analyse and check quality of last night data.

year=""
month=""
day=""
if [[ $# == 0 ]]; then
    year=$(ls /sst1m/raw/ -t| head -n 1)
    year_dir="/sst1m/raw/${year}/"
    month=$(ls ${year_dir} -t| head -n 1)
    month_dir="${year_dir}$month/"
    day=$(ls ${month_dir} -t | head -n 1)
    day_dir="${month_dir}$day/"
    files_dir="${day_dir}$(ls ${day_dir} -t| head -n 1)/"
    echo "no path given, using last directory: ${files_dir}"
elif [[ $# == 1 ]]; then
    files_dir=$1
    #keep only the part with the date
    date_dir=$(echo $files_dir | sed 's|.*/\(20[0-9]\{2\}/[0-9]\{2\}/[0-9]\{2\}\)/\?.*|\1|' | tr -s '/' ' ')
    read -r -a array <<< "${date_dir}"
    year=${array[0]}
    month=${array[1]}
    day=${array[2]}
    echo "extracting date form path $files_dir"
    echo "year: $year"
    echo "month: $month"
    echo "day: $day"
else
    echo "error: $# arguments"
    echo "usage: $0 path_to_zfits"
    exit
fi

raw_files=$(find ${files_dir}*)

dest_dir="/home/reniery/cron/${year}/${month}/${day}"
mkdir -p ${dest_dir}
cd  ${dest_dir}
runs=$(python /home/reniery/cron/get_runs.sh ${raw_files})

run=0
last_dark="None";
echo "#dark_file param_file analyze_log output_file files"> runs.txt
while read -r line; do
    run=$((run+1))
    IFS=', ' read -r -a array <<< "${line}"
    dark=${array[0]}
    files=${array[@]:1:1000}
    if [ -z "$files" ]; then
        echo "no file to analyze !, passing run $run"
        continue
    fi
    if [[ "$dark" != "$last_dark" ]]; then
        # analyze dark
        dark_file="${dest_dir}/raw_histo_${year}_${month}_${day}.pk"
        i=0
        while [ -f ${dark_file} ]; do
            i=$((i+1))
            dark_file="$(echo ${dark_file}| sed 's|-[0-9]*\.pk$||'| sed 's|\.pk$||')-$i.pk"
        done
        rm -f $dest_dir/raw_histo.pk
        echo "runnig dark analysis on ${dark}: digicam-raw -o $dest_dir -c $dark"
        digicam-raw -o $dest_dir -c $dark
        last_dark=$dark
        mv $dest_dir/raw_histo.pk ${dark_file}
        echo "$dark_file created from $dark"
    else
        #get last file
        while [ -f ${dark_file} ]; do
            last=$dark_file
            i=$((i+1))
            dark_file="$(echo ${dark_file}| sed 's|-[0-9]*\.pk$||'| sed 's|\.pk$||')-$i.pk"
        done
        dark_file=$last
    fi
    # analyze data
    echo "analyzing $files"
    output_file="${dest_dir}/hillas_${year}_${month}_${day}-run${run}.fits"
    param_file="digicampipe/tests/resources/calibration_20180814.yml"
    
    sbatch /home/reniery/cron/launch_test_pipeline.sbatch ${dark_file} ${param_file} ${analyze_log} ${output_file} ${files}
    echo "run $run launched."
    echo " ${dark_file} ${param_file} ${output_file} ${files}">>runs.txt
done <<< "$runs"

