{
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
	Source code beautified by beautify.pl on 2020-01-03 13:41:23	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P3_GLOBALS.4gl" 
GLOBALS 
--	DEFINE glob_idx SMALLINT 
	DEFINE glob_scrn SMALLINT 
--	DEFINE glob_where_text STRING
	DEFINE glob_option CHAR(1) 
	DEFINE glob__error_text CHAR(60) 
	DEFINE glob_cycle_num LIKE tenthead.cycle_num 
	DEFINE glob_max_array SMALLINT # maximum ARRAY records 
	DEFINE glob_max_screen SMALLINT # maximum screen LINES 
	DEFINE t_rec_tentpays TYPE AS RECORD
		scroll_flag CHAR(1), 
		vend_code LIKE tentpays.vend_code, 
		vouch_code LIKE tentpays.vouch_code, 
		due_date LIKE tentpays.due_date, 
		vouch_amt LIKE tentpays.vouch_amt, 
		inv_text LIKE tentpays.inv_text, 		#  different from glob_arr_rec_tentpays2
		taken_disc_amt LIKE tentpays.taken_disc_amt, 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind, 
		pay_meth_ind LIKE tentpays.pay_meth_ind 
	END RECORD
	DEFINE glob_arr_rec_tentpays DYNAMIC ARRAY OF t_rec_tentpays 

	DEFINE l_rec_s_tentpay1 RECORD 
		vend_code LIKE tentpays.vend_code, 
		vouch_code LIKE tentpays.vouch_code, 
		due_date LIKE tentpays.due_date, 
		vouch_amt LIKE tentpays.vouch_amt, 
		inv_text LIKE tentpays.inv_text, 
		taken_disc_amt LIKE tentpays.taken_disc_amt, 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind, 
		pay_meth_ind LIKE tentpays.pay_meth_ind, 
		source_ind LIKE tentpays.source_ind 
	END RECORD 

	DEFINE t_rec_tentpays2 TYPE AS RECORD
		scroll_flag CHAR(1), 
		vend_code LIKE tentpays.vend_code, 
		vouch_code LIKE tentpays.vouch_code, 
		due_date LIKE tentpays.due_date, 
		vouch_amt LIKE tentpays.vouch_amt, 		
		disc_date LIKE tentpays.disc_date, 		#  different from glob_arr_rec_tentpays
		taken_disc_amt LIKE tentpays.taken_disc_amt, 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind, 
		pay_meth_ind LIKE tentpays.pay_meth_ind 
	END RECORD 
	DEFINE glob_arr_rec_tentpays2 DYNAMIC ARRAY OF t_rec_tentpays2  
END GLOBALS
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P33  Payment Register Adjustments
#  The payment register can be altered before printing
############################################################
FUNCTION P33_MAIN ()
	DEFINE l_count SMALLINT 
	DEFINE l_operation_status SMALLINT
	DEFINE l_where_clause STRING

	#Initial UI Init
	#Initial UI Init
	CALL setModuleId("P33") 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	LET glob_cycle_num = 1 
	LET glob_max_array = 1500 
	LET glob_max_screen = 12 
	LET glob_option = get_kandoooption_feature_state('AP','TP') 

	# Vendor's Invoice Number
	CASE glob_option 
		WHEN '2' 
			OPEN WINDOW p221 with FORM "P221" 
			CALL windecoration_p("P221") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			IF NOT check_tenthead_status(glob_cycle_num,1) THEN 
				CLOSE WINDOW p221 
				EXIT PROGRAM 
			END IF 

			WHILE l_operation_status = TRUE
				CALL construct_dataset_tentpays_1() RETURNING l_operation_status,l_where_clause
				CALL process_tentpays(l_where_clause) RETURNING l_operation_status
				IF NOT l_operation_status THEN 
					EXIT WHILE 
				END IF 
			END WHILE 
			CLOSE WINDOW p221 

			# Default IS Discount Date
		OTHERWISE 
			OPEN WINDOW p111 with FORM "P111" 
			CALL windecoration_p("P111") 

			IF NOT check_tenthead_status(glob_cycle_num,1) THEN 
				CLOSE WINDOW p111 
				EXIT PROGRAM 
			END IF 
			LET l_operation_status = TRUE
			WHILE l_operation_status = TRUE
				CALL construct_dataset_tentpays_2() RETURNING l_operation_status,l_where_clause
				CALL process_tentpays2(l_where_clause) RETURNING l_operation_status
				IF l_operation_status THEN 
					EXIT WHILE 
				END IF 
			END WHILE 
			CLOSE WINDOW p111 
	END CASE 

	### Check FOR 0 rows in tentpays ###
	### therefore TO delete tenthead ###
	SELECT count(*) INTO l_count 
	FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = 1 

	IF l_count = 0 THEN 
		WHENEVER ERROR CONTINUE 
		DELETE FROM tenthead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = 1 
		WHENEVER ERROR stop 
	END IF 
END FUNCTION # P33_main 


############################################################
# FUNCTION construct_dataset_tentpays_1()
#
#
############################################################
FUNCTION construct_dataset_tentpays_1() 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_where_clause STRING 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT l_where_clause ON tentpays.vend_code, 
		tentpays.vouch_code, 
		tentpays.due_date, 
		tentpays.vouch_amt, 
		tentpays.inv_text, 
		tentpays.taken_disc_amt, 
		tentpays.withhold_tax_ind, 
		tentpays.pay_meth_ind 
	FROM tentpays.vend_code, 
		tentpays.vouch_code, 
		tentpays.due_date, 
		tentpays.vouch_amt, 
		tentpays.inv_text, 
		tentpays.taken_disc_amt, 
		tentpays.withhold_tax_ind, 
		tentpays.pay_meth_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P33","construct-tentpays-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE,""
	END IF 
	RETURN TRUE,l_where_clause 
END FUNCTION   # construct_dataset_tentpays_1



############################################################
# FUNCTION process_tentpays()
#
#
############################################################
FUNCTION process_tentpays(p_where_clause) 
	DEFINE p_where_clause STRING
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_recalc_ind CHAR(1) 
	DEFINE l_status INTEGER 
	DEFINE l_del_cnt SMALLINT #pr_arr_cnt, 
	DEFINE l_pr_cnt SMALLINT 
	DEFINE l_idx, l_curr, l_line, l_next SMALLINT 
	DEFINE l_cnt2, l_scrn SMALLINT #not used , l_count 
	DEFINE l_total_to_pay DECIMAL(14,2) 
	DEFINE l_curr_code LIKE vendor.currency_code 
	DEFINE l_query_text CHAR(2200) 
	#DEFINE #l_rec_tentpays, NOT used
	DEFINE l_rec_s_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_s_tentpay1 RECORD 
		vend_code LIKE tentpays.vend_code, 
		vouch_code LIKE tentpays.vouch_code, 
		due_date LIKE tentpays.due_date, 
		vouch_amt LIKE tentpays.vouch_amt, 
		inv_text LIKE tentpays.inv_text, 
		taken_disc_amt LIKE tentpays.taken_disc_amt, 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind, 
		pay_meth_ind LIKE tentpays.pay_meth_ind, 
		source_ind LIKE tentpays.source_ind 
	END RECORD 
	DEFINE l_arr_rec_source_ind DYNAMIC ARRAY OF RECORD 
		source_ind LIKE tentpays.source_ind 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE prp_tentpays_statusind_1 PREPARED
	DEFINE crs_tentpays_statusind_1 CURSOR

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database - please wait
	LET l_query_text = "SELECT '*' ,",
	" vend_code, ", 
	"vouch_code, ", 
	"due_date, ", 
	"vouch_amt, ", 
	"inv_text, ", 
	"taken_disc_amt, ", 
	"withhold_tax_ind, ", 
	"pay_meth_ind, ", 
	"source_ind ", 
	"FROM tentpays ", 
	"WHERE tentpays.cmpy_code = ? ",
	"AND cycle_num = ? ",
	"AND status_ind = '1' ", 
	"AND ",p_where_clause clipped," ", 
	"ORDER BY pay_meth_ind, ", 
	" vend_code, ", 
	" withhold_tax_ind, ", 
	" vouch_code" 

	CALL prp_tentpays_statusind_1.Prepare(l_query_text)
	CALL crs_tentpays_statusind_1.Declare(prp_tentpays_statusind_1)
	CALL crs_tentpays_statusind_1.Open(glob_rec_kandoouser.cmpy_code,glob_cycle_num)

	LET l_idx = 1 
	LET l_total_to_pay = 0 
	LET l_recalc_ind = NULL 
	--FOREACH c_tentpays INTO l_rec_s_tentpay1.* 
	# As a horrible trick, we set glob_arr_rec_tentpays2[1].* to NULL so that it can be passed as a dummy argument
	INITIALIZE glob_arr_rec_tentpays2[1].* TO NULL

	WHILE crs_tentpays_statusind_1.FetchNext(glob_arr_rec_tentpays[l_idx].*) = 0
		LET l_idx = l_idx - 1 
--		IF glob_arr_rec_tentpays[l_idx].vend_code = l_rec_s_tentpay1.vend_code THEN 
--			FOR l_idx = glob_max_array TO 1 step -1 
--				IF glob_arr_rec_tentpays[l_idx].vend_code = l_rec_s_tentpay1.vend_code THEN 
--					LET l_total_to_pay = l_total_to_pay - glob_arr_rec_tentpays[l_idx].vouch_amt 
--					INITIALIZE glob_arr_rec_tentpays[l_idx].* TO NULL 
--				ELSE 
--					EXIT FOR 
--				END IF 
--			END FOR 
--		END IF 
		LET l_msgresp=kandoomsg("U",6100,l_idx) 
		#6100 "First l_idx entries selected"
--		EXIT WHILE 

		LET l_total_to_pay = l_total_to_pay + glob_arr_rec_tentpays[l_idx].vouch_amt 
		LET l_idx = l_idx + 1 
	END WHILE  # crs_tentpays_statusind_1
	CALL glob_arr_rec_tentpays.Delete(l_idx)  # last l_idx is one ahead of elements
	LET l_idx = l_idx -1 	

	LET l_msgresp = kandoomsg("U","9113",l_idx) 
	#9133 l_idx records selected
	DISPLAY l_total_to_pay TO total_pay 

	IF l_idx > 0 THEN 
		SELECT currency_code INTO l_curr_code 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = glob_arr_rec_tentpays[l_idx].vend_code 
		DISPLAY l_curr_code TO currency_code 
		attribute(green) 
	ELSE 
		LET l_idx = 1 
		INITIALIZE glob_arr_rec_tentpays[l_idx].* TO NULL 
	END IF 
	--OPTIONS INSERT KEY f1, 
	
	CALL set_count(l_idx) 
	LET l_del_cnt = 0 
	LET l_msgresp = kandoomsg("P",1053,"") 
	#1053 RETURN TO Edit - F1 TO Add - F2 TO Delete - F9 TO View Voucher"
	INPUT ARRAY glob_arr_rec_tentpays WITHOUT DEFAULTS FROM sr_tentpays.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P33","inp-arr-tentpays-1") 
			CALL dialog.setActionHidden ("DELETE",TRUE)   --DELETE KEY f36 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			LET glob_scrn = scr_line() 
			LET l_scroll_flag = glob_arr_rec_tentpays[l_idx].scroll_flag 
			DISPLAY glob_arr_rec_tentpays[l_idx].* 
			TO sr_tentpays[glob_scrn].* 

		AFTER FIELD scroll_flag 
			LET glob_arr_rec_tentpays[l_idx].scroll_flag = l_scroll_flag 
			DISPLAY glob_arr_rec_tentpays[l_idx].* 
			TO sr_tentpays[glob_scrn].* 

--			IF fgl_lastkey() = fgl_keyval("down") THEN 
--				IF (l_idx + 1) <= glob_max_array THEN 
--					IF glob_arr_rec_tentpays[l_idx+1].vend_code IS NULL 
--					OR arr_curr() = arr_count() THEN 
--						LET l_msgresp=kandoomsg("U","9001","") 
--						#9001 There are no more rows...
--						NEXT FIELD scroll_flag 
--					END IF 
--				ELSE 
--					LET l_msgresp=kandoomsg("U","9001","") 
--					#9001 There are no more rows...
--					NEXT FIELD scroll_flag 
--				END IF 
--			ELSE 
--				IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
--					IF (l_idx + glob_max_screen) <= glob_max_array THEN 
--						IF glob_arr_rec_tentpays[l_idx+glob_max_screen].vend_code IS NULL 
--						OR arr_curr() >= arr_count() THEN 
--							LET l_msgresp=kandoomsg("U","9001","") 
--							#9001 There are no more rows...
--							NEXT FIELD scroll_flag 
--						END IF 
--					ELSE 
--						LET l_msgresp=kandoomsg("U","9001","") 
--						#9001 There are no more rows...
--						NEXT FIELD scroll_flag 
--					END IF 
--				END IF 
--			END IF 
		BEFORE FIELD vend_code 
			IF l_arr_rec_source_ind[l_idx].source_ind = "S" THEN #sundry payment 
				LET l_msgresp=kandoomsg("P","9133","") 
				#9133 Sundry Payment amount must match voucher; Edit NOT allowed.
				NEXT FIELD scroll_flag 
			END IF 
			IF glob_arr_rec_tentpays[l_idx].vend_code IS NOT NULL THEN 
				CALL process_automatic_payment(l_idx,MODE_CLASSIC_EDIT,glob_arr_rec_tentpays[l_idx].*,glob_arr_rec_tentpays2[1].*) # MODE 
				RETURNING l_status, l_rec_s_tentpays.* 
				IF l_status THEN 
					IF l_status < 0 THEN 
						EXIT INPUT 
					END IF 
					LET l_total_to_pay = l_total_to_pay + l_rec_s_tentpays.vouch_amt - glob_arr_rec_tentpays[l_idx].vouch_amt 
					LET glob_arr_rec_tentpays[l_idx].inv_text = l_rec_s_tentpays.inv_text 
					LET glob_arr_rec_tentpays[l_idx].vouch_amt = l_rec_s_tentpays.vouch_amt 
					LET glob_arr_rec_tentpays[l_idx].due_date = l_rec_s_tentpays.due_date 
					LET glob_arr_rec_tentpays[l_idx].taken_disc_amt = l_rec_s_tentpays.taken_disc_amt 
					LET glob_arr_rec_tentpays[l_idx].withhold_tax_ind = l_rec_s_tentpays.withhold_tax_ind 
					LET glob_arr_rec_tentpays[l_idx].pay_meth_ind = l_rec_s_tentpays.pay_meth_ind 
					LET l_arr_rec_source_ind[l_idx].source_ind = l_rec_s_tentpays.source_ind 
					DISPLAY l_total_to_pay TO total_pay 
				END IF 
				DISPLAY glob_arr_rec_tentpays[l_idx].* 
				TO sr_tentpays[glob_scrn].* 

			END IF 
--			OPTIONS INSERT KEY f1, 
--			DELETE KEY f36 
			NEXT FIELD scroll_flag 
		
		ON ACTION "Cancel This Payment"   # ON KEY (F2) 
			IF glob_arr_rec_tentpays[l_idx].vend_code IS NOT NULL THEN 
				IF glob_arr_rec_tentpays[l_idx].scroll_flag IS NULL THEN 
					LET glob_arr_rec_tentpays[l_idx].scroll_flag = "*" 
					LET l_del_cnt = l_del_cnt + 1 
					LET l_total_to_pay = l_total_to_pay - glob_arr_rec_tentpays[l_idx].vouch_amt 
					DISPLAY l_total_to_pay TO total_pay 
				ELSE 
					LET glob_arr_rec_tentpays[l_idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
					LET l_total_to_pay = l_total_to_pay + glob_arr_rec_tentpays[l_idx].vouch_amt 
					DISPLAY l_total_to_pay TO total_pay 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

		ON ACTION "Show Voucher"   --ON KEY (F9)  
			IF glob_arr_rec_tentpays[l_idx].vouch_code IS NOT NULL THEN 
				CALL display_voucher_header(glob_rec_kandoouser.cmpy_code, glob_arr_rec_tentpays[l_idx].vouch_code) 
			END IF 
			NEXT FIELD scroll_flag 
		
		ON ACTION "Cancel All Payments" # ON KEY (F10) 
			FOR l_pr_cnt = 1 TO arr_count() 
				IF glob_arr_rec_tentpays[l_pr_cnt].vend_code IS NOT NULL THEN 
					IF glob_arr_rec_tentpays[l_pr_cnt].scroll_flag IS NULL THEN 
						LET glob_arr_rec_tentpays[l_pr_cnt].scroll_flag = "*" 
						LET l_del_cnt = l_del_cnt + 1 
						LET l_total_to_pay = l_total_to_pay - glob_arr_rec_tentpays[l_pr_cnt].vouch_amt 
					ELSE 
						LET glob_arr_rec_tentpays[l_pr_cnt].scroll_flag = NULL 
						LET l_del_cnt = l_del_cnt - 1 
						LET l_total_to_pay = l_total_to_pay + glob_arr_rec_tentpays[l_pr_cnt].vouch_amt 
					END IF 
				END IF 
			END FOR 
--			LET l_next = (l_curr - l_line) + 1 
--			LET l_scrn = 1 
--			FOR l_cnt2 = l_next TO (l_next + (glob_max_screen + 1)) 
--				IF l_cnt2 <= arr_count() THEN 
--					IF l_scrn <= glob_max_screen THEN 
--						DISPLAY glob_arr_rec_tentpays[l_cnt2].scroll_flag 
--						TO sr_tentpays[l_scrn].scroll_flag 
--
--						LET l_scrn = l_scrn + 1 
--					END IF 
--				END IF 
--			END FOR 
			DISPLAY l_total_to_pay TO total_pay 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			FOR l_idx = arr_count() TO (arr_curr() + 1) step - 1 
				LET l_arr_rec_source_ind[l_idx].* = l_arr_rec_source_ind[l_idx-1].* 
			END FOR 
			INITIALIZE l_arr_rec_source_ind[l_idx].* TO NULL 
			CALL process_automatic_payment(l_idx,MODE_CLASSIC_ADD,glob_arr_rec_tentpays[l_idx].*,glob_arr_rec_tentpays2[1].*) # MODE 
			RETURNING l_status, l_rec_s_tentpays.* 
			IF NOT l_status THEN 
				FOR l_idx = l_curr TO l_pr_cnt 
					IF (l_idx + 1) <= glob_max_array THEN 
						IF glob_arr_rec_tentpays[l_idx+1].vend_code IS NOT NULL THEN 
							LET glob_arr_rec_tentpays[l_idx].* = glob_arr_rec_tentpays[l_idx+1].* 
							LET l_arr_rec_source_ind[l_idx].* = l_arr_rec_source_ind[l_idx+1].* 
						ELSE 
							INITIALIZE glob_arr_rec_tentpays[l_idx].* TO NULL 
							INITIALIZE l_arr_rec_source_ind[l_idx].* TO NULL 
						END IF 
					ELSE 
						INITIALIZE glob_arr_rec_tentpays[l_idx].* TO NULL 
						INITIALIZE l_arr_rec_source_ind[l_idx].* TO NULL 
					END IF 
					IF l_scrn <= glob_max_screen THEN 
						DISPLAY glob_arr_rec_tentpays[l_idx].* TO sr_tentpays[l_scrn].* 

						LET l_scrn = l_scrn + 1 
					END IF 
				END FOR 
			ELSE 
				IF l_status < 0 THEN 
					EXIT INPUT 
				END IF 
				LET glob_arr_rec_tentpays[l_curr].inv_text = l_rec_s_tentpays.inv_text 
				LET glob_arr_rec_tentpays[l_curr].vend_code = l_rec_s_tentpays.vend_code 
				LET glob_arr_rec_tentpays[l_curr].vouch_code = l_rec_s_tentpays.vouch_code 
				LET glob_arr_rec_tentpays[l_curr].due_date = l_rec_s_tentpays.due_date 
				LET glob_arr_rec_tentpays[l_curr].vouch_amt = l_rec_s_tentpays.vouch_amt 
				LET glob_arr_rec_tentpays[l_curr].taken_disc_amt = l_rec_s_tentpays.taken_disc_amt 
				LET glob_arr_rec_tentpays[l_curr].withhold_tax_ind = l_rec_s_tentpays.withhold_tax_ind 
				LET glob_arr_rec_tentpays[l_curr].pay_meth_ind = l_rec_s_tentpays.pay_meth_ind 
				LET l_arr_rec_source_ind[l_curr].source_ind = l_rec_s_tentpays.source_ind 
				DISPLAY glob_arr_rec_tentpays[l_curr].* 
				TO sr_tentpays[l_scrn].* 

				LET l_total_to_pay = l_total_to_pay + glob_arr_rec_tentpays[l_curr].vouch_amt 
				DISPLAY l_total_to_pay TO total_pay 
			END IF 
--			OPTIONS INSERT KEY f1, 
--			DELETE KEY f36 
		AFTER ROW 
			DISPLAY glob_arr_rec_tentpays[l_idx].* TO sr_tentpays[glob_scrn].* 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN TRUE 
	ELSE 
		IF l_status < 0 THEN 
			RETURN FALSE 
		END IF 
		IF l_del_cnt > 0 THEN 
			IF NOT check_tenthead_status(glob_cycle_num,2) THEN 
				RETURN FALSE 
			END IF 
			LET l_msgresp = kandoomsg("U",8001,l_del_cnt) 
			#8060 Confirm TO Delete VALUE rows...
			IF l_msgresp = "Y" THEN 
--				WHENEVER ERROR GOTO recovery3 
--				GOTO bypass3 
--				LABEL recovery3: 
--				IF error_recover(glob__error_text,status) != "Y" THEN 
--					RETURN TRUE 
--				END IF 
--				LABEL bypass3: 
				BEGIN WORK 
				LET glob__error_text = "Problem Deleting a Tentative Payment - P33" 
				FOR l_idx = 1 TO arr_count() 
					IF glob_arr_rec_tentpays[l_idx].scroll_flag = "*" THEN 
						DELETE FROM tentpays 
						WHERE vend_code = glob_arr_rec_tentpays[l_idx].vend_code 
					AND vouch_code = glob_arr_rec_tentpays[l_idx].vouch_code 
					END IF 
				END FOR 
				COMMIT WORK 
--				WHENEVER ERROR CONTINUE 
			END IF 
		END IF 
		RETURN TRUE 
	END IF 
END FUNCTION 

############################################################
# FUNCTION construct_dataset_tentpays_2()
#
#
############################################################
FUNCTION construct_dataset_tentpays_2() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_where_text STRING

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT l_where_text ON tentpays.vend_code, 
		tentpays.vouch_code, 
		tentpays.due_date, 
		tentpays.vouch_amt, 
		tentpays.disc_date, 
		tentpays.taken_disc_amt, 
		tentpays.withhold_tax_ind, 
		tentpays.pay_meth_ind 
	FROM tentpays.vend_code, 
		tentpays.vouch_code, 
		tentpays.due_date, 
		tentpays.vouch_amt, 
		tentpays.disc_date, 
		tentpays.taken_disc_amt, 
		tentpays.withhold_tax_ind, 
		tentpays.pay_meth_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P33","construct-tentpays-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE,"" 
	END IF 
	RETURN TRUE,l_where_text 
END FUNCTION 



############################################################
# FUNCTION process_tentpays2()
#
#
############################################################
FUNCTION process_tentpays2(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_recalc_ind CHAR(1) 
	DEFINE l_status INTEGER 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_pr_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_curr SMALLINT 
	DEFINE l_line SMALLINT 
	DEFINE l_next SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_cnt2 SMALLINT #, pr_coun AND pr_scrnt NOT used 
	DEFINE l_total_to_pay DECIMAL(14,2) 
	DEFINE l_curr_code LIKE vendor.currency_code 
	DEFINE l_query_text STRING
	DEFINE l_rec_s_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_tentpay2 RECORD 
		vend_code LIKE tentpays.vend_code, 
		vouch_code LIKE tentpays.vouch_code, 
		due_date LIKE tentpays.due_date, 
		vouch_amt LIKE tentpays.vouch_amt, 
		disc_date LIKE tentpays.disc_date, 
		taken_disc_amt LIKE tentpays.taken_disc_amt, 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind, 
		pay_meth_ind LIKE tentpays.pay_meth_ind, 
		source_ind LIKE tentpays.source_ind 
	END RECORD 
	DEFINE l_arr_rec_source_ind DYNAMIC ARRAY OF RECORD 
		source_ind LIKE tentpays.source_ind 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE prp_tentpays_statusind_2 PREPARED
	DEFINE crs_tentpays_statusind_2 CURSOR
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database - please wait
	LET l_query_text = " SELECT '*',",
	" vend_code, ", 
	"vouch_code, ", 
	"due_date, ", 
	"vouch_amt, ", 
	"disc_date,", 
	"taken_disc_amt, ", 
	"withhold_tax_ind, ", 
	"pay_meth_ind, ", 
	"source_ind ", 
	"FROM tentpays ", 
	"WHERE cmpy_code = ? ",
	"AND cycle_num = ? ",
	"AND status_ind = '1' ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY pay_meth_ind, ", 
	"vend_code, ", 
	"withhold_tax_ind, ", 
	"vouch_code" 

	CALL prp_tentpays_statusind_2.Prepare(l_query_text)
	CALL crs_tentpays_statusind_2.Declare(prp_tentpays_statusind_2)
	CALL crs_tentpays_statusind_2.Open(glob_rec_kandoouser.cmpy_code,glob_cycle_num)

	LET l_idx = 1 
	LET l_total_to_pay = 0 
	LET l_recalc_ind = NULL 

	# As a horrible trick, we set glob_arr_rec_tentpays[1].* to NULL so that it can be passed as a dummy argument
	INITIALIZE glob_arr_rec_tentpays[1].* TO NULL
	WHILE crs_tentpays_statusind_2.FetchNext(glob_arr_rec_tentpays2[l_idx].*) = 0
		LET l_idx = l_idx + 1 
	END WHILE # crs_tentpays_statusind_2 
	# Delete last element which is empty (l_idx ahead of records)
	CALL glob_arr_rec_tentpays2.Delete(l_idx)
	LET l_idx = l_idx -1
	
	LET l_msgresp = kandoomsg("U","9113",l_idx) 
	#9133 l_idx records selected
	DISPLAY l_total_to_pay TO total_pay 

	IF l_idx > 0 THEN 
		SELECT currency_code INTO l_curr_code 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = glob_arr_rec_tentpays2[l_idx].vend_code 
		DISPLAY l_curr_code TO currency_code 
		attribute(green) 
	END IF 

	LET l_del_cnt = 0 
	LET l_msgresp = kandoomsg("P",1053,"") 
	#1053 RETURN TO Edit - F1 TO Add - F2 TO Delete - F9 TO View Voucher"
	INPUT ARRAY glob_arr_rec_tentpays2 WITHOUT DEFAULTS FROM sr_tentpays.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P33","inp-arr-tentpays-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW
			LET l_idx = arr_curr() 
			LET glob_scrn = scr_line() 

		BEFORE FIELD scroll_flag 
--			LET l_scroll_flag = glob_arr_rec_tentpays2[l_idx].scroll_flag 
--			DISPLAY glob_arr_rec_tentpays2[l_idx].* 
--			TO sr_tentpays[glob_scrn].* 

			--OPTIONS INSERT KEY f1, 
			--DELETE KEY f36 
		AFTER FIELD scroll_flag 
			LET glob_arr_rec_tentpays2[l_idx].scroll_flag = l_scroll_flag 
			DISPLAY glob_arr_rec_tentpays2[l_idx].* 
			TO sr_tentpays[glob_scrn].* 

		BEFORE FIELD vend_code 
			IF l_arr_rec_source_ind[l_idx].source_ind = "S" THEN #sundry payment 
				NEXT FIELD scroll_flag 
			END IF 
			IF glob_arr_rec_tentpays2[l_idx].vend_code IS NOT NULL THEN 
				CALL process_automatic_payment(l_idx,MODE_CLASSIC_EDIT,glob_arr_rec_tentpays[1].*,glob_arr_rec_tentpays2[l_idx].*) # MODE 
				RETURNING l_status, l_rec_s_tentpays.* 
				IF l_status THEN 
					LET l_total_to_pay = l_total_to_pay + l_rec_s_tentpays.vouch_amt - glob_arr_rec_tentpays2[l_idx].vouch_amt 
					LET glob_arr_rec_tentpays2[l_idx].disc_date = l_rec_s_tentpays.disc_date 
					LET glob_arr_rec_tentpays2[l_idx].vouch_amt = l_rec_s_tentpays.vouch_amt 
					LET glob_arr_rec_tentpays2[l_idx].due_date = l_rec_s_tentpays.due_date 
					LET glob_arr_rec_tentpays2[l_idx].taken_disc_amt = l_rec_s_tentpays.taken_disc_amt 
					LET glob_arr_rec_tentpays2[l_idx].withhold_tax_ind = l_rec_s_tentpays.withhold_tax_ind 
					LET glob_arr_rec_tentpays2[l_idx].pay_meth_ind = l_rec_s_tentpays.pay_meth_ind 
					LET l_arr_rec_source_ind[l_idx].source_ind = l_rec_s_tentpays.source_ind 
					DISPLAY l_total_to_pay TO total_pay 
				END IF 
				DISPLAY glob_arr_rec_tentpays2[l_idx].* 
				TO sr_tentpays[glob_scrn].* 

			END IF 
--			OPTIONS INSERT KEY f1, 
--			DELETE KEY f36 
--			NEXT FIELD scroll_flag 

		ON ACTION "Cancel This Payment"   # ON KEY (F2) 
			IF glob_arr_rec_tentpays2[l_idx].scroll_flag IS NULL THEN 
				LET glob_arr_rec_tentpays2[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
				LET l_total_to_pay = l_total_to_pay - glob_arr_rec_tentpays2[l_idx].vouch_amt 
				DISPLAY l_total_to_pay TO total_pay 
			ELSE 
				LET glob_arr_rec_tentpays2[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
				LET l_total_to_pay = l_total_to_pay + glob_arr_rec_tentpays2[l_idx].vouch_amt 
				DISPLAY l_total_to_pay TO total_pay 
			END IF 
			NEXT FIELD scroll_flag 
		
		ON ACTION "Show Voucher"   --ON KEY (F9) 
			IF glob_arr_rec_tentpays2[l_idx].vouch_code IS NOT NULL THEN 
				CALL display_voucher_header(glob_rec_kandoouser.cmpy_code, glob_arr_rec_tentpays2[l_idx].vouch_code) 
			END IF 
			NEXT FIELD scroll_flag 

		ON ACTION "Cancel All Payments" # ON KEY (F10) 
			FOR l_pr_cnt = 1 TO arr_count() 
				IF glob_arr_rec_tentpays2[l_pr_cnt].vend_code IS NOT NULL THEN 
					IF glob_arr_rec_tentpays2[l_pr_cnt].scroll_flag IS NULL THEN 
						LET glob_arr_rec_tentpays2[l_pr_cnt].scroll_flag = "*" 
						LET l_del_cnt = l_del_cnt + 1 
						LET l_total_to_pay = l_total_to_pay - glob_arr_rec_tentpays2[l_pr_cnt].vouch_amt 
					ELSE 
						LET glob_arr_rec_tentpays2[l_pr_cnt].scroll_flag = NULL 
						LET l_del_cnt = l_del_cnt - 1 
						LET l_total_to_pay = l_total_to_pay + glob_arr_rec_tentpays2[l_pr_cnt].vouch_amt 
					END IF 
				END IF 
			END FOR 
			LET l_curr = arr_curr() 
			LET l_line = scr_line() 
			LET l_next = (l_curr - l_line) + 1 
			LET l_scrn = 1 
			FOR l_cnt2 = l_next TO (l_next + (glob_max_screen + 1)) 
				IF l_cnt2 <= arr_count() THEN 
					IF l_scrn <= glob_max_screen THEN 
						DISPLAY glob_arr_rec_tentpays2[l_cnt2].scroll_flag 
						TO sr_tentpays[l_scrn].scroll_flag 

						LET l_scrn = l_scrn + 1 
					END IF 
				END IF 
			END FOR 
			LET glob_scrn = scr_line() 
			DISPLAY l_total_to_pay TO total_pay 

			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			LET l_curr = arr_curr() 
			LET l_pr_cnt = arr_count() 
			LET l_scrn = scr_line() 
			FOR l_idx = arr_count() TO (arr_curr() + 1) step - 1 
				LET l_arr_rec_source_ind[l_idx].* = l_arr_rec_source_ind[l_idx-1].* 
			END FOR 
			INITIALIZE l_arr_rec_source_ind[l_idx].* TO NULL 
			CALL process_automatic_payment(0, "ADD",glob_arr_rec_tentpays[1].*,glob_arr_rec_tentpays2[l_idx].*) 
			RETURNING l_status, l_rec_s_tentpays.* 
			IF NOT l_status THEN 
				IF l_status < 0 THEN 
					EXIT INPUT 
				END IF 
				FOR l_idx = l_curr TO l_pr_cnt 
					IF (l_idx + 1) <= glob_max_array THEN 
						IF glob_arr_rec_tentpays2[l_idx+1].vend_code IS NOT NULL THEN 
							LET glob_arr_rec_tentpays2[l_idx].* = glob_arr_rec_tentpays2[l_idx+1].* 
							LET l_arr_rec_source_ind[l_idx].* = l_arr_rec_source_ind[l_idx+1].* 
						ELSE 
							INITIALIZE glob_arr_rec_tentpays2[l_idx].* TO NULL 
							INITIALIZE l_arr_rec_source_ind[l_idx].* TO NULL 
						END IF 
					ELSE 
						INITIALIZE glob_arr_rec_tentpays2[l_idx].* TO NULL 
						INITIALIZE l_arr_rec_source_ind[l_idx].* TO NULL 
					END IF 
					IF l_scrn <= glob_max_screen THEN 
						DISPLAY glob_arr_rec_tentpays2[l_idx].* TO sr_tentpays[l_scrn].* 

						LET l_scrn = l_scrn + 1 
					END IF 
				END FOR 
			ELSE 
				LET glob_arr_rec_tentpays2[l_curr].disc_date = l_rec_s_tentpays.disc_date 
				LET glob_arr_rec_tentpays2[l_curr].vend_code = l_rec_s_tentpays.vend_code 
				LET glob_arr_rec_tentpays2[l_curr].vouch_code = l_rec_s_tentpays.vouch_code 
				LET glob_arr_rec_tentpays2[l_curr].due_date = l_rec_s_tentpays.due_date 
				LET glob_arr_rec_tentpays2[l_curr].vouch_amt = l_rec_s_tentpays.vouch_amt 
				LET glob_arr_rec_tentpays2[l_curr].withhold_tax_ind = l_rec_s_tentpays.withhold_tax_ind 
				LET glob_arr_rec_tentpays2[l_curr].taken_disc_amt = l_rec_s_tentpays.taken_disc_amt 
				LET glob_arr_rec_tentpays2[l_curr].pay_meth_ind = l_rec_s_tentpays.pay_meth_ind 
				LET l_arr_rec_source_ind[l_curr].source_ind = l_rec_s_tentpays.source_ind 
				DISPLAY glob_arr_rec_tentpays2[l_curr].* 
				TO sr_tentpays[l_scrn].* 

				LET l_total_to_pay = l_total_to_pay + glob_arr_rec_tentpays2[l_curr].vouch_amt 
				DISPLAY l_total_to_pay TO total_pay 
			END IF 
--			OPTIONS INSERT KEY f1, 
--			DELETE KEY f36 

		AFTER ROW 
			DISPLAY glob_arr_rec_tentpays2[l_idx].* TO sr_tentpays[glob_scrn].* 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN TRUE 
	ELSE 
		IF l_status < 0 THEN 
			RETURN FALSE 
		END IF 
		IF l_del_cnt > 0 THEN 
			IF NOT check_tenthead_status(glob_cycle_num,2) THEN 
				RETURN FALSE 
			END IF 
			LET l_msgresp = kandoomsg("U",8001,l_del_cnt) 
			#8060 Confirm TO Delete VALUE rows...
			IF l_msgresp = "Y" THEN 
--				WHENEVER ERROR GOTO recovery1 
--				GOTO bypass1 
--				LABEL recovery1: 
--				IF error_recover(glob__error_text,status) != "Y" THEN 
--					RETURN TRUE 
--				END IF 
--				LABEL bypass1: 
				BEGIN WORK 
					LET glob__error_text = "Problem Deleting a Tentative Payment - P33" 
					FOR l_idx = 1 TO arr_count() 
						IF glob_arr_rec_tentpays2[l_idx].scroll_flag = "*" THEN 
							DELETE FROM tentpays 
							WHERE vend_code = glob_arr_rec_tentpays2[l_idx].vend_code 
							AND vouch_code = glob_arr_rec_tentpays2[l_idx].vouch_code 
						END IF 
					END FOR 
				COMMIT WORK 
				WHENEVER ERROR CONTINUE 
			END IF 
		END IF 
		RETURN TRUE 
	END IF 
END FUNCTION 

############################################################
# FUNCTION process_automatic_payment(p_idx, p_mode)
#
#
############################################################
FUNCTION process_automatic_payment(p_idx, p_mode,p_rec_tentpays,p_rec_tentpays2) 
	DEFINE p_rec_tentpays t_rec_tentpays
	DEFINE p_rec_tentpays2 t_rec_tentpays2
	DEFINE p_idx SMALLINT
	DEFINE p_mode CHAR(4) 
 	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_status INTEGER 
	DEFINE l_disc_taken_ind CHAR(1) 
	DEFINE l_recalc_ind CHAR(1) 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_count SMALLINT 
	DEFINE l_kandoo_voucher_amt LIKE tentpays.vouch_amt 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	#DEFINE #pr_apparms   RECORD LIKE apparms.*
	#DEFINE l_tentpays1 RECORD LIKE tentpays.*
	DEFINE l_rec_tentpays2 RECORD LIKE tentpays.* 
	DEFINE l_rec_s_tentpays RECORD 
		vend_code LIKE tentpays.vend_code, 
		vouch_code LIKE tentpays.vouch_code, 
		due_date LIKE tentpays.due_date, 
		vouch_amt LIKE tentpays.vouch_amt, 
		taken_disc_amt LIKE tentpays.taken_disc_amt, 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind, 
		pay_meth_ind LIKE tentpays.pay_meth_ind 
	END RECORD 
	DEFINE l_pay_meth_ind LIKE vouchpayee.pay_meth_ind 

	OPEN WINDOW p233 with FORM "P233" 
	CALL windecoration_p("P233") 

	LET l_msgresp = kandoomsg("U","1020","Automatic Payment") 
	#U1020 Enter Automatic Payment Details; OK TO Continue...
	CASE p_mode 
		WHEN MODE_CLASSIC_EDIT 
			### Assign Values ###
			IF glob_option = "2" THEN 
				LET l_rec_s_tentpays.vend_code = p_rec_tentpays.vend_code 
				LET l_rec_s_tentpays.vouch_code = p_rec_tentpays.vouch_code 
				LET l_rec_s_tentpays.due_date = p_rec_tentpays.due_date 
				LET l_rec_s_tentpays.vouch_amt = p_rec_tentpays.vouch_amt 
				LET l_rec_s_tentpays.taken_disc_amt = p_rec_tentpays.taken_disc_amt 
				LET l_rec_s_tentpays.withhold_tax_ind = p_rec_tentpays.withhold_tax_ind 
				LET l_rec_s_tentpays.pay_meth_ind = p_rec_tentpays.pay_meth_ind 
			ELSE 
				LET l_rec_s_tentpays.vend_code = p_rec_tentpays2.vend_code 
				LET l_rec_s_tentpays.vouch_code = p_rec_tentpays2.vouch_code 
				LET l_rec_s_tentpays.due_date = p_rec_tentpays2.due_date 
				LET l_rec_s_tentpays.vouch_amt = p_rec_tentpays2.vouch_amt 
				LET l_rec_s_tentpays.taken_disc_amt = p_rec_tentpays2.taken_disc_amt 
				LET l_rec_s_tentpays.withhold_tax_ind = p_rec_tentpays2.withhold_tax_ind 
				LET l_rec_s_tentpays.pay_meth_ind = p_rec_tentpays2.pay_meth_ind 
			END IF 
			CASE l_rec_s_tentpays.pay_meth_ind 
				WHEN 1 
					DISPLAY "Auto/Manual Payment" TO payment_desc 
				WHEN 2 
					DISPLAY "" TO payment_desc 
				WHEN 3 
					DISPLAY "EFT Payment" TO payment_desc 
				WHEN 4 
					DISPLAY "" TO payment_desc 
			END CASE 
			SELECT * INTO l_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_s_tentpays.vend_code 
			DISPLAY BY NAME l_rec_s_tentpays.vend_code, 
				l_rec_vendor.name_text, 
				l_rec_s_tentpays.vouch_code, 
				l_rec_s_tentpays.due_date, 
				l_rec_s_tentpays.vouch_amt, 
				l_rec_s_tentpays.taken_disc_amt, 
				l_rec_s_tentpays.withhold_tax_ind, 
				l_rec_s_tentpays.pay_meth_ind 
		OTHERWISE 
			INITIALIZE l_rec_s_tentpays.* TO NULL 
	END CASE 

	INPUT BY NAME l_rec_s_tentpays.* WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P33","inp-tentpays-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD vend_code 
			IF p_mode = MODE_CLASSIC_EDIT THEN 
				NEXT FIELD due_date 
			ELSE 
				IF l_recalc_ind IS NULL THEN 
					CASE get_kandoooption_feature_state("AP","PT") 
						WHEN '1' 
							LET l_recalc_ind = 'N' 
						WHEN '2' 
							LET l_recalc_ind = 'Y' 
						WHEN '3' 
							LET l_recalc_ind = kandoomsg("P",1503,"") 
							#A1503 Override invoice discount settings (Y/N)
					END CASE 
				END IF 
			END IF 

		AFTER FIELD vend_code 
			IF l_rec_s_tentpays.vend_code IS NOT NULL THEN 
				SELECT * INTO l_rec_vendor.* 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_s_tentpays.vend_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P","9105","") 
					#P9105 - Vendor NOT found...
					NEXT FIELD vend_code 
				ELSE 
					DISPLAY BY NAME l_rec_vendor.name_text 
				END IF 
				IF l_rec_vendor.hold_code IS NOT NULL THEN #and 
					#l_rec_vendor.hold_code <> "NOT" THEN
					LET l_msgresp = kandoomsg("P",9574,"") 
					# 9574 Vendor on hold.
					NEXT FIELD vend_code 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("P","9105","") 
				#P9105 - Vendor NOT found...
				NEXT FIELD vend_code 
			END IF 

		AFTER FIELD vouch_code 
			SELECT * INTO l_rec_voucher.* 
			FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_s_tentpays.vend_code 
				AND vouch_code = l_rec_s_tentpays.vouch_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9122,"") 
				#9122 Voucher NOT found
				NEXT FIELD vouch_code 
			END IF 
			IF l_rec_voucher.approved_code != "Y" THEN 
				LET l_msgresp = kandoomsg("P",9080,"") 
				NEXT FIELD vouch_code 
			END IF 
			IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
				LET l_msgresp = kandoomsg("P",1057,"") 
				#1057 Voucher has already been paid
				NEXT FIELD vouch_code 
			END IF 
			#IF l_rec_voucher.hold_code != "NO"
			IF l_rec_voucher.hold_code IS NOT NULL THEN 
				LET l_msgresp = kandoomsg("P",9573,"") 
				#9573 Voucher IS on hold
				NEXT FIELD vouch_code 
			END IF 
			SELECT count(*) INTO l_count 
			FROM tentpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_s_tentpays.vend_code 
				AND vouch_code = l_rec_s_tentpays.vouch_code 
			IF l_count != 0 THEN 
				LET l_msgresp = kandoomsg("P",9055,"") 
				#9055 Voucher payment already exists
				NEXT FIELD vend_code 
			END IF 
			LET l_rec_s_tentpays.due_date = l_rec_voucher.due_date 
			LET l_rec_s_tentpays.taken_disc_amt = 0 
			LET l_rec_s_tentpays.withhold_tax_ind = l_rec_voucher.withhold_tax_ind 

			SELECT pay_meth_ind INTO l_pay_meth_ind 
			FROM vouchpayee 
			WHERE vend_code = l_rec_voucher.vend_code 
				AND vouch_code = l_rec_voucher.vouch_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_rec_s_tentpays.pay_meth_ind = l_rec_vendor.pay_meth_ind 
			ELSE 
				LET l_rec_s_tentpays.pay_meth_ind = l_pay_meth_ind 
			END IF 
			DISPLAY BY NAME l_rec_s_tentpays.pay_meth_ind, 
				l_rec_s_tentpays.withhold_tax_ind 

			CASE l_rec_s_tentpays.pay_meth_ind 
				WHEN 1 
					DISPLAY "Auto/Manual Payment" TO payment_desc 
				WHEN 2 
					DISPLAY "" TO payment_desc 
				WHEN 3 
					DISPLAY "EFT Payment" TO payment_desc 
				WHEN 4 
					DISPLAY "" TO payment_desc 
			END CASE 
			IF l_recalc_ind IS NOT NULL THEN 
				IF l_recalc_ind = 'Y' THEN 
					LET l_rec_s_tentpays.taken_disc_amt = l_rec_voucher.goods_amt * (show_disc(glob_rec_kandoouser.cmpy_code, l_rec_voucher.term_code, today, l_rec_voucher.vouch_date) /100) 
					IF l_rec_s_tentpays.taken_disc_amt != 0 THEN 
						IF l_disc_taken_ind IS NULL THEN 
							LET l_disc_taken_ind = kandoomsg("P",1504,"") 
							#P1504 Apply settlement discount ? (Y/N)
						END IF 
					END IF 
					IF l_disc_taken_ind IS NOT NULL AND l_disc_taken_ind = "N" THEN 
						LET l_rec_s_tentpays.taken_disc_amt = 0 
					END IF 
				ELSE 
					IF today <= l_rec_voucher.disc_date THEN 
						LET l_rec_s_tentpays.taken_disc_amt = l_rec_voucher.poss_disc_amt 
					END IF 
				END IF 
			END IF 
			LET l_rec_s_tentpays.vouch_amt = l_rec_voucher.total_amt - l_rec_voucher.paid_amt - l_rec_s_tentpays.taken_disc_amt 
			DISPLAY l_rec_voucher.withhold_tax_ind TO tentpays.withhold_tax_ind 

			DISPLAY BY NAME l_rec_s_tentpays.* 

		AFTER FIELD due_date 
--			IF p_mode = MODE_CLASSIC_EDIT THEN 
--				IF (fgl_lastkey() = fgl_keyval("up") 
--				OR fgl_lastkey() = fgl_keyval("left")) THEN 
--					NEXT FIELD due_date 
--				END IF 
--			END IF 
		BEFORE FIELD vouch_amt 
			LET l_kandoo_voucher_amt = l_rec_s_tentpays.vouch_amt 

		AFTER FIELD vouch_amt 
			IF (l_rec_s_tentpays.vouch_amt <= 0) THEN 
				LET l_msgresp = kandoomsg("P",1058,"") 
				#P1058 Cheque amount must be greater than zero
				NEXT FIELD vouch_amt 
			ELSE 
				LET l_kandoo_voucher_amt = l_rec_s_tentpays.vouch_amt 
			END IF 
			
			IF l_rec_s_tentpays.vouch_amt < l_kandoo_voucher_amt THEN 
				LET l_rec_s_tentpays.taken_disc_amt = 0 
				DISPLAY BY NAME l_rec_s_tentpays.taken_disc_amt 
			END IF 

			AFTER FIELD taken_disc_amt 
			IF (l_rec_s_tentpays.taken_disc_amt < 0) THEN 
				LET l_msgresp = kandoomsg("P",9189,"") 
				#P9189 Discount amount cannot be negative
				NEXT FIELD taken_disc_amt 
			END IF 
			IF (l_rec_s_tentpays.taken_disc_amt + l_rec_s_tentpays.vouch_amt + l_rec_voucher.paid_amt) > l_rec_voucher.total_amt THEN 
				LET l_msgresp = kandoomsg("P",9057,"") 
				#9057 This amount will overpay the voucher
				LET l_rec_s_tentpays.vouch_amt = l_kandoo_voucher_amt 
				DISPLAY BY NAME l_rec_s_tentpays.vouch_amt 
				NEXT FIELD vouch_amt 
			END IF 
			IF (l_rec_s_tentpays.taken_disc_amt > 0) AND ((l_rec_s_tentpays.taken_disc_amt + l_rec_s_tentpays.vouch_amt + l_rec_voucher.paid_amt) < l_rec_voucher.total_amt) THEN 
				LET l_msgresp = kandoomsg("P",9056,"") 
				#9056 Payment must be complete TO claim discount
				LET l_rec_s_tentpays.taken_disc_amt = 0 
				DISPLAY BY NAME l_rec_s_tentpays.taken_disc_amt 
				NEXT FIELD vouch_amt 
			END IF 

		ON KEY (control-b) 
			CASE 
				WHEN infield(vend_code) 
					LET l_winds_text = NULL 
					LET l_winds_text = show_vend(glob_rec_kandoouser.cmpy_code,l_rec_s_tentpays.vend_code) 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_s_tentpays.vend_code = l_winds_text 
						DISPLAY BY NAME l_rec_s_tentpays.vend_code 
					END IF 
					NEXT FIELD vend_code 
			END CASE 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF p_mode = "ADD" THEN 
					IF l_recalc_ind IS NULL THEN 
						CASE get_kandoooption_feature_state("AP","PT") 
							WHEN '1' 
								LET l_recalc_ind = 'N' 
							WHEN '2' 
								LET l_recalc_ind = 'Y' 
							WHEN '3' 
								LET l_recalc_ind = kandoomsg("P",1503,"") 
								#A1503 Override invoice discount settings (Y/N)
						END CASE 
					END IF 
					SELECT * INTO l_rec_vendor.* 
					FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_s_tentpays.vend_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("P","9105","") 
						#P9105 - Vendor NOT found...
						NEXT FIELD vend_code 
					ELSE 
						DISPLAY BY NAME l_rec_vendor.name_text 

					END IF 
					IF l_rec_vendor.hold_code IS NOT NULL THEN #and 
						#l_rec_vendor.hold_code <> "NOT" THEN
						LET l_msgresp = kandoomsg("P",9574,"") 
						# 9574 Vendor on hold.
						NEXT FIELD vend_code 
					END IF 
					SELECT * INTO l_rec_voucher.* 
					FROM voucher 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vend_code = l_rec_s_tentpays.vend_code 
						AND vouch_code = l_rec_s_tentpays.vouch_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("P",9122,"") 
						#9122 Voucher NOT found
						NEXT FIELD vouch_code 
					END IF 
					IF l_rec_voucher.approved_code != "Y" THEN 
						LET l_msgresp = kandoomsg("P",9080,"") 
						NEXT FIELD vouch_code 
					END IF 
					#IF l_rec_voucher.hold_code != "NO"
					IF l_rec_voucher.hold_code IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("P",9573,"") 
						#9573 Voucher IS on hold
						NEXT FIELD vouch_code 
					END IF 
					IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
						LET l_msgresp = kandoomsg("P",1057,"") 
						#1057 Voucher has already been paid
						NEXT FIELD vouch_code 
					END IF 
					SELECT count(*) INTO l_count 
					FROM tentpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vend_code = l_rec_s_tentpays.vend_code 
						AND vouch_code = l_rec_s_tentpays.vouch_code 
					IF l_count != 0 THEN 
						LET l_msgresp = kandoomsg("P",9055,"") 
						#9055 Voucher payment already exists
						NEXT FIELD vend_code 
					END IF 
				ELSE 
					SELECT * INTO l_rec_voucher.* 
					FROM voucher 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vend_code = l_rec_s_tentpays.vend_code 
						AND vouch_code = l_rec_s_tentpays.vouch_code 
				END IF 
				IF l_recalc_ind IS NOT NULL THEN 
					IF l_recalc_ind = 'Y' THEN 
						LET l_rec_s_tentpays.taken_disc_amt = l_rec_voucher.goods_amt * (show_disc(glob_rec_kandoouser.cmpy_code, l_rec_voucher.term_code, today,l_rec_voucher.vouch_date) /100) 
						IF l_rec_s_tentpays.taken_disc_amt != 0 THEN 
							IF l_disc_taken_ind IS NULL THEN 
								LET l_disc_taken_ind = kandoomsg("P",1504,"") 
								#P1504 Apply settlement discount ? (Y/N)
							END IF 
						END IF 
						IF l_disc_taken_ind IS NOT NULL AND l_disc_taken_ind = "N" THEN 
							LET l_rec_s_tentpays.taken_disc_amt = 0 
						END IF 
					ELSE 
						IF today <= l_rec_voucher.disc_date THEN 
							LET l_rec_s_tentpays.taken_disc_amt = l_rec_voucher.poss_disc_amt 
						END IF 
					END IF 
				END IF 
				IF (l_rec_s_tentpays.vouch_amt <= 0) THEN 
					LET l_msgresp = kandoomsg("P",1058,"") 
					#P1058 Cheque amount must be greater than zero
					NEXT FIELD vouch_amt 
				END IF 
				IF (l_rec_s_tentpays.taken_disc_amt < 0) THEN 
					LET l_msgresp = kandoomsg("P",9189,"") 
					#P9189 Discount amount cannot be negative
					NEXT FIELD taken_disc_amt 
				END IF 
				IF (l_rec_s_tentpays.taken_disc_amt + l_rec_s_tentpays.vouch_amt + l_rec_voucher.paid_amt) > l_rec_voucher.total_amt THEN 
					LET l_msgresp = kandoomsg("P",9057,"") 
					#9057 This amount will overpay the voucher
					LET l_rec_s_tentpays.vouch_amt = l_kandoo_voucher_amt 
					DISPLAY BY NAME l_rec_s_tentpays.vouch_amt 

					NEXT FIELD vouch_amt 
				END IF 
				IF (l_rec_s_tentpays.taken_disc_amt > 0) AND ((l_rec_s_tentpays.taken_disc_amt + l_rec_s_tentpays.vouch_amt + l_rec_voucher.paid_amt) < l_rec_voucher.total_amt) THEN 
					LET l_msgresp = kandoomsg("P",9056,"") 
					#9056 Payment must be complete TO claim discount
					LET l_rec_s_tentpays.taken_disc_amt = 0 
					DISPLAY BY NAME l_rec_s_tentpays.taken_disc_amt 

					NEXT FIELD vouch_amt 
				END IF 
				IF p_mode = MODE_CLASSIC_EDIT THEN 
					IF (glob_arr_rec_tentpays[p_idx].vouch_amt != l_rec_s_tentpays.vouch_amt) 
					OR (glob_arr_rec_tentpays[p_idx].due_date != l_rec_s_tentpays.due_date ) 
					OR (glob_arr_rec_tentpays[p_idx].taken_disc_amt != l_rec_s_tentpays.taken_disc_amt) THEN 
						IF check_tenthead_status(glob_cycle_num,2) THEN 
							CALL write_tentpays(p_mode,1,l_rec_s_tentpays.vend_code,l_rec_s_tentpays.vouch_code,l_rec_s_tentpays.due_date,l_rec_s_tentpays.vouch_amt,l_rec_s_tentpays.taken_disc_amt) 
							RETURNING l_status, l_rec_tentpays2.*   #  TODO:check if tentpays2
							IF NOT l_status THEN 
								NEXT FIELD vouch_amt 
							END IF 
						ELSE 
							INITIALIZE l_rec_tentpays2.* TO NULL 
							LET l_status = -1 # means EXIT now 
						END IF 
					END IF 
				ELSE 
					IF check_tenthead_status(glob_cycle_num,2) THEN 
						CALL write_tentpays(p_mode,1,l_rec_s_tentpays.vend_code,l_rec_s_tentpays.vouch_code,l_rec_s_tentpays.due_date,l_rec_s_tentpays.vouch_amt,l_rec_s_tentpays.taken_disc_amt) 
						RETURNING l_status, l_rec_tentpays2.* 
						IF NOT l_status THEN 
							NEXT FIELD vouch_code 
						END IF 
					ELSE 
						INITIALIZE l_rec_tentpays2.* TO NULL 
						LET l_status = -1 # means EXIT now 
					END IF 
				END IF 
			END IF 
	END INPUT 
	CLOSE WINDOW p233 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		INITIALIZE l_rec_tentpays2.* TO NULL 
		RETURN FALSE, l_rec_tentpays2.* 
	ELSE 
		RETURN l_status, l_rec_tentpays2.* 
	END IF 
END FUNCTION  # process_automatic_payment

############################################################
# FUNCTION write_tentpays(p_mode,
#                        p_cycle_num,
#                        p_vend_code,
#                        p_vouch_code,
#                        p_due_date,
#                        p_vouch_amt,
#                        p_taken_disc_amt)
#
#
############################################################
FUNCTION write_tentpays(p_mode,p_cycle_num,p_vend_code,p_vouch_code,p_due_date,p_vouch_amt,p_taken_disc_amt) 
	DEFINE p_mode CHAR(4) 
	DEFINE p_cycle_num LIKE tentpays.cycle_num 
	DEFINE p_vend_code LIKE tentpays.vend_code 
	DEFINE p_vouch_code LIKE tentpays.vouch_code 
	DEFINE p_due_date LIKE tentpays.due_date 
	DEFINE p_vouch_amt LIKE tentpays.vouch_amt 
	DEFINE p_taken_disc_amt LIKE tentpays.taken_disc_amt 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_pay_meth_ind LIKE vouchpayee.pay_meth_ind 
	DEFINE l_status INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_error_text CHAR(60) 

	LET l_msgresp = kandoomsg("U","1005","") 
	#U1005 - Updating Database...
--	WHENEVER ERROR CONTINUE 
--	GOTO bypass5 
--	LABEL recovery5: 
--	IF error_recover(l_error_text,status) != "Y" THEN 
--		INITIALIZE l_rec_tentpays.* TO NULL 
--		RETURN FALSE, l_rec_tentpays.* 
--	END IF 
--	LABEL bypass5: 
--	WHENEVER ERROR GOTO recovery5 
	BEGIN WORK 
		CASE p_mode 
			WHEN "ADD" 
				INITIALIZE l_rec_tentpays.* TO NULL 
				LET l_rec_tentpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_tentpays.vend_code = p_vend_code 
				LET l_rec_tentpays.cycle_num = p_cycle_num 
				LET l_rec_tentpays.vouch_code = p_vouch_code 
				LET l_rec_tentpays.due_date = p_due_date 
				LET l_rec_tentpays.vouch_amt = p_vouch_amt 
				LET l_rec_tentpays.taken_disc_amt = p_taken_disc_amt 
				SELECT * INTO l_rec_vendor.* 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = p_vend_code 
				CALL get_whold_tax(glob_rec_kandoouser.cmpy_code,l_rec_vendor.vend_code,l_rec_vendor.type_code) 
				RETURNING l_rec_tentpays.withhold_tax_ind, l_rec_tentpays.tax_code, l_rec_tentpays.tax_per 
				#
				# Overide tax_ind FROM voucher
				#
				SELECT pay_meth_ind INTO l_pay_meth_ind 
				FROM vouchpayee 
				WHERE vend_code = p_vend_code 
					AND vouch_code = p_vouch_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_rec_tentpays.pay_meth_ind = l_rec_vendor.pay_meth_ind 
				ELSE 
					LET l_rec_tentpays.pay_meth_ind = l_pay_meth_ind 
				END IF 
				
				SELECT * INTO l_rec_voucher.* 
				FROM voucher 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = p_vend_code 
					AND vouch_code = p_vouch_code 
				IF l_rec_voucher.source_ind IS NOT NULL AND l_rec_voucher.source_ind = "8" THEN 
					LET l_rec_tentpays.source_ind = l_rec_voucher.source_ind 
					IF l_rec_voucher.source_text IS NULL THEN 
						LET l_rec_tentpays.source_text = p_vend_code 
					ELSE 
						LET l_rec_tentpays.source_text = l_rec_voucher.source_text 
					END IF 
				ELSE 
					IF l_pay_meth_ind IS NOT NULL THEN 
						# Sundry vendor
						LET l_rec_tentpays.source_ind = l_rec_voucher.source_ind 
						LET l_rec_tentpays.source_text = l_rec_voucher.vouch_code USING "&&&&&&&&" 
					ELSE 
						LET l_rec_tentpays.source_ind = "1" 
						LET l_rec_tentpays.source_text = p_vend_code 
					END IF 
				END IF 
				LET l_rec_tentpays.withhold_tax_ind = l_rec_voucher.withhold_tax_ind 
				LET l_rec_tentpays.disc_date = l_rec_voucher.disc_date 
				LET l_rec_tentpays.status_ind = 1 
				LET l_rec_tentpays.pay_doc_num = 0 
				LET l_rec_tentpays.page_num = 0 
				LET l_rec_tentpays.cheq_code = 0 
				LET l_rec_tentpays.vouch_date = l_rec_voucher.vouch_date 
				LET l_rec_tentpays.inv_text = l_rec_voucher.inv_text 
				LET l_rec_tentpays.total_amt = l_rec_voucher.total_amt 
				LET l_error_text = "Problems Inserting INTO Tentative Payments Table - P33" 
				INSERT INTO tentpays VALUES (l_rec_tentpays.*) 
			OTHERWISE 
				LET l_error_text = "Problems Updating Tentative Payments Table - P33" 
				UPDATE tentpays 
				SET due_date = p_due_date, 
					vouch_amt = p_vouch_amt, 
					taken_disc_amt = p_taken_disc_amt, 
					status_ind = 1 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = p_vend_code 
					AND vouch_code = p_vouch_code 
					AND cycle_num = p_cycle_num 
		END CASE 
	COMMIT WORK 
--	WHENEVER ERROR CONTINUE 
	IF p_mode != "ADD" THEN 
		SELECT * INTO l_rec_tentpays.* 
		FROM tentpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_vend_code 
			AND vouch_code = p_vouch_code 
			AND cycle_num = p_cycle_num 
	END IF 
	RETURN TRUE, l_rec_tentpays.* 
END FUNCTION 

############################################################
# FUNCTION check_tenthead_status(p_cycle_num,p_stage)
#
#
############################################################
FUNCTION check_tenthead_status(p_cycle_num,p_stage) 
	DEFINE p_cycle_num LIKE tentpays.cycle_num 
	DEFINE p_stage SMALLINT #1=begin p33 2=edit p33 
	DEFINE l_rec_tenthead RECORD LIKE tenthead.* 
	DEFINE l_status INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

--	WHENEVER ERROR GOTO recovery4 
--	GOTO bypass4 
--	LABEL recovery4: 
--	IF error_recover(glob__error_text,status) != "Y" THEN 
--		RETURN FALSE 
--	END IF 
--	LABEL bypass4: 
	SELECT * 
	INTO l_rec_tenthead.* 
	FROM tenthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = p_cycle_num 
--	LET l_status = status 
	CASE sqlca.sqlcode 
		WHEN 0 
			IF l_rec_tenthead.status_ind = 3 THEN 
				IF p_stage = 1 THEN 
					LET l_msgresp = kandoomsg("P","7055",l_rec_tenthead.entry_code) 
					#P7055  - Tentative Payments...
				ELSE 
					LET l_msgresp = kandoomsg("P","7080","") 
					#P7055  - WHILE editt...
				END IF 
				RETURN FALSE 
			ELSE 
				RETURN TRUE 
			END IF 
		OTHERWISE 
			IF p_stage = 1 THEN 
				LET l_msgresp = kandoomsg("P","7056","") 
				#P7056 - Tentative payments have NOT been loaded...
			ELSE 
				LET l_msgresp = kandoomsg("P","7081","") 
				#P7081 - WHILE editting, the Tentative payments have been...
			END IF 
			RETURN FALSE 
	END CASE 
END FUNCTION 