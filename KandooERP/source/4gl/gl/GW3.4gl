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

	Source code beautified by beautify.pl on 2020-01-03 14:28:56	$Id: $
}



# This module contains the global declarations AND main
# functions FOR the REPORT COLUMN maintenance programs.


#This file IS used as GLOBALS file FROM Gw3a.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW3_GLOBALS.4gl" 


############################################################
# MAIN
#
#FUNCTION            :   main
#Description         :   This IS the main FUNCTION of the col_maint
#                        module. It contains the code TO DISPLAY the
#                        rptcol form AND menu of OPTIONS TO the
#                        SCREEN, AND administer the user's choice of
#                        these OPTIONS
#perform screens     :   rptcol
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GW3") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	#Get mwr parameters.  "There can only be one."
	SELECT * INTO glob_rec_mrwparms.* 
	FROM mrwparms 

	#OPEN the maintenance window
	OPEN WINDOW g513 with FORM "G513" 
	CALL windecoration_g("G513") 

	#Check IF the rpthead.rpt_id has been passed
	LET glob_rec_rpthead.rpt_id = get_url_report_id() #arg_val(2) 
	IF glob_rec_rpthead.rpt_id IS NOT NULL AND glob_rec_rpthead.rpt_id > " " THEN 
		LET glob_query_1 = "rpthead.rpt_id = '",glob_rec_rpthead.rpt_id,"'" 
		CALL col_curs() 
		IF glob_scurs_col_open THEN 
			CALL first_col() 
			# SELECT REPORT header information
			SELECT * INTO glob_rec_rpthead.* FROM rpthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = glob_rec_rpthead.rpt_id 

			CALL disp_col() 
		END IF 
	END IF 

	#SET up the menu bar
	MENU " COLUMN" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GW3","menu-COLUMN") 
			CALL fgl_dialog_setkeylabel("Add-Report-Column","Add Rep. Col","{CONTEXT}/public/querix/icon/svg/24/ic_add_box_24px.svg",11,FALSE,"Add Report Column" ) 
			CALL fgl_dialog_setkeylabel("Insert-Additional-Column","Insert Col","{CONTEXT}/public/querix/icon/svg/24/ic_add_box_24px.svg",12,FALSE,"Insert Additional Column" ) 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Query" 
			#COMMAND "Query" " SELECT Report columns"
			CALL col_qry() 
			IF glob_scurs_col_open THEN 
				CALL first_col() 
				CALL disp_col() 
			END IF 

		ON ACTION "Add-Report-Column" 
			#COMMAND "ADD" " Add a Report COLUMN"
			IF glob_rec_rpthead.rpt_id IS NOT NULL AND glob_rec_rpthead.rpt_id > " " THEN 
				CALL col_add() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected; Use Query Option.
				NEXT option "Query" 
			END IF 

		ON ACTION "INSERT" --"Insert-Additional-Column" 
			#COMMAND "Insert" " Insert an Additional COLUMN"
			IF glob_rec_rpthead.rpt_id IS NOT NULL AND glob_rec_rpthead.rpt_id > " " THEN 
				CALL col_insert() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected;  Use Query Option.
				NEXT option "Query" 
			END IF 

		ON ACTION "UPDATE" 
			#COMMAND "UPDATE" " Update selected Report COLUMN"
			IF glob_scurs_col_open THEN 
				IF glob_rec_rptcol.col_id IS NULL OR glob_rec_rptcol.col_id = 0 THEN 
					CALL col_add() 
				ELSE 
					CALL col_updt(false) 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected;  Use Query Option.
				NEXT option "Query" 
			END IF 

		ON ACTION "Delete" 
			#COMMAND "Delete" " Delete selected Report COLUMN"
			IF glob_scurs_col_open THEN 
				CALL col_dlte () 
				#Close AND re-OPEN CURSOR.
				CALL close_scurs_col() 
				CALL open_scurs_col() 
				IF glob_scurs_col_open THEN 
					CALL first_col() 
					CALL disp_col() 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected;  Use Query Option.
				NEXT option "Query" 
			END IF 

		ON ACTION "First" 
			#COMMAND KEY ("F",f18) "First" " SELECT the first RECORD in the queried SET"
			IF glob_scurs_col_open THEN 
				CALL first_col() 
				CALL disp_col() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected;  Use Query Option.
				NEXT option "Query" 
			END IF 

		ON ACTION "Last" 
			#COMMAND KEY ("L",f22) "Last" " SELECT the last RECORD in the queried SET"
			IF glob_scurs_col_open THEN 
				CALL last_col() 
				CALL disp_col() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected;  Use Query Option.
				NEXT option "Query" 
			END IF 

		ON ACTION "Next" 
			#COMMAND KEY ("N",f21) "Next" " SELECT the next RECORD in the queried SET"
			IF glob_scurs_col_open THEN 
				CALL next_col() 
				CALL disp_col() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected;  Use Query Option.
				NEXT option "Query" 
			END IF 

		ON ACTION "Previous" 
			#COMMAND KEY ("P",f19) "Prev" " SELECT the previous RECORD in the queried SET"
			IF glob_scurs_col_open THEN 
				CALL prev_col() 
				CALL disp_col() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected;  Use Query Option.
				NEXT option "Query" 
			END IF #glob_scurs_col_open THEN 

		ON ACTION "Analysis" 
			#COMMAND "Analysis" " Segment analysis across"
			IF glob_scurs_col_open THEN 
				CALL seg_anal_across(glob_rec_rptcol.col_uid) 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected;  Use Query Option.
				NEXT option "Query" 
			END IF 

		ON ACTION "Report" #was "Columns" 
			#COMMAND "Columns" " Open REPORT columns browse window"
			LET glob_rec_rptcol.rpt_id = col_brws(glob_rec_rptcol.rpt_id) 
			IF glob_rec_rptcol.rpt_id IS NOT NULL THEN 
				SELECT * INTO glob_rec_rpthead.* FROM rpthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rptcol.rpt_id 
				SELECT * INTO glob_rec_rptcol.* FROM rptcol 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rptcol.rpt_id 
				AND col_id = glob_rec_rptcol.col_id 
			END IF 
			CALL disp_col() 

		ON ACTION "Exit" 
			#COMMAND KEY(E,interrupt) "Exit" " Exit TO menus"
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 

	END MENU 

	CLOSE WINDOW g513 

END MAIN 


{

}
############################################################
# FUNCTION disp_col()
#
# FUNCTION           :    disp-col
# Description        :    This FUNCTION selects info FROM the rptcol table AND
#                         coldetl table AND displays it TO the rptcol form
# Impact GLOBALS     :    glob_rec_rowid
# perform screens    :    rptcol
############################################################
FUNCTION disp_col() 
	DEFINE l_rec_mrwitem RECORD LIKE mrwitem.* 
	DEFINE l_idx INTEGER 

	CLEAR FORM 

	DISPLAY BY NAME glob_rec_rpthead.rpt_id, 
	glob_rec_rpthead.rpt_text, 
	glob_rec_rptcol.col_id, 
	glob_rec_rptcol.width, 
	glob_rec_rptcol.amt_picture 


	FOR l_idx = 1 TO glob_coldesc_cnt 
		INITIALIZE glob_arr_recrptcoldesc[l_idx] TO NULL 
	END FOR 

	#Array Information.
	DECLARE col_curs CURSOR FOR 
	SELECT rptcoldesc.* FROM rptcoldesc 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rptcol.rpt_id 
	AND col_uid = glob_rec_rptcol.col_uid 
	ORDER BY rptcoldesc.seq_num 

	LET glob_coldesc_cnt = 0 
	FOREACH col_curs INTO glob_rec_rptcoldesc.* 
		LET glob_coldesc_cnt = glob_coldesc_cnt + 1 
		LET glob_arr_recrptcoldesc[glob_coldesc_cnt].col_desc = glob_rec_rptcoldesc.col_desc 
		IF glob_coldesc_cnt < 4 THEN #only DISPLAY the FIRST 3 
			DISPLAY glob_arr_recrptcoldesc[glob_coldesc_cnt].col_desc 
			TO sa_rptcol[glob_coldesc_cnt].col_desc 
		END IF 
		IF glob_coldesc_cnt > 19 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	#Array Information.
	DECLARE item_curs CURSOR FOR 
	SELECT colitem.*, mrwitem.*, colitemcolid.id_col_id 
	FROM colitem, mrwitem, outer( colitemcolid ) 
	WHERE colitem.col_uid = glob_rec_rptcol.col_uid 
	AND mrwitem.item_id = colitem.col_item 
	AND colitemcolid.col_uid = colitem.col_uid 
	AND colitemcolid.seq_num = colitem.seq_num 
	AND colitem.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND colitemcolid.cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY colitem.seq_num 

	LET glob_colitem_cnt = 0 
	FOREACH item_curs INTO glob_rec_colitem.*, glob_rec_mrwitem.*, glob_id_col_id 
		LET glob_colitem_cnt = glob_colitem_cnt + 1 

		LET glob_arr_reccolitem[glob_colitem_cnt].seq_num = glob_colitem_cnt 
		LET glob_arr_reccolitem[glob_colitem_cnt].id_col_id = glob_id_col_id 
		LET glob_arr_reccolitem[glob_colitem_cnt].col_item = glob_rec_colitem.col_item 
		LET glob_arr_reccolitem[glob_colitem_cnt].item_desc = glob_rec_mrwitem.item_desc 
		LET glob_arr_reccolitem[glob_colitem_cnt].item_operator = glob_rec_colitem.item_operator 

		IF glob_colitem_cnt < 5 THEN #only DISPLAY the FIRST 4 
			DISPLAY glob_arr_reccolitem[glob_colitem_cnt].seq_num, 
			glob_arr_reccolitem[glob_colitem_cnt].id_col_id, 
			glob_arr_reccolitem[glob_colitem_cnt].item_operator, 
			glob_arr_reccolitem[glob_colitem_cnt].col_item, 
			glob_arr_reccolitem[glob_colitem_cnt].item_desc 
			TO sa_colitem[glob_colitem_cnt].seq_num, 
			sa_colitem[glob_colitem_cnt].id_col_id, 
			sa_colitem[glob_colitem_cnt].item_operator, 
			sa_colitem[glob_colitem_cnt].col_item, 
			sa_colitem[glob_colitem_cnt].item_desc 

		END IF 
		IF glob_colitem_cnt > 19 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

END FUNCTION #disp_col() 
