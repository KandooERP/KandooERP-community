package Ffg::ParseForms;
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
						parse_fm2
						set_LyciaFieldDefs
						get_tables_list_from_form
					);
our $VERSION	= 1.0;
use 5.010;
use File::Basename;
use Ffg::Misc;
#use strict;
#use warnings;
#use List::MoreUtils qw(uniq);
use XML::LibXML;
use XML::LibXML::Reader qw( XML_READER_TYPE_END_ELEMENT );
use File::Basename;


#main () ;
#sub main () {
#    my $FormFileName = 'I:\\Users\\BeGooden-IT\\git\\MaiaERP\\apps\\MaiaERP\\source\\per\\sr\\f_history.fm2';
#    my $FormFileName = 'E:\\Users\\BeGooden-IT\\Projects\\QuerixTools\\Ffg\\GUI\\source\\f_gridpanel.fm2';
#    my $FormFileName = 'E:\\Users\\BeGooden-IT\\Projects\\QuerixTools\\Ffg\\GUI\\source\\f_run_ffg.fm2';
#    parse_fm2 ($FormFileName);
#    $a=1;
#}

sub parse_fm2 {
    my ($FormFileName,$DBSchemaPtr,$DataEquivPtr,$ModeX ) =  (@_ ) ;
    our $FormName=basename($FormFileName);
    our $tableIndex=0;
    our $parentLocation=0;
	our $Mode=$ModeX;	# Mode is set to global as it may interfere in process_form_node 
	$FormName =~ s/\.fm2//;
	$ScreenRecOrder=0;
	#undef ($ScreenRecord);
	$ScreenRecord=();
	$TableList=();
	@TableList=();
	undef($SRTableList);
	undef(@SRTabList);

    my $dom = XML::LibXML->load_xml(location => $FormFileName);
	if (defined($Mode) && $Mode =~ /translate/ ) {
		# used for the script that translates the forms lables
		our $SupportedWidgets="Label\$|TextField\$\|TextArea\$\|Calendar\$\|TimeEditField\$\|Slider\$\|Spinner\|CheckBoxList\$\|CheckBox\$\|ComboBox\$\|ListBox\$\|RadioGroup\$|RadioButtonList\$|TableColumn\$|GroupBox\$|Button\$|Browser\$|Canvas\$|FunctionField\$|ProgressBar\$";
	} else {
		# used for the regular forms
		our $SupportedWidgets="TextField\$\|TextArea\$\|Calendar\$\|TimeEditField\$\|Slider\$\|Spinner\|CheckBoxList\$\|CheckBox\$\|ComboBox\$\|ListBox\$\|RadioButtonList\$";
		# Widgets that need initialization at beginning
		our $WidgetsForInit="ComboBox\$\|ListBox\$" ;
	}
    # documentElement is more straight-forward than findnodes('/').
    $level=0;
	%DBSchema=%$DBSchemaPtr;
	%DataEquiv=%$DataEquivPtr;
	$CurrentContainerOrder=0;
    process_form_node($dom->documentElement);
    return \$Fields,\$ScreenRecord,\$TableList ;
} # end parse_fm2


sub process_form_node {
	my $node = shift;
    my $tabs = '  ' x $level++ ;

    my $nodeName=$node->nodeName;
	#printf "%s\n",$nodeName ;
    if ( $nodeName =~ /\AGridPanel\Z|\ACoordPanel\Z|\AGroupBox\Z|\AStackPanel\Z|\ATable\Z|\AStackPanel\Z|\ATreeTable\Z\ATabPage\Z|\ATab\Z/) {
		# handling form containers nodes
		$CurrentContainerType=$nodeName;
		$CurrentContainerName=$node->getAttribute("identifier");
		$CurrentContainerOrder++;
		if (defined($DEBUGPRINT)) { printf LOGFILE "Caught %s container called %s\n",$nodeName,$node->getAttribute("identifier"); }
        if (defined($node->getAttribute("gridItemLocation"))) {
            my @Location=split /,/,$node->getAttribute("gridItemLocation");
            #printf "%s -> %s gridItemLocation=%s\n",$nodeName,$node->getAttribute("identifier"),$node->getAttribute("gridItemLocation");
            $ContainerLocation{$node->getAttribute("identifier")}=$Location[1];
            $a=1;
        } elsif (defined($node->getAttribute("location"))) {
            my $Location=$node->getAttribute("location");
            $a=1;
        }
        if ( $nodeName eq "Table") {
            $tableIndex=0;
			$SrName = $node->getAttribute("identifier") ;
			$ArrayRecord->{$SrName}->{'visible'} = $node->getAttribute("visible");
			if (defined($node->getAttribute("rowCount"))) {
				$ScreenRecord->{$FormName}->{$SrName}->{'ElemCount'} = $node->getAttribute("rowCount");
			} else {
				$ScreenRecord->{$FormName}->{$SrName}->{'ElemCount'} = 10; # set arbitrary number of rows, rowcount has been forgotten
			}
        }
    } # elsif ($nodeName =~ /$SupportedWidgets/ || $nodeName eq "TableColumn" ) {    trying to catch groupbox for translation
	if ($nodeName =~ /$SupportedWidgets/ || $nodeName eq "TableColumn" ) {    
		# trying to catch groupbox for translation modif 11/09/2018
		# handling supported widgets  and TableColumns 
        my $identifier=$node->getAttribute("identifier");
		my $Widget=$nodeName ;
        
        my $parent=$node->parentNode;
        # prepare exact position in form, if the widget is inside a container => we take the order number of container, else 0
        if (defined($parent->getAttribute("gridItemLocation"))) {
            if($parent->getAttribute("gridItemLocation") =~ /\d+,(\d+),\d+,\d+/ ) {
                $parentLocation=$1;
            }
            $a=1;
        } elsif (defined($parent->getAttribute("location"))) {
            if ($location=$parent->getAttribute("location") =~ /\d+qch,(\d+)qch/) {
                $parentLocation=$1;
            } elsif ($location=$parent->getAttribute("location") =~ /\d+qch,(\d+)qch/) {
                $parentLocation=$1;
            } else {
               $parentLocation=0; 
            }
            $a=1;
        }

        if ($node->getAttribute("gridItemLocation") =~ /(\d+),(\d+),\d+,\d+/ ) {
            $Location=sprintf "%04d,%04d",$2,$1;
        } elsif ($node->getAttribute("location") =~ /(\d+)qch,(\d+)qch/) {
            $Location=sprintf "%04d,%04d",$2,$1;
        } elsif ($node->getAttribute("location") =~ /(\d+),(\d+)/) {
            $Location=sprintf "%04d,%04d",int($2/12),int($1/10);
        } elsif ( $node->parentNode->nodeName eq "TableColumn") {
            $tableIndex++;
            $Location=sprintf "%04d,%04d",0,$tableIndex;
			#push ( @{$TablesList->{$tabname}->{ChildOf} },$1);
			push ( @{ $ScreenRecord->{$FormName}->{$SrName}->{TableFields} },$node->getAttribute("identifier"));
			#===> check here how to feell the screen record)
        }

        if ( $nodeName =~ /$SupportedWidgets/ ) {
			undef($HasBoxItems);
            $dataType=$node->getAttribute("dataType");
			
            if (defined($DEBUGPRINT)) { printf LOGFILE "Caugth %s widget called %s (%s)\n",$nodeName,$identifier,$dataType; }
            $CurrentWidget=$nodeName;
            my $FieldName=$node->getAttribute("identifier");
            if (defined($node->getAttribute("fieldTable"))) {
				if (defined($node->getAttribute("fieldTable"))) {
					$TableName = lc($node->getAttribute("fieldTable"));
					if ( $TableName eq "formonly" && defined($node->getAttribute("lookupTable"))) {
						# lookupTable is a specific non supported Querix form attribute that allows 
						# to identify a formonly field as lookup value to another table
						$TableName=$node->getAttribute("lookupTable");
						push (@{$TableList->{$TableName}->{FieldList}},$FieldName);
						push (@{$TableList->{$TableName}->{ColumnsList}},$node->getAttribute("lookupColumn"));
					} else {
						push (@{$TableList->{$TableName}->{FieldList}},$FieldName);
						push (@{$TableList->{$TableName}->{ColumnsList}},$FieldName);
					}
					# push (@{$TableList->{$TableName}->{FieldList}},$FieldName);
					$TableList->{$TableName}->{'Count'}++ ;
					if (!defined($TableList->{$TableName}->{InputFieldsCount})) {
						$TableList->{$TableName}->{InputFieldsCount} = 0 ;
					}
				} else {
					printf STDERR "Widget %s (%s) has a field name but no column name ",$nodeName,$FieldName ;
					$TableName="formonly";
				}
            } else {
				$TableName="formonly";
            }

			# not so brilliant but has to be
			if ($TableName =~ /^$/ ) {
				$TableName="formonly";
			}
			my $Key=sprintf "%s:%s:%s",$FieldName,$TableName,$CurrentContainerName;
            if ( defined($Fields->{$FormName}->{$Key})) {
                # fields can be repeated in a screen record, define only once
                $idx++;
                next ;
            }
            my $CtnrKey=sprintf "%s:%s:%s",$FormName,$FieldName,$TableName;
			$Container{$CtnrKey}=$CurrentContainerName;
			$Fields->{$FormName}->{$Key}->{WidgetType} = $Widget ;
			if ( $Widget =~/$WidgetsForInit/) {
				# put a special flag if this widget needs to be initialization
				$Fields->{$FormName}->{$Key}->{RequiresInit} = 1;
				$Fields->{$FormName}->{WidgetsForInit}++;
			}
			$Fields->{$FormName}->{$Key}->{ContainerType} = $CurrentContainerType ;
			$Fields->{$FormName}->{$Key}->{ContainerName} = $CurrentContainerName ;
			$Fields->{$FormName}->{$Key}->{ContainerOrder} = $CurrentContainerOrder;
			$Fields->{$FormName}->{$Key}->{Order} = sprintf "%02d,%s",$CurrentContainerOrder,$Location;
			#$Fields->{$FormName}->{$Key}->{text}=$node->getAttribute("text");


# if field is formonly && tablename is in Schema => take FK of this table with one table of this section

            if (defined($node->getAttribute("fieldTable")) && !defined($node->getAttribute("lookupTable"))) {
                $Fields->{$FormName}->{$Key}->{Table} = $node->getAttribute("fieldTable");
			} elsif ( defined($node->getAttribute("lookupTable"))) {
				# This is a trick to be able to map a formonly to its reference table (case when duplicates of 'description' from same table)
				$Fields->{$FormName}->{$Key}->{Table} = $node->getAttribute("fieldTable");
				$Fields->{$FormName}->{$Key}->{lookupTable} = $node->getAttribute("lookupTable");
			} else {
				$Fields->{$FormName}->{$Key}->{Table} ="formonly";
            }

            if (!defined($node->getAttribute("fieldColumn")) && !defined($node->getAttribute("lookupColumn"))) {
				# The field name is contained in the parent node
                $Fields->{$FormName}->{$Key}->{Column} = $FieldName ;
				$Fields->{$FormName}->{$Key}->{Field} = $FieldName ;
                $ColName=$Fields->{$FormName}->{$Key}->{Column};
			} elsif ( defined($node->getAttribute("lookupColumn"))) {
				# This is a trick to be able to map a formonly field 
				# to its reference table (case when duplicates of 'description' from same table)
                $Fields->{$FormName}->{$Key}->{Column} = $node->getAttribute("lookupColumn") ;
				$Fields->{$FormName}->{$Key}->{Field} = $FieldName ;
                $ColName=$Fields->{$FormName}->{$Key}->{Column};
            } else {
                # fields with same name not allowed in graphic form, we must match field name with table column ( yes this is ugly )
                $Fields->{$FormName}->{$Key}->{Column} = $node->getAttribute("fieldColumn");
				$Fields->{$FormName}->{$Key}->{Field} = $FieldName ;
                $ColName=$Fields->{$FormName}->{$Key}->{Column};
            }
			# This is a trick to be able to map a formonly field to its reference table (case when duplicates of 'description' from same table)
            if (defined($node->getAttribute("lookupColumn"))) {
                $Fields->{$FormName}->{$Key}->{lookupColumn} = $node->getAttribute("lookupColumn");
            } 
            
            #if (defined($TableName) && $TableName !~ /formonly/i && $Mode !~ /translate/ ) {

			if (defined($DBSchema{$TableName}{$ColName}->{datatype})) {
               	$Fields->{$FormName}->{$Key}->{ColDef} = $DBSchema{$TableName}{$ColName}->{datatype};
				$Fields->{$FormName}->{$Key}->{ColDef} =~ s/serial/integer/ ;
			} else {
				# Not a column in this table, try to catch form attribute dataType
                my $dataType=$node->getAttribute("dataType");
				if ($dataType ne "") {
                	$Fields->{$FormName}->{$Key}->{ColDef} = get_coldef($ColName,uc($dataType));
	            } else {
					printf STDERR "Error: Field %s not found in table %s, please check form file definition\n",$ColName,$TableName;
					printf LOGFILE "Error: Field %s not found in table %s, please check form file definition\n",$ColName,$TableName;
				}
			}
            
            if ( defined($node->getAttribute("noEntry"))) {
                $Fields->{$FormName}->{$Key}->{Noentry} = $node->getAttribute("noEntry");
            } else {
                $Fields->{$FormName}->{$Key}->{Noentry} = "false" ;
            }
            if ( defined($node->getAttribute("visible") )) {
                $Fields->{$FormName}->{$Key}->{Visible} = $node->getAttribute("visible") ;
            } else {
                $Fields->{$FormName}->{$Key}->{Visible} = 'true' ;
            }
			
            # This attribute is a specific FFG attribute, no Lycia standard
			if ( $Fields->{$FormName}->{$Key}->{WidgetType} =~ /\w+Box/ ) {
				
				if (defined($node->getAttribute("boxFill"))) {
                	$Fields->{$FormName}->{$Key}->{boxFill} = $node->getAttribute("boxFill") ;
            	} else {
                	$Fields->{$FormName}->{$Key}->{boxFill} = 'atStart' ;
				}
            }
			# check if field has to be input or not
			if ( ($Fields->{$FormName}->{$Key}->{Noentry} eq 'false' || !defined(($Fields->{$FormName}->{$Key}->{Noentry})))
			&& ($Fields->{$FormName}->{$Key}->{Visible} ne 'false' || !defined(($Fields->{$FormName}->{$Key}->{Visible})))) {
				$TableList->{$TableName}->{InputFieldsCount}++ ;
				$CountedColumns->{$Key}++;
			}
			if ( $Mode =~ /translate/) {
				$Fields->{$FormName}->{$Key}->{text}=$node->getAttribute("text");
				if (!defined($Fields->{$FormName}->{$Key}->{text})) {
					delete($Fields->{$FormName}->{$Key}->{text});
				}
				$Fields->{$FormName}->{$Key}->{toolTip}=$node->getAttribute("toolTip");
				if (!defined($Fields->{$FormName}->{$Key}->{toolTip})) {
					delete($Fields->{$FormName}->{$Key}->{toolTip});
				}
				$Fields->{$FormName}->{$Key}->{comment}=$node->getAttribute("comment");
				if (!defined($Fields->{$FormName}->{$Key}->{comment})) {
					delete($Fields->{$FormName}->{$Key}->{comment});
				}
				$Fields->{$FormName}->{$Key}->{title}=$node->getAttribute("title");
				if (!defined($Fields->{$FormName}->{$Key}->{title})) {
					delete($Fields->{$FormName}->{$Key}->{title});
				}
				$a=1;
			}
            $a=1;	
        
        }	# end Supported Widgets
		$a=1;
	} elsif ($nodeName =~ /BoxItem/ ) {
		# This widgets has hard code Box Items, no need to fill it by function
		my $parent=$node->parentNode;
        my $FieldName=$parent->getAttribute("identifier");
		my $TableName="";
		if (defined($parent->getAttribute("fieldTable"))) {
			$TableName=$parent->getAttribute("fieldTable");
		} else {
			$TableName="formonly";
		}
		my $parentKey=sprintf "%s:%s:%s",$FieldName,$TableName,$CurrentContainerName;
		$HasBoxItems=1;
		$Fields->{$FormName}->{$parentKey}->{HasBoxItems}=1;
    } elsif ($nodeName eq "ScreenRecord") {
		if (defined($DEBUGPRINT)) { printf LOGFILE "Caugth a screen Record %s for %s\n",$nodeName,$node->getAttribute("identifier") ; }
		my %Table=();
		# ===> this is the old code, to be translated accordingly
		my @FieldList = () ;
		my $SrName = $node->getAttribute("identifier") ;
		@FieldList = split (',',$node->getAttribute("fields"));
		$FieldCount = $#FieldList ;
		# first take match table for fields and tables : SR has no 'elements' tag
		# but 
		#if ( !defined($node->getAttribute("elements")) && !defined($ScreenRecord->{$FormName}->{$SrName})) { # 2018-01-19
		
		# if ( !defined($node->getAttribute("elements"))) { 
		# elements is no more part of generated data in FD ericv 2018-12-30
		# check if the SrName is a table name or formonly
		if (defined($DBSchema{$SrName}) || $SrName =~ /formonly/i ) {
			# this is NOT an input array screen record
			# since information in screen record is not trusted information, we build TableList from the Form list 
			# modif ericv 20190214
			#$TabName = lc($node->getAttribute("identifier")) ;
			#my $ff=0;
			# All the fields come from same table
			#while (defined($FieldList[$ff])) {
			#	if ( $FieldList[$ff] =~ /(\w+)\.(\w+)/ ) {
			#		$FieldList[$ff] = $2;
			#		$Table{$2} = $1;
			#	} else {
			#		$Table{$FieldList[$ff]}=$TabName;
			#	}
			#	$ff++;  
			#}
			#$TableList->{$TabName}->{'FieldList'} = [ @FieldList ] ;
			#$TableList->{$TabName}->{'Count'} = $FieldCount + 1 ;
			#$SRTabList[$jdx]=$TabName;  # 1 element = table for each field
			#$ScreenRecord->{$FormName}->{$SrName}->{'FieldList'} = [ @FieldList ] ;
			#$ScreenRecord->{$FormName}->{$SrName}->{'TableList'}[0] = $TabName ;
			#$ScreenRecord->{$FormName}->{$SrName}->{'Order'}++ ;
			
			$a=1;
			#$ScreenRecord->{$FormName}->{$SrName}->{'Order'}++ ;
		} else {
			#this IS a Screen Record for array
			# $ScreenRecord->{$FormName}->{$SrName}->{'ElemCount'} = $node->getAttribute("elements") ;
			# Put any number of elements ericv 2018-12-30
			$ScreenRecord->{$FormName}->{$SrName}->{'ElemCount'} = 2 ;
			$ScreenRecord->{$FormName}->{$SrName}->{'Order'} = ++$ScreenRecOrder ;
			#$ScreenRecord->{$FormName}->{$SrName}->{'FieldList'} = [ @FieldList ] ;
			$flx = 0 ;
			while ( defined($FieldList[$flx]) ) {
				if ( $FieldList[$flx] =~ /(\w+)\.(\w+)/ ) {
					my $tabname=lc($1);
					$ScreenRecord->{$FormName}->{$SrName}->{'FieldList'}[$flx] = $2 ;
					$FieldList[$flx]=$2;
					$TableList->{$tabname}->{'ScreenRecord'} = $SrName;
					$TableList->{$tabname}->{'ScreenRecordNum'} = $ScreenRecord->{$FormName}->{$SrName}->{'Order'} ;
					$SRTableList = $SRTableList . ',' . $tabname;
					my $Key=sprintf "%s:%s:%s",$FormName,$2,$tabname;
					my $Container=$Container{$Key};
					$ScreenRecord->{$FormName}->{$SrName}->{'CntrnList'}[$flx] = $Container ;
					$Key=sprintf "%s:%s:%s",$2,$tabname,$Container;
					$Fields->{$FormName}->{$Key}->{ScreenRecord}=$SrName;
				} else {
					$ScreenRecord->{$FormName}->{$SrName}->{'FieldList'}[$flx] = $FieldList[$flx];
					if (defined($Table{$FieldList[$flx]})) {
						$TableList->{$Table{$FieldList[$flx]}}->{'ScreenRecord'} = $SrName;
					} else {
						if ( $Mode !~ /translate/ && $Table !~ /formonly/i) { 
							printf STDERR "the generator cannot understand which table the field %s belongs to, check form file for node %s/%s\n",
							$FieldList[$flx],$nodeName,$node->getAttribute("identifier");
							printf STDERR "Count on unpredictable results!!!\n";
						}
					}
					my $Key=sprintf "%s:%s:%s",$FormName,$FieldList[$flx],$Table{$FieldList[$flx]};
					my $Container=$Container{$Key};
					$ScreenRecord->{$FormName}->{$SrName}->{'CntrnList'}[$flx] = $Container ;
					$Key=sprintf "%s:%s:%s",$FieldList[$flx],$Table{$FieldList[$flx]},$Container;
					$Fields->{$FormName}->{$Key}->{ScreenRecord}=$SrName;
				}

				$flx++;
			}
			$SRTableList =~ s/^,// ;
			# remove duplicates
			#@SRTabList = uniq(split (/,/,$SRTableList));
			@SRTabList = split (/,/,$SRTableList);
			
			$ScreenRecord->{$FormName}->{$SrName}->{'TableList'} = [ @SRTabList ] ;
			#$ScreenRecord->{$FormName}->{$SrName}->{'Order'} = ++$ScreenRecOrder ;
			
		}
	} elsif ( $nodeName eq "Table" ) {
		@TableFields = [] ;
	}
    
    # No need to check hasChildNodes. If there aren't any
    # children, childNodes will return an empty array.
    for my $child ($node->childNodes) {
        # Call process_form_node recursively.
        process_form_node($child);
    }
    $level--;
}

sub get_coldef {
    my ($column,$FormDataType) =  ( @_ ) ;
    ### to be completed
    my @DataPrecision=();
    my $dataType="";
    my $Precision='';
    if ( $FormDataType =~ /(\w+)(.*)/) {
        #$Fields->{$FormName}->{$Key}->{DataType} = $1;
        $dataType=$1;
        @DataPrecision=split (/,/,$2);
        $a=1;
    } else {
		$dataType=$FormDataType;
	}
	#$ColDef=$DataEquiv{uc($dataType)}->{ColDef};			
	$ColDef=$dataType;
							
    if ( $ColDef =~ /^CHAR/i) {
        $ColDef = sprintf "%s(%d)",$ColDef,$DataPrecision[4];
    } elsif ( $ColDef =~ /^VARCHAR/i) {
        $ColDef = sprintf "%s(%d,%d)",$ColDef,$DataPrecision[4],$DataPrecion[3];
    } elsif ( $ColDef =~ /^MONEY/i) {
        if ( !defined($DataPrecision[4]) || $DataPrecision[4] eq '') {
            #$DataPrecision[4] = 2;
        }
        if ( !defined($DataPrecision[3]) || $DataPrecision[3] eq '') {
            #$DataPrecision[3] = 16;
        }
        $ColDef = sprintf "%s(%d,%d)",$ColDef,$DataPrecision[3],$DataPrecision[4];
    } elsif ( $ColDef =~ /^DATETIME/i) {
        if ( $DataPrecision[1] eq '') {
            $DataPrecision[1] = "YEAR";
        }
        if ( $DataPrecision[2] eq '') {
            $DataPrecision[2] = "DAY";
        }
        $ColDef = sprintf "%s %s TO %s",$ColDef,uc($DataPrecision[1]),uc($DataPrecision[2]);
    }

    if ( !defined($ColDef) ) {
        printf STDOUT "Error: field %s has no data type,\n",$column;
        if ( $Key =~ /formonly/i ) { 
            printf STDOUT "please set data type to relevant value in Form Designer for this field\n" ;
        } else {
            printf STDOUT "please manually set the property 'fieldColumn' with the column name this field is related to in the Form Designer\n" ;
        }
    }
    return $ColDef;
}

# not operational yet!
sub get_tables_list_from_form {
	my ($FormFileName ) =  (@_ ) ;
    my $dom = XML::LibXML->load_xml(location => $FormFileName);
	
	process_form_node_tblonly ($dom->documentElement);
	
	$a=1;
} # end sub get_tables_list_from_form

# not operational yet!
sub process_form_node_tblonly {
	my $node = shift;
	my $tabs = '  ' x $level++ ;
	our $SupportedWidgets="TextField\$\|Calendar\$\|TimeEditField\$\|Slider\$\|Spinner\|CheckBoxList\$\|CheckBox\$\|ComboBox\$\|ListBox\$\|RadioButtonList\$";
	my $nodeName=$node->nodeName;
	if ($nodeName =~ /$SupportedWidgets/ || $nodeName eq "TableColumn" ) {
	# handling supported widgets  and TableColumns 
		if (defined($node->getAttribute("fieldTable"))) {
			$TableName = $node->getAttribute("fieldTable");
		}

	}

	for my $child ($node->childNodes) {
	# Call process_form_node recursively.
		process_form_node_tblonly($child);
	}
} #end process_form_node_tblonly
