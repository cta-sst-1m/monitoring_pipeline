#!/bin/bash
#SBATCH --job-name=data_quality
#SBATCH --time=4:00:00
#SBATCH --partition=mono,dpnc
#SBATCH --output=batch_output/data_quality-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=4G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4

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
files=$@

echo "run: $run"
echo "dark_file: $dark_file"
echo "output_fits: $output_fits"
echo "output_hist: $output_hist"
echo "rate_plot: $rate_plot"
echo "baseline_plot: $baseline_plot"
echo "time_step: $time_step"
echo "param_file: $param_file"
echo "files: $files"

if [ -z "$files" ]; then
    echo "no file to analyze !, exiting..."
    exit
fi

cd /home/reniery/ctasoft/digicampipe/

echo "python -u digicampipe/scripts/data_quality.py --dark_filename=${dark_file} --output-fits=${output_fits} --output-hist=${output_hist} --rate_plot=${rate_plot} --baseline_plot=${baseline_plot} --time_step=${time_step} --parameters=${param_file} ${files}"

 python -u digicampipe/scripts/data_quality.py --dark_filename=${dark_file} --output-fits=${output_fits} --output-hist=${output_hist} --rate_plot=${rate_plot} --baseline_plot=${baseline_plot} --time_step=${time_step} --parameters=${param_file} ${files}

