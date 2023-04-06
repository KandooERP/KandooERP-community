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

	Source code beautified by beautify.pl on 2020-01-02 19:48:28	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module JZ6  This Program allows the user TO enter AND maintain
# Unit Codes          FOR Job Management

GLOBALS 

	DEFINE 
	pr_actiunit RECORD LIKE actiunit.*, 
	pa_actiunit array[40] OF RECORD 
		scroll_flag CHAR(1), 
		unit_code LIKE actiunit.unit_code, 
		desc_text LIKE actiunit.desc_text 
	END RECORD, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	idx, id_flag, scrn, cnt, err_flag SMALLINT 

END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("JZ6") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	OPEN WINDOW j112 with FORM "J112" -- alch kd-747 
	CALL winDecoration_j("J112") -- alch kd-747 
	WHILE select_codes() 
		CALL scan_codes() 
		CLEAR FORM 
	END WHILE 
	CLOSE WINDOW j112 
END MAIN 

FUNCTION select_codes() 
	DEFINE 
	query_text CHAR(200), 
	where_text CHAR(100) 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue."
	CONSTRUCT BY NAME where_text ON 
	unit_code, 
	desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JZ6","const-unit_code-1") -- alch kd-506 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET query_text = 
		"SELECT * ", 
		"FROM actiunit ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"unit_code" 
		PREPARE s_actiunit FROM query_text 
		DECLARE c_actiunit CURSOR FOR s_actiunit 
		RETURN true 
	END IF 
END FUNCTION 

FUNCTION scan_codes() 
	DEFINE 
	pr_actiunit RECORD LIKE actiunit.*, 
	pa_actiunit array[100] OF RECORD 
		scroll_flag CHAR(1), 
		unit_code LIKE actiunit.unit_code, 
		desc_text LIKE actiunit.desc_text 
	END RECORD, 
	pr_scroll_flag CHAR(1), 
	idx,scrn,del_cnt SMALLINT 

	LET idx = 0 
	LET del_cnt = 0 
	FOREACH c_actiunit INTO pr_actiunit.* 
		LET idx = idx + 1 
		LET pa_actiunit[idx].scroll_flag = NULL 
		LET pa_actiunit[idx].unit_code = pr_actiunit.unit_code 
		LET pa_actiunit[idx].desc_text = pr_actiunit.desc_text 
		IF idx = 100 THEN 
			LET msgresp=kandoomsg("J",1561,idx) 
			#1561 " First 100 Unit Codes selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET idx = 1 
	END IF 
	LET msgresp=kandoomsg("U",9113,idx) 
	#9113 "idx" records selected.
	CALL set_count(idx) 
	LET msgresp=kandoomsg("U",1003,"100") 
	#1003 F1 TO Add;  F2 TO delete;  ENTER on line TO Edit.
	INPUT ARRAY pa_actiunit WITHOUT DEFAULTS FROM sr_actiunit.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZ6","input_arr-pa_actiunit-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		BEFORE FIELD scroll_flag 
			LET pr_scroll_flag = pa_actiunit[idx].scroll_flag 
			DISPLAY pa_actiunit[idx].* 
			TO sr_actiunit[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_actiunit[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND pa_actiunit[idx+1].unit_code IS NULL THEN 
				LET msgresp=kandoomsg("J",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp=kandoomsg("J",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD unit_code 
			IF pa_actiunit[idx].unit_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 
		AFTER FIELD unit_code 
			IF pa_actiunit[idx].unit_code IS NULL THEN 
				LET msgresp=kandoomsg("J",9495,"") 
				#9495 Unit Code must be entered.
				NEXT FIELD unit_code 
			ELSE 
				SELECT unique 1 FROM actiunit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND unit_code = pa_actiunit[idx].unit_code 
				IF status = 0 THEN 
					LET msgresp=kandoomsg("J",9496,"") 
					#9496 Unit Code already exists;  Please Re Enter.
					LET pa_actiunit[idx].unit_code = NULL 
					NEXT FIELD unit_code 
				END IF 
				NEXT FIELD desc_text 
			END IF 
		BEFORE INSERT 
			INITIALIZE pa_actiunit[idx].* TO NULL 
			IF arr_curr() < arr_count() THEN 
				NEXT FIELD unit_code 
			END IF 
		AFTER ROW 
			LET pr_actiunit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pa_actiunit[idx].unit_code IS NOT NULL THEN 
				UPDATE actiunit 
				SET desc_text = pa_actiunit[idx].desc_text 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND unit_code = pa_actiunit[idx].unit_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO actiunit VALUES (glob_rec_kandoouser.cmpy_code,pa_actiunit[idx].unit_code, 
					pa_actiunit[idx].desc_text) 
				END IF 
			ELSE 
				INITIALIZE pa_actiunit[idx].* TO NULL 
			END IF 
			DISPLAY pa_actiunit[idx].* 
			TO sr_actiunit[scrn].* 

		ON KEY (F2) 
			IF pa_actiunit[idx].unit_code IS NOT NULL THEN 
				IF pa_actiunit[idx].scroll_flag IS NULL THEN 
					IF unit_inuse(pa_actiunit[idx].unit_code) THEN 
						LET msgresp=kandoomsg("J",9497,"") 
						#9497 Unit Code in use; Delete NOT allowed.
						NEXT FIELD scroll_flag 
					ELSE 
						LET pa_actiunit[idx].scroll_flag = "*" 
						LET del_cnt = del_cnt + 1 
						NEXT FIELD scroll_flag 
					END IF 
				ELSE 
					LET pa_actiunit[idx].scroll_flag = NULL 
					LET del_cnt = del_cnt - 1 
					NEXT FIELD scroll_flag 
				END IF 
			ELSE 
				NEXT FIELD unit_code 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF pa_actiunit[idx].unit_code IS NULL THEN 
					FOR idx = arr_curr() TO arr_count() 
						LET pa_actiunit[idx].* = pa_actiunit[idx+1].* 
						IF arr_curr() = arr_count() THEN 
							INITIALIZE pa_actiunit[idx].* TO NULL 
							EXIT FOR 
						END IF 
						IF scrn <= 10 THEN 
							DISPLAY pa_actiunit[idx].* 
							TO sr_actiunit[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					LET idx =arr_curr() 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_cnt > 0 THEN 
			LET msgresp=kandoomsg("J",8014,del_cnt) 
			#8014 Confirmation TO Delete del_cnt Sales Hold Reasons (Y/N)?:
			IF msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_actiunit[idx].scroll_flag IS NOT NULL THEN 
						IF unit_inuse(pa_actiunit[idx].unit_code) THEN 
							LET msgresp=kandoomsg("J",7013,pa_actiunit[idx].unit_code) 
							#7013 Unit code in use delete NOT allowed.
							#     Any key TO continue.
						ELSE 
							DELETE FROM actiunit 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND unit_code = pa_actiunit[idx].unit_code 
						END IF 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


FUNCTION unit_inuse(pr_unit_code) 
	DEFINE 
	pr_unit_code LIKE actiunit.unit_code 

	SELECT unique 1 FROM activity 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND unit_code = pr_unit_code 
	IF status = 0 THEN 
		RETURN true 
	END IF 
	SELECT unique 1 FROM jmresource 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND unit_code = pr_unit_code 
	IF status = 0 THEN 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 
