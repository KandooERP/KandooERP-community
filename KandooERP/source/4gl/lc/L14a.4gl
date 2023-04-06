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

	Source code beautified by beautify.pl on 2020-01-02 18:38:29	$Id: $
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
# \brief module L14a allows the user TO Scan AND SELECT Shipments

GLOBALS "L11_GLOBALS.4gl" 

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
	pt_shiphead RECORD LIKE shiphead.*, 
	sel_text, where_part CHAR(1500), 
	pr_repeat CHAR(1) 


	LET int_flag = 0 
	LET quit_flag = 0 
	LET ans = "Y" 
	LET retain_flag = false 

	OPEN WINDOW wl108 with FORM "L108" 
	CALL windecoration_l("L108") -- albo kd-761 

	LET pr_repeat = 'Y' 
	WHILE pr_repeat = 'Y' 
		CLEAR FORM 
		LET msgresp = kandoomsg("U",1001,"") 
		#U1001 "Enter Selection Criteria;  OK TO Continue.

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
		" finalised_flag != \"Y\" AND ", 
		" ship_type_ind = \"1\" AND ", 
		where_part clipped, 
		" ORDER BY cmpy_code, ship_code " 
		IF int_flag != 0 
		OR quit_flag != 0 THEN 
			LET ans = "N" 
			CLOSE WINDOW wl108 
			RETURN false 
		END IF 

		PREPARE getord FROM sel_text 
		DECLARE c_ord CURSOR FOR getord 

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
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF idx > 0 THEN 
			CALL set_count (idx) 
			MESSAGE "" 
			MESSAGE " Cursor TO shipment AND press RETURN TO edit " 
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
					LET pr_shiphead.vessel_text = pa_shiphead[idx].vessel_text 
					LET pr_shiphead.eta_curr_date = pa_shiphead[idx].eta_curr_date 
					LET pr_shiphead.fob_ent_cost_amt = 
					pa_shiphead[idx].fob_ent_cost_amt 
					LET pr_shiphead.ship_status_code = 
					pa_shiphead[idx].ship_status_code 

				AFTER FIELD ship_code 
					IF fgl_lastkey() = fgl_keyval("down") THEN 
						IF idx >= arr_count() THEN 
							LET msgresp = kandoomsg("U",9001,"") 
							#U9001 "There are no more rows in the direction ...
							NEXT FIELD ship_code 
						END IF 
					END IF 

				BEFORE FIELD ship_type_code 
					IF pr_shiphead.ship_code IS NULL THEN 
						LET msgresp = kandoomsg("L",9005,"") 
						#L9005 Shipment NOT found
						NEXT FIELD ship_code 
					ELSE 
						SELECT * INTO pr_shiphead.* 
						FROM shiphead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ship_code = pa_shiphead[idx].ship_code 
						IF status = notfound THEN 
							LET msgresp = kandoomsg("L",9005,"") 
							#L9005 Shipment NOT found
							NEXT FIELD ship_code 
						END IF 
						EXIT INPUT 
					END IF 

				ON KEY (control-w) 
					CALL kandoohelp("") 
			END INPUT 
			LET pr_repeat = 'N' 
		ELSE 
			LET msgresp = kandoomsg("U",1021,"") 
			#U1021 "No entries satisfied selection criteria.
		END IF 
	END WHILE 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		RETURN false 
	END IF 
	LET int_flag = 0 
	LET quit_flag = 0 
	CLOSE WINDOW wl108 
	RETURN true 
END FUNCTION 
