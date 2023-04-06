#!/usr/bin/perl
# Description  : this package contains generic functions
# (c) Copyright Begooden-IT Consulting 2010-2014
# Author eric.vercelletto@begooden-it.com
#  "@(#)$Id: Misc.pm 403 2016-09-15 09:30:43Z  $"
# $Rev: 403 $                                             last commit revision number
# $Author: $                                          last commit author
# $Date: 2016-09-15 11:30:43 +0200 (jeu., 15 sept. 2016) $ last commit date
package Ffg::Misc;
$ID="\$Id: \$";
BEGIN {
	$FFGDIR=$ENV{"FFGDIR"};
	if ( length($FFGDIR) == 0 ) {
		die "Please set FFGDIR environment variable";
	}
	eval "use lib \"$FFGDIR/incl\"";
	die "$@\n" if ($@);
} # End BEGIN

require Exporter;

our @ISA		= qw(Exporter);
our @EXPORT		= qw(
	input
	LF
	print_fgltarget_file
	print_fglproject_file
	uniq
	get_eclipse_project_dir
	);
our $VERSION	= 1.0;
use File::Basename;

sub inputs {
my ( $question,$required) = (@_) ;
printf "%s: ",$question ;
my $answer = <STDIN> ;
chomp ( $answer);
if ( $required == 1 && length($answer) == 0 ) {
	$answer = "#required#" ;
}
return $answer;
}

sub LFs {
	if (defined($_[0])) {
		my $MODULE = $_[0] ;
	} else {
		$MODULE = $SRCHANDLE ;
	}
	printf $MODULE "\n";
	$OutLineNum++;
}

sub  print_fglproject_file {
my ($fglprojectfile,$programname) = ( @_ );
	open FGLPROJECTFILE,$fglprojectfile or die "Cannot open .fglproject file " . $fglprojectfile;
	while (<FGLPROJECTFILE> ) {
		if (/buildTarget .*name=\"${programname}\"/) {
			close FGLPROJECTFILE;
			return 1;     # the program exists in the project
		}
	}
	close FGLPROJECTFILE;
	return -1 
} # end sub  print_fglproject_file

sub  print_fgltarget_file {
my ( $FglTargetFile,$ProjectDir,$Qx4glLocation,$QxPerLocation,$ProgramName,$ModuleListPtr,$FormListPtr,$LibListPtr) = (@_ );
# create the fgltarget file

open FGLTARGETFILE, ">$FglTargetFile" or die "Cannot create fgltarget file " . $FglTargetFile ;

# Reset the libaries for this program
%ThisProgramLibraries = () ;
my @ModuleList = @$ModuleListPtr;
my @FormList = @$FormListPtr;
my @LibList = @$LibListPtr;

# Take lowest level of location
my $FglPath=basename($Qx4glLocation);
my $FrmPath=basename($QxPerLocation);

#	if ( $ModuleList[$mdl] =~ /[\/\\](${FglPath}[\\\/])/ ) {
#		$ModulePath=sprintf "%s%s",$1,$';
#	} else {
#		$a=1;
#	}
printf "Creating the Program %s in Lycia Project %s\n",$ProgramName,basename($ProjectDir);
my $message = <<"ENDFGLTRGF" ;
<?xml version="1.0" encoding="UTF-8"?>
<fglBuildTarget xmlns="http://namespaces.querix.com/lyciaide/target" name="$ProgramName" type="fgl-program">

ENDFGLTRGF
printf FGLTARGETFILE $message;

# Libraries reinit for every program
#if (defined($CLibraryName)) {
	#undef $CLibraryName ; 
#}
# print modules in fgltarget file
# one element / module

##################################################
# handle libraries
##################################################
my $libn=0;
while (defined($LibList[$libn])) {
	if ( $libn == 0 ) {
		printf FGLTARGETFILE "  <libraries>\n";
	} 
	printf FGLTARGETFILE "    <library name=\"%s\" dynamic=\"false\" location=\"\"/>\n",$LibList[$libn];
  
	if ( $libn == $#LibList ) {
		printf FGLTARGETFILE "  </libraries>\n\n";
	} 
	$libn++;
}

my $BaseProjectDir=basename($ProjectDir);

##################################################
# loop on 4gl regular modules
my $mdl=0 ;
my $nblines=0 ;

# get last part of $Qx4glLocation (i.e just after $BaseProjectDir)
my $SourceDir=dirname ($Qx4glLocation) ;

while (defined($ModuleList[$mdl])) {
	
	if ( $mdl == 0 ) {
		printf FGLTARGETFILE "  <sources type=\"fgl\">\n";
	} 
	$TargetDir=sprintf "%s/%s",$ProjectDir,dirname($ProgramName);
	my $ModulePath = $ModuleList[$mdl] ;
	
	# keep this regexp that is match the last occurrence of a word
#	if ( $ModuleList[$frm] =~ /($BaseProjectDir)(?!.*${BaseProjectDir})/) {
	if ( $ModuleList[$mdl] =~ /[\/\\](${FglPath}[\\\/])/ ) {
		$ModulePath=sprintf "%s%s",$1,$';
	} else {
		$a=1;
	}

	# printf FGLTARGETFILE "    <file location=\"%s/%s\"/>\n",basename($TargetDir),$$ProgramList->{ModuleList}[$mdl];
	printf FGLTARGETFILE   "    <file location=\"%s\"/>\n",$ModulePath;
	$mdl++;
}
if ($mdl > 0 ) {
	printf FGLTARGETFILE "  </sources>\n\n";
} 

my $frm=0 ;
my $nblines=0 ;
my $SourceDir=dirname ($QxPerLocation) ;
my $FormPath = $FormList[$frm] ;
while (defined($FormList[$frm])) {
	
	if ( $frm == 0 ) {
		printf FGLTARGETFILE "  <sources type=\"form\">\n";
	} 
	#$TargetDir=sprintf "%s/%s",$ProjectDir,dirname($ProgramName);
	my $FormPath = $FormList[$frm] ;
	# truncate the Form path, starting only at the Qx4glLocation 
	
	# this regexp catches the last occurrence of the word $BaseProjectDir
	#if ( $FormList[$frm] =~ /($BaseProjectDir)(?!.*${BaseProjectDir})/) {
	if ( $FormList[$frm] =~ /[\/\\](${FrmPath}[\\\/])/ ) {
		$FormPath=sprintf "%s%s",$1,$';
	} else {
		$a=1;
	}
	#if ( $FormList[$frm] =~ /$SourceDir/) {
	#	$FormPath=sprintf "%s",$';
	#} else {
	#	$a=1;
	#}
	
	printf FGLTARGETFILE   "    <file location=\"%s\"/>\n",$FormPath;
	$frm++;
}
if ( $frm > 0 ) {
	printf FGLTARGETFILE "  </sources>\n\n";
} 

if (defined($StdQxTheme) ) {
	if ( -f $StdQxTheme ) {
		my $TargetQxTheme = sprintf "%s.qxtheme",$ProgramName ;
		$message = <<"ENDTRGF2" ;
  <mediaFiles>
     <file client="true" location="$TargetQxTheme" type="gui-theme-file"/>
  </mediaFiles>
ENDTRGF2
		printf FGLTARGETFILE $message;
		$TargetQxTheme = sprintf "%s/%s",$ProjectSourceDir,$TargetQxTheme ;
		copy ( $StdQxTheme,$TargetQxTheme ) ;
		if ( $? == 0 ) {
			#printf LOGFILE "standard qxthem file %s copied to %s\n",$StdQxTheme,$TargetQxTheme ;
		} else {
			#printf LOGFILE "ERROR! standard qxthem file %s CANNOT BE COPIE TO to %s\n",$StdQxTheme,$TargetQxTheme ;
		}
	 } else {
		#printf LOGFILE "ERROR! standard qxthem file %s CANNOT BE FOUND\n",$StdQxTheme ;
	}
}
printf FGLTARGETFILE "</fglBuildTarget>\n";
close FGLTARGETFILE ;
} # end print_fgltarget_file

sub uniq {
	my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub get_eclipse_project_dir {
	my ($QxWorkspace,$ProjectName) = ( @_ );
	my $filename=sprintf "%s/.metadata/.plugins/org.eclipse.core.resources/.projects/%s/.location",$QxWorkspace,$ProjectName;
	#my $filename=sprintf "%s/%s/.location",$LyciaProjectsDir,$ProjectName;
	# $filename = "I:\\Users\\BeGooden-IT\git\\.metadata\\.plugins\\org.eclipse.core.resources\\.projects\\MaiaERP\\.location" ;
	if ( -r $filename) {
		open PROJECTLOCATION,$filename or die "Cannot open project location file " . $filename;
		while (<PROJECTLOCATION>) {
			if ( /file:\/([\w:\/\\\-]+)/) {
				my $ProjectLocation=$1;
				close PROJECTLOCATION;
				return $ProjectLocation;
			}
		}
	} else {
		my $ProjectLocation=sprintf "%s/%s",$QxWorkspace,$ProjectName;
		if ( -d $ProjectLocation) {
			return $ProjectLocation;
		} 
	}
	return "NotFound";
}