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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../in/I_IN_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tr_ware_text LIKE warehouse.desc_text 
DEFINE modu_no_flag LIKE language.yes_flag 
DEFINE modu_yes_flag LIKE language.yes_flag 

####################################################################
# MAIN
#
# \brief module IZP - Inventory Set Up Parameters
#                   allows the user TO enter AND maintain inventory
#                   parameters
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZP") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET modu_no_flag = xlate_from("N") 
	LET modu_yes_flag = xlate_from("Y") 

	OPEN WINDOW i145 with FORM "I145" 
	 CALL windecoration_i("I145") 

	MENU "Inventory Parameters" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","IZP","menu-Inventory_Parameters-1") -- albo kd-505 
			CALL fgl_dialog_setactionlabel("Add Parameters","Add","{CONTEXT}/public/querix/icon/svg/24/ic_add_24px.svg",2,FALSE,"Add Parameters")
			CALL fgl_dialog_setactionlabel("Display","Display","{CONTEXT}/public/querix/icon/svg/24/ic_done_24px.svg",3,FALSE,"Display Inventory Parameters or Product reporting codes")
			CALL fgl_dialog_setactionlabel("Change","Change","{CONTEXT}/public/querix/icon/svg/24/ic_edit_24px.svg",4,FALSE,"Change Inventory Parameters or Product reporting codes")	
			IF disp_parm() THEN 
				CALL DIALOG.SetActionHidden("Add Parameters",TRUE)
			ELSE 
				CALL DIALOG.SetActionHidden("Change",TRUE)
			END IF

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "Add Parameters"  # " Add Parameters"  		
			IF add_parm() THEN 
				OPEN WINDOW i173 with FORM "I173" 
				 CALL windecoration_i("I173") -- albo kd-758 
				CALL change_ref() 
				CLOSE WINDOW i173 
				CALL DIALOG.SetActionHidden("Add Parameters",TRUE)
				CALL DIALOG.SetActionHidden("Change",FALSE)
			END IF 
			IF disp_parm() THEN 
			END IF 

		ON ACTION "Display"  # " DISPLAY Parameters"
			IF disp_parm() THEN 

				MENU " Reference Description" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","IZP","menu-Reference Description-1") -- albo kd-505 
						CALL fgl_dialog_setactionlabel("Report Codes","Report Codes","{CONTEXT}/public/querix/icon/svg/24/ic_done_24px.svg",4,FALSE,"Display Product reporting codes")

					ON ACTION "WEB-HELP" -- albo kd-372 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "Report Codes"  # Display Report Codes
						OPEN WINDOW i173 with FORM "I173" 
						 CALL windecoration_i("I173") -- albo kd-758 
						CALL disp_ref() 
						CALL eventsuspend()#let l_msgresp = kandoomsg("U",1,"") 
						CLOSE WINDOW i173 
						EXIT MENU 

					ON ACTION "Exit"
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						EXIT MENU 

				END MENU 
			END IF 

		ON ACTION "Change"

			MENU " Change" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IZP","menu-Change-1") -- albo kd-505 
					CALL fgl_dialog_setactionlabel("Parameters","Parameters","{CONTEXT}/public/querix/icon/svg/24/ic_edit_24px.svg",2,FALSE,"Change Inventory Parameters")
					CALL fgl_dialog_setactionlabel("Report Codes","Report Codes","{CONTEXT}/public/querix/icon/svg/24/ic_edit_24px.svg",3,FALSE,"Change Product reporting codes")

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "Parameters"  # " Change IN Parameters"
					CALL change_parm() 
					EXIT MENU 

				ON ACTION "Report Codes" 
					OPEN WINDOW i173 with FORM "I173" 
					 CALL windecoration_i("I173") -- albo kd-758 
					CALL change_ref() 
					CLOSE WINDOW i173 
					EXIT MENU 

				ON ACTION "Exit"
					LET int_flag = FALSE 
					LET quit_flag = FALSE 
					EXIT MENU 

			END MENU 

			IF disp_parm() THEN 
			END IF 

		ON ACTION "Exit"  # " Exit TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW i145 

END MAIN 


####################################################################
# FUNCTION add_parm()
#
#
####################################################################
FUNCTION add_parm() 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_seq_num SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	INITIALIZE glob_rec_inparms.* TO NULL 
	MESSAGE kandoomsg2("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	LET glob_rec_inparms.cycle_num = 1 
	LET glob_rec_inparms.cost_ind = "W" 
	LET glob_rec_inparms.gl_post_flag = modu_yes_flag 
	LET glob_rec_inparms.gl_del_flag = modu_no_flag 
	LET glob_rec_inparms.auto_trans_flag = modu_yes_flag 
	LET glob_rec_inparms.next_trans_num = 1 
	LET glob_rec_inparms.auto_adjust_flag = modu_yes_flag 
	LET glob_rec_inparms.next_adjust_num = 1 
	LET glob_rec_inparms.auto_issue_flag = modu_yes_flag 
	LET glob_rec_inparms.next_issue_num = 1 
	LET glob_rec_inparms.auto_recpt_flag = modu_yes_flag 
	LET glob_rec_inparms.next_recpt_num = 1 
	LET glob_rec_inparms.auto_class_flag = modu_yes_flag 
	LET glob_rec_inparms.next_class_num = 1 
	LET glob_rec_inparms.last_post_date = TODAY 
	LET glob_rec_inparms.last_cost_date = TODAY 
	LET glob_rec_inparms.last_del_date = TODAY 
	LET glob_rec_inparms.dec_place_num = 2 
	LET glob_rec_inparms.int_place_num = 8 

	INPUT BY NAME 
	glob_rec_inparms.mast_ware_code, 
	glob_rec_inparms.ibt_ware_code, 
	glob_rec_inparms.cycle_num, 
	glob_rec_inparms.cost_ind, 
	glob_rec_inparms.inv_journal_code, 
	glob_rec_inparms.gl_post_flag, 
	glob_rec_inparms.gl_del_flag, 
	glob_rec_inparms.rec_post_flag, 
	glob_rec_inparms.auto_trans_flag, 
	glob_rec_inparms.next_trans_num, 
	glob_rec_inparms.auto_adjust_flag, 
	glob_rec_inparms.next_adjust_num, 
	glob_rec_inparms.auto_issue_flag, 
	glob_rec_inparms.next_issue_num, 
	glob_rec_inparms.auto_recpt_flag, 
	glob_rec_inparms.next_recpt_num, 
	glob_rec_inparms.auto_class_flag, 
	glob_rec_inparms.next_class_num, 
	glob_rec_inparms.dec_place_num, 
	glob_rec_inparms.int_place_num, 
	glob_rec_inparms.last_post_date, 
	glob_rec_inparms.last_del_date, 
	glob_rec_inparms.last_cost_date WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZP","input-glob_rec_inparms-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 


		ON KEY (control-b) infield (inv_journal_code) 
			LET glob_rec_inparms.inv_journal_code = show_jour(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD inv_journal_code 

		ON KEY (control-b) infield (mast_ware_code) 
			LET glob_rec_inparms.mast_ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD mast_ware_code 

		ON KEY (control-b) infield (ibt_ware_code) 
			LET glob_rec_inparms.ibt_ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD ibt_ware_code 

		AFTER FIELD mast_ware_code 
			IF glob_rec_inparms.mast_ware_code IS NULL THEN 
				ERROR kandoomsg2("I",9029,"") 
				#9029 Warehouse must be entered"
				NEXT FIELD mast_ware_code 
			ELSE 
				SELECT desc_text 
				INTO l_rec_warehouse.desc_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_inparms.mast_ware_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("I",9030,"") 
					#9030" Warehouse does NOT exist - Try Window"
					NEXT FIELD mast_ware_code 
				ELSE 
					DISPLAY l_rec_warehouse.desc_text 
					TO warehouse.desc_text 

				END IF 
			END IF 

		AFTER FIELD ibt_ware_code 
			IF glob_rec_inparms.ibt_ware_code IS NULL THEN 
				ERROR kandoomsg2("I",9029,"") 
				#9029 Warehouse must be entered"
				NEXT FIELD ibt_ware_code 
			ELSE 
				SELECT desc_text 
				INTO modu_tr_ware_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_inparms.ibt_ware_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("I",9030,"") 
					#9030" Warehouse does NOT exist - Try Window"
					NEXT FIELD ibt_ware_code 
				ELSE 
					DISPLAY modu_tr_ware_text TO tr_ware_text 

				END IF 
			END IF 

		AFTER FIELD inv_journal_code 
			LET l_seq_num = 0 
			IF glob_rec_inparms.inv_journal_code IS NULL THEN 
				ERROR kandoomsg2("I",9035,"") 
				#9035 Inventory Journal must be Entered
				NEXT FIELD inv_journal_code 
			ELSE 
				SELECT desc_text 
				INTO l_rec_journal.desc_text 
				FROM journal 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_code = glob_rec_inparms.inv_journal_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("I",9027,"") 
					#9027 Inventory Journal does NOT exist - Try Window"
					NEXT FIELD inv_journal_code 
				ELSE 
					DISPLAY l_rec_journal.desc_text 
					TO journal.desc_text 

				END IF 
			END IF 

		AFTER FIELD auto_trans_flag 
			LET l_seq_num = 1 
			IF glob_rec_inparms.auto_trans_flag IS NULL 
			OR glob_rec_inparms.auto_trans_flag = modu_no_flag THEN 
				LET glob_rec_inparms.auto_trans_flag = modu_no_flag 
				LET glob_rec_inparms.next_trans_num = NULL 
			ELSE 
				LET glob_rec_inparms.next_trans_num = 1 
			END IF 
			DISPLAY BY NAME glob_rec_inparms.auto_trans_flag, 
			glob_rec_inparms.next_trans_num 

		BEFORE FIELD next_trans_num 
			IF glob_rec_inparms.auto_trans_flag = modu_no_flag THEN 
				IF l_seq_num > 1 THEN 
					NEXT FIELD auto_trans_flag 
				ELSE 
					NEXT FIELD auto_adjust_flag 
				END IF 
			END IF 

		AFTER FIELD auto_adjust_flag 
			LET l_seq_num = 2 
			IF glob_rec_inparms.auto_adjust_flag IS NULL 
			OR glob_rec_inparms.auto_adjust_flag = modu_no_flag THEN 
				LET glob_rec_inparms.auto_adjust_flag = modu_no_flag 
				LET glob_rec_inparms.next_adjust_num = NULL 
			ELSE 
				LET glob_rec_inparms.next_adjust_num = 1 
			END IF 
			DISPLAY BY NAME glob_rec_inparms.auto_adjust_flag, 
			glob_rec_inparms.next_adjust_num 

		BEFORE FIELD next_adjust_num 
			IF glob_rec_inparms.auto_adjust_flag != modu_yes_flag THEN 
				IF l_seq_num > 2 THEN 
					NEXT FIELD auto_adjust_flag 
				ELSE 
					NEXT FIELD auto_issue_flag 
				END IF 
			END IF 

		AFTER FIELD auto_issue_flag 
			LET l_seq_num = 3 
			IF glob_rec_inparms.auto_issue_flag IS NULL 
			OR glob_rec_inparms.auto_issue_flag = modu_no_flag THEN 
				LET glob_rec_inparms.auto_issue_flag = modu_no_flag 
				LET glob_rec_inparms.next_issue_num = NULL 
			ELSE 
				LET glob_rec_inparms.next_issue_num = 1 
			END IF 
			DISPLAY BY NAME glob_rec_inparms.auto_issue_flag, 
			glob_rec_inparms.next_issue_num 

		BEFORE FIELD next_issue_num 
			IF glob_rec_inparms.auto_issue_flag != modu_yes_flag THEN 
				IF l_seq_num > 3 THEN 
					NEXT FIELD auto_issue_flag 
				ELSE 
					NEXT FIELD auto_recpt_flag 
				END IF 
			END IF 

		AFTER FIELD auto_recpt_flag 
			LET l_seq_num = 4 
			IF glob_rec_inparms.auto_recpt_flag IS NULL 
			OR glob_rec_inparms.auto_recpt_flag = modu_no_flag THEN 
				LET glob_rec_inparms.auto_recpt_flag = modu_no_flag 
				LET glob_rec_inparms.next_recpt_num = NULL 
			ELSE 
				LET glob_rec_inparms.next_recpt_num = 1 
			END IF 
			DISPLAY BY NAME glob_rec_inparms.auto_recpt_flag, 
			glob_rec_inparms.next_recpt_num 

		BEFORE FIELD next_recpt_num 
			IF glob_rec_inparms.auto_recpt_flag != modu_yes_flag THEN 
				IF l_seq_num > 4 THEN 
					NEXT FIELD auto_recpt_flag 
				ELSE 
					NEXT FIELD auto_class_flag 
				END IF 
			END IF 

		AFTER FIELD auto_class_flag 
			LET l_seq_num = 5 
			IF glob_rec_inparms.auto_class_flag IS NULL 
			OR glob_rec_inparms.auto_class_flag = modu_no_flag THEN 
				LET glob_rec_inparms.auto_class_flag = modu_no_flag 
				LET glob_rec_inparms.next_class_num = NULL 
			ELSE 
				LET glob_rec_inparms.next_class_num = 1 
			END IF 
			DISPLAY BY NAME glob_rec_inparms.auto_class_flag, 
			glob_rec_inparms.next_class_num 

		BEFORE FIELD next_class_num 
			IF glob_rec_inparms.auto_class_flag != modu_yes_flag THEN 
				IF l_seq_num > 5 THEN 
					NEXT FIELD auto_class_flag 
				ELSE 
					NEXT FIELD dec_place_num 
				END IF 
			END IF 

		AFTER FIELD dec_place_num 
			LET l_seq_num = 6 
			IF glob_rec_inparms.dec_place_num IS NULL THEN 
				LET glob_rec_inparms.dec_place_num = 0 
				NEXT FIELD dec_place_num 
			END IF 

		AFTER FIELD int_place_num 
			LET l_seq_num = 7 
			IF glob_rec_inparms.int_place_num IS NULL THEN 
				LET glob_rec_inparms.int_place_num = 6 
				NEXT FIELD int_place_num 
			END IF 
			IF (glob_rec_inparms.int_place_num+glob_rec_inparms.dec_place_num) > 10 THEN 
				ERROR kandoomsg2("I",9028,"") 
				#9028 Stock Quantity has Maximum length of 10 digits
				LET glob_rec_inparms.int_place_num = 10 - glob_rec_inparms.dec_place_num 
				NEXT FIELD dec_place_num 
			END IF 

	END INPUT 

	IF (int_flag OR quit_flag) THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	LET glob_rec_inparms.cost_ind = "W" 
	LET glob_rec_inparms.hist_flag = "Y" 
	LET glob_rec_inparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_inparms.parm_code = "1" 
	INSERT INTO inparms VALUES (glob_rec_inparms.*) 

	RETURN TRUE 
END FUNCTION 



####################################################################
# FUNCTION add_parm()
#
# SELECT max() FROM the prodledg table are very time consuming.
# Code exists so the 'SELECT max' are done only WHERE
# its imperative TO do so. Remove AT own risk.
####################################################################
FUNCTION change_parm() 
	DEFINE l_rec_inparms RECORD LIKE inparms.* 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_auto_temp_flag LIKE inparms.auto_trans_flag 
	DEFINE l_next_temp_num LIKE inparms.next_trans_num 
	DEFINE l_seq_num SMALLINT 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO glob_rec_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	MESSAGE kandoomsg2("U",1070,"Parameter") 
	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME 
	glob_rec_inparms.mast_ware_code, 
	glob_rec_inparms.ibt_ware_code, 
	glob_rec_inparms.cycle_num, 
	glob_rec_inparms.cost_ind, 
	glob_rec_inparms.inv_journal_code, 
	glob_rec_inparms.gl_post_flag, 
	glob_rec_inparms.gl_del_flag, 
	glob_rec_inparms.rec_post_flag, 
	glob_rec_inparms.auto_trans_flag, 
	glob_rec_inparms.next_trans_num, 
	glob_rec_inparms.auto_adjust_flag, 
	glob_rec_inparms.next_adjust_num, 
	glob_rec_inparms.auto_issue_flag, 
	glob_rec_inparms.next_issue_num, 
	glob_rec_inparms.auto_recpt_flag, 
	glob_rec_inparms.next_recpt_num, 
	glob_rec_inparms.auto_class_flag, 
	glob_rec_inparms.next_class_num, 
	glob_rec_inparms.dec_place_num, 
	glob_rec_inparms.int_place_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZP","input-glob_rec_inparms-2") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(inv_journal_code) 
					LET glob_rec_inparms.inv_journal_code = show_jour(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD inv_journal_code 
				WHEN infield(mast_ware_code) 
					LET glob_rec_inparms.mast_ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD mast_ware_code 
				WHEN infield(ibt_ware_code) 
					LET glob_rec_inparms.ibt_ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD ibt_ware_code 
			END CASE 

		AFTER FIELD mast_ware_code 
			IF glob_rec_inparms.mast_ware_code IS NULL THEN 
				ERROR kandoomsg2("I",9029,"") 
				#9029 Warehouse must be entered"
				CLEAR warehouse.desc_text 
				NEXT FIELD mast_ware_code 
			ELSE 
				SELECT desc_text 
				INTO l_rec_warehouse.desc_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_inparms.mast_ware_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("I",9030,"") 
					#9030" Warehouse does NOT exist - Try Window"
					CLEAR warehouse.desc_text 
					NEXT FIELD mast_ware_code 
				ELSE 
					DISPLAY l_rec_warehouse.desc_text 
					TO warehouse.desc_text 
				END IF 
			END IF 

		AFTER FIELD ibt_ware_code 
			IF glob_rec_inparms.ibt_ware_code IS NULL THEN 
				ERROR kandoomsg2("I",9029,"") 
				#9029 Warehouse must be entered"
				NEXT FIELD ibt_ware_code 
			ELSE 
				SELECT desc_text 
				INTO modu_tr_ware_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_inparms.ibt_ware_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("I",9030,"") 
					#9030" Warehouse does NOT exist - Try Window"
					NEXT FIELD ibt_ware_code 
				ELSE 
					DISPLAY modu_tr_ware_text TO tr_ware_text 
				END IF 
			END IF 

		AFTER FIELD inv_journal_code 
			LET l_seq_num = 0 
			IF glob_rec_inparms.inv_journal_code IS NULL THEN 
				ERROR kandoomsg2("I",9035,"") 
				#9035 Inventory Journal must be Entered
				CLEAR journal.desc_text 
				NEXT FIELD inv_journal_code 
			ELSE 
				SELECT desc_text 
				INTO l_rec_journal.desc_text 
				FROM journal 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_code = glob_rec_inparms.inv_journal_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("I",9027,"") 
					#9027 Inventory Journal does NOT exist - Try Window"
					CLEAR journal.desc_text 
					NEXT FIELD inv_journal_code 
				ELSE 
					DISPLAY l_rec_journal.desc_text 
					TO journal.desc_text 
				END IF 
			END IF 

		BEFORE FIELD auto_trans_flag 
			LET l_auto_temp_flag = glob_rec_inparms.auto_trans_flag 

		AFTER FIELD auto_trans_flag 
			LET l_seq_num = 1 
			IF glob_rec_inparms.auto_trans_flag IS NULL THEN 
				ERROR kandoomsg2("U",3,"") 
				#U003 Valid Responses are (Y)es OR (N)o"
				LET glob_rec_inparms.auto_trans_flag = l_auto_temp_flag 
				NEXT FIELD auto_trans_flag 
			END IF 
			IF l_auto_temp_flag != glob_rec_inparms.auto_trans_flag THEN 
				IF glob_rec_inparms.auto_trans_flag = modu_yes_flag THEN 
					SELECT max(source_num) 
					INTO glob_rec_inparms.next_trans_num 
					FROM prodledg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND trantype_ind = "T" 
				ELSE 
					LET glob_rec_inparms.next_trans_num = NULL 
					CLEAR next_trans_num 
				END IF 
			END IF 

		BEFORE FIELD next_trans_num 
			IF glob_rec_inparms.auto_trans_flag = modu_yes_flag THEN 
				LET l_next_temp_num = glob_rec_inparms.next_trans_num 
			ELSE 
				IF l_seq_num > 1 THEN 
					NEXT FIELD auto_trans_flag 
				ELSE 
					NEXT FIELD auto_adjust_flag 
				END IF 
			END IF 

		AFTER FIELD next_trans_num 
			IF l_next_temp_num != glob_rec_inparms.next_trans_num 
			OR glob_rec_inparms.next_trans_num IS NULL THEN 
				SELECT max(source_num) 
				INTO l_next_temp_num 
				FROM prodledg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trantype_ind = "T" 
				IF glob_rec_inparms.next_trans_num <= l_next_temp_num 
				OR glob_rec_inparms.next_trans_num IS NULL THEN 
					ERROR kandoomsg2("I",9031,l_next_temp_num) 
					#9031 "Next Transfer Number must be Greater than: ???? "
					LET glob_rec_inparms.next_trans_num = l_next_temp_num + 1 
					NEXT FIELD next_trans_num 
				END IF 
			END IF 

		BEFORE FIELD auto_adjust_flag 
			LET l_auto_temp_flag = glob_rec_inparms.auto_adjust_flag 

		AFTER FIELD auto_adjust_flag 
			LET l_seq_num = 2 
			IF glob_rec_inparms.auto_adjust_flag IS NULL THEN 
				ERROR kandoomsg2("U",3,"") 
				#U003 " Valid Responses are (Y)es OR (N)o"
				LET glob_rec_inparms.auto_adjust_flag = l_auto_temp_flag 
				NEXT FIELD auto_adjust_flag 
			END IF 
			IF l_auto_temp_flag != glob_rec_inparms.auto_adjust_flag THEN 
				IF glob_rec_inparms.auto_adjust_flag = modu_yes_flag THEN 
					SELECT max(source_num) 
					INTO glob_rec_inparms.next_adjust_num 
					FROM prodledg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND trantype_ind = "A" 
				ELSE 
					LET glob_rec_inparms.next_adjust_num = NULL 
					CLEAR next_adjust_num 
				END IF 
			END IF 

		BEFORE FIELD next_adjust_num 
			IF glob_rec_inparms.auto_adjust_flag = modu_yes_flag THEN 
				LET l_next_temp_num = glob_rec_inparms.next_adjust_num 
			ELSE 
				IF l_seq_num > 2 THEN 
					NEXT FIELD auto_adjust_flag 
				ELSE 
					NEXT FIELD auto_issue_flag 
				END IF 
			END IF 

		AFTER FIELD next_adjust_num 
			IF l_next_temp_num != glob_rec_inparms.next_adjust_num 
			OR glob_rec_inparms.next_adjust_num IS NULL THEN 
				SELECT max(source_num) 
				INTO l_next_temp_num 
				FROM prodledg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trantype_ind = "A" 
				IF glob_rec_inparms.next_adjust_num <= l_next_temp_num 
				OR glob_rec_inparms.next_adjust_num IS NULL THEN 
					ERROR kandoomsg2("I",9032,l_next_temp_num) 
					#9032 "Number must be greater THEN ???"
					LET glob_rec_inparms.next_adjust_num = l_next_temp_num + 1 
					NEXT FIELD next_adjust_num 
				END IF 
			END IF 

		BEFORE FIELD auto_issue_flag 
			LET l_auto_temp_flag = glob_rec_inparms.auto_issue_flag 

		AFTER FIELD auto_issue_flag 
			LET l_seq_num = 3 
			IF glob_rec_inparms.auto_issue_flag IS NULL THEN 
				ERROR kandoomsg2("U",3,"") 
				#U003 " Valid Responses are (Y)es OR (N)o"
				LET glob_rec_inparms.auto_issue_flag = l_auto_temp_flag 
				NEXT FIELD auto_issue_flag 
			END IF 
			IF l_auto_temp_flag != glob_rec_inparms.auto_issue_flag THEN 
				IF glob_rec_inparms.auto_issue_flag = modu_yes_flag THEN 
					SELECT max(source_num) 
					INTO glob_rec_inparms.next_issue_num 
					FROM prodledg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND trantype_ind = "I" 
				ELSE 
					LET glob_rec_inparms.next_issue_num = NULL 
					CLEAR next_issue_num 
				END IF 
			END IF 

		BEFORE FIELD next_issue_num 
			IF glob_rec_inparms.auto_issue_flag = modu_yes_flag THEN 
				LET l_next_temp_num = glob_rec_inparms.next_issue_num 
			ELSE 
				IF l_seq_num > 3 THEN 
					NEXT FIELD auto_issue_flag 
				ELSE 
					NEXT FIELD auto_recpt_flag 
				END IF 
			END IF 
		AFTER FIELD next_issue_num 
			IF l_next_temp_num != glob_rec_inparms.next_issue_num 
			OR glob_rec_inparms.next_issue_num IS NULL THEN 
				SELECT max(source_num) 
				INTO l_next_temp_num 
				FROM prodledg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trantype_ind = "I" 
				IF glob_rec_inparms.next_issue_num <= l_next_temp_num 
				OR glob_rec_inparms.next_issue_num IS NULL THEN 
					ERROR kandoomsg2("I",9033,l_next_temp_num) 
					#9033 "Next Issue Number must be greater THEN ???"
					LET glob_rec_inparms.next_issue_num = l_next_temp_num + 1 
					NEXT FIELD next_issue_num 
				END IF 
			END IF 

		BEFORE FIELD auto_recpt_flag 
			LET l_auto_temp_flag = glob_rec_inparms.auto_recpt_flag 

		AFTER FIELD auto_recpt_flag 
			LET l_seq_num = 4 
			IF glob_rec_inparms.auto_recpt_flag IS NULL THEN 
				ERROR kandoomsg2("U",3,"") 
				#U003 " Valid Responses are (Y)es OR (N)o"
				LET glob_rec_inparms.auto_recpt_flag = l_auto_temp_flag 
				NEXT FIELD auto_recpt_flag 
			END IF 
			IF l_auto_temp_flag != glob_rec_inparms.auto_recpt_flag THEN 
				IF glob_rec_inparms.auto_recpt_flag = modu_yes_flag THEN 
					SELECT max(source_num) 
					INTO glob_rec_inparms.next_recpt_num 
					FROM prodledg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND trantype_ind = "R" 
				ELSE 
					LET glob_rec_inparms.next_recpt_num = NULL 
					CLEAR next_recpt_num 
				END IF 
			END IF 

		BEFORE FIELD next_recpt_num 
			IF glob_rec_inparms.auto_recpt_flag = modu_yes_flag THEN 
				LET l_next_temp_num = glob_rec_inparms.next_recpt_num 
			ELSE 
				IF l_seq_num > 4 THEN 
					NEXT FIELD auto_recpt_flag 
				ELSE 
					NEXT FIELD auto_class_flag 
				END IF 
			END IF 

		AFTER FIELD next_recpt_num 
			IF l_next_temp_num != glob_rec_inparms.next_recpt_num 
			OR glob_rec_inparms.next_recpt_num IS NULL THEN 
				SELECT max(source_num) 
				INTO l_next_temp_num 
				FROM prodledg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trantype_ind = "R" 
				IF glob_rec_inparms.next_recpt_num <= l_next_temp_num 
				OR glob_rec_inparms.next_recpt_num IS NULL THEN 
					ERROR kandoomsg2("I",9034,l_next_temp_num) 
					#9034 "Receipt Number must be greater THEN ???"
					LET glob_rec_inparms.next_recpt_num = l_next_temp_num + 1 
					NEXT FIELD next_recpt_num 
				END IF 
			END IF 

		BEFORE FIELD auto_class_flag 
			LET l_auto_temp_flag = glob_rec_inparms.auto_class_flag 

		AFTER FIELD auto_class_flag 
			LET l_seq_num = 5 
			IF glob_rec_inparms.auto_class_flag IS NULL THEN 
				ERROR kandoomsg2("U",3,"") 
				#U003 " Valid Responses are (Y)es OR (N)o"
				LET glob_rec_inparms.auto_class_flag = l_auto_temp_flag 
				NEXT FIELD auto_class_flag 
			END IF 
			IF l_auto_temp_flag != glob_rec_inparms.auto_class_flag THEN 
				IF glob_rec_inparms.auto_class_flag = modu_yes_flag THEN 
					SELECT max(source_num) + 1 
					INTO glob_rec_inparms.next_class_num 
					FROM prodledg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND trantype_ind = "X" 
				ELSE 
					LET glob_rec_inparms.next_class_num = NULL 
					CLEAR next_class_num 
				END IF 
			END IF 

		BEFORE FIELD next_class_num 
			IF glob_rec_inparms.auto_class_flag = modu_yes_flag THEN 
				LET l_next_temp_num = glob_rec_inparms.next_class_num 
			ELSE 
				IF l_seq_num > 5 THEN 
					NEXT FIELD auto_class_flag 
				ELSE 
					NEXT FIELD dec_place_num 
				END IF 
			END IF 

		AFTER FIELD next_class_num 
			IF l_next_temp_num != glob_rec_inparms.next_class_num 
			OR glob_rec_inparms.next_class_num IS NULL THEN 
				SELECT max(source_num) 
				INTO l_next_temp_num 
				FROM prodledg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trantype_ind = "X" 
				IF glob_rec_inparms.next_class_num <= l_next_temp_num 
				OR glob_rec_inparms.next_class_num IS NULL THEN 
					ERROR kandoomsg2("I",9034,l_next_temp_num) 
					#9034 "Receipt Number must be greater THEN ???"
					LET glob_rec_inparms.next_class_num = l_next_temp_num + 1 
					NEXT FIELD next_class_num 
				END IF 
			END IF 

		AFTER FIELD dec_place_num 
			LET l_seq_num = 6 
			IF glob_rec_inparms.dec_place_num IS NULL THEN 
				LET glob_rec_inparms.dec_place_num = 0 
				NEXT FIELD dec_place_num 
			END IF 
			LET glob_rec_inparms.int_place_num = 10 - glob_rec_inparms.dec_place_num 

		AFTER FIELD int_place_num 
			IF glob_rec_inparms.int_place_num IS NULL THEN 
				LET glob_rec_inparms.int_place_num = 6 
				NEXT FIELD int_place_num 
			END IF 
			IF (glob_rec_inparms.int_place_num+glob_rec_inparms.dec_place_num)> 10 THEN 
				ERROR kandoomsg2("I",9028,"") 
				#9028 Stock Quantity has Maximum length of 10 digits
				LET glob_rec_inparms.dec_place_num = 10 - glob_rec_inparms.int_place_num 
				NEXT FIELD dec_place_num 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET glob_rec_inparms.auto_trans_flag = 
				xlate_from(glob_rec_inparms.auto_trans_flag) 
				LET glob_rec_inparms.auto_adjust_flag = 
				xlate_from(glob_rec_inparms.auto_adjust_flag) 
				LET glob_rec_inparms.auto_issue_flag = 
				xlate_from(glob_rec_inparms.auto_issue_flag) 
				LET glob_rec_inparms.auto_recpt_flag = 
				xlate_from(glob_rec_inparms.auto_recpt_flag) 
				LET glob_rec_inparms.auto_class_flag = 
				xlate_from(glob_rec_inparms.auto_class_flag) 
				LET glob_rec_inparms.gl_post_flag = 
				xlate_from(glob_rec_inparms.gl_post_flag) 
				LET glob_rec_inparms.gl_del_flag = 
				xlate_from(glob_rec_inparms.gl_del_flag) 
			END IF 

	END INPUT 

	IF not(int_flag OR quit_flag) THEN 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(l_err_message, status) = "N" THEN 
			RETURN 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			SELECT * INTO l_rec_inparms.* FROM inparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
			IF l_rec_inparms.next_trans_num > glob_rec_inparms.next_trans_num 
			OR l_rec_inparms.next_issue_num > glob_rec_inparms.next_issue_num 
			OR l_rec_inparms.next_adjust_num > glob_rec_inparms.next_adjust_num 
			OR l_rec_inparms.next_recpt_num > glob_rec_inparms.next_recpt_num 
			OR l_rec_inparms.next_class_num > glob_rec_inparms.next_class_num THEN 
				ROLLBACK WORK 
				ERROR kandoomsg2("U",7050,"") 
				#7050 Parameter VALUES have been updated since changes.
				RETURN 
			END IF 
			LET l_err_message = "IZP - Update parameters" 
			UPDATE inparms 
			SET * = glob_rec_inparms.* 
			WHERE parm_code = "1" 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		COMMIT WORK 
		WHENEVER ERROR stop 
	ELSE 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 
END FUNCTION 



####################################################################
# FUNCTION disp_parm()
#
#
####################################################################
FUNCTION disp_parm() 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 

	CLEAR FORM 
	SELECT * INTO glob_rec_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		RETURN FALSE 
	END IF 

	LET glob_rec_inparms.auto_trans_flag = xlate_to(glob_rec_inparms.auto_trans_flag) 
	LET glob_rec_inparms.auto_adjust_flag = xlate_to(glob_rec_inparms.auto_adjust_flag) 
	LET glob_rec_inparms.auto_issue_flag = xlate_to(glob_rec_inparms.auto_issue_flag) 
	LET glob_rec_inparms.auto_recpt_flag = xlate_to(glob_rec_inparms.auto_recpt_flag) 
	LET glob_rec_inparms.auto_class_flag = xlate_to(glob_rec_inparms.auto_class_flag) 
	LET glob_rec_inparms.gl_post_flag = xlate_to(glob_rec_inparms.gl_post_flag) 
	LET glob_rec_inparms.gl_del_flag = xlate_to(glob_rec_inparms.gl_del_flag) 
	SELECT desc_text INTO modu_tr_ware_text FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = glob_rec_inparms.ibt_ware_code 
	IF status = notfound THEN 
		LET modu_tr_ware_text = "" 
	END IF 
	SELECT desc_text 
	INTO l_rec_warehouse.desc_text 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = glob_rec_inparms.mast_ware_code 
	IF status = notfound THEN 
		LET l_rec_warehouse.desc_text = "" 
	END IF 
	SELECT desc_text INTO l_rec_journal.desc_text FROM journal 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = glob_rec_inparms.inv_journal_code 
	IF status = notfound THEN 
		LET l_rec_journal.desc_text = "" 
	END IF 
	DISPLAY 
	glob_rec_inparms.mast_ware_code, 
	glob_rec_inparms.ibt_ware_code, 
	modu_tr_ware_text, 
	glob_rec_inparms.auto_trans_flag, 
	glob_rec_inparms.next_trans_num, 
	glob_rec_inparms.auto_adjust_flag, 
	glob_rec_inparms.next_adjust_num, 
	glob_rec_inparms.auto_issue_flag, 
	glob_rec_inparms.next_issue_num, 
	glob_rec_inparms.auto_recpt_flag, 
	glob_rec_inparms.next_recpt_num, 
	glob_rec_inparms.auto_class_flag, 
	glob_rec_inparms.next_class_num, 
	glob_rec_inparms.last_post_date, 
	glob_rec_inparms.last_cost_date, 
	glob_rec_inparms.last_del_date, 
	glob_rec_inparms.inv_journal_code, 
	glob_rec_inparms.gl_post_flag, 
	glob_rec_inparms.gl_del_flag, 
	glob_rec_inparms.rec_post_flag, 
	glob_rec_inparms.dec_place_num, 
	glob_rec_inparms.int_place_num, 
	glob_rec_inparms.cost_ind, 
	glob_rec_inparms.cycle_num 

	TO mast_ware_code, 
	ibt_ware_code, 
	tr_ware_text, 
	auto_trans_flag, 
	next_trans_num, 
	auto_adjust_flag, 
	next_adjust_num, 
	auto_issue_flag, 
	next_issue_num, 
	auto_recpt_flag, 
	next_recpt_num, 
	auto_class_flag, 
	next_class_num, 
	last_post_date, 
	last_cost_date, 
	last_del_date, 
	inv_journal_code, 
	gl_post_flag, 
	gl_del_flag, 
	rec_post_flag, 
	dec_place_num, 
	int_place_num, 
	cost_ind, 
	cycle_num 


	DISPLAY l_rec_warehouse.desc_text, 
	l_rec_journal.desc_text 
	TO warehouse.desc_text, 
	journal.desc_text 

	RETURN TRUE 
END FUNCTION 


####################################################################
# FUNCTION change_ref()
#
#
####################################################################
FUNCTION change_ref() 
	DEFINE l_seq_num SMALLINT 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	MESSAGE kandoomsg2("U",1020,"Report Code") 
	#1020 Enter Report Code details; OK TO continue.
	INPUT BY NAME 
	glob_rec_inparms.ref1_text, 
	glob_rec_inparms.ref1_ind, 
	glob_rec_inparms.ref2_text, 
	glob_rec_inparms.ref2_ind, 
	glob_rec_inparms.ref3_text, 
	glob_rec_inparms.ref3_ind, 
	glob_rec_inparms.ref4_text, 
	glob_rec_inparms.ref4_ind, 
	glob_rec_inparms.ref5_text, 
	glob_rec_inparms.ref5_ind, 
	glob_rec_inparms.ref6_text, 
	glob_rec_inparms.ref6_ind, 
	glob_rec_inparms.ref7_text, 
	glob_rec_inparms.ref7_ind, 
	glob_rec_inparms.ref8_text, 
	glob_rec_inparms.ref8_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZP","input-glob_rec_inparms-3") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD ref1_text 
			LET l_seq_num = 1 
			IF glob_rec_inparms.ref1_text IS NULL THEN 
				LET glob_rec_inparms.ref1_ind = NULL 
			END IF 
			CALL disp_ref() 

		BEFORE FIELD ref1_ind 
			IF glob_rec_inparms.ref1_text IS NULL THEN 
				IF l_seq_num > 1 THEN 
					NEXT FIELD ref1_text 
				ELSE 
					NEXT FIELD ref2_text 
				END IF 
			END IF 

		AFTER FIELD ref1_ind 
			IF glob_rec_inparms.ref1_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 
				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref1_ind 
			END IF 

		AFTER FIELD ref2_text 
			LET l_seq_num = 2 
			IF glob_rec_inparms.ref2_text IS NULL THEN 
				LET glob_rec_inparms.ref2_ind = NULL 
			END IF 
			CALL disp_ref() 

		BEFORE FIELD ref2_ind 
			IF glob_rec_inparms.ref2_text IS NULL THEN 
				IF l_seq_num > 2 THEN 
					NEXT FIELD ref2_text 
				ELSE 
					NEXT FIELD ref3_text 
				END IF 
			END IF 

		AFTER FIELD ref2_ind 
			IF glob_rec_inparms.ref2_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 
				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref2_ind 
			END IF 

		AFTER FIELD ref3_text 
			LET l_seq_num = 3 
			IF glob_rec_inparms.ref3_text IS NULL THEN 
				LET glob_rec_inparms.ref3_ind = NULL 
			END IF 
			CALL disp_ref() 

		BEFORE FIELD ref3_ind 
			IF glob_rec_inparms.ref3_text IS NULL THEN 
				IF l_seq_num > 3 THEN 
					NEXT FIELD ref3_text 
				ELSE 
					NEXT FIELD ref4_text 
				END IF 
			END IF 

		AFTER FIELD ref3_ind 
			IF glob_rec_inparms.ref3_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 
				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref3_ind 
			END IF 

		AFTER FIELD ref4_text 
			LET l_seq_num = 4 
			IF glob_rec_inparms.ref4_text IS NULL THEN 
				LET glob_rec_inparms.ref4_ind = NULL 
			END IF 
			CALL disp_ref() 

		BEFORE FIELD ref4_ind 
			IF glob_rec_inparms.ref4_text IS NULL THEN 
				IF l_seq_num > 4 THEN 
					NEXT FIELD ref4_text 
				ELSE 
					NEXT FIELD ref5_text 
				END IF 
			END IF 

		AFTER FIELD ref4_ind 
			IF glob_rec_inparms.ref4_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 
				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref4_ind 
			END IF 

		AFTER FIELD ref5_text 
			LET l_seq_num = 5 
			IF glob_rec_inparms.ref5_text IS NULL THEN 
				LET glob_rec_inparms.ref5_ind = NULL 
			END IF 
			CALL disp_ref() 

		BEFORE FIELD ref5_ind 
			IF glob_rec_inparms.ref5_text IS NULL THEN 
				IF l_seq_num > 5 THEN 
					NEXT FIELD ref5_text 
				ELSE 
					NEXT FIELD ref6_text 
				END IF 
			END IF 

		AFTER FIELD ref5_ind 
			IF glob_rec_inparms.ref5_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 
				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref5_ind 
			END IF 

		AFTER FIELD ref6_text 
			LET l_seq_num = 6 
			IF glob_rec_inparms.ref6_text IS NULL THEN 
				LET glob_rec_inparms.ref6_ind = NULL 
			END IF 
			CALL disp_ref() 

		BEFORE FIELD ref6_ind 
			IF glob_rec_inparms.ref6_text IS NULL THEN 
				IF l_seq_num > 6 THEN 
					NEXT FIELD ref6_text 
				ELSE 
					NEXT FIELD ref7_text 
				END IF 
			END IF 

		AFTER FIELD ref6_ind 
			IF glob_rec_inparms.ref6_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 
				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref6_ind 
			END IF 

		AFTER FIELD ref7_text 
			LET l_seq_num = 7 
			IF glob_rec_inparms.ref7_text IS NULL THEN 
				LET glob_rec_inparms.ref7_ind = NULL 
			END IF 
			CALL disp_ref() 

		BEFORE FIELD ref7_ind 
			IF glob_rec_inparms.ref7_text IS NULL THEN 
				IF l_seq_num > 7 THEN 
					NEXT FIELD ref7_text 
				ELSE 
					NEXT FIELD ref8_text 
				END IF 
			END IF 

		AFTER FIELD ref7_ind 
			IF glob_rec_inparms.ref7_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 
				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref7_ind 
			END IF 

		AFTER FIELD ref8_text 
			LET l_seq_num = 8 
			IF glob_rec_inparms.ref8_text IS NULL THEN 
				LET glob_rec_inparms.ref8_ind = NULL 
			END IF 
			CALL disp_ref()

		BEFORE FIELD ref8_ind 
			IF glob_rec_inparms.ref8_text IS NULL THEN 
				EXIT INPUT 
			END IF 

		AFTER FIELD ref8_ind 
			IF glob_rec_inparms.ref8_ind IS NULL THEN 
				ERROR kandoomsg2("A",9023,"") 
				#9023" Validation Indicator must be Entered "
				NEXT FIELD ref8_ind 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(l_err_message, status) = "N" THEN 
			RETURN 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET l_err_message = "IZP - Update Parameters" 
			UPDATE inparms 
			SET ref1_text = glob_rec_inparms.ref1_text, 
			ref2_text = glob_rec_inparms.ref2_text, 
			ref3_text = glob_rec_inparms.ref3_text, 
			ref4_text = glob_rec_inparms.ref4_text, 
			ref5_text = glob_rec_inparms.ref5_text, 
			ref6_text = glob_rec_inparms.ref6_text, 
			ref7_text = glob_rec_inparms.ref7_text, 
			ref8_text = glob_rec_inparms.ref8_text, 
			ref1_ind = glob_rec_inparms.ref1_ind, 
			ref2_ind = glob_rec_inparms.ref2_ind, 
			ref3_ind = glob_rec_inparms.ref3_ind, 
			ref4_ind = glob_rec_inparms.ref4_ind, 
			ref5_ind = glob_rec_inparms.ref5_ind, 
			ref6_ind = glob_rec_inparms.ref6_ind, 
			ref7_ind = glob_rec_inparms.ref7_ind, 
			ref8_ind = glob_rec_inparms.ref8_ind 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 
END FUNCTION 


####################################################################
# FUNCTION disp_ref()
#
#
####################################################################
FUNCTION disp_ref() 

	DISPLAY BY NAME 
	glob_rec_inparms.ref1_text, 
	glob_rec_inparms.ref2_text, 
	glob_rec_inparms.ref3_text, 
	glob_rec_inparms.ref4_text, 
	glob_rec_inparms.ref5_text, 
	glob_rec_inparms.ref6_text, 
	glob_rec_inparms.ref7_text, 
	glob_rec_inparms.ref8_text, 
	glob_rec_inparms.ref1_ind, 
	glob_rec_inparms.ref2_ind, 
	glob_rec_inparms.ref3_ind, 
	glob_rec_inparms.ref4_ind, 
	glob_rec_inparms.ref5_ind, 
	glob_rec_inparms.ref6_ind, 
	glob_rec_inparms.ref7_ind, 
	glob_rec_inparms.ref8_ind 

END FUNCTION 
