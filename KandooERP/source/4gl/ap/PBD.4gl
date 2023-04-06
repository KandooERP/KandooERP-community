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
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../ap/PB_GROUP_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################
#Module Scope Variables
DEFINE modu_tot_amt DECIMAL(16,2)
DEFINE modu_tot_disc DECIMAL(16,2)
DEFINE modu_tot_paid DECIMAL(16,2)

############################################################
# FUNCTION PBD_main() 
#
# Duplicate Voucher Exception Report
############################################################
FUNCTION PBD_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("PBD")  

	LET modu_tot_amt = 0 
	LET modu_tot_disc = 0 
	LET modu_tot_paid = 0 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query  
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW P509 with FORM "P509" 
			CALL windecoration_p("P509") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Duplicate Vouchers" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PBD","menu-duplicate_voucher-1") 
					CALL PBD_rpt_process(PBD_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)					
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL PBD_rpt_process(PBD_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)	

				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P509 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PBD_rpt_process(NULL)  #(NULL query-where-part will read report_code from URL


		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P509 with FORM "P509" 
			CALL windecoration_p("P509") 

			CALL PBD_rpt_query() 
			CLOSE WINDOW P509 
			CALL set_url_sel_text(PBD_rpt_query()) #save where clause in env

 		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PBD_rpt_process(get_url_sel_text())
	END CASE 
	
END FUNCTION 


############################################################
# FUNCTION PBD_rpt_query()
#
#
############################################################
FUNCTION PBD_rpt_query() 
	DEFINE l_where_text STRING 
	DEFINE l_date_from DATE 
	DEFINE l_date_to DATE	

	LET l_date_from = today - 120 
	LET l_date_to = today 

	DISPLAY l_date_from TO date_from  
	DISPLAY l_date_to TO date_to  

	MESSAGE kandoomsg2("U",1001,"") 
	INPUT l_date_from,l_date_to WITHOUT DEFAULTS FROM date_from,date_to  

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PBD","inp-date-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD date_from 
			IF l_date_from IS NULL THEN 
				ERROR kandoomsg2("W",9120,"") 	#9120  Start date must be entered
				NEXT FIELD date_from 
			ELSE 
				IF l_date_from > l_date_to THEN 
					ERROR kandoomsg2("U",9110,"")#9110 Date IS outside allowed range
					NEXT FIELD date_from 
				END IF 
			END IF 
			
		AFTER FIELD date_to 
			IF l_date_to IS NULL THEN 
				ERROR kandoomsg2("J",9505,"")		#9505 " Date must be entered
				NEXT FIELD date_to 
			END IF 
			
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_date_from IS NULL THEN 
					ERROR kandoomsg2("W",9120,"")		#9120  Start date must be entered
					NEXT FIELD date_from 
				END IF 
				IF l_date_to IS NULL THEN 
					ERROR kandoomsg2("J",9505,"") #9505 " Date must be entered
					NEXT FIELD date_to 
				END IF 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE 
		OPEN WINDOW P105 with FORM "P105" 
		CALL windecoration_p("P105") 

		MESSAGE kandoomsg2("U",1001,"") 

		CONSTRUCT BY NAME l_where_text ON vendor.vend_code, 
		name_text, 
		vendor.currency_code, 
		addr1_text, 
		addr2_text, 
		addr3_text, 
		city_text, 
		state_code, 
		post_code, 
		country_code, 
		curr_amt, 
		over1_amt, 
		over30_amt, 
		over60_amt, 
		over90_amt, 
		bal_amt, 
		avg_day_paid_num, 
		type_code, 
		vendor.term_code, 
		vendor.tax_code, 
		vendor.hold_code, 
		vendor.pay_meth_ind, 
		usual_acct_code, 
		vat_code, 
		last_po_date, 
		last_vouc_date, 
		last_payment_date, 
		setup_date, 
		highest_bal_amt, 
		ytd_amt 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","PBD","construct-voucher-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		CLOSE WINDOW P105
		
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW P105 
			RETURN NULL
		ELSE
			LET glob_rec_rpt_selector.ref1_date = l_date_from 
			LET glob_rec_rpt_selector.ref2_date = l_date_to 
			RETURN l_where_text
		END IF
	END IF 
END FUNCTION	

############################################################
# FUNCTION PBD_rpt_process()
#
#
############################################################
FUNCTION PBD_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 	
	DEFINE l_date_from DATE 
	DEFINE l_date_to DATE		
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_count INTEGER 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PBD_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PBD_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Get additional variables from rmsreps 
	LET l_date_from = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date
	LET l_date_to = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_date

	LET l_query_text = "SELECT unique count(*), inv_text ", 
	"FROM voucher ", 
	"WHERE inv_text = ? ", 
	"AND vend_code = ? ", 
	"AND cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"group by inv_text ", 
	"having count(*) > 1" 
	
	PREPARE s_duplicate FROM l_query_text 
	DECLARE c_duplicate CURSOR FOR s_duplicate 

	LET l_query_text = "SELECT voucher.* FROM voucher, vendor ", 
	"WHERE voucher.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND voucher.vend_code = vendor.vend_code ", 
	"AND voucher.inv_text IS NOT NULL ", 
	"AND voucher.vouch_date between '",l_date_from,"' ", 
	"AND '",l_date_to ,"' ", 
	"AND ", p_where_text clipped," ", 
	"ORDER BY voucher.vend_code, voucher.inv_text, ", 
	"voucher.vouch_code" 

	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 

	FOREACH c_voucher INTO l_rec_voucher.* 
		LET l_count = 0 
		OPEN c_duplicate USING l_rec_voucher.inv_text,l_rec_voucher.vend_code 

		WHILE true 
			FETCH c_duplicate INTO l_count, l_rec_voucher.inv_text 
			IF status = NOTFOUND THEN 
				EXIT WHILE 
			ELSE 
				IF l_count > 1 THEN

					#---------------------------------------------------------
					OUTPUT TO REPORT PBD_rpt_list(l_rpt_idx,
					l_rec_voucher.*)
					IF NOT rpt_int_flag_handler2("Vendor",l_rec_voucher.vend_code, l_rec_voucher.inv_text,l_rpt_idx) THEN
						EXIT FOREACH 
					END IF 
					#---------------------------------------------------------	
					 					
				END IF 
			END IF 
		END WHILE 
		
	END FOREACH
	
	#------------------------------------------------------------
	FINISH REPORT PBD_rpt_list
	CALL rpt_finish("PBD_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 


############################################################
# REPORT PBD_rpt_list(p_rec_voucher) )
#
# PBD - Duplicate Voucher Exception Report
############################################################
REPORT PBD_rpt_list(p_rpt_idx,p_rec_voucher)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_avg_amt DECIMAL(16,2)
	DEFINE l_vendor_text LIKE vendor.name_text 
	DEFINE l_vendor_currency_code LIKE vendor.currency_code 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_voucher.vend_code, 
	p_rec_voucher.inv_text, 
	p_rec_voucher.vouch_code 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_rec_voucher.vend_code 
			SKIP 1 LINES 
			INITIALIZE l_vendor_text TO NULL 
			SELECT name_text, currency_code 
			INTO l_vendor_text, l_vendor_currency_code 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_voucher.vend_code 
			PRINT COLUMN 1, "Vendor : ",p_rec_voucher.vend_code clipped,2 spaces, l_vendor_text 
			PRINT COLUMN 1, "Currency: ",l_vendor_currency_code 
			
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_voucher.vouch_code USING "########", 
			COLUMN 10, p_rec_voucher.inv_text, 
			COLUMN 31, p_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 40, p_rec_voucher.year_num USING "####", 
			COLUMN 45, p_rec_voucher.period_num USING "###", 
			COLUMN 49, p_rec_voucher.total_amt USING "---,---,---.&&", 
			COLUMN 64, p_rec_voucher.poss_disc_amt USING "---,---,---.&&", 
			COLUMN 79, p_rec_voucher.paid_amt USING "---,---,---.&&", 
			COLUMN 98, p_rec_voucher.post_flag, 
			COLUMN 104, p_rec_voucher.hold_code 
			LET modu_tot_amt = modu_tot_amt + p_rec_voucher.total_amt / p_rec_voucher.conv_qty 
			LET modu_tot_disc = modu_tot_disc + p_rec_voucher.poss_disc_amt / p_rec_voucher.conv_qty 
			LET modu_tot_paid = modu_tot_paid + p_rec_voucher.paid_amt / p_rec_voucher.conv_qty 
			
		AFTER GROUP OF p_rec_voucher.vend_code 
			NEED 2 LINES 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 1, "Vouchers: ",group count(*) USING "<<<<<", 
			COLUMN 18,"Average: ",group avg(p_rec_voucher.total_amt) USING "---,---,---.&&", 
			COLUMN 49,group sum(p_rec_voucher.total_amt) USING "---,---,---.&&", 
			COLUMN 64,group sum(p_rec_voucher.poss_disc_amt) 	USING "---,---,---.&&", 
			COLUMN 79,group sum(p_rec_voucher.paid_amt) USING "---,---,---.&&" 
			
		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 line 
			LET l_avg_amt = modu_tot_amt / count(*) 
			PRINT COLUMN 1, "Totals In Base Currency: " 
			PRINT COLUMN 1, "Vouchers:", count(*) USING "####", 
			COLUMN 18,"Average: ", l_avg_amt USING "---,---,---.&&", 
			COLUMN 49, modu_tot_amt USING "---,---,---.&&", 
			COLUMN 64, modu_tot_disc USING "---,---,---.&&", 
			COLUMN 79, modu_tot_paid USING "---,---,---.&&" 
			SKIP 1 line 
			SKIP 1 line 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT 