#!/usr/bin/perl

# ------------------------------------------------------------------------------------
#
# KHAI NGUYEN
# CSU LONG BEACH 2014
#
# ------------------------------------------------------------------------------------

# This script extract RMSD and Rg values for the F@H data.
# Type `usegromacs???`, where ??? stands for GROMACS version, before running this script
# Lastly, this script must be run from with a Project<#> folder.

$usage = "perl  script.pl  [project]  [ndx file]  [starting structure] [g_rms least squares group flag #] [g_rms RMSD group flag #] [g_gyrate group flag #] [RMSD, RG, or both? (1,2,3) optional] [frame 0 only? (1) optional]
NOTE: ndx and starting structure files must have absolute paths";
# ------------------------------------------------------------------------------------
# GET ARGUMENTS
	$project                     = $ARGV[0] or die "$usage\n";
	$ndx                         = $ARGV[1] or die "$usage\n";
	$nativeStrture               = $ARGV[2] or die "$usage\n";
	$g_rms_least_squares_flag    = int($ARGV[3]) or die "$usage\n";
	$g_rms_RMSD_calculation_flag = int($ARGV[4]) or die "$usage\n";
	$g_gyrate_group_flag         = int($ARGV[5]) or die "$usage\n";
	$g_rms_g_gyrate_switch       = int($ARGV[6]) or 3;
	$frame_0_only_switch         = int($ARGV[7]) or 0;

# ------------------------------------------------------------------------------------
# ?
	if ($g_rms_g_gyrate_switch < 0 || $g_rms_g_gyrate_switch > 3) {
		die "$usage\n";
	}
	
	if ($frame_0_only_switch < 0 || $frame_0_only_switch > 1) {
		die "$usage\n";
	}

	$currentDir = `pwd`; chomp $currentDir;
	# Obtain absolute paths for all runs.
	@runs = &pattern_walk("RUN", $currentDir);
	$num_runs = scalar(@runs);
	print "Number of runs is $num_runs\n";
	mkdir "RMSD-RG";
	$out_dir = "$currentDir"."/RMSD-RG";
	foreach $run (@runs){
		# Continue if the run directory exists
		if (-d $run) {
			if ($frame_0_only_switch == 1) {
				$num_clones = 1;
				print "$run: $num_clones clones\n";
				@clones[0] = "$run/CLONE0";
			} else {
				# Get all clone directories if not doing a frame0 analysis
				@clones = &pattern_walk("CLONE", $run);
				$num_clones = scalar($clones);
				print "$run: $num_clones clones\n";
			}
			foreach $clone (@clones){
				# Continue if the clone directory exists
				if (-d $clone) {
					@rc = &get_rc($clone);
					$run_number = $rc[0];
					$clone_number = $rc[1];
					if ($frame_0_only_switch == 1) {
						$rmsd_output = "$out_dir/P$project"."_R$run_number"."_C$clone_number"."_F0_rmsd.xvg";
						$gyrate_output = "$out_dir/P$project"."_R$run_number"."_C$clone_number"."F0_gyrate.xvg";
						# Obtain the ..f0.pdb file (if more than one there is a problem)
						@files = &pattern_walk("f0.pdb", $clone);
						$num_files = scalar(@files); 
						if ($num_files > 1) {
							die "[ERROR] More than one ..f0.pdb file at $clone. Exiting...";
						} elsif ($num_files == 0) {
							die "[ERROR] No ..f0.pdb file at $clone. Exiting...";
						}
						$data_file = $files[0];
					} else {
						$rmsd_output = "$out_dir/P$project"."_R$run_number"."_C$clone_number"."_rmsd.xvg";
						$gyrate_output = "$out_dir/P$project"."_R$run_number"."_C$clone_number"."_gyrate.xvg";
						$data_file_name = "P$project"."_R$run_number"."_C$clone_number".".xtc";
						# Obtain concatenated .xtc file (if more than one there is a problem) 
						@files = &pattern_walk($data_file_name, $clone);
						$num_files = scalar(@files); 
						if ($num_files > 1) {
							die "[ERROR] More than one $data_file_name at $clone. Exiting...";
						} elsif ($num_files == 0) {
							die "[ERROR] No $data_file_name file at $clone. Exiting...";
						}
						$data_file = $files[0];
					}
					# Perform GMX commands
					if ($g_rms_g_gyrate_switch == 1) {
						`echo $g_rms_least_squares_flag $g_rms_RMSD_calculation_flag | g_rms -s $nativeStrture -f $data_file -n $ndx -o $rmsd_output`;
					} elsif ($g_rms_g_gyrate_switch == 2) {
						`echo $g_gyrate_group_flag | g_gyrate -s $nativeStrture -f $data_file -n $ndx -o $gyrate_output`;
					} else {
						`echo $g_rms_least_squares_flag $g_rms_RMSD_calculation_flag | g_rms -s $nativeStrture -f $data_file -n $ndx -o $rmsd_output`;
						`echo $g_gyrate_group_flag | g_gyrate -s $nativeStrture -f $data_file -n $ndx -o $gyrate_output`;
					}
				} else {
					print "[ERROR] $clone does not exist. Exiting...";
				}
			} # END OF LOOP THROUGH CLONE* directories
		} else {
			print "[WARNING] $run does not exist. Skipping...";
		}
	} # END OF LOOP THROUGH RUN* directories

# Requires tree Linux OS command
sub pattern_walk{ # arguments: pattern to search for, absolute path of directory
	local($pattern, $path, @dirs, $num_dirs);
	$pattern = $_[0];
	$path = $_[1];
	@dirs = `ls $path | grep $pattern`;
	$num_dirs = scalar(@dirs);
	for (my $x=0; $x<$num_dirs; $x++) {
		$dir = $dirs[$x];
		chomp $dir;
		$dirs[$x] = "$path/$dir";
	}
	return @dirs;
}
sub get_rc{ # arguments: absolute path of directory
	local($path, @rc);
	$path = $_[0];
	@split = split("/", $path);
	foreach $val (@split) {
		if (index($val, "RUN") != -1) {
   			$val =~ s/RUN//ig;
			chdir ".."; # go out of RUN* directory
		@rc[0] = $val;
		}
		if (index($val, "CLONE") != -1) {
   			$val =~ s/CLONE//ig;
			@rc[1] = $val;
		}
	}
	return @rc;
}
