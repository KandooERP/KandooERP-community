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
# \brief module E11f - (Q11f !!!) Condition & Offer check
#
#  FUNCTION does the following.  IF a condition exists it IS validated
#  AND placed in a RECORD type variable.  IF special offers exist THEN
#  they are validated AND placed in an ARRAY FOR the user TO scroll thru
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 

FUNCTION check_offer() 
	DEFINE 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pr_offersale RECORD LIKE offersale.*, 
	pr_orderpart RECORD 
		scroll_flag CHAR(1), 
		offer_code LIKE orderoffer.offer_code, 
		desc_text LIKE offersale.desc_text, 
		gross_amt LIKE quotehead.total_amt, 
		net_amt LIKE quotehead.total_amt, 
		disc_ind LIKE orderoffer.disc_ind 
	END RECORD, 
	pa_orderpart array[31] OF RECORD 
		scroll2_flag CHAR(1), 
		offer_code LIKE orderoffer.offer_code, 
		desc_text LIKE offersale.desc_text, 
		gross_amt LIKE quotehead.total_amt, 
		net_amt LIKE quotehead.total_amt, 
		disc_ind LIKE orderoffer.disc_ind 
	END RECORD, 
	pr_msg_num INTEGER, 
	pr_temp_text CHAR(100), 
	idx,scrn,i SMALLINT 

	OPEN WINDOW e119 with FORM "E119" -- alch kd-747 
	CALL winDecoration_e("E119") -- alch kd-747 
	LET msgresp = kandoomsg("E",1022,"") 
	#1022 Checking Offers/Conditions - please wait
	IF pr_quotehead.cond_code IS NOT NULL THEN 
		SELECT desc_text INTO pr_orderpart.desc_text 
		FROM condsale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cond_code = pr_quotehead.cond_code 
		UPDATE t_orderpart SET desc_text = pr_orderpart.desc_text 
		WHERE offer_code = "###" 
		LET pr_orderpart.offer_code = pr_quotehead.cond_code 
		LET pr_orderpart.gross_amt = 0 
		LET pr_orderpart.net_amt = 0 
		LET pr_orderpart.disc_ind = "-" 
		DISPLAY BY NAME pr_orderpart.offer_code, 
		pr_orderpart.desc_text, 
		pr_orderpart.gross_amt, 
		pr_orderpart.net_amt, 
		pr_orderpart.disc_ind 

		CALL validate_offer(glob_rec_kandoouser.cmpy_code,"1",pr_quotehead.cond_code) 
		RETURNING pr_msg_num,pr_temp_text 
		####################### calc nett total & display
		SELECT gross_amt, 
		net_amt, 
		disc_ind 
		INTO pr_orderpart.gross_amt, 
		pr_orderpart.net_amt, 
		pr_orderpart.disc_ind 
		FROM t_orderpart 
		WHERE offer_code = "###" 
		DISPLAY BY NAME pr_orderpart.offer_code, 
		pr_orderpart.desc_text, 
		pr_orderpart.gross_amt, 
		pr_orderpart.net_amt, 
		pr_orderpart.disc_ind 

	END IF 
	LET idx = 0 
	LET scrn = 0 
	DECLARE c_orderpart CURSOR FOR 
	SELECT offer_code 
	FROM t_orderpart 
	WHERE offer_code != "###" 
	AND offer_qty > 0 
	ORDER BY offer_code 
	FOREACH c_orderpart INTO pr_orderpart.offer_code 
		SELECT desc_text INTO pr_orderpart.desc_text 
		FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = pr_orderpart.offer_code 
		UPDATE t_orderpart SET desc_text = pr_orderpart.desc_text 
		WHERE offer_code = pr_orderpart.offer_code 
		LET pr_msg_num = 0 
		LET pr_temp_text = "" 
		LET idx = idx + 1 
		LET scrn = scrn + 1 
		IF scrn > 5 THEN 
			SCROLL sr_orderpart.* up BY 1 
			LET scrn = 5 
		END IF 
		LET pa_orderpart[idx].offer_code = pr_orderpart.offer_code 
		LET pa_orderpart[idx].desc_text = pr_orderpart.desc_text 
		LET pa_orderpart[idx].gross_amt = 0 
		LET pa_orderpart[idx].net_amt = 0 
		LET pa_orderpart[idx].disc_ind = "-" 
		DISPLAY pa_orderpart[idx].* 
		TO sr_orderpart[scrn].* 

		CALL validate_offer(glob_rec_kandoouser.cmpy_code,"2",pr_orderpart.offer_code) 
		RETURNING pr_msg_num,pr_temp_text 
		IF pr_msg_num THEN 
			LET pa_orderpart[idx].disc_ind = "X" 
		ELSE 
			LET pa_orderpart[idx].disc_ind = "/" 
		END IF 
		SELECT gross_amt, 
		net_amt, 
		disc_ind 
		INTO pa_orderpart[idx].gross_amt, 
		pa_orderpart[idx].net_amt, 
		pa_orderpart[idx].disc_ind 
		FROM t_orderpart 
		WHERE offer_code = pa_orderpart[idx].offer_code 
		DISPLAY pa_orderpart[idx].* 
		TO sr_orderpart[scrn].* 

	END FOREACH 
	IF idx = 0 THEN 
		##### No special offers - Only sales condition
		LET msgresp = kandoomsg("E",1020,"") 
		#1020 Sales Condition Check - RETURN TO View Detail
		INPUT BY NAME pr_orderpart.scroll_flag, 
		pr_orderpart.offer_code WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","Q11f","inp-scroll_flag-1") -- alch kd-501 
			ON ACTION "WEB-HELP" -- albo kd-369 
				CALL onlinehelp(getmoduleid(),null) 
			AFTER FIELD scroll_flag 
				LET pr_orderpart.scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					EXIT INPUT 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					LET msgresp=kandoomsg("E",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") THEN 
					CALL disp_offer("###") 
					NEXT FIELD scroll_flag 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	ELSE 
		####################### special offers scan & check
		LET msgresp = kandoomsg("E",1019,"") 
		#1019 Offer Check - RETURN TO View - F8 Sales Condition
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		CALL set_count(idx) 
		INPUT ARRAY pa_orderpart WITHOUT DEFAULTS FROM sr_orderpart.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","Q11f","inp_arr-pa_orderpart-1") -- alch kd-501 
			ON ACTION "WEB-HELP" -- albo kd-369 
				CALL onlinehelp(getmoduleid(),null) 
			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
			BEFORE FIELD scroll2_flag 
				DISPLAY pa_orderpart[idx].* 
				TO sr_orderpart[scrn].* 

			AFTER FIELD scroll2_flag 
				LET pa_orderpart[idx].scroll2_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("E",9001,"") 
					NEXT FIELD scroll2_flag 
				END IF 
			BEFORE FIELD offer_code 
				CALL disp_offer(pa_orderpart[idx].offer_code) 
				NEXT FIELD scroll2_flag 
			ON KEY (F8) 
				IF pr_orderpart.offer_code IS NOT NULL THEN 
					CALL disp_offer("###") 
					NEXT FIELD scroll2_flag 
				END IF 
			AFTER ROW 
				DISPLAY pa_orderpart[idx].* 
				TO sr_orderpart[scrn].* 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	END IF 
	CLOSE WINDOW e119 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		## Recalc line VALUES & header totals
		DECLARE c1_quotedetl CURSOR FOR 
		SELECT * FROM t_quotedetl 
		ORDER BY line_num 
		OPEN c1_quotedetl 
		FOREACH c1_quotedetl INTO pr_quotedetl.* 
			CALL update_line(pr_quotedetl.*) 
		END FOREACH 
		### Calc Totals & Line Info
		SELECT sum(ext_price_amt), 
		sum(ext_tax_amt) 
		INTO pr_quotehead.goods_amt, 
		pr_quotehead.tax_amt 
		FROM t_quotedetl 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION disp_offer(pr_offer_code) 
	DEFINE 
	pr_offer_code LIKE offersale.offer_code, 
	pr_orderpart RECORD 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text, 
		disc_ind CHAR(1), 
		offer_qty DECIMAL(8,0), 
		disc_per DECIMAL(5,2), 
		bonus_amt DECIMAL(16,2), 
		bonus_check_per LIKE offersale.bonus_check_per, 
		bonus_check_amt LIKE offersale.bonus_check_amt, 
		disc_check_per LIKE offersale.bonus_check_per, 
		min_sold_amt LIKE offersale.min_sold_amt, 
		min_order_amt LIKE offersale.min_order_amt, 
		msg_num INTEGER, 
		msg_text CHAR(60), 
		total_amt DECIMAL(16,2), 
		nett_amt DECIMAL(16,2), 
		sold_amt DECIMAL(16,2), 
		actual_amt DECIMAL(16,2), 
		actual_per DECIMAL(5,2), 
		bonus_per DECIMAL(5,2), 
		disc_base_amt DECIMAL(16,2), 
		non_base_amt DECIMAL(16,2) 
	END RECORD 

	SELECT * INTO pr_orderpart.* 
	FROM t_orderpart 
	WHERE offer_code = pr_offer_code 
	IF sqlca.sqlcode = 0 THEN 
		OPEN WINDOW e117 with FORM "E117" -- alch kd-747 
		CALL winDecoration_e("E117") -- alch kd-747 
		LET msgresp = kandoomsg("E",1021,"") 
		#1021 Special Offer/Condition Details
		IF pr_offer_code = "###" THEN 
			LET pr_orderpart.offer_code = pr_quotehead.cond_code 
			SELECT sum(sold_qty*list_price_amt), 
			sum(ext_bonus_amt) 
			INTO pr_orderpart.sold_amt, 
			pr_orderpart.bonus_amt 
			FROM t_quotedetl 
			WHERE offer_code IS NULL 
			AND trade_in_flag = "N" 
			AND status_ind in ("0","1","2") 
			SELECT sum(order_qty*list_price_amt) 
			INTO pr_orderpart.disc_base_amt 
			FROM t_quotedetl 
			WHERE offer_code IS NULL 
			AND status_ind in ("0","1","2") 
			AND disc_allow_flag = "Y" 
		ELSE 
			SELECT sum(sold_qty*list_price_amt), 
			sum(ext_bonus_amt) 
			INTO pr_orderpart.sold_amt, 
			pr_orderpart.bonus_amt 
			FROM t_quotedetl 
			WHERE offer_code = pr_orderpart.offer_code 
			SELECT sum(order_qty*list_price_amt) 
			INTO pr_orderpart.disc_base_amt 
			FROM t_quotedetl 
			WHERE offer_code = pr_orderpart.offer_code 
			AND status_ind in ("0","1","2") 
			AND disc_allow_flag = "Y" 
		END IF 
		IF pr_orderpart.sold_amt IS NULL THEN 
			LET pr_orderpart.sold_amt = 0 
		END IF 
		IF pr_orderpart.bonus_amt IS NULL THEN 
			LET pr_orderpart.bonus_amt = 0 
		END IF 
		IF pr_orderpart.actual_amt IS NULL THEN 
			LET pr_orderpart.actual_amt = 0 
		END IF 
		IF pr_orderpart.disc_base_amt IS NULL THEN 
			LET pr_orderpart.disc_base_amt = 0 
		END IF 
		LET pr_orderpart.actual_amt = pr_orderpart.total_amt 
		- pr_orderpart.nett_amt 
		LET pr_orderpart.non_base_amt = pr_orderpart.total_amt 
		- pr_orderpart.disc_base_amt 
		LET pr_orderpart.actual_per = pr_orderpart.disc_per 
		IF pr_orderpart.sold_amt = 0 THEN 
			LET pr_orderpart.bonus_per = 100 
		ELSE 
			LET pr_orderpart.bonus_per = (100 * pr_orderpart.bonus_amt) 
			/ (pr_orderpart.bonus_amt + pr_orderpart.sold_amt) 
		END IF 
		IF pr_orderpart.bonus_check_amt = 0 THEN 
			LET pr_orderpart.bonus_check_amt = 
			(pr_orderpart.bonus_check_per/100) 
			* (pr_orderpart.sold_amt+pr_orderpart.bonus_amt) 
		END IF 
		DISPLAY BY NAME pr_orderpart.offer_code, 
		pr_orderpart.desc_text, 
		pr_orderpart.sold_amt, 
		pr_orderpart.bonus_amt, 
		pr_orderpart.total_amt, 
		pr_orderpart.actual_amt, 
		pr_orderpart.nett_amt, 
		pr_orderpart.actual_per, 
		pr_orderpart.bonus_per, 
		pr_orderpart.min_sold_amt, 
		pr_orderpart.bonus_check_amt, 
		pr_orderpart.disc_base_amt, 
		pr_orderpart.non_base_amt, 
		pr_orderpart.min_order_amt, 
		pr_orderpart.disc_check_per, 
		pr_orderpart.bonus_check_per 

		IF pr_orderpart.msg_num = 0 THEN 
			CALL eventsuspend() # LET msgresp = kandoomsg("U",1,"") 
		ELSE 
			LET msgresp = kandoomsg("E",pr_orderpart.msg_num,pr_orderpart.msg_text) 
		END IF 
		CLOSE WINDOW e117 
	END IF 
END FUNCTION 
