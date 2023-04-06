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
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZP_GLOBALS.4gl" 
--GLOBALS 
--	DEFINE glob_ans CHAR(1) 
--	DEFINE glob_rec_customertype RECORD LIKE customertype.* 

--END GLOBALS 
DEFINE modu_rec_accounts RECORD 
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD 
--DEFINE glob_temp_text STRING
##############################################################
# MAIN
# \brief module AZP which provides FOR the maintenance of Accounts Receivable Parameters
#
##############################################################
FUNCTION AZP_main()
--	DEFINE l_rec_arparms RECORD LIKE arparms.*
--	DEFINE l_rec_arparmext RECORD LIKE arparmext.*
	DEFINE l_operation_status INTEGER
	DEFINE l_int_flag SMALLINT

	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("AZP")

	OPEN WINDOW A164 with FORM "A164" 
	CALL windecoration_a("A164") 

	MENU "Parameters" 

		BEFORE MENU 
			CALL dialog.setActionHidden("CANCEL",TRUE) 

			LET l_operation_status = db_arparms_parm_code_exist("1") 
			IF l_operation_status THEN
				CALL display_arpams_arparmext_fields() --RETURNING l_operation_status, glob_rec_arparms.*,glob_rec_arparmext.*
				HIDE option "ADD" 
			ELSE 
				HIDE option "EDIT" 
				HIDE option "REPORTING CODE" 
			END IF 

			CALL publish_toolbar("kandoo","AZP","menu-parameters") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REPORTING CODE" #COMMAND "Reporting" " DISPLAY Reporting Code labels"

			OPEN WINDOW A211 with FORM "A211" 
			CALL windecoration_a("A211") 

			CALL display_arparms_record(glob_rec_arparms.*)
			#CALL eventSuspend()
			CALL eventsuspend() # MESSAGE kandoomsg2("U",1,"") 		#1 Any Key TO Continue
			CLOSE WINDOW A211 

		ON ACTION "ADD"		#COMMAND "ADD" " Add Parameters"
			IF NOT db_arparms_parm_code_exist("1") THEN
				INITIALIZE glob_rec_arparms.* TO NULL
				INITIALIZE glob_rec_arparmext.* TO NULL

				CALL input_arparms_arparmext(MODE_CLASSIC_ADD,glob_rec_arparms.*,glob_rec_arparmext.*) 
				RETURNING l_int_flag,glob_rec_arparms.*,glob_rec_arparmext.*

				IF NOT l_int_flag THEN
					CALL insert_arparms_arparmext(glob_rec_arparms.*,glob_rec_arparmext.*) RETURNING l_operation_status
					IF l_operation_status = 0 THEN
						OPEN WINDOW A211 with FORM "A211" 
						CALL windecoration_a("A211") 

						CALL input_and_update_ref_fields(glob_rec_arparms.*) RETURNING l_int_flag,glob_rec_arparms.*

						CLOSE WINDOW A211 
						HIDE option "ADD" 
						SHOW option "EDIT" 
						SHOW option "Reporting" 
					END IF
				END IF
			END IF
			
		ON ACTION "EDIT" 			#     COMMAND "EDIT" "Edit Parameters"
			IF db_arparms_parm_code_exist("1") THEN
				CALL input_arparms_arparmext(MODE_CLASSIC_EDIT,glob_rec_arparms.*,glob_rec_arparmext.*) 
				RETURNING 
					l_int_flag,
					glob_rec_arparms.*,
					glob_rec_arparmext.*
				
				IF NOT l_int_flag THEN
					IF update_arparms_arparmext(glob_rec_arparms.*,glob_rec_arparmext.*) < 0 THEN
						CALL fgl_winmessage("Failed to Update Arparmext","Failed to update the Accounts Receivable Configuration (DB.arparmext)","ERROR")
					ELSE
						MESSAGE "Accounts Receivable Configuration updated successfully!" 
					END IF  
					--RETURNING glob_rec_arparms.*,glob_rec_arparmext.*
				END IF
			END IF

		ON ACTION "REPORTING CODE"	#COMMAND "Reporting"" Modify Reporting Code labels"
			IF db_arparms_parm_code_exist("1") THEN
				OPEN WINDOW A211 with FORM "A211" 
				CALL windecoration_a("A211")
				
				CALL input_and_update_ref_fields(glob_rec_arparms.*) RETURNING l_int_flag,glob_rec_arparms.*
				
				CLOSE WINDOW A211 
			END IF
			
--		ON ACTION "Cancel" #COMMAND KEY(interrupt,"E") "Exit" " RETURN TO main menu"
--			LET int_flag = false 

		ON ACTION ("Exit","CANCEL") 			#       COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus"
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU
	END MENU 

	CLOSE WINDOW A164 
END FUNCTION # AZP_main 
##############################################################
# END FUNCTION AZP_main()
##############################################################


##############################################################
# FUNCTION insert_arparms_arparmext()
#
#
##############################################################
FUNCTION insert_arparms_arparmext(p_rec_arparms,p_rec_arparmext)
	DEFINE p_rec_arparms RECORD LIKE arparms.*
	DEFINE p_rec_arparmext RECORD LIKE arparmext.*
	DEFINE l_rec_orderaccounts RECORD LIKE orderaccounts.*
	DEFINE l_err_message CHAR(60) 
	DEFINE l_counter SMALLINT 

	LET l_err_message = "AZP - Error Inserting INTO arparms" 

	BEGIN WORK

	WHENEVER SQLERROR CONTINUE

	# INSERT ----------------------------------------
	INSERT INTO arparms VALUES (p_rec_arparms.*) 
	IF sqlca.sqlcode < 0 THEN
		ERROR "Insert of arparms FAILED with errors"
		ROLLBACK WORK
		RETURN sqlca.sqlcode
	END IF

	LET p_rec_arparmext.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_err_message = "AZP - Error Updating arparmext"
	INSERT INTO arparmext VALUES (p_rec_arparmext.*)

--	IF sqlca.sqlcode < 0 THEN  # albo
--		UPDATE arparmext SET * = p_rec_arparmext.* 
--		WHERE cmpy_code = p_rec_arparmext.cmpy_code
--	END IF 

	IF sqlca.sqlcode < 0 THEN
		ERROR "Insert of arparmext FAILED with errors!"
		ROLLBACK WORK
		RETURN sqlca.sqlcode
	END IF

	IF get_kandoooption_feature_state("WO","TA") = "Y" THEN 
		# FIXME: check where we get l_rec_orderaccounts from
		LET l_err_message = "AZP - Error Inserting Order Accounts" 
		LET l_rec_orderaccounts.ref_code = "AZP" 
		LET l_rec_orderaccounts.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_orderaccounts.table_name = "arparms" 
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
			
			LET l_rec_orderaccounts.ord_ind = l_counter 
			
			# INSERT ----------------------------------------------------
			INSERT INTO orderaccounts VALUES (l_rec_orderaccounts.*)
			IF sqlca.sqlcode < 0 THEN
				ERROR "Insert of orderaccounts FAILED with errors!"
				ROLLBACK WORK
				RETURN sqlca.sqlcode
			END IF
		END FOR 
	END IF 

	COMMIT WORK 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN sqlca.sqlcode 

END FUNCTION  #  insert_arparms_arparmext()
##############################################################
# END FUNCTION insert_arparms_arparmext()
##############################################################


##############################################################
# FUNCTION update_arparms_arparmext()
#
#
##############################################################
FUNCTION update_arparms_arparmext(p_rec_arparms,p_rec_arparmext) 
	DEFINE p_rec_arparms RECORD LIKE arparms.*
	DEFINE p_rec_arparmext RECORD LIKE arparmext.*
	DEFINE l_rec_orderaccounts RECORD LIKE orderaccounts.* 
	DEFINE l_counter SMALLINT 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_operation_status INTEGER

	WHENEVER SQLERROR CONTINUE
		BEGIN WORK 
	# Got rid of cursor for UPDATE, better use REPEATABLE READ
	SET ISOLATION TO REPEATABLE READ    # any record read receives a shared lock, but has priority for UPDATE

-- @eric - I did comment your line... (otherwise, it will not be able to update the record in the DB
--	CALL arparms_get_record("1") RETURNING l_operation_status,p_rec_arparms.*

	LET p_rec_arparms.show_tax_flag = xlate_to(p_rec_arparms.show_tax_flag) 
	LET p_rec_arparms.gl_flag = xlate_to(p_rec_arparms.gl_flag) 
	LET p_rec_arparms.detail_to_gl_flag = xlate_to(p_rec_arparms.detail_to_gl_flag) 
	LET p_rec_arparms.show_seg_flag = xlate_to(p_rec_arparms.show_seg_flag) 

	# FIXME: not sure this test means something: comparing same variables
	IF p_rec_arparms.ar_acct_code != p_rec_arparms.ar_acct_code 
	OR p_rec_arparms.freight_acct_code != p_rec_arparms.freight_acct_code 
	OR p_rec_arparms.lab_acct_code != p_rec_arparms.lab_acct_code 
	OR p_rec_arparms.tax_acct_code != p_rec_arparms.tax_acct_code 
	OR p_rec_arparms.disc_acct_code != p_rec_arparms.disc_acct_code 
	OR p_rec_arparms.exch_acct_code != p_rec_arparms.exch_acct_code THEN 
	
		IF kandoomsg("A",8048,"") = "Y" THEN #8048 AT least one GL account has changed.  Update customer type ... 
			LET l_err_message = "AZP - Error Updating Customer Types" 
			CALL update_customertype(p_rec_arparms.*) 
		END IF 

	END IF 

	# UPDATE ---------------------------------------------
	UPDATE arparms 
	SET * = p_rec_arparms.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1"
	IF sqlca.sqlcode < 0 THEN
		ERROR "Update of arparms FAILED with errors!"
		ROLLBACK WORK
		CALL reset_isolation_mode() 
		RETURN FALSE
	END IF

	LET p_rec_arparmext.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_err_message = "AZP - Error Updating " 

	# UPDATE -------------------------------------
	UPDATE arparmext SET * = p_rec_arparmext.* 
	WHERE cmpy_code = p_rec_arparmext.cmpy_code 
	IF sqlca.sqlcode < 0 THEN 
		ERROR "Update of arparmext FAILED with errors!"
		ROLLBACK WORK
		CALL reset_isolation_mode() 
		RETURN FALSE
	END IF	

--	IF sqlca.sqlerrd[3] = 0 THEN  # albo
--		# INSERT ----------------------------------------------
--		INSERT INTO arparmext VALUES (p_rec_arparmext.*) 
--		IF sqlca.sqlcode < 0 THEN
--			ERROR "Insert of arparmext FAILED with errors!"
--			CALL reset_isolation_mode() 
--			ROLLBACK WORK
--			RETURN FALSE
--		END IF
--	END IF

	IF modu_rec_accounts.def_acct_code IS NOT NULL THEN 
		LET l_err_message = "AZP - Error Updating Order Accounts" 
		LET l_rec_orderaccounts.ref_code = "AZP" 
		LET l_rec_orderaccounts.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_orderaccounts.table_name = "arparms" 
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
				# DELETE ----------------------------------------------
				DELETE FROM orderaccounts 
				WHERE table_name = l_rec_orderaccounts.table_name 
				AND column_name = l_rec_orderaccounts.column_name 
				AND ref_code = l_rec_orderaccounts.ref_code 
				AND ord_ind = l_counter 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				CONTINUE FOR 
			END IF 
			
			# UPDATE ----------------------------------------------
			UPDATE orderaccounts 
			SET acct_code = l_rec_orderaccounts.acct_code 
			WHERE table_name = l_rec_orderaccounts.table_name 
			AND column_name = l_rec_orderaccounts.column_name 
			AND ref_code = l_rec_orderaccounts.ref_code 
			AND ord_ind = l_counter 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF sqlca.sqlerrd[3] = 0 THEN 
				LET l_rec_orderaccounts.ord_ind = l_counter 
				# INSERT ----------------------------------------------------
				INSERT INTO orderaccounts VALUES (l_rec_orderaccounts.*) 
			END IF 
		END FOR 
	END IF 

	COMMIT WORK 

	CALL reset_isolation_mode() 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN sqlca.sqlcode
END FUNCTION 
##############################################################
# END FUNCTION update_arparms_arparmext()
##############################################################


##############################################################
# FUNCTION input_arparms()
#
#
##############################################################
FUNCTION input_arparms_arparmext(p_mode,p_rec_arparms,p_rec_arparmext) 
	DEFINE p_mode CHAR(6)
	DEFINE p_rec_arparms RECORD LIKE arparms.*
	DEFINE p_rec_arparmext RECORD LIKE arparmext.*
	#	DEFINE l_rec_journal        RECORD LIKE journal.*
	#	DEFINE l_rec_country        RECORD LIKE country.*
	#	DEFINE l_rec_currency       RECORD LIKE currency.*
	#	DEFINE l_rec_tax            RECORD LIKE tax.*
	#	DEFINE l_rec_coa            RECORD LIKE coa.*
	DEFINE l_rec_glparams RECORD LIKE glparms.* 
	DEFINE l_first_flag SMALLINT 
	DEFINE l_lastkey SMALLINT 
	DEFINE l_exit_flag CHAR(1) 
	DEFINE l_rec_accounts RECORD 
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE l_cash_book CHAR(1) 

	LET l_first_flag = true 
	INITIALIZE modu_rec_accounts.* TO NULL 

	CASE
		WHEN p_mode = MODE_CLASSIC_ADD
			LET p_rec_arparms.nextinv_num = 1 
			LET p_rec_arparms.nextcash_num = 1 
			LET p_rec_arparms.nextcredit_num = 1 
			LET p_rec_arparms.inv_ref1_text = "Purchase Code" 
			LET p_rec_arparms.inv_ref2a_text = "Purchase" 
			LET p_rec_arparms.inv_ref2b_text = " Code " 
			LET p_rec_arparms.credit_ref1_text = "Authorise Code" 
			LET p_rec_arparms.credit_ref2a_text = " Auth. " 
			LET p_rec_arparms.credit_ref2b_text = " Code " 
			LET p_rec_arparms.next_bank_dep_num = 1 
			LET p_rec_arparms.cust_age_date = today 
			LET p_rec_arparms.last_stmnt_date = today 
			LET p_rec_arparms.last_post_date = today 
			LET p_rec_arparms.last_del_date = today 
			LET p_rec_arparms.last_rec_date = today 
			LET p_rec_arparms.consolidate_flag = "Y" 

			#??? why why why ???		
			SELECT country_code INTO p_rec_arparms.country_code 
			FROM company 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET p_rec_arparms.show_tax_flag = xlate_to(p_rec_arparms.show_tax_flag) 
			LET p_rec_arparms.gl_flag = xlate_to(p_rec_arparms.gl_flag) 
			LET p_rec_arparms.detail_to_gl_flag = xlate_to(p_rec_arparms.detail_to_gl_flag) 
			LET p_rec_arparms.show_seg_flag = xlate_to(p_rec_arparms.show_seg_flag) 
			LET p_rec_arparms.last_mail_date = today 
			LET p_rec_arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET p_rec_arparms.parm_code = "1" 
			
			INITIALIZE l_rec_accounts.* TO NULL 

			#init check boxes if they have NULL values huho
			IF p_rec_arparms.consolidate_flag IS NULL THEN 
				LET p_rec_arparms.consolidate_flag = 'N' 
			END IF 
			IF p_rec_arparms.corp_drs_flag IS NULL THEN 
				LET p_rec_arparms.corp_drs_flag = 'N' 
			END IF 
			IF p_rec_arparms.show_tax_flag IS NULL THEN 
				LET p_rec_arparms.show_tax_flag = 'N' 
			END IF 
			IF p_rec_arparms.show_seg_flag IS NULL THEN 
				LET p_rec_arparms.show_seg_flag = 'N' 
			END IF 
			IF p_rec_arparms.gl_flag IS NULL THEN 
				LET p_rec_arparms.gl_flag = 'N' 
			END IF 
			IF p_rec_arparms.detail_to_gl_flag IS NULL THEN 
				LET p_rec_arparms.detail_to_gl_flag = 'N' 
			END IF 
		WHEN p_mode = MODE_CLASSIC_EDIT

	END CASE
	
	MESSAGE kandoomsg2("U",1070,"")	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME p_rec_arparms.sales_jour_code, 
		p_rec_arparms.cash_jour_code, 
		p_rec_arparms.ar_acct_code, 
		p_rec_arparms.cash_acct_code, 
		p_rec_arparms.freight_acct_code, 
		p_rec_arparms.lab_acct_code, 
		p_rec_arparms.tax_acct_code, 
		p_rec_arparms.disc_acct_code, 
		p_rec_arparms.exch_acct_code, 
		p_rec_arparmext.int_acct_code, 
		p_rec_arparmext.writeoff_acct_code, 
		p_rec_arparms.cred_amt, 
		p_rec_arparms.currency_code, 
		p_rec_arparms.reason_code, 
		p_rec_arparms.stmnt_ind, 
		p_rec_arparms.next_bank_dep_num, 
		p_rec_arparms.report_ord_flag, 
		p_rec_arparms.consolidate_flag, 
		p_rec_arparms.corp_drs_flag, 
		p_rec_arparms.show_tax_flag, 
		p_rec_arparms.show_seg_flag, 
		p_rec_arparms.gl_flag, 
		p_rec_arparms.detail_to_gl_flag WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZP","inp-arparms-1") 
			
			SELECT * INTO l_rec_glparams.* FROM glparms #l_rec_glparams 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = '1' 
			
			IF l_rec_glparams.cash_book_flag = "Y" THEN 
				LET l_cash_book = "4" 
			ELSE 
				LET l_cash_book = "2" 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (sales_jour_code) 
			LET glob_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.sales_jour_code = glob_temp_text 
			END IF 
			NEXT FIELD sales_jour_code 

		ON ACTION "LOOKUP" infield (cash_jour_code) 
			LET glob_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.cash_jour_code = glob_temp_text 
			END IF 
			NEXT FIELD cash_jour_code 

		ON ACTION "LOOKUP" infield (ar_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.ar_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD ar_acct_code 

		ON ACTION "LOOKUP" infield (cash_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.cash_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD cash_acct_code 

		ON ACTION "LOOKUP" infield (freight_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.freight_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD freight_acct_code 

		ON ACTION "LOOKUP" infield (lab_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.lab_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD lab_acct_code 

		ON ACTION "LOOKUP" infield (tax_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.tax_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD tax_acct_code 

		ON ACTION "LOOKUP" infield (disc_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.disc_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD disc_acct_code 

		ON ACTION "LOOKUP" infield (exch_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.exch_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD exch_acct_code 

		ON ACTION "LOOKUP" infield (int_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparmext.int_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD int_acct_code 

		ON ACTION "LOOKUP" infield (writeoff_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparmext.writeoff_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD writeoff_acct_code 

		ON ACTION "LOOKUP" infield (currency_code) 
			LET glob_temp_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_arparms.currency_code = glob_temp_text 
			END IF 
			NEXT FIELD currency_code 

		ON ACTION "LOOKUP" infield (reason_code) 
			#FUNCTION show_credreas(p_cmpy,p_filter_where2_text,p_def_reason_code) 
			LET p_rec_arparms.reason_code = show_credreas(glob_rec_kandoouser.cmpy_code,NULL,p_rec_arparms.reason_code) 
			NEXT FIELD reason_code 

		AFTER FIELD sales_jour_code 
			IF NOT db_journal_pk_exists(glob_rec_kandoouser.cmpy_code,p_rec_arparms.sales_jour_code) THEN
				ERROR kandoomsg2("A",9048,"") 	#9048 "Specified Sales Journal NOT found, try win.."
				NEXT FIELD sales_jour_code 
			END IF 

		AFTER FIELD cash_jour_code 
			IF NOT db_journal_pk_exists(glob_rec_kandoouser.cmpy_code,p_rec_arparms.cash_jour_code) THEN
				ERROR kandoomsg2("A",9049,"") 		#9049 "Specified Cash Receipts Journal NOT found, try win.."
				NEXT FIELD cash_jour_code 
			END IF 

		AFTER FIELD ar_acct_code 
			IF NOT check_prykey_exists_coa(glob_rec_kandoouser.cmpy_code,p_rec_arparms.ar_acct_code) THEN
				ERROR kandoomsg2("A",9050,"") 		#9050 "AR Account (Trade Debtors) NOT found, try again"
				NEXT FIELD ar_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,p_rec_arparms.ar_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"Y") THEN 
				NEXT FIELD ar_acct_code 
			END IF 

		AFTER FIELD cash_acct_code 
			IF NOT check_prykey_exists_coa(glob_rec_kandoouser.cmpy_code,p_rec_arparms.cash_acct_code) THEN
				ERROR kandoomsg2("A",9051,"") 			#9051 "Cash/Bank Account NOT found, try window"
				NEXT FIELD cash_acct_code 
			END IF 
			# COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK OR COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK  #cash_acct_code=KAU-002-1200 l_cash_book=4
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,p_rec_arparms.cash_acct_code,l_cash_book,"Y") THEN 
				NEXT FIELD cash_acct_code 
			END IF 

		BEFORE FIELD freight_acct_code 
			IF get_kandoooption_feature_state("WO","TA") = "Y" THEN 
				LET l_rec_accounts.* = modu_rec_accounts.* 
				LET modu_rec_accounts.def_acct_code = p_rec_arparms.freight_acct_code 
				CALL enter_ordacct(glob_rec_kandoouser.cmpy_code,"AZP","arparms","freight_acct_code",modu_rec_accounts.*,l_first_flag) 
				RETURNING l_exit_flag, modu_rec_accounts.* 
				IF NOT l_exit_flag THEN 
					LET l_first_flag = false 
					LET p_rec_arparms.freight_acct_code = modu_rec_accounts.def_acct_code 
					DISPLAY BY NAME p_rec_arparms.freight_acct_code 
				ELSE 
					# User has cancelled entries
					LET modu_rec_accounts.* = l_rec_accounts.* 
				END IF 
			END IF 

		AFTER FIELD freight_acct_code 
			IF NOT check_prykey_exists_coa(glob_rec_kandoouser.cmpy_code,p_rec_arparms.freight_acct_code) THEN
				ERROR kandoomsg2("A",9052,"") 			#9052 "Freight Account NOT found, try window"
				NEXT FIELD freight_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,p_rec_arparms.freight_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD freight_acct_code 
			END IF 

		AFTER FIELD lab_acct_code 
			IF NOT check_prykey_exists_coa(glob_rec_kandoouser.cmpy_code,p_rec_arparms.lab_acct_code) THEN
				ERROR kandoomsg2("A",9053,"") 			#9053 "Handling Account NOT found, try again"
				NEXT FIELD lab_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,p_rec_arparms.lab_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD lab_acct_code 
			END IF 

		AFTER FIELD tax_acct_code 
			IF NOT check_prykey_exists_coa(glob_rec_kandoouser.cmpy_code,p_rec_arparms.tax_acct_code) THEN
				ERROR kandoomsg2("A",9054,"") 			#9054" Taxation Account NOT found, try wind"
				NEXT FIELD tax_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,p_rec_arparms.tax_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD tax_acct_code 
			END IF 
			
		AFTER FIELD disc_acct_code 
			IF NOT check_prykey_exists_coa(glob_rec_kandoouser.cmpy_code,p_rec_arparms.disc_acct_code) THEN
				ERROR kandoomsg2("A",9055,"") 				#9055 "Discount Account NOT found, try wind"
				NEXT FIELD disc_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,p_rec_arparms.disc_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD disc_acct_code 
			END IF 

		AFTER FIELD exch_acct_code 
			IF NOT check_prykey_exists_coa(glob_rec_kandoouser.cmpy_code,p_rec_arparms.exch_acct_code) THEN
				ERROR kandoomsg2("A",9056,"") 				#9056" Exchange Variance GL Account NOT found, try window"
				NEXT FIELD exch_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,p_rec_arparms.exch_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD exch_acct_code 
			END IF 
			
		AFTER FIELD int_acct_code 
			IF NOT check_prykey_exists_coa(glob_rec_kandoouser.cmpy_code,p_rec_arparmext.int_acct_code) THEN
				ERROR kandoomsg2("A",9219,"") 				#9219" Service Fee Income GL Account NOT found, try window"
				NEXT FIELD int_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,p_rec_arparmext.int_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD int_acct_code 
			END IF 

		AFTER FIELD writeoff_acct_code 
			IF NOT check_prykey_exists_coa(glob_rec_kandoouser.cmpy_code,p_rec_arparmext.writeoff_acct_code) THEN
				ERROR kandoomsg2("A",9307,"") 			#9307" Write Off GL Account NOT found, try window"
				NEXT FIELD writeoff_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,p_rec_arparmext.writeoff_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD writeoff_acct_code 
			END IF 
			
		AFTER FIELD currency_code 
			SELECT unique 1 FROM currency 
			WHERE currency_code = p_rec_arparms.currency_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9057,"") 			#9057" Currency NOT found, try window"
				NEXT FIELD currency_code 
			END IF 
			
		AFTER FIELD reason_code 
			IF NOT check_prykey_exists_credreas(glob_rec_kandoouser.cmpy_code,p_rec_arparms.reason_code) THEN
				IF p_rec_arparms.reason_code IS NOT NULL THEN 
					IF NOT check_prykey_exists_credreas(glob_rec_kandoouser.cmpy_code,p_rec_arparms.reason_code) THEN 
						ERROR kandoomsg2("A",9058,"") 				#9058 " Credit reason NOT found - Try Window"
						NEXT FIELD reason_code 
					END IF 
				END IF 
			END IF
		END INPUT 			
		
		IF int_flag OR quit_flag THEN
			LET int_flag = FALSE
			LET quit_flag = FALSE
			RETURN TRUE,p_rec_arparms.*,p_rec_arparmext.*
		ELSE
			RETURN FALSE,p_rec_arparms.*,p_rec_arparmext.*
		END IF

END FUNCTION # input_arparms()
##############################################################
# END FUNCTION input_arparms()
##############################################################


##############################################################
# FUNCTION input_and_update_ref_fields()
#
#
##############################################################
FUNCTION input_and_update_ref_fields(p_rec_arparms) 
	DEFINE p_rec_arparms RECORD LIKE arparms.*
	DEFINE l_rec_arparms_bckp RECORD LIKE arparms.*
	DEFINE l_seq_num SMALLINT 

	MESSAGE kandoomsg2("U",1070,"")	#1070 Enter Parameter details; OK TO continue.
	LET l_rec_arparms_bckp.* = p_rec_arparms.*   # save values before input
	
	INPUT BY NAME 
		p_rec_arparms.ref1_text, 
		p_rec_arparms.ref1_ind, 
		p_rec_arparms.ref2_text, 
		p_rec_arparms.ref2_ind, 
		p_rec_arparms.ref3_text, 
		p_rec_arparms.ref3_ind, 
		p_rec_arparms.ref4_text, 
		p_rec_arparms.ref4_ind, 
		p_rec_arparms.ref5_text, 
		p_rec_arparms.ref5_ind, 
		p_rec_arparms.ref6_text, 
		p_rec_arparms.ref6_ind, 
		p_rec_arparms.ref7_text, 
		p_rec_arparms.ref7_ind, 
		p_rec_arparms.ref8_text, 
		p_rec_arparms.ref8_ind, 
		p_rec_arparms.inv_ref1_text, 
		p_rec_arparms.inv_ref2a_text, 
		p_rec_arparms.inv_ref2b_text, 
		p_rec_arparms.credit_ref1_text, 
		p_rec_arparms.credit_ref2a_text, 
		p_rec_arparms.credit_ref2b_text WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZP","inp-arparms-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD ref1_text 
			LET l_seq_num = 1 

			IF p_rec_arparms.ref1_text IS NULL THEN 
				LET p_rec_arparms.ref1_ind = NULL 
			END IF 

			CALL display_arparms_record(p_rec_arparms.*)

		BEFORE FIELD ref1_ind 
			IF p_rec_arparms.ref1_text IS NULL THEN 
				IF l_seq_num > 1 THEN 
					NEXT FIELD ref1_text 
				ELSE 
					NEXT FIELD ref2_text 
				END IF 
			END IF 

		AFTER FIELD ref1_ind 
			IF p_rec_arparms.ref1_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref1_ind 
			END IF 

		AFTER FIELD ref2_text 
			LET l_seq_num = 2 
			IF p_rec_arparms.ref2_text IS NULL THEN 
				LET p_rec_arparms.ref2_ind = NULL 
			END IF 
			CALL display_arparms_record(p_rec_arparms.*) 

		BEFORE FIELD ref2_ind 
			IF p_rec_arparms.ref2_text IS NULL THEN 
				IF l_seq_num > 2 THEN 
					NEXT FIELD ref2_text 
				ELSE 
					NEXT FIELD ref3_text 
				END IF 
			END IF 

		AFTER FIELD ref2_ind 
			IF p_rec_arparms.ref2_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref2_ind 
			END IF 

		AFTER FIELD ref3_text 
			LET l_seq_num = 3 
			IF p_rec_arparms.ref3_text IS NULL THEN 
				LET p_rec_arparms.ref3_ind = NULL 
			END IF 

		BEFORE FIELD ref3_ind 
			IF p_rec_arparms.ref3_text IS NULL THEN 
				IF l_seq_num > 3 THEN 
					NEXT FIELD ref3_text 
				ELSE 
					NEXT FIELD ref4_text 
				END IF 
			END IF 

		AFTER FIELD ref3_ind 
			IF p_rec_arparms.ref3_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 	#9023" Validation Indicator must be Entered "
				NEXT FIELD ref3_ind 
			END IF 

		AFTER FIELD ref4_text 
			LET l_seq_num = 4 
			IF p_rec_arparms.ref4_text IS NULL THEN 
				LET p_rec_arparms.ref4_ind = NULL 
			END IF 

		BEFORE FIELD ref4_ind 
			IF p_rec_arparms.ref4_text IS NULL THEN 
				IF l_seq_num > 4 THEN 
					NEXT FIELD ref4_text 
				ELSE 
					NEXT FIELD ref5_text 
				END IF 
			END IF 

		AFTER FIELD ref4_ind 
			IF p_rec_arparms.ref4_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") #9023" Validation Indicator must be Entered "
				NEXT FIELD ref4_ind 
			END IF 

		AFTER FIELD ref5_text 
			LET l_seq_num = 5 
			IF p_rec_arparms.ref5_text IS NULL THEN 
				LET p_rec_arparms.ref5_ind = NULL 
			END IF 

		BEFORE FIELD ref5_ind 
			IF p_rec_arparms.ref5_text IS NULL THEN 
				IF l_seq_num > 5 THEN 
					NEXT FIELD ref5_text 
				ELSE 
					NEXT FIELD ref6_text 
				END IF 
			END IF 

		AFTER FIELD ref5_ind 
			IF p_rec_arparms.ref5_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") #9023" Validation Indicator must be Entered "
				NEXT FIELD ref5_ind 
			END IF 

		AFTER FIELD ref6_text 
			LET l_seq_num = 6 
			IF p_rec_arparms.ref6_text IS NULL THEN 
				LET p_rec_arparms.ref6_ind = NULL 
			END IF 

		BEFORE FIELD ref6_ind 
			IF p_rec_arparms.ref6_text IS NULL THEN 
				IF l_seq_num > 6 THEN 
					NEXT FIELD ref6_text 
				ELSE 
					NEXT FIELD ref7_text 
				END IF 
			END IF 

		AFTER FIELD ref6_ind 
			IF p_rec_arparms.ref6_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 	#9023" Validation Indicator must be Entered "
				NEXT FIELD ref6_ind 
			END IF 

		AFTER FIELD ref7_text 
			LET l_seq_num = 7 
			IF p_rec_arparms.ref7_text IS NULL THEN 
				LET p_rec_arparms.ref7_ind = NULL 
			END IF 

		BEFORE FIELD ref7_ind 
			IF p_rec_arparms.ref7_text IS NULL THEN 
				IF l_seq_num > 7 THEN 
					NEXT FIELD ref7_text 
				ELSE 
					NEXT FIELD ref8_text 
				END IF 
			END IF 

		AFTER FIELD ref7_ind 
			IF p_rec_arparms.ref7_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 	#9023" Validation Indicator must be Entered "
				NEXT FIELD ref7_ind 
			END IF 

		AFTER FIELD ref8_text 
			LET l_seq_num = 8 
			IF p_rec_arparms.ref8_text IS NULL THEN 
				LET p_rec_arparms.ref8_ind = NULL 
			END IF 

		BEFORE FIELD ref8_ind 
			IF p_rec_arparms.ref8_text IS NULL THEN 
				IF l_seq_num > 8 THEN 
					NEXT FIELD ref8_text 
				ELSE 
					NEXT FIELD inv_ref1_text 
				END IF 
			END IF 

		AFTER FIELD ref8_ind 
			IF p_rec_arparms.ref8_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") #9023" Validation Indicator must be Entered "
				NEXT FIELD ref8_ind 
			END IF 

		AFTER FIELD inv_ref1_text 
			LET l_seq_num = 9 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 1,l_rec_arparms_bckp.*
	ELSE 
		# UPDATE ---------------------------------------
		UPDATE arparms 
		SET 
			ref1_text = p_rec_arparms.ref1_text, 
			ref2_text = p_rec_arparms.ref2_text, 
			ref3_text = p_rec_arparms.ref3_text, 
			ref4_text = p_rec_arparms.ref4_text, 
			ref5_text = p_rec_arparms.ref5_text, 
			ref6_text = p_rec_arparms.ref6_text, 
			ref7_text = p_rec_arparms.ref7_text, 
			ref8_text = p_rec_arparms.ref8_text, 
			ref1_ind = p_rec_arparms.ref1_ind, 
			ref2_ind = p_rec_arparms.ref2_ind, 
			ref3_ind = p_rec_arparms.ref3_ind, 
			ref4_ind = p_rec_arparms.ref4_ind, 
			ref5_ind = p_rec_arparms.ref5_ind, 
			ref6_ind = p_rec_arparms.ref6_ind, 
			ref7_ind = p_rec_arparms.ref7_ind, 
			ref8_ind = p_rec_arparms.ref8_ind, 
			inv_ref1_text = p_rec_arparms.inv_ref1_text, 
			inv_ref2a_text = p_rec_arparms.inv_ref2a_text, 
			inv_ref2b_text = p_rec_arparms.inv_ref2b_text, 
			credit_ref1_text = p_rec_arparms.credit_ref1_text, 
			credit_ref2a_text = p_rec_arparms.credit_ref2a_text, 
			credit_ref2b_text = p_rec_arparms.credit_ref2b_text 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		IF sqlca.sqlcode = 0 THEN
			ERROR "Parameters of Accounts Receivable updated successfully"
			RETURN 0,p_rec_arparms.*
		ELSE
			ERROR "Update of Parameters of Accounts Receivable FAILED with errors"
			RETURN 1,l_rec_arparms_bckp.*
		END IF
	END IF 

END FUNCTION # input_and_update_ref_fields
##############################################################
# END FUNCTION input_and_update_ref_fields()
##############################################################

##############################################################
# FUNCTION display_arpams_arparmext_fields
#
#
##############################################################
FUNCTION display_arpams_arparmext_fields() 
--	DEFINE l_rec_arparms RECORD LIKE arparms.*
--	DEFINE l_rec_arparmext RECORD LIKE arparmext.*
--	DEFINE l_operation_status INTEGER
	
	CLEAR FORM 
	
--	INITIALIZE l_rec_arparmext.* TO NULL 

--	CALL arparmext_init() # AR/Account Receivable Parameters EXT (arparmext)
--	CALL arparms_init() # AR/Account Receivable Parameters (arparms)
	# FIXME: both functions are used just to check if the parameters exist or not -> we do not want to use the glob_rec vars in that program

--	CALL arparms_get_record("1") RETURNING l_operation_status,l_rec_arparms.*
--	CALL arparmext_get_record() RETURNING l_operation_status,l_rec_arparmext.*

	IF NOT db_arparms_parm_code_exist("1") THEN  #check, if it was already setup
	
		IF glob_rec_arparms.cust_age_date = "31/12/1899" THEN 
			LET glob_rec_arparms.cust_age_date = NULL 
		END IF 
		IF glob_rec_arparms.last_post_date = "31/12/1899" THEN 
			LET glob_rec_arparms.last_post_date = NULL 
		END IF 
		IF glob_rec_arparms.last_stmnt_date = "31/12/1899" THEN 
			LET glob_rec_arparms.last_stmnt_date = NULL 
		END IF 
	
		IF glob_rec_arparms.last_del_date = "31/12/1899" THEN 
			LET glob_rec_arparms.last_del_date = NULL 
		END IF 
	
		LET glob_rec_arparms.show_tax_flag = xlate_from(glob_rec_arparms.show_tax_flag) 
		LET glob_rec_arparms.gl_flag = xlate_from(glob_rec_arparms.gl_flag) 
		LET glob_rec_arparms.detail_to_gl_flag = xlate_from(glob_rec_arparms.detail_to_gl_flag) 
		LET glob_rec_arparms.show_seg_flag = xlate_from(glob_rec_arparms.show_seg_flag) 
	END IF
	
	DISPLAY BY NAME 
		glob_rec_arparms.sales_jour_code, 
		glob_rec_arparms.cash_jour_code, 
		glob_rec_arparms.cust_age_date, 
		glob_rec_arparms.last_post_date, 
		glob_rec_arparms.last_stmnt_date, 
		glob_rec_arparms.last_del_date, 
		glob_rec_arparms.ar_acct_code, 
		glob_rec_arparms.cash_acct_code, 
		glob_rec_arparms.freight_acct_code, 
		glob_rec_arparms.lab_acct_code, 
		glob_rec_arparms.tax_acct_code, 
		glob_rec_arparms.disc_acct_code, 
		glob_rec_arparms.exch_acct_code, 
		glob_rec_arparmext.last_int_date, 
		glob_rec_arparmext.int_acct_code, 
		glob_rec_arparmext.last_writeoff_date, 
		glob_rec_arparmext.writeoff_acct_code, 
		glob_rec_arparms.cred_amt, 
		glob_rec_arparms.currency_code, 
		glob_rec_arparms.reason_code, 
		glob_rec_arparms.stmnt_ind, 
		glob_rec_arparms.next_bank_dep_num, 
		glob_rec_arparms.corp_drs_flag, 
		glob_rec_arparms.show_tax_flag, 
		glob_rec_arparms.show_seg_flag, 
		glob_rec_arparms.gl_flag, 
		glob_rec_arparms.detail_to_gl_flag, 
		glob_rec_arparms.report_ord_flag, 
		glob_rec_arparms.consolidate_flag 

--	RETURN l_operation_status,l_rec_arparms.*,l_rec_arparmext.*
 
END FUNCTION  #  display_arpams_arparmext_fields
##############################################################
# END FUNCTION display_arpams_arparmext_fields
##############################################################


##############################################################
# FUNCTION display_arparms_record(l_rec_arparms)
#
#
##############################################################
FUNCTION display_arparms_record(p_rec_arparms) 
	DEFINE p_rec_arparms RECORD LIKE arparms.*
	DISPLAY BY NAME 
		p_rec_arparms.ref1_text, 
		p_rec_arparms.ref2_text, 
		p_rec_arparms.ref3_text, 
		p_rec_arparms.ref4_text, 
		p_rec_arparms.ref5_text, 
		p_rec_arparms.ref6_text, 
		p_rec_arparms.ref7_text, 
		p_rec_arparms.ref8_text, 
		p_rec_arparms.ref1_ind, 
		p_rec_arparms.ref2_ind, 
		p_rec_arparms.ref3_ind, 
		p_rec_arparms.ref4_ind, 
		p_rec_arparms.ref5_ind, 
		p_rec_arparms.ref6_ind, 
		p_rec_arparms.ref7_ind, 
		p_rec_arparms.ref8_ind, 
		p_rec_arparms.inv_ref1_text, 
		p_rec_arparms.inv_ref2a_text, 
		p_rec_arparms.inv_ref2b_text, 
		p_rec_arparms.credit_ref1_text, 
		p_rec_arparms.credit_ref2a_text, 
		p_rec_arparms.credit_ref2b_text 

END FUNCTION # display_arparms_record
##############################################################
# END FUNCTION display_arparms_record(l_rec_arparms)
##############################################################


##############################################################
# FUNCTION update_customertype()
#
#
##############################################################
FUNCTION update_customertype(p_rec_arparms) 
	DEFINE p_rec_arparms RECORD LIKE arparms.*
	DEFINE l_rec_customertype RECORD LIKE customertype.*
	DEFINE l_query_text STRING
	DEFINE l_type_code LIKE customertype.type_code
	DEFINE crs_customertype CURSOR

	LET l_query_text = 
		"SELECT type_code,*",
		" FROM customertype ",
		" WHERE cmpy_code = ? "

	CALL crs_customertype.Declare(l_query_text)
	CALL crs_customertype.Open(glob_rec_kandoouser.cmpy_code)

	WHILE crs_customertype.FetchNext(l_type_code,l_rec_customertype.*)
		# FIXME: not sure I understand this test ..... if they are simimar, why set the same values?
		IF l_rec_customertype.ar_acct_code = p_rec_arparms.ar_acct_code THEN 
			LET l_rec_customertype.ar_acct_code = p_rec_arparms.ar_acct_code 
		END IF 
		IF l_rec_customertype.freight_acct_code = p_rec_arparms.freight_acct_code THEN 
			LET l_rec_customertype.freight_acct_code = p_rec_arparms.freight_acct_code 
		END IF 
		IF l_rec_customertype.lab_acct_code = p_rec_arparms.lab_acct_code THEN 
			LET l_rec_customertype.lab_acct_code = p_rec_arparms.lab_acct_code 
		END IF 
		IF l_rec_customertype.tax_acct_code = p_rec_arparms.tax_acct_code THEN 
			LET l_rec_customertype.tax_acct_code = p_rec_arparms.tax_acct_code 
		END IF 
		IF l_rec_customertype.disc_acct_code = p_rec_arparms.disc_acct_code THEN 
			LET l_rec_customertype.disc_acct_code = p_rec_arparms.disc_acct_code 
		END IF 
		IF l_rec_customertype.exch_acct_code = p_rec_arparms.exch_acct_code THEN 
			LET l_rec_customertype.exch_acct_code = p_rec_arparms.exch_acct_code 
		END IF 

		UPDATE customertype 
		SET * = l_rec_customertype.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = l_type_code 
	END WHILE 

END FUNCTION  #  update_customertype
##############################################################
# END FUNCTION update_customertype()
##############################################################