#Fixed memory issue and email issue#
#------------------------------------------------------------------------------------------------#
#

#!/usr/bin/perl
use strict;
#use warnings;
use POSIX qw(strftime);
use Time::Piece;
use LWP::Simple;
#use JIRA::REST;
#use REST::Client;
#use LWP::UserAgent;
use JIRA::Client::Automated;
use MIME::Base64;
#my $xx = " " x  1024;
#{
#-----------------------------+  Global Declarations +--------------------------------------------#
my $start_run = time();

#Original Script Path LogMonitor.pl
my $Home_Path=`pwd`;

$Home_Path =~s/\s+$//;
$Home_Path =~ s/\n//g;
#my $test = "$Home_Path/Config/$ARGV[0]";
#print "\n $test \n\n";

# Reading Config File from Command line
my @Conf = `cat $Home_Path/Config/$ARGV[0]`;

#All Global Variables
my ($format,$Log_Path,$app,$e,$lines,$bklines,$email,$log,$fsize,$loglevel,$threshold,$email1,$email2,$exclude);
#Only for splitting purpose variables , not used  in the script
my ($aa0,$aa1,$aa2,$aa3,$aa4,$aa5,$aa6,$aa7,$aa8,$aa9,$aa10,$aa11,$aa12,$aa13);

#-----------------------------+  Reading Config File  +--------------------------------------------#
#Reading values from Config file into local variables.
for( my $i=0; $i < @Conf; $i++ )
{

 $Conf[$i] =~ s/\n//g;

($aa0, $log)      = split(/=/,$Conf[0]);	# Current log file 
($aa1, $app)        = split(/=/,$Conf[1]);	# Application Name
($aa2, $Log_Path)   = split(/=/,$Conf[2]);	# Location of the  Log Files.
($aa3, $format)	    = split(/=/,$Conf[3]);	# Log File format i.e zip or .gzip
($aa4, $e) 	    = split(/=/,$Conf[4]);	# Search Patterns 
($aa5, $lines)      = split(/=/,$Conf[5]);	# Number of lines after Matching the pattern
($aa6, $bklines)    = split(/=/,$Conf[6]);	# Number of lines befor Matching Pattern
($aa7, $email)       = split(/=/,$Conf[7]);	# List of email addresses to send  Exception Report
($aa8, $fsize)       = split(/=/,$Conf[8]);	# Max file size to raise  the alert mails. 
($aa9, $loglevel)   = split(/=/,$Conf[9]);	# Mode of the log file. 
($aa10, $threshold) = split(/=/,$Conf[10]);	# Time to test the Log file Mode. 
($aa11, $email1)    = split(/=/,$Conf[11]);	# To send the Log file size.
($aa12, $email2)    = split(/=/,$Conf[12]);	# To send the Log file mode.
($aa13, $exclude)   = split(/=/,$Conf[13]);     # Patterns to be excluded
}

#-----------------------------+  Reading Config File  +--------------------------------------------#

$Log_Path =~s/\s+$//;
$Log_Path =~ s/\n//g;

$log =~s/\s+$//;

my $appf = $app."_Temp";
$app=~s/\s+$//;
$appf =~s/\s+$//;
$appf =~ s/\n//g;

my $Timestamp = $app."_Timestamp.txt";
$Timestamp=~ s/\n//g;
$Timestamp=~s/\s+$//;

my $cronfile  = $app."_runonce.txt"; 	# To maintain the flag value of the logger level code.

my $LogInput  = $app."_LogInput.txt";	# It holds the content of the all log files,And will pass as a input file.

my @time =`cat $Log_Path/$Timestamp`;	# Read time from Timestamp File.

#converting the timestamp to required format to compare in logs
my $Ttime = localtime->strftime("\"$time[1]\"", "%Y-%m-%d_%H:%M:%S");


my @m         = split(/\,/, $e);                # It holds the search patterns.
my @ep	      = split(/\,/, $exclude);          # It holds the list of patterns to be excluded.
my $date      = strftime "%Y-%m-%d", localtime;	
my $Prev_Logs = $log."-".$date.".*.".$format;	# Creating the file name


my $Temp = $app."Temp.txt";
$Temp =~ s/\n//g;

system ("find $Log_Path/$app* -newer $Log_Path/$Timestamp>> $Home_Path/Temp/$Temp 2>/dev/null");#finding all the files which are modified after the last run
#system ("find $app* -newer $Timestamp>> $Home_Path/Temp/$Temp 2>/dev/null");#finding all the files which are modified after the last run

#To find Last Reading Line of the file from latest generated log files. 
my @files = `cat $Home_Path/Temp/$Temp | sort`;
print @files;

system("rm $Home_Path/Temp/$Temp 2>/dev/null");

system("rm $LogInput 2>/dev/null"); 		
my $filename = $files[0]; 			                     

print "$filename \n";

my $appfolder = "$Home_Path/Temp/$app";
$appfolder =~s/\s+$//;
$appfolder =~ s/\n//g;

#my $appTempFolder = $appfolder."_Temp";
my $appdir = $appfolder."_Temp";
  $appdir =~ s/\n//g;
  $appdir =~s/\s+$//;

#-----------Find the current log file size --------------------------------------------------------#
my ($size,$z,$ksize,$msize,$newpath,$logfilesize);

$newpath = "$Log_Path/$log";

$newpath =~s/\s+$//;
$newpath =~ s/\n//g;

$size = `du -sh $newpath`;

($ksize, $z) = split(/\s+/,$size);

($msize, $z) = split(/[KMG]/,$ksize);

$logfilesize = $msize/1024;

if( $logfilesize >= 100 )
{
 print "File size is crossed 100 MB $logfilesize, script will not continue further, need to send an email here" ;
 exit;
}
elsif( $logfilesize < 100)
{

#-----------------------------+  Finding Log File Type  +--------------------------------------------#


        system(" rm -rf $Home_Path/Temp/$app* 2>/dev/null");
          `mkdir $appdir`;
          `chmod 777 $appdir`;
        
if( $filename =~ m/.zip/ ) 
{
#      	system("unzip $filename 2>/dev/null");
        $filename =~s/\s+$//;        
        $filename =~ s/\n//g;
        system("unzip $filename -d $appdir 2>>/dev/null");
 	$filename =~ s/.zip//g;
        $filename =~ s/$Log_Path/$appdir/g;
}
elsif( $filename =~ m/.gz/ )
{
        $filename =~s/\s+$//;
        $filename =~ s/\n//g;
	my $nfile = $filename;
	$nfile =~ s/.gz//g;
	$nfile =~ s/$Log_Path/$appdir/g;
        $nfile =~s/\s+$//;
        $nfile =~ s/\n//g;
        `gunzip -c $filename > $nfile 2>>/dev/null`;
        $filename =~ s/.gz//g;
        $filename =~ s/$Log_Path/$appdir/g;
#       print "\n first time filename \n $filename";
}
$filename =~s/\s+$//;
$filename =~ s/\n//g;
#$filename =~ s/" "//g;


#Generate $app_LogInput.txt file by reading the content from first file after the last run. 
open (my $OUT , ">>" , $LogInput) || die "File $LogInput file not found $!"; 


my $Logtime;				# To Read Time Content from  the Log files.
my $NewTime;				 


# Reading file, which is generated first after the last run.
#open(my $fh1, "<", $Log_Path/$filename) || die "File not found $!";
open(my $fh1, "<", $filename) || die "No new logs were written $!";

	while(<$fh1>)
	{
		#Finding first line file after the last run. 
 		if ($_ =~ /(\d\d\d\d)-(\d\d)-(\d\d)_(\d\d):(\d\d):(\d\d)/)
 		{

    			$Logtime = substr $_, 0, 19;

    			$NewTime = localtime->strftime("\"$Logtime\"", "%Y-%m-%d_%H:%M:%S");

 			if ($NewTime gt $Ttime)
			{
       				print $OUT $_;

       				while(<$fh1>)
				{
    					print $OUT $_;  
				}
     			}
 		}
	}

close($fh1);


#-----------+  Reading the contenet from 2nd file on wards in the array  +-----------------------------#
my @gzfiles;
for ( my $i=1; $i < @files; $i++ )  
{

  if ( $files[$i] =~ m/.zip/ )
  {
        $files[$i] =~s/\s+$//;
        $files[$i] =~ s/\n//g;
    	system("unzip $files[$i] -d $appdir 2>>/dev/null");		# unzip the files
    	$files[$i] =~ s/.zip//g;
        $files[$i] =~ s/$Log_Path/$appdir/g;
  }
  elsif ( $files[$i] =~ m/.gz/ )
  {
        $files[$i] =~s/\s+$//;
        $files[$i] =~ s/\n//g;
        $gzfiles[$i] = $files[$i];
        $gzfiles[$i] =~ s/.gz//g;
        $gzfiles[$i] =~ s/$Log_Path/$appdir/g;
        $gzfiles[$i] =~s/\s+$//;
        $gzfiles[$i] =~ s/\n//g;
        `gunzip -c $files[$i] > $gzfiles[$i] 2>>/dev/null`;       #gunzip the files 
  	$files[$i] =~ s/.gz//g;
        $files[$i] =~ s/$Log_Path/$appdir/g;
  }
  $files[$i] =~s/\s+$//;
  $files[$i] =~ s/\n//g;
#  $files[$i] =~ s/" "//g;


# Appending  the content to $app_LogInput.txt file by reading rest of the file in @files. 
  open( my $FH , "<" , $files[$i] ) || die "File not found $!";
  while (<$FH>)
  {
       print $OUT $_ ;
  }
  close($FH);


}
close($OUT);

#------------------------------+  Searching Patterns in $app_LogInput.txt  +-----------------------------#

my $Errors = $app."_Exceptions_".$date.".txt";		# Exceptions Output File.
$Errors =~s/\s+$//;
#system("rm $Errors 2>/dev/null");
system("rm *Exceptions* 2>/dev/null");

open(my $FL , "<" , $LogInput ) || die "File $LogInput not found $!"; #open the file to perform pattern matching
chomp(my @content=<$FL>);
my $l=$.;
#print $l;
close ($FL);


open (my $ERR , ">>" , $Errors ) || die "File $Errors not found $!";
print $ERR "Hi Team \n\n Please find the exceptions as mentioned below\n";
print $ERR "\n=================== Exceptions List =====================================\n";

my $c=0;
my $Exno=0;
for(my $i=0; $i < scalar(@m); $i++ )
{
 for(my $i1=0; $i1 < scalar(@ep); $i1++)
 {
#$m[$i] =~ s/" "//g;
#$m[$i]=~s/\s+$//;
$m[$i] =~ s/\n//g;
$ep[$i1] =~ s/\n//g;

$bklines=~s/\s+$//;
$bklines =~ s/\n//g;
$lines=~s/\s+$//;
$lines =~ s/\n//g;

open(my $F , "<" , $LogInput ) || die "File $LogInput not found $!"; #open the file to perform pattern matching

my (@bb,$cc);
my $ind=0;


while(<$F>)
{
#  if($_ =~ m/$m[$i]/ ) #When the pattern is matched follow this loop
# if ($_ = '^(?=.*?/$m[i]/)((?!$exclude).)*$.')
  if($_ =~ m/$m[$i]/ && $_ !~ m/$ep[$i1]/ ) 
  {

                 $Exno = $Exno + 1; #counter for no.of exceptions
                print $ERR "\nException : $Exno \n";
                $cc = scalar(@bb);

                for(my $j = $cc - $bklines; $j <@bb; $j++ )
                        {
                                print $ERR " $bb[ $j ]";
                                print " $bb[ $j ] \n";
                        }
                        undef @bb;
                        $ind = 0;
                        while($c <= $lines )#print required no.of lines after the pattern 
                        {
                         print $ERR $_ ;
                         $_ = <$F>;
                         $c = $c +1;
                        }
                      $c=0;

                print $ERR "\n====================== End of Exception $Exno =================================================\n";
    }
     else #***When the pattern is not matched store the lines here for backward reading
     {
       if( $ind < $bklines )
                {
                        $bb[ $ind ] = $_;
                }
       else
                {
                        undef $bb[ scalar(@bb)- $bklines ];
                        $bb[ $ind ] = $_;

                }
                $ind = $ind + 1;
      }
}
close($F);
}
}
my $logsize = `du -sh $Log_Path/$log`;

my $foldersize = `du -sh $Log_Path`; #Entire log folder size
my ($nsize,$s);
($nsize, $s) = split(/\s+/,$foldersize);

#print $ERR "\n\nLog folder size is $nsize.\n";

#print $ERR "\n\nCurrent log file size for $app is $logsize.\n";

close($ERR);
system("chmod 777 $LogInput");
system("rm $LogInput");
system("chmod 777 *Exceptions* 2>/dev/null");
#===============================Updating Timestamp for next run ===========================
system ("rm $Log_Path/$Timestamp 2>/dev/null");

my $dummy = "modified now\n";
system ("chmod 777 $Log_Path/$Timestamp 2>/dev/null");

open (my $FILE, ">>", "$Log_Path/$Timestamp") || die "file not found $!";
print $FILE $dummy;
my $tstamp=(`stat -c %y $Log_Path/$Timestamp | cut -d . -f 1`);
chomp $tstamp;
my $t=localtime->strftime("\"$tstamp\"", "%Y_%m_%d %H:%M:%S");
my $a=localtime->strftime("%Y-%m-%d_%H:%M:%S");
print $FILE $a;

close ($FILE);
#============================File size of input file =====================================
if ($logfilesize > $fsize) {

#system ("mutt  -s \"Email for internal file Size\"  $email2 < \"Input log file size is $logfilesize , this is used by the script \n\"");
system ("echo \"Input log file size is $logfilesize , this is used by the script \n\" | mailx -s \"Email for internal file Size\" $email2");
#system ("echo \"Input log file size is $logfilesize , this is used by the script \n\" | mutt -s \"Email for internal file Size\" $email2");
}
#===========================Exlcuding keywords and Sending emails ================================================
my @emailids = split(/,/,$email);

if ($Exno > 0)
{

    for (my $p=0; $p<@emailids; $p++)
     {
      #system("mutt -s \"Exception report for $app \"  $emailids[$p] < ./$Errors");
#      system("cat $Errors | mailx -e -s \"Exceptions report for $app \" -c $emailids[$p]");
     system("cat $Errors | mutt  -s \"Exceptions report for $app \" purnima.chinni\@zyme.com -c $emailids[$p]");
     }
}
#=========================sending sms alerts =======================================
my $msgtext;
$msgtext = "DuplicateKeyException: SqlMapClient operation; SQL []; Duplicate entry '2' for key 'PRIMARY'; nested exception is java.sql.BatchUpdateExce";
#my $cnt=0;
#my $r=0;
#open(my $SF , "<" , $Errors ) || die "File not found $!";
#while (<$SF>)
#{     
# if ($_ =~ m/Exception/)
# {
#  $cnt = $cnt+1;
#   if ($cnt=1)
#   {
#     print $msgtext $_;
#     close $SF;
#    }
#  }
#}
   print "messge txt is :$msgtext \n";
    my $apiKey = "apikey=" . 'jnWHED0BVRY-02ZIpWSpO0qSxlJ4lB05lBqzQhsRO3';
    my $message = "&message=" . $msgtext;
    #my $sender = "&sender=" . "TXTLCL";
    my $number = "&numbers=" . "919972420386";
    my $test = "true";
     
   my $getString = join "", "https://api.textlocal.in/send/?", $apiKey, $message , $number, $test;
   my $contents = get($getString);
   print "$contents \n";
#========================Creating JIRA tickets ============================================
my $url='https://zymespl.atlassian.net';
my $user = 'purnima.chinni@zyme.com';
my $password = '23*Kiran';

my $jira = JIRA::Client::Automated->new($url, $user, $password);

my $key = 'TDAW';
my $type ='Bug';
my $summary = 'Duplicate entry for primary key exception found in TDAWB log';
my $description = 'This is for testing creation of JIRA tickets using log monitoring demo';
my $assignee = 'pchinni';
my $Priority = 'Critical';
#my @version = ("TDAW - 7.9.3");

my $issue = $jira->create({
    # Jira issue 'fields' hash
     project     => {
         key => $key,
    },
    issuetype   => {
	name => $type,      # "Bug", "Task", "SubTask", etc.
       },
    summary     => $summary,
    description => $description,
    assignee => { name => $assignee},
    priority => { name => $Priority},
    fixVersions => [{ id => "26601"}]
});
print "JIRA ticket has been created successfully\n";
#=========================Alerting logger level============================================

my @level = split(/\W/, $loglevel);
my $Rtime = (stat $cronfile)[9];#find last modified time of runonce file

my $ctime = time(); #current system time
my $startvalue = $ctime-$Rtime;
#my $NF;

my $currentlog = "$Log_Path/$log";

if ($startvalue >= $threshold) #Execute logger level info code only once in 24 hrs
{
open (my $NF , ">", $cronfile) || die "file not found $!";

for (my $k=0; $k < scalar(@level); $k++)
{

open(my $F1 , "<", $currentlog ) || die "file not found $!";
   while( <$F1> )
   {
                if( $_ =~ m/$level[$k]/ )
                {
                        print $_."\n";
                       # system ("echo \"Logger level info for $app \" | mail -s \"Logger level is $level[$k]\" $email1");
                       system ("echo \"Logger level for $app is set to $level[$k] \" | mailx -s \"Logger level info for $app\" $email1");
                        print $NF 1;
                }
                last;
    }
        close($F1,$NF);
}
}
#close($NF);
}
my $end_run = time();
my $run_time = $end_run - $start_run;
print "Script execution time took $run_time seconds\n";
#===================================================+ END OF THE SCRIPT +======================================#
#
#}
#system("rm *Exceptions*.txt");
exit;
