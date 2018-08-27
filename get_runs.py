from astropy.io import fits
import numpy as np
import sys
import subprocess
import protozfits

#from a list of zfit files determine the runs, output as
# "source", dark_file, datafile1, datafile2, ..., 

if len(sys.argv) < 2:
    sys.stderr.write('list of zfit files must be passed as argument.\n')
files = sys.argv[1:]
# get info from files
types = []
starts = []
ends = []
sources = []
with open('files_info.txt', 'w') as run_file:
    old_path=$PWD
    cd /home/reniery/ctasoft/digicampipe
    digicampipe_branch = subprocess.check_output("git branch | grep \* | cut -d ' ' -f2", shell=True).decode('utf-8').strip('\n')
    digicampipe_commit = subprocess.check_output("git rev-parse HEAD", shell=True).decode('utf-8').strip('\n')
    cd /home/reniery/cron
    pipeline_branch =  subprocess.check_output("git branch | grep \* | cut -d ' ' -f2", shell=True).decode('utf-8').strip('\n')
    pipeline_commit = subprocess.check_output("git rev-parse HEAD", shell=True).decode('utf-8').strip('\n')
    cd $old_path
    run_file.write("#digicampipe branch " + digicampipe_branch+ " commit " + digicampipe_commit + "\n")
    run_file.write("#protozfits version " + protozfits.__version__ + '\n')
    run_file.write("#monitoring pipeline branch " + pipeline_branch + " commit " + pipeline_commit + "\n")
    run_file.write("#file type start end source\n")
    for f in files:
        with fits.open(f) as hdul:
            t = None
            start = None
            end = None
            source = None
            for hdu in hdul:
                if 'RUNTYPE' in hdu.header.keys():
                    t = hdu.header['RUNTYPE']
                if 'DATE' in hdu.header.keys():
                    start = hdu.header['DATE']
                if 'DATEEND' in hdu.header.keys():
                    end = hdu.header['DATEEND']
                if 'TARGET' in hdu.header.keys():
                    source = hdu.header['TARGET']
            types.append(t)
            starts.append(start)
            ends.append(end)
            sources.append(source)
            run_file.write("{} {} {} {} {}\n".format(f, t, start, end, source))
# create runs
previous_file_is_dark = False
latest_dark_run = None
dark_runs = []
source_runs = []
runs = [[]]
for i, f in enumerate(files):
    if types[i] == "darkrun":
        latest_dark_run = i
        # a new darkrun starts a new run if last one is not empty
        if len(runs[-1]) != 0:
            runs.append([])
    elif types[i] == 'science':
        # science runs must have a dark run taken sometime before
        if latest_dark_run is None:
            sys.stderr.write('WARNING: ' + f + ' is science without previous dark run, skipping it!\n')
            continue
        if sources[i] is None:
            sys.stderr.write('WARNING: ' + f + ' is science without source! It will be analysed separatly.\n')
            # science run file with no source is a run of its own.
            if len(runs[-1]) != 0:
                runs.append([i])
            else:
                runs[-1].append(i)
            runs.append([])
            dark_runs.append(latest_dark_run)
            source_runs.append('None')
        else:
            # if the source is the same as before, continue the run
            if source_runs[-1] == sources[i]:
                runs[-1].append(i)
            # otherwise start a new run
            elif len(runs[-1]) != 0:
                runs.append([i])
                dark_runs.append(latest_dark_run)
                source_runs.append(sources[i])
            else:
                runs[-1].append(i)
                dark_runs.append(latest_dark_run)
                source_runs.append(sources[i])
    else:
        sys.stderr.write('WARNING: ' + f + ' has unkown type: "' + str(types[i]) + '"\n')
# format output
for run_idx, run in enumerate(runs):
    if len(run) == 0:
        sys.stderr.write('ERROR: run with no science, check files_info.txt, skiping that run.\n')
        continue
    dark_run = dark_runs[run_idx]
    #sys.stdout.write('"' + source_runs[run_idx] + '", ' + files[dark_run] + ', ')
    sys.stdout.write(files[dark_run] + ', ')
    for file_idx in range(len(run)):
        sys.stdout.write(files[run[file_idx]] + ', ')
    sys.stdout.write('\n')
