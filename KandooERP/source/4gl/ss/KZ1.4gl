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

	Source code beautified by beautify.pl on 2019-12-31 14:28:33	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 

#       KZ1 maintains subproduct type codes

GLOBALS 
	DEFINE 
	pr_ssparms RECORD LIKE ssparms.* 
END GLOBALS 

MAIN 
	DEFINE msgresp LIKE language.yes_flag 
	#Initial UI Init
	CALL setModuleId("KZ1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * INTO pr_ssparms.* 
	FROM ssparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("K",9114,"") 
		#9114 Subscription parameters NOT found
		SLEEP 2 
		EXIT program 
	END IF 
	OPEN WINDOW k146 at 2,5 WITH FORM "K146" 
	attribute(border) 
	WHILE select_type() 
		CALL scan_type() 
	END WHILE 
	CLOSE WINDOW k146 
END MAIN 


FUNCTION select_type() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	query_text CHAR(300), 
	where_text CHAR(200) 

	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria - ESC TO continue
	CLEAR FORM 
	CONSTRUCT BY NAME where_text ON type_code, 
	desc_text, 
	renew_flag, 
	start_day_num, 
	start_mth_num, 
	end_day_num, 
	end_mth_num, 
	format_ind 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
	LET msgresp = kandoomsg("U",1005,"") 
	#1002 Searching database - please wait
	LET query_text = "SELECT * FROM substype ", 
	"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",where_text clipped," ", 
	"ORDER BY cmpy_code,", 
	"type_code" 
	PREPARE s_substype FROM query_text 
	DECLARE c_substype CURSOR FOR s_substype 
	RETURN true 
END IF 
END FUNCTION 


FUNCTION scan_type() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_substype RECORD LIKE substype.*, 
	pr_scroll_flag CHAR(1), 
	pa_substype array[100] OF RECORD 
		scroll_flag CHAR(1), 
		type_code LIKE substype.type_code, 
		desc_text LIKE substype.desc_text, 
		renew_flag LIKE substype.renew_flag, 
		start_day_num LIKE substype.start_day_num, 
		start_mth_num LIKE substype.start_mth_num, 
		end_day_num LIKE substype.end_day_num, 
		end_mth_num LIKE substype.end_mth_num, 
		format_ind LIKE substype.format_ind 
	END RECORD, 
	pr_rowid INTEGER, 
	idx,scrn,del_cnt SMALLINT 

	LET idx = 0 
	FOREACH c_substype INTO pr_substype.* 
		LET idx = idx + 1 
		LET pa_substype[idx].scroll_flag = NULL 
		LET pa_substype[idx].type_code = pr_substype.type_code 
		LET pa_substype[idx].desc_text = pr_substype.desc_text 
		LET pa_substype[idx].renew_flag = pr_substype.renew_flag 
		LET pa_substype[idx].start_day_num = pr_substype.start_day_num 
		LET pa_substype[idx].start_mth_num = pr_substype.start_mth_num 
		LET pa_substype[idx].end_day_num = pr_substype.end_day_num 
		LET pa_substype[idx].end_mth_num = pr_substype.end_mth_num 
		LET pa_substype[idx].format_ind = pr_substype.format_ind 
		IF idx = 100 THEN 
			LET msgresp = kandoomsg("U",9100,"100") 
			#9100 " First ??? substypes selected only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp=kandoomsg("U",9101,"") 
		#9101 "No subproduct type satisfies the selection criteria"
		LET idx = 1 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("U",1003,"") 
	#1003 "F1 TO add, RETURN on line TO change, F2 TO delete"
	INPUT ARRAY pa_substype WITHOUT DEFAULTS FROM sr_substype.* 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_substype[idx].scroll_flag 
			DISPLAY pa_substype[idx].* 
			TO sr_substype[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_substype[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_substype[idx+1].type_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					# There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD type_code 
			IF pa_substype[idx].type_code IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
			IF edit_type(pa_substype[idx].type_code) THEN 
				SELECT type_code, 
				desc_text, 
				renew_flag, 
				start_day_num, 
				start_mth_num, 
				end_day_num, 
				end_mth_num, 
				format_ind 
				INTO pa_substype[idx].type_code, 
				pa_substype[idx].desc_text, 
				pa_substype[idx].renew_flag, 
				pa_substype[idx].start_day_num, 
				pa_substype[idx].start_mth_num, 
				pa_substype[idx].end_day_num, 
				pa_substype[idx].end_mth_num, 
				pa_substype[idx].format_ind 
				FROM substype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pa_substype[idx].type_code 
			END IF 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET pr_rowid = edit_type("") 
				SELECT type_code, 
				desc_text, 
				renew_flag, 
				start_day_num, 
				start_mth_num, 
				end_day_num, 
				end_mth_num, 
				format_ind 
				INTO pa_substype[idx].type_code, 
				pa_substype[idx].desc_text, 
				pa_substype[idx].renew_flag, 
				pa_substype[idx].start_day_num, 
				pa_substype[idx].start_mth_num, 
				pa_substype[idx].end_day_num, 
				pa_substype[idx].end_mth_num, 
				pa_substype[idx].format_ind 
				FROM substype 
				WHERE rowid = pr_rowid 
				IF status = notfound THEN 
					FOR idx = arr_curr() TO arr_count() 
						LET pa_substype[idx].* = pa_substype[idx+1].* 
						IF pa_substype[idx].type_code IS NULL THEN 
							LET pa_substype[idx].start_day_num = NULL 
							LET pa_substype[idx].start_mth_num = NULL 
							LET pa_substype[idx].end_day_num = NULL 
							LET pa_substype[idx].end_mth_num = NULL 
						END IF 
						IF scrn <= 14 THEN 
							DISPLAY pa_substype[idx].* 
							TO sr_substype[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					INITIALIZE pa_substype[idx].* TO NULL 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		ON KEY (F2) 
			IF pa_substype[idx].type_code IS NOT NULL THEN 
				IF pa_substype[idx].scroll_flag IS NULL THEN 
					IF delete_type(pa_substype[idx].type_code) THEN 
						LET pa_substype[idx].scroll_flag = "*" 
						LET del_cnt = del_cnt + 1 
					END IF 
				ELSE 
				LET pa_substype[idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
		END IF 
		NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_substype[idx].* 
			TO sr_substype[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
	IF del_cnt > 0 THEN 
		LET msgresp = kandoomsg("U",8020,del_cnt) 
		#8020 Confirm TO Delete ",del_cnt," substype(s)? (Y/N)"
		IF msgresp = "Y" THEN 
			FOR idx = 1 TO arr_count() 
				IF pa_substype[idx].scroll_flag = "*" THEN 
					IF delete_type(pa_substype[idx].type_code) THEN 
						DELETE FROM substype 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND type_code = pa_substype[idx].type_code 
					END IF 
				END IF 
			END FOR 
		END IF 
	END IF 
END IF 
END FUNCTION 


FUNCTION edit_type(pr_type_code) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_substype RECORD LIKE substype.*, 
	pr_type_code LIKE substype.type_code, 
	pr_coa RECORD LIKE coa.*, 
	inv_day_prompt,inv_mth_prompt CHAR(20), 
	label_text,pr_temp_text CHAR(40) 

	OPEN WINDOW k152 at 3,4 WITH FORM "K152" 
	attribute(border) 
	SELECT * INTO pr_substype.* 
	FROM substype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_type_code 
	IF sqlca.sqlcode = notfound THEN 
		LET pr_substype.type_code = pr_type_code 
	END IF 
	CASE 
		WHEN pr_substype.format_ind = "1" 
			LET label_text = pr_ssparms.format1_desc 
		WHEN pr_substype.format_ind = "2" 
			LET label_text = pr_ssparms.format2_desc 
		WHEN pr_substype.format_ind = "3" 
			LET label_text = pr_ssparms.format3_desc 
	END CASE 
	DISPLAY BY NAME label_text 

	SELECT desc_text INTO pr_coa.desc_text FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_substype.subacct_code 
	IF status != notfound THEN 
		DISPLAY pr_coa.desc_text TO acct_text 

	END IF 
	IF pr_substype.inv_ind = "2" THEN 
		LET inv_day_prompt = "Invoice day......." 
		LET inv_mth_prompt = "Month...." 
	ELSE 
	LET inv_day_prompt = NULL 
	LET inv_mth_prompt = NULL 
	LET pr_substype.inv_day_num = NULL 
	LET pr_substype.inv_mth_num = NULL 
END IF 
DISPLAY BY NAME inv_day_prompt, 
inv_mth_prompt 
attribute(white) 
LET msgresp = kandoomsg("U",1020,"Subscription type") 
#1020 " Enter Subscription Type Details - ESC TO Continue"
INPUT BY NAME pr_substype.type_code, 
pr_substype.desc_text, 
pr_substype.inv_ind, 
pr_substype.inv_day_num, 
pr_substype.inv_mth_num, 
pr_substype.renew_flag, 
pr_substype.format_ind, 
pr_substype.subacct_code, 
pr_substype.start_day_num, 
pr_substype.start_mth_num, 
pr_substype.end_day_num, 
pr_substype.end_mth_num 
WITHOUT DEFAULTS 

	ON KEY (control-b) 
		CASE 
			WHEN infield(subacct_code) 
				LET pr_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
				IF pr_temp_text IS NOT NULL THEN 
					LET pr_substype.subacct_code = pr_temp_text 
					NEXT FIELD subacct_code 
				END IF 
		END CASE 
	BEFORE FIELD type_code 
		IF pr_type_code IS NOT NULL THEN 
			NEXT FIELD NEXT 
		END IF 
	AFTER FIELD type_code 
		IF pr_substype.type_code IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription Type code must be entered "
			NEXT FIELD type_code 
		ELSE 
		SELECT unique 1 FROM substype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_substype.type_code 
		IF status = 0 THEN 
			LET msgresp = kandoomsg("U",9104,"") 
			#9104 " Subscription Type code must be unique "
			NEXT FIELD type_code 
		END IF 
	END IF 
	AFTER FIELD inv_ind 
		IF pr_substype.inv_ind IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription Invoice Type code must be entered "
			NEXT FIELD inv_ind 
		END IF 
		IF pr_substype.inv_ind = "2" THEN 
			LET inv_day_prompt = "Invoice day......." 
			LET inv_mth_prompt = "Month...." 
		ELSE 
		LET inv_day_prompt = NULL 
		LET inv_mth_prompt = NULL 
		LET pr_substype.inv_day_num = NULL 
		LET pr_substype.inv_mth_num = NULL 
	END IF 
	DISPLAY BY NAME inv_day_prompt, 
	inv_mth_prompt 
	attribute(white) 
	DISPLAY BY NAME pr_substype.inv_day_num, 
	pr_substype.inv_mth_num 

	BEFORE FIELD inv_day_num 
		IF pr_substype.inv_ind <> "2" THEN 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("accept") 
					NEXT FIELD renew_flag 
				OTHERWISE 
					NEXT FIELD inv_ind 
			END CASE 
		END IF 
	BEFORE FIELD inv_mth_num 
		IF pr_substype.inv_ind <> "2" THEN 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("accept") 
					NEXT FIELD renew_flag 
				OTHERWISE 
					NEXT FIELD inv_ind 
			END CASE 
		END IF 
	AFTER FIELD inv_day_num 
		IF pr_substype.inv_day_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription Start day must be entered
			NEXT FIELD inv_day_num 
		END IF 
	AFTER FIELD inv_mth_num 
		IF pr_substype.inv_mth_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription Start mth must be entered
			NEXT FIELD inv_mth_num 
		END IF 
	AFTER FIELD renew_flag 
		IF pr_substype.renew_flag IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Auto renewable flag must be entered
			NEXT FIELD renew_flag 
		ELSE 
		IF pr_substype.renew_flag <> "Y" AND 
		pr_substype.renew_flag <> "N" THEN 
			LET msgresp = kandoomsg("U",9103,"") 
			#9103 " Auto renewable flag must be Y OR N
			NEXT FIELD renew_flag 
		END IF 
	END IF 
	AFTER FIELD subacct_code 
		IF pr_substype.subacct_code IS NOT NULL THEN 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,pr_substype.subacct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD subacct_code 
			ELSE 
			SELECT * INTO pr_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = pr_substype.subacct_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 Account Code NOT found - Try Window
				NEXT FIELD subacct_code 
			ELSE 
			DISPLAY pr_coa.desc_text TO acct_text 

		END IF 
	END IF 
END IF 
	AFTER FIELD start_day_num 
		IF pr_substype.start_day_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription Start day must be entered
			NEXT FIELD start_day_num 
		END IF 
	AFTER FIELD start_mth_num 
		IF pr_substype.start_mth_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription Start mth must be entered
			NEXT FIELD start_mth_num 
		END IF 
	AFTER FIELD end_day_num 
		IF pr_substype.end_day_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription END day must be entered
			NEXT FIELD end_day_num 
		END IF 
	AFTER FIELD end_mth_num 
		IF pr_substype.end_mth_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription END mth must be entered
			NEXT FIELD end_mth_num 
		END IF 
	AFTER FIELD format_ind 
		IF pr_substype.format_ind IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Label FORMAT indicator must be entered
			NEXT FIELD format_ind 
		END IF 
		CASE 
			WHEN pr_substype.format_ind = "1" 
				LET label_text = pr_ssparms.format1_desc 
			WHEN pr_substype.format_ind = "2" 
				LET label_text = pr_ssparms.format2_desc 
			WHEN pr_substype.format_ind = "3" 
				LET label_text = pr_ssparms.format3_desc 
		END CASE 
		DISPLAY BY NAME label_text 

	AFTER INPUT 
		IF not(int_flag OR quit_flag) THEN 
			IF pr_substype.type_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 " Subscription Type code must be entered "
				NEXT FIELD type_code 
			END IF 
			IF pr_substype.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 "Must enter a description"
				NEXT FIELD desc_text 
			END IF 
			IF pr_substype.inv_ind IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 " Subscription Invoice Type code must be entered "
				NEXT FIELD inv_ind 
			END IF 
			IF pr_substype.renew_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 " Auto renewable flag must be entered
				NEXT FIELD renew_flag 
			ELSE 
			IF pr_substype.renew_flag <> "Y" AND 
			pr_substype.renew_flag <> "N" THEN 
				LET msgresp = kandoomsg("U",9103,"") 
				#9103 " Auto renewable flag must be Y OR N
				NEXT FIELD renew_flag 
			END IF 
		END IF 
		IF pr_substype.format_ind IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Label FORMAT indicator must be entered
			NEXT FIELD format_ind 
		END IF 
		IF pr_substype.start_day_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription Start day must be entered
			NEXT FIELD start_day_num 
		END IF 
		IF pr_substype.start_mth_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription Start mth must be entered
			NEXT FIELD start_mth_num 
		END IF 
		IF pr_substype.end_day_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription END day must be entered
			NEXT FIELD end_day_num 
		END IF 
		IF pr_substype.end_mth_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 " Subscription END mth must be entered
			NEXT FIELD end_mth_num 
		END IF 
		WHENEVER ERROR CONTINUE 
		IF pr_substype.inv_ind = "2" THEN 
			IF mdy(pr_substype.inv_mth_num, 
			pr_substype.inv_day_num, 
			year(today)) THEN 
			ELSE 
			WHENEVER ERROR stop 
			NEXT FIELD inv_day_num 
		END IF 
	END IF 
	IF mdy(pr_substype.start_mth_num, 
	pr_substype.start_day_num, 
	year(today)) THEN 
	ELSE 
	WHENEVER ERROR stop 
	NEXT FIELD start_day_num 
END IF 
IF mdy(pr_substype.end_mth_num, 
pr_substype.end_day_num, 
year(today)) THEN 
ELSE 
WHENEVER ERROR stop 
NEXT FIELD end_day_num 
END IF 
WHENEVER ERROR stop 
END IF 
	ON KEY (control-w) 
		CALL kandoohelp("") 
END INPUT 
CLOSE WINDOW k152 
IF int_flag OR quit_flag THEN 
	LET int_flag = false 
	LET quit_flag = false 
	RETURN false 
ELSE 
IF pr_type_code IS NULL THEN 
	LET pr_substype.cmpy_code = glob_rec_kandoouser.cmpy_code 
	INSERT INTO substype VALUES (pr_substype.*) 
	RETURN sqlca.sqlerrd[6] 
ELSE 
UPDATE substype 
SET substype.* = pr_substype.* 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND type_code = pr_type_code 
RETURN sqlca.sqlerrd[3] 
END IF 
END IF 
END FUNCTION 


FUNCTION delete_type(pr_type_code) 
	DEFINE 
	pr_type_code LIKE substype.type_code 

	SELECT unique 1 FROM subproduct 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_type_code 
	IF sqlca.sqlcode = 0 THEN 
		#LET msgresp=kandoomsg("E",7047,pr_type_code)
		#7047" Interval type IS in use - Deletion IS NOT permitted"
		ERROR " Subscription type IS in use - Deletion IS NOT permitted" 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


