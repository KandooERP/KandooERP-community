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
# Purpose - Payments Register FOR Accounts Payable

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
--GLOBALS 
--	DEFINE glob_where_part STRING -- CHAR(2048)
--END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	#Initial UI Init
	CALL setModuleId("PR7") 
	CALL ui_init(0) 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	#######################################################################
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW P111 with FORM "P111" 
			CALL windecoration_p("P111") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
		
			MENU " Pay Register" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PR7","menu-pay_register-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PR7_rpt_process(PR7_rpt_query()) 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PR7_rpt_process(PR7_rpt_query()) 
		
				ON ACTION "Print Manager" 					#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" 					#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW P111

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PR7_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P111 with FORM "P111" 
			CALL windecoration_p("P111") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PR7_rpt_query()) #save where clause in env 
			CLOSE WINDOW P111 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PR7_rpt_process(get_url_sel_text())
	END CASE 
				 
END MAIN 


############################################################
# FUNCTION PR7_rpt_query()
#
#
############################################################
FUNCTION PR7_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON tentpays.vend_code, 
	tentpays.vouch_code, 
	tentpays.due_date, 
	tentpays.vouch_amt, 
	tentpays.disc_date, 
	tentpays.taken_disc_amt, 
	tentpays.withhold_tax_ind, 
	tentpays.pay_meth_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PR7","construct-tentpays-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text 
	END IF 
END FUNCTION 


############################################################
# FUNCTION PR1_rpt_process()
#
#
############################################################
FUNCTION PR7_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE l_rec_tentpays RECORD 
		vend_code LIKE tentpays.vend_code, 
		name_text LIKE vendor.name_text, 
		bal_amt LIKE vendor.bal_amt, 
		vouch_code LIKE tentpays.vouch_code, 
		due_date LIKE tentpays.due_date, 
		vouch_amt LIKE tentpays.vouch_amt, 
		disc_date LIKE tentpays.disc_date, 
		taken_disc_amt LIKE tentpays.taken_disc_amt , 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind, 
		tax_per LIKE tentpays.tax_per, 
		pay_meth_ind LIKE tentpays.pay_meth_ind 
	END RECORD 
	DEFINE l_query_text CHAR(2200)
	DEFINE l_msgresp LIKE language.yes_flag 
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PR7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PR7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT tentpays.vend_code,vendor.name_text,vendor.bal_amt,", 
	"tentpays.vouch_code,tentpays.due_date,tentpays.vouch_amt,", 
	"tentpays.disc_date,tentpays.taken_disc_amt,", 
	"tentpays.withhold_tax_ind, tentpays.tax_per, ", 
	"tentpays.pay_meth_ind ", 
	"FROM tentpays, vendor ", 
	"WHERE tentpays.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = tentpays.cmpy_code ", 
	"AND vendor.vend_code = tentpays.vend_code ", 
	"AND ", p_where_text clipped," ", 
	"ORDER BY tentpays.vend_code,", 
	"tentpays.withhold_tax_ind,", 
	"tentpays.vouch_code" 
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 




	FOREACH selcurs INTO l_rec_tentpays.* 
		DISPLAY l_rec_tentpays.name_text at 1,12 

			#---------------------------------------------------------
			OUTPUT TO REPORT PR7_rpt_list(l_rpt_idx,
			l_rec_tentpays.*) 
			IF NOT rpt_int_flag_handler2("Vendor:",l_rec_tentpays.name_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PR7_rpt_list
	CALL rpt_finish("PR7_rpt_list")
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
# REPORT PR7_rpt_list(p_rpt_idx,p_rec_tentpays)
#
#
############################################################
REPORT PR7_rpt_list(p_rpt_idx,p_rec_tentpays) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_tentpays RECORD 
		vend_code LIKE tentpays.vend_code, 
		name_text LIKE vendor.name_text, 
		bal_amt LIKE vendor.bal_amt, 
		vouch_code LIKE tentpays.vouch_code, 
		due_date LIKE tentpays.due_date, 
		vouch_amt LIKE tentpays.vouch_amt, 
		disc_date LIKE tentpays.disc_date, 
		taken_disc_amt LIKE tentpays.taken_disc_amt, 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind, 
		tax_per LIKE tentpays.tax_per, 
		pay_meth_ind LIKE tentpays.pay_meth_ind 
	END RECORD 
	DEFINE l_rec_currency RECORD LIKE currency.*
	DEFINE l_tot_pay_amt LIKE cheque.net_pay_amt
	DEFINE l_tot_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132)
	DEFINE l_last_page SMALLINT 
	DEFINE l_wtax_chq_amt LIKE cheque.net_pay_amt 
	DEFINE l_wtax_tax_amt LIKE cheque.net_pay_amt
	DEFINE l_tot_vend_pay LIKE cheque.net_pay_amt 
	DEFINE l_tot_vend_tax LIKE cheque.net_pay_amt
	DEFINE l_tot_ind_pay LIKE cheque.net_pay_amt 
	DEFINE l_tot_ind_tax LIKE cheque.net_pay_amt
	DEFINE i SMALLINT

	OUTPUT 
 
	ORDER BY p_rec_tentpays.pay_meth_ind, 
	p_rec_tentpays.vend_code, 
	p_rec_tentpays.withhold_tax_ind, 
	p_rec_tentpays.vouch_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			IF NOT l_last_page THEN 
				SELECT currency.* INTO l_rec_currency.* FROM currency, vendor 
				WHERE vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND currency.currency_code = vendor.currency_code 
				AND vendor.vend_code = p_rec_tentpays.vend_code 
				PRINT COLUMN 01, "Currency: ", 
				COLUMN 11, l_rec_currency.currency_code, 
				COLUMN 17, l_rec_currency.desc_text 
				IF p_rec_tentpays.pay_meth_ind = "1" THEN 
					PRINT COLUMN 01, "Payments by Cheque" 
				ELSE 
					PRINT COLUMN 01, "Payments by EFT" 
				END IF 
			ELSE 
				SKIP 2 LINES 
			END IF 

		BEFORE GROUP OF p_rec_tentpays.pay_meth_ind 
			LET l_tot_ind_pay = 0 
			LET l_tot_ind_tax = 0 
			LET l_last_page = false 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF p_rec_tentpays.vend_code 
			LET l_tot_vend_pay = 0 
			LET l_tot_vend_tax = 0 
			NEED 4 LINES 
			SKIP 1 line 
			PRINT COLUMN 02, "Vendor: ", 
			COLUMN 10, p_rec_tentpays.vend_code, 
			COLUMN 19, p_rec_tentpays.name_text, 
			COLUMN 57, "Balance: ", 
			COLUMN 66, p_rec_tentpays.bal_amt USING "----,---,--&.&&" 

		ON EVERY ROW 
			PRINT COLUMN 15, p_rec_tentpays.vouch_code USING "#######" , 
			COLUMN 25, p_rec_tentpays.due_date USING "dd/mm/yy", 
			COLUMN 35, p_rec_tentpays.vouch_amt USING "----,---,--&.&&", 
			COLUMN 51, p_rec_tentpays.disc_date USING "dd/mm/yy", 
			COLUMN 61, p_rec_tentpays.taken_disc_amt USING "----,--&.&&" 

		AFTER GROUP OF p_rec_tentpays.withhold_tax_ind 
			LET l_wtax_chq_amt = GROUP sum(p_rec_tentpays.vouch_amt) 
			NEED 5 LINES 
			IF p_rec_tentpays.withhold_tax_ind = "0" THEN 
				PRINT COLUMN 35, "---------------" 
				IF p_rec_tentpays.pay_meth_ind = "1" THEN 
					PRINT COLUMN 20, "Cheque Amount: "; 
				ELSE 
					PRINT COLUMN 20, " EFT Amount: "; 
				END IF 
				PRINT COLUMN 35, l_wtax_chq_amt USING "----,---,--&.&&" 
			ELSE 
				CALL wtaxcalc(l_wtax_chq_amt, 
				p_rec_tentpays.tax_per, 
				p_rec_tentpays.withhold_tax_ind, 
				glob_rec_kandoouser.cmpy_code) 
				RETURNING l_wtax_chq_amt, 
				l_wtax_tax_amt 
				PRINT COLUMN 35, "---------------" 
				PRINT COLUMN 19, "Taxable Amount: ", 
				COLUMN 35, GROUP sum(p_rec_tentpays.vouch_amt) 
				USING "----,---,--&.&&", 
				COLUMN 61, GROUP sum(p_rec_tentpays.taken_disc_amt) 
				USING "----,--&.&&" 
				PRINT COLUMN 25, "Less tax:", 
				COLUMN 35, (0 - l_wtax_tax_amt) USING "----,---,--&.&&" 
				IF p_rec_tentpays.pay_meth_ind = "1" THEN 
					PRINT COLUMN 20, "Cheque Amount: "; 
				ELSE 
					PRINT COLUMN 20, " EFT Amount: "; 
				END IF 
				PRINT COLUMN 35, l_wtax_chq_amt USING "----,---,--&.&&" 
				LET l_tot_vend_tax = l_tot_vend_tax + l_wtax_tax_amt 
			END IF 
			LET l_tot_vend_pay = l_tot_vend_pay + l_wtax_chq_amt 
			SKIP 1 line 
		AFTER GROUP OF p_rec_tentpays.vend_code 
			NEED 5 LINES 
			SKIP 1 line 
			PRINT COLUMN 01, " Vendor Total: ", 
			COLUMN 35, l_tot_vend_pay USING "----,---,--&.&&", 
			COLUMN 61, GROUP sum(p_rec_tentpays.taken_disc_amt) 
			USING "----,--&.&&" 
			LET l_tot_ind_pay = l_tot_ind_pay + l_tot_vend_pay 
			LET l_tot_ind_tax = l_tot_ind_tax + l_tot_vend_tax 
		AFTER GROUP OF p_rec_tentpays.pay_meth_ind 
			LET l_tot_pay_amt = l_tot_pay_amt + l_tot_ind_pay 
			LET l_tot_tax_amt = l_tot_tax_amt + l_tot_ind_tax 
			NEED 5 LINES 
			SKIP 2 line 
			PRINT COLUMN 35, "===============" 
			IF p_rec_tentpays.pay_meth_ind = "1" THEN 
				PRINT COLUMN 01, " Total Payments by Cheque: "; 
			ELSE 
				PRINT COLUMN 01, " Total Payments by EFT: "; 
			END IF 
			PRINT COLUMN 35, l_tot_ind_pay USING "----,---,--&.&&", 
			COLUMN 61, GROUP sum(p_rec_tentpays.taken_disc_amt) 
			USING "----,--&.&&" 
		ON LAST ROW 
			LET l_last_page = true 
			SKIP TO top OF PAGE 
			PRINT COLUMN 1, "Total Vouchers: ",count(*) using "####", 
			COLUMN 34, l_tot_pay_amt + l_tot_tax_amt USING "-----,---,--&.&&", 
			COLUMN 61, sum(p_rec_tentpays.taken_disc_amt) USING "----,--&.&&" 
			IF l_tot_tax_amt != 0 THEN 
				PRINT COLUMN 18, "Less total tax:", 
				COLUMN 34, (0 - l_tot_tax_amt) USING "-----,---,--&.&&" 
				PRINT COLUMN 34, l_tot_pay_amt USING "-----,---,--&.&&" 
			END IF 
			SKIP 2 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
END REPORT