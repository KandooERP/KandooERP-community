###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZ4_GLOBALS.4gl"  

############################################################
# Module Scope Variables
############################################################
DEFINE modu_err_message CHAR(40) 
DEFINE modu_rec_customertype RECORD LIKE customertype.* 
DEFINE modu_rec_accounts 
RECORD 
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD 

#########################################################
# FUNCTION AZ4_main()
#
# \brief module - AZ4.4gi
#  Description - Maintainance of Customer Types
#########################################################
FUNCTION AZ4_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("AZ4") 

	OPEN WINDOW A161 with FORM "A161" 
	CALL windecoration_a("A161") 

	CALL scan_customertype() 

	CLOSE WINDOW A161 

END FUNCTION 
#########################################################
# END FUNCTION AZ4_main()
#########################################################


#############################################################
# FUNCTION select_customertype(p_filter)
#
#
#############################################################
FUNCTION select_customertype(p_filter) 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE p_filter boolean 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_arr_rec_customertype DYNAMIC ARRAY OF t_rec_customertype_tc_tt 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		MESSAGE kandoomsg2("U",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			type_code, 
			type_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZ4","construct-type") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag = 1 OR quit_flag = 1 THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("W",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = "SELECT * FROM customertype ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND ", l_where_text CLIPPED," ", 
	"ORDER BY customertype.type_code" 

	PREPARE s_customertype FROM l_query_text 
	DECLARE c_customertype CURSOR FOR s_customertype 

	LET l_idx = 0 
	FOREACH c_customertype INTO l_rec_customertype.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customertype[l_idx].type_code = l_rec_customertype.type_code 
		LET l_arr_rec_customertype[l_idx].type_text = l_rec_customertype.type_text 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH
	 
	MESSAGE kandoomsg2("U",9113,l_idx)	#9113 l_idx records selected

	RETURN l_arr_rec_customertype 
END FUNCTION 
#############################################################
# END FUNCTION select_customertype(p_filter)
#############################################################


#########################################################################
# FUNCTION scan_customertype()
#
#
#########################################################################
FUNCTION scan_customertype() 
	DEFINE l_rec_orderaccounts RECORD LIKE orderaccounts.* 
	DEFINE l_arr_rec_customertype DYNAMIC ARRAY OF t_rec_customertype_tc_tt 
	DEFINE l_curr SMALLINT 
	DEFINE l_scr_line SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_rowid SMALLINT 
	DEFINE x SMALLINT 

	IF db_customertype_get_count() > 1000 THEN 
		CALL select_customertype(true) RETURNING l_arr_rec_customertype 
	ELSE 
		CALL select_customertype(false) RETURNING l_arr_rec_customertype 
	END IF 

	MESSAGE kandoomsg2("U",1003,"") #1003 "F1 TO Add - F2 TO Delete - RETURN TO Edit
	LET l_idx = 1 
	LET l_scr_line = 1 

	WHILE true 
		
		DISPLAY ARRAY l_arr_rec_customertype TO sr_customertype.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","AZ4","inp-arr-customertype") 
				CALL fgl_dialog_setcurrline(l_scr_line,l_idx) # RETURN CURSOR TO screen RECORD (l_scr_line) 

			ON ACTION "FILTER" 
				# refresh
				LET l_idx = 1 
				LET l_scr_line = 1 # number OF screen RECORD TO RETURN the CURSOR 
				CALL l_arr_rec_customertype.clear() 
				CALL select_customertype(true) RETURNING l_arr_rec_customertype # query BY example 
				EXIT DISPLAY 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION ("EDIT","doubleClick") 
				LET l_idx = arr_curr() 
				LET l_scr_line = scr_line() # number OF screen RECORD TO RETURN the CURSOR 
				IF l_arr_rec_customertype[l_idx].type_code IS NOT NULL THEN 
					LET modu_rec_customertype.type_code = l_arr_rec_customertype[l_idx].type_code 
					IF edit_customertype(modu_rec_customertype.type_code) > 0 THEN 
						# refresh
						CALL l_arr_rec_customertype.clear() 
						CALL select_customertype(false) RETURNING l_arr_rec_customertype 
						EXIT DISPLAY 
					END IF 
				END IF 

			ON ACTION ("ADD") 
				LET l_idx = arr_curr() 
				LET l_scr_line = scr_line() # number OF screen RECORD TO RETURN the CURSOR 
				INITIALIZE modu_rec_customertype.* TO NULL 
				IF edit_customertype(modu_rec_customertype.type_code) > 0 THEN 
					# refresh
					CALL l_arr_rec_customertype.clear() 
					CALL select_customertype(false) RETURNING l_arr_rec_customertype 
					EXIT DISPLAY 
				END IF 

			ON KEY (F2) # albo --> ON KEY (F2) should be changed TO ON ACTION "DELETE" ! 
				#            ON ACTION "DELETE" # albo
				LET l_idx = arr_curr() 
				LET l_scr_line = scr_line() 
				IF kandoomsg2("A",8047,"")  = "Y" THEN 				#8047 Confirm TO Delete
					SELECT count(*) INTO l_cnt FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = l_arr_rec_customertype[l_idx].type_code 
					IF l_cnt = 0 THEN 
						WHENEVER ERROR stop 
						WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
						BEGIN WORK 
							LET modu_err_message = "AZ4 - Error Deleting Customer Type" 
							DELETE FROM customertype 
							WHERE type_code = l_arr_rec_customertype[l_idx].type_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET modu_err_message = "AZ4 - Error Deleting Order Accounts" 
							DELETE FROM orderaccounts 
							WHERE table_name = l_rec_orderaccounts.table_name 
							AND column_name = l_rec_orderaccounts.column_name 
							AND ref_code = l_arr_rec_customertype[l_idx].type_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						COMMIT WORK 
						WHENEVER ERROR stop 
						WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

						# refresh
						CALL l_arr_rec_customertype.clear() 
						CALL select_customertype(false) RETURNING l_arr_rec_customertype 
						LET l_idx = l_idx - 1 
						LET l_scr_line = l_scr_line - 1 # number OF screen RECORD TO RETURN the CURSOR 
						EXIT DISPLAY 
					ELSE 
						ERROR kandoomsg2("A",9557,"") #9557 Cannot delete customer type, being used by customer(s).
						CONTINUE DISPLAY 
						
					END IF 
				END IF 

		END DISPLAY 

		IF int_flag = 1 OR quit_flag = 1 THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

	END WHILE 

END FUNCTION 
#########################################################################
# END FUNCTION scan_customertype()
#########################################################################


####################################################################################
# FUNCTION edit_customertype(p_type_code)
#
#
####################################################################################
FUNCTION edit_customertype(p_type_code) 
	DEFINE p_type_code LIKE customertype.type_code 
	DEFINE l_freight_acct_code LIKE customertype.freight_acct_code 
	DEFINE l_rec_orderaccounts RECORD LIKE orderaccounts.* 
	DEFINE l_rec_accounts 
	RECORD 
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE l_mask_code LIKE coa.acct_code 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_sqlerrd INTEGER 
	DEFINE i SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_first_flag SMALLINT 
	DEFINE l_exit_flag SMALLINT 
	DEFINE l_update_flag SMALLINT 
	DEFINE l_lastkey SMALLINT 
	DEFINE l_arg_acct_mask_code LIKE customertype.acct_mask_code 
	DEFINE l_ret_acct_mask_code LIKE customertype.acct_mask_code 

	OPEN WINDOW A201 with FORM "A201" 
	CALL windecoration_a("A201") 

	IF p_type_code IS NOT NULL THEN 
		SELECT * INTO modu_rec_customertype.* FROM customertype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = p_type_code 
		IF status = NOTFOUND THEN 
			ERROR kandoomsg2("U",7001,"Customer Type")		#7001 Logic Error: Customer Type RECORD No Exist
			RETURN false 
		END IF 
		FOR i = 1 TO 6 
			CALL display_desc(i) RETURNING l_cnt 
		END FOR 
	END IF 

	LET l_first_flag = true 
	LET l_update_flag = false 

	INITIALIZE modu_rec_accounts.* TO NULL 
	INITIALIZE l_rec_accounts.* TO NULL 
	LET l_freight_acct_code = modu_rec_customertype.freight_acct_code 

	MESSAGE kandoomsg2("U",1020,"Customer Type")	#1020 Enter Customer Type Details; OK TO Continue
	INPUT BY NAME 
		modu_rec_customertype.type_code, 
		modu_rec_customertype.type_text, 
		modu_rec_customertype.ar_acct_code, 
		modu_rec_customertype.freight_acct_code, 
		modu_rec_customertype.lab_acct_code, 
		modu_rec_customertype.tax_acct_code, 
		modu_rec_customertype.disc_acct_code, 
		modu_rec_customertype.exch_acct_code, 
		modu_rec_customertype.acct_mask_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ4","inp-customertype") 

		BEFORE FIELD type_code 
			IF p_type_code IS NOT NULL THEN 
				NEXT FIELD type_text 
			END IF 

		BEFORE FIELD freight_acct_code 
			IF get_kandoooption_feature_state("WO","TA") = "Y" THEN 
				LET l_lastkey = fgl_lastkey() 
				LET l_rec_accounts.* = modu_rec_accounts.* 
				LET modu_rec_accounts.def_acct_code = modu_rec_customertype.freight_acct_code
				 
				CALL enter_ordacct(glob_rec_kandoouser.cmpy_code, modu_rec_customertype.type_code, "customertype", 
				"freight_acct_code",modu_rec_accounts.*,l_first_flag) 
				RETURNING l_exit_flag, modu_rec_accounts.* 
				
				IF NOT l_exit_flag THEN 
					LET l_first_flag = false 
					LET modu_rec_customertype.freight_acct_code = modu_rec_accounts.def_acct_code 
				ELSE 
				
					# User has cancelled entries
					LET modu_rec_accounts.* = l_rec_accounts.* 
				END IF
				 
				IF modu_rec_customertype.ar_acct_code = modu_rec_customertype.freight_acct_code THEN 
					ERROR kandoomsg2("G",9202,"")			#9202 Subsidiary Control Account must NOT be used.
					NEXT FIELD freight_acct_code 
				END IF 
				
				CALL display_desc(2) RETURNING l_cnt
				 
				IF l_lastkey = fgl_keyval("up") 
				OR l_lastkey = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				END IF 
				NEXT FIELD NEXT 
			END IF 

		BEFORE FIELD acct_mask_code 
			--         ERROR kandoomsg2("U",7032,"")  # albo		#7032 Warning: Changing Mask will NOT affect existing invoices
			CALL build_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
			RETURNING l_mask_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, " ", " ") 
			RETURNING l_arg_acct_mask_code 
			CALL segment_fill(glob_rec_kandoouser.cmpy_code, l_mask_code, l_arg_acct_mask_code) 
			RETURNING l_ret_acct_mask_code 
			IF l_arg_acct_mask_code <> l_ret_acct_mask_code 
			THEN LET modu_rec_customertype.acct_mask_code = l_ret_acct_mask_code 
				DISPLAY BY NAME modu_rec_customertype.acct_mask_code 
			ELSE LET int_flag = false 
				LET quit_flag = false 
			END IF 
			IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN,modu_rec_customertype.acct_mask_code) 
			OR NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_RECEIPT_CA,modu_rec_customertype.acct_mask_code) 
			OR NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_CREDIT_CR,modu_rec_customertype.acct_mask_code) THEN
				IF promptTF("",kandoomsg2("A",8046,""),1) THEN 
					NEXT FIELD acct_mask_code 
				END IF 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(ar_acct_code) 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET modu_rec_customertype.ar_acct_code = l_winds_text 
				CALL display_desc(1) RETURNING l_cnt 
			END IF 

		ON ACTION "LOOKUP" infield(freight_acct_code) 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET modu_rec_customertype.freight_acct_code = l_winds_text 
				CALL display_desc(2) RETURNING l_cnt 
			END IF 

		ON ACTION "LOOKUP" infield(lab_acct_code) 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET modu_rec_customertype.lab_acct_code = l_winds_text 
				CALL display_desc(3) RETURNING l_cnt 
			END IF 

		ON ACTION "LOOKUP" infield(tax_acct_code) 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET modu_rec_customertype.tax_acct_code = l_winds_text 
				CALL display_desc(4) RETURNING l_cnt 
			END IF 

		ON ACTION "LOOKUP" infield(disc_acct_code) 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET modu_rec_customertype.disc_acct_code = l_winds_text 
				CALL display_desc(5) RETURNING l_cnt 
			END IF 

		ON ACTION "LOOKUP" infield(exch_acct_code) 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET modu_rec_customertype.exch_acct_code = l_winds_text 
				CALL display_desc(6) RETURNING l_cnt 
			END IF 

		AFTER FIELD type_code 
			IF modu_rec_customertype.type_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD type_code 
			END IF 
			SELECT count(*) INTO l_cnt FROM customertype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = modu_rec_customertype.type_code 
			IF l_cnt <> 0 THEN 
				ERROR kandoomsg2("U",9104,"")				#9104 RECORD already exists.
				NEXT FIELD type_code 
			END IF 

		AFTER FIELD type_text 
			IF modu_rec_customertype.type_text IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")			#9102 Value must be entered
				NEXT FIELD type_text 
			END IF 

		AFTER FIELD ar_acct_code 
			IF NOT display_desc(1) THEN 
				ERROR kandoomsg2("U",9105,"")		#9105 RECORD Not Found; Try Window
				NEXT FIELD ar_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_rec_customertype.ar_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"Y") THEN 
				NEXT FIELD ar_acct_code 
			END IF 

		AFTER FIELD freight_acct_code 
			IF NOT display_desc(2) THEN 
				ERROR kandoomsg2("U",9105,"") 		#9105 RECORD Not Found; Try Window
				NEXT FIELD freight_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_rec_customertype.freight_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD freight_acct_code 
			ELSE 
				IF modu_rec_customertype.ar_acct_code 
				= modu_rec_customertype.freight_acct_code THEN 
					ERROR kandoomsg2("G",9202,"")				#9202 Subsidiary Control Account must NOT be used
					NEXT FIELD freight_acct_code 
				END IF 
			END IF 

		AFTER FIELD lab_acct_code 
			IF NOT display_desc(3) THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD Not Found; Try Window
				NEXT FIELD lab_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_rec_customertype.lab_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD lab_acct_code 
			ELSE 
				IF modu_rec_customertype.ar_acct_code = modu_rec_customertype.lab_acct_code THEN 
					ERROR kandoomsg2("G",9202,"")				#9202 Subsidiary Control Account must NOT be used
					NEXT FIELD lab_acct_code 
				END IF 
			END IF 

		AFTER FIELD tax_acct_code 
			IF NOT display_desc(4) THEN 
				ERROR kandoomsg2("U",9105,"")		#9105 RECORD Not Found; Try Window
				NEXT FIELD tax_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_rec_customertype.tax_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD tax_acct_code 
			ELSE 
				IF modu_rec_customertype.ar_acct_code		= modu_rec_customertype.tax_acct_code THEN 
					ERROR kandoomsg2("G",9202,"")				#9202 Subsidiary Control Account must NOT be used
					NEXT FIELD tax_acct_code 
				END IF 
			END IF 

		AFTER FIELD disc_acct_code 
			IF NOT display_desc(5) THEN 
				ERROR kandoomsg2("U",9105,"")		#9105 RECORD Not Found; Try Window
				NEXT FIELD disc_acct_code 
			END IF 
			
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_rec_customertype.disc_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD disc_acct_code 
			ELSE 
				IF modu_rec_customertype.ar_acct_code		= modu_rec_customertype.disc_acct_code THEN 
					ERROR kandoomsg2("G",9202,"") #9202 Subsidiary Control Account must NOT be used
					NEXT FIELD disc_acct_code 
				END IF 
			END IF 

		AFTER FIELD exch_acct_code 
			IF NOT display_desc(6) THEN 
				ERROR kandoomsg2("U",9105,"")	#9105 RECORD Not Found; Try Window
				NEXT FIELD exch_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_rec_customertype.exch_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD exch_acct_code 
			ELSE 
				IF modu_rec_customertype.ar_acct_code = modu_rec_customertype.exch_acct_code THEN 
					ERROR kandoomsg2("G",9202,"")				#9202 Subsidiary Control Account must NOT be used
					NEXT FIELD exch_acct_code 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag = 1 OR quit_flag = 1 
			THEN # "Cancel" ACTION activated 
				LET int_flag = false 
				LET quit_flag = false 
				IF field_touched(customertype.*) <> 0 
				THEN #check, IF anything has changed... 
					IF promptTF("Exit ?","Do you want to exit ?\nAll changes will be lost !",TRUE) 
					THEN LET l_update_flag = false 
						EXIT INPUT 
					ELSE CONTINUE INPUT 
					END IF 
				ELSE LET l_update_flag = false 
					EXIT INPUT 
				END IF 
			ELSE # "Apply" ACTION activated 
				IF field_touched(customertype.*) <> 0 
				THEN #check, IF anything has changed... 
					IF modu_rec_customertype.type_text IS NULL THEN 
						ERROR kandoomsg2("U",9102,"")					#9102 Value must be entered
						NEXT FIELD type_text 
					END IF 
					FOR i = 1 TO 6 
						CALL display_desc(i) RETURNING l_cnt 
					END FOR 
					LET l_update_flag = true 
					EXIT INPUT 
				ELSE LET l_update_flag = false 
					EXIT INPUT 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW A201 

	IF l_update_flag = true THEN 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(modu_err_message, status) = "N" THEN 
			RETURN false 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 

			LET l_sqlerrd = 0 
			IF modu_rec_accounts.def_acct_code IS NOT NULL THEN 
				LET modu_err_message = "AZ4 - Updating Order Accounts" 
				LET l_rec_orderaccounts.ref_code = modu_rec_customertype.type_code 
				LET l_rec_orderaccounts.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_orderaccounts.table_name = "customertype" 
				LET l_rec_orderaccounts.column_name = "freight_acct_code" 
				FOR l_counter = 6 TO 9 
					CASE l_counter 
						WHEN "6" 
							LET l_rec_orderaccounts.acct_code = modu_rec_accounts.ord6_acct_code 
						WHEN "7" 
							LET l_rec_orderaccounts.acct_code = modu_rec_accounts.ord7_acct_code 
						WHEN "8" 
							LET l_rec_orderaccounts.acct_code = modu_rec_accounts.ord8_acct_code 
						WHEN "9" 
							LET l_rec_orderaccounts.acct_code = modu_rec_accounts.ord9_acct_code 
					END CASE 
					IF l_rec_orderaccounts.acct_code IS NULL THEN 
						DELETE FROM orderaccounts 
						WHERE table_name = l_rec_orderaccounts.table_name 
						AND column_name = l_rec_orderaccounts.column_name 
						AND ref_code = l_rec_orderaccounts.ref_code 
						AND ord_ind = l_counter 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						CONTINUE FOR 
					END IF 
					UPDATE orderaccounts 
					SET acct_code = l_rec_orderaccounts.acct_code 
					WHERE table_name = l_rec_orderaccounts.table_name 
					AND column_name = l_rec_orderaccounts.column_name 
					AND ref_code = l_rec_orderaccounts.ref_code 
					AND ord_ind = l_counter 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF sqlca.sqlerrd[3] = 0 THEN 
						LET l_rec_orderaccounts.ord_ind = l_counter 
						INSERT INTO orderaccounts VALUES (l_rec_orderaccounts.*) 
						LET l_sqlerrd = sqlca.sqlerrd[3] 
					ELSE LET l_sqlerrd = sqlca.sqlerrd[3] 
					END IF 
				END FOR 
			END IF 

			IF p_type_code IS NULL THEN 
				LET modu_rec_customertype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_err_message = "AZ4 - Inserting customertype" 
				INSERT INTO customertype VALUES (modu_rec_customertype.*) 
				LET l_sqlerrd = sqlca.sqlerrd[3] 
			ELSE 
				LET modu_err_message = "AZ4 - Updating customertype" 
				UPDATE customertype 
				SET * = modu_rec_customertype.* 
				WHERE type_code = modu_rec_customertype.type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_sqlerrd = sqlca.sqlerrd[3] 
			END IF 

		COMMIT WORK 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	END IF 

	RETURN l_update_flag 
END FUNCTION 
####################################################################################
# END FUNCTION edit_customertype(p_type_code)
####################################################################################


#############################################################
# FUNCTION display_desc(p_field_id)
#
#
#############################################################
FUNCTION display_desc(p_field_id) 
	DEFINE p_field_id SMALLINT 
	DEFINE l_account_code LIKE coa.acct_code 
	DEFINE l_acct_desc LIKE coa.desc_text 

	CASE p_field_id 
		WHEN 1 
			IF modu_rec_customertype.ar_acct_code IS NULL THEN 
				LET modu_rec_customertype.ar_acct_code = glob_rec_arparms.ar_acct_code 
			END IF 

			LET l_account_code = modu_rec_customertype.ar_acct_code 
			INITIALIZE l_acct_desc TO NULL 
			SELECT desc_text INTO l_acct_desc FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_account_code 
			IF status = NOTFOUND THEN 
				DISPLAY " " TO acct1_text 

				RETURN(FALSE) 
			END IF 
			DISPLAY l_acct_desc TO acct1_text 

		WHEN 2 
			IF modu_rec_customertype.freight_acct_code IS NULL THEN 
				LET modu_rec_customertype.freight_acct_code = glob_rec_arparms.freight_acct_code 
			END IF 

			LET l_account_code = modu_rec_customertype.freight_acct_code 
			INITIALIZE l_acct_desc TO NULL 
			SELECT desc_text INTO l_acct_desc FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_account_code 
			IF status = NOTFOUND THEN 
				DISPLAY " " TO acct2_text 

				RETURN(FALSE) 
			END IF 
			DISPLAY l_acct_desc TO acct2_text 

		WHEN 3 
			IF modu_rec_customertype.lab_acct_code IS NULL THEN 
				LET modu_rec_customertype.lab_acct_code = glob_rec_arparms.lab_acct_code 
			END IF 

			LET l_account_code = modu_rec_customertype.lab_acct_code 
			INITIALIZE l_acct_desc TO NULL 
			SELECT desc_text INTO l_acct_desc FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_account_code 
			IF status = NOTFOUND THEN 
				DISPLAY " " TO acct3_text 

				RETURN(FALSE) 
			END IF 
			DISPLAY l_acct_desc TO acct3_text 

		WHEN 4 
			IF modu_rec_customertype.tax_acct_code IS NULL THEN 
				LET modu_rec_customertype.tax_acct_code = glob_rec_arparms.tax_acct_code 
			END IF 

			LET l_account_code = modu_rec_customertype.tax_acct_code 
			INITIALIZE l_acct_desc TO NULL 
			SELECT desc_text INTO l_acct_desc FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_account_code 
			IF status = NOTFOUND THEN 
				DISPLAY " " TO acct4_text 

				RETURN(FALSE) 
			END IF 
			DISPLAY l_acct_desc TO acct4_text 

		WHEN 5 
			IF modu_rec_customertype.disc_acct_code IS NULL THEN 
				LET modu_rec_customertype.disc_acct_code = glob_rec_arparms.disc_acct_code 
			END IF 

			LET l_account_code = modu_rec_customertype.disc_acct_code 
			INITIALIZE l_acct_desc TO NULL 
			SELECT desc_text INTO l_acct_desc FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_account_code 
			IF status = NOTFOUND THEN 
				DISPLAY " " TO acct5_text 

				RETURN(FALSE) 
			END IF 
			DISPLAY l_acct_desc TO acct5_text 

		WHEN 6 
			IF modu_rec_customertype.exch_acct_code IS NULL THEN 
				LET modu_rec_customertype.exch_acct_code = glob_rec_arparms.exch_acct_code 
			END IF 

			LET l_account_code = modu_rec_customertype.exch_acct_code 
			INITIALIZE l_acct_desc TO NULL 
			SELECT desc_text INTO l_acct_desc FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_account_code 
			IF status = NOTFOUND THEN 
				DISPLAY " " TO acct6_text 

				RETURN(FALSE) 
			END IF 
			DISPLAY l_acct_desc TO acct6_text 

	END CASE 

	RETURN(TRUE) 
END FUNCTION 
#############################################################
# END FUNCTION display_desc(p_field_id)
#############################################################