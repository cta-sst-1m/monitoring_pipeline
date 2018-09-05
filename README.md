# monitoring_pipeline
scripts used by the monitoring pipeline

woking on baobab cluster (baobab.unige.sh).

## Instalation

install digicampipe [instalation procedure](https://github.com/cta-sst-1m/digicampipe/blob/master/README.md)

Download the monitoring pipeline and you are ready to go.
WARNING: if not running on baobab, editing the scripts might be mandatory.

## Scripts description

test_pipeline.sh is the script launched by cron.

get_runs.py is taking the path to data files and determine the runs based on the run type and sources of the fits files.

launch_analyze_run.sbatch is the script executed by the jobs analysing hillas for a run.

launch_data_quality.sbatch is the script executed by the jobs analysing data quality for a run.

launch_trigger_uniformity.sbatch is the script executed by the jobs analysing the trigger uniformity for a run.

recompute_all.sh is running the pipeline on all data (many jobs may be created!).
