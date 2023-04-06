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

KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IF1 allows the user TO scan the FIFO costs.
# TODO: check if the error -703 still occurs in lib_report_reptfunc.4gl after merge
# TODO: clean code priority 1
# TODO: clean code priority 2
# TODO: clean code priority 3

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	pa_prodledg array[200] OF RECORD 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num, 
		trantype_ind LIKE prodledg.trantype_ind, 
		source_code LIKE prodledg.source_code, 
		source_text LIKE prodledg.source_text, 
		source_num LIKE prodledg.source_num, 
		tran_qty DECIMAL(7,2), 
		cost_amt DECIMAL(10,2), 
		sales_amt DECIMAL(11,2), 
		margin_per CHAR(6) 
	END RECORD, 
	pa_seq_num array[200] OF RECORD 
		seq_num LIKE prodledg.seq_num 
	END RECORD, 
	pr_tran_date LIKE prodledg.tran_date, 
	pr_product RECORD LIKE product.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	runner CHAR(512), 
	filter_text CHAR(250), 
	filter_text2 CHAR(250), 
	idx, scrn SMALLINT 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IF1") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i116 with FORM "I116" 
	 CALL windecoration_i("I116") -- albo kd-758 
	IF num_args() > 0 THEN 
		LET pr_prodledg.part_code = arg_val(1) 
		WHILE select_ware() 
			CALL scan_prodledg() 
		END WHILE 
	ELSE 
		WHILE select_prodledg() 
			CALL scan_prodledg() 
		END WHILE 
	END IF 
	CLOSE WINDOW i116 
END MAIN 


FUNCTION select_ware() 
	CLEAR FORM 
	DISPLAY pr_prodledg.part_code TO prodledg.part_code 
	SELECT * INTO pr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_prodledg.part_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("I",5010,pr_prodledg.part_code) 
		#5010" Logic error: Product code NOT found ????"
		EXIT program 
	END IF 
	DISPLAY pr_product.desc_text, 
	pr_product.desc2_text 
	TO product.desc_text, 
	product.desc2_text 
	LET msgresp = kandoomsg("I",1001,"") 
	# 1001 Enter selection criteria - ESC TO continue
	LET pr_prodledg.tran_date = today - 30 
	INPUT BY NAME pr_prodledg.ware_code, 
	pr_prodledg.tran_date WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IE1","input-pr_prodledg-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (ware_code) 
					LET pr_prodledg.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_prodledg.ware_code 

					NEXT FIELD ware_code 
			END CASE 
		AFTER FIELD ware_code 
			SELECT warehouse.desc_text INTO pr_warehouse.desc_text FROM warehouse 
			WHERE ware_code = pr_prodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("I",9030,"") 
				# 9030 Warehouse does NOT exist - Try window
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 

			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT warehouse.desc_text INTO pr_warehouse.desc_text FROM warehouse 
				WHERE ware_code = pr_prodledg.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9030,"") 
					# 9030 Warehouse does NOT exist - Try window
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 

				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION select_prodledg() 
	CLEAR FORM 
	LET msgresp = kandoomsg("I",9180,"") 
	#9180 Enter Product AND Warehouse Codes.
	LET pr_prodledg.tran_date = today - 30 
	INPUT BY NAME pr_prodledg.part_code, 
	pr_prodledg.ware_code, 
	pr_prodledg.tran_date WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IE1","input-pr_prodledg-2") -- albo kd-505 
		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET pr_prodledg.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_prodledg.part_code 

					NEXT FIELD part_code 
				WHEN infield (ware_code) 
					LET pr_prodledg.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_prodledg.ware_code 

					NEXT FIELD ware_code 
			END CASE 
		AFTER FIELD part_code 
			SELECT product.* INTO pr_product.* FROM product 
			WHERE product.part_code = pr_prodledg.part_code 
			AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
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
			SELECT warehouse.desc_text INTO pr_warehouse.desc_text FROM warehouse 
			WHERE ware_code = pr_prodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("I",9030,"") 
				# 9030 Warehouse does NOT exist - Try window
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 

			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT product.* INTO pr_product.* FROM product 
				WHERE part_code = pr_prodledg.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
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
				SELECT warehouse.desc_text INTO pr_warehouse.desc_text FROM warehouse 
				WHERE ware_code = pr_prodledg.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9030,"") 
					# 9030 Warehouse does NOT exist - Try window
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 

				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_prodledg() 
	DEFINE l_run_arg STRING 

	LET msgresp = kandoomsg("I",1002,"") 
	# 1002 Searching database - Please wait
	DECLARE c_prodledg CURSOR FOR 
	SELECT prodledg.* INTO pr_prodledg.* FROM prodledg 
	WHERE prodledg.part_code = pr_prodledg.part_code 
	AND prodledg.ware_code = pr_prodledg.ware_code 
	AND prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND prodledg.tran_date >= pr_prodledg.tran_date 
	ORDER BY prodledg.seq_num 
	LET idx = 0 
	FOREACH c_prodledg 
		LET idx = idx + 1 
		IF idx > 200 THEN 
			LET msgresp=kandoomsg("I",9100,200) 
			#9100 First 200 product ledgers selected only
			EXIT FOREACH 
		END IF 
		LET pa_prodledg[idx].tran_date = pr_prodledg.tran_date 
		LET pa_prodledg[idx].year_num = pr_prodledg.year_num 
		LET pa_prodledg[idx].period_num = pr_prodledg.period_num 
		LET pa_prodledg[idx].trantype_ind = pr_prodledg.trantype_ind 
		LET pa_prodledg[idx].source_code = pr_prodledg.source_code 
		LET pa_prodledg[idx].source_text = pr_prodledg.source_text 
		LET pa_prodledg[idx].source_num = pr_prodledg.source_num 
		LET pa_prodledg[idx].tran_qty = pr_prodledg.tran_qty 
		LET pa_prodledg[idx].cost_amt = pr_prodledg.cost_amt 
		LET pa_prodledg[idx].sales_amt = pr_prodledg.sales_amt * 
		pr_prodledg.tran_qty 
		IF pr_prodledg.sales_amt = 0 THEN 
			LET pa_prodledg[idx].margin_per = 0 USING "##&.&&" 
		ELSE 
			LET pa_prodledg[idx].margin_per = ((pr_prodledg.sales_amt - 
			pr_prodledg.cost_amt) * 100) / 
			pr_prodledg.sales_amt USING "##&.&&" 
		END IF 
		LET pa_seq_num[idx].seq_num = pr_prodledg.seq_num 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp=kandoomsg("I",9101,"") 
		#9101 No product ledgers satisfied the selection criteria
		RETURN 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	SELECT onhand_qty INTO pr_prodstatus.onhand_qty FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_prodledg.part_code 
	AND ware_code = pr_prodledg.ware_code 
	DISPLAY pr_prodstatus.onhand_qty TO prodstatus.onhand_qty 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("I",1007,"") 
	# F3/F4 TO page forward/backward RETURN on line TO View
	INPUT ARRAY pa_prodledg WITHOUT DEFAULTS FROM sr_prodledg.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IE1","input-arr-pa_prodledg-3") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD tran_date 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_tran_date = pa_prodledg[idx].tran_date 
			DISPLAY pa_prodledg[idx].* TO sr_prodledg[scrn].* 
		AFTER FIELD tran_date 
			LET pa_prodledg[idx].tran_date = pr_tran_date 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF idx >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#U9001 "There are no more rows in the direction ...
					NEXT FIELD tran_date 
				END IF 
			END IF 
		BEFORE FIELD year_num 
			CASE pa_prodledg[idx].trantype_ind 
				WHEN "A" 
					CALL show_qty_adj(glob_rec_kandoouser.cmpy_code,pr_prodledg.part_code, 
					pr_prodledg.ware_code, 
					pa_prodledg[idx].tran_date, 
					pa_seq_num[idx].seq_num) 
				WHEN "C" 
					LET l_run_arg = "COMPANY_CODE=", trim(glob_rec_kandoouser.cmpy_code) 
					LET l_run_arg = trim(l_run_arg), " ", "CREDIT_NUMBER=", trim(pa_prodledg[idx].source_num) 
					CALL run_prog("A46",l_run_arg,"","","") #credit scan 

				WHEN "I" 
					CALL show_inv_issue(glob_rec_kandoouser.cmpy_code,pr_prodledg.part_code, 
					pr_prodledg.ware_code, 
					pa_prodledg[idx].tran_date, 
					pa_seq_num[idx].seq_num) 
				WHEN "J" 
					LET filter_text = 
					"prodledg.cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' ", 
					"AND prodledg.part_code = '", pr_prodledg.part_code,"' ", 
					"AND prodledg.ware_code = '", pr_prodledg.ware_code,"' " 
					LET filter_text2 = 
					"AND prodledg.tran_date = '", pa_prodledg[idx].tran_date,"' ", 
					"AND prodledg.seq_num = ", pa_seq_num[idx].seq_num 
					CALL run_prog("J92",filter_text,filter_text2,"","") 

				WHEN "P" 
					LET filter_text = 
					' ph.ware_code = \'', pr_prodledg.ware_code, '\' ', 
					'and pd.ref_text = \'', pr_prodledg.part_code, '\' ', 
					'and pa.tran_date = \'', pa_prodledg[idx].tran_date, '\' ', 
					'and pa.tran_num = \'', pa_prodledg[idx].source_num, '\' ' 
					CALL run_prog("R27",filter_text,"","","") 
				WHEN "R" 
					CALL show_inv_receipt(glob_rec_kandoouser.cmpy_code,pr_prodledg.part_code, 
					pr_prodledg.ware_code, 
					pa_prodledg[idx].tran_date, 
					pa_seq_num[idx].seq_num) 
				WHEN "S" 
					LET l_run_arg = "COMPANY_CODE=", trim(glob_rec_kandoouser.cmpy_code) 
					LET l_run_arg = trim(l_run_arg), " ", "INVOICE_NUMBER=", trim(pa_prodledg[idx].source_num) 
					CALL run_prog("A26",l_run_arg,"","","") #a26-invoice scan 

				WHEN "T" 
					CALL show_inv_transf(glob_rec_kandoouser.cmpy_code,pr_prodledg.part_code, 
					pr_prodledg.ware_code, 
					pa_prodledg[idx].tran_date, 
					pa_seq_num[idx].seq_num) 
				WHEN "U" 
					CALL show_cost_adj(glob_rec_kandoouser.cmpy_code,pr_prodledg.part_code, 
					pr_prodledg.ware_code, 
					pa_prodledg[idx].tran_date, 
					pa_seq_num[idx].seq_num) 
				OTHERWISE 
					LET msgresp = kandoomsg("I",7037,"") 
					# 7037 Invalid transation type detected
			END CASE 
			NEXT FIELD tran_date 
		AFTER ROW 
			DISPLAY pa_prodledg[idx].* TO sr_prodledg[scrn].* 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 
