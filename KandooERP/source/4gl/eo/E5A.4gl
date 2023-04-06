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
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E5A_GLOBALS.4gl"

###########################################################################
# \brief module E5A - Monitors the proceeding of the delivery cycle in the
#               warehouses. Currently five OPTIONS are provided via a ring
#               menu.
#               Scroll: scrolls through generated delivery MESSAGEs with
#                       the option of RETURN on an error MESSAGE TO get a
#                       detailed explanation.
#               Run   : starts the delivery cycle(E5Aa) FOR every warehouse
#                       which has automated delivery cycle turned on.
#               Report: lets the user enter selection criteria TO PRINT a
#                       REPORT of the delivery(error) MESSAGEs
#               Delete: lets the user enter selection criteria TO delete
#                       delivery(error) MESSAGEs
#               Print : goes TO RMS
# inactive      Backgr: starts delivery cycle in background; interactive
# inactive              monitoring IS turned off
#               Exit  : stops program AND returns TO menu
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_where_text char(200) 
###########################################################################
# FUNCTION E5A_main()
#
# E5A - Monitors the proceeding of the delivery cycle in the
#       warehouses. Currently five OPTIONS are provided via a ring menu.
###########################################################################
FUNCTION E5A_main() 

	DEFER QUIT 
	DEFER INTERRUPT 


	CALL setModuleId("E5A") -- albo 
	CALL init_E5_GROUP()
	
	OPEN WINDOW E172 with FORM "E172" 
	 CALL windecoration_e("E172") -- albo kd-755 
	CALL build_up_screen()
	 
	MENU " Delivery cycle" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","E5A","menu-Delivery_Cycle-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Scroll" " Scroll through delivery messages" 
			CALL scan_delivmsg("1=1") 
			CALL build_up_screen() 

		COMMAND "Start Delivery Cycle" " Start delivery cycle" 
			CALL run_del_cycle() 

		COMMAND "Report" " SELECT Criteria AND PRINT report" 
			IF E5A_rpt_query() THEN 
				NEXT option "PRINT MANAGER" 
			END IF 

		COMMAND "Delete" " Delete delivery messages/errors" 
			CALL E5A_del_delivmsg_query() 
			CLEAR FORM 
			CALL build_up_screen() 

		ON ACTION "PRINT" #COMMAND KEY ("P",f11) "Print" " Print OR view using rms" 
			CALL run_prog("URS.4gi","","","","") 

		ON ACTION "EXIT" #COMMAND KEY(INTERRUPT,"E")"Exit" " Exit TO menus" 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW E172 
END FUNCTION
###########################################################################
# END FUNCTION E5A_main()
###########################################################################


###########################################################################
# FUNCTION select_delivmsg()
#
#
###########################################################################
FUNCTION select_delivmsg() 
	DEFINE l_where_text STRING

	CLEAR FORM 
	MESSAGE kandoomsg2("E",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME l_where_text ON 
		msg_date, 
		msg_time, 
		ware_code, 
		event_text, 
		msg_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E5A","construct-msg_date-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE 
		RETURN l_where_text 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_delivmsg()
###########################################################################


###########################################################################
# FUNCTION scan_delivmsg(p_where_text)
#
#
###########################################################################
FUNCTION scan_delivmsg(p_where_text) 
	DEFINE p_where_text char(200) 
	DEFINE l_rec_delivmsg RECORD LIKE delivmsg.* 
	DEFINE l_arr_rec_delivmsg DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag char(1), 
		msg_date LIKE delivmsg.msg_date, 
		msg_time LIKE delivmsg.msg_time, 
		ware_code LIKE delivmsg.ware_code, 
		event_text LIKE delivmsg.event_text, 
		msg_num LIKE delivmsg.msg_num 
	END RECORD 
	DEFINE l_arr_rec_msg_text DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		msg_text LIKE delivmsg.msg_text 
	END RECORD 
	DEFINE l_query_text STRING 
	DEFINE idx SMALLINT 

	WHILE p_where_text IS NOT NULL 
		MESSAGE kandoomsg2("E",1002,"") 	#1002 " Searching database - please wait "
		LET l_query_text = "SELECT * ", 
		"FROM delivmsg ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",p_where_text clipped," ", 
		"ORDER BY seq_num desc" 
		LET idx = 0 
		PREPARE s0_delivmsg FROM l_query_text 
		DECLARE c0_delivmsg cursor FOR s0_delivmsg 
		FOREACH c0_delivmsg INTO l_rec_delivmsg.* 
			LET idx = idx + 1
			LET l_arr_rec_delivmsg[idx].scroll_flag = NULL 
			LET l_arr_rec_delivmsg[idx].msg_date = l_rec_delivmsg.msg_date 
			LET l_arr_rec_delivmsg[idx].msg_time = l_rec_delivmsg.msg_time 
			LET l_arr_rec_delivmsg[idx].ware_code = l_rec_delivmsg.ware_code 
			LET l_arr_rec_delivmsg[idx].event_text = l_rec_delivmsg.event_text 
			LET l_arr_rec_delivmsg[idx].msg_num = l_rec_delivmsg.msg_num 
			LET l_arr_rec_msg_text[idx].msg_text = l_rec_delivmsg.msg_text 
		END FOREACH 

		IF idx = 0 THEN 
			ERROR kandoomsg2("E",9193,"")	#9193 No delivery MESSAGEs satisfied selection criteria "
			LET p_where_text = "" 
		ELSE 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f36 
			--CALL set_count(idx) 

			MESSAGE kandoomsg2("E",1053,"")			#1053 RETURN on line FOR Detailed Error Message
			INPUT ARRAY l_arr_rec_delivmsg WITHOUT DEFAULTS FROM sr_delivmsg.* 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","E5A","input-l_arr_rec_delivmsg-1") -- albo kd-502 

				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 

				BEFORE FIELD scroll_flag 
					LET idx = arr_curr() 

				AFTER FIELD scroll_flag 
					LET l_arr_rec_delivmsg[idx].scroll_flag = NULL 
					IF fgl_lastkey() = fgl_keyval("down") AND arr_curr() >= arr_count() THEN 
						ERROR kandoomsg2("E",9001,"") 
						NEXT FIELD scroll_flag 
					END IF 
					
				BEFORE FIELD msg_date 
					IF l_arr_rec_delivmsg[idx].msg_num IS NOT NULL THEN 
						ERROR kandoomsg2("E",l_arr_rec_delivmsg[idx].msg_num,	l_arr_rec_msg_text[idx].msg_text) 
					END IF 
					NEXT FIELD scroll_flag 


			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				CALL select_delivmsg() 
				RETURNING p_where_text 
			ELSE 
				LET p_where_text = "" 
			END IF 
		END IF 
	END WHILE 
	
END FUNCTION 
###########################################################################
# END FUNCTION scan_delivmsg(p_where_text)
###########################################################################


###########################################################################
# FUNCTION build_up_screen()
#
#
###########################################################################
FUNCTION build_up_screen() 
	DEFINE l_rec_delivmsg RECORD LIKE delivmsg.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_next_sched_date char(16) 
	DEFINE l_sched_date char(8) 
	DEFINE l_sched_time char(5) 
	DEFINE i SMALLINT 

	DECLARE c0_warehouse cursor FOR 
	SELECT * 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND next_sched_date IS NOT NULL 
	ORDER BY next_sched_date, ware_code 
	OPEN c0_warehouse 
	FETCH c0_warehouse INTO l_rec_warehouse.* 

	IF sqlca.sqlcode = 0 THEN 
		# Format of l_next_sched_date IS "ccyy-mm-dd hh:mm"
		LET l_next_sched_date = l_rec_warehouse.next_sched_date 
		LET l_sched_date[1,2] = l_next_sched_date[9,10] 
		LET l_sched_date[3,3] = "/" 
		LET l_sched_date[4,5] = l_next_sched_date[6,7] 
		LET l_sched_date[6,6] = "/" 
		LET l_sched_date[7,8] = l_next_sched_date[3,4] 
		LET l_sched_time = l_next_sched_date[12,16] 
		DISPLAY l_rec_warehouse.desc_text TO warehouse.desc_text 
		DISPLAY l_sched_date TO sched_date 
		DISPLAY l_sched_time TO sched_time 
	END IF 

	DECLARE c1_delivmsg cursor FOR 
	SELECT * FROM delivmsg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY seq_num desc 
	
	OPEN c1_delivmsg 
	FOR i = 1 TO 12 
		FETCH c1_delivmsg INTO l_rec_delivmsg.* 
		IF sqlca.sqlcode = 0 THEN 
			DISPLAY 
				"", 
				l_rec_delivmsg.msg_date, 
				l_rec_delivmsg.msg_time, 
				l_rec_delivmsg.ware_code, 
				l_rec_delivmsg.event_text, 
				l_rec_delivmsg.msg_num 
			TO sr_delivmsg[i].* 

		END IF 
	END FOR 
END FUNCTION 
###########################################################################
# END FUNCTION build_up_screen()
###########################################################################


###########################################################################
# FUNCTION run_del_cycle()
#
#
###########################################################################
FUNCTION run_del_cycle() 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_current_date DATE 
	DEFINE l_current_time char(8) 
	DEFINE runner char(20) 

	MESSAGE kandoomsg2("E",1055,"") 	#1055 Automated Delivery Cycle - DEL TO Exit

	LET l_current_date = CURRENT year TO day 
	LET l_current_time = CURRENT hour TO second 
	DISPLAY l_current_date USING "ddd dd mmm yyyy" at 2, 13 

	DISPLAY l_current_time at 2, 30   #???

	WHILE NOT (int_flag OR quit_flag) 
		IF get_kandoooption_feature_state("EO","01") = "Y" THEN 
			EXIT WHILE 
		END IF 
		DECLARE c1_warehouse cursor FOR 
		SELECT * 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND next_sched_date IS NOT NULL 
		ORDER BY next_sched_date, ware_code 
		OPEN c1_warehouse 
		FETCH c1_warehouse INTO l_rec_warehouse.* 

		IF sqlca.sqlcode = 0 THEN 
			IF l_rec_warehouse.next_sched_date <= CURRENT year TO minute THEN 
				CALL run_prog("E5X",l_rec_warehouse.ware_code,"","","") 
				CURRENT WINDOW IS E172 
				CALL build_up_screen() 
				--            CURRENT WINDOW IS w1_E5A  -- albo  KD-755
			END IF 
			LET l_current_date = CURRENT year TO day 
			LET l_current_time = CURRENT hour TO second 
			DISPLAY l_current_date USING "ddd dd mmm yyyy" at 2, 13 

			--DISPLAY l_current_time at 2, 30 

			--DISPLAY "" at 2, 45 
		ELSE 
			ERROR kandoomsg2("E",9192,"") 		#9192 None of the warehouses uses the automated delivery cycle
		END IF 
	END WHILE 
	--   CLOSE WINDOW w1_E5A  -- albo  KD-755
	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 
###########################################################################
# END FUNCTION run_del_cycle()
###########################################################################


###########################################################################
# FUNCTION E5A_del_delivmsg_query()
#
#
###########################################################################
FUNCTION E5A_del_delivmsg_query() 
	DEFINE l_rec_delivmsg RECORD LIKE delivmsg.* 
	DEFINE l_query_text char(300) 
	DEFINE l_where_text STRING
	
	OPEN WINDOW E173 with FORM "E173" 
	 CALL windecoration_e("E173") -- albo kd-755
 
	MESSAGE kandoomsg2("A",1001,"")#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON 
		msg_date, 
		msg_time, 
		ware_code, 
		event_text, 
		msg_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E5A","construct-msg_date-2") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF NOT (int_flag OR quit_flag) THEN
		IF promptTF("",kandoomsg2("E",8022,""),1)	THEN		 
			MESSAGE kandoomsg2("A",1005,"") #1005 Updating database - please wait
			LET l_query_text = "DELETE FROM delivmsg ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND ",l_where_text clipped," " 
			WHENEVER ERROR CONTINUE 
			PREPARE s3_delivmsg FROM l_query_text 
			EXECUTE s3_delivmsg 
			WHENEVER ERROR stop 
		END IF 
	END IF 
	CLOSE WINDOW E173 
END FUNCTION 


###########################################################################
# FUNCTION E5A_rpt_query() 
#
#
###########################################################################
FUNCTION E5A_rpt_query() 
	DEFINE l_rec_delivmsg RECORD LIKE delivmsg.* 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index

	OPEN WINDOW E173 with FORM "E173" 
	 CALL windecoration_e("E173") -- albo kd-755 

	MESSAGE kandoomsg2("A",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON 
		msg_date, 
		msg_time, 
		ware_code, 
		event_text, 
		msg_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E5A","construct-msg_date-3") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW E173 
		RETURN FALSE 
	END IF 

	MESSAGE kandoomsg2("A",1002,"")	#1002 Searching database - please wait
	LET l_query_text = "SELECT * ", 
	"FROM delivmsg ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY seq_num desc" 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"E5A_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E5A_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	
	PREPARE s2_delivmsg FROM l_query_text 
	DECLARE c2_delivmsg cursor FOR s2_delivmsg
	 
	FOREACH c2_delivmsg INTO l_rec_delivmsg.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT E5A_rpt_list(l_rpt_idx,
		l_rec_delivmsg.*) 
		
		IF NOT rpt_int_flag_handler2("Message:",l_rec_delivmsg.msg_num, l_rec_delivmsg.seq_num,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
		 
	END FOREACH
	 
	#------------------------------------------------------------
	FINISH REPORT E5A_rpt_list
	CALL rpt_finish("E5A_rpt_list")
	#------------------------------------------------------------

	CLOSE WINDOW E173
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION E5A_del_delivmsg_query()
###########################################################################


###########################################################################
# REPORT E5A_rpt_list(p_rec_delivmsg)  
#
#
###########################################################################
REPORT E5A_rpt_list(p_rpt_idx,p_rec_delivmsg) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_delivmsg RECORD LIKE delivmsg.*
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_kandoomsg RECORD LIKE kandoomsg.* 
	DEFINE l_col SMALLINT 
	DEFINE x SMALLINT 
	DEFINE i SMALLINT 
--	DEFINE line1 char(78)
--	DEFINE line2 char(78)
	DEFINE l_line1 char(320) 
	DEFINE l_line2 char(320) 
	DEFINE l_spaces char(320) 

	OUTPUT 

	ORDER external BY p_rec_delivmsg.seq_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 3, "Date", 
			COLUMN 10, "Time", 
			COLUMN 16, "Ware", 
			COLUMN 21, "Event/Error" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			IF p_rec_delivmsg.msg_num IS NOT NULL THEN 
				SELECT * 
				INTO l_kandoomsg.* 
				FROM kandoomsg 
				WHERE source_ind = "E" 
				AND msg_num = p_rec_delivmsg.msg_num 
				AND language_code = ( 
					select language_code 
					FROM kandoouser 
					WHERE sign_on_code = glob_rec_kandoouser.sign_on_code) 

				IF status = NOTFOUND THEN 
					LET l_spaces[1,80] = "Message Library Error - Message Not found." 
					LET l_spaces[81,160] = "Message Source Indicator = 'E'" 
					LET l_spaces[161,240] = "Message Number = ",p_rec_delivmsg.msg_num USING "#######" 
					LET l_spaces[241,320] = "Calling Program = ",get_baseProgName()," " 
					CALL errorlog(l_spaces) 
				END IF 

				IF p_rec_delivmsg.msg_text IS NOT NULL THEN 

					CASE l_kandoomsg.format_ind 

						WHEN "9" ## DISPLAY best possible fit. amend lines. 
							LET l_spaces = l_kandoomsg.msg1_text clipped," ", 
							p_rec_delivmsg.msg_text clipped," ", 
							l_kandoomsg.msg2_text clipped 
							IF length(l_spaces) > 70 THEN ##### manual wordwrap 
								LET x = length(l_spaces) 
								LET l_line2 = l_spaces[70,x] 
								FOR x = 69 TO 55 step -1 
									IF l_spaces[x,x] = " " THEN 
										EXIT FOR 
									ELSE 
										LET l_line2 = l_spaces[x,x],l_line2 clipped 
									END IF 
								END FOR 
								LET l_line1 = l_spaces[1,x] 
							ELSE 
								LET l_line1 = l_spaces clipped 
							END IF 

						WHEN "1" ## DISPLAY ***** at START line 1 
							LET l_spaces = p_rec_delivmsg.msg_text clipped," ", 
							l_kandoomsg.msg1_text clipped 
							LET l_line1 = l_spaces[1,60] 
							LET l_line2 = l_kandoomsg.msg2_text clipped 

						WHEN "2" ## DISPLAY ***** at END line 1 
							LET l_spaces = l_kandoomsg.msg1_text clipped," ", 
							p_rec_delivmsg.msg_text clipped 
							LET l_line1 = l_spaces[1,60] 
							LET l_line2 = l_kandoomsg.msg2_text 

						WHEN "3" ## DISPLAY ***** at START line 2 
							LET l_line1 = l_kandoomsg.msg1_text 
							LET l_spaces = p_rec_delivmsg.msg_text clipped," ", 
							l_kandoomsg.msg2_text clipped 
							LET l_line2 = l_spaces[1,60] 

						WHEN "4" ## DISPLAY ***** at END line 2 
							LET l_line1 = l_kandoomsg.msg1_text 
							LET l_spaces = l_kandoomsg.msg2_text clipped," ",	p_rec_delivmsg.msg_text clipped 
							LET l_line2 = l_spaces[1,60] 

						OTHERWISE 
							LET l_line1 = l_kandoomsg.msg1_text clipped 
							LET l_line2 = l_kandoomsg.msg2_text clipped 
					END CASE
					 
				ELSE 
					LET l_line1 = l_kandoomsg.msg1_text clipped 
					LET l_line2 = l_kandoomsg.msg2_text clipped 
				END IF 

			ELSE 

				LET l_kandoomsg.msg1_text = p_rec_delivmsg.event_text 
				LET l_kandoomsg.msg2_text = NULL 
			END IF
			 
			PRINT COLUMN 1, p_rec_delivmsg.msg_date USING "dd/mm/yy", 
			COLUMN 10, p_rec_delivmsg.msg_time, 
			COLUMN 16, p_rec_delivmsg.ware_code, 
			COLUMN 21, l_kandoomsg.msg1_text 
			
			IF l_kandoomsg.msg2_text IS NOT NULL THEN 
				PRINT COLUMN 21, l_kandoomsg.msg2_text 
			END IF 

		ON LAST ROW 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
END REPORT
###########################################################################
# END REPORT E5A_rpt_list(p_rec_delivmsg)  
###########################################################################