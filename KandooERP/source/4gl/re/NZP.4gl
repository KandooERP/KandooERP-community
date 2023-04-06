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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/NZ_GROUP_GLOBALS.4gl"
GLOBALS "../re/NZP_GLOBALS.4gl"  
GLOBALS 
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module NZP - Internal Requisition Parameters
#                 provides FOR the maintenance of RE Parameters
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("NZP") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N100 with FORM "N100" 
	CALL windecoration_n("N100") -- albo kd-763 

	MENU " Parameters" 
		BEFORE MENU 
			IF disp_parm() THEN 
				HIDE option "Add" 
			ELSE 
				HIDE option "Change" 
			END IF 


		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Add" " Add Parameters" 
			IF input_reqparms("ADD") THEN 
				HIDE option "Add" 
				SHOW option "Change" 
			END IF 
			IF disp_parm() THEN 
			END IF 

		COMMAND "Change" " Change Parameters" 
			IF input_reqparms("EDIT") THEN 
			END IF 
			IF disp_parm() THEN 
			END IF 

		COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus" 
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 

	CLOSE WINDOW n100 

END MAIN 


############################################################
# FUNCTION input_reqparms(p_mode)
#
#
############################################################
FUNCTION input_reqparms(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_rec_t_reqparms RECORD LIKE reqparms.* 
	DEFINE l_rec_s_reqparms RECORD LIKE reqparms.* 
	DEFINE l_rec_reqparms RECORD LIKE reqparms.* 
	DEFINE l_temp_num LIKE reqparms.next_pend_po_num 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_err_message CHAR(60) 

	IF p_mode = "EDIT" THEN 
		SELECT * INTO l_rec_reqparms.* FROM reqparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		LET l_rec_s_reqparms.* = l_rec_reqparms.* 
	ELSE 
		INITIALIZE l_rec_reqparms.* TO NULL 
		LET l_rec_reqparms.next_req_num = 1 
		LET l_rec_reqparms.next_del_num = 1 
		LET l_rec_reqparms.next_pend_po_num = 1 
		LET l_rec_reqparms.auto_pick_flag = "N" 
		LET l_rec_reqparms.auto_po_flag = "N" 
		LET l_rec_reqparms.pend_purch_flag = "N" 
		LET l_rec_reqparms.log_flag = "N" 
	END IF 
	LET msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME l_rec_reqparms.next_req_num, 
	l_rec_reqparms.next_del_num, 
	l_rec_reqparms.next_pend_po_num, 
	l_rec_reqparms.pend_purch_flag, 
	l_rec_reqparms.log_flag, 
	l_rec_reqparms.auto_pick_flag, 
	l_rec_reqparms.pick_print_text, 
	l_rec_reqparms.auto_po_flag, 
	l_rec_reqparms.po_print_text WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (pick_print_text) 
			LET l_temp_text = show_print(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_reqparms.pick_print_text = l_temp_text 
				DISPLAY BY NAME l_rec_reqparms.pick_print_text 

			END IF 
			NEXT FIELD pick_print_text 

		ON KEY (control-b) infield (po_print_text) 
			LET l_temp_text = show_print(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_reqparms.po_print_text = l_temp_text 
				DISPLAY BY NAME l_rec_reqparms.po_print_text 

			END IF 
			NEXT FIELD po_print_text 


		BEFORE FIELD next_req_num 
			LET l_temp_num = l_rec_reqparms.next_req_num 

		AFTER FIELD next_req_num 
			IF l_temp_num != l_rec_reqparms.next_req_num 
			OR l_rec_reqparms.next_req_num IS NULL THEN 
				SELECT max(req_num) INTO l_temp_num FROM reqhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_temp_num = l_temp_num + 1 
			END IF 
			IF l_rec_reqparms.next_req_num < l_temp_num 
			OR l_rec_reqparms.next_req_num IS NULL THEN 
				LET msgresp = kandoomsg("N",9516,l_temp_num) 
				#9516 Next requistion number must be greater than OR equal TO XXX.
				LET l_rec_reqparms.next_req_num = l_temp_num 
				NEXT FIELD next_req_num 
			END IF 

		BEFORE FIELD next_del_num 
			LET l_temp_num = l_rec_reqparms.next_del_num 

		AFTER FIELD next_del_num 
			IF l_temp_num != l_rec_reqparms.next_del_num 
			OR l_rec_reqparms.next_del_num IS NULL THEN 
				SELECT max(del_num) INTO l_temp_num FROM delhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_temp_num = l_temp_num + 1 
			END IF 
			IF l_rec_reqparms.next_del_num < l_temp_num 
			OR l_rec_reqparms.next_del_num IS NULL THEN 
				LET msgresp = kandoomsg("N",9515,l_temp_num) 
				#9515 Next delivery number must be greater than OR equal TO XXX.
				LET l_rec_reqparms.next_del_num = l_temp_num 
				NEXT FIELD next_del_num 
			END IF 

		BEFORE FIELD next_pend_po_num 
			LET l_temp_num = l_rec_reqparms.next_pend_po_num 

		AFTER FIELD next_pend_po_num 
			IF l_temp_num != l_rec_reqparms.next_pend_po_num 
			OR l_rec_reqparms.next_pend_po_num IS NULL THEN 
				SELECT max(pend_num) INTO l_temp_num FROM pendhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_temp_num = l_temp_num + 1 
			END IF 
			IF l_rec_reqparms.next_pend_po_num < l_temp_num 
			OR l_rec_reqparms.next_pend_po_num IS NULL THEN 
				LET msgresp = kandoomsg("N",9517,l_temp_num) 
				#9517 Next pending PO number must be greater than OR equal TO XXX.
				LET l_rec_reqparms.next_pend_po_num = l_temp_num 
				NEXT FIELD next_pend_po_num 
			END IF 

		AFTER FIELD pick_print_text 
			IF l_rec_reqparms.pick_print_text IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				CLEAR pick_desc_text 
				NEXT FIELD pick_print_text 
			END IF 
			SELECT desc_text INTO pr_printcodes.desc_text FROM printcodes 
			WHERE print_code = l_rec_reqparms.pick_print_text 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("W",9301,"") 
				#9301 Printer NOT found; Try Window.
				CLEAR pick_desc_text 
				NEXT FIELD pick_print_text 
			END IF 
			DISPLAY pr_printcodes.desc_text TO pick_desc_text 

		AFTER FIELD po_print_text 
			IF l_rec_reqparms.po_print_text IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				CLEAR po_desc_text 
				NEXT FIELD po_print_text 
			END IF 
			SELECT desc_text INTO pr_printcodes.desc_text FROM printcodes 
			WHERE print_code = l_rec_reqparms.po_print_text 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("W",9301,"") 
				#9301 Printer NOT found; Try Window.
				CLEAR po_desc_text 
				NEXT FIELD po_print_text 
			END IF 
			DISPLAY pr_printcodes.desc_text TO po_desc_text 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT desc_text FROM printcodes 
				WHERE print_code = l_rec_reqparms.pick_print_text 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("W",9301,"") 
					#9301 Printer NOT found; Try Window.
					CLEAR pick_desc_text 
					NEXT FIELD pick_print_text 
				END IF 
				SELECT desc_text FROM printcodes 
				WHERE print_code = l_rec_reqparms.po_print_text 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("W",9301,"") 
					#9301 Printer NOT found; Try Window.
					CLEAR po_desc_text 
					NEXT FIELD po_print_text 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 


	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	END IF 

	IF p_mode = "ADD" THEN 
		LET l_rec_reqparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_reqparms.key_code = "1" 
		INSERT INTO reqparms VALUES (l_rec_reqparms.*) 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(l_err_message, status) = "N" THEN 
			RETURN false 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET l_err_message = "NZP - Locking Parameters Record" 

			DECLARE c_reqparms CURSOR FOR 
			SELECT * FROM reqparms 
			WHERE key_code = "1" 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			OPEN c_reqparms 
			FETCH c_reqparms INTO l_rec_t_reqparms.* 
			IF l_rec_t_reqparms.next_req_num != l_rec_s_reqparms.next_req_num 
			OR l_rec_t_reqparms.next_del_num != l_rec_s_reqparms.next_del_num 
			OR l_rec_t_reqparms.next_pend_po_num != l_rec_s_reqparms.next_pend_po_num THEN 
				ROLLBACK WORK 
				LET msgresp = kandoomsg("U",7050,"") 
				#7050 Parameter VALUES have been updated since changes. ...
				RETURN false 
			END IF 

			UPDATE reqparms 
			SET * = l_rec_reqparms.* 
			WHERE key_code = "1" 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION disp_parm()
#
#
############################################################
FUNCTION disp_parm() 
	DEFINE l_rec_reqparms RECORD LIKE reqparms.* 

	CLEAR FORM 
	SELECT * INTO l_rec_reqparms.* FROM reqparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	DISPLAY BY NAME l_rec_reqparms.next_req_num, 
	l_rec_reqparms.next_del_num, 
	l_rec_reqparms.next_pend_po_num, 
	l_rec_reqparms.pend_purch_flag, 
	l_rec_reqparms.log_flag, 
	l_rec_reqparms.auto_pick_flag, 
	l_rec_reqparms.pick_print_text, 
	l_rec_reqparms.auto_po_flag, 
	l_rec_reqparms.po_print_text 

	SELECT desc_text INTO pr_printcodes.desc_text FROM printcodes 
	WHERE print_code = l_rec_reqparms.pick_print_text 
	IF status = notfound THEN 
		LET pr_printcodes.desc_text = NULL 
	END IF 
	DISPLAY pr_printcodes.desc_text TO pick_desc_text 

	SELECT desc_text INTO pr_printcodes.desc_text FROM printcodes 
	WHERE print_code = l_rec_reqparms.po_print_text 
	IF status = notfound THEN 
		LET pr_printcodes.desc_text = NULL 
	END IF 
	DISPLAY pr_printcodes.desc_text TO po_desc_text 

	RETURN true 
END FUNCTION 
