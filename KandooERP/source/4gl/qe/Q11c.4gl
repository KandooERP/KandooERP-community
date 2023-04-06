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
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 
# \brief module Q11c - FUNCTION TO handle Entry of Special Offers



FUNCTION offer_entry() 
	DEFINE 
	pa_orderoffer array[30] OF RECORD 
		scroll_flag CHAR(1), 
		offer_code LIKE orderoffer.offer_code, 
		desc_text LIKE offersale.desc_text, 
		offer_qty LIKE orderoffer.offer_qty 
	END RECORD, 
	pr_offersale RECORD LIKE offersale.*, 
	pr_orderoffer RECORD LIKE orderoffer.*, 
	pr_line_num,idx,scrn SMALLINT, 
	i SMALLINT 

	OPEN WINDOW e118 with FORM "E118" -- alch kd-747 
	CALL winDecoration_e("E118") -- alch kd-747 
	DECLARE ci_orderoffer CURSOR FOR 
	SELECT * FROM orderoffer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = pr_quotehead.order_num 
	AND offer_code NOT in (SELECT offer_code FROM t_orderpart) 
	LET idx = 0 
	FOREACH ci_orderoffer INTO pr_orderoffer.* 
		LET idx = idx + 1 
		INSERT INTO t_orderpart(offer_code,disc_ind,offer_qty,disc_per) 
		VALUES (pr_orderoffer.offer_code, 
		pr_orderoffer.disc_ind, 
		pr_orderoffer.offer_qty, 
		pr_orderoffer.disc_per) 
	END FOREACH 
	IF idx > 0 THEN 
		LET msgresp=kandoomsg("E",1017,"") 
		#1017, Validating Existing Special Offers - Please Wait
	END IF 
	LET idx = 1 
	DECLARE c0_orderpart CURSOR FOR 
	SELECT offer_code, offer_qty 
	FROM t_orderpart 
	WHERE offer_code != "###" 
	FOREACH c0_orderpart INTO pa_orderoffer[idx].offer_code, 
		pa_orderoffer[idx].offer_qty 
		SELECT desc_text INTO pa_orderoffer[idx].desc_text 
		FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = pa_orderoffer[idx].offer_code 
		IF sqlca.sqlcode = notfound THEN 
			LET msgresp=kandoomsg("E",7014,pa_orderoffer[idx].offer_code) 
			#7014, Special Offer ???? details NOT found"
			LET pa_orderoffer[idx].desc_text = "**********" 
		END IF 
		LET idx = idx + 1 
		IF idx = 30 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(idx-1) 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	LET msgresp=kandoomsg("E",1018,"") 
	#1018, Include Offer - F1 TO Add - F2 TO Delete - RETURN TO Edit Quantity
	INPUT ARRAY pa_orderoffer WITHOUT DEFAULTS FROM sr_orderoffer.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q11c","inp_arr-pa_orderoffer-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		ON KEY (control-b) 
			IF infield(offer_code) THEN 
				LET pr_temp_text = "start_date <= '",pr_quotehead.quote_date,"' ", 
				"AND end_date >= '",pr_quotehead.quote_date,"'" 
				LET pr_temp_text = show_offer(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
				IF pr_temp_text IS NOT NULL THEN 
					LET pa_orderoffer[idx].offer_code = pr_temp_text 
				END IF 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				NEXT FIELD offer_code 
			END IF 
		BEFORE FIELD scroll_flag 
			DISPLAY pa_orderoffer[idx].* 
			TO sr_orderoffer[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_orderoffer[idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("E",9001,"") 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD offer_code 
			DISPLAY pa_orderoffer[idx].* 
			TO sr_orderoffer[scrn].* 

			IF pa_orderoffer[idx].offer_qty IS NOT NULL THEN 
				NEXT FIELD offer_qty 
			END IF 
		AFTER FIELD offer_code 
			CLEAR sr_orderoffer[scrn].desc_text 
			CASE 
				WHEN fgl_lastkey()=fgl_keyval("accept") 
				WHEN fgl_lastkey()=fgl_keyval("RETURN") 
					OR fgl_lastkey()=fgl_keyval("right") 
					OR fgl_lastkey()=fgl_keyval("tab") 
					OR fgl_lastkey()=fgl_keyval("down") 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey()=fgl_keyval("left") 
					OR fgl_lastkey()=fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD offer_code 
			END CASE 
		BEFORE FIELD desc_text 
			IF pa_orderoffer[idx].offer_code IS NULL THEN 
				INITIALIZE pa_orderoffer[idx].* TO NULL 
				NEXT FIELD offer_code 
			ELSE 
				SELECT * INTO pr_offersale.* 
				FROM offersale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND offer_code = pa_orderoffer[idx].offer_code 
				AND start_date <= pr_quotehead.quote_date 
				AND end_date >= pr_quotehead.quote_date 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("E",9070,"") 
					#9070 Special Offer Invalid - Try Window"
					LET pa_orderoffer[idx].offer_code = NULL 
					NEXT FIELD offer_code 
				ELSE 
					FOR i = 1 TO arr_count() 
						IF pa_orderoffer[i].offer_code = pa_orderoffer[idx].offer_code 
						AND pa_orderoffer[i].offer_code IS NOT NULL THEN 
							IF i != idx THEN 
								LET msgresp=kandoomsg("E",9069,"") 
								#9069 This special offer already included in the offer"
								NEXT FIELD offer_code 
							END IF 
						END IF 
					END FOR 
					IF pr_offersale.disc_rule_ind = "2" THEN 
						## disc_rule two requires a sales condition
						IF pr_quotehead.cond_code IS NULL THEN 
							LET msgresp=kandoomsg("E",7032,"") 
							#7032Warning:Offer needs sale condition FOR chk limits
						END IF 
					END IF 
					LET pa_orderoffer[idx].desc_text = pr_offersale.desc_text 
					DISPLAY pa_orderoffer[idx].desc_text 
					TO sr_orderoffer[scrn].desc_text 

				END IF 
				NEXT FIELD offer_qty 
			END IF 
		AFTER FIELD offer_qty 
			CASE 
				WHEN pa_orderoffer[idx].offer_qty IS NULL 
					LET pa_orderoffer[idx].offer_qty = 0 
					NEXT FIELD offer_qty 
				WHEN pa_orderoffer[idx].offer_qty < 0 
					LET msgresp=kandoomsg("E",9071,"") 
					#9071" Quantity must NOT be less than zero"
					NEXT FIELD offer_qty 
				WHEN autolines(pa_orderoffer[idx].offer_code, 
					pa_orderoffer[idx].offer_qty) 
					UPDATE t_orderpart 
					SET offer_qty = pa_orderoffer[idx].offer_qty 
					WHERE offer_code= pa_orderoffer[idx].offer_code 
					IF sqlca.sqlerrd[3] = 0 THEN 
						INSERT INTO t_orderpart 
						VALUES (pa_orderoffer[idx].offer_code, 
						pr_offersale.desc_text, "X", 
						pa_orderoffer[idx].offer_qty, 0, 0, 
						pr_offersale.bonus_check_per, 
						pr_offersale.bonus_check_amt, 
						pr_offersale.disc_check_per, 
						pr_offersale.min_sold_amt, 
						pr_offersale.min_order_amt,0,"",0,0) 
					END IF 
				OTHERWISE 
					NEXT FIELD offer_qty 
			END CASE 
		BEFORE INSERT 
			INITIALIZE pa_orderoffer[idx].* TO NULL 
			NEXT FIELD offer_code 
		ON KEY (F2) 
			IF pa_orderoffer[idx].offer_code IS NOT NULL THEN 
				IF autolines(pa_orderoffer[idx].offer_code,0) THEN 
					UPDATE t_orderpart 
					SET offer_qty = 0 
					WHERE offer_code= pa_orderoffer[idx].offer_code 
					LET pa_orderoffer[idx].offer_qty = 0 
				END IF 
			ELSE 
				LET pa_orderoffer[idx].offer_qty = "" 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			IF pa_orderoffer[idx].offer_code IS NOT NULL THEN 
				IF pa_orderoffer[idx].offer_qty IS NULL THEN 
					LET pa_orderoffer[idx].offer_qty = 0 
				END IF 
			ELSE 
				LET pa_orderoffer[idx].offer_qty = "" 
			END IF 
			DISPLAY pa_orderoffer[idx].* TO sr_orderoffer[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW e118 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	DELETE FROM t_orderpart WHERE offer_qty = 0 
	RETURN true 
END FUNCTION 


FUNCTION autolines(pr_offer_code,pr_offer_qty) 
	DEFINE 
	pr_offer_code LIKE orderoffer.offer_code, 
	pr_offer_qty LIKE orderoffer.offer_qty, 
	pr_orderoffer RECORD LIKE orderoffer.*, 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pr_offerauto RECORD LIKE offerauto.*, 
	pr_offersale RECORD LIKE offersale.* 

	SELECT offer_qty INTO pr_orderoffer.offer_qty 
	FROM t_orderpart 
	WHERE offer_code = pr_offer_code 
	IF sqlca.sqlcode = notfound THEN 
		LET pr_orderoffer.offer_qty = 0 
	END IF 
	SELECT * INTO pr_offersale.* 
	FROM offersale 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND offer_code = pr_offer_code 
	LABEL tryagain: 
	BEGIN WORK 
		IF pr_offer_qty != pr_orderoffer.offer_qty THEN 
			CASE 
				WHEN pr_offer_qty = 0 ## DELETE offer 
					DECLARE c1_quotedetl CURSOR with HOLD FOR 
					SELECT * FROM t_quotedetl 
					WHERE offer_code = pr_offer_code 
					AND autoinsert_flag IS NOT NULL 
					FOREACH c1_quotedetl INTO pr_quotedetl.* 
						DELETE FROM t_quotedetl 
						WHERE line_num = pr_quotedetl.line_num 
					END FOREACH 
					CLOSE c1_quotedetl 
					UPDATE t_quotedetl 
					SET offer_code = null, 
					autoinsert_flag = NULL 
					WHERE offer_code = pr_offer_code 
				WHEN pr_orderoffer.offer_qty = 0 ## add new offer 
					DECLARE c_offerauto CURSOR with HOLD FOR 
					SELECT * FROM offerauto 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND offer_code = pr_offer_code 
					FOREACH c_offerauto INTO pr_offerauto.* 
						CALL insert_line() RETURNING pr_quotedetl.* 
						LET pr_quotedetl.offer_code = pr_offerauto.offer_code 
						LET pr_quotedetl.part_code = pr_offerauto.part_code 
						IF pr_offerauto.status_ind = "Y" THEN 
							LET pr_quotedetl.status_ind = "1" 
							IF pr_globals.supp_ware_code IS NOT NULL THEN 
								LET pr_quotedetl.ware_code = pr_globals.supp_ware_code 
							END IF 
						END IF 
						IF valid_part(glob_rec_kandoouser.cmpy_code,pr_quotedetl.part_code, 
						pr_quotedetl.ware_code, 
						0,2,0,"","","") = false THEN 
							ROLLBACK WORK 
							LET msgresp=kandoomsg("E",7033,pr_quotedetl.part_code) 
							#7033 Auto Lines are NOT stocked OR available AT warehouse"
							RETURN false 
						END IF 
						LET pr_quotedetl.sold_qty = pr_offerauto.sold_qty 
						* pr_offer_qty 
						LET pr_quotedetl.bonus_qty = pr_offerauto.bonus_qty 
						* pr_offer_qty 
						LET pr_quotedetl.disc_allow_flag = pr_offerauto.disc_allow_flag 
						IF pr_offerauto.disc_per IS NOT NULL THEN 
							LET pr_quotedetl.disc_per = pr_offerauto.disc_per 
							LET pr_quotedetl.unit_price_amt = NULL 
						ELSE 
							LET pr_quotedetl.disc_per = NULL 
							LET pr_quotedetl.unit_price_amt = pr_offerauto.price_amt 
						END IF 
						LET pr_quotedetl.autoinsert_flag = "Y" 
						IF pr_quotedetl.status_ind = "4" THEN 
							ROLLBACK WORK 
							LET msgresp = kandoomsg("E",7034,pr_quotedetl.part_code) 
							#7034 " Insufficent stock of Auto Lines AT warehouse"
							RETURN false 
						ELSE 
							CALL get_lead(pr_quotedetl.*) 
							RETURNING pr_quotedetl.quote_lead_text, 
							pr_quotedetl.quote_lead_text2 
							CALL update_line(pr_quotedetl.*) 
						END IF 
					END FOREACH 
					CLOSE c_offerauto 
			END CASE 
		END IF 
	COMMIT WORK 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
