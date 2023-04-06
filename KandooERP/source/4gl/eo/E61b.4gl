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
###########################################################################
# FUNCTION lineitem_entry(p_type_ind)
#
# E61b - Maintainence program FOR Sales Order Special Offers
#                   Products TO be Sold Line Entry
###########################################################################
FUNCTION lineitem_entry(p_type_ind) 
	DEFINE p_type_ind LIKE offerprod.type_ind 
	DEFINE l_arr_rec_offerprod DYNAMIC ARRAY OF RECORD --array[1020] OF RECORD 
		part_code LIKE offerprod.part_code, 
		prodgrp_code LIKE offerprod.prodgrp_code, 
		maingrp_code LIKE offerprod.maingrp_code, 
		reqd_qty LIKE offerprod.reqd_qty, 
		reqd_amt LIKE offerprod.reqd_amt 
	END RECORD 
	DEFINE l_part_code_previous LIKE offerprod.part_code 
	DEFINE l_temp_code char(20) 
	DEFINE l_idx SMALLINT 
	DEFINE l_counter SMALLINT
	DEFINE l_lastcol_no SMALLINT 
	DEFINE l_valid_maingrp_code SMALLINT

	DISPLAY glob_rec_offersale.offer_code TO offer_code 
	DISPLAY glob_rec_offersale.desc_text TO desc_text

	DECLARE c_offerprod cursor FOR 
	SELECT 
		part_code, 
		prodgrp_code, 
		maingrp_code, 
		reqd_qty, 
		reqd_amt 
	FROM t_offerprod 
	WHERE type_ind = p_type_ind 

	LET l_idx = 1 
	FOREACH c_offerprod INTO l_arr_rec_offerprod[l_idx].* 
		IF glob_rec_offersale.checktype_ind = "1" THEN 
			LET l_arr_rec_offerprod[l_idx].reqd_amt = NULL 
		ELSE 
			LET l_arr_rec_offerprod[l_idx].reqd_qty = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
		  MESSAGE kandoomsg2("U",6100,l_idx)
		  EXIT FOREACH
		END IF

		LET l_idx = l_idx + 1 
	END FOREACH 
	LET l_idx = l_arr_rec_offerprod.getSize()
	
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
 
	MESSAGE kandoomsg2("E",1004,"") #" F1 TO Insert - F2 TO Delete - ESC TO Continue"
	INPUT ARRAY l_arr_rec_offerprod WITHOUT DEFAULTS FROM sr_offerprod.* ATTRIBUTE(UNBUFFERED, insert row = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E61b","inp-arr-l_arr_rec_offerprod") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			--NEXT FIELD part_code 

		BEFORE INSERT 
			--INITIALIZE l_arr_rec_offerprod[l_idx].* TO NULL 
			--NEXT FIELD part_code 

		AFTER INSERT
		#nothing 

		BEFORE DELETE 
			--INITIALIZE l_arr_rec_offerprod[l_idx].* TO NULL 
			--NEXT FIELD part_code 

		AFTER DELETE
		#nothing 

		AFTER ROW 
			IF l_arr_rec_offerprod[l_idx].maingrp_code IS NOT NULL THEN 
				IF glob_rec_offersale.checktype_ind = "1" AND l_arr_rec_offerprod[l_idx].reqd_qty IS NULL THEN 
					LET l_arr_rec_offerprod[l_idx].reqd_qty = 0 
				END IF 
				IF glob_rec_offersale.checktype_ind = "2" AND l_arr_rec_offerprod[l_idx].reqd_amt IS NULL THEN 
					LET l_arr_rec_offerprod[l_idx].reqd_amt = 0 
				END IF 
			END IF 

			IF fgl_lastkey() != fgl_keyval("delete") THEN 
				LET l_arr_rec_offerprod[l_idx].part_code = l_part_code_previous 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(part_code) 
					LET l_temp_code = show_part(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_arr_rec_offerprod[l_idx].part_code = l_temp_code clipped 
					END IF 
					
		ON ACTION "LOOKUP" infield(prodgrp_code) 
					LET l_temp_code = show_prodgrp(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_arr_rec_offerprod[l_idx].prodgrp_code = l_temp_code clipped 
					END IF 
					
		ON ACTION "LOOKUP" infield(maingrp_code) 
					LET l_temp_code = show_maingrp(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_arr_rec_offerprod[l_idx].maingrp_code = l_temp_code clipped 
					END IF 

		BEFORE FIELD part_code 
 
			LET l_part_code_previous = l_arr_rec_offerprod[l_idx].part_code 

			IF l_arr_rec_offerprod[l_idx].maingrp_code IS NOT NULL THEN 
				LET l_valid_maingrp_code = TRUE 
			ELSE 
				LET l_valid_maingrp_code = FALSE 
			END IF 

		AFTER FIELD part_code 
			LET l_lastcol_no = 1 
			IF l_arr_rec_offerprod[l_idx].part_code IS NOT NULL THEN 
				SELECT unique 1 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_arr_rec_offerprod[l_idx].part_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9010,"") 	#9010" Product does NOT Exist - Try Window"
					LET l_arr_rec_offerprod[l_idx].part_code = l_part_code_previous 
					NEXT FIELD part_code 
				END IF 
			END IF 

		BEFORE FIELD prodgrp_code 
			OPTIONS INSERT KEY f36 
 			CALL dialog.setActionHidden("APPEND",TRUE)
			IF l_arr_rec_offerprod[l_idx].part_code IS NOT NULL THEN 
				SELECT unique 1 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_arr_rec_offerprod[l_idx].part_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9010,"") 	#9010" Product does NOT Exist - Try Window"
					CALL dialog.setActionHidden("APPEND",FALSE)
					NEXT FIELD part_code 
				END IF 

				IF l_part_code_previous IS NULL THEN 
					CALL select_level(l_arr_rec_offerprod[l_idx].part_code) 
					RETURNING 
						l_arr_rec_offerprod[l_idx].part_code, 
						l_arr_rec_offerprod[l_idx].prodgrp_code, 
						l_arr_rec_offerprod[l_idx].maingrp_code 

					FOR l_counter = 1 TO arr_count() 
						IF (l_arr_rec_offerprod[l_idx].maingrp_code = l_arr_rec_offerprod[l_counter].maingrp_code 
						AND l_arr_rec_offerprod[l_idx].prodgrp_code = l_arr_rec_offerprod[l_counter].prodgrp_code 
						AND l_arr_rec_offerprod[l_counter].part_code IS NULL 
						AND l_arr_rec_offerprod[l_idx].part_code IS NULL 
						AND l_idx != l_counter) OR (l_arr_rec_offerprod[l_idx].maingrp_code = l_arr_rec_offerprod[l_counter].maingrp_code 
						AND l_arr_rec_offerprod[l_idx].prodgrp_code IS NULL 
						AND l_arr_rec_offerprod[l_counter].prodgrp_code IS NULL 
						AND l_arr_rec_offerprod[l_idx].part_code IS NULL 
						AND l_arr_rec_offerprod[l_counter].part_code IS NULL 
						AND l_idx != l_counter) OR (l_arr_rec_offerprod[l_idx].part_code 	= l_arr_rec_offerprod[l_counter].part_code 
						AND l_arr_rec_offerprod[l_counter].maingrp_code = l_arr_rec_offerprod[l_idx].maingrp_code 
						AND l_arr_rec_offerprod[l_counter].prodgrp_code = l_arr_rec_offerprod[l_idx].prodgrp_code 
						AND l_idx != l_counter) THEN 
							ERROR kandoomsg2("U",9104,"") 	#9104 RECORD already exists.
--							INITIALIZE l_arr_rec_offerprod[l_idx].* TO NULL
							CALL dialog.setActionHidden("APPEND",FALSE) 
							NEXT FIELD part_code 
						END IF 
					END FOR 

				ELSE 

					IF l_arr_rec_offerprod[l_idx].part_code != l_part_code_previous THEN 
						CALL select_level(l_arr_rec_offerprod[l_idx].part_code) 
						RETURNING 
							l_arr_rec_offerprod[l_idx].part_code, 
							l_arr_rec_offerprod[l_idx].prodgrp_code, 
							l_arr_rec_offerprod[l_idx].maingrp_code 
					END IF 
				END IF 


				FOR l_counter = 1 TO arr_count() 
					IF (l_arr_rec_offerprod[l_idx].prodgrp_code = l_arr_rec_offerprod[l_counter].prodgrp_code 
					AND l_arr_rec_offerprod[l_idx].maingrp_code = l_arr_rec_offerprod[l_counter].maingrp_code 
					AND l_arr_rec_offerprod[l_idx].part_code IS null) 
					AND l_idx != l_counter THEN 
						ERROR kandoomsg2("U",9104,"") 	#9104 RECORD already exists.
						NEXT FIELD prodgrp_code 
					END IF 
				END FOR 

				LET l_part_code_previous = l_arr_rec_offerprod[l_idx].part_code 
				IF l_arr_rec_offerprod[l_idx].prodgrp_code IS NOT NULL OR l_arr_rec_offerprod[l_idx].maingrp_code IS NOT NULL THEN 
					IF glob_rec_offersale.checktype_ind = 1 THEN 
						NEXT FIELD reqd_qty 
					ELSE 
						NEXT FIELD reqd_amt 
					END IF 
				END IF				
			END IF 
			LET l_part_code_previous = NULL 

		AFTER FIELD prodgrp_code 
			LET l_lastcol_no = 2 
			IF l_arr_rec_offerprod[l_idx].prodgrp_code IS NOT NULL THEN 
				SELECT maingrp_code 
				INTO l_arr_rec_offerprod[l_idx].maingrp_code 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = l_arr_rec_offerprod[l_idx].prodgrp_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9011,"") 	#9011" Product Group does NOT Exist - Try Window"
					NEXT FIELD prodgrp_code 
				ELSE 

					FOR l_counter = 1 TO arr_count() 
						IF (l_arr_rec_offerprod[l_idx].prodgrp_code = l_arr_rec_offerprod[l_counter].prodgrp_code 
						AND l_arr_rec_offerprod[l_idx].maingrp_code = l_arr_rec_offerprod[l_counter].maingrp_code) 
						AND (l_arr_rec_offerprod[l_counter].part_code IS null) 
						AND (l_idx != l_counter) THEN 
							ERROR kandoomsg2("U",9104,"") 	#9104 RECORD already exists.
							INITIALIZE l_arr_rec_offerprod[l_idx].* TO NULL 
							NEXT FIELD prodgrp_code 
						END IF 
					END FOR 

				END IF 
			ELSE 

			END IF 

		BEFORE FIELD maingrp_code 
			IF l_lastcol_no > 3 THEN 

				CASE 
					WHEN l_arr_rec_offerprod[l_idx].part_code IS NOT NULL 
						NEXT FIELD part_code 
					WHEN l_arr_rec_offerprod[l_idx].prodgrp_code IS NOT NULL 
						NEXT FIELD prodgrp_code 
				END CASE 

			ELSE 
				IF l_arr_rec_offerprod[l_idx].prodgrp_code IS NOT NULL THEN 
					SELECT maingrp_code 
					INTO l_arr_rec_offerprod[l_idx].maingrp_code 
					FROM prodgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND prodgrp_code = l_arr_rec_offerprod[l_idx].prodgrp_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("I",9011,"") 		#9011" Product Group does NOT Exist - Try Window"
						NEXT FIELD prodgrp_code 
					ELSE 
						NEXT FIELD reqd_qty 
					END IF 

				ELSE 

					IF l_arr_rec_offerprod[l_idx].maingrp_code IS NOT NULL AND l_valid_maingrp_code THEN 
						IF glob_rec_offersale.checktype_ind = 1 THEN 
							NEXT FIELD reqd_qty 
						ELSE 
							NEXT FIELD reqd_amt 
						END IF 
					END IF 
				END IF 

			END IF 

		AFTER FIELD maingrp_code 
			LET l_lastcol_no = 3 
			IF l_arr_rec_offerprod[l_idx].maingrp_code IS NULL THEN 
				ERROR kandoomsg2("I",9015,"") 	#9015" Product Main Group must be Entered"
				NEXT FIELD maingrp_code 
			ELSE 
				SELECT maingrp_code 
				INTO l_arr_rec_offerprod[l_idx].maingrp_code 
				FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = l_arr_rec_offerprod[l_idx].maingrp_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9012,"")#9012" Product Main Group does NOT Exist - Try Window"
					NEXT FIELD maingrp_code 
				END IF 

				FOR l_counter = 1 TO arr_count() 
					IF (l_arr_rec_offerprod[l_idx].maingrp_code = l_arr_rec_offerprod[l_counter].maingrp_code 
					AND l_arr_rec_offerprod[l_counter].prodgrp_code IS NULL 
					AND l_arr_rec_offerprod[l_idx].prodgrp_code IS NULL 
					AND l_idx != l_counter) 
					OR (l_arr_rec_offerprod[l_idx].maingrp_code = l_arr_rec_offerprod[l_counter].maingrp_code 
					AND l_arr_rec_offerprod[l_counter].prodgrp_code	= l_arr_rec_offerprod[l_idx].prodgrp_code 
					AND l_idx != l_counter) THEN 
						ERROR kandoomsg2("U",9104,"")		#9104 RECORD already exists.
						LET l_valid_maingrp_code = FALSE 
						NEXT FIELD maingrp_code 
					END IF 
				END FOR 

				LET l_valid_maingrp_code = TRUE 
			END IF 

		BEFORE FIELD reqd_qty 
			IF glob_rec_offersale.checktype_ind = "2" THEN 
				IF l_lastcol_no > 4 THEN 
					NEXT FIELD maingrp_code 
				ELSE 
					NEXT FIELD reqd_amt 
				END IF 
			END IF 

		AFTER FIELD reqd_qty 
			IF NOT get_is_screen_navigation_forward() THEN
			--IF fgl_lastkey() = fgl_keyval("up") 
			--OR fgl_lastkey() = fgl_keyval("down") THEN 
				NEXT FIELD reqd_qty 
			END IF
			 
			LET l_lastcol_no = 4
			 
			IF l_arr_rec_offerprod[l_idx].reqd_qty IS NULL THEN 
				ERROR kandoomsg2("E",9019,"") 	#9019" Required Quantity must be Entered "
				LET l_arr_rec_offerprod[l_idx].reqd_qty = 0 
				NEXT FIELD reqd_qty 
			ELSE 
				IF l_arr_rec_offerprod[l_idx].reqd_qty < 0 THEN 
					ERROR kandoomsg2("E",9020,"")	#9020" Required Quantity must NOT be Negative "
					LET l_arr_rec_offerprod[l_idx].reqd_qty = 0 
					NEXT FIELD reqd_qty 
				END IF 
			END IF 

		BEFORE FIELD reqd_amt 
			IF glob_rec_offersale.checktype_ind = "1" THEN 
				IF l_lastcol_no > 4 THEN 
					NEXT FIELD maingrp_code 
				ELSE 
					IF l_arr_rec_offerprod[l_idx].reqd_qty IS NOT NULL THEN 
						NEXT FIELD NEXT 
					ELSE 
						NEXT FIELD reqd_qty 
					END IF 
				END IF 
			END IF 

		AFTER FIELD reqd_amt 
			IF NOT get_is_screen_navigation_forward() THEN
			--IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD reqd_amt 
			END IF 
			
			LET l_lastcol_no = 5 
			IF l_arr_rec_offerprod[l_idx].reqd_amt IS NULL THEN 
				ERROR kandoomsg2("E",9021,"") 	#9021" Required Amount must be Entered "
				LET l_arr_rec_offerprod[l_idx].reqd_amt = 0 
				NEXT FIELD reqd_amt 
			ELSE 
				IF l_arr_rec_offerprod[l_idx].reqd_amt < 0 THEN 
					ERROR kandoomsg2("E",9022,"")		#9022" Required Amount must NOT be Negative "
					LET l_arr_rec_offerprod[l_idx].reqd_amt = 0 
					NEXT FIELD reqd_amt 
				END IF 
			END IF 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
	ELSE 
		DELETE FROM t_offerprod 
		WHERE type_ind = p_type_ind 

		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_offerprod[l_idx].maingrp_code IS NOT NULL THEN 
				INSERT INTO t_offerprod 
				VALUES (
					p_type_ind, 
					l_arr_rec_offerprod[l_idx].maingrp_code, 
					l_arr_rec_offerprod[l_idx].prodgrp_code, 
					l_arr_rec_offerprod[l_idx].part_code, 
					l_arr_rec_offerprod[l_idx].reqd_amt, 
					l_arr_rec_offerprod[l_idx].reqd_qty) 
			END IF 
		END FOR 

	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION lineitem_entry(p_type_ind)
###########################################################################


################################################################################
# FUNCTION select_level(p_part_code)
#
#
################################################################################
FUNCTION select_level(p_part_code) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_prodgrp_text LIKE prodgrp.desc_text 
	DEFINE l_maingrp_text LIKE maingrp.desc_text 

	SELECT 
		x.part_code, 
		x.desc_text, 
		x.prodgrp_code, 
		y.desc_text, 
		x.maingrp_code, 
		z.desc_text 
	INTO 
		l_rec_product.part_code, 
		l_rec_product.desc_text, 
		l_rec_product.prodgrp_code, 
		l_prodgrp_text, 
		l_rec_product.maingrp_code, 
		l_maingrp_text 
	FROM 
		product x, 
		prodgrp y, 
		maingrp z 
	WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND z.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND x.part_code = p_part_code 
	AND y.prodgrp_code = x.prodgrp_code 
	AND z.maingrp_code = x.maingrp_code 
	IF status = NOTFOUND THEN 
		LET l_rec_product.part_code = NULL 
		LET l_rec_product.prodgrp_code = NULL 
		LET l_rec_product.maingrp_code = NULL 
	ELSE 

		OPEN WINDOW E106 with FORM "E106" 
		 CALL windecoration_e("E106") 

		DISPLAY 
			l_rec_product.part_code, 
			l_rec_product.desc_text, 
			l_rec_product.prodgrp_code, 
			l_prodgrp_text, 
			l_rec_product.maingrp_code, 
			l_maingrp_text 
		TO
			part_code, 
			desc_text, 
			prodgrp_code, 
			prodgrp_text, 
			maingrp_code, 
			maingrp_text 
		
		-------------------------------------

		MENU "Product selection" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","E61b","menu-product_selection") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Product" 	#COMMAND "Product"                 " SELECT this individual product"
				EXIT MENU 

			ON ACTION "Product group"	#COMMAND "Product Group"                 " SELECT product group"
				LET l_rec_product.part_code = NULL 
				EXIT MENU 

			ON ACTION "Main group"	#COMMAND "Main Group"                 " SELECT entire product main group"
				LET l_rec_product.part_code = NULL 
				LET l_rec_product.prodgrp_code = NULL 
				EXIT MENU 

			ON ACTION "Exit" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO entry SCREEN"
				LET l_rec_product.part_code = NULL 
				LET l_rec_product.prodgrp_code = NULL 
				LET l_rec_product.maingrp_code = NULL 
				EXIT MENU 

		END MENU 

		----------------------------------------

		CLOSE WINDOW E106 
	END IF 

	RETURN 
		l_rec_product.part_code, 
		l_rec_product.prodgrp_code, 
		l_rec_product.maingrp_code 
END FUNCTION 
################################################################################
# END FUNCTION select_level(p_part_code)
################################################################################