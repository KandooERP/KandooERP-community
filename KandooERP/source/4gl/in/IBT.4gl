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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

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
DEFINE modu_period_num LIKE period.year_num
DEFINE modu_status_date LIKE period.start_date 
DEFINE modu_arr_interval ARRAY[12] OF RECORD 
	int_text CHAR(6), 
	year_num LIKE period.year_num, 
	period_num LIKE period.period_num 
END RECORD 

############################################################
# FUNCTION IBT_main()
#
# Purpose - Print Product Trends Report by Product
############################################################
FUNCTION IBT_main()

	CALL setModuleId("IBT") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I616 WITH FORM "I616" 
			 CALL windecoration_i("I616")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Product Trends" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IBT","menu-Product_Trends-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IBT_rpt_process(IBT_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IBT_rpt_process(IBT_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I616

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IBT_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I616 with FORM "I616" 
			 CALL windecoration_i("I616") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IBT_rpt_query()) #save where clause in env 
			CLOSE WINDOW I616 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IBT_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION
############################################################
# END FUNCTION IBT_main()
############################################################

############################################################
# FUNCTION IBT_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IBT_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

   # Enter the Fiscal Year and Fiscal Period to begin this report from.
	IF NOT enter_year_IBT() THEN 
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
	product.maingrp_code, 
	product.prodgrp_code, 
	product.class_code, 
	product.alter_part_code, 
	product.oem_text, 
	product.days_lead_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IBT","construct-prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		CALL build_interval()
		RETURN r_where_text
	END IF
 
END FUNCTION
############################################################
# END FUNCTION IBT_rpt_query() 
############################################################

############################################################
# FUNCTION IBT_rpt_process() 
#
# The report driver
############################################################
FUNCTION IBT_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
 	DEFINE l_rec_product RECORD LIKE product.* 
 	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
 
	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IBT_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IBT_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatus.*,product.* ", 
	"FROM prodstatus,product ", 
	"WHERE prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND prodstatus.part_code = product.part_code ", 
	"AND prodstatus.stocked_flag = 'Y' ", 
	"AND (prodstatus.status_ind = '1' OR prodstatus.status_ind='4') ", 
	"AND product.trade_in_flag = 'N' ", 
	"AND (product.status_ind = '1' OR product.status_ind='4') ", 
	"AND ", p_where_text CLIPPED," ",
	"ORDER BY prodstatus.part_code,prodstatus.ware_code" 

	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 

	LET l_query_text = 
	"SELECT (sales_qty - credit_qty) FROM prodhist ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND part_code = ? ", 
	"AND ware_code = ? ", 
	"AND year_num = ? ", 
	"AND period_num = ? " 

	PREPARE s_prodhist FROM l_query_text 
	DECLARE c_prodhist CURSOR FOR s_prodhist 

	FOREACH c_prodstatus INTO l_rec_prodstatus.*, l_rec_product.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IBT_rpt_list (l_rpt_idx,l_rec_prodstatus.*,l_rec_product.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodstatus.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IBT_rpt_list
	RETURN rpt_finish("IBT_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IBT_rpt_process() 
############################################################

############################################################
# FUNCTION enter_year_IBT() 
#
# Purpose - Enter the Fiscal Year and Fiscal Period to begin this report from.
############################################################
FUNCTION enter_year_IBT() 
	DEFINE l_failed_it SMALLINT 
	DEFINE l_temp_date LIKE period.start_date 
	DEFINE l_start_date LIKE period.start_date
	DEFINE l_end_date LIKE period.start_date
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_cnt INTEGER	

	#Get last year + 1 month so that current period IS reported on
	LET l_temp_date = TODAY - 1 UNITS YEAR 
	LET l_temp_date = l_temp_date + 1 UNITS MONTH 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, l_temp_date) 
	RETURNING modu_year_num, modu_period_num 

   MESSAGE kandoomsg2("E",1157,"")
	#1157 Enter year FOR REPORT run - ESC TO Continue

	CLEAR FORM
	INPUT modu_year_num,modu_period_num WITHOUT DEFAULTS FROM year_num,period_num  

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IBT","input-pr_year_num-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD year_num 
			IF modu_year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"")
				#9210 Year number must be entered
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD period_num 
			IF modu_period_num IS NULL THEN 
				ERROR kandoomsg2("G",9508,"")
				#9508 Period number must be entered"
				NEXT FIELD period_num 
			ELSE 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, modu_year_num, 
				modu_period_num, TRAN_TYPE_INVOICE_IN) RETURNING modu_year_num,modu_period_num,l_failed_it 
				IF l_failed_it THEN 
					NEXT FIELD year_num 
				ELSE 
					SELECT * INTO l_rec_period.* FROM period 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = modu_year_num 
					AND period_num = modu_period_num 
					LET l_start_date = l_rec_period.start_date 
					LET l_end_date = l_rec_period.end_date 
					DISPLAY l_start_date,l_end_date TO start_date,end_date 
					LET modu_status_date = l_rec_period.end_date 
					LET l_temp_date = l_rec_period.start_date + 1 UNITS YEAR 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		SELECT COUNT(*) INTO l_cnt FROM prodledg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				tran_date BETWEEN l_rec_period.start_date AND l_temp_date AND
				hist_flag = "N" 
		IF l_cnt > 0 THEN 
			MESSAGE kandoomsg2("I",7038,"")
			#7038 WARNING - History UPDATE should be run first
		END IF 
		RETURN TRUE 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION enter_year_IBT() 
############################################################

############################################################
# FUNCTION build_interval()
#
# 
############################################################
FUNCTION build_interval() 
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE i,j SMALLINT 

	FOR i = 1 TO 12 
		INITIALIZE modu_arr_interval[i].* TO NULL 
	END FOR 
	LET i = 1 
	LET modu_arr_interval[i].int_text = modu_status_date USING "mmmyy" 
	LET modu_arr_interval[i].int_text = upshift(modu_arr_interval[i].int_text) 
	LET modu_arr_interval[i].year_num = modu_year_num 
	LET modu_arr_interval[i].period_num = modu_period_num 

	# Get next 11 intervals
	DECLARE c_period CURSOR FOR 
	SELECT * INTO l_rec_period.* FROM period 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ((year_num = modu_year_num AND period_num > modu_period_num) OR 
	(year_num > modu_year_num AND period_num < modu_period_num)) 
	FOREACH c_period INTO l_rec_period.* 
		LET i = i + 1 
		IF i > 12 THEN
			EXIT FOREACH
		END IF
		LET modu_arr_interval[i].int_text = l_rec_period.start_date USING "mmmyy" 
		LET modu_arr_interval[i].int_text = upshift(modu_arr_interval[i].int_text) 
		LET modu_arr_interval[i].year_num = l_rec_period.year_num 
		LET modu_arr_interval[i].period_num = l_rec_period.period_num 
	END FOREACH 
	FOR i = 1 TO 12 
		IF modu_arr_interval[i].int_text IS NULL THEN 
			LET modu_arr_interval[i].int_text = " N/A" 
		ELSE 
			#Just in CASE next 12 periods NOT setup in GZA
			LET j = i 
		END IF 
	END FOR 

	SELECT * INTO l_rec_period.* FROM period 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = modu_arr_interval[j].year_num 
	AND period_num = modu_arr_interval[j].period_num 
	LET modu_status_date = l_rec_period.end_date 

END FUNCTION 
############################################################
# END FUNCTION build_interval()
############################################################

############################################################
# REPORT IBT_rpt_list(p_rpt_idx,p_rec_prodstatus,p_rec_product)
#
# Report Definition/Layout
############################################################
REPORT IBT_rpt_list(p_rpt_idx,p_rec_prodstatus,p_rec_product) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
 	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE l_sales_qty LIKE prodhist.sales_qty 
	DEFINE l_tot_sales_qty LIKE prodhist.sales_qty
	DEFINE l_qtr_sales_qty LIKE prodhist.sales_qty
	DEFINE l_qtr_avg LIKE prodhist.sales_qty 
	DEFINE l_year_avg LIKE prodhist.sales_qty
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE l_mths_sold SMALLINT 
	DEFINE l_year_cov FLOAT 
	DEFINE l_qtr_cov FLOAT
	DEFINE l_diff FLOAT
	DEFINE i SMALLINT

	ORDER EXTERNAL BY p_rec_prodstatus.part_code,p_rec_prodstatus.ware_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT 18 spaces; 
			FOR i = 1 TO 12 
				PRINT modu_arr_interval[i].int_text; 
			END FOR 
			PRINT COLUMN 95,"Qty", 
			COLUMN 102,"Qty", 
			COLUMN 108,"Avg", 
			COLUMN 114,"Avg", 
			COLUMN 118,"Diff%", 
			COLUMN 124,"Cov.", 
			COLUMN 129,"Cov."
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_prodstatus.part_code 
		NEED 6 LINES 
		IF modu_status_date - p_rec_product.status_date > 365 THEN 
			LET l_mths_sold = 12 
		ELSE 
			LET l_mths_sold = MONTH(modu_status_date) - 
			MONTH(p_rec_product.status_date) 
			IF l_mths_sold < 0 THEN 
				LET l_mths_sold = l_mths_sold + 13 
			ELSE 
				LET l_mths_sold = l_mths_sold + 1 
			END IF 
		END IF 
		PRINT COLUMN 01,p_rec_product.part_code, 
		COLUMN 17,p_rec_product.desc_text 
		PRINT COLUMN 03,"Mths Sold:", 
			COLUMN 13,l_mths_sold USING "<&" 
		SKIP 1 line 
		PRINT COLUMN 05,"Warehouse:" 

	AFTER GROUP OF p_rec_prodstatus.part_code 
		SKIP 3 LINES 

	ON EVERY ROW 
		LET l_desc_text = NULL 
		LET l_tot_sales_qty = 0 
		LET l_qtr_sales_qty = 0 
		SELECT desc_text INTO l_desc_text FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_rec_prodstatus.ware_code 
		PRINT COLUMN 01,p_rec_prodstatus.ware_code, 
		COLUMN 05,l_desc_text[1,13]; 
		FOR i = 1 TO 12 
			OPEN c_prodhist USING p_rec_prodstatus.part_code, 
			p_rec_prodstatus.ware_code, 
			modu_arr_interval[i].year_num, 
			modu_arr_interval[i].period_num 
			FETCH c_prodhist INTO l_sales_qty 
			IF STATUS = NOTFOUND THEN 
				LET l_sales_qty = 0 
			ELSE 
				IF l_sales_qty IS NULL THEN 
					LET l_sales_qty = 0 
				END IF 
			END IF 
			IF i > 9 THEN 
				LET l_qtr_sales_qty = l_qtr_sales_qty + l_sales_qty 
			END IF 
			LET l_tot_sales_qty = l_tot_sales_qty + l_sales_qty 
			IF i = 1 THEN
				PRINT COLUMN 18,l_sales_qty USING "-----&";
			ELSE 
				PRINT l_sales_qty USING "-----&";
			END IF 
		END FOR 
		LET l_year_avg = l_tot_sales_qty / l_mths_sold 
			IF l_mths_sold > 3 THEN 
			LET l_qtr_avg = l_qtr_sales_qty / 3 
		ELSE 
			LET l_qtr_avg = l_qtr_sales_qty / l_mths_sold 
		END IF 
		IF l_year_avg = 0 THEN 
			LET l_diff = 0 
			LET l_year_cov = 0 
		ELSE 
			LET l_diff = 100 * ((l_qtr_avg - l_year_avg) / l_year_avg) 
			LET l_year_cov = (p_rec_prodstatus.onhand_qty - l_tot_sales_qty) / l_year_avg 
		END IF 
		IF l_qtr_avg = 0 THEN 
			LET l_qtr_cov = 0 
		ELSE 
			LET l_qtr_cov = (p_rec_prodstatus.onhand_qty - l_qtr_sales_qty) / l_qtr_avg 
		END IF 
		PRINT COLUMN 91,l_tot_sales_qty USING "------&", 
		COLUMN 98,p_rec_prodstatus.onhand_qty USING "------&", 
		COLUMN 105,l_year_avg USING "-----&", 
		COLUMN 111,l_qtr_avg USING "-----&", 
		COLUMN 117,l_diff USING "---&.&", 
		COLUMN 123,l_year_cov USING "##&.&", 
		COLUMN 128,l_qtr_cov USING "##&.&" 

	ON LAST ROW 
		SKIP 2 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
