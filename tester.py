import copy
import os
import shutil
import sys, getopt, json

# test script: TestPeriod=M5 M15 H1 H4 -> 4 .set files generated.

help = "usage: \ntester.py \n\t-e --ea <expert_advisor_absolute> \n\t-t --test <test_script_absolute (not mt4 recognizable)> \n\t-s --set <set_file_absolute> \n\t-i --instf <instance_folder> \n\t-o --out <output_folder>"

settings = {}
LOGGER = []
setting_paths = []
setting_files = []


def main(test_file, expert_advisor, setting, working_folder, instance_folder, output_folder):
    parse(test_file)
    generate_files(working_folder)
    test()
    move_results(instance_folder, output_folder)
    print(LOGGER)


def test():
    for setting in setting_paths:
        # start /wait terminal.exe "C:\Users\bendi\Desktop\expert advisors\settings\3_Moving Average_EURUSD_M1_2019-08-06_2019-10-01"
        # subprocess.call(["start", "/wait", "terminal.exe", setting])
        command = "start /wait terminal.exe \"" + setting + "\""
        os.system(command)

    print("FINISHED")


def move_results(instance_folder, output_folder):
    for name in setting_files:
        report = underline_join([name, "REPORT.htm"])
        gif = underline_join([name, "REPORT.gif"])
        report_path = os.path.join(instance_folder, report)
        gif_path = os.path.join(instance_folder, gif)
        report_dest_path = os.path.join(output_folder, report)
        gif_dest_path = os.path.join(output_folder, gif)

        shutil.move(report_path, report_dest_path)
        shutil.move(gif_path, gif_dest_path)


def make_files(all_settings, working_folder):
    for setting in all_settings:
        name = underline_join([setting["TestExpert"], setting["TestSymbol"], setting["TestPeriod"],
                               setting["TestFromDate"].replace(".", "-"), setting["TestToDate"].replace(".", "-")])
        filepath = os.path.join(working_folder, name)
        setting["TestReport"] = underline_join([name, "REPORT"])
        with open(filepath, "w+") as out:
            for key, val in setting.items():
                out.write(key + "=" + val + "\n")
            setting_paths.append(filepath)
            setting_files.append(name)


def underline_join(iterable):
    joined = ""
    for elem in iterable:
        joined += elem + "_"
    return joined.strip("_")


def make_folders():
    # working_folder = mkdir()
    pass


def parse(file_path):
    try:
        with open(file_path) as setting_file:
            for line in setting_file:
                if line[0] != ";":
                    if line.find("=") > 0:
                        setting, raw_val = line.split("=")
                        settings[setting.strip()] = raw_val.strip()
    except Exception as e:
        LOGGER.append("parse error, " + str(e.args).strip("()"))


def generate():
    generated = [{}]
    for key, val in settings.items():
        previous = [{}]
        next_gen = []
        if len(generated) > 0:
            previous = copy.deepcopy(generated)
        if val.find("*") > 0:
            values = val.split("*")
            for value in values:
                current = copy.deepcopy(previous)
                for setting in current:
                    setting[key] = value
                next_gen.extend(current)
            generated = copy.deepcopy(next_gen)
        else:
            for setting in generated:
                setting[key] = val
    return generated


def generate_files(working_folder):
    if len(settings) <= 0:
        LOGGER.append("no settings found")
        return
    else:
        generated = generate()
        make_folders()
        make_files(generated, working_folder)


def read_settings_file(file_path):
    return json.load(file_path)


def get_opts(argv):
    if len(argv) == 0:
        print(help)
        sys.exit(2)
    try:
        opts, args = getopt.getopt(argv, "hf:etsio", ["help", "file=" "ea=", "test=", "set=", "instf=", "out="])
        is_args_from_file = False
        for opt, arg in opts:
            if opt in ("-h", "--help"):
                print(help)
                sys.exit()
            elif opt in ("-f", "--file"):
                if arg != "":
                    is_args_from_file = True
                    from_file = json.load(open(arg, "r"))
                    expert_advisor = from_file["expert_advisor"]
                    test_file = from_file["test_file"]
                    setting = from_file["setting"]
                    working_folder = from_file["working_folder"]
                    instance_folder = from_file["instance_folder"]
                    output_folder = from_file["output_folder"]

        if not is_args_from_file:
            for opt, arg in opts:
                if opt in ("-e", "--ea"):
                    expert_advisor = arg
                elif opt in ("-t", "--test"):
                    test_file = arg
                elif opt in ("-s", "--set"):
                    setting = arg
                elif opt in ("-i", "--instf"):
                    instance_folder = arg
                elif opt in ("-o", "--out"):
                    output_folder = arg

    except getopt.GetoptError:
        print(help)
        sys.exit(2)

    main(test_file, expert_advisor, setting, working_folder, instance_folder, output_folder)


if __name__ == "__main__":
    get_opts(sys.argv[1:])
