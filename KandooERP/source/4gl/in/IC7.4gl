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
DEFINE modu_book_tax CHAR(1) 
DEFINE modu_start_date DATE 
DEFINE modu_end_date DATE 

###################################################
# FUNCTION IC7_main()
#
# Purpose - Summary Stock Valuation Report 
############################################################
FUNCTION IC7_main() 

	CALL setModuleId("IC7") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I206 WITH FORM "I206" 
			 CALL windecoration_i("I206")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Summary Stock Valuation" 

				BEFORE MENU 
				CALL publish_toolbar("kandoo","IC7","menu-Summary_Stock-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IC7_rpt_process(IC7_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IC7_rpt_process(IC7_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I206

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IC7_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I206 with FORM "I206" 
			 CALL windecoration_i("I206") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IC7_rpt_query()) #save where clause in env 
			CLOSE WINDOW I206 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IC7_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION
############################################################
# END FUNCTION IC7_main() 
############################################################ 

#####################################################################
# FUNCTION IC7_rpt_query()
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
#####################################################################
FUNCTION IC7_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CLEAR FORM
	DIALOG ATTRIBUTES(UNBUFFERED)

		INPUT modu_book_tax,modu_start_date,modu_end_date FROM book_tax,start_date,end_date 
			AFTER FIELD book_tax
				IF modu_book_tax IS NULL THEN 
					LET modu_book_tax = "B" 
					DISPLAY modu_book_tax TO book_tax
				END IF 
			AFTER FIELD start_date
				IF modu_start_date IS NULL THEN 
					LET modu_start_date = "01/01/0001" 
					DISPLAY modu_start_date TO start_date 
				END IF 
			AFTER FIELD end_date
				IF modu_end_date IS NULL THEN 
					LET modu_end_date = "30/12/9999" 
					DISPLAY modu_end_date TO end_date
				END IF
		END INPUT	

		CONSTRUCT BY NAME r_where_text ON 
		product.cat_code, 
		product.class_code, 
		prodstatus.part_code, 
		prodstatus.ware_code
		END CONSTRUCT

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null)

		ON ACTION "ACCEPT" 
			ACCEPT DIALOG
			
		ON ACTION "CANCEL" 
			EXIT DIALOG			

		AFTER DIALOG
			IF modu_book_tax IS NULL THEN 
				LET modu_book_tax = "B" 
				DISPLAY modu_book_tax TO book_tax
			END IF 
			IF modu_start_date IS NULL THEN 
				LET modu_start_date = "01/01/0001" 
				DISPLAY modu_start_date TO start_date 
			END IF 
			IF modu_end_date IS NULL THEN 
				LET modu_end_date = "30/12/9999" 
				DISPLAY modu_end_date TO end_date
			END IF	
	
	END DIALOG

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET modu_book_tax = NULL  
		LET modu_start_date = NULL
		LET modu_end_date = NULL
		CLEAR FORM
		RETURN NULL
	ELSE
		RETURN r_where_text
	END IF

END FUNCTION
############################################################
# END FUNCTION IC7_rpt_query() 
############################################################

#####################################################################
# FUNCTION IC7_rpt_process(p_where_text) 
#
# The report driver
#####################################################################
FUNCTION IC7_rpt_process(p_where_text) 
	DEFINE p_where_text LIKE rmsreps.sel_text 
	DEFINE l_query_text LIKE rmsreps.sel_text
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_costledg RECORD LIKE costledg.*
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_product RECORD LIKE product.*

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	IF modu_book_tax = "B" THEN 
		LET l_rpt_idx = rpt_start("IC7","IC7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	ELSE 
		LET l_rpt_idx = rpt_start("IC7.","IC7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	END IF

	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IC7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = "SELECT * ", 
	"FROM product,prodstatus,costledg ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"product.cmpy_code = prodstatus.cmpy_code AND ", 
	"product.cmpy_code = costledg.cmpy_code AND ", 
	"product.part_code = prodstatus.part_code AND ", 
	"product.part_code = costledg.part_code AND ", 
	"costledg.ware_code = prodstatus.ware_code AND ", 
	"costledg.tran_date > \"",modu_start_date,"\" AND ", 
	"costledg.tran_date < \"",modu_end_date,"\" AND ", 
	"costledg.onhand_qty != 0 ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY product.cat_code,product.part_code,prodstatus.ware_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_product.*,l_rec_prodstatus.*,l_rec_costledg.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IC7_rpt_list(l_rpt_idx,l_rec_product.*,l_rec_prodstatus.*,l_rec_costledg.*,modu_book_tax) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IC7_rpt_list
	RETURN rpt_finish("IC7_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IC7_rpt_process(p_where_text) 
############################################################

#####################################################################
# REPORT IC7_rpt_list(p_rpt_idx,p_rec_product,p_rec_prodstatus,p_rec_costledg,p_book_tax)
#
# Report Definition/Layout
#####################################################################
REPORT IC7_rpt_list(p_rpt_idx,p_rec_product,p_rec_prodstatus,p_rec_costledg,p_book_tax) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE p_rec_costledg RECORD LIKE costledg.*
	DEFINE p_book_tax CHAR(1) 
	DEFINE l_rec_category RECORD LIKE category.*
	DEFINE l_oh MONEY(11,4)
	DEFINE l_curr MONEY(11,4)
	DEFINE l_wo MONEY(11,4)
	DEFINE l_pwo MONEY(11,4)
	DEFINE l_val MONEY(11,4)
	DEFINE l_tot_oh MONEY(11,4)
	DEFINE l_tot_curr MONEY(11,4)
	DEFINE l_tot_wo MONEY(11,4)
	DEFINE l_tot_pwo MONEY(11,4)
	DEFINE l_tot_val MONEY(11,4) 
	
	ORDER EXTERNAL BY p_rec_product.cat_code,p_rec_product.part_code,p_rec_prodstatus.ware_code 

	FORMAT 
		FIRST PAGE HEADER 
			LET l_oh = 0 
			LET l_curr = 0 
			LET l_wo = 0 
			LET l_pwo = 0 
			LET l_val = 0
			LET l_tot_oh = 0 
			LET l_tot_curr = 0 
			LET l_tot_wo = 0 
			LET l_tot_pwo = 0 
			LET l_tot_val = 0
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_product.cat_code 
		SELECT * INTO l_rec_category.* FROM category 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cat_code = p_rec_product.cat_code 

	AFTER GROUP OF p_rec_product.cat_code 
		IF p_book_tax = "B" THEN 
			LET l_oh = NVL(GROUP SUM(p_rec_costledg.onhand_qty),0) 
			LET l_curr = NVL(GROUP SUM(p_rec_costledg.curr_cost_amt * p_rec_costledg.onhand_qty),0) 
			LET l_wo = NVL(GROUP SUM(p_rec_costledg.curr_tot_wo_amt),0) 
			LET l_pwo = NVL(GROUP SUM(p_rec_costledg.prev_tot_wo_amt),0) 
			LET l_val = l_curr + l_wo + l_pwo 
			PRINT COLUMN 01, "Category: ", 
			COLUMN 12, l_rec_category.cat_code CLIPPED, 
			COLUMN 17, l_rec_category.desc_text CLIPPED, 
			COLUMN 63, l_oh   USING "-------&", 
			COLUMN 74, l_curr USING "--,---,--&.&&", 
			COLUMN 89, l_wo   USING "--,---,--&.&&", 
			COLUMN 104,l_pwo  USING "--,---,--&.&&", 
			COLUMN 119,l_val  USING "--,---,--&.&&" 

			# Accum own totals because SUM shows diff total TO GROUP SUM
			LET l_tot_oh = l_tot_oh + l_oh 
			LET l_tot_curr = l_tot_curr + l_curr 
			LET l_tot_wo = l_tot_wo + l_wo 
			LET l_tot_pwo = l_tot_pwo + l_pwo 
			LET l_tot_val = l_tot_curr + l_tot_wo + l_tot_pwo 
		ELSE 
			LET l_oh = NVL(GROUP SUM(p_rec_costledg.onhand_qty),0) 
			LET l_curr = NVL(GROUP SUM(p_rec_costledg.tax_cost_amt * p_rec_costledg.onhand_qty),0) 
			LET l_wo = NVL(GROUP SUM(p_rec_costledg.tax_tot_wo_amt),0) 
			LET l_pwo = NVL(GROUP SUM(p_rec_costledg.prv_tot_tax_wo_amt),0) 
			LET l_val = l_curr + l_wo + l_pwo 
			PRINT COLUMN 01, "Category: ", 
			COLUMN 12, l_rec_category.cat_code, 
			COLUMN 17, l_rec_category.desc_text, 
			COLUMN 63, l_oh   USING "-------&", 
			COLUMN 74, l_curr USING "--,---,--&.&&", 
			COLUMN 89, l_wo   USING "--,---,--&.&&", 
			COLUMN 104,l_pwo  USING "--,---,--&.&&", 
			COLUMN 119,l_val  USING "--,---,--&.&&" 

			# Accum own totals because SUM shows diff total TO GROUP SUM
			LET l_tot_oh = l_tot_oh + l_oh 
			LET l_tot_curr = l_tot_curr + l_curr 
			LET l_tot_wo = l_tot_wo + l_wo 
			LET l_tot_pwo = l_tot_pwo + l_pwo 
			LET l_tot_val = l_tot_curr + l_tot_wo + l_tot_pwo 
		END IF 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 43, "Report Total:", 
			COLUMN 63, l_tot_oh   USING "-------&", 
			COLUMN 74, l_tot_curr USING "--,---,--&.&&", 
			COLUMN 89, l_tot_wo   USING "--,---,--&.&&", 
			COLUMN 104,l_tot_pwo  USING "--,---,--&.&&", 
			COLUMN 119,l_tot_val  USING "--,---,--&.&&" 
			SKIP 4 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report CLIPPED			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
