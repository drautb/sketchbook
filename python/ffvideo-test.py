import PIL

from ffvideo import VideoStream


VIDEO_FILE = '/Users/drautb/Desktop/haystack-samples/moto-x/VID_20151207_081126527.mp4'
THUMBNAIL = '/Users/drautb/Desktop/haystack-samples/moto-x/test-thumbnail.jpg'

vs = VideoStream(VIDEO_FILE,
                 frame_size=(128, None),  # scale to width 128px
                 frame_mode='RGB')  # convert to grayscale

# vs = VideoStream(VIDEO_FILE)

print "frame size: %dx%d" % (vs.frame_width, vs.frame_height)
print "Width: %d" % (vs.width)
print "Height: %d" % (vs.height)

frame = vs.get_frame_at_sec(0)
frame.image().transpose(PIL.Image.ROTATE_270).save(THUMBNAIL)
