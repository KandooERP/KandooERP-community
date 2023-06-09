		
# module generated by KandooERP Ffg(c)		
# Generated on 2021-03-01 08:41:35		
# Main template H:\Eclipse\git\KandooERP\KandooERP\Resources\Utilities\Perl\Ffg/templates/module/Kandoo-parent-scroll-menu.mtplt 		
		
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS
	DEFINE glob_rec_formonly RECORD
		translate_similar_strings BOOLEAN
	END RECORD
	DEFINE glob_enu_msg LIKE application_strings.string_contents
	DEFINE type_frm_rec_U807_strings_translation TYPE AS RECORD # This is the TYPE for form image record		
		string_id LIKE application_strings.string_id, #  integer	
		program_name LIKE fgltarget.program_name, # varchar(28)	
		container LIKE application_strings.container, #  varchar(24)		
		string_type LIKE application_strings.string_type, #  char(10)		
		string_contents LIKE application_strings.string_contents, #  lvarchar(256)		
		xnumber INTEGER , # ,		
		trsltd_messages INTEGER, # ,		
		tobe_trsltd_messages INTEGER # 	
	END RECORD		
	DEFINE glob_fgltarget_clause STRING			# trick to keep the clause on fgltarget if used			
END GLOBALS		
		
	DEFINE type_tbl_rec_application_strings TYPE AS RECORD # This is the TYPE for table image record		
		string_id LIKE application_strings.string_id, # integer		
		container LIKE application_strings.container, # varchar(24)		
		string_type LIKE application_strings.string_type, # char(10)		
		string_contents LIKE application_strings.string_contents # lvarchar(256)				
	END RECORD		
		
	DEFINE type_prykey_application_strings TYPE AS RECORD 		
		string_id LIKE application_strings.string_id # integer				
	END RECORD		
		
	DEFINE cb_language ui.Combobox			

	CONSTANT CLASSIC_MODE_EDIT = "EDIT"		
	CONSTANT CLASSIC_MODE_ADD = "ADD"		
	DEFINE mdl_program CHAR(30)			
		
	# Define cursors and prepared statements		
	DEFINE crs_row_application_strings CURSOR		
	DEFINE crs_pky_application_strings CURSOR		
	DEFINE crs_upd_application_strings CURSOR		
	DEFINE crs_cnt_application_strings CURSOR		
	DEFINE crs_scrl_pky_application_strings CURSOR		
	DEFINE pr_ins_application_strings PREPARED		
	DEFINE pr_upd_application_strings PREPARED		
	DEFINE pr_del_application_strings PREPARED		


		

		
##########################################################################		
FUNCTION main_UT6_strings_translate ()		
## this module's main function called by MAIN		
		
		
	--CALL init_U_UT()      #init utility module # put Business module letter + 2 letters		
		
	CALL sql_prepare_queries_parent_UT6_strings_translate () # initialize all cursors on parent table		
	CALL sql_prepare_queries_child_UT6_strings_translate()      # initialize allcursors on Child table

	OPEN WINDOW U807_strings_translation WITH FORM "U807_strings_translation"		
	CALL windecoration_u("U807_strings_translation")
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
 
	
	CALL menu_parent_UT6_strings_translate()      		

	CLOSE WINDOW U807_strings_translation		

END FUNCTION # main_UT6_strings_translate		
		
######################################################################		
FUNCTION menu_parent_UT6_strings_translate ()		
## menu_parent_UT6_strings_translate		
## the top level menu 		
## input arguments: none		
## output arguments: none		
	DEFINE nbsel_application_strings INTEGER		
	DEFINE sql_stmt_status INTEGER		
	DEFINE record_num INTEGER		
	DEFINE action smallint		
	DEFINE xnumber smallint		
	DEFINE arr_elem_num smallint		
	DEFINE l_prykey_application_strings type_prykey_application_strings # Primary key record		
	DEFINE l_frm_rec_U807_strings_translation type_frm_rec_U807_strings_translation # Form image record		
	DEFINE l_tbl_rec_application_strings type_tbl_rec_application_strings # Table image record	
	DEFINE l_match util.match_results 	

	DEFINE where_clause STRING		
	DEFINE record_found INTEGER		
	DEFINE lookup_status INTEGER		
		
	LET nbsel_application_strings = 0
	LET glob_rec_formonly.translate_similar_strings = TRUE
	DISPLAY BY NAME glob_rec_formonly.translate_similar_strings
	MENU "application_strings"		
	BEFORE MENU		
		HIDE OPTION "Next","Previous","Edit","Delete","View Translations","Translate Strings","SHOW FORM","Replay Child"		
			
	COMMAND "Query Parent" "Query data with multiple criteria application_strings"		
		MESSAGE ""		
		INITIALIZE l_frm_rec_U807_strings_translation.* TO NULL	
		CLEAR application_strings.*	
		DISPLAY BY NAME l_frm_rec_U807_strings_translation.*		
		HIDE OPTION "Next","Previous"		
		
		# Build the QBE where clause		
		CALL frm_construct_dataset_parent_UT6_strings_translate() RETURNING where_clause

		# very special trick to catch the clause on program_name, because a string can belong to many containers that belong to many programs
		LET l_match = util.regex.search(where_clause,/(fgltarget\.program_name \w+ '[\w%]+')/) # 
		LET glob_fgltarget_clause = l_match.str(1)
		IF glob_fgltarget_clause IS NULL THEN
			LET glob_fgltarget_clause = "fgltarget.program_name LIKE '%'"
		END IF

		# Call the function that counts matching rows and opens the scroll cursor on primary key		
		CALL sql_declare_pky_scr_curs_parent_UT6_strings_translate(where_clause)		
		RETURNING nbsel_application_strings,sql_stmt_status	
		WHENEVER SQLERROR CONTINUE		
		CALL crs_scrl_pky_application_strings.Open()		
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler		
				
		
		IF nbsel_application_strings > 0 THEN 		
			CALL sql_nxtprev_parent_UT6_strings_translate(1) RETURNING record_found,		
			l_prykey_application_strings.*		
		
			CASE		
				WHEN record_found = 1		
					LET record_num = 1		
					CALL sql_fetch_full_row_parent_UT6_strings_translate (l_prykey_application_strings.*)		
					RETURNING record_found,l_frm_rec_U807_strings_translation.*		
					CALL frm_display_parent_UT6_strings_translate(l_frm_rec_U807_strings_translation.*)		
					CALL frm_display_array_child_UT6_strings_translate (l_prykey_application_strings,TRUE) RETURNING arr_elem_num 
					IF arr_elem_num > 0 THEN
						SHOW OPTION "View Translations","Translate Strings","SHOW FORM"
					ELSE
						HIDE OPTION "View Translations","Translate Strings"
					END IF
							
				WHEN record_found = -1 		
					ERROR "This row is unreachable ",sqlca.sqlcode		
			END CASE		
			IF nbsel_application_strings > 1 THEN		
			   SHOW OPTION "Next"		
			   NEXT OPTION "Next"		
			END IF		
			SHOW OPTION "Edit","Delete"		
		ELSE 		
			ERROR "No row matches the criteria"		
			NEXT OPTION "Query"		
		END IF		
		
	COMMAND "Next" "Display Next record application_strings"		
		MESSAGE ""		
		CLEAR application_strings.*	
		INITIALIZE l_frm_rec_U807_strings_translation.* TO NULL		
		
		IF record_num <= nbsel_application_strings THEN		
			CALL sql_nxtprev_parent_UT6_strings_translate(1) RETURNING record_found,		
			l_prykey_application_strings.*		
		
			CASE 		
			WHEN record_found = 0 		
				ERROR "fetch Last record of this selection application_strings"		
			WHEN record_found = -1 		
				ERROR "This row is unreachable ",sqlca.sqlcode		
			WHEN record_found = 1		
				LET record_num = record_num + 1		
				CALL sql_fetch_full_row_parent_UT6_strings_translate (l_prykey_application_strings.*)		
				RETURNING record_found,l_frm_rec_U807_strings_translation.*		
				CALL frm_display_parent_UT6_strings_translate(l_frm_rec_U807_strings_translation.*)		
				CALL frm_display_array_child_UT6_strings_translate (l_prykey_application_strings,TRUE) RETURNING arr_elem_num 
				IF arr_elem_num > 0 THEN
					SHOW OPTION "View Translations","Translate Strings"
				ELSE
					HIDE OPTION "View Translations","Translate Strings"
				END IF

				IF record_num >= nbsel_application_strings THEN		
				   HIDE OPTION "Next"		
				END IF		
                IF record_num > 1 THEN		
                	SHOW OPTION "Previous"		
                ELSE		
                	HIDE OPTION "Previous"		
				END IF		
			END CASE		
		ELSE		
			ERROR " Please set query criteria previously application_strings "		
			NEXT OPTION "Query" 		
		END IF		
		
	COMMAND "Previous" "Display Previous Record application_strings"		
		MESSAGE ""		
		INITIALIZE l_frm_rec_U807_strings_translation.* TO NULL		
		CLEAR application_strings.*			
		IF record_num >= 1 THEN		
			CALL sql_nxtprev_parent_UT6_strings_translate(-1) RETURNING record_found,		
			l_prykey_application_strings.*		
			CASE 		
			WHEN record_found = 0		
				ERROR "fetch First record of this selection application_strings"		
			WHEN record_found < -1		
				ERROR "This row is unreachable ",sqlca.sqlcode		
			WHEN record_found = 1		
				LET record_num = record_num - 1		
				CALL sql_fetch_full_row_parent_UT6_strings_translate (l_prykey_application_strings.*)		
				RETURNING record_found,l_frm_rec_U807_strings_translation.*		
		
				CALL frm_display_parent_UT6_strings_translate(l_frm_rec_U807_strings_translation.*)		
				CALL frm_display_array_child_UT6_strings_translate (l_prykey_application_strings,TRUE) RETURNING arr_elem_num 
				IF arr_elem_num > 0 THEN
					SHOW OPTION "View Translations","Translate Strings"
				ELSE
					HIDE OPTION "View Translations","Translate Strings"
				END IF
						
		
				IF record_num = 1 THEN		
				   HIDE OPTION "Previous"		
				END IF		
                IF record_num < nbsel_application_strings THEN		
                	SHOW OPTION "Next"		
                ELSE		
                	HIDE OPTION "Next"		
				END IF		
			END CASE		
		ELSE		
			ERROR " Please set query criteria previously application_strings "		
			NEXT OPTION "Query"		
		END IF		
		
	COMMAND "Add" "Add a new record application_strings"		
		MESSAGE ""	
		CLEAR application_strings.*		
		CALL frm_input_parent_UT6_strings_translate(MODE_CLASSIC_ADD,l_prykey_application_strings.*,l_frm_rec_U807_strings_translation.*) 		
		RETURNING sql_stmt_status,l_prykey_application_strings.*		
		MESSAGE ""		
		SHOW OPTION "Translate Strings"
				
		
	COMMAND "Edit" "Modify current record application_strings"		
		MESSAGE ""		
		IF nbsel_application_strings THEN		
			IF sql_pky_exists_parent_UT6_strings_translate(l_prykey_application_strings.*) < 0 THEN		
				ERROR "is locked "		
				NEXT OPTION "Next"		
			ELSE		
				CALL frm_input_parent_UT6_strings_translate(MODE_CLASSIC_EDIT,l_prykey_application_strings.*,l_frm_rec_U807_strings_translation.*) 		
				RETURNING sql_stmt_status,l_prykey_application_strings.*		
			END IF		
		ELSE		
			ERROR " Please set query criteria previously application_strings "		
			NEXT OPTION "Query"		
		END IF		
		
   COMMAND "Delete" "Suppress current record application_strings"		
				
		MESSAGE ""		
		IF nbsel_application_strings THEN		
			IF sql_pky_exists_parent_UT6_strings_translate(l_prykey_application_strings.*) < 0 THEN		
				ERROR "is locked "		
				NEXT OPTION "Next"		
			END IF		
			WHILE TRUE		
				CALL confirm_operation(5,10,"Delete") RETURNING action		
				CASE 		
				WHEN action = 0 OR action = 1 		
					EXIT WHILE # degage abandon		
				WHEN action = 2 		
					CALL frm_suppress_parent_UT6_strings_translate(l_prykey_application_strings.*)		
					RETURNING sql_stmt_status		
					EXIT WHILE		
				END CASE		
			END WHILE		
		ELSE		
			ERROR "Please set query criteria previously application_strings "		
			NEXT OPTION "Query"		
		END IF		

	ON ACTION ("SHOW FORM")
		CALL show_form(l_frm_rec_U807_strings_translation.container)
		
	COMMAND "Generate New Language Set"
		CALL generate_new_language_set()

	COMMAND "View Translations" "View translation strings for this string"
		CALL frm_display_array_child_UT6_strings_translate (l_prykey_application_strings.*,False)
	
	COMMAND  "Translate Strings" "Translate strings for this string"
		CALL edit_array_srec_translation (l_prykey_application_strings.*,NULL)
			
	COMMAND "Query Child" "Query child data with multiple criteria application_strings"		
		CALL query_child_data()		
		SHOW OPTION "Replay Child"

	COMMAND "Replay Child" "Replay Child query with identical criteria"
		CALL replay_child_query()
		
	COMMAND "EXIT" "Exit program"		
		MESSAGE ""		
		EXIT MENU		
	END MENU		
END FUNCTION # menu_parent_UT6_strings_translate ()		
		
#######################################################################		
FUNCTION frm_construct_dataset_parent_UT6_strings_translate()		
## frm_construct_dataset_parent_UT6_strings_translate_U807_strings_translation : Query By Example on table application_strings		
## Input selection criteria,		
## prepare the query,		
## open the data set		
	DEFINE qbe_statement,where_clause STRING		
	DEFINE xnumber,sql_stmt_status INTEGER		
	DEFINE l_prykey type_prykey_application_strings 		
		
	DEFINE l_frm_rec_U807_strings_translation type_frm_rec_U807_strings_translation # Form image record		
		
	DEFINE reply CHAR(5)		
	LET xnumber = 0		
	MESSAGE "Please input query criteria"		
	# initialize record and display blank		

	INITIALIZE l_frm_rec_U807_strings_translation.* TO NULL				
	CLEAR application_strings.*	
	CLEAR srec_translation.*
		
	CONSTRUCT BY NAME where_clause ON application_strings.string_id,
		fgltarget.program_name,		
		application_strings.container,		
		application_strings.string_type,		
		application_strings.string_contents,
		strings_translation.language_code,
		strings_translation.country_code,
		strings_translation.translation,
		strings_translation.last_modification_ts

	## Check whether criteria have been entered		
	AFTER CONSTRUCT 		
		IF NOT field_touched(application_strings.string_id,
		fgltarget.program_name,		
		application_strings.container,		
		application_strings.string_type,		
		application_strings.string_contents,
		strings_translation.language_code,
		strings_translation.country_code,
		strings_translation.translation,
		strings_translation.last_modification_ts )
		AND NOT int_flag THEN		
			LET reply = fgl_winbutton("","Select all rows, are you sure?","Yes","Yes|No","question",0)		
			CASE 		
			WHEN reply MATCHES "Yes"		
				EXIT CONSTRUCT 		
			OTHERWISE # Saisie d'un critere de selection		
				ERROR "Please input a least one criteria"		
				CONTINUE CONSTRUCT		
			END CASE		
		END IF		
	END CONSTRUCT		
		
	IF int_flag = TRUE THEN		
		LET where_clause = NULL		
		MESSAGE "Quit with quit key"		
		LET int_flag=0		
	END IF		
	RETURN where_clause		
END FUNCTION ## frm_construct_dataset_parent_UT6_strings_translate		
		
#######################################################################		
# frm_display_parent_UT6_strings_translate_U807_strings_translation : displays the form record after reading and displays lookup records if any		
# inbound: Form record.*		
FUNCTION frm_display_parent_UT6_strings_translate(p_frm_rec_U807_strings_translation)		
	DEFINE p_frm_rec_U807_strings_translation type_frm_rec_U807_strings_translation 		
		
	DISPLAY BY NAME p_frm_rec_U807_strings_translation.program_name,
	p_frm_rec_U807_strings_translation.string_id,		
	p_frm_rec_U807_strings_translation.container,		
	p_frm_rec_U807_strings_translation.string_type,		
	p_frm_rec_U807_strings_translation.string_contents	
	
	SELECT count(*) INTO p_frm_rec_U807_strings_translation.xnumber
	FROM application_strings
	WHERE string_contents = p_frm_rec_U807_strings_translation.string_contents
	DISPLAY BY NAME p_frm_rec_U807_strings_translation.xnumber  

END FUNCTION # frm_display_parent_UT6_strings_translate_U807_strings_translation		
		
#######################################################################		
# frm_input_parent_UT6_strings_translate_U807_strings_translation : Edit a application_strings RECORD		
# inbound: p_mode : determines whether Add or Edit record (ADD/EDIT)		
#          p_pky: table primary key		
#          p_frm_rec_U807_strings_translation : contents of the form record		
FUNCTION frm_input_parent_UT6_strings_translate(p_mode,p_pky,p_frm_rec_U807_strings_translation)		
	DEFINE action SMALLINT 		
	DEFINE sql_stmt_status,dummy SMALLINT		
	DEFINE p_mode NCHAR(5)		
	DEFINE p_pky type_prykey_application_strings #Primary key record 		
	DEFINE p_frm_rec_U807_strings_translation type_frm_rec_U807_strings_translation # Form image record		
	DEFINE sav_rec_U807_strings_translation type_frm_rec_U807_strings_translation # Form image record to save the data		
	DEFINE l_tbl_rec_application_strings type_tbl_rec_application_strings # Table image record		
			
	DEFINE rows_count SMALLINT		
		
	## check if record can be accessed		
	WHILE true		
		LET int_flag = false		
		IF p_mode = MODE_CLASSIC_EDIT THEN		
			# Save Screen Record values before altering		
			LET sav_rec_U807_strings_translation.* = p_frm_rec_U807_strings_translation.* 		
			BEGIN WORK		
			EXECUTE IMMEDIATE "SET ISOLATION TO COMMITTED READ RETAIN UPDATE LOCKS"		
			WHENEVER SQLERROR CONTINUE		
			CALL crs_upd_application_strings.Open(p_pky.*)		
			CALL crs_upd_application_strings.FetchNext(dummy)		
			IF sqlca.sqlcode = -244 THEN		
				ERROR "THIS ROW IS BEING MODIFIED"		
				ROLLBACK WORK		
				EXIT WHILE		
			END IF		
		END IF		


		DIALOG ATTRIBUTE(UNBUFFERED)

		INPUT BY NAME p_frm_rec_U807_strings_translation.string_id,		
		p_frm_rec_U807_strings_translation.container,		
		p_frm_rec_U807_strings_translation.string_type,		
		p_frm_rec_U807_strings_translation.string_contents						
		WITHOUT DEFAULTS		
			BEFORE INPUT		
				IF p_mode = MODE_CLASSIC_EDIT THEN # IF we edit the record, we do not modify the primary key fields		
					CALL DIALOG.SetFieldActive('string_id',FALSE)		
							
				ELSE		
					CALL DIALOG.SetFieldActive('string_id',TRUE)		
							
				END IF		
		END INPUT		

		INPUT BY NAME glob_rec_formonly.translate_similar_strings WITHOUT DEFAULTS
		END INPUT
		
			ON ACTION "EXIT"
				EXIT DIALOG
		END DIALOG

		IF int_flag = TRUE THEN		
			LET int_flag=false		
			# Restore previous value		
			LET p_frm_rec_U807_strings_translation.* = sav_rec_U807_strings_translation.*		
			DISPLAY p_frm_rec_U807_strings_translation.*  TO application_strings.*		
				
		
			EXECUTE IMMEDIATE "SET ISOLATION TO COMMITTED READ"		
			ROLLBACK WORK		
			MESSAGE "$CancelCom Control-C"		
			EXIT WHILE		
		END IF 		
		
		CALL confirm_operation(4,10,"Edit") RETURNING action		
		
		CASE 		
		WHEN action = 0		
			# Redo, leave values as modified		
			CONTINUE WHILE		
		WHEN action = 1 		
			# Resign, restore original values		
			LET p_frm_rec_U807_strings_translation.* = sav_rec_U807_strings_translation.*		
			DISPLAY p_frm_rec_U807_strings_translation.*  TO application_strings.*		
			EXECUTE IMMEDIATE "SET ISOLATION TO COMMITTED READ"		
			ROLLBACK WORK		
			EXIT WHILE # Cancel operation		
		
		WHEN action = 2 		
			# confirm update		
			CALL set_table_record_U807_strings_translation_application_strings("#",p_frm_rec_U807_strings_translation.*)		
			RETURNING l_tbl_rec_application_strings.*		
		
			# Perform the prepared update statement		
			LET sql_stmt_status = sql_update_parent_UT6_strings_translate(p_pky.*,l_tbl_rec_application_strings.*) 		
			CASE 		
			WHEN sql_stmt_status = 0		
				MESSAGE "Edit application_strings Successful operation"		
				EXECUTE IMMEDIATE "SET ISOLATION TO COMMITTED READ"		
				COMMIT WORK		
		
			WHEN sql_stmt_status < 0		
				ERROR "UPDATE application_strings:failed "
				EXECUTE IMMEDIATE "SET ISOLATION TO COMMITTED READ"		
				ROLLBACK WORK		
			END CASE		
			EXIT WHILE		
		END CASE		
	END WHILE		
	RETURN sql_stmt_status		
END FUNCTION ## frm_input_parent_UT6_strings_translate(p_pky)		
		
#######################################################################		
# DELETE A application_strings row		
# inbound: table primary key		
FUNCTION frm_suppress_parent_UT6_strings_translate(p_prykey)		
	DEFINE action SMALLINT		
	DEFINE dummy SMALLINT		
	DEFINE sql_stmt_status INTEGER		
	DEFINE nbr_deleted_rows INTEGER		
	DEFINE p_prykey type_prykey_application_strings #Primary key record 		
		
	WHILE TRUE		
		CALL confirm_operation(5,10,"Delete") RETURNING action		
		BEGIN WORK		
		EXECUTE IMMEDIATE "SET ISOLATION TO COMMITTED READ RETAIN UPDATE LOCKS"		
		WHENEVER SQLERROR CONTINUE		
		CALL crs_upd_application_strings.Open(p_prykey.*)		
		CALL crs_upd_application_strings.FetchNext(dummy)		
		IF sqlca.sqlcode = -244 THEN		
			ERROR "THIS ROW IS BEING DELETED"		
			ROLLBACK WORK		
			EXIT WHILE		
		END IF		
		
		CASE 		
		WHEN action = 0 OR action = 1 		
			# can the delete operation		
			EXIT WHILE 		
		WHEN action = 2		
			# Validate the delete operation		
			CALL sql_delete_parent_UT6_strings_translate(p_prykey.*) RETURNING sql_stmt_status,nbr_deleted_rows		
			CASE 		
				WHEN sql_stmt_status = 0		
					MESSAGE "Delete application_strings Successful operation "		
					COMMIT WORK		
				WHEN sql_stmt_status < 0		
					ERROR "Delete application_strings:failed "
					ROLLBACK WORK		
			END CASE		
			EXIT WHILE		
		END CASE		
	END WHILE		
	RETURN sql_stmt_status		
END FUNCTION ## frm_suppress_parent_UT6_strings_translate(p_prykey)		
		
#########################################################################		
#  Build, prepare, declare and initialize main queries and cursors		
FUNCTION sql_prepare_queries_parent_UT6_strings_translate ()		
	DEFINE sql_stmt_text STRING		
		
	# Declare cursor for full master table row contents, access by primary key		
	LET sql_stmt_text=		
	"SELECT 	string_id,container,string_type,string_contents	",		
	" FROM application_strings ",		
	"WHERE  string_id = ?	"		
	CALL crs_row_application_strings.Declare(sql_stmt_text)		
		
	# Declare cursor for row test / check if locked		
	let sql_stmt_text= "SELECT 	string_id	",		
	" FROM application_strings ",		
	" WHERE  string_id = ?	"		
	CALL crs_pky_application_strings.Declare(sql_stmt_text)		
		
	# Declare cursor for SELECT FOR UPDATE		
	let sql_stmt_text= "SELECT 	string_id	",		
	" FROM application_strings ",		
	" WHERE  string_id = ?	",		
	" FOR UPDATE"		
	CALL crs_upd_application_strings.Declare(sql_stmt_text,1,0)		
		
	# PREPARE INSERT statement		
	LET sql_stmt_text =		
	"INSERT INTO application_strings (	string_id,container,string_type,string_contents	)",		
	" VALUES ( 	?,?,?,?	)" 		
	CALL pr_ins_application_strings.Prepare(sql_stmt_text)		
		
	# PREPARE UPDATE statement		
	let sql_stmt_text=		
	"UPDATE application_strings ",		
	"SET ( 	container,string_type,string_contents	)",		
	" = ( 	?,?,?	)",		
	" WHERE  string_id = ?	" 		
	CALL pr_upd_application_strings.Prepare(sql_stmt_text)		
		
	# PREPARE DELETE statement		
	let sql_stmt_text= "DELETE FROM application_strings ",		
	" WHERE  string_id = ?	" 		
	CALL pr_del_application_strings.Prepare(sql_stmt_text)		
		
END FUNCTION ## sql_prepare_queries_parent_UT6_strings_translate		
		
#########################################################		
FUNCTION sql_declare_pky_scr_curs_parent_UT6_strings_translate(p_where_clause)		
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
		
	CALL l_arr_tables_list.append("application_strings")
	IF util.REGEX.search(p_where_clause,/\bstrings_translation\./)  THEN  
		CALL l_arr_tables_list.append("strings_translation")
		CALL l_arr_joins_list.append("application_strings.string_id = strings_translation.string_id")
	END IF

	IF util.REGEX.search(p_where_clause,/\bfgltarget\./)  THEN # application_strings + fgltarget
		CALL l_arr_tables_list.append("fgltarget") 
		CALL l_arr_joins_list.append("application_strings.container = fgltarget.container")
	END IF
	
	LET qbe_statement = "SELECT count(*) FROM "
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
	LET qbe_statement = "SELECT count(*) FROM ",qbe_predicate
	IF l_arr_joins_list.GetSize() > 0 THEN
		LET qbe_statement = qbe_statement," AND "
	END IF
	LET qbe_statement = qbe_statement, p_where_clause
			
	CALL crs_cnt_application_strings.Declare(qbe_statement)		
	CALL crs_cnt_application_strings.Open()		
	SET ISOLATION TO DIRTY READ		
	WHENEVER SQLERROR CONTINUE		
		
	CALL crs_cnt_application_strings.FetchNext(rows_count)		
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler		
	SET ISOLATION TO COMMITTED READ		
		
	# if FETCH fails, count = 0, the, get back to query		
	IF sqlca.sqlcode OR rows_count = 0 THEN		
		let rows_count =0		
	END IF		
	CALL crs_cnt_application_strings.Free()		
		
	# display the selected columns		
	LET qbe_statement = "SELECT distinct application_strings.string_id FROM ",qbe_predicate
	IF l_arr_joins_list.GetSize() > 0 THEN		# If there is one join or more, we need to plance "AND"
		LET qbe_statement = qbe_statement," AND "
	END IF
	LET qbe_statement = qbe_statement, p_where_clause," ORDER BY application_strings.string_id	"		
		
	# crs_scrl_pky_application_strings : the first cursor selects all the primary keys (not all the table columns)		
	CALL crs_scrl_pky_application_strings.Declare(qbe_statement,1,1)   # SCROLL CURSOR WITH HOLD		
		
		
	RETURN rows_count,sqlca.sqlcode		
END FUNCTION ## sql_declare_pky_scr_curs_parent_UT6_strings_translate		
		
#######################################################################		
FUNCTION sql_nxtprev_parent_UT6_strings_translate(offset)		
## sql_nxtprev_parent_UT6_strings_translate : FETCH NEXT OR PREVIOUS RECORD		
	DEFINE offset SMALLINT		
	define l_sql_stmt_status,record_found integer		
	DEFINE l_prykey type_prykey_application_strings #Primary key record 		
	DEFINE frm_rec_U807_strings_translation type_frm_rec_U807_strings_translation		
		
	WHENEVER SQLERROR CONTINUE		
	CALL crs_scrl_pky_application_strings.FetchRelative(offset,l_prykey.*)		
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler		
		
	CASE 		
		WHEN sqlca.sqlcode = 100 		
			LET record_found = 0		
		
		WHEN sqlca.sqlcode < 0 		
			LET record_found = -1		
		OTHERWISE		
			LET l_sql_stmt_status = 1		
			LET record_found = 1		
	END CASE		
	RETURN record_found,l_prykey.*		
END FUNCTION ## sql_nxtprev_parent_UT6_strings_translate		
		
#########################################################################################		
FUNCTION sql_fetch_full_row_parent_UT6_strings_translate(p_prykey_application_strings)		
# sql_fetch_full_row_parent_UT6_strings_translate : read a complete row accessing by primary key		
# inbound parameter : primary key		
# outbound parameter: sql_stmt_status and row contents		
	DEFINE sql_stmt_status smallint		
	DEFINE p_prykey_application_strings type_prykey_application_strings #Primary key record 		
	DEFINE l_tbl_rec_application_strings type_tbl_rec_application_strings # Table image record		
	DEFINE frm_rec_U807_strings_translation type_frm_rec_U807_strings_translation # Form image record	
	DEFINE l_sql_statement STRING
	DEFINE l_crs_fetch_program_name CURSOR	
	# read the table, access on primary key		
WHENEVER SQLERROR CONTINUE		
	CALL crs_row_application_strings.Open(p_prykey_application_strings.*)		
	CALL crs_row_application_strings.FetchNext(l_tbl_rec_application_strings.*)		
	LET glob_enu_msg = l_tbl_rec_application_strings.string_contents
WHENEVER SQL ERROR CALL kandoo_sql_errors_handler		

	CASE		
		WHEN sqlca.sqlcode = 100 		
			LET sql_stmt_status = 0		
		WHEN sqlca.sqlcode < 0 		
				LET sql_stmt_status = -1		
		OTHERWISE		
			LET sql_stmt_status = 1		
			CALL set_form_record_parent_strings_translation_U807(l_tbl_rec_application_strings.*)		
			RETURNING frm_rec_U807_strings_translation.*

			LET l_sql_statement = "SELECT program_name ",
			" FROM fgltarget WHERE fgltarget.container = ? AND ",glob_fgltarget_clause		
			CALL l_crs_fetch_program_name.Declare(l_sql_statement)
			CALL l_crs_fetch_program_name.Open(l_tbl_rec_application_strings.container)
			CALL l_crs_fetch_program_name.FetchNext(frm_rec_U807_strings_translation.program_name )

	END CASE		
	RETURN sql_stmt_status,frm_rec_U807_strings_translation.*		
END FUNCTION ## sql_fetch_full_row_parent_UT6_strings_translate		
		
########################################################################		
FUNCTION sql_insert_parent_UT6_strings_translate(p_tbl_rec_application_strings)		
## INSERT in table application_strings 		
	DEFINE l_sql_stmt_status integer		
	DEFINE rows_count SMALLINT		
	DEFINE p_prykey type_prykey_application_strings #Primary key record		
	DEFINE p_tbl_rec_application_strings type_tbl_rec_application_strings # Table image record		
		
	WHENEVER SQLERROR CONTINUE		
	CALL pr_ins_application_strings.Execute(	p_tbl_rec_application_strings.string_id,		
	p_tbl_rec_application_strings.container,		
	p_tbl_rec_application_strings.string_type,		
	p_tbl_rec_application_strings.string_contents	)		
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler		
		
	IF sqlca.sqlcode < 0 THEN 		
		LET l_sql_stmt_status = -1		
	ELSE 		
		LET l_sql_stmt_status = 0		
		LET p_prykey.string_id = p_tbl_rec_application_strings.string_id		
				
		
	END IF		
	RETURN l_sql_stmt_status,p_prykey.*		
END FUNCTION ## sql_insert_parent_UT6_strings_translate		
		
########################################################################		
FUNCTION sql_update_parent_UT6_strings_translate(p_prykey,p_tbl_rec_application_strings)		
## sql_update_parent_UT6_strings_translate :update application_strings record		
	DEFINE l_sql_stmt_status integer		
	DEFINE l_updated_rows_number integer		
	DEFINE p_prykey type_prykey_application_strings #Primary key record 		
	DEFINE p_tbl_rec_application_strings type_tbl_rec_application_strings # Table image record		
		
	WHENEVER SQLERROR CONTINUE		
	CALL pr_upd_application_strings.Execute(	p_tbl_rec_application_strings.container,		
	p_tbl_rec_application_strings.string_type,		
	p_tbl_rec_application_strings.string_contents	,p_prykey.*)		
		
WHENEVER SQL ERROR CALL kandoo_sql_errors_handler		
	LET l_sql_stmt_status = sqlca.sqlcode		
	LET l_updated_rows_number = sqlca.sqlerrd[3]		
	RETURN l_sql_stmt_status,l_updated_rows_number		
END FUNCTION ## sql_update_parent_UT6_strings_translate		
		
##############################################################################################		
FUNCTION sql_delete_parent_UT6_strings_translate(p_prykey)		
## sql_delete_parent_UT6_strings_translate :delete current row in table application_strings 		
	DEFINE l_sql_stmt_status smallint		
	DEFINE p_prykey type_prykey_application_strings #Primary key record 		
	DEFINE l_deleted_rows_number integer		
	WHENEVER SQLERROR CONTINUE		
	CALL pr_del_application_strings.Execute(p_prykey.*)		
		
WHENEVER SQL ERROR CALL kandoo_sql_errors_handler		
	LET l_sql_stmt_status = sqlca.sqlcode		
	LET l_deleted_rows_number = sqlca.sqlerrd[3]		
	RETURN l_sql_stmt_status,l_deleted_rows_number		
END FUNCTION ## sql_delete_parent_UT6_strings_translate		
		
################################################################################		
FUNCTION sql_pky_exists_parent_UT6_strings_translate(p_prykey)  		
##   sql_pky_exists_parent_UT6_strings_translate : Check if primary key exists		
## inbound parameter : record of primary key		
## outbound parameter:  status > 0 if exists, 0 if no record, < 0 if error		
	DEFINE p_prykey type_prykey_application_strings #Primary key record 		
	DEFINE pk_status INTEGER		
		
	WHENEVER SQLERROR CONTINUE		
	CALL crs_pky_application_strings.Open(p_prykey.*)		
	CALL crs_pky_application_strings.FetchNext() 		
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler		
		
	CASE sqlca.sqlcode		
		WHEN 0 		
			let pk_status = 1		
		WHEN 100		
			let pk_status = 0		
		WHEN sqlca.sqlerrd[2] = 104		
			let pk_status = -1 # record locked		
		WHEN sqlca.sqlcode < 0		
			let pk_status = sqlca.sqlcode		
	END CASE		
		
	RETURN pk_status		
END FUNCTION ## sql_pky_exists_parent_UT6_strings_translate		
		
################################################################################################		
FUNCTION set_form_record_parent_strings_translation_U807(p_tbl_contents)		
## set_form_record_parent_strings_translation_U807_U807_strings_translation: assigns table values to form fields values		
	DEFINE l_frm_contents type_frm_rec_U807_strings_translation # Form image record		
	DEFINE p_tbl_contents type_tbl_rec_application_strings # Table image record		
		
	INITIALIZE l_frm_contents.* TO NULL		
	LET l_frm_contents.string_id = p_tbl_contents.string_id		
	LET l_frm_contents.container = p_tbl_contents.container		
	LET l_frm_contents.string_type = p_tbl_contents.string_type		
	LET l_frm_contents.string_contents = p_tbl_contents.string_contents		
			
	RETURN l_frm_contents.*		
END FUNCTION ## set_form_recordUT6_strings_translate_U807_strings_translation		
		
################################################################################################		
FUNCTION set_table_record_U807_strings_translation_application_strings(sql_stmt_type,p_frm_contents)		
## set_table_record_U807_strings_translation_application_strings: assigns form fields value to table values		
	DEFINE sql_stmt_type CHAR(1)					# + => Insert, # => Update		
	DEFINE l_prykey type_prykey_application_strings #Primary key record 		
	DEFINE p_frm_contents type_frm_rec_U807_strings_translation # Form image record		
	DEFINE l_tbl_contents type_tbl_rec_application_strings # Table image record		
		
	INITIALIZE l_tbl_contents.* TO NULL		
	CASE sql_stmt_type		
		WHEN "+"			# Prepare record for INSERT		
			LET l_tbl_contents.string_id = p_frm_contents.string_id		
			LET l_tbl_contents.container = p_frm_contents.container		
			LET l_tbl_contents.string_type = p_frm_contents.string_type		
			LET l_tbl_contents.string_contents = p_frm_contents.string_contents		
					
		WHEN "#"			# Prepare record for UPDATE		
			LET l_tbl_contents.container = p_frm_contents.container		
			LET l_tbl_contents.string_type = p_frm_contents.string_type		
			LET l_tbl_contents.string_contents = p_frm_contents.string_contents		
					
	END CASE		
		
	RETURN l_tbl_contents.*		
END FUNCTION ## set_table_recordU807_strings_translation_application_strings		
		
FUNCTION generate_new_language_set() 
	DEFINE l_language_code LIKE language.language_code 
	DEFINE l_country_code LIKE country.country_code
	DEFINE l_language_text LIKE language.language_text 
	DEFINE l_national_text LIKE language.national_text 
	DEFINE language_count,strings_count,translate_count,new_translation INTEGER 
	DEFINE query_string,msg_string STRING 
	DEFINE l_rec_string RECORD
		string_id LIKE strings_translation.string_id,
		language_code LIKE strings_translation.language_code,
		country_code LIKE strings_translation.country_code,
		translation LIKE strings_translation.translation
	END RECORD
	DEFINE prp_insert_translation CURSOR
	DEFINE crs_scan_strings CURSOR

	INITIALIZE l_language_code TO NULL 

	INPUT BY NAME l_rec_string.language_code,l_rec_string.country_code
		AFTER FIELD language_code
			IF l_rec_string.language_code IS NULL THEN 
				NEXT FIELD language_code
			END IF 
			SELECT count(*) INTO language_count 
			FROM language 
			WHERE language_code = l_rec_string.language_code 
			IF language_count = 0 THEN 
				LET l_language_code = NULL 
				ERROR "This language is not in the languages list" 
				NEXT FIELD language_code
			ELSE
				LET l_language_code = l_rec_string.language_code
			END IF

			SELECT language_text,national_text 
			INTO l_language_text,l_national_text 
			FROM language 
			WHERE language_code = l_language_code 
			LET msg_string = l_language_code," ",l_language_text," ",l_national_text 
			ERROR msg_string 


	END INPUT

	IF l_rec_string.country_code IS NULL THEN
		LET l_rec_string.country_code = "ALL"    # i.e all countries
	END IF
	LET l_country_code = l_rec_string.country_code 

	SELECT count(*) 
		INTO strings_count 
		FROM application_strings  

	SELECT count(*) 
	INTO translate_count 
	FROM strings_translation 
	WHERE language_code = l_language_code 
		AND country_code = l_country_code

	IF translate_count = strings_count THEN 
		LET l_language_code = NULL 
		LET msg_string = "This language has already been generated, please check:",l_language_code 
		ERROR msg_string 
		RETURN
	ELSE 
		# select the strings that are not yet translated in this language ( reduces the data set )
		IF l_language_code = "ENG" THEN
			LET query_string = "SELECT string_id,",
			"'", l_language_code CLIPPED,l_country_code CLIPPED,"',",
			" string_contents ",
			" FROM application_strings WHERE string_id NOT IN ( SELECT string_id from strings_translation WHERE language_code = ? ) "
		ELSE
			LET query_string = "SELECT string_id,'",l_language_code CLIPPED,"',NULL::VARCHAR FROM application_strings WHERE string_id NOT IN ( SELECT string_id from strings_translation WHERE language_code = ? ) "
		END IF
		CALL crs_scan_strings.Declare(query_string)
		LET query_string = "INSERT INTO strings_translation (string_id,language_code,country_code,translation) VALUES (?,?,?,?)" 
		CALL prp_insert_translation.Declare(query_string) 
		--CALL prp_insert_translation.Prepare(query_string)
		BEGIN WORK
		CALL crs_scan_strings.Open(l_language_code)
		CALL prp_insert_translation.Open()

		LET new_translation = 0
		LET msg_string = "Generating Language SET  ",l_language_text,"..."
		ERROR msg_string 

		WHILE crs_scan_strings.FetchNext(l_rec_string.*) = 0
			WHENEVER SQLERROR CONTINUE
			CALL  prp_insert_translation.setParameters(l_rec_string.string_id,l_language_code,l_country_code,l_rec_string.translation)
			CALL prp_insert_translation.PUT ()
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			IF sqlca.sqlcode = 0 THEN
				LET new_translation = new_translation + 1
			ELSE
				# row already existing, we just skip
			END IF 
		END WHILE 
		WHENEVER SQLERROR CONTINUE
		COMMIT WORK
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		IF sqlca.sqlcode = 0 THEN
			LET msg_string = l_language_text," Language SET generated successfully "
			CALL fgl_winmessage(msg_string,new_translation,"INFO") 
		ELSE
			LET msg_string = l_language_text,"Language SET generated with ERRORS: ",sqlca.sqlcode
			CALL fgl_winmessage(msg_string,0,"ERROR") 
		END IF

	END IF 

END FUNCTION 	#  generate_new_language_set

FUNCTION show_form(p_container)
	DEFINE p_container LIKE application_strings.container
	DEFINE rep CHAR(1)
	CALL util.REGEX.replace(p_container,/\.fm2/,"") returning p_container
	OPEN WINDOW show_form_window WITH FORM p_container attribute(border)
	DISPLAY p_container TO lbformname

	MENU	
		BEFORE MENU
			 CALL dialog.setActionHidden("ACCEPT",TRUE)
			 CALL dialog.setActionHidden("CANCEL",TRUE)
		ON ACTION "DONE"
			EXIT MENU
	END MENU
	CLOSE WINDOW show_form_window
END FUNCTION # show_form