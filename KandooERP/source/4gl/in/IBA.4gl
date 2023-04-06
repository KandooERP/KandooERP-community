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
DEFINE modu_orderby_num CHAR(1) 

############################################################
# FUNCTION IBA_main()
#
# Purpose - Top 100 Products Report by Volume OR Sales Value
############################################################
FUNCTION IBA_main()

	CALL setModuleId("IBA") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I163 WITH FORM "I163" 
			 CALL windecoration_i("I163")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Top 100 Products" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IBA","menu-Top_100_Products-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IBA_rpt_process(IBA_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IBA_rpt_process(IBA_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I163

		WHEN "2" #Background Process with rmsreps.report_code
			LET modu_orderby_num = "6"
			CALL IBA_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I163 with FORM "I163" 
			 CALL windecoration_i("I163") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			LET modu_orderby_num = "6"
			CALL set_url_sel_text(IBA_rpt_query()) #save where clause in env 
			CLOSE WINDOW I163 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			LET modu_orderby_num = "6"
			CALL IBA_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION IBA_main()
############################################################

############################################################
# FUNCTION IBA_report_menu()
#
# Purpose - Choosing the Report sorting mode
############################################################
FUNCTION IBA_report_menu() 
	DEFINE menu_option CHAR(1) 

	MENU "Run Report" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","IBA","menu-Run Report-1") -- albo kd-505 
			CALL fgl_dialog_setactionlabel("Net Sales","Net Sales","{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg",2,FALSE,"Order Report by Net Sales Value ($)")
			CALL fgl_dialog_setactionlabel("Gross Sales","Gross Sales","{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg",3,FALSE,"Order Report by Gross Sales Value ($)")
			CALL fgl_dialog_setactionlabel("Volume","Volume","{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg",4,FALSE,"Order Report by Volume (Units)")			

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null)

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()

		ON ACTION "Net Sales" 
			LET menu_option = "6" --> "Top 100 Products by Net Sales Value" 
			EXIT MENU

		ON ACTION "Gross Sales" 
			LET menu_option = "4" --> "Top 100 Products by Gross Sales Value" 
			EXIT MENU 

		ON ACTION "Volume" 
			LET menu_option = "7" --> "Top 100 Products by Sales Volume" 
			EXIT MENU 

		ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU

	END MENU 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN menu_option 
  	END IF

END FUNCTION 
############################################################
# END FUNCTION IBA_report_menu()
############################################################

############################################################
# FUNCTION IBA_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IBA_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	product.cat_code, 
	product.class_code, 
	product.alter_part_code, 
	product.super_part_code, 
	product.compn_part_code, 
	prodledg.ware_code, 
	prodledg.tran_date, 
	prodledg.trantype_ind, 
	prodledg.year_num, 
	prodledg.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IBA","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
      LET modu_orderby_num = NULL
		RETURN NULL 
	ELSE 
      LET modu_orderby_num = IBA_report_menu()
		RETURN r_where_text
	END IF 

END FUNCTION 
############################################################
# END FUNCTION IBA_rpt_query() 
############################################################

############################################################
# FUNCTION IBA_rpt_process(p_where_text) 
#
# The report driver
############################################################
FUNCTION IBA_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_prodledg RECORD 
		rank_num DECIMAL(3,0), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		gross_amt MONEY(15,2), 
		gross_per DECIMAL(7,2), 
		gross_num DECIMAL(3,0), 
		sales_amt MONEY(15,2), 
		cost_amt MONEY(15,2), 
		volume DECIMAL(15,4) 
	END RECORD 
	DEFINE l_arr_prodarray ARRAY[100] OF RECORD 
		rank_num DECIMAL(3,0), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		gross_amt MONEY(15,2), 
		gross_per DECIMAL(7,2), 
		gross_num DECIMAL(3,0), 
		sales_amt MONEY(15,2), 
		cost_amt MONEY(15,2), 
		volume DECIMAL(15,4) 
	END RECORD
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE i,j,pos INTEGER
	DEFINE idx INTEGER	

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	CASE modu_orderby_num
		WHEN "6"
			LET l_rpt_idx = rpt_start("IBA","IBA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
		WHEN "4"
			LET l_rpt_idx = rpt_start("IBA.","IBA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
		WHEN "7"
			LET l_rpt_idx = rpt_start("IBA..","IBA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
		OTHERWISE
			RETURN FALSE
	END CASE					

	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IBA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	IF p_where_text MATCHES "*tran_date*" THEN
	ELSE 
		LET p_where_text = p_where_text CLIPPED, " AND prodledg.tran_date ", 
		"BETWEEN \"",DAY(TODAY) USING "&&","\/",MONTH(TODAY) USING "&&","\/",YEAR(TODAY)-1 USING "&&&&" ,"\" AND \"",TODAY,"\" " 
	END IF 
	LET l_query_text = 
	"SELECT prodledg.cmpy_code,prodledg.part_code,product.desc_text,", 
	"sum(prodledg.sales_amt*prodledg.tran_qty)*-1,", 
	"sum(prodledg.cost_amt*prodledg.tran_qty)*-1,", 
	"(sum(prodledg.sales_amt*prodledg.tran_qty)*-1)-(sum(prodledg.cost_amt*prodledg.tran_qty)*-1),", 
	"sum(prodledg.tran_qty * -1) ", 
	"FROM prodledg,product ", 
	"WHERE prodledg.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.part_code = prodledg.part_code ", 
	"AND prodledg.trantype_ind IN (\"S\") ", 
	"AND ", p_where_text CLIPPED," ",
	"GROUP BY 1,2,3 ", 
	"ORDER BY ",modu_orderby_num," DESC" 
 
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	LET idx = 0 
	FOREACH selcurs INTO
		l_cmpy_code,
		l_rec_prodledg.part_code, 
		l_rec_prodledg.desc_text, 
		l_rec_prodledg.sales_amt,
		l_rec_prodledg.cost_amt, 
		l_rec_prodledg.gross_amt,
		l_rec_prodledg.volume 

		LET idx = idx + 1 
		LET l_rec_prodledg.rank_num = idx 
		IF l_rec_prodledg.sales_amt != 0 THEN 
			LET l_rec_prodledg.gross_per = (l_rec_prodledg.gross_amt / l_rec_prodledg.sales_amt) 
			* 100 
		ELSE 
			LET l_rec_prodledg.gross_per = 0 
		END IF 
		# save in the ARRAY so we can work out the GP % ranking
		LET l_arr_prodarray[idx].* = l_rec_prodledg.* 

		IF idx = 100 THEN 
			EXIT FOREACH 
		END IF 

	END FOREACH 
 
	FOR i=1 TO 100 
		LET pos = 0 

		FOR j=1 TO 100 
			IF l_arr_prodarray[i].gross_per <= l_arr_prodarray[j].gross_per THEN 
				LET pos = pos + 1 
			END IF 
		END FOR 

		LET l_arr_prodarray[i].gross_num = pos 
		IF l_arr_prodarray[i].gross_num > 0 THEN 
			#---------------------------------------------------------
			OUTPUT TO REPORT IBA_rpt_list (l_rpt_idx,l_arr_prodarray[i].*) 
			IF NOT rpt_int_flag_handler2("Product: ",l_arr_prodarray[i].part_code,"",l_rpt_idx) THEN
				EXIT FOR 
			END IF 
			#---------------------------------------------------------
		END IF 

	END FOR 

	#------------------------------------------------------------
	FINISH REPORT IBA_rpt_list
	RETURN rpt_finish("IBA_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IBA_rpt_process(p_where_text) 
############################################################

############################################################
# REPORT IBA_rpt_list(p_rpt_idx,p_rec_prodledg)
#
#
############################################################
REPORT IBA_rpt_list(p_rpt_idx,p_rec_prodledg) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodledg RECORD 
		rank_num DECIMAL(3,0), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		gross_amt MONEY(15,2), 
		gross_per DECIMAL(7,2), 
		gross_num DECIMAL(3,0), 
		sales_amt MONEY(15,2), 
		cost_amt MONEY(15,2), 
		volume DECIMAL(15,4) 
	END RECORD 

	ORDER EXTERNAL BY p_rec_prodledg.rank_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]		PAGE HEADER 

	ON EVERY ROW 
		PRINT COLUMN 1, p_rec_prodledg.rank_num USING "###", 
		COLUMN 8, p_rec_prodledg.part_code, 
		COLUMN 24, p_rec_prodledg.desc_text, 
		COLUMN 61, p_rec_prodledg.gross_num USING "###", 
		COLUMN 65, p_rec_prodledg.volume USING "---,---,--&", 
		COLUMN 77, p_rec_prodledg.sales_amt USING "----,---,-$&.&&", 
		COLUMN 93, p_rec_prodledg.cost_amt USING "----,---,-$&.&&", 
		COLUMN 109, p_rec_prodledg.gross_amt USING "----,---,-$&.&&", 
		COLUMN 125, p_rec_prodledg.gross_per USING "---&.&"

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
