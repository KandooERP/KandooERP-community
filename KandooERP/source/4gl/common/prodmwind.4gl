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

	Source code beautified by beautify.pl on 2020-01-02 10:35:29	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
############################################################
# Module prodmwind.4gl allows the user TO scan the FIFO costs.
# Module prodmwind.4gl  allows the user TO scan Cost Ledgers.
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
#DEFINE glob_rec_cmpy LIKE company.cmpy_code #not used
#DEFINE l_msgresp LIKE language.yes_flag
DEFINE modu_arr_rec_prodledg DYNAMIC ARRAY OF #array[200] OF RECORD 
	RECORD 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num, 
		trantype_ind LIKE prodledg.trantype_ind, 
		source_text LIKE prodledg.source_text, 
		source_num LIKE prodledg.source_num, 
		tran_qty DECIMAL(7,2), 
		cost_amt DECIMAL(10,2), 
		sales_amt DECIMAL(11,2), 
		margin_per CHAR(6) 
	END RECORD 
DEFINE modu_arr_rec_seq_num DYNAMIC ARRAY OF #array[200] OF RECORD 
	RECORD 
		seq_num LIKE prodledg.seq_num 
	END RECORD 
DEFINE modu_tran_date LIKE prodledg.tran_date 
DEFINE modu_rec_product RECORD LIKE product.* 
DEFINE modu_rec_warehouse RECORD LIKE warehouse.* 
DEFINE modu_rec_prodstatus RECORD LIKE prodstatus.* 
DEFINE modu_rec_prodledg RECORD LIKE prodledg.* 
DEFINE modu_runner CHAR(512) 
DEFINE modu_filter_text CHAR(512) 
DEFINE modu_idx SMALLINT 


############################################################
# FUNCTION product_margin_inquiry(p_cmpy, p_part_code )
#
#
############################################################
FUNCTION product_margin_inquiry(p_cmpy,p_part_code ) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_ware_code LIKE warehouse.ware_code 
	DEFINE l_tran_date LIKE prodledg.tran_date 
	DEFINE l_ret_value SMALLINT 

	OPEN WINDOW i185 with FORM "I185" 
	CALL windecoration_i("I185") 

	IF p_part_code IS NOT NULL THEN 
		LET modu_rec_prodledg.part_code = p_part_code 
		CALL prm_select_ware(p_cmpy,p_part_code) 
		RETURNING l_ret_value, l_ware_code, l_tran_date 
		IF l_ret_value THEN 
			CALL prm_scan_prodledg(p_cmpy,p_part_code, l_ware_code, l_tran_date) 
		END IF 
	ELSE 
		CALL prm_select_prodledg(p_cmpy) RETURNING 
		l_ret_value, p_part_code, l_ware_code, l_tran_date 
		IF l_ret_value THEN 
			CALL prm_scan_prodledg(p_cmpy,p_part_code, l_ware_code, l_tran_date) 
		END IF 
	END IF 
	CLOSE WINDOW i185 
END FUNCTION 


############################################################
# FUNCTION prm_select_ware(p_cmpy,p_part_code)
#
#
############################################################
FUNCTION prm_select_ware(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_ware_code LIKE warehouse.ware_code 
	DEFINE l_ret_value SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET modu_rec_prodledg.part_code = p_part_code 
	DISPLAY modu_rec_prodledg.part_code TO prodledg.part_code 
	SELECT * INTO modu_rec_product.* FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = modu_rec_prodledg.part_code 
	IF status = notfound THEN 
		LET l_msgresp=kandoomsg("I",5010,modu_rec_prodledg.part_code) 
		#5010" Logic error: Product code NOT found ????"
		RETURN false, "", "" 
	END IF 
	DISPLAY modu_rec_product.desc_text, 
	modu_rec_product.desc2_text 
	TO product.desc_text, 
	product.desc2_text 
	LET l_msgresp = kandoomsg("U",1020,"Input") 
	#1020 Enter VALUE Details;  OK TO Continue.
	LET modu_rec_prodledg.tran_date = today - 30 
	INPUT BY NAME modu_rec_prodledg.ware_code, 
	modu_rec_prodledg.tran_date WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","prodmwind","input-prodledg-1") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (ware_code) 
			LET modu_rec_prodledg.ware_code = show_ware(p_cmpy) 
			DISPLAY BY NAME modu_rec_prodledg.ware_code 

			NEXT FIELD ware_code 

		AFTER FIELD ware_code 
			SELECT warehouse.desc_text INTO modu_rec_warehouse.desc_text FROM warehouse 
			WHERE ware_code = modu_rec_prodledg.ware_code 
			AND cmpy_code = p_cmpy 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("I",9030,"") 
				# 9030 Warehouse does NOT exist - Try window
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY modu_rec_warehouse.desc_text TO warehouse.desc_text 

			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT warehouse.desc_text INTO modu_rec_warehouse.desc_text FROM warehouse 
				WHERE ware_code = modu_rec_prodledg.ware_code 
				AND cmpy_code = p_cmpy 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("I",9030,"") 
					# 9030 Warehouse does NOT exist - Try window
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY modu_rec_warehouse.desc_text TO warehouse.desc_text 

				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false, "", "" 
	END IF 
	IF modu_rec_prodledg.tran_date IS NULL THEN 
		LET modu_rec_prodledg.tran_date = today - 30 
	END IF 
	RETURN true, modu_rec_prodledg.ware_code, modu_rec_prodledg.tran_date 
END FUNCTION 


############################################################
# FUNCTION prm_select_prodledg(p_cmpy)
#
#
############################################################
FUNCTION prm_select_prodledg(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_part LIKE product.part_code 
	DEFINE l_ware_code LIKE warehouse.ware_code 
	DEFINE l_tran_date LIKE prodledg.tran_date 
	DEFINE l_ret_value SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("I",1030,"") 
	#1030 Enter Warehouse Code;  OK TO Continue.
	LET modu_rec_prodledg.tran_date = today - 30 

	INPUT BY NAME modu_rec_prodledg.part_code, 
	modu_rec_prodledg.ware_code, 
	modu_rec_prodledg.tran_date WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","prodmwind","input-prodledg-2") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (ware_code) 
			LET modu_rec_prodledg.ware_code = show_ware(p_cmpy) 
			DISPLAY BY NAME modu_rec_prodledg.ware_code 

			NEXT FIELD ware_code 

		AFTER FIELD part_code 
			SELECT product.* INTO modu_rec_product.* FROM product 
			WHERE product.part_code = modu_rec_prodledg.part_code 
			AND product.cmpy_code = p_cmpy 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("I",9010,"") 
				# 9010 Product does NOT exist - Try window
				NEXT FIELD part_code 
			ELSE 
				DISPLAY modu_rec_product.desc_text, 
				modu_rec_product.desc2_text 
				TO product.desc_text, 
				product.desc2_text 
			END IF 

		AFTER FIELD ware_code 
			SELECT warehouse.desc_text INTO modu_rec_warehouse.desc_text FROM warehouse 
			WHERE ware_code = modu_rec_prodledg.ware_code 
			AND cmpy_code = p_cmpy 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("I",9030,"") 
				# 9030 Warehouse does NOT exist - Try window
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY modu_rec_warehouse.desc_text TO warehouse.desc_text 

			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT product.* INTO modu_rec_product.* FROM product 
				WHERE part_code = modu_rec_prodledg.part_code 
				AND cmpy_code = p_cmpy 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("I",9010,"") 
					# 9010 Product does NOT exist - Try window
					NEXT FIELD part_code 
				ELSE 
					DISPLAY modu_rec_product.desc_text, 
					modu_rec_product.desc2_text 
					TO product.desc_text, 
					product.desc2_text 

				END IF 
				SELECT warehouse.desc_text INTO modu_rec_warehouse.desc_text FROM warehouse 
				WHERE ware_code = modu_rec_prodledg.ware_code 
				AND cmpy_code = p_cmpy 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("I",9030,"") 
					# 9030 Warehouse does NOT exist - Try window
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY modu_rec_warehouse.desc_text TO warehouse.desc_text 

				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false, "", "", "" 
	END IF 
	RETURN true, modu_rec_prodledg.part_code, modu_rec_prodledg.ware_code, modu_rec_prodledg.tran_date 
END FUNCTION 


############################################################
# FUNCTION prm_scan_prodledg(p_cmpy, p_part_code, p_ware_code, p_tran_date)
#
#
############################################################
FUNCTION prm_scan_prodledg(p_cmpy,p_part_code,p_ware_code,p_tran_date) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_tran_date LIKE prodledg.tran_date 
	DEFINE l_ret_value SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("I",1002,"") 
	# 1002 Searching database - Please wait
	DECLARE c_prodledg CURSOR FOR 
	SELECT prodledg.* INTO modu_rec_prodledg.* FROM prodledg 
	WHERE prodledg.part_code = p_part_code 
	AND prodledg.ware_code = p_ware_code 
	AND prodledg.cmpy_code = p_cmpy 
	AND prodledg.tran_date >= p_tran_date 
	ORDER BY prodledg.seq_num 
	LET modu_idx = 0 

	FOREACH c_prodledg 
		LET modu_idx = modu_idx + 1 
		LET modu_arr_rec_prodledg[modu_idx].tran_date = modu_rec_prodledg.tran_date 
		LET modu_arr_rec_prodledg[modu_idx].year_num = modu_rec_prodledg.year_num 
		LET modu_arr_rec_prodledg[modu_idx].period_num = modu_rec_prodledg.period_num 
		LET modu_arr_rec_prodledg[modu_idx].trantype_ind = modu_rec_prodledg.trantype_ind 
		LET modu_arr_rec_prodledg[modu_idx].source_text = modu_rec_prodledg.source_text 
		LET modu_arr_rec_prodledg[modu_idx].source_num = modu_rec_prodledg.source_num 
		LET modu_arr_rec_prodledg[modu_idx].tran_qty = modu_rec_prodledg.tran_qty 
		LET modu_arr_rec_prodledg[modu_idx].cost_amt = modu_rec_prodledg.cost_amt 
		LET modu_arr_rec_prodledg[modu_idx].sales_amt = modu_rec_prodledg.sales_amt * 
		modu_rec_prodledg.tran_qty 
		IF modu_rec_prodledg.sales_amt = 0 THEN 
			LET modu_arr_rec_prodledg[modu_idx].margin_per = 0 USING "##&.&&" 
		ELSE 
			LET modu_arr_rec_prodledg[modu_idx].margin_per = ((modu_rec_prodledg.sales_amt - 
			modu_rec_prodledg.cost_amt) * 100) / 
			modu_rec_prodledg.sales_amt USING "##&.&&" 
		END IF 
		LET modu_arr_rec_seq_num[modu_idx].seq_num = modu_rec_prodledg.seq_num 
		IF modu_idx > 200 THEN 
			LET l_msgresp=kandoomsg("I",9100,200) 
			#9100 First 200 product ledgers selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF modu_idx = 0 THEN 
		LET l_msgresp=kandoomsg("I",9101,"") 
		#9101 No product ledgers satisfied the selection criteria
		RETURN 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	SELECT onhand_qty INTO modu_rec_prodstatus.onhand_qty FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = modu_rec_prodledg.part_code 
	AND ware_code = modu_rec_prodledg.ware_code 

	DISPLAY modu_rec_prodstatus.onhand_qty TO prodstatus.onhand_qty 
	#   CALL set_count(modu_idx)
	LET l_msgresp = kandoomsg("I",1008,"") 

	# F3/F4 TO page forward/backward; OK TO continue
	INPUT ARRAY modu_arr_rec_prodledg WITHOUT DEFAULTS FROM sr_prodledg.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","prodmwind","input-arr-prodledg-1") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD tran_date 
			LET modu_idx = arr_curr() 
			#         LET scrn = scr_line()
			LET p_tran_date = modu_arr_rec_prodledg[modu_idx].tran_date 
			#         DISPLAY modu_arr_rec_prodledg[modu_idx].* TO sr_prodledg[scrn].*

		AFTER FIELD tran_date 
			LET modu_arr_rec_prodledg[modu_idx].tran_date = p_tran_date 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF modu_arr_rec_prodledg[modu_idx+1].tran_date IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("I",9001,"") 
					# There are no more rows in the direction you are going.
					NEXT FIELD tran_date 
				END IF 
			END IF 

		BEFORE FIELD year_num 
			NEXT FIELD tran_date 
			#      AFTER ROW
			#         DISPLAY modu_arr_rec_prodledg[modu_idx].* TO sr_prodledg[scrn].*

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
END FUNCTION 
