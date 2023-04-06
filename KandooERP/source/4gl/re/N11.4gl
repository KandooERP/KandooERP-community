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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N1_GROUP_GLOBALS.4gl" 
GLOBALS "../re/N11_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N11 - Internal Requisition Entry
#
# Functions in this module are:
# * Main            - Main FUNCTION
# * select_person   - Enter the Person/Requisition Details
# * print_pick_slip - Print Picking Slip
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N11") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N105 with FORM "N105" 
	CALL windecoration_n("N105") -- albo kd-763 

	SELECT * INTO pr_reqperson.* FROM reqperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND person_code = glob_rec_kandoouser.sign_on_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("U",1531,glob_rec_kandoouser.sign_on_code) 		#1531 User does NOT have access TO Internal Requisitions
		EXIT program 
	END IF 
	CALL create_table("reqdetl","t_reqdetl","","Y") 
	CREATE INDEX t_reqdetl_key ON t_reqdetl(line_num) 
	CREATE temp TABLE t_loadreq(barcode CHAR(18), 
	req_qty DECIMAL(16,2)) 
	with no log; 
	LET held_order = false 
	CALL req_initialize() 
	WHILE select_person() 
		OPEN WINDOW n107 with FORM "N107" 
		CALL windecoration_n("N107") -- albo kd-763 
		IF lineitem_scan("ADD") THEN 
			CALL write_req() 
			IF pr_reqhead.status_ind != 0 THEN 
				CALL print_pick_slip() 
			END IF 
			LET msgresp=kandoomsg("N",7011,pr_reqhead.req_num) 			#7011 Successful Addition of Requisition Number
		END IF 
		CALL req_initialize() 
		LET held_order = false 
		CLOSE WINDOW n107 
	END WHILE 
	CLOSE WINDOW n105 
END MAIN 


FUNCTION select_person() 
	DEFINE 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_street RECORD LIKE street.*, 
	pr_suburb RECORD LIKE suburb.*, 
	pr_suburb_code LIKE suburb.suburb_code, 
	trans_limit LIKE reqperson.stock_limit_amt, 
	trans_start LIKE reqperson.sl_start_date, 
	trans_exp LIKE reqperson.sl_exp_date, 
	pr_save_date LIKE reqhead.req_date, 
	invalid_period SMALLINT, 
	pr_rowid INTEGER 

	IF pr_reqperson.stock_limit_amt IS NULL 
	AND pr_reqperson.dr_limit_amt IS NULL THEN 
		LET msgresp=kandoomsg("N",7010,glob_rec_kandoouser.sign_on_code) 	#7010 User does NOT have authority TO Internal Requisitions
		RETURN false 
	END IF 
	IF pr_reqperson.stock_limit_amt IS NOT NULL 
	AND pr_reqperson.dr_limit_amt IS NULL THEN 
		IF pr_reqperson.sl_start_date > today THEN 
			LET msgresp=kandoomsg("N",7010,glob_rec_kandoouser.sign_on_code) 		#7010 User does NOT have authority TO Internal Requisitions
			RETURN false 
		END IF 
		IF pr_reqperson.sl_exp_date < today THEN 
			LET msgresp=kandoomsg("N",7010,glob_rec_kandoouser.sign_on_code) 		#7010 User does NOT have authority TO Internal Requisitions
			RETURN false 
		END IF 
	END IF 
	IF pr_reqperson.dr_limit_amt IS NOT NULL 
	AND pr_reqperson.stock_limit_amt IS NULL THEN 
		IF pr_reqperson.dr_start_date > today THEN 
			LET msgresp=kandoomsg("N",7010,glob_rec_kandoouser.sign_on_code) 		#7010 User does NOT have authority TO Internal Requisitions
			RETURN false 
		END IF 
		IF pr_reqperson.dr_exp_date < today THEN 
			LET msgresp=kandoomsg("N",7010,glob_rec_kandoouser.sign_on_code) 		#7010 User does NOT have authority TO Internal Requisitions
			RETURN false 
		END IF 
	END IF 
	IF pr_reqhead.person_code IS NULL THEN 
		LET pr_reqhead.person_code = pr_reqperson.person_code 
		LET pr_reqhead.del_dept_text = pr_reqperson.dept_text 
		LET pr_reqhead.del_name_text = pr_reqperson.name_text 
		LET pr_reqhead.del_addr1_text = pr_reqperson.addr1_text 
		LET pr_reqhead.del_addr2_text = pr_reqperson.addr2_text 
		LET pr_reqhead.del_addr3_text = pr_reqperson.addr3_text 
		LET pr_reqhead.del_city_text = pr_reqperson.city_text 
		LET pr_reqhead.del_state_code = pr_reqperson.state_code 
		LET pr_reqhead.del_country_code = pr_reqperson.country_code 
		LET pr_reqhead.del_post_code = pr_reqperson.post_code 
		LET pr_reqhead.stock_ind = "0" 
		LET trans_text = kandooword("reqhead.stock_ind",pr_reqhead.stock_ind) 
		LET pr_reqhead.ware_code = pr_reqperson.ware_code 
		SELECT desc_text INTO pr_warehouse.desc_text FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_reqhead.ware_code 
		LET pr_reqhead.req_date = today 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
		RETURNING pr_reqhead.year_num, 
		pr_reqhead.period_num 
		LET pr_reqhead.part_flag = "Y" 
	END IF 
	DISPLAY BY NAME pr_reqhead.person_code, 
	pr_reqperson.name_text, 
	pr_warehouse.desc_text, 
	trans_text 

	LET msgresp=kandoomsg("U",1020,"Requisition") #1020 Enter Requisition Details - OK TO Continue "
	INPUT BY NAME pr_reqhead.del_dept_text, 
	pr_reqhead.del_name_text, 
	pr_reqhead.del_addr1_text, 
	pr_reqhead.del_addr2_text, 
	pr_reqhead.del_addr3_text, 
	pr_reqhead.del_city_text, 
	pr_reqhead.del_state_code, 
	pr_reqhead.del_post_code, 
	pr_reqhead.del_country_code, 
	pr_reqhead.stock_ind, 
	pr_reqhead.part_flag, 
	pr_reqhead.ware_code, 
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
			IF infield(ware_code) THEN 
				LET pr_reqhead.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME pr_reqhead.ware_code 

				NEXT FIELD ware_code 
			END IF 
			IF infield(del_addr2_text) THEN 
				LET pr_rowid = show_wstreet(glob_rec_kandoouser.cmpy_code) 
				IF pr_rowid != 0 THEN 
					SELECT * INTO pr_street.* FROM street 
					WHERE rowid = pr_rowid 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("W",9005,"") 					#9005 Logic error: Street name NOT found"
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
				LET msgresp=kandoomsg("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD del_country_code 
			END IF 
			SELECT unique 1 FROM country 
			WHERE country_code = pr_reqhead.del_country_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("U",9105,"") 			#9105 RECORD NOT found - Try Window
				NEXT FIELD del_country_code 
			END IF 
		AFTER FIELD stock_ind 
			LET trans_text = kandooword("reqhead.stock_ind",pr_reqhead.stock_ind) 
			DISPLAY BY NAME trans_text 

			CASE pr_reqhead.stock_ind 
				WHEN 0 
					LET trans_limit = pr_reqperson.dr_limit_amt 
					LET trans_start = pr_reqperson.dr_start_date 
					LET trans_exp = pr_reqperson.dr_exp_date 
				WHEN 1 
					LET trans_limit = pr_reqperson.stock_limit_amt 
					LET trans_start = pr_reqperson.sl_start_date 
					LET trans_exp = pr_reqperson.sl_exp_date 
				WHEN 2 
					LET trans_limit = pr_reqperson.dr_limit_amt 
					LET trans_start = pr_reqperson.dr_start_date 
					LET trans_exp = pr_reqperson.dr_exp_date 
				OTHERWISE 
					NEXT FIELD stock_ind 
			END CASE 
			IF trans_limit IS NULL THEN 
				LET msgresp=kandoomsg("N",9508,trans_text) 
				#9508 No limit SET up FOR this person "
				NEXT FIELD stock_ind 
			ELSE 
				IF trans_start > today THEN 
					LET msgresp=kandoomsg("N",9508,trans_text) 
					#9508 No limit SET up FOR this person "
					NEXT FIELD stock_ind 
				END IF 
				IF trans_exp < today THEN 
					LET msgresp=kandoomsg("N",9508,trans_text) 
					#9508 No limit SET up FOR this person "
					NEXT FIELD stock_ind 
				END IF 
			END IF 
		BEFORE FIELD ware_code 
			IF pr_reqhead.ware_code IS NOT NULL THEN 
				IF pr_reqperson.ware_oride_flag = "N" THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD part_flag 
					ELSE 
						NEXT FIELD ref_text 
					END IF 
				END IF 
			END IF 
		AFTER FIELD ware_code 
			IF pr_reqhead.ware_code IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					LET pr_warehouse.desc_text = NULL 
				ELSE 
					LET msgresp=kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD ware_code 
				END IF 
			ELSE 
				SELECT desc_text INTO pr_warehouse.desc_text FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_reqhead.ware_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD ware_code 
				END IF 
			END IF 
			DISPLAY BY NAME pr_warehouse.desc_text 

		BEFORE FIELD req_date 
			LET pr_save_date = pr_reqhead.req_date 
		AFTER FIELD req_date 
			IF pr_reqhead.req_date IS NULL THEN 
				LET pr_reqhead.req_date = pr_save_date 
				DISPLAY BY NAME pr_reqhead.req_date 

			END IF 
			IF pr_reqhead.year_num IS NULL 
			OR pr_reqhead.period_num IS NULL 
			OR pr_reqhead.req_date != pr_save_date THEN 
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
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT unique 1 FROM country 
				WHERE country_code = pr_reqhead.del_country_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD del_country_code 
				END IF 
				SELECT desc_text INTO pr_warehouse.desc_text FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_reqhead.ware_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD ware_code 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_reqhead.year_num, 
				pr_reqhead.period_num,TRAN_TYPE_INVOICE_IN) 
				RETURNING pr_reqhead.year_num, 
				pr_reqhead.period_num, 
				invalid_period 
				IF invalid_period THEN 
					NEXT FIELD req_date 
				END IF 
				CASE pr_reqhead.stock_ind 
					WHEN 0 
						LET trans_limit = pr_reqperson.dr_limit_amt 
						LET trans_start = pr_reqperson.dr_start_date 
						LET trans_exp = pr_reqperson.dr_exp_date 
					WHEN 1 
						LET trans_limit = pr_reqperson.stock_limit_amt 
						LET trans_start = pr_reqperson.sl_start_date 
						LET trans_exp = pr_reqperson.sl_exp_date 
					WHEN 2 
						LET trans_limit = pr_reqperson.dr_limit_amt 
						LET trans_start = pr_reqperson.dr_start_date 
						LET trans_exp = pr_reqperson.dr_exp_date 
					OTHERWISE 
						NEXT FIELD stock_ind 
				END CASE 
				IF trans_limit IS NULL THEN 
					LET msgresp=kandoomsg("N",9508,trans_text) 
					#9508 No limit SET up FOR this person "
					NEXT FIELD stock_ind 
				ELSE 
					IF trans_start > today 
					OR trans_exp < today THEN 
						LET msgresp=kandoomsg("N",9508,trans_text) 
						#9508 No limit SET up FOR this person "
						NEXT FIELD stock_ind 
					END IF 
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
#
# Print Picking Slip FOR Requisition
#
FUNCTION print_pick_slip() 
	DEFINE 
	pr_temp_text CHAR(80), 
	pr_printcodes RECORD LIKE printcodes.*, 
	pr_print_cmd CHAR(400), 
	pr_output CHAR(25) 

	IF glob_rec_reqparms.auto_pick_flag = "Y" THEN 
		SELECT unique 1 FROM reqdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND req_num = pr_reqhead.req_num 
		AND reserved_qty > 0 
		IF status != notfound THEN 
			LET pr_temp_text = " reqhead.req_num = ", 
			pr_reqhead.req_num USING "<<<<<<" 
			LET pr_output = create_pickslip(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,pr_temp_text) 
			SELECT * INTO pr_printcodes.* FROM printcodes 
			WHERE print_code = glob_rec_reqparms.pick_print_text 
			IF status != notfound THEN 
				LET pr_print_cmd = " F=",pr_output clipped," ;C=1 ", 
				" ;L=66 ;W=80 ", 
				" ;",pr_printcodes.print_text clipped, 
				" 2>>",trim(get_settings_logFile()) 
				RUN pr_print_cmd 
				SELECT last_del_no INTO pr_reqhead.last_del_no FROM reqhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND req_num = pr_reqhead.req_num 
				error" Printing Picking Slip No: ", 
				pr_reqhead.last_del_no USING "<<<<<<", 
				" on Device ",pr_printcodes.desc_text clipped 
			END IF 
		END IF 
	END IF 
END FUNCTION 
