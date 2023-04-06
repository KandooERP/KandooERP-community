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

	Source code beautified by beautify.pl on 2020-01-03 09:12:25	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module I27b - Allows the user TO SELECT the cost ledger TO be changed
# AND THEN change the prouct qty details

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
--GLOBALS "I27_GLOBALS.4gl" 
DEFINE pr_inparms RECORD LIKE inparms.*

DEFINE pa_costledg array[7] OF RECORD 
	tran_date LIKE costledg.tran_date, 
	onhand_qty INTEGER, 
	curr_cost_amt LIKE costledg.curr_cost_amt 
END RECORD, 
pop_cost RECORD 	
	tran_date LIKE costledg.tran_date, 
	onhand_qty INTEGER, 
	curr_cost_amt LIKE costledg.curr_cost_amt 
END RECORD, 

pa_rowid array[7] OF INTEGER, 
idx2, cur2, nxt2, pa_tot2, laslin2 SMALLINT 




FUNCTION sel_cost(p_cmpy, p_ware_code, p_part_code, p_sign_on_code) 

	DEFINE 
	p_ware_code LIKE warehouse.ware_code, 
	p_part_code LIKE prodstatus.part_code, 
	p_cmpy LIKE company.cmpy_code, 
	p_sign_on_code LIKE kandoouser.sign_on_code, 
	pr_product RECORD LIKE product.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	where_part CHAR(100), 
	sel_text CHAR(500), 
	y INTEGER, 
	i, usr_esc SMALLINT, 
	reset_flag SMALLINT, 
	pr_tran_date LIKE costledg.tran_date 

	LET int_flag = false 
	LET quit_flag = false 
	OPEN WINDOW wi204 with FORM "I204" 
	 CALL windecoration_i("I204") -- albo kd-758 

	LET sel_text = 
	"SELECT costledg.tran_date, costledg.onhand_qty, ", 
	" costledg.curr_cost_amt, rowid ", 
	" FROM costledg ", 
	" WHERE costledg.cmpy_code = \"",p_cmpy,"\" AND ", 
	" costledg.ware_code = \"",p_ware_code,"\" AND ", 
	" costledg.part_code = \"",p_part_code,"\" ", 
	" ORDER BY costledg.tran_date" 

	PREPARE sel_stmt FROM sel_text 
	DECLARE cost_curs SCROLL CURSOR with HOLD FOR sel_stmt 
	LET pa_tot2 = 5 
	LET idx2 = 0 

	WHILE true 
		OPEN cost_curs 
		INITIALIZE pop_cost.* TO NULL 
		FOR i = 1 TO 7 
			INITIALIZE pa_costledg[i].* TO NULL 
		END FOR 

		FOR i = 2 TO 6 
			LET y = idx2 + i - 1 
			FETCH absolute y cost_curs INTO pa_costledg[i].*, pa_rowid[i] 
			IF status = notfound THEN 
				LET pa_tot2 = 0 
				EXIT FOR 
			END IF 
		END FOR 

		CALL set_count(7) 
		LET nxt2 = 2 
		LET laslin2 = false 

		LET msgresp = kandoomsg("I",1503,"") 
		#1503 TAB on line TO enter adjustment; OK TO continue.
		SELECT * INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		SELECT * INTO pr_warehouse.* FROM warehouse 
		WHERE cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		DISPLAY pr_product.part_code, 
		pr_product.desc_text, 
		pr_product.desc2_text, 
		pr_warehouse.ware_code, 
		pr_warehouse.desc_text 
		TO prodstatus.part_code, 
		product.desc_text, 
		product.desc2_text, 
		prodstatus.ware_code, 
		warehouse.desc_text 


		WHILE true 
			LET usr_esc = true 
			IF laslin2 THEN 
				LET nxt2 = 6 
				LET laslin2 = false 
				CALL shflup2() 
			END IF 
			INPUT ARRAY pa_costledg WITHOUT DEFAULTS FROM sr_costledg.* 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","I27b","input-arr-pa_costledg-1") -- albo kd-505 

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				BEFORE ROW 
					LET cur2 = arr_curr() 
					IF nxt2 IS NULL THEN 
						IF cur2 = 1 THEN 
							LET nxt2 = 2 
							CALL shfldown2() 
						ELSE 
							IF cur2 = 7 THEN 
								LET laslin2 = true 
								LET usr_esc = false 
								EXIT INPUT 
							END IF 
						END IF 
					END IF 
					IF nxt2 > cur2 THEN 
						NEXT FIELD curr_cost_amt 
					END IF 
					LET nxt2 = NULL 

				BEFORE FIELD tran_date 
					LET cur2 = arr_curr() 
					LET pr_tran_date = pa_costledg[cur2].tran_date 

				BEFORE FIELD onhand_qty 
					LET pa_costledg[cur2].tran_date = pr_tran_date 
					IF pa_costledg[cur2].tran_date IS NOT NULL THEN 
						CALL chg_qty(p_cmpy, p_sign_on_code, p_ware_code, p_part_code, 
						pa_costledg[cur2].tran_date, pa_rowid[cur2]) 
						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
							LET reset_flag = false 
						ELSE 
							LET usr_esc = false 
							LET reset_flag = true 
							EXIT INPUT 
						END IF 
					END IF 
					NEXT FIELD tran_date 

				AFTER ROW 
					LET cur2 = arr_curr() 
				ON KEY (F4) # PAGE down 
					CALL pagedown2() 
					LET usr_esc = false 
					LET laslin2 = false 
					LET nxt2 = 2 
					EXIT INPUT 
				ON KEY (F3) # PAGE up 
					CALL pageup2() 
					LET usr_esc = false 
					LET laslin2 = false 
					LET nxt2 = 2 
					EXIT INPUT 
				ON KEY (control-w) 
					CALL kandoohelp("") 
			END INPUT 
			IF quit_flag OR int_flag THEN 
				EXIT WHILE 
			END IF 
			IF reset_flag THEN 
				EXIT WHILE 
			END IF 
			IF usr_esc THEN 
				EXIT WHILE 
			END IF 
		END WHILE 
		CLOSE cost_curs 
		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
			EXIT WHILE 
		END IF 
		IF usr_esc THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW wi204 
END FUNCTION 











#FETCH row AT bottom of SELECT list AND move rows in array
#up one. row AT top IS lost AND row AT bottom becomes newly
#FETCHed row.

FUNCTION shflup2() 
	DEFINE 
	i SMALLINT, 
	x, pr_rowid INTEGER 

	IF pa_tot2 = 0 THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		RETURN 
	END IF 
	LET idx2 = idx2 + 1 
	LET x = idx2 + pa_tot2 
	FETCH absolute x cost_curs INTO pop_cost.*, pr_rowid 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		LET idx2 = idx2 - 1 
		RETURN 
	END IF 
	FOR i = 1 TO pa_tot2 
		LET pa_costledg[i+1].* = pa_costledg[i+2].* 
		LET pa_rowid[i+1] = pa_rowid[i+2] 
	END FOR 
	LET pa_costledg[6].* = pop_cost.* 
	LET pa_rowid[6] = pr_rowid 
END FUNCTION 

#FETCH row AT top of SELECT list AND move rows in array
#down one. Row AT bottom IS lost AND row AT top becomes newly
#FETCHed row.

FUNCTION shfldown2() 
	DEFINE 
	i SMALLINT, 
	pr_rowid INTEGER 

	IF idx2 = 0 THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		RETURN 
	ELSE 
		FETCH absolute idx2 cost_curs INTO pop_cost.*, pr_rowid 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("I",9117,"") 
			#9117 Logic Error: Costledger NOT found.
			INITIALIZE pop_cost.* TO NULL 
		END IF 
		LET idx2 = idx2 - 1 
		LET i = 6 
		WHILE i > 2 
			LET pa_costledg[i].* = pa_costledg[i-1].* 
			LET pa_rowid[i] = pa_rowid[i-1] 
			DISPLAY pa_costledg[i].* TO sr_costledg[i].* 
			LET i = i - 1 
		END WHILE 
		LET pa_costledg[2].* = pop_cost.* 
		LET pa_rowid[2] = pr_rowid 
		DISPLAY pa_costledg[2].* TO sr_costledg[2].* 
	END IF 
END FUNCTION 

#FETCH rows AT bottom of SELECT list AND move rows in array
#out. Rows are lost AND replaced by newly FETCHed rows

FUNCTION pageup2() 
	DEFINE 
	x, i, j, diff SMALLINT, 
	pr_rowid INTEGER 

	IF pa_tot2 = 0 THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		RETURN 
	END IF 
	FOR i = 1 TO 5 
		LET idx2 = idx2 + 1 
		LET x = pa_tot2 + idx2 
		FETCH absolute x cost_curs INTO pop_cost.*, pr_rowid 
		IF status = notfound THEN 
			IF i = 1 THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There are no more rows in the direction you are going.
				LET idx2 = idx2 - 1 
			ELSE # this code IS performed so that the LAST screen has 5 items 
				# AND the idx2 ARRAY counter IS NOT upset
				LET diff = 5 - i 
				LET idx2 = idx2 - i 
				LET idx2 = idx2 - (diff + 1) 
				FOR i = 1 TO 5 
					LET idx2 = idx2 + 1 
					LET x = pa_tot2 + idx2 
					FETCH absolute x cost_curs INTO pop_cost.*, pr_rowid 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("I",2001,"") 
						#2001 "Error in ARRAY processing"
						EXIT program 
					END IF 
					IF i = 1 THEN 
						FOR j = 1 TO 7 
							INITIALIZE pa_costledg[j].* TO NULL 
						END FOR 
					END IF 
					LET pa_costledg[i+1].* = pop_cost.* 
					LET pa_rowid[i+1] = pr_rowid 
				END FOR 
			END IF 
			RETURN 
		END IF 
		IF i = 1 THEN 
			FOR j = 1 TO 7 
				INITIALIZE pa_costledg[j].* TO NULL 
			END FOR 
		END IF 
		LET pa_costledg[i+1].* = pop_cost.* 
		LET pa_rowid[i+1] = pr_rowid 
	END FOR 
END FUNCTION 

#FETCH rows AT top of SELECT list AND move rows in array
#out. Rows are lost AND replaced by newly FETCHed rows

FUNCTION pagedown2() 
	DEFINE 
	x, i, j, diff SMALLINT, 
	pr_rowid INTEGER 

	IF pa_tot2 = 0 
	OR idx2 = 0 THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		RETURN 
	END IF 
	LET idx2 = idx2 - 10 
	IF idx2 < -5 THEN 
		LET idx2 = -5 
	END IF 
	FOR i = 1 TO 5 
		LET idx2 = idx2 + 1 
		LET x = pa_tot2 + idx2 
		FETCH absolute x cost_curs INTO pop_cost.*, pr_rowid 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("I",2001,"") 
			#2001 "Error in ARRAY processing"
			EXIT program 
		END IF 
		IF i = 1 THEN 
			FOR j = 1 TO 7 
				INITIALIZE pa_costledg[j].* TO NULL 
			END FOR 
		END IF 
		LET pa_costledg[i+1].* = pop_cost.* 
		LET pa_rowid[i+1] = pr_rowid 
	END FOR 
END FUNCTION 


FUNCTION chg_qty(p_cmpy, p_sign_on_code, p_ware_code, p_part_code, p_cost_date, p_rowid) 

	DEFINE 
	p_ware_code LIKE warehouse.ware_code, 
	p_cmpy LIKE company.cmpy_code, 
	p_sign_on_code LIKE kandoouser.sign_on_code, 
	p_rowid INTEGER, 
	pr_product RECORD LIKE product.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_costledg RECORD LIKE costledg.*, 
	p_part_code LIKE prodstatus.part_code, 
	p_cost_date LIKE costledg.tran_date, #huho NOT used ???? 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_coa RECORD LIKE coa.*, 
	pr_category RECORD LIKE category.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodadjtype RECORD LIKE prodadjtype.*, 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	new_onhand_qty LIKE costledg.onhand_qty, 
	save_onhand_qty LIKE costledg.onhand_qty, 
	mask_code LIKE warehouse.acct_mask_code, 
	pr_sto_sell_tran_qty LIKE prodledg.tran_qty, 
	pr_rel_qty LIKE costledg.onhand_qty, 
	winds_text CHAR(200), 
	failed_it CHAR(1), 
	try_again CHAR(1), 
	pr_reedit CHAR(1), 
	err_message CHAR(80), 
	pr_pos_adj CHAR(1), 
	pr_lastkey INTEGER, 
	pr_cnt SMALLINT, 
	pr_tmp_source_text LIKE prodledg.source_text ,
	pr_tmp_adj_type_code LIKE prodledg.source_code

	SELECT * INTO pr_product.* 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND product.part_code = p_part_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("I",5013,"") 
		#5013  Product code NOT found.
		CALL errorlog ("I27b - Product missing? - deleted") 
		ROLLBACK WORK 
		EXIT program 
	END IF 

	SELECT * INTO pr_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND warehouse.ware_code = p_ware_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("I",7034,"") 
		#I       7034  Warehouse does NOT exist.
		CALL errorlog ("S28aa - Active warehouse missing? - deleted") 
		ROLLBACK WORK 
		EXIT program 
	END IF 

	SELECT * INTO pr_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	AND ware_code = p_ware_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("A",9126,"") 
		#9126  Product NOT stocked AT this warehouse.
		CALL errorlog ("I27b - Prodstatus missing? - deleted") 
		ROLLBACK WORK 
		EXIT program 
	END IF 

	SELECT * INTO pr_costledg.* 
	FROM costledg 
	WHERE costledg.cmpy_code = p_cmpy 
	AND costledg.ware_code = p_ware_code 
	AND costledg.part_code = p_part_code 
	AND costledg.tran_date = tran_date 
	AND rowid = p_rowid 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("I",9117,"") 
		#9117 Logic Error: Costledger NOT found.
		CALL errorlog ("S28aa - Active costledger missing? - deleted") 
		ROLLBACK WORK 
		EXIT program 
	END IF 

	CALL serial_init(p_cmpy, '', '', '' ) 
	LET pr_cnt = 0 
	LET pr_pos_adj = 'Y' 
	OPEN WINDOW wi205 with FORM "I205" 
	 CALL windecoration_i("I205") -- albo kd-758 
	DISPLAY p_part_code, 
	pr_product.desc_text, 
	pr_product.desc2_text, 
	p_ware_code, 
	pr_warehouse.desc_text, 
	pr_costledg.onhand_qty, 
	pr_costledg.curr_cost_amt 
	TO part_code, 
	product.desc_text, 
	product.desc2_text, 
	ware_code, 
	warehouse.desc_text, 
	onhand_qty, 
	curr_cost_amt 


	SELECT * INTO pr_category.* 
	FROM category 
	WHERE cmpy_code = p_cmpy 
	AND cat_code = pr_product.cat_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("N",9029,p_part_code) 
		#9029  Product category FOR part code
		EXIT program 
	END IF 

	LET pr_prodledg.acct_code = pr_category.adj_acct_code 
	SELECT desc_text INTO pr_coa.desc_text 
	FROM coa 
	WHERE coa.acct_code = pr_prodledg.acct_code 
	AND coa.cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET pr_coa.desc_text = "" 
	END IF 
	DISPLAY pr_prodledg.acct_code, 
	pr_coa.desc_text 
	TO prodledg.acct_code, 
	coa.desc_text 


	LET pr_prodledg.tran_qty = NULL 
	LET pr_prodledg.source_num = NULL 
	LET pr_prodledg.desc_text = NULL 
	LET pr_prodledg.tran_date = today 
	CALL db_period_what_period(p_cmpy, pr_prodledg.tran_date) 
	RETURNING pr_prodledg.year_num, pr_prodledg.period_num 

	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") <> "1" THEN 
		LET pr_prodledg.source_text = "Adjust" 
	END IF 

	DISPLAY BY NAME pr_prodledg.tran_date, 
	pr_prodledg.year_num, 
	pr_prodledg.period_num, 
	pr_prodledg.source_num, 
	pr_prodledg.source_code,
	pr_prodledg.source_text, 
	pr_prodledg.desc_text, 
	pr_prodledg.tran_qty 

	LET msgresp = kandoomsg("U","1504","") 
	#1504 Enter Product Adjustment details; OK TO continue.
	INPUT BY NAME pr_prodledg.tran_date, 
	pr_prodledg.year_num, 
	pr_prodledg.period_num, 
	pr_prodledg.source_code,
	pr_prodledg.source_text, 
	pr_prodledg.source_num, 
	pr_prodledg.desc_text, 
	pr_prodledg.acct_code, 
	pr_prodledg.tran_qty WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I27b","input-pr_prodledg-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-w) 
			CALL kandoohelp("") 

		ON KEY (control-b) 
			CASE 
				WHEN infield (acct_code) 
					LET pr_prodledg.acct_code = show_acct(p_cmpy) 
					DISPLAY BY NAME pr_prodledg.acct_code 

					NEXT FIELD acct_code 

				WHEN infield (prod_adj_type) 
					LET winds_text = show_adj_type_code(p_cmpy) 
					IF winds_text IS NOT NULL THEN 
						LET pr_prodledg.source_code = winds_text clipped 
						SELECT * INTO pr_prodadjtype.* 
						FROM prodadjtype 
						WHERE source_code = pr_prodledg.source_code 
						AND cmpy_code = p_cmpy 
						LET pr_prodledg.source_type = "PADJ" 
						LET pr_prodledg.desc_text = pr_prodadjtype.desc_text 
						LET pr_prodledg.acct_code = pr_prodadjtype.adj_acct_code 
						DISPLAY pr_prodledg.desc_text TO prodledg.desc_text 

						NEXT FIELD prod_adj_type 
					END IF 
			END CASE 

		ON KEY (control-n) 
			IF infield(desc_text) THEN 
				LET pr_prodledg.desc_text = sys_noter(p_cmpy, pr_prodledg.desc_text) 
				NEXT FIELD previous 
			END IF 

		AFTER FIELD tran_date 
			IF pr_prodledg.tran_date IS NULL THEN 
				LET pr_prodledg.tran_date = today 
			END IF 
			CALL db_period_what_period(p_cmpy, pr_prodledg.tran_date) 
			RETURNING pr_prodledg.year_num, pr_prodledg.period_num 
			DISPLAY BY NAME pr_prodledg.year_num, 
			pr_prodledg.period_num, 
			pr_prodledg.tran_date 


		AFTER FIELD year_num 
			IF pr_prodledg.year_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD year_num 
			END IF 
			
		AFTER FIELD period_num 
			IF pr_prodledg.period_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD period_num 
			END IF 
			CALL valid_period(p_cmpy, pr_prodledg.year_num, pr_prodledg.period_num, 'in') 
			RETURNING pr_prodledg.year_num, pr_prodledg.period_num,failed_it 
			DISPLAY BY NAME pr_prodledg.year_num, pr_prodledg.period_num 

			IF failed_it = 1 THEN 
				NEXT FIELD year_num 
			END IF 

		BEFORE FIELD prod_adj_type 
			LET pr_tmp_adj_type_code = pr_prodledg.source_code 
		
		AFTER FIELD prod_adj_type 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
				IF pr_prodledg.source_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9167,"") 
					#9167 Adjustment type code must be entered.
					NEXT FIELD prod_adj_type 
				END IF 
				SELECT * INTO pr_prodadjtype.* 
				FROM prodadjtype 
				WHERE source_code = pr_prodledg.source_code 
				AND cmpy_code = p_cmpy 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9166,"") 
					#9166 Adjustment Type Not Found - Try Window
					NEXT FIELD source_text 
				END IF 
				LET pr_prodledg.source_type = "PADJ"			#the source is a product adjustement
				IF pr_prodadjtype.desc_text IS NULL THEN 
					LET pr_prodledg.desc_text = pr_prodadjtype.desc_text 
				END IF 
				IF pr_tmp_adj_type_code IS NULL 
				OR pr_tmp_adj_type_code != pr_prodledg.source_code THEN 
					LET pr_prodledg.desc_text = pr_prodadjtype.desc_text 
					LET pr_prodledg.acct_code = pr_prodadjtype.adj_acct_code 
				END IF 
				IF pr_prodledg.acct_code IS NULL THEN 
					SELECT acct_mask_code INTO mask_code FROM warehouse 
					WHERE ware_code = pr_prodstatus.ware_code 
					AND cmpy_code = p_cmpy 
					IF status = notfound OR mask_code IS NULL 
					OR mask_code = " " THEN 
						CALL build_mask(p_cmpy, 
						"??????????????????", 
						" ") 
						RETURNING mask_code 
					END IF 
					LET pr_prodledg.acct_code = build_mask(p_cmpy,mask_code,pr_prodadjtype.adj_acct_code) 
				END IF 
			ELSE 
				IF pr_tmp_adj_type_code IS NULL 
				OR pr_tmp_adj_type_code != pr_prodledg.source_code THEN 
					SELECT * INTO pr_prodadjtype.* 
					FROM prodadjtype 
					WHERE cmpy_code = p_cmpy 
					AND adj_type_code = pr_prodledg.source_code 
					IF status != notfound THEN 
						LET pr_prodledg.acct_code = pr_prodadjtype.adj_acct_code 
						LET pr_prodledg.desc_text = pr_prodadjtype.desc_text 
					END IF 
				END IF 
				IF pr_prodledg.acct_code IS NULL THEN 
					LET pr_prodledg.acct_code = pr_category.adj_acct_code 
				END IF 
			END IF 
			SELECT desc_text INTO pr_coa.desc_text 
			FROM coa 
			WHERE coa.acct_code = pr_prodledg.acct_code 
			AND coa.cmpy_code = p_cmpy 
			IF status = notfound THEN 
				LET pr_coa.desc_text = NULL 
			END IF 
			DISPLAY BY NAME pr_prodledg.source_code, 
			pr_prodledg.desc_text, 
			pr_prodledg.acct_code, 
			pr_coa.desc_text 
			--TO prodledg.source_text, 
			--prodledg.desc_text, 
			--prodledg.acct_code, 
			--coa.desc_text 

		AFTER FIELD acct_code 
			SELECT coa.* INTO pr_coa.* 
			FROM coa 
			WHERE coa.acct_code = pr_prodledg.acct_code 
			AND coa.cmpy_code = p_cmpy 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("G",9112,"") 
				#9112  Account code does NOT exist;  Try Window.
				NEXT FIELD acct_code 
			ELSE 
				IF NOT acct_type(p_cmpy,pr_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 
			END IF 
			DISPLAY pr_coa.desc_text TO coa.desc_text 


		BEFORE FIELD source_num 
			IF pr_inparms.auto_adjust_flag = "Y" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD source_num 
			IF pr_inparms.auto_adjust_flag <> "Y" THEN 
				IF pr_prodledg.source_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD source_num 
				END IF 
			END IF 

		BEFORE FIELD tran_qty 
			LET pr_sto_sell_tran_qty = pr_prodledg.tran_qty 

		AFTER FIELD tran_qty 
			IF pr_prodledg.tran_qty IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD tran_qty 
			END IF 
			IF pr_prodledg.tran_qty = pr_costledg.onhand_qty THEN 
				LET msgresp = kandoomsg("I",9060,"") 
				#9060 New Quantity must NOT equal current quantity.
				NEXT FIELD tran_qty 
			END IF 
			IF ( pr_prodstatus.onhand_qty + pr_prodledg.tran_qty 
			- pr_costledg.onhand_qty ) < 0 THEN 
				LET msgresp = kandoomsg("I",6015,"") 
				#6015 WARNING: This will make the on hand quantity negative.
				IF msgresp <> 'Y' THEN 
					NEXT FIELD tran_qty 
				END IF 
			END IF 

			IF pr_product.serial_flag = 'Y' THEN 
				IF pr_prodledg.tran_qty > pr_costledg.onhand_qty 
				AND pr_sto_sell_tran_qty < pr_costledg.onhand_qty THEN 
					CALL serial_init(p_cmpy, '', '', '' ) 
					LET pr_cnt = 0 
					LET pr_pos_adj = 'Y' 
				END IF 
				IF pr_prodledg.tran_qty < pr_costledg.onhand_qty 
				AND ( pr_sto_sell_tran_qty > pr_costledg.onhand_qty 
				OR pr_pos_adj = 'Y' ) THEN 
					CALL serial_init(p_cmpy, '', '0', '' ) 
					LET pr_cnt = 0 
					LET pr_pos_adj = 'N' 
				END IF 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_cnt = serial_input(pr_product.part_code, 
				pr_prodstatus.ware_code,pr_cnt) 
				IF pr_cnt < 0 THEN 
					EXIT program 
				ELSE 
					LET pr_rel_qty = pr_prodledg.tran_qty - pr_costledg.onhand_qty 
					IF pr_rel_qty > 0 THEN 
						IF pr_cnt <> pr_rel_qty THEN 
							LET msgresp = kandoomsg("I",9302,pr_rel_qty) 
							#9302 x Serial Codes need TO be entered. ie.
							NEXT FIELD tran_qty 
						END IF 
					ELSE 
						IF pr_cnt <> ( -1 * pr_rel_qty ) THEN 
							LET msgresp = kandoomsg("I",9302,pr_rel_qty) 
							#9302 x Serial Codes need TO be entered. ie.
							NEXT FIELD tran_qty 
						END IF 
					END IF 
					IF pr_lastkey = fgl_keyval("up") 
					OR pr_lastkey = fgl_keyval("left") THEN 
						NEXT FIELD tran_qty 
					ELSE 
						NEXT FIELD tran_date 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_prodledg.tran_date IS NULL THEN 
					LET pr_prodledg.tran_date = today 
				END IF 
				CALL db_period_what_period(p_cmpy, pr_prodledg.tran_date) 
				RETURNING pr_prodledg.year_num, pr_prodledg.period_num 
				DISPLAY BY NAME pr_prodledg.year_num, 
				pr_prodledg.period_num, 
				pr_prodledg.tran_date 


				CALL valid_period(p_cmpy, pr_prodledg.year_num, 
				pr_prodledg.period_num, 'in') 
				RETURNING pr_prodledg.year_num, pr_prodledg.period_num, 
				failed_it 
				DISPLAY BY NAME pr_prodledg.year_num, 
				pr_prodledg.period_num 

				IF failed_it = 1 THEN 
					NEXT FIELD year_num 
				END IF 

				SELECT coa.* INTO pr_coa.* FROM coa 
				WHERE coa.acct_code = pr_prodledg.acct_code AND 
				coa.cmpy_code = p_cmpy 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("G",9112,"") 
					#9112  Account code does NOT exist;  Try Window.
					NEXT FIELD acct_code 
				ELSE 
					IF NOT acct_type(p_cmpy,pr_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD acct_code 
					END IF 
				END IF 
				DISPLAY pr_coa.desc_text TO coa.desc_text 


				IF pr_prodledg.tran_qty IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD tran_qty 
				END IF 

				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
					IF pr_prodledg.source_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD source_text 
					END IF 
					SELECT * INTO pr_prodadjtype.* 
					FROM prodadjtype 
					WHERE source_code = pr_prodledg.source_code 
					AND cmpy_code = p_cmpy 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("I",9166,"") 
						#9166 Adjustment Type Not Found - Try Window
						NEXT FIELD prod_adj_type 
					END IF 
				END IF 

				IF pr_inparms.auto_adjust_flag <> "Y" THEN 
					IF pr_prodledg.source_num IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD source_num 
					END IF 
				END IF 

				OPEN WINDOW w1_i27 at 2,9 with 3 rows,52 COLUMNS 
				attribute(border, MENU line 2) 
				LET pr_reedit = 'N' 
				MENU " Quantity Adjustment " 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","I27b","menu-Quantity-1") -- albo kd-505 

					ON ACTION "WEB-HELP" -- albo kd-372 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Save" " Save Adjustment TO Database" 
						EXIT MENU 
					COMMAND KEY("E",Interrupt)"Exit" 
						" RETURN TO editting Adjustment" 
						LET pr_reedit = 'Y' 
						EXIT MENU 
					COMMAND KEY (control-w) 
						CALL kandoohelp("") 
				END MENU 
				CLOSE WINDOW w1_i27 
				IF pr_reedit = 'Y' THEN 
					NEXT FIELD tran_date 
				END IF 

			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW wi205 
		RETURN 
	END IF 
	# now do updates
	LET new_onhand_qty = pr_prodledg.tran_qty 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		LET err_message = "I27b - Itemstat UPDATE" 
		DECLARE ps_cur2 CURSOR FOR 
		SELECT * INTO pr_prodstatus.* 
		FROM prodstatus 
		WHERE prodstatus.cmpy_code = p_cmpy 
		AND prodstatus.part_code = p_part_code 
		AND prodstatus.ware_code = p_ware_code 
		FOR UPDATE 
		FOREACH ps_cur2 
			LET save_onhand_qty = pr_prodstatus.onhand_qty 
			LET pr_prodstatus.onhand_qty = save_onhand_qty + 
			(new_onhand_qty - pr_costledg.onhand_qty) 
			IF pr_prodstatus.onhand_qty != 0 THEN 
				LET pr_prodstatus.wgted_cost_amt = 
				((pr_prodstatus.wgted_cost_amt * save_onhand_qty) - 
				(pr_costledg.onhand_qty * pr_costledg.curr_cost_amt) + 
				(new_onhand_qty * pr_costledg.curr_cost_amt)) / 
				pr_prodstatus.onhand_qty 
			ELSE 
				LET pr_prodstatus.wgted_cost_amt = 0 
			END IF 
			LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
			UPDATE prodstatus 
			SET seq_num = pr_prodstatus.seq_num , 
			wgted_cost_amt = pr_prodstatus.wgted_cost_amt, 
			onhand_qty = pr_prodstatus.onhand_qty 
			WHERE CURRENT OF ps_cur2 
		END FOREACH 

		# INSERT INTO prodledg
		IF pr_inparms.auto_adjust_flag = "Y" THEN 
			SELECT * INTO pr_inparms.* FROM inparms 
			WHERE cmpy_code = p_cmpy 
			AND parm_code = "1" 
			LET pr_inparms.next_adjust_num = pr_inparms.next_adjust_num + 1 
			UPDATE inparms 
			SET next_adjust_num = pr_inparms.next_adjust_num 
			WHERE cmpy_code = p_cmpy 
			AND parm_code = "1" 
			LET pr_prodledg.source_num = pr_inparms.next_adjust_num 
		END IF 
		LET pr_prodledg.tran_qty = new_onhand_qty - pr_costledg.onhand_qty 
		LET pr_prodledg.cost_amt = pr_costledg.curr_cost_amt 
		LET pr_prodledg.cmpy_code = p_cmpy 
		LET pr_prodledg.part_code = p_part_code 
		LET pr_prodledg.ware_code = p_ware_code 
		LET pr_prodledg.trantype_ind = "A" 
		LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
		LET pr_prodledg.sales_amt = 0 
		LET pr_prodledg.post_flag = "N" 
		LET pr_prodledg.entry_code = p_sign_on_code 
		LET pr_prodledg.entry_date = today 
		IF pr_inparms.hist_flag = "Y" THEN 
			LET pr_prodledg.hist_flag = "N" 
		ELSE 
			LET pr_prodledg.hist_flag = "Y" 
		END IF 
		LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
		LET err_message = "I27b - Itemledg INSERT" 

		INSERT INTO prodledg VALUES (pr_prodledg.*) 

		# UPDATE costledg
		LET err_message = "I27b - costledg UPDATE" 
		UPDATE costledg SET onhand_qty = new_onhand_qty 
		WHERE costledg.cmpy_code = p_cmpy 
		AND costledg.ware_code = p_ware_code 
		AND costledg.part_code = p_part_code 
		AND costledg.tran_date = tran_date 
		AND rowid = p_rowid 

		LET msgresp = kandoomsg("I",7048,pr_prodledg.source_num) 
		#7048 Adjustment VALUE added successfully.

		IF pr_product.serial_flag = "Y" THEN 
			IF pr_prodledg.tran_qty < 0 THEN 
				LET err_message = "I27b - serial_update (del)" 
				LET pr_serialinfo.cmpy_code = pr_prodledg.cmpy_code 
				LET pr_serialinfo.part_code = pr_prodledg.part_code 
				LET pr_serialinfo.ware_code = pr_prodledg.ware_code 
				LET pr_serialinfo.trantype_ind = "X" 
				LET status = serial_update(pr_serialinfo.*, 1, "") 
				IF status <> 0 THEN 
					GOTO recovery 
					EXIT program 
				END IF 
			ELSE 
				LET err_message = "I27b - serial_update " 
				LET pr_serialinfo.cmpy_code = pr_prodledg.cmpy_code 
				LET pr_serialinfo.part_code = pr_prodledg.part_code 
				LET pr_serialinfo.ware_code = pr_prodledg.ware_code 
				LET pr_serialinfo.receipt_date = pr_prodledg.tran_date 
				LET pr_serialinfo.receipt_num = pr_prodledg.seq_num 
				LET pr_serialinfo.vend_code = NULL 
				LET pr_serialinfo.trantype_ind = "0" 
				LET status = serial_update(pr_serialinfo.*, 1, "") 
				IF status <> 0 THEN 
					GOTO recovery 
					EXIT program 
				END IF 
			END IF 
		END IF 
	COMMIT WORK 
	WHENEVER ERROR stop 
	CLOSE WINDOW wi205 
END FUNCTION 
