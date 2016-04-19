import sys

from PIL import Image

PATH_TO_FILE = sys.argv[1]
PATH_TO_THUMBNAIL = 'thumb.jpg'


image = Image.open(PATH_TO_FILE)

image.thumbnail((128, 128), Image.ANTIALIAS)

image.save(PATH_TO_THUMBNAIL)
