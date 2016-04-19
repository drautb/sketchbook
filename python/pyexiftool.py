import exiftool
import sys

path_to_file = sys.argv[1]

et = exiftool.ExifTool()
et.start()

metadata = et.get_metadata(path_to_file)
for k, v in metadata.iteritems():
    print k, " => ", v
