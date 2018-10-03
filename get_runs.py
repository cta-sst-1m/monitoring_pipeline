from astropy.io import fits
import numpy as np
import sys
import subprocess
import protozfits

#From a list of zfit files determine the runs, output as:
#dark_file1 dark_file2 ...,datafile1 datafile2 ...
#Note the comma separating the dark_files and the data_files

digicampipe_dir = '/home/reniery/ctasoft/digicampipe'
monitoring_dir = "/home/reniery/cron/"

if len(sys.argv) < 2:
    sys.stderr.write('list of zfit files must be passed as argument.\n')
files = sys.argv[1:]
# get info from files
types = []
starts = []
ends = []
sources = []
with open('files_info.txt', 'w') as run_file:
    #get info about digicampipe version
    digicampipe_branch = subprocess.check_output("cd " + digicampipe_dir +"; git branch | grep \* | cut -d ' ' -f2", shell=True).decode('utf-8').strip('\n')
    digicampipe_commit = subprocess.check_output("cd " + digicampipe_dir +"; git rev-parse HEAD", shell=True).decode('utf-8').strip('\n')
    #get info about the monitoring pipeline version
    pipeline_branch =  subprocess.check_output("cd " + monitoring_dir + "; git branch | grep \* | cut -d ' ' -f2", shell=True).decode('utf-8').strip('\n')
    pipeline_commit = subprocess.check_output("cd " + monitoring_dir + "; git rev-parse HEAD", shell=True).decode('utf-8').strip('\n')
    #write header of files_info.txt
    run_file.write("#digicampipe branch " + digicampipe_branch+ " commit " + digicampipe_commit + "\n")
    run_file.write("#protozfits version " + protozfits.__version__ + '\n')
    run_file.write("#monitoring pipeline branch " + pipeline_branch + " commit " + pipeline_commit + "\n")
    run_file.write("#file type start end source\n")
    for f in files:
        try:
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
        except (OSError, PermissionError) as err:
            print('WARNING: file', f, 'skipped due to:', err)
            if t:
                types.append(t)
            else:
                types.append("none")
            if start:
                starts.append(start)
            else:
                starts.append("")
            if end:
                ends.append(end)
            else:
                ends.append("")
            if source:
                sources.append(source)
            else:
                sources.append("none")
            continue
# create runs
previous_file_is_dark = False
dark_run = []
dark_runs = []
source_runs = []
runs = [[]]
for i, f in enumerate(files):
    if types[i] == "darkrun":
        # a new darkrun starts a new run if last run is not empty
        if not previous_file_is_dark:
            if len(runs[-1]) != 0:
                runs.append([])
            dark_run = []
        dark_run.append(i)
        previous_file_is_dark = True
    elif types[i] == 'science':
        previous_file_is_dark = False
        # science runs must have a dark run taken sometime before
        if len(dark_run) == 0:
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
            dark_runs.append(dark_run)
            source_runs.append('None')
        else:
            # if first defined source, start a new run
            if len(source_runs) == 0:
                if len(runs[-1]) != 0:
                    runs.append([i])
                else:
                    runs[-1].append(i)
                dark_runs.append(dark_run)
            # if the source is the same as before, continue the run
            elif source_runs[-1] == sources[i]:
                runs[-1].append(i)
                # no dark run added here as we make a run longer
            # otherwise start a new run
            elif len(runs[-1]) != 0:
                runs.append([i])
                dark_runs.append(dark_run)
            else:
                runs[-1].append(i)
                dark_runs.append(dark_run)
            source_runs.append(sources[i])
    else:
        sys.stderr.write('WARNING: ' + f + ' has unkown type: "' + str(types[i]) + '"\n')
if len(runs) == 0:
    sys.stderr.write('ERROR: empty list of runs.\n')
    exit()

if len(runs[-1]) == 0:
    # remove last empty run
    runs = runs[:-1]

#print('runs (', len(runs), '):')
#for i, run in enumerate(runs):
#    print(i+1, run)
#print('dark_runs (', len(dark_runs), '):')
#for i, dark in enumerate(dark_runs):
#    print(i+1, dark)

assert len(runs) == len(dark_runs)

# format output
for run_idx, run in enumerate(runs):
    if len(run) == 0:
        sys.stderr.write('ERROR: run ' + str(run_idx) + ' with no science, check files_info.txt, skiping that run.\n')
        continue
    dark_run = dark_runs[run_idx]
    dark_run_files = [files[dark_run_idx] for dark_run_idx in dark_run]
    dark_run_files_str = ""
    for filename in dark_run_files:
        dark_run_files_str += filename + ' '
    dark_run_files_str = dark_run_files_str[:-1]
    sys.stdout.write(dark_run_files_str + ', ')
    for file_idx in range(len(run)):
        sys.stdout.write(files[run[file_idx]] + ' ')
    sys.stdout.write('\n')
