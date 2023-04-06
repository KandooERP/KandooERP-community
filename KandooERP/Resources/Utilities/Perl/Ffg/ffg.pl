# !/usr/bin/perl
# Author : Eric Vercelletto
# (C) 2006-2016 BeGooden-IT Consulting
# http://www.begooden-it.com
# $Id: ffg.pl 407 2016-10-22 19:58:32Z  $ : full revision info
# $Revision: 407 $  last commit revision number
# $Author: $  last commit author
# $Date: 2016-10-22 21:58:32 +0200 (sam., 22 oct. 2016) $  last commit date
# $Message: $
# Description  : this script builds Querix Lycia .4gl module sources and form sources
BEGIN {
  $OS_win = ($^O eq "MSWin32") ? 1 : 0;
  $OS_aix = ($^O eq "aix") ? 1 : 0;
  $OS_solaris = ($^O eq "Solaris") ? 1 : 0;
  $OS_hpux = ($^O eq "hp-ux") ? 1 : 0;
  $OS_SCO = ($^O eq "sco") ? 1 : 0;
use File::Spec;
use Cwd qw(abs_path);
if (!defined($ENV{"FFGDIR"})) {
	die "Please set the FFGDIR env variable";
} else {
	$FFGDIR=abs_path($ENV{"FFGDIR"});
	# set unix like path
	# $FFGDIR =~ s/\\/\//g;
}
# Directory of perl custom ffg packages
if ( defined ($ENV{"FFGINCLDIR"} ) ) {
	$FFGINCLDIR=abs_path($ENV{"FFGINCLDIR"}) ;
	eval "use lib \"$FFGINCLDIR\"";
} else {
	# Build ffgincldir from ffgdir
	$FFGINCLDIR = abs_path($FFGDIR) ;
	$FFGINCLDIR =~ s/\w+$// ;
	$FFGINCLDIR=sprintf "%s/incl",$FFGINCLDIR;
	eval "use lib \"$FFGINCLDIR\"";
}


} # End BEGIN
use Getopt::Long;
#use File::stat;
use File::Basename;
use File::Path;
#use File::Spec;
use XML::Simple;
use IO::Handle;
use Data::Dumper qw(Dumper);
use Cwd;
use Storable;
use Ffg::DbSchema;
use Ffg::ParseForms;
use Ffg::Misc;

usage () if ( ! GetOptions(
	"arrayelements=i"=>\$ArrayElements,		# Will generate a screen Record with n elements
	"checkonly"=>\$CheckOnly,		# dumps the generation data stop or continue
	"checkvariables"=>\$CheckVariable,	# parses the template to check dynamic variables
	"childformuse=s"=>\$ChildFormFile,			# Existing child Lycia form to be used (must be .fm2)
	"childforeignkey=s"=>\$ChildForeignKey,		# force child primary key
	"childprimarykey=s"=>\$ChildPrimaryKey,		# force child primary key
	"childtemplate=s"=>\$ChildTemplate,		# template used for child table
	"database=s"=>\$DatabaseName,
	"debug=i"=>\$DEBUGPRINT,		# dumps the generation data stop or continue
	"definecolumninform"=>\$ColumnInForm,	# only describe columns that are part of the form
	"definestyle=s"=>\$DefineStyle,		# describe columns LIKE table.column or explicitly (char(3))
	"checknotnull=s"=>\$CheckNotNull,	# at INPUT, check not null values
	"dumpdata=s"=>\$DumpData,		# dumps the generation data stop or continue
	"fieldexclude=s"=>\$ExcludeFields,		# Exclude only those fields (comma separated)
	"fieldinclude=s"=>\$IncludeFields,		# Include only those fields (comma separated)
	"forceerrors"=>\$ForceErrors,		# continues or errors when checking
	"forcetargetfile"=>\$ForceTargetFile,		# overwrite .flgtarget file
	"formclassname=s" =>\$FormClassName,		# form class name for grid and coord
	"formgenerate=s"=>\$GenerateFormName,			# Existing main Lycia form to be used (must be .fm2)
	"listformuse=s"=>\$ListFormFile,			# Existing list form ( to pick a parent from list) Lycia form to be used (must be .fm2)
	"formlookup"=>\$DoFormLookup,		# Include lookup fields
	"formmaxwidth=i"=>\$FormMaxWidth,		# Form max width for form generation
	"formparentexclude=s"=>\$ExcludeParentTable,		# form generation: exclude parent table xxx, keep parent tables if DoFormLookup
	"formtable=s"=>\$FormTable,		# Main table used
	"formtemplate=s"=>\$FormTemplate,		# Form template used for form generation
	"grandchildformuse=s"=>\$GrandChildFormFile,			# Existing grandchild Lycia form to be used (must be .fm2)
	"grandchildforeignkey=s"=>\$GrandChildForeignKey,		# force child primary key
	"grandchildprimarykey=s"=>\$GrandChildPrimaryKey,		# force grandchild primary key
	"grandchildtemplate=s"=>\$GrandChildTemplate,		# template used for child table
	"lang=s"=>\$Language,				# Standard messages and menus will use that language
	"listtemplate=s"=>\$ListModuleTemplate,		# Main template used
	"logfile=s"=>\$LogFile,				# write to log file
	"maintemplate=s"=>\$MainModuleTemplate,		# Main template used
	"modulegenerate=s"=>\$GenerateModuleName,			# Lycia module name to be generated ( .4gl file)
	"forceparenttable=s"=>\$ParentTableForced,			# force parent table name for tricky cases in guess_tables_roles
	"parentformuseuse=s"=>\$ParentFormFiles,			# Existing main Lycia form to be used (must be .fm2)
	"parentprimarykey=s"=>\$ParentPrimaryKey,		# force parent primary key
	"program=s"=>\$ProgramName,			# Lycia program name
	"projectname=s"=>\$ProjectName,	# Lycia project Name
	"skipfunctions=s"=>\$SkipFunctions,	# Skip the generation of some Functions
	"nolookupbuild"=>\$NoLookupBuild,	# Do not build lookup functions in that module
	"nowidgetpopbuild"=>\$NoWidgetPopulationBuild,	# Do not build lookup functions in that module
	"trace=i"=>\$trace,		# continues or errors when checking:
	"version"=>\$Version,
	"xposition=i"=>\$xposition,			# standard form position X
	"yposition=i"=>\$yposition,			# standard form position Y
	"executecmd=s"=>\$ExecuteCommand,	# execute the following command and send to stdout
	
	
	) ) ;

main () ;

sub main {
	%FormDescription=() ;
	# Check existence of template filesq

	$XML::Simple::PREFERRED_PARSER = 'XML::Parser';
	if ( defined ($ENV{"FFGDIR"} ) ) {
		$FFGDIR=abs_path($ENV{"FFGDIR"}) ;
	} else {
	  die "Please set FFGDIR env variable";
	}

	# Diretory of ffg parameters, language files etc: Mandatory
	if ( defined ($ENV{"FFGETCDIR"} ) ) {
		$FFGETCDIR=abs_path($ENV{"FFGETCDIR"}); 
	} else {
	  $FFGETCDIR=$FFGDIR . "/etc" ;
	}

	# read global parameters
	set_parameters_for("global") ;
	set_parameters_for("global_object_names") ;

	# read project parameters
	set_parameters_for($ProjectName,"","overwrite");

	# directory of database schemas
	if ( !defined ($FFGDATADIR) ) {
		if ( defined ($ENV{"FFGDATADIR"} ) ) {
			$FFGDATADIR=abs_path($ENV{"FFGDATADIR"}) ;
		} else {
			$FFGDATADIR=$FFGDIR . "/database" ;
		}
	}

	if ( !defined($Language) ) {
		$Language="ENU" ;
	}

	# set local messages and commands
	&set_application_messages( $Language ) ;

	my $time = time;
	my ($sec, $min, $hour, $day,$month,$year) = (localtime($time))[0,1,2,3,4,5];
	
	if ( defined($LogFile)) {
		open LOGFILE,">" . $LogFile or die "cannot open file " . $LogFile;
	} else {
		open LOGFILE,">&STDOUT" or die "cannot open STDOUT";
	}
	$GenerationTS = sprintf "%04s-%02s-%02s %02s:%02s:%02s",$year+1900,$month+1,$day,$hour,$min,$sec;
	if ( !defined($DatabaseName) ) {
		$DatabaseName=input ($QDatabaseName,1) ;
	} else {
		printf LOGFILE "The database for this project is : %s\n",$DatabaseName;
	}

	# Parse database schema etiher using qx_expt or better with SchemaSpy generated data
	# Build relationships between tables : data written in table description files by bld_primary_key
	$FfgSchemaFile=sprintf "%s/Schema_%s.hash",$FFGDATADIR,$DatabaseName ;
	$FfgPrimaryKeyFile=sprintf "%s/PrimaryKeys_%s.hash",$FFGDATADIR,$DatabaseName ;
	$FfgForeignKeyFile=sprintf "%s/ForeignKeys_%s.hash",$FFGDATADIR,$DatabaseName ;
	$FfgUniqueKeyFile=sprintf "%s/UniqueKeys_%s.hash",$FFGDATADIR,$DatabaseName ;
	$FfgLookupKeyFile=sprintf "%s/LookupKeys_%s.hash",$FFGDATADIR,$DatabaseName ;
	$FfgDuplicateKeyFile=sprintf "%s/DuplicateKeys_%s.hash",$FFGDATADIR,$DatabaseName ;
	our $Dbschema_xml_info = sprintf "%s\/%s.%s.xml",$FFGDATADIR,$DatabaseName,$DBVENDOR ;

	if ( -e $FfgSchemaFile ) {
		($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,$atime, $SchMtime, $ctime, $blksize, $blocks) = stat($FfgSchemaFile );
		printf LOGFILE "Existing db Schema OK: %s\n",$FfgSchemaFile;
	} else {
		$SchMtime=999999999999999999;
	}
	if ( -e $Dbschema_xml_info) {
		($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,$atime, $XMLMtime, $ctime, $blksize, $blocks) = stat($Dbschema_xml_info);
	}

	if ( $SchemaSource eq "qx_expt") {
		our $Dbschema_xml_info = sprintf "%s\/%s.xml",$FFGDATADIR,$DatabaseName ;
		if ((-e $Dbschema_xml_info) ) {
			printf "Building new Schema Hashes\n" ;
			($DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr)=parse_qxexpt_schema($Dbschema_xml_info) ;
		} else {	
			printf STDERR "Please build the dbschema xml file with qx_expt utility or schemaSpy\nand place it in %s\n",dirname($Dbschema_xml_info);
			exit(1);
		}
	} elsif ( $SchemaSource eq "schemaSpy") {
		if ( -e $FfgSchemaFile && $SchMtime > $XMLMtime ) {
			# Look if the schema has been stored in XML file and see if too old
			# Compare ages of XML file and stored hash file
			printf LOGFILE "Using up to date db Schema OK: %s\n",$FfgSchemaFile;
			%AllDbschema  = %{retrieve ($FfgSchemaFile)};
			$DBSchemaPtr = \%AllDbschema;
			%AllPrimaryKeys = %{retrieve ($FfgPrimaryKeyFile)};
			$PrimaryKeysPtr = \%AllPrimaryKeys;
			%AllForeignKeys = %{retrieve ($FfgForeignKeyFile)};
			$ForeignKeysPtr = \%AllForeignKeys ;
			%AllUniqueKeys = %{retrieve ($FfgUniqueKeyFile)} ;
			$UniqueKeysPtr = \%AllUniqueKeys ;
			%AllLookupKeys = %{retrieve ($FfgLookupKeyFile)};
			$LookupKeysPtr = \%AllLookupKeys ;
			%AllDuplicateKeys = %{retrieve ($FfgDuplicateKeyFile)};
			$DuplicateKeysPtr = \%AllDuplicateKeys ;			
		} else {
			# the persistent schema hashes have not been created, first parse the  schemaSpy file, then store to xxx.dat
			if ((-e $Dbschema_xml_info) ) {
				printf LOGFILE "Building new db Schema ... ";
				($DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$UniqueKeysPtr,$LookupKeysPtr,$DuplicateKeysPtr)=parse_schemaSpy($Dbschema_xml_info) ;
				# just after building the hashes, we store them to a file for fast retrieve on consecutive times
				printf LOGFILE "OK!";
				#%DBSchema=%$DBSchemaPtr;
				%AllDBSchema=%$DBSchemaPtr;
				#%PrimaryKeys=%$PrimaryKeysPtr;
				%AllPrimaryKeys=%$PrimaryKeysPtr;
				#%ForeignKeys=%$ForeignKeysPtr;
				%AllForeignKeys=%$ForeignKeysPtr;
				#%UniqueKeys=%$UniqueKeysPtr;
				%AllUniqueKeys=%$UniqueKeysPtr;
				#%LookupKeys=%$LookupKeysPtr;
				%AllLookupKeys=%$LookupKeysPtr;
				%AllDuplicateKeys=%$DuplicateKeysPtr;
				store \%AllDBSchema, $FfgSchemaFile  ;
				store \%AllPrimaryKeys,$FfgPrimaryKeyFile;
				store \%AllForeignKeys,$FfgForeignKeyFile ;
				store \%AllUniqueKeys,$FfgUniqueKeyFile;
				store \%AllLookupKeys,$FfgLookupKeyFile ;
				store \%AllDuplicateKeys,$FfgDuplicateKeyFile ;
			} else {	
				printf STDERR "Please build the dbschema xml file with qx_expt utility or schemaSpy\nand place it in %s\n",dirname($Dbschema_xml_info);
				exit(1);
			}
		}
	} else {
		die "please choose a db schema parser schemaSpy or qx_expt" ;
	}	

	our $QxWidgetsCount=0;

	set_parameters_for("CurrentValues","QxWorkSpace");
	if (!-d ($QxWorkSpace) || !defined($QxWorkSpace)) {
		printf LOGFILE "Lycia Workspace not found!: %s \n",$QxWorkSpace;
		die "please choose a valid Querix Workspace " . $QxWorkSpace . " or set QxWorkSpace in file " . $FFGETCDIR . "/CurrentValues.params";
	} else {
		printf LOGFILE "Lycia Workspace OK: %s\n",$QxWorkSpace;
	}


	# Lycia Project name

	if ( !defined($ProjectName) ) {
		$ProjectName=input($QProjName,1) ;
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

	if ( -d $Qx4glLocation) {
		printf LOGFILE "4gl location OK: %s\n",$Qx4glLocation;
	} else {
		printf LOGFILE "4gl location not found: %s\n",$Qx4glLocation;
	}

	if ( -d $QxPerLocation) {
		printf LOGFILE "Forms location OK: %s\n",$QxPerLocation;
	} else {
		printf LOGFILE "Forms location not found: %s\n",$QxPerLocation;
	}

	if (-d $FFGDATADIR ) {
		printf LOGFILE "Db schema location OK: %s\n",$FFGDATADIR;
	} else {
			printf LOGFILE "Db schema location not found: %s\n",$FFGDATADIR;
	}

	if (-d $FFGSIGNDIR ) {
		printf LOGFILE "Signature files location OK: %s\n",$FFGSIGNDIR;
	} else {
			printf LOGFILE "Signature files location not found: %s\n",$FFGSIGNDIR;
	}

	if (-d $FFGLOGDIR ) {
		printf LOGFILE "Log location OK: %s\n",$FFGLOGDIR;
	} else {
			printf LOGFILE "Log location not found: %s\n",$FFGLOGDIR;
	}

	if ( defined($GenerateModuleName) && !defined($ProgramName) ) {
		$ProgramName=input($QProgName,1) ;
	}

	# Lycia module name to be generated
	#if ( !defined($GenerateModuleName) && !defined($FormTemplate)) {
	if ( !defined($MainModuleTemplate) && !defined($FormTemplate)) {
		# $GenerateModuleName=input($QModName,1) ;
		die "Please choose at least one generation option: -modulegenerate <module name> OR -formgenerate <form name>";
	}

	if (defined($ListFormFile)) {
		$ListFormFile=sprintf "%s/%s",$QxPerLocation,$ListFormFile;
		$ListFormName = basename($ListFormFile) ;
		$ListFormName =~ s/\.per|\.fm2// ;
		if ( -e $ListFormFile) {
			printf LOGFILE "List form file OK: %s\n",$ListFormFile;
		} else {
			printf LOGFILE "List form file not found: %s\n",$ListFormFile;
		}
	}

	# some modules may use several forms like list function
	if (defined($FormsList[1]) &&  $FormsList[1] =~ /\.fm2/){
		$SecondFormFile=sprintf "%s/%s",$QxPerLocation,$FormsList[1];
		$SecondFormName=basename($SecondFormFile);
		$SecondFormName =~ s/\.per|\.fm2// ;
		if ( -e $SecondFormFile) {
			printf LOGFILE "Second form file OK: %s\n",$SecondFormFile;
		} else {
			printf LOGFILE "Second form file not found: %s\n",$SecondFormFile;
		}
	}
	if (defined($FormsList[2]) &&  $FormsList[2] =~ /\.fm2/){
		$ThirdFormFile=sprintf "%s/%s",$QxPerLocation,$FormsList[2];
		$ThirdFormName=basename($ThirdFormFile);
		$ThirdFormName =~ s/\.per|\.fm2// ;
		if ( -e $ThirdFormFile) {
			printf LOGFILE "Third form file OK: %s\n",$ThirdFormFile;
		} else {
			printf LOGFILE "Third form file not found: %s\n",$ThirdFormFile;
		}
	}

	if (defined($ExcludeFields)) {
		my @ExcludeList=split(/,/,$ExcludeFields);
		my $fl=0;
		while (defined($ExcludeList[$fl])) {
			$ExcludeList=sprintf "%s|\\b%s\\b",$ExcludeList,$ExcludeList[$fl];
			$fl++;
		}
		$ExcludeFields=$ExcludeList;
		$ExcludeFields =~ s/^\|// ;
	}

	if (defined($IncludeFields)) {
		my @IncludeList=split(/,/,$IncludeFields);
		my $fl=0;
		while (defined($IncludeList[$fl])) {
			$IncludeList=sprintf "%s|\\b%s\\b",$IncludeList,$IncludeList[$fl];
			$fl++;
		}
		$IncludeFields=$IncludeList;
		$IncludeFields =~ s/^\|// ;
	}

	if (!defined($NoLookupBuild)) {
		our $GenerateLookupFunctions=1;
	}
	if (!defined($NoWidgetPopulationBuild)) {
		our $GenerateWidgetPopulateFunctions=1;
	}

	@ModuleList=();
	@FormList=();
	@MainFormsList=();

	# HERE IS FORM GENERATION
	if ( defined($FormTemplate)) {
		# we generate a form or a set of forms
		$FormTemplateFile = sprintf "%s/form/%s",$FFGTPLTDIR,$FormTemplate;
		if ($FormTemplateFile !~ /\.ftplt$/ ) {
			$FormTemplateFile = $FormTemplateFile . ".ftplt" ;
		}
		if ( ! -e $FormTemplateFile) {
			# check that form template exists
			printf LOGFILE "Error: form template cannot be found: %s, ABORTING\n",$FormTemplateFile;
			printf STDERR "Error: form template cannot be found: %s, ABORTING\n",$FormTemplateFile;
			exit(1);
		}
		# this means we will Generate FORMS
		@GlobalTablesList = split (/,/,$FormTable);
		$frx=0;
		#foreach $FormTable ( @TablesList ) {
		my $tblx=0;
		while (defined($GlobalTablesList[$tblx])) {
			if (!defined($GenerateFormName)) {
				# for multi-table form generation, we give no form name, use Standard Prefix . tablename
				$MainFormsList[$tblx]=sprintf "%s%s",$FormStandardPrefix,$GlobalTablesList[$tblx];
			} else {
				$MainFormsList[$tblx]=$GenerateFormName;
			}
			generate_form($MainFormsList[$tblx],$FormTemplateFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName,$GlobalTablesList[$tblx],$ArrayElements) ; 
			my $FormLocation=$QxPerLocation;
			if ( $FormLocation =~ /$ProjectName/) {
				$FormLocation=$' ;
			}
			printf LOGFILE "Check the form %s in the Project Explorer, project %s, in folder %s\n",$FormsList[$tblx],$ProjectName,$FormLocation ;
			#undef($GenerateFormName);

			$tblx++;
		}
	} # end of forms generation

	if ( defined($MainModuleTemplate) ) {
		# we generate a module, this option is mandatory for module generation and determines we are generating a module
		#==> add below all the controls done between line 302 and 385
		my $frmx=0;			#we will set a while loop on number of forms generated, or 1
		if ($MainModuleTemplate !~ /\.mtplt$/) {
			$MainModuleTemplate = sprintf "%s/module/%s.mtplt",$FFGTPLTDIR,$MainModuleTemplate;
		} else {
			$MainModuleTemplate = sprintf "%s/module/%s",$FFGTPLTDIR,$MainModuleTemplate;
		}
		if ( -e $MainModuleTemplate) {
			# check that module template exists
			printf LOGFILE "Module template OK: %s\n",$MainModuleTemplate;
		} else {
			printf LOGFILE "Module template not found: %s\n",$MainModuleTemplate;
			printf STDERR "Module template not found: %s\n",$MainModuleTemplate;
			exit(1);
		}
		LOGFILE->flush();

		if (defined($ProgramName) ) {
			$ProgramsList[0]= $ProgramName;
			if ( !defined ($GenerateModuleName) ) {
				# GenerateModuleName is not mandatory, if not set, it take ProgramName's value
				#$ModulesList=$ProgramsList[0];
				$GenerateModuleName=$ProgramsList[0];
			}
		} else {
			# only in case of multi-programs generation, give automatic name $TblMngmtPrgRoot in global parameters
			if ( defined($FormTemplateFile)) {
				my $prgx=0;
				printf LOGFILE "Applying automatic program name parameter (TblMngmtPrgRoot) %s\n",$TblMngmtPrgRoot;
				while (defined($GlobalTablesList[$prgx])) {
					$ProgramsList[$prgx]=sprintf "%s%s",$TblMngmtPrgRoot,$GlobalTablesList[$prgx];
					$prgx++;
				}
			}
		}
		# Now scan the programs list array
		$prgx=0;
		while (defined($ProgramsList[$prgx])) {
			# Check the form file
			if ( !defined($ParentFormFiles) ) { 
				if ( defined($FormTemplateFile)) {
					# when we generate the form + the program, form file is not mandatory, so we set an automatic form name
					$ParentFormFiles=$MainFormsList[$prgx];
				} else {
					printf LOGFILE "-parentformfile option missing, ABORTING\n";
					printf STDERR "-parentformfile option missing, ABORTING\n";
					exit(1);
				}
			 } else {
				# Module generation
				# $ParentFormFiles = $ParentFormFiles ;
			}
			$MainFormFile=sprintf "%s/%s",$QxPerLocation,$ParentFormFiles;
			if ($MainFormFile !~ /\.fm2$/ ) {
				$MainFormFile = $MainFormFile . ".fm2" ;
			}
			$MainFormName = basename($MainFormFile) ;
			$MainFormName =~ s/\.per|\.fm2// ;

			if ( -e $MainFormFile ) {
				printf LOGFILE "Main form file OK: %s\n",$MainFormFile;
			} else {
				printf LOGFILE "Main form file not found: %s, ABORTING\n",$MainFormFile;
				printf STDERR "Main form file not found: %s, ABORTING\n",$MainFormFile;
				exit(1);
			}
			if ( !defined($GenerateModuleName)) {
				$GenerateModuleName = $ProgramsList[$prgx] ;
			}
			
			#Generate main module
			generate_module($GenerateModuleName,">",$MainModuleTemplate,$MainFormFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName) ;
			
			if ( defined($ListFormFile) && defined($ListModuleTemplate)) {
				#our $ListTable=$ParentTable;
				my $TemplateFile = sprintf "%s/templates/module/%s",$FFGDIR,$ListModuleTemplate;
				generate_module($GenerateModuleName,">",$TemplateFile,$ListFormFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
			}

			if ( defined($ChildTable) && defined($ChildTemplate)) {
				my $TemplateFile = sprintf "%s/templates/module/%s",$FFGDIR,$ChildTemplate;
				if (defined($ChildFormFile)) {
					generate_module($GenerateModuleName,">",$TemplateFile,$ChildFormFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
				} else {
					generate_module($GenerateModuleName,">",$TemplateFile,$MainFormFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
				}
			}
			if ( defined($GrandChildTable) && defined($GrandChildTemplate)) {
				my $TemplateFile = sprintf "%s/templates/module/%s",$FFGDIR,$GrandChildTemplate;
				if (defined($GrandChildFormFile)) {
					generate_module($GenerateModuleName,">",$TemplateFile,$GrandChildFormFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
				} else {
					generate_module($GenerateModuleName,">",$TemplateFile,$MainFormFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
				}
			}

			$FglTargetFile = sprintf "%s/source/.%s.fgltarget",$ProjectDir,$ProgramsList[$prgx] ;
			if ( ! -e $FglTargetFile || defined($ForceTargetFile) ) {
				print_fgltarget_file($FglTargetFile,$ProjectDir,$Qx4glLocation,$QxPerLocation,$ProgramsList[$prgx],\@ModulesList,\@FormsList,\@LibrariesList);
			}
			printf LOGFILE "Project %s: Program %s generated, contains modules:\n",$ProjectName,$ProgramsList[$prgx];
			$mdl=0;
			while (defined($ModulesList[$mdl])) {
				printf LOGFILE "\t%s\n",$ModulesList[$mdl];
				$mdl++
			}
			printf LOGFILE "Forms list:\n";
			$frm=0;
			while (defined($FormsList[$frm])) {
				printf LOGFILE "\t%s\n",$FormsList[$frm];
				$frm++
			}
			# check Eclipse fglproject file
			$FglProjectFile = sprintf "%s/.fglproject",$ProjectDir;
			if ( print_fglproject_file ($FglProjectFile,$ProgramsList[$prgx]) ==  -1  ) {
				printf LOGFILE "Please add the following line in %s\n",$FglProjectFile;
				printf LOGFILE "<buildTarget location=\"\" name=\"\%s\" type=\"fgl-program\"/>\n",$ProgramsList[$prgx];
				printf "Please add the following line in %s\n",$FglProjectFile;
				printf "<buildTarget location=\"\" name=\"\%s\" type=\"fgl-program\"/>\n",$ProgramsList[$prgx];
			}
			$prgx++ ;
			undef $ParentFormFiles;
			undef $MainFormFile;
			undef @ModulesList;
			undef @FormsList;
			undef @LibrariesList;
		}
	} # end of module generate

} # end  main

#
####################################################################################################################
#** @method generate_module  ($Module,$TemplateFile,$Form,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName)
#** reads one template file, one form file and write into generally one module
#** \param Module Value of the module to be generated, can be completed according to template name/type
#** \param OpenMode open the file in 'New file' mode (>) or 'Apped Mode' (>>)
#** \param Templatefile Name of the template file to be used
#** \param Form Name of the Lycia form to be parsed, must contain .fm2 extension
#** \param PrimaryKeysPtr Pointer to the Global Primary Keys map
#** \param ForeignKeysPtr Pointer to the Global Foreign Keys map
#** \param DatabaseName Database name
sub generate_module {
my ($Module,$OpenMode,$TmpltFile,$Form,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName) = (@_) ;

%DBSchema=%$DBSchemaPtr;
%PrimaryKeys=%$PrimaryKeysPtr;
%ForeignKeys=%$ForeignKeysPtr;
our $TemplateFile = $TmpltFile;
# Check templatefile is full path
if ( $TemplateFile !~ /^\w:|\/\w+/ ) {
	$TemplateFile = sprintf "%s\/module/%s",$FFGTPLTDIR,$TemplateFile;
}
$sep_save = $/ ;
$/ = "\n";
my $ModSubDir="";
my @PKCols = () ;
$mdll=0;
$frmnum=0;
undef ($ThisModuleInitWidgetsFct);

if ( $Module =~ /(.*[\/\\])(\w+)$/ ) {
	$ModuleSubDir=$1;
	$Module=$2;
}
if ( $TemplateFile =~ /parent.*child/ ) {
	$ModuleFile=sprintf "%s/%s%s%s.4gl",$Qx4glLocation,$ModuleSubDir,$Module,$ParentChildModuleSuffix ;
}	elsif ( $TemplateFile =~ /\-list\-/ ) {
	$ModuleFile=sprintf "%s/%s%s%s.4gl",$Qx4glLocation,$ModuleSubDir,$Module,$ListModuleSuffix ;
} elsif ( $TemplateFile =~ /\-parent\-/ ) {
	$ModuleFile=sprintf "%s/%s%s%s.4gl",$Qx4glLocation,$ModuleSubDir,$Module,$ParentModuleSuffix ;
}	elsif ( $TemplateFile =~ /\-child\-/ ) {
	$ModuleFile=sprintf "%s/%s%s%s.4gl",$Qx4glLocation,$ModuleSubDir,$Module,$ChildModuleSuffix;
}	elsif ( $TemplateFile =~ /\-grandchild\-/ ) {
	$ModuleFile=sprintf "%s/%s%s%s.4gl",$Qx4glLocation,$ModuleSubDir,$Module,$GrandChildModuleSuffix;
}	elsif ( $TemplateFile =~ /\-pick\-/ ) {
	$ModuleFile=sprintf "%s/%s%s%s.4gl",$Qx4glLocation,$ModuleSubDir,$Module,$LookupModuleSuffix;
}	elsif ( $TemplateFile =~ /standalone/ ) {
	$ModuleFile=sprintf "%s/%s%s%s.4gl",$Qx4glLocation,$ModuleSubDir,$Module,$StandaloneModuleSuffix ;
} elsif ( $TemplateFile =~ /\-lookup\-/ ) {
	$ModuleFile=sprintf "%s/%s%s%s.4gl",$Qx4glLocation,$ModuleSubDir,$Module,$LookupModuleSuffix ;
} else {
	$ModuleFile=sprintf "%s%s/%s.4gl",$Qx4glLocation,$Module,$ModuleSubDir ;
}
our $ModuleName=$Module;
our $FormName=basename($Form);
push ( @ModulesList,$ModuleFile) ;
if (!defined($FormList{$FormName})) {
	$FormList{$FormName}=$Form;
	push (@FormsList,$Form);
}

printf "Generating module %s for program %s, from form %s in %s\n",basename($ModuleFile),$ProgramName,basename($Form),dirname($ModuleFile);
printf LOGFILE "Generating module %s for program %s, from form %s in %s\n",basename($ModuleFile),$ProgramName,basename($Form),dirname($ModuleFile);$FormName =~ s/\.fm2// ;

if (!defined($DataEquiv)) {
	$DataEquivPtr = set_LyciaFieldDefs();
}
if (!defined($FormField->{$FormName})) {
	# finish this if just after guess_tables_roles modif ericv 15/09/2018
	%TablesList = [] ;
	my ($FormFieldPtr,$ScreenRecordP,$TablesListPtr) = parse_fm2($Form,$DBSchemaPtr,$DataEquivPtr) ;
	
	$FormField = $$FormFieldPtr;
	%ScreenRecord = %{$$ScreenRecordP} ;
	%TablesList = %{$$TablesListPtr};

	# Add previous field and next field fields to FormField: allows to identify lookup columns
	my $PreviousField="";
	my $NextField="";
	foreach my $key (sort { $FormField->{$FormName}->{$a}->{'Order'} cmp $FormField->{$FormName}->{$b}->{'Order'} }keys %{ $FormField->{$FormName} } ) {
		if ( $PreviousField ne "") {
			$FormField->{$FormName}->{$key}->{PreviousField} = $PreviousField;
		}
		$FormField->{$FormName}->{$PreviousField}->{NextField} = $key ;
		$PreviousField = $key ;	
	}
	# TablesList is built only from the main file because tables roles do no change
	if (!defined ($TablesList)) {
		$a=1;
	} 
	
	# keep only relevant Dbschema, Primary Keys, Foerign keys etc to handle small hashes
	undef %Dbschema ;
	foreach my $key ( keys %AllDbschema ) {
		if (defined($TablesList{$key})) {
			$Dbschema{$key}=$AllDbschema{$key};
		}
	}
	undef %PrimaryKeys ;
	foreach my $key ( keys %AllPrimaryKeys ) {
		if (defined($TablesList{$key})) {
			$PrimaryKeys{$key}=$AllPrimaryKeys{$key};
		}
	}
	undef %ForeignKeys ;
	foreach my $key ( keys %AllForeignKeys ) {
		#my ($child,$parent) = split (/:/,$key);
		my $child = $AllForeignKeys{$key}->{childTable};
		my $parent = $AllForeignKeys{$key}->{parentTable};
		# look if both tables are in TablesList
		if (defined($TablesList{$parent}) || defined($TablesList{$child})) {
			$ForeignKeys{$key}=$AllForeignKeys{$key};
		}
	}
	undef %UniqueKeys ;
	foreach my $key ( keys %AllUniqueKeys ) {
		if (defined($TablesList{$key})) {
			$UniqueKeys{$key}=$AllUniqueKeys{$key};
		}
	}
	undef %LookupKeys ;
	foreach my $key ( keys %AllLookupKeys ) {
		my ($child,$parent) = split (/:/,$key);
		# look if both tables are in TablesList
		# printf "%s -> %s\n",$child,$parent ;
		if ( $parent eq "product") {
			$a=1;
		}
		if (defined($TablesList{$parent}) && defined($TablesList{$child})) {
			$LookupKeys{$key}=$AllLookupKeys{$key};
		}
	}
	undef %DuplicateKeys ;
	foreach my $key ( keys %AllDuplicateKeys ) {
		# look if both tables are in TablesList
		# printf "%s -> %s\n",$child,$parent ;

		if (defined($TablesList{$key}) ) {
			$DuplicateKeys{$key}=$AllDuplicateKeys{$key};
		}
	}
	if (%ScreenRecord) {
		$a=1;
	}

	set_tables_roles ($FormName) ;

	# set Form information in the %Dbschema structure (for future filters)
	#foreach my $key ( keys %{ $DBSchema{$ParentTable} }  ) {

	foreach my $key ( keys %{ $FormField->{$FormName} } ) {
		$a=1;
		my $tbl=$FormField->{$FormName}->{$key}->{Table};
		my $field=$FormField->{$FormName}->{$key}->{Column};
		if ( $tbl !~ /formonly/i ) {
			$FormField->{$FormName}->{$key}->{Section} = $TablesList{$tbl}->{Section};
		} else {
			# take the section of the next field
			if (defined($FormField->{$FormName}->{$key}->{NextField})) {
				my $OtherField=$FormField->{$FormName}->{$key}->{NextField};
			} else {
				my $OtherField=$FormField->{$FormName}->{$key}->{PreviousField};
			}
			my $OtherFieldTable=$FormField->{$FormName}->{$OtherField}->{Table};
			$FormField->{$FormName}->{$key}->{Section} = $TablesList{$OtherFieldTable}->{Section};
			next ;
		}
		next if field =~ /^$/ ;
		# set Form field section from TablesList->Section
		$FormField->{$FormName}->{$key}->{Section} = $TablesList{$tbl}->{Section};

		# specify is field is PK or
		if ( defined($Dbschema{$tbl}->{$field}->{IsPK})) {
			$FormField->{$FormName}->{$key}->{IsPK} = 1;
		}
		if ( defined($Dbschema{$tbl}->{$field}->{IsFK})) {
			$FormField->{$FormName}->{$key}->{IsFK} = 1;
		}
		if (defined($Dbschema{$tbl}->{$field})) {
			$Dbschema{$tbl}->{$field}->{Role}=$FormField->{$FormName}->{$key}->{Role};
			$Dbschema{$tbl}->{$field}->{Section}=$FormField->{$FormName}->{$key}->{Section};
			$Dbschema{$tbl}->{$field}->{Noentry}=$FormField->{$FormName}->{$key}->{Noentry};
		}
	
	}
}
$a=1;
	# check here if no PKCols or PK listed in options ....
#} # finish this if just after guess_tables_roles modif ericv 15/09/2018

	if ($DEBUGPRINT > 0 && !defined ($InfoDumped) ) {
		dump_form_info ($FormName) ;
		dump_database_info ();
		$InfoDumped=1;
	}

	if (!defined($ParentTable) && !defined($ListTable)) {
		die "There is not parent or list table, please check the db schema";
	}

	# If primary keys have been given as ffg options
	if (defined($GrandChildPrimaryKey) && $TmpltFile =~ /grandchild/ ) { # primary key is given as an option at launch time
		# Primary key has been forced in the program options
		@PKCols=split(/,/,$GrandChildPrimaryKey);
		$PrimaryKeys{$GrandChildTable}->{parentColumns}=$GrandChildPrimaryKey;
		$KeyMode="pkey"; 
		foreach my $key ( keys %{ $DBSchema{$GrandChildTable} }  ) {
				if ( defined($DBSchema{$GrandChildTable}{$key}->{'IsPK'}) ) {
					undef $DBSchema{$GrandChildTable}{$key}->{'IsPK'};
				}
		}
		my $pkx=0;
		while (defined($PKCols[$pkx])) {
			$DBSchema{$GrandChildTable}{$PKCols[$pkx]}->{'IsPK'} = 1;
			$pkx++;
		}
	} elsif (defined($ChildPrimaryKey) && $TmpltFile =~ /child/ ) { # primary key is given as an option at launch time
		# Primary key has been forced in the program options
		@PKCols=split(/,/,$ChildPrimaryKey);
		$PrimaryKeys{$ChildTable}->{parentColumns}=$ChildPrimaryKey;
		$KeyMode="pkey"; 
		foreach my $key ( keys %{ $DBSchema{$ChildTable} }  ) {
			if ( defined($DBSchema{$ChildTable}{$key}->{'IsPK'}) ) {
				undef $DBSchema{$ChildTable}{$key}->{'IsPK'};
			}
		}
		my $pkx=0;
		while (defined($PKCols[$pkx])) {
			$DBSchema{$ChildTable}{$PKCols[$pkx]}->{'IsPK'} = 1;
			$pkx++;
		}
	} else {
		# Primary keys have not be set explicitly, look in %TablesList
		#First try to get from primary key constraint
		if ( !defined($PKCols[0])) {
			if ( $TmpltFile =~ /parent|standalone/ ) {
				@PKCols = split(/,/,$TablesList{$ParentTable}->{PrimaryKey}) ;
				$Section="parent";
			} elsif ( $TmpltFile =~ /grandchild/ ) {
				@PKCols = split(/,/,$TablesList{$GrandChildTable}->{PrimaryKey}) ;
				$Section="grandchild";
			} elsif ( $TmpltFile =~ /child/ ) {
				@PKCols = split(/,/,$TablesList{$ChildTable}->{PrimaryKey}) ;
				$Section="child";
			} elsif ( $TmpltFile =~ /list/ ) {
				@PKCols = split(/,/,$TablesList{$ListTable}->{PrimaryKey}) ;
				$Section="list";
			} else {
				printf STDERR "Determining %s table's primary key: not sure about how to find it\n",${ParentTable};
			}
		}
	}

	if ( $#PKCols >= 0)  {
		$KeyMode="pkey";
	} else {
		# Primary keys not found => Second try to get from unique key
		if ( $TmpltFile =~ /parent|standalone/ ) {
			@PKCols = list_table_columns(${ParentTable},"","","","ukey","","");
		} elsif ( $TmpltFile =~ /grandchild/ ) {
			@PKCols = list_table_columns(${GrandChildTable},"","","","ukey","","");	
		} elsif ( $TmpltFile =~ /child/ ) {
			@PKCols = list_table_columns(${ChildTable},"","","","ukey","","");	
		} else {
			printf STDERR "Determining %s table's primary key: not sure about how to find it\n",${ParentTable};
		}
			# Use unique key instead
		if ( $#PKCols >= 0)  {
			$KeyMode="ukey";
			printf LOGFILE "The table %s has no primary key, using the first unique index available ",$ParentTable;
		} else {	
			printf STDERR "The table %s has no primary key, please check xml schema file ",$ParentTable;
			die "exiting" ;
		}
	} 

# set screen record name
# Determine Screen Record Names
if ( keys ( %ScreenRecord ) > 0 ) {
	foreach my $srname ( keys %{ScreenRecord->{$FormName} } ) {
		if ( defined($ScreenRecord{$FormName}->{$srname}->{'ElemCount'})) {
			if ( $TemplateFile =~ /$PicklistAttribute|$ListAttribute/) {
				$PickListScreenRecord=$srname;
			} elsif ($ScreenRecord{$FormName}->{$srname}->{'Order'} == 1) {
				our $ChildScreenRecord=$srname;
			} elsif ($ScreenRecord{$FormName}->{$srname}->{'Order'} == 2) {
				our $GrandChildScreenRecord=$srname;
			}
		}
	}
}

# Building the Input Event  AFTER FIELD / On change list for this form
# 1st takes primary key fields, then foreign key, then not null if required
# Then merge the 3 into one Hash %InputEventFields

# Building After Field fields list ( list of primary keys and foreign keys having columns in the form)
my @AfterFieldPrimaryKey=list_form_fields ($SRCHANDLE,$FormName,".*",$Section,".*","false","pkey","","","listkey") ;
my $aft=0;

while (defined($AfterFieldPrimaryKey[$aft])) {
	my ( $field,$table,$container) = split /:/,$AfterFieldPrimaryKey[$aft];
	my $key=$AfterFieldPrimaryKey[$aft];
	$InputEventFields{$key}->{Order} = $FormField->{$FormName}->{$key}->{Order};
	$InputEventFields{$key}->{Section}  = $FormField->{$FormName}->{$key}->{Section};
	$InputEventFields{$key}->{Field} = $FormField->{$FormName}->{$key}->{Column};
	$InputEventFields{$key}->{Table} = $FormField->{$FormName}->{$key}->{Table};
#	$InputEventFields{$key}->{DoAfterField}=1;
	if (defined($FormField->{$FormName}->{$key}->{'ScreenRecord'})) {
		$InputEventFields{$key}->{ScreenRecord}=$FormField->{$FormName}->{$key}->{'ScreenRecord'};
	}
	$InputEventFields{$key}->{PKY} = 1 ;
	# $InputEventFields{$key}->{PKY} = $PrimaryKeys{$table};
	if ( $aft == $#AfterFieldPrimaryKey) {
		# mark is this column is the last column of the PK in the form
		$InputEventFields{$key}->{IsLastPKColumn} = 1;
		$InputEventFields{$key}->{PkyColList}=$PrimaryKeys{$InputEventFields{$key}->{Table}}->{parentColumns};
		$InputEventFields{$key}->{NotNull} = 1 ;
		$InputEventFields{$key}->{PKY}=1;
		$InputEventFields{$key}->{DoAfterField}=1;
		$InputEventFields{$key}->{ChkPryKeyFct} = sprintf "%s_%s",$SqlCheckPrimaryKeyFct,$InputEventFields{$key}->{Table}
	}
	$aft++;
}
# Same for the foreign keys of this section
my @AfterFieldForeignKey=list_form_fields ($SRCHANDLE,$FormName,".*",$Section,".*","false","fkey","","","listkey") ;
my $aft=0;
while (defined($AfterFieldForeignKey[$aft])) {
	my ( $field,$table,$container) = split /:/,$AfterFieldForeignKey[$aft];
	my $key=$AfterFieldForeignKey[$aft];
	$InputEventFields{$key}->{Order} = $FormField->{$FormName}->{$key}->{Order};
	$InputEventFields{$key}->{Section}  = $FormField->{$FormName}->{$key}->{Section};
	$InputEventFields{$key}->{Field} = $FormField->{$FormName}->{$key}->{Column};
	$InputEventFields{$key}->{childTable} = $FormField->{$FormName}->{$key}->{Table};
	$InputEventFields{$key}->{FKY}=1;
	$InputEventFields{$key}->{DoAfterField}=1;
	if (defined($FormField->{$FormName}->{$key}->{'ScreenRecord'})) {
		$InputEventFields{$key}->{ScreenRecord}=$FormField->{$FormName}->{$key}->{'ScreenRecord'};
	}

	($InputEventFields{$key}->{childColumns},$InputEventFields{$key}->{parentTable},$InputEventFields{$key}->{parentColumns}) = get_this_FK($table,$field);
	# set a while loop to catch as many fields from parent table as possible (loop on NExtField)
	my $NextField=$FormField->{$FormName}->{$key}->{NextField};
	while ( $NextField!~ /^$/ ) {
		if ( defined($FormField->{$FormName}->{$NextField}->{lookupTable})) {
			if ( $FormField->{$FormName}->{$NextField}->{lookupTable} eq $InputEventFields{$key}->{parentTable}) {	
				$InputEventFields{$key}->{descriptionColumn} = $FormField->{$FormName}->{$NextField}->{lookupColumn};
				$InputEventFields{$key}->{descriptionField} = $FormField->{$FormName}->{$NextField}->{Field};
				$InputEventFields{$key}->{LookupFct} = sprintf "%s_%s_%s",$SqlLookupFct,$InputEventFields{$key}->{childTable},$InputEventFields{$key}->{parentTable};
				$NextField=$FormField->{$FormName}->{$NextField}->{NextField}; # Look at next field ...
			} else {
				last ;
			}
		} elsif ( $FormField->{$FormName}->{$NextField}->{Table} eq $InputEventFields{$key}->{parentTable}) {
			$InputEventFields{$key}->{descriptionColumn} = $FormField->{$FormName}->{$NextField}->{Column};
			$InputEventFields{$key}->{descriptionField} = $FormField->{$FormName}->{$NextField}->{Field};
			$InputEventFields{$key}->{LookupFct} = sprintf "%s_%s_%s",$SqlLookupFct,$InputEventFields{$key}->{childTable},$InputEventFields{$key}->{parentTable};
			$NextField=$FormField->{$FormName}->{$NextField}->{NextField};
		} else {
			last;
		}
		if ( !defined($InputEventFields{$key}->{LookupFct})) {
			$InputEventFields{$key}->{ChkForeignKeyFct} = sprintf "%s_%s_%s",$SqlCheckForeignKeyFct,$InputEventFields{$key}->{childTable},$InputEventFields{$key}->{parentTable};
		}
	}

					
	$aft++;
}

my @BeforeFieldBox=list_form_fields ($SRCHANDLE,$FormName,".*",$Section,".*","false","attr","","","listkey","","ComboBox:BeforeField") ;
my $bff=0;
while (defined($BeforeFieldBox[$bff])) {
	my ( $field,$table,$container) = split /:/,$BeforeFieldBox[$bff];
	my $key = $BeforeFieldBox[$bff];
	$InputEventFields{$key}->{DoBeforeField}=1;
	$bff++;
}
prepare_populate_widgets_functions($SRCHANDLE,$MainFormName,".*",$Section) ;

if ( $CheckNotNull) {
	# Same for the not null attribute columns of this section
	my @AfterFieldNotNull=list_form_fields ($SRCHANDLE,$FormName,".*",$Section,".*","false","attr","","","listkey") ;
} else {
	@AfterFieldNotNull=();
}

my $aft=0;
while (defined($AfterFieldNotNull[$aft])) {
	my ( $field,$table,$container) = split /:/,$AfterFieldNotNull[$aft];
	my $key=$AfterFieldNotNull[$aft];
	if ( !defined($InputEventFields{$key})) {
		$InputEventFields{$key}->{Order} = $FormField->{$FormName}->{$key}->{Order};
		$InputEventFields{$key}->{Section}  = $FormField->{$FormName}->{$key}->{Section};
		$InputEventFields{$key}->{Field} = $FormField->{$FormName}->{$key}->{Column};
		$InputEventFields{$key}->{Table} = $FormField->{$FormName}->{$key}->{Table};
		$InputEventFields{$key}->{DoAfterField}=1;
		if (defined($FormField->{$Form}->{$key}->{'ScreenRecord'})) {
			$InputEventFields{$key}->{ScreenRecord}=$FormField->{$Form}->{$key}->{'ScreenRecord'};
		}
	}
	$InputEventFields{$key}->{NotNull} = 1 ;
	$aft++;
}


$SignatureFile = sprintf "%s/%s/%s/%s.sig",$FFGSIGNDIR,$ProjectName,$ProgramName,basename($ModuleFile);
$SignatureFile =~ s/\.4gl// ;
if ( !(-d (dirname($SignatureFile)))) {
	mkpath (dirname($SignatureFile));
}

if (defined ($CheckOnly) ) {
	exit (0);
}
$PreProcessFile = sprintf "%s/%s/%s/%s.expanded",$FFGSIGNDIR,$ProjectName,$ProgramName,basename($TemplateFile);
my $SourceOpen = sprintf "%s%s",$OpenMode,$ModuleFile ;
my $SigOpen = sprintf "%s%s",$OpenMode,$SignatureFile ;


#open our $SRCHANDLE,"$SourceOpen" or die "Could not create or append source module" . $ModuleFile ;
$Hdl++;
open our $SRCHANDLE,"$SourceOpen" or die "Could not create or append source module" . $ModuleFile ;
open our $SIGNHANDLE,"$SigOpen" or die "Could not create or append signature file  " . $SignatureFile ;
my $TpltLine="" ;
#
# prepare modules and forms list to generate fgltarget file
#$frmnum=0;


$mdll++;
$frmnum++;

$n=10 ;
our $OutLineNum=0;
our $FunctionName ="";
$.=0;
$StmtLine=0;
$TmpltLineNum=0;

# if there are includes, paste all the files into one file
my $TotalTmpltLines=preprocess_template ($TemplateFile,$PreProcessFile);

# function that processes the whole template
our $IndentLevel=0;
process_template ($PreProcessFile) ;

$/ = $sep_save ;
close ($SRCHANDLE);

my $mdl=0;

} # end generate_module

sub process_template {
	my ($TemplateFile) = ( @_) ;
	# we now read the expanded template
	if ( $TemplateFile !~ /^\// && $TemplateFile !~ /^\w:/ ) {
		$TemplateFile = sprintf "%s\/module/%s",$FFGTPLTDIR,$TemplateFile;
	}
	open my $TEMPLATE,$TemplateFile or die "Could not open template file " . $TemplateFile ;
	my $TpltLine="" ;
	#
	# prepare modules and forms list to generate fgltarget file
	#$frmnum=0;


	$mdll++;
	$frmnum++;

	$n=10 ;
	our $OutLineNum=0;
	our $FunctionName ="";
	$.=0;
	$StmtLine=0;
	our $TmpltLineNum=0;

	READTMPL: while ( $TpltLine=<$TEMPLATE> ) {
		$TmpltLineNum++;
		undef($MoreToPrint);
		if ( $TpltLine =~ /^\/#/ ) {
			next READTMPL ;    #ffg comment,not to be printed
		}
		if ( $TpltLine =~ /^@(\w+)/ ){
			$BlockName=$1;
			next READTMPL ;    explicit block name
		} 
		# define statement / function call position in line, for future use
		# $IndentLevel=0;
		if (defined($trace)) { print $TpltLine ; }

		if ( $TpltLine =~ /^(\t*)\<Script:/ ) {
			$IndentLevel = ($& =~ tr/\t//);
		} elsif ( $TpltLine =~ /^(\s+).*/ ) {
			$IndentLevel = ($1 =~ tr/\t//);
		} 
		
		# Add a module in the modules list of fgltarget
		if ( $TpltLine =~ /^<AddRqrmnt:(\w+)::(.*):AddRqrmnt>/ ) {
			if ( $1 eq "fgl" ) {
				$ModulesList[$mdll]=sprintf "%s/%s",$Qx4glLocation,$2;
				$mdll++;
			} elsif ( $1 eq "lib" ) {
				$LibrariesList[$libl]=sprintf "%s",$2;
				$libl++;
			} elsif ( $1 eq "per" ) {
				$FormsList[$frmnum]=sprintf "%s/%s",$QxPerLocation,$1;
				$frmnum++;
			} else {
				die "Add Requirement " . $1 . " Not supported" ;
			} 
			next READTMPL ;
		}
		# catch the name of the function as defined in the template
		if ( $TpltLine =~ /^\s*FUNCTION\s+(.*)\(/i ||
		$TpltLine =~ /^\s*REPORT\s+(.*)\(/i ||
		$TpltLine =~ /^\s*(MAIN)/i ) {
			our $TemplateFctName = $1 ;
			printf LOGFILE "    building function %s\n",$CurrentFctName ;
		}
		
		if ( defined($SkipFunctions)) {
			#this block handles the Skip Functions functionality ( you want to skip template's standard functions)
			while ( $TpltLine =~ /$SkipFunctions/) {
				if ( $TpltLine =~ /^\s*FUNCTION\s+/ ) {
					# do not generate functions matching the regexp
					# We asked to skip the generation of some functions: check if that function is in the list, and read until END FUNCTION
					do {
						$TpltLine=<$TEMPLATE>;
					} until ( $TpltLine =~ /^\s*END FUNCTION/) ;
					next READTMPL ;
				} elsif ( $TpltLine =~ /^\s*COMMAND\s+/ ) {
					# do not generate the MENU commands that match the regexp
					# CALLs to those functions are supposed to be placed in those MENU options
					do {
						$TpltLine=<$TEMPLATE>;
					} until ( $TpltLine =~ /^\s*COMMAND|^\s*END MENU/) ;
					#next PROCESSTMPL ;
				} elsif ( $TpltLine =~ /^\s*SHOW OPTION\s+|^\s*HIDE OPTION\s+/ ) {
					$TpltLine=<$TEMPLATE>;
				} elsif ( $TpltLine =~ /^\s*#/ ) {
					$TpltLine=<$TEMPLATE>;
				} else {
					# Anything else matching the regexp.
					next READTMPL ;
					$b=1;
				}
			}
		}
		# Replace FFG Variable names by their value
		while ( $TpltLine =~ /\$\{(.*)\}?/ ) {
			if ( $TpltLine =~ /\$\{(\w+)\}/ ) {
				$FfgVariable=$1;
				if (defined($$FfgVariable)) {
					$TpltLine =~ s/\$\{(\w+)\}/${$FfgVariable}/ ;
					$a=1 ;
				} else {
					if (!defined($CheckVariables) && !defined($${FfgVariable}) ) {
						if (!defined($ForceErrors) ) {
							printf LOGFILE "Error: Perl variable is not defined: \$" . ${FfgVariable} . " in line " . $TmpltLineNum . " " . $TpltLine . "\n" . $TpltLine ;
							$ReplaceLoops++;
							
						} else {
							printf LOGFILE "Error: Perl variable is not defined: \$" . ${FfgVariable} . " in line " . $TmpltLineNum . " " . $TpltLine . "\n" . $TpltLine  ;
							next READTMPL ;
						}
					} else {
						printf LOGFILE "Error: Perl variable is not defined: \$" . ${FfgVariable} . " in line " . $TmpltLineNum . "\n"  . $TpltLine;
						
					}
					if ( $ReplaceLoops > $MaxReplaceAttempts) {
						printf LOGFILE "Error: Perl variable is not defined: " . ${PerlVariable} . " in line " . $TmpltLineNum . "\n" . $TpltLine;
						printf STDERR "Error: Perl variable is not defined: " . ${PerlVariable} . " in line " . $TmpltLineNum . "\n" . $TpltLine;
						die  "Aborting generation\n";
					}
				}
				if (defined($CheckVariables)) {
					if (defined($${FfgVariable}) ) {
						printf LOGFILE "\$%s = %s\n",${FfgVariable},$${FfgVariable};
					} else {
						printf LOGFILE "Error: Perl variable is not defined: \$" . ${FfgVariable} . " in line " . $TmpltLineNum . "\n" . $TpltLine;
					}
					next READTMPL ;
				}
			} else {
				$a=1;
			}
		} # end while complet ${xxx}
		# take function name
		if ( $TpltLine =~ /^\s*FUNCTION\s+([\w\$\{\}_]+)/i ||
		$TpltLine =~ /^\s*REPORT\s+([\w\$\{\}_]+)/i ||
		$TpltLine =~ /^\s*(MAIN)/i ) {
			our $CurrentFctName = $1 ;
			printf LOGFILE "    building function %s\n",$CurrentFctName ;
		}

		# Special case for tested perl variables ( $!variable )
		my $ReplaceLoops=0;
		while ( $TpltLine =~ /\$!(\w+)/ ) {
			$PerlVariable=$1;
			if ($${PerlVariable} ne "") {
				$TpltLine =~ s/\$!(\w+)/\$${PerlVariable}/ ;
			} else {
				#printf LOGFILE "Error: Perl variable is not defined: " . ${PerlVariable} . " in line " . $TmpltLineNum ;
				$a=1;
				$ReplaceLoops++;
			}
			if ( $ReplaceLoops > $MaxReplaceAttempts) {
				printf LOGFILE "Error: Perl variable is not defined: " . ${PerlVariable} . " in line" . $TmpltLineNum . "\n" ;
				printf STDERR "Error: Perl variable is not defined: " . ${PerlVariable} . " in line"  . $TmpltLineNum . "\n" ;
				die  "Aborting generation\n";
			}
		}

		# Previously look if statement end + more to print
		if ( $TpltLine =~ /\s*:Script>(\S+)/ && $TpltLine !~ /noprint/) {
			$MoreToPrint=1;
		} else {
			$MoreToPrint=0;
		}
		# execute command xxx in pattern file, command line contains <Script: xxxxx >/
		if ( $TpltLine =~ /<Script:\s*(.*)/) { 
			undef($statement) ;
			$StmtComplete=0;
			my $linestart=$` ;
			$statement=sprintf "%s",$1 ;
			if ( $linestart =~ /^\s+$/ ) {
				$linestart = "" ;
			}
				
			# take eventual other stuff to print after the statement, no other statement allowed on the right
			#if ( $statement =~ />\// ) {
				#$statement = $`;
			#}
			chomp($statement) ;
			# print part of line on the left of the command, if any
			if ( length($linestart) > 1 ) {
				printf $SRCHANDLE "%s",$linestart ;
				if ( $DEBUGPRINT > 2) { printf LOGFILE "%s",$linestart ; }
			}

			if ( $TpltLine =~ /<Script:(.*):Script>/ ) {
				$StmtComplete=1;  
				$statement = $1;
				$lineend=$';
			} else {
				# statement finishes with >/, if multi-line statement then
				# read the next line until finding a >/
				#while ($TpltLine !~ /\s*:Script>/ && ($TpltLine=<TEMPLATE>) ) {
				while ($TpltLine !~ /:Script>/ && ($TpltLine=<$TEMPLATE>) ) {
					$TmpltLineNum++;
					$TpltLine =~ s/^[\t\s]*//g;
					$StmtStart=$statement;
					$statement=sprintf "%s\n%s",$StmtStart,$TpltLine ;
				}
				if ( $statement =~ /:Script>(.*)/ ) {
					$lineend=$1;
				}
				$StmtComplete=1;  
				#$statement =~ s/\s*:Script>/;/ ;
				$statement =~ s/\s*:Script>.*// ;
			}
			if ( $StmtComplete == 1 && $statement !~ /^\s*$/) {
				#undef ($RetFieldsCount);
				if (defined($CheckVariables) && $statement =~ /\$\w+\s+=/ ) {
					
					my $evalStatus=eval ($statement);
					next READTMPL ;
				}
				
				# execution of the script
				#transform script command 'print' by printf $SRCHANDLE
				#while ( $statement =~ /\bprint\b(\".*\")/ ) {
				# remove commented code
				$statement =~ s/#.*$// ;
				#while ( $statement =~ /\bprint\b(.*);.*\n/ ) {
				while ( $statement =~ /\bprint\b(.*);\s*\n/ ) {
					my $NewPrintStmt=sprintf "ffg_print_short (%s,'lf',%d)",$1,$IndentLevel;
					$statement =~ s/\bprint\b(.*);.*\n/ $NewPrintStmt ;/;
				}
				while ( $statement =~ /\bprintNoLF\b(.*);\s*\n/ ) {
					my $NewPrintStmt=sprintf "ffg_print_short (%s,'nolf',%d)",$1,$IndentLevel;
					$statement =~ s/\bprintNoLF\b(.*);.*\n/ $NewPrintStmt ;/;
				}
				while ( $statement =~ /\bprintNoLFOnSameLine\b(.*);\s*\n/ ) {
					my $NewPrintStmt=sprintf "ffg_print_short (%s,'nolf',0)",$1;
					$statement =~ s/\bprintNoLFOnSameLine\b(.*);.*\n/ $NewPrintStmt ;/;
				}
				our $Statement=$statement ;
				# printf "%s\n",$Statement ;
				undef ($RetFieldsCount);
				my $evalStatus=eval ($statement);
				my @Errors=$@ ;
				
				#if ( !defined($evalStatus) ) {
				if ( $Errors[0] ne "") {
						printf STDERR "%s:L %d, Perl statement has wrong syntax:%s\n%s",$TemplateFile,$TmpltLineNum-1,$statement,$Errors[0] ;
						printf LOGFILE "%s:L %d, Perl statement has wrong syntax:%s\n%s",$TemplateFile,$TmpltLineNum-1,$statement,$Errors[0] ;
				}
				$StmtComplete=0;

				if (defined($RetFieldsCount) && $RetFieldsCount < 1) {
					if ( $statement =~ /\s*print_input|print_form/ ) {
						printf	STDERR "Error: Statement returned 0 columns for an input statement\nPlease check if ALL form fields are noEntry\n" ;
						printf	LOGFILE "Error: Statement returned 0 columns for an input statement\nPlease check if ALL form fields are noEntry\n" ;
						
						#printf	LOGFILE "Error: Statement returned 0 columns\nPlease check db schema file, primary keys and foreign keys or check if fields are noEntry\n" ;
					} elsif ( $statement =~ /\s*define_/ ) {
						printf	STDERR "Error: Statement returned 0 columns for a define statement\nPlease check if ALL form fields are noEntry\n" ;
						printf	LOGFILE "Error: Statement returned 0 columns for a define statement\nPlease check if ALL form fields are noEntry\n" ;
					}
					#printf	STDERR "Statement: %s\nTemplate %s\nLineNo: %d\nDb schema file: %s\n\n",$statement,basename($TemplateFile),$TmpltLineNum,basename($Dbschema_xml_info) ;
					#printf	LOGFILE "Statement: %s\nTemplate %s\nLineNo: %d\nDb schema file: %s\n\n",$statement,basename($TemplateFile),$TmpltLineNum,basename($Dbschema_xml_info) ;
					undef($RetFieldsCount);
				}
				if ( $statement =~ /printf \$\w+/ ) {
					$OutLineNum += ($statement =~ tr/\n//);
				}
				$lineend =~ s/\/#.*//;
				if ( $lineend =~ /noprint/ ) {
					next READTMPL ;
				}
				if ( $lineend eq "\n" ) {
					$a=1;
				}
					
				$OutLineNum=ffg_print($SRCHANDLE,$lineend,$OutLineNum,$CurrentFctName,"ptrn_line_end",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,0,1);
				undef ($statement) ;
				$StmtComplete=0;
			}
			next READTMPL ;
		} else {	
			$IndentLevel=0;
			if ( $TpltLine !~ /^\s*$/ ) {
			
				$OutLineNum=ffg_print ($SRCHANDLE,$TpltLine,$OutLineNum,$CurrentFctName,"ptrn_line",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			} else {
				$OutLineNum=ffg_print ($SRCHANDLE,$TpltLine,$OutLineNum,$CurrentFctName,"ptrn_blank",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,0,0);
			}
		}
	}
	close ($TEMPLATE);
} # end process_template

sub generate_form {
my ($FormName,$FormTemplateFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName,$TableName,$ArrayElements) = ( @_) ;

%DBSchema=%$DBSchemaPtr;
%PrimaryKeys=%$PrimaryKeysPtr;
%ForeignKeys=%$ForeignKeysPtr;
%ScreenRecord = () ;
$sep_save = $/ ;
$/ = "\n";
$ArrayElements //= 1;

our $Form_Name=$FormName ;
$FormName =~ s/\.fm2|\.per// ;
my $FormFile=sprintf "%s/%s.fm2",$QxPerLocation,$FormName ;
our $FormTitle=$FormName;
#$FormsList[$frm++]=$FormFile;
$FormTableName=$TableName;

if ($FormTemplate !~ /Array/ && $ArrayElements > 1) {
	printf STDERR "please use an Array template to build an array form with %d elements\nDo not use %s\n",$ArrayElements,$FormTemplate;
	exit(1);
}
if ($DEBUGPRINT > 0 && !defined ($InfoDumped) ) {
		dump_form_info ($FormName) ;
		dump_database_info ();
		$InfoDumped=1;
	}
# TablesList is built only from the main file because tables roles do no change
if (!defined ($TablesList)) {
	$TablesList = $$TablesListPtr;
}
our $LabelWidth = 0 ;
our $FieldWidth = 0;
our $LookupCols=0;
if (defined ($DoFormLookup)) {
	$LookupCols=1;
}
($DataPanelWidth,$DataPanelHeight,$FieldsNum,$LabelWidth,$FieldWidth) = bld_form_widgets("",$FormTableName,$ArrayElements,"NoPrint") ;
# check if this file has already been generated, and keep custom lines
#our $RowsNum=$FormHeight-$StdRowStart-2;
our $RowsNum=$DataPanelHeight;
our $ColumnsNum = $FieldsNum;
our $FormWidth=$DataPanelWidth;
our $FormHeight=$DataPanelHeight+$StdRowStart;


open FORMTEMPLATE,$FormTemplateFile or die "Could not open form template file " . $FormTemplateFile ;
if ( $FormTemplateFile =~ /Grid/ ) {
	if ($ArrayElements == 1) {
		if (defined ($DoFormLookup)) {
			$ColumnsNum=3;
		} else {
			$ColumnsNum=2;
		}
		$GridLength=int(100/$ColumnsNum);
	} else {
		#$RowsNum = $ArrayElements + 2 ;
		$GridLength=int(100/$ColumnsNum);
	}
}
#open our $FORMHANDLE,"$SourceOpen" or die "Could not create or append source module" . $ModuleFile ;
open our $FORMHANDLE,">$FormFile" or die "Could not create or append source module" . $FormFile ;

my $TpltLine="" ;
#
# prepare modules and forms list to generate fgltarget file
$frm=0;
#$FormsList[$frm] = $Form ;
#printf "Generating form %s for program %s in %s\n",basename($FormsList[$frm]),$ProgramName,dirname($FormFile);
$frm++;

$n=10 ;
our $OutLineNum=0;
READFTMPL: while ( $TpltLine=<FORMTEMPLATE> ) {
	$TmpltLineNum = $. ;
	undef($MoreToPrint);
	if ( $TpltLine =~ /^\/#/ ) {
		next READFTMPL ;    #ffg comment,not to be printed
	} 
	if ( $TpltLine =~ /^@(\w+)/ ){
		$BlockName=$1;
		next READFTMPL ;    #explicit block name
	}
	
	if ($TpltLine =~ /<(\w+Panel)\s/) {
		$FormPanel=$1;
	}
	# define statement / function call position in line, for future use
	$IndentLevel=0;
	if ( $TpltLine =~ /^(\s+).*/ ) {
		$IndentLevel = ($1 =~ tr/\t//);
		# if a function call follows printed code
	} elsif ( $TpltLine =~ /^(\t*)\<Script:/ ) {
		$IndentLevel = ($& =~ tr/\t//);
	} else {
		$IndentLevel=0;
	}
	# replace all ${xxx} in module by actual $xxx value
	# caution, does not catch ${FormField{${MainForm}}->{ScreenArray} yet!
	while ( $TpltLine =~ /\$\{(.*)\}?/ ) {
		if ( $TpltLine =~ /\$\{(\w+)\}/ ) {
			$FfgVariable=$1;
			if (defined($$FfgVariable)) {
				$TpltLine =~ s/\$\{(\w+)\}/${$FfgVariable}/ ;
				$a=1 ;
			} else {
				if (!defined($CheckVariables) && !defined($${FfgVariable}) ) {
					if (!defined($ForceErrors) ) {
						printf LOGFILE "Error: Perl variable is not defined in form template: \$" . ${FfgVariable} . " in line " . $. ;
						die "exiting";
					} else {
						printf LOGFILE "Error: Perl variable is not defined in form template: \$" . ${FfgVariable} . " in line " . $. . "\n" ;
						next READFTMPL ;
					}
				}
			}
			if (defined($CheckVariables)) {
				if (defined($${FfgVariable}) ) {
					printf LOGFILE "\$%s = %s\n",${FfgVariable},$${FfgVariable};
				} else {
					printf LOGFILE "Error: Perl variable is not defined: \$" . ${FfgVariable} . " in line " . $TmpltLineNum . "\n" ;
				}
				next READFTMPL ;
			}
		} else {
			$a=1;
		}
	} # end while complet ${xxx}

	# Special case for tested perl variables ( $!variable )
	while ( $TpltLine =~ /\$!(\w+)/ ) {
		$PerlVariable=$1;
		if ($${PerlVariable} ne "") {
			$TpltLine =~ s/\$!(\w+)/\$${PerlVariable}/ ;
		} else {
			die "Perl variable is not defined: " . ${PerlVariable} . " in line " . $TmpltLineNum ;
		}
	}

	# Previously look if statement end + more to print
	if ( $TpltLine =~ /\s*:Script>(\S+)/ && $TpltLine !~ /noprint/) {
		$MoreToPrint=1;
	} else {
		$MoreToPrint=0;
	}
	# execute command xxx in pattern file, command line contains <Script: xxxxx >/
	if ( $TpltLine =~ /<Script:\s*(.*)/) {
		undef($statement) ;
		$StmtComplete=0;
		my $linestart=$` ;
		$statement=sprintf "%s",$1 ;
		if ( $linestart =~ /^\s+$/ ) {
			$linestart = "" ;
		}
		
		
		# take eventual other stuff to print after the statement, no other statement allowed on the right
		#if ( $statement =~ />\// ) {
			#$statement = $`;
		#}
		chomp($statement) ;
		# print part of line on the left of the command, if any
		if ( length($linestart) > 1 ) {
			printf $FORMHANDLE "%s",$linestart ;
			if ( $DEBUGPRINT > 2 ) { printf LOGFILE "%s",$linestart ; }
		}

		if ( $TpltLine =~ /<Script:(.*):Script>/ ) {
			$StmtComplete=1;  
			$statement = $1;
			$lineend=$';
		} else {
			# statement finishes with >/, if multi-line statement then
			# read the next line until finding a >/
			#while ($TpltLine !~ /\s*:Script>/ && ($TpltLine=<FORMTEMPLATE>) ) {
			while ($TpltLine !~ /:Script>/ && ($TpltLine=<FORMTEMPLATE>) ) {
				$TpltLine =~ s/^[\t\s]*//g;
				$StmtStart=$statement;
				$statement=sprintf "%s\n%s",$StmtStart,$TpltLine ;
			}
			$lineend=$'; 
			$statement =~ s/\s*:Script>/;/ ;
		}
		if ( $StmtComplete == 1 ) {
			if (defined($CheckVariables) && $statement =~ /\$\w+\s+=/ ) {
				my $evalStatus=eval ($statement);
				next READFTMPL ;
			}
			$statement =~ s/\sprint\s/ printf \$SRCHANDLE  /g;
#############################################################################################################
# this is where the statement is executed
			my $evalStatus=eval ($statement);
#############################################################################################################
			if ( !defined($evalStatus) ) {
				printf STDERR "%s:L %d, Perl command has wrong syntax:%s \n",$FormTemplateFile,$TmpltLineNum,$statement ;
			}
			if ( $statement =~ /printf \$\w+/ ) {
				$OutLineNum += ($statement =~ tr/\n//);
			}
			$lineend =~ s/\/#.*//;
			if ( $lineend =~ /noprint/ ) {
				next READFTMPL ;
			}
			if ( $lineend eq "\n" ) {
				$a=1;
			}
				
			#if ( $lineend !~ /noprint/ &&  $lineend !~ /^$/ ) { # 8/7
			#if ( $lineend !~ /noprint/ ) { # 8/7
			printf $FORMHANDLE "%s",$lineend;
			undef ($statement) ;
			$StmtComplete=0;
		}
		next READFTMPL ;
	} elsif ( $TpltLine =~ /<RepeatBlock:(\w+)/ ) {
			my $NbRepeatBlock=$$1;
			my $iter=1;
			
			#$TpltLine=<FORMTEMPLATE>;
			# First read block, then repeat it
			my $Block="";
			while (($TpltLine=<FORMTEMPLATE>) && $TpltLine !~ /:RepeatBlock>/ ) {
				while ( $TpltLine =~ /\$\{(\w+)\}/ ) {
					$PerlVariable=$1;
					if ($${PerlVariable} ne "") {
						$TpltLine =~ s/\$\{(\w+)\}/$${PerlVariable}/ ;
					} else {
						die "Perl variable is not defined: " . ${PerlVariable} . " in line " . $TmpltLineNum ;
					}
				}			
 				$Block=sprintf "%s%s",$Block,$TpltLine;
			}
			while ( $iter <= $NbRepeatBlock) {
	
				printf $FORMHANDLE "%s",$Block;
				$iter++;
			}
			
		} else {	
		#$IndentLevel=0;
		printf $FORMHANDLE "%s",$TpltLine;
	}
}
$/ = $sep_save ;
close ($FORMHANDLE);
close (FORMTEMPLATE);
} # end generate_form

#** \method set_application_messages Sets application messages in different languages
#** Check $FFGETCDIR/ffg_lang.<language code>
sub set_application_messages {
my $LANG=$_[0];
my $LangFile = sprintf "%s/ffg_lang_variables.%s",$FFGETCDIR,$LANG ;
&set_parameters($LangFile) ;
} # end set_application_messages

########################################################################################
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
} # end  set_parameters_for {

#sub set_project_parameters {
# read global parameters
# precedence is QX_WORKSPACE/etc , if not $FFGETCDIR
#  my ($Project,$Param) = (@_) ;	
#	my $ParamsFile = sprintf "%s/%s/etc\/project_parameters.ffg",$QxWorkSpace,$Project;
#	if ( -e $ParamsFile ) {
#		my $FfgParamsFile=$ParamsFile;
#		&set_parameters($FfgParamsFile,$Param) ;
#	}
#} # end  set_global_parameters {

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
} # end  set_parameters

########################################################################################
sub list_form_fields {
	my ($MODULE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$InPrefix,$Tabul,$WriteMode,$isRecord,$WidgetType,$ReturnFieldKeys) = (@_ ) ;
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	my $FieldsCount=0;
	my $TableExpression = "";
	my $TheTable = "";
	if ( $Table =~ /^$/ ) {
		$Table=".*";
	}
	if ( $Table =~ /ParentFormonly/i ) { # Special trick to get parent table + formonly
		$TableExpression=$ParentTable . "\|formonly" ;
		$TheTable=$ParentTable;
	} elsif ( $Table =~ /GrandChildFormonly/i ) { # Special trick to get GrandChild table + formonly
		$TableExpression=$GrandChildTable . "\|formonly" ;
		$TheTable=$GrandChildTable;
	} elsif ( $Table =~ /ChildFormonly/i ) { # Special trick to get Child table + formonly
		$TableExpression=$ChildTable . "\|formonly" ;
		$TheTable=$ChildTable;
	} else {
		$TableExpression=$Table ;
		$TheTable=$Table;
	}
	if ( $Section =~ /^$/ ) {
		$Section=".*" ;
	}
	if ( $Role =~ /^$/) {
		$Role=".*" ;
	}
	if ( $NoEntry =~ /^$/ || $NoEntry =~ /all/ ) {
		$NoEntry='true|false' ;
	}
	if ( $ColType =~ /^$/ || $ColType eq ".*" ) {
		$ColType="all" ;
	}
	if ( $WriteMode =~ / ^$/ ) {
		$WriteMode="skipline" ;
	}
	if ( $isRecord =~ /^$/ ) {
		$isRecord="record" ;
	}

	if ( $WidgetType =~ /^$/ ) {
		$WidgetType=".*";
		$Box=".*";
		$boxFill=".*";
	} elsif ( $WidgetType =~ /(\w+)Box/ ) {
		$Box=$&;
		if ($WidgetType =~ /BeforeField|AtStart/i) {
			$boxFill=$&;
		} else {
			$boxFill=".*";
		}
	} 
	$ReturnFieldKeys //= 0 ;
	$tabnum=0;
	my @FormFieldsList = () ;

	if ( $WriteMode =~ /skip/ ) {
		$ColSep="\n";
	} else {
		$ColSep="";
	}
	if ( $isRecord =~ /isRecord/ ) {
		$Prefix = $Prefix . '.' ;
	}
	# first count fields to be printed ( no need to sort )
	LCOUNTFIELDS: foreach my $key ( keys %{ $FormField->{$Form} } ) {
		if ( $key !~ /\w+:\w+:\w+/) {
			next LCOUNTFIELDS;
		}
		if (defined($FormField->{$Form}->{$key}->{'Visible'}) && $FormField->{$Form}->{$key}->{'Visible'} eq 'false' ) {
			next LCOUNTFIELDS ;
		}
		
		if ( $FormField->{$Form}->{$key}->{'Table'} =~ /\b${Table}\b/ || $FormField->{$Form}->{$key}->{'Table'} =~ /${TableExpression}/ ) {
			$a=1;
		} else {
			next LCOUNTFIELDS ;
		}
		
		if ( defined($FormField->{$Form}->{$key}->{'Role'}) && $FormField->{$Form}->{$key}->{'Role'} !~ /$Role/ ) {
			next LCOUNTFIELDS ;
		}
		
		if ( defined($FormField->{$Form}->{$key}->{'Section'}) && $FormField->{$Form}->{$key}->{'Section'} !~ /$Section/ ) {
			next LCOUNTFIELDS ;
		}
		
		if ( $ColType =~ /pkey/  && !defined($FormField->{$Form}->{$key}->{'IsPK'}) ) {
			next LCOUNTFIELDS;
		} 
		
		if ($ColType =~ /attr/ && defined($FormField->{$Form}->{$key}->{'IsPK'})) {
			next LCOUNTFIELDS;
		} 
		
		if ( $ColType =~ /fkey/ && !defined($FormField->{$Form}->{$key}->{'IsFK'}) ) {
			next LCOUNTFIELDS;
		}		
		
		if ( $FormField->{$Form}->{$key}->{'Noentry'} =~ /$NoEntry/ ) {
			if ($FormField->{$Form}->{$key}->{Table} =~ /\b${TheTable}\b/ ) {
				$a=1;
			} elsif ( $FormField->{$Form}->{$key}->{Table} eq "formonly" && !defined($FormField->{$Form}->{$key}->{lookupTable})) {
				$a=1;
			} else {
				next LCOUNTFIELDS ;	
			}
		} else {
			if ($FormField->{$Form}->{$key}->{Table} =~ /\b${TheTable}\b/ ) {
				next LCOUNTFIELDS ;	
			} elsif ( $FormField->{$Form}->{$key}->{Table} eq "formonly" && !defined($FormField->{$Form}->{$key}->{lookupTable})) {
				$a=1;
			} else {
				next LCOUNTFIELDS ;	
			}
			
		}		
		if (defined($FormField->{$Form}->{$key}->{'ScreenRecord'})) {
				#do not take fields in array screen records
				# next LCOUNTFIELDS ; no no, take them, we use same function for form and arrays, discriminating with $Section
		}

		if (defined($FormField->{$Form}->{$key}->{WidgetType}) ) {
			if ($FormField->{$Form}->{$key}->{WidgetType} !~ /$Box/ ) { 
				next LCOUNTFIELDS ;	
			}
			if (defined ($FormField->{$Form}->{$key}->{boxFill}) && $FormField->{$Form}->{$key}->{boxFill} !~ /$boxFill/ ) { 
				next LCOUNTFIELDS ;	
			}
		} 

		# Get actual names of field and table ( not the function parameter values)
		my $ThisField=$FormField->{$Form}->{$key}->{'Column'};
		my $ThisTable=$FormField->{$Form}->{$key}->{'Table'};
		$FieldsCount++;
	}

	$fflx=0;
	LREADFIELDS: foreach my $key (sort { $FormField->{$Form}->{$a}->{'Order'} cmp $FormField->{$Form}->{$b}->{'Order'} }keys %{ $FormField->{$Form} } ) {
		if ( $key !~ /\w+:\w+:\w+/) {
			next LREADFIELDS;
		}
		if (defined($FormField->{$Form}->{$key}->{'Visible'}) && $FormField->{$Form}->{$key}->{'Visible'} eq 'false' ) {
			next LREADFIELDS ;
		}

		if ( defined($FormField->{$Form}->{$key}->{'Section'}) && $FormField->{$Form}->{$key}->{'Section'} ne $Section ) {
			next LREADFIELDS ;
		}
		
		if ( $FormField->{$Form}->{$key}->{'Table'} eq ${TheTable} || $FormField->{$Form}->{$key}->{'Table'} =~ /${TableExpression}/ ) {
			$a=1;
		} else {
			next LREADFIELDS ;
		}
		
		if ( defined($FormField->{$Form}->{$key}->{'Role'}) && $FormField->{$Form}->{$key}->{'Role'} !~ /$Role/ ) {
			next LREADFIELDS ;
		}
		

		if ( $ColType =~ /pkey/  && !defined($FormField->{$Form}->{$key}->{'IsPK'}) ) {
			next LREADFIELDS;
		} 
		
		if ($ColType =~ /attr/ && defined($FormField->{$Form}->{$key}->{'IsPK'})) {
			next LREADFIELDS;
		} 
		
		if ( $ColType =~ /fkey/ && !defined($FormField->{$Form}->{$key}->{'IsFK'}) ) {
			next LREADFIELDS;
		}		

		if ( $FormField->{$Form}->{$key}->{'Noentry'} =~ /$NoEntry/ ) {
			#if ($FormField->{$Form}->{$key}->{Table} eq $TheTable ) {
			if ($FormField->{$Form}->{$key}->{Table} =~ /\b${TheTable}\b/ ) {
				$a=1;
			} elsif ( $FormField->{$Form}->{$key}->{Table} eq "formonly" && !defined($FormField->{$Form}->{$key}->{lookupTable})) {
				$a=1;
			} else {
				next LREADFIELDS ;	
			}
		} else {
			if ($FormField->{$Form}->{$key}->{Table} =~ /\b${TheTable}\b/ ) {
				next LREADFIELDS ;	
			} elsif ( $FormField->{$Form}->{$key}->{Table} eq "formonly" && !defined($FormField->{$Form}->{$key}->{lookupTable})) {
				$a=1;
			} else {
				next LREADFIELDS ;	
			}
			
		}
		
		if ($FormField->{$Form}->{$key}->{WidgetType} !~ /$Box/ ) { 
			next LREADFIELDS ;	
		} else {
			if ($FormField->{$Form}->{$key}->{boxFill} !~ /$boxFill/ ) { 
				next LREADFIELDS ;	
			}
		}

		if (defined($FormField->{$Form}->{$key}->{'ScreenRecord'})) {
				#do not take fields in array screen records
				# next LREADFIELDS ; no no, take them, we use same function for form and arrays, discriminating with $Section
		}

		my $ThisField=$FormField->{$Form}->{$key}->{'Column'};
		my $ThisTable=$FormField->{$Form}->{$key}->{'Table'};
		
		# listkey mode: we keep just the key for further use
		if ( $WriteMode =~ /listkey/) {
			$FormFieldsList[$fflx] = $key;
			$fflx++;
			next LREADFIELDS;
		}
		if ($InPrefix !~ /^$/ ) {
			if ( $InPrefix eq "TblName") {
				$Prefix=$table . "." ;
			} else {
				$Prefix=$InPrefix . "." ;
			}
		} else {
			undef($Prefix);
		}

		if (defined($Prefix) && length($Prefix) > 0 ) {
			if ($tabnum++ > 0 ) {
				$FldName=sprintf "%s%s%s",$Tabul,$Prefix,$ThisField ;
			} else {
				$FldName=sprintf "%s%s",$Prefix,$ThisField ;
			}
		} else {
			if ($tabnum++ > 0 ) {
				$FldName=sprintf "%s%s",$Tabul,$ThisField;
			} else {
				$FldName=sprintf "%s",$ThisField;
			}
		}
		if ( $tabnum < $FieldsCount ) {
			$FldName=sprintf "%s,%s",$FldName,$ColSep ;
		} else {
			$FldName=sprintf "%s%s",$FldName,$ColSep ;
		}
		if ($ReturnFieldKeys == 1 ) {
			$FormFieldsList[$fflx] = $key ;
		} else {
			$FormFieldsList[$fflx] = $FldName ;
		}
		$fflx++;
	}
	$idx++;

	return @FormFieldsList ;
	
} # end  list_form_fields 

sub list_form_tables {
	my ($Form,$Table,$Section) = (@_ ) ;
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	my $TablesCount=0;
	my $TableExpression = "";
	my $TheTable = "";

	if ( $Table =~ /^$/ ) {
		$Table=".*";
	}
	if ($Section =~ /^$/) {
		$Section = ".*" ;
	}
	if ( $Role =~ /^$/) {
		$Role = ".*" ;
	}
	$tabnum=0;
	my @FormTablesList = () ;

	# first count tables to be printed ( no need to sort )
	LCOUNTTABLES: foreach my $key ( keys %{ $FormField->{$Form} } ) {
		if ( $key !~ /\w+:\w+:\w+/) {
			next LCOUNTTABLES;
		}
		
		if ( $FormField->{$Form}->{$key}->{'Table'} !~ /${Table}/ ) {
			next LCOUNTTABLES ;
		}
		
		if ( defined($FormField->{$Form}->{$key}->{'Role'}) && $FormField->{$Form}->{$key}->{'Role'} !~ /$Role/ ) {
			next LCOUNTTABLES ;
		}
		
		if ( defined($FormField->{$Form}->{$key}->{'Section'}) && $FormField->{$Form}->{$key}->{'Section'} !~ /$Section/ ) {
			next LCOUNTTABLES ;
		}
		
		# Get actual names of field and table ( not the function parameter values)
		my $ThisField=$FormField->{$Form}->{$key}->{'Column'};
		my $ThisTable=$FormField->{$Form}->{$key}->{'Table'};
		$TablesCount++;
	}

	$fflx=0;
	LREADTABLES: foreach my $key (sort { $FormField->{$Form}->{$a}->{'Order'} cmp $FormField->{$Form}->{$b}->{'Order'} }keys %{ $FormField->{$Form} } ) {
		if ( $key !~ /\w+:\w+:\w+/) {
			next LREADTABLES;
		}

		if ( defined($FormField->{$Form}->{$key}->{'Section'}) && $FormField->{$Form}->{$key}->{'Section'} !~ $Section ) {
			next LREADTABLES ;
		}
		
		if ( $FormField->{$Form}->{$key}->{'Table'}  !~ /${Table}/ ) {
			next LREADTABLES ;
		}
		
		if ( defined($FormField->{$Form}->{$key}->{'Role'}) && $FormField->{$Form}->{$key}->{'Role'} !~ /$Role/ ) {
			next LREADTABLES ;
		}
		
		$FormTablesList[$fflx]=$FormField->{$Form}->{$key}->{'Table'};
		$fflx++;
	}
	my @UniqueTablesList=unique(\@FormTablesList);
	return @UniqueTablesList ;
	
} # end  list_form_tables

########################################################################################
sub set_fields_active {
	my    ($MODULE,$Form,$Table,$Section,$Role,$ColType,$Active) = (@_ ) ;
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	my $FieldsCount=0;
	my $NoEntry = ".*";
	my $InPrefix="";
	# set the list of fields to be printed
	my @ThisFormFields=list_form_fields ($SRCHANDLE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$InPrefix,"","listkey") ;
	my $FieldsCount=$#ThisFormFields+1;
	
	# Check who has called this function ( determines position to print)
	my ($package, $filename, $line, $CallingSub, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);
	my $afx=0;
	my $field_num=0;
	my $key="";
	my $field="";
	my $table="";
	my $container="";
	
	
	while (defined($ThisFormFields[$field_num])) {
		if ( $ThisFormFields[$field_num] =~ /(\w+):(\w+):(\w+)/ ) {
			$key=$&;
			$field = $1;
			$table=$2;
			$container=$3;
		}

		if ( $DEBUGPRINT > 2) { 
			printf LOGFILE "set_fields_active:%s table %s"	 ,$field,$table ;
		}
		my $Prefix='';
		$afx++;

		if ( $DBSchema{$table}{$field}->{'IsPK'} eq true ) {
			if ( $DBSchema{$table}{$field}->{datatype} =~ /SERIAL/i) {
				next ;
			}
		}
		if ( $DBSchema{$table}{$field}->{'IsFK'} eq true) {
			if ( $DBSchema{$table}{$field}->{datatype} =~ /SERIAL/i) {
				next ;
			}
		}

		my $Line = sprintf "CALL DIALOG.SetFieldActive('%s',%s)",$field,$Active;
		$OutLineNum = ffg_print ($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_fields_active",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
		
		# reset IndentLevel to saved value
		if ($tabnum == 1 && $CallingSub =~ /generate_module|eval/) {
			$IndentLevel=$SavedIndentLevel;
		} 
		$idx++;
		$field_num++;
	}
} # end  set_fields_active {

sub print_form_fields {
	my    ($MODULE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$InPrefix,$Tabul,$WriteMode,$isRecord,$ResetAFF) = (@_ ) ;
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	my $FieldsCount=0;
	if ( $NoEntry =~ /^$/ ) {
			$NoEntry="true|false" ;
	}
	if ( $WriteMode =~ /^$/ ) {
		$WriteMode="skipline" ;
	}
	if ( $isRecord =~ /^$/ ) {
		$isRecord //= "record" ;
	}

	if ( $Section =~ /^$/ ) {
		$Section=".*" ;
	}

	if ( $ColType eq ".*") { 
		$ColType="all";
	}
	$tabnum=0;
	if ( $ColType eq ".*") { 
		$ColType="all";
	}
	my $ColSep = "";
	if ( $WriteMode =~ /quoteskip/ ) {
		$ColSep="\",\n";
	} elsif ( $WriteMode =~ /skip/ ) {
		$ColSep="\n";
	} elsif ( $WriteMode =~ /flat/ ) {
		$ColSep="";
	}
	@AfterField = {} ;
	if ($ResetAFF =~ /reset/ ) {
#		%InputEventFields = () ;
	}
	# set the list of fields to be printed
	if ( $Section eq "parent") {
		@ThisFormFields=list_form_fields ($SRCHANDLE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$InPrefix,"","listkey") ;
	} elsif ( $Section eq "child") {
		@ThisFormFields=list_scrrec_fields ($Form,$ChildScreenRecord,$Table,$ColType,$NoEntry,"","","","") ;
	} elsif ( $Section eq "grandchild") {
		@ThisFormFields=list_scrrec_fields ($Form,$GrandChildScreenRecord,$Table,$ColType,$NoEntry,"","","","") ;
	}

#	my @ThisFormFields=list_form_fields ($SRCHANDLE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$InPrefix,"","listkey") ;
	my $FieldsCount=$#ThisFormFields+1;
	$tabnum=0;
	$printedFields=0;
	# Check who has called this function ( determines position to print)
	my ($package, $filename, $line, $CallingSub, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);
	my $afx=0;
	my $field_num=0;
	my $key="";
	my $field="";
	my $table="";
	my $container="";
	
	
	while (defined($ThisFormFields[$field_num])) {
		if ( $ThisFormFields[$field_num] =~ /(\w+):(\w+):(\w+)/ ) {
			$key=$&;
			$field = $1;
			$table=$2;
			$container=$3;
		}

		if ( $DEBUGPRINT > 2) { 
			printf LOGFILE "print_form_field:%s table %s"	 ,$field,$table ;
		}
		my $Prefix='';
		$afx++;
		if ( $table =~ /formonly/i && $InPrefix =~ /(.*)TblName/ ) {    # i.e we list columns for a query
			# Cast a NULL on the ColDefinition
			my $ColDef=$FormField->{$Form}->{$ThisFormFields[$field_num]}->{ColDef};
			if ( $ColDef =~ /(.*)\(/i) {
				$field = "NULL::" . $1;
			} else {
				$field = "NULL::" . $ColDef ;
			}
			
		}
		if (defined($InPrefix) && length($InPrefix) > 0 && $field !~ /NULL::/ ) {
			if ( $InPrefix =~ /(.*)TblName/ ) {
				$Prefix=$1 . $FormField->{$Form}->{$key}->{'Table'} . "." ;
			} elsif ( $InPrefix =~ /(.*)\.=TblName/ ) {
				$Prefix = $FormField->{$Form}->{$key}->{'Table'} . "." ;
			} elsif ( $InPrefix =~ /=screenrecord/ ) {
				$Prefix = $FormField->{$Form}->{$key}->{'ScreenRecord'} . "[" . $ScrLineVar . "]" . "." ;
			} else {
				$Prefix = $InPrefix . "." ;
			}
			if ($FormField->{$Form}->{$key}->{'Table'} !~ /formonly/i) {
				$FldName=sprintf "%s%s",$Prefix,$field ;
			} else {
				#$FldName=sprintf "ascii(34)ascii(34)";
				$FldName=sprintf "%s%s",$Prefix,$field ;
				#$FldName="\\\"\\\"";
			}
		} else {
			$FldName=sprintf "%s",$field;
		}



		if ( $DBSchema{$table}{$field}->{'IsPK'} eq true ) {
			if ( $DBSchema{$table}{$field}->{datatype} =~ /SERIAL/i) {
				next ;
			}
		}
		if ( $DBSchema{$table}{$field}->{'IsFK'} eq true) {
			if ( $DBSchema{$table}{$field}->{datatype} =~ /SERIAL/i) {
				next ;
			}
		}
		my $AfterFieldSize=$#AfterField;			
		#=================================================
		$tabnum++;
		$printedFields++;
		#if ($tabnum == 1 ) {
		if ($tabnum == 1 && $CallingSub =~ /generate_module|eval/) {
			$SavedIndentLevel=$IndentLevel ;
			$IndentLevel=0 ;
		}
		
		if ( $tabnum < $FieldsCount ) {
			$FldName=sprintf "%s,%s",$FldName,$ColSep ;
			if ( $WriteMode =~ /quoteskip/ ) {
				$FldName = "\"" . $FldName ;
			}
			$FldName =~s/,+/,/g;
			$OutLineNum = ffg_print ($SRCHANDLE,$FldName,$OutLineNum,$CurrentFctName,"print_form_fields",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
		} else {
			$FldName=sprintf "%s%s",$FldName,$ColSep ;
			if ( $WriteMode =~ /quoteskip/ ) {
				$FldName = "\"" . $FldName ;
			}
			$OutLineNum = ffg_print ($SRCHANDLE,$FldName,$OutLineNum,$CurrentFctName,"print_form_fields",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0) ;
			#my ($package, $filename, $line, $CallingSub, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);
			if ( $CallingSub =~ /generate_module|eval/ ) {
				$OutLineNum = ffg_print ($SRCHANDLE,"\n",$OutLineNum,$CurrentFctName,"print_form_fields",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0) ;
			} else {
				$OutLineNum = ffg_print ($SRCHANDLE,"\n",$OutLineNum,$CurrentFctName,"print_form_fields",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
			}
		}
		# reset IndentLevel to saved value
		if ($tabnum == 1 && $CallingSub =~ /generate_module|eval/) {
			$IndentLevel=$SavedIndentLevel;
		} 
		$idx++;
		$field_num++;
	}

	if ( $FieldsCount != $printedFields) {
		printf LOGFILE "ERROR: print_form_fields counts %d fields and prints %d\n", $FieldsCount,$printedFields;
	}
 
} # end  print_form_fields 




# takes list on the screen record for input array, display array etc
sub print_scrrec_fields {
	my ($MODULE,$Form,$ScrRec,$Table,$ColType,$NoEntry,$InPrefix,$Tabul,$WriteMode,$isRecord) = (@_ ) ;
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	my $FieldsCount=0;
	$Table //= ".*" ;
	$Noentry //= 'false' ;
	$WriteMode //= "skipline" ;
	$isRecord //= "record" ;
	$Section //= ".*" ;
	$tabnum=0;
	if ( $ColType eq ".*") { 
		$ColType="all";
	}
	if ( $WriteMode =~ /quoteskip/ ) {
		$ColSep="\",\n";
	} elsif ( $WriteMode =~ /skip/ ) {
		$ColSep="\n";
	} elsif ( $WriteMode =~ /flat/ ) {
		$ColSep="";
	}
	if ( $isRecord =~ /record/ ) {
		if ( $Prefix !~ /^$/ ) {
			$Prefix = $Prefix . '.' ;
		}
	}
	# first count fields to be printed ( no need to sort )
	my $tt=0;
	SCOUNTFIELDS: while (defined($ScreenRecord{$Form}->{$ScrRec}->{FieldList}[$tt])) {
		my $fieldname=$ScreenRecord{$Form}->{$ScrRec}->{'FieldList'}[$tt];
		my $tabname=$ScreenRecord{$Form}->{$ScrRec}->{'TableList'}[$tt];
		my $container=$ScreenRecord{$Form}->{$ScrRec}->{'CntrnList'}[$tt];
		my $key=sprintf "%s:%s:%s",$fieldname,$tabname,$container;
		if (  $FormField->{$Form}->{$key}->{'Table'} =~ /^$Table$/ 
		&& $FormField->{$Form}->{$key}->{'Visible'} ne 'false' ) {
			if ( $FormField->{$Form}->{$key}->{'Noentry'} !~ /$NoEntry/ ) {
				$tt++;
				next SCOUNTFIELDS ;
			}
			$field=$FormField->{$Form}->{$key}->{'Column'};      # rajout 05/07
			if (defined($Prefix) && length($Prefix) > 0 ) {
				if ( $DBSchema{$Table}{$field}->{'IsPK'} eq true && $ColType !~ /pkey|all/ ) {
					$tt++;
					next SCOUNTFIELDS;
				}
				$FieldsCount++;
			} else {
				$FieldsCount++;
			}
		}
		$tt++;
	}

	$tabnum=0;
	my $tt=0;
	SREADFIELDS: while (defined($ScreenRecord{$Form}->{$ScrRec}->{FieldList}[$tt])) {
		my $fieldname=$ScreenRecord{$Form}->{$ScrRec}->{'FieldList'}[$tt];
		my $tabname=$ScreenRecord{$Form}->{$ScrRec}->{'TableList'}[$tt];
		my $container=$ScreenRecord{$Form}->{$ScrRec}->{'CntrnList'}[$tt];
		my $key=sprintf "%s:%s:%s",$fieldname,$tabname,$container;
		
		if (  $FormField->{$Form}->{$key}->{'Table'} =~ /^$Table$/ 
		&& $FormField->{$Form}->{$key}->{'Visible'} ne 'false' ) {
			if ( $FormField->{$Form}->{$key}->{'Noentry'} !~ /$NoEntry/ ) {
				$tt++;
				next SREADFIELDS ;
			}
			$field=$FormField->{$Form}->{$key}->{'Column'};
			if (defined($InPrefix) && length($InPrefix) > 0 ) {
				if ( $DBSchema{$Table}{$field}->{'IsPK'} eq true && $ColType !~ /pkey|all/ ) {
					$tt++;
					next SREADFIELDS ;
				}
				if ($InPrefix eq "TblName") {
						$Prefix=sprintf "%s.",$tabname;
				} else {
					$Prefix=$InPrefix . "." ;
				}
				$FldName=sprintf "%s%s",$Prefix,$field ;
			} else {
				$FldName=sprintf "%s",$field;
			}
			$tabnum++;
			if ($tabnum == 1 ) {
				$SavedIndentLevel=$IndentLevel ;
				$IndentLevel=0 ;
			}
			if ( $tabnum < $FieldsCount ) {
				$FldName=sprintf "%s,%s",$FldName,$ColSep ;
				if ( $WriteMode =~ /quoteskip/ ) {
					$FldName = "\"" . $FldName ;
				}
				if ( $WriteMode =~ /flat/ ) {
					$OutLineNum = ffg_print ($SRCHANDLE,$FldName,$OutLineNum,$CurrentFctName,"print_scrrec_field",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0) ;
				} else {
					$OutLineNum = ffg_print ($SRCHANDLE,$FldName,$OutLineNum,$CurrentFctName,"print_scrrec_field",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
				}
			} else {
				$FldName=sprintf "%s%s",$FldName,$ColSep ;
				if ( $WriteMode =~ /quoteskip/ ) {
					$FldName = "\"" . $FldName ;
				}
				$OutLineNum = ffg_print ($SRCHANDLE,$FldName,$OutLineNum,$CurrentFctName,"print_scrrec_field",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0) ;
				my ($package, $filename, $line, $CallingSub, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);
				if ( $CallingSub =~ /generate_module|eval/ && $lineend !~ /^$/ ) {
					$OutLineNum = ffg_print ($SRCHANDLE,"\n",$OutLineNum,$CurrentFctName,"print_scrrec_field",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0) ;
				} else {
					$OutLineNum = ffg_print ($SRCHANDLE,"\n",$OutLineNum,$CurrentFctName,"print_scrrec_field",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
				}
			}
			# reset IndentLevel to saved value
			if ($tabnum == 1 ) {
				$IndentLevel=$SavedIndentLevel;
			} 
		} 
		$idx++;
		$tt++;
	}	
	our $RetFieldsCount=$tabnum;
} # end  print_scrrec_fields

########################################################################################
sub define_scrrec_fields {
	my ($MODULE,$Form,$ScrRec,$Table,$ColType,$NoEntry,$Prefix,$Tabul,$WriteMode,$isRecord) = (@_ ) ;
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	my $FieldsCount=0;
	$Noentry //= 'false' ;
	$WriteMode //= "skipline" ;
	$isRecord //= "record" ; 
	$tabnum=0;

	if ( $ColType eq ".*") { 
		$ColType="all";
	}
	
	if ( $WriteMode =~ /skip/ ) {
		$ColSep="\n";
	} else {
		$ColSep="";
	}
	if ( $isRecord =~ /record/ ) {
		if ( $Prefix !~ /^$/ ) {
			$Prefix = $Prefix . '.' ;
		}
	}
	# first count fields to be printed ( no need to sort )
	my $tt=0;
	my $key="";
	
	UCOUNTFIELDS: while (defined($ScreenRecord{$Form}->{$ScrRec}->{FieldList}[$tt])) {
		my $fldname="";
		my $tabname="";
		my $container="";
		my $key=sprintf "%s:%s:%s",$ScreenRecord{$Form}->{$ScrRec}->{'FieldList'}[$tt],$ScreenRecord{$Form}->{$ScrRec}->{'TableList'}[$tt],$container=$ScreenRecord{$Form}->{$ScrRec}->{'CntrnList'}[$tt];

 		if (  $FormField->{$Form}->{$key}->{'Table'} =~ /^$Table$/ 
		&&  $FormField->{$Form}->{$key}->{'Visible'} ne 'false' ) {
				if ( defined($FormField->{$Form}->{$key}->{'Noentry'}) && $FormField->{$Form}->{$key}->{'Noentry'} !~ /$NoEntry/ ) {
					$tt++;
					next UCOUNTFIELDS ;
				}
				if ( $key =~ /(\w+):(\w+):(\w+)/ ) {
					$fldname=$1;
					$tabname=$2;
					$container=$3;
				}
				if (defined($Prefix) && length($Prefix) > 0 ) {
					if ( $DBSchema{$tabname}{$fldname}->{'IsPK'} eq true && $ColType !~ /pkey|all/ ) {
						$tt++;
						next UCOUNTFIELDS;
					}
					if ( !defined($DBSchema{$tabname}{$fldname}->{'IsFK'}) && $ColType !~ /fkey|all/ ) {
						$tt++;
						next UCOUNTFIELDS;
					}
					if ( $ColType =~ /lookup/ && $TablesList{$tabname}->{'Role'} ne "lookup" ) {
						$tt++;
						next UCOUNTFIELDS;
					}
					$FieldsCount++;
				} else {
					$FieldsCount++;
				}
		}
		$tt++;
	}
	$tt=0;
	my $key="";
	my $VarDef="";
	
	UREADFIELDS: while (defined($ScreenRecord{$Form}->{$ScrRec}->{FieldList}[$tt])) {
		my $fldname="";
		my $tabname="";
		my $container="";
		my $key=sprintf "%s:%s:%s",$ScreenRecord{$Form}->{$ScrRec}->{'FieldList'}[$tt],$ScreenRecord{$Form}->{$ScrRec}->{'TableList'}[$tt],
		$container=$ScreenRecord{$Form}->{$ScrRec}->{'CntrnList'}[$tt];
		
		if (  $FormField->{$Form}->{$key}->{'Table'} =~ /^$Table$/ 
		&&  $FormField->{$Form}->{$key}->{'Visible'} ne 'false' ) {
			if ( defined($FormField->{$Form}->{$key}->{'Noentry'}) && $FormField->{$Form}->{$key}->{'Noentry'} !~ /$NoEntry/ ) {
				$tt++;
				next UREADFIELDS ;
			}
			# $field=$FormField->{$Form}->{$key}->{'Column'};
			#$field=$key;
			#$field =~ s/:\w+// ;

			my $key=sprintf "%s:%s:%s",$ScreenRecord{$Form}->{$ScrRec}->{'FieldList'}[$tt],$ScreenRecord{$Form}->{$ScrRec}->{'TableList'}[$tt],$ScreenRecord{$Form}->{$ScrRec}->{'CntrnList'}[$tt];
			$colname=$FormField->{$Form}->{$key}->{'Column'};
			$tabname=$FormField->{$Form}->{$key}->{'Table'};
			if (defined($Prefix) && length($Prefix) > 0 ) {
				if ( $DBSchema{$tabname}{$colname}->{'IsPK'} eq true && $ColType !~ /pkey|all/ ) {
					$tt++;
					next UREADFIELDS ;
				}
				if ( !defined($DBSchema{$tabname}{$colname}->{'IsFK'}) && $ColType !~ /fkey|all/ ) {
					$tt++;
					next UREADFIELDS;
				}
				if ($DefineStyle =~ /like/i) {
					#$DefLike=sprintf " LIKE %s.%s,   # ",$TableName,$colname;
					$DefLike=sprintf " LIKE %s.%s,   # ",$tabname,$colname;
				} else {
					$DefLike=" ";
				}
				if ($tabnum++ > 0 ) {
					$VarDef=sprintf "%s%s %s %s",$Prefix,$colname,$DefLike,$FormField->{$Form}->{$key}->{'ColDef'} ;
				} else {
					$VarDef=sprintf "%s%s %s %s",$Prefix,$colname,$DefLike,$FormField->{$Form}->{$key}->{'ColDef'} ;
				}
			} else {
				if ($DefineStyle =~ /like/i) {
					#$DefLike=sprintf " LIKE %s.%s,   # ",$TableName,$colname;
					$DefLike=sprintf " LIKE %s.%s,   # ",$tabname,$colname;
				} else {
					$DefLike=" ";
				}
				if ($tabnum++ > 0 ) {
					$VarDef=sprintf "%s %s %s",$colname,$DefLike,$FormField->{$Form}->{$key}->{'ColDef'};
				} else {
					$VarDef=sprintf "%s %s %s",$colname,$DefLike,$FormField->{$Form}->{$key}->{'ColDef'};
				}
			}
			if ( $tabnum < $FieldsCount ) {
				if ( $VarDef !~ /\sLIKE\s/) {
						$VarDef = sprintf "%s,\n",$VarDef;
				}
				#$VarDef=sprintf "%s,%s",$VarDef,$ColSep ;
				$OutLineNum = ffg_print ($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"print_scrrec_field",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
			} else {
				#$VarDef=sprintf "%s%s",$VarDef,$ColSep ;
				if ( $VarDef =~ /\sLIKE\s/) {
						$VarDef =~ s/,(\s+#)/$1/;
					}
				$OutLineNum = ffg_print ($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"print_scrrec_field",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0) ;
			}
			# $OutLineNum = ffg_print ($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"print_scrrec_field",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
		}
		$idx++;
		$tt++;
	}
	our $RetFieldsCount=$FieldsCount;
} # end  define_scrrec_fields {

sub list_scrrec_fields {
	my ($Form,$ScrRec,$Table,$ColType,$NoEntry,$InPrefix,$Tabul,$WriteMode,$isRecord) = (@_ ) ;
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	my $FieldsCount=0;
	$Noentry //= 'false' ;
	$WriteMode //= "skipline" ;
	$isRecord //= "record" ;
	$Section //= ".*" ;
	$tabnum=0;
	if ( $ColType eq ".*") { 
		$ColType="all";
	}
	my @ScreenRecFieldsList = () ;

	if ( $WriteMode =~ /skip/ ) {
		$ColSep="\n";
	} else {
		$ColSep="";
	}
	if ( $isRecord =~ /isRecord/ ) {
		$Prefix = $Prefix . '.' ;
	}
	# first count fields to be printed ( no need to sort )
	my $tt=0;
	TCOUNTFIELDS: while (defined($ScreenRecord{$Form}->{$ScrRec}->{'FieldList'}[$tt])) {
		my $fieldname=$ScreenRecord{$Form}->{$ScrRec}->{'FieldList'}[$tt];
		my $tabname=$ScreenRecord{$Form}->{$ScrRec}->{'TableList'}[$tt];
		my $container=$ScreenRecord{$Form}->{$ScrRec}->{'CntrnList'}[$tt];
		my $key=sprintf "%s:%s:%s",$fieldname,$tabname,$container;
		if (  $ScreenRecord->{$FormName}->{$ScrRec}->{TableList}[$tt] =~ /^${Table}$/ ) {
			if (defined($FormField->{$Form}->{$key}->{'Visible'}) && $FormField->{$Form}->{$key}->{'Visible'} eq 'false' ) {
				$tt++;
				next TCOUNTFIELDS ;
			}
				#if ( $FormField->{$Form}->{$key}->{'Noentry'} !~ /$NoEntry/ ) {
			if ( defined($FormField->{$Form}->{$key}->{'Noentry'}) && $FormField->{$Form}->{$key}->{'Noentry'} !~ /$NoEntry/ ) {
				$tt++;
				next TCOUNTFIELDS ;
			}
			
			if (defined($Prefix) && length($Prefix) > 0 ) {
				if ( $DBSchema{$tabname}{$fieldname}->{'IsPK'} eq 'true' && $ColType !~ /pkey|all/ ) {
					$tt++;
					next TCOUNTFIELDS ;
				}
				if ( $DBSchema{$tabname}{$fieldname}->{'IsFK'} eq 'true' && $ColType !~ /fkey|all/ ) {
					$tt++;
					next TCOUNTFIELDS ;
				}
				if ( $ColType =~ /lookup/ && $TablesList{$tabname}->{'Role'} ne "lookup" ) {
					$tt++;
					next TCOUNTFIELDS ;
				}
				$FieldsCount++;
			} else {
				$FieldsCount++;
			}
		}
		$tt++;
	}

	$tt=0;
	$fflx=0;
		TREADFIELDS:while (defined($ScreenRecord{$Form}->{$ScrRec}->{'FieldList'}[$tt])) {
			if (  $ScreenRecord->{$FormName}->{$ScrRec}->{TableList}[$tt] =~ /^${Table}$/ ) {
				my $fieldname=$ScreenRecord{$Form}->{$ScrRec}->{'FieldList'}[$tt];
				my $tabname=$ScreenRecord{$Form}->{$ScrRec}->{'TableList'}[$tt];
				my $container=$ScreenRecord{$Form}->{$ScrRec}->{'CntrnList'}[$tt];
				my $key=sprintf "%s:%s:%s",$fieldname,$tabname,$container;
				if (defined($FormField->{$Form}->{$key}->{'Visible'}) && $FormField->{$Form}->{$key}->{'Visible'} eq 'false' ) {
					$tt++;
					next TREADFIELDS ;
				}
				if ( defined($FormField->{$Form}->{$key}->{'Noentry'}) && $FormField->{$Form}->{$key}->{'Noentry'} !~/$NoEntry/ ) {
					$tt++;
					next TREADFIELDS ;
				}
				
				if (defined($InPrefix) && length($InPrefix) > 0 ) {
					if ( $DBSchema{$tabname}{$fieldname}->{'IsPK'} eq true && $ColType !~ /pkey|all/ ) {
						$tt++;
						next TREADFIELDS ;
					}
					if ( $DBSchema{$tabname}{$fieldname}->{'IsFK'} eq 'true' && $ColType =~ /fkey|all/ ) {
						$tt++;
						next TREADFIELDS ;
					}
					if ( $ColType =~ /lookup/ && $TablesList{$tabname}->{'Role'} ne "lookup" ) {
						$tt++;
						next TREADFIELDS ;
					}
					($FldName,$SRName)=column_is_in_form($fieldname,$tabname);
				} else {
					($FldName,$SRName)=column_is_in_form($fieldname,$tabname);
				}
				@ScreenRecFieldsList[$fflx++] = $FldName ;
				#$fflx++;
			}
		$tt++;
	}	
	return @ScreenRecFieldsList ;
	
} # end  list_scrrec_fields {

sub print_scrrec_tables {
	my ($MODULE,$Form,$ScrRec,$Role,$OuterJoin,$Tabul,$WriteMode) = (@_ ) ;
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	my $FieldsCount=0;
	$Table //= ".*" ;
	$Noentry //= 'false' ;
	$WriteMode //= "skipline" ;
	$isRecord //= "record" ;
	$Section //= ".*" ;
	$tabnum=0;

	if ( $WriteMode =~ /quoteskip/ ) {
		$ColSep="\",\n";
	} elsif ( $WriteMode =~ /skip/ ) {
		$ColSep="\n";
	} elsif ( $WriteMode =~ /flat/ ) {
		$ColSep="";
	}
	if ( $isRecord =~ /record/ ) {
		if ( $Prefix !~ /^$/ ) {
			$Prefix = $Prefix . '.' ;
		}
	}
	# first count fields to be printed ( no need to sort )
	my $tt=0;
	my %SRTableList = () ;
	my $TablesCount =  0 ;
	#COUNTTABLES: foreach  $key ( keys %{ $SRTableList }  ) {
	COUNTTABLES: while (defined($ScreenRecord->{$FormName}->{$ScrRec}->{'TableList'}[$tt])) {
		my $Table = $ScreenRecord{$Form}->{$ScrRec}->{TableList}[$tt];
		if ( $TablesList{$Table}->{'Role'} !~ /$Role/ ) {
			$tt++;
			next COUNTTABLES;
		}
		if (!defined($SRTableList{$Table})) {
			$SRTableList{$Table} = $Table ;
			$TablesCount++;
		}
		$tt++;
	}

	$tabnum=0;
	my $tt=0;
	READTABLES: foreach  $TabName ( keys %{ $SRTableList } ) {
		if ( $TablesList{$TabName}->{'Role'} !~ /$Role/ ) {
			next READTABLES;
		}
		#printf ">> %s\n",$TablesList->{$TabName}->{'Role'};
		if ($OuterJoin =~ /outer/ ) {
				if ($TablesList{$TabName}->{'Role'} =~ /lookup/ ) {
					$TabName=sprintf " %s OUTER ",$TabName;
				}
		}
		if ( $tabnum + 1 < $TablesCount ) {
			$TabName=sprintf "%s,%s",$TabName,$ColSep ;
			if ( $WriteMode =~ /quoteskip/ ) {
				$TabName = "\"" . $TabName ;
			}
			if ( $WriteMode =~ /flat/ ) {
				$OutLineNum = ffg_print ($SRCHANDLE,$TabName,$OutLineNum,$CurrentFctName,"print_scrrec_table",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0) ;
			} else {
				$OutLineNum = ffg_print ($SRCHANDLE,$TabName,$OutLineNum,$CurrentFctName,"print_scrrec_table",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
			}
		} else {
			$TabName=sprintf "%s%s",$TabName,$ColSep ;
			if ( $WriteMode =~ /quoteskip/ ) {
				$TabName = "\"" . $TabName ;
			}
			$OutLineNum = ffg_print ($SRCHANDLE,$TabName,$OutLineNum,$CurrentFctName,"print_scrrec_table",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0) ;
			my ($package, $filename, $line, $CallingSub, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);
			if ( $CallingSub =~ /generate_module|eval/ && $lineend !~ /^$/ ) {
				$OutLineNum = ffg_print ($SRCHANDLE,"\n",$OutLineNum,$CurrentFctName,"print_scrrec_table",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0) ;
			} else {
				$OutLineNum = ffg_print ($SRCHANDLE,"\n",$OutLineNum,$CurrentFctName,"print_scrrec_table",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
			}
		}
			# reset IndentLevel to saved value
		if ($tabnum == 1 ) {
			$IndentLevel=$SavedIndentLevel;
		}
		$tabnum++;
		$idx++;
		$tt++;
	}
	
	our $RetTablesCount=$tabnum;
} # end  print_scrrec_tables {

sub bld_scrrec_join {
	my ($MODULE,$Form,$ScrRec,$ParentTable,$ChildTable,$Role,$OuterJoin,$Tabul,$WriteMode) = ( @_ ) ;
	my $tbl=0;
	my @TabList=();
	my @JoinTablesList=();
	my $tt=0;
	my $TablesCount=0;
	my @JoinText = () ;
	my $elem=0;
	my @ParentCols=split (/,/,$TablesList{$ChildTable}->{ParentJoinColumns}[0]);
	my @ChildCols=split (/,/,$TablesList{$ChildTable}->{ChildJoinColumns}[0]);
	my $pc=0;

	my $ChildAndLookupList = "\" FROM ";
	my @tablesListArray=list_tables($Section,$Role);
	my $tbx=0;
	foreach my $tabname ( @tablesListArray  ) {
		if ($tbx < $#tablesListArray) {
			$ColSep=",";
		} else {
			$ColSep="";
		}
		if (!(defined($WriteMode) || $WriteMode ne "flat") ) {
			$ColSep = $ColSep . '\n' ;
		} 

		$ChildAndLookupList=sprintf "%s%s%s",$ChildAndLookupList,$tabname,$ColSep;
		$tbx++;
	}
	$ChildAndLookupList=$ChildAndLookupList . "\",";

	# First set FK to parent criteria
	my $ParentChildClause="";
	while ($pc <= $#ChildCols) {
		if ( $WhereWritten == 0 ) {
			$ParentChildClause = sprintf "\" WHERE %s.%s = ?\",\n",$ChildTable,$ChildCols[$pc],$ParentTable,$ParentCols[$pc++];
			#ffg_print_short ($Line) ;
			$WhereWritten=1;
		} else {
			if ( defined($ChildCols[$pc]) && defined($ParentCols[$pc]) ) {
				$ParentChildClause = sprintf "%s\t\" AND %s.%s = ?\",\n",$ParentChildClause,$ChildTable,$ChildCols[$pc],$ParentTable,$ParentCols[$pc++];
				#ffg_print_short ( $Line) ;
			}
		}
	}
	# then join with lookup tables if necessary
	@JoinTablesList=list_tables($Section,"lookup");
	my $fkx=0;


	my $JoinLines="";
	while (defined($JoinTablesList[$fkx])) {
		# check if lookup form table  is in tables list and has a join
		# my @LookupTable = grep { $_ eq $JoinTablesList[$fkx] } @ { $TablesList{$ChildTable}->{ParentLookupTables} };
		my $lkx=0;
		my $LookupTable="";
		while (defined($TablesList{$ChildTable}->{ParentLookupTables}[$lkx])) {
			my @LookupParentCols =();
			my @LookupChildCols =();
			#my $JoinLines="";
			if ($TablesList{$ChildTable}->{ParentLookupTables}[$lkx] eq $JoinTablesList[$fkx] ) {
				$LookupTable=$TablesList{$ChildTable}->{ParentLookupTables}[$lkx];
				if ( $LookupTable !~ /^$/) {
					@LookupParentCols=split(/,/,$TablesList{$ChildTable}->{ParentLookupCols}[$lkx]);
					@LookupChildCols=split(/,/,$TablesList{$ChildTable}->{ChildLookupCols}[$lkx]);
					my $clx=0;
#					my $JoinLines="";
					while (defined($LookupParentCols[$clx])) {
						if (!defined($Dbschema{$ChildTable}->{$LookupChildCols[$clx]}->{NotNull})) {
							$ChildAndLookupList =~ s/FROM(\s+$LookupTable\b)/FROM OUTER $1/ ;
							$ChildAndLookupList =~ s/,(\s*$LookupTable\b)/,OUTER $1/ ;
						}
						$JoinLines=sprintf "%s\t\" AND %s.%s = %s.%s \",\n",$JoinLines,$ChildTable,$LookupChildCols[$clx],$LookupTable,$LookupParentCols[$clx];
						#ffg_print_short($line);
						$clx++;
					}
				} 
			} 
			$lkx++;
		}
		# if table not found
		
		if ($LookupTable =~ /^$/) {
			$JoinLines=sprintf "%sERROR on join build: the table %s has no foreign key pointing to %s, please set join manually if necessary\n",$JoinLines,$ChildTable,$JoinTablesList[$fkx];	
			#ffg_print_short($line);
		}
		$fkx++;
		$a=1;
	}
	ffg_print_short($ChildAndLookupList);
	ffg_print_short($ParentChildClause);
	ffg_print_short($JoinLines);
} # end  bld_tables_join

########################################################################################
sub define_form_fields {
	my ($MODULE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$Prefix,$Tabul,$WriteMode,$isRecord) = (@_ ) ;
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	my $FieldsCount=0;
	if ( $NoEntry =~ /^$/ ) {
		$NoEntry="true|false" ;
	}
	if ( $WriteMode =~ /^$/ ) {
		$WriteMode="skipline" ;
	}
	if ( $isRecord =~ /^$/ ) {
		$isRecord //= "record" ;
	}

	if ( $Section =~ /^$/ ) {
		$Section=".*" ;
	}

	if ( $ColType eq ".*") { 
		$ColType="all";
	}
	my $ColSep = "," ;

	if ( $isRecord =~ /record/ ) {
		if ( $Prefix !~ /^$/ ) {
			$Prefix = $Prefix . '.' ;
		}
	}
	$tabnum=0;
	# first count fields to be printed ( no need to sort )
	my $key="";
	my $fldname="";
	my $tabname="";
	my @ThisFormFields=();
	if ( $Section eq "parent") {
		@ThisFormFields=list_form_fields ($SRCHANDLE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$InPrefix,"","listkey") ;
	} elsif ( $Section eq "child") {
		@ThisFormFields=list_form_fields ($SRCHANDLE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$InPrefix,"","listkey") ;
	} elsif ( $Section eq "grandchild") {
		@ThisFormFields=list_form_fields ($SRCHANDLE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$InPrefix,"","listkey") ;
	}
	
	my $FieldsCount=$#ThisFormFields+1;
	
	my $key="";
	my $VarDef="";
	my $DefLike="";
	my $Tables="";
	my $field="";
	my $field_num=0;
	# DREADFIELDS: foreach $key (sort { $FormField->{$Form}->{$a}->{'Order'} cmp $FormField->{$Form}->{$b}->{'Order'} }keys %{ $FormField->{$Form} } ) {
	while (defined($ThisFormFields[$field_num])) {
		if ( $ThisFormFields[$field_num] =~ /(\w+):(\w+):(\w+)/ ) {
			$key=$&;
			$field = $1;
			$table=$2;
			$container=$3;
		} else {
			$field_num++; # some xxx in the form, see form definition
			next;
		}

		if (!defined($FormField->{$Form}->{$key}->{'ColDef'} )) { 
			$FormField->{$Form}->{$key}->{'ColDef'} = sprintf "%s Unknown: please modify form's field datatype or fix in source code",$key ;
			printf LOGFILE "Error: Field %s in table %s has no data type, please check form file if field belongs to table\n",$field,$table;
			printf STDERR "Error: Field %s in table %s has no data type,please check form file if field belongs to table\n",$field,$table;
		}
		
		if ( $DEBUGPRINT > 2 ) { printf LOGFILE "Field: %s Location: %s\n",$field,$FormField->{$Form}->{$key}->{'Order'} };
		$column=$FormField->{$Form}->{$key}->{'Column'};
		if ($DefineStyle =~ /like/i ) {
			if ( defined($DBSchema{$table}->{$field}->{datatype}) ) {
				$DefLike=sprintf " LIKE %s.%s,   # ",$table,$field;
			} else {
				if (defined($FormField->{$Form}->{$key}->{'ColDef'} && $FormField->{$Form}->{$key}->{'ColDef'} !~ /^$/ ) ) {
					$DefLike=sprintf " %s,  #",$FormField->{$Form}->{$key}->{'ColDef'} ;
				} else {
					$DefLike="please specify data type here or check field data type in the form\n";
					printf LOGFILE "Error: field %s.%s had no data"
				}
			}
		} else {
				$DefLike="";
		}
		if (defined($Prefix) && length($Prefix) > 0 ) {
			if ( $DBSchema{$table}{$column}->{'IsPK'} eq true && $ColType =~ /attr/ ) {
				next DREADFIELDS ;
			}
			
			if ($tabnum++ > 0 ) {
				
				$VarDef=sprintf "%s%s %s %s",$Prefix,$field,$DefLike,$FormField->{$Form}->{$key}->{'ColDef'} ;
			} else {
				$VarDef=sprintf "%s%s %s %s",$Prefix,$field,$DefLike,$FormField->{$Form}->{$key}->{'ColDef'} ;
			}
		} else {
			if ($tabnum++ > 0 ) {
				$VarDef=sprintf "%s %s %s",$field,$DefLike,$FormField->{$Form}->{$key}->{'ColDef'};
			} else {
				$VarDef=sprintf "%s %s %s",$field,$DefLike,$FormField->{$Form}->{$key}->{'ColDef'};
			}
		}
		
		if ( $VarDef ne "" ) {
			if ( $tabnum < $FieldsCount ) {
				if ( $VarDef !~ /\sLIKE\s/) {
					$VarDef = sprintf "%s,\n",$VarDef;
				}
				$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_form_fields",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			} else {
				if ( $VarDef =~ /\sLIKE\s/) {
					$VarDef =~ s/,(\s+#)/$1/;
				} else {
					$VarDef =~ s/,(\s*)#/$1#/ ;
				}
				$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_form_fields",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1);
				#$lineend =~ s/\n// ;
			}
		}
		$idx++;
		$field_num++;
	}

	our $RetFieldsCount=$FieldsCount;
} # end  define_form_fields {

# define one lookup record per table
# scan the lookup tables list and grab the field names
sub define_lookup_fields {
	my ($Form,$Section,$Style,$Tabul,$WriteMode,$isRecord) = (@_ ) ;
	# $Style: "astype" or "plain" or "fromtype"
	my $CountFields=0;
	if ( $Style !~ /astype|plain|fromtype/) {
		return 0;
	}

	READLKUP: foreach my $tab ( keys %TablesList ) {
		if ( !defined ($TablesList{$tab}->{Role}) || $TablesList{$tab}->{Role} ne "lookup" ) {
			next READLKUP ;
		}
		if ( $TablesList{$tab}->{Section} ne $Section ) {
			next READLKUP ;
		}
		my $idx=0;
		
		if ($Style =~ /astype/) {
			$OutLineNum=ffg_print($SRCHANDLE,"DEFINE ${TypeDataPrefix}${SRLUpPrfx}${tab} TYPE AS RECORD",$OutLineNum,$CurrentFctName,"AdHoc",$TemplateFile,$TmpltLineNum,$SIGNHANDLE); 
		} elsif ($Style =~ /plain/) {
			$OutLineNum=ffg_print($SRCHANDLE,"DEFINE ${SRLUpPrfx}${tab} RECORD",$OutLineNum,$CurrentFctName,"AdHoc",$TemplateFile,$TmpltLineNum,$SIGNHANDLE); 
		} elsif ($Style =~ /fromtype/) {
			$OutLineNum=ffg_print($SRCHANDLE,"DEFINE ${SRLUpPrfx}${tab} ${TypeDataPrefix}${SRLUpPrfx}${tab}",$OutLineNum,$CurrentFctName,"AdHoc",$TemplateFile,$TmpltLineNum,$SIGNHANDLE); 
			$CountFields++;
			# no need to print the colums, next iteration of the foreach
			next READLKUP ;
		} 
		my $tt=0;
		my $Line="";
		$IndentLevel++;
		my @FieldsArray= @{$TablesList{$tab}->{'FieldList'}};
		my $FieldsCount= $#FieldsArray;
		while (defined($TablesList{$tab}->{'FieldList'}[$tt])) {
			$Line = sprintf "%s LIKE %s.%s,\n",$TablesList{$tab}->{'FieldList'}[$tt],$tab,$TablesList{$tab}->{'ColumnsList'}[$tt] ;
			if ( $tt == $FieldsCount) {
				$Line =~ s/,\n// ;
			}
			#define_form_fields($SRCHANDLE,$MainFormName,$tab,$Section,"lookup","true","","","\t\t");
			#$MODULE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$Prefix,$Tabul,$WriteMode,$isRecord
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"AdHoc",$TemplateFile,$TmpltLineNum,$SIGNHANDLE);
			$CountFields++;
			$tt++;
		}
		$IndentLevel--;
		$OutLineNum=ffg_print($SRCHANDLE,"\n\tEND RECORD",$OutLineNum,$CurrentFctName,"AdHoc",$TemplateFile,$TmpltLineNum,$SIGNHANDLE);
	}
	$RetFieldsCount=$CountFields;
} # end  define_lookup_fields
########################################################################################
sub define_table_columns {
	my ( $MODULE,$TableName,$Section,$Role,$ColType,$VarStruct,$Prefix,$Tabul,$ExcludeFields) = ( @_ ) ;
	# module,table name,(pkey,fkey,attr,all),(record/variable),prefix,tab char,exclude exp, display max length
	# Due to the fact that the PK and FK columns may have an order different than found in the table, 
	# we have created the functions define_pk_columns ($tabname) and define_join_columns(childtable,parenttable)
	if ( $ColType =~ /pkey|fkey+/) {
		return "";
	}
	if (!defined($ExcludeFields) ) { 
		$ExcludeFields = "#@!xxa%<" ;
	}
	
	if ( $ColType eq ".*") { 
		$ColType="all";
	}

	if ( $Section =~ /^$/ ) {
		#$Section=".*" ;
	} elsif ( $Section =~ /(\w+)\+/ ) {
		$Section=$1;
		$IncludePKCols=1;
	}
	my $ColSep = "," ;
	my $VarDef = "" ;
	my $VarCount = 0 ;
	my $key="";
	my $ColsToDefine=0;
	my $DefinedCols=0;
	
	# first count variables to be defined
	# TODO: case 'no section specified does not work'
	COUNTDEFINECOL: foreach $colname ( keys %{ $DBSchema{$TableName} }  ) {
		next if  $colname =~ /^$/;

		#if ( ${Section} !~ /^$/ ) {
		#	if ( $DBSchema{$TableName}{$colname}->{'Section'} ne $Section ) {
		#		next COUNTDEFINECOL;
		#	} 
		#}
		
		if ( ${Role} !~ /^$/ ) {
			if ( $DBSchema{$TableName}{$colname}->{'Role'} ne $Role ) {
				next COUNTDEFINECOL;
			} 
		}

		if (defined($ColumnInForm) ) {
			my $formkey=sprintf "%s:%s",$colname,$TableName;
			my ( $IsInForm,$ScreenRecord) = (column_is_in_form($childColumns[$ll],$fkey->{childTable}));
			if ( $IsInForm ne "0") {
				next COUNTDEFINECOL;
			}
		}
		if ( $ColType eq 'pkey' && defined($DBSchema{$TableName}{$colname}->{'IsPK'}) ) {
			$VarCount++;
		} elsif ( $ColType =~ /fkey/ && defined($DBSchema{$TableName}{$colname}->{'IsFK'}) ) {
			if ( $ColType eq 'fkey') {
				$VarCount++;	
			} elsif ($ColType =~ /fkey:(\w+)/) {
				$FK=sprintf "%s:%s",$TableName,$1;
				#printf "%s:%s\n",$ForeignKeys{$FK}->{'childColumns'},$colname;
				if ( $ForeignKeys{$FK}->{'childColumns'}=~ /\b$colname\b/ ) {
					$VarCount++;	
				}
				$a=1;
			}
			
		} elsif ( $ColType eq 'attr' && !defined($DBSchema{$TableName}{$colname}->{'IsPK'}) ) {
			$VarCount++;
		} elsif ( $ColType eq 'all' && $colname !~ /$ExcludeFields/ ) {
			$VarCount++;
		}
		if ( ${Section} !~ /^$/ ) {
			if ( $DBSchema{$TableName}{$colname}->{'Section'} ne $Section ) {
				if ( defined($DBSchema{$TableName}{$colname}->{IsPK}) ) {
					if ( $IncludePKCols == 0 ) {
						$LineStart = "# ";
					} else {
						$LineStart = "";
						$ColsToDefine++;
					}
				} else {
					$LineStart = "# ";
				}
			} else {
				$LineStart = "";
				$ColsToDefine++;
			}
		} else {
			$LineStart = "";
			$ColsToDefine++;
		}
	}
	my $VarNum=0;
	my $colname="";
	my $DefLike="";
	my $ColDataType="";
	my $VarDef="";
	my $LastDefined = 0;
	if ( $DEBUGPRINT > 2) { printf LOGFILE "-----------------------------------------------------------------\n"; }
	my $DefinedCols=0;
	DEFINECOL: foreach my  $colname (sort { $DBSchema{$TableName}{$a}->{'Order'}  <=> $DBSchema{$TableName}{$b}->{'Order'} } keys %{ $DBSchema{$TableName} } ) {
	#          foreach my $colname (sort { $DBSchema{$TableName}{$a}->{'Order'} <=> $DBSchema{$TableName}{$b}->{'Order'}  }keys %{ $DBSchema{$TableName} } ) {
		next if  $colname =~ /^$/;
		next if !defined($DBSchema{$TableName}{$colname}->{Order});    # due to weird behaviour in the sort statement
		
		if ( ${Role} !~ /^$/ ) {
			if ( $DBSchema{$TableName}{$colname}->{'Role'} ne $Role ) {
				next DEFINECOL;
			} 
		}

		if (defined($ColumnInForm) ) {
			my $formkey=sprintf "%s:%s",$colname,$TableName;
			my ( $IsInForm,$ScreenRecord) = (column_is_in_form($childColumns[$ll],$fkey->{childTable}));
			if ( $IsInForm ne "0") {
				next DEFINECOL;
			}
		}
		if ( $DEBUGPRINT > 2) { printf LOGFILE "-> %s,%s\n",$colname,$DBSchema{$TableName}{$colname}->{Order}; }
		my $VarDef = "" ;
		if ($DefineStyle =~ /like/i) {
			$DefLike=sprintf " LIKE %s.%s,   # ",$TableName,$colname;
		} else {
			$DefLike=" ";
		}
		
		my $ColDataType=$DBSchema{$TableName}{$colname}->{'datatype'};
		$ColDataType =~ s/serial/integer/;

		if ( $ColType eq 'pkey' && defined($DBSchema{$TableName}{$colname}->{'IsPK'}) ) {
			#$VarDef = $colname . $DefLike . $DBSchema{$TableName}{$colname}->{'datatype'} ;
			$VarDef = $colname . $DefLike . $ColDataType ;
			$VarNum++;
		} elsif ( $ColType =~ /fkey/ && defined($DBSchema{$TableName}{$colname}->{'IsFK'}) ) {
				if ( $ColType eq 'fkey') {
					#$VarDef = $colname . $DefLike . $DBSchema{$TableName}{$colname}->{'datatype'} ;
					$VarDef = $colname . $DefLike . $ColDataType ;
					$VarNum++;
				} elsif ($ColType =~ /fkey:(\w+)/) {
					$FK=sprintf "%s:%s",$TableName,$1;
					#printf "%s:%s\n",$ForeignKeys{$FK}->{'childColumns'},$colname;
					if ( $ForeignKeys{$FK}->{'childColumns'}=~ /\b$colname\b/ ) {
						#$VarDef = $colname . $DefLike . $DBSchema{$TableName}{$colname}->{'datatype'} ;
						$VarDef = $colname . $DefLike . $ColDataType ;
						$VarNum++;
					}
				}
		} elsif ( $ColType eq 'attr' && !defined($DBSchema{$TableName}{$colname}->{'IsPK'}) ) {
			#$VarDef = $colname . $DefLike . $DBSchema{$TableName}{$colname}->{'datatype'} ;
			$VarDef = $colname . $DefLike . $ColDataType ;
			$VarNum++;
		} elsif ( $ColType eq 'all' && $colname !~ /$ExcludeFields/ ) {
			#$VarDef = $colname . $DefLike . $DBSchema{$TableName}{$colname}->{'datatype'} ;
			$VarDef = $colname . $DefLike . $ColDataType ;
			$VarNum++;
		}
		
		if ( ${Section} !~ /^$/ ) {
			if ( $DBSchema{$TableName}{$colname}->{'Section'} ne $Section ) {
				if ( defined($DBSchema{$TableName}{$colname}->{IsPK}) ) {
					if ( $IncludePKCols == 0 ) {
						$LineStart = "# ";
					} else {
						$LineStart = "";
						$DefinedCols++;
					}
				} else {
					$LineStart = "# ";
				}
			} else {
				$LineStart = "";
				$DefinedCols++;
			}
		} else {
			$LineStart = "";
			$DefinedCols++;
		}

		if ( $VarDef ne "" ) {
			#if ( $VarNum < $VarCount ) {
			#if ( $DefinedCols != $ColsToDefine ) {
			$VarDef = sprintf "%s%s%s\n",$LineStart,$VarDef,$ColSep ;
			if ( $DefinedCols < $ColsToDefine ) {
				$a=1;
			} else {
				if ( $LastDefined == 0 ) {
					$VarDef =~ s/,(\s*#)/$1/;
					if ( $DefinedCols == $ColsToDefine ) {
						$LastDefined=1;
					}
				}
			}
			if ( $LastDefined == 1) {
				if ( $VarNum < $VarCount ) {
					$a=1;
				} else {
					$VarDef =~ s/,(\s*#)/$1/;
				}
			}
			#if ( $VarDef !~ /\bLIKE\b/) {
			#	$VarDef = sprintf "%s%s%s\n",$LineStart,$VarDef,$ColSep ;
			#} else {
			#	$VarDef = sprintf "%s%s%s\n",$LineStart,$VarDef,$ColSep ;
			#}
			$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_table_columns",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			#} else {
			#	if ( $VarDef =~ /\sLIKE\s/) {
			#		$VarDef =~ s/,(\s+#)/$1/;
			#	}
			#	$VarDef = sprintf "%s%s",$LineStart,$VarDef ;
			#	$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_table_columns",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1);
			#}
		}
	}
	our $RetFieldsCount=$VarNum;
} # end define_table_columns 

sub print_input_events {
	my ($MODULE,$Form,$Table,$Section,$ColType,$RecordName,$Tabul,$AlternativeRecord) = (@_ ) ;
	# alternative record can be GlobalReferenceRecord for parent or foreign key name for child and grandchild
	# $ColType = insert/updatex
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	$tabnum=0;
	our $RetFieldsCount=0;
	if ( $ColType eq ".*") { 
		$ColType="all";
	}

	my %AfterFieldPrinted = ();
	my @Fkeys = {} ;
	# first check fields not belonging to main table
	
	# define ordered list of primary keys for that section, then foreign keys
#	my @AFTERFIELSPK=list_form_fields ($SRCHANDLE,$Form,$Table,$Section,".*","true|false","pkey","","","listkey",) ;
#	my @AFTERFIELSFK=list_form_fields ($SRCHANDLE,$Form,$Table,$Section,".*","true|false","fkey","","","listkey",) ;
	
	FORFATAFT: foreach my $key (sort { $InputEventFields{$a}->{'Order'} cmp $InputEventFields{$b}->{'Order'} } keys %InputEventFields ) { 
#		if (defined($InputEventFields{$key}->{Table}) && $InputEventFields{$key}->{Table} !~ /^${Table}$/) {
#			next FORFATAFT;
#		}
		if (defined($InputEventFields{$key}->{Section}) && $InputEventFields{$key}->{Section} !~ /^$Section$/) {
			next FORFATAFT;
		}
		
		if (!defined($InputEventFields{$key}->{Field})) {
			$idx++;
			next FORFATAFT;
		} 
		my $TakeIt=0;
		if ( defined($InputEventFields{$key}->{PKY}) && $ColType =~ /pkey/ ) {
			$TakeIt++;
		}
		if ( defined($InputEventFields{$key}->{UKY}) && $ColType =~ /ukey/ ) {
			$TakeIt++;
		}
		
		if ( defined($InputEventFields{$key}->{FKY}) && $ColType =~ /fkey/ ) {
			$TakeIt++;
		}
		
		if ($TakeIt == 0 ) {
			next FORFATAFT ;
		}
		if (defined($InputEventFields{$key}->{DoBeforeField}) ) {
			$Line = sprintf "BEFORE FIELD %s",$InputEventFields{$key}->{Field};
			ffg_print_short($Line,"lf");
			$IndentLevel++;
#			my $AdditionalFilter="";
#			my $FKColumns_in_form=find_filter_columns_in_form($FormField->{$Form}->{$key}->{'Column'},$FieldTable,$BoxParentTable);
#			@AdditionalFilters=@$FKColumns_in_form;
#			$AdditonalFiltersList=split(/,/,@AdditionalFilters);

			if (defined($InputEventFields{$key}->{BoxFillFct})) {
				$Line=sprintf "CALL %s(",$InputEventFields{$key}->{BoxFillFct};
				foreach my $field ( split(/,/,$InputEventFields{$key}->{BoxFilterParams}) ) {
					if ( $field eq $GlobalReferenceKey) {
						$Line=sprintf "%s%s.%s,",$Line,${GlobalReferenceRecord},$field;
					} else {
						$Line=sprintf "%s%s.%s,",$Line,${RecordName},$field;
					}
				}
				$Line =~ s/,$/)/;
				ffg_print_short($Line,"lf");
				ffg_print_short("","lf");
			}
			$IndentLevel--;
		}
		if ( !defined($AfterFieldPrinted{$key})) {
			if (defined($InputEventFields{$key}->{NotNull}) ) {
				# since a primary key cannot be null, we force the check: ON CHANGE will not see if a NULL is input
				$Line = sprintf "AFTER FIELD %s\n",$InputEventFields{$key}->{Field};
			} else {
				$Line = sprintf "ON CHANGE %s\n",$InputEventFields{$key}->{Field};
			}

			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$AfterFieldPrinted{$key}=1;
			#$IndentLevel++;
		}
		if (defined($InputEventFields{$key}->{NotNull}) || defined($InputEventFields{$key}->{PKY})) {
			# handle a primary key or NOT NULL
			#if ( !defined($InputEventFields{$key}->{ScreenRecord})) {
			if ( $InputEventFields{$key}->{Section} !~ /child/ ) {
				$IndentLevel++;
				$Line = sprintf "IF %s.%s IS NULL AND fgl_lastkey() <> fgl_keyval(\"ACCEPT\") THEN\n",${RecordName},$InputEventFields{$key}->{Field};
			} else {
				$IndentLevel++;
				$Line = sprintf "IF %s[%s].%s IS NULL AND fgl_lastkey() <> fgl_keyval(\"ACCEPT\") THEN\n",$RecordName,$ArrCurrVar,$InputEventFields{$key}->{Field};
			}
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel++;
			my $Line = sprintf "NEXT FIELD %s\n",$InputEventFields{$key}->{Field};
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel--;
			my $Line = sprintf "END IF\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		}
		# Do check after having all the PK columns
		if (defined($InputEventFields{$key}->{IsLastPKColumn})) {
			if ( $ColType =~ /pkey|ukey|all/ ) {
				# check of primary key only in case of insert, not update
				# gets here if this field is the last one of the primary key
				my $tabname=$InputEventFields{$key}->{Table};
				my $colname=$InputEventFields{$key}->{Field};
				if ( $DBSchema{$tabname}->{$colname}->{datatype} !~ /SERIAL/i ) {
					# check if the primary key exists
					# Write the check primary key exist function
					$Line = "IF ${SqlCheckPrimaryKeyFct}" . "_" . $InputEventFields{$key}->{Table} . "(" ;
					my @parentCols = split(/,/,$InputEventFields{$key}->{PkyColList}) ;
					$xx=0;
					while(defined($parentCols[$xx])) {
						# scan the parent columns list and check if the column is in the section or not
						# build key for this field
						$ThisKey=$key;
						$ThisKey =~ s/^\w+:/$parentCols[$xx]:/ ;
						if ( $Section eq "parent") {
							if ( defined($InputEventFields{$ThisKey}->{Field}) && $InputEventFields{$ThisKey}->{Section} eq  "parent" ) {
								# This is parent section, check if the field is in the form or not
								$Line = sprintf "%s,%s.%s",$Line,$RecordName,$parentCols[$xx];
							} else {
								#This value is set somewhere else as a global ( like cmpy_code for instance)
								$Line = sprintf "%s,%s.%s",$Line,$AlternativeRecord,$parentCols[$xx];
							}
						} elsif ( $Section eq "child") {
							if (defined($InputEventFields{$ThisKey}->{Field}) && $InputEventFields{$ThisKey}->{Section} eq  "child" ) {
							# child section
								$tab=$InputEventFields{$ThisKey}->{Table};
								$col=$parentCols[$xx];
								$Line = sprintf "%s,%s%s[%s].%s",$Line,$LocalVarPrefix,$ChildSRArray,$ArrCurrVar,$parentCols[$xx];
							} else {
								$Line = sprintf "%s,%s.%s",$Line,$AlternativeRecord,$parentCols[$xx];
							}
						} elsif ( $Section eq "grandchild") {
							if (defined($InputEventFields{$ThisKey}->{Field}) && $InputEventFields{$ThisKey}->{Section} eq  "child" ) {
							# grandchild section
								$tab=$InputEventFields{$ThisKey}->{Table};
								$col=$parentCols[$xx];
								$Line = sprintf "%s,%s%s[%s].%s",$Line,$LocalVarPrefix,$GrandChildSRArray,$ArrCurrVar,$parentCols[$xx];
							} else {
								$Line = sprintf "%s,%s.%s",$Line,$AlternativeRecord,$parentCols[$xx];
							}
						 }
						$xx++;
					}
					$Line = $Line . ") THEN\n" ;
					$Line =~ s/\(,/(/;
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$IndentLevel++;
					my $Line = sprintf "ERROR \"%s:%s\"\n",$InputEventFields{$key}->{Table},$Exists;	
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					my $Line = sprintf "NEXT FIELD %s\n",$InputEventFields{$key}->{Field};
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$IndentLevel--;
					my $Line = sprintf "END IF\n";
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					
					if ($InputEventFields{$key}->{Section} =~ /child/) {
						my $Line="LET ${LocalVarPrefix}${ChildPkyArray}[${ArrCurrVar}]." . $InputEventFields{$key}->{Field} . " =  ${LocalVarPrefix}${ChildSRArray}[${ArrCurrVar}]." . $InputEventFields{$key}->{Field} ;
						$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					}
					#AFTER ROW other derivated values
				}
				$RetFieldsCount=$xx;
			}
			#$IndentLevel--;
			#$IndentLevel--;
		}
		
		# we don't want to look at foreign keys if there are no lookup tables
		if ( ($Section eq "parent" && $ParentLookupTables > 0 ) ||
		($Section eq "child" && $ChildLookupTables > 0 ) ||
		($Section eq "grandchild" && $GrandChildLookupTables > 0 ) ) {
			if (defined($InputEventFields{$key}->{FKY})) {
				#if ( $ColType =~ /fkey|all/ ) {
				if ( $ColType =~ /fkey/ ) {
					# if $Section eq parent and $ParentLookupTables > 0
					if ( !defined($AfterFieldPrinted{$key})) {
						my $Line = sprintf "AFTER FIELD %s\n",$InputEventFields{$key}->{Field};
						$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
						$AfterFieldPrinted{$InputEventFields{$key}->{Field}}=1;
						$RetFieldsCount++;
					}
					if ( !defined($InputEventFields{$key}->{ScreenRecord})) {
						bld_lookup_call($RecordName,$SRLUpPrfx ,$Section,$InputEventFields{$key},"input");
						$RetFieldsCount++;
						ffg_print_short("","lf");
					} else {
						$ArrayName=sprintf ("%s%s[%s]",$LocalVarPrefix,$ChildSRArray,$ArrCurrVar);
						bld_lookup_call($ArrayName,$ArrayName,$Section,$InputEventFields{$key},"input");
						$RetFieldsCount++;
						ffg_print_short("","lf");
					}
					$AfterFieldList{$LastChildColumn} = 1;
				}
			}
			$IndentLevel--;
		}
		$idx++;
	}

} # end  print_input_events {

sub print_inputarray_events {
	my ($MODULE,$FormName,$SR,$ArrayName,$Table,$ColType,$Section,$Tabul) = (@_ ) ;
	# $ColType = insert/update
	my $idx=0;
	my $fieldslist="";
	my $FldName="";
	$tabnum=0;
	our $RetFieldsCount=0;
	my @LookupTables = () ;
	my $lkpt=0;
	my $tbx=0;
	if ( $ColType eq ".*") { 
		$ColType="all";
	}
	my  @AfterFieldFields = list_afterfield_fields ($FormName,$Section,$Table);
	
		while (defined $InputEventFields{$key}) {
		if (defined($InputEventFields{$key}->{NotNull})) {
			if ( $ColType =~ /pkey|ukey/ && !defined($DBSchema{$InputEventFields{$key}->{Table}}->{$InputEventFields{$key}->{Field}}->{IsPK})
			&& !defined($DBSchema{$InputEventFields{$key}->{Table}}->{$InputEventFields{$key}->{Field}}->{IsUK})) {
				$idx++;
				next ;
			}
			if ( $ColType =~ /fkey/ && !defined($DBSchema{$InputEventFields{$key}->{Table}}->{$InputEventFields{$key}->{Field}}->{IsFK})) {
				$idx++;
				next ;
			}
			my $Line = sprintf "\tAFTER FIELD %s\n",$InputEventFields{$key}->{Field};
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$AfterFieldPrinted{$InputEventFields{$key}->{Field}}=1;
			my $Line = sprintf "\t\tIF %s%s.%s IS NULL THEN\n",${SRInpPrfx},$InputEventFields{$key}->{Table},$InputEventFields{$key}->{Field};
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $Line = sprintf "\t\t\tERROR \"This field is required\"\n",$InputEventFields{$key}->{Field};
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $Line = sprintf "\t\t\tNEXT FIELD %s\n",$InputEventFields{$key}->{Field};
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $Line = sprintf "\t\tEND IF\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);

		}
		if (defined($InputEventFields{$key}->{PKY})) {
			if ( $ColType =~ /pkey|ukey|all/ ) {
				# check of primary key only in case of insert, not update
				# gets here if this field is the last one of the primary key
				if ( $DBSchema{$InputEventFields{$key}->{Table}}->{$InputEventFields{$key}->{Field}}->{datatype} !~ /SERIAL/i ) {
					# check if the primary key exists
					if ( !defined($AfterFieldPrinted{$InputEventFields{$key}->{Field}})) {
						my $Line = sprintf "AFTER FIELD %s\n",$InputEventFields{$key}->{Field} ;
						$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
						$AfterFieldPrinted{$InputEventFields{$key}->{Field}}=1;
					}
					my $Line = sprintf "\tIF %s_%s(",${SqlCheckPrimaryKeyFct},$InputEventFields{$key}->{Table};
					$xx=0;
					my @parentCols = split(/,/,$InputEventFields{$key}->{PKY}->{parentColumns});				
					while(defined($parentCols[$xx])) {
						$Line = sprintf "%s,%s.%s",$Line,$MstInpFormRec,$parentCols[$xx];
						$xx++;
					}
					$Line = $Line . ") THEN\n" ;
					$Line =~ s/\(,/(/;
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					my $Line = sprintf "\t\tERROR \"%s:%s\"\n",$InputEventFields{$key}->{Table},$Exists;	
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					my $Line = sprintf "\t\tNEXT FIELD %s\n",$InputEventFields{$key}->{Field};
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					my $Line = sprintf "\tEND IF\n";
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				}
				$RetFieldsCount=$xx;
			}
		}
		if (defined($InputEventFields{$key}->{FKY})) {
			if ( $ColType =~ /fkey|all/ ) {
				if ( !defined($AfterFieldPrinted{$InputEventFields{$key}->{Field}})) {
					my $Line = sprintf "AFTER FIELD %s\n",$InputEventFields{$key}->{Field};
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$AfterFieldPrinted{$InputEventFields{$key}->{Field}}=1;
				}
				bld_lookup_call($MstInpFormRec,$MstLkUpRec,$Section,$InputEventFields{$key}->{FKY},"input");
				$AfterFieldList{$LastChildColumn} = 1;
			}
		}
		$idx++;
	}
$a=1;
	WHILESRFIELD: while (defined( $ScreenRecord->{$FormName}->{$SR}->{'FieldList'}[$tbx] )) {
		my $field = $ScreenRecord->{$FormName}->{$SR}->{'FieldList'}[$tbx];
		my $table = $ScreenRecord->{$FormName}->{$SR}->{'TableList'}[$tbx];
		my $key = sprintf "%s:%s",$field,$table;
		if ( $table ne $Table && $TablesList{$table}->{'Role'} =~ /lookup/) {
			$LookupTables[$lkpt++]=$table;
		}
		if (defined($FormField->{$FormName}->{$field}->{'Visible'}) && $FormField->{$FormName}->{$key}->{'Visible'} eq 'false' ) {
			$tbx++;
			next WHILESRFIELD ;
		}
		if ( defined($FormField->{$FormName}->{$key}->{'Noentry'}) && $FormField->{$FormName}->{$key}->{'Noentry'} eq 'true' ) {
			$tbx++;
			next WHILESRFIELD ;
		}
		# Check primary Key for each array element:
		# PK will be checked AFTER INPUT in the pk_array
		$tbx++;
	}

	
	if ( $ColType =~ /fkey|all/ ) {
		# get foreign keys AFTER FIELD
		my $fkx=0;
		# my @Fkeys = ( list_FK_Keys($Table) ) ;
		# exclude parent table check :-)
		# $LookupTables[0]="contact_channel";
		my $lkpt=0;
		while (defined($LookupTables[$lkpt])) {
			$key=sprintf "%s:%s",$Table,$LookupTables[$lkpt];
			my @childColumns = split (/,/,$ForeignKeys{$key}->{childColumns});
			my $LastInputFKColumn = get_LastConstraintColumn($ForeignKeys{$key},$FormName,\$FormField) ;
			my $Line = sprintf "AFTER FIELD %s\n",$LastInputFKColumn;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $ArrElem=sprintf "%s[%s]",$ArrayName,$ArrCurrVar;
			#bld_lookup_call($ArrElem,$ArrayName,$Fkeys[$fkx],"input");
			bld_lookup_call($ArrElem,$ArrayName,$Section,$ForeignKeys{$key},"input");
			$a=1;
		}
	} 
} # end  print_inputarray_events {

########################################################################################

# find parent table for a table in the child section
# this table has to be in the tables list of this form

sub bld_ck_pk_value {
	my ($table,$InputVar) = (@_ );
			
	my $Line = sprintf "\tIF %s_%s(",${SqlCheckPrimaryKeyFct},$table;
	$xx=0;
	my @parentCols = split(/,/,$PrimaryKeys{$table}->{parentColumns});				
	while(defined($parentCols[$xx])) {
		$Line = sprintf "%s,%s.%s",$Line,$InputVar,$parentCols[$xx];
		$xx++;
	}
	$Line = $Line . ") THEN\n" ;
	$Line =~ s/\(,/(/;
	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"bld_ck_pk_value",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
	my $Line = sprintf "\t\tERROR \"%s:%s\"\n",$table,$Exists;	
	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"bld_ck_pk_value",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
	my $Line = sprintf "\t\tNEXT FIELD %s\n",$field;
	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"bld_ck_pk_values",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
	my $Line = sprintf "\tEND IF\n";
	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"bld_ck_pk_values",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
	$RetFieldsCount=$xx;
} # end  bld_ck_pk_value

sub bld_after_field_list {
	my ( $tabname,$InThisForm ) = (@_) ;
	my @ParentTables=();
	my @AllParentTables=();

	my $prx=-1;
	foreach $FKid ( keys %ForeignKeys ) {
		if ( $ForeignKeys{$FKid}->{childTable} eq $tabname ) {
			my @parentCols=split (/,/,$ForeignKeys{$FKid}->{'parentColumns'});
			my @childCols=split (/,/,$ForeignKeys{$FKid}->{'childColumns'});
			for ( my $tt=0;$tt<= $#childCols;$tt++) {
				my ($ThisFieldKey,$SRName)=column_is_in_form($childCols[$tt],$tabname );
				if ( $ThisFieldKey =~ /(\w+:\w+)/ ) {
					$AfterFieldList{$1}->{lookupColumn} = $parentCols[$tt];
					$AfterFieldList{$1}->{lookupTable} = $ForeignKeys{$FKid}->{parentTable};
					$AfterFieldList{$1}->{order} = $FormField->{$FormName}{$ThisFieldKey}->{Order};
					my $NextField = $FormField->{$FormName}{$ThisFieldKey}->{NextField} ;
					if ( $FormField->{$FormName}{$NextField}->{lookupTable} eq $AfterFieldList{$1}->{lookupTable} ||
					$FormField->{$FormName}{$NextField}->{Table} eq $AfterFieldList{$1}->{lookupTable}) {
						$AfterFieldList{$1}->{DescField} = $NextField;
					}
					if (defined($FormField->{$FormName}{$ThisFieldKey}->{ScreenRecord})) {
						$AfterFieldList{$1}->{ScreenRecord} = $FormField->{$FormName}{$ThisFieldKey}->{ScreenRecord};
					}
					push ( @AllParentTables,$ForeignKeys{$FKid}->{parentTable});
				}
			}

		}
	}
	@ParentTables = unique(\@AllParentTables);
	return @ParentTables ;
}	# bld_after_field_list

sub get_parent_table {
	my ( $tabname,$InThisForm ) = (@_) ;
	# $InThisForm = 1: only select table if it is referenced in that form
	my @ParentTable={};
	my $prx=-1;
	foreach $FKid ( keys %ForeignKeys ) {
		if ( $ForeignKeys{$FKid}->{childTable} eq $tabname ) {
			my $parent=$ForeignKeys{$FKid}->{parentTable};
			if (defined($TablesList{$parent})) {
				# means the parent table is referenced
				if ( $TablesList{$parent}->{'InputFieldsCount'} > 0  ) {   # a table that has input fields is probably a parent table
					#this is probably a parent table and not a lookup
					$ParentTable[$prx++] = $ForeignKeys{$FKid}->{'parentTable'};
				} else {
					# this is definitely a lookup
					$TablesList{$parent}->{Role} = "lookup";
					if ( defined($TablesList{$parent}->{ScreenRecord})) {
						if ( $ScreenRecord->{$FormName}->{$TablesList{$parent}->{ScreenRecord}}->{Order} == 1 ) {
							$TablesList{$parent}->{Section} = "child";
							$ChildLookupTables++;
						} elsif ( $ScreenRecord->{$FormName}->{$TablesList{$parent}->{ScreenRecord}}->{Order} == 2 ) {
							$TablesList{$parent}->{Section} = "grandchild";
							$GrandChildLookupTables++;
						} else {
							$TablesList{$parent}->{Section} = "parent";
							$ParentLookupTables++;
						}
					}
				}
			} else {
				$a=1;
				# the table has a parent but parent not used in that form
			}
		}
	}
	if ( $prx == -1 ) {
		$ParentTable[0] ="none" ;
	} 
	return @ParentTable;
	
} # end  get_parent_table {

sub get_child_table {
	my $tabname = $_[0] ;
	my @ChildTable={};
	my $prx=-1;

	# this is the new way of getting child tables
	foreach $FKid ( keys %ForeignKeys ) {
		if ( $ForeignKeys{$FKid}->{parentTable} eq $tabname ) {
			my @parentCols=split (/,/,$ForeignKeys{$FKid}->{'parentColumns'});
			my @childCols=split (/,/,$ForeignKeys{$FKid}->{'childColumns'});
			for ( my $tt=0;$tt<= $#parentCols;$tt++) {
				my ($ThisFieldKey,$SRName)=column_is_in_form($childCols[$tt],$tabname );  
				
				if ( $ThisFieldKey =~ /(\w+:\w+)/ ) {
					#$AfterFieldList{$1}->{lookupColumn} = $parentCols[$tt];
					#$AfterFieldList{$1}->{lookupTable} = $ForeignKeys{$FKid}->{parentTable};
					#$AfterFieldList{$1}->{order} = $FormField->{$FormName}{$ThisFieldKey}->{Order};
					push ( @AllChildTables,$ForeignKeys{$FKid}->{childTable});
				}
			}

		}
	}
	@childTables = unique(\@AllChildTables);
	return @childTables ;

	# this is the old way, no more used for now
	foreach $FKid ( keys %ForeignKeys ) {
		if ( $ForeignKeys{$FKid}->{parentTable} eq $tabname ) {
			my $child=$ForeignKeys{$FKid}->{childTable};
			if (defined($TablesList{$child})) {
				if ( $TablesList{$child}->{'InputFieldsCount'} > 0  ) {   # a table that has input fields is probably a parent table
					#this is probably a parent table and not a lookup
					$ChildTable[$prx++] = $ForeignKeys{$FKid}->{'childTable'};
				} else {
					# this is definitely a lookup
					$TablesList{$parent}->{Role} = "lookup";
					if ( defined($TablesList{$child}->{ScreenRecord})) {
						if ( $ScreenRecord->{$FormName}->{$TablesList{$child}->{ScreenRecord}}->{Order} == 1 ) {
							$TablesList{$child}->{Section} = "child";
							$ChildLookupTables++;
						} elsif ( $ScreenRecord->{$FormName}->{$TablesList{$parent}->{ScreenRecord}}->{Order} == 2 ) {
							$TablesList{$parent}->{Section} = "grandchild";
							$GrandChildLookupTables++;
						} else {
							$TablesList{$parent}->{Section} = "parent";
							$ParentLookupTables++;
						}
					}
				}
			} else {
				$a=1;
				# the table has a parent but parent not used in that form
			}
		}
	}
	if ( $prx == -1 ) {
		$ChildTable[0] ="none" ;
	} 
	return @ChildTable;
	
} # end  get_child_table {

sub list_tables {
	my ( $Section,$Role) = ( @_ ) ;
	$Role //= ".*";
	$isRecord //= "record" ;
	my @tablesList=();
	foreach my $tabname ( keys %TablesList  ) {
		if (defined($Section) && $TablesList{$tabname}->{Section} !~ /$Section/ ) {
			next;
		}
		if (defined($Role) && $TablesList{$tabname}->{Role} !~ /$Role/ ) {
			next;
		}
		push(@tablesList,$tabname);
	}
	return @tablesList ;

} # end list_tables

sub print_tables_list {
	my ( $MODULE,$Section,$Role,$WriteMode,$Tabul,$EndLine,$ExcludeFields) = ( @_ ) ;
	$Role //= ".*";
	$isRecord //= "record" ;
	my $tableLines = "";
	my @tablesListArray=list_tables($Section,$Role);
	my $tbx=0;
	foreach my $tabname ( @tablesListArray  ) {
		if ($tbx < $#tablesListArray) {
			$ColSep=",";
		} else {
			$ColSep="";
		}
		if (!(defined($WriteMode) || $WriteMode ne "flat") ) {
			$ColSep = $ColSep . '\n' ;
		} 

		$tableLines=sprintf "%s%s%s",$tableLines,$tabname,$ColSep;
		$tbx++;
	}
	# ffg_print_short($tableLines,'noLF');
	return $tableLines;
	
} # end print_tables_list 

########################################################################################
sub print_table_columns {
	my ( $MODULE,$TableName,$Section,$Role,$ExcludeNoentry,$ColType,$VarStruct,$Prefix,$WriteMode,$Tabul,$EndLine,$ExcludeFields) = ( @_ ) ;
	# table name,(pkey,fkey,attr,all),(record/variable),prefix,display flat or split,tab or not tab,endline?,exclude exp, display max length
	
	if ( $ColType eq ".*") { 
		$ColType="all";
	}
	if (!defined($ExcludeFields) ) {
		$ExcludeFields = "#@!xxa%<" ;
	}
	#if (!(defined($WriteMode) && $WriteMode eq "flat") ) {
	if (!(defined($WriteMode) || $WriteMode ne "flat") ) {
		$ColSep = ",\n" ;
	} else {
		$ColSep = "," ;
	}
	# Start looking at determining at which is Upper and lower
	# first count variables to be defined
	my $ColCount=0;
	#### Check $DBSchema{$TableName}
	if ( $ColType eq "all" ) {
		@TableColList=list_table_columns($TableName,$Section,$Role,$ExcludeNoentry,$ColType,"","");
	} elsif ( $ColType eq "attr" ) {
		@TableColList=list_table_columns($TableName,$Section,$Role,$ExcludeNoentry,$ColType,"","");
	} elsif ( $ColType eq "pkey" ) {
		@TableColList=split(/,/,$TablesList{$TableName}->{PrimaryKey} );		
	} elsif ( $ColType eq "fkey" ) {
		@TableColList=list_FK_columns($TableName);
	} else {
		$a=1;
	}
	my $ColList = "" ;
	my $ColCount=$#TableColList ;
	my $ColNum=0;
	## Doub on Sort!!

	my $colx=0;
	while (defined($TableColList[$colx])) {
		$ColNum++;
		my $colname=$TableColList[$colx];
		if ( $VarStruct =~ /place/i ) {
			$colname = '?';
		}
		# print all in one line
		if  ( $WriteMode eq "flat") {
			if (length($Prefix) > 0) {
				$ColList = $ColList . $Prefix . '.' . $colname ;
			} else {
				$ColList = $ColList . $colname ;
			}
			if ( $colx < $ColCount ) {
				$ColList = $ColList . ',' ;
			}
		} else {
			# print one line per column
			if (length($Prefix) > 0) {
				#$ColList = $Tabul . $Prefix . '.' . $colname ;
				$ColList = $Prefix . '.' . $colname ;
			} else {
				#$ColList = $Tabul . $colname ;
				$ColList = $colname ;
			}
			if ( $colx < $ColCount ) {
				$ColList = $ColList . "," ;
				$OutLineNum=ffg_print($SRCHANDLE,$ColList,$OutLineNum,$CurrentFctName,"list_table_colum",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			} else {
				$OutLineNum=ffg_print($SRCHANDLE,$ColList,$OutLineNum,$CurrentFctName,"list_table_colum",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1);
			}
		}
		$colx++;
	} # end while @ColList
	if  ( $WriteMode eq "flat") {
		$ColList =~ s/^,//;
		$OutLineNum=ffg_print($SRCHANDLE,$ColList,$OutLineNum,$CurrentFctName,"list_table_colum",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1,0);
	}
	our $RetFieldsCount=$ColCount;
} # end print_table_columns

########################################################################################
sub list_table_columns {
	my ($Table,$Section,$Role,$NoEntry,$ColType,$Prefix,$VarStruct ) = ( @_ );
	# table name,(pkey,fkey,attr,all),(record/variable),prefix
	my $IncludePKCols=0;
	if ( $Section =~ /^$/ ) {
		$Section=".*" ;
	} elsif ( $Section =~ /(\w+)\+/ ) {
		$Section=$1;
		$IncludePKCols=1;
	}
	if ( $Role =~ /^$/) {
		$Role=".*" ;
	}
	if ( $NoEntry =~ /^$/ ) {
		$NoEntry='true|false' ;
	}
	if ( $ColType =~ /^$/ || $ColType eq ".*" ) {
		$ColType="all" ;
	}

	if (!defined($ExcludeFields) ) {
		$ExcludeFields = "#@!xxa%<" ;
	}
	my @TableColumnsList = () ;
	# first count variables to be defined
	my $ColCount=0;
	COUNTLISTTBLCOL:foreach my $colname ( keys %{ $DBSchema{$Table} } ) {
		if ( $colname =~ /^$/ ) {
			next COUNTLISTTBLCOL;
		}
		if ( defined($DBSchema{$Table}{$colname}->{IsPK}) &&  $IncludePKCols == 0 ) {
			next COUNTLISTTBLCOL;
		}
		if ((defined($DBSchema{$Table}{$colname}->{Section}) && $DBSchema{$Table}{$colname}->{Section} !~ /$Section/  ) 
		||  (!defined($DBSchema{$Table}{$colname}->{Section}) && $Section =~ /parent|child/ ) ) {
			if ( defined($DBSchema{$Table}{$colname}->{IsPK}) ) {
				if ( $IncludePKCols == 0 ) {
					next COUNTLISTTBLCOL;
				}
			} else {
				next COUNTLISTTBLCOL;
			}
		}
		if (defined($DBSchema{$Table}{$colname}->{Role}) && $DBSchema{$Table}{$colname}->{Role} !~ /$Role/) {
			next COUNTLISTTBLCOL;
		}
		#if ( defined($DBSchema{$Table}{$colname}->{Noentry}) && $DBSchema{$Table}{$colname}->{Noentry} !~ /$NoEntry/) {
		if ( $NoEntry =~ /excl/ && $DBSchema{$Table}{$colname}->{Noentry} eq 'true' ) {
			next COUNTLISTTBLCOL;
		}
		if ($ColType =~ /pkey/ && !defined($DBSchema{$Table}{$colname}->{'IsPK'}) ) {
			next COUNTLISTTBLCOL;
		}
		if ($ColType =~ /attr/ && defined($DBSchema{$Table}{$colname}->{'IsPK'})) {
			next COUNTLISTTBLCOL;
		}
		if ( $ColType =~ /fkey/ && !defined($DBSchema{$Table}{$colname}->{'IsFK'}) ) {
			next COUNTLISTTBLCOL;
		}
		$ColCount++;
	}

	my $ColList = "" ;
	my $ColNum=0;
	my $tblk=0;
	LISTTBLCOL:foreach my $colname (sort { $DBSchema{$Table}{$a}->{'Order'}  <=> $DBSchema{$Table}{$b}->{'Order'}  }keys %{ $DBSchema{$Table} } ) {
		if ( $colname =~ /^$/ ) {
			next LISTTBLCOL;
		}

		if (defined($DBSchema{$Table}{$colname}->{Role}) && $DBSchema{$Table}{$colname}->{Role} !~ /$Role/) {
			next LISTTBLCOL;
		}
		if ( $NoEntry =~ /excl/ && $DBSchema{$Table}{$colname}->{Noentry} eq 'true' ) {
			next LISTTBLCOL;
		}
		if ($ColType =~ /pkey/ && !defined($DBSchema{$Table}{$colname}->{'IsPK'}) ) {
			next LISTTBLCOL;
		}
		if ($ColType =~ /attr/ && defined($DBSchema{$Table}{$colname}->{'IsPK'})) {
			next LISTTBLCOL;
		}
		if ( $ColType =~ /fkey/ && !defined($DBSchema{$Table}{$colname}->{'IsFK'}) ) {
			next LISTTBLCOL;
		}
		
		if ((defined($DBSchema{$Table}{$colname}->{Section}) && $DBSchema{$Table}{$colname}->{Section} !~ /$Section/  ) 
		||  (!defined($DBSchema{$Table}{$colname}->{Section}) && $Section =~ /parent|child/ ) ) {
			if ( defined($DBSchema{$Table}{$colname}->{IsPK}) ) {
				if ( $IncludePKCols == 0 ) {
					next LISTTBLCOL;
				}
			} else {
				next LISTTBLCOL;
			}
		}

		$ColNum++;
		# print all in one line
		# print one line per column
		if (length($Prefix) > 0) {
			$ColList = $Prefix . '.' . $colname ;
		} else {
			$ColList = $colname ;
		}
		$TableColumnsList[$tblk] = $ColList;
		$tblk++;
	} # end foreach
	our $RetFieldsCount=$ColCount;
	return @TableColumnsList ;
} # end list_table_columns

########################################################################################
sub bld_where_clause {
	my ( $MODULE,$TableName,$ColType,$InputRecord,$WriteMode,$Tabul,$ExcludeFields) = ( @_ ) ;
	# table name,(pkey,fkey,attr,all),Input Variable,display flat or split,exclude exp, display max length
	if (!defined($ExcludeFields) ) {
		$ExcludeFields = "#@!xxa%<" ;
	}
	if (!(defined($WriteMode) && $WriteMode eq "flat") ) {
		$ColSep = ",\n" ;
	} else {
		$ColSep = "," ;
	}
	if ( $ColType eq ".*") { 
		$ColType="all";
	}
	my $WhereClause = "";
	my $VarNum=0;
	
	if ( $ColType eq 'pkey' ) {
		my $pkx=0;
		my @PKY_Columns=list_PK_columns($TableName);
		while (defined($PKY_Columns[$pkx])) {
		#foreach my $colname (sort { $DBSchema{$TableName}{$a}->{'Order'}  <=> $DBSchema{$TableName}{$b}->{'Order'}  } keys %{ $DBSchema{$TableName} } ) {
			my $VarName = "" ;
			my $colname=$PKY_Columns[$pkx];
			$VarNum++;
			if ( $InputRecord eq '?' ) {
				$VarName = '?';
				$WhereClause = sprintf "%s%sAND %s = %s\n",$WhereClause,$Tabul,$colname,$VarName;
			} elsif ( length($InputRecord) > 0 ) {
				$VarName = sprintf "%s.%s",$InputRecord,$colname ;
				$WhereClause = sprintf "%s%sAND %s.%s = %s\n",$WhereClause,$Tabul,$TableName,$colname,$VarName;
			}
			$pkx++;
		}
	} elsif ( $ColType =~ /fkey:(\w+)/ ) {
		my $key = sprintf "%s:%s",$TableName,$1;
		if (defined($ForeignKeys{$key})) {
			my @ParentCols=split (/,/,$ForeignKeys{$key}->{'parentColumns'});
			my @ChildCols=split (/,/,$ForeignKeys{$key}->{'childColumns'});
			my $pc=0;
			while (defined($ParentCols[$pc])) {
				$VarNum++;
				if ( $InputRecord eq '?' ) {
					$VarName = '?';
					#$WhereClause = sprintf "%s%sAND %s = %s\n",$WhereClause,$Tabul,$ChildCols[$pc],$VarName;
					$WhereClause = sprintf "%s%sAND %s.%s = %s\n",$WhereClause,$Tabul,$TableName,$ChildCols[$pc],$VarName;
				} elsif ( length($InputRecord) > 0 ) {
					$VarName = sprintf "%s.%s",$InputRecord,$ChildCols[$pc] ;
					#$WhereClause = sprintf "%s%sAND %s = %s\n",$WhereClause,$Tabul,$ChildCols[$pc],$VarName;
					$WhereClause = sprintf "%s%sAND %s.%s = %s\n",$WhereClause,$Tabul,$TableName,$ChildCols[$pc],$VarName;
				}
				$pc++ ;
			}
		}
		$a=1;
	} elsif ( $ColType =~ /fkey/ && $ColType !~ /fkey:(\w+)/) {
			printf STDERR "print_where_clause for fkey, please specify parent columns,%s\n",$TpltLine ;
	}
	$WhereClause =~ s/^\s*AND// ;
	$WhereClause =~ s/\n$// ;
	printf $MODULE "%s",$WhereClause ;
	$OutLineNum += ($WhereClause =~ tr/\n//);
	our $RetFieldsCount=$VarNum;
#
} # end bld_primary_key

sub set_tables_roles {
#even better than guess_tables_roles

	# Scan the tables used in the form
	# Step 1:this foreach determines who is parent of who and who is child of who
	foreach my $tabname ( keys %TablesList  ) {
		if ( $tabname !~  /^formonly$/i) {
			$TablesCount++;
		}
		if (!defined($TablesList{$tabname}->{FieldList})) {
			$a=1;
#			delete ($TablesList{$tabname});
#			next ;
		}
		# Get the section of this table
		my @ThisTableFieldIDs=list_form_fields ($SRCHANDLE,$FormName,$tabname,"","","","","","","","","",1) ;
		if ( defined($FormField->{$FormName}->{$ThisTableFieldIDs[0]}->{ScreenRecord}) ) {
			my $SrName=$FormField->{$FormName}->{$ThisTableFieldIDs[0]}->{ScreenRecord};
			if ( $ScreenRecord{$FormName}->{$SrName}->{Order} == 1 ) {
				$TablesList{$tabname}->{Section} = "child";
				$TablesList{$tabname}->{SectionOrder} = 2;
			} elsif ( $ScreenRecord{$FormName}->{$SrName}->{Order} == 2 ) {
				$TablesList{$tabname}->{SectionOrder} = 3;
			}
		} else {
			$TablesList{$tabname}->{Section} = "parent";
			$TablesList{$tabname}->{SectionOrder} = 1;
		}

		$TablesList{$tabname}->{PrimaryKey} = $PrimaryKeys{$tabname}->{parentColumns};
		foreach my $FKid ( keys %ForeignKeys ) {
			if ( $ForeignKeys{$FKid}->{childTable} eq $tabname ) {
				push ( @{$TablesList{$tabname}->{ChildOf} },$ForeignKeys{$FKid}->{parentTable});
				push ( @{$TablesList{$tabname}->{ChildJoinColumns} },$ForeignKeys{$FKid}->{childColumns});
				push ( @{$TablesList{$tabname}->{ParentJoinColumns} },$ForeignKeys{$FKid}->{parentColumns});
			}
			if ( $ForeignKeys{$FKid}->{parentTable} eq $tabname ) {
				push ( @{$TablesList{$tabname}->{ParentOf} },$ForeignKeys{$FKid}->{childTable});
			}
		}
	}

	# Step 2: Scan the TablesList: look at parent tables and search for a child in a screen array
	#foreach my $key ( sort { $InputEventFields->{$a}->{Order} cmp $InputEventFields->{$b}->{Order} } keys %InputEventFields ) {
	foreach my $tabname ( sort { $TablesList{$b}->{SectionOrder} <=> $TablesList{$a}->{SectionOrder} } keys %TablesList  ) {
		if (defined($TablesList{$tabname}->{ParentOf})) {
			my $idx=0;
			WhileParentOf: while (defined($TablesList{$tabname}->{ParentOf}[$idx])) {
				my $childTable=$TablesList{$tabname}->{ParentOf}[$idx];
				my $SrName=$TablesList{$childTable}->{ScreenRecord};
				if (defined($TablesList{$childTable}->{SectionOrder} )) {
					# $tabname is parent of a table this is in a screen record: that should be a parent child relationship
					if ( $TablesList{$tabname}->{SectionOrder} < $TablesList{$childTable}->{SectionOrder} ) {
						if ($TablesList{$tabname}->{SectionOrder} == 1 ) {
							if (!defined($ParentTable)) {
								our $ParentTable=$tabname;
								$TablesList{$ParentTable}->{Role} = "parent";
							}
							if (!defined($ChildTable)) {
								our $ChildTable=$childTable;
								$TablesList{$ChildTable}->{Role} = "child";
							}
						} elsif ($TablesList{$tabname}->{SectionOrder} == 2 ) {
							if (!defined($GrandChildTable)) {
								our $GrandChildTable=$childTable;
								$TablesList{$GrandChildTable}->{Role} = "grandchild";
								#$TablesList{$GrandChildTable}->{Section} = "grandchild";
							}
							if (!defined($ChildTable)) {
								our $ChildTable=$tabname;
								if ( !defined$TablesList{$ChildTable}->{Role}) {
									$TablesList{$ChildTable}->{Role} = "child";
									#$TablesList{$ChildTable}->{Section} = "child";
								}
							}
						}
					} elsif ( $TablesList{$tabname}->{SectionOrder} == $TablesList{$childTable}->{SectionOrder} ) {
						if ($TablesList{$tabname}->{SectionOrder} == 1 ) {
							$TablesList{$tabname}->{Role} = "lookup" ;
						} elsif ($TablesList{$tabname}->{SectionOrder} == 2 ) {
							$TablesList{$tabname}->{Role} = "lookup" ;
						}

						$a=1; # no screen record
					}
					#last WhileParentOf;
				}
				$idx++;
			}
		}
	}
	$a=1;

	# Step 3 clean the %TablesList useless attributes
	# Not good for prodstatus : not referenced by invoicedetl 
	foreach my $tabname ( sort { $TablesList->{$a}->{SectionOrder} <=> $TablesList->{$b}->{SectionOrder} } keys %TablesList ) {
		# if this record has no elements, means if is not related with our form
		my (@RecordElements)=(keys %{ $TablesList{$tabname} });
		if ($#RecordElements<0) {
			$a=1;
			delete ($TablesList{$tabname}) ;
			next;
		}
		my $idx=0;
		
		while (defined($TablesList{$tabname}->{ChildOf}[$idx])) {
			if ( $TablesList{$tabname}->{ChildOf}[$idx] eq $ParentTable || $TablesList{$tabname}->{ChildOf}[$idx] eq $ChildTable) {
				$a=1;
			} else {
				# move from List of ChildOf to list of ParentLookup Tables
				push ( @{$TablesList{$tabname}->{ParentLookupTables} },$TablesList{$tabname}->{ChildOf}[$idx]);
				splice(@{$TablesList{$tabname}->{ChildOf} },$idx,1);
				push ( @{$TablesList{$tabname}->{ChildLookupCols} },$TablesList{$tabname}->{ChildJoinColumns}[$idx]);
				splice(@{$TablesList{$tabname}->{ChildJoinColumns} },$idx,1);
				push ( @{$TablesList{$tabname}->{ParentLookupCols} },$TablesList{$tabname}->{ParentJoinColumns}[$idx]);
				splice(@{$TablesList{$tabname}->{ParentJoinColumns} },$idx,1);
				$idx-- ;   # one element less in the array
			}
			$idx++;
		}
		if (!defined($TablesList{$tabname}->{ChildOf}[0])) {
			undef ($TablesList{$tabname}->{ChildOf});
		}
		$idx=0;
		while (defined($TablesList{$tabname}->{ParentOf}[$idx])) {
			if ($TablesList{$tabname}->{Role} eq "lookup" ) {
				if ( $TablesList{$tabname}->{ParentOf}[$idx] eq $ParentTable 
				|| $TablesList{$tabname}->{ParentOf}[$idx] eq $ChildTable 
				||  $TablesList{$tabname}->{ParentOf}[$idx] eq $GrandChildTable ) {
					push ( @{$TablesList{$tabname}->{ReferencedBy} },$TablesList{$tabname}->{ParentOf}[$idx]);
					splice(@{$TablesList{$tabname}->{ParentOf} },$idx,1);
					$idx-- ;   # one element less in the array				
				} else {
					# TODO: if table not in form => ParentOfTableNotInForm else ParentofNotChildorGrandChild
						if ( list_form_tables($FormName,$TablesList{$tabname}->{ParentOf}[$idx],"") ) { 
							push ( @{$TablesList{$tabname}->{ParentOfAnotherTable} },$TablesList{$tabname}->{ParentOf}[$idx]);
							splice(@{$TablesList{$tabname}->{ParentOf} },$idx,1);
						} else {
							push ( @{$TablesList{$tabname}->{ParentOfTableNotInForm} },$TablesList{$tabname}->{ParentOf}[$idx]);
							splice(@{$TablesList{$tabname}->{ParentOf} },$idx,1);
						}
					$idx-- ;   # one element less in the array				
					$a=1;
					# referenced by a table not in the form
				}
			} else {
				$a=1;
			}
			$idx++;
		}
		if (!defined($TablesList{$tabname}->{ParentOf}[0])) {
			undef ($TablesList{$tabname}->{ParentOf});
		}
		if (!defined($TablesList{$tabname}->{ChildJoinColumns}[0])) {
			undef ($TablesList{$tabname}->{ChildJoinColumns});
		}
		if (!defined($TablesList{$tabname}->{ParentJoinColumns}[0])) {
			undef ($TablesList{$tabname}->{ParentJoinColumns});
		}
		$a=1;
	}
	$a=1;
	foreach my $tabname ( keys %TablesList  ) {
		if (!defined($TablesList{$tabname}->{Role}) && defined($TablesList{$tabname}->{ReferencedBy})) {
			$TablesList{$tabname}->{Role} = "lookup";
		}
		if ($TablesList{$tabname}->{Role} eq "lookup" ) {
			if (!defined($TablesList{$tabname}->{ReferencedBy})) {
				printf LOGFILE "Table %s is lookup but misses child table name\n",$tabname;
				printf "Error: Table %s is lookup but misses child table name\n",$tabname;
				# TODO: try to build lookup relationship from indexes (guess_lookup_columns)
			}

		}
	}
	$a=1;
	
	# step  4 : compare form tables list and %TablesList

	foreach my $tabname ( keys %TablesList  ) {
		# delete table if it is not neither parent or child or FKlookup
		if ( !defined($TablesList{$tabname}->{ParentOf}) 
		&& !defined($TablesList{$tabname}->{ChildOf}) 
		&& !defined($TablesList{$tabname}->{ReferencedBy}) 
		&& !defined($TablesList{$tabname}->{ParentLookupTables})) {
			my @SectionTablesList=list_form_tables($FormName,$tabname,"");
			if ( !defined($SectionTablesList[0])) {
				# delete this table only if it is not part of the form
				delete $TablesList{$tabname};
				next ;
			} else {
				# last chance, look in unique indexes
				$a=1;
			}
		}
		if ( !defined($TablesList{$tabname}->{Role}) && !defined($TablesList{$tabname}->{ScreenRecord}) ) {
			# means it is not a child,grandchild, parent or lookup =>
			$TablesList{$tabname}->{Role} = "parent";
			$TablesList{$tabname}->{Section} = "parent";
			our $ParentTable=$tabname;
		}
		if ( !defined($TablesList{$tabname}->{Section}) ) {
			if (defined($TablesList{$tabname}->{ScreenRecord})) {
				if ( $TablesList{$tabname}->{ScreenRecordNum} = 1 ) {
					$TablesList{$tabname}->{Section} = "child";
				} elsif ( $TablesList{$tabname}->{ScreenRecordNum} = 2 ) {
					$TablesList{$tabname}->{Section} = "grandchild";
				} else {
					$a=1;
				}
			} else {
				# if No Screen Record, there is only the parent table
				$TablesList{$tabname}->{Section} = "parent";
			}
		}
	}		
	$a=1;

	# Step 5: align primary key and join key columns lists (due to bug in SchemaSpy)
	foreach my $tabname ( keys %TablesList  ) {
		# delete table if it is not neither parent or child or FKlookup
		if ( defined($TablesList{$tabname}->{ChildOf}) ) {
			my $pox=0;
			while(defined($TablesList{$tabname}->{ChildOf}[$pox])) {
				my $parent=$TablesList{$tabname}->{ChildOf}[$pox];
				$TablesList{$parent}->{PrimaryKey}=$TablesList{$tabname}->{ParentJoinColumns}[$pox];
				$pox++;
			}
		}
	}
	$a=1;
	
	# Check if there are Array Screen Records in that form
	$SRCount = keys %{ $ScreenRecord->{$FormName} } ;
	our @ParentPLTables = () ;
	our @ChildPLTables = () ;
	our @GrandChildPLTables = () ;
	$ParentLookupTables = 0 ;
	$ChildLLookupTables = 0 ;
	$GrandChildLLookupTables = 0 ;

	#printf "%s parent of %s\n",$tabname,$1;	
	#printf "%s child of %s\n",$tabname,$1;
	# at the end, reparse table list and check role
	foreach my $tabname ( keys %TablesList ) {
		next if $tabname =~ /formonly/ ;
		$a=1;
		if (defined($TablesList{$tabname}->{ParentLookupTables})) {
			my @LookupTables=@{ $TablesList{$tabname}->{ParentLookupTables}};
			my @UniqueLookup= unique(\@LookupTables) ;
			if ( $TablesList{$tabname}->{Section} eq "parent") {
				$ParentLookupTables = $#UniqueLookup;
			} elsif ( $TablesList{$tabname}->{Section} eq "child") {
					$ChildLookupTables = $#UniqueLookup;
			} elsif ( $TablesList{$tabname}->{Section} eq "grandchild") {
					$GrandChildLookupTables = $#UniqueLookup;
			}
		}
	}
	$a=1;
} # end  set_tables_roles {

sub unique {
	my (@words) = @{$_[0]};
	my @unique;
	my %seen;
	foreach my $value (@words) {
  		if (! $seen{$value}) {
	    	push @unique, $value;
    		$seen{$value} = 1;
  		}
	}
	return @unique ;
}
#########################################################


#########################################################

sub set_pk_values {
	my ($SRCHANDLE,$FormName,$ScreenRecordName,$ChildSRArray,$ChildPkyArray,$ParentTable,$ChildTable,$FKRecordName,$sql_stmt_type) = ( @_ ) ;
	my @PKCols = split(/,/,$PrimaryKeys{$ChildTable}->{parentColumns});
	my $key=sprintf "%s:%s",$ChildTable,$ParentTable;
	my @FKChildCols = split (/,/,$ForeignKeys{$key}->{childColumns});
	my @FKParentCols = split (/,/,$ForeignKeys{$key}->{parentColumns});
	my @ScrFields = list_scrrec_fields($FormName,$ScreenRecordName,$ChildTable,"all",".*","","","","");
	my %PKColValue = ();
	my @ArrPKColValue = () ;
	#my @PKCols = ();
	# search pk col value in the SR array
	my $pkc=0;
	my $pka=0;
	 # ==> check if all the pk columns are in the array, else take the foreign key
	# First check if PK columns are part of the array screen record
	# scan the primary key columns for that table and set its value
	while (defined($PKCols[$pkc])) {
		my $fld=0;
		while (defined($ScrFields[$fld])) {	
			my $colname=$PKCols[$pkc];
			if ( $PKCols[$pkc] eq $ScrFields[$fld] ) {
				# this field is part of the screen record}
				if ($sql_stmt_type eq "insert" ) {
					if ( $DBSchema->{$ChildTable}->{$colname}->{datatype} =~ /SERIAL/i) {
						# this is an insert, serial need to be set to 0 in any case
						$PKColValue{$colname} = 1;
						$ArrPKColValue[$pka++] = sprintf "LET %s[%s].%s = 0",$ChildPkyArray,$ArrCurrVar,$colname;
					} else {
						$PKColValue{$colname} = 1;
						$ArrPKColValue[$pka++] = sprintf "LET %s[%s].%s = %s[%s].%s",$ChildPkyArray,$ArrCurrVar,$colname,$ChildSRArray,$ArrCurrVar,$colname;
					}
				} else {
					$PKColValue{$colname} = 1;
					$ArrPKColValue[$pka++] = sprintf "LET %s[%s].%s = %s[%s].%s",$ChildPkyArray,$ArrCurrVar,$colname,$ChildSRArray,$ArrCurrVar,$colname;
				}
 				$fld=$#PKCols;
				last;
			} else {
				$a=1;
			}
			$fld++;
		}
		$pkc++;
	}
	# recheck: if pkcolvalue not set, assign foreign key column value
	my $pkc=0;
	while (defined($PKCols[$pkc])) {
		my $colname = $PKCols[$pkc] ;
		if (!defined($PKColValue{$colname})) {
			my $fkc=0;
			while(defined($FKChildCols[$fkc] )) {
				if ($FKChildCols[$fkc] eq $PKCols[$pkc] ) {
					$PKColValue{$colname} = 1;
					$ArrPKColValue[$pka++] = sprintf "LET %s[%s].%s = %s.%s",$ChildPkyArray,$ArrCurrVar,$FKChildCols[$fkc],$FKRecordName,$FKChildCols[$fkc];
				}
				$fkc++;
			}
		}
		$pkc++;
	}
	$a=1;
	print_stuff($SRCHANDLE,\@ArrPKColValue,"","","multiline") ;
	# get ChildTable Primary Key columns
	# check if they are in the ChildSRArray
	# if in SRArray, LET PK_array.columns = SRArray.columns
	# else look for column in foreign key
} # end  set_pk_values

sub list_PK_columns {
	my ($table) = ( @_ );
	my @PKCols = split(/,/,$TablesList{$table}->{PrimaryKey});
	return @PKCols;
} # list_PK_Columns

sub define_PK_columns {
	my ($SRCHANDLE,$Table,$Prefix,$DefStyle) = ( @_ );
	$DefStyle //= $DefineStyle;

	# trying to elaborate something on level tables
	if ( $TemplateFile =~ /parent/) {
		$UpperTable=$ParentTable;
		if (defined($ChildTable)) {
			$LowerTable=$ChildTable;
		}
	} elsif ( $TemplateFile =~ /grandchild/) {
		$b=1;
	} elsif ( $TemplateFile =~ /child/) {
		if (defined($GrandChildTable)) {
			$LowerTable=$GrandChildTable;
		}
		$c=1;
	}

	@PKColumnsList=list_PK_columns($Table);

	my $pkl=0;
	my $PKSize=$#PKColumnsList;
	my $tabname=$childTable;
	my $ColSep=',';
	while(defined($PKColumnsList[$pkl])) {
		my $colname=$PKColumnsList[$pkl];
		my $VarDef = "" ;
		if ($DefStyle =~ /like/i) {
			$DefLike=sprintf " LIKE %s.%s,   # ",$Table,$colname;
		} else {
			$DefLike=" ";
		}
			
		my $ColDataType=$DBSchema{$Table}{$colname}->{'datatype'};
		$ColDataType =~ s/serial/integer/;
		$VarDef = $colname . $DefLike . $ColDataType ;
		if ( $VarDef ne "" ) {
			if ( $pkl < $PKSize ) {
				if ( $VarDef !~ /\sLIKE\s/) {
					#$VarDef = sprintf "%s%s\n",$VarDef,$ColSep ;
					$VarDef = sprintf "%s%s",$VarDef,$ColSep ;
				}
				$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_table_columns",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			} else {
				if ( $VarDef =~ /\sLIKE\s/) {
					$VarDef =~ s/,(\s+#)/$1/;
				} else {
					$VarDef = sprintf "%s",$VarDef ;
				}
				$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_table_columns",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1); #,1,0);
			}
		}
		$pkl++;
	}
} # end list_PK_columns

sub define_FK_columns {
	my ($SRCHANDLE,$lowerTable,$upperTable,$Prefix,$DefStyle,$Mode) = ( @_ );
	$DefStyle //= $DefineStyle;
	$Mode //= "lookup" ;  # other possible value "join"

	# trying to elaborate something on level tables
	if ( $TemplateFile =~ /parent/) {
		$UpperTable=$ParentTable;
		if (defined($ChildTable)) {
			$LowerTable=$ChildTable;
		}
	} elsif ( $TemplateFile =~ /grandchild/) {
		$b=1;
	} elsif ( $TemplateFile =~ /child/) {
		if (defined($GrandChildTable)) {
			$LowerTable=$GrandChildTable;
		}
		$c=1;
	}

	my @ColumnsList=list_FK_columns($lowerTable,$upperTable,$Mode);

	my $pkl=0;
	my $PKSize=$#ColumnsList;
	my $tabname="";
	if ( $Mode =~ /parent/) {
		$tabname=$upperTable;
	} else {
		$tabname=$lowerTable;
	}
	
	my $ColSep=',';
	while(defined($ColumnsList[$pkl])) {
		my $colname=$ColumnsList[$pkl];
		my $VarDef = "" ;
		if ($DefStyle =~ /like/i) {
			$DefLike=sprintf " LIKE %s.%s,   # ",$tabname,$colname;
		} else {
			$DefLike=" ";
		}
			
		my $ColDataType=$DBSchema{$Table}{$colname}->{'datatype'};
		$ColDataType =~ s/serial/integer/;
		$VarDef = $colname . $DefLike . $ColDataType ;
		if ( $VarDef ne "" ) {
			if ( $pkl < $PKSize ) {
				if ( $VarDef !~ /\sLIKE\s/) {
					$VarDef = sprintf "%s%s",$VarDef,$ColSep ;
				}
				$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_table_columns",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			} else {
				if ( $VarDef =~ /\sLIKE\s/) {
					$VarDef =~ s/,(\s+#)/$1/;
				} else {
					$VarDef = sprintf "%s",$VarDef ;
				}
				$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_table_columns",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1); #,1,0);
			}
		}
		$pkl++;
	}
} # end define_FK_columns

sub set_pk_values2 {
	my ($SRCHANDLE,$FormName,$ScreenRecordName,$ChildSRArray,$ChildPkyArray,$ParentTable,$ChildTable,$sql_stmt_type) = ( @_ ) ;
	my @PKCols = split(/,/,$PrimaryKeys{$ChildTable}->{parentColumns});
	my $key=sprintf "%s:%s",$ChildTable,$ParentTable;
	my @FKChildCols = split (/,/,$ForeignKeys{$key}->{childColumns});
	my @FKParentCols = split (/,/,$ForeignKeys{$key}->{parentColumns});
	my @ScrFields = list_scrrec_fields($FormName,$ScreenRecordName,$ChildTable,"all",".*","","","","");
	my $fld=0;
	while (defined($ScrFields[$fld])) {
		my $fldname=$ScrFields[$fld];
		if ( $PrimaryKeys{$ChildTable}->{parentColumns} =~ /[\a,]*$fldname[,\z]*/) {
			if ($sql_stmt_type eq "insert" && $DBSchema->{$ChildTable}->{$fldname}->{datatype} =~ /SERIAL/i) {
				printf "LET %s.%s = 0\n",$ChildPkyArray,$fldname;
			} else {
				printf "LET %s.%s = %s[%s].%s",$ChildPkyArray,$fldname,$ChildSRArray,$ArrCurrVar,$fldname;
			}
		} else {
			$a=1;
		}
 		$fld++;
	}
	# get ChildTable Primary Key columns
	# check if they are in the ChildSRArray
	# if in SRArray, LET PK_array.columns = SRArray.columns
	# else look for column in foreign key
	
	
} # end  set_pk_values2 
#########################################################
sub list_FK_columns {
# list the child columns and or the parent columns of an identified foreign key
	my ($childTable,$parentTable,$mode) = ( @_ );
	my @FKs = [];
	my $fkx=0;
	my $keysfound=0;
	my @FK_Columns_List =();
	if ( $mode =~ /join/) {
		while (defined($TablesList{$childTable}->{ChildOf}[$fkx])) {
			if ($TablesList{$childTable}->{ChildOf}[$fkx] eq $parentTable) {
				if ( $mode =~ /joinchild/) {
					@FK_Columns_List=split(/,/,$TablesList{$childTable}->{ChildJoinColumns}[$fkx]);
					$keysfound=1;
				} elsif ( $mode =~ /joinparent/) {
					@FK_Columns_List=split(/,/,$TablesList{$childTable}->{ParentJoinColumns}[$fkx]);
					$keysfound=1;
				} else {
					$a=1; # not found
				}
				last;
			}
			$fkx++;
		}
		if ( $keysfound == 1) {
			return @FK_Columns_List;
		}

	} elsif ( $mode =~ /lookup/) {
		$a=1;
	}
} # end  list_FK_columns

sub define_join_columns {
my ($SRCHANDLE,$childTable,$parentTable,$Prefix,$DefStyle) = ( @_ );
$DefStyle //= $DefineStyle;
my @FKColumnsList=split(/,/,$TablesList{$childTable}->{ChildJoinColumns}[0]);
my $fkl=0;
my $FKSize=$#FKColumnsList;
my $tabname=$childTable;
while(defined($FKColumnsList[$fkl])) {
	my $colname=$FKColumnsList[$fkl];
	my $VarDef = "" ;
	if ($DefStyle =~ /like/i) {
		$DefLike=sprintf " LIKE %s.%s,   # ",$tabname,$colname;
	} else {
		$DefLike=" ";
	}
		
	my $ColDataType=$DBSchema{$tabname}{$colname}->{'datatype'};
	$ColDataType =~ s/serial/integer/;
	$VarDef = $colname . $DefLike . $ColDataType ;
	if ( $VarDef ne "" ) {
		if ( $fkl < $FKSize ) {
			if ( $VarDef !~ /\sLIKE\s/) {
				$VarDef = sprintf "%s%s\n",$VarDef,$ColSep ;
			}
			$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_table_columns",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		} else {
			if ( $VarDef =~ /\sLIKE\s/) {
				$VarDef =~ s/,(\s+#)/$1/;
			} else {
				$VarDef = sprintf "%s\n",$VarDef ;
			}
			$OutLineNum=ffg_print($SRCHANDLE,$VarDef,$OutLineNum,$CurrentFctName,"define_table_columns",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1);
		}
	}
	$fkl++;
}


} # end define_join_columns

sub list_FK_Keys {
my ($tabname,$mode) = ( @_ );
my @FKs = [];
my $fkx=0;
	foreach my $FKid ( keys %ForeignKeys ) {
		#next if ( $mode eq "child" && $FKid !~ /^${tabname}:/ );	# eliminate FK where the parent is not this table
		# next if ($mode eq "parent" && $FKid !~ /:${tabname}$/ );    # eliminate FK where the child is not this table
		next if ( $mode eq "child" && $ForeignKeys{$FKid}->{childTable} ne $tabname );
		next if ($mode eq "parent" && $ForeignKeys{$FKid}->{parentTable} ne $tabname ) ;
		if (defined($TablesList{$ForeignKeys{$FKid}->{childTable}})) {
			my $rec->{childTable}=$ForeignKeys{$FKid}->{childTable};
			$rec->{childColumns}=$ForeignKeys{$FKid}->{childColumns};
			$rec->{parentColumns}=$ForeignKeys{$FKid}->{parentColumns};
			$rec->{parentTable}=$ForeignKeys{$FKid}->{parentTable};
			$FKs[$fkx]=$rec ;
			$fkx++;
		}
	}
	our $RetFieldsCount=$fkx;
	return @FKs ;
} # end  list_FK_Keys

sub list_LU_Keys {
# list loookup keys
my ($tabname) = ( @_ );
#my @LUs = [];
my $LUx=0;
	foreach my $LUid ( keys %LookupKeys ) {
		next if ( $LUid !~ /^${tabname}\:/ );
		if (defined($TablesList{$LookupKeys{$LUid}->{childTable}})) {
			my $rec->{childTable}=$LookupKeys{$LUid}->{childTable};
			$rec->{childColumns}=$LookupKeys{$LUid}->{childColumns};
			$rec->{parentColumns}=$LookupKeys{$LUid}->{parentColumns};
			$rec->{parentTable}=$LookupKeys{$LUid}->{parentTable};
			$LUs[$LUx]=$rec ;
			$LUx++;
		}
	}
	our $RetFieldsCount=$LUx;
	return @LUs ;
} # end  list_LU_Keys

#########################################################
sub list_parent_columns {
my ($tabname,$field,$colnum ) = ( @_ );
our $RetFieldsCount=0;
	foreach my $FKid ( keys %ForeignKeys ) {
		next if ( $FKid !~ /${tabname}:/ );
		if (defined($TablesList{$ForeignKeys->{$FKid}->{'parentTable'}})) {
			$RetFieldsCount++;
			#return join(",",@{ $TablesList->{$ForeignKeys->{$FKid}->{'parentTable'}}->{FieldList} }) ;
			return join(",",@{ $TablesList{$ForeignKeys->{$FKid}->{'parentTable'}}->{FieldList} }) ;
		}
	}
} # end  list_parent_columns

#########################################################
sub get_this_FK {
my ($tabname,$field) = ( @_ );	
	my $idx=0;
	my $ParentLookupTable="";
	my $ChildLookupCols="";
	my $ParentLookupCols="";
	while (defined($TablesList{$tabname}->{ChildLookupCols}[$idx])) {
		if ($TablesList{$tabname}->{ChildLookupCols}[$idx] =~ /\b$field\b/ ) {
			$ChildLookupCols=$TablesList{$tabname}->{ChildLookupCols}[$idx];
			$ParentLookupTable=$TablesList{$tabname}->{ParentLookupTables}[$idx];
			$ParentLookupCols=$TablesList{$tabname}->{ParentLookupCols}[$idx];
			return $ChildLookupCols,$ParentLookupTable,$ParentLookupCols;		
		}
		$idx++;
	}
	return $ChildLookupCols,$ParentLookupTable,$ParentLookupCols;
} # get_this_FK 


sub get_this_FK_old { 
my ($tabname,$field,$colnum ) = ( @_ );
	foreach my $FKid ( keys %ForeignKeys ) {
		# next if ( $FKid !~ /^${tabname}:/ );
		next if ( $ForeignKeys{$FKid}->{'childTable'} ne $tabname) ;
		next if ( $ForeignKeys{$FKid}->{'childColumns'} !~ /\b${field}\b/ ) ;
		my @ChildCols = split (/,/,$ForeignKeys{$FKid}->{'childColumns'});
		my $cdx=0;
		while (defined($ChildCols[$cdx])) {
			if ($ChildCols[$cdx] eq $field ) {
				if ( $field ne $GlobalReferenceKey ) {
					return $FKid;
				} else {
					if ( $#ChildCols == 0 ) {
						return $FKid;
					}
				}
			} else {
				$a=1;
			}
			$cdx++;
		}
	}
	return "" ;
} # end  get_this_FK_old

sub ffg_print_short {
	my ($Line,$LfOrNotLF,$ThisIndentLevel) = ( @_ ) ;
	$LfOrNotLF //= "lf";
	$ThisIndentLevel //= $IndentLevel ;
	$MaxLineLength //= 130 ;
	my ($package, $filename, $line, $CallingSub, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);

	if ( $LfOrNotLF eq "lf" ) {
		$LineNum += ($Line =~ tr/\n//);
		if ( $CodeBlock eq "ptrn_blank" ) {
			$PrintTag=0;
		}
	} else {
		$PrintTag=0;
	}
	my $Tag="";
	my $LineEnd="";

	my $Indent = $IndentChar x $ThisIndentLevel ;

	if ( $LfOrNotLF eq "lf" ) { # there is nothing anymore to print on the line, print tag
		printf $SRCHANDLE "%s%s\n",$Indent,$Line;
		if ( $DEBUGPRINT > 2) { printf LOGFILE "%s%s\t\t%s",$Indent,$Line,$LineEnd ; }
	} else { # more to print, do not print tag
		printf $SRCHANDLE "%s%s",$Indent,$Line;
		if ( $DEBUGPRINT > 2 ) { printf LOGFILE "%s",$Line; }
	}

	return $LineNum ;
} # end  ffg_print_short

sub ffg_print {
	my ($HANDLE,$Line,$LineNum,$CurrentFctName,$CodeBlock,$TmplFile,$OldTmpltLineNum,$SIGNAT,$MoreToPrint,$PrintTag) = ( @_ ) ;
	$MoreToPrint //= 0;
	$PrintTag //= 0;
	$MaxLineLength //= 130 ;
	my ($package, $filename, $line, $CallingSub, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);

	if ( $MoreToPrint == 0 ) {
		#$LineNum += ($Line =~ tr/\n//);
		if ( $CodeBlock eq "ptrn_blank" ) {
			$PrintTag=0;
		}
	} else {
		$PrintTag=0;
	}
	my $Tag="";
	my $LineEnd="";
	if ( $Line =~ /^[\s\t]+$/) {
		$Line =~ s/$&// ;
	}
	
	if ( $CodeBlock ne "ptrn_blank" ) {
		chomp($Line);
	}

	$Line =~ s/\x0D//;
	if ( $TmplFile =~ /\// ) {
		$TmplFile=basename($TmplFile);
	}
	$Line =~ s/([\w,])\s+/$1 /g ;
	if ( $PrintTag == 1 ) {
		#$Tag = sprintf "\t#\@G%05d",$LineNum;
		#my $TagOffset = $MaxLineLength - (length($Line)+length($Tag));
		#$LineEnd = " " x ($TagOffset*$PrintTag) . $Tag . "\n" x $PrintTag;
		$LineEnd = "\n";
	} else {
		$Tag="";
		$LineEnd="";
	}
	$Tag="";
	my $Indent = $IndentChar x $IndentLevel ;
	
	#if ( $PrintTag == 1 ) {
	$BlockName=$Line;
	$BlockName =~ s/^[s\t]+//g;
	$BlockName = substr($BlockName,0,25);
	if ( $MoreToPrint == 0 ) { # there is nothing anymore to print on the line, print tag
		$LineEnd="\n";
		printf $HANDLE "%s%s\t\t%s",$Indent,$Line,$LineEnd ;
		$LineNum++;
	#		printf $HANDLE "%s%s\n",$Indent,$Line;
	#		if ( $DEBUGPRINT > 2) { printf LOGFILE "%s%s\t\t%s",$Indent,$Line,$LineEnd ; }
		printf $SIGNAT "%d\t%s\t%s\t%s\t%s\t%d\n",$LineNum,$CurrentFctName,$BlockName,$CallingSub,$TmplFile,$TmpltLineNum ;
	#	} else { # more to print, do not print tag
	#		printf $HANDLE "%s",$Line;
	#		if ( $DEBUGPRINT > 2 ) { printf LOGFILE "%s",$Line; }
	#	}
	} else {
		printf $HANDLE "%s%s",$Indent,$Line;
		#$LineNum++;
		printf $SIGNAT "%d\t%s\t%s\t%s\t%s\t%d\n",$LineNum,$CurrentFctName,$BlockName,$CallingSub,$TmplFile,$TmpltLineNum-1 ;
	#	if ( $DEBUGPRINT > 2 ) { printf LOGFILE "%s%s",$Indent,$Line; }
	}
	return $LineNum ;
} # end  ffg_print

sub CheckCustomLines {
	my ( $Source,$Signature) = ( @_ ) ;
	open SOURCE,$Source or die "Cannot open source module " . $Source;
	if ( -r ($Signature) ) {
		open SIGNAT,$Signature or die "pas possible ouvrir module signature " . $Signature;
		%SignatureLines = () ;
		while ( my $SignLine = <SIGNAT> ) {
			@Sign =split (/\t/,$SignLine);
			$Tag=$Sign[0];
			$SignatureLines{$Tag}->{Function}=$Sign[1];
			$SignatureLines{$Tag}->{GenMethod}=$Sign[2];
			$SignatureLines{$Tag}->{PatternName}=$Sign[3];
			$SignatureLines{$Tag}->{PatternLine}=$Sign[4];
		}
		close (SIGNAT);
	} else {
		if (-r ($Source)) {	# if source already exists, there must be a signature
          printf STDERR "Signature file %s does not exist, you may lose your custom code",$Signature ;
        } else {
		  open SIGNAT,>$Signature or die "impossible to create signature file " . $Signature;
		}
	}
		
	my $NewCustomLiness = 0 ;
	my $NewCustomLinessCount = 0 ;
	my @NewCustomBlock = () ;
	my $NewCustomBlockCount = 0 ;
	%NewCustomLines = () ;
	READSOURCE: while ( my $Line=<SOURCE> ) {
		next READSOURCE if $Line =~ /^\s*$/ ;
		if ( $Line =~ /\t(#\@G\d{5})/ ) {
			$tag=$1;
			# check for the former lines
			if ( $NewCustomBlockCount > 0 ) {
				printf LOGFILE "Nw block after %s\n", $LastValidTag;
				$NewCustomLiness{$LastValidTag}->{StartAfter} = $LastValidTag;
				$NewCustomLiness{$LastValidTag}->{EndBefore} = $tag;
				$NewCustomLiness{$LastValidTag}->{Block} = [ @CustomBlock ] ;
				$NewCustomBlockCount=0;
				@NewCustomBlock = () ;
			}
			$LastValidTag = $tag;
			next READSOURCE;
		} elsif ( $Line =~ /\t(#@M\d{5})/ ) {
			$ModifiedCustomLinesCount++;
			$ModifiedCustomBlock[$ModifiedCustomBlockCount++] = $Line;
		} elsif ( $Line !~ /^\s*$/ ) {
			$NewCustomLinesCount++;
			$NewCustomBlock[$NewCustomBlockCount++] = $Line;
		}
	}
	close (SOURCE);
	close(SIGNAT);
	return $NewCustomLinesCount ;
} # end CheckNewCustomLiness 

sub bld_lookup_call {
	my ( $InRecord,$LkUpPrefix,$Section,$AfterField,$Mode ) = ( @_ );
	my @parentColumns = split (/,/,$AfterField->{parentColumns});
	my @childColumns = split (/,/,$AfterField->{childColumns});
#	=> Use AfterFieldList
	### $IndentLevel++;
	my $Line = sprintf "IF " ;
	my $ll=0;
	my $LUPRecordName=sprintf "%s%s",${SRLUpPrfx},$AfterField->{parentTable};
	while (defined($childColumns[$ll])) {
		# check if this column is in the form, else we take the global value we assume is declared
		my ( $IsInForm,$ScreenRecord) = (column_is_in_form($childColumns[$ll],$AfterField->{childTable}));
		if ( $IsInForm ne "0") {
			$Line = sprintf "%s%s.%s IS NOT NULL AND ",$Line,$InRecord,$childColumns[$ll];
		} else {
			$Line = sprintf "%s%s.%s IS NOT NULL AND ",$Line,$GlobalReferenceRecord,$childColumns[$ll];
		}
		$ll++;
	}
	$Line =~ s/ AND $/ THEN/;
	$IndentLevel++;
	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
	$IndentLevel++;
	if ( defined($AfterField->{descriptionField}) ) {
		# call lookup function to display description field
		$Line = sprintf "CALL %s_%s_%s(",$SqlLookupFct,$AfterField->{childTable},$AfterField->{parentTable};
	} else {
		# no description field, just check primary key
		if ( $Mode =~ /input/) {
			$Line = sprintf "CALL %s_%s_%s(",$SqlCheckForeignKeyFct,$AfterField->{childTable},$AfterField->{parentTable};
		}
	}
	my $ll=0;
	if ( $Section =~  /child/) {
		$a=1;
	}
	while (defined($childColumns[$ll])) {
		my ( $IsInForm,$ScreenRecord) = (column_is_in_form($childColumns[$ll],$AfterField->{childTable}));
		if ( $IsInForm ne "0") {
			$Line = sprintf "%s%s.%s,",$Line,$InRecord,$childColumns[$ll];
		} else {
			$Line = sprintf "%s%s.%s,",$Line,$GlobalReferenceRecord,$childColumns[$ll];
		}
		$ll++;
	}
	$Line =~ s/,$/)\n/ ;
	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);


	if ( defined($AfterField->{descriptionField}) ) {
		my $Line = "RETURNING lookup_status,";
		#$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		$Line = sprintf "%s%s%s.%s,",$Line,$LkUpPrefix,$AfterField->{parentTable},$AfterField->{descriptionField}	;
		$Line =~ s/,$/\n/ ;
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		my $Line = sprintf "CASE\n";
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		my $Line = sprintf "WHEN lookup_status = 0\n";
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		$IndentLevel++;
	
		my @DescriptionFields = split (/,/,$AfterField->{descriptionField}) ;
		$OutLineNum=ffg_print($SRCHANDLE,"DISPLAY ",$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1); 
		$Line="";
		foreach my $field (@DescriptionFields) {
			$Line = sprintf "%s,%s%s.%s",$Line,$LkUpPrefix,$AfterField->{parentTable},$field;
		}
		$Line =~ s/^,// ;
		$Line =~ s/,$/\n/ ;
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,0);
		$Line = "TO ";
		foreach my $field (@DescriptionFields) {
			$Line = sprintf "%s,%s.%s",$Line,$AfterField->{parentTable},$field;
		}
		$Line =~ s/TO ,/TO / ;
		$Line =~ s/,$/\n/ ;
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,0);

		$IndentLevel--;
		if ($Mode =~ /input/) {
			my $Line = sprintf "WHEN lookup_status = 100\n" ;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel++;
			my $Line = sprintf "ERROR \"$ErrorCode \"\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);

			# Check if the NEXT FIELD name is an input field
			my @KKeys = split (",",$AfterField->{childColumns});
			my $fff=0;
			while (defined($KKeys[$fff]) && $Mode =~ /input/ ) {
				my $key=sprintf "%s:%s",$KKeys[$fff],$AfterField->{childTable};
				($key,$SRName)=column_is_in_form($KKeys[$fff],$AfterField->{childTable}); 
				if (defined($FormField->{$MainFormName}->{$key}) && $FormField->{$MainFormName}->{$key}->{NoEntry} ne 'false') {
					my $Line = sprintf "NEXT FIELD %s\n",$childColumns[$fff];
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$IndentLevel--;
					last;
				}
				$fff++;
			}		
			my $Line = sprintf "WHEN lookup_status < 0\n" ;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel++;
			my $Line = sprintf "ERROR \"$ErrorCode \"\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			# Check if the NEXT FIELD name is an input field
			my @KKeys = split (",",$AfterField->{childColumns});
			my $fff=0;
			while (defined($KKeys[$fff]) && $Mode =~ /input/ ) {
				my $key=sprintf "%s:%s",$KKeys[$fff],$AfterField->{childTable};
				($key,$SRName)=column_is_in_form($KKeys[$fff],$AfterField->{childTable}); 
				if (defined($FormField->{$MainFormName}->{$key}) && $FormField->{$MainFormName}->{$key}->{NoEntry} ne 'false') {
					my $Line = sprintf "NEXT FIELD %s\n",$childColumns[$fff];
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$IndentLevel--;
					last;
				}
				$fff++;
			}
		}
		my $Line = sprintf "END CASE\n";
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
#		$IndentLevel--;
	} else {
		my $Line = "RETURNING fky_exists";
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		my $Line = sprintf "IF fky_exists = 'false' THEN\n";
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		$IndentLevel++;
		my $Line = sprintf "ERROR 'code does not exist, please input again'";
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		$IndentLevel--;
		my $Line = sprintf "END IF\n";
		$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
	}
	$IndentLevel--;
	my $Line="END IF";
	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
	#LF() ;
} # end  bld_lookup_call

# build lookup query functions for the whole template: calls individual function build
sub bld_lookup_functions {
	my ( $Form,$Table,$Section,$Mode ) = ( @_ ) ;
	#my @Fkeys = ( list_FK_Keys($Table),"parent" ) ;
	my $fkx=0;
	my %BuiltFunctions = [];

	foreach my $key ( sort { $InputEventFields->{$a}->{Order} cmp $InputEventFields->{$b}->{Order} } keys %InputEventFields ) {
		if ( $InputEventFields{$key}->{Section} eq $Section ) { 
			#if ($Mode =~ /input/ || defined($InputEventFields{$key}->{descriptionField}) ) {	
			#if (defined($InputEventFields{$key}->{descriptionField}) ) {	
			if ($InputEventFields{$key}->{FKY} == 1) {
				my $FunctionKey=sprintf "%s_%s",$InputEventFields{$key}->{childTable},$InputEventFields{$key}->{parentTable};
				if (!defined($BuiltFunctions{$FunctionKey}) ) {
					bld_lookup_function($Section,$LocalVarPrefix,$InputEventFields{$key},"input");
					$BuiltFunctions{$FunctionKey} = 1;
				}
			}
		}
		$fkx++;
	}


} # end  bld_lookup_functions {

sub bld_lookup_function {
	my ( $Section,$Prefix,$AfterField ) = ( @_ );
	# TODO: do this function with a template
			my @parentColumns = split (/,/,$AfterField->{parentColumns});
			my @childColumns = split (/,/,$AfterField->{childColumns});
			my $functionName = "";
			if ( defined($AfterField->{descriptionField} )) {
				$functionName=sprintf "%s_%s_%s",$SqlLookupFct,$AfterField->{childTable},$AfterField->{parentTable};
			} else {
				$functionName=sprintf "%s_%s_%s",$SqlCheckForeignKeyFct,$AfterField->{childTable},$AfterField->{parentTable};
			}
			printf LOGFILE "    building function %s\n",$functionName;
			my $Line = sprintf "FUNCTION %s(",$functionName;
			my $ll=0;
			my $table = $AfterField->{childTable};
			my @ThisFormLookups = (); ;
			if ( $TablesList{$table}->{Role} eq "parent") {
				#@ThisFormLookups=list_form_fields ($SRCHANDLE,$MainFormName,".*",$AfterField->{parentTable},"all",".*",$Prefix,"","","variable") ;
				@ThisFormLookups=list_form_fields ($SRCHANDLE,$MainFormName,$AfterField->{parentTable},$Section,".*",".*",".*","","","","variable") ;
			} else {
				@ThisFormLookups=list_form_fields ($SRCHANDLE,$MainFormName,$AfterField->{parentTable},$Section,".*",".*",".*","","","","variable") ;
			}
			map s/,$//, @ThisFormLookups;
			#while (defined($childColumns[$ll])) {
			while (defined($parentColumns[$ll])) {
				$Line = sprintf "%s%s%s,",$Line,$Prefix,$parentColumns[$ll];
				$ll++;
			}
			$Line =~ s/,$/)\n/ ;
			$IndentLevel=0;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);

			my $ll=0;
			$IndentLevel++;
			$Line=sprintf "DEFINE fky_exists BOOLEAN";
			ffg_print_short($Line);
			while (defined($parentColumns[$ll])) {
				$Line = sprintf "DEFINE %s%s %s\n",$Prefix,$parentColumns[$ll],$DBSchema{$AfterField->{parentTable}}{$parentColumns[$ll]}->{'datatype'};
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$ll++;
			}
			my $ll=0;
			while (defined($ThisFormLookups[$ll])) {
				# my $Var =$ThisFormLookups[$ll];
				# $Var =~ s/$Prefix// ;
				$key=sprintf "%s:%s",$ThisFormLookups[$ll],$AfterField->{parentTable};
				$Line = sprintf "DEFINE %s%s %s\n",$Prefix,$ThisFormLookups[$ll],$DBSchema{$AfterField->{parentTable}}{$ThisFormLookups[$ll]}->{'datatype'};
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$ll++;
			}

			my $Line = sprintf "WHENEVER SQLERROR CONTINUE\n" ;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $ll=0;
			my $LookupColumns="";
			my $LookupVars="";
			if ( defined($AfterField->{descriptionField} )) {
				while (defined($ThisFormLookups[$ll])) {
					$key=sprintf "%s:%s",$ThisFormLookups[$ll],$AfterField->{parentTable};
					$LookupColumns = sprintf "%s,%s",$LookupColumns,$ThisFormLookups[$ll];
					$ll++;
				}
				$LookupColumns =~ s/^,// ;
			} else {
				$LookupColumns = 'true' ;
				$LookupVars= "fky_exists";
				$Line = "LET fky_exists = 'FALSE'";
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);				
			}

			my $Line = sprintf "SELECT " . $LookupColumns ;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			
			my $ll=0;

			while (defined($ThisFormLookups[$ll])) {
				#$LookupColumns = sprintf "%s,%s",$LookupColumns,$ThisFormLookups[$ll];
				$LookupVars = sprintf "%s,%s%s",$LookupVars,$Prefix,$ThisFormLookups[$ll];
				$ll++;
			}
			$LookupVars =~ s/^,// ;
			my $Line = sprintf "INTO %s\n",$LookupVars ;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$Line = sprintf "FROM %s\n",$AfterField->{parentTable};
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$Line = sprintf "WHERE "; 
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE,1);
			my $ll=0;
			while ( $ll <= $#childColumns ) {
				if ( $ll > 0 ) {
					$Line = "AND ";
				} else {
					$Line = "";
				}
				$Line=sprintf "%s%s = %s%s\n",$Line,$parentColumns[$ll],$Prefix,$childColumns[$ll] ;
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$ll++ ;
			}
			my $Line = sprintf "IF sqlca.sqlcode = 100 THEN\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel++;
			my $ll = 0 ;
			while (defined($ThisFormLookups[$ll])) {
				$Line = sprintf "LET %s%s = NULL\n",$Prefix,$ThisFormLookups[$ll];
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$ll++;
			}
			$IndentLevel--;
			my $Line = sprintf "END IF\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $Line = sprintf "WHENEVER SQLERROR CALL ${ErrorMngmtFunction}\n" ;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $Line = sprintf "RETURN sqlca.sqlcode,%s\n",$LookupVars;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel=0;
			my $Line = sprintf "END FUNCTION\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			LF() ;
} # end  bld_lookup_function 

# set the form record from table record
sub set_form_record {
my ($SRCHANDLE,$Table,$Form,$FormRecordName,$TblRecordName,$ScrRecName) = ( @_ ) ;
 
if (defined($ScrRecName) && $ScrRecName ne "") {
	@ThisFormFields=list_scrrec_fields($Form,$ScrRecName,$ChildTable,"all",".*","","","","");
} else {
	# @ThisFormFields=list_form_fields ($SRCHANDLE,$Form,$Table,".*",".*","true|false",".*","","","",) ;
	@ThisFormFields=list_form_fields  ($SRCHANDLE,$Form,$Table,$Section,".*","false",".*","","","",) ;
	#@ThisFormFields=list_form_fields ($SRCHANDLE,$Form,$Table,$Section,$Role,$NoEntry,$ColType,$InPrefix,"","listkey") ;
}

my $ff=0;
while ( defined($ThisFormFields[$ff]) ) {
	$ThisFormFields[$ff] =~ s/,// ;
	my $Line = sprintf "LET %s.%s = %s.%s\n",$FormRecordName,$ThisFormFields[$ff],$TblRecordName,$ThisFormFields[$ff];
	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_form_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
	$ff++;
}
our $RetFieldsCount=$ff;
} # end  set_form_record 
#

sub set_table_record {
	my ($SRCHANDLE,$Table,$Form,$Section,$FormRecordName,$TblRecordName,$Action,$ScrRecName,$FrgnKeyName) = ( @_ ) ;
	my @ThisTableColumns = ();
	my @ThisFormFields = () ;
	@ThisTableColumns=list_table_columns ($Table,"","","","","") ;

	if (defined($ScrRecName) && $ScrRecName ne "") {
		#@ThisFormFields=list_scrrec_fields($Form,$ScrRecName,$ChildTable,"all",".*","","","","");
		@ThisFormFields=list_form_fields  ($SRCHANDLE,$Form,".*",$Section,".*","false",".*","","","",) ;
	} else {
		#@ThisFormFields=list_form_fields ($SRCHANDLE,$MainFormName,".*",$Table,"all","","","",) ; ( before)
		@ThisFormFields=list_form_fields  ($SRCHANDLE,$Form,".*",$Section,".*","false",".*","","","",) ;
										
	}
	my $ff=0;
	my %AssignedColumns=() ;
	map s/,$//, @ThisFormFields;
	STCCOLS: while ( defined($ThisTableColumns[$ff]) ) {
		$ThisTableColumns[$ff] =~ s/,// ;
		my $ThisColumn = $ThisTableColumns[$ff] ;
		my $key=sprintf "%s:%s",$ThisColumn,$Table;
		# if SERIAL and INSERT : value = 0
		# if PK and UPDATE: skip
		# if field not in form: make a commented LET line 
		my $x=0;
		my ($found,$SRName)=column_is_in_form($ThisTableColumns[$ff],$Table);
		if ( $found ne "0") {
			$ThisFormRecordName=$FormRecordName;
		} else {
			# if parent, best guess is the global reference record, for child and grandchild 99% it is a foreign key column
			if ( $Section eq "parent" ) {
				$ThisFormRecordName=$GlobalReferenceRecord;
			} elsif ( $Section =~ /child/ ) {
				$ThisFormRecordName=$FrgnKeyName;
			} else {
				$a=1; # no clue
			}
		}
		if ($Action eq "I" ) {	# specific case for Insert, all possible values must be there
			if ( $DBSchema{$Table}{$ThisColumn}->{datatype} =~ /SERIAL/i ) {
				if (!defined($AssignedColumns{$ThisColumn})) {
					$Line = sprintf "\tLET %s.%s = 0\n",$TblRecordName,$ThisColumn;
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$AssignedColumns{$ThisColumn} = 1;
				}
			} elsif ( $DBSchema{$ThisColumn}{$ThisColumn}->{IsPK} eq 'true' || $DBSchema{$Table}{$ThisColumn}->{IsUK} eq 'true' ) {
				if (!defined($AssignedColumns{$ThisColumn})) {			
					if ( defined($DBSchema{$Table}{$ThisColumn}->{Section}) && $DBSchema{$Table}{$ThisColumn}->{Section} eq $Section) {
						# i.e this column is in the form in this section
						# Take the value from the form value
						$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,${ThisFormRecordName},$ThisColumn;
					} elsif ( ($Table eq $ChildTable && TemplateFile =~ /\/child/) || ($Table eq $GrandChildTable && TemplateFile =~ /\/grandchild/) ) {   
						$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,"fky",$ThisColumn;
					} else {
						#$Line = sprintf "LET %s.%s = %s%s.%s\n",$TblRecordName,$ThisColumn,$GlobalRecPrefix,$ParentTable,$ThisColumn;
						$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,$ThisFormRecordName,$ThisColumn;
					}
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$AssignedColumns{$ThisColumn} = 1;
				}
			} elsif  ($DBSchema{$Table}{$ThisColumn}->{IsFK} eq 'true' ) {
				if (!defined($AssignedColumns{$ThisColumn})){
					if ( defined($DBSchema{$Table}{$ThisColumn}->{Section}) && $DBSchema{$Table}{$ThisColumn}->{Section} eq $Section) {
						$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,${ThisFormRecordName},$ThisColumn;
					} elsif ( ($Table eq $ChildTable && TemplateFile =~ /\/child/) || ($Table eq $GrandChildTable && TemplateFile =~ /\/grandchild/) ) {   
						$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,"fky",$ThisColumn;
					} else {
						my ( $IsInForm,$ScreenRecord) = (column_is_in_form($childColumns[$ll],$fkey->{childTable}));
						if ( $IsInForm ne "0") {
							# $Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,$ThisFormRecordName,$ParentTable,$ThisColumn;
						} else {
							$Line = sprintf "-- LET %s.%s = YOUR VALUE\n",$TblRecordName,$ThisColumn;
						}
					}
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$AssignedColumns{$ThisColumn} = 1;
				}
			} else {
				if ( defined($DBSchema{$Table}{$ThisColumn}->{Section}) && $DBSchema{$Table}{$ThisColumn}->{Section} eq $Section) {
					$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,${ThisFormRecordName},$ThisColumn;
				} else {
					$Line = sprintf "-- LET %s.%s = YOUR VALUE\n",$TblRecordName,$ThisColumn,${ThisFormRecordName},$ThisColumn;
				}
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$AssignedColumns{$ThisColumn} = 1;
			}
		} elsif ( $Action eq "U" ) {
			if ( $DBSchema{$Table}{$ThisColumn}->{datatype} =~ /SERIAL/i ) {
				$a=1;  # skip
			} elsif ( $DBSchema{$Table}{$ThisColumn}->{IsPK} eq 'true' || $DBSchema{$Table}{$ThisColumn}->{IsUK} eq 'true' ) {
				$a=1;	# skip
			#} elsif  ($DBSchema{$Table}{$ThisColumn}->{IsFK} eq 'true' ) {
			#	$a=1;	# skip
			} else {
				if ( defined($DBSchema{$Table}{$ThisColumn}->{Section}) && $DBSchema{$Table}{$ThisColumn}->{Section} eq $Section) {
					$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,${ThisFormRecordName},$ThisColumn;
				} else {
					$Line = sprintf "-- LET %s.%s = YOUR VALUE\n",$TblRecordName,$ThisColumn,${ThisFormRecordName},$ThisColumn;
				}
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$AssignedColumns{$ThisColumn} = 1;
			}
		}
		$ff++;
		next STCCOLS;
		#Reviser la politique de valorisation du record 'table' probablement supprimer le cas général if found et l'utiliser dans chaque cas
		#if (defined($FormField->{$Form}->{$key})) {
		##if ( $found == 1) {
		if ( $DBSchema{$Table}{$ThisColumn}->{datatype} =~ /SERIAL/i ) {
			if (!defined($AssignedColumns{$ThisColumn})) {
				$Line = sprintf "IF sql_stmt_type = 'I' THEN\n";
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$Line = sprintf "\tLET %s.%s = 0\n",$TblRecordName,$ThisColumn;
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$Line = sprintf "END IF\n";
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$AssignedColumns{$ThisColumn} = 1;
			}
		} elsif ( $DBSchema{$Table}{$ThisColumn}->{IsPK} eq 'true' 
		|| $DBSchema{$Table}{$ThisColumn}->{IsUK} eq 'true' ) { 
			#if ( $ff > 0 && $DBSchema{$Table}{$ThisTableColumns[$ff-1]}->{IsPK} ne 'true' && $DBSchema{$Table}{$ThisTableColumns[$ff-1]}->{IsUK} ne 'true' ) {
			#	$Line = sprintf "IF sql_stmt_type  = 1 THEN\n";
			#	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			#}
			#if ( column_is_in_form($ThisColumn,$Table)) {
			
			if ( column_is_entry($ThisColumn,$Table)) {
				if (!defined($AssignedColumns{$ThisColumn})) {
					$Line = sprintf "IF sql_stmt_type  = 'I' THEN\n";
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,${ThisFormRecordName},$ThisColumn;
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$AssignedColumns{$ThisColumn} = 1;
					$Line = sprintf "END IF";
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				}
			} else {
				if (!defined($AssignedColumns{$ThisColumn})) {
					$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,"pky",$ThisColumn;
					$AssignedColumns{$ThisColumn} = 1;
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				}
			}
			#$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			#if ( $ff < $#ThisTableColumns && $DBSchema{$Table}{$ThisTableColumns[$ff+1]}->{IsPK} ne 'true' && $DBSchema{$Table}{$ThisTableColumns[$ff+1]}->{IsUK} ne 'true' ) {
			#	$Line = sprintf "END IF\n";
			#	$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			#}
		} elsif  ($DBSchema{$Table}{$ThisColumn}->{IsFK} eq 'true' ) {
			if ( column_is_entry($ThisColumn,$Table)) {
				if (!defined($AssignedColumns{$ThisColumn})){
					$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,${ThisFormRecordName},$ThisColumn;
					$AssignedColumns{$ThisColumn} = 1;
				}
			} else {
				if (!defined($AssignedColumns{$ThisColumn})) {
					$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,"fky",$ThisColumn;
					$AssignedColumns{$ThisColumn} = 1;
				}
			}
		} elsif ($found ne "0" ) {
			if (!defined($AssignedColumns{$ThisColumn})) {
				$Line = sprintf "LET %s.%s = %s.%s\n",$TblRecordName,$ThisColumn,${ThisFormRecordName},$ThisColumn;
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$AssignedColumns{$ThisColumn} = 1;
			}
		} else {
			if (!defined($AssignedColumns{$ThisColumn})) {
				$Line = sprintf "# LET %s.%s = your value %s\n",$TblRecordName,$ThisColumn,$Warning;
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$AssignedColumns{$ThisColumn} = 1;
			}
		}
		
		my $FKKey=sprintf "%s:%s",$Table,$ParentTable;
		if ($ForeignKeys{$FKKey}->{childColumns} =~ /$ThisColumn/) {
			# Set a value to the foreign key
			if (!defined($AssignedColumns{$ThisColumn})) {
				$Line = sprintf "LET %s.%s = fky.%s\n",$TblRecordName,$ThisColumn,$ThisColumn;
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"set_table_record",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
				$AssignedColumns{$ThisColumn} = 1;
			}
		} else {
			my $Warning="";
			if ( defined($DBSchema{$Table}{$ThisColumn}->{NotNull}) && $DBSchema{$Table}{$ThisColumn}->{NotNull} eq 'true' ) {
				$Warning="(Warning: this column needs a NOT NULL value, may give an ERROR at runtime!)";
			} else {
				$Warning="";
			}
		}
		$ff++;
	}
	our $RetFieldsCount=$ff;
} # end  set_table_record 

# set the table record OLD from form record
sub bld_lookup_calls {
( my $Form,$Section,$Table,$Record,$Mode ) = ( @_ ) ;
		if ( $Record =~ /^\s*$/) {
			$Record=$MstInpFormRec;
		}
		#=> $Record is bult from the table name
		my $fkx=0;

		foreach my $key ( sort { $InputEventFields->{$a}->{Order} cmp $InputEventFields->{$b}->{Order} } keys %InputEventFields ) {
			if (defined($InputEventFields{$key}->{descriptionField}) ) {
				if (!defined($InputEventFields{$key}->{ScreenRecord})) {
					bld_lookup_call($Record,${SRLUpPrfx},$Section,$InputEventFields{$key},$Mode);
				} else {
					bld_lookup_call($Record,$ChildSRArray."[$ArrCurr}",$Section,$InputEventFields{$key},$Mode);
				}
			} else {
				if ($Mode eq "input") {
					# this will call the primary key exists function. Must not be called in display mode
					if (!defined($InputEventFields{$key}->{ScreenRecord})) {
						bld_lookup_call($Record,${SRLUpPrfx},$Section,$InputEventFields{$key},$Mode);
					} else {
						my $Record = ${LocalVarPrefix} . ${ChildSRArray};
						bld_lookup_call($Record,$Record ."[$ArrCurr}",$Section,$InputEventFields{$key},$Mode);
					}
				}
			}
			$fkx++;
		}
		our $RetFieldsCount=$fkx;
		if ( $RetFieldsCount == 0 ) {
			printf LOGFILE "Error: in form %s, Section %s there are no foreign keys available to build lookup statemnts\n",$Form,$Section;
			printf "Error: in form %s, Section %s there are no foreign keys available to build lookup statemnts\n",$Form,$Section;
			
		}
} # end  bld_lookup_calls


# 
# this sub generate the call of all the individual picklist calls with comboboxes
sub bld_picklist_calls {
( my $Table, $Mode ) = ( @_ ) ;
		my @Fkeys = ( list_FK_Keys($Table,"parent") ) ;
		if ( $#Fkeys > -1 ) {
			my $fkx=0;
			while ( defined($Fkeys[$fkx]) ) {
				my $ParentTable = $Fkeys[$fkx]->{parentTable} ;
				if ( $TablesList{$Table}->{'Role'} eq "child" &&  $TablesList{$ParentTable}->{'Role'} eq "parent"
				|| $TablesList{$Table}{'Role'} eq "grandchild" &&  $TablesList{$ParentTable}->{'Role'} eq "child" ) {
					$fkx++;
					next;
				}
				my $FormFile = sprintf "%s/%s%s.fm2",$QxPerLocation,$PLWPrefix,$Fkeys[$fkx]->{parentTable};
				if ( -r ($FormFile)) {
					my $Line = sprintf "ON KEY (%s)\n",$PickListKey;
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"picklist_calls",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					$IndentLevel++;
					my $Line = "CASE\n";
					$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"picklist_calls",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
					last;
				} else {
					printf LOGFILE "Cannot build picklist call for %s: form %s does not exist!\n",$Fkeys[$fkx]->{parentTable},basename($FormFile);
				}
				$fkx++
			}
			my $fkx=0;
			my $PickListCount=0;
			while ( defined($Fkeys[$fkx]) ) {
				my $ParentTable = $Fkeys[$fkx]->{parentTable} ;
				if ( $TablesList{$Table}->{'Role'} eq "child" &&  $TablesList{$ParentTable}->{'Role'} eq "parent"
				|| $TablesList{$Table}->{'Role'} eq "grandchild" &&  $TablesList{$ParentTable}->{'Role'} eq "child" ) {
					$fkx++;
					next;
				}
				my $FormFile = sprintf "%s/%s%s.fm2",$QxPerLocation,$PLWPrefix,$Fkeys[$fkx]->{parentTable};
				if ( -r ($FormFile)) {
					$PickListCount++;
					my @childColumns = split (/,/,$Fkeys[$fkx]->{childColumns});
					my $LastChildColumn= $childColumns[$#childColumns];
					bld_picklist_call($MstInpFormRec,$MstLkUpRec,$Fkeys[$fkx]);
					$IndentLevel--;
				}
				$fkx++;
			}	
			if ( $PickListCount > 0 ) {
				my $Line = "END CASE\n";
				$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"picklist_calls",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			}
		}
} # end  bld_picklist_calls

sub bld_picklist_call {
	my ( $MstPrefix,$LkUpPrefix,$fkey,$Mode ) = ( @_ );
			my @parentColumns = split (/,/,$fkey->{parentColumns});
			my @childColumns = split (/,/,$fkey->{childColumns});
			$IndentLevel++;
			#my $Line = sprintf "WHEN infield(%s)\n",$fkey->{parentColumns};
			my $Line = sprintf "WHEN infield(%s)\n",$childColumns[$#childColumns];
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"call_picklist",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel++;
			my $Line = sprintf "CALL picklist_%s(${xposition},${yposition})\n",$fkey->{parentTable};
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"call_picklist",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $Line = sprintf "RETURNING row_count,";
			my $ll=0;
			while ( defined($childColumns[$ll]) ) {
				$Line = sprintf "%s%s.%s,",$Line,$MstPrefix,$childColumns[$ll];
				$ll++;
			}
			$Line =~ s/,$//;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"call_picklist",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $Line = sprintf "CASE\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $Line = sprintf "WHEN row_count > 0\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel++;
			my $Line = sprintf "DISPLAY BY NAME ";
			my $ll=0;
			while ( defined($childColumns[$ll]) ) {
				$Line = sprintf "%s%s.%s,",$Line,$MstPrefix,$childColumns[$ll];
				$ll++;
			}
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			#print_form_fields ($SRCHANDLE,$MainForm,$fkey->{parentTable},"all","true|false",$MstLkUpRec) ;
			#print_form_fields ($SRCHANDLE,$MainFormName,$Section,$fkey->{parentTable},".*","true|false",$MstLkUpRec) ;
			print_form_fields ($SRCHANDLE,$MainFormName,$fkey->{parentTable},$Section,".*","true|false",".*",${SRLUpPrfx}."TblName");
			#LF() ;
			$IndentLevel--;
			my $Line = sprintf "WHEN row_count < 0\n" ;
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel++;
			my $Line = sprintf "ERROR \"$ErrorCode \"\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			my $Line = sprintf "NEXT FIELD %s\n",$childColumns[0];
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel--;
			my $Line = sprintf "END CASE\n";
			$OutLineNum=ffg_print($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_input_events",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
			$IndentLevel--;
			#LF() ;
} # end  bld_picklist_call 

sub bld_lookup_picklist_windows {
	my ( $Module ) = ( @_ );
	my $plw=0;
	my $plwdone=0;
	while (defined($ParentPLTables[$plw])) {
		my $FormName = sprintf "%s%s",$PLWPrefix,$ParentPLTables[$plw] ;
		my $FormFile = sprintf "%s/%s.fm2",$QxPerLocation,$FormName;
		
		if ( -r ($FormFile) ) {
			our $PLTable = $ParentPLTables[$plw] ;
			if ( $plwdone == 0 ) {
				generate_module($Module,">","$FFGDIR/templates/picklist_with_qbe.mtplt",$FormFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
			} else {
				generate_module($Module,">>","$FFGDIR/templates/picklist_with_qbe.mtplt",$FormFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
			}
			$plwdone++;
		}
		$plw++;
	}
} # end  bld_lookup_picklist_windows 


sub bld_additional_module {
	my ( $Module,$Form,$Template ) = ( @_ );
	my $plw=0;
	my $plwdone=0;
	my $TemplateFile = sprintf "%s/templates/module/%s",$FFGDIR,$Template;
	&generate_module($Module,">",$TemplateFile,$Form,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
	
} # end  bld_additional_module 

sub bld_main_moduleX {
	my ( $Module,$Form,$Template ) = ( @_ );
	my $plw=0;
	my $plwdone=0;
	my $TemplateFile = sprintf "%s/templates/module/%s",$FFGDIR,$Template;
	generate_module($Module,">",$TemplateFile,$Form,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
	
} # end  bld_main_module 

sub bld_form_widgets {
	my ( $FORM, $Table, $ArrayElements,$NoPrint) = ( @_ );
		my $col=$row=0;
	my $y=$z=0;
	my $DataType="";
	my $MaxLength="";
	if (!defined($ArrayElements)) {
		$ArrayElements = 1;
	} else {
		$ScreenRecordName=sprintf "%s%s",$ScreenRecordPrefix,$Table;
	}
	$DataEquivPtr = set_LyciaFieldDefs();
	if ( $FormType =~ /CoordPanel/) {
		# 1: count columns to organize the space
	}
	my $fld=1;
	#my %ScreenRecord = () ;
	my @Fields = ();
	my %FormSchema = ();
	my $FormpreferredSize="";
	my $FormDataType="";
	my $row=0;
	my $col=0;
	my $order=0;
	#our $FormWidth=0;
	my $FormWidth=0;
	my $FormHeight=0;
	$FormWidth = 10;
	$FieldWidth = 10;
	#$row=$StdRowStart+2;
	$row=$StdRowStart+1;
	if ( $ArrayElements > 1 ) {	
		#$col=$StdColStart;
		$col=0;
		$FormWidth=0;
		$FormHeight=0;
		$FieldsNum=0;
	}
	RCOLS1: foreach my $colname (sort { $DBSchema{$Table}{$a}->{'Order'}  <=> $DBSchema{$Table}{$b}->{'Order'}  } keys %{ $DBSchema{$Table} } ) {
		if (defined ($ExcludeFields) && $colname =~ /$ExcludeFields/) {
			next RCOLS1;
		}
		if (defined ($IncludeFields) && $colname !~ /$IncludeFields/) {
			next RCOLS1;
		}
		$FormSchema{$colname} = $DBSchema{$Table}{$colname};
		$FormSchema{$colname}->{TabName}=$Table;
		#$FormSchema{$colname}->{Order}=$order++;
		$FormSchema{$colname}->{LabelSize}=length($colname);
		
		( $FormSchema{$colname}->{GenericDataType}, $FormSchema{$colname}->{FieldSize}) = CvtDTIfmx_Lycia(\$FormSchema{$colname}) ;
		if ( defined($PreviousField)) {
			$FormSchema{$colname}->{PreviousField}=$PreviousField ;
		}
		if ( $ArrayElements > 1 && !defined($NoPrint)) {
			if ( $FormPanel =~ /CoordPanel/) {
				printf $FORM "%s<Label text=\"%s\" location=\"%dqch,%dqch\" preferredSize=\"%dqch,%dqch\" fieldTable=\"\" identifier=\"%s%s\"/>\n",
				$Indent,$colname,$col,$row,$FormSchema{$colname}->{FieldSize}+1,1,$FormLabelPrefix,$colname;
				$col += $FormSchema{$colname}->{FieldSize}+1;
			} elsif ($FormPanel =~ /GridPanel/) {
				printf $FORM "%s<Label isDynamic=\"true\" text=\"%s\" classNames=\"%s\" visible=\"true\" gridItemLocation=\"%d,%d,%d,%d\" fieldTable=\"%s\" identifier=\"%s%s\"/>\n",
				$Indent,$colname,$FormClassName,$col,$row,1,1,$Table,$FormLabelPrefix,$colname;
				$col++;
			}
		}
		if ( $ArrayElements > 1) {
			$FormWidth += $FormSchema{$colname}->{FieldSize}+1;
			$FormHeight = $ArrayElements + $StdRowStart + 2 ;
			$FieldsNum++ ;
		} else {
			$LabelWidth = length($colname) > $LabelWidth ? length($colname)  : $LabelWidth ;
			if ( $FormSchema{$colname}->{datatype} =~ /char\s*\((\d+)\)/i ) {
				my $colsize=$1;
				$FormWidth = $colsize > $FormWidth ? $colsize  : $FormWidth ;
				$FieldWidth = $colsize > $FieldWidth ? $colsize  : $FieldWidth ;
			} else {
			}
			$FormHeight++;
		}
		
		if ($ArrayElements == 1 && !defined($FormSchema{$colname}->{IsFK})) {
			$FormWidth = length ($colname) + $FormSchema{$colname}->{FieldSize} + 2 > $FormWidth ? $FormSchema{$colname}->{FieldSize} + length ($colname) + 2 : $FormWidth ;
		}
		if ( defined($FormSchema{$colname}->{IsFK}) && defined($DoFormLookup) ) {
			# this column is a FK and we want to display the lookup value
			# search for the foreign key for this column
			undef($PreviousField);
			my $FKId=get_this_FK ($Table,$colname,$colnum );
			if ( $FKId ne "") {
				my $parentTable=$ForeignKeys{$FKId}->{parentTable};
				$parentColumn =~ s/^.*,//;
				my $parentcol=""; 
				# Look for first attribute column ( i.e a char longer than 10)
				PARENTCOL: foreach $parentcol (sort { $DBSchema{$parentTable}{$a}->{'Order'}  <=> $DBSchema{$parentTable}{$b}->{'Order'}  }keys %{ $DBSchema{$parentTable} } ) {
					if ( defined($DBSchema{$parentTable}{$parentcol}->{'IsPK'}) ||
					defined($DBSchema{$parentTable}{$parentcol}->{'IsFK'})  ||
					$DBSchema{$parentTable}{$parentcol}->{datatype} !~ /char\((\d+)\)/i ) {
						next PARENTCOL;
					}
					if ( $parentcol =~ /$MainAttributeExpression/) {
						if ($DBSchema{$parentTable}{$parentcol}->{datatype} =~ /char\s*\((\d+)\s*\)/i ) {
							if ( $1 > 10) {
								$FormSchema{$colname}->{parentAttribute}=$parentcol;
								$FieldsNum++;
								last PARENTCOL;
							}
						}
					}
				} 

				$FormSchema{$colname}->{parentTable} = $parentTable;
				if ( $ArrayElements > 1 && !defined($NoPrint)) {
					if ( $FormPanel =~ /CoordPanel/) {
						printf $FORM "%s<Label text=\"%s\" location=\"%dqch,%dqch\" preferredSize=\"%dqch,%dqch\" fieldTable=\"\" identifier=\"%s%s\"/>\n",
						$Indent,$parentColumn,$col,$row,$FormSchema{$parentColumn}->{FieldSize}+1,1,$FormLabelPrefix,$parentColumn;
						$col += $FormSchema{$parentColumn}->{FieldSize}+1;
					} elsif ($FormPanel =~ /GridPanel/) {
						printf $FORM "%s<Label isDynamic=\"true\" text=\"%s\" classNames=\"%s\" visible=\"true\" gridItemLocation=\"%d,%d,%d,%d\" fieldTable=\"%s\" identifier=\"%s%s\"/>\n",
						$Indent,$parentColumn,$FormClassName,$col,$row,1,1,$Table,$FormLabelPrefix,$parentColumn;
						$col++;
					}
				}
				$PreviousField=$parentColumn;
				if ( $ArrayElements > 1) {
					$FormWidth += $FormSchema{$parentColumn}->{FieldSize}+1;
				} else {
				 	###!!! Caution this line causes adding a blank element in %FormSchema
					#$FormWidth = length ($colname) + $FormSchema{$colname}->{FieldSize} + $FormSchema{$parentColumn}->{FieldSize} + 3 > $FormWidth ? length ($colname) + $FormSchema{$colname}->{FieldSize} + $FormSchema{$parentColumn}->{FieldSize} + 3 : $FormWidth ;
					#$FormWidth = length ($colname) + $FormSchema{$col
					#name}->{FieldSize} + $FormSchema{$parentColumn}->{FieldSize} + 3 ; 
					$a=1;
				}
			}
		} # end search for FK parent attribute
		
		if (!defined($PreviousField)) {
			$PreviousField=$colname;	
		}
		
	} # end foreach
	if ( $ArrayElements == 1) {
		$FormHeight = $FormHeight+ $StdRowStart;
	} 
	$a=1;
	if (defined($NoPrint)) {
		return $FormWidth,$FormHeight,$FieldsNum,$LabelWidth,$FieldWidth;
	}
	
	if ( $ArrayElements == 1 ) {	
		my $col=$StdColStart;
		my $row=$StdRowStart;
	} else {
		$row++;
		$col=0;
	}
	if (defined($StdFormTitle) && $ArrayElements == 1 ) {
			$LabelLength=length($StdFormTitle);
			if ( $FormPanel =~ /CoordPanel/ ) { 
				#printf $FORM "%s<Label text=\"%s\" location=\"%dqch,%dqch\" preferredSize=\"%dqch,%dqch\" fieldTable=\"\" identifier=\"%s\"/>\n",
				#$Indent,$StdFormTitle . $Table,5,1,$LabelLength,1,"FormTitle";
				#$row++;
			} elsif ( $FormPanel =~ /GridPanel/) {
				#printf $FORM "%s<Label isDynamic=\"true\" text=\"%s\" visible=\"true\" gridItemLocation=\"%d,%d,%d,%d\" fieldTable=\"\" identifier=\"%s%s\"/>\n",
				#$Indent,$StdFormTitle . $Table,$col,$row,1,1,"FormTitle";
				#$row++;
			}	
	} elsif (defined($ArrayFormTitle) && $ArrayElements > 1 ) {
			$LabelLength=length($StdFormTitle);
	}
	# Now print
	my $ArrayNum=1;
	if ( $ArrayElements == 1 ) {
		$OnePerRow=1;
	} else {
		$OnePerRow=0;
	}
	while ( $ArrayNum <= $ArrayElements) {
		if ($ArrayElements > 1 ) {
			if ($FormPanel =~ /Grid/ ) {
				$col=0;
			} else {
				$col = $StdColStart;
			}
		} else {
			if (FormPanel =~ /Grid/ ) {
				$col=0;
			} else {
				$col = $StdColStart;
			}
		}
		# scan the fields list and print one row per field
		COLSCAN: foreach my $colname (sort { $FormSchema{$a}->{'Order'}  <=> $FormSchema{$b}->{'Order'}  } keys %FormSchema ) {
			#if ( $ColDataType =~ /(\w*CHAR|MONEY|DECIMAL)\((\d+)\)/) {
			
			#$ScreenRecord{$tabname}[$fld++]=$colname ;
			next COLSCAN if ( colname =~ /^\s*$/) ;   # watch out the is a blank FormSchema element hidden!
			
			if ( $ArrayElements > 1) {
				$Row = $row;  # one while loop on the same row
				$Col = $push ; # put all fields on after the other
			}
			
			if ( $FormPanel =~ /CoordPanel/) {
 				my $Indent = $IndentChar x $IndentLevel ;
				if (!defined($FormSchema{$colname}->{IsLookup}) && $ArrayElements == 1 ) {
					printf $FORM "%s<Label text=\"%s\" location=\"%dqch,%dqch\" preferredSize=\"%dqch,%dqch\" fieldTable=\"\" identifier=\"%s%s\"/>\n",
					$Indent,$colname,$col,$row,$FormSchema{$colname}->{LabelSize},1,$FormLabelPrefix,$colname;
					$col += $FormSchema{$colname}->{LabelSize}+1;
					$NoEntryValue="";
				} elsif ( defined($FormSchema{$colname}->{IsLookup})){
					$NoEntryValue=sprintf "noEntry=\"true\"";
				}
				#
				printf $FORM "%s<TextField %s visible=\"true\" location=\"%dqch,%dqch\" preferredSize=\"%dqch,1qch\" fieldTable=\"%s\" identifier=\"%s\"",
				$Indent,$NoEntryValue,$col,$row,$FormSchema{$colname}->{FieldSize},$FormSchema{$colname}->{TabName},$colname;
				
				if (defined($FormClassName)) {
					printf $FORM " classNames=\"%s\"/>\n",$FormClassName;
				} else {
					printf $FORM "/>\n";
				}
				if ( defined($FormSchema{$colname}->{IsFK}) && defined($DoFormLookup) ) {
					$col += $FormSchema{$colname}->{FieldSize}+1;
				} elsif ( $ArrayElements > 1) {
					$col += $FormSchema{$colname}->{FieldSize}+1;
				} else {
					$col = $StdColStart;
					$row++;
				}
			} elsif ( $FormPanel =~ /GridPanel/) {
				my $Indent = $IndentChar x $IndentLevel ;
				
				if (!defined($%{$colname}->{IsLookup}) && $ArrayElements == 1 ) {
					$col=0;
					printf $FORM "%s<Label isDynamic=\"true\" text=\"%s\" classNames=\"%s\" visible=\"true\" gridItemLocation=\"%d,%d,%d,%d\" fieldTable=\"%s\" identifier=\"%s%s\"/>\n",
					$Indent,$colname,$FormClassName,$col,$row,1,1,$Table,$FormLabelPrefix,$colname;
					$col ++ ;
					$NoEntryValue="";
				#
				} elsif ($ArrayElements > 1 ) {
					#printf $FORM "%s<Label isDynamic=\"true\" text=\"%s\" classNames=\"%s\" visible=\"true\" gridItemLocation=\"%d,%d,%d,%d\" fieldTable=\"%s\" identifier=\"%s%s\"/>\n",
					#$Indent,$colname,$FormClassName,$col,$row,1,1,$Table,$LabelPrefix,$colname;
					#$col++;
				} elsif ( defined($FormSchema{$colname}->{IsLookup})){
					$NoEntryValue=sprintf "noEntry=\"true\"";
				}
				printf $FORM "%s<TextField visible=\"true\" %s identifier=\"%s\" gridItemLocation=\"%d,%d,%d,%d\" fieldTable=\"%s\"",
				$Indent,$NoEntryValue,$colname,$col,$row,1,1,$FormSchema{$colname}->{TabName};
				if (defined($FormClassName)) {
					printf $FORM " classNames=\"%s\"/>\n",$FormClassName;
				} else {
					printf $FORM "/>\n"; 
				}
				if ( defined($FormSchema{$colname}->{parentAttribute}) && defined($DoFormLookup) ) {
					$col ++;
					printf $FORM "%s<TextField visible=\"true\" noEntry=\"true\" identifier=\"%s\" gridItemLocation=\"%d,%d,%d,%d\" fieldTable=\"%s\"",
					$Indent,$FormSchema{$colname}->{parentAttribute},$col,$row,1,1,$FormSchema{$colname}->{parentTable};
					if (defined($FormClassName)) {
						printf $FORM " classNames=\"%s\"/>\n",$FormClassName;
					} else {
						printf $FORM "/>\n"; 
					}
					$row++;
				} elsif ( $ArrayElements > 1) {
					$col ++ ;
				} else {
					$col = $StdColStart;
					$row++;
				}
			}
			$a=1;
			if ( $ArrayNum == 1) {
				my $Table=$FormSchema{$colname}->{TabName};
				if ($colname !~ /^\s*$/ ) {
					# main table screenrecord
					$ScreenRecord{$Table}[$fld{$Table}]=$colname ;
					$fld{$Table}++ ;
				}
				if ( defined($FormSchema{$colname}->{parentAttribute})) {
					# LOOKUP TABLE SCREENRECORD
					my $parentTable=$FormSchema{$colname}->{parentTable};
					my $parentAttribute=$FormSchema{$colname}->{parentAttribute};
					$ScreenRecord{$parentTable}[$fld{$parentTable}]=$parentAttribute ;
					$fld{$parentTable}++;
				}
				if ( $ArrayElements > 1) {
					$ScreenRecord{$ScreenRecordName}[$fld{$ScreenRecordName}++]=$colname ;
				}
			}
		}
		$ArrayNum++;
		$row++ ;
	}
	$a=1;

} # end bld_form_widgets

sub bld_form_screenrecords {
	my ( $FORM  ) = ( @_ );
	foreach my $Table ( keys %ScreenRecord ) {
			my $Indent = $IndentChar x $IndentLevel ;
			if ( $Table ne $ScreenRecordName) {
				printf $FORM "%s<ScreenRecord identifier=\"%s\" fields=\"%s\"/>\n",
				$Indent,$Table,join(',',@{ $ScreenRecord{$Table} });
			} else {
				printf $FORM "%s<ScreenRecord identifier=\"%s\" fields=\"%s\" elements=\"%d\"/>\n",
				$Indent,$Table,join(',',@{ $ScreenRecord{$Table} }),$ArrayElements;
			}
	}
} #  bld_form_screenrecords

sub input {
my ( $question,$required) = (@_) ;
printf "%s: ",$question ;
my $answer = <STDIN> ;
chomp ( $answer);
if ( $required == 1 && length($answer) == 0 ) {
	$answer = "#required#" ;
}
return $answer;
}

sub LF {
	if (defined($_[0])) {
		my $MODULE = $_[0] ;
	} else {
		$MODULE = $SRCHANDLE ;
	}
	printf $MODULE "\n";
	$OutLineNum++;
}

sub set_LyciaFieldDefs {
	my $DataTypeFile = sprintf "%s/etc/DataTypes.%s",$FFGDIR,$DBVENDOR;
	open DTHANDLE,$DataTypeFile or die "cannot open file " . $DataTypeFile;
	while (my $dtline=<DTHANDLE>) {
		next if ($dtline =~ /^\s*#/) ;
		chomp ($dtline);
		my ($key,$Length,$DataType) = split (/\t+/,$dtline);
		$DataType{$key}->{Length}=$Length;
		$DataType{$key}->{Type}=$DataType;
		# for formonly fields, build Hash with inversed keys
		$DataEquiv{$DataType}->{ColDef}=$key;
	}
	return \%DataEquiv ; 
} # end  get_datatypes

sub CvtDTIfmx_Lycia {
	my ( $Schema) = ( @_ ) ;
	my $FieldSize=0;
	my $DataType="";
	my $GenericDataType="";
	my $FormSchema = $$Schema ;
	if ( $FormSchema->{datatype} =~ /(\w*CHAR|MONEY|DECIMAL)/) {
		$DataType=uc($1); 
		if ( $FormSchema->{datatype}  =~ /\((\d+)/) {
			$FieldSize = $1;
		} 
		$GenericDataType=$DataType{$DataType}->{Type};
	} else {
		$DataType =$DataType{$FormSchema->{datatype}}->{Type} ;
		$FieldSize=$DataType{$FormSchema->{datatype}}->{Length};
	}
	return $GenericDataType,$FieldSize;
} # end  CvtDTIfmx_Lycia

sub CvtDTLycia_Ifmx {
	my ( $Schema) = ( @_ ) ;
	my $FieldSize=0;
	my $DataType="";
	my $GenericDataType="";
	my $FormSchema = $$Schema ;
	if ( $FormSchema->{datatype} =~ /(\w*CHAR|MONEY|DECIMAL,DATETIME,INTERVAL)/i) {
		$DataType=uc($1); 
		if ( $FormSchema->{datatype}  =~ /\((\d+)/) {
			$FieldSize = $1;
		} 
		$GenericDataType=$DataType{$DataType}->{Type};
	} else {
		$DataType =$DataType{$FormSchema->{datatype}}->{Type} ;
		$FieldSize=$DataType{$FormSchema->{datatype}}->{Length};
	}
	return $GenericDataType,$FieldSize;
} # CvtDTLycia_Ifmx {

sub print_stuff {
	my ($SRCHANDLE,$ArrayPtr,$QuoteChar,$EndLine,$prtmode) = ( @_ ) ;
	my @Array = @{ $ArrayPtr };
	my $QChar= "\"" ;
	my $idx=0;
	if ( $prtmode =~ /multi/) {
		while (defined($Array[$idx])) {
			my $Line = "";
			if ( length($QuoteChar) > 0 ) { 
				$Line = sprintf "%s %s %s",$QuoteChar,$Array[$idx],$QuoteChar ;
			} else {
				$Line = sprintf "%s ",$Array[$idx];
			}
			my $ArrNum=$#Array;
			if ($idx < $ArrNum ) {
				$Line = $Line . $EndLine ;
			} 
 			$OutLineNum=ffg_print ($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_stuff",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
 			$idx++
		}
		$a=1;
	} elsif ( $prtmode =~ /linear/) {
		my $Line = join (/,/,@Array);
		if ( $WriteMode =~ /quote/) { 
			$Line = sprintf "%s %s %s",$QChar,$Line,$QChar ;
			$OutLineNum=ffg_print ($SRCHANDLE,$Line,$OutLineNum,$CurrentFctName,"print_stuff",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE);
		} else {
			$a=1;
		}
	}
	$a=1;
} # end  print_stuff {

sub get_LastConstraintColumn {
	# Sometimes a constraint can be set with columns having a different order than the input order,
	# this subs will return the last Primary/Foreign Key column considering the form input order
	# parse the form ordered by field order then take the last field contained in the constraint column list
	my ( $Constraint,$Form,$FormFieldPtr) = ( @_ );
	my $LastCol="notfound" ;
	my $FormFields = $$FormFieldPtr;
	my $tabme ="";
	if (defined($Constraint->{childColumns}) ) {
		$ConstraintCols=$Constraint->{childColumns};
		$table=$Constraint->{childTable};
	} elsif ( defined($Constraint->{parentColumns}) ) {
		$ConstraintCols=$Constraint->{parentColumns};
		$table=$Constraint->{parentTable};
	} else {
		# unique key
		$ConstraintCols=$Constraint->{columns};
		$table=$Constraint->{table};
	}
	foreach my $key (sort { $FormFields->{$Form}->{$a}->{'Order'} eq $FormFields->{$Form}->{$b}->{'Order'} } keys %{$FormFields->{$Form}} ) {
		if ( $FormFields->{$Form}->{$key}->{Table} ne $table ) {
			next ;
		}
		$key =~ s/:.*// ;
		if ( $ConstraintCols =~ /\b${key}\b/ ) {
			$LastCol=$key;
		}
	}
	return $LastCol;
}

sub list_afterfield_fields {
my ($Form,$Section,$Table) = ( @_ ) ;
my @AfterField = {};
my $afx=0;
	if ($#InputEventFields == 0 ) {
	foreach my $key (sort { $FormField->{$Form}->{$a}->{'Order'} cmp $FormField->{$Form}->{$b}->{'Order'} } keys %{$FormField->{$Form}} ) {
		if ( $FormField->{$Form}->{$key}->{Section} !~ /$Section/ ) {
			next ;
		}
		if ( $FormField->{$Form}->{$key}->{Table} ne $Table ) {
			next ;
		}
		my ($FldName,$TabName,$WID) = split (/:/,$key);

		# one element per property
		if ( $DEBUGPRINT > 2 ) { printf LOGFILE "%s %s\n",$FormField->{$Form}->{$key}->{'Order'},$FormField->{$Form}->{$key}->{'Column'}; }
		if ( $DBSchema{$TabName}{$FldName}->{'NotNull'} eq true ) {
			if ($DBSchema{$TabName}{$FldName}->{datatype} =~ /SERIAL/i ) {
				next ;
			}

			# Check for NOT NULL
			$AfterFieldFields[$afx]->{Section}  = $Section ;
			$AfterFieldFields[$afx]->{Field} = $FldName ;
			$AfterFieldFields[$afx]->{Table} = $TabName ;
			if (defined($FormField->{$Form}->{$key}->{'ScreenRecord'})) {
				$AfterFieldFields[$afx]->{ScreenRecord}=$FormField->{$Form}->{$key}->{'ScreenRecord'};
			}
			$AfterFieldFields[$afx++]->{NotNull} = 1;
		}
		if ( $DBSchema{$TabName}{$FldName}->{'IsPK'} eq true ) {
			if ( $DBSchema{$TabName}{$FldName}->{datatype} =~ /SERIAL/i) {
				next ;
			}
			#Check for primary key
			$AfterFieldFields[$afx]->{Section}  = $Section ;
			$AfterFieldFields[$afx]->{Field} = $FldName ;
			$AfterFieldFields[$afx]->{Table} = $TabName ;
			if (defined($FormField->{$Form}->{$key}->{'ScreenRecord'})) {
				$AfterFieldFields[$afx]->{ScreenRecord}=$FormField->{$Form}->{$key}->{'ScreenRecord'};
			}
			$AfterFieldFields[$afx++]->{PKY} = $PrimaryKeys{$TabName};
		}
		if ( $DBSchema{$TabName}{$FldName}->{'IsFK'} eq true) {
			if ( $DBSchema{$TabName}{$FldName}->{datatype} =~ /SERIAL/i) {
				next ;
			}
			#Check for foreign key
			$AfterFieldFields[$afx]->{Section}  = $Section ;
			$AfterFieldFields[$afx]->{Field} = $FldName ;
			$AfterFieldFields[$afx]->{Table} = $TabName ;
			#my $FKId=get_this_FK ($TabName,$FldName,$colnum );
			my ($ChildLookupCols,$ParentLookupTable,$ParentLookupCols)=get_this_FK ($TabName,$FldName,$colnum );
			
			if (defined($FormField->{$Form}->{$key}->{'ScreenRecord'})) {
				$AfterFieldFields[$afx]->{ScreenRecord}=$FormField->{$Form}->{$key}->{'ScreenRecord'};
			}
			$AfterFieldFields[$afx++]->{FKY} = $ForeignKeys{$FKId};
		}
	}
	}
	# keep the array size, because some elements will be deleted
	my $AfterFieldSize=$#AfterField;
	
	# now check if some PK or FK have utliple columns and keep only the last one
	$afx=0;
	while (defined($AfterFieldFields[$afx])) {
		if ( defined($AfterFieldFields[$afx]->{NotNull})) {
			$afx++;
			next;
		}
		if (defined($AfterFieldFields[$afx]->{PKY})) {
			$LastPKCol=$afx;
		}
		if (defined($AfterFieldFields[$afx]->{FKY})) {
			$LastFKCol{$AfterFieldFields[$afx]->{FKY}} = $afx;
		}
		$afx++;
	}
	$afx=0;
	# clean up all the array elements which are not the last column of PKY and FKY
	while (defined($AfterFieldFields[$afx])) {
		if ( defined($AfterFieldFields[$afx]->{NotNull})) {
			$afx++;
			next;
		}
		if (defined($AfterFieldFields[$afx]->{PKY}) && $afx < $LastPKCol) {
			delete($AfterFieldFields[$afx]) ;
			# @AfterField=splice(@AfterField,$afx,1;
		}
		if (defined($AfterFieldFields[$afx]->{FKY}) && $afx < $LastFKCol{$AfterFieldFields[$afx]->{FKY}} ) {
			delete($AfterFieldFields[$afx]) ;
		}
		$afx++;
	}
	# Compact the array
	$afx=0;
	while ($afx < $AfterFieldSize ) {
		if (!defined($AfterFieldFields[$afx])) {
			splice(@AfterField,$afx,1);
			$AfterFieldSize--;
			$afx--;
		}
		$afx++;
	}
	return @AfterField ;
} # end  list_afterfield_fields



sub catch_last_serial_value {
my ( $SRCHANDLE,$Table,$TableRecord,$PryKeyRecord) = ( @_ ) ;
	my @PKCols = list_table_columns($Table,"","","","pkey","","");
	while (defined($PKCols[$pkx])) {
		if ( $DBSchema{$Table}->{$PKCols[$pkx]}->{datatype} =~ /^SERIAL$/i ) {
			my $line=sprintf "LET %s.%s = sqlca.sqlerrd[2]",$TableRecord,$PKCols[$pkx];
			$OutLineNum = ffg_print ($SRCHANDLE,$line,$OutLineNum,$CurrentFctName,"last_serial_value",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
		} elsif ( $DBSchema{$Table}->{$PKCols[$pkx]}->{datatype} =~ /^BIGSERIAL$|^SERIAL8$/i ) {
			my $line=sprintf "SELECT dbinfo('bigserial') INTO %s.%s\n",$TableRecord,$PKCols[$pkx];
			$OutLineNum = ffg_print ($SRCHANDLE,$line,$OutLineNum,$CurrentFctName,"last_serial_value",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
			$line = "FROM systables WHERE tabid=1\n";
			$OutLineNum = ffg_print ($SRCHANDLE,$line,$OutLineNum,$CurrentFctName,"last_serial_value",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
		}
		my$line=sprintf "LET %s.%s = %s.%s",$PryKeyRecord,$PKCols[$pkx],$TableRecord,$PKCols[$pkx];
		$OutLineNum = ffg_print ($SRCHANDLE,$line,$OutLineNum,$CurrentFctName,"last_serial_value",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
		$pkx++;
	}
} # end catch_last_serial_value

sub dump_database_info {
	printf LOGFILE "===> Database Info\n";
	printf LOGFILE "Here is the database schema for the tables used:\n";
	print LOGFILE Dumper (\%Dbschema );
	printf LOGFILE "Here is the tables list:\n";
	print LOGFILE Dumper (\%TablesList );
	printf LOGFILE "Here are the Primary Keys:\n";
	print LOGFILE Dumper (\%PrimaryKeys );
	printf LOGFILE "Here are the Unique Keys:\n";
	print LOGFILE Dumper (\%UniqueKeys );
	printf LOGFILE "Here are the Foreign Keys:\n";
	print LOGFILE Dumper (\%ForeignKeys );
	printf LOGFILE "Here are the Lookup Keys:\n";
	print LOGFILE Dumper (\%LookupKeys );
	LOGFILE->flush();

}

sub dump_form_info {
	my ($form) = (@_ );
	printf LOGFILE "===> Form %s Info\n",$form;
	printf LOGFILE "Here is the form description of %s:\n",$form;
	print LOGFILE Dumper ($FormField->{$form} );
}

# count number of fields per widget class, to prepare widget object definitions
sub define_Widgets {
my ($MODULE,$Form,$Table,$Section) = (@_ ) ;
my $WidgetsCount=0;
LCOUNTWIDGETS: foreach my $key (sort { $FormField->{$Form}->{$a}->{'Order'} cmp $FormField->{$Form}->{$b}->{'Order'} }keys %{ $FormField->{$Form} } ) {
		if (  $FormField->{$Form}->{$key}->{'Section'} =~ /$Section/ && $FormField->{$Form}->{$key}->{'Table'} =~ /^${Table}$/ ) {
			if (defined($FormField->{$Form}->{$key}->{'Visible'}) && $FormField->{$Form}->{$key}->{'Visible'} eq 'false' ) {
				next LCOUNTWIDGETS ;
			}
				#if ( $FormField->{$Form}->{$key}->{'Noentry'} !~ /$NoEntry/ ) {
			if ( defined($FormField->{$Form}->{$key}->{'Noentry'}) && $FormField->{$Form}->{$key}->{'Noentry'} =~ /true/ ) {
				next LCOUNTWIDGETS ;
			}
			if (defined($FormField->{$Form}->{$key}->{'ScreenRecord'})) {
				#do not take fields in array screen records
				next LCOUNTWIDGETS ;
			}

			$field=$FormField->{$Form}->{$key}->{'Column'};      # rajout 05/07
			my @KeyElem = split (/:/,$key);
			my $FieldTable=$KeyElem[1];
			my $field = $FormField->{$Form}->{$key}->{'Column'} ;
			my $parentTable="";
			my $parentColumns="";
			my $lkx=0;
			my @Lkeys = {} ;
			my @Fkeys = [] ;
			if ( $FormField->{$Form}->{$key}->{'WidgetType'} =~ /ComboBox|ListBox/ ) {
				@Lkeys = ( list_LU_Keys($FieldTable) ) ;
				@Fkeys = ( list_FK_Keys($FieldTable,"child") ) ;
				if ( $#Lkeys > -1) {
					push (@Lkeys,@Fkeys);
				} else {
					@Lkeys=@Fkeys;
				}
				while ( defined($Lkeys[$lkx]) ) {
					if (!defined($Lkeys[$lkx]->{childTable})) {
						$lkx++;
						next;
					}
					if ( $Lkeys[$lkx]->{childTable} eq $FieldTable && $Lkeys[$lkx]->{childColumns} =~ /${field}/ ) {
						# Rule is to consider the first PK column
						$parentTable = $Lkeys[$lkx]->{parentTable} ;
						$parentColumns = $Lkeys[$lkx]->{parentColumns} ;
						$parentColumns =~ s/$GlobalReferenceKey//;
						$parentColumns =~ s/,//g;
						last;
					}
					$lkx++;
				}
			}

			$WidgetsCount++;
			my $WidgetDef="";
			if (defined($GenerateWidgetPopulateFunctions)) {
				if ( $FormField->{$Form}->{$key}->{'WidgetType'} eq 'ComboBox' ) {
					my $ComboName=sprintf "cb_%s",$parentTable;
					if (!defined($CursDeclare{$ComboName})) {
						$WidgetDef=sprintf "DEFINE %s ui.Combobox",$ComboName ;
						$CursDeclare{$ComboName} = 1;
						$OutLineNum = ffg_print ($SRCHANDLE,$WidgetDef,$OutLineNum,$CurrentFctName,"define_widgets",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;
					}
				} elsif ( $FormField->{$Form}->{$key}->{'WidgetType'} eq 'ListBox' ) {
					my $LBName=sprintf "lb_%s",$parentTable;
					if (!defined($CursDeclare{$LBName})) {
						$WidgetDef=sprintf "DEFINE %s ui.Listbox",$LBName ;
						$CursDeclare{$LBName} = 1;
						$OutLineNum = ffg_print ($SRCHANDLE,$WidgetDef,$OutLineNum,$CurrentFctName,"define_widgets",basename($TemplateFile),$TmpltLineNum,$SIGNHANDLE) ;						
					}
				}
			}
		}
	}
	return $WidgetsCount ;
} # end define_Widgets

sub prepare_populate_widgets_functions {
# this function populate the widgets one by one
# TODO: add an option to write the widget functions in library
	my ($MODULE,$Form,$Table,$Section) = (@_ ) ;
	# TODO: build only one populate function per table
	# TODO: rewrite prepare_populate_widgets_functions with %AfterFieldFied

	LPOPW: foreach my $key (sort { $FormField->{$Form}->{$a}->{'Order'} cmp $FormField->{$Form}->{$b}->{'Order'} }keys %{ $FormField->{$Form} } ) {
		if (  $FormField->{$Form}->{$key}->{'Section'} =~ /$Section/ && $FormField->{$Form}->{$key}->{'Table'} =~ /^${Table}$/ ) {
			if ( $FormField->{$Form}->{$key}->{'WidgetType'} !~ /ComboBox|ListBox/ ) {
				next LPOPW ;
			}
			if ( defined($FormField->{$Form}->{$key}->{HasBoxItems})) {
				# eliminate widgets that have static box items
				next LPOPW ;
			}
			if (!defined($FormField->{$Form}->{$key}->{'RequiresInit'})) {
				next LPOPW ;
			}
			if (defined($FormField->{$Form}->{$key}->{'Visible'}) && $FormField->{$Form}->{$key}->{'Visible'} eq 'false' ) {
				next LPOPW ;
			}
				#if ( $FormField->{$Form}->{$key}->{'Noentry'} !~ /$NoEntry/ ) {x 
			if ( defined($FormField->{$Form}->{$key}->{'Noentry'}) && $FormField->{$Form}->{$key}->{'Noentry'} =~ /true/ ) {
				next LPOPW ;
			}
			if (defined($FormField->{$Form}->{$key}->{'ScreenRecord'})) {
				#do not take fields in array screen records
				next LPOPW ;
			}
			my $field=$FormField->{$Form}->{$key}->{'Column'};      # rajout 05/07	
			my $FieldTable=$FormField->{$Form}->{$key}->{'Table'};  # rajout 05/07	
			
			my $lkx=0;
			while (defined($TablesList{$FieldTable}->{ChildLookupCols}[$lkx])) {
				our $BoxParentTable="";
				our $BoxParentLookupCols="";
				our $BoxParentSelectCols="";
				our $BoxFillFct="";
				our $BoxFunctionName="";
				our $BoxDescriptionField="";
				our @BoxFilterParams="";
				our $AdditonalFiltersList="";
				if ( $TablesList{$FieldTable}->{ChildLookupCols}[$lkx] =~ /\b$field\b/ ) {
					# Rule is to consider the first PK column
					$BoxParentTable = $TablesList{$FieldTable}->{ParentLookupTables}[$lkx] ;
					$BoxParentLookupCols = $TablesList{$FieldTable}->{ParentLookupCols}[$lkx] ;
					$BoxParentSelectCols = $BoxParentLookupCols ;
					$BoxParentSelectCols =~ s/$GlobalReferenceKey//;
					$BoxParentSelectCols =~ s/,$|^,//g;

					if (defined($FormField->{$Form}->{$key}->{'BoxDescription'}) ) {
						$SelectBoxColsList=sprintf "%s-%s",$BoxParentSelectCols,$FormField->{$Form}->{$key}->{'BoxDescription'};
					} else {
						$SelectBoxColsList=sprintf "%s",$BoxParentSelectCols;
					}
					undef $BoxFillFct;
					if ( $FormField->{$Form}->{$key}->{'WidgetType'} eq 'ComboBox' ) {
						if ( $FormField->{$Form}->{$key}->{boxFill} =~ /BeforeField/i) {
							$BoxFillFct=$FillComboBoxFct;
						} else {
							$BoxFillFct=$InitComboBoxFct;
						}
					} elsif ( $FormField->{$Form}->{$key}->{'WidgetType'} eq 'ListBox' ) {
						if ( $FormField->{$Form}->{$key}->{boxFill} =~ /BeforeField/i) {
							$BoxFillFct=$FillListBoxFct;
						} else {
							$BoxFillFct=$InitListBoxFct;
						}
					} else {
						$a=1;
					}

					if (defined($BoxFillFct) ) {
						#boxFill is 'prepared with additional where clause as parameter' or 'atStart with no where additional clause'
						if ( $FormField->{$Form}->{$key}->{boxFill} =~ /BeforeField/i) {
							my $AdditionalFilter="";
							$BoxFunctionName = sprintf "%s_%s_%s",$BoxFillFct,$BoxParentTable,$FormField->{$Form}->{$key}->{'Column'};
							my $FKColumns_in_form=find_filter_columns_in_form($FormField->{$Form}->{$key}->{'Column'},$FieldTable,$BoxParentTable);
							#@BoxFilterParams=@$FKColumns_in_form;
							$InputEventFields{$key}->{BoxFilterParams}=join(",",@$FKColumns_in_form);
							$InputEventFields{$key}->{DoBeforeField}=1;
							$InputEventFields{$key}->{BoxFillFct}=$BoxFunctionName;
#							$InputEventFields{$key}->{BoxFillTable}=$BoxParentTable;
							#@ { $InputEventFields{$key}->{BoxFilterParams} } = @BoxFilterParams;
							#process_template ($DynamicComboListTmplt) ;
						} elsif ( $FormField->{$Form}->{$key}->{boxFill} =~ /atStart/i) {
							if (!defined($ThisModuleInitWidgetsFct)) {
								our $ThisModuleInitWidgetsFct=sprintf "%s_%s_%s",$InitWidgetsFct,$ModuleName,$Section ;
							}
							$BoxFunctionName = sprintf "%s_%s_%s",$BoxFillFct,$BoxParentTable,$FormField->{$Form}->{$key}->{'Column'};
							#$InputEventFields{$key}->{BoxFilterParams}=join(",",@$FKColumns_in_form);
							if ( defined($Dbschema{$BoxParentTable}->{$GlobalReferenceKey})) {
								$InputEventFields{$key}->{BoxFilterParams}=$GlobalReferenceKey;
							} else {
								$a=1;
							}
							$InputEventFields{$key}->{BoxFillFct}=$BoxFunctionName;

							#process_template ($StaticComboListTmplt) ;
						}
					} else {
						$a=1;
					}
				}
				$lkx++;
			}
		}
	}
$a=1;
} # end prepare_populate_widgets_functions

sub bld_populate_widgets_functions {
	my ($MODULE,$Form,$Table,$Section) = (@_ ) ;
	$Table //= ".*";
	$Section //= ".*";
	our $BoxParentTable="";
	our $BoxFillFct="";
	our @BoxFilterParams=();
	our @BoxSelectColumns=();
	our $SelectBoxColsList="";

	FORPOPWID:foreach my $key (sort { $InputEventFields{$a}->{'Order'} cmp $InputEventFields{$b}->{'Order'} } keys %InputEventFields ) { 
		$BoxParentTable="";
		$BoxParentLookupCols="";
		$BoxParentSelectCols="";
		$BoxFillFct="";
		$BoxDescriptionField="";
		@BoxFilterParams="";
		$SelectBoxColsList="";
		$AdditonalFiltersList="";

		if (!defined($InputEventFields{$key}->{BoxFillFct})) {
			next FORPOPWID;
		}
		if (defined($InputEventFields{$key}->{Section}) && $InputEventFields{$key}->{Section} !~ /^$Section$/) {
			next FORPOPWID;
		}
		if (defined($InputEventFields{$key}->{childTable}) && $InputEventFields{$key}->{childTable} !~ /\b$Table\b/)	 {
			next FORPOPWID;
		}
		
		$BoxParentTable=$InputEventFields{$key}->{parentTable};
		$BoxFillFct=$InputEventFields{$key}->{BoxFillFct};
		@BoxFilterParams = split(/,/,$InputEventFields{$key}->{BoxFilterParams});
		$BoxParentSelectCols = $InputEventFields{$key}->{parentColumns};
		$BoxParentSelectCols =~ s/$GlobalReferenceKey//;
		$BoxParentSelectCols =~ s/,$|^,//g;
		

		if (defined($FormField->{$Form}->{$key}->{'BoxDescription'}) ) {
			$SelectBoxColsList=sprintf "%s-%s",$BoxParentSelectCols,$FormField->{$Form}->{$key}->{'BoxDescription'};
		} else {
			$SelectBoxColsList=sprintf "%s",$BoxParentSelectCols;
		}
		process_template ($DynamicComboListTmplt) ;
	}
} # bld_populate_widgets_functions


sub bld_populate_widgets_calls_function {
# This functions calls the individual widget populate functions
	my ($MODULE,$Form,$Table,$Section) = (@_ ) ;
	# First count init_widget functions
	# (sort { $InputEventFields{$a}->{'Order'} cmp $InputEventFields{$b}->{'Order'} } keys %InputEventFields ) { 
	my $InitFctCount=0;
	foreach my $key ( %InputEventFields ) {
		if ($InputEventFields{$key}->{Section} ne $Section) {
			next;
		}
		if ($InputEventFields{$key}->{BoxFillFct} !~ /^init_/) {
			next ;
		}
		$InitFctCount++;
	}
	if (defined($ThisModuleInitWidgetsFct) ) {
		printf LOGFILE "    building function %s\n",$ThisModuleInitWidgetsFct ;
		my $Line=sprintf "FUNCTION %s ()",$ThisModuleInitWidgetsFct;
		ffg_print_short($Line);

		foreach my $key ( %InputEventFields ) {
			if ($InputEventFields{$key}->{Section} ne $Section) {
				next;
			}
			if ($InputEventFields{$key}->{BoxFillFct} !~ /^init_/) {
				next ;
			}
			$Line=sprintf "CALL %s(",$InputEventFields{$key}->{BoxFillFct};
			foreach my $field ( split(/,/,$InputEventFields{$key}->{BoxFilterParams}) ) {
				if ( $field eq $GlobalReferenceKey) {
					$Line=sprintf "%s%s.%s,",$Line,${GlobalReferenceRecord},$field;
				} else {
					$Line=sprintf "%s%s.%s,",$Line,${RecordName},$field;
				}
			}
			$Line =~ s/,$/)/;
			$IndentLevel++;
			ffg_print_short($Line);
			$IndentLevel--;
		}
		my $Line=sprintf "END FUNCTION # %s ()\n",$ThisModuleInitWidgetsFct ;
		ffg_print_short($Line);
	}

 } # end bld_populate_widgets_calls
 
 sub bld_main_picklist_window {
	my ( $Module,$Template,$Form ) = ( @_ );

	my $FormFile = sprintf "%s/%s",$QxPerLocation,$Form;
			
	if ( -e $FormFile ) {
		generate_module($Module,">",$Template,$FormFile,$DBSchemaPtr,$PrimaryKeysPtr,$ForeignKeysPtr,$DatabaseName);
	}
} # end  bld_main_picklist_window 

sub column_is_in_form {
	my ($formfield,$formtable,$section) = ( @_ ) ;
	$formtable //= ".*" ;
	$section //= ".*";
	my $IsInForm=0;
	my $ScreenRecord="";
	foreach my $key ( keys %{ $FormField->{$FormName} } ) {
		if ( $FormField->{$FormName}->{$key}->{Field} eq $formfield 
		&&  $FormField->{$FormName}->{$key}->{Table} eq $formtable 
		&& $FormField->{$FormName}->{$key}->{Section} =~ /$section/ )  {
			$IsInForm=$key;
			if (defined($FormField->{$FormName}->{$key}->{'ScreenRecord'} ) ) {
				$ScreenRecord=$FormField->{$FormName}->{$key}->{'ScreenRecord'};
			} 
			last;
		}
	}
	return $IsInForm,$ScreenRecord;
} # end  column_is_in_form 

sub column_is_in_screen_record {
	my ($formfield,$formtable) = ( @_ ) ;
	$formtable //= ".*" ;
	my $IsInForm=0;
	# $FormField->{$Form}->{$key}->{'ScreenRecord'}
	foreach my $key ( keys %{ $FormField->{$FormName} } ) {
		if ( $key =~ /^${formfield}:${formtable}/) {
			$IsInForm=$key;
			last;
		}
	}
	return $IsInForm;
} # end  column_is_in_screen_record 

sub intersect_and_union {
	@a = (1, 3, 5, 6, 7, 8);
	@b = (2, 3, 5, 7, 9);

	@union = @isect = @diff = ();
	%union = %isect = ();
	%count = ();

	foreach $e (@a) { $union{$e} = 1 }

	foreach $e (@b) {
		if ( $union{$e} ) { $isect{$e} = 1 }
		$union{$e} = 1;
	}
	@union = keys %union;
	@isect = keys %isect;
	$a=1;
} # intersect_and_union 

sub find_filter_columns_in_form {
	# This functions looks for potential additional filter columns for a lookup table, that would be present in the form
	# is useful for example to check for additional filters in dynamic combo/listBoxes
	my ($formfield,$formtable,$LookupTable) = ( @_ ) ;
	$formtable //= ".*" ;
	my $IsInForm=0;
	my @idxcols = ();
	my $ScreenRecord="";
	my $FilterColumns=0;
	foreach my $index ( keys %{ $DuplicateKeys{$LookupTable} }) {
		foreach my $Column (split (/,/,$DuplicateKeys{$LookupTable}->{$index}->{columns})) {
			( $ColumnKey,$a) = column_is_in_form($Column,$formtable) ;
			if ( $ColumnKey ne '0' ) { 
				push ( @MoreFilterColumns,$FormField->{$FormName}{$ColumnKey}->{Column});
				$FilterColumns++;	
			} 
			if ( $Column eq $GlobalReferenceKey ) {
				push ( @MoreFilterColumns,$Column);
				$FilterColumns++;	
			}
		}
	}
	return $FilterColumns,\@MoreFilterColumns;
} # end  find_filter_columns_in_form 

sub column_is_entry {
	my ($formfield,$formtable) = ( @_ ) ;
	$formtable //= ".*" ;
	my $IsInForm=0;
	foreach my $key ( keys %{ $FormField->{$FormName} } ) {
		if ( $key =~ /^${formfield}:${formtable}/) {
			if ( !defined($FormField->{$FormName}{$key}->{Noentry}) || $FormField->{$FormName}{$key}->{Noentry} eq 'false' ) {
				$IsInForm=$key;
				last;
			}
		}
	}
	return $IsInForm;
} # end  column_is_entry 

sub column_is_in_index {
	my ($ColName,$TableName) = ( @_) ;
	foreach my $key ( keys % { $DuplicateKeys{$TableName} } ) {
		if ( $DuplicateKeys{$TableName}->{$key}->{columns} =~ /\b$ColName\b/) {
			return $DuplicateKeys{$TableName}->{$key}->{columns};
		}
	}
	return "NotFound";
} # end column_is_in_index

sub dummy_fct {
# dummy function to use in templates, because a template cannot be debugged
	my $dummy=$_[0];
	return $dummy ;
}

sub get_section_from_containerName {
	my ($FormName,$ContainerName ) = ( @_ ) ;
	foreach my $key ( keys %{ $FormField->{$FormName} } ) {
		if ( $FormField->{$FormName}->{$key}->{'ContainerName'} eq $ContainerName && defined($FormField->{$FormName}->{$key}->{'Section'})) {
			return $FormField->{$FormName}->{$key}->{'Section'} ;
		} 
	}
	return "?" ;
} # end get_section_from_containerName

# define_form_fields_old deleted see previous commit

# print_form_fields_old  deleted see previous commit

# list_table_columns_old deleted

# define_table_columns_old deleted see previous commits
# guess_tables_roles deleted see previous commits
# guess_tables_roles_new deleted see previous commits

# print_table_columns_old deleted see previous commit

sub preprocess_template {
	# One template file can "include" other template files
	# to do so, they "include" template are copied into the "main/calling" template file in a big file in the signatures folder
	# this sub reads the template file, eventually includes!include files and write to the sig directory
	# this file will be the template used
	my ($TemplateFile,$PreProcessFile) = (@_) ;
	my $SPreProcOpen = sprintf "%s%s",$OpenMode,$PreProcessFile ;
	open $TEMPLATE,$TemplateFile or die "Could not open template file " . $TemplateFile ;
	open $PREPROCESS,">$PreProcessFile" or die "Could not create pre-process file " . $PreProcessFile  ;

	my $TpltLine="" ;
	$.=0;
	my $TmpltLineNum=0;

	PREPROCESS: while ( $TpltLine=<$TEMPLATE> ) {
		if ($TpltLine =~ /<:Include\s+(.*)\s*:Include>/ ) {
			my $IncludeName=$1;
			my $IncludeFile=sprintf "%s/%s",dirname($TemplateFile),$IncludeName;
			open $INCLUDE,$IncludeFile or die "Could not open the include file " . $IncludeName ;
			while (my $InclLine=<$INCLUDE>) {
				printf $PREPROCESS "%s",$InclLine;
			}
			close $INCLUDE;
			next PREPROCESS;
		}
		printf $PREPROCESS "%s",$TpltLine;
		$TmpltLineNum++;
	}
	close $PREPROCESS;
	close $TEMPLATE ;
	return $TmpltLineNum;
}

#############################################################################################################
# deprecated functions
#############################################################################################################

sub guess_lookup_columns {
	# This functions guesses lookup columns based on identical column names in tables indexes
	my ( $LookupTable,$ChildTable) = ( @_);
	# TODO: complete guess_lookup_columns
	# 1 guet looktupTable PK or UK
	# 2 find same columns in duplicate indexes of the childTable
	# 3 Set same structure as %TablesList
} # end guess_lookup_columns {