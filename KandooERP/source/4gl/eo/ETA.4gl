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
GLOBALS "../eo/ET_GROUP_GLOBALS.4gl"
GLOBALS "../eo/ETA_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statparms RECORD LIKE statparms.* 
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_temp_text STRING 
###########################################################################
# FUNCTION ETA_main()
#
# ETA - Salesperson Contribution Report
###########################################################################
FUNCTION ETA_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ETA") 

	SELECT * INTO modu_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = RPT_OP_MENU 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW E287 with FORM "E287" 
			 CALL windecoration_e("E287")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY getmenuitemlabel(NULL) TO header_text 
		
		 
			MENU " Salesperson contribution" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ETA","menu-Salesperson-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL ETA_rpt_process(ETA_rpt_query())
		
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
							
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 												
					
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ETA_rpt_process(ETA_rpt_query())
		
				ON ACTION "PRINT MANAGER" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 			
		 
			END MENU 
			CLOSE WINDOW E287 

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ETA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E287 with FORM "E287" 
			 CALL windecoration_e("E287") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ETA_rpt_query()) #save where clause in env 
			CLOSE WINDOW E287 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ETA_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 
###########################################################################
# END FUNCTION ETA_main()
###########################################################################


###########################################################################
# FUNCTION ETA_rpt_query() 
#
#
###########################################################################
FUNCTION ETA_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg("E",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue

	CONSTRUCT BY NAME l_where_text ON sale_code, 
	name_text, 
	sale_type_ind, 
	terri_code, 
	mgr_code, 
	city_text, 
	state_code, 
	post_code, 
	country_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ETA","construct-sale_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		LET glob_rec_rpt_selector.ref1_num = modu_rec_statint.year_num
		LET glob_rec_rpt_selector.ref1_code = modu_rec_statint.type_code
		LET glob_rec_rpt_selector.ref1_date = modu_rec_statint.start_date
		LET glob_rec_rpt_selector.ref1_ind = modu_rec_statint.dist_flag

		LET glob_rec_rpt_selector.ref2_num = modu_rec_statint.int_num
		LET glob_rec_rpt_selector.ref2_date = modu_rec_statint.end_date
		LET glob_rec_rpt_selector.ref2_code = modu_rec_statint.int_text
		LET glob_rec_rpt_selector.ref2_ind = modu_rec_statint.updreq_flag
				
		RETURN l_where_text 
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION ETA_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION ETA_enter_year() 
#
#
###########################################################################
FUNCTION ETA_enter_year() 
	LET modu_rec_statint.year_num = modu_rec_statparms.year_num 
	LET modu_rec_statint.int_num = modu_rec_statparms.mth_num 
	
	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue
	INPUT BY NAME 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ETA","input-modu_rec_statint-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "LOOKUP" infield(int_text) 
				LET modu_temp_text = "year_num = '",modu_rec_statint.year_num,"' ", 
				"AND type_code = '",modu_rec_statparms.mth_type_code,"'" 
				LET modu_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,modu_temp_text) 
				IF modu_temp_text IS NOT NULL THEN 
					LET modu_rec_statint.int_num = modu_temp_text 
					NEXT FIELD int_text 
				END IF 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET modu_rec_statint.year_num = modu_rec_statint.year_num - 1 
			NEXT FIELD year_num 

		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET modu_rec_statint.year_num = modu_rec_statint.year_num + 1 
			NEXT FIELD year_num 

		BEFORE FIELD year_num 
			SELECT * INTO modu_rec_statint.* 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statparms.mth_type_code 
			AND int_num = modu_rec_statint.int_num 
			
			DISPLAY BY NAME 
				modu_rec_statint.int_text, 
				modu_rec_statint.start_date, 
				modu_rec_statint.end_date 

		AFTER FIELD year_num 
			IF modu_rec_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 			#9210 Year number must be entered
				LET modu_rec_statint.year_num = modu_rec_statparms.year_num 
				NEXT FIELD year_num 
			END IF 

		BEFORE FIELD int_text 
			SELECT int_text INTO modu_rec_statint.int_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statparms.mth_type_code 
			AND int_num = modu_rec_statint.int_num 

		AFTER FIELD int_text 
			IF modu_rec_statint.int_text IS NULL THEN 
				ERROR kandoomsg2("E",9222,"") 			#9222 Interval must be entered"
				NEXT FIELD int_text 
			ELSE 
				DECLARE c_interval cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_rec_statint.year_num 
				AND type_code = modu_rec_statparms.mth_type_code 
				AND int_text = modu_rec_statint.int_text 
				OPEN c_interval 
				FETCH c_interval INTO modu_rec_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") 			#9223 Interval does NOT exist - Try Window"
					LET modu_rec_statint.int_num = modu_rec_statparms.mth_num 
					NEXT FIELD int_text 
				END IF 
			END IF 
			DISPLAY BY NAME 
				modu_rec_statint.start_date, 
				modu_rec_statint.end_date 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ETA_enter_year() 
###########################################################################


###########################################################################
# FUNCTION ETA_rpt_process(p_where_text) 
#
#
###########################################################################
FUNCTION ETA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING

	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

	DEFINE l_rec_salesperson RECORD LIKE salesperson.*
	DEFINE l_rec_cur_statsper RECORD LIKE statsper.*
	DEFINE l_rec_ytd_statsper RECORD LIKE statsper.*
	--DEFINE l_year_num LIKE statint.year_num
	DEFINE l_int_num LIKE statint.int_num


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF
	
	LET l_rpt_idx = rpt_start(getmoduleid(),"ETA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ETA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------	
	#get additional rms_reps values for query
	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ETA_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ETA_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ETA_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ETA_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ETA_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ETA_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ETA_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ETA_rpt_list")].ref2_ind
	#------------------------------------------------------------	


	LET l_query_text = "SELECT * FROM salesperson ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ETA_rpt_list")].sel_text clipped," ",
	"ORDER BY 1,2" 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson
	 
	LET l_query_text = "SELECT * FROM statsper ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND sale_code = ? ", 
	"AND year_num = ? ", 
	"AND type_code = '",modu_rec_statparms.mth_type_code,"' ", 
	"AND int_num between ? AND ? ", 
	"ORDER BY 1,3" 
	PREPARE s_statsper FROM l_query_text 
	DECLARE c_statsper cursor FOR s_statsper
	 
	--MESSAGE kandoomsg2("E",1045,"")	#1045 Reporting on Salesperson..
	FOREACH c_salesperson INTO l_rec_salesperson.* 
		DISPLAY "" at 1,30 
		DISPLAY l_rec_salesperson.name_text at 1,30 

		#
		# The following section IS coded this way TO cater FOR salespersons
		# with no statistics in current period but have YTD
		#
		OPEN c_statsper USING l_rec_salesperson.sale_code, 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_num, 
		modu_rec_statint.int_num 
		FOREACH c_statsper INTO l_rec_cur_statsper.* 
			LET l_rec_ytd_statsper.* = l_rec_cur_statsper.* 
			LET l_rec_ytd_statsper.grs_inv_amt = 0 
			LET l_rec_ytd_statsper.grs_cred_amt = 0 
			LET l_rec_ytd_statsper.grs_offer_amt = 0 
			LET l_rec_ytd_statsper.grs_amt = 0 
			LET l_rec_ytd_statsper.net_inv_amt = 0 
			LET l_rec_ytd_statsper.net_cred_amt = 0 
			LET l_rec_ytd_statsper.net_offer_amt = 0 
			LET l_rec_ytd_statsper.net_amt = 0 
			LET l_rec_ytd_statsper.cost_amt = 0 
			LET l_rec_ytd_statsper.comm_amt = 0

			#---------------------------------------------------------
			OUTPUT TO REPORT ETA_rpt_list(l_rpt_idx,
			l_rec_cur_statsper.*,
			l_rec_ytd_statsper.*)
			IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
		 
		END FOREACH 

		LET l_int_num = 1 
		OPEN c_statsper USING 
			l_rec_salesperson.sale_code, 
			modu_rec_statint.year_num, 
			l_int_num, 
			modu_rec_statint.int_num 

		FOREACH c_statsper INTO l_rec_ytd_statsper.* 
			LET l_rec_cur_statsper.* = l_rec_ytd_statsper.* 
			LET l_rec_cur_statsper.grs_inv_amt = 0 
			LET l_rec_cur_statsper.grs_cred_amt = 0 
			LET l_rec_cur_statsper.grs_offer_amt = 0 
			LET l_rec_cur_statsper.grs_amt = 0 
			LET l_rec_cur_statsper.net_inv_amt = 0 
			LET l_rec_cur_statsper.net_cred_amt = 0 
			LET l_rec_cur_statsper.net_offer_amt = 0 
			LET l_rec_cur_statsper.net_amt = 0 
			LET l_rec_cur_statsper.cost_amt = 0 
			LET l_rec_cur_statsper.comm_amt = 0

			#---------------------------------------------------------
			OUTPUT TO REPORT ETA_rpt_list(l_rpt_idx,
			l_rec_cur_statsper.*,
			l_rec_ytd_statsper.*)
			IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	

		END FOREACH 

	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT ETA_rpt_list
	CALL rpt_finish("ETA_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF
END FUNCTION 
###########################################################################
# END FUNCTION ETA_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# REPORT ETA_rpt_list(p_rpt_idx,p_rec_cur_statsper, p_rec_ytd_statsper) 
#
#
###########################################################################
REPORT ETA_rpt_list(p_rpt_idx,p_rec_cur_statsper, p_rec_ytd_statsper) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cur_statsper RECORD LIKE statsper.*
	DEFINE p_rec_ytd_statsper RECORD LIKE statsper.*
	DEFINE l_rec_statsper RECORD LIKE statsper.*
	DEFINE l_s_rec_statsper RECORD LIKE statsper.*
	--pa_line array[4] OF char(80), 
	DEFINE l_name_text LIKE salesperson.name_text
	DEFINE l_bdgt_amt LIKE stattarget.bdgt_amt
	DEFINE l_s_bdgt_amt LIKE stattarget.bdgt_amt

	DEFINE l_disc_net FLOAT
	DEFINE l_disc_off FLOAT
	DEFINE l_disc_trn FLOAT

	DEFINE l_s_disc_net FLOAT
	DEFINE l_s_disc_off FLOAT
	DEFINE l_s_disc_trn FLOAT

	DEFINE l_achieve_net FLOAT
	DEFINE l_costs_per FLOAT
	DEFINE l_comm_per FLOAT
	DEFINE l_contr_per FLOAT

	DEFINE l_s_achieve_net FLOAT
	DEFINE l_s_costs_per FLOAT
	DEFINE l_s_comm_per FLOAT
	DEFINE l_s_contr_per FLOAT
	 
	DEFINE x,i,j SMALLINT 

	OUTPUT 

	ORDER BY p_rec_cur_statsper.cmpy_code, p_rec_cur_statsper.sale_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text	
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
		AFTER GROUP OF p_rec_cur_statsper.sale_code 
			SKIP TO top OF PAGE 
			# pr = curr, ps = ytd OTHERWISE will have over 50 group sum occ'ces
			LET l_rec_statsper.grs_amt = GROUP sum(p_rec_cur_statsper.grs_amt) 
			LET l_rec_statsper.grs_offer_amt = GROUP sum(p_rec_cur_statsper.grs_offer_amt) 
			LET l_rec_statsper.grs_inv_amt = GROUP sum(p_rec_cur_statsper.grs_inv_amt) 
			LET l_rec_statsper.grs_cred_amt = GROUP sum(p_rec_cur_statsper.grs_cred_amt) 
			IF l_rec_statsper.grs_offer_amt < 0 THEN 
				LET l_rec_statsper.grs_cred_amt = l_rec_statsper.grs_cred_amt - l_rec_statsper.grs_offer_amt 
			END IF 
			IF l_rec_statsper.grs_offer_amt > 0 THEN 
				LET l_rec_statsper.grs_inv_amt = l_rec_statsper.grs_inv_amt - l_rec_statsper.grs_offer_amt 
			END IF 
			LET l_rec_statsper.net_amt = GROUP sum(p_rec_cur_statsper.net_amt) 
			LET l_rec_statsper.net_offer_amt = GROUP sum(p_rec_cur_statsper.net_offer_amt) 
			LET l_rec_statsper.net_inv_amt = GROUP sum(p_rec_cur_statsper.net_inv_amt) 
			LET l_rec_statsper.net_cred_amt = GROUP sum(p_rec_cur_statsper.net_cred_amt) 
			IF l_rec_statsper.net_offer_amt < 0 THEN 
				LET l_rec_statsper.net_cred_amt = l_rec_statsper.net_cred_amt - l_rec_statsper.net_offer_amt 
			END IF 
			IF l_rec_statsper.net_offer_amt > 0 THEN 
				LET l_rec_statsper.net_inv_amt = l_rec_statsper.net_inv_amt - l_rec_statsper.net_offer_amt 
			END IF 
			LET l_rec_statsper.cost_amt = GROUP sum(p_rec_cur_statsper.cost_amt) 
			LET l_rec_statsper.comm_amt = GROUP sum(p_rec_cur_statsper.comm_amt) 
			
			#YTD
			LET l_s_rec_statsper.grs_amt = GROUP sum(p_rec_ytd_statsper.grs_amt) 
			LET l_s_rec_statsper.grs_inv_amt = GROUP sum(p_rec_ytd_statsper.grs_inv_amt) 
			LET l_s_rec_statsper.grs_cred_amt = GROUP sum(p_rec_ytd_statsper.grs_cred_amt) 
			LET l_s_rec_statsper.grs_offer_amt = GROUP sum(p_rec_ytd_statsper.grs_offer_amt) 
			IF l_s_rec_statsper.grs_offer_amt < 0 THEN 
				LET l_s_rec_statsper.grs_cred_amt = l_s_rec_statsper.grs_cred_amt - l_s_rec_statsper.grs_offer_amt 
			END IF 
			IF l_s_rec_statsper.grs_offer_amt > 0 THEN 
				LET l_s_rec_statsper.grs_inv_amt = l_s_rec_statsper.grs_inv_amt - l_s_rec_statsper.grs_offer_amt 
			END IF 
			LET l_s_rec_statsper.net_amt = GROUP sum(p_rec_ytd_statsper.net_amt) 
			LET l_s_rec_statsper.net_inv_amt = GROUP sum(p_rec_ytd_statsper.net_inv_amt) 
			LET l_s_rec_statsper.net_cred_amt = GROUP sum(p_rec_ytd_statsper.net_cred_amt) 
			LET l_s_rec_statsper.net_offer_amt = GROUP sum(p_rec_ytd_statsper.net_offer_amt) 
			IF l_s_rec_statsper.net_offer_amt < 0 THEN 
				LET l_s_rec_statsper.net_cred_amt = l_s_rec_statsper.net_cred_amt - l_s_rec_statsper.net_offer_amt 
			END IF 
			IF l_rec_statsper.net_offer_amt > 0 THEN 
				LET l_rec_statsper.net_inv_amt = l_rec_statsper.net_inv_amt - l_rec_statsper.net_offer_amt 
			END IF 
			LET l_rec_statsper.cost_amt = GROUP sum(p_rec_ytd_statsper.cost_amt) 
			LET l_rec_statsper.comm_amt = GROUP sum(p_rec_ytd_statsper.comm_amt) 
			
			#
			SELECT name_text INTO l_name_text FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = p_rec_cur_statsper.sale_code 
			PRINT COLUMN 01,"Salesperson: ", 
			COLUMN 14,p_rec_cur_statsper.sale_code, 
			COLUMN 23,l_name_text 
			SKIP 1 line 
			PRINT COLUMN 11,"Gross invoices", 
			COLUMN 34,l_rec_statsper.grs_inv_amt USING "--,---,--&", 
			COLUMN 58,l_s_rec_statsper.grs_inv_amt USING "--,---,--&" 
			PRINT COLUMN 11,"Gross credits", 
			COLUMN 34,l_rec_statsper.grs_cred_amt USING "--,---,--&", 
			COLUMN 58,l_s_rec_statsper.grs_cred_amt USING "--,---,--&" 
			PRINT COLUMN 11,"Gross offers", 
			COLUMN 34,l_rec_statsper.grs_offer_amt USING "--,---,--&", 
			COLUMN 58,l_s_rec_statsper.grs_offer_amt USING "--,---,--&" 
			PRINT COLUMN 34,"----------", 
			COLUMN 58,"----------" 
			PRINT COLUMN 11,"Total gross turnover", 
			COLUMN 34,l_rec_statsper.grs_amt USING "--,---,--&", 
			COLUMN 58,l_s_rec_statsper.grs_amt USING "--,---,--&" 
			
			SKIP 2 line 
			SELECT bdgt_amt INTO l_bdgt_amt FROM stattarget 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bdgt_type_ind = "4" 
			AND bdgt_type_code = p_rec_cur_statsper.sale_code 
			AND bdgt_ind = "1" 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statint.type_code 
			AND int_num = modu_rec_statint.int_num 
			IF status = NOTFOUND THEN 
				LET l_bdgt_amt = 0 
			END IF 
			IF l_bdgt_amt = 0 THEN 
				LET l_achieve_net = 0 
			ELSE 
				LET l_achieve_net = 100 * (l_s_rec_statsper.net_amt/l_bdgt_amt) 
			END IF 

			#YTD
			SELECT sum(bdgt_amt) INTO l_s_bdgt_amt FROM stattarget 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bdgt_type_ind = "4" 
			AND bdgt_type_code = p_rec_cur_statsper.sale_code 
			AND bdgt_ind = "1" 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statint.type_code 
			AND int_num between 1 AND modu_rec_statint.int_num 
			IF l_s_bdgt_amt IS NULL THEN 
				LET l_s_bdgt_amt = 0 
			END IF 
			IF l_s_bdgt_amt = 0 THEN 
				LET l_s_achieve_net = 0 
			ELSE 
				LET l_s_achieve_net = 100 * (l_rec_statsper.net_amt/l_s_bdgt_amt) 
			END IF 
			PRINT COLUMN 11,"Nett invoices", 
			COLUMN 34,l_rec_statsper.net_inv_amt USING "--,---,--&", 
			COLUMN 58,l_s_rec_statsper.net_inv_amt USING "--,---,--&" 
			PRINT COLUMN 11,"Nett credits", 
			COLUMN 34,l_rec_statsper.net_cred_amt USING "--,---,--&", 
			COLUMN 58,l_s_rec_statsper.net_cred_amt USING "--,---,--&" 
			PRINT COLUMN 11,"Nett offers", 
			COLUMN 34,l_rec_statsper.net_offer_amt USING "--,---,--&", 
			COLUMN 58,l_s_rec_statsper.net_offer_amt USING "--,---,--&" 
			PRINT COLUMN 34,"----------", 
			COLUMN 58,"----------" 
			PRINT COLUMN 11,"Total nett turnover", 
			COLUMN 34,l_rec_statsper.net_amt USING "--,---,--&", 
			COLUMN 58,l_s_rec_statsper.net_amt USING "--,---,--&" 
			PRINT COLUMN 11,"Sales targets", 
			COLUMN 34,l_bdgt_amt USING "--,---,--&", 
			COLUMN 45,l_achieve_net USING "----&.&", 
			COLUMN 58,l_s_bdgt_amt USING "--,---,--&", 
			COLUMN 69,l_s_achieve_net USING "----&.&" 
			
			SKIP 2 line 
			IF l_rec_statsper.grs_inv_amt - l_rec_statsper.grs_cred_amt = 0 THEN 
				LET l_disc_net = 0 
			ELSE 
				LET l_disc_net = 100 * 
				(1-((l_rec_statsper.net_inv_amt-l_rec_statsper.net_cred_amt)/ 
				(l_rec_statsper.grs_inv_amt-l_rec_statsper.grs_cred_amt))) 
			END IF 
			IF l_rec_statsper.grs_offer_amt = 0 THEN 
				LET l_disc_off = 0 
			ELSE 
				LET l_disc_off = 100 * 	(1-(l_rec_statsper.net_offer_amt/l_rec_statsper.grs_offer_amt)) 
			END IF 
			IF l_rec_statsper.grs_amt = 0 THEN 
				LET l_disc_trn = 0 
			ELSE 
				LET l_disc_trn = 100 * (1-(l_rec_statsper.net_amt/l_rec_statsper.grs_amt)) 
			END IF 
			#YTD
			IF l_rec_statsper.grs_inv_amt - l_rec_statsper.grs_cred_amt = 0 THEN 
				LET l_s_disc_net = 0 
			ELSE 
				LET l_s_disc_net = 100 * 
				(1-((l_rec_statsper.net_inv_amt-l_rec_statsper.net_cred_amt)/ 
				(l_rec_statsper.grs_inv_amt-l_rec_statsper.grs_cred_amt))) 
			END IF 
			IF l_rec_statsper.grs_offer_amt = 0 THEN 
				LET l_s_disc_off = 0 
			ELSE 
				LET l_s_disc_off = 100 * 
				(1-(l_rec_statsper.net_offer_amt/l_rec_statsper.grs_offer_amt)) 
			END IF 
			IF l_rec_statsper.grs_amt = 0 THEN 
				LET l_s_disc_trn = 0 
			ELSE 
				LET l_s_disc_trn = 100 * (1-(l_rec_statsper.net_amt/l_rec_statsper.grs_amt)) 
			END IF 
			PRINT COLUMN 11,"Discount-% nett", 
			COLUMN 34,(l_rec_statsper.grs_inv_amt-l_rec_statsper.grs_cred_amt) - 
			(l_rec_statsper.net_inv_amt-l_rec_statsper.net_cred_amt) 
			USING "--,---,--&", 
			COLUMN 45,l_disc_net USING "----&.&", 
			COLUMN 58,(l_rec_statsper.grs_inv_amt-l_rec_statsper.grs_cred_amt) - 
			(l_rec_statsper.net_inv_amt-l_rec_statsper.net_cred_amt) 
			USING "--,---,--&", 
			COLUMN 69,l_s_disc_net USING "----&.&" 
			PRINT COLUMN 11,"Discount-% off.", 
			COLUMN 34,l_rec_statsper.grs_offer_amt - 
			l_rec_statsper.net_offer_amt USING "--,---,--&", 
			COLUMN 45,l_disc_off USING "----&.&", 
			COLUMN 58,l_rec_statsper.grs_offer_amt - 
			l_rec_statsper.net_offer_amt USING "--,---,--&", 
			COLUMN 69,l_s_disc_off USING "----&.&" 
			PRINT COLUMN 34,"----------", 
			COLUMN 58,"----------" 
			PRINT COLUMN 11,"Total discount-% ", 
			COLUMN 34,l_rec_statsper.grs_amt - 
			l_rec_statsper.net_amt USING "--,---,--&", 
			COLUMN 45,l_disc_trn USING "----&.&", 
			COLUMN 58,l_rec_statsper.grs_amt - 
			l_rec_statsper.net_amt USING "--,---,--&", 
			COLUMN 69,l_s_disc_trn USING "----&.&" 
			SKIP 2 line 
			
			IF l_rec_statsper.net_amt = 0 THEN 
				LET l_costs_per = 0 
				LET l_comm_per = 0 
				LET l_contr_per = 0 
			ELSE 
				LET l_costs_per = 100 * (l_rec_statsper.cost_amt/l_rec_statsper.net_amt) 
				LET l_comm_per = 100 * (l_rec_statsper.comm_amt/l_rec_statsper.net_amt) 
				LET l_contr_per = 100 * ((l_rec_statsper.net_amt - 
				l_rec_statsper.cost_amt - 
				l_rec_statsper.comm_amt)/l_rec_statsper.net_amt) 
			END IF 

			#YTD
			IF l_rec_statsper.net_amt = 0 THEN 
				LET l_s_costs_per = 0 
				LET l_s_comm_per = 0 
				LET l_s_contr_per = 0 
			ELSE 
				LET l_s_costs_per = 100 * (l_rec_statsper.cost_amt/l_rec_statsper.net_amt) 
				LET l_s_comm_per = 100 * (l_rec_statsper.comm_amt/l_rec_statsper.net_amt) 
				LET l_s_contr_per = 100 * ((l_rec_statsper.net_amt - 
				l_rec_statsper.cost_amt - 
				l_rec_statsper.comm_amt)/l_rec_statsper.net_amt) 
			END IF 

			PRINT COLUMN 11,"Product costs", 
			COLUMN 34,l_rec_statsper.cost_amt USING "--,---,--&", 
			COLUMN 58,l_rec_statsper.cost_amt USING "--,---,--&" 
			PRINT COLUMN 11,"% of net turnover", 
			COLUMN 37,l_costs_per USING "----&.&", 
			COLUMN 61,l_s_costs_per USING "----&.&" 
			SKIP 1 line 
			PRINT COLUMN 11,"Commission", 
			COLUMN 34,l_rec_statsper.comm_amt USING "--,---,--&", 
			COLUMN 58,l_rec_statsper.comm_amt USING "--,---,--&" 
			PRINT COLUMN 11,"% of net turnover", 
			COLUMN 37,l_comm_per USING "----&.&", 
			COLUMN 61,l_s_comm_per USING "----&.&" 
			SKIP 1 line 
			PRINT COLUMN 11,"Contribution", 
			COLUMN 34,l_rec_statsper.net_amt - 
			l_rec_statsper.cost_amt - 
			l_rec_statsper.comm_amt USING "--,---,--&", 
			COLUMN 58,l_rec_statsper.net_amt - 
			l_rec_statsper.cost_amt - 
			l_rec_statsper.comm_amt USING "--,---,--&" 
			PRINT COLUMN 11,"% of net turnover", 
			COLUMN 37,l_contr_per USING "----&.&", 
			COLUMN 61,l_s_contr_per USING "----&.&" 
			SKIP 2 line 
			
		ON LAST ROW 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]			 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
###########################################################################
# END REPORT ETA_rpt_list(p_rpt_idx,p_rec_cur_statsper, p_rec_ytd_statsper) 
########################################################################### 