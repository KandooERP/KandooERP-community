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
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_voucher RECORD LIKE voucher.* 
	DEFINE glob_arr_voucher ARRAY[400] OF 
	RECORD 
		scroll_flag CHAR(1), 
		line_num SMALLINT, 
		vouch_code LIKE voucher.vouch_code, 
		vend_code LIKE voucher.vend_code, 
		inv_text LIKE voucher.inv_text, 
		dist_amt LIKE voucher.dist_amt, 
		total_amt LIKE voucher.total_amt 
	END RECORD 
	DEFINE glob_cnt SMALLINT 
	DEFINE glob_ctl_linetotal SMALLINT 
	DEFINE glob_bat_linetotal SMALLINT 
	DEFINE glob_ctl_amttotal LIKE voucher.total_amt 
	DEFINE glob_bat_amttotal LIKE voucher.total_amt 
	DEFINE glob_batch_num LIKE batch.batch_num 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P24 allows the user TO enter AND distribute Payables Voucher
#             in batch mode.
############################################################
MAIN 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("P24") 
	CALL ui_init(0) #initial ui init 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW P214 with FORM "P214" 
	CALL windecoration_p("P214") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#IF STATUS = NOTFOUND THEN
	#   LET msgresp=kandoomsg("P",5016,"")
	#   #5016 Accounts Payable Parameters Not Set Up;  Refer Menu PZP.
	#   EXIT PROGRAM
	#END IF
	CALL create_table("voucherdist","t_voucherdist","","Y") 
	CALL create_table("purchdetl","t_purchdetl","","Y") 
	CALL create_table("poaudit","t_poaudit","","Y") 
	
	LET glob_ctl_linetotal = NULL 
	LET glob_ctl_amttotal = NULL 
	LET glob_bat_linetotal = 0 
	LET glob_bat_amttotal = 0 
	
	INITIALIZE glob_rec_voucher.* TO NULL 
	CALL batch_entry() 
	
	CLOSE WINDOW p214 

END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION batch_entry()
#
#
############################################################
FUNCTION batch_entry() 
	DEFINE l_rec_default RECORD 
			term_code LIKE voucher.term_code, 
			tax_code LIKE voucher.tax_code, 
			vouch_date LIKE voucher.vouch_date, 
			year_num LIKE voucher.year_num, 
			period_num LIKE voucher.period_num 
		END RECORD
	DEFINE l_temp_text CHAR(60)
	DEFINE l_rec_batch RECORD LIKE batch.* 
	DEFINE l_term_text LIKE term.desc_text 
	DEFINE l_tax_text LIKE tax.desc_text 
	DEFINE l_lastkey INTEGER 
	DEFINE l_exit_flag CHAR(1) 
	DEFINE l_bal_flag CHAR(1) 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_counter SMALLINT 
	DEFINE l_err_message CHAR(40) 
	DEFINE i SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE scrn SMALLINT 

	INITIALIZE l_rec_default.* TO NULL
	SELECT * INTO l_rec_batch.* FROM batch 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND entry_person = glob_rec_kandoouser.sign_on_code 
	AND trans_type_ind = "VO" 
	IF status != NOTFOUND THEN 
		LET glob_batch_num = l_rec_batch.batch_num 
		LET glob_ctl_linetotal = l_rec_batch.control_count 
		LET glob_ctl_amttotal = l_rec_batch.control_amt 
		LET l_rec_default.term_code = l_rec_batch.term_code 
		LET l_rec_default.tax_code = l_rec_batch.tax_code 
		LET l_rec_default.vouch_date = l_rec_batch.trans_date 
		LET l_rec_default.year_num = l_rec_batch.year_num 
		LET l_rec_default.period_num = l_rec_batch.period_num 
		LET idx = 0 
		
		DISPLAY glob_batch_num TO batch_num 

		IF l_rec_default.term_code IS NOT NULL THEN 
			SELECT desc_text INTO l_term_text FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = l_rec_default.term_code 
			IF status = NOTFOUND THEN 
				LET l_term_text = NULL 
			END IF 
		
			DISPLAY l_term_text TO term.desc_text 

		END IF 
		
		IF l_rec_default.tax_code IS NOT NULL THEN 
			SELECT desc_text INTO l_tax_text FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = l_rec_default.tax_code 
			IF status = NOTFOUND THEN 
				LET l_tax_text = NULL 
			END IF 
			DISPLAY l_tax_text 
			TO tax.desc_text 

		END IF 
		DECLARE c_batch CURSOR FOR 
		SELECT vend_code, vouch_code, inv_text, dist_amt, total_amt FROM voucher 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND batch_num = glob_batch_num 
		
		FOREACH c_batch INTO 
			glob_rec_voucher.vend_code, 
			glob_rec_voucher.vouch_code, 
			glob_rec_voucher.inv_text, 
			glob_rec_voucher.dist_amt, 
			glob_rec_voucher.total_amt 
			
			LET idx = idx + 1 
			LET glob_arr_voucher[idx].scroll_flag = NULL 
			LET glob_arr_voucher[idx].line_num = idx 
			LET glob_arr_voucher[idx].vouch_code = glob_rec_voucher.vouch_code 
			LET glob_arr_voucher[idx].vend_code = glob_rec_voucher.vend_code 
			LET glob_arr_voucher[idx].inv_text = glob_rec_voucher.inv_text[1,16] 
			LET glob_arr_voucher[idx].dist_amt = glob_rec_voucher.dist_amt 
			LET glob_arr_voucher[idx].total_amt = glob_rec_voucher.total_amt 
			LET glob_bat_linetotal = glob_bat_linetotal + 1 
			LET glob_bat_amttotal = glob_bat_amttotal + glob_rec_voucher.total_amt 
			
			IF idx = 400 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		
		DISPLAY glob_bat_linetotal, glob_bat_amttotal TO bat_linetotal, bat_amttotal  

		FOR l_counter = 1 TO 8 
			IF glob_arr_voucher[l_counter].vouch_code = 0 THEN 
				EXIT FOR 
			END IF 
			DISPLAY glob_arr_voucher[l_counter].*	TO sr_voucher[l_counter].* 

		END FOR 
		CALL set_count(idx) 
		LET glob_cnt = idx + 1 
	ELSE 
		LET glob_cnt = 1 
		LET glob_batch_num = 0 
	END IF 
	
	WHILE true 
		IF l_lastkey != fgl_keyval("F1") THEN 
			MESSAGE kandoomsg2("P",1505,"") #1505 Batch Detail Entry;  F1 Add;  F8 Batch Correction.
{
			INPUT BY NAME pr_ctl_linetotal, 
			pr_ctl_amttotal, 
			pa_default.term_code, 
			pa_default.tax_code, 
			pa_default.vouch_date, 
			pa_default.year_num, 
			pa_default.period_num WITHOUT DEFAULTS 
}
			INPUT 
				glob_ctl_linetotal, 
				glob_ctl_amttotal, 
				l_rec_default.term_code, 
				l_rec_default.tax_code, 
				l_rec_default.vouch_date, 
				l_rec_default.year_num, 
				l_rec_default.period_num WITHOUT DEFAULTS
			FROM 
				ctl_linetotal, 
				ctl_amttotal, 
				term_code, 
				tax_code, 
				vouch_date, 
				year_num, 
				period_num   

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","P24","inp-line-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "LOOKUP" infield (term_code) 
					LET l_temp_text = show_term(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET l_rec_default.term_code = l_temp_text 
					END IF 
					NEXT FIELD term_code 

				ON ACTION "LOOKUP"infield (tax_code) 
					LET l_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET l_rec_default.tax_code = l_temp_text 
					END IF 
					NEXT FIELD tax_code 

				ON KEY (F1) 
					EXIT INPUT 

				ON KEY (F8) 
					IF glob_cnt > 1 THEN 
						EXIT INPUT 
					ELSE 
						ERROR kandoomsg2("P",1510,"")			#1510 Batch contains no vouchers.
					END IF 

				AFTER FIELD ctl_linetotal 
					IF glob_ctl_linetotal IS NULL THEN 
						LET glob_ctl_linetotal = 0 
						DISPLAY glob_ctl_linetotal TO ctl_linetotal 

					ELSE 
						IF glob_ctl_linetotal < 0 THEN 
							ERROR kandoomsg2("P",1507,"")	#1507 Control total must NOT be negative.
							NEXT FIELD ctl_linetotal 
						END IF 
					END IF 

				AFTER FIELD ctl_amttotal 
					IF glob_ctl_amttotal IS NULL THEN 
						LET glob_ctl_amttotal = 0 
						DISPLAY glob_ctl_amttotal TO ctl_amttotal 

					ELSE 
						IF glob_ctl_amttotal < 0 THEN 
							ERROR kandoomsg2("P",1507,"")				#1507 Control total must NOT be negative
							NEXT FIELD ctl_amttotal 
						END IF 
					END IF 

				AFTER FIELD term_code 
					CLEAR term.desc_text 
					IF l_rec_default.term_code IS NOT NULL THEN 
						SELECT desc_text INTO l_term_text 
						FROM term 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND term_code = l_rec_default.term_code 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("P",9025,"")			#9025 Term code NOT found.
							NEXT FIELD term_code 
						END IF 
						
						DISPLAY l_term_text	TO term.desc_text 

					END IF 

				AFTER FIELD tax_code 
					CLEAR tax.desc_text 
					IF l_rec_default.tax_code IS NOT NULL THEN 
						SELECT desc_text INTO l_tax_text 
						FROM tax 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND tax_code = l_rec_default.tax_code 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("P",9106,"") 		#9025 Tax code NOT found.
							NEXT FIELD tax_code 
						END IF 
						DISPLAY l_tax_text 
						TO tax.desc_text 

					END IF 

				AFTER INPUT 
					IF not(int_flag OR quit_flag) THEN 
						IF glob_ctl_linetotal IS NULL THEN 
							LET glob_ctl_linetotal = 0 
							DISPLAY glob_ctl_linetotal TO ctl_linetotal 

						END IF 
						IF glob_ctl_amttotal IS NULL THEN 
							LET glob_ctl_amttotal = 0 
							DISPLAY glob_ctl_amttotal TO ctl_amttotal 

						END IF 
						IF l_rec_default.term_code IS NOT NULL THEN 
							SELECT desc_text INTO l_term_text FROM term 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND term_code = l_rec_default.term_code 
							IF status = NOTFOUND THEN 
								ERROR kandoomsg2("P",9025,"")	#9025 Term code NOT found.
								NEXT FIELD term_code 
							END IF 
							DISPLAY l_term_text 
							TO term.desc_text 

						END IF 
						IF l_rec_default.tax_code IS NOT NULL THEN 
							SELECT desc_text INTO l_tax_text FROM tax 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND tax_code = l_rec_default.tax_code 
							IF status = NOTFOUND THEN 
								ERROR kandoomsg2("P",9106,"")	#9106 Tax code NOT found.
								NEXT FIELD tax_code 
							END IF 
							DISPLAY l_tax_text 				TO tax.desc_text 

						END IF 
						IF l_rec_default.year_num IS NOT NULL 
						AND l_rec_default.period_num IS NOT NULL THEN 
							IF NOT valid_period2(
								glob_rec_kandoouser.cmpy_code, 
								l_rec_default.year_num, 
								l_rec_default.period_num, "ap") THEN 
								
								ERROR kandoomsg2("P",9024,"")		#9024 Accounting year & period IS closed OR NOT SET up.
								NEXT FIELD year_num 
							END IF 
						END IF 
						
						IF glob_batch_num = 0 THEN 
							GOTO bypass 
							LABEL recovery: 
							
							IF error_recover(l_err_message,status) != "Y" THEN 
								RETURN false 
							END IF 
							
							LABEL bypass: 
							WHENEVER ERROR GOTO recovery 
							
							BEGIN WORK 
								LET l_err_message = "P24 - Next Batch number" 
								LET glob_batch_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_BATCH_BAT,"") 
								LET l_err_message = "P24 - Inserting Batch details" 
								LET l_rec_batch.cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET l_rec_batch.trans_type_ind = "VO" 
								LET l_rec_batch.batch_num = glob_batch_num 
								LET l_rec_batch.term_code = l_rec_default.term_code 
								LET l_rec_batch.tax_code = l_rec_default.tax_code 
								LET l_rec_batch.trans_date = l_rec_default.vouch_date 
								LET l_rec_batch.year_num = l_rec_default.year_num 
								LET l_rec_batch.period_num = l_rec_default.period_num 
								LET l_rec_batch.control_count = glob_ctl_linetotal 
								LET l_rec_batch.control_amt = glob_ctl_amttotal 
								LET l_rec_batch.entry_person = glob_rec_kandoouser.sign_on_code 
								LET l_rec_batch.entry_date = today 
						
								# INSERT ----------------------------
								INSERT INTO batch VALUES (l_rec_batch.*) 
						
							COMMIT WORK 
							WHENEVER ERROR CONTINUE 
							DISPLAY glob_batch_num TO batch_num 

						END IF 
					END IF 

			END INPUT 
			IF fgl_lastkey() = fgl_keyval("F8") THEN 
				LET quit_flag = true 
			END IF 
		END IF 
		
		WHILE not(int_flag OR quit_flag) 
			IF voucher("","","",glob_cnt) THEN 
				IF glob_cnt > 8 THEN 
					LET i = 1 
					FOR idx = ( glob_cnt - 8 ) TO ( glob_cnt - 1 ) 
						DISPLAY glob_arr_voucher[idx].*	TO sr_voucher[i].* 

						LET i = i + 1 
					END FOR 
				ELSE 
					DISPLAY glob_arr_voucher[glob_cnt-1].*	TO sr_voucher[glob_cnt-1].* 

				END IF 
				DISPLAY glob_bat_linetotal,glob_bat_amttotal TO bat_linetotal,bat_amttotal  

			ELSE 
				LET quit_flag = true 
			END IF 
		END WHILE 

		LET int_flag = false 
		LET quit_flag = false 
		LET l_lastkey = 0 
		
		MESSAGE kandoomsg2("P",1506,"")	#1506 Batch Correction;  F1 Add;  F8 Batch Detail.

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36
		 
		IF glob_batch_num = 0 OR glob_batch_num IS NULL THEN 
			RETURN 
		END IF 

		WHILE l_lastkey = 0 
			CALL set_count(glob_cnt-1) 
			INPUT ARRAY glob_arr_voucher WITHOUT DEFAULTS FROM sr_voucher.* ATTRIBUTE(UNBUFFERED,INSERT ROW = FALSE,APPEND ROW = FALSE, AUTO APPEND = FALSE, DELETE ROW=FALSE)  

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","P24","inp-arr-voucher-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				ON KEY (F1) 
					EXIT INPUT 

				ON KEY (F8) 
					EXIT INPUT 

				BEFORE FIELD scroll_flag 
					LET idx = arr_curr() 
					LET scrn = scr_line() 
					LET l_scroll_flag = glob_arr_voucher[idx].scroll_flag 
					DISPLAY glob_arr_voucher[idx].* 
					TO sr_voucher[scrn].* 

				AFTER FIELD scroll_flag 
					LET glob_arr_voucher[idx].scroll_flag = l_scroll_flag 

				BEFORE FIELD line_num 
					IF voucher(
						glob_arr_voucher[idx].vend_code, 
						glob_arr_voucher[idx].vouch_code, 
						glob_arr_voucher[idx].total_amt, idx) THEN 
						
						DISPLAY glob_bat_linetotal,glob_bat_amttotal TO bat_linetotal,bat_amttotal  

					END IF 
					NEXT FIELD scroll_flag
					 
				AFTER ROW 
					DISPLAY glob_arr_voucher[idx].*		TO sr_voucher[scrn].* 

			END INPUT 
			LET l_lastkey = fgl_lastkey() 
		END WHILE 

		IF int_flag OR quit_flag OR l_lastkey = fgl_keyval("accept") THEN 
			IF glob_bat_amttotal != 0 
			OR glob_bat_linetotal != 0 
			OR glob_ctl_amttotal != 0 
			OR glob_ctl_linetotal != 0 THEN
			 
				IF glob_batch_num IS NOT NULL	AND glob_batch_num != 0 THEN 
					LET l_bal_flag = true 
					LET l_exit_flag = "Y" 
					
					IF glob_bat_linetotal != glob_ctl_linetotal	OR glob_bat_amttotal != glob_ctl_amttotal THEN 
						LET l_bal_flag = false 
						LET l_exit_flag = kandoomsg("P",8012,"")				#8012 Batch NOT in balance.  Do you wish TO quit?
					END IF 
				
				END IF 
				
				IF l_exit_flag = "N" THEN 
					CONTINUE WHILE 
				ELSE 
					IF l_bal_flag = true THEN 
					
						# DELETE --------------------------
						DELETE FROM batch 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND batch_num = glob_batch_num 
						AND entry_person = glob_rec_kandoouser.sign_on_code 
					ELSE 
						LET l_rec_batch.term_code = l_rec_default.term_code 
						LET l_rec_batch.tax_code = l_rec_default.tax_code 
						LET l_rec_batch.trans_date = l_rec_default.vouch_date 
						LET l_rec_batch.year_num = l_rec_default.year_num 
						LET l_rec_batch.period_num = l_rec_default.period_num 
						LET l_rec_batch.control_count = glob_ctl_linetotal 
						LET l_rec_batch.control_amt = glob_ctl_amttotal 
						
						# UPDATE ---------------------------------
						UPDATE batch 
						SET * = l_rec_batch.* 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND entry_person = glob_rec_kandoouser.sign_on_code 
						AND batch_num = l_rec_batch.batch_num 
					END IF 
				END IF 
			ELSE 
				LET l_rec_batch.term_code = l_rec_default.term_code 
				LET l_rec_batch.tax_code = l_rec_default.tax_code 
				LET l_rec_batch.trans_date = l_rec_default.vouch_date 
				LET l_rec_batch.year_num = l_rec_default.year_num 
				LET l_rec_batch.period_num = l_rec_default.period_num 
				LET l_rec_batch.control_count = glob_ctl_linetotal 
				LET l_rec_batch.control_amt = glob_ctl_amttotal
				
				# UPDATE ------------------------------- 
				UPDATE batch 
				SET * = l_rec_batch.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND entry_person = glob_rec_kandoouser.sign_on_code 
				AND batch_num = l_rec_batch.batch_num 
			END IF 
			
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
	END WHILE 

END FUNCTION 
############################################################
# END FUNCTION batch_entry()
############################################################


############################################################
# FUNCTION voucher(p_vend_code, p_vouch_code, p_line_total, p_arr_cnt)
#
#
############################################################
FUNCTION voucher(p_vend_code,p_vouch_code,p_line_total,p_arr_cnt) 
	DEFINE p_vend_code LIKE voucher.vend_code 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE p_line_total LIKE voucher.total_amt 
	DEFINE p_arr_cnt SMALLINT 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_update_ind CHAR(1) 

	IF p_vend_code IS NULL THEN 
		LET l_update_ind = '1' 
	ELSE 
		LET l_update_ind = '2' 
	END IF 

	OPEN WINDOW P125 with FORM "P125" 
	CALL windecoration_p("P125") 

	CLEAR FORM 
	CALL input_voucher(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_kandoouser.sign_on_code, 
		p_vend_code, 
		p_vouch_code,
		"") 
	RETURNING glob_rec_voucher.*, l_rec_vouchpayee.*
	 
	LET glob_rec_voucher.vouch_code = voucher_distribution_menu(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_kandoouser.sign_on_code, 
		glob_rec_voucher.*, 
		l_rec_vouchpayee.*, 
		l_update_ind) 
	
	CLOSE WINDOW P125 

	IF glob_rec_voucher.vouch_code > 0 THEN 
		LET glob_arr_voucher[p_arr_cnt].scroll_flag = NULL 
		LET glob_arr_voucher[p_arr_cnt].line_num = p_arr_cnt 
		LET glob_arr_voucher[p_arr_cnt].vouch_code = glob_rec_voucher.vouch_code 
		LET glob_arr_voucher[p_arr_cnt].vend_code = glob_rec_voucher.vend_code 
		LET glob_arr_voucher[p_arr_cnt].inv_text = glob_rec_voucher.inv_text[1,16] 
		LET glob_arr_voucher[p_arr_cnt].dist_amt = glob_rec_voucher.dist_amt 
		LET glob_arr_voucher[p_arr_cnt].total_amt = glob_rec_voucher.total_amt 

		IF p_vend_code IS NULL THEN 
			LET glob_bat_linetotal = glob_bat_linetotal + 1 
			LET glob_bat_amttotal = glob_bat_amttotal + glob_rec_voucher.total_amt 
			LET glob_cnt = glob_cnt + 1 
		ELSE 
			LET glob_bat_amttotal = glob_bat_amttotal 
			- p_line_total 
			+ glob_rec_voucher.total_amt 
		END IF 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION batch_entry()
############################################################