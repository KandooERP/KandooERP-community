#!/usr/bin/perl 
# Author : Eric Vercelletto
# (C) 2006-2010 BeGooden-IT Consulting
# http://www.kandooerp.org
# Description  : beautiful informix 4GL code beautifier
BEGIN {
        $OS_win = ($^O eq "MSWin32") ? 1 : 0;
        $OS_aix = ($^O eq "aix") ? 1 : 0;
        $OS_solaris = ($^O eq "Solaris") ? 1 : 0;
        $OS_hpux = ($^O eq "hp-ux") ? 1 : 0;
        $OS_SCO = ($^O eq "sco") ? 1 : 0;         
} # End BEGIN
use Getopt::Long;
use File::Copy;
use File::Basename;
# use Time::ParseDate;
usage () if ( ! GetOptions(
	"file=s"=>\$FileName,			# expression to select the input files
	"directory=s"=>\$DirectoryName,			# expression to select the input files
	"replace"=>\$Replace,			# expression to select the input files
	"debug"=>\$Debug,			# show indent levels
	"blocks"=>\$PrintBlocks,			# show indent levels
	"force"=>\$ForceReplace			# forces replace even if file has not been commited (Caution!!!)
	) ) ;

if ( !defined ($FileName) && !defined($DirectoryName) ) {
	die "usage: beautify.pl -f <filename> | -directory <dir name> [-replace]" ;
}
$KANDOOTOOLSTEMPDIR=$ENV{"KANDOOTOOLSTEMPDIR"} ;
if ( $KANDOOTOOLSTEMPDIR eq "" ) {
	if ($^O =~ /win/i ) {
		$KANDOOTOOLSTEMPDIR="C:\\TEMP" ;
	} else {
		$KANDOOTOOLSTEMPDIR="/tmp" ;
	}
}

%FglSyntax=() ;
($indent_block,$IndentCommentsFullLeft,$SpecialBlocksInit,$SpecialBlocksEvents) = read_ifgl_syntax () ;

if (!defined($DirectoryName)) {
	if ($FileName =~ /[\/\\]+/ ) {
		$DirectoryName=dirname($FileName);
		$FileName=basename($FileName);
	} else {
		$DirectoryName=".";
	}
}
if (!defined($FileName)) {
	$FileName="\.4gl\$" ;   # All 4gl Files
}

if ( -d $DirectoryName ) {
	opendir (DIRECTORY,$DirectoryName) or die "Cannot open directory " . $DirectoryName ;
	@FilesList0 = grep (/${FileName}/, sort readdir(DIRECTORY) );
	@FilesList=map { s/^/$DirectoryName\//;$_ } @FilesList0;
	if ( $DirectoryName !~ /\.$|\.\/$/ ) {
	}
} 
my $TempDir =  $KANDOOTOOLSTEMPDIR . "/" . $DirectoryName;
if ( -d $TempDir ) {
	$a=1;
} else {
	mkdir $TempDir;
}
$fln=0;
$FilesNumber=$#FilesList+1;
while(defined($FilesList[$fln])) {	
	printf "%d/%d ",$fln+1,$FilesNumber;
	beautify_4gl_file ( $FilesList[$fln] ) ;
	$fln++;
}

sub beautify_4gl_file {
# this function	reads the 4gl and makes it beautifully layed out
$module_name=$_[0];

if (! defined ($indent_block) ) {
	$indent_block="    ";
}

if ( defined ($Debug) && defined ($Replace)) {
		die "Debug option not compatible with Replace option, exiting";
}

if (defined($Replace) && !defined($ForceReplace)) {
	my $cmd="git status|" ;
	print ( open GIT,$cmd  ) ? 'Git Repository' : 'Repository not handled by git' ;
	while (<GIT>) {
		if (/#\s+modified:\s+$FileName/ ) {
			printf "Please commit this file %s before beautifying it\nExiting\n",$FileName;
			exit(1);
		}
	}
	close GIT;
}
for ( $sep=1;$sep<=$separator_number;$sep++ ) {
	$indent_block=sprintf "%s%s",$indent_block,$separator ;
}
if  ( $OS_win == 1 ) {
	$module_name=~ s/\//\\/g ;
}


open ( MODULE,$module_name)  ;
$StartTime=time();
$extension= cvt_TIS_DSF($StartTime,"yyyymd_hms") ;
$BeautifyTimeStamp= cvt_TIS_DSF($StartTime,"yyyy-mm-dd h:m:s") ;
$BeautyFile=sprintf "%s/%s.bty.%s",$KANDOOTOOLSTEMPDIR,$module_name, $extension ;
$BackupFile=sprintf "%s/%s.bkp.%s",$KANDOOTOOLSTEMPDIR,$module_name, $extension ;

if ( $Replace ) {
	copy ( $module_name,$BackupFile ) ;
}
open ( BEAUTYFILE,">$BeautyFile") ;

#if ( $? == 0 ) { return } ;
$indent_level=0;
$IndentPosition=0;
$spaces="";
$ind=0;
# build the indenting spaces string
$InComments=0;
$InReportBlock=0;
$InitiateSpecialBlock=0;
$PrintedLines=0;
$IsInAFunctionBlock=0;
$FJS=0;
undef %NewBlock ;
undef $BlockStartsAt;
undef @Line;
undef $line;
undef $Before;
undef $After;
undef $Structure;
undef $PrintedLines;
undef $linenumber;
if ( defined($Debug)) {
	$dbg="<  ";
} else {
	$less="> ";
}
READMODULE15: while ( $line=<MODULE> ) {
	$linenumber++;
	if ( defined($Debug)) {
		# print original line for reference
		$DbgLineNumber=$. ;
		printf  BEAUTYFILE "%6d:     %s",$DbgLineNumber,$line;
	}
	# clean trailing spaces and tabs
	$line =~ s/// ;
	$line =~ s/\s+$/\n/g;

	# empty line: print and continue while
	if ( $line =~ /^$/ ) {
		# if line is empty, print and continue read
		$PrintedLines++;
		print_dbg_header() ;
		printf BEAUTYFILE "%s",$line ;
		next READMODULE15;
	}

	# handle single line comments : print and continue while
	if( $line =~ /^\s*(#|^\s*--|^\s*\{.*\})/ ) {
		$line =~ s/^\s+// ;
		
		if ( $IsInAFunctionBlock == 1 ) {
			# indent comments only if in a function block
			indent_line ($IndentPosition,$indent_block,$FJS,0) ;
		}
		$PrintedLines++;
		print_dbg_header() ;
		printf BEAUTYFILE "%s",$line;
		next READMODULE15;
	}

	#handle multi-lines comments: print line in the block
	#if ( ( $line =~ /\{/ && !/\"[^\"]*\{[^\"]*\"/ && $line !~ /\}/ ) || $InComments ) {
	if  ( $line =~ /\{/ && !/\"[^\"]*\{[^\"]*\"/ && $line !~ /\}/ ) {
		# if line has { but not }, i.e the comments continues on next lines
		$InComments=1;
		if ( $IsInAFunctionBlock == 1 ) {
			# indent comments only if in a function block
			indent_line ($IndentPosition,$indent_block,$FJS,0) ;
		}
		$PrintedLines++;
		print_dbg_header() ;
		printf BEAUTYFILE "%s",$line;
		next READMODULE15;
	} elsif ( $InComments == 1 ) {
		if ( $line =~ /Source code beautified by \w+ on (\d{4}-\d{2}-\d{2}\s-\d{2}:-\d{2}:-\d{2})/ ) {
			$line =~ s/$1/$BeautifyTimeStamp\t/;
			$AdditionalWords=0;
		} elsif ( $line =~ /\$Id: \$/ ) {
			$BeautifiedOnString=sprintf "Source code beautified by %s on %s",basename($0),$BeautifyTimeStamp;
			$line =~ s/^\s+/\t$BeautifiedOnString\t/;
			$AdditionalWords=8;
		}
		if ( $IsInAFunctionBlock == 1 ) {
			# indent comments only if in a function block
			indent_line ($IndentPosition,$indent_block,$FJS,0) ;
		}
		$PrintedLines++;
		print_dbg_header() ;
		printf BEAUTYFILE "%s",$line;
		if (  $line =~ /\}/ ) {
			$InComments=0;
		}
		next READMODULE15;
	} elsif ( $line =~ /(\{.*\})/ ) {
		#if line has a self closing comments
		#if there any command before comments ?
		if ( $` =~ /\s*\w+/ ) {
			# the line needs to be processed
			$a=1;
		} else {
			# this line is only a comment goto next line
			if ( $IsInAFunctionBlock == 1 ) {
				# indent comments only if in a function block
				indent_line ($IndentPosition,$indent_block,$FJS,0) ;
			}
			$PrintedLines++;
			print_dbg_header() ;
			printf BEAUTYFILE "%s",$line;
			next READMODULE15;
		}
		$InComments=0;
	} else {
		$a=1;
		#this line will be processed normally
	}

	# protect quoted separators  ( ex: "    Item   ", replace \s by '#@&' )
	# $Remainder = $_ ;
	$Remainder = $line ;

	# separate comments in the middle of the line if any
	#if ( /#/ && !(/--#/) && !(/using\s+\".*#.*\"/i) ) {
		#$ExecLine=$` ;
		#$remainder=$';
		#$remainder =~ s/\A\[ \t]+/ / ;
	#} else {
		#$ExecLine=$line ;
		#$remainder="";
	#}
	#	
	# special cases of if( or when( etc: we add a blank in between for better line split
	if ( $line =~ /\b(if)\(/i  
	||  $line =~ /\b(when)\(/i 
	|| $line =~ /\b(while)\(/i 
	|| $line =~ /\b(values)\(/i 
	|| $line =~ /\b(for)\(/i ) {
		$line =~ s/\(/ \(/ ;
	}	
	# fix forms like "on key(" by "on key ("
	if ($line =~ /on key\(|on action\(/i ) {
		$line =~ s/\(/ (/g ;
	}
	@Line=split " ",$line ;
	# Check whether possible to use also ',' as separator
	$JustSubsted=0;
	$JustAdded=0;
	$word=0;
	$BlockNum+0;
	
	$Before="=";
	$After="=";
	if ( $. != $linenumber ) {
		$a=1;
	}
	# start evaluating blocks end because block init regexp also match block end regexp ( FUNCTION / END FUNCTION )
	if ($line =~ /$FunctionBlocksEnd/i ) {
		$Function=uc($1.$2.$3.$4.$5);
		$Before=0;
		$After="=";
		$IndentPosition=0;
		$IsInAFunctionBlock=0;
		$BlockStartsAt=SearchBlockInit($Function,$linenumber);
		$NewBlock{$BlockStartsAt}->{EndPosition}=$linenumber;
		if ( defined($Debug) && $Debug == 1 ) {
			my $Idt=$indent_block x $Before ;
			printf "%s%s\t%s\t%4d\t%d\t%d\n",$Idt,$NewBlock{$BlockStartsAt}->{BlockType},$NewBlock{$BlockStartsAt}->{Name},
			$NewBlock{$BlockStartsAt}->{StartPosition},$NewBlock{$BlockStartsAt}->{EndPosition},$NewBlock{$BlockStartsAt}->{IndentPosition} ;
		}
		# delete $NewBlock{$BlockStartsAt} ;
	} elsif ( $line =~ /^\s*COMMIT\s*WORK/i ) {
		$Before="-";
		$After="=" ;
		$BlockStartsAt=SearchBlockInit("BEGIN",$linenumber);
		$NewBlock{$BlockStartsAt}->{EndPosition}=$linenumber;
		if ( defined($Debug) && $Debug == 1 ) {
			my $Idt=$indent_block x $IndentPosition ;
			printf "%s%s\t%4d\t%d\t%d\n",$Idt,$NewBlock{$BlockStartsAt}->{BlockType},$NewBlock{$BlockStartsAt}->{StartPosition},
			$NewBlock{$BlockStartsAt}->{EndPosition},$NewBlock{$BlockStartsAt}->{IndentPosition} ;
		}
	} elsif ( $line =~ /$StructureBlocksEnd/i ) {
		$Structure=uc($1.$2.$3.$4.$5.$6.$7);
		$Before="-";
		$After="=" ;
		$BlockStartsAt=SearchBlockInit($Structure,$linenumber);
		$NewBlock{$BlockStartsAt}->{EndPosition}=$linenumber;
		if ( defined($Debug) && $Debug == 1 ) {
			my $Idt=$indent_block x $IndentPosition ;
			printf "%s%s\t%4d\t%d\t%d\n",$Idt,$NewBlock{$BlockStartsAt}->{BlockType},$NewBlock{$BlockStartsAt}->{StartPosition},
			$NewBlock{$BlockStartsAt}->{EndPosition},$NewBlock{$BlockStartsAt}->{IndentPosition} ;
		}
	} elsif ( $line =~ /$ReportBlocksEnd/i ) {
		# these instructions are start of block and end of block at the same time
		#$Report=uc($1.$2.$3.$4.$5);
		#$Before="-";
		#$After="=" ;
		#$BlockStartsAt=SearchBlockInit($Report,$linenumber);
		#$NewBlock{$BlockStartsAt}->{EndPosition}=$linenumber;
		#if ( defined($Debug) && $Debug == 1 ) {
			#my $Idt=$indent_block x $IndentPosition ;
			#printf "%s%s\t%4d\t%d\t%d\n",$Idt,$NewBlock{$BlockStartsAt}->{BlockType},$NewBlock{$BlockStartsAt}->{StartPosition},
			#$NewBlock{$BlockStartsAt}->{EndPosition},$NewBlock{$BlockStartsAt}->{IndentPosition} ;
		#}
		$BlockType = uc($1.$2.$3.$4.$5.$6.$7.$8.$9);
		if ( $InReportBlock == 1 ) {
			#close the previous Block
			#$Report=$1.$2.$3.$4.$5;
			#$BlockStartsAt=SearchBlockInit($Report,$linenumber);
			$BlockStartsAt=SearchBlockInit("^REPORT",$linenumber);
			$Before=$NewBlock{$BlockStartsAt}->{IndentPosition} + 1;
			#$Before="=";
			$After="=" ;
			$NewBlock{$BlockStartsAt}->{EndPosition}=$linenumber;
			if ( defined($Debug) && $Debug == 1 ) {
				my $Idt=$indent_block x $IndentPosition ;
				printf "%s%s\t%4d\t%d\t%d\n",$Idt,$NewBlock{$BlockStartsAt}->{BlockType},$NewBlock{$BlockStartsAt}->{StartPosition},
				$NewBlock{$BlockStartsAt}->{EndPosition},$NewBlock{$BlockStartsAt}->{IndentPosition} ;
			}
			$InReportBlock=0;
		} 
		if ( $InReportBlock != 1 ) {
			$InReportBlock=1;
			$NewBlock{$linenumber}->{BlockType}=$BlockType ;
			$InitiateReportBlock=1;
			$CurrentReportBlockIndentLevel=$IndentPosition;
			$ReportBlockEventNum=0;
			#$Before="=";
			$BlockStartsAt=SearchBlockInit("^REPORT",$linenumber);
			$Before=$NewBlock{$BlockStartsAt}->{IndentPosition} + 1;
			## $After="+" ;
			$After="=" ;
			$NewBlock{$linenumber}->{StartPosition}=$linenumber ;
			$NewBlock{$linenumber}->{IndentPosition}=$IndentPosition;
		}
	} elsif ($line =~ /$SpecialBlocksEnd/i ) {
		$Special=uc($1.$2.$3.$4.$5.$6.$7.$8.$9);
		$After="=" ;
		$BlockStartsAt=SearchBlockInit($Special,$linenumber);
		$Before=$NewBlock{$BlockStartsAt}->{IndentPosition};
		$NewBlock{$BlockStartsAt}->{EndPosition}=$linenumber;
		if ( defined($Debug) && $Debug == 1 ) {
			my $Idt=$indent_block x $Before ;
			printf "%s%s\t%4d\t%d\t%d\n",$Idt,$NewBlock{$BlockStartsAt}->{BlockType},$NewBlock{$BlockStartsAt}->{StartPosition},
			$NewBlock{$BlockStartsAt}->{EndPosition},$NewBlock{$BlockStartsAt}->{IndentPosition} ;
		}
	} elsif ( $line =~ /$FunctionBlocksInit/i ) {
		# GLOBALS,MAIN, FUNCTION, REPORT
		if ( $line !~ /^\s*globals\s*\".*\"/i ) {
				# i.e if this is not a single line globals "filename" definition
				$NewBlock{$linenumber}->{BlockType}=uc($1.$2.$3.$4) ;
				$IsInAFunctionBlock=1;
				$Before=0;
				if (defined($DoNotIndentAfterFunction) && $DoNotIndentAfterFunction == 1 ) {
					$After="=";
				} else {
					$After="+";
				}
				$IndentPosition=0;
				if ( $line =~ /FUNCTION\s+(\w+)/i ) {
					$NewBlock{$linenumber}->{Name}=$1;
				} elsif ( $line =~ /REPORT\s+(\w+)/i ) {
					$NewBlock{$linenumber}->{Name}=$1;
				}
				$NewBlock{$linenumber}->{StartPosition}=$linenumber ;
				$NewBlock{$linenumber}->{IndentPosition}=$IndentPosition;
		}
	} elsif ( $line =~ /$StructureBlocksInit/i ) {
		# simple blocks that have a starting token, an ending token and no sub events inside
		#IF, WHILE, FOR, FOREACH ... RECORD
		$NewBlock{$linenumber}->{BlockType}=uc($1.$2.$3.$4.$5.$6);
		$InitiateStructureBlock=1;
		$Before="=";
		$After="+" ;
		$NewBlock{$linenumber}->{StartPosition}=$linenumber ;
		$NewBlock{$linenumber}->{IndentPosition}=$IndentPosition;
	} elsif ( $line =~ /^\s*BEGIN\s+WORK\b/i ) {
		# indent transactions
		$NewBlock{$linenumber}->{BlockType}="BEGIN" ;
		$InitiateStructureBlock=1;
		$Before="=";
		$After="+" ;
		$NewBlock{$linenumber}->{StartPosition}=$linenumber ;
		$NewBlock{$linenumber}->{IndentPosition}=$IndentPosition;
	} elsif ($line =~ /$ReportBlocksEvents/i ) {
		# Events in reports! PAGE HEADER, BEFORE GROUP, ON EVERY ROW etc ...
		$Event=$1.$2.$3.$4.$5.$6.$7.$8.$9;
		$BlockStartsAt=SearchBlockInit("^OUTPUT\$|^FORMAT\$",$linenumber);
		$Before=$NewBlock{$BlockStartsAt}->{IndentPosition} + 1;
		$After="+" ;
		$SpecialBlockEventNum++;
		$NewBlock{$linenumber}->{BlockType}=$Event;
		$NewBlock{$linenumber}->{IndentPosition}=$IndentPosition;
		$NewBlock{$linenumber}->{StartPosition}=$linenumber ;
	} elsif ($line =~ /$ReportBlocksInit/i ) {
		# FORMAT, OUTPUT   : those keywords mean begin and end of the block
		$BlockType = uc($1.$2.$3.$4.$5.$6.$7.$8.$9);
		if ( $InReportBlock == 1 ) {
			#close the previous Block
			#$Report=$1.$2.$3.$4.$5;
			#$BlockStartsAt=SearchBlockInit($Report,$linenumber);
			$BlockStartsAt=SearchBlockInit("^REPORT",$linenumber);
			$Before=$NewBlock{$BlockStartsAt}->{IndentPosition} + 1;
			#$Before="=";
			$After="=" ;
			$NewBlock{$BlockStartsAt}->{EndPosition}=$linenumber;
			if ( defined($Debug) && $Debug == 1 ) {
				my $Idt=$indent_block x $IndentPosition ;
				printf "%s%s\t%4d\t%d\t%d\n",$Idt,$NewBlock{$BlockStartsAt}->{BlockType},$NewBlock{$BlockStartsAt}->{StartPosition},
				$NewBlock{$BlockStartsAt}->{EndPosition},$NewBlock{$BlockStartsAt}->{IndentPosition} ;
			}
			$InReportBlock=0;
		} 
		if ( $InReportBlock != 1 ) {
			$InReportBlock=1;
			$NewBlock{$linenumber}->{BlockType}=$BlockType ;
			$InitiateReportBlock=1;
			$CurrentReportBlockIndentLevel=$IndentPosition;
			$ReportBlockEventNum=0;
			#$Before="=";
			$BlockStartsAt=SearchBlockInit("^REPORT",$linenumber);
			$Before=$NewBlock{$BlockStartsAt}->{IndentPosition} + 1;
			## $After="+" ;
			$After="=" ;
			$NewBlock{$linenumber}->{StartPosition}=$linenumber ;
			$NewBlock{$linenumber}->{IndentPosition}=$IndentPosition;
		}
	} elsif ($line =~ /$SpecialBlocksEvents/i ) {
		# Events in special blocks! BEFORE INPUT, AFTER, ON ACTION, COMMAND, COMMAND KEY etc ...
		## replace by searchLastStart $Before=$CurrentSpecialBlockIndentLevel+1;
		$Event=uc($1.$2.$3.$4.$5.$6.$7.$8.$9);
		if ( $Event =~ /^WHEN\b|^OTHERWISE\b/i ) {
			$BlockStartsAt=SearchBlockInit("^CASE",$linenumber);
			$Before=$NewBlock{$BlockStartsAt}->{IndentPosition} + 1;
		} elsif ( $Event =~ /\bBEFORE\s+MENU\b|\bAFTER\s+MENU\b|\bCOMMAND\s+KEY\b|\bCOMMAND\b/i ) {
			$BlockStartsAt=SearchBlockInit("^MENU\$",$linenumber);
			$Before=$NewBlock{$BlockStartsAt}->{IndentPosition} + 1;
		} elsif ( $Event =~ /\w+\sFIELD|\w+\s+ROW|\w+\s+INSERT|\w+\s+DELETE|\w+\s+INPUT|\w+\s+DISPLAY|\bON\s+ACTION|\bON\s+KEY\b|\w+\s+CONSTRUCT\b/ ) {   # on action can be menu or display or input
			$BlockStartsAt=SearchBlockInit("^INPUT\$|^CONSTRUCT\$|^DISPLAY\$|^MENU\$",$linenumber);
			$Before=$NewBlock{$BlockStartsAt}->{IndentPosition} + 1;
		} else {
			$a=1;
		}
		$After="+" ;
		$SpecialBlockEventNum++;
		$NewBlock{$linenumber}->{BlockType}=$Event;
		$NewBlock{$linenumber}->{IndentPosition}=$IndentPosition;
		$NewBlock{$linenumber}->{StartPosition}=$linenumber ;
	} elsif ($line =~ /$SpecialBlocksInit/i ) {
		# INPUT, CONSTRUCT, MENU, DISPLAY, CASE etc
		# Check if this instruction is a multi-line block, that is with END xxx
		$BlockType = uc($1.$2.$3.$4.$5.$6.$7.$8.$9);
		if ( check_block_has_events($module_name,$linenumber,$BlockType) ) {
			$NewBlock{$linenumber}->{BlockType}=$BlockType ;
			$NewBlock{$linenumber}->{BlockType} =~ s/\s*ARRAY\s*// ;  # INPUT & DISPLAY ARRAY are INPUT and DISPLAY
			$InitiateSpecialBlock=1;
			$CurrentSpecialBlockIndentLevel=$IndentPosition;
			$SpecialBlockEventNum=0;
			
			$Before="=";
			## $After="+" ;
			$After="=" ;
			$NewBlock{$linenumber}->{StartPosition}=$linenumber ;
			$NewBlock{$linenumber}->{IndentPosition}=$IndentPosition;
		}
	} else {
		#Not a special case, try to find a rule
		( $Before, $After) = GetIndentRule (3,@Line) ;
	}
	
	# check for list
	if ( m/INPUT\s+BY\s+NAME\s+(.*)WITHOUT\s+DEFAULTS/mi ) {
		$VarList=$1;
	}
	$FormerPosition=$IndentPosition ;   # for debug purpose
	# ( $Before, $After) = GetIndentRule (3,@Line) ;
	if ( $Before =~ /(\d+)/ ) {
		$IndentPosition=$1;
	} elsif ( $Before eq "+" ) {
		$IndentPosition++ ;
	} elsif ( $Before eq "-" ) {
		if ( defined($PrintBlocks) ) { 
			printf BEAUTYFILE "#Block %d %s-%d\n",$IndentPosition,$NewBlock[$IndentPosition]->{START},$NewBlock[$IndentPosition]->{END}; 
		}
		$IndentPosition--;
	}
	if ( defined($NewBlock{$BlockStartsAt}->{EndPosition})) {
		$NewBlock{$linenumber}->{IndentPosition}=$IndentPosition;
		#printf "%s\t%4d,%d\n",$NewBlock{$linenumber}->{BlockType},$NewBlock{$linenumber}->{StartPosition},$NewBlock{$linenumber}->{EndPosition}$NewBlock{$linenumber}->{IndentPosition} ;
	}

	$PrintedLines++;
	print_dbg_header() ;
	if ( $Before ne "<" ) { # line is indented full left, unconditionnaly, without impacting ident_level
		indent_line ($IndentPosition,$indent_block,$FJS,0) ;
	}
	if ( $After eq "+" ) {
		$IndentPosition++ ;
		$JustAdded=1;				# prevents from indenting more than once for a line
	} elsif ( $After eq "-" ) {
		$IndentPosition--;
		$JustSubsted=1;
	}

	# walk until any comments sign (#{})
	
	# test: @Line has no more comments in
	$InString=0;
	$ResetInStringAfter=0;
	while ( defined($Line[$word]) ) { # && $Line[$word] !~ /[{#]/ ) {
		#if this word is recognized
		if ( $line !~ /\bCALL\b|\bLET\b|\bFUNCTION\b|\bREPORT\b|\bIF\b|\bWHILE\b/i && $Line[$word] =~ /(.*)(\(.*)/ ) {
			# case when words contain (...) example char(102)
			my $StartOfWord=$1;
			my $EndOfWord=$2;
			if ( $FglSyntax{$StartOfWord}->{BEFORE} =~ /[\d\+-<=]/ ) {
				# if not a quoted string
				if ( ! ( $InString ) ) {
					printf BEAUTYFILE "%s%s ", uc($StartOfWord),$EndOfWord;
				} else {
					printf BEAUTYFILE "%s%s ",$StartOfWord,$EndOfWord;
				}
			} else {
				if ( ! ( $InString )) {
					printf BEAUTYFILE "%s%s ",lc($StartOfWord),$EndOfWord;
				} else {
					printf BEAUTYFILE "%s%s ",$StartOfWord,$EndOfWord;
					if ( $ResetInStringAfter ) {
						$InString=0;
						$ResetInStringAfter=0;
					}
				}
			}		

		} elsif ( $Line[$word] =~ /\"/ ) {
			my $quotes_count = $Line[$word] =~ tr/\"//;
			#if ( $Line[$word] =~ /^\".*\"$/ ) {
			if ( $quotes_count %2 == 0 ) {
				# if number of " is odd
				#$InString = ($InString + 1 ) %2 ;
				printf BEAUTYFILE "%s ",$Line[$word] ;
			} else {
				# starts a quote or ends a quote
				$InString = ($InString + 1 ) %2 ;
				printf BEAUTYFILE "%s ",$Line[$word] ;
				##$Line[$word] =~ s/$SubsSeparatorChar/ /g ;
			}
		} else {
			if ( $FglSyntax{uc($Line[$word])}->{BEFORE} =~ /[\d\+-<=]/ ) {
				# if not a quoted string
				if ( ! ( $InString ) ) {
					printf BEAUTYFILE "%s ", uc($Line[$word]) ;
				} else {
					printf BEAUTYFILE "%s ",$Line[$word] ;
				}
			} else {
				if ( ! ( $InString )) {
					printf BEAUTYFILE "%s ",lc($Line[$word]) ;
				} else {
					printf BEAUTYFILE "%s ",$Line[$word] ;
					if ( $ResetInStringAfter ) {
						$InString=0;
						$ResetInStringAfter=0;
					}
				}
			}		
		}
		$word++ ;
	}

	# print comments after hash sign, forget indent rules
	if ( $remainder ne "" ) {
		printf BEAUTYFILE "# %s",$remainder ;
	}

	#while ( defined($Line[$word]) ) {
		#printf BEAUTYFILE "%s ",$Line[$word] ;
		#$word++ ;
	#}

	# -> consider case where 'THEN' is the only word on the line
	#if (( ($FglSyntax{uc($Line[$word-1])}->{AFTER} eq "+" && ! ($JustAdded)) && $Line[$word-2] !~ /END|EXIT|CONTINUE/i  
	#&& ( $_ =~ $FglSyntax{uc($Line[$word-1])}->{FULLREGEXP} ))) {
		#$IndentPosition++;
	#} elsif ( ! ($JustSubsted) && $FglSyntax{uc($Line[$word-1])}->{AFTER} eq "-" && $Line[$word-2] !~ /END|EXIT|CONTINUE/i) {
		#if ( defined($PrintBlocks) ) { 
			##printf BEAUTYFILE "#Block %d %s-%d\n",$IndentPosition,$NewBlock[$IndentPosition]->{START},$NewBlock[$IndentPosition]->{END}; 
		#}
		#$IndentPosition--;
	#}
	printf BEAUTYFILE "\n" ;
	# prepare for next indent
	if ( $PrintedLines ne $. ) {
		$a=1;
	}
}
close  MODULE ;
close  BEAUTYFILE  ;
close CKMULTI;
undef $CkmultiOpen ;
$EndTime=time();
#

#
$Elapsed=$EndTime-$StartTime ;
if ( $Replace ) {
	printf "-> Replacing File %s, backup is %s (%d seconds) ",$module_name,$BackupFile,$Elapsed  ;
	copy ( $BeautyFile,$module_name );
	if ( $? == 0 ) {
		unlink ( $BeautyFile ) ;
	}
} else {
	printf "-> file %s indented to file %s, %s remaining \'as is\' (%d seconds) ", $module_name,$BeautyFile,$module_name,$Elapsed ;
}
# compare both files with wc, take lines number and words number -8 ( the 
# beautifier header 
if ( !defined($Replace)) {
	$WcStmt=sprintf "grep -vi \"Source code beautified by beautify\" %s \| wc",$module_name;
} else {
	$WcStmt=sprintf "grep -vi \"Source code beautified by beautify\" %s \| wc",$BackupFile;
}

open WC,"$WcStmt|" or die "cannot run wc check" ;
my $wclinenum=0;
my $CountIssues=0;
@Wcline=<WC>;
if ( $Wcline[0] =~ /^\s+(\d+)\s+(\d+)\s+(\d+)/ ) {
	$NbLines_src = $1;
	$NbWords_src = $2;
	$NbChars_src = $3;
}
close WC ;
if ( !defined($Replace)) {
	$WcStmt=sprintf " grep -vi \"Source code beautified by beautify\" %s \| wc",$BeautyFile;
} else {
	$WcStmt=sprintf " grep -vi \"Source code beautified by beautify\" %s \| wc",$module_name;
}
open WC,"$WcStmt|" or die "cannot run wc check" ;
my $wclinenum=0;
my $CountIssues=0;
@Wcline=<WC>;
if ( $Wcline[0] =~ /^\s+(\d+)\s+(\d+)\s+(\d+)/ ) {
	$NbLines_trg = $1;
	$NbWords_trg = $2;
	$NbChars_trg = $3;
}
close WC ;
if ( $NbLines_src != $NbLines_trg ) { 
	$CountIssues++;
	printf "Source lines %d <> target lines %d ", $NbLines_src,$NbLines_trg;
}
if ( $NbWords_src != $NbWords_trg ) { 
	$CountIssues++;
	printf "Source words %d <> target words %d ", $NbWords_src,$NbWords_trg;
}
if ( $NbChars_src != $NbChars_trg ) { 
	$CountIssues++;
	printf "Source characters %d <> target characters %d ", $NbChars_src,$NbChars_trg;
}
if ( $CountIssues > 0 ) {
	printf " ==> Check Target file\n"
} else {
	printf "Check OK\n" ;
}

} # end sub beautify_4gl_file 

sub indent_line {
$indent_lvl=$_[0];
$indent_block=$_[1] ;
my $IsFjs=$_[2];
my $InComments=$_[3] ;
if ( length($indent_block) > 1 ) {
	$IndentChar=substr($indent_block,0,1);
} else {
	$IndentChar=$indent_block;
}

if ( $IsFjs && $IndentLeftFJSInit ) {
	printf BEAUTYFILE "--#";
}

## ---> voir cas ou le string d'indent est \t, fausse les calculs
if ( length($indent_block) > 1 ) {
	$IndentLength=(length($indent_block)*$indent_lvl)-(3*$IsFjs*($indent_lvl>0)) ;
} else {
	$IndentLength=(length($indent_block)*$indent_lvl) ;
} 
my $this_indent_block =~ s/^/$IndentChar x $IndentLength/e ;
printf BEAUTYFILE "%s",$this_indent_block ;

if ( $IsFjs && !($IndentLeftFJSInit) ) {
	printf BEAUTYFILE "--#";
}

} # end indent_line

sub read_ifgl_syntax {
$SyntaxFile = sprintf "%s/../etc/ifgl_layout.rules",$ENV{"KANDOOTOOLSDIR"};
if  (!( -f $SyntaxFile )) {
	die "You need the syntax file $Syntaxfile to run this tool, please check" ;
} 
%FglSyntax=() ;
open (SYNTAXFILE,$SyntaxFile);
READSYNTAX: while (<SYNTAXFILE> ) {
	next READSYNTAX if (/^\s*#/) ;
	if ( /(\$\w+=.*)/ ) {
		$SetExpression=$1;
		$SetExpression =~ s/([\\\*\+])/\\$1/g ;
		eval ${SetExpression};
		next READSYNTAX ;
	} else {
		$_ =~ s/[\r\n]+//g;
		my @Line=split("\t",$_);
		$FglSyntax{$Line[0]}->{BEFORE}=$Line[1];
		$FglSyntax{$Line[0]}->{AFTER}=$Line[2];
		if ( defined($Line[3]) ) {
			$FglSyntax{$Line[0]}->{FULLREGEXP}=$Line[3];
		} else {
			$FglSyntax{$Line[0]}->{FULLREGEXP}=".*";
		}
	}
	
}
close(SYNTAXFILE) ;
# read %FglSyntax to check all words of expression in hash, for uppercase/lowercase setting purpose
foreach $expression (keys ( %FglSyntax ) ) {
	my @Words=split(" ",$expression);
	for ($w=0;$w<=$#Words;$w++) {
		if (!defined($FglSyntax{$Words[$w]})) {
			$FglSyntax{$Words[$w]}->{BEFORE}="=";
			$FglSyntax{$Words[$w]}->{AFTER}="=";
		}
	}
}
return $indent_block,$IndentCommentsFullLeft,$SpecialBlocksInit,$SpecialBlocksEvents ;
} # end read_ifgl_syntax

sub GetIndentRule {
# find longuest matching expression
( $WrdNum, @line) = ( @_ );
$ExprFound=0;
$expr="" ;
$thisline = join (" ",@line) ;
# Try to identify expression with $WrdNum words, then 2, then 1 ...
for ( $wrd=$WrdNum;$wrd>=0;$wrd-- ) {
	$expr="" ;
	for ( $ind=0;$ind<=$wrd;$ind++ ) {
		$expr=sprintf "%s %s",$expr,uc($line[$ind]) ;
	}
	# voir si expression regexp
	$expr =~ s/\A\s+// ; 		
	$expr =~ s/\s+\Z// ; 		
	if ( $FglSyntax{$expr}->{BEFORE} =~ /[\+-=\d<]/ && $thisline  =~ /$FglSyntax{$expr}->{FULLREGEXP}/i ) {
		$ind=$wrd+1;
		$wrd=-1;
		$ExprFound=1;
		return $FglSyntax{$expr}->{BEFORE},$FglSyntax{$expr}->{AFTER};
	}
}
return "=","=" ;
}

sub SearchBlockInit{
# this function scans the NewBlock list to find where this block began
	my ($Type,$EndLine) = ( @_ ) ;
	$Type =~ s/^END\s+//i ;
	foreach my $key (sort { $NewBlock{$b}->{StartPosition} <=> $NewBlock{$a}->{StartPosition} } keys %NewBlock ) {
		if ( $NewBlock{$key}->{StartLine} > $EndLine ) {
			#next;
		} else {
			if (($NewBlock{$key}->{BlockType} =~ /^$Type$/i 
			#if (($NewBlock{$key}->{BlockType} =~ /$Type/i 
			|| $NewBlock{$key}->{BlockType} =~ /$Type\sARRAY/i )
			&& !defined( $NewBlock{$key}->{EndPosition})) {
				return $key ;
			}
		}
	}
	return 0;
}

sub check_block_has_events { 
	my ($FileName,$StartReadAt,$BlockType) = ( @_ ) ;
	if (!defined($CkmultiOpen) ) {
		# open once, else retake at same point
		open CKMULTI,$FileName ;
		$CkmultiOpen=1;
	}
	my $linenum=0;
	my $InAList=0;
	while ( my $ckline=<CKMULTI> ) {
		# we read the module from StartReadAt: if we find a block type event, the block has events, else it has no events
		$linenum=$. ;
		if ($linenum <= $StartReadAt ) {
			next ;
		} 
		if ( $ckline =~ /^\s*#|^\s*\{.*\}/ ) {
			# skip comments
			next ;
		} elsif ( $ckline =~ /^\s*$/ ) {
			# skip blank lines
			next ;
		} elsif ( $ckline =~ /,\s*$|,\s*#\s*$/ ) {
			# skip list lines, i.e lines having a , 
			$InAList=1;
			next ;
		} 
		if ( $BlockType =~ /CONSTRUCT|INPUT/ && $ckline =~ /\bFROM\b|WITHOUT DEFAULTS|ATTRIBUTE/i ) {
			# CONSTRUCT ... FROM is a single statement
			next ;
		} elsif ( $BlockType =~ /DISPLAY/ && $ckline =~ /\bTO\b/ ) {
			# DISPLAY ... TO is a single statement
			next ;
		}
		if ( $ckline !~ /$SpecialBlocksEvents/ ) {
			# if any instruction BUT Special Block Event
			if ( $InAList == 1 ) {
				# end of the list
				$InAList=0;
				next ;
			} else {
				#not an event, so the block has no events
				## ericv 20191206 last;
			}
		} elsif ( $ckline =~ /$SpecialBlocksEnd/ ) {
			last;
		} elsif ( $ckline =~ /$SpecialBlocksEvents/ ) {
			# if $SpecialBlocksEvents => there is at least one event in the block
			return 1;
		}
	}
	if (!defined($ckline)) {   # reached end of the file
		close CKMULTI;
		# check if EOF $CkmultiOpen undef
	}		# 
	return 0;
}

sub usage {
	printf "Option not recognized\n";
	return 1;
}

sub cvt_TIS_DSF {
my $TS_seconds=$_[0];
my $TS_format=$_[1];
($S, $M, $H, $d, $m, $y, $wd, $aj, $isdst) = localtime $TS_seconds;
$year = $y + 1900;
$day=$d;
$month=$m + 1;
if ( $TS_format eq "yymd_hms" ) {
	$TS_DSF=sprintf "%2s%02d%02d_%02d%02d%02d",$year, $month, $day, $H,$M,$S ;
} elsif  ( $TS_format eq "yyyymd_hms" ) {
	$TS_DSF=sprintf "%4s%02d%02d%02d%02d%02d",$year, $month, $day, $H,$M,$S ;
} elsif  ( $TS_format eq "yyyy-mm-dd h:m:s" ) {
	$TS_DSF=sprintf "%4s-%02d-%02d %02d:%02d:%02d",$year, $month, $day, $H,$M,$S ;
} else {
	$TS_DSF=sprintf "%4s-%02d-%02d %02d:%02d:%02d",$year, $month, $day, $H,$M,$S ;
}
return $TS_DSF ;
}

sub print_dbg_header {
	if ( defined($Debug) ) {
		if ($PrintedLines == $DbgLineNumber ) {
			$sign="=";
		} elsif ($PrintedLines < $DbgLineNumber ) {
			$sign="<";
		} else {
			$sign="+";
		}
		printf BEAUTYFILE "%6d%s%2d:%2d",$PrintedLines,$sign,$IndentPosition,$FormerPosition ;
	}
}
