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
#  ES1c.4gl - Source file contains all updates FOR statistics tables.
#
#        distterr - UPDATE/INSERT territory based statistics
#                 - includes separate section FOR shared commissions
#
#        distsper - UPDATE/INSERT salesperson based statistics
#                 - includes separate section FOR shared commissions
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ES1_GLOBALS.4gl"  

###########################################################################
# FUNCTION upd_distribution(p_rec_statint) 
#
# 
###########################################################################
FUNCTION upd_distribution(p_rec_statint) 
	DEFINE p_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_rec_statsale RECORD LIKE statsale.* 
	DEFINE l_rec_distsper RECORD LIKE distsper.* 
	DEFINE l_rec_distterr RECORD LIKE distterr.* 
	DEFINE l_arr_month_num array[12] OF INTEGER 
	DEFINE l_rowid INTEGER 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE x,y SMALLINT 

	CALL disp_status(3,"I",p_rec_statint.start_date) 
	SELECT * INTO l_rec_stattype.* 
	FROM stattype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = p_rec_statint.type_code 
	#--------------------------------------------------------
	# Remove any existing distribution statistics
	#--------------------------------------------------------
	DELETE FROM distsper 
	WHERE intseq_num = p_rec_statint.intseq_num 
	DELETE FROM distterr 
	WHERE intseq_num = p_rec_statint.intseq_num 
	#--------------------------------------------------------
	# Setup default salesperson distribution record.
	#--------------------------------------------------------
	LET l_rec_distsper.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_distsper.intseq_num = p_rec_statint.intseq_num 
	LET l_rec_distsper.year_num = p_rec_statint.year_num 
	LET l_rec_distsper.type_code = p_rec_statint.type_code 
	LET l_rec_distsper.int_num = p_rec_statint.int_num 
	#--------------------------------------------------------
	# Setup default territory distribution record.
	#--------------------------------------------------------
	LET l_rec_distterr.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_distterr.intseq_num = p_rec_statint.intseq_num 
	LET l_rec_distterr.year_num = p_rec_statint.year_num 
	LET l_rec_distterr.type_code = p_rec_statint.type_code 
	LET l_rec_distterr.int_num = p_rec_statint.int_num 
	#--------------------------------------------------------
	# FOREACH monthly sales statitics posted.
	#--------------------------------------------------------
	DECLARE c_statsale cursor FOR 
	SELECT * FROM statsale 
	WHERE intseq_num = p_rec_statint.intseq_num 
	FOREACH c_statsale INTO l_rec_statsale.* 
		CASE 
			WHEN l_rec_statsale.part_code IS NOT NULL 
				CALL disp_status(3,"S","Products") 
				FOR y = 1 TO l_rec_stattype.sper_upd_ind 
					CASE y 
						WHEN "1" 
							SELECT rowid INTO l_rowid 
							FROM distsper 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND mgr_code = l_rec_statsale.mgr_code 
							AND sale_code = l_rec_statsale.sale_code 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code = l_rec_statsale.prodgrp_code 
							AND part_code = l_rec_statsale.part_code 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distsper.sale_code = l_rec_statsale.sale_code 
						WHEN "2" 
							SELECT rowid INTO l_rowid 
							FROM distsper 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND mgr_code = l_rec_statsale.mgr_code 
							AND sale_code IS NULL 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code = l_rec_statsale.prodgrp_code 
							AND part_code = l_rec_statsale.part_code 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distsper.sale_code = NULL 
						OTHERWISE 
							EXIT FOR 
					END CASE 
					
					IF status = NOTFOUND THEN 
						LET l_rec_distsper.mgr_code = l_rec_statsale.mgr_code 
						LET l_rec_distsper.dept_code = l_rec_statsale.dept_code 
						LET l_rec_distsper.maingrp_code=l_rec_statsale.maingrp_code 
						LET l_rec_distsper.prodgrp_code=l_rec_statsale.prodgrp_code 
						LET l_rec_distsper.part_code=l_rec_statsale.part_code 
						LET l_rec_distsper.mth_net_amt = l_rec_statsale.net_amt 
						LET l_rec_distsper.mth_sales_qty = l_rec_statsale.sales_qty 
						INSERT INTO distsper VALUES (l_rec_distsper.*) 
						LET l_rowid = sqlca.sqlerrd[6] 
					ELSE 
						UPDATE distsper 
						SET mth_net_amt = mth_net_amt 
						+ l_rec_statsale.net_amt, 
						mth_sales_qty = mth_sales_qty 
						+ l_rec_statsale.sales_qty 
						WHERE rowid = l_rowid 
					END IF 
				END FOR 
				
				FOR y = 1 TO l_rec_stattype.terr_upd_ind 
					CASE y 
						WHEN "1" 
							SELECT rowid INTO l_rowid 
							FROM distterr 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND area_code = l_rec_statsale.area_code 
							AND terr_code = l_rec_statsale.terr_code 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code = l_rec_statsale.prodgrp_code 
							AND part_code = l_rec_statsale.part_code 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distterr.terr_code = l_rec_statsale.terr_code 
						WHEN "2" 
							SELECT rowid INTO l_rowid 
							FROM distterr 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND area_code = l_rec_statsale.area_code 
							AND terr_code IS NULL 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code = l_rec_statsale.prodgrp_code 
							AND part_code = l_rec_statsale.part_code 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distterr.terr_code = NULL 
						OTHERWISE 
							EXIT FOR 
					END CASE 
					IF status = NOTFOUND THEN 
						LET l_rec_distterr.area_code = l_rec_statsale.area_code 
						LET l_rec_distterr.dept_code = l_rec_statsale.dept_code 
						LET l_rec_distterr.maingrp_code=l_rec_statsale.maingrp_code 
						LET l_rec_distterr.prodgrp_code=l_rec_statsale.prodgrp_code 
						LET l_rec_distterr.part_code=l_rec_statsale.part_code 
						LET l_rec_distterr.mth_net_amt = l_rec_statsale.net_amt 
						LET l_rec_distterr.mth_sales_qty = l_rec_statsale.sales_qty 
						INSERT INTO distterr VALUES (l_rec_distterr.*) 
						LET l_rowid = sqlca.sqlerrd[6] 
					ELSE 
						UPDATE distterr 
						SET mth_net_amt = mth_net_amt 
						+ l_rec_statsale.net_amt, 
						mth_sales_qty = mth_sales_qty 
						+ l_rec_statsale.sales_qty 
						WHERE rowid = l_rowid 
					END IF 
				END FOR 

			WHEN l_rec_statsale.prodgrp_code IS NOT NULL 
				CALL disp_status(3,"S","Prod Group") 
				FOR y = 1 TO l_rec_stattype.sper_upd_ind 
					CASE y 
						WHEN "1" 
							SELECT rowid INTO l_rowid 
							FROM distsper 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND mgr_code = l_rec_statsale.mgr_code 
							AND sale_code = l_rec_statsale.sale_code 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code = l_rec_statsale.prodgrp_code 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distsper.mgr_code = l_rec_statsale.mgr_code 
							LET l_rec_distsper.sale_code = l_rec_statsale.sale_code 
						WHEN "2" 
							SELECT rowid INTO l_rowid 
							FROM distsper 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND mgr_code = l_rec_statsale.mgr_code 
							AND sale_code IS NULL 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code = l_rec_statsale.prodgrp_code 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distsper.mgr_code = l_rec_statsale.mgr_code 
							LET l_rec_distsper.sale_code = NULL 
						OTHERWISE 
							EXIT FOR 
					END CASE 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_rec_distsper.dept_code = l_rec_statsale.dept_code 
						LET l_rec_distsper.maingrp_code=l_rec_statsale.maingrp_code 
						LET l_rec_distsper.prodgrp_code=l_rec_statsale.prodgrp_code 
						LET l_rec_distsper.part_code = NULL 
						LET l_rec_distsper.mth_net_amt = l_rec_statsale.net_amt 
						LET l_rec_distsper.mth_sales_qty = l_rec_statsale.sales_qty 
						INSERT INTO distsper VALUES (l_rec_distsper.*) 
						LET l_rowid = sqlca.sqlerrd[6] 
					ELSE 
						UPDATE distsper 
						SET mth_net_amt = mth_net_amt 
						+ l_rec_statsale.net_amt, 
						mth_sales_qty = mth_sales_qty 
						+ l_rec_statsale.sales_qty 
						WHERE rowid = l_rowid 
					END IF 
				END FOR 

				FOR y = 1 TO l_rec_stattype.terr_upd_ind 
					CASE y 
						WHEN "1" 
							SELECT rowid INTO l_rowid 
							FROM distterr 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND area_code = l_rec_statsale.area_code 
							AND terr_code = l_rec_statsale.terr_code 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code = l_rec_statsale.prodgrp_code 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distterr.area_code = l_rec_statsale.area_code 
							LET l_rec_distterr.terr_code = l_rec_statsale.terr_code 
						WHEN "2" 
							SELECT rowid INTO l_rowid 
							FROM distterr 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND area_code = l_rec_statsale.area_code 
							AND terr_code IS NULL 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code = l_rec_statsale.prodgrp_code 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distterr.area_code = l_rec_statsale.area_code 
							LET l_rec_distterr.terr_code = NULL 
						OTHERWISE 
							EXIT FOR 
					END CASE 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_rec_distterr.dept_code = l_rec_statsale.dept_code 
						LET l_rec_distterr.maingrp_code=l_rec_statsale.maingrp_code 
						LET l_rec_distterr.prodgrp_code=l_rec_statsale.prodgrp_code 
						LET l_rec_distterr.part_code = NULL 
						LET l_rec_distterr.mth_net_amt = l_rec_statsale.net_amt 
						LET l_rec_distterr.mth_sales_qty = l_rec_statsale.sales_qty 
						INSERT INTO distterr VALUES (l_rec_distterr.*) 
						LET l_rowid = sqlca.sqlerrd[6] 
					ELSE 
						UPDATE distterr 
						SET mth_net_amt = mth_net_amt + l_rec_statsale.net_amt, mth_sales_qty = mth_sales_qty + l_rec_statsale.sales_qty 
						WHERE rowid = l_rowid 
					END IF 
				END FOR 

			WHEN l_rec_statsale.maingrp_code IS NOT NULL 
				CALL disp_status(3,"S","Main Group") 
				FOR y = 1 TO l_rec_stattype.sper_upd_ind 
					CASE y 
						WHEN "1" 
							SELECT rowid INTO l_rowid 
							FROM distsper 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND mgr_code = l_rec_statsale.mgr_code 
							AND sale_code = l_rec_statsale.sale_code 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code IS NULL 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distsper.mgr_code = l_rec_statsale.mgr_code 
							LET l_rec_distsper.sale_code = l_rec_statsale.sale_code 
						WHEN "2" 
							SELECT rowid INTO l_rowid 
							FROM distsper 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND mgr_code = l_rec_statsale.mgr_code 
							AND sale_code IS NULL 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code IS NULL 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distsper.mgr_code = l_rec_statsale.mgr_code 
							LET l_rec_distsper.sale_code = NULL 
						OTHERWISE 
							EXIT FOR 
					END CASE 

					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_rec_distsper.dept_code = l_rec_statsale.dept_code 
						LET l_rec_distsper.maingrp_code=l_rec_statsale.maingrp_code 
						LET l_rec_distsper.prodgrp_code = NULL 
						LET l_rec_distsper.part_code = NULL 
						LET l_rec_distsper.mth_net_amt = l_rec_statsale.net_amt 
						LET l_rec_distsper.mth_sales_qty = l_rec_statsale.sales_qty 
						INSERT INTO distsper VALUES (l_rec_distsper.*) 
						LET l_rowid = sqlca.sqlerrd[6] 
					ELSE 
						UPDATE distsper 
						SET mth_net_amt = mth_net_amt 	+ l_rec_statsale.net_amt, 	mth_sales_qty = mth_sales_qty + l_rec_statsale.sales_qty 
						WHERE rowid = l_rowid 
					END IF 
				END FOR 

				FOR y = 1 TO l_rec_stattype.terr_upd_ind 
					CASE y 
						WHEN "1" 
							SELECT rowid INTO l_rowid 
							FROM distterr 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND area_code = l_rec_statsale.area_code 
							AND terr_code = l_rec_statsale.terr_code 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code IS NULL 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distterr.area_code = l_rec_statsale.area_code 
							LET l_rec_distterr.terr_code = l_rec_statsale.terr_code 
						WHEN "2" 
							SELECT rowid INTO l_rowid 
							FROM distterr 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND area_code = l_rec_statsale.area_code 
							AND terr_code IS NULL 
							AND maingrp_code = l_rec_statsale.maingrp_code 
							AND prodgrp_code IS NULL 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distterr.area_code = l_rec_statsale.area_code 
							LET l_rec_distterr.terr_code = NULL 
						OTHERWISE 
							EXIT FOR 
					END CASE 

					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_rec_distterr.dept_code = l_rec_statsale.dept_code 
						LET l_rec_distterr.maingrp_code=l_rec_statsale.maingrp_code 
						LET l_rec_distterr.prodgrp_code = NULL 
						LET l_rec_distterr.part_code = NULL 
						LET l_rec_distterr.mth_net_amt = l_rec_statsale.net_amt 
						LET l_rec_distterr.mth_sales_qty = l_rec_statsale.sales_qty 
						INSERT INTO distterr VALUES (l_rec_distterr.*) 
						LET l_rowid = sqlca.sqlerrd[6] 
					ELSE 
						UPDATE distterr 
						SET mth_net_amt = mth_net_amt + l_rec_statsale.net_amt, 	mth_sales_qty = mth_sales_qty 	+ l_rec_statsale.sales_qty 
						WHERE rowid = l_rowid 
					END IF 
				END FOR 

			WHEN l_rec_statsale.dept_code IS NOT NULL 
				CALL disp_status(3,"S","Department") 

				FOR y = 1 TO l_rec_stattype.sper_upd_ind 
					CASE y 
						WHEN "1" 
							SELECT rowid INTO l_rowid 
							FROM distsper 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND mgr_code = l_rec_statsale.mgr_code 
							AND sale_code = l_rec_statsale.sale_code 
							AND dept_code = l_rec_statsale.dept_code 
							AND maingrp_code IS NULL 
							AND prodgrp_code IS NULL 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distsper.mgr_code = l_rec_statsale.mgr_code 
							LET l_rec_distsper.sale_code = l_rec_statsale.sale_code 
						WHEN "2" 
							SELECT rowid INTO l_rowid 
							FROM distsper 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND mgr_code = l_rec_statsale.mgr_code 
							AND sale_code IS NULL 
							AND dept_code = l_rec_statsale.dept_code 
							AND maingrp_code IS NULL 
							AND prodgrp_code IS NULL 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distsper.mgr_code = l_rec_statsale.mgr_code 
							LET l_rec_distsper.sale_code = NULL 
						OTHERWISE 
							EXIT FOR 
					END CASE 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_rec_distsper.dept_code = l_rec_statsale.dept_code 
						LET l_rec_distsper.maingrp_code = NULL 
						LET l_rec_distsper.prodgrp_code = NULL 
						LET l_rec_distsper.part_code = NULL 
						LET l_rec_distsper.mth_net_amt = l_rec_statsale.net_amt 
						LET l_rec_distsper.mth_sales_qty = l_rec_statsale.sales_qty 
						INSERT INTO distsper VALUES (l_rec_distsper.*) 
						LET l_rowid = sqlca.sqlerrd[6] 
					ELSE 
						UPDATE distsper 
						SET mth_net_amt = mth_net_amt 	+ l_rec_statsale.net_amt, mth_sales_qty = mth_sales_qty 	+ l_rec_statsale.sales_qty 
						WHERE rowid = l_rowid 
					END IF 
				END FOR 
				
				FOR y = 1 TO l_rec_stattype.terr_upd_ind 
					CASE y 
						WHEN "1" 
							SELECT rowid INTO l_rowid 
							FROM distterr 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND area_code = l_rec_statsale.area_code 
							AND terr_code = l_rec_statsale.terr_code 
							AND dept_code = l_rec_statsale.dept_code 
							AND maingrp_code IS NULL 
							AND prodgrp_code IS NULL 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distterr.area_code = l_rec_statsale.area_code 
							LET l_rec_distterr.terr_code = l_rec_statsale.terr_code 
						WHEN "2" 
							SELECT rowid INTO l_rowid 
							FROM distterr 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND area_code = l_rec_statsale.area_code 
							AND terr_code IS NULL 
							AND dept_code = l_rec_statsale.dept_code 
							AND maingrp_code IS NULL 
							AND prodgrp_code IS NULL 
							AND part_code IS NULL 
							AND intseq_num = p_rec_statint.intseq_num 
							LET l_rec_distterr.area_code = l_rec_statsale.area_code 
							LET l_rec_distterr.terr_code = NULL 
						OTHERWISE 
							EXIT FOR 
					END CASE 
					
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_rec_distterr.dept_code = l_rec_statsale.dept_code 
						LET l_rec_distterr.maingrp_code = NULL 
						LET l_rec_distterr.prodgrp_code = NULL 
						LET l_rec_distterr.part_code = NULL 
						LET l_rec_distterr.mth_net_amt = l_rec_statsale.net_amt 
						LET l_rec_distterr.mth_sales_qty = l_rec_statsale.sales_qty 
						INSERT INTO distterr VALUES (l_rec_distterr.*) 
						LET l_rowid = sqlca.sqlerrd[6] 
					ELSE 
						UPDATE distterr 
						SET mth_net_amt = mth_net_amt + l_rec_statsale.net_amt, 
						mth_sales_qty = mth_sales_qty + l_rec_statsale.sales_qty 
						WHERE rowid = l_rowid 
					END IF 
				END FOR 
		END CASE 
	END FOREACH 

	#--------------------------------------------------------
	# END of updating current months - Now need TO rollup last 3 & 12 months
	#
	#
	# create table of 12 month identifiers so all data can be accessed by
	# non-data type indexes (ie: dates).
	#--------------------------------------------------------

	LET l_arr_month_num[1] = p_rec_statint.intseq_num 
	FOR x = 2 TO 12 
		SELECT * INTO p_rec_statint.* 
		FROM statint 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = glob_rec_statparms.mth_type_code 
		AND end_date = p_rec_statint.start_date - 1 
		IF status = NOTFOUND THEN 
			EXIT FOR 
		ELSE 
			LET l_arr_month_num[x] = p_rec_statint.intseq_num 
		END IF 
	END FOR 
	
	#--------------------------------------------------------
	# Distribution Salesperson - Rollup History
	#--------------------------------------------------------
	CALL disp_status(3,"S","Salesperson") 
	DECLARE c_distsper cursor FOR 
	SELECT rowid,* FROM distsper 
	WHERE intseq_num = l_arr_month_num[1] 

	FOREACH c_distsper INTO l_rowid,	l_rec_distsper.* 

		#--------------------------------------------------------
		# Setup appropriate data fields filters
		#--------------------------------------------------------
		LET l_where_text = "mgr_code = '",l_rec_distsper.mgr_code,"'" 
		IF l_rec_distsper.sale_code IS NULL THEN 
			LET l_where_text = l_where_text clipped," AND sale_code IS null" 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
			"AND sale_code = '",l_rec_distsper.sale_code,"'" 
		END IF 
		IF l_rec_distsper.dept_code IS NULL THEN 
			LET l_where_text = l_where_text clipped," AND dept_code IS null" 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
			"AND dept_code = '",l_rec_distsper.dept_code,"'" 
		END IF 
		IF l_rec_distsper.maingrp_code IS NULL THEN 
			LET l_where_text = l_where_text clipped," AND maingrp_code IS null" 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
			"AND maingrp_code = '",l_rec_distsper.maingrp_code,"'" 
		END IF 
		IF l_rec_distsper.prodgrp_code IS NULL THEN 
			LET l_where_text = l_where_text clipped," AND prodgrp_code IS null" 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
			"AND prodgrp_code = '",l_rec_distsper.prodgrp_code,"'" 
		END IF 
		IF l_rec_distsper.part_code IS NULL THEN 
			LET l_where_text = l_where_text clipped," AND part_code IS null" 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
			"AND part_code = '",l_rec_distsper.part_code,"'" 
		END IF 
		
		#--------------------------------------------------------
		# Number of Unique Customers Update
		#--------------------------------------------------------
		LET l_query_text = "SELECT count(unique cust_code) FROM statsale ", 
		"WHERE intseq_num in (?,?,?,?,?,?,?,?,?,?,?,?) ", 
		"AND ",l_where_text clipped 
		PREPARE s1_statsale FROM l_query_text 
		DECLARE c1_statsale cursor FOR s1_statsale 
		OPEN c1_statsale USING l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1] 
		FETCH c1_statsale INTO l_rec_distsper.mth_cust_num 
		OPEN c1_statsale USING l_arr_month_num[1], 
		l_arr_month_num[2], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3] 

		FETCH c1_statsale INTO l_rec_distsper.qtr_cust_num 
		OPEN c1_statsale USING l_arr_month_num[1], 
		l_arr_month_num[2], 
		l_arr_month_num[3], 
		l_arr_month_num[4], 
		l_arr_month_num[5], 
		l_arr_month_num[6], 
		l_arr_month_num[7], 
		l_arr_month_num[8], 
		l_arr_month_num[9], 
		l_arr_month_num[10], 
		l_arr_month_num[11], 
		l_arr_month_num[12] 
		FETCH c1_statsale INTO l_rec_distsper.yr_cust_num 

		#--------------------------------------------------------
		# Net/Gross Update
		#
		# Qtr & Year Amounts
		#--------------------------------------------------------
		LET l_query_text = 
		"SELECT sum(mth_net_amt),", 
		"sum(mth_sales_qty) ", 
		"FROM distsper ", 
		"WHERE intseq_num in (?,?,?,?,?,?,?,?,?,?,?,?) ", 
		"AND ",l_where_text clipped 
		PREPARE s1_distsper FROM l_query_text 
		DECLARE c1_distsper cursor FOR s1_distsper
		 
		OPEN c1_distsper USING l_arr_month_num[1], 
		l_arr_month_num[2], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3] 
		
		FETCH c1_distsper INTO l_rec_distsper.qtr_net_amt, 
		l_rec_distsper.qtr_sales_qty 
		OPEN c1_distsper USING l_arr_month_num[1], 
		l_arr_month_num[2], 
		l_arr_month_num[3], 
		l_arr_month_num[4], 
		l_arr_month_num[5], 
		l_arr_month_num[6], 
		l_arr_month_num[7], 
		l_arr_month_num[8], 
		l_arr_month_num[9], 
		l_arr_month_num[10], 
		l_arr_month_num[11], 
		l_arr_month_num[12] 
		FETCH c1_distsper INTO l_rec_distsper.yr_net_amt, 
		l_rec_distsper.yr_sales_qty 
		UPDATE distsper SET * = l_rec_distsper.* 
		WHERE rowid = l_rowid 
	END FOREACH 

	#--------------------------------------------------------
	# Distribution Territory - Rollup History
	#--------------------------------------------------------
	CALL disp_status(3,"S","Territory") 
	DECLARE c_distterr cursor FOR 
	SELECT rowid,* FROM distterr 
	WHERE intseq_num = l_arr_month_num[1] 
	FOREACH c_distterr INTO l_rowid, 
		l_rec_distterr.* 
		LET l_where_text = "area_code = '",l_rec_distterr.area_code,"'" 
		IF l_rec_distterr.terr_code IS NULL THEN 
			LET l_where_text = l_where_text clipped," AND terr_code IS null" 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
			"AND terr_code = '",l_rec_distterr.terr_code,"'" 
		END IF 
		IF l_rec_distterr.dept_code IS NULL THEN 
			LET l_where_text = l_where_text clipped," AND dept_code IS null" 
		ELSE 
			LET l_where_text = l_where_text clipped, 
			" AND dept_code = '",l_rec_distterr.dept_code,"'" 
		END IF 
		IF l_rec_distterr.maingrp_code IS NULL THEN 
			LET l_where_text = l_where_text clipped, " AND maingrp_code IS NULL " 
		ELSE 
			LET l_where_text = l_where_text clipped, 
			" AND maingrp_code = '",l_rec_distterr.maingrp_code,"'" 
		END IF 
		IF l_rec_distterr.prodgrp_code IS NULL THEN 
			LET l_where_text = l_where_text clipped," AND prodgrp_code IS null" 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
			"AND prodgrp_code = '",l_rec_distterr.prodgrp_code,"'" 
		END IF 
		IF l_rec_distterr.part_code IS NULL THEN 
			LET l_where_text = l_where_text clipped," AND part_code IS null" 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
			"AND part_code = '",l_rec_distterr.part_code,"'" 
		END IF 
		
		#--------------------------------------------------------
		# Number of Unique Customers Update
		#--------------------------------------------------------
		LET l_query_text = "SELECT count(unique cust_code) FROM statsale ", 
		"WHERE intseq_num in (?,?,?,?,?,?,?,?,?,?,?,?) ", 
		"AND ",l_where_text clipped 
		PREPARE s2_statsale FROM l_query_text 
		DECLARE c2_statsale cursor FOR s2_statsale 
		OPEN c2_statsale USING l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1], 
		l_arr_month_num[1] 
		FETCH c2_statsale INTO l_rec_distterr.mth_cust_num 
		OPEN c2_statsale USING l_arr_month_num[1], 
		l_arr_month_num[2], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3] 
		FETCH c2_statsale INTO l_rec_distterr.qtr_cust_num 
		OPEN c2_statsale USING l_arr_month_num[1], 
		l_arr_month_num[2], 
		l_arr_month_num[3], 
		l_arr_month_num[4], 
		l_arr_month_num[5], 
		l_arr_month_num[6], 
		l_arr_month_num[7], 
		l_arr_month_num[8], 
		l_arr_month_num[9], 
		l_arr_month_num[10], 
		l_arr_month_num[11], 
		l_arr_month_num[12] 
		
		FETCH c1_statsale INTO l_rec_distterr.yr_cust_num 

		#--------------------------------------------------------
		# Net/Gross Update
		#
		# Qtr & Year Amounts
		#--------------------------------------------------------
		LET l_query_text = 
		"SELECT sum(mth_net_amt),", 
		"sum(mth_sales_qty) ", 
		"FROM distterr ", 
		"WHERE intseq_num in (?,?,?,?,?,?,?,?,?,?,?,?) ", 
		"AND ",l_where_text clipped," " 
		PREPARE s1_distterr FROM l_query_text 
		DECLARE c1_distterr cursor FOR s1_distterr 
		OPEN c1_distterr USING l_arr_month_num[1], 
		l_arr_month_num[2], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3], 
		l_arr_month_num[3]
		 
		FETCH c1_distterr INTO l_rec_distterr.qtr_net_amt, 
		l_rec_distterr.qtr_sales_qty 
		OPEN c1_distterr USING l_arr_month_num[1], 
		l_arr_month_num[2], 
		l_arr_month_num[3], 
		l_arr_month_num[4], 
		l_arr_month_num[5], 
		l_arr_month_num[6], 
		l_arr_month_num[7], 
		l_arr_month_num[8], 
		l_arr_month_num[9], 
		l_arr_month_num[10], 
		l_arr_month_num[11], 
		l_arr_month_num[12]
		 
		FETCH c1_distterr INTO l_rec_distterr.yr_net_amt, 
		l_rec_distterr.yr_sales_qty 
		UPDATE distterr SET * = l_rec_distterr.* 
		WHERE rowid = l_rowid 
	END FOREACH 
	
	CALL disp_status(3,"S","Complete")
	 
	UPDATE statint SET dist_flag = "N" 
	WHERE intseq_num = l_arr_month_num[1]
	 
	RETURN TRUE 
	LABEL recovery: 
	RETURN FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION upd_distribution(p_rec_statint) 
###########################################################################