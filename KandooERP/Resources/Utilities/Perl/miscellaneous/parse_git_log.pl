BEGIN {
$PublicLib=$ENV{"PUBLICLIB"};
if ( length($PublicLib) == 0 ) {
	$PublicLib="../incl";
}
eval "use lib \"$PublicLib\"";
} # End BEGIN
use Getopt::Long;
use File::Basename;
use Time::ParseDate;
use File::Basename;
#

if (!GetOptions(
"outdir=s"=>\$OutDir,
"startdate=s"=>\$StartDateStr,
"enddate=s"=>\$EndDateStr,
"who=s"=>\$Who,
"filesearch=s"=>\$FileSearch,
"messagesearch=s"=>\$MsgSearch,
"showmessage"=>\$MsgShow,

"detail"=>\$Detail,
) ) {
	$a=1;
	exit (1);
}
if (!defined($OutDir)) {
	$OutDir="/tmp";
}

$GitCmd="git log --stat |";
$OutFile=sprintf "%s/%s.txt",$OutDir,"gitlog.txt";
open GITLOG,$GitCmd or die "cannot run git log " ;
open OUTFILE,">$OutFile" or die "cannot create outfile file " ;

if (defined($EndDateStr)) {
	$EndDateUTC=parsedate($EndDateStr);
}
if (defined($StartDateStr)) {
	$StartDateUTC=parsedate($StartDateStr);
}

printf "Detail activity on kandooerp between %s and %s\n",$StartDateStr,$EndDateStr;
printf "Kandooer's email                                             Files modif.    Line Inserts    Line Deletes       Commit ID\n";
LGITLOG: while (<GITLOG>) {
	if ( /^\s*$/ ) {
		next LGITLOG;
	}
	if ( /^commit\s*(\w+)/) {
		$NewCommit=$1;
		if ( $FilesChanged > 0   ) {
			if (((defined($EndDateUTC) && $DateTimeUTC <= $EndDateUTC) || !defined($EndDateUTC))  
			&& ((defined($StartDateUTC) && $DateTimeUTC >= $StartDateUTC) || !defined($StartDateUTC))
			&& ((defined($Who) && $email =~ /$Who/) || !defined($Who)) 
			&& ((defined($FileSearch) && defined($CommitFilesList[0])) || !defined($FileSearch))
			&& ((defined($MsgSearch) && $KeepMsg == 1 ) || !defined($MsgSearch))) {
				printf "%s %-42s\t%9d\t%9d\t%9d\t%s\n",$DateTimeStr,$email,$FilesChanged,$Inserts,$Deletes,$OldCommit;
			}
			if ( defined($CommitMessage[0]) && $KeepMsg == 1 ) {
				while(defined($CommitMessage[$cmsg])) {
					printf "\t%s\n",$CommitMessage[$cmsg++];
				}
			}

			if ( defined($CommitFilesList[0])) {
				while(defined($CommitFilesList[$cfl])) {
					printf "\t%s\n",$CommitFilesList[$cfl++];
				}
			}
		}

		
		$Name="";
		$email="";
		$FilesChanged=0;
		$Inserts=0;
		$Deletes=0;
		$CommitsNumber++;
		$SkipCommit=0;
		$KeepMsg=0;
		$KeepFile=0;
		undef  @CommitFilesList ;
		undef  @CommitMessage ;
		$cfl=0;
		$cmsg=0;
		$OldCommit=$NewCommit;
	}
	if ( $SkipCommit == 1 ) {
		next LGITLOG;
	}
	#if ( /^Author:\s+([\w\s\\\-\.]+)\s+<(.*)>/ ) {
	if ( /^Author:.*<(.*)>/ ) {
		$email=$1;
		if ( defined($Who) && $email !~ /$Who/ ) {
				$SkipCommit=1;
				next LGITLOG;
		}
	}
	if ( /^Date:\s+(\w{3}\s+\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+\d{4})/ ) {
		$DateTimeStr=$1;
		$DateTimeUTC=parsedate($DateTimeStr,1);
		$DateTimeStr=utc_to_datetime($DateTimeUTC);
		if (!defined($LastCommitDate{$email})) {
			$LastCommitDate{$email}=$DateTimeStr;
		}
		# printf "%s : %s  %s\n",utc_to_datetime($DateTimeUTC),utc_to_datetime($StartDateUTC),utc_to_datetime($EndDateUTC);
		if (defined($EndDateUTC) && $DateTimeUTC > $EndDateUTC ) {
			$SkipCommit=1;
			next LGITLOG;
		}
		if (defined($StartDateUTC) && $DateTimeUTC < $StartDateUTC ) {
			$SkipCommit=1;
			last LGITLOG;
			
		}
	}
	if ( defined($MsgShow) || defined($MsgSearch) ) {
		undef  $MsgLine;
		if ( !/^Date:\s+/ && !/^Author:\s+/ && !/^commit\s*/ && !/(.*)\s+\|\s+(\d+)\s+[\-\+]+|(.*)\s+\|\s+Bin\s+\d/ && !/(\d+)\s+file\w*\s+changed/ ) {
			# this is the message
			$MsgLine=$_;
			$MsgLine =~ s/^\s+|\s+$//g;
			if ( defined($MsgSearch)) {
				push @CommitMessage,$MsgLine;
				if ( $MsgLine =~ /$MsgSearch/ ) {
					$KeepMsg=1;
				} else {
					$SkipCommit=1;
					#next LGITLOG;
				}
			} elsif ( defined($MsgShow) ) {
				$KeepMsg=1;
				push @CommitMessage,$MsgLine;
			}
		}
	}

	if ( defined($FileSearch) && /(.*)\s+\|\s+\d+\s+[\-\+]+|(.*)\s+\|(.*)\s+Bin\s+\d+/) {
		if ( $1 ne "" ) {
			$FileName=$1;
		} elsif ( $2 ne "" ) {
                        $FileName=$2;
		}

			
		if ( $FileName =~ /$FileSearch/ ) {
			$KeepFile=1;
			push @CommitFilesList,$FileName;
		}
	}

	
	#$SkipCommit=0;
	if ( /(\d+)\s+file\w*\s+changed/ ) {
		 if (((defined($MsgSearch) && $KeepMsg == 1) || !defined($MsgSearch))
		 && ((defined($FileSearch) && $KeepFile == 1) || !defined($FileSearch))) {
			$FilesChanged=$1;
			if ( !defined($TotalActivity{$email}->{lastCommit})) {
				$TotalActivity{$email}->{LastCommit}=$LastCommitDate{$email};
			}
			$TotalActivity{$email}->{FilesChanged} += $FilesChanged ;
			$TotalActivity{$email}->{Commits}++ ;
			if (/\s+(\d+)\s+insertion/ ) {
				$Inserts=$1;
				$TotalActivity{$email}->{Inserts} += $Inserts ;
			}
			if (/\s+(\d+)\s+deletion/ ) {
				$Deletes=$1;
				$TotalActivity{$email}->{Deletes} += $Deletes ;
			}
		}
	}

		
}
# check last row
if ( $FilesChanged > 0   ) {
	if (((defined($EndDateUTC) && $DateTimeUTC <= $EndDateUTC) || !defined($EndDateUTC))  
	&& ((defined($StartDateUTC) && $DateTimeUTC >= $StartDateUTC) || !defined($StartDateUTC))
	&& ((defined($Who) && $email =~ /$Who/) || !defined($Who)) 
	&& ((defined($FileSearch) && defined($CommitFilesList[0])) || !defined($FileSearch))
	&& ((defined($MsgSearch) && defined($CommitMessage[0])) || !defined($MsgSearch))) {
		printf "%s %-42s\t%9d\t%9d\t%9d\t%s\n",$DateTimeStr,$email,$FilesChanged,$Inserts,$Deletes,$OldCommit;
	}
		if ( defined($CommitMessage[0])) {
			while(defined($CommitMessage[$cmsg])) {
				printf "\t%s\n",$CommitMessage[$cmsg++];
			}
		}

		if ( defined($CommitFilesList[0])) {
			while(defined($CommitFilesList[$cfl])) {
				printf "\t%s\n",$CommitFilesList[$cfl++];
			}
		}
}

	printf "\n\n";
	printf "Summary of git activity\n";
	printf "Kandooer's email                                  Commits    Files modif.    Line Inserts    Line Deletes       Last Commit Date\n";
	foreach $email ( keys %TotalActivity ) {
		printf "%-45s\t%9d\t%9d\t%9d\t%9d\t%s\n",$email,$TotalActivity{$email}->{Commits},
		$TotalActivity{$email}->{FilesChanged},$TotalActivity{$email}->{Inserts},$TotalActivity{$email}->{Deletes},$TotalActivity{$email}->{LastCommit};
	}


sub thousand_sep {
my $number = $_[0] ;
if ( $number !~ /[A-Za-z\.]/ ) {
    $number = reverse join ",", (reverse $number) =~ /(\d{1,3})/g;
}
return $number;
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

