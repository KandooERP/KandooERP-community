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

	Source code beautified by beautify.pl on 2020-01-02 10:35:34	$Id: $
}



# FUNCTION serial_in allows the user TO receipt serial stock TO the
# serialinfo table
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION serial_in(p_cmpy,p_vend_code,p_received_qty,p_part_code,p_cost_amt,p_po_num,p_received_date,p_received_text,p_ware_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE serialinfo.vend_code 
	DEFINE p_received_qty DECIMAL(8,2) 
	DEFINE p_part_code LIKE invoicedetl.part_code 
	DEFINE p_cost_amt LIKE prodledg.cost_amt 
	DEFINE p_po_num LIKE serialinfo.po_num 
	DEFINE p_received_date LIKE serialinfo.receipt_date 
	DEFINE p_received_text LIKE serialinfo.receipt_num 
	DEFINE p_ware_code LIKE invoicedetl.ware_code 
	DEFINE l_arr_serialinfo ARRAY[600] OF RECORD 
		c_num INTEGER, 
		serial_code LIKE serialinfo.serial_code 
	END RECORD 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_receipt_qty INTEGER 
	DEFINE l_serialised_qty INTEGER
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rest_to_serialize INTEGER 
	DEFINE l_serial_code LIKE serialinfo.serial_code 
	DEFINE l_tester SMALLINT 
	DEFINE l_idx1 SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_scrn SMALLINT
	DEFINE l_ser_number INTEGER 
	DEFINE l_counter DECIMAL(8,2) 
	DEFINE i SMALLINT 

	# before we go on we need TO check TO see IF preallocations are being
	# used AND IF so, need TO see IF the serialinfos have already been
	# SET up. IF so we UPDATE those already SET up AND continue if
	# some have NOT been SET up. We need TO operate on a part/po level.
	# IF one part IS repeated on a po, we do all serialisation together.
	# So the logic IS
	#     1. Search serial info FOR the count of this part on the p.o.
	#     2. Compare that with the receipted quantity FOR this part
	#        FROM the p.o.  (Note the p.o. IS updated before CALL TO serial_in)
	#     3. IF receipted_qty = 2 - 1, THEN all IS OK, IF NOT THEN
	#        we need TO serialise 2 - 1. (Assuming 2 - 1 IS > 0).
	#        AND UPDATE receipt information on receipt_qty - (2-1).
	#
	# part 1.
	#
	IF p_po_num != 0 THEN # we have a valid po so CHECK preallocations 
		LET l_serialised_qty = 0 
		SELECT count(*) 
		INTO l_serialised_qty 
		FROM serialinfo 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		AND po_num = p_po_num 
		IF l_serialised_qty IS NULL THEN 
			LET l_serialised_qty = 0 
		END IF 
		# lets do part 2.
		LET l_receipt_qty = 0 
		DECLARE c_purchdetl CURSOR FOR 
		SELECT * 
		FROM purchdetl 
		WHERE cmpy_code = p_cmpy 
		AND ref_text = p_part_code 
		AND order_num = p_po_num 
		FOREACH c_purchdetl INTO l_rec_purchdetl.* 
			CALL po_line_info(p_cmpy,l_rec_purchdetl.order_num,l_rec_purchdetl.line_num) 
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
					DECLARE c_serialinfo CURSOR FOR 
					SELECT * FROM serialinfo 
					WHERE cmpy_code = p_cmpy 
					AND po_num = p_po_num 
					AND part_code = p_part_code 
					AND receipt_date = 0 
					FOREACH c_serialinfo INTO l_rec_serialinfo.* 
						LET l_idx1 = l_idx1 + 1 
						UPDATE serialinfo SET receipt_date = p_received_date, 
						receipt_num = p_received_text 
						WHERE cmpy_code = p_cmpy 
						AND po_num = p_po_num 
						AND part_code = p_part_code 
						AND serial_code = l_rec_serialinfo.serial_code 
						IF l_idx1 = p_received_qty THEN 
							EXIT FOREACH 
						END IF 
					END FOREACH 
					LET p_received_qty = 0 
				ELSE 
					# some TO be serialised by the user AND some TO be updated
					# by program. calculating what IS TO be updated by program
					LET p_received_qty = p_received_qty + l_serialised_qty 
					- l_receipt_qty 
					LET l_idx1 = 0 
					#UPDATE the serialised info with receipt info
					DECLARE c1_serialinfo CURSOR FOR 
					SELECT * FROM serialinfo 
					WHERE cmpy_code = p_cmpy 
					AND po_num = p_po_num 
					AND part_code = p_part_code 
					AND receipt_date = 0 
					FOREACH c1_serialinfo INTO l_rec_serialinfo.* 
						LET l_idx1 = l_idx1 + 1 
						UPDATE serialinfo SET receipt_date = p_received_date, 
						receipt_num = p_received_text 
						WHERE cmpy_code = p_cmpy 
						AND po_num = p_po_num 
						AND part_code = p_part_code 
						AND serial_code = l_rec_serialinfo.serial_code 
						IF l_idx1 = p_received_qty THEN 
							EXIT FOREACH 
						END IF 
					END FOREACH 
					LET p_received_qty = l_receipt_qty - l_serialised_qty 
					LET l_msgresp = kandoomsg("I",6013,"") 
					#6013 Adjusted quantity TO serialise, FROM serial info
				END IF 
			WHEN ( (l_receipt_qty - l_serialised_qty) > p_received_qty ) 
				# NOT all were serialised last time, so we jump
				# up the received AND make them serialise properly
				LET p_received_qty = l_receipt_qty - l_serialised_qty 
				LET l_msgresp = kandoomsg("I",6013,"") 
				#6013 Adjusted quantity TO serialise, FROM serial info
		END CASE 
	END IF 
	IF p_received_qty = 0 THEN 
		RETURN 
	END IF 
	LET l_counter = 0 
	OPEN WINDOW i158 with FORM "I158" 
	CALL windecoration_i("I158") -- albo kd-767 
	LET l_msgresp = kandoomsg("I",1020,"") 
	#1020 F10 TO increment numbers
	DISPLAY p_part_code TO d_part 
	DISPLAY p_received_qty TO sel_num 
	DISPLAY l_counter TO cont attribute(magenta) 
	LET l_rest_to_serialize = NULL 
	FOR i = 1 TO p_received_qty 
		IF i > 600 THEN 
			LET l_rest_to_serialize = p_received_qty - 600 
			LET l_msgresp = kandoomsg("I",7030,l_rest_to_serialize) 
			# 7030 "l_rest_to_serialize" products will be serialized automatically
			EXIT FOR 
		END IF 
		LET l_arr_serialinfo[i].c_num = i 
	END FOR 

	LET i = i - 1 
	CALL set_count(i) 
	INPUT ARRAY l_arr_serialinfo WITHOUT DEFAULTS FROM sr_serialinfo.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","serrwind","input-arr-serialinfo") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F10) 
			IF l_arr_serialinfo[l_idx].serial_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9096,"") 
				#9096 Must enter a number
				NEXT FIELD serial_code 
			END IF 
			SELECT unique 1 FROM serialinfo 
			WHERE cmpy_code = p_cmpy 
			AND part_code = p_part_code 
			AND serial_code = l_arr_serialinfo[l_idx].serial_code 
			IF sqlca.sqlcode = 0 THEN 
				LET l_msgresp = kandoomsg("I",9097,"") 
				#9097 Serial Number already exists
				NEXT FIELD serial_code 
			END IF 
			FOR i = 1 TO arr_count() 
				IF i = arr_curr() THEN 
				ELSE 
					IF l_arr_serialinfo[i].serial_code = l_arr_serialinfo[l_idx].serial_code THEN 
						LET l_msgresp = kandoomsg("I",9098,"") 
						#9098 Already entered this serial number
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
			FOR i = 1 TO arr_curr() 
				IF l_arr_serialinfo[i].serial_code IS NOT NULL THEN 
					LET l_tester = l_tester + 1 
				END IF 
			END FOR 
			IF l_rest_to_serialize IS NOT NULL THEN 
				FOR i = 1 TO (600 - l_tester) 
					LET l_arr_serialinfo[l_idx + i].serial_code = l_ser_number + i 
					IF l_scrn + i < 11 THEN 
						DISPLAY l_arr_serialinfo[l_idx+i].* TO sr_serialinfo[l_scrn+i].* 
					END IF 
				END FOR 
			ELSE 
				FOR i = 1 TO (p_received_qty - l_tester) 
					LET l_arr_serialinfo[l_idx + i].serial_code = l_ser_number + i 
					IF l_scrn + i < 11 THEN 
						DISPLAY l_arr_serialinfo[l_idx+i].* TO sr_serialinfo[l_scrn+i].* 
					END IF 
				END FOR 
			END IF 
			LET l_counter = p_received_qty 
			DISPLAY l_counter TO cont attribute(magenta) 
		ON KEY (F2) 
			LET l_arr_serialinfo[l_idx].serial_code = NULL 
			DISPLAY l_arr_serialinfo[l_idx].serial_code TO sr_serialinfo[l_idx].serial_code 
		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			LET l_counter = 0 
			FOR i=1 TO arr_count() 
				IF l_arr_serialinfo[i].serial_code IS NOT NULL THEN 
					LET l_counter = l_counter + 1 
				END IF 
			END FOR 
			DISPLAY l_counter TO cont attribute(magenta) 
			IF l_counter = p_received_qty THEN 
				LET l_msgresp = kandoomsg("I",8021,"") 
				IF l_msgresp = "Y" THEN 
					EXIT INPUT 
				END IF 
			END IF 
		AFTER FIELD serial_code 
			SELECT unique 1 FROM serialinfo 
			WHERE cmpy_code = p_cmpy 
			AND part_code = p_part_code 
			AND serial_code = l_arr_serialinfo[l_idx].serial_code 
			IF sqlca.sqlcode = 0 THEN 
				LET l_msgresp = kandoomsg("I",9097,"") 
				#9097 Serial Number already exists
				NEXT FIELD serial_code 
			END IF 
			FOR i = 1 TO arr_count() 
				IF i = arr_curr() THEN 
				ELSE 
					IF l_arr_serialinfo[i].serial_code = l_arr_serialinfo[l_idx].serial_code THEN 
						LET l_msgresp = kandoomsg("I",9098,"") 
						#9098 Already entered this serial number
						NEXT FIELD serial_code 
					END IF 
				END IF 
			END FOR 
		AFTER INPUT 
			FOR i = 1 TO arr_count() 
				SELECT unique 1 FROM serialinfo 
				WHERE cmpy_code = p_cmpy 
				AND part_code = p_part_code 
				AND serial_code = l_arr_serialinfo[i].serial_code 
				IF sqlca.sqlcode = 0 THEN 
					LET l_msgresp = kandoomsg("I",7013,l_arr_serialinfo[i].serial_code) 
					#7013 Serial Number "l_arr_serialinfo[i].serial_code" already exists"
					NEXT FIELD serial_code 
				END IF 
			END FOR 
			IF l_counter < p_received_qty THEN 
				LET l_msgresp = kandoomsg("I",8020,"") 
				IF l_msgresp != "N" THEN 
					CONTINUE INPUT 
				END IF 
			END IF 
			IF l_counter > p_received_qty THEN 
				LET l_msgresp = kandoomsg("I",6012,"") 
				CONTINUE INPUT 
			END IF 

	END INPUT 
	LET l_rec_serialinfo.cmpy_code = p_cmpy 
	LET l_rec_serialinfo.part_code = p_part_code 
	LET l_rec_serialinfo.vend_code = p_vend_code 
	LET l_rec_serialinfo.po_num = p_po_num 
	LET l_rec_serialinfo.receipt_date = p_received_date 
	LET l_rec_serialinfo.receipt_num = p_received_text 
	LET l_rec_serialinfo.cust_code = "" 
	LET l_rec_serialinfo.trans_num = 0 
	LET l_rec_serialinfo.ref_num = 0 
	LET l_rec_serialinfo.ship_date = 0 
	LET l_rec_serialinfo.ware_code = p_ware_code 
	LET l_msgresp = kandoomsg ("I",1005,"") 
	FOR i=1 TO arr_count() 
		IF l_arr_serialinfo[i].serial_code IS NOT NULL THEN 
			LET l_rec_serialinfo.serial_code = l_arr_serialinfo[i].serial_code 
			INSERT INTO serialinfo VALUES (l_rec_serialinfo.*) 
		END IF 
	END FOR 
	IF l_rest_to_serialize IS NOT NULL THEN 
		LET l_msgresp = kandoomsg ("I",9095,l_rest_to_serialize) 
		# 9095 Now serializing the remaining "l_rest_to_serialize" products
		LET l_serial_code = l_arr_serialinfo[600].serial_code 
		FOR i = 1 TO l_rest_to_serialize 
			LET l_serial_code = l_serial_code + 1 
			LET l_rec_serialinfo.serial_code = l_serial_code 
			WHILE true 
				SELECT unique 1 
				FROM serialinfo 
				WHERE cmpy_code = p_cmpy 
				AND part_code = p_part_code 
				AND serial_code = l_serial_code 
				IF status != notfound THEN 
					LET l_serial_code = l_serial_code + 1 
					CONTINUE WHILE 
				ELSE 
					EXIT WHILE 
				END IF 
			END WHILE 
			INSERT INTO serialinfo VALUES (l_rec_serialinfo.*) 
		END FOR 
	END IF 
	CLOSE WINDOW i158 
END FUNCTION 


