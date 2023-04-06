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

	Source code beautified by beautify.pl on 2020-01-03 09:12:37	$Id: $
}




# IK1 - Product Kit Maintenance
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	pr_kithead RECORD LIKE kithead.*, 
	err_message CHAR(60) 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IK1") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i159 with FORM "I159" 
	 CALL windecoration_i("I159") -- albo kd-758 
	WHILE select_kithead() 
		CALL scan_kithead() 
	END WHILE 
	CLOSE WINDOW i159 
END MAIN 


FUNCTION select_kithead() 
	DEFINE 
	where_text CHAR(100), 
	query_text CHAR(300) 

	CLEAR FORM 
	LET msgresp = kandoomsg("I",1001,"") 
	#1001 Enter Selection Criteria
	CONSTRUCT BY NAME where_text ON kit_code, 
	kit_text, 
	type_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IK1","construct-kit_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("I",1002,"") 
		#1002 Searching Database
		LET query_text = "SELECT * FROM kithead ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",where_text clipped," ", 
		"ORDER BY kit_code" 
		PREPARE s_kithead FROM query_text 
		DECLARE c_kithead CURSOR FOR s_kithead 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_kithead() 
	DEFINE 
	pa_kithead array[100] OF RECORD 
		scroll_flag CHAR(1), 
		kit_code LIKE kithead.kit_code, 
		kit_text LIKE kithead.kit_text, 
		type_ind LIKE kithead.type_ind 
	END RECORD, 
	del_cnt,idx,scrn,pr_curr,pr_cnt SMALLINT 

	LET idx = 0 
	FOREACH c_kithead INTO pr_kithead.* 
		LET idx = idx + 1 
		LET pa_kithead[idx].kit_code = pr_kithead.kit_code 
		LET pa_kithead[idx].kit_text = pr_kithead.kit_text 
		LET pa_kithead[idx].type_ind = pr_kithead.type_ind 
		IF idx = 100 THEN 
			LET msgresp = kandoomsg("I",9172,idx) 
			#9172 First 'idx' entries selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET idx = 1 
	END IF 
	CALL set_count(idx) 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	LET msgresp = kandoomsg("I",1003,"") 
	#1003 F1 TO Add - F2 Delete - RETURN on line TO Edit
	INPUT ARRAY pa_kithead WITHOUT DEFAULTS FROM sr_kithead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IK1","input-arr-pa_kithead-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD scroll_flag 
			LET scrn = scr_line() 
			LET idx = arr_curr() 
			DISPLAY pa_kithead[idx].* TO sr_kithead[scrn].* 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() = arr_count() THEN 
				LET msgresp = kandoomsg("I",9001,"") 
				#9001 No more Rows in direction
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD kit_code 
			CALL edit_kithead(pa_kithead[idx].kit_code) 
			RETURNING pa_kithead[idx].kit_code 
			SELECT * INTO pr_kithead.* 
			FROM kithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND kit_code = pa_kithead[idx].kit_code 
			IF status = 0 THEN 
				LET pa_kithead[idx].kit_text = pr_kithead.kit_text 
				LET pa_kithead[idx].type_ind = pr_kithead.type_ind 
				DISPLAY pa_kithead[idx].* TO sr_kithead[scrn].* 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET pr_cnt = arr_count() 
				LET pr_curr = arr_curr() 
				LET pa_kithead[idx].kit_code = edit_kithead("") 
				SELECT * INTO pr_kithead.* 
				FROM kithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND kit_code = pa_kithead[idx].kit_code 
				IF status = 0 THEN 
					LET pa_kithead[idx].kit_text = pr_kithead.kit_text 
					LET pa_kithead[idx].type_ind = pr_kithead.type_ind 
				ELSE 
					FOR idx = pr_curr TO pr_cnt 
						LET pa_kithead[idx].* = pa_kithead[idx+1].* 
						IF scrn <= 14 THEN 
							DISPLAY pa_kithead[idx].* TO sr_kithead[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
				END IF 
			ELSE 
				IF idx > 1 THEN 
					LET msgresp = kandoomsg("I",9001,"") 
					#9001 There are no more rows....
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_kithead[idx].* TO sr_kithead[scrn].* 

		ON KEY (F2) 
			IF pa_kithead[idx].scroll_flag IS NULL THEN 
				LET pa_kithead[idx].scroll_flag = "*" 
				LET del_cnt = del_cnt + 1 
			ELSE 
				LET pa_kithead[idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
		ON KEY (control-c) 
			LET int_flag = true 
			EXIT INPUT 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message, status) = "N" THEN 
			RETURN 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			IF del_cnt > 0 THEN 
				IF kandoomsg("I",8000,del_cnt) = "Y" THEN 
					#8025 Confirm TO Delete ",del_cnt," Product Kit(s)? (Y/N)"
					FOR idx = 1 TO arr_count() 
						IF pa_kithead[idx].scroll_flag = "*" THEN 
							DELETE FROM kithead 
							WHERE kit_code = pa_kithead[idx].kit_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							DELETE FROM kitdetl 
							WHERE kit_code = pa_kithead[idx].kit_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END IF 
					END FOR 
				END IF 
			END IF 
			WHENEVER ERROR stop 
		COMMIT WORK 
	END IF 
END FUNCTION 


FUNCTION edit_kithead(pr_kit_code) 
	DEFINE 
	serialised CHAR(18), 
	get_component CHAR(1), 
	pr_kit_code LIKE kithead.kit_code, 
	pr_kitdetl RECORD LIKE kitdetl.*, 
	pr_product RECORD LIKE product.*, 
	ps_kitdetl RECORD 
		part_code LIKE kitdetl.part_code, 
		desc_text LIKE product.desc_text, 
		serial_flag LIKE product.serial_flag, 
		kit_per LIKE kitdetl.kit_per, 
		kit_qty LIKE kitdetl.kit_qty 
	END RECORD, 
	pa_kitdetl array[100] OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE kitdetl.part_code, 
		desc_text LIKE product.desc_text, 
		serial_flag LIKE product.serial_flag, 
		kit_per LIKE kitdetl.kit_per, 
		kit_qty LIKE kitdetl.kit_qty 
	END RECORD, 
	pr_total_per LIKE kitdetl.kit_per, 
	pr_line_cnt LIKE kitdetl.line_num, 
	idx,scrn SMALLINT 

	OPEN WINDOW i25 with FORM "I259" 
	 CALL windecoration_i("I259") -- albo kd-758 
	IF pr_kit_code IS NOT NULL THEN 
		SELECT * INTO pr_kithead.* 
		FROM kithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND kit_code = pr_kit_code 
		IF status = notfound THEN 
			LET pr_kit_code = NULL 
		ELSE 
			SELECT * INTO pr_product.* 
			FROM product 
			WHERE part_code = pr_kithead.kit_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pr_product.serial_flag = "Y" THEN 
				LET get_component = "Y" 
				LET serialised = "Serialized Product" 
			ELSE 
				LET get_component = "N" 
				LET serialised = " " 
			END IF 
		END IF 
	ELSE 
		LET pr_kithead.type_ind = "1" 
		LET pr_kithead.qtyper_ind = "1" 
	END IF 
	WHILE true 
		FOR idx = 1 TO 8 
			SELECT kitdetl.*, product.desc_text, product.serial_flag 
			INTO pr_kitdetl.*, 
			pr_product.desc_text, 
			pr_product.serial_flag 
			FROM kitdetl, product 
			WHERE kitdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND product.part_code = kitdetl.part_code 
			AND kit_code = pr_kit_code 
			AND line_num = idx 
			IF status != 0 THEN 
				INITIALIZE pr_kitdetl.* TO NULL 
				INITIALIZE pr_product.* TO NULL 
			END IF 
			DISPLAY "", 
			pr_kitdetl.part_code, 
			pr_product.desc_text, 
			pr_product.serial_flag, 
			pr_kitdetl.kit_per, 
			pr_kitdetl.kit_qty 
			TO sr_kitdetl[idx].* 

		END FOR 
		DISPLAY BY NAME serialised 
		INPUT BY NAME pr_kithead.kit_code, 
		pr_kithead.kit_text, 
		pr_kithead.type_ind, 
		pr_kithead.qtyper_ind WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IK1","input-pr_kithead-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-c) 
				LET int_flag = true 
				EXIT WHILE 
			ON KEY (control-b) 
				IF infield(kit_code) THEN 
					LET pr_kithead.kit_code= show_part(glob_rec_kandoouser.cmpy_code,"") 
					NEXT FIELD kit_code 
				END IF 
			BEFORE FIELD kit_code 
				IF pr_kit_code IS NOT NULL THEN 
					NEXT FIELD NEXT 
				END IF 
			AFTER FIELD kit_code 
				IF pr_kithead.kit_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9230,"") 
					#9230" Kit Code Must Be Entered
					NEXT FIELD kit_code 
				END IF 
				SELECT unique 1 FROM kithead 
				WHERE kit_code = pr_kithead.kit_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status != notfound THEN 
					LET msgresp = kandoomsg("I",9231,"") 
					#9231" Kit Code Already Exists
					NEXT FIELD kit_code 
				END IF 
				SELECT * INTO pr_product.* 
				FROM product 
				WHERE part_code = pr_kithead.kit_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9010,"") 
					#9010 " Product Code Not Found - Try Window
					NEXT FIELD kit_code 
				END IF 
				IF pr_kithead.kit_text IS NULL THEN 
					LET pr_kithead.kit_text = pr_product.desc_text 
				END IF 
				IF pr_product.serial_flag = "Y" THEN 
					LET get_component = "Y" 
					LET serialised = "Serialized Product" 
				ELSE 
					LET get_component = "N" 
					LET serialised = " " 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		DECLARE c_kitdetl CURSOR FOR 
		SELECT * FROM kitdetl 
		WHERE kit_code = pr_kithead.kit_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		ORDER BY kit_code,line_num 
		LET msgresp = kandoomsg("I",1002,"") 
		#1002 " Searching database - please wait"
		LET idx = 0 
		FOREACH c_kitdetl INTO pr_kitdetl.* 
			LET idx = idx + 1 
			LET pa_kitdetl[idx].part_code = pr_kitdetl.part_code 
			SELECT desc_text, serial_flag 
			INTO pa_kitdetl[idx].desc_text, 
			pa_kitdetl[idx].serial_flag 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_kitdetl.part_code 
			IF status = notfound THEN 
				LET pa_kitdetl[idx].desc_text = "************" 
				LET pa_kitdetl[idx].serial_flag = "*" 
			END IF 
			LET pa_kitdetl[idx].kit_per = pr_kitdetl.kit_per 
			LET pa_kitdetl[idx].kit_qty = pr_kitdetl.kit_qty 
			IF idx >= 100 THEN 
				LET msgresp = kandoomsg("I",9021,idx) 
				#9021 " First ??? entries Selected Only"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		CALL set_count(idx) 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 
		LET msgresp = kandoomsg("I",1003,"") 
		#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
		INPUT ARRAY pa_kitdetl WITHOUT DEFAULTS FROM sr_kitdetl.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IK1","input-arr-pa_kitdetl-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-c) 
				LET int_flag = true 
				EXIT INPUT 
			ON KEY (control-b) 
				IF infield(part_code) THEN 
					LET pr_kitdetl.part_code = show_part(glob_rec_kandoouser.cmpy_code,"") 
					IF pr_kitdetl.part_code IS NOT NULL THEN 
						LET pa_kitdetl[idx].part_code = pr_kitdetl.part_code 
					END IF 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					NEXT FIELD part_code 
				END IF 
			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				NEXT FIELD scroll_flag 
			BEFORE INSERT 
				INITIALIZE ps_kitdetl.* TO NULL 
				NEXT FIELD part_code 
			BEFORE FIELD scroll_flag 
				DISPLAY pa_kitdetl[idx].* TO sr_kitdetl[scrn].* 

			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF pa_kitdetl[idx+1].part_code IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET msgresp=kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
				LET ps_kitdetl.part_code = pa_kitdetl[idx].part_code 
				LET ps_kitdetl.desc_text = pa_kitdetl[idx].desc_text 
				LET ps_kitdetl.serial_flag = pa_kitdetl[idx].serial_flag 
				LET ps_kitdetl.kit_qty = pa_kitdetl[idx].kit_qty 
				LET ps_kitdetl.kit_per = pa_kitdetl[idx].kit_per 
				LET pa_kitdetl[idx].scroll_flag = NULL 
				DISPLAY pa_kitdetl[idx].* TO sr_kitdetl[scrn].* 

			AFTER FIELD part_code 
				IF pa_kitdetl[idx].part_code IS NOT NULL THEN 
					IF pa_kitdetl[idx].part_code = pr_kithead.kit_code THEN 
						LET msgresp = kandoomsg("I",9233,"") 
						#9233 Product Kit Can Not Contain itself
						NEXT FIELD part_code 
					END IF 
					SELECT * INTO pr_product.* FROM product 
					WHERE part_code = pa_kitdetl[idx].part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("I",9010,"") 
						#9010 " Product Code Not Found - Try Window
						NEXT FIELD part_code 
					END IF 
					LET pa_kitdetl[idx].desc_text = pr_product.desc_text 
					LET pa_kitdetl[idx].serial_flag = pr_product.serial_flag 
					DISPLAY pa_kitdetl[idx].* TO sr_kitdetl[scrn].* 

				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						IF pr_kithead.qtyper_ind = "1" THEN 
							IF pa_kitdetl[idx].kit_qty IS NULL THEN 
								LET msgresp = kandoomsg("U",9102,"") 
								NEXT FIELD kit_qty 
							END IF 
						ELSE 
							IF pa_kitdetl[idx].kit_per IS NULL THEN 
								LET msgresp = kandoomsg("U",9102,"") 
								NEXT FIELD kit_per 
							END IF 
						END IF 
						NEXT FIELD scroll_flag 
					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						IF pr_kithead.qtyper_ind = "1" THEN 
							LET pa_kitdetl[idx].kit_per = NULL 
							NEXT FIELD kit_qty 
						END IF 
					OTHERWISE 
						NEXT FIELD part_code 
				END CASE 
			AFTER FIELD kit_per 
				IF pa_kitdetl[idx].kit_per IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD kit_per 
				END IF 
				IF pa_kitdetl[idx].kit_per <= 0 THEN 
					LET msgresp = kandoomsg("U",9005,"0") 
					NEXT FIELD kit_per 
				END IF 
				LET pa_kitdetl[idx].kit_qty = NULL 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD part_code 
					OTHERWISE 
						NEXT FIELD scroll_flag 
				END CASE 
			AFTER FIELD kit_qty 
				IF pa_kitdetl[idx].kit_qty IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD kit_qty 
				END IF 
				IF pa_kitdetl[idx].kit_qty <= 0 THEN 
					LET msgresp = kandoomsg("U",9005,"0") 
					NEXT FIELD kit_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD part_code 
					OTHERWISE 
						NEXT FIELD scroll_flag 
				END CASE 
			AFTER ROW 
				DISPLAY pa_kitdetl[idx].* TO sr_kitdetl[scrn].* 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF NOT (infield(scroll_flag)) THEN 
						IF ps_kitdetl.part_code IS NULL THEN 
							FOR idx = arr_curr() TO arr_count() 
								LET pa_kitdetl[idx].* = pa_kitdetl[idx+1].* 
								IF idx = arr_count() THEN 
									INITIALIZE pa_kitdetl[idx].* TO NULL 
								END IF 
								IF scrn <= 8 THEN 
									DISPLAY pa_kitdetl[idx].* TO sr_kitdetl[scrn].* 

									LET scrn = scrn + 1 
								END IF 
							END FOR 
							LET scrn = scr_line() 
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD scroll_flag 
						ELSE 
							LET pa_kitdetl[idx].part_code = ps_kitdetl.part_code 
							LET pa_kitdetl[idx].desc_text = ps_kitdetl.desc_text 
							LET pa_kitdetl[idx].serial_flag = ps_kitdetl.serial_flag 
							LET pa_kitdetl[idx].kit_qty = ps_kitdetl.kit_qty 
							LET pa_kitdetl[idx].kit_per = ps_kitdetl.kit_per 
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				END IF 
				IF not(int_flag OR quit_flag) THEN 
					LET pr_total_per = 0 
					FOR idx = 1 TO arr_count() 
						IF pa_kitdetl[idx].part_code IS NOT NULL THEN 
							IF pr_kithead.qtyper_ind = "1" 
							AND pa_kitdetl[idx].kit_qty IS NULL THEN 
								LET msgresp = kandoomsg("I",9508,"") 
								#9509 All kit component lines must have a quantity value
								CONTINUE INPUT 
							END IF 
							IF pr_kithead.qtyper_ind = "2" 
							AND pa_kitdetl[idx].kit_per IS NULL THEN 
								LET msgresp = kandoomsg("I",9509,"") 
								#9509 All kit component lines must have a percentage value
								CONTINUE INPUT 
							END IF 
						END IF 
						IF pa_kitdetl[idx].part_code IS NOT NULL 
						AND pr_kithead.qtyper_ind = "2" THEN 
							LET pr_total_per = pr_total_per + pa_kitdetl[idx].kit_per 
						END IF 
					END FOR 
					IF pr_kithead.qtyper_ind = "2" 
					AND pr_total_per != 100 THEN 
						LET msgresp = kandoomsg("I",9232,"") 
						#9232 Percentage Must Total 100
						CONTINUE INPUT 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			GOTO bypass 
			LABEL recovery: 
			IF error_recover(err_message, status) = "N" THEN 
				EXIT WHILE 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				LET err_message = "Deleting Previous Lines" 
				DELETE FROM kitdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND kit_code = pr_kithead.kit_code 
				LET pr_kithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_line_cnt = 0 
				FOR idx = 1 TO arr_count() 
					IF pa_kitdetl[idx].part_code IS NOT NULL THEN 
						LET pr_line_cnt = pr_line_cnt + 1 
						LET pr_kitdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET pr_kitdetl.kit_code = pr_kithead.kit_code 
						LET pr_kitdetl.line_num = pr_line_cnt 
						LET pr_kitdetl.part_code = pa_kitdetl[idx].part_code 
						LET pr_kitdetl.kit_per = pa_kitdetl[idx].kit_per 
						LET pr_kitdetl.kit_qty = pa_kitdetl[idx].kit_qty 
						LET err_message = "Inserting line",pr_line_cnt 
						INSERT INTO kitdetl VALUES (pr_kitdetl.*) 
					END IF 
				END FOR 
				LET err_message = "Updating kit information" 
				UPDATE kithead SET * = pr_kithead.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND kit_code = pr_kithead.kit_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET err_message = "Inserting kit information" 
					INSERT INTO kithead VALUES (pr_kithead.*) 
				END IF 
			COMMIT WORK 
			LET pr_kit_code = pr_kithead.kit_code 
			WHENEVER ERROR stop 
			EXIT WHILE 
		END IF 
	END WHILE 

	IF fgl_lastkey() != fgl_keyval("interrupt") THEN 
		IF get_component = "Y" THEN 
			OPEN WINDOW i260 with FORM "I260" 
			 CALL windecoration_i("I260") -- albo kd-758 
			INPUT BY NAME pr_kithead.serial_product WITHOUT DEFAULTS 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","IK1","input-pr_kithead-2") -- albo kd-505 
				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 
				AFTER FIELD serial_product 
					IF pr_kithead.serial_product != " " THEN 
						SELECT * FROM kitdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND kit_code = pr_kithead.kit_code 
						AND part_code = pr_kithead.serial_product 
						IF status = notfound THEN 
							NEXT FIELD serial_product 
						END IF 
					END IF 
			END INPUT 
			UPDATE kithead SET serial_product = pr_kithead.serial_product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND kit_code = pr_kithead.kit_code 
			CLOSE WINDOW i260 
			CLOSE WINDOW i259 
		END IF 
	END IF 

	RETURN pr_kit_code 
END FUNCTION 
