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
# MODULE Scope Variables
###########################################################################
DEFINE modu_arr_rec_offerauto DYNAMIC ARRAY OF RECORD --array[500] OF RECORD 
	scroll_flag char(1), 
	part_code LIKE offerauto.part_code, 
	desc_text LIKE product.desc_text, 
	sold_qty LIKE offerauto.sold_qty, 
	bonus_qty LIKE offerauto.bonus_qty 
END RECORD 
DEFINE modu_rec_inparms RECORD LIKE inparms.* 
################################################################################
# FUNCTION disp_autoprod()
#
# E61d - Maintainence program FOR Sales Order Special Offers
#        Automatic Product Insertion.
################################################################################
FUNCTION disp_autoprod() 
	DEFINE l_idx SMALLINT 

	DECLARE c_offerauto cursor FOR 
	SELECT part_code, 
	sold_qty, 
	bonus_qty 
	FROM t_offerauto 
	ORDER BY part_code 

	FOR l_idx = 1 TO 500 
		INITIALIZE modu_arr_rec_offerauto[l_idx].* TO NULL 
	END FOR 

	LET l_idx = 1 
	FOREACH c_offerauto INTO modu_arr_rec_offerauto[l_idx].part_code, 
		modu_arr_rec_offerauto[l_idx].sold_qty, 
		modu_arr_rec_offerauto[l_idx].bonus_qty 
		LET modu_arr_rec_offerauto[l_idx].scroll_flag = NULL 
		SELECT desc_text 
		INTO modu_arr_rec_offerauto[l_idx].desc_text 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = modu_arr_rec_offerauto[l_idx].part_code 
		IF l_idx = 500 THEN 
			EXIT FOREACH 
		END IF 
		IF l_idx <= 5 THEN 
			DISPLAY modu_arr_rec_offerauto[l_idx].* 
			TO sr_offerauto[l_idx].* 

		END IF 
		LET l_idx = l_idx + 1 
	END FOREACH 

	----------------------------------------------------

	CALL disp_cnt() 
END FUNCTION 


################################################################################
# FUNCTION scan_groups()
#
#
################################################################################
FUNCTION scan_groups() 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_offerauto RECORD LIKE offerauto.* 
	DEFINE l_sold_qty LIKE offerauto.sold_qty 
	DEFINE l_bonus_qty LIKE offerauto.bonus_qty 
	DEFINE l_part_text LIKE product.desc_text 
	DEFINE l_prodgrp_text LIKE prodgrp.desc_text 
	DEFINE l_maingrp_text LIKE maingrp.desc_text 
	DEFINE l_serial_flag LIKE product.serial_flag 
	DEFINE l_temp_code char(20) 
	DEFINE l_query_text STRING 
	DEFINE l_lastcol_no SMALLINT 

	INPUT 
		l_rec_product.part_code, 
		l_rec_product.prodgrp_code, 
		l_rec_product.maingrp_code, 
		l_sold_qty, 
		l_bonus_qty WITHOUT DEFAULTS 
	FROM
		part_code, 
		prodgrp_code, 
		maingrp_code, 
		sold_qty, 
		bonus_qty ATTRIBUTE(UNBUFFERED) 
	
		BEFORE INPUT 
			CLEAR l_part_text, 
			l_prodgrp_text, 
			l_maingrp_text 

			CALL publish_toolbar("kandoo","E61d","inp-l_rec_product") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(part_code) 
					LET l_temp_code = show_part(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_rec_product.part_code = l_temp_code clipped 
						NEXT FIELD part_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(prodgrp_code) 
					LET l_temp_code = show_prodgrp(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_rec_product.prodgrp_code = l_temp_code clipped 
						NEXT FIELD prodgrp_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(maingrp_code) 
					LET l_temp_code = show_maingrp(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_rec_product.maingrp_code = l_temp_code 
						NEXT FIELD maingrp_code 
					END IF 
 

		AFTER FIELD part_code 
			LET l_lastcol_no = 1 
			CLEAR l_part_text 
			IF l_rec_product.part_code IS NOT NULL THEN 
				SELECT desc_text, serial_flag 
				INTO l_part_text, l_serial_flag 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_product.part_code
				 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9162,"") 				#9010" Product does NOT Exist - Try Window"
					NEXT FIELD part_code 
				END IF
				 
				IF l_serial_flag = 'Y' THEN 
					ERROR kandoomsg2("I",9285,"") 				#9285 Serial Items can NOT be used.
					NEXT FIELD part_code 
				END IF 
				
				CALL select_level(l_rec_product.part_code) 
				RETURNING l_rec_product.part_code, 
				l_rec_product.prodgrp_code, 
				l_rec_product.maingrp_code 
				IF l_rec_product.part_code IS NOT NULL THEN 
					SELECT unique 1 
					FROM t_offerauto 
					WHERE part_code = l_rec_product.part_code 
					IF status != NOTFOUND THEN 
						ERROR kandoomsg2("E",9027,"") 			#9027" Automatic product line Already Exists "
						NEXT FIELD part_code 
					END IF
					 
					SELECT * INTO l_rec_product.* 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_product.part_code 

					SELECT desc_text 
					INTO l_prodgrp_text 
					FROM prodgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND prodgrp_code = l_rec_product.prodgrp_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",1170,"") 			#9016" Product group NOT found FOR Product"
						LET l_rec_product.prodgrp_code = NULL 
						LET l_rec_product.part_code = NULL 
					END IF 
					
					SELECT desc_text 
					INTO l_maingrp_text 
					FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = l_rec_product.maingrp_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",1171,"") 		#9017" Main product group NOT found FOR Product"
						LET l_rec_product.maingrp_code = NULL 
						LET l_rec_product.prodgrp_code = NULL 
						LET l_rec_product.part_code = NULL 
					END IF 
				ELSE 
					LET l_part_text = NULL 
					CLEAR l_part_text 
				END IF 
				DISPLAY BY NAME l_rec_product.part_code, 
				l_part_text, 
				l_rec_product.prodgrp_code, 
				l_prodgrp_text, 
				l_rec_product.maingrp_code, 
				l_maingrp_text 

			END IF 


		BEFORE FIELD prodgrp_code 
			IF l_rec_product.part_code IS NOT NULL THEN 
				IF l_lastcol_no < 2 THEN 
					NEXT FIELD maingrp_code 
				ELSE 
					NEXT FIELD part_code 
				END IF 
			END IF 

		AFTER FIELD prodgrp_code 
			LET l_lastcol_no = 2 
			IF l_rec_product.prodgrp_code IS NOT NULL THEN 
				SELECT desc_text, 
				maingrp_code 
				INTO l_prodgrp_text, 
				l_rec_product.maingrp_code 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = l_rec_product.prodgrp_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9163,"") 				#9011" Product Group does NOT Exist - Try Window"
					NEXT FIELD prodgrp_code 
				ELSE 
					SELECT desc_text 
					INTO l_maingrp_text 
					FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = l_rec_product.maingrp_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",1172,"") 					#9018" Main product group NOT found FOR product group"
						LET l_rec_product.prodgrp_code = NULL 
						LET l_rec_product.maingrp_code = NULL 
						CLEAR l_prodgrp_text 
						CLEAR l_maingrp_text 
					ELSE 
						DISPLAY BY NAME l_rec_product.prodgrp_code, 
						l_prodgrp_text, 
						l_rec_product.maingrp_code, 
						l_maingrp_text 

					END IF 
				END IF 
			ELSE 
				CLEAR l_prodgrp_text 
			END IF 


		BEFORE FIELD maingrp_code 
			IF l_lastcol_no > 3 THEN 
				CASE 
					WHEN l_rec_product.part_code IS NOT NULL 
						NEXT FIELD part_code 
					WHEN l_rec_product.prodgrp_code IS NOT NULL 
						NEXT FIELD prodgrp_code 
				END CASE 
			ELSE 
				IF l_rec_product.prodgrp_code IS NOT NULL THEN 
					NEXT FIELD l_sold_qty 
				END IF 
			END IF 

		AFTER FIELD maingrp_code 
			LET l_lastcol_no = 3 
			IF l_rec_product.maingrp_code IS NULL THEN 
				ERROR kandoomsg2("E",1173,"") 			#9015" Product Main Group must be Entered"
				NEXT FIELD maingrp_code 
			ELSE 
				SELECT desc_text 
				INTO l_maingrp_text 
				FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = l_rec_product.maingrp_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9164,"") 			#9012" Product Main Group does NOT Exist - Try Window"
					CLEAR l_maingrp_text 
					NEXT FIELD maingrp_code 
				ELSE 
					DISPLAY BY NAME l_maingrp_text 

				END IF 
			END IF 

		AFTER FIELD l_sold_qty 
			LET l_lastcol_no = 4 
			IF l_sold_qty IS NULL THEN 
				LET l_sold_qty = 0 
				NEXT FIELD l_sold_qty 
			ELSE 
				IF l_rec_product.trade_in_flag = "Y" THEN 
					IF l_sold_qty > 0 THEN 
						ERROR kandoomsg2("E",9181,"") 				#9181" Trade in must be negative
						LET l_sold_qty = l_sold_qty * -1 
						NEXT FIELD l_sold_qty 
					END IF 
				END IF 
				IF l_sold_qty < 0 THEN 
					IF l_rec_product.trade_in_flag IS NULL 
					OR l_rec_product.trade_in_flag = "N" THEN 
						ERROR kandoomsg2("E",9024,"") 				#9024" Line Quantity must NOT be Negative "
						LET l_sold_qty = 0 
						NEXT FIELD l_sold_qty 
					END IF 
				END IF 
			END IF 

		AFTER FIELD l_bonus_qty 
			LET l_lastcol_no = 5 
			IF l_bonus_qty IS NULL THEN 
				LET l_bonus_qty = 0 
				NEXT FIELD l_bonus_qty 
			ELSE 
				IF l_rec_product.trade_in_flag = "Y" AND 
				l_bonus_qty <> 0 THEN 
					ERROR kandoomsg2("E",9181,"") 	#9181" Trade in cannot be used FOR bonus
					LET l_bonus_qty = 0 
					NEXT FIELD l_bonus_qty 
				END IF 
				IF l_bonus_qty < 0 THEN 
					ERROR kandoomsg2("E",9024,"") 		#9024" Line Quantity must NOT be Negative "
					LET l_bonus_qty = 0 
					NEXT FIELD l_bonus_qty 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_product.maingrp_code IS NULL THEN 
					ERROR kandoomsg2("E",1173,"") 			#9015" Main Product Group must be Entered"
					NEXT FIELD maingrp_code 
				END IF 
				IF l_sold_qty IS NULL THEN 
					LET l_sold_qty = 0 
				END IF 
				IF l_bonus_qty IS NULL THEN 
					LET l_bonus_qty = 0 
				END IF 
				IF l_bonus_qty = 0 AND l_sold_qty = 0 THEN 
					ERROR kandoomsg2("E",9019,"") 			#9019" Required Qty must be Entered"
					NEXT FIELD l_sold_qty 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 

	------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
	ELSE 
		LET l_query_text = "SELECT * ", 
		"FROM product ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
		"AND serial_flag <> 'Y' " 

		CASE 
			WHEN l_rec_product.part_code IS NOT NULL 
				LET l_query_text = l_query_text clipped, 
				" AND part_code = \"",l_rec_product.part_code,"\"" 
			WHEN l_rec_product.prodgrp_code IS NOT NULL 
				LET l_query_text = l_query_text clipped, 
				" AND prodgrp_code = \"",l_rec_product.prodgrp_code,"\"" 
			WHEN l_rec_product.maingrp_code IS NOT NULL 
				LET l_query_text = l_query_text clipped, 
				" AND maingrp_code = \"",l_rec_product.maingrp_code,"\"" 
		END CASE 

		PREPARE s_product FROM l_query_text 
		DECLARE c_product cursor FOR s_product 

		--------------------------------------------------

		FOREACH c_product INTO l_rec_product.* 
			SELECT unique 1 
			FROM t_offerauto 
			WHERE part_code = l_rec_product.part_code 
			IF status = NOTFOUND THEN 
				IF l_rec_product.disc_allow_flag IS NULL THEN 
					LET l_rec_product.disc_allow_flag = no_flag 
				ELSE 
					LET l_rec_product.disc_allow_flag = 
					xlate_from(l_rec_product.disc_allow_flag) 
				END IF 
				INSERT INTO t_offerauto 
				VALUES ( l_rec_product.part_code, 
				l_bonus_qty, 
				l_sold_qty, 
				0, 
				0, 
				l_rec_product.disc_allow_flag, 
				"N") 
				CALL disp_cnt() 
			END IF 
		END FOREACH 
		-----------------------------------------------------
	END IF 
END FUNCTION 


################################################################################
# FUNCTION scan_prods()
#
#
################################################################################
FUNCTION scan_prods() 
	DEFINE l_idx SMALLINT 

	CALL db_inparms_get_rec(UI_OFF,"1") RETURNING modu_rec_inparms.* 

	SELECT count(*) 
	INTO l_idx 
	FROM t_offerauto 
	CALL set_count(l_idx) 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 

	MESSAGE kandoomsg2("E",1003,"") #1003 " F1 TO Add - F2 TO Delete - RETURN TO Edit
	INPUT ARRAY modu_arr_rec_offerauto WITHOUT DEFAULTS FROM sr_offerauto.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E61d","inp-arr-modu_arr_rec_offerauto") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
 
			CALL disp_cnt() 

		AFTER FIELD scroll_flag 
			LET modu_arr_rec_offerauto[l_idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				ERROR kandoomsg2("E",9001,"") 
				NEXT FIELD scroll_flag 
			ELSE 

			END IF 

		BEFORE FIELD part_code 
			IF enter_autoline(l_idx) THEN 

			END IF 
			NEXT FIELD scroll_flag 

		BEFORE DELETE 
			IF modu_arr_rec_offerauto[l_idx].part_code IS NOT NULL THEN 
				DELETE FROM t_offerauto 
				WHERE part_code = modu_arr_rec_offerauto[l_idx].part_code 
				INITIALIZE modu_arr_rec_offerauto[l_idx].* TO NULL 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE INSERT 
			LET l_idx = arr_curr() 
--			LET scrn = scr_line() 
			LET modu_arr_rec_offerauto[l_idx].part_code = NULL 
			IF l_idx < arr_count() OR l_idx = 1 THEN 
				IF enter_autoline(l_idx) THEN 
--					DISPLAY modu_arr_rec_offerauto[l_idx].* 
--					TO sr_offerauto[scrn].* 

					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
				ELSE 
					FOR l_idx = arr_curr() TO arr_count() 
						LET modu_arr_rec_offerauto[l_idx].* = modu_arr_rec_offerauto[l_idx+1].* 
--						IF scrn <= 5 THEN 
--							DISPLAY modu_arr_rec_offerauto[l_idx].* 
--							TO sr_offerauto[scrn].* 
--
--							LET scrn = scrn + 1 
--						END IF 
					END FOR 
					INITIALIZE modu_arr_rec_offerauto[l_idx].* TO NULL 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 

--		AFTER ROW 
--			DISPLAY modu_arr_rec_offerauto[l_idx].* 
--			TO sr_offerauto[scrn].* 


	END INPUT 
	----------------------------------------------

	LET quit_flag = FALSE 
	LET int_flag = FALSE 

END FUNCTION 



################################################################################
# FUNCTION enter_autoline(l_idx)
#
#
################################################################################
FUNCTION enter_autoline(l_idx) 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_offerauto RECORD LIKE offerauto.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_list_amt LIKE prodstatus.list_amt 
	DEFINE l_temp_code char(20) 
	DEFINE l_lastfield char(10) 

	IF modu_arr_rec_offerauto[l_idx].part_code IS NULL THEN 
		INITIALIZE l_rec_offerauto.* TO NULL 
		INITIALIZE modu_arr_rec_offerauto[l_idx].* TO NULL 
	ELSE 
		SELECT "1", "2", t_offerauto.* INTO l_rec_offerauto.* 
		FROM t_offerauto 
		WHERE part_code = modu_arr_rec_offerauto[l_idx].part_code 
		SELECT * INTO l_rec_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_offerauto.part_code 
		
		SELECT list_amt INTO l_list_amt 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_offerauto.part_code 
		AND ware_code = modu_rec_inparms.mast_ware_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_list_amt = 0 
		END IF 
		IF l_rec_offerauto.price_amt = 0 THEN 
			LET l_rec_offerauto.disc_per = NULL 
		ELSE 
			IF l_rec_offerauto.disc_per = 0 THEN 
				LET l_rec_offerauto.price_amt = NULL 
			END IF 
		END IF 
	END IF 

	OPEN WINDOW e127 with FORM "E127" 
	 CALL windecoration_e("E127") 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 

	DISPLAY BY NAME l_rec_product.desc_text 

	DISPLAY l_list_amt 
	TO prodstatus.list_amt 

	MESSAGE kandoomsg2("E",1165,"") 	#1165" Enter Auto Line Details"
	INPUT BY NAME l_rec_offerauto.part_code, 
	l_rec_offerauto.sold_qty, 
	l_rec_offerauto.bonus_qty, 
	l_rec_offerauto.status_ind, 
	l_rec_offerauto.disc_allow_flag, 
	l_rec_offerauto.price_amt, 
	l_rec_offerauto.disc_per WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E61b","inp-modu_arr_rec_offerauto") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield(part_code)  
			LET l_temp_code = show_part(glob_rec_kandoouser.cmpy_code,"") 
			IF l_temp_code IS NOT NULL THEN 
				LET l_rec_offerauto.part_code = l_temp_code clipped 
			END IF 
			NEXT FIELD part_code 


		BEFORE FIELD part_code 
			IF modu_arr_rec_offerauto[l_idx].part_code IS NOT NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD sold_qty 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD part_code 
			IF l_rec_offerauto.part_code IS NULL THEN 
				ERROR kandoomsg2("E",1174,"") 			#9013" Product Code must be Entered"
				CLEAR desc_text 
				NEXT FIELD part_code 
			ELSE 
				SELECT * INTO l_rec_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_offerauto.part_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",9162,"") 				#9010" Product does NOT Exist - Try Window"
					CLEAR desc_text 
					NEXT FIELD part_code 
				ELSE 
					IF l_rec_product.serial_flag = 'Y' THEN 
						ERROR kandoomsg2("I",9285,"") 					#9285 Serial Items can NOT be used.
						NEXT FIELD part_code 
					END IF 
					SELECT unique 1 
					FROM t_offerauto 
					WHERE part_code = l_rec_offerauto.part_code 
					
					IF status = NOTFOUND THEN 
					
						SELECT list_amt INTO l_list_amt 
						FROM prodstatus 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = l_rec_offerauto.part_code 
						AND ware_code = modu_rec_inparms.mast_ware_code 
						IF sqlca.sqlcode = NOTFOUND THEN 
							LET l_list_amt = 0 
						END IF
						 
						DISPLAY l_list_amt 
						TO prodstatus.list_amt 

						IF l_rec_offerauto.price_amt IS NULL THEN 
							LET l_rec_offerauto.price_amt = l_list_amt 
							LET l_rec_offerauto.disc_per = NULL 
						END IF 
						IF l_rec_offerauto.disc_allow_flag IS NULL THEN 
							LET l_rec_offerauto.disc_allow_flag = 
							xlate_from(l_rec_product.disc_allow_flag) 
						END IF 
						IF l_rec_offerauto.disc_allow_flag = "N" THEN 
							LET l_rec_offerauto.disc_per = 0 
						END IF 
						IF l_rec_offerauto.status_ind IS NULL THEN 
							LET l_rec_offerauto.status_ind = "N" 
						END IF 
						DISPLAY BY NAME l_rec_product.desc_text, 
						l_rec_offerauto.price_amt, 
						l_rec_offerauto.disc_per, 
						l_rec_offerauto.disc_allow_flag, 
						l_rec_offerauto.status_ind 

					ELSE 
						ERROR kandoomsg2("E",9027,"") 					#9027" Automatic product line Already Exists "
						NEXT FIELD part_code 
					END IF 
				END IF 
			END IF 

		AFTER FIELD sold_qty 
			IF l_rec_offerauto.sold_qty IS NULL THEN 
				LET l_rec_offerauto.sold_qty = 0 
				NEXT FIELD sold_qty 
			ELSE 
				IF l_rec_product.trade_in_flag = "Y" THEN 
					IF l_rec_offerauto.sold_qty > 0 THEN 
						ERROR kandoomsg2("E",9181,"") 					#9181" Trade in must be negative
						LET l_rec_offerauto.sold_qty = l_rec_offerauto.sold_qty * -1 
						NEXT FIELD sold_qty 
					END IF 
				END IF 
				IF l_rec_offerauto.sold_qty < 0 THEN 
					IF l_rec_product.trade_in_flag IS NULL 
					OR l_rec_product.trade_in_flag = "N" THEN 
						LET l_rec_offerauto.sold_qty = 0 
						ERROR kandoomsg2("E",9031,"") 					#9031" Quantity of Product cannot be Negative"
						NEXT FIELD sold_qty 
					END IF 
				END IF 
			END IF 
		AFTER FIELD bonus_qty 
			IF l_rec_offerauto.bonus_qty IS NULL THEN 
				LET l_rec_offerauto.bonus_qty = 0 
				NEXT FIELD bonus_qty 
			ELSE 
				IF l_rec_product.trade_in_flag = "Y" AND 
				l_rec_offerauto.bonus_qty <> 0 THEN 
					ERROR kandoomsg2("E",9181,"") 				#9181" Trade in cannot be used FOR bonus
					LET l_rec_offerauto.bonus_qty = 0 
					NEXT FIELD bonus_qty 
				END IF 
				IF l_rec_offerauto.bonus_qty < 0 THEN 
					LET l_rec_offerauto.bonus_qty = 0 
					ERROR kandoomsg2("E",9031,"") 				#9031" Quantity of Product cannot be Negative"
					NEXT FIELD bonus_qty 
				END IF 
			END IF 
		AFTER FIELD disc_allow_flag 
			IF l_rec_offerauto.disc_allow_flag = no_flag THEN 
				LET l_rec_offerauto.price_amt = l_list_amt 
				LET l_rec_offerauto.disc_per = 0 
				DISPLAY BY NAME l_rec_offerauto.price_amt, 
				l_rec_offerauto.disc_per 

				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD status_ind 
				END IF 
			END IF 

		BEFORE FIELD price_amt 
			IF l_rec_offerauto.disc_per IS NOT NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD disc_allow_flag 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD price_amt 
			IF l_rec_offerauto.price_amt IS NOT NULL THEN 
				IF l_rec_offerauto.price_amt < 0 THEN 
					LET l_rec_offerauto.price_amt = 0 
					ERROR kandoomsg2("E",9033,"") 				#9033" Selling Price Amount cannot be Negative"
					NEXT FIELD price_amt 
				END IF 
			END IF 

		BEFORE FIELD disc_per 
			IF l_rec_offerauto.price_amt IS NOT NULL THEN 
				EXIT INPUT 
			END IF 

		AFTER FIELD disc_per 
			IF l_rec_offerauto.disc_per IS NOT NULL THEN 
				IF l_rec_offerauto.disc_per < 0 
				OR l_rec_offerauto.disc_per > 100 THEN 
					LET l_rec_offerauto.disc_per = 0 
					ERROR kandoomsg2("E",9034,"") 				#9034" Discount percentage must be between 0 AND 100
					NEXT FIELD disc_per 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_offerauto.sold_qty IS NULL THEN 
					LET l_rec_offerauto.sold_qty = 0 
				END IF 
				IF l_rec_offerauto.bonus_qty IS NULL THEN 
					LET l_rec_offerauto.bonus_qty = 0 
				END IF 
				IF l_rec_offerauto.sold_qty = 0 
				AND l_rec_offerauto.bonus_qty = 0 THEN 
					ERROR kandoomsg2("E",9030,"") 				#9030" Product quantity must be Entered"
					NEXT FIELD sold_qty 
				END IF 
				IF l_rec_offerauto.price_amt IS NULL 
				AND l_rec_offerauto.disc_per IS NULL THEN 
					LET l_rec_offerauto.disc_per = 0 
					DISPLAY BY NAME l_rec_offerauto.disc_per 

				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	-----------------------------------------------

	CLOSE WINDOW e127 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		UPDATE t_offerauto 
		SET sold_qty = l_rec_offerauto.sold_qty, 
		bonus_qty = l_rec_offerauto.bonus_qty, 
		price_amt = l_rec_offerauto.price_amt, 
		disc_per = l_rec_offerauto.disc_per, 
		disc_allow_flag = l_rec_offerauto.disc_allow_flag, 
		status_ind = l_rec_offerauto.status_ind 
		WHERE part_code = modu_arr_rec_offerauto[l_idx].part_code 

		IF sqlca.sqlerrd[3] = 0 THEN 
			INSERT INTO t_offerauto VALUES ( l_rec_offerauto.part_code, 
			l_rec_offerauto.bonus_qty, 
			l_rec_offerauto.sold_qty, 
			l_rec_offerauto.price_amt, 
			l_rec_offerauto.disc_per, 
			l_rec_offerauto.disc_allow_flag, 
			l_rec_offerauto.status_ind) 
		END IF 

		LET modu_arr_rec_offerauto[l_idx].part_code = l_rec_offerauto.part_code 
		LET modu_arr_rec_offerauto[l_idx].desc_text = l_rec_product.desc_text 
		LET modu_arr_rec_offerauto[l_idx].sold_qty = l_rec_offerauto.sold_qty 
		LET modu_arr_rec_offerauto[l_idx].bonus_qty = l_rec_offerauto.bonus_qty 
		RETURN TRUE 
	END IF 
END FUNCTION 


################################################################################
# FUNCTION disp_cnt()
#
#
################################################################################
FUNCTION disp_cnt() 
	DEFINE l_linecnt SMALLINT 

	SELECT count(*) 
	INTO l_linecnt 
	FROM t_offerauto 

	DISPLAY BY NAME l_linecnt attribute(yellow) 

END FUNCTION 
