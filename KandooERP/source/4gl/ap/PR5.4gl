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
# \brief module PR5 Cash Forecast

############################################################
# Global Scope
#
#
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS 
--	DEFINE glob_where_part STRING -- CHAR(2048) 
	DEFINE glob_tot_dis DECIMAL(16,2) 
	DEFINE glob_tot_unpaid DECIMAL(16,2)
	DEFINE glob_tot_past DECIMAL(16,2)	
	DEFINE glob_tot_1t7 DECIMAL(16,2)
	DEFINE glob_tot_8t14 DECIMAL(16,2)
	DEFINE glob_tot_15t21 DECIMAL(16,2)
	DEFINE glob_tot_22t28 DECIMAL(16,2) 
	DEFINE glob_tot_29t60 DECIMAL(16,2)
	DEFINE glob_tot_61t90 DECIMAL(16,2)
	DEFINE glob_tot_plus DECIMAL(16,2)
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PR5") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	LET glob_tot_dis = 0 
	LET glob_tot_unpaid = 0 
	LET glob_tot_past = 0 
	LET glob_tot_1t7 = 0 
	LET glob_tot_8t14 = 0 
	LET glob_tot_15t21 = 0 
	LET glob_tot_22t28 = 0 
	LET glob_tot_29t60 = 0 
	LET glob_tot_61t90 = 0 
	LET glob_tot_plus = 0 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW P100 with FORM "P100" 
			CALL windecoration_p("P100") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Forecast Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PR5","menu-forecast_rep-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PR5_rpt_process(PR5_rpt_query())
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 				#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PR5_rpt_process(PR5_rpt_query())
		
				ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Cancel" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW P100
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PR5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P100 with FORM "P100" 
			CALL windecoration_p("P100") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PR5_rpt_query()) #save where clause in env 
			CLOSE WINDOW P100 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PR5_rpt_process(get_url_sel_text())
	END CASE 
	
END MAIN 



############################################################
# FUNCTION PR5_rpt_query()
#
#
############################################################
FUNCTION PR5_rpt_query() 
	DEFINE l_where_text STRING 

	WHENEVER ERROR CONTINUE 
	DROP TABLE shuffle 
	WHENEVER ERROR stop 
	CREATE temp TABLE shuffle (tm_vend CHAR(8), 
	tm_name CHAR(30), 
	tm_date DATE, 
	tm_doc INTEGER, 
	tm_type CHAR(2), 
	tm_refer CHAR(20), 
	tm_due SMALLINT, 
	tm_amount DECIMAL(16,2), 
	tm_dis DECIMAL(16,2), 
	tm_unpaid DECIMAL(16,2), 
	tm_past DECIMAL(16,2), 
	tm_1t7 DECIMAL(16,2), 
	tm_8t14 DECIMAL(16,2), 
	tm_15t21 DECIMAL(16,2), 
	tm_22t28 DECIMAL(16,2), 
	tm_29t60 DECIMAL(16,2), 
	tm_61t90 DECIMAL(16,2), 
	tm_plus DECIMAL(16,2) ) with no LOG 

	CLEAR FORM 
	
	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME l_where_text ON vendor.vend_code, 
	vendor.name_text, 
	vendor.addr1_text, 
	vendor.addr2_text, 
	vendor.addr3_text, 
	vendor.city_text, 
	vendor.state_code, 
	vendor.post_code, 
	vendor.country_code, 
--@db-patch_2020_10_04--	vendor.country_text, 
	vendor.our_acct_code, 
	vendor.contact_text, 
	vendor.tele_text, 
	vendor.extension_text, 
	vendor.fax_text, 
	vendor.type_code, 
	vendor.term_code, 
	vendor.tax_code, 
	vendor.currency_code, 
	vendor.tax_text, 
	vendor.bank_acct_code, 
	vendor.drop_flag, 
	vendor.language_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PR5","construct-vendor-1") 

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
# FUNCTION PR5_rpt_process()
#
#
############################################################
FUNCTION PR5_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE l_rec_tempdoc RECORD 
		tm_vend LIKE vendor.vend_code, 
		tm_name LIKE vendor.name_text, 
		tm_date LIKE vendor.setup_date, 
		tm_doc INTEGER, 
		tm_type CHAR(2), 
		tm_refer CHAR(20), 
		tm_due SMALLINT, 
		tm_amount DECIMAL(16,2), 
		tm_dis DECIMAL(16,2), 
		tm_unpaid DECIMAL(16,2), 
		tm_past DECIMAL(16,2), 
		tm_1t7 DECIMAL(16,2), 
		tm_8t14 DECIMAL(16,2), 
		tm_15t21 DECIMAL(16,2), 
		tm_22t28 DECIMAL(16,2), 
		tm_29t60 DECIMAL(16,2), 
		tm_61t90 DECIMAL(16,2), 
		tm_plus DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rec_voucher RECORD 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		due_date LIKE voucher.due_date, 
		po_num LIKE voucher.po_num, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt, 
		poss_disc_amt LIKE voucher.poss_disc_amt, 
		taken_disc_amt LIKE voucher.taken_disc_amt 
	END RECORD 
	DEFINE l_rec_debithead RECORD 
		vend_code LIKE debithead.vend_code, 
		name_text LIKE vendor.name_text, 
		debit_num LIKE debithead.debit_num, 
		debit_date LIKE debithead.debit_date, 
		debit_text LIKE debithead.debit_text, 
		total_amt LIKE debithead.total_amt, 
		apply_amt LIKE debithead.apply_amt 
	END RECORD 
	DEFINE l_query_text CHAR(2200)
	DEFINE l_temp_value INTEGER 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PR5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PR5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	#NONE 
	#------------------------------------------------------------

	LET l_query_text = "SELECT voucher.vend_code,", 
	"vendor.name_text,", 
	"voucher.vouch_code,", 
	"voucher.vouch_date,", 
	"voucher.due_date,", 
	"voucher.po_num,", 
	"voucher.total_amt,", 
	"voucher.paid_amt,", 
	"voucher.poss_disc_amt,", 
	"voucher.taken_disc_amt ", 
	"FROM voucher,", 
	"vendor ", 
	"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND voucher.vend_code = vendor.vend_code AND ", 
	"voucher.cmpy_code = vendor.cmpy_code AND ", 
	p_where_text clipped, 
	" AND voucher.total_amt != voucher.paid_amt " 
	PREPARE invoicer FROM l_query_text 
	DECLARE invcurs CURSOR FOR invoicer 

	WHILE true 
		FOREACH invcurs INTO l_rec_voucher.* 
			LET l_rec_tempdoc.tm_vend = l_rec_voucher.vend_code 
			LET l_rec_tempdoc.tm_name = l_rec_voucher.name_text 
			LET l_rec_tempdoc.tm_date = l_rec_voucher.vouch_date 
			LET l_rec_tempdoc.tm_type = "VO" 
			LET l_rec_tempdoc.tm_doc = l_rec_voucher.vouch_code 
			LET l_rec_tempdoc.tm_refer = l_rec_voucher.po_num 
			LET l_temp_value = l_rec_voucher.due_date - today 
			CASE 
				WHEN l_temp_value > 32000 
					LET l_rec_tempdoc.tm_due = 32000 
				WHEN l_temp_value < -32000 
					LET l_rec_tempdoc.tm_due = -32000 
				OTHERWISE 
					LET l_rec_tempdoc.tm_due = l_temp_value 
			END CASE 
			LET l_rec_tempdoc.tm_dis = l_rec_voucher.poss_disc_amt 
			- l_rec_voucher.taken_disc_amt 
			LET l_rec_tempdoc.tm_amount = l_rec_voucher.total_amt 
			LET l_rec_tempdoc.tm_unpaid = l_rec_voucher.total_amt - l_rec_voucher.paid_amt 
			LET l_rec_tempdoc.tm_past = 0 
			LET l_rec_tempdoc.tm_plus = 0 
			LET l_rec_tempdoc.tm_1t7 = 0 
			LET l_rec_tempdoc.tm_8t14 = 0 
			LET l_rec_tempdoc.tm_15t21 = 0 
			LET l_rec_tempdoc.tm_22t28 = 0 
			LET l_rec_tempdoc.tm_29t60 = 0 
			LET l_rec_tempdoc.tm_61t90 = 0 
			CASE 
				WHEN l_rec_tempdoc.tm_due > 90 
					LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 60 
					LET l_rec_tempdoc.tm_61t90 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 28 
					LET l_rec_tempdoc.tm_29t60 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 21 
					LET l_rec_tempdoc.tm_22t28 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 14 
					LET l_rec_tempdoc.tm_15t21 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 7 
					LET l_rec_tempdoc.tm_8t14 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 0 
					LET l_rec_tempdoc.tm_1t7 = l_rec_tempdoc.tm_unpaid 
				OTHERWISE 
					LET l_rec_tempdoc.tm_past = l_rec_tempdoc.tm_unpaid 
			END CASE 
			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
			DISPLAY "" at 1,10 
			DISPLAY " Voucher: ", l_rec_voucher.vouch_code at 1,10 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		END FOREACH 
		LET l_query_text = "SELECT debithead.vend_code,", 
		"vendor.name_text,", 
		"debithead.debit_num,", 
		"debithead.debit_date,", 
		"debithead.debit_text,", 
		"debithead.total_amt,", 
		"debithead.apply_amt ", 
		"FROM debithead,", 
		"vendor ", 
		"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND debithead.cmpy_code = vendor.cmpy_code ", 
		"AND debithead.vend_code = vendor.vend_code AND ", 
		p_where_text clipped, 
		"AND debithead.total_amt != debithead.apply_amt" 
		PREPARE creditor FROM l_query_text 
		DECLARE credcurs CURSOR FOR creditor 

		FOREACH credcurs INTO l_rec_debithead.* 
			LET l_rec_tempdoc.tm_vend = l_rec_debithead.vend_code 
			LET l_rec_tempdoc.tm_name = l_rec_debithead.name_text 
			LET l_rec_tempdoc.tm_date = l_rec_debithead.debit_date 
			LET l_rec_tempdoc.tm_doc = l_rec_debithead.debit_num 
			LET l_rec_tempdoc.tm_type = "DB" 
			LET l_rec_tempdoc.tm_refer = l_rec_debithead.debit_text 
			LET l_rec_tempdoc.tm_due = l_rec_debithead.debit_date - today 
			LET l_rec_tempdoc.tm_amount = 0 
			LET l_rec_tempdoc.tm_dis = 0 
			LET l_rec_tempdoc.tm_amount = l_rec_tempdoc.tm_amount 
			- l_rec_debithead.total_amt 
			LET l_rec_tempdoc.tm_unpaid = l_rec_debithead.apply_amt 
			- l_rec_debithead.total_amt 
			LET l_rec_tempdoc.tm_past = 0 
			LET l_rec_tempdoc.tm_plus = 0 
			LET l_rec_tempdoc.tm_1t7 = 0 
			LET l_rec_tempdoc.tm_8t14 = 0 
			LET l_rec_tempdoc.tm_15t21 = 0 
			LET l_rec_tempdoc.tm_22t28 = 0 
			LET l_rec_tempdoc.tm_29t60 = 0 
			LET l_rec_tempdoc.tm_61t90 = 0 
			CASE 
				WHEN l_rec_tempdoc.tm_due > 90 
					LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 60 
					LET l_rec_tempdoc.tm_61t90 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 28 
					LET l_rec_tempdoc.tm_29t60 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 21 
					LET l_rec_tempdoc.tm_22t28 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 14 
					LET l_rec_tempdoc.tm_15t21 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 7 
					LET l_rec_tempdoc.tm_8t14 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_due > 0 
					LET l_rec_tempdoc.tm_1t7 = l_rec_tempdoc.tm_unpaid 
				OTHERWISE 
					LET l_rec_tempdoc.tm_past = l_rec_tempdoc.tm_unpaid 
			END CASE 
			DISPLAY "" at 1,10 
			DISPLAY " Debit: ", l_rec_debithead.debit_num at 1,10 

			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		END FOREACH 
		EXIT WHILE 
	END WHILE 
	

	 
	DECLARE selcurs CURSOR FOR 
	SELECT * FROM shuffle 
	ORDER BY tm_vend, 
	tm_date, 
	tm_doc 

	FOREACH selcurs INTO l_rec_tempdoc.*

			#---------------------------------------------------------
			OUTPUT TO REPORT PR5_rpt_list(l_rpt_idx,
			l_rec_tempdoc.*)  
			IF NOT rpt_int_flag_handler2("Document:",l_rec_tempdoc.tm_doc, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
	 
	END FOREACH 


	#------------------------------------------------------------
	FINISH REPORT PR5_rpt_list
	CALL rpt_finish("PR5_rpt_list")
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
# REPORT PR5_rpt_list(p_rpt_idx,p_rec_tempdoc)
#
#
############################################################
REPORT PR5_rpt_list(p_rpt_idx,p_rec_tempdoc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_tempdoc RECORD 
		tm_vend CHAR(8), 
		tm_name CHAR(30), 
		tm_date DATE, 
		tm_doc INTEGER, 
		tm_type CHAR(2), 
		tm_refer CHAR(20), 
		tm_due SMALLINT, 
		tm_amount DECIMAL(16,2), 
		tm_dis DECIMAL(16,2), 
		tm_unpaid DECIMAL(16,2), 
		tm_past DECIMAL(16,2), 
		tm_1t7 DECIMAL(16,2), 
		tm_8t14 DECIMAL(16,2), 
		tm_15t21 DECIMAL(16,2), 
		tm_22t28 DECIMAL(16,2), 
		tm_29t60 DECIMAL(16,2), 
		tm_61t90 DECIMAL(16,2), 
		tm_plus DECIMAL(16,2) 
	END RECORD 
--	DEFINE l_arr_line ARRAY[4] OF CHAR(132)
--	DEFINE l_msgresp LIKE language.yes_flag 

	OUTPUT 
 
	ORDER external BY p_rec_tempdoc.tm_vend, 
	p_rec_tempdoc.tm_date, 
	p_rec_tempdoc.tm_doc 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_tempdoc.tm_vend 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Vendor: ", p_rec_tempdoc.tm_vend, 2 spaces, 
			COLUMN 25, p_rec_tempdoc.tm_name 
			SELECT * INTO glob_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_tempdoc.tm_vend 
			PRINT COLUMN 1, "Currency: ", glob_rec_vendor.currency_code 

		AFTER GROUP OF p_rec_tempdoc.tm_vend 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 15, GROUP sum(p_rec_tempdoc.tm_dis) 
			USING "----------&", 
			COLUMN 27, GROUP sum(p_rec_tempdoc.tm_unpaid) 
			USING "---------&", 
			COLUMN 38, GROUP sum(p_rec_tempdoc.tm_past) 
			USING "-------&", 
			COLUMN 46, GROUP sum(p_rec_tempdoc.tm_1t7) 
			USING "----------&", 
			COLUMN 58, GROUP sum(p_rec_tempdoc.tm_8t14) 
			USING "----------&", 
			COLUMN 71, GROUP sum(p_rec_tempdoc.tm_15t21) 
			USING "----------&", 
			COLUMN 84, GROUP sum(p_rec_tempdoc.tm_22t28) 
			USING "----------&", 
			COLUMN 97, GROUP sum(p_rec_tempdoc.tm_29t60) 
			USING "----------&", 
			COLUMN 110, GROUP sum(p_rec_tempdoc.tm_61t90) 
			USING "---------&", 
			COLUMN 122, GROUP sum(p_rec_tempdoc.tm_plus) 
			USING "----------&" 
			
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_tempdoc.tm_date USING "dd/mm/yy", 
			COLUMN 09, p_rec_tempdoc.tm_due USING "---#", 
			COLUMN 15, p_rec_tempdoc.tm_dis USING "----------&", 
			COLUMN 27, p_rec_tempdoc.tm_unpaid USING "---------&", 
			COLUMN 38, p_rec_tempdoc.tm_past USING "-------&", 
			COLUMN 46, p_rec_tempdoc.tm_1t7 USING "----------&", 
			COLUMN 58, p_rec_tempdoc.tm_8t14 USING "----------&", 
			COLUMN 71, p_rec_tempdoc.tm_15t21 USING "----------&", 
			COLUMN 84, p_rec_tempdoc.tm_22t28 USING "----------&", 
			COLUMN 97, p_rec_tempdoc.tm_29t60 USING "----------&", 
			COLUMN 110, p_rec_tempdoc.tm_61t90 USING "----------&", 
			COLUMN 122, p_rec_tempdoc.tm_plus USING "----------&" 
			LET glob_tot_dis = glob_tot_dis 
			+ conv_currency(p_rec_tempdoc.tm_dis, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 
			LET glob_tot_unpaid = glob_tot_unpaid 
			+ conv_currency(p_rec_tempdoc.tm_unpaid, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 
			LET glob_tot_past = glob_tot_past 
			+ conv_currency(p_rec_tempdoc.tm_past, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 
			LET glob_tot_1t7 = glob_tot_1t7 
			+ conv_currency(p_rec_tempdoc.tm_1t7, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 
			LET glob_tot_8t14 = glob_tot_8t14 
			+ conv_currency(p_rec_tempdoc.tm_8t14, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 
			LET glob_tot_15t21 = glob_tot_15t21 
			+ conv_currency(p_rec_tempdoc.tm_15t21, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 
			LET glob_tot_22t28 = glob_tot_22t28 
			+ conv_currency(p_rec_tempdoc.tm_22t28, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 
			LET glob_tot_29t60 = glob_tot_29t60 
			+ conv_currency(p_rec_tempdoc.tm_29t60, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 
			LET glob_tot_61t90 = glob_tot_61t90 
			+ conv_currency(p_rec_tempdoc.tm_61t90, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 
			LET glob_tot_plus = glob_tot_plus 
			+ conv_currency(p_rec_tempdoc.tm_plus, glob_rec_kandoouser.cmpy_code, 
			glob_rec_vendor.currency_code, "F", today, "B") 

		ON LAST ROW 
			PRINT COLUMN 1, "Totals in base currency" 
			PRINT COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
			PRINT COLUMN 1, "Report Total:" , 
			COLUMN 15, glob_tot_dis USING "----------&", 
			COLUMN 27, glob_tot_unpaid USING "---------&", 
			COLUMN 38, glob_tot_past USING "-------&", 
			COLUMN 46, glob_tot_1t7 USING "----------&", 
			COLUMN 58, glob_tot_8t14 USING "----------&", 
			COLUMN 71, glob_tot_15t21 USING "----------&", 
			COLUMN 84, glob_tot_22t28 USING "----------&", 
			COLUMN 97, glob_tot_29t60 USING "----------&", 
			COLUMN 110, glob_tot_61t90 USING "----------&", 
			COLUMN 122, glob_tot_plus USING "----------&" 

			LET glob_tot_dis = 0 
			LET glob_tot_unpaid = 0 
			LET glob_tot_past = 0 
			LET glob_tot_1t7 = 0 
			LET glob_tot_8t14 = 0 
			LET glob_tot_15t21 = 0 
			LET glob_tot_22t28 = 0 
			LET glob_tot_29t60 = 0 
			LET glob_tot_61t90 = 0 
			LET glob_tot_plus = 0

			#End Of Report
			SKIP 2 line 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 		
			 
END REPORT