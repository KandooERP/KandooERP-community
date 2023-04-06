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
# common/note_disp.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION shipshow(p_cmpy_code,p_vend_code,p_ship_code,p_func_type)
#
# \brief module - shipfunc
# Purpose - showship. Displays shipment header AND allows the user
#           TO view details
############################################################
FUNCTION shipshow(p_cmpy_code,p_vend_code,p_ship_code,p_func_type) 
	DEFINE p_cmpy_code LIKE vendor.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE p_ship_code LIKE shiphead.ship_code 
	DEFINE p_func_type CHAR(14) 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_shipstatus RECORD LIKE shipstatus.* 
	DEFINE l_rec_shipdetl RECORD LIKE shipdetl.* 
	DEFINE l_arr_rec_shipdetl DYNAMIC ARRAY OF #array [301] OF RECORD 
		RECORD 
			part_code LIKE shipdetl.part_code, 
			source_doc_num LIKE shipdetl.source_doc_num, 
			ship_inv_qty LIKE shipdetl.ship_inv_qty, 
			fob_unit_ent_amt LIKE shipdetl.fob_unit_ent_amt, 
			tariff_code LIKE shipdetl.tariff_code, 
			duty_unit_ent_amt LIKE shipdetl.duty_unit_ent_amt 
		END RECORD 
	DEFINE l_desc_text LIKE shipdetl.desc_text 
	DEFINE l_rec_cat_codecat RECORD LIKE category.* 
	DEFINE l_idx SMALLINT 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		INITIALIZE l_rec_shipdetl.* TO NULL 
		SELECT * INTO l_rec_shiphead.* FROM shiphead 
		WHERE shiphead.cmpy_code = p_cmpy_code 
		AND shiphead.vend_code = p_vend_code 
		AND shiphead.ship_code = p_ship_code 
		CASE 
			WHEN l_rec_shiphead.ship_type_ind = 1 
				LET p_func_type = " Import " 
			WHEN l_rec_shiphead.ship_type_ind = 2 
				LET p_func_type = " PO RETURN " 
			WHEN l_rec_shiphead.ship_type_ind = 3 
				LET p_func_type = "Credit Returns" 
		END CASE 
		WHENEVER ERROR CONTINUE 
		IF (status = notfound) THEN 
			ERROR "Shipment header NOT found" 
			SLEEP 2 
		END IF 
		SELECT * INTO l_rec_shipstatus.* FROM shipstatus 
		WHERE cmpy_code = p_cmpy_code 
		AND ship_status_code = l_rec_shiphead.ship_status_code 
		IF (status = notfound) THEN 
			ERROR "Shipment STATUS NOT found" 
			SLEEP 2 
		END IF 
		SELECT * INTO l_rec_vendor.* FROM vendor 
		WHERE cmpy_code = p_cmpy_code 
		AND vend_code = p_vend_code 
		IF (status = notfound) THEN 
			ERROR "Vendor master NOT found" 
			SLEEP 2 
		END IF 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		OPEN WINDOW L102 with FORM "L102" 
		CALL winDecoration_l("L102") -- albo kd-752 

		DECLARE curser_item CURSOR FOR 
		SELECT shipdetl.* INTO l_rec_shipdetl.* FROM shipdetl 
		WHERE shipdetl.ship_code = l_rec_shiphead.ship_code 
		AND shipdetl.cmpy_code = p_cmpy_code 
		ORDER BY line_num 
		LET l_idx = 0 
		FOREACH curser_item 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_shipdetl[l_idx].part_code = l_rec_shipdetl.part_code 
			LET l_arr_rec_shipdetl[l_idx].source_doc_num = l_rec_shipdetl.source_doc_num 
			LET l_arr_rec_shipdetl[l_idx].ship_inv_qty = l_rec_shipdetl.ship_inv_qty 
			LET l_arr_rec_shipdetl[l_idx].fob_unit_ent_amt = l_rec_shipdetl.fob_unit_ent_amt 
			LET l_arr_rec_shipdetl[l_idx].tariff_code = l_rec_shipdetl.tariff_code 
			LET l_arr_rec_shipdetl[l_idx].duty_unit_ent_amt = l_rec_shipdetl.duty_unit_ent_amt 
			IF l_idx > 300 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
 

		MESSAGE 
		"ESC TO EXIT,CTRL V view STATUS,CTRL N view notes,RETURN details " 
		attribute(yellow) 

		DISPLAY BY NAME 
			l_rec_shiphead.vend_code, 
			l_rec_shiphead.ship_code, 
			l_rec_shiphead.ship_type_code, 
			l_rec_vendor.name_text, 
			l_rec_shiphead.eta_curr_date, 
			l_rec_shiphead.vessel_text, 
			l_rec_shiphead.discharge_text, 
			l_rec_shiphead.ship_status_code, 
			l_rec_shipstatus.desc_text, 
			l_rec_shiphead.conversion_qty, 
			l_rec_shiphead.ware_code 
		DISPLAY BY NAME 
			l_rec_shiphead.fob_ent_cost_amt, 
			l_rec_shiphead.curr_code, 
			l_rec_shiphead.duty_ent_amt, 
			l_rec_shiphead.fob_curr_cost_amt, 
			l_rec_shiphead.duty_inv_amt, 
			l_rec_shiphead.other_cost_amt 

		DISPLAY p_func_type TO func attribute(green) 
		DISPLAY l_rec_shiphead.curr_code TO shiphead.curr_code 

		INPUT ARRAY l_arr_rec_shipdetl WITHOUT DEFAULTS FROM sr_shipdetl.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","shipfunc","input-arr-shipdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#        LET scrn = scr_line()
				SELECT * INTO l_rec_shipdetl.* FROM shipdetl 
				WHERE shipdetl.cmpy_code = p_cmpy_code 
				AND shipdetl.ship_code = p_ship_code 
				AND shipdetl.line_num = l_idx 
				LET l_desc_text = l_rec_shipdetl.desc_text 
				DISPLAY BY NAME l_desc_text 

			ON ACTION "SHIPPING STATISTIC" --ON KEY (F5) 
				CALL ship_stat(p_cmpy_code, l_rec_shiphead.vend_code, l_rec_shiphead.ship_code) 

			--ON KEY (control-v) 
			--	CALL ship_stat(p_cmpy_code, l_rec_shiphead.vend_code, l_rec_shiphead.ship_code) 

			ON ACTION "NOTES" --ON KEY (control-n) 
				SELECT * INTO l_rec_shipdetl.* 
				FROM shipdetl 
				WHERE shipdetl.cmpy_code = p_cmpy_code 
				AND shipdetl.ship_code = p_ship_code 
				AND shipdetl.line_num = l_idx 
				IF status = notfound THEN 
					ERROR "Shipment line NOT found" 
					SLEEP 3 
					EXIT program 
				END IF 
				IF l_rec_shipdetl.desc_text[1,3] = "###" 
				AND l_rec_shipdetl.desc_text[16,18] = "###" THEN 
					CALL note_disp(p_cmpy_code,l_rec_shipdetl.desc_text[4,15]) 
				ELSE 
					ERROR "No notes TO view" 
					SLEEP 2 
				END IF 

			BEFORE FIELD source_doc_num 
				SELECT * INTO l_rec_shipdetl.* FROM shipdetl 
				WHERE cmpy_code = p_cmpy_code 
				AND shipdetl.ship_code = l_rec_shiphead.ship_code 
				AND shipdetl.line_num = l_idx 
				# pop up the window AND show the info...
				CALL detl_show(p_cmpy_code, l_rec_shipdetl.*, l_rec_shiphead.*) 
				CURRENT WINDOW IS L102 

			BEFORE DELETE 
				ERROR "This IS a DISPLAY FUNCTION only, delete has no affect on data" 

			BEFORE INSERT 
				ERROR "This IS a DISPLAY FUNCTION only, INSERT has no affect on data" 

			AFTER ROW 
				MESSAGE 
				"ESC TO EXIT,CTRL V view STATUS,CTRL N view notes,RETURN details " 
				attribute (yellow) 
				INITIALIZE l_rec_shipdetl.* TO NULL 

		END INPUT 

		CLOSE WINDOW L102 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 

		RETURN 
END FUNCTION 
############################################################
# END FUNCTION shipshow(p_cmpy_code,p_vend_code,p_ship_code,p_func_type)
############################################################


############################################################
# FUNCTION detl_show(p_cmpy_code, p_rec_shipdetl, p_rec_shiphead)
#
#
############################################################
FUNCTION detl_show(p_cmpy_code,p_rec_shipdetl,p_rec_shiphead) 
	DEFINE p_cmpy_code LIKE vendor.cmpy_code 
	DEFINE p_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE p_rec_shipdetl RECORD LIKE shipdetl.* 
	DEFINE l_rec_tariff RECORD LIKE tariff.* 
	DEFINE l_duty_ext_ent_amt LIKE shipdetl.duty_ext_ent_amt 
	DEFINE l_cost_amt MONEY(10,2) 

	OPEN WINDOW L103 with FORM "L103" 
	CALL winDecoration_l("L103") -- albo kd-752 

	LET l_cost_amt = p_rec_shipdetl.fob_unit_ent_amt / p_rec_shiphead.conversion_qty 

	DISPLAY BY NAME 
		p_rec_shipdetl.part_code, 
		p_rec_shipdetl.desc_text, 
		p_rec_shipdetl.source_doc_num, 
		p_rec_shipdetl.doc_line_num, 
		p_rec_shipdetl.ship_inv_qty, 
		p_rec_shipdetl.ship_rec_qty, 
		p_rec_shipdetl.fob_unit_ent_amt, 
		p_rec_shiphead.curr_code, 
		p_rec_shipdetl.fob_ext_ent_amt, 
		p_rec_shipdetl.tariff_code, 
		p_rec_shipdetl.duty_ext_ent_amt, 
		p_rec_shipdetl.duty_rate_per 

	IF p_rec_shipdetl.part_code IS NULL THEN 

		OPEN WINDOW L142 with FORM "L142" 
		CALL winDecoration_l("L142") 

		DISPLAY BY NAME p_rec_shipdetl.acct_code 

		CALL eventsuspend()
		CLOSE WINDOW L142 

	ELSE 
		CALL eventsuspend()
	END IF 

	CLOSE WINDOW L103 
END FUNCTION 
############################################################
# END FUNCTION detl_show(p_cmpy_code, p_rec_shipdetl, p_rec_shiphead)
############################################################