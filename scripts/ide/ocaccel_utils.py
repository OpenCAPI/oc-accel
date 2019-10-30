#!/usr/bin/env python
#
# Copyright 2019 International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import os
import re
import sys
import shlex
import subprocess
import pprint
import signal
import time
import fileinput

ERASE_LINE = '\x1b[2K'

def kill_pid(pid):
    if pid is None:
        pass
    else:
        os.kill(pid, signal.SIGTERM)

def file_line_count (fname):
    num_lines = sum(1 for line in open(fname))
    return num_lines

def spin_bar():
    syms = ['\\', '|', '/', '-']
    for sym in syms:
        sys.stdout.write("\b%s" % sym)
        sys.stdout.flush()
        time.sleep(.5)

def progress_bar(i, max_len, bar_size, finish = False):
    progress_id = int(float(float(i)/float(max_len))*bar_size)
    if not finish:
        if progress_id >= bar_size - 1:
            progress_id = bar_size - 2
    sys.stdout.write('\r')
    sys.stdout.write("[%-{0}s] %d%%".format(bar_size-1) % ('='*progress_id, float(100.0/(bar_size-1))*float(progress_id)))
    sys.stdout.flush()

    if finish:
        print

def progress_bar_with_text(i, max_len, bar_size, text, finish = False):
    progress_id = int(float(float(i)/float(max_len))*bar_size)
    if not finish:
        if progress_id >= bar_size - 1:
            progress_id = bar_size - 2
    sys.stdout.write(ERASE_LINE)
    sys.stdout.write('\r')
    sys.stdout.write(bcolors.BOLD + text + bcolors.ENDC)
    sys.stdout.write(" - [%-{0}s] %d%%".format(bar_size-1) % ('='*progress_id, float(100.0/(bar_size-1))*float(progress_id)))
    sys.stdout.flush()
    if finish:
        print

def write_file(file, line):
    with open(file, 'w+') as infile:
        infile.write(line + '\n')

def append_file(file, line):
    with open(file, 'a+') as infile:
        infile.write(line + '\n')

def search_file_group_1(file, pattern):
    if os.path.isfile(file):
        with open(file, 'r') as infile:
            for line in infile:
                result = re.search(pattern, line)
                if result is not None:
                    return result.group(1)
    else:
        msg.warn_msg("%s not exist!" % file)
        msg.fail_msg("File not existed when using search_file_group_1()")

    return None

def search_file(file, pattern):
    if os.path.isfile(file):
        with open(file, 'r') as infile:
            for line in infile:
                result = re.search(pattern, line)
                if result is not None:
                    return result.group()
    else:
        msg.warn_msg("%s not exist!" % file)
        msg.fail_msg("File not existed when using search_file()")

    return None

def search_file_reversely(file, pattern):
    if os.path.isfile(file):
        for line in reversed(open(file).readlines()):
            result = re.search(pattern, line)
            if result is not None:
                return result.group()
    else:
        msg.warn_msg("%s not exist!" % file)
        msg.fail_msg("File not existed when using search_file()")

    return None


def grep_file(file, pattern):
    if os.path.isfile(file):
        with open(file, 'r') as infile:
            for line in infile:
                if re.search(pattern, line) is not None:
                    return line
    else:
        msg.warn_msg("%s not exist!" % file)
        msg.fail_msg("File not existed when using grep_file()")

    return None

def sed_file(file, pattern, replace, remove_matched_line = False):
    if os.path.isfile(file):
        for line in fileinput.input(file, inplace=1, backup='.bak'):
            if not remove_matched_line:
                line = re.sub(pattern, replace, line.rstrip())
                print(line)
            else:
                match = re.search(pattern, line.rstrip())
                if match is None:
                    print line.rstrip()
    else:
        msg.warn_msg("%s not exist!" % file)
        msg.fail_msg("File not existed when using sed_file()")

def run_and_poll(cmd, work_dir, log, timeout = 2592000):
    with open(log, "w+") as f:
        proc = subprocess.Popen(shlex.split(cmd),\
                                cwd=work_dir,\
                                shell=False,\
                                stdout=f, stderr=f)
        print "Runnig ...\\",
        for _ in range(timeout):
            poll = proc.poll()
            if poll is None:
                spin_bar()
            else:
                print
                return proc.returncode
        print
        msg.warn_msg("Timeout running %s after %d seconds" % (cmd, timeout))
    return proc.returncode

def run_and_poll_with_progress(cmd, work_dir, log, max_log_len, timeout = 2592000):
    progress_bar_size = 30
    with open(log, "w") as f:
        proc = subprocess.Popen(shlex.split(cmd),\
                                cwd=work_dir,\
                                shell=False,\
                                stdout=f, stderr=f)
        print "Runnig ... check %s for details of full progress" % log
        current_text = "JUST STARTED!"
        for _ in range(timeout):
            poll = proc.poll()
            if poll is None:
                text = search_file_reversely(log, "\[.*\]\s+(start|done)")
                if text is not None:
                    current_text = text
                len = file_line_count(log)
                progress_bar_with_text(len, max_log_len, progress_bar_size, current_text)
                time.sleep(1)
            else:
                progress_bar_with_text(max_log_len - 1, max_log_len, progress_bar_size, "FINISHED!", True)
                print
                return proc.returncode
        msg.warn_msg("Timeout running %s after %d seconds" % (cmd, timeout))
    return proc.returncode

def run_in_background(cmd, work_dir, log):
    with open(log, "w+") as f:
        pid = subprocess.Popen(shlex.split(cmd),\
                               cwd=work_dir,\
                               shell=False,\
                               stdout=f, stderr=f).pid
    return pid

def run_and_wait(cmd, work_dir, log):
    with open(log, "w+") as f:
        proc = subprocess.Popen(shlex.split(cmd),\
                                cwd=work_dir,\
                                shell=False,\
                                stdout=f, stderr=f)
        proc.communicate()
    return proc.returncode

def run_to_stdout(cmd, work_dir):
    proc = subprocess.Popen(shlex.split(cmd),\
                            cwd=work_dir,\
                            shell=False,\
                            stdout=sys.stdout, stderr=sys.stderr)
    proc.communicate()
    return proc.returncode

def mkdirs(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

def source(file):
    if os.path.isfile(file):
        cmd = "env -i bash -c 'source " + file + " && env'"
        command = shlex.split(cmd)
        proc = subprocess.Popen(command, stdout = subprocess.PIPE)
        for line in proc.stdout:
            (key, _, value) = line.partition("=")
            os.environ[key] = value.rstrip()
        proc.communicate()
    else:
        msg.warn_msg(file + " not exist!")
        msg.fail_msg("Something wrong to source file " + file + "! Exiting ...")

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        pass
 
    try:
        import unicodedata
        unicodedata.numeric(s)
        return True
    except (TypeError, ValueError):
        pass
 
    return False

def which(program):
    import os
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None

class SystemCMD:
    def __init__(self, name):
        self.name = name
        self.cmd = which(name)

    def check(self, existence_critical = False, minimum_version = "0.0.0"):
        if (self.check_existence(critical = existence_critical) == None):
            return
        self.check_version(minimum = minimum_version)

    def check_existence(self, critical = False):
        if self.cmd != None:
            msg.header_msg(self.name + "\t installed as\t" + self.cmd)
            return self.cmd
        else:
            msg.warn_msg(self.name + "\t NOT FOUND!")
            if critical == True:
                msg.fail_msg(self.name + " not found, dependency check failed! Exiting ... ")
            return None

    def check_version(self, minimum = "0.0.0"):
        self.version = self.get_version()

        if minimum == "0.0.0":
            return

        real = tuple(map(int, self.version.split('.')))
        min = tuple(map(int, minimum.split('.')))

        if real < min:
            msg.warn_msg("Version check failed on %s, current version %s, "\
                  "expected minimum version %s" % (self.name, self.version, minimum))
            msg.fail_msg(self.name + " version check failed! Exiting ... ")
        else:
            return

    def get_version(self):
        version = "0"

        if self.name == "gcc":
            proc = subprocess.Popen([self.cmd + " -dumpversion"], stdout=subprocess.PIPE, shell=True)
            version = proc.stdout.read()
            version = version.strip("\n")
            version = version.strip("\r")

        elif self.name == "vivado":
            proc = subprocess.Popen([self.cmd + " -version"], stdout=subprocess.PIPE, shell=True)
            tmp = proc.stdout.read()
            for l in tmp.splitlines():
                if l.startswith("Vivado"):
                    for v in l.split():
                        if v.startswith("v"):
                            version = v[1:]

        elif  self.name == "xterm":
            proc = subprocess.Popen([self.cmd + " -version"], stdout=subprocess.PIPE, shell=True)
            tmp = proc.stdout.read()
            for v in tmp.split():
                if v[0].isdigit():
                    # remove contents in ()
                    v = v.replace(v[v.find('(') : v.find(')') + 1], "")
                    version = v

        else:
            version = "invalid"

        return version

class bcolors:
    #HEADER = '\033[1m'
    OKBLUE = '\033[1m'
    OKGREEN = '\033[1m'
    WARNING = '\033[1m'
    FAIL = '\033[1m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

fail_on_exit = True
class msg:
    @classmethod
    def fail_msg(cls, msg):
        if fail_on_exit:
            exit(bcolors.FAIL + msg + bcolors.ENDC)
        else:
            print bcolors.FAIL + msg + bcolors.ENDC
    @classmethod
    def warn_msg(cls, msg):
        print bcolors.WARNING + msg + bcolors.ENDC
    @classmethod
    def ok_msg(cls, msg):
        print bcolors.OKGREEN + msg + bcolors.ENDC
    @classmethod
    def ok_msg_blue(cls, msg):
        print bcolors.OKBLUE + msg + bcolors.ENDC
    @classmethod
    def header_msg(cls, msg):
        #print bcolors.HEADER + msg + bcolors.ENDC
        print msg

