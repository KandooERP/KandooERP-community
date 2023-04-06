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
	Source code beautified by beautify.pl on 2020-01-03 13:41:21	$Id: $
}
############################################################
# P29c.4gl - creates job management payment TO temp table t_jmdist.
#
# \brief module has two levels of commit/discard.  JM lines are
#            added TO t_jmdist,  on acceptance they are committed TO
#            t_voucherdist.  WHEN ARRAY in P29a IS accepted THEN all
#            lines are committed TO database
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
GLOBALS "P29_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 
DEFINE modu_base_currency LIKE glparms.base_currency_code 

############################################################
# FUNCTION cr_jm_dist(p_cmpy,p_kandoouser_sign_on_code)
#
#
############################################################
FUNCTION cr_jm_dist(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_rec_jmparms RECORD LIKE jmparms.*
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_arr_rowid array[200] OF INTEGER 
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
	DEFINE l_rowid INTEGER 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT 
	DEFINE i SMALLINT

	SELECT * INTO l_rec_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = glob_rec_voucher.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		#P5010 Job Management Patameters Not Set up
		LET l_msgresp=kandoomsg("P",5010,"") 
		RETURN 
	END IF 
	SELECT base_currency_code INTO modu_base_currency 
	FROM glparms 
	WHERE cmpy_code = glob_rec_voucher.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		#P5007 GL Parameters Not Set up
		LET l_msgresp=kandoomsg("P",5007,"") 
		RETURN 
	END IF 

	OPEN WINDOW j147 with FORM "J147" 
	CALL winDecoration_j("J147") 

	LET l_msgresp=kandoomsg("P",1002,"") 
	#1002 Searching database pls wait
	DISPLAY BY NAME glob_rec_voucher.vend_code, 
	glob_rec_vendor.name_text, 
	glob_rec_voucher.vouch_code, 
	glob_rec_voucher.total_amt, 
	glob_rec_voucher.dist_amt 

	DISPLAY glob_rec_voucher.currency_code, 
	glob_rec_voucher.currency_code, 
	modu_base_currency 
	TO sr_voucher[1].currency_code, 
	sr_voucher[2].currency_code, 
	glparms.base_currency_code 
	attribute(green) 
	### Informix bug workaround

	WHENEVER ERROR CONTINUE 
	SELECT * FROM t_voucherdist WHERE rowid = 0 INTO temp t_jmdist with no LOG 
	IF sqlca.sqlcode < 0 THEN 
		DELETE FROM t_jmdist 
	END IF 
	INSERT INTO t_jmdist SELECT * FROM t_voucherdist 
	WHENEVER ERROR stop 
	DECLARE c_voucherdist CURSOR FOR 
	SELECT rowid, * FROM t_jmdist 
	WHERE type_ind = "J" 
	ORDER BY line_num 

	LET idx = 0 
	FOREACH c_voucherdist INTO l_rowid, 
		l_rec_voucherdist.* 
		IF l_rec_voucherdist.res_code IS NULL THEN 
			DELETE FROM t_jmdist 
			WHERE rowid = l_rowid 
			CONTINUE FOREACH 
		END IF 
		LET idx = idx + 1 
		LET l_arr_rowid[idx] = l_rowid 
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

	IF idx = 0 THEN 
		LET idx = 1 
		LET l_arr_rec_voucherdist[1].var_code = NULL 
	END IF 
	OPTIONS DELETE KEY f2, 
	INSERT KEY f1 
	LET l_msgresp=kandoomsg("P",1038,"") 
	#1038 Enter Job Management Voucher Line - F1 Add F2 Delete
	CALL set_count(idx) 

	INPUT ARRAY l_arr_rec_voucherdist WITHOUT DEFAULTS FROM sr_voucherdist.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P29c","inp-arr-voucherdist-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			IF l_arr_rec_voucherdist[idx].res_code IS NOT NULL THEN 
				#            DISPLAY l_arr_rec_voucherdist[idx].*
				#                 TO sr_voucherdist[scrn].*

				SELECT * INTO l_rec_voucherdist.* 
				FROM t_jmdist 
				WHERE rowid = l_arr_rowid[idx] 
				SELECT * INTO l_rec_jmresource.* 
				FROM jmresource 
				WHERE cmpy_code = p_cmpy 
				AND res_code = l_arr_rec_voucherdist[idx].res_code 

				IF status = NOTFOUND THEN 
					LET l_rec_jmresource.desc_text = "********" 
				END IF 

				DISPLAY l_rec_jmresource.desc_text TO jmresource.desc_text 

				SELECT title_text INTO l_rec_job.title_text 
				FROM job 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_arr_rec_voucherdist[idx].job_code 

				IF status = NOTFOUND THEN 
					LET l_rec_job.title_text = "********" 
				END IF 
				DISPLAY l_rec_job.title_text TO job.title_text 

				SELECT title_text INTO l_rec_activity.title_text 
				FROM activity 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_arr_rec_voucherdist[idx].job_code 
				AND var_code = l_arr_rec_voucherdist[idx].var_code 
				AND activity_code = l_arr_rec_voucherdist[idx].act_code 

				IF status = NOTFOUND THEN 
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
			LET l_arr_rowid[idx] = dist_jm_line(p_cmpy,l_arr_rowid[idx]) 
			SELECT * INTO l_rec_voucherdist.* 
			FROM t_jmdist 
			WHERE rowid = l_arr_rowid[idx] 
			IF status = NOTFOUND THEN 
				FOR i = idx TO arr_count() 
					LET l_arr_rowid[i] = l_arr_rowid[i+1] 
					LET l_arr_rec_voucherdist[i].* = l_arr_rec_voucherdist[i+1].* 
					#               IF scrn <= 5 THEN
					#                  DISPLAY l_arr_rec_voucherdist[i].*
					#                       TO sr_voucherdist[scrn].*
					#
					#                  LET scrn = scrn + 1
					#               END IF
				END FOR 
				LET l_arr_rowid[i] = 0 
				INITIALIZE l_arr_rec_voucherdist[i].* TO NULL 
			ELSE 
				LET l_arr_rec_voucherdist[idx].res_code = l_rec_voucherdist.res_code 
				LET l_arr_rec_voucherdist[idx].job_code = l_rec_voucherdist.job_code 
				LET l_arr_rec_voucherdist[idx].var_code = l_rec_voucherdist.var_code 
				LET l_arr_rec_voucherdist[idx].act_code = l_rec_voucherdist.act_code 
				LET l_arr_rec_voucherdist[idx].desc_text = l_rec_voucherdist.desc_text 
				LET l_arr_rec_voucherdist[idx].dist_amt = l_rec_voucherdist.dist_amt 

			END IF 
			SELECT sum(dist_amt) INTO glob_rec_voucher.dist_amt FROM t_jmdist 
			DISPLAY BY NAME glob_rec_voucher.dist_amt 

			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			FOR i = arr_count() TO idx step -1 
				LET l_arr_rowid[i+1] = l_arr_rowid[i] 
			END FOR 
			INITIALIZE l_arr_rec_voucherdist[idx].* TO NULL 
			#         CLEAR sr_voucherdist[scrn].*
			LET l_arr_rowid[idx] = 0 
			NEXT FIELD res_code 

		BEFORE DELETE 
			DELETE FROM t_jmdist 
			WHERE rowid = l_arr_rowid[idx] 
			FOR i = idx TO arr_count() 
				LET l_arr_rowid[i] = l_arr_rowid[i+1] 
			END FOR 

			#      AFTER ROW
			#         DISPLAY l_arr_rec_voucherdist[idx].*
			#              TO sr_voucherdist[scrn].*


	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_msgresp=kandoomsg("P",1005,"") 
		#1005 Searching database pls wait
		DELETE FROM t_voucherdist 
		INSERT INTO t_voucherdist SELECT * FROM t_jmdist 
	END IF 
	CLOSE WINDOW j147 
END FUNCTION 


############################################################
# FUNCTION dist_jm_line(p_cmpy,p_rowid)
#
#
############################################################
FUNCTION dist_jm_line(p_cmpy,p_rowid) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rowid INTEGER 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_jobvars RECORD LIKE jobvars.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_save_amt LIKE voucherdist.dist_amt 
	DEFINE l_temp1_text CHAR(8) 
	DEFINE l_temp2_text CHAR(8) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_rowid > 0 THEN 
		SELECT * INTO l_rec_voucherdist.* 
		FROM t_jmdist 
		WHERE rowid = l_rowid 
		SELECT jmresource.* 
		INTO l_rec_jmresource.* 
		FROM jmresource 
		WHERE cmpy_code = p_cmpy 
		AND res_code = l_rec_voucherdist.res_code 
		SELECT job.* 
		INTO l_rec_job.* 
		FROM job 
		WHERE cmpy_code = p_cmpy 
		AND job_code = l_rec_voucherdist.job_code 
		SELECT jobvars.* 
		INTO l_rec_jobvars.* 
		FROM jobvars 
		WHERE cmpy_code = p_cmpy 
		AND job_code = l_rec_voucherdist.job_code 
		AND var_code = l_rec_voucherdist.var_code 
		SELECT activity.* 
		INTO l_rec_activity.* 
		FROM activity 
		WHERE cmpy_code = p_cmpy 
		AND job_code = l_rec_voucherdist.job_code 
		AND var_code = l_rec_voucherdist.var_code 
		AND activity_code = l_rec_voucherdist.act_code 
	ELSE 
		LET l_rec_voucherdist.var_code = NULL 
		LET l_rec_voucherdist.cost_amt = 0 
		LET l_rec_voucherdist.charge_amt = 0 
		LET l_rec_voucherdist.trans_qty = 0 
	END IF 
	OPEN WINDOW j148 with FORM "J148" 
	CALL winDecoration_j("J148") 

	#1039 Enter Job Management Voucher Line - ESC TO Continue
	LET l_msgresp=kandoomsg("P",1039,"") 
	INPUT BY NAME glob_rec_vendor.vend_code, 
	glob_rec_vendor.name_text, 
	l_rec_voucherdist.res_code, 
	l_rec_voucherdist.acct_code, 
	l_rec_voucherdist.job_code, 
	l_rec_voucherdist.var_code, 
	l_rec_voucherdist.act_code, 
	l_rec_voucherdist.desc_text, 
	l_rec_voucherdist.trans_qty, 
	l_rec_voucherdist.cost_amt, 
	l_rec_voucherdist.dist_amt, 
	l_rec_voucherdist.charge_amt WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P29c","inp-voucherdist-1") 

			LET l_rec_jobledger.charge_amt = l_rec_voucherdist.trans_qty 
			* l_rec_voucherdist.charge_amt 
			DISPLAY l_rec_jmresource.desc_text, 
			l_rec_job.title_text, 
			l_rec_jobvars.title_text, 
			l_rec_activity.title_text, 
			l_rec_jmresource.unit_code, 
			l_rec_voucherdist.allocation_ind, 
			l_rec_jobledger.charge_amt, 
			glob_rec_voucher.total_amt, 
			glob_rec_voucher.dist_amt 
			TO jmresource.desc_text, 
			job.title_text, 
			jobvars.title_text, 
			activity.title_text, 
			jmresource.unit_code, 
			jobledger.allocation_ind, 
			jobledger.charge_amt, 
			voucher.total_amt, 
			voucher.dist_amt 

			DISPLAY glob_rec_voucher.currency_code, 
			glob_rec_voucher.currency_code, 
			glob_rec_voucher.currency_code, 
			modu_base_currency 
			TO sr_currency[1].*, 
			sr_currency[2].*, 
			sr_currency[3].*, 
			glparms.base_currency_code 
			attribute(green) 



		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (F8) 
			IF l_rec_jmresource.res_code IS NOT NULL AND 
			l_rec_jmresource.allocation_flag <> "1" THEN 
				LET l_msgresp = kandoomsg("J",9555,"") 
			ELSE 
				CALL adjust_allocflag(p_cmpy, l_rec_jmresource.res_code, 
				l_rec_voucherdist.allocation_ind) 
				RETURNING l_rec_voucherdist.allocation_ind 
			END IF 

		ON ACTION "LOOKUP" infield (res_code) 
			LET l_temp1_text = show_res(p_cmpy) 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			IF l_temp1_text IS NOT NULL THEN 
				LET l_rec_voucherdist.res_code = l_temp1_text 
			END IF 
			NEXT FIELD res_code
			 
		ON ACTION "LOOKUP" infield (job_code) 
			LET l_temp1_text = show_job(p_cmpy) 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			IF l_temp1_text IS NOT NULL THEN 
				LET l_rec_voucherdist.job_code = l_temp1_text 
			END IF 
			NEXT FIELD job_code 
		
		ON ACTION "LOOKUP" infield (var_code) 
			LET l_temp1_text = show_jobvars(p_cmpy,l_rec_voucherdist.job_code) 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			IF l_temp1_text IS NOT NULL THEN 
				LET l_rec_voucherdist.var_code = l_temp1_text 
			END IF 
			NEXT FIELD var_code 
		
		ON ACTION "LOOKUP" infield (act_code) 
			LET l_temp1_text = show_activity(p_cmpy,l_rec_voucherdist.job_code, 
			l_rec_voucherdist.var_code) 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			IF l_temp1_text IS NOT NULL THEN 
				LET l_rec_voucherdist.act_code = l_temp1_text 
			END IF 
			NEXT FIELD act_code 

			ON ACTION "NOTES" infield (desc_text)
		--ON KEY (control-n) infield (desc_text) 
			LET l_rec_voucherdist.desc_text = 
			sys_noter(p_cmpy,l_rec_voucherdist.desc_text) 
			NEXT FIELD desc_text 

		BEFORE FIELD res_code 
			LET l_temp2_text = l_rec_voucherdist.res_code 

		AFTER FIELD res_code 
			IF l_rec_voucherdist.res_code IS NULL THEN 
				LET l_msgresp=kandoomsg("P",9034,"") 
				#P9034 " Resource code must be entered
				NEXT FIELD res_code 
			ELSE 
				SELECT * INTO l_rec_jmresource.* 
				FROM jmresource 
				WHERE cmpy_code = p_cmpy 
				AND res_code = l_rec_voucherdist.res_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9029,"") 
					#P9029 " Resource code does NOT exist - Try Window"
					NEXT FIELD res_code 
				ELSE 
					DISPLAY l_rec_jmresource.desc_text TO jmresource.desc_text 

					LET l_rec_voucherdist.allocation_ind = l_rec_jmresource.allocation_ind 
					IF l_rec_voucherdist.allocation_ind IS NULL THEN 
						LET l_rec_voucherdist.allocation_ind = "A" 
					END IF 
					DISPLAY BY NAME l_rec_voucherdist.allocation_ind 

					IF l_temp2_text IS NULL 
					OR l_temp2_text != l_rec_voucherdist.res_code THEN 
						IF l_rec_jmresource.unit_cost_amt IS NULL THEN 
							LET l_rec_jmresource.unit_cost_amt = 1 
						END IF 
						IF l_rec_jmresource.unit_bill_amt IS NULL THEN 
							LET l_rec_jmresource.unit_bill_amt = 1 
						END IF 
						LET l_rec_voucherdist.desc_text = l_rec_jmresource.desc_text 
						LET l_rec_voucherdist.acct_code = l_rec_jmresource.exp_acct_code 
						IF glob_rec_voucher.conv_qty != 1 
						AND glob_rec_voucher.conv_qty != 0 THEN 
							LET l_rec_voucherdist.cost_amt = l_rec_jmresource.unit_cost_amt * 
							glob_rec_voucher.conv_qty 
						ELSE 
							LET l_rec_voucherdist.cost_amt = l_rec_jmresource.unit_cost_amt 
						END IF 
						LET l_rec_voucherdist.charge_amt = l_rec_jmresource.unit_bill_amt 
						DISPLAY BY NAME l_rec_voucherdist.desc_text, 
						l_rec_voucherdist.acct_code, 
						l_rec_jmresource.unit_code, 
						l_rec_voucherdist.cost_amt, 
						l_rec_voucherdist.charge_amt 

						LET l_rec_voucherdist.dist_amt = l_rec_voucherdist.trans_qty 
						* l_rec_voucherdist.cost_amt 
						LET l_rec_jobledger.charge_amt = l_rec_voucherdist.trans_qty 
						* l_rec_voucherdist.charge_amt 
						DISPLAY l_rec_voucherdist.dist_amt, 
						l_rec_jobledger.charge_amt 
						TO voucherdist.dist_amt, 
						jobledger.charge_amt 

					END IF 
				END IF 
			END IF 

		BEFORE FIELD job_code 
			LET l_temp2_text = l_rec_voucherdist.job_code 

		BEFORE FIELD var_code 
			IF l_rec_voucherdist.job_code IS NULL THEN 
				LET l_msgresp=kandoomsg("P",9035,"") 
				#P9035 " Job code must be entered
				NEXT FIELD job_code 
			ELSE 
				SELECT * INTO l_rec_job.* 
				FROM job 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_voucherdist.job_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9030,"") 
					#P9030 " Job NOT found - try window"
					NEXT FIELD job_code 
				ELSE 
					DISPLAY l_rec_job.title_text TO job.title_text 

					LET l_rec_voucherdist.acct_code = 
					build_mask(p_cmpy,l_rec_voucherdist.acct_code, 
					l_rec_job.wip_acct_code) 
					DISPLAY BY NAME l_rec_voucherdist.acct_code 

					IF l_temp2_text != l_rec_voucherdist.job_code 
					OR l_temp2_text IS NULL THEN 
						CALL verify_acct_code(p_cmpy,l_rec_voucherdist.acct_code, 
						glob_rec_voucher.year_num, 
						glob_rec_voucher.period_num) 
						RETURNING l_rec_coa.* 
						IF l_rec_coa.acct_code IS NULL THEN 
							NEXT FIELD job_code 
						ELSE 
							LET l_rec_voucherdist.acct_code = l_rec_coa.acct_code 
						END IF 
					END IF 
				END IF 
			END IF 

		AFTER FIELD var_code 
			CLEAR jobvars.title_text 
			IF l_rec_voucherdist.var_code IS NULL THEN 
				LET l_rec_voucherdist.var_code = 0 
			END IF 
			IF l_rec_voucherdist.var_code > 0 THEN 
				SELECT title_text INTO l_rec_jobvars.title_text 
				FROM jobvars 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_voucherdist.job_code 
				AND var_code = l_rec_voucherdist.var_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9032,"") 
					#P9032 "Invalid Variation Code"
					LET l_rec_voucherdist.var_code = NULL 
					CLEAR var_code 
					NEXT FIELD job_code 
				ELSE 
					DISPLAY l_rec_jobvars.title_text TO jobvars.title_text 

				END IF 
			END IF 
		BEFORE FIELD desc_text 
			IF l_rec_voucherdist.act_code IS NULL THEN 
				LET l_msgresp=kandoomsg("P",9036,"") 
				#P9035 Activity Code must be entered"
				NEXT FIELD act_code 
			ELSE 
				SELECT * INTO l_rec_activity.* 
				FROM activity 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_voucherdist.job_code 
				AND var_code = l_rec_voucherdist.var_code 
				AND activity_code = l_rec_voucherdist.act_code 
				CASE 
					WHEN status = NOTFOUND 
						LET l_msgresp=kandoomsg("P",9031,"") 
						#P9031 Activity Code NOT found - try window
						NEXT FIELD job_code 
					WHEN l_rec_activity.finish_flag = "Y" 
						LET l_msgresp=kandoomsg("P",9033,"") 
						#P9033 Activity IS complete no transaction entry
						LET l_rec_voucherdist.act_code = NULL 
						NEXT FIELD job_code 
					WHEN l_rec_activity.acct_code IS NULL 
						LET l_msgresp=kandoomsg("P",9037,"") 
						#P9037 Invalid activity FOR transaction entry
						NEXT FIELD job_code 
				END CASE 
				DISPLAY l_rec_activity.title_text TO activity.title_text 

			END IF 

		BEFORE FIELD trans_qty 
			LET l_save_amt = l_rec_voucherdist.dist_amt 

		AFTER FIELD trans_qty 
			IF l_rec_voucherdist.trans_qty IS NULL THEN 
				LET l_rec_voucherdist.trans_qty = 0 
				NEXT FIELD trans_qty 
			END IF 
			LET l_rec_voucherdist.dist_amt = l_rec_voucherdist.trans_qty 
			* l_rec_voucherdist.cost_amt 
			LET l_rec_jobledger.charge_amt = l_rec_voucherdist.trans_qty 
			* l_rec_voucherdist.charge_amt 
			LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
			- l_save_amt 
			+ l_rec_voucherdist.dist_amt 
			DISPLAY l_rec_voucherdist.trans_qty, 
			l_rec_voucherdist.dist_amt, 
			l_rec_jobledger.charge_amt, 
			glob_rec_voucher.dist_amt 
			TO voucherdist.trans_qty, 
			voucherdist.dist_amt, 
			jobledger.charge_amt, 
			voucher.dist_amt 

		BEFORE FIELD cost_amt 
			IF l_rec_jmresource.cost_ind = "2" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			ELSE 
				IF glob_rec_voucher.dist_amt > glob_rec_voucher.total_amt THEN 
					LET l_msgresp=kandoomsg("P",9015,"") 
					#P9015 Warning: This entry will over distribute the voucher"
				END IF 
				LET l_save_amt = l_rec_voucherdist.dist_amt 
			END IF 

		AFTER FIELD cost_amt 
			IF l_rec_voucherdist.cost_amt IS NULL THEN 
				LET l_rec_voucherdist.cost_amt = 0 
				NEXT FIELD cost_amt 
			ELSE 
				IF l_rec_voucherdist.cost_amt < 0 THEN 
					LET l_msgresp = kandoomsg("U",9927,"0") 
					# Must Enter value greater than zero
					NEXT FIELD cost_amt 
				END IF 
				LET l_rec_voucherdist.dist_amt = l_rec_voucherdist.trans_qty 
				* l_rec_voucherdist.cost_amt 
				LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
				- l_save_amt 
				+ l_rec_voucherdist.dist_amt 
			END IF 
			DISPLAY l_rec_voucherdist.dist_amt, 
			glob_rec_voucher.dist_amt 
			TO voucherdist.dist_amt, 
			voucher.dist_amt 

		BEFORE FIELD dist_amt 
			LET l_save_amt = l_rec_voucherdist.dist_amt 
			IF glob_rec_voucher.dist_amt > glob_rec_voucher.total_amt THEN 
				LET l_msgresp=kandoomsg("P",9015,"") 
				#P9015 Warning: This entry will over distribute the voucher"
			END IF 

		AFTER FIELD dist_amt 
			IF l_rec_voucherdist.cost_amt IS NULL THEN 
				LET l_rec_voucherdist.cost_amt = 0 
			ELSE 
				IF l_rec_jmresource.cost_ind = "1" THEN 
					IF l_rec_voucherdist.trans_qty > 0 THEN 
						LET l_rec_voucherdist.cost_amt = l_rec_voucherdist.dist_amt 
						/ l_rec_voucherdist.trans_qty 
					ELSE 
						LET l_rec_voucherdist.trans_qty = 1 
						LET l_rec_voucherdist.cost_amt = l_rec_voucherdist.dist_amt 
					END IF 
				ELSE 
					IF l_rec_voucherdist.cost_amt > 0 THEN 
						LET l_rec_voucherdist.trans_qty = l_rec_voucherdist.dist_amt 
						/ l_rec_voucherdist.cost_amt 
					END IF 
				END IF 
			END IF 
			LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
			- l_save_amt 
			+ l_rec_voucherdist.dist_amt 
			DISPLAY l_rec_voucherdist.trans_qty, 
			l_rec_voucherdist.cost_amt, 
			l_rec_voucherdist.dist_amt, 
			l_rec_jobledger.charge_amt, 
			glob_rec_voucher.dist_amt 
			TO voucherdist.trans_qty, 
			voucherdist.cost_amt, 
			voucherdist.dist_amt, 
			jobledger.charge_amt, 
			voucher.dist_amt 

		BEFORE FIELD charge_amt 
			IF l_rec_jmresource.bill_ind = "2" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD charge_amt 
			IF l_rec_voucherdist.charge_amt IS NULL THEN 
				LET l_rec_voucherdist.charge_amt = 0 
				NEXT FIELD charge_amt 
			ELSE 
				IF l_rec_voucherdist.charge_amt < 0 THEN 
					LET l_msgresp = kandoomsg("U",9927,"0") 
					# Must Enter value greater than zero
					NEXT FIELD charge_amt 
				END IF 
				LET l_rec_jobledger.charge_amt = l_rec_voucherdist.trans_qty 
				* l_rec_voucherdist.charge_amt 
			END IF 
			DISPLAY l_rec_jobledger.charge_amt TO jobledger.charge_amt 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT * FROM jmresource 
				WHERE cmpy_code = p_cmpy 
				AND res_code = l_rec_voucherdist.res_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9029,"") 
					#P9029 " Resource code does NOT exist - Try Window"
					NEXT FIELD res_code 
				END IF 
				SELECT * FROM job 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_voucherdist.job_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9030,"") 
					#P9030 " Job code does NOT exist - Try Window"
					NEXT FIELD job_code 
				END IF 
				IF l_rec_voucherdist.var_code > 0 THEN 
					SELECT * FROM jobvars 
					WHERE cmpy_code = p_cmpy 
					AND job_code = l_rec_voucherdist.job_code 
					AND var_code = l_rec_voucherdist.var_code 
					IF status = NOTFOUND THEN 
						LET l_msgresp=kandoomsg("P",9032,"") 
						#P9032 " Job code does NOT exist - Try Window"
						NEXT FIELD var_code 
					END IF 
				END IF 
				SELECT * FROM activity 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_voucherdist.job_code 
				AND var_code = l_rec_voucherdist.var_code 
				AND activity_code = l_rec_voucherdist.act_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9031,"") 
					#P9031 " Job code does NOT exist - Try Window"
					NEXT FIELD act_code 
				END IF 
				IF glob_rec_voucher.dist_amt > glob_rec_voucher.total_amt THEN 
					LET l_msgresp=kandoomsg("P",9015,"") 
					#P9015 Warning: This entry will over distribute the voucher"
				END IF 
				CALL verify_acct_code(p_cmpy, 
				l_rec_voucherdist.acct_code, 
				glob_rec_voucher.year_num, 
				glob_rec_voucher.period_num) 
				RETURNING l_rec_coa.* 
				IF l_rec_coa.acct_code IS NULL THEN 
					NEXT FIELD res_code 
				ELSE 
					LET l_rec_voucherdist.acct_code = l_rec_coa.acct_code 
					DISPLAY BY NAME l_rec_voucherdist.acct_code 

				END IF 
			END IF 

	END INPUT 
	----------

	CLOSE WINDOW j148 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN p_rowid 
	ELSE 
		IF p_rowid = 0 THEN 
			SELECT max(line_num) INTO glob_rec_voucher.line_num 
			FROM t_jmdist 
			IF glob_rec_voucher.line_num IS NULL THEN 
				LET l_rec_voucherdist.line_num = 1 
			ELSE 
				LET l_rec_voucherdist.line_num = glob_rec_voucher.line_num + 1 
			END IF 
			LET l_rec_voucherdist.cmpy_code = glob_rec_voucher.cmpy_code 
			LET l_rec_voucherdist.vend_code = glob_rec_voucher.vend_code 
			LET l_rec_voucherdist.vouch_code = glob_rec_voucher.vouch_code 
			LET l_rec_voucherdist.type_ind = "J" 
			INSERT INTO t_jmdist VALUES (l_rec_voucherdist.*) 
			RETURN sqlca.sqlerrd[6] 
		ELSE 
			UPDATE t_jmdist 
			SET res_code = l_rec_voucherdist.res_code, 
			job_code = l_rec_voucherdist.job_code, 
			var_code = l_rec_voucherdist.var_code, 
			act_code = l_rec_voucherdist.act_code, 
			acct_code = l_rec_voucherdist.acct_code, 
			trans_qty = l_rec_voucherdist.trans_qty, 
			cost_amt = l_rec_voucherdist.cost_amt, 
			dist_amt = l_rec_voucherdist.dist_amt, 
			charge_amt = l_rec_voucherdist.charge_amt, 
			desc_text = l_rec_voucherdist.desc_text, 
			allocation_ind = l_rec_voucherdist.allocation_ind 
			WHERE rowid = p_rowid 
			RETURN p_rowid 
		END IF 
	END IF 

END FUNCTION 
