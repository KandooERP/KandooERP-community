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

	Source code beautified by beautify.pl on 2020-01-03 13:41:20	$Id: $
}


#
# P29b.4gl - creates purchase ORDER payment TO temp table t_podist.
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module has two levels of commit/discard.  PO lines are
#            added TO t_podist,  on acceptance they are committed TO
#            t_voucherdist.  WHEN ARRAY in P29a IS accepted THEN all
#            lines are committed TO database
#
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
DEFINE modu_rec_puparms RECORD LIKE puparms.* 

############################################################
# FUNCTION cr_po_dist(p_cmpy,p_kandoouser_sign_on_code)
#
#
############################################################
FUNCTION cr_po_dist(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_arr_rec_purchhead ARRAY[300] OF 
	RECORD 
		scroll_flag CHAR(1), 
		order_num LIKE purchdetl.order_num, 
		order_amt LIKE voucher.dist_amt, 
		received_amt LIKE voucher.dist_amt, 
		paid_amt LIKE voucher.dist_amt, 
		remain_amt LIKE voucher.dist_amt, 
		voucher_amt LIKE voucher.dist_amt 
	END RECORD 
	DEFINE l_rec_podist RECORD LIKE voucherdist.* 
	DEFINE l_poexist SMALLINT 
	DEFINE l_sel_text CHAR(2200) 
	DEFINE l_where_po CHAR(2048) 
	DEFINE l_where2_po CHAR(2048) 
	DEFINE l_mast_vend_code LIKE vendorgrp.mast_vend_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx,scrn SMALLINT
	DEFINE i,j,pr_po,pr_tpo SMALLINT

	SELECT * INTO modu_rec_puparms.* FROM puparms 
	WHERE cmpy_code = glob_rec_voucher.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",5018,"") 
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW r144 with FORM "R144" 
	CALL winDecoration_r("R144") 

	LET l_msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	DISPLAY BY NAME glob_rec_voucher.vend_code, 
	glob_rec_vendor.name_text, 
	glob_rec_voucher.vouch_code, 
	glob_rec_voucher.total_amt, 
	glob_rec_voucher.dist_amt 

	DISPLAY BY NAME glob_rec_voucher.currency_code 
	attribute(green) 
	### please wait MESSAGE
	### Informix bug workaround
	WHENEVER ERROR CONTINUE 
	SELECT * FROM t_voucherdist WHERE rowid = 0 INTO temp t_podist with no LOG 
	IF sqlca.sqlcode < 0 THEN 
		DELETE FROM t_podist 
	END IF 
	INSERT INTO t_podist SELECT * FROM t_voucherdist WHERE dist_amt <> 0 
	AND dist_amt IS NOT NULL 
	WHENEVER ERROR stop 
	LET pr_tpo = true 
	# add construct
	CONSTRUCT BY NAME l_where_po ON purchhead.order_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P29b","construct-order_num-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW r144 
		RETURN 
	END IF 
	LET j = length(l_where_po) 
	IF j > 10 THEN 
		LET pr_po = true 
	END IF 
	SELECT unique 1 FROM t_podist 
	WHERE cmpy_code = p_cmpy 
	IF status = NOTFOUND THEN 
		LET pr_tpo = false 
	END IF 
	SELECT distinct mast_vend_code INTO l_mast_vend_code FROM vendorgrp 
	WHERE mast_vend_code = glob_rec_voucher.vend_code 
	AND cmpy_code = p_cmpy 
	IF status = 0 THEN 
		LET l_where2_po = " OR vend_code in(SELECT vend_code FROM vendorgrp ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		" AND mast_vend_code = ", 
		" '",l_mast_vend_code,"') " 
	END IF 
	IF pr_po THEN ### ORDER number used in CONSTRUCT 
		LET l_sel_text = "SELECT * FROM purchhead ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		" AND ", l_where_po clipped, " ", 
		"AND (vend_code = '",glob_rec_voucher.vend_code,"' ", 
		" ", l_where2_po clipped, ") ", 
		" ORDER BY order_num " 
	ELSE 
		LET l_sel_text = "SELECT * FROM purchhead ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		" AND ", l_where_po clipped, " ", 
		"AND (vend_code = '",glob_rec_voucher.vend_code,"' ", 
		" ", l_where2_po clipped, ") ", 
		" ORDER BY vend_code " 
	END IF 
	PREPARE s_purchhead FROM l_sel_text 
	DECLARE c_purchhead CURSOR FOR s_purchhead 
	LET l_msgresp=kandoomsg("P",1002,"") 
	#1002 Searching Database - please wait

	LET idx = 0 
	FOREACH c_purchhead INTO l_rec_purchhead.* 
		LET idx = idx + 1 
		LET l_arr_rec_purchhead[idx].order_num = l_rec_purchhead.order_num 
		SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].order_amt FROM poaudit 
		WHERE cmpy_code = p_cmpy 
		AND po_num = l_rec_purchhead.order_num 
		AND order_qty != 0 
		SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].received_amt 
		FROM poaudit 
		WHERE cmpy_code = p_cmpy 
		AND po_num = l_rec_purchhead.order_num 
		AND received_qty != 0 
		IF glob_rec_voucher.vouch_code IS NULL THEN 
			SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].paid_amt FROM voucherdist 
			WHERE cmpy_code = p_cmpy 
			AND po_num = l_rec_purchhead.order_num 
		ELSE 
			SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].paid_amt FROM voucherdist 
			WHERE cmpy_code = p_cmpy 
			AND vouch_code != glob_rec_voucher.vouch_code 
			AND po_num = l_rec_purchhead.order_num 
		END IF 
		IF l_arr_rec_purchhead[idx].paid_amt > 0 THEN 
			IF l_arr_rec_purchhead[idx].paid_amt = l_arr_rec_purchhead[idx].order_amt THEN 
				INITIALIZE l_arr_rec_purchhead[idx].* TO NULL 
				LET idx = idx - 1 
				CONTINUE FOREACH 
			END IF 
		END IF 
		SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].voucher_amt FROM t_podist 
		WHERE po_num = l_rec_purchhead.order_num 
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

	############# Test Code
	IF pr_tpo AND idx < 300 THEN 
		DECLARE c_podist CURSOR FOR 
		SELECT * FROM t_podist 
		WHERE po_num IS NOT NULL 
		FOREACH c_podist INTO l_rec_podist.* 
			LET l_poexist = false 
			FOR i = 1 TO idx 
				IF l_rec_podist.po_num = l_arr_rec_purchhead[i].order_num THEN 
					LET l_poexist = true 
					EXIT FOR 
				END IF 
			END FOR 
			IF l_poexist THEN 
				CONTINUE FOREACH 
			END IF 
			SELECT * INTO l_rec_purchhead.* 
			FROM purchhead 
			WHERE order_num = l_rec_podist.po_num 
			AND cmpy_code = p_cmpy 
			IF status = 0 THEN 
				LET idx = idx + 1 
				LET l_arr_rec_purchhead[idx].order_num = l_rec_purchhead.order_num 
				SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].order_amt FROM poaudit 
				WHERE cmpy_code = p_cmpy 
				AND po_num = l_rec_purchhead.order_num 
				AND order_qty != 0 
				SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].received_amt 
				FROM poaudit 
				WHERE cmpy_code = p_cmpy 
				AND po_num = l_rec_purchhead.order_num 
				AND received_qty != 0 
				IF glob_rec_voucher.vouch_code IS NULL THEN 
					SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].paid_amt FROM voucherdist 
					WHERE cmpy_code = p_cmpy 
					AND po_num = l_rec_purchhead.order_num 
				ELSE 
					SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].paid_amt FROM voucherdist 
					WHERE cmpy_code = p_cmpy 
					AND vouch_code != glob_rec_voucher.vouch_code 
					AND po_num = l_rec_purchhead.order_num 
				END IF 

				IF l_arr_rec_purchhead[idx].received_amt > 0 THEN 
					IF l_arr_rec_purchhead[idx].paid_amt = l_arr_rec_purchhead[idx].received_amt THEN 
						INITIALIZE l_arr_rec_purchhead[idx].* TO NULL 
						LET idx = idx - 1 
						CONTINUE FOREACH 
					END IF 
				END IF 


				SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].voucher_amt FROM t_podist 
				WHERE po_num = l_rec_purchhead.order_num 
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
			END IF 
		END FOREACH 

	END IF 
	#############
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	CALL set_count(idx) 
	LET l_msgresp=kandoomsg("P",1011,"") 

	#1011 Purchasing - F8 Edit Order - F9 Receipt Order - RETURN Edit Lines
	INPUT ARRAY l_arr_rec_purchhead WITHOUT DEFAULTS FROM sr_purchhead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P29b","inp-arr-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY l_arr_rec_purchhead[idx].* TO sr_purchhead[scrn].* 

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

		ON KEY (F8) 
			IF l_arr_rec_purchhead[idx].order_num > 0 THEN 
				IF po_mod(p_cmpy,p_kandoouser_sign_on_code,l_arr_rec_purchhead[idx].order_num,MODE_CLASSIC_EDIT) THEN 
				END IF 
				## After Edit of PO retreive new ORDER total
				SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].order_amt 
				FROM poaudit 
				WHERE cmpy_code = p_cmpy 
				AND po_num = l_arr_rec_purchhead[idx].order_num 
				AND order_qty != 0 
				IF l_arr_rec_purchhead[idx].order_amt IS NULL THEN 
					LET l_arr_rec_purchhead[idx].order_amt = 0 
				END IF 
				SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].received_amt 
				FROM poaudit 
				WHERE cmpy_code = p_cmpy 
				AND po_num = l_arr_rec_purchhead[idx].order_num 
				AND received_qty != 0 
				IF l_arr_rec_purchhead[idx].received_amt IS NULL THEN 
					LET l_arr_rec_purchhead[idx].received_amt = 0 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 

		ON KEY (F9) 
			IF l_arr_rec_purchhead[idx].order_num > 0 THEN 
				CALL run_prog("R21",l_arr_rec_purchhead[idx].order_num,"","","") 
				## After PO Receipt retreive new ORDER total
				SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].order_amt 
				FROM poaudit 
				WHERE cmpy_code = p_cmpy 
				AND po_num = l_arr_rec_purchhead[idx].order_num 
				AND order_qty != 0 
				IF l_arr_rec_purchhead[idx].order_amt IS NULL THEN 
					LET l_arr_rec_purchhead[idx].order_amt = 0 
				END IF 
				## After PO Receipt retreive new received total
				SELECT sum(line_total_amt) INTO l_arr_rec_purchhead[idx].received_amt 
				FROM poaudit 
				WHERE cmpy_code = p_cmpy 
				AND po_num = l_arr_rec_purchhead[idx].order_num 
				AND received_qty != 0 
				IF l_arr_rec_purchhead[idx].received_amt IS NULL THEN 
					LET l_arr_rec_purchhead[idx].received_amt = 0 
				END IF 
				LET l_arr_rec_purchhead[idx].remain_amt = l_arr_rec_purchhead[idx].received_amt 
				- l_arr_rec_purchhead[idx].paid_amt 
				- l_arr_rec_purchhead[idx].voucher_amt 
				IF l_arr_rec_purchhead[idx].remain_amt < 0 THEN 
					LET l_arr_rec_purchhead[idx].remain_amt = 0 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 

		ON KEY (F10) 
			IF glob_rec_voucher.dist_amt < glob_rec_voucher.total_amt 
			AND l_arr_rec_purchhead[idx].received_amt > 0 
			AND l_arr_rec_purchhead[idx].paid_amt < l_arr_rec_purchhead[idx].received_amt THEN 
				CALL auto_dist_line(l_arr_rec_purchhead[idx].order_num) 
				SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].voucher_amt 
				FROM t_podist 
				WHERE po_num = l_arr_rec_purchhead[idx].order_num 
				IF l_arr_rec_purchhead[idx].voucher_amt IS NULL THEN 
					LET l_arr_rec_purchhead[idx].voucher_amt = 0 
				END IF 
				LET l_arr_rec_purchhead[idx].remain_amt = l_arr_rec_purchhead[idx].received_amt 
				- l_arr_rec_purchhead[idx].paid_amt 
				- l_arr_rec_purchhead[idx].voucher_amt 
				IF l_arr_rec_purchhead[idx].remain_amt < 0 THEN 
					LET l_arr_rec_purchhead[idx].remain_amt = 0 
				END IF 
				DISPLAY BY NAME glob_rec_voucher.dist_amt 

				NEXT FIELD scroll_flag 
			END IF 

		BEFORE FIELD order_num 
			IF l_arr_rec_purchhead[idx].order_num > 0 THEN 
				IF l_arr_rec_purchhead[idx].received_amt = l_arr_rec_purchhead[idx].paid_amt THEN 
					LET l_msgresp=kandoomsg("P",9547,"") 
					#9547 Nothing outstanding TO pay.  Receipt items first.
				ELSE 
					IF dist_po_line(l_arr_rec_purchhead[idx].order_num) THEN 
						SELECT sum(dist_amt) INTO l_arr_rec_purchhead[idx].voucher_amt 
						FROM t_podist 
						WHERE po_num = l_arr_rec_purchhead[idx].order_num 
						IF l_arr_rec_purchhead[idx].voucher_amt IS NULL THEN 
							LET l_arr_rec_purchhead[idx].voucher_amt = 0 
						END IF 
						LET l_arr_rec_purchhead[idx].remain_amt = l_arr_rec_purchhead[idx].received_amt 
						- l_arr_rec_purchhead[idx].paid_amt 
						- l_arr_rec_purchhead[idx].voucher_amt 
						IF l_arr_rec_purchhead[idx].remain_amt < 0 THEN 
							LET l_arr_rec_purchhead[idx].remain_amt = 0 
						END IF 
						DISPLAY BY NAME glob_rec_voucher.dist_amt 

					END IF 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

		AFTER ROW 
			DISPLAY l_arr_rec_purchhead[idx].* TO sr_purchhead[scrn].* 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_msgresp=kandoomsg("P",1005,"") 
		#1005 Searching database pls wait
		DELETE FROM t_voucherdist 
		INSERT INTO t_voucherdist SELECT * FROM t_podist 
	END IF 

	CLOSE WINDOW r144 

END FUNCTION 


############################################################
# FUNCTION dist_po_line(p_order_num)
#
#
############################################################
FUNCTION dist_po_line(p_order_num) 
	DEFINE p_order_num LIKE purchhead.order_num 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_arr_rec_purchdetl ARRAY[2000] OF 
	RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE purchdetl.line_num, 
		desc_text LIKE purchdetl.desc_text, 
		outstand_qty LIKE poaudit.voucher_qty, 
		outstand_amt LIKE poaudit.line_total_amt, 
		payment_qty LIKE poaudit.voucher_qty, 
		payment_amt LIKE poaudit.line_total_amt 
	END RECORD 
	DEFINE l_rec_display 
	RECORD 
		remain_qty LIKE poaudit.order_qty, 
		received_amt LIKE poaudit.line_total_amt, 
		voucher_amt LIKE poaudit.line_total_amt, 
		remain_amt LIKE poaudit.line_total_amt 
	END RECORD 
	DEFINE l_commit_qty LIKE poaudit.order_qty 
	DEFINE l_temp_vouch_dist LIKE voucher.dist_amt 
	DEFINE l_default_pay_amt LIKE poaudit.line_total_amt 
	DEFINE l_lower_limit LIKE poaudit.line_total_amt 
	DEFINE l_upper_limit LIKE poaudit.line_total_amt 
	DEFINE l_amt_text CHAR(11) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx,scrn SMALLINT

	OPEN WINDOW r146 with FORM "R146" 
	CALL windecoration_p("P146") 

	LET l_temp_vouch_dist = glob_rec_voucher.dist_amt 
	SELECT * INTO l_rec_purchhead.* FROM purchhead 
	WHERE cmpy_code = glob_rec_vendor.cmpy_code 
	AND order_num = p_order_num 
	LET l_msgresp=kandoomsg("P",1002,"") 
	#1002 Searching Database;  Please wait.
	LET l_rec_purchdetl.order_num = p_order_num 
	DISPLAY BY NAME glob_rec_voucher.vouch_code, 
	l_rec_purchdetl.order_num, 
	glob_rec_voucher.total_amt, 
	glob_rec_voucher.dist_amt 

	DISPLAY BY NAME glob_rec_voucher.currency_code 
	attribute(green) 
	DECLARE c_purchdetl CURSOR FOR 
	SELECT * FROM purchdetl 
	WHERE cmpy_code = glob_rec_voucher.cmpy_code 
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
		IF glob_rec_voucher.vouch_code IS NULL THEN 
			LET l_commit_qty = 0 
		ELSE 
			LET l_commit_qty = 0 
			SELECT trans_qty 
			INTO l_commit_qty FROM voucherdist 
			WHERE cmpy_code = glob_rec_voucher.cmpy_code 
			AND vend_code = glob_rec_voucher.vend_code 
			AND vouch_code = glob_rec_voucher.vouch_code 
			AND po_num = l_rec_purchdetl.order_num 
			AND po_line_num = l_rec_purchdetl.line_num 
		END IF 
		LET l_rec_poaudit.voucher_qty = l_rec_poaudit.voucher_qty - l_commit_qty 
		LET l_rec_poaudit.unit_cost_amt = l_rec_poaudit.unit_cost_amt 
		+ l_rec_poaudit.unit_tax_amt 
		SELECT trans_qty,dist_amt 
		INTO l_arr_rec_purchdetl[idx].payment_qty, 
		l_arr_rec_purchdetl[idx].payment_amt 
		FROM t_podist 
		WHERE po_num = l_rec_purchdetl.order_num 
		AND po_line_num = l_rec_purchdetl.line_num 
		IF status = NOTFOUND THEN 
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
	LET l_msgresp = kandoomsg("P",1012,"") 

	#1012 Purchase Order Lines - F8 View History - RETURN Edit Payment
	INPUT ARRAY l_arr_rec_purchdetl WITHOUT DEFAULTS FROM sr_purchdetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P29b","inp-arr-purchdetl-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			CALL po_line_info(glob_rec_voucher.cmpy_code, 
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

			IF glob_rec_voucher.vouch_code IS NULL THEN 
				LET l_commit_qty = 0 
			ELSE 
				LET l_commit_qty = 0 
				SELECT trans_qty INTO l_commit_qty FROM voucherdist 
				WHERE cmpy_code = glob_rec_voucher.cmpy_code 
				AND vend_code = glob_rec_voucher.vend_code 
				AND vouch_code = glob_rec_voucher.vouch_code 
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
		ON KEY (F8) 
			IF l_arr_rec_purchdetl[idx].line_num > 0 THEN 
				CALL pohiwind(l_rec_purchdetl.cmpy_code, 
				glob_rec_vendor.vend_code, 
				l_rec_purchdetl.order_num, 
				l_arr_rec_purchdetl[idx].line_num) 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD payment_qty 
			IF l_arr_rec_purchdetl[idx].line_num = 0 
			OR l_arr_rec_purchdetl[idx].line_num IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
			SELECT unique 1 
			FROM shipdetl, shiphead 
			WHERE shipdetl.source_doc_num = p_order_num 
			AND shipdetl.doc_line_num = l_arr_rec_purchdetl[idx].line_num 
			AND shipdetl.ship_inv_qty > 0 
			AND shipdetl.cmpy_code = l_rec_purchhead.cmpy_code 
			AND shipdetl.cmpy_code = shiphead.cmpy_code 
			AND shipdetl.ship_code = shiphead.ship_code 
			AND shiphead.finalised_flag <> "Y" 
			IF status != NOTFOUND THEN 
				LET l_msgresp = kandoomsg("R",9016,"") 
				#9016 Cannot distribute voucher TO shipment ORDER line
				NEXT FIELD scroll_flag 
			END IF 
			LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
			- l_arr_rec_purchdetl[idx].payment_amt 
		AFTER FIELD payment_qty 
			CASE 
				WHEN l_arr_rec_purchdetl[idx].payment_qty IS NULL 
					LET l_arr_rec_purchdetl[idx].payment_qty = 0 
					LET l_arr_rec_purchdetl[idx].payment_amt = 0 
					NEXT FIELD payment_qty 
				WHEN l_arr_rec_purchdetl[idx].payment_qty < 0 
					LET l_msgresp=kandoomsg("P",9019,"") 
					#P9019" cannot be less than zero
					LET l_arr_rec_purchdetl[idx].payment_qty = 0 
					LET l_arr_rec_purchdetl[idx].payment_amt = 0 
					NEXT FIELD payment_qty 
				WHEN l_arr_rec_purchdetl[idx].payment_qty > l_rec_display.remain_qty 
					LET l_msgresp=kandoomsg("P",9020,"") 
					#P9020 Payment quantity exceeds purchase ORDER line quantity"
					LET l_arr_rec_purchdetl[idx].payment_qty = l_rec_display.remain_qty 
					LET l_arr_rec_purchdetl[idx].payment_amt = l_rec_display.remain_amt 
					LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
					+ l_arr_rec_purchdetl[idx].payment_amt 
					NEXT FIELD payment_qty 
				OTHERWISE 
					LET l_default_pay_amt = l_arr_rec_purchdetl[idx].payment_qty 
					* l_rec_poaudit.unit_cost_amt 
					LET l_arr_rec_purchdetl[idx].payment_amt = l_default_pay_amt 
					IF (l_arr_rec_purchdetl[idx].payment_amt) > 
					(glob_rec_voucher.total_amt - glob_rec_voucher.dist_amt) THEN 
						LET l_msgresp=kandoomsg("P",9015,"") 
						#P9015"Warning:  Payment amount exceeds voucher total"
					END IF 
					LET l_arr_rec_purchdetl[idx].outstand_amt = 
					l_rec_display.remain_amt - l_arr_rec_purchdetl[idx].payment_amt 
					IF l_arr_rec_purchdetl[idx].outstand_amt < 0 THEN #jp 
						LET l_arr_rec_purchdetl[idx].outstand_amt = 0 
					END IF 
					LET l_arr_rec_purchdetl[idx].outstand_qty = 
					l_rec_display.remain_qty - l_arr_rec_purchdetl[idx].payment_qty 
					DISPLAY l_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].* 

					LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
					+ l_arr_rec_purchdetl[idx].payment_amt 
					DISPLAY BY NAME glob_rec_voucher.dist_amt 

			END CASE 
		BEFORE FIELD payment_amt 
			LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
			- l_arr_rec_purchdetl[idx].payment_amt 
			LET l_default_pay_amt = l_arr_rec_purchdetl[idx].payment_qty 
			* l_rec_poaudit.unit_cost_amt 
		AFTER FIELD payment_amt 
			CASE 
				WHEN l_arr_rec_purchdetl[idx].payment_amt IS NULL 
					LET l_arr_rec_purchdetl[idx].payment_amt = 0 
					NEXT FIELD payment_amt 
				WHEN l_arr_rec_purchdetl[idx].payment_amt < 0 
					LET l_msgresp=kandoomsg("P",9019,"") 
					#9019 Payment amount must NOT be less than zero"
					LET l_arr_rec_purchdetl[idx].payment_amt = 0 
					NEXT FIELD payment_amt 

				WHEN l_rec_display.voucher_amt > 0 AND 
					l_arr_rec_purchdetl[idx].payment_amt <> l_default_pay_amt 
					LET l_msgresp=kandoomsg("P",9021,"") 
					#P9021" Purchase ORDER line already invoiced - cannot alter price"
					LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
					+ l_arr_rec_purchdetl[idx].payment_amt 
					LET l_arr_rec_purchdetl[idx].payment_amt = l_default_pay_amt 
					NEXT FIELD payment_amt 

				OTHERWISE 
					LET l_lower_limit = 
					l_default_pay_amt * (1 -(glob_rec_vendor.po_var_per/100)) 
					LET l_upper_limit = 
					l_default_pay_amt * (1 +(glob_rec_vendor.po_var_per/100)) 
					IF l_lower_limit < 
					(l_default_pay_amt - glob_rec_vendor.po_var_amt) THEN 
						LET l_lower_limit = 
						l_default_pay_amt - glob_rec_vendor.po_var_amt 
					END IF 
					IF l_upper_limit > 
					(l_default_pay_amt + glob_rec_vendor.po_var_amt) THEN 
						LET l_upper_limit = 
						l_default_pay_amt + glob_rec_vendor.po_var_amt 
					END IF 
					IF (l_arr_rec_purchdetl[idx].payment_amt < l_lower_limit) OR 
					(l_arr_rec_purchdetl[idx].payment_amt > l_upper_limit) THEN 
						LET l_amt_text = l_arr_rec_purchdetl[idx].payment_amt 
						USING "<<<<<<<<.&&" 
						LET l_msgresp = kandoomsg("P",9081,l_amt_text) 
						#P9081" Amount outside allowable price variance FOR this Vendor"
						LET l_arr_rec_purchdetl[idx].payment_amt = l_default_pay_amt 
						LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
						+ l_arr_rec_purchdetl[idx].payment_amt 
						NEXT FIELD payment_amt 
					END IF 
					IF (l_arr_rec_purchdetl[idx].payment_amt) > 
					(glob_rec_voucher.total_amt - glob_rec_voucher.dist_amt) THEN 
						LET l_msgresp=kandoomsg("P",9015,"") 
						#P9015"Warning:  Payment amount exceeds voucher total"
					END IF 
					LET l_arr_rec_purchdetl[idx].outstand_amt = 
					l_rec_display.remain_amt - l_arr_rec_purchdetl[idx].payment_amt 
					LET l_arr_rec_purchdetl[idx].outstand_qty = 
					l_rec_display.remain_qty - l_arr_rec_purchdetl[idx].payment_qty 
					IF l_arr_rec_purchdetl[idx].outstand_qty < 0 THEN 
						LET l_arr_rec_purchdetl[idx].outstand_qty = 0 
					END IF 
					IF l_arr_rec_purchdetl[idx].outstand_amt < 0 THEN 
						LET l_arr_rec_purchdetl[idx].outstand_amt = 0 
					END IF 
					DISPLAY l_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].* 

					LET glob_rec_voucher.dist_amt = glob_rec_voucher.dist_amt 
					+ l_arr_rec_purchdetl[idx].payment_amt 
					DISPLAY BY NAME glob_rec_voucher.dist_amt 

			END CASE 

	END INPUT 
	CLOSE WINDOW r146 
	IF int_flag OR quit_flag THEN 
		LET glob_rec_voucher.dist_amt = l_temp_vouch_dist 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		FOR idx = 1 TO arr_count() 
			IF l_arr_rec_purchdetl[idx].line_num > 0 THEN 
				IF l_arr_rec_purchdetl[idx].payment_qty = 0 THEN 
					DELETE FROM t_podist 
					WHERE po_num = p_order_num 
					AND po_line_num = l_arr_rec_purchdetl[idx].line_num 
				ELSE 
					UPDATE t_podist 
					SET dist_amt = l_arr_rec_purchdetl[idx].payment_amt, 
					trans_qty = l_arr_rec_purchdetl[idx].payment_qty, 
					cost_amt =l_arr_rec_purchdetl[idx].payment_amt/ 
					l_arr_rec_purchdetl[idx].payment_qty 
					WHERE po_num = p_order_num 
					AND po_line_num = l_arr_rec_purchdetl[idx].line_num 
					IF sqlca.sqlerrd[3] = 0 THEN 
						SELECT max(line_num) INTO glob_rec_voucher.line_num FROM t_podist 
						IF glob_rec_voucher.line_num IS NULL THEN 
							LET glob_rec_voucher.line_num = 1 
						ELSE 
							LET glob_rec_voucher.line_num = glob_rec_voucher.line_num + 1 
						END IF 
						LET l_rec_voucherdist.line_num = glob_rec_voucher.line_num 
						LET l_rec_voucherdist.type_ind = "P" 
						LET l_rec_voucherdist.acct_code = modu_rec_puparms.clear_acct_code 
						LET l_rec_voucherdist.desc_text = l_arr_rec_purchdetl[idx].desc_text 
						LET l_rec_voucherdist.dist_qty = 0 
						LET l_rec_voucherdist.dist_amt = l_arr_rec_purchdetl[idx].payment_amt 
						LET l_rec_voucherdist.po_num = p_order_num 
						LET l_rec_voucherdist.po_line_num = l_arr_rec_purchdetl[idx].line_num 
						LET l_rec_voucherdist.trans_qty = l_arr_rec_purchdetl[idx].payment_qty 
						LET l_rec_voucherdist.cost_amt = l_rec_voucherdist.dist_amt / 
						l_rec_voucherdist.trans_qty 
						LET l_rec_voucherdist.charge_amt = 0 
						INSERT INTO t_podist VALUES (l_rec_voucherdist.*) 
					END IF 
				END IF 
			END IF 
		END FOR 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION cr_lc_dist(p_cmpy,p_kandoouser_sign_on_code,p_line_num)
#
#
############################################################
FUNCTION cr_lc_dist(p_cmpy,p_kandoouser_sign_on_code,p_line_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_line_num SMALLINT 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_shipcosttype RECORD LIKE shipcosttype.* 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* #huho - NOT used 
	DEFINE l_rec_smparms RECORD LIKE smparms.* 
	DEFINE l_old_desc_text LIKE voucherdist.desc_text 
	DEFINE l_old_res_code LIKE voucherdist.res_code 
	DEFINE l_old_job_code LIKE voucherdist.job_code 
	DEFINE l_vouch_remain LIKE voucher.total_amt 
	DEFINE l_old_dist_amt LIKE voucher.dist_amt 
	DEFINE l_flag INTEGER 
	DEFINE l_temp_text CHAR(60) 
	DEFINE l_winds_text CHAR(80) 
	DEFINE l_msgresp LIKE language.yes_flag 

	INITIALIZE l_rec_voucherdist.* TO NULL 
	INITIALIZE l_rec_coa.* TO NULL 
	SELECT * INTO l_rec_voucherdist.* FROM t_voucherdist 
	WHERE line_num = p_line_num 
	IF status = 0 THEN 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_voucherdist.acct_code 
		AND cmpy_code = p_cmpy 

		SELECT * INTO l_rec_shipcosttype.* FROM shipcosttype 
		WHERE cost_type_code = l_rec_voucherdist.res_code 
		AND cmpy_code = p_cmpy 

		SELECT * INTO l_rec_shiphead.* FROM shiphead 
		WHERE ship_code = l_rec_voucherdist.job_code 
		AND cmpy_code = p_cmpy 
	END IF 
	IF l_rec_coa.analy_prompt_text IS NULL THEN 
		LET l_rec_coa.analy_prompt_text = "Analysis" 
	END IF 
	LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
	LET l_rec_coa.analy_prompt_text = l_temp_text 
	OPEN WINDOW p231 with FORM "P231" 
	CALL windecoration_p("P231") 
	DISPLAY BY NAME l_rec_coa.analy_prompt_text 
	attribute(white) 
	DISPLAY BY NAME l_rec_voucherdist.job_code, 
	l_rec_voucherdist.res_code, 
	l_rec_voucherdist.desc_text, 
	l_rec_voucherdist.acct_code, 
	l_rec_voucherdist.dist_amt, 
	l_rec_voucherdist.analysis_text, 
	l_rec_voucherdist.dist_qty 

	DISPLAY l_rec_shipcosttype.desc_text TO ship_desc_text--pr_ship_desc_text 


	IF l_rec_shiphead.finalised_flag = 'Y' 
	AND l_rec_shipcosttype.class_ind <> '4' THEN 
		LET l_msgresp = kandoomsg("P",7061,"") 
		#7061 Only "Late" cost types can be editted once a shipment IS fin
		CLOSE WINDOW p231 
		RETURN 
	END IF 

	LET l_old_res_code = l_rec_voucherdist.res_code 
	LET l_old_job_code = l_rec_voucherdist.job_code 

	INPUT BY NAME l_rec_voucherdist.job_code, 
	l_rec_voucherdist.res_code, 
	l_rec_voucherdist.desc_text, 
	l_rec_voucherdist.acct_code, 
	l_rec_voucherdist.dist_amt, 
	l_rec_voucherdist.analysis_text, 
	l_rec_voucherdist.dist_qty 
	WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P29b","inp-voucherdist-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 




		ON ACTION "LOOKUP" infield (job_code) 
			LET l_winds_text = showship(p_cmpy) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_voucherdist.job_code = l_winds_text 
				NEXT FIELD job_code 
			END IF 
		
		ON ACTION "LOOKUP" infield (res_code) 
			CALL show_costtype(p_cmpy) RETURNING l_flag, l_winds_text 
			IF l_flag THEN 
				LET l_rec_voucherdist.res_code = l_winds_text 
				NEXT FIELD res_code 
			END IF 
		
		ON ACTION "LOOKUP" infield (acct_code) 
			LET l_winds_text = show_acct(p_cmpy) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_voucherdist.acct_code = l_winds_text 
				NEXT FIELD acct_code 
			END IF 

		ON ACTION "NOTES" infield (desc_text) 
		--ON KEY (control-n)infield (desc_text) 
			LET l_rec_voucherdist.desc_text = 
			sys_noter(glob_rec_voucher.cmpy_code,l_rec_voucherdist.desc_text) 
			NEXT FIELD desc_text 


		AFTER FIELD job_code 
			IF l_rec_voucherdist.job_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD job_code 
			ELSE 
				SELECT * INTO l_rec_shiphead.* FROM shiphead 
				WHERE ship_code = l_rec_voucherdist.job_code 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("L",9005,"") 
					#9005 Shipment was NOT found
					NEXT FIELD job_code 
				END IF 
			END IF 

		AFTER FIELD res_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF l_rec_voucherdist.res_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD res_code 
			END IF 
			SELECT * INTO l_rec_shipcosttype.* FROM shipcosttype 
			WHERE cost_type_code = l_rec_voucherdist.res_code 
			AND cmpy_code = p_cmpy 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("L",9006,"") 
				#9006 Shipment Cost Type NOT found
				NEXT FIELD res_code 
			END IF 
			IF l_rec_shipcosttype.class_ind = '1' THEN 
				IF l_rec_shiphead.vend_code <> glob_rec_voucher.vend_code THEN 
					LET l_msgresp = kandoomsg("P",7060,"") 
					#7060 "Free on Board" cost types can .. vendor codes
					NEXT FIELD res_code 
				END IF 
				IF glob_rec_voucher.conv_qty <> l_rec_shiphead.conversion_qty THEN 
					LET l_msgresp = kandoomsg("P",7062,"") 
					#7062 "Free on Board" cost types can .. exchange rate
					NEXT FIELD res_code 
				END IF 
			END IF 
			IF l_rec_shiphead.finalised_flag <> 'Y' 
			AND l_rec_shipcosttype.class_ind = '4' THEN 
				LET l_msgresp = kandoomsg("P",9185,"") 
				#9185 "Late" cost types can only be used FOR finalised sh
				NEXT FIELD res_code 
			END IF 
			IF l_rec_shiphead.finalised_flag = 'Y' 
			AND l_rec_shipcosttype.class_ind <> '4' THEN 
				LET l_msgresp = kandoomsg("P",9186,"") 
				#9186 Only "Late" cost types can be used FOR finalised sh
				NEXT FIELD res_code 
			END IF 
			DISPLAY l_rec_shipcosttype.desc_text TO pr_ship_desc_text 


			IF l_old_res_code <> l_rec_voucherdist.res_code 
			OR l_old_job_code <> l_rec_voucherdist.job_code 
			OR l_old_res_code IS NULL 
			OR l_old_job_code IS NULL THEN 
				LET l_old_res_code = l_rec_voucherdist.res_code 
				LET l_old_job_code = l_rec_voucherdist.job_code 
				IF l_rec_shipcosttype.class_ind <> '4' THEN 
					SELECT * INTO l_rec_smparms.* FROM smparms 
					WHERE key_num = '1' 
					AND cmpy_code = p_cmpy 
					IF l_rec_shiphead.ship_type_ind = 3 THEN 
						IF l_rec_shipcosttype.ret_acct_code IS NULL THEN 
							LET l_rec_voucherdist.acct_code = l_rec_smparms.ret_git_acct_code 
						ELSE 
							LET l_rec_voucherdist.acct_code = l_rec_shipcosttype.ret_acct_code 
						END IF 
					ELSE 
						IF l_rec_shipcosttype.acct_code IS NULL THEN 
							LET l_rec_voucherdist.acct_code = l_rec_smparms.git_acct_code 
						ELSE 
							LET l_rec_voucherdist.acct_code = l_rec_shipcosttype.acct_code 
						END IF 
					END IF 
					DISPLAY BY NAME l_rec_voucherdist.acct_code 

				ELSE 
					IF l_rec_shiphead.ship_type_ind = 3 THEN 
						LET l_rec_voucherdist.acct_code = l_rec_shipcosttype.ret_acct_code 
					ELSE 
						LET l_rec_voucherdist.acct_code = l_rec_shipcosttype.acct_code 
					END IF 
					DISPLAY BY NAME l_rec_voucherdist.acct_code 

				END IF 
				IF l_old_desc_text <> 'changed' THEN 
					LET l_rec_voucherdist.desc_text = 'shipment - ', 
					l_rec_voucherdist.job_code clipped, 
					' ', l_rec_shipcosttype.desc_text 
					LET l_old_desc_text = l_rec_voucherdist.desc_text 
				END IF 
			END IF 

		BEFORE FIELD desc_text 
			IF l_rec_voucherdist.desc_text IS NULL THEN 
				LET l_rec_voucherdist.desc_text = 'shipment - ', 
				l_rec_voucherdist.job_code clipped, 
				' ', l_rec_shipcosttype.desc_text 
				LET l_old_desc_text = l_rec_voucherdist.desc_text 
			END IF 

		AFTER FIELD desc_text 
			IF l_old_desc_text <> l_rec_voucherdist.desc_text THEN 
				LET l_old_desc_text = 'changed' 
			END IF 

		BEFORE FIELD acct_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE acct_code = l_rec_voucherdist.acct_code 
			AND cmpy_code = p_cmpy 
			IF l_rec_coa.analy_prompt_text IS NULL THEN 
				LET l_rec_coa.analy_prompt_text = "Analysis" 
			END IF 
			LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
			LET l_rec_coa.analy_prompt_text = l_temp_text 
			DISPLAY BY NAME l_rec_coa.analy_prompt_text 
			attribute(white) 
			IF l_rec_shipcosttype.class_ind <> '4' THEN 
				NEXT FIELD dist_amt 
			END IF 

		AFTER FIELD acct_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF l_rec_voucherdist.acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9232,"") 
				#9232 An account code must be entered
				NEXT FIELD acct_code 
			ELSE 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_voucherdist.acct_code 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("W",9234,"") 
					#9234 Account code NOT found - Try window
					NEXT FIELD acct_code 
				ELSE 
					IF NOT acct_type(p_cmpy,l_rec_voucherdist.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
						NEXT FIELD acct_code 
					END IF 
					SELECT unique 1 FROM bank 
					WHERE cmpy_code = p_cmpy 
					AND acct_code = l_rec_voucherdist.acct_code 
					IF status = NOTFOUND THEN 
					ELSE 
						LET l_msgresp = kandoomsg("G",9111," ") 
						NEXT FIELD acct_code 
					END IF 
					IF l_rec_coa.analy_prompt_text IS NULL THEN 
						LET l_rec_coa.analy_prompt_text = "Analysis" 
					END IF 
					LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
					LET l_rec_coa.analy_prompt_text = l_temp_text 
					DISPLAY BY NAME l_rec_coa.analy_prompt_text 
					attribute(white) 
				END IF 
			END IF 

		BEFORE FIELD dist_amt 
			LET l_vouch_remain = glob_rec_voucher.total_amt - glob_rec_voucher.dist_amt 
			LET l_old_dist_amt = l_rec_voucherdist.dist_amt 
			IF l_vouch_remain > 0 
			AND ( l_rec_voucherdist.dist_amt = 0 
			OR l_rec_voucherdist.dist_amt IS NULL ) THEN 
				LET l_rec_voucherdist.dist_amt = l_vouch_remain 
			END IF 

		AFTER FIELD dist_amt 
			IF l_rec_voucherdist.dist_amt IS NULL OR 
			l_rec_voucherdist.dist_amt <= 0 THEN 
				LET l_msgresp=kandoomsg("I",9085,"") 
				#9085 Must enter a value greater than zero
				NEXT FIELD dist_amt 
			END IF 
			IF ( l_rec_voucherdist.dist_amt - l_old_dist_amt ) 
			> l_vouch_remain THEN 
				LET l_msgresp=kandoomsg("P",9015,"") 
				#9015"WARNING: This entry will over distribute the voucher.
			END IF 

		AFTER FIELD analysis_text 
			IF l_rec_voucherdist.analysis_text IS NULL 
			AND l_rec_coa.analy_req_flag = 'Y' THEN 
				LET l_msgresp=kandoomsg("P",9016,"") 
				#9016 Analysis IS required
				NEXT FIELD analysis_text 
			END IF 

		AFTER FIELD dist_qty 
			IF l_rec_coa.uom_code IS NULL 
			AND l_rec_voucherdist.dist_qty IS NOT NULL 
			AND l_rec_voucherdist.dist_qty <> 0 THEN 
				LET l_msgresp=kandoomsg("P",9184,"") 
				#9184 Quantities are NOT collected FOR this Account Code
				LET l_rec_voucherdist.dist_qty = NULL 
				NEXT FIELD dist_qty 
			END IF 
			IF l_rec_coa.uom_code IS NOT NULL 
			AND l_rec_voucherdist.dist_qty IS NULL THEN 
				LET l_rec_voucherdist.dist_qty = 0 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			ELSE 
				IF l_rec_voucherdist.job_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD job_code 
				ELSE 
					SELECT * INTO l_rec_shiphead.* FROM shiphead 
					WHERE ship_code = l_rec_voucherdist.job_code 
					AND cmpy_code = p_cmpy 
					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("L",9005,"") 
						#9005 Shipment was NOT found
						NEXT FIELD job_code 
					END IF 
				END IF 
				IF l_rec_voucherdist.res_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD res_code 
				ELSE 
					SELECT * INTO l_rec_shipcosttype.* FROM shipcosttype 
					WHERE cost_type_code = l_rec_voucherdist.res_code 
					AND cmpy_code = p_cmpy 
					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("L",9006,"") 
						#9006 Shipment Cost Type NOT found
						NEXT FIELD res_code 
					END IF 
					IF l_rec_shipcosttype.class_ind = '1' THEN 
						IF l_rec_shiphead.vend_code <> glob_rec_voucher.vend_code THEN 
							LET l_msgresp = kandoomsg("P",7060,"") 
							#7060 "Free on Board" cost types can .. vendor code
							NEXT FIELD res_code 
						END IF 
						IF glob_rec_voucher.conv_qty <> l_rec_shiphead.conversion_qty THEN 
							LET l_msgresp = kandoomsg("P",7062,"") 
							#7062 "Free on Board" cost types can .. exchange
							NEXT FIELD res_code 
						END IF 
					END IF 
					IF l_rec_shiphead.finalised_flag <> 'Y' 
					AND l_rec_shipcosttype.class_ind = '4' THEN 
						LET l_msgresp = kandoomsg("P",9185,"") 
						#9185 "Late" cost types can only be used FOR finalised
						NEXT FIELD res_code 
					END IF 
					IF l_rec_shiphead.finalised_flag = 'Y' 
					AND l_rec_shipcosttype.class_ind <> '4' THEN 
						LET l_msgresp = kandoomsg("P",9186,"") 
						#9186 Only "Late" cost types can be used FOR finalised
						NEXT FIELD res_code 
					END IF 
					DISPLAY l_rec_shipcosttype.desc_text TO pr_ship_desc_text 

				END IF 
				IF l_rec_shipcosttype.class_ind = '4' THEN 
					IF l_rec_voucherdist.acct_code IS NULL THEN 
						LET l_msgresp = kandoomsg("W",9232,"") 
						#9232 An account code must be entered
						NEXT FIELD acct_code 
					END IF 
					IF NOT acct_type(p_cmpy,l_rec_voucherdist.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
						NEXT FIELD acct_code 
					END IF 
				END IF 
				IF l_rec_voucherdist.dist_amt IS NULL OR 
				l_rec_voucherdist.dist_amt <= 0 THEN 
					LET l_msgresp=kandoomsg("I",9085,"") 
					#9085 Must enter a value greater than zero
					NEXT FIELD dist_amt 
				END IF 
				IF l_rec_voucherdist.analysis_text IS NULL 
				AND l_rec_coa.analy_req_flag = "Y" THEN 
					LET l_msgresp=kandoomsg("P",9016,"") 
					#9016 " Analysis IS required "
					NEXT FIELD analysis_text 
				END IF 
				IF l_rec_coa.uom_code IS NOT NULL 
				AND l_rec_voucherdist.dist_qty IS NULL THEN 
					LET l_rec_voucherdist.dist_qty = 0 
				END IF 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW p231 
		RETURN 
	END IF 
	LET l_rec_voucherdist.type_ind = "S" 
	IF l_rec_voucherdist.dist_qty IS NULL THEN 
		LET l_rec_voucherdist.dist_qty = 0 
	END IF 
	LET l_rec_voucherdist.po_num = '' 
	LET l_rec_voucherdist.po_line_num = '' 
	LET l_rec_voucherdist.trans_qty = 0 
	LET l_rec_voucherdist.charge_amt = 0 
	UPDATE t_voucherdist 
	SET job_code = l_rec_voucherdist.job_code, 
	dist_qty = l_rec_voucherdist.dist_qty, 
	dist_amt = l_rec_voucherdist.dist_amt, 
	analysis_text = l_rec_voucherdist.analysis_text, 
	po_num = l_rec_voucherdist.po_num, 
	po_line_num = l_rec_voucherdist.po_line_num, 
	type_ind = l_rec_voucherdist.type_ind , 
	desc_text = l_rec_voucherdist.desc_text, 
	trans_qty = l_rec_voucherdist.trans_qty, 
	charge_amt = l_rec_voucherdist.charge_amt, 
	res_code = l_rec_voucherdist.res_code, 
	acct_code = l_rec_voucherdist.acct_code 
	WHERE line_num = p_line_num 
	IF sqlca.sqlerrd[3] = 0 THEN 
		SELECT max(line_num) INTO glob_rec_voucher.line_num 
		FROM t_voucherdist 
		IF glob_rec_voucher.line_num IS NULL THEN 
			LET glob_rec_voucher.line_num = 1 
		ELSE 
			LET glob_rec_voucher.line_num = glob_rec_voucher.line_num + 1 
		END IF 
		LET l_rec_voucherdist.vouch_code = glob_rec_voucher.vouch_code 
		LET l_rec_voucherdist.line_num = glob_rec_voucher.line_num 
		INSERT INTO t_voucherdist VALUES (l_rec_voucherdist.*) 
	END IF 
	CLOSE WINDOW p231 
END FUNCTION 


############################################################
# FUNCTION cr_wo_dist(p_cmpy, p_kandoouser_sign_on_code, p_line_num)
#
#
############################################################
FUNCTION cr_wo_dist(p_cmpy,p_kandoouser_sign_on_code,p_line_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_line_num SMALLINT 
	DEFINE l_rec_ordhead RECORD LIKE ordhead.* 
	DEFINE l_name_text LIKE customer.name_text 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_cost_amt DECIMAL(16,2) 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_addcharge RECORD LIKE addcharge.* 
	DEFINE l_temp_text CHAR(60) 
	DEFINE l_mask_code LIKE warehouse.acct_mask_code 
	DEFINE l_winds_text,filter_text CHAR(80) 
	DEFINE l_outstdg_amt LIKE orderline.ext_price_amt 
	DEFINE l_status_ind LIKE orderline.status_ind 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_cost_amt = NULL 
	INITIALIZE l_rec_ordhead.* TO NULL 
	INITIALIZE l_rec_voucherdist.* TO NULL 
	INITIALIZE l_name_text TO NULL 
	INITIALIZE l_rec_coa.* TO NULL 
	SELECT * INTO l_rec_voucherdist.* FROM t_voucherdist 
	WHERE line_num = p_line_num 
	IF status != NOTFOUND THEN 
		LET l_cost_amt = l_rec_voucherdist.dist_amt 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_voucherdist.acct_code 
		AND cmpy_code = p_cmpy 
		SELECT * INTO l_rec_ordhead.* FROM ordhead 
		WHERE order_num = l_rec_voucherdist.po_num 
		AND cmpy_code = p_cmpy 
		IF status = 0 THEN 
			SELECT name_text INTO l_name_text FROM customer 
			WHERE cust_code = l_rec_ordhead.cust_code 
			AND cmpy_code = p_cmpy 
		END IF 
		# This next step IS an interim measure as we are changing what IS
		# stored in the voucherdist.desc_text FROM customer.name_text TO
		# addcharge.desc_code
		IF (l_rec_voucherdist.desc_text = l_name_text 
		OR l_rec_voucherdist.desc_text = l_rec_coa.desc_text) 
		AND l_rec_voucherdist.desc_text IS NOT NULL THEN 
			LET l_rec_voucherdist.desc_text = NULL 
		END IF 
	END IF 
	LET l_rec_addcharge.desc_code = l_rec_voucherdist.desc_text 
	IF l_rec_coa.analy_prompt_text IS NULL THEN 
		LET l_rec_coa.analy_prompt_text = "Analysis" 
	END IF 
	LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
	LET l_rec_coa.analy_prompt_text = l_temp_text 
	IF l_cost_amt IS NULL THEN 
		LET l_cost_amt = 0 
	END IF 

	OPEN WINDOW p506 with FORM "P506" 
	CALL windecoration_p("P506") 

	DISPLAY glob_rec_voucher.vend_code, 
	glob_rec_vendor.name_text, 
	glob_rec_voucher.vouch_code, 
	glob_rec_voucher.total_amt, 
	glob_rec_voucher.dist_amt 
	TO voucher.vend_code, 
	vendor.name_text, 
	voucher.vouch_code, 
	voucher.total_amt, 
	voucher.dist_amt 

	DISPLAY BY NAME l_rec_coa.analy_prompt_text 
	attribute(white) 
	DISPLAY l_rec_ordhead.cust_code, 
	l_name_text, 
	l_rec_ordhead.ship_addr1_text, 
	l_rec_ordhead.ship_addr2_text, 
	l_rec_ordhead.ship_city_text, 
	l_rec_ordhead.ord_text, 
	l_rec_ordhead.order_num, 
	l_rec_addcharge.desc_code, 
	l_rec_voucherdist.allocation_ind, 
	l_rec_voucherdist.acct_code, 
	l_rec_coa.desc_text , 
	l_rec_voucherdist.dist_amt, 
	l_rec_voucherdist.analysis_text, 
	l_rec_voucherdist.dist_qty, 
	l_rec_coa.uom_code 
	TO ordhead.cust_code, 
	customer.name_text, 
	ordhead.ship_addr1_text, 
	ordhead.ship_addr2_text, 
	ordhead.ship_city_text, 
	ordhead.ord_text, 
	ordhead.order_num, 
	addcharge.desc_code, 
	complete_flag, 
	voucherdist.acct_code, 
	coa.desc_text , 
	voucherdist.dist_amt, 
	voucherdist.analysis_text, 
	voucherdist.dist_qty, 
	coa.uom_code 

	INPUT l_rec_ordhead.order_num, 
	l_rec_addcharge.desc_code, 
	l_rec_voucherdist.allocation_ind, 
	l_rec_voucherdist.acct_code, 
	l_rec_voucherdist.dist_amt, 
	l_rec_voucherdist.analysis_text, 
	l_rec_voucherdist.dist_qty 
	WITHOUT DEFAULTS 
	FROM ordhead.order_num, 
	addcharge.desc_code, 
	complete_flag, 
	voucherdist.acct_code, 
	voucherdist.dist_amt, 
	voucherdist.analysis_text, 
	voucherdist.dist_qty 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P29b","inp-voucherdist-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (order_num) 
			LET filter_text = "ordhead.ord_ind in ('8','9') " 
			LET l_winds_text = show_mborders(p_cmpy,filter_text) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_ordhead.order_num = l_winds_text 
				NEXT FIELD ordhead.order_num 
			END IF 

		ON ACTION "LOOKUP" infield (acct_code) 
			LET l_winds_text = show_acct(p_cmpy) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_voucherdist.acct_code = l_winds_text 
				NEXT FIELD voucherdist.acct_code 
			END IF 

		ON ACTION "LOOKUP" infield (desc_code) 
			LET l_winds_text = show_addcharge(p_cmpy,"0") 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_addcharge.desc_code = l_winds_text 
				NEXT FIELD addcharge.desc_code 
			END IF 


		AFTER FIELD order_num 
			IF l_rec_ordhead.order_num IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9264,"") 
				#9264 Order Number must be entered
				NEXT FIELD ordhead.order_num 
			ELSE 
				SELECT * INTO l_rec_ordhead.* FROM ordhead 
				WHERE order_num = l_rec_ordhead.order_num 
				AND ord_ind in ("8","9") 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("W",9333,"") 
					#9333 No deliveries exist FOR this customer/ Order combination
					NEXT FIELD ordhead.order_num 
				END IF 
				SELECT name_text INTO l_name_text FROM customer 
				WHERE cust_code = l_rec_ordhead.cust_code 
				AND cmpy_code = p_cmpy 

				DISPLAY l_rec_ordhead.cust_code, 
				l_name_text, 
				l_rec_ordhead.ship_addr1_text, 
				l_rec_ordhead.ship_addr2_text, 
				l_rec_ordhead.ship_city_text, 
				l_rec_ordhead.ord_text 
				TO ordhead.cust_code, 
				customer.name_text, 
				ordhead.ship_addr1_text, 
				ordhead.ship_addr2_text, 
				ordhead.ship_city_text, 
				ordhead.ord_text 

			END IF 

		AFTER FIELD desc_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF l_rec_addcharge.desc_code IS NOT NULL THEN 
				SELECT * INTO l_rec_addcharge.* 
				FROM addcharge 
				WHERE desc_code = l_rec_addcharge.desc_code 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("W",9263,"") 
					#9263 Additional charge does NOT exist;  Try Window.
					NEXT FIELD desc_code 
				END IF 
				IF l_rec_addcharge.process_ind = 1 THEN 
					LET l_msgresp = kandoomsg("W",9955,"") 
					#9955 Cannot enter additional charge that IS automatically
					#     calculated.
					NEXT FIELD desc_code 
				END IF 
				DECLARE o_curs CURSOR FOR 
				SELECT line_num, ext_price_amt - ext_cost_amt, status_ind 
				INTO l_rec_voucherdist.po_line_num,l_outstdg_amt, l_status_ind 
				FROM orderline 
				WHERE order_num = l_rec_ordhead.order_num 
				AND part_code IS NULL 
				AND desc_text = l_rec_addcharge.desc_code 
				OPEN o_curs 
				FETCH o_curs 
				IF status = NOTFOUND 
				OR l_outstdg_amt IS NULL THEN 
					LET l_outstdg_amt = 0 
				END IF 
				CLOSE o_curs 
				IF (l_outstdg_amt <= 0 
				OR l_status_ind = "C" 
				OR l_status_ind IS null) 
				AND (l_rec_voucherdist.allocation_ind != "N" 
				OR l_rec_voucherdist.allocation_ind IS null) THEN 
					LET l_rec_voucherdist.allocation_ind = "Y" 
				ELSE 
					LET l_rec_voucherdist.allocation_ind = "N" 
				END IF 
				DISPLAY l_rec_voucherdist.allocation_ind 
				TO complete_flag 

				IF l_rec_voucherdist.acct_code IS NULL THEN 
					SELECT acct_mask_code INTO l_mask_code 
					FROM warehouse 
					WHERE ware_code = l_rec_ordhead.ware_code 
					AND cmpy_code = p_cmpy 
					LET l_rec_addcharge.sl_exp_code = build_mask(p_cmpy, l_mask_code, 
					l_rec_addcharge.sl_exp_code) 
					LET l_rec_voucherdist.acct_code = l_rec_addcharge.sl_exp_code 
					DISPLAY BY NAME l_rec_voucherdist.acct_code 

				END IF 
			END IF 

		BEFORE FIELD complete_flag 
			IF l_rec_addcharge.desc_code IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD complete_flag 
			IF l_rec_voucherdist.allocation_ind IS NULL 
			OR (l_rec_voucherdist.allocation_ind != "Y" 
			AND l_rec_voucherdist.allocation_ind != "N") THEN 
				LET l_msgresp = kandoomsg("G",9209,"") 
				#9209 Must be Y OR N
				NEXT FIELD complete_flag 
			END IF 
		AFTER FIELD acct_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF l_rec_voucherdist.acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9232,"") 
				#9232 An account code must be entered
				NEXT FIELD voucherdist.acct_code 
			ELSE 
				CALL verify_acct_code(p_cmpy,l_rec_voucherdist.acct_code, 
				glob_rec_voucher.year_num, 
				glob_rec_voucher.period_num) 
				RETURNING l_rec_coa.* 
				IF l_rec_coa.acct_code IS NULL THEN 
					NEXT FIELD acct_code 
				END IF 
				IF l_rec_voucherdist.acct_code != l_rec_coa.acct_code THEN 
					LET l_rec_voucherdist.acct_code = l_rec_coa.acct_code 
					NEXT FIELD acct_code 
				END IF 
				IF NOT acct_type(p_cmpy,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 
				IF l_rec_coa.analy_prompt_text IS NULL THEN 
					LET l_rec_coa.analy_prompt_text = "Analysis" 
				END IF 
				LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
				LET l_rec_coa.analy_prompt_text = l_temp_text 
				DISPLAY BY NAME l_rec_coa.analy_prompt_text 
				attribute(white) 
				DISPLAY BY NAME l_rec_coa.uom_code, l_rec_coa.desc_text 

			END IF 

		AFTER FIELD analysis_text 
			IF l_rec_voucherdist.analysis_text IS NULL 
			AND l_rec_coa.analy_req_flag = "Y" THEN 
				LET l_msgresp=kandoomsg("P",9016,"") 
				#9016 " Analysis IS required "
				NEXT FIELD voucherdist.analysis_text 
			END IF 
		AFTER FIELD dist_amt 
			IF l_rec_voucherdist.dist_amt IS NULL OR 
			l_rec_voucherdist.dist_amt <= 0 THEN 
				LET l_msgresp=kandoomsg("I",9085,"") 
				#9085 Must enter a value greater than zero
				NEXT FIELD voucherdist.dist_amt 
			END IF 

		AFTER FIELD dist_qty 
			IF l_rec_coa.uom_code IS NULL 
			AND l_rec_voucherdist.dist_qty IS NOT NULL 
			AND l_rec_voucherdist.dist_qty <> 0 THEN 
				LET l_msgresp=kandoomsg("P",9184,"") 
				#9184 Quantities are NOT collected FOR this Account Code
				LET l_rec_voucherdist.dist_qty = NULL 
				NEXT FIELD voucherdist.dist_qty 
			END IF 
			IF l_rec_coa.uom_code IS NOT NULL 
			AND l_rec_voucherdist.dist_qty IS NULL THEN 
				LET l_rec_voucherdist.dist_qty = 0 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			ELSE 
				IF l_rec_ordhead.order_num IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9264,"") 
					#9264 Order Number must be entered
					NEXT FIELD ordhead.order_num 
				END IF 
				SELECT * INTO l_rec_ordhead.* FROM ordhead 
				WHERE order_num = l_rec_ordhead.order_num 
				AND ord_ind in ("8","9") 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("W",9333,"") 
					#9333 No deliveries exist FOR this customer/ Order combination
					NEXT FIELD ordhead.order_num 
				END IF 
				IF l_rec_addcharge.desc_code IS NOT NULL THEN 
					SELECT * INTO l_rec_addcharge.* 
					FROM addcharge 
					WHERE desc_code = l_rec_addcharge.desc_code 
					AND cmpy_code = p_cmpy 
					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("W",9263,"") 
						#9263 Additional charge does NOT exist;  Try Window.
						NEXT FIELD addcharge.desc_code 
					END IF 
				END IF 
				IF l_rec_voucherdist.acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9232,"") 
					#9232 An account code must be entered
					NEXT FIELD voucherdist.acct_code 
				END IF 
				CALL verify_acct_code(p_cmpy,l_rec_voucherdist.acct_code, 
				glob_rec_voucher.year_num, 
				glob_rec_voucher.period_num) 
				RETURNING l_rec_coa.* 
				IF l_rec_coa.acct_code IS NULL THEN 
					NEXT FIELD acct_code 
				END IF 
				IF l_rec_voucherdist.acct_code != l_rec_coa.acct_code THEN 
					LET l_rec_voucherdist.acct_code = l_rec_coa.acct_code 
					NEXT FIELD acct_code 
				END IF 
				IF NOT acct_type(p_cmpy,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 
				IF l_rec_voucherdist.dist_amt IS NULL OR 
				l_rec_voucherdist.dist_amt <= 0 THEN 
					LET l_msgresp=kandoomsg("I",9085,"") 
					#9085 Must enter a value greater than zero
					NEXT FIELD voucherdist.dist_amt 
				END IF 
				IF l_rec_voucherdist.analysis_text IS NULL 
				AND l_rec_coa.analy_req_flag = "Y" THEN 
					LET l_msgresp=kandoomsg("P",9016,"") 
					#9016 " Analysis IS required "
					NEXT FIELD voucherdist.analysis_text 
				END IF 
				IF l_rec_coa.uom_code IS NOT NULL 
				AND l_rec_voucherdist.dist_qty IS NULL THEN 
					LET l_rec_voucherdist.dist_qty = 0 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW p506 
		RETURN 
	END IF 
	LET l_rec_voucherdist.type_ind = "W" 
	LET l_rec_voucherdist.desc_text = l_rec_addcharge.desc_code 
	IF l_rec_voucherdist.dist_qty IS NULL THEN 
		LET l_rec_voucherdist.dist_qty = 0 
	END IF 
	LET l_rec_voucherdist.po_num = l_rec_ordhead.order_num 
	LET l_rec_voucherdist.res_code = l_rec_ordhead.cust_code 
	LET l_rec_voucherdist.trans_qty = 0 
	LET l_rec_voucherdist.charge_amt = 0 

	UPDATE t_voucherdist 
	SET dist_qty = l_rec_voucherdist.dist_qty, 
	dist_amt = l_rec_voucherdist.dist_amt, 
	analysis_text = l_rec_voucherdist.analysis_text, 
	po_num = l_rec_ordhead.order_num, 
	type_ind = "W", 
	desc_text = l_rec_addcharge.desc_code, 
	trans_qty = 0, 
	charge_amt = 0, 
	res_code = l_rec_ordhead.cust_code, 
	acct_code = l_rec_voucherdist.acct_code, 
	allocation_ind = l_rec_voucherdist.allocation_ind 
	WHERE line_num = p_line_num 
	IF sqlca.sqlerrd[3] = 0 THEN 
		SELECT max(line_num) INTO glob_rec_voucher.line_num 
		FROM t_voucherdist 
		IF glob_rec_voucher.line_num IS NULL THEN 
			LET glob_rec_voucher.line_num = 1 
		ELSE 
			LET glob_rec_voucher.line_num = glob_rec_voucher.line_num + 1 
		END IF 
		LET l_rec_voucherdist.vouch_code = glob_rec_voucher.vouch_code 
		LET l_rec_voucherdist.line_num = glob_rec_voucher.line_num 
		LET l_rec_voucherdist.type_ind = "W" 
		LET l_rec_voucherdist.desc_text = l_rec_addcharge.desc_code 
		LET l_rec_voucherdist.res_code = l_rec_ordhead.cust_code 
		IF l_rec_voucherdist.dist_qty IS NULL THEN 
			LET l_rec_voucherdist.dist_qty = 0 
		END IF 
		LET l_rec_voucherdist.po_num = l_rec_ordhead.order_num 
		LET l_rec_voucherdist.trans_qty = 0 
		LET l_rec_voucherdist.charge_amt = 0 
		INSERT INTO t_voucherdist VALUES (l_rec_voucherdist.*) 
	END IF 
	CLOSE WINDOW p506 
END FUNCTION 


############################################################
# FUNCTION auto_dist_line(p_order_num)
#
#
############################################################
FUNCTION auto_dist_line(p_order_num) 
	DEFINE 
	p_order_num LIKE purchhead.order_num, 
	l_rec_purchhead RECORD LIKE purchhead.*, 
	l_rec_purchdetl RECORD LIKE purchdetl.*, 
	l_rec_poaudit RECORD LIKE poaudit.*, 
	l_rec_voucherdist RECORD LIKE voucherdist.*, 
	l_payment_amt LIKE poaudit.line_total_amt, 
	l_paid_amt LIKE poaudit.line_total_amt, 
	l_payment_qty LIKE poaudit.voucher_qty, 
	l_paid_qty LIKE poaudit.voucher_qty, 
	l_outstand_qty LIKE poaudit.voucher_qty, 
	l_outstand_amt LIKE poaudit.line_total_amt, 
	l_vouch_remain LIKE poaudit.order_qty, 
	l_commit_qty LIKE poaudit.order_qty 

	SELECT * INTO l_rec_purchhead.* FROM purchhead 
	WHERE cmpy_code = glob_rec_vendor.cmpy_code 
	AND order_num = p_order_num 
	DECLARE c2_purchdetl CURSOR FOR 
	SELECT * FROM purchdetl 
	WHERE cmpy_code = glob_rec_voucher.cmpy_code 
	AND vend_code = l_rec_purchhead.vend_code 
	AND order_num = p_order_num 
	ORDER BY 3,4 
	LET l_vouch_remain = glob_rec_voucher.total_amt - glob_rec_voucher.dist_amt 
	FOREACH c2_purchdetl INTO l_rec_purchdetl.* 
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
		IF glob_rec_voucher.vouch_code IS NULL THEN 
			LET l_commit_qty = 0 
		ELSE 
			LET l_commit_qty = 0 
			SELECT trans_qty INTO l_commit_qty FROM voucherdist 
			WHERE cmpy_code = glob_rec_voucher.cmpy_code 
			AND vend_code = glob_rec_voucher.vend_code 
			AND vouch_code = glob_rec_voucher.vouch_code 
			AND po_num = l_rec_purchdetl.order_num 
			AND po_line_num = l_rec_purchdetl.line_num 
		END IF 
		LET l_rec_poaudit.voucher_qty = l_rec_poaudit.voucher_qty - l_commit_qty 
		LET l_rec_poaudit.unit_cost_amt = l_rec_poaudit.unit_cost_amt 
		+ l_rec_poaudit.unit_tax_amt 
		SELECT trans_qty,dist_amt INTO l_paid_qty,l_paid_amt FROM t_podist 
		WHERE po_num = l_rec_purchdetl.order_num 
		AND po_line_num = l_rec_purchdetl.line_num 
		IF status = NOTFOUND THEN 
			LET l_paid_qty = 0 
			LET l_paid_amt = 0 
		END IF 
		LET l_outstand_qty = l_rec_poaudit.received_qty 
		- l_rec_poaudit.voucher_qty 
		- l_paid_qty 
		LET l_outstand_amt = l_rec_poaudit.unit_cost_amt 
		* l_outstand_qty 
		IF l_outstand_qty < 0 THEN 
			LET l_outstand_qty = 0 
		END IF 
		IF l_outstand_amt < 0 THEN 
			LET l_outstand_amt = 0 
		END IF 
		IF l_outstand_amt <= l_vouch_remain THEN 
			LET l_vouch_remain = l_vouch_remain - l_outstand_amt 
			LET l_payment_amt = l_paid_amt + l_outstand_amt 
			LET l_payment_qty = l_paid_qty + l_outstand_qty 
		ELSE 
			LET l_payment_amt = l_paid_amt + l_vouch_remain 
			LET l_payment_qty = l_payment_amt / l_rec_poaudit.unit_cost_amt 
			LET l_vouch_remain = 0 
		END IF 
		IF l_payment_qty > 0 THEN 
			UPDATE t_podist 
			SET dist_amt = l_payment_amt, 
			trans_qty = l_payment_qty, 
			cost_amt = l_payment_amt/l_payment_qty 
			WHERE po_num = p_order_num 
			AND po_line_num = l_rec_purchdetl.line_num 
			IF sqlca.sqlerrd[3] = 0 THEN 
				SELECT max(line_num) INTO glob_rec_voucher.line_num FROM t_podist 
				IF glob_rec_voucher.line_num IS NULL THEN 
					LET glob_rec_voucher.line_num = 1 
				ELSE 
					LET glob_rec_voucher.line_num = glob_rec_voucher.line_num + 1 
				END IF 
				LET l_rec_voucherdist.line_num = glob_rec_voucher.line_num 
				LET l_rec_voucherdist.type_ind = "P" 
				LET l_rec_voucherdist.acct_code = modu_rec_puparms.clear_acct_code 
				LET l_rec_voucherdist.desc_text = l_rec_purchdetl.desc_text 
				LET l_rec_voucherdist.dist_qty = 0 
				LET l_rec_voucherdist.dist_amt = l_payment_amt 
				LET l_rec_voucherdist.po_num = p_order_num 
				LET l_rec_voucherdist.po_line_num = l_rec_purchdetl.line_num 
				LET l_rec_voucherdist.trans_qty = l_payment_qty 
				LET l_rec_voucherdist.cost_amt = l_rec_voucherdist.dist_amt / 
				l_rec_voucherdist.trans_qty 
				LET l_rec_voucherdist.charge_amt = 0 
				INSERT INTO t_podist VALUES (l_rec_voucherdist.*) 
			END IF 
		END IF 
		IF l_vouch_remain = 0 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET glob_rec_voucher.dist_amt = glob_rec_voucher.total_amt - l_vouch_remain 

END FUNCTION 


