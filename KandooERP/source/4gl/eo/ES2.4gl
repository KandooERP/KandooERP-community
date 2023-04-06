###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
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
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ES2_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statint RECORD LIKE statint.* 
###########################################################################
# FUNCTION ES2_main() 
#
# ES2 Management Information Statistics Purging
###########################################################################
FUNCTION ES2_main() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_temp_text char(100) 
	DEFINE l_table_name char(20) 
	DEFINE x SMALLINT 

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ES2") 
	 
	SELECT min(year_num) INTO modu_rec_statint.year_num 
	FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	OPEN WINDOW E214 with FORM "E214" 
	 CALL windecoration_e("E214") -- albo kd-755 
	CALL disp_stats()
	 
	MENU " purge" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","ES2","menu-Purge-1") -- albo kd-502
 
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
					
--		COMMAND KEY ("N",f21) "Next" " Start purge FROM the next year " 
--			LET modu_rec_statint.year_num = modu_rec_statint.year_num + 1 
--			CALL disp_stats() 
--
--		COMMAND KEY ("L",f19) "Last" " Start purge FROM the last year " 
--			LET modu_rec_statint.year_num = modu_rec_statint.year_num - 1 
--			CALL disp_stats() 

		COMMAND "Commence" " Commence purging procedure" 
			IF promptTF("",kandoomsg2("E",8029,""),1)	THEN
				MESSAGE kandoomsg2("U",1005,"")		#1005 Updating database; Please wait.
				--IF rpt_note IS NULL THEN 
				--	LET rpt_note = "EO Statistics - Purge of year:", 
				--	modu_rec_statint.year_num 
				--END IF 
				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start(getmoduleid(),"ES2_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT ES2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------
				WHENEVER ERROR CONTINUE 

				BEGIN WORK 
					FOR x = 1 TO 11 
						DISPLAY "*" TO sr_rowcnt[x].scroll_flag 

						LET l_table_name = stat_table(x) 
						LET l_temp_text = "lock table ",l_table_name," in share mode" 
						PREPARE c_lock FROM l_temp_text 
						EXECUTE c_lock 
						IF sqlca.sqlcode = 0 THEN 
							LET l_temp_text ="DELETE FROM ",l_table_name," ", 
							"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
							"AND year_num='",modu_rec_statint.year_num,"'" 
							PREPARE c_delete FROM l_temp_text 
							EXECUTE c_delete 

							#---------------------------------------------------------							
							OUTPUT TO REPORT ES2_rpt_list(l_rpt_idx,x,sqlca.sqlerrd[3])
							#---------------------------------------------------------							 
						ELSE 
							LET quit_flag = TRUE 
							EXIT FOR 
						END IF 
						DISPLAY "*" TO sr_rowcnt[x].scroll_flag 

					END FOR 
					WHENEVER ERROR stop 
					
					FINISH REPORT ES2_rpt_list 
					#------------------------------------------------------------
						CALL rpt_finish("ES2_rpt_list")
					#------------------------------------------------------------					
					IF int_flag OR quit_flag THEN 
						ROLLBACK WORK 
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						ERROR kandoomsg2("E",7083,"") 
					ELSE 
						UPDATE statparms 
						SET last_purge_date = today 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND parm_code = "1" 
					COMMIT WORK 
					UPDATE STATISTICS 
					MESSAGE kandoomsg2("E",7082,"") 
				END IF 

			END IF 

		ON ACTION "PRINT MANAGER"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E") "Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW E214 
END FUNCTION
###########################################################################
# END FUNCTION ES2_main()
###########################################################################


###########################################################################
# FUNCTION disp_stats()  
#
# 
###########################################################################
FUNCTION disp_stats() 
	DEFINE l_arr_rowcnt array[12] OF INTEGER 
	DEFINE l_table_name char(20) 
	DEFINE l_query_text STRING
	DEFINE i SMALLINT 

	SELECT min(start_date) INTO modu_rec_statint.start_date 
	FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = modu_rec_statint.year_num 
	
	DISPLAY BY NAME glob_rec_statparms.last_purge_date 
	DISPLAY BY NAME modu_rec_statint.year_num 
	DISPLAY BY NAME modu_rec_statint.start_date 

	LET l_arr_rowcnt[12] = 0 
	FOR i = 1 TO 11 
		LET l_table_name = stat_table(i) 
		LET l_query_text = "SELECT count(*) FROM ",l_table_name," ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND year_num = '",modu_rec_statint.year_num,"'" 
		PREPARE s_count FROM l_query_text 
		DECLARE c_count cursor FOR s_count 
		OPEN c_count 
		FETCH c_count INTO l_arr_rowcnt[i] 
		LET l_arr_rowcnt[12] = l_arr_rowcnt[12] + l_arr_rowcnt[i] 
		DISPLAY l_arr_rowcnt[i],"" TO sr_rowcnt[i].* 

	END FOR 
	DISPLAY l_arr_rowcnt[12],"" TO sr_rowcnt[12].* 

END FUNCTION 
###########################################################################
# END FUNCTION disp_stats()  
###########################################################################


###########################################################################
# REPORT ES2_rpt_list(p_idx,p_row_cnt)   
#
# 
###########################################################################
REPORT ES2_rpt_list(p_rpt_idx,p_idx,p_row_cnt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_idx SMALLINT 
	DEFINE p_row_cnt INTEGER 
	DEFINE l_rec_stattrig RECORD LIKE stattrig.* 
	DEFINE l_line_text char(30) 
	--DEFINE col SMALLINT 

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			CASE p_idx 
				WHEN "1" LET l_line_text = "Statistics intervals" 
				WHEN "2" LET l_line_text = "Sales targets" 
				WHEN "3" LET l_line_text = "Customers" 
				WHEN "4" LET l_line_text = "products (& groups)" 
				WHEN "5" LET l_line_text = "Sales lines" 
				WHEN "6" LET l_line_text = "Sales Territories (& areas)" 
				WHEN "7" LET l_line_text = "Salespersons (& managers)" 
				WHEN "8" LET l_line_text = "Special offers" 
				WHEN "9" LET l_line_text = "Sales conditions" 
				WHEN "10" LET l_line_text ="Salesperson distributions" 
				WHEN "11" LET l_line_text ="Territory distributions" 
			END CASE 
			PRINT COLUMN 10, l_line_text clipped, 
			COLUMN 50, p_row_cnt USING "#######&" 

		ON LAST ROW 
			PRINT COLUMN 50, "=========" 
			PRINT COLUMN 10, "Total Number of Entries Deleted :", 
			COLUMN 50, sum(p_row_cnt) USING "&&&&&&&&" 
			SKIP 1 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
###########################################################################
# END REPORT ES2_rpt_list(p_idx,p_row_cnt)   
###########################################################################


###########################################################################
# FUNCTION stat_table(i)  
#
# 
###########################################################################
FUNCTION stat_table(i) 
	DEFINE i SMALLINT 

	CASE i 
	#     WHEN "1"  RETURN "statint"   ## commented out statint FOR testing
		WHEN "1" RETURN "stattarget" 
		WHEN "2" RETURN "stattarget" 
		WHEN "3" RETURN "statcust" 
		WHEN "4" RETURN "statprod" 
		WHEN "5" RETURN "statsale" 
		WHEN "6" RETURN "statterr" 
		WHEN "7" RETURN "statsper" 
		WHEN "8" RETURN "statoffer" 
		WHEN "9" RETURN "statcond" 
		WHEN "10" RETURN "distsper" 
		WHEN "11" RETURN "distterr" 
		OTHERWISE RETURN "" 
	END CASE 
END FUNCTION
###########################################################################
# END FUNCTION stat_table(i)  
###########################################################################