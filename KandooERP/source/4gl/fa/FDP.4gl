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

	Source code beautified by beautify.pl on 2020-01-03 10:37:00	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 

# Purpose    :    Depreciation rate maintenance

GLOBALS 
	DEFINE 
	batch_numeric INTEGER, 
	program_name CHAR(40), 
	screen_no CHAR(6), 
	fadepmethod_trn RECORD LIKE fadepmethod.*, 
	ans CHAR(1), 
	the_rowid INTEGER, 
	flag CHAR(1), 
	counter SMALLINT, 
	switch_char CHAR(1), 
	try_again CHAR(1), 
	err_message CHAR(60), 
	where_text CHAR(200), 
	query_text CHAR(250), 
	exist INTEGER , 
	not_found INTEGER, 
	array_rec ARRAY [200] OF RECORD 
		depn_code LIKE fadepmethod.depn_code, 
		depn_method_code LIKE fadepmethod.depn_method_code 
	END RECORD, 
	array_rec2 ARRAY [200] OF RECORD 
		depn_method_rate LIKE fadepmethod.depn_method_rate 
	END RECORD 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("FDP") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPTIONS #message line first, 
	accept KEY esc#, 
	#DELETE KEY interrupt

	WHILE true 
		OPEN WINDOW win_main with FORM "F169" -- alch kd-757 
		CALL  windecoration_f("F169") -- alch kd-757 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME query_text ON fadepmethod.depn_code, 
		fadepmethod.depn_method_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","FDP","const-fadepmethod-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT program 
		END IF 
		LET where_text = "SELECT * ", 
		"FROM fadepmethod ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ", query_text clipped, " ", 
		"ORDER BY depn_code" 

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
					CALL publish_toolbar("kandoo","FDP","display-arr-depmethod") 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
				ON KEY (f1) 
					CALL add_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (control-m) 
					LET counter = arr_curr() 
					LET fadepmethod_trn.depn_code = array_rec[counter].depn_code 
					LET fadepmethod_trn.depn_method_code = 
					array_rec[counter].depn_method_code 
					LET fadepmethod_trn.depn_method_rate = 
					array_rec2[counter].depn_method_rate 
					CALL edit_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (f2) 
					LET counter = arr_curr() 
					LET fadepmethod_trn.depn_code = array_rec[counter].depn_code 
					LET fadepmethod_trn.depn_method_code = 
					array_rec[counter].depn_method_code 
					LET fadepmethod_trn.depn_method_rate = 
					array_rec2[counter].depn_method_rate 
					CALL delete_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (control-w) 
					CALL kandoohelp("") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
			END DISPLAY 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT WHILE 
			END IF 
		END WHILE 
		CLOSE WINDOW win_main 
	END WHILE 
END MAIN 

FUNCTION delete_fn() 
	DELETE FROM fadepmethod 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND depn_code = fadepmethod_trn.depn_code 
END FUNCTION 

FUNCTION add_fn() 
	DEFINE end_flag SMALLINT 

	INITIALIZE fadepmethod_trn.* TO NULL 
	OPEN WINDOW win_add with FORM "F168" -- alch kd-757 
	CALL  windecoration_f("F168") -- alch kd-757 
	LET msgresp = kandoomsg("U",1020,"depreciation rate details") 
	#1020 Enter depreciation rate details;  OK TO Continue.
	LET end_flag = 0 
	INPUT BY NAME fadepmethod_trn.depn_code thru 
	fadepmethod_trn.depn_method_rate 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FDP","inp-fadepmethod_trn-1") -- alch kd-504 
		AFTER FIELD depn_code 
			IF fadepmethod_trn.depn_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD depn_code 
			ELSE 
				SELECT * FROM fadepmethod 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND depn_code = fadepmethod_trn.depn_code 
				IF NOT status THEN 
					LET msgresp = kandoomsg("G",9027,"Depreciation code") 
					#9027 Depreciation code already exists.
					NEXT FIELD depn_code 
				END IF 
			END IF 
		AFTER FIELD depn_method_rate 
			IF fadepmethod_trn.depn_method_code = "SLL" OR 
			fadepmethod_trn.depn_method_code = "DVL" THEN 
				IF fadepmethod_trn.depn_method_rate IS NOT NULL OR 
				fadepmethod_trn.depn_method_rate > 0 THEN 
					LET msgresp = kandoomsg("F",9522,"") 
					#9522 Percentage entered IS NOT applicable TO method code.
					NEXT FIELD depn_method_rate 
				END IF 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET end_flag = 1 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	LET fadepmethod_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 
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
			LET err_message = "F32 - Depreciation rate ID Insert" 
			IF fadepmethod_trn.depn_code IS NOT NULL THEN 
				INSERT INTO fadepmethod VALUES (fadepmethod_trn.*) 
			END IF 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 
	CLOSE WINDOW win_add 
END FUNCTION 

FUNCTION load_array() 
	DEFINE look_rec RECORD LIKE fadepmethod.* 

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
		LET array_rec[counter].depn_code = look_rec.depn_code 
		LET array_rec[counter].depn_method_code = look_rec.depn_method_code 
		LET array_rec2[counter].depn_method_rate = look_rec.depn_method_rate 
	END FOREACH 

	LET not_found = 0 
	IF NOT exist THEN 
		LET not_found = 1 
	END IF 
	LET msgresp = kandoomsg("U",1003,"") 
	#1003 F1 TO add, RETURN on line TO change, F2 TO delete"
	CALL set_count(counter) 
	OPTIONS MESSAGE line first, 
	PROMPT line last-1, 
	comment line last, 
	ERROR line last-1 
END FUNCTION 

FUNCTION edit_fn() 
	DEFINE saved_code LIKE fadepmethod.depn_code 

	OPEN WINDOW win_add with FORM "F168" -- alch kd-757 
	CALL  windecoration_f("F168") -- alch kd-757 
	LET msgresp = kandoomsg("U",1047,"Depreciation") 
	#1047 Edit Depreciation Details;  OK TO Continue.
	LET saved_code = fadepmethod_trn.depn_code 
	INPUT BY NAME fadepmethod_trn.depn_code thru 
	fadepmethod_trn.depn_method_rate WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FDP","inp-fadepmethod_trn-2") -- alch kd-504 
		AFTER FIELD depn_code 
			IF fadepmethod_trn.depn_code != saved_code THEN 
				IF fadepmethod_trn.depn_code IS NULL THEN 
					LET msgresp = kandoomsg("G",9026,"Depreciation code") 
					#9026 Depreciation code must be entered.
					NEXT FIELD depn_code 
				ELSE 
					SELECT * FROM fadepmethod 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND depn_code = fadepmethod_trn.depn_code 
					IF NOT status THEN 
						LET msgresp = kandoomsg("G",9027,"Depreciation code") 
						#9027 Depreciation code already exists.
						NEXT FIELD depn_code 
					END IF 
				END IF 
			END IF 
		AFTER FIELD depn_method_rate 
			IF fadepmethod_trn.depn_method_code = "SLL" OR 
			fadepmethod_trn.depn_method_code = "DVL" THEN 
				IF fadepmethod_trn.depn_method_rate IS NOT NULL OR 
				fadepmethod_trn.depn_method_rate > 0 THEN 
					LET msgresp = kandoomsg("F",9522,"") 
					#9522 Percentage entered IS NOT applicable TO method code.
					NEXT FIELD depn_method_rate 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW win_add 
		RETURN 
	END IF 

	LET fadepmethod_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "FDP - Depreciation Rate ID Edit" 

		UPDATE fadepmethod SET fadepmethod.* = fadepmethod_trn.* 
		WHERE fadepmethod.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND fadepmethod.depn_code = 
		array_rec[counter].depn_code 

	COMMIT WORK 
	WHENEVER ERROR stop 
	INITIALIZE fadepmethod_trn.* TO NULL 
	CLOSE WINDOW win_add 
END FUNCTION 
