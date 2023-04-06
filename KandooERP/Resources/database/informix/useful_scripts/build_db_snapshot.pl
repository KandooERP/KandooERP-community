use Getopt::Long;
use File::Basename;
use File::Copy;
use File::Spec;
use Cwd;
use Cwd 'abs_path';

if (!GetOptions(
	# "setdate=s"=>\$ThisSnapshotDate,
	"sourcedatabasename=s"=>\$SourceDatabaseName,	# will do a dbexport of this database 
	"targetdatabasename=s"=>\$TargetDatabaseName,	# will rename the .exp directory and the .exp/dbname.sql to this value ((thisvalue).exp/(thisvalue).sql.No value will generate kandoodb.exp/kandoodb.sql
	"destinationfolder=s"=>\$DestinationFolder,		# will place the .exp folder in /Resources/database/informix/db_snapshots/(thisvalue)_database. No value will generate (sourcedatabasename)_database
	"snapshotfolder=s"=>\$SnapshotsFolder,		# will place the .exp folder in /Resources/database/informix/db_snapshots/(thisvalue)_database. No value will generate (sourcedatabasename)_database
	"zip"=>\$DoZipExport,				# will zip the contents of the .exp folder (and remove the .exp folder)
	"convert"=>\$ConvToUTF8,			# will convert files to utf8 if not done yet. Normally not necessary
	"exitifnonews"=>\$ExitIfNothingNew,		# exit if no modif on database since last snapshot
) ) {
	$a=1;
	exit (1);
}
if ( $^O =~ /win/i ) {
	$TempDir = "C:\temp" ;
}else {
	$TempDir = "/tmp" ;
}
if ( !defined($SourceDatabaseName)) {
	$SourceDatabaseName="kandoodb_reference" ;
}
if ( !defined($TargetDatabaseName)) {
	$TargetDatabaseName="kandoodb" ;
}

if ( !defined($DbVendor)) {
	$DbVendor="informix" ;
}

if (!defined($SnapshotsFolder)) {
	$SnapshotsFolder=sprintf "%s/../db_snapshots/",getcwd;
	$SnapshotsFolder=abs_path($SnapshotsFolder);
}

if (!defined($DestinationFolder)) {
	if ( $SourceDatabaseName =~ /kandoodb_(\w+)/) {
		$SourceDbSuffix=$1;
	} else {
		die "The database name must start with kandoodb_";
	}
} else {
	 $SourceDbSuffix=$DestinationFolder;
}

$SnapshotDir=sprintf "%s/%s_database/",$SnapshotsFolder,$SourceDbSuffix;

if (! -d  $SnapshotDir ) {
	mkdir $SnapshotDir;
}
$NewExportDir=sprintf "%s/%s.exp",$SnapshotDir,$TargetDatabaseName;
$OldExportDir=sprintf "%s/%s.exp",$SnapshotDir,$SourceDatabaseName;

$DatabaseName=$SourceDatabaseName;
$ThisDBSnapshotDateFile=sprintf "%s/lastsnapshot",$SnapshotDir;
if ( -r $ThisDBSnapshotDateFile ) {
	open SNAPSHOT,$ThisDBSnapshotDateFile ;
	@SnapshotData=<SNAPSHOT>;
	if ( $SnapshotData[0] =~ /^(20\d\d\d\d\d\d)\s+/ ) {
		$LastSnapshotDateForThisDB=$1;
	}

	close SNAPSHOT ;
} else {
	# set a very old last snapshot date
	$LastSnapshotDateForThisDB="20000101";
}
if ( !defined($ThisSnapshotDate)) {
	my $Statement = sprintf "select max(created) from systables where tabid > 99 ";
	($status,@LastTableSchemaModification) = execute_select_statement ($DatabaseName,$Statement) ;
	if ( $LastTableSchemaModification[0] !~ /^\|$/ ) {
		$ThisTableSchemaModifDate = $LastTableSchemaModification[0];
		$ThisTableSchemaModifDate =~ s/\|$// ;
		$ThisTableSchemaModifDateTime = date_to_datetime($ThisTableSchemaModifDate); # return date as yyyymmdd format
	}
	# this snapshot date takes the date of the last fix applied by apply_db_fix.pl
	# First check if some patch ran bad, then take this date as a reference
	# If all patches are OK, then take last patch apply date
	my $Statement = sprintf "select min(fix_create_date) from dbschema_fix where fix_dbsname = \"%s\" and fix_status in (\"KO\",\"KOF\",\"WAD\")",$SourceDatabaseName;
	($status,@LastFix_Date) = execute_select_statement ($DatabaseName,$Statement) ;
	# the snapshot date is based on the date of the last applied fix (taken from file name)
	if ( $LastFix_Date[0] !~ /^\|$/ ) {
		$ThisSnapshotDate = $LastFix_Date[0];
		$ThisSnapshotDate =~ s/\|$// ;
		$ThisSnapshotDateTime = date_to_datetime($ThisSnapshotDate); # return date as yyyymmdd format
	}else {
		my $Statement = sprintf "select max(fix_create_date) from dbschema_fix where fix_dbsname = \"%s\" and fix_status matches \"OK\*\"",$SourceDatabaseName;
		($status,@LastFix_Date) = execute_select_statement ($DatabaseName,$Statement) ;
		if ( $LastFix_Date[0] !~ /^\|$/ ) {
			$ThisSnapshotDate =~ s/\|$// ;
			$ThisSnapshotDateTime = date_to_datetime($ThisSnapshotDate); # return date as yyyymmdd format
		} else {
			printf "No fix have been applied since the last snapshot, stopping snapshot!\n";
			exit(0);
		}
	}

	# if there has been no actual modifications on the database since last snapshot => exit
	if ( $ThisTableSchemaModifDateTime < $LastSnapshotDateForThisDB && defined ($ExitIfNothingNew)) {
		printf "No new database patch done since last snapshot\n";
		exit(0);
	}
}

# force DBDATE for this process so that date are always handled the same way
$ENV{"DBDATE"} ="dmy4/" ;
$ENV{"CLIENT_LOCALE"}="en_US.utf8";
$ENV{"DB_LOCALE"}="en_US.utf8";

# first test exclusive connection to database, if not possible, exit
my $stmt = sprintf "database %s exclusive",$DatabaseName;
($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);
if ( $status != 0 ) {
	die "Cannot perform snapshot with users connected, please log them out";
}
#

# check date of database snapshot
my $Statement = sprintf "select snapshot_date from dbschema_properties where dbsname = \"%s\"",$DatabaseName;
($status,@Creation_Date) = execute_select_statement ($DatabaseName,$Statement) ;
$CreationDate = date_to_datetime($Creation_Date[0]); # return date as yyyymmdd format
printf STDOUT "Database %s has been created on %s\n",$DatabaseName,$Creation_Date[0] ;

# check date of last patch apply
my $Statement = sprintf "select last_patch_date from dbschema_properties where dbsname = \"%s\"",$DatabaseName;
($status,@LastPatch_Date) = execute_select_statement ($DatabaseName,$Statement) ;
$LastPatchDateTime = date_to_datetime($LastPatch_Date[0]); # return date as yyyymmdd format
$LastPatchDate = $LastPatch_Date[0]; 
$LastPatchDate =~ s/\|// ;
printf STDOUT "Last patch for %s has been applied on %s\n",$DatabaseName,$LastPatchDate ;
#printf STDOUT "Last patch for %s has been applied on %s\n",$DatabaseName,$LastPatch_Date[0] ;
$a=1;
#Keep those values to reapply at the end (I want to keep my values)

$LogFile=sprintf "%s.log",$0 ;
$LogFile =~ s/\.pl//;
open LOGFILE,">>$LogFile" or die "cannot open log file " ;
$InDir = ".";
printf STDOUT "performing database snapshot stamped as %s\n",$DatabaseName;

# Get Kandoo build ID from somewhere
$BuildID="N/A";

# cleanup previous version
if ( -d $NewExportDir ) {
	$cmd=sprintf "rm -rf %s 1>/dev/null;",$NewExportDir;
	system($cmd);
}
if ( -d $OldExportDir ) {
	$cmd=sprintf "rm -rf %s 1>/dev/null;",$OldExportDir;
	system($cmd);
}

# run the dbexport
$cmd=sprintf "cd %s;dbexport %s 1>/dev/null;",$SnapshotDir,$DatabaseName;
$TS_Start = time () ;
$StartTSStr = utc_to_datetime($TS_Start);
printf STDOUT "%s Starting dbexport of database %s\n",$StartTSStr,$DatabaseName;
printf LOGFILE "%s Starting dbexport of database %s\n",$StartTSStr,$DatabaseName;
$status=system($cmd);
if ( $status == 0 ) {
	printf STDOUT "%s Finished dbexport of database %s\n",utc_to_datetime(time()),$DatabaseName;
	printf LOGFILE "%s Finished dbexport of database %s\n",utc_to_datetime(time()),$DatabaseName;
	if (defined($ConvToUTF8) ) {
		
		$status= convert_export_to_utf8($SnapshotDir,$DatabaseName);
	}
	# in the dbschema_fix and dbschema_properties unload files, change 
	($properties_file,$properties_rows_number)=GetUnloadFileInfo($DatabaseName,"dbschema_properties");	
	($fix_file,$fix_rows_number)=GetUnloadFileInfo($DatabaseName,"dbschema_fix");	

	# if Source name <> Target name then : 
	if ( $SourceDatabaseName ne $TargetDatabaseName ) {
		# cleanup dbschema_fix file, removing patches before last_patch_date
		$dbschema_fix_lines_number = CleanUpDbschemafix( $fix_file,$ThisSnapshotDateTime);
		$dbschema_properties_lines_number = CleanUpDbschemaproperties( $properties_file,$ThisSnapshotDate);

		# change .exp directory to target name
		move ($OldExportDir,$NewExportDir) ;
		#
		# change .sql file name to target name
		$SqlFile=sprintf "%s/%s.sql",$NewExportDir,$SourceDatabaseName;
		$NewSqlFile=sprintf "%s/%s.sql",$NewExportDir,$TargetDatabaseName;
		move ($SqlFile, $NewSqlFile) ;
		$status=FixNewSqlFile($NewSqlFile,$TargetDatabaseName,basename($fix_file),$dbschema_fix_lines_number);
	}

	# rename the .exp directory and the .sql file

	if (defined($DoZipExport)) {
		#$cmd =  sprintf "cd %s;zip -9 -r %s.zip %s.exp/* 1>/dev/null",$SnapshotDir,$NewExportDir,$NewExportDir;
		$cmd =  sprintf "cd %s;zip -9 -r %s.zip %s.exp/* ",$SnapshotDir,$NewExportDir,$NewExportDir;
		printf STDOUT "%s Starting compression of database %s\n",utc_to_datetime(time()),$DatabaseName;
		printf LOGFILE "%s Starting compression of database %s\n",utc_to_datetime(time()),$DatabaseName;
		$status=system($cmd);
		printf STDOUT "%s Finished compression of database %s\n",utc_to_datetime(time()),$DatabaseName;
		printf LOGFILE "%s Finished compression of database %s\n",utc_to_datetime(time()),$DatabaseName;
		# removing export directory
		$cmd = sprintf "rm -rf %s/%s.exp",$NewExportDir;
		system($cmd);
	}	
	printf "snapshot of database %s has placed in %s%s.exp\n",$SourceDatabaseName,$SnapshotDir,$TargetDatabaseName;
	open SNAPSHOT,">$ThisDBSnapshotDateFile" or die "Cannot write into timestamp file";
	if (utc_to_datetime(time()) =~ /^(\d\d\d\d)-(\d\d)-(\d\d)/) {
		$ThisSnapshotDateTime = $1.$2.$3;
	}
	printf SNAPSHOT "%s\t%s\n",$ThisSnapshotDateTime,$SourceDatabaseName;
	}else {
	close SNAPSHOT;
}


# convert informix date to yyyymmdd format (for sort etc)
sub date_to_datetime {
my $indate = $_[0] ;
my $datetime_value="";
$DbDate=$ENV{"DBDATE"} ;
if ($DbDate =~ /^$|mdy4\// ) {
	if ( $indate =~ /(\d\d)\/(\d\d)\/(\d\d\d\d)/ ) {
		$datetime_value=sprintf "%04d%02d%02d",$3,$1,$2;
	}
} elsif ($DbDate =~ /dmy4\// ) {
	if ( $indate =~ /(\d\d)\/(\d\d)\/(\d\d\d\d)/ ) {
		$datetime_value=sprintf "%04d%02d%02d",$3,$2,$1;
	}
}
return $datetime_value;
}

sub execute_select_statement {
	my ($DbName,$Statement) = ( @_ ) ;
	if (!defined($IFMXTOOLSTEMPDIR)) {
		$IFMXTOOLSTEMPDIR="/tmp" ;
	}
	my $ProcNum=sprintf "%d.%d",$$,int(rand(2000000)) + 1000000 ;
	my $TempUnloadFile = sprintf "%s/stmt.%s.out",$TempDir,$ProcNum ;
	my $TempCmdFile = sprintf "%s/stmt.%s.sql",$TempDir,$ProcNum ;
	my $TempErrorFile = sprintf "%s/stmt.%s.err",$TempDir,$ProcNum ;
	my $TempStdOutFile = sprintf "%s/stmt.%s.log",$TempDir,$ProcNum ;

	if ( defined($OS_win) && $OS_win == 1 ) {
		$TempCmdFile =~ s/\//\\/g ;	
		$TempErrorFile =~ s/\//\\/g ;
		$TempUnloadFile =~ s/\//\\/g ;
		$TempStdOutFile =~ s/\//\\/g ;
	}
	open CMDFILE,">$TempCmdFile" or die "Cannot open Sql command file " . $TempCmdFile ;
	printf CMDFILE "unload to %s\n%s\n",$TempUnloadFile,$Statement ;
	close ( CMDFILE );
	$Command = sprintf "dbaccess %s %s 1>%s 2>%s",$DbName,$TempCmdFile,$TempStdOutFile,$TempErrorFile ;
	$status=system($Command) ;
	open (ERRFILE,$TempErrorFile) or die "Cannot open $TempErrorFile for reading";
	@Errors = grep (/\d+:.*error|ISAM/,<ERRFILE>);
	if ( $KeepTempFile != 1 ) {
		unlink ($TempErrorFile);
	}
	if ( $#Errors < 0 ) {
		open (UNLOADFILE,$TempUnloadFile) or die "Cannot open $TempUnloadFile for reading";
		#@UnloadFile=map { s/\|\n//;$_ } <UNLOADFILE> ;
		@UnloadFile=map { s/\|\n/|/;$_ } <UNLOADFILE> ;

		if ( $KeepTempFile != 1 ) {
			unlink ($TempUnloadFile);
			unlink ($TempStdOutFile) ;
			unlink ($TempErrorFile) ;
			unlink ($TempCmdFile) 
		}
		return "OK",@UnloadFile ;
	} else {
		$errors=join('',@Errors);
		return $errors,"";
	}
} # execute_select_statement 

sub execute_sql_stmt {
	( $stmt,$database,$NoShow ) = ( @_ ) ;
	if ($stmt !~ /.*\.sql$/ ) { # this is not an sql script file, generates a temp file
		if ( $database ne "" ) {
			$STMT=sprintf "database %s;\n%s",$database,$stmt ;
		} else {
			$STMT=$stmt ;
		}
		# create a unique sql file
		$ProcNum=sprintf "%d.%d",$$,int(rand(1000000)) + 1 ;
		$StmtFile = sprintf "%s/stmt.%s.sql",$TempDir,$ProcNum ;
		open SQLSTMT,">" . $StmtFile ;
		printf SQLSTMT $STMT ;
		close SQLSTMT ;
		$StmtErrFile = sprintf "%s/stmt.%s.err",$TempDir,$ProcNum ;
		$StmtLogFile = sprintf "%s/stmt.%s.log",$TempDir,$ProcNum ;
	} else { # this is a .sql file that must be kept
		$StmtFile = $stmt ;
		my $BaseName = basename($StmtFile);
		$BaseName = basename($BaseName,".sql");
		$StmtErrFile = sprintf "%s/%s.err",$TempDir,$BaseName;
		$StmtLogFile = sprintf "%s/%s.log",$TempDir,$BaseName ;
	}
	if (defined($ListOnly)) {
		$TS_End = time () ;
		my $Duration_Sec=$TS_End - $TS_tbl_init;
		return 0,0,$EndTSStr,0 ;
	}
	$TS_Start = time () ;
        $StartTSStr = utc_to_datetime($TS_Start);
	$cmd=sprintf "dbaccess %s < %s 2>%s 1>%s",$database,$StmtFile,$StmtErrFile,$StmtLogFile ;
	system ($cmd) ;
	$TS_End = time () ;
        my $Duration_Sec=$TS_End - $TS_tbl_init;
        $Duration_H=int($Duration_Sec/3600);
        $Duration_M=int(($Duration_Sec-($Duration_H*3600))/60);
        $Duration_S=int(($Duration_Sec-($Duration_H*3600)-($Duration_M*60)));
	
        $Duration = sprintf "%02d:%02d:%02d",$Duration_H,$Duration_M,$Duration_S ;
        my $EndTSStr = utc_to_datetime($TS_End);
	open STMTERR,$StmtErrFile ;
	@ErrFile=<STMTERR> ;
	@Errors = grep(/^\s*(\d+):.*[Ee]rror|Error in line|Near character/,@ErrFile);
	if ( $#Errors > -1 && !defined($NoShow) ) {
		printf "%s",@Errors ;
		printf LOGFILE "%s",@Errors ;
		printf " Check files %s ",$StmtErrFile ;
		printf LOGFILE " Check files %s\n",$StmtErrFile ;
	} else {
		unlink ($TempUnloadFile);
		unlink ($TempStdOutFile) ;
		if ( $StmtFile =~ /stmt\.\d+/ ) {
			unlink ($StmtFile) ;
		}
		unlink ($StmtErrFile) ;
		unlink ($StmtLogFile) 
	}
	return ($#Errors+1),$ProcNum,$EndTSStr,$Duration_Sec ;
} # end execute_sql_stmt

#
# insert a record into dbschema_fix to trace the patch execution
sub insert_dbschema_fix {
	my ($ScriptFile)=(@_) ;
	my $FixName = basename($ScriptFile,".sql");
	my ($Abstract,$FixType,$FixDependencies,$TableList,$FixCreateDate,$FixApplyDate) = qw ("","","","","","");
	# parse the script to collect header
	($Abstract,$FixDependencies,$TableList) = parse_sqlscript_header($ScriptFile);	
	$TableList =~ s/\s+//g;
	if ( $FixName =~ /^(\d{8})\-(\w+)\-(\w+)/ ) {
		$FixCreate= $1;
		$FixType = $3;
		if ( $FixCreate =~ /(\d{4})(\d{2})(\d{2})/ ) {
			$FixCreateDate = sprintf "%s/%s/%s",$3,$2,$1;
		}
	}
	my $stmt=sprintf "INSERT INTO dbschema_fix (fix_script_name,fix_dbvendor,fix_abstract,fix_type,fix_dependencies,fix_tableslist,fix_create_date,fix_apply_date) VALUES (\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\")",
	$FixName,"informix",$Abstract,$FixType,$FixDependencies,$TableList,$FixCreateDate,$TodayStr;
	($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);
	$a=1;

} # end sub insert_dbschema_fix

# parse the script file to collect data
sub parse_sqlscript_header {
	my ($ScriptFile) = ( @_) ;
	my $Abstract="";
	my $FixDependencies="";
	my $TableList="";
	open SCRIPT,$ScriptFile;
	while (<SCRIPT>) {
		if ( /--# description:\s*(.*)\s+$/ ) {
			$Abstract=$1;
		} elsif ( /--# dependencies:\s*(.*)\s+$/ ) {
			$FixDependencies=$1;
		} elsif ( /--# tables list:\s*(.*)\s+$/ ) {
			$TableList=$1;
		}
	}
	return $Abstract,$FixDependencies,$TableList;
} # end sub parse_sqlscript_header {


sub utc_to_date {
my $TS_seconds=$_[0];
($S, $M, $H, $d, $m, $y, $wd, $aj, $isdst) = localtime $TS_seconds;
my $year = $y + 1900;
my $day=$d;
my $month=$m + 1;
my $TS_DSF=sprintf "%02d/%02d/%4d",$day,$month, $year;
return $TS_DSF ;
}

sub utc_to_datetime {
my $TS_seconds=$_[0];
($S, $M, $H, $d, $m, $y, $wd, $aj, $isdst) = localtime $TS_seconds;
my $year = $y + 1900;
my $day=$d;
my $month=$m + 1;
my $TS_DSF=sprintf "%04d-%02d-%02d %02d:%02d:%02d",$year, $month, $day, $H,$M,$S ;
return $TS_DSF ;
}

sub convert_export_to_utf8 {
my ($SnapshotDir,$DatabaseName) = ( @_ ) ;
my $NewExportDir=sprintf "%s/%s.exp",$SnapshotDir,$DatabaseName;

opendir (EXPORT,$NewExportDir) or die "Cannot open export directory " . $NewExportDir;
printf "reading export directory %s for utf8 conversion\n",File::Spec->canonpath($NewExportDir);
foreach my $File (sort readdir EXPORT) {
        if ( -d $File ) {
                next;
        }
        my $FullFile=sprintf "%s/%s",$NewExportDir,$File ;
        my $UTF8File=sprintf "%s.UTF8",$FullFile;
        if ($File =~ /\w+\.unl$/ ) {
		my $Cmd=sprintf "iconv -f ISO8859-1 -t UTF8 %s -o %s", $FullFile, $UTF8File;
		printf "%s\n",$Cmd;
		my $status=system($Cmd);
		if ( -e $UTF8File ) {
			$Cmd = sprintf "mv %s %s",$UTF8File, $FullFile;
			system($Cmd);
		}
	}
}
} # end sub convert_export_to_utf8 

sub GetUnloadFileInfo {
my ($DatabaseName,$TableName) = ( @_ ) ;
$DbScriptFile=sprintf "%s/%s.sql",$OldExportDir,$SourceDatabaseName;
open SCRIPTFILE,$DbScriptFile or die "cannot open script file " ;
my $TableFound=0;
while (my $scrline=<SCRIPTFILE>) {
	if ( $scrline =~ /TABLE .*($TableName)\s/ ) {
		$TableFound=1;
		next;
	}	
	if ($TableFound == 1 && $scrline =~ /unload file name =\s+(\w+\.unl)\s+number of rows\s*=\s*(\d+)/) {
		return $1,$2;
	}
}
return "notfound";
}

sub  CleanUpDbschemafix { 
	my ($fix_file,$LastPatch) = (@_ ) ;
	my $FixFile=sprintf "%s/%s",$OldExportDir,$fix_file;
	my $FixFileNew=sprintf "%s.new",$FixFile;
	open FIXFILE,$FixFile or die "cannot open dbschema_fix file " ;
	open FIXFILENEW,">$FixFileNew" or die "cannot open new dbschema_fix file " ;
	my $TableFound=0;
	my $LinesNumber=0;
	while (my $fixline=<FIXFILE>) {
		if ( $fixline =~ /(\d\d\/\d\d\/\d\d\d\d)/ ) {
			$FixDateTime = date_to_datetime($1); # return date as yyyymmdd format
			if ( $FixDateTime > $LastPatch ) {
				$fixline =~ s/$SourceDatabaseName/$TargetDatabaseName/ ;
				printf FIXFILENEW "%s", $fixline;
				$LinesNumber++;
			}
		}
	}
	close FIXFILE;
	close FIXFILENEW;
	close $FixFile;
	close $FixFileNew;
	# replace old fixfile by new fixfile
	move ($FixFileNew,$FixFile) ;
	return $LinesNumber;
}

sub  CleanUpDbschemaproperties { 
	my ($properties_file,$LastPatch) = (@_ ) ;
	my $PropertiesFile=sprintf "%s/%s",$OldExportDir,$properties_file;
	my $PropertiesFileNew=sprintf "%s.new",$PropertiesFile;
	open PROPERTIESFILE,$PropertiesFile or die "cannot open dbschema_properties file " ;
	open PROPERTIESFILENEW,">$PropertiesFileNew" or die "cannot open new dbschema_properties file " ;
	my $TableFound=0;
	my $LinesNumber=0;
	while (my $propertiesline=<PROPERTIESFILE>) {
		my @propLine=split (/\|/, $propertiesline) ;
		$propLine[0] =~ s/.*/$TargetDatabaseName/;
		$propLine[2] =~ s/.*/$LastPatch/;
		$propLine[3] = "" ;
		$propLine[4] = "" ;
		$propLine[6] = 0 ;
		$propLine[7] = 0 ;
		$propertiesline=sprintf "%s",join("|",@propLine);
		printf PROPERTIESFILENEW "%s", $propertiesline;
		$LinesNumber++;
	}
	close PROPERTIESFILE;
	close PROPERTIESFILENEW;
	# replace old propertiesfile by new propertiesfile
	move ($PropertiesFileNew,$PropertiesFile) ;
	return $LinesNumber;
}

sub FixNewSqlFile {
# do in place replace of the database name and dbschema_fix lines number
	my ($NewSqlFile,$TargetDatabaseName,$fix_filename,$dbschema_fix_lines_number) = ( @_ );
	our $^I = '.bak';

	our @ARGV= ($NewSqlFile);
	while (<>) {
		if ( /{ DATABASE (\w+)  delimiter/ ) {
			$_ =~ s/ $1 / $TargetDatabaseName / ;
		}
		if ( /unload file name =\s+($fix_filename)\s+number of rows\s*=\s*(\d+)/) {
			$_ =~ s/= $2 /= $dbschema_fix_lines_number / ;
		}
		print;
	}


}
