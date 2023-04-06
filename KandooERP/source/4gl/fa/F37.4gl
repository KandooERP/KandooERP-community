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

# Purpose    :    maintain lease details

GLOBALS 
	DEFINE 
	batch_numeric INTEGER, 
	program_name CHAR(40), 
	screen_no CHAR(6), 
	falease_trn RECORD LIKE falease.*, 
	ans CHAR(1), 
	try_again CHAR(1), 
	err_message CHAR(60), 
	the_rowid INTEGER, 
	flag CHAR(1), 
	counter SMALLINT, 
	switch_char CHAR(1), 
	where_text CHAR(200), 
	query_text CHAR(250), 
	exist INTEGER, 
	not_found INTEGER, 
	array_rec ARRAY [200] OF RECORD 
		asset_code LIKE falease.asset_code, 
		add_on_code LIKE falease.add_on_code, 
		lease_value_amt LIKE falease.lease_value_amt 
	END RECORD, 
	array_rec_2 ARRAY [200] OF RECORD 
		lease_tot_rent_amt LIKE falease.lease_tot_rent_amt, 
		lease_st_date LIKE falease.lease_st_date, 
		lease_end_date LIKE falease.lease_end_date, 
		install_value_amt LIKE falease.install_value_amt, 
		lease_no_inst_num LIKE falease.lease_no_inst_num, 
		lease_residual_amt LIKE falease.lease_residual_amt, 
		lease_imp_per LIKE falease.lease_imp_per 
	END RECORD, 
	pr_famast RECORD LIKE famast.* 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("F37") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPTIONS #accept KEY esc, 
	DELETE KEY interrupt#, 
	#MESSAGE line first

	LET program_name = "Leases" 
	LET screen_no = "F37" 

	OPEN WINDOW win_main with FORM "F125" -- alch kd-757 
	CALL  windecoration_f("F125") -- alch kd-757 
	WHILE true 
		MESSAGE "Enter selection criteria - press ESC TO begin search" 
		CONSTRUCT BY NAME query_text ON falease.asset_code, 
		falease.add_on_code, 
		falease.lease_value_amt 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F37","const-falease-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 
		IF int_flag THEN 
			LET int_flag = false 
			EXIT program 
		END IF 

		LET where_text = "SELECT * ", 
		"FROM falease ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ", query_text clipped," ", 
		"ORDER BY asset_code,add_on_code" 

		PREPARE statement1 FROM where_text 
		DECLARE curs_qry SCROLL CURSOR FOR statement1 

		CALL load_array() 
		IF not_found THEN 
			CALL add_fn() 
			CALL load_array() 
		END IF 

		WHILE true 
			DISPLAY ARRAY array_rec TO screen_rec.* 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","F37","display-arr-lease") 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
				ON KEY (f1) 
					CALL add_fn() 
					CALL load_array() 
					CONTINUE WHILE 

				ON KEY (control-m) 
					LET counter = arr_curr() 
					LET falease_trn.asset_code = array_rec[counter].asset_code 
					LET falease_trn.add_on_code = array_rec[counter].add_on_code 
					LET falease_trn.lease_value_amt = 
					array_rec[counter].lease_value_amt 
					LET falease_trn.lease_tot_rent_amt = 
					array_rec_2[counter].lease_tot_rent_amt 
					LET falease_trn.lease_st_date = 
					array_rec_2[counter].lease_st_date 
					LET falease_trn.lease_end_date = 
					array_rec_2[counter].lease_end_date 
					LET falease_trn.install_value_amt = 
					array_rec_2[counter].install_value_amt 
					LET falease_trn.lease_no_inst_num = 
					array_rec_2[counter].lease_no_inst_num 
					LET falease_trn.lease_residual_amt = 
					array_rec_2[counter].lease_residual_amt 
					LET falease_trn.lease_imp_per = 
					array_rec_2[counter].lease_imp_per 
					CALL edit_fn() 
					CALL load_array() 
					CONTINUE WHILE 

				ON KEY (f2) 
					LET counter = arr_curr() 
					LET falease_trn.asset_code = array_rec[counter].asset_code 
					LET falease_trn.add_on_code = array_rec[counter].add_on_code 
					LET falease_trn.lease_value_amt = 
					array_rec[counter].lease_value_amt 
					LET falease_trn.lease_tot_rent_amt = 
					array_rec_2[counter].lease_tot_rent_amt 
					LET falease_trn.lease_st_date = 
					array_rec_2[counter].lease_st_date 
					LET falease_trn.lease_end_date = 
					array_rec_2[counter].lease_end_date 
					LET falease_trn.install_value_amt = 
					array_rec_2[counter].install_value_amt 
					LET falease_trn.lease_no_inst_num = 
					array_rec_2[counter].lease_no_inst_num 
					LET falease_trn.lease_residual_amt = 
					array_rec_2[counter].lease_residual_amt 
					LET falease_trn.lease_imp_per = 
					array_rec_2[counter].lease_imp_per 

					CALL delete_fn() 
					CALL load_array() 
					CONTINUE WHILE 
				ON KEY (control-w) 
					CALL kandoohelp("") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
			END DISPLAY 

			IF int_flag THEN 
				LET int_flag = false 
				EXIT program 
			END IF 
			EXIT WHILE 
		END WHILE 
	END WHILE 
	CLOSE WINDOW win_main 

END MAIN 

FUNCTION delete_fn() 
	DELETE FROM falease 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = falease_trn.asset_code 
	AND add_on_code = falease_trn.add_on_code 
END FUNCTION 

FUNCTION add_fn() 
	DEFINE end_flag SMALLINT 

	OPEN WINDOW win_add with FORM "F124" -- alch kd-757 
	CALL  windecoration_f("F124") -- alch kd-757 
	MESSAGE "Enter lease details AND ESC TO save" 
	INPUT BY NAME falease_trn.asset_code, 
	falease_trn.add_on_code, 
	falease_trn.lease_value_amt thru falease_trn.lease_imp_per 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F37","inp-falease_trn-5") -- alch kd-504 
		ON KEY (interrupt) 
			LET int_flag = false 
			LET end_flag = 1 
			EXIT INPUT 

		ON ACTION "LOOKUP" infield(asset_code) --ON KEY (control-b)  
				CALL lookup_famast(glob_rec_kandoouser.cmpy_code) RETURNING 
					falease_trn.asset_code, 
					falease_trn.add_on_code 
				DISPLAY BY NAME 
					falease_trn.asset_code, 
					falease_trn.add_on_code 


		AFTER FIELD add_on_code 
			IF val_asset() THEN 
				NEXT FIELD asset_code 
			ELSE 
				SELECT * 
				FROM falease 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = falease_trn.asset_code 
				AND add_on_code = falease.add_on_code 
				IF NOT status THEN 
					ERROR "Asset allready has a lease" 
					NEXT FIELD asset_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	LET falease_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 

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
			LET err_message = "F37 - Lease ID Insert" 

			INSERT INTO falease VALUES (falease_trn.*) 

		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 

	CLOSE WINDOW win_add 

END FUNCTION 

FUNCTION load_array() 

	DEFINE look_rec RECORD LIKE falease.* 

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
		LET array_rec[counter].lease_value_amt = look_rec.lease_value_amt 

		LET array_rec_2[counter].lease_tot_rent_amt = 
		look_rec.lease_tot_rent_amt 
		LET array_rec_2[counter].lease_st_date = look_rec.lease_st_date 
		LET array_rec_2[counter].lease_end_date = look_rec.lease_end_date 
		LET array_rec_2[counter].install_value_amt = look_rec.install_value_amt 
		LET array_rec_2[counter].lease_no_inst_num = look_rec.lease_no_inst_num 
		LET array_rec_2[counter].lease_residual_amt = 
		look_rec.lease_residual_amt 
		LET array_rec_2[counter].lease_imp_per = look_rec.lease_imp_per 
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
	OPEN WINDOW win_add with FORM "F124" -- alch kd-757 
	CALL  windecoration_f("F124") -- alch kd-757 
	DISPLAY BY NAME falease_trn.asset_code thru falease_trn.lease_imp_per 
	MESSAGE "Edit the data THEN press ESC OR press DEL TO EXIT" 
		INPUT BY NAME falease_trn.lease_value_amt thru falease_trn.lease_imp_per 
		WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F37","inp-lease_value_amt-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
		IF int_flag THEN 
			LET int_flag = false 
			CLOSE WINDOW win_add 
			RETURN 
		END IF 

		LET falease_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 
		GOTO bypass 
		LABEL recovery: 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_message = "F37 - Lease ID Update" 

			UPDATE falease SET falease.* = falease_trn.* 
			WHERE falease.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND falease.asset_code = 
			array_rec[counter].asset_code 
		COMMIT WORK 

		WHENEVER ERROR stop 

		INITIALIZE falease_trn.* TO NULL 

		CLOSE WINDOW win_add 

END FUNCTION 

FUNCTION val_asset() 

	SELECT * 
	INTO pr_famast.* 
	FROM famast 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = falease_trn.asset_code 
	AND add_on_code = falease_trn.add_on_code 

	IF status = notfound THEN 
		ERROR "Asset NOT found, try window" 
		RETURN true 
	END IF 

	IF pr_famast.acquist_code IS NULL OR (pr_famast.acquist_code != "L") THEN 
		ERROR "Asset NOT tagged as Leased in menu F11 " 
		RETURN true 
	END IF 

	RETURN false 

END FUNCTION 
