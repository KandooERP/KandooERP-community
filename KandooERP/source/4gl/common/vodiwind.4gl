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

############################################################
# Module Scope Variables
############################################################
DEFINE glob_rec_jmparms RECORD LIKE jmparms.* 
DEFINE glob_base_currency LIKE glparms.base_currency_code 
DEFINE glob_rec_puparms RECORD LIKE puparms.* 
#DEFINE l_msgresp LIKE language.yes_flag


#############################################################
# FUNCTION disp_dist_amt(p_cmpy_code,p_vouch_code)
#
#
############################################################
FUNCTION disp_dist_amt(p_cmpy_code,p_vouch_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_arr_rec_voucherdist DYNAMIC ARRAY OF #array[2000] OF 
	RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE voucherdist.line_num, 
		type_ind LIKE voucherdist.type_ind, 
		acct_code LIKE voucherdist.acct_code, 
		dist_amt LIKE voucherdist.dist_amt, 
		dist_qty LIKE voucherdist.dist_qty, 
		uom_code LIKE coa.uom_code 
	END RECORD 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE idx SMALLINT 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_voucher.* 
	FROM voucher 
	WHERE cmpy_code = p_cmpy_code 
	AND vouch_code = p_vouch_code 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",9022,"") 
		#9022 "Logic Error: Voucher NOT found FOR distribution"
		RETURN 
	END IF 
	SELECT * INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = l_rec_voucher.vend_code 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",9014,"") 
		#9014" Logic Error: Vendor does NOT Exist"
		RETURN 
	END IF 

	OPEN WINDOW p169 with FORM "P169" 
	CALL windecoration_p("P169") 

	DISPLAY BY NAME l_rec_voucher.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_voucher.vouch_code, 
	l_rec_voucher.total_amt 

	DISPLAY BY NAME l_rec_voucher.currency_code 
	attribute(green) 
	DISPLAY l_rec_voucher.dist_amt, 
	l_rec_voucher.dist_qty 
	TO voucher.dist_amt, 
	voucher.dist_qty 

	IF l_rec_voucher.line_num > 30 THEN 
		LET l_msgresp=kandoomsg("P",1001,"") 
		#1001 Enter Selection Criteria - ESC TO Continue
		CONSTRUCT BY NAME l_where_text ON voucherdist.line_num, 
		voucherdist.type_ind, 
		voucherdist.acct_code, 
		voucherdist.dist_amt, 
		voucherdist.dist_qty 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","vodiwind","construct-voucherdist") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


	ELSE 
		LET l_where_text = "1=1" 
	END IF 
	LET l_query_text = "SELECT * FROM voucherdist ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND vend_code = '",l_rec_voucher.vend_code,"' ", 
	"AND vouch_code ='",l_rec_voucher.vouch_code,"' ", 
	"ORDER BY 2,3,4" 
	IF not(int_flag OR quit_flag) THEN 
		LET l_msgresp=kandoomsg("P",1002,"") 
		#P1002 Searching database - Please Wait
		PREPARE s_voucherdist FROM l_query_text 
		DECLARE c1_voucherdist CURSOR FOR s_voucherdist 
		LET idx = 0 

		FOREACH c1_voucherdist INTO l_rec_voucherdist.* 
			LET idx = idx + 1 
			LET l_arr_rec_voucherdist[idx].line_num = l_rec_voucherdist.line_num 
			LET l_arr_rec_voucherdist[idx].type_ind = l_rec_voucherdist.type_ind 
			LET l_arr_rec_voucherdist[idx].acct_code = l_rec_voucherdist.acct_code 
			LET l_arr_rec_voucherdist[idx].dist_amt = l_rec_voucherdist.dist_amt 
			LET l_arr_rec_voucherdist[idx].dist_qty = l_rec_voucherdist.dist_qty 
			SELECT uom_code INTO l_arr_rec_voucherdist[idx].uom_code 
			FROM coa 
			WHERE cmpy_code = p_cmpy_code 
			AND acct_code = l_rec_voucherdist.acct_code 
			IF idx = 2000 THEN 
				LET l_msgresp=kandoomsg("P",9017,idx) 
				#P9017 " First 2000 lines selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		CALL set_count(idx) 
		LET l_msgresp = kandoomsg("P",1014,"") 
		#1014 F3 page forward, F4 page back  CTRL N FOR Notes"

		INPUT ARRAY l_arr_rec_voucherdist WITHOUT DEFAULTS FROM sr_voucherdist.* attribute(UNBUFFERED, INSERT ROW = false, append ROW = false, auto append = false, DELETE ROW = false) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","vodiwind","input-arr-voucherdist-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET idx = arr_curr() 
				#LET scrn = scr_line()
				DISPLAY l_arr_rec_voucherdist[idx].line_num TO idx 

				#DISPLAY l_arr_rec_voucherdist[idx].*
				#     TO sr_voucherdist[scrn].*

				CALL disp_vouchline(p_cmpy_code,p_vouch_code,l_arr_rec_voucherdist[idx].line_num) 
				NEXT FIELD scroll_flag 

				#         AFTER FIELD scroll_flag
				#            IF fgl_lastkey() = fgl_keyval("down") THEN
				#               IF arr_curr() = arr_count() THEN
				#                  LET l_msgresp=kandoomsg("P",9001,"")
				#                  #9001 There are no more rows in the direction ...
				#                  NEXT FIELD scroll_flag
				#               ELSE
				#                  IF l_arr_rec_voucherdist[idx+1].type_ind IS NULL THEN
				#                     LET l_msgresp=kandoomsg("P",9001,"")
				#                     #9001 There are no more rows in the direction ...
				#                     NEXT FIELD scroll_flag
				#                  END IF
				#               END IF
				#            END IF

			BEFORE FIELD type_ind 

				LET idx = arr_curr() 
				CASE 
					WHEN l_arr_rec_voucherdist[idx].type_ind = "J" 
						CALL cr_jm_show(p_cmpy_code,p_vouch_code,l_arr_rec_voucherdist[idx].line_num) 
						NEXT FIELD scroll_flag 
					WHEN l_arr_rec_voucherdist[idx].type_ind = "P" 
						CALL cr_po_show(p_cmpy_code,p_vouch_code,l_arr_rec_voucherdist[idx].line_num) 
						NEXT FIELD scroll_flag 
					OTHERWISE 
						NEXT FIELD scroll_flag 
				END CASE 

			ON ACTION "Notes" #on KEY (control-n) 
				SELECT * INTO l_rec_voucherdist.* 
				FROM voucherdist 
				WHERE cmpy_code = p_cmpy_code 
				AND vouch_code = l_rec_voucher.vouch_code 
				AND line_num = l_arr_rec_voucherdist[idx].line_num 
				IF l_rec_voucherdist.desc_text[1,3] = "###" 
				AND l_rec_voucherdist.desc_text[16,18] = "###" THEN 
					CALL note_disp(p_cmpy_code,l_rec_voucherdist.desc_text[4,15]) 
				END IF 
				#AFTER ROW
				#   DISPLAY l_arr_rec_voucherdist[idx].*
				#        TO sr_voucherdist[scrn].*



		END INPUT 

	END IF 

	CLOSE WINDOW p169 

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 


#############################################################
# FUNCTION disp_vouchline(p_cmpy_code,p_vouch_code,p_line_num)
#
#
############################################################
FUNCTION disp_vouchline(p_cmpy_code,p_vouch_code,p_line_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE p_line_num LIKE voucher.line_num 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_prompt 
	RECORD 
		line_1 CHAR(25), 
		line_2 CHAR(25) 
	END RECORD 
	DEFINE l_temp_text CHAR(30) 

	SELECT * INTO l_rec_voucherdist.* 
	FROM voucherdist 
	WHERE cmpy_code = p_cmpy_code 
	AND vouch_code = p_vouch_code 
	AND line_num = p_line_num 
	IF STATUS = NOTFOUND THEN 
		CLEAR analy_prompt_text, 
		line_1, 
		line_2, 
		analysis_text, 
		desc_text, 
		job_code, 
		res_code 
	ELSE 
		SELECT * INTO l_rec_coa.* 
		FROM coa 
		WHERE cmpy_code = p_cmpy_code 
		AND acct_code = l_rec_voucherdist.acct_code 
		IF l_rec_coa.analy_prompt_text IS NULL THEN 
			LET l_rec_coa.analy_prompt_text = "Analysis" 
		END IF 
		LET l_temp_text = l_rec_coa.analy_prompt_text CLIPPED,"..............." 
		LET l_rec_coa.analy_prompt_text = l_temp_text 
		CASE l_rec_voucherdist.type_ind 
			WHEN "A" 
				LET l_rec_prompt.line_1 = kandooword("customer.cust_code",1) 
				LET l_rec_prompt.line_1 = l_rec_prompt.line_1 CLIPPED,"........." 
				LET l_rec_prompt.line_2 = kandooword("invoicehead.inv_num",1) 
				LET l_rec_prompt.line_2 = l_rec_prompt.line_2 CLIPPED,"........." 
				LET l_rec_voucherdist.job_code = l_rec_voucherdist.res_code 
				LET l_rec_voucherdist.res_code = l_rec_voucherdist.po_num 
			WHEN "J" 
				LET l_rec_prompt.line_1 = kandooword(TRAN_TYPE_JOB_JOB,1) 
				LET l_rec_prompt.line_1 = l_rec_prompt.line_1 CLIPPED,"........." 
				LET l_rec_prompt.line_2 = kandooword("jmresource",1) 
				LET l_rec_prompt.line_2 = l_rec_prompt.line_2 CLIPPED,"........." 
			WHEN "S" 
				LET l_rec_prompt.line_1 = kandooword("shipment",1) 
				LET l_rec_prompt.line_1 = l_rec_prompt.line_1 CLIPPED,"........." 
				LET l_rec_prompt.line_2 = kandooword("costtype",1) 
				LET l_rec_prompt.line_2 = l_rec_prompt.line_2 CLIPPED,"........." 
			WHEN "P" 
				LET l_rec_prompt.line_1 = kandooword("purchhead.order_num",1) 
				LET l_rec_prompt.line_1 = l_rec_prompt.line_1 CLIPPED,"........." 
				LET l_rec_prompt.line_2 = kandooword("purchdetl.line_num",1) 
				LET l_rec_prompt.line_2 = l_rec_prompt.line_2 CLIPPED,"........." 
				LET l_rec_voucherdist.job_code = l_rec_voucherdist.po_num 
				LET l_rec_voucherdist.res_code = l_rec_voucherdist.po_line_num 
			WHEN "W" 
				LET l_rec_prompt.line_1 = kandooword("ordhead.order_num",1) 
				LET l_rec_prompt.line_1 = l_rec_prompt.line_1 CLIPPED,"........." 
				LET l_rec_prompt.line_2 = kandooword("ordhead.cust_code",1) 
				LET l_rec_prompt.line_2 = l_rec_prompt.line_2 CLIPPED,"........." 
				LET l_rec_voucherdist.job_code = l_rec_voucherdist.po_num 
			OTHERWISE 
				LET l_rec_voucherdist.job_code = NULL 
				LET l_rec_voucherdist.res_code = NULL 
		END CASE 
		DISPLAY BY NAME l_rec_coa.analy_prompt_text, 
		l_rec_prompt.line_1, 
		l_rec_prompt.line_2 
		DISPLAY BY NAME l_rec_voucherdist.analysis_text, 
		l_rec_voucherdist.desc_text, 
		l_rec_voucherdist.job_code, 
		l_rec_voucherdist.res_code 

	END IF 
END FUNCTION 


#############################################################
# FUNCTION cr_jm_show(p_cmpy_code,p_vouch_code,p_line_num)
#
#
############################################################
FUNCTION cr_jm_show(p_cmpy_code,p_vouch_code,p_line_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vouch_code LIKE voucherdist.vouch_code 
	DEFINE p_line_num LIKE voucherdist.line_num 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_arr_rec_voucherdist DYNAMIC ARRAY OF #array[200] OF 
	RECORD 
		scroll_flag CHAR(1), 
		res_code LIKE voucherdist.res_code, 
		desc_text LIKE voucherdist.desc_text, 
		job_code LIKE voucherdist.job_code, 
		var_code LIKE voucherdist.var_code, 
		act_code LIKE voucherdist.act_code, 
		dist_amt LIKE voucherdist.dist_amt 
	END RECORD 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT

	SELECT * INTO glob_rec_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = p_cmpy_code 
	AND key_code = "1" 
	IF STATUS = NOTFOUND THEN 
		#P5010 Job Management Patameters Not Set up
		LET l_msgresp=kandoomsg("P",5010,"") 
		RETURN 
	END IF 
	SELECT base_currency_code INTO glob_base_currency 
	FROM glparms 
	WHERE cmpy_code = p_cmpy_code 
	AND key_code = "1" 
	IF STATUS = NOTFOUND THEN 
		#P5007 GL Parameters Not Set up
		LET l_msgresp=kandoomsg("P",5007,"") 
		RETURN 
	END IF 

	OPEN WINDOW j147 with FORM "J147" 
	CALL windecoration_j("J147") 

	LET l_msgresp=kandoomsg("P",1002,"") 
	#1002 Searching database pls wait

	SELECT * INTO l_rec_voucher.* 
	FROM voucher 
	WHERE cmpy_code = p_cmpy_code 
	AND vouch_code = p_vouch_code 

	SELECT * INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = l_rec_voucher.vend_code 

	DISPLAY BY NAME l_rec_voucher.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_voucher.vouch_code, 
	l_rec_voucher.total_amt, 
	l_rec_voucher.dist_amt, 
	l_rec_voucher.currency_code 


	DECLARE c2_voucherdist CURSOR FOR 
	SELECT * FROM voucherdist 
	WHERE cmpy_code = p_cmpy_code 
	AND vouch_code = p_vouch_code 
	AND type_ind = "J" 
	ORDER BY line_num 

	LET idx = 0 
	FOREACH c2_voucherdist INTO l_rec_voucherdist.* 

		LET idx = idx + 1 
		LET l_arr_rec_voucherdist[idx].res_code = l_rec_voucherdist.res_code 
		LET l_arr_rec_voucherdist[idx].job_code = l_rec_voucherdist.job_code 
		LET l_arr_rec_voucherdist[idx].var_code = l_rec_voucherdist.var_code 
		LET l_arr_rec_voucherdist[idx].act_code = l_rec_voucherdist.act_code 
		LET l_arr_rec_voucherdist[idx].desc_text = l_rec_voucherdist.desc_text 
		LET l_arr_rec_voucherdist[idx].dist_amt = l_rec_voucherdist.dist_amt 
		IF idx = 200 THEN 
			LET l_msgresp=kandoomsg("P",9028,idx) 
			#P9028 Only first Job Management Vouchers Selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("U",1007,"") 
	#1007 TAB TO view line.

	INPUT ARRAY l_arr_rec_voucherdist WITHOUT DEFAULTS FROM sr_voucherdist.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","vodiwind","input-arr-voucherdist-2") 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			IF l_arr_rec_voucherdist[idx].res_code IS NOT NULL THEN 
				#DISPLAY l_arr_rec_voucherdist[idx].*
				#     TO sr_voucherdist[scrn].*


				SELECT * INTO l_rec_jmresource.* 
				FROM jmresource 
				WHERE cmpy_code = p_cmpy_code 
				AND res_code = l_arr_rec_voucherdist[idx].res_code 
				IF STATUS = NOTFOUND THEN 
					LET l_rec_jmresource.desc_text = "********" 
				END IF 
				DISPLAY l_rec_jmresource.desc_text,l_rec_jmresource.unit_code 
				TO jmresource.desc_text, jmresource.unit_code 

				SELECT title_text INTO l_rec_job.title_text 
				FROM job 
				WHERE cmpy_code = p_cmpy_code 
				AND job_code = l_arr_rec_voucherdist[idx].job_code 
				IF STATUS = NOTFOUND THEN 
					LET l_rec_job.title_text = "********" 
				END IF 
				DISPLAY l_rec_job.title_text TO job.title_text 

				SELECT title_text INTO l_rec_activity.title_text 
				FROM activity 
				WHERE cmpy_code = p_cmpy_code 
				AND job_code = l_arr_rec_voucherdist[idx].job_code 
				AND var_code = l_arr_rec_voucherdist[idx].var_code 
				AND activity_code = l_arr_rec_voucherdist[idx].act_code 
				IF STATUS = NOTFOUND THEN 
					LET l_rec_activity.title_text = "********" 
				END IF 
				DISPLAY l_rec_activity.title_text TO activity.title_text 

				DISPLAY BY NAME l_rec_jmresource.unit_code, 
				l_rec_voucherdist.trans_qty, 
				l_rec_voucherdist.cost_amt, 
				l_rec_voucherdist.charge_amt 

				LET l_rec_jobledger.trans_amt = l_rec_voucherdist.dist_amt 
				LET l_rec_jobledger.charge_amt = l_rec_voucherdist.charge_amt 
				* l_rec_voucherdist.trans_qty 
				DISPLAY l_rec_jobledger.trans_amt, 
				l_rec_jobledger.charge_amt 
				TO jobledger.trans_amt, 
				jobledger.charge_amt 

				DISPLAY l_rec_voucher.currency_code 
				TO voucher.currency_code 

			END IF 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("P",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD scroll_flag 
				ELSE 
					IF l_arr_rec_voucherdist[idx+1].res_code IS NULL THEN 
						LET l_msgresp=kandoomsg("P",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD res_code 
			LET idx = arr_curr() 
			IF l_arr_rec_voucherdist[idx].res_code IS NOT NULL THEN 
				SELECT * INTO l_rec_voucherdist.* 
				FROM voucherdist 
				WHERE cmpy_code = p_cmpy_code 
				AND vouch_code = p_vouch_code 
				AND line_num = p_line_num 
				CALL show_jm_line(p_cmpy_code, l_rec_voucherdist.*) 
			END IF 

			#AFTER ROW
			#   DISPLAY l_arr_rec_voucherdist[idx].*
			#        TO sr_voucherdist[scrn].*

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW j147 
END FUNCTION 


#############################################################
# FUNCTION show_jm_line(p_cmpy_code,p_rec_voucherdist)
#
#
############################################################
FUNCTION show_jm_line(p_cmpy_code,p_rec_voucherdist) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_jobvars RECORD LIKE jobvars.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	#DEFINE l_rowid INTEGER

	#DEFINE l_rec_coa RECORD LIKE coa.* NOT used
	#DEFINE l_save_amt LIKE voucherdist.dist_amt
	#DEFINE l_temp1_text CHAR(8)
	#DEFINE l_temp2_text CHAR(8)

	SELECT jmresource.* 
	INTO l_rec_jmresource.* 
	FROM jmresource 
	WHERE cmpy_code = p_cmpy_code 
	AND res_code = p_rec_voucherdist.res_code 
	SELECT vendor.* 
	INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_rec_voucherdist.vend_code 
	SELECT voucher.* 
	INTO l_rec_voucher.* 
	FROM voucher 
	WHERE cmpy_code = p_cmpy_code 
	AND vouch_code = p_rec_voucherdist.vouch_code 
	AND vend_code = p_rec_voucherdist.vend_code 
	SELECT job.* 
	INTO l_rec_job.* 
	FROM job 
	WHERE cmpy_code = p_cmpy_code 
	AND job_code = p_rec_voucherdist.job_code 
	SELECT jobvars.* 
	INTO l_rec_jobvars.* 
	FROM jobvars 
	WHERE cmpy_code = p_cmpy_code 
	AND job_code = p_rec_voucherdist.job_code 
	AND var_code = p_rec_voucherdist.var_code 
	SELECT activity.* 
	INTO l_rec_activity.* 
	FROM activity 
	WHERE cmpy_code = p_cmpy_code 
	AND job_code = p_rec_voucherdist.job_code 
	AND var_code = p_rec_voucherdist.var_code 
	AND activity_code = p_rec_voucherdist.act_code 

	OPEN WINDOW j148 with FORM "J148" 
	CALL windecoration_j("J148") 

	DISPLAY BY NAME p_rec_voucherdist.res_code, 
	p_rec_voucherdist.job_code, 
	p_rec_voucherdist.var_code, 
	p_rec_voucherdist.act_code, 
	p_rec_voucherdist.desc_text, 
	p_rec_voucherdist.acct_code, 
	p_rec_voucherdist.cost_amt, 
	p_rec_voucherdist.trans_qty, 
	p_rec_voucherdist.dist_amt, 
	p_rec_voucherdist.charge_amt, 
	l_rec_vendor.vend_code, 
	l_rec_vendor.name_text 

	LET l_rec_jobledger.charge_amt = p_rec_voucherdist.trans_qty 
	* p_rec_voucherdist.charge_amt 


	DISPLAY l_rec_jmresource.desc_text, 
	l_rec_job.title_text, 
	l_rec_jobvars.title_text, 
	l_rec_activity.title_text, 
	l_rec_jmresource.unit_code, 
	p_rec_voucherdist.allocation_ind, 
	l_rec_jobledger.charge_amt, 
	l_rec_voucher.total_amt, 
	l_rec_voucher.dist_amt, 
	l_rec_voucher.currency_code 
	TO jmresource.desc_text, 
	job.title_text, 
	jobvars.title_text, 
	activity.title_text, 
	jmresource.unit_code, 
	jobledger.allocation_ind, 
	jobledger.charge_amt, 
	voucher.total_amt, 
	voucher.dist_amt, 
	voucher.currency_code 

	DISPLAY l_rec_voucher.currency_code 
	TO voucher.currency_code 

	DISPLAY l_rec_voucher.currency_code 
	TO voucher.currency_code 

	DISPLAY glob_base_currency 
	TO glparms.base_currency_code 
	attribute(green) 
	CALL eventsuspend() # LET l_msgresp=kandoomsg("U",1,"") 
	#1 Any Key TO Continue
	CLOSE WINDOW j148 

END FUNCTION 


#############################################################
# FUNCTION cr_po_show(p_cmpy_code,p_vouch_code, p_line_num)
#
#
############################################################
FUNCTION cr_po_show(p_cmpy_code,p_vouch_code, p_line_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_line_num LIKE voucherdist.line_num 
	DEFINE p_vouch_code LIKE voucherdist.vouch_code 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_arr_rec_purchhead DYNAMIC ARRAY OF #array[300] OF 
	RECORD 
		scroll_flag CHAR(1), 
		order_num LIKE purchdetl.order_num, 
		order_amt LIKE voucher.dist_amt, 
		received_amt LIKE voucher.dist_amt, 
		paid_amt LIKE voucher.dist_amt, 
		remain_amt LIKE voucher.dist_amt, 
		voucher_amt LIKE voucher.dist_amt 
	END RECORD 
	DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 

	SELECT * INTO glob_rec_puparms.* FROM puparms 
	WHERE cmpy_code = p_cmpy_code 
	AND key_code = "1" 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",5018,"") 
		EXIT program 
	END IF 

	OPEN WINDOW r144 with FORM "R144" 
	CALL winDecoration_r("R144") 

	LET l_msgresp=kandoomsg("P",1002,"") 
	#1002 Searching database pls wait

	SELECT * INTO l_rec_voucher.* 
	FROM voucher 
	WHERE cmpy_code = p_cmpy_code 
	AND vouch_code = p_vouch_code 

	SELECT * INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = l_rec_voucher.vend_code 

	SELECT * INTO l_rec_voucherdist.* 
	FROM voucherdist 
	WHERE cmpy_code = p_cmpy_code 
	AND vouch_code = p_vouch_code 
	AND line_num = p_line_num 

	DISPLAY BY NAME l_rec_voucher.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_voucher.vouch_code, 
	l_rec_voucher.total_amt, 
	l_rec_voucher.dist_amt 

	DISPLAY BY NAME l_rec_voucher.currency_code 
	attribute(green) 
	DECLARE c_purchhead CURSOR FOR 
	SELECT purchhead.* 
	FROM purchhead 
	WHERE cmpy_code = p_cmpy_code 
	AND order_num = l_rec_voucherdist.po_num 
	ORDER BY order_num 

	LET idx = 0 
	FOREACH c_purchhead INTO l_rec_purchhead.* 
		LET idx = idx + 1 
		LET l_arr_rec_purchhead[idx].order_num = l_rec_purchhead.order_num 
		SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].order_amt FROM poaudit 
		WHERE cmpy_code = p_cmpy_code 
		AND po_num = l_rec_purchhead.order_num 
		AND order_qty != 0 
		SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].received_amt 
		FROM poaudit 
		WHERE cmpy_code = p_cmpy_code 
		AND po_num = l_rec_purchhead.order_num 
		AND received_qty != 0 
		IF l_rec_voucher.vouch_code IS NULL THEN 
			SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].paid_amt FROM voucherdist 
			WHERE cmpy_code = p_cmpy_code 
			AND po_num = l_rec_purchhead.order_num 
		ELSE 
			SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].paid_amt FROM voucherdist 
			WHERE cmpy_code = p_cmpy_code 
			AND vouch_code != l_rec_voucher.vouch_code 
			AND po_num = l_rec_purchhead.order_num 
		END IF 
		IF l_arr_rec_purchhead[idx].paid_amt > 0 THEN 
			IF l_arr_rec_purchhead[idx].paid_amt = l_arr_rec_purchhead[idx].order_amt THEN 
				INITIALIZE l_arr_rec_purchhead[idx].* TO NULL 
				LET idx = idx - 1 
				CONTINUE FOREACH 
			END IF 
		END IF 
		SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].voucher_amt FROM voucherdist 
		WHERE cmpy_code = p_cmpy_code 
		AND po_num = l_rec_purchhead.order_num 
		AND dist_amt <> 0 
		AND dist_amt IS NOT NULL 
		IF l_arr_rec_purchhead[idx].order_amt IS NULL THEN 
			LET l_arr_rec_purchhead[idx].order_amt = 0 
		END IF 
		IF l_arr_rec_purchhead[idx].received_amt IS NULL THEN 
			LET l_arr_rec_purchhead[idx].received_amt = 0 
		END IF 
		IF l_arr_rec_purchhead[idx].paid_amt IS NULL THEN 
			LET l_arr_rec_purchhead[idx].paid_amt = 0 
		END IF 
		IF l_arr_rec_purchhead[idx].voucher_amt IS NULL THEN 
			LET l_arr_rec_purchhead[idx].voucher_amt = 0 
		END IF 
		LET l_arr_rec_purchhead[idx].remain_amt = l_arr_rec_purchhead[idx].received_amt 
		- l_arr_rec_purchhead[idx].paid_amt 
		- l_arr_rec_purchhead[idx].voucher_amt 
		IF l_arr_rec_purchhead[idx].remain_amt < 0 THEN 
			LET l_arr_rec_purchhead[idx].remain_amt = 0 
		END IF 
		IF idx = 300 THEN 
			LET l_msgresp=kandoomsg("P",9040,idx) 
			#P9040 " Only first 300 Purchase Orders Selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("U",1007,"") 
	#1007 TAB TO view line
	INPUT ARRAY l_arr_rec_purchhead WITHOUT DEFAULTS FROM sr_purchhead.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","vodiwind","input-arr-purchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			#DISPLAY l_arr_rec_purchhead[idx].* TO sr_purchhead[scrn].*

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("P",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD scroll_flag 
				ELSE 
					IF l_arr_rec_purchhead[idx+1].order_num IS NULL 
					OR l_arr_rec_purchhead[idx+1].order_num = 0 THEN 
						LET l_msgresp=kandoomsg("P",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD order_num 
			IF l_arr_rec_purchhead[idx].order_num > 0 THEN 
				IF l_arr_rec_purchhead[idx].received_amt = l_arr_rec_purchhead[idx].paid_amt THEN 
					LET l_msgresp=kandoomsg("P",9547,"") 
					#9547 Nothing outstanding TO pay.  Receipt items first.
				ELSE 
					CALL show_po_line(p_cmpy_code, l_arr_rec_purchhead[idx].order_num, l_rec_voucher.*) 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
			#AFTER ROW
			#   DISPLAY l_arr_rec_purchhead[idx].* TO sr_purchhead[scrn].*



	END INPUT 

	CLOSE WINDOW r144 
END FUNCTION 


#############################################################
# FUNCTION show_po_line(p_cmpy_code, p_order_num, p_rec_voucher)
#
#
############################################################
FUNCTION show_po_line(p_cmpy_code,p_order_num,p_rec_voucher) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_order_num LIKE purchhead.order_num 
	DEFINE p_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_arr_rec_purchdetl DYNAMIC ARRAY OF #array[2000] OF 
	RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE purchdetl.line_num, 
		desc_text LIKE purchdetl.desc_text, 
		outstand_qty LIKE poaudit.voucher_qty, 
		outstand_amt LIKE poaudit.line_total_amt, 
		payment_qty LIKE poaudit.voucher_qty, 
		payment_amt LIKE poaudit.line_total_amt 
	END RECORD 
	DEFINE l_rec_display RECORD 
		remain_qty LIKE poaudit.order_qty, 
		received_amt LIKE poaudit.line_total_amt, 
		voucher_amt LIKE poaudit.line_total_amt, 
		remain_amt LIKE poaudit.line_total_amt 
	END RECORD 
	DEFINE l_commit_qty LIKE poaudit.order_qty 
	DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW r146 with FORM "R146" 
	CALL winDecoration_r("R146") 

	SELECT * INTO l_rec_purchhead.* FROM purchhead 
	WHERE cmpy_code = p_cmpy_code 
	AND order_num = p_order_num 

	LET l_msgresp=kandoomsg("P",1002,"") 
	#1002 Searching Database;  Please wait.
	LET l_rec_purchdetl.order_num = p_order_num 
	DISPLAY BY NAME p_rec_voucher.vouch_code, 
	l_rec_purchdetl.order_num, 
	p_rec_voucher.total_amt, 
	p_rec_voucher.dist_amt 

	DISPLAY BY NAME p_rec_voucher.currency_code 
	attribute(green) 

	DECLARE c_purchdetl CURSOR FOR 
	SELECT * FROM purchdetl 
	WHERE cmpy_code = p_rec_voucher.cmpy_code 
	AND vend_code = l_rec_purchhead.vend_code 
	AND order_num = p_order_num 
	ORDER BY 3,4 
	LET idx = 0 
	FOREACH c_purchdetl INTO l_rec_purchdetl.* 
		LET idx = idx + 1 
		LET l_arr_rec_purchdetl[idx].line_num = l_rec_purchdetl.line_num 
		LET l_arr_rec_purchdetl[idx].desc_text = l_rec_purchdetl.desc_text 
		CALL po_line_info(l_rec_purchdetl.cmpy_code, 
		l_rec_purchdetl.order_num, 
		l_rec_purchdetl.line_num) 
		RETURNING l_rec_poaudit.order_qty, 
		l_rec_poaudit.received_qty, 
		l_rec_poaudit.voucher_qty, 
		l_rec_poaudit.unit_cost_amt, 
		l_rec_poaudit.ext_cost_amt, 
		l_rec_poaudit.unit_tax_amt, 
		l_rec_poaudit.ext_tax_amt, 
		l_rec_poaudit.line_total_amt 
		IF p_rec_voucher.vouch_code IS NULL THEN 
			LET l_commit_qty = 0 
		ELSE 
			LET l_commit_qty = 0 
			SELECT trans_qty 
			INTO l_commit_qty FROM voucherdist 
			WHERE cmpy_code = p_rec_voucher.cmpy_code 
			AND vend_code = p_rec_voucher.vend_code 
			AND vouch_code = p_rec_voucher.vouch_code 
			AND po_num = l_rec_purchdetl.order_num 
			AND po_line_num = l_rec_purchdetl.line_num 
		END IF 
		LET l_rec_poaudit.voucher_qty = l_rec_poaudit.voucher_qty - l_commit_qty 
		LET l_rec_poaudit.unit_cost_amt = l_rec_poaudit.unit_cost_amt 
		+ l_rec_poaudit.unit_tax_amt 
		SELECT trans_qty,dist_amt 
		INTO l_arr_rec_purchdetl[idx].payment_qty, 
		l_arr_rec_purchdetl[idx].payment_amt 
		FROM voucherdist 
		WHERE cmpy_code = p_cmpy_code 
		AND po_num = l_rec_purchdetl.order_num 
		AND po_line_num = l_rec_purchdetl.line_num 
		AND dist_amt <> 0 
		AND dist_amt IS NOT NULL 
		IF STATUS = NOTFOUND THEN 
			LET l_arr_rec_purchdetl[idx].payment_qty = 0 
			LET l_arr_rec_purchdetl[idx].payment_amt = 0 
		END IF 
		LET l_arr_rec_purchdetl[idx].outstand_qty = l_rec_poaudit.received_qty 
		- l_rec_poaudit.voucher_qty 
		- l_arr_rec_purchdetl[idx].payment_qty 
		LET l_arr_rec_purchdetl[idx].outstand_amt = l_rec_poaudit.unit_cost_amt 
		* l_arr_rec_purchdetl[idx].outstand_qty 
		IF l_arr_rec_purchdetl[idx].outstand_qty < 0 THEN 
			LET l_arr_rec_purchdetl[idx].outstand_qty = 0 
		END IF 
		IF l_arr_rec_purchdetl[idx].outstand_amt < 0 THEN 
			LET l_arr_rec_purchdetl[idx].outstand_amt = 0 
		END IF 
		IF idx = 2000 THEN 
			EXIT FOREACH 
			LET l_msgresp=kandoomsg("P",9040,idx) 
			#P9040 " Only first 2000 Purchase Orders Selected"
		END IF 
	END FOREACH 

	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("U",1007,"") 
	#1007 TAB TO view line

	INPUT ARRAY l_arr_rec_purchdetl WITHOUT DEFAULTS FROM sr_purchdetl.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","vodiwind","input-arr-purchdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			CALL po_line_info(p_rec_voucher.cmpy_code, 
			l_rec_purchdetl.order_num, 
			l_arr_rec_purchdetl[idx].line_num) 
			RETURNING l_rec_poaudit.order_qty, 
			l_rec_poaudit.received_qty, 
			l_rec_poaudit.voucher_qty, 
			l_rec_poaudit.unit_cost_amt, 
			l_rec_poaudit.ext_cost_amt, 
			l_rec_poaudit.unit_tax_amt, 
			l_rec_poaudit.ext_tax_amt, 
			l_rec_poaudit.line_total_amt 

			IF p_rec_voucher.vouch_code IS NULL THEN 
				LET l_commit_qty = 0 
			ELSE 
				LET l_commit_qty = 0 
				SELECT trans_qty INTO l_commit_qty FROM voucherdist 
				WHERE cmpy_code = p_rec_voucher.cmpy_code 
				AND vend_code = p_rec_voucher.vend_code 
				AND vouch_code = p_rec_voucher.vouch_code 
				AND po_num = p_order_num 
				AND po_line_num = l_arr_rec_purchdetl[idx].line_num 
			END IF 
			LET l_rec_poaudit.voucher_qty = l_rec_poaudit.voucher_qty - l_commit_qty 
			LET l_rec_display.remain_qty = l_rec_poaudit.received_qty 
			- l_rec_poaudit.voucher_qty 
			LET l_rec_poaudit.unit_cost_amt = l_rec_poaudit.unit_cost_amt 
			+ l_rec_poaudit.unit_tax_amt 
			LET l_rec_display.received_amt = l_rec_poaudit.received_qty 
			* l_rec_poaudit.unit_cost_amt 
			LET l_rec_display.voucher_amt = l_rec_poaudit.voucher_qty 
			* l_rec_poaudit.unit_cost_amt 
			LET l_rec_display.remain_amt = l_rec_display.remain_qty 
			* l_rec_poaudit.unit_cost_amt 
			IF l_rec_display.remain_amt < 0 THEN #jp 
				LET l_rec_display.remain_amt = 0 
			END IF 
			DISPLAY BY NAME l_rec_poaudit.order_qty, 
			l_rec_poaudit.received_qty, 
			l_rec_poaudit.voucher_qty, 
			l_rec_display.remain_qty, 
			l_rec_poaudit.unit_cost_amt, 
			l_rec_poaudit.line_total_amt, 
			l_rec_display.received_amt, 
			l_rec_display.voucher_amt, 
			l_rec_display.remain_amt 

			CASE 
				WHEN fgl_lastkey() = fgl_keyval("down") 
					IF infield(payment_qty) THEN 
						NEXT FIELD payment_qty 
					END IF 
					IF infield(payment_amt) THEN 
						IF (arr_curr() -1) = arr_count() THEN 
							NEXT FIELD scroll_flag 
						ELSE 
							NEXT FIELD payment_amt 
						END IF 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("up") 
					IF infield(payment_qty) THEN 
						NEXT FIELD payment_qty 
					END IF 
					IF infield(payment_amt) THEN 
						NEXT FIELD payment_amt 
					END IF 
				OTHERWISE 
					NEXT FIELD scroll_flag 
			END CASE 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("P",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD scroll_flag 
				ELSE 
					IF l_arr_rec_purchdetl[idx+1].line_num IS NULL 
					OR l_arr_rec_purchdetl[idx+1].line_num = 0 THEN 
						LET l_msgresp=kandoomsg("P",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD payment_qty 
			IF l_arr_rec_purchdetl[idx].line_num > 0 THEN 
				CALL pohiwind(l_rec_purchdetl.cmpy_code, 
				p_rec_voucher.vend_code, 
				l_rec_purchdetl.order_num, 
				l_arr_rec_purchdetl[idx].line_num) 
				NEXT FIELD scroll_flag 
			END IF 



	END INPUT 

	CLOSE WINDOW r146 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 
