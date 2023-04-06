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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/../ap/P_AP_P3_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS 
	DEFINE glob_rec_tenthead RECORD LIKE tenthead.* 
	DEFINE glob_rec_bank RECORD LIKE bank.* 
	DEFINE glob_rec_banktype RECORD LIKE banktype.* 
	DEFINE glob_rpt_note LIKE rmsreps.report_text  #title line 1 text
	DEFINE glob_rpt_note2 LIKE rmsreps.report_text #title line 2 text	
	DEFINE glob_year_num LIKE cheque.year_num 
	DEFINE glob_period_num LIKE cheque.period_num 
	DEFINE glob_cycle_num LIKE tentpays.cycle_num 
	DEFINE glob_user_text1 LIKE kandoouser.sign_on_code 
	DEFINE glob_user_text2 LIKE kandoouser.sign_on_code
	DEFINE glob_error_text CHAR(60) #was CHAR(8) 
	DEFINE glob_path_name CHAR(60) #was CHAR(8)
	DEFINE glob_cheq_date DATE 
	DEFINE glob_arr_comments ARRAY[10] OF CHAR(60) 
	DEFINE glob_cheque_count INTEGER 
	DEFINE glob_eft_count INTEGER
	DEFINE global_efts_exist SMALLINT 
	DEFINE glob_cheqs_exist SMALLINT
	DEFINE glob_job_status SMALLINT
	DEFINE glob_diff_message SMALLINT 
END GLOBALS 

############################################################
# FUNCTION P3A_main()
#
# Purpose - Generates AND Creates Cheques AND EFT Payments
############################################################
FUNCTION P3A_main()
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_count SMALLINT
	DEFINE l_version CHAR(1)

	DEFER quit 
	DEFER interrupt 

	SELECT kandoo_type INTO l_version FROM kandooinfo 
	### Currently hardcoded - Future enhancement ###
	LET glob_cycle_num = 1 
	OPEN WINDOW p234 with FORM "P234" 
	CALL winDecoration_p("P234") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	IF kandooword("P3A","1") = "N" THEN 
		#LET l_msgresp=kandoomsg("P",7078,"") 
		#P7078 - WARNING: You have selected menu path P3A...
		CALL msgerror("",kandoomsg2("P",7078,""))
		CLOSE WINDOW p234
		EXIT PROGRAM 
	END IF 
	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		#LET l_msgresp=kandoomsg("P",5000,"") 
		#U5000 - Company Not Found"
		CALL msgerror("",kandoomsg2("P",5000,""))
		CLOSE WINDOW p234 
		EXIT PROGRAM 
	END IF 
	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#IF STATUS = NOTFOUND THEN
	#   LET l_msgresp=kandoomsg("U",5116,"")
	#   #U5116 - Parameters Not Found, See Menu PZP"
	#   CLOSE WINDOW P234
	#   EXIT PROGRAM
	#END IF
	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		#LET l_msgresp=kandoomsg('P',5007,'') 
		#P5007 General Ledger...
		CALL msgerror("",kandoomsg2('P',5007,''))
		CLOSE WINDOW p234 
		EXIT PROGRAM 
	END IF 
	SELECT unique 1 FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	IF status = NOTFOUND THEN 
		#LET l_msgresp=kandoomsg("P","7065","") 
		#P7065 There are no Tentative Payments TO Process"
		CALL msgerror("",kandoomsg2("P","7065",""))
		CLOSE WINDOW p234 
		EXIT PROGRAM 
	END IF 
	IF get_kandoooption_feature_state('AP','CH') = 'Y' 
	OR get_kandoooption_feature_state('AP','CH') = 2 THEN 
		CALL cheque_passwd() 
	END IF 
	FOR l_count = 1 TO 10 
		INITIALIZE glob_arr_comments[l_count] TO NULL 
	END FOR 
	LET glob_job_status = 0 

	CALL rpt_rmsreps_reset(NULL)
	CALL process_payments() 

	CLOSE WINDOW p234 
END FUNCTION 
############################################################
# END FUNCTION P3A_main()
############################################################

############################################################
# FUNCTION process_payments()
############################################################
FUNCTION process_payments() 
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arg1 STRING
	
	WHILE TRUE 
		CASE check_status_of_job(glob_job_status) 
			WHEN 1 
				IF get_bank_and_date() THEN 
					LET glob_job_status = 1 
				ELSE 
					LET glob_job_status = 5 
				END IF 
			WHEN 3 
				LET glob_diff_message = 1 
				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start(getmoduleid(),"exception_report","N/A",RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF
				# Automatic Payments Exception Report
				START REPORT exception_report TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------

				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_tenthead.cheq_date) 
				RETURNING glob_year_num, glob_period_num 
				IF glob_job_status = 0 THEN 
					SELECT * INTO glob_rec_bank.* FROM bank 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_code = glob_rec_tenthead.bank_code 
					IF status = NOTFOUND THEN 
						LET glob_error_text = "Bank RECORD cannot be Retrieved" 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
						#---------------------------------------------------------
						LET glob_job_status = 9 
						EXIT CASE 
					END IF 
					SELECT * INTO glob_rec_banktype.* FROM banktype 
					WHERE type_code = glob_rec_bank.type_code 
					IF status = NOTFOUND THEN 
						LET glob_error_text = "Bank Type RECORD cant be Retrieved" 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
						#---------------------------------------------------------
						LET glob_job_status = 9 
						EXIT CASE 
					END IF 
					LET glob_path_name = glob_rec_banktype.eft_path_text clipped,"/", 
					glob_rec_banktype.eft_file_text clipped 
					LET glob_error_text = "Recommence Automatic Cheque/EFT Routine" 
				ELSE 
					LET glob_error_text = "Commence Automatic Cheque/EFT Routine" 
				END IF 
				CALL display_progress(glob_error_text) 
				LET l_msgresp=kandoomsg("U","1002","") 
				#U1002 Searching Database...
				LET glob_error_text = "Commence Tentative Payments Processing" 
				CALL display_progress(glob_error_text) 
				LET glob_cheq_date = glob_rec_tenthead.cheq_date 
				SELECT unique 1 FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND status_ind = "1" 
				IF status != NOTFOUND THEN 
					IF NOT create_cheques_for_payments(l_rpt_idx) THEN 
						LET glob_error_text = 
						"Errors found in Tentative Payments Processing" 
						CALL display_progress(glob_error_text) 
						LET glob_job_status = 9 
						EXIT CASE 
					END IF 
				END IF 
				LET glob_error_text = 
				"Commence Collecting Unreported Payment Applications" 
				CALL display_progress(glob_error_text) 
				SELECT unique 1 FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND status_ind = "3" 
				AND page_num = 0 
				IF status != NOTFOUND THEN 
					IF NOT collect_unreported_applications(l_rpt_idx) THEN 
						LET glob_error_text = 
						"Problems collecting unreported Voucher Applications" 
						CALL display_progress(glob_error_text) 
						LET glob_job_status = 9 
						EXIT CASE 
					END IF 
				END IF
				 
				### EXTERNAL INTERFACE FILE ###
				IF glob_rec_bank.ext_file_ind = "1" THEN 
					LET l_arg1 = "CYCLE_NUM=", trim(glob_cycle_num)
					CALL run_prog("PX3",l_arg1,"P3A","","") 
					SELECT unique 1 FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					AND status_ind = "4" 
					AND pay_meth_ind = "1" 
					AND page_num = 0 
					
					IF status != NOTFOUND THEN 
						LET glob_error_text = 
						"There are Automatic Cheque Payments NOT printed." 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
						#---------------------------------------------------------
						CALL display_progress(glob_error_text) 
						LET glob_job_status = 9 
						EXIT CASE 
					ELSE 
						LET glob_job_status = 3 
						EXIT CASE 
					END IF 
				END IF
				 
				LET glob_cheqs_exist = FALSE 
				SELECT unique 1 FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND status_ind = "4" 
				AND pay_meth_ind = "1" 
				IF status = 0 THEN 
					LET glob_cheqs_exist = TRUE 
				END IF 
				LET global_efts_exist = TRUE 
				SELECT unique 1 FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND status_ind = "4" 
				AND pay_meth_ind = "3" 
				IF status = NOTFOUND THEN 
					LET global_efts_exist = FALSE 
				ELSE 
					LET glob_error_text = "Commence Custom EFT Print Routine" 
					CALL display_progress(glob_error_text) 
					CALL run_custom_print("EFT") 
					SELECT unique 1 FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					AND status_ind = "4" 
					AND pay_meth_ind = "3" 
					AND page_num = 0 
					IF status = 0 THEN 
						LET glob_error_text = 
						"There are Automatic EFT Payments NOT Reported." 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
						#---------------------------------------------------------
						CALL display_progress(glob_error_text) 
						LET glob_job_status = 9 
						EXIT CASE 
					END IF 
				END IF 
				### IF there were EFTs noted FROM before lets produce the
				### formatted file IF indicated.
				IF global_efts_exist THEN 
					LET glob_error_text = "Commence EFT Bank File Routine" 
					CALL display_progress(glob_error_text) 
					IF NOT create_eft_bank_file() THEN 
						LET glob_error_text = "Errors found in EFT Bank File Routine" 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
						#---------------------------------------------------------
						CALL display_progress(glob_error_text) 
						LET glob_job_status = 9 
						EXIT CASE 
					END IF 
				END IF 
				IF glob_cheqs_exist THEN 
					LET glob_error_text = "Commence Custom Cheque Print Routine" 
					CALL display_progress(glob_error_text) 
					CALL run_custom_print("CHQ") 
					# There IS the possibility that the custom PRINT routine failed
					# AND has allowed the program TO continue.  Therefore we need TO
					# check that all the tentpays records have been updated before
					# we proceed with the numbering process.
					SELECT unique 1 FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					AND status_ind = "4" 
					AND pay_meth_ind = "1" 
					AND page_num = 0 
					IF status != NOTFOUND THEN 
						LET glob_error_text = 
						"There are Automatic Cheque Payments NOT printed." 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
						#---------------------------------------------------------
						CALL display_progress(glob_error_text) 
						LET glob_job_status = 9 
						EXIT CASE 
					END IF 
					LET glob_error_text = "Commence Cheque Number Allocation" 
					CALL display_progress(glob_error_text) 
					IF NOT update_cheques_printed() THEN 
						LET glob_error_text = "Cheque Number Allocation Incomplete" 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
						#---------------------------------------------------------
						CALL display_progress(glob_error_text) 
						LET glob_error_text = 
						"INCOMPLETE Automatic Cheque/EFT Payment Routine" 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
						#---------------------------------------------------------
						CALL display_progress(glob_error_text) 
						LET l_msgresp=kandoomsg("P","7063","Incomplete.") 
						#P7063 Automatic Payment Run FOR Cheques/EFTs IS Incomplete
						LET glob_job_status = 10 ## opted TO terminate now 
						EXIT WHILE 
					END IF 
				END IF 
				LET glob_job_status = 3 
			WHEN 4 
				LET glob_error_text = "Deletion of Tentative Payments Processed" 
				CALL display_progress(glob_error_text) 
				LET glob_job_status = 9 
				LET glob_diff_message = 0 ### this flags the different MESSAGE 
				--WHENEVER ERROR CONTINUE 
				IF NOT remove_processed_payments() THEN 
					LET glob_error_text = "Errors found in Deleting Payments" 
					#---------------------------------------------------------
					OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
					#---------------------------------------------------------
					CALL display_progress(glob_error_text) 
				ELSE 
					### Remove the tenthead RECORD FOR this cycle AND glob_rec_kandoouser.cmpy_code ###
					### AT this point there should be no tentpays records ###
					### but we better check anyway before removing the     ###
					### tenthead record.                                   ###
					SELECT unique 1 FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					IF status = NOTFOUND THEN 
						DELETE FROM tenthead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cycle_num = glob_cycle_num 
						IF status <> 0 THEN 
							LET glob_error_text = 
							"Error in Deleting the Tentative Control" 
							#---------------------------------------------------------
							OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
							#---------------------------------------------------------
							CALL display_progress(glob_error_text) 
						ELSE 
							LET l_msgresp=kandoomsg("P","7076","Complete.") 
							#P7063 Automatic Payment Run IS VALUE
							LET glob_error_text = 
							"Completion of Automatic Cheque/EFT Routine" 
							CALL display_progress(glob_error_text) 
							IF NOT glob_cheqs_exist THEN 

								MENU " Print EFT Report" 

									BEFORE MENU 
										CALL publish_toolbar("kandoo","P3A","menu-print_eft-1") 

									ON ACTION "WEB-HELP" 
										CALL onlinehelp(getmoduleid(),null) 
									ON ACTION "actToolbarManager" 
										CALL setuptoolbar() 

									ON ACTION "Print Manager" 
										#COMMAND KEY("P") "Print" " Print OR view using RMS"
										CALL run_prog("URS","","","","") 

									COMMAND KEY("E", interrupt) "Exit" " Exit Automatic Payment Cycle" 
										EXIT MENU 

								END MENU 
							END IF 
							LET glob_job_status = 4 
							EXIT WHILE 
						END IF 
					ELSE 
						LET glob_diff_message = 1 
						LET glob_error_text = 
						"There are tentative payments still in cycle" 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
						#---------------------------------------------------------
						CALL display_progress(glob_error_text) 
					END IF 
				END IF 
			OTHERWISE 
				### User has NOT attempted TO restart the automatic payment run ###
				### OR has initiated a cancel operation in one of the above jobs###
				IF glob_job_status = 9 THEN 
					CASE glob_diff_message 
						WHEN 0 
							LET glob_error_text = 
							"CANCELLED Automatic Cheque/EFT Payment Routine" 
							#---------------------------------------------------------
							OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
							#---------------------------------------------------------
							CALL display_progress(glob_error_text) 
							LET l_msgresp=kandoomsg("P","7063","Incomplete.") 
							#P7063 Automatic Payment Run FOR Cheques/EFTs IS VALUE
						WHEN 1 
							LET glob_error_text = 
							"INCOMPLETE Automatic Cheque/EFT Payment Routine" 
							#---------------------------------------------------------
							OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
							#---------------------------------------------------------
							CALL display_progress(glob_error_text) 
							LET l_msgresp=kandoomsg("P","7076","Incomplete.") 
							#P7076 Automatic Payment Run FOR Cheques/EFTs IS VALUE
						WHEN 2 
							LET glob_error_text = 
							"INCOMPLETE Automatic Cheque/EFT Payment Routine" 
							#---------------------------------------------------------
							OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
							#---------------------------------------------------------
							CALL display_progress(glob_error_text) 
							LET l_msgresp=kandoomsg("P","7077","") 
							#P7077 Automatic Payment Run FOR Cheqs/EFTs IS Incomplete
					END CASE 
				END IF 
				EXIT WHILE 
		END CASE 
	END WHILE 
	IF (glob_job_status>0 AND glob_job_status!=5) THEN 
		LET glob_error_text = "Automatic Payment Cycle Details" 
		#---------------------------------------------------------
		OUTPUT TO REPORT exception_report(l_rpt_idx,glob_error_text)
		#---------------------------------------------------------

		#------------------------------------------------------------
		FINISH REPORT exception_report
		CALL rpt_finish("exception_report")
		#------------------------------------------------------------

		IF glob_job_status = 9 THEN 

			MENU " Exception Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","P3A","menu-exception_report-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Print Manager" 
					#COMMAND KEY("P") "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				COMMAND KEY("E",interrupt) "Exit" " Exit the Automatic Payment Cycle" 
					EXIT MENU 

			END MENU 
		END IF 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION process_payments()
############################################################

############################################################
# FUNCTION display_progress(p_text_line)
############################################################
FUNCTION display_progress(p_text_line) 
	DEFINE p_text_line CHAR(60) 
	DEFINE idx SMALLINT 

	FOR idx = 1 TO 9 
		IF glob_arr_comments[idx] IS NULL THEN 
			EXIT FOR 
		END IF 
	END FOR 
	LET glob_arr_comments[idx] = p_text_line 
	DISPLAY glob_arr_comments[idx] TO sr_comments[idx].comments 

END FUNCTION 
############################################################
# FUNCTION display_progress(p_text_line)
############################################################

############################################################
# FUNCTION get_bank_and_date()
############################################################
FUNCTION get_bank_and_date() 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_vend_curr_code LIKE vendor.currency_code 
	DEFINE l_bank_acct_code LIKE cheque.bank_acct_code 
	DEFINE l_payment_count INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp=kandoomsg("U",1020,"Payment") 
	#U1020 Enter Payment Details
	LET glob_cheq_date = today 
	SELECT * INTO glob_rec_bank.* FROM bank 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_apparms.bank_acct_code 
	DISPLAY BY NAME glob_rec_bank.currency_code 
	attribute(green) 

--	INPUT BY NAME glob_rec_bank.bank_code, 
--	pr_cheq_date WITHOUT DEFAULTS 
	INPUT glob_rec_bank.bank_code,glob_cheq_date WITHOUT DEFAULTS FROM bank_code,cheq_date 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P3A","inp-bank-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) 
			IF infield (bank_code) THEN 
				CALL show_bank(glob_rec_kandoouser.cmpy_code) 
				RETURNING glob_rec_bank.bank_code, 
				l_bank_acct_code 
				DISPLAY BY NAME glob_rec_bank.bank_code 
				NEXT FIELD bank_code 
			END IF 
		AFTER FIELD bank_code 
			SELECT * INTO glob_rec_bank.* FROM bank 
			WHERE bank_code = glob_rec_bank.bank_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				#LET l_msgresp=kandoomsg("P",9003,"") 
				#9003 Bank Code NOT found - Try Window"
				ERROR kandoomsg2("P",9003,"")
				NEXT FIELD bank_code 
			END IF 
			DECLARE c1_tentpays CURSOR FOR 
			SELECT * FROM tentpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			OPEN c1_tentpays 
			FETCH c1_tentpays INTO l_rec_tentpays.* 
			IF status != NOTFOUND THEN 
				SELECT currency_code INTO l_vend_curr_code FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_tentpays.vend_code 
				IF l_vend_curr_code <> glob_rec_bank.currency_code THEN 
					#LET l_msgresp=kandoomsg("P","9191",l_vend_curr_code) 
					#P9191 Bank must have ....
					ERROR kandoomsg2("P","9191",l_vend_curr_code)
					NEXT FIELD bank_code 
				END IF 
			END IF 
			IF glob_eft_count > 0 THEN 
				IF glob_rec_bank.type_code IS NULL THEN 
					#LET l_msgresp=kandoomsg("P","9076","") 
					#P9076 A bank type has NOT been defined FOR this bank
					ERROR kandoomsg2("P","9076","")
					NEXT FIELD bank_code 
				END IF 
				SELECT * INTO glob_rec_banktype.* FROM banktype 
				WHERE type_code = glob_rec_bank.type_code 
				IF status = NOTFOUND THEN 
					#LET l_msgresp=kandoomsg("P","9076","") 
					#P9076 A bank type has NOT been defined FOR this bank
					ERROR kandoomsg2("P","9076","")
					NEXT FIELD bank_code 
				END IF 
				IF glob_rec_banktype.eft_format_ind != 1 AND 
				glob_rec_banktype.eft_format_ind != 5 THEN 
					#LET l_msgresp=kandoomsg("P",9127,"") 
					#9127 EFT file FORMAT NOT available - Check Bank Type parameters
					ERROR kandoomsg2("P",9127,"")
					NEXT FIELD bank_code 
				END IF 
				# Create temp table TO test directory of EFT file
				WHENEVER ERROR CONTINUE 
				IF glob_rec_bank.ext_file_ind <> "1" THEN # eft file NOT used FOR external payments 
					DROP TABLE t_testdir 
					CREATE temp TABLE t_testdir(pr_pay_line CHAR(10)) with no LOG 
					LET glob_path_name = glob_rec_banktype.eft_path_text clipped,"/","tempfile" 
					DELETE FROM t_testdir 
					UNLOAD TO glob_path_name 
					SELECT * FROM t_testdir 
					IF status = -806 THEN 
						#LET l_msgresp=kandoomsg("P",9128,"") 
						#9128 " EFT directory NOT found - Check Bank Type parameters"
						--WHENEVER ERROR stop 
						ERROR kandoomsg2("P",9128,"")
						NEXT FIELD bank_code 
					END IF 
					# Check IF file exists by inserting INTO temporary temp table
					--WHENEVER ERROR CONTINUE 
					DELETE FROM t_testdir 
					LET glob_path_name = glob_rec_banktype.eft_path_text clipped,"/", 
												glob_rec_banktype.eft_file_text clipped 
					LOAD FROM glob_path_name INSERT INTO t_testdir 
					IF status = 0 THEN 
						LET l_msgresp = kandoomsg("P",8017,"") 
						#8017 "EFT file already exists. Overwrite? (Y/N)"
						IF l_msgresp matches "[Nn]" THEN 
							--WHENEVER ERROR stop 
							NEXT FIELD bank_code 
						END IF 
					END IF 
				END IF 
				--WHENEVER ERROR stop 
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				IF glob_rec_bank.ext_file_ind = "1" THEN 
					LET l_payment_count = glob_eft_count + glob_cheque_count 
				ELSE 
					LET l_payment_count = glob_eft_count 
				END IF 
				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code between glob_rec_bank.next_eft_ref_num 
				AND (glob_rec_bank.next_eft_ref_num + l_payment_count - 1) 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "3" 
				IF status != NOTFOUND THEN 
					#LET l_msgresp=kandoomsg("P",9052,glob_rec_bank.next_eft_ref_num) 
					#9052 EFT reference Number n already issued
					ERROR kandoomsg2("P",9052,glob_rec_bank.next_eft_ref_num)
					NEXT FIELD bank_code 
				END IF 
				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND eft_run_num = glob_rec_bank.next_eft_run_num 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "3" 
				IF status != NOTFOUND THEN 
					#LET l_msgresp=kandoomsg("P",9053,glob_rec_bank.next_eft_run_num) 
					#9053 EFT Run Number n already issued
					ERROR kandoomsg2("P",9053,glob_rec_bank.next_eft_run_num)
					NEXT FIELD bank_code 
				END IF 
			END IF 
			IF glob_rec_bank.ext_file_ind = "1" THEN 
				SELECT unique 1 FROM menu3 
				WHERE run_text matches "PX3*" 
				IF status = NOTFOUND THEN 
					#LET l_msgresp = kandoomsg("P",7007,"") 
					#7007 No definition exists FOR external interface FOR this bank
					ERROR kandoomsg2("P",7007,"")
					NEXT FIELD bank_code 
				END IF 
				# Create temp table TO test directory of External Interface File
				WHENEVER ERROR CONTINUE 
				DROP TABLE t_testdir 
				CREATE temp TABLE t_testdir(pr_pay_line CHAR(500)) with no LOG 
				LET glob_path_name = glob_rec_bank.ext_path_text clipped,"/","tempfile" 
				DELETE FROM t_testdir 
				UNLOAD TO glob_path_name 
				SELECT * FROM t_testdir 
				IF status = -806 THEN 
					#LET l_msgresp=kandoomsg("P",9535,"") 
					#9535 " Directory NOT found - Check Bank parameters"
					--WHENEVER ERROR stop 
					ERROR kandoomsg2("P",9535,"")
					NEXT FIELD bank_code 
				END IF 
				# Check IF file exists by inserting INTO temporary temp table
				--WHENEVER ERROR CONTINUE 
				DELETE FROM t_testdir 
				LET glob_path_name = glob_rec_bank.ext_path_text clipped,"/", 
				glob_rec_bank.ext_file_text clipped 
				LOAD FROM glob_path_name INSERT INTO t_testdir 
				IF status = 0 THEN 
					LET l_msgresp = kandoomsg("P",8009,"") 
					#8009 "Interface file already exists. Overwrite? (Y/N)"
					IF l_msgresp = "N" THEN 
						--WHENEVER ERROR stop 
						NEXT FIELD bank_code 
					END IF 
				END IF 
				--WHENEVER ERROR stop 
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			END IF 
			DISPLAY BY NAME glob_rec_bank.name_acct_text 

			DISPLAY BY NAME glob_rec_bank.currency_code 
			attribute(green) 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_cheq_date IS NULL THEN 
					#LET l_msgresp=kandoomsg("P",9190,"") 
					#9190 The cheque date IS NOT valid.
					ERROR kandoomsg2("P",9190,"")
					NEXT FIELD cheq_date 
				END IF 
				IF glob_cheq_date > today + 30 THEN 
					LET l_msgresp=kandoomsg("P",8018,"") 
					#1008 WARNING: Date IS 30 days FROM today. Continue? (Y?N)
					IF l_msgresp matches "[Nn]" THEN 
						NEXT FIELD cheq_date 
					END IF 
				END IF 
				IF glob_cheq_date < today - 30 THEN 
					LET l_msgresp=kandoomsg("P",8019,"") 
					#1008 WARNING: Date IS 30 days less than today. Continue? (Y?N)
					IF l_msgresp matches "[Nn]" THEN 
						NEXT FIELD cheq_date 
					END IF 
				END IF 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_cheq_date) 
				RETURNING glob_year_num, glob_period_num 
				IF NOT valid_period2(glob_rec_kandoouser.cmpy_code,glob_year_num,glob_period_num,"ap") THEN 
					#LET l_msgresp=kandoomsg("G",9013,"") 
					ERROR kandoomsg2("G",9013,"")
					NEXT FIELD cheq_date 
				END IF 
				### ask Continue TO process automatic payments ###
				LET l_msgresp=kandoomsg("P","8023","Commence") 
				IF l_msgresp != "Y" THEN 
					NEXT FIELD bank_code 
				END IF 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		--WHENEVER ERROR GOTO recovery6 
		GOTO bypass6 
		LABEL recovery6: 
		IF error_recover(glob_error_text,status) != "Y" THEN 
			RETURN FALSE 
		END IF 
		LABEL bypass6: 
		BEGIN WORK 
			DECLARE c_tenthead CURSOR FOR 
			SELECT * FROM tenthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			FOR UPDATE 
			LET glob_error_text = "Problems in Tentative Control (Get) - P3A" 
			OPEN c_tenthead 
			FETCH c_tenthead INTO glob_rec_tenthead.* 
			UPDATE tenthead 
			SET bank_code = glob_rec_bank.bank_code, 
			cheq_date = glob_cheq_date 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			--WHENEVER ERROR CONTINUE 
		COMMIT WORK 
		RETURN TRUE 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION get_bank_and_date()
############################################################

############################################################
# FUNCTION setup_cheque_range_allocation()
############################################################
FUNCTION setup_cheque_range_allocation() 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_arr_disp_vend ARRAY[1500] OF RECORD 
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
	DEFINE l_arr_range ARRAY[100] OF RECORD 
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
	DEFINE l_doc_num LIKE tentpays.pay_doc_num 
	DEFINE l_pay_doc_num LIKE tentpays.pay_doc_num
	DEFINE l_page_num LIKE tentpays.page_num
	DEFINE l_vend_code LIKE tentpays.vend_code 
	DEFINE l_prev_chq INTEGER 
	DEFINE l_chq_cnt INTEGER
	DEFINE l_print_cnt INTEGER
	DEFINE l_scrn INTEGER 
	DEFINE l_cnt_chq INTEGER
	DEFINE l_cnt1 INTEGER
	DEFINE l_cnt2 INTEGER
	DEFINE l_arr_count INTEGER 
	DEFINE l_lastkey INTEGER
	DEFINE l_prev_pages INTEGER
	DEFINE l_save_pages INTEGER
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_count SMALLINT	
	DEFINE l_arr_cnt INTEGER
	DEFINE idx,i,j,k,curr,scrn INTEGER

	### INITIALIZE ARRAY ###
	FOR i = 1 TO 100 
		INITIALIZE l_arr_range[i].* TO NULL 
	END FOR 
	LET curr = 0 
	LET l_chq_cnt = 0 
	INITIALIZE l_rec_range.* TO NULL 
	### Fill up the Vendor DISPLAY ARRAY VALUES###
	DECLARE c7_tentpays CURSOR FOR 
	SELECT unique vend_code, page_num 
	FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND status_ind = "4" 
	AND cheq_code = 0 
	AND pay_meth_ind = "1" 
	AND (page_num IS NOT NULL AND page_num != 0) 
	ORDER BY 2 
	LET l_count = 1 
	FOREACH c7_tentpays INTO l_arr_disp_vend[l_count].vend_code, 
		l_arr_disp_vend[l_count].page_num 
		LET l_count = l_count + 1 
	END FOREACH 
	### Highest page number represents total physical cheques used ###
	SELECT max(page_num) INTO l_print_cnt FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND status_ind = "4" 
	AND pay_meth_ind = "1" 
	AND vouch_amt != 0 
	AND cheq_code = 0 
	AND (page_num IS NOT NULL AND page_num !=0) 
	IF l_print_cnt IS NULL THEN 
		LET l_print_cnt = 0 
	END IF 
	OPEN WINDOW p239 with FORM "P239" 
	CALL winDecoration_p("P239") 

	DISPLAY l_print_cnt,l_chq_cnt TO print_cnt,chq_cnt  

	LET l_lastkey = NULL 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(curr) 
	LET l_msgresp = kandoomsg("P",1065,"") 
	#1065 Enter Cheque No. Details - F1 TO Add - F2 TO Delete
	INPUT ARRAY l_arr_range WITHOUT DEFAULTS FROM sr_range.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P3A","inp-arr-range-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
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
			IF (l_arr_range[curr].start_num IS null) OR 
			(l_arr_range[curr].start_num <= 0) THEN 
				#LET l_msgresp=kandoomsg("P",9062,"") 
				#9062 Must enter start no.
				LET l_lastkey = NULL 
				ERROR kandoomsg2("P",9062,"")
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
			IF (l_arr_range[curr].end_num IS null) OR 
			(l_arr_range[curr].end_num <= 0) THEN 
				#LET l_msgresp=kandoomsg("P",9064,"") 
				#9064 Must enter END no.
				ERROR kandoomsg2("P",9064,"")
				NEXT FIELD end_num 
			END IF 
			LET l_lastkey = fgl_lastkey() 
			SELECT unique 1 FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheq_code between l_arr_range[curr].start_num AND 
			l_arr_range[curr].end_num 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "1" 
			IF status != NOTFOUND THEN 
				#LET l_msgresp=kandoomsg("P",9010,"in this range") 
				#9010 Cheque Number n already issued
				ERROR kandoomsg2("P",9010,"in this range")
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
				IF l_scrn <= 9 THEN 
					DISPLAY l_arr_range[l_cnt1].* TO sr_range[l_scrn].* 

					LET l_scrn = l_scrn + 1 
				END IF 
			END FOR 
			LET l_rec_range.* = l_arr_range[curr].* 
			### Screen Handling FOR a Vendor Code start AND END ###
			LET l_scrn = scrn 
			FOR l_cnt1 = 1 TO 100 
				INITIALIZE l_rec_range.start_vend TO NULL 
				INITIALIZE l_arr_range[l_cnt1].start_vend TO NULL 
				INITIALIZE l_rec_range.end_vend TO NULL 
				INITIALIZE l_arr_range[l_cnt1].end_vend TO NULL 
				IF l_arr_range[l_cnt1].start_num IS NOT NULL THEN 
					LET l_cnt_chq = l_cnt_chq + 1 
					FOR l_cnt2 = 1 TO 1500 
						IF (l_arr_disp_vend[l_cnt2].page_num != 0) THEN 
							IF (l_arr_disp_vend[l_cnt2].page_num >= l_cnt_chq) THEN 
								LET l_rec_range.start_vend 
								= l_arr_disp_vend[l_cnt2].vend_code 
								LET l_arr_range[l_cnt1].start_vend 
								= l_arr_disp_vend[l_cnt2].vend_code 
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
					FOR l_cnt2 = 1 TO 1500 
						IF (l_arr_disp_vend[l_cnt2].page_num != 0) THEN 
							IF (l_arr_disp_vend[l_cnt2].page_num >= l_cnt_chq) 
							THEN 
								LET l_rec_range.end_vend 
								= l_arr_disp_vend[l_cnt2].vend_code 
								LET l_arr_range[l_cnt1].end_vend 
								= l_arr_disp_vend[l_cnt2].vend_code 
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
			LET l_scrn = 1 
			FOR i = (curr-scrn)+1 TO curr+(9 - scrn) 
				DISPLAY l_arr_range[i].* TO sr_range[l_scrn].* 

				LET l_scrn = l_scrn + 1 
			END FOR 
			LET l_rec_range.* = l_arr_range[curr].* 
			NEXT FIELD scroll_flag 
		BEFORE FIELD chq_cnt 
			IF l_lastkey != fgl_keyval("interrupt") THEN 
				IF l_arr_range[curr].end_num IS NOT NULL THEN 
					IF l_arr_range[curr].start_num > l_arr_range[curr].end_num THEN 
						#LET l_msgresp=kandoomsg("P",9063,"") 
						#9063 Starting no. must be less than ending no.
						ERROR kandoomsg2("P",9063,"")
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
							#LET l_msgresp=kandoomsg("P",9065,"") 
							#9065 Invalid cheque range specified
							ERROR kandoomsg2("P",9065,"")
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
						FOR l_cnt2 = 1 TO 1500 
							IF (l_arr_disp_vend[l_cnt2].page_num != 0) THEN 
								IF (l_arr_disp_vend[l_cnt2].page_num >= l_cnt_chq) THEN 
									LET l_rec_range.start_vend 
									= l_arr_disp_vend[l_cnt2].vend_code 
									LET l_arr_range[l_cnt1].start_vend 
									= l_arr_disp_vend[l_cnt2].vend_code 
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
						FOR l_cnt2 = 1 TO 1500 
							IF (l_arr_disp_vend[l_cnt2].page_num != 0) THEN 
								IF (l_arr_disp_vend[l_cnt2].page_num >= l_cnt_chq) 
								THEN 
									LET l_rec_range.end_vend 
									= l_arr_disp_vend[l_cnt2].vend_code 
									LET l_arr_range[l_cnt1].end_vend 
									= l_arr_disp_vend[l_cnt2].vend_code 
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
				LET l_scrn = 1 
				FOR i = (curr-scrn)+1 TO curr+(9-scrn) 
					DISPLAY l_arr_range[i].* TO sr_range[l_scrn].* 

					LET l_scrn = l_scrn + 1 
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
					EXIT INPUT 
				END IF 
			ELSE 
				IF l_arr_range[curr].start_num IS NOT NULL OR 
				l_arr_range[curr].end_num IS NOT NULL THEN 
					IF (l_arr_range[curr].start_num IS null) OR 
					(l_arr_range[curr].start_num <= 0) THEN 
						#LET l_msgresp=kandoomsg("P",9062,"") 
						#9062 Must enter start no.
						ERROR kandoomsg2("P",9062,"")
						NEXT FIELD start_num 
					END IF 
					IF (l_arr_range[curr].end_num IS null) OR 
					(l_arr_range[curr].end_num <= 0) THEN 
						#LET l_msgresp=kandoomsg("P",9064,"") 
						#9064 Must enter END no.
						ERROR kandoomsg2("P",9064,"")
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
					#LET l_msgresp=kandoomsg("P",9066,"") 
					#9066 No. of cheques numbered does NOT match those printed
					ERROR kandoomsg2("P",9066,"")
					NEXT FIELD scroll_flag 
				END IF 
				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code between l_arr_range[curr].start_num AND 
				l_arr_range[curr].end_num 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "1" 
				IF status != NOTFOUND THEN 
					#LET l_msgresp=kandoomsg("P",9010,"in this range") 
					#9010 Cheque Number n already issued
					ERROR kandoomsg2("P",9010,"in this range")
					NEXT FIELD scroll_flag 
				END IF 
				--WHENEVER ERROR CONTINUE 
				GOTO bypass5 
				LABEL recovery5: 
				IF error_recover(glob_error_text,status) != "Y" THEN 
					LET int_flag = TRUE 
					EXIT INPUT 
				END IF 
				LABEL bypass5: 
				--WHENEVER ERROR GOTO recovery5 
				LET l_msgresp=kandoomsg("U",1005,"") 
				#U1005 Updating database - please wait
				BEGIN WORK 
					### Cheque numbers allocated by adding page number as offset TO
					### starting cheque number.  IF break in range detected, reset
					### start number TO be start of next range AND subtract previously
					### printed pages FROM the current offset TO get offset FROM that
					### start number
					LET i = 1 
					LET l_prev_pages = 0 
					LET l_save_pages = 0 
					LET l_start_cheq_num = l_arr_range[1].start_num 
					LET l_cheque_num = NULL 
					DECLARE c_cheque CURSOR FOR 
					SELECT doc_num FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND doc_num = l_pay_doc_num 
					FOR UPDATE 
					DECLARE c_voucherpays CURSOR FOR 
					SELECT * FROM voucherpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_vend_code 
					AND remit_doc_num = l_pay_doc_num 
					AND pay_doc_num = l_pay_doc_num 
					FOR UPDATE 
					DECLARE c_apaudit CURSOR FOR 
					SELECT * FROM apaudit 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_num = l_pay_doc_num 
					AND vend_code = l_vend_code 
					FOR UPDATE 
					DECLARE c_exchangevar CURSOR FOR 
					SELECT * FROM exchangevar 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ref2_num = l_pay_doc_num 
					AND tran_type2_ind = "CH" 
					FOR UPDATE 
					DECLARE c4_tentpays CURSOR FOR 
					SELECT unique pay_doc_num, page_num, vend_code 
					FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					AND status_ind = "4" 
					AND pay_meth_ind = "1" 
					ORDER BY page_num 
					FOREACH c4_tentpays INTO l_pay_doc_num, 
						l_page_num, 
						l_vend_code 
						# Get valid number in range
						WHILE TRUE 
							LET l_cheque_num = l_start_cheq_num + 
							(l_page_num - l_prev_pages) - 1 
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
						### Check FOR error in range AND reset allocations ###
						IF l_cheque_num IS NULL THEN 
							LET l_msgresp=kandoomsg("P",9066,"") 
							#9066 No. of cheques numbered does NOT match those printed
							EXIT FOREACH 
						ELSE 
							LET glob_error_text = "Problems Opening Cheque Table - P3A" 
							OPEN c_cheque 
							LET glob_error_text = "Problems Fetching Cheque Table - P3A" 
							FETCH c_cheque INTO l_doc_num 
							LET glob_error_text = "Problems Updating Cheque Range Numbers - P3A" 
							UPDATE cheque 
							SET cheq_code = l_cheque_num 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND doc_num = l_pay_doc_num 
							AND cheq_code = 0 
							CLOSE c_cheque 
							### Lets UPDATE the voucherpays AND apaudits AND exchangevar too ###
							LET glob_error_text = "Problems Opening VoucherPays Table (Range) - P3A" 
							OPEN c_voucherpays 
							LET glob_error_text = "Problems Fetching VoucherPays Table (Range) - P3A" 
							FETCH c_voucherpays INTO l_rec_voucherpays.* 
							LET glob_error_text = "Problems updating Voucher Applications (Range)- P3A" 
							UPDATE voucherpays 
							SET pay_num = l_cheque_num 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND remit_doc_num = l_pay_doc_num 
							AND pay_doc_num = l_pay_doc_num 
							CLOSE c_voucherpays 
							LET glob_error_text = "Problems Opening ApAudit Table (Range) - P3A" 
							OPEN c_apaudit 
							LET glob_error_text = "Problems Fetching ApAudit Table (Range) - P3A" 
							FETCH c_apaudit INTO l_rec_apaudit.* 
							LET glob_error_text = "Problems updating Vendor Audit Trail (Range) - P3A" 
							UPDATE apaudit 
							SET source_num = l_cheque_num, 
							trantype_ind = "CH" 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND source_num = l_pay_doc_num 
							AND vend_code = l_vend_code 
							CLOSE c_apaudit 
							LET glob_error_text = "Problems Opening ExchangeVar Table (Range) - P3A" 
							OPEN c_exchangevar 
							LET glob_error_text = "Problems Fetching ExchangeVar Table (Range) - P3A" 
							FETCH c_exchangevar INTO l_rec_exchangevar.* 
							LET glob_error_text = "Problems updating Exchange Variances (Range)- P3A" 
							UPDATE exchangevar 
							SET ref2_num = l_cheque_num 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ref2_num = l_pay_doc_num 
							AND tran_type2_ind = "CH" 
							CLOSE c_exchangevar 
							### Update Tentative Payment records with the cheque number ###
							LET glob_error_text = "Problems updating Tentative Payments (Range) - P3A" 
							UPDATE tentpays 
							SET cheq_code = l_cheque_num 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cycle_num = glob_cycle_num 
							AND pay_doc_num = l_pay_doc_num 
							AND status_ind = "4" 
						END IF 
						LET l_save_pages = l_page_num 
					END FOREACH 
					IF l_cheque_num IS NULL THEN 
						ROLLBACK WORK 
						#LET l_msgresp = kandoomsg("P",1065,"") 
						#1065 Enter Cheque No. Details - F1 TO Add - F2 TO Delete
						ERROR kandoomsg2("P",1065,"")
						NEXT FIELD scroll_flag 
					END IF 
				COMMIT WORK 
			END IF 

	END INPUT 
	CLOSE WINDOW p239 

	--WHENEVER ERROR stop 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	RETURN TRUE 
END FUNCTION 
############################################################
# FUNCTION setup_cheque_range_allocation()
############################################################

############################################################
# FUNCTION FUNCTION cheque_passwd()
############################################################
FUNCTION cheque_passwd() 
	DEFINE l_passwd_text1 CHAR(8) 
	DEFINE l_passwd_text2 CHAR(8)
	DEFINE l_user_desc1 CHAR(40) 
	DEFINE l_user_desc2 CHAR(40)
	DEFINE l_header_text_text CHAR(60) 
	DEFINE l_attempt_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	--WHENEVER ERROR CONTINUE 
	LET l_attempt_cnt = 0 
	OPEN WINDOW p510 with FORM "P510" 
	CALL winDecoration_p("P510") 

	CASE 
		WHEN get_kandoooption_feature_state('AP','CH') = 'Y' 
			LET l_header_text_text = "One Password IS required FOR Cheque Print" 
		WHEN get_kandoooption_feature_state('AP','CH') = 2 
			LET l_header_text_text = "Two Passwords are required FOR Cheque Print" 
	END CASE 
	DISPLAY l_header_text_text TO number_passwd 

	LET l_msgresp = kandoomsg("U",1001,"") 

   INPUT glob_user_text1,l_passwd_text1 WITHOUT DEFAULTS FROM user_text1,passwd_text1 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P3A","inp-user-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
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
				IF status = NOTFOUND THEN 
					#LET l_msgresp = kandoomsg("U",5001,"") 
					ERROR kandoomsg2("U",5001,"")
					NEXT FIELD user_text1 
				END IF 
			END IF 
			DISPLAY l_user_desc1 TO pr_user_desc1 

		AFTER FIELD passwd_text1 
			LET l_attempt_cnt = l_attempt_cnt + 1 
			IF l_attempt_cnt = 4 THEN 
				LET l_msgresp=kandoomsg("U",5003,"Cheque OR EFT Payment") 
				EXIT INPUT 
			ELSE 
				IF l_passwd_text1 IS NULL THEN 
					#LET l_msgresp = kandoomsg("U",9002,"") 
					ERROR kandoomsg2("U",9002,"")
					NEXT FIELD passwd_text1 
				ELSE 
					SELECT unique 1 FROM kandoouser 
					WHERE sign_on_code = glob_user_text1 
					AND password_text = l_passwd_text1 
					IF status = NOTFOUND THEN 
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
					IF status = NOTFOUND THEN 
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
					SELECT unique 1 FROM kandoouser 
					WHERE sign_on_code = glob_user_text1 
					AND password_text = l_passwd_text1 
					IF status = NOTFOUND THEN 
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
		EXIT PROGRAM 
	END IF 
	IF l_attempt_cnt = 4 THEN 
		CLOSE WINDOW p510 
		EXIT PROGRAM 
	END IF 
	IF get_kandoooption_feature_state('AP','CH') = 2 THEN 
		LET l_attempt_cnt = 0 

		INPUT glob_user_text2,l_passwd_text2 WITHOUT DEFAULTS FROM user_text2,passwd_text2 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","P3A","inp-user-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
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
						IF status = NOTFOUND THEN 
							#LET l_msgresp = kandoomsg("U",5001,"") 
							ERROR kandoomsg2("U",5001,"")
							NEXT FIELD user_text2 
						END IF 
					END IF 
					DISPLAY l_user_desc2 TO pr_user_desc2 

				END IF 
			AFTER FIELD passwd_text2 
				LET l_attempt_cnt = l_attempt_cnt + 1 
				IF l_attempt_cnt = 4 THEN 
					LET l_msgresp=kandoomsg("U",5003,"Cheque OR EFT Payment") 
					EXIT INPUT 
				ELSE 
					IF l_passwd_text2 IS NULL THEN 
						#LET l_msgresp = kandoomsg("U",9002,"") 
						ERROR kandoomsg2("U",9002,"")
						NEXT FIELD passwd_text2 
					ELSE 
						SELECT unique 1 FROM kandoouser 
						WHERE sign_on_code = glob_user_text2 
						AND password_text = l_passwd_text2 
						IF status = NOTFOUND THEN 
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
							IF status = NOTFOUND THEN 
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
						SELECT unique 1 FROM kandoouser 
						WHERE sign_on_code = glob_user_text2 
						AND password_text = l_passwd_text2 
						IF status = NOTFOUND THEN 
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
		EXIT PROGRAM 
	END IF 
	IF l_attempt_cnt = 4 THEN 
		CLOSE WINDOW p510 
		EXIT PROGRAM 
	END IF 
	CLOSE WINDOW p510 
END FUNCTION 
############################################################
# END FUNCTION cheque_passwd()
############################################################

############################################################
# FUNCTION run_custom_print(p_option)
############################################################
FUNCTION run_custom_print(p_option) 
	DEFINE p_option CHAR(3) 
	DEFINE l_arg1 STRING
	DEFINE l_arg2 STRING
	DEFINE l_arg3 STRING
			
	LET l_arg1 = "CYCLE_NUM=", trim(glob_rec_tenthead.cycle_num)
	LET l_arg2 = "PROG_CHILD=", "P3A" #????
	LET l_arg3 = "MODULE_CHILD=", "P3A" #????
	IF p_option = "CHQ" THEN 
		CALL run_prog("PX1",l_arg1,"","","") 
	ELSE 
		CALL run_prog("PX2",l_arg1,l_arg2,l_arg3,"") 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION run_custom_print(p_option)
############################################################

############################################################
# FUNCTION update_cheques_printed()
############################################################
FUNCTION update_cheques_printed() 
	DEFINE l_counter SMALLINT
	DEFINE r_return SMALLINT 

	LET r_return = TRUE 
	### There IS the possibility that the custom PRINT routine failed ###
	### AND has allowed the program TO continue.  Therefore we need TO###
	### check that all the tentpays records have been updated before  ###
	### we proceed with the numbering process.                        ###
	SELECT count(*) INTO l_counter FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND status_ind = "4" 
	AND pay_meth_ind = "1" 
	AND (page_num IS NOT NULL AND page_num != 0) 
	AND cheq_code = 0 
	IF l_counter = 0 OR l_counter IS NULL THEN 
		RETURN FALSE 
	END IF 

	MENU " Number Allocation " 

		BEFORE MENU 
			IF l_counter > 1500 THEN 
				HIDE option "Number" 
			END IF 

			CALL publish_toolbar("kandoo","P3A","menu-number_allocation-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Print Manager" 
			#COMMAND KEY("P") "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY("R") "Range" " Enter cheque numbers by range" 
			### Use the cheque range allocation ###
			IF setup_cheque_range_allocation() THEN 
				EXIT MENU 
			END IF 
		COMMAND KEY("N") "Number" " Enter individual cheque numbers" 
			### Use the individual cheque number allocation ###
			IF setup_individual_cheque_numbers() THEN 
				EXIT MENU 
			END IF 
		COMMAND KEY("E") "Exit" " Terminate Payment Processing" 
			#Note interrupt purposely left out
			LET r_return = FALSE 
			EXIT MENU 

	END MENU 
	RETURN r_return 
END FUNCTION 
############################################################
# END FUNCTION update_cheques_printed()
############################################################

############################################################
# FUNCTION check_status_of_job(p_job_status)
############################################################
FUNCTION check_status_of_job(p_job_status) 
	DEFINE p_job_status SMALLINT
	DEFINE l_arr_line ARRAY[7] OF CHAR(60) 
	DEFINE l_ind LIKE tentpays.source_ind 
	DEFINE l_text LIKE tentpays.source_text 
	DEFINE l_tax LIKE tentpays.withhold_tax_ind 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_total_pays DECIMAL(16,2)	
	DEFINE idx SMALLINT
	DEFINE r_return SMALLINT

	--WHENEVER ERROR CONTINUE 
	GOTO bypass3 
	LABEL recovery: 
	IF error_recover(glob_error_text,status) != "Y" THEN 
		RETURN p_job_status 
	END IF 
	LABEL bypass3: 
	--WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET glob_error_text = "Retrieving Tentative Control Information - P3A" 
		DECLARE c1_tenthead CURSOR FOR 
		SELECT * FROM tenthead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = glob_cycle_num 
		FOR UPDATE 
		LET glob_error_text = "Problem Retrieving Tentative Control Table(2) - P3A" 
		OPEN c1_tenthead 
		FETCH c1_tenthead INTO glob_rec_tenthead.* 
		CASE p_job_status 
			WHEN 0 
				DISPLAY glob_rec_tenthead.bank_code, glob_rec_tenthead.cheq_date 
				TO bank.bank_code, cheq_date 

				DECLARE c_countmeth_1 CURSOR FOR 
				SELECT unique source_ind, source_text, withhold_tax_ind FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND pay_meth_ind = "1" 
				GROUP BY 1,2,3 
				LET glob_cheque_count = 0 
				FOREACH c_countmeth_1 INTO l_ind, l_text, l_tax 
					LET glob_cheque_count = glob_cheque_count + 1 
				END FOREACH 
				DECLARE c_countmeth_3 CURSOR FOR 
				SELECT unique source_ind, source_text, withhold_tax_ind 
				FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND pay_meth_ind = "3" 
				GROUP BY 1,2,3 
				LET glob_eft_count = 0 
				FOREACH c_countmeth_3 INTO l_ind, l_text, l_tax 
					LET glob_eft_count = glob_eft_count + 1 
				END FOREACH 
				SELECT sum(vouch_amt) INTO l_total_pays FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				IF l_total_pays IS NULL THEN 
					LET l_total_pays = 0 
				END IF 
				IF l_total_pays <= 0 THEN 
					LET l_msgresp=kandoomsg("P","7072","") 
					#P7072 WARNING:.....NEGATIVE OR ZERO...
					LET r_return = 5 ### lets leave now 
					EXIT CASE 
				END IF 
				DISPLAY l_total_pays TO total_pay_amt 
				DISPLAY glob_cheque_count TO number_of_cheques 
				DISPLAY glob_eft_count TO number_of_efts 
				CASE glob_rec_tenthead.status_ind 
					WHEN 2 LET l_msgresp=kandoomsg("P","7054",glob_rec_tenthead.entry_code) 
						#P7054 - Tentative payments are currently...
						LET r_return = 9 
					WHEN 3 LET l_msgresp=kandoomsg("P","7055",glob_rec_tenthead.entry_code) 
						#P7055 - Tentative payments are currently...
						LET r_return = 9 
					OTHERWISE 
						### Could be a restart ###
						IF glob_rec_tenthead.cheq_date IS NOT NULL THEN 
							LET l_arr_line[1] = " " 
							LET l_arr_line[2] = "This IS a Restart of Automatic Payment Processing" 
							LET l_arr_line[3] = " Bank Code.......... ", glob_rec_tenthead.bank_code clipped 
							LET l_arr_line[4] = " Cheque Date........ ", 
							glob_rec_tenthead.cheq_date USING "dd/mm/yyyy" 
							LET l_arr_line[5] = " EFT Run Number..... ", 
							glob_rec_tenthead.eft_run_num USING "<<<<<<<<<<" 
							LET l_arr_line[6] = " Cheque Run Number.. ", 
							glob_rec_tenthead.cheq_run_num USING "<<<<<<<<<<" 
							LET l_arr_line[7] = " " 
							DISPLAY l_arr_line[1] TO sr_comments[1].comments 
							DISPLAY l_arr_line[2] TO sr_comments[2].comments 
							DISPLAY l_arr_line[3] TO sr_comments[3].comments 
							DISPLAY l_arr_line[4] TO sr_comments[4].comments 
							DISPLAY l_arr_line[5] TO sr_comments[5].comments 
							DISPLAY l_arr_line[6] TO sr_comments[6].comments 
							DISPLAY l_arr_line[7] TO sr_comments[7].comments 
							LET l_msgresp=kandoomsg("P","8023","Recommence") 
							IF l_msgresp matches "[Yy]" THEN 
								FOR idx = 1 TO 9 
									CLEAR sr_comments[idx].comments 
								END FOR 
								LET glob_error_text = 
								"Problem updating Tentative Control Status(1) - P3A" 
								LET r_return = 3 
								UPDATE tenthead 
								SET status_ind = 3, 
								status_datetime = current, 
								entry_code = glob_rec_kandoouser.sign_on_code 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cycle_num = glob_cycle_num 
								AND status_ind = 1 
							ELSE 
								LET r_return = 0 
							END IF 
						ELSE 
							LET glob_error_text = 
							"Problem updating Tentative Control Status(2) - P3A" 
							LET r_return = 1 
							UPDATE tenthead 
							SET status_ind = 3, 
							status_datetime = current, 
							entry_code = glob_rec_kandoouser.sign_on_code 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cycle_num = glob_cycle_num 
							AND status_ind = 1 
						END IF 
				END CASE 
			WHEN 1 LET r_return = glob_rec_tenthead.status_ind 
			WHEN 5 LET glob_error_text = "Problem updating Tent Ctrl Status(3) - P3A" 
				UPDATE tenthead 
				SET status_ind = 1, 
				status_datetime = current, 
				entry_code = glob_rec_kandoouser.sign_on_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				LET r_return = 5 ### represents a clean EXIT FROM the program 
			WHEN 9 LET glob_error_text = "Problem updating Tent Ctrl Status(4) - P3A" 
				UPDATE tenthead 
				SET status_ind = 1, 
				status_datetime = current, 
				entry_code = glob_rec_kandoouser.sign_on_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				LET r_return = 9 ### represents a CANCEL FROM the program ### 
			OTHERWISE 
				LET glob_error_text = "Problem updating Tent Ctrl Status(5) - P3A" 
				UPDATE tenthead 
				SET status_ind = (status_ind + 1), 
				status_datetime = current, 
				entry_code = glob_rec_kandoouser.sign_on_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND status_ind = p_job_status 
				LET r_return = p_job_status + 1 
		END CASE 
	COMMIT WORK 
	SELECT * INTO glob_rec_tenthead.* FROM tenthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	RETURN r_return 
END FUNCTION 
############################################################
# END FUNCTION check_status_of_job(p_job_status)
############################################################

############################################################
# FUNCTION create_eft_bank_file()
############################################################
FUNCTION create_eft_bank_file() 
	DEFINE l_rpt_idx_1 SMALLINT
	DEFINE l_rpt_idx_2 SMALLINT
	DEFINE l_rpt_idx_3 SMALLINT
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_pay_doc_num LIKE tentpays.pay_doc_num 
	DEFINE l_2_vendor RECORD LIKE vendor.*
	DEFINE l_mods_flag LIKE vendor.bkdetls_mod_flag 
	DEFINE l_bank_acct_code LIKE vouchpayee.bank_acct_code 
	DEFINE l_bic_code CHAR(6) 
	DEFINE l_msgresp LIKE language.yes_flag 

	DECLARE c6_tentpays CURSOR FOR 
	SELECT unique pay_doc_num FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND (pay_doc_num IS NOT NULL AND pay_doc_num != 0) 
	AND pay_meth_ind = "3" 
	AND status_ind = "4" 
	AND page_num = 1 
	ORDER BY 1 
	--WHENEVER ERROR CONTINUE 
	LET glob_rpt_note = "EFT Bank Listing - (BANK USE ONLY)" 
	IF glob_rec_bank.eft_rpt_ind !=0 THEN 
		LET glob_rpt_note2 = "Cleansing Report - (Menu PCL)" 
		#------------------------------------------------------------
		LET l_rpt_idx_1 = rpt_start(trim(getmoduleid())||".","pc9z_list","N/A",RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx_1 = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF
      # Cleansing REPORT 
		START REPORT pc9z_list TO rpt_get_report_file_with_path2(l_rpt_idx_1)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].report_width_num
		#------------------------------------------------------------
	END IF 
	IF glob_rec_banktype.eft_format_ind = 5 THEN 
		#------------------------------------------------------------
		LET l_rpt_idx_2 = rpt_start(trim(getmoduleid())||".","pc9f1_list","N/A",RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx_2 = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF
      # Bank file FOR eft's
		START REPORT pc9f1_list TO rpt_get_report_file_with_path2(l_rpt_idx_2) 
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].report_width_num
		#------------------------------------------------------------
	END IF 
	IF glob_rec_banktype.eft_format_ind = 1 THEN 
		#------------------------------------------------------------
		LET l_rpt_idx_3 = rpt_start(trim(getmoduleid())||".","pc9f2_list","N/A",RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx_3 = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF
      # Bank file FOR eft's
		START REPORT pc9f2_list TO rpt_get_report_file_with_path2(l_rpt_idx_3)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_3].report_width_num
		#------------------------------------------------------------
	END IF 
	GOTO bypass 
	LABEL recovery: 
	ROLLBACK WORK 
	RETURN FALSE 
	LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_msgresp=kandoomsg("U",1005,"") 
		#U1005 Updating database - please wait
		FOREACH c6_tentpays INTO l_pay_doc_num 
			LET glob_error_text = "Collecting Cheque Details FOR EFT Payment" 
			SELECT * INTO l_rec_cheque.* FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND doc_num = l_pay_doc_num 
			LET glob_error_text = "Declare Vendor Cursor FOR EFT Payment" 
			DECLARE c2_vendor CURSOR FOR 
			SELECT * FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = 
			(SELECT unique vend_code 
			FROM tentpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			AND pay_doc_num = l_pay_doc_num) 
			FOR UPDATE 
			LET glob_error_text = "Opening Vendor Table FOR EFT Payment" 
			OPEN c2_vendor 
			FETCH c2_vendor INTO l_2_vendor.* 
			IF l_rec_cheque.source_ind = "S" THEN #sundry voucher 
				SELECT bank_acct_code INTO l_bank_acct_code FROM vouchpayee 
				WHERE vend_code = l_2_vendor.vend_code 
				AND vouch_code = l_rec_cheque.source_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_bic_code = l_bank_acct_code[1,6] 
			ELSE 
				LET l_bic_code = l_2_vendor.bank_acct_code[1,6] 
			END IF 
			LET l_mods_flag = l_2_vendor.bkdetls_mod_flag 
			IF glob_rec_bank.eft_rpt_ind != 0 #ie. 1 OR 2 
			AND l_mods_flag = "Y" THEN #and new/modified 
				LET glob_error_text = "Updating Vendor Table FOR EFT Payment" 
				UPDATE vendor 
				SET bkdetls_mod_flag = "N" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_2_vendor.vend_code 
				LET glob_error_text = "Closing Vendor Table FOR EFT Payment" 
				CLOSE c2_vendor 
				#------------------------------------------------------------
				OUTPUT TO REPORT pc9z_list(l_rpt_idx_1,l_bic_code, l_rec_cheque.*,glob_rpt_note) 
				#------------------------------------------------------------
			END IF 
			IF glob_rec_banktype.eft_format_ind = 5 THEN 
				#------------------------------------------------------------
				OUTPUT TO REPORT pc9f1_list(l_rpt_idx_2,l_rec_cheque.*,l_mods_flag) 
				#------------------------------------------------------------
			END IF 
			IF glob_rec_banktype.eft_format_ind = 1 THEN 
				#------------------------------------------------------------
				OUTPUT TO REPORT pc9f2_list(l_rpt_idx_3,l_rec_cheque.*) 
				#------------------------------------------------------------
			END IF 
			### The idea here IS TO use the page_num field on tentpays TO ###
			### indicate that the eft tentative payment has been processed ###
			UPDATE tentpays 
			SET page_num = 2 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			AND pay_doc_num = l_pay_doc_num 
		END FOREACH 

		IF glob_rec_bank.eft_rpt_ind !=0 THEN 
			#------------------------------------------------------------
			FINISH REPORT pc9z_list
			CALL rpt_finish("pc9z_list")	
			#------------------------------------------------------------
			--FINISH REPORT pc9z_list 
		END IF 

		IF glob_rec_banktype.eft_format_ind = 5 THEN 
			#------------------------------------------------------------
			FINISH REPORT pc9f1_list
			CALL rpt_finish("pc9f1_list")	
			#------------------------------------------------------------
			--FINISH REPORT pc9f1_list 
		END IF 

		IF glob_rec_banktype.eft_format_ind = 1 THEN 
			#------------------------------------------------------------
			FINISH REPORT pc9f2_list
			CALL rpt_finish("pc9f2_list")	
			#------------------------------------------------------------
			--FINISH REPORT pc9f2_list 
		END IF 

	COMMIT WORK 
	--WHENEVER ERROR stop 

	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION create_eft_bank_file()
############################################################

############################################################
# FUNCTION remove_processed_payments()
############################################################
FUNCTION remove_processed_payments() 
	--WHENEVER ERROR CONTINUE 
	DELETE FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND status_ind = "4" 
	AND (page_num IS NOT NULL AND page_num != 0) 
	AND cheq_code IS NOT NULL 


	--WHENEVER ERROR stop 
	IF status <> 0 THEN 
		RETURN FALSE 
	END IF 
	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION remove_processed_payments()
############################################################

############################################################
# FUNCTION create_cheques_for_payments(p_rpt_idx)
############################################################
FUNCTION create_cheques_for_payments(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_accum_vouch_amt LIKE tentpays.vouch_amt 
	DEFINE l_accum_disc_amt LIKE tentpays.taken_disc_amt 
	DEFINE l_error_text CHAR(100) 
	DEFINE l_source_ind LIKE tentpays.source_ind 
	DEFINE l_source_text LIKE tentpays.source_text 
	DEFINE l_withhold_tax_ind LIKE tentpays.withhold_tax_ind 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_next_appl_num LIKE cheque.next_appl_num 
	DEFINE l_create_cheque SMALLINT
	DEFINE l_eft_report SMALLINT
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_vend_code LIKE vendor.vend_code 
	DEFINE l_pay_meth_ind LIKE cheque.pay_meth_ind 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_base_vouc_apply_amt LIKE voucherpays.apply_amt 
	DEFINE l_base_cheq_apply_amt LIKE voucherpays.apply_amt 
	DEFINE l_base_vouc_disc_amt LIKE voucherpays.disc_amt 
	DEFINE l_base_cheq_disc_amt LIKE voucherpays.disc_amt 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_call_status INTEGER
	DEFINE l_db_status INTEGER
	DEFINE l_contra_adjust SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_eft_report = TRUE 
	SELECT unique 1 FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND status_ind = "1" 
	AND pay_meth_ind = "3" 
	IF status != NOTFOUND THEN 
		IF glob_rec_bank.ext_file_ind != "1" THEN 
			LET glob_rpt_note = "EFT Payments Report" 
			#------------------------------------------------------------
			LET l_rpt_idx = rpt_start(trim(getmoduleid())||".","pc9a_list","N/A",RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF
         # Confirmation type REPORT
			START REPORT pc9a_list TO rpt_get_report_file_with_path2(l_rpt_idx)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
			#------------------------------------------------------------
			LET glob_rpt_note = glob_rpt_note clipped, " (Menu-PC9)" 
		END IF 
	ELSE 
		IF glob_rec_bank.ext_file_ind != "1" THEN 
			LET l_eft_report = FALSE 
		END IF 
	END IF 
	--WHENEVER ERROR CONTINUE 
	GOTO bypass1 
	LABEL recovery1: 
	IF error_recover(l_error_text,status) != "Y" THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT exception_report(p_rpt_idx,l_error_text)
		#---------------------------------------------------------
		RETURN FALSE 
	END IF 
	LABEL bypass1: 
	--WHENEVER ERROR GOTO recovery1 
	### IF this IS the first time through THEN we must collect the ###
	### selected banks next_eft_run_num AND/OR next_cheq_run_num   ###
	### VALUES WHERE needed.  These VALUES IF collected will UPDATE###
	### the selected bank RECORD AND the tenthead table.  Now, IF  ###
	### this IS NOT the first time through AND the tenthead table  ###
	### already has these VALUES SET THEN lets just walk on by AND ###
	### take the tenthead eft_run_num AND cheq_run_num as our      ###
	### references.                                                ###
	BEGIN WORK 
		DECLARE c4_tenthead CURSOR FOR 
		SELECT * FROM tenthead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = glob_cycle_num 
		FOR UPDATE 
		LET l_error_text = "Problems Opening Tentative Control Table (Chq)- P3A" 
		OPEN c4_tenthead 
		FETCH c4_tenthead INTO glob_rec_tenthead.* 
		DECLARE c_bank CURSOR FOR 
		SELECT * FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_tenthead.bank_code 
		FOR UPDATE 
		LET l_error_text = "Problems Opening Bank EFT Run Number - P3A" 
		OPEN c_bank 
		FETCH c_bank INTO glob_rec_bank.* 
		IF (glob_rec_tenthead.eft_run_num IS null) AND 
		(l_eft_report) THEN 
			LET l_error_text = "Problems Updating Tentative Control Table (EFT)- P3A" 
			LET glob_rec_tenthead.eft_run_num = glob_rec_bank.next_eft_run_num 
			UPDATE tenthead 
			SET eft_run_num = glob_rec_tenthead.eft_run_num 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			LET l_error_text = "Problems Updating Bank EFT Run Number - P3A" 
			UPDATE bank 
			SET next_eft_run_num = next_eft_run_num + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_tenthead.bank_code 
		END IF 
		IF glob_rec_tenthead.cheq_run_num IS NULL THEN 
			SELECT unique 1 FROM tentpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			AND status_ind = "1" 
			AND pay_meth_ind = "1" 
			IF status != NOTFOUND THEN 
				LET l_error_text = "Problems Updating Tentative Control Table (Chq)- P3A" 
				LET glob_rec_tenthead.cheq_run_num = glob_rec_bank.next_cheq_run_num 
				UPDATE tenthead 
				SET cheq_run_num = glob_rec_tenthead.cheq_run_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				LET l_error_text = "Problems Updating Bank Cheq Run Number - P3A" 
				UPDATE bank 
				SET next_cheq_run_num = next_cheq_run_num + 1 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_tenthead.bank_code 
			END IF 
		END IF 
	COMMIT WORK 
	LET l_msgresp=kandoomsg("U",1005,"") 
	#U1005 Updating database - please wait
	DECLARE c_tentpays CURSOR with HOLD FOR 
	SELECT unique pay_meth_ind, 
	source_ind, 
	source_text, 
	withhold_tax_ind 
	FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND status_ind = "1" 
	GROUP BY 1,2,3,4 
	ORDER BY 1,2,3,4 
	FOREACH c_tentpays INTO l_pay_meth_ind, 
		l_source_ind, 
		l_source_text, 
		l_withhold_tax_ind 
		--WHENEVER ERROR CONTINUE 
		GOTO bypass2 
		LABEL recovery2: 
		IF error_recover(l_error_text,status) != "Y" THEN 
			#---------------------------------------------------------
			OUTPUT TO REPORT exception_report(p_rpt_idx,l_error_text)
			#---------------------------------------------------------
			IF l_eft_report 
			AND glob_rec_bank.ext_file_ind != "1" THEN 
				#------------------------------------------------------------
				FINISH REPORT pc9a_list
				CALL rpt_finish("pc9a_list")	
				#------------------------------------------------------------
			END IF 
			RETURN FALSE 
		END IF 
		LABEL bypass2: 
		--WHENEVER ERROR GOTO recovery2 
		BEGIN WORK 
			### INITIALIZE the accumulation AND other variables ###
			LET l_accum_vouch_amt = 0 
			LET l_accum_disc_amt = 0 
			LET l_next_appl_num = 1 
			LET l_create_cheque = TRUE 
			DECLARE c2_tentpays CURSOR FOR 
			SELECT * FROM tentpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			AND source_ind = l_source_ind 
			AND source_text = l_source_text 
			AND pay_meth_ind = l_pay_meth_ind 
			AND withhold_tax_ind = l_withhold_tax_ind 
			AND status_ind = "1" 
			FOR UPDATE 
			FOREACH c2_tentpays INTO l_rec_tentpays.* 
				IF l_create_cheque THEN 
					DECLARE c_vendor CURSOR FOR 
					SELECT * FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_tentpays.vend_code 
					FOR UPDATE 
					LET l_error_text = "Problems retrieving FROM Vendor Table - P3A" 
					OPEN c_vendor 
					FETCH c_vendor INTO l_rec_vendor.* 
					IF status = NOTFOUND THEN 
						LET l_error_text = "Vendor ", l_rec_tentpays.vend_code clipped, 
						" IS NOT found in database." 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(p_rpt_idx,l_error_text)
						#---------------------------------------------------------
						CONTINUE FOREACH 
					END IF 
					INITIALIZE l_rec_cheque.* TO NULL 
					IF l_pay_meth_ind = "3" 
					OR glob_rec_bank.ext_file_ind = "1" THEN 
						DECLARE c3_bank CURSOR FOR 
						SELECT * FROM bank 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_code = glob_rec_tenthead.bank_code 
						FOR UPDATE 
						LET l_error_text = "Problems Retrieving Bank EFT Ref Num - P3A" 
						OPEN c3_bank 
						FETCH c3_bank INTO glob_rec_bank.* 
						LET l_rec_cheque.com2_text = "EFT Run Number ", 
						glob_rec_tenthead.eft_run_num 
						LET l_rec_cheque.cheq_code = glob_rec_bank.next_eft_ref_num 
						UPDATE bank 
						SET next_eft_ref_num = glob_rec_bank.next_eft_ref_num + 1 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_code = glob_rec_bank.bank_code 
						CLOSE c3_bank 
						LET l_rec_cheque.eft_run_num = glob_rec_tenthead.eft_run_num 
					ELSE 
						LET l_rec_cheque.cheq_code = 0 
						LET l_rec_cheque.eft_run_num = glob_rec_tenthead.cheq_run_num 
					END IF 
					LET l_rec_cheque.cheq_date = glob_cheq_date 
					LET l_rec_cheque.entry_code = glob_rec_kandoouser.sign_on_code 
					LET l_rec_cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_cheque.apply_amt = 0 
					LET l_rec_cheque.next_appl_num = l_next_appl_num 
					LET l_rec_cheque.pay_amt = 0 
					LET l_rec_cheque.disc_amt = 0 
					LET l_rec_cheque.withhold_tax_ind = l_rec_tentpays.withhold_tax_ind 
					LET l_rec_cheque.pay_meth_ind = l_rec_tentpays.pay_meth_ind 
					IF glob_rec_bank.ext_file_ind = "1" THEN 
						LET l_rec_cheque.pay_meth_ind = "3" 
					END IF 
					LET l_rec_cheque.source_ind = l_rec_tentpays.source_ind 
					LET l_rec_cheque.source_text = l_rec_tentpays.source_text 
					CALL get_whold_tax(glob_rec_kandoouser.cmpy_code, 
					l_rec_vendor.vend_code, 
					l_rec_vendor.type_code) 
					RETURNING l_rec_tentpays.withhold_tax_ind, 
					l_rec_cheque.tax_code, 
					l_rec_cheque.tax_per 
					LET l_rec_cheque.whtax_rep_ind = l_rec_tentpays.withhold_tax_ind 
					LET l_rec_cheque.pay_amt = 0 
					LET l_rec_cheque.vend_code = l_rec_vendor.vend_code 
					LET l_rec_cheque.bank_acct_code = glob_rec_bank.acct_code 
					LET l_rec_cheque.bank_code = glob_rec_bank.bank_code 
					LET l_rec_cheque.bank_currency_code = glob_rec_bank.currency_code 
					LET l_rec_cheque.currency_code = glob_rec_bank.currency_code 
					IF l_rec_cheque.currency_code != glob_rec_glparms.base_currency_code THEN 
						CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, 
						l_rec_cheque.currency_code, 
						l_rec_cheque.cheq_date, 
						"B") 
						RETURNING l_rec_cheque.conv_qty 
					ELSE 
						LET l_rec_cheque.conv_qty = 1 
					END IF 
					LET l_rec_cheque.entry_date = today 
					LET l_rec_cheque.com1_text = "Gen. Payments On ", today USING "dd/mm/yyyy" 
					IF l_rec_tentpays.source_ind = "S" THEN 
						SELECT name_text INTO l_rec_cheque.com2_text FROM vouchpayee 
						WHERE vend_code = l_rec_tentpays.vend_code 
						AND vouch_code = l_rec_tentpays.vouch_code 
						AND cmpy_code = cmpy_code 
					ELSE 
						LET l_rec_cheque.com2_text = NULL 
					END IF 
					LET l_rec_cheque.period_num = glob_period_num 
					LET l_rec_cheque.year_num = glob_year_num 
					LET l_rec_cheque.post_flag = "N" 
					LET l_rec_cheque.post_date = NULL 
					LET l_rec_cheque.recon_flag = "N" 
					LET l_rec_cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_cheque.apply_amt = 0 
					LET l_rec_cheque.doc_num = 0 
					LET l_error_text = "Problems Inserting Cheque Details - P3A" 
					INSERT INTO cheque VALUES (l_rec_cheque.*) 
					### the serial value created FOR the cheque AND cheque RECORD ###
					LET l_rec_cheque.doc_num = sqlca.sqlerrd[2] 
					LET l_create_cheque = FALSE 
					DECLARE c2_cheque CURSOR FOR 
					SELECT * FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND doc_num = l_rec_cheque.doc_num 
					FOR UPDATE 
					LET l_error_text = "Problems Retrieving Cheque Details - P3A" 
					OPEN c2_cheque 
					FETCH c2_cheque INTO l_rec_cheque.* 
				END IF 
				LET l_error_text = NULL 
				DECLARE c_voucher CURSOR FOR 
				SELECT * FROM voucher 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vouch_code = l_rec_tentpays.vouch_code 
				AND vend_code = l_rec_tentpays.vend_code 
				FOR UPDATE 
				LET l_error_text = "Problems Retrieving FROM Voucher Table - P3A" 
				OPEN c_voucher 
				FETCH c_voucher INTO l_rec_voucher.* 
				### Will the voucher amount TO pay overpay the current voucher ###
				### OR IS the voucher amount TO pay = 0.
				IF (l_rec_tentpays.vouch_amt > (l_rec_voucher.total_amt 
				- l_rec_voucher.paid_amt)) OR 
				(l_rec_tentpays.vouch_amt = 0) THEN 
					IF (l_rec_tentpays.vouch_amt = 0) THEN 
						LET l_error_text = "Payment Amount IS Zero on Voucher ", 
						l_rec_tentpays.vouch_code, " FOR ", 
						l_rec_tentpays.vend_code 
					ELSE 
						LET l_error_text = "Payment Amount will overpay Voucher ", 
						l_rec_tentpays.vouch_code, " FOR ", 
						l_rec_vendor.vend_code 
					END IF 
					#---------------------------------------------------------
					OUTPUT TO REPORT exception_report(p_rpt_idx,l_error_text)
					#---------------------------------------------------------
					LET l_rec_tentpays.vouch_amt = 0 
					LET l_rec_tentpays.taken_disc_amt = 0 
				ELSE 
					IF l_rec_voucher.taken_disc_amt IS NULL THEN 
						LET l_rec_voucher.taken_disc_amt = 0 
					END IF 
					IF l_rec_voucher.poss_disc_amt IS NULL THEN 
						LET l_rec_voucher.poss_disc_amt = 0 
					END IF 
					LET l_rec_voucher.taken_disc_amt = l_rec_voucher.taken_disc_amt 
					+ l_rec_tentpays.taken_disc_amt 
					LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt + l_rec_tentpays.vouch_amt 
					+ l_rec_tentpays.taken_disc_amt 
					LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num + 1 
					IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
						LET l_rec_voucher.paid_date = l_rec_cheque.cheq_date 
					END IF 
					UPDATE voucher 
					SET paid_amt = l_rec_voucher.paid_amt, 
					pay_seq_num = l_rec_voucher.pay_seq_num, 
					taken_disc_amt = l_rec_voucher.taken_disc_amt, 
					poss_disc_amt = l_rec_voucher.poss_disc_amt, 
					paid_date = l_rec_voucher.paid_date 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_voucher.vend_code 
					AND vouch_code = l_rec_voucher.vouch_code 
					LET l_rec_voucherpays.cmpy_code = l_rec_voucher.cmpy_code 
					LET l_rec_voucherpays.vend_code = l_rec_voucher.vend_code 
					LET l_rec_voucherpays.vouch_code = l_rec_voucher.vouch_code 
					LET l_rec_voucherpays.seq_num = 0 
					LET l_rec_voucherpays.pay_num = l_rec_cheque.cheq_code 
					LET l_rec_voucherpays.pay_meth_ind = l_rec_tentpays.pay_meth_ind 
					IF glob_rec_bank.ext_file_ind = "1" THEN 
						LET l_rec_voucherpays.pay_meth_ind = "3" 
					END IF 
					LET l_rec_voucherpays.apply_num = l_rec_voucher.pay_seq_num 
					LET l_rec_voucherpays.pay_type_code = "CH" 
					LET l_rec_voucherpays.pay_date = today 
					LET l_rec_voucherpays.apply_amt = l_rec_tentpays.vouch_amt 
					LET l_rec_voucherpays.disc_amt = l_rec_tentpays.taken_disc_amt 
					LET l_rec_voucherpays.withhold_tax_ind = l_rec_cheque.withhold_tax_ind 
					LET l_rec_voucherpays.tax_code = l_rec_cheque.tax_code 
					LET l_rec_voucherpays.bank_code = l_rec_cheque.bank_code 
					LET l_rec_voucherpays.rev_flag = NULL 
					LET l_rec_voucherpays.tax_per = l_rec_cheque.tax_per 
					LET l_rec_voucherpays.pay_doc_num = l_rec_cheque.doc_num 
					LET l_rec_voucherpays.remit_doc_num = l_rec_cheque.doc_num 
					LET l_error_text = "Error in Inserting Voucher Payment Applications - P3A" 
					INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 
					IF l_rec_voucher.conv_qty IS NOT NULL THEN 
						IF l_rec_voucher.conv_qty != 0 THEN 
							LET l_base_vouc_apply_amt = l_rec_voucherpays.apply_amt / 
							l_rec_voucher.conv_qty 
							LET l_base_cheq_apply_amt = l_rec_voucherpays.apply_amt / 
							l_rec_cheque.conv_qty 
							LET l_base_vouc_disc_amt = l_rec_voucherpays.disc_amt / 
							l_rec_voucher.conv_qty 
							LET l_base_cheq_disc_amt = l_rec_voucherpays.disc_amt / 
							l_rec_cheque.conv_qty 
						END IF 
					END IF 
					LET l_rec_exchangevar.exchangevar_amt = l_base_cheq_apply_amt - 
					l_base_vouc_apply_amt 
					IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
						LET l_rec_exchangevar.cmpy_code = l_rec_cheque.cmpy_code 
						LET l_rec_exchangevar.year_num = l_rec_cheque.year_num 
						LET l_rec_exchangevar.period_num = l_rec_cheque.period_num 
						LET l_rec_exchangevar.source_ind = "P" 
						LET l_rec_exchangevar.tran_date = l_rec_cheque.cheq_date 
						LET l_rec_exchangevar.ref_code = l_rec_cheque.vend_code 
						LET l_rec_exchangevar.tran_type1_ind = "VO" 
						LET l_rec_exchangevar.ref1_num = l_rec_voucher.vouch_code 
						LET l_rec_exchangevar.tran_type2_ind = "CH" 
						LET l_rec_exchangevar.ref2_num = l_rec_cheque.doc_num 
						LET l_rec_exchangevar.currency_code = l_rec_voucher.currency_code 
						LET l_rec_exchangevar.posted_flag = "N" 
						LET l_error_text = "Problems Inserting Exchange Variance - P3A" 
						INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
					END IF 
					LET l_rec_exchangevar.exchangevar_amt = l_base_cheq_disc_amt - 
					l_base_vouc_disc_amt 
					IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
						LET l_error_text = "Problems Inserting Exchange Variance (2) - P3A" 
						INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
					END IF 
					LET l_accum_vouch_amt = l_accum_vouch_amt 
					+ l_rec_tentpays.vouch_amt 
					LET l_accum_disc_amt = l_accum_disc_amt 
					+ l_rec_tentpays.taken_disc_amt 
					LET l_next_appl_num = l_next_appl_num + 1 
				END IF 
				LET l_error_text = "Problems Updating Tenatative Payments Status - P3A" 
				UPDATE tentpays 
				SET status_ind = "3", 
				vouch_amt = l_rec_tentpays.vouch_amt, 
				taken_disc_amt = l_rec_tentpays.taken_disc_amt, 
				cheq_code = l_rec_cheque.cheq_code, 
				pay_doc_num = l_rec_cheque.doc_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND pay_meth_ind = l_pay_meth_ind 
				AND source_ind = l_source_ind 
				AND source_text = l_source_text 
				AND withhold_tax_ind = l_withhold_tax_ind 
				AND vouch_code = l_rec_tentpays.vouch_code 
			END FOREACH 
			### IF the payment amount IS zero THEN rollback all ###
			IF (l_accum_vouch_amt + l_accum_disc_amt) <= 0 THEN 
				ROLLBACK WORK 
				LET l_error_text = "Accumulated Payment Amount IS negative FOR Vendor ", 
				l_source_text 
				#---------------------------------------------------------
				OUTPUT TO REPORT exception_report(p_rpt_idx,l_error_text)
				#---------------------------------------------------------
				CONTINUE FOREACH 
			ELSE 
				IF (l_accum_vouch_amt > l_rec_vendor.bal_amt) THEN 
					ROLLBACK WORK 
					LET l_error_text = "Voucher Payment/s will overpay the Vendor ", 
					l_source_text 
					#---------------------------------------------------------
					OUTPUT TO REPORT exception_report(p_rpt_idx,l_error_text)
					#---------------------------------------------------------
					CONTINUE FOREACH 
				END IF 
			END IF 
			LET l_rec_cheque.pay_amt = l_accum_vouch_amt 
			LET l_rec_cheque.disc_amt = l_accum_disc_amt 
			LET l_rec_cheque.apply_amt = l_accum_vouch_amt 
			LET l_rec_cheque.next_appl_num = l_next_appl_num + 1 
			LET l_rec_cheque.contra_amt = 0 
			IF l_rec_cheque.cheq_date > l_rec_vendor.last_payment_date OR 
			l_rec_vendor.last_payment_date IS NULL 
			THEN 
				LET l_rec_vendor.last_payment_date = l_rec_cheque.cheq_date 
			END IF 
			CALL wtaxcalc(l_rec_cheque.pay_amt, 
			l_rec_cheque.tax_per, 
			l_rec_cheque.withhold_tax_ind, 
			glob_rec_kandoouser.cmpy_code) 
			RETURNING l_rec_cheque.net_pay_amt, 
			l_rec_cheque.tax_amt 
			#
			#  Check FOR a contra balance in the AR ledger AND adjust the net
			#  payment amount accordingly, AFTER creating the balancing AR
			#  transactions.
			#  Rules FOR applying the contra amount are:
			#     0 - no contra adjustments allowed
			#     1 - adjust taxed payments only
			#     2 - adjust non-taxed payments only
			#
			CASE 
				WHEN (l_rec_vendor.contra_meth_ind = "1" AND 
					l_rec_cheque.withhold_tax_ind <> "0") 
					LET l_contra_adjust = TRUE 
				WHEN (l_rec_vendor.contra_meth_ind = "2" AND 
					l_rec_cheque.withhold_tax_ind = "0") 
					LET l_contra_adjust = TRUE 
				OTHERWISE 
					LET l_contra_adjust = FALSE 
			END CASE 
			IF l_contra_adjust THEN 
				DECLARE c_customer CURSOR FOR 
				SELECT bal_amt FROM customer 
				WHERE cust_code = l_rec_vendor.contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 
				OPEN c_customer 
				FETCH c_customer INTO l_rec_cheque.contra_amt 
				IF status = NOTFOUND THEN 
					ROLLBACK WORK 
					LET l_error_text = 
					"Contra Customer ",l_rec_vendor.contra_cust_code, 
					" NOT found FOR Vendor ", l_rec_vendor.vend_code 
					#---------------------------------------------------------
					OUTPUT TO REPORT exception_report(p_rpt_idx,l_error_text)
					#---------------------------------------------------------
					CONTINUE FOREACH 
				ELSE 
					LET l_call_status = 0 
					CASE 
						WHEN (l_rec_cheque.contra_amt < 0) 
							CALL contra_invoice(glob_rec_kandoouser.cmpy_code, 
							l_rec_cheque.entry_code, 
							l_rec_vendor.contra_cust_code, 
							l_rec_cheque.cheq_date, 
							l_rec_cheque.year_num, 
							l_rec_cheque.period_num, 
							glob_rec_glparms.clear_acct_code, 
							l_rec_cheque.contra_amt) 
							RETURNING l_call_status, 
							l_db_status, 
							l_error_text, 
							l_rec_cheque.contra_trans_num 
						WHEN (l_rec_cheque.contra_amt > 0) 
							CALL contra_credit(glob_rec_kandoouser.cmpy_code, 
							l_rec_cheque.entry_code, 
							l_rec_vendor.contra_cust_code, 
							l_rec_cheque.cheq_date, 
							l_rec_cheque.year_num, 
							l_rec_cheque.period_num, 
							glob_rec_glparms.clear_acct_code, 
							l_rec_cheque.contra_amt) 
							RETURNING l_call_status, 
							l_db_status, 
							l_error_text, 
							l_rec_cheque.contra_trans_num 
					END CASE 
					IF l_call_status = -2 THEN 
						LET status = l_db_status 
						GOTO recovery2 
					END IF 
					IF l_call_status = -1 THEN 
						ROLLBACK WORK 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(p_rpt_idx,l_error_text)
						#---------------------------------------------------------
						CONTINUE FOREACH 
					END IF 
					LET l_rec_cheque.net_pay_amt = 
					l_rec_cheque.net_pay_amt - l_rec_cheque.contra_amt 
					IF l_rec_cheque.net_pay_amt <= 0 THEN 
						ROLLBACK WORK 
						LET l_error_text = "Contra entry greater than ", 
						"payment amount FOR Vendor ", l_rec_vendor.vend_code 
						#---------------------------------------------------------
						OUTPUT TO REPORT exception_report(p_rpt_idx,l_error_text)
						#---------------------------------------------------------
						CONTINUE FOREACH 
					END IF 
				END IF 
			END IF 
			LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_rec_cheque.net_pay_amt 
			LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - l_rec_cheque.net_pay_amt 
			LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
			IF l_rec_cheque.pay_meth_ind = "3" THEN 
				LET l_rec_apaudit.tran_text = "Auto EFT Amt" 
				LET l_rec_apaudit.trantype_ind = "CH" 
				LET l_rec_apaudit.source_num = l_rec_cheque.cheq_code 
			ELSE 
				LET l_rec_apaudit.tran_text = "Auto Cheque Amt" 
				LET l_rec_apaudit.trantype_ind = "PP" 
				LET l_rec_apaudit.source_num = l_rec_cheque.doc_num 
			END IF 
			LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_apaudit.tran_date = l_rec_cheque.cheq_date 
			LET l_rec_apaudit.vend_code = l_rec_cheque.vend_code 
			LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
			LET l_rec_apaudit.year_num = glob_year_num 
			LET l_rec_apaudit.period_num = glob_period_num 
			LET l_rec_apaudit.tran_amt = 0 - l_rec_cheque.net_pay_amt 
			LET l_rec_apaudit.entry_code = l_rec_cheque.entry_code 
			LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
			LET l_rec_apaudit.currency_code = l_rec_cheque.currency_code 
			LET l_rec_apaudit.conv_qty = l_rec_cheque.conv_qty 
			LET l_rec_apaudit.entry_date = today 
			LET l_error_text = "Problems Inserting Audit Trail - P3A" 
			INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
			IF l_accum_disc_amt > 0 THEN 
				LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
				LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - l_accum_disc_amt 
				LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_accum_disc_amt 
				LET l_rec_apaudit.cmpy_code = l_rec_vendor.cmpy_code 
				LET l_rec_apaudit.tran_date = today 
				LET l_rec_apaudit.vend_code = l_rec_voucher.vend_code 
				LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
				IF l_rec_cheque.pay_meth_ind = "3" THEN 
					LET l_rec_apaudit.trantype_ind = "CH" 
					LET l_rec_apaudit.source_num = l_rec_cheque.cheq_code 
				ELSE 
					LET l_rec_apaudit.trantype_ind = "PP" 
					LET l_rec_apaudit.source_num = l_rec_cheque.doc_num 
				END IF 
				LET l_rec_apaudit.tran_text = "Apply Discount" 
				LET l_rec_apaudit.tran_amt = 0 - l_accum_disc_amt 
				LET l_rec_apaudit.year_num = glob_year_num 
				LET l_rec_apaudit.period_num = glob_period_num 
				LET l_rec_apaudit.entry_code = l_rec_cheque.entry_code 
				LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
				LET l_rec_apaudit.currency_code = l_rec_cheque.currency_code 
				LET l_rec_apaudit.conv_qty = l_rec_cheque.conv_qty 
				LET l_rec_apaudit.entry_date = today 
				LET l_error_text = "Problems Inserting Audit Trail(2) - P3A" 
				INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
			END IF 
			IF l_rec_cheque.tax_amt != 0 THEN 
				LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_rec_cheque.tax_amt 
				LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - l_rec_cheque.tax_amt 
				LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
				LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
				IF l_rec_cheque.pay_meth_ind = "1" THEN 
					LET l_rec_apaudit.tran_text = "Auto Cheque Tax" 
				ELSE 
					LET l_rec_apaudit.tran_text = "EFT Cheque Tax" 
				END IF 
				LET l_rec_apaudit.tran_amt = 0 - l_rec_cheque.tax_amt 
				LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
				LET l_error_text = "Problems Inserting Audit Trail(3) - P3A" 
				INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
			END IF 
			IF l_rec_cheque.contra_amt != 0 THEN 
				LET l_rec_vendor.bal_amt = 
				l_rec_vendor.bal_amt - l_rec_cheque.contra_amt 
				LET l_rec_vendor.curr_amt = 
				l_rec_vendor.curr_amt - l_rec_cheque.contra_amt 
				LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
				LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
				IF l_rec_cheque.contra_amt > 0 THEN 
					LET l_rec_apaudit.tran_text = "Contra Credit" 
				ELSE 
					LET l_rec_apaudit.tran_text = "Contra Invoice" 
				END IF 
				LET l_rec_apaudit.tran_amt = 0 - l_rec_cheque.contra_amt 
				LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
				LET l_error_text = "Problems Inserting Audit Trail(4) - P3A" 
				INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
			END IF 
			LET l_error_text = "Problems Updating Vendor Details - P3A" 
			UPDATE vendor 
			SET * = l_rec_vendor.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = l_rec_cheque.vend_code 
			DECLARE c_apparms CURSOR FOR 
			SELECT * FROM apparms 
			WHERE cmpy_code = l_rec_cheque.cmpy_code 
			LET l_error_text = "Problems Updating AP Parameters - P3A" 
			OPEN c_apparms 
			FETCH c_apparms INTO glob_rec_apparms.* 
			UPDATE apparms 
			SET last_chq_prnt_date = l_rec_cheque.cheq_date 
			WHERE cmpy_code = l_rec_cheque.cmpy_code 
			LET l_error_text = "Problems Updating Cheque Details - P3A" 
			UPDATE cheque 
			SET * = l_rec_cheque.* 
			WHERE doc_num = l_rec_cheque.doc_num 
			IF l_pay_meth_ind = "3" 
			AND glob_rec_bank.ext_file_ind != "1" THEN 
				#---------------------------------------------------------
				OUTPUT TO REPORT pc9a_list(l_rpt_idx,l_rec_cheque.*,l_rec_vendor.*,glob_rpt_note) 
				#---------------------------------------------------------
			END IF 
		COMMIT WORK 
	END FOREACH 
	IF l_eft_report 
	AND glob_rec_bank.ext_file_ind != "1" THEN 
		#------------------------------------------------------------
		FINISH REPORT pc9a_list
		CALL rpt_finish("pc9a_list")	
		#------------------------------------------------------------
	END IF 

	--WHENEVER ERROR stop 
	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION create_cheques_for_payments(p_rpt_idx)
############################################################

############################################################
# FUNCTION collect_unreported_applications(p_rpt_idx)
############################################################
FUNCTION collect_unreported_applications(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT
	DEFINE l_pay_doc_num LIKE tentpays.pay_doc_num 
	DEFINE l_pay_meth_ind LIKE tentpays.pay_meth_ind 
	DEFINE l_source_ind LIKE tentpays.source_ind 
	DEFINE l_source_text LIKE tentpays.source_text 
	DEFINE l_vend_code LIKE tentpays.vend_code 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_remit_flag SMALLINT 

	### Collect the VoucherPays records that are NOT in the tentpays ###
	### table AND need TO be shown in this remittance as they are:   ###
	### 1. Voucher being paid (partly paid) as part of this payment  ###
	### 2. Not appeared on remittance before AND IS fully paid. Paid ###
	###    by Debit Note OR Cheque.                                  ###
	###                                                              ###
	--WHENEVER ERROR CONTINUE 
	DECLARE c3_tentpays CURSOR with HOLD FOR 
	SELECT unique pay_doc_num, 
	pay_meth_ind, 
	vend_code, 
	source_ind, 
	source_text FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND status_ind = "3" 
	ORDER BY 1 
	FOREACH c3_tentpays INTO l_pay_doc_num, 
		l_pay_meth_ind, 
		l_vend_code, 
		l_source_ind, 
		l_source_text 
		GOTO bypass3 
		LABEL recovery3: 
		IF error_recover(glob_error_text,status) != "Y" THEN 
			#---------------------------------------------------------
			OUTPUT TO REPORT exception_report(p_rpt_idx,glob_error_text)
			#---------------------------------------------------------
			RETURN FALSE 
		END IF 
		LABEL bypass3: 
		--WHENEVER ERROR GOTO recovery3 
		BEGIN WORK 
			DECLARE c2_voucherpays CURSOR FOR 
			SELECT * FROM voucherpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND (rev_flag != "Y" OR rev_flag IS null) 
			AND remit_doc_num = 0 
			AND vend_code = l_vend_code 
			FOR UPDATE 
			FOREACH c2_voucherpays INTO l_rec_voucherpays.* 
				SELECT unique 1 FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND vend_code = l_rec_voucherpays.vend_code 
				AND vouch_code = l_rec_voucherpays.vouch_code 
				IF status = NOTFOUND THEN 
					### Do NOT include vouchers that are NOT part of this payment
					### unless they are fully paid AND are either NOT a refund TO
					### customer OR are a refund TO the same customer (ie. source text)
					### AND the voucher IS NOT a Sundry Voucher.
					INITIALIZE l_rec_tentpays.* TO NULL 
					SELECT * INTO l_rec_voucher.* FROM voucher 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vouch_code = l_rec_voucherpays.vouch_code 
					AND total_amt = paid_amt 
					AND source_ind != "S" 
					AND ((source_ind IS NULL OR source_ind != '8') OR 
					(source_ind = '8' AND source_text = l_source_text)) 
					IF status = NOTFOUND THEN 
						LET l_remit_flag = FALSE 
					ELSE 
						LET l_remit_flag = TRUE 
						LET l_rec_tentpays.cycle_num = glob_cycle_num 
						LET l_rec_tentpays.taken_disc_amt = 0 
						LET l_rec_tentpays.vouch_amt = 0 
						LET l_rec_tentpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_tentpays.vend_code = l_rec_voucher.vend_code 
						LET l_rec_tentpays.vouch_code = l_rec_voucher.vouch_code 
						LET l_rec_tentpays.due_date = l_rec_voucher.due_date 
						LET l_rec_tentpays.disc_date = l_rec_voucher.disc_date 
						LET l_rec_tentpays.withhold_tax_ind = l_rec_voucher.withhold_tax_ind 
						LET l_rec_tentpays.tax_code = l_rec_voucherpays.tax_code 
						LET l_rec_tentpays.tax_per = l_rec_voucherpays.tax_per 
						LET l_rec_tentpays.pay_meth_ind = l_pay_meth_ind 
						LET l_rec_tentpays.source_ind = l_source_ind 
						LET l_rec_tentpays.source_text = l_source_text 
						LET l_rec_tentpays.status_ind = "4" 
						LET l_rec_tentpays.pay_doc_num = l_pay_doc_num 
						LET l_rec_tentpays.page_num = 0 
						LET l_rec_tentpays.vouch_date = l_rec_voucher.vouch_date 
						LET l_rec_tentpays.inv_text = l_rec_voucher.inv_text 
						LET l_rec_tentpays.total_amt = l_rec_voucher.total_amt 
						LET l_rec_tentpays.cheq_code = 0 
						LET glob_error_text = "Problems Inserting INTO Tentative Payments - P3A" 
						INSERT INTO tentpays VALUES (l_rec_tentpays.*) 
					END IF 
				ELSE 
					LET l_remit_flag = TRUE 
				END IF 
				LET glob_error_text = "Problems Updating Voucher Application - P3A" 
				IF l_remit_flag THEN 
					UPDATE voucherpays 
					SET remit_doc_num = l_pay_doc_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vouch_code = l_rec_voucherpays.vouch_code 
					AND vend_code = l_rec_voucherpays.vend_code 
					AND (rev_flag != "Y" OR rev_flag IS null) 
					AND remit_doc_num = 0 
				END IF 
			END FOREACH 
			LET glob_error_text = "Problems Updating Tentative Payments - P3A" 
			UPDATE tentpays 
			SET status_ind = "4" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = glob_cycle_num 
			AND pay_doc_num = l_pay_doc_num 
		COMMIT WORK 
	END FOREACH 
	--WHENEVER ERROR stop 
	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION collect_unreported_applications(p_rpt_idx)
############################################################

############################################################
# FUNCTION setup_individual_cheque_numbers()
############################################################
FUNCTION setup_individual_cheque_numbers() 
	DEFINE l_next SMALLINT
	DEFINE l_save_cheq LIKE tentpays.cheq_code
	DEFINE l_sum_vouch_amt LIKE tentpays.vouch_amt 
	DEFINE l_save_doc_id INTEGER 
	DEFINE l_prev_page_no INTEGER
	DEFINE l_curr_page_no INTEGER 
	DEFINE l_error_text CHAR(40) 
	DEFINE l_arr_doc_num ARRAY[1500] OF LIKE tentpays.pay_doc_num 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_indcheque RECORD LIKE cheque.* 
	DEFINE l_rec_indvouchpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_indapaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_indexchvar RECORD LIKE exchangevar.* 
	DEFINE l_arr_tentpays ARRAY[1500] OF 
	RECORD 
		cheq_code LIKE tentpays.cheq_code, 
		vend_code LIKE tentpays.vend_code, 
		source_ind LIKE tentpays.source_ind, 
		source_text LIKE tentpays.source_text, 
		vouch_amt LIKE tentpays.vouch_amt, 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE lr_idx, ls_idx, idx, scrn SMALLINT
	DEFINE i,j SMALLINT

	--WHENEVER ERROR CONTINUE 
	DECLARE c5_tentpays CURSOR FOR 
	SELECT unique pay_doc_num, 
	source_ind, 
	source_text, 
	withhold_tax_ind, 
	vend_code, 
	sum(vouch_amt) 
	FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	AND status_ind = "4" 
	AND vouch_amt != 0 
	AND pay_meth_ind = "1" 
	GROUP BY 1,2,3,4,5 
	ORDER BY 1,2,3,4 
	LET lr_idx = 0 
	FOREACH c5_tentpays INTO l_rec_tentpays.pay_doc_num, 
		l_rec_tentpays.source_ind, 
		l_rec_tentpays.source_text, 
		l_rec_tentpays.withhold_tax_ind, 
		l_rec_tentpays.vend_code, 
		l_sum_vouch_amt 
		LET lr_idx = lr_idx + 1 
		LET l_arr_doc_num[lr_idx] = l_rec_tentpays.pay_doc_num 
		INITIALIZE l_arr_tentpays[lr_idx].* TO NULL 
		LET l_arr_tentpays[lr_idx].vend_code = l_rec_tentpays.vend_code 
		LET l_arr_tentpays[lr_idx].source_ind = l_rec_tentpays.source_ind 
		LET l_arr_tentpays[lr_idx].source_text = l_rec_tentpays.source_text 
		LET l_arr_tentpays[lr_idx].vouch_amt = l_sum_vouch_amt 
		LET l_arr_tentpays[lr_idx].withhold_tax_ind = l_rec_tentpays.withhold_tax_ind 
	END FOREACH 
	OPEN WINDOW p235 with FORM "P235" 
	CALL windecoration_p("P235") 

	CALL set_count(lr_idx) 
	LET l_msgresp=kandoomsg("P",1077,"") 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	#1049 Enter Cheque Numbers; OK TO Continue
	INPUT ARRAY l_arr_tentpays WITHOUT DEFAULTS FROM sr_tentpays.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P3A","inp-arr-tentpays-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		AFTER ROW 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF (idx+1 > lr_idx) THEN 
					#LET l_msgresp=kandoomsg("U",9001,"") 
					#U9001 "There no more rows in the direction you are going"
					ERROR kandoomsg2("U",9001,"")
					NEXT FIELD cheq_code 
				ELSE 
					IF l_arr_tentpays[idx+1].vend_code IS NULL THEN 
						#LET l_msgresp=kandoomsg("U",9001,"") 
						#U9001 "There no more rows in the direction you are going"
						ERROR kandoomsg2("U",9001,"")
						NEXT FIELD cheq_code 
					END IF 
				END IF 
			ELSE 
				IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
					IF (idx+10 > lr_idx) THEN 
						#LET l_msgresp=kandoomsg("U",9001,"") 
						#U9001 "There no more rows in the direction you are going"
						ERROR kandoomsg2("U",9001,"")
						NEXT FIELD cheq_code 
					ELSE 
						IF l_arr_tentpays[idx+10].vend_code IS NULL THEN 
							#LET l_msgresp=kandoomsg("U",9001,"") 
							#U9001 "There no more rows in the direction you are going"
							ERROR kandoomsg2("U",9001,"")
							NEXT FIELD cheq_code 
						END IF 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD cheq_code 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF l_arr_tentpays[idx].cheq_code IS NOT NULL THEN 
				LET l_msgresp=kandoomsg("P",1078,"") 
				#1050 Edit Cheque Numbers;  OK TO Continue"
			END IF 
		AFTER FIELD cheq_code 
			IF (l_arr_tentpays[idx].cheq_code IS null) OR 
			(l_arr_tentpays[idx].cheq_code <= 0) THEN 
				#LET l_msgresp=kandoomsg("P",9009,"") 
				#9009 A Valid Cheque Number Must be Entered"
				ERROR kandoomsg2("P",9009,"")
				NEXT FIELD cheq_code 
			END IF 
			IF l_arr_tentpays[idx].vend_code IS NULL THEN 
				#No Voucher on this Line"
				NEXT FIELD cheq_code 
			END IF 
			SELECT unique 1 FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheq_code = l_arr_tentpays[idx].cheq_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "1" 
			IF status != NOTFOUND THEN 
				#LET l_msgresp=kandoomsg("P",9010,l_arr_tentpays[idx].cheq_code) 
				#9010 Cheque Number n already issued
				ERROR kandoomsg2("P",9010,l_arr_tentpays[idx].cheq_code)
				NEXT FIELD cheq_code 
			ELSE 
				FOR j = 1 TO (idx - 1) 
					IF l_arr_tentpays[idx].cheq_code = l_arr_tentpays[j].cheq_code THEN 
						#LET l_msgresp=kandoomsg("P",9010,l_arr_tentpays[idx].cheq_code) 
						#9010 Cheque Number n already issued
						ERROR kandoomsg2("P",9010,l_arr_tentpays[idx].cheq_code)
						NEXT FIELD cheq_code 
					END IF 
				END FOR 
			END IF 
			IF fgl_lastkey() = fgl_keyval("prevpage") OR 
			fgl_lastkey() = fgl_keyval("up") OR 
			fgl_lastkey() = fgl_keyval("right") 
			THEN 
			ELSE 
				IF fgl_lastkey() != fgl_keyval("accept") AND 
				fgl_lastkey() != fgl_keyval("down") AND 
				fgl_lastkey() != fgl_keyval("nextpage") THEN 
					NEXT FIELD vend_code 
				END IF 
			END IF 
		BEFORE FIELD vend_code 
			LET l_save_doc_id = l_arr_doc_num[idx] 
			LET l_save_cheq = l_arr_tentpays[idx].cheq_code 
			### Each logical doc_id cannot be split over different cheq. no's ###
			LET ls_idx = idx 
			### Find first entry in ARRAY with current doc_id ###
			FOR i = ( idx - 1 ) TO 1 step -1 
				IF l_arr_doc_num[i] != l_save_doc_id THEN 
					EXIT FOR 
				END IF 
			END FOR 
			LET idx = i + 1 
			### N.B. scrn may be negative ( handled by scrn test IF scrn > 0 ) ###
			LET scrn = scrn - ( ls_idx - idx ) 
			WHILE idx <= lr_idx 
				IF l_arr_tentpays[idx].vend_code IS NOT NULL THEN 
					IF l_arr_doc_num[idx] != l_save_doc_id THEN 
						SELECT max(page_num) INTO l_prev_page_no FROM tentpays 
						WHERE pay_doc_num = l_save_doc_id 
						IF sqlca.sqlcode = NOTFOUND THEN 
							LET l_prev_page_no = 0 
						END IF 
						SELECT min(page_num) INTO l_curr_page_no FROM tentpays 
						WHERE pay_doc_num = l_arr_doc_num[idx] 
						LET l_arr_tentpays[idx].cheq_code = l_save_cheq + (l_curr_page_no 
						- l_prev_page_no) 
					ELSE 
						LET l_arr_tentpays[idx].cheq_code = l_save_cheq 
					END IF 
					LET l_save_doc_id = l_arr_doc_num[idx] 
					LET l_save_cheq = l_arr_tentpays[idx].cheq_code 
					IF scrn > 0 AND scrn < 11 THEN 
						DISPLAY l_arr_tentpays[idx].cheq_code 
						TO sr_tentpays[scrn].cheq_code 

					END IF 
				END IF 
				LET idx = idx + 1 
				LET scrn = scrn + 1 
			END WHILE 
			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF (ls_idx+10) <= 1500 THEN 
					IF l_arr_tentpays[ls_idx+10].vend_code IS NULL THEN 
						#LET l_msgresp=kandoomsg("U",9001,"") 
						#U9001 No more rows in the direction...
						ERROR kandoomsg2("U",9001,"")
						NEXT FIELD cheq_code 
					END IF 
				ELSE 
					#LET l_msgresp=kandoomsg("U",9001,"") 
					#U9001 No more rows in the direction...
					ERROR kandoomsg2("U",9001,"")
					NEXT FIELD cheq_code 
				END IF 
				NEXT FIELD NEXT 
			ELSE 
				IF fgl_lastkey() = fgl_keyval("RETURN") OR 
				fgl_lastkey() = fgl_keyval("right") OR 
				fgl_lastkey() = fgl_keyval("tab") OR 
				fgl_lastkey() = fgl_keyval("down") THEN 
					IF l_arr_tentpays[ls_idx+1].vend_code IS NULL THEN 
						#LET l_msgresp=kandoomsg("U",9001,"")
						#U9001 "There no more rows in the direction you are going"
						ERROR kandoomsg2("U",9001,"")
						NEXT FIELD cheq_code 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				ELSE 
					NEXT FIELD cheq_code 
				END IF 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			FOR i = 1 TO lr_idx 
				### Only IF current cheque no. IS different TO next one,
				### THEN SELECT FROM cheque table. This saves on DB I/O.
				IF l_arr_tentpays[i].cheq_code != l_arr_tentpays[i+1].cheq_code 
				OR l_arr_tentpays[i+1].cheq_code IS NULL THEN 
					SELECT unique 1 FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cheq_code = l_arr_tentpays[i].cheq_code 
					AND bank_code = glob_rec_bank.bank_code 
					AND pay_meth_ind = "1" 
					IF status != NOTFOUND THEN 
						#LET l_msgresp=kandoomsg("P",9010,l_arr_tentpays[i].cheq_code) 
						#9010 Cheque Number n already issued
						ERROR kandoomsg2("P",9010,l_arr_tentpays[i].cheq_code)
						NEXT FIELD cheq_code 
					END IF 
				END IF 
			END FOR 

	END INPUT 
	IF NOT (int_flag OR quit_flag) THEN 
		LET l_msgresp=kandoomsg("U",1005,"") 
		#U1005 Updating database - please wait
		### Begin the updating of cheque numbers ###
		--WHENEVER ERROR GOTO recovery4 
		GOTO bypass4 
		LABEL recovery4: 
		IF error_recover(l_error_text,status) != "Y" THEN 
			CLOSE WINDOW p235 
			RETURN FALSE 
		END IF 
		LABEL bypass4: 
		--WHENEVER ERROR GOTO recovery4 
		BEGIN WORK 
			FOR l_next = 1 TO lr_idx 
				###Cheque Update###
				LET l_error_text = "Problems Declare Cheque Payment (Ind) - P3A" 
				DECLARE c_indcheque CURSOR FOR 
				SELECT * FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND doc_num = l_arr_doc_num[l_next] 
				FOR UPDATE 
				OPEN c_indcheque 
				FETCH c_indcheque INTO l_rec_indcheque.* 
				UPDATE cheque 
				SET cheq_code = l_arr_tentpays[l_next].cheq_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND doc_num = l_arr_doc_num[l_next] 
				CLOSE c_indcheque 
				###Voucherpays Update###
				LET l_error_text = "Problems Declare Voucher Applications (Ind)-P3A" 
				DECLARE c_indvouchpays CURSOR FOR 
				SELECT * FROM voucherpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND remit_doc_num = l_arr_doc_num[l_next] 
				AND pay_doc_num = l_arr_doc_num[l_next] 
				FOR UPDATE 
				OPEN c_indvouchpays 
				FETCH c_indvouchpays INTO l_rec_indvouchpays.* 
				UPDATE voucherpays 
				SET pay_num = l_arr_tentpays[l_next].cheq_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND remit_doc_num = l_arr_doc_num[l_next] 
				AND pay_doc_num = l_arr_doc_num[l_next] 
				CLOSE c_indvouchpays 
				###Apaudit Update###
				LET l_error_text = "Problems Declare Vendor Audit Trail (Ind) - P3A" 
				DECLARE c_indapaudit CURSOR FOR 
				SELECT * FROM apaudit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND source_num = l_arr_doc_num[l_next] 
				AND vend_code = l_arr_tentpays[l_next].vend_code 
				FOR UPDATE 
				OPEN c_indapaudit 
				FETCH c_indapaudit INTO l_rec_indapaudit.* 
				UPDATE apaudit 
				SET source_num = l_arr_tentpays[l_next].cheq_code, 
				trantype_ind = "CH" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND source_num = l_arr_doc_num[l_next] 
				AND vend_code = l_arr_tentpays[l_next].vend_code 
				CLOSE c_indapaudit 
				###ExchangeVar Update###
				LET l_error_text = "Problems Updating Exchange Variances (Ind) - P3A" 
				DECLARE c_indexchvar CURSOR FOR 
				SELECT * FROM exchangevar 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ref2_num = l_arr_doc_num[l_next] 
				AND tran_type2_ind = "CH" 
				FOR UPDATE 
				OPEN c_indexchvar 
				FETCH c_indexchvar INTO l_rec_indexchvar.* 
				UPDATE exchangevar 
				SET ref2_num = l_arr_tentpays[l_next].cheq_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ref2_num = l_arr_doc_num[l_next] 
				AND tran_type2_ind = "CH" 
				CLOSE c_indexchvar 
				###Tentpays Update###
				LET l_error_text = "Problems Declare Tentative Payments (Ind) - P3A" 
				DECLARE c_indtentpays CURSOR FOR 
				SELECT * FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND pay_doc_num = l_arr_doc_num[l_next] 
				FOR UPDATE 
				OPEN c_indtentpays 
				FETCH c_indtentpays 
				UPDATE tentpays 
				SET cheq_code = l_arr_tentpays[l_next].cheq_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = glob_cycle_num 
				AND pay_doc_num = l_arr_doc_num[l_next] 
				CLOSE c_indtentpays 
			END FOR 
		COMMIT WORK 
		CLOSE WINDOW p235 
		RETURN TRUE 
	ELSE 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW p235 
		RETURN FALSE 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION setup_individual_cheque_numbers()
############################################################


############################################################
# REPORT exception_report(p_rpt_idx,p_error_text)
#
# Report Definition/Layout
############################################################
REPORT exception_report(p_rpt_idx,p_error_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_error_text CHAR(60) 
	DEFINE l_offset1, l_offset2 SMALLINT 
	DEFINE l_line1 CHAR(132) 
	DEFINE l_date_time DATETIME year TO second 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

		ON EVERY ROW 
			SKIP 1 line 
			LET l_date_time = CURRENT 
			PRINT COLUMN 001, l_date_time, 
			COLUMN 022, p_error_text clipped 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 022, "Bank Code........: ", glob_rec_tenthead.bank_code 
			PRINT COLUMN 022, "Cheque Date......: ", glob_rec_tenthead.cheq_date USING "dd/mm/yyyy" 
			PRINT COLUMN 022, "EFT Run Number...: ", glob_rec_tenthead.eft_run_num USING "<<<<<<<<<<" 
			PRINT COLUMN 022, "Cheque Run Number: ", glob_rec_tenthead.cheq_run_num USING "<<<<<<<<<<" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT
