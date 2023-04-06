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

###########################################################################
# Module Scope Variables
########################################################################### 
DEFINE modu_cmpy LIKE company.cmpy_code 
DEFINE modu_load_trantype_ind LIKE serialinfo.trantype_ind 
DEFINE modu_from_trantype_ind LIKE serialinfo.trantype_ind 
DEFINE mv_trans_num LIKE serialinfo.trans_num 
# the fields are 'backwards' TO get the ARRAY TO work proper
DEFINE modu_arr_serialinfo ARRAY[1000] OF RECORD 
	serial_code LIKE serialinfo.serial_code, 
	scroll_flag CHAR(1) 
END RECORD 
DEFINE modu_return_type CHAR(1)
DEFINE modu_table_exists CHAR(1) 


###########################################################################
# FUNCTION serial_init(p_cmpy,p_load_trantype_ind,p_from_trantype_ind,p_trans_num )
#
#
########################################################################### 
FUNCTION serial_init(p_cmpy,p_load_trantype_ind,p_from_trantype_ind,p_trans_num ) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_load_trantype_ind LIKE serialinfo.trantype_ind 
	DEFINE p_from_trantype_ind LIKE serialinfo.trantype_ind 
	DEFINE p_trans_num LIKE serialinfo.trans_num 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 

	LET modu_cmpy = p_cmpy 
	LET modu_load_trantype_ind = p_load_trantype_ind 
	LET modu_from_trantype_ind = p_from_trantype_ind 
	LET mv_trans_num = p_trans_num 

	IF modu_table_exists = "Y" THEN 
		DELETE FROM t_serialinfo WHERE 1 = 1 
	ELSE 
		LET modu_table_exists = "Y" 
		CALL create_table("serialinfo","t_serialinfo","","Y") 
	END IF 

	CASE modu_load_trantype_ind 
		WHEN 'C' 
			LET modu_return_type = 'C' 
		WHEN 'P' 
			LET modu_return_type = 'P' 
		WHEN "V" 
			LET modu_return_type = "V" 
		OTHERWISE 
			LET modu_return_type = 'N' 
	END CASE 

	IF p_trans_num IS NULL OR p_trans_num = 0 THEN 
		RETURN 

	ELSE 

		CASE modu_load_trantype_ind 
			WHEN 'C' 
				LET modu_load_trantype_ind = '0' 
				DECLARE c_serialinfo2 CURSOR FOR 
				SELECT * FROM serialinfo 
				WHERE cmpy_code = modu_cmpy 
				AND trantype_ind = modu_load_trantype_ind 
				AND credit_num = p_trans_num 
				FOREACH c_serialinfo2 INTO l_rec_serialinfo.* 
					INSERT INTO t_serialinfo VALUES ( l_rec_serialinfo.*) 
				END FOREACH 

			WHEN 'P' 
				LET modu_load_trantype_ind = '0' 
				DECLARE c_serialinfo3 CURSOR FOR 
				SELECT * FROM serialinfo 
				WHERE cmpy_code = modu_cmpy 
				AND trantype_ind = modu_load_trantype_ind 
				AND po_num = p_trans_num 
				FOREACH c_serialinfo3 INTO l_rec_serialinfo.* 
					INSERT INTO t_serialinfo VALUES ( l_rec_serialinfo.*) 
				END FOREACH 

			WHEN '2' 
				DECLARE c_serialinfo4 CURSOR FOR 
				SELECT * FROM serialinfo 
				WHERE cmpy_code = modu_cmpy 
				AND trantype_ind = modu_load_trantype_ind 
				AND ref_num = p_trans_num 
				FOREACH c_serialinfo4 INTO l_rec_serialinfo.* 
					INSERT INTO t_serialinfo VALUES ( l_rec_serialinfo.*) 
				END FOREACH 

			OTHERWISE 
				DECLARE c_serialinfo CURSOR FOR 
				SELECT * FROM serialinfo 
				WHERE cmpy_code = modu_cmpy 
				AND trantype_ind = modu_load_trantype_ind 
				AND trans_num = p_trans_num 
				FOREACH c_serialinfo INTO l_rec_serialinfo.* 
					INSERT INTO t_serialinfo VALUES ( l_rec_serialinfo.*) 
				END FOREACH 
		END CASE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION serial_init(p_cmpy,p_load_trantype_ind,p_from_trantype_ind,p_trans_num )
########################################################################### 


###########################################################################
# FUNCTION serial_line_init(p_part_code,p_ware_code)
#
#
########################################################################### 
FUNCTION serial_line_init(p_part_code,p_ware_code) 
	DEFINE p_part_code LIKE serialinfo.part_code 
	DEFINE p_ware_code LIKE serialinfo.ware_code 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 

	DELETE FROM t_serialinfo 
	WHERE part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND cmpy_code = modu_cmpy 

	CASE modu_return_type 
		WHEN 'C' 
			LET modu_load_trantype_ind = '0' 
			DECLARE c_serialinfo12 CURSOR FOR 
			SELECT * FROM serialinfo 
			WHERE cmpy_code = modu_cmpy 
			AND part_code = p_part_code 
			AND ware_code = p_ware_code 
			AND trantype_ind = modu_load_trantype_ind 
			AND credit_num = mv_trans_num 
			FOREACH c_serialinfo12 INTO l_rec_serialinfo.* 
				INSERT INTO t_serialinfo VALUES ( l_rec_serialinfo.*) 
			END FOREACH 

		WHEN 'V' 
			LET modu_load_trantype_ind = '0' 
			DECLARE c_serialinfo5 CURSOR FOR 
			SELECT * FROM serialinfo 
			WHERE cmpy_code = modu_cmpy 
			AND part_code = p_part_code 
			AND (( ref_num = 0 OR ref_num IS null) 
			OR (credit_num IS NOT NULL OR credit_num != 0)) 
			FOREACH c_serialinfo5 INTO l_rec_serialinfo.* 
				INSERT INTO t_serialinfo VALUES ( l_rec_serialinfo.*) 
			END FOREACH 

		WHEN 'P' 
			LET modu_load_trantype_ind = '0' 
			DECLARE c_serialinfo13 CURSOR FOR 
			SELECT * FROM serialinfo 
			WHERE cmpy_code = modu_cmpy 
			AND part_code = p_part_code 
			AND ware_code = p_ware_code 
			AND trantype_ind = modu_load_trantype_ind 
			AND po_num = mv_trans_num 
			FOREACH c_serialinfo13 INTO l_rec_serialinfo.* 
				INSERT INTO t_serialinfo VALUES ( l_rec_serialinfo.*) 
			END FOREACH 

		OTHERWISE 
			DECLARE c_serialinfo10 CURSOR FOR 
			SELECT * FROM serialinfo 
			WHERE cmpy_code = modu_cmpy 
			AND part_code = p_part_code 
			AND ware_code = p_ware_code 
			AND trantype_ind = modu_load_trantype_ind 
			AND trans_num = mv_trans_num 
			FOREACH c_serialinfo10 INTO l_rec_serialinfo.* 
				INSERT INTO t_serialinfo VALUES ( l_rec_serialinfo.*) 
			END FOREACH 
	END CASE 
END FUNCTION 
###########################################################################
# FUNCTION serial_line_init(p_part_code,p_ware_code)
########################################################################### 


###########################################################################
# FUNCTION serial_input(p_part_code,p_ware_code,p_tran_qty)
#
#
########################################################################### 
FUNCTION serial_input(p_part_code,p_ware_code,p_tran_qty) 
	DEFINE p_part_code LIKE serialinfo.part_code 
	DEFINE p_ware_code LIKE serialinfo.ware_code 
	DEFINE p_tran_qty INTEGER 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_sto_serial_code LIKE serialinfo.serial_code 
	DEFINE l_errmsg CHAR(100) 
	DEFINE l_sto_scroll_flag CHAR(1) 
	DEFINE l_errors CHAR(1) 
	DEFINE l_first_time  SMALLINT
	DEFINE l_idx, l_scrn, l_cnt SMALLINT 
	DEFINE l_counter DECIMAL(8,2) 
	DEFINE i SMALLINT
	
	IF p_tran_qty IS NULL THEN 
		LET p_tran_qty = 0 
	END IF 

	OPEN WINDOW i186 with FORM "I186" 
	CALL windecoration_i("I186") -- albo kd-758 

	SELECT * INTO l_rec_product.* FROM product 
	WHERE part_code = p_part_code 
	AND cmpy_code = modu_cmpy 

	SELECT * INTO l_rec_warehouse.* FROM warehouse 
	WHERE ware_code = p_ware_code 
	AND cmpy_code = modu_cmpy 

	DISPLAY 
		l_rec_product.part_code, 
		l_rec_product.desc_text, 
		l_rec_product.desc2_text, 
		l_rec_warehouse.ware_code, 
		l_rec_warehouse.desc_text 
	TO 
		part_code, 
		product.desc_text, 
		desc2_text, 
		ware_code, 
		warehouse.desc_text 

	FOR i= 1 TO 1000 
		INITIALIZE modu_arr_serialinfo[i].* TO NULL 
	END FOR 

	DECLARE curser_item CURSOR FOR 
	SELECT * INTO l_rec_serialinfo.* FROM t_serialinfo 
	WHERE part_code = p_part_code 
	AND cmpy_code = modu_cmpy 
	ORDER BY serial_code 
	LET l_idx = 0 

	FOREACH curser_item 
		DISPLAY "" at 2,1 
		DISPLAY "RETURN/FROM ", modu_return_type, " ", modu_from_trantype_ind at 2,1 
		SLEEP 3 
		IF l_rec_serialinfo.ware_code <> p_ware_code 
		AND modu_from_trantype_ind IS NULL 
		AND ( modu_return_type = 'N' 
		OR modu_return_type = 'P' ) THEN 
			CONTINUE FOREACH 
		END IF 
		LET l_idx = l_idx + 1 
		LET modu_arr_serialinfo[l_idx].scroll_flag = NULL 
		LET modu_arr_serialinfo[l_idx].serial_code = l_rec_serialinfo.serial_code 
		IF l_idx > 1000 THEN 
			LET l_msgresp = kandoomsg("I",9277,'') 
			#9277 Only 1000 Serial Products are allowed in a Transaction.
			CLOSE WINDOW i186 
			LET l_errmsg = "serial_input - Only 1000 Serial Products ", 
			"allowed in a Transaction " 
			CALL errorlog(l_errmsg) 
			RETURN - 3 
		END IF 
	END FOREACH 

	DISPLAY "" at 2,1 
	DISPLAY "p_tran_qty / l_idx ",p_tran_qty, " ",l_idx at 2,1 
	SLEEP 2 

	IF p_tran_qty = 0 
	AND l_idx > 0 THEN 
		LET l_msgresp = kandoomsg("I",9278,'') 
		#9278 Product / Warehouse combination can only occur once.
		CLOSE WINDOW i186 
		RETURN -1 
	END IF 

	IF p_tran_qty <> l_idx THEN 
		LET l_msgresp = kandoomsg("I",9279,'') 
		#9279 Error - INPUT Quantity NOT equal OUTPUT Quantity.
		LET l_errmsg = "serial_input - Qty supplied NOT = table qty ", 
		p_tran_qty , " <> ", l_idx 
		CALL errorlog(l_errmsg) 
		CLOSE WINDOW i186 
		RETURN -2 
	END IF 
	LET l_cnt = l_idx 
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("A",1004,"") 
	#1004  F1 TO Add;  F2 TO Delete;  OK TO Continue.
	LET l_errors = 'Y' 
	OPTIONS DELETE KEY f2, 
	INSERT KEY f1 

	WHILE l_errors = 'Y' 
		LET l_first_time = true 

		INPUT ARRAY modu_arr_serialinfo WITHOUT DEFAULTS FROM sr_serialinfo.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","serifunc","input_arr-serialinfo") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 



			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				NEXT FIELD serial_code 

			BEFORE FIELD scroll_flag 
				LET l_sto_scroll_flag = modu_arr_serialinfo[l_idx].scroll_flag 
				##            IF fgl_lastkey() = fgl_keyval("up")
				##             OR fgl_lastkey() = fgl_keyval("left") THEN
				##               NEXT FIELD previous
				##            ELSE
				##               NEXT FIELD next
				##            END IF

			AFTER FIELD scroll_flag 
				LET modu_arr_serialinfo[l_idx].scroll_flag = l_sto_scroll_flag 
				DISPLAY modu_arr_serialinfo[l_idx].* TO sr_serialinfo[l_scrn].* 


			BEFORE FIELD serial_code 
				LET l_sto_serial_code = modu_arr_serialinfo[l_idx].serial_code 
				IF l_first_time THEN 
					IF modu_arr_serialinfo[l_idx].serial_code IS NULL THEN 
						LET l_first_time = false 
					ELSE 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 

			AFTER FIELD serial_code 
				IF modu_arr_serialinfo[l_idx].serial_code IS NULL 
				AND l_sto_serial_code IS NOT NULL THEN 
					LET modu_arr_serialinfo[l_idx].serial_code = l_sto_serial_code 
					DISPLAY modu_arr_serialinfo[l_idx].* TO sr_serialinfo[l_scrn].* 

					LET l_msgresp = kandoomsg("U",9102,'') 
					#9102 Value must be entered
					NEXT FIELD serial_code 
				END IF 
				IF modu_arr_serialinfo[l_idx].serial_code != l_sto_serial_code THEN 
					LET modu_arr_serialinfo[l_idx].serial_code = l_sto_serial_code 
					DISPLAY modu_arr_serialinfo[l_idx].* TO sr_serialinfo[l_scrn].* 

					ERROR " Can't edit serial numbers in this program - Use I32 " 
					NEXT FIELD serial_code 
				END IF 
				IF fgl_lastkey() != fgl_keyval("accept") THEN 
					IF modu_arr_serialinfo[l_idx].serial_code IS NULL THEN 
						LET modu_arr_serialinfo[l_idx].scroll_flag = "" 
						DISPLAY modu_arr_serialinfo[l_idx].* TO sr_serialinfo[l_scrn].* 

						IF fgl_lastkey() = fgl_keyval("down") 
						OR fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("right") THEN 
							NEXT FIELD serial_code 
						END IF 
					ELSE 
						CALL check_code(l_sto_serial_code, p_part_code, 
						p_ware_code, l_idx ) 
					END IF 
					DISPLAY modu_arr_serialinfo[l_idx].* TO sr_serialinfo[l_scrn].* 

				END IF 

		END INPUT 

		LET l_errors = 'N' 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		FOR i = 1 TO arr_count() 
			IF modu_arr_serialinfo[i].scroll_flag IS NOT NULL THEN 
				LET l_msgresp = kandoomsg("I",9276,'') 
				#9276 Errored Serial Codes exist.
				LET l_errors = 'Y' 
				EXIT FOR 
			END IF 
		END FOR 
	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW i186 
		RETURN l_cnt 
	END IF 
	LET l_counter = 0 
	DELETE FROM t_serialinfo 
	WHERE part_code = l_rec_serialinfo.part_code 
	FOR i = 1 TO arr_count() 
		IF modu_arr_serialinfo[i].serial_code IS NOT NULL THEN 

			LET l_counter = l_counter + 1 
			SELECT * INTO l_rec_serialinfo.* FROM serialinfo 
			WHERE cmpy_code = modu_cmpy 
			AND part_code = p_part_code 
			AND serial_code = modu_arr_serialinfo[i].serial_code 
			IF status = notfound THEN 
				LET l_rec_serialinfo.cmpy_code = modu_cmpy 
				LET l_rec_serialinfo.part_code = p_part_code 
				LET l_rec_serialinfo.serial_code = modu_arr_serialinfo[i].serial_code 
				LET l_rec_serialinfo.po_num = NULL 
				LET l_rec_serialinfo.ref_num = NULL 
				LET l_rec_serialinfo.credit_num = NULL 
			END IF 
			LET l_rec_serialinfo.ware_code = p_ware_code 
			IF modu_return_type = 'N' 
			OR modu_return_type = 'V' THEN 
				LET l_rec_serialinfo.trans_num = mv_trans_num 
			END IF 
			INSERT INTO t_serialinfo VALUES (l_rec_serialinfo.*) 
		END IF 
	END FOR 
	CLOSE WINDOW i186 
	RETURN l_counter 
END FUNCTION 
###########################################################################
# END FUNCTION serial_input(p_part_code,p_ware_code,p_tran_qty)
########################################################################### 


###########################################################################
# FUNCTION check_code(p_sto_serial_code,p_part_code,p_ware_code,p_idx)
#
#
########################################################################### 
FUNCTION check_code(p_sto_serial_code,p_part_code,p_ware_code,p_idx) 
	DEFINE p_sto_serial_code LIKE serialinfo.serial_code 
	DEFINE p_part_code LIKE serialinfo.part_code 
	DEFINE p_ware_code LIKE serialinfo.ware_code 
	DEFINE p_idx SMALLINT 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_test_trans_num LIKE serialinfo.credit_num 
	DEFINE l_store_scroll_flag CHAR(1) 
	DEFINE l_sto_i SMALLINT 
	DEFINE l_err_cnt SMALLINT 
	DEFINE i SMALLINT

	LET l_store_scroll_flag = modu_arr_serialinfo[p_idx].scroll_flag 
	LET modu_arr_serialinfo[p_idx].scroll_flag = "" 
	SELECT * INTO l_rec_serialinfo.* FROM serialinfo 
	WHERE cmpy_code = modu_cmpy 
	AND part_code = p_part_code 
	AND serial_code = modu_arr_serialinfo[p_idx].serial_code 

	# turned INTO CASE statement AND added type "V" AND "C"
	#          Note C AND V temporary FOR this check. Never updated INTO
	#          serialinfo

	CASE modu_from_trantype_ind 
		WHEN modu_from_trantype_ind IS NULL 
			IF status <> notfound THEN 
				IF (modu_return_type = 'P' 
				OR modu_return_type = 'V') 
				AND l_rec_serialinfo.po_num = mv_trans_num 
				AND l_rec_serialinfo.trantype_ind = modu_load_trantype_ind THEN 
					#its ok
				ELSE 
					LET modu_arr_serialinfo[p_idx].scroll_flag = "E" 
					LET l_msgresp = kandoomsg("I",9272,'') 
					#9272  Serial number already exists.
					RETURN 
				END IF 
			END IF 
		WHEN "V" 
			IF status = notfound THEN 
				LET modu_arr_serialinfo[p_idx].scroll_flag = "N" 
				LET l_msgresp = kandoomsg("I",9271,'') 
				#9271 Serial number does NOT exist.
				RETURN 
			END IF 
			IF l_rec_serialinfo.ref_num = 0 
			OR l_rec_serialinfo.ref_num IS NULL 
			OR l_rec_serialinfo.credit_num != 0 
			OR l_rec_serialinfo.credit_num IS NOT NULL THEN 
			ELSE 
				LET l_msgresp = kandoomsg("I",9274,'') 
				#9274 The Product with this Serial Number IS already
				LET modu_arr_serialinfo[p_idx].scroll_flag = "U" 
				RETURN 
			END IF 
		WHEN "C" 
			IF status = notfound THEN 
				LET modu_arr_serialinfo[p_idx].scroll_flag = "N" 
				LET l_msgresp = kandoomsg("I",9271,'') 
				#9271 Serial number does NOT exist.
				RETURN 
			END IF 
			IF l_rec_serialinfo.credit_num <> 0 
			AND l_rec_serialinfo.credit_num IS NOT NULL THEN 
				LET l_msgresp = kandoomsg("I",9274,'') 
				#9274 The Product with this Serial Number IS already
				LET modu_arr_serialinfo[p_idx].scroll_flag = "U" 
				RETURN 
			END IF 
			IF l_rec_serialinfo.ref_num = 0 
			OR l_rec_serialinfo.ref_num IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9274,'') 
				#9274 The Product with this Serial Number IS already
				LET modu_arr_serialinfo[p_idx].scroll_flag = "U" 
				RETURN 
			END IF 
		OTHERWISE 
			IF status = notfound 
			AND (modu_return_type <> "P" OR modu_return_type <> "V") THEN 
				LET modu_arr_serialinfo[p_idx].scroll_flag = "N" 
				LET l_msgresp = kandoomsg("I",9271,'') 
				#9271 Serial number does NOT exist.
				RETURN 
			END IF 
			IF l_rec_serialinfo.ware_code <> p_ware_code 
			AND modu_return_type <> 'C' THEN 
				LET l_msgresp = kandoomsg("I",9273,'') 
				#9273 The Product with this serial number exists at
				LET modu_arr_serialinfo[p_idx].scroll_flag = "E" 
				RETURN 
			END IF 
			CASE modu_return_type 
				WHEN 'N' 
					LET l_test_trans_num = l_rec_serialinfo.trans_num 
				WHEN 'P' 
					LET l_test_trans_num = l_rec_serialinfo.po_num 
				OTHERWISE 
					LET l_test_trans_num = l_rec_serialinfo.credit_num 
			END CASE 
			IF l_test_trans_num <> mv_trans_num 
			OR l_test_trans_num IS NULL 
			OR mv_trans_num IS NULL 
			OR l_rec_serialinfo.trantype_ind <> modu_load_trantype_ind THEN 
				IF modu_from_trantype_ind = 'T' 
				OR modu_from_trantype_ind = 'T' THEN 
					IF l_rec_serialinfo.trantype_ind <> modu_load_trantype_ind 
					OR l_rec_serialinfo.trans_num <> mv_trans_num THEN 
						LET l_msgresp = kandoomsg("I",9274,'') 
						#9274 The Product with this Serial Number IS already
						LET modu_arr_serialinfo[p_idx].scroll_flag = "U" 
						RETURN 
					END IF 
				ELSE 
					IF l_rec_serialinfo.trantype_ind <> modu_from_trantype_ind THEN 
						LET l_msgresp = kandoomsg("I",9274,'') 
						#9274 The Product with this Serial Number IS already
						LET modu_arr_serialinfo[p_idx].scroll_flag = "U" 
						RETURN 
					END IF 
				END IF 
			END IF 
	END CASE 

	FOR i = 1 TO arr_count() 
		IF modu_arr_serialinfo[i].serial_code = modu_arr_serialinfo[p_idx].serial_code 
		AND i <> p_idx THEN 
			LET modu_arr_serialinfo[p_idx].scroll_flag = "e" 
			LET l_msgresp = kandoomsg("I",9275,'') 
			#9275  Serial number already added TO table
			EXIT FOR 
		END IF 
	END FOR 
	IF l_store_scroll_flag = 'E' 
	AND modu_arr_serialinfo[p_idx].scroll_flag = '' THEN 
		LET l_err_cnt = 0 
		FOR i = 1 TO arr_count() 
			IF p_sto_serial_code = modu_arr_serialinfo[i].serial_code 
			AND i <> p_idx THEN 
				LET l_sto_i = i 
				LET l_err_cnt = l_err_cnt + 1 
			END IF 
		END FOR 
		IF l_err_cnt = 1 THEN 
			LET modu_arr_serialinfo[l_sto_i].scroll_flag = '' 
		END IF 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION check_code(p_sto_serial_code,p_part_code,p_ware_code,p_idx)
########################################################################### 


###########################################################################
# FUNCTION serial_update(p_serialinfo,p_trans_qty,p_return_trantype_ind)
#
#
########################################################################### 
FUNCTION serial_update(p_serialinfo,p_trans_qty,p_return_trantype_ind) 
	DEFINE p_serialinfo RECORD LIKE serialinfo.* 
	DEFINE p_trans_qty INTEGER 
	DEFINE p_return_trantype_ind LIKE serialinfo.trantype_ind 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_rec_serialinfo2 RECORD LIKE serialinfo.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_test_trans_num LIKE serialinfo.credit_num 
	DEFINE l_errmsg CHAR(100) 
	DEFINE l_err_flag CHAR(1) 

	IF p_serialinfo.trantype_ind IS NULL THEN 
		LET l_errmsg = "Serial UPDATE - trantype NOT setup " 
		CALL errorlog(l_errmsg) 
		RETURN -1 
	END IF 

	IF p_trans_qty <> 0 THEN 
		DECLARE c_serialinfo_c CURSOR FOR 
		SELECT * FROM t_serialinfo 
		WHERE cmpy_code = p_serialinfo.cmpy_code 
		AND part_code = p_serialinfo.part_code 
		FOREACH c_serialinfo_c INTO l_rec_serialinfo.* 
			LET l_err_flag = 'N' 
			SELECT * INTO l_rec_serialinfo2.* FROM serialinfo 
			WHERE cmpy_code = modu_cmpy 
			AND part_code = l_rec_serialinfo.part_code 
			AND serial_code = l_rec_serialinfo.serial_code 
			IF modu_from_trantype_ind IS NULL THEN 
				IF status <> notfound THEN 
					IF (modu_return_type = 'P' 
					OR modu_return_type = 'V') 
					AND l_rec_serialinfo2.trantype_ind = modu_load_trantype_ind 
					AND l_rec_serialinfo2.po_num = mv_trans_num THEN 
						#its ok
					ELSE 
						LET l_err_flag = 'Y' 
					END IF 
				ELSE 
					INITIALIZE l_rec_serialinfo2.* TO NULL 
				END IF 
			ELSE 
				IF status = notfound THEN 
					LET l_err_flag = 'Y' 
				END IF 
				IF l_rec_serialinfo2.ware_code <> l_rec_serialinfo.ware_code 
				AND modu_return_type <> 'C' THEN 
					LET l_err_flag = 'Y' 
				END IF 
				CASE modu_return_type 
					WHEN 'N' 
						LET l_test_trans_num = l_rec_serialinfo2.trans_num 
					WHEN 'P' 
						LET l_test_trans_num = l_rec_serialinfo2.po_num 
					OTHERWISE 
						LET l_test_trans_num = l_rec_serialinfo2.credit_num 
				END CASE 
				#   l_rec_serialinfo  IS FROM temp table
				#   l_rec_serialinfo2 IS FROM database now
				IF l_test_trans_num <> mv_trans_num 
				OR l_test_trans_num IS NULL 
				OR mv_trans_num IS NULL 
				OR l_rec_serialinfo2.trantype_ind <> modu_load_trantype_ind THEN 
					IF modu_from_trantype_ind = 'T' 
					OR modu_from_trantype_ind = 'T' THEN 
						IF l_rec_serialinfo2.trantype_ind <> modu_load_trantype_ind 
						OR l_rec_serialinfo2.trans_num <> mv_trans_num THEN 
							LET l_err_flag = 'Y' 
						END IF 
					ELSE 
						IF l_rec_serialinfo2.trantype_ind <> modu_from_trantype_ind THEN 
							LET l_err_flag = 'Y' 
						END IF 
					END IF 
				END IF 
			END IF 

			IF l_err_flag = 'Y' THEN 
				LET l_msgresp = kandoomsg("I",7080,'') 
				#7080 Another User altered serial information during this .
				LET l_errmsg = "Serial UPDATE - Another user changed VALUES ", 
				l_rec_serialinfo2.trantype_ind, "|", status, "|", 
				l_rec_serialinfo.serial_code 
				CALL errorlog(l_errmsg) 
				RETURN 1 
			END IF 

			IF p_serialinfo.vend_code IS NOT NULL THEN 

				IF l_rec_serialinfo2.vend_code IS NULL THEN 
					LET l_rec_serialinfo.vend_code = p_serialinfo.vend_code 
				END IF 
			END IF 
			IF p_serialinfo.po_num IS NOT NULL 
			AND p_serialinfo.po_num <> 0 THEN 

				IF l_rec_serialinfo2.po_num IS NULL 
				OR l_rec_serialinfo2.po_num = 0 THEN 
					LET l_rec_serialinfo.po_num = p_serialinfo.po_num 
				END IF 
			END IF 
			IF p_serialinfo.receipt_date IS NOT NULL 
			AND p_serialinfo.receipt_date <> 0 THEN 

				IF l_rec_serialinfo2.receipt_date IS NULL 
				OR l_rec_serialinfo2.receipt_date = 0 THEN 
					LET l_rec_serialinfo.receipt_date = p_serialinfo.receipt_date 
				END IF 
			END IF 
			IF p_serialinfo.receipt_num IS NOT NULL 
			AND p_serialinfo.receipt_num <> 0 THEN 

				IF l_rec_serialinfo2.receipt_num IS NULL 
				OR l_rec_serialinfo2.receipt_num = 0 THEN 
					LET l_rec_serialinfo.receipt_num = p_serialinfo.receipt_num 
				END IF 
			END IF 
			IF p_serialinfo.cust_code IS NOT NULL THEN 

				IF l_rec_serialinfo2.cust_code IS NULL THEN 
					LET l_rec_serialinfo.cust_code = p_serialinfo.cust_code 
				END IF 
			END IF 
			IF p_serialinfo.trans_num IS NOT NULL 
			AND p_serialinfo.trans_num <> 0 THEN 

				IF l_rec_serialinfo2.trans_num IS NULL 
				OR l_rec_serialinfo2.trans_num = 0 THEN 
					LET l_rec_serialinfo.trans_num = p_serialinfo.trans_num 
				END IF 
			END IF 
			IF p_serialinfo.ref_num IS NOT NULL 
			AND p_serialinfo.ref_num <> 0 THEN 
				LET l_rec_serialinfo.ref_num = p_serialinfo.ref_num 
			END IF 
			IF p_serialinfo.ship_date IS NOT NULL 
			AND p_serialinfo.ship_date <> 0 THEN 
				LET l_rec_serialinfo.ship_date = p_serialinfo.ship_date 
			END IF 
			IF l_rec_serialinfo.ship_date = 0 THEN 
				LET l_rec_serialinfo.ship_date = NULL 
			END IF 
			IF p_serialinfo.credit_num IS NOT NULL 
			AND p_serialinfo.credit_num <> 0 THEN 

				IF l_rec_serialinfo2.credit_num IS NULL 
				OR l_rec_serialinfo2.credit_num = 0 THEN 
					LET l_rec_serialinfo.credit_num = p_serialinfo.credit_num 
				END IF 
			END IF 
			IF p_serialinfo.ware_code IS NOT NULL THEN 
				LET l_rec_serialinfo.ware_code = p_serialinfo.ware_code 
			END IF 

			LET l_rec_serialinfo.trantype_ind = p_serialinfo.trantype_ind 
			IF l_rec_serialinfo.trantype_ind = 'X' THEN 
				DELETE FROM serialinfo 
				WHERE part_code = l_rec_serialinfo.part_code 
				AND serial_code = l_rec_serialinfo.serial_code 
				AND cmpy_code = l_rec_serialinfo.cmpy_code 
				IF status <> 0 THEN 
					RETURN status 
				END IF 
			ELSE 
				SELECT unique 1 FROM serialinfo 
				WHERE part_code = l_rec_serialinfo.part_code 
				AND serial_code = l_rec_serialinfo.serial_code 
				AND cmpy_code = l_rec_serialinfo.cmpy_code 
				IF status <> notfound THEN 
					UPDATE serialinfo 
					SET serialinfo.* = l_rec_serialinfo.* 
					WHERE part_code = l_rec_serialinfo.part_code 
					AND serial_code = l_rec_serialinfo.serial_code 
					AND cmpy_code = l_rec_serialinfo.cmpy_code 
					IF status <> 0 THEN 
						RETURN status 
					END IF 
				ELSE 
					INSERT INTO serialinfo VALUES ( l_rec_serialinfo.*) 
					IF status <> 0 THEN 
						RETURN status 
					END IF 
				END IF 
			END IF 
		END FOREACH 

		IF p_return_trantype_ind IS NOT NULL THEN 
			LET status = serial_return(p_serialinfo.part_code, 
			p_return_trantype_ind) 
			IF status <> 0 THEN 
				RETURN status 
			END IF 
		END IF 
	END IF 
	RETURN 0 
END FUNCTION 
###########################################################################
# END FUNCTION serial_update(p_serialinfo,p_trans_qty,p_return_trantype_ind)
########################################################################### 


###########################################################################
# FUNCTION serial_return(p_part_code,p_return_trantype_ind)
#
#
########################################################################### 
FUNCTION serial_return(p_part_code,p_return_trantype_ind) 
	DEFINE p_part_code LIKE serialinfo.part_code 
	DEFINE p_return_trantype_ind LIKE serialinfo.trantype_ind 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_rec_serialinfo2 RECORD LIKE serialinfo.* 
	DEFINE l_ware_code LIKE serialinfo.ware_code 
	DEFINE l_tmp_trans_num LIKE serialinfo.trans_num 
	DEFINE l_cust_code LIKE serialinfo.cust_code 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_errmsg CHAR(100) 

	IF p_return_trantype_ind IS NULL THEN 
		LET l_errmsg = "Serial delete live - trantype NOT setup " 
		CALL errorlog(l_errmsg) 
		RETURN -1 
	END IF 

	CASE modu_return_type 
		WHEN 'C' 
			LET l_query_text = "SELECT * FROM serialinfo ", 
			"WHERE cmpy_code = '", modu_cmpy, 
			"' AND credit_num = '", mv_trans_num, 
			"' AND trantype_ind = '", modu_load_trantype_ind,"'" 
		WHEN 'P' 
			LET l_query_text = "SELECT * FROM serialinfo ", 
			"WHERE cmpy_code = '", modu_cmpy, 
			"' AND po_num = '", mv_trans_num, 
			"' AND trantype_ind = '", modu_load_trantype_ind,"'" 
		OTHERWISE 
			LET l_query_text = "SELECT * FROM serialinfo ", 
			"WHERE cmpy_code = '", modu_cmpy, 
			"' AND trans_num = '", mv_trans_num, 
			"' AND trantype_ind = '", modu_load_trantype_ind,"'" 
	END CASE 

	IF p_part_code IS NOT NULL THEN 
		LET l_query_text = l_query_text CLIPPED, 
		" AND part_code = '", p_part_code, "'" 
	END IF 

	PREPARE s_ret_serial FROM l_query_text 
	DECLARE c_ret_serial CURSOR FOR s_ret_serial 

	FOREACH c_ret_serial INTO l_rec_serialinfo.* 
		SELECT * INTO l_rec_serialinfo2.* FROM t_serialinfo 
		WHERE cmpy_code = l_rec_serialinfo.cmpy_code 
		AND part_code = l_rec_serialinfo.part_code 
		AND serial_code = l_rec_serialinfo.serial_code 
		IF status = notfound THEN 
			CASE modu_return_type 
				WHEN 'N' 
					UPDATE serialinfo 
					SET trans_num = null, 
					trantype_ind = p_return_trantype_ind 
					WHERE cmpy_code = l_rec_serialinfo.cmpy_code 
					AND part_code = l_rec_serialinfo.part_code 
					AND serial_code = l_rec_serialinfo.serial_code 
					AND trans_num = l_rec_serialinfo.trans_num 

				WHEN 'P' 
					DELETE FROM serialinfo 
					WHERE cmpy_code = l_rec_serialinfo.cmpy_code 
					AND part_code = l_rec_serialinfo.part_code 
					AND serial_code = l_rec_serialinfo.serial_code 
					AND po_num = l_rec_serialinfo.po_num 
					AND trantype_ind = '0' 

				OTHERWISE 
					SELECT trans_num INTO l_tmp_trans_num FROM serialinfo 
					WHERE cmpy_code = l_rec_serialinfo.cmpy_code 
					AND part_code = l_rec_serialinfo.part_code 
					AND serial_code = l_rec_serialinfo.serial_code 
					AND credit_num = l_rec_serialinfo.credit_num 

					SELECT cust_code INTO l_cust_code FROM invoicehead 
					WHERE cmpy_code = l_rec_serialinfo.cmpy_code 
					AND inv_num = l_tmp_trans_num 
					SELECT unique ware_code INTO l_ware_code FROM invoicedetl 
					WHERE cmpy_code = l_rec_serialinfo.cmpy_code 
					AND inv_num = l_tmp_trans_num 
					IF status = 0 THEN 
						UPDATE serialinfo 
						SET credit_num = null, 
						ware_code = l_ware_code, 
						cust_code = l_cust_code, 
						trantype_ind = p_return_trantype_ind 
						WHERE cmpy_code = l_rec_serialinfo.cmpy_code 
						AND part_code = l_rec_serialinfo.part_code 
						AND serial_code = l_rec_serialinfo.serial_code 
						AND credit_num = l_rec_serialinfo.credit_num 
					ELSE 
						UPDATE serialinfo 
						SET credit_num = null, 
						cust_code = l_cust_code, 
						trantype_ind = p_return_trantype_ind 
						WHERE cmpy_code = l_rec_serialinfo.cmpy_code 
						AND part_code = l_rec_serialinfo.part_code 
						AND serial_code = l_rec_serialinfo.serial_code 
						AND credit_num = l_rec_serialinfo.credit_num 
					END IF 
			END CASE 
		END IF 
	END FOREACH 
	RETURN 0 
END FUNCTION 
###########################################################################
# END FUNCTION serial_return(p_part_code,p_return_trantype_ind)
########################################################################### 


###########################################################################
# FUNCTION serial_delete(p_part_code,p_ware_code)
#
#
########################################################################### 
FUNCTION serial_delete(p_part_code,p_ware_code) 
	DEFINE p_part_code LIKE serialinfo.part_code 
	DEFINE p_ware_code LIKE serialinfo.ware_code 

	IF modu_table_exists = 'Y' THEN 
		DELETE FROM t_serialinfo 
		WHERE part_code = p_part_code 
		AND ware_code = p_ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

END FUNCTION 

FUNCTION serial_count( p_part_code, p_ware_code) 
	DEFINE p_part_code LIKE serialinfo.part_code 
	DEFINE p_ware_code LIKE serialinfo.ware_code 
	DEFINE r_cnt INTEGER 

	SELECT COUNT(*) INTO r_cnt FROM t_serialinfo 
	WHERE part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND cmpy_code = modu_cmpy 

	RETURN r_cnt 
END FUNCTION 
###########################################################################
# END FUNCTION serial_delete(p_part_code,p_ware_code)
###########################################################################