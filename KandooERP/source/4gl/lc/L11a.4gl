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




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L11a allows the user TO enter Shipment Header details

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L11_GLOBALS.4gl" 


DEFINE 
pr_shiptype RECORD LIKE shiptype.*, 
failed_it, cnt SMALLINT 


FUNCTION select_vendor() 
	DEFINE 
	pr_fob_cnt SMALLINT 

	SELECT * INTO pr_smparms.* FROM smparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	key_num = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U", 5112, "") 
		#U5112 "Landed Costing Parameters Not Set up Use LZP"
		EXIT program 
	END IF 
	SELECT * INTO pr_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U", 5107, "") 
		#U5107 "GL Parameters do NOT exist, use GZP TO add"
		EXIT program 
	END IF 

	SELECT count(*) INTO pr_fob_cnt 
	FROM shipcosttype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND class_ind = '1' 
	IF pr_fob_cnt = 0 THEN 
		LET msgresp = kandoomsg("L", 5001, "") 
		#U5001 "No Free On Board Shipment Cost Types exist.  Use LZ4.
		EXIT program 
	END IF 

	# in CASE coming back FROM DELETE KEY
	IF f_type != "O" THEN 
		# shipment edit - so DISPLAY only
		OPEN WINDOW wl100 with FORM "L100" 
		CALL windecoration_l("L100") -- albo kd-761 

		SELECT * INTO pr_vendor.* FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = pr_shiphead.vend_code 
		CALL display_vend() 
		RETURN true 
	ELSE 
		INITIALIZE pr_vendor.* TO NULL 
		LET pr_shiphead.entry_date = today 
		LET pr_shiphead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_shiphead.tax_paid_flag = "N" 

		OPEN WINDOW wl100 with FORM "L100" 
		CALL windecoration_l("L100") -- albo kd-761 

		INPUT BY NAME pr_vendor.vend_code 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) infield (vend_code) 
				LET pr_vendor.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,pr_vendor.vend_code) 
				DISPLAY BY NAME pr_vendor.vend_code 
				NEXT FIELD vend_code 


			AFTER FIELD vend_code 
				MESSAGE " " 
				SELECT * INTO pr_vendor.* FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pr_vendor.vend_code 
				IF (status = notfound) THEN 
					ERROR "Vendor NOT found, try window" 
					NEXT FIELD vend_code 
				END IF 
				CALL display_vend() 

			ON KEY (control-w) 
				CALL kandoohelp("") 

		END INPUT 

		IF int_flag != 0 
		OR quit_flag != 0 THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			#CLOSE WINDOW wL100
			RETURN false 
		ELSE 
			#CLOSE WINDOW wL100
			RETURN true 
		END IF 
	END IF 

END FUNCTION {select vendor} 


FUNCTION display_vend() 
	DISPLAY BY NAME pr_vendor.vend_code, 
	pr_vendor.name_text, 
	pr_vendor.addr1_text, 
	pr_vendor.addr2_text, 
	pr_vendor.city_text, 
	pr_vendor.state_code, 
	pr_vendor.post_code, 
	pr_vendor.country_code, --@db-patch_2020_10_04--
	pr_vendor.fax_text, 
	pr_vendor.contact_text, 
	pr_vendor.tele_text, 
	pr_vendor.extension_text 

	SLEEP 2 
END FUNCTION 



FUNCTION L11_header() 
	DEFINE 
	foundit CHAR(1), 
	char_ship_code CHAR(8), 
	dec_ship_code DECIMAL(8,0), 
	err_flag, cnt, chosen, exist, idx, id_flag SMALLINT 

	LET pr_shiphead.vend_code = pr_vendor.vend_code 
	{
	   OPEN WINDOW wL101 AT 3,3 WITH FORM "L101"      -- albo  KD-761
	       attribute (border, white, MESSAGE line first)
	}
	IF f_type = "O" THEN 
		IF pr_shiphead.agent_code IS NULL THEN 
			LET pr_shiphead.agent_code = pr_smparms.agent_vend_code 
		END IF 
		LET pr_shiphead.curr_code = pr_vendor.currency_code 
		LET foundit = "N" 
		GOTO bypass 
		LABEL recovery: 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER any ERROR GOTO recovery 
		BEGIN WORK 
			DECLARE pcurs CURSOR FOR 
			SELECT * INTO pr_smparms.* FROM smparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			key_num = "1" 
			FOR UPDATE 
			OPEN pcurs 
			FETCH pcurs 
			WHILE (foundit = "N") 
				LET char_ship_code = pr_smparms.next_ship_code 
				LET dec_ship_code = pr_smparms.next_ship_code 
				SELECT count(*) INTO cnt FROM shiphead 
				WHERE ship_code = char_ship_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF cnt > 0 THEN 
					LET pr_smparms.next_ship_code = pr_smparms.next_ship_code + 1 
				ELSE 
					LET pr_shiphead.ship_code = char_ship_code 
					LET foundit = "Y" 
					UPDATE smparms 
					SET next_ship_code = dec_ship_code + 1 
					WHERE CURRENT OF pcurs 
				END IF 
			END WHILE 
		COMMIT WORK 
	END IF 
	SELECT * INTO pr_currency.* FROM currency 
	WHERE currency_code = pr_shiphead.curr_code 
	DISPLAY BY NAME 
	pr_shiphead.ship_code, 
	pr_shiphead.ship_type_code, 
	pr_shiphead.agent_code, 
	pr_shiphead.vessel_text, 
	pr_shiphead.origin_port_text, 
	pr_shiphead.discharge_text, 
	pr_shiphead.ship_via_text, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.conversion_qty, 
	pr_shiphead.tax_paid_flag, 
	pr_shiphead.ship_status_code, 
	pr_shiphead.ware_code 

	IF f_type = "O" THEN 
		LET tran_date = today 
		LET pr_shiphead.conversion_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code, 
			pr_shiphead.curr_code, 
			tran_date, CASH_EXCHANGE_BUY) 
		LET save_conversion_qty = pr_shiphead.conversion_qty 
	END IF 

	IF f_type = "E" THEN 
		LET save_conversion_qty = pr_shiphead.conversion_qty 

		SELECT vendor.* INTO pr_shipagent.* FROM vendor 
		WHERE vendor.vend_code = pr_shiphead.agent_code 
		AND vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 

		SELECT warehouse.* INTO pr_warehouse.* FROM warehouse 
		WHERE warehouse.ware_code = pr_shiphead.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		SELECT * INTO pr_shipstatus.* FROM shipstatus 
		WHERE ship_status_code = pr_shiphead.ship_status_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		DISPLAY pr_shipagent.name_text, 
		pr_shipstatus.desc_text, 
		pr_warehouse.desc_text TO 
		vendor.name_text, 
		shipstatus.desc_text, 
		warehouse.desc_text 
	END IF 
	LET save_curr_code = pr_shiphead.curr_code 

	DISPLAY pr_shiphead.curr_code, 
	pr_currency.desc_text, 
	pr_shiphead.conversion_qty 
	TO curr_code, 
	currency.desc_text, 
	conversion_qty 
	INPUT BY NAME 
	pr_shiphead.ship_type_code, 
	pr_shiphead.agent_code, 
	pr_shiphead.vessel_text, 
	pr_shiphead.origin_port_text, 
	pr_shiphead.discharge_text, 
	pr_shiphead.ship_via_text, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.curr_code, 
	pr_shiphead.conversion_qty, 
	pr_shiphead.tax_paid_flag, 
	pr_shiphead.duty_flag, 
	pr_shiphead.ship_status_code, 
	pr_shiphead.ware_code, 
	pr_shiphead.ant_fob_amt, 
	pr_shiphead.ant_duty_amt WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (ship_type_code) 
			LET pr_shiphead.ship_type_code = show_type(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME pr_shiphead.ship_type_code 
			NEXT FIELD ship_type_code 

		ON KEY (control-b) infield (curr_code) 
			LET pr_shiphead.curr_code = show_curr(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME pr_shiphead.curr_code 
			NEXT FIELD curr_code 

		ON KEY (control-b) infield (agent_code) 
			LET pr_shiphead.agent_code = show_vend(glob_rec_kandoouser.cmpy_code,pr_shiphead.agent_code) 
			DISPLAY BY NAME pr_shiphead.agent_code 
			NEXT FIELD agent_code 

		ON KEY (control-b) infield (ship_status_code) 
			LET pr_shiphead.ship_status_code = show_shipst(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME pr_shiphead.ship_status_code 

			NEXT FIELD ship_status_code 

		ON KEY (control-b) infield (ware_code) 
			LET pr_shiphead.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME pr_shiphead.ware_code 
			NEXT FIELD ware_code 


		AFTER FIELD ship_type_code 
			SELECT * INTO pr_shiptype.* FROM shiptype 
			WHERE shiptype.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shiptype.ship_type_code = pr_shiphead.ship_type_code 
			IF status = notfound THEN 
				ERROR "Shipment type NOT found, try window" 
				NEXT FIELD ship_type_code 
			END IF 
		BEFORE FIELD ware_code 
			IF pr_shiphead.goods_receipt_text IS NOT NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD ship_status_code 
				ELSE 
					NEXT FIELD ant_fob_amt 
				END IF 
			END IF 
		AFTER FIELD ware_code 
			SELECT warehouse.* INTO pr_warehouse.* FROM warehouse 
			WHERE warehouse.ware_code = pr_shiphead.ware_code 
			AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				ERROR "Warehouse Code NOT found, try window" 
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 

			END IF 

		AFTER FIELD ship_status_code 
			SELECT * INTO pr_shipstatus.* FROM shipstatus 
			WHERE ship_status_code = pr_shiphead.ship_status_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (status = notfound) THEN 
				ERROR "Shipstatus NOT found, try window" 
				NEXT FIELD ship_status_code 
			ELSE 
				DISPLAY pr_shipstatus.desc_text TO shipstatus.desc_text 

			END IF 

		AFTER FIELD agent_code 
			SELECT vendor.* INTO pr_shipagent.* FROM vendor 
			WHERE vendor.vend_code = pr_shiphead.agent_code 
			AND vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (status = notfound) THEN 
				ERROR "Shipping Agent NOT found, try window" 
				NEXT FIELD agent_code 
			ELSE 
				DISPLAY pr_shipagent.name_text TO vendor.name_text 

			END IF 

		AFTER FIELD curr_code 
			IF f_type = "E" THEN 
				IF pr_shiphead.curr_code != save_curr_code THEN 
					LET pr_shiphead.curr_code = save_curr_code 
					LET msgresp = kandoomsg("L",9017,"") 
					#L9017 "Cannot change currency code"
					DISPLAY BY NAME pr_shiphead.curr_code 
					NEXT FIELD curr_code 
				END IF 
			ELSE 
				IF pr_shiphead.curr_code != pr_glparms.base_currency_code 
				AND pr_shiphead.curr_code != pr_vendor.currency_code THEN 
					LET msgresp = kandoomsg("L",9018,"") 
					#L9018 "Must be base OR vendor currency"
					NEXT FIELD curr_code 
				END IF 
				IF pr_shiphead.curr_code IS NULL THEN 
					LET pr_shiphead.curr_code = save_curr_code 
					DISPLAY BY NAME pr_shiphead.curr_code 
				ELSE 
					LET pr_shiphead.conversion_qty = get_conv_rate(
						glob_rec_kandoouser.cmpy_code, 
						pr_shiphead.curr_code, 
						tran_date, 
						CASH_EXCHANGE_BUY) 
					
					LET save_conversion_qty = pr_shiphead.conversion_qty 
					LET save_curr_code = pr_shiphead.curr_code 
					SELECT * INTO pr_currency.* FROM currency 
					WHERE currency_code = pr_shiphead.curr_code
					 
					DISPLAY pr_shiphead.curr_code, 
					pr_currency.desc_text, 
					pr_shiphead.conversion_qty 
					TO curr_code, 
					currency.desc_text, 
					conversion_qty 
				END IF 
			END IF 

		BEFORE FIELD conversion_qty 
			IF pr_shiphead.curr_code = pr_glparms.base_currency_code THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD curr_code 
				ELSE 
					NEXT FIELD tax_paid_flag 
				END IF 
			END IF 

		AFTER FIELD conversion_qty 
			IF pr_shiphead.conversion_qty IS NULL THEN 
				LET pr_shiphead.conversion_qty = save_conversion_qty 
				DISPLAY BY NAME pr_shiphead.conversion_qty 
			END IF 
			IF f_type = "E" THEN 
				IF pr_shiphead.conversion_qty != save_conversion_qty THEN 
					LET pr_shiphead.conversion_qty = save_conversion_qty 
					ERROR "Cannot change exchange rate" 
					DISPLAY BY NAME pr_shiphead.conversion_qty 

					NEXT FIELD conversion_qty 
				END IF 
			END IF 

		AFTER FIELD duty_flag 
			IF pr_shiphead.duty_flag IS NULL THEN 
				LET msgresp = kandoomsg("U", 9909, "") 
				#U9909 "This value IS NOT among the valid possibilities
				NEXT FIELD duty_flag 
			END IF 

		AFTER FIELD ant_fob_amt 
			IF pr_shiphead.ant_fob_amt IS NULL THEN 
				LET pr_shiphead.ant_fob_amt = 0 
			END IF 
			IF pr_shiphead.ant_fob_amt < 0 THEN 
				ERROR " Expected FOB must be greater than 0" 
				LET pr_shiphead.ant_fob_amt = 0 
				NEXT FIELD ant_fob_amt 
			END IF 

		AFTER FIELD ant_duty_amt 
			IF pr_shiphead.ant_duty_amt IS NULL THEN 
				LET pr_shiphead.ant_duty_amt = 0 
			END IF 
			IF pr_shiphead.ant_duty_amt < 0 THEN 
				ERROR " Expected FOB must be greater than 0" 
				LET pr_shiphead.ant_duty_amt = 0 
				NEXT FIELD ant_duty_amt 
			END IF 
		AFTER INPUT 
			IF int_flag != 0 
			OR quit_flag != 0 THEN 
			ELSE 
				SELECT * INTO pr_shiptype.* FROM shiptype 
				WHERE shiptype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shiptype.ship_type_code = pr_shiphead.ship_type_code 
				IF status = notfound THEN 
					ERROR "Shipment type NOT found, try window" 
					NEXT FIELD ship_type_code 
				END IF 

				SELECT vendor.* INTO pr_shipagent.* FROM vendor 
				WHERE vendor.vend_code = pr_shiphead.agent_code 
				AND vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					ERROR "Shipping Agent NOT found, try window" 
					NEXT FIELD agent_code 
				ELSE 
					DISPLAY pr_shipagent.name_text TO vendor.name_text 

				END IF 

				IF f_type = "E" THEN 
					IF pr_shiphead.curr_code != save_curr_code THEN 
						LET pr_shiphead.curr_code = save_curr_code 
						LET msgresp = kandoomsg("L",9017,"") 
						#L9017 "Cannot change currency code"
						DISPLAY BY NAME pr_shiphead.curr_code 
						NEXT FIELD curr_code 
					END IF 
				ELSE 
					IF pr_shiphead.curr_code != pr_glparms.base_currency_code 
					AND pr_shiphead.curr_code != pr_vendor.currency_code THEN 
						LET msgresp = kandoomsg("L",9018,"") 
						#L9018 "Must be base OR vendor currency"
						NEXT FIELD curr_code 
					END IF 
					IF pr_shiphead.curr_code IS NULL THEN 
						LET pr_shiphead.curr_code = save_curr_code 
						DISPLAY BY NAME pr_shiphead.curr_code 
					ELSE 
						LET save_curr_code = pr_shiphead.curr_code 
						LET save_conversion_qty = pr_shiphead.conversion_qty 
						DISPLAY pr_shiphead.curr_code, 
						pr_currency.desc_text, 
						pr_shiphead.conversion_qty 
						TO curr_code, 
						currency.desc_text, 
						conversion_qty 
					END IF 
				END IF 

				IF pr_shiphead.conversion_qty IS NULL THEN 
					LET pr_shiphead.conversion_qty = save_conversion_qty 
					DISPLAY BY NAME pr_shiphead.conversion_qty 
				END IF 
				IF f_type = "E" THEN 
					IF pr_shiphead.conversion_qty != save_conversion_qty THEN 
						LET pr_shiphead.conversion_qty = save_conversion_qty 
						ERROR "Cannot change exchange rate" 
						DISPLAY BY NAME pr_shiphead.conversion_qty 

						NEXT FIELD conversion_qty 
					END IF 
				END IF 

				LET pr_shiphead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				SELECT * INTO pr_shipstatus.* FROM shipstatus 
				WHERE ship_status_code = pr_shiphead.ship_status_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					ERROR "Shipstatus NOT found, try window" 
					NEXT FIELD ship_status_code 
				ELSE 
					DISPLAY pr_shipstatus.desc_text TO shipstatus.desc_text 

				END IF 

				SELECT warehouse.* INTO pr_warehouse.* FROM warehouse 
				WHERE warehouse.ware_code = pr_shiphead.ware_code 
				AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					ERROR "Warehouse Code NOT found, try window" 
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 

				END IF 
				IF pr_shiphead.ant_fob_amt IS NULL THEN 
					LET pr_shiphead.ant_fob_amt = 0 
				END IF 
				IF pr_shiphead.ant_fob_amt < 0 THEN 
					ERROR " Expected FOB must be greater than 0" 
					LET pr_shiphead.ant_fob_amt = 0 
					NEXT FIELD ant_fob_amt 
				END IF 
				IF pr_shiphead.ant_duty_amt IS NULL THEN 
					LET pr_shiphead.ant_duty_amt = 0 
				END IF 
				IF pr_shiphead.ant_duty_amt < 0 THEN 
					ERROR " Expected FOB must be greater than 0" 
					LET pr_shiphead.ant_duty_amt = 0 
					NEXT FIELD ant_duty_amt 
				END IF 

				IF f_type = "O" THEN 
					LET pr_shiphead.entry_date = today 
					LET pr_shiphead.entry_code = glob_rec_kandoouser.sign_on_code 
					LET pr_shiphead.late_cost_amt = 0 
					LET pr_shiphead.other_cost_amt = 0 
					LET pr_shiphead.ship_type_ind = 1 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		--      CLOSE WINDOW wL101       -- albo  KD-761
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
