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

DEFINE 
save_idx CHAR(3), 
acount, ins_flag, del_flag, tax_idx SMALLINT, 
pa_shipdetl ARRAY [300] OF RECORD 
	part_code LIKE shipdetl.part_code, 
	ship_inv_qty LIKE shipdetl.ship_inv_qty, 
	desc_text LIKE shipdetl.desc_text, 
	landed_cost LIKE shipdetl.landed_cost, 
	line_total_amt LIKE shipdetl.line_total_amt 
END RECORD, 

sv_shipdetl ARRAY [300] OF RECORD 
	part_code LIKE shipdetl.part_code, 
	ship_inv_qty LIKE shipdetl.ship_inv_qty, 
	desc_text LIKE shipdetl.desc_text, 
	landed_cost LIKE shipdetl.landed_cost, 
	line_total_amt LIKE shipdetl.line_total_amt 
END RECORD, 

new_arr_size, image_flag SMALLINT 



FUNCTION lineitem() 

	OPTIONS DELETE KEY control-s, 
	INSERT KEY control-s 

	OPEN WINDOW wl155 with FORM "L155" 
	CALL windecoration_l("L155") -- albo kd-763 

	DISPLAY BY NAME pr_customer.currency_code attribute(green) 

	IF ans = "Y" THEN 
		DECLARE curser_item CURSOR FOR 
		SELECT shipdetl.* 
		INTO pr_shipdetl.* 
		FROM shipdetl 
		WHERE ship_code = pr_shiphead.ship_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET idx = 0 
		FOREACH curser_item 
			LET idx = idx + 1 
			LET save_idx = idx 
			IF idx > 300 THEN 
				EXIT FOREACH 
			END IF 
			LET pa_shipdetl[idx].part_code = pr_shipdetl.part_code 
			LET pa_shipdetl[idx].ship_inv_qty = pr_shipdetl.ship_inv_qty 
			LET pa_shipdetl[idx].desc_text = pr_shipdetl.desc_text 
			LET pa_shipdetl[idx].landed_cost = pr_shipdetl.landed_cost 
			IF pr_arparms.show_tax_flag = "Y" THEN 
				LET pa_shipdetl[idx].line_total_amt = pr_shipdetl.line_total_amt 
			ELSE 
				LET pa_shipdetl[idx].line_total_amt = pr_shipdetl.landed_cost 
				* pr_shipdetl.ship_inv_qty 
			END IF 

			LET st_shipdetl[idx].* = pr_shipdetl.* 
			LET sv_shipdetl[idx].* = pa_shipdetl[idx].* 

			CALL find_taxcode(pr_shipdetl.tax_code) RETURNING tax_idx 
			LET pa_taxamt[tax_idx].duty_ent_amt = pa_taxamt[tax_idx].duty_ent_amt + 
			pr_shipdetl.duty_ext_ent_amt 

		END FOREACH 


		IF save_idx IS NULL THEN 
			LET save_idx = 0 
		END IF 
		CALL set_count(idx) 
		CALL find_taxcode(pr_shiphead.hand_tax_code) RETURNING tax_idx 
		LET pa_taxamt[tax_idx].duty_ent_amt = pa_taxamt[tax_idx].duty_ent_amt + 
		pr_shiphead.hand_tax_amt 
		CALL find_taxcode(pr_shiphead.freight_tax_code) RETURNING tax_idx 
		LET pa_taxamt[tax_idx].duty_ent_amt = pa_taxamt[tax_idx].duty_ent_amt + 
		pr_shiphead.freight_tax_amt 
	ELSE 
		# this IS the CASE of a RETURN FROM the A51c module via DEL key
		FOR i = 1 TO arr_size 
			LET pa_shipdetl[i].part_code = st_shipdetl[i].part_code 
			LET pa_shipdetl[i].ship_inv_qty = st_shipdetl[i].ship_inv_qty 
			LET pa_shipdetl[i].desc_text = st_shipdetl[i].desc_text 
			LET pa_shipdetl[i].landed_cost = st_shipdetl[i].landed_cost 
			IF pr_arparms.show_tax_flag = "Y" THEN 
				LET pa_shipdetl[i].line_total_amt = st_shipdetl[i].line_total_amt 
			ELSE 
				LET pa_shipdetl[i].line_total_amt = st_shipdetl[i].landed_cost 
				* st_shipdetl[i].ship_inv_qty 
			END IF 

		END FOR 
		CALL set_count(arr_size) 
		LET ans = "Y" 
	END IF 

	DISPLAY pr_shiphead.vend_code, 
	pr_customer.name_text, 
	pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.duty_ent_amt, 
	pr_shiphead.total_amt, 
	pr_shiphead.ware_code, 
	pr_customer.inv_level_ind, 
	pr_shiphead.tax_code, 
	pr_tax.desc_text, 
	pr_customer.cred_bal_amt 
	TO shiphead.vend_code, 
	customer.name_text, 
	shiphead.fob_ent_cost_amt, 
	shiphead.duty_ent_amt, 
	shiphead.total_amt, 
	shiphead.ware_code, 
	inv_level_ind, 
	shiphead.tax_code, 
	tax.desc_text, 
	customer.cred_bal_amt 

	DISPLAY func_type TO func 
	attribute(green) 

	DISPLAY pr_customer.cust_code TO vend_code 

	WHILE true 
		LET image_flag = false 
		CALL input_lines() 
		IF image_flag THEN 
			CALL set_count(new_arr_size) 
			LET arr_size = new_arr_size 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	# has interrupt OR quit been hit
	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		{  -- albo
		         OPEN WINDOW wfA519 AT 10,4
		            with 1 rows, 70 columns
		            attribute (border, reverse)
		         prompt " Do you wish TO hold line information (y/n) "
		            FOR CHAR ans
		         CLOSE WINDOW wfA519
		}
		LET ans = promptYN(""," Do you wish TO hold line information (y/n) ","Y") -- albo 
		LET ans = upshift(ans) 
		LET arr_size = arr_count() 
		IF ans = "Y" 
		THEN 
			LET ans = "C" 
		ELSE 
			LET first_time = 1 
			LET ans = "N" 
			CLOSE WINDOW wl154 
			CLOSE WINDOW wl153 
		END IF 

	END IF 

	CLOSE WINDOW wl155 
	RETURN 
END FUNCTION 


FUNCTION input_lines() 
	DEFINE 
	cat_codecat RECORD LIKE category.*, 
	which CHAR(3), 
	pr_savedetl RECORD LIKE shipdetl.*, 
	scrn1, last_window, scrn, id_flag, j SMALLINT, 
	sav_cust_code LIKE customer.cust_code, 
	pos, start_idx, x SMALLINT, 
	msgresp LIKE language.yes_flag, 
	ext_price, saved_tot money(10,2) 

	LET save_ware = pr_shiphead.ware_code 
	INITIALIZE pr_shipdetl.* TO NULL 
	LET nxtfld = 0 
	LET firstime = 1 
	LET del_flag = 0 
	LET ins_flag = 0 
	MESSAGE "Press ESC TO finish the credit OR arrow TO new line TO add" 
	attribute (yellow) 

	INPUT ARRAY pa_shipdetl WITHOUT DEFAULTS FROM sr_shipdetl.* 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			# SET up ARRAY variables
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET arr_size = arr_count() 
			LET firstime = 1 
			LET last_window = 0 
			LET pr_part_code = pa_shipdetl[idx].part_code 

		ON KEY (control-b) infield (part_code) 
			LET pa_shipdetl[idx].part_code = show_item(glob_rec_kandoouser.cmpy_code) 
			DISPLAY pa_shipdetl[idx].part_code TO sr_shipdetl[scrn].part_code 
			# IF adding the last line AND using a window THEN flag
			LET last_window = 1 
			NEXT FIELD part_code 

		ON KEY (F5) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code, pr_customer.cust_code) --customer details / customer invoice submenu 
			NEXT FIELD part_code 

		ON KEY (F9) 
			CALL inv_image() RETURNING new_arr_size 
			IF new_arr_size > 0 THEN 
				DISPLAY BY NAME pr_shiphead.fob_ent_cost_amt, 
				pr_shiphead.duty_ent_amt 
				#   pr_shiphead.curr_code
				attribute (magenta) 
				LET image_flag = true 
				EXIT INPUT 
			END IF 

		AFTER FIELD part_code 
			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_shipdetl[idx].part_code 
			AND serial_flag = 'Y' 
			IF status <> notfound THEN 
				LET msgresp = kandoomsg("I",9285,'') 
				#9285 Serial Items cannot be used.
				NEXT FIELD part_code 
			END IF 
			LET nxtfld = 0 
			#sorry about this piece, but that's the way it IS with nulls!
			IF pr_part_code = pa_shipdetl[idx].part_code 
			OR (pr_part_code IS NULL AND pa_shipdetl[idx].part_code IS null) THEN 
			ELSE 
				NEXT FIELD ship_inv_qty 
			END IF 

		BEFORE FIELD ship_inv_qty 
			LET pr_part_code = NULL 
			# IF new product THEN initialise the DISPLAY line
			# this "if" IS this way around because of NULL "if" compares
			# ----change it AT your own peril .....

			IF (st_shipdetl[idx].part_code = pa_shipdetl[idx].part_code) OR 
			(st_shipdetl[idx].part_code IS NULL AND 
			pa_shipdetl[idx].part_code IS null) THEN 
				# IF the same product THEN SELECT previous entry....
				LET pr_shipdetl.* = st_shipdetl[idx].* 
				#LET pr_shipdetl.ware_code = save_ware
			ELSE 
				LET pr_shipdetl.part_code = pa_shipdetl[idx].part_code 
				#LET pr_shipdetl.ware_code = save_ware
				LET pr_shipdetl.ship_inv_qty = 0 
				LET pr_shipdetl.desc_text = NULL 
				LET pr_shipdetl.landed_cost = 0 
				LET pr_shipdetl.duty_unit_ent_amt = 0 
				LET pr_shipdetl.ext_landed_cost = 0 
				LET pr_shipdetl.line_total_amt = 0 
			END IF 
			# take off the current line FROM credit totals
			IF firstime = 1 
			THEN 
				CALL minusline() 
				LET firstime = 0 
			END IF 
			# pop up the window AND get the info...
			LET tot_lines = arr_count() 
			LET pr_savedetl.* = pr_shipdetl.* 
			CALL cred_ship_window() 
			RETURNING del_flag 
			# check TO see IF interrupt hit
			# add line back TO header totals (deleted before call)
			IF del_flag THEN 
				LET st_shipdetl[idx].* = pr_savedetl.* 
				LET pr_shipdetl.* = pr_savedetl.* 
				LET pa_shipdetl[idx].part_code = 
				st_shipdetl[idx].part_code 
				DISPLAY pa_shipdetl[idx].part_code TO 
				sr_shipdetl[scrn].part_code 
				LET pr_part_code = pa_shipdetl[idx].part_code 
				CALL plusline() 
				NEXT FIELD part_code 
			END IF 

			# check TO see IF interrupt hit

			IF ans = "N" 
			THEN 
				EXIT INPUT 
			END IF 
			CURRENT WINDOW IS wl155 
			# did we RETURN with a problem
			IF nxtfld = 1 
			THEN 
				LET pa_shipdetl[idx].part_code = NULL 
				DISPLAY pa_shipdetl[idx].part_code TO sr_shipdetl[scrn].part_code 
				NEXT FIELD part_code 
			ELSE 
				LET nxtfld = 0 
				# SET up the stored line

				CALL set_shipdetl() 

				# SET up the SCREEN ARRAY line FROM the window

				LET pa_shipdetl[idx].part_code = st_shipdetl[idx].part_code 
				LET pa_shipdetl[idx].ship_inv_qty = st_shipdetl[idx].ship_inv_qty 
				IF pa_shipdetl[idx].ship_inv_qty = 0 THEN 
					LET pa_shipdetl[idx].ship_inv_qty = NULL 
				END IF 
				LET pa_shipdetl[idx].desc_text = st_shipdetl[idx].desc_text 
				LET pa_shipdetl[idx].landed_cost = st_shipdetl[idx].landed_cost 
				IF pa_shipdetl[idx].landed_cost = 0 THEN 
					LET pa_shipdetl[idx].landed_cost = NULL 
				END IF 
				LET pa_shipdetl[idx].line_total_amt = st_shipdetl[idx].line_total_amt 
				IF pa_shipdetl[idx].line_total_amt = 0 THEN 
					LET pa_shipdetl[idx].line_total_amt = NULL 
				END IF 

				IF pr_arparms.show_tax_flag = "Y" THEN 
					DISPLAY pa_shipdetl[idx].part_code TO sr_shipdetl[scrn].part_code 
					DISPLAY pa_shipdetl[idx].ship_inv_qty TO sr_shipdetl[scrn].ship_inv_qty 
					DISPLAY pa_shipdetl[idx].desc_text TO sr_shipdetl[scrn].desc_text 
					DISPLAY pa_shipdetl[idx].landed_cost TO 
					sr_shipdetl[scrn].landed_cost 
					DISPLAY pa_shipdetl[idx].line_total_amt TO 
					sr_shipdetl[scrn].line_total_amt 
				ELSE 
					LET ext_price = pa_shipdetl[idx].ship_inv_qty * 
					pa_shipdetl[idx].landed_cost 
					DISPLAY pa_shipdetl[idx].part_code TO sr_shipdetl[scrn].part_code 
					DISPLAY pa_shipdetl[idx].ship_inv_qty TO sr_shipdetl[scrn].ship_inv_qty 
					DISPLAY pa_shipdetl[idx].desc_text TO sr_shipdetl[scrn].desc_text 
					DISPLAY pa_shipdetl[idx].landed_cost TO 
					sr_shipdetl[scrn].landed_cost 
					DISPLAY ext_price TO sr_shipdetl[scrn].line_total_amt 
				END IF 
			END IF 
			LET sv_shipdetl[idx].* = pa_shipdetl[idx].* 
			LET ins_flag = 1 

			NEXT FIELD line_total_amt 


		ON KEY (F2) 
			IF st_shipdetl[idx].ship_rec_qty <> 0 THEN 
				ERROR " Unable TO delete line. Goods have been receipted" 
				NEXT FIELD part_code 
			END IF 
			CALL minusline() 

			IF f_type != "E" THEN # edit session 
				# take row out of stored ARRAY - do NOT move acount=arr_count
				# as arr_count can alter without entering a BEFORE ROW-
				LET acount = arr_count() 
				FOR j = idx TO (acount - 1) 
					LET sv_shipdetl[j].* = pa_shipdetl[j+1].* 
					LET st_shipdetl[j].* = st_shipdetl[j+1].* 
					LET pa_shipdetl[j].* = pa_shipdetl[j+1].* 
				END FOR 
				INITIALIZE st_shipdetl[acount].* TO NULL 
				INITIALIZE pa_shipdetl[acount].* TO NULL 
				CALL set_count(acount - 1) 
				LET scrn1 = scrn 
				FOR i = idx TO idx + (7 - scrn) 
					IF pr_arparms.show_tax_flag = "Y" THEN 
						DISPLAY pa_shipdetl[i].part_code TO sr_shipdetl[scrn1].part_code 
						DISPLAY pa_shipdetl[i].ship_inv_qty TO sr_shipdetl[scrn1].ship_inv_qty 
						DISPLAY pa_shipdetl[i].desc_text TO sr_shipdetl[scrn1].desc_text 
						DISPLAY pa_shipdetl[i].landed_cost TO 
						sr_shipdetl[scrn1].landed_cost 
						DISPLAY pa_shipdetl[i].line_total_amt TO 
						sr_shipdetl[scrn1].line_total_amt 
					ELSE 
						LET ext_price = pa_shipdetl[idx].ship_inv_qty * 
						pa_shipdetl[idx].landed_cost 
						DISPLAY pa_shipdetl[i].part_code TO sr_shipdetl[scrn1].part_code 
						DISPLAY pa_shipdetl[i].ship_inv_qty TO sr_shipdetl[scrn1].ship_inv_qty 
						DISPLAY pa_shipdetl[i].desc_text TO sr_shipdetl[scrn1].desc_text 
						DISPLAY pa_shipdetl[i].landed_cost TO 
						sr_shipdetl[scrn1].landed_cost 
						DISPLAY ext_price TO sr_shipdetl[scrn1].line_total_amt 
					END IF 
					LET scrn1 = scrn1 + 1 
				END FOR 
				LET del_flag = 1 
			ELSE 
				LET pa_shipdetl[idx].ship_inv_qty = 0 
				LET st_shipdetl[idx].ship_inv_qty = 0 
				LET st_shipdetl[idx].fob_ext_ent_amt = 0 
				LET st_shipdetl[idx].duty_ext_ent_amt = 0 
				DISPLAY pa_shipdetl[idx].ship_inv_qty TO 
				sr_shipdetl[scrn].ship_inv_qty 
			END IF 
			LET pr_part_code = pa_shipdetl[idx].part_code 

		BEFORE INSERT 

			# add room FOR line in array
			LET acount = arr_count() 
			IF acount = 300 
			THEN 
			ELSE 
				FOR j = acount TO idx step -1 
					LET st_shipdetl[j+1].* = st_shipdetl[j].* 
				END FOR 
				INITIALIZE st_shipdetl[idx].* TO NULL 

			END IF 

			INITIALIZE pr_shipdetl.* TO NULL 


		AFTER ROW 
			# reconcile tax (total tax calculation)
			IF st_shipdetl[idx].part_code != sv_shipdetl[idx].part_code OR 
			st_shipdetl[idx].ship_inv_qty != sv_shipdetl[idx].ship_inv_qty OR 
			st_shipdetl[idx].landed_cost != sv_shipdetl[idx].landed_cost OR 
			st_shipdetl[idx].line_total_amt != sv_shipdetl[idx].line_total_amt 
			THEN 
				IF st_shipdetl[idx].line_total_amt IS NOT NULL THEN 
					IF pr_tax.calc_method_flag = "T" THEN {invoice total tax} 
						LET tot_lines = arr_count() 
						LET start_idx = idx - (scrn - 1) 
						CALL find_taxcode(pr_shipdetl.tax_code) RETURNING tax_idx 
						LET pa_taxamt[tax_idx].duty_ent_amt = pr_shiphead.freight_tax_amt 
						+ pr_shiphead.hand_tax_amt 
						LET pr_shiphead.fob_ent_cost_amt = 0 
						LET pr_shiphead.duty_ent_amt = 0 
						IF pr_shiphead.duty_ent_amt IS NULL THEN 
							LET pr_shiphead.duty_ent_amt = 0 
						END IF 
						LET pr_shiphead.cost_amt = 0 
						LET pr_shiphead.total_amt = 0 
						FOR x = 1 TO tot_lines 
							IF st_shipdetl[x].line_total_amt IS NOT NULL THEN 
								LET saved_tot = st_shipdetl[x].line_total_amt 
								CALL find_tax(pr_shiphead.tax_code, 
								st_shipdetl[x].part_code, 
								pr_shiphead.ware_code, 
								tot_lines, 
								x, 
								st_shipdetl[x].landed_cost, 
								st_shipdetl[x].ship_inv_qty, 
								"S", 
								"", 
								"") 
								RETURNING st_shipdetl[x].ext_landed_cost, 
								st_shipdetl[x].duty_unit_ent_amt, 
								st_shipdetl[x].duty_ext_ent_amt, 
								st_shipdetl[x].line_total_amt, 
								st_shipdetl[x].tax_code 
								CALL plusln(x) 
								IF x = idx THEN 
									IF ins_flag THEN 
										CALL minusline() {gets added later on} 
									END IF 
								END IF 
								IF saved_tot != st_shipdetl[x].line_total_amt THEN 
									IF pr_arparms.show_tax_flag = "Y" THEN 

										# Because the SCREEN ARRAY IS only 7
										# THEN the DISPLAY pos has TO be <= 7
										# OTHERWISE the program falls over.
										IF x >= start_idx 
										AND x <= ( start_idx + 6 ) THEN 
											LET pos = scrn - (idx - x) 
											DISPLAY st_shipdetl[x].line_total_amt TO 
											sr_shipdetl[pos].line_total_amt 
										END IF 
									END IF 
								END IF 
							END IF 
						END FOR 
					END IF 
				END IF 
			END IF 
			# adjust header totals
			IF ins_flag = 1 THEN 
				CALL plusline() 
				LET ins_flag = 0 
			END IF 

			MESSAGE "Press ESC TO finish the credit OR RETURN TO add more lines" 
			attribute (yellow) 

			INITIALIZE pr_shipdetl.* TO NULL 

			#NEXT FIELD part_code


		AFTER INPUT 
			LET arr_size = arr_count() 
			IF int_flag = 0 AND quit_flag = 0 THEN 
				FOR i = 1 TO arr_size 
					SELECT unique 1 FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pa_shipdetl[i].part_code 
					AND serial_flag = 'Y' 
					IF status <> notfound THEN 
						LET msgresp = kandoomsg("I",9293,pa_shipdetl[i].part_code) 
						#9293 Serial Products cannot be used. Remove Pr
						NEXT FIELD part_code 
					END IF 
				END FOR 
			END IF 
			# in CASE window used on last line THEN arr_count IS 1 too low (believe it)
			IF last_window = 1 
			AND idx > arr_size 
			THEN 
				LET arr_size = arr_size + 1 
			END IF 
			# in CASE blank lines AT bottom - lower arr_size value
			IF arr_size > 0 
			THEN 
				WHILE (pa_shipdetl[arr_size].part_code IS NULL 
					AND pa_shipdetl[arr_size].desc_text IS NULL 
					AND (pa_shipdetl[arr_size].line_total_amt = 0 OR 
					pa_shipdetl[arr_size].line_total_amt IS null)) 
					LET arr_size = arr_size - 1 
					IF arr_size = 0 
					THEN 
						EXIT WHILE 
					END IF 
				END WHILE 
				IF save_idx = arr_size THEN 
					LET ins_line = 0 # no change 
				ELSE 
					LET ins_line = 1 # LINES added 
				END IF 
				IF arr_size = 0 THEN 
					LET edit_line = 0 # no line OR all been deleted 
				ELSE 
					LET edit_line = 1 # still LINES 
				END IF 
			END IF 
			IF arr_size = 0 
			THEN 
				IF int_flag = 0 
				THEN 
					ERROR " Shipment should have lines TO continue" 
					SLEEP 2 
					#LET int_flag = 1
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	# has interrupt OR quit been hit
	OPTIONS DELETE KEY control-s, 
	INSERT KEY control-s 
	##IF int_flag != 0
	#OR quit_flag != 0
	#then
	#OPEN WINDOW wfA519 AT 10,4
	#with 1 rows, 70 columns
	#attribute (border, reverse)
	#prompt " Do you wish TO hold line information (y/n) "
	#FOR CHAR ans
	#CLOSE WINDOW wfA519
	#LET ans = upshift(ans)
	#LET arr_size = arr_count()
	#IF ans = "Y"
	#then
	#LET ans = "C"
	#ELSE
	#LET first_time = 1
	#LET ans = "N"
	#CLOSE WINDOW wL154
	#CLOSE WINDOW wL153
	#END IF
	#
	#END IF
	#
	#CLOSE WINDOW wL155
	RETURN 
END FUNCTION 

FUNCTION inv_image() 
	DEFINE 
	where_part, query_text CHAR(600), 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_category RECORD LIKE category.*, 
	pa_invoicehead array[300] OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		ord_num LIKE invoicehead.ord_num 
	END RECORD, 
	inv_idx SMALLINT 

	OPEN WINDOW wl158 at 2,3 with FORM "L158" 
	attribute(border, white, MESSAGE line first) 

	MESSAGE " Enter Invoice Number TO start scan" attribute (yellow) 

	CONSTRUCT BY NAME where_part ON invoicehead.inv_num, 
	invoicehead.inv_date, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.purchase_code, 
	invoicehead.ord_num 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	LET query_text = "SELECT * FROM invoicehead WHERE ", 
	where_part clipped, 
	" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND cust_code = \"",pr_customer.cust_code,"\"" 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		CLOSE WINDOW wl158 
		RETURN false 
	END IF 

	LET inv_idx = 0 
	PREPARE ledger FROM query_text 
	DECLARE c_cust CURSOR FOR ledger 
	FOREACH c_cust INTO pr_invoicehead.* 
		LET inv_idx = inv_idx + 1 
		LET pa_invoicehead[inv_idx].inv_num = pr_invoicehead.inv_num 
		LET pa_invoicehead[inv_idx].inv_date = pr_invoicehead.inv_date 
		LET pa_invoicehead[inv_idx].year_num = pr_invoicehead.year_num 
		LET pa_invoicehead[inv_idx].period_num = pr_invoicehead.period_num 
		LET pa_invoicehead[inv_idx].purchase_code = pr_invoicehead.purchase_code 
		LET pa_invoicehead[inv_idx].ord_num = pr_invoicehead.ord_num 
		IF inv_idx > 290 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count (inv_idx) 

	MESSAGE "" 
	MESSAGE " ESC TO SELECT Invoice" attribute (yellow) 

	INPUT ARRAY pa_invoicehead WITHOUT DEFAULTS FROM sr_invoicehead.* 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET inv_idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_invoicehead.inv_num = pa_invoicehead[inv_idx].inv_num 
			LET pr_invoicehead.inv_date = pa_invoicehead[inv_idx].inv_date 
			LET pr_invoicehead.year_num = pa_invoicehead[inv_idx].year_num 
			LET pr_invoicehead.period_num = pa_invoicehead[inv_idx].period_num 
			LET pr_invoicehead.purchase_code = pa_invoicehead[inv_idx].purchase_code 
			LET pr_invoicehead.ord_num = pa_invoicehead[inv_idx].ord_num 
			LET id_flag = 0 
			IF inv_idx > arr_count() THEN 
				ERROR "There are no more invoices in the direction you are going" 
			END IF 

		BEFORE FIELD inv_date 
			NEXT FIELD inv_num 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		CLOSE WINDOW wl158 
		RETURN false 
	END IF 
	DECLARE c_inv CURSOR FOR 
	SELECT invoicedetl.* FROM invoicedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_invoicehead.inv_num 
	AND cust_code = pr_customer.cust_code 
	LET inv_idx = 0 
	FOREACH c_inv INTO pr_invoicedetl.* 
		LET inv_idx = inv_idx + 1 
		SELECT * INTO pr_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_invoicedetl.part_code 
		LET pr_shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_shipdetl.part_code = pr_invoicedetl.part_code 
		IF pr_shipdetl.part_code IS NOT NULL THEN 
			SELECT sale_acct_code INTO pr_shipdetl.acct_code 
			FROM category 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cat_code = pr_product.cat_code 
		END IF 
		#         LET pr_shipdetl.ship_inv_qty = pr_invoicedetl.ship_qty
		LET pr_shipdetl.desc_text = pr_invoicedetl.line_text 
		LET pr_shipdetl.landed_cost = pr_invoicedetl.unit_sale_amt 
		LET pr_shipdetl.level_code = pr_invoicedetl.level_code 
		LET pr_shipdetl.line_total_amt = 0 
		LET pr_shipdetl.duty_unit_ent_amt = 0 
		LET pr_shipdetl.ext_landed_cost = 0 
		LET pr_shipdetl.ext_landed_cost = 0 
		LET pr_shipdetl.fob_ext_ent_amt = 0 
		LET pr_shipdetl.ship_rec_qty = 0 
		LET pr_shipdetl.fob_unit_ent_amt = pr_invoicedetl.unit_cost_amt 
		LET st_shipdetl[arr_size + inv_idx].* = pr_shipdetl.* 
		LET pa_shipdetl[arr_size + inv_idx].part_code = pr_shipdetl.part_code 
		LET pa_shipdetl[arr_size + inv_idx].ship_inv_qty = pr_shipdetl.ship_inv_qty 
		LET pa_shipdetl[arr_size + inv_idx].desc_text = pr_shipdetl.desc_text 
		LET pa_shipdetl[arr_size + inv_idx].landed_cost = pr_shipdetl.landed_cost 
		LET pr_shipdetl.tax_code = pr_invoicedetl.tax_code 
		LET pr_shipdetl.duty_unit_ent_amt = pr_invoicedetl.unit_tax_amt 
		IF pr_arparms.show_tax_flag = "Y" THEN 
			LET pa_shipdetl[arr_size + inv_idx].line_total_amt = pr_shipdetl.line_total_amt 
		ELSE 
			LET pa_shipdetl[arr_size + inv_idx].line_total_amt = pr_shipdetl.landed_cost 
			* pr_shipdetl.ship_inv_qty 
		END IF 
		LET sv_shipdetl[arr_size + inv_idx].* = pa_shipdetl[arr_size + inv_idx].* 
	END FOREACH 
	CLOSE WINDOW wl158 
	RETURN (arr_size + inv_idx) 
END FUNCTION 
