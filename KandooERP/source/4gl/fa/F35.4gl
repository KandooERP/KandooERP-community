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

# Purpose    :    maintain responsibility codes

GLOBALS 
	DEFINE 
	batch_numeric INTEGER, 
	program_name CHAR(40), 
	screen_no CHAR(6), 
	faresp_trn RECORD LIKE faresp.*, 
	ans CHAR(1), 
	the_rowid INTEGER, 
	flag CHAR(1), 
	counter SMALLINT, 
	switch_char CHAR(1), 
	try_again CHAR(1), 
	err_message CHAR(60), 
	where_text CHAR(200), 
	query_text CHAR(250), 
	exist INTEGER, 
	not_found INTEGER, 

	del_cnt SMALLINT, 
	edit_flag SMALLINT, 
	esc_flag SMALLINT, 
	array_rec ARRAY [200] OF RECORD 
		scroll_flag CHAR(1), 
		faresp_code LIKE faresp.faresp_code, 
		faresp_text LIKE faresp.faresp_text 
	END RECORD 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("F35") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPTIONS #accept KEY esc, 
	DELETE KEY interrupt#, 
	#MESSAGE line first

	WHILE true 
		OPEN WINDOW win_main with FORM "F127" -- alch kd-757 
		CALL  windecoration_f("F127") -- alch kd-757 
		#1862 MESSAGE "Enter selection criteria - press ESC TO begin search"
		LET msgresp = kandoomsg("A",1001,"") 

		CONSTRUCT BY NAME query_text ON 
		faresp.faresp_code, 
		faresp.faresp_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F35","const-faresp-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
			EXIT program 
		END IF 
		LET del_cnt = 0 

		LET where_text = "SELECT * FROM faresp WHERE ", 
		" cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		query_text clipped, "ORDER BY faresp_code" 

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
					CALL publish_toolbar("kandoo","F35","display-arr-resp") 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
				ON KEY (f1) 
					CALL add_fn() 
					CALL load_array() 
					EXIT DISPLAY 

				ON KEY (control-m) 
					LET counter = arr_curr() 
					LET faresp_trn.faresp_code = array_rec[counter].faresp_code 
					LET faresp_trn.faresp_text = array_rec[counter].faresp_text 

					CALL edit_fn() 
					CALL load_array() 
					EXIT DISPLAY 


				ON KEY (ESC) 
					LET esc_flag = true 
					EXIT DISPLAY 


				ON KEY (f2) 
					LET counter = arr_curr() 

					IF array_rec[counter].faresp_code IS NOT NULL THEN 
						IF array_rec[counter].scroll_flag IS NULL THEN 
							LET edit_flag = false 
							IF check_used(array_rec[counter].faresp_code) THEN 
								LET array_rec[counter].scroll_flag = "*" 
								LET del_cnt = del_cnt + 1 
							END IF 
						ELSE 
							LET array_rec[counter].scroll_flag = NULL 
							LET del_cnt = del_cnt - 1 
						END IF 
					END IF 
					EXIT DISPLAY 
				ON KEY (control-w) 
					CALL kandoohelp("") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
			END DISPLAY 

			IF int_flag OR quit_flag OR esc_flag THEN 
				LET esc_flag = false 


				EXIT WHILE 
			END IF 
		END WHILE 

		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
		ELSE 
			IF del_cnt > 0 THEN 
				#1503 Confirm deletion of ",del_cnt," responsibility codes (Y/N)"
				LET msgresp = kandoomsg("F", 1503, del_cnt) 
				IF msgresp = "Y" THEN 
					#1005 Updating database - please wait
					LET msgresp = kandoomsg("A",1005,"") 
					FOR counter = 1 TO arr_count() 
						IF array_rec[counter].scroll_flag = "*" THEN 
							LET edit_flag = false 
							IF check_used(array_rec[counter].faresp_code) THEN 
								DELETE FROM faresp 
								WHERE faresp.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
								faresp.faresp_code = array_rec[counter].faresp_code AND 
								faresp.faresp_text = array_rec[counter].faresp_text 
							END IF 
						END IF 
					END FOR 
				END IF 
			END IF 
		END IF 

		CLOSE WINDOW win_main 

	END WHILE 

END MAIN 









FUNCTION add_fn() 
	DEFINE end_flag SMALLINT 

	OPEN WINDOW win_add with FORM "F126" -- alch kd-757 
	CALL  windecoration_f("F126") -- alch kd-757 
	# 1862MESSAGE " Enter authorisation details AND ESC TO save"
	LET msgresp = kandoomsg("U", 1512, "") 
	LET end_flag = 0 
	INPUT BY NAME faresp_trn.faresp_code thru faresp_trn.faresp_text 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F35","inp-faresp-1") -- alch kd-504 
		AFTER FIELD faresp_code 
			SELECT unique 1 FROM faresp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			faresp_code = faresp_trn.faresp_code 
			IF sqlca.sqlcode = 0 THEN 
				LET msgresp = kandoomsg("F", 1506, faresp_trn.faresp_code) 
				NEXT FIELD faresp_code 
			END IF 
		ON KEY (interrupt) 
			LET int_flag = false 
			LET end_flag = 1 
			EXIT INPUT 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	LET faresp_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 

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
			LET err_message = "F35 - Responsibility Insert" 
			INSERT INTO faresp VALUES (faresp_trn.*) 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 

	CLOSE WINDOW win_add 

END FUNCTION 


FUNCTION load_array() 

	DEFINE look_rec RECORD LIKE faresp.* 

	OPTIONS 
	PROMPT line last-1, 
	ERROR line last-1, 
	comment line last, 
	MESSAGE line FIRST 



	LET flag = "N" 
	LET exist = false 

	LET counter = 0 
	FOREACH curs_qry INTO look_rec.* 
		LET exist = true 
		LET counter = counter + 1 
		#       LET array_rec[counter].cmpy_code = look_rec.cmpy_code
		LET array_rec[counter].scroll_flag = NULL 
		LET array_rec[counter].faresp_code = look_rec.faresp_code 
		LET array_rec[counter].faresp_text = look_rec.faresp_text 
	END FOREACH 

	LET not_found = 0 
	IF NOT exist THEN 
		LET not_found = 1 
	END IF 

	# MESSAGE "F1 TO add, RETURN on line TO change, F2 TO delete"
	LET msgresp = kandoomsg("A",1003,"") 

	CALL set_count(counter) 

	OPTIONS 
	MESSAGE line first, 
	PROMPT line last-1, 
	comment line last, 
	ERROR line last-1 

END FUNCTION 

FUNCTION edit_fn() 
	OPEN WINDOW win_add with FORM "F126" -- alch kd-757 
	CALL  windecoration_f("F126") -- alch kd-757 

	DISPLAY BY NAME faresp_trn.faresp_code thru faresp_trn.faresp_text 

	#" Edit the data THEN press ESC OR press DEL TO EXIT"
	LET msgresp = kandoomsg("U", 1512, "") 

	# IF code used on asset THEN dont allow amendment
	LET edit_flag = true 
	IF check_used(faresp_trn.faresp_code) THEN 
		INPUT BY NAME faresp_trn.faresp_code thru faresp_trn.faresp_text 
		WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F35","inp-faresp_trn-4") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
	ELSE 
		INPUT BY NAME faresp_trn.faresp_text 
		WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F35","inp-faresp_trn-5") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
	END IF 


	IF int_flag THEN 
		LET int_flag = false 
		CLOSE WINDOW win_add 
		RETURN 
	END IF 

	LET faresp_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "F35 Responsibility ID Update" 
		WHILE true 
			UPDATE faresp SET faresp.* = faresp_trn.* 
			WHERE faresp.faresp_code = array_rec[counter].faresp_code 
			AND faresp.faresp_text = array_rec[counter].faresp_text 
			AND faresp.cmpy_code = glob_rec_kandoouser.cmpy_code 
			EXIT WHILE 
		END WHILE 
	COMMIT WORK 
	WHENEVER ERROR stop 

	INITIALIZE faresp_trn.* TO NULL 

	CLOSE WINDOW win_add 

END FUNCTION 


FUNCTION check_used(pr_faresp_code) 
	DEFINE pr_faresp_code LIKE faresp.faresp_code 

	SELECT unique 1 FROM famast 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	faresp_code = pr_faresp_code 

	IF sqlca.sqlcode = 0 THEN 
		#1504 Responsibility code appears on asset master - No deletion/ changes allowed
		IF edit_flag THEN 
			LET msgresp=kandoomsg("F", 1505, "") 
		ELSE 
			LET msgresp=kandoomsg("F", 1504, "") 
		END IF 
		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 

