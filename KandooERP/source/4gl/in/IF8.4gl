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
DEFINE modu_val_date DATE
DEFINE modu_arr_date ARRAY[12] OF DATE 
DEFINE modu_arr_curr_tot ARRAY[14] OF DECIMAL(16,0) 
DEFINE modu_arr_wo_tot ARRAY[14] OF DECIMAL(16,0)

############################################################
# FUNCTION IF8_main()
#
# Purpose - Aged Stock Writedown Valuation by Product Category
############################################################
FUNCTION IF8_main()

	CALL setModuleId("IF8") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I216 WITH FORM "I216" 
			 CALL windecoration_i("I216")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Aged Stock Writedown Valuation" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IF8","menu-Aged Stock-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IF8_rpt_process(IF8_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IF8_rpt_process(IF8_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I216

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IF8_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I216 with FORM "I216" 
			 CALL windecoration_i("I216") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IF8_rpt_query()) #save where clause in env 
			CLOSE WINDOW I216 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IF8_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IF8_main()
############################################################

############################################################
# FUNCTION IF8_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IF8_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
	DEFINE l_day SMALLINT 
	DEFINE l_month SMALLINT
	DEFINE l_year SMALLINT
	DEFINE i SMALLINT

	LET modu_book_tax = "B"
	LET modu_start_date = NULL
	LET modu_end_date = NULL
	LET modu_val_date = NULL								

	CLEAR FORM	
	DIALOG ATTRIBUTES(UNBUFFERED)
		INPUT modu_book_tax,modu_start_date,modu_end_date,modu_val_date WITHOUT DEFAULTS 
		FROM book_tax,start_date,end_date,val_date 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IF8","input-pr_book_tax-1") -- albo kd-505 
				MESSAGE " Enter criteria FOR selection - ESC TO begin search"
			AFTER FIELD book_tax
				IF modu_book_tax IS NULL THEN 
					LET modu_book_tax = "B" 
				END IF 
			AFTER FIELD start_date
				IF modu_start_date IS NULL THEN 
					LET modu_start_date = "01/01/0001" 
				END IF 
			AFTER FIELD end_date
				IF modu_end_date IS NULL THEN 
					LET modu_end_date = "31/12/9999" 
				END IF
			AFTER FIELD val_date			 
				IF modu_val_date IS NULL THEN 
					LET modu_val_date = TODAY 
				END IF	 
			AFTER INPUT
				IF modu_book_tax IS NULL THEN 
					LET modu_book_tax = "B" 
				END IF 
				IF modu_start_date IS NULL THEN 
					LET modu_start_date = "01/01/0001" 
				END IF 
				IF modu_end_date IS NULL THEN 
					LET modu_end_date = "31/12/9999" 
				END IF
				IF modu_val_date IS NULL THEN 
					LET modu_val_date = TODAY 
				END IF	 
				IF modu_start_date > modu_end_date THEN
					ERROR "The Transaction start date is greater than the Transaction end date."
					NEXT FIELD start_date
				END IF
				# FORMAT dates FOR transaction aging
				LET l_day = DAY(modu_val_date) 
				LET l_month = MONTH(modu_val_date) 
				LET l_year = YEAR(modu_val_date) 
				FOR i = 1 TO 12 
					LET modu_arr_date[i] = MDY(l_month,l_day,l_year - i) 
				END FOR 
				# INITIALIZE REPORT totals
				FOR i = 1 TO 14 
					LET modu_arr_curr_tot[i] = 0 
					LET modu_arr_wo_tot[i] = 0 
				END FOR 

		END INPUT 

		CONSTRUCT r_where_text ON 
		product.cat_code, 
		product.class_code, 
		costledg.part_code, 
		costledg.ware_code 
		FROM 
		cat_code, 
		class_code, 
		part_code, 
		ware_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","IF8","construct-product-1") -- albo kd-505 
				MESSAGE " Enter criteria FOR selection - ESC TO begin search"
		END CONSTRUCT 
 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "ACCEPT" 
			ACCEPT DIALOG
			
		ON ACTION "CANCEL" 
			EXIT DIALOG

	END DIALOG

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION
############################################################
# END FUNCTION IF8_rpt_query() 
############################################################

############################################################
# FUNCTION IF8_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IF8_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_costledg RECORD LIKE costledg.*	
	DEFINE l_cat_code LIKE category.cat_code

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	IF modu_book_tax = "B" THEN 
		LET l_rpt_idx = rpt_start(getmoduleid(),"IF8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	ELSE 
		LET l_rpt_idx = rpt_start(trim(getmoduleid())||".","IF8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	END IF

	START REPORT IF8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT product.cat_code,costledg.* ", 
	"FROM product,costledg ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"costledg.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"product.part_code = costledg.part_code AND ", 
	"costledg.tran_date > \"",modu_start_date,"\" AND ", 
	"costledg.tran_date < \"",modu_end_date,"\" AND ", 
	"costledg.onhand_qty != 0 AND ", 
	p_where_text CLIPPED," ", 
	"ORDER BY product.cat_code" 

	PREPARE s_costledg FROM l_query_text 
	DECLARE c_costledg CURSOR FOR s_costledg 

	FOREACH c_costledg INTO l_cat_code,l_rec_costledg.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IF8_rpt_list(l_rpt_idx,l_cat_code,l_rec_costledg.*,modu_book_tax) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_costledg.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IF8_rpt_list
	RETURN rpt_finish("IF8_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IF8_rpt_process() 
############################################################

############################################################
# REPORT IF8_rpt_list(p_rpt_idx,p_cat_code,p_rec_costledg,p_book_tax)
#
# Report Definition/Layout
############################################################
REPORT IF8_rpt_list(p_rpt_idx,p_cat_code,p_rec_costledg,p_book_tax) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cat_code LIKE category.cat_code
	DEFINE p_rec_costledg RECORD LIKE costledg.*
	DEFINE p_book_tax CHAR(1) 
	DEFINE l_cat_desc LIKE category.desc_text 
	DEFINE l_arr_curr_amt ARRAY[13] OF DECIMAL(14,4) 
	DEFINE l_arr_wo_amt ARRAY[13] OF DECIMAL(14,4) 
	DEFINE l_arr_round_amt ARRAY[14] OF DECIMAL(16,0) 
	DEFINE l_total_amt DECIMAL(16,0) 
	DEFINE l_offset SMALLINT 
	DEFINE l_col_num SMALLINT
	DEFINE i SMALLINT

	ORDER EXTERNAL BY p_cat_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			LET l_offset = LENGTH(glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3)/2 - LENGTH("As at "||modu_val_date)/2
			PRINT COLUMN l_offset,"As at "||modu_val_date CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_cat_code 
		SELECT desc_text INTO l_cat_desc 
		FROM category 
		WHERE category.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				category.cat_code = p_cat_code 
		IF STATUS = NOTFOUND THEN 
			LET l_cat_desc = "N/A" 
		END IF 
		# initialise variables FOR accumulation
		FOR i = 1 TO 13 
			LET l_arr_curr_amt[i] = 0 
			LET l_arr_wo_amt[i] = 0 
		END FOR

	ON EVERY ROW 
		# Choose value amounts according TO valuation type
		IF p_book_tax = "T" THEN 
			LET p_rec_costledg.curr_cost_amt = p_rec_costledg.tax_cost_amt 
			LET p_rec_costledg.curr_wo_amt = p_rec_costledg.tax_wo_amt 
			LET p_rec_costledg.prev_wo_amt = p_rec_costledg.prev_tax_wo_amt 
		END IF 
		# IF transaction dated within one year FROM valuation DATE, add TO
		# Year 1 total OTHERWISE, search FOR appropriate year
		IF p_rec_costledg.tran_date >= modu_arr_date[1] THEN 
			LET l_arr_curr_amt[1] = l_arr_curr_amt[1] + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
			IF p_rec_costledg.curr_wo_amt != 0 OR p_rec_costledg.prev_wo_amt != 0 THEN 
				LET l_arr_wo_amt[1] = l_arr_wo_amt[1] + (p_rec_costledg.onhand_qty * (p_rec_costledg.curr_wo_amt + p_rec_costledg.prev_wo_amt)) 
			END IF 
		ELSE 
			FOR i = 12 TO 1 STEP -1 
				IF p_rec_costledg.tran_date < modu_arr_date[i] THEN 
					LET l_arr_curr_amt[i+1] = l_arr_curr_amt[i+1] + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
					IF p_rec_costledg.curr_wo_amt != 0 OR p_rec_costledg.prev_wo_amt != 0 THEN 
						LET l_arr_wo_amt[i+1] = l_arr_wo_amt[i+1] + (p_rec_costledg.onhand_qty * (p_rec_costledg.curr_wo_amt + p_rec_costledg.prev_wo_amt)) 
					END IF 
					EXIT FOR 
				END IF 
			END FOR 
		END IF 

	AFTER GROUP OF p_cat_code 
		NEED 4 LINES 
		# Current amounts rounded TO whole dollars before printing
		# Rounded amounts added TO line AND COLUMN totals TO ensure REPORT adds correctly
		LET l_arr_round_amt[14] = 0 
		FOR i = 1 TO 13 
			LET l_arr_round_amt[i] = l_arr_curr_amt[i] * 1 
			LET l_arr_round_amt[14] = l_arr_round_amt[14] + l_arr_round_amt[i] 
			LET modu_arr_curr_tot[i] = modu_arr_curr_tot[i] + l_arr_round_amt[i] 
		END FOR 
		LET modu_arr_curr_tot[14] = modu_arr_curr_tot[14] + l_arr_round_amt[14] 
		LET l_col_num = 5 
		PRINT 
		COLUMN 01, p_cat_code CLIPPED,
		COLUMN 05, l_cat_desc CLIPPED
		PRINT	COLUMN 01, "Cur"; 
		FOR i = 1 TO 13 
			PRINT COLUMN l_col_num, l_arr_round_amt[i]                USING "###,###,##&"; 
			LET l_col_num = l_col_num + 11 
		END FOR 
		PRINT COLUMN l_col_num, l_arr_round_amt[14]                  USING "#,###,###,##&" 
		LET l_total_amt = l_arr_round_amt[14] 
		# Writedown amounts rounded TO whole dollars before printing
		# Rounded amounts added TO totals TO ensure REPORT adds correctly
		LET l_arr_round_amt[14] = 0 
		FOR i = 1 TO 13 
			LET l_arr_round_amt[i] = l_arr_wo_amt[i] * 1 
			LET l_arr_round_amt[14] = l_arr_round_amt[14] + l_arr_round_amt[i] 
			LET modu_arr_wo_tot[i] = modu_arr_wo_tot[i] + l_arr_round_amt[i] 
		END FOR 
		LET modu_arr_wo_tot[14] = modu_arr_wo_tot[14] + l_arr_round_amt[14] 
		LET l_col_num = 5 
		PRINT	COLUMN 1, "W/O"; 
		FOR i = 1 TO 13 
			PRINT COLUMN l_col_num, l_arr_round_amt[i]                USING "###,###,##&"; 
			LET l_col_num = l_col_num + 11 
		END FOR 
		PRINT COLUMN l_col_num, l_arr_round_amt[14]                  USING "#,###,###,##&" 
		LET l_total_amt = l_total_amt + l_arr_round_amt[14] 
		PRINT 
		COLUMN 127, "Total Value ", 
		COLUMN 139, p_cat_code CLIPPED,
		COLUMN 142, ":",
		COLUMN 145, l_total_amt                                      USING "-###,###,###,##&" 
		SKIP 1 LINE

	ON LAST ROW 
		SKIP 1 LINE 
		LET l_col_num = 5 
		PRINT COLUMN 01, "Report Totals:"
		PRINT	COLUMN 01, "Cur"; 
		FOR i = 1 TO 13 
			PRINT COLUMN l_col_num, modu_arr_curr_tot[i]              USING "###,###,##&"; 
			LET l_col_num = l_col_num + 11 
		END FOR 
		PRINT COLUMN l_col_num, modu_arr_curr_tot[14]                USING "#,###,###,##&" 
		LET l_total_amt = modu_arr_curr_tot[14] 
		LET l_col_num = 5 
		PRINT	COLUMN 01, "W/O"; 
		FOR i = 1 TO 13 
			PRINT COLUMN l_col_num, modu_arr_wo_tot[i]                USING "###,###,##&"; 
			LET l_col_num = l_col_num + 11 
		END FOR 
		PRINT COLUMN l_col_num, modu_arr_wo_tot[14]                  USING "#,###,###,##&" 
		LET l_total_amt = l_total_amt + modu_arr_wo_tot[14] 
		PRINT COLUMN 130, "Total Value :",COLUMN 143, l_total_amt    USING "-#,###,###,###,##&" 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
