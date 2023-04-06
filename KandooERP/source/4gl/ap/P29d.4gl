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
# P29d.4gl - P29d allows vouchers TO be distributed TO debtors
#
# \brief module has two levels of commit/discard.  PO lines are
#            added TO t_ardist,  on acceptance they are committed TO
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
# FUNCTION cr_ar_dist(p_cmpy,p_kandoouser_sign_on_code)
#
#
############################################################
FUNCTION cr_ar_dist(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicehead2 RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_arr_rowid array[200] OF INTEGER 
	DEFINE l_arr_rec_dist array[200] OF 
	RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		sup_inv_num LIKE voucher.inv_text, 
		dist_amt LIKE voucherdist.dist_amt 
	END RECORD 
	DEFINE l_rowid,l_rowid2 INTEGER 
	DEFINE l_inv_total_amt LIKE invoicehead.total_amt 
	DEFINE l_goods_amt LIKE invoicehead.total_amt 
	DEFINE l_ref_text LIKE arparms.inv_ref1_text 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT 
	DEFINE i SMALLINT 


	SELECT inv_ref1_text INTO l_ref_text FROM arparms 
	WHERE cmpy_code = p_cmpy 
	IF status = NOTFOUND THEN 
		LET l_ref_text = "Reference" 
	END IF 
	OPEN WINDOW p226 at 2,3 with FORM "P226" 
	CALL windecoration_p("P226") 

	LET l_msgresp=kandoomsg("P",1002,"") 
	#1002 Searching database pls wait
	DISPLAY BY NAME glob_rec_voucher.vend_code, 
	glob_rec_vendor.name_text, 
	glob_rec_voucher.vouch_code, 
	glob_rec_voucher.total_amt, 
	glob_rec_voucher.dist_amt, 
	l_ref_text 

	DISPLAY BY NAME glob_rec_voucher.currency_code 
	attribute(green) 
	### Informix bug workaround
	WHENEVER ERROR CONTINUE 
	SELECT * FROM t_voucherdist WHERE rowid = 0 INTO temp t_ardist with no LOG 
	IF sqlca.sqlcode < 0 THEN 
		DELETE FROM t_ardist 
	END IF 
	INSERT INTO t_ardist SELECT * FROM t_voucherdist 
	WHENEVER ERROR stop 
	DECLARE c_voucherdist CURSOR FOR 
	SELECT rowid, * FROM t_ardist 
	WHERE type_ind = "A" 
	ORDER BY line_num 
	LET idx = 0 
	FOREACH c_voucherdist INTO l_rowid, 
		l_rec_voucherdist.* 
		IF l_rec_voucherdist.res_code IS NULL THEN 
			DELETE FROM t_ardist 
			WHERE rowid = l_rowid 
			CONTINUE FOREACH 
		END IF 
		LET idx = idx + 1 
		LET l_arr_rowid[idx] = l_rowid 
		SELECT name_text INTO l_rec_customer.name_text FROM customer 
		WHERE cust_code = l_rec_voucherdist.res_code 
		AND cmpy_code = p_cmpy 
		IF status = 0 THEN 
			LET l_arr_rec_dist[idx].name_text = l_rec_customer.name_text 
		ELSE 
			LET l_arr_rec_dist[idx].name_text = "" 
		END IF 
		LET l_arr_rec_dist[idx].cust_code = l_rec_voucherdist.res_code 
		LET l_arr_rec_dist[idx].dist_amt = l_rec_voucherdist.dist_amt 
		LET l_arr_rec_dist[idx].sup_inv_num = l_rec_voucherdist.analysis_text 
		IF idx = 200 THEN 
			LET l_msgresp=kandoomsg("P",9042,idx) 
			#P9042 First idx entries selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 
--	IF idx = 0 THEN 
--		LET idx = 1 
--		INITIALIZE l_arr_rec_dist[1].* TO NULL 
--	END IF 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f1 
	LET l_msgresp=kandoomsg("P",1068,"") 
	#1068 "Charge Thru Expenses - F1 Add - F2 Delete - RETURN TO Edit"
	CALL set_count(idx) 

	INPUT ARRAY l_arr_rec_dist WITHOUT DEFAULTS FROM sr_invoicehead.* attributes(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P29d","inp-arr-ardist-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			IF l_arr_rec_dist[idx].cust_code IS NOT NULL THEN 
				#            DISPLAY l_arr_rec_dist[idx].* TO sr_invoicehead[scrn].*

				SELECT * INTO l_rec_voucherdist.* FROM t_ardist 
				WHERE rowid = l_arr_rowid[idx] 
				IF status = 0 THEN 
					SELECT * INTO l_rec_customer.* FROM customer 
					WHERE cmpy_code = p_cmpy 
					AND cust_code = l_arr_rec_dist[idx].cust_code 
					IF status = NOTFOUND THEN 
						LET l_rec_customer.name_text = "********" 
					END IF 
					LET l_inv_total_amt = l_rec_voucherdist.dist_amt + 
					l_rec_voucherdist.cost_amt + 
					l_rec_voucherdist.charge_amt 
					CALL assign_inv(p_cmpy,l_rec_voucherdist.*) RETURNING l_rec_invoicehead.* 
					LET l_goods_amt = l_rec_invoicehead.goods_amt 
					DISPLAY BY NAME l_rec_invoicehead.inv_date, 
					l_rec_invoicehead.inv_num, 
					l_rec_invoicehead.tax_code, 
					l_rec_invoicehead.term_code, 
					l_rec_invoicehead.com1_text, 
					l_goods_amt, 
					l_rec_invoicehead.hand_amt, 
					l_rec_invoicehead.tax_amt, 
					l_inv_total_amt 

				END IF 
			END IF 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("P",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD scroll_flag 
				ELSE 
					IF l_arr_rec_dist[idx+1].cust_code IS NULL THEN 
						LET l_msgresp=kandoomsg("P",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD cust_code 
			LET l_rowid = l_arr_rowid[idx] 
			INITIALIZE l_rec_voucherdist.* TO NULL 
			SELECT * INTO l_rec_voucherdist.* FROM t_ardist 
			WHERE rowid = l_arr_rowid[idx] 
			IF status = 0 THEN 
				INITIALIZE l_rec_invoicehead2.* TO NULL
				
				IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,l_rec_voucherdist.po_num) THEN
					CALL db_invoicehead_get_rec(UI_ON,l_rec_voucherdist.po_num ) RETURNING  l_rec_invoicehead2.*

					IF l_rec_invoicehead2.posted_flag IS NOT NULL	AND l_rec_invoicehead2.posted_flag = "Y" THEN 
						LET l_msgresp=kandoomsg("P",9067,"") #P9067 This distribution has been posted TO the GL.
						NEXT FIELD scroll_flag 
					END IF 
					IF l_rec_invoicehead2.paid_amt > 0 THEN 
						LET l_msgresp=kandoomsg("P",9068,"") #P9068 Expense distribution has been paid by debtor
						NEXT FIELD scroll_flag 
					END IF 
					
				ELSE
				
				END IF
				
				IF status = 0 THEN 
				END IF 
			END IF 

			LET l_arr_rowid[idx] = enter_trans_detl(p_cmpy,l_rowid) 
			SELECT * INTO l_rec_voucherdist.* FROM t_ardist 
			WHERE rowid = l_arr_rowid[idx] 
			IF status = NOTFOUND THEN 
				FOR i = idx TO arr_count() 
					LET l_arr_rowid[i] = l_arr_rowid[i+1] 
					LET l_arr_rec_dist[i].* = l_arr_rec_dist[i+1].* 
					#               IF scrn <= 6 THEN
					#                  DISPLAY l_arr_rec_dist[i].*
					#                       TO sr_invoicehead[scrn].*
					#
					#                  LET scrn = scrn + 1
					#               END IF
				END FOR 
				LET l_arr_rowid[i] = 0 
				INITIALIZE l_arr_rec_dist[i].* TO NULL 
			ELSE 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = l_rec_voucherdist.res_code 
				LET l_arr_rec_dist[idx].cust_code = l_rec_voucherdist.res_code 
				LET l_arr_rec_dist[idx].name_text = l_rec_customer.name_text 
				LET l_arr_rec_dist[idx].sup_inv_num = l_rec_voucherdist.analysis_text 
				LET l_arr_rec_dist[idx].dist_amt = l_rec_voucherdist.dist_amt 
			END IF 
			LET l_inv_total_amt = l_rec_voucherdist.dist_amt + 
			l_rec_voucherdist.cost_amt + 
			l_rec_voucherdist.charge_amt 
			CALL assign_inv(p_cmpy,l_rec_voucherdist.*) RETURNING l_rec_invoicehead.* 
			DISPLAY BY NAME l_rec_invoicehead.inv_date, 
			l_rec_invoicehead.tax_code, 
			l_rec_invoicehead.term_code 

			DISPLAY l_rec_voucherdist.desc_text TO invoicehead.com1_text 

			SELECT sum(dist_amt) INTO glob_rec_voucher.dist_amt FROM t_ardist 
			DISPLAY BY NAME glob_rec_voucher.dist_amt,glob_rec_voucher.total_amt 

			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			FOR i = arr_count() TO idx step -1 
				LET l_arr_rowid[i+1] = l_arr_rowid[i] 
			END FOR 
			INITIALIZE l_arr_rec_dist[idx].* TO NULL 
			#         CLEAR sr_invoicehead[scrn].*
			LET l_arr_rowid[idx] = 0 
			NEXT FIELD cust_code 

		ON KEY (F2) 
			INITIALIZE l_rec_invoicehead2.* TO NULL
			
			
			IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,l_rec_voucherdist.po_num) THEN
				CALL db_invoicehead_get_rec(UI_ON,l_rec_voucherdist.po_num ) RETURNING  l_rec_invoicehead2.*
				IF l_rec_invoicehead2.posted_flag IS NOT NULL 
				AND l_rec_invoicehead2.posted_flag = "Y" THEN 
					
					LET l_msgresp=kandoomsg("P",9067,"") #P9067 This distribution has been posted TO the GL.
					NEXT FIELD scroll_flag 
				END IF 
				IF l_rec_invoicehead2.paid_amt > 0 THEN 
					
					LET l_msgresp=kandoomsg("P",9068,"")  
					NEXT FIELD scroll_flag 
				END IF 
			END IF					 

			DELETE FROM t_ardist 
			WHERE rowid = l_arr_rowid[idx] 
			SELECT sum(dist_amt) INTO glob_rec_voucher.dist_amt FROM t_ardist 
			DISPLAY BY NAME glob_rec_voucher.dist_amt,glob_rec_voucher.total_amt 

			FOR i = idx TO arr_count() 
				LET l_arr_rowid[i] = l_arr_rowid[i+1] 
				LET l_arr_rec_dist[i].* = l_arr_rec_dist[i+1].* 
				#            IF scrn <= 6 THEN
				#               DISPLAY l_arr_rec_dist[i].* TO sr_invoicehead[scrn].*
				#
				#               LET scrn = scrn + 1
				#            END IF
			END FOR 
			LET l_arr_rowid[i] = 0 
			INITIALIZE l_arr_rec_dist[i].* TO NULL 
			NEXT FIELD scroll_flag 

			#      AFTER ROW
			#         DISPLAY l_arr_rec_dist[idx].* TO sr_invoicehead[scrn].*


	END INPUT 
	---------

	CLOSE WINDOW p226 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_msgresp=kandoomsg("P",1005,"") 
		#1005 Searching database pls wait
		DELETE FROM t_voucherdist 
		INSERT INTO t_voucherdist SELECT * FROM t_ardist 
	END IF 
END FUNCTION 



############################################################
# FUNCTION enter_trans_detl(p_cmpy,p_rowid)
#
#
############################################################
FUNCTION enter_trans_detl(p_cmpy,p_rowid) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rowid INTEGER 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_mode SMALLINT # 0 = add, 1 = edit 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_save_code LIKE customer.cust_code 
	DEFINE l_save_date LIKE invoicehead.inv_date 
	DEFINE l_inv_ref1_text CHAR(17) 
	DEFINE l_failed_it SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	#get Account Receivable Parameters Record
	CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.* 
	IF l_rec_arparms.parm_code IS NULL THEN #(status = NOTFOUND) 
		LET l_inv_ref1_text = "Reference........" 
	ELSE 
		LET l_inv_ref1_text = l_rec_arparms.inv_ref1_text clipped, "................." 
	END IF 
	
	LET l_mode = 1
	 
	INITIALIZE l_rec_voucherdist.* TO NULL 
	SELECT * INTO l_rec_voucherdist.* FROM t_ardist 
	WHERE rowid = p_rowid 
	IF status = NOTFOUND THEN 
		LET l_mode = 0 
		INITIALIZE l_rec_invoicehead.* TO NULL 
		INITIALIZE l_rec_invoicedetl.* TO NULL 
		LET l_rec_invoicehead.inv_date = today 
		LET l_rec_invoicehead.com1_text = glob_rec_vendor.name_text 
		LET l_rec_invoicehead.purchase_code = glob_rec_voucher.inv_text 
		LET l_rec_invoicehead.goods_amt = 0 
		LET l_rec_invoicehead.freight_amt = 0 
		LET l_rec_invoicehead.hand_amt = 0 
		LET l_rec_invoicehead.tax_amt = 0 
		LET l_rec_invoicehead.paid_amt = 0 
		LET l_rec_invoicehead.inv_num = 0 
	ELSE 
		CALL assign_inv(p_cmpy,l_rec_voucherdist.*) RETURNING l_rec_invoicehead.* 
	END IF 
	CALL db_period_what_period(p_cmpy,l_rec_invoicehead.inv_date) 
	RETURNING l_rec_invoicehead.year_num, 
	l_rec_invoicehead.period_num 

	OPEN WINDOW p227 with FORM "P227" 
	CALL windecoration_p("P227") 

	CLEAR FORM 

	DISPLAY BY NAME l_inv_ref1_text 
	LET l_msgresp=kandoomsg("A",1082,"") 
	#A1082 Enter Adjustment Details - ESC TO Continue
	INPUT BY NAME l_rec_invoicehead.cust_code, 
	l_rec_invoicehead.inv_date, 
	l_rec_invoicehead.com1_text, 
	l_rec_invoicehead.purchase_code, 
	l_rec_invoicehead.currency_code, 
	l_rec_invoicehead.goods_amt, 
	l_rec_invoicehead.hand_amt, 
	l_rec_invoicehead.tax_amt, 
	l_rec_invoicehead.total_amt WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P29d","inp-invoicehead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (cust_code) 
			LET l_rec_invoicehead.cust_code = show_clnt(p_cmpy) 
			NEXT FIELD cust_code 

		BEFORE FIELD cust_code 
			LET l_save_code = l_rec_invoicehead.cust_code 

		AFTER FIELD cust_code 
			CASE 
				WHEN l_rec_invoicehead.cust_code IS NULL 
					LET l_rec_invoicehead.cust_code = l_save_code 
					ERROR "Customer NOT found - Try Window" 
					NEXT FIELD cust_code 
				WHEN (l_rec_invoicehead.cust_code = l_save_code 
					AND l_save_code IS NOT null) 
					SELECT name_text,currency_code 
					INTO l_rec_invoicehead.name_text,l_rec_customer.currency_code 
					FROM customer 
					WHERE cmpy_code = p_cmpy 
					AND cust_code = l_rec_invoicehead.cust_code 
					DISPLAY BY NAME l_rec_invoicehead.name_text 

					DISPLAY BY NAME l_rec_customer.currency_code 
					attribute(green) 
				OTHERWISE 
					IF l_rec_invoicehead.inv_num > 0 
					AND l_rec_invoicehead.cust_code != l_save_code THEN 
						LET l_msgresp = kandoomsg("P",9132,"") 
						#9132 "Customer cannot change -
						#      invoice created FOR this distribution"
						LET l_rec_invoicehead.cust_code = l_save_code 
						NEXT FIELD cust_code 
					END IF 
					SELECT * INTO l_rec_customer.* FROM customer 
					WHERE cmpy_code = p_cmpy 
					AND cust_code = l_rec_invoicehead.cust_code 
					IF status = NOTFOUND THEN 
						ERROR "Customer NOT found - Try Window" 
						LET l_rec_invoicehead.cust_code = NULL 
						NEXT FIELD cust_code 
					END IF 
					IF l_rec_customer.delete_flag = "Y" THEN 
						LET l_msgresp = kandoomsg("P",9069,"") 
						#9069 "Customer has been marked FOR deletion"
						LET l_rec_invoicehead.cust_code = NULL 
						NEXT FIELD cust_code 
					END IF 
					IF l_rec_customer.hold_code IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("P",9070,"") 
						#9070 Customer IS on hold - Release before proceeding
						LET l_rec_invoicehead.cust_code = NULL 
						NEXT FIELD cust_code 
					END IF 
					IF l_rec_customer.currency_code != glob_rec_vendor.currency_code THEN 
						LET l_msgresp = kandoomsg("P",9071,"") 
						#9071 Customer currency code must be the same as the vendors
						LET l_rec_invoicehead.cust_code = NULL 
						NEXT FIELD cust_code 
					END IF 
					LET l_rec_invoicehead.cmpy_code = p_cmpy 
					LET l_rec_invoicehead.sale_code = l_rec_customer.sale_code 
					LET l_rec_invoicehead.term_code = l_rec_customer.term_code 
					LET l_rec_invoicehead.tax_code = l_rec_customer.tax_code 
					DISPLAY BY NAME l_rec_invoicehead.name_text 

					DISPLAY l_rec_customer.name_text 
					TO invoicehead.name_text 

					DISPLAY BY NAME l_rec_customer.currency_code 
					attribute(green) 
			END CASE 

		BEFORE FIELD inv_date 
			LET l_save_date = l_rec_invoicehead.inv_date 

		AFTER FIELD inv_date 
			CASE 
				WHEN l_rec_invoicehead.inv_date IS NULL 
					LET l_rec_invoicehead.inv_date = today 
					NEXT FIELD inv_date 
				WHEN l_rec_invoicehead.inv_date != l_save_date 
					CALL db_period_what_period(p_cmpy, l_rec_invoicehead.inv_date) 
					RETURNING l_rec_invoicehead.year_num, 
					l_rec_invoicehead.period_num 
			END CASE 

		AFTER FIELD goods_amt 
			IF l_rec_invoicehead.goods_amt IS NULL 
			OR l_rec_invoicehead.goods_amt < 0 THEN 
				LET l_rec_invoicehead.goods_amt = 0 
				NEXT FIELD goods_amt 
			ELSE 
				LET l_rec_invoicehead.total_amt = l_rec_invoicehead.goods_amt 
				+ l_rec_invoicehead.hand_amt 
				+ l_rec_invoicehead.tax_amt 
				DISPLAY BY NAME l_rec_invoicehead.total_amt 

			END IF 

		AFTER FIELD hand_amt 
			IF l_rec_invoicehead.hand_amt IS NULL OR l_rec_invoicehead.hand_amt < 0 THEN 
				LET l_rec_invoicehead.hand_amt = 0 
				NEXT FIELD hand_amt 
			ELSE 
				LET l_rec_invoicehead.total_amt = l_rec_invoicehead.goods_amt 
				+ l_rec_invoicehead.hand_amt 
				+ l_rec_invoicehead.tax_amt 
				DISPLAY BY NAME l_rec_invoicehead.total_amt 

			END IF 

		AFTER FIELD tax_amt 
			IF l_rec_invoicehead.tax_amt IS NULL OR l_rec_invoicehead.tax_amt < 0 THEN 
				LET l_rec_invoicehead.tax_amt = 0 
				NEXT FIELD tax_amt 
			ELSE 
				LET l_rec_invoicehead.total_amt = l_rec_invoicehead.goods_amt 
				+ l_rec_invoicehead.hand_amt 
				+ l_rec_invoicehead.tax_amt 
				DISPLAY BY NAME l_rec_invoicehead.total_amt 

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_invoicehead.tax_amt IS NULL THEN 
					LET l_rec_invoicehead.tax_amt = 0 
				END IF 
				IF l_rec_invoicehead.goods_amt IS NULL THEN 
					LET l_rec_invoicehead.goods_amt = 0 
				END IF 
				IF (l_rec_invoicehead.goods_amt > 0 AND l_rec_invoicehead.tax_amt < 0) 
				OR (l_rec_invoicehead.goods_amt < 0 
				AND l_rec_invoicehead.tax_amt > 0) THEN 
					error" Adjustment AND tax amounts must be of the same sign " 
					NEXT FIELD goods_amt 
				END IF 
				IF l_rec_invoicehead.inv_date IS NULL THEN 
					LET l_rec_invoicehead.inv_date = today 
					NEXT FIELD inv_date 
				END IF 
				IF l_rec_invoicehead.total_amt = 0 THEN 
					IF kandoomsg("A",8031,"") != "Y" THEN 
						CONTINUE INPUT 
					END IF 
				END IF 
			END IF 

	END INPUT 
	---------

	CLOSE WINDOW p227 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN p_rowid 
	ELSE 
		IF l_mode = 1 THEN # edit 
			DELETE FROM t_ardist WHERE rowid = pr_rowid 
		END IF 

		LET l_rec_voucherdist.cmpy_code = p_cmpy 
		LET l_rec_voucherdist.res_code = l_rec_invoicehead.cust_code 
		LET l_rec_voucherdist.acct_code = glob_rec_vendor.usual_acct_code 
		LET l_rec_voucherdist.analysis_text = l_rec_invoicehead.purchase_code 
		LET l_rec_voucherdist.desc_text = l_rec_invoicehead.com1_text 
		LET l_rec_voucherdist.po_num = l_rec_invoicehead.inv_num 
		LET l_rec_voucherdist.type_ind = "A" 
		LET l_rec_voucherdist.dist_amt = l_rec_invoicehead.goods_amt 
		LET l_rec_voucherdist.job_code = l_rec_invoicehead.inv_date USING "ddmmyyyy" 
		LET l_rec_voucherdist.cost_amt = l_rec_invoicehead.tax_amt 
		LET l_rec_voucherdist.charge_amt = l_rec_invoicehead.hand_amt 
		LET l_rec_voucherdist.trans_qty = 1 
		SELECT max(line_num) INTO glob_rec_voucher.line_num FROM t_ardist 

		IF glob_rec_voucher.line_num IS NULL THEN 
			LET l_rec_voucherdist.line_num = 1 
		ELSE 
			LET l_rec_voucherdist.line_num = glob_rec_voucher.line_num + 1 
		END IF 

		INSERT INTO t_ardist VALUES (l_rec_voucherdist.*) 
		RETURN sqlca.sqlerrd[6] 
	END IF 

END FUNCTION 


############################################################
# FUNCTION assign_inv(p_cmpy,p_rec_voucherdist)
#
#
############################################################
FUNCTION assign_inv(p_cmpy,p_rec_voucherdist) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_rec_voucherdist.res_code 
	LET l_rec_invoicehead.cust_code = p_rec_voucherdist.res_code 
	LET l_rec_invoicehead.purchase_code = p_rec_voucherdist.analysis_text 
	LET l_rec_invoicehead.inv_num = p_rec_voucherdist.po_num 
	LET l_rec_invoicehead.total_amt = p_rec_voucherdist.dist_amt + 
	p_rec_voucherdist.cost_amt + 
	p_rec_voucherdist.charge_amt 
	LET l_rec_invoicehead.inv_date = p_rec_voucherdist.job_code 
	LET l_rec_invoicehead.year_num = glob_rec_voucher.year_num 
	LET l_rec_invoicehead.period_num = glob_rec_voucher.period_num 
	LET l_rec_invoicehead.tax_code = l_rec_customer.tax_code 
	LET l_rec_invoicehead.term_code = l_rec_customer.term_code 
	LET l_rec_invoicehead.com1_text = p_rec_voucherdist.desc_text 
	LET l_rec_invoicehead.goods_amt = p_rec_voucherdist.dist_amt 
	LET l_rec_invoicehead.hand_amt = p_rec_voucherdist.charge_amt 
	LET l_rec_invoicehead.tax_amt = p_rec_voucherdist.cost_amt 

	RETURN l_rec_invoicehead.* 
END FUNCTION 
