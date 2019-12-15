import os
import re
import sys, getopt
import xml.etree.ElementTree as ET

help = "usage: \ngroup_by.py \n\t-r --results <results_root_directory> \n\t-q --quality \tgroup by modelling quality\n\t-p --profit \tgroup by total net profit \n\t-t --threshold <percentage>"
DEBUG = True


class Result:
    def __init__(self, root, name="", attributes=None):
        if attributes is None:
            attributes = {}
        self.root = root
        self.name = name
        self.attributes = attributes


def debug_print(message):
    if DEBUG:
        print message


def val_find(line):
    #regex selects every part of line which is in between "<>" but contains no "<" or ">"
    split = re.split(r"<[^<>]*>", line)
    found = None
    for value in split:
        if value is not "":
            found = value
            break
    return found


def parse(root, filename, keys):
    ret = {}
    with open(os.path.join(root, filename)) as f:
        for line in f:
            for key in keys:
                index = line.find(key)
                if index > 0:
                    split = line[index+len(key):]
                    value = val_find(split)
                    ret[key] = value
                    debug_print("{}: \t{}".format(key, value))
    return ret


def move_to_deleted(root, files, threshold):
    debug_print("deleting files: {}".format(files))
    deleted_dir = os.path.join(root, "under_{}".format(threshold))
    if not os.path.isdir(deleted_dir):
        os.mkdir(deleted_dir)
    for file in files:
        os.rename(os.path.join(root, file), os.path.join(deleted_dir, file))


def main(results_root, sort_quality, sort_profit, threshold):
    results = []
    attributes = ["Modelling quality", "Total net profit"]
    debug_print("{}{}{}{}".format(results_root, sort_profit, sort_quality, threshold))
    for root, subdirs, files in os.walk(results_root):
        debug_print("open folder: {}\nfound subdirectories: {}\nfound files: {}".format(root, subdirs, files))
        for filename in files:
            if filename.find(".htm") > 0:
                debug_print("checking attributes of {}".format(filename))
                dict_attr = parse(root, filename, attributes)
                if threshold > 0 and threshold > dict_attr["Modelling quality"]:
                    move_to_deleted(root, [filename, re.sub(r"(\.htm)$", ".gif", filename)], threshold=threshold)
                    continue
                results.append(Result(name=filename, attributes=dict_attr, root=root))
                if sort_quality:
                    # TODO make folder quality and copy sorted files and .gifs
                    pass
                if sort_profit:
                    # TODO make folder profit and copy sorted files and .gifs
                    pass


def print_help_exit(status_code=None):
    print(help)
    if status_code is not None:
        sys.exit(status_code)
    else:
        sys.exit()


def get_opts(argv):
    if len(argv) == 0:
        print_help_exit(2)
    try:
        opts, args = getopt.getopt(argv, "hr:qpt:", ["help", "results=" "quality", "profit", "threshold="])
        results_root = ""
        sort_quality = False
        sort_profit = False
        threshold = 0

        for opt, arg in opts:
            if opt in ("-h", "--help"):
                print_help_exit()
            elif opt in ("-r", "--results"):
                results_root = arg.strip("/")
            elif opt in ("-q", "--quality"):
                sort_quality = True
            elif opt in ("-p", "--profit"):
                sort_profit = True
            elif opt in ("-t", "--threshold"):
                threshold = arg
        if not sort_profit and not sort_quality:
            print_help_exit()

        main(results_root, sort_quality, sort_profit, threshold)

    except getopt.GetoptError:
        print_help_exit(2)


if __name__ == "__main__":
    get_opts(sys.argv[1:])
