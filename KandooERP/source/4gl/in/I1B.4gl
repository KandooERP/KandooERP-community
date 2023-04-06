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

###########################################################################
# Requires
# common\crhdwind.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# \brief module I1B allows the user TO scan the item ledger.

MAIN 
	DEFINE exit_status SMALLINT
	#Initial UI Init
	CALL setModuleId("I1B") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i112 with FORM "I112" 
	 CALL windecoration_i("I112") 

	WHILE exit_status = 0
		CALL I1B_main() RETURNING exit_status
	END WHILE
	CLOSE WINDOW i112 
END MAIN

FUNCTION I1B_main()	
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*
	MENU "Item ledger"
		COMMAND "Query Item Ledger"
			CALL select_prodledg() RETURNING l_rec_prodledg.* 
			CALL scan_prodledg(l_rec_prodledg.*)
			RETURN 0
		COMMAND "Exit"
			RETURN 1
	END MENU 
	
END FUNCTION  # I1B_main

 


FUNCTION select_prodledg() 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	CLEAR FORM 
	LET msgresp = kandoomsg("I",1001,"") 
	# 1001 Enter selection criteria - ESC TO continue
	LET l_rec_prodledg.tran_date = today - 30 
	
	INPUT BY NAME l_rec_prodledg.part_code, 
	l_rec_prodledg.ware_code, 
	l_rec_prodledg.tran_date WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I1B","input-l_rec_prodledg-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "Lookup"
			CASE 
				WHEN infield (part_code) 
					LET l_rec_prodledg.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME l_rec_prodledg.part_code 

					NEXT FIELD part_code 
				WHEN infield (ware_code) 
					LET l_rec_prodledg.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME l_rec_prodledg.ware_code 

					NEXT FIELD ware_code 
			END CASE 

		ON CHANGE part_code 
			SELECT product.* 
			INTO l_rec_product.* 
			FROM product 
			WHERE product.part_code = l_rec_prodledg.part_code 
				AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
			
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET msgresp = kandoomsg("I",9010,"") 
				# 9010 Product does NOT exist - Try window
				NEXT FIELD part_code 
			ELSE 
				DISPLAY l_rec_product.desc_text, 
				l_rec_product.desc2_text 
				TO product.desc_text, 
				product.desc2_text 

			END IF 
		
		ON CHANGE ware_code 
			SELECT warehouse.desc_text 
			INTO l_rec_warehouse.desc_text 
			FROM warehouse 
			WHERE ware_code = l_rec_prodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET msgresp = kandoomsg("I",9030,"") 
				# 9030 Warehouse does NOT exist - Try window
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY l_rec_warehouse.desc_text TO warehouse.desc_text 

			END IF 

#	Deleted the AFTER INPUT block that did redundant checks		ericv 2020-09-20

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		RETURN "" 
	ELSE 
		LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code
		RETURN l_rec_prodledg.* 
	END IF 
END FUNCTION 	# select_prodledg

FUNCTION scan_prodledg(p_rec_prodledg)
	DEFINE p_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_arr_rec_prodledg DYNAMIC ARRAY OF RECORD 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num, 
		trantype_ind LIKE prodledg.trantype_ind, 
		source_code LIKE prodledg.source_code,
		source_text LIKE prodledg.source_text, 
		source_num LIKE prodledg.source_num, 
		tran_qty LIKE prodledg.tran_qty, 
		cost_amt LIKE prodledg.cost_amt, 
		sales_amt LIKE prodledg.sales_amt 
	END RECORD
	DEFINE l_arr_rec_seqnum DYNAMIC ARRAY OF RECORD 
		seq_num LIKE prodledg.seq_num 
	END RECORD
	DEFINE l_filter_text STRING
	DEFINE l_filter_text2 STRING
	DEFINE l_idx SMALLINT
	DEFINE l_arr_curr SMALLINT 
	DEFINE l_scr_line SMALLINT
	DEFINE l_run_arg STRING 
	LET msgresp = kandoomsg("I",1002,"") 
	# 1002 Searching database - Please wait
	
	DECLARE crs_scan_prodledg CURSOR FOR 
	SELECT tran_date,
		year_num,
		period_num,
		trantype_ind,
		source_code,
		source_text,
		source_num,
		tran_qty,
		cost_amt,
		sales_amt,
		seq_num
	FROM prodledg 
	WHERE prodledg.part_code = p_rec_prodledg.part_code 
		AND prodledg.ware_code = p_rec_prodledg.ware_code 
		AND prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND prodledg.tran_date >= p_rec_prodledg.tran_date 
	ORDER BY prodledg.part_code, prodledg.ware_code, 
		prodledg.tran_date, prodledg.seq_num 
	
	LET l_idx = 1
	FOREACH crs_scan_prodledg INTO l_arr_rec_prodledg[l_idx].tran_date,
		l_arr_rec_prodledg[l_idx].year_num,
		l_arr_rec_prodledg[l_idx].period_num,
		l_arr_rec_prodledg[l_idx].trantype_ind,
		l_arr_rec_prodledg[l_idx].source_code,
		l_arr_rec_prodledg[l_idx].source_text,
		l_arr_rec_prodledg[l_idx].source_num,
		l_arr_rec_prodledg[l_idx].tran_qty,
		l_arr_rec_prodledg[l_idx].cost_amt,
		l_arr_rec_prodledg[l_idx].sales_amt,
		l_arr_rec_seqnum[l_idx].seq_num
		LET l_idx = l_idx + 1 
	END FOREACH 
	LET l_idx = l_idx - 1
	IF l_idx = 0 THEN 
		LET msgresp=kandoomsg("I",9101,"") 
		ERROR "No product ledgers satisfied the selection criteria"
		#9101 No product ledgers satisfied the selection criteria
		RETURN 
	END IF 

	LET msgresp = kandoomsg("I",1007,"") 
	# F3/F4 TO page forward/backward RETURN on line TO View
	DISPLAY ARRAY l_arr_rec_prodledg TO sr_prodledg.* 

		BEFORE DISPLAY
			CALL publish_toolbar("kandoo","I1B","input-arr-l_arr_rec_prodledg-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW
			LET l_arr_curr = arr_curr() 
			LET l_scr_line = scr_line() 

# These BEFORE FIELD tran_date and AFTER FIELD seem perfectly useless    ericv 2020-09-20

		# moving this block to ON ACTION
		ON ACTION ("VIEW PRODUCT","DOUBLECLICK")
			CASE l_arr_rec_prodledg[l_arr_curr].trantype_ind 
				WHEN "A" 
					CALL show_qty_adj(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[l_arr_curr].tran_date, 
					l_arr_rec_seqnum[l_arr_curr].seq_num) 
				WHEN "C" 
					CALL cr_disp_head(glob_rec_kandoouser.cmpy_code, l_arr_rec_prodledg[l_arr_curr].source_text, 
					l_arr_rec_prodledg[l_arr_curr].source_num) 
				WHEN "I" 
					CALL show_inv_issue(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[l_arr_curr].tran_date, 
					l_arr_rec_seqnum[l_arr_curr].seq_num) 
				WHEN "J" 
					LET l_filter_text = 
					"prodledg.cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' ", 
					"AND prodledg.part_code = '", p_rec_prodledg.part_code,"' ", 
					"AND prodledg.ware_code = '", p_rec_prodledg.ware_code,"' " 
					LET l_filter_text2 = 
					"AND prodledg.tran_date = '", l_arr_rec_prodledg[l_arr_curr].tran_date,"' ", 
					"AND prodledg.seq_num = ", l_arr_rec_seqnum[l_arr_curr].seq_num 
					CALL run_prog("J92",l_filter_text,l_filter_text2,"","") 
				WHEN "P" 
					LET l_filter_text = 
					' ph.ware_code = \'', p_rec_prodledg.ware_code, '\' ', 
					'and pd.ref_text = \'', p_rec_prodledg.part_code, '\' ', 
					'and pa.tran_date = \'', l_arr_rec_prodledg[l_arr_curr].tran_date, '\' ', 
					'and pa.tran_num = \'', l_arr_rec_prodledg[l_arr_curr].source_num, '\' ' 
					CALL run_prog("R27",l_filter_text,"","","") 
				WHEN "R" 
					CALL show_inv_receipt(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[l_arr_curr].tran_date, 
					l_arr_rec_seqnum[l_arr_curr].seq_num) 
				WHEN "S" 
					LET l_run_arg = "COMPANY_CODE=", trim(glob_rec_kandoouser.cmpy_code) 
					LET l_run_arg = trim(l_run_arg), " ", "INVOICE_NUMBER=", trim(l_arr_rec_prodledg[l_arr_curr].source_num) 
					CALL run_prog("A26",l_run_arg,"","","") #a26-invoice scan 

				WHEN "T" 
					CALL show_inv_transf(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[l_arr_curr].tran_date, 
					l_arr_rec_seqnum[l_arr_curr].seq_num) 
				WHEN "U" 
					CALL show_cost_adj(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[l_arr_curr].tran_date, 
					l_arr_rec_seqnum[l_arr_curr].seq_num) 
				WHEN "W" 
					LET msgresp = kandoomsg("I",7040,"") 
					# 7040 View window FOR type "W" NOT yet implemented
				WHEN "X" 
					CALL show_reclass(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[l_arr_curr].tran_date, 
					l_arr_rec_prodledg[l_arr_curr].source_num) 
				OTHERWISE 
					LET msgresp = kandoomsg("I",7037,"") 
					# 7037 Invalid transation type detected
			END CASE 


		ON KEY (control-w) 
			CALL kandoohelp("") 
	END DISPLAY 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 	# scan_prodledg
