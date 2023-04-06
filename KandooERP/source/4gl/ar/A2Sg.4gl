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
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A2S_GLOBALS.4gl"  
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_cust_add LIKE customer.cust_code 
DEFINE modu_group_code LIKE stnd_custgrp.group_code 
DEFINE modu_cnt SMALLINT 
DEFINE modu_bal_amt LIKE customer.bal_amt 
DEFINE modu_cred_avail_amt DECIMAL(16,2)
DEFINE modu_cred_limit_amt LIKE customer.cred_limit_amt 
DEFINE modu_continue SMALLINT 


############################################################
# FUNCTION inv_cust_list() 
#
#
############################################################
FUNCTION inv_cust_list() 
	DEFINE l_od_flg CHAR(1)
	DEFINE l_ind_flg CHAR(1)
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_rpt_idx SMALLINT 
	
	LET glob_idx = 1 
	LET l_od_flg = 'N' 
	LET modu_continue = true 
	INITIALIZE glob_arr_rec_customer TO NULL 

	OPEN WINDOW wa2sa with FORM "A2Sa" 
	CALL windecoration_a("A2Sa") 

	# INPUT the customers group code in which TO send a copy of this invoice TO.
	INPUT BY NAME glob_rec_stnd_grp.group_code
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2Sg","inp-group_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (group_code) 
					LET glob_rec_stnd_grp.group_code = show_group(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME glob_rec_stnd_grp.group_code 
					NEXT FIELD group_code 

		AFTER FIELD group_code 
			# Check IF group code IS a valid group code (ie in stnd_grp table).
			IF glob_rec_stnd_grp.group_code IS NULL OR glob_rec_stnd_grp.group_code = " " THEN 
				ERROR "A group code must be entered, try window (W)" 
				NEXT FIELD group_code 
			END IF 

			SELECT * 
			FROM stnd_grp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND group_code = glob_rec_stnd_grp.group_code 

			IF status = NOTFOUND THEN 
				ERROR "An invalid group code has been entered, please try window(W)" 
				NEXT FIELD group_code 
			ELSE 
				# Now we know it's valid, we get all of the customers which belong
				# TO this group.
				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start(getmoduleid(),"AS2G_rpt_list_over_cred",NULL, RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT AS2G_rpt_list_over_cred TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------

				DECLARE cust_grp CURSOR FOR 
				SELECT cust_code 
				FROM stnd_custgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = glob_rec_stnd_grp.group_code 

				FOREACH cust_grp INTO l_cust_code 
					DECLARE custcurs CURSOR FOR 
					SELECT cust_code, name_text, cred_limit_amt, 
					bal_amt 
					FROM customer 
					WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND customer.cust_code = l_cust_code 
					ORDER BY cust_code 

					FOREACH custcurs INTO glob_arr_rec_customer[glob_idx].cust_code, 
						glob_arr_rec_customer[glob_idx].name_text, 
						modu_cred_limit_amt, 
						modu_bal_amt 

						LET glob_arr_rec_customer[glob_idx].incld_flg = 'Y' 
						LET modu_cred_avail_amt = modu_cred_limit_amt - modu_bal_amt 

						IF modu_cred_avail_amt <= 0 THEN 
							LET l_od_flg = 'Y' 
							LET glob_arr_rec_customer[glob_idx].incld_flg = 'N' 
							
							OUTPUT TO REPORT AS2G_rpt_list_over_cred(l_rpt_idx,
							modu_cred_limit_amt, 
							modu_bal_amt, 
							modu_cred_avail_amt) 
							
						END IF 

						IF glob_idx > 1000 THEN 
							MESSAGE "Only the first 1000 Customers selected" 
							attribute (YELLOW) 
							SLEEP 5 
							EXIT FOREACH 
						END IF 

						IF int_flag OR quit_flag THEN 
							EXIT FOREACH 
						END IF 

						LET glob_idx = glob_idx + 1 
					END FOREACH 
				END FOREACH 
				LET glob_idx = glob_idx - 1 
				IF glob_idx = 0 THEN 
					MESSAGE "No customers belong TO this group" 
					LET glob_idx = 1 
					NEXT FIELD group_code 
				END IF 

				#------------------------------------------------------------
				FINISH REPORT AS2G_rpt_list_over_cred
				CALL rpt_finish("AS2G_rpt_list_over_cred")
				#------------------------------------------------------------
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

				IF l_od_flg = 'Y' THEN 

					ERROR "WARNING, some Customers included in this list are over their credit limit. " 

					LET glob_ans = "z" 
					WHILE glob_ans NOT matches "[YyNn]" 
						LET glob_ans = promptYN("Continue","WARNING, some Customers included in this list are over their credit limit.\n\nContinue?","Y") 
					END WHILE 


					LET glob_ans = downshift(glob_ans) 
					IF glob_ans = "n" THEN 
						LET int_flag = true 
						LET quit_flag = true 
						EXIT INPUT 
					END IF 
				END IF 

				IF glob_ans = "y" THEN 
				END IF 

				WHILE modu_continue 
					IF int_flag OR quit_flag THEN 
						EXIT WHILE 
					END IF 
					CALL set_count(glob_idx) 
					LET modu_cnt = arr_count() 
					MESSAGE "ESC TO create invoices, F7 TO toggle, F10 TO add Customers" 

					DISPLAY ARRAY glob_arr_rec_customer TO sr_stand_inv.* ATTRIBUTE(UNBUFFERED) 
						BEFORE DISPLAY 
							CALL publish_toolbar("kandoo","A2Sg","display-arr-customer") 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 
						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						ON KEY (F7) 
							# This IS TO allow the user the option TO exclude a
							# customer(s) FROM this particular invoice run.
							LET glob_idx = arr_curr() 
							#LET scrn = scr_line()
							IF glob_arr_rec_customer[glob_idx].incld_flg = 'N' THEN 
								SELECT cred_limit_amt, bal_amt 
								INTO modu_cred_limit_amt, modu_bal_amt 
								FROM customer 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code = glob_arr_rec_customer[glob_idx].cust_code 

								LET modu_cred_avail_amt = modu_cred_limit_amt - 
								modu_bal_amt 

								IF modu_cred_avail_amt <= 0 THEN 
									ERROR "This customer IS over their credit limit" 
								ELSE 
									LET glob_arr_rec_customer[glob_idx].incld_flg = 'Y' 
								END IF 
							ELSE 
								LET glob_arr_rec_customer[glob_idx].incld_flg = 'N' 
							END IF 
							#DISPLAY glob_arr_rec_customer[glob_idx].incld_flg TO
							#             sr_stand_inv[scrn].incld_flg

						ON KEY (F10) 
							# Allows the user TO add a customer TO this invoice list,
							# but only FOR this invoice PRINT.  This customer will NOT
							# be added TO the group chosen above.  Also tests IF the
							# customer chosen IS NOT already on the list.
							LET glob_idx = arr_curr() 
							#LET scrn = scr_line()
							LET modu_cust_add = show_clnt(glob_rec_kandoouser.cmpy_code) 
							LET l_ind_flg = "Y" 

							EXIT DISPLAY 
							IF int_flag OR quit_flag THEN 
								EXIT DISPLAY 
							END IF 

						ON KEY (ESC) 
							LET modu_continue = false 
							LET l_ind_flg = "N" 
							EXIT DISPLAY 
					END DISPLAY 

					IF l_ind_flg = "Y" THEN 
						CALL get_cust_list() 
						LET l_ind_flg = "N" 
					END IF 
				END WHILE 

				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 
			END IF 
	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW wa2sa 

		OPEN WINDOW wa2s with FORM "A2S" 
		CALL windecoration_a("A2S") 
		RETURN "N", " " 
	END IF 
	RETURN "Y", glob_rec_stnd_grp.group_code 
END FUNCTION 


############################################################
# FUNCTION get_cust_list() 
#
# 
############################################################
FUNCTION get_cust_list() 

	SELECT cred_limit_amt, bal_amt 
	INTO modu_cred_limit_amt, modu_bal_amt 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = modu_cust_add 

	IF status = NOTFOUND THEN 
		ERROR "This customer does NOT exist try window(W)" 
		LET glob_idx = modu_cnt 
		RETURN 
	END IF 

	LET modu_cred_avail_amt = modu_cred_limit_amt - modu_bal_amt 

	SELECT group_code 
	INTO modu_group_code 
	FROM stnd_custgrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = modu_cust_add 
	AND group_code = glob_rec_stnd_grp.group_code 

	IF status = NOTFOUND THEN 
		CALL add_cust_list(modu_cust_add) 
		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW wa2sa 
			CURRENT WINDOW IS wa2s 
			RETURN "N" 
		END IF 
	ELSE 
		LET glob_idx = modu_cnt 
		ERROR " This customer IS already on the current list" 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET modu_continue = false 
		RETURN 
	END IF 
END FUNCTION {get_cust_list} 



############################################################
# FUNCTION add_cust_list(p_fv_cust_add) 
#
# Adds another customer TO the current customer list.
############################################################
FUNCTION add_cust_list(p_fv_cust_add) 
	DEFINE p_fv_cust_add LIKE customer.cust_code 
	DEFINE j SMALLINT 
	DEFINE i SMALLINT 

	FOR i = modu_cnt TO glob_idx step -1 
		LET glob_arr_rec_customer[i+1].* = glob_arr_rec_customer[i].* 
	END FOR 

	INITIALIZE glob_arr_rec_customer[glob_idx].* TO NULL 
	#DISPLAY glob_arr_rec_customer[glob_idx].* TO sr_stand_inv[scrn].*

	IF p_fv_cust_add IS NOT NULL THEN 
		SELECT cust_code, name_text 
		INTO glob_arr_rec_customer[glob_idx].cust_code, 
		glob_arr_rec_customer[glob_idx].name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = p_fv_cust_add 

		IF modu_cred_avail_amt <= 0 THEN 
			LET glob_arr_rec_customer[glob_idx].incld_flg = "N" 
			ERROR "customer IS over credit limit" 
		ELSE 
			LET glob_arr_rec_customer[glob_idx].incld_flg = 'Y' 
		END IF 

		LET glob_idx = modu_cnt + 1 
		CALL set_count(glob_idx) 
		LET modu_cnt = arr_count() 

		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 
	END IF 
END FUNCTION 



############################################################
# REPORT AS2G_rpt_list_over_cred(p_rv_cred_limit_amt, p_rv_bal_amt, p_rv_avail_cred_amt) 
#
# This FUNCTION IS TO PRINT a REPORT of all customers over their credit limit.
############################################################
REPORT AS2G_rpt_list_over_cred(p_rpt_idx,p_rv_cred_limit_amt, p_rv_bal_amt, p_rv_avail_cred_amt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rv_cred_limit_amt LIKE customer.cred_limit_amt 
	DEFINE p_rv_bal_amt LIKE customer.bal_amt 
	DEFINE p_rv_avail_cred_amt DECIMAL(16,2) 

	OUTPUT 
--	left margin 0 
--	right margin 0 
--	top margin 0 
--	bottom margin 0 
--	PAGE length 66 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1		
			SKIP 4 LINES 

			PRINT COLUMN 50, "CUSTOMERS OVER THEIR CREDIT LIMIT" 
			SKIP 2 LINES 

			PRINT COLUMN 7, "Customer Code", 
			COLUMN 33, "Name", 
			COLUMN 52, "Credit Limit", 
			COLUMN 70, "Available Credit" 
			SKIP 1 line 

			PRINT COLUMN 5, "----------------------------------------------------------------------------------------------------" 

		ON EVERY ROW 
			PRINT COLUMN 10, glob_arr_rec_customer[glob_idx].cust_code, 
			COLUMN 20, glob_arr_rec_customer[glob_idx].name_text, 
			COLUMN 50, p_rv_cred_limit_amt, 
			COLUMN 70, p_rv_avail_cred_amt 

		ON LAST ROW 
			--PRINT COLUMN 38, "--=== END OF REPORT ===--" 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno			
END REPORT 


