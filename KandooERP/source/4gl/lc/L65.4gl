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

	Source code beautified by beautify.pl on 2020-01-02 18:38:33	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L65 allows the user TO Credit Scan Shipments   that have the
# potentail TO be finalised, AND flag the ready FOR finalisation
#
# potential shipments are those that have
#   shipdetl.rec_qty > 0

GLOBALS 
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_customer RECORD LIKE customer.*, 
	pt_shiphead RECORD LIKE shiphead.*, 
	pa_shiphead array[250] OF RECORD 
		final_flag LIKE shiphead.finalised_flag, 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		vend_code LIKE shiphead.vend_code, 
		total_amt LIKE shiphead.total_amt, 
		eta_curr_date LIKE shiphead.eta_curr_date, 
		ship_status_code LIKE shiphead.ship_status_code 
	END RECORD, 
	pr_final_qty, idx, id_flag, scrn, cnt, err_flag SMALLINT, 
	sel_text, where_part CHAR(1500), 
	rep CHAR(1), 
	func_type CHAR(14), 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_ship_code LIKE shiphead.ship_code 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("L65") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	OPEN WINDOW l166 with FORM "L166" 
	CALL windecoration_l("L166") -- albo kd-763 

	WHILE doit() 
	END WHILE 
	CLOSE WINDOW l166 
	OPTIONS DELETE KEY f2, 
	INSERT KEY f1 
END MAIN 

FUNCTION doit() 
	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME where_part ON 
	shiphead.ship_code, 
	shiphead.ship_type_code, 
	shiphead.vend_code, 
	shiphead.total_amt, 
	shiphead.eta_curr_date, 
	shiphead.ship_status_code 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	LET sel_text = 
	"SELECT distinct shiphead.ship_code, shiphead.cmpy_code ", 
	"FROM shiphead, shipdetl ", 
	" WHERE shiphead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND shipdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND shiphead.ship_code = shipdetl.ship_code ", 
	" AND shipdetl.ship_rec_qty > 0 ", 
	" AND shiphead.finalised_flag NOT in ('Y','P') AND ", 
	" shiphead.ship_type_ind = 3 AND ", 
	where_part clipped, 
	" ORDER BY shiphead.cmpy_code, shiphead.ship_code " 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	PREPARE getord FROM sel_text 
	DECLARE c_ord CURSOR FOR getord 
	FOR idx = 1 TO 100 
		INITIALIZE pa_shiphead[idx].* TO NULL 
	END FOR 
	LET idx = 0 
	FOREACH c_ord INTO pr_ship_code 
		LET idx = idx + 1 
		SELECT * 
		INTO pr_shiphead.* 
		FROM shiphead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ship_code = pr_ship_code 
		LET pa_shiphead[idx].ship_code = pr_shiphead.ship_code 
		LET pa_shiphead[idx].vend_code = pr_shiphead.vend_code 
		LET pa_shiphead[idx].ship_type_code = pr_shiphead.ship_type_code 
		LET pa_shiphead[idx].total_amt = pr_shiphead.total_amt 
		LET pa_shiphead[idx].eta_curr_date = pr_shiphead.eta_curr_date 
		LET pa_shiphead[idx].ship_status_code = pr_shiphead.ship_status_code 
		IF idx > 240 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("L",9019,"") 
		RETURN true 
	END IF 
	LET pr_final_qty = 0 
	CALL set_count (idx) 
	LET msgresp = kandoomsg("L",1013,"") 
	#1012 Enter on line TO View;  F7 TO Flag.
	WHILE true 
		INPUT ARRAY pa_shiphead WITHOUT DEFAULTS FROM sr_shiphead.* 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_shiphead.ship_code = pa_shiphead[idx].ship_code 
				LET pr_shiphead.vend_code = pa_shiphead[idx].vend_code 
				LET pr_shiphead.ship_type_code = pa_shiphead[idx].ship_type_code 
				LET pr_shiphead.total_amt = pa_shiphead[idx].total_amt 
				LET pr_shiphead.eta_curr_date = pa_shiphead[idx].eta_curr_date 
				LET pr_shiphead.ship_status_code = pa_shiphead[idx].ship_status_code 
				DISPLAY pa_shiphead[idx].* TO sr_shiphead[scrn].* 

				LET id_flag = 0 
			AFTER FIELD ship_code 
				IF arr_curr() = arr_count() 
				AND fgl_lastkey() = fgl_keyval("down") THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the ...
					NEXT FIELD ship_code 
				END IF 
			BEFORE FIELD ship_type_code 
				IF pr_shiphead.ship_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
				ELSE 
					CALL scanner() 
					NEXT FIELD ship_code 
				END IF 
				NEXT FIELD ship_code 
			ON KEY (F7) 
				IF pr_shiphead.ship_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
				ELSE 
					IF pa_shiphead[idx].final_flag = "*" THEN 
						LET pa_shiphead[idx].final_flag = " " 
						LET pr_final_qty = pr_final_qty - 1 
					ELSE 
						LET pa_shiphead[idx].final_flag = "*" 
						LET pr_final_qty = pr_final_qty + 1 
					END IF 
					DISPLAY pa_shiphead[idx].final_flag TO sr_shiphead[scrn].final_flag 
				END IF 
			AFTER ROW 
				DISPLAY pa_shiphead[idx].* TO sr_shiphead[scrn].* 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			IF pr_final_qty > 0 THEN 
				LET msgresp = kandoomsg("L",8002,"") 
				#8002 Do you wish TO abandon changes? (Y/N)
				IF msgresp = "Y" THEN 
					EXIT WHILE 
				ELSE 
					CONTINUE WHILE 
				END IF 
			END IF 
		END IF 
		IF pr_final_qty > 0 THEN 
			FOR idx = 1 TO arr_count() 
				IF pa_shiphead[idx].ship_code IS NOT NULL 
				AND pa_shiphead[idx].final_flag = "*" THEN 
					UPDATE shiphead 
					SET finalised_flag = "P" 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ship_code = pa_shiphead[idx].ship_code 
				END IF 
			END FOR 
		END IF 
		EXIT WHILE 
	END WHILE 
	RETURN true 
END FUNCTION 


FUNCTION scanner() 
	OPEN WINDOW scanwind with FORM "L164" 
	CALL windecoration_l("L164") -- albo kd-763 
	SELECT o.*, c.* 
	INTO pr_shiphead.*, pr_customer.* 
	FROM shiphead o, customer c 
	WHERE o.ship_code = pa_shiphead[idx].ship_code 
	AND c.cust_code = pr_shiphead.vend_code 
	AND o.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND c.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY BY NAME 
	pr_shiphead.vend_code, 
	pr_customer.name_text, 
	pr_shiphead.ship_code, 
	pr_shiphead.ship_type_code, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.curr_code, 
	pr_shiphead.ship_status_code, 
	pr_shiphead.ware_code, 
	pr_shiphead.total_amt, 
	pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.duty_ent_amt, 
	pr_shiphead.entry_code, 
	pr_shiphead.entry_date, 
	pr_shiphead.com1_text, 
	pr_shiphead.rev_num, 
	pr_shiphead.com2_text, 
	pr_shiphead.rev_date 


	MENU " Detailed Inquiry" 
		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Lines" " DISPLAY shipment line details" 
			LET func_type = "View Shipment" 
			CALL ship_cred_show(glob_rec_kandoouser.cmpy_code, pr_shiphead.vend_code, 
			pr_shiphead.ship_code, func_type) 
			NEXT option "Exit" 
		COMMAND "Status" " DISPLAY shipment lines STATUS" 
			CALL ship_stat(glob_rec_kandoouser.cmpy_code, pr_shiphead.vend_code, pr_shiphead.ship_code) 
			NEXT option "Exit" 
		COMMAND "Other Costs" " DISPLAY breakdown of other costs" 
			CALL show_shipcost(glob_rec_kandoouser.cmpy_code, pr_shiphead.ship_code) 
			NEXT option "Exit" 
		COMMAND KEY (interrupt, escape, "E") "Exit" " RETURN TO main SCREEN" 
			LET int_flag = 0 
			LET quit_flag = 0 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW scanwind 
	RETURN 
END FUNCTION 

