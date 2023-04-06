##########################################################################
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
# \brief module J74 allows the user TO maintain job management resources
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/J7_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J74_GLOBALS.4gl"

MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("J74") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_j_jm() #init a/ar module/program 
	--CALL J74_main()

	OPEN WINDOW J121 with FORM "J121a" -- alch kd-747 
	CALL winDecoration_j("J121a") -- alch kd-747
 
	WHILE select_resource() 
	END WHILE
	 
	CLOSE WINDOW J121 
END MAIN 


FUNCTION select_resource() 
	DEFINE 
	where_text, 
	query_text CHAR(1000), 
	idx, scrn SMALLINT, 
	pa_jmresource array[300] OF RECORD 
		scroll_flag CHAR(1), 
		res_code LIKE jmresource.res_code, 
		resgrp_code LIKE jmresource.resgrp_code, 
		desc_text LIKE jmresource.desc_text 
	END RECORD 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001," ") 
	#1001 "Enter Selection Criteria; OK TO Continue"
	CONSTRUCT BY NAME where_text ON 
	res_code, 
	resgrp_code, 
	desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J74","const-res_code-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = " SELECT * FROM jmresource ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ",where_text clipped, 
	" ORDER BY res_code " 
	PREPARE s_jmresource FROM query_text 
	DECLARE c_jmresource CURSOR FOR s_jmresource 
	LET idx = 0 
	FOREACH c_jmresource INTO pr_jmresource.* 
		LET idx = idx + 1 
		LET pa_jmresource[idx].scroll_flag = "" 
		LET pa_jmresource[idx].res_code = pr_jmresource.res_code 
		LET pa_jmresource[idx].resgrp_code = pr_jmresource.resgrp_code 
		LET pa_jmresource[idx].desc_text = pr_jmresource.desc_text 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx records selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_jmresource[idx].* TO NULL 
	END IF 
	LET msgresp = kandoomsg("U",1101,"") 
	#1101 F2 TO Delete; ENTER on Line TO Edit
	CALL set_count (idx) 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	INPUT ARRAY pa_jmresource WITHOUT DEFAULTS FROM sr_jmresource.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J74","input_arr-pa_jmresource-1") -- alch kd-506 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_jmresource.res_code = pa_jmresource[idx].res_code 
			LET pr_jmresource.desc_text = pa_jmresource[idx].desc_text 
			DISPLAY pa_jmresource[idx].* TO sr_jmresource[scrn].* 

			NEXT FIELD scroll_flag 
		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp=kandoomsg("A",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
			IF (fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("RETURN") ) 
			AND pa_jmresource[idx].res_code IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
		AFTER ROW 
			DISPLAY pa_jmresource[idx].* TO sr_jmresource[scrn].* 

		BEFORE FIELD res_code 
			OPTIONS DELETE KEY f2, 
			INSERT KEY f1 
			CALL edit_resource() 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f36 
			DISPLAY pa_jmresource[idx].* TO sr_jmresource[scrn].* 

			NEXT FIELD scroll_flag 
		ON KEY (F2) #delete option. 
			IF delete_res(pa_jmresource[idx].res_code) THEN 
				FOR idx = arr_curr() TO arr_count() 
					LET pa_jmresource[idx].* = pa_jmresource[idx+1].* 
					IF arr_curr() = arr_count() THEN 
						INITIALIZE pa_jmresource[idx].* TO NULL 
						EXIT FOR 
					END IF 
					IF scrn <= 10 THEN 
						DISPLAY pa_jmresource[idx].* 
						TO sr_jmresource[scrn].* 

						LET scrn = scrn + 1 
					END IF 
				END FOR 
				LET idx =arr_curr() 
				LET scrn = scr_line() 
				CALL set_count (idx) 
				NEXT FIELD scroll_flag 
				#DISPLAY pa_jmresource[idx].* TO sr_jmresource[scrn].*
				#
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION edit_resource() 
	DEFINE 
	pr_rowid INTEGER 
	OPEN WINDOW j120 with FORM "J120" -- alch kd-747 
	CALL winDecoration_j("J120") -- alch kd-747 
	SELECT * , rowid 
	INTO pr_jmresource.*, pr_rowid 
	FROM jmresource 
	WHERE jmresource.res_code = pr_jmresource.res_code 
	AND jmresource.cmpy_code = glob_rec_kandoouser.cmpy_code 
	CALL disp_resource() 
	DISPLAY pr_jmresource.desc_text TO jmresource.desc_text 

	WHILE true 
		INPUT pr_jmresource.desc_text, 
		pr_jmresource.resgrp_code WITHOUT DEFAULTS 
		FROM jmresource.desc_text, 
		jmresource.resgrp_code 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J74","input-pr_jmresource-1") -- alch kd-506 

			ON KEY (control-b) 
				IF infield (resgrp_code) THEN 
					LET pr_jmresource.resgrp_code = show_resg(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_jmresource.resgrp_code 

				END IF 
			AFTER FIELD desc_text 
				IF pr_jmresource.desc_text = " " 
				OR pr_jmresource.desc_text IS NULL THEN 
					#ERROR "value must be entered"
					LET msgresp = kandoomsg("U",9102," ") 
					NEXT FIELD desc_text 
				END IF 
			AFTER FIELD resgrp_code 
				IF pr_jmresource.resgrp_code IS NULL THEN 
					#ERROR " Value must be entered "
					LET msgresp = kandoomsg("U",9102," ") 
					NEXT FIELD resgrp_code 
				END IF 
				IF pr_jmresource.resgrp_code IS NOT NULL THEN 
					SELECT count(*) 
					INTO cnt 
					FROM resgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND resgrp_code = pr_jmresource.resgrp_code 
					IF cnt = 0 THEN 
						#ERROR "Resource group IS invalid - Try window"
						LET msgresp = kandoomsg("J",9580," ") 
						NEXT FIELD resgrp_code 
					END IF 
				END IF 
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				ELSE 
					IF pr_jmresource.desc_text = " " 
					OR pr_jmresource.desc_text IS NULL THEN 
						#ERROR "value must be entered"
						LET msgresp = kandoomsg("U",9102," ") 
						NEXT FIELD desc_text 
					END IF 
					IF pr_jmresource.resgrp_code IS NULL THEN 
						#ERROR " Value must be entered "
						LET msgresp = kandoomsg("U",9102," ") 
						NEXT FIELD resgrp_code 
					END IF 
					IF pr_jmresource.resgrp_code IS NOT NULL THEN 
						SELECT count(*) 
						INTO cnt 
						FROM resgrp 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND resgrp_code = pr_jmresource.resgrp_code 
						IF cnt = 0 THEN 
							#ERROR "Resource group IS invalid - Try window"
							LET msgresp = kandoomsg("J",9580," ") 
							NEXT FIELD resgrp_code 
						END IF 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		CALL read_resource() 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW j120 
		RETURN 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		LET err_continue = error_recover(err_message, status) 
		IF err_continue != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_message = " J14 - Updating Job" 
			WHENEVER ERROR GOTO recovery 
			UPDATE jmresource 
			SET desc_text = pr_jmresource.desc_text , 
			acct_code = pr_jmresource.acct_code, 
			exp_acct_code = pr_jmresource.exp_acct_code, 
			unit_code = pr_jmresource.unit_code, 
			unit_cost_amt = pr_jmresource.unit_cost_amt, 
			unit_bill_amt = pr_jmresource.unit_bill_amt, 
			cost_ind = pr_jmresource.cost_ind, 
			bill_ind = pr_jmresource.bill_ind, 
			total_tax_flag = pr_jmresource.total_tax_flag, 
			tax_code = pr_jmresource.tax_code, 
			tax_amt = pr_jmresource.tax_amt, 
			allocation_ind = pr_jmresource.allocation_ind, 
			allocation_flag = pr_jmresource.allocation_flag, 
			resgrp_code = pr_jmresource.resgrp_code 
			WHERE rowid = pr_rowid 
			WHENEVER ERROR stop 
		COMMIT WORK 
	END IF 
	CLOSE WINDOW j120 
END FUNCTION 


FUNCTION delete_res(pr_res_code) 
	DEFINE 
	pr_res_code LIKE jmresource.res_code, 
	resbdgt_cnt, 
	jbldg_cnt, tmsht_cnt SMALLINT 

	SELECT count(*) INTO jbldg_cnt FROM jobledger 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_source_text = pr_res_code 
	IF jbldg_cnt IS NULL 
	OR jbldg_cnt = 0 THEN 
		SELECT count(*) INTO tmsht_cnt FROM ts_detail 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND res_code = pr_res_code 
		IF tmsht_cnt IS NULL 
		OR tmsht_cnt = 0 THEN 
			SELECT count(*) INTO resbdgt_cnt FROM resbdgt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND res_code = pr_res_code 
		END IF 
	END IF 
	IF jbldg_cnt > 0 
	OR tmsht_cnt > 0 
	OR resbdgt_cnt > 0 THEN 
		LET msgresp = kandoomsg("J",9581," ") 
		#9581 " This resource has been used, so may NOT be deleted"
		RETURN false 
	ELSE 
		IF kandoomsg("J",8011,"") = "Y" THEN 
			GOTO bypass2 
			LABEL recovery2: 
			LET err_continue = error_recover(err_message, status) 
			IF err_continue != "Y" THEN 
				EXIT program 
			END IF 
			LABEL bypass2: 
			DELETE FROM jmresource 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND res_code = pr_res_code 
			WHENEVER ERROR stop 
			RETURN true 
		END IF 
	END IF 
	RETURN false 
END FUNCTION 
