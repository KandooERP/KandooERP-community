use Getopt::Long;
use File::Copy;
if ( ! GetOptions(
	"directory=s"=>\$DirectoryName,		# sub directory where backup files have been placed
	"files=s"=>\$FilesExpression,		# additional filter for file names
	"timestamp=s"=>\$Timestamp,			# additional filter on timestamp
	"copy"=>\$Copy,						# if not set, just check names, else copy and overwrite
	) ) {
		show_doc() ;
		exit(1) ;
	}

$KANDOOTOOLSTEMPDIR=$ENV{"KANDOOTOOLSTEMPDIR"} ;
if ( $KANDOOTOOLSTEMPDIR eq "" ) {
	if ($^O =~ /win/i ) {
		$KANDOOTOOLSTEMPDIR="C:\\TEMP" ;
	} else {
		$KANDOOTOOLSTEMPDIR="/tmp" ;
	}
}

if (!defined($FilesExpression)) {
	$FilesExpression=".*" ;
}

if (!defined($Timestamp)) {
	$Timestamp=".*" ;
}

$TargetDir=$KANDOOTOOLSTEMPDIR . "/" . $DirectoryName;
if ( -d $TargetDir ) {
	opendir (DIRECTORY,$TargetDir) or die "Cannot open directory " . $TargetDir ;
	@FilesList0 = grep (/${FilesExpression}\.4gl\.bkp\.${Timestamp}/, sort readdir(DIRECTORY) );
	@FilesList1=map { s/^/$TargetDir\//;$_ } @FilesList0;
	@FilesList=sort @FilesList0;

	# test source dir
	if (!defined($SourceDir)) {
		$SourceStartDir=".";
		$SourceDir=$SourceStartDir . "/" . $DirectoryName;
	}
	if ( -d $SourceDir ) {
		$a=1;
	} else {
		printf "Source directory $SourceDir does not exist\n";
		die "Exiting" ;
	}

}

$mdl=0;
%CopiedFilesList=[];
while (defined($FilesList[$mdl])) {
	printf "%s ",$FilesList[$mdl];
	if (defined($Copy)) {
		my $SourceFileName=$FilesList[$mdl];
		$SourceFileName =~ s/\.4gl\.bkp\..*/.4gl/ ;
		$SourceFileName =~ s/${TargetDir}// ;
		$SourceFileName = $SourceDir . $SourceFileName ;
		if ( -e $SourceFileName && !defined($CopiedFilesList{$SourceFileName} ) {
			# the source file exists, we are ok
			copy ($FilesList[$mdl],$SourceFileName);
			if ( $? == 0 ) {
				# we say this file has been copied, in case several backups exist for this file
				$CopiedFilesList{$SourceFileName}=1;
				printf "OK";
				$restored++;
			} else {
				printf "ERROR!";
			}
		}
	}
	printf "\n";
	$mdl++;
}
printf "Found %d files, restored %d files\n",$mdl,$restored;

#for module in /tmp/eo/*bkp* 
#do 
#filename=`echo $module | perl -lane '$_ =~ s/\.4gl.*/.4gl/;print $_;'`
#echo $filename
#done
