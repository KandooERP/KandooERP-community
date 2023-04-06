#!/usr/bin/perl
# Description  :  this script builds a database schema in 4gl language
# (c) Copyright Begooden-IT Consulting 2010-2015
# Author eric.vercelletto@begooden-it.com
#  "@(#)$Id: fglbld_db_schema.pl 366 2016-07-24 14:49:46Z  $:"
# $Rev: 366 $:                                             last commit revision number
# $Date: 2016-07-24 16:49:46 +0200 (dim., 24 juil. 2016) $: last commit date
#
use Getopt::Long;
use Fcntl ':mode';
use File::Basename;
usage () if ( ! GetOptions(
	"database=s"=>\$DatabaseName,
	"outfile=s"=>\$OutFile,
	) ) ;

$INFORMIXDIR=$ENV{"INFORMIXDIR"} ;
if ( !defined($INFORMIXDIR) ) {
    die "Please export INFORMIXDIR environment variable" ;
}

if (!(defined($OutFile))) {
	$OutFile=sprintf "cr_database_%s.4gl",$DatabaseName;
}


$dbschemaCMD=sprintf "%s/bin/dbschema",$INFORMIXDIR;
if ( ! (-x $dbschemaCMD )) {
	die "You need the IBM Informix utility dbschema on this machine"
}
system("clear");
printf "Creating database schema 4gl moodule for database %s\n",$DatabaseName ;

$cmd=sprintf "%s/bin/dbschema -d %s|",$INFORMIXDIR,$DatabaseName;
open DBSCHEMA,$cmd or die "Cannot execute dbschema for this database " . $DatabaseName ;

if ( $OutFile !~ /\w+\.4gl$/ ) {
	$OutFile=sprintf "%s.4gl",basename($OutFile);
}
open OUTFILE,">$OutFile" or die "Cannot open ouput file name " . $OutFile ;
printf OUTFILE "MAIN\n\n";
$/ = ";" ;

while (<DBSCHEMA>) {
	next if ( /^$/ ) ;
   next if (!/create.*table\s/) ;
   s/\n{2,}/\n/;
   s/\"\w+\"\.//g;
   s/, +/,/g;
   s/ +/ /g;
   s/;//;
	s/\{\s+(TABLE.*?)\}/###\n## \\brief $1\n###/;
	s/create table/CREATE TABLE/i ;
	printf OUTFILE "%s\n",$_ ;
}
printf OUTFILE "END MAIN\n";
printf "\nDatabase schema module generated : %s\n",$OutFile ;
