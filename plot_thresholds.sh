#!/bin/bash
#find tail-cut thresholds and concatenate all hillas output for any of those thresholds.

source ./monitoring_setup.sh

basepath="${analyzed_dir}/2018/10"
data_description="2018-10"
files=$(ls $basepath/hillas_*thr*.fits.gz | sort)
#determine uniques thresholds

thresholds=$(echo "$files"|tr -s ' ' '\n' |sed 's/.*thr\([0-9]*-[0-9]*\).*/\1/g' | sort  | tac | uniq)

#concatenate hillas file for each threshold
for thr in ${thresholds}; do
    file_thr=($(ls $files | grep "thr${thr}"))
    if [ ${#file_thr[@]} -gt 1 ]; then 
        echo "ERROR more than one file found (${file_thr[@]}) for thr${thresholds}, skipped";
        continue
    fi
    scan2d_thr="${basepath}/2dscan_${data_description}_thr${thr}.png"
    disp_thr="${basepath}/disp_${data_description}_thr${thr}.png"
    shower_center="${basepath}/shower-center_${data_description}_thr${thr}.png"
    hillas_plot="${basepath}/hillas_${data_description}_thr${thr}.png"
    corel_all_plot="${basepath}/corel-all_${data_description}_thr${thr}.png"
    corel_sel_plot="${basepath}/corel-sel_${data_description}_thr${thr}.png"
    echo "plotting for threshold $thr ..."
    null=/dev/null
    sbatch ${monitoring_dir}/launch_plot_pipeline.sbatch ${file_thr} ${scan2d_thr} ${shower_center} ${hillas_plot} ${corel_all_plot} ${corel_sel_plot} ${disp_thr}
    sleep 0.1
done
