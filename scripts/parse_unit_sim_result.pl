#!/usr/bin/perl -w
##
## Copyright 2019 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##

use strict;
use Getopt::Long;
use Term::ANSIColor;
use Cwd qw(cwd);

my $help           = 0;
my $fail_num       = 0;
my $pass_num       = 0;
my $input_dir      = 'hardware/sim/xcelium/';
my %all_tests;
my @linelist;

my $outfile_name = "parse_unit_sim_result.log";
open(OUTFILE, ">$outfile_name") || die "Could not open $outfile_name.\n$!\n\n";

GetOptions (
    'input_dir:s' => \$input_dir,
    'h!'          => \$help,
);

if ($help) {
    print "Usage:\n";
    print "parse_unit_sim_result.pl <options>\n";
    print "options:\n";
    print "  <-input_dir path_to_simulation_dir> Specify a testlist\n";
    exit; 
}

sub parse_dir {
    opendir(my $DIR, $input_dir);
    while (my $entry = readdir $DIR) {
        next unless -d $input_dir.'/'.$entry;
        next if $entry eq '.' or $entry eq '..';

        if ($entry =~ /(\d+)\.(\d+)\.([A-Za-z_\d]+)/) {
            my $timestamp = $1;
            my $seed = $2;
            my $testcase = $3;

            $all_tests{$timestamp.".".$seed}{tc_name} = $testcase;
            $all_tests{$timestamp.".".$seed}{seed} = $seed;
            $all_tests{$timestamp.".".$seed}{timestamp} = $timestamp;
            $all_tests{$timestamp.".".$seed}{output} = $input_dir.'/'.$entry;
            $all_tests{$timestamp.".".$seed}{status} = "UNKNOWN";
        }
    }
    closedir $DIR;
}

# print the results in a table keeping refreshing.
do {
    parse_dir();
    system("clear");
    printf "%-100s %-20s %-20s %-20s\n", "TESTCASE", "STATUS", "TIMESTAMP", "SEED";
    $pass_num = 0;
    $fail_num = 0;
    foreach my $key (sort keys %all_tests) {
        if (-e "$all_tests{$key}{output}/.RUNNING") {
            $all_tests{$key}{status} = "RUNNING";
        } elsif (-e "$all_tests{$key}{output}/.FAILED") {
            $all_tests{$key}{status} = "FAILED";
            $fail_num = $fail_num + 1;
        } elsif (-e "$all_tests{$key}{output}/.PASSED") {
            $all_tests{$key}{status} = "PASSED";
            $pass_num = $pass_num + 1;
        }
        printf "%-100s ", $all_tests{$key}{tc_name};
        if ($all_tests{$key}{status} eq "RUNNING") {
            print colored(sprintf("%-20s ", $all_tests{$key}{status}), "bold blue");
        } elsif ($all_tests{$key}{status} eq "FAILED") {
            print colored(sprintf("%-20s ", $all_tests{$key}{status}), "bold red");
        } elsif ($all_tests{$key}{status} eq "PASSED") {
            print colored(sprintf("%-20s ", $all_tests{$key}{status}), "bold green");
        } else {
            print colored(sprintf("%-20s ", $all_tests{$key}{status}), "bold yellow");
        }
        printf "%-20s %-20s\n", $all_tests{$key}{timestamp}, $all_tests{$key}{seed};
    }

    print colored("\n----> This table is refreshing every 5 seconds <----\n", "bold");
    sleep(5);
} while (($pass_num + $fail_num) < (keys %all_tests));

# Put result into log file
printf OUTFILE "%-50s %-20s %-20s %-20s %-100s\n", "TESTCASE", "STATUS", "TIMESTAMP", "SEED", "OUTPUT DIR";

foreach my $key (sort keys %all_tests) {
    printf OUTFILE "%-50s %-20s %-20s %-20s %-100s\n", $all_tests{$key}{tc_name}, $all_tests{$key}{status}, $all_tests{$key}{timestamp}, $all_tests{$key}{seed}, $all_tests{$key}{output};
}

print colored("All jobs done. See a full list of simulation results in $outfile_name\n", "bold blue");

close(OUTFILE);

if ($fail_num == 0) {
    exit;
} else {
    exit 1;
}

