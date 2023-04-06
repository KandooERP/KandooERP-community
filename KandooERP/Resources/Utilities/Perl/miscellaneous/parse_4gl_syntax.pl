use Getopt::Long;
use File::Basename;
use File::Spec;
use Cwd 'abs_path';

if (!GetOptions(
"indir=s"=>\$InDir,
"outdir=s"=>\$OutDir,
"syntaxfile=s"=>\$SyntaxFile,
"forms"=>\$DoForms_Not4gl
) ) {
	$a=1;
	exit (1);
}
if (!defined($OutDir)) {
	$OutDir="/tmp";
}
# read syntax file to build regexp
if ( !defined($SyntaxFile)) {
	$SyntaxFile="syntax_file.txt" ;
}

if (defined($DoForms_Not4gl)) {
	$FilesExtension=".fm2";
} else {
	$FilesExtension=".4gl";
}
@SyntaxList=();
@TagsList=();
@ExcludeList=();

open SYNTAX,$SyntaxFile or die "cannot open syntax " ;
while (<SYNTAX>) {
	#s/\n// ;
	if ( /\:regexp\=(.*?)[:\n\r]{1}/) {
		$SyntaxList[$sdx] = $1;
	}
	if ( /\:tag=(.*?)[:\n\r]{1}/) {
		$TagsList[$sdx] = $1;
	} 
	if ( /\:exclexp=(.*?)[:\n\r]{1}?/) {
		$ExcludeList[$sdx] = $1;
	} 
	$sdx++;
}

$SyntaxRegexp=join "\|",@SyntaxList ;
$SyntaxRegexp =~ s/\|$// ;
$ParseFile = sprintf "%s/ParseFrom_%s_%s.txt",$OutDir,basename($SyntaxFile,".syn"),$FilesExtension ;
$StatsFile = sprintf "%s/StatsFor_%s.txt",$OutDir,basename($SyntaxFile,".syn") ;
$TagsFile=sprintf "%s/tags_0.%s",$OutDir,$FilesExtension;
open PARSEFILE,">$ParseFile" or die "cannot open Parse File " ;
printf PARSEFILE "Module Name\tLine Number\tTag\tLine Contents\n";
open STATSFILE,">$StatsFile" or die "cannot open Stats File " ;
printf STATSFILE "File Name\tIs Main\tFunctions Number\tOpenFormNumber\tReports Number\t Lines Number\tCode Lines Number\tComments Lines Number\tBlank Lines Number\n";
open TAGSFILE,">$TagsFile" or die "cannot open syntax " ;
my $SqlFile=sprintf "%s/sql",$OutDir;
open SQLFILE,">$SqlFile" or die "cannot create sql file " ;
read_directory($InDir);
close PARSEFILE;
close TAGSFILE;
printf STATSFILE "Total modules:           %12s\n",thousand_sep($Modules);
printf STATSFILE "Total forms:             %12s\n",thousand_sep($Forms);
printf STATSFILE "Total lines:             %12s\n",thousand_sep($TotalLines);
printf STATSFILE "Total MAIN number:       %12s\n",thousand_sep($TotalMainNumber);
printf STATSFILE "Total functions number:  %12s\n",thousand_sep($TotalFunctionsNum);
printf STATSFILE "Total open form          %12s\n",thousand_sep($TotalOpenFormsNum);
printf STATSFILE "Total reports number:    %12s\n",thousand_sep($TotalReportsNum);
printf STATSFILE "Total active code lines: %12s\n",thousand_sep($TotalCodeLines);
printf STATSFILE "Total commented lines:   %12s\n",thousand_sep($TotalCommentsLines);
printf STATSFILE "Total blank lines:       %12s\n",thousand_sep($TotalBlankLines);
printf  "Total modules:           %12s\n",thousand_sep($Modules);
printf  "Total forms:             %12s\n",thousand_sep($Forms);
printf  "Total lines:             %12s\n",thousand_sep($TotalLines);
printf  "Total MAIN number:       %12s\n",thousand_sep($TotalMainNumber);
printf  "Total functions number:  %12s\n",thousand_sep($TotalFunctionsNum);
printf "Total open form          %12s\n",thousand_sep($TotalOpenFormsNum);
printf  "Total reports number:    %12s\n",thousand_sep($TotalReportsNum);
printf  "Total active code lines: %12s\n",thousand_sep($TotalCodeLines);
printf  "Total commented lines:   %12s\n",thousand_sep($TotalCommentsLines);
printf  "Total blank lines:       %12s\n",thousand_sep($TotalBlankLines);

printf "Please check parse file %s\n",File::Spec->canonpath($ParseFile);
printf "Please check stats file %s\n",File::Spec->canonpath($StatsFile);
$sortcmd=sprintf "sort %s > %s/tags",$TagsFile,$OutDir;
open TMPTAGSFILE,$TagsFile or die "cannot open syntax " ;
my $NewTagsFile=sprintf "%s/tags",$OutDir;
open NEWTAGSFILE,">$NewTagsFile" or die "cannot create tags file " ;
#printf NEWTAGSFILE sort {$a cmp $b} <TMPTAGSFILE> ;
my @TagFile=<TMPTAGSFILE>;
my ( @NewTagFile) = sort (@TagFile);
while (defined($NewTagFile[$tdx++])) {
	printf NEWTAGSFILE "%s",$NewTagFile[$tdx] ;
}
#system($sortcmd);
if ( $! = 0 ) {
	printf "tags file sorted and operational\n";
}

sub read_directory {
my $indir=$_[0];
opendir (my $DIR,$indir) or die "Cannot open indir " . $indir;
printf"reading directory %s\n",File::Spec->canonpath($indir);
while ( my $Handle=readdir($DIR) ) {
	#my $FullHandle=$indir . "/" . $Handle ;
	my $FullHandle=abs_path($indir . "/" . $Handle);
	if ( $Handle eq '.' || $Handle eq '..' || -l $FullHandle ) {
		next ;
	} elsif ( -d $FullHandle ) {
		read_directory($FullHandle);
	} elsif ( $FullHandle =~ /\.per$|\.fm2$/ && ${FilesExtension} !~ /\.per$|\.fm2$/ ) {
		$Forms++;
	} elsif ( $FullHandle =~ /${FilesExtension}$/ ) {
		printf STATSFILE "%s\t",File::Spec->canonpath($FullHandle);
		printf "\tChecking module %s (%d) ",File::Spec->canonpath($FullHandle),$Modules++ ;
		open MODULE,$FullHandle or die "cannot open module " . $FullHandle ;
		my $linenum=0;
		my $CodeLines=0;
		my $InComment=0;
		my $CommentsLines=0;
		my $BlankLines=0;
		my $FunctionsNumber=0;
		my $ReportsNumber=0;
		my $MainNumber=0;
		my $OpenFormsNumber=0;
		ReadModule: while ( <MODULE> ) {
			$linenum++ ;
			if ( $_ =~ /^\s*$/) {
				$BlankLines++;
				next;
			}
			if ( $_ =~ /^\s*\{.*\}|^\s*#|^\s*\-\-/) {
				$CommentsLines++;
				if ( /.*\}\s*$/ ) {
					$InComment=0;
				}
				next ;
			}
			$_ =~ s/^\s+//g;
			#$_ =~ s/\{.*\}//gsm;
			#$_ =~ s/#.*// ;
			#$_ =~ s/\-\-.*// ;
			if ( $_ =~ /^\s*\{/ ) {
				$InComment=1;
				$CommentsLines++;
				next ;
			} 
			if ( $_ =~ /\}(.*)/ ) {
				$InComment=0;
				$CommentsLines++;
				next ;
			}
			
			$CodeLines++;
			if ( /^\s*FUNCTION\s+(\w+)/i) {
				$FunctionsNumber++;
				$FunctionName=$1;
			} elsif ( /^\s*REPORT\s+(\w+)/i) {
				$ReportsNumber++;
				$FunctionName=$1;
			} elsif ( /^\s*MAIN\s/i) {
				$MainNumber++;
			} elsif ( /^\s*OPEN\s+WINDOW\s|^\s*OPEN\s+FORM\s/i) {
				$OpenFormsNumber++;
			}
			if ( $_ =~ /$SyntaxRegexp/smi ) {
				my $tdx=0;
				my $TagName="";
				RecheckExp:while(defined($SyntaxList[$tdx])) {
					if ( $_ =~ /$SyntaxList[$tdx]/smi) {
						my $Exit=0;
						my $RegexpContents=$&;
						if ( defined($1)) {
							printf SQLFILE "%s\t%s\t%s\t%s\t%s\n",basename(dirname($FullHandle)),basename($FullHandle),$FunctionName,uc($1),$2;
						}
						if (defined($TagsList[$tdx])) {
							$TagName=sprintf "%s_%08d",uc($TagsList[$tdx]),$TagNum++;
						} else {
							$RegexpContents =~ s/\W+//g;
							$TagName=sprintf "%s_%08d",uc($RegexpContents),$TagNum++;
						}
						if (defined($ExcludeList[$tdx])) {
							if ( $_ =~ /$ExcludeList[$tdx]/i ) {
								# $a=1;
								next ReadModule ;
							}
						}
						last RecheckExp ;
					}
					$tdx++;
				}
				if ( $TagName =~ /^$/) {
					$a=1;
				}
				#printf PARSEFILE "%s\t%d\t%s\t%s",$Handle,$linenum,$TagName,$_ ;
				printf PARSEFILE "%s\t%d\t%s\t%s",$FullHandle,$linenum,$TagName,$_ ;
				printf TAGSFILE "%s\t%s\t%d\n",$TagName,$FullHandle,$linenum;
			}
		}
		printf "%d lines,%d code lines\n",$linenum,$CodeLines;
		printf STATSFILE "%d\t%d\t%d\t%d\t%s\t%s\t%s\t%s\n",$MainNumber,$FunctionsNumber,$ReportsNumber,$OpenFormsNumber,
		thousand_sep($linenum),
		thousand_sep($CodeLines),thousand_sep($CommentsLines),thousand_sep($BlankLines);
		$TotalLines += $linenum;
		$TotalCodeLines += $CodeLines;
		$TotalCommentsLines += $CommentsLines;
		$TotalBlankLines += $BlankLines;
		$TotalMainNumber += $MainNumber ;
		$TotalFunctionsNum += $FunctionsNumber;
		$TotalReportsNum += $ReportsNumber;
		$TotalOpenFormsNum += $OpenFormsNumber ;
	}
}
close ($DIR) ;
return ;
}

sub thousand_sep {
my $number = $_[0] ;
if ( $number !~ /[A-Za-z\.]/ ) {
    $number = reverse join ",", (reverse $number) =~ /(\d{1,3})/g;
}
return $number;
}
