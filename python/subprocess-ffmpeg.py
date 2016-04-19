# I want to execute a command like this from python:
#
# `ffmpeg -i input.mts -threads 4 -f mp4 -metadata creation_time="YYYY-MM-DD HH:MM:SS" output.mp4 `

import subprocess

INPUT_FILE = '/Users/drautb/Desktop/haystack-samples/sony-handycam-pure/AVCHD/BDMV/STREAM/00146.MTS'

retval = subprocess.check_call(['ffmpeg', '-i',
                                INPUT_FILE,
                                '-threads', '4',
                                '-f', 'mp4',
                                '-metadata', 'creation_time=2015-11-17 15:31:00',
                                'out.mp4'])

print "retval: " + str(retval)
