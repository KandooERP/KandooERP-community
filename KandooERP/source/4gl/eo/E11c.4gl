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
# FUNCTION offer_entry() 
#
# E11c - FUNCTION TO handle Entry of Special Offers
###########################################################################
FUNCTION offer_entry() 
	DEFINE l_arr_rec_orderoffer DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		offer_code LIKE orderoffer.offer_code, 
		desc_text LIKE offersale.desc_text, 
		offer_qty LIKE orderoffer.offer_qty 
	END RECORD 
	DEFINE l_rec_s_orderoffer RECORD 
		offer_code LIKE orderoffer.offer_code, 
		desc_text LIKE offersale.desc_text, 
		offer_qty LIKE orderoffer.offer_qty 
	END RECORD
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_rec_orderoffer RECORD LIKE orderoffer.* 
	DEFINE l_line_num SMALLINT
	DEFINE l_idx SMALLINT	
	DEFINE l_upd_flag SMALLINT 
	DEFINE i SMALLINT 

	OPEN WINDOW E118 with FORM "E118" 
	 CALL windecoration_e("E118")  

	DECLARE ci_orderoffer cursor FOR 
	SELECT * FROM orderoffer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = glob_rec_orderhead.order_num 
	AND offer_code NOT in (select offer_code FROM t_orderpart) 

	LET l_idx = 0 
	FOREACH ci_orderoffer INTO l_rec_orderoffer.* 
		LET l_idx = l_idx + 1 
		INSERT INTO t_orderpart(offer_code,disc_ind,offer_qty,disc_per) 
		VALUES (
			l_rec_orderoffer.offer_code, 
			l_rec_orderoffer.disc_ind, 
			l_rec_orderoffer.offer_qty, 
			l_rec_orderoffer.disc_per) 
	END FOREACH 
	
	IF l_idx > 0 THEN 
		ERROR kandoomsg2("E",1017,"") #1017, Validating Existing Special Offers - Please Wait
	END IF 

	LET l_idx = 1 
	DECLARE c0_orderpart cursor FOR 
	SELECT offer_code, offer_qty 
	FROM t_orderpart 
	WHERE offer_code != "###" 

	FOREACH c0_orderpart INTO 
			l_arr_rec_orderoffer[l_idx].offer_code, 
			l_arr_rec_orderoffer[l_idx].offer_qty 
		SELECT desc_text INTO l_arr_rec_orderoffer[l_idx].desc_text 
		FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = l_arr_rec_orderoffer[l_idx].offer_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ERROR kandoomsg2("E",7014,l_arr_rec_orderoffer[l_idx].offer_code) 		#7014, Special Offer ???? details NOT found"
			LET l_arr_rec_orderoffer[l_idx].desc_text = "**********" 
		END IF 
		LET l_idx = l_idx + 1 
	END FOREACH 

	#for each will insert one empty row... we need to remove it
	IF l_arr_rec_orderoffer[l_idx].offer_code IS NULL THEN
		CALL l_arr_rec_orderoffer.delete(l_idx)
		LET l_idx = 0 
	End IF

	OPTIONS INSERT KEY f1 
	OPTIONS DELETE KEY f36 

	MESSAGE kandoomsg2("E",1018,"") #1018, Include Offer - F1 TO Add - F2 TO Delete - RETURN TO Edit Quantity
	INPUT ARRAY l_arr_rec_orderoffer WITHOUT DEFAULTS FROM sr_orderoffer.* ATTRIBUTE(UNBUFFERED, delete row = false, insert row = false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E11c","input-l_arr_rec_orderoffer-1")  
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_orderoffer.getSize())
				
		BEFORE ROW 
			LET l_idx = arr_curr() 
--			NEXT FIELD scroll_flag 
			
			IF l_arr_rec_orderoffer[l_idx].offer_code IS NULL THEN
				CALL dialog.setActionHidden("APPEND",TRUE)
				CALL dialog.setActionHidden("INSERT",TRUE)
				CALL dialog.setActionHidden("DELETE",TRUE)
			ELSE #current row is not valid/completed
				CALL dialog.setActionHidden("APPEND",FALSE)
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderoffer.getSize()) THEN
					CALL dialog.setActionHidden("DELETE",FALSE)
				END IF
			END IF

			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderoffer.getSize()) THEN
				LET l_rec_s_orderoffer.offer_code = l_arr_rec_orderoffer[l_idx].offer_code 
				LET l_rec_s_orderoffer.desc_text = l_arr_rec_orderoffer[l_idx].desc_text 
				LET l_rec_s_orderoffer.offer_qty = l_arr_rec_orderoffer[l_idx].offer_qty 
			END IF


--		BEFORE FIELD scroll_flag 
--			LET l_idx = arr_curr()
--			IF l_idx = 0 THEN
--				CALL fgl_winmessage("BEFORE FIELD arr_curr() returned 0","BEFORE FIELD arr_curr() returned 0","ERROR")
--			END IF
			 
--			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderoffer.getSize()) THEN
--				LET l_rec_s_orderoffer.offer_code = l_arr_rec_orderoffer[l_idx].offer_code 
--				LET l_rec_s_orderoffer.desc_text = l_arr_rec_orderoffer[l_idx].desc_text 
--				LET l_rec_s_orderoffer.offer_qty = l_arr_rec_orderoffer[l_idx].offer_qty 
--			END IF

		AFTER ROW 
			IF l_arr_rec_orderoffer[l_idx].offer_code IS NOT NULL THEN 
				IF l_arr_rec_orderoffer[l_idx].offer_qty IS NULL THEN 
					LET l_arr_rec_orderoffer[l_idx].offer_qty = 0 
				END IF 
			ELSE 
				LET l_arr_rec_orderoffer[l_idx].offer_qty = "" 
			END IF 


		ON ACTION "WEB-HELP"  
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()

		ON ACTION "LOOKUP" infield(offer_code) 
				LET glob_temp_text = 
					"start_date <= '",glob_rec_orderhead.order_date,"' ", 
					"AND end_date >= '",glob_rec_orderhead.order_date,"'" 
				
				LET glob_temp_text = show_offer(glob_rec_kandoouser.cmpy_code,glob_temp_text)
				 
				IF glob_temp_text IS NOT NULL THEN 
					LET l_arr_rec_orderoffer[l_idx].offer_code = glob_temp_text 
				END IF
				 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				NEXT FIELD offer_code 

			
--		AFTER FIELD scroll_flag 
--			LET l_arr_rec_orderoffer[l_idx].scroll_flag = NULL 
--			IF fgl_lastkey() = fgl_keyval("down") 
--			AND arr_curr() >= arr_count() THEN 
--				ERROR kandoomsg2("E",9001,"") 
--				NEXT FIELD scroll_flag 
--			END IF 

			ON ACTION "OFFER"			
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderoffer.getSize()) THEN
				IF l_arr_rec_orderoffer[l_idx].offer_qty IS NOT NULL THEN 
					SELECT unique 1 
					FROM t_orderdetl 
					WHERE picked_qty > 0 
					AND offer_code = l_arr_rec_orderoffer[l_idx].offer_code 
					AND autoinsert_flag = "Y" 
					IF status = 0 THEN 
						IF NOT check_pick_edit() THEN 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
					
					NEXT FIELD offer_qty 
				END IF 
			END IF			
			
		BEFORE INSERT 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderoffer.getSize()) THEN
				--INITIALIZE l_arr_rec_orderoffer[l_idx].* TO NULL
				IF l_arr_rec_orderoffer[l_idx].offer_code IS NOT NULL THEN   
					INITIALIZE l_rec_s_orderoffer.* TO NULL 
					--NEXT FIELD offer_code
				ELSE
					--NEXT FIELD offer_code
				END IF 
			END IF			
			
		AFTER INSERT
			#nothing
			
		ON ACTION "DELETE" --ON KEY (f2) #DELETE ????
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderoffer.getSize()) THEN 
				IF l_arr_rec_orderoffer[l_idx].offer_code IS NOT NULL THEN 
					
					SELECT unique 1 
					FROM t_orderdetl 
					WHERE picked_qty > 0 
					AND offer_code = l_arr_rec_orderoffer[l_idx].offer_code 
					AND autoinsert_flag = "Y" 
					
					IF status = 0 THEN 
						IF NOT check_pick_edit() THEN 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
					IF autolines(l_arr_rec_orderoffer[l_idx].offer_code,0) THEN 
						UPDATE t_orderpart 
						SET offer_qty = 0 
						WHERE offer_code= l_arr_rec_orderoffer[l_idx].offer_code 
						LET l_arr_rec_orderoffer[l_idx].offer_qty = 0 
					END IF 
				ELSE 
					LET l_arr_rec_orderoffer[l_idx].offer_qty = "" 
				END IF 
				NEXT FIELD scroll_flag 
			END IF
			
 

		AFTER FIELD offer_code 
--			CLEAR sr_orderoffer[scrn].desc_text 
			CASE 
				WHEN get_is_screen_navigation_forward() 
					--fgl_lastkey()=fgl_keyval("RETURN") 
					--OR fgl_lastkey()=fgl_keyval("tab") 
					--OR fgl_lastkey()=fgl_keyval("right") 
					--OR fgl_lastkey()=fgl_keyval("down") 
					NEXT FIELD NEXT 
				WHEN NOT get_is_screen_navigation_forward() 
					--fgl_lastkey()=fgl_keyval("left") 
					--OR fgl_lastkey()=fgl_keyval("up") 
					NEXT FIELD offer_code
					 
				WHEN fgl_lastkey()=fgl_keyval("accept") 
				 
				OTHERWISE 
					NEXT FIELD offer_code 
			END CASE 
			
		BEFORE FIELD desc_text 
			IF l_arr_rec_orderoffer[l_idx].offer_code IS NULL THEN 
				INITIALIZE l_arr_rec_orderoffer[l_idx].* TO NULL 
				NEXT FIELD offer_code 
			ELSE 
				SELECT * INTO l_rec_offersale.* 
				FROM offersale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND offer_code = l_arr_rec_orderoffer[l_idx].offer_code 
				AND start_date <= glob_rec_orderhead.order_date 
				AND end_date >= glob_rec_orderhead.order_date 
				
				IF sqlca.sqlcode = NOTFOUND THEN 
					--CALL fgl_winmessage("#9070 Special Offer Invalid",kandoomsg2("E",9070,""),"ERROR") 		#9070 Special Offer Invalid - Try Window"
					ERROR kandoomsg2("E",9070,"") 		#9070 Special Offer Invalid - Try Window"
					SLEEP 2
					LET l_arr_rec_orderoffer[l_idx].offer_code = NULL 
					NEXT FIELD offer_code 
				
				ELSE
				 	#check if offer was already used here 
					FOR i = 1 TO arr_count() 
						IF l_arr_rec_orderoffer[i].offer_code = l_arr_rec_orderoffer[l_idx].offer_code AND l_arr_rec_orderoffer[i].offer_code IS NOT NULL THEN 
							IF i != l_idx THEN 
								ERROR kandoomsg2("E",9069,"") 			#9069 This special offer already included in the offer"
								NEXT FIELD offer_code 
							END IF 
						END IF 
					END FOR 
					
					IF l_rec_offersale.disc_rule_ind = "2" THEN 
						#------------------------------------------
						# disc_rule two requires a sales condition
						IF glob_rec_orderhead.cond_code IS NULL THEN 
							ERROR kandoomsg2("E",7032,"") 					#7032Warning:Offer needs sale condition FOR chk limits
						END IF 
					END IF 
					
					LET l_arr_rec_orderoffer[l_idx].desc_text = l_rec_offersale.desc_text 

				END IF 
				NEXT FIELD offer_qty 
			END IF 
			
		AFTER FIELD offer_qty 
			CASE 
				WHEN l_arr_rec_orderoffer[l_idx].offer_qty IS NULL 
					LET l_arr_rec_orderoffer[l_idx].offer_qty = 0 
					NEXT FIELD offer_qty 
					
				WHEN l_arr_rec_orderoffer[l_idx].offer_qty < 0 
					ERROR kandoomsg2("E",9071,"") 	#9071" Quantity must NOT be less than zero"
					NEXT FIELD offer_qty 
					
				WHEN autolines(
							l_arr_rec_orderoffer[l_idx].offer_code, 
							l_arr_rec_orderoffer[l_idx].offer_qty) 
					UPDATE t_orderpart 
					SET offer_qty = l_arr_rec_orderoffer[l_idx].offer_qty 
					WHERE offer_code= l_arr_rec_orderoffer[l_idx].offer_code 
					IF sqlca.sqlerrd[3] = 0 THEN 
						INSERT INTO t_orderpart VALUES (
							l_arr_rec_orderoffer[l_idx].offer_code, 
							l_rec_offersale.desc_text, "X", 
							l_arr_rec_orderoffer[l_idx].offer_qty, 0, 0, 
							l_rec_offersale.bonus_check_per, 
							l_rec_offersale.bonus_check_amt, 
							l_rec_offersale.disc_check_per, 
							l_rec_offersale.min_sold_amt, 
							l_rec_offersale.min_order_amt,
							0,
							"",
							0,
							0) 
					END IF 
					
				OTHERWISE 
					NEXT FIELD offer_qty 
			END CASE 


		AFTER INPUT 
			IF int_flag OR quit_flag THEN
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderoffer.getSize()) THEN 
					IF NOT infield(scroll_flag) THEN 
						IF l_rec_s_orderoffer.offer_code IS NULL THEN 
							
							FOR l_idx = arr_curr() TO arr_count() 
								LET l_arr_rec_orderoffer[l_idx].* = l_arr_rec_orderoffer[l_idx+1].* 
								IF l_idx = arr_count() THEN 
									INITIALIZE l_arr_rec_orderoffer[l_idx].* TO NULL 
								END IF 
--							IF scrn <= 4 THEN 
--								DISPLAY l_arr_rec_orderoffer[l_idx].* TO sr_orderoffer[scrn].* 
--
--								LET scrn = scrn + 1 
--							END IF 
							END FOR
							 
-- 						LET scrn = scr_line() 
							LET int_flag = FALSE 
							LET quit_flag = FALSE 
							NEXT FIELD scroll_flag 

						ELSE 

							LET l_arr_rec_orderoffer[l_idx].offer_code = l_rec_s_orderoffer.offer_code 
							LET l_arr_rec_orderoffer[l_idx].desc_text = l_rec_s_orderoffer.desc_text 
							LET l_arr_rec_orderoffer[l_idx].offer_qty = l_rec_s_orderoffer.offer_qty 
							LET int_flag = FALSE 
							LET quit_flag = FALSE 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				
					FOR l_idx = 1 TO arr_count() 
						IF l_arr_rec_orderoffer[l_idx].offer_code IS NOT NULL	AND l_arr_rec_orderoffer[l_idx].offer_qty > 0 THEN 
							LET int_flag = FALSE 
							LET quit_flag = FALSE 
							CALL fgl_winmessage("#9267 Special offers exist", kandoomsg2("E",9267,""),"ERROR") 		#9267 Special offers exist, must press OK TO continue
							CONTINUE INPUT 
						END IF 
					END FOR 
				END IF #l_idx > 0
			END IF #int_flag
			
	END INPUT 

	CLOSE WINDOW E118 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		DELETE FROM t_orderpart WHERE offer_qty = 0 
	END IF 
	#Note: Do NOT change this RETURN of "TRUE" even though the user has pressed
	#      CANCEL.  There reason FOR this IS TO correctly adjust product
	#      movement AT the warehouse, AND TO reduce the instances of Negative
	#      Reserved appearing on stock STATUS reports AND enquires.
	#
	RETURN TRUE 
END FUNCTION 
############################################################
# END  FUNCTION offer_entry()  
############################################################


###########################################################################
# FUNCTION offer_entry() 
#
# E11c - FUNCTION TO handle Entry of Special Offers
###########################################################################
FUNCTION autolines(p_offer_code,p_offer_qty) 
	DEFINE p_offer_code LIKE orderoffer.offer_code 
	DEFINE p_offer_qty LIKE orderoffer.offer_qty 
	DEFINE l_rec_orderoffer RECORD LIKE orderoffer.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_offerauto RECORD LIKE offerauto.* 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_inv_ratio FLOAT 
	DEFINE l_upd_flag SMALLINT 

	SELECT offer_qty INTO l_rec_orderoffer.offer_qty 
	FROM t_orderpart 
	WHERE offer_code = p_offer_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_rec_orderoffer.offer_qty = 0 
	END IF 
	
	SELECT * INTO l_rec_offersale.* 
	FROM offersale 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND offer_code = p_offer_code 

	LABEL tryagain: 
	BEGIN WORK 
		LET l_upd_flag = 1 
		IF p_offer_qty != l_rec_orderoffer.offer_qty THEN 
			CASE 
				WHEN p_offer_qty = 0 ## DELETE offer 
					DECLARE c1_orderdetl cursor with hold FOR 
					
					SELECT * 
					FROM t_orderdetl 
					WHERE offer_code = p_offer_code 
					AND autoinsert_flag IS NOT NULL 
					AND autoinsert_flag = 'Y'
					 
					FOREACH c1_orderdetl INTO l_rec_orderdetl.* 
						IF l_rec_orderdetl.inv_qty = 0 THEN 
							LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,TRAN_TYPE_INVOICE_IN,1) 
							IF l_upd_flag < 1 THEN 
								EXIT FOREACH 
							END IF 
							
							DELETE FROM t_orderdetl 
							WHERE line_num = l_rec_orderdetl.line_num
							 
						END IF 
					END FOREACH 

					IF l_upd_flag = -1 THEN 
						GOTO tryagain 
					ELSE 
						IF l_upd_flag = 0 THEN 
							RETURN FALSE 
						END IF 
					END IF 

					CLOSE c1_orderdetl 
					UPDATE t_orderdetl 
					SET 
						offer_code = null, 
						autoinsert_flag = NULL 
					WHERE offer_code = p_offer_code
					 
				WHEN l_rec_orderoffer.offer_qty = 0 ## add new offer 
					DECLARE c_offerauto cursor with hold FOR 
					SELECT * FROM offerauto 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND offer_code = p_offer_code 

					FOREACH c_offerauto INTO l_rec_offerauto.*
					
					 	#INSERT ROW to temp table --------------------------------------
						CALL db_t_orderdetl_insert_line(NULL) RETURNING l_rec_orderdetl.* 
						
						LET l_rec_orderdetl.offer_code = l_rec_offerauto.offer_code 
						LET l_rec_orderdetl.part_code = l_rec_offerauto.part_code 

						LET l_rec_orderdetl.cost_ind = permit_backordering(l_rec_orderdetl.ware_code,	l_rec_orderdetl.part_code) 

						IF l_rec_offerauto.status_ind = "Y" THEN 
							LET l_rec_orderdetl.status_ind = "1" 
							IF glob_rec_sales_order_parameter.supp_ware_code IS NOT NULL THEN 
								LET l_rec_orderdetl.ware_code = glob_rec_sales_order_parameter.supp_ware_code 
							END IF 
						END IF 

						IF valid_part(
							glob_rec_kandoouser.cmpy_code,
							l_rec_orderdetl.part_code, 
							l_rec_orderdetl.ware_code, 
							0,2,0,"","","") = FALSE 
						THEN 
							ROLLBACK WORK 
							ERROR kandoomsg2("E",7033,l_rec_orderdetl.part_code) 		#7033 Auto Lines are NOT stocked OR available AT warehouse"
							RETURN FALSE 
						END IF 
						
						LET l_rec_orderdetl.sold_qty = l_rec_offerauto.sold_qty * p_offer_qty 
						LET l_rec_orderdetl.bonus_qty = l_rec_offerauto.bonus_qty	* p_offer_qty 
						LET l_rec_orderdetl.disc_allow_flag = l_rec_offerauto.disc_allow_flag
						 
						IF l_rec_offerauto.disc_per IS NOT NULL THEN 
							LET l_rec_orderdetl.disc_per = l_rec_offerauto.disc_per 
							LET l_rec_orderdetl.unit_price_amt = NULL 
						ELSE 
							LET l_rec_orderdetl.disc_per = NULL 
							LET l_rec_orderdetl.unit_price_amt = l_rec_offerauto.price_amt 
						END IF 
						
						LET l_rec_orderdetl.autoinsert_flag = "Y" 

						CALL allocate_stock(l_rec_orderdetl.*,1)	RETURNING l_rec_orderdetl.* 

						IF l_rec_orderdetl.status_ind = "4" THEN 
							ROLLBACK WORK 
							ERROR kandoomsg2("E",7034,l_rec_orderdetl.part_code) 			#7034 " Insufficent stock of Auto Lines AT warehouse"
							RETURN FALSE 
						ELSE 
							CALL db_t_orderdetl_update_line(l_rec_orderdetl.*) 
							LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,"OUT",1) 
							IF l_upd_flag < 1 THEN 
								EXIT FOREACH 
							END IF 
						END IF 

					END FOREACH 

					IF l_upd_flag = -1 THEN 
						GOTO tryagain 
					ELSE 
						IF l_upd_flag = 0 THEN 
							RETURN FALSE 
						END IF 
					END IF 
					CLOSE c_offerauto 

				OTHERWISE 
					## Edit Offer Line
					## calc.invoiced ratio of offerlines TO determine inv offer_qty
					DELETE FROM t2_orderdetl WHERE 1=1 
					INSERT INTO t2_orderdetl 

					SELECT * 
					FROM t_orderdetl 
					WHERE offer_code = p_offer_code 
					AND order_qty != 0 
					AND autoinsert_flag IS NOT NULL 
					AND autoinsert_flag = 'Y' 
					
					DECLARE c2_orderdetl cursor with hold FOR 

					SELECT *,(inv_qty/order_qty) 
					FROM t_orderdetl 
					WHERE offer_code = p_offer_code 
					AND order_qty != 0 
					AND autoinsert_flag IS NOT NULL 
					AND autoinsert_flag = 'Y' 
					ORDER BY 2 desc
					 
					FOREACH c2_orderdetl INTO l_rec_orderdetl.*,l_inv_ratio 
						IF l_inv_ratio > (p_offer_qty/l_rec_orderoffer.offer_qty) THEN 
							IF l_inv_ratio = 1 THEN 
								LET p_offer_qty = l_rec_orderoffer.offer_qty 
							ELSE 
								LET p_offer_qty = 0.5	+ (l_inv_ratio * l_rec_orderoffer.offer_qty) 
							END IF 
							
							ROLLBACK WORK 
							ERROR kandoomsg2("E",7035,p_offer_qty) 							#7035" Qty decreased below invd. Min ",p_offer_qty
							RETURN FALSE 

						ELSE 
							LET l_rec_orderdetl.sold_qty = l_rec_orderdetl.sold_qty	* p_offer_qty/l_rec_orderoffer.offer_qty 
							LET l_rec_orderdetl.bonus_qty = l_rec_orderdetl.bonus_qty	* p_offer_qty/l_rec_orderoffer.offer_qty 
							CALL allocate_stock(l_rec_orderdetl.*,1) RETURNING l_rec_orderdetl.*
							 
							IF l_rec_orderdetl.status_ind = "4" THEN 
								ROLLBACK WORK 
								ERROR kandoomsg2("E",7034,l_rec_orderdetl.part_code) 							#7034 " Insufficent stock of Auto Lines AT warehouse"
								RETURN FALSE 
							ELSE 
								LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,TRAN_TYPE_INVOICE_IN,1) 
								IF l_upd_flag < 1 THEN 
									EXIT FOREACH 
								END IF 
								
								IF l_rec_orderoffer.offer_qty = 0 THEN 
									DELETE FROM t_orderoffer 
									WHERE line_num = l_rec_orderdetl.line_num 
								ELSE 
									CALL db_t_orderdetl_update_line(l_rec_orderdetl.*) 
									LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,"OUT",1) 
									IF l_upd_flag < 1 THEN 
										EXIT FOREACH 
									END IF 
								END IF
								 
							END IF 
						END IF
						 
					END FOREACH 

					IF l_upd_flag = -1 THEN 
						GOTO tryagain 
					ELSE 
						IF l_upd_flag = 0 THEN 
							RETURN FALSE 
						END IF 
					END IF 
					CLOSE c2_orderdetl 
			END CASE 
		END IF 

	COMMIT WORK 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION
############################################################
# FUNCTION autolines(p_offer_code,p_offer_qty)  
############################################################