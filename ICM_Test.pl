#!/usr/bin/env perl
#use Cwd qw(abs_path);

$fileinfo = "\nICM_Test.pl last updated 07-01-17\n";

############  define I/O && initialize
$info = "\nICM_Test.pl loads in multiple files into ICM. It will need the full directory path as well as the file(s) count.";

$input = "\nUsage\:  ICM_Test.pl  [options]\n

\t-d   \t\tFull Path to the files
\t-n   \t\tNumber of files to load
";
# set default values that can be overwritten #
$directory = $ENV{'PWD'};;
$files_Number = 0;
$icm_home = "/home/server/ICM_Test_Folder"
# get flags #
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

#Create ICM script
open(ICM,'>',$icm_home."temp.icm") || die "Please give me output filename $!"; #adjust the ICMscript 
print ICM "#!$icm_home"."icm -s\n";
close(ICM)||die $!;
#Ending creating ICM script

###################################################################################################################################################################################
