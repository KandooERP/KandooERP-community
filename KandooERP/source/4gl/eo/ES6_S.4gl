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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ES6_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################


###########################################################################
# FUNCTION ES6_S_main()
#
# Order Confirmation Summary
###########################################################################
FUNCTION ES6_S_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ES6") 

	IF fgl_find_table("t_invoicedetl") THEN
		DELETE FROM t_invoicedetl
	ELSE
		CREATE temp TABLE t_invoicedetl(
			cust_code char(8), 
			part_code char(15), 
			ship_date DATE, 
			ship_qty decimal(16,4)) with no LOG 
	END IF
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW E451 with FORM "E451" 
			 CALL windecoration_e("E451") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
 
			MENU " Order Confirmation summary" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ES6","menu-Order_Confirmation-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL ES5_rpt_process(ES6_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
					
				ON ACTION "REPORT" #COMMAND "Run" " Enter selection criteria AND generate report" 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL ES5_rpt_process(ES6_rpt_query())

				ON ACTION "PRINT MANAGER" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 

				ON ACTION "CANCEL" #COMMAND KEY("E",INTERRUPT)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			
			CLOSE WINDOW E451 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ES5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E451 with FORM "E451" 
			 CALL windecoration_e("E451") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ES6_rpt_query()) #save where clause in env 
			CLOSE WINDOW E451 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ES5_rpt_process(get_url_sel_text())
	END CASE 	

END FUNCTION 
###########################################################################
# END FUNCTION ES6_S_main()
###########################################################################


###########################################################################
# FUNCTION ES6_rpt_query()
#
# Order Confirmation Summary
###########################################################################
FUNCTION ES6_rpt_query() 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_select RECORD 
		file_name STRING, 
		path_name STRING, 
		inv_start_num LIKE invoicehead.inv_num, 
		inv_last_num LIKE invoicehead.inv_num, 
		inv_start_date LIKE invoicehead.inv_date, 
		inv_last_date LIKE invoicehead.inv_date, 
		inv_start_cust LIKE invoicehead.cust_code, 
		inv_last_cust LIKE invoicehead.cust_code, 
		inv_start_load LIKE invoicehead.purchase_code, 
		inv_last_load LIKE invoicehead.purchase_code, 
		inv_prev_prnt_ind char(1) 
	END RECORD
	DEFINE l_inv_text STRING 
	DEFINE l_time nchar(8) 

	CLEAR FORM 

	MESSAGE kandoomsg2("U",1001,"") #1001 Enter selection criteria;  OK TO Continue

	DECLARE c_loadparms cursor FOR 
	SELECT * FROM loadparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = 'EO' 
	AND format_ind = "2" 
	OPEN c_loadparms 
	FETCH c_loadparms INTO l_rec_loadparms.* 

	LET l_time = time 
	LET l_time = l_time[1,2],l_time[4,5],l_time[7,8] 
	LET l_rec_select.file_name = "MXR", today USING "yyyymmdd", l_time clipped 
	LET l_rec_select.path_name = l_rec_loadparms.path_text 
	LET l_rec_select.inv_start_num = NULL 
	LET l_rec_select.inv_last_num = NULL 
	LET l_rec_select.inv_start_date = NULL 
	LET l_rec_select.inv_last_date = NULL 
	LET l_rec_select.inv_start_cust = NULL 
	LET l_rec_select.inv_last_cust = NULL 
	LET l_rec_select.inv_start_load = NULL 
	LET l_rec_select.inv_last_load = NULL 
	LET l_rec_select.inv_prev_prnt_ind = "N" 

	INPUT BY NAME l_rec_select.* WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ES6","input-l_rec_select-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD file_name 
			IF l_rec_select.file_name IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered
				NEXT FIELD file_name 
			END IF 

		AFTER FIELD path_name 
			IF l_rec_select.path_name IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered
				NEXT FIELD path_name 
			ELSE 
				IF NOT is_path_valid(l_rec_select.path_name) THEN 
					NEXT FIELD path_name 
				END IF 
			END IF 

		AFTER INPUT 
			IF l_rec_select.inv_start_num > l_rec_select.inv_last_num THEN 
				ERROR kandoomsg2("E",9176,"") 	#9176 Beginning document IS greater than ending document
				NEXT FIELD inv_start_num 
			END IF 

	END INPUT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF
	 
	LET l_inv_text = NULL 
	LET l_inv_text = " 1=1 "
	 
	IF l_rec_select.inv_start_num IS NOT NULL THEN 
		LET l_inv_text = l_inv_text clipped," ", 
		"AND invoicehead.inv_num>='", 
		l_rec_select.inv_start_num USING "&<<<<<<<","'" 
	END IF 
	IF l_rec_select.inv_last_num IS NOT NULL THEN 
		LET l_inv_text = l_inv_text clipped," ", 
		"AND invoicehead.inv_num<='", 
		l_rec_select.inv_last_num USING "&<<<<<<<","'" 
	END IF 
	IF l_rec_select.inv_start_date IS NOT NULL THEN 
		LET l_inv_text = l_inv_text clipped," ", 
		"AND invoicehead.inv_date>='",l_rec_select.inv_start_date,"'" 
	END IF 
	IF l_rec_select.inv_last_date IS NOT NULL THEN 
		LET l_inv_text = l_inv_text clipped," ", 
		"AND invoicehead.inv_date<='",l_rec_select.inv_last_date,"'" 
	END IF 
	IF l_rec_select.inv_start_cust IS NOT NULL THEN 
		LET l_inv_text = l_inv_text clipped," ", 
		"AND invoicehead.cust_code>='",l_rec_select.inv_start_cust,"'" 
	END IF 
	IF l_rec_select.inv_last_cust IS NOT NULL THEN 
		LET l_inv_text = l_inv_text clipped," ", 
		"AND invoicehead.cust_code<='",l_rec_select.inv_last_cust,"'" 
	END IF 
	IF l_rec_select.inv_start_load IS NOT NULL THEN 
		LET l_inv_text = l_inv_text clipped," ", 
		"AND invoicehead.purchase_code>='",l_rec_select.inv_start_load,"'" 
	END IF 
	IF l_rec_select.inv_last_load IS NOT NULL THEN 
		LET l_inv_text = l_inv_text clipped," ", 
		"AND invoicehead.purchase_code<='",l_rec_select.inv_last_load,"'" 
	END IF 
	IF l_rec_select.inv_prev_prnt_ind = "N" THEN 
		LET l_inv_text = l_inv_text clipped," AND invoicehead.printed_num<='0'" 
	END IF

	LET glob_rec_rpt_selector.ref1_text = l_rec_select.path_name 
	LET glob_rec_rpt_selector.ref2_text = l_rec_select.file_name
	LET glob_rec_rpt_selector.sel_text = l_inv_text

	RETURN TRUE
END FUNCTION
###########################################################################
# END FUNCTION ES6_rpt_query()
###########################################################################