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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_ldx SMALLINT 
END GLOBALS 
###########################################################################
# MAIN
#
#
###########################################################################
MAIN 
	DEFINE l_part_code LIKE product.part_code
	
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("I13") 
	CALL ui_init(0) #Initial UI Init 
	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CALL create_table("prodnote","t_prodnote","","Y")

	LET l_part_code = get_url_part_code() #read URL if we edit a part code directly 
	IF l_part_code IS NOT NULL THEN
		CALL edit_notes(glob_rec_kandoouser.cmpy_code,l_part_code) 
	ELSE 
		OPEN WINDOW I620 with FORM "I620" 
		 CALL windecoration_i("I620") -- albo kd-758 
		WHILE select_prod() 
			CALL scan_prod() 
		END WHILE 
		CLOSE WINDOW I620 
	END IF 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION select_prod()
#
#
###########################################################################
FUNCTION select_prod() 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_outer_text CHAR(5) 
	DEFINE x SMALLINT 

	CLEAR FORM 
	ERROR kandoomsg2("I",1001,"") 
	CONSTRUCT BY NAME l_where_text ON 
		product.part_code, 
		product.desc_text, 
		prodnote.note_date, 
		product.oem_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I13","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		ERROR kandoomsg2("I",1002,"") 
		LET l_outer_text = "outer" 
		FOR x = 1 TO (length(l_where_text) -7) 
			IF l_where_text[x,x+7] = "prodnote" THEN 
				LET l_outer_text = NULL 
				EXIT FOR 
			END IF 
		END FOR 
		LET l_query_text = "SELECT unique product.* ", 
		"FROM product,",l_outer_text," ", 
		"prodnote ", 
		"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND product.status_ind != '3' ", 
		"AND prodnote.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND prodnote.part_code = product.part_code ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2" 
		PREPARE s_product FROM l_query_text 
		DECLARE c_product CURSOR FOR s_product 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_prod()
###########################################################################


###########################################################################
# FUNCTION scan_prod()
#
#
###########################################################################
FUNCTION scan_prod() 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		note_date LIKE prodnote.note_date 
	END RECORD 
	DEFINE l_arr_rec_oem DYNAMIC ARRAY OF RECORD 
		oem_text LIKE product.oem_text 
	END RECORD 
	DEFINE l_idx SMALLINT 

	LET l_idx = 0 
	FOREACH c_product INTO l_rec_product.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_product[l_idx].part_code = l_rec_product.part_code 
		LET l_arr_rec_product[l_idx].desc_text = l_rec_product.desc_text 
		LET l_arr_rec_oem[l_idx].oem_text = l_rec_product.oem_text 
		SELECT max(note_date) INTO l_arr_rec_product[l_idx].note_date 
		FROM prodnote 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_product.part_code 
		IF l_arr_rec_product[l_idx].note_date = 0 THEN 
			LET l_arr_rec_product[l_idx].note_date = NULL 
		END IF 
	END FOREACH 
	
	MESSAGE kandoomsg2("I",1031,"") 
	DISPLAY ARRAY l_arr_rec_product TO sr_product.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","I13","input-arr-l_arr_rec_product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD part_code 
			IF l_idx > 0 AND l_arr_rec_product.getSize() > 0 THEN
				CALL edit_notes(glob_rec_kandoouser.cmpy_code,l_arr_rec_product[l_idx].part_code)
				 
				SELECT max(note_date) INTO l_arr_rec_product[l_idx].note_date 
				FROM prodnote 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND part_code = l_arr_rec_product[l_idx].part_code 
				IF l_arr_rec_product[l_idx].note_date = 0 THEN 
					LET l_arr_rec_product[l_idx].note_date = NULL 
				END IF 
			END IF

	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
###########################################################################
# END FUNCTION scan_prod()
###########################################################################


###########################################################################
# FUNCTION edit_notes(p_cmpy_code,p_part_code)
#
#
###########################################################################
FUNCTION edit_notes(p_cmpy_code,p_part_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodnote RECORD LIKE prodnote.* 
	DEFINE l_arr_rec_prodnote DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		note_date LIKE prodnote.note_date, 
		note_text LIKE prodnote.note_text 
	END RECORD 
	DEFINE l_curr_date DATE 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_product.* 
	FROM product 
	WHERE cmpy_code = p_cmpy_code 
	AND part_code = p_part_code 
	AND status_ind != "3" 
	IF status = notfound THEN 
		RETURN 
	END IF 

	DELETE FROM t_prodnote 

	OPEN WINDOW i108 with FORM "I108" 
	 CALL windecoration_i("I108") -- albo kd-758 

	DISPLAY BY NAME 
		l_rec_product.part_code, 
		l_rec_product.desc_text 

	SELECT count(*) INTO l_idx 
	FROM prodnote 
	WHERE cmpy_code = p_cmpy_code 
	AND part_code = p_part_code 
	
	IF l_idx >= 50 THEN 
		MESSAGE kandoomsg2("I",1001,"") 
		CONSTRUCT BY NAME l_where_text ON note_date
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		MESSAGE kandoomsg2("I",1002,"") 
		LET l_query_text = 
			"SELECT * FROM prodnote ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND part_code = '",p_part_code,"' ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY 2,3 desc,4,1" 
		PREPARE s_note FROM l_query_text 
		DECLARE c_note CURSOR FOR s_note 

		LET l_idx = 0 
		FOREACH c_note INTO l_rec_prodnote.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_prodnote[l_idx].note_date = l_rec_prodnote.note_date 
			LET l_arr_rec_prodnote[l_idx].note_text = l_rec_prodnote.note_text 

			INSERT INTO t_prodnote VALUES (l_rec_prodnote.*) 
			## keep track of whats in the ARRAY so it can undergo
			## a (delete/re-add) UPDATE logic
		END FOREACH 

		LET l_curr_date = NULL 
		
		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 

		MESSAGE kandoomsg2("I",1032,"")	#1032 F1 Add F2 Delete RETURN Edit F10 Finish Note Entry
		INPUT ARRAY l_arr_rec_prodnote WITHOUT DEFAULTS FROM sr_prodnote.* ATTRIBUTE(UNBUFFERED,APPEND ROW = FALSE)  

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				IF l_curr_date IS NOT NULL THEN 
					LET l_arr_rec_prodnote[l_idx].note_date = l_curr_date 
					NEXT FIELD note_date 
				END IF 

			ON KEY (f10) #???buffer update ???
				LET l_arr_rec_prodnote[l_idx].note_text = get_fldbuf(note_text) 
				LET l_curr_date = NULL 
				NEXT FIELD scroll_flag 

			BEFORE FIELD scroll_flag 
				LET l_curr_date = NULL 

			BEFORE INSERT 
				LET l_arr_rec_prodnote[l_idx].note_date = l_curr_date 
				NEXT FIELD note_date 

			BEFORE DELETE 
				INITIALIZE l_arr_rec_prodnote[l_idx].* TO NULL 
				LET l_curr_date = NULL 
				NEXT FIELD scroll_flag 

			AFTER FIELD note_date 
				IF l_arr_rec_prodnote[l_idx].note_date IS NULL THEN 
					NEXT FIELD scroll_flag 
				END IF 

--			AFTER FIELD note_text 
--				IF fgl_lastkey() != fgl_keyval("up") THEN 
--					## WHEN going down take the date with the CURSOR
--					IF l_arr_rec_prodnote[l_idx+1].note_date IS NULL 
--					OR l_arr_rec_prodnote[l_idx+1].note_date = 0 THEN 
--						LET l_curr_date = l_arr_rec_prodnote[l_idx].note_date 
--					END IF 
--				ELSE 
--					LET l_curr_date = NULL 
--				END IF 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			ERROR kandoomsg2("I",1005,"") 
			GOTO bypass 
			LABEL recovery:
			 
			IF error_recover(l_err_message, status) = "N" THEN 
				CLOSE WINDOW i108 
				RETURN 
			END IF 
			
			LABEL bypass: 
			
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				LET l_err_message = "Deleting previous notes" 
				DECLARE c_prodnote CURSOR FOR 
				SELECT * FROM t_prodnote 
			
				FOREACH c_prodnote INTO l_rec_prodnote.* 
					DELETE FROM prodnote 
					WHERE cmpy_code = p_cmpy_code 
					AND part_code = l_rec_prodnote.part_code 
					AND note_date = l_rec_prodnote.note_date 
					AND note_seq = l_rec_prodnote.note_seq 
					DELETE FROM t_prodnote 
					WHERE cmpy_code = p_cmpy_code 
					AND part_code = l_rec_prodnote.part_code 
					AND note_date = l_rec_prodnote.note_date 
					AND note_seq = l_rec_prodnote.note_seq 
				END FOREACH 
			
				LET l_err_message = "E11 - Adding new notes" 
			
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_prodnote[l_idx].note_date IS NOT NULL 
					AND l_arr_rec_prodnote[l_idx].note_date != 0 THEN 
						UPDATE prodnote 
						SET note_text = l_arr_rec_prodnote[l_idx].note_text 
						WHERE cmpy_code = p_cmpy_code 
						AND part_code = l_rec_prodnote.part_code 
						AND note_date = l_arr_rec_prodnote[l_idx].note_date 
						AND note_seq = l_idx 
						IF sqlca.sqlerrd[3] = 0 THEN 
							INSERT INTO prodnote 
							VALUES (p_cmpy_code,p_part_code, 
							l_arr_rec_prodnote[l_idx].note_date, 
							l_idx, 
							l_arr_rec_prodnote[l_idx].note_text) 
						END IF 
					END IF 
				END FOR 
			
			COMMIT WORK 
		
			WHENEVER ERROR stop 
		
		END IF 
	END IF 
	CLOSE WINDOW I108 
END FUNCTION 
###########################################################################
# END FUNCTION edit_notes(p_cmpy_code,p_part_code)
###########################################################################