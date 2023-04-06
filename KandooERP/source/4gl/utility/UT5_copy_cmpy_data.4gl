############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

DEFINE t_tables_list TYPE as RECORD
	ord_num INTEGER,
    tabname LIKE table_documentation.tabname,
	do_copy BOOLEAN,
    documentation LIKE table_documentation.documentation,
    nb_rows_src INTEGER,
    nb_rows_trg INTEGER,
    op_status CHAR(5)
END RECORD


#@G00009
DEFINE g_table_documentation RECORD LIKE table_documentation.* 


MAIN 
	#Initial UI Init
	CALL setModuleId("UT5") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	CALL main_UT5_copy_data() 

END MAIN 

FUNCTION main_UT5_copy_data() 

	## this module's main function called by MAIN

	OPEN WINDOW f_copy_cmpy_data with FORM "U997" 
	--CALL windecoration_u("U997")   # useless

	--CALL sql_prepare_queries_UT5_copy_data () # INITIALIZE all cursors ON master TABLE 

	CALL menu_UT5_copy_data() 

	CLOSE WINDOW f_copy_cmpy_data 

END FUNCTION  # main_UT5_copy_data

######################################################################
FUNCTION menu_UT5_copy_data () 
	## menu_UT5_copy_data
	## the top level menu
	## input arguments: none
	## output arguments: none

    DEFINE l_scr_cmpy_code LIKE company.cmpy_code   # Source company (data comes FROM this company)
    DEFINE l_trg_cmpy_code LIKE company.cmpy_code   # Target company (data goes TO this company)
    DEFINE l_arr_tables_list DYNAMIC ARRAY OF t_tables_list
    DEFINE l_xaction_mode CHAR(1)

	DEFINE record_found INTEGER 
	DEFINE lookup_status INTEGER 

	MENU "Copy Company Data" 
		BEFORE MENU 
			HIDE option "Execute Copy Scenario"

		COMMAND "Construct Copy Scenario" "Select source and target cmpy + tables to copy" 
			CALL frm_input_scenario_data() RETURNING l_scr_cmpy_code,l_trg_cmpy_code,l_xaction_mode,l_arr_tables_list
			IF l_arr_tables_list.GetSize() > 0 THEN 
				SHOW OPTION "Execute Copy Scenario"
            END IF

		COMMAND "Execute Copy Scenario" "Execute Copy Scenario with selected companies and tables" #@g00113 
			CALL execute_copy_scenario (l_scr_cmpy_code,l_trg_cmpy_code,l_xaction_mode,l_arr_tables_list)

        COMMAND "Exit"
            EXIT PROGRAM
    END MENU
END FUNCTION

FUNCTION frm_input_scenario_data ()
    DEFINE l_scr_cmpy_code LIKE company.cmpy_code   # Source company (data comes FROM this company)
    DEFINE l_trg_cmpy_code LIKE company.cmpy_code   # Target company (data goes TO this company)
	DEFINE l_src_cmpy_name LIKE company.name_text
    DEFINE l_trg_cmpy_name LIKE company.name_text
    DEFINE l_bm_list CHAR(256)
    DEFINE l_table_list CHAR(256)
    DEFINE l_xaction_mode CHAR(1)
    DEFINE l_arr_tables_list DYNAMIC ARRAY OF t_tables_list
    DEFINE query_stmt STRING
	DEFINE where_clause STRING
    DEFINE l_idx INTEGER
    DEFINE l_arr_curr INTEGER
	DEFINE crs_count_rows CURSOR
	DEFINE crs_list_tables CURSOR
	
	INPUT l_scr_cmpy_code,
		l_trg_cmpy_code,
		l_bm_list,
		l_xaction_mode,
		l_table_list
		
	FROM src_cmpy_code,
		trg_cmpy_code,
		bm_list,
		xaction_mode,
		sr_tables_list.tabname
		
		BEFORE INPUT
			LET l_xaction_mode = "R"

		BEFORE FIELD src_cmpy_code
			CALL dyn_combolist_company ("src_cmpy_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,NULL) 

		AFTER FIELD src_cmpy_code
			IF l_scr_cmpy_code IS NULL THEN
				ERROR "Please select a company code"
				NEXT FIELD src_cmpy_code
			END IF

			SELECT name_text INTO l_src_cmpy_name
			FROM company
			WHERE cmpy_code = l_scr_cmpy_code

			IF sqlca.sqlcode = 0 THEN
				DISPLAY l_src_cmpy_name TO src_cmpy_name
			ELSE
				NEXT FIELD src_cmpy_code
			END IF

		BEFORE FIELD trg_cmpy_code
			CALL dyn_combolist_company ("trg_cmpy_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,l_scr_cmpy_code) 

		AFTER FIELD trg_cmpy_code
			IF l_trg_cmpy_code IS NULL THEN
				ERROR "Please select a company code"
				NEXT FIELD trg_cmpy_code
			END IF

			SELECT name_text INTO l_trg_cmpy_name
			FROM company
			WHERE cmpy_code = l_trg_cmpy_code

			IF sqlca.sqlcode = 0 THEN
				DISPLAY l_trg_cmpy_name TO trg_cmpy_name
			ELSE
				NEXT FIELD trg_cmpy_code
			END IF


		--AFTER FIELD bm_list
			--LET where_clause = l_bm_list

		--AFTER FIELD tabname
			--IF 

	END INPUT

	IF int_flag THEN	
		LET l_scr_cmpy_code = NULL
		LET l_trg_cmpy_code = NULL
		CALL l_arr_tables_list.Clear()
		RETURN l_scr_cmpy_code,l_trg_cmpy_code,l_arr_tables_list
	END IF	
	CALL l_arr_tables_list.Clear()
		
	# Select all the tables matching criteria that have a cmpy_code
	LET query_stmt = "SELECT 0,d.tabname,'t',d.documentation,0,0,'todo' ",
	" FROM table_documentation d, ",
	"systables s ",
	"WHERE d.tabname = s.tabname ",
	" AND d.tabname IN ( SELECT DISTINCT c.tabname FROM column_documentation c where c.colname = 'cmpy_code' ) "
	IF l_bm_list IS NOT NULL THEN
		LET query_stmt = query_stmt," AND d.usage_bmlist matches '",l_bm_list clipped,"' "
	END IF

	IF l_table_list IS NOT NULL THEN
		LET query_stmt = query_stmt," AND d.tabname matches '",l_table_list clipped,"' "
	END IF
	LET query_stmt = query_stmt," ORDER by 1"
	
	CALL crs_list_tables.Declare (query_stmt)
	CALL crs_list_tables.Open()

	LET l_idx = 1
	WHENEVER SQLERROR STOP		# FIXME: IF we remove "STOP" and fetch has an error due to wrong field names, WHENEVER ERROR CALLS kandoo_sql_error_handler for sqlca.sqlcode = 100
	# To reproduce, you may change the name of one of the variable
	WHILE crs_list_tables.FetchNext(l_arr_tables_list[l_idx]) = 0
		LET l_arr_tables_list[l_idx].ord_num = l_idx
		# count number of rows for the source company
		LET query_stmt = "SELECT COUNT(*) FROM ",l_arr_tables_list[l_idx].tabname,
		" WHERE cmpy_code = ? "
		CALL crs_count_rows.Declare(query_stmt )
		# Count rows in source company
		CALL crs_count_rows.Open(l_scr_cmpy_code)
		CALL crs_count_rows.FetchNext(l_arr_tables_list[l_idx].nb_rows_src)
		# Count rows in target company
		CALL crs_count_rows.Open(l_trg_cmpy_code)
		CALL crs_count_rows.FetchNext(l_arr_tables_list[l_idx].nb_rows_trg)
		IF l_arr_tables_list[l_idx].nb_rows_trg > 0 THEN
			LET l_arr_tables_list[l_idx].do_copy = false
			LET l_arr_tables_list[l_idx].op_status = "SKIP TBL"
		END IF
		LET l_idx = l_idx + 1
	END WHILE
	CALL l_arr_tables_list.DeleteElement(l_idx)

	INPUT ARRAY l_arr_tables_list WITHOUT DEFAULTS FROM sr_tables_list.* attribute(UNBUFFERED,auto append = false, append row = false, delete row = false,insert row = false)
		BEFORE ROW 
			LET l_arr_curr = arr_curr()
			
		ON CHANGE do_copy
			IF  l_arr_tables_list[l_arr_curr].do_copy = false THEN
				LET l_arr_tables_list[l_arr_curr].op_status = "SKIP TBL"
			ELSE
				LET l_arr_tables_list[l_arr_curr].op_status = "to do"
			END IF
			DISPLAY l_arr_tables_list[l_arr_curr].op_status TO sr_tables_list[l_arr_curr].op_status
	END INPUT

	RETURN l_scr_cmpy_code,l_trg_cmpy_code,l_xaction_mode,l_arr_tables_list
END FUNCTION   #  frm_input_scenario_data

FUNCTION execute_copy_scenario(p_scr_cmpy_code,p_trg_cmpy_code,p_xaction_mode,p_arr_tables_list)
    DEFINE p_scr_cmpy_code LIKE company.cmpy_code   # Source company (data comes FROM this company)
    DEFINE p_trg_cmpy_code LIKE company.cmpy_code   # Target company (data goes TO this company)
    DEFINE p_arr_tables_list DYNAMIC ARRAY OF t_tables_list
    DEFINE nbr_rows_copied INTEGER
    DEFINE l_idx INTEGER
    DEFINE sql_stmt STRING
    DEFINE p_xaction_mode CHAR(1)
    DEFINE p_execute_stmt PREPARED
    DEFINE crs_rows_copied CURSOR
    
    # we take the array of the tables to copy
	# and execute the stored procedure, returning number of copied rows
	IF p_xaction_mode = "G" THEN
		BEGIN WORK
		CALL p_execute_stmt.Prepare("SET CONSTRAINTS ALL DEFERRED")
		CALL p_execute_stmt.Execute()
	END IF
    FOR l_idx = 1 TO p_arr_tables_list.GetSize()
    	IF p_arr_tables_list[l_idx].do_copy = true THEN
    		LET sql_stmt = "EXECUTE FUNCTION copy_company_data_for_table (",
    		"'",p_arr_tables_list[l_idx].tabname clipped,"',",
    		"'",p_scr_cmpy_code clipped, "',",
    		"'",p_trg_cmpy_code clipped,"') "
    		WHENEVER SQLERROR CONTINUE
    		# Execute the copy and return nb rows copied
			IF p_xaction_mode = "T" THEN
				BEGIN WORK
			END IF
    		CALL p_execute_stmt.Prepare(sql_stmt)
    		IF sqlca.sqlcode = 0 THEN
    			CALL crs_rows_copied.Declare(p_execute_stmt)
    			CALL crs_rows_copied.Open()
    			CALL crs_rows_copied.FetchNext(nbr_rows_copied)
    			
    			IF sqlca.sqlcode = 0 THEN
    				LET p_arr_tables_list[l_idx].nb_rows_trg = nbr_rows_copied
    				LET p_arr_tables_list[l_idx].op_status = "OK"
    			ELSE
    				LET p_arr_tables_list[l_idx].nb_rows_trg = nbr_rows_copied
    				LET p_arr_tables_list[l_idx].op_status = "KO:",sqlca.sqlcode
    			END IF
    		ELSE
    			LET p_arr_tables_list[l_idx].nb_rows_trg = nbr_rows_copied
    			LET p_arr_tables_list[l_idx].op_status = "KO:",sqlca.sqlcode
    		END IF
    		DISPLAY p_arr_tables_list[l_idx].* TO sr_tables_list[l_idx].*
    		IF p_xaction_mode = "T" THEN
				COMMIT WORK
			END IF
    		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
    		
    	END IF
    END FOR
	
	IF p_xaction_mode = "G" THEN
		COMMIT WORK
	END IF
	IF p_xaction_mode = "G" OR p_xaction_mode = "T" THEN
		# return to default constraints mode
		CALL p_execute_stmt.Prepare("SET CONSTRAINTS ALL IMMEDIATE")
		CALL p_execute_stmt.Execute()
	END IF
	RETURN 
END FUNCTION # execute_copy_scenario()

# this combo on maingrp is dynamic, is filters on NOT cmpy_code
FUNCTION dyn_combolist_company (p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null,p_cmpy_code)
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	IF p_cmpy_code IS NOT NULL THEN
		LET l_wherestring = " WHERE cmpy_code <> '",p_cmpy_code,"' "
	ELSE
		LET l_wherestring = " WHERE 1 = 1"
	END IF
	CALL comboList_Flex(p_cb_field_name,"company", "cmpy_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 
END FUNCTION # dyn_combolist_company

