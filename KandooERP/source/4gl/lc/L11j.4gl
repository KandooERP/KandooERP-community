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

	Source code beautified by beautify.pl on 2020-01-02 18:38:29	$Id: $
}




# poscan - Provides a lookup scan of purchase orders
# select_multipo_lines - Allows the user TO SELECT multiple lines FROM a
#                     po TO be included in a shipment
# select_singlepo_lines - Allows the user TO SELECT a single line FROM a
#             po TO be included in a shipment

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L11_GLOBALS.4gl" 


FUNCTION find_po(p_cmpy, pr_vend_code, pr_ware_code) 

	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_vend_code LIKE vendor.vend_code, 
	pr_ware_code LIKE warehouse.ware_code, 
	where_part CHAR(500), 
	sel_text CHAR(1000), 
	try_another CHAR(1), 
	pa_purchhead array[500] OF RECORD 
		order_num LIKE purchhead.order_num, 
		ref_text LIKE purchdetl.ref_text, 
		order_date LIKE purchhead.order_date, 
		desc_text LIKE purchdetl.desc_text 
	END RECORD, 
	idx SMALLINT, 
	cnt SMALLINT 

	OPEN WINDOW wl134 with FORM "L134" 
	CALL windecoration_l("L134") -- albo kd-761 
	WHILE true 
		LET try_another = "N" 
		MESSAGE "Enter selection criteria - ESC TO begin search" 
		attribute (yellow) 
		CONSTRUCT where_part ON 
		purchhead.order_num, 
		purchdetl.ref_text, 
		purchhead.order_date , 
		purchdetl.desc_text 
		FROM sr_purchhead[1].order_num, 
		sr_purchhead[1].ref_text, 
		sr_purchhead[1].order_date, 
		sr_purchhead[1].desc_text 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		LET sel_text = 
		"SELECT purchhead.order_num, ", 
		" purchdetl.ref_text, ", 
		" purchhead.order_date, ", 
		" purchdetl.desc_text ", 
		" FROM purchhead, purchdetl ", 
		" WHERE purchhead.cmpy_code = \"", p_cmpy, "\" ", 
		" AND purchdetl.cmpy_code = \"", p_cmpy, "\" ", 
		" AND purchhead.order_num = purchdetl.order_num ", 
		" AND purchhead.vend_code = \"", pr_vend_code, "\" ", 
		" AND purchhead.ware_code = \"",pr_ware_code, "\" ", 
		" AND ", where_part clipped, 
		" ORDER BY purchdetl.ref_text " 
		PREPARE purch FROM sel_text 
		DECLARE purchcurs CURSOR FOR purch 
		LET idx = 1 
		FOREACH purchcurs INTO pa_purchhead[idx].* 
			LET idx = idx + 1 
			IF idx > 500 THEN 
				MESSAGE " First 500 only selected "attribute (yellow) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET idx = idx -1 
		IF idx > 0 THEN 
			MESSAGE 
			"Cursor TO code AND press ESC, F9 re-SELECT, F10 add" 
			attribute (yellow) 
		ELSE 
			MESSAGE "No orders satisfy criteria, F9 re-SELECT, F10 add" 
			attribute (yellow) 
		END IF 
		LET cnt = idx 
		CALL set_count(idx) 

		DISPLAY ARRAY pa_purchhead TO sr_purchhead.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","L11j","display-arr-purchhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F10) 
				CALL run_prog("R11.4gi","","","","") 

			ON KEY (F9) 
				LET try_another = "Y" 
				EXIT DISPLAY 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END DISPLAY 
		IF try_another != "Y" THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	LET idx = arr_curr() 
	CLOSE WINDOW wl134 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN -1 
	ELSE 
		RETURN pa_purchhead[idx].order_num 
	END IF 
END FUNCTION 

########################################################################
# select_multipo_lines - Allows the user TO SELECT multiple lines FROM a
#             po TO be included in a shipment

FUNCTION select_multipo_lines(p_cmpy, pr_po_num, pr_vend_code) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_po_num LIKE purchhead.order_num, 
	pr_name_text LIKE vendor.name_text, 
	pr_vend_code LIKE vendor.vend_code, 
	where_part CHAR(500), 
	sel_text CHAR(1000), 
	try_another CHAR(1), 
	pt_purchdetl RECORD 
		type_ind LIKE purchdetl.type_ind, 
		line_num LIKE purchdetl.line_num, 
		ref_text LIKE purchdetl.ref_text, 
		desc_text LIKE purchdetl.desc_text, 
		order_qty LIKE poaudit.order_qty 
	END RECORD, 
	pa_purchdetl array[300] OF RECORD 
		toggle_ind CHAR(1), 
		type_ind LIKE purchdetl.type_ind, 
		line_num LIKE purchdetl.line_num, 
		ref_text LIKE purchdetl.ref_text, 
		order_qty LIKE poaudit.order_qty 
	END RECORD, 
	pa_purchdetl2 array[300] OF RECORD 
		desc_text LIKE purchdetl.desc_text 
	END RECORD, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_toggle_flag CHAR(1), 
	idx , j, i, cnt SMALLINT, 
	base_cost_amt LIKE shipdetl.fob_unit_ent_amt 

	OPEN WINDOW wl135 with FORM "L135" 
	CALL windecoration_l("L135") -- albo kd-761 
	SELECT name_text 
	INTO pr_name_text 
	FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = pr_vend_code 
	DISPLAY pr_po_num, 
	pr_vend_code, 
	pr_name_text 
	TO 
	purchhead.order_num, 
	vendor.vend_code, 
	vendor.name_text 
	WHILE true 
		LET try_another = "N" 
		LET sel_text = 
		"SELECT purchdetl.type_ind, ", 
		" purchdetl.line_num, ", 
		" purchdetl.ref_text, ", 
		" purchdetl.desc_text , ", 
		" sum(poaudit.order_qty) ", 
		" FROM poaudit, purchdetl ", 
		" WHERE poaudit.cmpy_code = \"", p_cmpy, "\" ", 
		" AND purchdetl.cmpy_code = \"", p_cmpy, "\" ", 
		" AND purchdetl.order_num = \"", pr_po_num, "\" ", 
		" AND poaudit.po_num = purchdetl.order_num ", 
		" AND poaudit.line_num = purchdetl.line_num ", 
		" group by purchdetl.line_num, purchdetl.type_ind, ", 
		" purchdetl.ref_text, ", 
		" purchdetl.desc_text ", 
		" ORDER BY purchdetl.line_num" 
		PREPARE purch1 FROM sel_text 
		DECLARE purch1curs CURSOR FOR purch1 
		LET idx = 1 
		FOREACH purch1curs INTO pt_purchdetl.* 
			LET pa_purchdetl[idx].toggle_ind = " " 
			LET pa_purchdetl[idx].type_ind = pt_purchdetl.type_ind 
			LET pa_purchdetl[idx].line_num = pt_purchdetl.line_num 
			LET pa_purchdetl[idx].ref_text = pt_purchdetl.ref_text 
			LET pa_purchdetl[idx].order_qty = pt_purchdetl.order_qty 
			LET pa_purchdetl2[idx].desc_text = pt_purchdetl.desc_text 
			LET idx = idx + 1 
			IF idx > 300 THEN 
				MESSAGE " First 300 only selected "attribute (yellow) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET idx = idx -1 
		IF idx > 0 THEN 
			MESSAGE "F7 TO toggle line" attribute (yellow) 
		ELSE 
			ERROR "No ORDER lines found " 
		END IF 
		LET cnt = idx 
		CALL set_count(idx) 
		INPUT ARRAY pa_purchdetl WITHOUT DEFAULTS FROM sr_purchdetl.* 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

				#        DISPLAY ARRAY pa_purchdetl TO sr_purchdetl.*
			ON KEY (F7) 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_purchdetl[idx].toggle_ind = "*" THEN 
					LET pa_purchdetl[idx].toggle_ind = " " 
				ELSE 
					LET pa_purchdetl[idx].toggle_ind = "*" 
				END IF 
				LET pr_toggle_flag = pa_purchdetl[idx].toggle_ind 
				DISPLAY pa_purchdetl[idx].toggle_ind TO 
				sr_purchdetl[scrn].toggle_ind 

			BEFORE FIELD toggle_ind 
				LET idx = arr_curr() 
				DISPLAY pa_purchdetl2[idx].desc_text 
				TO purchdetl.desc_text 
				LET pr_toggle_flag = pa_purchdetl[idx].toggle_ind 

			AFTER FIELD toggle_ind 
				LET pa_purchdetl[idx].toggle_ind = pr_toggle_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() = arr_count() THEN 
					LET msgresp = kandoomsg("E",9001,"") 
					NEXT FIELD toggle_ind 
				END IF 
				#                NEXT FIELD toggle_ind

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		#        END DISPLAY
		IF try_another != "Y" THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW wl135 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN 0 
	ELSE 
		# SET up lines selected
		FOR j = 1 TO 300 
			IF st_shipdetl[j].desc_text IS NULL THEN 
				EXIT FOR 
			END IF 
		END FOR 
		FOR i = 1 TO 300 
			IF pa_purchdetl[i].toggle_ind = "*" THEN 
				INITIALIZE st_shipdetl[j].* TO NULL 
				LET st_shipdetl[j].cmpy_code = p_cmpy 
				SELECT * INTO pr_purchdetl.* 
				FROM purchdetl 
				WHERE cmpy_code = p_cmpy 
				AND order_num = pr_po_num 
				AND line_num = pa_purchdetl[i].line_num 
				CALL po_line_info (p_cmpy, pr_purchdetl.order_num,pr_purchdetl.line_num) 
				RETURNING 
				pr_poaudit.order_qty, 
				pr_poaudit.received_qty, 
				pr_poaudit.voucher_qty, 
				pr_poaudit.unit_cost_amt, 
				pr_poaudit.ext_cost_amt, 
				pr_poaudit.unit_tax_amt, 
				pr_poaudit.ext_tax_amt, 
				pr_poaudit.line_total_amt 
				LET st_shipdetl[j].ship_inv_qty = pr_poaudit.order_qty - 
				pr_poaudit.received_qty 
				IF st_shipdetl[j].ship_inv_qty < 0 THEN 
					LET st_shipdetl[j].ship_inv_qty = 0 
				END IF 
				LET st_shipdetl[j].fob_unit_ent_amt = pr_poaudit.unit_cost_amt 
				LET st_shipdetl[j].fob_ext_ent_amt = st_shipdetl[j].ship_inv_qty 
				* st_shipdetl[j].fob_unit_ent_amt 
				CASE 
					WHEN pr_purchdetl.type_ind = "I" {inventory} 
						LET st_shipdetl[j].source_doc_num = pr_purchdetl.order_num 
						LET st_shipdetl[j].doc_line_num = pr_purchdetl.line_num 
						LET st_shipdetl[j].part_code = pr_purchdetl.ref_text 
						LET st_shipdetl[j].desc_text = pr_purchdetl.desc_text 
						LET st_shipdetl[j].job_code = NULL 
						LET st_shipdetl[j].var_code = NULL 
						LET st_shipdetl[j].activity_code = NULL 
						LET st_shipdetl[j].acct_code = pr_purchdetl.acct_code 
						SELECT tariff_code 
						INTO st_shipdetl[j].tariff_code 
						FROM product 
						WHERE cmpy_code = p_cmpy 
						AND part_code = st_shipdetl[j].part_code 
						IF status != notfound THEN 
							SELECT duty_per 
							INTO st_shipdetl[j].duty_rate_per 
							FROM tariff 
							WHERE cmpy_code = p_cmpy 
							AND tariff_code = st_shipdetl[j].tariff_code 
							IF status = notfound THEN 
								IF pr_poaudit.unit_cost_amt != 0 THEN 
									LET st_shipdetl[j].duty_rate_per = 
									(pr_poaudit.unit_tax_amt / 
									pr_poaudit.unit_cost_amt ) * 100 
								ELSE 
									LET st_shipdetl[j].duty_rate_per = 0 
								END IF 
								LET base_cost_amt = conv_shipcurr( 
								pr_poaudit.unit_tax_amt, 
								pr_shiphead.curr_code, "F", 
								pr_shiphead.conversion_qty) 
								LET st_shipdetl[j].tariff_code = NULL 
								LET st_shipdetl[j].duty_unit_ent_amt = 
								base_cost_amt 
								LET st_shipdetl[j].duty_ext_ent_amt = 
								base_cost_amt * 
								st_shipdetl[j].ship_inv_qty 
							ELSE 
								LET base_cost_amt = conv_shipcurr( 
								st_shipdetl[j].fob_unit_ent_amt, 
								pr_shiphead.curr_code, "F", 
								pr_shiphead.conversion_qty) 
								LET st_shipdetl[j].duty_unit_ent_amt = 
								base_cost_amt * st_shipdetl[j].duty_rate_per / 100 
								LET st_shipdetl[j].duty_ext_ent_amt = 
								st_shipdetl[j].duty_unit_ent_amt * 
								st_shipdetl[j].ship_inv_qty 
							END IF 
						ELSE 
							LET base_cost_amt = conv_shipcurr( 
							pr_poaudit.unit_tax_amt, 
							pr_shiphead.curr_code, "F", 
							pr_shiphead.conversion_qty) 
							IF pr_poaudit.unit_cost_amt != 0 THEN 
								LET st_shipdetl[j].duty_rate_per = 
								(pr_poaudit.unit_tax_amt / 
								pr_poaudit.unit_cost_amt ) * 100 
							ELSE 
								LET st_shipdetl[j].duty_rate_per = 0 
							END IF 
							LET st_shipdetl[j].duty_unit_ent_amt = 
							base_cost_amt 
							LET st_shipdetl[j].duty_ext_ent_amt = 
							base_cost_amt * st_shipdetl[j].ship_inv_qty 
						END IF 
					WHEN pr_purchdetl.type_ind = "G" {general} 
						LET st_shipdetl[j].source_doc_num = pr_purchdetl.order_num 
						LET st_shipdetl[j].doc_line_num = pr_purchdetl.line_num 
						LET st_shipdetl[j].part_code = NULL 
						LET st_shipdetl[j].desc_text = pr_purchdetl.desc_text 
						LET st_shipdetl[j].job_code = NULL 
						LET st_shipdetl[j].var_code = NULL 
						LET st_shipdetl[j].activity_code = NULL 
						LET st_shipdetl[j].acct_code = pr_purchdetl.acct_code 
						IF pr_poaudit.unit_cost_amt != 0 THEN 
							LET st_shipdetl[j].duty_rate_per = 
							(pr_poaudit.unit_tax_amt / 
							pr_poaudit.unit_cost_amt ) * 100 
						ELSE 
							LET st_shipdetl[j].duty_rate_per = 0 
						END IF 
						LET st_shipdetl[j].tariff_code = NULL 
						LET st_shipdetl[j].duty_unit_ent_amt = conv_shipcurr( 
						pr_poaudit.unit_tax_amt, 
						pr_shiphead.curr_code, "F", 
						pr_shiphead.conversion_qty) 
						LET st_shipdetl[j].duty_ext_ent_amt = 
						st_shipdetl[j].duty_unit_ent_amt * 
						st_shipdetl[j].ship_inv_qty 
					WHEN pr_purchdetl.type_ind = "J" {job management} 
						LET st_shipdetl[j].source_doc_num = pr_purchdetl.order_num 
						LET st_shipdetl[j].doc_line_num = pr_purchdetl.line_num 
						LET st_shipdetl[j].part_code = NULL 
						LET st_shipdetl[j].desc_text = pr_purchdetl.desc_text 
						LET st_shipdetl[j].job_code = pr_purchdetl.job_code 
						LET st_shipdetl[j].var_code = pr_purchdetl.var_num 
						LET st_shipdetl[j].activity_code = pr_purchdetl.activity_code 
						LET st_shipdetl[j].acct_code = pr_purchdetl.acct_code 
						IF pr_poaudit.unit_cost_amt != 0 THEN 
							LET st_shipdetl[j].duty_rate_per = 
							(pr_poaudit.unit_tax_amt / 
							pr_poaudit.unit_cost_amt ) * 100 
						ELSE 
							LET st_shipdetl[j].duty_rate_per = 0 
						END IF 
						LET st_shipdetl[j].tariff_code = NULL 
						LET st_shipdetl[j].duty_unit_ent_amt = 
						conv_shipcurr( pr_poaudit.unit_tax_amt, 
						pr_shiphead.curr_code, "F", 
						pr_shiphead.conversion_qty) 
						LET st_shipdetl[j].duty_ext_ent_amt = 
						st_shipdetl[j].duty_unit_ent_amt * 
						st_shipdetl[j].ship_inv_qty 
				END CASE 
				LET pr_shiphead.fob_ent_cost_amt = pr_shiphead.fob_ent_cost_amt 
				+ st_shipdetl[j].fob_ext_ent_amt 
				LET pr_shiphead.duty_ent_amt = pr_shiphead.duty_ent_amt 
				+ st_shipdetl[j].duty_ext_ent_amt 
				LET pa_shipdetl[j].part_code = st_shipdetl[j].part_code 
				LET pa_shipdetl[j].source_doc_num = st_shipdetl[j].source_doc_num 
				LET pa_shipdetl[j].ship_inv_qty = st_shipdetl[j].ship_inv_qty 
				LET pa_shipdetl[j].fob_unit_ent_amt = st_shipdetl[j].fob_unit_ent_amt 
				LET pa_shipdetl[j].tariff_code = st_shipdetl[j].tariff_code 
				LET pa_shipdetl[j].duty_unit_ent_amt = st_shipdetl[j].duty_unit_ent_amt 
				LET j = j + 1 
				IF j > 300 THEN 
					ERROR " Only 300 lines allowed on a shipment" 
					EXIT FOR 
				END IF 
			END IF 
		END FOR 
	END IF 
	RETURN j-1 
END FUNCTION 



########################################################################
# select_singlepo_lines - Allows the user TO SELECT a single line FROM a
#             po TO be included in a shipment

FUNCTION select_singlepo_lines(p_cmpy, pr_po_num, pr_vend_code) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_po_num LIKE purchhead.order_num, 
	pr_name_text LIKE vendor.name_text, 
	pr_vend_code LIKE vendor.vend_code, 
	where_part CHAR(500), 
	sel_text CHAR(1000), 
	try_another CHAR(1), 
	pt_purchdetl RECORD 
		type_ind LIKE purchdetl.type_ind, 
		line_num LIKE purchdetl.line_num, 
		ref_text LIKE purchdetl.ref_text, 
		desc_text LIKE purchdetl.desc_text, 
		order_qty LIKE poaudit.order_qty 
	END RECORD, 
	pa_purchdetl array[100] OF RECORD 
		toggle_ind CHAR(1), 
		type_ind LIKE purchdetl.type_ind, 
		line_num LIKE purchdetl.line_num, 
		ref_text LIKE purchdetl.ref_text, 
		order_qty LIKE poaudit.order_qty 
	END RECORD, 
	pa_purchdetl2 array[100] OF RECORD 
		desc_text LIKE purchdetl.desc_text 
	END RECORD, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	idx , j, i, cnt SMALLINT 
	OPEN WINDOW wl135 with FORM "L135" 
	CALL windecoration_l("L135") -- albo kd-761 
	SELECT name_text 
	INTO pr_name_text 
	FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = pr_vend_code 
	DISPLAY pr_po_num, 
	pr_vend_code, 
	pr_name_text 
	TO 
	purchhead.order_num, 
	vendor.vend_code, 
	vendor.name_text 
	WHILE true 
		LET try_another = "N" 
		LET sel_text = 
		"SELECT purchdetl.type_ind, ", 
		" purchdetl.line_num, ", 
		" purchdetl.ref_text, ", 
		" purchdetl.desc_text, ", 
		" sum(poaudit.order_qty) ", 
		" FROM poaudit, purchdetl ", 
		" WHERE poaudit.cmpy_code = \"", p_cmpy, "\" ", 
		" AND purchdetl.cmpy_code = \"", p_cmpy, "\" ", 
		" AND purchdetl.order_num = \"", pr_po_num, "\" ", 
		" AND poaudit.po_num = purchdetl.order_num ", 
		" AND poaudit.line_num = purchdetl.line_num ", 
		" group by purchdetl.line_num, purchdetl.type_ind, ", 
		" purchdetl.ref_text, ", 
		" purchdetl.desc_text ", 
		" ORDER BY purchdetl.line_num" 
		PREPARE purch2 FROM sel_text 
		DECLARE purch2curs CURSOR FOR purch2 
		LET idx = 1 
		FOREACH purch2curs INTO pt_purchdetl.* 
			LET pa_purchdetl[idx].toggle_ind = " " 
			LET pa_purchdetl[idx].type_ind = pt_purchdetl.type_ind 
			LET pa_purchdetl[idx].line_num = pt_purchdetl.line_num 
			LET pa_purchdetl[idx].ref_text = pt_purchdetl.ref_text 
			LET pa_purchdetl[idx].order_qty = pt_purchdetl.order_qty 
			LET pa_purchdetl2[idx].desc_text = pt_purchdetl.desc_text 
			LET idx = idx + 1 
			IF idx > 100 THEN 
				MESSAGE " First 100 only selected "attribute (yellow) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET idx = idx -1 
		IF idx > 0 THEN 
			MESSAGE "Arrow TO row, ESC TO SELECT" attribute (yellow) 
		ELSE 
			ERROR "No ORDER lines found " 
			RETURN 0 
		END IF 
		LET cnt = idx 
		CALL set_count(idx) 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 
		INPUT ARRAY pa_purchdetl WITHOUT DEFAULTS FROM sr_purchdetl.* 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE FIELD toggle_ind 
				LET idx = arr_curr() 
				DISPLAY pa_purchdetl2[idx].desc_text 
				TO purchdetl.desc_text 
				#LET pr_toggle_flag = pa_purchdetl[idx].toggle_ind

			AFTER FIELD toggle_ind 
				#LET pa_purchdetl[idx].toggle_ind = pr_toggle_flag
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() = arr_count() THEN 
					LET msgresp = kandoomsg("E",9001,"") 
					NEXT FIELD toggle_ind 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		OPTIONS DELETE KEY f2, 
		INSERT KEY f1 
		EXIT WHILE 
	END WHILE 
	LET idx = arr_curr() 
	CLOSE WINDOW wl135 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN 0 
	ELSE 
		RETURN pa_purchdetl[idx].line_num 
	END IF 
END FUNCTION 

