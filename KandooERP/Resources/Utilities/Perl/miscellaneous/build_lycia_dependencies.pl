#!/usr/bin/perl
# Description  :  this script parses one or more makefiles and builds directory structure
# for import into a Lycia project
# (c) Copyright Begooden-IT Consulting 2010-2016
# Author eric.vercelletto@begooden-it.com
#  "@(#)$Id: build_lycia_dependencies.pl 334 2016-04-12 06:10:05Z  $:"
# $Rev: 334 $:                                             last commit revision number
# $Date: 2016-04-12 08:10:05 +0200 (mar., 12 avr. 2016) $: last commit date

use Getopt::Long;
use File::Basename;
use File::Copy;
use Cwd 'abs_path';
usage () if ( ! GetOptions(
## options for files selection
	"makefiles=s"=>\$MakeFile,				# imports from this makefiles list, separated by ,
	"makelist=s"=>\$MakefilesList,		# gets the makefiles list by reading this file: 1 file per line
	"makedir=s"=>\$InputDir, 				# gets the makefiles list by reading this directory
	"includefiles=s"=>\$IncludeFiles,	# file patterns ( .4gl, .ec etc...
	"excludefiles=s"=>\$ExcludeFiles, 	# file patterns ( .4gl, .ec etc...
	"recursive"=>\$Recursive, 			# Directory where source files are backuped
## options for mode ( do what ? )
	"mode=s"=>\$MakeMode,					# looks for .4ge or .4gi or other
	"checkonly"=>\$CheckOnly,				# only checks files contents and lists found progs and objects
	"qxtheme=s"=>\$StdQxTheme,				# name of standard qxtheme file if any
	"force"=>\$Force, 						# Directory where source files are backuped
	"listonly"=>\$ListOnly, 				# just list the files
## options for locations and identifications
	"workspace=s"=>\$LyciaWorkspace, 	# Lycia workspace where project will be generated
	"projectname=s"=>\$ProjectName, 		# ProjectName
	"clibrary=s"=>\$CLibraryName, 		# Default C library name
	) ) ;

	# choose targets and objects extensions in the makefile, can be .4ge/.o, .4gi/.4go or custom
	if (!defined( $MakeMode ) || $MakeMode =~ /4ge/ ) {
		$PrgExtension = "\\\.4ge" ;
		$ObjExtension ="\\\.o" ;
		$ProgramTargetComponentsExpr = "([\\w_]+)\.4ge\:\s*(\.\*\\\.[oa])" ;
		$LibraryTargetComponentsExpr =  "([\\w_]+)\.a\:\s*(\.\*\\\.[oa])" ;
	} elsif ( $MakeMode =~ /4gi/ ) {
		$PrgExtension = "\.4gi" ;
		$ObjExtension ="\.4go" ;
		$ProgramTargetComponentsExpr = "([\\w_]+)\.4gi\:\s*(\.\*\\\.4go)" ;
		$LibraryTargetComponentsExpr =  "([\\w_]+)\.4ga\:\s*(\.\*\\\.4go)" ;
	} elsif ( $MakeMode =~ /cust/ ) {
		printf "Please input Program extension: " ;
		$PrgExtension = <STDIN> ;
		chomp $PrgExtension ;
		printf "Please input Object extension : " ;
		$ObjExtension = <STDIN> ;
		chomp $ObjExtension ;
		$ProgramTargetComponentsExpr = "([\\w_]+)\\" . $PrgExtension ."\:\s*(\.\*\\" . $ObjExtension .")" ;
		$LibraryTargetComponentsExpr =  "([\\w_]+)\.a\:\s*(\.\*\\\.4gl)" ;
	} else {
		die "Please give a valid Makefile mode ( 4ge 4gi custom )";
	}
		
	printf "RegExp to catch programs and modules\n%s\n",$ProgramTargetComponentsExpr ;
	
if (!defined ($CheckOnly)) {
	if (!defined($LyciaWorkspace)) {
		printf "Lycia Workspace location ";
		$LyciaWorkspace=<STDIN>;
		chomp $LyciaWorkspace;
	}
	if ( -d $LyciaWorkspace ) {
		printf "Workspace %s exists, ok\n",$LyciaWorkspace;
	} else {
		printf "Workspace %s does not exist, creating\n",$LyciaWorkspace;
		mkdir $LyciaWorkspace ;
	}
	if (!defined($ProjectName)) {
		printf "Lycia Project Name: " ;
		$ProjectName=<STDIN> ;
		chomp $ProjectName ;
	}
	$ProjectDir=sprintf "%s/%s",$LyciaWorkspace,$ProjectName ;
	$ProjectSourceDir=sprintf "%s/%s/source",$LyciaWorkspace,$ProjectName ;
	$ProjectSource4gl=sprintf "%s/%s/source/4gl",$LyciaWorkspace,$ProjectName ;
	$ProjectSourcePer=sprintf "%s/%s/source/per",$LyciaWorkspace,$ProjectName ;
	$ProjectSourceC=sprintf "%s/%s/source/C",$LyciaWorkspace,$ProjectName ;
	$ProjectOutputDir=sprintf "%s/%s/output",$LyciaWorkspace,$ProjectName ;
	mkdir $ProjectDir ;
	mkdir $ProjectSourceDir ;
	mkdir $ProjectOutputDir ;
	mkdir $ProjectSource4gl;
	mkdir $ProjectSourcePer;
	mkdir $ProjectSourceC;

	$LogFile = sprintf "%s/prj_import_%s.log",$ProjectDir,$ProjectName;
	open LOGFILE,">$LogFile" or die "Cannot create project file " . $LogFile ;


	# project file and fglproject file not necessary. They are created at lycia import time or project create time
	# print .project file
	$ProjectFile = sprintf "%s/.project",$ProjectDir;
	open PROJECTFILE,">$ProjectFile" or die "Cannot create project file " . $ProjectFile ;
	print_project_file($ProjectName) ;

	$FglProjectFile = sprintf "%s/.fglproject",$ProjectDir;
	open FGLPROJECTFILE,">$FglProjectFile" or die "Cannot create project file " . $FglProjectFile ;
}

if (defined($MakeFile) ) {
	# list in one string, comma separated
	$MakeFile =~ s/\s+// ;
	@MakeList = split (/,/,$MakeFile) ;
} elsif (defined($MakefilesList)) {
	# list in one file, \n separated
	if ( -f $MakefilesList ) {
		open MAKELIST,$MakefilesList or die "cannot open file containing list of makefiles " . $MakefilesList ;
		@MakeList = <MAKELIST> ;
	}
} elsif ( defined($InputDir) ) {
	# parse from here, filter IncludeFiles and ExcludeFile
	# caution, parse_directory still calls import_from_makefile !!!!
	parse_directory ($InputDir,$Recursive,$IncludeFiles,$ExcludeFiles) ;
}

my $mkf=0;
# run the import for all those makefiles
while(defined($MakeList[$mkf])) {
	chomp $MakeList[$mkf] ;
	import_from_makefile ($MakeList[$mkf]);
	$mkf++;
}

if (!defined($CheckOnly)) {
	# prepare the zip file to be imported
	printf "Building Archive terminated, please run the following command\n";
	my $zipcommand = sprintf "cd %s;zip -r %s.zip .",$ProjectSourceDir,$ProjectName ;
	printf "%s\n",$zipcommand ;
}
	

sub import_from_makefile {
my $Makefile = $_[0] ;
$mdl=0;
	parse_makefile ($Makefile) ;

	# build fgltarget file for each program or library
	if (!defined($CheckOnly)) {
		foreach $prog ( keys %ProgramList ) {
			print_fgltarget_file ($prog,\$ProgramList{$prog}) ;
		}

		# if new libraries have been created, they need a fgltarget file
		if ( defined(%NewLibraryList)) {
			# New Libraries have been created during this process
			foreach $lib ( keys %NewLibraryList ) {
				print_fgltarget_file ($lib,\$NewLibraryList{$lib}) ;
			}
		}
		# Build fglproject file for this project at the end because new libraries may have been created in fgltarget
		print_fglproject_file($ProjectName) ; #/ deprecated, not necessary
	}
	print_makefile_stats($Makefile) ;
$a=1;

} # end import_from_makefile

# Read makefile and catch all program and library dependencies
sub parse_makefile {
	my $Makefile = $_[0] ;
	open MAKEFILE,$Makefile or die "cannot open " . $Makefile;
	$ContinueList = 0;
	READMAKE: while (<MAKEFILE>) {
		if ( /$ProgramTargetComponentsExpr/ || /$LibraryTargetComponentsExpr/ || $ContinueList == 1 ) {
			if ( /$ProgramTargetComponentsExpr/ ) {
				# this is a regular program definition, made a priori of .4gl
				undef $LibName;
				$ProgName=$1;
				$ModuleListString=$2 ;
			} elsif (/$LibraryTargetComponentsExpr/ ) {
				# This is a library definition, can be .4gl or .c
				undef $ProgName;
				$LibName=$1;
				$ModuleListString=$2 ;
			}
			if ( $ContinueList == 0 ) {
				undef @ModulesListArray ;
				undef @ModuleTypeArray ;
				$FglCount=0;
				$CCount=0;
				$mdl=0;
				$ModuleListString =~ s/^\s+// ;
			} else {
				# concatenate former line 
				$ModuleListString = $ModuleListString . " " . $_ ;
			}

			if ( /\\$/ ) { # line ends with \  => continue dependencies list
				$ContinueList = 1;
				next READMAKE;
			} else {
				$ContinueList = 0;
			}

			# if we catch a program, all components should be .4gl modules, with some .c exceptions
			# if we catch a library, components can be .c modules or .4gl
			if (defined($ProgName) ) {
				#$ModuleListString =~ s/\.o/.4gl/g ;
				$ModuleListString =~ s/$ObjExtension/.4gl/g ;
			} elsif (defined($LibName) ) {
				#$ModuleListString =~ s/\.o/.c/g ;
				$ModuleListString =~ s/$ObjExtension/.c/g ;
			}
			@ModulesListArray = split (/\s+/,$ModuleListString) ;

			
			# parse the modules list array and check files
			#############

			while ( defined($ModulesListArray[$mdl]) ) {
				if (defined($ProgName) ) {
					# this normally a .4gl file, try .4gl first, if not, try .c, else file not found
					$ProgramList{$ProgName}->{Type} = "fgl-program" ;
					if ( ( -f $ModulesListArray[$mdl] )) {
						$ModuleTypeArray[$mdl] = "fgl" ;
						$FglCount++;
					} else {
						# probably a .c module
						$ModulesListArray[$mdl] =~ s/\.4gl/.c/ ;
						# test if .c, if not, file not found
						if ( ! ( -f $ModulesListArray[$mdl] )) {
							printf LOGFILE "ERROR! FILE %s NOT FOUND for program %s, will be discarded %s\n",$ProgramList{$ProgramName}->{ModuleList}[$mdl], $ProgName;
							# print not found in log and splice arrary
						} else {
							$ModuleTypeArray[$mdl] = "c" ;
							$CCount++;
						}
					}
				} elsif (defined($LibName) ) {
					# this normally a .c file, try .c first, if not, try .4gl, else file not found
					if ( ( -f $ModulesListArray[$mdl] )) {
						$ModuleTypeArray[$mdl] = "c" ;
						$CCount++;
					} else {
						# probably a .4gl module: try
						$ModulesListArray[$mdl] =~ s/\.c/.4gl/ ;
						if ( ( -f $ModulesListArray[$mdl] )) {
							$ModuleTypeArray[$mdl] = "fgl" ;
							$FglCount++;
						}	else {
							printf LOGFILE "ERROR! FILE %s NOT FOUND for library %s, will be discarded %s\n",$ProgramList{$ProgramName}->{ModuleList}[$mdl],$LibName;
							# print not found in log and splice arrary
						}
					}
				}
				$mdl++;
			}
			if (defined($ProgName) ) {
				$ProgramList{$ProgName}->{ModuleList}   = [@ModulesListArray] ;
				$ProgramList{$ProgName}->{ModuleType}  = [@ModuleTypeArray] ;
			} elsif (defined($LibName) ) {
				$ProgramList{$LibName}->{ModuleList}   = [@ModulesListArray] ;
				$ProgramList{$LibName}->{ModuleType}  = [@ModuleTypeArray] ;
				# check if lib members are 4Gl or C to determine type
				if ( $FglCount < $CCount ) {
					$ProgramList{$LibName}->{Type} = "static-c-library" ;
				} else {
					$ProgramList{$LibName}->{Type} = "fgl-library" ;
				}
			}
			if ( defined($CheckOnly)) {
				my $mm=0;
				if ( $ProgName =~ /^$/ ) {
					$ProgName = $LibName;
				}
				printf "%s %s:" ,$ProgramList{$ProgName}->{Type},$ProgName;
				while (defined($ProgramList{$ProgName}->{ModuleList}[$mm])) {
					if ( -f $ProgramList{$ProgName}->{ModuleList}[$mm] ) {
						$TotalExistingModules{$ProgramList{$ProgName}->{ModuleList}[$mm]} = 1 ;
						printf "%s ",$ProgramList{$ProgName}->{ModuleList}[$mm];
					} else {
						$TotalMissingModules{$ProgramList{$ProgName}->{ModuleList}[$mm]} = 1 ;
						printf "%s MISSING,",$ProgramList{$ProgName}->{ModuleList}[$mm];
					}
					$mm++ ;
				}
				printf "\n" ;
				print_forms_dependencies ($ProgName);
			}
		}
	}
	close MAKEFILE ;
} # end sub parse_makefile

#### parse the modules of a program for open form or open window
sub print_forms_dependencies {
	my ($ProgName,$TargetDir) = @_ ;
	my $mdlf=0;
	$TargetDir=sprintf "%s/per",$ProjectSourceDir;
	%ProgramForms = () ;		# controls forms only once

	# parse every module of the program and look for OPEN FORM or WITH FORM
	while(defined($ProgramList{$ProgName}->{ModuleList}[$mdlf])) {
		if ( -r $ProgramList{$ProgName}->{ModuleList}[$mdlf] ) {
			open MODULE,$ProgramList{$ProgName}->{ModuleList}[$mdlf] or die "cannot open module " . $ProgramList{$ProgName}->{ModuleList}[$mdlf];
			while ( <MODULE> ) {
				if ( /open form\s+|with form\s+"/i ) {
					if ( /open form.*from\s+\"([\w_]+)\"/i ) {
						$ProgramForms{$1} = 1;	
					} elsif ( /with form\s+\"([\w_]+)\"/i ) {
						$ProgramForms{$1} = 1;	
					} else {
						printf "weird syntax for form %s",$& ;
					}
				}
			}
		}
		$frm =  0 ;
		close MODULE;
		$mdlf++;
	}
	if (defined($CheckOnly)) {
		if ( keys %ProgramForms > 0 ) {
			printf "   forms: ";
			foreach $form ( keys %ProgramForms ) {
				my $f = $form . ".per" ;
				if ( -f $f ) {
					printf "%s ",$form;
					$TotalExistingForms{$form} = 1 ;
				} else {
					printf "%s MISSING ",$form;
					$TotalMissingForms{$form}  = 1;
				}
			}
			printf "\n",$form;
		}
		return ;
	}
		
	# Once all modules have been checked, print forms list
	my $nblines=0 ;
	# print forms dependencies
	foreach $form ( keys %ProgramForms ) {
		if ( $nblines == 0 ) {
			printf FGLTARGETFILE "  <sources type=\"form\">\n"; 
		}
		printf FGLTARGETFILE "    <file location=\"%s/%s.per\"/>\n",basename($TargetDir),$form ;
		printf LOGFILE "form %s referenced in fgltarget file %s\n",$SourceFormFile,$TargetDir;
		$SourceFormFile=sprintf "%s.per",$form ;
		$TargetFormFile=sprintf "%s/%s.per",$TargetDir,$form;
		if ( -f $SourceFormFile ) {
			copy ( $SourceFormFile,$TargetFormFile ) ;
			$TotalExistingForms{$SourceFormFile} = 1 ;
			$nblines++;
			if ( $? == 0 ) {
				printf LOGFILE "form %s copied to project source %s\n",$SourceFormFile,$TargetDir;
			} else {
				printf LOGFILE "ERROR! FORM %s CANNOT BE COPIED to project source %s\n",$SourceFormFile,$TargetDir;
			}
		} else {
			printf LOGFILE "ERROR! form %s opened in application but not found %s\n",$SourceFormFile;
			$TotalMissingForms{$SourceFormFile} = 1 ;
		}
	}
	my $FormsNumber=keys %ProgramForms;
	if ( $FormsNumber > 0 ) {
		printf FGLTARGETFILE "  </sources>\n\n" ;
	}
}

##### print fgltarget file for program or Library
sub  print_fgltarget_file {
my ($ProgramName,$ProgramList) = @_;
# create the fgltarget file
$FglTargetFile = sprintf "%s/.%s.fgltarget",$ProjectSourceDir,$ProgramName ;
open FGLTARGETFILE, ">$FglTargetFile" or die "Cannot create fgltarget file " . $FglTargetFile ;

# Reset the libaries for this program
%ThisProgramLibraries = () ;

my $message = <<"ENDFGLTRGF" ;
<?xml version="1.0" encoding="UTF-8"?>
<fglBuildTarget xmlns="http://namespaces.querix.com/lyciaide/target" name="$ProgramName" type="$$ProgramList->{Type}">

ENDFGLTRGF
printf FGLTARGETFILE $message;

# Libraries reinit for every program
#if (defined($CLibraryName)) {
	#undef $CLibraryName ;
#}
# print modules in fgltarget file
# one element / module

##################################################
# First while loop catching C libraries with .c files
my $mdl=0 ;
my $nblines=0 ;
#while (defined($ProgramList{$ProgramName}->{ModuleList}[$mdl])) {
while (defined($$ProgramList->{ModuleList}[$mdl])) {
	if ( $$ProgramList->{ModuleList}[$mdl] =~ /\.c$/ && $$ProgramList->{Type} eq "static-c-library" ) {
		if ( $nblines == 0 ) {
			printf FGLTARGETFILE "  <sources type=\"c\">\n";
		} 
		$TargetDir=sprintf "%s/C",$ProjectSourceDir;
		printf FGLTARGETFILE "    <file location=\"%s/%s\"/>\n",basename($TargetDir),$$ProgramList->{ModuleList}[$mdl];
		copy ( $$ProgramList->{ModuleList}[$mdl],$TargetDir ) ;
		$nblines++;
		if ( $? == 0 ) {
			printf LOGFILE "C module %s copied to project source %s\n",$$ProgramList->{ModuleList}[$mdl],$TargetDir;
			$TotalExistingModules{$$ProgramList->{ModuleList}[$mdl]} = 1 ;
		} else {
			printf LOGFILE "ERROR! C MODULE %s CANNOT BE COPIED to project source %s\n",$$ProgramList->{ModuleList}[$mdl],$TargetDir;
			$TotalMissingModules{$$ProgramList->{ModuleList}[$mdl]} = 1 ;
		}
		
	}
	$mdl++;
}
if ( $nblines > 0 ) {
	printf FGLTARGETFILE "  </sources>\n\n";
} 

##################################################
# Then while loop catching 4gl libraries with .4gl files
my $mdl=0 ;
my $nblines=0 ;
while (defined($$ProgramList->{ModuleList}[$mdl])) {
	if ( $$ProgramList->{ModuleList}[$mdl] =~ /\.4gl$/ && $$ProgramList->{Type} eq "fgl-library" ) {
		if ( $nblines == 0 ) {
			printf FGLTARGETFILE "  <sources type=\"%s\">\n",$$ProgramList->{ModuleType}[$mdl];
		} 
		$TargetDir=sprintf "%s/4gl",$ProjectSourceDir;
		printf FGLTARGETFILE "    <file location=\"%s/%s\"/>\n",basename($TargetDir),$$ProgramList->{ModuleList}[$mdl];
		copy ( $$ProgramList->{ModuleList}[$mdl],$TargetDir ) ;
		$nblines++;
		if ( $? == 0 ) {
			printf LOGFILE "Library 4gl module %s copied to project source %s\n",$$ProgramList->{ModuleList}[$mdl],$TargetDir;
			$TotalExistingModules{$ProgramList{$ProgName}->{ModuleList}[$mdl]} = 1 ;
		} else {
			printf LOGFILE "ERROR! Library 4gl MODULE %s CANNOT BE COPIED to project source %s\n",$$ProgramList->{ModuleList}[$mdl],$TargetDir;
			$TotalMissingModules{$ProgramList{$ProgName}->{ModuleList}[$mdl]} = 1 ;
		}
	}
	$mdl++;
}
if ( $nblines > 0 ) {
	printf FGLTARGETFILE "  </sources>\n\n";
} 

##################################################
# then loop on 4gl regular modules
my $mdl=0 ;
my $nblines=0 ;
while (defined($$ProgramList->{ModuleList}[$mdl])) {
	if ( $$ProgramList->{ModuleType}[$mdl] eq "fgl" && $$ProgramList->{Type} eq "fgl-program" ) {
		if ( $nblines == 0 ) {
			printf FGLTARGETFILE "  <sources type=\"%s\">\n",$$ProgramList->{ModuleType}[$mdl];
		} 
		$TargetDir=sprintf "%s/4gl",$ProjectSourceDir;
		printf FGLTARGETFILE "    <file location=\"%s/%s\"/>\n",basename($TargetDir),$$ProgramList->{ModuleList}[$mdl];
		printf LOGFILE "4gl module %s referenced in fglproject file %s\n",$$ProgramList->{ModuleList}[$mdl],$FglTargetFile;
		copy ( $$ProgramList->{ModuleList}[$mdl],$TargetDir ) ;
		$nblines++;
		if ( $? == 0 ) {
			printf LOGFILE "4gl module %s copied to project source %s\n",$$ProgramList->{ModuleList}[$mdl],$TargetDir;
			$TotalExistingModules{$$ProgramList}->{ModuleList}[$mdl] = 1 ;
		} else {
			printf LOGFILE "ERROR! 4GL MODULE %s CANNOT BE COPIED to project source %s\n",$$ProgramList->{ModuleList}[$mdl],$TargetDir;
			$TotalMissingModules{$$ProgramList}->{ModuleList}[$mdl] = 1 ;
		}
	}
	$mdl++;
}
if ( $nblines > 0 ) {
	printf FGLTARGETFILE "  </sources>\n\n";
} 

##################################################
# then loop on hidden .c in fgl programs ( special case )
my $mdl=0 ;
my $nblines=0 ;
while (defined($$ProgramList->{ModuleList}[$mdl])) {
	if ( $$ProgramList->{ModuleList}[$mdl] =~ /\.c$/ && $$ProgramList->{Type} eq "fgl-program" ) {
		## there is a C library hidden in the 4gl list
		# it must be moved to an existing Library and this Library should be referenced here instead of .c module file
		if (!defined($Libraries{$$ProgramList->{ModuleList}[$mdl]})) {
			# if this .c module has not yet been moved to a library
			# this is the lib name of this c module
			if (!defined($CLibraryName)) {
				while (length($CLibraryName) == 0 ) {
					printf "For program %s, the module %s has to be copied in a C library\n",$ProgramName,$$ProgramList->{ModuleList}[$mdl] ;
					printf "Please enter new Library Name to be created: ";
					$CLibraryName = <STDIN>;
					chomp $CLibraryName;
				}
				# Add a new 'program' which is the library , containing the c files
			}
			# put the .c file into the library, and see how to delete the current module NEW HASH to be parsed after
			$NewLibraryList{$CLibraryName}->{ModuleList}[$cfiles] = $$ProgramList->{ModuleList}[$mdl] ;
			$NewLibraryList{$CLibraryName}->{Type} = "static-c-library" ;
			$TargetDir=sprintf "%s/C",$ProjectSourceDir;
			copy ( $$ProgramList->{ModuleList}[$mdl],$TargetDir ) ;
			if ( $? == 0 ) {
				printf LOGFILE "C module %s moved to NEW library %s\n",$$ProgramList->{ModuleList}[$cfiles],$CLibraryName ;
				$Libraries{$$ProgramList->{ModuleList}[$mdl]}->{LibName} = $CLibraryName ;
			} else {
				printf LOGFILE "ERROR! C module %CANNOT BE MOVED to NEW library %s\n",$$ProgramList->{ModuleList}[$cfiles],$CLibraryName ;
			}
			$cfiles++;
			$a=1 ;
		} 
		# Set this library for this program
		$ThisProgramLibraries{$Libraries{$$ProgramList->{ModuleList}[$mdl]}->{LibName}} = 1;
	} 
	$mdl++;
}
$a=1;

# if libraries have been used, put them here
$libn=0;
if ( defined(%ThisProgramLibraries)) {
	foreach $lib ( keys (ThisProgramLibraries) ) {
		if ( $libn == 0 ) {
			printf FGLTARGETFILE "<libraries>\n" ;
		}
		printf FGLTARGETFILE "    <library name=\"%s\" dynamic=\"false\" location=\"\"/>\n",$lib;
		$libn++;
	}
	if ( $libn > 0 ) {
		printf FGLTARGETFILE "  </libraries>\n" ;
	}
	printf LOGFILE "C Library %s referenced in fglproject file %s\n",$lib,$TargetDir;
}

# print forms dependencies
print_forms_dependencies ($ProgramName,$TargetDir) ;

if (defined($StdQxTheme) ) {
	if ( -f $StdQxTheme ) {
		my $TargetQxTheme = sprintf "%s.qxtheme",$ProgramName ;
		$message = <<"ENDTRGF2" ;
  <mediaFiles>
     <file client="true" location="$TargetQxTheme" type="gui-theme-file"/>
  </mediaFiles>
</fglBuildTarget>
ENDTRGF2
		printf FGLTARGETFILE $message;
		$TargetQxTheme = sprintf "%s/%s",$ProjectSourceDir,$TargetQxTheme ;
		copy ( $StdQxTheme,$TargetQxTheme ) ;
		if ( $? == 0 ) {
			printf LOGFILE "standard qxthem file %s copied to %s\n",$StdQxTheme,$TargetQxTheme ;
		} else {
			printf LOGFILE "ERROR! standard qxthem file %s CANNOT BE COPIE TO to %s\n",$StdQxTheme,$TargetQxTheme ;
		}
	 } else {
		printf LOGFILE "ERROR! standard qxthem file %s CANNOT BE FOUND\n",$StdQxTheme ;
	}
}
close FGLTARGETFILE ;
} # end print_fgltarget_file

sub parse_directory {
	my ($InputDir,$Recursive,$IncludeFiles,$ExcludeFile) = ( @_ ) ;
	opendir (INPUTDIR,$InputDir) or die "Cannot open directory " . $InputDir ;
	my @FilesList = ( sort readdir(INPUTDIR) );
	my $fl=0;
	my $mdl=0;
	FILE: while ( $mkfile = $FilesList[$fl] ) {
		if ( $mkfile eq "." || $mkfile eq ".." || $mkfile =~ /$ExcludeDir/ ) {
			$fl++;
			next FILE;
		}
		if ( defined($IncludeFiles) && $mkfile !~  /$IncludeFiles/ ) {
			$fl++;
			next FILE;
		}
		if ( defined($ExcludeFiles) && $mkfile =~  /$ExcludeFiles/ ) {
			$fl++;
			next FILE;
		}
		
		# parse file for open window open form
		if ($InputDir =~ /\./ ) {
			$InputDirAbs = abs_path($InputDir) ;
		}
		$fname=sprintf "%s/%s",$InputDirAbs,$mkfile;
		#$fname =~ s://:/:g;
		if ( -f $fname ) {
			# push this makefile into array
			# import_from_makefile($fname);
			push (@MakeList,$fname )
		} else { ############## end
			if ( $Recursive eq "YES" && -d ($fname) && $fname !~ /^\./ ) {
				parse_directory ($fname) ;
			} else {
				$a=1;
			}
		}
		$fl++ ;
	}  # end while FILE
}

sub print_makefile_stats {
my $Makefile = $_[0] ;
	$totprogs=keys %ProgramList;
	$totexismod=keys %TotalExistingModules;
	$totexisforms=keys %TotalExistingForms;
	$totmismod=keys %TotalMissingModules;
	$totmisforms=keys %TotalMissingForms;

	#############
	# statistics
	printf "\n\nMakefiles %s contains %d programs, with %d existing modules, %d existing forms, %d missing modules and %d missing forms\n\n",
	$Makefile,$totprogs,$totexismod,$totexisforms,$totmismod,$totmisforms;
}


###### deprecated subs 
sub print_project_file {
my $ProjectName = $_[0];
my $message = <<"ENDPJF" ;
<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
	<name>$ProjectName</name>
	<comment></comment>
	<projects>
	</projects>
	<buildSpec>
		<buildCommand>
			<name>com.querix.fgl.core.fglbuilder</name>
			<arguments>
			</arguments>
		</buildCommand>
	</buildSpec>
	<natures>
		<nature>com.querix.fgl.core.fglnature</nature>
	</natures>
</projectDescription>
ENDPJF
$a=1;
printf PROJECTFILE $message ;
}  # end print_project_file


#################################################
# prints the fglproject file 
#################################################
sub print_fglproject_file {
my $ProjectName = $_[0];
my $message = <<"ENDFGLPJF" ;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<fglProject name="$ProjectName">
<data>
<item id="com.querix.fgl.core.pathentries">
<pathentry kind="src" path="source"/>
<pathentry kind="out" path="output"/>
</item>
<item id="com.querix.fgl.core.buildtargets">
ENDFGLPJF
printf FGLPROJECTFILE $message;



## check if better build fgltarget files, detect there are libraries then build fglprojectfile
# one element per program

foreach $prog ( keys %ProgramList ) {
	if ( $prog,$ProgramList{$prog}->{Type} =~ /fgl-program/ ) {
		$location = "" ;
	} elsif ( $prog,$ProgramList{$prog}->{Type} =~ /library/ ) {
		$location = "" ;
	} else {
		# not typed, skip
		next;
	}
	printf FGLPROJECTFILE "<buildTarget location=\"%s\" name=\"%s\" type=\"%s\"/>\n",$location,$prog,$ProgramList{$prog}->{Type};
	printf LOGFILE "4gl program %s referenced in fglproject file %s\n",$prog,$TargetDir;
}

if ( defined(%NewLibraryList)) {
	# New Libraries have been created during this process
	foreach $lib ( keys %NewLibraryList ) {
		printf FGLPROJECTFILE "<buildTarget location=\"\" name=\"%s\" type=\"%s\"/>\n",$lib,$NewLibraryList{$lib}->{Type};
		printf LOGFILE "C Library %s referenced in fglproject file %s\n",$lib
	}
}

## we finish the fglproject file and close it 
printf FGLPROJECTFILE "</item>\n</data>\n </fglProject>\n";
close FGLPROJECTFILE ;

} # end print_fglproject_file

