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



# FUNCTION Seri_update recieves a parameter info AND allows the user
# TO UPDATE the serial stock record...

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION ser_update(p_cmpy,p_part,p_ware,p_client,p_invnum,p_inv_date,p_select_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part LIKE invoicedetl.part_code 
	DEFINE p_ware LIKE invoicedetl.ware_code 
	DEFINE p_client LIKE invoicedetl.cust_code 
	DEFINE p_invnum LIKE invoicehead.inv_num 
	DEFINE p_inv_date DATE 
	DEFINE p_select_num DECIMAL(8,2) 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_save_ser LIKE serialinfo.serial_code 
	DEFINE l_rec_serial_flagitem RECORD LIKE serialinfo.* 
	DEFINE l_arr_serialinfo ARRAY[600] OF RECORD 
		serial_code LIKE serialinfo.serial_code, 
		receipt_date LIKE serialinfo.receipt_date 
	END RECORD 
	DEFINE l_arr_selitem ARRAY[300] OF RECORD 
		serial_code LIKE serialinfo.serial_code 
	END RECORD 
	DEFINE l_save_scrn1 SMALLINT 
	DEFINE l_save_idx1 SMALLINT
	DEFINE l_overcopy SMALLINT
	DEFINE l_idx1 SMALLINT
	DEFINE l_scrn1 SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE i SMALLINT
	DEFINE l_scrn SMALLINT
	DEFINE l_cnt1 SMALLINT
	DEFINE l_cnt SMALLINT
	DEFINE r_counter DECIMAL(8,2) 

	OPEN WINDOW wi129 with FORM "I129" 
	CALL windecoration_i("I129") -- albo kd-767 
	DECLARE seli CURSOR FOR 
	SELECT * INTO l_rec_serial_flagitem.* FROM serialinfo 
	WHERE part_code = p_part 
	AND cmpy_code = p_cmpy 
	AND ware_code = p_ware 
	AND trans_num = p_invnum 
	AND trans_num != -1 # -1 IS issues 
	ORDER BY serial_code 
	LET l_idx1 = 0 
	FOREACH seli 
		LET l_idx1 = l_idx1 + 1 
		LET l_arr_selitem[l_idx1].serial_code = l_rec_serial_flagitem.serial_code 
		IF l_idx1 > 300 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			#6100 First l_idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_cnt1 = l_idx1 
	LET r_counter = l_idx1 
	CALL set_count (l_idx1) 
	IF l_idx1 > 10 THEN 
		LET l_scrn1 = 10 
	ELSE 
		LET l_scrn1 = l_idx1 
	END IF 
	FOR i = 1 TO l_scrn1 
		DISPLAY l_arr_selitem[i].serial_code TO scr_sel[i].serial_code 

	END FOR 
	LET l_scrn1 = 1 
	IF l_idx1 = 0 THEN 
		LET l_idx1 = 1 
	END IF 
	DISPLAY p_part, 
	p_select_num 
	TO d_part, 
	sel_num 

	DISPLAY r_counter 
	TO cont 
	attribute(magenta) 
	LET l_rec_serial_flagitem.serial_code = 0 
	OPEN WINDOW wi130 with FORM "I130" 
	CALL windecoration_i("I130") -- albo kd-767 
	DECLARE curser_item CURSOR FOR 
	SELECT * INTO l_rec_serial_flagitem.* FROM serialinfo 
	WHERE part_code = p_part 
	AND cmpy_code = p_cmpy 
	AND ware_code = p_ware 
	AND (trans_num = 0 OR trans_num = p_invnum) 
	ORDER BY serial_code 
	LET l_idx = 0 
	FOREACH curser_item 
		LET l_idx = l_idx + 1 
		LET l_arr_serialinfo[l_idx].serial_code = l_rec_serial_flagitem.serial_code 
		LET l_arr_serialinfo[l_idx].receipt_date = l_rec_serial_flagitem.receipt_date 
		IF l_idx = 600 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			#6100 First l_idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_cnt = l_idx 
	CALL set_count (l_idx) 

	LABEL keep_on: 

	LET l_msgresp = kandoomsg("I",1010,"") 
	#1010 F9 TO INSERT serial item; F10 TO remove serial item.
	INPUT ARRAY l_arr_serialinfo WITHOUT DEFAULTS FROM sr_serialinfo.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","seriwind","input-arr-serialinfo") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F10) 
			CURRENT WINDOW IS wi129 
			IF r_counter >= p_select_num THEN 
				LET l_msgresp = kandoomsg("I",7003,"") 
				# Maximum number of serial item selected.
			ELSE 
				LABEL here1: 
				SELECT * INTO l_rec_serial_flagitem.* FROM serialinfo 
				WHERE cmpy_code = p_cmpy 
				AND part_code = p_part 
				AND serial_code = l_arr_serialinfo[l_idx].serial_code 
				WHILE status = -250 
					ERROR " RECORD locked by another user, please stand by" 
					SLEEP 3 
					ERROR " " 
					GOTO here1 
					LET status = 0 
				END WHILE 
				WHENEVER ERROR stop 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("U",9910,"") 
					#9910 RECORD Not Found
				ELSE 
					IF l_rec_serial_flagitem.trans_num != 0 THEN 
						LET l_msgresp = kandoomsg("I",9523,"") 
						#9523 "Serial item already allocated"
					ELSE 
						LET l_arr_selitem[l_idx1].serial_code = 
						l_arr_serialinfo[l_idx].serial_code 
						DISPLAY l_arr_selitem[l_idx1].serial_code 
						TO scr_sel[l_scrn1].serial_code 

						LET l_idx1 = l_idx1 + 1 
						IF l_scrn1 < 10 THEN 
							LET l_scrn1 = l_scrn1 + 1 
						END IF 
						LET l_rec_serial_flagitem.cust_code = p_client 
						LET l_rec_serial_flagitem.trans_num = p_invnum 
						LET l_rec_serial_flagitem.ship_date = p_inv_date 
						UPDATE serialinfo 
						SET serialinfo.cust_code = l_rec_serial_flagitem.cust_code, 
						serialinfo.ship_date = l_rec_serial_flagitem.ship_date, 
						serialinfo.trans_num = l_rec_serial_flagitem.trans_num 
						WHERE serialinfo.serial_code = l_rec_serial_flagitem.serial_code 
						AND serialinfo.cmpy_code = p_cmpy 
						AND part_code = p_part 
						LET r_counter = r_counter + 1 
					END IF 
				END IF 
				DISPLAY r_counter 
				TO cont 
				attribute(magenta) 
				IF r_counter = p_select_num THEN 
					LET l_msgresp = kandoomsg("I",8016,"") 
					#8016 Selection Complete?
					IF l_msgresp = "Y" THEN 
						CURRENT WINDOW IS wi130 
						EXIT INPUT 
					END IF 
				END IF 
			END IF 
			CURRENT WINDOW IS wi130 
		ON KEY (F9) 
			CURRENT WINDOW IS wi129 
			LABEL here: 
			SELECT * INTO l_rec_serial_flagitem.* FROM serialinfo 
			WHERE cmpy_code = p_cmpy 
			AND part_code = p_part 
			AND serial_code = l_arr_serialinfo[l_idx].serial_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("U",9910,"") 
				#9910 RECORD NOT found
			END IF 
			WHILE status = -250 
				ERROR " RECORD locked by another user, please stand by" 
				SLEEP 3 
				ERROR " " 
				GOTO here 
				LET status = 0 
			END WHILE 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			IF status = notfound THEN 
			ELSE 
				IF l_rec_serial_flagitem.trans_num = 0 THEN 
					LET l_msgresp = kandoomsg("I",9523,"") 
					#9523 "Serial item NOT allocated"
				ELSE 
					LET l_rec_serial_flagitem.cust_code = NULL 
					LET l_rec_serial_flagitem.trans_num = 0 
					LET l_rec_serial_flagitem.ship_date = NULL 
					UPDATE serialinfo 
					SET serialinfo.cust_code = l_rec_serial_flagitem.cust_code, 
					serialinfo.ship_date = l_rec_serial_flagitem.ship_date, 
					serialinfo.trans_num = l_rec_serial_flagitem.trans_num 
					WHERE serialinfo.serial_code = l_rec_serial_flagitem.serial_code 
					AND serialinfo.cmpy_code = p_cmpy 
					AND part_code = p_part 
					LET r_counter = r_counter - 1 
					LET l_overcopy = 0 
					FOR i = 1 TO l_idx1 
						IF l_arr_serialinfo[l_idx].serial_code = 
						l_arr_selitem[i].serial_code THEN 
							LET l_overcopy = 1 
						END IF 
						IF l_overcopy = 1 THEN 
							IF i = l_idx1 THEN 
								LET l_arr_selitem[i].serial_code = NULL 
								EXIT FOR 
							ELSE 
								LET l_arr_selitem[i].serial_code = 
								l_arr_selitem[i+1].serial_code 
							END IF 
						END IF 
					END FOR 
					LET l_idx1 = l_idx1 - 1 
					IF l_idx1 = 0 THEN 
						LET l_idx1 = 1 
					END IF 
					LET l_scrn1 = l_scrn1 - 1 
					IF l_scrn1 = 0 THEN 
						LET l_scrn1 = 1 
					END IF 
					LET l_save_idx1 = l_idx1 
					LET l_save_scrn1 = l_scrn1 
					FOR l_scrn1 = 1 TO l_save_scrn1 
						LET l_idx1 = l_scrn1 
						DISPLAY l_arr_selitem[l_idx1].serial_code 
						TO scr_sel[l_scrn1].serial_code 

					END FOR 
					LET l_scrn1 = l_save_scrn1 
					LET l_idx1 = l_save_idx1 
					DISPLAY r_counter 
					TO cont 
					attribute(magenta) 
				END IF 
			END IF 
			CURRENT WINDOW IS wi130 
			NEXT FIELD serial_code 
		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			IF l_idx <= l_cnt THEN 
				DISPLAY l_arr_serialinfo[l_idx].* TO sr_serialinfo[l_scrn].* 

			END IF 
			LET l_save_ser = l_arr_serialinfo[l_idx].serial_code 
		AFTER FIELD serial_code 
			IF l_save_ser != l_arr_serialinfo[l_idx].serial_code THEN 
				LET l_save_ser = l_arr_serialinfo[l_idx].serial_code 
				NEXT FIELD serial_code 
			END IF 
		AFTER ROW 
			IF l_idx <= l_cnt THEN 
				DISPLAY l_arr_serialinfo[l_idx].* TO sr_serialinfo[l_scrn].* 
			END IF 
		AFTER INPUT 
			IF r_counter < p_select_num THEN 
				LET l_msgresp = kandoomsg("I",8012,"") 
				#8012 Allocated serials less than required-continue allocation?
				IF l_msgresp != "N" THEN 
					LET l_save_ser = "TOO LESS" 
				END IF 
			END IF 

	END INPUT 
	IF l_save_ser = "TOO LESS" THEN 
		GOTO keep_on 
	END IF 
	CLOSE WINDOW wi130 
	CLOSE WINDOW wi129 
	RETURN r_counter 
END FUNCTION 


