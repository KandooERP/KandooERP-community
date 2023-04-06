{
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

	Source code beautified by beautify.pl on 2020-01-02 10:35:18	$Id: $
}


#This file IS used as GLOBALS FROM U58.4gl AND loadfunc.4gl had it's own nested GLOBALS.. AND Informix
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/PSK_GLOBALS.4gl" 
GLOBALS "../in/ISR_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
################################################################
# FUNCTION menu_details()
################################################################
FUNCTION menu_details() 
	DELETE FROM kandooreport 
	WHERE report_code = pr_menu_path 
	AND language_code = "ENG" 
	CREATE temp TABLE t_quaderr(line_num SMALLINT, error_text CHAR(100)) 
	--CALL rpt_rmsreps_set_page_size(132,66) 

	OPEN WINDOW U527 with FORM "U527" 
	CALL windecoration_u("U527") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	DISPLAY pr_window_name TO window_name

	MENU " Data Load " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","loadfunc","menu-data_load") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Load" " Enter load file details" 
			IF load_file() THEN 
				CALL validate_file() 
				CALL finish_report(rpt_rmsreps_idx_get_idx("IZQc_rpt_list_err")) 
				NEXT option "Print Manager" 
			ELSE 
				NEXT option "Exit" 
			END IF 

		ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

			# --huho we need TO use OS class functions with this.. AND what do we do with the output ? hmmm @task @todo
      COMMAND "Directory" " List entries in specified directory"
         prompt "Enter UNIX Pathname: " FOR directory

         IF int_flag OR quit_flag
         OR directory IS NULL THEN
            LET int_flag = FALSE
            LET quit_flag = FALSE
            LET directory = NULL
         ELSE
            LET runner = "ls -f ",directory clipped,"|pg"
            run runner
         END IF

         NEXT OPTION "Load"

		ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW u527 
END FUNCTION 


################################################################
# FUNCTION load_file()
################################################################
FUNCTION load_file() 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp=kandoomsg("U",1020,"Load") 
	#1087 Enter Load Details - ESC TO Continue"
	LET pr_filename = directory 

	INPUT BY NAME pr_filename WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","lodfunc","input-filename") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD pr_filename 
			IF pr_filename IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9144,"") 
				#9144 " Interface file does NOT exist - Check path AND file name"
				NEXT FIELD pr_filename 
			END IF 

		AFTER INPUT 
			DISPLAY " " at 10,4 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			WHENEVER ERROR CONTINUE 
			DELETE FROM t_rates 
			WHERE 1=1 

			LET pr_filename2 = pr_filename clipped,".tmp" 
			LET runner = "../bin/NQI_to_MXI.sh ",pr_filename clipped, 
			" ",pr_filename2 clipped 
			RUN runner 

			LOAD FROM pr_filename2 INSERT INTO t_rates 

			IF status != 0 THEN 

				IF status = -846 THEN 
					ERROR " Incorrect file FORMAT OR blank lines detected" 
				ELSE 
					DISPLAY "Status ", status at 10,4 
					LET l_msgresp=kandoomsg("G",9144,"") 
					#9144 "Interface file does NOT exist - Check path AND file name"
				END IF 

				NEXT FIELD pr_filename 

			END IF 

			SELECT unique 1 FROM t_rates 

			IF status = notfound THEN 
				LET l_msgresp=kandoomsg("G",9146,"") 
				#9146 "Interface file IS empty - Check PC Transfer was successfull"
				NEXT FIELD pr_filename 
			END IF 

			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 


################################################################
# FUNCTION finish_report(p_rpt_idx)
################################################################
FUNCTION finish_report(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_quaderr RECORD 
				line_num SMALLINT, 
				error_text CHAR(100) 
			 END RECORD 

	LET l_query_text = "SELECT * FROM t_quaderr" 
	PREPARE s_quaderr FROM l_query_text 
	DECLARE c_quaderr CURSOR FOR s_quaderr 

	FOREACH c_quaderr INTO l_quaderr.* 
		LET pr_err_cnt = pr_err_cnt + 1
		#---------------------------------------------------------
		OUTPUT TO REPORT IZQc_rpt_list_err(p_rpt_idx,l_quaderr.*) 
		#---------------------------------------------------------		 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IZQc_rpt_list_err
	CALL rpt_finish("IZQc_rpt_list_err")
	#------------------------------------------------------------

	IF pr_err_cnt > 0 THEN 
		ERROR pr_err_cnt," errors encountered in load. Refer TO error REPORT." 
	ELSE 
		ERROR "Load complete. ",pr_inserted_rows," rows successfully processed." 
	END IF 

	DELETE FROM t_rates 
	WHERE 1=1 

	DELETE FROM t_quaderr 
	WHERE 1=1 

END FUNCTION 


################################################################
# REPORT IZQc_rpt_list_err(p_rpt_idx,p_rec_quaderr)
#
#
################################################################
REPORT IZQc_rpt_list_err(p_rpt_idx,p_rec_quaderr) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_quaderr RECORD 
									line_num SMALLINT, 
									error_text CHAR(100) 
								END RECORD 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 

	OUTPUT 
--	left margin 0 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


		ON EVERY ROW 
			PRINT COLUMN 04, p_rec_quaderr.line_num USING "###&", 
			COLUMN 18, p_rec_quaderr.error_text 

		ON LAST ROW 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	


END REPORT 