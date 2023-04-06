#!/usr/bin/perl
# Description  :  this script parses directories to check 
# encoding conformity with Doxyfile definitions
# (c) Copyright Begooden-IT Consulting 2010-2015
# Author eric.vercelletto@begooden-it.com
#  "@(#)$Id: fglaacheck.pl 321 2016-02-07 08:16:14Z  $:"
# $Rev: 321 $:                                             last commit revision number
# $Date: 2016-02-07 09:16:14 +0100 (dim. 07 févr. 2016) $: last commit date

use Getopt::Long;
use File::Basename;
use File::Copy;
use Cwd 'abs_path';
usage () if ( ! GetOptions(
	"inputdir=s"=>\$InputDir,			# input directory, where the source files are
	"listfile=s"=>\$ModulesListFile,		# File containing the list of modules
	"moduleslist=s"=>\$ModulesList,		# File containing the list of modules
	"includefiles=s"=>\$IncludeFiles, 		# file patterns ( .4gl, .ec etc...
	"excludefiles=s"=>\$ExcludeFiles, 		# file patterns ( .4gl, .ec etc...
	"recursive=s"=>\$Recursive, 	# Directory where source files are backuped
	"force"=>\$Force, 				# Directory where source files are backuped
	"listonly"=>\$ListOnly, 			# just list the files
	) ) ;

##########################
# first build files list
@ModulesListArray = {} ;
if (!defined($ExcludeDir)) {
	$ExcludeDir="Xnqsd,#rjks!!" ;
}
$mdl=0;
if ( defined($InputDir) ) {
	parse_directory ($InputDir,".4gl") ;
} elsif (defined ($ModulesListFile)) {
	open MDLLIST,$ModulesListFile or die "cannot open " . $ModulesListFile;
	while (<MDLLIST>) {
		if ( $_ =~ /(.*)$/ ) {
			$ModulesListArray[$mdl++] = $& ;
		}
	}
	close MDDLLIST ;
} elsif ( defined($ModulesList) ) {
	@ModulesListArray = split (/,/,$ModulesList) ;
}

#### then parse the files for open form or open window
$mdl=0;
while (defined($ModulesListArray[$mdl])) {
	if ( -r $ModulesListArray[$mdl] ) {
		open MODULE,$ModulesListArray[$mdl] or die "cannot open module " . $ModulesListArray[$mdl];
		%ModuleForms = () ;		# controls forms only once
		while ( <MODULE> ) {
			if ( /open form\s+|with form\s+"/i ) {
				if ( /open form.*from\s+\"([\w_]+)\"/i ) {
					$ModuleForms{$1} = 1;	
					#printf "%s ",$formname ;
				} elsif ( /with form\s+\"([\w_]+)\"/i ) {
					$ModuleForms{$1} = 1;	
					#printf "%s ",$formname ;
				} else {
					printf "weird syntax for form %s",$& ;
				}
				$a=1;
			}
		}
		$size = keys %ModuleForms ;
		if ( $size > 0) {
			printf "%s : ",$ModulesListArray[$mdl];
			foreach $form ( keys %ModuleForms ) {
				printf "%s ",$form ;
			}
			printf "\n" ;
		}
		close MODULE;
	}
	$mdl++
}
$a=1;
sub parse_directory {
	($InputDir,$Extension) = (@_) ;
	opendir (INPUTDIR,$InputDir) or die "Cannot open directory " . $InputDir ;
	@FilesList = ( sort readdir(INPUTDIR) );
	$fl=0;
	$mdl=0;
	FILE: while ( $srcfile = $FilesList[$fl] ) {
		if ( $srcfile eq "." || $srcfile eq ".." || $srcfile =~ /$ExcludeDir/ ) {
			$fl++;
			next FILE;
		}
		if ( defined($IncludeFiles) && $srcfile !~  $IncludeFiles ) {
			$fl++;
			next FILE;
		}
		if ( defined($ExcludeFiles) && $srcfile =~  $ExcludeFiles ) {
			$fl++;
			next FILE;
		}
		
		# parse file for open window open form
		if ($InputDir =~ /\./ ) {
			$InputDirAbs = abs_path($InputDir) ;
		}
		$fname=sprintf "%s/%s",$InputDirAbs,$srcfile;
		$fname =~ s://:/:g;
		if ( $fname =~ /$Extension$/ ) {
			$ModulesListArray[$mdl++] = $fname ;
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


sub get_form_name {
		open FGL,$fname or die "cannot open " . $fname ;
		while (<FGL> ) {
			next if /^\s*--|^\s*$|^\s*#/ ;
			if ( $_ !~ /open form\s+ \"([\w_]+)\"/ ) {
				next;
			} else {
				printf "%s: %s\n",$fname,$1;
			}
		}
}
