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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E8_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E84_GLOBALS.4gl"
###########################################################################
# FUNCTION E84_main()
#
# E84 Sales Commissions Report
###########################################################################
FUNCTION E84_main() 
	DEFINE l_rec_salescomm RECORD 
		sale_code LIKE salesperson.sale_code, 
		cust_code LIKE customer.cust_code, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		total_amt LIKE invoicehead.total_amt, 
		currency_code LIKE invoicehead.currency_code, 
		paid_amt LIKE invoicehead.paid_amt, 
		share_per LIKE saleshare.share_per, 
		comm_amt LIKE invoicedetl.comm_amt 
	END RECORD 
	DEFINE l_report_type_ind char(1)

	DEFER QUIT 
	DEFER INTERRUPT 
	
	#Initial UI Init
	CALL setModuleId("E84") 
	--CALL authenticate(getmoduleid()) 

	CREATE temp TABLE t_salescomm( 
		sale_code char(8), 
		cust_code char(8), 
		inv_num INTEGER, 
		inv_date DATE, 
		total_amt DECIMAL (16,2), 
		currency_code char(3), 
		paid_amt decimal(16,2), 
		share_per decimal(4,1), 
		comm_amt decimal(16,2) ) 



	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW E167 with FORM "E167" 
			 CALL windecoration_e("E167") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Sales Commission report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E84","menu-Sales_Commission-1") -- albo kd-502
		 
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null)
		
				ON ACTION "DETAILED REPORT" #COMMAND "Detailed" " SELECT criteria AND PRINT detailed report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL E84_rpt_process(E84_rpt_query("D"))
					 
				ON ACTION "SUMMARY REPORT" #COMMAND "Summary" " SELECT criteria AND PRINT summary report"
					CALL rpt_rmsreps_reset(NULL)
					CALL E84_rpt_process(E84_rpt_query("S"))
								 
				ON ACTION "PRINT MANAGER" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
			END MENU 

			CLOSE WINDOW E167
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E84_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E160 with FORM "E160" 
			 CALL windecoration_e("E160") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			LET l_report_type_ind = promptds("Report Type","Generate Detailed or Summary Report","S") 
			CALL set_url_sel_text(E84_rpt_query(l_report_type_ind)) #save where clause in env 
			CLOSE WINDOW E160 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E84_rpt_process(get_url_sel_text())
	END CASE 
		
END FUNCTION 


###########################################################################
# FUNCTION E84_rpt_query(p_report_type_ind) 
#
#
###########################################################################
FUNCTION E84_rpt_query(p_report_type_ind) 
	DEFINE p_report_type_ind char(1)
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 

	CLEAR FORM 
	MESSAGE kandoomsg2("A",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON invoicehead.sale_code, 
	salesperson.name_text, 
	salesperson.terri_code, 
	salesperson.sale_type_ind, 
	salesperson.mgr_code, 
	invoicehead.cust_code, 
	invoicehead.inv_date, 
	invoicehead.inv_num, 
	invoicehead.currency_code, 
	invoicehead.total_amt, 
	invoicehead.paid_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E84","construct-invoicehead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE
		LET glob_rec_rpt_selector.ref1_ind = p_report_type_ind
		RETURN l_where_text 
	END IF 
END FUNCTION


###########################################################################
# FUNCTION E84_rpt_process(p_where_text)
#
#
###########################################################################
FUNCTION E84_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING	
	DEFINE l_rpt_idx SMALLINT  #report array index	

	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_saleshare RECORD LIKE saleshare.* 
	DEFINE l_rec_salescomm RECORD 
		sale_code LIKE salesperson.sale_code, 
		cust_code LIKE customer.cust_code, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		total_amt LIKE invoicehead.total_amt, 
		currency_code LIKE invoicehead.currency_code, 
		paid_amt LIKE invoicehead.paid_amt, 
		share_per LIKE saleshare.share_per, 
		comm_amt LIKE invoicedetl.comm_amt 
	END RECORD 	
	DEFINE l_comm_amt LIKE invoicedetl.comm_amt 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 	
	DEFINE l_report_type_ind NCHAR(1) #flag for "D"etailed or "S"ummary Report
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	IF (get_url_report_code() IS NULL) OR (get_url_report_code() = 0) THEN
		LET l_report_type_ind = glob_rec_rpt_selector.ref1_ind 
	ELSE
		LET l_report_type_ind =	db_rmsreps_get_ref1_ind(UI_OFF,get_url_report_code())
	END IF

 
	IF l_report_type_ind = "S" THEN
		LET l_rpt_idx = rpt_start("E84-SUM","E84_rpt_list_summary",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT E84_rpt_list_summary TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text	
	ELSE
		LET l_rpt_idx = rpt_start("E84-DET","E84_rpt_list_detail",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT E84_rpt_list_detail TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text		
	END IF
	#------------------------------------------------------------
	# Get additional data from rmsreps
	LET l_report_type_ind = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind #Flag for S/D summary/detailed reporrt
	#------------------------------------------------------------
	
	LET l_query_text = "SELECT invoicehead.* ", 
	"FROM invoicehead,", 
	"salesperson ", 
	"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND salesperson.cmpy_code = invoicehead.cmpy_code ", 
	"AND salesperson.sale_code = invoicehead.sale_code ", 
	"AND invoicehead.posted_flag NOT in ('V', 'H') ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY invoicehead.sale_code" 
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead cursor FOR s_invoicehead
	 
	LET l_query_text = " SELECT * FROM invoicedetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND inv_num = ?" 
	PREPARE s_invoicedetl FROM l_query_text 
	DECLARE c_invoicedetl cursor FOR s_invoicedetl 
	
	LET l_query_text = " SELECT * FROM creditdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND cred_num = ?" 
	PREPARE s_creditdetl FROM l_query_text 
	DECLARE c_creditdetl cursor FOR s_creditdetl 
	
	LET l_query_text = " SELECT * FROM saleshare ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND order_num = ?" 
	PREPARE s_saleshare FROM l_query_text 
	DECLARE c_saleshare cursor FOR s_saleshare 
	
	MESSAGE kandoomsg2("E",1045,"") #1045 Reporting on Salesperson...

	FOREACH c_invoicehead INTO l_rec_invoicehead.* 
		OPEN c_invoicedetl USING l_rec_invoicehead.inv_num 

		FOREACH c_invoicedetl INTO l_rec_invoicedetl.* 
			OPEN c_saleshare USING l_rec_invoicedetl.order_num 
			LET l_idx = 0 

			FOREACH c_saleshare INTO l_rec_saleshare.* 
				LET l_idx = l_idx + 1 
				IF l_rec_saleshare.share_per > 0 THEN 
					UPDATE t_salescomm 
					SET comm_amt = comm_amt + (l_rec_invoicedetl.comm_amt * 
					(l_rec_saleshare.share_per/100)) 
					WHERE sale_code = l_rec_saleshare.sale_code 
					AND inv_num = l_rec_invoicehead.inv_num 
					IF sqlca.sqlerrd[3] = 0 THEN 
						LET l_comm_amt = l_rec_invoicedetl.comm_amt * 
						(l_rec_saleshare.share_per/100) 

						INSERT INTO t_salescomm VALUES (l_rec_saleshare.sale_code, 
						l_rec_invoicehead.cust_code, 
						l_rec_invoicehead.inv_num, 
						l_rec_invoicehead.inv_date, 
						l_rec_invoicehead.total_amt, 
						l_rec_invoicehead.currency_code, 
						l_rec_invoicehead.paid_amt, 
						l_rec_saleshare.share_per, 
						l_comm_amt) 

					END IF 
				END IF 
			END FOREACH 

			IF l_idx = 0 THEN 
				UPDATE t_salescomm 
				SET comm_amt = comm_amt + l_rec_invoicedetl.comm_amt 
				WHERE sale_code = l_rec_invoicehead.sale_code 
				AND inv_num = l_rec_invoicehead.inv_num 
				IF sqlca.sqlerrd[3] = 0 THEN 

					INSERT INTO t_salescomm VALUES (l_rec_invoicehead.sale_code, 
					l_rec_invoicehead.cust_code, 
					l_rec_invoicehead.inv_num, 
					l_rec_invoicehead.inv_date, 
					l_rec_invoicehead.total_amt, 
					l_rec_invoicehead.currency_code, 
					l_rec_invoicehead.paid_amt, 
					100.0, 
					l_rec_invoicedetl.comm_amt) 

				END IF 
			END IF 

		END FOREACH 

	END FOREACH 

	LET j = (length(p_where_text)) 
	LET i = j 
	WHILE i > 0 
		IF i <= j - 19 THEN 
			# Remove paid_amt b/c it does NOT occur in credithead table
			IF p_where_text[i,i+19] = 'invoicehead.paid_amt' THEN 
				LET p_where_text[i,j] = '1=1' 
			END IF 
		END IF 
		IF i <= j - 10 THEN 
			IF p_where_text[i,i+10] = "invoicehead" THEN 
				LET p_where_text[i,i+10] = " credithead" 
			END IF 
		END IF 
		IF i <= j - 2 THEN 
			IF p_where_text[i,i+2] = "inv" THEN 
				LET p_where_text = p_where_text[1,i-1],"cred",p_where_text[i+3,j] 
				LET j=j+1 
			END IF 
		END IF 
		LET i = i - 1 
	END WHILE 
	
	LET l_query_text = "SELECT credithead.* ", 
	"FROM credithead,", 
	"salesperson ", 
	"WHERE credithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND salesperson.cmpy_code = credithead.cmpy_code ", 
	"AND salesperson.sale_code = credithead.sale_code ", 
	"AND credithead.posted_flag NOT in ('V', 'H') ", 
	"AND ",p_where_text clipped, " ", 
	"ORDER BY credithead.sale_code" 
	PREPARE s_credithead FROM l_query_text 
	DECLARE c_credithead cursor FOR s_credithead
	 
	FOREACH c_credithead INTO l_rec_credithead.* 
		OPEN c_creditdetl USING l_rec_credithead.cred_num 
		FOREACH c_creditdetl INTO l_rec_creditdetl.* 
			UPDATE t_salescomm 
			SET comm_amt = comm_amt + l_rec_creditdetl.comm_amt 
			WHERE sale_code = l_rec_credithead.sale_code 
			AND inv_num = l_rec_credithead.cred_num 
			IF sqlca.sqlerrd[3] = 0 THEN 
				INSERT INTO t_salescomm VALUES (l_rec_credithead.sale_code, 
				l_rec_credithead.cust_code, 
				l_rec_credithead.cred_num, 
				l_rec_credithead.cred_date, 
				l_rec_credithead.total_amt, 
				l_rec_credithead.currency_code, 
				0.00, 
				100.0, 
				l_rec_creditdetl.comm_amt) 
			END IF 
		END FOREACH 
	END FOREACH 



	DECLARE c_t_salescomm cursor FOR 
	SELECT * 
	FROM t_salescomm 
	ORDER BY sale_code, 
	currency_code, 
	inv_date, 
	inv_num 

	FOREACH c_t_salescomm INTO l_rec_salescomm.* 
		IF l_report_type_ind = "S" THEN
 	 	#---------------------------------------------------------		 
			OUTPUT TO REPORT E84_rpt_list_summary (l_rpt_idx,
			l_rec_salescomm.*) 
 	 	#---------------------------------------------------------			
		ELSE 
 	 	#---------------------------------------------------------		
			OUTPUT TO REPORT E84_rpt_list_detail (l_rpt_idx,
			l_rec_salescomm.*) 
 	 	#---------------------------------------------------------			
		END IF 
	END FOREACH 

	IF l_report_type_ind = "S" THEN
		#------------------------------------------------------------
		FINISH REPORT E84_rpt_list_summary
		CALL rpt_finish("E84_rpt_list_summary")
		#------------------------------------------------------------	 
	ELSE 
		#------------------------------------------------------------
		FINISH REPORT E84_rpt_list_detail
		CALL rpt_finish("E84_rpt_list_detail")
		#------------------------------------------------------------	
	END IF 


	DELETE FROM t_salescomm WHERE 1=1 

	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 


###########################################################################
# REPORT E84_rpt_list_summary(p_rpt_idx,p_rec_salescomm) 
#
#
###########################################################################
REPORT E84_rpt_list_summary(p_rpt_idx,p_rec_salescomm) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_salescomm RECORD 
		sale_code LIKE salesperson.sale_code, 
		cust_code LIKE customer.cust_code, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		total_amt LIKE invoicehead.total_amt, 
		currency_code LIKE invoicehead.currency_code, 
		paid_amt LIKE invoicehead.paid_amt, 
		share_per LIKE saleshare.share_per, 
		comm_amt LIKE invoicedetl.comm_amt 
	END RECORD 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE i SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_salescomm.sale_code, 
	p_rec_salescomm.currency_code, 
	p_rec_salescomm.inv_date, 
	p_rec_salescomm.inv_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Salesperson", 
			COLUMN 41, "Total", 
			COLUMN 60, "Paid", 
			COLUMN 70, "Commission" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		AFTER GROUP OF p_rec_salescomm.currency_code 
			SELECT * 
			INTO l_rec_salesperson.* 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = p_rec_salescomm.sale_code 
			IF status = NOTFOUND THEN 
				LET l_rec_salesperson.name_text = "**********" 
			END IF 
			PRINT COLUMN 1, p_rec_salescomm.sale_code, 
			COLUMN 10, l_rec_salesperson.name_text[1,25], 
			COLUMN 37, GROUP sum(p_rec_salescomm.total_amt) 
			USING "--,---,---.&&", 
			COLUMN 51, p_rec_salescomm.currency_code, 
			COLUMN 55, GROUP sum(p_rec_salescomm.paid_amt) 
			USING "--,---,---.&&", 
			COLUMN 68, GROUP sum(p_rec_salescomm.comm_amt) 
			USING "--,---,---.&&"
			 
		AFTER GROUP OF p_rec_salescomm.sale_code 
			DISPLAY p_rec_salescomm.sale_code at 1,28 

			SKIP 1 LINES 
			
		ON LAST ROW 
			SKIP 1 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT 


###########################################################################
# REPORT E84_rpt_list_detail(p_rpt_idx,p_rec_salescomm)
#
#
###########################################################################
REPORT E84_rpt_list_detail(p_rpt_idx,p_rec_salescomm)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_salescomm RECORD 
		sale_code LIKE salesperson.sale_code, 
		cust_code LIKE customer.cust_code, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		total_amt LIKE invoicehead.total_amt, 
		currency_code LIKE invoicehead.currency_code, 
		paid_amt LIKE invoicehead.paid_amt, 
		share_per LIKE saleshare.share_per, 
		comm_amt LIKE invoicedetl.comm_amt 
	END RECORD 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_salescomm.sale_code, 
	p_rec_salescomm.currency_code, 
	p_rec_salescomm.inv_date, 
	p_rec_salescomm.inv_num
	 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Inv.Date", 
				COLUMN 11, "Inv.No.", 
				COLUMN 20, "Customer", 
				COLUMN 33, "Total", 
				COLUMN 52, "Paid", 
				COLUMN 62, "Share%", 
				COLUMN 70, "Commission" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_salescomm.sale_code 
			SELECT * 
			INTO l_rec_salesperson.* 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = p_rec_salescomm.sale_code 
			IF status = NOTFOUND THEN 
				LET l_rec_salesperson.name_text = "**********" 
			END IF 

			PRINT COLUMN 1, "Salesperson:", 
				COLUMN 14, p_rec_salescomm.sale_code, 
				COLUMN 23, l_rec_salesperson.name_text 

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_salescomm.inv_date USING "dd/mm/yy", 
				COLUMN 10, p_rec_salescomm.inv_num USING "########", 
				COLUMN 20, p_rec_salescomm.cust_code, 
				COLUMN 29, p_rec_salescomm.total_amt USING "--,---,---.&&", 
				COLUMN 47, p_rec_salescomm.paid_amt USING "--,---,---.&&", 
				COLUMN 62, p_rec_salescomm.share_per USING "###.&", 
				COLUMN 69, p_rec_salescomm.comm_amt USING "-,---,---.&&" 
			
		AFTER GROUP OF p_rec_salescomm.currency_code 
			PRINT COLUMN 29, "-------------------------------", 
				COLUMN 68, "-------------" 
			PRINT COLUMN 15, "Currency total", 
				COLUMN 29, GROUP sum(p_rec_salescomm.total_amt) 
				USING "--,---,---.&&", 
				COLUMN 43, p_rec_salescomm.currency_code, 
				COLUMN 47, GROUP sum(p_rec_salescomm.paid_amt) 
				USING "--,---,---.&&", 
				COLUMN 68, GROUP sum(p_rec_salescomm.comm_amt) 
				USING "--,---,---.&&" 
			SKIP 1 line 

		AFTER GROUP OF p_rec_salescomm.sale_code 
			DISPLAY p_rec_salescomm.sale_code at 1,28 

			SKIP 2 LINES 
			
		ON LAST ROW 
			SKIP 1 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno			
END REPORT 