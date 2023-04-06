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

	Source code beautified by beautify.pl on 2020-01-02 18:38:31	$Id: $
}




# Perform INPUT of shipment Line Items

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L51_GLOBALS.4gl" 


DEFINE 
which CHAR(3), 
new_arr_size,scrn1, last_window, j,acount, ins_flag, del_flag SMALLINT, 
image_flag CHAR(1) 

FUNCTION lineitem() 

	DEFINE resp CHAR(1) 
	# need TO turn off DELETE KEY, as we need control
	OPTIONS DELETE KEY f36 

	INITIALIZE pr_shipdetl.* TO NULL 
	LET nxtfld = 0 
	LET firstime = 1 
	LET del_flag = 0 
	LET ins_flag = 0 


	OPEN WINDOW wl102 with FORM "L147" 
	CALL windecoration_l("L147") -- albo kd-761 

	IF NOT retain_flag THEN 
		DECLARE curser_item CURSOR FOR 
		SELECT shipdetl.* INTO pr_shipdetl.* FROM shipdetl 
		WHERE ship_code = pr_shiphead.ship_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET idx = 0 
		FOREACH curser_item 
			LET idx = idx + 1 
			LET pa_shipdetl[idx].part_code = pr_shipdetl.part_code 
			LET pa_shipdetl[idx].desc_text = pr_shipdetl.desc_text 
			LET pa_shipdetl[idx].source_doc_num = pr_shipdetl.source_doc_num 
			LET pa_shipdetl[idx].doc_line_num = pr_shipdetl.doc_line_num 
			LET pa_shipdetl[idx].ship_inv_qty = pr_shipdetl.ship_inv_qty 
			LET pa_shipdetl[idx].fob_unit_ent_amt = pr_shipdetl.fob_unit_ent_amt 
			LET pa_shipdetl[idx].fob_ext_ent_amt = pr_shipdetl.fob_ext_ent_amt 
			LET st_shipdetl[idx].* = pr_shipdetl.* 
			IF idx > 100 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		CALL set_count(idx) 
	ELSE 
		# this IS the CASE of a RETURN FROM the L51c module via DEL key

		FOR i = 1 TO arr_size 
			LET pa_shipdetl[i].part_code = st_shipdetl[i].part_code 
			LET pa_shipdetl[i].desc_text = st_shipdetl[i].desc_text 
			LET pa_shipdetl[i].source_doc_num = st_shipdetl[i].source_doc_num 
			LET pa_shipdetl[i].doc_line_num = st_shipdetl[i].doc_line_num 
			LET pa_shipdetl[i].ship_inv_qty = st_shipdetl[i].ship_inv_qty 
			LET pa_shipdetl[i].fob_unit_ent_amt = st_shipdetl[i].fob_unit_ent_amt 
			LET pa_shipdetl[i].fob_ext_ent_amt = st_shipdetl[i].fob_ext_ent_amt 
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
	pr_shiphead.ship_status_code, 
	pr_shipstatus.desc_text, 
	pr_shiphead.conversion_qty, 
	pr_shiphead.ware_code, 
	pr_shiphead.curr_code 
	TO shiphead.vend_code, 
	shiphead.ship_code, 
	shiphead.ship_type_code, 
	shiphead.fob_ent_cost_amt, 
	shiphead.curr_code, 
	vendor.name_text, 
	shiphead.duty_ent_amt, 
	shiphead.eta_curr_date, 
	shiphead.ship_status_code, 
	shipstatus.desc_text, 
	shiphead.conversion_qty, 
	shiphead.ware_code, 
	inv_curr_code 

	DISPLAY func_type TO func attribute(green) 
	WHILE true 
		CALL input_lines() 
		IF image_flag = "Y" THEN 
			CALL set_count(new_arr_size) 
			LET arr_size = new_arr_size 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	# has interrupt OR quit been hit
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		OPTIONS DELETE KEY f2 
		{  -- albo
		            OPEN WINDOW wfO119 AT 10,4 with 1 rows, 70 columns
		               attribute (border, reverse)
		            prompt " Do you wish TO hold line information (y/n) " FOR
		         CHAR resp
		}
		LET resp = promptYN(""," Do you wish TO hold line information (y/n) ","Y") -- albo 
		IF resp = "N" 
		OR resp = "n" THEN 
			LET retain_flag = false 
			LET restart = true 
		ELSE 
			LET retain_flag = true 
			LET restart = false 
		END IF 
		--            CLOSE WINDOW wfO119
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN false 
	END IF 
	LET retain_flag = true 
	OPTIONS DELETE KEY f2 
	#CLOSE WINDOW wL102
	RETURN true 

END FUNCTION 


FUNCTION input_lines() 
	DEFINE 
	scrn SMALLINT 

	MESSAGE "ESC TO finish, F1 TO add, F2 TO delete " 
	attribute (yellow) 
	LET image_flag = "N" 
	INPUT ARRAY pa_shipdetl WITHOUT DEFAULTS FROM sr_shipdetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","L51b","input-arr-pa_shipdetl-1") -- albo 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET del_flag = 0 
			LET firstime = 1 
			LET last_window = 1 
			LET pr_source_doc_num = pa_shipdetl[idx].source_doc_num 

		ON KEY (control-b) 
			CASE 
				WHEN infield (source_doc_num) 
					LET pr_po_num = find_po(glob_rec_kandoouser.cmpy_code,pr_shiphead.vend_code) 
					CALL select_multipo_lines(glob_rec_kandoouser.cmpy_code, pr_po_num, 
					pr_shiphead.vend_code) 
					RETURNING new_arr_size 
					IF new_arr_size > 0 THEN 
						DISPLAY BY NAME pr_shiphead.fob_ent_cost_amt, 
						pr_shiphead.duty_ent_amt, 
						pr_shiphead.curr_code 
						attribute (magenta) 
						LET image_flag = "Y" 
						EXIT INPUT 
					END IF 

			END CASE 

		AFTER FIELD source_doc_num 
			IF pr_source_doc_num IS NOT NULL 
			AND pr_source_doc_num != pa_shipdetl[idx].source_doc_num THEN 
				LET pa_shipdetl[idx].source_doc_num = 
				pr_source_doc_num 
				NEXT FIELD source_doc_num 
			END IF 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("del") THEN 
			ELSE 
				IF pa_shipdetl[idx].source_doc_num IS NOT NULL THEN 
					SELECT 1 
					FROM purchhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = pr_shiphead.vend_code 
					AND order_num = pa_shipdetl[idx].source_doc_num 
					IF status = notfound THEN 
						ERROR " No PO found. Try window" 
						NEXT FIELD source_doc_num 
					END IF 
				END IF 
			END IF 
		AFTER FIELD doc_line_num 
			LET nxtfld = 0 
			IF pr_source_doc_num = pa_shipdetl[idx].source_doc_num 
			OR (pr_source_doc_num IS NULL AND pa_shipdetl[idx].source_doc_num) THEN 
			ELSE 
				NEXT FIELD doc_line_num 
			END IF 


		BEFORE FIELD doc_line_num 
			IF pr_source_doc_num <> pa_shipdetl[idx].source_doc_num THEN 
				NEXT FIELD doc_line_num 
			END IF 

			# LET pr_source_doc_num = NULL
			# IF new product THEN initialise the DISPLAY line
			# this "if" IS this way around because of NULL "if" compares
			# ----change it AT your own peril .....
			IF (st_shipdetl[idx].source_doc_num = 
			pa_shipdetl[idx].source_doc_num 
			OR (st_shipdetl[idx].source_doc_num IS NULL 
			AND pa_shipdetl[idx].source_doc_num IS null)) THEN 
				# IF the same product THEN SELECT previous entry....

				#LET pr_shipdetl.part_code = pa_shipdetl[idx].part_code
				#LET pr_shipdetl.source_doc_num = st_shipdetl[idx].source_doc_num
				#LET pr_shipdetl.ship_inv_qty = st_shipdetl[idx].ship_inv_qty
				#LET pr_shipdetl.ship_rec_qty = st_shipdetl[idx].ship_rec_qty
				#LET pr_shipdetl.fob_unit_ent_amt = st_shipdetl[idx].fob_unit_ent_amt
				#LET pr_shipdetl.fob_ext_ent_amt = st_shipdetl[idx].fob_ext_ent_amt
				#LET pr_shipdetl.tariff_code = st_shipdetl[idx].tariff_code
				#LET pr_shipdetl.duty_unit_ent_amt = st_shipdetl[idx].duty_unit_ent_amt
				#LET pr_shipdetl.duty_ext_ent_amt = st_shipdetl[idx].duty_ext_ent_amt
				#LET pr_shipdetl.desc_text = st_shipdetl[idx].desc_text
				#LET pr_shipdetl.landed_cost = st_shipdetl[idx].landed_cost
				#LET pr_shipdetl.duty_rate_per = st_shipdetl[idx].duty_rate_per
				LET pr_shipdetl.* = st_shipdetl[idx].* 
			ELSE 
				LET pr_shipdetl.part_code = 0 
				LET pr_shipdetl.source_doc_num = pa_shipdetl[idx].source_doc_num 
				LET pr_shipdetl.doc_line_num = 0 
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

			# take off the current line FROM shipment totals
			IF firstime = 1 THEN 
				CALL minusline() 
				LET firstime = 0 
			END IF 

			# pop up the window AND get the info...
			CALL ship_window() 

			# check TO see IF interrupt hit
			IF ans = "N" THEN 
				EXIT INPUT 
			END IF 
			CURRENT WINDOW IS wl102 
			# did we RETURN with a problem
			IF nxtfld = 1 THEN 
				LET pa_shipdetl[idx].source_doc_num = " " 
				DISPLAY pa_shipdetl[idx].source_doc_num TO sr_shipdetl[scrn].source_doc_num 
				NEXT FIELD source_doc_num 
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
				LET pa_shipdetl[idx].desc_text = st_shipdetl[idx].desc_text 
				LET pa_shipdetl[idx].source_doc_num = st_shipdetl[idx].source_doc_num 
				LET pa_shipdetl[idx].doc_line_num = st_shipdetl[idx].doc_line_num 
				LET pa_shipdetl[idx].ship_inv_qty = st_shipdetl[idx].ship_inv_qty 
				LET pa_shipdetl[idx].fob_unit_ent_amt = 
				st_shipdetl[idx].fob_unit_ent_amt 
				LET pa_shipdetl[idx].fob_ext_ent_amt = 
				st_shipdetl[idx].fob_ext_ent_amt 
				DISPLAY pa_shipdetl[idx].part_code TO sr_shipdetl[scrn].part_code 
				DISPLAY pa_shipdetl[idx].desc_text TO sr_shipdetl[scrn].desc_text 
				DISPLAY pa_shipdetl[idx].source_doc_num TO sr_shipdetl[scrn].source_doc_num 
				DISPLAY pa_shipdetl[idx].doc_line_num TO sr_shipdetl[scrn].doc_line_num 
				DISPLAY pa_shipdetl[idx].ship_inv_qty TO sr_shipdetl[scrn].ship_inv_qty 
				#IF pa_shipdetl[idx].fob_unit_ent_amt = 0
				#AND pa_shipdetl[idx].source_doc_num IS NULL THEN
				#LET pa_shipdetl[idx].fob_unit_ent_amt = NULL
				#END IF
				#DISPLAY pa_shipdetl[idx].fob_unit_ent_amt TO
				#sr_shipdetl[scrn].fob_unit_ent_amt
				#IF pa_shipdetl[idx].fob_ext_ent_amt = 0
				#AND pa_shipdetl[idx].source_doc_num IS NULL THEN
				#LET pa_shipdetl[idx].fob_ext_ent_amt = NULL
				#END IF
				DISPLAY pa_shipdetl[idx].fob_ext_ent_amt TO sr_shipdetl[scrn].fob_ext_ent_amt 
			END IF 

			LET ins_flag = 1 
			NEXT FIELD fob_ext_ent_amt 

		ON KEY (F2) 
			IF st_shipdetl[idx].ship_rec_qty <> 0 THEN 
				ERROR " Unable TO delete line. Goods have been receipted" 
			END IF 
			CALL minusline() 

			IF f_type != "E" THEN # edit session 
				# take row out of stored ARRAY - do NOT move acount=arr_count
				# as arr_count can alter without entering a BEFORE ROW-
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
					DISPLAY pa_shipdetl[i].part_code TO 
					sr_shipdetl[scrn1].part_code 
					DISPLAY pa_shipdetl[i].desc_text TO 
					sr_shipdetl[scrn1].desc_text 
					DISPLAY pa_shipdetl[i].source_doc_num TO 
					sr_shipdetl[scrn1].source_doc_num 
					DISPLAY pa_shipdetl[i].doc_line_num TO 
					sr_shipdetl[scrn1].doc_line_num 
					DISPLAY pa_shipdetl[i].ship_inv_qty TO 
					sr_shipdetl[scrn1].ship_inv_qty 
					DISPLAY pa_shipdetl[i].fob_unit_ent_amt TO 
					sr_shipdetl[scrn1].fob_unit_ent_amt 
					DISPLAY pa_shipdetl[i].fob_ext_ent_amt TO 
					sr_shipdetl[scrn1].fob_ext_ent_amt 
					LET scrn1 = scrn1 + 1 
				END FOR 
				LET del_flag = 1 
			ELSE 
				LET pa_shipdetl[idx].ship_inv_qty = 0 
				LET st_shipdetl[idx].ship_inv_qty = 0 
				LET st_shipdetl[idx].fob_ext_ent_amt = 0 
				LET st_shipdetl[idx].duty_ext_ent_amt = 0 
				DISPLAY pa_shipdetl[idx].ship_inv_qty TO 
				sr_shipdetl[scrn].ship_inv_qty 
			END IF 

		AFTER ROW 
			# adjust header totals
			IF ins_flag = 1 THEN 
				CALL plusline() 
				LET ins_flag = 0 
			END IF 
			# MESSAGE "Press ESC TO finish the shipment OR RETURN on new line TO add" attribute (yellow)
			INITIALIZE pr_shipdetl.* TO NULL 
			#   NEXT FIELD source_doc_num


		AFTER INPUT 
			# in CASE last line was a window - arr_count out by 1 (believe it)
			LET arr_size = arr_count() 
			IF last_window = 1 THEN 
				LET arr_size = arr_size + 1 
			END IF 
			# in CASE blank lines AT bottom of the SCREEN - will fix up
			IF arr_size > 0 THEN 
				WHILE (pa_shipdetl[arr_size].part_code IS NULL 
					AND pa_shipdetl[arr_size].fob_unit_ent_amt IS NULL 
					AND pa_shipdetl[arr_size].fob_ext_ent_amt IS null) 
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
