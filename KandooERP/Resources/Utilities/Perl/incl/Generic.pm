#!/usr/bin/perl
# Description  : this package contains generic functions
# Use, but do not sell
# author: eric.vercelletto@begooden-it.com
###########################################################################
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF not, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################
package PublicIfmx::Generic;
$ID="\$Id: \$";
BEGIN {
	$PublicLib=$ENV{"PUBLICIFMXLIB"};
	if ( length($PublicLib) == 0 ) {
		$PublicLib="/home/informix/ifxtools/incl";
	}
	eval "use lib \"$PublicLib\"";
	die "$@\n" if ($@);
} # End BEGIN
use Time::ParseDate;
use Sys::Hostname;
use Fcntl ':mode';
#use Filesys::DiskSpace;

require Exporter;

our @ISA		= qw(Exporter);
our @EXPORT		= qw(
						
						cvt_TIS_DSF
						format_TIS
						DetermineTimeCoverage
						ping_system
						CalcInterval
						choose_value_in_list
						check_fileproperties
						DiskFree
						SetCustomParameters
						Separate1000
						ReadOnconfigParam
						
					);
our $VERSION	= 1.0;
 

sub DetermineTimeCoverage {
( $AtTime, $BetweenTime , $AroundTime, $Before, $After, $Until, $During, $UKDateStyle ) = @_ ;
if (defined($UKDateStyle)) {
	$UK=$UKDateStyle;
} else {
	$UK=0;
}
if ( defined ( $AtTime) ) {
	$valid = 0;
	# Datetime Like date
	if ($AtTime =~ /^(\d\d\d\d)\-(\d\d)\-(\d\d)\s/) {
		($y,$m,$d) = ($1,$2,$3);
		$match=$&;
		$remain=$' ;
		$AtTime=sprintf "%s/%s/%s %s",$d,$m,$y,$remain ;
		$UK=1;
	}
	if ($AtTime =~  /now|today|yesterday|tomorrow/ ) { # just the date
		$AtTS = parsedate($AtTime,UK => $UK);
		$BeforeTS=$AtTS+(3600*24);
		$AfterTS=$AtTS-1;
		$valid=1;
	}
	if ( $valid == 0 && $AtTime !~  /\d\d\/\d\d\/\d\d\d\d/ ) {	# if the date is not specified, set as today
		my($Tmpsec,$Tmpmin,$Tmphour,$Tmpmday,$Tmpmon,$Tmpyear) = localtime();
		$AtTime=sprintf("%02d/%02d/%04d %s",$Tmpmday,$Tmpmon+1,$Tmpyear+1900,$AtTime);
	}

	# Consider activity for the current second
	if ($valid == 0 && $AtTime =~ / \d\d:\d\d:\d\d\Z/ ) { # hh:mm:ss
		$AtTS = parsedate($AtTime,UK => $UK);
		$BeforeTS=$AtTS+1;
		$AfterTS=$AtTS-1;
		$valid=1;
	}
	# Consider activity for the current minute
	if ($valid == 0 && $AtTime =~  / \d\d:\d\d\Z/ ) { # hh:mm
		$AtTS = parsedate($AtTime,UK => $UK);
		$BeforeTS=$AtTS+60;
		$AfterTS=$AtTS-1;
		$valid=1;
	}
	# Consider activity for the current 10 minutes
	if ($valid == 0 && $AtTime =~  / \d\d:\d\Z/ ) { # hh:mX
		$AtTime=$AtTime . "0";
		$AtTS = parsedate($AtTime,UK => $UK);
		$BeforeTS=$AtTS+600;
		$AfterTS=$AtTS-1;
		$valid=1;
	}

	if ( $valid == 0 && $AtTime =~  / \d\d\Z/ ) { # hh
		# parsedate does not understand only hours
		$AtTime=$AtTime . ":00";
		$AtTS = parsedate($AtTime,UK => $UK);
		$BeforeTS=$AtTS+3600;
		$AfterTS=$AtTS-1;
		$valid=1;
	}
	if ($valid == 0 &&  $AtTime =~  /\d\d\/\d\d\/\d\d\d\d$/ ) { # just the date
		$AtTS = parsedate($AtTime,UK => $UK);
		$BeforeTS=$AtTS+(3600*24);
		$AfterTS=$AtTS-1;
		$valid=1;
	}
	
	if ( $valid == 0 ) {
		die "Date format not valid $AtTime";
	}
	
	my($bsec,$bmin,$bhour,$bmday,$bmon,$byear) = localtime($BeforeTS);
	$BeforeString=sprintf ("%4d-%02d-%02d %02d:%02d:%02d",$byear+1900,$bmon+1,$bmday,$bhour,$bmin,$bsec);
	
	my($asec,$amin,$ahour,$amday,$amon,$ayear) = localtime($AfterTS);
	$AfterString=sprintf ("%4d-%02d-%02d %02d:%02d:%02d",$ayear+1900,$amon+1,$amday,$ahour,$amin,$asec);
	
}
if ( defined ( $During) ) {
	$valid = 0;
	if (!defined($After)) {
		$Start=time ();
	} else {
		$Start = parsedate($After,UK => $UK);
	}

	# Consider activity for the current second
	if ($During =~ /^(\d{1,2}):(\d\d):(\d\d)\Z/ ) { # hh:mm:ss
		$Interval=($1*3600) + ($2*60) + $3 + 1;
		$BeforeTS=$Start + $Interval ;
		$valid=1;
	} elsif ($During =~  /\A(\d{1,2}):(\d\d)\Z/ ) { # hh:mm
		$Interval=($1*3600) + ($2*60) + 1;
		$BeforeTS=$Start + $Interval ;
		$valid=1;
	} elsif ($During =~  /\A(\d{1,2})\Z/ ) { # hh
		$Interval=($1*3600) +1 ;
		$BeforeTS=$Start + $Interval ;
		$valid=1;
	} 
	
	if ( $valid == 0 ) {
		die "Date format not valid $DuringTime";
	}
	
	my($bsec,$bmin,$bhour,$bmday,$bmon,$byear) = localtime($BeforeTS);
	$BeforeString=sprintf ("%4d-%02d-%02d %02d:%02d:%02d",$byear+1900,$bmon+1,$bmday,$bhour,$bmin,$bsec);
	
	my($asec,$amin,$ahour,$amday,$amon,$ayear) = localtime($AfterTS);
	$AfterString=sprintf ("%4d-%02d-%02d %02d:%02d:%02d",$ayear+1900,$amon+1,$amday,$ahour,$amin,$asec);
	
}

if ( defined ( $BetweenTime ) ) {
	if ( $BetweenTime =~ "-" ) {
		$Before = $' ;
		$After = $` ;
	}
}

if ( defined ( $AroundTime ) ) {
	if ( $AroundTime =~ "~" ){
		$BaseTime = $` ;
		$Precision = $' ;
		if ($BaseTime !~  /\d\d\/\d\d\/\d\d\d\d/ ) {	# if the date is not specified, set as today
			my($Tmpsec,$Tmpmin,$Tmphour,$Tmpmday,$Tmpmon,$Tmpyear) = localtime();
			$BaseTime=sprintf("%02d/%02d/%04d %s",$Tmpmday,$Tmpmon+1,$Tmpyear+1900,$BaseTime);
		}
		$BaseTimeSec = parsedate($BaseTime, UK => $UK  );
		if( $Precision =~ /(\d+)(hh|mm|ss)/ ) {
			$Precision_num = $1;
			$Precision_unit = $2 ;
		} else {
			die "usage -around 10:45~10hh|mm|ss " ;
		}
		if ( $Precision_unit eq "hh" ) {
			$Interval=$Precision_num*3600 ;
		} elsif ( $Precision_unit eq "mm" ) {
			$Interval=$Precision_num*60 ;
		} else {
			$Interval=$Precision_num ;
		}
		$BeforeTS = $BaseTimeSec + $Interval + 1;
		$AfterTS = $BaseTimeSec - $Interval ;
		undef ( $Before );
		undef ( $After ) ;
	} else {
		die "usage -around 10:45~10hh|mm|ss " ;
	}
	my($bsec,$bmin,$bhour,$bmday,$bmon,$byear) = localtime($BeforeTS);
	$BeforeString=sprintf ("%4d-%02d-%02d %02d:%02d:%02d",$byear+1900,$bmon+1,$bmday,$bhour,$bmin,$bsec);
	
	my($asec,$amin,$ahour,$amday,$amon,$ayear) = localtime($AfterTS);
	$AfterString=sprintf ("%4d-%02d-%02d %02d:%02d:%02d",$ayear+1900,$amon+1,$amday,$ahour,$amin,$asec);
}

if ( defined ( $Before ) ) {
	# Datetime Like date
	if ($Before =~ /^(\d\d\d\d)\-(\d\d)\-(\d\d)\s/) {
		($y,$m,$d) = ($1,$2,$3);
		$match=$&;
		$remain=$' ;
		$Before=sprintf "%s/%s/%s %s",$d,$m,$y,$remain ;
		$UK=1;
	}

	if ($Before !~  /\d\d\/\d\d\/\d\d\d\d/ && $Before !~  /now|today|yesterday|tomorrow/ ) {	# if the date is not specified, set as today
		my($Tmpsec,$Tmpmin,$Tmphour,$Tmpmday,$Tmpmon,$Tmpyear) = localtime();
		$Before=sprintf("%02d/%02d/%04d %s",$Tmpmday,$Tmpmon+1,$Tmpyear+1900,$Before);
	}
	$BeforeTS = parsedate($Before, UK => $UK  );
	my($bsec,$bmin,$bhour,$bmday,$bmon,$byear) = localtime($BeforeTS);
	$BeforeString=sprintf ("%4d-%02d-%02d %02d:%02d:%02d",$byear+1900,$bmon+1,$bmday,$bhour,$bmin,$bsec);
}

if ( defined ( $After ) ) {
	# Datetime Like date
	if ($After =~ /^(\d\d\d\d)\-(\d\d)\-(\d\d)\s/) {
		($y,$m,$d) = ($1,$2,$3);
		$match=$&;
		$remain=$' ;
		$After=sprintf "%s/%s/%s %s",$d,$m,$y,$remain ;
		$UK=1;
	}
	if ($After !~  /\d\d\/\d\d\/\d\d\d\d/ && $After !~  /now|today|yesterday|tomorrow/ ) {	# if the date is not specified, set as today
		my($Tmpsec,$Tmpmin,$Tmphour,$Tmpmday,$Tmpmon,$Tmpyear) = localtime();
		$After=sprintf("%02d/%02d/%04d %s",$Tmpmday,$Tmpmon+1,$Tmpyear+1900,$After);
	}
	$AfterTS = parsedate($After ,UK => $UK );
	my($asec,$amin,$ahour,$amday,$amon,$ayear) = localtime($AfterTS);
	$AfterString=sprintf ("%4d-%02d-%02d %02d:%02d:%02d",$ayear+1900,$amon+1,$amday,$ahour,$amin,$asec);
}


$a=1 ;
return $BeforeTS,$BeforeString,$AfterTS,$AfterString ;
} # end sub DetermineTimeCoverage

###########################################################################################
# This sub converts a system timestamp in seconds to a formatted and readable string format
# in: system time in seconds
# out: formatted date
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
} elsif  ( $TS_format eq "yyyy-mm-dd" ) {
	$TS_DSF=sprintf "%4s-%02d-%02d",$year, $month, $day;
} elsif  ( $TS_format =~ /dd[\/\-]mm[\/\-]yyyy h:m:s/ ) {
	$TS_DSF=sprintf "%02d/%02d/%02d %02d:%02d:%02d",$day, $month, $year, $H,$M,$S ;
} elsif  ( $TS_format =~ /dd[\/\-]mm[\/\-]yyyy/ ) {
	$TS_DSF=sprintf "%02d/%02d/%02d",$day, $month, $year ;
} else {
	$TS_DSF=sprintf "%4s-%02d-%02d %02d:%02d:%02d",$year, $month, $day, $H,$M,$S ;
}
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

sub ping_system {
my $Host = $_[0] ;
$PingCmd=sprintf "ping -n 1 %s|",$Host ;
open PING ,$PingCmd ;
$status=0;
PING: while ( <PING> ) {
	if ( /(\d+\.\d+\.\d+\.\d+).*:.*\w+=\d+.*TTL=/ ) {
		$status=0;
		last PING;
	}
}
return $status ;
}

sub CalcInterval {
my ($Start,$End,$Mode ) = @_ ;
if ( $Start =~ /[\/\-\:]+/ ) {
	$StartDateSec=parsedate($Start ) ;
} else {
	$StartDateSec=$Start ;
}

if ( $End =~ /[\/\-\: ]+/ ) {
	$EndDateSec=parsedate($End ) ;
} else {
	$EndDateSec=$End
}


$ElapsedSec= $EndDateSec - $StartDateSec ;
if ( $Mode =~ /sec/i) {
	return $ElapsedSec;
}
$NbDays=int($ElapsedSec/86400) ;
$RemainingSec=$ElapsedSec-($NbDays*86400);
$NbHours=int($RemainingSec/3600) ;
$RemainingSec=$ElapsedSec-($NbDays*86400)-($NbHours*3600);
$NbMn=int ($RemainingSec/60) ;
$RemainingSec=$ElapsedSec-($NbDays*86400)-($NbHours*3600)-($NbMn*60) ;
$Interval=sprintf "%d %02d:%02d:%02d",$NbDays,$NbHours,$NbMn,$RemainingSec;
return $Interval ;
} # end sub CalcInterval

sub ReadRecursive  {
 # my $DIR = shift;
 my $DIR = $_[0] ;
 # this is a new sublevel
 my @levels = split (/\\/,$DIR) ;
  
if (opendir DIR, $DIR)  {

  foreach (sort (readdir(DIR))) {
   next if $_ =~ m/^(\.|\.\.)$/;
   if ( $DIR !~ /\\$/ ) {
   	$entry = $DIR . "\\" . $_;
  } else {
  	$entry = $DIR . $_;
  }
   
   if (-d $entry){
   	 # Taking creation date and last modified
   		$ReturnedRec = &ReadRecursive($entry);
   	}
   else {
		if ( basename($DIR) eq basename($entry) ) {
			if ( $entry =~ /\.4ge|\.o|\.4go|\.frm/ ) {
				unlink ($entry) ;
				rmdir $DIR ;
			} else {
				$moved++;
				$upperdir = $DIR;
				$upperdir =~ s/[\w\.]+$// ;
				$newentry= $upperdir . "nw_". basename($entry);
				move ($entry,$newentry) or die "could not copy file $entry";
			}
		}
    }
   }
   
  closedir DIR;
  if ( $moved > 0 ) {
	rmdir $DIR ;
	$entry = $newentry ;
	$entry =~ s/nw_// ;
	move ( $newentry,$entry ) ;
}
}

return ( $RecToReturn ) ; 
  # return ($ThisDirSize );
} # end sub ReadRecursive  


sub disk_stats {
my $dir = $_[0] ;
if ( $^ =~ /win/i ) {
	$a=1;
} else {
	open DF, "|df -k" or die "Cannot run df on this system";
	while ( <DF> ) {
	}
}
}

sub choose_value_in_list {
my ($question, @Array) = @_ ;
my $PossibleChoice="";
my $adx=0;
my $rep="";
my $Reply="";
$sep_save=$/ ;
$/ = "\n" ;
if ( $#Array > 0 ) {
	printf "%s\n",$question ;
	while ( defined($Array[$adx] )) {
		printf "    %2d) %s\n",$adx+1,$Array[$adx] ;
		$PossibleChoice=sprintf "%s\^%s\$\|",$PossibleChoice,$adx+1;
		$adx++;
	}
	chop ($PossibleChoice) ;
	if ( $PossibleChoice =~ /(\d).*(\d+)/ ) {
		$ChoiceMsg=sprintf "%d-%d or q to quit ",$1,$2 ;
	}
	printf "Please enter a value ( %s ) ",$ChoiceMsg ;
	if ( length($Reply) == 0 ) {
		$rep="XxXx";
		while ( ($rep) !~ /$PossibleChoice|q/i ) {
			$rep=<STDIN>;
			chomp ($rep) ;
		}
		if ( $rep =~ /q/i ) {
			exit;
		}
		$Reply=$Array[$rep-1];
		printf "%s\n",$Reply ;
	}
} elsif ( $#Array == 0 ) {
	$Reply=$Array[0];
	printf "%s: %s\n",$question,$Reply;
} else {
	printf STDERR "%s : no possible choice listed\n";
	exit(1) ;
}
$/ = $sep_save ;
return $Reply;
}

sub check_fileproperties {
my $filename = $_[0] ;
if (($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat($filename)) {
	$user = getpwuid($uid);
	$group = getgrgid($gid);
	$ftypes[S_IFDIR] = "d";
	$ftypes[S_IFCHR] = "c";
	$ftypes[S_IFBLK] = "b";
	$ftypes[S_IFREG] = "-";
	$ftypes[S_IFIFO] = "p";
	$ftypes[S_IFLNK] = "l";
	$ftypes[S_IFSOCK] = "s";

	$permissions = sprintf "%04o", S_IMODE($mode);
	$filetype = S_IFMT($mode);

	$ftype = $ftypes[$filetype];

	return $user,$group,$permissions,$size,$mtime  ;
} else {
	print "Please specify an EXISTING file!\n";
	return "X","X","X","X","X" ;
}
} # end sub check_fileproperties 

sub DiskFree {
my $dir = $_[0] ;
my ($fs_type, $fs_desc, $used, $avail, $fused, $favail) = df $dir;
 # calculate free space in %
my $df_free = (($avail) / ($avail+$used)) * 100.0;
return $df_free ;
}

# this sub reads a file containing perl variable settings and executes them
sub SetCustomParameters {
   ($ParametersFile) = @_ ;
	if ( -e ($ParametersFile) ) {
		$xStatus=0;
	} else {
		$xStatus=1;
		return $xStatus;
	}
	@CommandsToEval={} ;
	$cte=0;
   open PARAMETERS,"$ParametersFile" or die "Parameters does not exist " . $ParametersFile ;
   while (<PARAMETERS>) {
      if ( $_ =~ /^\$\w+=.*/) {
			$CommandsToEval[$cte++]=$& ;
      }
   }
	return @CommandsToEval;
} # end SetCustomParameters


# this sub format thousands with ','
sub Separate1000 {
	($number,$decimal) = @_ ;
	if (!defined($_[1])) {
		$decimal=0;
	}
	# left part
	1 while ($number =~ s/^(-?\d+)(\d{3})/$1,$2/);
	# right part, decimals
	1 while ($number =~ s/(\.\d{$decimal})\d+/$1/i);
	1 while ($number =~ s/\.$//i);
	return $number;
}

sub ReadOnconfigParam {
    ( $Param,$OnconfigFile ) = @_ ;
    $Param=uc($Param) ;
    if (!defined($OnconfigFile)) {
        $OnconfigFile=sprintf "%s/etc/%s",$ENV{"INFORMIXDIR"},$ENV{"ONCONFIG"};
    }
    open ONCONFIG,$OnconfigFile or die "Cannot open onconfig file " . $OnconfigFile ;
    while ( $onconfigline=<ONCONFIG> ) {
        next if ( $onconfigline !~ /^$Param\s(.*)#*/ ) ;
        return $1;
    }
    return "notfound";
}

