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

	Source code beautified by beautify.pl on 2020-01-03 09:12:23	$Id: $
}

##- This menu path is used to review the changing quantities of a product that is available in a selected warehouse.  
##- All stock balances for specified products are current at the time of using this inquiry program.  
##- Modifications cannot be made via this menu path, nor is any pricing displayed.

# clean code priority 1 : done  ericv 2020-09-28
# clean code priority 2 :  done  ericv 2020-09-28
# clean code priority 3 : done  ericv 2020-09-28

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief This menu path is used to review the changing quantities of a product that is available in a selected warehouse.  
##- All stock balances for specified products are current at the time of using this inquiry program.  
##- Modifications cannot be made via this menu path, nor is any pricing displayed.


{
DEFINE pr_tran_date LIKE prodledg.tran_date
DEFINE runner STRING 
DEFINE where_clause STRING
}

MAIN 
	DEFINE exit_status SMALLINT
	#Initial UI Init
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	CALL setModuleId("I1C") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i114 with FORM "I114" 
	 CALL windecoration_i("I114") -- albo kd-758 

	CALL I1C_main() RETURNING exit_status

	CLOSE WINDOW i114 
END MAIN 

FUNCTION I1C_main()
	DEFINE l_rec_prodledg RECORD 
		part_code LIKE prodledg.part_code,
		ware_code LIKE prodledg.ware_code,
		tran_date LIKE prodledg.tran_date
	END RECORD

	MENU "IC1"
		COMMAND "Query" "Query a product in a warehouse"
			CALL query_prodledg() RETURNING l_rec_prodledg.*
			IF l_rec_prodledg.part_code IS NOT NULL 
			AND l_rec_prodledg.ware_code IS NOT NULL THEN
				CALL scan_prodledg(l_rec_prodledg.*) 
			END IF
		COMMAND "Exit" "Exit Program"
			EXIT PROGRAM
	END MENU 

END FUNCTION # I1C_main()

FUNCTION query_prodledg()
	DEFINE l_rec_prodledg RECORD 
		part_code LIKE prodledg.part_code,
		ware_code LIKE prodledg.ware_code,
		tran_date LIKE prodledg.tran_date
	END RECORD
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
			CALL publish_toolbar("kandoo","I1C","input-lr_prodledg-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield (part_code) 
			LET l_rec_prodledg.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME l_rec_prodledg.part_code 
		
		ON ACTION "LOOKUP" infield  (ware_code) 
			LET l_rec_prodledg.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME l_rec_prodledg.ware_code 
		
		ON CHANGE  part_code 
			SELECT product.desc_text,
				product.desc2_text 
			INTO l_rec_product.desc_text,
				l_rec_product.desc2_text
			FROM product 
			WHERE product.part_code = l_rec_prodledg.part_code 
			AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = notfound THEN 
				LET msgresp = kandoomsg("I",9010,"") 
				# 9010 Product does NOT exist - Try window
				NEXT FIELD part_code 
			ELSE 
				DISPLAY BY NAME l_rec_product.desc_text, 
					l_rec_product.desc2_text 
			END IF 
		
		ON CHANGE  ware_code 
			SELECT warehouse.desc_text 
			INTO l_rec_warehouse.desc_text 
			FROM warehouse 
			WHERE ware_code = l_rec_prodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = notfound THEN 
				LET msgresp = kandoomsg("I",9030,"") 
				# 9030 Warehouse does NOT exist - Try window
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY BY NAME l_rec_warehouse.desc_text
			END IF 
			# removed all redundant pk checks ericv 2020-09-27
	END INPUT 
	IF int_flag OR quit_flag THEN 
		INITIALIZE l_rec_prodledg.* TO NULL
	END IF 
	RETURN l_rec_prodledg.* 
END FUNCTION 	# query_prodledg 


FUNCTION scan_prodledg(p_rec_prodledg) 
	DEFINE p_rec_prodledg RECORD 
		part_code LIKE prodledg.part_code,
		ware_code LIKE prodledg.ware_code,
		tran_date LIKE prodledg.tran_date
	END RECORD
	DEFINE l_arr_rec_prodledg DYNAMIC ARRAY OF RECORD 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num, 
		trantype_ind LIKE prodledg.trantype_ind, 
		source_code LIKE prodledg.source_code,
		source_text LIKE prodledg.source_text, 
		source_num LIKE prodledg.source_num, 
		tran_qty LIKE prodledg.tran_qty, 
		bal_amt LIKE prodledg.bal_amt 
	END RECORD
	DEFINE l_arr_seqnum DYNAMIC ARRAY OF RECORD 
		seq_num LIKE prodledg.seq_num 
	END RECORD 

	DEFINE lr_prodledg RECORD LIKE prodledg.*
	DEFINE pr_tran_date LIKE prodledg.tran_date
	DEFINE where_clause STRING 
	DEFINE where_clause2 STRING 
	DEFINE l_run_arg STRING 
	DEFINE idx SMALLINT
	DEFINE arr_curr SMALLINT
	DEFINE scr_line SMALLINT

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
		bal_amt,
		seq_num
	FROM prodledg 
	WHERE part_code = p_rec_prodledg.part_code 
		AND ware_code = p_rec_prodledg.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tran_date >= p_rec_prodledg.tran_date 
	ORDER BY seq_num 
	
	LET idx = 1 
	FOREACH crs_scan_prodledg INTO l_arr_rec_prodledg[idx].tran_date,
		l_arr_rec_prodledg[idx].year_num,
		l_arr_rec_prodledg[idx].period_num,
		l_arr_rec_prodledg[idx].trantype_ind,
		l_arr_rec_prodledg[idx].source_code,
		l_arr_rec_prodledg[idx].source_text,
		l_arr_rec_prodledg[idx].source_num,
		l_arr_rec_prodledg[idx].tran_qty,
		l_arr_rec_prodledg[idx].bal_amt,
		l_arr_seqnum[idx].seq_num
		LET idx = idx + 1 
	END FOREACH 
	LET idx = idx -1 
	IF idx = 0 THEN 
		LET msgresp=kandoomsg("I",9101,"") 
		#9101 No product ledgers satisfied the selection criteria
		RETURN 
	END IF 
		
	CALL set_count(idx) 
	# INPUT ARRAY transformed to DISPLAY ARRAY ericv 2020-09-28 
	DISPLAY ARRAY l_arr_rec_prodledg TO sr_prodledg.* 
	
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","I1C","input-arr-l_arr_rec_prodledg-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW
			LET arr_curr = arr_curr() 
			LET scr_line = scr_line() 

		# BEFORE FIELD useless ericv 2020-09-27
		# deleted all cursor navigation  ericv 2020-09-27
		
		-- This block must be part of ON ACTION, not before field
		ON ACTION ("VIEW PRODUCT","DOUBLECLICK")
			CASE l_arr_rec_prodledg[arr_curr].trantype_ind 
				WHEN "A" 
					CALL show_qty_adj(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code,p_rec_prodledg.ware_code,l_arr_rec_prodledg[arr_curr].tran_date,l_arr_seqnum[arr_curr].seq_num) 

				WHEN "C" 
					LET l_run_arg = "COMPANY_CODE=", trim(glob_rec_kandoouser.cmpy_code) 
					LET l_run_arg = trim(l_run_arg), " ", "CREDIT_NUMBER=", trim(l_arr_rec_prodledg[arr_curr].source_num) 
					CALL run_prog("A46",l_run_arg,"","","") #credit scan 

				WHEN "I" 
					CALL show_inv_issue(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code,p_rec_prodledg.ware_code, l_arr_rec_prodledg[arr_curr].tran_date,l_arr_seqnum[arr_curr].seq_num) 

				WHEN "J" 
					LET where_clause = 
					"prodledg.cmpy_code='", glob_rec_kandoouser.cmpy_code,"' ", 
					"AND prodledg.part_code='", p_rec_prodledg.part_code,"' ", 
					"AND prodledg.ware_code='", p_rec_prodledg.ware_code,"' " 
					LET where_clause2 = 
					"AND prodledg.tran_date='", l_arr_rec_prodledg[arr_curr].tran_date,"' ", 
					"AND prodledg.seq_num=", l_arr_seqnum[arr_curr].seq_num 
					CALL run_prog("J92",where_clause,where_clause2,"","") 

				WHEN "P" 
					LET where_clause = 
					" ph.ware_code = '", p_rec_prodledg.ware_code, "' ", 
					"AND pd.ref_text = '", p_rec_prodledg.part_code, "' ", 
					"AND pa.tran_date = '", l_arr_rec_prodledg[arr_curr].tran_date, "' ", 
					"AND pa.tran_num = '", l_arr_rec_prodledg[arr_curr].source_num, "' " 
					CALL run_prog("R27",where_clause,"","","") 

				WHEN "R" 
					CALL show_inv_receipt(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[arr_curr].tran_date, 
					l_arr_seqnum[arr_curr].seq_num) 

				WHEN "S" 
					LET l_run_arg = "COMPANY_CODE=", trim(glob_rec_kandoouser.cmpy_code) 
					LET l_run_arg = trim(l_run_arg), " ", "INVOICE_NUMBER=", trim(l_arr_rec_prodledg[arr_curr].source_num) 
					CALL run_prog("A26",l_run_arg,"","","") #a26-invoice scan 

				WHEN "T" 
					CALL show_inv_transf(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[arr_curr].tran_date, 
					l_arr_seqnum[arr_curr].seq_num) 
				WHEN "U" 
					CALL show_cost_adj(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[arr_curr].tran_date, 
					l_arr_seqnum[arr_curr].seq_num) 
				WHEN "W" 
					LET msgresp = kandoomsg("I",7040,"") 
					# 7040 View window FOR type "W" NOT yet implemented
				WHEN "X" 
					CALL show_reclass(glob_rec_kandoouser.cmpy_code,p_rec_prodledg.part_code, 
					p_rec_prodledg.ware_code, 
					l_arr_rec_prodledg[arr_curr].tran_date, 
					l_arr_rec_prodledg[arr_curr].source_num) 
				OTHERWISE 
					LET msgresp = kandoomsg("I",7037,"") 
					# 7037 Invalid transation type detected
			END CASE 

	END DISPLAY 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 	# scan_prodledg
