#!/usr/bin/perl
# Description  : this package contains generic functions
# (c) Copyright Begooden-IT Consulting 2010-2014
# Author eric.vercelletto@begooden-it.com
#  "@(#)$Id: DbSchema.pm 405 2016-10-06 13:30:56Z  $"
# $Rev: 405 $                                             last commit revision number
# $Author: $                                          last commit author
# $Date: 2016-10-06 15:30:56 +0200 (jeu., 06 oct. 2016) $ last commit date
package Ffg::DbSchema;
$ID="\$Id: \$";

BEGIN {
  $OS_win = ($^O eq "MSWin32") ? 1 : 0;
  $OS_aix = ($^O eq "aix") ? 1 : 0;
  $OS_solaris = ($^O eq "Solaris") ? 1 : 0;
  $OS_hpux = ($^O eq "hp-ux") ? 1 : 0;
  $OS_SCO = ($^O eq "sco") ? 1 : 0;
		
if (defined($ENV{"FFGDIR"})) {
	$FfgLib=$ENV{"FFGDIR"} . "/incl" ;
	#$FfgLib =~ s/[\/\\]/\\\//g;
	$FfgLib =~ s/[\/\\]/\//g;
	eval "use lib \"$FfgLib\"";
	die "$@\n" if ($@);
} else {
	die "Please set the FFGDIR env variable";
}
use Storable;

} # End BEGIN

require Exporter;

our @ISA		= qw(Exporter);
our @EXPORT		= qw(
						parse_qxexpt_schema
						parse_schemaSpy
						set_dt_formats
						
					);
our $VERSION	= 1.0;
#use XML::Simple;

sub parse_qxexpt_schema {
	my ($SchemaFile)  =  (@_)  ;
	
	# create xml object
	$xml = new XML::Simple;

	# read the XML file
	$data = $xml->XMLin($SchemaFile,ForceArray => ['table','column','length','primarykey','foreignkey','columnName','column','localcolumn','parentcolumns' ]);
	#$data = $xml->XMLin($SchemaFile,ForceArray => ['table','column','length','primarykey','foreignkey','index','localcolumn','foreigncolumn','index','columns' ]);
	$idx = 0 ;
	my %TablesDesc = () ;
	my %PrimaryKeys = () ;
	my %ForeignKeys = () ;

	foreach my $tableHash ( @{ $data->{'tables'}->{'table'}} ) {
		my $tabname = $tableHash->{'tableName'};
		my $SqlType = "" ;
		# Build primary key if any
		foreach my $pkHash ( @{ $tableHash->{'primarykey'}} ) {
			my $pkdx=0;
			$PrimaryKeys{$tabname}->{'parentTable'} = $tabname ;
			if ( defined(($pkHash->{'columnName'}[$pkdx])) ) {
				while (defined($pkHash->{'columnName'}[$pkdx])) {
					$PrimaryKeys{$tabname}->{'parentColumns'} = $PrimaryKeys{$tabname}->{'parentColumns'} . ',' . $pkHash->{'columnName'}[$pkdx] ;
					$pkdx++ ;
				}
			} elsif ( defined(($pkHash->{'columnName'})) ) {
				$PrimaryKeys{$tabname}->{'parentColumns'} = $PrimaryKeys{$tabname}->{'parentColumns'} . ',' . $pkHash->{'columnName'} ;
			}
				
			$PrimaryKeys{$tabname}->{'parentColumns'} =~ s/^,// ;
		}
		#
		# define foreign keys
		foreach my $fkHash ( @{ $tableHash->{'foreignkey'}} ) {
			$foreignKey = $tabname . ':' . $fkHash->{'foreigntable'} ;
			$ForeignKeys{$foreignKey}->{'parentTable'} = $fkHash->{'foreigntable'} ;
			$ForeignKeys{$foreignKey}->{'childTable'} = $tabname;
			my $fkdx=0;
			# get child columns
			while (defined($fkHash->{'localcolumn'}[$fkdx])) {
				$ForeignKeys{$foreignKey}->{'childColumns'} = $ForeignKeys{$foreignKey}->{'childColumns'} . ',' . $fkHash->{'localcolumn'}[$fkdx] ;
				$fkdx++ ;
			}
			# get parent columns
			$ForeignKeys{$foreignKey}->{'childColumns'} =~ s/^,// ;

			# get parent columns
			my $fkdx=0;
			while (defined($fkHash->{'foreigncolumn'}[$fkdx])) {
				$ForeignKeys{$foreignKey}->{'parentColumns'} = $ForeignKeys{$foreignKey}->{'parentColumns'} . ',' . $fkHash->{'foreigncolumn'}[$fkdx] ;
				$fkdx++ ;
			}
			$ForeignKeys{$foreignKey}->{'parentColumns'} =~ s/^,// ;
		}

		UNIQIDX: foreach my $indHash ( @{ $tableHash->{'index'}} ) {
			my $inddx=0;
			# if this index is unique and no Primary Key defined, we take the index as a PK
			if ( $indHash->{unique} eq 'true' ) {
				if ( !defined($PrimaryKeys{$tabname})) {
					$PrimaryKeys{$tabname}->{'parentTable'} = $tabname ;
				} else {
					next UNIQIDX;
				}
			} else {
				next UNIQIDX;
			}
			if ( defined(($indHash->{'columnName'}[$inddx])) ) {
				while (defined($indHash->{'columnName'}[$inddx])) {
					$PrimaryKeys{$tabname}->{'parentColumns'} = $PrimaryKeys{$tabname}->{'parentColumns'} . ',' . $indHash->{'columnName'}[$inddx] ;
					$inddx++ ;
				}
			} elsif ( defined(($indHash->{'columnName'})) ) {
				$PrimaryKeys{$tabname}->{'parentColumns'} = $PrimaryKeys{$tabname}->{'parentColumns'} . ',' . $indHash->{'columnName'} ;
			}
				
			$PrimaryKeys{$tabname}->{'parentColumns'} =~ s/^,// ;
		}

		my $colOrder=0;
		foreach my $colHash ( @{ $tableHash->{'column'}} ) {
			$colname = $colHash->{'columnName'};
			# printf "%s\n", $colname ;
			$SqlType = $colHash->{'sqlType'};
			if (defined($colHash->{'length'})) {
				$SqlType = $SqlType . '(' . $colHash->{'length'}[0] ;
				if (defined($colHash->{'length'}[1])) {
					$SqlType = $SqlType . ',' . $colHash->{'length'}[1] . ')' ;
				} else {
					$SqlType = $SqlType . ')' ;
				}
			} elsif (defined($colHash->{'precision'})) {
				$SqlType = $SqlType . '(' .  $colHash->{'precision'} . ',' . $colHash->{'scale'} . ')' ;
				$a = 1;
			} elsif (defined($colHash->{'start'})) {
				$SqlType = $SqlType . ' ', $colHash->{'start'} . ' TO ' . $colHash->{'end'} ;
				if (defined($colHash->{'scale'})) {
					$SqlType = $SqlType . ' (', $colHash->{'scale'} . ')' ;
				}
			}
			$TablesDesc{$tabname}->{$colname}->{datatype} = $SqlType ;
			$TablesDesc{$tabname}->{$colname}->{Order} = $colOrder++ ;
			if ( defined($PrimaryKeys{$tabname})) {
				if ($PrimaryKeys{$tabname}->{'parentColumns'} =~ /[^,]*${colname}[,\$]*/ ) {
					$TablesDesc{$tabname}->{$colname}->{IsPK} = 'true' ;
				}
			}
			foreach $FKKey ( keys %ForeignKeys ) {
				if ( $FKKey =~ /^${tabname}:/ ) {
					if ($ForeignKeys{$FKKey}->{'childColumns'} =~ /[^,]*${colname}[,\$]*/ ) {
						$TablesDesc{$tabname}->{$colname}->{IsFK} = 'true' ;
					}
				}
			}
		}	
		$a=1 ;
	} # end tables

	return \%TablesDesc,\%PrimaryKeys,\%ForeignKeys ;
} #end  parse_qxexpt_schema {

sub parse_schemaSpy {
	my $SchemaFile  =  @_[0]  ;
	# create xml object
	$xml = new XML::Simple;

	# read the XML file
	#$data = $xml->XMLin($SchemaFile,ForceArray => ['primaryKey']);
	$data = $xml->XMLin($SchemaFile,ForceArray => ['primaryKey','parent','child']);
	$data = $xml->XMLin($SchemaFile,ForceArray => ['column','primaryKey','parent','child']);

	$idx = 0 ;

		my %TablesDesc = () ;
	my %PrimaryKeys = () ;
	my %ForeignKeys = () ;
	my %LookupKeys = () ;
	$DateTimeFormatsPtr=set_dt_formats();
	%DatetimeFormats=%$DateTimeFormatsPtr;
	#$TablesListString="sr_events\|supported_products\|operating_systems\|service_request";
	$TablesListString=".*";
	TABLIST: foreach my $tabname (keys %{ $data->{'tables'}->{'table'} } ) {
		if ( $tabname !~ /$TablesListString/ ) {
			next TABLIST;
		}
		$colOrder=0;
		#printf "table: %s\n",$tabname ;
		#printf "%s\n",keys %{ $data->{'tables'}->{'table'}->{$tabname}->{'column'}};
		foreach my $colname (sort { $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$a}->{'id'} <=> $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$b}->{'id'} } keys %{ $data->{'tables'}->{'table'}->{$tabname}->{'column'}} ) {
			#printf "%s    %s\n",$tabname,$colname;
			if ( $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'type'} =~ /(\w*CHAR)/i ) {
					$TablesDesc{$tabname}->{$colname}->{datatype} = sprintf "%s(%d)",$1,
					$data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'size'};
			} elsif ( $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'type'} =~ /(DECIMAL|MONEY)/ ) {
					$TablesDesc{$tabname}->{$colname}->{datatype} = sprintf "%s(%d,%d)",$1,
					$data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'size'},
					$data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'digits'};
			} elsif ( $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'type'} =~ /(DATETIME|INTERVAL)/ ) {
					$TablesDesc{$tabname}->{$colname}->{datatype} =sprintf "%s",$DatetimeFormats{$data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'size'}};
			} else {
					$TablesDesc{$tabname}->{$colname}->{datatype} = sprintf "%s",
					$data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'type'} ;
			}
			if ( $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'nullable'} eq "false" ) {
				$TablesDesc{$tabname}->{$colname}->{NotNull} = "true" ;
			} 
			$a=1 ;
			$TablesDesc{$tabname}->{$colname}->{Order} = $colOrder++ ;

			# define foreign keys
			#cif ( defined($data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'} )  
			#&& $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}->{'implied'} eq 'false'  ) {
			my $paridx=0;
			if ( defined($data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'} )) { 
				while (defined($data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}[$paridx])) {
					if ($data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}[$paridx]->{'implied'} eq 'false'  ) {
						$parentTable = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}[$paridx]->{'table'};
						$parentColumn = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}[$paridx]->{'column'};
						# modif ericv 20210409 : changing FK Key ##- are old lines
						##- my $foreignKey = sprintf "%s:%s",$tabname,$parentTable ;
						# key is FK name because a table can have more than 1 FK to 1 table
						my $foreignKey = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}[$paridx]->{'foreignKey'}; 
						if (!defined($ForeignKeys{$foreignKey})  ) {
							$ForeignKeys{$foreignKey}->{'parentTable'} = $parentTable;
							$ForeignKeys{$foreignKey}->{'childTable'} = $tabname;
							$ForeignKeys{$foreignKey}->{'parentColumns'} = $parentColumn;
							$ForeignKeys{$foreignKey}->{'childColumns'} = $colname;
							$ForeignKeys{$foreignKey}->{'FKName'} = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}[$paridx]->{'foreignKey'};
						} else {
							$ForeignKeys{$foreignKey}->{'childColumns'} = $ForeignKeys{$foreignKey}->{'childColumns'} . ',' . $colname ; 
							$ForeignKeys{$foreignKey}->{'parentColumns'} = $ForeignKeys{$foreignKey}->{'parentColumns'} . ',' . $parentColumn ; 
						}
					} else {
						# this is an implied lookup key
						$parentTable = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}[$paridx]->{'table'};
						$parentColumn = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}[$paridx]->{'column'};
						my $lookupKey = sprintf "%s:%s",$tabname,$parentTable ;
						if (!defined($LookupKeys{$lookupKey})  ) {
							$LookupKeys{$lookupKey}->{'parentTable'} = $parentTable;
							$LookupKeys{$lookupKey}->{'childTable'} = $tabname;
							$LookupKeys{$lookupKey}->{'parentColumns'} = $parentColumn;
							$LookupKeys{$lookupKey}->{'childColumns'} = $colname;
							$LookupKeys{$lookupKey}->{'FKName'} = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'parent'}[$paridx]->{'foreignKey'};
						} else {
							$LookupKeys{$lookupKey}->{'childColumns'} = $LookupKeys{$lookupKey}->{'childColumns'} . ',' . $colname ; 
							$LookupKeys{$lookupKey}->{'parentColumns'} = $LookupKeys{$lookupKey}->{'parentColumns'} . ',' . $parentColumn ; 
						}
					}
					$paridx++;
				}
			}
			if ( defined($PrintPKeys)) { # in case we want more details about primary keys
				#if ( defined($data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'child'}->{'implied'}  )
				if ( defined($data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'child'})) {
					my $chlidx=0;
					while (defined($data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'child'}[$chlidx])) {
						if ($data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'child'}[$chlidx]->{'implied'} eq 'false'  ) {
							$childTable = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'child'}[$chlidx]->{'table'};
							$childColumn = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'child'}[$chlidx]->{'column'};
							$foreignKey = $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$colname}->{'child'}[$chlidx]->{'foreignKey'};
							my $key = sprintf "%s:%s",$tabname,$childColumn ;
							if (!defined($PrimaryKeys{$foreignKey})  ) {
								$PrimaryKeys{$foreignKey}->{'parentTable'} = $tabname ;
								$PrimaryKeys{$foreignKey}->{'childTable'} = $childTable;
								$PrimaryKeys{$foreignKey}->{'parentColumns'} = $colname;
								$PrimaryKeys{$foreignKey}->{'childColumns'} = $childColumn;
							} else {
								$PrimaryKeys{$foreignKey}->{'childColumns'} = $PrimaryKeys{$foreignKey}->{'childColumns'} . ',' . $childColumn;
								$PrimaryKeys{$foreignKey}->{'parentColumns'} = $PrimaryKeys{$foreignKey}->{'parentColumns'} . ',' . $colname ; 
							}
						}
						$chlidx++;
					}
				}
			}
		} #  end columns

		# Look into  indexes
		#if ( !defined($data->{'tables'}->{'table'}->{$tabname}->{'primaryKey'}) ) {
		# Watch out: in schemaspy, if there is only 1 index, the structure is different!!!
		if (defined($data->{'tables'}->{'table'}->{$tabname}->{'index'}->{'column'}) ) {
			if ($data->{'tables'}->{'table'}->{$tabname}->{'index'}->{'unique'} eq 'true' ) {
				$indexname='unique_key';
				foreach my $colname ( keys %{ $data->{'tables'}->{'table'}->{$tabname}->{'index'}->{'column'} } ) {
					$a=1;
					$collist=sprintf "%s,%s",$collist,$colname;
					$TablesDesc{$tabname}->{$colname}->{IsUK} = 'true' ;
					$TablesDesc{$tabname}->{$colname}->{IsPK} = 'true' ;
				}
				$collist =~ s/,$|^,//;
				$UniqueKeys{$tabname}->{$indexname}->{'columns'}=$collist ;
				$UniqueKeys{$tabname}->{$indexname}->{'table'}=$tabname;
				$collist="";
			}
		} else {
			# table has more than one index
			foreach my $indexname (keys %{$data->{'tables'}->{'table'}->{$tabname}->{'index'} }) {
				if ( $data->{'tables'}->{'table'}->{$tabname}->{'index'}->{$indexname}->{'unique'} eq 'true') {
					my $collist="";
					
					foreach my $colname ( keys %{ $data->{'tables'}->{'table'}->{$tabname}->{'index'}->{$indexname}->{'column'} } ) {
						$a=1;
						$collist=sprintf "%s,%s",$collist,$colname;
						$TablesDesc{$tabname}->{$colname}->{IsUK} = 'true' ;
						$TablesDesc{$tabname}->{$colname}->{IsPK} = 'true' ;
					}
					$collist =~ s/,$|^,//;
					$UniqueKeys{$tabname}->{$indexname}->{'columns'}=$collist ;
					$UniqueKeys{$tabname}->{$indexname}->{'table'}=$tabname;
					$collist="";
				} else {
					my $collist="";
					foreach my $colname ( keys %{ $data->{'tables'}->{'table'}->{$tabname}->{'index'}->{$indexname}->{'column'} } ) {
						$a=1;
						$collist=sprintf "%s,%s",$collist,$colname;
						$TablesDesc{$tabname}->{$colname}->{DuplK} = 'true' ;
					}
					$collist =~ s/,$|^,//;
					$DuplicateKeys{$tabname}->{$indexname}->{'columns'}=$collist ;
					$DuplicateKeys{$tabname}->{$indexname}->{'table'}=$tabname;
					$collist="";
				}
			}
		}
		
		# check primary keys: caution, the format is variable sometimes array sometimes HASH
		if ( defined($data->{'tables'}->{'table'}->{$tabname}->{'primaryKey'}) ) {
			$PKColList="" ;
			my $kdx=0;
			$PrimaryKeys{$tabname}->{'parentTable'} = $tabname ;
			while (defined($data->{'tables'}->{'table'}->{$tabname}->{'primaryKey'}[$kdx]->{'column'})) {
				if ($data->{'tables'}->{'table'}->{$tabname}->{'primaryKey'}[$kdx]->{'sequenceNumberInPK'} == 1 ) {
					$PrimaryKeys{$tabname}->{'parentColumns'} = $data->{'tables'}->{'table'}->{$tabname}->{'primaryKey'}[$kdx]->{'column'}
				} else {
					$PrimaryKeys{$tabname}->{'parentColumns'} = $PrimaryKeys{$tabname}->{'parentColumns'} . ',' . $data->{'tables'}->{'table'}->{$tabname}->{'primaryKey'}[$kdx]->{'column'} ;
				}
				$kdx++ ;
			}
		} # end primary keys

		foreach my $colname (sort { $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$a}->{'id'}  <=> $data->{'tables'}->{'table'}->{$tabname}->{'column'}->{$b}->{'id'} } keys %{ $data->{'tables'}->{'table'}->{$tabname}->{'column'}} ) {
			if ( defined($PrimaryKeys{$tabname})) {
				if ($PrimaryKeys{$tabname}->{'parentColumns'} =~ /[^,]*${colname}[,\$]*/ ) {
					$TablesDesc{$tabname}->{$colname}->{IsPK} = 'true' ;
				}
			}
			
			#foreach my $UniqueIndex ( keys  %{ $UniqueKeys{$tabname} } ) {
			#	if ( defined($UniqueKeys{$tabname}->{$UniqueIndex}->{'columns'})) {
			#		if ($UniqueKeys{$tabname}->{$UniqueIndesx}->{'columns'} =~ /[^,]*${colname}[,\$]*/ ) {
			#			$TablesDesc{$tabname}->{$colname}->{IsUK} = 'true' ;
			#		}
			#	}
			#}
			#TODO: should this block be checked after # end tables ( L 359 ? )
			foreach $FKKey ( keys %ForeignKeys ) {
				#if ( $FKKey =~ /^${tabname}:/ ) {  # fixed ericv 2021-04-11n
				if ( $ForeignKeys{$FKKey}->{'childTable'} eq ${tabname} ) {
					if ($ForeignKeys{$FKKey}->{'childColumns'} =~ /[^,]*${colname}[,\$]*/ ) {
						$TablesDesc{$tabname}->{$colname}->{IsFK} = 'true' ;
					}
				}
			}
		}
	$a=1;
	} # end tables

	return \%TablesDesc,\%PrimaryKeys,\%ForeignKeys,\%UniqueKeys,\%LookupKeys,\%DuplicateKeys ;
} # end parse_schemaSpy

sub set_dt_formats {
	$DtFormats{4} = uc ("datetime year to year");
	$DtFormats{7} = uc ("datetime year to month");
	$DtFormats{10} = uc ("datetime year to day");
	$DtFormats{13} = uc ("datetime year to hour");
	$DtFormats{16} = uc ("datetime year to minute");
	$DtFormats{19} = uc ("datetime year to second");
	$DtFormats{21} = uc ("datetime year to fraction(1)");
	$DtFormats{22} = uc ("datetime year to fraction(2)");
	$DtFormats{23} = uc ("datetime year to fraction(3)");
	$DtFormats{24} = uc ("datetime year to fraction(4)");
	$DtFormats{25} = uc ("datetime year to fraction(5)");
	
	return \%DtFormats;
}