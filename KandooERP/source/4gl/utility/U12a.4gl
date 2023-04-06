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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../utility/U12_GLOBALS.4gl"  
###########################################################################
# Module Scope Variables
###########################################################################
#DEFINE modu_err_message  CHAR(40) #not used ?
#DEFINE modu_err_continue CHAR(1) ) #not used ?
DEFINE modu_rec_kandoomask RECORD LIKE kandoomask.* 

#######################################################################
# FUNCTION change_mask_access(p_module_code,p_cmpy)
#
#
#######################################################################
FUNCTION change_mask_access(p_module_code,p_cmpy) 
	DEFINE p_module_code LIKE kandoomask.module_code 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_arr_rec_kandoomask DYNAMIC ARRAY OF t_rec_kandoomask_am_at_with_scrollflag 
	#	DEFINE l_arr_rec_kandoomask array[300] OF
	#		RECORD
	#          delete_flag      CHAR(1),
	#          acct_mask_code   LIKE kandoomask.acct_mask_code,
	#          access_type_code LIKE kandoomask.access_type_code
	#		END RECORD
	#DEFINE l_rec_menu1           RECORD LIKE menu1.* #not used ????
	DEFINE l_mask_code LIKE kandoomask.acct_mask_code 
	DEFINE l_module_text LIKE company.module_text 
	DEFINE l_old_acct_mask LIKE kandoomask.acct_mask_code 
	DEFINE l_old_access_type LIKE kandoomask.access_type_code 
	DEFINE l_acct_desc_text CHAR(30) 
	DEFINE l_entry_flag SMALLINT 
	DEFINE l_del SMALLINT 
	DEFINE l_rowid SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag

	INITIALIZE modu_rec_kandoomask.* TO NULL 
	INITIALIZE l_arr_rec_kandoomask TO NULL 
	LET l_idx = 0 

	OPEN WINDOW U150 with FORM "U150" 
	CALL windecoration_u("U150") 

	SELECT menu1_code,name_text 
	INTO p_module_code,	l_module_text 
	FROM menu1 
	WHERE menu1_code = p_module_code
	 
	DISPLAY glob_rec_kandoouser_specific.sign_on_code TO  user_code
	DISPLAY p_module_code TO  module_code
	DISPLAY l_module_text TO name_text 

	DECLARE c_kandoomask CURSOR FOR 
	SELECT * INTO modu_rec_kandoomask.* FROM kandoomask 
	WHERE cmpy_code = p_cmpy 
	AND user_code = glob_rec_kandoouser_specific.sign_on_code 
	AND module_code = p_module_code 
	ORDER BY 
		acct_mask_code, 
		access_type_code 

	FOREACH c_kandoomask 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_kandoomask[l_idx].acct_mask_code = modu_rec_kandoomask.acct_mask_code 
		LET l_arr_rec_kandoomask[l_idx].access_type_code = modu_rec_kandoomask.access_type_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
		
	END FOREACH 
	
	MESSAGE kandoomsg2("U", 1004, "") #1004 F1 TO Add - F2 TO Delete - ESC TO Continue

	CALL build_mask(p_cmpy, "??????????????????", " ") 
	RETURNING l_mask_code 
	
	OPTIONS INSERT KEY f1 

	INPUT ARRAY l_arr_rec_kandoomask WITHOUT DEFAULTS FROM sr_kandoomask.* attribute(UNBUFFERED, auto append = false, append ROW = false, DELETE row=false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U12a","input-arr-kandoomask") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#           LET scrn = scr_line()
			LET l_old_acct_mask = l_arr_rec_kandoomask[l_idx].acct_mask_code 
			LET l_old_access_type = l_arr_rec_kandoomask[l_idx].access_type_code 

		BEFORE INSERT 
			LET l_arr_rec_kandoomask[l_idx].acct_mask_code = glob_rec_kandoouser_specific.acct_mask_code 
			LET l_arr_rec_kandoomask[l_idx].access_type_code = NULL 
			LET l_old_acct_mask = NULL 
			LET l_old_access_type = NULL 

		ON KEY (F2) --delete / SET DELETE marker * 
			IF l_arr_rec_kandoomask[l_idx].delete_flag = "*" THEN 
				LET l_arr_rec_kandoomask[l_idx].delete_flag = "" 
				LET l_del = l_del - 1 
			ELSE 
				LET l_arr_rec_kandoomask[l_idx].delete_flag = "*" 
				LET l_del = l_del + 1 
			END IF 

		ON ACTION "LOOKUP" infield (acct_mask_code) 
			LET l_arr_rec_kandoomask[l_idx].acct_mask_code = showuaccts(
				p_cmpy, 
				l_mask_code) 

			NEXT FIELD acct_mask_code 

		AFTER FIELD acct_mask_code 

			IF fgl_lastkey() = fgl_keyval("accept") THEN 
				IF l_arr_rec_kandoomask[l_idx].acct_mask_code IS NOT NULL AND l_arr_rec_kandoomask[l_idx].access_type_code IS NULL THEN 
					ERROR kandoomsg2("U", 9530, "") #9530 "Access Type Code must be 1=Entry OR 2=Access ....
					NEXT FIELD access_type_code 
				END IF 
			END IF 

			LET l_entry_flag = false 
			IF NOT check_acct_code(p_cmpy,l_arr_rec_kandoomask[l_idx].acct_mask_code) THEN 
				CALL account_fill(p_cmpy, 
				l_mask_code, 
				l_arr_rec_kandoomask[l_idx].acct_mask_code, 
				2, 
				"User Module mask") 
				RETURNING l_arr_rec_kandoomask[l_idx].acct_mask_code, 
				l_acct_desc_text, 
				l_entry_flag 
				NEXT FIELD acct_mask_code 
			END IF 

			IF (l_old_acct_mask IS null) OR 
			(l_old_acct_mask != l_arr_rec_kandoomask[l_idx].acct_mask_code) 
			THEN 
				IF l_arr_rec_kandoomask[l_idx].access_type_code IS NOT NULL THEN 

					#UPDATE mask access  CALL update_mask_access()
					IF NOT update_mask_access(
						p_module_code, 
						l_arr_rec_kandoomask[l_idx].acct_mask_code, 
						l_old_acct_mask, 
						l_arr_rec_kandoomask[l_idx].access_type_code, 
						l_old_access_type, 
						p_cmpy) 
					THEN 						
						ERROR kandoomsg2("U", 9529, "") #9529 "This row entry already exist"
						IF l_old_acct_mask IS NOT NULL THEN 
							LET l_arr_rec_kandoomask[l_idx].acct_mask_code = l_old_acct_mask 
						END IF 
						LET l_entry_flag = true 
					ELSE 
						LET l_old_acct_mask = l_arr_rec_kandoomask[l_idx].acct_mask_code 
						LET l_old_access_type = l_arr_rec_kandoomask[l_idx].access_type_code 
					END IF 
				END IF 
			END IF 
			#           DISPLAY l_arr_rec_kandoomask[l_idx].acct_mask_code,
			#                   l_arr_rec_kandoomask[l_idx].access_type_code
			#               TO  sr_kandoomask[scrn].acct_mask_code,
			#                   sr_kandoomask[scrn].access_type_code

			IF l_entry_flag THEN 
				NEXT FIELD acct_mask_code 
			END IF 

		AFTER FIELD access_type_code 
			IF l_arr_rec_kandoomask[l_idx].access_type_code = "1" OR 
			l_arr_rec_kandoomask[l_idx].access_type_code = "2" OR 
			l_arr_rec_kandoomask[l_idx].access_type_code = "3" 
			THEN 
			ELSE 
				
				ERROR kandoomsg2("U", 9530, "") #9530 "Access Type Code must be 1=Entry OR 2=Access OR 3=Both"
				NEXT FIELD access_type_code 
			END IF 

			IF l_old_access_type IS NULL OR l_old_access_type != l_arr_rec_kandoomask[l_idx].access_type_code	THEN 

				#UPDATE mask access  CALL update_mask_access()
				IF NOT update_mask_access(
					p_module_code, 
					l_arr_rec_kandoomask[l_idx].acct_mask_code, 
					l_old_acct_mask, 
					l_arr_rec_kandoomask[l_idx].access_type_code, 
					l_old_access_type, 
					p_cmpy) 
				THEN 
					
					ERROR kandoomsg2("U", 9529, "") #9529 "This row entry already exist"
					IF l_old_access_type IS NOT NULL THEN 
						LET l_arr_rec_kandoomask[l_idx].access_type_code = l_old_access_type 
					END IF 
					NEXT FIELD access_type_code 
				ELSE 
					LET l_old_acct_mask = l_arr_rec_kandoomask[l_idx].acct_mask_code 
					LET l_old_access_type = l_arr_rec_kandoomask[l_idx].access_type_code 
				END IF 
			END IF 

			IF fgl_lastkey() = fgl_keyval("accept") THEN 
				IF l_arr_rec_kandoomask[l_idx].acct_mask_code IS NOT NULL AND l_arr_rec_kandoomask[l_idx].access_type_code IS NULL 
				THEN 					
					ERROR kandoomsg2("U", 9530, "") #9530 "Access Type Code must be 1=Entry OR 2=Access ....
					#                   DISPLAY l_arr_rec_kandoomask[l_idx].acct_mask_code
					#                        TO sr_kandoomask[scrn].acct_mask_code

					NEXT FIELD access_type_code 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	OPTIONS INSERT KEY f36 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del > 0 THEN 
			IF kandoomsg("U", 8900, l_del)  = "Y" THEN #prompt "There are VALUE Flex Codes TO delete. Confirm...."
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_kandoomask[l_idx].delete_flag = "*" THEN 
						DELETE FROM kandoomask 
						WHERE cmpy_code = p_cmpy 
						AND user_code = glob_rec_kandoouser_specific.sign_on_code 
						AND module_code = p_module_code 
						AND access_type_code= l_arr_rec_kandoomask[l_idx].access_type_code 
						AND acct_mask_code = l_arr_rec_kandoomask[l_idx].acct_mask_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
	
	CLOSE WINDOW U150 

END FUNCTION {change_mask} 
#######################################################################
# END FUNCTION change_mask_access(p_module_code,p_cmpy)
#######################################################################


#######################################################################
# FUNCTION update_mask_access(p_module_code,
#                            p_acct_mask,
#                            p_old_acct_mask,
#                            p_access_type,
#                            p_old_access_type,
#                            p_cmpy)
#
#
#######################################################################
FUNCTION update_mask_access(p_module_code, 
	p_acct_mask, 
	p_old_acct_mask, 
	p_access_type, 
	p_old_access_type, 
	p_cmpy) 
	DEFINE p_module_code LIKE kandoomask.module_code 
	DEFINE p_acct_mask LIKE kandoomask.acct_mask_code 
	DEFINE p_old_acct_mask LIKE kandoomask.acct_mask_code 
	DEFINE p_access_type LIKE kandoomask.access_type_code 
	DEFINE p_old_access_type LIKE kandoomask.access_type_code 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag
	
	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 
	SELECT * FROM kandoomask 
	WHERE cmpy_code = p_cmpy 
	AND user_code = glob_rec_kandoouser_specific.sign_on_code 
	AND module_code = p_module_code 
	AND access_type_code= p_access_type 
	AND acct_mask_code = p_acct_mask 
	IF (status=notfound) THEN 
		IF p_old_acct_mask IS NOT NULL THEN 
			DELETE FROM kandoomask 
			WHERE cmpy_code = p_cmpy 
			AND user_code = glob_rec_kandoouser_specific.sign_on_code 
			AND module_code = p_module_code 
			AND access_type_code= p_old_access_type 
			AND acct_mask_code = p_old_acct_mask 
		END IF 

		LET modu_rec_kandoomask.cmpy_code = p_cmpy 
		LET modu_rec_kandoomask.user_code = glob_rec_kandoouser_specific.sign_on_code 
		LET modu_rec_kandoomask.module_code = p_module_code 
		LET modu_rec_kandoomask.access_type_code = p_access_type 
		LET modu_rec_kandoomask.acct_mask_code = p_acct_mask 

		INSERT INTO kandoomask VALUES (modu_rec_kandoomask.*) 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION {update_access_mask} 
#######################################################################
# END FUNCTION update_mask_access(p_module_code,
#                            p_acct_mask,
#                            p_old_acct_mask,
#                            p_access_type,
#                            p_old_access_type,
#                            p_cmpy)
#######################################################################


#######################################################################
# FUNCTION change_cmpy_access()
#
#
#######################################################################
FUNCTION change_cmpy_access(l_rec_specific_rec_kandoouser) 
	DEFINE l_rec_specific_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_arr_rec_cmpy_access DYNAMIC ARRAY OF t_rec_cmpy_access_cc_ct_lc_am_with_scrollflag 
	DEFINE l_rec_cmpy_access t_rec_cmpy_access_cc_ct_lc_am_with_scrollflag 
	DEFINE l_old_cmpy_code LIKE company.cmpy_code 
	DEFINE l_del SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_winds_text STRING 
	DEFINE l_scroll_flag CHAR(1) 

	
	OPEN WINDOW U151 with FORM "U151" 
	CALL windecoration_u("U151") 

	DISPLAY BY NAME 
		l_rec_specific_rec_kandoouser.sign_on_code, 
		l_rec_specific_rec_kandoouser.name_text, 
		l_rec_specific_rec_kandoouser.security_ind, 
		l_rec_specific_rec_kandoouser.cmpy_code 

	DISPLAY db_company_get_name_text(UI_OFF,l_rec_specific_rec_kandoouser.cmpy_code) TO company.name_text 
	#DISPLAY glob_rec_specific_company.name_text TO company.name_text

	DECLARE c_kandoousercmpy CURSOR FOR 
	SELECT 
		kandoousercmpy.cmpy_code, 
		company.name_text, 
		kandoousercmpy.acct_mask_code 
	FROM kandoousercmpy, company 
	WHERE kandoousercmpy.sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 
	AND kandoousercmpy.cmpy_code = company.cmpy_code 
	ORDER BY cmpy_code 
	LET l_idx = 0 

	FOREACH c_kandoousercmpy INTO 
		l_rec_cmpy_access.curr_code, 
		l_rec_cmpy_access.cmpy_text, 
		l_rec_cmpy_access.acct_mask_code 

		LET l_idx = l_idx + 1 
		LET l_arr_rec_cmpy_access[l_idx].scroll_flag = "" 
		LET l_arr_rec_cmpy_access[l_idx].curr_code = l_rec_cmpy_access.curr_code 
		LET l_arr_rec_cmpy_access[l_idx].cmpy_text = l_rec_cmpy_access.cmpy_text 
		LET l_arr_rec_cmpy_access[l_idx].acct_mask_code = l_rec_cmpy_access.acct_mask_code 

		INITIALIZE glob_rec_userlocn.* TO NULL 
		INITIALIZE glob_rec_location.* TO NULL 

		SELECT * INTO glob_rec_userlocn.* FROM userlocn 
		WHERE cmpy_code = l_rec_cmpy_access.curr_code 
		AND sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 
		IF status = 0 THEN 
			SELECT * INTO glob_rec_location.* FROM location 
			WHERE cmpy_code = l_rec_cmpy_access.curr_code 
			AND locn_code = glob_rec_userlocn.locn_code 
		END IF 
		
		LET l_arr_rec_cmpy_access[l_idx].locn_code = glob_rec_userlocn.locn_code 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 
	
	MESSAGE kandoomsg2("U", 1052, "") #1052 F1 TO Add - F2 TO Delete - OK TO Continue 
	OPTIONS DELETE KEY f36 

	INPUT ARRAY l_arr_rec_cmpy_access WITHOUT DEFAULTS FROM sr_cmpy_access.* attribute(UNBUFFERED, auto append = false, append ROW = false, DELETE row=false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U12a","input-arr-cmpy_access") 
			IF (l_arr_rec_cmpy_access.getlength() <= 0) THEN 
				CALL fgl_dialog_setkeylabel("Module Access","") #hide option "Module Access" 
				CALL fgl_dialog_setkeylabel("Menu Access","") #hide option "Menu Access" 
				CALL fgl_dialog_setkeylabel("Limits Access","") #hide option "Limits Access" 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (locn_code) 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_cmpy_access.getSize()) THEN
				LET l_winds_text = show_user_loc(l_arr_rec_cmpy_access[l_idx].curr_code) 

				IF l_winds_text IS NOT NULL THEN 
					LET l_arr_rec_cmpy_access[l_idx].locn_code = l_winds_text clipped 
				END IF 

				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				NEXT FIELD locn_code 
			END IF
			
		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_cmpy_access.getSize()) THEN 
				LET l_old_cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
			END IF 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			LET l_scroll_flag = l_arr_rec_cmpy_access[l_idx].scroll_flag 
			LET l_rec_cmpy_access.curr_code = l_arr_rec_cmpy_access[l_idx].curr_code 
			LET l_rec_cmpy_access.cmpy_text = l_arr_rec_cmpy_access[l_idx].cmpy_text 
			LET l_rec_cmpy_access.locn_code = l_arr_rec_cmpy_access[l_idx].locn_code 
			LET l_rec_cmpy_access.acct_mask_code = l_arr_rec_cmpy_access[l_idx].acct_mask_code 

		AFTER FIELD scroll_flag 
			LET l_arr_rec_cmpy_access[l_idx].scroll_flag = l_scroll_flag 
			#         DISPLAY l_arr_rec_cmpy_access[l_idx].* TO sr_cmpy_access[scrn].*

			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_cmpy_access[l_idx+1].curr_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               ERROR kandoomsg2("W",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF
			#         IF fgl_lastkey() = fgl_keyval("nextpage") THEN
			#            IF l_arr_rec_cmpy_access[l_idx+7].curr_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               ERROR kandoomsg2("W",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		BEFORE INSERT 
			LET l_old_cmpy_code = NULL 
			INITIALIZE l_rec_cmpy_access.* TO NULL 
			NEXT FIELD curr_code 

		AFTER INSERT #huho 
			IF int_flag THEN 
				LET int_flag = false 
				CALL l_arr_rec_cmpy_access.delete(l_idx) 
				NEXT FIELD scroll_flag 
			END IF 

			--delete marker
		ON KEY (F2) infield(scroll_flag) 
			IF l_idx > 0 THEN 
				IF l_arr_rec_cmpy_access[l_idx].scroll_flag = "*" THEN 
					LET l_arr_rec_cmpy_access[l_idx].scroll_flag = "" 
					LET l_del = l_del - 1 
				ELSE 
					LET l_arr_rec_cmpy_access[l_idx].scroll_flag = "*" 
					LET l_del = l_del + 1 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 

		ON ACTION "Module Access" 
			#		ON KEY (F6)  --Edit Mode Access
			#          IF infield(scroll_flag) THEN
			IF l_idx > 0 THEN 
				CALL change_mod_access(l_arr_rec_cmpy_access[l_idx].curr_code) 
				OPTIONS DELETE KEY f36 
			END IF 
			#             NEXT FIELD scroll_flag
			#          END IF

		ON ACTION "Menu Access" 
			#		ON KEY (F7) --Edit Path Access
			#         IF infield(scroll_flag) THEN
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_cmpy_access.getSize()) THEN 
				CALL change_path_access(l_arr_rec_cmpy_access[l_idx].curr_code) 
				OPTIONS DELETE KEY f36 
			END IF 
			#            NEXT FIELD scroll_flag
			#          END IF

		ON ACTION "Limits" 
			#		ON KEY (F8)  --Edit Limits - some kind of $/€ max amount
			#          IF infield(scroll_flag) THEN
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_cmpy_access.getSize()) THEN 
				CALL change_limits(l_arr_rec_cmpy_access[l_idx].curr_code) 
				OPTIONS DELETE KEY f36 
			END IF 

		BEFORE FIELD curr_code 
			SELECT unique 1 FROM kandoousercmpy 
			WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
			AND sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 
			IF status = 0 THEN 
				NEXT FIELD locn_code 
			END IF 

		AFTER FIELD curr_code 
			IF l_arr_rec_cmpy_access[l_idx].curr_code IS NULL THEN 
				IF l_old_cmpy_code IS NOT NULL THEN 
					
					MESSAGE kandoomsg2("U", 9531, "") #9531 "This value cannot be NULL - use F2 TO delete" 
					LET l_arr_rec_cmpy_access[l_idx].curr_code = l_old_cmpy_code 
					NEXT FIELD curr_code 
				ELSE 					
					MESSAGE kandoomsg2("U",9102, "") #9102 "Value must be entered"
					NEXT FIELD curr_code 
				END IF 
			ELSE 
				INITIALIZE glob_rec_specific_company.* TO NULL 
				SELECT * INTO glob_rec_specific_company.* FROM company 
				WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
				IF status = notfound THEN 					
					ERROR kandoomsg2("U", 9532, "") #9532 "This company code does NOT exist"
					NEXT FIELD curr_code 
				END IF 
				
				IF l_arr_rec_cmpy_access[l_idx].locn_code IS NOT NULL THEN 
					SELECT * INTO glob_rec_location.* FROM location 
					WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
					AND locn_code = l_arr_rec_cmpy_access[l_idx].locn_code 
					IF status = notfound THEN 
						ERROR kandoomsg2("U", 9130, "") 	#9130 "Location/Company combination does NOT exist"
						NEXT FIELD curr_code 
					END IF 
				END IF 
			END IF 

			IF (l_old_cmpy_code IS NULL OR l_old_cmpy_code != l_arr_rec_cmpy_access[l_idx].curr_code) 
			AND (l_arr_rec_cmpy_access[l_idx].curr_code IS NOT null) THEN 
			
				SELECT * FROM kandoousercmpy 
				WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
				AND sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 
				IF status = notfound THEN 
					IF l_old_cmpy_code IS NOT NULL THEN 
						DELETE FROM kandoousercmpy 
						WHERE cmpy_code = l_old_cmpy_code 
						AND sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 
					END IF 
					
					INITIALIZE glob_rec_kandoousercmpy.* TO NULL
					 
					CALL build_mask(
						l_arr_rec_cmpy_access[l_idx].curr_code, 
						"??????????????????", " ") 
					RETURNING glob_rec_kandoousercmpy.acct_mask_code 

					LET glob_rec_kandoousercmpy.cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
					LET glob_rec_kandoousercmpy.sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 

					INSERT INTO kandoousercmpy VALUES (glob_rec_kandoousercmpy.*) 
				ELSE 					
					ERROR kandoomsg2("U", 9529, "") #9529 "This row entry already exist"
					LET l_arr_rec_cmpy_access[l_idx].curr_code = NULL 
					NEXT FIELD curr_code 
				END IF 
			END IF 

			LET l_arr_rec_cmpy_access[l_idx].cmpy_text = glob_rec_specific_company.name_text 
			LET l_arr_rec_cmpy_access[l_idx].acct_mask_code = glob_rec_kandoousercmpy.acct_mask_code 

			-----------------------------------

			CASE 
				WHEN get_is_screen_navigation_forward()

					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF glob_rec_specific_company.module_text[23,23] = "W" AND l_arr_rec_cmpy_access[l_idx].locn_code IS NULL THEN 
							SELECT unique 1 FROM location 
							WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
							IF status != notfound THEN 
								ERROR kandoomsg2("U",9102,"") 								#9102 Value must be entered
								NEXT FIELD locn_code 
							END IF 
						END IF 

						IF l_arr_rec_cmpy_access[l_idx].acct_mask_code IS NULL THEN 
							ERROR kandoomsg2("U",9102,"") 						#9102 Value must be entered
							NEXT FIELD acct_mask_code 
						END IF 

						--NEXT FIELD scroll_flag 

					--ELSE 
					--	NEXT FIELD locn_code 
					END IF 

				--WHEN get_is_screen_navigation_forward()
				--	--fgl_lastkey() = fgl_keyval("left") OR fgl_lastkey() = fgl_keyval("up") 
				--	NEXT FIELD scroll_flag 

				--OTHERWISE 
				--	NEXT FIELD curr_code 

			END CASE 
			--------------------------------------------------

		BEFORE FIELD locn_code 
			CALL comboList_location_cmpy("locn_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL, l_arr_rec_cmpy_access[l_idx].curr_code,COMBO_NULL_SPACE) 

		AFTER FIELD locn_code #updates location AND also updates userlocn (user location NOTlocation !!!)
			IF l_arr_rec_cmpy_access[l_idx].locn_code IS NOT NULL THEN 

				SELECT * INTO glob_rec_location.* FROM location 
				WHERE locn_code = l_arr_rec_cmpy_access[l_idx].locn_code 
				AND cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("W",9144,"") 	#9144 A location NOT found - Try window
					NEXT FIELD locn_code 
				ELSE 
					#               DISPLAY l_arr_rec_cmpy_access[l_idx].* TO sr_cmpy_access[scrn].*

				END IF 
				
				DELETE FROM userlocn 
				WHERE sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 
				AND cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code
				 
				LET glob_rec_userlocn.cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
				LET glob_rec_userlocn.sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 
				LET glob_rec_userlocn.locn_code = l_arr_rec_cmpy_access[l_idx].locn_code 
				
				INSERT INTO userlocn VALUES (glob_rec_userlocn.*)
				 
			ELSE 
				IF glob_rec_specific_company.module_text[23,23] = "W" THEN 
					SELECT unique 1 FROM location 
					WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
					IF status != notfound THEN 
						ERROR kandoomsg2("U",9102,"")				#9102 Value must be entered
						NEXT FIELD locn_code 
					END IF 
				END IF 
			END IF 

			------------------------------------------------------------------
			CASE 

				WHEN get_is_screen_navigation_forward() 
					--fgl_lastkey() = fgl_keyval("accept") 
					--OR fgl_lastkey() = fgl_keyval("RETURN") 
					--OR fgl_lastkey() = fgl_keyval("tab") 
					--OR fgl_lastkey() = fgl_keyval("right") 
					--OR fgl_lastkey() = fgl_keyval("down") 
					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF l_arr_rec_cmpy_access[l_idx].acct_mask_code IS NULL THEN 
							ERROR kandoomsg2("U",9102,"")#9102 Value must be entered
							NEXT FIELD acct_mask_code 
						END IF 
						NEXT FIELD scroll_flag 
					ELSE 
						NEXT FIELD acct_mask_code 
					END IF 
				--WHEN NOT get_is_screen_navigation_forward()
					--fgl_lastkey() = fgl_keyval("left") 
					--OR fgl_lastkey() = fgl_keyval("up") 
				--	NEXT FIELD previous 
				--OTHERWISE 
				--	NEXT FIELD locn_code 

			END CASE 
			------------------------------------------

		AFTER FIELD acct_mask_code 
			IF l_arr_rec_cmpy_access[l_idx].acct_mask_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 	#9102 Value must be entered
				NEXT FIELD acct_mask_code 
			ELSE 
				UPDATE kandoousercmpy 
				SET acct_mask_code = l_arr_rec_cmpy_access[l_idx].acct_mask_code 
				WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
				AND sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 
				IF l_arr_rec_cmpy_access[l_idx].curr_code = glob_rec_kandoouser_specific.cmpy_code THEN 
					UPDATE kandoouser 
					SET acct_mask_code = l_arr_rec_cmpy_access[l_idx].acct_mask_code 
					WHERE sign_on_code = l_rec_specific_rec_kandoouser.sign_on_code 
				END IF 
			END IF 

			----------------------------------------
			CASE 

				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					NEXT FIELD scroll_flag 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 

					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD acct_mask_code 
			END CASE 
			----------------------------------------------


		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_cmpy_access.curr_code IS NULL THEN 
						IF (l_idx > 0) AND (l_arr_rec_cmpy_access.getlength() > 0) THEN #in CASE the ARRAY IS empty 
							IF l_arr_rec_cmpy_access[l_idx].curr_code IS NOT NULL THEN 

								DELETE FROM kandoousercmpy 
								WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
								AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
								#ELSE
								#	CALL l_arr_rec_cmpy_access.delete(l_idx)  --huho, needs testing and debugging
							END IF 
						END IF 


						#   #               FOR l_idx = arr_curr() TO l_arr_rec_cmpy_access.getLength()   --huho, needs testing and debugging
						#   #                  LET l_arr_rec_cmpy_access[l_idx].* = l_arr_rec_cmpy_access[l_idx+1].*
						#   #        IF l_idx = l_arr_rec_cmpy_access.getLength() THEN #arr_count() THEN
						#		#				 CALL l_arr_rec_cmpy_access.delete(l_idx)  --huho, needs testing and debugging
						#    #                    #INITIALIZE l_arr_rec_cmpy_access[l_idx].* TO NULL
						#    #                 END IF
						#   #                  IF scrn <= 6 THEN
						#   #                     DISPLAY l_arr_rec_cmpy_access[l_idx].* TO sr_cmpy_access[scrn].*
						#   #
						#   #                     LET scrn = scrn + 1
						#   #                  END IF
						#    #              END FOR
						#        LET scrn = scr_line()


						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						IF (l_idx > 0) AND (l_arr_rec_cmpy_access.getlength() > 0) THEN #in CASE the ARRAY IS empty 
							LET l_arr_rec_cmpy_access[l_idx].curr_code = l_rec_cmpy_access.curr_code 
							LET l_arr_rec_cmpy_access[l_idx].cmpy_text = l_rec_cmpy_access.cmpy_text 
							LET l_arr_rec_cmpy_access[l_idx].locn_code = l_rec_cmpy_access.locn_code 
							LET l_arr_rec_cmpy_access[l_idx].acct_mask_code = l_rec_cmpy_access.acct_mask_code 
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				END IF 
			END IF 

	END INPUT 

	OPTIONS DELETE KEY f2 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del > 0 THEN 
			 
			IF kandoomsg("U", 8900, l_del) = "Y" THEN #MESSAGE kandoomsg2("U", 8900, l_del) #prompt "There are VALUE Company Access Codes TO delete. Confirm...." 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_cmpy_access[l_idx].scroll_flag = "*" THEN 
						BEGIN WORK 

							DELETE FROM kandoousercmpy 
							WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
							AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 

							DELETE FROM userlocn 
							WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
							AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 

							DELETE FROM kandoomodule 
							WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
							AND user_code = glob_rec_kandoouser_specific.sign_on_code 

							DELETE FROM userlimits 
							WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
							AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 

							DELETE FROM kandoomask 
							WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
							AND user_code = glob_rec_kandoouser_specific.sign_on_code 

							DELETE FROM grant_deny_access 
							WHERE cmpy_code = l_arr_rec_cmpy_access[l_idx].curr_code 
							AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 

						COMMIT WORK 

					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
	CLOSE WINDOW U151 
END FUNCTION {change_cmpy_access} 
#######################################################################
# END FUNCTION change_cmpy_access()
#######################################################################


#######################################################################
# FUNCTION change_path_access(p_cmpy_code)
#
#
#######################################################################
FUNCTION change_path_access(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_name_text LIKE company.name_text 
	DEFINE l_arr_rec_access_priv DYNAMIC ARRAY OF t_rec_priv_access_df_gd_pc_sm_spg
	DEFINE l_msgresp LIKE language.yes_flag
	#	DEFINE l_arr_rec_access_priv array[300] OF
	#		RECORD
	#         delete_flag         CHAR(1),
	#         grant_deny_flag     CHAR(1),
	#         path_code           CHAR(3),
	#         security_module_ind CHAR(1),
	#         security_prog_ind   CHAR(1)
	#		END RECORD
	DEFINE l_rec_access_priv t_rec_priv_access_df_gd_pc_sm_spg 
	#		RECORD
	#         delete_flag         CHAR(1),
	#         grant_deny_flag     CHAR(1),
	#         path_code           CHAR(3),
	#         security_module_ind CHAR(1),
	#         security_prog_ind   CHAR(1)
	#		END RECORD
	DEFINE fv_old_path_code CHAR(3) 
	DEFINE fv_old_access_flag CHAR(1) 
	DEFINE l_del SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_menu1_code LIKE menu3.menu1_code 
	DEFINE l_menu2_code LIKE menu3.menu2_code 
	DEFINE l_menu3_code LIKE menu3.menu3_code 
	DEFINE l_menu1_old LIKE menu3.menu1_code 
	DEFINE l_menu2_old LIKE menu3.menu2_code 
	DEFINE l_menu3_old LIKE menu3.menu3_code 
	DEFINE l_grant_deny_flag LIKE grant_deny_access.grant_deny_flag 

	OPEN WINDOW U152 with FORM "U152" 
	CALL windecoration_u("U152") 

	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_cmpy_code 
	IF status = 0 THEN 
		LET l_name_text = l_rec_company.name_text 
	END IF 

	DECLARE c_access CURSOR FOR 
	SELECT 
		grant_deny_flag, 
		menu1_code, 
		menu2_code, 
		menu3_code 
	FROM grant_deny_access 
	WHERE cmpy_code = p_cmpy_code 
	AND grant_deny_access.sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
	ORDER BY 
		menu1_code, 
		menu2_code, 
		menu3_code 

	LET l_idx = 0 
	FOREACH c_access INTO 
		l_rec_access_priv.grant_deny_flag, 
		l_menu1_code, 
		l_menu2_code, 
		l_menu3_code 

		LET l_idx = l_idx + 1 
		LET l_arr_rec_access_priv[l_idx].delete_flag = "" 
		LET l_arr_rec_access_priv[l_idx].path_code[1,1] = l_menu1_code 
		LET l_arr_rec_access_priv[l_idx].path_code[2,2] = l_menu2_code 
		LET l_arr_rec_access_priv[l_idx].path_code[3,3] = l_menu3_code 
		LET l_arr_rec_access_priv[l_idx].grant_deny_flag = l_rec_access_priv.grant_deny_flag 

		SELECT security_ind 
		INTO l_arr_rec_access_priv[l_idx].security_module_ind 
		FROM kandoomodule 
		WHERE cmpy_code = p_cmpy_code 
		AND user_code = glob_rec_kandoouser_specific.sign_on_code 
		AND module_code = l_menu1_code 

		SELECT security_ind 
		INTO l_arr_rec_access_priv[l_idx].security_prog_ind 
		FROM menu3 
		WHERE menu1_code = l_menu1_code 
		AND menu2_code = l_menu2_code 
		AND menu3_code = l_menu3_code 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	LET l_del = 0 
	MESSAGE kandoomsg2("U", 1004, "") #1004 F1 TO Add - F2 TO Delete - ESC TO continue

	DISPLAY 
		glob_rec_kandoouser_specific.sign_on_code, 
		glob_rec_kandoouser_specific.name_text, 
		glob_rec_kandoouser_specific.security_ind, 
		l_rec_company.cmpy_code, 
		l_name_text 
	TO 
		kandoouser.sign_on_code, 
		kandoouser.name_text, 
		kandoouser.security_ind, 
		company.cmpy_code, 
		company.name_text 


	OPTIONS DELETE KEY f36 

	INPUT ARRAY l_arr_rec_access_priv WITHOUT DEFAULTS FROM sr_access_priv.* attribute(UNBUFFERED, auto append = false, append ROW = false, DELETE row=false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U12a","input-arr-access_priv") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#           LET scrn = scr_line()
			LET fv_old_access_flag = l_arr_rec_access_priv[l_idx].grant_deny_flag 
			LET fv_old_path_code = l_arr_rec_access_priv[l_idx].path_code 

		BEFORE INSERT 
			LET fv_old_access_flag = NULL 
			LET fv_old_path_code = NULL 

		ON KEY (F2) --delete marker 
			IF l_arr_rec_access_priv[l_idx].delete_flag = "*" THEN 
				LET l_arr_rec_access_priv[l_idx].delete_flag = "" 
				LET l_del = l_del - 1 
			ELSE 
				LET l_arr_rec_access_priv[l_idx].delete_flag = "*" 
				LET l_del = l_del + 1 
			END IF 

		AFTER FIELD grant_deny_flag 
			IF l_arr_rec_access_priv[l_idx].grant_deny_flag <> "G" 
			AND l_arr_rec_access_priv[l_idx].grant_deny_flag <> "D" 
			AND l_arr_rec_access_priv[l_idx].grant_deny_flag IS NOT NULL THEN 
				
				ERROR kandoomsg2("U", 9533, "") #9533 "Value in field must be D OR G"
				NEXT FIELD grant_deny_flag 
			END IF 

			IF (fv_old_access_flag IS NOT null) AND (l_arr_rec_access_priv[l_idx].grant_deny_flag IS null) THEN 
				
				ERROR kandoomsg2("U", 9531, "") #9531 "This value cannot be NULL - use F2 TO delete"
				IF fv_old_access_flag IS NOT NULL THEN 
					LET l_arr_rec_access_priv[l_idx].grant_deny_flag = fv_old_access_flag 
				END IF 
				NEXT FIELD grant_deny_flag 
			END IF 

			IF l_arr_rec_access_priv[l_idx].grant_deny_flag IS NULL AND l_arr_rec_access_priv[l_idx].path_code IS NOT NULL THEN 
				ERROR kandoomsg2("U", 9533, "") #9533 "Value in field must be D OR G"
				IF fv_old_access_flag IS NOT NULL THEN 
					LET l_arr_rec_access_priv[l_idx].grant_deny_flag = fv_old_access_flag 
				END IF 
				NEXT FIELD grant_deny_flag 
			END IF 

			IF (fv_old_access_flag != l_arr_rec_access_priv[l_idx].grant_deny_flag) OR	(fv_old_path_code IS null) THEN 
				IF l_arr_rec_access_priv[l_idx].path_code IS NOT NULL THEN 
					IF NOT update_path_access(
						p_cmpy_code, 
						l_arr_rec_access_priv[l_idx].path_code, 
						fv_old_path_code, 
						l_arr_rec_access_priv[l_idx].grant_deny_flag, 
						fv_old_access_flag) 
					THEN 
						ERROR kandoomsg2("U", 9529, "") #9529 "This row entry already exist" 
						NEXT FIELD grant_deny_flag 
					END IF 
				END IF 
			END IF 

		AFTER FIELD path_code 
			IF l_arr_rec_access_priv[l_idx].path_code IS NULL THEN 
				LET l_arr_rec_access_priv[l_idx].path_code = " " 
			END IF 
			LET l_menu1_code = l_arr_rec_access_priv[l_idx].path_code[1,1] 
			LET l_menu2_code = l_arr_rec_access_priv[l_idx].path_code[2,2] 
			LET l_menu3_code = l_arr_rec_access_priv[l_idx].path_code[3,3] 
			IF (fv_old_path_code != l_arr_rec_access_priv[l_idx].path_code) 
			OR (fv_old_path_code IS null) THEN 
				IF (l_arr_rec_access_priv[l_idx].path_code = " ") AND 
				(fv_old_path_code IS NOT null) 
				THEN 
					
					ERROR kandoomsg2("U", 9531, "") #9531 "Value cannot be NULL - use F2 TO delete"
					LET l_arr_rec_access_priv[l_idx].path_code = fv_old_path_code 
					NEXT FIELD path_code 
				END IF 

				IF l_menu1_code = " " THEN 
					
					ERROR kandoomsg2("U", 9534, "")  #9534 "Menu Path one must be entered"
					NEXT FIELD path_code 
				ELSE 
					SELECT * FROM menu1 
					WHERE menu1.menu1_code = l_menu1_code 
					IF (status=notfound) THEN 
						
						ERROR kandoomsg2("U", 9900, "1") #9900 "Menu Path <VALUE> IS invalid "
						NEXT FIELD path_code 
					END IF 
				END IF 

				IF l_menu2_code = " " THEN 
					IF l_menu3_code != " " THEN 
						ERROR kandoomsg2("U", 9535, "") #9535 "Menu Path 2 cannot be blank WHEN menu path 3 ..." 
						NEXT FIELD path_code 
					END IF 
				ELSE 
					SELECT * FROM menu2 
					WHERE menu2.menu1_code = l_menu1_code 
					AND menu2.menu2_code = l_menu2_code 
					IF (status=notfound) THEN 
						
						ERROR kandoomsg2("U", 9900, "2") #9900 "Menu Path <VALUE> IS invalid "
						NEXT FIELD path_code 
					END IF 
				END IF 

				IF l_menu3_code <> " " THEN 
					SELECT * FROM menu3 
					WHERE menu3.menu1_code = l_menu1_code 
					AND menu3.menu2_code = l_menu2_code 
					AND menu3.menu3_code = l_menu3_code 
					IF (status=notfound) THEN 
						
						MESSAGE kandoomsg2("U", 9900, "3") #9900 "Menu Path <VALUE> IS invalid "
						NEXT FIELD path_code 
					END IF 
				END IF 
				IF l_arr_rec_access_priv[l_idx].grant_deny_flag IS NULL THEN 
					IF fv_old_path_code IS NULL THEN 
						LET fv_old_path_code = l_arr_rec_access_priv[l_idx].path_code 
					END IF 
					NEXT FIELD grant_deny_flag 
				ELSE 
					#VALIDATE IF ENTRY ALREADY EXISTS
					IF NOT update_path_access(
						p_cmpy_code, 
						l_arr_rec_access_priv[l_idx].path_code, 
						fv_old_path_code, 
						l_arr_rec_access_priv[l_idx].grant_deny_flag, 
						fv_old_access_flag) 
					THEN 
						
						ERROR kandoomsg2("U", 9529, "") #9529 "This row entry already exist"
						NEXT FIELD path_code 
					END IF 
				END IF 
			END IF 

			SELECT security_ind 
			INTO l_arr_rec_access_priv[l_idx].security_module_ind 
			FROM kandoomodule 
			WHERE cmpy_code = p_cmpy_code 
			AND user_code = glob_rec_kandoouser_specific.sign_on_code 
			AND module_code = l_menu1_code 

			SELECT security_ind 
			INTO l_arr_rec_access_priv[l_idx].security_prog_ind 
			FROM menu3 
			WHERE menu1_code = l_menu1_code 
			AND menu2_code = l_menu2_code 
			AND menu3_code = l_menu3_code 
			#           DISPLAY l_arr_rec_access_priv[l_idx].security_module_ind,
			#                   l_arr_rec_access_priv[l_idx].security_prog_ind
			#               TO  sr_access_priv[scrn].security_module_ind,
			#                   sr_access_priv[scrn].security_prog_ind


	END INPUT 

	OPTIONS DELETE KEY f2 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del > 0 THEN 
			
			MESSAGE kandoomsg2("U", 8901, l_del) #prompt "There are VALUE Path Codes TO delete. Confirm...."
			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_access_priv[l_idx].delete_flag = "*" THEN 
						LET l_menu1_code = l_arr_rec_access_priv[l_idx].path_code[1,1] 
						LET l_menu2_code = l_arr_rec_access_priv[l_idx].path_code[2,2] 
						LET l_menu3_code = l_arr_rec_access_priv[l_idx].path_code[3,3] 

						DELETE FROM grant_deny_access 
						WHERE cmpy_code = p_cmpy_code 
						AND menu1_code = l_menu1_code 
						AND menu2_code = l_menu2_code 
						AND menu3_code = l_menu3_code 
						AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
						AND grant_deny_flag =	l_arr_rec_access_priv[l_idx].grant_deny_flag 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
	
	CLOSE WINDOW U152 
END FUNCTION {change_path_access} 


#######################################################################
# FUNCTION update_path_access(p_cmpy,
#                            p_path_code,
#                            p_old_path_code,
#                            p_access_flag,
#                            p_old_access_flag)
#
#
#######################################################################
FUNCTION update_path_access(p_cmpy, p_path_code,p_old_path_code,p_access_flag,p_old_access_flag) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_path_code CHAR(3) 
	DEFINE p_old_path_code CHAR(3) 
	DEFINE p_access_flag CHAR(1) 
	DEFINE p_old_access_flag CHAR(1) 
	DEFINE l_menu1_code CHAR(1) 
	DEFINE l_menu2_code CHAR(1) 
	DEFINE l_menu3_code CHAR(1) 
	DEFINE l_menu1_old CHAR(1) 
	DEFINE l_menu2_old CHAR(1) 
	DEFINE l_menu3_old CHAR(1) 

	IF p_path_code = " " OR p_path_code IS NULL THEN 
		RETURN TRUE 
	END IF 

	LET l_menu1_code = p_path_code[1,1] 
	LET l_menu2_code = p_path_code[2,2] 
	LET l_menu3_code = p_path_code[3,3] 

	SELECT * INTO glob_rec_grant_deny_access.* FROM grant_deny_access 
	WHERE cmpy_code = p_cmpy 
	AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
	AND menu1_code = l_menu1_code 
	AND menu2_code = l_menu2_code 
	AND menu3_code = l_menu3_code 

	IF (status=notfound) THEN 
		#DELETE OLD CODE FIRST BEFORE INSERTING THE NEW PATH CODE
		LET l_menu1_old = p_old_path_code[1,1] 
		LET l_menu2_old = p_old_path_code[2,2] 
		LET l_menu3_old = p_old_path_code[3,3] 

		DELETE FROM grant_deny_access 
		WHERE cmpy_code = p_cmpy 
		AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
		AND menu1_code = l_menu1_old 
		AND menu2_code = l_menu2_old 
		AND menu3_code = l_menu3_old 
		AND grant_deny_flag = p_old_access_flag 

		LET glob_rec_grant_deny_access.cmpy_code = p_cmpy 
		LET glob_rec_grant_deny_access.menu1_code = l_menu1_code 
		LET glob_rec_grant_deny_access.menu2_code = l_menu2_code 
		LET glob_rec_grant_deny_access.menu3_code = l_menu3_code 
		LET glob_rec_grant_deny_access.sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
		LET glob_rec_grant_deny_access.grant_deny_flag = p_access_flag 

		INSERT INTO grant_deny_access VALUES (glob_rec_grant_deny_access.*) 

	ELSE 

		IF p_access_flag = glob_rec_grant_deny_access.grant_deny_flag THEN 
			RETURN false 
		ELSE 
			IF p_old_path_code = p_path_code THEN 
				UPDATE grant_deny_access 
				SET grant_deny_flag = p_access_flag 
				WHERE cmpy_code = p_cmpy 
				AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
				AND menu1_code = l_menu1_code 
				AND menu2_code = l_menu2_code 
				AND menu3_code = l_menu3_code 
				AND grant_deny_flag = p_old_access_flag 
			ELSE 
				RETURN false 
			END IF 
		END IF 
	END IF 
	RETURN true 
END FUNCTION {update_path_access} 
#######################################################################
# END FUNCTION update_path_access(p_cmpy,
#                            p_path_code,
#                            p_old_path_code,
#                            p_access_flag,
#                            p_old_access_flag)
#######################################################################


#######################################################################
# FUNCTION delete_user_access(p_sign_on_code)
#
#
#######################################################################
FUNCTION delete_user_access(p_sign_on_code) 
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code 

	DELETE FROM kandoomodule 
	WHERE user_code = p_sign_on_code 

	DELETE FROM kandoousercmpy 
	WHERE sign_on_code = p_sign_on_code 

	DELETE FROM grant_deny_access 
	WHERE sign_on_code = p_sign_on_code 
END FUNCTION {delete_user_access} 
#######################################################################
# END FUNCTION delete_user_access(p_sign_on_code)
#######################################################################



#######################################################################
# FUNCTION check_acct_code(p_cmpy,p_acct_code)
#
#
#######################################################################
# check_acct_code
#
#  Used TO validate an entered account code, IF any part of the account
#  code contains a '?' the segment/code portion will NOT be validated.
#  It only checks against the coa table WHEN the code IS fully resolved
#  (ie. contains no '?' in the code portion AND the segments have been
#  validated. Returns TRUE FOR a valid account ELSE FALSE IF invalid.
#
#
#######################################################################
FUNCTION check_acct_code(p_cmpy, p_acct_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE account.acct_code 
	DEFINE l_temp_text LIKE account.acct_code 
	DEFINE l_type_ind LIKE structure.type_ind 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_arr_rec_structure DYNAMIC ARRAY OF t_rec_structure_ti_sn_ln_dt 
	#	DEFINE l_arr_rec_structure array[18] OF
	#		RECORD
	#          type_ind      LIKE structure.type_ind,
	#          start_num     LIKE structure.start_num,
	#          length_num    LIKE structure.length_num,
	#          default_text  LIKE structure.default_text
	#       END RECORD
	#DEFINE l_i SMALLINT
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_validate_flag SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_i SMALLINT 

	DECLARE c_structure CURSOR FOR 
	SELECT * 
	INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	ORDER BY start_num 

	LET l_idx = 0 

	FOREACH c_structure 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_structure[l_idx].type_ind = l_rec_structure.type_ind 
		LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
		LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
		LET l_arr_rec_structure[l_idx].default_text = l_rec_structure.default_text 
	END FOREACH 

	FOR l_i = 1 TO l_idx 
		LET l_type_ind = l_arr_rec_structure[l_i].type_ind 
		LET l_start_pos = l_arr_rec_structure[l_i].start_num 
		LET l_end_pos = (l_arr_rec_structure[l_i].start_num + l_arr_rec_structure[l_i].length_num - 1) 


		--------------------
		CASE 
			WHEN l_type_ind = "S" # segment 
				LET l_validate_flag = false 
				FOR l_cnt = l_start_pos TO l_end_pos 
					IF p_acct_code[l_cnt,l_cnt] <> "?" THEN 
						LET l_validate_flag = true 
						EXIT FOR 
					END IF 
				END FOR 
				
				IF l_validate_flag THEN 
					LET l_temp_text = p_acct_code[l_start_pos,l_end_pos] 
					SELECT * 
					FROM validflex 
					WHERE cmpy_code = p_cmpy 
					AND start_num = l_arr_rec_structure[l_i].start_num 
					AND flex_code = l_temp_text 
					IF (status=notfound) THEN 
						RETURN false 
					END IF 
				END IF 

			WHEN l_type_ind = "F" # filler 
				IF l_arr_rec_structure[l_i].default_text != p_acct_code[l_start_pos,l_start_pos] 
				THEN 
					RETURN false 
				END IF 

			WHEN l_type_ind = "C" # code 
				LET l_validate_flag = true 
				FOR l_cnt = l_start_pos TO l_end_pos 
					IF p_acct_code[l_cnt,l_cnt] = "?" THEN 
						LET l_validate_flag = false 
						EXIT FOR 
					END IF 
				END FOR 

				IF l_validate_flag THEN 
					SELECT * 
					FROM coa 
					WHERE cmpy_code = p_cmpy 
					AND acct_code = p_acct_code 
					IF (status=notfound) THEN 
						RETURN false 
					END IF 
				END IF 
		END CASE 
		-----------------------------------------------------

	END FOR 

	RETURN true 

END FUNCTION {check_acct_code}
#######################################################################
# END FUNCTION check_acct_code(p_cmpy, p_acct_code) 
#######################################################################