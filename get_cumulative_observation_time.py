import matplotlib
matplotlib.use('Agg')
from astropy.io import fits
import numpy as np
import sys
import subprocess
import protozfits
import os
import re
from dateutil.parser import parse
from matplotlib import pyplot as plt
import matplotlib.dates as mdates

dir_slow = "/sst1m/aux/"
monitoring_dir = "/sst1m/analyzed/2018"

# get all files_info.txt files recusirvely in monitoring_dir
files_info = []
for dirpath, dirnames, files in os.walk(monitoring_dir):
    for name in files:
        if name.lower() == "files_info.txt":
            files_info.append(os.path.join(dirpath, name))
print('found', len(files_info), 'days with data files')

# setup regexp to parse files_info.txt
zfits_re = "(?P<zfits>[^ ]+)"
type_re = "(?P<type>.+)"
date_re = "\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"
begin_re = "(?P<begin>" + date_re + ")"
end_re = "(?P<end>" + date_re + ")"
source_re = "(?P<source>.*)"
reg = re.compile(" *" + zfits_re + " +" + type_re + " +" + 
                 begin_re + " +" + end_re + " +" + source_re)

# parse all lines of all files_info.txt files
zfits_files = []
type_files = []
begin_files = []
end_files = []
elapsed_files = []
source_files = []
n_files = 0
for file_info in files_info:
    with  open(file_info, 'r') as fp:
        for line_idx, line in enumerate(fp.readlines()):
            if line.strip().startswith("#"):
                continue
            match = reg.match(line)
            if match is None:
                print("could not parse ", file_info, ":", line_idx, '\n', line)
                continue
            zfits_files.append(match.group('zfits'))
            type_files.append(match.group('type'))
            begin = parse(match.group('begin'))
            end = parse(match.group('end'))
            begin_files.append(begin)
            end_files.append(end)
            source_files.append(match.group('source'))
            elapsed_files.append((end - begin).total_seconds())
            n_files += 1
zfits_files = np.array(zfits_files)
type_files = np.array(type_files)
begin_files = np.array(begin_files)
end_files = np.array(end_files)
elapsed_files = np.array(elapsed_files)
source_files = [source.replace('&nbsp;', ' ') for source in source_files]
source_files = np.array(source_files)

# sort files
order = np.argsort(begin_files)
zfits_files = zfits_files[order]
type_files = type_files[order]
begin_files = begin_files[order]
end_files = end_files[order]
elapsed_files = elapsed_files[order]
source_files = source_files[order]

# remove duplicate files
_, unique_idx = np.unique(begin_files, return_index=True)
if len(unique_idx) != len(begin_files):
    print('WARNING: skiped', len(begin_files) - len(unique_idx), 'files')
zfits_files = zfits_files[unique_idx]
type_files = type_files[unique_idx]
begin_files = begin_files[unique_idx]
end_files = end_files[unique_idx]
elapsed_files = elapsed_files[unique_idx]
source_files = source_files[unique_idx]

# TEMPORAY HACK ! set all missing sources as 1ES 1959+650
"""
source_files_new = []
for source in source_files:
    if source.lower() == "none":
        source_files_new.append('1ES 1959+650 (299.9991667, 65.1486111)')
    else:
        source_files_new.append(source)
source_files = np.array(source_files_new)
"""
# maxout the duration of a file to 5 min. Needed as some file have large gaps
elapsed_files[elapsed_files > 300] = 300

# plot observation time for each source
is_science = type_files == 'science'
unique_sources = np.unique(source_files[is_science])
print(np.sum(elapsed_files[is_science])/3600, 'h in science')
fig, ax = plt.subplots(figsize=(8, 6))
reg = re.compile('(?P<name>.*) \(.*\)')
for source in unique_sources:
    is_source = np.logical_and(is_science, source == source_files)
    if source.lower() == 'none':
        source = 'Unknown'
    else:
        match = reg.match(source)
        if match:
            source = match.group('name')
    print(np.sum(elapsed_files[is_source])/3600, 'h on', source)
    ax.plot_date(
        begin_files[is_source], 
        np.cumsum(elapsed_files[is_source])/3600, 
        '-', label=source
    )

ax.xaxis.set_major_locator(mdates.WeekdayLocator(byweekday=mdates.MO))
ax.xaxis.set_minor_locator(mdates.DayLocator())
ax.xaxis.set_major_formatter(mdates.DateFormatter('%m/%d'))
ax.set_ylabel('Integrated observation time [h]')
ax.legend()
ax.grid(which='both')
plt.savefig('observations.png')
plt.close(fig)
