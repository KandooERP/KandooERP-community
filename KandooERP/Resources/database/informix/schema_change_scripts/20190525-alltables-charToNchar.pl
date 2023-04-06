# description: this script is a global modif of all CHAR types to NCHAR type
# dependencies:
# tables list: all
# author: ericv
# date: 2019-05-25
# Ticket # :

use Getopt::Long;
use File::Basename;
use File::Spec;
use File::Copy;

if (!GetOptions(
	"since=s"=>\$SinceDate,
	"include=s"=>\$IncludeExpr,		# include will execute the scripts matching the expression and will not consider last patch date
	"exclude=s"=>\$ExcludeExpr,		# exclude will not  execute the scripts matching the expression and WILL consider last patch date
	"database=s"=>\$DatabaseName,
	"dbspace=s"=>\$DbspaceName,
	"logmode=s"=>\$LogMode,
	"tempDir=s"=>\$TempDir,
	"check"=>\$Check,
) ) {
	$a=1;
	exit (1);
}
if ( !defined($TempDir) ) {
	if ( $^O =~ /^win/i ) {
		$TempDir = "C:/temp" ;
	} else {
		$TempDir = "/tmp" ;
	}
}

if ( !defined($DatabaseName)) {
	$DatabaseName="kandoodb" ;
}

$DropDBFile = sprintf "%s/dropkandoodb.sql",$TempDir;

if (!defined($DbspaceName)) {
	$DbspaceName=$ENV{"DBSPACENAME"};
}

$dbExportDir=sprintf "%s/%s.exp",$TempDir,$DatabaseName;
$OriginalSqlFile=sprintf "%s/%s.sql",$dbExportDir,$DatabaseName;
$ModifiedSqlFile=sprintf "%s/%s.sqlmodif",$dbExportDir,$DatabaseName;
$BackupSqlFile=sprintf "%s/%s.sqlbackup",$dbExportDir,$DatabaseName;

if ( -e $OriginalSqlFile ) {
	$a=1;
} else {
	my $cmd = sprintf "cd %s;dbexport %s -ss",$TempDir,$DatabaseName;
	system($cmd);
}

open ORIGINAL,$OriginalSqlFile or die "Cannot open original sql file " . $OriginalSqlFile;
open BACKUP,">$BackupSqlFile" or die "Cannot open backup sql file " . $BackupSqlFile;
open MODIFIED,">$ModifiedSqlFile" or die "Cannot open backup sql file " . $ModifiedSqlFile;

printf "building new sql script\n";
while(<ORIGINAL> ) {
	printf BACKUP $_ ;
	if ( $_ !~ /create .*procedure|create .*function/i) {
		s/\schar\(/ nchar(/ ;
		s/\svarchar\(/ nvarchar(/ ;
	}
	print MODIFIED $_;
}	
 $a=1;
# copy the modified sql file to original one
copy $ModifiedSqlFile,$OriginalSqlFile;

if ( $? == 0 ) {
	printf "Now dbimporting the database with new modifs\n";
	open DROPDB,">$DropDBFile";
	printf DROPDB "drop database %s",$DatabaseName;
	my $cmd = sprintf "dbaccess sysmaster < %s ",$DropDBFile;
	system($cmd);
	if (defined($ENV{"LOGMODE"})) {
		$logMode=$ENV{"LOGMODE"};
	}
		
	my $cmd = sprintf "cd %s;dbimport %s -d %s %s",$TempDir,$DatabaseName,$DbspaceName,$logMode;
	system($cmd);
	if ( $? == 0 ) {
		printf "dbimport OK\n";
	} else {
		printf "dbimport failed\n";
	}
}

