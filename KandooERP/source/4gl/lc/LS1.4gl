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
GLOBALS "../lc/LS1_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module LS1 allows the user TO Finalise Shipments


MAIN 
	#Initial UI Init
	CALL setModuleId("LS1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	#  SET up temp table
	CREATE temp TABLE posttemp ( 
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
		#5107 Genenal Ledger Paramters Not Set Up; Refer Menu GZP.
		EXIT program 
	END IF 
	SELECT * INTO pr_smparms.* FROM smparms 
	WHERE key_num = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U","5112","") 
		#5112 Landed Costing Parameters Not Set Up; Refer Menu LZP
		EXIT program 
	END IF 
	SELECT * INTO pr_puparms.* FROM puparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U","5118","") 
		#5118 Purchasing Paramters Not Set Up; Refer Menu RZP.
		EXIT program 
	END IF 
	SELECT * INTO pr_inparms.* FROM inparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U","5109","") 
		#5109 "Inventory Paramters Not Set Up; Refer Menu IZP.
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
		vessel_text LIKE shiphead.vessel_text, 
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

	OPEN WINDOW l108 with FORM "L108" 
	CALL windecoration_l("L108") -- albo kd-763 

	IF display_ship_code = "Y" THEN 
		MESSAGE message_text, temp_ship_code attribute (yellow) 
		LET display_ship_code = "N" 
	ELSE 
		LET msgresp = kandoomsg("U","1001","") 	#1001 Enter Selection Criteria;  OK TO Continue.
	END IF 

	CONSTRUCT BY NAME where_part ON ship_code, 
	ship_type_code, 
	vend_code, 
	vessel_text, 
	eta_curr_date, 
	fob_ent_cost_amt, 
	ship_status_code 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	LET sel_text = "SELECT * FROM shiphead ", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" finalised_flag = \"P\" AND ", 
	where_part clipped, 
	" ORDER BY ship_code " 
	IF int_flag OR quit_flag THEN 
		LET ans = "N" 
		CLOSE WINDOW l108 
		RETURN 
	END IF 
	PREPARE getord FROM sel_text 
	DECLARE c_ord CURSOR FOR getord 
	OPEN c_ord 
	LET idx = 0 
	FOREACH c_ord INTO pr_shiphead.* 
		LET idx = idx + 1 
		LET pa_shiphead[idx].ship_code = pr_shiphead.ship_code 
		LET pa_shiphead[idx].vend_code = pr_shiphead.vend_code 
		LET pa_shiphead[idx].ship_type_code = pr_shiphead.ship_type_code 
		LET pa_shiphead[idx].vessel_text = pr_shiphead.vessel_text 
		LET pa_shiphead[idx].eta_curr_date = pr_shiphead.eta_curr_date 
		LET pa_shiphead[idx].fob_ent_cost_amt = 
		pr_shiphead.fob_ent_cost_amt 
		LET pa_shiphead[idx].ship_status_code = pr_shiphead.ship_status_code 
		IF idx > 240 THEN 
			LET idx = 240 
			LET msgresp = kandoomsg("U",6100,"idx") 
			#6100 First 240 records selected only.  More may be ...
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx > 0 THEN 
		CALL set_count(idx) 
		LET msgresp = kandoomsg("U",1051,"finalise shipment") 
		#1051 F3/F4 TO Page Fwd/Bwd;  ENTER on line TO finalise shipment.
		INPUT ARRAY pa_shiphead WITHOUT DEFAULTS FROM sr_shiphead.* 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_shiphead.ship_code = pa_shiphead[idx].ship_code 
				LET pr_shiphead.vend_code = pa_shiphead[idx].vend_code 
				LET pr_shiphead.ship_type_code = pa_shiphead[idx].ship_type_code 
				LET pr_shiphead.vessel_text = pa_shiphead[idx].vessel_text 
				LET pr_shiphead.eta_curr_date = pa_shiphead[idx].eta_curr_date 
				LET pr_shiphead.fob_ent_cost_amt = 
				pa_shiphead[idx].fob_ent_cost_amt 
				LET pr_shiphead.ship_status_code = 
				pa_shiphead[idx].ship_status_code 
				LET id_flag = 0 
			BEFORE FIELD ship_code 
				DISPLAY pa_shiphead[idx].* 
				TO sr_shiphead[scrn].* 

			AFTER FIELD ship_code 
				IF idx > arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD ship_code 
				END IF 
				IF pa_shiphead[idx+1].ship_code IS NULL 
				AND (fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("right")) THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD ship_code 
				END IF 
			BEFORE FIELD ship_type_code 
				IF pr_shiphead.ship_code IS NULL THEN 
					LET msgresp = kandoomsg("L",9023,"") 
					#9023 No shipment number entered.
					NEXT FIELD ship_code 
				END IF 
				SELECT * INTO pr_shiphead.* FROM shiphead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pr_shiphead.vend_code 
				AND ship_code = pr_shiphead.ship_code 
				IF (status = notfound) THEN 
					LET msgresp = kandoomsg("L",9005,"") 
					#9005 Shipment was NOT found.
					NEXT FIELD ship_code 
				END IF 
				SELECT * INTO pr_vendor.* FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pr_shiphead.vend_code 
				IF (status = notfound) THEN 
					LET msgresp = kandoomsg("P",7087,"") 
					#7087 Vendor details NOT found.
					NEXT FIELD ship_code 
				ELSE 
					LET resp = ship_final(glob_rec_kandoouser.cmpy_code, pr_shiphead.ship_code, 
					pr_shiphead.vend_code) 
				END IF 
				IF int_flag != 0 
				OR quit_flag != 0 
				OR resp = "Z" THEN 
					LET int_flag = 0 
					LET quit_flag = 0 
				ELSE 
					LET display_ship_code = "Y" 
					LET temp_ship_code = pr_shiphead.ship_code 
				END IF 
				NEXT FIELD ship_code 
			AFTER ROW 
				DISPLAY pa_shiphead[idx].* 
				TO sr_shiphead[scrn].* 

		END INPUT 
	ELSE 
		LET msgresp = kandoomsg("L","9011","") 
		#9011 No Shipments TO Finalise found.
	END IF 
	CLOSE WINDOW l108 
END FUNCTION 
