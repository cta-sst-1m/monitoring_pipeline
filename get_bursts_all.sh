#!/bin/bash
#find all existing data and process them all.

#-`links 2` filters for directories that have two (hard) links in them. It only matches the deepest directories (containing . and ..)
# tac (cat spelled backwards) reverse the order of the files
days_data=$(find /sst1m/raw/2018/ -type d -links 2| tac)

for day in ${days_data}; do
    sbatch /home/reniery/cron/get_bursts.sh $day
done
