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

# Purpose    :    Insurance details

GLOBALS 
	DEFINE 
	batch_numeric INTEGER, 
	program_name CHAR(40), 
	screen_no CHAR(6), 
	fainsure_trn RECORD LIKE fainsure.*, 
	ans CHAR(1), 
	the_rowid INTEGER, 
	flag CHAR(1), 
	counter SMALLINT, 
	switch_char CHAR(1), 
	where_text CHAR(200), 
	query_text CHAR(250), 
	exist INTEGER, 
	not_found INTEGER, 
	try_again CHAR(1), 
	err_message CHAR(60), 
	array_rec ARRAY [200] OF RECORD 
		asset_code LIKE fainsure.asset_code, 
		add_on_code LIKE fainsure.add_on_code, 
		insure_value_amt LIKE fainsure.insure_value_amt 
	END RECORD, 
	array_rec2 ARRAY [200] OF RECORD 
		insure_comp_code LIKE fainsure.insure_comp_code, 
		policy_text LIKE fainsure.policy_text, 
		insure_start_date LIKE fainsure.insure_start_date, 
		insure_end_date LIKE fainsure.insure_end_date, 
		reminder_date LIKE fainsure.reminder_date 
	END RECORD 

END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("F36") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPTIONS #accept KEY esc, 
	DELETE KEY interrupt#, 
	#MESSAGE line first

	WHILE true 
		OPEN WINDOW win_main with FORM "F123" -- alch kd-757 
		CALL  windecoration_f("F123") -- alch kd-757 
		MESSAGE "Enter selection criteria - press ESC TO begin search" 
		CONSTRUCT BY NAME query_text ON fainsure.asset_code, 
		fainsure.add_on_code, 
		fainsure.insure_value_amt 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F36","const-fainsure-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 

		IF int_flag THEN 
			LET int_flag = false 
			EXIT program 
		END IF 

		LET where_text = "SELECT * ", 
		"FROM fainsure ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",query_text clipped, 
		"ORDER BY asset_code, add_on_code" 

		PREPARE statement1 FROM where_text 
		DECLARE curs_qry SCROLL CURSOR FOR statement1 

		CALL load_array() 
		IF not_found = 1 THEN 
			CALL add_fn() 
			CALL load_array() 
		END IF 

		WHILE true 
			DISPLAY ARRAY array_rec TO screen_rec.* 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","F36","display-arr-insure") 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
				ON KEY (f1) 
					CALL add_fn() 
					CALL load_array() 
					EXIT DISPLAY 

				ON KEY (control-m) 
					LET counter = arr_curr() 

					LET fainsure_trn.asset_code = array_rec[counter].asset_code 
					LET fainsure_trn.add_on_code = 
					array_rec[counter].add_on_code 
					LET fainsure_trn.insure_value_amt = 
					array_rec[counter].insure_value_amt 

					LET fainsure_trn.insure_comp_code = 
					array_rec2[counter].insure_comp_code 
					LET fainsure_trn.insure_end_date = 
					array_rec2[counter].insure_end_date 
					LET fainsure_trn.policy_text = 
					array_rec2[counter].policy_text 
					LET fainsure_trn.insure_start_date = 
					array_rec2[counter].insure_start_date 
					LET fainsure_trn.reminder_date = 
					array_rec2[counter].reminder_date 
					CALL edit_fn() 
					CALL load_array() 
					EXIT DISPLAY 

				ON KEY (f2) 
					LET counter = arr_curr() 
					LET fainsure_trn.asset_code = 
					array_rec[counter].asset_code 
					LET fainsure_trn.add_on_code = 
					array_rec[counter].add_on_code 
					LET fainsure_trn.insure_value_amt = 
					array_rec[counter].insure_value_amt 

					LET fainsure_trn.insure_comp_code = 
					array_rec2[counter].insure_comp_code 
					LET fainsure_trn.insure_end_date = 
					array_rec2[counter].insure_end_date 
					LET fainsure_trn.policy_text = 
					array_rec2[counter].policy_text 
					LET fainsure_trn.insure_start_date = 
					array_rec2[counter].insure_start_date 
					LET fainsure_trn.reminder_date = 
					array_rec2[counter].reminder_date 
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
	DELETE FROM fainsure WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = fainsure_trn.asset_code 
	AND add_on_code = fainsure_trn.add_on_code 
END FUNCTION 

FUNCTION add_fn() 
	DEFINE end_flag SMALLINT 

	OPEN WINDOW win_add with FORM "F122" -- alch kd-757 
	CALL  windecoration_f("F122") -- alch kd-757 
	MESSAGE " Enter insurance details AND ESC TO save" 

	LET end_flag = 0 

	INPUT BY NAME fainsure_trn.asset_code, 
	fainsure_trn.add_on_code, 
	fainsure_trn.insure_value_amt thru 
	fainsure_trn.reminder_date 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F36","inp-fainsure_trn-1") -- alch kd-504 
		ON KEY (interrupt) 
			LET int_flag = false 
			LET end_flag = 1 
			EXIT INPUT 

		ON ACTION "LOOKUP" infield(asset_code) --ON KEY (control-b) 
				CALL lookup_famast(glob_rec_kandoouser.cmpy_code) RETURNING 
					fainsure_trn.asset_code, 
					fainsure_trn.add_on_code 
				DISPLAY BY NAME 
					fainsure_trn.asset_code, 
					fainsure_trn.add_on_code 
				NEXT FIELD asset_code 
 
		AFTER FIELD add_on_code 
			IF val_asset() = 1 THEN 
				NEXT FIELD asset_code 
			ELSE 
				SELECT * 
				FROM fainsure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = fainsure_trn.asset_code 
				AND add_on_code = fainsure_trn.asset_code 
				IF NOT status THEN 
					ERROR "Asset allready has insurance policy" 
					NEXT FIELD asset_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	LET fainsure_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 

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

			LET err_message = "F36 - Insurance ID Insert" 

			INSERT INTO fainsure VALUES (fainsure_trn.*) 

		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 

	CLOSE WINDOW win_add 

END FUNCTION 

FUNCTION load_array() 

	DEFINE look_rec RECORD LIKE fainsure.* 

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

		LET array_rec[counter].asset_code = look_rec.asset_code 
		LET array_rec[counter].add_on_code = look_rec.add_on_code 
		LET array_rec[counter].insure_value_amt = look_rec.insure_value_amt 

		LET array_rec2[counter].insure_comp_code = look_rec.insure_comp_code 
		LET array_rec2[counter].insure_end_date = look_rec.insure_end_date 
		LET array_rec2[counter].policy_text = look_rec.policy_text 
		LET array_rec2[counter].insure_start_date=look_rec.insure_start_date 
		LET array_rec2[counter].reminder_date = look_rec.reminder_date 
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
	OPEN WINDOW win_add with FORM "F122" -- alch kd-757 
	CALL  windecoration_f("F122") -- alch kd-757 
	DISPLAY BY NAME fainsure_trn.asset_code, 
	fainsure_trn.add_on_code, 
	fainsure_trn.insure_value_amt thru 
	fainsure_trn.reminder_date 
	MESSAGE "Edit the data THEN press ESC OR press DEL TO EXIT" 
		INPUT BY NAME fainsure_trn.insure_value_amt thru fainsure_trn.reminder_date 
		WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F36","inp-fainsure-2") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
		IF int_flag THEN 
			LET int_flag = false 
			CLOSE WINDOW win_add 
			RETURN 
		END IF 

		LET fainsure_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 
		GOTO bypass 
		LABEL recovery: 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_message = " F36 - Insurance ID Update" 

			UPDATE fainsure SET * = fainsure_trn.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = fainsure_trn.asset_code 
			AND add_on_code = fainsure_trn.add_on_code 
		COMMIT WORK 
		WHENEVER ERROR stop 

		INITIALIZE fainsure_trn.* TO NULL 

		CLOSE WINDOW win_add 

END FUNCTION 

FUNCTION val_asset() 

	SELECT * 
	FROM famast 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = fainsure_trn.asset_code 
	AND add_on_code = fainsure_trn.add_on_code 

	IF status = notfound THEN 
		ERROR "Asset NOT found, try window" 
		RETURN 1 
	END IF 

	RETURN 0 

END FUNCTION 
