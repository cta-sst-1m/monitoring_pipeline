#!/bin/bash
# script to extract date from given data path. 
# If no argument is given, the last data folder is chosen

source /home/reniery/cron/monitoring_setup.sh

year=""
month=""
day=""
if [[ $# == 0 ]]; then
    year=$(ls ${default_data_dir} -t|grep 20| head -n 1);
    year_dir="${default_data_dir}/${year}/";
    month=$(ls ${year_dir} -t| head -n 1);
    month_dir="${year_dir}$month/";
    day=$(ls ${month_dir} -t | head -n 1);
    day_dir="${month_dir}$day/";
    files_dir="${day_dir}$(ls ${day_dir} -t| head -n 1)/";
    auxfiles_dir="$(ls ${default_aux_dir}/${year}/$month/$day/ -t| head -n 1)/"
    aux_dir="${default_aux_dir}/${year}/$month/$day/$auxfiles_dir"
    echo "no path given, using last directory: ${files_dir}";
elif [[ $# == 1 ]]; then
    files_dir=$1;
    #keep only the part with the date
    date_dir=$(echo $files_dir | sed 's|.*/\(20[0-9]\{2\}/[0-9]\{2\}/[0-9]\{2\}\)/\?.*|\1|' | tr -s '/' ' ');
    read -r -a array <<< "${date_dir}";
    year=${array[0]};
    month=${array[1]};
    day=${array[2]};
    auxfiles_dir="$(ls ${default_aux_dir}/${year}/$month/$day/ -t| head -n 1)/"
    aux_dir="${default_aux_dir}/${year}/$month/$day/$auxfiles_dir"
    echo "extracting date form path $files_dir";
    echo "year: $year";
    echo "month: $month";
    echo "day: $day";
else
    echo "error: $# arguments";
    echo "usage: $0 path_to_zfits";
    exit;
fi
echo "using ${aux_dir} as slow data directory: ";
export year
export mounth
export day
export files_dir
export aux_dir
