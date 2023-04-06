#!/usr/bin/perl
# Description  :  this script parses directories to check 
# encoding conformity with Doxyfile definitions
# (c) Copyright Begooden-IT Consulting 2010-2015
# Author eric.vercelletto@begooden-it.com
#  "@(#)$Id: fglaacheck.pl 366 2016-07-24 14:49:46Z  $:"
# $Rev: 366 $:                                             last commit revision number
# $Date: 2016-07-24 16:49:46 +0200 (dim., 24 juil. 2016) $: last commit date

use Getopt::Long;
use File::Basename;
use File::Copy;
use Cwd 'abs_path';
usage () if ( ! GetOptions(
	"inputdir=s"=>\$InputDir,		# input directory, where the source files are
	"doxyfile=s"=>\$Doxyfile,		# Doxyfile to be taken, defaut is ./Doxyfile
	"convert"=>\$DoConvert,			# Convert file if needs to be converted
	"fromconvert=s"=>\$ConvertFrom,	# Convert file from this encore
	"equivencode=s"=>\$EncodeEquivalent,	# equivalent codepage to fix what the file command returns and what the OS supports (ex: ISO-8859-1 <=> ISO-8859)
	"toconvert=s"=>\$ConvertTo, 	# Convert file to this encode
	"pattern=s"=>\$Patterns, 		# file patterns ( .4gl, .ec etc...
	"includefiles=s"=>\$IncludeFiles, 		# file patterns ( .4gl, .ec etc...
	"excludefiles=s"=>\$ExcludeFiles, 		# file patterns ( .4gl, .ec etc...
	"includecodepage=s"=>\$IncludeCodePage, 		# file patterns ( .4gl, .ec etc...
	"excludecodepage=s"=>\$ExcludeCodePage, 		# file patterns ( .4gl, .ec etc...
	"backupdir=s"=>\$BackupDir, 	# Directory where source files are backuped
	"excludedir=s"=>\$ExcludeDir, 	# Directory where source files are backuped
	"recursive=s"=>\$Recursive, 	# Directory where source files are backuped
	"force"=>\$Force, 				# Directory where source files are backuped
	"listonly"=>\$ListOnly, 			# just list the files
	) ) ;

if (!defined($Doxyfile)) { # (Doxyfile)
	$Doxyfile="Doxyfile";
}

if (!defined($ExcludeDir)) { # (ExcludeDir)
	$ExcludeDir="xXzM98z#@~ aa127";
}
if (defined($EncodeEquivalent) ) {
	@EquivStr=split(/[=:]/,$EncodeEquivalent);
	$EncodeEquiv{$EquivStr[0]} = $EquivStr[1];
}

if (!defined($BackupDir) && defined($DoConvert)) { 
	printf "Caution: you want to operate the conversion without any backup, are you sure? (Yes/No)" ;
	$Rep=<STDIN> ;
	if ( $Rep =~ /Yes/ ) {
		$a=1;
	} else {
		printf "Exiting, launch again with the -backup <dirname> option" ;
		exit (0);
	}
}

if (!defined($InputDir)) { 
	@InputDirectory=GetDoxyFParam($Doxyfile,"INPUT");
} else {
	@InputDirectory=split (/:/,$InputDir);
}

if (defined($ConvertTo)) {
	$InputEncoding=$ConvertTo;
} else {
	$InputEncoding=GetDoxyFParam($Doxyfile,"INPUT_ENCODING");
}

if (defined($Recursive)) {
	if ( $Recursive =~ /^[Yy]/ ) {
		$Recursive = "Yes" ;
	} else {
		$Recursive = "No" ;
	}
} else {
	$Recursive=GetDoxyFParam($Doxyfile,"RECURSIVE");
}

if (defined($Patterns) ) {
        @FilePattrn = split (/[:,]/,$Patterns) ;
} else {
        @FilePattrn=GetDoxyFParam($Doxyfile,"FILE_PATTERNS");
}
@FilePatterns=map{s/(.*)$/$1\$/;$_ } @FilePattrn ;


check_files_encoding ($InputEncoding,\@InputDirectory,$Recursive,\@FilePatterns);
if (defined($DoConvert)) {
	printf "                         Converted Files #        : %d\n",$Converted;
	printf "                         Conversion Errors        : %d\n",$ErrorConvert++;
} else {
	printf "Encoding check finished: Correct Encoding Files #: %d\n",$GoodEncoding;
	printf "                         Unconform Encoded Files# : %d\n",$BadEncoding;
}

							
sub check_files_encoding {
($InputEncode,$InpDir,$Recursive,$FilPat) = ( @ _ );
@InputDir=@$InpDir;
@FilePatterns=@$FilPat;
$Extens=join('|',@FilePatterns);
$Extens =~ s/\*\./\\\./g;

$DirNum=0;
while ( $DirNum <= $#InputDir ) {
	&parse_directory ($InputDir[$DirNum],$Extens) ;
	$DirNum++;
}
} # end sub check_files_encoding

sub parse_directory {
	($InputDir,$Extension) = (@_) ;
	opendir (INPUTDIR,$InputDir) or die "Cannot open directory " . $InputDir ;
	@FilesList = ( sort readdir(INPUTDIR) );
	$fl=0;
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
		
		if ( $InputDir =~ /\./ ) {
			$InputDirAbs = abs_path($InputDir) ;
		}
		$fname=sprintf "%s/%s",$InputDir,$srcfile;
		$fname =~ s://:/:g;
		if ( $fname =~ /$Extension/ ) {
			$cmd=sprintf "file %s|",$fname;
			open FILECMD,$cmd ;
			$ThisFileEncodingLine=<FILECMD>;
			if ( $ThisFileEncodingLine =~ /:\s+(.*)\s+text/ ) {
				$ThisEncode=$1;
				if ( defined($IncludeCodePage) && $ThisEncode !~  $IncludeCodePage ) {
					$fl++;
					next FILE;
				}
				if ( defined($ExcludeCodePage) && $ThisEncode =~  $ExcludeCodePage ) {
					$fl++;
					next FILE;
				}
				if (defined($ListOnly) ) {
					printf "%s : %s\n",$fname,$ThisEncode;
					$fl++;
					next FILE ;
				}
				if ( $ThisEncode ne $InputEncoding ) {
					if ( !defined($DoConvert) ) {
						$BadEncoding++;
						printf "File %s has not correct encoding %s<>%s\n",$fname,$ThisEncode,$InputEncoding;
					} else {
						if (defined($EncodeEquiv{$ThisEncode})) {
							# file command returns ISO-xxx but the OS supports ISO-xxx-1
							# $EncodeEquiv makes the translation
							$ConvertFrom=$EncodeEquiv{$ThisEncode};
						}
						if (defined($BackupDir) ) {
							$ThisBackupDir=sprintf "%s/%s",$BackupDir,$InputDir;
							if ( ! (-d $ThisBackupDir) ) {
								$cmd=sprintf "mkdir -p %s",$ThisBackupDir;
								system($cmd) ;
							}
							$BckFileName=sprintf "%s/%s",$ThisBackupDir,basename($fname);
							if ( ! (-f $BckFileName) ) {
								# copy only once to avoid overwriting with a corrupt file
								copy ($fname,$BackupDir);
								if ( $errno == 0 ) {
									$a=1;
								} else {
									printf "Could not backup file %s, skipping\n",$fname;
									next FILE;
								}
								
							}
						}
						if (defined($ConvertFrom)) {
							$ConvCmd=sprintf "iconv -f %s -t %s ",$ConvertFrom,$InputEncoding ;
						} else {
							$ConvCmd=sprintf "iconv -f %s -t %s ",$ThisEncode,$InputEncoding;
						}

						$ConvertedFile=sprintf "%s.CNV",$fname ;
						$ConvCmd = sprintf "%s < %s > %s",$ConvCmd,$fname,$ConvertedFile ;
						$status=system($ConvCmd);
						if ($status == 0 ) {
							unlink ($fname);
							rename $ConvertedFile,$fname ;
							if ( $errno == 0 ) {
								printf "%s converted to %s\n",$fname,$InputEncoding ;
								$Converted++;
							} else {
								$ErrorConvert++;
								printf "FAILED to convert %s to %s\n",$fname,$InputEncoding ;
							}
						} else {
							printf "FAILED to convert %s to %s\n",$fname,$InputEncoding ;
							$ErrorConvert++;
						}
					}
				} else {
					$GoodEncoding++;
				}
			} else {
				if ( $ThisFileEncodingLine =~ /:\s+(.*)\n/ ) {
					$BadEncoding++;
					printf "File %s has not correct encoding %s<>%s\n",$fname,$1,$InputEncoding;
				}
			}
		} else {
			if ( $Recursive eq "YES" && -d ($fname) && $fname !~ /^\./ ) {
				parse_directory ($fname) ;
			} else {
				$a=1;
			}
		}
		$fl++ ;
	}  # end while FILE
}
sub GetDoxyFParam {
( $DoxyFile,$Param ) = ( @_ ) ;
open DOXYFILE,$DoxyFile or die "Cannot open Doxyfile " . $DoxyFile ;
$ParamFound=0;
while (<DOXYFILE>) {
	next if (/^#/ ) ;
	if ( /^$Param\s*=\s+/ ) {
		@Value= split (/\s+/,$');
		$ParamFound=1;
		if ( $Value[$#Value] =~ /\\/ ) { #Multi Line
			$MultiLine=1;
			$_ .= <DOXYFILE>;
			redo unless eof(DOXYFILE);
			$a=1;
		} else {
			$MultiLine=0;
			@ReturnedValue=grep (!/\\$/,@Value);
			if ( $#ReturnedValue > 0 ) {
				return @ReturnedValue;
			} else {
				return $ReturnedValue[0];
			}
		}
	} 
}
if ( $ParamFound == 0 ) {
	return "NotFound";
}
}
