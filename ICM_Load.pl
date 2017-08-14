#!/usr/bin/env perl
#use Cwd qw(abs_path);

$fileinfo = "\nICM_Load.pl last updated 08-11-17\n";

# Define I/O && initialize #
$info = "\nICM_Load.pl opens all files within a given folder into ICM. It will need the full directory path. \n\t(IE: ./ICM_Load.pl -d /home/server/ICM_FOLDER/)";

$input = "\nUsage\:  ICM_Load.pl  [options]\n

\t-d   \t\tFull Path to the files
";
# Set default values that can be overwritten #
$directory = $ENV{'PWD'};
$files_Number = 0;
$icm_home = "/home/server/icm-3.7-2b/";

# Get flags #
if((@ARGV)) {
  if($#ARGV<1){
   print "\nInvalid Usage, Please try again\n";
   $help = 1;
  }
  else {  
   for ($i=0; $i<=$#ARGV; $i++) {
     $flag = $ARGV[$i];
     chomp $flag;
     if($flag eq "-d"){ $i++; $directory=$ARGV[$i]; next; }
     if($flag eq "-h"){ $help = 1; }
   }
 }
}else{
  print "$input\n"; exit();
}

if($help==1){
  print "$fileinfo";
  print "$info";
  print "$input\n"; exit();
}

# Validing user's directory #
if(-e $directory){
 chomp $directory;
 if((substr $directory, -1) ne "/"){
  $directory = $directory."/";
 }
}
else{
 print "\nThe directory:$directory does not exist!!!\n\n";
 exit;
}

# Reading the files in the directory and putting the files name into array DIR #
opendir(DIR,$directory);
my @files = readdir(DIR);
closedir(DIR);

# This section is used to set up the working directory for loadICM.icm to be made #
chdir $directory;
chdir "..";

# Create ICM script #
open(ICM,'>',"loadICM.icm") || die "Please give me output filename $!"; #adjust the ICMscript 
#print ICM "#!$icm_home"."icm64 -g /home/server/icm-3.7-2b/_startup \n";

# This print portion is used to Hack ICM into loading its Library -Aingty Eung #
print ICM "l_commands = no \n";
print ICM "l_info=no \n";
print ICM "if((Version()~\"*WIN*\" & Version() !~ \"*WINCONSOLE*\" ) | Version()~\"*MacOSX-IL*\") set directory s_projectsDir \n";
print ICM "read table s_icmhome + \"WEBLINK.tab\" system \n";
print ICM "set property WEBLINK show delete edit off \n";
print ICM "set property WEBAUTOLINK show delete edit off \n";
print ICM "set property DATABASE show delete edit off \n";
print ICM "print \"Startup> Loading libraries..\" \n";
print ICM "read libraries \n";
print ICM "read libraries mute \n";
print ICM "l_info=yes \n";
print ICM "call _aliases \n";
print ICM "call _macro \n";
print ICM "loadResources \n";
print ICM "call _bioinfo test \n";
print ICM "call _rebel test \n";
print ICM "call _ligedit test \n";
print ICM "call _docking test \n";
print ICM "l_info=yes \n";
print ICM "if (l_info) printf \"\\n\" \n";
print ICM "if (Index(Version(),\"NoGraphics\")==0 & !Exist(gui)) then \n";
print ICM "  print \" Hint> Run program with -g switch to start graphical user interface\" \n";
print ICM "endif \n";
print ICM "movie_init \n";
print ICM "print \"...ICM startup file executed...\" \n";
print ICM "l_info=yes \n";
print ICM "l_commands=yes \n";
# End of Hacked Print section #

$newNameCount = 0;
for($i=0; $i<=$#files; $i++){
chomp $files[$i];
 if($files[$i] eq "." || $files[$i] eq ".."){
  next;
 }
 else{
  $newNameCount++;
  print ICM "openFile '$directory$files[$i]'\n";
  print ICM "rename a_bche1. Name(Name(\"bche$newNameCount\" simple),object)\n";
 }

}
close(ICM)||die $!;
# Ending creating ICM script #

# Running the command to load in files
system("$icm_home"."icm64 -g loadICM.icm"); 
system("rm loadICM.icm");
# End running the command
###################################################################################################################################################################################
