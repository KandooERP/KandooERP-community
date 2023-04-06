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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N4_GROUP_GLOBALS.4gl"
GLOBALS "../re/N42_GLOBALS.4gl"  
# \brief module N42a - Pending Purchase Order Line Item Authorisation



FUNCTION auth_lineitems(pr_pend_num) 
	DEFINE 
	pr_pend_num LIKE pendhead.pend_num, 
	pr_pendhead RECORD LIKE pendhead.*, 
	pr_penddetl RECORD LIKE penddetl.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_reqpurch RECORD 
		pend_num LIKE pendhead.pend_num, 
		vend_code LIKE pendhead.vend_code, 
		ware_code LIKE pendhead.ware_code, 
		part_code LIKE penddetl.part_code, 
		req_num INTEGER, 
		req_line_num INTEGER, 
		po_qty DECIMAL(12,4), 
		unit_cost_amt DECIMAL(10,2), 
		desc_text CHAR(40), 
		auth_ind SMALLINT, 
		req_alt_ind SMALLINT 
	END RECORD, 
	pa_penddetl ARRAY [100] OF RECORD 
		req_num LIKE penddetl.line_num, 
		req_line_num LIKE penddetl.req_line_num, 
		person_code LIKE reqhead.person_code, 
		part_code LIKE penddetl.part_code, 
		po_qty LIKE penddetl.po_qty, 
		unit_cost_amt LIKE reqdetl.unit_cost_amt, 
		total_cost_amt LIKE reqhead.total_cost_amt, 
		auth_flag CHAR(1) 
	END RECORD, 
	pr_total_pend_amt LIKE poaudit.line_total_amt, 
	pr_total_auth_amt LIKE poaudit.line_total_amt, 
	pr_toggle SMALLINT, 
	idx, scrn, cnt SMALLINT 

	SELECT pendhead.*, 
	vendor.name_text 
	INTO pr_pendhead.*, 
	pr_vendor.name_text 
	FROM pendhead, 
	vendor 
	WHERE pendhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pendhead.cmpy_code = vendor.cmpy_code 
	AND pendhead.vend_code = vendor.vend_code 
	AND pendhead.pend_num = pr_pend_num 
	IF status = notfound THEN 
		error" Pending Purchase Order Number does NOT Exist " 
		RETURN 
	END IF 
	DECLARE c1_reqpurch CURSOR FOR 
	SELECT reqpurch.* 
	FROM reqpurch 
	WHERE pend_num = pr_pendhead.pend_num 
	ORDER BY req_num, 
	req_line_num 
	LET idx = 0 
	FOREACH c1_reqpurch INTO pr_reqpurch.* 
		LET idx = idx + 1 
		LET pa_penddetl[idx].req_num = pr_reqpurch.req_num 
		LET pa_penddetl[idx].req_line_num = pr_reqpurch.req_line_num 
		LET pa_penddetl[idx].part_code = pr_reqpurch.part_code 
		LET pa_penddetl[idx].po_qty = pr_reqpurch.po_qty 
		LET pa_penddetl[idx].unit_cost_amt = pr_reqpurch.unit_cost_amt 
		LET pa_penddetl[idx].total_cost_amt = pr_reqpurch.unit_cost_amt 
		* pr_reqpurch.po_qty 
		SELECT person_code 
		INTO pa_penddetl[idx].person_code 
		FROM reqhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND req_num = pr_reqpurch.req_num 
		IF pr_reqpurch.auth_ind THEN 
			LET pa_penddetl[idx].auth_flag = "*" 
		ELSE 
			LET pa_penddetl[idx].auth_flag = NULL 
		END IF 
		IF idx = 100 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	SELECT sum(po_qty * unit_cost_amt) 
	INTO pr_total_pend_amt 
	FROM reqpurch 
	WHERE pend_num = pr_pendhead.pend_num 
	SELECT sum(po_qty * unit_cost_amt) 
	INTO pr_total_auth_amt 
	FROM reqpurch 
	WHERE pend_num = pr_pendhead.pend_num 
	AND auth_ind = 1 
	IF pr_total_pend_amt IS NULL THEN 
		LET pr_total_pend_amt = 0 
	END IF 
	IF pr_total_auth_amt IS NULL THEN 
		LET pr_total_auth_amt = 0 
	END IF 
	OPEN WINDOW n120 with FORM "N120" 
	CALL windecoration_n("N120") -- albo kd-763 
	DISPLAY BY NAME pr_pendhead.pend_num, 
	pr_pendhead.vend_code, 
	pr_vendor.name_text, 
	pr_total_pend_amt, 
	pr_total_auth_amt 

	LET msgresp = kandoomsg("P",1514,"") 
	#1514 Line Authorisation; F7 Toggle Line; F8 Toggle All; F10 Change Amounts.
	CALL set_count(idx) 

	DISPLAY ARRAY pa_penddetl TO sr_penddetl.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","N42a","display-arr-penddetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F7) 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF pa_penddetl[idx].auth_flag IS NULL THEN 
				UPDATE reqpurch 
				SET auth_ind = 1 
				WHERE pend_num = pr_pendhead.pend_num 
				AND req_num = pa_penddetl[idx].req_num 
				AND req_line_num = pa_penddetl[idx].req_line_num 
				LET pa_penddetl[idx].auth_flag = "*" 
			ELSE 
				UPDATE reqpurch 
				SET auth_ind = 0 
				WHERE pend_num = pr_pendhead.pend_num 
				AND req_num = pa_penddetl[idx].req_num 
				AND req_line_num = pa_penddetl[idx].req_line_num 
				LET pa_penddetl[idx].auth_flag = NULL 
			END IF 
			SELECT sum(po_qty * unit_cost_amt) 
			INTO pr_total_auth_amt 
			FROM reqpurch 
			WHERE pend_num = pr_pendhead.pend_num 
			AND auth_ind = 1 
			IF pr_total_auth_amt IS NULL THEN 
				LET pr_total_auth_amt = 0 
			END IF 
			DISPLAY BY NAME pr_total_auth_amt 

			DISPLAY pa_penddetl[idx].auth_flag 
			TO sr_penddetl[scrn].auth_flag 

		ON KEY (F8) 
			IF pr_toggle THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_penddetl[idx].auth_flag IS NOT NULL THEN 
						UPDATE reqpurch 
						SET auth_ind = 0 
						WHERE pend_num = pr_pendhead.pend_num 
						AND req_num = pa_penddetl[idx].req_num 
						AND req_line_num = pa_penddetl[idx].req_line_num 
						LET pa_penddetl[idx].auth_flag = NULL 
					END IF 
				END FOR 
				LET pr_toggle = false 
			ELSE 
				FOR idx = 1 TO arr_count() 
					IF pa_penddetl[idx].auth_flag IS NULL THEN 
						UPDATE reqpurch 
						SET auth_ind = 1 
						WHERE pend_num = pr_pendhead.pend_num 
						AND req_num = pa_penddetl[idx].req_num 
						AND req_line_num = pa_penddetl[idx].req_line_num 
						LET pa_penddetl[idx].auth_flag = "*" 
					END IF 
				END FOR 
				LET pr_toggle = true 
			END IF 
			FOR scrn = 1 TO 9 
				LET idx = arr_curr() - scr_line() + scrn 
				IF idx <= arr_count() THEN 
					DISPLAY pa_penddetl[idx].auth_flag 
					TO sr_penddetl[scrn].auth_flag 

				ELSE 
					EXIT FOR 
				END IF 
			END FOR 
			SELECT sum(po_qty * unit_cost_amt) 
			INTO pr_total_auth_amt 
			FROM reqpurch 
			WHERE pend_num = pr_pendhead.pend_num 
			AND auth_ind = 1 
			IF pr_total_auth_amt IS NULL THEN 
				LET pr_total_auth_amt = 0 
			END IF 
			DISPLAY BY NAME pr_total_auth_amt 

		ON KEY (F10) 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_penddetl[idx].po_qty, 
			pa_penddetl[idx].unit_cost_amt, 
			pa_penddetl[idx].total_cost_amt 
			TO sr_penddetl[scrn].po_qty, 
			sr_penddetl[scrn].unit_cost_amt, 
			sr_penddetl[scrn].total_cost_amt 

			LET cnt = 8 + scrn 
			OPEN WINDOW n121 with FORM "N121" 
			CALL windecoration_n("N121") -- albo kd-763 
			IF change_amount(pr_pendhead.pend_num, 
			pa_penddetl[idx].req_num, 
			pa_penddetl[idx].req_line_num) THEN 
				SELECT po_qty, 
				unit_cost_amt, 
				(unit_cost_amt * po_qty) 
				INTO pa_penddetl[idx].po_qty, 
				pa_penddetl[idx].unit_cost_amt, 
				pa_penddetl[idx].total_cost_amt 
				FROM reqpurch 
				WHERE pend_num = pr_pendhead.pend_num 
				AND req_num = pa_penddetl[idx].req_num 
				AND req_line_num = pa_penddetl[idx].req_line_num 
			END IF 
			CLOSE WINDOW n121 
			SELECT sum(po_qty * unit_cost_amt) 
			INTO pr_total_pend_amt 
			FROM reqpurch 
			WHERE pend_num = pr_pendhead.pend_num 
			SELECT sum(po_qty * unit_cost_amt) 
			INTO pr_total_auth_amt 
			FROM reqpurch 
			WHERE pend_num = pr_pendhead.pend_num 
			AND auth_ind = 1 
			IF pr_total_pend_amt IS NULL THEN 
				LET pr_total_pend_amt = 0 
			END IF 
			IF pr_total_auth_amt IS NULL THEN 
				LET pr_total_auth_amt = 0 
			END IF 
			DISPLAY BY NAME pr_total_pend_amt, 
			pr_total_auth_amt 

			DISPLAY pa_penddetl[idx].* 
			TO sr_penddetl[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END DISPLAY 
	CLOSE WINDOW n120 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		UPDATE reqpurch 
		SET auth_ind = 0 
		WHERE pend_num = pr_pendhead.pend_num 
	END IF 
END FUNCTION 


FUNCTION change_amount(pr_pend_num,pr_req_num,pr_line_num) 
	DEFINE 
	pr_pend_num LIKE penddetl.pend_num, 
	pr_req_num LIKE penddetl.req_num, 
	pr_line_num LIKE penddetl.line_num, 
	pr_penddetl RECORD LIKE penddetl.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_reqpurch RECORD 
		pend_num LIKE pendhead.pend_num, 
		vend_code LIKE pendhead.vend_code, 
		ware_code LIKE pendhead.ware_code, 
		part_code LIKE penddetl.part_code, 
		req_num INTEGER, 
		req_line_num INTEGER, 
		po_qty DECIMAL(12,4), 
		unit_cost_amt DECIMAL(10,2), 
		desc_text CHAR(40), 
		auth_ind SMALLINT, 
		req_alt_ind SMALLINT 
	END RECORD, 
	pr_total_cost_amt LIKE poaudit.line_total_amt 

	SELECT reqpurch.* 
	INTO pr_reqpurch.* 
	FROM reqpurch 
	WHERE pend_num = pr_pend_num 
	AND req_num = pr_req_num 
	AND req_line_num = pr_line_num 
	SELECT * 
	INTO pr_penddetl.* 
	FROM penddetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pend_num = pr_pend_num 
	AND req_num = pr_req_num 
	AND req_line_num = pr_line_num 
	SELECT * 
	INTO pr_reqdetl.* 
	FROM reqdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND req_num = pr_req_num 
	AND line_num = pr_line_num 
	INPUT BY NAME pr_reqpurch.po_qty, 
	pr_reqpurch.unit_cost_amt WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD po_qty 
			LET pr_total_cost_amt = pr_reqpurch.po_qty 
			* pr_reqpurch.unit_cost_amt 
			DISPLAY BY NAME pr_total_cost_amt 

		AFTER FIELD po_qty 
			IF pr_reqpurch.po_qty IS NULL THEN 
				LET pr_reqpurch.po_qty = pr_penddetl.po_qty 
				NEXT FIELD po_qty 
			END IF 
			IF pr_reqpurch.po_qty <= 0 THEN 
				error" Requisition Quantity must be Greater than Zero " 
				LET pr_reqpurch.po_qty = pr_penddetl.po_qty 
				NEXT FIELD po_qty 
			END IF 
			IF pr_reqpurch.po_qty > pr_penddetl.po_qty THEN 
				error" Requisition Quantity cannot be greater than ", 
				pr_penddetl.po_qty USING "######.##"," " 
				LET pr_reqpurch.po_qty = pr_penddetl.po_qty 
				NEXT FIELD po_qty 
			END IF 
			LET pr_total_cost_amt = pr_reqpurch.po_qty 
			* pr_reqpurch.unit_cost_amt 
			DISPLAY BY NAME pr_total_cost_amt 

		AFTER FIELD unit_cost_amt 
			IF pr_reqpurch.unit_cost_amt IS NULL THEN 
				LET pr_reqpurch.unit_cost_amt = pr_reqdetl.unit_cost_amt 
				NEXT FIELD unit_cost_amt 
			END IF 
			IF pr_reqpurch.unit_cost_amt <= 0 THEN 
				error" Requisition Quantity must be Greater than Zero " 
				LET pr_reqpurch.unit_cost_amt = pr_reqdetl.unit_cost_amt 
				NEXT FIELD unit_cost_amt 
			END IF 
			LET pr_total_cost_amt = pr_reqpurch.po_qty 
			* pr_reqpurch.unit_cost_amt 
			DISPLAY BY NAME pr_total_cost_amt 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET pr_reqpurch.po_qty = pr_penddetl.po_qty 
				LET pr_reqpurch.unit_cost_amt = pr_reqdetl.unit_cost_amt 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF pr_reqpurch.po_qty = pr_penddetl.po_qty 
	AND pr_reqpurch.unit_cost_amt = pr_reqdetl.unit_cost_amt THEN 
		RETURN false 
	ELSE 
		UPDATE reqpurch 
		SET req_alt_ind = 1, 
		po_qty = pr_reqpurch.po_qty, 
		unit_cost_amt = pr_reqpurch.unit_cost_amt 
		WHERE pend_num = pr_pend_num 
		AND req_num = pr_req_num 
		AND req_line_num = pr_line_num 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION disp_mess(pr_disp_mess) 
	DEFINE 
	pr_disp_mess CHAR(70), 
	ans CHAR(1), 
	i SMALLINT 

	LET i = (70 - length(pr_disp_mess))/2 
	IF i < 1 THEN LET i = 1 END IF 
		{
		   OPEN WINDOW w1_N42 AT 10,6 with 2 rows,70 columns    -- albo  KD-763
		      attributes(border, red, prompt line last)
		}
		DISPLAY pr_disp_mess clipped at 3,i 
		attribute(red) 
		--   prompt "                       Any Key TO Continue " FOR CHAR ans  -- albo
		--      ATTRIBUTE(red)
		CALL eventsuspend() --LET ans = AnyKey(" Any key TO continue ",14,25) -- albo 
		LET int_flag = false 
		LET quit_flag = false 
		--   CLOSE WINDOW w1_N42     -- albo  KD-763
END FUNCTION 


FUNCTION response(pr_disp_message) 
	DEFINE 
	pr_disp_message CHAR(60), 
	ans CHAR(1), 
	x INTEGER 

	LET x = length(pr_disp_message) + 5 
	{
	   OPEN WINDOW w1_N42a AT 15,10 with 1 rows,x columns     -- albo  KD-763
	      ATTRIBUTE(border)
	}
	PROMPT pr_disp_message clipped FOR CHAR ans 
	attribute(yellow) 
	--   CLOSE WINDOW w1_N42a    -- albo  KD-763
	LET int_flag = false 
	LET quit_flag = false 
	IF upshift(ans) = "Y" THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 
