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
}
#as global FROM TGW2a

# This module contains the global declarations AND main
# functions FOR the M.R.W. REPORT header maintenance programs.


{
FUNCTION            :   main
Description         :   This IS the main FUNCTION of the hdr_maint
                        module. It contains the code TO DISPLAY the
                        hdr_maint form AND menu of OPTIONS TO the
                        SCREEN, AND administer the user's choice of
                        these OPTIONS
perform screens     :   hdr_maint
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW2_GLOBALS.4gl" 

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	DEFINE fv_run_text CHAR(80) 

	CALL setModuleId("GW2") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_t_gw() #init batch module 



	OPEN WINDOW g510 with FORM "TG510" 
	CALL windecoration_t("TG510") -- albo kd-768 

	MENU "HEADER" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","TGW2","menu-HEADER-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND key(q,f9) "Query" "SELECT Report headers" 
			MESSAGE "" 
			CALL hdr_qry() 
			IF gv_scurs_hdr_open 
			OR gr_rpthead.rpt_id IS NOT NULL THEN 
				CALL first_hdr() 
			END IF 

		COMMAND key(a,f1) "Add" "Add a Report header" 
			MESSAGE "" 
			CALL hdr_add() 
			LET gv_scurs_hdr_open = false 

		COMMAND key(u) "UPDATE" "Update selected Report header" 
			MESSAGE "" 
			IF gv_scurs_hdr_open 
			OR gr_rpthead.rpt_id IS NOT NULL THEN 
				CALL hdr_updt() 
			ELSE 
				ERROR "No records selected. Query first" 
				NEXT option "Query" 
			END IF 

		COMMAND key(d,f2) "Delete" "Delete selected Report header" 
			MESSAGE "" 
			IF gv_scurs_hdr_open 
			OR gr_rpthead.rpt_id IS NOT NULL THEN 
				IF hdr_dlte() THEN 
					CALL close_scurs_hdr() 
					CALL open_scurs_hdr() 
					CALL first_hdr() 
				END IF 
			ELSE 
				ERROR "No records selected. Query first" 
				NEXT option "Query" 
			END IF 

		COMMAND "First" "SELECT the first RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_hdr_open THEN 
				CALL first_hdr() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND "Last" "SELECT the last RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_hdr_open THEN 
				CALL last_hdr() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(N,F3) "Next" "SELECT the next RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_hdr_open THEN 
				CALL next_hdr() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(P,F4) "Prev" "SELECT the previous RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_hdr_open THEN 
				CALL prev_hdr() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND "Report" "Generate a REPORT of the definition details" 
			CALL run_prog("TGW5", "", "", "", "") 

		COMMAND KEY(E,interrupt) "DEL TO Exit" "Exit this menu TO calling process" 
			EXIT MENU 

		COMMAND KEY(CONTROL-B) 
			LET gr_rpthead.rpt_id = hdr_brws(gr_rpthead.rpt_id) 
			IF gr_rpthead.rpt_id IS NOT NULL THEN 
				SELECT * 
				INTO gr_rpthead.* 
				FROM rpthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = gr_rpthead.rpt_id 

			END IF 
			IF status = notfound THEN 
				ERROR "Header disappeared!" 
			ELSE 
				CALL disp_hdr() 
			END IF 

		ON ACTION "Print Manager" 
			#COMMAND KEY(F10)
			CALL run_prog("URS", "", "", "", "") 

	END MENU 

	CLOSE WINDOW g510 

END MAIN 


{
FUNCTION           :    disp-hdr
Description        :    This FUNCTION selects info FROM the rpthead table AND
                        hdrdetl table AND displays it TO the hdr_maint form
Impact GLOBALS     :    gr_rowid
perform screens    :    hdr_maint
}


FUNCTION disp_hdr() 

	CLEAR FORM 

	DISPLAY BY NAME gr_rpthead.rpt_id, 
	gr_rpthead.rpt_text, 
	gr_rpthead.rpt_desc1, 
	gr_rpthead.rpt_desc2, 
	gr_rpthead.rpt_desc_position, 
	gr_rpthead.rnd_code, 
	gr_rpthead.sign_code, 
	gr_rpthead.always_print_line, 
	gr_rpthead.acct_grp, 
	gr_rpthead.col_hdr_per_page, 
	gr_rpthead.col_code, 
	gr_rpthead.std_head_per_page, 
	gr_rpthead.line_code 

	SELECT rptpos.* INTO gr_rptpos.* FROM rptpos 
	WHERE rptpos_id = gr_rpthead.rpt_desc_position 

	SELECT rndcode.* INTO gr_rndcode.* FROM rndcode 
	WHERE rnd_code = gr_rpthead.rnd_code 

	SELECT signcode.* INTO gr_signcode.* FROM signcode 
	WHERE sign_code = gr_rpthead.sign_code 

	DISPLAY BY NAME gr_rptpos.rptpos_desc, 
	gr_rndcode.rnd_desc, 
	gr_signcode.sign_desc 

END FUNCTION 
