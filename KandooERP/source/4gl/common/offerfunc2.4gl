{
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

	Source code beautified by beautify.pl on 2020-01-02 10:35:20	$Id: $
}



#
#  FUNCTION offerfunc - Condition & Offer validation
#
#  This FUNCTION receives a offer (OR condition) code AND validates its
#  usage within a sale.  IF valid THEN the approriate discounts are
#  calculated.  The table t_quotedetl IS used TO interface with lines
#  in the sale.
#
#  program note  1. The temp table COLUMN t_quotedetl.job_code IS used
#                   within the scope of the program TO indicate
#                   (TRUE/FALSE) whether a orderline has been
#                   included in a discount allocation.  It avoids a
#                   line item receiving more than one discount.
#                2. The entry INTO t_orderpart with offer_code = ### IS
#                   the condition.  Only used within this source module
#                   the condition.  Any other value IS a special offer.
#                3. The t_orderpart table represents the offers being
#                   used within a sale AND various attributes of how the
#                   the offer IS being used, ie: nett/gross/disc etc.
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION validate_offer(p_cmpy,p_type_ind,p_type_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_type_ind CHAR(1) ## 1 condition, 2 offer 
	DEFINE p_type_code LIKE offersale.offer_code ## offer/condition code`` 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 
	DEFINE l_rec_orderoffer RECORD LIKE orderoffer.* 
	DEFINE l_rec_quotedetl RECORD LIKE quotedetl.* 
	DEFINE l_rec_proddisc RECORD LIKE proddisc.* 
	DEFINE l_rec_conddisc RECORD LIKE conddisc.* 
	DEFINE l_rec_offerprod RECORD 
		type_ind LIKE offerprod.type_ind, 
		maingrp_code LIKE offerprod.maingrp_code, 
		prodgrp_code LIKE offerprod.prodgrp_code, 
		part_code LIKE offerprod.part_code, 
		reqd_qty FLOAT, 
		allocated_qty FLOAT 
	END RECORD 
	DEFINE l_rec_proddisc1 RECORD 
		type_ind CHAR(1), 
		key_num CHAR(3), 
		maingrp_code CHAR(3), 
		prodgrp_code CHAR(3), 
		part_code CHAR(15), 
		reqd_amt DECIMAL(16,2), 
		allocated_amt DECIMAL(16,2), 
		reqd_qty FLOAT, 
		allocated_qty FLOAT, 
		disc_per DECIMAL(6,3), 
		poss_disc_amt DECIMAL(16,2), 
		disc_taken_ind SMALLINT 
	END RECORD 
	DEFINE l_total_grs_amt DECIMAL(16,2)
	DEFINE l_total_net_amt DECIMAL(16,2)
	DEFINE l_total_sold_amt DECIMAL(16,2)
	DEFINE l_total_bonus_amt DECIMAL(16,2)
	DEFINE l_total_disc_amt DECIMAL(16,2)
	DEFINE l_disc_base_amt DECIMAL(16,2) 
	DEFINE l_bonus_disc_per DECIMAL(6,3)
	DEFINE l_actual_disc_per DECIMAL(6,3) 
	DEFINE l_avail_qty FLOAT 
	DEFINE l_calc_disc CHAR(1) 
	DEFINE l_disc_ind CHAR(1) 
	DEFINE l_rowid INTEGER
	DEFINE l_query_text CHAR(2200) 
	DEFINE i INTEGER
	DEFINE r_error_code INTEGER
	DEFINE r_temp_text CHAR(100) 

	IF p_type_ind = "1" THEN ### condition validation 
		SELECT * INTO l_rec_condsale.* 
		FROM condsale 
		WHERE cmpy_code = p_cmpy 
		AND cond_code = p_type_code 
		LET r_error_code = 0 
		############################# calc condition total amounts
		SELECT sum(sold_qty*list_price_amt), 
		sum(ext_bonus_amt) 
		INTO l_total_sold_amt, 
		l_total_bonus_amt 
		FROM t_quotedetl 
		WHERE offer_code IS NULL 
		AND status_ind in ("0","1","2") 
		AND trade_in_flag = "N" 
		IF l_total_sold_amt IS NULL THEN 
			LET l_total_sold_amt = 0 
		END IF 
		IF l_total_bonus_amt IS NULL THEN 
			LET l_total_bonus_amt = 0 
		END IF 
		############################# calc. condition discount base
		SELECT sum(list_price_amt*order_qty) INTO l_disc_base_amt 
		FROM t_quotedetl 
		WHERE offer_code IS NULL 
		AND status_ind in ("0","1","2") 
		AND disc_allow_flag = "Y" 
		IF l_disc_base_amt IS NULL THEN 
			LET l_disc_base_amt = 0 
		END IF 
		############################# SELECT appropiate 'conddisc'
		IF l_rec_condsale.tier_disc_flag = "Y" THEN 
			DECLARE c_conddisc CURSOR FOR 
			SELECT * FROM conddisc 
			WHERE cmpy_code = p_cmpy 
			AND cond_code = p_type_code 
			AND reqd_amt <= l_total_sold_amt 
			ORDER BY reqd_amt desc 
			OPEN c_conddisc 
			FETCH c_conddisc INTO l_rec_conddisc.* 
			IF sqlca.sqlcode = notfound THEN 
				#### calculate discount based on list
				LET l_rec_conddisc.reqd_amt = 0 
				LET l_rec_conddisc.bonus_check_per = 0 
				LET l_rec_conddisc.disc_check_per = 0 
				LET l_rec_conddisc.disc_per = 0 
			END IF 
		END IF 
		###################### distribute discount %'s
		IF l_rec_condsale.prodline_disc_flag = "N" THEN 
			IF l_rec_condsale.tier_disc_flag = "Y" THEN 
				UPDATE t_quotedetl 
				SET disc_per = l_rec_conddisc.disc_per, 
				job_code = true ##job_code =>disc_taken_ind(see note) 
				WHERE offer_code IS NULL 
				AND status_ind in ("0","1","2") 
				AND disc_allow_flag = "Y" 
				AND job_code = false ##job_code =>disc_taken_ind(see note) 
			END IF 
		ELSE 
			DELETE FROM t_proddisc WHERE 1=1 
			INSERT INTO t_proddisc SELECT type_ind, 
			key_num, 
			maingrp_code, 
			prodgrp_code, 
			part_code, 
			reqd_amt, 0, 
			reqd_qty, 0, 
			disc_per, 0, 0 
			FROM proddisc 
			WHERE cmpy_code = p_cmpy 
			AND type_ind = "1" 
			AND key_num = p_type_code 

			###-Remove any t_proddisc rows that are NOT relevant TO the -###
			###-current SET of sales ORDER products                     -###
			###- check t_quotedetl records that do NOT match a          -###
			###- t_proddisc with the combination of:                    -###
			###-  1. maingrp+prodgrp IS NULL+part IS NULL               -###
			###-  2. part only (prodgrp, maingrp are NOT NULL)          -###
			###-  3. prodgrp AND maingrp (part_code IS NULL)            -###
			DELETE FROM t_proddisc 
			WHERE part_code IS NULL 
			AND prodgrp_code IS NULL 
			AND maingrp_code NOT in 
			(SELECT maingrp_code 
			FROM t_quotedetl 
			WHERE offer_code IS NULL 
			AND status_ind in ("0","1","2") 
			AND job_code = false ## discount taken ind 
			AND disc_allow_flag = "Y") 
			DELETE FROM t_proddisc 
			WHERE part_code IS NOT NULL 
			AND part_code NOT in 
			(SELECT part_code 
			FROM t_quotedetl 
			WHERE offer_code IS NULL 
			AND status_ind in ("0","1","2") 
			AND job_code = false ## discount taken ind 
			AND disc_allow_flag = "Y") 
			DECLARE c2_proddisc CURSOR FOR 
			SELECT * FROM t_proddisc 
			FOREACH c2_proddisc INTO l_rec_proddisc1.* 
				IF l_rec_proddisc1.part_code IS NULL THEN 
					IF l_rec_proddisc1.prodgrp_code IS NOT NULL THEN 
						SELECT unique 1 FROM t_quotedetl 
						WHERE prodgrp_code = l_rec_proddisc1.prodgrp_code 
						AND maingrp_code = l_rec_proddisc1.maingrp_code 
						AND offer_code IS NULL 
						AND status_ind in ("0","1","2") 
						AND job_code = false ## discount taken ind 
						AND disc_allow_flag = "Y" 
						IF status = notfound THEN 
							DELETE FROM t_proddisc 
							WHERE part_code IS NULL 
							AND prodgrp_code = l_rec_proddisc1.prodgrp_code 
							AND maingrp_code = l_rec_proddisc1.maingrp_code 
						END IF 
					END IF 
				END IF 
			END FOREACH 
			DECLARE c0_quotedetl CURSOR FOR 
			SELECT part_code, 
			prodgrp_code, 
			maingrp_code, 
			sum(sold_qty*list_price_amt) 
			FROM t_quotedetl 
			WHERE offer_code IS NULL 
			AND status_ind in ("0","1","2") 
			AND job_code = false ## discount taken ind 
			AND disc_allow_flag = "Y" 
			GROUP BY part_code, 
			prodgrp_code, 
			maingrp_code 
			FOREACH c0_quotedetl INTO l_rec_quotedetl.part_code, 
				l_rec_quotedetl.prodgrp_code, 
				l_rec_quotedetl.maingrp_code, 
				l_rec_quotedetl.ext_price_amt 
				UPDATE t_proddisc 
				SET allocated_amt = allocated_amt+l_rec_quotedetl.ext_price_amt, 
				poss_disc_amt = poss_disc_amt 
				+ ((disc_per/100) 
				* l_rec_quotedetl.ext_price_amt), 
				disc_taken_ind = false 
				WHERE type_ind = "1" 
				AND key_num = p_type_code 
				AND maingrp_code = l_rec_quotedetl.maingrp_code 
				AND (prodgrp_code IS NULL 
				OR prodgrp_code = l_rec_quotedetl.prodgrp_code) 
				AND (part_code IS NULL OR part_code = l_rec_quotedetl.part_code) 
			END FOREACH 
			WHILE true 
				DELETE FROM t_proddisc 
				WHERE reqd_amt > allocated_amt 
				AND key_num = p_type_code 
				AND type_ind = "1" 
				AND disc_taken_ind = false 
				DECLARE c_proddisc CURSOR FOR 
				SELECT rowid, 
				part_code, 
				prodgrp_code, 
				maingrp_code, 
				poss_disc_amt, 
				disc_per 
				FROM t_proddisc 
				WHERE type_ind = "1" 
				AND key_num = p_type_code 
				AND disc_taken_ind = false 
				ORDER BY poss_disc_amt desc 
				OPEN c_proddisc 
				FETCH c_proddisc INTO l_rowid, 
				l_rec_proddisc.part_code, 
				l_rec_proddisc.prodgrp_code, 
				l_rec_proddisc.maingrp_code, 
				l_rec_proddisc.reqd_amt, 
				l_rec_proddisc.disc_per 
				IF sqlca.sqlcode = 0 THEN 
					UPDATE t_proddisc 
					SET disc_taken_ind = true 
					WHERE rowid = l_rowid 
					LET l_query_text = 
					"SELECT line_num,", 
					"part_code,", 
					"prodgrp_code,", 
					"maingrp_code,", 
					"(list_price_amt*sold_qty) ", 
					"FROM t_quotedetl ", 
					"WHERE offer_code IS NULL ", 
					"AND status_ind in ('0','1','2') ", 
					"AND job_code=0 ", 
					"AND disc_allow_flag='Y' ", 
					"AND sold_qty!= 0 ", 
					"AND maingrp_code= '",l_rec_proddisc.maingrp_code,"'" 
					IF l_rec_proddisc.prodgrp_code IS NOT NULL THEN 
						LET l_query_text = l_query_text CLIPPED," ", 
						"AND prodgrp_code='",l_rec_proddisc.prodgrp_code,"'" 
					END IF 
					IF l_rec_proddisc.part_code IS NOT NULL THEN 
						LET l_query_text = l_query_text CLIPPED," ", 
						"AND part_code='",l_rec_proddisc.part_code,"'" 
					END IF 
					PREPARE s1_quotedetl FROM l_query_text 
					DECLARE c1_quotedetl CURSOR FOR s1_quotedetl 
					FOREACH c1_quotedetl INTO l_rec_quotedetl.line_num, 
						l_rec_quotedetl.part_code, 
						l_rec_quotedetl.prodgrp_code, 
						l_rec_quotedetl.maingrp_code, 
						l_rec_quotedetl.ext_price_amt 
						UPDATE t_quotedetl 
						SET disc_per = l_rec_proddisc.disc_per, 
						job_code = true ##job_code =>disc_taken_ind 
						WHERE line_num = l_rec_quotedetl.line_num 
						UPDATE t_proddisc 
						SET allocated_amt = allocated_amt 
						- l_rec_quotedetl.ext_price_amt, 
						poss_disc_amt = poss_disc_amt 
						- ((disc_per/100) 
						*l_rec_quotedetl.ext_price_amt) 
						WHERE type_ind = "1" 
						AND key_num = p_type_code 
						AND maingrp_code = l_rec_quotedetl.maingrp_code 
						AND (prodgrp_code IS NULL 
						OR prodgrp_code = l_rec_quotedetl.prodgrp_code) 
						AND (part_code IS NULL 
						OR part_code = l_rec_quotedetl.part_code) 
					END FOREACH 
				ELSE 
					EXIT WHILE 
				END IF 
			END WHILE 
			IF l_rec_condsale.tier_disc_flag = "Y" THEN 
				UPDATE t_quotedetl 
				SET disc_per = l_rec_conddisc.disc_per, 
				job_code = true ##job_code =>disc_taken_ind(see note) 
				WHERE offer_code IS NULL 
				AND status_ind in ("0","1","2") 
				AND disc_allow_flag = "Y" 
				AND job_code = false ##job_code =>disc_taken_ind(see note) 
			END IF 
		END IF 
		####################### Update Line Item Discount & Price
		DECLARE c1_t_quotedetl CURSOR FOR 
		SELECT * FROM t_quotedetl 
		WHERE status_ind in ('0','1','2') 
		AND offer_code IS NULL 
		LET l_total_grs_amt = 0 
		LET l_total_net_amt = 0 
		FOREACH c1_t_quotedetl INTO l_rec_quotedetl.* 
			LET l_calc_disc = "Y" 
			IF l_rec_quotedetl.trade_in_flag = "Y" THEN 
				LET l_calc_disc = "N" 
			END IF 
			IF l_rec_quotedetl.list_price_amt = 0 THEN 
				LET l_calc_disc = "N" 
			END IF 
			IF l_rec_quotedetl.list_price_amt < l_rec_quotedetl.unit_price_amt THEN 
				LET l_calc_disc = "N" 
			END IF 
			IF NOT l_rec_quotedetl.job_code THEN 
				## use whatever price entered in line item entry routine
				LET l_calc_disc = "N" 
			END IF 
			LET l_rec_quotedetl.bonus_disc_amt = 0 
			IF l_rec_quotedetl.disc_allow_flag = "Y" THEN 
				IF l_disc_base_amt != 0 THEN 
					LET l_rec_quotedetl.bonus_disc_amt = l_rec_quotedetl.list_price_amt 
					* l_rec_quotedetl.order_qty 
					* (l_total_bonus_amt/l_disc_base_amt) 
				END IF 
			END IF 
			IF l_calc_disc = "Y" THEN 
				## calc price based on disc
				LET l_rec_quotedetl.disc_amt = l_rec_quotedetl.sold_qty 
				* (l_rec_quotedetl.list_price_amt-l_rec_quotedetl.unit_price_amt) 
				LET l_rec_quotedetl.unit_price_amt = l_rec_quotedetl.list_price_amt 
				-(l_rec_quotedetl.list_price_amt*(l_rec_quotedetl.disc_per/100)) 
				UPDATE t_quotedetl 
				SET unit_price_amt = l_rec_quotedetl.unit_price_amt, 
				disc_amt = l_rec_quotedetl.disc_amt 
				WHERE line_num = l_rec_quotedetl.line_num 
			END IF 
			LET l_total_grs_amt = l_total_grs_amt + 
			(l_rec_quotedetl.order_qty*l_rec_quotedetl.list_price_amt) 
			LET l_total_net_amt = l_total_net_amt + 
			(l_rec_quotedetl.sold_qty*l_rec_quotedetl.unit_price_amt) 
		END FOREACH 
		LET l_actual_disc_per = 0 
		IF l_disc_base_amt != 0 THEN 
			LET l_total_disc_amt = l_total_grs_amt - l_total_net_amt 
			LET l_actual_disc_per = (l_total_disc_amt/l_disc_base_amt)*100 
			###-Combined the section commented below-###
			IF (l_actual_disc_per < 0) OR 
			(l_actual_disc_per IS null) 
			THEN 
				LET l_actual_disc_per = 0 
			END IF 
		ELSE 
			IF l_total_bonus_amt > 0 THEN 
				## Cannot apply bonus_value discount as lines NOT discountable
				LET r_error_code = 7036 
			END IF 
		END IF 
		####################### Check actual & bonus % TO condition limits
		IF l_actual_disc_per > l_rec_conddisc.disc_check_per THEN 
			IF r_error_code = 0 THEN 
				#7020" Actual discount percentage exceeded condition limit"
				LET r_error_code = 7020 
			END IF 
		ELSE 
			IF l_total_bonus_amt = 0 THEN 
				LET l_bonus_disc_per = 0 
			ELSE 
				LET l_bonus_disc_per = (l_total_bonus_amt*100) 
				/ (l_total_sold_amt + l_total_bonus_amt) 
			END IF 
			IF l_bonus_disc_per > l_rec_conddisc.bonus_check_per THEN 
				IF r_error_code = 0 THEN 
					LET r_error_code = 7021 
					#7021" Bonus discount percentage exceeded condition limit"
				END IF 
			END IF 
		END IF 
		IF r_error_code THEN 
			LET l_disc_ind = "X" 
		ELSE 
			LET l_disc_ind = "A" 
		END IF 
		UPDATE t_orderpart 
		SET disc_ind = l_disc_ind, 
		desc_text = l_rec_condsale.desc_text, 
		disc_per = l_actual_disc_per, 
		bonus_amt = l_total_bonus_amt, 
		bonus_check_per = l_rec_conddisc.bonus_check_per, 
		disc_check_per = l_rec_conddisc.disc_check_per, 
		min_sold_amt = l_rec_conddisc.reqd_amt, 
		min_order_amt = l_rec_conddisc.reqd_amt, 
		msg_num = r_error_code, 
		gross_amt = l_total_grs_amt, 
		net_amt = l_total_net_amt 
		WHERE offer_code = "###" ### identifies t_orderpart.sale_condition 
	ELSE 
		SELECT offer_code, 
		offer_qty 
		INTO l_rec_orderoffer.offer_code, 
		l_rec_orderoffer.offer_qty 
		FROM t_orderpart 
		WHERE offer_code = p_type_code 
		AND offer_qty > 0 
		DELETE FROM t_offerprod WHERE 1=1 
		LET r_error_code = 0 
		LET r_temp_text = "" 
		SELECT * INTO l_rec_offersale.* 
		FROM offersale 
		WHERE cmpy_code = p_cmpy 
		AND offer_code = l_rec_orderoffer.offer_code 
		############################## calc.total offer amounts
		SELECT sum(sold_qty*list_price_amt), 
		sum(ext_bonus_amt) 
		INTO l_total_sold_amt, 
		l_total_bonus_amt 
		FROM t_quotedetl 
		WHERE offer_code = l_rec_offersale.offer_code 
		AND status_ind in ("0","1","2") 
		IF l_total_sold_amt IS NULL THEN 
			LET l_total_sold_amt = 0 
		END IF 
		IF l_total_bonus_amt IS NULL THEN 
			LET l_total_bonus_amt = 0 
		END IF 
		############################## calc.offer discount base
		SELECT sum(list_price_amt*order_qty) 
		INTO l_disc_base_amt 
		FROM t_quotedetl 
		WHERE offer_code = l_rec_orderoffer.offer_code 
		AND status_ind in ("0","1","2") 
		AND disc_allow_flag = "Y" 
		IF l_disc_base_amt IS NULL THEN 
			LET l_disc_base_amt = 0 
			IF l_total_bonus_amt > 0 THEN 
				IF r_error_code = 0 THEN 
					## Cannot apply bonus_value discount as lines NOT discountable
					LET r_error_code = 7036 
				END IF 
			END IF 
		END IF 
		####################### Determine disc. check amounts & %'s
		CASE l_rec_offersale.disc_rule_ind 
			WHEN "1" 
				### use check amounts FROM special offer
				IF l_rec_offersale.bonus_check_per = 0 THEN 
					## Convert check amt INTO check percentage
					LET l_rec_offersale.bonus_check_amt = l_rec_offersale.bonus_check_amt 
					* l_rec_orderoffer.offer_qty 
					IF (l_total_sold_amt+l_total_bonus_amt) = 0 THEN 
						LET l_rec_offersale.bonus_check_per = 0 
					ELSE 
						LET l_rec_offersale.bonus_check_per = 
						(100*l_rec_offersale.bonus_check_amt) 
						/ (l_total_sold_amt+l_total_bonus_amt) 
					END IF 
				END IF 
			WHEN "2" 
				### use check amounts FROM sales condition
				IF l_rec_condsale.cond_code IS NULL THEN 
					IF r_error_code = 0 THEN 
						#7026" Special offer requires sales condition"
						LET r_error_code = 7026 
					END IF 
					LET l_rec_offersale.bonus_check_per = 0 
					LET l_rec_offersale.bonus_check_amt = 0 
					LET l_rec_offersale.disc_check_per = 0 
				ELSE 
					LET l_rec_offersale.bonus_check_per = l_rec_conddisc.bonus_check_per 
					LET l_rec_offersale.bonus_check_amt = 0 
					LET l_rec_offersale.disc_check_per = l_rec_conddisc.disc_check_per 
				END IF 
			WHEN "3" 
				### use check amounts FROM max(offer,condition)
				IF l_rec_offersale.bonus_check_per = 0 THEN 
					## Convert check amt INTO check percentage
					LET l_rec_offersale.bonus_check_amt = l_rec_offersale.bonus_check_amt 
					* l_rec_orderoffer.offer_qty 
					IF (l_total_sold_amt+l_total_bonus_amt) = 0 THEN 
						LET l_rec_offersale.bonus_check_per = 0 
					ELSE 
						LET l_rec_offersale.bonus_check_per = 
						(100*l_rec_offersale.bonus_check_amt) 
						/ (l_total_sold_amt+l_total_bonus_amt) 
					END IF 
				END IF 
				IF l_rec_conddisc.bonus_check_per>l_rec_offersale.bonus_check_per THEN 
					LET l_rec_offersale.bonus_check_per = l_rec_conddisc.bonus_check_per 
				END IF 
				IF l_rec_conddisc.disc_check_per > l_rec_offersale.disc_check_per THEN 
					LET l_rec_offersale.disc_check_per = l_rec_conddisc.disc_check_per 
				END IF 
		END CASE 
		############################## minimum required amount calc
		LET l_rec_offersale.min_sold_amt = l_rec_offersale.min_sold_amt 
		* l_rec_orderoffer.offer_qty 
		LET l_rec_offersale.min_order_amt = l_rec_offersale.min_order_amt 
		* l_rec_orderoffer.offer_qty 
		##
		##########   Offer checking
		IF l_rec_offersale.checkrule_ind > "1" THEN 
			######################## minimum required amount checking
			IF l_total_sold_amt < l_rec_offersale.min_sold_amt THEN 
				IF r_error_code = 0 THEN 
					#7022" Sold Amt < minimum required FOR this offer"
					LET r_error_code = 7022 
				END IF 
			END IF 
			IF (l_total_sold_amt + l_total_bonus_amt) 
			< l_rec_offersale.min_order_amt THEN 
				IF r_error_code = 0 THEN 
					#7023" Offer Amount < minimum required "
					LET r_error_code = 7023 
				END IF 
			END IF 
			IF l_rec_offersale.checkrule_ind > "2" THEN 
				## load up the offerpart table
				IF l_rec_offersale.checktype_ind = "1" THEN 
					INSERT INTO t_offerprod 
					SELECT type_ind, 
					maingrp_code, 
					prodgrp_code, 
					part_code, 
					(reqd_qty*l_rec_orderoffer.offer_qty), 0 
					FROM offerprod 
					WHERE cmpy_code = p_cmpy 
					AND offer_code = l_rec_orderoffer.offer_code 
				ELSE 
					INSERT INTO t_offerprod 
					SELECT type_ind, 
					maingrp_code, 
					prodgrp_code, 
					part_code, 
					(reqd_amt*l_rec_orderoffer.offer_qty), 0 
					FROM offerprod 
					WHERE cmpy_code = p_cmpy 
					AND offer_code = l_rec_orderoffer.offer_code 
				END IF 
				IF l_rec_offersale.checkrule_ind = "3" 
				OR l_rec_offersale.checkrule_ind = "5" THEN 
					####################### sold value check IF any row valid
					SELECT unique 1 FROM t_quotedetl 
					WHERE offer_code = l_rec_orderoffer.offer_code 
					AND status_ind in ("0","1","2") 
					AND sold_qty != 0 
					AND (autoinsert_flag = "N" OR 
					autoinsert_flag IS null) 
					IF sqlca.sqlcode = 0 THEN 
						DECLARE c2_quotedetl CURSOR FOR 
						SELECT part_code, 
						prodgrp_code, 
						maingrp_code, 
						sum(sold_qty), 
						sum(sold_qty*list_price_amt) 
						FROM t_quotedetl 
						WHERE offer_code = l_rec_orderoffer.offer_code 
						AND status_ind in ("0","1","2") 
						AND sold_qty != 0 
						AND (autoinsert_flag = "N" OR 
						autoinsert_flag IS null) 
						GROUP BY part_code, 
						prodgrp_code, 
						maingrp_code 
						FOREACH c2_quotedetl INTO l_rec_quotedetl.part_code, 
							l_rec_quotedetl.prodgrp_code, 
							l_rec_quotedetl.maingrp_code, 
							l_rec_quotedetl.sold_qty, 
							l_rec_quotedetl.ext_price_amt 
							IF l_rec_offersale.checktype_ind = "1" THEN 
								LET l_avail_qty = l_rec_quotedetl.sold_qty 
							ELSE 
								LET l_avail_qty = l_rec_quotedetl.ext_price_amt 
							END IF 
							FOR i = 1 TO 3 
								LET l_query_text = "SELECT rowid,* FROM t_offerprod ", 
								"WHERE type_ind = \"1\" ", 
								"AND allocated_qty < reqd_qty" 
								CASE i 
									WHEN 1 
										LET l_query_text = l_query_text CLIPPED," ", 
										"AND part_code=\"",l_rec_quotedetl.part_code,"\" ", 
										"AND prodgrp_code=\"",l_rec_quotedetl.prodgrp_code,"\" ", 
										"AND maingrp_code=\"",l_rec_quotedetl.maingrp_code,"\"" 
									WHEN 2 
										LET l_query_text = l_query_text CLIPPED," ", 
										"AND part_code IS NULL ", 
										"AND prodgrp_code=\"",l_rec_quotedetl.prodgrp_code,"\" ", 
										"AND maingrp_code=\"",l_rec_quotedetl.maingrp_code,"\"" 
									WHEN 3 
										LET l_query_text = l_query_text CLIPPED," ", 
										"AND part_code IS NULL ", 
										"AND prodgrp_code IS NULL ", 
										"AND maingrp_code =\"",l_rec_quotedetl.maingrp_code,"\"" 
								END CASE 
								PREPARE s1_offerprod FROM l_query_text 
								DECLARE c1_offerprod CURSOR FOR s1_offerprod 
								OPEN c1_offerprod 
								FETCH c1_offerprod INTO l_rowid, l_rec_offerprod.* 
								IF sqlca.sqlcode = 0 THEN 
									IF (l_rec_offerprod.allocated_qty + l_avail_qty) 
									> l_rec_offerprod.reqd_qty THEN 
										UPDATE t_offerprod 
										SET allocated_qty = reqd_qty 
										WHERE rowid = l_rowid 
										LET l_avail_qty = l_avail_qty 
										- l_rec_offerprod.reqd_qty 
										+ l_rec_offerprod.allocated_qty 
									ELSE 
										UPDATE t_offerprod 
										SET allocated_qty = allocated_qty 
										+ l_avail_qty 
										WHERE rowid = l_rowid 
										LET l_avail_qty = 0 
									END IF 
								END IF 
							END FOR 
						END FOREACH 
						SELECT unique 1 FROM t_offerprod 
						WHERE type_ind = "1" 
						AND allocated_qty < reqd_qty 
						IF sqlca.sqlcode = 0 THEN 
							IF r_error_code = 0 THEN 
								DECLARE c2_offerprod CURSOR FOR 
								SELECT * FROM t_offerprod 
								WHERE type_ind = "1" 
								AND allocated_qty < reqd_qty 
								OPEN c2_offerprod 
								FETCH c2_offerprod INTO l_rec_offerprod.* 
								IF l_rec_offerprod.part_code IS NOT NULL THEN 
									#7039 Insufficent amount of product ????
									LET r_error_code = 7039 
									LET r_temp_text = l_rec_offerprod.part_code 
								ELSE 
									#7024 Insufficent amount of product combo
									LET r_error_code = 7024 
									LET r_temp_text = l_rec_offerprod.maingrp_code,":", 
									l_rec_offerprod.prodgrp_code 
								END IF 
							END IF 
						END IF 
					END IF 
				END IF 
				IF l_rec_offersale.checkrule_ind = "4" 
				OR l_rec_offersale.checkrule_ind = "5" THEN 
					######################### bonus value check IF any row valid
					SELECT unique 1 FROM t_quotedetl 
					WHERE offer_code = l_rec_orderoffer.offer_code 
					AND bonus_qty != 0 
					AND (autoinsert_flag = "N" OR 
					autoinsert_flag IS null) 
					IF sqlca.sqlcode = 0 THEN 
						DECLARE c3_quotedetl CURSOR FOR 
						SELECT part_code, 
						prodgrp_code, 
						maingrp_code, 
						sum(bonus_qty), 
						sum(ext_bonus_amt) 
						FROM t_quotedetl 
						WHERE offer_code = l_rec_orderoffer.offer_code 
						AND status_ind in ("0","1","2") 
						AND bonus_qty != 0 
						AND (autoinsert_flag = "N" OR 
						autoinsert_flag IS null) 
						GROUP BY part_code, 
						prodgrp_code, 
						maingrp_code 
						FOREACH c3_quotedetl INTO l_rec_quotedetl.part_code, 
							l_rec_quotedetl.prodgrp_code, 
							l_rec_quotedetl.maingrp_code, 
							l_rec_quotedetl.bonus_qty, 
							l_rec_quotedetl.ext_bonus_amt 
							IF l_rec_offersale.checktype_ind = "1" THEN 
								LET l_avail_qty = l_rec_quotedetl.bonus_qty 
							ELSE 
								LET l_avail_qty = l_rec_quotedetl.ext_bonus_amt 
							END IF 
							FOR i = 1 TO 3 
								LET l_query_text = "SELECT rowid,* FROM t_offerprod ", 
								"WHERE type_ind = \"2\" ", 
								"AND allocated_qty < reqd_qty" 
								CASE i 
									WHEN 1 
										LET l_query_text = l_query_text CLIPPED," ", 
										"AND part_code=\"",l_rec_quotedetl.part_code,"\" ", 
										"AND prodgrp_code=\"",l_rec_quotedetl.prodgrp_code,"\" ", 
										"AND maingrp_code=\"",l_rec_quotedetl.maingrp_code,"\"" 
									WHEN 2 
										LET l_query_text = l_query_text CLIPPED," ", 
										"AND part_code IS NULL ", 
										"AND prodgrp_code=\"",l_rec_quotedetl.prodgrp_code,"\" ", 
										"AND maingrp_code=\"",l_rec_quotedetl.maingrp_code,"\"" 
									WHEN 3 
										LET l_query_text = l_query_text CLIPPED," ", 
										"AND part_code IS NULL ", 
										"AND prodgrp_code IS NULL ", 
										"AND maingrp_code=\"",l_rec_quotedetl.maingrp_code,"\"" 
								END CASE 
								PREPARE s3_offerprod FROM l_query_text 
								DECLARE c3_offerprod CURSOR FOR s3_offerprod 
								OPEN c3_offerprod 
								FETCH c3_offerprod INTO l_rowid, l_rec_offerprod.* 
								IF sqlca.sqlcode = 0 THEN 
									IF (l_rec_offerprod.allocated_qty + l_avail_qty) 
									> l_rec_offerprod.reqd_qty THEN 
										UPDATE t_offerprod 
										SET allocated_qty = reqd_qty 
										WHERE rowid = l_rowid 
										LET l_avail_qty = l_avail_qty 
										- l_rec_offerprod.reqd_qty 
										+ l_rec_offerprod.allocated_qty 
									ELSE 
										UPDATE t_offerprod 
										SET allocated_qty = allocated_qty 
										+ l_avail_qty 
										WHERE rowid = l_rowid 
										LET l_avail_qty = 0 
									END IF 
								END IF 
							END FOR 
							IF l_avail_qty > 0 THEN 
								IF r_error_code = 0 THEN 
									#7025" Bonus products value has > limitations"
									LET r_error_code = 7025 
									LET r_temp_text = l_rec_quotedetl.maingrp_code,":", 
									l_rec_quotedetl.prodgrp_code,":", 
									l_rec_quotedetl.part_code 
								END IF 
							END IF 
						END FOREACH 
					END IF 
				END IF 
			END IF 
		END IF 
		IF NOT r_error_code THEN 
			############################################ calc.discount
			IF l_rec_offersale.prodline_disc_flag = "N" THEN 
				IF l_rec_offersale.disc_per > 0 THEN 
					IF l_disc_base_amt = 0 THEN 
						IF r_error_code = 0 THEN 
							## Cannot apply cash discount as no lines are discountable
							LET r_error_code = 7037 
						END IF 
					END IF 
				END IF 
				UPDATE t_quotedetl 
				SET disc_per = l_rec_offersale.disc_per, 
				job_code = true ##job_code =>disc_taken_ind(see note) 
				WHERE offer_code = l_rec_orderoffer.offer_code 
				AND disc_allow_flag = "Y" 
				AND job_code = false ##job_code =>disc_taken_ind(see note) 
			ELSE 
				###-ensure the t_proddisc table IS empty before processing-###
				DELETE FROM t_proddisc WHERE 1=1 
				INSERT INTO t_proddisc 
				SELECT type_ind, 
				key_num, 
				maingrp_code, 
				prodgrp_code, 
				part_code, 
				reqd_amt, 0, 
				reqd_qty, 0, 
				disc_per,0,0 
				FROM proddisc 
				WHERE cmpy_code = p_cmpy 
				AND type_ind = "2" 
				AND key_num = l_rec_orderoffer.offer_code 
				###-Remove any t_proddisc rows that are NOT relevant TO the -###
				###-current SET of sales ORDER products                     -###
				###- check t_quotedetl records that do NOT match a          -###
				###- t_proddisc with the combination of:                    -###
				###-  1. maingrp+prodgrp IS NULL+part IS NULL               -###
				###-  2. part only (prodgrp, maingrp are NOT NULL)          -###
				###-  3. prodgrp AND maingrp (part_code IS NULL)            -###
				DELETE FROM t_proddisc 
				WHERE part_code IS NULL 
				AND prodgrp_code IS NULL 
				AND maingrp_code NOT in 
				(SELECT maingrp_code 
				FROM t_quotedetl 
				WHERE offer_code = l_rec_orderoffer.offer_code 
				AND sold_qty != 0 
				AND disc_allow_flag = "Y") 
				DELETE FROM t_proddisc 
				WHERE part_code IS NOT NULL 
				AND part_code NOT in 
				(SELECT part_code 
				FROM t_quotedetl 
				WHERE offer_code = l_rec_orderoffer.offer_code 
				AND sold_qty != 0 
				AND disc_allow_flag = "Y") 
				DECLARE c0_proddisc CURSOR FOR 
				SELECT * FROM t_proddisc 
				FOREACH c0_proddisc INTO l_rec_proddisc1.* 
					IF l_rec_proddisc1.part_code IS NULL THEN 
						IF l_rec_proddisc1.prodgrp_code IS NOT NULL THEN 
							SELECT unique 1 FROM t_quotedetl 
							WHERE prodgrp_code = l_rec_proddisc1.prodgrp_code 
							AND maingrp_code = l_rec_proddisc1.maingrp_code 
							AND offer_code = l_rec_orderoffer.offer_code 
							AND sold_qty != 0 
							AND disc_allow_flag = "Y" 
							IF status = notfound THEN 
								DELETE FROM t_proddisc 
								WHERE part_code IS NULL 
								AND prodgrp_code = l_rec_proddisc1.prodgrp_code 
								AND maingrp_code = l_rec_proddisc1.maingrp_code 
							END IF 
						END IF 
					END IF 
				END FOREACH 
				DECLARE c4_quotedetl CURSOR FOR 
				SELECT part_code, 
				prodgrp_code, 
				maingrp_code, 
				sum(sold_qty), 
				sum(sold_qty*list_price_amt) 
				FROM t_quotedetl 
				WHERE offer_code = l_rec_orderoffer.offer_code 
				AND sold_qty != 0 
				AND disc_allow_flag = "Y" 
				GROUP BY part_code, 
				prodgrp_code, 
				maingrp_code 
				FOREACH c4_quotedetl INTO l_rec_quotedetl.part_code, 
					l_rec_quotedetl.prodgrp_code, 
					l_rec_quotedetl.maingrp_code, 
					l_rec_quotedetl.sold_qty, 
					l_rec_quotedetl.ext_price_amt 
					UPDATE t_proddisc 
					SET allocated_qty = allocated_qty 
					+ l_rec_quotedetl.sold_qty, 
					allocated_amt = allocated_amt 
					+ l_rec_quotedetl.ext_price_amt, 
					poss_disc_amt = poss_disc_amt 
					+ ((disc_per/100) 
					* l_rec_quotedetl.ext_price_amt), 
					disc_taken_ind = false 
					WHERE type_ind = "2" 
					AND key_num = l_rec_orderoffer.offer_code 
					AND maingrp_code = l_rec_quotedetl.maingrp_code 
					AND (prodgrp_code IS NULL 
					OR prodgrp_code = l_rec_quotedetl.prodgrp_code) 
					AND (part_code IS NULL 
					OR part_code = l_rec_quotedetl.part_code) 
				END FOREACH 
				WHILE true 
					IF l_rec_offersale.checktype_ind = "1" THEN 
						DELETE FROM t_proddisc 
						WHERE type_ind = "2" 
						AND key_num = l_rec_orderoffer.offer_code 
						AND reqd_qty > allocated_qty 
						AND disc_taken_ind = false 
					ELSE 
						DELETE FROM t_proddisc 
						WHERE type_ind = "2" 
						AND key_num = l_rec_orderoffer.offer_code 
						AND reqd_amt > allocated_amt 
						AND disc_taken_ind = false 
					END IF 
					LET l_query_text = 
					"SELECT rowid,part_code,", 
					"prodgrp_code,", 
					"maingrp_code,", 
					"poss_disc_amt,", 
					"disc_per ", 
					"FROM t_proddisc ", 
					"WHERE type_ind='2' ", 
					"AND key_num = '",l_rec_orderoffer.offer_code,"' ", 
					"AND disc_taken_ind ='0' " 
					IF l_rec_offersale.grp_disc_flag = "Y" THEN 
						## poss discount regardless of grouping
						LET l_query_text = l_query_text CLIPPED," ", 
						"ORDER BY poss_disc_amt desc" 
					ELSE 
						LET l_query_text = l_query_text CLIPPED," ", 
						"ORDER BY part_code desc,", 
						"prodgrp_code desc,", 
						"maingrp_code desc,", 
						"poss_disc_amt desc" 
					END IF 
					PREPARE s1_proddisc FROM l_query_text 
					DECLARE c1_proddisc CURSOR FOR s1_proddisc 
					OPEN c1_proddisc 
					FETCH c1_proddisc INTO l_rowid, 
					l_rec_proddisc.part_code, 
					l_rec_proddisc.prodgrp_code, 
					l_rec_proddisc.maingrp_code, 
					l_rec_proddisc.reqd_amt, 
					l_rec_proddisc.disc_per 
					IF sqlca.sqlcode = 0 THEN 
						UPDATE t_proddisc 
						SET disc_taken_ind = true 
						WHERE rowid = l_rowid 
						LET l_query_text = 
						"SELECT rowid,", 
						"part_code,", 
						"prodgrp_code,", 
						"maingrp_code,", 
						"sold_qty,", 
						"(list_price_amt*sold_qty) ", 
						"FROM t_quotedetl ", 
						"WHERE offer_code ='",l_rec_orderoffer.offer_code,"' ", 
						"AND disc_allow_flag = 'Y' ", 
						"AND sold_qty > 0 ", 
						"AND maingrp_code= '",l_rec_proddisc.maingrp_code,"'" 
						IF l_rec_proddisc.prodgrp_code IS NOT NULL THEN 
							LET l_query_text = l_query_text CLIPPED," ", 
							"AND prodgrp_code='",l_rec_proddisc.prodgrp_code,"'" 
						END IF 
						IF l_rec_proddisc.part_code IS NOT NULL THEN 
							LET l_query_text = l_query_text CLIPPED," ", 
							"AND part_code='",l_rec_proddisc.part_code,"'" 
						END IF 
						PREPARE s5_quotedetl FROM l_query_text 
						DECLARE c5_quotedetl CURSOR FOR s5_quotedetl 
						FOREACH c5_quotedetl INTO l_rowid, 
							l_rec_quotedetl.part_code, 
							l_rec_quotedetl.prodgrp_code, 
							l_rec_quotedetl.maingrp_code, 
							l_rec_quotedetl.sold_qty, 
							l_rec_quotedetl.ext_price_amt 
							UPDATE t_quotedetl 
							SET disc_per = l_rec_proddisc.disc_per, 
							job_code = true ##job_code =>disc_taken_ind 
							WHERE rowid = l_rowid 
							UPDATE t_proddisc 
							SET allocated_qty = allocated_qty 
							- l_rec_quotedetl.sold_qty, 
							allocated_amt = allocated_amt 
							- l_rec_quotedetl.ext_price_amt, 
							poss_disc_amt = poss_disc_amt 
							- ((disc_per/100) 
							*l_rec_quotedetl.ext_price_amt) 
							WHERE key_num = l_rec_orderoffer.offer_code 
							AND type_ind = "2" 
							AND maingrp_code = l_rec_quotedetl.maingrp_code 
							AND (prodgrp_code = l_rec_quotedetl.prodgrp_code 
							OR prodgrp_code IS null) 
							AND (part_code = l_rec_quotedetl.part_code 
							OR part_code IS null) 
						END FOREACH 
					ELSE 
						EXIT WHILE 
					END IF 
				END WHILE 
				UPDATE t_quotedetl 
				SET disc_per = l_rec_offersale.disc_per, 
				job_code = true ##job_code =>disc_taken_ind(see note) 
				WHERE offer_code = l_rec_orderoffer.offer_code 
				AND sold_qty != 0 
				AND disc_allow_flag = "Y" 
				AND job_code = false ##job_code =>disc_taken_ind(see note) 
			END IF 
		END IF 
		#######################
		### Adjust orderline VALUES TO reflect cash discounts
		LET l_total_grs_amt = 0 
		LET l_total_net_amt = 0 
		LET l_query_text = "SELECT * FROM t_quotedetl ", 
		"WHERE status_ind in ('0','1','2') ", 
		"AND offer_code=?" 
		PREPARE s_t_quotedetl FROM l_query_text 
		DECLARE c_t_quotedetl CURSOR FOR s_t_quotedetl 
		OPEN c_t_quotedetl USING l_rec_offersale.offer_code 
		FOREACH c_t_quotedetl INTO l_rec_quotedetl.* 
			LET l_calc_disc = "Y" 
			IF l_rec_quotedetl.trade_in_flag = "Y" THEN 
				LET l_calc_disc = "N" 
			END IF 
			IF l_rec_quotedetl.list_price_amt = 0 THEN 
				LET l_calc_disc = "N" 
			END IF 
			IF l_rec_quotedetl.list_price_amt < l_rec_quotedetl.unit_price_amt THEN 
				LET l_calc_disc = "N" 
			END IF 
			IF l_rec_quotedetl.disc_allow_flag = "Y" THEN 
				IF l_disc_base_amt != 0 THEN 
					LET l_rec_quotedetl.bonus_disc_amt = l_rec_quotedetl.list_price_amt 
					* l_rec_quotedetl.order_qty 
					* (l_total_bonus_amt/l_disc_base_amt) 
				END IF 
			END IF 
			IF l_calc_disc = "Y" THEN 
				## calc price based on disc
				LET l_rec_quotedetl.disc_amt = l_rec_quotedetl.sold_qty 
				* (l_rec_quotedetl.list_price_amt-l_rec_quotedetl.unit_price_amt) 
				LET l_rec_quotedetl.unit_price_amt = l_rec_quotedetl.list_price_amt 
				-(l_rec_quotedetl.list_price_amt*(l_rec_quotedetl.disc_per/100)) 
				UPDATE t_quotedetl 
				SET unit_price_amt = l_rec_quotedetl.unit_price_amt, 
				disc_amt = l_rec_quotedetl.disc_amt 
				WHERE line_num = l_rec_quotedetl.line_num 
			END IF 
			LET l_total_grs_amt = l_total_grs_amt + 
			(l_rec_quotedetl.order_qty*l_rec_quotedetl.list_price_amt) 
			LET l_total_net_amt = l_total_net_amt + 
			(l_rec_quotedetl.sold_qty*l_rec_quotedetl.unit_price_amt) 
		END FOREACH 
		LET l_actual_disc_per = 0 
		IF l_disc_base_amt != 0 THEN 
			LET l_total_disc_amt = l_total_grs_amt - l_total_net_amt 
			LET l_actual_disc_per = (l_total_disc_amt/l_disc_base_amt)*100 
			IF l_actual_disc_per < 0 THEN 
				LET l_actual_disc_per = 0 
			END IF 
			IF l_actual_disc_per IS NULL THEN 
				LET l_actual_disc_per = 0 
			END IF 
		ELSE 
			LET l_actual_disc_per = 0 
		END IF 
		####################### Check actual & bonus % TO offer limits
		IF l_actual_disc_per > l_rec_offersale.disc_check_per THEN 
			IF r_error_code = 0 THEN 
				#7027" Actual Discount percentage exceeded condition limit"
				LET r_error_code = 7027 
			END IF 
		ELSE 
			### Bonus discount check
			IF l_rec_offersale.bonus_check_amt > 0 THEN 
				IF l_total_bonus_amt > l_rec_offersale.bonus_check_amt THEN 
					IF r_error_code = 0 THEN 
						#7029" Bonus Discount Amount Exceeds Offer Limit"
						LET r_error_code = 7028 
					END IF 
				END IF 
			ELSE 
				IF l_total_bonus_amt = 0 THEN 
					LET l_bonus_disc_per = 0 
				ELSE 
					LET l_bonus_disc_per =(l_total_bonus_amt*100) 
					/(l_total_sold_amt+l_total_bonus_amt) 
				END IF 
				IF l_bonus_disc_per > l_rec_offersale.bonus_check_per THEN 
					IF r_error_code = 0 THEN 
						#7029" Bonus discount percentage exceeded offer limit"
						LET r_error_code = 7029 
					END IF 
				END IF 
			END IF 
		END IF 
		IF r_error_code THEN 
			LET l_disc_ind = "X" 
		ELSE 
			LET l_disc_ind = "A" 
		END IF 
		UPDATE t_orderpart 
		SET disc_ind = l_disc_ind, 
		desc_text = l_rec_offersale.desc_text, 
		disc_per = l_actual_disc_per, 
		bonus_amt = l_total_bonus_amt, 
		bonus_check_per = l_rec_offersale.bonus_check_per, 
		bonus_check_amt = l_rec_offersale.bonus_check_amt, 
		disc_check_per = l_rec_offersale.disc_check_per, 
		min_sold_amt = l_rec_offersale.min_sold_amt, 
		min_order_amt = l_rec_offersale.min_order_amt, 
		msg_num = r_error_code, 
		msg_text = r_temp_text, 
		gross_amt = l_total_grs_amt, 
		net_amt = l_total_net_amt 
		WHERE offer_code = l_rec_offersale.offer_code 
	END IF 
	RETURN r_error_code,r_temp_text 
END FUNCTION 


FUNCTION cr_offer_tables() 
	CREATE temp TABLE t_orderpart(offer_code CHAR(3), 
	desc_text CHAR(30), 
	disc_ind CHAR(1), 
	offer_qty DECIMAL(8,0), 
	disc_per DECIMAL(5,2), 
	bonus_amt DECIMAL(16,2), 
	bonus_check_per DECIMAL(5,2), 
	bonus_check_amt DECIMAL(16,2), 
	disc_check_per DECIMAL(5,2), 
	min_sold_amt DECIMAL(16,2), 
	min_order_amt DECIMAL(16,2), 
	msg_num INTEGER, 
	msg_text CHAR(60), 
	gross_amt DECIMAL(16,2), 
	net_amt DECIMAL(16,2)) with no LOG 
	CREATE temp TABLE t_offerprod(type_ind CHAR(1), 
	maingrp_code CHAR(3), 
	prodgrp_code CHAR(3), 
	part_code CHAR(15), 
	reqd_qty FLOAT, 
	allocated_qty float) with no LOG 
	CREATE temp TABLE t_proddisc( type_ind CHAR(1), 
	key_num CHAR(3), 
	maingrp_code CHAR(3), 
	prodgrp_code CHAR(3), 
	part_code CHAR(15), 
	reqd_amt DECIMAL(16,2), 
	allocated_amt DECIMAL(16,2), 
	reqd_qty FLOAT, 
	allocated_qty FLOAT, 
	disc_per DECIMAL(5,2), 
	poss_disc_amt DECIMAL(16,2), 
	disc_taken_ind smallint) with no LOG 
	CREATE INDEX t_proddisc_1 ON t_proddisc(type_ind, key_num) 
	CREATE INDEX t_quotedetl_1 ON t_quotedetl(offer_code, status_ind) 
	CREATE INDEX t_quotedetl_2 ON t_quotedetl(part_code, 
	prodgrp_code, 
	maingrp_code) 
END FUNCTION 


