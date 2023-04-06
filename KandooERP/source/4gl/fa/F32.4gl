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
GLOBALS "F32_GLOBALS.4gl" 

MAIN 

	#Initial UI Init
	CALL setModuleId("F32") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPTIONS 
	#MESSAGE LINE FIRST,
	#ACCEPT KEY ESC,
	DELETE KEY interrupt 

	#   LET program_name = "Location Table"
	#   LET screen_no = "F32"

	#    CALL STARTLOG(get_settings_logPath_forFile("error.sys"))
	#    WHENEVER ERROR CALL error_screen

	#CALL getco()

	#
	# Main WHILE loop
	#
	WHILE true 

		OPEN WINDOW win_main with FORM "F117" -- alch kd-757 
		CALL  windecoration_f("F117") -- alch kd-757 

		MESSAGE "Enter selection criteria - press ", 
		"ESC TO begin search" 

		CONSTRUCT BY NAME query_text ON 
		falocation.location_code, 
		falocation.location_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F32","const-falocation-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 

		IF int_flag THEN 
			LET int_flag = false 
			EXIT program 
		END IF 

		LET where_text = "SELECT * FROM falocation WHERE ", 
		" cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		query_text clipped, "ORDER BY location_code" 
		PREPARE statement1 FROM where_text 
		DECLARE curs_qry SCROLL CURSOR FOR statement1 

		CALL load_array() 
		IF not_found = 1 THEN 
			CALL add_fn() 
			CALL load_array() 
		END IF 
		#
		# Now loop thru all records chosen
		#
		WHILE true 
			DISPLAY ARRAY array_rec TO sr_falocation.* 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","F32","display-arr-location") 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
				ON KEY (f1) 
					CALL add_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (control-m) 
					LET counter = arr_curr() 
					LET falocation_trn.location_code = array_rec[counter].location_code 
					LET falocation_trn.location_text = array_rec[counter].location_text 
					LET falocation_trn.manager_text = array_rec2[counter].manager_text 
					LET falocation_trn.loc_add1_text = array_rec2[counter].loc_add1_text 
					LET falocation_trn.loc_add2_text = array_rec2[counter].loc_add2_text 
					LET falocation_trn.loc_add3_text = array_rec2[counter].loc_add3_text 
					LET falocation_trn.loc_add4_text = array_rec2[counter].loc_add4_text 
					CALL edit_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (f2) 
					LET counter = arr_curr() 
					LET falocation_trn.location_code = array_rec[counter].location_code 
					LET falocation_trn.location_text = array_rec[counter].location_text 
					LET falocation_trn.manager_text = array_rec2[counter].manager_text 
					LET falocation_trn.loc_add1_text = array_rec2[counter].loc_add1_text 
					LET falocation_trn.loc_add2_text = array_rec2[counter].loc_add2_text 
					LET falocation_trn.loc_add3_text = array_rec2[counter].loc_add3_text 
					LET falocation_trn.loc_add4_text = array_rec2[counter].loc_add4_text 
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
	DELETE FROM falocation WHERE 
	falocation_trn.location_code = location_code AND 
	falocation_trn.location_text = location_text 

END FUNCTION 

FUNCTION add_fn() 
	DEFINE end_flag SMALLINT 
	INITIALIZE falocation_trn.* TO NULL 
	OPEN WINDOW win_add with FORM "F116" -- alch kd-757 
	CALL  windecoration_f("F116") -- alch kd-757 
	MESSAGE " Enter location details AND ESC TO save" 
	attribute(yellow) 
	LET end_flag = 0 
	INPUT BY NAME falocation_trn.location_code thru falocation_trn.loc_add4_text 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F32","inp-falocation_trn-1") -- alch kd-504 
		ON KEY (INTERRUPT) 
			LET int_flag = false 
			LET end_flag = 1 
			EXIT INPUT 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	LET falocation_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 

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
			LET err_message = "F32 - Location ID Insert" 
			INSERT INTO falocation VALUES (falocation_trn.*) 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 

	CLOSE WINDOW win_add 

END FUNCTION 

FUNCTION load_array() 

	DEFINE look_rec RECORD LIKE falocation.* 

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
		LET array_rec[counter].location_code = look_rec.location_code 
		LET array_rec[counter].location_text = look_rec.location_text 

		LET array_rec2[counter].manager_text = look_rec.manager_text 
		LET array_rec2[counter].loc_add1_text = look_rec.loc_add1_text 
		LET array_rec2[counter].loc_add2_text = look_rec.loc_add2_text 
		LET array_rec2[counter].loc_add3_text = look_rec.loc_add3_text 
		LET array_rec2[counter].loc_add4_text = look_rec.loc_add4_text 
	END FOREACH 

	LET not_found = 0 
	IF NOT exist THEN 
		LET not_found = 1 
	END IF 

	MESSAGE "F1 TO add, RETURN on line TO change, F2 TO delete" 
	attribute(yellow) 
	CALL set_count(counter) 

	OPTIONS MESSAGE line first, 
	PROMPT line last-1, 
	comment line last, 
	ERROR line last-1 
END FUNCTION 


FUNCTION edit_fn() 

	OPEN WINDOW win_add with FORM "F116" -- alch kd-757 
	CALL  windecoration_f("F116") -- alch kd-757 

	MESSAGE " Edit the data THEN press ESC OR press DEL TO EXIT" 
		attribute(yellow) 

		INPUT BY NAME falocation_trn.location_code thru falocation_trn.loc_add4_text 
		WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F32","inp-falocation_trn-2") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
		IF int_flag THEN 
			LET int_flag = false 
			CLOSE WINDOW win_add 
			RETURN 
		END IF 

		LET falocation_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 
		GOTO bypass 
		LABEL recovery: 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_message = "F32 - Location ID Edit" 

			WHILE true 
				UPDATE falocation SET 
				falocation.* = falocation_trn.* 
				WHERE falocation.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND falocation.location_code = array_rec[counter].location_code 
				AND falocation.location_text = array_rec[counter].location_text 
				EXIT WHILE 
			END WHILE 
		COMMIT WORK 
		WHENEVER ERROR stop 
		INITIALIZE falocation_trn.* TO NULL 
		CLOSE WINDOW win_add 

END FUNCTION 
