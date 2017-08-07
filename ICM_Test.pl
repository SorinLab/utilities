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

# get flags #
if(defined(@ARGV)) {
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

###################################################################################################################################################################################
if (0) {

#!/usr/bin/env perl
#use Cwd qw(abs_path);

$fileinfo = "\nICM_docking.pl last updated 07-01-17\n";

############  define I/O && initialize
$info = "\nICM_docking.pl performs ICM docking with the specified .mol file for n trials.
The .mol file must be in your icm home folder (icm-3.7-2b). If you want you can change the home icm folder in this script below.
The starting docking number can be specified in order to continue where last docking trials left off.
This is important because you do not want to overwrite older docking scores while compiling them together.";

$input = "\nUsage\:  ICM_docking.pl  [options]\n

\t-pro \t\tProject name (default BChE)
\t-lig \t\tLigand to be tested (exclude .mol) MANDATORY
\t-num \t\tStarting docking number (default set to 1)
\t-max \t\tNumber of trials to be ran (default set to 5000)
\t-tho \t\tthoroughness of job (default 1)
\t-h   \t\tprint help info and describe script steps
";

# set default values that can be overwritten #
$project = "BChE";
$ligand = "";
$initial = 1;
$max_run = 5000;
$thorough = 1;
$help = 0;

# get flags #
if(defined(@ARGV)) {
  @options = @ARGV;
  for ($i=0; $i<=$#ARGV; $i++) {
    $flag = $ARGV[$i];
    chomp $flag;
    if($flag eq "-pro"){ $i++; $project=$ARGV[$i]; next; }
    if($flag eq "-lig"){ $i++; $ligand=$ARGV[$i]; next; }
    if($flag eq "-num"){ $i++; $initial=$ARGV[$i]; next; }
    if($flag eq "-max"){ $i++; $max_run=$ARGV[$i]; next; }
    if($flag eq "-thorough"){ $i++; $thorough=$ARGV[$i]; next; }
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

if($ligand eq ""){ print "\n\tError: no ligand input defined\n\n"; exit(); }

# Start time #
$start = gmtime(time());
##########################

$script_home = $ENV{'PWD'};
$data_home = $script_home.'/'.$project.'/'.$ligand.'/';
$icm_home = "/home/username/icm-3.7-2b/";	     #CHANGE THIS TO DIRECT PATHWAY, ~ DOES NOT WORK

# reintialize the run #
$max_run = $max_run + $initial;

print $data_home."\n";
system("mkdir -p -v $data_home");

for($i=$initial; $i<=$max_run; $i++) {
   chdir $data_home;
   $obfile="rm $ligand"."_dock$i.ob";
   if(-e $ligand."_dock$i.ob") { system($obfile); }
   chdir $icm_home;
   system("./icm64 _dockScan $project input=$ligand.mol -s confs=50 thorough=$thorough outdir=$data_home");    
   chdir $data_home; 
   $obfile="mv $project"."_$ligand"."1.ob $ligand"."_dock$i.ob";
   system($obfile);
   $date = `date`;
   print "Docking $i complete ... $date\n\n";
}            

#Create ICM script
open(ICM,'>',$icm_home."temp.icm") || die "Please give me output filename $!"; #adjust the ICMscript 
print ICM "#!$icm_home"."icm64 -s\n";
print ICM "for i=$initial, $max_run\n"; 
print ICM "s_obname= \"$data_home$ligand"."_dock\"+i+\".ob\";\n";
print ICM "s_sdfname= \"$data_home$ligand"."_dock\"+i+\".sdf\";\n"; 
#print ICM 'read  stack s_cnfname'."\n";
print ICM 'read object s_obname'."\n";
print ICM 'load stack a_'."\n";
print ICM 'write Energy(stack) s_sdfname'."\n";
print ICM "endfor\n";
print ICM "quit\n";
close(ICM)||die $!;
#Ending creating ICM script

#running the command to generate sdf files that were used to created a file log file
chdir $icm_home;
system("./icm64 -s temp.icm"); 
#end running the command to generate sdf files

#create the final log file
chdir $data_home;

open(W,'>',"temp.log") || die "Please give me output filename $!";

for($index=$initial;$index<=$max_run;$index++)
{
   open(Read,'<',$ligand."_dock$index.sdf")||die $!;
   while($line=<Read>)
   {
      chomp($line);
      foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
      my @temp=split(' ',$line);
      $ICMscore = $temp[0];
      close(Read)||die $!;
   }
   print W $ligand."_dock$index\t$ICMscore\n";
}
close(W)||die $!;
$outputName=$project."_".$ligand.".log";
`sort -n -k2 temp.log > $outputName`;
`rm temp.log`;
chdir $icm_home;
system("rm temp.icm"); # Remove ICM script file.

$end = gmtime(time());
print "Start Process at $start\n";
print "End Process at   $end\n\n\n";

}
