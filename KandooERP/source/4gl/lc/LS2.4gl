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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../lc/L_LC_GLOBALS.4gl"
GLOBALS "../lc/LS_GROUP_GLOBALS.4gl" 
GLOBALS "../lc/LS2_GLOBALS.4gl" 

# \brief module LS2 allows the user TO Finalise Credit Shipments

MAIN 
	CALL authenticate("LS2") 

	DEFER interrupt 
	DEFER quit 

	#  SET up temp table
	CREATE temp TABLE posttemp 
	( 
	tran_type_ind CHAR(3), 
	ref_num INTEGER, 
	ref_text CHAR(8), 
	acct_code CHAR(18), 
	desc_text CHAR(40), 
	debit_amt money(10,2), 
	credit_amt money(10,2), 
	base_debit_amt money(10,2), 
	base_credit_amt money(10,2), 
	currency_code CHAR(3), 
	conv_qty FLOAT, 
	tran_date DATE, 
	stats_qty DECIMAL(15,3) ) with no LOG 

	SELECT * INTO pr_glparms.* FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U","5107","") 
		#U5107 "Genenal Ledger Paramters Not Set Up; Refer Menu GZP
		EXIT program 
	END IF 
	SELECT * INTO pr_smparms.* FROM smparms 
	WHERE key_num = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U","5112","") 
		#U5112 "Landed Costing Parameters Not Set Up; Refer Menu LZP
		EXIT program 
	END IF 
	SELECT * INTO pr_arparms.* FROM arparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U","5101","") 
		#U5101 " AR Parameters missing. Add using AZP"
		EXIT program 
	END IF 
	SELECT * INTO pr_inparms.* FROM inparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U","5109","") 
		#U5109 "Inventory Paramters Not Set Up; Refer Menu IZP
		EXIT program 
	END IF 

	LET display_ship_code = "N" 
	LET ans = "Y" 
	WHILE ans = "Y" 
		CALL ship_select() 
	END WHILE 
END MAIN 


FUNCTION ship_select() 
	DEFINE 
	pa_shiphead array[250] OF RECORD 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		vend_code LIKE shiphead.vend_code, 
		eta_curr_date LIKE shiphead.eta_curr_date, 
		fob_ent_cost_amt LIKE shiphead.fob_ent_cost_amt, 
		ship_status_code LIKE shiphead.ship_status_code 
	END RECORD, 
	sel_text, where_part CHAR(1500), 
	pt_shiphead RECORD LIKE shiphead.*, 
	resp CHAR(1), 
	l_sign_on_code LIKE kandoouser.sign_on_code 

	LET int_flag = 0 
	LET quit_flag = 0 

	OPEN WINDOW wl151 with FORM "L151" 
	CALL windecoration_l("L151") -- albo kd-763 

	IF display_ship_code = "Y" THEN 
		MESSAGE message_text, temp_ship_code attribute (yellow) 
		LET display_ship_code = "N" 
	ELSE 
		LET msgresp = kandoomsg("U","1001","") 
		#U1001 " Enter selection criteria AND press ESC TO begin search"
	END IF 

	CONSTRUCT BY NAME where_part ON ship_code, 
	ship_type_code, 
	vend_code, 
	eta_curr_date, 
	fob_ent_cost_amt, 
	ship_status_code 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	LET sel_text = "SELECT * FROM shiphead ", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" finalised_flag = \"P\" AND ", 
	" ship_type_ind = '3' AND ", 
	where_part clipped, 
	" ORDER BY cmpy_code, ship_code " 
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET ans = "N" 
		CLOSE WINDOW wl151 
		RETURN 
	END IF 
	PREPARE getord FROM sel_text 
	DECLARE c_ord CURSOR FOR getord 
	LET idx = 0 
	FOREACH c_ord INTO pr_shiphead.* 
		LET idx = idx + 1 
		LET pa_shiphead[idx].ship_code = pr_shiphead.ship_code 
		LET pa_shiphead[idx].vend_code = pr_shiphead.vend_code 
		LET pa_shiphead[idx].ship_type_code = pr_shiphead.ship_type_code 
		LET pa_shiphead[idx].eta_curr_date = pr_shiphead.eta_curr_date 
		LET pa_shiphead[idx].fob_ent_cost_amt = 
		pr_shiphead.fob_ent_cost_amt 
		LET pa_shiphead[idx].ship_status_code = pr_shiphead.ship_status_code 
		IF idx > 240 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx > 0 THEN 
		CALL set_count (idx) 
		MESSAGE "" 
		MESSAGE " Cursor TO shipment AND press RETURN " 
		attribute (yellow) 
		INPUT ARRAY pa_shiphead WITHOUT DEFAULTS FROM sr_shiphead.* 
			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 
			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_shiphead.ship_code = pa_shiphead[idx].ship_code 
				LET pr_shiphead.vend_code = pa_shiphead[idx].vend_code 
				LET pr_shiphead.ship_type_code = pa_shiphead[idx].ship_type_code 
				LET pr_shiphead.eta_curr_date = pa_shiphead[idx].eta_curr_date 
				LET pr_shiphead.fob_ent_cost_amt = 
				pa_shiphead[idx].fob_ent_cost_amt 
				LET pr_shiphead.ship_status_code = 
				pa_shiphead[idx].ship_status_code 
				LET id_flag = 0 
				IF idx > arr_count() THEN 
					ERROR "There are no further shipments in the direction you are going" 
				END IF 
			BEFORE FIELD ship_type_code 
				IF pr_shiphead.ship_code IS NULL THEN 
					ERROR "No shipment number entered" 
					SLEEP 2 
					NEXT FIELD ship_code 
				END IF 
				SELECT * INTO pr_shiphead.* FROM shiphead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pr_shiphead.vend_code 
				AND ship_code = pr_shiphead.ship_code 
				IF (status = notfound) THEN 
					ERROR "Shipment must have been deleted" 
					SLEEP 3 
					NEXT FIELD ship_code 
				END IF 
				SELECT * INTO pr_customer.* FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_shiphead.vend_code 
				IF (status = notfound) THEN 
					ERROR "Customer missing on live shipment" 
					SLEEP 5 
					NEXT FIELD ship_code 
				ELSE 
					CALL ship_final(glob_rec_kandoouser.cmpy_code,pr_shiphead.ship_code, pr_shiphead.vend_code) RETURNING resp 
				END IF 
				IF int_flag != 0 
				OR quit_flag != 0 
				OR resp = "Z" THEN 
					LET int_flag = 0 
					LET quit_flag = 0 
				ELSE 
					LET display_ship_code = "Y" 
					LET temp_ship_code = pr_shiphead.ship_code 
					SELECT * INTO pr_shiphead.* 
					FROM shiphead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ship_code = pr_shiphead.ship_code 
					LET pa_shiphead[idx].ship_status_code = pr_shiphead.ship_status_code 
					DISPLAY pa_shiphead[idx].ship_status_code TO sr_shiphead[scrn].ship_status_code 
					IF resp = "N" THEN 
						LET message_text = "Successfully finalised shipment number " 
						MESSAGE message_text, temp_ship_code attribute (yellow) 
					ELSE 
						LET message_text = "Landed cost calculated shipment number " 
						MESSAGE message_text, temp_ship_code attribute (yellow) 
					END IF 
				END IF 

				NEXT FIELD ship_code 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	ELSE 
		LET msgresp = kandoomsg("L","9011","") 
		#L9011 "No Shipments TO Finalise found"
	END IF 
	CLOSE WINDOW wl151 
END FUNCTION 
