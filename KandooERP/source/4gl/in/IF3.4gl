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

	Source code beautified by beautify.pl on 2020-01-03 09:12:36	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IF3 allows the user TO scan Cost Ledgers.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_costledg RECORD LIKE costledg.*, 
	pa_costledg array[500] OF RECORD 
		tran_date LIKE costledg.tran_date, 
		onhand_qty DECIMAL(16,2), 
		curr_cost_amt DECIMAL(16,2), 
		orig_cost_amt DECIMAL(16,2), 
		current_valuation DECIMAL(16,2) 
	END RECORD, 
	pr_tran_date DATE, 
	pr_tot_valuation DECIMAL(16,2), 
	idx, scrn SMALLINT 
END GLOBALS 


####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IF3") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 


	OPEN WINDOW i142 with FORM "I142" 
	 CALL windecoration_i("I142") -- albo kd-758 
	IF num_args() = 2 THEN 
		LET pr_costledg.part_code = arg_val(1) 
		LET pr_costledg.ware_code = arg_val(2) 
		CALL disp_product() 
		CALL scan_cost() 
	ELSE 
		IF num_args() = 1 THEN 
			LET pr_costledg.part_code = arg_val(1) 
			WHILE select_ware() 
				CALL scan_cost() 
			END WHILE 
		ELSE 
			WHILE select_prod() 
				CALL scan_cost() 
			END WHILE 
		END IF 
	END IF 
	CLOSE WINDOW i142 
END MAIN 


FUNCTION disp_product() 
	LET msgresp=kandoomsg("I",9180,"") 
	#I9180 " Enter Product AND Warehouse Codes.
	DISPLAY pr_costledg.part_code, 
	pr_costledg.ware_code 
	TO costledg.part_code, 
	costledg.ware_code 
	SELECT * INTO pr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_costledg.part_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("I",5010,pr_costledg.part_code) 
		#5010" Logic error: Product code NOT found ????"
		EXIT program 
	END IF 
	SELECT * INTO pr_warehouse.* FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_costledg.ware_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("I",5011,pr_costledg.ware_code) 
		#5010" Logic error: Warehouse code NOT found ????"
		EXIT program 
	END IF 
	DISPLAY pr_product.desc_text, 
	pr_product.desc2_text, 
	pr_warehouse.desc_text 
	TO product.desc_text, 
	product.desc2_text, 
	warehouse.desc_text 
END FUNCTION 


FUNCTION select_ware() 
	LET msgresp=kandoomsg("I",9180,"") 
	#I9180 " Enter Product AND Warehouse Codes.
	CLEAR FORM 
	LET pr_costledg.part_code = arg_val(1) 
	DISPLAY pr_costledg.part_code TO costledg.part_code 
	SELECT * INTO pr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_costledg.part_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("I",5010,pr_costledg.part_code) 
		#5010" Logic error: Product code NOT found ????"
		EXIT program 
	END IF 
	DISPLAY pr_product.desc_text, 
	pr_product.desc2_text 
	TO product.desc_text, 
	product.desc2_text 

	INPUT BY NAME pr_costledg.ware_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IF3","input-pr_costledg-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (ware_code) 
					LET pr_costledg.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_costledg.ware_code 
					NEXT FIELD ware_code 
			END CASE 

		AFTER FIELD ware_code 
			SELECT * INTO pr_warehouse.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_costledg.ware_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("I",9030,"") 
				# 9010 "Warehouse does NOT exist - Try window"
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION select_prod() 
	LET msgresp=kandoomsg("I",9180,"") 
	#I9180 " Enter Product AND Warehouse Codes.
	CLEAR FORM 
	INPUT BY NAME pr_costledg.part_code, 
	pr_costledg.ware_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IF3","input-pr_costledg-2") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET pr_costledg.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_costledg.part_code 
					NEXT FIELD part_code 
				WHEN infield (ware_code) 
					LET pr_costledg.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_costledg.ware_code 
					NEXT FIELD ware_code 
			END CASE 

		AFTER FIELD part_code 
			SELECT * INTO pr_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_costledg.part_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("I",9010,"") 
				# 9010 Product does NOT exist - Try window
				NEXT FIELD part_code 
			ELSE 
				DISPLAY pr_product.desc_text, 
				pr_product.desc2_text 
				TO product.desc_text, 
				product.desc2_text 
			END IF 

		AFTER FIELD ware_code 
			SELECT * INTO pr_warehouse.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_costledg.ware_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("I",9030,"") 
				# 9010 "Warehouse does NOT exist - Try window"
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT * INTO pr_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_costledg.part_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9010,"") 
					# 9010 Product does NOT exist - Try window
					NEXT FIELD part_code 
				ELSE 
					DISPLAY pr_product.desc_text, 
					pr_product.desc2_text 
					TO product.desc_text, 
					product.desc2_text 
				END IF 
				SELECT * INTO pr_warehouse.* FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_costledg.ware_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9030,"") 
					# 9010 "Warehouse does NOT exist - Try window"
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY pr_warehouse.desc_text 
					TO warehouse.desc_text 
				END IF 

			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION scan_cost() 
	DECLARE c_costledg CURSOR FOR 
	SELECT * INTO pr_costledg.* FROM costledg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_costledg.part_code 
	AND ware_code = pr_costledg.ware_code 
	AND onhand_qty != 0 
	ORDER BY costledg.tran_date 
	LET idx = 0 
	FOREACH c_costledg 
		LET idx = idx + 1 
		LET pa_costledg[idx].tran_date = pr_costledg.tran_date 
		LET pa_costledg[idx].onhand_qty = pr_costledg.onhand_qty 
		LET pa_costledg[idx].curr_cost_amt = pr_costledg.curr_cost_amt 
		LET pa_costledg[idx].orig_cost_amt = pr_costledg.curr_cost_amt + 
		pr_costledg.curr_wo_amt + 
		pr_costledg.prev_wo_amt 
		LET pa_costledg[idx].current_valuation = pr_costledg.onhand_qty * 
		pr_costledg.curr_cost_amt 
		IF idx > 500 THEN 
			LET msgresp = kandoomsg("I",9105,"500") 
			# 9105 "First 500 cost ledgers selected only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("I",9106,"") 
		# 9105 " No Cost ledgers satisfied the selection criteria"
		RETURN 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET pr_tot_valuation = NULL 
	SELECT sum(onhand_qty * curr_cost_amt) INTO pr_tot_valuation FROM costledg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_costledg.part_code 
	AND ware_code = pr_costledg.ware_code 
	DISPLAY pr_tot_valuation TO tot_valuation 

	CALL set_count(idx) 
	LET msgresp = kandoomsg("I",1008,"") 
	# F3/F4 TO page forward/backward ESC TO Continue

	INPUT ARRAY pa_costledg WITHOUT DEFAULTS FROM sr_costledg.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IF3","input-arr-pa_costledg-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE FIELD tran_date 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_tran_date = pa_costledg[idx].tran_date 
			DISPLAY pa_costledg[idx].* TO sr_costledg[scrn].* 
		AFTER FIELD tran_date 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_costledg[idx+1].tran_date IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("I",9001,"") 
					# There are no more rows in the direction you are going "
					NEXT FIELD tran_date 
				END IF 
			END IF 
		BEFORE FIELD onhand_qty 
			NEXT FIELD tran_date 
		AFTER ROW 
			LET pa_costledg[idx].tran_date = pr_tran_date 
			DISPLAY pa_costledg[idx].* TO sr_costledg[scrn].* 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
	CLEAR FORM 
END FUNCTION 
