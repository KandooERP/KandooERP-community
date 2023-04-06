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
# Binning List REPORT FOR goods receipts in shipments
# Called either as a stand alone REPORT OR FROM goods receipting
# which passes the receipt text
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../lc/L_LC_GLOBALS.4gl"
GLOBALS "../lc/LA_GROUP_GLOBALS.4gl" 
GLOBALS "../lc/LA2_GLOBALS.4gl" 
GLOBALS 
--	DEFINE 
--	rpt_note LIKE rmsreps.report_text, 
--	rpt_wid LIKE rmsreps.report_width_num, 
--	rpt_length LIKE rmsreps.page_length_num, 
--	rpt_pageno LIKE rmsreps.page_num, 
--	pr_output CHAR(20), 
--	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
--	pr_company RECORD LIKE company.*, 
	DEFINE query_text STRING 
	DEFINE where_part STRING
	--rpt_date LIKE rmsreps.report_date, 
	--rpt_time CHAR(8), 
	--line1, line2 CHAR(120), 
	DEFINE ret_code INTEGER 
	DEFINE i SMALLINT
	--DEFINE offset1, offset2 SMALLINT
	--rpt_head SMALLINT, 
	--col, col2 SMALLINT, 
	--cmpy_head CHAR(130), 
	DEFINE passed_receipt_text LIKE shiprec.goods_receipt_text 
	DEFINE pr_temp RECORD 
		dest LIKE printcodes.print_code 
	END RECORD
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
	DEFINE destination LIKE printcodes.print_code 
END GLOBALS 

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("LA2") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	IF num_args() > 1 THEN 
		ERROR "Binning list REPORT NOT printed" 
		EXIT program 
	ELSE 
		IF num_args() = 0 THEN 
			OPEN WINDOW l143 with FORM "L143" 
			CALL windecoration_l("L143") -- albo kd-763 

			MENU " Shipment Receipt Report" 
				ON ACTION "WEB-HELP" -- albo kd-375 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Run" " SELECT criteria AND PRINT REPORT" 
--					LET rpt_head = true 
					IF LA2_rpt_query() THEN 
						NEXT option "Print Manager" 
--						LET rpt_note = NULL 
					END IF 

				ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS",'','','','') 

				COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					EXIT MENU 
	
			END MENU 
			CLOSE WINDOW l143 
	
		ELSE 
			LET passed_receipt_text = arg_val(1) 
			IF LA2_rpt_query() THEN 
				#CALL print_rep() 
				EXIT program 
			ELSE 
				EXIT program 
			END IF 
		END IF 
	END IF 
END MAIN 
###########################################################################
# MAIN
#
#
###########################################################################


###########################################################################
# FUNCTION LA2_rpt_query() 
#
#
###########################################################################
FUNCTION LA2_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	pr_tempdoc RECORD 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		goods_receipt_text LIKE shiphead.goods_receipt_text, 
		receipt_date LIKE shiprec.recpt_date, 
		line_num LIKE shipdetl.line_num, 
		part_code LIKE shipdetl.part_code, 
		rec_qty LIKE shiprec.trans_qty, 
		vend_code LIKE shiphead.vend_code, 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE shipdetl.desc_text, 
		ship_type_ind LIKE shiphead.ship_type_ind, 
		ship_rec_qty LIKE shipdetl.ship_rec_qty, 
		bin1_text LIKE prodstatus.bin1_text 
	END RECORD 

	WHILE true # SET up loop 
		IF num_args() = 0 THEN 
			MESSAGE" Enter Selection Criteria - ESC TO Continue"			attribute(yellow) 
			CONSTRUCT BY NAME where_part ON 
			shiphead.vend_code, 
			shiphead.ship_code, 
			shiphead.ship_type_code, 
			shiphead.eta_curr_date, 
			shiphead.vessel_text, 
			shiphead.discharge_text, 
			shiphead.ware_code, 
			shiphead.ship_status_code, 
			shiprec.goods_receipt_text, 
			shiprec.recpt_date, 
			shipdetl.part_code, 
			shipdetl.desc_text, 
			shiphead.ship_type_ind 

				ON ACTION "WEB-HELP" -- albo kd-375 
					CALL onlinehelp(getmoduleid(),null) 

			END CONSTRUCT 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		ELSE 
			LET where_part = "shiprec.goods_receipt_text = \"", 
			passed_receipt_text, "\" " 
		END IF 
		

		#------------------------------------------------------------
		#User pressed CANCEL = p_where_text IS NULL
		IF (where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
			LET int_flag = false 
			LET quit_flag = false
	
			RETURN FALSE
		END IF
	
		LET l_rpt_idx = rpt_start(getmoduleid(),"LA2_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT LA2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
		#------------------------------------------------------------

		LET query_text = "SELECT ", 
		" shiphead.ship_code, ", 
		" shiphead.ship_type_code, ", 
		" shiprec.goods_receipt_text, ", 
		" shiprec.recpt_date, ", 
		" shipdetl.line_num, ", 
		" shipdetl.part_code, ", 
		" shiprec.trans_qty, ", 
		" shiphead.vend_code, ", 
		" shiphead.ware_code, ", 
		" shipdetl.desc_text, ", 
		" shiphead.ship_type_ind, ", 
		" shipdetl.ship_rec_qty ", 
		" FROM shiphead, shipdetl, shiprec ", 
		" WHERE shiphead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND shiprec.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND shiprec.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND shiphead.ship_code = shipdetl.ship_code ", 
		" AND shiphead.ship_code = shiprec.ship_code ", 
		" AND shipdetl.line_num = shiprec.line_num ", 
		" AND ", where_part clipped, 
		" ORDER BY shiprec.goods_receipt_text, ", 
		" shiphead.ship_code, shipdetl.line_num " 
		PREPARE s_invoice FROM query_text 
		DECLARE c_invoice CURSOR FOR s_invoice 
		{
		      OPEN WINDOW w1_LA2 AT 19,16 with 2 rows,46 columns     -- albo  KD-763
		         ATTRIBUTE(border)
		}
		DISPLAY " Reporting on Shipment..." at 1,1 
		DISPLAY " Receipt...." at 2,1 
		FOREACH c_invoice INTO pr_tempdoc.* 
			#DISPLAY pr_tempdoc.ship_code at 1,25 
			#DISPLAY pr_tempdoc.goods_receipt_text at 2,25 

			#---------------------------------------------------------
			OUTPUT TO REPORT LA2_rpt_list(l_rpt_idx,
			pr_tempdoc.*) 
			#---------------------------------------------------------

		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT LA2_rpt_list
		CALL rpt_finish("LA2_rpt_list")
		#------------------------------------------------------------
		

		EXIT WHILE 
		
	END WHILE 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# FUNCTION LA2_rpt_query() 
#
#
###########################################################################


###########################################################################
# FUNCTION LA2_rpt_query() 
#
#
###########################################################################
REPORT LA2_rpt_list(p_rpt_idx,pr_tempdoc)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_tempdoc RECORD 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		goods_receipt_text LIKE shiphead.goods_receipt_text, 
		receipt_date LIKE shiprec.recpt_date, 
		line_num LIKE shipdetl.line_num, 
		part_code LIKE shipdetl.part_code, 
		rec_qty LIKE shiprec.trans_qty, 
		vend_code LIKE shiphead.vend_code, 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE shipdetl.desc_text, 
		ship_type_ind LIKE shiphead.ship_type_ind, 
		ship_rec_qty LIKE shipdetl.ship_rec_qty, 
		bin1_text LIKE prodstatus.bin1_text 
	END RECORD, 
	pr_period RECORD LIKE period.*, 
	pr_vend_name LIKE vendor.name_text, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_picked_qty LIKE prodstatus.onhand_qty, 
	s, len, pr_inv_count, pr_inv_line SMALLINT 

	OUTPUT 
	left margin 0 
	ORDER external BY pr_tempdoc.goods_receipt_text, 
	pr_tempdoc.ship_code, pr_tempdoc.line_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 6, "Line", 
			COLUMN 12, "Product", 
			COLUMN 63, "Receipt", 
			COLUMN 72, "Balance" 
			PRINT COLUMN 5, "Number", 
			COLUMN 13, "Code", 
			COLUMN 29, "Description", 
			COLUMN 62, "Quantity" 

	PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_tempdoc.ship_code 
			SKIP 1 LINES 
			CASE 
				WHEN pr_tempdoc.ship_type_ind = 1 OR 
					pr_tempdoc.ship_type_ind = 2 
					LET pr_vend_name = " " 
					SELECT name_text 
					INTO pr_vend_name 
					FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = pr_tempdoc.vend_code 
					PRINT COLUMN 1, "Receipt Number: ", 
					COLUMN 17, pr_tempdoc.goods_receipt_text, 
					COLUMN 28, pr_tempdoc.receipt_date USING "DD/MM/YY", 
					COLUMN 38, "Shipment: ", 
					COLUMN 49, pr_tempdoc.ship_code clipped, "/", 
					pr_tempdoc.ship_type_code 
					PRINT COLUMN 9, "Vendor: ", 
					COLUMN 17, pr_tempdoc.vend_code, 
					COLUMN 28, pr_vend_name 
				WHEN pr_tempdoc.ship_type_ind = 3 
					LET pr_vend_name = " " 
					SELECT name_text 
					INTO pr_vend_name 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_tempdoc.vend_code 
					PRINT COLUMN 1, "Receipt Number: ", 
					COLUMN 17, pr_tempdoc.goods_receipt_text, 
					COLUMN 28, pr_tempdoc.receipt_date USING "DD/MM/YY", 
					COLUMN 38, "Shipment: ", 
					COLUMN 49, pr_tempdoc.ship_code clipped, "/", 
					pr_tempdoc.ship_type_code 
					PRINT COLUMN 9, "Customer: ", 
					COLUMN 17, pr_tempdoc.vend_code, 
					COLUMN 28, pr_vend_name 
			END CASE 
			SKIP 1 LINES 
		ON EVERY ROW 
			IF pr_tempdoc.part_code IS NOT NULL THEN 
				SELECT * 
				INTO pr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_tempdoc.part_code 
				AND ware_code = pr_tempdoc.ware_code 
				IF num_args() > 0 THEN 
					SELECT sum(picked_qty) 
					INTO pr_picked_qty 
					FROM orderdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND orderdetl.part_code = pr_tempdoc.part_code 
					AND orderdetl.ware_code = pr_tempdoc.ware_code 
					GROUP BY cmpy_code, part_code, ware_code 
				ELSE 
					INITIALIZE pr_picked_qty TO NULL 
				END IF 
			ELSE 
				INITIALIZE pr_prodstatus.* TO NULL 
			END IF 
			PRINT COLUMN 5, pr_tempdoc.line_num USING "##&", 
			COLUMN 11, pr_tempdoc.part_code, 
			COLUMN 29, pr_tempdoc.desc_text, 
			COLUMN 59, pr_tempdoc.rec_qty USING "-------&.&&", 
			COLUMN 70, pr_prodstatus.onhand_qty - 
			pr_picked_qty 
			+ pr_tempdoc.ship_rec_qty 
			USING "-------&.&&" 
			IF pr_tempdoc.part_code IS NOT NULL THEN 
				PRINT COLUMN 20 , "Location: ", 
				COLUMN 30, pr_prodstatus.bin1_text, 
				COLUMN 46, pr_prodstatus.bin2_text, 
				COLUMN 62, pr_prodstatus.bin3_text 
			END IF 

		ON LAST ROW 
--			IF num_args() = 0 THEN 
				SKIP 5 LINES 
{
				PRINT COLUMN 10, "Report used the following selection criteria" 
				SKIP 2 LINES 
				PRINT COLUMN 10, "WHERE:-" 
				SKIP 1 LINES 
				LET len = length (where_part) 
				FOR s = 1 TO 1421 step 60 
					IF len > s THEN 
						PRINT COLUMN 10, "|", where_part [s, s + 59], "|" 
					ELSE 
						LET s = 32000 
					END IF 
				END FOR 
				# the last line doesnt have 60 characters of where_part TO display
				IF len > 1481 THEN 
					PRINT COLUMN 10, "|", where_part [1481, 1500], "|" 
				END IF 
				PRINT COLUMN 50, "***** END OF REPORT LA2 *****" 
			END IF 
}
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]


END REPORT 
{
!!! Escape Squences in lib_report is going to be implemented by Eric !!!
FUNCTION print_rep() 

	DEFINE 
	idx SMALLINT, 
	pr_report_code INTEGER, 
	pr_printcodes RECORD LIKE printcodes.*, 
	l_rec_rmsreps RECORD LIKE rmsreps.*, 
	pr_smparms RECORD LIKE smparms.*, 
	runner CHAR(200), 
	pr_print_cmd CHAR(300), 
	pr_del_cmd CHAR(100), 
	err_message CHAR(50), 
	ans CHAR(1), 
	pr_comp CHAR(1), 
	file_name, 
	pr_cmd CHAR(200), 
	file_tmp1, file_tmp2 CHAR(25), 
	pr_file_status SMALLINT, 
	ret_code, start_line, end_line INTEGER, 
	norm_on, 
	comp_on CHAR(100) 
	--thirty_four SMALLINT 

	SELECT * INTO pr_smparms.* 
	FROM smparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	--LET thirty_four = 34 

	LET pr_smparms.print_text = get_print(glob_rec_kandoouser.cmpy_code, pr_smparms.print_text) 
	SELECT * INTO pr_printcodes.* 
	FROM printcodes 
	WHERE print_code = pr_smparms.print_text 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("U",9042,"") 
		#U9042 "An error has occured during printing"
	END IF 

	SELECT * 
	INTO l_rec_rmsreps.* 
	FROM rmsreps 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND report_code = pr_report_code 
	LET file_name = pr_output 
	LET file_tmp1 = file_name clipped,".tmp1" 
	LET file_tmp2 = file_name clipped,".tmp2" 
	IF l_rec_rmsreps.report_width_num > pr_printcodes.width_num THEN 
		LET pr_comp = "Y" 
	ELSE 
		LET pr_comp = "N" 
	END IF 
	IF pr_comp = "N" THEN 
		LET pr_cmd = "F=",file_name clipped, 
		";C=1", 
		";L=",l_rec_rmsreps.page_length_num USING "<<<<<", 
		";W=",l_rec_rmsreps.report_width_num USING "<<<<<", 
		";",pr_printcodes.print_text clipped," 2>>",trim(get_settings_logFile()), 
		"; STATUS=$? ", 
		" ; EXIT $STATUS " 
		LET pr_del_cmd = "rm ",file_name," " 
	ELSE 
		LET comp_on = ascii ASCII_QUOTATION_MARK, 
		ascii pr_printcodes.compress_1, 
		ascii pr_printcodes.compress_2, 
		ascii pr_printcodes.compress_3, 
		ascii pr_printcodes.compress_4, 
		ascii pr_printcodes.compress_5, 
		ascii pr_printcodes.compress_6, 
		ascii pr_printcodes.compress_7, 
		ascii pr_printcodes.compress_8, 
		ascii pr_printcodes.compress_9, 
		ascii pr_printcodes.compress_10, 
		ascii pr_printcodes.compress_11, 
		ascii pr_printcodes.compress_12, 
		ascii pr_printcodes.compress_13, 
		ascii pr_printcodes.compress_14, 
		ascii pr_printcodes.compress_15, 
		ascii pr_printcodes.compress_16, 
		ascii pr_printcodes.compress_17, 
		ascii pr_printcodes.compress_18, 
		ascii pr_printcodes.compress_19, 
		ascii pr_printcodes.compress_20, ascii ASCII_QUOTATION_MARK 
		LET norm_on = ascii ASCII_QUOTATION_MARK, 
		ascii pr_printcodes.normal_1, 
		ascii pr_printcodes.normal_2, 
		ascii pr_printcodes.normal_3, 
		ascii pr_printcodes.normal_4, 
		ascii pr_printcodes.normal_5, 
		ascii pr_printcodes.normal_6, 
		ascii pr_printcodes.normal_7, 
		ascii pr_printcodes.normal_8, 
		ascii pr_printcodes.normal_9, 
		ascii pr_printcodes.normal_10, ascii ASCII_QUOTATION_MARK 
		LET runner = "echo ",comp_on clipped," > ",file_tmp2 clipped, 
		"\;cat ", file_name clipped, " >> ",file_tmp2 clipped, 
		"\;echo ", norm_on clipped, " >> ",file_tmp2 clipped, 
		" 2>>",trim(get_settings_logFile()) 
		RUN runner 
		LET pr_cmd = "F=",file_tmp2 clipped, 
		" ;C=1", 
		" ;L=",l_rec_rmsreps.page_length_num USING "<<<<<", 
		" ;W=",l_rec_rmsreps.report_width_num USING "<<<<<", 
		" ;",pr_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()), 
		" ; STATUS=$? " 
		LET pr_del_cmd = "rm ",file_tmp2, " " 

	END IF 
	RUN pr_cmd 
	RETURNING ret_code 
	IF ret_code THEN 
		LET msgresp=kandoomsg("U",9042,"") 
		#U9042 "An error has occured during printing"
		RUN pr_del_cmd 
	ELSE 
		DELETE FROM rmsreps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND report_code = pr_report_code 
		RUN pr_del_cmd 
	END IF 
END FUNCTION 
}



FUNCTION get_print(p_cmpy, pr_default) 
	DEFINE 
	pr_default LIKE printcodes.print_code, 
	p_cmpy LIKE company.cmpy_code 

	LET int_flag = 0 
	LET quit_flag = 0 
	LET pr_temp.dest = pr_default 
	OPEN WINDOW wu500 with FORM "U500" 
	CALL winDecoration_u("U500") -- albo kd-763 

	INPUT BY NAME pr_temp.* WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield(dest) THEN 
				LET pr_temp.dest = show_print(p_cmpy) 
				NEXT FIELD dest 
			END IF 

		AFTER FIELD dest 
			SELECT * INTO pr_printcodes.* FROM printcodes 
			WHERE print_code = pr_temp.dest 

			IF status = (notfound) THEN 
				LET pr_temp.dest = NULL 
				ERROR "Printer/terminal definition NOT found" 
				NEXT FIELD dest 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		LET pr_temp.dest = pr_default 
	END IF 
	LET destination = pr_temp.dest 
	CLOSE WINDOW wu500 
	RETURN destination 
END FUNCTION 
