import requests
from subprocess import call

ETAG_FILE = '/tmp/dnsmasq-config.etag'
HOSTS_FILE_URL = 'https://gist.githubusercontent.com/drautb/30827af5945a400cb64811d7f66dc16c/raw'

call(["touch", ETAG_FILE])


def file_get_contents(filename):
    with open(filename) as f:
        return f.read()


def file_put_contents(filename, contents):
    with open(filename, 'w') as f:
        f.write(contents)


headers = {'If-None-Match': file_get_contents(ETAG_FILE)}
r = requests.get(HOSTS_FILE_URL, headers=headers)

if r.status_code == 200:
    file_put_contents("./config", r.text)
    file_put_contents(ETAG_FILE, r.headers['ETag'])
    call(["service", "dnsmasq", "restart"])
elif r.status_code != 304:
    print "Received unexpected response! " + r
    exit(1)
