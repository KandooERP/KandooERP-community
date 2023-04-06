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


# program L17a.4gl - FUNCTION ship_dist dispalys the debit memo distribution FOR
#                    shipment debit memo by shipment

FUNCTION ship_debit(p_cmpy, pr_ship_code, pr_vend_code) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_ship_code LIKE shiphead.ship_code, 
	pr_vend_code LIKE vendor.vend_code, 
	pr_debithead RECORD LIKE debithead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_debitdist RECORD LIKE debitdist.*, 
	pa_ship_debit array[110] OF RECORD 
		debit_date LIKE debithead.debit_date, 
		debit_code LIKE debithead.debit_num, 
		line_num LIKE debitdist.line_num, 
		cost_type_code LIKE shipcosttype.cost_type_code, 
		desc_text LIKE debitdist.desc_text, 
		dist_amt LIKE debitdist.dist_amt 
	END RECORD, 
	scrn, idx SMALLINT 


	OPEN WINDOW wl132 with FORM "L132" 
	CALL windecoration_l("L132") -- albo kd-761 

	SELECT * INTO pr_shiphead.* FROM shiphead 
	WHERE shiphead.cmpy_code = p_cmpy 
	AND shiphead.vend_code = pr_vend_code 
	AND shiphead.ship_code = pr_ship_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("L",9005,'') 
		#L9005 "Shipment was NOT found "
		CLOSE WINDOW wl132 
		RETURN 
	END IF 

	IF pr_shiphead.ship_type_ind = '3' THEN 
		SELECT name_text INTO pr_vendor.name_text FROM customer 
		WHERE customer.cmpy_code = p_cmpy 
		AND customer.cust_code = pr_vend_code 
		IF status = notfound THEN 
			LET msgresp=kandoomsg("A",9109,'') 
			#A9109 "Customer NOT found "
			CLOSE WINDOW wl132 
			RETURN 
		END IF 
	ELSE 
		SELECT * INTO pr_vendor.* FROM vendor 
		WHERE vendor.cmpy_code = p_cmpy 
		AND vendor.vend_code = pr_vend_code 
		IF status = notfound THEN 
			LET msgresp=kandoomsg("P",9501,'') 
			#P9501 "Vendor NOT found "
			CLOSE WINDOW wl132 
			RETURN 
		END IF 
	END IF 

	LET msgresp = kandoomsg("U",1002, '') 
	#1002 "Seacrching Database; Please wait

	DECLARE c_dist CURSOR FOR 
	SELECT * INTO pr_debithead.*, pr_debitdist.* 
	FROM debithead, debitdist 
	WHERE debithead.cmpy_code = p_cmpy 
	AND debitdist.cmpy_code = p_cmpy 
	AND debitdist.job_code = pr_ship_code 
	AND debithead.debit_num = debitdist.debit_code 
	ORDER BY debithead.debit_date, debitdist.debit_code, 
	debitdist.line_num 

	LET idx = 0 
	FOREACH c_dist 
		LET idx = idx + 1 
		LET pa_ship_debit[idx].debit_date = pr_debithead.debit_date 
		LET pa_ship_debit[idx].debit_code = pr_debithead.debit_num 
		LET pa_ship_debit[idx].line_num = pr_debitdist.line_num 
		LET pa_ship_debit[idx].cost_type_code = pr_debitdist.res_code 
		LET pa_ship_debit[idx].desc_text = pr_debitdist.desc_text 
		LET pa_ship_debit[idx].dist_amt = pr_debitdist.dist_amt 
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

		INPUT ARRAY pa_ship_debit WITHOUT DEFAULTS FROM sr_ship_dist.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","L17a","input-arr-pa_ship_debit-1") -- albo 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 

			ON ACTION "NOTES"  --	ON KEY (control-n) 
				IF pa_ship_debit[idx].desc_text[1,3] = "###" 
				AND pa_ship_debit[idx].desc_text[14,16] = "###" THEN 
					CALL note_disp(p_cmpy, pa_ship_debit[idx].desc_text[4,13]) 
				ELSE 
					LET msgresp = kandoomsg("A",7027,'') 
					#7027 "No notes TO view"
				END IF 

			AFTER FIELD debit_date 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF idx >= arr_count() 
					OR arr_curr() > arr_count() THEN 
						LET msgresp=kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD debit_date 
					END IF 
				END IF 

			BEFORE FIELD debit_code 
				IF pa_ship_debit[idx].debit_date IS NULL THEN 
					LET msgresp = kandoomsg("L",9010,'') 
					#9008 "No Debit TO view"
					NEXT FIELD debit_date 
				ELSE 
					CALL disp_dm_head(p_cmpy, pa_ship_debit[idx].debit_code) 
					NEXT FIELD debit_date 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	ELSE 
		LET msgresp=kandoomsg("L",9009,'') 
		#9007 "No vouchers found matching the criteria"
	END IF 
	CLOSE WINDOW wl132 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 
