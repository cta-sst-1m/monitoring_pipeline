#!/bin/bash
#find all existing data and process them all. All data within the provided folder as argument will be analyzed.

source /home/reniery/cron/monitoring_setup.sh

if [[ $# == 0 ]]; then
    data_dir="${default_data_dir}/$(date +'%Y')/";
elif [[ $# == 1 ]]; then
    data_dir=$1;
else;
    echo "give a path that include the data to be analyzed as argument."
    return
fi

#-`links 2` filters for directories that have two (hard) links in them. It only matches the deepest directories (containing . and ..)
# tac (cat spelled backwards) reverse the order of the files
days_data=$(find  -type d -links 2| tac)

for day in ${days_data}; do
    sbatch ${monitoring_dir}/test_pipeline.sh $day
done
