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
############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# MAIN
#
# RS1 - Enter selection criteria
#     - Determines which REPORT TO CALL using the purchase type on the purchase ORDER
#######################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("RS1") -- albo 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	SELECT printcodes.* INTO pr_printcodes.* 
	FROM reqparms, printcodes 
	WHERE key_code = '1' 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND print_code = po_print_text 

	IF sqlca.sqlcode = notfound THEN 
		INITIALIZE pr_printcodes.* TO NULL 
	END IF 
	IF num_args() = 1 THEN 
		CALL po_allocate(arg_val(1)) 
		EXIT program 
	END IF 
	OPEN WINDOW R155 with FORM "R155" 
	CALL  windecoration_r("R155") 

	DISPLAY BY NAME pr_printcodes.print_code 

	MENU " PO Print" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","RS1","menu-po_print-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REPORT" --COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
			IF pr_printcodes.print_code IS NULL THEN 
				LET msgresp = kandoomsg("P",9536,"") 	#9536 " No OUTPUT device selected"
				NEXT option "Device" 
			END IF 
			IF select_po() THEN 
				CALL po_allocate(where_text) 
				LET rpt_pageno = 0 
				NEXT option "Print Manager" 
			END IF 
			
		COMMAND "Device" " SELECT device TO PRINT purchase ORDER" 
			LET pr_temp_text = get_print( glob_rec_kandoouser.cmpy_code, pr_printcodes.print_code ) 
			IF pr_temp_text IS NOT NULL THEN 
				SELECT * INTO pr_printcodes.* FROM printcodes 
				WHERE print_code = pr_temp_text 
				DISPLAY BY NAME pr_printcodes.print_code 

				NEXT option "Report" 
			END IF 

		ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW R155 
END MAIN 


FUNCTION select_po() 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue.
	CONSTRUCT BY NAME where_text ON purchhead.order_num, 
	purchhead.vend_code, 
	purchhead.ware_code, 
	purchhead.order_date, 
	purchhead.purchtype_code, 
	purchhead.order_text, 
	purchhead.enter_code, 
	purchhead.entry_date, 
	purchhead.due_date, 
	purchhead.year_num, 
	purchhead.period_num, 
	purchhead.curr_code, 
	purchhead.printed_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RS1","construct-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION po_allocate(where_text) 
	DEFINE 
	pr_purchtype_code LIKE purchtype.purchtype_code, 
	err_message CHAR(50), 
	err_cnt, pr_interrupt SMALLINT, 
	query_text CHAR(800), 
	where_text CHAR(500), 
	where_text2 CHAR(550) 

	# FOR each type of purchase ORDER matching the selection criteria
	# CALL the appropriate PRINT routine according TO the FORMAT indicator
	# FOR that type

	LET msgresp = kandoomsg("U",1002,"") 
	#1002 "Searching Database; Please Wait "
	LET query_text = "SELECT unique purchtype_code ", 
	"FROM purchhead ", 
	" WHERE purchhead.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",where_text clipped 
	PREPARE s_purchtype FROM query_text 
	DECLARE c_purchtype CURSOR with HOLD FOR s_purchtype 
	--   OPEN WINDOW w1_RS1 AT 12,15 with 1 rows, 40 columns  -- albo  KD-756
	--      ATTRIBUTE(border)
	DISPLAY "Purchase Order Type: " at 1,2 
	LET err_cnt = 0 
	FOREACH c_purchtype INTO pr_purchtype_code 
		DISPLAY pr_purchtype_code at 1,23 

		SELECT * INTO pr_purchtype.* FROM purchtype 
		WHERE purchtype_code = pr_purchtype_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET err_cnt = err_cnt + 1 
			LET err_message = "Purchase Order Type NOT found - ", pr_purchtype_code 
			CALL errorlog(err_message) 
			CONTINUE FOREACH 
		END IF 
		LET where_text2 = where_text clipped, 
		" AND purchhead.purchtype_code = \'",pr_purchtype_code, "\'" 
		# Note: Print routines RETURN the OUTPUT file details TO enable automatic
		#       PRINT scheduling in a future enhancement.  Further refinement IS
		#       required - note also that each routine may create one rms file
		#       per ORDER depending on the rms flag
		CASE pr_purchtype.format_ind 
			WHEN "00" ## standard po FORMAT 
				CALL po_print_00(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text2) 
				RETURNING pr_output, pr_interrupt 
			WHEN "01" ## gun401 stationery FORMAT 
				CALL po_print_01(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text2) 
				RETURNING pr_output, pr_interrupt 
			WHEN "02" ## gun401 mepic FORMAT 
				CALL po_print_02(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text2) 
				RETURNING pr_output, pr_interrupt 
			WHEN "03" ## bri401 stationery FORMAT 
				CALL po_print_03(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text2) 
				RETURNING pr_output, pr_interrupt 
			WHEN "04" ## aus301 stationery FORMAT 
				CALL po_print_04(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text2) 
				RETURNING pr_output, pr_interrupt 
			WHEN "05" ## mir401 stationery FORMAT 
				CALL po_print_05(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text2) 
				RETURNING pr_output, pr_interrupt 
			WHEN "06" ## sel401 stationery FORMAT 
				CALL po_print_06(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text2) 
				RETURNING pr_output, pr_interrupt 
			WHEN "07" ## cen401 stationery FORMAT 
				CALL po_print_07(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text2) 
				RETURNING pr_output, pr_interrupt 
			OTHERWISE 
				LET err_cnt = err_cnt + 1 
				LET err_message = "Unknown FORMAT ",pr_purchtype.format_ind, 
				" FOR Purchase Order Type ", pr_purchtype_code 
				CALL errorlog(err_message) 
		END CASE 
		IF pr_interrupt THEN ## user interrupted PRINT via del KEY 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	--   CLOSE WINDOW w1_RS1  -- albo  KD-756
	IF err_cnt > 0 THEN 
		LET msgresp = kandoomsg('R',7001,'') 
		#7001 Unable TO allocate FORMAT FOR some Purchase Orders - refer to get_settings_logFile()"
	END IF 
END FUNCTION 
