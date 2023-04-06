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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E11_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
	DEFINE modu_arr_rec_matrix DYNAMIC ARRAY OF RECORD 
		part_code char(15), 
		order_qty FLOAT, 
		minmax_qty FLOAT, 
		line_num SMALLINT 
	END RECORD 
	DEFINE modu_arr_rec_table DYNAMIC ARRAY OF RECORD  
		order_qty char(10), 
		array_num SMALLINT 
	END RECORD 
	DEFINE modu_arr_vertical array[35] OF char(15) 
	DEFINE modu_arr_horizontal array[35] OF char(15) 
	DEFINE modu_parent_code LIKE product.part_code 
	DEFINE modu_template LIKE product.part_code 
	DEFINE modu_ware_code LIKE warehouse.ware_code 
	DEFINE modu_class_code LIKE product.class_code 
	DEFINE modu_cust_code LIKE customer.cust_code 
	# glob_rec_opparms RECORD LIKE opparms.*
	DEFINE modu_mode char(1) 
	DEFINE modu_horizontal_count, modu_vertical_count, modu_matrix_count SMALLINT 
	DEFINE modu_h_start, modu_h_end, modu_v_start, modu_v_end, modu_counter SMALLINT 
	DEFINE modu_loop, modu_v_more, modu_h_more, modu_v_offset, modu_h_offset SMALLINT 
###########################################################################
# #allow FOR the entry/maintenance of a color/size matrix FOR products.
###########################################################################
# FUNCTION create_matrix_table() 
#
#
###########################################################################
FUNCTION create_matrix_table() 
	CREATE temp TABLE t_matrix (part_code char(15), 
	order_qty FLOAT, 
	minmax_qty FLOAT, 
	line_num smallint) 
END FUNCTION 
###########################################################################
# END FUNCTION create_matrix_table() 
###########################################################################


###########################################################################
# FUNCTION initialize_matrix(p_rec_product, p_temp_ware_code, p_temp_cust_code,p_temp_mode)  
#
#
###########################################################################
FUNCTION initialize_matrix(p_rec_product, p_temp_ware_code, p_temp_cust_code,p_temp_mode) 
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE p_temp_ware_code LIKE warehouse.ware_code
	DEFINE p_temp_cust_code LIKE customer.cust_code
	DEFINE p_temp_mode char(1)
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.*
	DEFINE l_rec_prodstructure2 RECORD LIKE prodstructure.*
	DEFINE l_rec_prodflex RECORD LIKE prodflex.*
	--DEFINE l_tracker SMALLINT
--	DEFINE l_htracker SMALLINT 
--	DEFINE l_vtracker SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_idx2 SMALLINT 
--	DEFINE l_idx3 SMALLINT 

	DELETE FROM t_matrix 
	WHERE 1=1 
	LET modu_ware_code = p_temp_ware_code 
	LET modu_cust_code = p_temp_cust_code 
	#LET glob_rec_kandoouser.cmpy_code = p_rec_product.cmpy_code #HuHo:2.12.2020 did comment this, as it can break the program when the product data are invalid i.e. no company code in product 
	LET modu_class_code = p_rec_product.class_code 
	LET modu_mode = p_temp_mode 
	IF modu_mode != "O" THEN 
		RETURN FALSE 
	END IF 
	
	IF modu_mode = "O" THEN 

		CALL db_opparms_get_rec(UI_OFF,"1") RETURNING glob_rec_opparms.*
		IF glob_rec_opparms.key_num IS NULL AND glob_rec_opparms.cmpy_code IS NULL THEN  
			CALL fgl_winmessage("Configuration Error - Operational Parameters missing (Program AZP)",kandoomsg2("E",5002,""),"ERROR") #5002 EO Parameters are NOT found #HuHo 2.12.2020: Was "OZP" which we haven't got and I changed it to "EZP"
			EXIT PROGRAM 
		END IF 

	END IF 

	LET modu_v_offset = 0 
	LET modu_h_offset = 0 
	LET modu_counter = 1 
	SELECT unique 1 FROM prodstructure 
	WHERE class_code = modu_class_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind in ("H","V") 
	IF status = NOTFOUND THEN 
		RETURN FALSE 
	END IF

# This may only work with a fix size static array	 
--	FOR l_idx = 1 TO 500 
--		INITIALIZE modu_arr_rec_matrix[l_idx].* TO NULL 
--		IF l_idx < 50 THEN 
--			LET modu_arr_rec_table[l_idx].order_qty = NULL 
--			LET modu_arr_rec_table[l_idx].array_num = 0 
--		END IF 
--		IF l_idx < 36 THEN 
--			INITIALIZE modu_arr_vertical[l_idx] TO NULL 
--			INITIALIZE modu_arr_horizontal[l_idx] TO NULL 
--		END IF 
--	END FOR 
	
	SELECT * INTO l_rec_prodstructure2.* FROM prodstructure 
	WHERE class_code = modu_class_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "V" 
	IF status = NOTFOUND THEN 
		LET modu_vertical_count = 0 
	ELSE 
		DECLARE c_prodflex cursor FOR 
		SELECT * FROM prodflex 
		WHERE start_num = l_rec_prodstructure2.start_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND class_code = modu_class_code 
		ORDER BY flex_code 
		LET l_idx = 0 

		FOREACH c_prodflex INTO l_rec_prodflex.* 
			LET l_idx = l_idx + 1 
			LET modu_arr_vertical[l_idx] = l_rec_prodflex.flex_code 
		END FOREACH 

		LET modu_vertical_count = l_idx 
	END IF
	 
	CALL build_template(p_rec_product.part_code) 
	LET l_idx = 0 
	LET l_idx2 = 0
	 
	SELECT * INTO l_rec_prodstructure.* FROM prodstructure 
	WHERE class_code = modu_class_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "H"
	 
	IF status = 0 THEN 
		DECLARE c2_prodflex cursor FOR 
		SELECT * FROM prodflex 
		WHERE start_num = l_rec_prodstructure.start_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND class_code = modu_class_code 
		ORDER BY flex_code 
		FOREACH c2_prodflex INTO l_rec_prodflex.* 
			LET l_idx = l_idx + 1 
			LET modu_arr_horizontal[l_idx] = l_rec_prodflex.flex_code 
			FOR i = 1 TO modu_vertical_count 
				LET l_idx2 = l_idx2 + 1 
				LET modu_arr_rec_matrix[l_idx2].part_code = modu_template 
				LET modu_arr_rec_matrix[l_idx2].part_code[modu_h_start,modu_h_end] = modu_arr_horizontal[l_idx] 
				LET modu_arr_rec_matrix[l_idx2].part_code[modu_v_start,modu_v_end] = modu_arr_vertical[i] 
				LET modu_arr_rec_matrix[l_idx2].order_qty = 0.0 
			END FOR 
			IF modu_vertical_count = 0 THEN 
				LET l_idx2 = l_idx2 + 1 
				LET modu_arr_rec_matrix[l_idx2].part_code = modu_template 
				LET modu_arr_rec_matrix[l_idx2].part_code[modu_h_start,modu_h_end] =	modu_arr_horizontal[l_idx] 
				LET modu_arr_rec_matrix[l_idx2].order_qty = 0.0 
			END IF 
		END FOREACH 
	END IF 
	IF modu_vertical_count = 0 THEN 
		IF l_idx = 0 THEN 
			RETURN FALSE 
		ELSE 
			LET modu_vertical_count = 1 
			LET modu_arr_vertical[1] = modu_parent_code 
		END IF 
	END IF
	 
	IF l_idx = 0 THEN 
		LET l_idx = 1 
		LET modu_arr_horizontal[l_idx] = modu_parent_code 
		FOR i = 1 TO modu_vertical_count 
			LET l_idx2 = l_idx2 + 1 
			LET modu_arr_rec_matrix[l_idx2].part_code = modu_template 
			LET modu_arr_rec_matrix[l_idx2].part_code[modu_v_start,modu_v_end] = modu_arr_vertical[i] 
			LET modu_arr_rec_matrix[l_idx2].order_qty = 0.0 
		END FOR 
	END IF 
	
	LET modu_horizontal_count = l_idx 
	LET modu_matrix_count = l_idx2
	 
	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION initialize_matrix(p_rec_product, p_temp_ware_code, p_temp_cust_code,p_temp_mode)
###########################################################################


###########################################################################
# FUNCTION initialize_matrix_quantity(p_part_code, 
#	p_order_qty, 
#	p_minmax_qty, 
#	p_line_num) 
#  
#
#
###########################################################################
FUNCTION initialize_matrix_quantity(p_part_code, 
	p_order_qty, 
	p_minmax_qty, 
	p_line_num) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_order_qty FLOAT 
	DEFINE p_minmax_qty FLOAT 
	DEFINE p_line_num SMALLINT 
	DEFINE l_idx SMALLINT 

	FOR l_idx = modu_counter TO modu_arr_rec_matrix.getSize() # was 500 
		IF modu_arr_rec_matrix[l_idx].part_code = p_part_code THEN 
			IF modu_arr_rec_matrix[l_idx].order_qty IS NULL THEN 
				LET modu_arr_rec_matrix[l_idx].order_qty = 0 
			END IF 
			LET modu_arr_rec_matrix[l_idx].order_qty = modu_arr_rec_matrix[l_idx].order_qty + p_order_qty 
			LET modu_arr_rec_matrix[l_idx].line_num = p_line_num 
			LET modu_arr_rec_matrix[l_idx].minmax_qty = p_minmax_qty 
			EXIT FOR 
		END IF 
	END FOR 

	LET modu_counter = modu_arr_rec_matrix.getSize()
--	IF l_idx <= 500 THEN 
--		LET modu_counter = l_idx 
--	ELSE 
--		LET modu_counter = 1 
--	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION initialize_matrix_quantity(p_part_code,
###########################################################################


###########################################################################
# FUNCTION display_matrix() 
#  
#
#
###########################################################################
FUNCTION display_matrix() 
	DEFINE l_mod SMALLINT
	DEFINE x SMALLINT
	DEFINE j SMALLINT
	DEFINE i SMALLINT
	DEFINE k SMALLINT
	DEFINE c SMALLINT
	DEFINE r SMALLINT	 
	DEFINE l_arr_h_heading array[7] OF char(15) 
	DEFINE l_arr_v_heading array[7] OF char(15) 

	FOR x = 1 TO 7 
		LET i = modu_h_offset + x 
		LET j = modu_v_offset + x 
		LET l_arr_h_heading[x] = modu_arr_horizontal[i] 
		LET l_arr_v_heading[x] = modu_arr_vertical[j] 
	END FOR 

	IF modu_arr_horizontal[i+1] IS NOT NULL THEN 
		LET modu_h_more = TRUE 
	ELSE 
		LET modu_h_more = FALSE 
	END IF 
	IF modu_arr_vertical[j+1] IS NOT NULL THEN 
		LET modu_v_more = TRUE 
	ELSE 
		LET modu_v_more = FALSE 
	END IF 
	DISPLAY l_arr_h_heading[1], 
	l_arr_h_heading[2], 
	l_arr_h_heading[3], 
	l_arr_h_heading[4], 
	l_arr_h_heading[5], 
	l_arr_h_heading[6], 
	l_arr_h_heading[7], 
	l_arr_v_heading[1], 
	l_arr_v_heading[2], 
	l_arr_v_heading[3], 
	l_arr_v_heading[4], 
	l_arr_v_heading[5], 
	l_arr_v_heading[6], 
	l_arr_v_heading[7] 
	TO horizontal1, 
	horizontal2, 
	horizontal3, 
	horizontal4, 
	horizontal5, 
	horizontal6, 
	horizontal7, 
	vertical1, 
	vertical2, 
	vertical3, 
	vertical4, 
	vertical5, 
	vertical6, 
	vertical7 
	attribute(white) 

	FOR x = 1 TO 49 
		LET c = (x - 1) mod 7 
		IF c >= modu_horizontal_count THEN 
			CONTINUE FOR 
		END IF 
		LET r = ((x - c - 1) / 7) + 1 
		IF r > modu_vertical_count THEN 
			CONTINUE FOR 
		END IF 
		LET k = modu_v_offset + r + ((modu_h_offset + c) * modu_vertical_count) 
		IF modu_arr_rec_matrix[k].part_code IS NULL THEN 
			LET modu_arr_rec_table[x].order_qty = NULL 
			LET modu_arr_rec_table[x].array_num = 0 
		ELSE 
			LET modu_arr_rec_table[x].order_qty = modu_arr_rec_matrix[k].order_qty 
			LET modu_arr_rec_table[x].array_num = k 
		END IF 
	END FOR 

	DISPLAY modu_arr_rec_table[1].order_qty, 
	modu_arr_rec_table[2].order_qty, 
	modu_arr_rec_table[3].order_qty, 
	modu_arr_rec_table[4].order_qty, 
	modu_arr_rec_table[5].order_qty, 
	modu_arr_rec_table[6].order_qty, 
	modu_arr_rec_table[7].order_qty, 
	modu_arr_rec_table[8].order_qty, 
	modu_arr_rec_table[9].order_qty, 
	modu_arr_rec_table[10].order_qty, 
	modu_arr_rec_table[11].order_qty, 
	modu_arr_rec_table[12].order_qty, 
	modu_arr_rec_table[13].order_qty, 
	modu_arr_rec_table[14].order_qty, 
	modu_arr_rec_table[15].order_qty, 
	modu_arr_rec_table[16].order_qty, 
	modu_arr_rec_table[17].order_qty, 
	modu_arr_rec_table[18].order_qty, 
	modu_arr_rec_table[19].order_qty, 
	modu_arr_rec_table[20].order_qty, 
	modu_arr_rec_table[21].order_qty, 
	modu_arr_rec_table[22].order_qty, 
	modu_arr_rec_table[23].order_qty, 
	modu_arr_rec_table[24].order_qty, 
	modu_arr_rec_table[25].order_qty, 
	modu_arr_rec_table[26].order_qty, 
	modu_arr_rec_table[27].order_qty, 
	modu_arr_rec_table[28].order_qty, 
	modu_arr_rec_table[29].order_qty, 
	modu_arr_rec_table[30].order_qty, 
	modu_arr_rec_table[31].order_qty, 
	modu_arr_rec_table[32].order_qty, 
	modu_arr_rec_table[33].order_qty, 
	modu_arr_rec_table[34].order_qty, 
	modu_arr_rec_table[35].order_qty, 
	modu_arr_rec_table[36].order_qty, 
	modu_arr_rec_table[37].order_qty, 
	modu_arr_rec_table[38].order_qty, 
	modu_arr_rec_table[39].order_qty, 
	modu_arr_rec_table[40].order_qty, 
	modu_arr_rec_table[41].order_qty, 
	modu_arr_rec_table[42].order_qty, 
	modu_arr_rec_table[43].order_qty, 
	modu_arr_rec_table[44].order_qty, 
	modu_arr_rec_table[45].order_qty, 
	modu_arr_rec_table[46].order_qty, 
	modu_arr_rec_table[47].order_qty, 
	modu_arr_rec_table[48].order_qty, 
	modu_arr_rec_table[49].order_qty 
	TO matrix1, 
	matrix2, 
	matrix3, 
	matrix4, 
	matrix5, 
	matrix6, 
	matrix7, 
	matrix8, 
	matrix9, 
	matrix10, 
	matrix11, 
	matrix12, 
	matrix13, 
	matrix14, 
	matrix15, 
	matrix16, 
	matrix17, 
	matrix18, 
	matrix19, 
	matrix20, 
	matrix21, 
	matrix22, 
	matrix23, 
	matrix24, 
	matrix25, 
	matrix26, 
	matrix27, 
	matrix28, 
	matrix29, 
	matrix30, 
	matrix31, 
	matrix32, 
	matrix33, 
	matrix34, 
	matrix35, 
	matrix36, 
	matrix37, 
	matrix38, 
	matrix39, 
	matrix40, 
	matrix41, 
	matrix42, 
	matrix43, 
	matrix44, 
	matrix45, 
	matrix46, 
	matrix47, 
	matrix48, 
	matrix49 

END FUNCTION 
###########################################################################
# END FUNCTION display_matrix()
###########################################################################


###  WARNING : The FUNCTION matix_entry IS AT critical mass
###  AND cannot accept any more code. Place any new code in another FUNCTION
###  OR you will get error -4451 : Pcode generated exceeds 32K FUNCTION limit


###########################################################################
# FUNCTION matrix_entry()  
#  
#
#
###########################################################################
FUNCTION matrix_entry() 
	DEFINE l_curr_arr SMALLINT 
--	DEFINE l_i SMALLINT 
--	DEFINE l_j SMALLINT 

	OPEN WINDOW E459 with FORM "E459" 
	 CALL windecoration_e("E459") -- albo kd-755 

	WHILE TRUE 
		CALL display_matrix() 
		LET modu_loop = FALSE 

		MESSAGE kandoomsg2("E",1184,"") #1184 Enter Order Quantities; F9 TO Page Down; F10 TO Page Up.

		INPUT modu_arr_rec_table[1].order_qty, 
		modu_arr_rec_table[2].order_qty, 
		modu_arr_rec_table[3].order_qty, 
		modu_arr_rec_table[4].order_qty, 
		modu_arr_rec_table[5].order_qty, 
		modu_arr_rec_table[6].order_qty, 
		modu_arr_rec_table[7].order_qty, 
		modu_arr_rec_table[8].order_qty, 
		modu_arr_rec_table[9].order_qty, 
		modu_arr_rec_table[10].order_qty, 
		modu_arr_rec_table[11].order_qty, 
		modu_arr_rec_table[12].order_qty, 
		modu_arr_rec_table[13].order_qty, 
		modu_arr_rec_table[14].order_qty, 
		modu_arr_rec_table[15].order_qty, 
		modu_arr_rec_table[16].order_qty, 
		modu_arr_rec_table[17].order_qty, 
		modu_arr_rec_table[18].order_qty, 
		modu_arr_rec_table[19].order_qty, 
		modu_arr_rec_table[20].order_qty, 
		modu_arr_rec_table[21].order_qty, 
		modu_arr_rec_table[22].order_qty, 
		modu_arr_rec_table[23].order_qty, 
		modu_arr_rec_table[24].order_qty, 
		modu_arr_rec_table[25].order_qty, 
		modu_arr_rec_table[26].order_qty, 
		modu_arr_rec_table[27].order_qty, 
		modu_arr_rec_table[28].order_qty, 
		modu_arr_rec_table[29].order_qty, 
		modu_arr_rec_table[30].order_qty, 
		modu_arr_rec_table[31].order_qty, 
		modu_arr_rec_table[32].order_qty, 
		modu_arr_rec_table[33].order_qty, 
		modu_arr_rec_table[34].order_qty, 
		modu_arr_rec_table[35].order_qty, 
		modu_arr_rec_table[36].order_qty, 
		modu_arr_rec_table[37].order_qty, 
		modu_arr_rec_table[38].order_qty, 
		modu_arr_rec_table[39].order_qty, 
		modu_arr_rec_table[40].order_qty, 
		modu_arr_rec_table[41].order_qty, 
		modu_arr_rec_table[42].order_qty, 
		modu_arr_rec_table[43].order_qty, 
		modu_arr_rec_table[44].order_qty, 
		modu_arr_rec_table[45].order_qty, 
		modu_arr_rec_table[46].order_qty, 
		modu_arr_rec_table[47].order_qty, 
		modu_arr_rec_table[48].order_qty, 
		modu_arr_rec_table[49].order_qty WITHOUT DEFAULTS 
		FROM matrix1, 
		matrix2, 
		matrix3, 
		matrix4, 
		matrix5, 
		matrix6, 
		matrix7, 
		matrix8, 
		matrix9, 
		matrix10, 
		matrix11, 
		matrix12, 
		matrix13, 
		matrix14, 
		matrix15, 
		matrix16, 
		matrix17, 
		matrix18, 
		matrix19, 
		matrix20, 
		matrix21, 
		matrix22, 
		matrix23, 
		matrix24, 
		matrix25, 
		matrix26, 
		matrix27, 
		matrix28, 
		matrix29, 
		matrix30, 
		matrix31, 
		matrix32, 
		matrix33, 
		matrix34, 
		matrix35, 
		matrix36, 
		matrix37, 
		matrix38, 
		matrix39, 
		matrix40, 
		matrix41, 
		matrix42, 
		matrix43, 
		matrix44, 
		matrix45, 
		matrix46, 
		matrix47, 
		matrix48, 
		matrix49 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E11j","input-modu_arr_rec_table-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (f3) 
				#Go Forward One Row
				IF function_key("F3") THEN 
					EXIT INPUT 
				END IF 

			ON KEY (f4) 
				#Go Back One Row
				IF function_key("F4") THEN 
					EXIT INPUT 
				END IF 

			ON KEY (f19) 
				#Go Back One Column
				IF function_key("F19") THEN 
					EXIT INPUT 
				END IF 

			ON KEY (f21) 
				#Go Forward One Column
				IF function_key("F21") THEN 
					EXIT INPUT 
				END IF 

			ON KEY (f18) 
				#Go Back One Page
				IF function_key("F18") THEN 
					EXIT INPUT 
				END IF 

			ON KEY (f22) 
				#Go Forward One Page
				IF function_key("F22") THEN 
					EXIT INPUT 
				END IF 

			BEFORE FIELD matrix1 
				IF modu_arr_rec_table[1].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix43 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD matrix7 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix8 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[1].array_num) 

			AFTER FIELD matrix1 
				IF NOT check_num(modu_arr_rec_table[1].order_qty) THEN 
					NEXT FIELD matrix1 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[1].array_num 
				IF NOT validate_cell(1) THEN 
					LET modu_arr_rec_table[1].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[1].order_qty 
					TO matrix1 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[1].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix43 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD matrix7 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix8 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix2 
				IF modu_arr_rec_table[2].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix44 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix9 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[2].array_num) 

			AFTER FIELD matrix2 
				IF NOT check_num(modu_arr_rec_table[2].order_qty) THEN 
					NEXT FIELD matrix2 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[2].array_num 
				IF NOT validate_cell(2) THEN 
					LET modu_arr_rec_table[2].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[2].order_qty 
					TO matrix2 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[2].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix44 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix9 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix3 
				IF modu_arr_rec_table[3].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix45 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix10 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[3].array_num) 

			AFTER FIELD matrix3 
				IF NOT check_num(modu_arr_rec_table[3].order_qty) THEN 
					NEXT FIELD matrix3 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[3].array_num 
				IF NOT validate_cell(3) THEN 
					LET modu_arr_rec_table[3].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[3].order_qty 
					TO matrix3 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[3].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix45 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix10 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix4 
				IF modu_arr_rec_table[4].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix46 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix11 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[4].array_num) 

			AFTER FIELD matrix4 
				IF NOT check_num(modu_arr_rec_table[4].order_qty) THEN 
					NEXT FIELD matrix4 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[4].array_num 
				IF NOT validate_cell(4) THEN 
					LET modu_arr_rec_table[4].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[4].order_qty 
					TO matrix4 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[4].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix46 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix11 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix5 
				IF modu_arr_rec_table[5].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix47 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix12 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[5].array_num) 

			AFTER FIELD matrix5 
				IF NOT check_num(modu_arr_rec_table[5].order_qty) THEN 
					NEXT FIELD matrix5 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[5].array_num 
				IF NOT validate_cell(5) THEN 
					LET modu_arr_rec_table[5].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[5].order_qty 
					TO matrix5 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[5].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix47 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix12 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix6 
				IF modu_arr_rec_table[6].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix48 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix13 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[6].array_num) 
				
			AFTER FIELD matrix6 
				IF NOT check_num(modu_arr_rec_table[6].order_qty) THEN 
					NEXT FIELD matrix6 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[6].array_num 
				IF NOT validate_cell(6) THEN 
					LET modu_arr_rec_table[6].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[6].order_qty 
					TO matrix6 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[6].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix48 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix13 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
				
			BEFORE FIELD matrix7 
				IF modu_arr_rec_table[7].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix49 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix14 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD matrix1 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[7].array_num) 
				
			AFTER FIELD matrix7 
				IF NOT check_num(modu_arr_rec_table[7].order_qty) THEN 
					NEXT FIELD matrix7 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[7].array_num 
				IF NOT validate_cell(7) THEN 
					LET modu_arr_rec_table[7].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[7].order_qty 
					TO matrix7 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[7].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix49 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix14 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD matrix1 
						END IF 
				END CASE 
				
			BEFORE FIELD matrix8 
				IF modu_arr_rec_table[8].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix1 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD matrix14 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix15 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[8].array_num) 
				
			AFTER FIELD matrix8 
				IF NOT check_num(modu_arr_rec_table[8].order_qty) THEN 
					NEXT FIELD matrix8 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[8].array_num 
				IF NOT validate_cell(8) THEN 
					LET modu_arr_rec_table[8].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[8].order_qty 
					TO matrix8 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[8].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix1 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD matrix14 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix15 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
				
			BEFORE FIELD matrix9 
				IF modu_arr_rec_table[9].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix2 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix16 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[9].array_num) 
				
			AFTER FIELD matrix9 
				IF NOT check_num(modu_arr_rec_table[9].order_qty) THEN 
					NEXT FIELD matrix9 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[9].array_num 
				IF NOT validate_cell(9) THEN 
					LET modu_arr_rec_table[9].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[9].order_qty 
					TO matrix9 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[9].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix2 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix16 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
				
			BEFORE FIELD matrix10 
				IF modu_arr_rec_table[10].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix3 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix17 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[10].array_num) 
				
			AFTER FIELD matrix10 
				IF NOT check_num(modu_arr_rec_table[10].order_qty) THEN 
					NEXT FIELD matrix10 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[10].array_num 
				IF NOT validate_cell(10) THEN 
					LET modu_arr_rec_table[10].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[10].order_qty 
					TO matrix10 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[10].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix3 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix17 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
				
			BEFORE FIELD matrix11 
				IF modu_arr_rec_table[11].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix4 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix18 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[11].array_num) 
				
			AFTER FIELD matrix11 
				IF NOT check_num(modu_arr_rec_table[11].order_qty) THEN 
					NEXT FIELD matrix11 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[11].array_num 
				IF NOT validate_cell(11) THEN 
					LET modu_arr_rec_table[11].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[11].order_qty 
					TO matrix11 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[11].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix4 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix18 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
				
			BEFORE FIELD matrix12 
				IF modu_arr_rec_table[12].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix5 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix19 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[12].array_num) 
				
			AFTER FIELD matrix12 
				IF NOT check_num(modu_arr_rec_table[12].order_qty) THEN 
					NEXT FIELD matrix12 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[12].array_num 
				IF NOT validate_cell(12) THEN 
					LET modu_arr_rec_table[12].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[12].order_qty 
					TO matrix12 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[12].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix5 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix19 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
				
			BEFORE FIELD matrix13 
				IF modu_arr_rec_table[13].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix6 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix20 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[13].array_num) 
				
			AFTER FIELD matrix13 
				IF NOT check_num(modu_arr_rec_table[13].order_qty) THEN 
					NEXT FIELD matrix13 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[13].array_num 
				IF NOT validate_cell(13) THEN 
					LET modu_arr_rec_table[13].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[13].order_qty 
					TO matrix13 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[13].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix6 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix20 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
				
			BEFORE FIELD matrix14 
				IF modu_arr_rec_table[14].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix7 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix21 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD matrix8 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[14].array_num) 
			AFTER FIELD matrix14 
				IF NOT check_num(modu_arr_rec_table[14].order_qty) THEN 
					NEXT FIELD matrix14 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[14].array_num 
				IF NOT validate_cell(14) THEN 
					LET modu_arr_rec_table[14].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[14].order_qty 
					TO matrix14 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[14].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix7 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix21 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD matrix8 
						END IF 
				END CASE 
				
			BEFORE FIELD matrix15 
				IF modu_arr_rec_table[15].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix8 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD matrix21 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix22 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[15].array_num) 
				
			AFTER FIELD matrix15 
				IF NOT check_num(modu_arr_rec_table[15].order_qty) THEN 
					NEXT FIELD matrix15 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[15].array_num 
				IF NOT validate_cell(15) THEN 
					LET modu_arr_rec_table[15].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[15].order_qty 
					TO matrix15 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[15].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix8 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD matrix21 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix22 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix16 
				IF modu_arr_rec_table[16].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix9 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix23 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[16].array_num) 

			AFTER FIELD matrix16 
				IF NOT check_num(modu_arr_rec_table[16].order_qty) THEN 
					NEXT FIELD matrix16 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[16].array_num 
				IF NOT validate_cell(16) THEN 
					LET modu_arr_rec_table[16].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[16].order_qty 
					TO matrix16 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[16].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix9 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix23 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix17 
				IF modu_arr_rec_table[17].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix10 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix24 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[17].array_num) 

			AFTER FIELD matrix17 
				IF NOT check_num(modu_arr_rec_table[17].order_qty) THEN 
					NEXT FIELD matrix17 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[17].array_num 
				IF NOT validate_cell(17) THEN 
					LET modu_arr_rec_table[17].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[17].order_qty 
					TO matrix17 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[17].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix10 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix24 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix18 
				IF modu_arr_rec_table[18].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix11 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix25 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[18].array_num) 
			AFTER FIELD matrix18 
				IF NOT check_num(modu_arr_rec_table[18].order_qty) THEN 
					NEXT FIELD matrix18 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[18].array_num 
				IF NOT validate_cell(18) THEN 
					LET modu_arr_rec_table[18].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[18].order_qty 
					TO matrix18 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[18].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix11 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix25 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
			BEFORE FIELD matrix19 
				IF modu_arr_rec_table[19].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix12 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix26 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[19].array_num) 

			AFTER FIELD matrix19 
				IF NOT check_num(modu_arr_rec_table[19].order_qty) THEN 
					NEXT FIELD matrix19 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[19].array_num 
				IF NOT validate_cell(19) THEN 
					LET modu_arr_rec_table[19].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[19].order_qty 
					TO matrix19 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[19].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix12 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix26 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix20 
				IF modu_arr_rec_table[20].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix13 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix27 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[20].array_num) 

			AFTER FIELD matrix20 
				IF NOT check_num(modu_arr_rec_table[20].order_qty) THEN 
					NEXT FIELD matrix20 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[20].array_num 
				IF NOT validate_cell(20) THEN 
					LET modu_arr_rec_table[20].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[20].order_qty 
					TO matrix20 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[20].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix13 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix27 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix21 
				IF modu_arr_rec_table[21].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix14 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix28 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD matrix15 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[21].array_num) 
			AFTER FIELD matrix21 
				IF NOT check_num(modu_arr_rec_table[21].order_qty) THEN 
					NEXT FIELD matrix21 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[21].array_num 
				IF NOT validate_cell(21) THEN 
					LET modu_arr_rec_table[21].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[21].order_qty 
					TO matrix21 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[21].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix14 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix28 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD matrix15 
						END IF 
				END CASE 

			BEFORE FIELD matrix22 
				IF modu_arr_rec_table[22].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix15 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD matrix28 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix29 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[22].array_num) 

			AFTER FIELD matrix22 
				IF NOT check_num(modu_arr_rec_table[22].order_qty) THEN 
					NEXT FIELD matrix22 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[22].array_num 
				IF NOT validate_cell(22) THEN 
					LET modu_arr_rec_table[22].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[22].order_qty 
					TO matrix22 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[22].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix15 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD matrix28 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix29 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix23 
				IF modu_arr_rec_table[23].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix16 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix30 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[23].array_num) 

			AFTER FIELD matrix23 
				IF NOT check_num(modu_arr_rec_table[23].order_qty) THEN 
					NEXT FIELD matrix23 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[23].array_num 
				IF NOT validate_cell(23) THEN 
					LET modu_arr_rec_table[23].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[23].order_qty 
					TO matrix23 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[23].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix16 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix30 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix24 
				IF modu_arr_rec_table[24].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix17 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix31 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[24].array_num) 

			AFTER FIELD matrix24 
				IF NOT check_num(modu_arr_rec_table[24].order_qty) THEN 
					NEXT FIELD matrix24 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[24].array_num 
				IF NOT validate_cell(24) THEN 
					LET modu_arr_rec_table[24].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[24].order_qty 
					TO matrix24 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[24].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix17 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix31 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix25 
				IF modu_arr_rec_table[25].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix18 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix32 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[25].array_num) 

			AFTER FIELD matrix25 
				IF NOT check_num(modu_arr_rec_table[25].order_qty) THEN 
					NEXT FIELD matrix25 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[25].array_num 
				IF NOT validate_cell(25) THEN 
					LET modu_arr_rec_table[25].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[25].order_qty 
					TO matrix25 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[25].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix18 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix32 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix26 
				IF modu_arr_rec_table[26].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix19 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix33 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[26].array_num) 

			AFTER FIELD matrix26 
				IF NOT check_num(modu_arr_rec_table[26].order_qty) THEN 
					NEXT FIELD matrix26 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[26].array_num 
				IF NOT validate_cell(26) THEN 
					LET modu_arr_rec_table[26].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[26].order_qty 
					TO matrix26 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[26].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix19 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix33 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix27 
				IF modu_arr_rec_table[27].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix20 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix34 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[27].array_num) 

			AFTER FIELD matrix27 
				IF NOT check_num(modu_arr_rec_table[27].order_qty) THEN 
					NEXT FIELD matrix27 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[27].array_num 
				IF NOT validate_cell(27) THEN 
					LET modu_arr_rec_table[27].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[27].order_qty 
					TO matrix27 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[27].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix20 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix34 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix28 
				IF modu_arr_rec_table[28].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix21 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix35 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD matrix22 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[28].array_num) 

			AFTER FIELD matrix28 
				IF NOT check_num(modu_arr_rec_table[28].order_qty) THEN 
					NEXT FIELD matrix28 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[28].array_num 
				IF NOT validate_cell(28) THEN 
					LET modu_arr_rec_table[28].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[28].order_qty 
					TO matrix28 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[28].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix21 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix35 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD matrix22 
						END IF 
				END CASE 

			BEFORE FIELD matrix29 
				IF modu_arr_rec_table[29].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix22 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD matrix35 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix36 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[29].array_num) 

			AFTER FIELD matrix29 
				IF NOT check_num(modu_arr_rec_table[29].order_qty) THEN 
					NEXT FIELD matrix29 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[29].array_num 
				IF NOT validate_cell(29) THEN 
					LET modu_arr_rec_table[29].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[29].order_qty 
					TO matrix29 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[29].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix22 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD matrix35 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix36 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix30 
				IF modu_arr_rec_table[30].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix23 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix37 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[30].array_num) 

			AFTER FIELD matrix30 
				IF NOT check_num(modu_arr_rec_table[30].order_qty) THEN 
					NEXT FIELD matrix30 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[30].array_num 
				IF NOT validate_cell(30) THEN 
					LET modu_arr_rec_table[30].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[30].order_qty 
					TO matrix30 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[30].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix23 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix37 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix31 
				IF modu_arr_rec_table[31].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix24 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix38 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[31].array_num) 

			AFTER FIELD matrix31 
				IF NOT check_num(modu_arr_rec_table[31].order_qty) THEN 
					NEXT FIELD matrix31 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[31].array_num 
				IF NOT validate_cell(31) THEN 
					LET modu_arr_rec_table[31].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[31].order_qty 
					TO matrix31 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[31].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix24 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix38 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix32 
				IF modu_arr_rec_table[32].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix25 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix39 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[32].array_num) 

			AFTER FIELD matrix32 
				IF NOT check_num(modu_arr_rec_table[32].order_qty) THEN 
					NEXT FIELD matrix32 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[32].array_num 
				IF NOT validate_cell(32) THEN 
					LET modu_arr_rec_table[32].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[32].order_qty 
					TO matrix32 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[32].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix25 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix39 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix33 
				IF modu_arr_rec_table[33].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix26 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix40 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[33].array_num) 

			AFTER FIELD matrix33 
				IF NOT check_num(modu_arr_rec_table[33].order_qty) THEN 
					NEXT FIELD matrix33 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[33].array_num 
				IF NOT validate_cell(33) THEN 
					LET modu_arr_rec_table[33].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[33].order_qty 
					TO matrix33 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[33].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix26 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix40 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix34 
				IF modu_arr_rec_table[34].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix27 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix41 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[34].array_num) 
			AFTER FIELD matrix34 
				IF NOT check_num(modu_arr_rec_table[34].order_qty) THEN 
					NEXT FIELD matrix34 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[34].array_num 
				IF NOT validate_cell(34) THEN 
					LET modu_arr_rec_table[34].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[34].order_qty 
					TO matrix34 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[34].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix27 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix41 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix35 
				IF modu_arr_rec_table[35].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix28 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix42 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD matrix29 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[35].array_num) 
			AFTER FIELD matrix35 
				IF NOT check_num(modu_arr_rec_table[35].order_qty) THEN 
					NEXT FIELD matrix35 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[35].array_num 
				IF NOT validate_cell(35) THEN 
					LET modu_arr_rec_table[35].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[35].order_qty 
					TO matrix35 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[35].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix28 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix42 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD matrix29 
						END IF 
				END CASE 

			BEFORE FIELD matrix36 
				IF modu_arr_rec_table[36].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix29 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD matrix42 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix43 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[36].array_num) 

			AFTER FIELD matrix36 
				IF NOT check_num(modu_arr_rec_table[36].order_qty) THEN 
					NEXT FIELD matrix36 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[36].array_num 
				IF NOT validate_cell(36) THEN 
					LET modu_arr_rec_table[36].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					LET modu_arr_rec_table[36].order_qty = "0.00" 
					DISPLAY modu_arr_rec_table[36].order_qty 
					TO matrix36 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[36].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix29 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD matrix42 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix43 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
			BEFORE FIELD matrix37 
				IF modu_arr_rec_table[37].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix30 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix44 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[37].array_num) 
			AFTER FIELD matrix37 
				IF NOT check_num(modu_arr_rec_table[37].order_qty) THEN 
					NEXT FIELD matrix37 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[37].array_num 
				IF NOT validate_cell(37) THEN 
					LET modu_arr_rec_table[37].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[37].order_qty 
					TO matrix37 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[37].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix30 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix44 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
			BEFORE FIELD matrix38 
				IF modu_arr_rec_table[38].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix31 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix45 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[38].array_num) 
			AFTER FIELD matrix38 
				IF NOT check_num(modu_arr_rec_table[38].order_qty) THEN 
					NEXT FIELD matrix38 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[38].array_num 
				IF NOT validate_cell(38) THEN 
					LET modu_arr_rec_table[38].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[38].order_qty 
					TO matrix38 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[38].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix31 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix45 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
			BEFORE FIELD matrix39 
				IF modu_arr_rec_table[39].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix32 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix46 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[39].array_num) 
			AFTER FIELD matrix39 
				IF NOT check_num(modu_arr_rec_table[39].order_qty) THEN 
					NEXT FIELD matrix39 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[39].array_num 
				IF NOT validate_cell(39) THEN 
					LET modu_arr_rec_table[39].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[39].order_qty 
					TO matrix39 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[39].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix32 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix46 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix40 
				IF modu_arr_rec_table[40].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix33 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix47 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[40].array_num) 
			AFTER FIELD matrix40 
				IF NOT check_num(modu_arr_rec_table[40].order_qty) THEN 
					NEXT FIELD matrix40 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[40].array_num 
				IF NOT validate_cell(40) THEN 
					LET modu_arr_rec_table[40].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[40].order_qty 
					TO matrix40 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[40].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix33 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix47 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
			BEFORE FIELD matrix41 
				IF modu_arr_rec_table[41].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix34 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix48 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[41].array_num) 
			AFTER FIELD matrix41 
				IF NOT check_num(modu_arr_rec_table[41].order_qty) THEN 
					NEXT FIELD matrix41 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[41].array_num 
				IF NOT validate_cell(41) THEN 
					LET modu_arr_rec_table[41].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[41].order_qty 
					TO matrix41 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[41].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix34 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix48 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
			BEFORE FIELD matrix42 
				IF modu_arr_rec_table[42].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix35 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix49 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD matrix36 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[42].array_num) 

			AFTER FIELD matrix42 
				IF NOT check_num(modu_arr_rec_table[42].order_qty) THEN 
					NEXT FIELD matrix42 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[42].array_num 
				IF NOT validate_cell(42) THEN 
					LET modu_arr_rec_table[42].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[42].order_qty 
					TO matrix42 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[42].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix35 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix49 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD matrix36 
						END IF 
				END CASE 

			BEFORE FIELD matrix43 
				IF modu_arr_rec_table[43].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix36 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD matrix49 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix1 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[43].array_num) 

			AFTER FIELD matrix43 
				IF NOT check_num(modu_arr_rec_table[43].order_qty) THEN 
					NEXT FIELD matrix43 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[43].array_num 
				IF NOT validate_cell(43) THEN 
					LET modu_arr_rec_table[43].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[43].order_qty 
					TO matrix43 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[43].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix36 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD matrix49 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix1 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix44 
				IF modu_arr_rec_table[44].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix37 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix2 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[44].array_num) 

			AFTER FIELD matrix44 
				IF NOT check_num(modu_arr_rec_table[44].order_qty) THEN 
					NEXT FIELD matrix44 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[44].array_num 
				IF NOT validate_cell(44) THEN 
					LET modu_arr_rec_table[44].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[44].order_qty 
					TO matrix44 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[44].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix37 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix2 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix45 
				IF modu_arr_rec_table[45].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix38 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix3 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[45].array_num) 
			AFTER FIELD matrix45 
				IF NOT check_num(modu_arr_rec_table[45].order_qty) THEN 
					NEXT FIELD matrix45 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[45].array_num 
				IF NOT validate_cell(45) THEN 
					LET modu_arr_rec_table[45].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[45].order_qty 
					TO matrix45 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[45].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix38 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix3 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 

			BEFORE FIELD matrix46 
				IF modu_arr_rec_table[46].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix39 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix4 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[46].array_num) 
			AFTER FIELD matrix46 
				IF NOT check_num(modu_arr_rec_table[46].order_qty) THEN 
					NEXT FIELD matrix46 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[46].array_num 
				IF NOT validate_cell(46) THEN 
					LET modu_arr_rec_table[46].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[46].order_qty 
					TO matrix46 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[46].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix39 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix4 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
			BEFORE FIELD matrix47 
				IF modu_arr_rec_table[47].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix40 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix5 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[47].array_num) 
			AFTER FIELD matrix47 
				IF NOT check_num(modu_arr_rec_table[47].order_qty) THEN 
					NEXT FIELD matrix47 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[47].array_num 
				IF NOT validate_cell(47) THEN 
					LET modu_arr_rec_table[47].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[47].order_qty 
					TO matrix47 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[47].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix40 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix5 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
			BEFORE FIELD matrix48 
				IF modu_arr_rec_table[48].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix41 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix6 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD NEXT 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[48].array_num) 
			AFTER FIELD matrix48 
				IF NOT check_num(modu_arr_rec_table[48].order_qty) THEN 
					NEXT FIELD matrix48 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[48].array_num 
				IF NOT validate_cell(48) THEN 
					LET modu_arr_rec_table[48].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[48].order_qty 
					TO matrix48 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[48].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix41 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix6 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD NEXT 
						END IF 
				END CASE 
			BEFORE FIELD matrix49 
				IF modu_arr_rec_table[49].array_num = 0 THEN 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("up") 
							NEXT FIELD matrix42 
						WHEN fgl_lastkey() = fgl_keyval("left") 
							NEXT FIELD previous 
						WHEN fgl_lastkey() = fgl_keyval("down") 
							NEXT FIELD matrix7 
						OTHERWISE 
							IF fgl_lastkey() = 4001 THEN 
								NEXT FIELD matrix1 
							END IF 
							NEXT FIELD matrix43 
					END CASE 
				END IF 
				CALL display_cell_details(modu_arr_rec_table[49].array_num) 
			AFTER FIELD matrix49 
				IF NOT check_num(modu_arr_rec_table[49].order_qty) THEN 
					NEXT FIELD matrix49 
				END IF 
				LET l_curr_arr = modu_arr_rec_table[49].array_num 
				IF NOT validate_cell(49) THEN 
					LET modu_arr_rec_table[49].order_qty = modu_arr_rec_matrix[l_curr_arr].order_qty 
					DISPLAY modu_arr_rec_table[49].order_qty 
					TO matrix49 

				ELSE 
					LET modu_arr_rec_matrix[l_curr_arr].order_qty = modu_arr_rec_table[49].order_qty 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD matrix42 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD matrix7 
					WHEN fgl_lastkey() != 4001 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD matrix43 
						END IF 
				END CASE 
				--- modif ericv init # AFTER INPUT
				#--#   CALL dialog.fieldorder(TRUE)
				#@huho replaced FUNCTION CALL (OLD legacy BDS FUNCTION)
				--#      CALL fgl_dialog_fieldorder(TRUE)

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF modu_loop THEN 
			CONTINUE WHILE 
		END IF 
		EXIT WHILE 
	END WHILE 

	CLOSE WINDOW E459 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	CALL fill_t_matrix() 
	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION matrix_entry()
###########################################################################


###########################################################################
# FUNCTION function_key(p_key)
#  
#
#
###########################################################################
FUNCTION function_key(p_key) 
	DEFINE p_key char(3) 

	CASE p_key 
		WHEN "F3" 
			#Go Forward One Row
			IF modu_v_more THEN 
				LET modu_v_offset = modu_v_offset + 1 
				LET modu_loop = TRUE 
				RETURN TRUE 
			ELSE 
				ERROR kandoomsg2("U",9001,"") 				#9001 No more rows in that direction
				RETURN FALSE 
			END IF 
		WHEN "F4" 
			#Go Back One Row
			IF modu_v_offset = 0 THEN 
				ERROR kandoomsg2("U",9001,"") 			#9001 No more rows in that direction
				RETURN FALSE 
			ELSE 
				LET modu_v_offset = modu_v_offset - 1 
				LET modu_loop = TRUE 
				RETURN TRUE 
			END IF 
		WHEN "F21" 
			#Go Forward One Column
			IF modu_h_more THEN 
				LET modu_h_offset = modu_h_offset + 1 
				LET modu_loop = TRUE 
				RETURN TRUE 
			ELSE 
				ERROR kandoomsg2("U",9001,"") 			#9001 No more rows in that direction
				RETURN FALSE 
			END IF 
		WHEN "F19" 
			#Go Back One Column
			IF modu_h_offset = 0 THEN 
				ERROR kandoomsg2("U",9001,"") 			#9001 No more rows in that direction
				RETURN FALSE 
			ELSE 
				LET modu_h_offset = modu_h_offset - 1 
				LET modu_loop = TRUE 
				RETURN TRUE 
			END IF 
		WHEN "F22" 
			#Go Forward One Page
			IF modu_h_more THEN 
				LET modu_h_offset = modu_h_offset + 7 
				LET modu_loop = TRUE 
				RETURN TRUE 
			ELSE 
				ERROR kandoomsg2("U",9001,"") 			#9001 No more rows in that direction
				RETURN FALSE 
			END IF 
		WHEN "F18" 
			#Go Back One Page
			IF modu_h_offset = 0 THEN 
				ERROR kandoomsg2("U",9001,"") 			#9001 No more rows in that direction
				RETURN FALSE 
			ELSE 
				LET modu_h_offset = modu_h_offset - 7 
				IF modu_h_offset < 0 THEN 
					LET modu_h_offset = 0 
				END IF 
				LET modu_loop = TRUE 
				RETURN TRUE 
			END IF 
		OTHERWISE 
			RETURN FALSE 
	END CASE 
END FUNCTION 
###########################################################################
# END FUNCTION function_key(p_key)
###########################################################################


###########################################################################
# FUNCTION fill_t_matrix()   
#  
#
#
###########################################################################
FUNCTION fill_t_matrix() 
	DEFINE i SMALLINT
	 
	FOR i = 1 TO modu_arr_rec_matrix.getSize() # was 500 
		IF modu_arr_rec_matrix[i].order_qty > 0 
		OR modu_arr_rec_matrix[i].line_num != 0 THEN 
			INSERT INTO t_matrix VALUES (modu_arr_rec_matrix[i].part_code, 
			modu_arr_rec_matrix[i].order_qty, 
			modu_arr_rec_matrix[i].minmax_qty, 
			modu_arr_rec_matrix[i].line_num) 
		END IF 
	END FOR 
END FUNCTION 

###########################################################################
# END FUNCTION fill_t_matrix()
###########################################################################


###########################################################################
# FUNCTION build_template(p_part_code)  
#  
#
#
###########################################################################
FUNCTION build_template(p_part_code) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_filler_part_code LIKE product.part_code 
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.* 
	DEFINE l_kandoo_length SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 

	LET l_filler_part_code = "XXXXXXXXXXXXXXX" 
	INITIALIZE modu_parent_code TO NULL 
	DECLARE c_prodstructure3 cursor FOR 
	SELECT * FROM prodstructure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND class_code = modu_class_code 
	ORDER BY seq_num 
	LET j = 0 
	LET modu_h_start = 0 
	LET modu_h_end = 0 
	LET modu_v_start = 0 
	LET modu_v_end = 0 
	
	FOREACH c_prodstructure3 INTO l_rec_prodstructure.* 
		CASE l_rec_prodstructure.type_ind 
			WHEN "F" 
				LET j = j + 1 
				LET modu_template[j] = l_rec_prodstructure.desc_text[1] 
			WHEN "S" 
				LET i = j + 1 
				LET j = j + l_rec_prodstructure.length 
				LET modu_template[i,j] = p_part_code 
				LET modu_parent_code[i,j] = p_part_code 
			WHEN "H" 
				LET i = j + 1 
				LET j = j + l_rec_prodstructure.length 
				LET modu_template[i,j] = l_filler_part_code[i,j] 
				LET modu_h_start = i 
				LET modu_h_end = j 
			WHEN "V" 
				LET i = j + 1 
				LET j = j + l_rec_prodstructure.length 
				LET modu_template[i,j] = l_filler_part_code[i,j] 
				LET modu_v_start = i 
				LET modu_v_end = j 
		END CASE 
	END FOREACH 

	LET l_kandoo_length = l_rec_prodstructure.start_num + l_rec_prodstructure.length 
	IF l_kandoo_length < 15 THEN 
		LET modu_template[l_kandoo_length,15] = " " 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION build_template(p_part_code)
###########################################################################


###########################################################################
# FUNCTION display_cell_details(l_curr_arr)   
#  
#
#
###########################################################################
FUNCTION display_cell_details(l_curr_arr) 
	DEFINE l_curr_arr SMALLINT 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_desc_text char(60) 
	DEFINE l_available_qty FLOAT 

	INITIALIZE l_rec_product.* TO NULL 
	SELECT * INTO l_rec_product.* FROM product 
	WHERE part_code = modu_arr_rec_matrix[l_curr_arr].part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_desc_text = "PRODUCT NOT found" 
		LET l_available_qty = NULL 
	ELSE 
		INITIALIZE l_rec_prodstatus.* TO NULL 
		SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
		WHERE part_code = modu_arr_rec_matrix[l_curr_arr].part_code 
		AND ware_code = modu_ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = NOTFOUND THEN 
			LET l_desc_text = "PRODUCT DOES NOT EXIST AT THIS warehouse" 
			LET l_available_qty = NULL 
		ELSE 
			IF glob_rec_opparms.cal_available_flag = "N" THEN  
				LET l_available_qty = l_rec_prodstatus.onhand_qty 
				- l_rec_prodstatus.reserved_qty 
				- l_rec_prodstatus.back_qty 
			ELSE 
				LET l_available_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty 
			END IF 
			LET l_desc_text = l_rec_product.desc_text clipped," ",	l_rec_product.desc2_text 
		END IF 
	END IF 

	DISPLAY BY NAME modu_arr_rec_matrix[l_curr_arr].part_code, 
	l_available_qty, 
	l_desc_text 

END FUNCTION 
###########################################################################
# END FUNCTION display_cell_details(l_curr_arr)
###########################################################################


###########################################################################
# FUNCTION check_num(p_char_num)  
#  
#
#
###########################################################################
FUNCTION check_num(p_char_num) 
	DEFINE p_char_num char(10) 
	DEFINE l_order_qty FLOAT 

	WHENEVER any ERROR CONTINUE 
	LET l_order_qty = p_char_num 
	IF status = 0 THEN 
		WHENEVER any ERROR stop 
		RETURN TRUE 
	ELSE 
		WHENEVER any ERROR stop 
		ERROR kandoomsg2("U",9049,"") 	#9049 Error in field.
		RETURN FALSE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION check_num(p_char_num)
###########################################################################


###########################################################################
# FUNCTION validate_cell(p_idx)   
#  
#
#
###########################################################################
FUNCTION validate_cell(p_idx) 
	DEFINE p_idx SMALLINT 
	DEFINE l_curr_arr SMALLINT 
	DEFINE l_rec_product RECORD LIKE product.*
--	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_order_qty FLOAT 

	LET l_curr_arr = modu_arr_rec_table[p_idx].array_num 
	LET l_order_qty = modu_arr_rec_table[p_idx].order_qty 
	IF l_order_qty != 0 
	OR (modu_arr_rec_matrix[l_curr_arr].line_num != 0 
	AND modu_arr_rec_matrix[l_curr_arr].line_num IS NOT null) THEN 
		#### Check FOR exclusions
		IF prod_exclude(glob_rec_kandoouser.cmpy_code,modu_arr_rec_matrix[l_curr_arr].part_code, 
		modu_cust_code, 
		modu_ware_code, 
		5, 
		today) THEN 
			ERROR kandoomsg2("E",9261,"") 		#9261" product can NOT be sold
			RETURN FALSE 
		END IF 
		IF prod_exclude(glob_rec_kandoouser.cmpy_code,modu_arr_rec_matrix[l_curr_arr].part_code, 
		modu_cust_code, 
		modu_ware_code, 
		6, 
		today) THEN 
			ERROR kandoomsg2("E",9261,"") 		#9261" product can NOT be sold
			RETURN FALSE 
		END IF 
		IF NOT valid_part(glob_rec_kandoouser.cmpy_code,modu_arr_rec_matrix[l_curr_arr].part_code, 
		modu_ware_code,1,2,1,"","","") THEN 
			RETURN FALSE 
		END IF 
		IF l_order_qty < 0 THEN 
			ERROR kandoomsg2("E",9180,"") 		#9180 Quantity may NOT be negative
			RETURN FALSE 
		END IF 
		IF l_order_qty < modu_arr_rec_matrix[l_curr_arr].minmax_qty THEN 
			ERROR kandoomsg2("E",9074,"") 		#9074 Cannot decrease stock below invoiced qty
			RETURN FALSE 
		END IF 
	END IF 

	IF l_order_qty IS NULL THEN 
		RETURN FALSE 
	END IF 
	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION validate_cell(p_idx)
###########################################################################


###########################################################################
# FUNCTION pack_addition()    
#  
#
#
###########################################################################
FUNCTION pack_addition() 
	DEFINE l_rec_kitdetl RECORD LIKE kitdetl.* 
	DEFINE l_rec_kithead RECORD LIKE kithead.* 
	DEFINE l_pack_qty FLOAT 
	DEFINE i SMALLINT 

	OPEN WINDOW e461 with FORM "E461" 
	 CALL windecoration_e("E461") -- albo kd-755 

	MESSAGE kandoomsg2("U",1020,"Pack") #1020 Enter Pack Details; OK TO Continue.
	INPUT BY NAME l_rec_kithead.kit_code, 
	l_pack_qty 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E11j","input-l_rec_kithead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD kit_code 
			IF l_rec_kithead.kit_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD kit_code 
			END IF 
			LET l_rec_kithead.kit_text = NULL 
			SELECT * INTO l_rec_kithead.* FROM kithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND kit_code = l_rec_kithead.kit_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD NOT found; Try Window.
				DISPLAY BY NAME l_rec_kithead.kit_text 

				NEXT FIELD kit_code 
			END IF 
			DISPLAY BY NAME l_rec_kithead.kit_text 

		AFTER FIELD l_pack_qty 
			IF l_pack_qty IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered
				NEXT FIELD l_pack_qty 
			END IF 
			IF l_pack_qty <= 0 THEN 
				ERROR kandoomsg2("U",9927,0) 			#9927 Value must be greater than 0
				NEXT FIELD l_pack_qty 
			END IF 

		AFTER INPUT 
			IF l_pack_qty IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD l_pack_qty 
			END IF 
	END INPUT 

	CLOSE WINDOW E461
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN 
	END IF
	 
	DECLARE c_kitdetl cursor FOR 
	SELECT * FROM kitdetl 
	WHERE kit_code = l_rec_kithead.kit_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code
	 
	FOREACH c_kitdetl INTO l_rec_kitdetl.* 
		FOR i = 1 TO modu_matrix_count 
			IF modu_arr_rec_matrix[i].part_code = l_rec_kitdetl.part_code THEN 
				LET modu_arr_rec_matrix[i].order_qty = modu_arr_rec_matrix[i].order_qty 
				+ (l_rec_kitdetl.kit_qty * l_pack_qty) 
			END IF 
		END FOR 
	END FOREACH
	 
	CALL display_matrix() 
END FUNCTION
###########################################################################
# END FUNCTION pack_addition()
###########################################################################