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
GLOBALS "../qe/Q_QE_GLOBALS.4gl" 
GLOBALS "../qe/QA8a_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################

#######################################################################
# MAIN
#
# \brief module QA8  - Quotation Print
#                 The actual REPORT routines are contained in QA8a,QA8b
#                 modules.
#          QA8a - Standard
#          QA8b - site specific
#
#  System tailoring option exists TO determined whether quotes are printed
#  in individual RMS files OR are consolidated INTO 1 file.
#######################################################################
MAIN 

	CALL setModuleId("QA8") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_q_qe() 

	SELECT * INTO glob_rec_qpparms.* FROM qpparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("Q",5002,"") 
		#5001 "Parameters do NOT exist, add quotation parameters"
		EXIT program 
	END IF 
	SELECT * INTO pr_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("A",7005,"") 
		#7005 AR Parms do NOT exist
		EXIT program 
	END IF 
	LET pr_temp_text = pr_arparms.inv_ref1_text clipped, "................" 
	LET pr_arparms.inv_ref1_text = pr_temp_text 
	LET pr_single_rms_flag = get_kandoooption_feature_state("QE","01") 
	IF pr_single_rms_flag = "Y" THEN ELSE 
		LET pr_single_rms_flag = "N" 
	END IF 
	LET rpt_width = 132 
	SELECT printcodes.* INTO pr_printcodes.* 
	FROM printcodes, 
	rmsparm 
	WHERE rmsparm.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rmsparm.order_print_text = printcodes.print_code 
	OPEN WINDOW q100 with FORM "Q100" -- alch kd-747 
	CALL windecoration_q("Q100") -- alch kd-747 
	LET pr_arparms.inv_ref1_text = pr_arparms.inv_ref1_text clipped, 
	"................" 

	DISPLAY BY NAME pr_arparms.inv_ref1_text 

	MENU " Quotation Print" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","QA8","menu-quot_print-1") -- alch kd-501 

		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "REPORT" --COMMAND "Report"	" Enter selection criteria AND generate quotes " 
			IF qa8_query() THEN 
				LET rpt_pageno = 0 
				NEXT option "Print Manager" 
			END IF 

		ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Report Management System"
			CALL run_prog("URS","","","","") 

		#Custom TRAILER message ??????
		--COMMAND "Message" 
		--	" Enter MESSAGE TO appear on quote trailer" 
		--	CALL quote_message()
			 
		COMMAND "Device" " SELECT printer type FOR creating PRINT file" 
			LET pr_temp_text = get_print(glob_rec_kandoouser.cmpy_code,pr_printcodes.print_code) 
			IF pr_temp_text IS NOT NULL THEN 
				SELECT * INTO pr_printcodes.* 
				FROM printcodes 
				WHERE print_code = pr_temp_text 
				IF sqlca.sqlcode = notfound THEN 
					# Printer edited / removed
				END IF 
				NEXT option "Report" 
			END IF 
			
		ON ACTION "CANCEL" COMMAND KEY(interrupt,"E") "Exit" " EXIT PROGRAM" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW Q100 
END MAIN 


FUNCTION qa8_query() 
	DEFINE pr_quotehead RECORD LIKE quotehead.* 
	DEFINE pr_quotedetl RECORD LIKE quotedetl.* 
	DEFINE pr_output CHAR(25) 
	DEFINE query_text STRING 
	DEFINE where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index

	LET msgresp=kandoomsg("Q",1001,"")	#1001 Enter Selection Criteria
	CONSTRUCT BY NAME where_text ON quotehead.cust_code, 
	customer.name_text, 
	quotehead.order_num, 
	quotehead.currency_code, 
	quotehead.goods_amt, 
	quotehead.hand_amt, 
	quotehead.freight_amt, 
	quotehead.tax_amt, 
	quotehead.total_amt, 
	quotehead.cost_amt, 
	quotehead.disc_amt, 
	quotehead.approved_by, 
	quotehead.approved_date, 
	quotehead.ord_text, 
	quotehead.quote_date, 
	quotehead.valid_date, 
	quotehead.ship_date, 
	quotehead.status_ind, 
	quotehead.entry_code, 
	quotehead.entry_date, 
	quotehead.rev_date, 
	quotehead.rev_num, 
	quotehead.com1_text, 
	quotehead.com2_text, 
	quotehead.com3_text, 
	quotehead.com4_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","QA8","const-cust_code-3") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET msgresp = kandoomsg("Q",1002,"")	#Q1002 Searching Database - pls wait

	IF pr_single_rms_flag = "N" THEN 

		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"QA8_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		
		--CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, pr_quote.order_num USING "&&&&&&&")
		
		START REPORT QA8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------

	END IF 

	LET query_text = "SELECT quotehead.*", 
	"FROM quotehead,", 
	"customer ", 
	"WHERE quotehead.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cust_code = quotehead.cust_code ", 
	"AND quotehead.approved_by IS NOT NULL ", 
	"AND ",where_text clipped," ", 
	"ORDER BY quotehead.cust_code,", 
	"quotehead.order_num" 
	PREPARE s_quotehead FROM query_text 
	DECLARE c_quotehead CURSOR with HOLD FOR s_quotehead 
	LET query_text = "SELECT * FROM quotedetl ", 
	"WHERE quotedetl.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND quotedetl.order_num = ? ", 
	"ORDER BY quotedetl.order_num,", 
	"quotedetl.line_num" 
	PREPARE s_quotedetl FROM query_text 
	DECLARE c_quotedetl CURSOR FOR s_quotedetl 
	LET msgresp = kandoomsg("Q",1500,"") ##Q1500 Quotation

	FOREACH c_quotehead INTO pr_quotehead.* 
		--DISPLAY pr_quotehead.order_num at 1,28 
		--LET rpt_note = "QE Quotation No.",pr_quotehead.order_num USING "&&&&&&&" 

		IF pr_single_rms_flag = "Y" THEN 

			#------------------------------------------------------------
			LET l_rpt_idx = rpt_start(getmoduleid(),"QA8_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF	
			
			CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, pr_quotehead.order_num  USING "&&&&&&&")
			
			START REPORT QA8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
			#------------------------------------------------------------
		 
		END IF 

		OPEN c_quotedetl USING pr_quotehead.order_num 
		FOREACH c_quotedetl INTO pr_quotedetl.*
		 
 			#---------------------------------------------------------
			OUTPUT TO REPORT QA8_rpt_list(l_rpt_idx,
			pr_quotehead.*,pr_quotedetl.*) 
			#---------------------------------------------------------
 
		END FOREACH 

		IF pr_single_rms_flag = "Y" THEN 

			#------------------------------------------------------------
			FINISH REPORT QA8_rpt_list
			CALL rpt_finish("QA8_rpt_list")
			#------------------------------------------------------------
		
		END IF 
	END FOREACH 

	IF pr_single_rms_flag = "N" THEN 
			#------------------------------------------------------------
			FINISH REPORT QA8_rpt_list
			CALL rpt_finish("QA8_rpt_list")
			#------------------------------------------------------------

	END IF 

	RETURN true 
END FUNCTION 


FUNCTION quote_message() 
	DEFINE ps_qpparms RECORD LIKE qpparms.* 

	LET ps_qpparms.* = glob_rec_qpparms.* 
	OPEN WINDOW q119 with FORM "Q119" -- alch kd-747 
	CALL windecoration_q("Q119") -- alch kd-747 

	INPUT BY NAME glob_rec_qpparms.footer1_text, 
	glob_rec_qpparms.footer2_text, 
	glob_rec_qpparms.footer3_text, 
	glob_rec_qpparms.quote_std_text WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","QA8","inp-glob_rec_qpparms-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
	END INPUT 
	CLOSE WINDOW q119 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET glob_rec_qpparms.* = ps_qpparms.* 
	END IF 
END FUNCTION 
