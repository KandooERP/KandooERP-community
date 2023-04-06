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
GLOBALS "../eo/E6_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E61_GLOBALS.4gl"
################################################################################
# FUNCTION proddisc_entry()
#
# E61c - Maintainence program FOR Sales Order Special Offers
#                   Product Line Discount Line Entry - (proddisc_entry)
#                 & Auto Product Line Insertion Entry - (autoprod_entry)
################################################################################
FUNCTION proddisc_entry() 
	DEFINE l_prompt char(30) 
	DEFINE l_arr_rec_proddisc DYNAMIC ARRAY OF RECORD --array[1000] OF RECORD 
		scroll_flag char(1), 
		part_code LIKE proddisc.part_code, 
		prodgrp_code LIKE proddisc.prodgrp_code, 
		maingrp_code LIKE proddisc.maingrp_code, 
		#reqd_qty LIKE proddisc.reqd_qty,
		reqd_amt LIKE proddisc.reqd_amt, 
		disc_per LIKE proddisc.disc_per, 
		unit_sale_amt LIKE proddisc.unit_sale_amt, 
		list_amt LIKE prodstatus.list_amt 
	END RECORD 
	DEFINE l_rec_proddisc RECORD 
		part_code LIKE proddisc.part_code, 
		prodgrp_code LIKE proddisc.prodgrp_code, 
		maingrp_code LIKE proddisc.maingrp_code, 
		reqd_qty LIKE proddisc.reqd_qty, 
		reqd_amt LIKE proddisc.reqd_amt, 
		disc_per LIKE proddisc.disc_per, 
		unit_sale_amt LIKE proddisc.unit_sale_amt, 
		per_amt_ind LIKE proddisc.per_amt_ind 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_part_code LIKE proddisc.part_code 
	DEFINE l_temp_code char(20) 
	DEFINE l_temp_disc FLOAT 
	DEFINE l_idx SMALLINT 
	DEFINE l_lastcol_no SMALLINT 
	DEFINE l_disc_type char(3) 

	LET l_prompt = "Special offer........" 

	DISPLAY l_prompt TO prompt attribute(white) 
	DISPLAY glob_rec_offersale.offer_code TO offer_code
	DISPLAY glob_rec_offersale.desc_text TO desc_text

	DECLARE c_proddisc cursor FOR 
	SELECT 
		part_code, 
		prodgrp_code, 
		maingrp_code, 
		reqd_qty, 
		reqd_amt, 
		disc_per, 
		unit_sale_amt, 
		per_amt_ind 
	FROM t_proddisc 
	LET l_idx = 0 

	FOREACH c_proddisc INTO l_rec_proddisc.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_proddisc[l_idx].part_code = l_rec_proddisc.part_code 
		LET l_arr_rec_proddisc[l_idx].prodgrp_code = l_rec_proddisc.prodgrp_code 
		LET l_arr_rec_proddisc[l_idx].maingrp_code = l_rec_proddisc.maingrp_code 
		LET l_arr_rec_proddisc[l_idx].disc_per = l_rec_proddisc.disc_per 
		LET l_arr_rec_proddisc[l_idx].unit_sale_amt = l_rec_proddisc.unit_sale_amt 
		IF l_rec_proddisc.part_code IS NOT NULL OR l_rec_proddisc.per_amt_ind = "A" THEN 
			LET l_arr_rec_proddisc[l_idx].list_amt = get_listamount(
				l_arr_rec_proddisc[l_idx].part_code, 
				l_arr_rec_proddisc[l_idx].prodgrp_code, 
				l_arr_rec_proddisc[l_idx].maingrp_code) 
		ELSE 
			LET l_arr_rec_proddisc[l_idx].list_amt = 0 
		END IF 

		IF glob_rec_offersale.checktype_ind = "1" THEN 
			LET l_arr_rec_proddisc[l_idx].reqd_amt = l_rec_proddisc.reqd_qty 
		ELSE 
			LET l_arr_rec_proddisc[l_idx].reqd_amt = l_rec_proddisc.reqd_amt 
		END IF 

		IF l_rec_proddisc.per_amt_ind = "P" THEN 
			LET l_arr_rec_proddisc[l_idx].unit_sale_amt = NULL 
		ELSE 
			LET l_arr_rec_proddisc[l_idx].disc_per = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	--------------------------------------

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 

	IF l_idx = 0 THEN 
		LET l_idx = 1 
	END IF 

--	CALL set_count(l_idx) 
	MESSAGE kandoomsg2("E",1004,"")	#1004 " F1 TO Insert - F2 TO Delete - ESC TO Continue"
	INPUT ARRAY l_arr_rec_proddisc WITHOUT DEFAULTS FROM sr_proddisc.* ATTRIBUTE(UNBUFFERED, insert row = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E61c","inp-arr-l_arr_rec_proddisc") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_proddisc.part_code = l_arr_rec_proddisc[l_idx].part_code 
			LET l_rec_proddisc.prodgrp_code = l_arr_rec_proddisc[l_idx].prodgrp_code 
			LET l_rec_proddisc.maingrp_code = l_arr_rec_proddisc[l_idx].maingrp_code 
			LET l_rec_proddisc.reqd_amt = l_arr_rec_proddisc[l_idx].reqd_amt 
			LET l_rec_proddisc.disc_per = l_arr_rec_proddisc[l_idx].disc_per 
			LET l_rec_proddisc.unit_sale_amt = l_arr_rec_proddisc[l_idx].unit_sale_amt 

		ON ACTION "LOOKUP" infield(part_code) 
					LET l_temp_code = show_part(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_arr_rec_proddisc[l_idx].part_code = l_temp_code clipped 
					END IF
					 
		ON ACTION "LOOKUP" infield(prodgrp_code) 
					LET l_temp_code = show_prodgrp(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_arr_rec_proddisc[l_idx].prodgrp_code = l_temp_code clipped 
					END IF 
					
		ON ACTION "LOOKUP" infield(maingrp_code) 
					LET l_temp_code = show_maingrp(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_arr_rec_proddisc[l_idx].maingrp_code = l_temp_code clipped 
					END IF 
 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f2 

--		BEFORE FIELD scroll_flag 
--			LET l_scroll_flag = l_arr_rec_proddisc[l_idx].scroll_flag 
--			DISPLAY l_arr_rec_proddisc[l_idx].* TO sr_proddisc[scrn].* 
{
		AFTER FIELD scroll_flag 
			LET l_arr_rec_proddisc[l_idx].scroll_flag = l_scroll_flag 
--			DISPLAY l_arr_rec_proddisc[l_idx].scroll_flag 
--			TO sr_proddisc[scrn].scroll_flag 

			LET l_rec_proddisc.part_code = l_arr_rec_proddisc[l_idx].part_code 
			LET l_rec_proddisc.prodgrp_code = l_arr_rec_proddisc[l_idx].prodgrp_code 
			LET l_rec_proddisc.maingrp_code = l_arr_rec_proddisc[l_idx].maingrp_code 
			LET l_rec_proddisc.reqd_amt = l_arr_rec_proddisc[l_idx].reqd_amt 
			LET l_rec_proddisc.disc_per = l_arr_rec_proddisc[l_idx].disc_per 
			LET l_rec_proddisc.unit_sale_amt = l_arr_rec_proddisc[l_idx].unit_sale_amt 
}
		BEFORE FIELD part_code 
--			DISPLAY l_arr_rec_proddisc[l_idx].* TO sr_proddisc[scrn].* 

			LET l_part_code = l_arr_rec_proddisc[l_idx].part_code 
		BEFORE DELETE 
--			INITIALIZE l_arr_rec_proddisc[l_idx].* TO NULL 
--			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			IF arr_curr() >= arr_count() THEN 
				NEXT FIELD scroll_flag 
			END IF 
			INITIALIZE l_rec_proddisc.* TO NULL 
--			INITIALIZE l_arr_rec_proddisc[l_idx].* TO NULL 
--			NEXT FIELD part_code 

		AFTER FIELD part_code 
			LET l_lastcol_no = 1 
			IF l_arr_rec_proddisc[l_idx].part_code IS NOT NULL THEN 
				SELECT unique 1 FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_arr_rec_proddisc[l_idx].part_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9010,"") 	#9010" Product does NOT Exist - Try Window"
					LET l_arr_rec_proddisc[l_idx].part_code = l_part_code 
					NEXT FIELD part_code 
				END IF 
			END IF 

		BEFORE FIELD prodgrp_code 
			IF l_arr_rec_proddisc[l_idx].part_code IS NOT NULL THEN 
				SELECT unique 1 FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_arr_rec_proddisc[l_idx].part_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9010,"") 		#9010" Product does NOT Exist - Try Window"
					NEXT FIELD part_code 
				END IF 

				IF l_part_code IS NULL THEN 
					CALL select_level(l_arr_rec_proddisc[l_idx].part_code) 
					RETURNING 
						l_arr_rec_proddisc[l_idx].part_code, 
						l_arr_rec_proddisc[l_idx].prodgrp_code, 
						l_arr_rec_proddisc[l_idx].maingrp_code 
				ELSE 
					IF l_arr_rec_proddisc[l_idx].part_code != l_part_code THEN 
						CALL select_level(l_arr_rec_proddisc[l_idx].part_code) 
						RETURNING 
							l_arr_rec_proddisc[l_idx].part_code, 
							l_arr_rec_proddisc[l_idx].prodgrp_code, 
							l_arr_rec_proddisc[l_idx].maingrp_code 
					END IF 
				END IF 

				LET l_arr_rec_proddisc[l_idx].list_amt = get_listamount(
					l_arr_rec_proddisc[l_idx].part_code, 
					l_arr_rec_proddisc[l_idx].prodgrp_code, 
					l_arr_rec_proddisc[l_idx].maingrp_code) 

				LET l_part_code = l_arr_rec_proddisc[l_idx].part_code 

				IF l_part_code IS NULL THEN 
					NEXT FIELD part_code 
				ELSE 
					NEXT FIELD reqd_amt 
				END IF 

			END IF 
			LET l_part_code = NULL 

		AFTER FIELD prodgrp_code 
			LET l_lastcol_no = 2 
			IF l_arr_rec_proddisc[l_idx].prodgrp_code IS NOT NULL THEN 
				SELECT maingrp_code INTO l_arr_rec_proddisc[l_idx].maingrp_code FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = l_arr_rec_proddisc[l_idx].prodgrp_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9011,"") 	#9011" Product Group does NOT Exist - Try Window"
					NEXT FIELD prodgrp_code 
				ELSE 
					LET l_arr_rec_proddisc[l_idx].list_amt = get_listamount(
						l_arr_rec_proddisc[l_idx].part_code, 
						l_arr_rec_proddisc[l_idx].prodgrp_code, 
						l_arr_rec_proddisc[l_idx].maingrp_code) 
				END IF 
			END IF 

		BEFORE FIELD maingrp_code 
			IF l_lastcol_no > 3 THEN 
				CASE 
					WHEN l_arr_rec_proddisc[l_idx].part_code IS NOT NULL 
						NEXT FIELD part_code 

					WHEN l_arr_rec_proddisc[l_idx].prodgrp_code IS NOT NULL 
						NEXT FIELD prodgrp_code 
				END CASE 
			END IF 

		AFTER FIELD maingrp_code 
			LET l_lastcol_no = 3 
			IF l_arr_rec_proddisc[l_idx].maingrp_code IS NULL THEN 
				ERROR kandoomsg2("I",9015,"") 		#9015" Product Main Group must be Entered"
				NEXT FIELD maingrp_code 
			ELSE 
				SELECT maingrp_code INTO l_arr_rec_proddisc[l_idx].maingrp_code FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = l_arr_rec_proddisc[l_idx].maingrp_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9012,"") 	#9012" Product Main Group does NOT Exist - Try Window"
					NEXT FIELD maingrp_code 
				END IF 
				LET l_arr_rec_proddisc[l_idx].list_amt = get_listamount(
					l_arr_rec_proddisc[l_idx].part_code, 
					l_arr_rec_proddisc[l_idx].prodgrp_code, 
					l_arr_rec_proddisc[l_idx].maingrp_code) 
			END IF 

		AFTER FIELD reqd_amt 
			LET l_lastcol_no = 5
			 
			IF l_arr_rec_proddisc[l_idx].reqd_amt IS NULL THEN 
				ERROR kandoomsg2("E",9021,"") 		#9021" Required Amount must be Entered "
				LET l_arr_rec_proddisc[l_idx].reqd_amt = 0 
				NEXT FIELD reqd_amt 
			ELSE 
				IF l_arr_rec_proddisc[l_idx].reqd_amt < 0 THEN 
					ERROR kandoomsg2("E",9022,"")			#9022" Required Amount must NOT be Negative "
					LET l_arr_rec_proddisc[l_idx].reqd_amt = 0 
					NEXT FIELD reqd_amt 
				END IF 
			END IF 
			NEXT FIELD disc_per 

		AFTER FIELD disc_per 
			CASE 
				WHEN get_is_screen_navigation_forward()
					--fgl_lastkey() = fgl_keyval("accept") 
					--OR fgl_lastkey() = fgl_keyval("RETURN") 
					--OR fgl_lastkey() = fgl_keyval("tab") 
					--OR fgl_lastkey() = fgl_keyval("right") 
					--OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_proddisc[l_idx].disc_per IS NOT NULL	AND l_arr_rec_proddisc[l_idx].unit_sale_amt IS NOT NULL THEN 
						ERROR kandoomsg2("E",9245,"") 		#9245" Only one of % OR Amount may be entered"
						NEXT FIELD disc_per 
					END IF
					 
					IF l_arr_rec_proddisc[l_idx].disc_per < 0 OR l_arr_rec_proddisc[l_idx].disc_per > 100 THEN 
						ERROR kandoomsg2("E",9034,"") 				#9034 Discount percentage must be between 0 AND 100
						NEXT FIELD disc_per 
					END IF 
					NEXT FIELD unit_sale_amt 

				WHEN NOT get_is_screen_navigation_forward() #fgl_lastkey() = fgl_keyval("up") OR fgl_lastkey() = fgl_keyval("left") 

					IF l_arr_rec_proddisc[l_idx].disc_per IS NULL	AND l_arr_rec_proddisc[l_idx].unit_sale_amt IS NULL THEN 
						ERROR kandoomsg2("E",9246,"") 		#9246" One of % OR Amount must be entered"
						NEXT FIELD disc_per 
					END IF 

					IF l_arr_rec_proddisc[l_idx].disc_per < 0 OR l_arr_rec_proddisc[l_idx].disc_per > 100 THEN 
						ERROR kandoomsg2("E",9034,"") 		#9034 Discount percentage must be between 0 AND 100
						NEXT FIELD disc_per 
					END IF 

					IF l_arr_rec_proddisc[l_idx].disc_per IS NOT NULL	AND l_arr_rec_proddisc[l_idx].unit_sale_amt IS NOT NULL THEN 
						ERROR kandoomsg2("E",9245,"") 		#9245" Only one of % OR Amount may be entered"
						NEXT FIELD disc_per 
					END IF 
					NEXT FIELD previous 
			END CASE 

		AFTER FIELD unit_sale_amt 
			CASE 
				WHEN get_is_screen_navigation_forward() 
				--fgl_lastkey() = fgl_keyval("accept") 
				--	OR fgl_lastkey() = fgl_keyval("RETURN") 
				--	OR fgl_lastkey() = fgl_keyval("tab") 
				--	OR fgl_lastkey() = fgl_keyval("right") 
				--	OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_proddisc[l_idx].disc_per IS NOT NULL	AND l_arr_rec_proddisc[l_idx].unit_sale_amt IS NOT NULL THEN 
						ERROR kandoomsg2("E",9245,"") 		#9245" Only one of % OR Amount may be entered"
						NEXT FIELD unit_sale_amt 
					END IF 
					
					IF l_arr_rec_proddisc[l_idx].disc_per IS NULL	AND l_arr_rec_proddisc[l_idx].unit_sale_amt IS NULL THEN 
						ERROR kandoomsg2("E",9246,"") 			#9246" One of % OR Amount must be entered"
						NEXT FIELD unit_sale_amt 
					END IF 
					
					IF l_arr_rec_proddisc[l_idx].unit_sale_amt < 0 THEN 
						ERROR kandoomsg2("E",9034,"") 		#9034 Discount percentage must be between 0 AND 100
						NEXT FIELD unit_sale_amt 
					END IF 
					NEXT FIELD scroll_flag
					 
				WHEN fgl_lastkey() = fgl_keyval("up")	OR fgl_lastkey() = fgl_keyval("left") 
					IF l_arr_rec_proddisc[l_idx].unit_sale_amt < 0 THEN 
						ERROR kandoomsg2("E",9034,"") 		#9034 Discount percentage must be between 0 AND 100
						NEXT FIELD unit_sale_amt 
					END IF 
					
					IF l_arr_rec_proddisc[l_idx].disc_per IS NOT NULL	AND l_arr_rec_proddisc[l_idx].unit_sale_amt IS NOT NULL THEN 
						ERROR kandoomsg2("E",9245,"") 		#9245" Only one of % OR Amount may be entered"
						NEXT FIELD unit_sale_amt 
					END IF 
					
					NEXT FIELD disc_per 
			END CASE 

--		AFTER ROW 
--			DISPLAY l_arr_rec_proddisc[l_idx].* TO sr_proddisc[scrn].* 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_proddisc.maingrp_code IS NULL THEN 
					
--						FOR l_idx = arr_curr() TO arr_count() 
--							LET l_arr_rec_proddisc[l_idx].* = l_arr_rec_proddisc[l_idx+1].* 
--							IF l_idx = arr_count() THEN 
--								INITIALIZE l_arr_rec_proddisc[l_idx].* TO NULL 
--							END IF 
--							IF scrn <= 7 THEN 
--								DISPLAY l_arr_rec_proddisc[l_idx].* TO 
--								sr_proddisc[scrn].* 
--								LET scrn = scrn + 1 
--							END IF 
--						END FOR 
--						LET scrn = scr_line() 
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_proddisc[l_idx].part_code = l_rec_proddisc.part_code 
						LET l_arr_rec_proddisc[l_idx].prodgrp_code = l_rec_proddisc.prodgrp_code 
						LET l_arr_rec_proddisc[l_idx].maingrp_code = l_rec_proddisc.maingrp_code 
						LET l_arr_rec_proddisc[l_idx].reqd_amt = l_rec_proddisc.reqd_amt 
						LET l_arr_rec_proddisc[l_idx].disc_per = l_rec_proddisc.disc_per 
						LET l_arr_rec_proddisc[l_idx].unit_sale_amt = l_rec_proddisc.unit_sale_amt 
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 

			ELSE 

				IF NOT infield(scroll_flag) THEN 
					IF l_arr_rec_proddisc[l_idx].maingrp_code IS NOT NULL THEN 
						IF l_arr_rec_proddisc[l_idx].reqd_amt IS NULL THEN 
							LET l_arr_rec_proddisc[l_idx].reqd_amt = 0 
						END IF 
					ELSE 
						ERROR kandoomsg2("I",9015,"") 		#9015" Product Main Group must be Entered"
						NEXT FIELD maingrp_code 
					END IF 
					IF l_arr_rec_proddisc[l_idx].disc_per IS NOT NULL 
					AND l_arr_rec_proddisc[l_idx].unit_sale_amt IS NOT NULL THEN 
						ERROR kandoomsg2("E",9245,"") 	#9245" Only one of % OR Amount may be entered"
						NEXT FIELD unit_sale_amt 
					END IF 

					IF l_arr_rec_proddisc[l_idx].disc_per IS NULL	AND l_arr_rec_proddisc[l_idx].unit_sale_amt IS NULL THEN 
						ERROR kandoomsg2("E",9246,"") 	#9246" One of % OR Amount must be entered"
						NEXT FIELD unit_sale_amt 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
	ELSE 
		DELETE FROM t_proddisc 
		
		FOR l_idx = 1 TO arr_count() ------------------------------------------------------------ 
			IF l_arr_rec_proddisc[l_idx].maingrp_code IS NOT NULL THEN 
			
				IF glob_rec_offersale.checktype_ind = "1" THEN 
					LET l_rec_proddisc.reqd_qty = l_arr_rec_proddisc[l_idx].reqd_amt 
					LET l_rec_proddisc.reqd_amt = NULL 
				ELSE 
					LET l_rec_proddisc.reqd_amt = l_arr_rec_proddisc[l_idx].reqd_amt 
					LET l_rec_proddisc.reqd_qty = NULL 
				END IF 

				IF l_arr_rec_proddisc[l_idx].disc_per IS NOT NULL THEN 
					LET l_rec_proddisc.per_amt_ind = 'P' 
				ELSE 
					LET l_rec_proddisc.per_amt_ind = 'A' 
					
					IF l_arr_rec_proddisc[l_idx].list_amt = 0 THEN 
						LET l_arr_rec_proddisc[l_idx].disc_per = 0 
					ELSE 
						LET l_temp_disc = 100 - ((l_arr_rec_proddisc[l_idx].unit_sale_amt	/ l_arr_rec_proddisc[l_idx].list_amt) * 100) 
						IF l_temp_disc < 0 THEN 
							LET l_arr_rec_proddisc[l_idx].disc_per = 0 
						ELSE 
							LET l_arr_rec_proddisc[l_idx].disc_per = l_temp_disc 
						END IF 
					END IF 
				END IF 

				INSERT INTO t_proddisc VALUES (
					l_arr_rec_proddisc[l_idx].maingrp_code, 
					l_arr_rec_proddisc[l_idx].prodgrp_code, 
					l_arr_rec_proddisc[l_idx].part_code, 
					l_rec_proddisc.reqd_amt, 
					l_rec_proddisc.reqd_qty, 
					l_arr_rec_proddisc[l_idx].disc_per, 
					l_arr_rec_proddisc[l_idx].unit_sale_amt, 
					l_rec_proddisc.per_amt_ind) 
			END IF 
		END FOR ---------------------------------------------------------
	END IF 

END FUNCTION 
################################################################################
# END FUNCTION proddisc_entry()
################################################################################


################################################################################
# FUNCTION get_listamount(p_part_code1,p_prodgrp_code,p_maingrp_code)
#
#
################################################################################
FUNCTION get_listamount(p_part_code1,p_prodgrp_code,p_maingrp_code) 
	DEFINE p_part_code1 LIKE proddisc.part_code 
	DEFINE p_prodgrp_code LIKE proddisc.prodgrp_code 
	DEFINE p_maingrp_code LIKE proddisc.maingrp_code 
	DEFINE l_rec_inparms RECORD LIKE inparms.* 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_list_amt LIKE prodstatus.list_amt 

	CALL db_inparms_get_rec(UI_OFF,"1") RETURNING l_rec_inparms.* 

	IF p_part_code1 IS NOT NULL THEN 
		SELECT list_amt INTO l_list_amt FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code1 
		AND ware_code = l_rec_inparms.mast_ware_code 
		IF status = NOTFOUND THEN 
			LET l_list_amt = 0 
		END IF 
	ELSE 
		IF p_prodgrp_code IS NOT NULL THEN 
			SELECT min(list_amt) INTO l_list_amt 
			FROM prodstatus,product 
			WHERE product.prodgrp_code = p_prodgrp_code 
			AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND prodstatus.part_code = product.part_code 
			AND prodstatus.ware_code = l_rec_inparms.mast_ware_code 
		ELSE 
			IF p_maingrp_code IS NOT NULL THEN 
				SELECT min(list_amt) INTO l_list_amt 
				FROM prodstatus,product 
				WHERE product.maingrp_code = p_maingrp_code 
				AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodstatus.part_code = product.part_code 
				AND prodstatus.ware_code = l_rec_inparms.mast_ware_code 
			END IF 
		END IF 
	END IF 

	RETURN l_list_amt 
END FUNCTION 
################################################################################
# END FUNCTION get_listamount(p_part_code1,p_prodgrp_code,p_maingrp_code)
################################################################################


################################################################################
# FUNCTION auto_proddisc()
#
#
################################################################################
FUNCTION auto_proddisc() 
	DEFINE l_rec_proddisc RECORD LIKE proddisc.* 
	DEFINE l_rec_offerprod RECORD 
		part_code LIKE proddisc.part_code, 
		prodgrp_code LIKE proddisc.prodgrp_code, 
		maingrp_code LIKE proddisc.maingrp_code 
	END RECORD 
	DEFINE l_disc_type char(3) 
	DEFINE l_reqd_amt LIKE proddisc.reqd_amt 
	DEFINE l_disc_per LIKE proddisc.disc_per 
	DEFINE l_unit_sale_amt LIKE proddisc.unit_sale_amt 
	DEFINE l_exit INTEGER 

	CALL enter_defaults() 
	RETURNING 
		l_reqd_amt, 
		l_rec_proddisc.disc_per, 
		l_rec_proddisc.unit_sale_amt, 
		l_exit 
	IF l_exit THEN 
		RETURN FALSE 
	END IF 

	IF glob_rec_offersale.checktype_ind = "1" THEN 
		LET l_rec_proddisc.reqd_qty = l_reqd_amt 
		LET l_rec_proddisc.reqd_amt = NULL 
	ELSE 
		LET l_rec_proddisc.reqd_amt = l_reqd_amt 
		LET l_rec_proddisc.reqd_qty = NULL 
	END IF 

	IF l_rec_proddisc.disc_per IS NOT NULL THEN 
		LET l_rec_proddisc.per_amt_ind = 'P' 
	ELSE 
		LET l_rec_proddisc.per_amt_ind = 'A' 
	END IF 

	DECLARE c_offerprod cursor FOR 
	SELECT part_code,prodgrp_code,maingrp_code FROM t_offerprod 

	------------------------------------------

	FOREACH c_offerprod INTO l_rec_offerprod.* 
		IF l_rec_offerprod.part_code IS NOT NULL THEN 
			SELECT unique 1 FROM t_proddisc 
			WHERE part_code = l_rec_offerprod.part_code 
			IF status = NOTFOUND THEN 
				LET l_rec_proddisc.part_code = l_rec_offerprod.part_code 
				LET l_rec_proddisc.prodgrp_code = l_rec_offerprod.prodgrp_code 
				LET l_rec_proddisc.maingrp_code = l_rec_offerprod.maingrp_code 
				INSERT INTO t_proddisc 
				VALUES (
					l_rec_proddisc.maingrp_code, 
					l_rec_proddisc.prodgrp_code, 
					l_rec_proddisc.part_code, 
					l_rec_proddisc.reqd_amt, 
					l_rec_proddisc.reqd_qty, 
					l_rec_proddisc.disc_per, 
					l_rec_proddisc.unit_sale_amt, 
					l_rec_proddisc.per_amt_ind) 
			END IF 

		ELSE 

			IF l_rec_offerprod.prodgrp_code IS NOT NULL THEN 
				SELECT unique 1 FROM t_proddisc 
				WHERE prodgrp_code = l_rec_offerprod.prodgrp_code 
				IF status = NOTFOUND THEN 
					LET l_rec_proddisc.part_code = l_rec_offerprod.part_code 
					LET l_rec_proddisc.prodgrp_code = l_rec_offerprod.prodgrp_code 
					LET l_rec_proddisc.maingrp_code = l_rec_offerprod.maingrp_code 

					INSERT INTO t_proddisc 
					VALUES (
						l_rec_proddisc.maingrp_code, 
						l_rec_proddisc.prodgrp_code, 
						l_rec_proddisc.part_code, 
						l_rec_proddisc.reqd_amt, 
						l_rec_proddisc.reqd_qty, 
						l_rec_proddisc.disc_per, 
						l_rec_proddisc.unit_sale_amt, 
						l_rec_proddisc.per_amt_ind) 
				END IF 

			ELSE 

				IF l_rec_offerprod.maingrp_code IS NOT NULL THEN 
					SELECT unique 1 FROM t_proddisc 
					WHERE maingrp_code = l_rec_offerprod.maingrp_code 
					IF status = NOTFOUND THEN 
						LET l_rec_proddisc.part_code = l_rec_offerprod.part_code 
						LET l_rec_proddisc.prodgrp_code = l_rec_offerprod.prodgrp_code 
						LET l_rec_proddisc.maingrp_code = l_rec_offerprod.maingrp_code 

						INSERT INTO t_proddisc 
						VALUES (
							l_rec_proddisc.maingrp_code, 
							l_rec_proddisc.prodgrp_code, 
							l_rec_proddisc.part_code, 
							l_rec_proddisc.reqd_amt, 
							l_rec_proddisc.reqd_qty, 
							l_rec_proddisc.disc_per, 
							l_rec_proddisc.unit_sale_amt, 
							l_rec_proddisc.per_amt_ind) 
					END IF 
				END IF 
			END IF 
		END IF 
	END FOREACH 
	-------------------------------------------------

	RETURN TRUE 
END FUNCTION 

################################################################################
# END FUNCTION auto_proddisc()
################################################################################


################################################################################
# FUNCTION enter_defaults()
#
#
################################################################################
FUNCTION enter_defaults() 
	DEFINE l_rec_proddisc RECORD LIKE proddisc.* 
	DEFINE l_disc_type char(3) 
	DEFINE l_reqd_amt LIKE proddisc.reqd_amt 
	DEFINE l_disc_per LIKE proddisc.disc_per 
	DEFINE l_unit_sale_amt LIKE proddisc.unit_sale_amt
	DEFINE l_exit INTEGER 

	OPEN WINDOW E295 with FORM "E295" 
	 CALL windecoration_e("E295") 

	CLEAR FORM 

	IF glob_rec_offersale.checktype_ind = "1" THEN 
		LET l_disc_type = "Qty" 
	ELSE 
		LET l_disc_type = "Amt" 
	END IF 

	DISPLAY l_disc_type TO disc_type 


	INPUT BY NAME 
		l_rec_proddisc.reqd_amt, 
		l_rec_proddisc.disc_per, 
		l_rec_proddisc.unit_sale_amt ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E61c","inp-l_arr_rec_proddisc") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD reqd_amt 
			IF l_rec_proddisc.reqd_amt IS NULL THEN 
				ERROR kandoomsg2("E",9021,"") #9021" Required Amount must be Entered "
				NEXT FIELD reqd_amt 
			END IF 

		BEFORE FIELD disc_per
			IF l_rec_proddisc.unit_sale_amt IS NOT NULL THEN
				ERROR kandoomsg2("E",9245,"") 		#9245" Only one of % OR Amount may be entered"
				NEXT FIELD unit_sale_amt
			END IF

		AFTER FIELD disc_per 
			IF l_rec_proddisc.disc_per IS NOT NULL AND l_rec_proddisc.unit_sale_amt IS NOT NULL THEN 
				ERROR kandoomsg2("E",9245,"") 	#9245" Only one of % OR Amount may be entered"
				NEXT FIELD disc_per 
			END IF 

			IF l_rec_proddisc.disc_per < 0 OR l_rec_proddisc.disc_per > 100 THEN 
				ERROR kandoomsg2("E",9034,"") 		#9034 Discount percentage must be between 0 AND 100
				NEXT FIELD disc_per 
			END IF 

		BEFORE FIELD unit_sale_amt
			IF l_rec_proddisc.disc_per IS NOT NULL THEN
				ERROR kandoomsg2("E",9245,"") 		#9245" Only one of % OR Amount may be entered"
				NEXT FIELD disc_per
			END IF
			
		AFTER FIELD unit_sale_amt 
			IF l_rec_proddisc.disc_per IS NOT NULL AND l_rec_proddisc.unit_sale_amt IS NOT NULL THEN 
				ERROR kandoomsg2("E",9245,"") 		#9245" Only one of % OR Amount may be entered"
				NEXT FIELD unit_sale_amt 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_proddisc.reqd_amt IS NULL THEN 
					ERROR kandoomsg2("E",9021,"") 		#9021" Required Amount must be Entered "
					NEXT FIELD reqd_amt 
				END IF 
				
				IF l_rec_proddisc.disc_per IS NOT NULL AND l_rec_proddisc.unit_sale_amt IS NOT NULL THEN 
					ERROR kandoomsg2("E",9245,"") 		#9245" Only one of % OR Amount may be entered"
					NEXT FIELD unit_sale_amt 
				END IF
				 
				IF l_rec_proddisc.disc_per IS NULL AND l_rec_proddisc.unit_sale_amt IS NULL THEN 
					ERROR kandoomsg2("E",9246,"") 		#9246" One of % OR Amount may be entered"
					NEXT FIELD unit_sale_amt 
				END IF
				 
				IF l_rec_proddisc.disc_per < 0 OR l_rec_proddisc.disc_per > 100 THEN 
					ERROR kandoomsg2("E",9034,"") 			#9034 Discount percentage must be between 0 AND 100
					NEXT FIELD disc_per 
				END IF 
			END IF 

	END INPUT 

	-----------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET l_exit = TRUE 
	END IF 

	CLOSE WINDOW E295 

	RETURN l_rec_proddisc.reqd_amt, 
	l_rec_proddisc.disc_per, 
	l_rec_proddisc.unit_sale_amt, 
	l_exit 
END FUNCTION 
