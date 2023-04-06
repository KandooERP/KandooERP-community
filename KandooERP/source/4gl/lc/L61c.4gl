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

	Source code beautified by beautify.pl on 2020-01-02 18:38:32	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L61_GLOBALS.4gl" 


FUNCTION cred_ship_window() 
	DEFINE which CHAR(3), 
	unit_tax money(16,4), 
	save_ware LIKE shiphead.ware_code, 
	save_level LIKE shipdetl.level_code, 
	x, 
	line_num, 
	num_lines SMALLINT, 
	pr_savedetl RECORD LIKE shipdetl.*, 
	del_flag SMALLINT 

	OPEN WINDOW wl157 with FORM "L157" 
	CALL windecoration_l("L157") -- albo kd-763 

	LET pr_savedetl.* = st_shipdetl[idx].* 
	IF pr_arparms.show_tax_flag = "Y" THEN 
		DISPLAY BY NAME pr_shipdetl.part_code, 
		pr_shipdetl.ship_inv_qty, 
		pr_shipdetl.desc_text, 
		pr_shiphead.ware_code, 
		pr_shipdetl.level_code, 
		pr_shipdetl.landed_cost, 
		pr_shipdetl.duty_unit_ent_amt, 
		pr_shipdetl.line_total_amt 

	ELSE 
		DISPLAY BY NAME pr_shipdetl.part_code, 
		pr_shipdetl.ship_inv_qty, 
		pr_shipdetl.desc_text, 
		pr_shiphead.ware_code, 
		pr_shipdetl.level_code, 
		pr_shipdetl.landed_cost 

	END IF 
	DISPLAY pr_shiphead.ware_code TO st_ware 
	attribute(yellow) 
	INPUT BY NAME pr_shipdetl.part_code, 
	pr_shipdetl.ship_inv_qty, 
	pr_shipdetl.desc_text, 
	pr_shipdetl.level_code, 
	pr_shipdetl.landed_cost 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET pr_shipdetl.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipdetl.part_code 

					NEXT FIELD part_code 
			END CASE 
			
		ON ACTION "NOTES" infield (desc_text) --	ON KEY (control-n) 
				# We need the correct DELETE KEY in notes
				OPTIONS DELETE KEY f2, 
				INSERT KEY f1 
				LET pr_shipdetl.desc_text = 
				sys_noter(glob_rec_kandoouser.cmpy_code, pr_shipdetl.desc_text) 
				WHENEVER ERROR CONTINUE 
				OPTIONS DELETE KEY control-s, 
				INSERT KEY control-s 
				WHENEVER ERROR stop 
				DISPLAY pr_shipdetl.desc_text 
				TO shipdetl.desc_text 

				NEXT FIELD level_code 

			# product id has already been entered so carry on.....
		BEFORE FIELD part_code 
			IF pr_shipdetl.part_code IS NOT NULL THEN 
				SELECT * 
				INTO pr_product.* 
				FROM product 
				WHERE product.part_code = pr_shipdetl.part_code 
				AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					ERROR "Product NOT found, try again" 
					SLEEP 4 
					LET nxtfld = 1 
					LET pr_part_code = NULL 
					EXIT INPUT 
				END IF 
				IF (st_shipdetl[idx].part_code != pr_shipdetl.part_code 
				OR (st_shipdetl[idx].part_code IS NULL AND 
				pr_shipdetl.part_code IS NOT null)) THEN 
					LET pr_shipdetl.desc_text = pr_product.desc_text 
					LET pr_shipdetl.level_code = pr_customer.inv_level_ind 
				END IF 
				LET save_level = pr_shipdetl.level_code 
				IF pr_arparms.show_tax_flag = "Y" THEN 
					DISPLAY BY NAME pr_shipdetl.part_code, 
					pr_shipdetl.desc_text, 
					pr_shipdetl.ship_inv_qty, 
					pr_shipdetl.level_code, 
					pr_shipdetl.landed_cost, 
					pr_shipdetl.duty_unit_ent_amt, 
					pr_shipdetl.level_code 
				ELSE 
					DISPLAY BY NAME pr_shipdetl.part_code, 
					pr_shipdetl.desc_text, 
					pr_shipdetl.ship_inv_qty, 
					pr_shipdetl.level_code, 
					pr_shipdetl.landed_cost, 
					pr_shipdetl.level_code 
				END IF 

				SELECT category.* 
				INTO cat_codecat.* 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = pr_product.cat_code 
				IF (status = notfound) THEN 
					ERROR "Product Category FOR item NOT found" SLEEP 4 
					LET nxtfld = 1 
					EXIT INPUT 
				END IF 
				CALL display_ware() 
				IF nxtfld = 1 THEN 
					SLEEP 4 
					EXIT INPUT 
				END IF 
				IF st_shipdetl[idx].landed_cost IS NULL THEN 
					CALL display_price() 
				END IF 
				CALL find_tax(pr_shiphead.tax_code, 
				pr_shipdetl.part_code, 
				pr_shiphead.ware_code, 
				num_lines, 
				line_num, 
				pr_shipdetl.landed_cost, 
				pr_shipdetl.ship_inv_qty, 
				"S", 
				"", 
				"") RETURNING pr_shipdetl.ext_landed_cost, 
				pr_shipdetl.duty_unit_ent_amt, 
				pr_shipdetl.duty_ext_ent_amt, 
				pr_shipdetl.line_total_amt, 
				pr_shipdetl.tax_code 

				IF pr_arparms.show_tax_flag = "Y" THEN 
					DISPLAY BY NAME pr_shipdetl.duty_unit_ent_amt, 
					pr_shipdetl.line_total_amt 
				ELSE 
					DISPLAY pr_shipdetl.ext_landed_cost TO line_total_amt 

				END IF 

				IF nxtfld = 1 THEN 
					SLEEP 4 
					EXIT INPUT 
				END IF 
				LET nxtfld = 0 
				NEXT FIELD ship_inv_qty 
			END IF 
		AFTER FIELD ship_inv_qty 
			IF pr_shipdetl.ship_inv_qty IS NULL THEN 
				LET pr_shipdetl.ship_inv_qty = 0 
			END IF 
			IF pr_shipdetl.ship_inv_qty <= 0 THEN 
				ERROR "Quantity should be greater than zero" 
				NEXT FIELD ship_inv_qty 
			END IF 
			IF pr_shipdetl.ship_inv_qty < pr_shipdetl.ship_rec_qty THEN 
				ERROR "Quantity should be greater than Receipt quantity" 
				LET pr_shipdetl.ship_inv_qty = pr_savedetl.ship_inv_qty 
				DISPLAY BY NAME pr_shipdetl.ship_inv_qty 
				NEXT FIELD ship_inv_qty 
			END IF 
			CALL display_ware() 
			IF pr_shipdetl.duty_unit_ent_amt IS NULL THEN LET pr_shipdetl.duty_unit_ent_amt = 0 END IF 
				LET dec2fix = pr_shipdetl.landed_cost 
				IF pr_arparms.show_tax_flag = "Y" THEN 
					LET pr_shipdetl.line_total_amt = (dec2fix + unit_tax) * 
					pr_shipdetl.ship_inv_qty 

				ELSE 
					LET pr_shipdetl.line_total_amt = pr_shipdetl.landed_cost 
					* pr_shipdetl.ship_inv_qty 
				END IF 

				DISPLAY BY NAME pr_shipdetl.line_total_amt 
				LET save_ware = pr_shiphead.ware_code 
		AFTER FIELD level_code 
			IF pr_shipdetl.level_code != save_level THEN 
				CALL display_price() 
				CALL find_tax(pr_shiphead.tax_code, 
				pr_shipdetl.part_code, 
				pr_shiphead.ware_code, 
				num_lines, 
				line_num, 
				pr_shipdetl.landed_cost, 
				pr_shipdetl.ship_inv_qty, 
				"S", 
				"", 
				"") RETURNING pr_shipdetl.ext_landed_cost, 
				pr_shipdetl.duty_unit_ent_amt, 
				pr_shipdetl.duty_ext_ent_amt, 
				pr_shipdetl.line_total_amt, 
				pr_shipdetl.tax_code 

				IF pr_arparms.show_tax_flag = "Y" THEN 
					DISPLAY BY NAME pr_shipdetl.duty_unit_ent_amt, 
					pr_shipdetl.line_total_amt 
				ELSE 
					DISPLAY pr_shipdetl.ext_landed_cost TO line_total_amt 

				END IF 

				LET save_level = pr_shipdetl.level_code 
			END IF 
		AFTER FIELD landed_cost 
			# in CASE of charge a non stocked product get GL info
			IF pr_shipdetl.landed_cost <> 0 AND pr_shipdetl.part_code IS NULL THEN 
				CALL get_acct() RETURNING del_yes 
			END IF 
			CALL find_tax(pr_shiphead.tax_code, 
			pr_shipdetl.part_code, 
			pr_shiphead.ware_code, 
			num_lines, 
			line_num, 
			pr_shipdetl.landed_cost, 
			pr_shipdetl.ship_inv_qty, 
			"S", 
			"", 
			"") RETURNING pr_shipdetl.ext_landed_cost, 
			pr_shipdetl.duty_unit_ent_amt, 
			pr_shipdetl.duty_ext_ent_amt, 
			pr_shipdetl.line_total_amt, 
			pr_shipdetl.tax_code 

			IF pr_arparms.show_tax_flag = "Y" THEN 
				DISPLAY BY NAME pr_shipdetl.duty_unit_ent_amt, 
				pr_shipdetl.line_total_amt 
			ELSE 
				DISPLAY pr_shipdetl.ext_landed_cost TO line_total_amt 

			END IF 

		AFTER INPUT 
			CALL find_tax(pr_shiphead.tax_code, 
			pr_shipdetl.part_code, 
			pr_shiphead.ware_code, 
			num_lines, 
			line_num, 
			pr_shipdetl.landed_cost, 
			pr_shipdetl.ship_inv_qty, 
			"S", 
			"", 
			"") RETURNING pr_shipdetl.ext_landed_cost, 
			pr_shipdetl.duty_unit_ent_amt, 
			pr_shipdetl.duty_ext_ent_amt, 
			pr_shipdetl.line_total_amt, 
			pr_shipdetl.tax_code 

			IF pr_arparms.show_tax_flag = "Y" THEN 
				DISPLAY BY NAME pr_shipdetl.duty_unit_ent_amt, 
				pr_shipdetl.line_total_amt 
			ELSE 
				DISPLAY pr_shipdetl.ext_landed_cost TO line_total_amt 

			END IF 

			DISPLAY BY NAME pr_shipdetl.landed_cost 
			# work out the extended tax AND prices
			# IF changing line THEN place old stock back
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW wl157 

	IF del_yes = "Y" THEN 
		#    LET st_shipdetl[idx].* = pr_savedetl.*
		#    LET pr_shipdetl.* = pr_savedetl.*
		LET del_flag = true 
		LET del_yes = "N" 
		RETURN (del_flag) 
	END IF 

	# has interrupt OR quit been hit
	IF int_flag OR quit_flag THEN 
		LET del_flag = true 
		LET int_flag = 0 
		LET quit_flag = 0 
	ELSE 
		LET del_flag = false 
	END IF 
	RETURN (del_flag) 
END FUNCTION 


FUNCTION set_shipdetl() 
	# SET up the invoice line
	LET pr_shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_shipdetl.landed_cost IS NULL THEN 
		LET pr_shipdetl.landed_cost = 0 
	END IF 
	# serilaisation should be handled AT goods receipt time
	IF pr_shipdetl.fob_unit_ent_amt IS NULL 
	OR pr_shipdetl.fob_unit_ent_amt = 0 THEN 
		LET pr_shipdetl.fob_unit_ent_amt = pr_prodstatus.wgted_cost_amt * 
		pr_shiphead.conversion_qty 
	END IF 
	IF pr_shipdetl.fob_unit_ent_amt IS NULL THEN LET pr_shipdetl.fob_unit_ent_amt = 0 END IF 
		IF pr_shipdetl.ship_inv_qty IS NULL THEN LET pr_shipdetl.ship_inv_qty = 0 END IF 
			LET pr_shipdetl.fob_ext_ent_amt = pr_shipdetl.fob_unit_ent_amt * 
			pr_shipdetl.ship_inv_qty 
			IF pr_shipdetl.fob_ext_ent_amt IS NULL THEN LET pr_shipdetl.fob_ext_ent_amt = 0 END IF 
				IF pr_shipdetl.ext_landed_cost IS NULL THEN LET pr_shipdetl.ext_landed_cost = 0 END IF 
					IF pr_shipdetl.acct_code IS NULL THEN 
						LET pr_shipdetl.acct_code = cat_codecat.sale_acct_code 
					END IF 
					IF pr_shipdetl.duty_ext_ent_amt IS NULL THEN LET pr_shipdetl.duty_ext_ent_amt = 0 END IF 
						IF pr_shiphead.duty_inv_amt IS NULL THEN LET pr_shiphead.duty_inv_amt = 0 END IF 
							IF pr_shipdetl.ship_rec_qty IS NULL THEN 
								LET pr_shipdetl.ship_rec_qty = 0 
							END IF 
							#
							# SET up shipdetl store array
							#
							LET st_shipdetl[idx].* = pr_shipdetl.* 
							RETURN 
END FUNCTION 


FUNCTION display_ware() 
	##
	## displays warehouse stocking & extension of line in L157..
	##
	IF pr_shipdetl.part_code IS NOT NULL THEN 
		SELECT * 
		INTO pr_prodstatus.* 
		FROM prodstatus WHERE part_code = pr_shipdetl.part_code 
		AND ware_code = pr_shiphead.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF (status = notfound) 
		THEN 
			ERROR "Product NOT AT warehouse" 
			LET nxtfld = 1 
			RETURN 
		END IF 
	END IF 


END FUNCTION 
