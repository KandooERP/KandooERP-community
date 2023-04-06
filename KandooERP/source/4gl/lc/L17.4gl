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

	Source code beautified by beautify.pl on 2020-01-02 18:38:30	$Id: $
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
# \brief module L17  allows the user TO Scan Shipment Debit Memos by Shipment

GLOBALS 
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	pa_shiphead array[250] OF RECORD 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		vend_code LIKE shiphead.vend_code, 
		vessel_text LIKE shiphead.vessel_text, 
		eta_curr_date LIKE shiphead.eta_curr_date, 
		fob_ent_cost_amt LIKE shiphead.fob_ent_cost_amt, 
		ship_status_code LIKE shiphead.ship_status_code 
	END RECORD, 
	func_type CHAR(14), 
	scrn, id_flag, idx SMALLINT, 
	sel_text, where_part CHAR(1500) 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("L17") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	LET func_type = "Shipment Scan" 
	LET int_flag = 0 
	LET quit_flag = 0 
	OPEN WINDOW wl108 with FORM "L108" 
	CALL windecoration_l("L108") -- albo kd-761 

	WHILE selectship() 
		CALL shipscan() 
	END WHILE 
	CLOSE WINDOW wl108 
END MAIN 



FUNCTION selectship() 
	CLEAR FORM 
	LET msgresp = kandoomsg("L", 1001, "") 
	#1001 "Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME where_part ON ship_code, 
	ship_type_code, 
	vend_code, 
	vessel_text, 
	eta_curr_date, 
	fob_ent_cost_amt, 
	ship_status_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","L17","construct-ship_code-1") -- albo 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("W",1002,"") 
		#1002 " Searching database - please wait"
		LET sel_text = "SELECT * FROM shiphead ", 
		" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" finalised_flag != \"Y\" AND ", 
		where_part clipped, 
		" ORDER BY ship_code " 

		PREPARE getord FROM sel_text 
		DECLARE c_ord CURSOR FOR getord 
		RETURN true 
	END IF 
END FUNCTION 



FUNCTION shipscan() 
	DEFINE 
	pr_cnt SMALLINT 


	LET idx = 0 
	FOREACH c_ord INTO pr_shiphead.* 
		LET idx = idx + 1 
		LET pa_shiphead[idx].ship_code = pr_shiphead.ship_code 
		LET pa_shiphead[idx].vend_code = pr_shiphead.vend_code 
		LET pa_shiphead[idx].ship_type_code = pr_shiphead.ship_type_code 
		LET pa_shiphead[idx].vessel_text = pr_shiphead.vessel_text 
		LET pa_shiphead[idx].eta_curr_date = pr_shiphead.eta_curr_date 
		LET pa_shiphead[idx].fob_ent_cost_amt = pr_shiphead.fob_ent_cost_amt 
		LET pa_shiphead[idx].ship_status_code = pr_shiphead.ship_status_code 
		IF idx > 240 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_shiphead[1].* TO NULL 
	END IF 

	CALL set_count (idx) 
	LET msgresp = kandoomsg("W",1079,"") 
	#W1079 Press ENTER on line TO view details


	INPUT ARRAY pa_shiphead WITHOUT DEFAULTS FROM sr_shiphead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","L17","input-pa_shiphead-1") -- albo 

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
			IF idx > arr_count() 
			AND idx > 1 THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 "There are no more rows in the direction you are
				NEXT FIELD ship_code 
			END IF 

		AFTER FIELD ship_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF idx >= arr_count() 
				OR arr_curr() > arr_count() THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD ship_code 
				END IF 
			END IF 

		BEFORE FIELD ship_type_code 
			IF pr_shiphead.ship_code IS NULL THEN 
				LET msgresp = kandoomsg("L",9005,"") 
				#9005 "Shipment was NOT found"
				NEXT FIELD ship_code 
			END IF 
			IF int_flag != 0 
			OR quit_flag != 0 THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
			ELSE 
				SELECT count(*) INTO pr_cnt 
				FROM debithead, debitdist 
				WHERE debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND debitdist.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND debitdist.job_code = pr_shiphead.ship_code 
				AND debithead.debit_num = debitdist.debit_code 

				IF pr_cnt = 0 THEN 
					LET msgresp = kandoomsg("L",9009,"") 
					#9009 No Debits found matching criteria
				ELSE 
					CALL ship_debit(glob_rec_kandoouser.cmpy_code, pr_shiphead.ship_code, 
					pr_shiphead.vend_code) 
				END IF 
			END IF 
			NEXT FIELD ship_code 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 
