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

	Source code beautified by beautify.pl on 2020-01-02 10:35:35	$Id: $
}



#
# FUNCTION serial_ret allows the user TO RETURN serial stock TO the
#          serialinfo table
#

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION serial_ret(p_cmpy,p_vend,p_received_qty,p_part,p_cost,p_po,p_rec_date,p_rec_text,p_ware) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_vend LIKE serialinfo.vend_code
	DEFINE p_received_qty DECIMAL(8,2)
	DEFINE p_part LIKE invoicedetl.part_code 
	DEFINE p_cost DECIMAL(16,4) 
	DEFINE p_po LIKE serialinfo.po_num 
	DEFINE p_rec_date LIKE serialinfo.receipt_date 
	DEFINE p_rec_text LIKE serialinfo.receipt_num 
	DEFINE p_ware LIKE invoicedetl.ware_code 
	DEFINE l_save_ser LIKE serialinfo.serial_code 
	DEFINE l_arr_serialinfo ARRAY[600] OF RECORD 
		c_num INTEGER, 
		serial_code LIKE serialinfo.serial_code 
	END RECORD 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_receipt_qty INTEGER 
	DEFINE l_serialised_qty INTEGER
	DEFINE l_tester SMALLINT 
	DEFINE l_idx1, l_idx SMALLINT
	DEFINE l_scrn SMALLINT 
	DEFINE l_ans CHAR(1) 
	DEFINE l_ser_number INTEGER 
	DEFINE l_counter DECIMAL(8,2) 
	DEFINE l_serial_qty DECIMAL(8,2) 
	DEFINE i SMALLINT

	# before we go on we need TO check TO see IF preallocations are being
	# used AND IF so, need TO see IF the serialinfos have already been
	# SET up. IF so we UPDATE those already SET up AND continue if
	# some have NOT been SET up. We need TO operate on a part/po level.
	# IF one part IS repeated on a po, we do all serialisation together.
	# So the logic IS
	#     1. Search serial info FOR the count of this part on the
	#        p.o.
	#     2. Compare that with the receipted quantity FOR this part
	#        FROM the p.o.  (Note the p.o. IS updated before coming
	#        here).
	#     3. IF receipted_qty = 2 - 1, THEN all IS OK, IF NOT THEN
	#        we need TO serialise 2 - 1. (Assuming 2 - 1 IS > 0).
	#        AND UPDATE receipt information on receipt_ qty - (2-1).
	#

	# store the original qty going back TO stock TO be used IF there IS
	# no serial stock OR po's on system
	LET l_serial_qty = p_received_qty 

	# lets do part 1.
	LET l_serialised_qty = 0 

	SELECT count(*) INTO l_serialised_qty FROM serialinfo 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part 
	AND po_num = p_po 

	IF l_serialised_qty IS NULL THEN 
		LET l_serialised_qty = 0 
	END IF 

	# lets do part 2.
	LET l_receipt_qty = 0 

	DECLARE po_2_curs CURSOR FOR 
	SELECT * INTO l_rec_purchdetl.* FROM purchdetl 
	WHERE cmpy_code = p_cmpy 
	AND ref_text = p_part 
	AND order_num = p_po 

	FOREACH po_2_curs 
		CALL po_line_info(p_cmpy, 
		l_rec_purchdetl.order_num, 
		l_rec_purchdetl.line_num) 
		RETURNING l_rec_poaudit.order_qty, 
		l_rec_poaudit.received_qty, 
		l_rec_poaudit.voucher_qty, 
		l_rec_poaudit.unit_cost_amt, 
		l_rec_poaudit.ext_cost_amt, 
		l_rec_poaudit.unit_tax_amt, 
		l_rec_poaudit.ext_tax_amt, 
		l_rec_poaudit.line_total_amt 
		LET l_receipt_qty = l_receipt_qty + l_rec_poaudit.received_qty 
	END FOREACH 

	CASE 
		WHEN ( (l_receipt_qty - l_serialised_qty) = p_received_qty ) 

		WHEN ( (l_receipt_qty - l_serialised_qty) < p_received_qty ) 
			# the serialised items have been SET up.

			IF l_receipt_qty - l_serialised_qty < 0 THEN 
				LET l_idx1 = 0 
				#UPDATE the serialised info with receipt info
				DECLARE ser_rec_upd CURSOR FOR 
				SELECT * INTO l_rec_serialinfo.* FROM serialinfo 
				WHERE cmpy_code = p_cmpy 
				AND po_num = p_po 
				AND part_code = p_part 
				AND receipt_date = 0 
				FOREACH ser_rec_upd 
					LET l_idx1 = l_idx1 + 1 
					UPDATE serialinfo SET receipt_date = p_rec_date, 
					receipt_num = p_rec_text 
					WHERE cmpy_code = p_cmpy 
					AND po_num = p_po 
					AND part_code = p_part 
					AND serial_code = l_rec_serialinfo.serial_code 

					IF l_idx1 = p_received_qty THEN 
						EXIT FOREACH 
					END IF 
				END FOREACH 
			ELSE 
				# OK some TO be serialised by the user
				# AND some TO be updated by us....
				# lets work out what IS TO be updated by us

				LET p_received_qty = p_received_qty + l_serialised_qty 
				- l_receipt_qty 
				LET l_idx1 = 0 
				#UPDATE the serialised info with receipt info
				DECLARE ser2_rec_upd CURSOR FOR 
				SELECT * INTO l_rec_serialinfo.* FROM serialinfo 
				WHERE cmpy_code = p_cmpy 
				AND po_num = p_po 
				AND part_code = p_part 
				AND receipt_date = 0 
				FOR UPDATE 
				FOREACH ser2_rec_upd 
					LET l_idx1 = l_idx1 + 1 
					UPDATE serialinfo SET receipt_date = p_rec_date, 
					receipt_num = p_rec_text 
					WHERE cmpy_code = p_cmpy 
					AND po_num = p_po 
					AND part_code = p_part 
					AND serial_code = l_rec_serialinfo.serial_code 

					IF l_idx1 = p_received_qty THEN 
						EXIT FOREACH 
					END IF 
				END FOREACH 
				LET p_received_qty = l_receipt_qty - l_serialised_qty 
				IF (l_receipt_qty != 0 AND l_serialised_qty != 0) THEN 
					ERROR " Adjusted quantity TO serialise, FROM serial info " 
					SLEEP 5 
				END IF 
			END IF 

		WHEN ( (l_receipt_qty - l_serialised_qty) > p_received_qty ) 

			# NOT all were serialised last time, so we jump
			# up the received AND make them serialise properly

			LET p_received_qty = l_receipt_qty - l_serialised_qty 
			IF (l_receipt_qty != 0 AND l_serialised_qty != 0) THEN 
				ERROR " Adjusted quantity TO serialise, FROM serial info " 
				SLEEP 5 
			END IF 
	END CASE 

	IF p_received_qty = 0 THEN 
		IF (l_receipt_qty != 0 AND l_serialised_qty != 0) THEN 
			RETURN 
		END IF 
		LET p_received_qty = l_serial_qty 
	END IF 

	OPEN WINDOW wi158 with FORM "I158" 
	CALL windecoration_i("I158") -- albo kd-752 

	MESSAGE " F10 TO increment numbers " attribute(yellow) 
	LET l_counter = 0 

	DISPLAY p_part TO d_part 
	DISPLAY p_received_qty TO sel_num 
	DISPLAY l_counter TO cont attribute(magenta) 

	FOR i = 1 TO p_received_qty 
		LET l_arr_serialinfo[i].c_num = i 
	END FOR 
	LET i = i - 1 

	CALL set_count(i) 
	LABEL keep_on: 
	INPUT ARRAY l_arr_serialinfo WITHOUT DEFAULTS FROM sr_serialinfo.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","sretwind","input-arr-serialinfo") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F10) 
			IF l_arr_serialinfo[l_idx].serial_code IS NULL THEN 
				ERROR " Must enter a number " 
				NEXT FIELD serial_code 
			END IF 

			FOR i = 1 TO arr_count() 
				IF i = arr_curr() THEN 
				ELSE 
					IF l_arr_serialinfo[i].serial_code = l_arr_serialinfo[l_idx].serial_code THEN 
						ERROR " Already entered this serial number" 
						NEXT FIELD serial_code 
					END IF 
				END IF 
			END FOR 

			# in CASE rubbish entered
			WHENEVER ERROR CONTINUE 
			LET l_ser_number = l_arr_serialinfo[l_idx].serial_code 
			WHENEVER ERROR stop
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

			# now check how many entered
			LET l_tester = 0 
			FOR i=1 TO arr_curr() 
				IF l_arr_serialinfo[i].serial_code IS NOT NULL THEN 
					LET l_tester = l_tester + 1 
				END IF 
			END FOR 

			# now stick em on the end
			FOR i = 1 TO (p_received_qty - l_tester) 
				LET l_arr_serialinfo[l_idx + i].serial_code = l_ser_number + i 
				IF l_scrn + i < 11 THEN 
					DISPLAY l_arr_serialinfo[l_idx+i].* TO sr_serialinfo[l_scrn+i].* 
				END IF 
			END FOR 
			LET l_counter = p_received_qty 
			DISPLAY l_counter TO cont attribute(magenta) 

		ON KEY (F2) 
			LET l_arr_serialinfo[l_idx].serial_code = NULL 
			DISPLAY l_arr_serialinfo[l_idx].serial_code TO sr_serialinfo[l_idx].serial_code 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			LET l_save_ser = l_arr_serialinfo[l_idx].serial_code 
			LET l_counter = 0 
			FOR i=1 TO arr_count() 
				IF l_arr_serialinfo[i].serial_code IS NOT NULL THEN 
					LET l_counter = l_counter + 1 
				END IF 
			END FOR 
			DISPLAY l_counter TO cont attribute(magenta) 
			IF l_counter = p_received_qty THEN 
				IF complete(l_ans) = "Y" THEN 
					EXIT INPUT 
				END IF 
			END IF 

		AFTER FIELD serial_code 
			FOR i = 1 TO arr_count() 
				IF i = arr_curr() THEN 
				ELSE 
					IF l_arr_serialinfo[i].serial_code = l_arr_serialinfo[l_idx].serial_code THEN 
						ERROR " Already entered this serial number" 
						NEXT FIELD serial_code 
					END IF 
				END IF 
			END FOR 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
				EXIT INPUT 
			ELSE 
				IF l_counter < p_received_qty THEN 
					LET l_ans = alloc_less(l_ans) 
					IF l_ans = "N" THEN 
						NEXT FIELD serial_code 
					END IF 
				END IF 
				IF l_counter > p_received_qty THEN 
					CALL too_many() 
					NEXT FIELD serial_code 
				END IF 
			END IF 

	END INPUT 

	LET l_rec_serialinfo.cmpy_code = p_cmpy 
	LET l_rec_serialinfo.part_code = p_part 
	LET l_rec_serialinfo.vend_code = p_vend 
	LET l_rec_serialinfo.po_num = p_po 
	LET l_rec_serialinfo.receipt_date = p_rec_date 
	LET l_rec_serialinfo.receipt_num = p_rec_text 
	LET l_rec_serialinfo.cust_code = "" 
	LET l_rec_serialinfo.trans_num = 0 
	LET l_rec_serialinfo.ref_num = 0 
	LET l_rec_serialinfo.ship_date = 0 
	LET l_rec_serialinfo.ware_code = p_ware 
	FOR i=1 TO arr_count() 
		IF l_arr_serialinfo[i].serial_code IS NOT NULL THEN 
			SELECT count(*) INTO l_tester FROM serialinfo 
			WHERE cmpy_code = p_cmpy 
			AND part_code = p_part 
			AND serial_code = l_arr_serialinfo[i].serial_code 
			IF l_tester != 0 THEN 
				UPDATE serialinfo 
				SET cmpy_code = l_rec_serialinfo.cmpy_code, 
				part_code = l_rec_serialinfo.part_code, 
				vend_code = l_rec_serialinfo.vend_code, 
				po_num = l_rec_serialinfo.po_num, 
				receipt_date = l_rec_serialinfo.receipt_date, 
				receipt_num = l_rec_serialinfo.receipt_num, 
				cust_code = l_rec_serialinfo.cust_code, 
				trans_num = l_rec_serialinfo.trans_num, 
				ref_num = l_rec_serialinfo.ref_num, 
				ship_date = l_rec_serialinfo.ship_date, 
				ware_code = l_rec_serialinfo.ware_code 
				WHERE cmpy_code = p_cmpy 
				AND part_code = p_part 
				AND serial_code = l_arr_serialinfo[i].serial_code 
			ELSE 
				LET l_rec_serialinfo.serial_code = l_arr_serialinfo[i].serial_code 
				INSERT INTO serialinfo VALUES (l_rec_serialinfo.*) 
			END IF 
		END IF 
	END FOR 
	CLOSE WINDOW wi158 
END FUNCTION 


FUNCTION alloc_less(l_ans) 
	DEFINE 
	l_ans CHAR(1) 

	--  OPEN WINDOW wseri AT 18,5  with 1 rows, 70 columns ATTRIBUTE(border, reverse)  -- albo  KD-752
	--  prompt " Allocated serials less than required - continue allocation ? (y/n) " FOR CHAR l_ans -- albo
	LET l_ans = promptYN(""," Allocated serials less than required - continue allocation ? ","Y") -- albo 

	--  CLOSE WINDOW wseri  -- albo  KD-752
	LET l_ans = upshift(l_ans) 
	RETURN(l_ans) 
END FUNCTION 


FUNCTION complete(l_ans) 
	DEFINE l_ans CHAR(1) 

	--  OPEN WINDOW wsere AT 18,5  with 1 rows, 35 columns ATTRIBUTE(border, reverse)
	--  prompt " Entry complete ? (y/n) " FOR CHAR l_ans -- albo
	LET l_ans = promptYN("","Entry complete ?","Y") -- albo 

	--  CLOSE WINDOW wsere  -- albo  KD-752
	LET l_ans = upshift(l_ans) 
	RETURN(l_ans) 
END FUNCTION 


FUNCTION too_many() 
	--  OPEN WINDOW wserf AT 18,5  with 1 rows, 50 columns ATTRIBUTE(border, reverse)
	MESSAGE "Remove surplus serial numbers TO continue" 
	SLEEP 3 
	--  CLOSE WINDOW wserf  -- albo  KD-752
END FUNCTION 


