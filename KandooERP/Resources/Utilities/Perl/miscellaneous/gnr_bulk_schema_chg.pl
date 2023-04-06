#!/usr/bin/perl
# gnr_sch_chg.pl : applies massive schema changes
# (c) Copyright Begooden-IT Consulting 2010-2018
# Author eric.vercelletto@begooden-it.com
# $Rev: 320 $:                                             last commit revision number
# $Author: $:                                          last commit author
# $Date: 2016-01-22 20:02:59 +0100 (ven., 22 janv. 2016) $: last commit date
BEGIN {
$PublicLib=$ENV{"PUBLICLIB"};
if ( length($PublicLib) == 0 ) {
	$PublicLib="/home/informix/incl";
}
eval "use lib \"$PublicLib\"";
die "$@\n" if ($@);
$OS_win = ($^O eq "MSWin32") ? 1 : 0;
$Version="@(#)$Id: ifmx_perfcollect.pl 320 2016-01-22 19:02:59Z  $:";
} # End BEGIN
use PublicIfmx::Generic;
use PublicIfmx::Ids;
use Getopt::Long;
use File::Basename;
use File::Copy;
use Time::ParseDate;
use File::stat ;
use File::Copy ;

generate_schema_changes () ;

sub generate_schema_changes {
	if ( ! GetOptions(
		"version"=>\$ShowVersion,
		"database=s"=>\$DatabaseName,			# regular expression to be searched in the input file lines
		"tablesinclude=s"=>\$TablesInclude,			# regular expression to be searched in the input file lines
		"tablesexclude=s"=>\$TablesExclude,			# regular expression to be searched in the input file lines
		"columnsinclude=s"=>\$ColumnsInclude,			# regular expression to be searched in the input file lines
		"columnsexclude=s"=>\$ColumnsExclude,			# regular expression to be searched in the input file lines
		"changeexpression=s"=>\$ChangeExp,			# regular expression to be searched in the input file lines
		"toexpression=s"=>\$ToExp,			# regular expression (ignorecase)  be searched in the input file lines ignorecase
		"schemafile=s"=>\$SchemaFile,				# outfile
		"outfile=s"=>\$OutFile,				# outfile
		"help"=>\$ShowDocumentation,
		) ) 
	{
			show_doc() ;
			exit(1) ;
	}

	if (!defined($SchemaFile)) {
		$SchemaFile=sprintf "/tmp/%s",$DatabaseName ;
		my $cmd = sprintf "dbschema -d %s %s",$DatabaseName,$SchemaFile ;
		system ($cmd) ;
	}

	if ( !defined($TablesInclude)) {
		$TablesInclude=".*";
	}
	if ( !defined($ColumnsInclude)) {
		$ColumnsInclude=".*";
	}

	if ( !defined($TablesExclude)) {
		$TablesExclude="@Qjckrixjlzrj";
	}
	if ( !defined($ColumnsExclude)) {
		$ColumnsExclude="@Qjckrixjlzrj";
	}

	open SCHEMA,$SchemaFile or die "Cannot open schema file " . $SchemaFile ;
	open OUT,">$OutFile" or die "Cannot open outfile " . $OutFile ;
	$/ = ";";

	Schema: while (<SCHEMA> ) {
		if ( $_ =~ /^\s*$/ ) {
			next;
		}
		if ( $_ =~ /create.*\stable\s*\"\w+\"\.(\w+).*\)/sm ) {
			$TableName=$1;
			@TableDefinition = split (/\n/,$&) ;
			if ( $TableName =~ /$TablesExclude/ ||  $TableName !~ /$TablesInclude/ ) {
				next Schema ;
			}
			printf "%s\n",$TableName ;
			my $cdx=0;
			Column: while (defined($TableDefinition[$cdx])) {
				# Exclude named columns or include
				$TableDefinition[$cdx] =~ s/,\s*[\n\r]//s ;
				# Keep out empty lines
				if ($TableDefinition[$cdx] =~ /^\s*$|^\s*[\(\)]\s*$|create.*table/ ) {
					$cdx++;
					next Column;
				}
				# column definition line
				if ( $TableDefinition[$cdx] !~ /^\s*(\w+)\s+(\w+.*)/) {
					$cdx++;
					next Column ;
				} else {
					$From = $& ;
					$ColumnName=$1;
					$ColType=$2;
					$ColDef=$3;
				}
				if ( $ColumnName =~ /$ColumnsExclude/ ||  $ColumnName !~ /$ColumnsInclude/ ) {
					$cdx++;
					next Column ;
				}

				if ( $TableDefinition[$cdx] =~ /${ChangeExp}/ ) {
				 	$ResChange=$&;
					if ( $ToExp =~ /\$ResChange/ ) {
						$ToExp=$`. $ResChange . $' ;
						$a=1;
					}
				 	$ColType =~ s/$ResChange/${ToExp}/ ;
					$AlterStmt = sprintf "alter table %s modify %s %s%s;\n",$TableName,$ColumnName,$ColType,$ColDef;
					printf OUT "%s\n",$AlterStmt ;
					printf "%s\n",$AlterStmt ;
				}
				$cdx++;
			}
		}
	}

}
