#!/bin/bash
#SBATCH --job-name=data_quality
#SBATCH --time=24:00:00
#SBATCH --partition=mono,dpnc
#SBATCH --output=batch_output/data_quality-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=4G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4
source /home/reniery/cron/monitoring_setup.sh

# we remove arguments after reading them to only keep the list of files at the end
run=$1
shift
dark_file=$1
shift
output_fits=$1
shift
output_hist=$1
shift
rate_plot=$1
shift
baseline_plot=$1
shift
time_step=$1
shift
param_file=$1
shift
aux_basepath=$1
shift
files=$@
template_file="digicampipe/tests/resources/pulse_SST-1M_pixel_0.dat"
threshold_sample_pe=20

echo "run: $run"
echo "dark_file: $dark_file"
echo "output_fits: $output_fits"
echo "output_hist: $output_hist"
echo "rate_plot: $rate_plot"
echo "baseline_plot: $baseline_plot"
echo "time_step: $time_step"
echo "param_file: $param_file"
echo "aux_basepath: $aux_basepath"
echo "files: $files"

if [ ! -f ${dark_file} ]; then
    echo "ERROR: dark file ${dark_file} do not exist. Exit";
    exit;
fi
if [ -z "$files" ]; then
    echo "no file to analyze !, exiting..."
    exit
fi

cd ${digicampipe_dir}

echo "python -u digicampipe/scripts/data_quality.py --dark_filename=${dark_file} --output-fits=${output_fits} --output-hist=${output_hist} --rate_plot=${rate_plot} --baseline_plot=${baseline_plot} --time_step=${time_step} --parameters=${param_file} --template=${template_file} --aux_basepath=${aux_basepath} --threshold_sample_pe=${threshold_sample_pe} --disable_bar ${files}"

 python -u digicampipe/scripts/data_quality.py --dark_filename=${dark_file} --output-fits=${output_fits} --output-hist=${output_hist} --rate_plot=${rate_plot} --baseline_plot=${baseline_plot} --time_step=${time_step} --parameters=${param_file} --template=${template_file} --aux_basepath=${aux_basepath} --threshold_sample_pe=${threshold_sample_pe} --disable_bar ${files}

echo "done"
