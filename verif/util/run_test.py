#!/usr/bin/env python3

import yaml
import argparse
import subprocess
import os
import sys
from contextlib import contextmanager

def run_cmd(cmd):
    subprocess.run(cmd, stdout=sys.stdout, shell=True)

def check_test_yaml(test):
    # Check test has rtl_files field, and that it isn't empty
    if "rtl_files" in test:
        if type(test['rtl_files']) != list:
            print("ERROR: YAML entry for " + test['name'] + " rtl_files must be a list")
            exit(1)
    else:
        print("ERROR: YAML entry for " + test['name'] + " has no rtl_files field")
        exit(1)
    
    # Check test has tb field, and that it isn't empty
    if "tb" in test:
        if type(test['tb']) == list:
            print("ERROR: YAML entry for " + test['name'] + " testbench is a list, should be single file")
            exit(1)
        elif test['tb'] is None:
            print("ERROR: YAML entry for " + test['name'] + " has no testbench files")
            exit(1)
    else:
        print("ERROR: YAML entry for " + test['name'] + " has no tb field")
        exit(1)

@contextmanager
def safe_chdir(path):
    old_path = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(old_path)

def make_test_dir(test_name):
    if os.path.isdir(os.path.join(verif_path, "results")) is False:
        print("ERROR: $VERIF_PATH/results must exist")
        exit(1)
    dir = os.path.join(verif_path, "results", test_name.rstrip(".sv"))
    if os.path.isdir(dir):
        print("WARNING: results already exist for this test, skipping test")
        return ""
    else:
        os.mkdir(dir)
        return dir

def get_rtl_files(files):
    file_list = [os.path.join(rtl_path, f) for f in files]
    file_str = ""
    for f in file_list:
        file_str += f + " "
    return " " + file_str.rstrip(" ")

###############################################################################
# Execution begins here

parser = argparse.ArgumentParser()
parser.add_argument("test_name", help="Name of test to run. Type \"all\" to run all tests")
parser.add_argument("-c", "--coverage", help="Enable coverage collection", action="store_true")
parser.add_argument("-g", "--gui", help="Enable GUI for simulation", action="store_true")
parser.add_argument("-p", "--print_cov", help="Print coverage summary after test. Requires -c", action="store_true")
args = parser.parse_args()
if args.print_cov and (args.coverage is not True):
    parser.error("--print_cov (-p) requires --coverage (-c)")

verif_path = os.environ.get("VERIF_PATH")
if (verif_path == "") or (verif_path is None):
    print("ERROR: VERIF_PATH environment variable must be set")
    exit(1)
verif_path = os.path.abspath(verif_path)

rtl_path =  os.environ.get("RTL_PATH")
if (rtl_path == "") or (rtl_path is None):
    print("ERROR: RTL_PATH environment variable must be set")
    exit(1)
rtl_path = os.path.abspath(rtl_path)

print("VERIF_PATH: " + verif_path)
print("RTL_PATH: " + rtl_path)

yaml_path = os.path.join(verif_path, "tests.yaml")
with open(yaml_path, 'r') as f:
    test_list = yaml.load(f, Loader=yaml.FullLoader)
    # print(test_list)

# This can be used to demonstrate run_cmd() is streaming to stdout properly
# run_cmd("ping www.google.com -c 4")

if args.test_name.lower() == "all":
    print("All tests will be run")
else:
    # Get list of test names for all tests. If specific test is given, check it exists
    all_test_names = [test['name'] for test in test_list]
    if args.test_name in all_test_names:
        # Get index of chosen test out of test_list by checking its index in list of names
        # Retrieve the chosen test from test test by indexing it
        test_list = [test_list[all_test_names.index(args.test_name)]]
    else:
        print("ERROR: test name \"" + args.test_name + "\" not found!")
        exit(1)

# Do run through test entries to check all are valid
for test in test_list:
    print("Checking test: " + test['name'])
    check_test_yaml(test)

# Run through test entries and run tests
for test in test_list:

    results_dir = make_test_dir(test['name'])
    if results_dir == "":
        continue
    
    with safe_chdir(results_dir):

        print("Running test: " + test['name'])
        print("Results directory: " + results_dir)

        tb_path = os.path.join(verif_path, test['tb']) 
        print("TB path: " + tb_path)
        rtl_string = get_rtl_files(test['rtl_files'])

        # Run vlib to make a work library
        vlib_cmd = "vlib work"
        run_cmd(vlib_cmd)

        # Run vmap to map library location to symbolic name
        vmap_cmd = "vmap work work"
        run_cmd(vmap_cmd)

        # Compile tb and rtl files, with coverage if desired
        vlog_cmd = "vlog " + tb_path + rtl_string + " -work work"
        if args.coverage:
            # Enables all main types of coverage (statement, branch, condition,
            # expression, fsm, toggle)
            vlog_cmd += " +cover=sbceft"
        run_cmd(vlog_cmd)
        
        # Run sim, GUI if desired, coverage if desired. If coverage is enabled
        # it is automatically stored in coverage.ucdb in the test's directory
        tb_module = test['tb'].rstrip(".sv")
        if args.coverage:
            do_cmd = "\"coverage save -onexit coverage.ucdb; run -all\""
        else:
            do_cmd = "\"run -all\""
        vsim_cmd = "vsim " + tb_module + " -work work -do " + do_cmd
        if args.gui is False:
            # GUI is enabled unless you specify batch
            vsim_cmd += " -batch"
        if args.coverage:
            vsim_cmd += " -coverage"
        run_cmd(vsim_cmd)

        # Print coverage summary at the end of each test if required
        if args.print_cov:
            run_cmd("vcover summary coverage.ucdb")
