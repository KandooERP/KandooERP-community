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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A62_GLOBALS.4gl"

#######################################################################
# FUNCTION A62_main() 
#
# Trial Banking Print
#######################################################################
FUNCTION A62_main() 

	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A62") 

	OPEN WINDOW A687 with FORM "A687" 
	CALL windecoration_a("A687") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	IF get_url_bankdepartment_number() IS NOT NULL THEN 
		LET glob_argument_passed = TRUE 
	END IF 

	WHILE select_deposit() 
	END WHILE 

	CLOSE WINDOW A687 

END FUNCTION 
#######################################################################
# END FUNCTION A62_main() 
#######################################################################

#######################################################################
# FUNCTION select_deposit()
#
#
#######################################################################
FUNCTION select_deposit() 
	DEFINE l_arr_rec_tentbankhead DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		bank_code LIKE tentbankhead.bank_code, 
		bank_dep_num LIKE tentbankhead.bank_dep_num, 
		desc_text LIKE tentbankhead.desc_text, 
		deposit_amt DECIMAL(16,2), 
		status_flag CHAR(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF glob_argument_passed THEN
		CALL db_tentbankhead_get_datasource(TRUE) RETURNING l_arr_rec_tentbankhead
	ELSE
		CALL db_tentbankhead_get_datasource(FALSE) RETURNING l_arr_rec_tentbankhead
	END IF

	MESSAGE kandoomsg2("A",1042,"") #1038 "ENTER TO Generate Trial Deposit List; OK TO Continue."

	DISPLAY ARRAY l_arr_rec_tentbankhead TO sr_tentbankhead.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A62","inp-arr-tentbankhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_tentbankhead.CLEAR()
			CALL db_tentbankhead_get_datasource(TRUE) RETURNING l_arr_rec_tentbankhead

		ON ACTION ("REPORT","DOUBLECLICK")
			LET l_idx = arr_curr() 
			LET l_arr_rec_tentbankhead[l_idx].scroll_flag = NULL 

			IF l_arr_rec_tentbankhead[l_idx].bank_dep_num IS NOT NULL 
			AND l_arr_rec_tentbankhead[l_idx].bank_dep_num != 0 THEN 
				CALL A62_rpt_process(l_arr_rec_tentbankhead[l_idx].bank_dep_num) 
			END IF 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE
	ELSE
		RETURN TRUE	
	END IF 
 
END FUNCTION 
#######################################################################
# END FUNCTION select_deposit()
#######################################################################


#######################################################################
# FUNCTION A62_rpt_process(p_rec_bank_dep_num)
#
#
#######################################################################
FUNCTION A62_rpt_process(p_rec_bank_dep_num) 
	DEFINE p_rec_bank_dep_num INTEGER
	DEFINE l_query_text STRING
	DEFINE l_where_part STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_tentbankdetl RECORD LIKE tentbankdetl.* 

	LET l_where_part = " tentbankdetl.bank_dep_num = ", trim(p_rec_bank_dep_num)
	
	#------------------------------------------------------------
	IF (p_rec_bank_dep_num IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF
	
	LET l_rpt_idx = rpt_start(getmoduleid(),"A62_rpt_list",l_where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT A62_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	
	LET glob_grand_total = 0

	LET l_query_text =
	"SELECT * FROM tentbankdetl ", 
	"WHERE tentbankdetl.cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
	"AND ",l_where_part CLIPPED," ",	
	"ORDER BY tentbankdetl.cash_type_ind, tentbankdetl.seq_num" 
 
 	PREPARE choice FROM l_query_text 
	DECLARE c_tentbankdetl CURSOR FOR choice 
		 
	FOREACH c_tentbankdetl INTO l_rec_tentbankdetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT A62_rpt_list(l_rpt_idx,l_rec_tentbankdetl.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_tentbankdetl.cust_code, l_rec_tentbankdetl.bank_dep_num,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT A62_rpt_list
	RETURN rpt_finish("A62_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
#######################################################################
# END FUNCTION A62_rpt_process(p_rec_bank_dep_num)
#######################################################################


#######################################################################
# FUNCTION db_tentbankhead_get_datasource(p_filter)
#
#
#######################################################################
FUNCTION db_tentbankhead_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_arr_rec_tentbankhead DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		bank_code LIKE tentbankhead.bank_code, 
		bank_dep_num LIKE tentbankhead.bank_dep_num, 
		desc_text LIKE tentbankhead.desc_text, 
		deposit_amt DECIMAL(16,2), 
		status_flag CHAR(1) 
	END RECORD 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT

	IF p_filter THEN
		CLEAR FORM 
		IF glob_argument_passed THEN 
			LET glob_argument_passed = FALSE 
			MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"

			LET l_query_text = 
			"SELECT * FROM tentbankhead ", 
			"WHERE tentbankhead.cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
			"AND tentbankhead.bank_dep_num = ",trim(get_url_bankdepartment_number()) 
		ELSE 
			MESSAGE kandoomsg2("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
	
			CONSTRUCT BY NAME l_where_text ON 
				tentbankhead.bank_code, 
				tentbankhead.bank_dep_num, 
				tentbankhead.desc_text 
	
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","A62","construct-bank") 
	
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),NULL) 
	
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
	
			END CONSTRUCT 
	
			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				LET l_where_text = " 1=1 "
			END IF
			LET l_query_text = 
			"SELECT * FROM tentbankhead ", 
			"WHERE tentbankhead.cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
			"AND ",l_where_text CLIPPED," ", 
			"ORDER BY tentbankhead.bank_code, tentbankhead.bank_dep_num" 
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
		LET l_query_text = 
		"SELECT * FROM tentbankhead ", 
		"WHERE tentbankhead.cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY tentbankhead.bank_code, tentbankhead.bank_dep_num" 
	END IF
			
	MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"
 
	PREPARE s_tentbankhead FROM l_query_text 
	DECLARE c_tentbankhead CURSOR FOR s_tentbankhead 

	LET l_idx = 0 
	CALL l_arr_rec_tentbankhead.CLEAR()
	FOREACH c_tentbankhead INTO l_rec_tentbankhead.* 
		LET l_idx = l_idx + 1 
		INITIALIZE l_arr_rec_tentbankhead[l_idx].* TO NULL 

		LET l_arr_rec_tentbankhead[l_idx].bank_code = l_rec_tentbankhead.bank_code 
		LET l_arr_rec_tentbankhead[l_idx].bank_dep_num = l_rec_tentbankhead.bank_dep_num 
		LET l_arr_rec_tentbankhead[l_idx].desc_text = l_rec_tentbankhead.desc_text 

		IF l_rec_tentbankhead.status_ind MATCHES "[23]" THEN 
			LET l_arr_rec_tentbankhead[l_idx].status_flag = "*" 
		END IF 

		SELECT SUM(tentbankdetl.tran_amt) INTO l_arr_rec_tentbankhead[l_idx].deposit_amt 
		FROM tentbankdetl 
		WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tentbankdetl.bank_dep_num = l_rec_tentbankhead.bank_dep_num

	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)  #U9113 l_idx records selected

	RETURN  l_arr_rec_tentbankhead

END FUNCTION	
#######################################################################
# END FUNCTION db_tentbankhead_get_datasource(p_filter)
#######################################################################


#######################################################################
# REPORT A62_rpt_list(p_rpt_idx,p_rec_tentbankdetl) 
#
#
#######################################################################
REPORT A62_rpt_list(p_rpt_idx,p_rec_tentbankdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tentbankdetl RECORD LIKE tentbankdetl.*
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_payment_text CHAR(8)
	DEFINE l_type_total DECIMAL(16,2) 

	ORDER EXTERNAL BY p_rec_tentbankdetl.cash_type_ind, p_rec_tentbankdetl.seq_num 

	FORMAT 
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 

			SELECT * INTO l_rec_tentbankhead.* FROM tentbankhead 
			WHERE tentbankhead.bank_dep_num = p_rec_tentbankdetl.bank_dep_num 
			AND tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank.bank_code = l_rec_tentbankhead.bank_code 
			SKIP 1 LINE 
			PRINT 
			COLUMN 02, "Bank: ",l_rec_tentbankhead.bank_code CLIPPED," ", 
			"Account: ", l_rec_bank.iban CLIPPED," ", 
			l_rec_bank.name_acct_text CLIPPED," ", 
			"Currency: ", l_rec_bank.currency_code CLIPPED
			PRINT 
			COLUMN 02, "Bank Deposit Number: ", 
			l_rec_tentbankhead.bank_dep_num USING "<<<<<<<&", 
			COLUMN 35, l_rec_tentbankhead.desc_text CLIPPED
			SKIP 1 LINE 

	BEFORE GROUP OF p_rec_tentbankdetl.cash_type_ind 
		LET l_type_total = 0 
		CASE p_rec_tentbankdetl.cash_type_ind 
			WHEN "C" 
				LET l_payment_text = "CASH" 
			WHEN PAYMENT_TYPE_CHEQUE_Q 
				LET l_payment_text = "CHEQUE" 
			WHEN "P" 
				LET l_payment_text = "PLASTIC" 
			OTHERWISE 
				LET l_payment_text = "OTHER" 
		END CASE 
		PRINT
		COLUMN 02, "Payment Type: ", 
		COLUMN 16, l_payment_text CLIPPED 
		SKIP 1 LINE 

	ON EVERY ROW 
		PRINT 
		COLUMN 01, p_rec_tentbankdetl.seq_num   USING "####", 
		COLUMN 07, p_rec_tentbankdetl.cash_num  USING "########", 
		COLUMN 17, p_rec_tentbankdetl.cash_date USING "dd/mm/yyyy", 
		COLUMN 28, p_rec_tentbankdetl.tran_amt  USING "---,---,--&.&&", 
		COLUMN 44, p_rec_tentbankdetl.drawer_text CLIPPED, 
		COLUMN 65, p_rec_tentbankdetl.bank_text CLIPPED, 
		COLUMN 81, p_rec_tentbankdetl.branch_text CLIPPED, 
		COLUMN 102,p_rec_tentbankdetl.cheque_text CLIPPED, 
		COLUMN 113,p_rec_tentbankdetl.locn_code CLIPPED, 
		COLUMN 122,p_rec_tentbankdetl.station_code CLIPPED
		LET l_type_total = l_type_total + p_rec_tentbankdetl.tran_amt 

	AFTER GROUP OF p_rec_tentbankdetl.cash_type_ind 
		NEED 2 LINES 
		PRINT COLUMN 27, "---------------" 
		PRINT 
		COLUMN 20, "Total: ", 
		COLUMN 27, l_type_total                 USING "----,---,--&.&&" 
		SKIP 2 LINES 
		LET glob_grand_total = glob_grand_total + l_type_total 

	ON LAST ROW 
		PRINT COLUMN 27, "---------------" 
		PRINT 
		COLUMN 13, "Report Total:", 
		COLUMN 27, glob_grand_total             USING "----,---,--&.&&" 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT
#######################################################################
# END REPORT A62_rpt_list(p_rpt_idx,p_rec_tentbankdetl) 
#######################################################################