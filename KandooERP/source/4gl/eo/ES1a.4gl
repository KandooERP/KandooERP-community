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
# \file
# \brief module ES1a Management Information Statistics Extraction
#                  Statist table UPDATE functions
#
########################################################################
#
#  ES1a.4gl - Source file contains all updates FOR statistics tables.
#
#        statcust - UPDATE/INSERT customer based statistics
#
#        statware - UPDATE/INSERT warehouse,product,prodgrp,maingrp,department
#                       based statistics.
#        statprod - UPDATE/INSERT product,prodgrp,maingrp,department
#                       based statistics.
#        statsale - UPDATE/INSERT customer,product,prodgrp,maingrp,department
#                       based statistics.
#        statterr - UPDATE/INSERT territory based statistics
#
#        statsper - UPDATE/INSERT salesperson based statistics
#                 - includes separate section FOR shared commissions
#
#        statoffer - UPDATE/INSERT special offer based statistics
#
#        statcond - UPDATE/INSERT sales conditions based statistics
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ES1_GLOBALS.4gl" 
###########################################################################
# FUNCTION post_tables() 
#
# 
###########################################################################
FUNCTION post_tables() 
	DEFINE p_rec_statint RECORD LIKE statint.* 
	DEFINE l_start_date DATE 
	DEFINE l_end_date DATE 

	LET l_start_date = NULL 
	LET l_end_date = NULL 

	SELECT min(trans_date), 
	max(trans_date) 
	INTO l_start_date, 
	l_end_date 
	FROM stathead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF l_start_date IS NULL OR l_end_date IS NULL THEN 
		RETURN 
	END IF 

	CALL declare_cursors() 

	DECLARE c_statint cursor FOR 
	SELECT * FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ((start_date between l_start_date AND l_end_date) 
	OR (end_date between l_start_date AND l_end_date) 
	OR (end_date >= l_end_date AND start_date <= l_start_date)) 
	ORDER BY start_date 

	#  WHENEVER ERROR GOTO recovery
	BEGIN WORK 
		FOREACH c_statint INTO p_rec_statint.* 
			CALL disp_status(1,"I",p_rec_statint.start_date) 
			IF upd_statdetl(p_rec_statint.*) THEN 
				IF p_rec_statint.type_code = glob_rec_statparms.mth_type_code THEN 
					LET p_rec_statint.dist_flag = "Y" 
				END IF 
				UPDATE statint 
				SET dist_flag = p_rec_statint.dist_flag, 
				updreq_flag = "Y" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = p_rec_statint.year_num 
				AND type_code = p_rec_statint.type_code 
				AND int_num = p_rec_statint.int_num 
			ELSE 
				GOTO recovery 
			END IF 
		END FOREACH 
		DELETE FROM stathead WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		DELETE FROM statdetl WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	COMMIT WORK 
	RETURN 
	LABEL recovery: 
	ROLLBACK WORK 
	WHENEVER ERROR stop 
END FUNCTION 
###########################################################################
# END FUNCTION post_tables() 
###########################################################################


###########################################################################
# FUNCTION declare_cursors() 
#
# 
###########################################################################
FUNCTION declare_cursors() 
	DEFINE l_query_text STRING

	LET l_query_text = "SELECT cust_code, sum(gross_amt),", 
	"sum(net_amt),", 
	"sum(cost_amt),", 
	"sum(sales_qty) ", 
	"FROM stathead ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND trans_date between ? AND ? ", 
	"group by 1" 
	PREPARE s_statcust FROM l_query_text 
	DECLARE c_statcust cursor FOR s_statcust 

	LET l_query_text = "SELECT area_code,terr_code,", 
	"sum(grs_amt),", 
	"sum(net_amt),", 
	"sum(cost_amt),", 
	"sum(sales_qty) ", 
	"FROM statdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND trans_date between ? AND ? ", 
	"group by 1,2" 
	PREPARE s_statterr FROM l_query_text 
	DECLARE c_statterr cursor FOR s_statterr 
	LET l_query_text = "SELECT mgr_code, sale_code,", 
	"sum(grs_amt),sum(grs_inv_amt),sum(grs_cred_amt),sum(grs_offer_amt),", 
	"sum(net_amt),sum(net_inv_amt),sum(net_cred_amt),sum(net_offer_amt),", 
	"sum(comm_amt), sum(cost_amt), sum(offer_qty), sum(sales_qty) ", 
	"FROM statdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND trans_date between ? AND ? ", 
	"group by 1,2" 
	PREPARE s_statsper FROM l_query_text 
	DECLARE c_statsper cursor FOR s_statsper 

	LET l_query_text = "SELECT part_code,prodgrp_code,maingrp_code,dept_code,", 
	"sum(grs_amt),sum(net_amt),", 
	"sum(cost_amt),sum(sales_qty) ", 
	"FROM statdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND trans_date between ? AND ? ", 
	"group by 1,2,3,4" 
	PREPARE s_statprod FROM l_query_text 
	DECLARE c_statprod cursor FOR s_statprod 

	LET l_query_text = "SELECT ware_code,part_code,prodgrp_code,maingrp_code,", 
	"dept_code,sum(grs_amt),sum(net_amt),", 
	"sum(cost_amt),sum(sales_qty) ", 
	"FROM statdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND trans_date between ? AND ? ", 
	"AND ware_code IS NOT NULL ", 
	"group by 1,2,3,4,5" 
	PREPARE s_statware FROM l_query_text 
	DECLARE c_statware cursor FOR s_statware 

	LET l_query_text = "SELECT cust_code,part_code,prodgrp_code,maingrp_code,", 
	"dept_code,sale_code,mgr_code,terr_code,area_code,", 
	"sum(grs_amt),sum(net_amt),", 
	"sum(cost_amt),sum(sales_qty) ", 
	"FROM statdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND trans_date between ? AND ? ", 
	"group by 1,2,3,4,5,6,7,8,9" 
	PREPARE s_statsale FROM l_query_text 
	DECLARE c_statsale cursor FOR s_statsale 

	LET l_query_text = "SELECT offer_code,sale_code,cust_code,", 
	"sum(grs_offer_amt),sum(net_offer_amt),", 
	"sum(cost_amt),sum(offer_qty) ", 
	"FROM statdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND trans_date between ? AND ? ", 
	"AND grs_offer_amt != 0 ", 
	"AND offer_code IS NOT NULL ", 
	"group by 1,2,3" 
	PREPARE s_statoffer FROM l_query_text 
	DECLARE c_statoffer cursor FOR s_statoffer 

	LET l_query_text = "SELECT cust_code,cond_code,mgr_code,sale_code,", 
	"sum(grs_amt),sum(net_amt),", 
	"sum(cost_amt),sum(sales_qty) ", 
	"FROM statdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND trans_date between ? AND ? ", 
	"AND offer_code IS NULL ", 
	"AND cond_code IS NOT NULL ", 
	"group by 1,2,3,4" 
	PREPARE s_statcond FROM l_query_text 
	DECLARE c_statcond cursor FOR s_statcond 
END FUNCTION 
###########################################################################
# END FUNCTION declare_cursors() 
###########################################################################


###########################################################################
# FUNCTION upd_statdetl(p_rec_statint) 
#
# 
###########################################################################
FUNCTION upd_statdetl(p_rec_statint) 
	DEFINE p_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_rec_statcust RECORD LIKE statcust.* 
	DEFINE l_rec_statprod RECORD LIKE statprod.* 
	DEFINE l_rec_statware RECORD LIKE statware.* 
	DEFINE l_rec_statsale RECORD LIKE statsale.* 
	DEFINE l_rec_statterr RECORD LIKE statterr.* 
	DEFINE l_rec_statsper RECORD LIKE statsper.* 
	DEFINE l_rec_statcond RECORD LIKE statcond.* 
	DEFINE l_rec_statoffer RECORD LIKE statoffer.* 
	DEFINE l_rec_orderoffer RECORD LIKE orderoffer.* 
	DEFINE x SMALLINT 

	SELECT * INTO l_rec_stattype.* 
	FROM stattype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = p_rec_statint.type_code 

	#  WHENEVER ERROR GOTO recovery
	#-------------------------------------------------------------------------
	#    Customers
	#-------------------------------------------------------------------------
	CALL disp_status(1,"S","Customers") 
	IF l_rec_stattype.cust_upd_ind = "Y" THEN 
		OPEN c_statcust USING p_rec_statint.start_date,p_rec_statint.end_date 
		FOREACH c_statcust INTO l_rec_statcust.cust_code, 
			l_rec_statcust.gross_amt, 
			l_rec_statcust.net_amt, 
			l_rec_statcust.cost_amt, 
			l_rec_statcust.sales_qty 
			UPDATE statcust 
			SET gross_amt = gross_amt + l_rec_statcust.gross_amt, 
			net_amt = net_amt + l_rec_statcust.net_amt, 
			cost_amt = cost_amt + l_rec_statcust.cost_amt, 
			sales_qty = sales_qty + l_rec_statcust.sales_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_statcust.cust_code 
			AND intseq_num = p_rec_statint.intseq_num 
			IF sqlca.sqlerrd[3] = 0 THEN 
				LET l_rec_statcust.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_statcust.cust_code = l_rec_statcust.cust_code 
				LET l_rec_statcust.intseq_num = p_rec_statint.intseq_num 
				LET l_rec_statcust.year_num = p_rec_statint.year_num 
				LET l_rec_statcust.type_code = p_rec_statint.type_code 
				LET l_rec_statcust.int_num = p_rec_statint.int_num 
				LET l_rec_statcust.gross_amt = l_rec_statcust.gross_amt 
				LET l_rec_statcust.net_amt = l_rec_statcust.net_amt 
				LET l_rec_statcust.cost_amt = l_rec_statcust.cost_amt 
				LET l_rec_statcust.sales_qty = l_rec_statcust.sales_qty 
				INSERT INTO statcust VALUES (l_rec_statcust.*) 
			END IF 
		END FOREACH 
	END IF 

	#-------------------------------------------------------------------------
	#     Sales Territories/Sales Areas
	#-------------------------------------------------------------------------

	CALL disp_status(1,"S","Territories") 
	IF l_rec_stattype.terr_upd_ind = "Y" 
	OR l_rec_stattype.terr_upd1_ind = "Y" THEN 
		OPEN c_statterr USING p_rec_statint.start_date,p_rec_statint.end_date 
		FOREACH c_statterr INTO l_rec_statterr.area_code, 
			l_rec_statterr.terr_code, 
			l_rec_statterr.gross_amt, 
			l_rec_statterr.net_amt, 
			l_rec_statterr.cost_amt, 
			l_rec_statterr.sales_qty 

			### Must do separate updates FOR area/terr so it IS known
			### which level needs an INSERT,  IF any.
			IF l_rec_stattype.terr_upd_ind = "Y" THEN 
				UPDATE statterr 
				SET gross_amt = gross_amt + l_rec_statterr.gross_amt, 
				net_amt = net_amt + l_rec_statterr.net_amt, 
				cost_amt = cost_amt + l_rec_statterr.cost_amt, 
				sales_qty = sales_qty + l_rec_statterr.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND area_code = l_rec_statterr.area_code 
				AND terr_code = l_rec_statterr.terr_code 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statterr.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statterr.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statterr.year_num = p_rec_statint.year_num 
					LET l_rec_statterr.type_code = p_rec_statint.type_code 
					LET l_rec_statterr.int_num = p_rec_statint.int_num 
					LET l_rec_statterr.orders_num = 0 
					LET l_rec_statterr.offers_num = 0 
					LET l_rec_statterr.credits_num = 0 
					LET l_rec_statterr.buy_cust_num = 0 
					LET l_rec_statterr.new_cust_num = 0 
					LET l_rec_statterr.lost_cust_num = 0 
					LET l_rec_statterr.poss_cust_num = NULL #null iniates count 
					INSERT INTO statterr VALUES (l_rec_statterr.*) 
				END IF 
			END IF 
			IF l_rec_stattype.terr_upd1_ind = "Y" THEN 
				UPDATE statterr 
				SET gross_amt = gross_amt + l_rec_statterr.gross_amt, 
				net_amt = net_amt + l_rec_statterr.net_amt, 
				cost_amt = cost_amt + l_rec_statterr.cost_amt, 
				sales_qty = sales_qty + l_rec_statterr.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND area_code = l_rec_statterr.area_code 
				AND terr_code IS NULL 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statterr.terr_code = NULL 
					LET l_rec_statterr.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statterr.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statterr.year_num = p_rec_statint.year_num 
					LET l_rec_statterr.type_code = p_rec_statint.type_code 
					LET l_rec_statterr.int_num = p_rec_statint.int_num 
					LET l_rec_statterr.orders_num = 0 
					LET l_rec_statterr.offers_num = 0 
					LET l_rec_statterr.credits_num = 0 
					LET l_rec_statterr.buy_cust_num = 0 
					LET l_rec_statterr.new_cust_num = 0 
					LET l_rec_statterr.lost_cust_num = 0 
					LET l_rec_statterr.poss_cust_num = NULL #null iniates count 
					INSERT INTO statterr VALUES (l_rec_statterr.*) 
				END IF 
			END IF 
		END FOREACH 
	END IF 

	#-------------------------------------------------------------------------
	# Salesperson/Sales Managers
	#-------------------------------------------------------------------------

	CALL disp_status(1,"S","Persons") 
	IF l_rec_stattype.sper_upd_ind = "Y" 
	OR l_rec_stattype.sper_upd1_ind = "Y" THEN 
		OPEN c_statsper USING p_rec_statint.start_date,p_rec_statint.end_date 
		FOREACH c_statsper INTO l_rec_statsper.mgr_code, 
			l_rec_statsper.sale_code, 
			l_rec_statsper.grs_amt, 
			l_rec_statsper.grs_inv_amt, 
			l_rec_statsper.grs_cred_amt, 
			l_rec_statsper.grs_offer_amt, 
			l_rec_statsper.net_amt, 
			l_rec_statsper.net_inv_amt, 
			l_rec_statsper.net_cred_amt, 
			l_rec_statsper.net_offer_amt, 
			l_rec_statsper.comm_amt, 
			l_rec_statsper.cost_amt, 
			l_rec_statsper.offers_num, 
			l_rec_statsper.sales_qty 

			IF l_rec_stattype.sper_upd_ind = "Y" THEN 
				UPDATE statsper 
				SET grs_amt = grs_amt + l_rec_statsper.grs_amt, 
				grs_inv_amt = grs_inv_amt + l_rec_statsper.grs_inv_amt, 
				grs_cred_amt = grs_cred_amt + l_rec_statsper.grs_cred_amt, 
				grs_offer_amt = grs_offer_amt 
				+ l_rec_statsper.grs_offer_amt, 
				net_amt = net_amt + l_rec_statsper.net_amt, 
				net_inv_amt = net_inv_amt + l_rec_statsper.net_inv_amt, 
				net_cred_amt = net_cred_amt + l_rec_statsper.net_cred_amt, 
				net_offer_amt = net_offer_amt 
				+ l_rec_statsper.net_offer_amt, 
				cost_amt = cost_amt + l_rec_statsper.cost_amt, 
				comm_amt = comm_amt + l_rec_statsper.comm_amt, 
				sales_qty = sales_qty + l_rec_statsper.sales_qty, 
				offers_num = offers_num + l_rec_statsper.offers_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND mgr_code = l_rec_statsper.mgr_code 
				AND sale_code = l_rec_statsper.sale_code 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statsper.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statsper.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statsper.year_num = p_rec_statint.year_num 
					LET l_rec_statsper.type_code = p_rec_statint.type_code 
					LET l_rec_statsper.int_num = p_rec_statint.int_num 
					LET l_rec_statsper.orders_num = 0 
					LET l_rec_statsper.credits_num = 0 
					LET l_rec_statsper.buy_cust_num = 0 
					LET l_rec_statsper.new_cust_num = 0 
					LET l_rec_statsper.lost_cust_num = 0 
					LET l_rec_statsper.poss_cust_num = NULL #null iniates count 
					INSERT INTO statsper VALUES (l_rec_statsper.*) 
				END IF 
			END IF 

			IF l_rec_stattype.sper_upd1_ind = "Y" THEN 
				UPDATE statsper 
				SET grs_amt = grs_amt + l_rec_statsper.grs_amt, 
				grs_inv_amt = grs_inv_amt 
				+ l_rec_statsper.grs_inv_amt, 
				grs_cred_amt = grs_cred_amt 
				+ l_rec_statsper.grs_cred_amt, 
				grs_offer_amt = grs_offer_amt 
				+ l_rec_statsper.grs_offer_amt, 
				net_amt = net_amt + l_rec_statsper.net_amt, 
				net_inv_amt = net_inv_amt 
				+ l_rec_statsper.net_inv_amt, 
				net_cred_amt = net_cred_amt 
				+ l_rec_statsper.net_cred_amt, 
				net_offer_amt = net_offer_amt 
				+ l_rec_statsper.net_offer_amt, 
				cost_amt = cost_amt + l_rec_statsper.cost_amt, 
				comm_amt = comm_amt + l_rec_statsper.comm_amt, 
				sales_qty = sales_qty + l_rec_statsper.sales_qty, 
				offers_num = offers_num+l_rec_statsper.offers_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code IS NULL 
				AND mgr_code = l_rec_statsper.mgr_code 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statsper.sale_code = NULL 
					LET l_rec_statsper.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statsper.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statsper.year_num = p_rec_statint.year_num 
					LET l_rec_statsper.type_code = p_rec_statint.type_code 
					LET l_rec_statsper.int_num = p_rec_statint.int_num 
					LET l_rec_statsper.orders_num = 0 
					LET l_rec_statsper.credits_num = 0 
					LET l_rec_statsper.buy_cust_num = 0 
					LET l_rec_statsper.new_cust_num = 0 
					LET l_rec_statsper.lost_cust_num = 0 
					LET l_rec_statsper.poss_cust_num = NULL #null iniates count 
					INSERT INTO statsper VALUES (l_rec_statsper.*) 
				END IF 
			END IF 
		END FOREACH 
		
	END IF

	CALL disp_status(1,"S","Products") 
	IF l_rec_stattype.prod_upd_ind = "Y" 
	OR l_rec_stattype.prod_upd1_ind = "Y" 
	OR l_rec_stattype.prod_upd2_ind = "Y" 
	OR l_rec_stattype.prod_upd3_ind = "Y" THEN 
		OPEN c_statprod USING p_rec_statint.start_date,p_rec_statint.end_date 
		FOREACH c_statprod INTO l_rec_statprod.part_code, 
			l_rec_statprod.prodgrp_code, 
			l_rec_statprod.maingrp_code, 
			l_rec_statprod.dept_code, 
			l_rec_statprod.gross_amt, 
			l_rec_statprod.net_amt, 
			l_rec_statprod.cost_amt, 
			l_rec_statprod.sales_qty 
			IF l_rec_stattype.prod_upd_ind = "Y" THEN 
				UPDATE statprod 
				SET gross_amt = gross_amt + l_rec_statprod.gross_amt, 
				net_amt = net_amt + l_rec_statprod.net_amt, 
				cost_amt = cost_amt + l_rec_statprod.cost_amt, 
				sales_qty = sales_qty + l_rec_statprod.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_statprod.part_code 
				AND prodgrp_code = l_rec_statprod.prodgrp_code 
				AND maingrp_code = l_rec_statprod.maingrp_code 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statprod.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statprod.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statprod.year_num = p_rec_statint.year_num 
					LET l_rec_statprod.type_code = p_rec_statint.type_code 
					LET l_rec_statprod.int_num = p_rec_statint.int_num 
					LET l_rec_statprod.bought_amt = 0 
					LET l_rec_statprod.sold_amt = 0 
					LET l_rec_statprod.cust_num = 1 
					INSERT INTO statprod VALUES (l_rec_statprod.*) 
				END IF 
			END IF 

			IF l_rec_stattype.prod_upd1_ind = "Y" THEN 
				UPDATE statprod 
				SET gross_amt = gross_amt + l_rec_statprod.gross_amt, 
				net_amt = net_amt + l_rec_statprod.net_amt, 
				cost_amt = cost_amt + l_rec_statprod.cost_amt, 
				sales_qty = sales_qty + l_rec_statprod.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code IS NULL 
				AND prodgrp_code = l_rec_statprod.prodgrp_code 
				AND maingrp_code = l_rec_statprod.maingrp_code 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statprod.part_code = NULL 
					LET l_rec_statprod.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statprod.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statprod.year_num = p_rec_statint.year_num 
					LET l_rec_statprod.type_code = p_rec_statint.type_code 
					LET l_rec_statprod.int_num = p_rec_statint.int_num 
					LET l_rec_statprod.bought_amt = 0 
					LET l_rec_statprod.sold_amt = 0 
					LET l_rec_statprod.cust_num = 1 
					INSERT INTO statprod VALUES (l_rec_statprod.*) 
				END IF 
			END IF 

			IF l_rec_stattype.prod_upd2_ind = "Y" THEN 
				UPDATE statprod 
				SET gross_amt = gross_amt + l_rec_statprod.gross_amt, 
				net_amt = net_amt + l_rec_statprod.net_amt, 
				cost_amt = cost_amt + l_rec_statprod.cost_amt, 
				sales_qty = sales_qty + l_rec_statprod.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code IS NULL 
				AND prodgrp_code IS NULL 
				AND maingrp_code = l_rec_statprod.maingrp_code 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statprod.part_code = NULL 
					LET l_rec_statprod.prodgrp_code = NULL 
					LET l_rec_statprod.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statprod.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statprod.year_num = p_rec_statint.year_num 
					LET l_rec_statprod.type_code = p_rec_statint.type_code 
					LET l_rec_statprod.int_num = p_rec_statint.int_num 
					LET l_rec_statprod.bought_amt = 0 
					LET l_rec_statprod.sold_amt = 0 
					LET l_rec_statprod.cust_num = 1 
					INSERT INTO statprod VALUES (l_rec_statprod.*) 
				END IF 
			END IF 
			IF l_rec_stattype.prod_upd3_ind = "Y" THEN 
				IF l_rec_statprod.dept_code IS NULL THEN 
					CONTINUE FOREACH 
				ELSE 
					UPDATE statprod 
					SET gross_amt = gross_amt + l_rec_statprod.gross_amt, 
					net_amt = net_amt + l_rec_statprod.net_amt, 
					cost_amt = cost_amt + l_rec_statprod.cost_amt, 
					sales_qty = sales_qty + l_rec_statprod.sales_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code IS NULL 
					AND prodgrp_code IS NULL 
					AND maingrp_code IS NULL 
					AND dept_code = l_rec_statprod.dept_code 
					AND intseq_num = p_rec_statint.intseq_num 
					IF sqlca.sqlerrd[3] = 0 THEN 
						LET l_rec_statprod.part_code = NULL 
						LET l_rec_statprod.prodgrp_code = NULL 
						LET l_rec_statprod.maingrp_code = NULL 
						LET l_rec_statprod.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_statprod.intseq_num = p_rec_statint.intseq_num 
						LET l_rec_statprod.year_num = p_rec_statint.year_num 
						LET l_rec_statprod.type_code = p_rec_statint.type_code 
						LET l_rec_statprod.int_num = p_rec_statint.int_num 
						LET l_rec_statprod.bought_amt = 0 
						LET l_rec_statprod.sold_amt = 0 
						LET l_rec_statprod.cust_num = 1 
						INSERT INTO statprod VALUES (l_rec_statprod.*) 
					END IF 
				END IF 
			END IF 

		END FOREACH 

	END IF 

	#-------------------------------------------------------------------------
	# Warehouse /Product Groups/Main Product Groups/Departments
	#-------------------------------------------------------------------------


	CALL disp_status(1,"S","Warehouse") 
	IF l_rec_stattype.ware_upd_ind = "Y" 
	OR l_rec_stattype.ware_upd1_ind = "Y" 
	OR l_rec_stattype.ware_upd2_ind = "Y" 
	OR l_rec_stattype.ware_upd3_ind = "Y" 
	OR l_rec_stattype.ware_upd4_ind = "Y" THEN 
		OPEN c_statware USING p_rec_statint.start_date,p_rec_statint.end_date 
		FOREACH c_statware INTO l_rec_statware.ware_code, 
			l_rec_statware.part_code, 
			l_rec_statware.prodgrp_code, 
			l_rec_statware.maingrp_code, 
			l_rec_statware.dept_code, 
			l_rec_statware.gross_amt, 
			l_rec_statware.net_amt, 
			l_rec_statware.cost_amt, 
			l_rec_statware.sales_qty 
			IF l_rec_stattype.ware_upd1_ind = "Y" THEN 
				UPDATE statware 
				SET gross_amt = gross_amt + l_rec_statprod.gross_amt, 
				net_amt = net_amt + l_rec_statprod.net_amt, 
				cost_amt = cost_amt + l_rec_statprod.cost_amt, 
				sales_qty = sales_qty + l_rec_statprod.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_statware.ware_code 
				AND part_code = l_rec_statware.part_code 
				AND prodgrp_code = l_rec_statware.prodgrp_code 
				AND maingrp_code = l_rec_statware.maingrp_code 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statware.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statware.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statware.year_num = p_rec_statint.year_num 
					LET l_rec_statware.type_code = p_rec_statint.type_code 
					LET l_rec_statware.int_num = p_rec_statint.int_num 
					LET l_rec_statware.bought_amt = 0 
					LET l_rec_statware.sold_amt = 0 
					LET l_rec_statware.cust_num = 1 
					INSERT INTO statware VALUES (l_rec_statware.*) 
				END IF 
			END IF 
			IF l_rec_stattype.ware_upd2_ind = "Y" THEN 
				UPDATE statware 
				SET gross_amt = gross_amt + l_rec_statware.gross_amt, 
				net_amt = net_amt + l_rec_statware.net_amt, 
				cost_amt = cost_amt + l_rec_statware.cost_amt, 
				sales_qty = sales_qty + l_rec_statware.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_statware.ware_code 
				AND part_code IS NULL 
				AND prodgrp_code = l_rec_statware.prodgrp_code 
				AND maingrp_code = l_rec_statware.maingrp_code 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statware.part_code = NULL 
					LET l_rec_statware.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statware.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statware.year_num = p_rec_statint.year_num 
					LET l_rec_statware.type_code = p_rec_statint.type_code 
					LET l_rec_statware.int_num = p_rec_statint.int_num 
					LET l_rec_statware.bought_amt = 0 
					LET l_rec_statware.sold_amt = 0 
					LET l_rec_statware.cust_num = 1 
					INSERT INTO statware VALUES (l_rec_statware.*) 
				END IF 
			END IF 

			IF l_rec_stattype.ware_upd3_ind = "Y" THEN 
				UPDATE statware 
				SET gross_amt = gross_amt + l_rec_statware.gross_amt, 
				net_amt = net_amt + l_rec_statware.net_amt, 
				cost_amt = cost_amt + l_rec_statware.cost_amt, 
				sales_qty = sales_qty + l_rec_statware.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_statware.ware_code 
				AND part_code IS NULL 
				AND prodgrp_code IS NULL 
				AND maingrp_code = l_rec_statware.maingrp_code 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statware.part_code = NULL 
					LET l_rec_statware.prodgrp_code = NULL 
					LET l_rec_statware.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statware.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statware.year_num = p_rec_statint.year_num 
					LET l_rec_statware.type_code = p_rec_statint.type_code 
					LET l_rec_statware.int_num = p_rec_statint.int_num 
					LET l_rec_statware.bought_amt = 0 
					LET l_rec_statware.sold_amt = 0 
					LET l_rec_statware.cust_num = 1 
					INSERT INTO statware VALUES (l_rec_statware.*) 
				END IF 
			END IF 

			IF l_rec_stattype.ware_upd4_ind = "Y" THEN 
				IF l_rec_statware.dept_code IS NULL THEN 
				ELSE 
					UPDATE statware 
					SET gross_amt = gross_amt + l_rec_statware.gross_amt, 
					net_amt = net_amt + l_rec_statware.net_amt, 
					cost_amt = cost_amt + l_rec_statware.cost_amt, 
					sales_qty = sales_qty + l_rec_statware.sales_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = l_rec_statware.ware_code 
					AND part_code IS NULL 
					AND prodgrp_code IS NULL 
					AND maingrp_code IS NULL 
					AND dept_code = l_rec_statware.dept_code 
					AND intseq_num = p_rec_statint.intseq_num 
					IF sqlca.sqlerrd[3] = 0 THEN 
						LET l_rec_statware.part_code = NULL 
						LET l_rec_statware.prodgrp_code = NULL 
						LET l_rec_statware.maingrp_code = NULL 
						LET l_rec_statware.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_statware.intseq_num = p_rec_statint.intseq_num 
						LET l_rec_statware.year_num = p_rec_statint.year_num 
						LET l_rec_statware.type_code = p_rec_statint.type_code 
						LET l_rec_statware.int_num = p_rec_statint.int_num 
						LET l_rec_statware.bought_amt = 0 
						LET l_rec_statware.sold_amt = 0 
						LET l_rec_statware.cust_num = 1 
						INSERT INTO statware VALUES (l_rec_statware.*) 
					END IF 
				END IF 
			END IF 

			IF l_rec_stattype.ware_upd_ind = "Y" THEN 
				UPDATE statware 
				SET gross_amt = gross_amt + l_rec_statware.gross_amt, 
				net_amt = net_amt + l_rec_statware.net_amt, 
				cost_amt = cost_amt + l_rec_statware.cost_amt, 
				sales_qty = sales_qty + l_rec_statware.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_statware.ware_code 
				AND part_code IS NULL 
				AND prodgrp_code IS NULL 
				AND maingrp_code IS NULL 
				AND dept_code IS NULL 
				AND intseq_num = p_rec_statint.intseq_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statware.part_code = NULL 
					LET l_rec_statware.prodgrp_code = NULL 
					LET l_rec_statware.maingrp_code = NULL 
					LET l_rec_statware.dept_code = NULL 
					LET l_rec_statware.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statware.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statware.year_num = p_rec_statint.year_num 
					LET l_rec_statware.type_code = p_rec_statint.type_code 
					LET l_rec_statware.int_num = p_rec_statint.int_num 
					LET l_rec_statware.bought_amt = 0 
					LET l_rec_statware.sold_amt = 0 
					LET l_rec_statware.cust_num = 1 
					INSERT INTO statware VALUES (l_rec_statware.*) 
				END IF 
			END IF 

		END FOREACH 

	END IF 

	#-------------------------------------------------------------------------
	# Sales ie: (Customers/Products/Product Groups/Main Product Groups)
	#-------------------------------------------------------------------------

	CALL disp_status(1,"S","Sales") 
	IF l_rec_stattype.sale_upd_ind = "Y" 
	OR l_rec_stattype.sale_upd1_ind = "Y" 
	OR l_rec_stattype.sale_upd2_ind = "Y" 
	OR l_rec_stattype.sale_upd3_ind = "Y" THEN 
		OPEN c_statsale USING p_rec_statint.start_date,p_rec_statint.end_date 
		FOREACH c_statsale INTO l_rec_statsale.cust_code, 
			l_rec_statsale.part_code, 
			l_rec_statsale.prodgrp_code, 
			l_rec_statsale.maingrp_code, 
			l_rec_statsale.dept_code, 
			l_rec_statsale.sale_code, 
			l_rec_statsale.mgr_code, 
			l_rec_statsale.terr_code, 
			l_rec_statsale.area_code, 
			l_rec_statsale.gross_amt, 
			l_rec_statsale.net_amt, 
			l_rec_statsale.cost_amt, 
			l_rec_statsale.sales_qty 
			IF l_rec_stattype.sale_upd_ind = "Y" THEN 
				UPDATE statsale 
				SET gross_amt = gross_amt + l_rec_statsale.gross_amt, 
				net_amt = net_amt + l_rec_statsale.net_amt, 
				cost_amt = cost_amt + l_rec_statsale.cost_amt, 
				sales_qty = sales_qty + l_rec_statsale.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_statsale.cust_code 
				AND part_code = l_rec_statsale.part_code 
				AND prodgrp_code = l_rec_statsale.prodgrp_code 
				AND maingrp_code = l_rec_statsale.maingrp_code 
				AND intseq_num = p_rec_statint.intseq_num 
				AND sale_code = l_rec_statsale.sale_code 
				AND mgr_code = l_rec_statsale.mgr_code 
				AND terr_code = l_rec_statsale.terr_code 
				AND area_code = l_rec_statsale.area_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statsale.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statsale.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statsale.year_num = p_rec_statint.year_num 
					LET l_rec_statsale.type_code = p_rec_statint.type_code 
					LET l_rec_statsale.int_num = p_rec_statint.int_num 
					LET l_rec_statsale.first_date = p_rec_statint.start_date 
					LET l_rec_statsale.last_date = p_rec_statint.end_date 
					INSERT INTO statsale VALUES (l_rec_statsale.*) 
				END IF 
			END IF 
			IF l_rec_stattype.sale_upd1_ind = "Y" THEN 
				UPDATE statsale 
				SET gross_amt = gross_amt + l_rec_statsale.gross_amt, 
				net_amt = net_amt + l_rec_statsale.net_amt, 
				cost_amt = cost_amt + l_rec_statsale.cost_amt, 
				sales_qty = sales_qty + l_rec_statsale.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_statsale.cust_code 
				AND part_code IS NULL 
				AND prodgrp_code = l_rec_statsale.prodgrp_code 
				AND maingrp_code = l_rec_statsale.maingrp_code 
				AND intseq_num = p_rec_statint.intseq_num 
				AND sale_code = l_rec_statsale.sale_code 
				AND mgr_code = l_rec_statsale.mgr_code 
				AND terr_code = l_rec_statsale.terr_code 
				AND area_code = l_rec_statsale.area_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statsale.part_code = NULL 
					LET l_rec_statsale.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statsale.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statsale.year_num = p_rec_statint.year_num 
					LET l_rec_statsale.type_code = p_rec_statint.type_code 
					LET l_rec_statsale.int_num = p_rec_statint.int_num 
					LET l_rec_statsale.first_date = p_rec_statint.start_date 
					LET l_rec_statsale.last_date = p_rec_statint.end_date 
					INSERT INTO statsale VALUES (l_rec_statsale.*) 
				END IF 
			END IF 

			IF l_rec_stattype.sale_upd2_ind = "Y" THEN 
				UPDATE statsale 
				SET gross_amt = gross_amt + l_rec_statsale.gross_amt, 
				net_amt = net_amt + l_rec_statsale.net_amt, 
				cost_amt = cost_amt + l_rec_statsale.cost_amt, 
				sales_qty = sales_qty + l_rec_statsale.sales_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_statsale.cust_code 
				AND part_code IS NULL 
				AND prodgrp_code IS NULL 
				AND maingrp_code = l_rec_statsale.maingrp_code 
				AND intseq_num = p_rec_statint.intseq_num 
				AND sale_code = l_rec_statsale.sale_code 
				AND mgr_code = l_rec_statsale.mgr_code 
				AND terr_code = l_rec_statsale.terr_code 
				AND area_code = l_rec_statsale.area_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_statsale.prodgrp_code = NULL 
					LET l_rec_statsale.part_code = NULL 
					LET l_rec_statsale.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_statsale.intseq_num = p_rec_statint.intseq_num 
					LET l_rec_statsale.year_num = p_rec_statint.year_num 
					LET l_rec_statsale.type_code = p_rec_statint.type_code 
					LET l_rec_statsale.int_num = p_rec_statint.int_num 
					LET l_rec_statsale.first_date = p_rec_statint.start_date 
					LET l_rec_statsale.last_date = p_rec_statint.end_date 
					INSERT INTO statsale VALUES (l_rec_statsale.*) 
				END IF 
			END IF 

			IF l_rec_stattype.sale_upd3_ind = "Y" THEN 
				IF l_rec_statsale.dept_code IS NULL THEN 
					CONTINUE FOREACH 
				ELSE 
					UPDATE statsale 
					SET gross_amt = gross_amt + l_rec_statsale.gross_amt, 
					net_amt = net_amt + l_rec_statsale.net_amt, 
					cost_amt = cost_amt + l_rec_statsale.cost_amt, 
					sales_qty = sales_qty + l_rec_statsale.sales_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_rec_statsale.cust_code 
					AND part_code IS NULL 
					AND prodgrp_code IS NULL 
					AND maingrp_code IS NULL 
					AND dept_code = l_rec_statsale.dept_code 
					AND intseq_num = p_rec_statint.intseq_num 
					AND sale_code = l_rec_statsale.sale_code 
					AND mgr_code = l_rec_statsale.mgr_code 
					AND terr_code = l_rec_statsale.terr_code 
					AND area_code = l_rec_statsale.area_code 
					IF sqlca.sqlerrd[3] = 0 THEN 
						LET l_rec_statsale.maingrp_code = NULL 
						LET l_rec_statsale.prodgrp_code = NULL 
						LET l_rec_statsale.part_code = NULL 
						LET l_rec_statsale.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_statsale.intseq_num = p_rec_statint.intseq_num 
						LET l_rec_statsale.year_num = p_rec_statint.year_num 
						LET l_rec_statsale.type_code = p_rec_statint.type_code 
						LET l_rec_statsale.int_num = p_rec_statint.int_num 
						LET l_rec_statsale.first_date = p_rec_statint.start_date 
						LET l_rec_statsale.last_date = p_rec_statint.end_date 
						INSERT INTO statsale VALUES (l_rec_statsale.*) 
					END IF 
				END IF 
			END IF 
		END FOREACH 

	END IF 

	#-------------------------------------------------------------------------
	# Special Offers
	#-------------------------------------------------------------------------

	CALL disp_status(1,"S","Offers") 
	IF l_rec_stattype.offer_upd_ind = "Y" THEN 
		OPEN c_statoffer USING p_rec_statint.start_date,p_rec_statint.end_date 
		FOREACH c_statoffer INTO l_rec_statoffer.offer_code, 
			l_rec_statoffer.sale_code, 
			l_rec_statoffer.cust_code, 
			l_rec_statoffer.gross_amt, 
			l_rec_statoffer.net_amt, 
			l_rec_statoffer.cost_amt, 
			l_rec_statoffer.sales_qty 
			UPDATE statoffer 
			SET gross_amt = gross_amt + l_rec_statoffer.gross_amt, 
			net_amt = net_amt + l_rec_statoffer.net_amt, 
			cost_amt = cost_amt + l_rec_statoffer.cost_amt, 
			sales_qty = sales_qty + l_rec_statoffer.sales_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND offer_code = l_rec_statoffer.offer_code 
			AND sale_code = l_rec_statoffer.sale_code 
			AND cust_code = l_rec_statoffer.cust_code 
			AND intseq_num = p_rec_statint.intseq_num 
			IF sqlca.sqlerrd[3] = 0 THEN 
				LET l_rec_statoffer.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_statoffer.intseq_num = p_rec_statint.intseq_num 
				LET l_rec_statoffer.year_num = p_rec_statint.year_num 
				LET l_rec_statoffer.type_code = p_rec_statint.type_code 
				LET l_rec_statoffer.int_num = p_rec_statint.int_num 
				LET l_rec_statoffer.offers_num = 0 
				INSERT INTO statoffer VALUES (l_rec_statoffer.*) 
			END IF 

		END FOREACH 

	END IF 

	#-------------------------------------------------------------------------
	# Sales Conditions
	#-------------------------------------------------------------------------

	CALL disp_status(1,"S","Conditions") 
	IF l_rec_stattype.cond_upd_ind = "Y" THEN 
		OPEN c_statcond USING p_rec_statint.start_date,p_rec_statint.end_date 
		FOREACH c_statcond INTO l_rec_statcond.cust_code, 
			l_rec_statcond.cond_code, 
			l_rec_statcond.mgr_code, 
			l_rec_statcond.sale_code, 
			l_rec_statcond.gross_amt, 
			l_rec_statcond.net_amt, 
			l_rec_statcond.cost_amt, 
			l_rec_statcond.sales_qty 
			UPDATE statcond 
			SET gross_amt = gross_amt + l_rec_statcond.gross_amt, 
			net_amt = net_amt + l_rec_statcond.net_amt, 
			cost_amt = cost_amt + l_rec_statcond.cost_amt, 
			sales_qty = sales_qty + l_rec_statcond.sales_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND mgr_code = l_rec_statcond.mgr_code 
			AND sale_code = l_rec_statcond.sale_code 
			AND cond_code = l_rec_statcond.cond_code 
			AND cust_code = l_rec_statcond.cust_code 
			AND intseq_num = p_rec_statint.intseq_num 
			IF sqlca.sqlerrd[3] = 0 THEN 
				LET l_rec_statcond.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_statcond.intseq_num = p_rec_statint.intseq_num 
				LET l_rec_statcond.year_num = p_rec_statint.year_num 
				LET l_rec_statcond.type_code = p_rec_statint.type_code 
				LET l_rec_statcond.int_num = p_rec_statint.int_num 
				LET l_rec_statcond.cond_num = 0 
				INSERT INTO statcond VALUES (l_rec_statcond.*) 
			END IF 

		END FOREACH 

	END IF 

	CALL disp_status(1,"S","Complete") 
	RETURN TRUE 
	LABEL recovery: 
	RETURN FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION upd_statdetl(p_rec_statint) 
###########################################################################