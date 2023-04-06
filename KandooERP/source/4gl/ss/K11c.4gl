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

	Source code beautified by beautify.pl on 2019-12-31 14:28:27	$Id: $
}



#  K11c.4gl:FUNCTION sub_detail()
#           called by F8 key FROM lineitem_scan
#           form add/edit of subdetl records
#  K11c.4gl:FUNCTION unit_price(pr_ware_code,pr_part_code,pr_level_ind)
#           gets unit_amt (price) details FROM prodstatus according TO
#           customer price level
#  K11c.4gl:FUNCTION unit_tax(pr_ware_code,pr_part_code,pr_unit_amt)
#           calculates unit_tax_amt


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 


FUNCTION sub_detail() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_subdetl RECORD LIKE subdetl.*, 
	ps_subdetl RECORD LIKE subdetl.*, 
	ware_text LIKE warehouse.desc_text, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_part_code LIKE product.part_code, 
	pr_save_level_ind LIKE subdetl.level_code, 
	pr_sub_qty LIKE subdetl.sub_qty, 
	pr_lastkey INTEGER, 
	pr_valid_ind SMALLINT 
	DEFINE l_tmp_text CHAR(500) #huho moved FROM GLOBALS 

	LET ps_subdetl.* = pr_gsubdetl.* 
	LET pr_subdetl.* = pr_gsubdetl.* 
	OPEN WINDOW k135 WITH FORM "K135" 

	LET msgresp = kandoomsg("K",1019,"") 
	#1019 Enter details

	SELECT desc_text INTO ware_text 
	FROM warehouse 
	WHERE ware_code = pr_subdetl.ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = 0 THEN 
		DISPLAY BY NAME ware_text 

	END IF 
	DISPLAY BY NAME pr_subdetl.line_text, 
	pr_subdetl.ware_code, 
	pr_subdetl.sub_qty, 
	pr_subdetl.issue_qty, 
	pr_subdetl.inv_qty, 
	pr_subdetl.level_code, 
	pr_subdetl.unit_amt, 
	pr_subdetl.unit_tax_amt, 
	pr_subdetl.line_total_amt 

	INPUT BY NAME pr_subdetl.part_code, 
	pr_subdetl.line_text, 
	pr_subdetl.ware_code, 
	pr_subdetl.sub_qty, 
	pr_subdetl.level_code, 
	pr_subdetl.unit_amt, 
	pr_subdetl.line_total_amt 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (F8) 
			IF pr_subdetl.part_code IS NOT NULL THEN 
				CALL pinvwind(glob_rec_kandoouser.cmpy_code,pr_subdetl.part_code) 
			END IF 

		ON KEY (control-b) 
			IF infield(part_code) THEN 
				LET l_tmp_text= " type_code = '",pr_subhead.sub_type_code,"' ", 
				" AND (linetype_ind = '2' OR ( part_code in ", 
				"(SELECT part_code FROM subissues ", 
				"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND plan_iss_date between '",pr_subhead.start_date, 
				"' AND '",pr_subhead.end_date,"')))" 
				LET l_tmp_text = show_subproduct(glob_rec_kandoouser.cmpy_code,l_tmp_text) 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				IF l_tmp_text IS NOT NULL THEN 
					LET pr_subdetl.part_code = l_tmp_text 
					NEXT FIELD part_code 
				END IF 
			END IF 
		BEFORE FIELD part_code 
			LET pr_part_code = pr_subdetl.part_code 
		AFTER FIELD part_code 
			LET pr_lastkey = fgl_lastkey() 
			IF pr_part_code IS NOT NULL 
			AND pr_subdetl.part_code <> pr_part_code THEN 
				IF pr_subdetl.issue_qty > 0 
				OR pr_subdetl.inv_qty > 0 THEN 
					LET pr_subdetl.part_code = pr_part_code 
					LET msgresp = kandoomsg("K",9111,"") 
					#9111 Partially shipped
					NEXT FIELD part_code 
				END IF 
			END IF 
			IF pr_part_code IS NULL 
			OR pr_subdetl.part_code != pr_part_code THEN 
				##
				## WHEN part code changed (OR first entered) the price
				## AND description must be reset.
				##
				## any scheduled items must also be deleted FROM old part code
				##
				DELETE FROM t_subschedule 
				WHERE sub_line_num = pr_subdetl.sub_line_num 
				AND (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
				LET pr_part_code = pr_subdetl.part_code 
				LET pr_subdetl.unit_amt = NULL 
				LET pr_subdetl.line_text = NULL 
			END IF 
			LET pr_gsubdetl.* = pr_subdetl.* 
			CALL validate_field(0) 
			RETURNING pr_valid_ind 
			LET pr_subdetl.* = pr_gsubdetl.* 
			CASE 
				WHEN NOT pr_valid_ind 
					NEXT FIELD part_code 
				WHEN pr_lastkey=fgl_keyval("RETURN") 
					OR pr_lastkey=fgl_keyval("right") 
					OR pr_lastkey=fgl_keyval("tab") 
					OR pr_lastkey=fgl_keyval("down") 
					OR pr_lastkey=fgl_keyval("accept") 
					SELECT * INTO pr_product.* 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_subdetl.part_code 
					SELECT * INTO pr_substype.* 
					FROM substype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = pr_subhead.sub_type_code 
					SELECT * INTO pr_subproduct.* 
					FROM subproduct 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_subdetl.part_code 
					AND type_code = pr_subhead.sub_type_code 
					IF pr_subproduct.linetype_ind = "1" THEN 
						LET pr_gsubdetl.* = pr_subdetl.* 
						CALL sched_issue(0) 
						RETURNING pr_valid_ind 
						OPTIONS INSERT KEY f1, 
						DELETE KEY f36 
						IF NOT pr_valid_ind THEN 
							NEXT FIELD part_code 
						END IF 
						CALL validate_field(2) 
						RETURNING pr_valid_ind 
						CALL update_line() 
						LET pr_subdetl.* = pr_gsubdetl.* 
						DISPLAY BY NAME pr_subdetl.line_text, 
						pr_subdetl.ware_code, 
						pr_subdetl.sub_qty, 
						pr_subdetl.issue_qty, 
						pr_subdetl.inv_qty, 
						pr_subdetl.unit_amt, 
						pr_subdetl.unit_tax_amt, 
						pr_subdetl.line_total_amt 

					ELSE 
					IF pr_substype.inv_ind = "2" OR 
					pr_substype.inv_ind = "3" THEN 
						LET msgresp = kandoomsg("K",9112,"") 
						LET pr_subdetl.part_code = pr_part_code 
						NEXT FIELD part_code 
					END IF 
				END IF 
				NEXT FIELD NEXT 
				OTHERWISE 
					NEXT FIELD part_code 
			END CASE 
		BEFORE FIELD line_text 
			CALL update_line() 
		BEFORE FIELD ware_code 
			IF pr_subdetl.inv_qty > 0 OR 
			pr_subdetl.issue_qty > 0 THEN 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("up") OR 
						fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD line_text 
					OTHERWISE 
						NEXT FIELD sub_qty 
				END CASE 
			END IF 
		AFTER FIELD ware_code 
			IF pr_subdetl.ware_code IS NULL THEN 
				LET msgresp = kandoomsg("A",9092,"") 
				NEXT FIELD ware_code 
			END IF 
			SELECT desc_text INTO ware_text 
			FROM warehouse 
			WHERE ware_code = pr_subdetl.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = 0 THEN 
				DISPLAY BY NAME ware_text 

			ELSE 
			LET msgresp = kandoomsg("A",9091,"") 
			NEXT FIELD ware_code 
		END IF 
		BEFORE FIELD sub_qty 
			LET pr_lastkey = fgl_lastkey() 
			LET pr_sub_qty = pr_subdetl.sub_qty 
			IF pr_subproduct.linetype_ind = "1" THEN 
				LET pr_gsubdetl.* = pr_subdetl.* 
				CALL sched_issue(1) 
				RETURNING pr_valid_ind 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				CALL update_line() 
				LET pr_subdetl.* = pr_gsubdetl.* 
				DISPLAY BY NAME pr_subdetl.line_text, 
				pr_subdetl.ware_code, 
				pr_subdetl.sub_qty, 
				pr_subdetl.issue_qty, 
				pr_subdetl.inv_qty, 
				pr_subdetl.level_code, 
				pr_subdetl.unit_amt, 
				pr_subdetl.unit_tax_amt, 
				pr_subdetl.line_total_amt 

				CASE 
					WHEN NOT(pr_valid_ind) 
						NEXT FIELD part_code 
					WHEN pr_lastkey=fgl_keyval("accept") 
						NEXT FIELD line_total_amt 
					WHEN pr_lastkey=fgl_keyval("RETURN") 
						OR pr_lastkey=fgl_keyval("right") 
						OR pr_lastkey=fgl_keyval("tab") 
						OR pr_lastkey=fgl_keyval("down") 
						NEXT FIELD unit_amt 
					WHEN pr_lastkey=fgl_keyval("left") 
						OR pr_lastkey=fgl_keyval("up") 
						NEXT FIELD line_text 
					OTHERWISE 
						NEXT FIELD unit_amt 
				END CASE 
			END IF 

		AFTER FIELD sub_qty 
			LET pr_lastkey = fgl_lastkey() 
			IF pr_subdetl.sub_qty < pr_subdetl.inv_qty 
			OR pr_subdetl.sub_qty < pr_subdetl.issue_qty THEN 
				LET pr_subdetl.sub_qty = pr_sub_qty 
				LET msgresp = kandoomsg("K",9111,"") 
				#9111 Partially shipped
				NEXT FIELD sub_qty 
			END IF 
			LET pr_gsubdetl.* = pr_subdetl.* 
			CALL validate_field(1) 
			RETURNING pr_valid_ind 
			CALL update_line() 
			LET pr_subdetl.* = pr_gsubdetl.* 
			DISPLAY BY NAME pr_subdetl.line_text, 
			pr_subdetl.ware_code, 
			pr_subdetl.sub_qty, 
			pr_subdetl.issue_qty, 
			pr_subdetl.inv_qty, 
			pr_subdetl.level_code, 
			pr_subdetl.unit_amt, 
			pr_subdetl.unit_tax_amt, 
			pr_subdetl.line_total_amt 

			CASE 
				WHEN NOT(pr_valid_ind) 
					NEXT FIELD sub_qty 
				WHEN pr_lastkey=fgl_keyval("accept") 
					NEXT FIELD line_total_amt 
				WHEN pr_lastkey=fgl_keyval("RETURN") 
					OR pr_lastkey=fgl_keyval("right") 
					OR pr_lastkey=fgl_keyval("tab") 
					OR pr_lastkey=fgl_keyval("down") 
					NEXT FIELD NEXT 
				WHEN pr_lastkey=fgl_keyval("left") 
					OR pr_lastkey=fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD sub_qty 
			END CASE 
		BEFORE FIELD level_code 
			IF pr_subdetl.issue_qty > 0 
			OR pr_subdetl.inv_qty > 0 THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
				NEXT FIELD NEXT 
			END IF 
		END IF 
		LET pr_save_level_ind = pr_subdetl.level_code 
		AFTER FIELD level_code 
			IF pr_subdetl.level_code IS NULL THEN 
				LET pr_subdetl.level_code = pr_save_level_ind 
				NEXT FIELD level_code 
			END IF 
			IF pr_subdetl.level_code != pr_save_level_ind THEN 
				LET pr_subdetl.unit_amt = 
				unit_price(pr_subdetl.ware_code, 
				pr_subdetl.part_code, 
				pr_subdetl.level_code) 
				LET pr_gsubdetl.* = pr_subdetl.* 
				CALL validate_field(2) 
				RETURNING pr_valid_ind 
				LET pr_subdetl.* = pr_gsubdetl.* 
				IF pr_valid_ind THEN 
					DISPLAY BY NAME pr_subdetl.line_text, 
					pr_subdetl.ware_code, 
					pr_subdetl.sub_qty, 
					pr_subdetl.issue_qty, 
					pr_subdetl.inv_qty, 
					pr_subdetl.level_code, 
					pr_subdetl.unit_amt, 
					pr_subdetl.unit_tax_amt, 
					pr_subdetl.line_total_amt 

				ELSE 
				NEXT FIELD unit_amt 
			END IF 
		END IF 
		BEFORE FIELD unit_amt 
			IF pr_subdetl.issue_qty > 0 
			OR pr_subdetl.inv_qty > 0 THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
				NEXT FIELD NEXT 
			END IF 
		END IF 
		AFTER FIELD unit_amt 
			LET pr_lastkey = fgl_lastkey() 
			LET pr_gsubdetl.* = pr_subdetl.* 
			CALL validate_field(2) 
			RETURNING pr_valid_ind 
			LET pr_subdetl.* = pr_gsubdetl.* 
			IF pr_valid_ind THEN 
				DISPLAY BY NAME pr_subdetl.line_text, 
				pr_subdetl.ware_code, 
				pr_subdetl.sub_qty, 
				pr_subdetl.issue_qty, 
				pr_subdetl.inv_qty, 
				pr_subdetl.level_code, 
				pr_subdetl.unit_amt, 
				pr_subdetl.unit_tax_amt, 
				pr_subdetl.line_total_amt 

			END IF 
			CASE 
				WHEN NOT(pr_valid_ind) 
					NEXT FIELD unit_amt 
				WHEN pr_lastkey=fgl_keyval("accept") 
					NEXT FIELD line_total_amt 
				WHEN pr_lastkey=fgl_keyval("RETURN") 
					OR pr_lastkey=fgl_keyval("right") 
					OR pr_lastkey=fgl_keyval("tab") 
					OR pr_lastkey=fgl_keyval("down") 
					NEXT FIELD NEXT 
				WHEN pr_lastkey=fgl_keyval("left") 
					OR pr_lastkey=fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD unit_amt 
			END CASE 
		BEFORE FIELD line_total_amt 
			IF pr_arparms.show_tax_flag = "N" THEN 
				LET pr_subdetl.line_total_amt = 
				pr_subdetl.unit_amt * pr_subdetl.sub_qty 
			END IF 
			LET pr_gsubdetl.* = pr_subdetl.* 
			IF fgl_lastkey() != fgl_keyval("accept") THEN 
				IF kandoomsg("E",8006,"") = "N" THEN 
					#8006 Line Entry Complete. (Y/N)?
					NEXT FIELD part_code 
				ELSE 
				EXIT INPUT 
			END IF 
		END IF 
		AFTER INPUT 
			IF NOT int_flag AND NOT quit_flag THEN 
				IF pr_subdetl.part_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD part_code 
				END IF 
				IF pr_subdetl.ware_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD ware_code 
				END IF 
				IF pr_subdetl.sub_qty IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD sub_qty 
				END IF 
				IF pr_subdetl.level_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD level_code 
				END IF 
				IF pr_subdetl.unit_amt IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD unit_amt 
				END IF 
				IF fgl_lastkey() != fgl_keyval("accept") THEN 
					IF kandoomsg("E",8006,"") = "N" THEN 
						#8006 Line Entry Complete. (Y/N)?
						NEXT FIELD part_code 
					END IF 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET pr_gsubdetl.* = ps_subdetl.* 
		CALL update_line() 
		CLOSE WINDOW k135 
		RETURN 
	END IF 
	LET pr_gsubdetl.* = pr_subdetl.* 
	CALL update_line() 
	CLOSE WINDOW k135 
END FUNCTION 

FUNCTION unit_price(pr_ware_code,pr_part_code,pr_level_ind) 
	DEFINE 
	pr_ware_code LIKE prodstatus.ware_code, 
	pr_part_code LIKE prodstatus.part_code, 
	pr_level_ind LIKE customer.inv_level_ind, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_price_amt LIKE prodstatus.list_amt 

	SELECT unit_amt INTO pr_price_amt 
	FROM subcustomer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	AND cust_code = pr_subhead.cust_code 
	AND sub_type_code = pr_subhead.sub_type_code 
	AND ship_code = pr_subhead.ship_code 
	AND comm_date = pr_subhead.start_date 
	AND end_date = pr_subhead.end_date 
	AND unit_amt > 0 
	IF status = notfound THEN 
		SELECT * INTO pr_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_ware_code 
		AND part_code = pr_part_code 
		IF sqlca.sqlcode = notfound THEN 
			LET pr_price_amt = 0 
		ELSE 
		CASE pr_level_ind 
			WHEN "1" LET pr_price_amt = pr_prodstatus.price1_amt 
			WHEN "2" LET pr_price_amt = pr_prodstatus.price2_amt 
			WHEN "3" LET pr_price_amt = pr_prodstatus.price3_amt 
			WHEN "4" LET pr_price_amt = pr_prodstatus.price4_amt 
			WHEN "5" LET pr_price_amt = pr_prodstatus.price5_amt 
			WHEN "6" LET pr_price_amt = pr_prodstatus.price6_amt 
			WHEN "7" LET pr_price_amt = pr_prodstatus.price7_amt 
			WHEN "8" LET pr_price_amt = pr_prodstatus.price8_amt 
			WHEN "9" LET pr_price_amt = pr_prodstatus.price9_amt 
			WHEN "L" LET pr_price_amt = pr_prodstatus.list_amt 
			WHEN "C" LET pr_price_amt = pr_prodstatus.wgted_cost_amt 
			OTHERWISE LET pr_price_amt = pr_prodstatus.list_amt 
		END CASE 
		LET pr_price_amt = pr_price_amt * pr_subhead.conv_qty 
	END IF 
END IF 
RETURN pr_price_amt 
END FUNCTION 


FUNCTION unit_tax(pr_ware_code,pr_part_code,pr_unit_amt) 
	DEFINE 
	pr_ware_code LIKE subdetl.ware_code, 
	pr_part_code LIKE subdetl.part_code, 
	pr_tax RECORD LIKE tax.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_unit_amt LIKE subdetl.unit_amt, 
	pr_unit_tax_amt LIKE subdetl.unit_tax_amt 

	IF pr_unit_amt IS NULL THEN 
		LET pr_unit_amt = 0 
	END IF 
	SELECT * INTO pr_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_subhead.tax_code 
	CASE pr_tax.calc_method_flag 
		WHEN "P" 
			IF pr_part_code IS NULL THEN 
				LET pr_unit_tax_amt = 0 
			ELSE 
			SELECT * INTO pr_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_part_code 
			AND ware_code = pr_ware_code 
			SELECT * INTO pr_tax.* 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = pr_prodstatus.sale_tax_code 
			IF pr_tax.calc_method_flag = "D" THEN 
				LET pr_unit_tax_amt = pr_prodstatus.sale_tax_amt 
			ELSE { use product tax code percentage} 
			IF pr_tax.tax_per IS NULL THEN 
				LET pr_tax.tax_per = 0 
			END IF 
			LET pr_unit_tax_amt = pr_tax.tax_per * pr_unit_amt / 100 
		END IF 
	END IF 
		WHEN "D" {product based tax - tax amount} 
			IF pr_part_code IS NULL THEN 
				LET pr_unit_tax_amt = 0 
			ELSE 
			SELECT * INTO pr_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_part_code 
			AND ware_code = pr_ware_code 
			LET pr_unit_tax_amt = pr_prodstatus.sale_tax_amt 
		END IF 
		WHEN "N" ## % FROM tax TABLE - line based 
			LET pr_unit_tax_amt = pr_tax.tax_per * pr_unit_amt / 100 
		WHEN "T" ## % FROM tax TABLE - inv based 
			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_part_code 
			AND total_tax_flag = "Y" 
			IF sqlca.sqlcode = 0 THEN 
				LET pr_unit_tax_amt = pr_tax.tax_per * pr_unit_amt / 100 
			ELSE 
			LET pr_unit_tax_amt = 0 
		END IF 
		OTHERWISE 
			LET pr_unit_tax_amt = 0 
	END CASE 
	RETURN pr_unit_tax_amt 
END FUNCTION 
