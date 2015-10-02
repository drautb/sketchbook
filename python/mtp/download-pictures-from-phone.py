import pymtp

# Connect to device
device = pymtp.MTP()
device.connect()

file_ids = [2400]

for f in file_ids:
    print device.get_file_metadata(f).filename
    # filename = "/tmp/file_" + str(f) + ".jpg"
    # device.get_file_to_file(f, filename, None)
    # print "Downloaded %s" % filename
    # device.delete_object(f)
    # print "Deleted %s from device." % filename

device.disconnect()
