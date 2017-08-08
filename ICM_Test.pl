#!/usr/bin/env perl
#use Cwd qw(abs_path);

$fileinfo = "\nICM_Test.pl last updated 07-01-17\n";

# Define I/O && initialize
$info = "\nICM_Test.pl loads in multiple files into ICM. It will need the full directory path as well as the file(s) count.";

$input = "\nUsage\:  ICM_Test.pl  [options]\n

\t-d   \t\tFull Path to the files
\t-n   \t\tNumber of files to load
";
# Set default values that can be overwritten #
$directory = $ENV{'PWD'};
$files_Number = 0;
$icm_home = "/home/server/icm-3.7-2b/";

# Get flags #
if((@ARGV)) {
  @options = @ARGV;
  for ($i=0; $i<=$#ARGV; $i++) {
    $flag = $ARGV[$i];
    chomp $flag;
    if($flag eq "-d"){ $i++; $directory=$ARGV[$i]; next; }
    if($flag eq "-n"){ $i++; $files_Number=$ARGV[$i]; next; }
    if($flag eq "-h"){ $help = 1; }
  }
}else{
  print "$input\n"; exit();
}

if($help==1){
  print "$fileinfo";
  print "$info";
  print "$input\n"; exit();
}

# Create ICM script
open(ICM,'>',$directory."temp.icm") || die "Please give me output filename $!"; #adjust the ICMscript 
#print ICM "#!$icm_home"."icm64 \n";
#print ICM "openFile '/home/server/ICM_Test_Folder/bbutyl_top_50/bbutyl_dock1213.ob'\n";
#print ICM "quit\n";
close(ICM)||die $!;
# Ending creating ICM script

# Running the command to load in files
chdir $icm_home;
$temp_Directory = $directory."temp.icm";
system("./icm64 -g $temp_Directory"); 
# End running the command
###################################################################################################################################################################################
