###############################################################################################
# Module Scope
###############################################################################################
--database kandoodb_test@kandoo_ref_tcp
--database kandoodb
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" #Try to extract the array from module scope and put in local
# TODO - move the array from module scope to local scope

DEFINE m_arr_tree DYNAMIC ARRAY OF RECORD
	description LIKE coatempltdetl.description,
	isclass boolean,
	isnominal boolean,
	CreateAccount boolean,
	parentId LIKE coatempltdetl.parent,
	id LIKE coatempltdetl.acct_code
END RECORD

DEFINE m_arr_moreinfo DYNAMIC ARRAY OF RECORD
	desc_text NCHAR(80),
	acct_type CHAR(1)
END RECORD

DEFINE m_arr_errors DYNAMIC ARRAY OF RECORD
	record_num INTEGER,
	templt_code LIKE coa.acct_code,
	generated_code LIKE coa.acct_code,
	error_shortmsg STRING,
	error_num INTEGER,
	error_message STRING
END RECORD

DEFINE glArrayId SMALLINT

#Table coatempltdetl	
DEFINE typeCoaTemplt TYPE AS RECORD
	acct_code LIKE coatempltdetl.acct_code,
	description LIKE coatempltdetl.description, 
	create_code SMALLINT,
	tree_level LIKE coatempltdetl.tree_level, 
	acct_type LIKE coatempltdetl.acct_type,
	is_max_level LIKE coatempltdetl.is_max_level
END RECORD

DEFINE cb_tmplt_country ui.combobox
DEFINE cb_tmplt_language ui.combobox


############################################################
# FUNCTION GZ9_main()
# RETURN VOID
#
############################################################

FUNCTION GZ9_main()
	DEFINE c INT
	DEFINE r INT
	DEFINE dnd ui.DragDrop

	DEFINE a_parentid DYNAMIC ARRAY OF LIKE coatempltdetl.acct_code
	DEFINE query_stmt STRING
	DEFINE current_level SMALLINT

	DEFINE idx INTEGER
	DEFINE l_parentid,former_id,former_parentid LIKE coatempltdetl.acct_code

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("GZ9") 

	OPEN WINDOW BuildCoaFromTemplate WITH FORM "G951"

	DISPLAY glob_rec_company.cmpy_code,glob_rec_company.name_text TO hdr_cmpy_code,hdr_cmpy_name
	CALL fill_combo_countries ()

	CALL create_coa_thru_template()

END FUNCTION # GZ9_main
	
FUNCTION create_coa_thru_template()
	DEFINE l_cmpy_code LIKE company.cmpy_code
	DEFINE l_country_code LIKE coatemplthead.country_code
	DEFINE l_language_code LIKE coatemplthead.language_code
	DEFINE l_start_year_num LIKE coa.start_year_num
	DEFINE l_start_period_num LIKE coa.start_period_num
	DEFINE l_end_year_num LIKE coa.end_year_num
	DEFINE l_end_period_num LIKE coa.end_period_num
	DEFINE l_padding_char CHAR(1)
	DEFINE l_padding_length SMALLINT
	DEFINE l_nb_created_accounts INTEGER
	DEFINE l_nb_error_accounts INTEGER

	MENU "Create chart of accounts"
		BEFORE MENU
			HIDE OPTION "Generate COA","Validate New COA","Discard New COA","Show errors","Parse New COA"
						
		COMMAND "Select COA template"
			CALL select_coa_template ()
			RETURNING l_cmpy_code,
				l_country_code,
				l_language_code,
				l_start_year_num,
				l_start_period_num,
				l_end_year_num,
				l_end_period_num,
				l_padding_char,
				l_padding_length
				
				SHOW OPTION "Generate COA"
			 
		COMMAND "Generate COA"
			CALL generate_coa(l_cmpy_code,
				l_start_year_num,
				l_start_period_num,
				l_end_year_num,
				l_end_period_num,
				l_padding_char,
				l_padding_length)
				RETURNING l_nb_created_accounts,l_nb_error_accounts
				IF l_nb_created_accounts > 0 THEN
					SHOW OPTION "Validate New COA"
				END IF
				IF l_nb_error_accounts > 0 THEN
					# leave no choice to rollback
					ROLLBACK WORK
					SHOW OPTION "Show errors"
				ELSE
					SHOW OPTION "Discard New COA"
					SHOW OPTION "Parse New COA"
				END IF
				
		COMMAND "Show errors"		
			CALL show_generation_errors()
			
		COMMAND "Validate New COA"
			COMMIT WORK
			HIDE OPTION "Validate New COA"
			ERROR "New coa created and validaded!"
			SHOW OPTION "Parse New COA"
				
		COMMAND "Discard New COA"
			ROLLBACK WORK
			HIDE OPTION "Discard New COA"
			
		COMMAND "Parse New COA"
			CALL parse_coa_tree ()
			
		COMMAND "EXIT"
			EXIT PROGRAM
	END MENU
END FUNCTION  # create_coa_thru_template

FUNCTION select_coa_template()
##- This function allows the selection of one coa template and displays it in an array
##- in order to eventually remove some nominal code
##- it also allows to define is nominal codes will be padded with any character on the right (ex 4413 becomes 441300)

	DEFINE l_rec_coatemplthead RECORD LIKE coatemplthead.*
	DEFINE query_stmt STRING
	DEFINE l_padding_char CHAR(1)
	DEFINE l_padding_length SMALLINT
	DEFINE l_country_text LIKE country.country_text
	DEFINE l_language_text LIKE language.language_text
	
	DEFINE l_cmpy_code LIKE coa.cmpy_code
	DEFINE l_name_text LIKE company.name_text
	DEFINE l_start_year_num LIKE coa.start_year_num
	DEFINE l_start_period_num LIKE coa.start_period_num
	DEFINE l_end_year_num LIKE coa.end_year_num
	DEFINE l_end_period_num LIKE coa.end_period_num
	DEFINE min_digits_for_nominal SMALLINT
	DEFINE idx SMALLINT
	DEFINE a_parentid DYNAMIC ARRAY OF LIKE coatempltdetl.acct_code
	DEFINE current_level SMALLINT
	DEFINE l_parentid,former_id,former_parentid LIKE coatempltdetl.acct_code
	
	DEFINE l_rec_coatemplt RECORD 
		acct_code LIKE coatempltdetl.acct_code,          
		description LIKE coatempltdetl.description, 
		tree_level char(2),
		acct_type LIKE coatempltdetl.acct_type,
		parent LIKE coatempltdetl.parent,
		is_max_level LIKE coatempltdetl.is_max_level
	END RECORD
	DEFINE l_arr_curr SMALLINT
	DEFINE l_scr_line SMALLINT
	DEFINE l_count_language SMALLINT
	DEFINE l_count_country SMALLINT
	DEFINE thiswindow ui.Window
	DEFINE thisform ui.Form
	DEFINE crs_scan_coatempldetldetl CURSOR
	LET thiswindow = ui.Window.getCurrent()
	LET thisform = thiswindow.getForm()

	LET l_cmpy_code = glob_rec_company.cmpy_code
	SELECT name_text
	INTO l_name_text
	FROM company
	WHERE cmpy_code = l_cmpy_code
	IF sqlca.sqlcode = 0 THEN
		DISPLAY l_cmpy_code,l_name_text 
		TO cmpy_code,name_text
	ELSE
		ERROR "This company does not exist"
	END IF
	ERROR "Please choose a template and input generation data"
	INPUT l_rec_coatemplthead.country_code,
		l_rec_coatemplthead.language_code,
		l_padding_char,
		l_padding_length,
		l_start_year_num,
		l_start_period_num,
		l_end_year_num,
		l_end_period_num
	FROM
		country_code,
		language_code,
		padding_char,
		padding_length,
		start_year_num,
		start_period_num,
		end_year_num,
		end_period_num
			 
		AFTER FIELD country_code
			SELECT country_text
			INTO l_country_text
			FROM country
			WHERE country_code = l_rec_coatemplthead.country_code
			IF sqlca.sqlcode = 0 THEN
				DISPLAY l_country_text TO country_text
			ELSE
				ERROR "Country code does not exist"
				--NEXT FIELD country_code
			END IF
			SELECT count(distinct(country_code))
			INTO l_count_country
			FROM coatemplthead
			WHERE country_code = l_rec_coatemplthead.country_code
			IF l_count_country = 0 THEN
				ERROR "There are no templates for this country, please choose another one"
				NEXT FIELD country_code
			END IF

		BEFORE FIELD language_code			
			CALL fill_combo_languages(l_rec_coatemplthead.country_code)
		
		AFTER FIELD language_code
			SELECT language_text
			INTO l_language_text
			FROM language
			WHERE language_code = l_rec_coatemplthead.language_code
			IF sqlca.sqlcode = 0 THEN
				DISPLAY l_language_text TO language_text
			ELSE
				ERROR "Language code does not exist"
				NEXT FIELD language_code
			END IF
			SELECT count(distinct(language_code))
			INTO l_count_language
			FROM coatemplthead
			WHERE language_code = l_rec_coatemplthead.language_code
			AND country_code = l_rec_coatemplthead.country_code
			IF l_count_language = 0 THEN
				ERROR "There are no templates for this country+language, please choose another one"
			END IF
			
			SELECT country_code,language_code,description,comments --comments
			INTO l_rec_coatemplthead.country_code,l_rec_coatemplthead.language_code,l_rec_coatemplthead.description,l_rec_coatemplthead.comments
			FROM coatemplthead
			WHERE country_code = l_rec_coatemplthead.country_code
			AND language_code = l_rec_coatemplthead.language_code
			
			IF sqlca.sqlcode = 0 THEN
				DISPLAY BY NAME l_rec_coatemplthead.country_code,
					l_rec_coatemplthead.language_code,
					l_rec_coatemplthead.description ,
					l_rec_coatemplthead.comments
			 ELSE
			 	ERROR "There is no coa template for these criteria, please choose another one"
			 	RETURN 1
			 END IF
			
		AFTER FIELD start_period_num
			SELECT 1
			FROM period
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND year_num = l_start_year_num
			AND period_num = l_start_period_num
			IF sqlca.sqlcode = 100 THEN
				ERROR "This period has not been set up, please check"
				NEXT FIELD start_year_num
			END IF

		AFTER FIELD end_period_num
			SELECT 1
			FROM period
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND year_num = l_end_year_num
			AND period_num = l_end_period_num
			IF sqlca.sqlcode = 100 THEN
				ERROR "This period has not been set up, please check"
				NEXT FIELD end_year_num
			END IF

	END INPUT

	# Now display the template in the tree view
	CALL m_arr_tree.Clear()
	LET query_stmt = "SELECT acct_code,",
	"description,",
	"tree_level,",
	"acct_type,",
	"parent,",
	"is_max_level ",
	" FROM coatempltdetl ",
	" WHERE country_code = ? ",
	"AND language_code = ? ",
	" ORDER BY acct_code "
	
	CALL crs_scan_coatempldetldetl.Declare(query_stmt)
	CALL crs_scan_coatempldetldetl.Open(l_rec_coatemplthead.country_code,l_rec_coatemplthead.language_code)
	
	LET min_digits_for_nominal = 3

	LET current_level = 0
	LET l_parentid = NULL
	ERROR "Building up a proposition from the template"
	LET idx = 0
	WHILE crs_scan_coatempldetldetl.FetchNext(l_rec_coatemplt.*) = 0
		LET idx = idx + 1
		LET m_arr_tree[idx].description = l_rec_coatemplt.acct_code,"-",l_rec_coatemplt.description
		LET m_arr_moreinfo[idx].desc_text = l_rec_coatemplt.description
		LET m_arr_moreinfo[idx].acct_type = l_rec_coatemplt.acct_type
	
		IF l_rec_coatemplt.is_max_level = 1 THEN  # this is for sure a nominal account
			LET m_arr_tree[idx].isnominal = true
			LET m_arr_tree[idx].isclass = false
		ELSE
			LET m_arr_tree[idx].isnominal = false
			LET m_arr_tree[idx].isclass = true
		END IF

		LET m_arr_tree[idx].parentid = l_rec_coatemplt.parent		
		LET m_arr_tree[idx].id  = l_rec_coatemplt.acct_code
		
		# Preset createAccount to true
		LET m_arr_tree[idx].CreateAccount = true
	END WHILE

	--CALL thisform.setFieldHidden("formonly.parentid",1)
	--CALL thisform.setFieldHidden("formonly.id",1)
	ERROR "Review/modify data, then Accept to validate this data" 
	INPUT ARRAY m_arr_tree WITHOUT DEFAULTS
	FROM tree.* ATTRIBUTE(UNBUFFERED)
	
		BEFORE INPUT
			CALL DIALOG.setSelectionMode("tree", 1)
			CALL DIALOG.SetFieldActive("description", false)
	
		BEFORE ROW
			LET l_arr_curr = arr_curr()
			LET l_scr_line = scr_line()
					
		AFTER FIELD CreateAccount
			IF m_arr_tree[l_arr_curr].isclass = true AND m_arr_tree[l_arr_curr].CreateAccount = false THEN
				ERROR "You cannot eliminate an account category, only nominal accounts"
				LET m_arr_tree[l_arr_curr].isnominal = true 
				DISPLAY m_arr_tree[l_arr_curr].isnominal TO tree[l_scr_line].isnominal
				NEXT FIELD isnominal
			END IF
	
	ON ACTION "HELP"
	CALL onlineHelp("TreeTable",NULL)		
		
	END INPUT
	RETURN l_cmpy_code,
		l_rec_coatemplthead.country_code,
		l_rec_coatemplthead.language_code,
		l_start_year_num,
		l_start_period_num,
		l_end_year_num,
		l_end_period_num,
		l_padding_char,
		l_padding_length
END FUNCTION		# select_coa_template


FUNCTION generate_coa (p_cmpy_code,p_start_year_num,p_start_period_num,p_end_year_num,p_end_period_num,p_padding_char,p_padding_length)
##- this function generates a new chart of account according to the input criteria
##- errors are placed in a specific array for further display and analysis
##- it starts with a begin work, but commit or rollback will have to be executed explicitly by the user
	DEFINE idx SMALLINT
	DEFINE p_cmpy_code LIKE coa.cmpy_code
	DEFINE p_start_year_num LIKE coa.start_year_num
	DEFINE p_start_period_num LIKE coa.start_period_num
	DEFINE p_end_year_num LIKE coa.end_year_num
	DEFINE p_end_period_num LIKE coa.end_period_num
	DEFINE p_padding_char CHAR(1)
	DEFINE p_padding_length SMALLINT
	DEFINE l_acct_code LIKE coa.acct_code
	DEFINE l_parentid LIKE coa.parentid
	DEFINE nb_created_accounts SMALLINT
	DEFINE nb_error_accounts SMALLINT
	DEFINE l_is_nominal BOOLEAN
	DEFINE query_stmt STRING
	DEFINE p_insert_coa PREPARED
	
	LET nb_created_accounts = 0
	LET nb_error_accounts = 0
	# Build INSERT prepare
	LET query_stmt = "INSERT INTO coa (cmpy_code,acct_code,desc_text,start_year_num,start_period_num,end_year_num,end_period_num,type_ind,is_nominalcode,parentid) ",
	" VALUES (?,?,?,?,?,?,?,?,?,?)"
	CALL p_insert_coa.Prepare(query_stmt)
	
	BEGIN WORK
	WHENEVER SQLERROR CONTINUE
	FOR idx = 1 TO m_arr_tree.Getsize()
		IF m_arr_tree[idx].CreateAccount = true THEN
			LET l_parentid = m_arr_tree[idx].parentid
			IF m_arr_tree[idx].isnominal = true THEN
				# prepare acct_code by padding with the padding char
				LET l_acct_code = pad_string(m_arr_tree[idx].id,p_padding_char,p_padding_length,"R")
				LET l_is_nominal = true
			ELSE
				LET l_acct_code = m_arr_tree[idx].id
				LET l_is_nominal = false
				# If not nominal, the account is created but not validated with start and end dates
			END IF
			CALL p_insert_coa.Execute(p_cmpy_code,l_acct_code,m_arr_moreinfo[idx].desc_text,
			p_start_year_num,p_start_period_num,p_end_year_num,p_end_period_num,
			m_arr_moreinfo[idx].acct_type,
			l_is_nominal,
			m_arr_tree[idx].parentid
			)
			
			IF sqlca.sqlcode = 0 THEN
				LET nb_created_accounts = nb_created_accounts + 1
			ELSE
				ERROR "Error on account",m_arr_tree[idx].id, "Aborting!"
				LET nb_error_accounts = nb_error_accounts + 1
				LET m_arr_errors[nb_error_accounts].record_num = idx
				LET m_arr_errors[nb_error_accounts].templt_code = m_arr_tree[idx].id
				LET m_arr_errors[nb_error_accounts].generated_code = l_acct_code
				LET m_arr_errors[nb_error_accounts].error_shortmsg = sqlca.sqlerrm
				LET m_arr_errors[nb_error_accounts].error_num = sqlca.sqlcode
				LET m_arr_errors[nb_error_accounts].error_message = sqlerrmessage
			END IF
		END IF
	END FOR
	
--WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	WHENEVER SQLERROR STOP
	WHENEVER ERROR STOP
	ERROR "Number of accounts created ",nb_created_accounts
	ERROR "Number of errors ",nb_error_accounts
	RETURN nb_created_accounts,nb_error_accounts
END FUNCTION	# generate_coa

FUNCTION parse_coa_tree ()
DEFINE idx SMALLINT
DEFINE thiswindow ui.Window
DEFINE thisform ui.Form
LET thiswindow = ui.Window.getCurrent()
	LET thisform = thiswindow.getForm()
	# Now display the template in the tree view
	CALL m_arr_tree.Clear()
	
	CALL thisform.setFieldHidden("formonly.CreateAccount",1)
	CALL thisform.setFieldHidden("coa.isnominal",1)
	CALL thisform.setFieldHidden("formonly.isclass",1)
	LET idx = 1

	DECLARE crs_scan_coa_tree CURSOR FOR
	SELECT trim (acct_code)|| " - " || desc_text,acct_code,parentId,is_nominalcode
	FROM coa
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	ORDER by acct_code
	
	WHENEVER SQLERROR CONTINUE
	SET ISOLATION TO DIRTY READ
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	FOREACH crs_scan_coa_tree INTO m_arr_tree[idx].description,
		m_arr_tree[idx].id,
		m_arr_tree[idx].parentId,
		m_arr_tree[idx].isnominal 			
		LET idx = idx + 1
	END FOREACH
	WHENEVER SQLERROR CONTINUE
	SET ISOLATION TO COMMITTED READ
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	DISPLAY ARRAY m_arr_tree 
	TO tree.* ATTRIBUTE(UNBUFFERED)

# display the fields again
	CALL thisform.setFieldHidden("formonly.CreateAccount",0)
	CALL thisform.setFieldHidden("coa.isnominal",0)
	CALL thisform.setFieldHidden("formonly.isclass",0)
	close crs_scan_coa_tree
	free crs_scan_coa_tree
END FUNCTION		# parse_coa_tree


FUNCTION show_generation_errors ()
	-- OPEN WINDOW BuildCoaErrors WITH FORM "G9s51_errors"
	DISPLAY ARRAY m_arr_errors 
	TO errors_list.*
	--CLOSE WINDOW BuildCoaErrors
END FUNCTION 	# show_generation_errors

###############################################################################################
# FUNCTION FILL(max_level)
#
#
###############################################################################################	
{
FUNCTION FILL(max_level)

    DEFINE max_level, p INT
    CALL m_arr_tree.clear()
    LET p = fill_tree(max_level, 1, 0, NULL)
END FUNCTION
}
FUNCTION fill_combo_countries()
	DEFINE l_country_text LIKE country.country_text
	LET cb_tmplt_country = ui.combobox.forname("country_code")
	LET cb_tmplt_language = ui.combobox.forname("language_code")
	CALL cb_tmplt_country.Clear()
	DECLARE crs_find_distinct_countries CURSOR FOR
	SELECT distinct(country_code)
	FROM coatempltdetl
	
	FOREACH crs_find_distinct_countries INTO l_country_text
		CALL cb_tmplt_country.additem(l_country_text)
	END FOREACH

END FUNCTION # fill_combo_countries

FUNCTION fill_combo_languages(p_country)
	DEFINE p_country LIKE country.country_code
	DEFINE l_language_code LIKE language.language_code
	CALL cb_tmplt_language.Clear()
	DECLARE crs_find_distinct_languages CURSOR FOR
	SELECT distinct(language_code)
	FROM coatempltdetl
	WHERE country_code = p_country
	
	FOREACH crs_find_distinct_languages INTO l_language_code
		CALL cb_tmplt_language.additem(l_language_code)
	END FOREACH
	CLOSE crs_find_distinct_languages
	FREE crs_find_distinct_languages
END FUNCTION # fill_combo_languages
