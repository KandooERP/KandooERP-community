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


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L64a  allows the user TO edit Credit RETURN Shipments

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 
GLOBALS "L64_GLOBALS.4gl" 

FUNCTION cred_ship_select() 
	DEFINE 
	pa_shiphead array[250] OF RECORD 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		eta_curr_date LIKE shiphead.eta_curr_date, 
		fob_ent_cost_amt LIKE shiphead.fob_ent_cost_amt, 
		ship_status_code LIKE shiphead.ship_status_code 
	END RECORD, 
	pt_shiphead RECORD LIKE shiphead.* 

	LET first_time = 0 
	WHILE true 
		CLEAR FORM 

		INPUT BY NAME pt_shiphead.vend_code, 
		pt_shiphead.ship_code 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				IF infield (vend_code) THEN 
					LET pt_shiphead.vend_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pt_shiphead.vend_code 

					NEXT FIELD vend_code 
				END IF 

			AFTER FIELD vend_code 
				SELECT * 
				INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pt_shiphead.vend_code 
				IF status = notfound THEN 
					ERROR " Customer NOT found - Try Window" 
					NEXT FIELD vend_code 
				END IF 
				DISPLAY BY NAME pr_customer.name_text 
				attribute (green) 
				LET pv_corp_cust = false 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 
				IF pt_shiphead.vend_code IS NULL THEN 
					ERROR "You must enter customer code " 
					NEXT FIELD vend_code 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
		IF pt_shiphead.ship_code IS NULL THEN 
			LET pt_shiphead.ship_code = 0 
		END IF 
		DISPLAY BY NAME pt_shiphead.vend_code 
		DISPLAY BY NAME pr_customer.name_text 
		attribute (green) 
		DISPLAY BY NAME pr_customer.currency_code 
		attribute (green) 
		DECLARE c_credit CURSOR FOR 
		SELECT * 
		FROM shiphead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = pt_shiphead.vend_code 
		AND ship_code >= pt_shiphead.ship_code 
		AND finalised_flag != "Y" 
		ORDER BY cmpy_code, ship_code 
		LET idx = 0 
		FOREACH c_credit INTO pr_shiphead.* 
			LET idx = idx + 1 
			LET pa_shiphead[idx].ship_code = pr_shiphead.ship_code 
			LET pa_shiphead[idx].ship_type_code = pr_shiphead.ship_type_code 
			LET pa_shiphead[idx].eta_curr_date = pr_shiphead.eta_curr_date 
			LET pa_shiphead[idx].fob_ent_cost_amt = pr_shiphead.fob_ent_cost_amt 
			LET pa_shiphead[idx].ship_status_code = pr_shiphead.ship_status_code 
			IF idx = 240 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF idx = 0 THEN 
			MESSAGE " No Shipments found FOR Customer " 
			attribute(yellow) 
			SLEEP 3 
			CONTINUE WHILE 
		END IF 
		CALL set_count (idx) 
		MESSAGE " RETURN on line TO edit shipment" 
		attribute (yellow) 
		INPUT ARRAY pa_shiphead WITHOUT DEFAULTS FROM sr_shiphead.* 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_shiphead.ship_code = pa_shiphead[idx].ship_code 
				IF idx > arr_count() THEN 
					ERROR 
					" There are no more rows in the direction you are going" 
				ELSE 
					DISPLAY pa_shiphead[idx].* 
					TO sr_shiphead[scrn].* 

				END IF 

			AFTER FIELD ship_code 
				LET pa_shiphead[idx].ship_code = pr_shiphead.ship_code 
				IF pr_shiphead.ship_code IS NOT NULL THEN 
					DISPLAY pa_shiphead[idx].ship_code 
					TO sr_shiphead[scrn].ship_code 

				END IF 

			BEFORE FIELD ship_type_code 
				SELECT * 
				INTO pr_shiphead.* 
				FROM shiphead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pt_shiphead.vend_code 
				AND ship_code = pa_shiphead[idx].ship_code 
				IF pr_shiphead.finalised_flag = "Y" THEN 
					ERROR " Cannot Edit Finalised Shipment " 
					NEXT FIELD ship_code 
				END IF 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY pa_shiphead[idx].* TO sr_shiphead[scrn].* 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	SELECT * 
	INTO pr_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_shiphead.vend_code 
	IF status = notfound THEN 
		ERROR " Logic Error - Customer Missing on live Shipment" 
		CALL errorlog("L64a - Customer Missing on live Shipment") 
		RETURN false 
	ELSE 
		LET first_time = 1 
		RETURN true 
	END IF 
END FUNCTION 

