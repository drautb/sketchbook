import exifread
import pprint

FILE = '/Users/drautb/.haystack/staging/TA9911X6LX/VID_20150807_114419476.mp4'
READ_ONLY = 'r'

f = open(FILE, READ_ONLY)
tags = exifread.process_file(f)

pp = pprint.PrettyPrinter(indent=4)
pp.pprint(tags)
