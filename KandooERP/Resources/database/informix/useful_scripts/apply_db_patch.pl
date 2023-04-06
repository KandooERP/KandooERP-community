use Getopt::Long;
use File::Basename;
use File::Spec;

if (!GetOptions(
	"since=s"=>\$SinceDate,
	"forceexec=s"=>\$ForceExecScript,
	"include=s"=>\$IncludeExpr,		# include will execute the scripts matching the expression and will not consider last patch date
	"exclude=s"=>\$ExcludeExpr,		# exclude will not  execute the scripts matching the expression and WILL consider last patch date
	"database=s"=>\$DatabaseName,
	"dbspace=s"=>\$DbspaceName,
	"check"=>\$Check,
) ) {
	$a=1;
	exit (1);
}
if ( $^O =~ /win/i ) {
	$OS_win=1;
	$TempDir = "C:/temp" ;
}else {
	$TempDir = "/tmp" ;
}
if ( !defined($DatabaseName)) {
	$DatabaseName="kandoodb" ;
}

if ( defined($ENV{"INFORMIXDIR"}) && defined($ENV{"INFORMIXSERVER"})) {
	$a=1;
} else {
	die "You need to run this script with the informix environment (INFORMIXDIR/INFORMIXSERVER)" ;
}
if ( $OS_win == 1 ) {
	$dbaccess=sprintf "%s/bin/dbaccess.exe",$ENV{"INFORMIXDIR"};
} else {
	$dbaccess=sprintf "%s/bin/dbaccess",$ENV{"INFORMIXDIR"};
}
if ( -f $dbaccess ) {
	$a=1;
} else {
	die "You need to be able to run dbaccess from this window/session" ;
}	
$TodayStr = utc_to_date(time());
$NowStr = utc_to_datetime(time());
# force DBDATE for this process so that date are always handled the same way
$ENV{"DBDATE"} ="dmy4/" ;
if (!defined($ENV{"DB_LOCALE"})) {
	$ENV{"DB_LOCALE"} ="en_US.57372" ;
}
if (!defined($ENV{"CLIENT_LOCALE"})) {
	$ENV{"CLIENT_LOCALE"} ="en_US.57372" ;
}
#
#
# check date of database snapshot
my $Statement = sprintf "select snapshot_date from dbschema_properties where dbsname = \"%s\"",$DatabaseName;
($status,@Creation_Date) = execute_select_statement ($DatabaseName,$Statement) ;

# if snapshot date is null, it means the dbschema_fix and dbschema_properties tables are not up to date
# first thing is to create those tables with proper schema
if ( $status ne "OK" || $Creation_Date[0] =~ /^\s*$/ || $#Creation_Date < 0 ) {
	my $Statement = sprintf "select created from sysdatabases where name = \"%s\"",$DatabaseName;
	($status,@Creation_Date) = execute_select_statement ("sysmaster",$Statement) ;
	if (!defined($Check)) {
		# dbsname,dbsvendor,snapshot_date,last_patch_date
		# execute drop/create of both dbschema_xx tables
		$FullFile="./20180714-dbschema_xxx-crttbl.sql" ;
		($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($FullFile,$DatabaseName);
		# Insert the initial row of dbschema_properties
		$Statement = sprintf "INSERT INTO dbschema_properties VALUES (\"%s\",\"informix\",\"%s\",NULL)",$DatabaseName,$Creation_Date[0];
		($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($Statement,$DatabaseName);
		
		# insert the dbschema_fix row for the initial schema_properties (to avoid repeating this script)
		($Abstract,$FixDependencies,$TableList) = parse_sqlscript_header($FullFile);
		insert_dbschema_fix($FullFile,$status,$Abstract,$FixDependencies,$TableList);
	}
} 
$CreationDate = date_to_datetime($Creation_Date[0]); # return date as yyyymmdd format
printf STDOUT "Database %s has been created on %s\n",$DatabaseName,$Creation_Date[0] ;
#
# Check dbspace name and collate of the current paceName,$DbCollate)andood
my $Statement = sprintf "select d.name,t.collate from systabnames t,sysdbspaces d where t.dbsname = \"%s\" and t.tabname = \"systables\" and d.dbsnum = t.dbsnum",$DatabaseName;
my ($Status,@ReturnedRows) = execute_select_statement ("sysmaster",$Statement) ;
if ( $Status eq "OK" ) {
	($DbspaceName,$DbCollate) = split ( /\|/,$ReturnedRows[0] ) ;
	$ENV{"DBSPACENAME"} = $DbspaceName;
	# export dbspace name for eventual scripts needing this variable
}

# Check logging mode
# is_logging      1
# is_buff_log     0
# is_ansi         0
#
my $Statement = sprintf "select is_logging,is_buff_log,is_ansi from sysdatabases where name = \"%s\"",$DatabaseName;
my ($Status,@ReturnedRows) = execute_select_statement ("sysmaster",$Statement) ;
if ( $Status eq "OK" ) {
	($is_logging,$is_buff_log,$is_ansi) = split ( /\|/,$ReturnedRows[0] ) ;
	if ( $is_logging == 1 ) {
		$logMode="-l";
		$DispLog="with log";
	} elsif ($is_buff_log == 1 ) {
		$logMode="-l buffered";
		$DispLog="with buffered log";
	} elsif ($is_ansi == 1 ) {
		$logMode="-ansi";
		$DispLog="ansi log";
	} else {
		$logMode="";
		$DispLog="NO LOG";
	}
	$ENV{"LOGMODE"}=$logMode;
}

printf STDOUT "Database is sitting in the %s dbspace , logging mode is %s , codeset is %s\n",$DbspaceName,$DispLog,$DbCollate;
my $Statement = sprintf "select last_patch_date from dbschema_properties where dbsname = \"%s\"",$DatabaseName;
($status,@LastPatch_Date) = execute_select_statement ($DatabaseName,$Statement) ;
if ( $LastPatch_Date[0] !~ /^\s*$/ ) {
	$LastPatchDateNum = date_to_datetime($LastPatch_Date[0]); # return date as yyyymmdd format
	$LastPatchDate =  $LastPatch_Date[0];
	printf STDOUT "Last patch applied on %s has been issued on %s\n",$DatabaseName,$LastPatch_Date[0] ;
} else {
	printf STDOUT "No patch has ever been applied on %s\n",$DatabaseName;
}

$a=1;

if ( !defined($SinceDate)) {
	if ( $LastPatchDate > 0 ) {
		$SinceDate=$LastPatchDateNum;
	} else {
		$SinceDate=$CreationDate;
	}
	
}
if (!defined($Check)) {
	printf "Warning!!!! this script will alter tables schemas or tables data in your database, please run backup_previous_version.sh or an ids backup!!!\n" ;
	printf "Have you saved your database before proceeding? (y/n) " ;
	$Rep=<STDIN>;
	if ( $Rep !~ /^[Yy]/ ) {
		"Please run backup_previous_version.sh now and relauch apply_db_patch.pl after\nExiting\n";
		exit ;
	}
}
$LogFile=sprintf "%s.log",$0 ;
if (defined($Check)) {
	$LogFile =~ s/\.pl/_check/;
} else {
	$LogFile =~ s/\.pl//;
}
open LOGFILE,">>$LogFile" or die "cannot open log file " ;
$InDir = ".";
opendir (DIR,$InDir) or die "Cannot open indir " . $InDir;
printf "reading directory %s\n",File::Spec->canonpath($InDir);
foreach my $File (sort readdir DIR) {
	if ( -d $File ) {
		next;
	}
	if ( $File !~ /\.sql$/ &&  $File !~ /\.pl/ ) {
		next;
	}
        $FullFile=$InDir . "/" . $File ;
	if ($File =~ /^(20\d\d\d\d\d\d)\.*\d*\-\w+\-\w+\.[sp].*l/ ) { # this is a valid sql script file
		$FileDate=$1;
		if ( ( $FileDate >= $SinceDate && !defined($IncludeExpr) && !defined($ExcludeExpr) && !defined($ForceExecScript))
		|| ( defined($IncludeExpr) && $File =~ /$IncludeExpr/&& !defined($ForceExecScript) ) 
		|| ( defined($ExcludeExpr) && $FileDate > $SinceDate && $File !~ /$ExcludeExpr/ && !defined($ForceExecScript) ) 
		|| ( defined($ForceExecScript) && $File =~ /$ForceExecScript/ ) ) {
			$TS_Start = time () ;
			$StartTSStr = utc_to_datetime($TS_Start);
			my $FixName = basename($File,".sql");
			my $Statement = sprintf "SELECT COUNT(*) FROM dbschema_fix WHERE fix_name = \"%s\" AND fix_status = \"OK\"",$FixName;
			($status,@ApplyCount) = execute_select_statement ($DatabaseName,$Statement) ;
			if ( $ApplyCount[0] > 0 && !defined ($ForceExecScript)) {
				printf STDOUT "%s script %s has already been applied, skipping\n",$StartTSStr,$FixName;
				printf LOGFILE "%s script %s has already been applied, skipping\n",$StartTSStr,$FixName;
				$SkippedScripts++;
				next ;
			}
			($Abstract,$FixDependencies,$TableList) = parse_sqlscript_header($FullFile);	
			if ( $Abstract =~ /^\s*$/ || $TableList =~ /^\s*$/ ) {
				printf STDOUT "%s Script %s: script header is incomplete\n",$StartTSStr,$FullFile,$action;
				printf LOGFILE "%s Script %s: script header is incomplete\n" ,$StartTSStr,$FullFile,$action;
				$BadHeaderScripts++;
				next;
			}
			$ScriptsToRun++;
					
			if (!defined($Check)) {
				$action = "starting";
			} else {
				$action = "due to execution";
			}
			printf STDOUT "%s Script:%s | tables list:%s | What:%s ... ",$StartTSStr,$FullFile,$TableList,$Abstract;
			printf LOGFILE "%s Script:%s | tables list:%s | What:%s ... ",$StartTSStr,$FullFile,$TableList,$Abstract;
			# EXECUTE THE FIX
			if (!defined($Check)) {
				if ($File =~ /.*\.sql$/ ) {
					($status,$procnum,$EndTSStr,$FixDuration)=execute_sql_stmt($FullFile,$DatabaseName);
				} elsif ($File =~ /.*\.pl$/ ) {
					$cmd = sprintf "perl %s -data %s -dbspace %s",$FullFile,$DatabaseName,$DbspaceName ;
					system($cmd);
					$status = $? ;
					if ( $status gt 0 ) {
						$status ="KO";
					} else {
						$status ="OK";
					}
				}
			}
			if ( $status eq "OK"  ) {
				if (!defined($Check)) {
					insert_dbschema_fix($FullFile,$status,$Abstract,$FixDependencies,$TableList);
				}
				printf STDOUT "| Status:OK (%d seconds)\n",$FixDuration;
				printf LOGFILE "| Status:OK (%d seconds)\n",$FixDuration;
				if ( $FailedScripts == 0 ) {
					# $MaxPatchDate is the last patch date IF all scripts are OK, else remains the date of last successful series
					$MaxPatchDate=$FileDate;
				}
				$SucessFulScripts++;
			} else {
				printf STDOUT " | Script has errors\n";
				printf LOGFILE " | Script has errors\n";
				$FailedScripts++;
			}
		} else {
			next ;
		}
	} elsif ($File =~ /^(20\d\d\d\d\d\d)\.*\d*\-\w+\-\w+\.pl/ ) {
		# this is a full perl script to be executed!
		perl $File ;
	} elsif ($File =~ /^20\d\d\d\d\d\d\-.*\.unl/ ) {
		$a=1; # this is an unload file
	} elsif ($File =~ /^\./ || $File =~ /apply_db_patch|script|.*\.pl/) {
		next ;
	} elsif ($File =~ /\.zip|\.unl|\.log/) {
		next ;
	} else {
		# unknown format
		# printf STDOUT "File %s : unknown file name format,will not execute\n",$FullFile;
		printf LOGFILE "File %s : unknown file name format,will not execute\n",$FullFile;
		next ;
	}
}
# Finalize the patch by setting the last patch date

if ( !defined($Check) && $SucessFulScripts+$FailedScripts > 0 ) {
	if ( $MaxPatchDate =~ /(\d{4})(\d{2})(\d{2})/ ) {
		$LastPatchDate=sprintf "%s/%s/%s",$3,$2,$1;
	} 
	if ( !defined($ForceExecScript)&& $LastPatchDate =~ /\d{2}\/\d{2}\/\d{4}/ ) {
		$stmt= sprintf "UPDATE dbschema_properties SET last_patch_date = \"%s\",last_patch_apply = \"%s\",last_patch_ok_scripts = %d,last_patch_ko_scripts = %d  WHERE dbsname = \"%s\"",
		$LastPatchDate,$NowStr,$SucessFulScripts,$FailedScripts,$DatabaseName;
		($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);
	}
	if ( $SucessFulScripts == $ScriptsToRun ) {
		printf STDOUT "%d scripts have been applied successfully today (All Successful)\n",$SucessFulScripts;
	} else {
		printf STDOUT "%d scripts have been applied successfully today (%d scripts failed, %s scripts have been skipped, %d scripts have bad headers)\n",
		$SucessFulScripts,$FailedScripts,$SkippedScripts,$BadHeaderScripts;
	}
} else {
	printf STDOUT "%d scripts should be applied today (%s scripts will be skipped, %d scripts have bad headers)\n",
	$SucessFulScripts,$SkippedScripts,$BadHeaderScripts;
}


# convert informix date to yyyymmdd format (for sort etc)
sub date_to_datetime {
my $indate = $_[0] ;
my $datetime_value="";
$DbDate=$ENV{"DBDATE"} ;
if ($DbDate =~ /^$|mdy4\// ) {
	if ( $indate =~ /(\d\d)\/(\d\d)\/(\d\d\d\d)/ ) {
		$datetime_value=sprintf "%4s%02d%02d",$3,$1,$2;
	}
} elsif ($DbDate =~ /dmy4\// ) {
	if ( $indate =~ /(\d\d)\/(\d\d)\/(\d\d\d\d)/ ) {
		$datetime_value=sprintf "%4s%02d%02d",$3,$2,$1;
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
#		$TempCmdFile =~ s/\//\\/g ;	
#		$TempErrorFile =~ s/\//\\/g ;
		$TempUnloadFile =~ s/\//\\/g ;
#		$TempStdOutFile =~ s/\//\\/g ;
	}
	open CMDFILE,">$TempCmdFile" or die "Cannot open Sql command file " . $TempCmdFile ;
	printf CMDFILE "unload to \"%s\"\n%s\n",$TempUnloadFile,$Statement ;
	close ( CMDFILE );
	$Command = sprintf "dbaccess %s %s 1>%s 2>%s",$DbName,$TempCmdFile,$TempStdOutFile,$TempErrorFile ;
	$status=system($Command) ;
	if ( $status == 0 ) {
		open (ERRFILE,$TempErrorFile) or die "Cannot open $TempErrorFile for reading";
	}
	@Errors = grep (/\d+:.*error|ISAM/,<ERRFILE>);
	if ( $KeepTempFile != 1 ) {
		unlink ($TempErrorFile);
	}
	if ( $#Errors < 0 ) {
		open (UNLOADFILE,$TempUnloadFile) or die "Cannot open $TempUnloadFile for reading";
		@UnloadFile=map { s/\|\n//;$_ } <UNLOADFILE> ;

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
	if (defined($Check)) {
		$TS_End = time () ;
		my $Duration_Sec=$TS_End - $TS_tbl_init;
		return 0,0,$EndTSStr,0 ;
	}
	$TS_Start = time () ;
        $StartTSStr = utc_to_datetime($TS_Start);
	$cmd=sprintf "dbaccess %s < %s 2>%s 1>%s",$database,$StmtFile,$StmtErrFile,$StmtLogFile ;
	system ($cmd) ;
	$TS_End = time () ;
        my $Duration_Sec=$TS_End - $TS_Start;
        $Duration_H=int($Duration_Sec/3600);
        $Duration_M=int(($Duration_Sec-($Duration_H*3600))/60);
        $Duration_S=int(($Duration_Sec-($Duration_H*3600)-($Duration_M*60)));
	
        $Duration = sprintf "%02d:%02d:%02d",$Duration_H,$Duration_M,$Duration_S ;
        my $EndTSStr = utc_to_datetime($TS_End);
	open STMTERR,$StmtErrFile ;
	@ErrFile=<STMTERR> ;
	@Errors = grep(/^\s*(\d+):.*[Ee]rror|Error in line|Near character/,@ErrFile);
	my $status="" ;
	if ( $#Errors > -1 && !defined($NoShow) ) {
		printf "%s",@Errors ;
		printf LOGFILE "%s",@Errors ;
		printf " Check files %s ",$StmtErrFile ;
		printf LOGFILE " Check files %s\n",$StmtErrFile ;
		$status="KO";
	} else {
		unlink ($TempUnloadFile);
		unlink ($TempStdOutFile) ;
		if ( $StmtFile =~ /stmt\.\d+/ ) {
			unlink ($StmtFile) ;
		}
		unlink ($StmtErrFile) ;
		unlink ($StmtLogFile) ;
		$status="OK";
	}
	#my $status="" ;
	#if ($#Errors > -1) {
		##$status="KO";
	#} else {
		##$status="OK";
	#}
	return $status,$ProcNum,$EndTSStr,$Duration_Sec ;
} # end execute_sql_stmt


#
sub update_dbschema_properties {
	my ($ScriptFile,$Status,$Abstract,$FixDependencies,$TableList)=(@_) ;
	my $stmt=sprintf "UPDATE dbschema_properties SET last_patch_date = \"%s\" WHERE dbsname = \"%s\"",$FixCreateDate,$DatabaseName;
	($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);

} # end  update_dbschema_properties 

# insert a record into dbschema_fix to trace the patch execution
sub insert_dbschema_fix {
	my ($ScriptFile,$Status,$Abstract,$FixDependencies,$TableList)=(@_) ;
	my $FixName = basename($ScriptFile,".sql");
	$TableList =~ s/\s+//g;
	#if ( $FixName =~ /^(\d{8})\-(\w+)\-(\w+)/ ) {
	if ( $FixName =~ /^(\d{8}).*\-(\w+)\-(\w+)/ ) {
		$FixCreate= $1;
		$FixType = $3;
		if ( $FixCreate =~ /(\d{4})(\d{2})(\d{2})/ ) {
			$FixCreateDate = sprintf "%s/%s/%s",$3,$2,$1;
		}
	}
	my $stmt=sprintf "INSERT INTO dbschema_fix (fix_name,fix_dbvendor,fix_abstract,fix_type,fix_dependencies,fix_tableslist,fix_create_date,fix_apply_date,fix_status) VALUES (\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\")",
	$FixName,"informix",$Abstract,$FixType,$FixDependencies,$TableList,$FixCreateDate,$NowStr,$Status;
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
		s/\r/\n/;
		if ( /\-*# description:\s*(.*)\s+$/ ) {
			$Abstract=$1;
		} elsif ( /\-*# dependencies:\s*(.*)\s+$/ ) {
			$FixDependencies=$1;
		} elsif ( /\-*# table.*:\s*(.*)\s+$/ ) {
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
