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
# E11f - Condition & Offer check
#
#  FUNCTION does the following.  IF a condition exists it IS validated
#  AND placed in a RECORD type variable.  IF special offers exist THEN
#  they are validated AND placed in an ARRAY FOR the user TO scroll thru
###########################################################################
###########################################################################
# FUNCTION check_offer() 
#
#
###########################################################################
FUNCTION check_offer() 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_rec_orderpart RECORD 
		scroll_flag char(1), 
		offer_code LIKE orderoffer.offer_code, 
		desc_text LIKE offersale.desc_text, 
		gross_amt LIKE orderhead.total_amt, 
		net_amt LIKE orderhead.total_amt, 
		disc_ind LIKE orderoffer.disc_ind 
	END RECORD 
	DEFINE l_arr_rec_orderpart array[31] OF RECORD 
		scroll2_flag char(1), 
		offer_code LIKE orderoffer.offer_code, 
		desc_text LIKE offersale.desc_text, 
		gross_amt LIKE orderhead.total_amt, 
		net_amt LIKE orderhead.total_amt, 
		disc_ind LIKE orderoffer.disc_ind 
	END RECORD 
	DEFINE l_msg_num INTEGER 
	DEFINE l_temp_text char(100) 
	DEFINE idx SMALLINT 
	DEFINE i SMALLINT 

	OPEN WINDOW E119 with FORM "E119" 
	 CALL windecoration_e("E119") -- albo kd-755 

	MESSAGE kandoomsg2("E",1022,"") #1022 Checking Offers/Conditions - please wait

	IF glob_rec_orderhead.cond_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_orderpart.desc_text 
		FROM condsale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cond_code = glob_rec_orderhead.cond_code 
		UPDATE t_orderpart SET desc_text = l_rec_orderpart.desc_text 
		WHERE offer_code = "###" 

		LET l_rec_orderpart.offer_code = glob_rec_orderhead.cond_code 
		LET l_rec_orderpart.gross_amt = 0 
		LET l_rec_orderpart.net_amt = 0 
		LET l_rec_orderpart.disc_ind = "-" 

		DISPLAY BY NAME l_rec_orderpart.offer_code, 
		l_rec_orderpart.desc_text, 
		l_rec_orderpart.gross_amt, 
		l_rec_orderpart.net_amt, 
		l_rec_orderpart.disc_ind 

		CALL validate_offer(glob_rec_kandoouser.cmpy_code,"1",glob_rec_orderhead.cond_code) 
		RETURNING l_msg_num,l_temp_text 
		####################### calc nett total & display
		SELECT gross_amt, 
		net_amt, 
		disc_ind 
		INTO l_rec_orderpart.gross_amt, 
		l_rec_orderpart.net_amt, 
		l_rec_orderpart.disc_ind 
		FROM t_orderpart 
		WHERE offer_code = "###" 
		DISPLAY BY NAME l_rec_orderpart.offer_code, 
		l_rec_orderpart.desc_text, 
		l_rec_orderpart.gross_amt, 
		l_rec_orderpart.net_amt, 
		l_rec_orderpart.disc_ind 

	END IF 

	LET idx = 0 
--	LET scrn = 0 
	DECLARE c_orderpart cursor FOR 
	SELECT offer_code 
	FROM t_orderpart 
	WHERE offer_code != "###" 
	AND offer_qty > 0 
	ORDER BY offer_code 

	FOREACH c_orderpart INTO l_rec_orderpart.offer_code 

		SELECT desc_text INTO l_rec_orderpart.desc_text 
		FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = l_rec_orderpart.offer_code 
		UPDATE t_orderpart SET desc_text = l_rec_orderpart.desc_text 
		WHERE offer_code = l_rec_orderpart.offer_code 

		LET l_msg_num = 0 
		LET l_temp_text = "" 
		LET idx = idx + 1 

--		LET scrn = scrn + 1 
--		IF scrn > 5 THEN 
--			SCROLL sr_orderpart.* up BY 1 
--			LET scrn = 5 
--		END IF 

		LET l_arr_rec_orderpart[idx].offer_code = l_rec_orderpart.offer_code 
		LET l_arr_rec_orderpart[idx].desc_text = l_rec_orderpart.desc_text 
		LET l_arr_rec_orderpart[idx].gross_amt = 0 
		LET l_arr_rec_orderpart[idx].net_amt = 0 
		LET l_arr_rec_orderpart[idx].disc_ind = "-"
		 
--		DISPLAY l_arr_rec_orderpart[idx].*	TO sr_orderpart[scrn].* 

		CALL validate_offer(glob_rec_kandoouser.cmpy_code,"2",l_rec_orderpart.offer_code) 
		RETURNING l_msg_num,l_temp_text 
		IF l_msg_num THEN 
			LET l_arr_rec_orderpart[idx].disc_ind = "X" 
		ELSE 
			LET l_arr_rec_orderpart[idx].disc_ind = "/" 
		END IF 

		SELECT gross_amt, 
		net_amt, 
		disc_ind 
		INTO l_arr_rec_orderpart[idx].gross_amt, 
		l_arr_rec_orderpart[idx].net_amt, 
		l_arr_rec_orderpart[idx].disc_ind 
		FROM t_orderpart 
		WHERE offer_code = l_arr_rec_orderpart[idx].offer_code 
--		DISPLAY l_arr_rec_orderpart[idx].*	TO sr_orderpart[scrn].* 

	END FOREACH 
	IF idx = 0 THEN 
		##### No special offers - Only sales condition
		MESSAGE kandoomsg2("E",1020,"") #1020 Sales Condition Check - RETURN TO View Detail
		INPUT BY NAME l_rec_orderpart.scroll_flag, 
		l_rec_orderpart.offer_code WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E11f","input-l_rec_orderpart-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD scroll_flag 
				LET l_rec_orderpart.scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					EXIT INPUT 
				END IF 
				
				IF fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					ERROR kandoomsg2("E",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
				
				IF fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") THEN 
					CALL disp_offer("###") 
					NEXT FIELD scroll_flag 
				END IF 

		END INPUT 
		
	ELSE 
	
		####################### special offers scan & check
		MESSAGE kandoomsg2("E",1019,"") 	#1019 Offer Check - RETURN TO View - F8 Sales Condition

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36
		 
--		CALL set_count(idx) 
		INPUT ARRAY l_arr_rec_orderpart WITHOUT DEFAULTS FROM sr_orderpart.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E11f","input-l_rec_orderpart-2") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
--				LET scrn = scr_line() 
--			BEFORE FIELD scroll2_flag 
--				DISPLAY l_arr_rec_orderpart[idx].* 
--				TO sr_orderpart[scrn].* 

			AFTER FIELD scroll2_flag 
				LET l_arr_rec_orderpart[idx].scroll2_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("E",9001,"") 
					NEXT FIELD scroll2_flag 
				END IF
				 
			BEFORE FIELD offer_code 
				CALL disp_offer(l_arr_rec_orderpart[idx].offer_code) 
				NEXT FIELD scroll2_flag
				 
			ON KEY (f8) 
				IF l_rec_orderpart.offer_code IS NOT NULL THEN 
					CALL disp_offer("###") 
					NEXT FIELD scroll2_flag 
				END IF 
--			AFTER ROW 
--				DISPLAY l_arr_rec_orderpart[idx].* 
--				TO sr_orderpart[scrn].* 

		END INPUT 
	END IF 

	CLOSE WINDOW E119 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		## Recalc line VALUES & header totals
		DECLARE c1_orderdetl cursor FOR 
		SELECT * FROM t_orderdetl 
		ORDER BY line_num 
		OPEN c1_orderdetl 
		
		FOREACH c1_orderdetl INTO l_rec_orderdetl.* 
			CALL db_t_orderdetl_update_line(l_rec_orderdetl.*) 
		END FOREACH 
		
		### Calc Totals & Line Info
		SELECT sum(ext_price_amt), 
		sum(ext_tax_amt) 
		INTO 
			glob_rec_orderhead.goods_amt, 
			glob_rec_orderhead.tax_amt 
		FROM t_orderdetl 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION check_offer()
###########################################################################


###########################################################################
# FUNCTION disp_offer(p_offer_code)
#
# 
###########################################################################
FUNCTION disp_offer(p_offer_code) 
	DEFINE p_offer_code LIKE offersale.offer_code 
	DEFINE l_rec_orderpart RECORD 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text, 
		disc_ind char(1), 
		offer_qty decimal(8,0), 
		disc_per decimal(5,2), 
		bonus_amt decimal(16,2), 
		bonus_check_per LIKE offersale.bonus_check_per, 
		bonus_check_amt LIKE offersale.bonus_check_amt, 
		disc_check_per LIKE offersale.bonus_check_per, 
		min_sold_amt LIKE offersale.min_sold_amt, 
		min_order_amt LIKE offersale.min_order_amt, 
		msg_num INTEGER, 
		msg_text char(60), 
		total_amt decimal(16,2), 
		nett_amt decimal(16,2), 
		sold_amt decimal(16,2), 
		actual_amt decimal(16,2), 
		actual_per decimal(5,2), 
		bonus_per decimal(5,2), 
		disc_base_amt decimal(16,2), 
		non_base_amt decimal(16,2) 
	END RECORD 

	SELECT * INTO l_rec_orderpart.* 
	FROM t_orderpart 
	WHERE offer_code = p_offer_code 
	IF sqlca.sqlcode = 0 THEN 

		OPEN WINDOW E117 with FORM "E117" 
		 CALL windecoration_e("E117") -- albo kd-755 
		ERROR kandoomsg2("E",1021,"") 	#1021 Special Offer/Condition Details
		IF p_offer_code = "###" THEN 
			LET l_rec_orderpart.offer_code = glob_rec_orderhead.cond_code 

			SELECT 
				sum(sold_qty*list_price_amt), 
				sum(ext_bonus_amt) 
			INTO 
				l_rec_orderpart.sold_amt, 
				l_rec_orderpart.bonus_amt 
			FROM t_orderdetl 
			WHERE offer_code IS NULL 
			AND trade_in_flag = "N" 
			AND status_ind in ("0","1","2") 

			SELECT csum(order_qty*list_price_amt) 
			INTO l_rec_orderpart.disc_base_amt 
			FROM t_orderdetl 
			WHERE offer_code IS NULL 
			AND status_ind in ("0","1","2") 
			AND disc_allow_flag = "Y" 
		
		ELSE
		 
			SELECT 
				sum(sold_qty*list_price_amt), 
				sum(ext_bonus_amt) 
			INTO 
				l_rec_orderpart.sold_amt, 
				l_rec_orderpart.bonus_amt 
			FROM t_orderdetl 
			WHERE offer_code = l_rec_orderpart.offer_code 

			SELECT sum(order_qty*list_price_amt) 
			INTO l_rec_orderpart.disc_base_amt 
			FROM t_orderdetl 
			WHERE offer_code = l_rec_orderpart.offer_code 
			AND status_ind in ("0","1","2") 
			AND disc_allow_flag = "Y" 

		END IF 

		IF l_rec_orderpart.sold_amt IS NULL THEN 
			LET l_rec_orderpart.sold_amt = 0 
		END IF 

		IF l_rec_orderpart.bonus_amt IS NULL THEN 
			LET l_rec_orderpart.bonus_amt = 0 
		END IF 

		IF l_rec_orderpart.actual_amt IS NULL THEN 
			LET l_rec_orderpart.actual_amt = 0 
		END IF 

		IF l_rec_orderpart.disc_base_amt IS NULL THEN 
			LET l_rec_orderpart.disc_base_amt = 0 
		END IF 

		LET l_rec_orderpart.actual_amt = l_rec_orderpart.total_amt	- l_rec_orderpart.nett_amt 
		LET l_rec_orderpart.non_base_amt = l_rec_orderpart.total_amt	- l_rec_orderpart.disc_base_amt 
		LET l_rec_orderpart.actual_per = l_rec_orderpart.disc_per 

		IF l_rec_orderpart.sold_amt = 0 THEN 
			LET l_rec_orderpart.bonus_per = 100 
		ELSE 
			LET l_rec_orderpart.bonus_per = (100 * l_rec_orderpart.bonus_amt)	/ (l_rec_orderpart.bonus_amt + l_rec_orderpart.sold_amt) 
		END IF 

		IF l_rec_orderpart.bonus_check_amt = 0 THEN 
			LET l_rec_orderpart.bonus_check_amt = (l_rec_orderpart.bonus_check_per/100)		* (l_rec_orderpart.sold_amt+l_rec_orderpart.bonus_amt) 
		END IF 
		
		DISPLAY BY NAME 
			l_rec_orderpart.offer_code, 
			l_rec_orderpart.desc_text, 
			l_rec_orderpart.sold_amt, 
			l_rec_orderpart.bonus_amt, 
			l_rec_orderpart.total_amt, 
			l_rec_orderpart.actual_amt, 
			l_rec_orderpart.nett_amt, 
			l_rec_orderpart.actual_per, 
			l_rec_orderpart.bonus_per, 
			l_rec_orderpart.min_sold_amt, 
			l_rec_orderpart.bonus_check_amt, 
			l_rec_orderpart.disc_base_amt, 
			l_rec_orderpart.non_base_amt, 
			l_rec_orderpart.min_order_amt, 
			l_rec_orderpart.disc_check_per, 
			l_rec_orderpart.bonus_check_per 

		IF l_rec_orderpart.msg_num = 0 THEN 
			
			CALL eventsuspend() #ERROR kandoomsg2("U",1,"")
		ELSE 
			ERROR kandoomsg2("E",l_rec_orderpart.msg_num,l_rec_orderpart.msg_text) 
		END IF 
		CLOSE WINDOW E117 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION disp_offer(p_offer_code)
###########################################################################