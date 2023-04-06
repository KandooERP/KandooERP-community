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

	Source code beautified by beautify.pl on 2020-01-02 18:38:33	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L61_GLOBALS.4gl" 


FUNCTION display_price() 
	IF pr_shipdetl.part_code IS NOT NULL THEN 
		CASE (pr_shipdetl.level_code) 
			WHEN "1" LET dec2fix = pr_prodstatus.price1_amt 
			WHEN "2" LET dec2fix = pr_prodstatus.price2_amt 
			WHEN "3" LET dec2fix = pr_prodstatus.price3_amt 
			WHEN "4" LET dec2fix = pr_prodstatus.price4_amt 
			WHEN "5" LET dec2fix = pr_prodstatus.price5_amt 
			WHEN "6" LET dec2fix = pr_prodstatus.price6_amt 
			WHEN "7" LET dec2fix = pr_prodstatus.price7_amt 
			WHEN "8" LET dec2fix = pr_prodstatus.price8_amt 
			WHEN "9" LET dec2fix = pr_prodstatus.price9_amt 
			WHEN "L" LET dec2fix = pr_prodstatus.list_amt 
			WHEN "C" LET dec2fix = pr_prodstatus.wgted_cost_amt 
			OTHERWISE 
				LET dec2fix = pr_prodstatus.list_amt 
		END CASE 
		LET pr_shipdetl.landed_cost = dec2fix * pr_shiphead.conversion_qty 
		DISPLAY BY NAME pr_shipdetl.landed_cost 
	END IF 
END FUNCTION 

FUNCTION plusln(ln_idx) 
	DEFINE 
	ln_idx, 
	tax_idx SMALLINT 

	IF st_shipdetl[ln_idx].ext_landed_cost IS NOT NULL THEN 
		LET pr_shiphead.fob_ent_cost_amt = pr_shiphead.fob_ent_cost_amt + 
		st_shipdetl[ln_idx].ext_landed_cost 
		LET pr_shiphead.total_amt = pr_shiphead.total_amt + 
		st_shipdetl[ln_idx].ext_landed_cost 
	END IF 

	IF st_shipdetl[ln_idx].duty_ext_ent_amt IS NOT NULL THEN 
		CALL find_taxcode(st_shipdetl[ln_idx].tax_code) RETURNING tax_idx 

		IF ln_idx = 1 THEN 
			LET pa_taxamt[tax_idx].duty_ent_amt = 0 
		END IF 

		LET pa_taxamt[tax_idx].duty_ent_amt = pa_taxamt[tax_idx].duty_ent_amt + 
		st_shipdetl[ln_idx].duty_ext_ent_amt 
		CALL total_tax() 
		LET pr_shiphead.total_amt = pr_shiphead.fob_ent_cost_amt + 
		pr_shiphead.hand_amt + 
		pr_shiphead.freight_amt + 
		pr_shiphead.duty_ent_amt 
	END IF 

	IF st_shipdetl[ln_idx].fob_ext_ent_amt IS NOT NULL THEN 
		LET pr_shiphead.cost_amt = pr_shiphead.cost_amt + 
		st_shipdetl[ln_idx].fob_ext_ent_amt 
	END IF 
END FUNCTION 

FUNCTION plusline() 
	DEFINE 
	tax_idx SMALLINT 

	# adjust the invoice header totals
	IF st_shipdetl[idx].ext_landed_cost IS NOT NULL THEN 
		LET pr_shiphead.fob_ent_cost_amt = pr_shiphead.fob_ent_cost_amt + 
		st_shipdetl[idx].ext_landed_cost 
		LET pr_shiphead.total_amt = pr_shiphead.total_amt + 
		st_shipdetl[idx].ext_landed_cost 
	END IF 
	IF st_shipdetl[idx].duty_ext_ent_amt IS NOT NULL THEN 
		CALL find_taxcode(st_shipdetl[idx].tax_code) RETURNING tax_idx 
		LET pa_taxamt[tax_idx].duty_ent_amt = pa_taxamt[tax_idx].duty_ent_amt + 
		st_shipdetl[idx].duty_ext_ent_amt 
		CALL total_tax() 
		LET pr_shiphead.total_amt = pr_shiphead.fob_ent_cost_amt + 
		pr_shiphead.hand_amt + 
		pr_shiphead.freight_amt + 
		pr_shiphead.duty_ent_amt 
	END IF 
	IF st_shipdetl[idx].fob_ext_ent_amt IS NOT NULL THEN 
		LET pr_shiphead.cost_amt = pr_shiphead.cost_amt + 
		st_shipdetl[idx].fob_ext_ent_amt 
	END IF 
	DISPLAY BY NAME pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.duty_ent_amt, 
	pr_shiphead.total_amt attribute (magenta) 
END FUNCTION 

FUNCTION minusline() 
	DEFINE 
	tax_idx SMALLINT 

	# adjust the invoice header totals
	IF st_shipdetl[idx].ext_landed_cost IS NOT NULL THEN 
		LET pr_shiphead.fob_ent_cost_amt = pr_shiphead.fob_ent_cost_amt - 
		st_shipdetl[idx].ext_landed_cost 
		LET pr_shiphead.total_amt = pr_shiphead.total_amt - 
		st_shipdetl[idx].ext_landed_cost 
	END IF 
	IF st_shipdetl[idx].duty_ext_ent_amt IS NOT NULL THEN 
		CALL find_taxcode(st_shipdetl[idx].tax_code) RETURNING tax_idx 
		LET pa_taxamt[tax_idx].duty_ent_amt = pa_taxamt[tax_idx].duty_ent_amt - 
		st_shipdetl[idx].duty_ext_ent_amt 
		CALL total_tax() 
		LET pr_shiphead.total_amt = pr_shiphead.fob_ent_cost_amt + 
		pr_shiphead.hand_amt + 
		pr_shiphead.freight_amt + 
		pr_shiphead.duty_ent_amt 
	END IF 
	IF st_shipdetl[idx].fob_ext_ent_amt IS NOT NULL THEN 
		LET pr_shiphead.cost_amt = pr_shiphead.cost_amt - 
		st_shipdetl[idx].fob_ext_ent_amt 
	END IF 
	DISPLAY BY NAME pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.duty_ent_amt, 
	pr_shiphead.total_amt attribute (magenta) 
END FUNCTION 

FUNCTION stat_res(p_cmpy,warehouse,prod_id,value,which) 
	# a FUNCTION TO handle all warehouse STATUS changes TO be used
	# WHERE ever AND WHEN ever required..

	DEFINE p_cmpy LIKE company.cmpy_code, 
	warehouse CHAR(3), 
	prod_id CHAR(15), 
	value DECIMAL(8,2), 
	which CHAR(3), 
	sequence INTEGER, 
	try_again CHAR(1), 
	err_message CHAR(30) 

	IF prod_id IS NULL OR value = 0 THEN 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		LET err_message = "A51 Itemstat Update" 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" 
		THEN 
			CALL errorlog("A51 Itemstat Adjustment NOT done") 
			EXIT program 
		END IF 
		LABEL bypass: 
		BEGIN WORK 
			WHENEVER ERROR GOTO recovery 
			DECLARE ps_curs CURSOR FOR 
			SELECT * 
			FROM prodstatus 
			WHERE part_code = prod_id 
			AND ware_code = warehouse 
			AND cmpy_code = p_cmpy 
			FOR UPDATE 
			FOREACH ps_curs INTO pr_prodstatus.* 

				LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
				LET sequence = pr_prodstatus.seq_num 
				IF pr_prodstatus.reserved_qty IS NULL 
				THEN LET pr_prodstatus.reserved_qty = 0 
				END IF 
				# do NOT adjust onhnd VALUES FOR non-stocked inventory items
				IF pr_prodstatus.stocked_flag = "Y" 
				THEN 
					IF which = TRAN_TYPE_INVOICE_IN 
					THEN 
						LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty - value 
					ELSE 
						LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty + value 
					END IF 
				END IF 
				UPDATE prodstatus SET reserved_qty = pr_prodstatus.reserved_qty, 
				seq_num = pr_prodstatus.seq_num 
				WHERE CURRENT OF ps_curs 
			END FOREACH 

			# INSERT INTO statab FOR backout purposes
			IF back_out = 0 
			THEN 
				INSERT INTO statab VALUES (p_cmpy, 
				warehouse , 
				prod_id , 
				value , 
				which ) 
			END IF 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 
	RETURN(sequence) 
END FUNCTION 

FUNCTION get_acct() 
	DEFINE 
	pr_coa RECORD LIKE coa.*, 
	pr_tax RECORD LIKE tax.* 

	LET pr_coa.acct_code = pr_shipdetl.acct_code 
	IF pr_shiphead.tax_code IS NOT NULL THEN
	 
		OPEN WINDOW wa104 with FORM "A104"
		CALL winDecoration_a("A104") -- albo kd-763 

		DISPLAY BY NAME pr_coa.acct_code 

		INPUT BY NAME pr_coa.acct_code WITHOUT DEFAULTS 
			BEFORE INPUT
				DISPLAY db_coa_get_desc_text(UI_OFF,pr_coa.acct_code) TO coa.desc_text
				
			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) infield (acct_code) 
						LET pr_coa.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_coa.acct_code 
						NEXT FIELD acct_code 
				
			ON CHANGE acct_code
				DISPLAY db_coa_get_desc_text(UI_OFF,pr_coa.acct_code) TO coa.desc_text	
							
			AFTER FIELD acct_code 
				IF pr_coa.acct_code IS NULL THEN 
					ERROR " Account Number IS required" 
					NEXT FIELD acct_code 
				END IF 
				
			AFTER INPUT 


				IF int_flag OR quit_flag THEN 
					LET int_flag = 0 
					LET quit_flag = 0 
					LET del_yes = "Y" 
					EXIT INPUT 
				END IF 

				#account code verification
				CALL verify_acct_code(glob_rec_kandoouser.cmpy_code,pr_coa.acct_code, 
				pr_shiphead.year_num, 
				pr_shiphead.period_num) 
				RETURNING pr_coa.* 



				IF pr_coa.acct_code IS NULL THEN 
					ERROR " Account Number IS required " 
					NEXT FIELD acct_code 
				END IF 

				LET del_yes = "N" 

--			ON KEY (control-w) 
--				CALL kandoohelp("") 
		END INPUT 
		CLOSE WINDOW wa104 

		LET pr_shipdetl.acct_code = pr_coa.acct_code 
		RETURN del_yes 

	ELSE 
		OPEN WINDOW wa208 with FORM "A208" 
		CALL winDecoration_a("A208") -- albo kd-763 
		DISPLAY BY NAME pr_coa.acct_code, 
		pr_shipdetl.tax_code 
		INPUT BY NAME pr_coa.acct_code, 
		pr_shipdetl.tax_code WITHOUT DEFAULTS 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield (acct_code) 
						LET pr_coa.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_coa.acct_code 
						NEXT FIELD acct_code 
					WHEN infield (tax_code) 
						LET pr_shipdetl.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_shipdetl.tax_code 
						NEXT FIELD tax_code 
				END CASE 
			AFTER FIELD acct_code 
				IF pr_coa.acct_code IS NULL THEN 
					ERROR " Account Number IS required, try window" 
					NEXT FIELD acct_code 
				END IF 
				CALL verify_acct_code(glob_rec_kandoouser.cmpy_code,pr_coa.acct_code, 
				pr_shiphead.year_num, 
				pr_shiphead.period_num) 
				RETURNING pr_coa.* 

			AFTER FIELD tax_code 
				IF pr_shipdetl.tax_code IS NULL AND 
				pr_arparms.inven_tax_flag = "3" THEN 
					ERROR " Tax Code IS required, try window" 
					NEXT FIELD tax_code 
				END IF 
			AFTER INPUT 
				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_coa.acct_code 
				IF status = notfound THEN 
					ERROR " Account NOT found" 
					NEXT FIELD acct_code 
				END IF 
				IF pr_shipdetl.tax_code IS NOT NULL THEN 
					SELECT * 
					INTO pr_tax.* 
					FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = pr_shipdetl.tax_code 
					IF status = notfound THEN 
						ERROR " Tax code NOT found" 
						NEXT FIELD tax_code 
					END IF 
				END IF 
--			ON KEY (control-w) 
--				CALL kandoohelp("") 
		END INPUT
		 
		CLOSE WINDOW wa208 
	END IF 
	
	LET pr_shipdetl.acct_code = pr_coa.acct_code 

	LET del_yes = "N" 
	RETURN del_yes 

END FUNCTION 
