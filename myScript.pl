#!/home/bif701_163a18/software/bin/perl

#Assignment Number 2
#BIF712[16-3]
#Thilukshan Udayakumar
#108796160
#Danny Abesdris
#Dec/13/2016
#Dec/9/2016

#Link to site:http://zenit.senecac.on.ca/~bif701_163a18/genbankForm.html 

#This assignment will retrieve a specific GenkBank file from http://www.ncbi.nlm.nih.gov 
#and send back an HTML page that displays the desired information from a specific GenBank record
#for a virus based on the selection made by the user. The program will also email the user 
#the results of their query.  

#Oath:

#Student Assignment Submission Form
#==================================
#I/we declare that the attached assignment is wholly my/our
#own work in accordance with Seneca Academic Policy.  No part of this
#assignment has been copied manually or electronically from any
#other source (including web sites) or distributed to other students.

#Name(s) Thilukshan Udayakumar          Student ID(s) 108796160

#---------------------------------------------------------------

use strict;
use warnings;

use CGI;
use LWP::Simple;
use Mail::Sendmail;

# The Content-type: directive is required by the web-server to tell the
# browser the type of data stream that is being processed!
# The Content-type: directive MUST appear before ANY output and must be
# appended with two (2) newlines!!!

my $cgi = new CGI;
my (@attributes, $checkAll $tmpAttr, $baseURL, $genbankFile, $virus, $ncbiURL, $rawData, $baseCount);
my (@tmpArray, @genbankData, $start, $i, $result);



print "Content-type: text/html\n\n";

print "<html><head><title>Genbank Results...</title></head>\n";
print "<body><pre>\n";

my $email = $cgi->param('mailto');                                        #Records the email entered

if (isCorrectFormat($email)) {                                                 #Uses the subroutine to check if the email is the correct format       
   @attributes = $cgi->param('attributes');
   $checkAll = $cgi->param('CHECKALL');                                #If the format is correct the body of the program will execute 
   $virus = $cgi->param('viruses');                                         #If the format is incorrect an error message will be displayed and the main body of the program
                                                                                            #will not execute 
   $baseURL = "ftp://ftp.ncbi.nih.gov/genomes/Viruses/";


   #print "Test Genbank solution\n";
   #print "virus selected is: '$virus'\n";
   $ncbiURL = $baseURL . $virus;
   print("full URL: $ncbiURL \n");


   @tmpArray = split('/', $virus);  # capture the accession number from the string
   $genbankFile = $tmpArray[1];     # the 2nd element of the array after the split '/'
   #print "genbank file to write is: $genbankFile\n";

   unless(-e $genbankFile) {
      $rawData = get($ncbiURL); # this function should download the genbank file
                             # and store it in the current working directory
      open(FD, "> $genbankFile") || die("Error opening file... $genbankFile $!\n");
      print FD $rawData;
      close(FD);
   }

   # slurp the genbank file into a scalar!
   $/ = undef;
   open(FD, "< $genbankFile") || die("Error opening file... $genbankFile $!\n");
   $rawData = <FD>;
   close(FD);

   $result = "";
   $start = 1;
   $i = 1;
   
   if($checkAll eq 'on'){							    #Checks to see if checkall was selected. If checkall was chosen then all the contents
      result.=$rawData;								#of the file will be printed to the screen and then sent to the user. 
      print "$rawData";	  
	  my %mail = ( To      => "$email",
                            From    => 'my.seneca.id@myseneca.ca',
                            Message => "$result"
                          );

      sendmail(%mail) or die $Mail::Sendmail::error;
      print "OK! Sent mail message...\n";
   }
   else {									                                #Loops through each element in attributes and prints the appropriate section
      foreach $tmpAttr (@attributes) {					        #to the screen and records the result in a variable to be later returned to the user
         if($tmpAttr =~ /LOCUS/) {						        #through email
            $rawData =~ /(LOCUS.*)DEFINITION/s;
            print "$1";
            $result .= $1;                     
         }
         elsif($tmpAttr =~ /DEFINITION/) {
            $rawData =~ /(DEFINITION.*)ACCESSION/s;
            $result .= $1;
            print "$1";
         }
         elsif($tmpAttr =~ /ACCESSION/) {
            $rawData =~ /(ACCESSION.*)VERSION/s;
            $result .= $1;
            print "$1";
         }
         elsif($tmpAttr =~ /VERSION/) {
            $rawData =~ /(VERSION.*)DBLINK/s;
            $result .= $1;
            print "$1";
         }
         elsif($tmpAttr =~ /KEYWORDS/) {
            $rawData =~ /(KEYWORDS.*)SOURCE/s;
            $result .= $1;
            print "$1";
         }
         elsif($tmpAttr =~ /SOURCE/) {
            $rawData =~ /(SOURCE.*)ORGANISM/s;
            $result .= $1;
            print "$1";
         }
         elsif($tmpAttr =~ /ORGANISM/) {
            $rawData =~ /(ORGANISM.*?)REFERENCE/s;
            $result .= $1;
            print "$1";
         }
         elsif($tmpAttr =~ /REFERENCE/) {
            $rawData =~ /(REFERENCE.*)COMMENT/gs;
            $result .= $1;
            print "$1";
         }
         elsif($tmpAttr =~ /AUTHORS/) {
            while($rawData =~ m/(AUTHORS.*?)TITLE/gs){
               $result .= $1;
               print "$1";
            }
         }
         elsif($tmpAttr =~ /TITLE/) {
            while( $rawData =~ m/(TITLE.*?)JOURNAL/gs){
               $result .= $1;
               print "$1";
            }
         }
         elsif($tmpAttr =~ /JOURNAL/) {
            while($rawData =~ /(JOURNAL.*?)(PUBMED|REFERENCE|COMMENT|REMARK)/gs{         #JOURNAL does not always
               $result .= $1;						                                                                                      #stop at the same point for each entry
               print "$1";							                                                                                      #so an or was used to account for the different cases
            }
         }
         elsif($tmpAttr =~ /PUBMED/) {
            while($rawData =~ /(PUBMED.*?)REFERENCE/s){
               $result .= $1;
               print "$1";
            }
         }
         elsif($tmpAttr =~ /FEATURES/) {
            $rawData =~ /(FEATURES.*)ORIGIN/s;
            $result .= $1;
            print "$1";
         }
         elsif($tmpAttr =~ /ORIGIN/) {
            $rawData =~ /(ORIGIN.*)\/\//gs;
            $result .= $1;
            print "$1";
         }
         elsif($tmpAttr =~ /BASECOUNT/) {
            print($baseCount = (baseCounter($rawData)));		#Calls the sub function baseCounter to count the number of base pairs
            $result .= $baseCount;
         }
      }

								#Emails the user the results 
      my %mail = ( To      => "$email",
                   From    => 'my.seneca.id@myseneca.ca',
                   Message => "$result"
                 );

      sendmail(%mail) or die $Mail::Sendmail::error;
      print "OK! Sent mail message...\n";
   }
}
else {
                                                                                                                                                                                                          
   print "Error! Not a valid email format.";

}

#Subroutine to determine if the email follows the correct format
sub isCorrectFormat($){

   my $email1 = shift(@_);
   return($email1 =~ m /[a-zA-Z0-9\-\.]{2,}\@[a-zA-Z0-9\-\.]{2,}\.[a-zA-Z]{2,4}/);

}

#Subrountine to count the number of base pairs
sub baseCounter($) {

   my ($acount, $ccount, $tcount, $gcount, $sequence);
   $sequence = shift(@_);
   $sequence =~ /(ORIGIN.*)\/\//sg;				    #Takes in the sequence 
   for (my  $i=0; $i<=length($1); $i++) {			#Loops through the sequence and checks each value and counts the number of a, c, t, g that are found
      if(substr($1, $i, 1) eq 'a'){
         $acount++;
      }
      elsif(substr($1, $i, 1) eq 'c'){
         $ccount++;
      }
      elsif(substr($1, $i, 1) eq 't'){
         $tcount++;
      }
      elsif(substr($1, $i, 1) eq 'g'){
         $gcount++;
      }
   }
   return("Base Count: A:  $acount C:  $ccount T:  $tcount G: $gcount \n ");		#Returns the values found 
}

print "</pre></body></html>\n";                                                                                                            

                                                                                                                                                                     
