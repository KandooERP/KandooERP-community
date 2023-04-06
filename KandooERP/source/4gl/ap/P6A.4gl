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
# P6A - Automatic Debit Application
#
#
# In 'Report' only Mode no database UPDATE IS performed on either
#      the 'voucher' OR 'debithead' tables. Since multiple debit's
#      may be applied against a single voucher we need TO keep track
#      of this voucher's applications. Since we cannot rely on the
#      information stored in the database as a current reflection of
#      applications , the use of a temp. table IS required.
# N.B. We do NOT need TO keep track of debit's because only one
#      application strategy can be chosen in 'Report' only Mode
#
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P6A_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

GLOBALS 
	DEFINE glob_disc_flag CHAR(1) 
	DEFINE glob_strategy_ind SMALLINT 
	DEFINE glob_update_ind SMALLINT 
	DEFINE glob_where1_text CHAR(2048) 
	DEFINE glob_where2_text CHAR(2048) 
	DEFINE glob_debit_not_applied SMALLINT 
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("P6A") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CALL create_table("voucher","t_voucher","","Y") 
	CREATE unique INDEX tvoucher_key ON t_voucher( vouch_code ) 

	OPEN WINDOW P222 with FORM "P222" 
	CALL windecoration_p("P222") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " Debit Application" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","P6A","menu-debit_app-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Report" " Apply debits in REPORT only mode" 
			LET glob_debit_not_applied = 0 
			LET glob_update_ind = FALSE 
			CALL auto_apply() 
			
			 
		COMMAND "UPDATE" " Commit debit applications TO database" 
			LET glob_debit_not_applied = 0 
			LET glob_update_ind = TRUE 
			CALL auto_apply() 
 

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW P222 
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION auto_apply()
#
#
############################################################
FUNCTION auto_apply() 
	DEFINE l_rpt_output CHAR(80)

	DELETE FROM t_voucher 

	IF scan_appl() THEN 

		#------------------------------------------------------------
--		#User pressed CANCEL = p_where_text IS NULL
--		IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--			LET int_flag = false 
--			LET quit_flag = false
--	
--			RETURN FALSE
--		END IF
	
		LET modu_rpt_idx = rpt_start(getmoduleid(),"P6A_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
		IF modu_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	

		IF glob_update_ind THEN 
			CALL rpt_set_header_footer_line_2_append(modu_rpt_idx,NULL, " - Update Mode") 
		ELSE 
			CALL rpt_set_header_footer_line_2_append(modu_rpt_idx,NULL, " - Report Mode") 
		END IF 
				
		START REPORT P6A_rpt_list TO rpt_get_report_file_with_path2(modu_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].report_width_num
		--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AC1_rpt_list")].sel_text
		#------------------------------------------------------------
		
		CALL scan_debit() 
		
		#------------------------------------------------------------
		FINISH REPORT P6A_rpt_list
		CALL rpt_finish("P6A_rpt_list")
		#------------------------------------------------------------
		
	END IF 
END FUNCTION 


FUNCTION scan_appl() 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_strategy_ind = 0 
	LET glob_disc_flag = 'N' 
	CLEAR FORM 
	LET l_msgresp = kandoomsg("P",1064,"") 
	#1064 Enter Application Details - ESC TO Continue
	CONSTRUCT BY NAME glob_where1_text ON vendor.vend_code, 
	name_text, 
	type_code, 
	vendor.currency_code, 
	debit_num, 
	debit_date, 
	debit_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P6A","construct-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	CONSTRUCT BY NAME glob_where2_text ON 
		vouch_code, 
		vouch_date, 
		term_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P6A","construct-voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	OPEN WINDOW p224 with FORM "P224" 
	CALL windecoration_p("P224") 

	INPUT glob_strategy_ind, glob_disc_flag WITHOUT DEFAULTS FROM strategy_ind, disc_flag

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P6A","inp-strategy-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	CLOSE WINDOW p224 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 


FUNCTION scan_debit() 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_query_text = " SELECT debithead.* ", 
	" FROM debithead, ", 
	" vendor ", 
	" WHERE debithead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND debithead.total_amt != debithead.apply_amt ", 
	" AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND vendor.vend_code = debithead.vend_code ", 
	" AND ", glob_where1_text clipped, 
	" ORDER BY vend_code, debit_date, debit_num" 
	PREPARE s_debit FROM l_query_text 
	DECLARE c_debit CURSOR with HOLD FOR s_debit 

	DISPLAY "" at 1,1 
	DISPLAY " Applying Debit :" at 2,1 

	DISPLAY " TO Voucher :" at 3,1 

	FOREACH c_debit INTO l_rec_debithead.* 
		IF NOT scan_vouch( l_rec_debithead.* ) THEN 
			#
			# User has DEL'd
			#
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CLOSE c_debit 

	IF glob_update_ind THEN 
		IF glob_debit_not_applied THEN 
			LET l_msgresp = kandoomsg("P",7004,"") 
			#7004 Not all debits applied due TO vouchers in P3A.
		END IF 
	END IF 
END FUNCTION 


FUNCTION scan_vouch(p_rec_debithead) 
	DEFINE p_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_r_voucher RECORD LIKE voucher.*
	DEFINE l_rec_s_voucher RECORD LIKE voucher.* 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_appl_amt LIKE debithead.apply_amt 
	DEFINE l_disc_amt LIKE debithead.disc_amt 

	LET l_query_text = " SELECT * FROM voucher WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND vend_code = '",p_rec_debithead.vend_code,"' ", 
	" AND ", glob_where2_text clipped 
	CASE glob_strategy_ind 
		WHEN 1 
			IF length(p_rec_debithead.debit_text) = 0 THEN 
				RETURN TRUE 
			ELSE 
				IF glob_disc_flag = 'Y' THEN 
					LET l_query_text = 
					l_query_text clipped, 
					" AND inv_text = '",p_rec_debithead.debit_text,"' ", 
					" AND ( ('",p_rec_debithead.debit_date,"' <= disc_date ", 
					" AND ( total_amt - paid_amt - poss_disc_amt ) = ", 
					p_rec_debithead.total_amt 
					- p_rec_debithead.apply_amt, " ) ", 
					" OR ( '",p_rec_debithead.debit_date,"' > disc_date ", 
					" AND ( total_amt - paid_amt ) = ", p_rec_debithead.total_amt 
					- p_rec_debithead.apply_amt,"))" 
				ELSE 
					LET l_query_text = 
					l_query_text clipped, 
					" AND inv_text = '",p_rec_debithead.debit_text,"' ", 
					" AND ( total_amt - paid_amt ) = ", p_rec_debithead.total_amt 
					- p_rec_debithead.apply_amt 
				END IF 
			END IF 
		WHEN 2 
			IF length(p_rec_debithead.debit_text) = 0 THEN 
				RETURN TRUE 
			ELSE 
				LET l_query_text = l_query_text clipped, 
				" AND inv_text = '",p_rec_debithead.debit_text,"' ", 
				" AND total_amt != paid_amt " 
			END IF 
		WHEN 3 
			IF glob_disc_flag = 'Y' THEN 
				LET l_query_text = 
				l_query_text clipped, 
				" AND ( ( '",p_rec_debithead.debit_date,"' <= disc_date ", 
				" AND ( total_amt - paid_amt - poss_disc_amt ) >= ", 
				p_rec_debithead.total_amt 
				- p_rec_debithead.apply_amt, " ) ", 
				" OR ( '",p_rec_debithead.debit_date,"' > disc_date ", 
				" AND ( total_amt - paid_amt ) >= ", p_rec_debithead.total_amt 
				- p_rec_debithead.apply_amt, "))" 
			ELSE 
				LET l_query_text = 
				l_query_text clipped, 
				" AND ( total_amt - paid_amt ) >= ", p_rec_debithead.total_amt 
				- p_rec_debithead.apply_amt 
			END IF 
		WHEN 4 
			LET l_query_text = l_query_text clipped, 
			" AND total_amt != paid_amt " 
	END CASE 
	LET l_query_text = l_query_text clipped, 
	" ORDER BY due_date, vouch_code " 
	PREPARE s_vouch FROM l_query_text 
	DECLARE c_vouch CURSOR with HOLD FOR s_vouch 
	FOREACH c_vouch INTO l_rec_r_voucher.* 
		SELECT unique 1 FROM tentpays 
		WHERE vend_code = p_rec_debithead.vend_code 
		AND vouch_code = l_rec_r_voucher.vouch_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status != NOTFOUND THEN 
			IF glob_update_ind THEN 
				LET glob_debit_not_applied = 1 
				CONTINUE FOREACH 
			END IF 
		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			#8005 Do you wish TO quit (Y/N) ?
			IF kandoomsg("P",8005,"") = 'Y' THEN 
				CLOSE c_vouch 
				RETURN FALSE 
			END IF 
		END IF 
		DISPLAY "" at 2,21 
		DISPLAY "" at 3,21 
		DISPLAY p_rec_debithead.debit_num USING "#######&" at 2,21 

		DISPLAY l_rec_r_voucher.vouch_code USING "#######&" at 3,21 

		#
		#
		#
		IF NOT glob_update_ind THEN 
			SELECT * INTO l_rec_s_voucher.* 
			FROM t_voucher 
			WHERE vouch_code = l_rec_r_voucher.vouch_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				INSERT INTO t_voucher VALUES ( l_rec_r_voucher.* ) 
			ELSE 
				LET l_rec_r_voucher.* = l_rec_s_voucher.* 
				IF l_rec_r_voucher.total_amt = l_rec_r_voucher.paid_amt THEN 
					CONTINUE FOREACH 
				END IF 
				IF glob_strategy_ind = '3' THEN 
					IF glob_disc_flag = 'Y' THEN 
						IF p_rec_debithead.debit_date <= l_rec_r_voucher.disc_date THEN 
							IF ( p_rec_debithead.total_amt - p_rec_debithead.apply_amt ) 
							< ( l_rec_r_voucher.total_amt - l_rec_r_voucher.paid_amt 
							- l_rec_r_voucher.poss_disc_amt ) THEN 
							ELSE 
								CONTINUE FOREACH 
							END IF 
						ELSE 
							IF ( p_rec_debithead.total_amt - p_rec_debithead.apply_amt ) 
							< ( l_rec_r_voucher.total_amt - l_rec_r_voucher.paid_amt ) THEN 
							ELSE 
								CONTINUE FOREACH 
							END IF 
						END IF 
					ELSE 
						IF ( p_rec_debithead.total_amt - p_rec_debithead.apply_amt ) 
						< ( l_rec_r_voucher.total_amt - l_rec_r_voucher.paid_amt ) THEN 
						ELSE 
							CONTINUE FOREACH 
						END IF 
					END IF 
				END IF 
			END IF 
		END IF 
		LET l_disc_amt = 0 
		LET l_appl_amt = l_rec_r_voucher.total_amt 
		- l_rec_r_voucher.paid_amt 
		IF l_appl_amt > ( p_rec_debithead.total_amt 
		- p_rec_debithead.apply_amt ) THEN 
			LET l_appl_amt = p_rec_debithead.total_amt 
			- p_rec_debithead.apply_amt 
		END IF 
		IF p_rec_debithead.post_flag != 'Y' THEN 
			IF glob_disc_flag = 'Y' THEN 
				IF p_rec_debithead.debit_date <= l_rec_r_voucher.disc_date THEN 
					LET l_disc_amt = l_rec_r_voucher.poss_disc_amt 
				END IF 
				IF ( l_rec_r_voucher.total_amt - l_rec_r_voucher.paid_amt ) 
				> ( l_appl_amt + l_disc_amt ) THEN 
					LET l_disc_amt = 0 
				ELSE 
					LET l_appl_amt = l_rec_r_voucher.total_amt 
					- l_rec_r_voucher.paid_amt 
					- l_disc_amt 
				END IF 
			END IF 
		END IF 
		IF glob_update_ind THEN 
			IF NOT debit_apply( glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, FALSE, p_rec_debithead.debit_num, 
			l_rec_r_voucher.vouch_code, 
			l_appl_amt , 
			l_disc_amt ) THEN 
				EXIT FOREACH 
			END IF 
		END IF 
		
		IF l_appl_amt	OR l_disc_amt THEN 
		
			OUTPUT TO REPORT P6A_rpt_list(modu_rpt_idx,
			p_rec_debithead.debit_num, 
			p_rec_debithead.total_amt, 
			l_rec_r_voucher.vend_code, 
			l_rec_r_voucher.vouch_code, 
			l_rec_r_voucher.inv_text, 
			p_rec_debithead.apply_amt, 
			l_appl_amt, 
			l_disc_amt, 
			l_rec_r_voucher.paid_amt, 
			l_rec_r_voucher.total_amt )
			 
		END IF 
		
		LET p_rec_debithead.apply_amt = p_rec_debithead.apply_amt	+ l_appl_amt 
		LET p_rec_debithead.disc_amt = p_rec_debithead.disc_amt 	+ l_disc_amt 
		IF NOT glob_update_ind THEN 
			LET l_rec_r_voucher.taken_disc_amt = l_rec_r_voucher.taken_disc_amt 
			+ l_disc_amt 
			LET l_rec_r_voucher.paid_amt = l_rec_r_voucher.paid_amt 
			+ l_appl_amt 
			+ l_disc_amt 
			UPDATE t_voucher 
			SET paid_amt = l_rec_r_voucher.paid_amt, 
			taken_disc_amt = l_rec_r_voucher.taken_disc_amt 
			WHERE vouch_code = l_rec_r_voucher.vouch_code 
		END IF 
		IF p_rec_debithead.apply_amt = p_rec_debithead.total_amt THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CLOSE c_vouch 
	RETURN TRUE 
END FUNCTION 


REPORT P6A_rpt_list(p_rpt_idx,p_debit_num,p_debit_amt,p_vend_code,p_vouch_code,p_inv_text,p_prev_apply_amt,p_apply_amt,p_disc_amt,p_prev_paid_amt,p_vouch_amt )
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_debit_num LIKE debithead.debit_num 
	DEFINE p_debit_amt LIKE debithead.total_amt 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE p_inv_text LIKE voucher.inv_text 
	DEFINE p_prev_apply_amt LIKE debithead.apply_amt
	DEFINE p_apply_amt LIKE debithead.apply_amt 
	DEFINE p_disc_amt LIKE voucher.taken_disc_amt 
	DEFINE p_prev_paid_amt LIKE voucher.paid_amt 
	DEFINE p_vouch_amt LIKE voucher.total_amt 
	DEFINE l_arr_linep_vend_code ARRAY[4] OF CHAR(132) 
	DEFINE l_temp_text LIKE kandooword.reference_text 
	DEFINE x SMALLINT 

	OUTPUT 
	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 01, p_debit_num USING "########", 
			COLUMN 10, p_debit_amt USING "#####&.&&", 
			COLUMN 20, p_vend_code, 
			COLUMN 29, p_vouch_code USING "########", 
			COLUMN 38, p_inv_text[1,15], 
			COLUMN 54, p_prev_apply_amt USING "#####&.&&", 
			COLUMN 64, p_apply_amt USING "#####&.&&", 
			COLUMN 74, ( p_prev_apply_amt 
			+ p_apply_amt ) USING "#####&.&&", 
			COLUMN 84, p_disc_amt USING "#####&.&&", 
			COLUMN 94, p_prev_paid_amt USING "#####&.&&", 
			COLUMN 104, ( p_apply_amt 
			+ p_disc_amt ) USING "#####&.&&", 
			COLUMN 114, ( p_prev_paid_amt 
			+ p_apply_amt 
			+ p_disc_amt ) USING "#####&.&&", 
			COLUMN 124, p_vouch_amt USING "#####&.&&" 

		ON LAST ROW 
			NEED 3 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 01,l_arr_linep_vend_code[4] 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			
END REPORT 