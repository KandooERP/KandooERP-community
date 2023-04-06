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
# FUNCTION ICF_main()
#
# Purpose - Price Exception Report - By Customer
############################################################
FUNCTION ICF_main()

	CALL setModuleId("ICF") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I214 WITH FORM "I214" 
			 CALL windecoration_i("I214")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Price Execption Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ICF","menu-Price Execption-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL ICF_rpt_process(ICF_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL ICF_rpt_process(ICF_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I214

		WHEN "2" #Background Process with rmsreps.report_code
			CALL ICF_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I214 with FORM "I214" 
			 CALL windecoration_i("I214") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ICF_rpt_query()) #save where clause in env 
			CLOSE WINDOW I214 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL ICF_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION
############################################################
# END FUNCTION ICF_main()
############################################################ 

############################################################
# FUNCTION ICF_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION ICF_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	product.part_code, 
	invoicedetl.ware_code, 
	product.desc_text, 
	product.desc2_text, 
	product.cat_code, 
	product.class_code, 
	product.maingrp_code, 
	product.prodgrp_code, 
	invoicehead.cust_code, 
	customer.name_text, 
	customer.type_code, 
	invoicehead.sale_code, 
	invoicehead.inv_num, 
	invoicehead.inv_date, 
	invoicehead.year_num, 
	invoicehead.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ICF","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

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
# END FUNCTION ICF_rpt_query() 
############################################################

############################################################
# FUNCTION ICF_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION ICF_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_invoice RECORD 
		part_code LIKE product.part_code, 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE product.desc_text, 
		desc2_text LIKE product.desc2_text, 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		inv_level_ind LIKE customer.inv_level_ind, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		ship_qty LIKE invoicedetl.ship_qty, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		list_amt LIKE invoicedetl.unit_sale_amt 
	END RECORD 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ICF_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT ICF_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT ", 
	"product.part_code,", 
	"invoicedetl.ware_code,", 
	"product.desc_text,", 
	"product.desc2_text,", 
	"customer.cust_code,", 
	"customer.name_text,", 
	"customer.inv_level_ind,", 
	"invoicehead.inv_num,", 
	"invoicehead.inv_date,", 
	"invoicedetl.ship_qty,", 
	"invoicedetl.unit_sale_amt ", 
	"FROM product,customer,invoicehead,invoicedetl ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND invoicedetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND invoicehead.cust_code = customer.cust_code ", 
	"AND product.part_code = invoicedetl.part_code ", 
	"AND invoicehead.inv_num = invoicedetl.inv_num ", 
	"AND invoicedetl.ship_qty > 0 ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY customer.name_text,customer.cust_code,product.part_code,invoicehead.inv_date,invoicehead.inv_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_invoice.* 
		SELECT *	INTO l_rec_prodstatus.*	FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND
				part_code = l_rec_invoice.part_code	AND
				ware_code = l_rec_invoice.ware_code 
		CASE 
			WHEN l_rec_invoice.inv_level_ind = "1" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.price1_amt 
			WHEN l_rec_invoice.inv_level_ind = "2" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.price2_amt 
			WHEN l_rec_invoice.inv_level_ind = "3" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.price3_amt 
			WHEN l_rec_invoice.inv_level_ind = "4" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.price4_amt 
			WHEN l_rec_invoice.inv_level_ind = "5" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.price5_amt 
			WHEN l_rec_invoice.inv_level_ind = "6" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.price6_amt 
			WHEN l_rec_invoice.inv_level_ind = "7" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.price7_amt 
			WHEN l_rec_invoice.inv_level_ind = "8" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.price8_amt 
			WHEN l_rec_invoice.inv_level_ind = "9" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.price9_amt 
			WHEN l_rec_invoice.inv_level_ind = "L" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.list_amt 
			WHEN l_rec_invoice.inv_level_ind = "C" 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.wgted_cost_amt 
			OTHERWISE 
				LET l_rec_invoice.list_amt = l_rec_prodstatus.list_amt 
		END CASE 
		IF l_rec_invoice.list_amt != l_rec_invoice.unit_sale_amt THEN 
			# discounted price need TO REPORT this one
			#---------------------------------------------------------
			OUTPUT TO REPORT ICF_rpt_list(l_rpt_idx,l_rec_invoice.*) 
			IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodstatus.part_code,"",l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ICF_rpt_list
	RETURN rpt_finish("ICF_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION ICF_rpt_process() 
############################################################

############################################################
# REPORT ICF_rpt_list(p_rpt_idx,p_rec_invoice)
#
# Report Definition/Layout
############################################################
REPORT ICF_rpt_list(p_rpt_idx,p_rec_invoice) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_invoice RECORD 
		part_code LIKE product.part_code, 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE product.desc_text, 
		desc2_text LIKE product.desc2_text, 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		inv_level_ind LIKE customer.inv_level_ind, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		ship_qty LIKE invoicedetl.ship_qty, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		list_amt LIKE invoicedetl.unit_sale_amt 
	END RECORD 

	ORDER EXTERNAL BY p_rec_invoice.name_text,p_rec_invoice.cust_code,p_rec_invoice.part_code,p_rec_invoice.inv_date,p_rec_invoice.inv_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_invoice.part_code 
		PRINT COLUMN 20, p_rec_invoice.part_code CLIPPED,3 SPACES,p_rec_invoice.desc_text CLIPPED,1 SPACES,p_rec_invoice.desc2_text CLIPPED

	BEFORE GROUP OF p_rec_invoice.cust_code 
		PRINT COLUMN 1, p_rec_invoice.cust_code CLIPPED,3 SPACES,p_rec_invoice.name_text CLIPPED

	AFTER GROUP OF p_rec_invoice.part_code 
		SKIP 1 LINE

	ON EVERY ROW 
		IF p_rec_invoice.list_amt <> 0 THEN 
			PRINT COLUMN 32, p_rec_invoice.inv_num USING "########", 
			COLUMN 49, p_rec_invoice.inv_date      USING "DD/MM/YYYY", 
			COLUMN 60, p_rec_invoice.ship_qty      USING "---,---,--&.&&", 
			COLUMN 75, p_rec_invoice.unit_sale_amt USING "---,---,--$.&&", 
			COLUMN 90, p_rec_invoice.list_amt      USING "---,---,--$.&&", 
			COLUMN 105,((p_rec_invoice.list_amt - p_rec_invoice.unit_sale_amt ) * 100 / p_rec_invoice.list_amt) USING "---,---,--$.&&" 
		ELSE 
			PRINT COLUMN 32, p_rec_invoice.inv_num USING "########", 
			COLUMN 49, p_rec_invoice.inv_date      USING "DD/MM/YYYY", 
			COLUMN 60, p_rec_invoice.ship_qty      USING "---,---,--&.&&", 
			COLUMN 75, p_rec_invoice.unit_sale_amt USING "---,---,--$.&&", 
			COLUMN 90, p_rec_invoice.list_amt      USING "---,---,--$.&&" 
		END IF 

	ON LAST ROW 
		SKIP 5 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
