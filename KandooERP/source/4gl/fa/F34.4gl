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

# Purpose    :    category code maintenance

GLOBALS 
	DEFINE 
	idx, 
	scrn SMALLINT, 
	batch_numeric INTEGER, 
	program_name CHAR(40), 
	pr_facat RECORD LIKE facat.*, 
	ans CHAR(1), 
	the_rowid INTEGER, 
	flag CHAR(1), 
	switch_char CHAR(1), 
	where_text CHAR(200), 
	query_text CHAR(250), 
	try_again CHAR(1), 
	err_message CHAR(60), 
	not_found INTEGER, 
	pa_facat ARRAY [200] OF RECORD 
		scroll_flag CHAR(1), 
		facat_code LIKE facat.facat_code, 
		facat_text LIKE facat.facat_text, 
		class_text LIKE facat.class_text, 
		deprec_flag LIKE facat.deprec_flag 
	END RECORD 
END GLOBALS 

MAIN 
	DEFINE 
	pr_scroll_flag CHAR(1), 
	del_cnt SMALLINT 

	#Initial UI Init
	CALL setModuleId("F34") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	LET program_name = "Category Table" 

	OPEN WINDOW f121 with FORM "F121" -- alch kd-757 
	CALL  windecoration_f("F121") -- alch kd-757 
	WHILE true 
		CLEAR FORM 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 Enter selection criteria; OK TO continue.
		CONSTRUCT BY NAME query_text ON facat.facat_code, 
		facat.facat_text, 
		facat.class_text, 
		facat.deprec_flag 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F34","const-facat-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

		LET where_text = "SELECT * FROM facat ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ", query_text clipped," ", 
		"ORDER BY facat_code" 
		PREPARE s_facat FROM where_text 
		DECLARE c_facat SCROLL CURSOR FOR s_facat 
		LET idx = 0 
		FOREACH c_facat INTO pr_facat.* 
			LET idx = idx + 1 
			LET pa_facat[idx].scroll_flag = NULL 
			LET pa_facat[idx].facat_code = pr_facat.facat_code 
			LET pa_facat[idx].facat_text = pr_facat.facat_text 
			LET pa_facat[idx].class_text = pr_facat.class_text 
			LET pa_facat[idx].deprec_flag = pr_facat.deprec_flag 
			IF idx = 200 THEN 
				LET msgresp = kandoomsg("U",6100,idx) 
				#6100 First XXXX records selected only. More may be available.
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET msgresp = kandoomsg("U",9113,idx) 
		#9113 XXX records selected.
		IF idx = 0 THEN 
			LET idx = 1 
			INITIALIZE pa_facat[idx].* TO NULL 
		END IF 
		CALL set_count(idx) 
		LET msgresp = kandoomsg("U",1003,"") 
		#1003 F1 Add; F2 Delete; TAB TO edit line.
		OPTIONS INSERT KEY f1, 
		DELETE KEY f36 
		LET del_cnt = 0 
		INPUT ARRAY pa_facat WITHOUT DEFAULTS FROM sr_facat.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F34","inp_arr-pa_facat-1") -- alch kd-504 
			BEFORE INSERT 
				IF idx < arr_count() 
				OR (idx = arr_count() AND pr_facat.facat_code IS NOT null) THEN 
					INITIALIZE pr_facat.* TO NULL 
					CALL add_fn() 
					LET pa_facat[idx].facat_code = pr_facat.facat_code 
					LET pa_facat[idx].facat_text = pr_facat.facat_text 
					LET pa_facat[idx].class_text = pr_facat.class_text 
					LET pa_facat[idx].deprec_flag = pr_facat.deprec_flag 
					DISPLAY pa_facat[idx].* TO sr_facat[scrn].* 

				END IF 
				ON KEY (F1,F2) --add RECORD 
					--- modif ericv init ON KEY(F2)
					IF pa_facat[idx].scroll_flag IS NULL THEN 
						SELECT unique 1 FROM glasset 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND facat_code = pa_facat[idx].facat_code 
						IF status != notfound THEN 
							LET msgresp = kandoomsg("F",9539,"") 
							#9539 Cannot delete category code as it IS being used by GL Asset.
							NEXT FIELD scroll_flag 
						END IF 
						SELECT unique 1 FROM famast 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND facat_code = pa_facat[idx].facat_code 
						IF status != notfound THEN 
							LET msgresp = kandoomsg("F",9540,"") 
							#9539 Cannot delete category code as it IS being used by Asset.
							NEXT FIELD scroll_flag 
						END IF 
						LET pa_facat[idx].scroll_flag = "*" 
						LET del_cnt = del_cnt + 1 
					ELSE 
						LET pa_facat[idx].scroll_flag = NULL 
						LET del_cnt = del_cnt - 1 
					END IF 
					NEXT FIELD scroll_flag 
			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_facat.facat_code = pa_facat[idx].facat_code 
				LET pr_facat.facat_text = pa_facat[idx].facat_text 
				LET pr_facat.class_text = pa_facat[idx].class_text 
				LET pr_facat.deprec_flag = pa_facat[idx].deprec_flag 
			AFTER ROW 
				LET pa_facat[idx].facat_code = pr_facat.facat_code 
				LET pa_facat[idx].facat_text = pr_facat.facat_text 
				LET pa_facat[idx].class_text = pr_facat.class_text 
				LET pa_facat[idx].deprec_flag = pr_facat.deprec_flag 
				DISPLAY pa_facat[idx].* TO sr_facat[scrn].* 

			BEFORE FIELD scroll_flag 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				DISPLAY pa_facat[idx].* TO sr_facat[scrn].* 

				LET pr_scroll_flag = pa_facat[idx].scroll_flag 
			AFTER FIELD scroll_flag 
				LET pa_facat[idx].scroll_flag = pr_scroll_flag 
				IF pa_facat[idx+1].facat_code IS NULL 
				AND fgl_lastkey() = fgl_keyval("down") THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD facat_code 
				IF pr_facat.facat_code IS NOT NULL THEN 
					CALL edit_fn() 
					LET pa_facat[idx].facat_code = pr_facat.facat_code 
					LET pa_facat[idx].facat_text = pr_facat.facat_text 
					LET pa_facat[idx].class_text = pr_facat.class_text 
					LET pa_facat[idx].deprec_flag = pr_facat.deprec_flag 
					DISPLAY pa_facat[idx].* TO sr_facat[scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (control-w) 
				CALL kandoohelp("") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			IF del_cnt > 0 THEN 
				LET msgresp = kandoomsg("U",8020,del_cnt) 
				#8014 Confirm TO Delete XXX record(s)? (Y/N)
				IF msgresp = "Y" THEN 
					FOR idx = 1 TO arr_count() 
						IF pa_facat[idx].scroll_flag = "*" THEN 
							DELETE FROM facat 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND facat_code = pa_facat[idx].facat_code 
						END IF 
					END FOR 
				END IF 
			END IF 
		END IF 
	END WHILE 
	CLOSE WINDOW f121 
END MAIN 

FUNCTION add_fn() 
	DEFINE i SMALLINT 

	OPEN WINDOW f120 with FORM "F120" -- alch kd-757 
	CALL  windecoration_f("F120") -- alch kd-757 
	LET msgresp = kandoomsg("F",1513,"") 
	#1513 Enter Category details; OK TO continue.
	INPUT BY NAME pr_facat.facat_code, 
	pr_facat.facat_text, 
	pr_facat.cost_limit_amt, 
	pr_facat.class_text, 
	pr_facat.deprec_flag WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F34","inp-pr_facat-1") -- alch kd-504 
		AFTER FIELD facat_code 
			IF pr_facat.facat_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD facat_code 
			END IF 
			SELECT unique 1 FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = pr_facat.facat_code 
			IF status != notfound THEN 
				LET msgresp = kandoomsg("F",9529,"") 
				#9529 This category code already exists.
				NEXT FIELD facat_code 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW f120 
		FOR i = idx TO arr_count() 
			IF i = arr_count() THEN 
				INITIALIZE pa_facat[i].* TO NULL 
			ELSE 
				LET pa_facat[i].* = pa_facat[i+1].* 
			END IF 
		END FOR 
		LET pr_facat.facat_code = pa_facat[idx].facat_code 
		LET pr_facat.facat_text = pa_facat[idx].facat_text 
		LET pr_facat.class_text = pa_facat[idx].class_text 
		LET pr_facat.deprec_flag = pa_facat[idx].deprec_flag 
		FOR i = 0 TO 10-scrn 
			DISPLAY pa_facat[idx+i].* TO sr_facat[scrn+i].* 

		END FOR 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET pr_facat.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_facat.facat_code IS NOT NULL THEN 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message, status) != "Y" THEN 
			CLOSE WINDOW f120 
			FOR i = idx TO arr_count() 
				IF i = arr_count() THEN 
					INITIALIZE pa_facat[i].* TO NULL 
				ELSE 
					LET pa_facat[i].* = pa_facat[i+1].* 
				END IF 
			END FOR 
			LET pr_facat.facat_code = pa_facat[idx].facat_code 
			LET pr_facat.facat_text = pa_facat[idx].facat_text 
			LET pr_facat.class_text = pa_facat[idx].class_text 
			LET pr_facat.deprec_flag = pa_facat[idx].deprec_flag 
			FOR i = 0 TO 10-scrn 
				DISPLAY pa_facat[idx+i].* TO sr_facat[scrn+i].* 

			END FOR 
			RETURN 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		LET err_message = "FZ4 - Inserting Category" 
		INSERT INTO facat VALUES (pr_facat.*) 
	END IF 
	CLOSE WINDOW f120 
END FUNCTION 


FUNCTION edit_fn() 
	DEFINE 
	ps_facat RECORD LIKE facat.* 

	LET ps_facat.* = pr_facat.* 
	OPEN WINDOW f120 with FORM "F120" -- alch kd-757 
	CALL  windecoration_f("F120") -- alch kd-757 
	LET msgresp = kandoomsg("F",1513,"") 
	#1513 Enter Category details; OK TO continue.
	DISPLAY BY NAME pr_facat.facat_code thru pr_facat.deprec_flag 
	INPUT BY NAME pr_facat.facat_text, 
	pr_facat.cost_limit_amt, 
	pr_facat.class_text, 
	pr_facat.deprec_flag WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F34","inp-pr_facat-3") -- alch kd-504 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET pr_facat.* = ps_facat.* 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW f120 
		RETURN 
	END IF 
	LET pr_facat.cmpy_code = glob_rec_kandoouser.cmpy_code 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) != "Y" THEN 
		CLOSE WINDOW f120 
		RETURN 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	LET err_message = "FZ4 - Updating Category" 
	BEGIN WORK 
		UPDATE facat 
		SET facat.* = pr_facat.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND facat.facat_code = pr_facat.facat_code 
	COMMIT WORK 
	CLOSE WINDOW f120 
	WHENEVER ERROR stop 
END FUNCTION 

