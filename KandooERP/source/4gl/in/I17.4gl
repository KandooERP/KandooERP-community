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

	Source code beautified by beautify.pl on 2020-01-03 09:12:22	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# I17 Allows the user TO enter AND maintain Supplier Product Quotes

GLOBALS 
	DEFINE 
	pr_loadparms RECORD LIKE loadparms.*, 
	pr_format_ind LIKE loadparms.format_ind, 
	err_message CHAR(60) 
END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("I17") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 


	OPTIONS 
	INSERT KEY f1, 
	DELETE KEY f36 

	DECLARE c_loadparms CURSOR FOR 
	SELECT * INTO pr_loadparms.* FROM loadparms 
	WHERE module_code = TRAN_TYPE_INVOICE_IN 
	AND ( format_ind = "4" OR format_ind = '5') 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY load_ind 
	OPEN c_loadparms 
	FETCH c_loadparms INTO pr_loadparms.* 
	CLOSE c_loadparms 
	LET pr_format_ind = pr_loadparms.format_ind 

	OPEN WINDOW w164 with FORM "I164" 
	 CALL windecoration_i("I164") -- albo kd-758 

	WHILE select_prodquotes() 
		CALL scan_prodquotes() 
	END WHILE 

	CLOSE WINDOW w164 
END MAIN 


FUNCTION select_prodquotes() 
	DEFINE 
	query_text CHAR(300), 
	where_text CHAR(200) 

	CLEAR FORM 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON vend_code, 
	part_code, 
	oem_text, 
	cost_amt, 
	curr_code, 
	expiry_date 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT rowid, prodquote.* FROM prodquote", 
		" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' AND ", 
		where_text clipped, 
		" ORDER BY vend_code, part_code" 
		PREPARE s_prodquote FROM query_text 
		DECLARE c_prodquote CURSOR FOR s_prodquote 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_prodquotes() 
	DEFINE 
	pr_prodquote RECORD LIKE prodquote.*, 
	pa_rowids array[1000] OF INTEGER, 
	pa_prodquote array[1000] OF RECORD 
		scroll_flag CHAR(1), 
		vend_code LIKE prodquote.vend_code, 
		part_code LIKE prodquote.part_code, 
		oem_text LIKE prodquote.oem_text, 
		cost_amt LIKE prodquote.cost_amt, 
		curr_code LIKE prodquote.curr_code, 
		expiry_date LIKE prodquote.expiry_date 
	END RECORD, 
	pr_scroll_flag CHAR(1), 
	pr_rowid INTEGER, 
	pr_curr,pr_cnt,idx,scrn,del_cnt,idx2 SMALLINT 

	LET idx = 0 
	FOREACH c_prodquote INTO pr_rowid, pr_prodquote.* 
		LET idx = idx + 1 
		LET pa_rowids[idx] = pr_rowid 
		LET pa_prodquote[idx].vend_code = pr_prodquote.vend_code 
		LET pa_prodquote[idx].part_code = pr_prodquote.part_code 
		LET pa_prodquote[idx].oem_text = pr_prodquote.oem_text 
		LET pa_prodquote[idx].cost_amt = pr_prodquote.cost_amt 
		LET pa_prodquote[idx].curr_code = pr_prodquote.curr_code 
		LET pa_prodquote[idx].expiry_date = pr_prodquote.expiry_date 
		IF idx = 1000 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113" idx entries selected"
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_prodquote[idx].* TO NULL 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("I",1128,"") 
	#1128 "F1 TO Add - F2 TO Delete - RETURN TO Edit - VALUE
	INPUT ARRAY pa_prodquote WITHOUT DEFAULTS FROM sr_prodquote.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I17","input-pa_prodquote-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_prodquote[idx].scroll_flag 
			DISPLAY pa_prodquote[idx].* TO sr_prodquote[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_prodquote[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_prodquote[idx].scroll_flag TO sr_prodquote[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF idx >= arr_count() THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				ELSE 
					IF pa_prodquote[idx+1].vend_code IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET msgresp=kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD vend_code 
			IF pa_prodquote[idx].vend_code IS NOT NULL THEN 
				LET idx = arr_curr() 
				LET pr_rowid = edit_prodquote(pa_rowids[idx]) 
				OPTIONS INSERT KEY f1 
				IF pr_rowid != 0 THEN 
					SELECT * INTO pr_prodquote.* FROM prodquote 
					WHERE rowid = pr_rowid 
					LET pa_prodquote[idx].vend_code = pr_prodquote.vend_code 
					LET pa_prodquote[idx].part_code = pr_prodquote.part_code 
					LET pa_prodquote[idx].oem_text = pr_prodquote.oem_text 
					LET pa_prodquote[idx].cost_amt = pr_prodquote.cost_amt 
					LET pa_prodquote[idx].curr_code = pr_prodquote.curr_code 
					LET pa_prodquote[idx].expiry_date = pr_prodquote.expiry_date 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET pr_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				LET pr_rowid = edit_prodquote(0) 
				OPTIONS INSERT KEY f1 
				IF pr_rowid = 0 THEN 
					FOR idx = pr_curr TO pr_cnt 
						LET pa_prodquote[idx].* = pa_prodquote[idx+1].* 
						IF idx = pr_cnt THEN 
							INITIALIZE pa_prodquote[idx].* TO NULL 
						END IF 
						IF scrn <= 10 THEN 
							DISPLAY pa_prodquote[idx].* TO sr_prodquote[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					LET scrn = scr_line() 
				ELSE 
					FOR idx2 = (pr_cnt+1) TO (idx + 1) step -1 
						LET pa_rowids[idx2] = pa_rowids[idx2-1] 
					END FOR 
					SELECT * INTO pr_prodquote.* 
					FROM prodquote 
					WHERE rowid = pr_rowid 
					LET pa_prodquote[idx].vend_code = pr_prodquote.vend_code 
					LET pa_prodquote[idx].part_code = pr_prodquote.part_code 
					LET pa_prodquote[idx].oem_text = pr_prodquote.oem_text 
					LET pa_prodquote[idx].cost_amt = pr_prodquote.cost_amt 
					LET pa_prodquote[idx].curr_code = pr_prodquote.curr_code 
					LET pa_prodquote[idx].expiry_date= pr_prodquote.expiry_date 
					LET pa_rowids[idx] = pr_rowid 
				END IF 
			ELSE 
				IF idx > 1 THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows....
				END IF 
			END IF 
		ON KEY (F2) 
			IF pa_prodquote[idx].scroll_flag IS NULL THEN 
				LET pa_prodquote[idx].scroll_flag = "*" 
				LET del_cnt = del_cnt + 1 
			ELSE 
				LET pa_prodquote[idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
		ON KEY (F8) 
			IF delete_prodquote() THEN 
				EXIT INPUT 
			END IF 
		AFTER ROW 
			DISPLAY pa_prodquote[idx].* TO sr_prodquote[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		-- AND WHERE was it opened? CLOSE WINDOW W152
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_cnt > 0 THEN 
			LET msgresp = kandoomsg("I",8009,del_cnt) 
			#8009 Confirm TO Delete ",del_cnt," Product Quotation(s)? (Y/N)"
			IF msgresp = "Y" THEN 
				BEGIN WORK 
					FOR idx = 1 TO arr_count() 
						IF pa_prodquote[idx].scroll_flag = "*" THEN 
							DELETE FROM prodquote 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND vend_code = pa_prodquote[idx].vend_code 
							AND part_code = pa_prodquote[idx].part_code 
							AND expiry_date = pa_prodquote[idx].expiry_date 
						END IF 
					END FOR 
				COMMIT WORK 
			END IF 
		END IF 
	END IF 
END FUNCTION 


FUNCTION edit_prodquote(pr_rowid) 
	DEFINE 
	pr_rowid INTEGER, 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_currency RECORD LIKE currency.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_product RECORD LIKE product.*, 
	pr_temp_text CHAR(30), 
	pr_tmp_rowid INTEGER, 
	pr_sqlerrd INTEGER 

	OPEN WINDOW i165 with FORM "I165" 
	 CALL windecoration_i("I165") -- albo kd-758 
	LET msgresp = kandoomsg("I",1129,"") 
	#1129 "Enter Product Quotation Details - ESC TO Continue"
	INITIALIZE pr_prodquote.* TO NULL 
	INITIALIZE pr_product.* TO NULL 

	IF pr_rowid != 0 THEN 
		SELECT * INTO pr_prodquote.* FROM prodquote 
		WHERE rowid = pr_rowid 
		SELECT * INTO pr_vendor.* FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = pr_prodquote.vend_code 
		SELECT * INTO pr_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_prodquote.part_code 
	ELSE 
		INITIALIZE pr_product.* TO NULL 
		INITIALIZE pr_vendor.* TO NULL 
		LET pr_prodquote.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_prodquote.list_amt = 0 
		LET pr_prodquote.break_qty= 0 
		LET pr_prodquote.cost_amt = 0 
		LET pr_prodquote.freight_amt = 0 
		LET pr_prodquote.curr_code = "" 
		LET pr_prodquote.frgt_curr_code = "" 
		LET pr_prodquote.lead_time_qty = 0 
		LET pr_prodquote.entry_date = today 
		LET pr_prodquote.expiry_date = today 
		LET pr_prodquote.desc_text = "" 
		LET pr_prodquote.status_ind = "1" 
		LET pr_prodquote.format_ind = pr_format_ind 
	END IF 
	IF pr_prodquote.status_ind IS NULL THEN 
		LET pr_prodquote.status_ind = "1" 
	END IF 
	DISPLAY BY NAME pr_prodquote.vend_code, 
	pr_vendor.name_text, 
	pr_prodquote.part_code, 
	pr_prodquote.oem_text, 
	pr_prodquote.barcode_text, 
	pr_prodquote.curr_code, 
	pr_prodquote.cost_amt, 
	pr_prodquote.frgt_curr_code, 
	pr_prodquote.freight_amt, 
	pr_prodquote.list_amt, 
	pr_prodquote.break_qty, 
	pr_prodquote.lead_time_qty, 
	pr_prodquote.expiry_date, 
	pr_prodquote.desc_text, 
	pr_prodquote.status_ind, 
	pr_prodquote.format_ind 

	DISPLAY pr_product.desc_text, 
	pr_product.desc2_text 
	TO prod_desc, 
	prod_desc2 

	INPUT BY NAME pr_prodquote.vend_code, 
	pr_prodquote.part_code, 
	pr_prodquote.oem_text, 
	pr_prodquote.barcode_text, 
	pr_prodquote.cost_amt, 
	pr_prodquote.curr_code, 
	pr_prodquote.freight_amt, 
	pr_prodquote.frgt_curr_code, 
	pr_prodquote.list_amt, 
	pr_prodquote.break_qty, 
	pr_prodquote.lead_time_qty, 
	pr_prodquote.expiry_date, 
	pr_prodquote.desc_text, 
	pr_prodquote.status_ind, 
	pr_prodquote.format_ind 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I17","input-pa_prodquote-2") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 


		ON KEY (control-b) infield (part_code) 
			LET pr_temp_text = show_item(glob_rec_kandoouser.cmpy_code) 
			IF pr_temp_text IS NOT NULL THEN 
				LET pr_prodquote.part_code = pr_temp_text 
			END IF 
			NEXT FIELD part_code 

		ON KEY (control-b) infield (vend_code) 
			LET pr_temp_text = show_vend(glob_rec_kandoouser.cmpy_code,pr_prodquote.vend_code) 
			IF pr_temp_text IS NOT NULL THEN 
				LET pr_prodquote.vend_code = pr_temp_text 
			END IF 
			NEXT FIELD vend_code 

		ON KEY (control-b) infield (curr_code) 
			LET pr_temp_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF pr_temp_text IS NOT NULL THEN 
				LET pr_prodquote.curr_code = pr_temp_text 
			END IF 
			NEXT FIELD curr_code 

		ON KEY (control-b) infield (frgt_curr_code) 
			LET pr_temp_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF pr_temp_text IS NOT NULL THEN 
				LET pr_prodquote.frgt_curr_code = pr_temp_text 
			END IF 
			NEXT FIELD frgt_curr_code 


		AFTER FIELD vend_code 
			IF pr_prodquote.vend_code IS NULL THEN 
				LET msgresp=kandoomsg("P",1022,"") 
				#1022 Vendor code must be entered
				NEXT FIELD vend_code 
			ELSE 
				SELECT * INTO pr_vendor.* 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pr_prodquote.vend_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("P",9105,"") 
					#9105" Vendor NOT found - try window"
					NEXT FIELD vend_code 
				ELSE 
					IF pr_rowid = 0 THEN 
						LET pr_prodquote.curr_code = pr_vendor.currency_code 
						LET pr_prodquote.frgt_curr_code = pr_vendor.currency_code 
						DISPLAY BY NAME pr_prodquote.curr_code, 
						pr_prodquote.frgt_curr_code 

					END IF 
					DISPLAY BY NAME pr_vendor.name_text 

				END IF 
			END IF 

		AFTER FIELD part_code 
			IF pr_prodquote.part_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9013,"") 
				#9013 Product Code must be entered
				NEXT FIELD part_code 
			ELSE 
				SELECT * INTO pr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_prodquote.part_code 
				IF status = notfound THEN 
					IF pr_prodquote.format_ind = 5 THEN 
						SELECT unique 1 FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND oem_text = pr_prodquote.part_code 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("I",9010,"") 
							#9105" Product NOT found - try window"
							NEXT FIELD part_code 
						ELSE 
							LET pr_prodquote.oem_text = pr_prodquote.part_code 
							DISPLAY "OEM Text", 
							pr_prodquote.oem_text 
							TO prod_desc, 
							oem_text 

						END IF 
					ELSE 
						LET msgresp=kandoomsg("I",9010,"") 
						#9105" Product NOT found - try window"
						NEXT FIELD part_code 
					END IF 
				ELSE 
					DISPLAY pr_product.desc_text 
					TO prod_desc 

					IF pr_prodquote.format_ind = '5' THEN 
						LET pr_prodquote.oem_text = pr_product.oem_text 
						DISPLAY pr_product.oem_text 
						TO oem_text 

					END IF 
				END IF 
			END IF 

		BEFORE FIELD oem_text 
			IF pr_prodquote.format_ind = '5' THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD curr_code 
			IF pr_prodquote.curr_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9261,"") 
				#9027 Currency Code must be entered
				NEXT FIELD curr_code 
			END IF 
			SELECT * INTO pr_currency.* 
			FROM currency 
			WHERE currency_code = pr_prodquote.curr_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9073,"") 
				#9073 Currency Code NOT found - Try WIndow
				NEXT FIELD curr_code 
			END IF 
		AFTER FIELD frgt_curr_code 
			IF pr_prodquote.frgt_curr_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9261,"") 
				#9027 Currency Code must be entered
				NEXT FIELD frgt_curr_code 
			END IF 
			SELECT * INTO pr_currency.* 
			FROM currency 
			WHERE currency_code = pr_prodquote.frgt_curr_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9073,"") 
				#9073 Currency Code NOT found - Try WIndow
				NEXT FIELD frgt_curr_code 
			END IF 
		AFTER FIELD cost_amt 
			IF pr_prodquote.cost_amt IS NULL THEN 
				LET pr_prodquote.cost_amt = 0 
				DISPLAY BY NAME pr_prodquote.cost_amt 

			END IF 
		AFTER FIELD list_amt 
			IF pr_prodquote.list_amt IS NULL THEN 
				LET pr_prodquote.list_amt = 0 
				DISPLAY BY NAME pr_prodquote.list_amt 

			END IF 
		AFTER FIELD break_qty 
			IF pr_prodquote.break_qty IS NULL THEN 
				LET pr_prodquote.break_qty= 0 
				DISPLAY BY NAME pr_prodquote.break_qty 

			END IF 
		AFTER FIELD freight_amt 
			IF pr_prodquote.freight_amt IS NULL THEN 
				LET pr_prodquote.freight_amt = 0 
				DISPLAY BY NAME pr_prodquote.freight_amt 

			END IF 
		AFTER FIELD lead_time_qty 
			IF pr_prodquote.lead_time_qty IS NULL THEN 
				LET pr_prodquote.lead_time_qty = 0 
				DISPLAY BY NAME pr_prodquote.lead_time_qty 

			END IF 
		AFTER FIELD expiry_date 
			IF pr_prodquote.expiry_date IS NULL THEN 
				LET msgresp=kandoomsg("I",9251,"") 
				#9251 Expiry Date must be entered
				NEXT FIELD expiry_date 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_prodquote.vend_code IS NULL THEN 
					LET msgresp=kandoomsg("P",1022,"") 
					#1022 Enter a Vendor Code...
					NEXT FIELD vend_code 
				END IF 
				SELECT * INTO pr_vendor.* FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pr_prodquote.vend_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("P",9105,"") 
					#9105" Vendor NOT found - try window"
					NEXT FIELD vend_code 
				END IF 
				IF pr_prodquote.part_code IS NULL THEN 
					LET msgresp=kandoomsg("I",9013,"") 
					#9013 Product Code must be entered
					NEXT FIELD part_code 
				END IF 
				SELECT * INTO pr_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_prodquote.part_code 
				IF status = notfound THEN 
					IF pr_prodquote.format_ind = 5 THEN 
						SELECT unique 1 FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND oem_text = pr_prodquote.part_code 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("I",9010,"") 
							#9105" Product NOT found - try window"
							NEXT FIELD part_code 
						ELSE 
							LET pr_prodquote.oem_text = pr_prodquote.part_code 
							DISPLAY "OEM Text" TO prod_desc 

						END IF 
					ELSE 
						LET msgresp=kandoomsg("I",9010,"") 
						#9105" Product NOT found - try window"
						NEXT FIELD part_code 
					END IF 
				END IF 
				IF pr_prodquote.format_ind = 5 
				AND pr_prodquote.oem_text IS NULL THEN 
					LET msgresp=kandoomsg("I",9545,"") 
					#9545" Product does NOT have OEM text.
					NEXT FIELD part_code 
				END IF 
				IF pr_prodquote.curr_code IS NULL THEN 
					LET msgresp=kandoomsg("I",9261,"") 
					#9261 Currency Code must be entered
					NEXT FIELD curr_code 
				END IF 
				SELECT * INTO pr_currency.* FROM currency 
				WHERE currency_code = pr_prodquote.curr_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("I",9073,"") 
					#9073 Currency Code NOT found - Try WIndow
					NEXT FIELD curr_code 
				END IF 
				IF pr_prodquote.frgt_curr_code IS NULL THEN 
					LET msgresp=kandoomsg("I",9261,"") 
					#9261 Currency Code must be entered
					NEXT FIELD frgt_curr_code 
				END IF 
				SELECT * INTO pr_currency.* FROM currency 
				WHERE currency_code = pr_prodquote.frgt_curr_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("I",9073,"") 
					#9073 Currency Code NOT found - Try WIndow
					NEXT FIELD frgt_curr_code 
				END IF 
				IF pr_prodquote.cost_amt IS NULL THEN 
					LET pr_prodquote.cost_amt = 0 
				END IF 
				IF pr_prodquote.list_amt IS NULL THEN 
					LET pr_prodquote.list_amt = 0 
				END IF 
				IF pr_prodquote.expiry_date IS NULL THEN 
					LET msgresp=kandoomsg("I",9251,"") 
					#9251 Expiry Date must be entered
					NEXT FIELD expiry_date 
				END IF 
				LET pr_tmp_rowid = 0 
				SELECT rowid INTO pr_tmp_rowid FROM prodquote 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_prodquote.part_code 
				AND vend_code = pr_prodquote.vend_code 
				AND expiry_date = pr_prodquote.expiry_date 
				IF pr_rowid <> pr_tmp_rowid 
				AND pr_tmp_rowid <> 0 THEN 
					LET msgresp=kandoomsg("I",9265,"") 
					#9265 Product Quotation already exists
					NEXT FIELD expiry_date 
				END IF 
				IF pr_prodquote.break_qty IS NULL THEN 
					LET pr_prodquote.break_qty= 0 
				END IF 
				IF pr_prodquote.freight_amt IS NULL THEN 
					LET pr_prodquote.freight_amt = 0 
				END IF 
				IF pr_prodquote.lead_time_qty IS NULL THEN 
					LET pr_prodquote.lead_time_qty = 0 
				END IF 
				IF pr_prodquote.status_ind IS NULL THEN 
					LET pr_prodquote.status_ind = "1" 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW i165 
		RETURN false 
	END IF 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		CLOSE WINDOW i165 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		IF pr_rowid = 0 THEN 
			LET err_message = "I17 - Inserting Prod Quote" 
			INSERT INTO prodquote VALUES (pr_prodquote.*) 
			LET pr_sqlerrd = sqlca.sqlerrd[6] 
		ELSE 
			LET err_message = "I17 - Updating Prod Quote" 
			UPDATE prodquote 
			SET * = pr_prodquote.* 
			WHERE rowid = pr_rowid 
			LET pr_sqlerrd = pr_rowid 
		END IF 
	COMMIT WORK 
	CLOSE WINDOW i165 
	RETURN pr_sqlerrd 
END FUNCTION 


FUNCTION delete_prodquote() 
	DEFINE 
	query_text CHAR(700), 
	where_text CHAR(500), 
	pr_counter SMALLINT 

	OPEN WINDOW i165 with FORM "I165" 
	 CALL windecoration_i("I165") -- albo kd-758 
	CLEAR FORM 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON vend_code, 
	part_code, 
	oem_text, 
	barcode_text, 
	cost_amt, 
	curr_code, 
	freight_amt, 
	frgt_curr_code, 
	list_amt, 
	break_qty, 
	lead_time_qty, 
	expiry_date, 
	desc_text, 
	status_ind, 
	format_ind 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW i165 
		RETURN false 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message, status) = "N" THEN 
			-- AND WHERE was it opened?          CLOSE WINDOW W152
			RETURN false 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT count(*) FROM prodquote", 
		" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' AND ", 
		where_text clipped 
		PREPARE s_delprodquote FROM query_text 
		DECLARE c_delprodquote CURSOR FOR s_delprodquote 
		OPEN c_delprodquote 
		FETCH c_delprodquote INTO pr_counter 
		IF pr_counter > 0 THEN 
			LET msgresp = kandoomsg("I",8009,pr_counter) 
			#8009 Confirm TO Delete 999 Product Quotation(s)? (Y/N)
			IF msgresp = "Y" THEN 
				LET query_text = "DELETE FROM prodquote ", 
				"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' AND ", 
				where_text clipped 
				PREPARE s_delquote FROM query_text 
				BEGIN WORK 
					EXECUTE s_delquote 
				COMMIT WORK 
				CLOSE WINDOW i165 
				LET msgresp=kandoomsg("I",9253,pr_counter) 
				#9253 999 Supplier Product Quotations successfully deleted
				RETURN true 
			END IF 
		ELSE 
			LET msgresp = kandoomsg("I",9252,"") 
			#9252 No Supplier Product Quotations satisfy the criteria entered
		END IF 
		CLOSE WINDOW i165 
		RETURN false 
	END IF 
END FUNCTION 
