#!/bin/bash
#SBATCH --job-name=hillas_launch
#SBATCH --time=0:15:00
#SBATCH --partition=mono,dpnc,mono-shared,debug
#SBATCH --output=batch_output/hillas_launch-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=1G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4
source /home/reniery/cron/monitoring_setup.sh

# we remove arguments after reading them to only keep the list of files at the end
run=$1
shift
dark_file=$1
shift
param_file=$1
shift
output_file=$1
shift
thr1=$1
shift
thr2=$1
shift
events_example_file=$1
shift
window_correction=$1
shift
files=$@
template_file="digicampipe/tests/resources/pulse_SST-1M_pixel_0.dat"

echo "run: $run"
echo "dark_file: $dark_file"
echo "param_file: $param_file"
echo "output_file: $output_file"
echo "picture_threshold: $thr1"
echo "boundary_threshold: $thr2"
echo "events_example_file: $events_example_file"
echo "files: $files"

if [ ! -f ${dark_file} ]; then
    echo "ERROR: dark file ${dark_file} do not exist. Exit";
    exit;
fi
if [ -z "$files" ]; then
    echo "no file to analyze !, exiting..."
    exit
fi

output_dir=${output_file%/*}
n_file=$(echo $files| wc -w)

echo "launching jobs to calculate Hillas parameters:"
if (( $n_file > 1)); then
    # analyse each zfit file independantly
    runs=""
    intermediate_outpouts=""
    for file in $files; do
        filename=${file##*/}
        filename_nogz=${filename%.fz}
        filename_noext=${filename_nogz%.fits}
        out="${output_dir}/hillas_${filename_noext}.fits"
        echo "compute hillas for $file:"
        hillas_run=$(sbatch --parsable ${monitoring_dir}/launch_analyze_run.sbatch $run $dark_file $param_file $out $thr1 $thr2 ${events_example_file} ${window_correction} $file);
        # show example only for first file
        events_example_file="none"
        echo "Submitted batch job ${hillas_run}"
        if [ -z $runs ]; then
            runs="$hillas_run";
        else
            runs="$runs,$hillas_run";
        fi
        intermediate_outpouts="${intermediate_outpouts} $out"
        sleep 0.1
    done
    # concatenate them to get the final output file
    echo "create $output_file from $intermediate_outpouts with --dependency=afterany:${runs}"
    final_hillas_run=$(sbatch --parsable --dependency=afterany:${runs} ${monitoring_dir}/launch_concatenate.sbatch $output_file $intermediate_outpouts)
    echo "Submitted batch job ${final_hillas_run}"
    # remove intermediate outpouts
    echo "remove intermediate_outpouts with --dependency=afterok:${final_hillas_run}: "
    sbatch --dependency=afterok:${final_hillas_run} ${monitoring_dir}/launch_rm_temp.sbatch $intermediate_outpouts
else
    final_hillas_run=$(sbatch --parsable ${monitoring_dir}/launch_analyze_run.sbatch $run $dark_file $param_file $output_file $thr1 $thr2 ${events_example_file} ${window_correction} $files)
    echo "Submitted batch job ${final_hillas_run}";
fi

# plot pipeline output if more than 5 files in the run
if (( $n_file >= 5 )); then 
    scan_2d_plot="${output_dir}/2d_alpha_scan_run${run}.png"
    shower_center_plot="${output_dir}/showers_center_run${run}.png"
    hillas_plot="${output_dir}/hillas_run${run}.png"
    corel_all_plot="${output_dir}/correlation_all_run${run}.png"
    corel_sel_plot="${output_dir}/correlation_pass_cut_run${run}.png"
    disp_plot="${output_dir}/disp_run${run}.png"
    echo "plot pipeline results:"
    sbatch --dependency=afterok:${final_hillas_run} ${monitoring_dir}/launch_plot_pipeline.sbatch $output_file  $scan_2d_plot $shower_center_plot $hillas_plot $corel_all_plot $corel_sel_plot $disp_plot
fi

echo "done"
