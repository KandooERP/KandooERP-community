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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAC_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_totals RECORD 
	currency_code LIKE customer.currency_code, 
	sales LIKE customerhist.sales_qty, 
	sales_cost LIKE customerhist.sale_cost_amt, 
	credits LIKE customerhist.cred_cost_amt, 
	credits_cost LIKE customerhist.cred_cost_amt, 
	profit LIKE customerhist.sales_qty, 
	percentage LIKE customerhist.gross_per, 
	cash LIKE customerhist.cash_amt 
END RECORD 
DEFINE modu_total_cred_amt LIKE customerhist.cred_amt 
DEFINE modu_total_disc_amt LIKE customerhist.disc_amt 
#####################################################################
# FUNCTION AAC_main() 
#
# AAC Customer History Report
#####################################################################
FUNCTION AAC_main() 

	IF NOT fgl_find_table("totals") THEN
		CREATE temp TABLE totals( currency_code CHAR(3), 
		sales money(16,2), 
		sales_cost money(16,2), 
		credits money(16,2), 
		credits_cost money(16,2), 
		profit money(16,2), 
		percentage DECIMAL(5,2), 
		cash money(16,2)) 
	END IF

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A114 with FORM "A114" 
			CALL windecoration_a("A114") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Customer History Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAC","menu-customer-history-rep") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAC_rpt_process(AAC_rpt_query())
					 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL rpt_rmsreps_reset(NULL)
					IF fgl_find_table("totals") THEN
						DELETE FROM totals WHERE "1=1"
					END IF
					
					CALL AAC_rpt_process(AAC_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 
			END MENU 

			CLOSE WINDOW A114 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAC_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A114 with FORM "A114" 
			CALL windecoration_a("A114") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAC_rpt_query()) #save where clause in env 
			CLOSE WINDOW A114 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAC_rpt_process(get_url_sel_text())
	END CASE

	IF fgl_find_table("totals") THEN
		DROP TABLE totals
	END IF
		
END FUNCTION 
#####################################################################
# END FUNCTION AAC_main() 
#####################################################################


#####################################################################
# FUNCTION AAC_rpt_query()
#
#
#####################################################################
FUNCTION AAC_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("U",1001,"") 	#1001 Enter Selection Criteria; Please Wait
	CONSTRUCT BY NAME l_where_text ON h.cust_code, 
	name_text, 
	year_num, 
	period_num 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAC","construct-customer") 

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
#####################################################################
# END FUNCTION AAC_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAC_rpt_process()
#
#
#####################################################################
FUNCTION AAC_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	--DEFINE l_exist SMALLINT
	DEFINE l_rec_customerhist RECORD 
		cust_code LIKE customerhist.cust_code, 
		name_text LIKE customer.name_text, 
		year_num LIKE customerhist.year_num, 
		period_num LIKE customerhist.period_num, 
		sales_num LIKE customerhist.sales_num, 
		sales_qty LIKE customerhist.sales_qty, 
		sale_cost_amt LIKE customerhist.sale_cost_amt, 
		cred_qty LIKE customerhist.cred_qty, 
		cred_amt LIKE customerhist.cred_amt, 
		cred_cost_amt LIKE customerhist.cred_cost_amt, 
		cash_qty LIKE customerhist.cash_qty, 
		cash_amt LIKE customerhist.cash_amt, 
		disc_amt LIKE customerhist.disc_amt, 
		gross_per LIKE customerhist.gross_per, 
		currency_code LIKE customer.currency_code 
	END RECORD
--	DEFINE l_rec_arparms RECORD LIKE arparms.*
	DEFINE l_query_text CHAR(1000) 

	LET modu_rec_totals.currency_code = " " 
	LET modu_rec_totals.sales = 0 
	LET modu_rec_totals.sales_cost = 0 
	LET modu_rec_totals.credits = 0 
	LET modu_rec_totals.credits_cost = 0 
	LET modu_rec_totals.profit = 0 
	LET modu_rec_totals.percentage = 0 
	LET modu_rec_totals.cash = 0 
	LET modu_total_disc_amt = 0 
	LET modu_total_cred_amt = 0

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAC_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
		 
	LET l_query_text = "SELECT H.cust_code, C.name_text, H.year_num,", 
	" H.period_num, H.sales_num, H.sales_qty,", 
	" H.sale_cost_amt, H.cred_qty, H.cred_amt,", 
	" H.cred_cost_amt, H.cash_qty, H.cash_amt,", 
	" H.disc_amt, H.gross_per, C.currency_code", 
	" FROM customerhist H, customer C", 
	" WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND C.cmpy_code = H.cmpy_code", 
	" AND C.cust_code = H.cust_code", 
	" AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAC_rpt_list")].sel_text clipped, 
	" ORDER BY C.currency_code, H.cust_code,", 
	" H.year_num, H.period_num" 
	PREPARE c_custhist FROM l_query_text 
	DECLARE s_custhist CURSOR FOR c_custhist 
	
	FOREACH s_custhist INTO l_rec_customerhist.*
		#------------------------------------------------------------
		OUTPUT TO REPORT AAC_rpt_list(l_rpt_idx,l_rec_customerhist.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customerhist.cust_code, l_rec_customerhist.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------	 
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT AAC_rpt_list
	CALL rpt_finish("AAC_rpt_list")
	#------------------------------------------------------------
END FUNCTION 
#####################################################################
# END FUNCTION AAC_rpt_process()
#####################################################################


#####################################################################
# REPORT AAC_rpt_list(p_rec_customerhist)
#
#
#####################################################################
REPORT AAC_rpt_list(p_rpt_idx,p_rec_customerhist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customerhist RECORD 
		cust_code LIKE customerhist.cust_code, 
		name_text LIKE customer.name_text, 
		year_num LIKE customerhist.year_num, 
		period_num LIKE customerhist.period_num, 
		sales_num LIKE customerhist.sales_num, 
		sales_qty LIKE customerhist.sales_qty, 
		sale_cost_amt LIKE customerhist.sale_cost_amt, 
		cred_qty LIKE customerhist.cred_qty, 
		cred_amt LIKE customerhist.cred_amt, 
		cred_cost_amt LIKE customerhist.cred_cost_amt, 
		cash_qty LIKE customerhist.cash_qty, 
		cash_amt LIKE customerhist.cash_amt, 
		disc_amt LIKE customerhist.disc_amt, 
		gross_per LIKE customerhist.gross_per, 
		currency_code LIKE customer.currency_code 
	END RECORD
	--DEFINE l_line1 CHAR(132)
	--DEFINE l_ytdsale money(16,2)
	--DEFINE l_cussale money(16,2)
	--DEFINE l_ytdcash money(16,2)
	--DEFINE l_cuscash money(16,2)
	--DEFINE l_ytdcred money(16,2)
	--DEFINE l_cuscred money(16,2)	 
	DEFINE l_tmp_gross_per DECIMAL(16)
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
--	left margin 0 
	ORDER BY p_rec_customerhist.currency_code, 
	p_rec_customerhist.cust_code, 
	p_rec_customerhist.year_num, 
	p_rec_customerhist.period_num 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			 
		ON EVERY ROW 
			IF p_rec_customerhist.sales_qty + p_rec_customerhist.cred_amt = 0 THEN 
				LET p_rec_customerhist.gross_per = 0 
			ELSE 
				LET l_tmp_gross_per = (((p_rec_customerhist.sales_qty 
				+ p_rec_customerhist.cred_cost_amt) 
				- (p_rec_customerhist.cred_amt 
				+ p_rec_customerhist.sale_cost_amt 
				+ p_rec_customerhist.disc_amt)) 
				/ (p_rec_customerhist.sales_qty 
				+ p_rec_customerhist.cred_amt) * 100) 
				IF l_tmp_gross_per > 999.99 THEN 
					LET p_rec_customerhist.gross_per = 999.99 
				ELSE 
					IF l_tmp_gross_per < -999.99 THEN 
						LET p_rec_customerhist.gross_per = -999.99 
					ELSE 
						LET p_rec_customerhist.gross_per = l_tmp_gross_per 
					END IF 
				END IF 
			END IF 
			
			PRINT COLUMN 10, p_rec_customerhist.period_num USING "##", 
			COLUMN 15, p_rec_customerhist.sales_qty USING "--,---,--&.&&", 
			COLUMN 30, p_rec_customerhist.sale_cost_amt USING "--,---,--&.&&", 
			COLUMN 45, (p_rec_customerhist.cred_amt + 
			p_rec_customerhist.disc_amt) USING "--,---,--&.&&", 
			COLUMN 60, p_rec_customerhist.cred_cost_amt USING "--,---,--&.&&", 
			COLUMN 75, ((p_rec_customerhist.sales_qty 
			+ p_rec_customerhist.cred_cost_amt) 
			- (p_rec_customerhist.cred_amt 
			+ p_rec_customerhist.sale_cost_amt 
			+ p_rec_customerhist.disc_amt)) USING "--,---,--&.&&", 
			COLUMN 100, p_rec_customerhist.gross_per USING "---#.##", 
			COLUMN 110, p_rec_customerhist.cash_amt USING "--,---,--&.&&" 
			# Accumlate totals FOR each currency code
			LET modu_rec_totals.currency_code = p_rec_customerhist.currency_code 
			LET modu_rec_totals.sales = modu_rec_totals.sales 
			+ p_rec_customerhist.sales_qty 
			LET modu_rec_totals.sales_cost = modu_rec_totals.sales_cost 
			+ p_rec_customerhist.sale_cost_amt 
			LET modu_rec_totals.credits = modu_rec_totals.credits 
			+ (p_rec_customerhist.cred_amt 
			+ p_rec_customerhist.disc_amt) 
			LET modu_rec_totals.credits_cost = modu_rec_totals.credits_cost 
			+ p_rec_customerhist.cred_cost_amt 
			LET modu_rec_totals.profit = modu_rec_totals.profit 
			+ ((p_rec_customerhist.sales_qty 
			+ p_rec_customerhist.cred_cost_amt) 
			- (p_rec_customerhist.cred_amt 
			+ p_rec_customerhist.sale_cost_amt 
			+ p_rec_customerhist.disc_amt)) 
			LET modu_rec_totals.cash = modu_rec_totals.cash 
			+ p_rec_customerhist.cash_amt 
			LET modu_total_cred_amt = modu_total_cred_amt 
			+ p_rec_customerhist.cred_amt 
			LET modu_total_disc_amt = modu_total_disc_amt 
			+ p_rec_customerhist.disc_amt 
			
		BEFORE GROUP OF p_rec_customerhist.cust_code 
			SKIP 2 LINES 
			PRINT COLUMN 01, "Customer Code : ", p_rec_customerhist.cust_code, 
			COLUMN 30, p_rec_customerhist.name_text, 
			COLUMN 65, p_rec_customerhist.currency_code 
			
		BEFORE GROUP OF p_rec_customerhist.year_num 
			SKIP 1 line 
			PRINT COLUMN 05, p_rec_customerhist.year_num USING "####" 
			
		BEFORE GROUP OF p_rec_customerhist.currency_code 
			SKIP TO top OF PAGE 
			
		AFTER GROUP OF p_rec_customerhist.currency_code 
			IF (modu_rec_totals.sales + modu_total_cred_amt) = 0 THEN 
				LET modu_rec_totals.percentage = 0 
			ELSE 
				LET modu_rec_totals.percentage = (((modu_rec_totals.sales 
				+ modu_rec_totals.credits_cost) 
				- (modu_total_cred_amt + modu_rec_totals.sales_cost 
				+ modu_total_disc_amt)) 
				/ (modu_rec_totals.sales + modu_total_cred_amt) * 100) 
			END IF
			 
			INSERT INTO totals VALUES (modu_rec_totals.*)
			 
			SKIP 1 line 
			PRINT COLUMN 15, "=============", 
			COLUMN 30, "=============", 
			COLUMN 45, "=============", 
			COLUMN 60, "=============", 
			COLUMN 75, "=============", 
			COLUMN 110, "=============" 
			PRINT COLUMN 01, "CURRENCY" 
			PRINT COLUMN 01, modu_rec_totals.currency_code, 
			COLUMN 08, "TOTAL:", 
			COLUMN 15, modu_rec_totals.sales USING "--,---,--&.&&", 
			COLUMN 30, modu_rec_totals.sales_cost USING "--,---,--&.&&", 
			COLUMN 45, modu_rec_totals.credits USING "--,---,--&.&&", 
			COLUMN 60, modu_rec_totals.credits_cost USING "--,---,--&.&&", 
			COLUMN 75, modu_rec_totals.profit USING "--,---,--&.&&", 
			COLUMN 110, modu_rec_totals.cash USING "--,---,--&.&&" 
			LET modu_rec_totals.currency_code = " " 
			LET modu_rec_totals.sales = 0 
			LET modu_rec_totals.sales_cost = 0 
			LET modu_rec_totals.credits = 0 
			LET modu_rec_totals.credits_cost = 0 
			LET modu_rec_totals.profit = 0 
			LET modu_rec_totals.percentage = 0 
			LET modu_rec_totals.cash = 0 
			LET modu_total_disc_amt = 0 
			LET modu_total_cred_amt = 0 
			
		AFTER GROUP OF p_rec_customerhist.cust_code 
			IF GROUP sum(p_rec_customerhist.sales_qty + p_rec_customerhist.cred_amt) = 0 THEN 
				LET p_rec_customerhist.gross_per = 0 
			ELSE 
				LET l_tmp_gross_per = ((group sum(p_rec_customerhist.sales_qty 
				+ p_rec_customerhist.cred_cost_amt) 
				- GROUP sum(p_rec_customerhist.cred_amt 
				+ p_rec_customerhist.sale_cost_amt 
				+ p_rec_customerhist.disc_amt)) 
				/ GROUP sum(p_rec_customerhist.sales_qty 
				+ p_rec_customerhist.cred_amt) * 100) 
				IF l_tmp_gross_per > 999.99 THEN 
					LET p_rec_customerhist.gross_per = 999.99 
				ELSE 
					IF l_tmp_gross_per < -999.99 THEN 
						LET p_rec_customerhist.gross_per = -999.99 
					ELSE 
						LET p_rec_customerhist.gross_per = l_tmp_gross_per 
					END IF 
				END IF 
			END IF 
			
			PRINT COLUMN 1, "Cust. Total :", 
			COLUMN 15, GROUP sum(p_rec_customerhist.sales_qty) 
			USING "--,---,--&.&&", 
			COLUMN 30, GROUP sum(p_rec_customerhist.sale_cost_amt) 
			USING "--,---,--&.&&", 
			COLUMN 45, GROUP sum((p_rec_customerhist.cred_amt + 
			p_rec_customerhist.disc_amt)) USING "--,---,--&.&&", 
			COLUMN 60, GROUP sum(p_rec_customerhist.cred_cost_amt) 
			USING "--,---,--&.&&", 
			COLUMN 75, GROUP sum(((p_rec_customerhist.sales_qty 
			+ p_rec_customerhist.cred_cost_amt) 
			- (p_rec_customerhist.cred_amt 
			+ p_rec_customerhist.sale_cost_amt 
			+ p_rec_customerhist.disc_amt))) 
			USING "--,---,--&.&&", 
			COLUMN 110, GROUP sum(p_rec_customerhist.cash_amt) 
			USING "--,---,--&.&&" 
		AFTER GROUP OF p_rec_customerhist.year_num 
			PRINT COLUMN 15, "=============", 
			COLUMN 30, "=============", 
			COLUMN 45, "=============", 
			COLUMN 60, "=============", 
			COLUMN 75, "=============", 
			COLUMN 110, "=============" 
			IF GROUP sum(p_rec_customerhist.sales_qty 
			+ p_rec_customerhist.cred_amt) = 0 THEN 
				LET p_rec_customerhist.gross_per = 0 
			ELSE 
				LET l_tmp_gross_per = ((group sum(p_rec_customerhist.sales_qty 
				+ p_rec_customerhist.cred_cost_amt) 
				- GROUP sum(p_rec_customerhist.cred_amt 
				+ p_rec_customerhist.sale_cost_amt 
				+ p_rec_customerhist.disc_amt)) 
				/ GROUP sum(p_rec_customerhist.sales_qty 
				+ p_rec_customerhist.cred_amt) * 100) 
				IF l_tmp_gross_per > 999.99 THEN 
					LET p_rec_customerhist.gross_per = 999.99 
				ELSE 
					IF l_tmp_gross_per < -999.99 THEN 
						LET p_rec_customerhist.gross_per = -999.99 
					ELSE 
						LET p_rec_customerhist.gross_per = l_tmp_gross_per 
					END IF 
				END IF 
			END IF 
			PRINT COLUMN 1, "Year TO Date:", 
			COLUMN 15, GROUP sum(p_rec_customerhist.sales_qty) 
			USING "--,---,--&.&&", 
			COLUMN 30, GROUP sum(p_rec_customerhist.sale_cost_amt) 
			USING "--,---,--&.&&", 
			COLUMN 45, GROUP sum((p_rec_customerhist.cred_amt 
			+ p_rec_customerhist.disc_amt)) 
			USING "--,---,--&.&&", 
			COLUMN 60, GROUP sum(p_rec_customerhist.cred_cost_amt) 
			USING "--,---,--&.&&", 
			COLUMN 75, GROUP sum(((p_rec_customerhist.sales_qty 
			+ p_rec_customerhist.cred_cost_amt) 
			- (p_rec_customerhist.cred_amt 
			+ p_rec_customerhist.sale_cost_amt 
			+ p_rec_customerhist.disc_amt))) 
			USING "--,---,--&.&&", 
			COLUMN 110, GROUP sum(p_rec_customerhist.cash_amt) 
			USING "--,---,--&.&&" 
		ON LAST ROW 
			SKIP 1 line 
			DELETE FROM totals WHERE 1=1 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			 
END REPORT
#####################################################################
# END REPORT AAC_rpt_list(p_rec_customerhist)
#####################################################################
