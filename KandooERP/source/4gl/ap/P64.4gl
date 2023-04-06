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
# \brief module P64 - allows the user TO enter Payables debits, distribute the
#               debits TO G/L accounts in a batch sequence.

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P64_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

GLOBALS 
	DEFINE 
	glob_rec_debithead RECORD LIKE debithead.*, 
	glob_arr_debithead ARRAY[400] OF RECORD 
		scroll_flag CHAR(1), 
		line_num SMALLINT, 
		debit_num LIKE debithead.debit_num, 
		vend_code LIKE debithead.vend_code, 
		debit_text LIKE debithead.debit_text, 
		dist_amt LIKE debithead.dist_amt, 
		total_amt LIKE debithead.total_amt 
	END RECORD, 
	glob_cnt, 
	glob_ctl_linetotal, 
	glob_bat_linetotal SMALLINT, 
	glob_ctl_amttotal, 
	glob_bat_amttotal LIKE debithead.total_amt, 
	glob_batch_num LIKE batch.batch_num 
END GLOBALS 


############################################################
# MAIN
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P64") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p240 with FORM "P240" 
	CALL windecoration_p("P240") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   AND parm_code = "1"
	#IF STATUS = NOTFOUND THEN
	#   LET msgresp=kandoomsg("P",5016,"")
	#   #5016 Accounts Payable Parameters Not Set Up;  Refer Menu PZP.
	#   EXIT PROGRAM
	#END IF
	CALL create_table("debitdist","t_debitdist","","Y") 
	LET glob_ctl_linetotal = NULL 
	LET glob_ctl_amttotal = NULL 
	LET glob_bat_linetotal = 0 
	LET glob_bat_amttotal = 0 
	INITIALIZE glob_rec_debithead.* TO NULL 
	CALL batch_entry() 
	CLOSE WINDOW p240 
END MAIN 


FUNCTION batch_entry() 
	DEFINE
	l_rec_default RECORD 
		debit_date LIKE debithead.debit_date, 
		year_num LIKE debithead.year_num, 
		period_num LIKE debithead.period_num 
	END RECORD	
	DEFINE l_rec_batch RECORD LIKE batch.*
	DEFINE l_lastkey INTEGER 
	DEFINE l_exit_flag CHAR(1) 
	DEFINE l_bal_flag CHAR(1) 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_counter SMALLINT 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i, idx, scrn SMALLINT

	INITIALIZE l_rec_default.* TO NULL
	SELECT * INTO l_rec_batch.* FROM batch 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND entry_person = glob_rec_kandoouser.sign_on_code 
	AND trans_type_ind = "DB" 
	IF status != NOTFOUND THEN 
		LET glob_batch_num = l_rec_batch.batch_num 
		LET glob_ctl_linetotal = l_rec_batch.control_count 
		LET glob_ctl_amttotal = l_rec_batch.control_amt 
		LET l_rec_default.debit_date = l_rec_batch.trans_date 
		LET l_rec_default.year_num = l_rec_batch.year_num 
		LET l_rec_default.period_num = l_rec_batch.period_num 
		LET idx = 0 
		DISPLAY glob_batch_num TO batch_num 

		DECLARE c_batch CURSOR FOR 
		SELECT vend_code, debit_num, debit_text, dist_amt, total_amt 
		FROM debithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND batch_num = glob_batch_num 
		FOREACH c_batch INTO glob_rec_debithead.vend_code, glob_rec_debithead.debit_num, 
			glob_rec_debithead.debit_text, glob_rec_debithead.dist_amt, 
			glob_rec_debithead.total_amt 
			LET idx = idx + 1 
			LET glob_arr_debithead[idx].scroll_flag = NULL 
			LET glob_arr_debithead[idx].line_num = idx 
			LET glob_arr_debithead[idx].debit_num = glob_rec_debithead.debit_num 
			LET glob_arr_debithead[idx].vend_code = glob_rec_debithead.vend_code 
			LET glob_arr_debithead[idx].debit_text = glob_rec_debithead.debit_text[1,16] 
			LET glob_arr_debithead[idx].dist_amt = glob_rec_debithead.dist_amt 
			LET glob_arr_debithead[idx].total_amt = glob_rec_debithead.total_amt 
			LET glob_bat_linetotal = glob_bat_linetotal + 1 
			LET glob_bat_amttotal = glob_bat_amttotal + glob_rec_debithead.total_amt 
			IF idx = 400 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		DISPLAY glob_bat_linetotal,glob_bat_amttotal TO bat_linetotal,bat_amttotal  

		FOR l_counter = 1 TO 8 
			IF glob_arr_debithead[l_counter].debit_num = 0 THEN 
				EXIT FOR 
			END IF 
			DISPLAY glob_arr_debithead[l_counter].* 
			TO sr_debithead[l_counter].* 

		END FOR 
		CALL set_count(idx) 
		LET glob_cnt = idx + 1 
	ELSE 
		LET glob_cnt = 1 
		LET glob_batch_num = 0 
	END IF 
	WHILE true 
		IF l_lastkey != fgl_keyval("F1") THEN 
			LET l_msgresp = kandoomsg("P",1505,"") 
			#1505 Batch Detail Entry;  F1 Add;  F8 Batch Correction.

			INPUT glob_ctl_linetotal, 
			glob_ctl_amttotal, 
			l_rec_default.debit_date, 
			l_rec_default.year_num, 
			l_rec_default.period_num WITHOUT DEFAULTS
			FROM ctl_linetotal, 
			ctl_amttotal, 
			debit_date, 
			year_num, 
			period_num

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","P64","inp-default-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (F1) 
					EXIT INPUT 
				ON KEY (F8) 
					IF glob_cnt > 1 THEN 
						EXIT INPUT 
					ELSE 
						LET l_msgresp = kandoomsg("P",9557,"") 
						#9557 Batch contains no debits.
					END IF 
				AFTER FIELD ctl_linetotal 
					IF glob_ctl_linetotal IS NULL 
					OR glob_ctl_linetotal = " " THEN 
						LET glob_ctl_linetotal = 0 
						DISPLAY glob_ctl_linetotal TO ctl_linetotal 

					END IF 
					IF glob_ctl_linetotal < 0 THEN 
						LET l_msgresp = kandoomsg("P",1507,"") 
						#1507 Control total must NOT be negative.
						NEXT FIELD ctl_linetotal 
					END IF 
				AFTER FIELD ctl_amttotal 
					IF glob_ctl_amttotal IS NULL 
					OR glob_ctl_amttotal = " " THEN 
						LET glob_ctl_amttotal = 0 
						DISPLAY glob_ctl_amttotal TO ctl_amttotal 

					END IF 
					IF glob_ctl_amttotal < 0 THEN 
						LET l_msgresp = kandoomsg("P",1507,"") 
						#1507 Control total must NOT be negative
						NEXT FIELD ctl_amttotal 
					END IF 
				AFTER INPUT 
					IF not(int_flag OR quit_flag) THEN 
						IF glob_ctl_linetotal IS NULL 
						OR glob_ctl_linetotal = " " THEN 
							LET glob_ctl_linetotal = 0 
							DISPLAY glob_ctl_linetotal TO ctl_linetotal 

						END IF 
						IF glob_ctl_amttotal IS NULL 
						OR glob_ctl_amttotal = " " THEN 
							LET glob_ctl_amttotal = 0 
							DISPLAY glob_ctl_amttotal TO ctl_amttotal 

						END IF 
						IF l_rec_default.year_num IS NOT NULL 
						AND l_rec_default.period_num IS NOT NULL THEN 
							IF NOT valid_period2(glob_rec_kandoouser.cmpy_code, l_rec_default.year_num, 
							l_rec_default.period_num, "ap") THEN 
								LET l_msgresp=kandoomsg("P",9024,"") 
								#9024 Accounting year & period IS closed OR NOT SET up.
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
								LET l_err_message = "P64 - Next Batch number" 
								LET glob_batch_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_BATCH_BAT,"") 
								LET l_err_message = "P64 - Inserting Batch details" 
								LET l_rec_batch.cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET l_rec_batch.trans_type_ind = "DB" 
								LET l_rec_batch.batch_num = glob_batch_num 
								LET l_rec_batch.trans_date = l_rec_default.debit_date 
								LET l_rec_batch.year_num = l_rec_default.year_num 
								LET l_rec_batch.period_num = l_rec_default.period_num 
								LET l_rec_batch.control_count = glob_ctl_linetotal 
								LET l_rec_batch.control_amt = glob_ctl_amttotal 
								LET l_rec_batch.entry_person = glob_rec_kandoouser.sign_on_code 
								LET l_rec_batch.entry_date = today 
								INSERT INTO batch VALUES (l_rec_batch.*) 
							COMMIT WORK 
							WHENEVER ERROR CONTINUE 
							DISPLAY glob_batch_num TO batch_num 

						END IF 
						IF glob_bat_amttotal != 0 
						OR glob_bat_linetotal != 0 
						OR glob_ctl_amttotal != 0 
						OR glob_ctl_linetotal != 0 THEN 
							IF glob_batch_num IS NOT NULL 
							AND glob_batch_num != 0 THEN 
							END IF 
						END IF 
					END IF 

			END INPUT 
			IF fgl_lastkey() = fgl_keyval("F8") THEN 
				LET quit_flag = true 
			END IF 
		END IF 
		WHILE not(int_flag OR quit_flag) 
			IF debithead("","","",glob_cnt) THEN 
				IF glob_cnt > 8 THEN 
					LET i = 1 
					FOR idx = ( glob_cnt - 8 ) TO ( glob_cnt - 1 ) 
						DISPLAY glob_arr_debithead[idx].* 
						TO sr_voucher[i].* 

						LET i = i + 1 
					END FOR 
				ELSE 
					DISPLAY glob_arr_debithead[glob_cnt-1].* 
					TO sr_voucher[glob_cnt-1].* 

				END IF 
				DISPLAY glob_bat_linetotal,glob_bat_amttotal TO bat_linetotal,bat_amttotal 

			ELSE 
				LET quit_flag = true 
			END IF 
		END WHILE 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_lastkey = 0 
		LET l_msgresp = kandoomsg("P",1506,"") 
		#1506 Batch Correction;  F1 Add;  F8 Batch Detail.
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		IF glob_batch_num IS NULL 
		OR glob_batch_num = 0 THEN 
			RETURN 
		END IF 
		WHILE l_lastkey = 0 
			CALL set_count(glob_cnt-1) 
			INPUT ARRAY glob_arr_debithead WITHOUT DEFAULTS FROM sr_debithead.* 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","P64","inp-arr-debithead-1") 

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
					LET l_scroll_flag = glob_arr_debithead[idx].scroll_flag 
					DISPLAY glob_arr_debithead[idx].* 
					TO sr_debithead[scrn].* 

				AFTER FIELD scroll_flag 
					LET glob_arr_debithead[idx].scroll_flag = l_scroll_flag 
					IF fgl_lastkey() = fgl_keyval("down") THEN 
						IF arr_curr() = arr_count() THEN 
							LET l_msgresp=kandoomsg("P",9001,"") 
							#9001 There are no more rows in the direction ...
							NEXT FIELD scroll_flag 
						ELSE 
							IF glob_arr_debithead[idx+1].vend_code IS NULL THEN 
								LET l_msgresp=kandoomsg("P",9001,"") 
								#9001 There are no more rows in the direction ...
								NEXT FIELD scroll_flag 
							END IF 
						END IF 
					END IF 
				BEFORE FIELD line_num 
					IF debithead(glob_arr_debithead[idx].vend_code, 
					glob_arr_debithead[idx].debit_num, 
					glob_arr_debithead[idx].total_amt,idx) THEN 
						DISPLAY glob_bat_linetotal,glob_bat_amttotal TO bat_linetotal,bat_amttotal 

					END IF 
					NEXT FIELD scroll_flag 
				AFTER ROW 
					DISPLAY glob_arr_debithead[idx].* 
					TO sr_debithead[scrn].* 


			END INPUT 
			LET l_lastkey = fgl_lastkey() 
		END WHILE 
		IF int_flag OR quit_flag 
		OR l_lastkey = fgl_keyval("accept") THEN 
			IF glob_bat_linetotal != 0 
			OR glob_bat_amttotal != 0 
			OR glob_ctl_amttotal != 0 
			OR glob_ctl_linetotal != 0 THEN 
				IF glob_batch_num IS NOT NULL 
				AND glob_batch_num != 0 THEN 
					LET l_bal_flag = true 
					LET l_exit_flag = "Y" 
					IF glob_bat_linetotal != glob_ctl_linetotal 
					OR glob_bat_amttotal != glob_ctl_amttotal THEN 
						LET l_bal_flag = false 
						LET l_exit_flag = kandoomsg("P",8011,"") 
						#8011 Batch IS NOT in balance.  Do you wish TO quit?
					END IF 
				END IF 
				IF l_exit_flag = "N" THEN 
					CONTINUE WHILE 
				ELSE 
					IF l_bal_flag = true THEN 
						DELETE FROM batch 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND batch_num = glob_batch_num 
						AND entry_person = glob_rec_kandoouser.sign_on_code 
					ELSE 
						LET l_rec_batch.trans_date = l_rec_default.debit_date 
						LET l_rec_batch.year_num = l_rec_default.year_num 
						LET l_rec_batch.period_num = l_rec_default.period_num 
						LET l_rec_batch.control_count = glob_ctl_linetotal 
						LET l_rec_batch.control_amt = glob_ctl_amttotal 
						UPDATE batch 
						SET * = l_rec_batch.* 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND entry_person = glob_rec_kandoouser.sign_on_code 
						AND batch_num = l_rec_batch.batch_num 
					END IF 
				END IF 
			ELSE 
				LET l_rec_batch.trans_date = l_rec_default.debit_date 
				LET l_rec_batch.year_num = l_rec_default.year_num 
				LET l_rec_batch.period_num = l_rec_default.period_num 
				LET l_rec_batch.control_count = glob_ctl_linetotal 
				LET l_rec_batch.control_amt = glob_ctl_amttotal 
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

FUNCTION debithead(p_vend_code,p_debit_num,p_line_total,p_arr_cnt) 
	DEFINE p_vend_code LIKE debithead.vend_code 
	DEFINE p_debit_num LIKE debithead.debit_num 
	DEFINE p_line_total LIKE debithead.total_amt 
	DEFINE p_arr_cnt SMALLINT
	DEFINE l_update_ind CHAR(1) 

	IF p_vend_code IS NULL THEN 
		LET l_update_ind = '1' 
	ELSE 
		LET l_update_ind = '2' 
	END IF 
	OPEN WINDOW p117 with FORM "P117" 
	CALL windecoration_p("P117") 

	CLEAR FORM 
	CALL enter_debit(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, p_vend_code, p_debit_num) 
	RETURNING glob_rec_debithead.* 
	IF glob_rec_debithead.vend_code IS NOT NULL 
	AND glob_rec_debithead.batch_num IS NULL THEN 
		LET glob_rec_debithead.batch_num = glob_batch_num 
	END IF 
	LET glob_rec_debithead.debit_num = my_menu(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, 
	glob_rec_debithead.*, l_update_ind) 
	CLOSE WINDOW p117 
	IF glob_rec_debithead.debit_num > 0 THEN 
		LET glob_arr_debithead[p_arr_cnt].scroll_flag = NULL 
		LET glob_arr_debithead[p_arr_cnt].line_num = p_arr_cnt 
		LET glob_arr_debithead[p_arr_cnt].debit_num = glob_rec_debithead.debit_num 
		LET glob_arr_debithead[p_arr_cnt].vend_code = glob_rec_debithead.vend_code 
		LET glob_arr_debithead[p_arr_cnt].debit_text = glob_rec_debithead.debit_text[1,16] 
		LET glob_arr_debithead[p_arr_cnt].dist_amt = glob_rec_debithead.dist_amt 
		LET glob_arr_debithead[p_arr_cnt].total_amt = glob_rec_debithead.total_amt 
		IF p_debit_num IS NULL THEN 
			LET glob_bat_linetotal = glob_bat_linetotal + 1 
			LET glob_bat_amttotal = glob_bat_amttotal + glob_rec_debithead.total_amt 
			LET glob_cnt = glob_cnt + 1 
		ELSE 
			LET glob_bat_amttotal = glob_bat_amttotal 
			- p_line_total 
			+ glob_rec_debithead.total_amt 
		END IF 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 



