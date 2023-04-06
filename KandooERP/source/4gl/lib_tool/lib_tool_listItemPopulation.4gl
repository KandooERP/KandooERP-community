############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_static_cb_arr DYNAMIC ARRAY WITH 2 DIMENSIONS OF STRING

###########################################################################################################
############################################################
# FUNCTION clearcombo()
#
#
############################################################
FUNCTION clearcombo() 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD 

END FUNCTION 
############################################################
# END FUNCTION clearcombo()
############################################################

############################################################
# FUNCTION combolist_flex(p_cb_field_name,p_table,p_field1,p_field2,p_where,p_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null)
#
#
############################################################
FUNCTION combolist_flex(p_cb_field_name,p_table,p_field1,p_field2,p_where,p_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null)
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD 
	DEFINE p_table STRING 
	DEFINE p_field1 STRING 
	DEFINE p_field2 STRING 
	DEFINE p_where STRING 
	DEFINE p_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable, 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST, 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL, 1= variable = LABEL 
	DEFINE p_hint SMALLINT --0= only variable, 1 = SHOW both VALUES in LABEL var left, 2 = SHOW both VALUES in LABEL var right 
	DEFINE p_add_null SMALLINT --0 = don't add any literal NULL, 1=null with "" LABEL, 2="NULL" with "NONE" 
	DEFINE curs_combo CURSOR 
	DEFINE p_sql_stmt STRING 
	DEFINE l_comborec RECORD 
		listvalue NVARCHAR(100), --can NOT be STRING 
		listlabel NVARCHAR(100) --can NOT be STRING 
	END RECORD 
	DEFINE l_err_code int 
	DEFINE i int 
	DEFINE l_label STRING 
	DEFINE l_include_condition boolean
	DEFINE l_ui_cb ui.ComboBox 
	#Handle multiple tables in argument
	#Example :"prodstatus,product"

	#add NULL value to list

	WHENEVER ERROR CONTINUE 

	LET l_ui_cb = ui.combobox.forname(p_cb_field_name)
	IF l_ui_cb IS NULL THEN
		--ERROR "ComboBox ", trim(p_cb_field_name), " does not exist in form" 
		RETURN NULL
	END IF
	
	CALL l_ui_cb.clear()
	CALL cb_object_add_null(l_ui_cb,p_add_null)

	WHENEVER ERROR STOP
	LET p_sql_stmt = 
		"SELECT DISTINCT ", 
		trim(p_field1), ", ", 
		trim(p_field2), " ", 
		"FROM ", trim(p_table), " ", 
		trim(p_where) 

	IF p_sort = 0 THEN 
		LET p_sql_stmt = p_sql_stmt, " ORDER BY ", trim(p_field1), " ASC " 
	ELSE 
		LET p_sql_stmt = p_sql_stmt, " ORDER BY ", trim(p_field2), " ASC " 
	END IF 

	#DISPLAY p_sql_stmt

	CALL curs_combo.declare(p_sql_stmt,1) RETURNING l_err_code 
	CALL curs_combo.setresults(l_comborec.listvalue, l_comborec.listlabel) RETURNING l_err_code 


	CALL curs_combo.open() RETURNING l_err_code 

	LET i = 0 
	WHILE (curs_combo.fetchnext()=0) 
		LET i = i + 1 

		IF get_debug() THEN 
			DISPLAY ">>>>>>>>>>>",l_comboRec.listValue, " <-> ", l_comborec.listlabel 
		END IF 


		IF p_condition_group IS NULL THEN 
			LET l_include_condition = true 
		ELSE 

			CASE p_condition_group 
				WHEN "CUSTOMER_DELETED"
					CASE p_condition_type
						WHEN "MARK"
							IF db_customer_get_delete_flag2(UI_OFF,l_comboRec.listValue) = "Y" THEN
								LET l_comboRec.listLabel = l_comboRec.listLabel, " *"
							END IF
							
					END CASE
					LET l_include_condition = true 
					
				WHEN "COA_ACCOUNT_TYPE" 
					CASE p_condition_type 
						WHEN COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION  
							IF db_coa_acct_type_for_coa_list(glob_rec_kandoouser.cmpy_code,l_comboRec.listValue,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"N") THEN 
								LET l_include_condition = true 
								IF get_debug() THEN 
									DISPLAY ">>VALIDATED>>",l_comboRec.listValue, " <-> ", l_comborec.listlabel 
								END IF 

							ELSE 
								LET l_include_condition = false 
							END IF 

						WHEN COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK
							IF db_coa_acct_type_for_coa_list(glob_rec_kandoouser.cmpy_code,l_comboRec.listValue,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK,"N") THEN 
								LET l_include_condition = true 
								IF get_debug() THEN 
									DISPLAY ">>VALIDATED>>",l_comboRec.listValue, " <-> ", l_comborec.listlabel 
								END IF 
							ELSE 
								LET l_include_condition = false 
							END IF 

						WHEN COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER 
							IF db_coa_acct_type_for_coa_list(glob_rec_kandoouser.cmpy_code,l_comboRec.listValue,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"N") THEN 
								LET l_include_condition = true 
								IF get_debug() THEN 
									DISPLAY ">>VALIDATED>>",l_comboRec.listValue, " <-> ", l_comborec.listlabel 
								END IF 
							ELSE 
								LET l_include_condition = false 
							END IF 

						WHEN COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK 
							IF db_coa_acct_type_for_coa_list(glob_rec_kandoouser.cmpy_code,l_comboRec.listValue,COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK,"N") THEN 
								LET l_include_condition = true 
								IF get_debug() THEN 
									DISPLAY ">>VALIDATED>>",l_comboRec.listValue, " <-> ", l_comborec.listlabel 
								END IF 
							ELSE 
								LET l_include_condition = false 
							END IF 


					END CASE 
			END CASE 
		END IF 




		IF l_include_condition = true THEN 

			#		IF i = 1 THEN
			#
			#			IF STATUS <> 0 THEN
			#				CALL fgl_winmessage("Combo Lookup Error",curs_combo.getStatement(),"error")
			#			END IF
			#		END IF


			IF p_variable = 0 THEN --variable IS FIRST column/field COMBO_FIRST_ARG_IS_VALUE 

				IF p_single = 1 THEN --listitem variable value = LABEL combo_value_is_label 
					IF p_hint = 0 THEN --only variable value as LABEL 
						CALL l_ui_cb.additem(trim(l_comborec.listvalue),trim(l_comborec.listvalue)) 
					ELSE --only label/text IS shown 
						CALL l_ui_cb.additem(trim(l_comborec.listvalue),trim(l_comborec.listlabel)) 
					END IF 

				ELSE --listitem IS a pair OF variable value AND LABEL 

					CASE p_hint 
						WHEN 0 
							CALL l_ui_cb.additem(trim(l_comborec.listvalue),trim(l_comborec.listlabel)) 
						WHEN 1 -- add both VALUES TO the LABEL 
							LET l_label = trim(l_comborec.listvalue), "\t", trim(l_comborec.listlabel) 
							CALL l_ui_cb.additem(trim(l_comborec.listvalue),trim(l_label)) 
						WHEN 2 -- add var TO the right 
							LET l_label = trim(l_comborec.listlabel), " (", trim(l_comborec.listvalue), ")" 
							CALL l_ui_cb.additem(trim(l_comborec.listvalue),trim(l_label)) 
						WHEN 3 -- add var TO the left 
							LET l_label = trim(l_comborec.listvalue), " - ", trim(l_comborec.listlabel) 
							IF get_debug() THEN 
								DISPLAY "ListLabel:", trim(l_label) 
							END IF 
							CALL l_ui_cb.additem(trim(l_comborec.listvalue),trim(l_label)) 
					END CASE 

				END IF 

			ELSE --variable IS second column/field 

				IF p_single = 1 THEN --listitem variable value = LABEL 
					CALL l_ui_cb.additem(trim(l_comborec.listlabel),trim(l_comborec.listlabel)) 
				ELSE 

					CASE p_hint 
						WHEN 0 
							CALL l_ui_cb.additem(trim(l_comborec.listvalue),trim(l_comborec.listlabel)) 
						WHEN 1 -- add both VALUES TO the LABEL left 
							LET l_label = trim(l_comborec.listlabel), " - ", trim(l_comborec.listvalue) 
							CALL l_ui_cb.additem(trim(l_comborec.listlabel),trim(l_label)) 
						WHEN 2 -- add var TO the right 
							LET l_label = trim(l_comborec.listvalue), " (", trim(l_comborec.listlabel), ")" 
							CALL l_ui_cb.additem(trim(l_comborec.listlabel),trim(l_label)) 
					END CASE 
				END IF 
			END IF 
		END IF 

		#		LET i = i+1
	END WHILE 

	IF i < 1 THEN 
		IF p_table <> "t_prodstructure" THEN
			DISPLAY "Empty Lookup for: ", p_cb_field_name 
		END IF
	END IF 

	WHENEVER ERROR stop 

	RETURN i 

END FUNCTION 
############################################################
# END FUNCTION combolist_flex(p_cb_field_name,p_table,p_field1,p_field2,p_where,p_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null)
############################################################


############################################
# FUNCTION cb_object_add_null(p_ui_cb,p_add_null
#
# Include NULL literal
############################################
FUNCTION cb_object_add_null(p_ui_cb,p_add_null) 
	DEFINE p_ui_cb ui.ComboBox  --form FIELD NAME 
	DEFINE p_add_null SMALLINT 
	--WHENEVER ERROR CONTINUE --alch kd-1415: temporary fix, remove it asap WHEN REAL issue fixed 
	CASE p_add_null 
		WHEN COMBO_NULL_NOT #Don't allow NULL entry
			#No NULL item will be added/available 
		WHEN COMBO_NULL_SPACE 
			CALL p_ui_cb.addItem(NULL,"")  
		WHEN COMBO_NULL_NONE 
			CALL p_ui_cb.addItem(NULL,"None")  
		WHEN COMBO_NULL_NA 
			CALL p_ui_cb.addItem(NULL,"N/A")  
		WHEN COMBO_NULL_UD 
			CALL p_ui_cb.addItem(NULL,"User Default")  
		WHEN COMBO_NULL_NOT_ON_HOLD 
			CALL p_ui_cb.addItem(NULL,"NOT on Hold") 
		WHEN COMBO_NULL_NOT_USED 
			CALL p_ui_cb.addItem(NULL,"NOT Used") 
		WHEN COMBO_NULL_ANY 
			CALL p_ui_cb.addItem(NULL,"* Any *") 


	END CASE 

END FUNCTION
############################################
# END FUNCTION cb_object_add_null(p_ui_cb,p_add_null
############################################


############################################
# FUNCTION comboList_add_Null(p_cb_field_name,p_add_null)
#
# Include NULL literal
############################################
FUNCTION combolist_add_null(p_cb_field_name,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_add_null SMALLINT 
	--WHENEVER ERROR CONTINUE --alch kd-1415: temporary fix, remove it asap WHEN REAL issue fixed 
	CASE p_add_null 
		WHEN 0 #COMBO_NULL_NOT 
		WHEN 1 
			CALL ui.ComboBox.ForName(p_cb_field_name).addItem(NULL,"") #combo_null_space 
		WHEN 2 
			CALL ui.ComboBox.ForName(p_cb_field_name).addItem(NULL,"None") #combo_null_none 
		WHEN 3 
			CALL ui.ComboBox.ForName(p_cb_field_name).addItem(NULL,"N/A") #combo_null_na 
		WHEN 4 
			CALL ui.ComboBox.ForName(p_cb_field_name).addItem(NULL,"User Default") #combo_null_na 

	END CASE 

END FUNCTION 
############################################
# END FUNCTION comboList_add_Null(p_cb_field_name,p_add_null)
############################################


###########################################################################################################


############################################
# Special Case ! do not copy paste !
# FUNCTION comboList_prodstructure_price_level_seq_num(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_kandooword(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	#DEFINE p_class_code STRING
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE l_arr_rec_comboboxdata DYNAMIC ARRAY OF t_rec_kandooword_rc_rt_with_scrollflag 
	DEFINE i SMALLINT 
	#LET l_whereString =  " WHERE cmpy_code = \'", trim(getCurrentUser_cmpy_code()), "\' AND class_code = '", trim(p_class_code), "' "
	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear() 
	CALL show_kandooword_filter_datasource(p_condition_type,false) RETURNING l_arr_rec_comboboxdata 
	FOR i = 1 TO l_arr_rec_comboboxdata.getlength() 
		CALL ui.combobox.forname(p_cb_field_name).additem(l_arr_rec_comboboxdata[i].reference_code,l_arr_rec_comboboxdata[i].response_text) 
	END FOR 
	WHENEVER ERROR STOP
END FUNCTION 
############################################
# Special Case ! do not copy paste !
# END FUNCTION comboList_prodstructure_price_level_seq_num(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################


############################################
# Special Case ! do not copy paste !
# Note, this is a special case with classs_code
# FUNCTION comboList_prodstructure_price_level_seq_num(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_class_code,p_add_null)
######################################
FUNCTION combolist_prodstructure_price_level_seq_num_by_class_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_class_code,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_class_code LIKE prodstructure.class_code 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND class_code = '", trim(p_class_code), "\' AND type_ind != 'F'"
--	CALL ui.combobox.forname(p_cb_field_name).clear() 
	CALL comboList_Flex(p_cb_field_name,"prodstructure", "seq_num", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 
############################################
# Special Case ! do not copy paste ! Note, this is a special case with classs_code
# END FUNCTION comboList_prodstructure_price_level_seq_num(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_class_code,p_add_null)
######################################


############################################
# Note, this is a special case with classs_code when the temporary table 't_prodstructure' is used.
# FUNCTION comboList_t_prodstructure_price_level_seq_num(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_class_code,p_add_null)
######################################
FUNCTION combolist_t_prodstructure_price_level_seq_num_by_class_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_class_code,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_class_code LIKE prodstructure.class_code 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND class_code = '", trim(p_class_code), "\' AND type_ind != 'F'"
--	CALL ui.combobox.forname(p_cb_field_name).clear() 
	CALL comboList_Flex(p_cb_field_name,"t_prodstructure", "seq_num", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION



############################################
#FUNCTION comboList_period(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_order_num(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 

		IF p_condition_type IS NOT NULL THEN
			LET l_whereString =  l_whereString CLIPPED, " AND cust_code = \'", trim(p_condition_type), "\' "
		END IF
	LET p_condition_type = NULL  
	CALL comboList_Flex(p_cb_field_name,"orderhead", "order_num", "ord_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


############################################
#FUNCTION comboList_period(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_period(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 

	#	IF p_condition_type IS NOT NULL THEN
	#		LET l_whereString =  l_whereString CLIPPED, " AND type_ind = \'", trim(p_condition_type), "\' "
	#	END IF
	LET p_condition_type = NULL  
	CALL comboList_Flex(p_cb_field_name,"period", "period_num", "period_num", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 


END FUNCTION 

############################################
#FUNCTION comboList_stattype_type_text(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_stattype_type_text(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 

	IF p_condition_type IS NOT NULL THEN 
		LET l_wherestring = l_wherestring clipped, " AND type_ind = \'", trim(p_condition_type), "\' " 
	END IF 
	LET p_condition_type = NULL 
	CALL comboList_Flex(p_cb_field_name,"stattype", "type_code", "type_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


############################################
# FUNCTION comboList_unit_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_unit_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 


	CALL comboList_Flex(p_cb_field_name,"jmresource", "unit_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



############################################
# FUNCTION comboList_job_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_job_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 


	CALL comboList_Flex(p_cb_field_name,TRAN_TYPE_JOB_JOB, "job_code", "title_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

############################################
# FUNCTION comboList_proddanger_dg_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_proddanger_dg_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 


	CALL comboList_Flex(p_cb_field_name,"proddanger", "dg_code", "tech_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

############################################
# FUNCTION combolist_prodadjtype_code_text(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_prodadjtype_code_text(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"prodadjtype", "adj_type_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



############################################
# FUNCTION combolist_suburb_code_text(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_suburb_code_text(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"suburb", "suburb_code", "suburb_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


############################################
# FUNCTION comboList_printcodes(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
######################################
FUNCTION combolist_printcodes(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	#LET l_whereString =  " WHERE cmpy_code = \'", trim(getCurrentUser_cmpy_code()), "\' "

--	CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"printcodes", "print_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



############################################
# language_code language_text
######################################
FUNCTION combolist_language(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	#LET l_whereString =  " WHERE cmpy_code = \'", trim(getCurrentUser_cmpy_code()), "\' "
--	CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"language", "language_code", "language_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 





############################################
# sr_stdgrp group_code
######################################

FUNCTION combolist_stnd_group_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"stnd_grp", "group_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


# job job_code
############################################
# arparms ref1_code Customer User Prompts
######################################

FUNCTION combolist_arparms_ref1_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AR\' " 

	CALL comboList_Flex(p_cb_field_name,"arparms", "ref1_ind", "ref1_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

############################################
# arparms ref2_code Customer User Prompts
######################################

FUNCTION combolist_arparms_ref2_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AR\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"arparms", "ref2_ind", "ref2_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

############################################
# arparms ref3_code Customer User Prompts
######################################

FUNCTION combolist_arparms_ref3_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AR\' " 
--	CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"arparms", "ref3_ind", "ref3_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


############################################
# arparms ref4_code Customer User Prompts
######################################

FUNCTION combolist_arparms_ref4_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AR\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"arparms", "ref4_ind", "ref4_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


############################################
# arparms ref5_code Customer User Prompts
######################################

FUNCTION combolist_arparms_ref5_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AR\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"arparms", "ref5_ind", "ref5_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


############################################
# arparms ref6_code Customer User Prompts
######################################

FUNCTION combolist_arparms_ref6_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AR\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"arparms", "ref6_ind", "ref6_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


############################################
# arparms ref7_code Customer User Prompts
######################################

FUNCTION combolist_arparms_ref7_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AR\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"arparms", "ref7_ind", "ref7_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 




############################################
# arparms ref8_code Customer User Prompts
######################################

FUNCTION combolist_arparms_ref8_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1=l_wherestring,l_condition_group,p_condition_type,s variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AR\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"arparms", "ref8_ind", "ref8_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 







############################################
#stateinfo Statement Message dun_code dun_code all1_text
######################################

FUNCTION combolist_stateinfo_dun_code_all1_text(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"stateinfo", "dun_code", "all1_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

#stateinfo Statement Message dun_code dun_code all2_text
######################################

FUNCTION combolist_stateinfo_dun_code_all2_text(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"stateinfo", "dun_code", "all2_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

######################################
# AR Acounts Receive - Load Parameters loadparms  load_ind
FUNCTION combolist_loadparms_ar(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AR\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"loadparms", "load_ind", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


######################################
# AP Acounts Payable - Load Parameters loadparms  load_ind
FUNCTION combolist_loadparms_ap(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_wherestring = l_wherestring, " AND module_code = \'AP\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"loadparms", "load_ind", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


######################################
# cmpy_code company code
FUNCTION combolist_company(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " "-- " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"company", "cmpy_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



######################################
# offer_code offercode
FUNCTION combolist_offer_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"offersale", "offer_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

######################################
# labelhead label_code
FUNCTION combolist_labelheadcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"labelhead", "label_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

########################################
# transptype Transport Type ?
FUNCTION combolist_transptype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"transptype", "transp_type_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

########################################
# Product Department
FUNCTION combolist_kit(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"kithead", "kit_code", "kit_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



########################################
# Product Department
FUNCTION combolist_proddept(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND dept_ind = \'1\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"proddept", "dept_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

########################################
# Product Sub-Department
FUNCTION combolist_prodsubdept(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND dept_ind = \'2\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"proddept", "dept_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_waregrp(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"waregrp", "waregrp_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_cartarea(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"cartarea", "cart_area_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist1_glrepsubgrp(p_cb_field_name,p_glrepsubgrp_x_maingrp_code,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --report MAIN GROUP 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE p_glrepsubgrp_x_maingrp_code LIKE glrepsubgrp.maingrp_code 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' ", 
	#" AND glrepmaingrp.maingrp_code = \'", trim(p_glrepmaingrp_x_maingrp_code), "\' ",
	" AND glrepsubgrp.maingrp_code = \'", trim(p_glrepsubgrp_x_maingrp_code), "\' ", 
	" AND glrepsubgrp.maingrp_code = glrepmaingrp.maingrp_code " 

	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"glrepmaingrp", "maingrp_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_glrepsubgrp(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"glrepsubgrp", "group_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_glrepmaingrp(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --report MAIN GROUP 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"glrepmaingrp", "maingrp_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

#maingrp
FUNCTION combolist_maingrp(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --report MAIN GROUP 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"maingrp", "maingrp_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

#ingroup
FUNCTION combolist_ingroup(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --report MAIN GROUP 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"ingroup", "ingroup_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

#device_type
FUNCTION combolist_device_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	#LET l_whereString = " WHERE cmpy_code = \'", trim(getCurrentUser_cmpy_code()), "\' "

	CALL comboList_Flex(p_cb_field_name,"device_type", "device_type_id", "device_desc", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_debttype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"jmj_debttype", "debt_type_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_profile(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"kandooprofile", "profile_code", "profile_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_country(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	#LET l_whereString = " WHERE cmpy_code = \'", trim(getCurrentUser_cmpy_code()), "\' "
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"country", "country_code", "country_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

#dependency on country
FUNCTION combolist_state(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	#LET l_whereString = " WHERE cmpy_code = \'", trim(getCurrentUser_cmpy_code()), "\' "
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	IF p_condition_type IS NOT NULL THEN 
		IF db_country_pk_exists(ui_off,null,p_condition_type) THEN 
			LET l_wherestring = " WHERE country_code = '", trim(p_condition_type), "' " 
		END IF 
	END IF 

	CALL comboList_Flex(p_cb_field_name,"state", "state_code", "state_text_enu", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


# This function displays all the currencies that have been authorized to use for the current company
FUNCTION combolist_currency(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_whereString = " WHERE currency_code IN (SELECT currency_code FROM used_currency WHERE cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code), "' ) "
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"currency", "currency_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

# This function displays all the currencies in the currency table
FUNCTION combolist_currency_all(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"currency", "currency_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_location(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"location", "locn_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

# Note: requires company id cmpy_code as condition_type argument
FUNCTION combolist_location_cmpy(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(p_condition_type), "\' " 
	LET p_condition_type = NULL 

	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"location", "locn_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_notes(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"notes", "note_code", "note_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_glsummary(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"glsummary", "summary_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

#################################################################################
# ALL products / product codes / part_code
FUNCTION combolist_productcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"product", "part_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

#################################################################################
# ALL products / product codes / part_code
FUNCTION combolist_productcode_where_text(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	IF p_condition_type IS NOT NULL THEN
		LET l_wherestring = " WHERE ", trim(p_condition_type)  
		LET p_condition_type = NULL
	END IF

	CALL comboList_Flex(p_cb_field_name,"product", "part_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

--@@@@
#################################################################################
# ALL products / product codes / part_code
FUNCTION combolist_prodstatus_productcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE prodstatus.cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	#LET l_whereString = l_whereString, " AND status_ind in ('1','4') AND part_code =(SELECT part_code FROM prodstatus WHERE cmpy_code='MA' AND part_code=product.part_code AND ware_code='WLN' AND status_ind in('1','4'))"
	LET l_wherestring = l_wherestring, " AND product.part_code= prodstatus.part_code AND prodstatus.status_ind in ('1','4') " 

	#SELECT prodstatus.part_code, desc_text FROM prodstatus,product WHERE product.part_code= prodstatus.part_code AND prodstatus.cmpy_code = 'MA'  AND prodstatus.status_ind in ('1','4') ORDER BY prodstatus.part_code ASC

	CALL comboList_Flex(p_cb_field_name,"prodstatus,product", "prodstatus.part_code", "product.desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

#################################################################################
# products in a specific warehouse / product codes / part_code
FUNCTION combolist_prodstatus_productcode_in_warehouse(p_cb_field_name,p_warecode,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_warecode LIKE warehouse.ware_code
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE prodstatus.cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	LET l_whereString = l_whereString," AND prodstatus.ware_code = '",p_warecode,"' "
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	#LET l_whereString = l_whereString, " AND status_ind in ('1','4') AND part_code =(SELECT part_code FROM prodstatus WHERE cmpy_code='MA' AND part_code=product.part_code AND ware_code='WLN' AND status_ind in('1','4'))"
	LET l_wherestring = l_wherestring, " AND product.part_code= prodstatus.part_code AND prodstatus.status_ind in ('1','4') " 

	#SELECT prodstatus.part_code, desc_text FROM prodstatus,product WHERE product.part_code= prodstatus.part_code AND prodstatus.cmpy_code = 'MA'  AND prodstatus.status_ind in ('1','4') ORDER BY prodstatus.part_code ASC

	CALL comboList_Flex(p_cb_field_name,"prodstatus,product", "prodstatus.part_code", "product.desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION


################################################################
FUNCTION combolist_mastervendorcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD n 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"vendorgrp", "mast_vend_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_vendorcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD n 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"vendor", "vend_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 




FUNCTION combolist_vendortype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD n 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"vendortype", "type_code", "type_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 





FUNCTION combolist_flexcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"validflex", "flex_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_posstation(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --rpt_id rpthead.rpt_id 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"posstation", "station_code", "station_desc", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


{
      LET query_text = "SELECT * FROM validflex ",
                       "WHERE cmpy_code = \"",
                       glob_rec_kandoouser.cmpy_code,
                       "\" ",
                       "AND start_num = \"",
                       start_pos,
                       "\" ",
                       "AND ",
                       where_text clipped,
                       " ",
                       "ORDER BY flex_code"
}
{
#HuHo need TO think of some solution FOR additional lookup arguments based on variable VALUES

                                                        SELECT * INTO pr_batchhead.* FROM batchhead
            WHERE batchhead.cmpy_code  = glob_rec_kandoouser.cmpy_code
              AND batchhead.jour_code = pr_batchhead.jour_code
              AND batchhead.jour_num  = pr_batchhead.jour_num

FUNCTION comboList_journalNumCode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
  DEFINE p_cb_field_name      VARCHAR(25)   --form field name FOR the journalNum combo list field
	DEFINE p_variable SMALLINT	-- 0=first field IS variable 1= 2nd field IS variable
	DEFINE p_single SMALLINT	--0=variable AND label 1= variable = label
	DEFINE p_hint SMALLINT  --1 = show both VALUES in label
	DEFINE l_whereString STRING  --WHERE


	LET l_whereString = " WHERE cmpy_code = \'", trim(getCurrentUser_cmpy_code()), "\' AND batchhead.jour_num  = pr_batchhead.jour_num  ??"???

	CALL comboList_Flex(p_cb_field_name,"batchhead", "jour_num", "jour_num", l_whereString,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null)

END FUNCTION

}


FUNCTION combolist_rpt_id(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --rpt_id rpthead.rpt_id 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"rpthead", "rpt_id", "rpt_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 




FUNCTION combolist_rpttype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --rpt_id rpthead.rpt_id 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = NULL --" WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"rpttype", "rpttype_id", "rpttype_desc", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_rnd_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --rpt_id rpthead.rpt_id 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = NULL --" WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"rndcode", "rnd_code", "rnd_desc", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_rpt_desc_position(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --rpt_desc_position rptpos 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = NULL --" WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"rptpos", "rptpos_id", "rptpos_desc", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_sign_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --rpt_desc_position rptpos 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = NULL --" WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"signcode", "sign_code", "sign_desc", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_journalnum(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the journalnum combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	IF p_condition_type IS NULL THEN 
		LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	ELSE 
		LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND jour_code = \'", trim(p_condition_type), "\' " 
	END IF 

	--CALL ui.combobox.forname(p_cb_field_name).clear() 
	LET p_condition_type = NULL 
	CALL comboList_Flex(p_cb_field_name,"batchhead", "jour_num", "jour_num", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_salesmanager(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --sales manager 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"salesmgr", "mgr_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_salesarea(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --sales area 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"salearea", "area_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 





FUNCTION combolist_purchtype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --purchase type code 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"purchtype", "purchtype_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 




FUNCTION combolist_creditreason(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"credreas", "reason_code", "reason_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_coa_account_current(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the account combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 

	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING --account type category filter 
	DEFINE p_condition_type STRING --account type category filter 
	DEFINE p_add_null SMALLINT 

	DEFINE l_current_year_num LIKE coa.start_year_num 
	DEFINE l_current_period_num LIKE coa.start_period_num 

	LET l_condition_group = "COA_ACCOUNT_TYPE" 
	CALL db_period_what_period(getcurrentuser_cmpy_code(),today) RETURNING l_current_year_num, l_current_period_num 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' ",
	" AND is_nominalcode = 't' "  
	LET l_wherestring = l_wherestring, " AND start_year_num <= ", trim(l_current_year_num), " " 
	LET l_wherestring = l_wherestring, " AND end_year_num >= ", trim(l_current_year_num), " " 
	LET l_wherestring = l_wherestring, " AND start_period_num <= ", trim(l_current_period_num), " " 
	LET l_wherestring = l_wherestring, " AND end_period_num >= ", trim(l_current_period_num), " " 

--	LET l_wherestring = l_wherestring, " AND acct_code[1,7] = 'KAU-002'", " "  #KD-2119 comment waiting for KD-2025 fix


	--CALL ui.combobox.forname(p_cb_field_name).clear() 


	CALL comboList_Flex(p_cb_field_name,"coa", "acct_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_coa_sales_account_current(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the account combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	#DEFINE p_account_type_required CHAR --account type category filter 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	DEFINE l_current_year_num LIKE coa.start_year_num 
	DEFINE l_current_period_num LIKE coa.start_period_num 

	CALL db_period_what_period(getcurrentuser_cmpy_code(),today) RETURNING l_current_year_num, l_current_period_num
	
	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\'",
-- FIXME				" AND group_code='SALES' ",   -- #alch temporary workaround for KD-2302 
		" AND is_nominalcode = 't' " ,
						" AND ((start_year_num <= ", trim(l_current_year_num), " AND end_year_num >= ", trim(l_current_year_num) ," ) ",

						" OR ( start_year_num = ", trim(l_current_year_num), 
						" AND start_period_num <= ", trim(l_current_period_num), 
						" AND end_period_num >= ", trim(l_current_period_num), " ) ",

						" OR (end_year_num = ", trim(l_current_year_num), 
						" AND start_period_num <= ", trim(l_current_period_num), 
						" AND end_period_num >= ", trim(l_current_period_num), " )) "

--	LET l_wherestring = l_wherestring, " AND acct_code[1,7] = 'KAU-002'", " "  #KD-2119 comment waiting for KD-2025 fix
	CALL comboList_Flex(p_cb_field_name,"coa", "acct_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 
###########################################################################
# FUNCTION combolist_coa_bank_account_current(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
#
# BANK only COA - COA with BAAC (BANK) group code
###########################################################################
FUNCTION combolist_coa_bank_account_current(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the account combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	#DEFINE p_account_type_required CHAR --account type category filter 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	DEFINE l_current_year_num LIKE coa.start_year_num 
	DEFINE l_current_period_num LIKE coa.start_period_num 

	CALL db_period_what_period(getcurrentuser_cmpy_code(),today) RETURNING l_current_year_num, l_current_period_num
	
	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND group_code='", trim(COA_GROUP_CODE_BANK_BAAC), "' ",
	" AND is_nominalcode = 't' " 
	LET l_wherestring = l_wherestring, " AND start_year_num <= ", trim(l_current_year_num), " " 
	LET l_wherestring = l_wherestring, " AND end_year_num >= ", trim(l_current_year_num), " " 
	LET l_wherestring = l_wherestring, " AND start_period_num <= ", trim(l_current_period_num), " " 
	LET l_wherestring = l_wherestring, " AND end_period_num >= ", trim(l_current_period_num), " " 


--	LET l_wherestring = l_wherestring, " AND acct_code[1,7] = 'KAU-002'", " "  #KD-2119 comment waiting for KD-2025 fix

	CALL comboList_Flex(p_cb_field_name,"coa", "acct_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_coa_account(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the account combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	#DEFINE p_account_type_required CHAR --account type category filter 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	DEFINE l_current_year_num LIKE coa.start_year_num 
	DEFINE l_current_period_num LIKE coa.start_period_num 

	CALL db_period_what_period(getcurrentuser_cmpy_code(),today) RETURNING l_current_year_num, l_current_period_num 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' ",
	" AND is_nominalcode = 't' " 

	--LET l_wherestring = l_wherestring, " AND acct_code[1,7] = 'KAU-002'", " "  #KD-2119 comment waiting for KD-2025 fix

	CALL comboList_Flex(p_cb_field_name,"coa", "acct_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_category(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR combo list FIELD group_code 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"category", "cat_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_productgroup(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the combo list FIELD group_code 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"prodgrp", "prodgrp_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_groupcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the group_code / combo list FIELD group_code 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"groupinfo", "group_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_structure(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the seq_num / combo list FIELD seq_num 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND start_num > 0 AND (type_ind = \"S\" OR type_ind = \"C\" OR type_ind = \"L\")" --albo kd-1221 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"structure", "start_num", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_prodstructure_seq_num(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the seq_num / combo list FIELD seq_num 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"prodstructure", "seq_num", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_class_price_level_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the price_level_ind / class combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"class", "price_level_ind", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_class_ord_level_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the price_level_ind / class combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"class", "ord_level_ind", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_classcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the class_code / combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"class", "class_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_carrier(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the carrier_code / combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"carrier", "carrier_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_warehouse(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the warhouse_code / combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"warehouse", "ware_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_customer(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the customer_code / combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND delete_flag != 'Y' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 

	CALL comboList_Flex(p_cb_field_name,"customer", "cust_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_customer_all(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the customer_code / combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 
	LET l_condition_group = "CUSTOMER_DELETED"
	--LET p_condition_type = "MARK"  #Feature Request Anna
	CALL comboList_Flex(p_cb_field_name,"customer", "cust_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_holdreascode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the hold_code / combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 
	#Add an empty list item for "NOT on hold" Reason=None
	--CALL ui.ComboBox.ForName(p_cb_field_name).addItem(NULL,"Not on hold") 
	CALL comboList_Flex(p_cb_field_name,"holdreas", "hold_code", "reason_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 


END FUNCTION 

FUNCTION combolist_holdpaycode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the hold_code / combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	--CALL ui.combobox.forname(p_cb_field_name).clear() 
	#Add an empty list item for "NOT on hold" Reason=None
	WHENEVER ERROR CONTINUE
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(NULL,"Not on hold")
	WHENEVER ERROR STOP 
	CALL comboList_Flex(p_cb_field_name,"holdpay", "hold_code", "hold_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 


END FUNCTION 

FUNCTION combolist_termcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the term_code / combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"term", "term_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


#Sales Tax
FUNCTION combolist_tax_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #sales tax 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the tax_code / combo list FIELD tax 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"tax", "tax_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_salescondition(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --sales condition 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the cond_code / combolist_salescondition combo list FIELD condsale 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"condsale", "cond_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


#sale_code / salesperson combo list field
FUNCTION combolist_salesperson(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --salesperson sales person 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"salesperson", "sale_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


# terr_code
FUNCTION combolist_territory(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the territory combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"territory", "terr_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_customertype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) -- customer type code 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the customertype combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"customertype", "type_code", "type_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

#disbhead.disb_code
FUNCTION combolist_disbursementcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the disbursementcode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 
	#Display "comboList_DisbursementCode"
	#display l_whereString
	CALL comboList_Flex(p_cb_field_name,"disbhead", "disb_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 





FUNCTION combolist_uomcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the uomcod combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"uom", "uom_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_biccode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the biccode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " " -- " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"bic", "bic_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_bank(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the uomcod combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"bank", "bank_code", "name_acct_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_bankacctnum(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the uomcod combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"bank", "iban", "name_acct_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_banktype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the banktype combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " " -- " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"banktype", "type_code", "type_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_user(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the user combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' ", " AND passwd_ind != \'0\' " 

	CALL comboList_Flex(p_cb_field_name,"kandoouser", "sign_on_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

	#LET query_text = "SELECT * FROM kandoouser ",
	#               " WHERE passwd_ind != '0' ",
	#               "   AND ",where_text clipped," ",
	#               " ORDER BY sign_on_code"

END FUNCTION 

FUNCTION combolist_user_cmpy(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the user combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE user_cmpy.sign_on_code = kandoouser.sign_on_code ",
						" AND user_cmpy.cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"'"

	CALL comboList_Flex(p_cb_field_name,"user_cmpy,kandoouser", "user_cmpy.sign_on_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

	#LET query_text = "SELECT * FROM kandoouser ",
	#               " WHERE passwd_ind != '0' ",
	#               "   AND ",where_text clipped," ",
	#               " ORDER BY sign_on_code"

END FUNCTION 


FUNCTION combolist_journalcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the journalcode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"journal", "jour_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 






FUNCTION combolist_usercode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --entry_code entrycode sign_on_code 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the journalcode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	#LET l_whereString = " WHERE cmpy_code = \'", trim(getCurrentUser_cmpy_code()), "\' "

	CALL comboList_Flex(p_cb_field_name,"kandoouser", "sign_on_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 




FUNCTION combolist_col_item(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --col_item colitemcolid 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the journalcode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"colitemcolid", "rpt_id", "id_col_id", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_id_col_id(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --col_item col_item id_col_id 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the journalcode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"colitemcolid", "id_col_id", "rpt_id", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_line_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --line_code txtline 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the journalcode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"txtline", "line_code", "rpt_id", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_invoicenumvoucher(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"voucher", "vouch_code", "vend_code", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_invoicenumorgcustcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"invoicehead", "inv_num", "org_cust_code", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 

FUNCTION combolist_invoiceNumCustCode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"invoicehead", "inv_num", "cust_code", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_inv_num_by_customer(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 


	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND cust_code = '", trim(p_condition_type), "' " 

	CALL comboList_Flex(p_cb_field_name,"invoicehead", "inv_num", "inv_date", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 




####################################################################################################################################################
####################################################################################################################################################
####################################################################################################################################################
####################################################################################################################################################

###########################################################################################################
###########################################################################################################
# Lookups which require double key filter i.e. company AND customer id
###########################################################################################################
###########################################################################################################

######################################
# shipping_code ship_code
FUNCTION combolist_customership_double(p_cb_field_name,pcust_code,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE pcust_code LIKE customership.cust_code 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable OR LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' AND cust_code = \'", trim(pcust_code), "\' " 

	CALL comboList_Flex(p_cb_field_name,"customership", "ship_code", "name_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 


FUNCTION combolist_reportcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --entry_code entrycode sign_on_code 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the journalcode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	
	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	CALL comboList_Flex(p_cb_field_name,"reporthead", "report_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



FUNCTION combolist_cheque_rec_state_num(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --entry_code entrycode sign_on_code 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the journalcode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	
	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	IF p_condition_type IS NOT NULL THEN
		LET l_whereString =  l_whereString CLIPPED, " AND bank_code = \'", trim(p_condition_type), "\' AND rec_state_num IS NOT NULL"
	END IF

	CALL comboList_Flex(p_cb_field_name,"cheque", "rec_state_num", "vend_code", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 

END FUNCTION 



#LET query_text = "SELECT * FROM customership ",
#                  "WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
#                    "AND cust_code = '",pr_cust_code,"' ",
#                    "AND ",where_text clipped," ",
#                  "ORDER BY ship_code"




####################################################################################################################################################
####################################################################################################################################################
####################################################################################################################################################
####################################################################################################################################################
#Static Combo Items
################################################################
####################################################################################################################################################
####################################################################################################################################################
####################################################################################################################################################

FUNCTION set_combolist_array_addItem(p1,p2)
	DEFINE p1 STRING
	DEFINE p2 STRING
	DEFINE i SMALLINT
	
	LET i = modu_static_cb_arr.getLength() + 1
	
	LET modu_static_cb_arr[i,1] = trim(p1)
	LET modu_static_cb_arr[i,2] = trim(p2)

END FUNCTION

FUNCTION get_combolist_array()
	DEFINE l_arr DYNAMIC ARRAY WITH 2 DIMENSIONS OF STRING
	
	LET l_arr = modu_static_cb_arr
	CALL modu_static_cb_arr.clear()  #after get.. module scope array will be ereased
	RETURN l_arr
	
	
END FUNCTION
	
FUNCTION comboList_Static(p_cb_field_name,p_arr,p_add_null)
	DEFINE p_cb_field_name STRING
	DEFINE p_arr DYNAMIC ARRAY WITH 2 DIMENSIONS OF STRING
	DEFINE p_add_null SMALLINT
	DEFINE l_ui_cb ui.ComboBox 
	DEFINE i SMALLINT
	
	WHENEVER ERROR CONTINUE 

	LET l_ui_cb = ui.combobox.forname(p_cb_field_name)
	IF l_ui_cb IS NULL THEN
		ERROR "ComboBox ", trim(p_cb_field_name), " does not exist in form" #needs to be enabled again AFTER we have applied DB patch for state_code 
		RETURN NULL
	END IF
	
	CALL l_ui_cb.clear()
	CALL cb_object_add_null(l_ui_cb,p_add_null)
	
	FOR i = 1 TO p_arr.getLength()
		CALL l_ui_cb.addItem(p_arr[i,1],p_arr[i,2]) 	
	END FOR
	WHENEVER ERROR STOP
	 		
END FUNCTION

################################################################
####################################################################################################################################################
####################################################################################################################################################
####################################################################################################################################################


######################################################################
# FUNCTION comboList_prodinfo_info_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE product information indicator info_ind
######################################################################
FUNCTION combolist_prodinfo_info_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	DEFINE l_arr DYNAMIC ARRAY WITH 2 DIMENSIONS OF STRING
	DEFINE ret_count SMALLINT


	CALL set_combolist_array_addItem("1","Document")
	CALL set_combolist_array_addItem("2","Picture")
	CALL set_combolist_array_addItem("3","Specification")
	CALL set_combolist_array_addItem("4","URL")

	LET ret_count =  comboList_Static(p_cb_field_name,get_combolist_array(),p_add_null)
	RETURN ret_count 

{

	WHENEVER ERROR CONTINUE
	CALL combolist_add_null(p_cb_field_name,p_add_null) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Document") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Picture") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Specification") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","URL") 
	WHENEVER ERROR STOP

	
	RETURN 4 
}

END FUNCTION 


######################################################################
# FUNCTION comboList_billing_method(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE contract user prompt indicators
######################################################################
FUNCTION combolist_bankstatement_entry_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()
--	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("BC","Bank charges (DR)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("BD","Bank deposits (CR)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CH","Cheque payments (DR)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PA","Payments (DR)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("RE","Receipts (CR)" ) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("SC","Sundry credits (CR)" ) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("TI","Currency Transfer in (CR)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("TO","Currency Transfer out (DR)" ) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DC","Dishonoured cheques (DR)" ) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("EF","Direct Entry (eft's) (DR)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("ER","Rejected Direct entry (CR)" ) 
	WHENEVER ERROR STOP

	RETURN 11 

END FUNCTION 


######################################################################
# FUNCTION comboList_billing_method(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE contract user prompt indicators
######################################################################
FUNCTION combolist_kandoo_module_groups(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AR","Accounts Receivable") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("EO","Sales Order Processing") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("FA","Fixed Asets") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("GL","General Ledger") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_INVOICE_IN,"Inventory") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("JM","Job Management") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("SS","Subsription") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("LC","Shipment/Landed Costing") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("RE","Internal Requisition") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AP","Accounts Payable") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("QE","Sales Quotation") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PU","Purchasing") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("UT","Utilities") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("WO","Building Products Distribution") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CM","Contact Management") 
	WHENEVER ERROR STOP



	RETURN 14 

END FUNCTION 


######################################################################
# FUNCTION comboList_billing_method(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE contract user prompt indicators
######################################################################
FUNCTION combolist_billing_method(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("F","Fixed Price") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","Cost plus") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("T","Time and materials") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("R","Recurring") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 


{
######################################################################
# FUNCTION comboList_report_desc_position(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE contract user prompt indicators
######################################################################
FUNCTION comboList_report_desc_position(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
  DEFINE p_cb_field_name      VARCHAR(25)   --form field name
	DEFINE p_variable SMALLINT	-- 0=first field IS variable 1= 2nd field IS variable
	DEFINE p_sort SMALLINT  --0=Sort on first 1=Sort on 2nd
	DEFINE p_single SMALLINT	--0=variable AND label 1= variable = label
	DEFINE p_hint SMALLINT  --1 = show both VALUES in label
	DEFINE p_condition_type STRING
	DEFINE p_add_null SMALLINT

	CALL comboList_add_Null(p_cb_field_name,p_add_null)

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","Centred")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L","Left Justified")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("R","Right Justified")

	RETURN 3

END FUNCTION
}

######################################################################
# FUNCTION comboList_billing_method(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE contract user prompt indicators
######################################################################
FUNCTION combolist_billing_issues(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Summary") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Detail") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 

######################################################################
# FUNCTION comboList_contract_user_prompt_indicator(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE contract user prompt indicators
######################################################################
FUNCTION combolist_contract_user_prompt_indicator(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Contract Val. Prompt 1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Contract Val. Prompt 2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Contract Val. Prompt 3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Contract Val. Prompt 4") 
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","Contract Val. Prompt 5") #one part of the code refers to 1-5 the other 1-4 ... bloxxxx devxxxx
	WHENEVER ERROR STOP

	RETURN 5 

END FUNCTION 


######################################################################
# FUNCTION comboList_job_report_prompt_indicator(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE job_report_prompt_indicator
######################################################################
FUNCTION combolist_job_report_prompt_indicator(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Optional") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Required") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","No entry required") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


######################################################################
# FUNCTION comboList_env_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE passwd_ind CHAR(1) MATCHES[1,2,3]
######################################################################
FUNCTION combolist_env_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Envelope Code 1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Envelope Code 2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Envelope Code 3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Envelope Code 4") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 


######################################################################
# FUNCTION comboList_pay_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE passwd_ind CHAR(1) MATCHES[1,2,3]
######################################################################
FUNCTION combolist_pay_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Pay Code 1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Pay Code 2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Pay Code 3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Pay Code 4") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 



######################################################################
# FUNCTION comboList_rate_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE passwd_ind CHAR(1) MATCHES[1,2,3]
######################################################################
FUNCTION combolist_rate_code(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(NULL,"No Rate (NULL)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Rate Code 1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Rate Code 2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Rate Code 3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Rate Code 4") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 



######################################################################
# FUNCTION comboList_accessMode_passwd_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE passwd_ind CHAR(1) MATCHES[1,2,3]
######################################################################
FUNCTION combolist_accessmode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Account Enabled") 
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","2-Trace  ????")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Account Disabled") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


######################################################################
# FUNCTION comboList_accessMode_passwd_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE passwd_ind CHAR(1) MATCHES[1,2,3]
######################################################################
FUNCTION combolist_vouchertype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("G","General") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","Charge Thru Sale") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P","Purchase Order") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("J","Distribution to Job") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Shipment") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Order") 
	WHENEVER ERROR STOP

	RETURN 6 

END FUNCTION 

######################################################################
# FUNCTION comboList_passwd_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE passwd_ind CHAR(1) MATCHES[0,1,2]
######################################################################
FUNCTION combolist_passwd_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","0-Logout") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","1-Password Required") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","2-No Password Required") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


######################################################################
# FUNCTION comboList_memoPriority(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
# DEFINE memo_pri_ind CHAR(1)
######################################################################
FUNCTION combolist_memopriority(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","0-Important/Urgent") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","1-Standard Memo") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 

######################################################################
# FUNCTION comboList_securityLevel(p_cb_field_name)
# DEFINE security_ind CHAR(1)
######################################################################
FUNCTION combolist_securitylevel(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","1-Low") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("9","9-Low") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("a","Normal User (a)") 
	#	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("u","u-Medium")
	#	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("z","z-Medium")
	#	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","A-High")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("M","Module Admin (M)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Z","Administrator (Z)") 
	WHENEVER ERROR STOP

	RETURN 7 

END FUNCTION 



#abc method analysis product inventory control
FUNCTION combolist_product_analysis_abc(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","A-High Importance") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("B","B-Medium Importance") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","C-Low Importance") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 

#product STATUS
FUNCTION combolist_product_status(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Available") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","On Hold") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Deleted") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Stop Re-ORDER") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 


######################################




#inv_type invoice type

FUNCTION combolist_invoice_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Contract","Contract") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_JOB_JOB,TRAN_TYPE_JOB_JOB) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Gen/Invoice","Gen/Invoice") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Consolid","Consolid") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 
######################################


#Account age date -(1) last account aging -(2) today -(3) nominate
#pr_age_ind
#
FUNCTION combolist_account_age_date(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","last account aging") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","today") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","nominate") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 
######################################
#    Credit Type 1-AR 4-Adjustment 5-EO 7-Subscriptions
# cred_ind credit type
#
FUNCTION combolist_credit_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","AR (1)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Adjustment (4)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","EO (5)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("7","Subscriptions (7)") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 


######################################
#   Invoice generated by: 1 - IE, 2 - OE, 3 - JM OR 4 - Adjustment
# pickhead.con_status_ind
#
FUNCTION combolist_invoice_generated_by(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","IE") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","OE") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","JM") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Adjustment") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 

######################################
#  Consigned STATUS: (0) Picked - (1) Consigned - (9) Rejected
# pickhead.con_status_ind
#
FUNCTION combolist_consigned_status(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","Picked") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Consigned") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("9","Rejected") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 

######################################
# Picking STATUS: (0) Picked - (1) Invoiced - (9) Rejected
# pickhead.status_ind
#
FUNCTION combolist_picking_status(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","Picked") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Invoiced") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("9","Rejected") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 

######################################
# Picking STATUS: (0) Picked - (1) Shipped - (9) Rejected
# pickhead.status_ind
#
FUNCTION combolist_picking_status2(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","Picked") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Shipped") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("9","Rejected") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


######################################
# Charging Method -(1) per ORDER -(2) per kilogram
# charge_ind
#
FUNCTION combolist_charging_method(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","per Order") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","per Kilogram") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 




######################################
# (1) None -(2) Min.Limits -(3) Sold -(4) Bonus -(5) Check All
#
FUNCTION combolist_checkrule(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","None") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Min.Limits") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Sold") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Bonus") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","Check All") 
	WHENEVER ERROR STOP


	RETURN 5 

END FUNCTION 



######################################
#  Discount Rule. (1) Spec.Offer -(2) Sales Cond. -(3) Maximum
#
FUNCTION combolist_discount_rule(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Spec.Offer") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Sales Cond.") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Maximum") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 




######################################
#  Check type. -(1) Check by Quantity -(2) Check by Value
#
FUNCTION combolist_check_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Check by Quantity") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Check by Value") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 

######################################

FUNCTION combolist_warrantydays(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	CALL ui.combobox.forname(p_cb_field_name).clear()

	WHENEVER ERROR CONTINUE

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","None") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("182","1/2 Year") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("365","1 Year") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("720","2 Years") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1095","3 Years") 
	WHENEVER ERROR STOP


	RETURN 5 

END FUNCTION 


FUNCTION combolist_intervaltype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Daily") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Weekly") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Fortnightly") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Calendar Month") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6","Custom") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("7","Quarerly") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("8","Yearly") 
	WHENEVER ERROR STOP


	RETURN 7 

END FUNCTION 



FUNCTION combolist_reporting_level(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Vendor Type") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Vendor Code") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Transaction Detail") 
	WHENEVER ERROR STOP


	RETURN 3 

END FUNCTION 


FUNCTION combolist_bankformat(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","ISBN/BIC") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","US Format") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Australian Format") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Other/Unknown Bank Format") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 


FUNCTION combolist_transationcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	#INvoice, CAsh, VOucher, ADJust, DEPreciation, CRedit, CHeque, CLose
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AA","Add Line") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("GR","Goods Receipt") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("VO","voucher") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DP","Deprecation") 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AD","Adjust") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CH","Cheque") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CL","Close") 
	WHENEVER ERROR STOP


	RETURN 7 


END FUNCTION 




FUNCTION combolist_transationtype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	#INvoice, CAsh, VOucher, ADJust, DEPreciation, CRedit, CHeque, CLose
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_RECEIPT_CA,"Cash)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_INVOICE_IN,"Invoice") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_CREDIT_CR,"Credit") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DP","Deprecation") 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("VO","Voucher") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AD","Adjust") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CH","Cheque") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CL","Close") 
	WHENEVER ERROR STOP


	#used TO be
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_RECEIPT_CA,"CA (CA)")
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_INVOICE_IN,"IN (IN)")
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_CREDIT_CR,"CR (CR)")
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DP","DP (DP)")

	RETURN 8 


END FUNCTION 


FUNCTION combolist_transation_source_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	#INvoice, CAsh, VOucher, ADJust, DEPreciation, CRedit, CHeque, CLose
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CD","CD - Cash Deposit from AR") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CB","CB - Generated from Cash Book") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AP","AP - Cheque from AP") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AD","AD ?????? AD") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DP","DP - Cash Book Deposit") --gc1 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("SC","SC ?????? SC") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("BC","BC - Bank Charges") 
	WHENEVER ERROR STOP


	RETURN 7 


END FUNCTION 




FUNCTION combolist_batch_source_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	#INvoice, CAsh, VOucher, ADJust, DEPreciation, CRedit, CHeque, CLose
	#Learning batch head codes
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","A - Accounts Receivable ???") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","C - Cash Book/ Cash Payments ???") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("G","G - General Ledger") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P","P - Accounts Payable ???") 
	WHENEVER ERROR STOP


	RETURN 4 


END FUNCTION 




FUNCTION combolist_transationtypeall(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("ADJ","Stock Adjustment/General Journal/Stock Export") --inventory / gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("BC","Bank Charge") --cash book 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_RECEIPT_CA,"Cash Receipt") --ar 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CB","Cash Book balance/deposit") --cash book 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CH","Cheque / Cheque Discount") --ap 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CL","Year/Period Closing") --gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("COS","Cost of Goods Sold / (suspense postings)") --inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_CREDIT_CR,"Credit Note") --ar 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AD","Asset Depreciation") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DM","Debit Memo") -- ap 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("EXA","Currency Exchange Variance") -- ar 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("EXG","Currency Exchange Variance") -- gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("EXP","Currency Exchange Variance") -- ap 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("GA","Goods Receipt Adjustment") -- purchasing 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("GR","Goods Receipt") -- purchasing 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_INVOICE_IN,"Invoices") -- ar 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("ISS","Inventory Stock Issue") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CO","Job Management Cost of Sales") -- ar 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("JMI","Job Management Stock Issue") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("REC","Inventory Receipt") -- inventory 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("ML","Multi-Ledger Balancing") -- gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CLS","Inventory Reclassification") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PAY","External Payroll Load") -- gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PO","Purchasing Commitment") -- purchasing 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("TRF","Stock Transfer b/t warehouses") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("VO","Voucher/JM Voucher Distribution") -- ap / jm 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("VP","Voucher Payment of Purchase Order") -- purchasing 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Wholesale tax claim") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AA","Asset Addition") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AS","Asset Sale") -- fa 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AV","Asset Revaluation") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AR","Asset Retirement") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AT","Asset Transfer") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AJ","Asset Adjustment") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("REC","Shipment Receipts") -- lc 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DEP","GL Asset Depreciation") -- gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PU","JM Purchase Order Distribution") -- jm 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DB","JM Debit Distribution") -- jm 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AD","Job Management Adjustment") -- jm 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("RE","Resource Allocation") -- jm 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("TS","Time Sheet Entry") -- jm 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("IS","JM Issues") -- jm 
	WHENEVER ERROR STOP

	RETURN 42 

END FUNCTION 




FUNCTION combolist_transationtypegl(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("ADJ","Stock Adjustment/General Journal/Stock Export") --gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CL","Year/Period Closing") --gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("EXG","Currency Exchange Variance") -- gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("ML","Multi-Ledger Balancing") -- gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PAY","External Payroll Load") -- gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DEP","GL Asset Depreciation") -- gl 
	WHENEVER ERROR STOP

	RETURN 6 

END FUNCTION 


FUNCTION combolist_transationtypecb(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("BC","Bank Charge") --cash book 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CB","Cash Book balance/deposit") --cash book 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 



FUNCTION combolist_transationtypear(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_RECEIPT_CA,"Cash Receipt") --ar 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_CREDIT_CR,"Credit Note") --ar 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("EXA","Currency Exchange Variance") -- ar 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_INVOICE_IN,"Invoices") -- ar 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CO","Job Management Cost of Sales") -- ar 
	WHENEVER ERROR STOP

	RETURN 5 

END FUNCTION 





FUNCTION combolist_transationtypeap(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CH","Cheque / Cheque Discount") --ap 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("EXP","Currency Exchange Variance") -- ap 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("VO","Voucher/JM Voucher Distribution") -- ap / jm 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 



FUNCTION combolist_transationtypeiv(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("ADJ","Stock Adjustment/General Journal/Stock Export") --inventory /gl 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("COS","Cost of Goods Sold / (suspense postings)") --inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("ISS","Inventory Stock Issue") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("JMI","Job Management Stock Issue") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("REC","Inventory Receipt") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CLS","Inventory Reclassification") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("TRF","Stock Transfer b/t warehouses") -- inventory 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Wholesale tax claim") -- inventory 
	WHENEVER ERROR STOP

	RETURN 8 

END FUNCTION 


FUNCTION combolist_transationtypefa(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AD","Asset Depreciation") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AA","Asset Addition") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AS","Asset Sale") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AV","Asset Revaluation") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AR","Asset Retirement") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AT","Asset Transfer") -- fa 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("AJ","Asset Adjustment") -- fa 
	WHENEVER ERROR STOP

	RETURN 7 

END FUNCTION 



FUNCTION combolist_transationtypepu(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("GA","Goods Receipt Adjustment") -- purchasing 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("GR","Goods Receipt") -- purchasing 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PO","Purchasing Commitment") -- purchasing 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("VP","Voucher Payment of Purchase Order") -- purchasing 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 




FUNCTION combolist_reportinglevel(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Department") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Main Grp") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Product Grp") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Product") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 





FUNCTION combolist_reportprintlevel(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Detailed") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Detailed AND Summary") 
	WHENEVER ERROR STOP

	RETURN 2 


END FUNCTION 

FUNCTION combolist_report_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --gr_report_type --0 - standard report, 1 - nominated conversion rate, 2 - foreign currency 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","Standard Report") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Nominated Conversion Rate") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Foreign Currency") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 

######################################
# Report Type: 1=Both, 2=Corporate Only, 3=Orignating Only
# pr_print_sel
FUNCTION combolist_report_type2(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Both") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Corporate Only") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Orignating Only") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 

######################################
# Report Type: (S)ummary-enter year/periods, (D)etail-all periods, (B)oth
# pr_print_sel
FUNCTION combolist_report_type3(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Summary-enter year/periods") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("D","Detail-all periods") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("B","Both") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


FUNCTION combolist_report_type_detailed(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --detailed_rpt -- PRINT a c=consolidated OR d=detailed REPORT 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","Consolidated Report") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("D","Detailed Report") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_reportorder(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Customer Code") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Customer Name") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","State") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Postcode") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 



FUNCTION combolist_customerreportorder(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","Alphabetic") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","Customer Code") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 




FUNCTION combolist_cogs(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Weighted Average") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("F","Fifo") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L","Lifo") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


FUNCTION combolist_record_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","A-Transaction Record Type A ???") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("B","B-Transaction Record Type A ???") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","C-Transaction Record Type A ???") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 

FUNCTION combolist_imprest_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","N - Imprest Indicator ???? list range unknown") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y","Y - Imprest Indicator ???? list range unknown") 
	WHENEVER ERROR STOP


	RETURN 3 

END FUNCTION 


FUNCTION combolist_warehousepartstatus(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Available") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","On Hold") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Deleted") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Re-ORDER") 
	WHENEVER ERROR STOP


	RETURN 4 

END FUNCTION 

FUNCTION combolist_purchstatus(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("O","Outstanding") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P","Partial") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","Complete") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


FUNCTION combolist_strategy_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Match by Document Reference AND Amount") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Match by Document Reference only") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Apply only if Debit IS less than OR equal TO Outstanding Amount") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Apply any outstanding") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 

FUNCTION combolist_allocation_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("R","Bill amount (R)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","Cost (C)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Q","Quantity (Q)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("B","Bill & Cost (B)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","All amounts (A)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","None resource (N)") 
	WHENEVER ERROR STOP

	RETURN 6 

END FUNCTION 


# Found full record table apaudit which uses them also BUT I found no lookup/foreign key table in the db
FUNCTION combolist_trantype_ind(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #toolTip="CH - Cheque, DB - Debit, VO - Voucher, TF - Transfer" 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CH","Cheque (CH)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DB","Debit (DB)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("VO","Voucher (VO)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("TF","Transfer (TF)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("VD","VD ?? (VD)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CC","Credit Card (CC)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PP","Credit Card (PP)") 
	WHENEVER ERROR STOP

	RETURN 7 

END FUNCTION 


FUNCTION combolist_price_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","For selected customers (1)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","For all customers (2)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","For selected customers (3)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","For all customers (4)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","For selected customers (5)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6","For all customers (6)") 
	WHENEVER ERROR STOP

	RETURN 6 

END FUNCTION 


FUNCTION combolist_line_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #ref_ind #9523 enter line type (q)uantity / (v)alue 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Q","(Q)uantity") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("V","(V)alue") 
	WHENEVER ERROR CONTINUE

	RETURN 2 

END FUNCTION 



FUNCTION combolist_write_file_path_default(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --y=offset column, n=own COLUMN 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/write/folder1","data/write/folder1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/write/folder2","data/write/folder2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/write/folder3","data/write/folder3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/write/folder4","data/write/folder4") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/write/folder5","data/write/folder5") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/write/payroll","data/read/payroll") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/write/payment","data/read/payment") 
	WHENEVER ERROR STOP

	RETURN 6 

END FUNCTION 


FUNCTION combolist_read_file_path_default(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --y=offset column, n=own COLUMN 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/read/ap_load","data/read/ap_load") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/read/folder1","data/read/folder1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/read/folder2","data/read/folder2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/read/folder3","data/read/folder3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/read/folder4","data/read/folder4") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/read/folder5","data/read/folder5") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/read/payment","data/read/payment") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/read/payroll","data/read/payroll") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("data/read/vendor" ,"data/read/vendor") 
	WHENEVER ERROR STOP

	RETURN 9 

END FUNCTION 

FUNCTION combolist_device_type_indicator(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --y=offset column, n=own COLUMN 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Printer (1)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Terminal (2)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Other (3)") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 



# Method “P”
# The amount of sales tax IS dictated by the tax Percentage associated with the Product.
#
# Method “D”
# The amount of sales tax IS dictated by the (Dollar) tax amount associated with the Product.
#
# Method “T”
# The amount of sales tax IS a flat percentage of the Transaction Total (ie. invoice OR voucher) based on the Customer’s (OR Vendor’s) tax rate.
#
# Method “N”
# The amount of (Net) sales tax IS calculated by applying the Customer’s (OR Vendor’s) tax rate TO each Product line in a transaction,
# (which may result in a difference compared TO the Total tax method due TO the rounding of each line amount).
#
# Method “I”
# This IS used TO identify customers, vendors, OR products whose prices are Inclusive of tax.
# Whether OR NOT tax IS calculated depends on its combination with other methods.
#
# Method “X”
# This IS used TO identify customers, vendors, OR products whose prices are Exclusive of tax.
# Tax IS NOT added (but may in some circumstances be deducted).
#
# Method “W”
# This IS used TO identify customers, vendors, AND products that are subject TO tax where the tax IS collected at the last wholesale transaction.
# Wholesale tax IS calculated at the point of goods receipt entry (for vendors AND stocked items with tax type “W”) AND posted TO a tax payable account.
# The tax IS then recalculated when posting the Cost of Goods sold for invoices AND credits,
# (for customers AND stocked items with tax type “W”), AND posted TO a tax claimable account.
# The amount of tax IS calculated FROM the percentage associated with the tax code stored on the product STATUS record.
#
# The tax rate IS primarily determined by the Customer’s (OR Vendor’s) method.
# However, in certain situations (defined below) the Product method will modify OR overrule this.
# There are a number of different tax regimes supported by KandooERP.  These are listed below together with suggestions on how Tax
# Codes should be SET up TO implement them (however please refer TO the AR Tax Calculation Summary for the definitive rules).
FUNCTION combolist_tax_calculation_method(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --y=offset column, n=own COLUMN 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P","Product Sales Tax") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("D","Dollar Product Sales Tax") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","Customers Sales Tax per Line") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("T","Customers Sales Tax - Flat Transaction Total") 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("X","Price excluding Tax (Exempt)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("I","Price inclusive Tax") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Wholesale Tax")
	#Following options exist in the code BUT are NOT DOCUMENTED
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("E","Export Sale Tax Exempt")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("H","Withholding Tax")	
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("M","Importation Purchase(See 'P')")	

	
	 
	WHENEVER ERROR STOP

	RETURN 7 

END FUNCTION 

FUNCTION combolist_validation(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --y=offset column, n=own COLUMN 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Entry Optional - No Validation") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Entry Mandatory - No Validation") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Entry Optional - Validation") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Entry Mandatory - Validation") 
	WHENEVER ERROR STOP

	RETURN 4 




END FUNCTION 


FUNCTION combolist_expected_sign(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --the expected sign OF the line. valid signs are (+,-). expected_sign 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("+","+") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("-","-") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_print_in_offset(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --y=offset column, n=own COLUMN 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y","Offset COLUMN (Y)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","Own COLUMN (N)") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_print_zero_values(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --y=print all zero values, n=never print, o=only PRINT non-zero --always_print_line --y=print all, n=never print, o=only non-zeros 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y","Print all Zero VALUES (Y)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","Never Print (N)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("O","Only PRINT Non-zero (O)") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 

#----------------------------------- Budget Category / Group
FUNCTION choose_budget_number(parg) 
	DEFINE f_field,parg SMALLINT 
	IF (parg >= 1) AND (parg <= 6) THEN 
		LET f_field = parg 
	ELSE 
		LET f_field = 1 --default=1 
	END IF 

	OPEN WINDOW wchoosedialog with FORM "form/lib_tool_choose_combo" 
	CALL displaymoduletitle(NULL) #"Choose Budget Number" 
	DISPLAY "Choose Budget No." TO header_text 
	DISPLAY "Budget No." TO lb_label 
	DISPLAY "lib_tool_choose_combo" TO lbFormName 
	CALL combolist_budg_num("f_field", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT)	 

	INPUT BY NAME f_field WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

	IF int_flag THEN 
		LET int_flag = false 
		LET f_field = 1 
	END IF 

	CLOSE WINDOW wchoosedialog 

	RETURN f_field 
END FUNCTION 

FUNCTION combolist_budg_num(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --budg_num 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Budget Number 1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Budget Number 2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Budget Number 3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Budget Number 4") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","Budget Number 5") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6","Budget Number 6") 
	WHENEVER ERROR STOP

	RETURN 6 

END FUNCTION 



#who the f... did this ? and added it here without a comment etc ? yes, HuHo is asking
FUNCTION choose_budget_group(parg) 
	DEFINE f_field,parg SMALLINT 
	IF parg = 0 OR parg = 1 THEN 
		LET f_field = parg 
	ELSE 
		LET f_field = 0 --default=1 
	END IF 

	OPEN WINDOW wchoosedialog with FORM "form/lib_tool_choose_combo" 
	CALL displaymoduletitle(NULL) #"Choose Budget Group Number" 
	DISPLAY "Choose Budget No." TO header_text 
	DISPLAY "Budget No." TO lb_label 
	DISPLAY "lib_tool_choose_combo" TO lbFormName 	CALL combolist_budg_num("f_field", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT)	 

	INPUT BY NAME f_field WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

	IF int_flag THEN 
		LET int_flag = false 
		LET f_field = 0 
	END IF 

	CLOSE WINDOW wchoosedialog 

	RETURN f_field 
END FUNCTION 




FUNCTION combolist_budg_grp(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --budg_num 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","Budget Group Number 1 - 4") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Budget Group Number 1 - 6") 
	WHENEVER ERROR STOP


	RETURN 2 

END FUNCTION 





#----------------- Funding Type -----------------------------------------------------------------
FUNCTION combolist_fund_type_ind_v1(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CAP","Capital Items") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CAY","CAY") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CAT","CAT") 
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("???","These combo list VALUES need researching... (???)")
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


FUNCTION combolist_repcmdcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A1","A1 (A1)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A2","A2 (A2)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A3","A3 (A3)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A4","A4 (A4)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A5","A5 (A5)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A6","A6 (A6)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CB","CB (CB)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CC","CC (CC)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("CJ","CJ (CJ)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DR","DR (DR)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(TRAN_TYPE_INVOICE_IN,"IN (IN)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("IP","IP (IP)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("IY","IY (IY)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("LA","LA (LA)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("LB","LB (LB)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("LP","LP (LP)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("LY","LY (LY)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L1","L1 (L1)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L2","L2 (L2)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L3","L3 (L3)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L4","L4 (L4)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L5","L5 (L5)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L6","L6 (L6)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PA","PA (PA)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PG","PG (PG)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PR","PR (PR)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("PS","PS (PS)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P1","P1 (P1)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P2","P2 (P2)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P3","P3 (P3)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P4","P4 (P4)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P5","P5 (P5)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P6","P6 (P6)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("RP","RP (RP)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("RY","RY (RY)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("SA","SA (SA)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("SN","SN (SN)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("SO","SO (SO)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("V1","V1 (V1)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("V2","V2 (V2)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("V3","V3 (V3)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("V4","V4 (V4)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("V5","V5 (V5)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("V6","V6 (V6)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("YA","YA (YA)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("YR","YR (YR)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("YS","YS (YS)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y1","Y1 (Y1)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y2","Y2 (Y2)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y3","Y3 (Y3)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y4","Y4 (Y4)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y5","Y5 (Y5)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y6","Y6 (Y6)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("U1","U1 (U1)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("U2","U2 (U2)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("U3","U3 (U3)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("U4","U4 (U4)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("U5","U5 (U5)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("U6","U6 (U6)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("%","% (%)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("+","+ (+)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("-","- (-)") 
	WHENEVER ERROR STOP


	RETURN 70 

END FUNCTION 



#pay_type
FUNCTION combolist_payment_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) #toolTip="CH - Cheque, DB - Debit, VO - Voucher, TF - Transfer" 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(PAYMENT_TYPE_CASH_C,"Cash Payment") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(PAYMENT_TYPE_CHEQUE_Q,"Cheque") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(PAYMENT_TYPE_CC_P,"Credit Card") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(PAYMENT_TYPE_ORDER_O,"Order Payment") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 


FUNCTION combolist_paymentmethod(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Invoice") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","COD - Cash on delivery") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Invoice/COD") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Direct Debit") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","CBD - Cash before delivery") 
	WHENEVER ERROR STOP

	RETURN 5 

END FUNCTION 

FUNCTION combolist_paymentmethod2(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","auto/manual cheques (1)") 
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","????? (2)")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","EFT payments (3)") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 

# card type card_type
FUNCTION combolist_card_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("V","VISA") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("M","MASTERCARD") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("B","BANKCARD") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","AMEX") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("D","DINERS CLUB") 
	WHENEVER ERROR STOP

	RETURN 5 

END FUNCTION 


FUNCTION combolist_paymentterm(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C",kandooword("term.day_date_ind","C")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("D",kandooword("term.day_date_ind","D")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("T",kandooword("term.day_date_ind","T")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W",kandooword("term.day_date_ind","W")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1",kandooword("term.day_date_ind","1")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2",kandooword("term.day_date_ind","2")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3",kandooword("term.day_date_ind","3")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4",kandooword("term.day_date_ind","4")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5",kandooword("term.day_date_ind","5")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6",kandooword("term.day_date_ind","6")) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("7",kandooword("term.day_date_ind","7")) 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 
{
        WHEN "1"  ## Cut off date
            LET pa_payment_menu[i].option_num = "C"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","C")
         WHEN "2"  ## No. of days TO pay
            LET pa_payment_menu[i].option_num = "D"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","D")
         WHEN "3"  ## Date of next month TO pay
            LET pa_payment_menu[i].option_num = "T"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","T")
         WHEN "4"  ## Working date of next month
            LET pa_payment_menu[i].option_num = "W"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","W")
         WHEN "5"  ## Due Sunday
            LET pa_payment_menu[i].option_num = "1"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","1")
         WHEN "6"  ## Due Monday
            LET pa_payment_menu[i].option_num = "2"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","2")
         WHEN "7"  ## Due Tuesday
            LET pa_payment_menu[i].option_num = "3"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","3")
         WHEN "8"  ## Due Wednesday
            LET pa_payment_menu[i].option_num = "4"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","4")
         WHEN "9"  ## Due Thursday
            LET pa_payment_menu[i].option_num = "5"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","5")
         WHEN "10"  ## Due Friday
            LET pa_payment_menu[i].option_num = "6"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","6")
         WHEN "11"  ## Due Saturday
            LET pa_payment_menu[i].option_num = "7"
            LET pa_payment_menu[i].option_text= kandooword("term.day_date_ind","7")

}
FUNCTION combolist_contramethod(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","None") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Taxed") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Non-Taxed") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 



FUNCTION combolist_year(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	#	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2025","2025")
	#	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2024","2024")
	#	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2023","2023")
	#	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2022","2022")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2021","2021")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2020","2020") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2019","2019") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2018","2018")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2017","2017")
	#	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2016","2016")
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 



FUNCTION combolist_year_from_period(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	LET l_wherestring = " WHERE cmpy_code = \'", trim(getcurrentuser_cmpy_code()), "\' " 

	LET p_condition_type = NULL  
	CALL comboList_Flex(p_cb_field_name,"period", "year_num", "year_num", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 
	WHENEVER ERROR STOP

END FUNCTION 



FUNCTION combolist_period_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --period_type --enter period type - (o)ffset value OR (s)pecific period. 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("O","Offset Value") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Specific Period") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_year_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --year_type --enter year type - (o)ffset value OR (s)pecific year. 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("O","Offset Value") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Specific Year") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_printignorezeroaccounts(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y","Print Zero Accounts") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","Ignore Zero Accounts") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_actualspreclose(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","Actuals") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P","Preclose") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_yearperiod(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y","Year") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P","Period TO date") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_yesno(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y","Yes") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","No") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_exchangetype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("B","Buy rate") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Sell rate") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("U","Budget rate") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 



FUNCTION combolist_seltype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Segment") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("R","Range") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("M","Matches") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 

####################################################
# Note, there is some strange implementation
# 1. DepositType is in some variables char(1) and in the main record variable (AND DB) char(2)
# 2. DepositType is in the char(1) assigned
# D or S (Deposit or Sundry)
# in the CHAR(2) / DATABASE
# BC Bank Charges
# SC Sundry Credit
# DP Deposit

#				WHEN l_bk_type = "S"
#					LET l_rec_banking.bk_type = "SC"
#					LET l_rec_banking.bk_desc = "Sundry credit"
#				WHEN l_bk_type = "D"
#					LET l_rec_banking.bk_type = "DP"
#					LET l_rec_banking.bk_desc = "Deposit"
#
# on the form level, we have char(1) and this comment text
# toolTip=" Type of Deposit - (D)eposit - (S)undry Credit"
#
####################################################

FUNCTION combolist_deposittype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	#Keep this in case of problems
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("SC","Sundry credit")
	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("DP","Deposit")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("D","Deposit") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Sundry") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 

FUNCTION combolist_executionmode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Interactive") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Unattended") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 



FUNCTION combolist_salespersontype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --salesperson type 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Pseudo salesentity") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Primary salesperson") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Normal salesperson") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 






FUNCTION combolist_bankstatementtype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("O","Open Item") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("B","Balance Forward") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","None") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Weekly") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 

FUNCTION combolist_expensetype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --the type a-asset l-liability i-income e-expense n-net worth --type_ind 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("G","General Expenses") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P","Purchase Orders") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("J","Job Management") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","Accounts Receivable Charge Through Sales") 
	--CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","LC") 
	WHENEVER ERROR STOP

	RETURN 5 

END FUNCTION 

#Usual method FOR dissecting expenses: A=AR, G=GL, J=JM, P=PU, S=LC

FUNCTION combolist_coa_accounttype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","Asset") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L","Liability") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("I","Income") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("E","Expense") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","Net Worth") 
	WHENEVER ERROR STOP

	RETURN 5 

END FUNCTION 

{FUNCTION comboList_coa_accountType(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
  DEFINE p_cb_field_name      VARCHAR(25)   --form field name
	DEFINE p_variable SMALLINT	-- 0=first field IS variable 1= 2nd field IS variable
	DEFINE p_single SMALLINT	--0=variable AND label 1= variable = label
	DEFINE p_hint SMALLINT  --1 = show both VALUES in label

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("E","Expense (E)")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("I","Income (I)")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("X","xxxx (X)")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y","yyyyy (Y)")
	RETURN 2

END FUNCTION
}

FUNCTION combolist_internetaccess(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level --freight rate level FOR this shipping address - (1) -&gt; (9) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","None") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Inquiry Only") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Order AND Inquiry") 
	WHENEVER ERROR STOP


	RETURN 3 

END FUNCTION 


FUNCTION combolist_freightrate(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level --freight rate level FOR this shipping address - (1) -&gt; (9) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","0 - Freight Rate 0") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","1 - Freight Rate 1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","2 - Freight Rate 2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","3 - Freight Rate 3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","4 - Freight Rate 4") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","5 - Freight Rate 5") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6","6 - Freight Rate 6") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("7","7 - Freight Rate 7") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("8","8 - Freight Rate 8") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("9","9 - Freight Rate 9") 
	WHENEVER ERROR STOP

	RETURN 9 

END FUNCTION 


FUNCTION combolist_invoiceaddress(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Statement") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Shipping") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 







FUNCTION combolist_roundingrule(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","Round Nearest") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Always Round Up") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Always Round Down") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


# 0 - Not applicable, 1 - cents, 2 - rounded down, 3 - rounded up
FUNCTION combolist_taxindicator(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","Tax is NOT applicable") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Round to 2 decimals") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Rounded down to whole number") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Rounded up (no decimals)") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 


FUNCTION combolist_defaultcosttype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("F","Foreign Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L","Latest Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Standard Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Weighted Cost") 
	WHENEVER ERROR STOP



	RETURN 4 

END FUNCTION 


FUNCTION combolist_costtype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Standard Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Weighted Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","Actual Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("F","Foreign Cost") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 



FUNCTION combolist_pricetype(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L","List Price") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","Standard Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Weighted Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","Actual Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("F","Foreign Cost") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 


FUNCTION combolist_pricelevel(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","Cost") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L","List") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","4") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","5") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6","6") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("7","7") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("8","8") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("9","9") 
	WHENEVER ERROR STOP

	RETURN 11 

END FUNCTION 

FUNCTION combolist_pricelevel2(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) --inv_level price_level 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","Cost")
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L","List") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","4") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","5") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6","6") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("7","7") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("8","8") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("9","9") 
	WHENEVER ERROR STOP

	RETURN 10 

END FUNCTION 


FUNCTION combolist_modules(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("A","A (A)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("B","B (B)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("C","C (C)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("D","D (D)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("E","E (E)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("F","F (F)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("G","G (G)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("H","H (H)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("I","I (I)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("J","J (J)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("K","K (K)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("L","L (L)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("M","M (M)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","N (N)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("O","O (O)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P","P (P)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Q","Q (Q)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("R","R (R)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("S","S (S)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("T","T (T)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("U","U (U)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("V","V (V)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","W (W)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("X","X (X)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Y","Y (Y)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("Z","Z (Z)") 
	WHENEVER ERROR STOP


	RETURN 26 

END FUNCTION 


FUNCTION combolist_disbursementtype2(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(DISBURSE_TYPE_CLOSING_BALANCE_1,"Closing Balance") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(DISBURSE_TYPE_PERIOD_MOVEMENT_2,"Period Movement") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 


FUNCTION combolist_disbursementtype3(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(DISBURSE_TYPE_CLOSING_BALANCE_1,"Closing Balance") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(DISBURSE_TYPE_PERIOD_MOVEMENT_2,"Period Movement") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(DISBURSE_TYPE_TRANS_AMOUNT_3,"Trans. Amount") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 

#------------------------------------------------------------------------
# FUNCTION combolist_disburse_cdb_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
#
#	#disbhead.dr_cr_ind / Disburse Credit,Debit or Both
#	CONSTANT DISBURSE_CDB_CREDIT_1 SMALLINT = 1
#	CONSTANT DISBURSE_CDB_DEBIT_2 SMALLINT = 2
#	CONSTANT DISBURSE_CDB_BOTH_3 SMALLINT = 3
#	
#------------------------------------------------------------------------
FUNCTION combolist_disburse_cdb_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(DISBURSE_CDB_CREDIT_1 ,"Disburse Credits Only") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(DISBURSE_CDB_DEBIT_2 ,"Disburse Debits Only") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem(DISBURSE_CDB_BOTH_3 ,"Both") 

	RETURN 3 

END FUNCTION 
#------------------------------------------------------------------------
# END FUNCTION combolist_disburse_cdb_type(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
#------------------------------------------------------------------------

FUNCTION combolist_creditdebit(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Credit Amounts Only") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Debit Amounts Only") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Both") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 




FUNCTION combolist_budgetcode(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Budget 1") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Budget 2") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Budget 3") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Budget 4") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","Budget 5") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6","Budget 6") 
	WHENEVER ERROR STOP

	RETURN 6 

END FUNCTION 





FUNCTION combolist_payrollsourceindicator(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Lattice") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Micropay Current") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Micropay Month TO Date") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Micropay Year TO Date") 
	WHENEVER ERROR STOP

	RETURN 4 

END FUNCTION 


FUNCTION combolist_bankformatindicatorstatement(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) -- eft_format_ind 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Anz") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","NAB") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","Westpac") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


FUNCTION combolist_bankformatindicatoretf(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Anz") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","NAB/Westpac") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 

FUNCTION combolist_transationnumbering(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Manually Entered") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Sequentially Allocated") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Account Segment Prefixed") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","Program Allocated") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("E","Exit") 
	WHENEVER ERROR STOP

	RETURN 5 

END FUNCTION 


FUNCTION combolist_extfile1(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","Print Cheques/remittances") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","External I/face") 
	WHENEVER ERROR STOP

	RETURN 2 

END FUNCTION 

FUNCTION combolist_repprint1(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("0","Don't Print") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","Print Once") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Always Print") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


FUNCTION combolist_displaystyle(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","$100.00 / ($100.00)") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","$100.00 DR / $100.00 CR") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","$100.00 / -$100.00") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 





FUNCTION combolist_messageaction(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","1-DISPLAY on form lines 1 & 2. :No window") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","2-DISPLAY & sleep 3 seconds. :No window") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","3-DISPLAY & 'Any Key TO Cont..' :No window") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","4-DISPLAY & prompt 'Supply|Choices' window") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","5-DISPLAY & sleep 10 seconds. :With window") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6","6-WARNING: Requiring user acknowledgement ") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("7","7-DISPLAY & 'Any Key TO Cont.':With window") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("8","8-DISPLAY & prompt (Y)es/(N)o.:With window") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("9","9-DISPLAY on error line with warning bell.") 
	WHENEVER ERROR STOP

	RETURN 26 

END FUNCTION 

FUNCTION combolist_formattext(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 

	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL combolist_add_null(p_cb_field_name,p_add_null) 

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","1-DISPLAY <VALUE> AT start of first line. ") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","2-DISPLAY <VALUE> AT END of first line. ") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","3-DISPLAY <VALUE> AT start of second line.") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("4","4-DISPLAY <VALUE> AT END of second line.") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("5","5-DISPLAY & sleep 10 seconds. :With window") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("6","6-No Format allocated") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("7","7-No Format allocated") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("8","8-No Format allocated") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("9","9-DISPLAY <VALUE> best fit. (append lines)") 
	WHENEVER ERROR STOP

	RETURN 26 

END FUNCTION 

FUNCTION combolist_priority3(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null) 
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD NAME FOR the accessmode combo list FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	WHENEVER ERROR CONTINUE
	CALL ui.combobox.forname(p_cb_field_name).clear()

	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("1","High") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("2","Medium") 
	CALL ui.ComboBox.ForName(p_cb_field_name).addItem("3","Low") 
	WHENEVER ERROR STOP

	RETURN 3 

END FUNCTION 


{
FUNCTION comboList_company(p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null)
  DEFINE p_cb_field_name      VARCHAR(25)   --form field name FOR the company combo list field
	DEFINE p_variable SMALLINT	-- 0=first field IS variable 1= 2nd field IS variable
	DEFINE p_sort SMALLINT  --0=Sort on first 1=Sort on 2nd
	DEFINE p_single SMALLINT	--0=variable AND label 1= variable = label
	DEFINE p_hint SMALLINT  --1 = show both VALUES in label
	DEFINE curs_company CURSOR
	DEFINE p_sql_stmt STRING
	DEFINE l_companyRec RECORD
			cmpy_code LIKE company.cmpy_code,
			name_text LIKE company.name_text
		END RECORD
	DEFINE l_err_code INT
	DEFINE i INT
	DEFINE l_label STRING

	LET p_sql_stmt = "SELECT ",
										"cmpy_code, ",
										"name_text ",

										"FROM company "

	IF p_variable = 0 THEN
		LET p_sql_stmt = p_sql_stmt, " ORDER BY name_text ASC "
	ELSE
		LET p_sql_stmt = p_sql_stmt, " ORDER BY cmpy_code ASC "
	END IF



	WHENEVER ERROR CONTINUE

	CALL curs_company.DECLARE(p_sql_stmt,1)	RETURNING l_err_code
	CALL curs_company.SetResults(l_companyRec)	RETURNING l_err_code
	CALL curs_company.OPEN()	RETURNING l_err_code

	LET i = 1

	WHILE (curs_company.FetchNext()=0)

		IF p_variable = 0 THEN	--Variable IS first COLUMN/field

			IF p_single = 1 THEN  --ListItem variable value = label
				CALL ui.ComboBox.ForName(p_cb_field_name).addItem(l_companyRec.cmpy_code,l_companyRec.cmpy_code)
			ELSE	--ListItem IS a pair of variable value AND label
				IF p_hint = 0 THEN
					CALL ui.ComboBox.ForName(p_cb_field_name).addItem(l_companyRec.cmpy_code,l_companyRec.name_text)
				ELSE  -- Add both VALUES TO the label
					LET l_label =  trim(l_companyRec.name_text), " (", trim(l_companyRec.cmpy_code), ")"
					CALL ui.ComboBox.ForName(p_cb_field_name).addItem(l_companyRec.cmpy_code,l_label)
				END IF
			END IF

		ELSE	--Variable IS second COLUMN/field

			IF p_single = 1 THEN  --ListItem variable value = label
				CALL ui.ComboBox.ForName(p_cb_field_name).addItem(l_companyRec.name_text,l_companyRec.name_text)
			ELSE
				IF p_hint = 0 THEN	--ListItem IS a pair of variable value AND label
					CALL ui.ComboBox.ForName(p_cb_field_name).addItem(l_companyRec.name_text,l_companyRec.cmpy_code)
				ELSE   -- Add both VALUES TO the label
					LET l_label =  trim(l_companyRec.cmpy_code), " (", trim(l_companyRec.name_text), ")"
					CALL ui.ComboBox.ForName(p_cb_field_name).addItem(l_companyRec.name_text,l_label)
				END IF
			END IF


		END IF

		LET i = i+1
	END WHILE



	WHENEVER ERROR STOP

	RETURN i-1



END FUNCTION
}

################################################################
#
################################################################



############################################################
# FUNCTION db_customer_get_delete_flag2(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_delete_flag2(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_delete_flag LIKE customer.delete_flag

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
	
	SELECT delete_flag 
	INTO l_ret_delete_flag
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "delete_flag NOT found or is empty"
		END IF
		LET l_ret_delete_flag = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_delete_flag	                                                                                                
END FUNCTION

