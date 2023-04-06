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
# ES1b Management Information Statistics Extraction
#                  Statist table UPDATE functions
#
########################################################################
#
#  ES1b.4gl - Source file contains all UPDATE functions FOR statistics
#             tables.
#
#        statterr - UPDATE number of customers in territory
#                   AND possible buying statuses
#        statsper - UPDATE number of customers FOR salesperson
#                   AND possible buying statuses
#
#  NB: Note a lot of the selects in this source module do NOT filter/join
#      on the 'cmpy_code'. This IS done on purpose as these selects do join
#      OR filter on intseq_num.  This IS a serial data type on the statint
#      table AND hence IS unique regardless of cmpy_code.

############################################################
# GLOBAL Scope Variables
############################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ES1_GLOBALS.4gl" 
###########################################################################
# FUNCTION post_intervals() 
#
# 
###########################################################################
FUNCTION post_intervals() 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_statsper RECORD LIKE statsper.* 
	DEFINE l_rec_statterr RECORD LIKE statterr.* 

	#  WHENEVER ERROR GOTO recovery
	CALL disp_status(2,"S","INITIALIZE") 

	#-------------------------------------------------------------------------
	# Update possible number of customers FOR each salesperson
	#-------------------------------------------------------------------------

	DECLARE c_statsper cursor FOR 
	SELECT unique sale_code FROM statsper 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code IS NOT NULL 
	AND poss_cust_num IS NULL 
	FOREACH c_statsper INTO l_rec_statsper.sale_code 
		SELECT count(*) INTO l_rec_statsper.poss_cust_num 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = l_rec_statsper.sale_code 
		UPDATE statsper 
		SET poss_cust_num = l_rec_statsper.poss_cust_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND poss_cust_num IS NULL 
		AND sale_code = l_rec_statsper.sale_code 
	END FOREACH 
	
	#-------------------------------------------------------------------------
	# Update possible number of customers FOR each territory
	#-------------------------------------------------------------------------
	
	DECLARE c_statterr cursor FOR 
	SELECT unique terr_code FROM statterr 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND terr_code IS NOT NULL 
	AND poss_cust_num IS NULL 
	FOREACH c_statterr INTO l_rec_statterr.terr_code 
		SELECT count(*) INTO l_rec_statterr.poss_cust_num 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND territory_code = l_rec_statterr.terr_code 
		UPDATE statterr 
		SET poss_cust_num = l_rec_statterr.poss_cust_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND poss_cust_num IS NULL 
		AND terr_code = l_rec_statterr.terr_code 
	END FOREACH 
	
	#-------------------------------------------------------------------------
	# Now add up all aggregate type VALUES FOR updated intervals
	#-------------------------------------------------------------------------

	DECLARE c_statint cursor with hold FOR 
	SELECT * FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND updreq_flag = "Y" 
	ORDER BY start_date 
	FOREACH c_statint INTO l_rec_statint.* 
		CALL disp_status(2,"I",l_rec_statint.start_date) 
		IF update_interval(l_rec_statint.*) THEN 
			OUTPUT TO REPORT es1_list(3,l_rec_statint.year_num, 
			l_rec_statint.int_text) 
			UPDATE statint 
			SET updreq_flag = "N" 
			WHERE intseq_num = l_rec_statint.intseq_num 
		ELSE 
			OUTPUT TO REPORT es1_list(4,l_rec_statint.year_num, 
			l_rec_statint.int_text) 
		END IF 
	END FOREACH 

	CALL disp_status(2,"S","Complete") 

	RETURN TRUE 
	LABEL recovery: 
	RETURN FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION post_intervals() 
###########################################################################


###########################################################################
# FUNCTION update_interval(p_rec_statint)  
#
# 
###########################################################################
FUNCTION update_interval(p_rec_statint) 
	DEFINE p_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_rec_statsale RECORD LIKE statsale.* 
	DEFINE l_rec_statprod RECORD LIKE statprod.* 
	DEFINE l_rec_statware RECORD LIKE statware.* 
	DEFINE l_rec_statterr RECORD LIKE statterr.* 
	DEFINE l_rec_statsper RECORD LIKE statsper.* 
	DEFINE l_rec_statcond RECORD LIKE statcond.* 
	DEFINE l_rec_statoffer RECORD LIKE statoffer.* 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rowid INTEGER 

	SELECT * INTO l_rec_stattype.* 
	FROM stattype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = p_rec_statint.type_code 
	#  WHENEVER ERROR GOTO recovery
	{
	################## First & Last Date Update Commented Out
	################## Deeemed unnecessary & time consuming
	   CALL disp_status(2,"S","Sales")
	   IF l_rec_stattype.sale_upd_ind != "0" THEN
	##    First/last dates FOR a sale line
	      DECLARE c_statsale CURSOR FOR
	         SELECT rowid,* FROM statsale
	          WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	            AND intseq_num = p_rec_statint.intseq_num
	      FOREACH c_statsale INTO l_rowid,
	                              l_rec_statsale.*
	         IF l_rec_statsale.type_code = glob_rec_statparms.day_type_code THEN
	            LET l_rec_statsale.first_date = p_rec_statint.start_date
	            LET l_rec_statsale.last_date = p_rec_statint.end_date
	         ELSE
	            CASE
	               WHEN l_rec_statsale.part_code IS NOT NULL
	                  SELECT min(first_date),
	                         max(first_date)
	                    INTO l_rec_statsale.first_date,
	                         l_rec_statsale.last_date
	                    FROM statsale
	                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	                     AND part_code = l_rec_statsale.part_code
	                     AND prodgrp_code = l_rec_statsale.prodgrp_code
	                     AND maingrp_code = l_rec_statsale.maingrp_code
	                     AND type_code = glob_rec_statparms.day_type_code
	                     AND first_date between p_rec_statint.start_date
	                                        AND p_rec_statint.end_date
	               WHEN l_rec_statsale.prodgrp_code IS NOT NULL
	                  SELECT min(first_date),
	                         max(first_date)
	                    INTO l_rec_statsale.first_date,
	                         l_rec_statsale.last_date
	                    FROM statsale
	                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	                     AND part_code IS NULL
	                     AND prodgrp_code = l_rec_statsale.prodgrp_code
	                     AND maingrp_code = l_rec_statsale.maingrp_code
	                     AND type_code = glob_rec_statparms.day_type_code
	                     AND first_date between p_rec_statint.start_date
	                                        AND p_rec_statint.end_date
	               WHEN l_rec_statsale.maingrp_code IS NOT NULL
	                  SELECT min(first_date),
	                         max(first_date)
	                    INTO l_rec_statsale.first_date,
	                         l_rec_statsale.last_date
	                    FROM statsale
	                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	                     AND part_code IS NULL
	                     AND prodgrp_code IS NULL
	                     AND maingrp_code = l_rec_statsale.maingrp_code
	                     AND type_code = glob_rec_statparms.day_type_code
	                     AND first_date between p_rec_statint.start_date
	                                        AND p_rec_statint.end_date
	               OTHERWISE
	                  IF l_rec_statsale.dept_code IS NOT NULL THEN
	                     SELECT min(first_date),
	                            max(first_date)
	                       INTO l_rec_statsale.first_date,
	                            l_rec_statsale.last_date
	                       FROM statsale
	                      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	                        AND dept_code = l_rec_statsale.dept_code
	                        AND part_code IS NULL
	                        AND prodgrp_code IS NULL
	                        AND maingrp_code IS NULL
	                        AND type_code = glob_rec_statparms.day_type_code
	                        AND first_date between p_rec_statint.start_date
	                                           AND p_rec_statint.end_date
	                  END IF
	            END CASE
	            IF l_rec_statsale.first_date IS NULL THEN
	               LET l_rec_statsale.first_date = p_rec_statint.start_date
	            END IF
	            IF l_rec_statsale.last_date IS NULL THEN
	               LET l_rec_statsale.last_date = p_rec_statint.end_date
	            END IF
	         END IF
	         UPDATE statsale
	            SET first_date = l_rec_statsale.first_date,
	                last_date = l_rec_statsale.last_date
	          WHERE rowid = l_rowid
	      END FOREACH
	   END IF
	################## First & Last Date Update Commented Out
	################## Deeemed unnecessary & time consuming
	}
	CALL disp_status(2,"S","Products") 
	IF l_rec_stattype.prod_upd_ind = "Y" 
	OR l_rec_stattype.prod_upd1_ind = "Y" 
	OR l_rec_stattype.prod_upd2_ind = "Y" 
	OR l_rec_stattype.prod_upd3_ind = "Y" THEN 
	
		#-------------------------------------------------------------------------
		# Products/Product Groups/Main Product Groups/Departments
		#-------------------------------------------------------------------------

		DECLARE c_statprod cursor FOR 
		SELECT rowid,* FROM statprod 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND intseq_num = p_rec_statint.intseq_num 
		FOREACH c_statprod INTO l_rowid, 
			l_rec_statprod.* 
			LET l_rec_statprod.cust_num = 0 
			CASE 
				WHEN l_rec_statprod.part_code IS NOT NULL 
					SELECT count(unique cust_code) INTO l_rec_statprod.cust_num 
					FROM statsale 
					WHERE part_code = l_rec_statprod.part_code 
					AND prodgrp_code = l_rec_statprod.prodgrp_code 
					AND maingrp_code = l_rec_statprod.maingrp_code 
					AND intseq_num = p_rec_statint.intseq_num 
				WHEN l_rec_statprod.prodgrp_code IS NOT NULL 
					SELECT count(unique cust_code) INTO l_rec_statprod.cust_num 
					FROM statsale 
					WHERE prodgrp_code = l_rec_statprod.prodgrp_code 
					AND maingrp_code = l_rec_statprod.maingrp_code 
					AND part_code IS NULL 
					AND intseq_num = p_rec_statint.intseq_num 
				WHEN l_rec_statprod.maingrp_code IS NOT NULL 
					SELECT count(unique cust_code) INTO l_rec_statprod.cust_num 
					FROM statsale 
					WHERE maingrp_code = l_rec_statprod.maingrp_code 
					AND prodgrp_code IS NULL 
					AND part_code IS NULL 
					AND intseq_num = p_rec_statint.intseq_num 
				OTHERWISE 
					IF l_rec_statprod.dept_code IS NULL THEN 
						CONTINUE FOREACH 
					ELSE 
						SELECT count(unique cust_code) INTO l_rec_statprod.cust_num 
						FROM statsale 
						WHERE dept_code = l_rec_statprod.dept_code 
						AND prodgrp_code IS NULL 
						AND part_code IS NULL 
						AND intseq_num = p_rec_statint.intseq_num 
					END IF 
			END CASE 
			UPDATE statprod 
			SET cust_num = l_rec_statprod.cust_num 
			WHERE rowid = l_rowid 
		END FOREACH 
	END IF 
	CALL disp_status(2,"S","Territory") 
	IF l_rec_stattype.terr_upd_ind = "Y" 
	OR l_rec_stattype.terr_upd1_ind = "Y" THEN 

		#-------------------------------------------------------------------------
		# Sales Territories/Sales Areas
		#-------------------------------------------------------------------------

		DECLARE c1_statterr cursor FOR 
		SELECT rowid,* FROM statterr 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND intseq_num = p_rec_statint.intseq_num 
		AND terr_code IS NOT NULL 
		FOREACH c1_statterr INTO l_rowid,	l_rec_statterr.* 

			SELECT count(unique ord_num) INTO l_rec_statterr.orders_num 
			FROM statorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tran_type_ind = TRAN_TYPE_INVOICE_IN 
			AND area_code = l_rec_statterr.area_code 
			AND terr_code = l_rec_statterr.terr_code 
			AND trans_date between p_rec_statint.start_date 
			AND p_rec_statint.end_date 

			SELECT count(*) INTO l_rec_statterr.credits_num 
			FROM statorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tran_type_ind = TRAN_TYPE_CREDIT_CR 
			AND area_code = l_rec_statterr.area_code 
			AND terr_code = l_rec_statterr.terr_code 
			AND trans_date between p_rec_statint.start_date 
			AND p_rec_statint.end_date 

			SELECT count(unique cust_code) INTO l_rec_statterr.buy_cust_num 
			FROM statorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND area_code = l_rec_statterr.area_code 
			AND terr_code = l_rec_statterr.terr_code 
			AND trans_date between p_rec_statint.start_date 
			AND p_rec_statint.end_date 

			SELECT count(unique cust_code) INTO l_rec_statterr.new_cust_num 
			FROM statorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND area_code = l_rec_statterr.area_code 
			AND terr_code = l_rec_statterr.terr_code 
			AND trans_date between p_rec_statint.start_date 
			AND p_rec_statint.end_date 
			AND cust_code NOT in 
			(select unique cust_code FROM statorder x 
			WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND x.trans_date between(p_rec_statint.start_date -glob_rec_statparms.new_days_num) 
			and(p_rec_statint.start_date-1)) 

			SELECT count(*) INTO l_rec_statterr.lost_cust_num 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND territory_code = l_rec_statterr.terr_code 
			AND last_inv_date <= (p_rec_statint.start_date - glob_rec_statparms.lost_days_num) 
			UPDATE statterr 
			SET orders_num = l_rec_statterr.orders_num, 
			credits_num = l_rec_statterr.credits_num, 
			buy_cust_num = l_rec_statterr.buy_cust_num, 
			new_cust_num = l_rec_statterr.new_cust_num, 
			lost_cust_num = l_rec_statterr.lost_cust_num 
			WHERE rowid = l_rowid 
		END FOREACH 

		#-------------------------------------------------------------------------
		# Sales Areas
		#-------------------------------------------------------------------------

		DECLARE c2_statterr cursor FOR 
		SELECT rowid,* FROM statterr 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND intseq_num = p_rec_statint.intseq_num 
		AND terr_code IS NULL 
		FOREACH c2_statterr INTO l_rowid, 
			l_rec_statterr.* 
			SELECT sum(orders_num), 
			sum(credits_num), 
			sum(poss_cust_num), 
			sum(buy_cust_num), 
			sum(new_cust_num), 
			sum(lost_cust_num) 
			INTO l_rec_statterr.orders_num, 
			l_rec_statterr.credits_num, 
			l_rec_statterr.poss_cust_num, 
			l_rec_statterr.buy_cust_num, 
			l_rec_statterr.new_cust_num, 
			l_rec_statterr.lost_cust_num 
			FROM statterr 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND intseq_num = p_rec_statint.intseq_num 
			AND area_code = l_rec_statterr.area_code 
			AND terr_code IS NOT NULL 
			UPDATE statterr 
			SET orders_num = l_rec_statterr.orders_num, 
			credits_num = l_rec_statterr.credits_num, 
			poss_cust_num = l_rec_statterr.poss_cust_num, 
			buy_cust_num = l_rec_statterr.buy_cust_num, 
			new_cust_num = l_rec_statterr.new_cust_num, 
			lost_cust_num = l_rec_statterr.lost_cust_num 
			WHERE rowid = l_rowid 
		END FOREACH 
	END IF 
	CALL disp_status(2,"S","Persons") 
	IF l_rec_stattype.sper_upd_ind = "Y" 
	OR l_rec_stattype.sper_upd1_ind = "Y" THEN 

		#-------------------------------------------------------------------------
		# Sales Persons
		#-------------------------------------------------------------------------

		DECLARE c1_statsper cursor FOR 
		SELECT rowid,* FROM statsper 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND intseq_num = p_rec_statint.intseq_num 
		AND sale_code IS NOT NULL 
		FOREACH c1_statsper INTO l_rowid,	l_rec_statsper.* 

			SELECT count(unique ord_num) INTO l_rec_statsper.orders_num 
			FROM statorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tran_type_ind = TRAN_TYPE_INVOICE_IN 
			AND mgr_code = l_rec_statsper.mgr_code 
			AND sale_code = l_rec_statsper.sale_code 
			AND trans_date between p_rec_statint.start_date 
			AND p_rec_statint.end_date 

			SELECT count(*) INTO l_rec_statsper.credits_num 
			FROM statorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tran_type_ind = TRAN_TYPE_CREDIT_CR 
			AND mgr_code = l_rec_statsper.mgr_code 
			AND sale_code = l_rec_statsper.sale_code 
			AND trans_date between p_rec_statint.start_date 
			AND p_rec_statint.end_date 

			SELECT count(unique cust_code) INTO l_rec_statsper.buy_cust_num 
			FROM statorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND mgr_code = l_rec_statsper.mgr_code 
			AND sale_code = l_rec_statsper.sale_code 
			AND trans_date between p_rec_statint.start_date 
			AND p_rec_statint.end_date 

			SELECT count(unique cust_code) INTO l_rec_statsper.new_cust_num 
			FROM statorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND mgr_code = l_rec_statsper.mgr_code 
			AND sale_code = l_rec_statsper.sale_code 
			AND trans_date between p_rec_statint.start_date 
			AND p_rec_statint.end_date 
			AND cust_code NOT in 
			(select unique cust_code FROM statorder x 
			WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND x.trans_date between(p_rec_statint.start_date 
			-glob_rec_statparms.new_days_num) 
			and(p_rec_statint.start_date-1)) 

			SELECT count(*) INTO l_rec_statsper.lost_cust_num 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = l_rec_statsper.sale_code 
			AND last_inv_date <= (p_rec_statint.start_date 
			- glob_rec_statparms.lost_days_num) 
			UPDATE statsper 
			SET orders_num = l_rec_statsper.orders_num, 
			credits_num = l_rec_statsper.credits_num, 
			buy_cust_num = l_rec_statsper.buy_cust_num, 
			new_cust_num = l_rec_statsper.new_cust_num, 
			lost_cust_num = l_rec_statsper.lost_cust_num 
			WHERE rowid = l_rowid 
		END FOREACH 

		#-------------------------------------------------------------------------
		# Sales Managers
		#-------------------------------------------------------------------------

		DECLARE c2_statsper cursor FOR 
		SELECT rowid,* FROM statsper 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND intseq_num = p_rec_statint.intseq_num 
		AND sale_code IS NULL 
		FOREACH c2_statsper INTO l_rowid, 
			l_rec_statsper.* 
			SELECT sum(orders_num), 
			sum(credits_num), 
			sum(poss_cust_num), 
			sum(buy_cust_num), 
			sum(new_cust_num), 
			sum(lost_cust_num) 
			INTO l_rec_statsper.orders_num, 
			l_rec_statsper.credits_num, 
			l_rec_statsper.poss_cust_num, 
			l_rec_statsper.buy_cust_num, 
			l_rec_statsper.new_cust_num, 
			l_rec_statsper.lost_cust_num 
			FROM statsper 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND intseq_num = p_rec_statint.intseq_num 
			AND mgr_code = l_rec_statsper.mgr_code 
			AND sale_code IS NOT NULL 
			UPDATE statsper 
			SET orders_num = l_rec_statsper.orders_num, 
			credits_num = l_rec_statsper.credits_num, 
			poss_cust_num = l_rec_statsper.poss_cust_num, 
			buy_cust_num = l_rec_statsper.buy_cust_num, 
			new_cust_num = l_rec_statsper.new_cust_num, 
			lost_cust_num = l_rec_statsper.lost_cust_num 
			WHERE rowid = l_rowid 
		END FOREACH 
	END IF 

	CALL disp_status(2,"S","Offers") 

	IF l_rec_stattype.offer_upd_ind = "Y" THEN 

		#-------------------------------------------------------------------------
		# Special Offers
		#-------------------------------------------------------------------------

		DECLARE c_statoffer cursor FOR 
		SELECT rowid,* FROM statoffer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND intseq_num = p_rec_statint.intseq_num 
		FOREACH c_statoffer INTO l_rowid, 
			l_rec_statoffer.* 
			LET l_rec_statoffer.offers_num = 0 
			SELECT count(unique ord_num) 
			INTO l_rec_statoffer.offers_num 
			FROM invoicehead, 
			invoicedetl 
			WHERE invoicehead.cmpy_code = l_rec_statoffer.cmpy_code 
			AND invoicehead.cust_code = l_rec_statoffer.cust_code 
			AND invoicehead.sale_code = l_rec_statoffer.sale_code 
			AND invoicedetl.cmpy_code = invoicehead.cmpy_code 
			AND invoicedetl.inv_num = invoicehead.inv_num 
			AND invoicedetl.offer_code = l_rec_statoffer.offer_code 
			AND invoicehead.inv_date between p_rec_statint.start_date 
			AND p_rec_statint.end_date 
			UPDATE statoffer SET offers_num = l_rec_statoffer.offers_num 
			WHERE rowid = l_rowid 
		END FOREACH 
	END IF 
	CALL disp_status(2,"S","Conditions") 
	IF l_rec_stattype.cond_upd_ind = "Y" THEN 
	
		#-------------------------------------------------------------------------
		#    Sales Conditions
		#-------------------------------------------------------------------------
		DECLARE c_statcond cursor FOR 
		SELECT rowid,* FROM statcond 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND intseq_num = p_rec_statint.intseq_num 

		FOREACH c_statcond INTO l_rowid, 
			l_rec_statcond.* 
			IF l_rec_statcond.sale_code IS NULL THEN 
				SELECT count(*) INTO l_rec_statcond.cond_num 
				FROM statorder 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND mgr_code = l_rec_statcond.mgr_code 
				AND cust_code = l_rec_statcond.cust_code 
				AND cond_code = l_rec_statcond.cond_code 
				AND trans_date between p_rec_statint.start_date 
				AND p_rec_statint.end_date 
			ELSE 
				SELECT count(*) INTO l_rec_statcond.cond_num 
				FROM statorder 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND mgr_code = l_rec_statcond.mgr_code 
				AND sale_code = l_rec_statcond.sale_code 
				AND cust_code = l_rec_statcond.cust_code 
				AND cond_code = l_rec_statcond.cond_code 
				AND trans_date between p_rec_statint.start_date 
				AND p_rec_statint.end_date 
			END IF 

			UPDATE statcond SET cond_num = l_rec_statcond.cond_num 
			WHERE rowid = l_rowid 
		END FOREACH 
	END IF 
	
	CALL disp_status(2,"S","Complete") 
	RETURN TRUE 
	LABEL recovery: 
	RETURN FALSE 
END FUNCTION
###########################################################################
# END FUNCTION update_interval(p_rec_statint)  
###########################################################################