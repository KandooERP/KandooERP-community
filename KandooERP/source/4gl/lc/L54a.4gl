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

	Source code beautified by beautify.pl on 2020-01-02 18:38:32	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L54a allows the user TO Scan AND edit po RETURN shipments

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 
GLOBALS "L54_GLOBALS.4gl" 

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
	pt_shiphead RECORD LIKE shiphead.* 


	LET int_flag = 0 
	LET quit_flag = 0 
	LET ans = "Y" 
	LET first_time = 1 

	OPEN WINDOW wl108 with FORM "L151" 
	CALL windecoration_l("L151") -- albo kd-761 

	IF display_ship_code = "Y" THEN 
		MESSAGE "Successful editing of shipment number ", temp_ship_code 
		attribute (yellow) 
		LET display_ship_code = "N" 
	ELSE 
		MESSAGE " Enter selection criteria AND press ESC TO begin search" 
		attribute (yellow) 
	END IF 


	CONSTRUCT BY NAME where_part ON ship_code, 
	ship_type_code, 
	vend_code, 
	eta_curr_date, 
	fob_ent_cost_amt, 
	ship_status_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","L54a","construct-ship_code-1") -- albo 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	LET sel_text = "SELECT * FROM shiphead ", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" finalised_flag != \"Y\" AND ", 
	" ship_type_ind = \"2\" AND ", 
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

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","L54a","input-arr-pa_shiphead-1") -- albo 

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
					ERROR " Not a valid shipment" 
					NEXT FIELD ship_code 
				ELSE 
					SELECT * 
					INTO pr_shiphead.* 
					FROM shiphead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ship_code = pa_shiphead[idx].ship_code 
					EXIT INPUT 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	END IF 
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		RETURN false 
	END IF 
	LET int_flag = 0 
	LET quit_flag = 0 
	CLOSE WINDOW wl108 
	RETURN true 
END FUNCTION 
