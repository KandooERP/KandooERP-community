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
GLOBALS "../eo/E85_GLOBALS.4gl"
# \brief module E85 Sales Commissions Report
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_invstart_date DATE 
DEFINE modu_invend_date DATE
DEFINE modu_paystart_date DATE
DEFINE modu_payend_date DATE
###########################################################################
# FUNCTION E85_main()
#
#
###########################################################################
FUNCTION E85_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E85") -- albo 

	CREATE temp TABLE t_salescomm 
	( sale_code char(8), 
	cust_code char(8), 
	inv_num INTEGER, 
	inv_date DATE, 
	total_amt DECIMAL (16,2), 
	currency_code char(3), 
	paid_amt decimal(16,2), 
	share_per decimal(4,1), 
	comm_amt decimal(16,2), 
	commpay_amt decimal(16,2) ) 
	CREATE INDEX t_salescomm_key ON t_salescomm(inv_num,sale_code)

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
	 
			OPEN WINDOW E294 with FORM "E294" 
			 CALL windecoration_e("E294")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Sales Commission report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E85","menu-Sales_Commission-1") -- albo kd-502
					CALL rpt_rmsreps_reset(NULL)
					CALL E85_rpt_process(E85_rpt_query())
					 
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				COMMAND "Report" " SELECT criteria AND PRINT detailed report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL E85_rpt_process(E85_rpt_query())
		
				ON ACTION "PRINT MANAGER" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW E294
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E85_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E294 with FORM "E294" 
			 CALL windecoration_e("E294") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E85_rpt_query()) #save where clause in env 
			CLOSE WINDOW E294 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E85_rpt_process(get_url_sel_text())
	END CASE 		
END FUNCTION 


###########################################################################
# FUNCTION E85_rpt_query()
#
#
###########################################################################
FUNCTION E85_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_paid_flag char(1)

	CLEAR FORM 
	MESSAGE kandoomsg2("A",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	INITIALIZE modu_invstart_date TO NULL 
	--INITIALIZE modu_invend_date TO NULL
	LET modu_invend_date = TODAY
	INITIALIZE modu_paystart_date TO NULL 
	--INITIALIZE modu_payend_date TO NULL
	LET modu_payend_date  = TODAY	 
	LET l_paid_flag = "1"
	 
	INPUT 
		modu_invstart_date, 
		modu_invend_date, 
		modu_paystart_date, 
		modu_payend_date, 
		l_paid_flag WITHOUT DEFAULTS
	FROM 
		invstart_date, 
		invend_date, 
		paystart_date, 
		payend_date, 
		paid_flag ATTRIBUTE(UNBUFFERED)
	 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E85","input-modu_invstart_date-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD invstart_date 
			IF modu_invstart_date IS NULL THEN 
				ERROR kandoomsg2("E",9243,"") 			#9243 Invoice start date must be entered
				NEXT FIELD invstart_date 
			END IF 
			
		AFTER FIELD invend_date 
			IF modu_invend_date IS NULL THEN 
				ERROR kandoomsg2("E",9243,"") 			#9243 Invoice END date must be entered
				NEXT FIELD invend_date 
			END IF 
			IF modu_invend_date < modu_invstart_date THEN 
				ERROR kandoomsg2("E",9244,"") 			#9244 invoice END date can NOT be less than start date
				NEXT FIELD invend_date 
			END IF 
			
		AFTER FIELD paystart_date 
			IF modu_paystart_date IS NULL THEN 
				ERROR kandoomsg2("E",9243,"") 			#9243 Payment start date must be entered
				NEXT FIELD paystart_date 
			END IF 
			
		AFTER FIELD payend_date 
			IF modu_payend_date IS NULL THEN 
				ERROR kandoomsg2("E",9243,"") 			#9243 Payment END date must be entered
				NEXT FIELD payend_date 
			END IF 
			IF modu_payend_date < modu_paystart_date THEN 
				ERROR kandoomsg2("E",9244,"") 			#9244 Payment END date can NOT be less than start date
				NEXT FIELD payend_date 
			END IF 
			
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
			ELSE 
				IF modu_invstart_date IS NULL THEN 
					ERROR kandoomsg2("E",9243,"") 				#9243 Invoice start date must be entered
					NEXT FIELD invstart_date 
				END IF 
				IF modu_invend_date IS NULL THEN 
					ERROR kandoomsg2("E",9243,"") 				#9243 Invoice END date must be entered
					NEXT FIELD invend_date 
				END IF 
				IF modu_invend_date < modu_invstart_date THEN 
					ERROR kandoomsg2("E",9244,"") 				#9244 invoice END date can NOT be less than start date
					NEXT FIELD invend_date 
				END IF 
				IF modu_paystart_date IS NULL THEN 
					ERROR kandoomsg2("E",9243,"") 				#9243 Payment start date must be entered
					NEXT FIELD paystart_date 
				END IF 
				IF modu_payend_date IS NULL THEN 
					ERROR kandoomsg2("E",9243,"") 				#9243 Payment END date must be entered
					NEXT FIELD payend_date 
				END IF 
				IF modu_payend_date < modu_paystart_date THEN 
					ERROR kandoomsg2("E",9244,"") 				#9244 Payment END date can NOT be less than start date
					NEXT FIELD payend_date 
				END IF 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	CONSTRUCT BY NAME l_where_text ON invoicehead.inv_ind, 
	invoicehead.sale_code, 
	salesperson.name_text, 
	salesperson.terri_code, 
	salesperson.sale_type_ind, 
	salesperson.mgr_code, 
	invoicehead.cust_code, 
	invoicehead.total_amt, 
	invoicehead.paid_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E85","construct-invoicehead-1") -- albo kd-502 
			DISPLAY "5|6" TO invoicehead.inv_ind 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_date = modu_invstart_date 
		LET glob_rec_rpt_selector.ref2_date = modu_invend_date 
		LET glob_rec_rpt_selector.ref3_date = modu_paystart_date 
		LET glob_rec_rpt_selector.ref4_date = modu_payend_date 
		LET glob_rec_rpt_selector.ref1_ind = l_paid_flag 
		RETURN l_where_text 
	END IF 
END FUNCTION


###########################################################################
# FUNCTION E85_rpt_process()
#
#
###########################################################################
FUNCTION E85_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING	
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE l_paid_flag char(1)
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.*
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
		comm_amt LIKE invoicedetl.comm_amt, 
		commpay_amt LIKE invoicedetl.comm_amt 
	END RECORD
	DEFINE l_idx SMALLINT 		
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"E85_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E85_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	#retrieve additional rmsreps values
	LET modu_invstart_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date  
	LET modu_invend_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_date  
	LET modu_paystart_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_date  
	LET modu_payend_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_date  
	LET l_paid_flag = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind  
	#------------------------------------------------------------

	LET l_query_text = "SELECT invoicehead.* ", 
	"FROM invoicehead,", 
	"salesperson ", 
	"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND salesperson.cmpy_code = invoicehead.cmpy_code ", 
	"AND salesperson.sale_code = invoicehead.sale_code ", 
	"AND invoicehead.inv_date between '",modu_invstart_date, 
	"' AND '",modu_invend_date,"' ", 
	"AND invoicehead.posted_flag NOT in ('V', 'H') ", 
	"AND ",p_where_text clipped 
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead cursor FOR s_invoicehead
	 
	LET l_query_text = " SELECT * FROM invoicedetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND inv_num = ?" 
	PREPARE s_invoicedetl FROM l_query_text 
	DECLARE c_invoicedetl cursor FOR s_invoicedetl
	 
	LET l_query_text = " SELECT * FROM saleshare ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND order_num = ?" 
	PREPARE s_saleshare FROM l_query_text 
	DECLARE c_saleshare cursor FOR s_saleshare 

	--MESSAGE kandoomsg2("E",1045,"")	#1045 Reporting on Salesperson...
	FOREACH c_invoicehead INTO l_rec_invoicehead.*
	 
		IF int_flag OR quit_flag THEN 
			IF kandoomsg("U",8503,"") = "N" THEN #8503 Continue Report(Y/N) 
				ERROR kandoomsg2("U",9501,"")#9501 Report Terminated 
				EXIT FOREACH 
			ELSE 
				LET quit_flag = FALSE 
				LET int_flag = FALSE 
			END IF 
		END IF 
		DISPLAY l_rec_invoicehead.sale_code at 1,28 

		LET l_rec_invoicehead.paid_amt = 0 
		SELECT sum(pay_amt) INTO l_rec_invoicehead.paid_amt 
		FROM invoicepay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = l_rec_invoicehead.inv_num 
		AND pay_date between modu_paystart_date AND modu_payend_date 
		AND pay_type_ind = TRAN_TYPE_RECEIPT_CA 

		IF l_rec_invoicehead.paid_amt IS NULL THEN 
			LET l_rec_invoicehead.paid_amt = 0 
		END IF 
		IF l_paid_flag = "2" THEN 
			IF l_rec_invoicehead.paid_amt = 0 THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 

		OPEN c_invoicedetl USING l_rec_invoicehead.inv_num 
		FOREACH c_invoicedetl INTO l_rec_invoicedetl.* 
			IF l_rec_invoicedetl.comm_amt IS NULL THEN 
				LET l_rec_invoicedetl.comm_amt = 0 
			END IF 

			OPEN c_saleshare USING l_rec_invoicedetl.order_num 
			LET l_idx = 0 
			FOREACH c_saleshare INTO l_rec_saleshare.* 
				LET l_idx = l_idx + 1 
				IF l_rec_saleshare.share_per > 0 THEN 
					UPDATE t_salescomm 
					SET comm_amt = comm_amt + l_rec_invoicedetl.comm_amt 
					WHERE sale_code = l_rec_saleshare.sale_code 
					AND inv_num = l_rec_invoicehead.inv_num 
					IF sqlca.sqlerrd[3] = 0 THEN 
						INSERT INTO t_salescomm VALUES (l_rec_saleshare.sale_code, 
						l_rec_invoicehead.cust_code, 
						l_rec_invoicehead.inv_num, 
						l_rec_invoicehead.inv_date, 
						l_rec_invoicehead.total_amt, 
						l_rec_invoicehead.currency_code, 
						l_rec_invoicehead.paid_amt, 
						l_rec_saleshare.share_per, 
						l_rec_invoicedetl.comm_amt, 
						0) 
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
					l_rec_invoicedetl.comm_amt, 
					0) 

				END IF 
			END IF 
		END FOREACH 
		
	END FOREACH 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	
	DECLARE c_t_salescomm cursor FOR 
	SELECT * 
	FROM t_salescomm 
	ORDER BY sale_code, 
	inv_date, 
	inv_num 
	
	FOREACH c_t_salescomm INTO l_rec_salescomm.* 
		IF l_rec_salescomm.total_amt = 0 
		OR l_rec_salescomm.paid_amt = 0 THEN 
		ELSE 
			LET l_rec_salescomm.commpay_amt = 
			((l_rec_salescomm.paid_amt / l_rec_salescomm.total_amt) 
			* l_rec_salescomm.comm_amt ) * ( l_rec_salescomm.share_per / 100) 
		END IF 
		
	 	#---------------------------------------------------------
		OUTPUT TO REPORT E85_rpt_list(l_rpt_idx,
		l_rec_salescomm.*)   
		
		IF NOT rpt_int_flag_handler2("Sales Comm.:",l_rec_salescomm.sale_code,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		

	END FOREACH 

	DELETE FROM t_salescomm WHERE 1=1 

	#------------------------------------------------------------
	FINISH REPORT E85_rpt_list
	CALL rpt_finish("E85_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 


###########################################################################
# FUNCTION E85_rpt_query()
#
#
###########################################################################
REPORT E85_rpt_list(p_rpt_idx,p_rec_salescomm) 
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
		comm_amt LIKE invoicedetl.comm_amt, 
		commpay_amt LIKE invoicehead.total_amt 
	END RECORD
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 

	OUTPUT 

	ORDER external BY p_rec_salescomm.sale_code, 
	p_rec_salescomm.inv_date, 
	p_rec_salescomm.inv_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Inv.Date", 
			COLUMN 11, "Invoice", 
			COLUMN 20, "Customer", 
			COLUMN 37, "Invoice", 
			COLUMN 53, "Payment", 
			COLUMN 69, "Commission", 
			COLUMN 102, "Share%", 
			COLUMN 111, "Commission" 
			PRINT COLUMN 11, "Number ", 
			COLUMN 37, "Total", 
			COLUMN 53, "Amount", 
			COLUMN 71, " Base ", 
			COLUMN 113, " Payable " 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

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

		BEFORE GROUP OF p_rec_salescomm.sale_code 
			SKIP TO top OF PAGE 
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_salescomm.inv_date USING "dd/mm/yy", 
			COLUMN 10, p_rec_salescomm.inv_num USING "########", 
			COLUMN 20, p_rec_salescomm.cust_code, 
			COLUMN 29, p_rec_salescomm.total_amt USING "--,---,---.&&", 
			COLUMN 47, p_rec_salescomm.paid_amt USING "--,---,---.&&", 
			COLUMN 67, p_rec_salescomm.comm_amt USING "-,---,---.&&", 
			COLUMN 102, p_rec_salescomm.share_per USING "###.&", 
			COLUMN 110, p_rec_salescomm.commpay_amt USING "-,---,---.&&" 
		AFTER GROUP OF p_rec_salescomm.sale_code 
			PRINT COLUMN 29,"----------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"---------" 
			PRINT COLUMN 10, "Totals FOR: ", p_rec_salescomm.sale_code clipped, 
			COLUMN 29, GROUP sum(p_rec_salescomm.total_amt) 
			USING "--,---,---.&&", 
			COLUMN 47, GROUP sum(p_rec_salescomm.paid_amt) 
			USING "--,---,---.&&", 
			COLUMN 66, GROUP sum(p_rec_salescomm.comm_amt) 
			USING "--,---,---.&&", 
			COLUMN 110,group sum(p_rec_salescomm.commpay_amt) USING "-,---,---.&&" 
		ON LAST ROW 
			PRINT COLUMN 29,"----------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"---------" 
			PRINT COLUMN 1, "Report totals:", 
			COLUMN 29, sum(p_rec_salescomm.total_amt) 
			USING "--,---,---.&&", 
			COLUMN 47, sum(p_rec_salescomm.paid_amt) 
			USING "--,---,---.&&", 
			COLUMN 66, sum(p_rec_salescomm.comm_amt) 
			USING "--,---,---.&&", 
			COLUMN 110,sum(p_rec_salescomm.commpay_amt) USING "-,---,---.&&" 
			PRINT COLUMN 1, "(in base currency)" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

END REPORT 
