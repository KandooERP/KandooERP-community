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

	Source code beautified by beautify.pl on 2020-01-03 14:28:57	$Id: $
}



# This module contains the global declarations AND main
# functions FOR the M.R.W. REPORT line maintenance programs.

#Thsi file IS used as GLOBALS file FROM Gw4a.4gl
#GLOBALS "../common/glob_GLOBALS.4gl"
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW4_GLOBALS.4gl" 

############################################################
# MAIN
#
# Description         :   This IS the main FUNCTION of the line_maint
#                         module. It contains the code TO DISPLAY the
#                         rptline form AND menu of OPTIONS TO the
#                         SCREEN, AND administer the user's choice of
#                         these OPTIONS
# perform screens     :   rptline
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GW4") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	#Get mwr parameters.  "There can only be one."
	SELECT * INTO glob_rec_mrwparms.* 
	FROM mrwparms 

	#OPEN the maintenance window
	OPEN WINDOW g525 with FORM "G525" 
	CALL windecoration_g("G525") 


	CALL create_temps() 

	#Check IF the rpthead.rpt_id has been passed
	LET glob_rec_rpthead.rpt_id = get_url_report_id() #arg_val(2) 
	IF glob_rec_rpthead.rpt_id IS NOT NULL AND glob_rec_rpthead.rpt_id > " " THEN 
		LET glob_rec_rptline.rpt_id = glob_rec_rpthead.rpt_id 
		LET glob_query_1 = " rpthead.rpt_id = '",glob_rec_rpthead.rpt_id,"'" 
		CALL line_curs() 
		IF gv_scurs_line_open THEN 
			CALL first_line() 
			CALL disp_line() 
		END IF 
	END IF 


	#SET up the menu bar
	MENU " LINE" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GW4","menu-line") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Query" 
			#COMMAND "Query" " SELECT REPORT headers"
			CALL line_qry() 
			IF gv_scurs_line_open THEN 
				CALL first_line() 
				CALL disp_line() 
			END IF 

		ON ACTION "Detail" 
			#COMMAND KEY ("D",f20) "Detail" " Maintain Report line details"
			IF gv_scurs_line_open THEN 
				CALL line_updt() 
				CALL disp_line() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected; Use Query option."
				NEXT option "Query" 
			END IF 

		ON ACTION "First" 
			#COMMAND KEY ("F",f18) "First" " SELECT the first RECORD in the queried SET"
			IF gv_scurs_line_open THEN 
				CALL first_line() 
				CALL disp_line() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected; Use Query option."
				NEXT option "Query" 
			END IF 

		ON ACTION "Last" 
			#COMMAND KEY ("L",f22) "Last" " SELECT the last RECORD in the queried SET"
			IF gv_scurs_line_open THEN 
				CALL last_line() 
				CALL disp_line() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected; Use Query option."
				NEXT option "Query" 
			END IF 

		ON ACTION "Next" 
			#COMMAND KEY ("N",f21) "Next" " SELECT the next RECORD in the queried SET"
			IF gv_scurs_line_open THEN 
				CALL next_line() 
				CALL disp_line() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected; Use Query option."
				NEXT option "Query" 
			END IF 

		ON ACTION "Previous" 
			#COMMAND KEY ("P",f19) "Prev" " SELECT the previous RECORD in the queried SET"
			IF gv_scurs_line_open THEN 
				CALL prev_line() 
				CALL disp_line() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected; Use Query option."
				NEXT option "Query" 
			END IF 

		ON ACTION "Header" 
			#COMMAND "Header" " Open REPORT header browse window"
			LET glob_rec_rptline.rpt_id = line_brws(glob_rec_rptline.rpt_id) 
			IF glob_rec_rptline.rpt_id IS NOT NULL THEN 
				SELECT * INTO glob_rec_rpthead.* FROM rpthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rptline.rpt_id 
			END IF 
			CALL disp_line() 

		ON ACTION "Exit" 
			#COMMAND KEY(E,interrupt) "Exit" " Exit this menu TO calling process"
			EXIT MENU 

			--   COMMAND KEY (control-w)
			--      CALL kandoohelp("")

	END MENU 

	CLOSE WINDOW g525 
END MAIN 


############################################################
# MAIN
#
# Description        :    This FUNCTION selects info FROM the rptline table AND
#                         linedetl table AND displays it TO the rptline form
# Impact GLOBALS     :    gr_rowid
# perform screens    :    rptline
# perform screens     :   rptline
############################################################
FUNCTION disp_line() 
	DEFINE l_s1 CHAR(200) 
	DEFINE l_idx INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 

	DISPLAY BY NAME glob_rec_rpthead.rpt_id, 
	glob_rec_rpthead.rpt_text 


	LET l_s1 = "SELECT rptline.* ", 
	"FROM rptline ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND rpt_id = '",glob_rec_rpthead.rpt_id,"' ", 
	glob_query_2 clipped, 
	" ORDER BY rptline.line_id" 

	#CLEAR previous array
	FOR l_idx = 1 TO glob_line_cnt 
		INITIALIZE glob_arr_rec_rptline[l_idx].* TO NULL 
	END FOR 

	PREPARE s1 FROM l_s1 
	DECLARE line_curs CURSOR FOR s1 

	LET glob_line_cnt = 0 

	FOREACH line_curs INTO glob_rec_rptline.* 
		LET glob_line_cnt = glob_line_cnt + 1 
		LET glob_arr_rec_rptline[glob_line_cnt].line_id = glob_rec_rptline.line_id 
		LET glob_arr_rec_rptline[glob_line_cnt].line_type = glob_rec_rptline.line_type 
		LET glob_arr_rec_rptline[glob_line_cnt].line_desc = glob_rec_rptline.line_desc 
		LET glob_arr_rec_rptline[glob_line_cnt].accum_id = glob_rec_rptline.accum_id 
		LET glob_arr_rec_rptline[glob_line_cnt].page_break_follow = glob_rec_rptline.page_break_follow 
		LET glob_arr_rec_rptline[glob_line_cnt].drop_lines = glob_rec_rptline.drop_lines 

		IF glob_line_cnt < 11 THEN #only DISPLAY the FIRST 10 
			DISPLAY glob_arr_rec_rptline[glob_line_cnt].line_id, 
			glob_arr_rec_rptline[glob_line_cnt].line_type, 
			glob_arr_rec_rptline[glob_line_cnt].line_desc, 
			glob_arr_rec_rptline[glob_line_cnt].accum_id, 
			glob_arr_rec_rptline[glob_line_cnt].page_break_follow, 
			glob_arr_rec_rptline[glob_line_cnt].drop_lines 
			TO sa_rptline[glob_line_cnt].line_id, 
			sa_rptline[glob_line_cnt].line_type, 
			sa_rptline[glob_line_cnt].line_desc, 
			sa_rptline[glob_line_cnt].accum_id, 
			sa_rptline[glob_line_cnt].page_break_follow, 
			sa_rptline[glob_line_cnt].drop_lines 

		END IF 
		IF glob_line_cnt > 1999 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

END FUNCTION #disp_line() 



############################################################
# FUNCTION rptline_load()
#
# Description        :    This FUNCTION inserts the selected REPORT line details
#                         INTO the temp table tt_rptline.  This allows us TO
#                         query the line details later.
############################################################
FUNCTION rptline_load() 
	DEFINE l_idx INTEGER 

	DELETE FROM tt_rptline #clear temporary table. 

	FOR l_idx = 1 TO glob_line_cnt 
		#Insert details INTO tt_rptline table.
		INSERT INTO tt_rptline VALUES ( glob_arr_rec_rptline[l_idx].line_id, 
		glob_arr_rec_rptline[l_idx].line_type, 
		glob_arr_rec_rptline[l_idx].line_desc, 
		glob_arr_rec_rptline[l_idx].accum_id, 
		glob_arr_rec_rptline[l_idx].page_break_follow, 
		glob_arr_rec_rptline[l_idx].drop_lines) 
	END FOR 

END FUNCTION 


FUNCTION create_temps() 

	#Temp table FOR rptline details.
	CREATE temp TABLE tt_rptline ( line_id SMALLINT, 
	line_type CHAR(1), 
	line_desc CHAR(32), 
	accum_id SMALLINT, 
	page_break_follow CHAR(1), 
	drop_lines CHAR(1)) with no LOG 
END FUNCTION 


############################################################
# FUNCTION seq_lines ()
#
# sequence REPORT lines
# description:    FUNCTION the UPDATE all REPORT line_id in sequence
############################################################
FUNCTION seq_lines () 
	DEFINE l_rec_rptline RECORD LIKE rptline.* 
	DEFINE l_seq_line LIKE rptline.line_id 

	DECLARE seqlines_curs CURSOR FOR 
	SELECT * FROM rptline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 
	ORDER BY line_id 


	LET l_seq_line = 0 

	FOREACH seqlines_curs INTO l_rec_rptline.* 
		LET l_seq_line = l_seq_line + 1 
		UPDATE rptline 
		SET line_id = l_seq_line 
		WHERE line_uid = l_rec_rptline.line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END FOREACH 

	CALL disp_line() 

END FUNCTION 
