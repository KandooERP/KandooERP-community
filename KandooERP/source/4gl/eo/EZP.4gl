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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EZ_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EZP_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
#
#
###########################################################################
DEFINE modu_rec_holdreas RECORD LIKE holdreas.* 
DEFINE modu_temp_text VARCHAR(200) 
###########################################################################
# FUNCTION EZP_main()
#
# EZP Enhanced Order Entry Parameters
# allows the user TO enter AND maintain EO Setup Parameters
###########################################################################
FUNCTION EZP_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EZP") -- albo 

	OPEN WINDOW E101 with FORM "E101" 
	 CALL windecoration_e("E101") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING glob_rec_opparms.*

	#NOTE: table must only hold ONE record
	#only one operation IS available at a time. Either ADD , if table IS empty OR CHANGE, if table stores one record
	MENU " parameters" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","EZP","menu-Parameters-1") -- albo kd-502 
			IF disp_parm() THEN 
				HIDE option "Add" 
			ELSE 
				HIDE option "Change" 
			END IF 
 
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "Add"	#COMMAND "Add" " Add Parameters"
			CALL add_parm() 
			IF disp_parm() THEN 
				HIDE option "Add" 
				SHOW option "Change" 
			END IF 

		ON ACTION "Settings"		#COMMAND "Change" " Change Parameters"
			CALL change_parm() 
			CALL disp_parm() #returns -Y/N ???? 

		ON ACTION "Exit"	#COMMAND KEY(INTERRUPT,"E") "Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW E101 
END FUNCTION
###########################################################################
# END FUNCTION EZP_main()
###########################################################################


###########################################################################
# FUNCTION disp_parm()
#
#
###########################################################################
FUNCTION disp_parm() 
	--DEFINE glob_rec_opparms RECORD LIKE opparms.* 

	CLEAR FORM 

	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING glob_rec_opparms.*
	IF glob_rec_opparms.key_num IS NULL AND glob_rec_opparms.cmpy_code IS NULL THEN  
		CALL fgl_winmessage("Configuration Error - Operational Parameters missing (Program EZP)",kandoomsg2("E",5003,""),"ERROR") #HuHo 2.12.2020: Was "OZP" which we haven't got and I changed it to "EZP"
		RETURN FALSE
	END IF 
		
	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.so_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO so_reason_text 

	END IF 
	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.ps_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO ps_reason_text 

	END IF 
	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.cf_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO cf_reason_text 

	END IF 

	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.cr_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO cr_reason_text 

	END IF 

	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.lim_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO lim_reason_text 

	END IF 

	DISPLAY BY NAME glob_rec_opparms.next_ord_num, 
	glob_rec_opparms.days_pick_num, 
	glob_rec_opparms.max_inv_cycle_num, 
	glob_rec_opparms.cal_available_flag, 
	glob_rec_opparms.show_seg_flag, 
	glob_rec_opparms.sellup_per, 
	glob_rec_opparms.surcharge_amt, 
	glob_rec_opparms.log_flag, 
	glob_rec_opparms.ship_label_ind, 
	glob_rec_opparms.ship_label_qty, 
	glob_rec_opparms.allow_edit_flag, 
	glob_rec_opparms.so_hold_code, 
	glob_rec_opparms.ps_hold_code, 
	glob_rec_opparms.cf_hold_code, 
	glob_rec_opparms.cr_hold_code, 
	glob_rec_opparms.lim_hold_code 

	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION disp_parm()
###########################################################################


###########################################################################
# FUNCTION add_parm()
#
#
###########################################################################
FUNCTION add_parm() 
	DEFINE l_rec_opparms RECORD LIKE opparms.* 

	LET l_rec_opparms.next_ord_num = 0 
	LET l_rec_opparms.days_pick_num = 0 
	LET l_rec_opparms.sellup_per = 0 
	LET l_rec_opparms.surcharge_amt = 0 

	MESSAGE kandoomsg2("U",1070,"") #1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME l_rec_opparms.next_ord_num, 
	l_rec_opparms.days_pick_num, 
	l_rec_opparms.max_inv_cycle_num, 
	l_rec_opparms.cal_available_flag, 
	l_rec_opparms.show_seg_flag, 
	l_rec_opparms.log_flag, 
	l_rec_opparms.ship_label_ind, 
	l_rec_opparms.ship_label_qty, 
	l_rec_opparms.allow_edit_flag, 
	l_rec_opparms.sellup_per, 
	l_rec_opparms.surcharge_amt, 
	l_rec_opparms.so_hold_code, 
	l_rec_opparms.ps_hold_code, 
	l_rec_opparms.cf_hold_code, 
	l_rec_opparms.cr_hold_code, 
	l_rec_opparms.lim_hold_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EZP","input-l_rec_opparms-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield (so_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET l_rec_opparms.so_hold_code = modu_temp_text 
				NEXT FIELD so_hold_code 
			END IF 

		ON ACTION "LOOKUP" infield (ps_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET l_rec_opparms.ps_hold_code = modu_temp_text 
				NEXT FIELD ps_hold_code 
			END IF 

		ON ACTION "LOOKUP" infield (cf_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET l_rec_opparms.cf_hold_code = modu_temp_text 
				NEXT FIELD cf_hold_code 
			END IF 

		ON ACTION "LOOKUP" infield (cr_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET l_rec_opparms.cr_hold_code = modu_temp_text 
				NEXT FIELD cr_hold_code 
			END IF 

		ON ACTION "LOOKUP" infield (lim_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET l_rec_opparms.lim_hold_code = modu_temp_text 
				NEXT FIELD lim_hold_code 
			END IF 


		AFTER FIELD next_ord_num 
			IF l_rec_opparms.next_ord_num <= 0 
			OR l_rec_opparms.next_ord_num IS NULL THEN 
				ERROR kandoomsg2("E",9107,"") # 9107 Next Order Number Must be a Positive Value
				NEXT FIELD next_ord_num 
			END IF 
		AFTER FIELD days_pick_num 
			IF l_rec_opparms.days_pick_num < 0 
			OR l_rec_opparms.days_pick_num IS NULL THEN 
				ERROR kandoomsg2("E",9108,"") # 9108 Days Ahead Picking Must be Zero OR a Positive Value
				NEXT FIELD days_pick_num 
			END IF 

		AFTER FIELD max_inv_cycle_num 
			IF l_rec_opparms.max_inv_cycle_num < 0 OR 
			l_rec_opparms.max_inv_cycle_num IS NULL 
			THEN 
				ERROR kandoomsg2("E",9248,"") # 9248 Number of invoices per cycle must be greater than zero
				NEXT FIELD max_inv_cycle_num 
			END IF 

		AFTER FIELD cal_available_flag 
			IF l_rec_opparms.cal_available_flag = "Y" THEN 
				ERROR kandoomsg2("E",7042,"") 
				# 7042 WARNING : IF you Calculate your AVAILABLE STOCK
				#                by ONHAND - RESERVED THEN there IS the
				#                potential of disrupting the existing
				#                backordering system.
			END IF 

		AFTER FIELD sellup_per 
			IF l_rec_opparms.sellup_per < 0 
			OR l_rec_opparms.sellup_per IS NULL THEN 
				ERROR kandoomsg2("E",9109,"") 		# 9109 Sellup percentage Must be Zero OR a Positive Value
				NEXT FIELD sellup_per 
			END IF 

			IF l_rec_opparms.sellup_per > 100 THEN 
				ERROR kandoomsg2("E",9117,"") 			# 9117 Sellup percentage cannot be more than 100 percent
				NEXT FIELD sellup_per 
			END IF 

		AFTER FIELD surcharge_amt 
			IF l_rec_opparms.surcharge_amt < 0 
			OR l_rec_opparms.surcharge_amt IS NULL THEN 
				ERROR kandoomsg2("E",9110,"") 		# 9110 Surcharge amount Must be Zero OR a Positive Value
				NEXT FIELD surcharge_amt 
			END IF 

		AFTER FIELD ship_label_qty 
			IF l_rec_opparms.ship_label_qty IS NULL 
			OR l_rec_opparms.ship_label_qty < 0 THEN 
				ERROR kandoomsg2("E",9111,"") 	# 9111 Number of labels must be greater than zero.
				NEXT FIELD ship_label_qty 
			END IF 

		AFTER FIELD so_hold_code 
			CLEAR so_reason_text 
			IF l_rec_opparms.so_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_opparms.so_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") 		# 9112 Hold code NOT found - Try Window
					NEXT FIELD so_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO so_reason_text 

				END IF 
			END IF 

		AFTER FIELD ps_hold_code 
			CLEAR ps_reason_text 
			IF l_rec_opparms.ps_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_opparms.ps_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") 		# 9112 Hold code NOT found - Try Window
					NEXT FIELD ps_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO ps_reason_text 

				END IF 
			END IF 

		AFTER FIELD cf_hold_code 
			IF l_rec_opparms.cf_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_opparms.cf_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") 		# 9112 Hold code NOT found - Try Window
					CLEAR cf_reason_text 
					NEXT FIELD cf_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO cf_reason_text 

				END IF 
			ELSE 
				ERROR kandoomsg2("E",9115,"") 	# 9115 Hold code must be entered
				CLEAR cf_reason_text 
				NEXT FIELD cf_hold_code 
			END IF 

		AFTER FIELD cr_hold_code 
			IF l_rec_opparms.cr_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_opparms.cr_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") 	# 9112 Hold code NOT found - Try Window
					CLEAR cr_reason_text 
					NEXT FIELD cr_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO cr_reason_text 

				END IF 
			ELSE 
				ERROR kandoomsg2("E",9115,"") # 9115 Hold code must be entered
				CLEAR cr_reason_text 
				NEXT FIELD cr_hold_code 
			END IF 

		AFTER FIELD lim_hold_code 
			IF l_rec_opparms.lim_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_opparms.lim_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") 	# 9112 Hold code NOT found - Try Window
					CLEAR lim_reason_text 
					NEXT FIELD lim_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO lim_reason_text 

				END IF 
			ELSE 
				ERROR kandoomsg2("E",9115,"") 	# 9115 Hold code must be entered
				CLEAR lim_reason_text 
				NEXT FIELD lim_hold_code 
			END IF 

		AFTER INPUT 

			IF NOT (int_flag OR quit_flag) THEN 
				LET quit_flag = FALSE 
				IF l_rec_opparms.next_ord_num <= 0 
				OR l_rec_opparms.next_ord_num IS NULL THEN 
					ERROR kandoomsg2("E",9107,"") 	# 9107 Next Order Number Must be a Positive Value
					NEXT FIELD next_ord_num 
				END IF 
				IF l_rec_opparms.days_pick_num < 0 
				OR l_rec_opparms.days_pick_num IS NULL THEN 
					ERROR kandoomsg2("E",9108,"") 	# 9108 Days Ahead Picking Must be Zero OR a Positive Value
					NEXT FIELD days_pick_num 
				END IF 
				IF l_rec_opparms.max_inv_cycle_num < 0 OR 
				l_rec_opparms.max_inv_cycle_num IS NULL 
				THEN 
					ERROR kandoomsg2("E",9248,"") 	# 9248 Number of invoices per cycle must be greater than zero
					NEXT FIELD max_inv_cycle_num 
				END IF
				 
				IF l_rec_opparms.sellup_per < 0 
				OR l_rec_opparms.sellup_per IS NULL THEN 
					ERROR kandoomsg2("E",9109,"") 				# 9109 Sellup percentage Must be Zero OR a Positive Value
					NEXT FIELD sellup_per 
				END IF
				 
				IF l_rec_opparms.surcharge_amt < 0 
				OR l_rec_opparms.surcharge_amt IS NULL THEN 
					ERROR kandoomsg2("E",9110,"") 				# 9110 Surcharge amount Must be Zero OR a Positive Value
					NEXT FIELD surcharge_amt 
				END IF 
				
				IF l_rec_opparms.ship_label_qty IS NULL 
				OR l_rec_opparms.ship_label_qty < 0 THEN 
					ERROR kandoomsg2("E",9111,"") 			# 9111 Number of labels must be greater than zero.
					NEXT FIELD ship_label_qty 
				END IF 
				
				IF l_rec_opparms.allow_edit_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered.
					NEXT FIELD allow_edit_flag 
				END IF 
				
				SELECT * FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_opparms.cf_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9115,"") 				# 9115 Hold code must be entered
					NEXT FIELD cf_hold_code 
				END IF 
				
				SELECT * FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_opparms.cr_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9115,"") 		# 9115 Hold code must be entered
					NEXT FIELD cr_hold_code 
				END IF 
				
				SELECT * FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_opparms.lim_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9115,"") # 9115 Hold code must be entered
					NEXT FIELD lim_hold_code 
				END IF 
			END IF 

			IF int_flag OR quit_flag THEN 
				LET quit_flag = FALSE 
				LET int_flag = FALSE 
			ELSE 
				LET l_rec_opparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_opparms.key_num = "1" 
				LET l_rec_opparms.show_seg_flag = xlate_to(l_rec_opparms.show_seg_flag) 
				LET l_rec_opparms.cal_available_flag = xlate_to(l_rec_opparms.cal_available_flag) 
				INSERT INTO opparms VALUES (l_rec_opparms.*) 
			END IF 

	END INPUT 
END FUNCTION 
###########################################################################
# END FUNCTION add_parm()
###########################################################################


###########################################################################
# FUNCTION change_parm()
#
#
###########################################################################
FUNCTION change_parm() 
	DEFINE l_rec_t_opparms RECORD LIKE opparms.* 
	DEFINE l_rec_s_opparms RECORD LIKE opparms.* 
	DEFINE l_next_ord_num LIKE opparms.next_ord_num 
	DEFINE l_err_message STRING 
	
	LET l_rec_s_opparms.* = glob_rec_opparms.* 

	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.so_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO so_reason_text 

	END IF 
	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.ps_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO ps_reason_text 

	END IF 
	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.cf_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO cf_reason_text 

	END IF 
	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.cr_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO cr_reason_text 

	END IF 
	SELECT reason_text 
	INTO modu_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_opparms.lim_hold_code 
	IF status != NOTFOUND THEN 
		DISPLAY modu_rec_holdreas.reason_text 
		TO lim_reason_text 

	END IF 
	MESSAGE kandoomsg2("U",1070,"") #1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME glob_rec_opparms.next_ord_num, 
	glob_rec_opparms.days_pick_num, 
	glob_rec_opparms.max_inv_cycle_num, 
	glob_rec_opparms.cal_available_flag, 
	glob_rec_opparms.show_seg_flag, 
	glob_rec_opparms.log_flag, 
	glob_rec_opparms.ship_label_ind, 
	glob_rec_opparms.ship_label_qty, 
	glob_rec_opparms.allow_edit_flag, 
	glob_rec_opparms.sellup_per, 
	glob_rec_opparms.surcharge_amt, 
	glob_rec_opparms.so_hold_code, 
	glob_rec_opparms.ps_hold_code, 
	glob_rec_opparms.cf_hold_code, 
	glob_rec_opparms.cr_hold_code, 
	glob_rec_opparms.lim_hold_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EZP","input-glob_rec_opparms-2") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 


		ON ACTION "LOOKUP" infield (so_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET glob_rec_opparms.so_hold_code = modu_temp_text 
				NEXT FIELD so_hold_code 
			END IF 

		ON ACTION "LOOKUP" infield (ps_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET glob_rec_opparms.ps_hold_code = modu_temp_text 
				NEXT FIELD ps_hold_code 
			END IF 

		ON ACTION "LOOKUP" infield (cf_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET glob_rec_opparms.cf_hold_code = modu_temp_text 
				NEXT FIELD cf_hold_code 
			END IF 

		ON ACTION "LOOKUP" infield (cr_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET glob_rec_opparms.cr_hold_code = modu_temp_text 
				NEXT FIELD cr_hold_code 
			END IF 

		ON ACTION "LOOKUP" infield (lim_hold_code) 
			LET modu_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF modu_temp_text IS NOT NULL THEN 
				LET glob_rec_opparms.lim_hold_code = modu_temp_text 
				NEXT FIELD lim_hold_code 
			END IF 

		BEFORE FIELD next_ord_num 
			LET l_next_ord_num = glob_rec_opparms.next_ord_num 

		AFTER FIELD next_ord_num 
			IF glob_rec_opparms.next_ord_num <= 0 
			OR glob_rec_opparms.next_ord_num IS NULL THEN 
				ERROR kandoomsg2("E",9107,"") 		# 9107 Next Order Number Must be a Positive Value
				NEXT FIELD next_ord_num 
			END IF 
			IF l_next_ord_num != glob_rec_opparms.next_ord_num THEN 
				SELECT max(order_num) 
				INTO l_next_ord_num 
				FROM orderhead 
				WHERE orderhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_next_ord_num = l_next_ord_num + 1 
			END IF 
			IF glob_rec_opparms.next_ord_num < l_next_ord_num 
			OR glob_rec_opparms.next_ord_num IS NULL THEN 
				ERROR kandoomsg2("E",9116,l_next_ord_num) 	#9116 New ORDER number cannot be less than
				LET glob_rec_opparms.next_ord_num = l_next_ord_num 
				NEXT FIELD next_ord_num 
			END IF 

		AFTER FIELD days_pick_num 
			IF glob_rec_opparms.days_pick_num < 0 
			OR glob_rec_opparms.days_pick_num IS NULL THEN 
				ERROR kandoomsg2("E",9108,"") 	# 9108 Days Ahead Picking Must be Zero OR a Positive Value
				NEXT FIELD days_pick_num 
			END IF 

		AFTER FIELD max_inv_cycle_num 
			IF glob_rec_opparms.max_inv_cycle_num < 0 OR 
			glob_rec_opparms.max_inv_cycle_num IS NULL 
			THEN 
				ERROR kandoomsg2("E",9248,"") 		# 9248 Number of invoices per cycle must be greater than zero
				NEXT FIELD max_inv_cycle_num 
			END IF 


		AFTER FIELD cal_available_flag 
			IF glob_rec_opparms.cal_available_flag = "Y" THEN 
				ERROR kandoomsg2("E",7042,"") 
				# 7042 WARNING : IF you Calculate your AVAILABLE STOCK
				#                by ONHAND - RESERVED THEN there IS the
				#                potential of disrupting the existing
				#                backordering system.
			END IF 

		AFTER FIELD sellup_per 
			IF glob_rec_opparms.sellup_per < 0 
			OR glob_rec_opparms.sellup_per IS NULL THEN 
				ERROR kandoomsg2("E",9109,"") 	# 9109 Sellup percentage Must be Zero OR a Positive Value
				NEXT FIELD sellup_per 
			END IF 
			IF glob_rec_opparms.sellup_per > 100 THEN 
				ERROR kandoomsg2("E",9117,"") 	# 9117 Sellup percentage cannot be more than 100 percent
				NEXT FIELD sellup_per 
			END IF 

		AFTER FIELD surcharge_amt 
			IF glob_rec_opparms.surcharge_amt < 0 
			OR glob_rec_opparms.surcharge_amt IS NULL THEN 
				ERROR kandoomsg2("E",9110,"") # 9110 Surcharge amount Must be Zero OR a Positive Value
				NEXT FIELD surcharge_amt 
			END IF 

		AFTER FIELD ship_label_qty 
			IF glob_rec_opparms.ship_label_qty IS NULL 
			OR glob_rec_opparms.ship_label_qty < 0 THEN 
				ERROR kandoomsg2("E",9111,"") # 9111 Number of labels must be greater than zero.
				NEXT FIELD ship_label_qty 
			END IF 

		AFTER FIELD so_hold_code 
			CLEAR so_reason_text 
			IF glob_rec_opparms.so_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_opparms.so_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") 		# 9112 Hold code NOT found - Try Window
					CLEAR so_reason_text 
					NEXT FIELD so_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO so_reason_text 

				END IF 
			END IF 

		AFTER FIELD ps_hold_code 
			CLEAR ps_reason_text 
			IF glob_rec_opparms.ps_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_opparms.ps_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") 		# 9112 Hold code NOT found - Try Window
					CLEAR ps_reason_text 
					NEXT FIELD ps_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO ps_reason_text 

				END IF 
			END IF 

		AFTER FIELD cf_hold_code 
			CLEAR cf_reason_text 
			IF glob_rec_opparms.cf_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_opparms.cf_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") # 9112 Hold code NOT found - Try Window
					CLEAR cf_reason_text 
					NEXT FIELD cf_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO cf_reason_text 

				END IF 
			ELSE 
				ERROR kandoomsg2("E",9115,"") # 9115 Hold code must be entered
				CLEAR cf_reason_text 
				NEXT FIELD cf_hold_code 
			END IF 

		AFTER FIELD cr_hold_code 
			CLEAR cr_reason_text 
			IF glob_rec_opparms.cr_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_opparms.cr_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") 		# 9112 Hold code NOT found - Try Window
					CLEAR cr_reason_text 
					NEXT FIELD cr_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO cr_reason_text 

				END IF 
			ELSE 
				ERROR kandoomsg2("E",9115,"") 	# 9115 Hold code must be entered
				CLEAR cr_reason_text 
				NEXT FIELD cr_hold_code 
			END IF 

		AFTER FIELD lim_hold_code 
			CLEAR lim_reason_text 
			IF glob_rec_opparms.lim_hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO modu_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_opparms.lim_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9112,"") # 9112 Hold code NOT found - Try Window
					CLEAR lim_reason_text 
					NEXT FIELD lim_hold_code 
				ELSE 
					DISPLAY modu_rec_holdreas.reason_text 
					TO lim_reason_text 

				END IF 
			ELSE 
				ERROR kandoomsg2("E",9115,"") # 9115 Hold code must be entered
				CLEAR lim_reason_text 
				NEXT FIELD lim_hold_code 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				LET quit_flag = FALSE 
				IF glob_rec_opparms.next_ord_num <= 0 
				OR glob_rec_opparms.next_ord_num IS NULL THEN 
					ERROR kandoomsg2("E",9107,"") # 9107 Next Order Number Must be a Positive Value
					NEXT FIELD next_ord_num 
				END IF 
				
				IF l_next_ord_num != glob_rec_opparms.next_ord_num THEN 
					SELECT max(order_num) 
					INTO l_next_ord_num 
					FROM orderhead 
					WHERE orderhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_next_ord_num = l_next_ord_num + 1 
				END IF 
				
				IF glob_rec_opparms.next_ord_num < l_next_ord_num 
				OR glob_rec_opparms.next_ord_num IS NULL THEN 
					ERROR kandoomsg2("E",9116,l_next_ord_num) #9116 New ORDER number cannot be less than
					LET glob_rec_opparms.next_ord_num = l_next_ord_num 
					NEXT FIELD next_ord_num 
				END IF 
				
				IF glob_rec_opparms.days_pick_num < 0 
				OR glob_rec_opparms.days_pick_num IS NULL THEN 
					ERROR kandoomsg2("E",9108,"") 	# 9108 Days Ahead Picking Must be Zero OR a Positive Value
					NEXT FIELD days_pick_num 
				END IF 
				
				IF glob_rec_opparms.max_inv_cycle_num < 0 OR 
				glob_rec_opparms.max_inv_cycle_num IS NULL 
				THEN 
					ERROR kandoomsg2("E",9248,"") # 9248 Number of invoices per cycle must be greater than zero
					NEXT FIELD max_inv_cycle_num 
				END IF 
				
				IF glob_rec_opparms.sellup_per < 0 
				OR glob_rec_opparms.sellup_per IS NULL THEN 
					ERROR kandoomsg2("E",9109,"") # 9109 Sellup percentage Must be Zero OR a Positive Value
					NEXT FIELD sellup_per 
				END IF 
				
				IF glob_rec_opparms.surcharge_amt < 0 
				OR glob_rec_opparms.surcharge_amt IS NULL THEN 
					ERROR kandoomsg2("E",9110,"") # 9110 Surcharge amount Must be Zero OR a Positive Value
					NEXT FIELD surcharge_amt 
				END IF
				 
				IF glob_rec_opparms.ship_label_qty IS NULL 
				OR glob_rec_opparms.ship_label_qty < 0 THEN 
					ERROR kandoomsg2("E",9111,"") # 9111 Number of labels must be greater than zero.
					NEXT FIELD ship_label_qty 
				END IF
				 
				IF glob_rec_opparms.allow_edit_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") #9102 Value must be entered.
					NEXT FIELD allow_edit_flag 
				END IF 
				
				SELECT * FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_opparms.cf_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9115,"") 	# 9115 Hold code must be entered
					NEXT FIELD cf_hold_code 
				END IF
				 
				SELECT * FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_opparms.cr_hold_code 
				IF status = NOTFOUND THEN 		
					ERROR kandoomsg2("E",9115,"")	# 9115 Hold code must be entered
					NEXT FIELD cr_hold_code 
				END IF 
				
				SELECT * FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_opparms.lim_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9115,"")		# 9115 Hold code must be entered
					NEXT FIELD lim_hold_code 
				END IF 
			END IF 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		RETURN 
	END IF 

	LET glob_rec_opparms.show_seg_flag = xlate_to(glob_rec_opparms.show_seg_flag) 
	LET glob_rec_opparms.cal_available_flag = xlate_to(glob_rec_opparms.cal_available_flag) 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "EZP - Locking Parameters record" 
		DECLARE c_opparms cursor FOR
		 
		SELECT * FROM opparms 
		WHERE key_num = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c_opparms 
		FETCH c_opparms INTO l_rec_t_opparms.*
		 
		IF l_rec_t_opparms.next_ord_num != l_rec_s_opparms.next_ord_num THEN 
			ROLLBACK WORK 
			ERROR kandoomsg2("U",7050,"") #7050 Parameter VALUES have been updated since changes. Please review.
			RETURN 
		END IF
		 
		UPDATE opparms 
		SET * = glob_rec_opparms.* 
		WHERE key_num = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	COMMIT WORK 
	WHENEVER ERROR stop 

END FUNCTION
###########################################################################
# END FUNCTION change_parm()
###########################################################################