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

#       KZ2 maintains subscription codes

GLOBALS 
	DEFINE 
	pa_dates array[100] OF RECORD 
		scroll_flag CHAR(1), 
		plan_iss_date LIKE subissues.plan_iss_date, 
		desc_text LIKE subissues.desc_text, 
		issue_num LIKE subissues.issue_num, 
		act_iss_date LIKE subissues.act_iss_date 
	END RECORD 
END GLOBALS 

MAIN 
	DEFINE msgresp LIKE language.yes_flag 
	#Initial UI Init
	CALL setModuleId("KZ2") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW k149 WITH FORM "K149" 

	WHILE select_subscript() 
		CALL scan_subscript() 
	END WHILE 
	CLOSE WINDOW k149 
END MAIN 


FUNCTION select_subscript() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	query_text CHAR(300), 
	where_text CHAR(200) 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria - ESC TO continue
	CONSTRUCT BY NAME where_text ON part_code, 
	desc_text, 
	type_code 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database - please wait
	LET query_text = "SELECT * FROM subproduct ", 
	"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",where_text clipped," ", 
	"ORDER BY part_code" 
	PREPARE s_subproduct FROM query_text 
	DECLARE c_subproduct CURSOR FOR s_subproduct 
	RETURN true 
END IF 
END FUNCTION 


FUNCTION scan_subscript() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_scroll_flag CHAR(1), 
	pa_subproduct array[100] OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE subproduct.part_code, 
		desc_text LIKE subproduct.desc_text, 
		type_code LIKE subproduct.type_code 
	END RECORD, 
	pr_rowid INTEGER, 
	idx,scrn,del_cnt SMALLINT 

	LET idx = 0 
	FOREACH c_subproduct INTO pr_subproduct.* 
		LET idx = idx + 1 
		LET pa_subproduct[idx].scroll_flag = NULL 
		LET pa_subproduct[idx].part_code = pr_subproduct.part_code 
		LET pa_subproduct[idx].desc_text = pr_subproduct.desc_text 
		LET pa_subproduct[idx].type_code = pr_subproduct.type_code 
		IF idx = 100 THEN 
			LET msgresp = kandoomsg("K",9002,"100") 
			#9002 " First ??? rows selected only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp=kandoomsg("K",9003,"") 
		#9003 " No rows selected"
		LET idx = 1 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("K",1013,"") 
	# "F1 TO add, RETURN on line TO change, F2 TO delete"
	INPUT ARRAY pa_subproduct WITHOUT DEFAULTS FROM sr_subproduct.* 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_subproduct[idx].scroll_flag 
			DISPLAY pa_subproduct[idx].* TO sr_subproduct[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_subproduct[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_subproduct[idx+1].part_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("K",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (F6) 
			SELECT * INTO pr_subproduct.* 
			FROM subproduct 
			WHERE part_code = pa_subproduct[idx].part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pr_subproduct.linetype_ind = "1" THEN 
				IF subproduct(pr_subproduct.*,0) THEN 
				END IF 
			END IF 
		BEFORE FIELD part_code 
			IF pa_subproduct[idx].part_code IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
			IF edit_subscript(pa_subproduct[idx].part_code) THEN 
				SELECT part_code, 
				desc_text, 
				type_code 
				INTO pa_subproduct[idx].part_code, 
				pa_subproduct[idx].desc_text, 
				pa_subproduct[idx].type_code 
				FROM subproduct 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pa_subproduct[idx].part_code 
			END IF 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET pr_rowid = edit_subscript("") 
				SELECT part_code, 
				desc_text, 
				type_code 
				INTO pa_subproduct[idx].part_code, 
				pa_subproduct[idx].desc_text, 
				pa_subproduct[idx].type_code 
				FROM subproduct 
				WHERE rowid = pr_rowid 
				IF status = notfound THEN 
					FOR idx = arr_curr() TO arr_count() 
						LET pa_subproduct[idx].* = pa_subproduct[idx+1].* 
						IF scrn <= 14 THEN 
							DISPLAY pa_subproduct[idx].* TO sr_subproduct[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					INITIALIZE pa_subproduct[idx].* TO NULL 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		ON KEY (F2) 
			IF pa_subproduct[idx].part_code IS NOT NULL THEN 
				IF pa_subproduct[idx].scroll_flag IS NULL THEN 
					IF delete_subscript(pa_subproduct[idx].part_code) THEN 
						LET pa_subproduct[idx].scroll_flag = "*" 
						LET del_cnt = del_cnt + 1 
					END IF 
				ELSE 
				LET pa_subproduct[idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
		END IF 
		NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_subproduct[idx].* TO sr_subproduct[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
	IF del_cnt > 0 THEN 
		IF kandoomsg("K",8011,del_cnt) = "Y" THEN 
			#8011 Confirm TO Delete ",del_cnt," subproduct(s)? (Y/N)"
			LET msgresp = kandoomsg("K",1005,"") 
			FOR idx = 1 TO arr_count() 
				IF pa_subproduct[idx].scroll_flag = "*" THEN 
					IF delete_subscript(pa_subproduct[idx].part_code) THEN 
						DELETE FROM subproduct 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pa_subproduct[idx].part_code 
					END IF 
				END IF 
			END FOR 
		END IF 
	END IF 
END IF 
END FUNCTION 


FUNCTION edit_subscript(pr_part_code) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_part_code LIKE subproduct.part_code, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_product RECORD LIKE product.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_substype RECORD LIKE substype.* 

	OPEN WINDOW k150 at 4,12 WITH FORM "K150" 
	attribute(border) 
	SELECT * INTO pr_subproduct.* 
	FROM subproduct 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	IF sqlca.sqlcode = notfound THEN 
		LET pr_subproduct.part_code = pr_part_code 
	ELSE 
	SELECT * INTO pr_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_subproduct.ware_code 
	SELECT * INTO pr_substype.* 
	FROM substype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_subproduct.type_code 
	DISPLAY pr_warehouse.desc_text, 
	pr_substype.desc_text 
	TO warehouse.desc_text, 
	substype.desc_text 

END IF 
LET msgresp = kandoomsg("K",1011,"") 
#K1011 " Enter Dubscription Information
INPUT BY NAME pr_subproduct.part_code, 
pr_subproduct.desc_text, 
pr_subproduct.ware_code, 
pr_subproduct.type_code, 
pr_subproduct.linetype_ind, 
pr_subproduct.comm1_text, 
pr_subproduct.comm2_text WITHOUT DEFAULTS 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 

	ON KEY (control-b) 
		CASE 
			WHEN infield(part_code) 
				LET pr_subproduct.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
				NEXT FIELD part_code 
			WHEN infield(type_code) 
				LET pr_subproduct.type_code = show_substype(glob_rec_kandoouser.cmpy_code," 1=1") 
				NEXT FIELD type_code 
			WHEN infield(ware_code) 
				LET pr_subproduct.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
				NEXT FIELD ware_code 
		END CASE 
	BEFORE FIELD part_code 
		IF pr_part_code IS NOT NULL THEN 
			NEXT FIELD NEXT 
		END IF 

	AFTER FIELD part_code 
		IF pr_subproduct.part_code IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 value must be entered
			NEXT FIELD part_code 
		END IF 
		SELECT unique 1 FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_subproduct.part_code 
		AND serial_flag = 'Y' 
		IF status <> notfound THEN 
			LET msgresp = kandoomsg("I",9285,"") 
			#9285 Serial Items can NOT be used.
			NEXT FIELD part_code 
		END IF 
		SELECT 1 FROM subproduct 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_subproduct.part_code 
		IF status = 0 THEN 
			LET msgresp = kandoomsg("U",9104,"") 
			#9104 RECORD already exists
			NEXT FIELD part_code 
		ELSE 
		IF NOT valid_part(glob_rec_kandoouser.cmpy_code,pr_subproduct.part_code,"",TRUE,2,0,"","","") 
		THEN 
			NEXT FIELD part_code 
		ELSE 
		SELECT * INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_subproduct.part_code 
	END IF 
END IF 

	BEFORE FIELD desc_text 
		IF pr_subproduct.desc_text IS NULL THEN 
			LET pr_subproduct.desc_text = pr_product.desc_text 
		END IF 
	AFTER FIELD desc_text 
		IF pr_subproduct.desc_text IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 Value must be entered
			NEXT FIELD pr_subproduct.desc_text 
		END IF 
	AFTER FIELD ware_code 
		IF pr_subproduct.ware_code IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 Value must be entered
			NEXT FIELD ware_code 
		ELSE 
		SELECT * INTO pr_warehouse.* 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_subproduct.ware_code 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("U",9105,"") 
			#9105 NOT found - try window
			NEXT FIELD ware_code 
		ELSE 
		DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 

	END IF 
END IF 
	AFTER FIELD type_code 
		IF pr_subproduct.type_code IS NOT NULL THEN 
			SELECT * INTO pr_substype.* 
			FROM substype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_subproduct.type_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 NOT found - try window
				NEXT FIELD type_code 
			ELSE 
			DISPLAY pr_substype.desc_text TO substype.desc_text 

		END IF 
	ELSE 
	LET msgresp = kandoomsg("U",9102,"") 
	#9102 Value must be entered
	NEXT FIELD type_code 
END IF 
	AFTER INPUT 
		IF not(int_flag OR quit_flag) THEN 
			IF pr_subproduct.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 value must be entered
				NEXT FIELD desc_text 
			END IF 
			IF pr_subproduct.ware_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 value must be entered
				NEXT FIELD ware_code 
			END IF 
			IF pr_subproduct.type_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 value must be entered
				NEXT FIELD type_code 
			END IF 
			IF pr_subproduct.linetype_ind IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 value must be entered
				NEXT FIELD linetype_ind 
			END IF 
			IF pr_subproduct.linetype_ind = "1" THEN 
				IF subproduct(pr_subproduct.*,1) THEN 
					EXIT INPUT 
				ELSE 
				NEXT FIELD desc_text 
			END IF 
		ELSE 
		EXIT INPUT 
	END IF 
END IF 
	ON KEY (control-w) 
		CALL kandoohelp("") 
END INPUT 
CLOSE WINDOW k150 
IF int_flag OR quit_flag THEN 
	LET int_flag = false 
	LET quit_flag = false 
	RETURN false 
ELSE 
IF pr_part_code IS NULL THEN 
	LET pr_subproduct.cmpy_code = glob_rec_kandoouser.cmpy_code 
	INSERT INTO subproduct VALUES (pr_subproduct.*) 
	RETURN sqlca.sqlerrd[6] 
ELSE 
UPDATE subproduct 
SET subproduct.* = pr_subproduct.* 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND part_code = pr_part_code 
RETURN sqlca.sqlerrd[3] 
END IF 
END IF 
END FUNCTION 


FUNCTION delete_subscript(pr_part_code) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_part_code LIKE subproduct.part_code 

	SELECT unique 1 FROM subcustomer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	IF sqlca.sqlcode = 0 THEN 
		LET msgresp = kandoomsg("U",9108,"Subscription") 
		#9108 " Subscription RECORD IS in use - Deletion IS NOT permitted"
		RETURN false 
	ELSE 
	RETURN true 
END IF 
END FUNCTION 

FUNCTION subproduct(pr_subproduct,pr_mode) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_part_code LIKE subproduct.part_code, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_mode SMALLINT, 
	query_text CHAR(800), 
	where_text CHAR(500), 
	pr_subissues RECORD 
		cmpy_code LIKE company.cmpy_code, 
		part_code LIKE product.part_code, 
		desc_text LIKE subproduct.desc_text, 
		type_code LIKE subissues.type_code, 
		start_date LIKE subissues.start_date, 
		last_issue_num LIKE subissues.last_issue_num, 
		status_ind LIKE subissues.status_ind 
	END RECORD, 
	pr_scroll_flag CHAR(1), 
	pa_subissues array[100] OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE subissues.part_code, 
		desc_text LIKE subissues.desc_text, 
		type_code LIKE subissues.type_code, 
		start_date LIKE subissues.start_date, 
		last_issue_num LIKE subissues.last_issue_num 
	END RECORD, 
	pr_end_date DATE, 
	pr_rowid INTEGER, 
	sv_arr_cnt,sv_idx,idx,scrn,del_cnt SMALLINT 

	OPEN WINDOW k151 at 3,9 WITH FORM "K151" 
	attribute(border) 
	LET pr_part_code = pr_subproduct.part_code 
	SELECT unique 1 FROM subissues 
	WHERE part_code = pr_subproduct.part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		CALL get_dates(today,pr_subproduct.type_code) 
		RETURNING pr_subissues.start_date,pr_end_date 
		LET pr_rowid = edit_year(pr_subproduct.part_code, 
		pr_subproduct.type_code, 
		pr_subproduct.desc_text, 
		pr_subissues.start_date,1) 
		IF pr_rowid = 0 THEN 
			CLOSE WINDOW k151 
			RETURN false 
		ELSE 
		CLOSE WINDOW k151 
		RETURN true 
	END IF 
END IF 
IF pr_mode = 1 THEN 
	LET where_text = "subissues.part_code = '",pr_part_code,"' " 
ELSE 
#LET msgresp = kandoomsg("E",1001,"")
#1001 Enter selection criteria - ESC TO continue
MESSAGE "Enter selection criteria - ESC TO continue" attribute (yellow) 
CLEAR FORM 
CONSTRUCT BY NAME where_text ON subissues.part_code, 
subproduct.desc_text, 
subissues.type_code, 
subissues.start_date, 
subissues.last_issue_num 
	BEFORE CONSTRUCT 
		DISPLAY pr_part_code TO subissues.part_code 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 
	ON KEY (control-w) 
		CALL kandoohelp("") 

END CONSTRUCT 
IF int_flag OR quit_flag THEN 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW k151 
	RETURN false 
END IF 
END IF 
#LET msgresp = kandoomsg("E",1002,"")
#1002 Searching database - please wait
MESSAGE "Searching database - please wait" attribute (yellow) 
LET query_text = "SELECT subissues.cmpy_code, subissues.part_code, ", 
" subproduct.desc_text, subissues.type_code, ", 
" subissues.start_date, ", 
" subissues.last_issue_num, subissues.status_ind ", 
" FROM subproduct, subissues ", 
" WHERE subproduct.cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
" AND subissues.cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
" AND subissues.part_code = subproduct.part_code ", 
" AND subissues.type_code = subproduct.type_code ", 
" AND ",where_text clipped," ", 
" group by subissues.cmpy_code, subissues.part_code, ", 
" subproduct.desc_text, subissues.type_code,", 
" subissues.start_date,", 
" subissues.last_issue_num, subissues.status_ind ", 
" ORDER BY subissues.cmpy_code,", 
"subissues.part_code,", 
"subissues.type_code,", 
"subissues.start_date " 
PREPARE s_subissues FROM query_text 
DECLARE c_subissues CURSOR FOR s_subissues 

LET idx = 0 
FOREACH c_subissues INTO pr_subissues.* 
LET idx = idx + 1 
IF pr_subissues.status_ind = "9" THEN 
	LET pa_subissues[idx].scroll_flag = "*" 
ELSE 
LET pa_subissues[idx].scroll_flag = NULL 
END IF 
LET pa_subissues[idx].part_code = pr_subissues.part_code 
LET pa_subissues[idx].desc_text = pr_subissues.desc_text 
LET pa_subissues[idx].type_code = pr_subissues.type_code 
LET pa_subissues[idx].start_date = pr_subissues.start_date 
LET pa_subissues[idx].last_issue_num = pr_subissues.last_issue_num 
IF idx = 100 THEN 
#LET msgresp = kandoomsg("E",9179,"100")
#9179 " First ??? payment subissuess selected only"
MESSAGE " First 100 subscriptions selected " 
EXIT FOREACH 
END IF 
END FOREACH 
IF idx = 0 THEN 
LET msgresp=kandoomsg("U",9101,"") 
#9101 "No subproduct satisfies the selection criteria"
LET idx = 1 
LET pa_subissues[idx].start_date = NULL 
LET pa_subissues[idx].last_issue_num = NULL 
END IF 
OPTIONS INSERT KEY f1, 
DELETE KEY f36 
CALL set_count(idx) 
LET msgresp = kandoomsg("U",1003,"") 
#"F1 TO add, RETURN on line TO change, F2 TO delete"
INPUT ARRAY pa_subissues WITHOUT DEFAULTS FROM sr_subissues.* 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 

	BEFORE ROW 
		LET idx = arr_curr() 
		LET scrn = scr_line() 

	BEFORE FIELD scroll_flag 
		LET idx = arr_curr() 
		LET scrn = scr_line() 
		LET pr_scroll_flag = pa_subissues[idx].scroll_flag 
		DISPLAY pa_subissues[idx].* 
		TO sr_subissues[scrn].* 

	AFTER FIELD scroll_flag 
		LET pa_subissues[idx].scroll_flag = pr_scroll_flag 
		IF fgl_lastkey() = fgl_keyval("down") THEN 
			IF pa_subissues[idx+1].part_code IS NULL 
			OR arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				# There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
		END IF 
	BEFORE FIELD part_code 
		IF pa_subissues[idx].part_code IS NULL THEN 
			NEXT FIELD scroll_flag 
		END IF 
		LET sv_arr_cnt = arr_count() 
		LET sv_idx = arr_curr() 
		IF edit_year(pa_subissues[idx].part_code, 
		pa_subissues[idx].type_code,"", 
		pa_subissues[idx].start_date,0) THEN 
			DECLARE b_curs CURSOR FOR 
			SELECT subissues.part_code, 
			subproduct.desc_text, 
			subissues.type_code, 
			subissues.start_date, 
			subissues.last_issue_num 
			INTO pa_subissues[idx].part_code, 
			pa_subissues[idx].desc_text, 
			pa_subissues[idx].type_code, 
			pa_subissues[idx].start_date, 
			pa_subissues[idx].last_issue_num 
			FROM subissues, subproduct 
			WHERE subissues.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND subproduct.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND subproduct.part_code = pa_subissues[idx].part_code 
			AND subproduct.type_code = pa_subissues[idx].type_code 
			AND subissues.part_code = pa_subissues[idx].part_code 
			AND subissues.start_date = pa_subissues[idx].start_date 
			GROUP BY subissues.part_code, 
			subproduct.desc_text, 
			subissues.type_code, 
			subissues.start_date, 
			subissues.last_issue_num 
			OPEN b_curs 
			FETCH b_curs 
		END IF 
		CALL set_count(sv_arr_cnt) 
		NEXT FIELD scroll_flag 
	BEFORE INSERT 
		IF arr_curr() < arr_count() THEN 
			LET sv_arr_cnt = arr_count() 
			LET sv_idx = arr_curr() 
			LET pr_rowid = edit_year("","","","",0) 
			CALL set_count(sv_arr_cnt) 
			SELECT subissues.part_code, 
			subproduct.desc_text, 
			subissues.type_code, 
			subissues.start_date, 
			subissues.last_issue_num 
			INTO pa_subissues[idx].part_code, 
			pa_subissues[idx].desc_text, 
			pa_subissues[idx].type_code, 
			pa_subissues[idx].start_date 
			FROM subissues, subproduct 
			WHERE subissues.rowid = pr_rowid 
			AND subissues.cmpy_code = subproduct.cmpy_code 
			AND subissues.part_code = subproduct.part_code 
			AND subissues.type_code = subproduct.type_code 
			IF status = notfound THEN 
				FOR idx = sv_idx TO sv_arr_cnt 
					LET pa_subissues[idx].* = pa_subissues[idx+1].* 
					IF scrn <= 9 THEN 
						IF pa_subissues[idx].part_code IS NULL THEN 
							LET pa_subissues[idx].start_date = NULL 
							LET pa_subissues[idx].last_issue_num = NULL 
						END IF 
						DISPLAY pa_subissues[idx].* TO sr_subissues[scrn].* 

						LET scrn = scrn + 1 
					END IF 
				END FOR 
				INITIALIZE pa_subissues[idx].* TO NULL 
				LET pa_subissues[idx].start_date = NULL 
				LET pa_subissues[idx].last_issue_num = NULL 
				IF scrn <= 9 THEN 
					DISPLAY pa_subissues[idx].* 
					TO sr_subissues[scrn].* 

					LET scrn = scrn + 1 
				END IF 
			END IF 
		END IF 
		LET scrn = scr_line() 
		NEXT FIELD scroll_flag 

	ON KEY (F2) 
		IF pa_subissues[idx].part_code IS NOT NULL THEN 
			IF pa_subissues[idx].scroll_flag IS NULL THEN 
				IF delete_year(pa_subissues[idx].part_code, 
				pa_subissues[idx].start_date, 
				pa_subissues[idx].type_code) THEN 
					LET pa_subissues[idx].scroll_flag = "*" 
					LET del_cnt = del_cnt + 1 
				END IF 
			ELSE 
			LET pa_subissues[idx].scroll_flag = NULL 
			LET del_cnt = del_cnt - 1 
		END IF 
	END IF 
	NEXT FIELD scroll_flag 
	AFTER ROW 
		DISPLAY pa_subissues[idx].* 
		TO sr_subissues[scrn].* 

	ON KEY (control-w) 
		CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW k151 
			RETURN false 
		ELSE 
		IF del_cnt > 0 THEN 
			LET msgresp = kandoomsg("U",8020,del_cnt) 
			#8020 Confirm TO Delete ",del_cnt," subissues(s)? (Y/N)"
			IF msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_subissues[idx].scroll_flag = "*" THEN 
						UPDATE subissues 
						SET status_ind = 9 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pa_subissues[idx].part_code 
						AND type_code = pa_subissues[idx].type_code 
						AND start_date = pa_subissues[idx].start_date 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
	CLOSE WINDOW k151 
	RETURN true 
END FUNCTION 


FUNCTION select_date(pr_part_code,pr_type, pr_start_date) 
	DEFINE 
	query_text CHAR(300), 
	pr_part_code LIKE subproduct.part_code, 
	pr_type LIKE subproduct.type_code, 
	pr_start_date LIKE subissues.start_date 

	LET query_text = "SELECT * ", 
	" FROM subissues ", 
	" WHERE subissues.cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND subissues.part_code = '",pr_part_code,"' ", 
	" AND subissues.type_code = '",pr_type,"' ", 
	" AND subissues.start_date = '",pr_start_date,"' ", 
	" ORDER BY cmpy_code,", 
	"part_code,", 
	"type_code,", 
	"start_date,", 
	"plan_iss_date" 
	PREPARE s_date FROM query_text 
	DECLARE c_date CURSOR FOR s_date 
	RETURN true 
END FUNCTION 



FUNCTION edit_year(pr_part_code,pr_type_code,pr_desc,pr_start_date,pr_mode) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_subissues RECORD LIKE subissues.*, 
	pr_part_code LIKE subissues.part_code, 
	pr_type_code LIKE subissues.type_code, 
	pr_start_date LIKE subissues.start_date, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_desc LIKE subproduct.desc_text, 
	pr_temp_text CHAR(60), 
	idx SMALLINT, 
	pr_mode SMALLINT, 
	pr_row_id INTEGER 

	OPEN WINDOW k145 at 4,10 WITH FORM "K145" 
	attribute(border,MESSAGE line first,white) 
	FOR idx = 1 TO 100 
		INITIALIZE pa_dates[idx].* TO NULL 
	END FOR 
	IF pr_mode = 1 THEN 
		DISPLAY pr_desc 
		TO sub_text 

	END IF 
	DECLARE a_curs CURSOR FOR 
	SELECT * INTO pr_subissues.* 
	FROM subissues 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	AND type_code = pr_type_code 
	AND start_date = pr_start_date 
	OPEN a_curs 
	FETCH a_curs 
	IF sqlca.sqlcode = notfound THEN 
		LET pr_subissues.part_code = pr_part_code 
		LET pr_subissues.type_code = pr_type_code 
		CALL get_dates(pr_start_date,pr_type_code) 
		RETURNING pr_subissues.start_date,pr_subissues.end_date 
		#LET msgresp = kandoomsg("E",1047,"")
		#1047 " Enter Interval Type Details - ESC TO Continue"
		MESSAGE " Enter Subscription Date Details - ESC TO continue" attribute(yellow) 
		INPUT BY NAME pr_subissues.part_code, 
		pr_subissues.type_code, 
		pr_subissues.start_date, 
		pr_subissues.end_date 
		WITHOUT DEFAULTS 

			ON ACTION "WEB-HELP" -- albo kd-374 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(part_code) 
						LET pr_temp_text = "1=1" 
						LET pr_temp_text = show_subproduct(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
						IF pr_temp_text IS NOT NULL THEN 
							LET pr_subissues.part_code = pr_temp_text 
							NEXT FIELD part_code 
						END IF 
					WHEN infield(type_code) 
						LET pr_temp_text = "1=1" 
						LET pr_temp_text = show_substype(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
						IF pr_temp_text IS NOT NULL THEN 
							LET pr_subissues.type_code = pr_temp_text 
							NEXT FIELD type_code 
						END IF 
				END CASE 
			BEFORE FIELD part_code 
				IF pr_part_code IS NOT NULL THEN 
					NEXT FIELD NEXT 
				END IF 
			AFTER FIELD part_code 
				SELECT * INTO pr_subproduct.* 
				FROM subproduct 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_subissues.part_code 
				IF status = notfound THEN 
					IF pr_part_code IS NOT NULL THEN 
						LET msgresp = kandoomsg("K",9103,"") 
						#9103 "Subscription has been deleted"
						RETURN false 
					ELSE 
					LET msgresp = kandoomsg("K",9113,"") 
					#9113 "Subscription does NOT exist
					NEXT FIELD part_code 
				END IF 
			END IF 
			DISPLAY pr_subproduct.desc_text 
			TO sub_text 

			BEFORE FIELD type_code 
				IF pr_mode = 1 
				AND pr_subissues.type_code IS NOT NULL THEN 
					NEXT FIELD NEXT 
				END IF 
			AFTER FIELD type_code 
				IF pr_subissues.type_code IS NOT NULL THEN 
					SELECT * INTO pr_subproduct.* 
					FROM subproduct 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = pr_subissues.type_code 
					AND part_code = pr_subissues.part_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9105,"") 
						#9105 NOT found - try window
						NEXT FIELD type_code 
					END IF 
				ELSE 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD type_code 
			END IF 
			AFTER FIELD start_date 
				IF pr_subissues.start_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD start_date 
				END IF 
				IF pr_subissues.start_date IS NOT NULL THEN 
					SELECT unique 1 FROM subissues 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_subissues.part_code 
					AND type_code = pr_subissues.type_code 
					AND start_date = pr_subissues.start_date 
					IF status = 0 THEN 
						LET msgresp = kandoomsg("U",9104,"") 
						#9104 " Subscription Year must be unique "
						NEXT FIELD start_date 
					END IF 
				END IF 
				CALL get_dates(pr_subissues.start_date,pr_subissues.type_code) 
				RETURNING pr_subissues.start_date,pr_subissues.end_date 
				DISPLAY BY NAME pr_subissues.end_date 
			AFTER FIELD end_date 
				IF pr_subissues.end_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD end_date 
				END IF 
				IF pr_subissues.end_date < pr_subissues.start_date THEN 
					LET msgresp = kandoomsg("K",9105,"") 
					#9105 Value must be entered
					NEXT FIELD start_date 
				END IF 
				IF pr_subissues.start_date IS NOT NULL THEN 
					SELECT unique 1 FROM subissues 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_subissues.part_code 
					AND type_code = pr_subissues.type_code 
					AND start_date = pr_subissues.start_date 
					IF status = 0 THEN 
						LET msgresp = kandoomsg("U",9104,"") 
						#9104 " Subscription Year must be unique "
						NEXT FIELD start_date 
					END IF 
				END IF 
			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					IF pr_subissues.part_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 " Subscription code must be entered "
						NEXT FIELD part_code 
					END IF 
					IF pr_subissues.type_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD type_code 
					END IF 
					IF pr_subissues.type_code IS NOT NULL AND pr_mode = 0 THEN 
						SELECT * INTO pr_subproduct.* 
						FROM subproduct 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND type_code = pr_subissues.type_code 
						AND part_code = pr_subissues.part_code 
						IF status = notfound THEN 
							LET msgresp = kandoomsg("U",9105,"") 
							#9105 NOT found - try window
							NEXT FIELD type_code 
						END IF 
					END IF 
					IF pr_subissues.start_date IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD start_date 
					END IF 
					IF pr_subissues.end_date IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD end_date 
					END IF 
					IF pr_subissues.end_date < pr_subissues.start_date THEN 
						LET msgresp = kandoomsg("K",9105,"") 
						#9105 Value must be entered
						NEXT FIELD start_date 
					END IF 
					IF pr_subissues.start_date IS NOT NULL 
					AND pr_subissues.end_date IS NOT NULL THEN 
						SELECT unique 1 FROM subissues 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pr_subissues.part_code 
						AND type_code = pr_subissues.type_code 
						AND start_date = pr_subissues.start_date 
						IF status = 0 THEN 
							LET msgresp = kandoomsg("U",9104,"") 
							#9104 " Subscription Year must be unique "
							NEXT FIELD start_date 
						END IF 
					END IF 
					IF select_date(pr_part_code, pr_type_code,pr_start_date) THEN 
						LET idx = 0 
						FOREACH c_date INTO pr_subissues.* 
							LET idx = idx + 1 
							LET pa_dates[idx].plan_iss_date = pr_subissues.plan_iss_date 
							LET pa_dates[idx].desc_text = pr_subissues.desc_text 
							LET pa_dates[idx].issue_num = pr_subissues.issue_num 
							LET pa_dates[idx].act_iss_date = pr_subissues.act_iss_date 
							IF idx = 100 THEN 
								EXIT FOREACH 
							END IF 
						END FOREACH 
						IF edit_dates(pr_subissues.part_code, pr_subissues.type_code, 
						pr_subissues.start_date,pr_subissues.end_date) 
						THEN 
						ELSE 
						NEXT FIELD part_code 
					END IF 
				END IF 
			END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	ELSE 
	SELECT * 
	INTO pr_subproduct.* 
	FROM subproduct 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	AND type_code = pr_type_code 
	IF status = notfound THEN 
	ELSE 
	CALL get_dates(pr_start_date,pr_subproduct.type_code) 
	RETURNING pr_subissues.start_date,pr_subissues.end_date 
	DISPLAY pr_subproduct.part_code, 
	pr_subproduct.desc_text, 
	pr_subproduct.type_code, 
	pr_subissues.start_date, 
	pr_subissues.end_date 
	TO 
	part_code, 
	sub_text, 
	type_code, 
	start_date, 
	end_date 

END IF 
{DISPLAY dates FOR the year }
IF select_date(pr_part_code,pr_type_code,pr_start_date) THEN 
	LET idx = 0 
	FOREACH c_date INTO pr_subissues.* 
		LET idx = idx + 1 
		LET pa_dates[idx].plan_iss_date = pr_subissues.plan_iss_date 
		LET pa_dates[idx].desc_text = pr_subissues.desc_text 
		LET pa_dates[idx].issue_num = pr_subissues.issue_num 
		LET pa_dates[idx].act_iss_date = pr_subissues.act_iss_date 
		IF idx = 100 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF edit_dates(pr_subissues.part_code, pr_subissues.type_code, 
	pr_subissues.start_date,pr_subissues.end_date) THEN 
	ELSE 
	CLOSE WINDOW k145 
	RETURN false 
END IF 
END IF 
END IF 
CLOSE WINDOW k145 
IF int_flag OR quit_flag THEN 
LET int_flag = false 
LET quit_flag = false 
RETURN false 
ELSE 
IF pr_part_code IS NULL THEN 
DECLARE x_curs CURSOR FOR 
SELECT rowid 
FROM subissues 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND part_code = pr_subissues.part_code 
AND type_code = pr_subissues.type_code 
AND start_date = pr_subissues.start_date 
OPEN x_curs 
FETCH x_curs INTO pr_row_id 
RETURN pr_row_id 
ELSE 
RETURN sqlca.sqlerrd[3] 
END IF 
END IF 
END FUNCTION 


FUNCTION delete_year(pr_part_code,pr_start_date,pr_type_code) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_part_code LIKE subissues.part_code, 
	pr_start_date LIKE subissues.start_date, 
	pr_type_code LIKE subissues.type_code 

	SELECT unique 1 FROM subcustomer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	AND comm_date = pr_start_date 
	AND type_code = pr_type_code 
	IF sqlca.sqlcode = 0 THEN 
		LET msgresp = kandoomsg("U",9108,"Subscription") 
		#9108 " Subscription has already benn scheduled OR invoiced
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 

FUNCTION edit_dates(pr_part_code, pr_type_code, pr_start_date,pr_end_date) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_subissues RECORD LIKE subissues.*, 
	pr_type_code LIKE subissues.type_code, 
	pr_start_date,pr_end_date DATE, 
	pr_dates RECORD 
		scroll_flag CHAR (1), 
		plan_iss_date LIKE subissues.plan_iss_date, 
		desc_text LIKE subissues.desc_text, 
		issue_num LIKE subissues.issue_num, 
		act_iss_date LIKE subissues.act_iss_date 
	END RECORD, 
	pr_part_code LIKE subissues.part_code, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_rowid INTEGER, 
	pr_last_num,array_size,i,idx,scrn,del_cnt SMALLINT, 
	try_again CHAR(1), 
	err_message CHAR(60) 

	FOR i = 1 TO 100 
		INITIALIZE pa_dates[i].* TO NULL 
	END FOR 
	LET idx = 0 
	LET pr_last_num = 0 
	FOREACH c_date INTO pr_subissues.* 
		LET idx = idx + 1 
		LET pa_dates[idx].plan_iss_date = pr_subissues.plan_iss_date 
		LET pa_dates[idx].desc_text = pr_subissues.desc_text 
		LET pa_dates[idx].issue_num = pr_subissues.issue_num 
		LET pa_dates[idx].act_iss_date = pr_subissues.act_iss_date 
		IF pr_subissues.last_issue_num > pr_last_num THEN 
			LET pr_last_num = pr_subissues.last_issue_num 
		END IF 
		IF idx = 100 THEN 
			#LET msgresp = kandoomsg("E",9179,"100")
			#9179 " First ??? payment subissuess selected only"
			MESSAGE " First 100 dates selected " 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(idx) 
	#LET msgresp = kandoomsg("E",1003,"")
	# "F1 TO add, RETURN on line TO change, F2 TO delete"
	MESSAGE "F1 TO add, RETURN on line TO edit, F2 TO delete" attribute(yellow) 
	INPUT ARRAY pa_dates WITHOUT DEFAULTS FROM sr_dates.* 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_dates[idx].* 
			TO sr_dates[scrn].* 

			LET pr_dates.* = pa_dates[idx].* 
		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_dates[idx+1].plan_iss_date IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					# There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (F2) 
			CASE 
				WHEN infield(scroll_flag) 
					#SELECT unique 1 FROM subschedule

					IF pa_dates[idx].act_iss_date IS NULL THEN 
						FOR i = idx TO 99 
							LET pa_dates[i].* = pa_dates[i+1].* 
							IF pa_dates[i].plan_iss_date IS NULL THEN 
								LET pa_dates[i].issue_num = NULL 
								LET pa_dates[i].act_iss_date = NULL 
							END IF 
							IF scrn <= 8 THEN 
								DISPLAY pa_dates[i].* TO sr_dates[scrn].* 

								LET scrn = scrn + 1 
							END IF 
							IF pa_dates[i].plan_iss_date IS NULL THEN 
								EXIT FOR 
							END IF 
						END FOR 
					ELSE 
					LET msgresp = kandoomsg("K",9108,"") 
					# Can NOT delete
				END IF 
			END CASE 
		BEFORE INSERT 
			LET pa_dates[idx].act_iss_date = NULL 
			NEXT FIELD plan_iss_date 
		AFTER FIELD plan_iss_date 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("accept") 
					IF pr_dates.plan_iss_date IS NOT NULL 
					OR pa_dates[idx].plan_iss_date IS NOT NULL 
					OR pa_dates[idx].plan_iss_date <> pr_dates.plan_iss_date THEN 
						IF pa_dates[idx].plan_iss_date < pr_start_date OR 
						pa_dates[idx].plan_iss_date > pr_end_date THEN 
							LET msgresp = kandoomsg("U",9110,"") 
							#9110 " Date out of range
							NEXT FIELD plan_iss_date 
						END IF 
						FOR i = 1 TO arr_count() 
							IF i = idx THEN 
							ELSE 
							IF pa_dates[idx].plan_iss_date = 
							pa_dates[i].plan_iss_date THEN 
								LET msgresp = kandoomsg("K",9100,"") 
								#9100 " Duplicated date "
								LET pa_dates[idx].plan_iss_date = 
								pr_dates.plan_iss_date 
								DISPLAY pa_dates[idx].plan_iss_date TO 
								sr_dates[scrn].plan_iss_date 

								NEXT FIELD plan_iss_date 
							END IF 
						END IF 
					END FOR 
				END IF 
				NEXT FIELD desc_text 
				WHEN fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left") 
					NEXT FIELD scroll_flag 
				OTHERWISE 
					NEXT FIELD scroll_flag 
			END CASE 
		AFTER FIELD desc_text 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_dates[idx+1].plan_iss_date IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					# There are no more rows in the direction you are going.
					NEXT FIELD desc_text 
				END IF 
			END IF 
		AFTER FIELD issue_num 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_dates[idx+1].plan_iss_date IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					# There are no more rows in the direction you are going.
					NEXT FIELD issue_num 
				END IF 
			END IF 
			IF pa_dates[idx].issue_num < 0 THEN 
				LET msgresp = kandoomsg("U",9101,"") 
				#9101 " Issue number must be greater than oe equal TO zero"
				NEXT FIELD issue_num 
			END IF 
			IF pa_dates[idx].plan_iss_date IS NOT NULL 
			AND pa_dates[idx].issue_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 " An issue number IS required "
				NEXT FIELD issue_num 
			END IF 
			IF pr_dates.issue_num IS NOT NULL 
			OR pa_dates[idx].issue_num IS NOT NULL 
			OR pa_dates[idx].issue_num <> pr_dates.issue_num THEN 
				FOR i = 1 TO arr_count() 
					IF i = idx THEN 
					ELSE 
					IF pa_dates[idx].issue_num = pa_dates[i].issue_num THEN 
						LET msgresp = kandoomsg("K",9102,"") 
						#9102 " Duplicated issue number "
						LET pa_dates[idx].issue_num = pr_dates.issue_num 
						DISPLAY pa_dates[idx].issue_num TO 
						sr_dates[scrn].issue_num 

						NEXT FIELD issue_num 
					END IF 
					IF pa_dates[idx].issue_num > 
					pa_dates[i].issue_num AND 
					pa_dates[idx].plan_iss_date < 
					pa_dates[i].plan_iss_date THEN 
						LET msgresp = kandoomsg("K",9117,"") 
						#9102 " Later issue exists FOR earlier date
						NEXT FIELD issue_num 
					END IF 
					IF pa_dates[idx].issue_num < 
					pa_dates[i].issue_num AND 
					pa_dates[idx].plan_iss_date > 
					pa_dates[i].plan_iss_date THEN 
						LET msgresp = kandoomsg("K",9116,"") 
						#9102 " Later issue exists FOR earlier date
						NEXT FIELD issue_num 
					END IF 
				END IF 
			END FOR 
		END IF 
		NEXT FIELD scroll_flag 
		AFTER INSERT 
			IF pa_dates[idx].plan_iss_date IS NULL THEN 
				FOR idx = arr_curr() TO arr_count() 
					LET pa_dates[idx].* = pa_dates[idx+1].* 
					IF scrn <= 8 THEN 
						DISPLAY pa_dates[idx].* 
						TO sr_dates[scrn].* 

						LET scrn = scrn + 1 
					END IF 
				END FOR 
				INITIALIZE pa_dates[idx].* TO NULL 
			END IF 
		AFTER INPUT 
			LET array_size = arr_count() 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	BEGIN WORK 
		DELETE FROM subissues 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_part_code 
		AND type_code = pr_type_code 
		AND start_date = pr_start_date 
		INITIALIZE pr_subissues.* TO NULL 
		LET pr_subissues.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_subissues.part_code = pr_part_code 
		LET pr_subissues.type_code= pr_type_code 
		LET pr_subissues.start_date = pr_start_date 
		LET pr_subissues.last_issue_num = pr_last_num 
		CALL get_dates(pr_start_date,pr_subissues.type_code) 
		RETURNING pr_subissues.start_date,pr_subissues.end_date 
		LET pr_subissues.status_ind = 0 
		FOR i = 1 TO array_size 
			IF pa_dates[i].plan_iss_date IS NOT NULL THEN 
				LET pr_subissues.plan_iss_date = pa_dates[i].plan_iss_date 
				LET pr_subissues.act_iss_date = pa_dates[i].act_iss_date 
				LET pr_subissues.desc_text = pa_dates[i].desc_text 
				LET pr_subissues.issue_num = pa_dates[i].issue_num 
				LET err_message = "KZ2 - Insert Subscription dates" 
				INSERT INTO subissues VALUES (pr_subissues.*) 
			END IF 
		END FOR 
	COMMIT WORK 
	RETURN true 
END IF 
END FUNCTION 

FUNCTION get_dates(pr_date,pr_type) 
	DEFINE pr_date DATE, 
	pr_start_year,pr_end_year SMALLINT, 
	pr_substype RECORD LIKE substype.*, 
	pr_type CHAR(3), 
	pr_start_date,pr_end_date DATE 

	SELECT * INTO pr_substype.* 
	FROM substype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_type 

	LET pr_start_year = year(pr_date) 
	IF month(pr_date) < pr_substype.start_mth_num THEN 
		LET pr_start_year = pr_start_year - 1 
	END IF 
	LET pr_end_year = pr_start_year 
	IF pr_substype.start_mth_num > pr_substype.end_mth_num THEN 
		LET pr_end_year = pr_end_year + 1 
	END IF 
	LET pr_start_date = mdy(pr_substype.start_mth_num, 
	pr_substype.start_day_num, 
	pr_start_year) 
	LET pr_end_date = mdy(pr_substype.end_mth_num, 
	pr_substype.end_day_num, 
	pr_end_year) 
	RETURN pr_start_date,pr_end_date 
END FUNCTION 
