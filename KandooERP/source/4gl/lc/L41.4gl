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

	Source code beautified by beautify.pl on 2020-01-02 18:38:30	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L41 allows the user TO Scan Vendor Shipments TO SELECT the
# shipment TO enter receipts against
# This program handles receipts by Quantity
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pt_shiphead RECORD LIKE shiphead.*, 
	pr_smparms RECORD LIKE smparms.*, 
	pa_shiphead array[250] OF RECORD 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		vend_code LIKE shiphead.vend_code, 
		part_code LIKE shipdetl.part_code, 
		source_doc_num LIKE shipdetl.source_doc_num, 
		discharge_text LIKE shiphead.discharge_text, 
		ship_status_code LIKE shiphead.ship_status_code 
	END RECORD, 
	pa_shipdetl ARRAY [310] OF RECORD 
		rec_qty LIKE shipdetl.ship_rec_qty, 
		ship_rec_qty LIKE shipdetl.ship_rec_qty, 
		part_code LIKE shipdetl.part_code, 
		source_doc_num LIKE shipdetl.source_doc_num, 
		doc_line_num LIKE shipdetl.doc_line_num, 
		bin_text LIKE prodstatus.bin1_text 
	END RECORD, 
	pa_desc_text ARRAY [310] OF RECORD 
		desc_text CHAR(30) 
	END RECORD, 
	idx, i, id_flag, cnt, err_flag SMALLINT, 
	sel_text, where_part CHAR(1500), 
	func_type CHAR(14), 
	new_status_code LIKE shiphead.ship_status_code, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	try_again CHAR(1), 
	err_message CHAR(40), 
	init_size SMALLINT, 
	ans CHAR(1) 

END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("L41") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	LET ans = "Y" 
	WHILE ans = "Y" 
		CALL select_receipt() 
		CLOSE WINDOW wl107 
	END WHILE 
END MAIN 

FUNCTION select_receipt() 

	DEFINE receipt_text LIKE shiphead.goods_receipt_text 

	OPEN WINDOW wl107 with FORM "L107" 
	CALL windecoration_l("L107") -- albo kd-761 

	MESSAGE " Enter selection criteria AND press ESC TO begin search" 
	attribute (yellow) 

	CONSTRUCT BY NAME where_part ON 
	shiphead.ship_code, 
	shiphead.ship_type_code, 
	shiphead.vend_code, 
	shipdetl.part_code, 
	shipdetl.source_doc_num, 
	shiphead.discharge_text, 
	shiphead.ship_status_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","L41","construct-shiphead-1") 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	LET sel_text = 
	"SELECT * ", 
	"FROM shiphead, shipdetl ", 
	" WHERE shiphead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND shipdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND shipdetl.ship_code = shiphead.ship_code ", 
	" AND shiphead.ship_type_ind = 1 ", 
	" AND shiphead.finalised_flag != 'Y' AND ", 
	where_part clipped, 
	" ORDER BY shiphead.cmpy_code, shiphead.ship_code " 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		EXIT program 
	END IF 
	PREPARE getord FROM sel_text 
	DECLARE c_ord CURSOR FOR getord 

	LET idx = 0 
	FOREACH c_ord INTO pr_shiphead.*, pr_shipdetl.* 

		LET idx = idx + 1 
		LET pa_shiphead[idx].ship_code = pr_shiphead.ship_code 
		LET pa_shiphead[idx].vend_code = pr_shiphead.vend_code 
		LET pa_shiphead[idx].ship_type_code = pr_shiphead.ship_type_code 
		IF pr_shipdetl.part_code IS NULL THEN 
			LET pa_shiphead[idx].part_code = pr_shipdetl.desc_text[1,15] 
		ELSE 
			LET pa_shiphead[idx].part_code = pr_shipdetl.part_code 
		END IF 
		LET pa_shiphead[idx].source_doc_num = pr_shipdetl.source_doc_num 
		LET pa_shiphead[idx].discharge_text = pr_shiphead.discharge_text 
		LET pa_shiphead[idx].ship_status_code = pr_shiphead.ship_status_code 
		IF idx > 240 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF idx > 0 THEN 
		CALL set_count (idx) 

		MESSAGE "" 
		MESSAGE " Cursor TO shipment AND press RETURN TO enter goods receipt" 
		attribute (yellow) 

		INPUT ARRAY pa_shiphead WITHOUT DEFAULTS FROM sr_shiphead.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","L41","input-arr-pa_shiphead-1") -- albo 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				#LET scrn = scr_line()
				LET pr_shiphead.ship_code = pa_shiphead[idx].ship_code 
				LET pr_shiphead.vend_code = pa_shiphead[idx].vend_code 
				LET pr_shiphead.ship_type_code = pa_shiphead[idx].ship_type_code 
				LET pr_shipdetl.part_code = pa_shiphead[idx].part_code 
				LET pr_shipdetl.source_doc_num = pa_shiphead[idx].source_doc_num 
				LET pr_shiphead.discharge_text = pa_shiphead[idx].discharge_text 
				LET pr_shiphead.ship_status_code = pa_shiphead[idx].ship_status_code 
				LET id_flag = 0 
				IF idx > arr_count() THEN 
					ERROR "There are no further Shipments in the direction you are going" 
				END IF 

			BEFORE FIELD ship_type_code 
				IF pr_shiphead.ship_code IS NULL THEN 
					ERROR " Not a valid shipment" 
				ELSE 
					CALL ship_receipt(pr_shiphead.ship_code, pr_shiphead.vend_code) 
					RETURNING new_status_code, 
					receipt_text 
					CURRENT WINDOW IS wl107 
					IF receipt_text != "0" THEN 
						MESSAGE "" 
						MESSAGE " Successfull addition of receipt ", receipt_text clipped 
						attribute (yellow) 
					ELSE 
						MESSAGE "" 
						MESSAGE " Cursor TO shipment AND press RETURN TO enter goods receipt" 
						attribute (yellow) 
					END IF 
					LET pa_shiphead[idx].ship_status_code = new_status_code 
					#DISPLAY pa_shiphead[idx].ship_status_code
					#   TO sr_shiphead[scrn].ship_status_code
					NEXT FIELD ship_code 
				END IF 
				NEXT FIELD ship_code 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	ELSE 
		ERROR "There are no Shipments matching the selection criteria" 
		SLEEP 3 
	END IF 
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET ans = "Y" 
	END IF 
	LET int_flag = 0 
	LET quit_flag = 0 


END FUNCTION 


FUNCTION add_receipts(pr_ship_code, pr_part_code, pr_line_num, pr_ship_rec_qty, pr_trans_rec_qty, pr_receipt_text, pr_recpt_date) 

	DEFINE 
	pr_ship_code LIKE shiphead.ship_code, 
	pr_part_code LIKE shipdetl.part_code, 
	pr_line_num SMALLINT, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_ship_rec_qty LIKE shipdetl.ship_rec_qty, 
	pr_trans_rec_qty LIKE shipdetl.ship_rec_qty, 
	pr_receipt_text LIKE shiphead.goods_receipt_text, 
	pr_recpt_date LIKE shiprec.recpt_date, 
	pr_shiprec RECORD LIKE shiprec.*, 
	i, counter, cnt, idx SMALLINT, 
	row_id INTEGER 

	#GOTO bypass
	#label recovery:
	#LET try_again = error_recover(err_message,STATUS)
	#IF try_again != "Y" THEN
	#EXIT PROGRAM
	#END IF
	#label bypass:
	#WHENEVER ERROR GOTO recovery

	LET err_message = "L41 - shipdetl UPDATE" 
	UPDATE shipdetl 
	SET ship_rec_qty = 
	pr_ship_rec_qty 
	WHERE shipdetl.ship_code = pr_ship_code 
	AND shipdetl.line_num = pr_line_num 
	#AND shipdetl.part_code = pr_part_code
	AND shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET pr_shiprec.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_shiprec.ship_code = pr_ship_code 
	LET pr_shiprec.line_num = pr_line_num 
	LET pr_shiprec.goods_receipt_text = pr_receipt_text 
	LET pr_shiprec.trans_qty = pr_trans_rec_qty 
	LET pr_shiprec.total_qty = pr_ship_rec_qty 
	LET pr_shiprec.recpt_date = pr_recpt_date 
	LET pr_shiprec.entry_date = today 
	LET pr_shiprec.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_shiprec.trans_amt = 0 
	LET pr_shiprec.total_amt = 0 
	LET pr_shiprec.rec_type_ind = 1 
	INSERT INTO shiprec VALUES (pr_shiprec.*) 
	IF pr_shiphead.ship_type_ind = 1 THEN 
		# this IS an import
		SELECT * INTO pr_shipdetl.* 
		FROM shipdetl 
		WHERE shipdetl.ship_code = pr_ship_code 
		AND shipdetl.line_num = pr_line_num 
		#AND shipdetl.part_code = pr_part_code
		AND shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		#     IF pr_part_code IS NOT NULL THEN
		#        CALL calc_prices(glob_rec_kandoouser.cmpy_code, pr_shipdetl.*,pr_recpt_date)
		#     END IF
		IF pr_shipdetl.source_doc_num IS NOT NULL 
		AND pr_shipdetl.source_doc_num != 0 
		AND pr_shipdetl.doc_line_num IS NOT NULL 
		AND pr_shipdetl.doc_line_num != 0 THEN 
			# INSERT poaudit
			SELECT * 
			INTO pr_purchdetl.* 
			FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_shipdetl.source_doc_num 
			AND line_num = pr_shipdetl.doc_line_num 
			IF status = notfound THEN ELSE 
				LET pr_poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_poaudit.vend_code = pr_shiphead.vend_code 
				LET pr_poaudit.po_num = pr_shipdetl.source_doc_num 
				LET pr_poaudit.line_num = pr_shipdetl.doc_line_num 
				LET pr_poaudit.tran_code = "GR" 
				LET pr_poaudit.order_qty = 0 
				LET pr_poaudit.voucher_qty = 0 
				LET pr_poaudit.posted_flag = "Y" # this IS SET because 
				# we dont want po postings
				# lc will handle this
				LET pr_poaudit.orig_auth_flag = "Y" 
				LET pr_poaudit.now_auth_flag = "Y" 
				LET pr_poaudit.received_qty = pr_trans_rec_qty 
				LET pr_poaudit.unit_cost_amt = pr_shipdetl.fob_unit_ent_amt 
				LET pr_poaudit.unit_tax_amt = 0 
				LET pr_poaudit.desc_text = "Ship#", pr_shiphead.ship_code clipped, 
				" ",pr_purchdetl.ref_text 
				LET pr_poaudit.ext_cost_amt = pr_poaudit.unit_cost_amt 
				* pr_poaudit.received_qty 
				LET pr_poaudit.ext_tax_amt = pr_poaudit.unit_tax_amt 
				* pr_poaudit.received_qty 
				LET pr_poaudit.line_total_amt = pr_poaudit.ext_tax_amt 
				+ pr_poaudit.ext_cost_amt 
				LET pr_poaudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_poaudit.entry_date = today 
				LET pr_poaudit.tran_num = pr_smparms.next_recpt_num 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_recpt_date) 
				RETURNING pr_poaudit.year_num, pr_poaudit.period_num 
				LET pr_poaudit.tran_date = pr_recpt_date 
				LET pr_poaudit.jour_num = 0 
				# up the sequence number in purchdetl
				DECLARE seq_curs CURSOR FOR 
				SELECT rowid, seq_num 
				INTO row_id, pr_poaudit.seq_num 
				FROM purchdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_poaudit.po_num 
				AND line_num = pr_poaudit.line_num 
				FOR UPDATE 
				FOREACH seq_curs # their should only be 1 
					LET pr_poaudit.seq_num = pr_poaudit.seq_num + 1 
					UPDATE purchdetl 
					SET seq_num = pr_poaudit.seq_num 
					WHERE rowid = row_id 
				END FOREACH 
				#  now add the line
				INSERT INTO poaudit VALUES (pr_poaudit.*) 
			END IF 
		END IF 
	END IF 

END FUNCTION 

#FUNCTION calc_prices(p_cmpy, pr_shipdetl,pr_recpt_date)
#DEFINE
#  p_cmpy LIKE company.cmpy_code,
#  pr_shipdetl RECORD LIKE shipdetl.*,
#  pr_recpt_date DATE,
#  pr_product RECORD LIKE product.*,
#  pr_category RECORD LIKE category.*,
#  pr_tariff RECORD LIKE tariff.*,
#  pr_prodstatus RECORD LIKE prodstatus.*,
#  converted_fob LIKE shipdetl.fob_unit_ent_amt,
#  std_cost, cost_fact_amt, duty, cost money(15,4),
#  duty_rate LIKE tariff.duty_per,
#  duty_found CHAR(1),
#  list_price LIKE prodstatus.list_amt
#
#           LET cost = pr_shipdetl.fob_unit_ent_amt
#           IF cost = 0
#           OR cost IS NULL THEN
#              RETURN
#           END IF
#
#     LET duty_found = "Y"
#  SELECT *
#     INTO pr_product.*
#     FROM product
#     WHERE cmpy_code = p_cmpy
#     AND part_code = pr_shipdetl.part_code
#  IF STATUS = NOTFOUND THEN
#     ERROR "Product missing "
#     RETURN
#  END IF
#  IF pr_shiphead.vend_code <> pr_product.vend_code THEN
#     RETURN
#  END IF
#     SELECT *
#     INTO pr_category.*
#     FROM category
#     WHERE cmpy_code = p_cmpy
#     AND cat_code = pr_product.cat_code
#  IF STATUS = NOTFOUND THEN
#     ERROR "Product category missing "
#     RETURN
#  END IF
#     IF pr_category.cost_list_ind = "F" THEN
#           LET converted_fob = conv_currency(pr_shipdetl.fob_unit_ent_amt,p_cmpy,
#                                       pr_shiphead.curr_code, "F",
#                                       pr_recpt_date, "S")
#           #LET converted_fob = pr_shipdetl.fob_unit_ent_amt /
#           #pr_shiphead.conversion_qty
#           LET duty = pr_shipdetl.duty_unit_ent_amt
#           LET cost_fact_amt = (converted_fob * pr_category.oth_cost_fact_per) / 100
#           LET std_cost = duty + cost_fact_amt + converted_fob
#           IF std_cost = 0 THEN
#              LET list_price = pr_prodstatus.list_amt
#           ELSE
#              LET list_price = std_cost +
#                          ((std_cost * pr_category.std_cost_mrkup_per) / 100)
#           END IF
#     END IF

#           LET pr_prodstatus.price1_amt = (list_price *
#                                        pr_category.price1_per) / 100
#           LET pr_prodstatus.price2_amt = (list_price *
#                                        pr_category.price2_per) / 100
#
#           LET pr_prodstatus.price3_amt = (list_price *
#                                        pr_category.price3_per) / 100
#
#           LET pr_prodstatus.price4_amt = (list_price *
#                                        pr_category.price4_per) / 100
#
#           LET pr_prodstatus.price5_amt = (list_price *
#                                        pr_category.price5_per) / 100
#
#           LET pr_prodstatus.price6_amt = (list_price *
#                                        pr_category.price6_per) / 100
#
#           LET pr_prodstatus.price7_amt = (list_price *
#                                        pr_category.price7_per) / 100
#
#           LET pr_prodstatus.price8_amt = (list_price *
#                                        pr_category.price8_per) / 100

#           LET pr_prodstatus.price9_amt = (list_price *
#                                        pr_category.price9_per) / 100
#
#  LET pr_prodstatus.list_amt = list_price
#  UPDATE prodstatus
#     SET price1_amt = pr_prodstatus.price1_amt,
#         price2_amt = pr_prodstatus.price2_amt,
#         price3_amt = pr_prodstatus.price3_amt,
#         price4_amt = pr_prodstatus.price4_amt,
#         price5_amt = pr_prodstatus.price5_amt,
#         price6_amt = pr_prodstatus.price6_amt,
#         price7_amt = pr_prodstatus.price7_amt,
#         price8_amt = pr_prodstatus.price8_amt,
#         price9_amt = pr_prodstatus.price9_amt,
#         last_price_date = today,
#         list_amt = pr_prodstatus.list_amt
#    WHERE part_code = pr_shipdetl.part_code
#    AND cmpy_code = p_cmpy
#END FUNCTION

FUNCTION insert_new_line(ship_code, part_code, line_num, desc_text,ship_rec_qty) 

	DEFINE 
	ship_code LIKE shiphead.ship_code, 
	part_code LIKE shipdetl.part_code, 
	desc_text LIKE shipdetl.desc_text, 
	line_num SMALLINT, 
	ship_rec_qty LIKE shipdetl.ship_rec_qty, 
	try_again CHAR(1), 
	err_message CHAR(40) 

	#GOTO bypass
	#label recovery:
	#LET try_again = error_recover(err_message,STATUS)
	#IF try_again != "Y" THEN
	#EXIT PROGRAM
	#END IF
	#label bypass:
	#WHENEVER ERROR GOTO recovery

	LET err_message = "L41 - shipdetl INSERT" 
	LET pr_shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_shipdetl.ship_code = ship_code 
	LET pr_shipdetl.line_num = line_num 
	LET pr_shipdetl.part_code = part_code 
	LET pr_shipdetl.desc_text = desc_text 
	LET pr_shipdetl.source_doc_num = 0 
	LET pr_shipdetl.doc_line_num = 0 
	LET pr_shipdetl.ship_inv_qty = 0 
	LET pr_shipdetl.ship_rec_qty = ship_rec_qty 
	LET pr_shipdetl.fob_unit_ent_amt = 0 
	LET pr_shipdetl.fob_ext_ent_amt = 0 
	LET pr_shipdetl.duty_unit_ent_amt = 0 
	LET pr_shipdetl.duty_ext_ent_amt = 0 
	LET pr_shipdetl.landed_cost = 0 

	INSERT INTO shipdetl VALUES (pr_shipdetl.*) 


END FUNCTION 

FUNCTION update_shiphead(ship_code, vend_code, ship_status_code, goods_receipt_text, line_num, pr_recpt_date) 

	DEFINE 
	ship_code LIKE shiphead.ship_code, 
	vend_code LIKE shiphead.vend_code, 
	ship_status_code LIKE shiphead.ship_status_code, 
	goods_receipt_text LIKE shiphead.goods_receipt_text, 
	pr_recpt_date DATE, 
	try_again CHAR(1), 
	err_message CHAR(40), 
	line_num LIKE shiphead.line_num 

	#GOTO bypass
	#label recovery:
	#LET try_again = error_recover(err_message,STATUS)
	#IF try_again != "Y" THEN
	#EXIT PROGRAM
	#END IF
	#label bypass:
	#WHENEVER ERROR GOTO recovery

	LET err_message = "L41 - shiphead UPDATE" 
	UPDATE shiphead 
	SET (ship_status_code, goods_receipt_text, line_num) = 
	(ship_status_code, goods_receipt_text, line_num) 
	WHERE shiphead.ship_code = ship_code 
	AND shiphead.vend_code = vend_code 
	AND shiphead.cmpy_code = glob_rec_kandoouser.cmpy_code 

END FUNCTION 

FUNCTION add_item(idx) 

	DEFINE ans CHAR(1), 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	go_on CHAR(1), 
	i, idx SMALLINT, 
	dup_flag CHAR(1) 

	INITIALIZE pr_shipdetl.* TO NULL 
	{  -- albo
	   OPEN WINDOW sitem
	      AT 10, 4
	      with 1 rows, 70 columns
	      attribute (border, yellow)

	   prompt " Do you wish TO add an item TO the shipment? Y/N "
	      FOR CHAR ans
	}
	LET ans = promptYN(""," Do you wish TO add an item TO the shipment? Y/N ","Y") -- albo 
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		--      CLOSE WINDOW sitem
		RETURN 
	END IF 
	LET ans = upshift(ans) 
	IF ans != "Y" THEN 
		--      CLOSE WINDOW sitem
		RETURN 
	END IF 

	--   CLOSE WINDOW sitem

	OPEN WINDOW wl128 with FORM "L128" 
	CALL windecoration_l("L128") -- albo kd-761 

	MESSAGE "CTRL P TO view product details" attribute(yellow) 

	INPUT BY NAME 
	pr_shipdetl.part_code, 
	pr_shipdetl.desc_text, 
	pr_shipdetl.ship_rec_qty, 
	go_on 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","L41","input-pr_shipdetl-1") -- albo 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET pr_shipdetl.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipdetl.part_code 

					NEXT FIELD part_code 
			END CASE 

		ON KEY (control-p) 
			CASE 
				WHEN infield (part_code) 
					CALL pinvwind(glob_rec_kandoouser.cmpy_code, pr_shipdetl.part_code) 
			END CASE 

		AFTER FIELD part_code 
			IF pr_shipdetl.part_code IS NOT NULL THEN 
				SELECT * INTO pr_product.* FROM product 
				WHERE product.part_code = pr_shipdetl.part_code 
				AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					ERROR "Product NOT found. Try window" 
					LET pr_shipdetl.part_code = NULL 
					NEXT FIELD part_code 
				END IF 
				SELECT * INTO pr_prodstatus.* FROM prodstatus 
				WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodstatus.part_code = pr_shipdetl.part_code 
				AND prodstatus.ware_code = pr_shiphead.ware_code 
				IF status = notfound THEN 
					ERROR "Product NOT AT warehouse" 
					SLEEP 2 
					LET pr_shipdetl.part_code = NULL 
					NEXT FIELD part_code 
				END IF 
				LET dup_flag = "N" 
				FOR i = 1 TO (idx - 1) 
					IF pa_shipdetl[i].part_code IS NOT NULL 
					AND pr_shipdetl.part_code IS NOT NULL THEN 
						IF pr_shipdetl.part_code = pa_shipdetl[i].part_code THEN 
							LET dup_flag = "Y" 
							EXIT FOR 
						END IF 
					END IF 
				END FOR 
				IF dup_flag = "Y" THEN 
					ERROR "Duplicate product" 
					SLEEP 2 
					LET pr_shipdetl.part_code = NULL 
					NEXT FIELD part_code 
				END IF 
				LET pr_shipdetl.desc_text = pr_product.desc_text 
				DISPLAY BY NAME 
				pr_shipdetl.desc_text 

			END IF 

		AFTER FIELD desc_text 
			IF pr_shipdetl.part_code IS NULL 
			AND pr_shipdetl.desc_text IS NULL THEN 
				ERROR "Description OR Product Code required" 
				NEXT FIELD part_code 
			END IF 
		AFTER FIELD ship_rec_qty 
			IF pr_shipdetl.ship_rec_qty IS NULL THEN 
				ERROR "Quantity must NOT be NULL" 
				NEXT FIELD ship_rec_qty 
			END IF 
			IF pr_shipdetl.ship_rec_qty < 0 
			OR pr_shipdetl.ship_rec_qty = 0 THEN 
				ERROR "Quantity must be > zero" 
				NEXT FIELD ship_rec_qty 
			END IF 

		AFTER FIELD go_on 
			IF go_on != "Y" THEN 
				NEXT FIELD part_code 
			END IF 

		AFTER INPUT 
			IF quit_flag != 0 
			OR int_flag != 0 THEN ELSE 
				IF pr_shipdetl.part_code IS NOT NULL THEN 
					SELECT * INTO pr_product.* FROM product 
					WHERE product.part_code = pr_shipdetl.part_code 
					AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						ERROR "Product NOT found. Try window" 
						LET pr_shipdetl.part_code = NULL 
						NEXT FIELD part_code 
					END IF 
					SELECT * INTO pr_prodstatus.* FROM prodstatus 
					WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND prodstatus.part_code = pr_shipdetl.part_code 
					AND prodstatus.ware_code = pr_shiphead.ware_code 
					IF status = notfound THEN 
						ERROR "Product NOT AT warehouse" 
						LET pr_shipdetl.part_code = NULL 
						NEXT FIELD part_code 
					END IF 
					LET dup_flag = "N" 
					FOR i = 1 TO (idx - 1) 
						IF pa_shipdetl[i].part_code IS NOT NULL 
						AND pr_shipdetl.part_code IS NOT NULL THEN 
							IF pr_shipdetl.part_code = pa_shipdetl[i].part_code THEN 
								LET dup_flag = "Y" 
								EXIT FOR 
							END IF 
						END IF 
					END FOR 
					IF dup_flag = "Y" THEN 
						ERROR "Duplicate product" 
						SLEEP 2 
						LET pr_shipdetl.part_code = NULL 
						NEXT FIELD part_code 
					END IF 
					LET pr_shipdetl.desc_text = pr_product.desc_text 
					DISPLAY BY NAME 
					pr_shipdetl.desc_text 

				END IF 
				IF pr_shipdetl.part_code IS NULL 
				AND pr_shipdetl.desc_text IS NULL THEN 
					ERROR "Description OR Product Code required" 
					NEXT FIELD part_code 
				END IF 
				IF pr_shipdetl.ship_rec_qty IS NULL THEN 
					ERROR "Quantity must NOT be NULL" 
					NEXT FIELD ship_rec_qty 
				END IF 
				IF pr_shipdetl.ship_rec_qty < 0 
				OR pr_shipdetl.ship_rec_qty = 0 THEN 
					ERROR "Quantity must be > zero" 
					NEXT FIELD ship_rec_qty 
				END IF 
				IF go_on != "Y" THEN 
					NEXT FIELD part_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW wl128 
	RETURN 
END FUNCTION 

FUNCTION ship_receipt(pr_ship_code, pr_vend_code) 

	DEFINE 
	pr_ship_code LIKE shiphead.ship_code, 
	pr_vend_code LIKE shiphead.vend_code, 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_shipstatus RECORD LIKE shipstatus.*, 
	pt_shipdetl ARRAY [310] OF RECORD 
		save_rec_qty LIKE shipdetl.ship_rec_qty, 
		bin1_text LIKE prodstatus.bin1_text, 
		bin2_text LIKE prodstatus.bin2_text, 
		bin3_text LIKE prodstatus.bin3_text, 
		line_num LIKE shipdetl.line_num 
	END RECORD, 
	pr_sum_qty LIKE shiprec.trans_qty, 
	pr_sum_amt LIKE shiprec.trans_amt, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	runner CHAR(200), 
	rec_qty LIKE shipdetl.ship_rec_qty, 
	idx, scrn,i SMALLINT, 
	save_ship_rec_qty LIKE shipdetl.ship_rec_qty, 
	save_ship_status_code LIKE shipstatus.ship_status_code, 
	bin_num SMALLINT, 
	pr_shiprec RECORD LIKE shiprec.*, 
	str CHAR (3000) 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 

	FOR i = 1 TO 310 
		INITIALIZE pa_shipdetl[i].* TO NULL 
	END FOR 
	LET pr_shiphead.ship_code = pr_ship_code 
	LET pr_shiphead.vend_code = pr_vend_code 
	OPEN WINDOW wl110 with FORM "L110" 
	CALL windecoration_l("L110") -- albo kd-761 

	MESSAGE "" 
	SELECT s.*, v.* INTO pr_shiphead.*, pr_vendor.* 
	FROM shiphead s, vendor v 
	WHERE s.ship_code = pr_ship_code 
	AND v.vend_code = pr_vend_code 
	AND s.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND v.cmpy_code = glob_rec_kandoouser.cmpy_code 


	SELECT * INTO pr_warehouse.* FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_shiphead.ware_code 

	LET save_ship_status_code = pr_shiphead.ship_status_code 
	SELECT * INTO pr_shipstatus.* FROM shipstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ship_status_code = pr_shiphead.ship_status_code 
	DISPLAY pr_shiphead.vend_code, 
	pr_vendor.name_text, 
	pr_shiphead.ship_code, 
	pr_shiphead.ship_type_code, 
	pr_warehouse.desc_text, 
	pr_shiphead.ship_status_code, 
	pr_shipstatus.desc_text 
	TO 
	shiphead.vend_code, 
	vendor.name_text, 
	shiphead.ship_code, 
	shiphead.ship_type_code, 
	warehouse.desc_text, 
	shiphead.ship_status_code, 
	shipstatus.desc_text 

	DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
	DISPLAY "see lc/L41.4gl" 
	EXIT program (1) 

	LET str = 
	" SELECT * INTO pr_shipdetl.*, pr_prodstatus.* ", 
	" FROM shipdetl, outer prodstatus ", 
	" WHERE shipdetl.cmpy_code = ",glob_rec_kandoouser.cmpy_code, 
	" AND prodstatus.cmpy_code = ",glob_rec_kandoouser.cmpy_code, 
	" AND shipdetl.ship_code = ",pr_shiphead.ship_code, 
	" AND shipdetl.part_code = prodstatus.part_code ", 
	" AND prodstatus.ware_code = ",pr_shiphead.ware_code, 
	" ORDER BY shipdetl.cmpy_code, ship_code, shipdetl.source_doc_num, ", 
	" doc_line_num " 

	PREPARE tre FROM str 
	DECLARE c_detl CURSOR FOR tre 

	LET idx = 0 
	FOREACH c_detl 
		LET idx = idx + 1 
		SELECT sum(trans_qty), sum(trans_amt) 
		INTO pr_sum_qty, pr_sum_amt 
		FROM shiprec 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND line_num = pr_shipdetl.line_num 
		AND ship_code = pr_shiphead.ship_code 
		IF status = notfound THEN 
			LET pr_sum_qty = 0 
			LET pr_sum_amt = 0 
		END IF 
		IF pr_sum_qty IS NULL THEN 
			LET pr_sum_qty = 0 
		END IF 
		IF pr_sum_amt IS NULL THEN 
			LET pr_sum_amt = 0 
		END IF 
		IF pr_shipdetl.fob_unit_ent_amt = 0 THEN 
			LET pr_shipdetl.ship_rec_qty = pr_sum_qty 
		ELSE 
			LET pr_shipdetl.ship_rec_qty = pr_sum_qty + 
			(pr_sum_amt / pr_shipdetl.fob_unit_ent_amt) 
		END IF 
		LET pa_shipdetl[idx].part_code = pr_shipdetl.part_code 
		LET pa_desc_text[idx].desc_text = pr_shipdetl.desc_text 
		LET pa_shipdetl[idx].ship_rec_qty = pr_shipdetl.ship_rec_qty 
		LET pt_shipdetl[idx].save_rec_qty = pr_shipdetl.ship_rec_qty 
		LET pa_shipdetl[idx].bin_text = pr_prodstatus.bin1_text 
		LET pt_shipdetl[idx].bin1_text = pr_prodstatus.bin1_text 
		LET pt_shipdetl[idx].bin2_text = pr_prodstatus.bin2_text 
		LET pt_shipdetl[idx].bin3_text = pr_prodstatus.bin3_text 
		LET pa_shipdetl[idx].source_doc_num = pr_shipdetl.source_doc_num 
		LET pa_shipdetl[idx].doc_line_num = pr_shipdetl.doc_line_num 
		LET pt_shipdetl[idx].line_num = pr_shipdetl.line_num 
		IF idx > 300 THEN 
			MESSAGE "First 300 items selected" 
			attribute(yellow) 
			SLEEP 3 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET init_size = idx 
	# this INPUT ARRAY IS only used TO DISPLAY the scrolling ARRAY on the
	# window
	CALL set_count(idx) 
	INPUT ARRAY pa_shipdetl WITHOUT DEFAULTS FROM sr_shipdetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","L41","input-arr-pr_shipdetl-2") -- albo 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			EXIT INPUT 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET pr_shiprec.recpt_date = today 
	INPUT BY NAME 
	pr_shiphead.ship_status_code, 
	pr_shiprec.recpt_date 
	WITHOUT DEFAULTS 
	#FROM
	#shiphead.ship_status_code,
	#shiprec.recpt_date

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","L41","input-arr-pr_shiphead-2") -- albo 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (ship_status_code) 
					LET pr_shiphead.ship_status_code = show_shipst(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shiphead.ship_status_code 

					NEXT FIELD ship_status_code 
			END CASE 

		AFTER FIELD ship_status_code 
			SELECT * INTO pr_shipstatus.* FROM shipstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ship_status_code = pr_shiphead.ship_status_code 
			IF status = notfound THEN 
				ERROR "Shipment STATUS NOT found, try window" 
				NEXT FIELD ship_status_code 
			ELSE 
				DISPLAY pr_shipstatus.desc_text TO shipstatus.desc_text 

			END IF 
		AFTER FIELD recpt_date 
			IF pr_shiprec.recpt_date IS NULL THEN 
				LET pr_shiprec.recpt_date = today 
			END IF 
		AFTER INPUT 
			SELECT * INTO pr_shipstatus.* FROM shipstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ship_status_code = pr_shiphead.ship_status_code 
			IF status = notfound THEN 
				ERROR "Shipment STATUS NOT found, try window" 
				SLEEP 3 
				NEXT FIELD ship_status_code 
			ELSE 
				DISPLAY pr_shipstatus.desc_text TO shipstatus.desc_text 

			END IF 
			IF pr_shiprec.recpt_date IS NULL THEN 
				LET pr_shiprec.recpt_date = today 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		CLOSE WINDOW wl110 
		RETURN save_ship_status_code, "0" 
	ELSE 
		IF idx > 0 THEN 
			CALL set_count(idx) 
			MESSAGE "" 
			MESSAGE "Enter quantity, ESC - UPDATE, DEL - EXIT, F7 toggle bin locn." 

			INPUT ARRAY pa_shipdetl WITHOUT DEFAULTS FROM sr_shipdetl.* 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","L41","input-arr-pa_shipdetl-3") -- albo 

				ON ACTION "WEB-HELP" -- albo kd-375 
					CALL onlinehelp(getmoduleid(),null) 

				ON KEY (F7) 
					LET i = 0 
					WHILE true 
						LET i = i + 1 
						IF i > 3 THEN 
							EXIT WHILE 
						END IF 
						LET bin_num = bin_num + 1 
						IF bin_num > 3 THEN 
							LET bin_num = 1 
						END IF 
						CASE bin_num 
							WHEN 1 
								LET pa_shipdetl[idx].bin_text = 
								pt_shipdetl[idx].bin1_text 
							WHEN 2 
								LET pa_shipdetl[idx].bin_text = 
								pt_shipdetl[idx].bin2_text 
							WHEN 3 
								LET pa_shipdetl[idx].bin_text = 
								pt_shipdetl[idx].bin3_text 
						END CASE 
						IF pa_shipdetl[idx].bin_text IS NULL 
						OR pa_shipdetl[idx].bin_text = " " THEN 
							CONTINUE WHILE 
						ELSE 
							EXIT WHILE 
						END IF 
					END WHILE 
					DISPLAY pa_shipdetl[idx].bin_text TO sr_shipdetl[scrn].bin1_text 
				BEFORE ROW 
					LET bin_num = 1 
					LET idx = arr_curr() 
					LET scrn = scr_line() 
					LET rec_qty = pa_shipdetl[idx].rec_qty 
					LET pr_shipdetl.part_code = pa_shipdetl[idx].part_code 
					LET pr_shipdetl.desc_text = pa_desc_text[idx].desc_text 
					LET pr_shipdetl.ship_rec_qty = pa_shipdetl[idx].ship_rec_qty 
					DISPLAY pa_desc_text[idx].desc_text TO shipdetl.desc_text 
					IF idx > arr_count() THEN 
						#   ERROR "There are no further items in the direction you are going"
					END IF 

				BEFORE FIELD rec_qty 
					IF pa_shipdetl[idx].part_code IS NULL 
					AND pa_desc_text[idx].desc_text IS NULL THEN 
						CALL add_item(arr_count()) 
						IF quit_flag != 0 
						OR int_flag != 0 THEN 
							LET quit_flag = 0 
							LET int_flag = 0 
						ELSE 
							LET pa_shipdetl[idx].part_code = pr_shipdetl.part_code 
							LET pa_desc_text[idx].desc_text = pr_shipdetl.desc_text 
							LET pa_shipdetl[idx].ship_rec_qty = pr_shipdetl.ship_rec_qty 
							LET pt_shipdetl[idx].save_rec_qty = 0 
							LET pa_shipdetl[idx].rec_qty = pr_shipdetl.ship_rec_qty 
							DISPLAY pa_shipdetl[idx].* TO sr_shipdetl[scrn].* 
							DISPLAY pa_desc_text[idx].desc_text TO shipdetl.desc_text 
						END IF 
					END IF 

				AFTER FIELD rec_qty 
					IF pa_shipdetl[idx].rec_qty IS NULL 
					AND (pa_shipdetl[idx].part_code IS NOT NULL 
					OR pa_desc_text[idx].desc_text IS NOT null) THEN 
						LET pa_shipdetl[idx].rec_qty = 0 
					END IF 
					IF (pr_shipdetl.ship_rec_qty + 
					pa_shipdetl[idx].rec_qty) < 0 THEN 
						ERROR "Total quantity must be > 0" 
						SLEEP 3 
						LET pa_shipdetl[idx].ship_rec_qty = 
						pt_shipdetl[idx].save_rec_qty 
						DISPLAY pa_shipdetl[idx].ship_rec_qty 
						TO sr_shipdetl[scrn].ship_rec_qty 
						NEXT FIELD rec_qty 
					END IF 
					LET pa_shipdetl[idx].ship_rec_qty = pt_shipdetl[idx].save_rec_qty 
					+ pa_shipdetl[idx].rec_qty 
					DISPLAY pa_shipdetl[idx].ship_rec_qty 
					TO sr_shipdetl[scrn].ship_rec_qty 
				BEFORE FIELD bin1_text 
					NEXT FIELD rec_qty 

				ON KEY (control-w) 
					CALL kandoohelp("") 
			END INPUT 
		ELSE 
			ERROR "There are no line items FOR this shipment" 
			SLEEP 3 
		END IF 
		OPTIONS DELETE KEY f2, 
		INSERT KEY f1 
		CLEAR screen 
		IF int_flag != 0 
		OR quit_flag != 0 THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			CLOSE WINDOW wl110 
			RETURN save_ship_status_code, "0" 
		ELSE 
			GOTO bypass 
			LABEL recovery: 
			LET try_again = error_recover(err_message,status) 
			IF try_again != "Y" THEN 
				EXIT program 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				DECLARE parm_curs CURSOR FOR 
				SELECT * 
				INTO pr_smparms.* 
				FROM smparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND key_num = 1 
				FOR UPDATE 

				OPEN parm_curs 
				FETCH parm_curs 
				LET pr_shiphead.goods_receipt_text = pr_shiphead.ware_code clipped, 
				pr_smparms.next_recpt_num USING "<<<<<<<<#" 
				LET pr_smparms.next_recpt_num = pr_smparms.next_recpt_num + 1 
				UPDATE smparms 
				SET next_recpt_num = next_recpt_num + 1 
				WHERE CURRENT OF parm_curs 

				FOR idx = 1 TO init_size 
					IF pa_shipdetl[idx].rec_qty <> 0 THEN 
						CALL add_receipts(pr_shiphead.ship_code, 
						pa_shipdetl[idx].part_code, 
						#idx,
						pt_shipdetl[idx].line_num, 
						pa_shipdetl[idx].ship_rec_qty, 
						pa_shipdetl[idx].rec_qty, 
						pr_shiphead.goods_receipt_text, 
						pr_shiprec.recpt_date) 
					END IF 
				END FOR 
				IF arr_count() > init_size THEN 
					FOR i = (init_size + 1) TO arr_count() 
						IF pa_shipdetl[i].part_code IS NOT NULL 
						OR pa_desc_text[i].desc_text IS NOT NULL THEN 
							CALL insert_new_line(pr_shiphead.ship_code, 
							pa_shipdetl[i].part_code, 
							idx, 
							pa_desc_text[i].desc_text, 
							pa_shipdetl[i].ship_rec_qty) 
							IF pa_shipdetl[idx].rec_qty <> 0 THEN 
								CALL add_receipts(pr_shiphead.ship_code, 
								pa_shipdetl[idx].part_code, 
								idx, 
								pa_shipdetl[idx].ship_rec_qty, 
								pa_shipdetl[idx].rec_qty, 
								pr_shiphead.goods_receipt_text, 
								pr_shiprec.recpt_date) 
							END IF 
							LET idx = idx + 1 
						END IF 
					END FOR 
				END IF 
				CALL update_shiphead(pr_shiphead.ship_code, 
				pr_shiphead.vend_code, 
				pr_shiphead.ship_status_code, 
				pr_shiphead.goods_receipt_text, (idx - 1), 
				pr_shiprec.recpt_date) 
			COMMIT WORK 
			IF pr_smparms.direct_print_flag = "Y" THEN 
				CALL run_prog("LA2","pr_shiphead.goods_receipt_text","","","") 
			END IF 
		END IF 
	END IF 

	CLOSE WINDOW wl110 
	RETURN pr_shiphead.ship_status_code, pr_shiphead.goods_receipt_text 
END FUNCTION 


