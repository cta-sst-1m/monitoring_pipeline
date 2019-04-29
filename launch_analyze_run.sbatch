#!/bin/bash
#SBATCH --job-name=hillas_compute
#SBATCH --time=1:30:00
#SBATCH --partition=mono,dpnc,mono-shared
#SBATCH --output=batch_output/hillas_compute-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=4G

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

if [ -z "$files" ]; then
    echo "no file to analyze !, exiting..."
    exit
fi

cd ${digicampipe_dir}

if $window_correction; then
    corr="--apply_corr_factor --wdw_number=1"
else
    corr=""
fi

python -u digicampipe/scripts/pipeline.py -o ${output_file} --dark ${dark_file} --parameters=${param_file} --template=${template_file} --disable_bar ${files} --picture_threshold=${thr1} --boundary_threshold=${thr2} --event_plot_filename=$events_example_file $corr
return_value=$?
echo "done"
exit ${return_value}
