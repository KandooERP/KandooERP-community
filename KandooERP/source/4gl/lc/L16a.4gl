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
GLOBALS "L_LC_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L16a - FUNCTION ship_dist displays the vouchers distribution FOR
#                shipment vouchers by shipment

FUNCTION ship_dist(p_cmpy, pr_ship_code, pr_vend_code) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_ship_code LIKE shiphead.ship_code, 
	pr_vend_code LIKE vendor.vend_code, 
	pr_voucher RECORD LIKE voucher.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_voucherdist RECORD LIKE voucherdist.*, 
	pa_ship_dist array[110] OF RECORD 
		vouch_date LIKE voucher.vouch_date, 
		vouch_code LIKE voucher.vouch_code, 
		line_num LIKE voucherdist.line_num, 
		cost_type_code LIKE shipcosttype.cost_type_code, 
		desc_text LIKE voucherdist.desc_text, 
		dist_amt LIKE voucherdist.dist_amt 
	END RECORD, 
	scrn, idx SMALLINT 

	OPEN WINDOW wl121 with FORM "L121" 
	CALL windecoration_l("L121") -- albo kd-761 

	SELECT * INTO pr_shiphead.* FROM shiphead 
	WHERE shiphead.cmpy_code = p_cmpy 
	AND shiphead.vend_code = pr_vend_code 
	AND shiphead.ship_code = pr_ship_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("L",9005,'') 
		#L9005 "Shipment was NOT found "
		CLOSE WINDOW wl121 
		RETURN 
	END IF 

	IF pr_shiphead.ship_type_ind = '3' THEN 
		SELECT name_text INTO pr_vendor.name_text FROM customer 
		WHERE customer.cmpy_code = p_cmpy 
		AND customer.cust_code = pr_vend_code 
		IF status = notfound THEN 
			LET msgresp=kandoomsg("A",9109,'') 
			#P9109 "Customer NOT found "
			CLOSE WINDOW wl121 
			RETURN 
		END IF 
	ELSE 
		SELECT * INTO pr_vendor.* FROM vendor 
		WHERE vendor.cmpy_code = p_cmpy 
		AND vendor.vend_code = pr_vend_code 
		IF status = notfound THEN 
			LET msgresp=kandoomsg("P",9501,'') 
			#P9501 "Vendor NOT found "
			CLOSE WINDOW wl121 
			RETURN 
		END IF 
	END IF 
	LET msgresp = kandoomsg("U",1002, '') 
	#1002 "Seacrching Database; Please wait

	DECLARE c_dist CURSOR FOR 
	SELECT * INTO pr_voucher.*, pr_voucherdist.* 
	FROM voucher, voucherdist 
	WHERE voucher.cmpy_code = p_cmpy 
	AND voucherdist.cmpy_code = p_cmpy 
	AND voucherdist.job_code = pr_ship_code 
	AND voucher.vouch_code = voucherdist.vouch_code 
	AND voucher.vend_code = voucherdist.vend_code 
	ORDER BY voucher.vouch_date, voucherdist.vouch_code, 
	voucherdist.line_num 
	LET idx = 0 
	FOREACH c_dist 
		LET idx = idx + 1 
		LET pa_ship_dist[idx].vouch_date = pr_voucher.vouch_date 
		LET pa_ship_dist[idx].vouch_code = pr_voucher.vouch_code 
		LET pa_ship_dist[idx].line_num = pr_voucherdist.line_num 
		LET pa_ship_dist[idx].cost_type_code = pr_voucherdist.res_code 
		LET pa_ship_dist[idx].desc_text = pr_voucherdist.desc_text 
		LET pa_ship_dist[idx].dist_amt = pr_voucherdist.dist_amt 
		IF idx = 100 THEN 
			LET msgresp = kandoomsg("U",1022, '100') 
			#1022 "First 100 records selected only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF idx > 0 THEN 
		CALL set_count(idx) 

		DISPLAY pr_vend_code, 
		pr_vendor.name_text, 
		pr_shiphead.ship_code 
		TO vendor.vend_code, 
		vendor.name_text, 
		shiphead.ship_code 


		LET msgresp = kandoomsg("U",1037,'') 
		#1037 "ENTER TO view details; CTRL TO view Notes

		INPUT ARRAY pa_ship_dist WITHOUT DEFAULTS FROM sr_ship_dist.* 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 

			ON ACTION "NOTES"  --	ON KEY (control-n) 
				IF pa_ship_dist[idx].desc_text[1,3] = "###" 
				AND pa_ship_dist[idx].desc_text[14,16] = "###" THEN 
					CALL note_disp(p_cmpy, pa_ship_dist[idx].desc_text[4,13]) 
				ELSE 
					LET msgresp = kandoomsg("A",7027,'') 
					#7027 "No notes TO view"
				END IF 

			AFTER FIELD vouch_date 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF idx >= arr_count() 
					OR arr_curr() > arr_count() THEN 
						LET msgresp=kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD vouch_date 
					END IF 
				END IF 


			BEFORE FIELD vouch_code 
				IF pa_ship_dist[idx].vouch_date IS NULL THEN 
					LET msgresp = kandoomsg("L",9008,'') 
					#9008 "No voucher TO view"
					NEXT FIELD vouch_date 
				ELSE 
					CALL display_voucher_header(p_cmpy, pa_ship_dist[idx].vouch_code) 
					NEXT FIELD vouch_date 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	ELSE 
		LET msgresp=kandoomsg("L",9007,'') 
		#9007 "No vouchers found matching the criteria"
	END IF 
	CLOSE WINDOW wl121 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 
