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
DEFINE modu_cost_option CHAR(1)

############################################################
# FUNCTION IB3_main()
#
# Purpose - Stock Valuations
############################################################
FUNCTION IB3_main()

	CALL setModuleId("IB3") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I162 WITH FORM "I162" 
			 CALL windecoration_i("I162")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Stock Valuation" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IB3","menu-Stock_Valuation-1") -- albo kd-505 
					CALL rpt_rmsreps_reset(NULL)
					CALL IB3_rpt_process(IB3_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IB3_rpt_process(IB3_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I162

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IB3_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I162 with FORM "I162" 
			 CALL windecoration_i("I162") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IB3_rpt_query()) #save where clause in env 
			CLOSE WINDOW I162 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IB3_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IB3_main()
############################################################

############################################################
# FUNCTION IB3_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IB3_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	prodstatus.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	prodstatus.status_ind, 
	prodstatus.ware_code, 
	prodstatus.onhand_qty, 
	prodstatus.reserved_qty, 
	prodstatus.back_qty, 
	prodstatus.forward_qty, 
	prodstatus.onord_qty, 
	prodstatus.bin1_text, 
	prodstatus.bin2_text, 
	prodstatus.bin3_text, 
	prodstatus.last_sale_date, 
	prodstatus.last_receipt_date, 
	prodstatus.stocked_flag, 
	prodstatus.stockturn_qty, 
	prodstatus.abc_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IB3","construct-prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	END IF
 
	OPEN WINDOW i225 with FORM "I225" 
	 CALL windecoration_i("I225") -- albo kd-758 
	INPUT modu_cost_option FROM cost_ind 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IB3","input-cost_option-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF modu_cost_option NOT MATCHES "[L,S,W]" AND modu_cost_option IS NOT NULL THEN 
				ERROR "Invalid valuation method; Must be W,L,S."
				#LET msgresp = kandoomsg("I",9501,"") 
				#9501 Invalid valuation MESSAGE
				NEXT FIELD cost_ind 
			END IF 

	END INPUT 

	CLOSE WINDOW i225

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	END IF

	RETURN r_where_text

END FUNCTION
############################################################
# FUNCTION IB3_rpt_query() 
############################################################

############################################################
#FUNCTION IB3_rpt_process(p_where_text) 
#
# The report driver
############################################################
FUNCTION IB3_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_report_line RECORD 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		wgted_cost_amt LIKE prodstatus.wgted_cost_amt, 
		est_cost_amt LIKE prodstatus.est_cost_amt, 
		act_cost_amt LIKE prodstatus.act_cost_amt, 
		cat_code LIKE product.cat_code, 
		class_code LIKE product.class_code 
	END RECORD 
 
	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IB3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IB3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatus.part_code,", 
	"prodstatus.ware_code,", 
	"prodstatus.onhand_qty,", 
	"prodstatus.reserved_qty,", 
	"prodstatus.back_qty,", 
	"prodstatus.wgted_cost_amt,", 
	"prodstatus.est_cost_amt,", 
	"prodstatus.act_cost_amt,", 
	"product.cat_code,", 
	"product.class_code ", 
	"FROM prodstatus,", 
	"product ", 
	"WHERE prodstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.cmpy_code = prodstatus.cmpy_code ", 
	"AND product.part_code = prodstatus.part_code ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY prodstatus.ware_code,prodstatus.part_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_report_line.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IB3_rpt_list (l_rpt_idx,l_rec_report_line.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_report_line.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IB3_rpt_list
	RETURN rpt_finish("IB3_rpt_list")
	#------------------------------------------------------------

END FUNCTION 

############################################################
# REPORT IB3_rpt_list(p_rpt_idx,p_rec_report_line)
#
# Report Definition/Layout
############################################################
REPORT IB3_rpt_list(p_rpt_idx,p_rec_report_line) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_report_line RECORD 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		wgted_cost_amt LIKE prodstatus.wgted_cost_amt, 
		est_cost_amt LIKE prodstatus.est_cost_amt, 
		act_cost_amt LIKE prodstatus.act_cost_amt, 
		cat_code LIKE product.cat_code, 
		class_code LIKE product.class_code 
	END RECORD 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_rec_opparms RECORD LIKE opparms.* 
	DEFINE l_dec_place_num LIKE inparms.dec_place_num 
	DEFINE l_avail DECIMAL(16,4)
	DEFINE l_tot_avail_qty DECIMAL(16,4) 
	DEFINE l_tot_av_value MONEY(16,2) 
	DEFINE l_tot_on_value MONEY(16,2)
	DEFINE l_avail_value MONEY(16,2)
	DEFINE l_on_value MONEY(16,2)
	DEFINE l_qty_dec_format CHAR(14)
	DEFINE l_total_dec_format CHAR(14)
	DEFINE l_on_val DECIMAL(16,4) 
	DEFINE l_avail_val DECIMAL(16,4)
	DEFINE l_line CHAR(132) 
	DEFINE l_cost_amt LIKE prodstatus.act_cost_amt 

	ORDER EXTERNAL BY p_rec_report_line.ware_code,p_rec_report_line.part_code 

	FORMAT 
		FIRST PAGE HEADER 
			SELECT dec_place_num INTO l_dec_place_num FROM inparms 
			WHERE parm_code = "1" 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF STATUS = NOTFOUND THEN 
				LET l_dec_place_num = 2 -- albo
		--		LET msgresp = kandoomsg("I",5002,"") 
		--		#5002 Inventroy Parameters are NOT Set Up;  Refer Menu IZP.
		--		EXIT program 
			END IF
			# DECIMAL places should only SET between 0 - 4 in IZP
			CASE l_dec_place_num 
				WHEN 0 
					LET l_qty_dec_format = "---,---,--&" 
					LET l_total_dec_format = "--,---,---,--&" 
				WHEN 1 
					LET l_qty_dec_format = "-,---,--&.&" 
					LET l_total_dec_format = "----,---,--&.&" 
				WHEN 2 
					LET l_qty_dec_format = "----,--&.&&" 
					LET l_total_dec_format = "---,---,--&.&&" 
				WHEN 3 
					LET l_qty_dec_format = "---,--&.&&&" 
					LET l_total_dec_format = "--,---,--&.&&&" 
				OTHERWISE 
					LET l_qty_dec_format = "--,--&.&&&&" 
					LET l_total_dec_format = "-,---,--&.&&&&" 
			END CASE

			SELECT * INTO l_rec_opparms.* FROM opparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_num = "1" 
			IF STATUS = NOTFOUND THEN 
				LET l_rec_opparms.cal_available_flag = "N" 
			END IF

			LET l_avail_value = 0 
			LET l_on_value = 0 
			LET l_tot_avail_qty = 0 
			LET l_tot_av_value = 0 
			LET l_tot_on_value = 0
			CASE 
				WHEN modu_cost_option = "W" 
					LET l_line = glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text 
				WHEN modu_cost_option = "L" 
					LET l_line = glob_arr_rec_rpt_kandooreport[p_rpt_idx].line4_text
				WHEN modu_cost_option = "S" 
					LET l_line = glob_arr_rec_rpt_kandooreport[p_rpt_idx].line5_text
			END CASE 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, l_line CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, l_line CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_report_line.ware_code 
		LET l_avail_val = 0 
		LET l_on_val = 0 
		SELECT * INTO l_rec_warehouse.* FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_rec_report_line.ware_code 
		PRINT COLUMN 01, "Warehouse: ", p_rec_report_line.ware_code CLIPPED, 
		" - ", l_rec_warehouse.desc_text CLIPPED 

	ON EVERY ROW 
		IF l_rec_opparms.cal_available_flag = "N" THEN 
			LET l_avail = p_rec_report_line.onhand_qty - p_rec_report_line.reserved_qty - 
			p_rec_report_line.back_qty 
		ELSE 
			LET l_avail = p_rec_report_line.onhand_qty - p_rec_report_line.reserved_qty 
		END IF 
		IF modu_cost_option = "W" THEN 
			LET l_cost_amt = p_rec_report_line.wgted_cost_amt 
		END IF 
		IF modu_cost_option = "L" THEN 
			LET l_cost_amt = p_rec_report_line.act_cost_amt 
		END IF 
		IF modu_cost_option = "S" THEN 
			LET l_cost_amt = p_rec_report_line.est_cost_amt 
		END IF 
		IF l_cost_amt IS NULL THEN 
			LET l_cost_amt = 0 
		END IF 
		LET l_avail_value = l_cost_amt * l_avail 
		LET l_on_value = p_rec_report_line.onhand_qty * l_cost_amt 
		PRINT COLUMN 06, p_rec_report_line.part_code, 
		COLUMN 28, p_rec_report_line.cat_code, 
		COLUMN 40, p_rec_report_line.class_code, 
		COLUMN 53, p_rec_report_line.onhand_qty USING l_qty_dec_format, 
		COLUMN 68, l_avail USING l_qty_dec_format, 
		COLUMN 83, l_cost_amt USING "----,--&.&&&&", 
		COLUMN 98, l_on_value USING "----,---,--&.&&", 
		COLUMN 117, l_avail_value USING "----,---,--&.&&" 
		IF l_on_value IS NOT NULL THEN 
			LET l_tot_on_value = l_tot_on_value + l_on_value 
			LET l_on_val = l_on_val + l_on_value 
		END IF 
		IF l_avail_value IS NOT NULL THEN 
			LET l_tot_av_value = l_tot_av_value + l_avail_value 
			LET l_avail_val = l_avail_val + l_avail_value 
		END IF 
		LET l_tot_avail_qty = l_tot_avail_qty + l_avail 

	AFTER GROUP OF p_rec_report_line.ware_code 
		IF l_rec_opparms.cal_available_flag = "N" THEN 
			LET l_avail = GROUP sum(p_rec_report_line.onhand_qty - 
			p_rec_report_line.reserved_qty - 
			p_rec_report_line.back_qty) 
		ELSE 
			LET l_avail = GROUP sum(p_rec_report_line.onhand_qty - 
			p_rec_report_line.reserved_qty) 
		END IF 
		IF modu_cost_option = "W" THEN 
			LET l_cost_amt = GROUP sum(p_rec_report_line.wgted_cost_amt) 
		END IF 
		IF modu_cost_option = "L" THEN 
			LET l_cost_amt = GROUP sum(p_rec_report_line.act_cost_amt) 
		END IF 
		IF modu_cost_option = "S" THEN 
			LET l_cost_amt = GROUP sum(p_rec_report_line.est_cost_amt) 
		END IF 
		PRINT COLUMN 49, "---------------", 
		COLUMN 65, "--------------", 
		COLUMN 98, "---------------", 
		COLUMN 117, "---------------" 
		PRINT COLUMN 06, "Warehouse Totals: ", 
		COLUMN 50, GROUP sum(p_rec_report_line.onhand_qty) USING l_total_dec_format, 
		COLUMN 65, l_avail USING l_total_dec_format, 
		COLUMN 98, l_on_val USING "----,---,--&.&&", 
		COLUMN 117, l_avail_val USING "----,---,--&.&&" 
		SKIP 1 LINES 

	ON LAST ROW 
		NEED 10 LINES 
		PRINT COLUMN 49, "===============", 
		COLUMN 65, "==============", 
		COLUMN 98, "===============", 
		COLUMN 117, "===============" 
		PRINT COLUMN 1, "Report Totals: ", 
		COLUMN 50, sum(p_rec_report_line.onhand_qty) USING l_total_dec_format, 
		COLUMN 65, l_tot_avail_qty USING l_total_dec_format, 
		COLUMN 98, l_tot_on_value USING "----,---,--&.&&", 
		COLUMN 117, l_tot_av_value USING "----,---,--&.&&" 
		PRINT COLUMN 49, "===============", 
		COLUMN 65, "==============", 
		COLUMN 98, "===============", 
		COLUMN 117, "===============" 
		LET l_on_value = 0 
		LET l_avail_value = 0 
		LET l_avail = 0 
		SKIP 1 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
