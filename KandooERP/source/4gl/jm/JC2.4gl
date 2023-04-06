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

	Source code beautified by beautify.pl on 2020-01-02 19:48:21	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"
#used as GLOBALS FROM Jc2a.4gl

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC2_GLOBALS.4gl" 

# Purpose: Credits a JM credit note TO be edited

MAIN 
	DEFINE 
	pt_invoicehead RECORD LIKE invoicehead.*, 
	tmp_idx SMALLINT, 
	pr_temp_text CHAR(400), 
	pr_cred_num LIKE credithead.cred_num 

	#Initial UI Init
	CALL setModuleId("JC2") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	LET pr_kandoooption_sn = get_kandoooption_feature_state("JM","SN") 
	SELECT credit_ref2a_text, 
	credit_ref2b_text INTO pr_arparms.credit_ref2a_text, 
	pr_arparms.credit_ref2b_text 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	CREATE temp TABLE statab(cmpy_code CHAR(2), 
	ware CHAR(3), 
	part CHAR(15), 
	ship DECIMAL(12, 3), 
	which CHAR(3)) 
	with no LOG 
	SELECT jmparms.* INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		#ERROR " Must SET up JM Parameters first in JZP"
		EXIT program 
	END IF 
	SELECT glparms.* INTO pr_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("G",7006,"") 
		#ERROR " Must SET up GL Parameters first in GZP"
		EXIT program 
	END IF 
	SELECT arparms.* INTO pr_arparms.* 
	FROM arparms 
	WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND arparms.parm_code = "1" 
	IF status = notfound THEN 
		#ERROR " Must SET up AR Parameters first in AZP"
		LET msgresp = kandoomsg("A",7005,"") 
		EXIT program 
	END IF 
	CALL create_temp1() 
	LET pv_corp_cust = false 
	LET display_inv_num = "N" 


	LET pr_temp_text = NULL 
	WHILE select_credit(pr_temp_text) 
		CALL scan_credit() 
		RETURNING pr_cred_num 

		IF pr_cred_num = 0 THEN 
			EXIT WHILE 
		END IF 
		LET tmp_idx = idx 
		LET func_type = "Credit Edit" 
		LET f_type = "J" {treat LIKE an edit} 
		LET first_time = 1 
		LET noerror = 1 
		LET display_cred_num = "N" 
		DELETE 
		FROM statab 
		WHERE 1 = 1 
		CALL edit_credit(pr_cred_num) 
		LET pr_temp_text = NULL 
	END WHILE 


END MAIN 

FUNCTION select_credit(where_text) 
	DEFINE 
	where_text CHAR(300), 
	query_text CHAR(400) 
	OPEN WINDOW j665 with FORM "J665" -- alch kd-747 
	CALL winDecoration_j("J665") -- alch kd-747 
	CLEAR FORM 
	DISPLAY BY NAME pr_arparms.credit_ref1_text attribute(white) 
	IF where_text IS NULL THEN 
		LET msgresp = kandoomsg("E",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue "
		CONSTRUCT BY NAME where_text ON 
		cred_num, 
		cred_date, 
		cust_code, 
		cred_text, 
		year_num, 
		period_num, 
		job_code, 
		total_amt 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","JC2","const-cred_num-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 
	END IF 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("E",1002,"") 
		#1002 " Searching database - please wait "
		LET query_text = "SELECT * FROM credithead ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND credithead.posted_flag = 'N' ", 
		"AND credithead.job_code != ' ' ", 
		"AND credithead.job_code IS NOT NULL ", 
		"AND ",where_text clipped," ", 
		"ORDER BY cred_num" 
		PREPARE s_credithead FROM query_text 
		DECLARE c_credithead CURSOR FOR s_credithead 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_credit() 
	DEFINE 
	pr_cred_num LIKE credithead.cred_num, 
	pr_scroll_flag CHAR(1), 
	pr_customer RECORD LIKE customer.*, 
	pr_credithead RECORD LIKE credithead.*, 
	pr_creditdetl RECORD LIKE creditdetl.*, 
	i,j,idx,scrn SMALLINT 

	LET idx = 0 
	FOREACH c_credithead INTO pr_credithead.* 
		LET idx = idx + 1 
		LET pa_credithead[idx].scroll_flag = NULL 
		LET pa_credithead[idx].cred_num = pr_credithead.cred_num 
		LET pa_credithead[idx].cred_date = pr_credithead.cred_date 
		LET pa_credithead[idx].cust_code = pr_credithead.cust_code 
		SELECT name_text INTO pa_credithead[idx].name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_credithead.cust_code 
		IF sqlca.sqlcode = notfound THEN 
			LET pa_credithead[idx].name_text = "**********" 
		END IF 
		LET pa_credithead[idx].cred_text = pr_credithead.cred_text 
		IF idx = 200 THEN 
			LET msgresp = kandoomsg("E",9212,"200") 
			#9212 First 200 credit selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("E",9213,"") 
		#9213" No Credits Satisfied Selection Criteria "
		LET idx = 1 
		INITIALIZE pa_credithead[idx].* TO NULL 
	END IF 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("E",1068,"") 
	#1068" F1 TO Add - F2 TO Cancel - RETURN TO Edit"
	INPUT ARRAY pa_credithead WITHOUT DEFAULTS FROM sr_credithead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JC2","input_arr-pa_credithead-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_credithead[idx].scroll_flag 
			CALL disp_credit(pa_credithead[idx].cred_num) 
			DISPLAY pa_credithead[idx].* 
			TO sr_credithead[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_credithead[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_credithead[idx].scroll_flag 
			TO sr_credithead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() 
				OR pa_credithead[idx+1].cust_code IS NULL THEN 
					LET msgresp=kandoomsg("E",9001,"") 
					#9001 There are no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		AFTER ROW 
			DISPLAY pa_credithead[idx].* 
			TO sr_credithead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON KEY (accept) 
			RETURN pa_credithead[idx].cred_num 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT INPUT 
		ON KEY (tab) 
			RETURN pa_credithead[idx].cred_num 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT INPUT 
		ON KEY (interrupt) 
			RETURN 0 
			LET int_flag = true 
			LET quit_flag = true 
			EXIT INPUT 
	END INPUT 
END FUNCTION 

FUNCTION disp_credit(pr_cred_num) 
	DEFINE 
	pr_cred_num LIKE credithead.cred_num, 
	pr_credithead RECORD LIKE credithead.*, 
	pr_org_name_text LIKE customer.name_text 

	SELECT * INTO pr_credithead.* 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num = pr_cred_num 
	IF status = notfound THEN 
		CLEAR year_num, 
		period_num, 
		total_amt, 
		job_code 
	ELSE 
		SELECT name_text INTO pr_org_name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_credithead.cust_code 
		IF status = notfound THEN 
			LET pr_org_name_text = "**********" 
		END IF 
		DISPLAY BY NAME pr_credithead.year_num, 
		pr_credithead.period_num, 
		pr_credithead.total_amt, 
		pr_credithead.job_code 

	END IF 
END FUNCTION 





FUNCTION edit_credit(pr_cred_num) 

	DEFINE 
	pr_cred_num LIKE credithead.cred_num, 
	rtn_value SMALLINT 

	SELECT * INTO pr_credithead.* 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num = pr_cred_num 

	LET pr_prev_head.* = pr_credithead.* 

	SELECT * INTO pr_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_credithead.rma_num 

	CALL get_jm_info() RETURNING rtn_value 

	SELECT sum(total_amt)INTO pr_cred_sum 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rma_num = pr_credithead.rma_num 

	LET pr_uncredited_amt = pr_invoicehead.total_amt - pr_cred_sum 
	LET allow_update = true 

	SELECT * INTO pr_job.* 
	FROM job 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_invoicehead.job_code 

	SELECT * INTO pr_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_credithead.cust_code 
	IF pr_customer.corp_cust_code IS NOT NULL THEN 
		LET pv_corp_cust = true 
		SELECT * INTO pr_corp_cust.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_customer.corp_cust_code 
	ELSE 
		LET pv_corp_cust = false 
	END IF 

	IF cnt > 0 THEN 
		LET t = 1 
		FOR t = t TO cnt 
		END FOR 
	END IF 
	INITIALIZE pr_creditdetl.* TO NULL 
	FOR i = 1 TO 300 
		INITIALIZE pa_taxamt[i].tax_code TO NULL 
	END FOR 
	OPEN WINDOW wa127 with FORM "A127" -- alch kd-747 
	CALL winDecoration_a("A127") -- alch kd-747 
	WHILE JC2_header() 
		WHILE lineitem() 
			IF summup() THEN 
				CALL write_cred() 
				LET msgresp = kandoomsg("J",1559,pr_credithead.cred_num) 
				CLOSE WINDOW wa127 
				RETURN 
			END IF 
		END WHILE 
	END WHILE 
	CLOSE WINDOW wa127 
END FUNCTION 














































FUNCTION create_temp1() 
	CREATE temp TABLE tempbill(trans_invoice_flag CHAR(1), 
	trans_date DATE NOT NULL , 
	var_code SMALLINT NOT null, 
	activity_code CHAR(8) NOT null, 
	seq_num INTEGER, 
	line_num SMALLINT, 
	trans_type_ind CHAR(2), 
	trans_source_num INTEGER, 
	trans_source_text CHAR(8), 
	trans_amt DECIMAL(16, 2) , 
	trans_qty FLOAT, 
	charge_amt DECIMAL(16, 2), 
	apply_qty FLOAT, 
	apply_amt DECIMAL(16, 2), 
	apply_cos_amt DECIMAL(16, 2), 
	desc_text CHAR (40), 
	prev_apply_qty FLOAT, 
	prev_apply_amt DECIMAL(16, 2), 
	prev_apply_cos_amt DECIMAL(16, 2), 
	arr_line_num SMALLINT, 
	allocation_ind CHAR (1), 
	goods_rec_num INTEGER, 
	part_code CHAR(25), 
	serial_flag CHAR(1), 
	store_qty FLOAT 
	) 
	with no LOG 
	CREATE unique INDEX tempbill ON tempbill(var_code, activity_code, seq_num) 
END FUNCTION 
