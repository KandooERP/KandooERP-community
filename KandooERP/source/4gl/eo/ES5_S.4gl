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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ES5_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_arparms RECORD LIKE arparms.* 

############################################################
# FUNCTION ES5_S_main()
#
# Order Confirmation Summary
############################################################
FUNCTION ES5_S_main()
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ES5")  

	CALL run_prog("E53","","","","") 
	
--	SELECT * INTO modu_rec_arparms.* FROM arparms 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND parm_code = "1" 

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
			MENU " Order Confirmation summary" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ess","menu-Order_Confirmation-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL ES5_rpt_process(ES5_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "EXPORT" #COMMAND "Run" " Create interface file AND generate report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ES5_rpt_process(ES5_rpt_query())

				ON ACTION "PRINT MANAGER" 					#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY("E",INTERRUPT)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ES5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
--			OPEN WINDOW A190 with FORM "A190" 
--			 CALL windecoration_a("A190") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ES5_rpt_query()) #save where clause in env 
--			CLOSE WINDOW A190 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ES5_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION
############################################################
# END FUNCTION ES5_S_main()
############################################################


############################################################
# FUNCTION ES5_rpt_query()
#
# 
############################################################
FUNCTION ES5_rpt_query() 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_select RECORD 
		file_name STRING, 
		path_name STRING, 
		inv_prev_prnt_ind char(1) 
	END RECORD
	DEFINE l_inv_text char(2000) 
	DEFINE l_time char(8) 

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
	 
	IF l_rec_select.file_name IS NULL THEN #don't understand the error message - file name was hand crafted... 
		ERROR kandoomsg2("E",9258,"") 	#9258  No Filename has been SET up in parameter file.
		RETURN FALSE 
	END IF 

	LET l_rec_select.path_name = l_rec_loadparms.path_text 

	IF NOT is_path_valid(l_rec_select.path_name) THEN 
		CALL fgl_winmessage("ERROR", kandoomsg2("E",9259,""),"ERROR") 	#9259  Invalid Unix pathname SET up in parameter file.
		RETURN FALSE 
	END IF 

	LET l_inv_text = " invoicehead.printed_num<='0'" 
	LET glob_rec_rpt_selector.ref1_text = l_rec_select.path_name 
	LET glob_rec_rpt_selector.ref2_text = l_rec_select.file_name
--	LET glob_rec_rpt_selector.ref3_code = l_rec_select.path_name[1,10] 
--	LET glob_rec_rpt_selector.ref4_code = l_rec_select.path_name[11,20] 
--	LET glob_rec_rpt_selector.ref1_code = l_rec_select.file_name[1,10] 
--	LET glob_rec_rpt_selector.ref2_code = l_rec_select.file_name[11,20] 
	LET glob_rec_rpt_selector.sel_text = l_inv_text
#@debug info - remove after we know what this is	 
CALL fgl_winmessage("ERROR","HuHo: l_inv_text - ERROR . check this out","error")
CALL fgl_winmessage("l_inv_text",l_inv_text,"error")

	RETURN l_inv_text	
--	IF report1(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,0) THEN 
--		RETURN TRUE 
--	ELSE 
--		RETURN FALSE 
--	END IF 
END FUNCTION
############################################################
# END FUNCTION ES5_rpt_query()
############################################################