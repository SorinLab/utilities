#!/usr/bin/perl
use strict;
use warnings;

# ------------------------------------------------------------------------------------
#
# KHAI NGUYEN
# CSU LONG BEACH 2014
#
# ------------------------------------------------------------------------------------

# This script extract RMSD and Rg values for the F@H data.
# Type `usegromacs???`, where ??? stands for GROMACS version, before running this script
# This script must be run from with a Project<#> folder.

my $usage =
"perl  script.pl  [project]  [ndx file]  [starting structure] [g_rms least squares group flag #] [g_rms RMSD group flag #] [g_gyrate group flag #] [RMSD, RG, or both? (1,2,3) optional] [frame 0 only? (1) optional]
NOTE: ndx and starting structure files must have absolute paths";

# ------------------------------------------------------------------------------------
# GET ARGUMENTS

my $project                     = $ARGV[0] or die "$usage\n";
my $ndx                         = $ARGV[1] or die "$usage\n";
my $nativeStrture               = $ARGV[2] or die "$usage\n";
my $g_rms_least_squares_flag    = $ARGV[3] or die "$usage\n";
my $g_rms_RMSD_calculation_flag = $ARGV[4] or die "$usage\n";
my $g_gyrate_group_flag         = $ARGV[5] or die "$usage\n";
my $g_rms_g_gyrate_switch       = $ARGV[6] or 3;
$g_rms_g_gyrate_switch = int($g_rms_g_gyrate_switch) or die "$usage\n";
my $frame_0_only_switch = $ARGV[7] or 0;
$frame_0_only_switch = int($frame_0_only_switch) or die "$usage\n";

# ------------------------------------------------------------------------------------
# Check validity of the user input
if ($g_rms_g_gyrate_switch < 0 || $g_rms_g_gyrate_switch > 3) {
    die "$usage\n";
}

if ($frame_0_only_switch < 0 || $frame_0_only_switch > 1) {
    die "$usage\n";
}

my $currentDir = `pwd`;
chomp $currentDir;

# Obtain absolute paths for all runs.
my @runs = &pattern_walk("RUN", $currentDir);
my $num_runs = scalar(@runs);
print "Number of runs is $num_runs\n";
mkdir "RMSD-RG";
my $out_dir = "$currentDir" . "/RMSD-RG";
foreach my $run (@runs) {

    # Continue if the run directory exists
    if (-d $run) {
        my @clones;
        if ($frame_0_only_switch == 1) {
            my $num_clones = 1;
            print "$run: $num_clones clones\n";
            @clones[0] = "$run/CLONE0";
        }
        else {
            # Get all clone directories if not doing a frame0 analysis
            @clones = &pattern_walk("CLONE", $run);
            my $num_clones = scalar(@clones);
            print "$run: $num_clones clones\n";
        }
        foreach my $clone (@clones) {

            # Continue if the clone directory exists
            if (-d $clone) {
                my @rc           = &get_rc($clone);
                my $run_number   = $rc[0];
                my $clone_number = $rc[1];
                my $rmsd_output;
                my $gyrate_output;
                my $data_file_name;
                my $data_file;
                if ($frame_0_only_switch == 1) {
                    $rmsd_output   = "$out_dir/P$project" . "_R$run_number" . "_C$clone_number" . "_F0_rmsd.xvg";
                    $gyrate_output = "$out_dir/P$project" . "_R$run_number" . "_C$clone_number" . "F0_gyrate.xvg";

                    # Obtain the ..f0.pdb file (if more than one there is a problem)
                    my @files = &pattern_walk("f0.pdb", $clone);
                    my $num_files = scalar(@files);
                    if ($num_files > 1) {
                        die "[ERROR] More than one ..f0.pdb file at $clone. Exiting...";
                    }
                    elsif ($num_files == 0) {
                        die "[ERROR] No ..f0.pdb file at $clone. Exiting...";
                    }
                    $data_file = $files[0];
                }
                else {
                    $rmsd_output    = "$out_dir/P$project" . "_R$run_number" . "_C$clone_number" . "_rmsd.xvg";
                    $gyrate_output  = "$out_dir/P$project" . "_R$run_number" . "_C$clone_number" . "_gyrate.xvg";
                    $data_file_name = "P$project" . "_R$run_number" . "_C$clone_number" . ".xtc";

                    # Obtain concatenated .xtc file (if more than one there is a problem)
                    my @files = &pattern_walk($data_file_name, $clone);
                    my $num_files = scalar(@files);
                    if ($num_files > 1) {
                        die "[ERROR] More than one $data_file_name at $clone. Exiting...";
                    }
                    elsif ($num_files == 0) {
                        die "[ERROR] No $data_file_name file at $clone. Exiting...";
                    }
                    $data_file = $files[0];
                }

                # Perform GMX commands
                if ($g_rms_g_gyrate_switch == 1) {
`echo $g_rms_least_squares_flag $g_rms_RMSD_calculation_flag | g_rms -s $nativeStrture -f $data_file -n $ndx -o $rmsd_output`;
                }
                elsif ($g_rms_g_gyrate_switch == 2) {
                    `echo $g_gyrate_group_flag | g_gyrate -s $nativeStrture -f $data_file -n $ndx -o $gyrate_output`;
                }
                else {
`echo $g_rms_least_squares_flag $g_rms_RMSD_calculation_flag | g_rms -s $nativeStrture -f $data_file -n $ndx -o $rmsd_output`;
                    `echo $g_gyrate_group_flag | g_gyrate -s $nativeStrture -f $data_file -n $ndx -o $gyrate_output`;
                }
            }
            else {
                die "[ERROR] $clone does not exist. Exiting...\n";
            }
        }    # END OF LOOP THROUGH CLONE* directories
    }
    else {
        print "[WARNING] $run does not exist. Skipping...";
    }
}    # END OF LOOP THROUGH RUN* directories

sub pattern_walk {    # arguments: pattern to search for, absolute path of directory
    my ($pattern, $path, @dirs, $num_dirs);
    $pattern  = $_[0];
    $path     = $_[1];
    @dirs     = `ls $path | grep $pattern`;
    $num_dirs = scalar(@dirs);
    for (my $x = 0 ; $x < $num_dirs ; $x++) {
        my $dir = $dirs[$x];
        chomp $dir;
        $dirs[$x] = "$path/$dir";
    }
    return @dirs;
}

sub get_rc {    # arguments: absolute path of directory
    my ($path, @rc);
    $path = $_[0];
    my @split = split("/", $path);
    foreach my $val (@split) {
        if (index($val, "RUN") != -1) {
            $val =~ s/RUN//ig;
            @rc[0] = $val;
        }
        if (index($val, "CLONE") != -1) {
            $val =~ s/CLONE//ig;
            @rc[1] = $val;
        }
    }
    return @rc;
}
