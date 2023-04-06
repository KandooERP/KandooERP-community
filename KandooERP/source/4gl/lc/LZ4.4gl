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

	Source code beautified by beautify.pl on 2020-01-02 18:38:37	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module LZ4 - Maintain Shipment Cost Type Codes
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 
GLOBALS 

	DEFINE 
	pr_shiptype RECORD LIKE shiptype.*, 
	pr_shipcosttype RECORD LIKE shipcosttype.*, 
	pr_scroll_flag CHAR(1), 
	pt_shipcosttype RECORD 
		scroll_flag CHAR(1), 
		cost_type_code LIKE shipcosttype.cost_type_code, 
		desc_text LIKE shipcosttype.desc_text 
	END RECORD, 
	pa_shipcosttype array[50] OF RECORD 
		scroll_flag CHAR(1), 
		cost_type_code LIKE shipcosttype.cost_type_code, 
		desc_text LIKE shipcosttype.desc_text 
	END RECORD, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	count_coa, idx, id_flag, scrn, cnt, err_flag SMALLINT, 
	ans CHAR(1), 
	del_cnt SMALLINT 
END GLOBALS 



MAIN 

	#Initial UI Init
	CALL setModuleId("LZ4") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	LET pr_shiptype.cmpy_code = glob_rec_kandoouser.cmpy_code 


	OPTIONS DELETE KEY f36 
	OPEN WINDOW wl140 with FORM "L140" 
	CALL windecoration_l("L140") -- albo kd-763 
	WHILE cost_select() 
		CALL doit() 
	END WHILE 
	CLOSE WINDOW wl140 
	OPTIONS DELETE KEY f2 
END MAIN 



FUNCTION cost_select() 
	DEFINE query_text CHAR(150), 
	where_part CHAR(300) 
	CLEAR FORM 
	MESSAGE " Enter Selection Criteria - ESC TO Continue " 
	attribute (yellow) 
	CONSTRUCT BY NAME where_part ON 
	cost_type_code, 
	desc_text 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN false 
	ELSE 
		LET query_text = "SELECT * ", 
		" FROM shipcosttype ", 
		" WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		" AND ", where_part clipped, 
		" ORDER BY cmpy_code, cost_type_code " 
		PREPARE sel_text FROM query_text 
		DECLARE cost_curs CURSOR FOR sel_text 
		RETURN true 
	END IF 
END FUNCTION 



FUNCTION doit() 
	DEFINE answer CHAR(1), 
	j, del_cnt, i SMALLINT, 
	mess_prompt STRING 

	LET idx = 0 
	LET del_cnt = 0 
	FOREACH cost_curs INTO pr_shipcosttype.* 
		LET idx = idx + 1 
		LET pa_shipcosttype[idx].scroll_flag = " " 
		LET pa_shipcosttype[idx].cost_type_code = 
		pr_shipcosttype.cost_type_code 
		LET pa_shipcosttype[idx].desc_text = 
		pr_shipcosttype.desc_text 
		IF idx > 49 THEN 
			ERROR " First 50 Cost types selected" 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count (idx) 
	MESSAGE "" 
	MESSAGE " F1 TO add, RETURN on line TO change" 
	attribute(yellow) 

	INPUT ARRAY pa_shipcosttype WITHOUT DEFAULTS FROM sr_shipcosttype.* 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF pa_shipcosttype[idx].cost_type_code IS NULL THEN 
				ERROR "There are no more rows in this direction" 
			ELSE 
				LET pr_scroll_flag = pa_shipcosttype[idx].scroll_flag 
				LET pr_shipcosttype.cost_type_code = 
				pa_shipcosttype[idx].cost_type_code 
				LET pr_shipcosttype.desc_text = 
				pa_shipcosttype[idx].desc_text 
			END IF 
			LET ans = pa_shipcosttype[idx].scroll_flag 

		BEFORE FIELD cost_type_code 
			IF pa_shipcosttype[idx].cost_type_code IS NOT NULL THEN 
				CALL changor() RETURNING pr_shipcosttype.desc_text 
				LET pa_shipcosttype[idx].scroll_flag = pr_scroll_flag 
				LET pa_shipcosttype[idx].cost_type_code = 
				pr_shipcosttype.cost_type_code 
				LET pa_shipcosttype[idx].desc_text = 
				pr_shipcosttype.desc_text 
				DISPLAY pa_shipcosttype[idx].* TO sr_shipcosttype[scrn].* 

				NEXT FIELD scroll_flag 
			END IF 
		AFTER FIELD scroll_flag 
			LET pa_shipcosttype[idx].scroll_flag = ans 
		ON KEY (F2) 
			IF pa_shipcosttype[idx].cost_type_code IS NOT NULL THEN 
				IF pa_shipcosttype[idx].cost_type_code = "FOB" THEN 
					ERROR "Unable TO delete FOB code " 
					NEXT FIELD scroll_flag 
				END IF 
				IF pa_shipcosttype[idx].cost_type_code = "DUTY" THEN 
					ERROR "Unable TO delete DUTY code " 
					NEXT FIELD scroll_flag 
				END IF 
				IF pa_shipcosttype[idx].cost_type_code = "LATE" THEN 
					ERROR "Unable TO delete LATE code " 
					NEXT FIELD scroll_flag 
				END IF 
				IF pa_shipcosttype[idx].scroll_flag = "*" THEN 
					LET pa_shipcosttype[idx].scroll_flag = NULL 
					LET ans = NULL 
					LET del_cnt = del_cnt - 1 
				ELSE 
					LET pa_shipcosttype[idx].scroll_flag = "*" 
					LET ans = "*" 
					LET del_cnt = del_cnt + 1 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 

		BEFORE INSERT 
			CALL addor() 
			IF int_flag OR 
			quit_flag THEN 
				FOR i = idx TO arr_count() 
					LET pa_shipcosttype[i].* = pa_shipcosttype[i+1].* 
				END FOR 
				INITIALIZE pa_shipcosttype[i+1].* TO NULL 
				LET j = idx 
				FOR i = scrn TO 6 
					DISPLAY pa_shipcosttype[j].* TO sr_shipcosttype[i].* 

					LET j = j + 1 
				END FOR 
				LET int_flag = 0 
				LET quit_flag = 0 
			ELSE 
				LET pa_shipcosttype[idx].scroll_flag = pr_scroll_flag 
				LET pa_shipcosttype[idx].cost_type_code = 
				pr_shipcosttype.cost_type_code 
				LET pa_shipcosttype[idx].desc_text = 
				pr_shipcosttype.desc_text 
				DISPLAY pa_shipcosttype[idx].* TO sr_shipcosttype[scrn].* 

			END IF 

		AFTER INPUT 
			IF int_flag != 0 OR 
			quit_flag != 0 THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
			ELSE 
				IF del_cnt > 0 THEN 
					--            prompt " Confirmation TO Delete ",del_cnt," Ship Cost Type(s). (Y/N)?" -- albo
					--               FOR CHAR ans
					-- albo --
					LET mess_prompt = " Confirmation TO Delete ",TRIM(del_cnt)," Ship Cost Type(s).", 
					"\n ", 
					"\n (Y/N)?" 

					LET ans = promptYN("",mess_prompt,"Y") -- albo 
					----------
					IF upshift(ans) = "Y" THEN 
						FOR idx = 1 TO arr_count() 
							IF pa_shipcosttype[idx].scroll_flag = "*" THEN 
								DELETE FROM shipcosttype 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cost_type_code = 
								pa_shipcosttype[idx].cost_type_code 
							END IF 
						END FOR 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 


FUNCTION addor() 

	OPEN WINDOW ba_wind with FORM "L141" 
	CALL windecoration_l("L141") -- albo kd-763 

	INITIALIZE pr_shipcosttype.* TO NULL 

	DISPLAY BY NAME pr_shipcosttype.cost_type_code, 
	pr_shipcosttype.desc_text, 
	pr_shipcosttype.class_ind, 
	pr_shipcosttype.acct_code, 
	pr_shipcosttype.exp_acct_code, 
	pr_shipcosttype.ord_acct_code, 
	pr_shipcosttype.ret_acct_code 


	INPUT BY NAME pr_shipcosttype.cost_type_code, 
	pr_shipcosttype.desc_text, 
	pr_shipcosttype.class_ind, 
	pr_shipcosttype.acct_code, 
	pr_shipcosttype.exp_acct_code, 
	pr_shipcosttype.ord_acct_code, 
	pr_shipcosttype.ret_acct_code WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (acct_code) 
					LET pr_shipcosttype.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipcosttype.acct_code 
					NEXT FIELD acct_code 
				WHEN infield (exp_acct_code) 
					LET pr_shipcosttype.exp_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipcosttype.exp_acct_code 
					NEXT FIELD exp_acct_code 
				WHEN infield (ord_acct_code) 
					LET pr_shipcosttype.ord_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipcosttype.ord_acct_code 
					NEXT FIELD ord_acct_code 
				WHEN infield (ret_acct_code) 
					LET pr_shipcosttype.ret_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipcosttype.ret_acct_code 
					NEXT FIELD ret_acct_code 
			END CASE 

		AFTER FIELD cost_type_code 
			IF pr_shipcosttype.cost_type_code IS NULL THEN 
				ERROR " Cost type code must be entered" 
				NEXT FIELD cost_type_code 
			END IF 
			SELECT count(*) INTO count_coa FROM shipcosttype 
			WHERE cost_type_code = pr_shipcosttype.cost_type_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF count_coa> 0 THEN 
				ERROR " Cost type code already exists use change" 
				NEXT FIELD cost_type_code 
			END IF 

		AFTER FIELD desc_text 
			IF pr_shipcosttype.desc_text IS NULL 
			OR pr_shipcosttype.desc_text = " " THEN 
				ERROR " Cost type description must be entered" 
				NEXT FIELD desc_text 
			END IF 
		AFTER FIELD acct_code 
			IF pr_shipcosttype.acct_code IS NOT NULL THEN 
				SELECT count(*) INTO count_coa FROM coa 
				WHERE acct_code = pr_shipcosttype.acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF count_coa = 0 THEN 
					ERROR " Account code does NOT exist in Chart " 
					NEXT FIELD acct_code 
				END IF 
			END IF 
		AFTER FIELD exp_acct_code 
			IF pr_shipcosttype.exp_acct_code IS NOT NULL THEN 
				SELECT count(*) INTO count_coa FROM coa 
				WHERE acct_code = pr_shipcosttype.exp_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF count_coa = 0 THEN 
					ERROR " Account code does NOT exist in Chart " 
					NEXT FIELD exp_acct_code 
				END IF 
			END IF 
		AFTER FIELD ord_acct_code 
			IF pr_shipcosttype.ord_acct_code IS NOT NULL THEN 
				SELECT count(*) INTO count_coa FROM coa 
				WHERE acct_code = pr_shipcosttype.ord_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF count_coa = 0 THEN 
					ERROR " Account code does NOT exist in Chart " 
					NEXT FIELD ord_acct_code 
				END IF 
			END IF 
		AFTER FIELD ret_acct_code 
			IF pr_shipcosttype.ret_acct_code IS NOT NULL THEN 
				SELECT count(*) INTO count_coa FROM coa 
				WHERE acct_code = pr_shipcosttype.ret_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF count_coa = 0 THEN 
					ERROR " Account code does NOT exist in Chart " 
					NEXT FIELD ret_acct_code 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag != 0 OR 
			quit_flag != 0 THEN 
			ELSE 
				IF pr_shipcosttype.cost_type_code IS NULL THEN 
					ERROR " Cost type code must be entered" 
					NEXT FIELD cost_type_code 
				END IF 
				SELECT count(*) INTO count_coa FROM shipcosttype 
				WHERE cost_type_code = pr_shipcosttype.cost_type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF count_coa> 0 THEN 
					ERROR " Cost type code already exists use change" 
					NEXT FIELD cost_type_code 
				END IF 
				IF pr_shipcosttype.desc_text IS NULL 
				OR pr_shipcosttype.desc_text = " " THEN 
					ERROR " Cost type description must be entered" 
					NEXT FIELD desc_text 
				END IF 
				IF pr_shipcosttype.acct_code IS NOT NULL THEN 
					SELECT count(*) INTO count_coa FROM coa 
					WHERE acct_code = pr_shipcosttype.acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF count_coa = 0 THEN 
						ERROR " Account code does NOT exist in Chart " 
						NEXT FIELD acct_code 
					END IF 
				END IF 
				IF pr_shipcosttype.exp_acct_code IS NOT NULL THEN 
					SELECT count(*) INTO count_coa FROM coa 
					WHERE acct_code = pr_shipcosttype.exp_acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF count_coa = 0 THEN 
						ERROR " Account code does NOT exist in Chart " 
						NEXT FIELD exp_acct_code 
					END IF 
				END IF 
				IF pr_shipcosttype.ord_acct_code IS NOT NULL THEN 
					SELECT count(*) INTO count_coa FROM coa 
					WHERE acct_code = pr_shipcosttype.ord_acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF count_coa = 0 THEN 
						ERROR " Account code does NOT exist in Chart " 
						NEXT FIELD ord_acct_code 
					END IF 
				END IF 
				IF pr_shipcosttype.ret_acct_code IS NOT NULL THEN 
					SELECT count(*) INTO count_coa FROM coa 
					WHERE acct_code = pr_shipcosttype.ret_acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF count_coa = 0 THEN 
						ERROR " Account code does NOT exist in Chart " 
						NEXT FIELD ret_acct_code 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag != 0 OR 
	quit_flag != 0 THEN 
	ELSE 
		LET pr_shipcosttype.cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF (pr_shipcosttype.cost_type_code IS NOT null) THEN 
			INSERT INTO shipcosttype VALUES (pr_shipcosttype.*) 
		END IF 
	END IF 

	CLOSE WINDOW ba_wind 
END FUNCTION 



FUNCTION changor() 

	DEFINE save_code LIKE shipcosttype.cost_type_code, 
	save_desc_text LIKE shipcosttype.desc_text, 
	pr_shipcosttype RECORD LIKE shipcosttype.* 

	OPEN WINDOW ba_wind with FORM "L141" 
	CALL windecoration_l("L141") -- albo kd-763 

	SELECT shipcosttype.* INTO pr_shipcosttype.* FROM shipcosttype 
	WHERE cost_type_code = pa_shipcosttype[idx].cost_type_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET save_desc_text = pr_shipcosttype.desc_text 
	LET save_code = pr_shipcosttype.cost_type_code 

	DISPLAY BY NAME pr_shipcosttype.cost_type_code, 
	pr_shipcosttype.desc_text, 
	pr_shipcosttype.class_ind, 
	pr_shipcosttype.acct_code, 
	pr_shipcosttype.exp_acct_code, 
	pr_shipcosttype.ord_acct_code, 
	pr_shipcosttype.ret_acct_code 

	INPUT BY NAME pr_shipcosttype.desc_text, 
	pr_shipcosttype.class_ind, 
	pr_shipcosttype.acct_code, 
	pr_shipcosttype.exp_acct_code, 
	pr_shipcosttype.ord_acct_code, 
	pr_shipcosttype.ret_acct_code WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (acct_code) 
					LET pr_shipcosttype.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipcosttype.acct_code 
					NEXT FIELD acct_code 
				WHEN infield (exp_acct_code) 
					LET pr_shipcosttype.exp_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipcosttype.exp_acct_code 
					NEXT FIELD exp_acct_code 
				WHEN infield (ord_acct_code) 
					LET pr_shipcosttype.ord_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipcosttype.ord_acct_code 
					NEXT FIELD ord_acct_code 
				WHEN infield (ret_acct_code) 
					LET pr_shipcosttype.ret_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipcosttype.ret_acct_code 
					NEXT FIELD ret_acct_code 
			END CASE 

		AFTER FIELD desc_text 
			IF pr_shipcosttype.desc_text IS NULL 
			OR pr_shipcosttype.desc_text = " " THEN 
				ERROR " Cost type description must be entered" 
				NEXT FIELD desc_text 
			END IF 
		AFTER FIELD acct_code 
			IF pr_shipcosttype.acct_code IS NOT NULL THEN 
				SELECT count(*) INTO count_coa FROM coa 
				WHERE acct_code = pr_shipcosttype.acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF count_coa = 0 THEN 
					ERROR " Account code does NOT exist in Chart " 
					NEXT FIELD acct_code 
				END IF 
			END IF 
		AFTER FIELD exp_acct_code 
			IF pr_shipcosttype.exp_acct_code IS NOT NULL THEN 
				SELECT count(*) INTO count_coa FROM coa 
				WHERE acct_code = pr_shipcosttype.exp_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF count_coa = 0 THEN 
					ERROR " Account code does NOT exist in Chart " 
					NEXT FIELD exp_acct_code 
				END IF 
			END IF 

		AFTER FIELD ord_acct_code 
			IF pr_shipcosttype.ord_acct_code IS NOT NULL THEN 
				SELECT count(*) INTO count_coa FROM coa 
				WHERE acct_code = pr_shipcosttype.ord_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF count_coa = 0 THEN 
					ERROR " Account code does NOT exist in Chart " 
					NEXT FIELD ord_acct_code 
				END IF 
			END IF 

		AFTER FIELD ret_acct_code 
			IF pr_shipcosttype.ret_acct_code IS NOT NULL THEN 
				SELECT count(*) INTO count_coa FROM coa 
				WHERE acct_code = pr_shipcosttype.ret_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF count_coa = 0 THEN 
					ERROR " Account code does NOT exist in Chart " 
					NEXT FIELD ret_acct_code 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag != 0 OR 
			quit_flag != 0 THEN 
				LET pr_shipcosttype.desc_text = save_desc_text 
			ELSE 
				IF pr_shipcosttype.desc_text IS NULL 
				OR pr_shipcosttype.desc_text = " " THEN 
					ERROR " Cost type description must be entered" 
					NEXT FIELD desc_text 
				END IF 
				IF pr_shipcosttype.acct_code IS NOT NULL THEN 
					SELECT count(*) INTO count_coa FROM coa 
					WHERE acct_code = pr_shipcosttype.acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF count_coa = 0 THEN 
						NEXT FIELD acct_code 
					END IF 
				END IF 
				IF pr_shipcosttype.exp_acct_code IS NOT NULL THEN 
					SELECT count(*) INTO count_coa FROM coa 
					WHERE acct_code = pr_shipcosttype.exp_acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF count_coa = 0 THEN 
						ERROR " Account code does NOT exist in Chart " 
						NEXT FIELD exp_acct_code 
					END IF 
				END IF 
				IF pr_shipcosttype.ord_acct_code IS NOT NULL THEN 
					SELECT count(*) INTO count_coa FROM coa 
					WHERE acct_code = pr_shipcosttype.ord_acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF count_coa = 0 THEN 
						ERROR " Account code does NOT exist in Chart " 
						NEXT FIELD ord_acct_code 
					END IF 
				END IF 
				IF pr_shipcosttype.ret_acct_code IS NOT NULL THEN 
					SELECT count(*) INTO count_coa FROM coa 
					WHERE acct_code = pr_shipcosttype.ret_acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF count_coa = 0 THEN 
						ERROR " Account code does NOT exist in Chart " 
						NEXT FIELD ret_acct_code 
					END IF 
				END IF 

				IF pr_shipcosttype.cost_type_code IS NOT NULL THEN 
					UPDATE shipcosttype SET 
					desc_text = pr_shipcosttype.desc_text, 
					acct_code = pr_shipcosttype.acct_code, 
					class_ind = pr_shipcosttype.class_ind, 
					exp_acct_code = pr_shipcosttype.exp_acct_code, 
					ord_acct_code = pr_shipcosttype.ord_acct_code, 
					ret_acct_code = pr_shipcosttype.ret_acct_code 
					WHERE cost_type_code = save_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW ba_wind 
	RETURN pr_shipcosttype.desc_text 
END FUNCTION 
