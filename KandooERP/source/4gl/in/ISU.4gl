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
###########################################################################

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_inparms RECORD LIKE inparms.* 
DEFINE modu_ret_year SMALLINT
DEFINE modu_date_stop DATE
DEFINE modu_year_num SMALLINT 
DEFINE modu_period_num SMALLINT
DEFINE modu_time_char CHAR(8) 
DEFINE modu_err_counter INTEGER 
DEFINE modu_counter INTEGER

############################################################
# FUNCTION ISU_main()
#
# Purpose - Inventory Transaction Purge by Fiscal Year
############################################################
FUNCTION ISU_main()

	CALL setModuleId("ISU") 

	#TODO replace with global_rec_inparms when FUNCTION init_i_in will be finished
	SELECT * INTO modu_rec_inparms.* 
	FROM inparms 
	WHERE inparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inparms.parm_code = "1"
	IF STATUS = NOTFOUND THEN 
		CALL msgerror("","Inventory Parameters are not set up.\n                Refer Menu IZP.")
		#LET msgresp = kandoomsg("I",5002,"") 
		#5002 In Parameters NOT SET up refer TO menu IZP
		EXIT PROGRAM
	END IF

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I661 WITH FORM "I661" 
			 CALL windecoration_i("I661")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Inventory Transaction Purge" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ISU","menu-Purge_Product-1") -- albo kd-505
					CALL fgl_dialog_setactionlabel("Begin purge","Begin purge","{CONTEXT}/public/querix/icon/svg/24/ic_done_24px.svg",2,FALSE,"Enter selection criteria and begin purge.")
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Begin purge" --" Enter selection criteria AND begin purge."
					LET modu_ret_year = NULL 
					LET modu_time_char = NULL 
					LET modu_date_stop = TODAY + 1
					CALL rpt_rmsreps_reset(NULL)
					CALL ISU_rpt_process(ISU_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I661

		WHEN "2" #Background Process with rmsreps.report_code
			CALL ISU_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I661 with FORM "I661" 
			 CALL windecoration_i("I661") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ISU_rpt_query()) #save where clause in env 
			CLOSE WINDOW I661 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL ISU_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION
############################################################
# END FUNCTION ISU_main()
############################################################  

############################################################
# FUNCTION ISU_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION ISU_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
	DEFINE l_backup_flag CHAR(1) 
	DEFINE l_update_flag CHAR(1)
	DEFINE l_user_flag CHAR(1)	
	DEFINE l_auth_flag CHAR(1)
	DEFINE l_time_stop SMALLINT 
	DEFINE l_time_char5 CHAR(5) 
	DEFINE l_msgresp LIKE language.yes_flag

	LET l_time_stop = 0600 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,TODAY) 
	RETURNING modu_year_num, modu_period_num 

	MESSAGE " Enter details; OK to continue."

	CLEAR FORM 
	DIALOG ATTRIBUTES(UNBUFFERED)

		INPUT 
		modu_ret_year, 
		modu_date_stop, 
		l_time_stop WITHOUT DEFAULTS
		FROM
		ret_year, 
		date_stop, 
		time_stop

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","ISU","input-pr_ret_year-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD ret_year 
				IF modu_ret_year IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD ret_year 
				END IF 
				IF modu_ret_year > modu_year_num THEN 
					ERROR kandoomsg2("U",9046,modu_year_num) 
					#9046 Value must be less than OR equal TO ????
					NEXT FIELD ret_year 
				END IF 
				IF modu_ret_year < 1988 THEN 
					ERROR kandoomsg2("G",9529,"1987") 
					#9529 Year entered must be greater THEN 1987
					NEXT FIELD ret_year
				END IF
				IF modu_year_num = modu_ret_year THEN 
					MESSAGE kandoomsg2("I",6001,"") 
					#6001 Less than a years worth of prodledg will be left
				END IF 

			AFTER FIELD date_stop 
				IF modu_date_stop IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD date_stop 
				END IF 
				IF modu_date_stop < TODAY THEN 
					ERROR kandoomsg2("U",9907,TODAY) 
					#9907 Value must be greater than OR equal TO TODAY
					NEXT FIELD date_stop 
				END IF 

			AFTER FIELD time_stop 
				IF l_time_stop IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD time_stop 
				END IF 
				IF l_time_stop < 0 THEN 
					LET l_time_stop = -l_time_stop
				END IF 
				IF l_time_stop > 2400 THEN 
					ERROR kandoomsg2("W",9449,"") 
					#9449 Time IS NOT in 24 hour FORMAT.
					NEXT FIELD time_stop 
				ELSE
					IF l_time_stop = 2400 THEN
						LET l_time_stop = 2359
					END IF				
				END IF 
				LET modu_time_char = l_time_stop USING "&&&&" 
				IF modu_time_char[3,4] > 59 THEN 
					ERROR kandoomsg2("W",9449,"") 
					#9449 Time IS NOT in 24 hour FORMAT.
					NEXT FIELD time_stop 
				END IF 
				LET modu_time_char = modu_time_char[1,2],":",modu_time_char[3,4],":00" 
				IF modu_time_char < TIME 
				AND modu_date_stop = TODAY THEN 
					LET l_time_char5 = TIME 
					ERROR kandoomsg2("U",9907,l_time_char5) 
					#9907 Value must be greater than OR equal TO current TIME
					NEXT FIELD time_stop 
				END IF 

			AFTER INPUT 
				IF int_flag = 0 AND quit_flag = 0 THEN 
					IF modu_ret_year IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD ret_year 
					END IF 
					IF modu_date_stop IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD date_stop 
					END IF 
					IF l_time_stop IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD time_stop 
					END IF 
					LET modu_time_char = l_time_stop USING "&&&&" 
					IF modu_time_char[3,4] > 59 THEN 
						ERROR kandoomsg2("W",9449,"") 
						#9449 Time IS NOT in 24 hour FORMAT.
						NEXT FIELD time_stop 
					END IF 
					LET modu_time_char = modu_time_char[1,2],":",modu_time_char[3,4],":00" 
					IF modu_time_char < TIME 
					AND modu_date_stop = TODAY THEN 
						LET l_time_char5 = TIME 
						ERROR kandoomsg2("U",9907,l_time_char5) 
						#9907 Value must be greater than OR equal TO current TIME
						NEXT FIELD time_stop 
					END IF
				END IF 

		END INPUT 

		CONSTRUCT BY NAME r_where_text ON
		prodstatus.ware_code, 
		product.part_code, 
		product.desc_text, 
		maingrp_code, 
		prodgrp_code, 
		cat_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ISU","construct-prodstatus-1") -- albo kd-505 

		END CONSTRUCT 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "ACCEPT" 
			ACCEPT DIALOG
			
		ON ACTION "CANCEL" 
			EXIT DIALOG

	END DIALOG

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	END IF 

	OPEN WINDOW I662 with FORM "I662" 
	 CALL windecoration_i("I662") -- albo kd-758 
	MESSAGE kandoomsg2("U",1020,"Confirmation") 
	#1020 Enter Confirmation Details
	INPUT 
	l_backup_flag, 
	l_update_flag, 
	l_user_flag, 
	l_auth_flag 
	FROM
	backup_flag, 
	update_flag, 
	user_flag, 
	auth_flag

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ISU","input-pr_backup_flag-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT
				IF int_flag = 0 AND quit_flag = 0 THEN 
					IF l_backup_flag IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD backup_flag 
					END IF 
					IF l_update_flag IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD update_flag 
					END IF 
					IF l_user_flag IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD user_flag 
					END IF 
					IF l_auth_flag IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD auth_flag 
					END IF 
				END IF

	END INPUT 
	CLOSE WINDOW I662

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	END IF 

	IF l_backup_flag = "N" 
	OR l_update_flag = "Y" 
	OR l_user_flag = "N" 
	OR l_auth_flag = "N" THEN 
		CALL msgcontinue("","Please re-run this program after you have completed all the steps and  have the authority to run the purge.") 
		#MESSAGE kandoomsg2("U",7008,"") 
		#7008 Complete Steps AND Get Authority THEN rerun program.
		EXIT PROGRAM 
	ELSE
		RETURN r_where_text
	END IF 

END FUNCTION 
############################################################
# END FUNCTION ISU_rpt_query() 
############################################################

############################################################
# FUNCTION ISU_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION ISU_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx_1 SMALLINT
	DEFINE l_rpt_idx_2 SMALLINT
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_cnt INTEGER
	DEFINE l_reason CHAR(50) 
	DEFINE l_err_message CHAR(70) 
	DEFINE l_msg CHAR(70)
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_time CHAR(15) 
	DEFINE l_interrupt SMALLINT 
	DEFINE l_prodledg_count INTEGER
	DEFINE l_cost_amt LIKE prodledg.cost_amt
	DEFINE l_tran_qty LIKE prodledg.tran_qty 
	DEFINE l_msgresp LIKE language.yes_flag

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx_1 = rpt_start(getmoduleid(),"ISU_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx_1 = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF
	
	LET l_rpt_idx_2 = rpt_start(trim(getmoduleid())||".","ISU_rpt_list_purge_exception",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx_2 = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT ISU_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx_1)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].report_width_num

	START REPORT ISU_rpt_list_purge_exception TO rpt_get_report_file_with_path2(l_rpt_idx_2)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatus.* FROM prodstatus,product ", 
	"WHERE prodstatus.cmpy_code = product.cmpy_code ", 
	"AND product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.part_code = prodstatus.part_code ", 
	"AND ",p_where_text CLIPPED," ", 
	"ORDER BY prodstatus.part_code,prodstatus.ware_code" 

	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_prodstatus CURSOR WITH HOLD FOR s_prodstatus 

	LET l_msg = "Product Ledger Purge started by ",glob_rec_kandoouser.sign_on_code 
	CALL errorlog(l_msg) 

	LET modu_counter = 0 
	LET modu_err_counter = 0 
	LET l_interrupt = 0 
	
	FOREACH c_prodstatus INTO l_rec_prodstatus.* 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET l_time = TIME 
			IF modu_time_char <= l_time 
			AND modu_date_stop <= TODAY THEN 
				LET l_msg = "Purge terminated by time limit. Rows Deleted: ", 
				modu_counter USING "<<<<<<&", " Errors: ", 
				modu_err_counter USING "<<<<<<&" 
				LET l_interrupt = 1 
				EXIT FOREACH 
			END IF 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE product.part_code = l_rec_prodstatus.part_code 
			AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF STATUS = NOTFOUND THEN 
				LET l_reason = "This product does NOT exist." 
				OUTPUT TO REPORT ISU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_prodstatus.*,l_reason) 
				ROLLBACK WORK 
				CONTINUE FOREACH 
			END IF 
			IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodstatus.part_code,"",l_rpt_idx_1) THEN
				LET l_msg = "Purge terminated by CANCEL key. Rows Deleted: ", 
				modu_counter USING "<<<<<<&", " Errors: ", 
				modu_err_counter USING "<<<<<<&" 
				LET l_interrupt = 2
				EXIT FOREACH 
			END IF
			IF modu_rec_inparms.gl_post_flag = "Y" THEN 
				SELECT COUNT(*) INTO l_cnt FROM prodledg 
				WHERE prodledg.part_code = l_rec_prodstatus.part_code 
				AND prodledg.ware_code = l_rec_prodstatus.ware_code 
				AND prodledg.post_flag != "Y" 
				AND prodledg.year_num < modu_ret_year 
				AND prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_cnt <> 0 THEN 
					LET l_reason = "This product ledger entry has NOT been posted." 
					OUTPUT TO REPORT ISU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_prodstatus.*,l_reason) 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
			END IF 
			SELECT COUNT(*), SUM(prodledg.tran_qty), SUM(prodledg.cost_amt) 
			INTO l_prodledg_count, l_tran_qty, l_cost_amt FROM prodledg 
			WHERE prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND prodledg.year_num < modu_ret_year 
			AND prodledg.part_code = l_rec_prodstatus.part_code 
			AND prodledg.trantype_ind != "W" 
			AND prodledg.trantype_ind != "U" 
			AND prodledg.trantype_ind IS NOT NULL 
			AND prodledg.ware_code = l_rec_prodstatus.ware_code 
			GOTO bypass 
			LABEL recovery: 
			CASE 
				WHEN STATUS = -107 {record IS locked} 
					OR STATUS = -113 {the file IS locked} 
					OR STATUS = -115 {cannot CREATE LOCK file} 
					OR STATUS = -134 {no more locks} 
					OR STATUS = -143 {deadlock detected} 
					OR STATUS = -144 {key value locked} 
					OR STATUS = -154 {deadlock timeout expired} 
					OR STATUS = -78 {deadlock situation detected/avoided} 
					OR STATUS = -79 {no RECORD locks available} 
					OR STATUS = -233 {record loced BY another user} 
					OR STATUS = -250 {cannot read RECORD FROM file FOR update} 
					OR STATUS = -263 {cannot LOCK ROW FOR update} 
					OR STATUS = -288 {table NOT locked BY CURRENT user} 
					OR STATUS = -289 {cannot LOCK TABLE in requested mode} 
					OR STATUS = -291 {cannot change LOCK MODE OF table} 
					OR STATUS = -327 {cannot UNLOCK TABLE within a transaction.} 
					OR STATUS = -378 {record currently locked BY another user.} 
					OR STATUS = -503 {too many tables locked.} 
					OR STATUS = -504 {cannot LOCK a view.} 
					OR STATUS = -521 {cannot LOCK system catalog.} 
					OR STATUS = -563 {cannot acquire ex LOCK FOR db conversion} 
					OR STATUS = -621 {unable TO UPDATE new LOCK level.} 
					OR STATUS = -3011 {a TABLE IS locked no reading OR writing} 
					OR STATUS = -3460 {this ROW has been locked BY another user} 
					LET l_msg = "Database Lock Error. Rows Deleted: ", 
					modu_counter USING "<<<<<<&", " Errors: ", 
					modu_err_counter USING "<<<<<<&" 
					LET l_interrupt = 3 
					EXIT FOREACH 
				WHEN STATUS = -104 
					LET l_msg = "Too many files OPEN under unix. Rows Deleted: ", 
					modu_counter USING "<<<<<<&", " Errors: ", 
					modu_err_counter USING "<<<<<<&" 
					LET l_interrupt = 3 
					EXIT FOREACH 
				WHEN STATUS = -349 
					OR STATUS = -457 
					LET l_msg = "Informix Online Terminated. Rows Deleted: ", 
					modu_counter USING "<<<<<<&", " Errors: ", 
					modu_err_counter USING "<<<<<<&" 
					LET l_interrupt = 3 
					EXIT FOREACH 
				OTHERWISE 
					LET l_reason = "Database Error Occured. Status: ",STATUS 
					OUTPUT TO REPORT ISU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_prodstatus.*,l_reason) 
					ROLLBACK WORK 
					CONTINUE FOREACH 
			END CASE 
			LABEL bypass: 
			IF l_prodledg_count > 0 THEN
				IF l_tran_qty IS NULL THEN 
					LET l_reason = "This product has a NULL transaction quantity." 
					OUTPUT TO REPORT ISU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_prodstatus.*,l_reason) 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				IF l_cost_amt IS NULL THEN 
					LET l_reason = "This product has a NULL cost amount." 
					OUTPUT TO REPORT ISU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_prodstatus.*,l_reason) 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				LOCK TABLE prodledg IN EXCLUSIVE MODE 
				LET l_err_message = "DELETE FROM prodledg failed" 
				DELETE FROM prodledg 
				WHERE prodledg.part_code = l_rec_prodstatus.part_code 
				AND prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodledg.ware_code = l_rec_prodstatus.ware_code 
				AND prodledg.year_num < modu_ret_year 
				LET l_prodledg_count = SQLCA.SQLERRD[3] 
				INITIALIZE l_rec_prodledg.* TO NULL 
				LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_prodledg.part_code = l_rec_prodstatus.part_code 
				LET l_rec_prodledg.ware_code = l_rec_prodstatus.ware_code 
				SELECT (MIN(seq_num) - 1) INTO l_rec_prodledg.seq_num FROM prodledg 
				WHERE prodledg.part_code = l_rec_prodstatus.part_code 
				AND prodledg.ware_code = l_rec_prodstatus.ware_code 
				AND prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_prodledg.seq_num IS NULL THEN 
					LET l_rec_prodledg.seq_num = 1 
				END IF 
				LET l_rec_prodledg.trantype_ind = "A" 
				LET l_rec_prodledg.year_num = modu_ret_year - 1 
				SELECT MAX(period.period_num) INTO l_rec_prodledg.period_num FROM period 
				WHERE period.year_num = l_rec_prodledg.year_num 
				AND period.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_prodledg.period_num IS NULL THEN 
					LET l_msg = "Year/Period are NOT setup FOR Year: ",modu_ret_year - 1 
					LET l_interrupt = 4 
					ROLLBACK WORK 
					EXIT FOREACH 
				END IF 
				SELECT period.end_date INTO l_rec_prodledg.tran_date FROM period 
				WHERE period.year_num = l_rec_prodledg.year_num 
				AND period.period_num = l_rec_prodledg.period_num 
				AND period.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_prodledg.source_text = "Purge" 
				LET l_rec_prodledg.source_num = 0 
				LET l_rec_prodledg.sales_amt = 0 
				LET l_rec_prodledg.hist_flag = NULL 
				LET l_rec_prodledg.post_flag = "Y" 
				LET l_rec_prodledg.jour_num = 0 
				LET l_rec_prodledg.desc_text = "Purge Entry (",TODAY,")" 
				SELECT category.stock_acct_code INTO l_rec_prodledg.acct_code FROM category 
				WHERE category.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND category.cat_code = l_rec_product.cat_code 
				IF STATUS = NOTFOUND THEN 
					LET l_rec_prodledg.acct_code = NULL 
				END IF 
				LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_prodledg.entry_date = l_rec_prodledg.tran_date 
				LET l_rec_prodledg.cost_amt = l_cost_amt / l_prodledg_count 
				LET l_rec_prodledg.tran_qty = l_tran_qty 
				LET l_rec_prodledg.bal_amt = l_rec_prodledg.tran_qty 
				LET l_err_message = "Insert TO prodledg failed" 
				INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
				LET modu_counter = modu_counter + l_prodledg_count 
				OUTPUT TO REPORT ISU_rpt_list(l_rpt_idx_1,l_rec_prodledg.*,l_prodledg_count,l_rec_product.desc_text) 
			END IF 
			
		COMMIT WORK
		 
		LET l_msg = "Purge Succesfully Completed. Rows Deleted: ", 
		modu_counter USING "<<<<<<&", " Errors: ", 
		modu_err_counter USING "<<<<<<&" 

	END FOREACH 

	WHENEVER ERROR stop 
		CASE l_interrupt 
			WHEN 0 
				IF modu_err_counter THEN 
					LET l_msgresp = kandoomsg("I",7006,modu_err_counter) 
					#7027 Purge completed with exceptions
				ELSE 
					LET l_msgresp = kandoomsg("U",7023,modu_counter) 
					#7008 Purge Succesfully Completed.
				END IF 
			WHEN 1 
				LET l_msgresp = kandoomsg("U",7024,modu_counter) 
				#7007 Purge terminated by time limit.
			WHEN 2 
				LET l_msgresp = kandoomsg("U",7025,modu_counter) 
				#7006 Purge terminated by Cancel Key.
			WHEN 3 
				LET l_msgresp = kandoomsg("U",7009,modu_counter) 
				#7009 Purge terminated by database lock.
			WHEN 4 
				LET l_msgresp = kandoomsg("U",7026,modu_ret_year-1) 
				#7053 Year/Period NOT SET up.
		END CASE 
	CALL errorlog(l_msg) 

	#------------------------------------------------------------
	FINISH REPORT ISU_rpt_list
	CALL rpt_finish("ISU_rpt_list")
	FINISH REPORT ISU_rpt_list_purge_exception
	RETURN rpt_finish("ISU_rpt_list_purge_exception")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION ISU_rpt_process() 
############################################################

############################################################
# REPORT ISU_rpt_list_purge_exception(p_rpt_idx,p_prodstatus,p_reason)
#
# Report Definition/Layout
############################################################
REPORT ISU_rpt_list_purge_exception(p_rpt_idx,p_prodstatus,p_reason)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_prodstatus RECORD LIKE prodstatus.* 
	DEFINE p_reason CHAR(50) 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			IF PAGENO > 1 THEN SKIP 1 LINE END IF
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	ON EVERY ROW 
		PRINT 
		COLUMN 01,p_prodstatus.part_code CLIPPED, 
		COLUMN 18,p_prodstatus.ware_code CLIPPED, 
		COLUMN 23,p_reason CLIPPED 
		LET modu_err_counter = modu_err_counter + 1 

	ON LAST ROW 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
############################################################
# END REPORT ISU_rpt_list_purge_exception()  
############################################################

############################################################
# REPORT ISU_rpt_list(p_rpt_idx,p_rec_prodledg,l_delete_count,p_prod_desc)
#
# Report Definition/Layout
############################################################
REPORT ISU_rpt_list(p_rpt_idx,p_rec_prodledg,l_delete_count,p_prod_desc)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE p_prod_desc LIKE product.desc_text
	DEFINE l_delete_count INTEGER 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			IF PAGENO > 1 THEN SKIP 1 LINE END IF
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			
	ON EVERY ROW 
		PRINT 
		COLUMN 01, p_rec_prodledg.ware_code CLIPPED, 
		COLUMN 07, p_rec_prodledg.part_code CLIPPED, 
		COLUMN 23, p_prod_desc CLIPPED, 
		COLUMN 60, l_delete_count USING "#####&" 
			
	ON LAST ROW 
		SKIP 1 LINE 
		PRINT COLUMN 58,"--------" 
		PRINT COLUMN 17,"Total number of deleted product ledgers: ",modu_counter USING "#######&" 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			

END REPORT
############################################################
# END REPORT ISU_rpt_list()  
############################################################
