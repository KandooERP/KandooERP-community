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

	Source code beautified by beautify.pl on 2020-01-02 10:35:34	$Id: $
}



# FUNCTION ship_stat shows the user the current shipment STATUS by line

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION ship_stat(p_cmpy_code, p_vend_code, p_ship_code)
#
#
############################################################
FUNCTION ship_stat(p_cmpy_code,p_vend_code,p_ship_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE shiphead.vend_code 
	DEFINE p_ship_code LIKE shiphead.ship_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 

	SELECT * INTO l_rec_shiphead.* FROM shiphead 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 
	AND ship_code = p_ship_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Shipment") 
		#7001 Shipment RECORD does NOT exist
		EXIT program 
	END IF 
	CASE 
		WHEN l_rec_shiphead.ship_type_ind = 1 
			CALL ship_type_one(p_cmpy_code, p_vend_code, p_ship_code) 
		WHEN l_rec_shiphead.ship_type_ind = 3 
			CALL ship_type_three(p_cmpy_code, p_vend_code, p_ship_code) 
	END CASE 
END FUNCTION 


############################################################
# FUNCTION ship_type_one(p_cmpy_code, p_vend_code, p_ship_code)
#
#
############################################################
FUNCTION ship_type_one(p_cmpy_code,p_vend_code,p_ship_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE shiphead.vend_code 
	DEFINE p_ship_code LIKE shiphead.ship_code 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_shipstatus RECORD LIKE shipstatus.* 
	DEFINE l_rec_shipdetl RECORD LIKE shipdetl.* 
	DEFINE l_arr_rec_shipdetl DYNAMIC ARRAY OF #array[200] OF RECORD 
		RECORD 
			part_code LIKE shipdetl.part_code, 
			ship_inv_qty LIKE shipdetl.ship_inv_qty, 
			fob_unit_ent_amt LIKE shipdetl.fob_unit_ent_amt, 
			duty_unit_ent_amt LIKE shipdetl.duty_unit_ent_amt, 
			ship_rec_qty LIKE shipdetl.ship_rec_qty, 
			desc_text LIKE shipdetl.desc_text 
		END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 

		SELECT * INTO l_rec_vendor.* FROM vendor 
		WHERE cmpy_code = p_cmpy_code 
		AND vend_code = p_vend_code 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("U",7001,"Vendor") 
			#7001 Logic Error: Vendor RECORD NOT found
			EXIT program 
		END IF 

		SELECT * INTO l_rec_shiphead.* FROM shiphead 
		WHERE cmpy_code = p_cmpy_code 
		AND vend_code = p_vend_code 
		AND ship_code = p_ship_code 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("U",7001,"Order") 
			#7001 Logic Error: Order RECORD NOT found
			EXIT program 
		END IF 

		SELECT * INTO l_rec_shipstatus.* FROM shipstatus 
		WHERE cmpy_code = p_cmpy_code 
		AND ship_status_code = l_rec_shiphead.ship_status_code 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("U",7001,"Shipment Status") 
			#7001 Logic Error: Shipment Status RECORD NOT found
		END IF 

		OPEN WINDOW wl106 with FORM "L106" 
		CALL winDecoration_l("L106") -- albo kd-752 
		DISPLAY BY NAME l_rec_shiphead.vend_code, 
		l_rec_vendor.name_text, 
		l_rec_shiphead.ship_code, 
		l_rec_shiphead.eta_curr_date, 
		l_rec_shipstatus.desc_text, 
		l_rec_shiphead.fob_ent_cost_amt, 
		l_rec_shiphead.fob_curr_cost_amt, 
		l_rec_shiphead.curr_code, 
		l_rec_shiphead.duty_ent_amt, 
		l_rec_shiphead.duty_inv_amt, 
		l_rec_shiphead.late_cost_amt, 
		l_rec_shiphead.other_cost_amt 

		DISPLAY l_rec_shiphead.curr_code TO inv_curr_code 
		attribute(green) 

		DECLARE ordcur CURSOR FOR 
		SELECT * INTO l_rec_shipdetl.* FROM shipdetl 
		WHERE cmpy_code = p_cmpy_code 
		AND ship_code = l_rec_shiphead.ship_code 

		LET l_idx = 0 
		FOREACH ordcur 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_shipdetl[l_idx].part_code = l_rec_shipdetl.part_code 
			LET l_arr_rec_shipdetl[l_idx].desc_text = l_rec_shipdetl.desc_text 
			LET l_arr_rec_shipdetl[l_idx].ship_inv_qty = l_rec_shipdetl.ship_inv_qty 
			LET l_arr_rec_shipdetl[l_idx].fob_unit_ent_amt = l_rec_shipdetl.fob_unit_ent_amt 
			LET l_arr_rec_shipdetl[l_idx].duty_unit_ent_amt = l_rec_shipdetl.duty_unit_ent_amt 
			LET l_arr_rec_shipdetl[l_idx].ship_rec_qty = l_rec_shipdetl.ship_rec_qty 
			#      IF l_idx > 200 THEN
			#         LET l_msgresp = kandoomsg("U",6100,l_idx)
			#         #6100 First l_idx records selected
			#         EXIT FOREACH
			#      END IF
		END FOREACH 

		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 l_idx records selected
		CALL set_count (l_idx) 
		LET l_msgresp = kandoomsg("U",1008,"") 

		#1008 F3/F4 TO page Bwd/Fwd; OK TO Continue.
		DISPLAY ARRAY l_arr_rec_shipdetl TO sr_shipdetl.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","shstfunc","display-arr-shipdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 

		CLOSE WINDOW wl106 

		LET int_flag = false 
		LET quit_flag = false 

END FUNCTION 



############################################################
# FUNCTION ship_type_three(p_cmpy_code, p_vend_code, p_ship_code)
#
#
############################################################
FUNCTION ship_type_three(p_cmpy_code,p_vend_code,p_ship_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE shiphead.vend_code 
	DEFINE p_ship_code LIKE shiphead.ship_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_shipstatus RECORD LIKE shipstatus.* 
	DEFINE l_rec_shipdetl RECORD LIKE shipdetl.* 
	DEFINE l_arr_rec_shipdetl DYNAMIC ARRAY OF #array[200] OF RECORD 
		RECORD 
			part_code LIKE shipdetl.part_code, 
			ship_inv_qty LIKE shipdetl.ship_inv_qty, 
			line_total_amt LIKE shipdetl.line_total_amt, 
			ship_rec_qty LIKE shipdetl.ship_rec_qty, 
			desc_text LIKE shipdetl.desc_text 
		END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 

		OPEN WINDOW wl165 with FORM "L165" 
		CALL winDecoration_l("L165") -- albo kd-752 
		SELECT * INTO l_rec_customer.* FROM customer 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = p_vend_code 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("U",7001,"Customer") 
			#7001 Logic Error: Customer RECORD NOT found
			EXIT program 
		END IF 

		SELECT * INTO l_rec_shiphead.* FROM shiphead 
		WHERE cmpy_code = p_cmpy_code 
		AND vend_code = p_vend_code 
		AND ship_code = p_ship_code 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("U",7001,"Shipment") 
			#7001 Logic Error: Shipment RECORD NOT found
			EXIT program 
		END IF 

		SELECT * INTO l_rec_shipstatus.* FROM shipstatus 
		WHERE cmpy_code = p_cmpy_code 
		AND ship_status_code = l_rec_shiphead.ship_status_code 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("U",7001,"Shipment Status") 
			#7001 Logic Error: Shipment Status RECORD NOT found
		END IF 

		DISPLAY BY NAME l_rec_shiphead.vend_code, 
		l_rec_customer.name_text, 
		l_rec_shiphead.ship_code, 
		l_rec_shiphead.eta_curr_date, 
		l_rec_shipstatus.desc_text, 
		l_rec_shiphead.total_amt, 
		l_rec_shiphead.late_cost_amt, 
		l_rec_shiphead.other_cost_amt 

		DECLARE twocur CURSOR FOR 
		SELECT * INTO l_rec_shipdetl.* FROM shipdetl 
		WHERE cmpy_code = p_cmpy_code 
		AND ship_code = l_rec_shiphead.ship_code 
		LET l_idx = 0 

		FOREACH twocur 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_shipdetl[l_idx].part_code = l_rec_shipdetl.part_code 
			LET l_arr_rec_shipdetl[l_idx].desc_text = l_rec_shipdetl.desc_text 
			LET l_arr_rec_shipdetl[l_idx].ship_inv_qty = l_rec_shipdetl.ship_inv_qty 
			LET l_arr_rec_shipdetl[l_idx].line_total_amt = l_rec_shipdetl.line_total_amt 
			LET l_arr_rec_shipdetl[l_idx].ship_rec_qty = l_rec_shipdetl.ship_rec_qty 
			#      IF l_idx > 200 THEN
			#         LET l_msgresp = kandoomsg("U",6100,l_idx)
			#         #6100 First l_idx records selected
			#         EXIT FOREACH
			#      END IF
		END FOREACH 

		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 l_idx records selected
		CALL set_count (l_idx) 
		LET l_msgresp = kandoomsg("U",1008,"") 
		#1008 F3/F4 TO page Bwd/Fwd; OK TO Continue.

		DISPLAY ARRAY l_arr_rec_shipdetl TO sr_shipdetl.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","shstfunc","display_arr-l_arr_rec_shipdetl-1") -- albo kd-512 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
		END DISPLAY 

		CLOSE WINDOW wl165 

		LET int_flag = false 
		LET quit_flag = false 

END FUNCTION 


