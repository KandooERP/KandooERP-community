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
GLOBALS "../eo/ET7_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statparms RECORD LIKE statparms.* 
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_temp_text STRING 
###########################################################################
# FUNCTION ET7_main()
#
# ET7 Results on Special Offers
###########################################################################
FUNCTION ET7_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ET7") 

	CREATE temp TABLE t_offersale(
		offer_code char(3), 
		desc_text char(30), 
		sales_qty float) with no LOG
	 
	SELECT * INTO modu_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
	
			OPEN WINDOW E276 with FORM "E276" 
			 CALL windecoration_e("E276") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY getmenuitemlabel(NULL) TO header_text 
			
			MENU " Special Offer results"
				BEFORE MENU
					CALL publish_toolbar("kandoo","ET7","menu-Special-Offer-1") -- albo kd-502 
				 	CALL rpt_rmsreps_reset(NULL)
					CALL ET7_rpt_process(ET7_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
										
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET7_rpt_process(ET7_rpt_query())

		
				ON ACTION "PRINT MANAGER" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
			
				ON ACTION "CANCEL" #COMMAND KEY("E",INTERRUPT)"Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW E276 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ET7_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E276 with FORM "E276" 
			 CALL windecoration_e("E276") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ET7_rpt_query()) #save where clause in env 
			CLOSE WINDOW E276 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ET7_rpt_process(get_url_sel_text())
	END CASE 
		
END FUNCTION 
###########################################################################
# END FUNCTION ET7_main()
###########################################################################


###########################################################################
# FUNCTION ET7_enter_offers() 
#
#
###########################################################################
FUNCTION ET7_enter_offers() 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_arr_rec_offersale DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING
	DEFINE l_sel_cnt SMALLINT 
	DEFINE idx SMALLINT 

	DELETE FROM t_offersale WHERE 1=1 

--	FOR idx = 1 TO 8 
--		CLEAR sr_offersale[idx].* 
--	END FOR 
	
	MESSAGE kandoomsg2("E",1001,"") #1001 Enter Selection Criteria - ESC TO Continue

	CONSTRUCT BY NAME l_where_text ON offer_code,	desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ET7","construct-offer_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	

	LET l_query_text = "SELECT * FROM offersale ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND start_date <= '",modu_rec_statint.end_date,"' ", 
	"AND end_date >= '",modu_rec_statint.start_date,"' ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY 1,2" 
	PREPARE s_offersale FROM l_query_text 
	DECLARE c_offersale cursor FOR s_offersale 

	LET l_sel_cnt = 0 
	LET idx = 0
	 
	FOREACH c_offersale INTO l_rec_offersale.* 
		LET idx = idx + 1 
		LET l_arr_rec_offersale[idx].offer_code = l_rec_offersale.offer_code 
		LET l_arr_rec_offersale[idx].desc_text = l_rec_offersale.desc_text 
	END FOREACH 
	
	IF idx = 0 THEN 
		CALL fgl_winmessage("No Data Found",kandoomsg2("E",9236,""),"ERROR") 	#9236" No Sales Special Offers Satsified Selection Criteria
	ELSE 
		MESSAGE kandoomsg2("E",1159,"") 	#1159 RETURN TO SELECT offer
--		CALL set_count(idx) 
		INPUT ARRAY l_arr_rec_offersale WITHOUT DEFAULTS FROM sr_offersale.* 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
--			LET scrn = scr_line() 
				IF l_arr_rec_offersale[idx].offer_code IS NOT NULL THEN 
	--				DISPLAY l_arr_rec_offersale[idx].* 
	--				TO sr_offersale[scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
				
			BEFORE FIELD scroll_flag 
				DISPLAY BY NAME l_sel_cnt 	attribute(yellow) 
				LET l_scroll_flag = l_arr_rec_offersale[idx].scroll_flag
				 
			AFTER FIELD scroll_flag 
				LET l_arr_rec_offersale[idx].scroll_flag = l_scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("E",9001,"") 
					NEXT FIELD scroll_flag 
				END IF
				 
			BEFORE FIELD offer_code 
				IF l_arr_rec_offersale[idx].scroll_flag IS NULL THEN 
					IF l_sel_cnt = 10 THEN 
						ERROR kandoomsg2("E",9237,"") 					#9237 Maximum of 10 offers only
					ELSE 
						LET l_arr_rec_offersale[idx].scroll_flag = "*" 
						LET l_sel_cnt = l_sel_cnt + 1 
					END IF 
				ELSE 
					LET l_arr_rec_offersale[idx].scroll_flag = NULL 
					LET l_sel_cnt = l_sel_cnt - 1 
				END IF 
				NEXT FIELD scroll_flag 

			AFTER INPUT 
				IF l_sel_cnt = 0 THEN 
					IF promptTF("",kandoomsg2("E",8031,""),1)	THEN #8031 No offers selected - Reselect ?
						NEXT FIELD scroll_flag 
					END IF 
				END IF 

		END INPUT 
		
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			RETURN FALSE 
		ELSE 
			FOR idx = 1 TO arr_count() 
				IF l_arr_rec_offersale[idx].scroll_flag IS NOT NULL THEN 
					INSERT INTO t_offersale VALUES (l_arr_rec_offersale[idx].offer_code, 
					l_arr_rec_offersale[idx].desc_text,0) 
				END IF 
			END FOR 
			RETURN TRUE 
		END IF 
	END IF 
	RETURN FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION ET7_enter_offers() 
###########################################################################


###########################################################################
# FUNCTION ET7_rpt_query()  
#
#
###########################################################################
FUNCTION ET7_rpt_query() 
	DEFINE l_where_text STRING

	IF NOT ET7_enter_year() THEN
		RETURN NULL
	END IF 
	IF NOT ET7_enter_offers() THEN 
		RETURN NULL
	END IF 


	MESSAGE kandoomsg2("E",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON sale_code, 
	name_text, 
	sale_type_ind, 
	terri_code, 
	mgr_code, 
	city_text, 
	state_code, 
	country_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ET7","construct-sale_code-1") -- albo kd-502 

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
# END FUNCTION ET7_rpt_query()  
###########################################################################


###########################################################################
# FUNCTION ET7_rpt_process(p_where_text) 
#
#
###########################################################################
FUNCTION ET7_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_statsale RECORD LIKE statsale.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ET7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ET7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET7_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET7_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET7_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET7_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET7_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET7_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET7_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET7_rpt_list")].ref2_ind
	#------------------------------------------------------------	

	LET l_query_text = "SELECT * FROM salesperson ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET7_rpt_list")].sel_text clipped," ",	
	"ORDER BY 1" 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 
	
	LET l_query_text="SELECT sum(sales_qty) ", 
	"FROM statoffer,", 
	"statint ", 
	"WHERE statoffer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND statoffer.sale_code = ? ", 
	"AND statoffer.offer_code = ? ", 
	"AND statint.cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND statint.type_code ='",modu_rec_statparms.day_type_code,"' ", 
	"AND statint.type_code = statoffer.type_code ", 
	"AND statint.int_num = statoffer.int_num ", 
	"AND statint.start_date between '",modu_rec_statint.start_date,"' ", 
	"AND '",modu_rec_statint.end_date,"'" 
	PREPARE s_statoffer FROM l_query_text 
	DECLARE c_statoffer cursor FOR s_statoffer
	 
	DECLARE c_t_offersale cursor FOR 
	SELECT * FROM t_offersale 

	MESSAGE kandoomsg2("E",1045,"")	#1045 Reporting on Salesperson...

	FOREACH c_salesperson INTO l_rec_salesperson.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ET7_rpt_list(l_rpt_idx,
		l_rec_salesperson.*)  
		IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ET7_rpt_list
	CALL rpt_finish("ET7_rpt_list")
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
# END FUNCTION ET7_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# FUNCTION ET7_enter_year() 
#
#
###########################################################################
FUNCTION ET7_enter_year() 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_query_text char(200) 
	DEFINE l_order_text char(10) 

	LET l_rec_statint.year_num = modu_rec_statparms.year_num 
	
	MESSAGE kandoomsg2("E",1157,"")	#1157 Enter year FOR REPORT run - ESC TO Continue
	INPUT BY NAME l_rec_statint.year_num, 
	l_rec_statint.type_code, 
	l_rec_statint.int_text, 
	l_rec_statint.start_date, 
	l_rec_statint.end_date WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(int_text)  
				LET modu_temp_text = "year_num = '",l_rec_statint.year_num,"' ", 
				"AND type_code = '",l_rec_statint.type_code,"'" 
				LET modu_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,modu_temp_text) 
				IF modu_temp_text IS NOT NULL THEN 
					LET l_rec_statint.int_num = modu_temp_text 
					NEXT FIELD int_text 
				END IF 

		ON ACTION "LOOKUP" infield(type_code)  
				LET modu_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,"") 
				IF modu_temp_text IS NOT NULL THEN 
					LET l_rec_statint.type_code = modu_temp_text 
					NEXT FIELD type_code 
				END IF 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET l_rec_statint.year_num = l_rec_statint.year_num - 1 
			NEXT FIELD year_num
			 
		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET l_rec_statint.year_num = l_rec_statint.year_num + 1 
			NEXT FIELD year_num
			 
		BEFORE FIELD year_num 
			IF l_rec_statint.type_code IS NULL THEN 
				LET l_rec_statint.type_code = modu_rec_statparms.mth_type_code 
				LET l_rec_statint.int_num = modu_rec_statparms.mth_num 
			END IF 
			IF l_rec_statint.int_num IS NOT NULL THEN 
				SELECT * INTO l_rec_statint.* 
				FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				DISPLAY BY NAME l_rec_statint.int_text, 
				l_rec_statint.type_code, 
				l_rec_statint.start_date, 
				l_rec_statint.end_date 

			END IF
			 
		AFTER FIELD year_num 
			IF l_rec_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 			#9210 Year number must be entered
				LET l_rec_statint.year_num = modu_rec_statparms.year_num 
				NEXT FIELD year_num 
			END IF 
			
		AFTER FIELD type_code 
			IF l_rec_statint.type_code IS NULL THEN 
				CLEAR int_text 
			ELSE 
				SELECT * FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = l_rec_statint.type_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9202,"") 				#9202 Interval type does NOT exist - Try Window"
					LET l_rec_statint.type_code = modu_rec_statparms.mth_type_code 
					NEXT FIELD type_code 
				ELSE 
					SELECT int_num INTO l_rec_statint.int_num 
					FROM statint 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = l_rec_statint.year_num 
					AND type_code = l_rec_statint.type_code 
					AND start_date <= modu_rec_statparms.last_upd_date 
					AND end_date >= modu_rec_statparms.last_upd_date 
					IF status = NOTFOUND THEN 
						LET l_rec_statint.int_num = NULL 
					END IF 
				END IF 
			END IF 
			DISPLAY BY NAME l_rec_statint.start_date, l_rec_statint.end_date 

		BEFORE FIELD int_text 
			IF l_rec_statint.type_code IS NULL THEN 
				CLEAR int_text 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD type_code 
				ELSE 
					NEXT FIELD start_date 
				END IF 
			ELSE 
				IF l_rec_statint.int_num IS NULL THEN 
					LET l_rec_statint.int_text = NULL 
				ELSE 
					SELECT * INTO l_rec_statint.* 
					FROM statint 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = l_rec_statint.year_num 
					AND type_code = l_rec_statint.type_code 
					AND int_num = l_rec_statint.int_num 
					DISPLAY BY NAME l_rec_statint.start_date, 
					l_rec_statint.end_date 

				END IF 
			END IF 

		AFTER FIELD int_text 
			IF l_rec_statint.int_text IS NOT NULL THEN 
				DECLARE c_interval cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_text = l_rec_statint.int_text 
				OPEN c_interval 
				FETCH c_interval INTO l_rec_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") 		#9223 Interval does NOT exist - Try Window"
					NEXT FIELD int_text 
				END IF 
			END IF 
			DISPLAY BY NAME l_rec_statint.start_date, l_rec_statint.end_date 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_statint.start_date IS NULL THEN 
					ERROR kandoomsg2("E",9203,"") 		#9203 Interval start_date be entered"
					NEXT FIELD start_date 
				END IF 
				IF l_rec_statint.end_date IS NULL THEN 
					ERROR kandoomsg2("E",9204,"") 	#9204 Interval end_date be entered"
					NEXT FIELD end_date 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		LET modu_rec_statint.start_date = l_rec_statint.start_date 
		LET modu_rec_statint.end_date = l_rec_statint.end_date 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ET7_enter_year() 
###########################################################################


###########################################################################
# REPORT ET7_rpt_list(p_rpt_idx,p_rec_salesperson)  
#
#
###########################################################################
REPORT ET7_rpt_list(p_rpt_idx,p_rec_salesperson) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_arr_offercode array[10] OF char(3) 
	DEFINE l_sales_qty LIKE statoffer.sales_qty 
	DEFINE l_tot_sales_qty LIKE statoffer.sales_qty 
	DEFINE l_desc_text char(30) 
	DEFINE x,i,j SMALLINT 

	OUTPUT 
 
	ORDER external BY p_rec_salesperson.cmpy_code, 
	p_rec_salesperson.mgr_code, 
	p_rec_salesperson.sale_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01,"Start Date: ",modu_rec_statint.start_date USING "dd/mm/yy", 
			COLUMN 25,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[25,132] 
			PRINT COLUMN 01," END Date: ",modu_rec_statint.end_date USING "dd/mm/yy" 
			PRINT COLUMN 01,"Manager", 
			COLUMN 10,"Salesperson"; 

			OPEN c_t_offersale 
			FOR i = 1 TO 10 
				FETCH c_t_offersale INTO l_rec_offersale.offer_code, 
				l_rec_offersale.desc_text, x 
				IF status = NOTFOUND THEN 
					EXIT FOR 
				END IF 
				LET x = 40 + (i*8) 
				PRINT COLUMN x, l_rec_offersale.offer_code; 
				LET l_arr_offercode[i] = l_rec_offersale.offer_code 
			END FOR 
			PRINT COLUMN 126,"Total" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_rec_salesperson.mgr_code 
			SKIP 1 line 
			NEED 20 LINES 
			SELECT name_text INTO l_desc_text 
			FROM salesmgr 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND mgr_code = p_rec_salesperson.mgr_code 
			PRINT COLUMN 01, p_rec_salesperson.mgr_code, 
			COLUMN 10, l_desc_text clipped 
			FOR x = 1 TO (length(l_desc_text)+9) 
				PRINT COLUMN x,"-"; 
			END FOR 
			PRINT COLUMN 132," " 
			
		ON EVERY ROW 
			LET l_tot_sales_qty = 0 
			PRINT COLUMN 10,p_rec_salesperson.sale_code, 
			COLUMN 19,p_rec_salesperson.name_text[1,26]; 
			FOR i = 1 TO 10 
				IF l_arr_offercode[i] IS NOT NULL THEN 
					OPEN c_statoffer USING p_rec_salesperson.sale_code, 
					l_arr_offercode[i] 
					FETCH c_statoffer INTO l_sales_qty 
					IF l_sales_qty IS NULL THEN 
						LET l_sales_qty = 0 
					END IF 
					LET x = 37 + (i*8) 
					PRINT COLUMN x,l_sales_qty USING "-------&"; 
					UPDATE t_offersale 
					SET sales_qty = sales_qty + l_sales_qty 
					WHERE offer_code = l_arr_offercode[i] 
					LET l_tot_sales_qty = l_tot_sales_qty + l_sales_qty 
				END IF 
			END FOR 
			PRINT COLUMN 125,l_tot_sales_qty USING "-------&" 
			
		ON LAST ROW 
			NEED 12 LINES 
			SKIP 1 LINES 
			PRINT COLUMN 10,"Special Offer summary" 
			PRINT COLUMN 10,"=====================" 
			OPEN c_t_offersale 
			FOREACH c_t_offersale INTO l_rec_offersale.offer_code, 
				l_rec_offersale.desc_text, 
				l_tot_sales_qty 
				PRINT COLUMN 5,l_rec_offersale.offer_code, 
				COLUMN 10,l_rec_offersale.desc_text, 
				COLUMN 42,l_tot_sales_qty USING "--------&" 
			END FOREACH 
			SELECT sum(sales_qty) INTO l_tot_sales_qty 
			FROM t_offersale 
			IF l_tot_sales_qty IS NULL THEN 
				LET l_tot_sales_qty = 0 
			END IF 
			PRINT COLUMN 10,"Total offers:", 
			COLUMN 42,l_tot_sales_qty USING "--------&" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			
END REPORT
###########################################################################
# END REPORT ET7_rpt_list(p_rpt_idx,p_rec_salesperson)  
###########################################################################