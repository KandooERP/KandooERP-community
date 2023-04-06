# UT7_gen_trslt_files : this program will 
# 1) update the global list of programs containing modules, forms and libraries
# 2) Generate .4s translation files for the selected programs of this list 
GLOBALS "../common/glob_GLOBALS.4gl"
    DEFINE type_frm_rec_U807_strings_translation TYPE AS RECORD # This is the TYPE for form image record		
		string_id LIKE application_strings.string_id, #  integer	
        program_name LIKE fgltarget.program_name,	
		container LIKE application_strings.container, #  varchar(24)		
		string_type LIKE application_strings.string_type, #  char(10)		
		string_contents LIKE application_strings.string_contents, #  lvarchar(256)		
		xnumber INTEGER , # ,		
		trsltd_messages INTEGER, # ,		
		tobe_trsltd_messages INTEGER # 				
	END RECORD		
		
	DEFINE type_tbl_rec_application_strings TYPE AS RECORD # This is the TYPE for table image record		
		string_id LIKE application_strings.string_id, # integer		
		container LIKE application_strings.container, # varchar(24)		
		string_type LIKE application_strings.string_type, # char(10)		
		string_contents LIKE application_strings.string_contents # lvarchar(256)				
	END RECORD		
		
	DEFINE type_prykey_application_strings TYPE AS RECORD 		
		string_id LIKE application_strings.string_id # integer				
	END RECORD		
    DEFINE nbElt,nbAttr,nbComment,nbPI,nbTxt,nbCData INTEGER

    DEFINE type_ArrElem_U807_strings_translation TYPE AS RECORD # Define Screen Record Array Type
        language_code LIKE strings_translation.language_code, #  char(3)
        country_code LIKE strings_translation.country_code, # char(3)
        translation LIKE strings_translation.translation, #  lvarchar(256)
        last_modification_ts LIKE strings_translation.last_modification_ts,  # DATETIME YEAR TO SECOND, # ,
        text_length INTEGER , # ,
        identical_count INTEGER # 
	END RECORD

	DEFINE modu_localized_dir STRING  # directory where the 4s files must be written
	DEFINE modu_fgltarget_directory STRING # directory where the .fgltarget files are located

    DEFINE crs_strings_program CURSOR
    DEFINE crs_list_program_name CURSOR
	DEFINE prp_delete_fgltarget PREPARED
	DEFINE prp_insert_fgltarget PREPARED

    MAIN		
        DEFER INTERRUPT		
        WHENEVER SQLERROR CALL error_mngmt		
        CALL setModuleId("UT7")			# put program name here (1 letter 2 or 3 digits)		
        CALL ui_init(0)		#Initial UI Init		
		CALL authenticate(getModuleId()) #authenticate		

        DEFER QUIT		
        DEFER INTERRUPT		
        LET modu_fgltarget_directory = "H:/Eclipse/git/KandooERP/KandooERP/source/"
		LET modu_localized_dir = modu_fgltarget_directory,"/locale_catalog/"
        CALL main_UT7_gen_trslt_files()		
            
    END MAIN		
		
##########################################################################		
FUNCTION main_UT7_gen_trslt_files ()		
## this module's main function called by MAIN		
		
	
	--CALL init_U_UT()      #init utility module # put Business module letter + 2 letters		
		
	OPEN WINDOW U807_strings_translation WITH FORM "U807_strings_translation"	
   	CALL windecoration_u("U807_strings_translation")
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
	

	--CALL combolist_language ("language_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
	CALL menu_UT7_gen_trslt_files()      		

	CLOSE WINDOW U807_strings_translation		

END FUNCTION # main_UT7_gen_trslt_files		

FUNCTION menu_UT7_gen_trslt_files ()		
## menu_UT6_strings_translate_application_strings		
## the top level menu 		
## input arguments: none		
## output arguments: none		
 
	DEFINE nbsel_application_strings INTEGER
    DEFINE l_where_clause STRING		
	DEFINE sql_stmt_status INTEGER		
	DEFINE record_num INTEGER		
	DEFINE action smallint		
	DEFINE xnumber smallint		
	DEFINE arr_elem_num smallint		
	DEFINE l_prykey_application_strings type_prykey_application_strings # Primary key record		
	DEFINE l_frm_rec_U807_strings_translation type_frm_rec_U807_strings_translation # Form image record		
	DEFINE l_tbl_rec_application_strings type_tbl_rec_application_strings # Table image record		
		
	DEFINE where_clause STRING		
	DEFINE record_found INTEGER		
	DEFINE lookup_status INTEGER		
		
	LET nbsel_application_strings = 0

	MENU "generate_trslt_files"		
        BEFORE MENU		
            --HIDE OPTION "Next","Previous","Edit","Delete","View Translations","Translate Strings","SHOW FORM"		
                
        COMMAND "Update Programs List" "Update programs lists from deve environment"		
            CALL parse_fgltarget_files(modu_fgltarget_directory)

        COMMAND "Generate Translation File"
            CALL generate_4s_files()
            
        COMMAND "EXIT"
            EXIT MENU
    END MENU

END FUNCTION # menu_UT7_gen_trslt_files ()		

FUNCTION parse_fgltarget_files(p_directory)
# This function parses the list of the .fgltarget files and call the function that delivers contents in terms of forms, modules and libraries for each program
# data is inserted into the fgltarget table
    DEFINE p_directory STRING
    DEFINE l_fgltarget_name STRING
	DEFINE l_program_name STRING
	DEFINE l_sql_statement STRING
	DEFINE entry STRING
	DEFINE dir_handle INTEGER
	DEFINE programs_number,total_prog_number INTEGER
	DEFINE l_match util.match_results 
	LET	l_sql_statement = "DELETE FROM fgltarget WHERE program_name = ?"
	CALL prp_delete_fgltarget.Prepare(l_sql_statement)
	LET	l_sql_statement = "INSERT INTO fgltarget (program_name,container) VALUES (?,?) "
	CALL prp_insert_fgltarget.Prepare(l_sql_statement)
	
	# First count the programs
	CALL os.path.diropen(p_directory) RETURNING dir_handle 
	LET total_prog_number = 0	
	LET entry ="#!%$" 
	WHILE entry IS NOT NULL 
		CALL os.path.dirnext(dir_handle) RETURNING entry
		IF util.regex.search(entry,/(\..*\.fgltarget)/) THEN
			IF util.regex.search(entry,/\w000_All_/) THEN
				CONTINUE WHILE		# exclude pseudo programs having all forms
			END IF	
			LET total_prog_number = total_prog_number + 1
		END IF
	END WHILE
	CALL os.path.dirclose(dir_handle)
	# then scan the directory for process
	CALL os.path.diropen(p_directory) RETURNING dir_handle 
	CALL os.Path.dirsort("name",1) 
	LET entry ="#!%$" 
	# scan the directory containing the fgltarget files
	LET programs_number = 0
	WHILE entry IS NOT NULL 
		# read the directory with  sort on file names (i.e. on patch date descending )
		CALL os.path.dirnext(dir_handle) RETURNING entry
		IF util.regex.search(entry,/(\..*\.fgltarget)/) THEN
			IF util.regex.search(entry,/\w000_All_/) THEN
				CONTINUE WHILE		# exclude pseudo programs having all forms
			END IF
			LET l_fgltarget_name = p_directory,"/",entry
			CALL parse_one_fgltarget(l_fgltarget_name)
			LET programs_number = programs_number + 1
			LET l_match = util.regex.search(entry,/\.(.*)\.fgltarget/) 
			LET l_program_name = l_match.str(1)
			DISPLAY programs_number USING "&&&&&","/",total_prog_number USING "&&&&&"," Components list for program ",l_program_name," updated successfully"
		END IF 	
	END WHILE	
	DISPLAY "Update of programs list completed successfully ",programs_number USING "&&&&&"," programs inserted"
END FUNCTION # parse_fgltarget_files

FUNCTION parse_one_fgltarget (p_file_name)
	# This function reads a flat file,with possibility or filtering line by regular expressions, and can return contents
	# either in a Dynamic array, or ONE variable(which is in fact a 1 element DYNAMIC array
	# Inbound parameters:
	# fullpath : full path of file name
	# grepexp : regular expression to filter line if any
	# return_form : "arr" to return a dynamic array, "var" to return a string variable (in fact return an array with 1 line or many lines)
	# Outbound:
	# Full Dynamic array or just one element of Dynamic array

	DEFINE p_file_name STRING
	DEFINE fullpath STRING 
	DEFINE grepexp STRING 
	DEFINE file_handle base.channel 
	DEFINE regexp util.regex 
	DEFINE l_match util.match_results 
	DEFINE regexps STRING 
	DEFINE dir_handle,line_number,fdx,ddx INTEGER 
	DEFINE arr_file_contents DYNAMIC ARRAY OF STRING 
	DEFINE str_file_contents STRING 
	DEFINE line_contents STRING
	DEFINE l_program_name LIKE fgltarget.program_name
	DEFINE l_form_name,l_module_name,l_library_name LIKE fgltarget.container
	DEFINE in_fgl,in_forms,in_libraries BOOLEAN
	DEFINE a INTEGER

	# open the file
	IF NOT os.path.exists(p_file_name) THEN 
		RETURN "File ",file_handle, " does not exist" 
	END IF 
	LET file_handle = base.channel.create() 

	CALL file_handle.openfile(p_file_name, "r") 
	IF regexps = "" OR regexps IS NULL THEN 
		# if no regular expression, initialize to .* (all)
		LET regexps = "/.*/" 
	ELSE 
		LET regexps = "/",regexps,"/" 
	END IF 
	LET regexp = regexps 

	# read the script file
	LET line_number = 1 
	LET in_fgl = false
	LET in_libraries = false
	LET in_forms = false
	# Delete all containers of this program / reset the program
	CALL prp_delete_fgltarget.Execute(l_program_name)
	WHILE NOT file_handle.iseof() 
		LET line_contents = file_handle.readline() 
		CASE
			WHEN util.regex.search(line_contents,/file location=".*\/(\w+\.fm2)"/)  
				LET l_match = util.regex.search(line_contents,/file location=".*\/(\w+\.fm2)"/) 
				LET l_form_name=l_match.str(1)
				IF in_forms = TRUE AND l_form_name IS NOT NULL THEN
					CALL prp_insert_fgltarget.Execute(l_program_name,l_form_name) 
				END IF
			WHEN util.regex.search(line_contents,/file location=".*\/(\w+\.4gl)"/)
				LET l_match = util.regex.search(line_contents,/file location=".*\/(\w+\.4gl)"/)
				LET l_module_name=l_match.str(1)
				IF in_fgl = TRUE AND l_module_name IS NOT NULL THEN
					CALL prp_insert_fgltarget.Execute(l_program_name,l_module_name) 
				END IF
			WHEN util.regex.search(line_contents,/<library name="(\w+)"/)
				LET l_match = util.regex.search(line_contents,/<library name="(\w+)"/)
				LET l_library_name=l_match.str(1)
				IF in_libraries = TRUE AND l_library_name IS NOT NULL THEN
					CALL prp_insert_fgltarget.Execute(l_program_name,l_library_name) 
				END IF

			WHEN util.regex.search(line_contents,/<fglBuildTarget .*name="(.*)" type="fgl-program">/)
				LET l_match=util.regex.search(line_contents,/<fglBuildTarget .*name="(.*)" type="fgl-program">/)
				LET l_program_name=l_match.str(1)
			WHEN util.regex.search(line_contents,/<sources type="fgl">/) 
				LET in_fgl = true
			WHEN util.regex.search(line_contents,/<sources type="form">/) 
				LET in_forms = true
			WHEN util.regex.search(line_contents,/<libraries>\//) 					
				LET in_libraries = true
			WHEN util.regex.search(line_contents,/<\/sources>/) 
				LET in_fgl = false		
				LET in_forms = false		
			WHEN util.regex.search(line_contents,/<\/libraries>/) 
				LET in_libraries	 = false						
			OTHERWISE
				CONTINUE WHILE 
		END CASE
	END WHILE			
END FUNCTION					

FUNCTION generate_4s_files()
# this function select the list of 4s files to be generated (based on programs)
# it prepares the selection criteria and opens the cursor
    DEFINE l_rec_form RECORD
        program_name LIKE fgltarget.program_name,
        language_code LIKE strings_translation.language_code,
        country_code LIKE strings_translation.country_code
    END RECORD
    DEFINE l_sql_statement,l_sql_statement_base,l_sql_statement_for_country STRING
    DEFINE l_where_clause STRING
    DEFINE l_status INTEGER
    DEFINE l_idx INTEGER
	DEFINE l_status_msg,msg_string STRING
    DEFINE l_arr_program_name DYNAMIC			 ARRAY OF RECORD 
        program_name LIKE fgltarget.program_name,
        language_code LIKE strings_translation.language_code,
        country_code LIKE strings_translation.country_code
    END RECORD
	DEFINE a INTEGER

	CALL frm_construct_dataset_parent_UT6_strings_translate() RETURNING l_where_clause
    CALL sql_opn_crs_list_program_name (l_where_clause) RETURNING l_status
    CALL crs_list_program_name.FetchAll(l_arr_program_name)

	LET l_sql_statement_base = "SELECT distinct application_strings.string_contents,strings_translation.translation ",
	" FROM fgltarget,application_strings,strings_translation ",
	" WHERE fgltarget.container = application_strings.container ",
	" AND application_strings.string_id = strings_translation.string_id ",
	" AND fgltarget.program_name = ? ",
	" AND strings_translation.language_code = ? ",
	" AND strings_translation.country_code = ? ",
	" AND strings_translation.translation IS NOT NULL "

	LET l_sql_statement_for_country = " AND strings_translation.string_id NOT IN (SELECT string_id FROM strings_translation WHERE language_code = ? AND country_code = ? )",
	"UNION ",
	l_sql_statement_base
	
    FOR l_idx = 1 TO l_arr_program_name.GetSize()
		IF l_arr_program_name[l_idx].country_code = "ALL" THEN
			LET l_sql_statement = l_sql_statement_base," ORDER BY 1"
			CALL crs_strings_program.Declare (l_sql_statement)
		ELSE
			LET l_sql_statement = l_sql_statement_base,l_sql_statement_for_country,"ORDER BY 1 "
			CALL crs_strings_program.Declare (l_sql_statement)
		END IF
        CALL generate_4s_file(l_arr_program_name[l_idx].program_name,l_arr_program_name[l_idx].language_code,l_arr_program_name[l_idx].country_code)
		CALL crs_strings_program.Close()
		CALL crs_strings_program.Free()
    END FOR
	LET msg_string = "Message files generated successfully for language ",l_arr_program_name[1].language_code
	CALL fgl_winmessage(msg_string,l_idx,"INFO") 

	ERROR l_status_msg
END FUNCTION

FUNCTION generate_4s_file(p_program,p_language,p_country)
# this function generates a .4s file for a given program/language/country
    DEFINE p_program LIKE fgltarget.program_name
    DEFINE p_language LIKE strings_translation.language_code
    DEFINE p_country LIKE strings_translation.country_code
    DEFINE l_sql_statement,ww,print_string,trslate_file STRING
	DEFINE l_contents LIKE application_strings.string_contents
	DEFINE l_translation LIKE strings_translation.translation
	DEFINE trlst_handle base.channel

	LET trlst_handle = base.Channel.Create()
	IF p_country = "ALL" THEN
		LET trslate_file = modu_localized_dir,p_program clipped,"_",p_language clipped,".4s"
			CALL crs_strings_program.Open(p_program,p_language,p_country)
	ELSE
		LET trslate_file = modu_localized_dir,p_program clipped,"_",p_language clipped,"_",p_country CLIPPED,".4s"
		CALL crs_strings_program.Open(p_program,p_language,"ALL",p_program,p_language,p_program,p_language,p_country)
	END IF
	CALL trlst_handle.openfile(trslate_file, "w") 
	CALL trlst_handle.setDelimiter("")
	LET print_string = p_program clipped,"_",p_language CLIPPED," {"
	CALL trlst_handle.writeLine(print_string)

    WHILE crs_strings_program.FetchNext(l_contents,l_translation) = 0
        LET print_string = l_contents,' { "',l_translation,'" }'
		CALL trlst_handle.writeLine(print_string)
		
    END WHILE
	LET print_string = "}"
	CALL trlst_handle.write(print_string)
    CALL trlst_handle.close()
	DISPLAY "Translation file ",trslate_file, " Generated successfully"
END FUNCTION

FUNCTION sql_opn_crs_list_program_name(p_where_clause)		
## Build the query generated by CONSTRUCT BY NAME,		
## Declare and open the cursor		
## inbound param: query predicate		
## outbound parameter: query status		
	DEFINE p_where_clause STRING		
	DEFINE qbe_statement,qbe_predicate,qbe_select,tables_list STRING		
	DEFINE rows_count,l_idx integer		
	DEFINE l_sql_stmt_status integer
	DEFINE l_arr_tables_list DYNAMIC ARRAY OF STRING
	DEFINE l_arr_joins_list DYNAMIC ARRAY OF STRING

	# define primary_key record		
	DEFINE l_prykey type_prykey_application_strings #Primary key record 		
		
	--CALL l_arr_tables_list.append("application_strings")
    CALL l_arr_tables_list.append("fgltarget")

    IF util.REGEX.search(p_where_clause,/\bapplication_strings\./)  THEN # application_strings + application_strings
		CALL l_arr_tables_list.append("application_strings") 
		CALL l_arr_joins_list.append("fgltarget.container = application_strings.container")
	END IF

    IF util.REGEX.search(p_where_clause,/\bstrings_translation\./)  THEN  
		# application_strings is mandatory if filter on strings_translation
		IF l_arr_tables_list.GetSize() = 1 THEN
			CALL l_arr_tables_list.append("application_strings") 
			CALL l_arr_joins_list.append("fgltarget.container = application_strings.container")
		END IF

		CALL l_arr_tables_list.append("strings_translation")
		CALL l_arr_joins_list.append("application_strings.string_id = strings_translation.string_id")
	END IF

    # build the tables list
	FOR l_idx = 1 TO l_arr_tables_list.GetSize()
		LET qbe_predicate = qbe_predicate,l_arr_tables_list[l_idx],","
	END FOR
	CALL util.REGEX.replace(qbe_predicate,/,$/," ") returning qbe_predicate
	LET qbe_predicate = qbe_predicate," WHERE "
	
	# build the joins list
	FOR l_idx = 1 TO l_arr_joins_list.GetSize()
		LET qbe_predicate = qbe_predicate,l_arr_joins_list[l_idx]," AND "
	END FOR
	CALL util.REGEX.replace(qbe_predicate,/ AND $/," ") returning qbe_predicate

	# build complete statement
    LET qbe_statement = "SELECT DISTINCT fgltarget.program_name,strings_translation.language_code,strings_translation.country_code FROM ",qbe_predicate
	IF l_arr_joins_list.GetSize() > 0 THEN
		LET qbe_statement = qbe_statement," AND "
	END IF
	LET qbe_statement = qbe_statement, p_where_clause
			
	CALL crs_list_program_name.Declare(qbe_statement)		
	CALL crs_list_program_name.Open()		
	RETURN sqlca.sqlcode		
END FUNCTION ## sql_opn_list_program_name	