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
GLOBALS "../pu/R_PU_GLOBALS.4gl" 
GLOBALS "../pu/RS_GROUP_GLOBALS.4gl"
GLOBALS "../pu/RS1_GLOBALS.4gl" 


#  RS1h - MEPIC System Purchase Order PRINT program - FORMAT ind 02


FUNCTION po_print_02(p_cmpy,p_kandoouser_sign_on_code,where_text) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	where_text CHAR(550), 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_save_order_num LIKE purchhead.order_num, 
	query_text STRING, 
	rpt_note2 LIKE rmsreps.report_text, 
	pr_report_started, pr_interrupt_flag SMALLINT 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	LET query_text = "SELECT purchhead.*,", 
	"purchdetl.* ", 
	"FROM purchdetl,", 
	"purchhead ", 
	" WHERE purchhead.cmpy_code='",p_cmpy,"' ", 
	"AND purchdetl.cmpy_code='",p_cmpy,"' ", 
	"AND purchhead.order_num=purchdetl.order_num ", 
	"AND ",where_text clipped, " ", 
	"ORDER BY purchdetl.order_num, purchdetl.line_num " 
	PREPARE s_purchdetl FROM query_text 
	DECLARE c_purchdetl CURSOR with HOLD FOR s_purchdetl 
	--   OPEN WINDOW w1 AT 15,15 with 1 rows, 40 columns  -- albo  KD-756
	--      ATTRIBUTE(border)
	LET pr_save_order_num = 0 
	LET pr_report_started = false 
	LET pr_interrupt_flag = false 
	FOREACH c_purchdetl INTO pr_purchhead.*, 
		pr_purchdetl.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			#8002 Do you wish TO quit (Y/N)?
			IF kandoomsg("U",8002,"") = 'Y' THEN 
				LET pr_interrupt_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
		IF pr_save_order_num != pr_purchhead.order_num THEN 
			LET pr_save_order_num = pr_purchhead.order_num 
			DISPLAY "" at 1,10 
			DISPLAY " Purchase Order: ", pr_save_order_num at 1,10 

			IF pr_purchhead.printed_flag != 'Y' THEN 
				WHENEVER ERROR CONTINUE ## printed_flag UPDATE NOT important 
				UPDATE purchhead 
				SET printed_flag = 'Y' 
				WHERE cmpy_code = pr_purchhead.cmpy_code 
				AND vend_code = pr_purchhead.vend_code 
				AND order_num = pr_purchhead.order_num 
				WHENEVER ERROR stop 
			END IF 
			# New PO number may mean new RMS file, depending on flag
			IF pr_purchtype.rms_flag = 'N' THEN 
				IF pr_report_started THEN 

					#------------------------------------------------------------
					FINISH REPORT RS1_rpt_list_02
					CALL rpt_finish("RS1_rpt_list_02")
					#------------------------------------------------------------	 

				END IF 
				LET rpt_note2 = "Purchase Order ", 
				pr_purchdetl.order_num USING "<<<<<<<<" clipped, " ", 
				pr_purchtype.desc_text clipped 
				LET pr_report_started = false 
			END IF 
			IF NOT pr_report_started THEN 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("RS1-02","RS1_rpt_list_02","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	

				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("RS1_rpt_list_02"),NULL, "pr_purchtype.desc_text")
					
				START REPORT RS1_rpt_list_02 TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------				

				LET pr_report_started = true 
			END IF 
		END IF 
		#---------------------------------------------------------		
		OUTPUT TO REPORT RS1_rpt_list_02(l_rpt_idx,
		pr_purchhead.*,pr_purchdetl.*)    
		#---------------------------------------------------------				

	END FOREACH 
	IF pr_report_started THEN 

		#------------------------------------------------------------
		FINISH REPORT RS1_rpt_list_02
		CALL rpt_finish("RS1_rpt_list_02")
		#------------------------------------------------------------	 

	END IF 
	--   CLOSE WINDOW w1  -- albo  KD-756
	RETURN pr_output, pr_interrupt_flag 
END FUNCTION 


REPORT RS1_rpt_list_02(pr_purchhead,pr_purchdetl) 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_map_gps_coordinates LIKE warehouse.map_gps_coordinates, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_order_time CHAR(10), 
	pr_count INTEGER, 
	pr_bar_code_text LIKE product.bar_code_text 

	OUTPUT 
#	PAGE length 1 
#	top margin 0 
#	bottom margin 0 
#	left margin 0 
	ORDER external BY pr_purchdetl.order_num,	pr_purchdetl.line_num
	 
	FORMAT 

		BEFORE GROUP OF pr_purchdetl.order_num 
			LET pr_order_time = time 
			LET pr_count = 0 
			LET pr_map_gps_coordinates = NULL 
			SELECT map_gps_coordinates INTO pr_map_gps_coordinates 
			FROM warehouse 
			WHERE cmpy_code = pr_purchhead.cmpy_code 
			AND ware_code = pr_purchhead.ware_code 
			## RECORD type H - Header record
			PRINT COLUMN 01, "H", # RECORD type 
			COLUMN 02, pr_map_gps_coordinates[1,5], # store number 
			COLUMN 07, "W", # ORDER status 
			COLUMN 48, pr_purchhead.order_date USING "yyyymmdd", # ORDER DATE 
			COLUMN 56, pr_order_time[1,2], pr_order_time[4,5], # ORDER time 
			COLUMN 71, pr_purchhead.order_num USING "&&&&&&&&&&&&&&&"; 
			# Order Number
			##    ## purchhead.order_text used as Promotion Identifier
			IF pr_purchhead.order_text IS NULL OR pr_purchhead.order_text = " " THEN 
				## RECORD type 1 - Order RECORD only
				PRINT COLUMN 106, "1"; # ORDER type 
			ELSE 
				## RECORD type 4 - Promotions record
				PRINT COLUMN 106, "4"; # ORDER type 
			END IF 
			PRINT COLUMN 107, "N", # tax exempt flag 
			COLUMN 126, pr_purchhead.order_text[1,8], # promotion id 
			COLUMN 176, "02", #static value 
			COLUMN 199, ascii(13) # cr 

		ON EVERY ROW 
			LET pr_bar_code_text = NULL 
			SELECT bar_code_text INTO pr_bar_code_text 
			FROM product 
			WHERE part_code = pr_purchdetl.ref_text 
			AND cmpy_code = pr_purchdetl.cmpy_code 
			INITIALIZE pr_poaudit.* TO NULL 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code,pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 
			LET pr_count = pr_count + 1 
			## RECORD type P - Line Item record
			PRINT COLUMN 01, "P", # RECORD type 
			COLUMN 02, pr_bar_code_text[1,13], # apn 
			COLUMN 15, pr_poaudit.order_qty USING "&&&&&", # ORDER qty 
			COLUMN 20, "A", # line type 
			COLUMN 110, pr_poaudit.ext_cost_amt USING "&&&&&&.&&", # cost 
			COLUMN 199, ascii(13) # cr 

		AFTER GROUP OF pr_purchdetl.order_num 
			## RECORD type T - Trailer record
			PRINT COLUMN 01, "T", # RECORD type 
			COLUMN 02, pr_map_gps_coordinates[1,5], # store number 
			COLUMN 54, pr_count USING "&&&&&", # type p records 
			COLUMN 59, "00000", # type q records 
			COLUMN 64, "00000", # type m records 
			COLUMN 69, pr_count USING "&&&&&&" , # total records 
			COLUMN 199, ascii(13) # cr 

		ON LAST ROW 
			LET rpt_pageno=pageno 
			LET rpt_width=47 
			LET rpt_length=lineno 
END REPORT 
