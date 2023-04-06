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

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P3_GLOBALS.4gl" 
GLOBALS "../ap/P34_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################

############################################################
# FUNCTION P34_main()
#
# Purpose - Generate Cheques & Applies them TO Vouchers
############################################################
FUNCTION P34_main()
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cnt INTEGER

	DEFER quit 
	DEFER interrupt 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	LET glob_cycle_num = 1 

	OPEN WINDOW p143 WITH FORM "P143" 
	CALL windecoration_p("P143") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF STATUS = NOTFOUND THEN 
		#LET l_msgresp=kandoomsg("P",5000,"") 
		#U5000 - Company Not Found"
		CALL msgerror("",kandoomsg2("P",5000,"")) 
		CLOSE WINDOW p143 
		EXIT PROGRAM 
	END IF 
	CALL db_glparms_get_rec("1") RETURNING glob_rec_glparms.* 
	#SELECT * INTO glob_rec_glparms.* FROM glparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   AND key_code = "1"
	IF glob_rec_glparms IS NULL THEN #if status = NOTFOUND THEN 
		#LET l_msgresp=kandoomsg('P',5007,'') 
		#P5007 General Ledger...
		CALL msgerror("",kandoomsg2('P',5007,''))
		CLOSE WINDOW p143 
		EXIT PROGRAM 
	END IF 
	SELECT COUNT(*) INTO l_cnt FROM tentpays 
	WHERE tentpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tentpays.cycle_num = glob_cycle_num 
	AND tentpays.status_ind = 1 
	IF l_cnt = 0 THEN 
		#LET l_msgresp=kandoomsg("P",7030,"") 
		#7030 No Vouchers Requiring Payment were Selected
		CALL msgerror("",kandoomsg2("P",7030,""))
		CLOSE WINDOW p143 
		EXIT PROGRAM 
	ELSE 
		IF NOT change_status("START",1) THEN 
			CLOSE WINDOW p143 
			EXIT PROGRAM 
		END IF 
	END IF 
	##now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	#   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#IF STATUS = NOTFOUND THEN
	#   ERROR " Parameters Not Found, See Menu PZP"
	#   sleep 3
	#   IF change_status("FINISH",1) THEN END IF  #hmmmm , am I misunderstanding this ?
	#   EXIT PROGRAM
	#END IF
	#
	# Default PRINT criteria IS Print Selection
	#
	LET glob_print_all_ind = FALSE 
	#
	# Create temp. table
	#
	CREATE temp TABLE t_docid # reqd. FOR both modes 
	( doc_id INTEGER , 
	page_no INTEGER , 
	vouch_code INTEGER ) WITH NO LOG 

	SELECT UNIQUE 1 FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = 1 
	AND pay_meth_ind = "1" 
	IF STATUS != NOTFOUND THEN 
		LET glob_pay_meth_ind = "1" 
		#
		# Note: The cheque_passwd FUNCTION will reset the statys flag on
		# the tenthead TO allow P34 TO be restarted AFTER a DEL FROM the
		# password window.
		#
		IF get_kandoooption_feature_state('AP','CH') = 'Y' OR get_kandoooption_feature_state('AP','CH') = 2 THEN 
			CALL cheque_passwd() 
		END IF 
		CASE get_kandoooption_feature_state('AP','PS') 
			WHEN 'Y' 
				MENU " Print Cheques" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","P34","menu-print_cheque-1") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),NULL) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					ON ACTION "All" 
						#COMMAND "All" " Print all cheques selected in Payment Calculator"
						LET glob_print_all_ind = TRUE 
						EXIT MENU 

					ON ACTION "Selection" 
						#COMMAND "Selection"
						#" SELECT cheques TO PRINT FROM Payment Calculator"
						LET glob_print_all_ind = FALSE 
						EXIT MENU 

					ON ACTION "Exit" 
						#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
						LET quit_flag = TRUE 
						EXIT MENU 

				END MENU 
			OTHERWISE 
				LET glob_print_all_ind = FALSE 
		END CASE 
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			IF change_status("FINISH",1) THEN END IF 
			EXIT PROGRAM 
		END IF

		CALL rpt_rmsreps_reset(NULL)

		WHILE get_bank() 
			IF select_payment() THEN 
				# Print Cheques
				CALL print_cheques() 
				IF glob_print_all_ind THEN 
					CALL setup_range() 
				ELSE 
					CALL setup_cheqs() 
				END IF 
				SELECT UNIQUE 1 FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND status_ind = 1 
				AND pay_meth_ind = "3" 
				IF STATUS = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",7029,"") 
					#7029 Cheque Processing Complete
				END IF 
				EXIT WHILE 
			END IF 
		END WHILE 
		# Print Remittances Advices REPORT
		CALL auto_remit() 
		CLOSE WINDOW p143 
	END IF 
	#
	# Print All mode NOT available FOR EFT's
	#
	# Ensure user has NOT DEL'ed FROM Cheque Payment SCREEN
	LET glob_print_all_ind = FALSE 
	IF NOT (int_flag OR quit_flag) THEN 
		SELECT UNIQUE 1 FROM tentpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = glob_cycle_num 
		AND status_ind = 1 
		AND pay_meth_ind = "3" 
		IF STATUS != NOTFOUND THEN 
			#Create temp table TO test directory of EFT file
			CREATE temp TABLE t_testdir(pr_pay_line CHAR(10)) WITH NO LOG 
			LET glob_pay_meth_ind = "3" 
			OPEN WINDOW p500 WITH FORM "P500" 
			CALL windecoration_p("P500") 

			WHILE get_bank() 
				IF select_payment() THEN 
					# Process EFT
					CALL process_efts() 
					LET l_msgresp=kandoomsg("P",7029,"") 
					#7029 Cheque Processing Complete
					EXIT WHILE 
				END IF 
			END WHILE 
			CLOSE WINDOW p500 
		END IF 
	END IF 
	IF change_status("FINISH",1) THEN END IF 

END FUNCTION 
############################################################
# END FUNCTION P34_main()
############################################################


############################################################
# FUNCTION change_status(p_mode, p_cycle_num)
#
# # Change the Control Status
############################################################
FUNCTION change_status(p_mode,p_cycle_num) 
	DEFINE p_mode CHAR(6) 
	DEFINE p_cycle_num LIKE tentpays.cycle_num 
	DEFINE l_rec_tenthead RECORD LIKE tenthead.* 
	DEFINE l_error_text CHAR(60) 
	DEFINE l_total_pays DECIMAL(16,2) 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO next_section 
	LABEL found_error: 
	IF error_recover(l_error_text, STATUS) THEN 
		RETURN FALSE 
	END IF 
	LABEL next_section: 
	--WHENEVER ERROR CONTINUE 
	BEGIN WORK 
		SELECT * INTO l_rec_tenthead.* 
		FROM tenthead 
		WHERE cycle_num = p_cycle_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF STATUS = 0 THEN 
			CASE p_mode 
				WHEN "START" 
					CASE l_rec_tenthead.status_ind 
						WHEN 1 
							SELECT sum(vouch_amt) 
							INTO l_total_pays 
							FROM tentpays 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cycle_num = p_cycle_num 
							AND status_ind = "1" 
							IF l_total_pays <= 0 THEN 
								#LET l_msgresp=kandoomsg("P","7072","") 
								#P7072 WARNING:.....NEGATIVE OR ZERO...
								ROLLBACK WORK 
								CALL msgerror("",kandoomsg2("P","7072",""))
								RETURN FALSE 
							END IF 
							LET l_error_text = "Problems Updating Tentative Master Table - P34" 
							UPDATE tenthead 
							SET status_ind = 3, 
							status_datetime = CURRENT year TO second, 
							entry_code = glob_rec_kandoouser.sign_on_code 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cycle_num = l_rec_tenthead.cycle_num 
							COMMIT WORK 
							RETURN TRUE 
						WHEN 2 
							#LET l_msgresp = kandoomsg("P","7054",l_rec_tenthead.entry_code) 
							#P7054 - Automatic Payments are currently being edited...
							ROLLBACK WORK 
							CALL msgerror("",kandoomsg2("P","7054",l_rec_tenthead.entry_code))
							RETURN FALSE 
						WHEN 3 
							#LET l_msgresp = kandoomsg("P","7055",l_rec_tenthead.entry_code) 
							#U7055 -  Automatic Payments are currently being processe..
							ROLLBACK WORK
							CALL msgerror("",kandoomsg2("P","7055",l_rec_tenthead.entry_code))
							RETURN FALSE 
						OTHERWISE 
							ROLLBACK WORK 
							RETURN FALSE 
					END CASE 
				WHEN "FINISH" 
					### Check TO see IF there are remaining tentpays ###
					SELECT UNIQUE 1 FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = p_cycle_num 
					AND status_ind = 1 
					IF STATUS = 0 THEN 
						LET l_error_text = "Problems Updating Tentative Master Table(2) - P34" 
						UPDATE tenthead 
						SET status_ind = 1, 
						status_datetime = CURRENT year TO second, 
						entry_code = glob_rec_kandoouser.sign_on_code 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cycle_num = p_cycle_num 
					COMMIT WORK 
					RETURN TRUE 
				ELSE 
					LET l_error_text = "Problems Deleting Tentative Master Table - P34" 
					DELETE FROM tenthead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = p_cycle_num 
				COMMIT WORK 
				RETURN TRUE 
			END IF 
			END CASE 
		ELSE 
			IF STATUS = 100 THEN 
				#LET l_msgresp = kandoomsg("P","7056","") 
				#U7056 - Automatic Payments do...
				ROLLBACK WORK 
				CALL msgerror("",kandoomsg2("P","7056",""))
				RETURN FALSE 
			END IF 
		END IF 
END FUNCTION 
############################################################
# END FUNCTION P34_main()
############################################################


############################################################
# FUNCTION cheque_passwd()
#
#
############################################################
FUNCTION cheque_passwd() 
	DEFINE l_passwd_text1 CHAR(8) 
	DEFINE l_passwd_text2 CHAR(8) 
	DEFINE l_user_desc1 CHAR(40) 
	DEFINE l_user_desc2 CHAR(40) 
	DEFINE l_header_text_text CHAR(60) 
	DEFINE l_attempt_cnt SMALLINT 
	DEFINE l_stat SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_attempt_cnt = 0 
	OPEN WINDOW p510 WITH FORM "P510" 
	CALL windecoration_p("P510") 

	CASE 
		WHEN get_kandoooption_feature_state('AP','CH') = 'Y' 
			LET l_header_text_text = "One Password IS required FOR Cheque Print" 
		WHEN get_kandoooption_feature_state('AP','CH') = 2 
			LET l_header_text_text = "Two Passwords are required FOR Cheque Print" 
	END CASE 
	DISPLAY l_header_text_text TO number_passwd 

	LET l_msgresp = kandoomsg("U",1001,"") 

	INPUT glob_user_text1, l_passwd_text1 WITHOUT DEFAULTS FROM user_text1, passwd_text1 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P34","inp-user-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD user_text1 
			IF glob_user_text1 IS NULL THEN 
				#LET l_msgresp = kandoomsg("U",5001,"") 
				ERROR kandoomsg2("U",5001,"")
				NEXT FIELD user_text1 
			ELSE 
				SELECT name_text INTO l_user_desc1 FROM kandoouser 
				WHERE sign_on_code = glob_user_text1 
				IF STATUS = NOTFOUND THEN 
					#LET l_msgresp = kandoomsg("U",5001,"") 
					ERROR kandoomsg2("U",5001,"")
					NEXT FIELD user_text1 
				END IF 
			END IF 
			DISPLAY l_user_desc1 TO user_desc1 

		AFTER FIELD passwd_text1 
			LET l_attempt_cnt = l_attempt_cnt + 1 
			IF l_attempt_cnt = 4 THEN 
				#LET l_msgresp=kandoomsg("U",5003,"Cheque OR EFT Payment") 
				ERROR kandoomsg2("U",5003,"Cheque OR EFT Payment")
				EXIT INPUT 
			ELSE 
				IF l_passwd_text1 IS NULL THEN 
					#LET l_msgresp = kandoomsg("U",9002,"") 
					ERROR kandoomsg2("U",9002,"")
					NEXT FIELD passwd_text1 
				ELSE 
					SELECT UNIQUE 1 FROM kandoouser 
					WHERE sign_on_code = glob_user_text1 
					AND password_text = l_passwd_text1 
					IF STATUS = NOTFOUND THEN 
						#LET l_msgresp=kandoomsg("U",9002,"") 
						ERROR kandoomsg2("U",9002,"")
						NEXT FIELD passwd_text1 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_user_text1 IS NULL THEN 
					#LET l_msgresp = kandoomsg("U",5001,"") 
					ERROR kandoomsg2("U",5001,"")
					NEXT FIELD user_text1 
				ELSE 
					SELECT name_text INTO l_user_desc1 FROM kandoouser 
					WHERE sign_on_code = glob_user_text1 
					IF STATUS = NOTFOUND THEN 
						#LET l_msgresp = kandoomsg("U",5001,"") 
						ERROR kandoomsg2("U",5001,"")
						NEXT FIELD user_text1 
					END IF 
				END IF 
				IF l_passwd_text1 IS NULL THEN 
					#LET l_msgresp = kandoomsg("U",9002,"") 
					ERROR kandoomsg2("U",9002,"")
					NEXT FIELD passwd_text1 
				ELSE 
					SELECT UNIQUE 1 FROM kandoouser 
					WHERE sign_on_code = glob_user_text1 
					AND password_text = l_passwd_text1 
					IF STATUS = NOTFOUND THEN 
						#LET l_msgresp=kandoomsg("U",9002,"") 
						ERROR kandoomsg2("U",9002,"")
						NEXT FIELD passwd_text1 
					END IF 
				END IF 
				DISPLAY " " TO passwd_text1 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW p510 
		LET l_stat = change_status("FINISH",1) 
		EXIT PROGRAM 
	END IF 
	IF l_attempt_cnt = 4 THEN 
		CLOSE WINDOW p510 
		LET l_stat = change_status("FINISH",1) 
		EXIT PROGRAM 
	END IF 
	IF get_kandoooption_feature_state('AP','CH') = 2 THEN 
		LET l_attempt_cnt = 0 

		INPUT glob_user_text2, l_passwd_text2 WITHOUT DEFAULTS FROM user_text2, passwd_text2 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","P34","inp-user-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER FIELD user_text2 
				IF glob_user_text2 = glob_user_text1 THEN 
					#LET l_msgresp = kandoomsg("P",9073,"") 
					ERROR kandoomsg2("P",9073,"")
					NEXT FIELD user_text2 
				ELSE 
					IF glob_user_text1 IS NULL THEN 
						#LET l_msgresp = kandoomsg("U",5001,"") 
						ERROR kandoomsg2("U",5001,"")
						NEXT FIELD user_text1 
					ELSE 
						SELECT name_text INTO l_user_desc2 FROM kandoouser 
						WHERE sign_on_code = glob_user_text2 
						IF STATUS = NOTFOUND THEN 
							#LET l_msgresp = kandoomsg("U",5001,"") 
							ERROR kandoomsg2("U",5001,"")
							NEXT FIELD user_text2 
						END IF 
					END IF 
					DISPLAY l_user_desc2 TO user_desc2 

				END IF 

			AFTER FIELD passwd_text2 
				LET l_attempt_cnt = l_attempt_cnt + 1 
				IF l_attempt_cnt = 4 THEN 
					#LET l_msgresp=kandoomsg("U",5003,"Cheque OR EFT Payment") 
					ERROR kandoomsg2("U",5003,"Cheque OR EFT Payment")
					EXIT INPUT 
				ELSE 
					IF l_passwd_text2 IS NULL THEN 
						#LET l_msgresp = kandoomsg("U",9002,"") 
						ERROR kandoomsg2("U",9002,"")
						NEXT FIELD passwd_text2 
					ELSE 
						SELECT UNIQUE 1 FROM kandoouser 
						WHERE sign_on_code = glob_user_text2 
						AND password_text = l_passwd_text2 
						IF STATUS = NOTFOUND THEN 
							#LET l_msgresp = kandoomsg("U",9002,"") 
							ERROR kandoomsg2("U",9002,"")
							NEXT FIELD passwd_text2 
						END IF 
					END IF 
				END IF 

			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					IF glob_user_text2 = glob_user_text1 THEN 
						#LET l_msgresp = kandoomsg("P",9073,"") 
						ERROR kandoomsg2("P",9073,"")
						NEXT FIELD user_text2 
					ELSE 
						IF glob_user_text2 IS NULL THEN 
							#LET l_msgresp = kandoomsg("U",5001,"") 
							ERROR kandoomsg2("U",5001,"")
							NEXT FIELD user_text2 
						ELSE 
							SELECT name_text INTO l_user_desc2 FROM kandoouser 
							WHERE sign_on_code = glob_user_text2 
							IF STATUS = NOTFOUND THEN 
								#LET l_msgresp = kandoomsg("U",5001,"") 
								ERROR kandoomsg2("U",5001,"")
								NEXT FIELD user_text2 
							END IF 
						END IF 
					END IF 
					IF l_passwd_text2 IS NULL THEN 
						#LET l_msgresp = kandoomsg("U",9002,"") 
						ERROR kandoomsg2("U",9002,"")
						NEXT FIELD passwd_text2 
					ELSE 
						SELECT UNIQUE 1 FROM kandoouser 
						WHERE sign_on_code = glob_user_text2 
						AND password_text = l_passwd_text2 
						IF STATUS = NOTFOUND THEN 
							#LET l_msgresp = kandoomsg("U",9002,"") 
							ERROR kandoomsg2("U",9002,"")
							NEXT FIELD passwd_text2 
						END IF 
					END IF 
					DISPLAY " " TO passwd_text2 
				END IF 
		END INPUT 
	END IF 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW p510 
		LET l_stat = change_status("FINISH",1) 
		EXIT PROGRAM 
	END IF 
	IF l_attempt_cnt = 4 THEN 
		CLOSE WINDOW p510 
		LET l_stat = change_status("FINISH",1) 
		EXIT PROGRAM 
	END IF 
	CLOSE WINDOW p510 
END FUNCTION 
############################################################
# FUNCTION cheque_passwd()
############################################################


############################################################
# FUNCTION get_bank()
#
#
############################################################
FUNCTION get_bank() 
	DEFINE l_vendor_curr_code LIKE vendor.currency_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	SELECT * INTO glob_rec_bank.* FROM bank 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	acct_code = glob_rec_apparms.bank_acct_code 
--	DISPLAY BY NAME glob_rec_bank.currency_code -- albo 
 
	LET l_msgresp=kandoomsg("P",1051,"") 
	#1051 Enter Bank Code - ESC TO Continue
	INPUT BY NAME glob_rec_bank.bank_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P34","inp-bank-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) 
			IF infield (bank_code) THEN 
				CALL show_bank(glob_rec_kandoouser.cmpy_code) 
				RETURNING glob_rec_bank.bank_code, 
				glob_rec_cheque.bank_acct_code 
				DISPLAY BY NAME glob_rec_bank.bank_code 
				NEXT FIELD bank_code 
			END IF 

		AFTER FIELD bank_code 
			SELECT * INTO glob_rec_bank.* FROM bank 
			WHERE bank_code = glob_rec_bank.bank_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF STATUS = NOTFOUND THEN 
				#LET l_msgresp=kandoomsg("P",9003,"") 
				#9003 Bank Code NOT found - Try Window"
				ERROR kandoomsg2("P",9003,"")
				NEXT FIELD bank_code 
			END IF 
			DECLARE c1_tentpays CURSOR FOR 
			SELECT * FROM tentpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			AND pay_meth_ind = glob_pay_meth_ind 
			OPEN c1_tentpays 
			FETCH c1_tentpays INTO glob_rec_tentpays.* 
			IF STATUS != NOTFOUND THEN 
				SELECT currency_code INTO l_vendor_curr_code FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = glob_rec_tentpays.vend_code 
				IF l_vendor_curr_code <> glob_rec_bank.currency_code THEN 
					ERROR " Bank currency must be ",l_vendor_curr_code, 
					" as selected in Automatic Cheque Run(P31)" 
					NEXT FIELD bank_code 
				END IF 
			END IF 
			IF glob_pay_meth_ind = "3" THEN 
				IF glob_rec_bank.type_code IS NULL THEN 
					ERROR " Bank type has NOT been defined FOR this bank" 
					NEXT FIELD bank_code 
				END IF 
				SELECT * INTO glob_rec_banktype.* FROM banktype 
				WHERE type_code = glob_rec_bank.type_code 
				IF STATUS = NOTFOUND THEN 
					ERROR " Bank type has NOT been defined FOR this bank" 
					NEXT FIELD bank_code 
				END IF 
				IF glob_rec_banktype.eft_format_ind != 1 
				AND glob_rec_banktype.eft_format_ind != 5 THEN 
					#LET l_msgresp=kandoomsg("P",9127,"") 
					#9127 EFT file FORMAT NOT available - Check Bank Type parameters
					ERROR kandoomsg2("P",9127,"")
					NEXT FIELD bank_code 
				END IF 
				WHENEVER ERROR CONTINUE 
				LET glob_path_name = glob_rec_banktype.eft_path_text CLIPPED,"/","tempfile" 
				DELETE FROM t_testdir 
				UNLOAD TO glob_path_name 
				SELECT * FROM t_testdir 
				IF STATUS = -806 THEN 
					#LET l_msgresp=kandoomsg("P",9128,"") 
					#9128 " EFT directory NOT found - Check Bank Type parameters"
					--WHENEVER ERROR stop 
					ERROR kandoomsg2("P",9128,"")
					NEXT FIELD bank_code 
				END IF 
				# Check IF file exists by inserting INTO temporary temp table
				--WHENEVER ERROR CONTINUE 
				DELETE FROM t_testdir 
				LET glob_path_name = glob_rec_banktype.eft_path_text CLIPPED,"/", 
											glob_rec_banktype.eft_file_text CLIPPED 
				LOAD FROM glob_path_name INSERT INTO t_testdir 
				IF STATUS = 0 THEN 
					LET l_msgresp = kandoomsg("P",8017,"") 
					#8017 "EFT file already exists. Overwrite? (Y/N)"
					IF l_msgresp matches "[Nn]" THEN 
						--WHENEVER ERROR stop 
						NEXT FIELD bank_code 
					END IF 
				END IF 
				--WHENEVER ERROR stop 
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				SELECT UNIQUE 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code = glob_rec_bank.next_eft_ref_num 
				AND bank_acct_code = glob_rec_bank.acct_code 
				AND pay_meth_ind = glob_pay_meth_ind 
				IF STATUS != NOTFOUND THEN 
					#LET l_msgresp=kandoomsg("P",9052,glob_rec_bank.next_eft_ref_num) 
					#9052 EFT reference Number n already issued
					ERROR kandoomsg2("P",9052,glob_rec_bank.next_eft_ref_num)
					NEXT FIELD cheq_code 
				END IF 
				SELECT UNIQUE 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND eft_run_num = glob_rec_bank.next_eft_run_num 
				AND bank_acct_code = glob_rec_bank.acct_code 
				AND pay_meth_ind = glob_pay_meth_ind 
				IF STATUS != NOTFOUND THEN 
					#LET l_msgresp=kandoomsg("P",9053,glob_rec_bank.next_eft_run_num) 
					#9053 EFT Run Number n already issued
					ERROR kandoomsg2("P",9053,glob_rec_bank.next_eft_run_num)
					NEXT FIELD cheq_code 
				END IF 
			END IF 
			DISPLAY BY NAME glob_rec_bank.name_acct_text 
			DISPLAY BY NAME glob_rec_bank.currency_code 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		#Do NOT CLEAR int_flag OR quit_flag....
		RETURN FALSE 
	ELSE 
		--WHENEVER ERROR CONTINUE 
		UPDATE tenthead 
		SET bank_code = glob_rec_bank.bank_code 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = glob_cycle_num 
		--WHENEVER ERROR stop 
		IF STATUS <> 0 THEN 
			RETURN FALSE 
		END IF 
		RETURN TRUE 
	END IF 
END FUNCTION 
############################################################
# FUNCTION get_bank()
############################################################


############################################################
# FUNCTION select_payment()
#
#
############################################################
FUNCTION select_payment() 
	DEFINE l_print_them CHAR(1) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_save_vend LIKE vendor.vend_code 
	DEFINE l_save_tax_ind LIKE tentpays.withhold_tax_ind 
	DEFINE l_save_cust LIKE voucher.source_text 
	DEFINE l_save_source_ind LIKE voucher.source_ind 
	DEFINE l_doc_id INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT

	FOR idx = 1 TO 3000 
		INITIALIZE glob_arr_rec_tentpays[idx].* TO NULL 
	END FOR 
	IF glob_print_all_ind THEN 
		LET l_where_text = " 1=1 " 
	ELSE 
		LET l_msgresp=kandoomsg("P",1001,"") 
		#1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON tentpays.vend_code, 
		tentpays.vouch_code, 
		tentpays.due_date, 
		tentpays.vouch_amt, 
		tentpays.taken_disc_amt, 
		tentpays.withhold_tax_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P34","construct-tentpays-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			RETURN FALSE 
		END IF 
	END IF 
	LET l_query_text = "SELECT * FROM tentpays ", 
	"WHERE tentpays.cmpy_code = '" ,glob_rec_kandoouser.cmpy_code, "' ", 
	"AND tentpays.pay_meth_ind = '", glob_pay_meth_ind, "' ", 
	"AND tentpays.status_ind = 1 ", 
	"AND tentpays.cycle_num = ", glob_cycle_num, 
	" AND ", l_where_text CLIPPED, " ", 
	"ORDER BY vend_code, withhold_tax_ind, ", 
	"source_ind, source_text, ", 
	"vouch_code" 

	PREPARE s_tentpays FROM l_query_text 
	DECLARE c_tentpays CURSOR FOR s_tentpays 

	LET idx = 0 
	LET glob_total_to_pay = 0 
	LET l_doc_id = 0 
	LET l_save_vend = " " 
	FOREACH c_tentpays INTO glob_rec_tentpays.* 
		#
		# Check FOR break in doc_id with following hierarchy :
		#
		#                 1. vend_code
		#                 2. withhold_tax_ind
		#                 3. source_ind
		#                 4. source_text
		#
		IF glob_rec_tentpays.vend_code != l_save_vend THEN 
			LET l_doc_id = l_doc_id + 1 
		ELSE 
			IF glob_rec_tentpays.withhold_tax_ind != l_save_tax_ind THEN 
				LET l_doc_id = l_doc_id + 1 
			ELSE 
				IF glob_rec_tentpays.source_ind = "8" THEN 
					IF l_save_source_ind = "8" THEN 
						IF glob_rec_tentpays.source_text != l_save_cust THEN 
							LET l_doc_id = l_doc_id + 1 
						END IF 
					ELSE 
						LET l_doc_id = l_doc_id + 1 
					END IF 
				ELSE 
					IF l_save_source_ind = "8" THEN 
						LET l_doc_id = l_doc_id + 1 
					END IF 
				END IF 
			END IF 
		END IF 
		IF NOT glob_print_all_ind THEN 
			LET idx = idx + 1 
			IF idx = 3000 THEN 
				#
				# Maximum ARRAY size = 2999
				#
				# The 3000'th ARRAY element IS used TO check FOR a
				# continuation of a logical doc_id.
				# IF this IS the CASE, THEN we need TO delete all ARRAY entries
				# with a matching doc_id.
				#
				# This logic ensure's that we don't split a logical doc_id
				# over separate runs.
				#
				INITIALIZE glob_arr_rec_tentpays[idx].* TO NULL 
				FOR idx = 2999 TO 1 step -1 
					IF glob_arr_doc_nums[idx] = l_doc_id THEN 
						LET glob_total_to_pay = glob_total_to_pay 
						- glob_arr_rec_tentpays[idx].vouch_amt 
						UPDATE tentpays 
						SET pay_doc_num = NULL 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cycle_num = glob_cycle_num 
						AND vend_code = glob_arr_rec_tentpays[idx].vend_code 
						AND vouch_code = glob_arr_rec_tentpays[idx].vouch_code 
						INITIALIZE glob_arr_rec_tentpays[idx].* TO NULL 
						INITIALIZE glob_arr_doc_nums[idx] TO NULL 
					ELSE 
						EXIT FOR 
					END IF 
				END FOR 
				LET l_msgresp=kandoomsg("P",9042,idx) 
				#9042 First idx entries selected
				EXIT FOREACH 
			END IF 
			LET glob_arr_rec_tentpays[idx].cheq_code = NULL 
			LET glob_arr_rec_tentpays[idx].vend_code = glob_rec_tentpays.vend_code 
			LET glob_arr_rec_tentpays[idx].vouch_code = glob_rec_tentpays.vouch_code 
			LET glob_arr_rec_tentpays[idx].due_date = glob_rec_tentpays.due_date 
			LET glob_arr_rec_tentpays[idx].vouch_amt = glob_rec_tentpays.vouch_amt 
			LET glob_arr_rec_tentpays[idx].taken_disc_amt = glob_rec_tentpays.taken_disc_amt 
			LET glob_arr_rec_tentpays[idx].withhold_tax_ind = glob_rec_tentpays.withhold_tax_ind 
			LET glob_arr_doc_nums[idx] = l_doc_id 
		END IF 
		UPDATE tentpays 
		SET pay_doc_num = l_doc_id 
		WHERE cmpy_code = glob_rec_tentpays.cmpy_code 
		AND cycle_num = glob_rec_tentpays.cycle_num 
		AND vend_code = glob_rec_tentpays.vend_code 
		AND vouch_code = glob_rec_tentpays.vouch_code 
		LET glob_total_to_pay = glob_total_to_pay + glob_rec_tentpays.vouch_amt 
		LET l_save_vend = glob_rec_tentpays.vend_code 
		LET l_save_tax_ind = glob_rec_tentpays.withhold_tax_ind 
		LET l_save_cust = glob_rec_tentpays.source_text 
		LET l_save_source_ind = glob_rec_tentpays.source_ind 
	END FOREACH 

	DISPLAY glob_total_to_pay TO total_pay 
 
	IF NOT glob_print_all_ind THEN 
		LET glob_arr_size = idx 
		IF glob_arr_size = 0 THEN 
			# This should never occur
			RETURN FALSE 
		END IF 

		CALL set_count(glob_arr_size) 
		LET l_msgresp=kandoomsg("P",1008,"") 
		#1008 F3/F4 Page Fwd/Bwd - ESC TO Continue"
		DISPLAY ARRAY glob_arr_rec_tentpays TO sr_tentpays.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","P34","display-arr-tentpays") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			RETURN FALSE 
		END IF 
	END IF 

	IF glob_pay_meth_ind = "1" THEN 
      # Automatic Cheque Print
		OPEN WINDOW p180 WITH FORM "P180" 
		CALL windecoration_p("P180") 
	ELSE 
		# Generate EFT Payments
		OPEN WINDOW p501 WITH FORM "P501" 
		CALL windecoration_p("P501") 
	END IF 

	LET l_print_them = "Y" 
	LET glob_chq_prt_date = TODAY 

	DISPLAY 
	l_print_them, 
	glob_chq_prt_date 
	TO 
	print_them, 
	chq_prt_date 

	INPUT l_print_them, glob_chq_prt_date WITHOUT DEFAULTS FROM print_them, chq_prt_date 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P34","inp-PRINT-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD print_them 
			IF l_print_them != "Y" THEN 
				LET int_flag = TRUE 
				LET quit_flag = TRUE 
				EXIT INPUT 
			END IF 

		AFTER INPUT 
			IF l_print_them != "Y" THEN 
				LET int_flag = TRUE 
				LET quit_flag = TRUE 
				EXIT INPUT 
			END IF 
			IF glob_chq_prt_date IS NULL THEN 
				#LET l_msgresp=kandoomsg("P",9190,"") 
				#9190 The cheque date IS NOT valid.
				ERROR kandoomsg2("P",9190,"")
				NEXT FIELD chq_prt_date 
			END IF 

			IF glob_chq_prt_date > TODAY + 30 THEN 
				LET l_msgresp=kandoomsg("P",8018,"") 
				#1008 Warning: Date IS 30 days FROM TODAY. Continue? (Y?N)
				IF l_msgresp = "N" OR l_msgresp = "n" THEN 
					NEXT FIELD chq_prt_date 
				END IF 
			END IF 

			IF glob_chq_prt_date < TODAY - 30 THEN 
				LET l_msgresp=kandoomsg("P",8019,"") 
				#1008 Warning: Date IS 30 days less than TODAY. Continue? (Y?N)
				IF l_msgresp = "N" OR l_msgresp = "n" THEN 
					NEXT FIELD chq_prt_date 
				END IF 
			END IF 

			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_chq_prt_date) 
			RETURNING glob_year_num, glob_period_num 
			IF NOT valid_period2(glob_rec_kandoouser.cmpy_code,glob_year_num,glob_period_num,"ap") THEN 
				#LET l_msgresp=kandoomsg("G",9013,"") 
				ERROR kandoomsg2("G",9013,"")
				NEXT FIELD chq_prt_date 
			END IF 

	END INPUT 

	IF glob_pay_meth_ind = "1" THEN 
		CLOSE WINDOW p180 
	ELSE 
		CLOSE WINDOW p501 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		--WHENEVER ERROR CONTINUE 
		UPDATE tenthead 
		SET cheq_date = glob_chq_prt_date 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = glob_cycle_num 
		--WHENEVER ERROR stop 
		IF STATUS <> 0 THEN 
			RETURN FALSE 
		END IF 
		RETURN TRUE 
	END IF 

END FUNCTION 
############################################################
# FUNCTION select_payment()
############################################################


############################################################
# FUNCTION setup_cheqs()
#
#
############################################################
FUNCTION setup_cheqs() 
	DEFINE l_save_doc_id INTEGER 
	DEFINE l_save_cheq LIKE tentpays.vouch_amt 
	DEFINE l_idx SMALLINT 
	DEFINE l_prev_page_no INTEGER
	DEFINE l_curr_page_no INTEGER 
	DEFINE l_source_ind1 LIKE tentpays.source_ind 
	DEFINE l_source_ind2 LIKE tentpays.source_ind 
	DEFINE l_old_cheq LIKE cheque.cheq_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i, j, idx, scrn SMALLINT

	CALL set_count(glob_arr_size) 
	LET l_msgresp=kandoomsg("P",1049,"") 
	#1049 Enter Starting Cheque Number - F5 Voucher Detail"
	INPUT ARRAY glob_arr_rec_tentpays WITHOUT DEFAULTS FROM sr_tentpays.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P34","inp-arr-tentpays-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF idx > glob_arr_size THEN 
				LET l_msgresp=kandoomsg("P",9001,"") 
				#9001 "There no more rows in the direction you are going"
				NEXT FIELD cheq_code 
			END IF 
		BEFORE FIELD cheq_code 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF glob_arr_rec_tentpays[idx].cheq_code IS NOT NULL THEN 
				DISPLAY glob_arr_rec_tentpays[idx].cheq_code 
				TO sr_tentpays[scrn].cheq_code 

				LET l_msgresp=kandoomsg("P",1050,"") 
				#1050 Edit Cheque Numbers - F5 Voucher Detail - ESC TO Continue"
			END IF 
		ON KEY (F5) 
			CALL display_voucher_header(glob_rec_kandoouser.cmpy_code, glob_arr_rec_tentpays[idx].vouch_code) 
			NEXT FIELD vend_code 
		AFTER FIELD cheq_code 
			IF glob_arr_rec_tentpays[idx].cheq_code IS NULL AND 
			glob_arr_rec_tentpays[idx].vouch_code IS NULL 
			THEN 
			ELSE 
				IF glob_arr_rec_tentpays[idx].cheq_code IS NULL THEN 
					LET l_msgresp=kandoomsg("P",9009,"") 
					#9009 A Valid Cheque Number Must be Entered"
					NEXT FIELD cheq_code 
				END IF 
				IF glob_arr_rec_tentpays[idx].vouch_code IS NULL THEN 
					#No Voucher on this Line"
					NEXT FIELD cheq_code 
				END IF 
				SELECT UNIQUE 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code = glob_arr_rec_tentpays[idx].cheq_code 
				AND bank_acct_code = glob_rec_bank.acct_code 
				AND pay_meth_ind = glob_pay_meth_ind 
				IF STATUS != NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9010,glob_arr_rec_tentpays[idx].cheq_code) 
					#9010 Cheque Number n already issued
					NEXT FIELD cheq_code 
				END IF 
			END IF 
		BEFORE FIELD vend_code 
			LET l_save_doc_id = glob_arr_doc_nums[idx] 
			LET l_save_cheq = glob_arr_rec_tentpays[idx].cheq_code 
			#
			# Each logical doc_id cannot be split over different cheq. no's
			#
			LET l_idx = idx 
			#
			# Find first entry in ARRAY with current doc_id
			#
			FOR i = ( idx - 1 ) TO 1 step -1 
				IF glob_arr_doc_nums[i] != l_save_doc_id THEN 
					EXIT FOR 
				END IF 
			END FOR 
			LET idx = i + 1 
			#
			# N.B. scrn may be negative ( handled by scrn test IF scrn > 0 ... )
			#
			LET scrn = scrn - ( l_idx - idx ) 
			MESSAGE " Stage I: Allocating Cheque Numbers" 
			WHILE idx <= glob_arr_size 
				IF glob_arr_rec_tentpays[idx].vouch_code IS NOT NULL AND 
				glob_arr_rec_tentpays[idx].vouch_code != 0 
				THEN 
					IF glob_arr_doc_nums[idx] != l_save_doc_id THEN 
						SELECT page_no 
						INTO l_prev_page_no 
						FROM t_docid 
						WHERE doc_id = l_save_doc_id 
						IF SQLCA.SQLCODE = NOTFOUND THEN 
							LET l_prev_page_no = 0 
						END IF 
						SELECT page_no 
						INTO l_curr_page_no 
						FROM t_docid 
						WHERE doc_id = glob_arr_doc_nums[idx] 
						LET l_old_cheq = glob_arr_rec_tentpays[idx].cheq_code 
						LET glob_arr_rec_tentpays[idx].cheq_code = l_save_cheq + (l_curr_page_no 
						- l_prev_page_no) 
						SELECT UNIQUE 1 FROM cheque 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cheq_code = glob_arr_rec_tentpays[idx].cheq_code 
						AND bank_acct_code = glob_rec_bank.acct_code 
						AND pay_meth_ind = glob_pay_meth_ind 
						IF STATUS != NOTFOUND THEN 
							LET l_msgresp=kandoomsg("P",9010,glob_arr_rec_tentpays[idx].cheq_code) 
							#9010 Cheque Number n already issued
							LET glob_arr_rec_tentpays[idx].cheq_code = l_old_cheq 
							NEXT FIELD cheq_code 
						END IF 
					ELSE 
						LET glob_arr_rec_tentpays[idx].cheq_code = l_save_cheq 
					END IF 
					LET l_save_doc_id = glob_arr_doc_nums[idx] 
					LET l_save_cheq = glob_arr_rec_tentpays[idx].cheq_code 
					IF scrn > 0 AND scrn < 12 THEN 
						DISPLAY glob_arr_rec_tentpays[idx].cheq_code 
						TO sr_tentpays[scrn].cheq_code 

					END IF 
				END IF 
				LET idx = idx + 1 
				LET scrn = scrn + 1 
			END WHILE 
			NEXT FIELD cheq_code 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				# I have commented out the password entry to Exit. (albo)
				# I don't understand why you need to enter the same "doitagain" password each time to Exit.
				#IF back_out() THEN 
				#	LET quit_flag = TRUE 
				#	EXIT INPUT 
				#ELSE 
				#	LET int_flag = FALSE 
				#	LET quit_flag = FALSE 
				#	NEXT FIELD cheq_code 
				#END IF 
				LET quit_flag = TRUE
				EXIT INPUT 
			END IF 
			MESSAGE " Stage II: Validating Cheques" 
			FOR i = 1 TO glob_arr_size 
				IF glob_arr_rec_tentpays[i].cheq_code IS NULL THEN 
					ERROR " Voucher on Line ",i," has a Null Cheque Number" 
					NEXT FIELD cheq_code 
				END IF 
				IF (glob_arr_rec_tentpays[i].cheq_code = glob_arr_rec_tentpays[i+1].cheq_code) AND 
				(glob_arr_rec_tentpays[i].vend_code != glob_arr_rec_tentpays[i+1].vend_code) 
				THEN 
					error" Cheque Number ", glob_arr_rec_tentpays[i].cheq_code, 
					" must be Unique TO a Vendor " 
					NEXT FIELD cheq_code 
				END IF 
				IF (glob_arr_rec_tentpays[i].cheq_code = glob_arr_rec_tentpays[i+1].cheq_code) AND 
				(glob_arr_rec_tentpays[i].withhold_tax_ind != 
				glob_arr_rec_tentpays[i+1].withhold_tax_ind) 
				THEN 
					error" Cheque Number ", glob_arr_rec_tentpays[i].cheq_code, 
					" must be Unique TO FOR each W/hold tax indicator" 
					NEXT FIELD cheq_code 
				END IF 
				IF (glob_arr_rec_tentpays[i].cheq_code != glob_arr_rec_tentpays[i+1].cheq_code) AND 
				(glob_arr_rec_tentpays[i].vend_code = glob_arr_rec_tentpays[i+1].vend_code AND 
				glob_arr_rec_tentpays[i].withhold_tax_ind = 
				glob_arr_rec_tentpays[i+1].withhold_tax_ind) 
				THEN 
					### Collect the current source_ind AND next source_ind VALUES###
					SELECT source_ind INTO l_source_ind1 
					FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					AND vend_code = glob_arr_rec_tentpays[i].vend_code 
					AND vouch_code = glob_arr_rec_tentpays[i].vouch_code 
					SELECT source_ind INTO l_source_ind2 
					FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					AND vend_code = glob_arr_rec_tentpays[i+1].vend_code 
					AND vouch_code = glob_arr_rec_tentpays[i+1].vouch_code 
					IF (l_source_ind1 != "8" AND l_source_ind2 != "8") 
					THEN 
						ERROR " Cheque Number ", glob_arr_rec_tentpays[i+1].cheq_code, 
						" must be Unique TO a Vendor " 
						NEXT FIELD cheq_code 
					END IF 
				END IF 
				FOR j = 1 TO (i-1) 
					IF (glob_arr_rec_tentpays[i].cheq_code = glob_arr_rec_tentpays[j].cheq_code) AND 
					(glob_arr_rec_tentpays[i].vend_code != glob_arr_rec_tentpays[j].vend_code) 
					THEN 
						ERROR " Cheque Number ", glob_arr_rec_tentpays[i].cheq_code, 
						" must be Unique TO a Vendor " 
						NEXT FIELD cheq_code 
					END IF 
					IF (glob_arr_rec_tentpays[i].cheq_code = glob_arr_rec_tentpays[j].cheq_code) AND 
					(glob_arr_rec_tentpays[i].withhold_tax_ind 
					!= glob_arr_rec_tentpays[j].withhold_tax_ind) 
					THEN 
						ERROR " Cheque Number ", glob_arr_rec_tentpays[i].cheq_code, 
						" must be Unique TO FOR each W/hold tax indicator" 
						NEXT FIELD cheq_code 
					END IF 
				END FOR 
				#
				# Only IF current cheque no. IS different TO next one,
				#      THEN SELECT FROM cheque table. This saves on
				#      DB I/O.
				#
				IF glob_arr_rec_tentpays[i].cheq_code != glob_arr_rec_tentpays[i+1].cheq_code 
				OR glob_arr_rec_tentpays[i+1].cheq_code IS NULL THEN 
					SELECT UNIQUE 1 FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cheq_code = glob_arr_rec_tentpays[i].cheq_code 
					AND bank_acct_code = glob_rec_bank.acct_code 
					AND pay_meth_ind = glob_pay_meth_ind 
					IF STATUS != NOTFOUND THEN 
						LET l_msgresp=kandoomsg("P",9010,glob_arr_rec_tentpays[i].cheq_code) 
						#9010 Cheque Number n already issued
						NEXT FIELD cheq_code 
					END IF 
				END IF 
			END FOR 

	END INPUT 
	IF NOT (int_flag OR quit_flag) THEN 
		CALL upd_chqs() 
	END IF 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
############################################################
# FUNCTION setup_cheqs()
############################################################


############################################################
# FUNCTION back_out()
#
#
############################################################
FUNCTION back_out() 
	DEFINE l_passwd CHAR(9) 

	DISPLAY "Cheques Not Written - Password TO Exit" at 1,1 

	LET l_passwd = fgl_winprompt(5,5, "Password TO Exit", "", 25, 255) 

	LET l_passwd = upshift(l_passwd) 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	IF l_passwd = "DOITAGAIN" THEN 
		RETURN TRUE 
	ELSE 
		RETURN FALSE 
	END IF 
END FUNCTION 
############################################################
# FUNCTION back_out()
############################################################


############################################################
# FUNCTION setup_range()
#
#
############################################################
FUNCTION setup_range() 
	DEFINE l_arr_rec_disp_vend ARRAY[3000] OF 
	RECORD 
		vend_code LIKE tentpays.vend_code, 
		page_num LIKE tentpays.page_num 
	END RECORD 
	DEFINE l_rec_range RECORD 
		scroll_flag CHAR(1), 
		line_num SMALLINT, 
		start_num LIKE cheque.cheq_code, 
		end_num LIKE cheque.cheq_code, 
		chq_cnt INTEGER, 
		start_vend LIKE cheque.vend_code, 
		end_vend LIKE cheque.vend_code 
	END RECORD 
	DEFINE l_arr_range ARRAY[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		line_num SMALLINT, 
		start_num LIKE cheque.cheq_code, 
		end_num LIKE cheque.cheq_code, 
		chq_cnt INTEGER, 
		start_vend LIKE cheque.vend_code, 
		end_vend LIKE cheque.vend_code 
	END RECORD 
	DEFINE l_start_cheq_num LIKE cheque.cheq_code 
	DEFINE l_cheque_num LIKE cheque.cheq_code
	DEFINE l_prev_chq INTEGER 
	DEFINE l_chq_cnt INTEGER
	DEFINE l_print_cnt INTEGER
	DEFINE l_pr_scrn,l_cnt_chq,l_cnt1,l_cnt2 INTEGER 
	DEFINE l_arr_cnt INTEGER
	DEFINE l_arr_count INTEGER 
	DEFINE l_lastkey INTEGER
	DEFINE l_prev_pages INTEGER
	DEFINE l_save_pages INTEGER
	DEFINE l_count INTEGER 
	DEFINE l_docid INTEGER 
	DEFINE l_vouch_code INTEGER 
	DEFINE l_page_no INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx, i, j, k, curr, scrn INTEGER

	#### All code in this FUNCTION IS related TO P3A unless OTHERWISE stated###
	### INITIALIZE ARRAY ###
	FOR i = 1 TO 100 
		INITIALIZE l_arr_range[i].* TO NULL 
		INITIALIZE glob_arr_cheque_code[i] TO NULL 
	END FOR 
	LET array_idx = 0 
	LET curr = 0 
	LET l_chq_cnt = 0 
	INITIALIZE l_rec_range.* TO NULL 
	### Fill up the Vendor DISPLAY ARRAY VALUES###
	####P34 AND P3A code below####
	DECLARE c7_tentpays CURSOR FOR 
	SELECT UNIQUE t.vend_code, d.page_no 
	FROM tentpays t, t_docid d 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cheq_code = 0 
	AND pay_meth_ind = "1" 
	AND d.doc_id = t.pay_doc_num 
	ORDER BY 2 
	####P34 AND P3A code above####
	LET l_count = 1 
	FOREACH c7_tentpays INTO l_arr_rec_disp_vend[l_count].vend_code, 
		l_arr_rec_disp_vend[l_count].page_num 
		LET l_count = l_count + 1 
	END FOREACH 
	### Highest page number represents total physical cheques used ###
	####P34 code below####
	SELECT max(page_no) INTO l_print_cnt FROM t_docid 
	####P34 code above####
	IF l_print_cnt IS NULL THEN 
		LET l_print_cnt = 0 
	END IF 
	OPEN WINDOW p239 WITH FORM "P239" 
	CALL windecoration_p("P239") 

	DISPLAY l_print_cnt, l_chq_cnt TO print_cnt, chq_cnt 

	LET l_lastkey = NULL 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(curr) 
	LET l_msgresp = kandoomsg("P",1065,"") 
	#1065 Enter Cheque No. Details - F1 TO Add - F2 TO Delete
	INPUT ARRAY l_arr_range WITHOUT DEFAULTS FROM sr_range.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P34","inp-arr-range-1") 
			CALL DIALOG.SetActionHidden("INSERT",TRUE)

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_lastkey = NULL 
			LET curr = arr_curr() 
			LET scrn = scr_line() 
			LET l_rec_range.* = l_arr_range[curr].* 
			IF l_arr_range[curr].start_num IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("right") THEN 
					NEXT FIELD line_num 
				END IF 
			ELSE 
				NEXT FIELD scroll_flag 
			END IF 

		BEFORE FIELD scroll_flag 
			DISPLAY l_arr_range[curr].* TO sr_range[scrn].* 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_range[curr].start_num IS NULL THEN 
					NEXT FIELD line_num 
				END IF 
			END IF 
			LET l_lastkey = fgl_lastkey() 

		BEFORE FIELD line_num 
			IF l_lastkey IS NULL THEN 
				LET l_lastkey = fgl_lastkey() 
			END IF 
			IF l_lastkey = fgl_keyval("left") 
			OR l_lastkey = fgl_keyval("up") 
			OR l_lastkey = fgl_keyval("interrupt") THEN 
				NEXT FIELD scroll_flag 
			ELSE 
				NEXT FIELD start_num 
			END IF 

		AFTER FIELD line_num 
			LET l_lastkey = fgl_lastkey() 

		BEFORE FIELD start_num 
			IF l_lastkey = fgl_keyval("left") 
			OR l_lastkey = fgl_keyval("up") THEN 
				NEXT FIELD scroll_flag 
			END IF 

		AFTER FIELD start_num 
			LET l_lastkey = fgl_lastkey() 
			IF (l_arr_range[curr].start_num IS NULL) OR 
			(l_arr_range[curr].start_num <= 0) THEN 
				LET l_msgresp=kandoomsg("P",9062,"") 
				#9062 Must enter start no.
				LET l_lastkey = NULL 
				NEXT FIELD start_num 
			END IF 
			CASE 
				WHEN l_lastkey = fgl_keyval("right") 
					OR l_lastkey = fgl_keyval("RETURN") 
					OR l_lastkey = fgl_keyval("tab") 
					OR l_lastkey = fgl_keyval("down") 
					NEXT FIELD NEXT 
				WHEN l_lastkey = fgl_keyval("up") 
					OR l_lastkey = fgl_keyval("left") 
					IF l_arr_range[curr].end_num IS NOT NULL THEN 
						IF l_arr_range[curr].start_num > l_arr_range[curr].end_num THEN 
							LET l_msgresp=kandoomsg("P",9063,"") 
							#9063 Starting No. ...
							LET l_lastkey = NULL 
						END IF 
					ELSE 
						INITIALIZE l_arr_range[curr].* TO NULL 
					END IF 
					NEXT FIELD start_num 
				OTHERWISE 
					IF (int_flag OR quit_flag) THEN 
						NEXT FIELD scroll_flag 
					ELSE 
						NEXT FIELD start_num 
					END IF 
			END CASE 

		AFTER FIELD end_num 
			IF (l_arr_range[curr].end_num IS NULL) OR 
			(l_arr_range[curr].end_num <= 0) THEN 
				LET l_msgresp=kandoomsg("P",9064,"") 
				#9064 Must enter END no.
				NEXT FIELD end_num 
			END IF 
			LET l_lastkey = fgl_lastkey() 
			SELECT UNIQUE 1 FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheq_code between l_arr_range[curr].start_num AND 
			l_arr_range[curr].end_num 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "1" 
			IF STATUS != NOTFOUND THEN 
				LET l_msgresp=kandoomsg("P",9010,"in this range") 
				#9010 Cheque Number n already issued
				NEXT FIELD start_num 
			END IF 
			CASE 
				WHEN l_lastkey = fgl_keyval("right") 
					OR l_lastkey = fgl_keyval("RETURN") 
					OR l_lastkey = fgl_keyval("tab") 
					OR l_lastkey = fgl_keyval("down") 
					NEXT FIELD chq_cnt 
				WHEN l_lastkey = fgl_keyval("left") 
					OR l_lastkey = fgl_keyval("up") 
					LET l_lastkey = NULL 
					NEXT FIELD previous 
				OTHERWISE 
					IF (int_flag OR quit_flag) THEN 
						NEXT FIELD scroll_flag 
					ELSE 
						NEXT FIELD end_num 
					END IF 
			END CASE 

		ON KEY (F2) 
			IF l_arr_range[curr].chq_cnt IS NOT NULL THEN 
				LET l_chq_cnt = l_chq_cnt - l_arr_range[curr].chq_cnt 
			END IF 
			INITIALIZE l_rec_range.* TO NULL 
			LET l_arr_cnt = arr_count() 
			INITIALIZE l_arr_range[l_arr_cnt+1].* TO NULL 
			DISPLAY l_chq_cnt TO chq_cnt 

			### Screen Handling FOR a deleted line ###
			LET l_cnt_chq = 0 
			FOR l_cnt1 = curr TO arr_count() 
				IF l_cnt1 = 100 THEN 
					INITIALIZE l_arr_range[l_cnt1].* TO NULL 
				ELSE 
					LET l_arr_range[l_cnt1].* = l_arr_range[l_cnt1+1].* 
				END IF 
				IF l_pr_scrn <= 9 THEN 
					DISPLAY l_arr_range[l_cnt1].* TO sr_range[l_pr_scrn].* 

					LET l_pr_scrn = l_pr_scrn + 1 
				END IF 
			END FOR 
			LET l_rec_range.* = l_arr_range[curr].* 
			### Screen Handling FOR a Vendor Code start AND END ###
			LET l_pr_scrn = scrn 
			FOR l_cnt1 = 1 TO 100 
				INITIALIZE l_rec_range.start_vend TO NULL 
				INITIALIZE l_arr_range[l_cnt1].start_vend TO NULL 
				INITIALIZE l_rec_range.end_vend TO NULL 
				INITIALIZE l_arr_range[l_cnt1].end_vend TO NULL 
				IF l_arr_range[l_cnt1].start_num IS NOT NULL THEN 
					LET l_cnt_chq = l_cnt_chq + 1 
					FOR l_cnt2 = 1 TO 3000 
						IF (l_arr_rec_disp_vend[l_cnt2].page_num != 0) THEN 
							IF (l_arr_rec_disp_vend[l_cnt2].page_num >= l_cnt_chq) THEN 
								LET l_rec_range.start_vend 
								= l_arr_rec_disp_vend[l_cnt2].vend_code 
								LET l_arr_range[l_cnt1].start_vend 
								= l_arr_rec_disp_vend[l_cnt2].vend_code 
								EXIT FOR 
							END IF 
						ELSE 
							EXIT FOR 
						END IF 
					END FOR 
					LET l_cnt_chq = l_cnt_chq + (l_arr_range[l_cnt1].end_num 
					- l_arr_range[l_cnt1].start_num) 
					IF l_cnt_chq IS NULL THEN 
						LET l_cnt_chq = 0 
					END IF 
					FOR l_cnt2 = 1 TO 3000 
						IF (l_arr_rec_disp_vend[l_cnt2].page_num != 0) THEN 
							IF (l_arr_rec_disp_vend[l_cnt2].page_num >= l_cnt_chq) 
							THEN 
								LET l_rec_range.end_vend 
								= l_arr_rec_disp_vend[l_cnt2].vend_code 
								LET l_arr_range[l_cnt1].end_vend 
								= l_arr_rec_disp_vend[l_cnt2].vend_code 
								EXIT FOR 
							END IF 
						ELSE 
							EXIT FOR 
						END IF 
					END FOR 
				ELSE 
					EXIT FOR 
				END IF 
			END FOR 
			LET l_pr_scrn = 1 
			FOR i = (curr-scrn)+1 TO curr+(9 - scrn) 
				DISPLAY l_arr_range[i].* TO sr_range[l_pr_scrn].* 

				LET l_pr_scrn = l_pr_scrn + 1 
			END FOR 
			LET l_rec_range.* = l_arr_range[curr].* 
			NEXT FIELD scroll_flag 

		BEFORE FIELD chq_cnt 
			IF l_lastkey != fgl_keyval("interrupt") THEN 
				IF l_arr_range[curr].end_num IS NOT NULL THEN 
					IF l_arr_range[curr].start_num > l_arr_range[curr].end_num THEN 
						LET l_msgresp=kandoomsg("P",9063,"") 
						#9063 Starting no. must be less than ending no.
						NEXT FIELD start_num 
					END IF 
				END IF 
				#
				# Check FOR an invalid range
				#
				FOR i = 1 TO arr_count() 
					IF i != arr_curr() THEN 
						IF NOT (l_arr_range[i].start_num< l_arr_range[curr].start_num 
						AND l_arr_range[i].end_num < l_arr_range[curr].start_num) 
						AND NOT (l_arr_range[i].start_num> l_arr_range[curr].end_num 
						AND l_arr_range[i].end_num > l_arr_range[curr].end_num) THEN 
							LET l_msgresp=kandoomsg("P",9065,"") 
							#9065 Invalid cheque range specified
							NEXT FIELD start_num 
							EXIT FOR 
						END IF 
					END IF 
				END FOR 
				IF i != (arr_count() + 1) THEN 
					NEXT FIELD start_num 
				END IF 
				IF l_arr_range[curr].chq_cnt IS NULL THEN 
					LET l_prev_chq = 0 
				ELSE 
					LET l_prev_chq = l_arr_range[curr].chq_cnt 
				END IF 
				LET l_arr_range[curr].chq_cnt = l_arr_range[curr].end_num 
				- l_arr_range[curr].start_num 
				+ 1 
				LET l_chq_cnt = l_chq_cnt 
				+ l_arr_range[curr].chq_cnt 
				- l_prev_chq 
				DISPLAY l_chq_cnt TO chq_cnt 

				### Screen Handling FOR a Vendor Code start AND END ###
				LET l_cnt_chq = 0 
				FOR l_cnt1 = 1 TO 100 
					INITIALIZE l_rec_range.start_vend TO NULL 
					INITIALIZE l_arr_range[l_cnt1].start_vend TO NULL 
					INITIALIZE l_rec_range.end_vend TO NULL 
					INITIALIZE l_arr_range[l_cnt1].end_vend TO NULL 
					IF l_arr_range[l_cnt1].start_num IS NOT NULL THEN 
						LET l_cnt_chq = l_cnt_chq + 1 
						FOR l_cnt2 = 1 TO 3000 
							IF (l_arr_rec_disp_vend[l_cnt2].page_num != 0) THEN 
								IF (l_arr_rec_disp_vend[l_cnt2].page_num >= l_cnt_chq) THEN 
									LET l_rec_range.start_vend 
									= l_arr_rec_disp_vend[l_cnt2].vend_code 
									LET l_arr_range[l_cnt1].start_vend 
									= l_arr_rec_disp_vend[l_cnt2].vend_code 
									EXIT FOR 
								END IF 
							ELSE 
								EXIT FOR 
							END IF 
						END FOR 
						LET l_cnt_chq = l_cnt_chq + (l_arr_range[l_cnt1].end_num 
						- l_arr_range[l_cnt1].start_num) 
						IF l_cnt_chq IS NULL THEN 
							LET l_cnt_chq = 0 
						END IF 
						FOR l_cnt2 = 1 TO 3000 
							IF (l_arr_rec_disp_vend[l_cnt2].page_num != 0) THEN 
								IF (l_arr_rec_disp_vend[l_cnt2].page_num >= l_cnt_chq) 
								THEN 
									LET l_rec_range.end_vend 
									= l_arr_rec_disp_vend[l_cnt2].vend_code 
									LET l_arr_range[l_cnt1].end_vend 
									= l_arr_rec_disp_vend[l_cnt2].vend_code 
									EXIT FOR 
								END IF 
							ELSE 
								EXIT FOR 
							END IF 
						END FOR 
					ELSE 
						EXIT FOR 
					END IF 
				END FOR 
				LET l_pr_scrn = 1 
				FOR i = (curr-scrn)+1 TO curr+(9-scrn) 
					DISPLAY l_arr_range[i].* TO sr_range[l_pr_scrn].* 

					LET l_pr_scrn = l_pr_scrn + 1 
				END FOR 
			ELSE 
				NEXT FIELD scroll_flag 
			END IF 

		BEFORE INSERT 
			INITIALIZE l_rec_range.* TO NULL 
			INITIALIZE l_arr_range[curr].* TO NULL 
			LET l_rec_range.* = l_arr_range[curr].* 
			NEXT FIELD line_num 

		AFTER ROW 
			IF NOT (int_flag OR quit_flag) THEN 
				DISPLAY l_arr_range[curr].* TO sr_range[scrn].* 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT infield(scroll_flag) THEN 
					LET int_flag = FALSE 
					LET quit_flag = FALSE 
					IF l_rec_range.start_num IS NULL THEN 
						### Insert ###
						LET j = scrn 
						LET l_arr_count = arr_count() 
						IF arr_curr() > arr_count() THEN 
							LET l_arr_count = arr_count() + 1 
						END IF 
						FOR idx = arr_curr() TO l_arr_count 
							IF l_arr_range[idx+1].start_num IS NOT NULL THEN 
								LET l_arr_range[idx].* = l_arr_range[idx+1].* 
							ELSE 
								INITIALIZE l_arr_range[idx].* TO NULL 
							END IF 
							IF j <= 9 THEN 
								DISPLAY l_arr_range[idx].* TO sr_range[j].* 

								LET j = j + 1 
							END IF 
						END FOR 
						IF arr_curr() = l_arr_count THEN 
							INITIALIZE l_arr_range[idx].* TO NULL 
							INITIALIZE l_rec_range.* TO NULL 
						END IF 
						NEXT FIELD scroll_flag 
					ELSE 
						### Update ###
						LET l_arr_range[curr].start_num = l_rec_range.start_num 
						LET l_arr_range[curr].end_num = l_rec_range.end_num 
						LET l_arr_range[curr].chq_cnt = l_rec_range.chq_cnt 
						LET l_arr_range[curr].start_vend = l_rec_range.start_vend 
						LET l_arr_range[curr].end_vend = l_rec_range.end_vend 
					END IF 
					NEXT FIELD chq_cnt 
				ELSE 
					# I have commented out the password entry to Exit. (albo)
					# I don't understand why you need to enter the same "doitagain" password each time to Exit.
					#IF back_out() THEN 
					#	LET quit_flag = TRUE 
					#	EXIT INPUT 
					#ELSE 
					#	LET int_flag = FALSE 
					#	LET quit_flag = FALSE 
					#	NEXT FIELD scroll_flag 
					#END IF 
					LET quit_flag = TRUE 
					EXIT INPUT 
				END IF 
			ELSE 
				IF l_arr_range[curr].start_num IS NOT NULL OR 
				l_arr_range[curr].end_num IS NOT NULL THEN 
					IF (l_arr_range[curr].start_num IS NULL) OR 
					(l_arr_range[curr].start_num <= 0) THEN 
						LET l_msgresp=kandoomsg("P",9062,"") 
						#9062 Must enter start no.
						NEXT FIELD start_num 
					END IF 
					IF (l_arr_range[curr].end_num IS NULL) OR 
					(l_arr_range[curr].end_num <= 0) THEN 
						LET l_msgresp=kandoomsg("P",9064,"") 
						#9064 Must enter END no.
						NEXT FIELD end_num 
					END IF 
				END IF 
				### reset total cheque count - gets out of sequence ###
				### IF lines deleted (temporary fix FOR speed)      ###
				LET l_chq_cnt = 0 
				FOR i = 1 TO arr_count() 
					IF l_arr_range[i].start_num IS NOT NULL THEN 
						LET l_chq_cnt = l_chq_cnt + 
						l_arr_range[i].end_num - l_arr_range[i].start_num + 1 
					ELSE 
						EXIT FOR 
					END IF 
				END FOR 
				DISPLAY l_chq_cnt TO chq_cnt 
				### Test no. of cheques numbered IS the same as no. of cheque ###
				### pages used                                                ###
				IF l_print_cnt != l_chq_cnt THEN 
					LET l_msgresp=kandoomsg("P",9066,"") 
					#9066 No. of cheques numbered does NOT match those printed
					NEXT FIELD scroll_flag 
				END IF 
				SELECT UNIQUE 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code between l_arr_range[curr].start_num AND 
				l_arr_range[curr].end_num 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "1" 
				IF STATUS != NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9010,"in this range") 
					#9010 Cheque Number n already issued
					NEXT FIELD scroll_flag 
				END IF 

				# Cheque numbers allocated by adding page number as offset TO
				# starting cheque number.  IF break in range detected, reset
				# start number TO be start of next range AND subtract previously
				# printed pages FROM the current offset TO get offset FROM that
				# start number
				LET i = 1 
				LET l_prev_pages = 0 
				LET l_save_pages = 0 
				LET l_start_cheq_num = l_arr_range[1].start_num 
				LET l_cheque_num = NULL 
				DECLARE c_tdocid CURSOR FOR 
				SELECT doc_id, 
				page_no, 
				vouch_code 
				FROM t_docid 
				ORDER BY 1 
				FOREACH c_tdocid INTO l_docid, l_page_no, l_vouch_code 

					# Get valid number in range
					WHILE TRUE 
						LET l_cheque_num = l_start_cheq_num + 
						(l_page_no - l_prev_pages) - 1 
						IF l_cheque_num < 0 THEN 
							LET l_cheque_num = NULL 
							EXIT WHILE 
						END IF 
						IF l_cheque_num > l_arr_range[i].end_num THEN 
							LET i = i + 1 

							IF i > arr_count() THEN # don't GO past ranges entered 
								LET l_cheque_num = NULL 
								EXIT WHILE 
							ELSE 
								LET l_prev_pages = l_save_pages 
								LET l_start_cheq_num = l_arr_range[i].start_num 
							END IF 
						ELSE 
							EXIT WHILE 
						END IF 
					END WHILE 
					#  Check FOR error in range AND reset allocations
					IF l_cheque_num IS NULL THEN 
						UPDATE tentpays 
						SET cheq_code = '' 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cycle_num = glob_cycle_num 
						AND status_ind = 1 
						LET l_msgresp=kandoomsg("P",9066,"") 
						#9066 No. of cheques numbered does NOT match those printed
						EXIT FOREACH 
					ELSE 
						# Check that number NOT already issued
						SELECT UNIQUE 1 FROM cheque 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cheq_code = l_cheque_num 
						AND bank_acct_code = glob_rec_bank.acct_code 
						AND pay_meth_ind = glob_pay_meth_ind 
						IF SQLCA.SQLCODE = 0 THEN 
							#
							# Reset cheque codes
							#
							UPDATE tentpays 
							SET cheq_code = '' 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cycle_num = glob_cycle_num 
							AND status_ind = 1 
							LET l_msgresp=kandoomsg("P",9010,l_cheque_num) 
							#9010 Cheque Number <VALUE> already issued
							LET l_cheque_num = NULL 
							EXIT FOREACH 
						ELSE 
							LET array_idx = array_idx + 1 
							LET glob_arr_cheque_code[array_idx] = l_cheque_num 
							IF l_vouch_code IS NOT NULL THEN 
								UPDATE tentpays 
								SET cheq_code = l_cheque_num 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cycle_num = glob_cycle_num 
								AND pay_doc_num = l_docid 
								AND vouch_code = l_vouch_code 
							ELSE 
								UPDATE tentpays 
								SET cheq_code = l_cheque_num 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cycle_num = glob_cycle_num 
								AND pay_doc_num = l_docid 
							END IF 
						END IF 
					END IF 
					LET l_save_pages = l_page_no 
				END FOREACH 
				IF l_cheque_num IS NULL THEN 
					NEXT FIELD scroll_flag 
				END IF 

			END IF 

	END INPUT 
	CLOSE WINDOW p239 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		CALL upd_chqs2() 
	END IF 

END FUNCTION 
############################################################
# FUNCTION setup_range()
############################################################


############################################################
# FUNCTION print_cheques()
#
#
############################################################
FUNCTION print_cheques() 
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_arr_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT
	DEFINE l_output STRING #report output file name inc. path

	#------------------------------------------------------------
	#CALL rpt_rmsreps_reset(NULL)

	LET l_rpt_idx = rpt_start(getmoduleid(),"P34A_rpt_list","N/A",RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT P34A_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	BEGIN WORK 
		DELETE FROM t_docid 
		IF glob_print_all_ind THEN 
			DECLARE c2_tentpays CURSOR FOR 
			SELECT * FROM tentpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			AND pay_meth_ind = '1' 
			ORDER BY vend_code, 
			withhold_tax_ind, 
			vouch_code 
			FOREACH c2_tentpays INTO glob_rec_tentpays.* 
				#
				# Create doc_id / page offset relationship
				#
				SELECT UNIQUE 1 FROM t_docid 
				WHERE doc_id = glob_rec_tentpays.pay_doc_num 
				IF SQLCA.SQLCODE = NOTFOUND THEN 
					INSERT INTO t_docid VALUES (glob_rec_tentpays.pay_doc_num,'',NULL) 
				END IF 
				#---------------------------------------------------------
				OUTPUT TO REPORT P34A_rpt_list(l_rpt_idx,
				glob_rec_tentpays.*, 
				glob_chq_prt_date, 
				glob_rec_tentpays.source_ind, 
				glob_rec_tentpays.source_text, 
				glob_rec_tentpays.pay_doc_num) 
				IF NOT rpt_int_flag_handler2("Cheque: ",glob_rec_tentpays.cheq_code,"",l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------
			END FOREACH 
		ELSE 
			LET l_arr_cnt = arr_curr() 
			FOR idx = 1 TO l_arr_cnt 
				SELECT * INTO glob_rec_tentpays.* FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND vend_code = glob_arr_rec_tentpays[idx].vend_code 
				AND vouch_code = glob_arr_rec_tentpays[idx].vouch_code 
				AND pay_meth_ind = "1" 
				#
				# Create doc_id / page offset relationship
				#
				SELECT UNIQUE 1 FROM t_docid 
				WHERE doc_id = glob_arr_doc_nums[idx] 
				IF SQLCA.SQLCODE = NOTFOUND THEN 
					INSERT INTO t_docid VALUES (glob_arr_doc_nums[idx],'',NULL) 
				END IF 
				#---------------------------------------------------------
				OUTPUT TO REPORT P34A_rpt_list(l_rpt_idx,
				glob_rec_tentpays.*, 
				glob_chq_prt_date, 
				glob_rec_tentpays.source_ind, 
				glob_rec_tentpays.source_text, 
				glob_arr_doc_nums[idx]) 
				IF NOT rpt_int_flag_handler2("Cheque: ",glob_rec_tentpays.cheq_code,"",l_rpt_idx) THEN
					EXIT FOR 
				END IF 
				#---------------------------------------------------------
			END FOR 
		END IF
	COMMIT WORK 
	--WHENEVER ERROR stop 
	#------------------------------------------------------------
	FINISH REPORT P34A_rpt_list
	RETURN rpt_finish("P34A_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# FUNCTION print_cheques()
############################################################


############################################################
# FUNCTION process_efts()
#
#
############################################################
FUNCTION process_efts() 
	DEFINE l_rpt_idx_1 SMALLINT
	DEFINE l_rpt_idx_2 SMALLINT
	DEFINE l_rpt_idx_3 SMALLINT
	DEFINE l_rpt_idx_4 SMALLINT
	DEFINE l_rpt_idx_5 SMALLINT
	DEFINE l_vend_code LIKE vendor.vend_code 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_save_vend LIKE vendor.vend_code 
	DEFINE l_save_tax_ind LIKE tentpays.withhold_tax_ind 
	DEFINE l_save_cheq LIKE tentpays.vouch_amt 
	DEFINE l_eft_amount LIKE tentpays.vouch_amt 
	DEFINE l_rpt_note,l_rpt_note2,l_rpt_note3 CHAR(80) 
	DEFINE l_bic_code CHAR(6)
	DEFINE l_mods_flag CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_err_message CHAR(40) 
	DEFINE try_again CHAR(1)
	DEFINE i, x, y, j, idx SMALLINT
	DEFINE l_output STRING #report output file name inc. path

	LET l_msgresp=kandoomsg("P",1005,"") 
	#1005 Updating database - please wait
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(l_err_message, STATUS) 
	IF try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 
	LET l_rpt_note = "EFT Payments Report" 
	LET l_rpt_note2 = "EFT Bank Listing - (BANK USE ONLY)" 
	LET l_rpt_note3 = "Remittances Advices" 

	BEGIN WORK 
		#  lock the bank table FOR the entire process - We need TO create two
		#  reports with allocated cheque reference numbers as well as writing
		#  AND applying the cheques.
		#
		LOCK TABLE bank in share MODE 
		LET l_err_message = "EFT reference number validation" 
		SELECT UNIQUE 1 FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cheq_code = glob_rec_bank.next_eft_ref_num 
		AND bank_acct_code = glob_rec_bank.acct_code 
		AND pay_meth_ind = glob_pay_meth_ind 
		IF STATUS != NOTFOUND THEN 
			LET l_msgresp=kandoomsg("P",9052,glob_rec_bank.next_eft_ref_num) 
			#9052 EFT Reference Number n already issued
			GOTO recovery 
		END IF 
		LET idx = 1 
		LET l_save_vend = glob_arr_rec_tentpays[idx].vend_code 
		LET l_save_tax_ind = glob_arr_rec_tentpays[idx].withhold_tax_ind 
		LET l_save_cheq = glob_rec_bank.next_eft_ref_num 
		WHILE idx <= glob_arr_size 
			IF glob_arr_rec_tentpays[idx].vouch_code IS NOT NULL 
			AND glob_arr_rec_tentpays[idx].vouch_code != 0 THEN 
				IF glob_arr_rec_tentpays[idx].vend_code = l_save_vend 
				AND glob_arr_rec_tentpays[idx].withhold_tax_ind = l_save_tax_ind THEN 
					LET glob_arr_rec_tentpays[idx].cheq_code = l_save_cheq 
				ELSE 
					LET glob_arr_rec_tentpays[idx].cheq_code = l_save_cheq + 1 
					SELECT UNIQUE 1 FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cheq_code = glob_arr_rec_tentpays[idx].cheq_code 
					AND bank_acct_code = glob_rec_bank.acct_code 
					AND pay_meth_ind = glob_pay_meth_ind 
					IF STATUS != NOTFOUND THEN 
						LET l_msgresp=kandoomsg("P",9052,glob_arr_rec_tentpays[idx].cheq_code) 
						#9052 EFT Reference Number n already issued
						GOTO recovery 
					END IF 
				END IF 
				LET l_save_vend = glob_arr_rec_tentpays[idx].vend_code 
				LET l_save_tax_ind = glob_arr_rec_tentpays[idx].withhold_tax_ind 
				LET l_save_cheq = glob_arr_rec_tentpays[idx].cheq_code 
			END IF 
			LET idx = idx + 1 
		END WHILE 
		LET l_err_message = "EFT reference number verification" 
		FOR i = 1 TO glob_arr_size 
			IF glob_arr_rec_tentpays[i].cheq_code IS NULL THEN 
				ERROR " Voucher on Line ",i," has no EFT number" 
				GOTO recovery 
			END IF 
			IF glob_arr_rec_tentpays[i].cheq_code = glob_arr_rec_tentpays[i+1].cheq_code AND 
			glob_arr_rec_tentpays[i].vend_code != glob_arr_rec_tentpays[i+1].vend_code 
			THEN 
				ERROR " EFT Number ", glob_arr_rec_tentpays[i].cheq_code, 
				" must be Unique TO a Vendor " 
				GOTO recovery 
			END IF 
			IF glob_arr_rec_tentpays[i].cheq_code = glob_arr_rec_tentpays[i+1].cheq_code 
			AND glob_arr_rec_tentpays[i].withhold_tax_ind != 
			glob_arr_rec_tentpays[i+1].withhold_tax_ind THEN 
				ERROR " EFT Number ", glob_arr_rec_tentpays[i].cheq_code, 
				" must be Unique TO FOR each W/hold tax indicator" 
				GOTO recovery 
			END IF 
			IF glob_arr_rec_tentpays[i].cheq_code != glob_arr_rec_tentpays[i+1].cheq_code 
			AND (glob_arr_rec_tentpays[i].vend_code = glob_arr_rec_tentpays[i+1].vend_code AND 
			glob_arr_rec_tentpays[i].withhold_tax_ind = 
			glob_arr_rec_tentpays[i+1].withhold_tax_ind) THEN 
				ERROR " EFT Number ", glob_arr_rec_tentpays[i+1].cheq_code, 
				" must be Unique TO a Vendor " 
				GOTO recovery 
			END IF 
			FOR j = 1 TO (i-1) 
				IF glob_arr_rec_tentpays[i].cheq_code = glob_arr_rec_tentpays[j].cheq_code AND 
				glob_arr_rec_tentpays[i].vend_code != glob_arr_rec_tentpays[j].vend_code 
				THEN 
					ERROR " EFT Number ", glob_arr_rec_tentpays[i].cheq_code, 
					" must be Unique TO a Vendor " 
					GOTO recovery 
				END IF 
				IF glob_arr_rec_tentpays[i].cheq_code = glob_arr_rec_tentpays[j].cheq_code AND 
				glob_arr_rec_tentpays[i].withhold_tax_ind 
				!= glob_arr_rec_tentpays[j].withhold_tax_ind 
				THEN 
					ERROR " EFT Number ", glob_arr_rec_tentpays[i].cheq_code, 
					" must be Unique TO FOR each W/hold tax indicator" 
					GOTO recovery 
				END IF 
			END FOR 
		END FOR

		#------------------------------------------------------------
		#CALL rpt_rmsreps_reset(NULL)

		LET l_rpt_idx_1 = rpt_start(getmoduleid(),"pc9a_list","N/A",RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx_1 = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF

		START REPORT pc9a_list TO rpt_get_report_file_with_path2(l_rpt_idx_1)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].report_width_num
		#------------------------------------------------------------

		#------------------------------------------------------------
		LET l_rpt_idx_2 = rpt_start(getmoduleid(),"pc9z_list","N/A",RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx_2 = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF

		START REPORT pc9z_list TO rpt_get_report_file_with_path2(l_rpt_idx_2)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].report_width_num
		#------------------------------------------------------------

		#------------------------------------------------------------
		LET l_rpt_idx_3 = rpt_start(getmoduleid(),"pcf_list","N/A",RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx_3 = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF

		START REPORT pcf_list TO rpt_get_report_file_with_path2(l_rpt_idx_3)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].report_width_num
		#------------------------------------------------------------
 
		IF glob_rec_banktype.eft_format_ind = 5 THEN 
			#------------------------------------------------------------
			LET l_rpt_idx_4 = rpt_start(getmoduleid(),"pc9f1_list","N/A",RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx_4 = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF

			START REPORT pc9f1_list TO rpt_get_report_file_with_path2(l_rpt_idx_4)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_4].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_4].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_4].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_4].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_4].report_width_num
			#------------------------------------------------------------
		END IF 
		
		IF glob_rec_banktype.eft_format_ind = 1 THEN 
			#------------------------------------------------------------
			LET l_rpt_idx_5 = rpt_start(getmoduleid(),"pc9f2_list","N/A",RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx_5 = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF

			START REPORT pc9f2_list TO rpt_get_report_file_with_path2(l_rpt_idx_5)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_5].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_5].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_5].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_5].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_5].report_width_num
			#------------------------------------------------------------
		END IF
		#
		######## Reserved FOR future use ########
		#IF glob_rec_banktype.eft_format_ind = 2 THEN
		#   START REPORT PC9f2_list TO glob_path_name    #Bank file FOR EFT's
		#END IF
		#
		LET l_rpt_note = l_rpt_note CLIPPED, " (Menu-PC9)" 
		LET l_rpt_note2 = "Cleansing Report (Menu-PCL)" 
		LET l_rpt_note3 = l_rpt_note3 CLIPPED, " (Menu-PC6)" 
		LET l_eft_amount = 0 
		LET x = 1 
		FOR i = 1 TO glob_arr_size 
			LET l_eft_amount = l_eft_amount + glob_arr_rec_tentpays[i].vouch_amt 
			IF glob_arr_rec_tentpays[i].cheq_code != glob_arr_rec_tentpays[i+1].cheq_code 
			OR i = glob_arr_size THEN 
				LET l_vend_code = glob_arr_rec_tentpays[i].vend_code 
				MESSAGE " Writing Cheque ",glob_arr_rec_tentpays[i].cheq_code 
				SELECT * INTO l_rec_vendor.* FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = glob_arr_rec_tentpays[i].vend_code 
				ORDER BY vendor.name_text 
				IF STATUS = NOTFOUND THEN 
					ERROR " Logic error: Vendor FOR Cheque", glob_arr_rec_tentpays[i].cheq_code, 
					" does NOT exist" 
					LET l_err_message = "Vendor NOT found ", glob_arr_rec_tentpays[i].vend_code 
					GOTO recovery 
				END IF 
				SELECT * INTO glob_rec_tentpays.* 
				FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND vend_code = glob_arr_rec_tentpays[i].vend_code 
				AND vouch_code = glob_arr_rec_tentpays[i].vouch_code 
				IF STATUS = NOTFOUND THEN 
					LET l_err_message = "Tentpays RECORD Not Found" 
					GOTO recovery 
				END IF 
				LET l_bic_code = l_rec_vendor.bank_acct_code[1,6] 
				LET l_mods_flag = l_rec_vendor.bkdetls_mod_flag 
				IF NOT write_cheq(glob_arr_rec_tentpays[i].cheq_code, 
				glob_arr_rec_tentpays[i].vend_code, 
				l_eft_amount, 
				0, 
				glob_rec_bank.bank_code, 
				glob_rec_bank.next_eft_run_num, 
				glob_pay_meth_ind, 
				glob_arr_rec_tentpays[i].withhold_tax_ind, 
				glob_rec_tentpays.tax_code, 
				glob_rec_tentpays.tax_per, 
				glob_rec_tentpays.source_ind, 
				glob_rec_tentpays.source_text) THEN 
					GOTO recovery 
				END IF 
				SELECT * INTO l_rec_cheque.* FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code = glob_arr_rec_tentpays[i].cheq_code 
				AND bank_acct_code = glob_rec_bank.acct_code 
				AND pay_meth_ind = glob_pay_meth_ind 
				IF STATUS = NOTFOUND THEN 
					ERROR " Logic error: Cheque ", glob_arr_rec_tentpays[i].cheq_code, 
					" has NOT been inserted " 
					LET l_err_message = "Validate cheque Insert " 
					GOTO recovery 
				END IF 
				#---------------------------------------------------------
				OUTPUT TO REPORT pc9a_list(l_rpt_idx_1,l_rec_cheque.*,l_rec_vendor.*,l_rpt_note) 
				#---------------------------------------------------------
				IF glob_rec_bank.eft_rpt_ind != 0 #ie. 1 OR 2 
				AND l_mods_flag = "Y" THEN #and new/modified 
					#
					# STAGE II
					# Modify it TO CALL PCLa_list etc etc
					# with PCL being the front END with an UPDATE clause
					#
					#---------------------------------------------------------
					OUTPUT TO REPORT pc9z_list(l_rpt_idx_2,l_bic_code, l_rec_cheque.*,l_rpt_note2) 
					#---------------------------------------------------------
				END IF 
				IF glob_rec_banktype.eft_format_ind = 5 THEN 
					#---------------------------------------------------------
					OUTPUT TO REPORT pc9f1_list(l_rpt_idx_4,l_rec_cheque.*,l_mods_flag) 
					#---------------------------------------------------------
				END IF 
				IF glob_rec_banktype.eft_format_ind = 1 THEN 
					#---------------------------------------------------------
					OUTPUT TO REPORT pc9f2_list(l_rpt_idx_5,l_rec_cheque.*) 
					#---------------------------------------------------------
				END IF 
				######## Reserved FOR future use ########
				#IF glob_rec_banktype.eft_format_ind = 2 THEN
				#  OUTPUT TO REPORT PC9f2_list(l_rec_cheque.*)
				#END IF
				FOR y = x TO i 
					IF NOT apply_cheq(glob_arr_rec_tentpays[y].cheq_code, 
					glob_rec_bank.acct_code, 
					glob_arr_rec_tentpays[y].vouch_code, 
					glob_arr_rec_tentpays[y].vouch_amt, 
					glob_pay_meth_ind, 
					glob_arr_rec_tentpays[y].taken_disc_amt) THEN 
						GOTO recovery 
					END IF 
					LET l_err_message = "P34 - EFT Tentpays delete" 
					DELETE FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					AND vend_code = glob_arr_rec_tentpays[y].vend_code 
					AND vouch_code = glob_arr_rec_tentpays[y].vouch_code 
				END FOR 
				#---------------------------------------------------------
				OUTPUT TO REPORT pcf_list(l_rpt_idx_3,l_rec_cheque.*) 
				#---------------------------------------------------------
				LET l_eft_amount = 0 
				LET x = y 
				#
				# Check IF any unapplied debits exist FOR this vendor
				#
				LET l_err_message = "P34 - EFT unapplied debits" 
				SELECT UNIQUE 1 FROM debithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_vend_code 
				AND apply_amt != total_amt 
				IF STATUS != NOTFOUND THEN 
					MESSAGE " Applying Debits " 
					IF NOT apply_deb(l_vend_code) THEN 
						GOTO recovery 
					END IF 
				END IF 
			END IF 
		END FOR 
		LET l_err_message = "P34 - Bank Update" 
		IF glob_rec_bank.eft_rpt_ind != 2 THEN 
			LET glob_rec_bank.eft_rpt_ind = 0 
		END IF 
		UPDATE bank 
		SET next_eft_run_num = glob_rec_bank.next_eft_run_num + 1, 
		next_eft_ref_num = l_save_cheq + 1, 
		eft_rpt_ind = glob_rec_bank.eft_rpt_ind 
		WHERE bank_code = glob_rec_bank.bank_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code

	COMMIT WORK

	#------------------------------------------------------------
	FINISH REPORT pc9a_list
	CALL rpt_finish("pc9a_list")	
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT pc9z_list
	CALL rpt_finish("pc9z_list")	
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT pcf_list
	CALL rpt_finish("pcf_list")	
	#------------------------------------------------------------

	IF glob_rec_banktype.eft_format_ind = 5 THEN 
		#------------------------------------------------------------
		FINISH REPORT pc9f1_list
		CALL rpt_finish("pc9f1_list")	
		#------------------------------------------------------------
	END IF 

	IF glob_rec_banktype.eft_format_ind = 1 THEN 
		#------------------------------------------------------------
		FINISH REPORT pc9f2_list
		CALL rpt_finish("pc9f2_list")	
		#------------------------------------------------------------
	END IF 

	######## Reserved FOR future use ########
	#IF glob_rec_banktype.eft_format_ind = 2 THEN
	#   FINISH REPORT PC9f2_list
	#END IF
 
END FUNCTION 
############################################################
# FUNCTION process_efts()
############################################################


############################################################
# FUNCTION upd_chqs()
#
#
############################################################
FUNCTION upd_chqs() 
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_vendor_text LIKE vendor.name_text
	DEFINE l_vend_code LIKE vendor.vend_code 
	DEFINE l_chq_amt LIKE tentpays.vouch_amt 
	DEFINE l_cheq_amount LIKE tentpays.vouch_amt 
	DEFINE l_start_num SMALLINT 
 	DEFINE l_err_cnt INTEGER 
	DEFINE l_chq_cnt INTEGER 
	DEFINE l_error_text CHAR(50) 
	DEFINE l_strmsg STRING 
	DEFINE l_err_message CHAR(40) 
	DEFINE i,x,y SMALLINT
	DEFINE l_output STRING #report output file name inc. path

	LET l_err_cnt = 0 
	LET l_chq_cnt = 0 
	LET l_cheq_amount = 0 
	LET x = 1 

	#------------------------------------------------------------
	#CALL rpt_rmsreps_reset(NULL)

	LET l_rpt_idx = rpt_start(getmoduleid(),"error_report","N/A",RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT error_report TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	FOR i = 1 TO glob_arr_size 
		LET l_cheq_amount = l_cheq_amount + glob_arr_rec_tentpays[i].vouch_amt 
		#
		# Check FOR break of cheque code
		#
		IF glob_arr_rec_tentpays[i].cheq_code != glob_arr_rec_tentpays[i+1].cheq_code 
		OR i = glob_arr_size THEN 
			#
			# Mark starting position of current cheque
			#
			LET l_start_num = x 
			LET l_chq_amt = l_cheq_amount 
			GOTO bypass 
			LABEL recovery: 
			IF STATUS = 0 THEN 

				# Non-DB related error (eg. cheque already issued, etc.)
				# Outputing all the cheque code, cheque amount, vendor code,
				# AND vendor description TO error REPORT IF a cheque IS skipped.
				#
				# Continue TO write remaining cheques
				#
				SELECT name_text INTO l_vendor_text FROM vendor 
				WHERE vend_code = glob_arr_rec_tentpays[i].vend_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_error_text = "Vendor Balance Error" 
				#---------------------------------------------------------
				OUTPUT TO REPORT error_report(l_rpt_idx,
				glob_arr_rec_tentpays[i].cheq_code, 
				l_chq_amt, 
				glob_arr_rec_tentpays[i].vend_code, 
				l_vendor_text, 
				l_error_text) 
				#---------------------------------------------------------
				LET l_err_cnt = l_err_cnt + 1 
				LET l_cheq_amount = 0 
				LET x = i + 1 
				ROLLBACK WORK 
				CONTINUE FOR 
			ELSE 
				IF error_recover(l_err_message, STATUS) != 'Y' THEN 

					# DataBase related error (eg. cheque already issued, etc.)
					# Outputing all the cheque code, cheque amount, vendor code,
					# AND vendor description TO error REPORT IF a cheque IS
					# skipped.
					# Continue TO write remaining cheques
					#
					SELECT name_text INTO l_vendor_text FROM vendor 
					WHERE vend_code = glob_arr_rec_tentpays[i].vend_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_error_text = "Database Lock Error" 
					#---------------------------------------------------------
					OUTPUT TO REPORT error_report(l_rpt_idx,
					glob_arr_rec_tentpays[i].cheq_code, 
					l_chq_amt, 
					glob_arr_rec_tentpays[i].vend_code, 
					l_vendor_text, 
					l_error_text) 
					#---------------------------------------------------------
					LET l_err_cnt = l_err_cnt + 1 
					LET l_cheq_amount = 0 
					LET x = i + 1 
					CONTINUE FOR 
				ELSE 
					#
					# Reset VALUES
					#
					LET x = l_start_num 
					LET l_cheq_amount = l_chq_amt 
				END IF 
			END IF 
			LABEL bypass: 
			--WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				LET l_vend_code = glob_arr_rec_tentpays[i].vend_code 
				SELECT * INTO glob_rec_tentpays.* 
				FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND vend_code = glob_arr_rec_tentpays[i].vend_code 
				AND vouch_code = glob_arr_rec_tentpays[i].vouch_code 
				IF STATUS = NOTFOUND THEN 
					LET l_error_text = "Tentpays RECORD Not Found" 
					GOTO recovery 
				END IF 
				MESSAGE " Writing Cheque ",glob_arr_rec_tentpays[i].cheq_code 
				IF NOT write_cheq(glob_arr_rec_tentpays[i].cheq_code, 
				glob_arr_rec_tentpays[i].vend_code, 
				l_cheq_amount, 
				0, 
				glob_rec_bank.bank_code, 
				glob_rec_bank.next_cheq_run_num, 
				glob_pay_meth_ind, 
				glob_rec_tentpays.withhold_tax_ind, 
				glob_rec_tentpays.tax_code, 
				glob_rec_tentpays.tax_per, 
				glob_rec_tentpays.source_ind, 
				glob_rec_tentpays.source_text) THEN 
					GOTO recovery 
				END IF 
				FOR y = x TO i 
					IF NOT apply_cheq(glob_arr_rec_tentpays[y].cheq_code, 
					glob_rec_bank.acct_code, 
					glob_arr_rec_tentpays[y].vouch_code, 
					glob_arr_rec_tentpays[y].vouch_amt, 
					glob_pay_meth_ind, 
					glob_arr_rec_tentpays[y].taken_disc_amt) THEN 
						GOTO recovery 
					END IF 
					LET l_err_message = "P34 - Tentpays delete" 
					DELETE FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					AND vend_code = glob_arr_rec_tentpays[y].vend_code 
					AND vouch_code = glob_arr_rec_tentpays[y].vouch_code 
				END FOR 
				LET l_cheq_amount = 0 
				LET x = y 
				#
				# Check IF any unapplied debits exist FOR this vendor
				#
				LET l_err_message = "P34 - Unapplied debits" 
				SELECT UNIQUE 1 FROM debithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_vend_code 
				AND apply_amt != total_amt 
				IF STATUS != NOTFOUND THEN 
					MESSAGE " Applying Debits " 
					IF NOT apply_deb(l_vend_code) THEN 
						GOTO recovery 
					END IF 
				END IF 
				LET l_error_text = "Bank Update Failed - P34" 
				UPDATE bank 
				SET next_cheq_run_num = glob_rec_bank.next_cheq_run_num + 1 
				WHERE bank_code = glob_rec_bank.bank_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			COMMIT WORK 
			LET l_chq_cnt = l_chq_cnt + 1 
		END IF 
	END FOR 

	#------------------------------------------------------------
	FINISH REPORT error_report
	CALL rpt_finish("error_report")
	#------------------------------------------------------------

	#
	# Summary window of successful vs. rejected cheques
	#

	#huho
	LET l_strmsg = "Cheques successfully generated : ", l_chq_cnt USING "#######&", "\n" 
	LET l_strmsg = l_strmsg, "Cheques in error : ", l_err_cnt USING "#######&", "\n" 
	LET l_strmsg = l_strmsg, "Refer TO RMS System IF Cheques in error" 

	CALL fgl_winmessage("Cheques generation", l_strmsg, "info") 

END FUNCTION 
############################################################
# FUNCTION upd_chqs()
############################################################


############################################################
# FUNCTION write_cheq()
#
# NOTE: This FUNCTION was cloned FROM P41e.4gl(auto_cheq) with
#       transaction processing replaced.
############################################################
FUNCTION write_cheq(p_cheq_num,p_vend,p_cheq_amt,p_dis_amt,p_bank,p_eft_run_num,p_pay_meth_ind,p_wtax_ind,p_wtax_code,p_wtax_per,p_source_ind,p_source_text) 
	DEFINE p_cheq_num LIKE cheque.cheq_code 
	DEFINE p_vend LIKE vendor.vend_code 
	DEFINE p_cheq_amt LIKE cheque.pay_amt 
	DEFINE p_dis_amt LIKE cheque.disc_amt 
	DEFINE p_bank LIKE bank.bank_code 
	DEFINE p_eft_run_num LIKE cheque.eft_run_num 
	DEFINE p_pay_meth_ind LIKE cheque.pay_meth_ind 
	DEFINE p_wtax_ind LIKE vendortype.withhold_tax_ind 
	DEFINE p_wtax_code LIKE tax.tax_code 
	DEFINE p_wtax_per LIKE tax.tax_per 
	DEFINE p_source_ind LIKE cheque.source_ind 
	DEFINE p_source_text LIKE cheque.source_text 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_vend_tax_code LIKE tax.tax_code 
	DEFINE l_vend_tax_per LIKE tax.tax_per 
	DEFINE l_err_message STRING 

	INITIALIZE glob_rec_cheque.* TO NULL 
	LET glob_rec_cheque.cheq_date = glob_chq_prt_date 
	LET glob_rec_cheque.entry_code = glob_rec_kandoouser.sign_on_code 
	LET glob_rec_cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_cheque.apply_amt = 0 
	LET glob_rec_cheque.next_appl_num = 0 
	LET glob_rec_cheque.pay_amt = p_cheq_amt 
	LET glob_rec_cheque.disc_amt = p_dis_amt 
	LET glob_rec_cheque.withhold_tax_ind = p_wtax_ind 
	LET glob_rec_cheque.tax_code = p_wtax_code 
	LET glob_rec_cheque.tax_per = p_wtax_per 
	LET glob_rec_cheque.pay_meth_ind = p_pay_meth_ind 
	LET glob_rec_cheque.eft_run_num = p_eft_run_num 
	LET glob_rec_cheque.source_ind = p_source_ind 
	IF glob_rec_cheque.source_ind = '1' THEN 
		LET glob_rec_cheque.source_text = p_vend 
	ELSE 
		LET glob_rec_cheque.source_text = p_source_text 
	END IF 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE vend_code = p_vend 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_cheque.pay_amt = p_cheq_amt 
	LET glob_rec_cheque.vend_code = p_vend 
	CALL wtaxcalc(glob_rec_cheque.pay_amt, 
	glob_rec_cheque.tax_per, 
	glob_rec_cheque.withhold_tax_ind, 
	glob_rec_kandoouser.cmpy_code) 
	RETURNING glob_rec_cheque.net_pay_amt, 
	glob_rec_cheque.tax_amt 
	LET glob_rec_cheque.bank_acct_code = glob_rec_bank.acct_code 
	LET glob_rec_cheque.bank_code = p_bank 
	LET glob_rec_cheque.bank_currency_code = glob_rec_bank.currency_code 
	LET glob_rec_cheque.currency_code = glob_rec_bank.currency_code 
	IF glob_rec_cheque.currency_code != glob_rec_glparms.base_currency_code THEN 
		CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, 
		glob_rec_cheque.currency_code, 
		glob_rec_cheque.cheq_date, 
		"B") 
		RETURNING glob_rec_cheque.conv_qty 
	ELSE 
		LET glob_rec_cheque.conv_qty = '1' 
	END IF 
	LET glob_rec_cheque.cheq_code = p_cheq_num 
	LET glob_rec_cheque.entry_date = TODAY 
	LET glob_rec_cheque.com1_text = "Generated Payments On ", TODAY USING "dd/mm/yy" 
	LET glob_rec_cheque.com2_text = NULL 
	IF glob_rec_cheque.pay_meth_ind = "3" THEN 
		LET glob_rec_cheque.com2_text = "EFT Run Number ", p_eft_run_num 
	END IF 
	SELECT * INTO l_rec_cheque.* FROM cheque 
	WHERE cheq_code = glob_rec_cheque.cheq_code 
	AND bank_acct_code = glob_rec_cheque.bank_acct_code 
	AND pay_meth_ind = glob_rec_cheque.pay_meth_ind 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF STATUS = NOTFOUND THEN 
	ELSE 
		IF glob_rec_cheque.pay_meth_ind = "1" THEN 
			LET l_err_message = " Cheque ", glob_rec_cheque.cheq_code USING "<<<<<&", " already issued"
		ELSE 
			LET l_err_message = " EFT reference ", glob_rec_cheque.cheq_code USING "<<<<<&", " already issued"
		END IF 
		CALL msgerror("",l_err_message)
		RETURN FALSE
	END IF 
	IF glob_rec_cheque.pay_amt > 0 THEN 
	ELSE 
		IF glob_rec_cheque.pay_meth_ind = "1" THEN 
			LET l_err_message = " Cheque ", glob_rec_cheque.cheq_code USING "<<<<<&", " amount must be greater than zero" 
		ELSE 
			LET l_err_message = " EFT reference ", glob_rec_cheque.cheq_code USING "<<<<<&", " amount must be greater than zero"
		END IF 
		CALL msgerror("",l_err_message)
		RETURN FALSE 
	END IF 
	GOTO bypass 
	LABEL recovery: 
	RETURN FALSE 
	LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 
	#
	# Assigned period_num AND year_num as it was displaying NULL on the
	# cheque table AFTER running P34
	#

	BEGIN WORK
	LET glob_rec_cheque.period_num = glob_period_num 
	LET glob_rec_cheque.year_num = glob_year_num 
	LET glob_rec_cheque.post_flag = "N" 
	LET glob_rec_cheque.post_date = NULL 
	LET glob_rec_cheque.recon_flag = "N" 
	LET glob_rec_cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_cheque.apply_amt = 0 
	LET glob_rec_cheque.doc_num = 0 
	LET glob_rec_cheque.tax_amt = glob_rec_cheque.pay_amt - glob_rec_cheque.net_pay_amt 
	# Only P3A allows take up of contra payments
	LET glob_rec_cheque.contra_amt = 0 
	# Vendor's standard tax code IS written TO the cheque
	CALL get_whold_tax(glob_rec_kandoouser.cmpy_code, 
	l_rec_vendor.vend_code, 
	l_rec_vendor.type_code) 
	RETURNING glob_rec_cheque.whtax_rep_ind, 
	l_vend_tax_code, 
	l_vend_tax_per 
	LET l_err_message = "P34 - Cheqhead INSERT" 
	INSERT INTO cheque VALUES (glob_rec_cheque.*) 
	LET l_err_message = "P34 - Vendmain lock" 
	DECLARE curr_amts CURSOR FOR 
	SELECT vendor.* 
	FROM vendor 
	WHERE vend_code = glob_rec_cheque.vend_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	FOR UPDATE 
	OPEN curr_amts 
	FETCH curr_amts INTO l_rec_vendor.* 
	IF glob_rec_cheque.cheq_date > l_rec_vendor.last_payment_date 
	OR l_rec_vendor.last_payment_date IS NULL THEN 
		LET l_rec_vendor.last_payment_date = glob_rec_cheque.cheq_date 
	END IF 
	LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - glob_rec_cheque.net_pay_amt 
	LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - glob_rec_cheque.net_pay_amt 
	LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
	IF glob_rec_cheque.pay_meth_ind = "3" THEN 
		LET l_rec_vendor.bkdetls_mod_flag = "N" 
		LET l_rec_apaudit.tran_text = "Auto EFT Amt" 
	ELSE 
		LET l_rec_apaudit.tran_text = "Auto Cheque Amt" 
	END IF 
	LET l_rec_apaudit.trantype_ind = "CH" 
	LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_apaudit.tran_date = glob_rec_cheque.cheq_date 
	LET l_rec_apaudit.vend_code = glob_rec_cheque.vend_code 
	LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
	LET l_rec_apaudit.year_num = glob_year_num 
	LET l_rec_apaudit.period_num = glob_period_num 
	LET l_rec_apaudit.source_num = glob_rec_cheque.cheq_code 
	LET l_rec_apaudit.tran_amt = 0 - glob_rec_cheque.net_pay_amt 
	LET l_rec_apaudit.entry_code = glob_rec_cheque.entry_code 
	LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
	LET l_rec_apaudit.currency_code = glob_rec_cheque.currency_code 
	LET l_rec_apaudit.conv_qty = glob_rec_cheque.conv_qty 
	LET l_rec_apaudit.entry_date = TODAY 
	LET l_err_message = "P34 - Apdlog INSERT" 
	INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	IF glob_rec_cheque.tax_amt != 0 THEN 
		LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - glob_rec_cheque.tax_amt 
		LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - glob_rec_cheque.tax_amt 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
		LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
		IF glob_rec_cheque.pay_meth_ind = "1" THEN 
			LET l_rec_apaudit.tran_text = "Auto Cheque Tax" 
		ELSE 
			LET l_rec_apaudit.tran_text = "EFT Cheque Tax" 
		END IF 
		LET l_rec_apaudit.tran_amt = 0 - glob_rec_cheque.tax_amt 
		LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	END IF 
	LET l_err_message = "P34 - Vendor UPDATE" 
	UPDATE vendor 
	SET * = l_rec_vendor.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = glob_rec_cheque.vend_code 
	IF glob_rec_cheque.pay_meth_ind = "1" THEN 
		LET l_err_message = "P34 - Chechead INSERT" 
		UPDATE bank 
		SET next_cheque_num = glob_rec_cheque.cheq_code + 1 
		WHERE acct_code = glob_rec_cheque.bank_acct_code 
		AND cmpy_code = glob_rec_cheque.cmpy_code 
	END IF 
	LET l_err_message = "P34 - Apparms UPDATE" 
	UPDATE apparms 
	SET last_chq_prnt_date = glob_rec_cheque.cheq_date 
	WHERE cmpy_code = glob_rec_cheque.cmpy_code 
	LET int_flag = 0 
	LET quit_flag = 0 
	COMMIT WORK

	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION write_cheq()
############################################################


#################################################################
# FUNCTION apply_cheq(p_cheqnum,p_account_code,p_vouch_num,p_payment_amt,p_pay_meth_ind,p_dis_amt)
# NOTE: This FUNCTION was cloned FROM P41d.4gl(auto_ap_cheq) with
#       transaction processing replaced.
############################################################
FUNCTION apply_cheq(p_cheqnum,p_account_code,p_vouch_num,p_payment_amt,p_pay_meth_ind,p_dis_amt) 
	DEFINE p_cheqnum LIKE cheque.cheq_code 
	DEFINE p_account_code LIKE cheque.bank_acct_code 
	DEFINE p_vouch_num LIKE voucher.vouch_code 
	DEFINE p_payment_amt DECIMAL(12,2)
	DEFINE p_pay_meth_ind LIKE cheque.pay_meth_ind	
	DEFINE p_dis_amt DECIMAL(12,2)
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_appl_amt DECIMAL(12,2) 
	DEFINE l_discount_amt DECIMAL(12,2)
	DEFINE l_base_vouc_apply_amt LIKE voucherpays.apply_amt 
	DEFINE l_base_cheq_apply_amt LIKE voucherpays.apply_amt
	DEFINE l_base_vouc_disc_amt LIKE voucherpays.disc_amt 
	DEFINE l_base_cheq_disc_amt LIKE voucherpays.disc_amt
	DEFINE l_strmsg STRING 
	DEFINE l_err_message STRING 

	GOTO bypass 
	LABEL recovery: 
	RETURN FALSE 
	LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 

	BEGIN WORK
	LET l_err_message = "P34 - Cheque UPDATE" 
	DECLARE c_cheque CURSOR FOR 
	SELECT * INTO glob_rec_cheque.* FROM cheque 
	WHERE cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cheque.cheq_code = p_cheqnum 
	AND cheque.bank_acct_code = p_account_code 
	AND cheque.pay_meth_ind = p_pay_meth_ind 
	FOR UPDATE 
	FOREACH c_cheque 
		LET glob_rec_cheque.next_appl_num = glob_rec_cheque.next_appl_num + 1 
		LET l_appl_amt = 0 
		LET l_discount_amt = 0 
		DECLARE c_voucher CURSOR FOR 
		SELECT * INTO l_rec_voucher.* FROM voucher 
		WHERE vouch_code = p_vouch_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		FOREACH c_voucher 
			LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt + p_payment_amt + p_dis_amt 
			IF l_rec_voucher.paid_amt > l_rec_voucher.total_amt THEN 
				ROLLBACK WORK
				LET l_err_message = " Voucher ",p_vouch_num USING "<<<<<&"," has changed, try again"
				CALL msgerror("",l_err_message)
				RETURN FALSE 
			END IF 
			IF l_rec_voucher.taken_disc_amt IS NULL THEN 
				LET l_rec_voucher.taken_disc_amt = 0 
			END IF 
			LET l_rec_voucher.taken_disc_amt = l_rec_voucher.taken_disc_amt + p_dis_amt 
			LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num + 1 
			IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
				LET l_rec_voucher.paid_date = glob_rec_cheque.cheq_date 
			END IF 
			LET l_err_message = "P34 - Vouchead UPDATE" 
			UPDATE voucher 
			SET paid_amt = l_rec_voucher.paid_amt, 
			pay_seq_num = l_rec_voucher.pay_seq_num, 
			taken_disc_amt = l_rec_voucher.taken_disc_amt, 
			paid_date = l_rec_voucher.paid_date 
			WHERE CURRENT OF c_voucher 
			LET l_appl_amt = l_appl_amt + p_payment_amt 
			LET l_discount_amt = l_discount_amt + p_dis_amt 
			LET l_rec_voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_voucherpays.vend_code = glob_rec_cheque.vend_code 
			LET l_rec_voucherpays.vouch_code = l_rec_voucher.vouch_code 
			LET l_rec_voucherpays.seq_num = 0 
			LET l_rec_voucherpays.pay_num = glob_rec_cheque.cheq_code 
			LET l_rec_voucherpays.pay_meth_ind = glob_rec_cheque.pay_meth_ind 
			LET l_rec_voucherpays.apply_num = l_rec_voucher.pay_seq_num 
			LET l_rec_voucherpays.pay_type_code = "CH" 
			LET l_rec_voucherpays.pay_date = glob_rec_cheque.cheq_date 
			LET l_rec_voucherpays.apply_amt = p_payment_amt 
			LET l_rec_voucherpays.disc_amt = p_dis_amt 
			LET l_rec_voucherpays.withhold_tax_ind = glob_rec_cheque.withhold_tax_ind 
			LET l_rec_voucherpays.tax_code = glob_rec_cheque.tax_code 
			LET l_rec_voucherpays.tax_per = glob_rec_cheque.tax_per 
			LET l_rec_voucherpays.bank_code = glob_rec_cheque.bank_code 
			LET l_rec_voucherpays.pay_doc_num = glob_rec_cheque.doc_num 
			LET l_rec_voucherpays.remit_doc_num = glob_rec_cheque.doc_num 
			LET l_rec_voucherpays.rev_flag = NULL 
			LET l_err_message = "P34 - Voucpay INSERT" 
			INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 
			IF l_rec_voucher.conv_qty IS NOT NULL THEN 
				IF l_rec_voucher.conv_qty != 0 THEN 
					LET l_base_vouc_apply_amt = l_rec_voucherpays.apply_amt / 
					l_rec_voucher.conv_qty 
					LET l_base_cheq_apply_amt = l_rec_voucherpays.apply_amt / 
					glob_rec_cheque.conv_qty 
					LET l_base_vouc_disc_amt = l_rec_voucherpays.disc_amt / 
					l_rec_voucher.conv_qty 
					LET l_base_cheq_disc_amt = l_rec_voucherpays.disc_amt / 
					glob_rec_cheque.conv_qty 
				END IF 
			END IF 
			LET l_rec_exchangevar.exchangevar_amt = l_base_cheq_apply_amt - 
			l_base_vouc_apply_amt 
			IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
				LET l_rec_exchangevar.cmpy_code = glob_rec_cheque.cmpy_code 
				LET l_rec_exchangevar.year_num = glob_year_num 
				LET l_rec_exchangevar.period_num = glob_period_num 
				LET l_rec_exchangevar.source_ind = "P" 
				LET l_rec_exchangevar.tran_date = glob_rec_cheque.cheq_date 
				LET l_rec_exchangevar.ref_code = glob_rec_cheque.vend_code 
				LET l_rec_exchangevar.tran_type1_ind = "VO" 
				LET l_rec_exchangevar.ref1_num = l_rec_voucher.vouch_code 
				LET l_rec_exchangevar.tran_type2_ind = "CH" 
				LET l_rec_exchangevar.ref2_num = glob_rec_cheque.cheq_code 
				LET l_rec_exchangevar.currency_code = l_rec_voucher.currency_code 
				LET l_rec_exchangevar.posted_flag = "N" 
				INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
			END IF 
			#
			# Add RECORD FOR exchange variance on discount
			#
			LET l_rec_exchangevar.exchangevar_amt = l_base_cheq_disc_amt - 
			l_base_vouc_disc_amt 
			IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
				INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
			END IF 
		END FOREACH 
		IF p_dis_amt > 0 THEN 
			LET l_err_message = "P34 - Vendmain UPDATE" 
			DECLARE c_vendor CURSOR FOR 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_cheque.vend_code 
			FOR UPDATE 
			FOREACH c_vendor 
				LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt 
				- p_dis_amt 
				LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt 
				- p_dis_amt 
				LET l_rec_vendor.last_payment_date = glob_rec_cheque.cheq_date 
				LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
				LET l_err_message = "P34 - Vendmain UPDATE" 
				UPDATE vendor 
				SET bal_amt = l_rec_vendor.bal_amt, 
				curr_amt = l_rec_vendor.curr_amt, 
				last_payment_date = l_rec_vendor.last_payment_date, 
				next_seq_num = l_rec_vendor.next_seq_num 
				WHERE CURRENT OF c_vendor 
			END FOREACH 
			LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_apaudit.tran_date = glob_rec_cheque.cheq_date 
			LET l_rec_apaudit.year_num = glob_year_num 
			LET l_rec_apaudit.period_num = glob_period_num 
			LET l_rec_apaudit.vend_code = glob_rec_cheque.vend_code 
			LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
			LET l_rec_apaudit.trantype_ind = "CH" 
			LET l_rec_apaudit.source_num = glob_rec_cheque.cheq_code 
			LET l_rec_apaudit.tran_text = "Apply Discount" 
			LET l_rec_apaudit.tran_amt = 0 - p_dis_amt 
			LET l_rec_apaudit.entry_code = glob_rec_cheque.entry_code 
			LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
			LET l_rec_apaudit.currency_code = glob_rec_cheque.currency_code 
			LET l_rec_apaudit.conv_qty = glob_rec_cheque.conv_qty 
			LET l_rec_apaudit.entry_date = TODAY 
			LET l_err_message = "P34 - Apdlog INSERT" 
			INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
		END IF 
		LET l_err_message = "P34 - Cheque Header UPDATE" 
		LET glob_rec_cheque.apply_amt = glob_rec_cheque.apply_amt 
		+ l_appl_amt 
		LET glob_rec_cheque.disc_amt = glob_rec_cheque.disc_amt 
		+ l_discount_amt 
		IF glob_rec_cheque.apply_amt > glob_rec_cheque.pay_amt THEN 
			ROLLBACK WORK
			#huho
			IF glob_rec_cheque.pay_meth_ind = "1" THEN 
				LET l_strmsg = "ERROR : Cheque No.", "\n" 
				LET l_strmsg = l_strmsg CLIPPED, glob_rec_cheque.cheq_code USING "<<<<<<<<<", "\n" 
				LET l_strmsg = l_strmsg CLIPPED, " has been Over Applied - Re Apply Cheques" 
			ELSE 
				LET l_strmsg = "ERROR : EFT Reference ","\n" 
				LET l_strmsg = l_strmsg CLIPPED, glob_rec_cheque.cheq_code USING "<<<<<<<<<","\n" 
				LET l_strmsg = l_strmsg CLIPPED, " has been Over Applied - Re Apply Cheques" 
			END IF 
			CALL msgerror("",l_strmsg)
			RETURN FALSE 
		END IF 
		UPDATE cheque 
		SET * = glob_rec_cheque.* 
		WHERE CURRENT OF c_cheque 
	END FOREACH 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	COMMIT WORK

	RETURN TRUE 

END FUNCTION 
#################################################################
# END FUNCTION apply_cheq(p_cheqnum,p_account_code,p_vouch_num,p_payment_amt,p_pay_meth_ind,p_dis_amt)
############################################################


############################################################
# FUNCTION apply_deb(p_vend_code)
#
#
############################################################
FUNCTION apply_deb(p_vend_code) 
	DEFINE p_vend_code LIKE vendor.vend_code #not used ? 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_payment_amt DECIMAL(12,2) 
	DEFINE l_appl_amt DECIMAL(12,2)
	DEFINE l_apply_amt DECIMAL(12,2)
	DEFINE l_base_vouc_apply_amt, base_debt_apply_amt LIKE voucherpays.apply_amt 
	DEFINE l_strmsg STRING 
	DEFINE l_err_message CHAR(40) 

	GOTO bypass 
	LABEL recovery: 
	RETURN FALSE 
	LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 

	BEGIN WORK
	LET l_err_message = "P34 - Debithead UPDATE" 
	DECLARE c_debithead CURSOR FOR 
	SELECT * INTO l_rec_debithead.* FROM debithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = l_vend_code 
	AND apply_amt != total_amt 
	FOR UPDATE 
	FOREACH c_debithead 
		LET l_apply_amt = l_rec_debithead.total_amt 
		- l_rec_debithead.apply_amt 
		IF l_apply_amt < 0 THEN 
			CONTINUE FOREACH 
		END IF 
		LET l_appl_amt = l_apply_amt 
		LET l_rec_debithead.appl_seq_num = l_rec_debithead.appl_seq_num + 1 
		DECLARE c1_voucher CURSOR FOR 
		SELECT * INTO l_rec_voucher.* FROM voucher 
		WHERE vend_code = l_vend_code 
		AND total_amt != paid_amt 
		AND post_flag != "V" 
		AND hold_code IS NULL #and (hold_code = "NO" OR hold_code IS NULL) 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		FOREACH c1_voucher 
			SELECT UNIQUE 1 FROM tentpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			AND vend_code = l_rec_voucher.vend_code 
			AND vouch_code = l_rec_voucher.vouch_code 
			IF STATUS != NOTFOUND THEN 
				#Voucher IS in tentative payment cycle - Do NOT process
				CONTINUE FOREACH 
			END IF 
			LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num + 1 
			IF l_rec_voucher.paid_amt + l_apply_amt >= l_rec_voucher.total_amt THEN 
				LET l_payment_amt = l_rec_voucher.total_amt 
				- l_rec_voucher.paid_amt 
				LET l_apply_amt = l_apply_amt 
				- (l_rec_voucher.total_amt - l_rec_voucher.paid_amt) 
				LET l_rec_voucher.paid_amt = l_rec_voucher.total_amt 
				LET l_rec_voucher.paid_date = TODAY 
			ELSE 
				LET l_payment_amt = l_apply_amt 
				LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt 
				+ l_apply_amt 
				LET l_apply_amt = 0 
			END IF 
			LET l_err_message = "P34 - DB Vouchead UPDATE" 
			UPDATE voucher 
			SET paid_amt = l_rec_voucher.paid_amt, 
			pay_seq_num = l_rec_voucher.pay_seq_num, 
			paid_date = l_rec_voucher.paid_date 
			WHERE CURRENT OF c1_voucher 
			LET l_rec_voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_voucherpays.vend_code = l_rec_voucher.vend_code 
			LET l_rec_voucherpays.vouch_code = l_rec_voucher.vouch_code 
			LET l_rec_voucherpays.seq_num = 0 
			LET l_rec_voucherpays.pay_num = l_rec_debithead.debit_num 
			LET l_rec_voucherpays.pay_meth_ind = NULL 
			LET l_rec_voucherpays.apply_num = l_rec_voucher.pay_seq_num 
			LET l_rec_voucherpays.pay_type_code = "DB" 
			LET l_rec_voucherpays.pay_date = TODAY 
			LET l_rec_voucherpays.apply_amt = l_payment_amt 
			LET l_rec_voucherpays.disc_amt = 0 
			LET l_rec_voucherpays.withhold_tax_ind = glob_rec_cheque.withhold_tax_ind 
			LET l_rec_voucherpays.tax_code = NULL 
			LET l_rec_voucherpays.tax_per = 0 
			LET l_rec_voucherpays.bank_code = NULL 
			LET l_rec_voucherpays.rev_flag = NULL 
			LET l_rec_voucherpays.pay_doc_num = 0 
			LET l_rec_voucherpays.remit_doc_num = glob_rec_cheque.doc_num 
			LET l_err_message = "P34 - DB Voucpay INSERT" 
			INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 
			IF l_rec_voucher.conv_qty IS NOT NULL THEN 
				IF l_rec_voucher.conv_qty != 0 THEN 
					LET l_base_vouc_apply_amt = l_rec_voucherpays.apply_amt 
					/ l_rec_voucher.conv_qty 
					LET base_debt_apply_amt = l_rec_voucherpays.apply_amt 
					/ l_rec_debithead.conv_qty 
				END IF 
			END IF 
			LET l_rec_exchangevar.exchangevar_amt = 
			base_debt_apply_amt - l_base_vouc_apply_amt 
			IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
				LET l_rec_exchangevar.cmpy_code = l_rec_debithead.cmpy_code 
				LET l_rec_exchangevar.year_num = l_rec_debithead.year_num 
				LET l_rec_exchangevar.period_num = l_rec_debithead.period_num 
				LET l_rec_exchangevar.source_ind = "P" 
				LET l_rec_exchangevar.tran_date = l_rec_debithead.debit_date 
				LET l_rec_exchangevar.ref_code = l_rec_debithead.vend_code 
				LET l_rec_exchangevar.tran_type1_ind = "VO" 
				LET l_rec_exchangevar.ref1_num = l_rec_voucher.vouch_code 
				LET l_rec_exchangevar.tran_type2_ind = "DM" 
				LET l_rec_exchangevar.ref2_num = l_rec_debithead.debit_num 
				LET l_rec_exchangevar.currency_code = l_rec_voucher.currency_code 
				LET l_rec_exchangevar.posted_flag = "N" 
				INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
			END IF 
			IF l_apply_amt = 0 THEN 
				#Debit fully applied
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_err_message = "P34 - Debit Header UPDATE" 
		LET l_rec_debithead.apply_amt = l_rec_debithead.apply_amt 
		+ l_appl_amt 
		- l_apply_amt 
		IF l_rec_debithead.apply_amt > l_rec_debithead.total_amt THEN 

			#huho
			LET l_strmsg = "ERROR : Debit No.", "\n" 
			LET l_strmsg = l_strmsg, l_rec_debithead.debit_num USING "<<<<<<<<<", "\n" 
			LET l_strmsg = l_strmsg, "has been Over Applied - Apply Debits", "\n" 
			CALL fgl_winmessage("Apply Debits",l_strmsg,"info") 

			ROLLBACK WORK
			RETURN FALSE 
		END IF 
		UPDATE debithead 
		SET * = l_rec_debithead.* 
		WHERE CURRENT OF c_debithead 
	END FOREACH 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	COMMIT WORK

	RETURN TRUE 

END FUNCTION 
############################################################
# FUNCTION apply_deb(p_vend_code)
############################################################


############################################################
# FUNCTION upd_chqs2()
#
#
############################################################
FUNCTION upd_chqs2() 
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_cheq_amt LIKE tentpays.vouch_amt 
	DEFINE l_vend_code LIKE tentpays.vend_code 
	DEFINE l_vendor_code LIKE tentpays.vend_code 
	DEFINE l_vendor_text LIKE vendor.name_text 
	DEFINE l_tax_ind LIKE tentpays.withhold_tax_ind 
	DEFINE l_tax_code LIKE tentpays.tax_code 
	DEFINE l_tax_per LIKE tentpays.tax_per 
	DEFINE l_cheq_code LIKE cheque.cheq_code 
	DEFINE l_vouch_code LIKE tentpays.vouch_code 
	DEFINE l_vouch_amt LIKE tentpays.vouch_amt 
	DEFINE l_taken_disc_amt LIKE tentpays.taken_disc_amt 
	DEFINE l_source_ind LIKE cheque.source_ind 
	DEFINE l_source_text LIKE cheque.source_text 
	DEFINE l_error_text CHAR(50) 
	DEFINE l_err_cnt, l_chq_cnt INTEGER 
	DEFINE l_strmsg STRING 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_output STRING #report output file name inc. path
	LET l_err_cnt = 0 
	LET l_chq_cnt = 0 
	DECLARE c5_tentpays CURSOR WITH HOLD FOR 
	SELECT UNIQUE cheq_code, vend_code 
	FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND pay_meth_ind = glob_pay_meth_ind 
	ORDER BY 1 
	
	#------------------------------------------------------------
	#CALL rpt_rmsreps_reset(NULL)	

	LET l_rpt_idx = rpt_start(getmoduleid(),"error_report","N/A",RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT error_report TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------	
	 
	FOREACH c5_tentpays INTO l_cheq_code, l_vendor_code 
		GOTO bypass 
		LABEL recovery: 
		IF STATUS = 0 THEN 
			#
			# Non-DB related errors (eg. cheque already issued, etc.)
			# Outputing all the cheque code, cheque amount, vendor code,
			# AND vendor description TO error REPORT IF a cheque IS skipped.
			#
			SELECT name_text INTO l_vendor_text FROM vendor 
			WHERE vend_code = l_vendor_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_error_text = "Vendor Balance Error" 
			#---------------------------------------------------------
			OUTPUT TO REPORT error_report(l_rpt_idx,
			l_cheq_code, 
			l_cheq_amt, 
			l_vendor_code, 
			l_vendor_text, 
			l_error_text) 
			#---------------------------------------------------------
			LET l_err_cnt = l_err_cnt + 1 
			ROLLBACK WORK 
			CONTINUE FOREACH 
		ELSE 
			IF error_recover(l_err_message, STATUS) != 'Y' THEN 
				LET l_error_text = "Database Lock Error" 
				SELECT name_text INTO l_vendor_text FROM vendor 
				WHERE vend_code = l_vendor_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				#---------------------------------------------------------
				OUTPUT TO REPORT error_report(l_rpt_idx,
				l_cheq_code, 
				l_cheq_amt, 
				l_vendor_code, 
				l_vendor_text, 
				l_error_text) 
				#---------------------------------------------------------
				LET l_err_cnt = l_err_cnt + 1 
				CONTINUE FOREACH 
			END IF 
		END IF 
		LABEL bypass: 
		#
		# Cheque amount
		#
		SELECT sum(vouch_amt) 
		INTO l_cheq_amt 
		FROM tentpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = glob_cycle_num 
		AND cheq_code = l_cheq_code 
		AND vend_code = l_vendor_code 
		AND pay_meth_ind = glob_pay_meth_ind 
		IF l_cheq_amt IS NULL THEN 
			LET l_cheq_amt = 0 
		END IF 
		#
		# Static details within cheque
		#
		DECLARE c6_tentpays CURSOR FOR 
		SELECT vend_code, 
		withhold_tax_ind, 
		tax_code, 
		tax_per, 
		source_ind, 
		source_text 
		FROM tentpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = glob_cycle_num 
		AND cheq_code = l_cheq_code 
		AND vend_code = l_vendor_code 
		AND pay_meth_ind = glob_pay_meth_ind 
		OPEN c6_tentpays 
		FETCH c6_tentpays INTO l_vend_code, 
		l_tax_ind, 
		l_tax_code, 
		l_tax_per, 
		l_source_ind, 
		l_source_text 
		--WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			MESSAGE " Writing Cheque ", l_cheq_code 
			IF NOT write_cheq(l_cheq_code, 
			l_vend_code, 
			l_cheq_amt , 
			0, 
			glob_rec_bank.bank_code, 
			glob_rec_bank.next_cheq_run_num, 
			glob_pay_meth_ind, 
			l_tax_ind, 
			l_tax_code, 
			l_tax_per, 
			l_source_ind, 
			l_source_text) 
			THEN 
				GOTO recovery 
			END IF 
			#
			# Apply cheque TO related vouchers
			#
			DECLARE c8_tentpays CURSOR FOR 
			SELECT vouch_code, 
			vouch_amt, 
			taken_disc_amt 
			FROM tentpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			AND cheq_code = l_cheq_code 
			AND vend_code = l_vendor_code 
			AND pay_meth_ind = glob_pay_meth_ind 
			FOREACH c8_tentpays INTO l_vouch_code, 
				l_vouch_amt , 
				l_taken_disc_amt 
				IF NOT apply_cheq(l_cheq_code, 
				glob_rec_bank.acct_code, 
				l_vouch_code, 
				l_vouch_amt, 
				glob_pay_meth_ind, 
				l_taken_disc_amt) 
				THEN 
					GOTO recovery 
				END IF 
				LET l_err_message = "P34 - Tentpays delete" 
				DELETE FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND vend_code = l_vend_code 
				AND vouch_code = l_vouch_code 
				AND pay_meth_ind = glob_pay_meth_ind 
			END FOREACH 
			#
			# Check IF any unapplied debits exist FOR this vendor
			#
			LET l_err_message = "P34 - Unapplied debits" 
			SELECT UNIQUE 1 FROM debithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = l_vend_code 
			AND apply_amt != total_amt 
			IF SQLCA.SQLCODE = 0 THEN 
				MESSAGE " Applying Debits " 
				IF NOT apply_deb( l_vend_code ) THEN 
					GOTO recovery 
				END IF 
			END IF 
		COMMIT WORK 
		LET l_chq_cnt = l_chq_cnt + 1 
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT error_report
	CALL rpt_finish("error_report")
	#------------------------------------------------------------

	#
	# Summary window of successful vs. rejected cheques
	#
	#huho
	LET l_strmsg = "Cheques sucessfully generated : ", l_chq_cnt USING "#######&", "\n" 
	LET l_strmsg = l_strmsg, "Cheques in error : ", l_err_cnt USING "#######&", "\n" 
	LET l_strmsg = l_strmsg, "Refer TO RMS System IF Cheques in error" 
	CALL fgl_winmessage("Cheque Generation",l_strmsg,"info") 

END FUNCTION 
############################################################
# FUNCTION upd_chqs2()
############################################################


############################################################
# FUNCTION auto_remit()
#
#
############################################################
FUNCTION auto_remit() 
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rpt_note5 CHAR(80) 
	DEFINE l_output5 CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_err_message CHAR(40) 
	DEFINE try_again CHAR(1)
	DEFINE idx SMALLINT
	DEFINE l_output STRING #report output file name inc. path

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(l_err_message, STATUS) 
	IF try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	LET l_err_message = "P34 - Auto Payment Remittance Advices" 

	#------------------------------------------------------------
	#CALL rpt_rmsreps_reset(NULL)

	LET l_rpt_idx = rpt_start(getmoduleid(),"pcf_list","N/A",RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT pcf_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	FOR idx = 1 TO array_idx 
		SELECT * INTO l_rec_cheque.* 
		FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code  
		AND cheq_code = glob_arr_cheque_code[idx] 

		#---------------------------------------------------------
		OUTPUT TO REPORT pcf_list(l_rpt_idx,l_rec_cheque.*)
		IF NOT rpt_int_flag_handler2("Cheque: ",l_rec_cheque.cheq_code,"",l_rpt_idx) THEN
			EXIT FOR 
		END IF 
		#---------------------------------------------------------

	END FOR 

	--WHENEVER ERROR GOTO recovery 
	#------------------------------------------------------------
	FINISH REPORT pcf_list
	RETURN rpt_finish("pcf_list")
	#------------------------------------------------------------
	
END FUNCTION 
############################################################
# FUNCTION auto_remit()
############################################################


############################################################
# REPORT error_report(p_cheq_code,p_cheq_amt,p_vendor_code,p_vendor_text,p_error_text)
#
# Report Definition/Layout
############################################################
REPORT error_report(p_rpt_idx,p_cheq_code,p_cheq_amt,p_vendor_code,p_vendor_text,p_error_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cheq_code LIKE cheque.cheq_code 
	DEFINE p_cheq_amt LIKE tentpays.vouch_amt 
	DEFINE p_vendor_code LIKE tentpays.vend_code 
	DEFINE p_vendor_text LIKE vendor.name_text 
	DEFINE p_error_text CHAR(50)
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT
	DEFINE l_rpt_note CHAR(60)
	DEFINE l_line1 CHAR(132) 
	DEFINE l_msgresp LIKE language.yes_flag 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			IF l_rpt_note IS NULL THEN 
				LET l_rpt_note = "Automatic Payments Error Report - (Menu P34)" 
			END IF 
			LET l_line1 = glob_rec_company.cmpy_code, " ", glob_rec_company.name_text CLIPPED 
			LET l_offset1 = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num/2) - (length (l_line1) / 2) + 1 
			LET l_offset2 = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num/2) - (length (l_rpt_note) / 2) + 1 
			PRINT COLUMN 01, TODAY USING "DD MMM YYYY", 
			COLUMN l_offset1, l_line1 CLIPPED, 
			COLUMN (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num -10), "Page :", 
			COLUMN (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num - 3), pageno USING "##&" 
			PRINT COLUMN 01, time, 
			COLUMN l_offset2, l_rpt_note 
			PRINT COLUMN 01, "--------------------------------------------------", 
			"-------------------------------------------------", 
			"---------------------------------" 
			PRINT COLUMN 01, "Cheque Code", 
			COLUMN 18, " Cheque Amount", 
			COLUMN 51, "Vendor Code", 
			COLUMN 64, "Vendor Description", 
			COLUMN 95, "Error Description" 
			PRINT COLUMN 01, "--------------------------------------------------", 
			"-------------------------------------------------", 
			"---------------------------------" 
			PAGE TRAILER 
				PRINT COLUMN 01, "The above cheques have NOT been written TO database" 
				PRINT COLUMN 01, "Please cancel printed cheque(s) ", 
				COLUMN 33, "OR raise manual payments." 
		ON EVERY ROW 
			PRINT COLUMN 01, p_cheq_code, 
			COLUMN 18, p_cheq_amt, 
			COLUMN 51, p_vendor_code, 
			COLUMN 64, p_vendor_text, 
			COLUMN 95, p_error_text 
		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
