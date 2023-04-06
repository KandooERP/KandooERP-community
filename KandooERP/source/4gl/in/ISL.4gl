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
DEFINE modu_mast_warecode LIKE inparms.mast_ware_code
DEFINE modu_blank_line_num SMALLINT
DEFINE modu_rec_warehouse RECORD LIKE warehouse.*
DEFINE modu_arr_label DYNAMIC ARRAY OF RECORD 
			part_code LIKE product.part_code, 
			desc_text LIKE product.desc_text, 
			label_num SMALLINT, 
			serial_code LIKE serialinfo.serial_code 
		END RECORD

############################################################
# FUNCTION ISL_main()
#
# Purpose - Product Label Generation
############################################################
FUNCTION ISL_main()

	CALL setModuleId("ISL") 

	#TODO replace with global_rec_inparms when FUNCTION init_i_in will be finished
	SELECT inparms.mast_ware_code INTO modu_mast_warecode 
	FROM inparms 
	WHERE inparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inparms.parm_code = "1"
	IF STATUS = NOTFOUND THEN 
		CALL msgerror("","Inventory Parameters are not set up.\n                Refer Menu IZP.")
		#LET msgresp = kandoomsg("I",5002,"") 
		#5002 In Parameters NOT SET up refer TO menu IZP
		EXIT program 
	END IF

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I630 WITH FORM "I630" 
			 CALL windecoration_i("I630")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Product Label" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ISL","menu-Product_Status-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL ISL_rpt_process(ISL_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL ISL_rpt_process(ISL_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I630

		WHEN "2" #Background Process with rmsreps.report_code
			CALL ISL_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I630 with FORM "I630" 
			 CALL windecoration_i("I630") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ISL_rpt_query()) #save where clause in env 
			CLOSE WINDOW I630 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL ISL_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION ISL_main()
############################################################

############################################################
# FUNCTION ISL_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION ISL_rpt_query() 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_labelhead RECORD LIKE labelhead.* 
	DEFINE l_serial_code LIKE serialinfo.serial_code
	DEFINE l_no_of_labels SMALLINT 
	DEFINE l_where_part STRING 
	DEFINE l_query_text STRING
	DEFINE idx SMALLINT 
	DEFINE scrn SMALLINT

	SELECT * INTO modu_rec_warehouse.* FROM warehouse 
	WHERE warehouse.ware_code = modu_mast_warecode 
	AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_no_of_labels = 1 

	DISPLAY BY NAME l_rec_labelhead.label_code, 
	modu_rec_warehouse.ware_code 

	DISPLAY l_rec_labelhead.desc_text, 
	modu_rec_warehouse.desc_text, 
	l_no_of_labels 
	TO label_text, 
	ware_text, 
	no_of_labels 

	CLEAR FORM
	DIALOG ATTRIBUTES(UNBUFFERED)

		INPUT l_rec_labelhead.label_code, 
		modu_rec_warehouse.ware_code, 
		l_no_of_labels WITHOUT DEFAULTS 
		FROM 
		label_code, 
		ware_code, 
		no_of_labels 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","ISL","input-l_rec_labelhead-1") -- albo kd-505 

			AFTER FIELD label_code 
				IF l_rec_labelhead.label_code IS NULL THEN 
					ERROR kandoomsg2("I",9162,"") 
					#9162 Label Code must be entered
					NEXT FIELD label_code 
				ELSE 
					SELECT * INTO l_rec_labelhead.* FROM labelhead 
					WHERE labelhead.label_code = l_rec_labelhead.label_code 
					AND labelhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF STATUS = NOTFOUND THEN 
						ERROR kandoomsg2("I",9170,"") 
						#9170 Label does NOT exist - Try Window
						NEXT FIELD label_code 
					ELSE 
						DISPLAY l_rec_labelhead.desc_text TO label_text 
					END IF 
				END IF 

			AFTER FIELD ware_code 
				IF modu_rec_warehouse.ware_code IS NULL THEN 
					ERROR kandoomsg2("I",9029,"") 
					#9029 Warehouse Code must be entered
					NEXT FIELD ware_code 
				ELSE 
					SELECT * INTO modu_rec_warehouse.* FROM warehouse 
					WHERE warehouse.ware_code = modu_rec_warehouse.ware_code 
					AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF STATUS = NOTFOUND THEN 
						ERROR kandoomsg2("I",9030,"") 
						#9030 Warehouse does NOT exist - Try Window
						NEXT FIELD ware_code 
					ELSE 
						DISPLAY modu_rec_warehouse.desc_text TO ware_text 
					END IF 
				END IF 

			AFTER FIELD no_of_labels 
				IF l_no_of_labels IS NULL 
				OR l_no_of_labels < 1 THEN 
					ERROR kandoomsg2("I",9171,"") 
					#9171 AT least one label must be printed
					NEXT FIELD no_of_labels 
				END IF 

		END INPUT 

		CONSTRUCT BY NAME l_where_part ON 
		prodstatus.part_code, 
		product.desc_text, 
		product.cat_code, 
		product.prodgrp_code, 
		product.maingrp_code, 
		prodstatus.bin1_text, 
		prodstatus.bin2_text, 
		prodstatus.bin3_text, 
		prodstatus.stocked_flag, 
		prodstatus.abc_ind, 
		prodstatus.stockturn_qty, 
		product.vend_code, 
		prodstatus.last_sale_date, 
		prodstatus.last_receipt_date, 
		prodstatus.last_price_date, 
		prodstatus.last_list_date, 
		prodstatus.last_cost_date, 
		serialinfo.serial_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ISL","construct-prodstatus-1") -- albo kd-505 

		END CONSTRUCT 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "ACCEPT" 
			ACCEPT DIALOG
			
		ON ACTION "CANCEL" 
			EXIT DIALOG

	END DIALOG

	IF int_flag OR quit_flag THEN 
		#9507 Query was Aborted
		LET msgresp = kandoomsg("U", 9507, "") 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	END IF 

	LET l_query_text = "SELECT DISTINCT serialinfo.serial_code, product.* ", 
	"FROM prodstatus, serialinfo, product ", 
	"WHERE prodstatus.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND product.cmpy_code = prodstatus.cmpy_code ", 
	"AND product.part_code = prodstatus.part_code ", 
	"AND prodstatus.ware_code = '", 
	modu_rec_warehouse.ware_code, "' ", 
	"AND serialinfo.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND serialinfo.part_code = product.part_code ", 
	"AND serialinfo.ware_code = prodstatus.ware_code ", 
	"AND serialinfo.trantype_ind = '0' ", 
	"AND ", l_where_part CLIPPED, " ", 
	"ORDER BY product.part_code" 

	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 

	LET idx = 0 
	CALL modu_arr_label.clear()
	FOREACH c_prodstatus INTO l_serial_code, l_rec_product.* 
		LET idx = idx + 1 
		LET modu_arr_label[idx].part_code = l_rec_product.part_code 
		LET modu_arr_label[idx].desc_text = l_rec_product.desc_text 
		LET modu_arr_label[idx].label_num = l_no_of_labels 
		LET modu_arr_label[idx].serial_code = l_serial_code 
	END FOREACH 

	CALL set_count(idx) 
	OPEN WINDOW I631 with FORM "I631" 
	 CALL windecoration_i("I631") -- albo kd-758 

	LET msgresp = kandoomsg("I",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY modu_arr_label WITHOUT DEFAULTS FROM sr_label.* ATTRIBUTES(UNBUFFERED,INSERT ROW = FALSE, AUTO APPEND = FALSE)

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD part_code 
			LET idx = arr_curr()
			LET scrn = scr_line()
			IF modu_arr_label[idx].part_code IS NOT NULL THEN
				SELECT * INTO l_rec_product.* FROM product 
				WHERE product.part_code = modu_arr_label[idx].part_code 
				AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF STATUS = NOTFOUND THEN 
					ERROR kandoomsg2("I",9010,"") 
					#9010 Product code does NOT exist - Try Window
					NEXT FIELD part_code 
				ELSE 
					SELECT * FROM prodstatus 
					WHERE prodstatus.part_code = modu_arr_label[idx].part_code 
					AND prodstatus.ware_code = modu_rec_warehouse.ware_code 
					AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF STATUS = NOTFOUND THEN 
						ERROR kandoomsg2("I",9185,"") 
						#9185 Must be stocked AT this warehouse
						NEXT FIELD part_code 
					ELSE 
						LET modu_arr_label[idx].desc_text = l_rec_product.desc_text 
						DISPLAY modu_arr_label[idx].desc_text TO sr_label[scrn].desc_text 
						IF modu_arr_label[idx].serial_code IS NULL THEN
							DECLARE c_serialinfo CURSOR FOR
							SELECT serialinfo.serial_code
							FROM serialinfo
							WHERE serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code
							AND serialinfo.part_code = modu_arr_label[idx].part_code
							OPEN c_serialinfo
							FETCH c_serialinfo INTO modu_arr_label[idx].serial_code
							DISPLAY modu_arr_label[idx].serial_code TO sr_label[scrn].serial_code
						END IF
					END IF 
				END IF 
			END IF 

		AFTER FIELD label_num 
			LET idx = arr_curr()
			IF modu_arr_label[idx].label_num < 1 THEN 
				ERROR kandoomsg2("I",9171,"") 
				#9171 AT least one label must be printed
				NEXT FIELD label_num 
			END IF 

	END INPUT 

	CLOSE WINDOW I631

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE
		RETURN l_rec_labelhead.label_code
	END IF 

END FUNCTION
############################################################
# END FUNCTION ISL_rpt_query() 
############################################################

############################################################
# FUNCTION ISL_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION ISL_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE idx SMALLINT
	DEFINE x SMALLINT

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ISL_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT ISL_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = "SELECT * FROM labeldetl ", 
	"WHERE label_code ='",p_where_text CLIPPED, "' ",	
	"AND line_num > ? ", 
	"AND cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"ORDER BY line_num" 

	PREPARE s_labeldetl FROM l_query_text 
	DECLARE c_labeldetl CURSOR FOR s_labeldetl 

	LET modu_blank_line_num = 0 
	LET msgresp=kandoomsg("I",1040,"") 
	#1040 Generating label FOR:
	FOR idx = 1 TO modu_arr_label.getsize() 
		IF modu_arr_label[idx].part_code IS NOT NULL THEN 
			DISPLAY "" at 1,25 
			DISPLAY modu_arr_label[idx].part_code at 1,25 
			FOR x = 1 TO modu_arr_label[idx].label_num 
				#---------------------------------------------------------
				OUTPUT TO REPORT ISL_rpt_list(l_rpt_idx,modu_arr_label[idx].part_code,modu_rec_warehouse.ware_code,modu_arr_label[idx].serial_code) 
				IF NOT rpt_int_flag_handler2("Product: ",modu_arr_label[idx].part_code,"",l_rpt_idx) THEN
					EXIT FOR 
				END IF
				#---------------------------------------------------------
			END FOR 
		ELSE 
			EXIT FOR 
		END IF 
	END FOR 

	#------------------------------------------------------------
	FINISH REPORT ISL_rpt_list
	RETURN rpt_finish("ISL_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION ISL_rpt_process() 
############################################################

############################################################
# FUNCTION format_line(p_part_code,p_ware_code,p_serial_code,p_label_code,p_line_num)
#
# 
############################################################
FUNCTION format_line(p_part_code,p_ware_code,p_serial_code,p_label_code,p_line_num) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_serial_code LIKE serialinfo.serial_code 
	DEFINE p_label_code LIKE labelhead.label_code 
	DEFINE p_line_num LIKE labeldetl.line_num 
	DEFINE l_rec_labeldetl RECORD LIKE labeldetl.* 
	DEFINE l_text LIKE labeldetl.line_text 
	DEFINE l_pos SMALLINT 
	DEFINE l_next_pos SMALLINT
	DEFINE l_end_pos SMALLINT
	DEFINE l_len SMALLINT
	DEFINE l_field LIKE labeldetl.line_text 
	DEFINE r_formatted_line LIKE labeldetl.line_text 

	SELECT * INTO l_rec_labeldetl.* FROM labeldetl 
	WHERE label_code = p_label_code 
	AND line_num = p_line_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_next_pos = 1 
	LET l_end_pos = 1 
	LET l_text = l_rec_labeldetl.line_text 
	LET l_len = length(l_text) 
	FOR l_pos = 1 TO l_len 
		IF l_text[l_pos]="#" THEN 
			LET l_text[l_pos,l_pos]=ascii(27) 
		END IF 
	END FOR 
	WHILE TRUE 
		LET l_len = length(l_text) 
		FOR l_pos = 1 TO l_len 
			IF l_text[l_pos] = "<" THEN 
				LET l_end_pos = l_next_pos + l_pos - 2 
				LET r_formatted_line[l_next_pos, l_end_pos] = l_text[1, (l_pos - 1)] 
				LET l_len = length(l_text) 
				LET l_text = l_text[l_pos, l_len] 
				LET l_next_pos = l_end_pos + 1 
				LET l_pos = 0 
				EXIT FOR 
			END IF 
		END FOR 
		LET l_len = length(l_text) 
		IF l_pos >= l_len THEN 
			LET l_end_pos = l_next_pos + l_len - 1 
			LET r_formatted_line[l_next_pos, l_end_pos] = l_text[1, l_len] 
			EXIT WHILE 
		END IF 
		LET l_len = length(l_text) 
		FOR l_pos = 2 TO l_len 
			IF l_text[l_pos] = ">" THEN 
				LET l_field = l_text[2, (l_pos - 1)] 
				CALL setup_field(p_part_code, p_ware_code, p_serial_code, l_field) 
				RETURNING l_field 
				LET l_len = length(l_field) 
				LET l_end_pos = l_next_pos + l_len - 1 
				IF l_len > 0 THEN 
					LET r_formatted_line[l_next_pos, l_end_pos] = l_field[1, l_len] 
				END IF 
				LET l_len = length(l_text) 
				IF l_pos < l_len THEN 
					LET l_text = l_text[(l_pos + 1), l_len] 
					LET l_pos = 0 
				ELSE 
					LET l_text = NULL 
					EXIT WHILE 
				END IF 
				LET l_next_pos = l_end_pos + 1 
				EXIT FOR 
			ELSE 
				IF l_text[l_pos] = "<" THEN 
					LET l_end_pos = l_next_pos + l_pos - 1 
					LET r_formatted_line[l_next_pos, l_end_pos] = l_text[1, (l_pos - 1)] 
					LET l_len = length(l_text) 
					LET l_text = l_text[l_pos, l_len] 
					LET l_next_pos = l_end_pos + 1 
					EXIT FOR 
				END IF 
			END IF 
		END FOR 
		LET l_len = length(l_text) 
		IF l_pos >= l_len THEN 
			LET l_end_pos = l_next_pos + l_len - 1 
			LET r_formatted_line[l_next_pos, l_end_pos] = l_text[1, l_len] 
			EXIT WHILE 
		END IF 
	END WHILE 

	RETURN r_formatted_line 

END FUNCTION 
############################################################
# END FUNCTION format_line() 
############################################################

############################################################
# FUNCTION setup_field(p_part_code,p_ware_code,p_serial_code,p_field)
#
# 
############################################################
FUNCTION setup_field(p_part_code,p_ware_code,p_serial_code,p_field) 
	DEFINE p_part_code LIKE product.part_code
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_serial_code LIKE serialinfo.serial_code 
	DEFINE p_field LIKE labeldetl.line_text 
	DEFINE l_text LIKE labeldetl.line_text 
	DEFINE l_query_text STRING 
	DEFINE l_pos, l_len SMALLINT 
	DEFINE cmpy_pos SMALLINT 
	DEFINE pr_table CHAR(30)
	DEFINE pr_column CHAR(50) 

	LET pr_table = NULL 
	LET pr_column = NULL 
	LET l_len = length(p_field) 
	FOR l_pos = 1 TO l_len 
		IF p_field[l_pos] = "." THEN 
			LET pr_table = p_field[1, (l_pos - 1)] 
			LET pr_column = p_field[(l_pos + 1), l_len] 
			EXIT FOR 
		END IF 
	END FOR 
	IF pr_table IS NULL 
	OR pr_column IS NULL THEN 
		RETURN p_field 
	END IF 
	IF pr_table != "company" 
	AND pr_table != "warehouse" 
	AND pr_table != "product" 
	AND pr_table != "prodstatus" 
	AND pr_table != "prodgrp" 
	AND pr_table != "maingrp" 
	AND pr_table != "category" 
	AND pr_table != "class" 
	AND pr_table != "serialinfo" THEN 
		RETURN p_field 
	END IF 

	LET l_query_text = "SELECT ", p_field, " FROM company, warehouse, ", 
	"product, prodstatus, ", 
	"prodgrp, maingrp, ", 
	"category, class, serialinfo ", 
	"WHERE company.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND warehouse.cmpy_code = company.cmpy_code ", 
	"AND warehouse.ware_code = '", p_ware_code, "' ", 
	"AND product.cmpy_code = company.cmpy_code ", 
	"AND product.part_code = '", p_part_code, "' ", 
	"AND prodstatus.cmpy_code = company.cmpy_code ", 
	"AND prodstatus.ware_code = warehouse.ware_code ", 
	"AND prodstatus.part_code = product.part_code ", 
	"AND prodgrp.cmpy_code = company.cmpy_code ", 
	"AND prodgrp.prodgrp_code = product.prodgrp_code ", 
	"AND maingrp.cmpy_code = company.cmpy_code ", 
	"AND maingrp.maingrp_code = product.maingrp_code ", 
	"AND category.cmpy_code = company.cmpy_code ", 
	"AND category.cat_code = product.cat_code ", 
	"AND class.cmpy_code = company.cmpy_code ", 
	"AND class.class_code = product.class_code ", 
	"AND serialinfo.cmpy_code = company.cmpy_code ", 
	"AND serialinfo.part_code = product.part_code ", 
	"AND serialinfo.serial_code = '", p_serial_code, "' " 

	PREPARE s_field FROM l_query_text 
	DECLARE c_field CURSOR FOR s_field 

	OPEN c_field 
	FETCH c_field INTO l_text 
	IF STATUS != NOTFOUND THEN 
		RETURN l_text 
	ELSE 
		RETURN p_field 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION setup_field() 
############################################################

############################################################
# REPORT ISL_rpt_list(p_rpt_idx,p_rec_prodstatus)
#
# Report Definition/Layout
############################################################
REPORT ISL_rpt_list(p_rpt_idx,p_part_code,p_ware_code,p_serial_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_serial_code LIKE serialinfo.serial_code
	DEFINE l_rec_labeldetl RECORD LIKE labeldetl.* 
	DEFINE l_formatted_line CHAR(132) 
	DEFINE l_len SMALLINT 

	ORDER EXTERNAL BY p_part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1

	ON EVERY ROW 
		OPEN c_labeldetl USING modu_blank_line_num 
		FOREACH c_labeldetl INTO l_rec_labeldetl.* 
			IF l_rec_labeldetl.line_text IS NULL 
			AND modu_blank_line_num = 0 THEN 
				LET modu_blank_line_num = l_rec_labeldetl.line_num 
			ELSE 
				IF l_rec_labeldetl.line_text IS NOT NULL THEN 
					CALL format_line(p_part_code, 
					p_ware_code, 
					p_serial_code, 
					l_rec_labeldetl.label_code, 
					l_rec_labeldetl.line_num) 
					RETURNING l_formatted_line 
					LET l_len = length(l_formatted_line) 
					IF l_formatted_line[1,1] = " " THEN 
						LET l_formatted_line = l_formatted_line[2,l_len] 
					END IF 
					PRINT l_formatted_line CLIPPED
				END IF 
			END IF 
		END FOREACH 

		AFTER GROUP OF p_part_code
			SKIP 1 LINE

END REPORT
 
############################################################
# END REPORT ISL_rpt_list() 
############################################################