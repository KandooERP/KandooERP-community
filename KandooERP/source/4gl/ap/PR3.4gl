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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
############################################################
# Global Scope
#
#
############################################################
GLOBALS 
--	DEFINE glob_where_part STRING -- CHAR(2048)
	DEFINE glob_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE glob_temp_start_year SMALLINT 
	DEFINE glob_temp_end_year SMALLINT
	DEFINE glob_temp_start_period SMALLINT
	DEFINE glob_temp_end_period SMALLINT 
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	#Initial UI Init
	CALL setModuleId("PR3") 
	CALL ui_init(0) 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW P165 with FORM "P165" 
			CALL windecoration_p("P165") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Audit Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PR3","menu-audit_rep-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PR3_rpt_process(PR3_rpt_query())
							
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PR3_rpt_process(PR3_rpt_query()) 
		
				ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

		
				ON ACTION "CANCEL"			#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW P165
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PR3_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P165 with FORM "P165" 
			CALL windecoration_p("P165") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PR3_rpt_query()) #save where clause in env 
			CLOSE WINDOW P165 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PR3_rpt_process(get_url_sel_text())
	END CASE
END MAIN 


############################################################
# FUNCTION PR3_rpt_query()
#
#
############################################################
FUNCTION PR3_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_query_text CHAR(2200)


--	DEFINE l_msgresp LIKE language.yes_flag 


	WHENEVER ERROR CONTINUE 
	DROP TABLE credaudit 
	WHENEVER ERROR stop 
	CREATE temp TABLE credaudit (vend_code CHAR(9), 
	tran_date DATE, 
	trantype_ind CHAR(2), 
	source_num INTEGER, 
	inv_text CHAR(20), 
	tran_amt DECIMAL(16,2), 
	apply_amt DECIMAL(16,2), 
	pay_type CHAR(2), 
	pay_num integer) with no LOG 
	CREATE INDEX i_credaudit ON credaudit(source_num, pay_num) 
	CLEAR FORM 
	
	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter criteria FOR selection - press ESC TO begin REPORT
	CONSTRUCT BY NAME l_where_text ON apaudit.vend_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PR3","construct-apaudit-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 


	INPUT 
		glob_temp_start_year, 
		glob_temp_start_period, 
		glob_temp_end_year, 
		glob_temp_end_period WITHOUT DEFAULTS
	FROM 
		temp_start_year, 
		temp_start_period, 
		temp_end_year, 
		temp_end_period	ATTRIBUTE(UNBUFFERED)
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PR3","inp-period-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD temp_start_year 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
			RETURNING glob_temp_start_year, 	glob_temp_start_period 
			LET glob_temp_start_period = 1
			 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
			RETURNING glob_temp_end_year, 		glob_temp_end_period 

			DISPLAY
				glob_temp_start_year, 
				glob_temp_start_period, 
				glob_temp_end_year, 
				glob_temp_end_period 
      TO
	      temp_start_year, 
				temp_start_period, 
				temp_end_year, 
				temp_end_period

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				CASE 
					WHEN glob_temp_start_year IS NULL 
						ERROR "You must INPUT a value FOR the start year" 
						NEXT FIELD temp_start_year 
					WHEN glob_temp_start_period IS NULL 
						ERROR "You must INPUT a value FOR the start period" 
						NEXT FIELD temp_start_period 
					WHEN glob_temp_end_year IS NULL 
						ERROR "You must INPUT a value FOR the END year" 
						NEXT FIELD temp_end_year 
					WHEN glob_temp_start_period IS NULL 
						ERROR "You must INPUT a value FOR the END period" 
						NEXT FIELD temp_start_period 
				END CASE 

				IF glob_temp_end_year - glob_temp_start_year > 1 THEN 
					ERROR "You can only inquire over a maximum two year period" 
					NEXT FIELD temp_start_year 
				END IF 
			END IF 



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_num = glob_temp_start_year 
		LET glob_rec_rpt_selector.ref2_num = glob_temp_start_period 
		LET glob_rec_rpt_selector.ref3_num = glob_temp_end_year 
		LET glob_rec_rpt_selector.ref4_num = glob_temp_end_period 

		RETURN l_where_text 
	END IF 			
END FUNCTION 


############################################################
# FUNCTION PR3_rpt_process()
#
#
############################################################
FUNCTION PR3_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_query_text STRING
	DEFINE l_rec_credaudit RECORD 
		vend_code LIKE apaudit.vend_code, 
		tran_date LIKE apaudit.tran_date, 
		trantype_ind LIKE apaudit.trantype_ind, 
		source_num LIKE apaudit.source_num, 
		inv_text LIKE voucher.inv_text, 
		tran_amt LIKE apaudit.tran_amt, 
		apply_amt LIKE voucherpays.apply_amt, 
		pay_type CHAR(2), 
		pay_num LIKE voucherpays.pay_num 
	END RECORD 
	DEFINE l_try_again CHAR(1)	
	DEFINE l_err_message CHAR(60)	
	DEFINE l_temp_apply_amt LIKE voucherpays.apply_amt
	DEFINE l_temp_pay_num LIKE voucherpays.pay_num
	DEFINE l_temp_pay_type_code LIKE voucherpays.pay_type_code
	DEFINE l_temp_disc_amt LIKE voucherpays.disc_amt
	DEFINE l_insert_flag SMALLINT	
	DEFINE l_rec_debithead RECORD LIKE debithead.*
	DEFINE l_rec_cheque RECORD LIKE cheque.*	
	DEFINE l_rec_voucher RECORD LIKE voucher.*
	DEFINE l_pay_meth_ind LIKE cheque.pay_meth_ind
		
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PR3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PR3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET glob_temp_start_year = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 
	LET glob_temp_start_period = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num 
	LET glob_temp_end_year = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_num 
	LET glob_temp_end_period = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_num 
	#------------------------------------------------------------	

	IF glob_temp_start_year = glob_temp_end_year THEN 
		LET l_query_text = " SELECT * FROM apaudit ", 
		" WHERE apaudit.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" ((apaudit.year_num >= ",glob_temp_start_year," AND ", 
		" apaudit.period_num >= ",glob_temp_start_period,") ", 
		" AND (apaudit.year_num <= ",glob_temp_end_year," AND ", 
		" apaudit.period_num <= ",glob_temp_end_period,")) ", 
		" AND apaudit.trantype_ind <> \"CH\" AND ", 
		" apaudit.trantype_ind <> \"CC\" AND ", 
		" apaudit.trantype_ind <> \"PP\" AND ", 
		" apaudit.trantype_ind <> \"DB\" AND ", 
		p_where_text clipped, 
		" ORDER BY apaudit.cmpy_code, apaudit.tran_date, ", 
		" apaudit.seq_num, apaudit.source_num " 
	ELSE 
		LET l_query_text = " SELECT * FROM apaudit ", 
		" WHERE apaudit.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" ((apaudit.year_num >= ",glob_temp_start_year," AND ", 
		" apaudit.period_num >= ",glob_temp_start_period,") ", 
		" OR (apaudit.year_num <= ",glob_temp_end_year," AND ", 
		" apaudit.period_num <= ",glob_temp_end_period,")) ", 
		" AND apaudit.trantype_ind <> \"CH\" AND ", 
		" apaudit.trantype_ind <> \"CC\" AND ", 
		" apaudit.trantype_ind <> \"PP\" AND ", 
		" apaudit.trantype_ind <> \"DB\" AND ", 
		p_where_text clipped, 
		" ORDER BY apaudit.cmpy_code, apaudit.tran_date, ", 
		" apaudit.seq_num, apaudit.source_num " 
	END IF 
	DELETE FROM credaudit 
	WHERE 1=1 

	PREPARE choice FROM l_query_text 
	DECLARE dledg CURSOR FOR choice 
	INITIALIZE l_rec_credaudit.* TO NULL 
	GOTO bypass 
	LABEL recovery: 
	LET l_try_again = error_recover(l_err_message, status) 
	IF l_try_again = "N" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 

	BEGIN WORK 

		FOREACH dledg INTO glob_rec_apaudit.* 
			IF glob_rec_apaudit.tran_text = "Edit Voucher" THEN 
				LET l_err_message = "PR3 - first credaudit UPDATE " 
				UPDATE credaudit 
				SET tran_amt = credaudit.tran_amt + glob_rec_apaudit.tran_amt 
				WHERE source_num = glob_rec_apaudit.source_num 
			ELSE 
				IF glob_rec_apaudit.trantype_ind = "TF" AND glob_rec_apaudit.tran_amt > 0 THEN
				 
					SELECT * INTO l_rec_voucher.* FROM voucher 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = glob_rec_apaudit.vend_code 
					AND vouch_code = glob_rec_apaudit.source_num 
					LET l_err_message = "PR3 - second credaudit UPDATE " 
					UPDATE credaudit 
					SET tran_amt = credaudit.tran_amt - glob_rec_apaudit.tran_amt 
					WHERE source_num = l_rec_voucher.split_from_num 
				END IF 
				LET l_rec_credaudit.vend_code = glob_rec_apaudit.vend_code 
				LET l_rec_credaudit.tran_date = glob_rec_apaudit.tran_date 
				LET l_rec_credaudit.trantype_ind = glob_rec_apaudit.trantype_ind 
				LET l_rec_credaudit.source_num = glob_rec_apaudit.source_num 
				LET l_rec_credaudit.tran_amt = glob_rec_apaudit.tran_amt 
				SELECT inv_text INTO l_rec_credaudit.inv_text 
				FROM voucher 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vouch_code = glob_rec_apaudit.source_num 
				IF glob_rec_apaudit.trantype_ind = "TF" AND 
				glob_rec_apaudit.tran_amt < 0 THEN 
					LET l_insert_flag = 0 
				ELSE 
					LET l_insert_flag = 0 
					DECLARE vpayscurs1 CURSOR FOR 
					SELECT voucherpays.apply_amt, 
					voucherpays.pay_num, 
					voucherpays.pay_type_code 
					INTO l_temp_apply_amt, 
					l_temp_pay_num, 
					l_temp_pay_type_code 
					FROM voucherpays, cheque 
					WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND voucherpays.cmpy_code = cheque.cmpy_code 
					AND voucherpays.vend_code = glob_rec_apaudit.vend_code 
					AND voucherpays.vend_code = cheque.vend_code 
					AND voucherpays.vouch_code = glob_rec_apaudit.source_num 
					AND voucherpays.pay_num = cheque.cheq_code 
					AND voucherpays.pay_meth_ind = cheque.pay_meth_ind 
					AND voucherpays.pay_type_code = "CH" 
					AND ((cheque.year_num >= glob_temp_start_year 
					AND cheque.period_num >= glob_temp_start_period) 
					AND (cheque.year_num <= glob_temp_end_year 
					AND cheque.period_num <= glob_temp_end_period)) 
					LET l_err_message = "PR3 - first credaudit INSERT " 
					FOREACH vpayscurs1 
						LET l_rec_credaudit.apply_amt = l_temp_apply_amt 
						LET l_rec_credaudit.pay_type = l_temp_pay_type_code 
						LET l_rec_credaudit.pay_num = l_temp_pay_num 
						LET l_insert_flag = 1 
						INSERT INTO credaudit VALUES (l_rec_credaudit.*) 
					END FOREACH 
					DECLARE vpayscurs2 CURSOR FOR 
					SELECT voucherpays.apply_amt, 
					voucherpays.pay_num, 
					voucherpays.pay_type_code 
					INTO l_temp_apply_amt, 
					l_temp_pay_num, 
					l_temp_pay_type_code 
					FROM voucherpays, debithead 
					WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND voucherpays.cmpy_code = debithead.cmpy_code 
					AND voucherpays.vend_code = glob_rec_apaudit.vend_code 
					AND voucherpays.vend_code = debithead.vend_code 
					AND voucherpays.vouch_code = glob_rec_apaudit.source_num 
					AND voucherpays.pay_num = debithead.debit_num 
					AND voucherpays.pay_type_code = "DB" 
					AND ((debithead.year_num >= glob_temp_start_year 
					AND debithead.period_num >= glob_temp_start_period) 
					AND (debithead.year_num <= glob_temp_end_year 
					AND debithead.period_num <= glob_temp_end_period)) 
					LET l_err_message = "PR3 - second credaudit INSERT " 
					FOREACH vpayscurs2 
						LET l_rec_credaudit.apply_amt = l_temp_apply_amt 
						LET l_rec_credaudit.pay_type = l_temp_pay_type_code 
						LET l_rec_credaudit.pay_num = l_temp_pay_num 
						LET l_insert_flag = 1 
						INSERT INTO credaudit VALUES (l_rec_credaudit.*) 
					END FOREACH 
				END IF 
				LET l_err_message = "PR3 - third credaudit INSERT " 
				IF l_insert_flag = 0 THEN 
					INSERT INTO credaudit VALUES (l_rec_credaudit.*) 
				END IF 
				INITIALIZE l_rec_credaudit.* TO NULL 
			END IF 

		END FOREACH 

		DECLARE vpayscurs3 CURSOR FOR 
		SELECT sum(voucherpays.apply_amt), 
		voucherpays.pay_num, 
		voucherpays.pay_type_code, 
		sum(voucherpays.disc_amt), 
		voucherpays.vend_code, 
		voucherpays.pay_meth_ind 
		INTO l_rec_credaudit.apply_amt, 
		l_rec_credaudit.pay_num, 
		l_rec_credaudit.pay_type, 
		l_temp_disc_amt, 
		l_rec_credaudit.vend_code, 
		l_pay_meth_ind 
		FROM voucherpays,cheque 
		WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND voucherpays.cmpy_code = cheque.cmpy_code 
		AND voucherpays.vend_code = glob_rec_apaudit.vend_code 
		AND voucherpays.vend_code = cheque.vend_code 
		AND voucherpays.pay_num = cheque.cheq_code 
		AND voucherpays.pay_meth_ind = cheque.pay_meth_ind 
		AND voucherpays.pay_type_code = "CH" 
		AND ((cheque.year_num >= glob_temp_start_year 
		AND cheque.period_num >= glob_temp_start_period) 
		AND (cheque.year_num <= glob_temp_end_year 
		AND cheque.period_num <= glob_temp_end_period)) 
		AND NOT exists (SELECT * FROM credaudit 
		WHERE credaudit.source_num= voucherpays.vouch_code 
		AND credaudit.pay_num = voucherpays.pay_num) 
		GROUP BY voucherpays.vend_code, 
		voucherpays.pay_meth_ind, 
		voucherpays.pay_num, 
		voucherpays.pay_type_code 
		LET l_err_message = "PR3 - fourth credaudit INSERT " 

		FOREACH vpayscurs3 
			SELECT * INTO l_rec_cheque.* FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheq_code = l_rec_credaudit.pay_num 
			AND vend_code = l_rec_credaudit.vend_code 
			AND pay_meth_ind = l_pay_meth_ind 
			LET l_rec_credaudit.tran_date = l_rec_cheque.cheq_date 
			IF l_rec_cheque.apply_amt < l_rec_cheque.pay_amt THEN 
				LET l_rec_credaudit.apply_amt = l_rec_credaudit.apply_amt 
				+ (l_rec_cheque.pay_amt 
				- l_rec_cheque.apply_amt) 
			END IF 
			INSERT INTO credaudit VALUES (l_rec_credaudit.*) 
			INITIALIZE l_rec_credaudit.* TO NULL 
		END FOREACH 

		LET l_err_message = "PR3 - fifth credaudit INSERT " 
		DECLARE cheqcurs CURSOR FOR 
		SELECT * INTO l_rec_cheque.* FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = glob_rec_apaudit.vend_code 
		AND apply_amt = 0 
		AND ((cheque.year_num >= glob_temp_start_year 
		AND cheque.period_num >= glob_temp_start_period) 
		AND (cheque.year_num <= glob_temp_end_year 
		AND cheque.period_num <= glob_temp_end_period)) 

		FOREACH cheqcurs 
			LET l_rec_credaudit.tran_date = l_rec_cheque.cheq_date 
			LET l_rec_credaudit.pay_num = l_rec_cheque.cheq_code 
			LET l_rec_credaudit.vend_code = l_rec_cheque.vend_code 
			LET l_rec_credaudit.pay_type = "CH" 
			LET l_rec_credaudit.apply_amt = l_rec_cheque.pay_amt 
			INSERT INTO credaudit VALUES (l_rec_credaudit.*) 
			IF l_temp_disc_amt > 0 THEN 
				LET l_rec_credaudit.apply_amt = l_temp_disc_amt 
				LET l_rec_credaudit.pay_type = "VD" 
				LET l_rec_credaudit.pay_num = l_temp_pay_num 
				INSERT INTO credaudit VALUES (l_rec_credaudit.*) 
			END IF 
			INITIALIZE l_rec_credaudit.* TO NULL 
		END FOREACH 

		DECLARE vpayscurs4 CURSOR FOR 
		SELECT sum(voucherpays.apply_amt), 
		voucherpays.pay_num, 
		voucherpays.pay_type_code, 
		sum(voucherpays.disc_amt), 
		voucherpays.vend_code 
		INTO l_rec_credaudit.apply_amt, 
		l_rec_credaudit.pay_num, 
		l_rec_credaudit.pay_type, 
		l_temp_disc_amt, 
		l_rec_credaudit.vend_code 
		FROM voucherpays,debithead 
		WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND voucherpays.cmpy_code = debithead.cmpy_code 
		AND voucherpays.vend_code = glob_rec_apaudit.vend_code 
		AND voucherpays.vend_code = debithead.vend_code 
		AND voucherpays.pay_num = debithead.debit_num 
		AND voucherpays.pay_type_code = "DB" 
		AND ((debithead.year_num >= glob_temp_start_year 
		AND debithead.period_num >= glob_temp_start_period) 
		AND (debithead.year_num <= glob_temp_end_year 
		AND debithead.period_num <= glob_temp_end_period)) 
		AND NOT exists (SELECT * FROM credaudit 
		WHERE credaudit.source_num= voucherpays.vouch_code 
		AND credaudit.pay_num = voucherpays.pay_num) 
		GROUP BY voucherpays.vend_code, 
		voucherpays.pay_num, 
		voucherpays.pay_type_code 
		LET l_err_message = "PR3 - sixth credaudit INSERT " 

		FOREACH vpayscurs4 
			SELECT * INTO l_rec_debithead.* FROM debithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND debit_num = l_rec_credaudit.pay_num 
			AND vend_code = l_rec_credaudit.vend_code 
			LET l_rec_credaudit.tran_date = l_rec_debithead.debit_date 
			IF l_rec_debithead.apply_amt < l_rec_debithead.total_amt THEN 
				LET l_rec_credaudit.apply_amt = l_rec_credaudit.apply_amt 
				+ (l_rec_debithead.total_amt 
				- l_rec_debithead.apply_amt) 
			END IF 
			INSERT INTO credaudit VALUES (l_rec_credaudit.*) 
			INITIALIZE l_rec_credaudit.* TO NULL 
		END FOREACH 

		DECLARE debcurs CURSOR FOR 
		SELECT * INTO l_rec_debithead.* FROM debithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = glob_rec_apaudit.vend_code 
		AND apply_amt = 0 
		AND ((debithead.year_num >= glob_temp_start_year 
		AND debithead.period_num >= glob_temp_start_period) 
		AND (debithead.year_num <= glob_temp_end_year 
		AND debithead.period_num <= glob_temp_end_period)) 
		LET l_err_message = "PR3 - seventh credaudit INSERT " 

		FOREACH debcurs 
			LET l_rec_credaudit.tran_date = l_rec_debithead.debit_date 
			LET l_rec_credaudit.vend_code = l_rec_debithead.vend_code 
			LET l_rec_credaudit.pay_num = l_rec_debithead.debit_num 
			LET l_rec_credaudit.pay_type = "DB" 
			LET l_rec_credaudit.apply_amt = l_rec_debithead.total_amt 
			INSERT INTO credaudit VALUES (l_rec_credaudit.*) 
			IF l_temp_disc_amt > 0 THEN 
				LET l_rec_credaudit.apply_amt = l_temp_disc_amt 
				LET l_rec_credaudit.pay_type = "VD" 
				LET l_rec_credaudit.pay_num = l_temp_pay_num 
				INSERT INTO credaudit VALUES (l_rec_credaudit.*) 
			END IF 
			INITIALIZE l_rec_credaudit.* TO NULL 
		END FOREACH 

	COMMIT WORK 
	WHENEVER ERROR stop 

	DECLARE credcurs CURSOR FOR 
	SELECT * INTO l_rec_credaudit.* FROM credaudit 
	ORDER BY credaudit.vend_code, 
	credaudit.tran_date, 
	credaudit.source_num 


	

	DISPLAY " Vendor Code : " at 1,1 
	DISPLAY " Voucher Number: " at 2,1 

	FOREACH credcurs 
		DISPLAY l_rec_credaudit.vend_code at 1,18 

		DISPLAY l_rec_credaudit.source_num at 2,18 

		OUTPUT TO REPORT PR3_rpt_list(l_rec_credaudit.*) 
		IF int_flag OR quit_flag THEN 			
			IF kandoomsg("U",8503,"") = "N" THEN 	#8503 Continue Report(Y/N)			
				ERROR kandoomsg2("U",9501,"") #9501 Report Terminated
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PR3_rpt_list
	CALL rpt_finish("PR3_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 


############################################################
# REPORT PR3_rpt_list(p_rec_credaudit)
#
#
############################################################
REPORT PR3_rpt_list(p_rpt_idx,p_rec_credaudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_credaudit RECORD 
		vend_code LIKE apaudit.vend_code, 
		tran_date LIKE apaudit.tran_date, 
		trantype_ind LIKE apaudit.trantype_ind, 
		source_num LIKE apaudit.source_num, 
		inv_text LIKE voucher.inv_text, 
		tran_amt LIKE apaudit.tran_amt, 
		apply_amt LIKE voucherpays.apply_amt, 
		pay_type CHAR(2), 
		pay_num LIKE voucherpays.pay_num 
	END RECORD 
	DEFINE l_rec_snapshot RECORD 
		vouch_total LIKE voucher.total_amt, 
		ch_paid_total LIKE voucherpays.apply_amt, 
		ch_disc_total LIKE voucherpays.disc_amt, 
		db_paid_total LIKE voucherpays.apply_amt, 
		db_disc_total LIKE voucherpays.disc_amt, 
		cheq_total LIKE cheque.pay_amt, 
		debit_total LIKE debithead.total_amt 
	END RECORD
	DEFINE l_rec_vendor RECORD LIKE vendor.*
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.*
	DEFINE l_arr_dist ARRAY[100] OF RECORD 
		dist_amt LIKE voucherdist.dist_amt, 
		acct_code LIKE voucherdist.acct_code, 
		desc_text CHAR(20) 
	END RECORD 
	DEFINE l_bal_amt_1 LIKE apaudit.bal_amt 
	DEFINE l_bal_amt_2 LIKE apaudit.bal_amt
	DEFINE l_close_vouch LIKE voucher.total_amt
	DEFINE l_close_apply LIKE voucherpays.apply_amt
	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 
	DEFINE l_acc_year SMALLINT
	DEFINE l_per SMALLINT
	DEFINE i, idx, maxidx SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_credaudit.vend_code, 
	p_rec_credaudit.tran_date, 
	p_rec_credaudit.source_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Start Year: ", glob_temp_start_year clipped," ",	"Start Period: ", glob_temp_start_period clipped 
			PRINT COLUMN 1, "END Year : ", glob_temp_end_year clipped," ", 	"END Period : ", glob_temp_end_period clipped 
			PRINT
			 
		BEFORE GROUP OF p_rec_credaudit.vend_code 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_credaudit.vend_code 
			PRINT COLUMN 1, "Vendor ID: ", p_rec_credaudit.vend_code, " - ", 
			l_rec_vendor.name_text 
			LET l_acc_year = glob_temp_start_year 
			LET l_per = glob_temp_start_period 
			
			CALL change_period(glob_rec_kandoouser.cmpy_code, l_acc_year, l_per, -1) 
			RETURNING l_acc_year, l_per 
			
			SELECT sum(total_amt) INTO l_rec_snapshot.vouch_total FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_apaudit.vend_code 
			AND (year_num <= (glob_temp_start_year - 1) 
			OR (year_num = l_acc_year AND period_num <= l_per)) 
			
			SELECT sum(voucherpays.apply_amt), 
			sum(voucherpays.disc_amt) 
			INTO l_rec_snapshot.ch_paid_total, 
			l_rec_snapshot.ch_disc_total 
			FROM voucherpays, cheque 
			WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucherpays.cmpy_code = cheque.cmpy_code 
			AND voucherpays.vend_code = glob_rec_apaudit.vend_code 
			AND voucherpays.vend_code = cheque.vend_code 
			AND voucherpays.pay_num = cheque.cheq_code 
			AND voucherpays.pay_meth_ind = cheque.pay_meth_ind 
			AND voucherpays.pay_type_code = "CH" 
			AND (year_num <= (glob_temp_start_year - 1) 
			OR (year_num = l_acc_year AND period_num <= l_per)) 
			
			SELECT sum(voucherpays.apply_amt), 
			sum(voucherpays.disc_amt) 
			INTO l_rec_snapshot.db_paid_total, 
			l_rec_snapshot.db_disc_total 
			FROM voucherpays, debithead 
			WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucherpays.cmpy_code = debithead.cmpy_code 
			AND voucherpays.vend_code = glob_rec_apaudit.vend_code 
			AND voucherpays.vend_code = debithead.vend_code 
			AND voucherpays.pay_num = debithead.debit_num 
			AND voucherpays.pay_type_code = "DB" 
			AND (year_num <= (glob_temp_start_year - 1) 
			OR (year_num = l_acc_year AND period_num <= l_per)) 
			
			SELECT sum(pay_amt - apply_amt) INTO l_rec_snapshot.cheq_total 
			FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_apaudit.vend_code 
			AND apply_amt < pay_amt 
			AND (year_num <= (glob_temp_start_year - 1) 
			OR (year_num = l_acc_year AND period_num <= l_per)) 
			
			SELECT sum(total_amt - apply_amt) INTO l_rec_snapshot.debit_total 
			FROM debithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_apaudit.vend_code 
			AND apply_amt < total_amt 
			AND (year_num <= (glob_temp_start_year - 1) 
			OR (year_num = l_acc_year AND period_num <= l_per))
			 
			IF l_rec_snapshot.vouch_total IS NULL THEN 
				LET l_rec_snapshot.vouch_total = 0 
			END IF 
			IF l_rec_snapshot.ch_paid_total IS NULL THEN 
				LET l_rec_snapshot.ch_paid_total = 0 
			END IF 
			IF l_rec_snapshot.ch_disc_total IS NULL THEN 
				LET l_rec_snapshot.ch_disc_total = 0 
			END IF 
			IF l_rec_snapshot.db_paid_total IS NULL THEN 
				LET l_rec_snapshot.db_paid_total = 0 
			END IF 
			IF l_rec_snapshot.db_disc_total IS NULL THEN 
				LET l_rec_snapshot.db_disc_total = 0 
			END IF 
			IF l_rec_snapshot.cheq_total IS NULL THEN 
				LET l_rec_snapshot.cheq_total = 0 
			END IF 
			IF l_rec_snapshot.debit_total IS NULL THEN 
				LET l_rec_snapshot.debit_total = 0 
			END IF
			 
			LET l_bal_amt_1 = 0 
			LET l_bal_amt_1 = (l_rec_snapshot.vouch_total - (l_rec_snapshot.ch_paid_total + 
			l_rec_snapshot.ch_disc_total + 
			l_rec_snapshot.db_paid_total + 
			l_rec_snapshot.db_disc_total + 
			l_rec_snapshot.cheq_total + 
			l_rec_snapshot.debit_total)) 

			PRINT COLUMN 1, "OPENING BALANCE: ", 
			COLUMN 30, l_bal_amt_1 USING "------------$.&&" 
			LET l_close_vouch = 0 
			LET l_close_apply = 0 
			LET l_bal_amt_2 = 0 
			
		BEFORE GROUP OF p_rec_credaudit.source_num 
			LET idx = 0 
			IF p_rec_credaudit.source_num IS NULL THEN 
				PRINT COLUMN 1, p_rec_credaudit.tran_date USING "dd/mm/yy"; 
			ELSE 
				DECLARE distcurs CURSOR FOR 
				SELECT * INTO l_rec_voucherdist.* FROM voucherdist 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vouch_code = p_rec_credaudit.source_num 
				FOREACH distcurs 
					LET idx = idx + 1 
					LET l_arr_dist[idx].dist_amt = l_rec_voucherdist.dist_amt 
					LET l_arr_dist[idx].acct_code = l_rec_voucherdist.acct_code 
					LET l_arr_dist[idx].desc_text = l_rec_voucherdist.desc_text[1,20] 
				END FOREACH 
				LET maxidx = idx 
				LET idx = 0 
				PRINT COLUMN 1, p_rec_credaudit.tran_date USING "dd/mm/yy", 
				COLUMN 10, p_rec_credaudit.trantype_ind, 
				COLUMN 13, p_rec_credaudit.source_num USING "########", 
				COLUMN 22, p_rec_credaudit.inv_text[1,10], 
				COLUMN 32, p_rec_credaudit.tran_amt USING "----------$.&&"; 
			END IF 
			IF p_rec_credaudit.tran_amt IS NOT NULL THEN 
				LET l_close_vouch = l_close_vouch + p_rec_credaudit.tran_amt 
			END IF 

		ON EVERY ROW 
			PRINT COLUMN 47, p_rec_credaudit.apply_amt USING "--------$.&&", 
			COLUMN 62, p_rec_credaudit.pay_type, 
			COLUMN 67, p_rec_credaudit.pay_num USING "######"; 
			IF idx <> maxidx THEN 
				LET idx = idx + 1 
				PRINT COLUMN 73, l_arr_dist[idx].dist_amt USING "----------$.&&", 
				COLUMN 88, l_arr_dist[idx].acct_code, 
				COLUMN 107, l_arr_dist[idx].desc_text 
			ELSE 
				PRINT 
			END IF 
			IF p_rec_credaudit.apply_amt IS NOT NULL THEN 
				LET l_close_apply = l_close_apply + p_rec_credaudit.apply_amt 
			END IF 

		AFTER GROUP OF p_rec_credaudit.source_num 
			WHILE idx <> maxidx 
				LET idx = idx + 1 
				PRINT COLUMN 73, l_arr_dist[idx].dist_amt USING "----------$.&&", 
				COLUMN 88, l_arr_dist[idx].acct_code, 
				COLUMN 107, l_arr_dist[idx].desc_text 
			END WHILE 
			FOR i = 1 TO maxidx 
				INITIALIZE l_arr_dist[i].* TO NULL 
			END FOR 

		AFTER GROUP OF p_rec_credaudit.vend_code 
			SKIP 1 LINES 
			LET l_bal_amt_2 = l_bal_amt_1 + (l_close_vouch - l_close_apply) 
			PRINT COLUMN 1, "CLOSING BALANCE: ", 
			COLUMN 31, l_bal_amt_2 USING "-----------$.&&" 
			SKIP 1 LINES 

		ON LAST ROW 
			NEED 4 LINES 
			SKIP 2 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		
END REPORT 