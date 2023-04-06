BEGIN {
  	if (defined($ENV{"FFGDIR"})) {
		$FfgLib=$ENV{"FFGDIR"} . "/../incl" ;
		#$FfgLib =~ s/[\/\\]/\\\//g;
		$FfgLib =~ s/[\/\\]/\//g;
		eval "use lib \"$FfgLib\"";
		die "$@\n" if ($@);
	} else {
		die "Please set the FFGDIR env variable";
	}
	if ( defined ($ENV{"FFGDIR"} ) ) {
		$FFGDIR=$ENV{"FFGDIR"} ;
	} else {
		die "Please set FFGDIR env variable";
	}

	# Directory of perl custom ffg packages
	if ( defined ($ENV{"FFGINCLDIR"} ) ) {
		$FFGINCLDIR=$ENV{"FFGINCLDIR"} ;
		$FFGINCLDIR =~ s/[\/\\]/\//g;
		eval "use lib \"$FFGINCLDIR\"";
	}

	# Diretory of ffg parameters, language files etc: Mandatory
	if ( defined ($ENV{"FFGETCDIR"} ) ) {
		$FFGETCDIR=$ENV{"FFGETCDIR"} ;
	} else {
		$FFGETCDIR=$FFGDIR . "/etc" ;
	}
} # End BEGIN


use Getopt::Long;
use File::stat;
use File::Basename;
use File::Path;
use XML::Simple;
use IO::Handle;
use Data::Dumper qw(Dumper);
use Cwd;
use Ffg::DbSchema;
use Ffg::ParseForms;
use Ffg::Misc;
use Ffg::Misc;

$XML::Simple::PREFERRED_PARSER = 'XML::Parser';
if ( defined ($ENV{"FFGDIR"} ) ) {
	$FFGDIR=$ENV{"FFGDIR"} ;
} else {
  die "Please set FFGDIR env variable";
}

# Directory of perl custom ffg packages
if ( defined ($ENV{"FFGINCLDIR"} ) ) {
	$FFGINCLDIR=$ENV{"FFGINCLDIR"} ;
	eval "use lib \"$FFGINCLDIR\"";
}

# Diretory of ffg parameters, language files etc: Mandatory
if ( defined ($ENV{"FFGETCDIR"} ) ) {
	$FFGETCDIR=$ENV{"FFGETCDIR"} ;
} else {
  $FFGETCDIR=$FFGDIR . "/etc" ;
}


usage () if ( ! GetOptions(
	"version"=>\$Version,
	"database=s"=>\$DatabaseName,
	"projectname=s"=>\$ProjectName,	# Lycia project Name
	"program=s"=>\$ProgramName,			# Lycia program name
	"formpath=s"=>\$QxPerLocation,			# Lycia program name
	"indir=s"=>\$InDir,					# parse this directory recursively ( starts from Qx4glLocation)
	"outdir=s"=>\$OutDir,					# parse this directory recursively ( starts from Qx4glLocation)
	"loaddatabase=s"=>\$LoadDatabaseName,					# parse this directory recursively ( starts from Qx4glLocation)
	"exclude=s"=>\$Exclude,		# dumps the generation data stop or continue
	"reset"=>\$ResetMessages,		# dumps the generation data stop or continue
	"formname=s"=>\$FormName,			# Existing main Lycia form to be used (must be .fm2)
	"lang=s"=>\$Language,				# Standard messages and menus will use that language
	"trace=i"=>\$trace,		# continues or errors when checking:
	"chopeol"=>\$ChopEOL,		# replaces \n & \r by a space
	"logfile=s"=>\$LogFile,		# force primary key
	"dumpdata=s"=>\$DumpData,		# dumps the generation data stop or continue
	"debug"=>\$DEBUGPRINT,		# dumps the generation data stop or continue
	
	) ) ;

if (!defined($Exclude)) {
	$Exclude="9876543210aBcDeF!";
}

$Language = "ENU" ;
$QxWorkSpace=$ENV{"QX_WORKSPACE"} ;
if (!defined($QxWorkSpace)) {
	set_parameters_for("CurrentValues","QxWorkSpace");
}
$ProjectDir=get_eclipse_project_dir ($QxWorkSpace,$ProjectName);
if ( $ProjectDir eq "NotFound") {
	$ProjectDir = sprintf "%s/%s",$QxWorkSpace,$ProjectName};
if (! -d($ProjectDir)) {
	printf LOGFILE "Project folder not found!: %s \n",$ProjectDir;
	die "please check that the project exists in Lycia " . $ProjectName ;		
} else {
	printf LOGFILE "Project folder OK: %s \n",$ProjectDir;
}

undef ($Qx4glLocation);
undef ($QxPerLocation);
# get 4gl and forms locations, first global then project if different
set_parameters_for("global","Qx4glLocation");
set_parameters_for("global","QxPerLocation");
set_parameters_for($ProjectName,"Qx4glLocation");
set_parameters_for($ProjectName,"QxPerLocation");






#-------------------------------------------------------------------------------------------------
if (!defined($QxPerLocation)) {
	if (!-d ($QxWorkSpace) || !defined($QxWorkSpace)) {
		die "please choose a valid Querix Workspace " . $QxWorkSpace . " or set QxWorkSpace in file " . $FFGETCDIR . "/CurrentValues.params";
	}
	$LyciaProjectsDir=sprintf "%s/.metadata/.plugins/org.eclipse.core.resources/.projects",$QxWorkSpace;

	if (-d $LyciaProjectsDir) {
		$a=1;
	} else {
		die "cannot find LyciProjectsDir for the WorkSpace " .  $LyciaProjectsDir;
	}
	# Lycia Project name

	if ( !defined($ProjectName) ) {
		$ProjectName=input($QProjName,1) ;
	} 
#-------------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------------------
	$ProjectDir=get_eclipse_project_dir ($LyciaProjectsDir,$ProjectName);
	if (! -d($ProjectDir)) {
		die "please check that the project exists in Lycia " . $ProjectName ;		
	}

	undef ($Qx4glLocation);
	undef ($QxPerLocation);
	set_parameters_for($$,"Qx4glLocation");
	set_parameters_for($ProjectName,"QxPerLocation");
} else {
	$a=1;
}

#We'll see later to run for Whole Project, Program or 1 form
#if ( !defined($ProgramName) ) {
#	$ProgramName=input($QProgName,1) ;
#}

if (!defined ($OutDir)) {
	if ( $^O =~ /win/i) {
		$OutDir="C:\\tmp";
	} else {
		$OutDir="/tmp";
	}
}
$FormAttrOutFile=sprintf "%s/form_attributes.unl",$OutDir;
$AttrTranslOutFile=sprintf "%s/attributes_translation.unl",$OutDir;
$CurrentAttributes=sprintf "%s/form_attributes.current",$OutDir;
$MaxId=0;
if ( !defined($ResetMessages) ) {
	# save current keys of widgets to compare
	$stmt=sprintf "unload to \"%s\" select f.attribute_key,f.attribute_id,t.translation from form_attributes f,attributes_translation t where f.attribute_id=t.attribute_id and t.language = \"%s\" order by 1",$CurrentAttributes,$Language;
	($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);
	#load into hash
	open CURRENT_IDS, $CurrentAttributes or die "Cannot open current atributes " . $CurrentAttributes ;
	while ( <CURRENT_IDS> ) {
		s/\s*$// ;
		my @Record=split('\|',$_) ;
		$CurrentAttributes{$Record[0]}->{Id} = $Record[1];
		if ( $CurrentAttributes{$Record[0]}->{Id} > $MaxId ) { $MaxId = $CurrentAttributes{$Record[0]}->{Id}; }
		$CurrentAttributes{$Record[0]}->{Message} = $Record[2];
	}
}
# set starting attributeId for new records
$NewAttributeId=$MaxId + 1;

open FF, ">:utf8" , $FormAttrOutFile or die "Cannot open FF" ;
open FT ,">:utf8", $AttrTranslOutFile or die  "Cannot open FT" ;
$FormModifTS=format_TIS(time,"yy-mm-dd H:M:S");

# Main form Name
if ( defined($FormName)) {
	$FormFile=sprintf "%s/%s",$QxPerLocation,$FormName ;
	build_widget_list ($FormFile);
} elsif (defined($InDir)) {
	$Indirectory=sprintf "%s/%s",$QxPerLocation,$Indir ;
	read_directory($Indirectory);
}
printf "Total New Messages: %d, Total Modified Messages: %d\n",$TotalNewMessages,$TotalModifiedMessages;

if ( defined($LoadDatabaseName)) {
	if ( defined(ResetMessages) ) {
		$stmt=sprintf "truncate table form_attributes;\ntruncate table attributes_translation\n",$FormAttrOutFile;
		($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);

	}
	# load the files into the database
	$stmt=sprintf "CREATE EXTERNAL TABLE tmp_form_attributes SAMEAS form_attributes USING ( DATAFILES (\"DISK:${FormAttrOutFile}\"), REJECTFILE \"/tmp/form_attributes.rej\" )",$FormAttrOutFile ;
	($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);
	$stmt = <<'END_SQL';
        MERGE INTO form_attributes as f USING tmp_form_attributes as t
        ON f.attribute_key = t.attribute_key
        WHEN MATCHED THEN UPDATE SET f.form_name=t.form_name , f.table_name=t.table_name , f.widget_id=t.widget_id
        , f.attribute_order=t.attribute_order , f.widget_type=t.widget_type , f.attribute_type=t.attribute_type
        WHEN NOT MATCHED THEN INSERT VALUES (t.attribute_key,t.attribute_id,t.form_name,t.table_name,t.widget_id,t.attribute_order,t.widget_type,t.attribute_type);
	DROP TABLE tmp_form_attributes;
END_SQL
	($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);
	if ( $status eq "OK" ) {
		printf "Load  form_attributes OK\n" ;
	} else {
		printf "Load  form_attributes has errors\n" ;
	}

	#$stmt=sprintf "load from %s insert into attributes_translation",$AttrTranslOutFile;
	$stmt=sprintf "CREATE EXTERNAL TABLE tmp_attributes_translation SAMEAS attributes_translation USING ( DATAFILES (\"DISK:${AttrTranslOutFile}\"), REJECTFILE \"/tmp/AttrTranslOutFile.rej\" )",$AttrTranslOutFile ;
	($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);
	$stmt = <<'END_SQL1';
        MERGE INTO attributes_translation as trs USING tmp_attributes_translation as tmp
        ON trs.attribute_id = tmp.attribute_id
        WHEN MATCHED THEN UPDATE SET trs.translation=tmp.translation , trs.modif_timestamp=tmp.modif_timestamp
        WHEN NOT MATCHED THEN INSERT VALUES (tmp.attribute_id,tmp.language,tmp.translation,tmp.modif_timestamp);
	DROP TABLE tmp_attributes_translation;
END_SQL1
	($status,$procnum,$EndTSStr,$Duration)=execute_sql_stmt($stmt,$DatabaseName);
	if ( $status eq "OK" ) {
		printf "Load  attributes_translation OK\n" ;
	} else {
		printf "Load  attributes_translation KO\n" ;
	}
}


sub build_widget_list {
	my ($Form) = ( @_ ) ;
	# first parse the form and catch labels etc into the FormField Hash
	($FormFieldPtr,$ScreenRecordP,$TablesListPtr) = parse_fm2($Form,$DBSchemaPtr,$DataEquivPtr,"translate") ;
	$FormField = $$FormFieldPtr;
	my $FormName=basename($Form);
	printf " Parse form %s ...",$Form;
	$FormName=basename($Form,".fm2");
	$PropertyNum=0;
	$FormNewMessages=0;
	$FormModifiedMessages=0;

	$stats=stat($Form) ;
	$FormerWidgetName="XxXxxxXx!" ;
	my %AttrKeys = {} ;
	LGETFIELDS: foreach my $key (sort { $FormField->{$FormName}->{$a}->{'Column'} cmp $FormField->{$FormName}->{$b}->{'Column'} }keys %{ $FormField->{$FormName} } ) {
		$a=1;
		$WidgetName=$FormField->{$FormName}->{$key}->{'Column'};
		$AttrNum=0;
		# if the widget is linl to a table, add table in key + table column
		if ( defined($FormField->{$FormName}->{$key}->{'Table'}) && $FormField->{$FormName}->{$key}->{'Table'} !~ /^\s*$/ ) {
			$WidgetRoot=sprintf "%s.%s.%s",$FormName,$FormField->{$FormName}->{$key}->{'Table'},$WidgetName;
		} else {
			$WidgetRoot=sprintf "%s.%s",$FormName,$WidgetName;
		}
		if ( defined($FormField->{$FormName}->{$key}->{'text'}) || defined($FormField->{$FormName}->{$key}->{'comment'}) ||  defined($FormField->{$FormName}->{$key}->{'toolTip'})
		|| 	defined($FormField->{$FormName}->{$key}->{'title'}))  {
			# Check duplicate keys
			if (defined ($AttrKeys->{$WidgetRoot})) {
				printf STDERR "Caution: attribute key %s duplication in form %s, Widget type %s : please fix the form!!!\n",
				$WidgetRoot,$FormName,$FormField->{$FormName}->{$key}->{WidgetType};
			} else {
				$AttrKeys->{$WidgetRoot} = $WidgetRoot ;
			}
		}
		
		# determine the unique attribute key
		if ( defined($FormField->{$FormName}->{$key}->{'text'})) {
			$AttrKey=sprintf "%s#txt",$WidgetRoot,$AttrNum++;
		} elsif ( defined($FormField->{$FormName}->{$key}->{'comment'})) {
			$AttrKey=sprintf "%s#cmt",$WidgetRoot,$AttrNum++;
		} elsif ( defined($FormField->{$FormName}->{$key}->{'toolTip'})) {
			$AttrKey=sprintf "%s#ttp",$WidgetRoot,$AttrNum++;
		} elsif ( defined($FormField->{$FormName}->{$key}->{'title'})) {
			$AttrKey=sprintf "%s#ttl",$WidgetRoot,$AttrNum++;
		}

		if ( defined($FormField->{$FormName}->{$key}->{'text'})) {
			#$AttrKey=sprintf "%s#txt",$WidgetRoot,$AttrNum++;
			if ( defined($ChopEOL) && $FormField->{$FormName}->{$key}->{'text'} =~ /\r/ ) {
				$FormField->{$FormName}->{$key}->{'text'} =~ s/[\r\n]/ /g;
			}
			if (!defined($CurrentAttributes{$AttrKey})) {
				# New Message
				$FormNewMessages++;
				$TotalNewMessages++;
				$NewAttributeId++;
				$Attribute_id = $NewAttributeId;
			} elsif ( $FormField->{$FormName}->{$key}->{'text'} ne $CurrentAttributes{$AttrKey}->{Message} && !defined ($Reset)) {
				#Message modified
				$FormModifiedMessages++;
				$TotalModifiedMessages++;
				$Attribute_id = $CurrentAttributes{$AttrKey}->{Id};
				
			} else {
				next LGETFIELDS;
			}

			printf FF "%s|%d|%s|%s|%s|%s|%s|text|\n",$AttrKey,$Attribute_id,$FormName,$FormField->{$FormName}->{$key}->{'Table'},
			$FormField->{$FormName}->{$key}->{'Column'},$FormField->{$FormName}->{$key}->{'Order'},
			$FormField->{$FormName}->{$key}->{'WidgetType'};
			printf FT "%d|%s|%s|%s|\n",$Attribute_id,$Language,$FormField->{$FormName}->{$key}->{'text'},$FormModifTS;
		} 

		if ( defined($FormField->{$FormName}->{$key}->{'comment'})) {
			if ( defined($ChopEOL) && $FormField->{$FormName}->{$key}->{'comment'} =~ /\r/ ) {
				$FormField->{$FormName}->{$key}->{'comment'} =~ s/[\r\n]/ /g;
			}
			#$AttrKey=sprintf "%s#cmt",$WidgetRoot,$AttrNum++;
			if (!defined($CurrentAttributes{$AttrKey})) {
				# New Message
				$FormNewMessages++;
				$TotalNewMessages++;
				$NewAttributeId++;
				$Attribute_id = $NewAttributeId;
			} elsif ( $FormField->{$FormName}->{$key}->{'comment'} ne $CurrentAttributes{$AttrKey}->{Message} && !defined ($Reset)) {
				#Message modified
				$FormModifiedMessages++;
				$TotalModifiedMessages++;
				$Attribute_id = $CurrentAttributes{$AttrKey}->{Id};
				
			} else {
				next LGETFIELDS;
			}
			printf FF "%s|%d|%s|%s|%s|%s|%s|comment|\n",$AttrKey,$Attribute_id,$FormName,$FormField->{$FormName}->{$key}->{'Table'},
			$FormField->{$FormName}->{$key}->{'Column'},$FormField->{$FormName}->{$key}->{'Order'},
			$FormField->{$FormName}->{$key}->{'WidgetType'};
			printf FT "%d|%s|%s|%s|\n",$Attribute_id,$Language,$FormField->{$FormName}->{$key}->{'comment'},$FormModifTS;
		} 
		
		if ( defined($FormField->{$FormName}->{$key}->{'toolTip'})) {
			#$AttrKey=sprintf "%s#ttp",$WidgetRoot,$AttrNum++;
			if ( defined($ChopEOL) && $FormField->{$FormName}->{$key}->{'toolTip'} =~ /\r/ ) {
				$FormField->{$FormName}->{$key}->{'toolTip'} =~ s/[\r\n]/ /g;
			}
			if (!defined($CurrentAttributes{$AttrKey})) {
				# New Message
				$FormNewMessages++;
				$TotalNewMessages++;
				$NewAttributeId++;
				$Attribute_id = $NewAttributeId;
			} elsif ( $FormField->{$FormName}->{$key}->{'toolTip'} ne $CurrentAttributes{$AttrKey}->{Message} && !defined ($Reset)) {
				#Message modified
				$FormModifiedMessages++;
				$TotalModifiedMessages++;
				$Attribute_id = $CurrentAttributes{$AttrKey}->{Id};
				
			} else {
				next LGETFIELDS;
			}

			printf FF "%s|%d|%s|%s|%s|%s|%s|toolTip|\n",$AttrKey,$Attribute_id,$FormName,$FormField->{$FormName}->{$key}->{'Table'},
			$FormField->{$FormName}->{$key}->{'Column'},$FormField->{$FormName}->{$key}->{'Order'},
			$FormField->{$FormName}->{$key}->{'WidgetType'};
			printf FT "%d|%s|%s|%s|\n",$Attribute_id,$Language,$FormField->{$FormName}->{$key}->{'toolTip'},$FormModifTS;
		}
		
		if ( defined($FormField->{$FormName}->{$key}->{'title'})) {
			#$AttrKey=sprintf "%s#ttl",$WidgetRoot,$AttrNum++;
			if (defined($ChopEOL) && $FormField->{$FormName}->{$key}->{'title'} =~ /\r/ ) {
				$FormField->{$FormName}->{$key}->{'title'} =~ s/[\r\n]/ /g;
			}
			if (!defined($CurrentAttributes{$AttrKey})) {
				# New Message
				$FormNewMessages++;
				$TotalNewMessages++;
				$NewAttributeId++;
				$Attribute_id = $NewAttributeId;
			} elsif ( $FormField->{$FormName}->{$key}->{'title'} ne $CurrentAttributes{$AttrKey}->{Message} && !defined ($Reset)) {
				#Message modified
				$FormModifiedMessages++;
				$TotalModifiedMessages++;
				$Attribute_id = $CurrentAttributes{$AttrKey}->{Id};
				
			} else {
				next LGETFIELDS;
			}
			printf FF "%s|%d|%s|%s|%s|%s|%s|title|\n",$AttrKey,$Attribute_id,$FormName,$FormField->{$FormName}->{$key}->{'Table'},
			$FormField->{$FormName}->{$key}->{'Column'},$FormField->{$FormName}->{$key}->{'Order'},
			$FormField->{$FormName}->{$key}->{'WidgetType'};
			printf FT "%d|%s|%s|%s|\n",$Attribute_id,$Language,$FormField->{$FormName}->{$key}->{'title'},$FormModifTS;
		}
	}
	printf " %d new messages, %d modified messages\n",$FormNewMessages,$FormModifiedMessages;
} # end sub build_widget_list 

sub set_parameters_for {
# read global parameters
# precedence is QX_WORKSPACE/etc , if not $FFGETCDIR
  my ($ParamsType,$Param,$Overwrite) = (@_) ;	
	$ParamsFile = sprintf "%s/%s.params",$FFGETCDIR,$ParamsType;
	if ( -e $ParamsFile ) {
		$FfgParamsFile=$ParamsFile;
	} else {
		# the globals is a mandatory file, other files are optional
		if ( $ParamsType eq "global") {
			die "Cannot find parameters file " . $ParamsFile;
		}
	}
	&set_parameters($FfgParamsFile,$Param,$Overwrite) ;
} # end sub set_parameters_for {

#sub set_project_parameters {
# read global parameters
# precedence is QX_WORKSPACE/etc , if not $FFGETCDIR
#  my ($Project,$Param) = (@_) ;	
#	my $ParamsFile = sprintf "%s/%s/etc\/project_parameters.ffg",$QxWorkSpace,$Project;
#	if ( -e $ParamsFile ) {
#		my $FfgParamsFile=$ParamsFile;
#		&set_parameters($FfgParamsFile,$Param) ;
#	}
#} # end sub set_global_parameters {

########################################################################################
sub set_parameters {
	my ($ParametersFile,$Parameter,$OverWrite) = (@_);
	if ( defined ($ParametersFile)) {
		open PARAMS,$ParametersFile or die "Cannot open ParamsFile" . $ParametersFile ;
	} else {
		die "Cannot open $ParametersFile" ;
	}
	while ( <PARAMS> ) {
		my $Line = $_ ;
		if ( $Line =~ /^\s*#/) {
			next;
		}
		if ( $Line =~ /(\$\w+)\s*=/) {
			if (($Parameter ne "" && $Line !~ /^our \$$Parameter\s*=/)) {
				next;
			}
			$VarName=$1;
			$VarName =~ s/\$//;
			if (!defined($$VarName) || defined($OverWrite)) {
				$Line =~ s/\n// ;
				$Line =~ s/#.*$// ;
				eval ($Line) ;
				if ($Parameter ne "") {
					last;					# quit while if only 1 parameter
				}
			}
		}
	}
	close (PARAMS) ;
	$a=1;
} # end sub set_parameters

sub read_directory {
my $indir=$_[0];
opendir (my $DIR,$indir) or die "Cannot open indir " . $indir;
printf"reading directory %s\n",File::Spec->canonpath($indir);
while ( my $Handle=readdir($DIR) ) {
	$FullHandle=$indir . "/" . $Handle ;
	if ( $Handle eq '.' || $Handle eq '..' ) {
		next ;
	} elsif ( -d $FullHandle ) {
		read_directory($FullHandle);
	} elsif ( $FullHandle =~ /\.fm2$/ ) {
		#$FormFile=sprintf "%s/%s",$QxPerLocation,$FormName ;
		if ( $FullHandle !~ /$Exclude/ && !defined($Forms{$Handle})) {
			build_widget_list ($FullHandle);
			$Forms{$Handle} = 1;
		} elsif (defined($Forms{$Handle})) {
			printf "Form: %s has already been parsed, skipping to next \n",$Handle;
		} else {
			$a=1;
			# excluded
		}
	}
}
} # end read_directory

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
	if (!defined($TempDir)) {
		$TempDir="/tmp";
	}
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
	my $status="" ;
	if ($#Errors > -1) {
		$status="KO";
	} else {
		$status="OK";
	}
	return $status,$ProcNum,$EndTSStr,$Duration_Sec ;
} # end execute_sql_stmt

sub utc_to_datetime {
my $TS_seconds=$_[0];
($S, $M, $H, $d, $m, $y, $wd, $aj, $isdst) = localtime $TS_seconds;
my $year = $y + 1900;
my $day=$d;
my $month=$m + 1;
my $TS_DSF=sprintf "%04d-%02d-%02d %02d:%02d:%02d",$year, $month, $day, $H,$M,$S ;
return $TS_DSF ;
}

sub format_TIS {
my $TS_seconds=$_[0];
my $TS_format=$_[1];
($S, $M, $H, $d, $m, $y, $wd, $aj, $isdst) = localtime $TS_seconds;
$year = $y + 1900;
$day=$d;
$month=$m + 1;
$target_format = $TS_format ;
$target_format =~ s/dd/%02d/g;
$target_format =~ s/yyyy/%4d/g;
$target_format =~ s/yy/%02d/g;
$target_format =~ s/mm/%02d/g;
$target_format =~ s/H/%02d/g;
$target_format =~ s/M/%02d/g;
$target_format =~ s/S/%02d/g;
if ( $TS_format =~ /y{2,4}(.*)mm(.*)dd(.*)H(.*)M(.*)S/ ) {
        $sep1=$1;
        $sep2=$2;
        $sep3=$3;
        $sep4=$4;
        $sep5=$5;
        $TS_DSF=sprintf $target_format,$year, $month, $day, $H,$M,$S ;
} elsif ( $TS_format =~ /y{2,4}(.*)mm(.*)dd/ ) {
        $sep1=$1;
        $sep2=$2;
$TS_DSF=sprintf $target_format,$year, $month,$day;
} elsif ( $TS_format =~ /dd(.*)mm(.*)y{2,4} H(.*)M(.*)S/ ) {
        $sep1=$1;
        $sep2=$2;
        $sep3=$3;
        $sep4=$4;
        $sep5=$5;
        $TS_DSF=sprintf $target_format,$day,$month,$year,$H,$M,$S ;
} elsif ( $TS_format =~ /dd(.*)mm(.*)y{2,4}/ ) {
        $sep1=$1;
        $sep2=$2;
        $TS_DSF=sprintf $target_format,$day,$month,$year,
} else {
        $TS_DSF="format not supported" ;
}
return $TS_DSF ;
} # end sub format_TIS

