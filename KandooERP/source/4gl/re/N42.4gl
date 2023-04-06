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

############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N42 - Internal Requisition Purchase Order Authorization
############################################################
MAIN 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
	DEFINE pr_print_cmd CHAR(300) 
	DEFINE pr_output CHAR(25) 
	DEFINE pr_first_ponum LIKE puparms.next_po_num 
	DEFINE pr_last_ponum LIKE puparms.next_po_num 
	DEFINE pr_po_cnt, invalid_period SMALLINT 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N42") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	SELECT * INTO pr_puparms.* FROM puparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("N",5018,"") 
		#5018 Purchasing Parameters Not Set Up;  Refer Menu RZP.
		EXIT program 
	END IF 
	
	CREATE temp TABLE reqpurch (pend_num INTEGER, 
	vend_code CHAR(8), 
	ware_code CHAR(3), 
	part_code CHAR(15), 
	req_num INTEGER, 
	req_line_num INTEGER, 
	po_qty DECIMAL(12,4), 
	unit_cost_amt DECIMAL(10,2), 
	desc_text CHAR(40), 
	auth_ind SMALLINT, 
	req_alt_ind smallint) with no LOG 
	CREATE unique INDEX reqpurch1_key 
	ON reqpurch(pend_num,req_num,req_line_num) 
	CREATE INDEX reqpurch2_key 
	ON reqpurch(vend_code,ware_code) 
	OPEN WINDOW n119 with FORM "N119" 
	CALL windecoration_n("N119") -- albo kd-763 

	SELECT reqperson.* INTO pr_reqperson.* FROM reqperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND person_code = glob_rec_kandoouser.sign_on_code 
	CASE 
		WHEN status = notfound 
			SELECT kandoouser.name_text INTO pr_rec_kandoouser.name_text FROM kandoouser 
			WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET err_message = " User ",pr_rec_kandoouser.name_text clipped, 
			" NOT SET up FOR Internal Reqisitions " 
		WHEN pr_reqperson.po_low_limit_amt IS NULL 
			OR pr_reqperson.po_up_limit_amt IS NULL 
			OR pr_reqperson.po_up_limit_amt <= 0 
			LET err_message = " Person ",pr_reqperson.name_text clipped, 
			" has no Purchase Order Authority " 
		WHEN pr_reqperson.po_start_date > today 
			LET err_message =" Person ",pr_reqperson.name_text clipped, 
			" Purchase Order Authority NOT yet valid " 
		WHEN pr_reqperson.po_exp_date < today 
			LET err_message =" Person ",pr_reqperson.name_text clipped, 
			" Purchase Order Authority has Expired " 
		OTHERWISE 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
			RETURNING pr_period.year_num, 
			pr_period.period_num 
			CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_period.year_num, 
			pr_period.period_num,"PU") 
			RETURNING pr_period.year_num, 
			pr_period.period_num, 
			invalid_period 
			IF invalid_period THEN 
				LET err_message = 
				" Current Purchasing Fiscal Year & Period Not Set Up" 
			END IF 
	END CASE 
	IF err_message IS NOT NULL THEN 
		CALL disp_mess(err_message) 
	ELSE 
		WHILE select_pend() 
			IF scan_pend() THEN 
				CALL write_purchord() 
				RETURNING pr_po_cnt 
				LET err_message = NULL 
				IF glob_rec_reqparms.auto_po_flag = "Y" AND pr_po_cnt > 0 THEN 
					LET pr_first_ponum = pr_puparms.next_po_num - pr_po_cnt 
					LET pr_last_ponum = pr_puparms.next_po_num - 1 
					LET err_message = " purchhead.order_num between \"", 
					pr_first_ponum USING "#<<<<<<<","\" AND \"", 
					pr_last_ponum USING "#<<<<<<<","\" " 
					CALL print_po(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,err_message) 
					RETURNING pr_output 
					SELECT * INTO pr_printcodes.* FROM printcodes 
					WHERE print_code = glob_rec_reqparms.po_print_text 
					IF status = false THEN 
						LET pr_print_cmd = 
						" F=",pr_output clipped," ;C=1 ", 
						" ;L=66 ;W=80 ", 
						" ;",pr_printcodes.print_text clipped, 
						" 2>>", trim(get_settings_logFile()) 
						RUN pr_print_cmd 
						LET err_message = 
						" Printing ",pr_po_cnt USING "#<<<<", 
						" Purchase Order/s on Device ", 
						pr_printcodes.desc_text clipped 
					ELSE 
						LET err_message = NULL 
					END IF 
				END IF 
				IF err_message IS NULL THEN 
					LET err_message = 
					" Successful Generation of ",pr_po_cnt USING "#<<", 
					" Purchase Orders " 
				END IF 
				CALL disp_mess(err_message) 
			END IF 
			DELETE FROM reqpurch WHERE 1=1 
		END WHILE 
	END IF 
	CLOSE WINDOW n119 
END MAIN 


FUNCTION select_pend() 
	DEFINE 
	pr_pendhead RECORD LIKE pendhead.*, 
	pr_penddetl RECORD LIKE penddetl.*, 
	pr_tot_po_amt LIKE poaudit.line_total_amt, 
	pr_auth_amt LIKE poaudit.line_total_amt, 
	pr_unit_cost_amt LIKE poaudit.line_total_amt, 
	where_text CHAR(500), 
	query_text CHAR(800), 
	idx SMALLINT 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	WHILE true 
		CLEAR FORM 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME where_text ON pendhead.pend_num, 
		pendhead.vend_code, 
		pendhead.order_date, 
		pendhead.entry_code, 
		pendhead.ware_code 
			ON ACTION "WEB-HELP" -- albo kd-377 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database;  Please wait.
		LET query_text = 
		"SELECT pendhead.* ", 
		"FROM pendhead ", 
		"WHERE pendhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",where_text clipped," ", 
		"ORDER BY pendhead.cmpy_code,", 
		"pendhead.pend_num" 
		PREPARE s_pendhead FROM query_text 
		DECLARE c_pendhead CURSOR FOR s_pendhead 
		LET idx = 0 
		FOREACH c_pendhead INTO pr_pendhead.* 
			SELECT sum(penddetl.po_qty * reqdetl.unit_cost_amt ), 
			sum(penddetl.auth_po_qty * reqdetl.unit_cost_amt) 
			INTO pr_tot_po_amt, 
			pr_auth_amt 
			FROM penddetl, 
			reqdetl 
			WHERE penddetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND penddetl.pend_num = pr_pendhead.pend_num 
			AND penddetl.cmpy_code = reqdetl.cmpy_code 
			AND penddetl.req_num = reqdetl.req_num 
			AND penddetl.req_line_num = reqdetl.line_num 
			AND penddetl.po_qty > penddetl.auth_po_qty 
			IF pr_tot_po_amt IS NULL THEN 
				LET pr_tot_po_amt = 0 
			END IF 
			IF pr_auth_amt IS NULL THEN 
				LET pr_auth_amt = 0 
			END IF 
			IF pr_auth_amt = pr_tot_po_amt 
			OR pr_tot_po_amt < pr_reqperson.po_low_limit_amt 
			OR pr_tot_po_amt > pr_reqperson.po_up_limit_amt THEN 
				CONTINUE FOREACH 
			END IF 
			DECLARE c_reqdetl CURSOR FOR 
			SELECT penddetl.*, 
			reqdetl.unit_cost_amt 
			FROM penddetl, 
			reqdetl 
			WHERE penddetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND penddetl.cmpy_code = reqdetl.cmpy_code 
			AND penddetl.req_num = reqdetl.req_num 
			AND penddetl.req_line_num = reqdetl.line_num 
			AND penddetl.pend_num = pr_pendhead.pend_num 
			AND penddetl.po_qty > penddetl.auth_po_qty 
			FOREACH c_reqdetl INTO pr_penddetl.*, 
				pr_unit_cost_amt 
				INSERT INTO reqpurch VALUES (pr_pendhead.pend_num, 
				pr_pendhead.vend_code, 
				pr_pendhead.ware_code, 
				pr_penddetl.part_code, 
				pr_penddetl.req_num, 
				pr_penddetl.req_line_num, 
				pr_penddetl.po_qty, 
				pr_unit_cost_amt, 
				pr_penddetl.desc_text, 0, 0) 
			END FOREACH 
			LET idx = idx + 1 
			LET pa_pendhead[idx].pend_num = pr_pendhead.pend_num 
			LET pa_pendhead[idx].vend_code = pr_pendhead.vend_code 
			LET pa_pendhead[idx].order_date = pr_pendhead.order_date 
			LET pa_pendhead[idx].entry_code = pr_pendhead.entry_code 
			LET pa_pendhead[idx].ware_code = pr_pendhead.ware_code 
			LET pa_pendhead[idx].auth_amt = pr_auth_amt 
			LET pa_pendhead[idx].tot_po_amt = pr_tot_po_amt 
			IF idx = 200 THEN 
				LET msgresp = kandoomsg("U",6100,idx) 
				#6100 First 200 records selected only.  More may be available.
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF idx = 0 THEN 
			LET msgresp = kandoomsg("U",9101,"") 
			#9101 No records satisfied selection criteria.
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET arr_size = idx 
	RETURN true 
END FUNCTION 


FUNCTION scan_pend() 
	DEFINE 
	pr_pendhead RECORD LIKE pendhead.*, 
	idx,scrn SMALLINT 

	LET msgresp = kandoomsg("P",1513,"") 
	#1513 Pending Purchase Orders;  ENTER on line TO Edit;  F8 TO Authorise.
	CALL set_count(arr_size) 
	INPUT ARRAY pa_pendhead WITHOUT DEFAULTS FROM sr_pendhead.* 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (F8) 
			IF pr_pendhead.pend_num IS NOT NULL THEN 
				IF pa_pendhead[idx].auth_amt = pa_pendhead[idx].tot_po_amt THEN 
					UPDATE reqpurch 
					SET auth_ind = 0 
					WHERE pend_num = pr_pendhead.pend_num 
				ELSE 
					UPDATE reqpurch 
					SET auth_ind = 1 
					WHERE pend_num = pr_pendhead.pend_num 
				END IF 
				SELECT sum(po_qty * unit_cost_amt) 
				INTO pa_pendhead[idx].auth_amt 
				FROM reqpurch 
				WHERE pend_num = pr_pendhead.pend_num 
				AND auth_ind = 1 
				IF pa_pendhead[idx].auth_amt IS NULL THEN 
					LET pa_pendhead[idx].auth_amt = 0 
				END IF 
				DISPLAY pa_pendhead[idx].* 
				TO sr_pendhead[scrn].* 

			END IF 
			NEXT FIELD pend_num 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF arr_curr() > arr_count() THEN 
				ERROR 
				" There are no more rows in the direction you are going" 
				INITIALIZE pa_pendhead[idx].* TO NULL 
			ELSE 
				DISPLAY pa_pendhead[idx].* 
				TO sr_pendhead[scrn].* 

			END IF 
		BEFORE FIELD pend_num 
			LET pr_pendhead.pend_num = pa_pendhead[idx].pend_num 
		AFTER FIELD pend_num 
			LET pa_pendhead[idx].pend_num = pr_pendhead.pend_num 
			DISPLAY pa_pendhead[idx].pend_num 
			TO sr_pendhead[scrn].pend_num 

		BEFORE FIELD vend_code 
			IF pr_pendhead.pend_num IS NOT NULL THEN 
				CALL auth_lineitems(pr_pendhead.pend_num) 
				SELECT sum(po_qty * unit_cost_amt) 
				INTO pa_pendhead[idx].auth_amt 
				FROM reqpurch 
				WHERE pend_num = pr_pendhead.pend_num 
				AND auth_ind = 1 
				SELECT sum(po_qty * unit_cost_amt) 
				INTO pa_pendhead[idx].tot_po_amt 
				FROM reqpurch 
				WHERE pend_num = pr_pendhead.pend_num 
				IF pa_pendhead[idx].auth_amt IS NULL THEN 
					LET pa_pendhead[idx].auth_amt = 0 
				END IF 
				DISPLAY pa_pendhead[idx].* 
				TO sr_pendhead[scrn].* 

			END IF 
			NEXT FIELD pend_num 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET msgresp = kandoomsg("P",8027,"") 
				#8027 Do you wish TO Save Authorization Information? (Y/N)
				IF msgresp = "Y" THEN 
					NEXT FIELD pend_num 
				ELSE 
					LET quit_flag = true 
				END IF 
			ELSE 
				LET msgresp = kandoomsg("P",8028,"") 
				#8028 Do you wish TO Generate Purchase Orders? (Y/N)
				IF msgresp = "N" THEN 
					NEXT FIELD pend_num 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
