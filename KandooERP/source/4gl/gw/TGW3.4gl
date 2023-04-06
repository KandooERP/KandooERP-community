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

	Source code beautified by beautify.pl on 2020-01-03 10:10:03	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW3_GLOBALS.4gl" 


# This module contains the global declarations AND main
# functions FOR the REPORT COLUMN maintenance programs.

{
FUNCTION            :   main
Description         :   This IS the main FUNCTION of the col_maint
                        module. It contains the code TO DISPLAY the
                        rptcol form AND menu of OPTIONS TO the
                        SCREEN, AND administer the user's choice of
                        these OPTIONS
perform screens     :   rptcol
}

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	DEFINE fv_dltd SMALLINT 

	CALL setModuleId("GW3") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_t_gw() #init batch module 


	#Get mwr parameters.  "There can only be one."
	SELECT * 
	INTO gr_mrwparms.* 
	FROM mrwparms 

	OPEN WINDOW g513 with FORM "TG513" 
	CALL windecoration_t("TG513") -- albo kd-768 
	INITIALIZE gr_rptcolgrp.* TO NULL 
	INITIALIZE gr_rptcol.* TO NULL 

	MENU "COLUMN" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","TGW3","menu-COLUMN-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND KEY(Q,F9) "Query" "SELECT Column codes" 
			MESSAGE "" 
			CALL col_qry() 

			IF gv_scurs_col_open THEN 
				CALL first_col() 
				CALL disp_col() 
			END IF 

		COMMAND KEY(A,F1) "Add" "Add a COLUMN" 
			MESSAGE "" 
			CALL col_add() 

		COMMAND KEY(I) "Insert" "Insert an Additional COLUMN" 
			MESSAGE "" 
			IF gr_rptcol.col_id IS NOT NULL 
			AND gr_rptcolgrp.col_code <> " " THEN 
				CALL col_insert() 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					CALL close_scurs_col() 
					CALL open_scurs_col() 
					IF gv_scurs_col_open THEN 
						CALL first_col() 
						CALL disp_col() 
					END IF 
				END IF 
			ELSE 
				ERROR "No records selected. Query first" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(U) "UPDATE" "Update selected COLUMN" 
			MESSAGE "" 
			IF gv_scurs_col_open 
			OR gr_rptcol.col_id IS NOT NULL THEN 
				IF gr_rptcol.col_id IS NULL OR gr_rptcol.col_id = 0 THEN 
					CALL col_add() 
				ELSE 
					CALL col_updt(false) 
				END IF 
			ELSE 
				ERROR "No records selected. Query first" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(D,F2) "Delete" "Delete selected COLUMN" 
			MESSAGE "" 
			IF gv_scurs_col_open 
			OR gr_rptcolgrp.col_code IS NOT NULL THEN 
				CALL col_dlte() 
				RETURNING fv_dltd 
				#Close AND re-OPEN CURSOR, IF sucessful delete
				IF fv_dltd AND gv_scurs_col_open THEN 
					CALL close_scurs_col() 
					CALL open_scurs_col() 
					IF gv_scurs_col_open THEN 
						CALL first_col() 
						CALL disp_col() 
					END IF 
				END IF 
			ELSE 
				ERROR "No records selected. Query first" 
				NEXT option "Query" 
			END IF 

		COMMAND "First" "SELECT the first RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_col_open THEN 
				CALL first_col() 
				CALL disp_col() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND "Last" "SELECT the last RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_col_open THEN 
				CALL last_col(true) 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(N,F3) "Next" "SELECT the next RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_col_open THEN 
				CALL next_col() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(P,F4) "Prev" "SELECT the previous RECORD in the queried SET" 
			MESSAGE "" 
			IF gv_scurs_col_open THEN 
				CALL prev_col() 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

		COMMAND KEY(E,interrupt) "DEL TO Exit" "Exit this menu TO calling process" 
			EXIT MENU 

		COMMAND KEY(CONTROL-B) 
			LET gr_rptcol.col_code = col_brws(gr_rptcol.col_code) 
			IF gr_rptcol.col_code IS NOT NULL THEN 
				SELECT * 
				INTO gr_rptcolgrp.* 
				FROM rptcolgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND col_code = gr_rptcol.col_code 

				SELECT * 
				INTO gr_rptcol.* 
				FROM rptcol 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND col_code = gr_rptcol.col_code 
				AND col_id = gr_rptcol.col_id 
			END IF 

			CALL disp_col() 

		ON ACTION "Print Manager" 
			#COMMAND KEY(F10)
			CALL run_prog("URS", "", "", "", "") 

		COMMAND KEY(F7) 
			MESSAGE "" 
			IF gv_scurs_col_open THEN 
				CALL seg_anal_across(gr_rptcol.col_uid) 
			ELSE 
				ERROR "No records selected, use Query option" 
				NEXT option "Query" 
			END IF 

	END MENU 

	CLOSE WINDOW g513 

END MAIN 


{
FUNCTION           :    disp-col
Description        :    This FUNCTION selects info FROM the rptcol table AND
                        coldetl table AND displays it TO the rptcol form
Impact GLOBALS     :    gr_rowid
perform screens    :    rptcol
}

FUNCTION disp_col() 

	DEFINE fr_mrwitem RECORD LIKE mrwitem.*, 
	fv_idx INTEGER 

	CLEAR FORM 
	MESSAGE "" 

	DISPLAY BY NAME gr_rptcolgrp.col_code, 
	gr_rptcolgrp.colgrp_desc, 
	gr_rptcolgrp.colrptg_type, 
	gr_rptcol.col_id, 
	gr_rptcol.width, 
	gr_rptcol.amt_picture, 
	gr_rptcol.curr_type, 
	gr_rptcol.print_flag 


	FOR fv_idx = 1 TO gv_coldesc_cnt 
		INITIALIZE ga_rptcoldesc[fv_idx] TO NULL 
	END FOR 

	DECLARE col_curs CURSOR FOR 
	SELECT rptcoldesc.* 
	FROM rptcoldesc 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND col_code = gr_rptcol.col_code 
	AND col_uid = gr_rptcol.col_uid 
	ORDER BY rptcoldesc.seq_num 

	LET gv_coldesc_cnt = 0 
	FOREACH col_curs INTO gr_rptcoldesc.* 
		LET gv_coldesc_cnt = gv_coldesc_cnt + 1 
		LET ga_rptcoldesc[gv_coldesc_cnt].col_desc = gr_rptcoldesc.col_desc 
		IF gv_coldesc_cnt < 4 THEN #only DISPLAY the FIRST 3 
			DISPLAY ga_rptcoldesc[gv_coldesc_cnt].col_desc 
			TO sa_rptcol[gv_coldesc_cnt].col_desc 
		END IF 
		IF gv_coldesc_cnt > 19 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CLOSE col_curs 

	DECLARE item_curs CURSOR FOR 
	SELECT colitem.*, mrwitem.*, colitemcolid.id_col_id 
	FROM colitem, mrwitem, outer( colitemcolid ) 
	WHERE colitem.col_uid = gr_rptcol.col_uid 
	AND mrwitem.item_id = colitem.col_item 
	AND colitemcolid.col_uid = colitem.col_uid 
	AND colitemcolid.seq_num = colitem.seq_num 
	ORDER BY colitem.seq_num 

	LET gv_colitem_cnt = 0 
	FOREACH item_curs INTO gr_colitem.*, gr_mrwitem.*, gv_id_col_id 
		LET gv_colitem_cnt = gv_colitem_cnt + 1 

		LET ga_colitem[gv_colitem_cnt].seq_num = gv_colitem_cnt 
		LET ga_colitem[gv_colitem_cnt].id_col_id = gv_id_col_id 
		LET ga_colitem[gv_colitem_cnt].col_item = gr_colitem.col_item 
		LET ga_colitem[gv_colitem_cnt].item_desc = gr_mrwitem.item_desc 
		LET ga_colitem[gv_colitem_cnt].item_operator = gr_colitem.item_operator 

		IF gv_colitem_cnt < 5 THEN #only DISPLAY the FIRST 4 
			DISPLAY ga_colitem[gv_colitem_cnt].seq_num, 
			ga_colitem[gv_colitem_cnt].id_col_id, 
			ga_colitem[gv_colitem_cnt].item_operator, 
			ga_colitem[gv_colitem_cnt].col_item, 
			ga_colitem[gv_colitem_cnt].item_desc 
			TO sa_colitem[gv_colitem_cnt].seq_num, 
			sa_colitem[gv_colitem_cnt].id_col_id, 
			sa_colitem[gv_colitem_cnt].item_operator, 
			sa_colitem[gv_colitem_cnt].col_item, 
			sa_colitem[gv_colitem_cnt].item_desc 
		END IF 
		IF gv_colitem_cnt > 19 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CLOSE item_curs 

END FUNCTION 
