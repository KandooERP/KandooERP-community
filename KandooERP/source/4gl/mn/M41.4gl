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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M4_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M41_GLOBALS.4gl"

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	pr_output CHAR(60), 
	pr_output1 CHAR(60), 
	fv_query_text CHAR(2000), 
	fv_where_part CHAR(2000), 

	rpt_pageno SMALLINT, 
	rpt_pageno1 SMALLINT, 
	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	pr_kandooreport1 RECORD LIKE kandooreport.*, 
	pr_menunames RECORD LIKE menunames.*, 
	pr_mnparms RECORD LIKE mnparms.* 

END GLOBALS 
###########################################################################
# MAIN
#
# Picking List Report
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("M41") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * 
	INTO pr_mnparms.* 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--    AND    parm_code = 1  -- albo
	AND param_code = 1 -- albo 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7500, "") 	# prompt "Manufacturing parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	OPEN WINDOW w1_m181 with FORM "M181" 
	CALL  windecoration_m("M181") -- albo kd-762 

	CALL kandoomenu("M", 160) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # REPORT 
			IF report_main() THEN 
				NEXT option pr_menunames.cmd2_code # PRINT 
			ELSE 
				NEXT option pr_menunames.cmd4_code # EXIT 
			END IF 

		ON ACTION "Print Manager"			#command pr_menunames.cmd2_code pr_menunames.cmd2_text # Print
			CALL run_prog("URS", "", "", "", "") 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text # EXIT 
			EXIT MENU 

		COMMAND KEY(interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW w1_m181 

END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION report_main()
#
#
###########################################################################
FUNCTION report_main() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	fv_com_cnt SMALLINT, 
	fv_mn_query_text CHAR(2000), 
	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_shopordhead2 RECORD LIKE shopordhead.*, 
	fr_shoporddetl2 RECORD LIKE shoporddetl.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 

	fr_picklist RECORD 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		work_centre_code LIKE shoporddetl.work_centre_code, 
		bin1_text LIKE prodstatus.bin1_text, 
		part_code LIKE shoporddetl.part_code, 
		required_qty LIKE shoporddetl.required_qty, 
		issued_qty LIKE shoporddetl.issued_qty, 
		uom_code LIKE shoporddetl.uom_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		ware_code LIKE prodstatus.ware_code 
	END RECORD 


	LET msgresp = kandoomsg("M", 1500, "") # MESSAGE "Enter selection criteria - ESC TO Accept, DEL TO Exit"

	CONSTRUCT BY NAME fv_where_part 
	ON shopordhead.shop_order_num, shopordhead.suffix_num, cust_code, 
	shopordhead.part_code, status_ind, shopordhead.start_date, 
	shopordhead.end_date, work_centre_code 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET msgresp = kandoomsg("M",9555,"") 
		# ERROR "Query aborted"
		RETURN false 
	END IF 

	LET msgresp = kandoomsg("M", 1532, "") # MESSAGE "Searching database - Please wait"

	###
	### Picking List Report
	###

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (fv_where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	LET l_rpt_idx = rpt_start("M41-PICKING","M41_rpt_list_picking",fv_where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M41_rpt_list_picking TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET fv_where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET fv_query_text = "SELECT shopordhead.shop_order_num, ", 
	"shopordhead.suffix_num, work_centre_code, ", 
	"bin1_text, shoporddetl.part_code, ", 
	"sum(required_qty), sum(issued_qty), ", 
	"shoporddetl.uom_code, onhand_qty, ", 
	"reserved_qty, back_qty, ware_code ", 
	"FROM shopordhead, shoporddetl, prodstatus ", 
	"WHERE shopordhead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND shopordhead.cmpy_code = ", 
	" shoporddetl.cmpy_code ", 
	"AND shopordhead.shop_order_num = ", 
	" shoporddetl.shop_order_num ", 
	"AND shopordhead.suffix_num = ", 
	" shoporddetl.suffix_num ", 
	"AND shoporddetl.cmpy_code = ", 
	" prodstatus.cmpy_code ", 
	"AND shoporddetl.part_code = ", 
	" prodstatus.part_code ", 
	"AND shoporddetl.issue_ware_code = ", 
	" prodstatus.ware_code ", 
	"AND shopordhead.status_ind != 'C' ", 
	"AND shopordhead.order_type_ind != 'F' ", 
	"AND shoporddetl.type_ind = 'C' ", 
	"AND ", fv_where_part clipped, " ", 
	"group by shopordhead.shop_order_num, ", 
	"shopordhead.suffix_num, work_centre_code, ", 
	"bin1_text, shoporddetl.part_code, ", 
	"shoporddetl.uom_code, onhand_qty, ", 
	"reserved_qty, back_qty, ware_code ", 
	"ORDER BY shopordhead.shop_order_num, ", 
	"shopordhead.suffix_num, work_centre_code, ", 
	"bin1_text, shoporddetl.part_code, ", 
	"shoporddetl.uom_code" 

	PREPARE statement1 FROM fv_query_text 
	DECLARE c_picklist CURSOR FOR statement1 
 

	FOREACH c_picklist INTO fr_picklist.* 
		SELECT * 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fr_picklist.part_code 
		AND part_type_ind = "P" 

		IF status = notfound THEN
			#---------------------------------------------------------
			OUTPUT TO REPORT M41_rpt_list_picking(l_rpt_idx,		 
			fr_picklist.*) 
			#---------------------------------------------------------
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT M41_rpt_list_picking
	CALL rpt_finish("M41_rpt_list_picking")
	#------------------------------------------------------------

	###
	### Packet List Report
	###

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (fv_where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	LET l_rpt_idx = rpt_start("M41-PACKET","M41_rpt_list_packet_order",fv_where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M41_rpt_list_packet_order TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET fv_where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET fv_mn_query_text = "SELECT * ", 
	"FROM shopordhead, shoporddetl ", 
	"WHERE shopordhead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND shopordhead.cmpy_code = ", 
	"shoporddetl.cmpy_code ", 
	"AND shopordhead.shop_order_num = ", 
	"shoporddetl.shop_order_num ", 
	"AND shopordhead.suffix_num = ", 
	"shoporddetl.suffix_num ", 
	"AND shopordhead.status_ind != 'C' ", 
	"AND shopordhead.order_type_ind != 'F' ", 
	"AND ", fv_where_part clipped, " ", 
	"ORDER BY shopordhead.shop_order_num, ", 
	"shopordhead.suffix_num" 

	PREPARE statement2 FROM fv_mn_query_text 
	DECLARE ts_cur2 CURSOR FOR statement2 

	FOREACH ts_cur2 INTO fr_shopordhead2.*, fr_shoporddetl2.* 
		IF fr_shoporddetl2.type_ind matches "[WUSI]" THEN 
			SELECT count(*) 
			INTO fv_com_cnt 
			FROM wipreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = fr_shoporddetl2.shop_order_num 
			AND suffix_num = fr_shoporddetl2.suffix_num 
			AND sequence_num = fr_shoporddetl2.sequence_num 
			AND work_centre_code = fr_shoporddetl2.work_centre_code 
			AND status_ind = "C" 

			IF fv_com_cnt = 0 THEN 
				#---------------------------------------------------------
				OUTPUT TO REPORT M41_rpt_list_packet_order(l_rpt_idx,		 
				fr_shoporddetl2.*) 
				#---------------------------------------------------------
			
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT M41_rpt_list_packet_order
	CALL rpt_finish("MM41_rpt_list_packet_order")
	#------------------------------------------------------------

END FUNCTION 
###########################################################################
# END FUNCTION report_main()
###########################################################################


###########################################################################
# REPORT M41_rpt_list_picking(p_rpt_idx,rr_picklist)
#
#
###########################################################################
REPORT M41_rpt_list_picking(p_rpt_idx,rr_picklist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	rr_prodstatus RECORD LIKE prodstatus.*, 
	rr_shopordhead RECORD LIKE shopordhead.*, 
	rr_product RECORD LIKE product.*, 
	rr_picklist RECORD 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		work_centre_code LIKE shoporddetl.work_centre_code, 
		bin1_text LIKE prodstatus.bin1_text, 
		part_code LIKE shoporddetl.part_code, 
		required_qty LIKE shoporddetl.required_qty, 
		issued_qty LIKE shoporddetl.issued_qty, 
		uom_code LIKE shoporddetl.uom_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		ware_code LIKE prodstatus.ware_code 
	END RECORD, 

	rv_work_centre_desc_text LIKE workcentre.desc_text, 
	rv_product_desc_text LIKE product.desc_text, 
	rv_balance LIKE shoporddetl.required_qty, 
	rv_note_code LIKE notes.note_code, 
	rv_note_text LIKE notes.note_text, 
	rv_name_text LIKE customer.name_text, 
	rv_cal_av_flag LIKE opparms.cal_available_flag, 
	rv_avail_qty LIKE prodstatus.onhand_qty 

--	rv_rpt_line1 CHAR(132), 
--	rv_rpt_line2 CHAR(132), 
--	rv_rpt_line3 CHAR(132), 
--	rv_rpt_line4 CHAR(132) 

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			# SELECT the flag TO determine available stock FROM opparms
			SELECT cal_available_flag INTO rv_cal_av_flag 
			FROM opparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_num = "1" 
			IF status = notfound THEN 
				LET rv_cal_av_flag = "N" 
			END IF 

			SELECT * 
			INTO rr_shopordhead.* 
			FROM shopordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = rr_picklist.shop_order_num 
			AND suffix_num = rr_picklist.suffix_num 

			IF rr_shopordhead.status_ind = "H" THEN 
				LET rr_shopordhead.status_ind = "R" 
				LET rr_shopordhead.release_date = today 
				LET rr_shopordhead.actual_start_date = today 
				LET rr_shopordhead.last_change_date = today 
				LET rr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET rr_shopordhead.last_program_text = "M41" 

				UPDATE shopordhead 
				SET * = rr_shopordhead.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = rr_picklist.shop_order_num 
				AND suffix_num = rr_picklist.suffix_num 
			END IF 

			PRINT COLUMN 1, "Shop Order Number : ", 
			COLUMN 22, rr_picklist.shop_order_num, 
			COLUMN 45, "Suffix Number: ", 
			COLUMN 61, rr_picklist.suffix_num, 
			COLUMN 78, "Order Type/No :", 
			COLUMN 94, rr_shopordhead.order_type_ind, 
			COLUMN 97, rr_shopordhead.sales_order_num 

			IF rr_picklist.work_centre_code IS NOT NULL THEN 
				SELECT desc_text 
				INTO rv_work_centre_desc_text 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = rr_picklist.work_centre_code 
			ELSE 
				LET rv_work_centre_desc_text = "" 
			END IF 

			IF rr_shopordhead.cust_code IS NOT NULL THEN 
				SELECT name_text 
				INTO rv_name_text 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = rr_shopordhead.cust_code 
			END IF 

			PRINT COLUMN 1, "Work Centre :", 
			COLUMN 23, rr_picklist.work_centre_code, 
			COLUMN 45, rv_work_centre_desc_text, 
			COLUMN 78, "Customer :", 
			COLUMN 94, rv_name_text 

			SELECT desc_text 
			INTO rv_product_desc_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rr_shopordhead.part_code 

			PRINT COLUMN 1, "Product Code : ", 
			COLUMN 23, rr_shopordhead.part_code, 
			COLUMN 45, rv_product_desc_text 

			IF pr_mnparms.ref4_ind matches "[1234]" 
			AND rr_shopordhead.user4_text IS NOT NULL THEN 
				LET rv_note_text = NULL 

				IF rr_shopordhead.user4_text[1,3] = "###" THEN 
					LET rv_note_code = rr_shopordhead.user4_text[4,15] 

					SELECT note_text 
					INTO rv_note_text 
					FROM notes 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND note_code = rv_note_code 
					AND note_num = 1 
				END IF 

				PRINT COLUMN 1, pr_mnparms.ref4_text, ": ", 
				rr_shopordhead.user4_text, " ", rv_note_text 
			ELSE 
				PRINT 
			END IF 

			PRINT COLUMN 1, "Quantity Required : ", 
			COLUMN 22, rr_shopordhead.order_qty, 
			COLUMN 45, "UOM:", 
			COLUMN 50, rr_shopordhead.uom_code, 
			COLUMN 78, "Status : Released" 

			PRINT COLUMN 1, "Start Date :", 
			COLUMN 23, rr_shopordhead.start_date, 
			COLUMN 78, "Release Date :", 
			COLUMN 94, rr_shopordhead.release_date, 
			COLUMN 109, "Due Date : ", 
			COLUMN 119, rr_shopordhead.end_date 

			PRINT "--------------------------------------------------", 
			"-------------------------------------------------", 
			"--------------------------------" 
			#####
			# PRINT COLUMN HEADINGS
			#####

			PRINT COLUMN 1 , "Bin Location", 
			COLUMN 17 , "Product", 
			COLUMN 33 , "Description", 
			COLUMN 64 , "--------- Q U A N T I T Y ----------", 
			COLUMN 105, "Stock Available", 
			COLUMN 124, "Quantity" 

			PRINT COLUMN 66 , "Required", 
			COLUMN 79 , "Issued", 
			COLUMN 89 , "Balance", 
			COLUMN 97 , "UOM", 
			COLUMN 105, "On Hand", 
			COLUMN 115, "W/Hse", 
			COLUMN 126, "Picked" 

			PRINT "--------------------------------------------------", 
			"-------------------------------------------------", 
			"--------------------------------" 

		BEFORE GROUP OF rr_picklist.shop_order_num 

			SKIP TO top OF PAGE 

		BEFORE GROUP OF rr_picklist.suffix_num 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF rr_picklist.work_centre_code 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			LET rv_balance = rr_picklist.required_qty - rr_picklist.issued_qty 

			IF rv_balance < 0 THEN 
				LET rv_balance = 0 
			END IF 

			IF rv_balance > 0 THEN 
				SELECT * 
				INTO rr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = rr_picklist.part_code 

				SELECT * 
				INTO rr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = rr_picklist.part_code 
				AND ware_code = rr_picklist.ware_code 

				# Calculate available quantity
				IF rv_cal_av_flag = "N" THEN 
					LET rv_avail_qty = rr_picklist.onhand_qty - 
					rr_picklist.reserved_qty - 
					rr_picklist.back_qty + 
					rv_balance 
				ELSE 
					LET rv_avail_qty = rr_picklist.onhand_qty - 
					rr_picklist.reserved_qty + 
					rv_balance 
				END IF 
				IF rv_avail_qty IS NULL THEN 
					LET rv_avail_qty = 0 
				END IF 

				PRINT 
				PRINT COLUMN 1 , rr_picklist.bin1_text, 
				COLUMN 17 , rr_picklist.part_code, 
				COLUMN 33 , rr_product.desc_text, 
				COLUMN 64 , rr_picklist.required_qty USING "#######.##", 
				COLUMN 75 , rr_picklist.issued_qty USING "#######.##", 
				COLUMN 86 , rv_balance USING "#######.##", 
				COLUMN 97 , rr_picklist.uom_code, 
				COLUMN 101, rv_avail_qty USING "-------#.##", 
				COLUMN 115, rr_picklist.ware_code, 
				COLUMN 121, "___________" 

				PRINT COLUMN 101, rr_picklist.onhand_qty USING "-------#.##" 
				IF rv_balance > rr_picklist.onhand_qty THEN 
					DECLARE ware_cur CURSOR FOR 
					SELECT * 
					INTO rr_prodstatus.* 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = rr_picklist.part_code 
					AND ware_code != rr_picklist.ware_code 

					FOREACH ware_cur INTO rr_prodstatus.* 
						PRINT 
						PRINT COLUMN 101, 
						rr_prodstatus.onhand_qty USING "-------#.##", 
						COLUMN 115, rr_prodstatus.ware_code, 
						COLUMN 121, "___________" 
					END FOREACH 
				END IF 
			END IF 

		ON LAST ROW 
			PRINT 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

			LET rpt_pageno = pageno 

END REPORT 
###########################################################################
# END REPORT M41_rpt_list_picking(p_rpt_idx,rr_picklist)
###########################################################################


###########################################################################
# REPORT M41_rpt_list_packet_order(p_rpt_idx,rr_shoporddetl) 
#
#
###########################################################################
REPORT M41_rpt_list_packet_order(p_rpt_idx,rr_shoporddetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE rr_prodstatus RECORD LIKE prodstatus.* 
	DEFINE rr_shopordhead RECORD LIKE shopordhead.* 
	DEFINE rr_shoporddetl RECORD LIKE shoporddetl.* 
	DEFINE rr_notes RECORD LIKE notes.* 
	DEFINE rr_workcentre RECORD LIKE workcentre.* 

	DEFINE rv_temp_note_code LIKE notes.note_code 
	DEFINE rv_work_centre_desc_text LIKE workcentre.desc_text 
	DEFINE rv_completed_qty LIKE shoporddetl.receipted_qty 
	DEFINE rv_required_qty LIKE shopordhead.order_qty 
	DEFINE rv_completed_time LIKE wipreceipt.receipt_qty 
	DEFINE rv_required_time LIKE wipreceipt.receipt_qty 
	DEFINE rv_product_desc_text LIKE product.desc_text 
	DEFINE rv_balance LIKE shoporddetl.required_qty 
	DEFINE rv_status_desc_text CHAR(9) 
	DEFINE rv_desc_text CHAR(10) 
--	rv_rpt_line1 CHAR(132), 
--	rv_rpt_line2 CHAR(132), 
--	rv_rpt_line3 CHAR(132), 
--	rv_rpt_line4 CHAR(132) 


	OUTPUT 

	FORMAT 
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			 

			SELECT * 
			INTO rr_shopordhead.* 
			FROM shopordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = rr_shoporddetl.shop_order_num 
			AND suffix_num = rr_shoporddetl.suffix_num 

			IF rr_shopordhead.status_ind = "H" THEN 
				LET rr_shopordhead.status_ind = "R" 
				LET rr_shopordhead.release_date = today 
				LET rr_shopordhead.actual_start_date = today 
				LET rr_shopordhead.last_change_date = today 
				LET rr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET rr_shopordhead.last_program_text = "M41" 

				UPDATE shopordhead 
				SET * = rr_shopordhead.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = rr_shoporddetl.shop_order_num 
				AND suffix_num = rr_shoporddetl.suffix_num 
			END IF 

			PRINT COLUMN 1, "Shop Order Number: ", 
			COLUMN 19, rr_shoporddetl.shop_order_num, 
			COLUMN 36, "Suffix Number: ", 
			COLUMN 52, rr_shoporddetl.suffix_num, 
			COLUMN 75, "Customer : ", 
			COLUMN 93, fr_shopordhead.cust_code 

			SELECT desc_text 
			INTO rv_work_centre_desc_text 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 

			SELECT desc_text 
			INTO rv_product_desc_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rr_shopordhead.part_code 

			PRINT COLUMN 1, "Product Code : ", 
			COLUMN 20, rr_shopordhead.part_code, 
			COLUMN 32, rv_product_desc_text, 
			COLUMN 75, "Order Type/No : ", 
			COLUMN 97, rr_shopordhead.order_type_ind 

			IF pr_mnparms.ref4_ind matches "[1234]" 
			AND rr_shopordhead.user4_text IS NOT NULL THEN 
				LET rr_notes.note_text = NULL 

				IF rr_shopordhead.user4_text[1,3] = "###" THEN 
					LET rv_temp_note_code = rr_shopordhead.user4_text[4,15] 

					SELECT * 
					INTO rr_notes.* 
					FROM notes 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND note_code = rv_temp_note_code 
					AND note_num = 1 
				END IF 

				PRINT COLUMN 1, pr_mnparms.ref4_text, ": ", 
				rr_shopordhead.user4_text, " ", rr_notes.note_text 
			ELSE 
				PRINT 
			END IF 

			LET rv_status_desc_text = "Released" 

			PRINT COLUMN 1, "Quantity Required: ", 
			COLUMN 20, rr_shopordhead.order_qty, 
			COLUMN 35, "UOM :", 
			COLUMN 41, rr_shopordhead.uom_code, 
			COLUMN 75, "Status : ", 
			COLUMN 93, rv_status_desc_text 

			PRINT COLUMN 1, "Start Date : ", 
			COLUMN 20, rr_shopordhead.start_date, 
			COLUMN 75, "Release Date : ", 
			COLUMN 93, rr_shopordhead.release_date, 
			COLUMN 106, "Due Date : ", 
			COLUMN 119, rr_shopordhead.end_date 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			#####
			# PRINT COLUMN HEADINGS
			#####

			PRINT COLUMN 1, "Type", 
			COLUMN 10, "Work Centre", 
			COLUMN 22, "Description", 
			COLUMN 55, "--------- Q U A N T I T Y ----------", 
			COLUMN 99, "------------ T I M E ------------" 

			PRINT COLUMN 58, "Required", 
			COLUMN 74, "Completed", 
			COLUMN 99, "Required UOM", 
			COLUMN 115,"Completed" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF rr_shoporddetl.shop_order_num 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF rr_shoporddetl.suffix_num 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			CASE 
				WHEN rr_shoporddetl.type_ind = "I" 
					IF rr_shoporddetl.desc_text[1,1] = "#" THEN 
						LET rv_temp_note_code = rr_shoporddetl.desc_text[4,15] 
					END IF 

					DECLARE rp_notes_cur CURSOR FOR 
					SELECT * 
					FROM notes 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND note_code = rv_temp_note_code 

					FOREACH rp_notes_cur INTO rr_notes.* 
						PRINT COLUMN 1, "Instruct:", 
						COLUMN 10, rr_notes.note_text 
					END FOREACH 

				WHEN rr_shoporddetl.type_ind = "W" 
					SELECT * 
					INTO rr_workcentre.* 
					FROM workcentre 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = rr_shoporddetl.work_centre_code 

					LET rv_required_qty = rr_shopordhead.order_qty 
					* rr_shoporddetl.oper_factor_amt 
					LET rv_completed_qty = rr_shoporddetl.receipted_qty 
					+ rr_shoporddetl.rejected_qty 

					IF rr_workcentre.processing_ind = "Q" THEN 
						LET rv_required_time = (rv_required_qty 
						* rr_shoporddetl.oper_factor_amt) 
						/ rr_workcentre.time_qty 
					ELSE 
						LET rv_required_time = (rv_required_qty 
						* rr_shoporddetl.oper_factor_amt) 
						* rr_workcentre.time_qty 
					END IF 

					IF rr_workcentre.count_centre_ind matches "[TBO]" THEN 
						SELECT sum(receipt_qty) 
						INTO rv_completed_time 
						FROM wipreceipt 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND work_centre_code = rr_shoporddetl.work_centre_code 
						AND shop_order_num = rr_shoporddetl.shop_order_num 
						AND suffix_num = rr_shoporddetl.suffix_num 
						AND part_code = rr_shopordhead.part_code 
					END IF 

					IF rv_completed_time IS NULL THEN 
						LET rv_completed_time = 0 
					END IF 

					PRINT COLUMN 1, "Process:", 
					COLUMN 10, rr_workcentre.work_centre_code, 
					COLUMN 22, rr_workcentre.desc_text, 
					COLUMN 55, rv_required_qty USING "########.##", 
					COLUMN 72, rv_completed_qty USING "########.##", 
					COLUMN 84, "_______", 
					COLUMN 93, rv_required_time, 
					COLUMN 109, rr_workcentre.time_unit_ind, 
					COLUMN 113, rv_completed_time USING "########.##", 
					COLUMN 125, "_______" 

				WHEN rr_shoporddetl.type_ind matches "[SU]" 
					IF rr_shoporddetl.type_ind = "S" THEN 
						LET rv_desc_text = "Cost" 
					ELSE 
						LET rv_desc_text = "Setup" 
					END IF 

					PRINT COLUMN 1, rv_desc_text, 
					COLUMN 10, rr_shoporddetl.work_centre_code, 
					COLUMN 22, rr_shoporddetl.desc_text, 
					COLUMN 55, rr_shoporddetl.required_qty 
					USING "########.##", 
					COLUMN 72, rr_shoporddetl.issued_qty USING "########.##" 

					IF rr_shoporddetl.desc_text[1,1] = "#" THEN 
						LET rv_temp_note_code = rr_shoporddetl.desc_text[4,15] 

						DECLARE rp_notes_cur1 CURSOR FOR 
						SELECT * 
						FROM notes 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND note_code = rv_temp_note_code 

						FOREACH rp_notes_cur1 INTO rr_notes.* 
							PRINT COLUMN 1, "Notes: ", 
							COLUMN 10, rr_notes.note_text 
						END FOREACH 
					END IF 

			END CASE 
			PRINT 

		ON LAST ROW 
			PRINT 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]


			LET rpt_pageno = pageno 

END REPORT 
###########################################################################
# END REPORT M41_rpt_list_packet_order(p_rpt_idx,rr_shoporddetl) 
###########################################################################