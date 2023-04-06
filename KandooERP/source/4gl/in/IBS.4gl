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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:32	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "I_IN_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_year_num LIKE period.year_num 
DEFINE modu_period_num LIKE period.period_num 
DEFINE modu_report_ind SMALLINT ## reporting level indicator 

############################################################
# FUNCTION IBS_main()
#
# Purpose - Warehouse History Report
############################################################
FUNCTION IBS_main()

	CALL setModuleId("IBS") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I617 WITH FORM "I617" 
			 CALL windecoration_i("I617")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Period History" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IBS","menu-Period_History-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IBS_rpt_process(IBS_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IBS_rpt_process(IBS_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I617

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IBS_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I617 with FORM "I617" 
			 CALL windecoration_i("I617") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IBS_rpt_query()) #save where clause in env 
			CLOSE WINDOW I617 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IBS_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IBS_main()
############################################################

############################################################
# FUNCTION IBT_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IBS_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

   # Enter the Fiscal Year and Fiscal Period to begin this report from.
	IF NOT enter_year_IBS() THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	END IF

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON
	prodstatus.ware_code, 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	maingrp.dept_code, 
	product.maingrp_code, 
	product.prodgrp_code, 
	product.class_code, 
	product.alter_part_code, 
	product.oem_text, 
	product.days_lead_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IBS","construct-prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION 
############################################################
# END FUNCTION IBT_rpt_query() 
############################################################

############################################################
# FUNCTION IBS_rpt_process() 
#
# The report driver
############################################################
FUNCTION IBS_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_prodhist RECORD LIKE prodhist.*
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_maingrp RECORD LIKE maingrp.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IBS_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IBS_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = " SELECT sum(credit_amt) ,", 
	" sum(pur_amt) ,", 
	" sum(reclassin_amt) ,", 
	" sum(transin_amt) ,", 
	" sum(adj_amt) ,", 
	" sum(sales_amt) ,", 
	" sum(reclassout_amt) ,", 
	" sum(transout_amt),", 
	" sum(gross_per)", 
	" FROM prodhist", 
	" WHERE cmpy_code = ? ", 
	" AND part_code = ? ", 
	" AND ware_code = ? ", 
	" AND year_num < ? " 

	PREPARE s1_prodhist FROM l_query_text 
	DECLARE c1_prodhist CURSOR FOR s1_prodhist 

	LET l_query_text = " SELECT sum(credit_amt) ,", 
	" sum(pur_amt) ,", 
	" sum(reclassin_amt) ,", 
	" sum(transin_amt) ,", 
	" sum(adj_amt) ,", 
	" sum(sales_amt) ,", 
	" sum(reclassout_amt) ,", 
	" sum(transout_amt),", 
	" sum(gross_per)", 
	" FROM prodhist", 
	" WHERE cmpy_code = ? ", 
	" AND part_code = ? ", 
	" AND ware_code = ? ", 
	" AND year_num = ? ", 
	" AND period_num< ? " 

	PREPARE s2_prodhist FROM l_query_text 
	DECLARE c2_prodhist CURSOR FOR s2_prodhist 

	LET l_query_text = 
	"SELECT warehouse.*,maingrp.*,product.*,prodstatus.*,prodhist.* ", 
	"FROM warehouse,maingrp,product,prodstatus,outer prodhist ", 
	"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND prodstatus.cmpy_code = product.cmpy_code ", 
	"AND warehouse.cmpy_code = prodstatus.cmpy_code ", 
	"AND maingrp.cmpy_code = product.cmpy_code ", 
	"AND prodstatus.part_code = product.part_code ", 
	"AND warehouse.ware_code = prodstatus.ware_code ", 
	"AND maingrp.maingrp_code = product.maingrp_code ", 
	"AND prodstatus.stocked_flag = 'Y' ", 
	"AND prodstatus.status_ind in ('1','4')", 
	"AND product.trade_in_flag = 'N' ", 
	"AND product.status_ind = '1' ", 
	"AND ", p_where_text CLIPPED," ",
	"AND prodhist.year_num = '",modu_year_num, "' ", 
	"AND prodhist.period_num = '",modu_period_num,"' ", 
	"AND prodhist.part_code = prodstatus.part_code ", 
	"AND prodhist.ware_code = prodstatus.ware_code ", 
	"AND prodhist.cmpy_code = prodstatus.cmpy_code ", 
	"ORDER BY warehouse.ware_code,maingrp.dept_code,product.maingrp_code,product.prodgrp_code,prodstatus.part_code" 

	PREPARE s_prodhist FROM l_query_text 
	DECLARE c_prodhist CURSOR FOR s_prodhist 

	FOREACH c_prodhist INTO l_rec_warehouse.*,l_rec_maingrp.*,l_rec_product.*,l_rec_prodstatus.*,l_rec_prodhist.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IBS_rpt_list(l_rpt_idx,l_rec_warehouse.*,l_rec_maingrp.*,l_rec_product.*,l_rec_prodstatus.*,l_rec_prodhist.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodstatus.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IBS_rpt_list
	RETURN rpt_finish("IBS_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IBS_rpt_process() 
############################################################

############################################################
# FUNCTION enter_year_IBS() 
#
# Purpose - Enter the Fiscal Year and Fiscal Period to begin this report from.
############################################################
FUNCTION enter_year_IBS() 
	DEFINE l_start_date LIKE period.start_date 
	DEFINE l_end_date LIKE period.start_date 
	DEFINE l_rec_period RECORD LIKE period.* 

	## Get last year + 1 month so that current period IS reported on
	## LET pr_temp_date = TODAY - 1 units year
	## LET pr_temp_date = pr_temp_date + 1 units month
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,TODAY) RETURNING modu_year_num,modu_period_num 
	MESSAGE kandoomsg2("U",1001,"") 
	#U1001 Enter selection criteria - ESC TO continue
	CLEAR FORM
	INPUT modu_year_num,modu_period_num,modu_report_ind WITHOUT DEFAULTS FROM year_num,period_num,report_ind  

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "CANCEL" 
			EXIT INPUT

		AFTER FIELD year_num 
			IF modu_year_num IS NULL OR modu_year_num = 0 THEN 
				ERROR kandoomsg2("I",9120,"") 
				#9120 Year number must be entered
				NEXT FIELD year_num 
			END IF 
			SELECT * INTO l_rec_period.* FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_year_num 
			AND period_num = modu_period_num 
         IF STATUS = NOTFOUND THEN
         	LET l_start_date = NULL
         	LET l_end_date = NULL
			ELSE
				LET l_start_date = l_rec_period.start_date 
				LET l_end_date = l_rec_period.end_date 
         END IF
			DISPLAY l_start_date, l_end_date TO start_date, end_date

		AFTER FIELD period_num 
			IF modu_period_num IS NULL OR modu_period_num = 0 THEN 
				ERROR kandoomsg2("I",9121,"") 
				#9121 Period number must be entered"
				NEXT FIELD period_num 
			END IF 
			SELECT * INTO l_rec_period.* FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_year_num 
			AND period_num = modu_period_num 
         IF STATUS = NOTFOUND THEN
         	LET l_start_date = NULL
         	LET l_end_date = NULL
			ELSE
				LET l_start_date = l_rec_period.start_date 
				LET l_end_date = l_rec_period.end_date 
         END IF
			DISPLAY l_start_date, l_end_date TO start_date, end_date

		AFTER FIELD report_ind 
			IF modu_report_ind IS NULL OR modu_report_ind = 0 THEN 
				ERROR kandoomsg2("I",9201,"") 
				#9201 Reporting level indicator must be entered
				NEXT FIELD report_ind 
			END IF

		AFTER INPUT 
			IF modu_year_num IS NULL OR modu_year_num = 0 THEN 
				ERROR kandoomsg2("I",9120,"") 
				#9120 Year number must be entered
				NEXT FIELD year_num 
			END IF 
			IF modu_period_num IS NULL OR modu_period_num = 0 THEN 
				ERROR kandoomsg2("I",9121,"") 
				#9121 Period number must be entered"
				NEXT FIELD period_num 
			END IF 
			IF modu_report_ind IS NULL OR modu_report_ind = 0 THEN 
				ERROR kandoomsg2("I",9201,"") 
				#9201 Reporting level indicator must be entered
				NEXT FIELD report_ind 
			END IF

			SELECT * INTO l_rec_period.* FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_year_num 
			AND period_num = modu_period_num 
         IF STATUS = NOTFOUND THEN
         	LET l_start_date = NULL
         	LET l_end_date = NULL
			ELSE
				LET l_start_date = l_rec_period.start_date 
				LET l_end_date = l_rec_period.end_date 
         END IF
			DISPLAY l_start_date, l_end_date TO start_date, end_date 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION enter_year_IBS() 
############################################################

############################################################
# FUNCTION null_test() 
#
#
############################################################
FUNCTION null_test(p_credit_amt,p_pur_amt,p_reclassin_amt,p_transin_amt,p_adj_amt,p_sales_amt,p_reclassout_amt,p_transout_amt,p_gross_per) 
	DEFINE p_credit_amt LIKE prodhist.sales_amt 
	DEFINE p_pur_amt LIKE prodhist.sales_amt 
	DEFINE p_reclassin_amt LIKE prodhist.sales_amt 
	DEFINE p_transin_amt LIKE prodhist.sales_amt 
	DEFINE p_adj_amt LIKE prodhist.sales_amt 
	DEFINE p_sales_amt LIKE prodhist.sales_amt
	DEFINE p_reclassout_amt LIKE prodhist.sales_amt 
	DEFINE p_transout_amt LIKE prodhist.sales_amt 
	DEFINE p_gross_per LIKE prodhist.sales_amt 

	IF p_credit_amt IS NULL THEN 
		LET p_credit_amt = 0 
	END IF 
	IF p_pur_amt IS NULL THEN 
		LET p_pur_amt = 0 
	END IF 
	IF p_reclassin_amt IS NULL THEN 
		LET p_reclassin_amt = 0 
	END IF 
	IF p_transin_amt IS NULL THEN 
		LET p_transin_amt = 0 
	END IF 
	IF p_adj_amt IS NULL THEN 
		LET p_adj_amt = 0 
	END IF 
	IF p_sales_amt IS NULL THEN 
		LET p_sales_amt = 0 
	END IF 
	IF p_reclassout_amt IS NULL THEN 
		LET p_reclassout_amt = 0 
	END IF 
	IF p_transout_amt IS NULL THEN 
		LET p_transout_amt = 0 
	END IF 
	IF p_gross_per IS NULL THEN 
		LET p_gross_per = 0 
	END IF 

	RETURN p_credit_amt, p_pur_amt, p_reclassin_amt, p_transin_amt,p_adj_amt,
			p_sales_amt, p_reclassout_amt, p_transout_amt,p_gross_per 

END FUNCTION
############################################################
# END FUNCTION null_test() 
############################################################
 
############################################################
# REPORT IBS_rpt_list(p_rpt_idx,p_rec_warehouse,p_rec_maingrp,p_rec_product,p_rec_prodstatus,p_rec_prodhist)
#
# Report Definition/Layout
############################################################
REPORT IBS_rpt_list(p_rpt_idx,p_rec_warehouse,p_rec_maingrp,p_rec_product,p_rec_prodstatus,p_rec_prodhist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE p_rec_maingrp RECORD LIKE maingrp.* 
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE p_rec_prodhist RECORD LIKE prodhist.* 
	DEFINE l_space_cnt SMALLINT ## used TO right justify part_code's ON REPORT 
	DEFINE l_total_ind SMALLINT ## indicator FOR skipping LINES b/w 
	## reporting levels
	DEFINE l_credit_amt LIKE prodhist.credit_amt
	DEFINE l_s_credit_amt LIKE prodhist.credit_amt 
	DEFINE l_pur_amt LIKE prodhist.pur_amt
	DEFINE l_s_pur_amt LIKE prodhist.pur_amt 
	DEFINE l_reclassin_amt LIKE prodhist.reclassin_amt
	DEFINE l_s_reclassin_amt LIKE prodhist.reclassin_amt 
	DEFINE l_transin_amt LIKE prodhist.transin_amt 
	DEFINE l_s_transin_amt LIKE prodhist.transin_amt 
	DEFINE l_adj_amt LIKE prodhist.adj_amt
	DEFINE l_s_adj_amt LIKE prodhist.adj_amt 
	DEFINE l_sales_amt LIKE prodhist.sales_amt
	DEFINE l_s_sales_amt LIKE prodhist.sales_amt 
	DEFINE l_reclassout_amt LIKE prodhist.reclassout_amt
	DEFINE l_s_reclassout_amt LIKE prodhist.reclassout_amt 
	DEFINE l_s_trans_amt LIKE prodhist.transout_amt
	DEFINE l_s_transout_amt LIKE prodhist.transout_amt
	DEFINE l_transout_amt LIKE prodhist.transout_amt 
	DEFINE l_prod_clos_bal LIKE prodhist.sales_amt ## product GROUP closing balance 
	DEFINE l_main_clos_bal LIKE prodhist.sales_amt ## MAIN GROUP closing balance 
	DEFINE l_dept_clos_bal LIKE prodhist.sales_amt ## department closing balance 
	DEFINE l_ware_clos_bal LIKE prodhist.sales_amt ## warehouse closing balance 
	DEFINE l_rpt_clos_bal LIKE prodhist.sales_amt ## REPORT closing balance 
	DEFINE l_prod_open_bal LIKE prodhist.sales_amt ## product GROUP opening balance 
	DEFINE l_main_open_bal LIKE prodhist.sales_amt ## MAIN GROUP opening balance 
	DEFINE l_dept_open_bal LIKE prodhist.sales_amt ## department opening balance 
	DEFINE l_ware_open_bal LIKE prodhist.sales_amt ## warehouse opening balance 
	DEFINE l_rpt_open_bal LIKE prodhist.sales_amt ## REPORT opening balance 
	DEFINE l_ytd_open_bal LIKE prodhist.sales_amt  
	DEFINE l_ytd_clos_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_prod_open_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_main_open_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_dept_open_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_ware_open_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_rpt_open_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_prod_clos_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_main_clos_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_dept_clos_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_ware_clos_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_rpt_clos_bal LIKE prodhist.sales_amt
	DEFINE l_ytd_sales_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_credit_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_pur_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_adj_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_trans_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_gross_per LIKE prodhist.sales_amt
	DEFINE l_ytd_prod_sales_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_prod_credit_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_prod_pur_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_prod_adj_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_prod_trans_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_prod_gross_per LIKE prodhist.sales_amt
	DEFINE l_ytd_main_sales_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_main_credit_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_main_pur_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_main_adj_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_main_trans_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_main_gross_per LIKE prodhist.sales_amt
	DEFINE l_ytd_dept_sales_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_dept_credit_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_dept_pur_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_dept_adj_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_dept_trans_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_dept_gross_per LIKE prodhist.sales_amt
	DEFINE l_ytd_ware_sales_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_ware_credit_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_ware_pur_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_ware_adj_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_ware_trans_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_ware_gross_per LIKE prodhist.sales_amt
	DEFINE l_ytd_rpt_sales_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_rpt_credit_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_rpt_pur_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_rpt_adj_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_rpt_trans_amt LIKE prodhist.sales_amt
	DEFINE l_ytd_rpt_gross_per LIKE prodhist.sales_amt
	DEFINE l_s_gross_per LIKE prodhist.sales_amt
	DEFINE l_gross_per LIKE prodhist.sales_amt ## gross profit - dec(16,4) b/c OF precision problems 
	DEFINE l_open_bal LIKE prodhist.sales_amt
	DEFINE l_clos_bal LIKE prodhist.sales_amt 
	DEFINE l_temp_text LIKE kandooword.response_text 
	DEFINE i SMALLINT 

	ORDER EXTERNAL BY p_rec_warehouse.ware_code,p_rec_maingrp.dept_code,p_rec_product.maingrp_code,p_rec_product.prodgrp_code,p_rec_prodstatus.part_code 

	FORMAT 
		FIRST PAGE HEADER 
				LET l_total_ind = FALSE 
				LET l_prod_open_bal = 0 
				LET l_prod_clos_bal = 0 
				LET l_main_open_bal = 0 
				LET l_main_clos_bal = 0 
				LET l_ware_open_bal = 0 
				LET l_ware_clos_bal = 0 
				LET l_dept_open_bal = 0 
				LET l_dept_clos_bal = 0 
				LET l_rpt_open_bal = 0 
				LET l_rpt_clos_bal = 0 
				LET l_ytd_prod_open_bal = 0 
				LET l_ytd_main_open_bal = 0 
				LET l_ytd_dept_open_bal = 0 
				LET l_ytd_ware_open_bal = 0 
				LET l_ytd_rpt_open_bal = 0 
				LET l_ytd_prod_clos_bal = 0 
				LET l_ytd_main_clos_bal = 0 
				LET l_ytd_dept_clos_bal = 0 
				LET l_ytd_ware_clos_bal = 0 
				LET l_ytd_rpt_clos_bal = 0 
				LET l_ytd_prod_sales_amt = 0 
				LET l_ytd_prod_credit_amt= 0 
				LET l_ytd_prod_pur_amt = 0 
				LET l_ytd_prod_adj_amt = 0 
				LET l_ytd_prod_trans_amt = 0 
				LET l_ytd_prod_gross_per = 0 
				LET l_ytd_main_sales_amt = 0 
				LET l_ytd_main_credit_amt= 0 
				LET l_ytd_main_pur_amt = 0 
				LET l_ytd_main_adj_amt = 0 
				LET l_ytd_main_trans_amt = 0 
				LET l_ytd_main_gross_per = 0 
				LET l_ytd_dept_sales_amt = 0 
				LET l_ytd_dept_credit_amt= 0 
				LET l_ytd_dept_pur_amt = 0 
				LET l_ytd_dept_adj_amt = 0 
				LET l_ytd_dept_trans_amt = 0 
				LET l_ytd_dept_gross_per = 0 
				LET l_ytd_ware_sales_amt = 0 
				LET l_ytd_ware_credit_amt= 0 
				LET l_ytd_ware_pur_amt = 0 
				LET l_ytd_ware_adj_amt = 0 
				LET l_ytd_ware_trans_amt = 0 
				LET l_ytd_ware_gross_per = 0 
				LET l_ytd_rpt_sales_amt = 0 
				LET l_ytd_rpt_credit_amt = 0 
				LET l_ytd_rpt_pur_amt = 0 
				LET l_ytd_rpt_adj_amt = 0 
				LET l_ytd_rpt_trans_amt = 0 
				LET l_ytd_rpt_gross_per = 0 

			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, "Year :", modu_year_num USING "####";
			PRINT COLUMN 33, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, "Period:", modu_period_num USING "<<<"; 
			CASE modu_report_ind 
				WHEN 1 
					PRINT COLUMN 13, "Department"; 
				WHEN 2 
					PRINT COLUMN 13, "Main Group"; 
				WHEN 3 
					PRINT COLUMN 13, "Prod.Group"; 
				WHEN 4 
					PRINT COLUMN 16, "Product"; 
			END CASE
			PRINT COLUMN 33, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, "Year :", modu_year_num USING "####";
			PRINT COLUMN 33, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, "Period:", modu_period_num USING "<<<"; 
			CASE modu_report_ind 
				WHEN 1 
					PRINT COLUMN 13, "Department"; 
				WHEN 2 
					PRINT COLUMN 13, "Main Group"; 
				WHEN 3 
					PRINT COLUMN 13, "Prod.Group"; 
				WHEN 4 
					PRINT COLUMN 16, "Product"; 
			END CASE
			PRINT COLUMN 33, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_prodstatus.part_code 
		##
		## SUM's are separated b/c NULL problems in summing altogether
		##
		## SUM TO get YTD Opening Balance
		##
		OPEN c1_prodhist USING p_rec_prodstatus.cmpy_code,p_rec_prodstatus.part_code,p_rec_prodstatus.ware_code,modu_year_num 
		FETCH c1_prodhist INTO l_credit_amt,l_pur_amt,l_reclassin_amt,l_transin_amt,l_adj_amt,l_sales_amt,l_reclassout_amt,l_transout_amt,l_gross_per 
		##
		## null_test() invoked  b/c of overheads
		## in reproducing same validation code
		##
		CALL null_test(l_credit_amt,l_pur_amt,l_reclassin_amt,l_transin_amt,l_adj_amt,l_sales_amt,l_reclassout_amt, l_transout_amt, l_gross_per) 
		RETURNING l_credit_amt,l_pur_amt, l_reclassin_amt,l_transin_amt, l_adj_amt, l_sales_amt,l_reclassout_amt,l_transout_amt, l_gross_per 
		LET l_ytd_open_bal = l_credit_amt 
		+ l_pur_amt 
		+ l_reclassin_amt 
		+ l_transin_amt 
		+ l_adj_amt 
		- l_sales_amt 
		- l_reclassout_amt 
		- l_transout_amt 
		##
		## Keep track of YTD opening balance's
		##
		LET l_ytd_prod_open_bal = l_ytd_prod_open_bal + l_ytd_open_bal 
		LET l_ytd_main_open_bal = l_ytd_main_open_bal + l_ytd_open_bal 
		LET l_ytd_ware_open_bal = l_ytd_ware_open_bal + l_ytd_open_bal 
		LET l_ytd_rpt_open_bal = l_ytd_rpt_open_bal + l_ytd_open_bal 
		IF p_rec_maingrp.dept_code IS NOT NULL THEN 
			LET l_ytd_dept_open_bal = l_ytd_dept_open_bal + l_ytd_open_bal 
		END IF 
		##
		## SUM TO get MTD Opening Balance
		##
		OPEN c2_prodhist USING p_rec_prodstatus.cmpy_code,p_rec_prodstatus.part_code,p_rec_prodstatus.ware_code,modu_year_num,modu_period_num 
		FETCH c2_prodhist INTO l_credit_amt,l_pur_amt,l_reclassin_amt,l_transin_amt,l_adj_amt,l_sales_amt,l_reclassout_amt,l_transout_amt,l_gross_per 
		CALL null_test(l_credit_amt,l_pur_amt,l_reclassin_amt,l_transin_amt,l_adj_amt,l_sales_amt,l_reclassout_amt,l_transout_amt,l_gross_per) 
		RETURNING l_credit_amt,l_pur_amt,l_reclassin_amt,l_transin_amt,l_adj_amt,l_sales_amt,l_reclassout_amt,l_transout_amt,l_gross_per 
		LET l_open_bal = l_ytd_open_bal ## add prior balance 
		+ l_credit_amt 
		+ l_pur_amt 
		+ l_reclassin_amt 
		+ l_transin_amt 
		+ l_adj_amt 
		- l_sales_amt 
		- l_reclassout_amt 
		- l_transout_amt 
		IF p_rec_prodhist.period_num IS NOT NULL THEN 
			CALL null_test(p_rec_prodhist.credit_amt,p_rec_prodhist.pur_amt,p_rec_prodhist.reclassin_amt,p_rec_prodhist.transin_amt,p_rec_prodhist.adj_amt,p_rec_prodhist.sales_amt,
			               p_rec_prodhist.reclassout_amt,p_rec_prodhist.transout_amt,p_rec_prodhist.gross_per) 
			RETURNING p_rec_prodhist.credit_amt,p_rec_prodhist.pur_amt,p_rec_prodhist.reclassin_amt,p_rec_prodhist.transin_amt,p_rec_prodhist.adj_amt,p_rec_prodhist.sales_amt,
						p_rec_prodhist.reclassout_amt,p_rec_prodhist.transout_amt,p_rec_prodhist.gross_per 
			LET l_clos_bal = l_open_bal 
			+ p_rec_prodhist.credit_amt 
			+ p_rec_prodhist.pur_amt 
			+ p_rec_prodhist.reclassin_amt 
			+ p_rec_prodhist.transin_amt 
			+ p_rec_prodhist.adj_amt 
			- p_rec_prodhist.sales_amt 
			- p_rec_prodhist.reclassout_amt 
			- p_rec_prodhist.transout_amt 
		ELSE 
			LET l_clos_bal = l_open_bal 
		END IF 

		LET l_prod_open_bal = l_prod_open_bal + l_open_bal 
		LET l_prod_clos_bal = l_prod_clos_bal + l_clos_bal 
		LET l_main_open_bal = l_main_open_bal + l_open_bal 
		LET l_main_clos_bal = l_main_clos_bal + l_clos_bal 
		LET l_ware_open_bal = l_ware_open_bal + l_open_bal 
		LET l_ware_clos_bal = l_ware_clos_bal + l_clos_bal 
		LET l_rpt_open_bal = l_rpt_open_bal + l_open_bal 
		LET l_rpt_clos_bal = l_rpt_clos_bal + l_clos_bal 
		##
		## Main Group may NOT always belong TO a Department
		##
		IF p_rec_maingrp.dept_code IS NOT NULL THEN 
			LET l_dept_open_bal = l_dept_open_bal + l_open_bal 
			LET l_dept_clos_bal = l_dept_clos_bal + l_clos_bal 
		END IF 

		IF modu_report_ind = 4 THEN 
			IF l_total_ind THEN 
				SKIP 1 line 
				LET l_total_ind = FALSE 
			END IF 
		END IF 

	BEFORE GROUP OF p_rec_product.prodgrp_code 
		IF modu_report_ind = 3 THEN 
			IF l_total_ind THEN 
				SKIP 1 line 
				LET l_total_ind = FALSE 
			END IF 
		END IF 

	BEFORE GROUP OF p_rec_product.maingrp_code 
		IF modu_report_ind = 2 THEN 
			IF l_total_ind THEN 
				SKIP 1 line 
				LET l_total_ind = FALSE 
			END IF 
		END IF 

	BEFORE GROUP OF p_rec_maingrp.dept_code 
		IF modu_report_ind = 1 THEN 
			IF l_total_ind THEN 
				SKIP 1 line 
				LET l_total_ind = FALSE 
			END IF 
		END IF 

	BEFORE GROUP OF p_rec_warehouse.ware_code 
		SKIP 1 line 
		NEED 3 LINES ## warehouse / SKIP 1 line / xxx mtd: 
		PRINT COLUMN 01, "WAREHOUSE:", 
		COLUMN 12, p_rec_warehouse.ware_code, 
		COLUMN 16, p_rec_warehouse.desc_text clipped 
		SKIP 1 line 

	AFTER GROUP OF p_rec_prodstatus.part_code 
		IF p_rec_prodhist.period_num IS NOT NULL THEN 
			LET l_s_sales_amt = GROUP sum(p_rec_prodhist.sales_amt) 
			LET l_s_credit_amt = GROUP sum(p_rec_prodhist.credit_amt) 
			LET l_s_pur_amt = GROUP sum(p_rec_prodhist.pur_amt) 
			LET l_s_adj_amt = GROUP sum(p_rec_prodhist.adj_amt) 
			LET l_s_transin_amt = GROUP sum(p_rec_prodhist.transin_amt) 
			LET l_s_transout_amt = GROUP sum(p_rec_prodhist.transout_amt) 
			LET l_s_gross_per = GROUP sum(p_rec_prodhist.gross_per) 
			CALL null_test(l_s_credit_amt,l_s_pur_amt,'',l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,'',l_s_transout_amt, l_s_gross_per) 
			RETURNING l_s_credit_amt, l_s_pur_amt, l_s_reclassin_amt,l_s_transin_amt, l_s_adj_amt,l_s_sales_amt,l_s_reclassout_amt,l_s_transout_amt,l_s_gross_per 
			LET l_s_trans_amt = l_s_transin_amt - l_s_transout_amt 
		ELSE 
			LET l_s_sales_amt = 0 
			LET l_s_credit_amt = 0 
			LET l_s_pur_amt = 0 
			LET l_s_adj_amt = 0 
			LET l_s_trans_amt = 0 
			LET l_s_gross_per = 0 
		END IF 
		##
		## YTD FOR product
		##
		LET l_ytd_sales_amt = l_s_sales_amt + l_sales_amt 
		LET l_ytd_credit_amt = l_s_credit_amt + l_credit_amt 
		LET l_ytd_pur_amt = l_s_pur_amt + l_pur_amt 
		LET l_ytd_adj_amt = l_s_adj_amt + l_adj_amt 
		LET l_ytd_trans_amt = l_s_trans_amt 
		+ l_transin_amt 
		- l_transout_amt 
		LET l_ytd_gross_per = l_s_gross_per + l_gross_per 
		##
		## Keep track of YTD closing balance's
		##
		LET l_ytd_clos_bal = l_ytd_open_bal 
		+ l_ytd_credit_amt 
		+ l_ytd_pur_amt 
		+ l_ytd_trans_amt 
		+ l_ytd_adj_amt 
		- l_ytd_sales_amt 
		LET l_ytd_prod_clos_bal = l_ytd_prod_clos_bal + l_ytd_clos_bal 
		LET l_ytd_main_clos_bal = l_ytd_main_clos_bal + l_ytd_clos_bal 
		LET l_ytd_ware_clos_bal = l_ytd_ware_clos_bal + l_ytd_clos_bal 
		LET l_ytd_rpt_clos_bal = l_ytd_rpt_clos_bal + l_ytd_clos_bal 
		IF p_rec_maingrp.dept_code IS NOT NULL THEN 
			LET l_ytd_dept_clos_bal = l_ytd_dept_clos_bal + l_ytd_clos_bal 
		END IF 
		##
		## YTD FOR product group
		##
		LET l_ytd_prod_sales_amt = l_ytd_prod_sales_amt +l_ytd_sales_amt 
		LET l_ytd_prod_credit_amt= l_ytd_prod_credit_amt+l_ytd_credit_amt 
		LET l_ytd_prod_pur_amt = l_ytd_prod_pur_amt +l_ytd_pur_amt 
		LET l_ytd_prod_adj_amt = l_ytd_prod_adj_amt +l_ytd_adj_amt 
		LET l_ytd_prod_trans_amt = l_ytd_prod_trans_amt +l_ytd_trans_amt 
		LET l_ytd_prod_gross_per = l_ytd_prod_gross_per +l_ytd_gross_per 
		##
		## YTD FOR main group
		##
		LET l_ytd_main_sales_amt = l_ytd_main_sales_amt +l_ytd_sales_amt 
		LET l_ytd_main_credit_amt= l_ytd_main_credit_amt+l_ytd_credit_amt 
		LET l_ytd_main_pur_amt = l_ytd_main_pur_amt +l_ytd_pur_amt 
		LET l_ytd_main_adj_amt = l_ytd_main_adj_amt +l_ytd_adj_amt 
		LET l_ytd_main_trans_amt = l_ytd_main_trans_amt +l_ytd_trans_amt 
		LET l_ytd_main_gross_per = l_ytd_main_gross_per +l_ytd_gross_per 
		##
		## YTD FOR department
		##
		IF p_rec_maingrp.dept_code IS NOT NULL THEN 
			LET l_ytd_dept_sales_amt = l_ytd_dept_sales_amt +l_ytd_sales_amt 
			LET l_ytd_dept_credit_amt= l_ytd_dept_credit_amt+l_ytd_credit_amt 
			LET l_ytd_dept_pur_amt = l_ytd_dept_pur_amt +l_ytd_pur_amt 
			LET l_ytd_dept_adj_amt = l_ytd_dept_adj_amt +l_ytd_adj_amt 
			LET l_ytd_dept_trans_amt = l_ytd_dept_trans_amt +l_ytd_trans_amt 
			LET l_ytd_dept_gross_per = l_ytd_dept_gross_per +l_ytd_gross_per 
		END IF 
		##
		## YTD FOR warehouse
		##
		LET l_ytd_ware_sales_amt = l_ytd_ware_sales_amt +l_ytd_sales_amt 
		LET l_ytd_ware_credit_amt= l_ytd_ware_credit_amt+l_ytd_credit_amt 
		LET l_ytd_ware_pur_amt = l_ytd_ware_pur_amt +l_ytd_pur_amt 
		LET l_ytd_ware_adj_amt = l_ytd_ware_adj_amt +l_ytd_adj_amt 
		LET l_ytd_ware_trans_amt = l_ytd_ware_trans_amt +l_ytd_trans_amt 
		LET l_ytd_ware_gross_per = l_ytd_ware_gross_per +l_ytd_gross_per 
		##
		## YTD FOR REPORT
		##
		LET l_ytd_rpt_sales_amt = l_ytd_rpt_sales_amt +l_ytd_sales_amt 
		LET l_ytd_rpt_credit_amt= l_ytd_rpt_credit_amt+l_ytd_credit_amt 
		LET l_ytd_rpt_pur_amt = l_ytd_rpt_pur_amt +l_ytd_pur_amt 
		LET l_ytd_rpt_adj_amt = l_ytd_rpt_adj_amt +l_ytd_adj_amt 
		LET l_ytd_rpt_trans_amt = l_ytd_rpt_trans_amt +l_ytd_trans_amt 
		LET l_ytd_rpt_gross_per = l_ytd_rpt_gross_per +l_ytd_gross_per 
		##
		##
		##
		IF modu_report_ind = 4 THEN 
			NEED 2 LINES 
			LET l_space_cnt = 15 - length(p_rec_prodstatus.part_code) 
			PRINT COLUMN 08, l_space_cnt spaces, 
			p_rec_prodstatus.part_code clipped, 
			COLUMN 25, "MTD:", 
			COLUMN 29, l_open_bal      USING "-------&.&&", 
			COLUMN 41, l_s_sales_amt     USING "--------&.&&", 
			COLUMN 54, l_s_credit_amt    USING "-------&.&&", 
			COLUMN 66, l_s_pur_amt       USING "-------&.&&", 
			COLUMN 78, l_s_adj_amt       USING "-------&.&&", 
			COLUMN 90, l_s_trans_amt     USING "-------&.&&", 
			COLUMN 102, l_clos_bal     USING "-------&.&&", 
			COLUMN 114, ( l_clos_bal - l_open_bal )USING "-------&.&&", 
			COLUMN 126, l_s_gross_per     USING "---&.&&" 
			PRINT COLUMN 25, "YTD:", 
			COLUMN 29, l_ytd_open_bal   USING "-------&.&&", 
			COLUMN 41, l_ytd_sales_amt  USING "--------&.&&", 
			COLUMN 54, l_ytd_credit_amt USING "-------&.&&", 
			COLUMN 66, l_ytd_pur_amt    USING "-------&.&&", 
			COLUMN 78, l_ytd_adj_amt    USING "-------&.&&", 
			COLUMN 90, l_ytd_trans_amt  USING "-------&.&&", 
			COLUMN 102, l_ytd_clos_bal  USING "-------&.&&", 
			COLUMN 114, ( l_ytd_clos_bal - l_ytd_open_bal ) USING "-------&.&&", 
			COLUMN 126, l_ytd_gross_per USING "---&.&&" 
		END IF 

	AFTER GROUP OF p_rec_product.prodgrp_code 
		LET l_s_sales_amt = GROUP sum(p_rec_prodhist.sales_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_credit_amt = GROUP sum(p_rec_prodhist.credit_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_pur_amt = GROUP sum(p_rec_prodhist.pur_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_adj_amt = GROUP sum(p_rec_prodhist.adj_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_transin_amt = GROUP sum(p_rec_prodhist.transin_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_transout_amt = GROUP sum(p_rec_prodhist.transout_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_gross_per = GROUP sum(p_rec_prodhist.gross_per) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		CALL null_test(l_s_credit_amt,l_s_pur_amt,'',l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,'',l_s_transout_amt,l_s_gross_per ) 
		RETURNING l_s_credit_amt,l_s_pur_amt, l_s_reclassin_amt,l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,l_s_reclassout_amt,l_s_transout_amt,l_s_gross_per 
		LET l_s_trans_amt = l_s_transin_amt - l_s_transout_amt 
		IF modu_report_ind > 3 THEN 
			NEED 3 LINES 
			PRINT COLUMN 29, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------" 
			PRINT COLUMN 01, "PROD.GROUP", 
			COLUMN 12, p_rec_product.prodgrp_code, 
			COLUMN 16, "TOTAL :"; 
			LET l_total_ind = TRUE 
		ELSE 
			IF modu_report_ind = 3 THEN 
				NEED 2 LINES 
				PRINT COLUMN 20, p_rec_product.prodgrp_code; 
			END IF 
		END IF 
		IF modu_report_ind >=3 THEN 
			PRINT COLUMN 25, "MTD:", 
			COLUMN 29, l_prod_open_bal USING "-------&.&&", 
			COLUMN 41, l_s_sales_amt USING "--------&.&&", 
			COLUMN 54, l_s_credit_amt USING "-------&.&&", 
			COLUMN 66, l_s_pur_amt USING "-------&.&&", 
			COLUMN 78, l_s_adj_amt USING "-------&.&&", 
			COLUMN 90, l_s_trans_amt USING "-------&.&&", 
			COLUMN 102, l_prod_clos_bal USING "-------&.&&", 
			COLUMN 114, ( l_prod_clos_bal - l_prod_open_bal ) USING "-------&.&&", 
			COLUMN 126, l_s_gross_per USING "---&.&&" 
			PRINT COLUMN 25, "YTD:", 
			COLUMN 29, l_ytd_prod_open_bal USING "-------&.&&", 
			COLUMN 41, l_ytd_prod_sales_amt USING "--------&.&&", 
			COLUMN 54, l_ytd_prod_credit_amt USING "-------&.&&", 
			COLUMN 66, l_ytd_prod_pur_amt USING "-------&.&&", 
			COLUMN 78, l_ytd_prod_adj_amt USING "-------&.&&", 
			COLUMN 90, l_ytd_prod_trans_amt USING "-------&.&&", 
			COLUMN 102, l_ytd_prod_clos_bal USING "-------&.&&", 
			COLUMN 114, ( l_ytd_prod_clos_bal - l_ytd_prod_open_bal )	USING "-------&.&&", 
			COLUMN 126, l_ytd_prod_gross_per USING "---&.&&" 
		END IF 
		LET l_prod_open_bal = 0 
		LET l_prod_clos_bal = 0 
		LET l_ytd_prod_clos_bal = 0 
		LET l_ytd_prod_open_bal = 0 
		LET l_ytd_prod_sales_amt = 0 
		LET l_ytd_prod_credit_amt = 0 
		LET l_ytd_prod_pur_amt = 0 
		LET l_ytd_prod_adj_amt = 0 
		LET l_ytd_prod_trans_amt = 0 
		LET l_ytd_prod_gross_per = 0 

	AFTER GROUP OF p_rec_product.maingrp_code 
		LET l_s_sales_amt = GROUP sum(p_rec_prodhist.sales_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_credit_amt = GROUP sum(p_rec_prodhist.credit_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_pur_amt = GROUP sum(p_rec_prodhist.pur_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_adj_amt = GROUP sum(p_rec_prodhist.adj_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_transin_amt = GROUP sum(p_rec_prodhist.transin_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_transout_amt = GROUP sum(p_rec_prodhist.transout_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_gross_per = GROUP sum(p_rec_prodhist.gross_per) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		CALL null_test(l_s_credit_amt,l_s_pur_amt,'',l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,'',l_s_transout_amt,l_s_gross_per ) 
		RETURNING l_s_credit_amt,l_s_pur_amt,l_s_reclassin_amt,l_s_transin_amt,l_s_adj_amt,l_s_sales_amt, 
		l_s_reclassout_amt, l_s_transout_amt, l_s_gross_per 
		LET l_s_trans_amt = l_s_transin_amt - l_s_transout_amt 
		IF modu_report_ind > 2 THEN 
			NEED 3 LINES 
			PRINT COLUMN 29, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------" 
			PRINT COLUMN 01, "MAIN GROUP", 
			COLUMN 12, p_rec_product.maingrp_code, 
			COLUMN 16, "TOTAL :"; 
			LET l_total_ind = TRUE 
		ELSE 
			IF modu_report_ind = 2 THEN 
				NEED 2 LINES 
				PRINT COLUMN 20, p_rec_product.maingrp_code; 
			END IF 
		END IF 
		IF modu_report_ind >= 2 THEN 
			PRINT COLUMN 25, "MTD:", 
			COLUMN 29, l_main_open_bal USING "-------&.&&", 
			COLUMN 41, l_s_sales_amt USING "--------&.&&", 
			COLUMN 54, l_s_credit_amt USING "-------&.&&", 
			COLUMN 66, l_s_pur_amt USING "-------&.&&", 
			COLUMN 78, l_s_adj_amt USING "-------&.&&", 
			COLUMN 90, l_s_trans_amt USING "-------&.&&", 
			COLUMN 102, l_main_clos_bal USING "-------&.&&", 
			COLUMN 114, ( l_main_clos_bal - l_main_open_bal ) USING "-------&.&&", 
			COLUMN 126, l_s_gross_per USING "---&.&&" 
			PRINT COLUMN 25, "YTD:", 
			COLUMN 29, l_ytd_main_open_bal USING "-------&.&&", 
			COLUMN 41, l_ytd_main_sales_amt USING "--------&.&&", 
			COLUMN 54, l_ytd_main_credit_amt USING "-------&.&&", 
			COLUMN 66, l_ytd_main_pur_amt USING "-------&.&&", 
			COLUMN 78, l_ytd_main_adj_amt USING "-------&.&&", 
			COLUMN 90, l_ytd_main_trans_amt USING "-------&.&&", 
			COLUMN 102, l_ytd_main_clos_bal USING "-------&.&&", 
			COLUMN 114, ( l_ytd_main_clos_bal - l_ytd_main_open_bal ) USING "-------&.&&", 
			COLUMN 126, l_ytd_main_gross_per USING "---&.&&" 
		END IF 
		LET l_main_open_bal = 0 
		LET l_main_clos_bal = 0 
		LET l_ytd_main_clos_bal = 0 
		LET l_ytd_main_open_bal = 0 
		LET l_ytd_main_sales_amt = 0 
		LET l_ytd_main_credit_amt = 0 
		LET l_ytd_main_pur_amt = 0 
		LET l_ytd_main_adj_amt = 0 
		LET l_ytd_main_trans_amt = 0 
		LET l_ytd_main_gross_per = 0 

	AFTER GROUP OF p_rec_maingrp.dept_code 
		IF p_rec_maingrp.dept_code IS NOT NULL THEN 
			LET l_s_sales_amt = GROUP sum(p_rec_prodhist.sales_amt) 
			WHERE p_rec_prodhist.period_num = modu_period_num 
			LET l_s_credit_amt = GROUP sum(p_rec_prodhist.credit_amt) 
			WHERE p_rec_prodhist.period_num = modu_period_num 
			LET l_s_pur_amt = GROUP sum(p_rec_prodhist.pur_amt) 
			WHERE p_rec_prodhist.period_num = modu_period_num 
			LET l_s_adj_amt = GROUP sum(p_rec_prodhist.adj_amt) 
			WHERE p_rec_prodhist.period_num = modu_period_num 
			LET l_s_transin_amt = GROUP sum(p_rec_prodhist.transin_amt) 
			WHERE p_rec_prodhist.period_num = modu_period_num 
			LET l_s_transout_amt = GROUP sum(p_rec_prodhist.transout_amt) 
			WHERE p_rec_prodhist.period_num = modu_period_num 
			LET l_s_gross_per = GROUP sum(p_rec_prodhist.gross_per) 
			WHERE p_rec_prodhist.period_num = modu_period_num 
			CALL null_test(l_s_credit_amt,l_s_pur_amt,'',l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,'',l_s_transout_amt,l_s_gross_per) 
			RETURNING l_s_credit_amt,l_s_pur_amt,l_s_reclassin_amt,l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,l_s_reclassout_amt,l_s_transout_amt,l_s_gross_per 
			LET l_s_trans_amt = l_s_transin_amt - l_s_transout_amt 
			IF modu_report_ind > 1 THEN 
				NEED 3 LINES 
				PRINT COLUMN 29, "----------------------------------------", 
				"----------------------------------------", 
				"------------------------" 
				PRINT COLUMN 01, "DEPARTMENT", 
				COLUMN 12, p_rec_maingrp.dept_code, 
				COLUMN 16, "TOTAL :"; 
				LET l_total_ind = TRUE 
			ELSE 
				IF modu_report_ind = 1 THEN 
					NEED 2 LINES 
					PRINT COLUMN 20, p_rec_maingrp.dept_code; 
				END IF 
			END IF 
			IF modu_report_ind >= 1 THEN 
				PRINT COLUMN 25, "MTD:", 
				COLUMN 29, l_dept_open_bal USING "-------&.&&", 
				COLUMN 41, l_s_sales_amt USING "--------&.&&", 
				COLUMN 54, l_s_credit_amt USING "-------&.&&", 
				COLUMN 66, l_s_pur_amt USING "-------&.&&", 
				COLUMN 78, l_s_adj_amt USING "-------&.&&", 
				COLUMN 90, l_s_trans_amt USING "-------&.&&", 
				COLUMN 102, l_dept_clos_bal USING "-------&.&&", 
				COLUMN 114, ( l_dept_clos_bal - l_dept_open_bal ) USING "-------&.&&", 
				COLUMN 126, l_s_gross_per USING "---&.&&" 
				PRINT COLUMN 25, "YTD:", 
				COLUMN 29, l_ytd_dept_open_bal USING "-------&.&&", 
				COLUMN 41, l_ytd_dept_sales_amt USING "--------&.&&", 
				COLUMN 54, l_ytd_dept_credit_amt USING "-------&.&&", 
				COLUMN 66, l_ytd_dept_pur_amt USING "-------&.&&", 
				COLUMN 78, l_ytd_dept_adj_amt USING "-------&.&&", 
				COLUMN 90, l_ytd_dept_trans_amt USING "-------&.&&", 
				COLUMN 102, l_ytd_dept_clos_bal USING "-------&.&&", 
				COLUMN 114, ( l_ytd_dept_clos_bal - l_ytd_dept_open_bal )	USING "-------&.&&", 
				COLUMN 126, l_ytd_dept_gross_per USING "---&.&&" 
			END IF 
			LET l_dept_open_bal = 0 
			LET l_dept_clos_bal = 0 
			LET l_ytd_dept_open_bal = 0 
			LET l_ytd_dept_clos_bal = 0 
			LET l_ytd_dept_sales_amt = 0 
			LET l_ytd_dept_credit_amt = 0 
			LET l_ytd_dept_pur_amt = 0 
			LET l_ytd_dept_adj_amt = 0 
			LET l_ytd_dept_trans_amt = 0 
			LET l_ytd_dept_gross_per = 0 
		END IF 

	AFTER GROUP OF p_rec_warehouse.ware_code 
		LET l_s_sales_amt = GROUP sum(p_rec_prodhist.sales_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_credit_amt = GROUP sum(p_rec_prodhist.credit_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_pur_amt = GROUP sum(p_rec_prodhist.pur_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_adj_amt = GROUP sum(p_rec_prodhist.adj_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_transin_amt = GROUP sum(p_rec_prodhist.transin_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_transout_amt = GROUP sum(p_rec_prodhist.transout_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_gross_per = GROUP sum(p_rec_prodhist.gross_per) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		CALL null_test( l_s_credit_amt, l_s_pur_amt,'',l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,'',l_s_transout_amt,l_s_gross_per ) 
		RETURNING l_s_credit_amt,l_s_pur_amt,l_s_reclassin_amt,l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,l_s_reclassout_amt,l_s_transout_amt,l_s_gross_per 
		LET l_s_trans_amt = l_s_transin_amt - l_s_transout_amt 
		NEED 3 LINES 
		PRINT COLUMN 29, "----------------------------------------", 
		"----------------------------------------", 
		"------------------------" 
		PRINT COLUMN 01, "WAREHOUSE", 
		COLUMN 12, p_rec_warehouse.ware_code, 
		COLUMN 16, "TOTAL :", 
		COLUMN 25, "MTD:", 
		COLUMN 29, l_ware_open_bal USING "-------&.&&", 
		COLUMN 41, l_s_sales_amt USING "--------&.&&", 
		COLUMN 54, l_s_credit_amt USING "-------&.&&", 
		COLUMN 66, l_s_pur_amt USING "-------&.&&", 
		COLUMN 78, l_s_adj_amt USING "-------&.&&", 
		COLUMN 90, l_s_trans_amt USING "-------&.&&", 
		COLUMN 102, l_ware_clos_bal USING "-------&.&&", 
		COLUMN 114, ( l_ware_clos_bal - l_ware_open_bal ) USING "-------&.&&", 
		COLUMN 126, l_s_gross_per USING "---&.&&" 
		PRINT COLUMN 25, "YTD:", 
		COLUMN 29, l_ytd_ware_open_bal USING "-------&.&&", 
		COLUMN 41, l_ytd_ware_sales_amt USING "--------&.&&", 
		COLUMN 54, l_ytd_ware_credit_amt USING "-------&.&&", 
		COLUMN 66, l_ytd_ware_pur_amt USING "-------&.&&", 
		COLUMN 78, l_ytd_ware_adj_amt USING "-------&.&&", 
		COLUMN 90, l_ytd_ware_trans_amt USING "-------&.&&", 
		COLUMN 102, l_ytd_ware_clos_bal USING "-------&.&&", 
		COLUMN 114, ( l_ytd_ware_clos_bal - l_ytd_ware_open_bal )	USING "-------&.&&", 
		COLUMN 126, l_ytd_ware_gross_per USING "---&.&&" 
		LET l_ware_open_bal = 0 
		LET l_ware_clos_bal = 0 
		LET l_ytd_ware_open_bal = 0 
		LET l_ytd_ware_clos_bal = 0 
		LET l_ytd_ware_sales_amt = 0 
		LET l_ytd_ware_credit_amt = 0 
		LET l_ytd_ware_pur_amt = 0 
		LET l_ytd_ware_adj_amt = 0 
		LET l_ytd_ware_trans_amt = 0 
		LET l_ytd_ware_gross_per = 0 
		SKIP 1 LINES 

	ON LAST ROW 
		NEED 8 LINES 
		SKIP 1 line 
		LET l_s_sales_amt = sum(p_rec_prodhist.sales_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_credit_amt = sum(p_rec_prodhist.credit_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_pur_amt = sum(p_rec_prodhist.pur_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_adj_amt = sum(p_rec_prodhist.adj_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_transin_amt = sum(p_rec_prodhist.transin_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_transout_amt = sum(p_rec_prodhist.transout_amt) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		LET l_s_gross_per = sum(p_rec_prodhist.gross_per) 
		WHERE p_rec_prodhist.period_num = modu_period_num 
		CALL null_test( l_s_credit_amt, l_s_pur_amt,'',l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,'',l_s_transout_amt,l_s_gross_per) 
		RETURNING l_s_credit_amt,l_s_pur_amt, l_s_reclassin_amt,l_s_transin_amt,l_s_adj_amt,l_s_sales_amt,l_s_reclassout_amt,l_s_transout_amt,l_s_gross_per 
		LET l_s_trans_amt = l_s_transin_amt - l_s_transout_amt 
		PRINT COLUMN 09, "REPORT TOTAL :", 
		COLUMN 25, "MTD:", 
		COLUMN 29, l_rpt_open_bal USING "-------&.&&", 
		COLUMN 41, l_s_sales_amt USING "--------&.&&", 
		COLUMN 54, l_s_credit_amt USING "-------&.&&", 
		COLUMN 66, l_s_pur_amt USING "-------&.&&", 
		COLUMN 78, l_s_adj_amt USING "-------&.&&", 
		COLUMN 90, l_s_trans_amt USING "-------&.&&", 
		COLUMN 102, l_rpt_clos_bal USING "-------&.&&", 
		COLUMN 114, ( l_rpt_clos_bal - l_rpt_open_bal ) USING "-------&.&&", 
		COLUMN 126, l_s_gross_per USING "---&.&&" 
		PRINT COLUMN 25, "YTD:", 
		COLUMN 29, l_ytd_rpt_open_bal USING "-------&.&&", 
		COLUMN 41, l_ytd_rpt_sales_amt USING "--------&.&&", 
		COLUMN 54, l_ytd_rpt_credit_amt USING "-------&.&&", 
		COLUMN 66, l_ytd_rpt_pur_amt USING "-------&.&&", 
		COLUMN 78, l_ytd_rpt_adj_amt USING "-------&.&&", 
		COLUMN 90, l_ytd_rpt_trans_amt USING "-------&.&&", 
		COLUMN 102, l_ytd_rpt_clos_bal USING "-------&.&&", 
		COLUMN 114, ( l_ytd_rpt_clos_bal - l_ytd_rpt_open_bal ) USING "-------&.&&", 
		COLUMN 126, l_ytd_rpt_gross_per USING "---&.&&" 
		SKIP 3 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT
