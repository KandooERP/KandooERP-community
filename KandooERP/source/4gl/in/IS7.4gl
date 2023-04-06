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

	Source code beautified by beautify.pl on 2020-01-03 09:12:41	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IS7  Inventory Product History Update program

GLOBALS 
	DEFINE 
	pa_period array[100] OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		hist_req CHAR(1) 
	END RECORD, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_prodhist RECORD LIKE prodhist.*, 
	pr_company RECORD LIKE company.*, 
	pr_arg CHAR(2), 
	pr_rowid INTEGER, 
	year_value LIKE period.year_num, 
	period_value LIKE period.period_num, 
	balance_amt LIKE prodledg.bal_amt, 
	transaction_qty LIKE prodledg.tran_qty, 
	query_text, where_part CHAR(500), 
	err_message CHAR(40), 
	try_again CHAR(1), 
	idx, scrn, i SMALLINT 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IS7") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET pr_arg = NULL 
	IF num_args() > 0 THEN 
		LET pr_arg = arg_val(1) 
	END IF 
	IF pr_arg IS NULL THEN 
		OPEN WINDOW wi213 with FORM "I213" 
		 CALL windecoration_i("I213") -- albo kd-758 
		MESSAGE "Enter selection - ESC TO search" attribute (yellow) 
		CONSTRUCT BY NAME where_part ON year_num, period_num 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","IS7","construct-where_part-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
		LET query_text = "SELECT unique year_num, period_num", 
		" FROM period", 
		" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' AND ", 
		where_part clipped, 
		" ORDER BY year_num, period_num " 
		IF int_flag OR quit_flag THEN 
			EXIT program 
		END IF 
		PREPARE s_period FROM query_text 
		DECLARE c_period CURSOR FOR s_period 
		LET idx = 0 
		FOREACH c_period INTO year_value, period_value 
			LET idx = idx + 1 
			IF idx > 100 THEN 
				MESSAGE " Only first 100 selected " attribute(yellow) 
				SLEEP 4 
				EXIT FOREACH 
			END IF 
			LET pa_period[idx].year_num = year_value 
			LET pa_period[idx].hist_req = " " 
			LET pa_period[idx].period_num = period_value 
		END FOREACH 
		CALL set_count (idx) 
		MESSAGE "" 
		MESSAGE "Press RETURN on line TO UPDATE, F10 TO check " attribute (yellow) 
		INPUT ARRAY pa_period WITHOUT DEFAULTS FROM sr_period.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IS7","input-arr-pa_period-1") -- albo kd-505 
			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 
			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF arr_curr() > arr_count() THEN 
					ERROR "No more rows in the direction you are going" 
				END IF 
			ON KEY (F10) 
				FOR i=1 TO arr_count() 
					LET pa_period[i].hist_req = "N" 
					DECLARE c1_prodledg CURSOR FOR 
					SELECT period_num 
					INTO period_value 
					FROM prodledg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hist_flag = "N" 
					AND period_num = pa_period[i].period_num 
					AND year_num = pa_period[i].year_num 
					FOREACH c1_prodledg 
						LET pa_period[i].hist_req = "Y" 
						EXIT FOREACH 
					END FOREACH 
					IF i <= 12 THEN 
						DISPLAY pa_period[i].* TO sr_period[i].* 
					END IF 
				END FOR 
			BEFORE FIELD period_num 
				LET period_value = pa_period[idx].period_num 
				LET year_value = pa_period[idx].year_num 
				IF year_value IS NOT NULL THEN 
					MESSAGE "" 
					MESSAGE " Product history UPDATE in progress ... " 
					attribute (yellow) 
					IF hist_update() < 0 THEN 
						EXIT program 
					END IF 
					LET pa_period[idx].hist_req = "N" 
					DISPLAY pa_period[idx].hist_req TO sr_period[scrn].hist_req 
					MESSAGE "Press RETURN on line TO UPDATE, F10 TO check " 
					attribute (yellow) 
				END IF 
				NEXT FIELD year_num 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		CLOSE WINDOW wi213 
	ELSE 
		SELECT * INTO pr_company.* 
		FROM company 
		WHERE cmpy_code = pr_arg 
		IF status = notfound THEN 
			EXIT program 
		END IF 
		LET glob_rec_kandoouser.cmpy_code = pr_arg ############################# 
		CALL get_fiscal_year_period_for_date(glob_rec_kandoouser.cmpy_code,today - 1) ## period SET TO yesterday FOR onite 
		RETURNING year_value,period_value ## processing 
		IF hist_update() < 0 THEN ############################# 
			EXIT program 
		END IF 
	END IF 
END MAIN 

FUNCTION hist_update() 

	GOTO bypass 
	LABEL recovery: 
	IF pr_arg IS NULL THEN 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" THEN 
			RETURN false 
		END IF 
	ELSE 
		ROLLBACK WORK 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	LET err_message = "Product history UPDATE - IS7" 
	LET query_text = "SELECT rowid,* FROM prodledg ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "'", 
	" AND year_num = ", year_value, 
	" AND period_num = ", period_value, 
	" AND hist_flag = 'N'" 
	PREPARE s_prodledg FROM query_text 
	DECLARE c2_prodledg CURSOR with HOLD FOR s_prodledg 
	FOREACH c2_prodledg INTO pr_rowid,pr_prodledg.* 
		BEGIN WORK 
			DECLARE c3_prodledg CURSOR FOR 
			SELECT * FROM prodledg 
			WHERE rowid = pr_rowid 
			FOR UPDATE 
			OPEN c3_prodledg 
			FETCH c3_prodledg 
			DECLARE c_prodhist CURSOR FOR 
			SELECT * 
			INTO pr_prodhist.* 
			FROM prodhist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodledg.part_code 
			AND ware_code = pr_prodledg.ware_code 
			AND year_num = year_value 
			AND period_num = period_value 
			FOR UPDATE 
			OPEN c_prodhist 
			FETCH c_prodhist 
			IF status = notfound THEN 
				LET pr_prodhist.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_prodhist.part_code = pr_prodledg.part_code 
				LET pr_prodhist.ware_code = pr_prodledg.ware_code 
				LET pr_prodhist.year_num = year_value 
				LET pr_prodhist.period_num = period_value 
				LET pr_prodhist.sales_qty = 0 
				LET pr_prodhist.sales_amt = 0 
				LET pr_prodhist.sales_cost_amt = 0 
				LET pr_prodhist.credit_qty = 0 
				LET pr_prodhist.credit_amt = 0 
				LET pr_prodhist.credit_cost_amt = 0 
				LET pr_prodhist.reclassin_qty = 0 
				LET pr_prodhist.reclassin_amt = 0 
				LET pr_prodhist.reclassout_qty = 0 
				LET pr_prodhist.reclassout_amt = 0 
				LET pr_prodhist.pur_qty = 0 
				LET pr_prodhist.pur_amt = 0 
				LET pr_prodhist.transin_qty = 0 
				LET pr_prodhist.transin_amt = 0 
				LET pr_prodhist.transout_qty = 0 
				LET pr_prodhist.transout_amt = 0 
				LET pr_prodhist.adj_qty = 0 
				LET pr_prodhist.adj_amt = 0 
				SELECT bal_amt, tran_qty 
				INTO balance_amt, transaction_qty 
				FROM prodledg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_prodledg.part_code 
				AND ware_code = pr_prodledg.ware_code 
				AND year_num = year_value 
				AND period_num = period_value 
				AND seq_num = (SELECT min(seq_num) 
				FROM prodledg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_prodledg.part_code 
				AND ware_code = pr_prodledg.ware_code 
				AND year_num = year_value 
				AND period_num = period_value) 
				LET pr_prodhist.start_qty = balance_amt - transaction_qty 
				IF calc_hist() < 0 THEN 
					GOTO recovery 
				END IF 
				INSERT INTO prodhist VALUES (pr_prodhist.*) 
			ELSE 
				IF calc_hist() < 0 THEN 
					GOTO recovery 
				END IF 
				UPDATE prodhist 
				SET sales_qty = pr_prodhist.sales_qty, 
				sales_amt = pr_prodhist.sales_amt, 
				sales_cost_amt = pr_prodhist.sales_cost_amt, 
				credit_qty = pr_prodhist.credit_qty, 
				credit_amt = pr_prodhist.credit_amt, 
				credit_cost_amt = pr_prodhist.credit_cost_amt, 
				reclassin_qty = pr_prodhist.reclassin_qty, 
				reclassin_amt = pr_prodhist.reclassin_amt, 
				reclassout_qty = pr_prodhist.reclassout_qty, 
				reclassout_amt = pr_prodhist.reclassout_amt, 
				pur_qty = pr_prodhist.pur_qty, 
				pur_amt = pr_prodhist.pur_amt, 
				transin_qty = pr_prodhist.transin_qty, 
				transin_amt = pr_prodhist.transin_amt, 
				transout_qty = pr_prodhist.transout_qty, 
				transout_amt = pr_prodhist.transout_amt, 
				adj_qty = pr_prodhist.adj_qty, 
				adj_amt = pr_prodhist.adj_amt, 
				start_qty = pr_prodhist.start_qty, 
				end_qty = pr_prodhist.end_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_prodledg.part_code 
				AND ware_code = pr_prodledg.ware_code 
				AND year_num = year_value 
				AND period_num = period_value 
			END IF 
			CLOSE c_prodhist 
			UPDATE prodledg 
			SET hist_flag = "Y" 
			WHERE rowid = pr_rowid 
			CLOSE c3_prodledg 
		COMMIT WORK 
	END FOREACH 
	RETURN true 
END FUNCTION 

FUNCTION calc_hist() 

	DEFINE tmp_stk_turn FLOAT, 
	tmp_gross_per FLOAT 

	WHENEVER ERROR GOTO recovery 
	CASE 
		WHEN pr_prodledg.trantype_ind matches "[SJ]" 
			LET pr_prodhist.sales_qty = pr_prodhist.sales_qty - 
			pr_prodledg.tran_qty 
			LET pr_prodhist.sales_amt = pr_prodhist.sales_amt - 
			(pr_prodledg.sales_amt * 
			pr_prodledg.tran_qty) 
			LET pr_prodhist.sales_cost_amt = pr_prodhist.sales_cost_amt - 
			(pr_prodledg.cost_amt * 
			pr_prodledg.tran_qty) 
		WHEN pr_prodledg.trantype_ind = "C" 
			LET pr_prodhist.credit_qty = pr_prodhist.credit_qty + 
			pr_prodledg.tran_qty 
			LET pr_prodhist.credit_amt = pr_prodhist.credit_amt + 
			(pr_prodledg.sales_amt * 
			pr_prodledg.tran_qty ) 
			LET pr_prodhist.credit_cost_amt = pr_prodhist.credit_cost_amt + 
			(pr_prodledg.cost_amt * 
			pr_prodledg.tran_qty ) 
		WHEN pr_prodledg.trantype_ind matches "[PR]" 
			LET pr_prodhist.pur_qty = pr_prodhist.pur_qty + 
			pr_prodledg.tran_qty 
			LET pr_prodhist.pur_amt = pr_prodhist.pur_amt + 
			(pr_prodledg.cost_amt * 
			pr_prodledg.tran_qty ) 
		WHEN pr_prodledg.trantype_ind = "X" 
			IF pr_prodledg.tran_qty > 0 THEN 
				LET pr_prodhist.reclassin_qty = pr_prodhist.reclassin_qty + 
				pr_prodledg.tran_qty 
				LET pr_prodhist.reclassin_amt = pr_prodhist.reclassin_amt + 
				(pr_prodledg.cost_amt * 
				pr_prodledg.tran_qty ) 
			ELSE 
				LET pr_prodhist.reclassout_qty = pr_prodhist.reclassout_qty - 
				pr_prodledg.tran_qty 
				LET pr_prodhist.reclassout_amt = pr_prodhist.reclassout_amt - 
				(pr_prodledg.cost_amt * 
				pr_prodledg.tran_qty ) 
			END IF 
		WHEN pr_prodledg.trantype_ind = "T" 
			IF pr_prodledg.tran_qty > 0 THEN 
				LET pr_prodhist.transin_qty = pr_prodhist.transin_qty + 
				pr_prodledg.tran_qty 
				LET pr_prodhist.transin_amt = pr_prodhist.transin_amt + 
				(pr_prodledg.cost_amt * 
				pr_prodledg.tran_qty ) 
			ELSE 
				LET pr_prodhist.transout_qty = pr_prodhist.transout_qty - 
				pr_prodledg.tran_qty 
				LET pr_prodhist.transout_amt = pr_prodhist.transout_amt - 
				(pr_prodledg.cost_amt * 
				pr_prodledg.tran_qty ) 
			END IF 
		WHEN pr_prodledg.trantype_ind = "I" 
			LET pr_prodhist.transout_qty = pr_prodhist.transout_qty - 
			pr_prodledg.tran_qty 
			LET pr_prodhist.transout_amt = pr_prodhist.transout_amt - 
			(pr_prodledg.cost_amt * 
			pr_prodledg.tran_qty ) 
		WHEN pr_prodledg.trantype_ind = "A" 
			LET pr_prodhist.adj_qty = pr_prodhist.adj_qty + 
			pr_prodledg.tran_qty 
		WHEN pr_prodledg.trantype_ind = "U" 
			LET pr_prodhist.adj_amt = pr_prodhist.adj_amt + 
			(pr_prodledg.cost_amt * 
			pr_prodledg.tran_qty ) 
	END CASE 
	IF (pr_prodhist.sales_amt - pr_prodhist.credit_amt) != 0 THEN 
		#check percentage FOR reasonable limits
		LET tmp_gross_per = 
		(pr_prodhist.sales_amt - pr_prodhist.sales_cost_amt - 
		pr_prodhist.credit_amt + pr_prodhist.credit_cost_amt) / 
		(pr_prodhist.sales_amt - pr_prodhist.credit_amt) * 100 
		IF tmp_gross_per > 999.99 THEN 
			LET tmp_gross_per = 999.99 
		ELSE 
			IF tmp_gross_per < -999.99 THEN 
				LET tmp_gross_per = -999.99 
			END IF 
		END IF 
		LET pr_prodhist.gross_per = tmp_gross_per 
	ELSE 
		LET pr_prodhist.gross_per = NULL 
	END IF 

	SELECT bal_amt 
	INTO pr_prodhist.end_qty 
	FROM prodledg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_prodledg.part_code 
	AND ware_code = pr_prodledg.ware_code 
	AND year_num = year_value 
	AND period_num = period_value 
	AND seq_num = (SELECT max(seq_num) 
	FROM prodledg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_prodledg.part_code 
	AND ware_code = pr_prodledg.ware_code 
	AND year_num = year_value 
	AND period_num = period_value) 
	IF (pr_prodhist.start_qty + pr_prodhist.end_qty) != 0 THEN 

		LET tmp_stk_turn = 
		(pr_prodhist.sales_qty - pr_prodhist.credit_qty) / 
		((pr_prodhist.start_qty + pr_prodhist.end_qty) / 2) 

		IF tmp_stk_turn > 999.99 THEN 
			LET tmp_stk_turn = 999.99 
		END IF 
		IF tmp_stk_turn < -99.99 THEN 
			LET tmp_stk_turn = -99.99 
		END IF 
		LET pr_prodhist.stock_turn_qty = tmp_stk_turn 
	ELSE 
		LET pr_prodhist.stock_turn_qty = NULL 
	END IF 
	LABEL recovery: 
	RETURN status 
END FUNCTION 
