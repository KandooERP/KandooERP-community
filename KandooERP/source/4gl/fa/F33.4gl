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

	Source code beautified by beautify.pl on 2020-01-03 10:36:55	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 

GLOBALS 
	DEFINE batch_numeric INTEGER 
	DEFINE program_name CHAR(40) 
	DEFINE screen_no CHAR(6) 
	DEFINE faauth_trn RECORD LIKE faauth.* 
	DEFINE ans CHAR(1) 
	DEFINE the_rowid INTEGER 
	DEFINE flag CHAR(1) 
	DEFINE counter SMALLINT 

	DEFINE switch_char CHAR(1) 
	DEFINE try_again CHAR(1) 
	DEFINE err_message CHAR(60) 
	DEFINE where_text CHAR(200) 
	DEFINE query_text CHAR(250) 
	DEFINE exist INTEGER 
	DEFINE not_found INTEGER 
	DEFINE array_rec ARRAY [200] OF RECORD 
		auth_code LIKE faauth.auth_code, 
		auth_text LIKE faauth.auth_text 
	END RECORD 
END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("F33") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPTIONS #accept KEY esc, 
	DELETE KEY interrupt#, 
	#MESSAGE line first

	LET program_name = "Authority Table" 
	LET screen_no = "F33" 

	#    CALL STARTLOG(get_settings_logPath_forFile("error.sys"))
	#    WHENEVER ERROR CALL error_screen

	#CALL getco()

	WHILE true 
		OPEN WINDOW win_main with FORM "F118" -- alch kd-757 
		CALL  windecoration_f("F118") -- alch kd-757 

		MESSAGE "Enter selection criteria - press ESC TO begin search" 

		CONSTRUCT BY NAME query_text ON 
		faauth.auth_code, 
		faauth.auth_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F33","const-faauth-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 

		IF int_flag THEN 
			LET int_flag = false 
			EXIT program 
		END IF 

		LET where_text = "SELECT * FROM faauth WHERE ", 
		" cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		query_text clipped, "ORDER BY auth_code" 

		PREPARE statement1 FROM where_text 
		DECLARE curs_qry SCROLL CURSOR FOR statement1 

		CALL load_array() 
		IF not_found = 1 THEN 
			CALL add_fn() 
			CALL load_array() 
		END IF 
		#
		# Now loop thru all records
		#
		WHILE true 
			DISPLAY ARRAY array_rec TO screen_rec.* 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","F33","display-arr-auth") 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
				ON KEY (f1) 
					CALL add_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (control-m) 
					LET counter = arr_curr() 
					LET faauth_trn.auth_code = array_rec[counter].auth_code 
					LET faauth_trn.auth_text = array_rec[counter].auth_text 
					CALL edit_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (f2) 
					LET counter = arr_curr() 
					LET faauth_trn.auth_code = array_rec[counter].auth_code 
					LET faauth_trn.auth_text = array_rec[counter].auth_text 
					CALL delete_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (control-w) 
					CALL kandoohelp("") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
			END DISPLAY 
			IF int_flag THEN 
				LET int_flag = false 
				EXIT WHILE 
			END IF 
		END WHILE 

		CLOSE WINDOW win_main 
	END WHILE 

END MAIN 

FUNCTION delete_fn() 
	DELETE FROM faauth WHERE 
	auth_code = faauth_trn.auth_code AND 
	auth_text = faauth_trn.auth_text 

END FUNCTION 


FUNCTION add_fn() 
	DEFINE end_flag SMALLINT 

	OPEN WINDOW win_add with FORM "F119" -- alch kd-757 
	CALL  windecoration_f("F119") -- alch kd-757 
	MESSAGE " Enter authorisation details AND ESC TO save" 
	LET end_flag = 0 

	INPUT BY NAME faauth_trn.auth_code thru faauth_trn.auth_text 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F33","inp-faauth_trn-1") -- alch kd-504 
			#BEFORE FIELD cmpy_code
			#LET faauth_trn.cmpy_code = glob_rec_kandoouser.cmpy_code
			#DISPLAY BY NAME faauth_trn.cmpy_code
			#NEXT FIELD auth_code
			#AFTER FIELD cmpy_code
			#IF cmpy_val() = TRUE THEN
			#NEXT FIELD cmpy_code
			#END IF
		ON KEY (interrupt) 
			LET int_flag = false 
			LET end_flag = 1 
			EXIT INPUT 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	LET faauth_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF end_flag = 0 THEN 
		GOTO bypass 
		LABEL recovery: 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_message = "F33 - Authority ID Insert" 
			INSERT INTO faauth VALUES (faauth_trn.*) 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 

	CLOSE WINDOW win_add 

END FUNCTION 

#FUNCTION cmpy_val()
#     SELECT cmpy_code FROM company
#   WHERE company.cmpy_code = faauth_trn.cmpy_code
#     IF STATUS = NOTFOUND THEN
#        ERROR "     No company by that code on file !!!   CHECK AND REINPUT"
#   RETURN TRUE #user entered cmpy_code does NOT exist in company table
#     ELSE
#   RETURN FALSE #user entered cmpy_code found in the company table
#     END IF
#END FUNCTION

FUNCTION load_array() 

	DEFINE look_rec RECORD LIKE faauth.* 

	OPTIONS 
	PROMPT line last-1, 
	ERROR line last-1, 
	comment line last, 
	MESSAGE line first, 
	NEXT KEY f3, 
	previous KEY f2 

	LET flag = "N" 
	LET exist = false 

	LET counter = 0 
	FOREACH curs_qry INTO look_rec.* 
		LET exist = true 
		LET counter = counter + 1 
		#      LET array_rec[counter].cmpy_code = look_rec.cmpy_code
		LET array_rec[counter].auth_code = look_rec.auth_code 
		LET array_rec[counter].auth_text = look_rec.auth_text 
	END FOREACH 

	LET not_found = 0 
	IF NOT exist THEN 
		LET not_found = 1 
	END IF 

	MESSAGE "F1 TO add, RETURN on line TO change, F2 TO delete" 

	CALL set_count(counter) 

	OPTIONS MESSAGE line first, 
	PROMPT line last-1, 
	comment line last, 
	ERROR line last-1 

END FUNCTION 

FUNCTION edit_fn() 
	OPEN WINDOW win_add with FORM "F119" -- alch kd-757 
	CALL  windecoration_f("F119") -- alch kd-757 
	DISPLAY BY NAME faauth_trn.auth_code thru faauth_trn.auth_text 
	MESSAGE " Edit the data THEN press ESC OR press DEL TO EXIT" 
		INPUT BY NAME faauth_trn.auth_code thru faauth_trn.auth_text 
		WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F33","inp-faauth_trn-2") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
		IF int_flag THEN 
			LET int_flag = false 
			CLOSE WINDOW win_add 
			RETURN 
		END IF 

		LET faauth_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 
		GOTO bypass 
		LABEL recovery: 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_message = "F33 Authority ID Update" 
			WHILE true 
				UPDATE faauth SET faauth.* = faauth_trn.* 
				WHERE faauth.auth_code = array_rec[counter].auth_code 
				AND faauth.auth_text = array_rec[counter].auth_text 
				AND faauth.cmpy_code = glob_rec_kandoouser.cmpy_code 
				EXIT WHILE 
			END WHILE 
		COMMIT WORK 
		WHENEVER ERROR stop 

		INITIALIZE faauth_trn.* TO NULL 

		CLOSE WINDOW win_add 

END FUNCTION 

FUNCTION getco() 
	DEFINE spos,ppos SMALLINT 
	OPTIONS MESSAGE line first, 
	PROMPT line last-1, 
	comment line last, 
	ERROR line last-1 
	LET batch_numeric = 0 
	LET ppos = ( 68 - length (program_name clipped)) / 2 

	DISPLAY 
	" " 
	at 1,1 

	DISPLAY program_name clipped at 3,ppos 
	DISPLAY screen_no clipped at 3,63 

	MESSAGE 
	" " 
END FUNCTION 

FUNCTION error_screen() 
	DEFINE error_text STRING 
	DEFINE msgstr STRING 
	# Check FOR errors you do NOT wish TO trap
	IF status = -246 THEN 
		RETURN 
	END IF 
	LET error_text = err_get(status) 

	LET msgstr = "The following Error has occured!\n" 
	LET msgstr = msgstr, "Please call your EDP Center TO log this error\n" 
	LET msgstr = msgstr, trim(error_text), "\n" 

	CALL fgl_winmessage("Error",msgStr,"error") #huho 


END FUNCTION 
