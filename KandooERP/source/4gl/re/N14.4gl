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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N1_GROUP_GLOBALS.4gl"
GLOBALS "../re/N11_GLOBALS.4gl"  
GLOBALS "../re/N14_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N14 - Internal Requisition Edit
# Functions in this module are:
# * main         - Main FUNCTION
# * select_req   - Enter the selection criteria FOR Requistion Edit
# * scan_reqhead - Scan AND SELECT the Requisition TO Edit
# * edit_person  - Edit the Person/Requisition Details
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N14") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N114 with FORM "N114" 
	CALL windecoration_n("N114") -- albo kd-763 

	SELECT * INTO pr_reqperson.* FROM reqperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND person_code = glob_rec_kandoouser.sign_on_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("U",1531,glob_rec_kandoouser.sign_on_code) 		#1531 User does NOT have access TO Internal Requisitions
		EXIT program 
	END IF 
	CALL create_table("reqdetl","t_reqdetl","","N") 
	CREATE INDEX t_reqdetl_key ON t_reqdetl(line_num) 
	CREATE temp TABLE t_loadreq(barcode CHAR(18), 
	req_qty DECIMAL(16,2)) 
	with no LOG 
	CALL req_initialize() 
	WHILE select_req() 
		CALL scan_reqhead() 
	END WHILE 
	CLOSE WINDOW n114 
END MAIN 


FUNCTION select_req() 
	DEFINE 
	where_text CHAR(500), 
	query_text CHAR(800), 
	idx SMALLINT 

	CLEAR FORM 
	LET msgresp=kandoomsg("N",1001,"") 
	CONSTRUCT BY NAME where_text ON reqhead.req_num, 
	reqhead.del_dept_text, 
	reqhead.stock_ind, 
	reqhead.req_date, 
	reqhead.ware_code, 
	reqhead.total_sales_amt, 
	reqhead.status_ind 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("N",1002,"") 
	#N1002 " Searching database - please wait "
	LET query_text = "SELECT * FROM reqhead ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND status_ind < 9 ", 
	"AND ",where_text clipped," ", 
	"ORDER BY req_num" 
	PREPARE s_reqhead FROM query_text 
	DECLARE c_reqhead CURSOR FOR s_reqhead 
	RETURN true 
END FUNCTION 


FUNCTION scan_reqhead() 
	DEFINE 
	pa_reqhead array[500] OF RECORD 
		req_num LIKE reqhead.req_num, 
		del_dept_text LIKE reqhead.del_dept_text, 
		stock_ind LIKE reqhead.stock_ind, 
		req_date LIKE reqhead.req_date, 
		ware_code LIKE reqhead.ware_code, 
		total_sales_amt LIKE reqhead.total_sales_amt, 
		status_ind LIKE reqhead.status_ind 
	END RECORD, 
	idx, scrn SMALLINT, 
	pr_req_num LIKE reqhead.req_num 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	LET idx = 0 
	FOREACH c_reqhead INTO pr_reqhead.* 
		LET idx = idx + 1 
		LET pa_reqhead[idx].req_num = pr_reqhead.req_num 
		LET pa_reqhead[idx].del_dept_text = pr_reqhead.del_dept_text 
		LET pa_reqhead[idx].stock_ind = pr_reqhead.stock_ind 
		LET pa_reqhead[idx].req_date = pr_reqhead.req_date 
		LET pa_reqhead[idx].ware_code = pr_reqhead.ware_code 
		LET pa_reqhead[idx].total_sales_amt = pr_reqhead.total_sales_amt 
		LET pa_reqhead[idx].status_ind = pr_reqhead.status_ind 
		IF idx = 500 THEN 
			LET msgresp=kandoomsg("U",6100,idx) 
			#6100 First idx records selected - More may exist
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp=kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_reqhead[idx].* TO NULL 
		RETURN 
	END IF 
	CALL set_count(idx) 
	LET msgresp=kandoomsg("N",1044,"") 
	#1044 F3 F4 ENTER on line TO Edit
	INPUT ARRAY pa_reqhead WITHOUT DEFAULTS FROM sr_reqhead.* 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD req_num 
			IF arr_curr() > arr_count() THEN 
				LET msgresp=kandoomsg("N",9001,"") 
				#N9001 No more rows in the direction you are going
				INITIALIZE pa_reqhead[idx].* TO NULL 
			ELSE 
				DISPLAY pa_reqhead[idx].* TO sr_reqhead[scrn].* 

			END IF 
			LET pr_req_num = pa_reqhead[idx].req_num 
		AFTER FIELD req_num 
			LET pa_reqhead[idx].req_num = pr_req_num 
			DISPLAY pa_reqhead[idx].req_num TO sr_reqhead[scrn].req_num 

		BEFORE FIELD del_dept_text 
			CALL req_initialize() 
			SELECT * INTO pr_reqhead.* FROM reqhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_req_num 
			IF status = notfound THEN 
				NEXT FIELD req_num 
			END IF 
			OPEN WINDOW n105 with FORM "N105" 
			CALL windecoration_n("N105") -- albo kd-763 
			WHILE edit_person() 
				DELETE FROM t_reqdetl WHERE 1=1 
				LET held_order = false 
				OPEN WINDOW n107 with FORM "N107" 
				CALL windecoration_n("N107") -- albo kd-763 
				IF lineitem_scan("EDIT") THEN 
					CALL update_req() 
					LET quit_flag = true 
				END IF 
				CLOSE WINDOW n107 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT WHILE 
				END IF 
			END WHILE 
			CALL req_initialize() 
			CLOSE WINDOW n105 
			SELECT del_dept_text, req_date, total_sales_amt, status_ind 
			INTO pa_reqhead[idx].del_dept_text, 
			pa_reqhead[idx].req_date, 
			pa_reqhead[idx].total_sales_amt, 
			pa_reqhead[idx].status_ind 
			FROM reqhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pa_reqhead[idx].req_num 
			NEXT FIELD req_num 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION edit_person() 
	DEFINE 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_street RECORD LIKE street.*, 
	pr_suburb RECORD LIKE suburb.*, 
	pr_suburb_code LIKE suburb.suburb_code, 
	pr2_reqperson RECORD LIKE reqperson.*, 
	invalid_period SMALLINT, 
	pr_temp_text CHAR(50), 
	pr_rowid INTEGER 

	SELECT * INTO pr2_reqperson.* FROM reqperson 
	WHERE cmpy_code = pr_reqhead.cmpy_code 
	AND person_code = pr_reqhead.person_code 
	IF status = notfound THEN 
		LET pr2_reqperson.name_text = 'person deleted' 
	END IF 
	LET trans_text = kandooword("reqhead.stock_ind",pr_reqhead.stock_ind) 
	SELECT desc_text INTO pr_warehouse.desc_text FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_reqhead.ware_code 
	DISPLAY BY NAME pr_reqhead.person_code, 
	pr2_reqperson.name_text, 
	pr_reqhead.stock_ind, 
	pr_reqhead.ware_code, 
	pr_warehouse.desc_text, 
	trans_text 

	LET msgresp=kandoomsg("U",1020,"Requisition") 
	#1020 Enter Requisition Details - OK TO Continue "
	INPUT BY NAME pr_reqhead.del_dept_text, 
	pr_reqhead.del_name_text, 
	pr_reqhead.del_addr1_text, 
	pr_reqhead.del_addr2_text, 
	pr_reqhead.del_addr3_text, 
	pr_reqhead.del_city_text, 
	pr_reqhead.del_state_code, 
	pr_reqhead.del_post_code, 
	pr_reqhead.del_country_code, 
	pr_reqhead.part_flag, 
	pr_reqhead.ref_text, 
	pr_reqhead.req_date, 
	pr_reqhead.year_num, 
	pr_reqhead.period_num, 
	pr_reqhead.com1_text, 
	pr_reqhead.com2_text WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield(del_country_code) THEN 
				LET pr_reqhead.del_country_code = show_country() 
				DISPLAY BY NAME pr_reqhead.del_country_code 

				NEXT FIELD del_country_code 
			END IF 
			IF infield(del_addr2_text) THEN 
				LET pr_rowid = show_wstreet(glob_rec_kandoouser.cmpy_code) 
				IF pr_rowid != 0 THEN 
					SELECT * INTO pr_street.* FROM street 
					WHERE rowid = pr_rowid 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("W",9005,"") 
						#9005 Logic error: Street name NOT found"
						NEXT FIELD del_addr2_text 
					END IF 
					SELECT * INTO pr_suburb.* FROM suburb 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND suburb_code = pr_street.suburb_code 
					LET pr_reqhead.del_addr2_text = pr_street.street_text clipped, 
					" ", pr_street.st_type_text 
					LET pr_reqhead.del_city_text = pr_suburb.suburb_text 
					LET pr_reqhead.del_state_code = pr_suburb.state_code 
					LET pr_reqhead.del_post_code = pr_suburb.post_code 
					DISPLAY BY NAME pr_reqhead.del_city_text, 
					pr_reqhead.del_state_code, 
					pr_reqhead.del_post_code 

				END IF 
				NEXT FIELD del_addr2_text 
			END IF 
			IF infield(del_city_text) THEN 
				LET pr_suburb_code = show_wsub(glob_rec_kandoouser.cmpy_code) 
				IF pr_suburb_code != 0 THEN 
					SELECT * INTO pr_suburb.* FROM suburb 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND suburb_code = pr_suburb_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("W",9006,"") 
						#9006 Logic error: Suburb NOT found"
						NEXT FIELD del_city_text 
					END IF 
					LET pr_reqhead.del_city_text = pr_suburb.suburb_text 
					LET pr_reqhead.del_state_code = pr_suburb.state_code 
					LET pr_reqhead.del_post_code = pr_suburb.post_code 
					DISPLAY BY NAME pr_reqhead.del_city_text, 
					pr_reqhead.del_state_code, 
					pr_reqhead.del_post_code 

				END IF 
				NEXT FIELD del_city_text 
			END IF 
		ON ACTION "NOTES" infield (com1_text) --ON KEY (control-n) 
				LET pr_reqhead.com1_text = sys_noter(glob_rec_kandoouser.cmpy_code, pr_reqhead.com1_text) 
				DISPLAY BY NAME pr_reqhead.com1_text 

				NEXT FIELD com1_text 

		AFTER FIELD del_country_code 
			IF pr_reqhead.del_country_code IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD del_country_code 
			END IF 
			SELECT unique 1 FROM country 
			WHERE country_code = pr_reqhead.del_country_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("U",9105,"") 
				#9105 RECORD NOT found - Try Window
				NEXT FIELD del_country_code 
			END IF 
		AFTER FIELD req_date 
			IF pr_reqhead.req_date IS NULL THEN 
				LET pr_reqhead.req_date = today 
			END IF 
			IF pr_reqhead.year_num IS NULL 
			OR pr_reqhead.period_num IS NULL THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_reqhead.req_date) 
				RETURNING pr_reqhead.year_num, 
				pr_reqhead.period_num 
				DISPLAY BY NAME pr_reqhead.year_num, 
				pr_reqhead.period_num 

			END IF 
		AFTER FIELD period_num 
			CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_reqhead.year_num, 
			pr_reqhead.period_num,TRAN_TYPE_INVOICE_IN) 
			RETURNING pr_reqhead.year_num, 
			pr_reqhead.period_num, 
			invalid_period 
			IF invalid_period THEN 
				NEXT FIELD req_date 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT unique 1 FROM country 
				WHERE country_code = pr_reqhead.del_country_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD del_country_code 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_reqhead.year_num, 
				pr_reqhead.period_num,TRAN_TYPE_INVOICE_IN) 
				RETURNING pr_reqhead.year_num, 
				pr_reqhead.period_num, 
				invalid_period 
				IF invalid_period THEN 
					NEXT FIELD req_date 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
