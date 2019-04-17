#!/bin/bash
#find tail-cut thresholds and concatenate all hillas output for any of those thresholds.

source ./monitoring_setup.sh

basepath="${analyzed_dir}/2018/10"
output_basename="${basepath}/hillas_2018-10"
files=$(find $basepath -path "*/thr*/hillas_*.fits" | grep -v .old)
echo "found $(echo $files | wc -w) files."

#WARNING on directory where temporary files where not concatenated.
paths_bad_files=$(echo "$files" | grep -v _run | xargs -i dirname {}| sort | uniq )
echo $paths_bad_files
for path in ${paths_bad_files}; do
    echo "WARNING: unconcatenated runs found in $path"
done

#determine uniques thresholds
thresholds=$(echo "$files"|tr -s ' ' '\n' |sed 's/.*thr\([0-9]*-[0-9]*\).*/\1/g' | sort | uniq)
echo "found $(echo $thresholds | wc -w) thresholds."

#concatenate hillas file for each threshold
for thr in ${thresholds}; do
    files_thr=($(ls $files | grep /thr${thr}/))
    output_thr="${output_basename}_thr${thr}.fits.gz"
    echo "concatenate ${#files_thr[@]} files for threshold $thr ..."
    sbatch launch_concatenate.sbatch ${output_thr} ${files_thr[@]}
done
