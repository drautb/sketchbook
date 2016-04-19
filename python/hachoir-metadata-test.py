# Inspired by https://github.com/jgstew/file-meta-data/blob/master/file_meta_data.py

import hachoir_core
import hachoir_core.cmd_line
import hachoir_metadata
import hachoir_parser
import sys


def getMetaData(filename):
    text = ""
    filename, realname = hachoir_core.cmd_line.unicodeFilename(filename), filename
    print "filename: " + filename
    print "realname: " + realname
    parser = hachoir_parser.createParser(filename, realname)

    if not parser:
        print >>sys.stderr, "Unable to parse file"
        return text

    try:
        metadata = hachoir_metadata.extractMetadata(parser)
    except HachoirError, err:
        print "Metadata extraction error: %s" % unicode(err)
        metadata = None

    if not metadata:
        print >>sys.stderr, "Unable to extract metadata"
        return text

    text = metadata.exportPlaintext()
    return text


if __name__ == "__main__":

    filename = "/Users/drautb/Desktop/Haystack Samples/Camera (Moto X)/IMG_20150810_220158824.jpg"

    if 1 < len(sys.argv):
        filename = sys.argv[1]

    meta_data_text = getMetaData(filename)

    for line in meta_data_text:
        print hachoir_core.tools.makePrintable(line, hachoir_core.i18n.getTerminalCharset())
