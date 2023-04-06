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

	Source code beautified by beautify.pl on 2020-01-03 10:10:04	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW4_GLOBALS.4gl" 


# This module contains the global declarations AND main
# functions FOR the REPORT line maintenance programs.

{
FUNCTION            :   main
Description         :   This IS the main FUNCTION of the line_maint
                        module. It contains the code TO DISPLAY the
                        rptline form AND menu of OPTIONS TO the
                        SCREEN, AND administer the user's choice of
                        these OPTIONS
perform screens     :   rptline
}

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	DEFINE fv_status SMALLINT 

	CALL setModuleId("GW4") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_t_gw() #init batch module 



	#Get mwr parameters.  "There can only be one."
	SELECT * INTO gr_mrwparms.* 
	FROM mrwparms 

	OPEN WINDOW g525 with FORM "TG525" 
	CALL windecoration_t("TG525") -- albo kd-768 
	CALL create_temps() 

	MENU "LINE" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","TGW4","menu-LINE-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND KEY(Q) "Query" "SELECT Line Codes" 
			LET gv_line_added = false 
			MESSAGE "" 
			CALL line_qry() 
			IF gv_scurs_line_open THEN 
				CALL first_line() 
				CALL disp_line() 
			END IF 

		COMMAND KEY(A,F1) "Add" "Add Line Code" 
			LET gv_line_added = false #until actually added 
			MESSAGE "" 
			CALL line_add() 

		COMMAND KEY(U) "UPDATE" "Update Line Code" 
			MESSAGE "" 
			IF gv_scurs_line_open OR gv_line_added THEN 
				CALL linegrp_updt() 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					ERROR "Update aborted" 
				ELSE 
					CALL line_updt() 
					CALL disp_line() 
				END IF 
			ELSE 
				ERROR "No records selected. Add/Query first" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(D) "Delete" "Delete Line Code" 
			MESSAGE "" 
			IF gv_scurs_line_open OR gv_line_added THEN 
				IF gr_rptlinegrp.line_code IS NOT NULL THEN 
					CALL line_dlte(gr_rptlinegrp.line_code) 
					RETURNING fv_status 
					IF NOT fv_status THEN 
						CALL close_scurs_line() 
						CALL open_scurs_line() 
						CALL first_line() 
						CALL disp_line() 
					END IF 
				END IF 
				IF gr_rptlinegrp.line_code IS NULL THEN 
					LET gv_line_added = false 
				END IF 
			ELSE 
				ERROR "No records selected. Add/Query first" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(I) "Image" "Image Line Code" 
			MESSAGE "" 
			CALL line_image() 
			RETURNING fv_status 

			IF fv_status THEN 
				ERROR "Line NOT imaged" 
			ELSE 
				MESSAGE "Line successfully imaged" 
				SLEEP 1 
			END IF 

		COMMAND "First" "SELECT the first RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_line_open THEN 
				CALL first_line() 
				CALL disp_line() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND "Last" "SELECT the last RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_line_open THEN 
				CALL last_line() 
				CALL disp_line() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(N,F3) "Next" "SELECT the next RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_line_open THEN 
				CALL next_line() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(P,F4) "Prev" "SELECT the previous RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_line_open THEN 
				CALL prev_line() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(E,interrupt) "DEL TO Exit" "Exit this menu TO calling process" 
			EXIT MENU 

		COMMAND KEY(CONTROL-B) 
			LET gr_rptline.line_code = line_brws(gr_rptline.line_code) 
			IF gr_rptlinegrp.line_code IS NOT NULL THEN 
				SELECT * 
				INTO gr_rptlinegrp.* 
				FROM rptlinegrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND line_code = gr_rptlinegrp.line_code 
			END IF 

			CALL disp_line() 


			#Special Key FOR checking AND correcting the line sequence numbers.
			#  TO be removed AFTER beta testing.
		COMMAND KEY(F9) 
			CALL seq_lines () 

		ON ACTION "Print Manager" 
			#COMMAND KEY(F10)
			CALL run_prog("URS", "", "", "", "") 

	END MENU 

	CLOSE WINDOW g525 

END MAIN 


{
FUNCTION           :    disp-line
Description        :    This FUNCTION selects info FROM the rptline table AND
                        linedetl table AND displays it TO the rptline form
Impact GLOBALS     :    gr_rowid
perform screens    :    rptline
}

FUNCTION disp_line() 

	DEFINE fv_s1 CHAR(200), 
	fv_idx INTEGER 

	CLEAR FORM 

	DISPLAY BY NAME gr_rptlinegrp.line_code, 
	gr_rptlinegrp.linegrp_desc 

	LET fv_s1 = "SELECT rptline.* ", 
	"FROM rptline ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND line_code = '",gr_rptlinegrp.line_code,"' ", 
	gv_query_2 clipped, 
	" ORDER BY rptline.line_id" 

	FOR fv_idx = 1 TO gv_line_cnt 
		INITIALIZE ga_rptline[fv_idx].* TO NULL 
	END FOR 

	PREPARE s1 FROM fv_s1 
	DECLARE line_curs CURSOR FOR s1 

	OPEN line_curs 
	LET gv_line_cnt = 0 

	FOREACH line_curs INTO gr_rptline.* 
		LET gv_line_cnt = gv_line_cnt + 1 
		LET ga_rptline[gv_line_cnt].line_id = gr_rptline.line_id 
		LET ga_rptline[gv_line_cnt].line_type = gr_rptline.line_type 
		LET ga_rptline[gv_line_cnt].line_desc = gr_rptline.line_desc 
		LET ga_rptline[gv_line_cnt].accum_id = gr_rptline.accum_id 
		LET ga_rptline[gv_line_cnt].page_break_follow = gr_rptline.page_break_follow 
		LET ga_rptline[gv_line_cnt].drop_lines = gr_rptline.drop_lines 

		IF gv_line_cnt < 11 THEN #only DISPLAY the FIRST 10 
			DISPLAY ga_rptline[gv_line_cnt].line_id, 
			ga_rptline[gv_line_cnt].line_type, 
			ga_rptline[gv_line_cnt].line_desc, 
			ga_rptline[gv_line_cnt].accum_id, 
			ga_rptline[gv_line_cnt].page_break_follow, 
			ga_rptline[gv_line_cnt].drop_lines 
			TO sa_rptline[gv_line_cnt].line_id, 
			sa_rptline[gv_line_cnt].line_type, 
			sa_rptline[gv_line_cnt].line_desc, 
			sa_rptline[gv_line_cnt].accum_id, 
			sa_rptline[gv_line_cnt].page_break_follow, 
			sa_rptline[gv_line_cnt].drop_lines 
		END IF 
		IF gv_line_cnt > 1999 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CLOSE line_curs 

END FUNCTION 


{
FUNCTION           :    disp-line
Description        :    This FUNCTION inserts the selected REPORT line details
                        INTO the temp table tt_rptline.  This allows us TO
                        query the line details later.
}

FUNCTION rptline_load() 

	DEFINE fv_idx INTEGER 

	DELETE FROM tt_rptline 

	FOR fv_idx = 1 TO gv_line_cnt 
		INSERT INTO tt_rptline VALUES ( ga_rptline[fv_idx].line_id, 
		ga_rptline[fv_idx].line_type, 
		ga_rptline[fv_idx].line_desc, 
		ga_rptline[fv_idx].accum_id, 
		ga_rptline[fv_idx].page_break_follow, 
		ga_rptline[fv_idx].drop_lines) 
	END FOR 

END FUNCTION 


FUNCTION create_temps() 

	CREATE temp TABLE tt_rptline ( line_id SMALLINT, 
	line_type CHAR(1), 
	line_desc CHAR(60), 
	accum_id SMALLINT, 
	page_break_follow CHAR(1), 
	drop_lines SMALLINT ) 
	with no LOG 
END FUNCTION 


{ FUNCTION:        sequence REPORT lines
  description:    FUNCTION the UPDATE all REPORT line_id in sequence
}
FUNCTION seq_lines () 

	DEFINE fr_rptline RECORD LIKE rptline.*, 
	fv_seq_line LIKE rptline.line_id 

	DECLARE seqlines_curs CURSOR FOR 
	SELECT * 
	FROM rptline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = gr_rptlinegrp.line_code 
	ORDER BY line_id 


	LET fv_seq_line = 0 

	FOREACH seqlines_curs INTO fr_rptline.* 
		LET fv_seq_line = fv_seq_line + 1 

		UPDATE rptline 
		SET line_id = fv_seq_line 
		WHERE line_uid = fr_rptline.line_uid 

	END FOREACH 

	CALL disp_line() 

END FUNCTION 
