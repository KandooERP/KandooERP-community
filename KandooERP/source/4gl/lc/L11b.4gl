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

	Source code beautified by beautify.pl on 2020-01-02 18:38:28	$Id: $
}



# Perform INPUT of shipment Line Items

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L11_GLOBALS.4gl" 


DEFINE 
new_arr_size,scrn1, last_window, j SMALLINT, 
acount, ins_flag SMALLINT, 
image_flag CHAR(1) 

FUNCTION lineitem() 
	DEFINE resp CHAR(1) 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	INITIALIZE pr_shipdetl.* TO NULL 
	LET nxtfld = 0 
	LET firstime = 1 
	LET ins_flag = 0 
	OPEN WINDOW wl102 with FORM "L102" 
	CALL windecoration_l("L102") -- albo kd-761 

	IF NOT retain_flag THEN 
		DECLARE c_item CURSOR FOR 
		SELECT shipdetl.* INTO pr_shipdetl.* FROM shipdetl 
		WHERE ship_code = pr_shiphead.ship_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET idx = 0 
		FOREACH c_item 
			LET idx = idx + 1 
			LET pa_shipdetl[idx].part_code = pr_shipdetl.part_code 
			LET pa_shipdetl[idx].source_doc_num = pr_shipdetl.source_doc_num 
			LET pa_shipdetl[idx].ship_inv_qty = pr_shipdetl.ship_inv_qty 
			LET pa_shipdetl[idx].fob_unit_ent_amt = pr_shipdetl.fob_unit_ent_amt 
			LET pa_shipdetl[idx].tariff_code = pr_shipdetl.tariff_code 
			LET pa_shipdetl[idx].duty_unit_ent_amt 
			= pr_shipdetl.duty_unit_ent_amt 
			LET st_shipdetl[idx].* = pr_shipdetl.* 
			IF idx = max_shipdetls THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		CALL set_count(idx) 
	ELSE 
		# this IS the CASE of a RETURN FROM the L11c module via DEL key
		FOR i = 1 TO arr_size 
			LET pa_shipdetl[i].part_code = st_shipdetl[i].part_code 
			LET pa_shipdetl[i].source_doc_num = st_shipdetl[i].source_doc_num 
			LET pa_shipdetl[i].ship_inv_qty = st_shipdetl[i].ship_inv_qty 
			LET pa_shipdetl[i].fob_unit_ent_amt = st_shipdetl[i].fob_unit_ent_amt 
			LET pa_shipdetl[i].tariff_code = st_shipdetl[i].tariff_code 
			LET pa_shipdetl[i].duty_unit_ent_amt = st_shipdetl[i].duty_unit_ent_amt 
		END FOR 
		CALL set_count(arr_size) 
		LET retain_flag = true 
	END IF 
	DISPLAY pr_shiphead.vend_code, 
	pr_shiphead.ship_code, 
	pr_shiphead.ship_type_code, 
	pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.curr_code, 
	pr_vendor.name_text, 
	pr_shiphead.duty_ent_amt, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.vessel_text, 
	pr_shiphead.discharge_text, 
	pr_shiphead.fob_curr_cost_amt, 
	pr_shiphead.ship_status_code, 
	pr_shipstatus.desc_text, 
	pr_shiphead.duty_inv_amt, 
	pr_shiphead.conversion_qty, 
	pr_shiphead.ware_code, 
	pr_shiphead.other_cost_amt 
	TO shiphead.vend_code, 
	shiphead.ship_code, 
	shiphead.ship_type_code, 
	shiphead.fob_ent_cost_amt, 
	shiphead.curr_code, 
	vendor.name_text, 
	shiphead.duty_ent_amt, 
	shiphead.eta_curr_date, 
	shiphead.vessel_text, 
	shiphead.discharge_text, 
	shiphead.fob_curr_cost_amt, 
	shiphead.ship_status_code, 
	shipstatus.desc_text, 
	shiphead.duty_inv_amt, 
	shiphead.conversion_qty, 
	shiphead.ware_code, 
	shiphead.other_cost_amt 

	DISPLAY func_type TO func attribute (white) 
	DISPLAY pr_shiphead.curr_code TO inv_curr_code attribute (green) 
	WHILE true 
		CALL input_lines() 
		IF image_flag = "Y" THEN 
			CALL set_count(new_arr_size) 
			LET arr_size = new_arr_size 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	IF int_flag != 0 OR quit_flag != 0 THEN 
		OPTIONS DELETE KEY f2, 
		INSERT KEY f1 
		LET resp = kandoomsg("A",8011,"") 
		#A8011 " Do you wish TO hold line information (y/n) " FOR
		IF resp = "N" 
		OR resp = "n" THEN 
			SELECT fob_ent_cost_amt, duty_ent_amt 
			INTO pr_shiphead.fob_ent_cost_amt, pr_shiphead.duty_ent_amt 
			FROM shiphead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ship_code = pr_shiphead.ship_code 
			IF status = notfound THEN 
				LET pr_shiphead.fob_ent_cost_amt = 0 
				LET pr_shiphead.duty_ent_amt = 0 
			END IF 
			FOR i = 1 TO arr_size 
				INITIALIZE st_shipdetl[i].* TO NULL 
				INITIALIZE pa_shipdetl[i].* TO NULL 
			END FOR 
			LET retain_flag = false 
			LET restart = false 
		ELSE 
			LET retain_flag = true 
			LET restart = false 
		END IF 
		LET int_flag = 0 
		LET quit_flag = 0 
		CLOSE WINDOW wl102 
		#CLOSE WINDOW wL101
		RETURN false 
	END IF 
	LET retain_flag = true 
	OPTIONS DELETE KEY f2, 
	INSERT KEY f1 
	CLOSE WINDOW wl102 
	RETURN true 
END FUNCTION 


FUNCTION input_lines() 
	DEFINE 
	st_fob_ext_ent_amt_old LIKE shipdetl.fob_ext_ent_amt, 
	st_duty_ext_ent_amt_old LIKE shipdetl.duty_ext_ent_amt, 
	pr_desc_text LIKE shipdetl.desc_text, 
	scrn SMALLINT 

	MESSAGE "ESC TO finish, F2 TO delete, F7 Tariff Totals, F8 Image" 
	attribute (yellow) 
	LET image_flag = "N" 
	INPUT ARRAY pa_shipdetl WITHOUT DEFAULTS FROM sr_shipdetl.* 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET pa_shipdetl[idx].part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY pa_shipdetl[idx].part_code 
					TO sr_shipdetl[scrn].part_code 

					IF idx > arr_count() THEN 
						LET last_window = 1 
					END IF 
					NEXT FIELD part_code 
			END CASE 
		ON KEY (F8) 
			LET pr_po_num = find_po(glob_rec_kandoouser.cmpy_code,pr_shiphead.vend_code, 
			pr_shiphead.ware_code) 
			IF pr_po_num > 0 THEN 
				CALL select_multipo_lines(glob_rec_kandoouser.cmpy_code, pr_po_num, 
				pr_shiphead.vend_code) 
				RETURNING new_arr_size 
				IF new_arr_size > 0 THEN 
					DISPLAY BY NAME pr_shiphead.fob_ent_cost_amt, 
					pr_shiphead.duty_ent_amt, 
					pr_shiphead.curr_code 

					LET image_flag = "Y" 
					EXIT INPUT 
				END IF 
			END IF 
		ON KEY (F7) 
			CALL tariff_review() 

		AFTER FIELD part_code 
			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_shipdetl[idx].part_code 
			AND serial_flag = 'Y' 
			IF status <> notfound THEN 
				LET msgresp = kandoomsg("I",9285,'') 
				#9285 Serial Items cannot be used.
				NEXT FIELD part_code 
			END IF 
			LET nxtfld = 0 
			IF pr_part_code = pa_shipdetl[idx].part_code 
			OR (pr_part_code IS NULL AND pa_shipdetl[idx].part_code IS null) THEN 
			ELSE 
				NEXT FIELD source_doc_num 
			END IF 
		BEFORE FIELD source_doc_num 
			IF pr_part_code <> pa_shipdetl[idx].part_code THEN 
				NEXT FIELD part_code 
			END IF 
			LET pr_part_code = NULL 
			# IF new product THEN initialise the DISPLAY line
			# this "if" IS this way around because of NULL "if" compares
			# ----change it AT your own peril .....
			IF (st_shipdetl[idx].part_code = pa_shipdetl[idx].part_code 
			OR (st_shipdetl[idx].part_code IS NULL 
			AND pa_shipdetl[idx].part_code IS null)) THEN 
				# IF the same product THEN SELECT previous entry....

				LET pr_shipdetl.* = st_shipdetl[idx].* 
			ELSE 
				LET pr_shipdetl.part_code = pa_shipdetl[idx].part_code 
				LET pr_shipdetl.ship_inv_qty = 0 
				LET pr_shipdetl.ship_rec_qty = 0 
				INITIALIZE pr_shipdetl.fob_unit_ent_amt TO NULL 
				INITIALIZE pr_shipdetl.duty_unit_ent_amt TO NULL 
				LET pr_shipdetl.fob_ext_ent_amt = 0 
				LET pr_shipdetl.duty_ext_ent_amt = 0 
				LET pr_shipdetl.tariff_code = NULL 
				LET pr_shipdetl.desc_text = NULL 
				LET pr_shipdetl.duty_rate_per = NULL 
			END IF 
			# pop up the window AND get the info...
			CALL ship_window() 
			# check TO see IF interrupt hit
			IF ans = "N" THEN 
				EXIT INPUT 
			END IF 
			# did we RETURN with a problem
			IF nxtfld = 1 THEN 
				LET pa_shipdetl[idx].part_code = " " 
				DISPLAY pa_shipdetl[idx].part_code TO sr_shipdetl[scrn].part_code 

				NEXT FIELD part_code 
			ELSE 
				LET nxtfld = 0 
				# SET up the stored line
				IF pr_shipdetl.ship_inv_qty IS NULL THEN 
					LET pr_shipdetl.ship_inv_qty = 0 
				END IF 
				IF pr_shipdetl.fob_unit_ent_amt IS NULL THEN 
					LET pr_shipdetl.fob_unit_ent_amt = 0 
				END IF 
				IF pr_shipdetl.fob_ext_ent_amt IS NULL THEN 
					LET pr_shipdetl.fob_ext_ent_amt = 0 
				END IF 
				IF pr_shipdetl.duty_ext_ent_amt IS NULL THEN 
					LET pr_shipdetl.duty_ext_ent_amt = 0 
				END IF 
				IF pr_shipdetl.duty_unit_ent_amt IS NULL THEN 
					LET pr_shipdetl.duty_unit_ent_amt = 0 
				END IF 
				CALL set_shipdetl() 
				# SET up the SCREEN ARRAY line FROM the window
				LET pa_shipdetl[idx].part_code = st_shipdetl[idx].part_code 
				LET pa_shipdetl[idx].source_doc_num = st_shipdetl[idx].source_doc_num 
				LET pa_shipdetl[idx].ship_inv_qty = st_shipdetl[idx].ship_inv_qty 
				LET pa_shipdetl[idx].fob_unit_ent_amt = 
				st_shipdetl[idx].fob_unit_ent_amt 
				LET pa_shipdetl[idx].tariff_code = st_shipdetl[idx].tariff_code 
				LET pa_shipdetl[idx].duty_unit_ent_amt = 
				st_shipdetl[idx].duty_unit_ent_amt 
				DISPLAY pa_shipdetl[idx].part_code, 
				pa_shipdetl[idx].source_doc_num 
				TO sr_shipdetl[scrn].part_code, 
				sr_shipdetl[scrn].source_doc_num 

				LET pr_desc_text = pr_shipdetl.desc_text 
				DISPLAY BY NAME pr_desc_text 

				IF pa_shipdetl[idx].ship_inv_qty = 0 
				AND pa_shipdetl[idx].part_code IS NULL THEN 
					LET pa_shipdetl[idx].ship_inv_qty = NULL 
				END IF 
				DISPLAY pa_shipdetl[idx].ship_inv_qty 
				TO sr_shipdetl[scrn].ship_inv_qty 

				IF pa_shipdetl[idx].fob_unit_ent_amt = 0 
				AND pa_shipdetl[idx].part_code IS NULL THEN 
					LET pa_shipdetl[idx].fob_unit_ent_amt = NULL 
				END IF 
				DISPLAY pa_shipdetl[idx].fob_unit_ent_amt, 
				pa_shipdetl[idx].tariff_code 
				TO sr_shipdetl[scrn].fob_unit_ent_amt, 
				sr_shipdetl[scrn].tariff_code 

				IF pa_shipdetl[idx].duty_unit_ent_amt = 0 
				AND pa_shipdetl[idx].part_code IS NULL THEN 
					LET pa_shipdetl[idx].duty_unit_ent_amt = NULL 
				END IF 
				DISPLAY pa_shipdetl[idx].duty_unit_ent_amt 
				TO sr_shipdetl[scrn].duty_unit_ent_amt 

			END IF 
			LET ins_flag = 1 
			NEXT FIELD duty_unit_ent_amt 
		ON KEY (F2) 
			IF st_shipdetl[idx].ship_rec_qty <> 0 THEN 
				ERROR " Unable TO delete line. Goods have been receipted" 
			ELSE 
				IF st_shipdetl[idx].fob_ext_ent_amt IS NULL THEN 
				ELSE 
					LET pr_shiphead.fob_ent_cost_amt 
					= pr_shiphead.fob_ent_cost_amt 
					- st_shipdetl[idx].fob_ext_ent_amt 
				END IF 

				IF st_shipdetl[idx].duty_ext_ent_amt IS NULL THEN 
				ELSE 
					LET pr_shiphead.duty_ent_amt = pr_shiphead.duty_ent_amt 
					- st_shipdetl[idx].duty_ext_ent_amt 
				END IF 
				DISPLAY BY NAME pr_shiphead.fob_ent_cost_amt, 
				pr_shiphead.duty_ent_amt, 
				pr_shiphead.curr_code 


			END IF 
			IF f_type != "E" THEN # edit session 
				#take row out of stored ARRAY - do NOT move acount=arr_count
				#as arr_count can alter without entering a BEFORE ROW-
				LET acount = arr_count() 
				FOR j = idx TO (acount - 1) 
					LET st_shipdetl[j].* = st_shipdetl[j+1].* 
					LET pa_shipdetl[j].* = pa_shipdetl[j+1].* 
				END FOR 
				INITIALIZE st_shipdetl[acount].* TO NULL 
				INITIALIZE pa_shipdetl[acount].* TO NULL 
				CALL set_count(acount - 1) 
				LET scrn1 = scrn 
				FOR i = idx TO idx + (3 - scrn) 
					DISPLAY pa_shipdetl[i].part_code , 
					pa_shipdetl[i].source_doc_num, 
					pa_shipdetl[i].ship_inv_qty, 
					pa_shipdetl[i].fob_unit_ent_amt, 
					pa_shipdetl[i].tariff_code, 
					pa_shipdetl[i].duty_unit_ent_amt 
					TO sr_shipdetl[scrn1].part_code, 
					sr_shipdetl[scrn1].source_doc_num, 
					sr_shipdetl[scrn1].ship_inv_qty, 
					sr_shipdetl[scrn1].fob_unit_ent_amt, 
					sr_shipdetl[scrn1].tariff_code, 
					sr_shipdetl[scrn1].duty_unit_ent_amt 

					LET scrn1 = scrn1 + 1 
				END FOR 
			ELSE 
				LET pa_shipdetl[idx].ship_inv_qty = 0 
				LET st_shipdetl[idx].ship_inv_qty = 0 
				LET st_shipdetl[idx].fob_ext_ent_amt = 0 
				LET st_shipdetl[idx].duty_ext_ent_amt = 0 
				DISPLAY pa_shipdetl[idx].ship_inv_qty TO 
				sr_shipdetl[scrn].ship_inv_qty 
			END IF 
		BEFORE INSERT 
			# add room FOR line in array
			LET acount = arr_count() 
			IF acount = max_shipdetls THEN 
			ELSE 
				FOR j = acount TO idx step -1 
					LET st_shipdetl[j+1].* = st_shipdetl[j].* 
				END FOR 
				INITIALIZE st_shipdetl[idx].* TO NULL 
			END IF 
			INITIALIZE pr_shipdetl.* TO NULL 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET firstime = 1 
			LET last_window = 1 
			LET pr_part_code = pa_shipdetl[idx].part_code 
			LET pr_desc_text = st_shipdetl[idx].desc_text 
			DISPLAY BY NAME pr_desc_text 

			IF st_shipdetl[idx].fob_ext_ent_amt IS NULL THEN 
				LET st_shipdetl[idx].fob_ext_ent_amt = 0 
			END IF 
			IF st_shipdetl[idx].duty_ext_ent_amt IS NULL THEN 
				LET st_shipdetl[idx].duty_ext_ent_amt = 0 
			END IF 
			LET st_fob_ext_ent_amt_old = st_shipdetl[idx].fob_ext_ent_amt 
			LET st_duty_ext_ent_amt_old = st_shipdetl[idx].duty_ext_ent_amt 
		AFTER ROW 
			# adjust header totals
			IF ins_flag = 1 THEN 
				IF st_shipdetl[idx].fob_ext_ent_amt IS NOT NULL THEN 
					LET pr_shiphead.fob_ent_cost_amt 
					= pr_shiphead.fob_ent_cost_amt 
					+ st_shipdetl[idx].fob_ext_ent_amt 
					- st_fob_ext_ent_amt_old 
				END IF 

				IF st_shipdetl[idx].duty_ext_ent_amt IS NOT NULL THEN 
					LET pr_shiphead.duty_ent_amt = pr_shiphead.duty_ent_amt 
					+ st_shipdetl[idx].duty_ext_ent_amt 
					- st_duty_ext_ent_amt_old 
				END IF 
				DISPLAY BY NAME pr_shiphead.fob_ent_cost_amt, 
				pr_shiphead.duty_ent_amt, 
				pr_shiphead.curr_code 

				LET ins_flag = 0 
			END IF 
			INITIALIZE pr_shipdetl.* TO NULL 

		AFTER INPUT 
			# in CASE last line was a window - arr_count out by 1
			LET arr_size = arr_count() 
			# IF CANCEL has NOT been pressed
			IF int_flag = 0 AND quit_flag = 0 THEN 
				FOR i = 1 TO arr_size 
					SELECT unique 1 FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pa_shipdetl[i].part_code 
					AND serial_flag = 'Y' 
					IF status <> notfound THEN 
						LET msgresp = kandoomsg("I",9293,pa_shipdetl[i].part_code) 
						#9293 Serial Products cannot be used. Remove Product
						NEXT FIELD part_code 
					END IF 
				END FOR 
			END IF 
			IF last_window = 1 THEN 
				LET arr_size = arr_size + 1 
				IF arr_size > max_shipdetls THEN 
					LET arr_size = max_shipdetls 
				END IF 
			END IF 
			# in CASE blank lines AT bottom of the SCREEN - will fix up
			IF arr_size > 0 THEN 
				WHILE (pa_shipdetl[arr_size].part_code IS NULL 
					AND pa_shipdetl[arr_size].fob_unit_ent_amt IS NULL 
					AND pa_shipdetl[arr_size].duty_unit_ent_amt IS null) 
					LET arr_size = arr_size - 1 
					IF arr_size = 0 THEN 
						EXIT WHILE 
					END IF 
				END WHILE 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 
