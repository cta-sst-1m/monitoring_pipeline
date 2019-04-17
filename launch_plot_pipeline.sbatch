#!/bin/bash
#SBATCH --job-name=plot_pipeline
#SBATCH --time=5:59:59
#SBATCH --partition=mono,dpnc,mono-shared
#SBATCH --output=batch_output/plot_pipeline-%J.out
#SBATCH --ntasks=1
#SBATCH --mem=4G

module load GCC/6.4.0-2.28 OpenMPI/2.1.2 TensorFlow/1.7.0-Python-3.6.4
source /home/reniery/cron/monitoring_setup.sh

dl2_file=$1
scan_2d_plot=$2
shower_center_plot=$3
hillas_plot=$4
corel_all_plot=$5
corel_sel_plot=$6
disp_plot=$7

echo "create plots"
output_dir=${output_file%/*}

cd $digicampipe_dir
#various plots
python -u $digicampipe_dir/digicampipe/scripts/plot_pipeline.py --plot_showers_center=${shower_center_plot} --plot_hillas=${hillas_plot} --plot_correl_all=${corel_all_plot} --plot_correl_selected=${corel_sel_plot} --plot_map_disp=${disp_plot} --plot_scan2d=${scan_2d_plot} --disable_bar ${dl2_file}

echo "done"
