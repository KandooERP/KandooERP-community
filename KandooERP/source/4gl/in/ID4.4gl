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
DEFINE modu_rec_inparms RECORD LIKE inparms.*

############################################################
# FUNCTION ID4_main()
#
# Purpose - Stock Over-stock Report by Product
############################################################
FUNCTION ID4_main()

	CALL setModuleId("ID4") 

	#TODO replace with global_rec_inparms when FUNCTION init_i_in will be finished
	SELECT * INTO modu_rec_inparms.*	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			parm_code = "1" 
	IF STATUS = NOTFOUND THEN 
		CALL msgerror("","Inventory Parameters are not set up.\n                 Refer Menu IZP.")
		#LET msgresp = kandoomsg("I",5002,"") 
		#5002 In Parameters NOT SET up - Refer Menu IZP
		EXIT PROGRAM 
	END IF
 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I175 WITH FORM "I175" 
			 CALL windecoration_i("I175")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Over-stock by Product" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ID4","menu-Over-stock-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL ID4_rpt_process(ID4_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL ID4_rpt_process(ID4_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I175

		WHEN "2" #Background Process with rmsreps.report_code
			CALL ID4_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I175 with FORM "I175" 
			 CALL windecoration_i("I175") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ID4_rpt_query()) #save where clause in env 
			CLOSE WINDOW I175 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL ID4_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION ID4_main()
############################################################

############################################################
# FUNCTION ID4_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION ID4_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
	DEFINE l_seq_num SMALLINT 

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
	product.days_lead_num, 
	product.ref1_code, 
	product.ref2_code, 
	product.ref3_code, 
	product.ref4_code, 
	product.ref5_code, 
	product.ref6_code, 
	product.ref7_code, 
	product.ref8_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ID4","construct-product-1") -- albo kd-505
			LET modu_rec_inparms.ref1_text = modu_rec_inparms.ref1_text CLIPPED,"...................." 
			LET modu_rec_inparms.ref2_text = modu_rec_inparms.ref2_text CLIPPED,"...................."
			LET modu_rec_inparms.ref3_text = modu_rec_inparms.ref3_text CLIPPED,"...................."
			LET modu_rec_inparms.ref4_text = modu_rec_inparms.ref4_text CLIPPED,"...................."
			LET modu_rec_inparms.ref5_text = modu_rec_inparms.ref5_text CLIPPED,"...................."
			LET modu_rec_inparms.ref6_text = modu_rec_inparms.ref6_text CLIPPED,"...................."
			LET modu_rec_inparms.ref7_text = modu_rec_inparms.ref7_text CLIPPED,"...................."
			LET modu_rec_inparms.ref8_text = modu_rec_inparms.ref8_text CLIPPED,"...................."
			DISPLAY BY NAME 
			modu_rec_inparms.ref1_text, 
			modu_rec_inparms.ref2_text, 
			modu_rec_inparms.ref3_text, 
			modu_rec_inparms.ref4_text, 
			modu_rec_inparms.ref5_text, 
			modu_rec_inparms.ref6_text, 
			modu_rec_inparms.ref7_text, 
			modu_rec_inparms.ref8_text 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD ref1_code 
			IF modu_rec_inparms.ref1_text IS NULL THEN 
				LET l_seq_num = 1 
				NEXT FIELD ref2_code 
			END IF 

		BEFORE FIELD ref2_code 
			IF modu_rec_inparms.ref2_text IS NULL THEN 
				IF l_seq_num > 2 THEN 
					LET l_seq_num = 2 
					NEXT FIELD ref1_code 
				ELSE 
					LET l_seq_num = 2 
					NEXT FIELD ref3_code 
				END IF 
			END IF 

		BEFORE FIELD ref3_code 
			IF modu_rec_inparms.ref3_text IS NULL THEN 
				IF l_seq_num > 3 THEN 
					LET l_seq_num = 3 
					NEXT FIELD ref2_code 
				ELSE 
					LET l_seq_num = 3 
					NEXT FIELD ref4_code 
				END IF 
			END IF 
 
		BEFORE FIELD ref4_code 
			IF modu_rec_inparms.ref4_text IS NULL THEN 
				IF l_seq_num > 4 THEN 
					LET l_seq_num = 4 
					NEXT FIELD ref3_code 
				ELSE 
					LET l_seq_num = 4 
					NEXT FIELD ref5_code 
				END IF 
			END IF 
 
		BEFORE FIELD ref5_code 
			IF modu_rec_inparms.ref5_text IS NULL THEN 
				IF l_seq_num > 5 THEN 
					LET l_seq_num = 5 
					NEXT FIELD ref4_code 
				ELSE 
					LET l_seq_num = 5 
					NEXT FIELD ref6_code 
				END IF 
			END IF 
 
		BEFORE FIELD ref6_code 
			IF modu_rec_inparms.ref6_text IS NULL THEN 
				IF l_seq_num > 6 THEN 
					LET l_seq_num = 6 
					NEXT FIELD ref5_code 
				ELSE 
					LET l_seq_num = 6 
					NEXT FIELD ref7_code 
				END IF 
			END IF 
 
		BEFORE FIELD ref7_code 
			IF modu_rec_inparms.ref7_text IS NULL THEN 
				IF l_seq_num > 7 THEN 
					LET l_seq_num = 7 
					NEXT FIELD ref6_code 
				ELSE 
					LET l_seq_num = 7 
					NEXT FIELD ref8_code 
				END IF 
			END IF 
 
		BEFORE FIELD ref8_code 
			IF modu_rec_inparms.ref8_text IS NULL THEN 
				LET l_seq_num = 8 
				EXIT CONSTRUCT 
			END IF 

		AFTER FIELD ref1_code 
			LET l_seq_num = 1 

		AFTER FIELD ref2_code 
			LET l_seq_num = 2 

		AFTER FIELD ref3_code 
			LET l_seq_num = 3

		AFTER FIELD ref4_code 
			LET l_seq_num = 4			
			
		AFTER FIELD ref5_code 
			LET l_seq_num = 5

		AFTER FIELD ref6_code 
			LET l_seq_num = 6

		AFTER FIELD ref7_code 
			LET l_seq_num = 7

		AFTER FIELD ref8_code 
			LET l_seq_num = 8 

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
# END FUNCTION ID4_rpt_query() 
############################################################

############################################################
# FUNCTION ID4_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION ID4_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_tran_qty LIKE prodledg.tran_qty 
	DEFINE l_required_qty LIKE prodstatus.onhand_qty 
	DEFINE l_sales_days_num LIKE product.days_lead_num 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ID4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT ID4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatus.*,product.* ", 
	"FROM prodstatus,product ", 
	"WHERE prodstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND prodstatus.part_code = product.part_code ", 
	"AND prodstatus.stocked_flag = 'Y' ", 
	"AND (prodstatus.status_ind='1' OR prodstatus.status_ind='4') ", 
	"AND product.trade_in_flag = 'N' ", 
	"AND (product.status_ind='1' OR product.status_ind='4') ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY prodstatus.part_code,prodstatus.ware_code" 

	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 

	FOREACH c_prodstatus INTO l_rec_prodstatus.*,l_rec_product.* 
		SELECT SUM(tran_qty)	INTO l_tran_qty FROM prodledg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				part_code = l_rec_prodstatus.part_code	AND 
				ware_code = l_rec_prodstatus.ware_code	AND 
				trantype_ind in ("C", "I", "J", "S")AND 
				tran_date >= l_rec_product.status_date 
		# We need sales as a positive value
		IF l_tran_qty < 0 THEN 
			LET l_tran_qty = l_tran_qty * -1 
		ELSE 
			LET l_tran_qty = 0 
		END IF 
		LET l_sales_days_num = (TODAY - l_rec_prodstatus.status_date) 
		IF l_sales_days_num = 0 THEN 
			LET l_sales_days_num = 1 
		END IF 
		IF l_rec_product.days_lead_num = 0 THEN 
			LET l_rec_product.days_lead_num = 1 
		END IF 
		LET l_required_qty = (l_tran_qty / l_sales_days_num) * l_rec_product.days_lead_num 
		IF l_rec_prodstatus.onhand_qty > l_required_qty THEN 
			#---------------------------------------------------------
			OUTPUT TO REPORT ID4_rpt_list(l_rpt_idx,l_rec_prodstatus.*,l_rec_product.*,l_required_qty) 
			IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodstatus.part_code,"",l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#--------------------------------------------------------- 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ID4_rpt_list
	RETURN rpt_finish("ID4_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION ID4_rpt_process() 
############################################################

############################################################
# REPORT ID4_rpt_list(p_rpt_idx,p_rec_prodstatus,p_rec_product,p_required_qty)
#
# Report Definition/Layout
############################################################
REPORT ID4_rpt_list(p_rpt_idx,p_rec_prodstatus,p_rec_product,p_required_qty) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE p_rec_product RECORD LIKE product.* 
 	DEFINE p_required_qty LIKE prodstatus.onhand_qty 
	DEFINE l_over_stock_qty LIKE prodstatus.onhand_qty 
	DEFINE l_over_days_num LIKE product.days_lead_num 
	
	ORDER BY EXTERNAL p_rec_prodstatus.part_code, p_rec_prodstatus.ware_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_prodstatus.part_code 
		PRINT COLUMN 1, p_rec_product.part_code CLIPPED, 
		COLUMN 17, p_rec_product.desc_text CLIPPED; 

	ON EVERY ROW 
		IF p_rec_product.days_lead_num = 0 THEN 
			LET p_rec_product.days_lead_num = 1 
		END IF 
		LET l_over_stock_qty = (p_rec_prodstatus.onhand_qty - p_required_qty) 
		IF p_required_qty != 0 THEN 
			LET l_over_days_num = (l_over_stock_qty / p_required_qty) / p_rec_product.days_lead_num 
		ELSE 
			LET l_over_days_num = l_over_stock_qty / p_rec_product.days_lead_num 
		END IF 
		PRINT COLUMN 54, p_rec_prodstatus.ware_code CLIPPED, 
		COLUMN 59, p_rec_prodstatus.onhand_qty USING "----,---.&&", 
		COLUMN 71, p_rec_product.sell_uom_code CLIPPED, 
		COLUMN 80, p_required_qty          USING "----,---.&&", 
		COLUMN 92, p_rec_product.sell_uom_code CLIPPED, 
		COLUMN 101,l_over_stock_qty        USING "----,---.&&", 
		COLUMN 113,p_rec_product.sell_uom_code CLIPPED, 
		COLUMN 120,l_over_days_num         USING "-------&" 

	ON LAST ROW 
		SKIP 1 LINE
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
