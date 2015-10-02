import configparser

config = configparser.ConfigParser()
config.read("config.ini")

paths = config.items("paths")
print paths
