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
GLOBALS "../re/NP_GROUP_GLOBALS.4gl"
GLOBALS "../re/NP1_GLOBALS.4gl"  
GLOBALS 
	DEFINE pa_reqperson array[200] OF 
	RECORD 
		delete_flag CHAR(1), 
		person_code LIKE reqperson.person_code, 
		name_text LIKE reqperson.name_text 
	END RECORD 
	DEFINE idx SMALLINT 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module NP1 - Internal Requisition Person Maintanence
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("NP1") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW n101 with FORM "N101" 
	CALL windecoration_n("N101") -- albo kd-763 
	WHILE select_person() 
		CALL scan_person() 
	END WHILE 
	CLOSE WINDOW n101 

END MAIN 


FUNCTION select_person() 
	DEFINE 
	pr_reqperson RECORD LIKE reqperson.*, 
	where_text CHAR(100), 
	query_text CHAR(300) 

	CLEAR FORM 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria - OK TO Continue "
	CONSTRUCT BY NAME where_text ON person_code, 
	name_text 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("U",1002,"") 
	#1002 Searching database - please wait
	LET query_text = "SELECT * FROM reqperson ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",where_text clipped," ", 
	"ORDER BY person_code" 
	PREPARE s_reqperson FROM query_text 
	DECLARE c_reqperson CURSOR FOR s_reqperson 
	LET idx = 0 
	FOREACH c_reqperson INTO pr_reqperson.* 
		LET idx = idx + 1 
		LET pa_reqperson[idx].delete_flag = NULL 
		LET pa_reqperson[idx].person_code = pr_reqperson.person_code 
		LET pa_reqperson[idx].name_text = pr_reqperson.name_text 
		IF idx = 200 THEN 
			LET msgresp=kandoomsg("U",6100,idx) 
			#6100 First idx records selected - More may exist
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp=kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION scan_person() 
	DEFINE 
	pr_person_code LIKE reqperson.person_code, 
	pr_delete_flag CHAR(1), 
	del_cnt, scrn SMALLINT 

	CALL set_count(idx) 
	OPTIONS DELETE KEY f36 
	OPTIONS INSERT KEY f1 
	LET msgresp=kandoomsg("U",1003,"") 
	#1003 F1 F2 ENTER on line TO Edit
	INPUT ARRAY pa_reqperson WITHOUT DEFAULTS FROM sr_reqperson.* 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD delete_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_delete_flag = pa_reqperson[idx].delete_flag 
			DISPLAY pa_reqperson[idx].* TO sr_reqperson[scrn].* 

		AFTER FIELD delete_flag 
			LET pa_reqperson[idx].delete_flag = pr_delete_flag 
			DISPLAY pa_reqperson[idx].delete_flag TO sr_reqperson[scrn].delete_flag 

		BEFORE FIELD person_code 
			IF pa_reqperson[idx].person_code IS NOT NULL THEN 
				LET pr_person_code = pa_reqperson[idx].person_code 
				LET pr_person_code = person_maint(pr_person_code) 
				IF pr_person_code IS NOT NULL THEN 
					SELECT name_text INTO pa_reqperson[idx].name_text FROM reqperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND person_code = pr_person_code 
				END IF 
			END IF 
			NEXT FIELD delete_flag 
		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET pr_person_code = NULL 
				LET pr_person_code = person_maint(pr_person_code) 
				IF pr_person_code IS NOT NULL THEN 
					LET pa_reqperson[idx].person_code = pr_person_code 
					SELECT name_text INTO pa_reqperson[idx].name_text FROM reqperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND person_code = pr_person_code 
				ELSE 
					FOR idx = arr_curr() TO 199 
						LET pa_reqperson[idx].* = pa_reqperson[idx+1].* 
						IF scrn < 12 THEN 
							DISPLAY pa_reqperson[idx].* TO sr_reqperson[scrn].* 

							LET scrn = scrn + 1 
						END IF 
						IF idx > arr_count() THEN 
							EXIT FOR 
						END IF 
					END FOR 
					INITIALIZE pa_reqperson[idx].* TO NULL 
				END IF 
			ELSE 
				IF idx != 1 THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are going "
				END IF 
			END IF 
			NEXT FIELD delete_flag 
		ON KEY (F2) 
			IF pa_reqperson[idx].person_code IS NULL THEN 
				NEXT FIELD delete_flag 
			END IF 
			IF pa_reqperson[idx].delete_flag IS NULL THEN 
				LET pa_reqperson[idx].delete_flag = "*" 
				DISPLAY pa_reqperson[idx].* TO sr_reqperson[scrn].* 

				SELECT unique 1 FROM reqhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND person_code = pa_reqperson[idx].person_code 
				AND status_ind != 9 
				IF status != notfound THEN 
					LET msgresp=kandoomsg("N",9010,"") 
					#9010 Note: Reqs exist FOR this person
				END IF 
				LET del_cnt = del_cnt + 1 
			ELSE 
				LET pa_reqperson[idx].delete_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
			NEXT FIELD delete_flag 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_cnt > 0 THEN 
			LET msgresp=kandoomsg("U",8000,del_cnt) 
			#8000 Confirm TO Delete ",del_cnt,"  Person/s? (Y/N)"
			IF msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_reqperson[idx].delete_flag = "*" THEN 
						DELETE FROM reqperson 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND person_code = pa_reqperson[idx].person_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


FUNCTION person_maint(pr_person_code) 
	DEFINE 
	pr_person_code LIKE reqperson.person_code, 
	pr_reqperson RECORD LIKE reqperson.*, 
	ps_reqperson RECORD LIKE reqperson.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_street RECORD LIKE street.*, 
	pr_suburb RECORD LIKE suburb.*, 
	pr_company RECORD LIKE company.*, 
	pr_suburb_code LIKE suburb.suburb_code, 
	prev_ware_code LIKE warehouse.ware_code, 
	pr_rowid INTEGER 

	OPEN WINDOW n102 with FORM "N102" 
	CALL windecoration_n("N102") -- albo kd-763 
	INITIALIZE pr_reqperson.* TO NULL 
	SELECT * INTO pr_reqperson.* FROM reqperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND person_code = pr_person_code 
	IF pr_reqperson.ware_oride_flag IS NULL THEN 
		LET pr_reqperson.ware_oride_flag = "N" 
	END IF 
	IF pr_reqperson.country_code IS NULL THEN 
		SELECT country_code INTO pr_reqperson.country_code FROM company 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 
	SELECT desc_text INTO pr_warehouse.desc_text FROM warehouse 
	WHERE ware_code = pr_reqperson.ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY BY NAME pr_warehouse.desc_text 

	LET ps_reqperson.* = pr_reqperson.* 
	LET msgresp=kandoomsg("U",1020,"Person") 
	#1020 Enter Person Details
	INPUT BY NAME pr_reqperson.person_code, 
	pr_reqperson.name_text, 
	pr_reqperson.ware_code, 
	pr_reqperson.dept_text, 
	pr_reqperson.addr1_text, 
	pr_reqperson.addr2_text, 
	pr_reqperson.addr3_text, 
	pr_reqperson.city_text, 
	pr_reqperson.state_code, 
	pr_reqperson.post_code, 
	pr_reqperson.country_code, 
	pr_reqperson.ware_oride_flag, 
	pr_reqperson.loadfile_text, 
	pr_reqperson.po_low_limit_amt, 
	pr_reqperson.po_up_limit_amt, 
	pr_reqperson.po_start_date, 
	pr_reqperson.po_exp_date, 
	pr_reqperson.stock_limit_amt, 
	pr_reqperson.sl_start_date, 
	pr_reqperson.sl_exp_date, 
	pr_reqperson.dr_limit_amt, 
	pr_reqperson.dr_start_date, 
	pr_reqperson.dr_exp_date WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield(country_code) THEN 
				LET pr_reqperson.country_code = show_country() 
				DISPLAY BY NAME pr_reqperson.country_code 

				OPTIONS DELETE KEY f36 
				OPTIONS INSERT KEY f1 
				NEXT FIELD country_code 
			END IF 
			IF infield(ware_code) THEN 
				LET pr_reqperson.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME pr_reqperson.ware_code 

				OPTIONS DELETE KEY f36 
				OPTIONS INSERT KEY f1 
				NEXT FIELD ware_code 
			END IF 
			IF infield(addr2_text) THEN 
				LET pr_rowid = show_wstreet(glob_rec_kandoouser.cmpy_code) 
				OPTIONS DELETE KEY f36 
				OPTIONS INSERT KEY f1 
				IF pr_rowid != 0 THEN 
					SELECT * INTO pr_street.* FROM street 
					WHERE rowid = pr_rowid 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("W",9005,"") 
						#9005 Logic error: Street name NOT found"
						NEXT FIELD addr2_text 
					END IF 
					SELECT * INTO pr_suburb.* FROM suburb 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND suburb_code = pr_street.suburb_code 
					LET pr_reqperson.addr2_text = pr_street.street_text clipped, 
					" ", pr_street.st_type_text 
					LET pr_reqperson.city_text = pr_suburb.suburb_text 
					LET pr_reqperson.state_code = pr_suburb.state_code 
					LET pr_reqperson.post_code = pr_suburb.post_code 
					DISPLAY BY NAME pr_reqperson.city_text, 
					pr_reqperson.state_code, 
					pr_reqperson.post_code 

				END IF 
				NEXT FIELD addr2_text 
			END IF 
			IF infield(city_text) THEN 
				LET pr_suburb_code = show_wsub(glob_rec_kandoouser.cmpy_code) 
				OPTIONS DELETE KEY f36 
				OPTIONS INSERT KEY f1 
				IF pr_suburb_code != 0 THEN 
					SELECT * INTO pr_suburb.* FROM suburb 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND suburb_code = pr_suburb_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("W",9006,"") 
						#9006 Logic error: Suburb NOT found"
						NEXT FIELD city_text 
					END IF 
					LET pr_reqperson.city_text = pr_suburb.suburb_text 
					LET pr_reqperson.state_code = pr_suburb.state_code 
					LET pr_reqperson.post_code = pr_suburb.post_code 
					DISPLAY BY NAME pr_reqperson.city_text, 
					pr_reqperson.state_code, 
					pr_reqperson.post_code 

				END IF 
				NEXT FIELD city_text 
			END IF 
		BEFORE FIELD person_code 
			IF pr_person_code IS NOT NULL THEN 
				NEXT FIELD NEXT 
			END IF 
		AFTER FIELD person_code 
			IF pr_reqperson.person_code IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD person_code 
			END IF 
			SELECT unique 1 FROM reqperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND person_code = pr_reqperson.person_code 
			IF status != notfound THEN 
				LET msgresp=kandoomsg("U",9104,"") 
				#9104 RECORD already exists
				NEXT FIELD person_code 
			END IF 
			IF pr_reqperson.name_text IS NULL THEN 
				SELECT name_text INTO pr_reqperson.name_text FROM kandoouser 
				WHERE sign_on_code = pr_reqperson.person_code 
				DISPLAY BY NAME pr_reqperson.name_text 

			END IF 
		AFTER FIELD name_text 
			IF pr_reqperson.name_text IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD name_text 
			END IF 
		BEFORE FIELD ware_code 
			LET prev_ware_code = ps_reqperson.ware_code 
		AFTER FIELD ware_code 
			IF pr_reqperson.ware_code IS NOT NULL THEN 
				SELECT * INTO pr_warehouse.* FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_reqperson.ware_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD ware_code 
				END IF 
				DISPLAY BY NAME pr_warehouse.desc_text 

			END IF 
			IF pr_reqperson.ware_code IS NOT NULL THEN 
				IF prev_ware_code != pr_reqperson.ware_code 
				OR prev_ware_code IS NULL THEN 
					IF pr_reqperson.addr1_text IS NOT NULL 
					OR pr_reqperson.addr2_text IS NOT NULL THEN 
						LET msgresp=kandoomsg("U",9928,"") 
						#9928 Confirm TO load warehouse addres? (Y/N)"
						IF msgresp = "N" THEN 
							LET prev_ware_code = pr_reqperson.ware_code 
							NEXT FIELD NEXT 
						END IF 
						LET ps_reqperson.ware_code = pr_reqperson.ware_code 
					END IF 
					LET pr_reqperson.addr1_text = NULL 
					LET pr_reqperson.addr2_text = pr_warehouse.addr1_text 
					LET pr_reqperson.addr3_text = pr_warehouse.addr2_text 
					LET pr_reqperson.city_text = pr_warehouse.city_text 
					LET pr_reqperson.state_code = pr_warehouse.state_code 
					LET pr_reqperson.post_code = pr_warehouse.post_code 
					DISPLAY BY NAME pr_reqperson.addr1_text, 
					pr_reqperson.addr2_text, 
					pr_reqperson.addr3_text, 
					pr_reqperson.city_text, 
					pr_reqperson.state_code, 
					pr_reqperson.post_code 

				END IF 
			END IF 
		AFTER FIELD country_code 
			IF pr_reqperson.country_code IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD country_code 
			END IF 
			SELECT unique 1 FROM country 
			WHERE country_code = pr_reqperson.country_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("U",9105,"") 
				#9105 RECORD NOT found - Try Window
				NEXT FIELD country_code 
			END IF 
		AFTER FIELD po_low_limit_amt 
			IF pr_reqperson.po_low_limit_amt IS NOT NULL THEN 
				IF pr_reqperson.po_low_limit_amt < 0 THEN 
					LET msgresp=kandoomsg("U",9046,"0") 
					#9046 Cannot be less than zero
					NEXT FIELD po_low_limit_amt 
				END IF 
			END IF 
		AFTER FIELD po_up_limit_amt 
			IF pr_reqperson.po_low_limit_amt IS NULL 
			AND pr_reqperson.po_up_limit_amt IS NULL THEN 
				LET pr_reqperson.po_start_date = NULL 
				LET pr_reqperson.po_exp_date = NULL 
				CLEAR po_start_date, 
				po_exp_date 
			ELSE 
				IF pr_reqperson.po_up_limit_amt < 0 THEN 
					LET msgresp=kandoomsg("U",9046,"0") 
					#9046 Cannot be less than zero
					NEXT FIELD po_up_limit_amt 
				END IF 
				IF pr_reqperson.po_up_limit_amt < pr_reqperson.po_low_limit_amt THEN 
					LET msgresp=kandoomsg("P",9182,"") 
					#9182 " PO Authorization Upper Limit must Exceed Lower Limit "
					NEXT FIELD po_low_limit_amt 
				END IF 
			END IF 
		BEFORE FIELD po_start_date 
			IF pr_reqperson.po_low_limit_amt IS NULL 
			AND pr_reqperson.po_up_limit_amt IS NULL THEN 
				NEXT FIELD stock_limit_amt 
			END IF 
		AFTER FIELD po_start_date 
			IF pr_reqperson.po_start_date IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD po_start_date 
			END IF 
		BEFORE FIELD po_exp_date 
			IF pr_reqperson.po_low_limit_amt IS NULL THEN 
				NEXT FIELD po_low_limit_amt 
			END IF 
		AFTER FIELD po_exp_date 
			IF pr_reqperson.po_exp_date IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD po_exp_date 
			END IF 
			IF pr_reqperson.po_exp_date < pr_reqperson.po_start_date THEN 
				LET msgresp=kandoomsg("G",9531,"") 
				#9531 " Start Date must preceed Expiry Date "
				NEXT FIELD po_start_date 
			END IF 
		AFTER FIELD stock_limit_amt 
			IF pr_reqperson.stock_limit_amt IS NULL THEN 
				LET pr_reqperson.sl_start_date = NULL 
				LET pr_reqperson.sl_exp_date = NULL 
				CLEAR sl_start_date, 
				sl_exp_date 
			ELSE 
				IF pr_reqperson.stock_limit_amt < 0 THEN 
					LET msgresp=kandoomsg("U",9046,"0") 
					#9046 Cannot be less than zero
					NEXT FIELD stock_limit_amt 
				END IF 
			END IF 
		BEFORE FIELD sl_start_date 
			IF pr_reqperson.stock_limit_amt IS NULL THEN 
				NEXT FIELD dr_limit_amt 
			END IF 
		AFTER FIELD sl_start_date 
			IF pr_reqperson.sl_start_date IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD sl_start_date 
			END IF 
		BEFORE FIELD sl_exp_date 
			IF pr_reqperson.stock_limit_amt IS NULL THEN 
				NEXT FIELD stock_limit_amt 
			END IF 
		AFTER FIELD sl_exp_date 
			IF pr_reqperson.sl_exp_date IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD sl_exp_date 
			END IF 
			IF pr_reqperson.sl_exp_date < pr_reqperson.sl_start_date THEN 
				LET msgresp=kandoomsg("G",9531,"") 
				#9531 " Start Date must preceed Expiry Date "
				NEXT FIELD sl_start_date 
			END IF 
		AFTER FIELD dr_limit_amt 
			IF pr_reqperson.dr_limit_amt IS NULL THEN 
				LET pr_reqperson.dr_start_date = NULL 
				LET pr_reqperson.dr_exp_date = NULL 
				CLEAR dr_start_date, 
				dr_exp_date 
			ELSE 
				IF pr_reqperson.dr_limit_amt < 0 THEN 
					LET msgresp=kandoomsg("U",9046,"0") 
					#9046 Cannot be less than zero
					NEXT FIELD dr_limit_amt 
				END IF 
			END IF 
		BEFORE FIELD dr_start_date 
			IF pr_reqperson.dr_limit_amt IS NULL THEN 
				EXIT INPUT 
			END IF 
		AFTER FIELD dr_start_date 
			IF pr_reqperson.dr_start_date IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD dr_start_date 
			END IF 
		BEFORE FIELD dr_exp_date 
			IF pr_reqperson.dr_limit_amt IS NULL THEN 
				NEXT FIELD dr_limit_amt 
			END IF 
		AFTER FIELD dr_exp_date 
			IF pr_reqperson.dr_exp_date IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD dr_exp_date 
			END IF 
			IF pr_reqperson.dr_exp_date < pr_reqperson.dr_start_date THEN 
				LET msgresp=kandoomsg("G",9531,"") 
				#9531 " Start Date must preceed Expiry Date "
				NEXT FIELD dr_start_date 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_reqperson.name_text IS NULL THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD name_text 
				END IF 
				SELECT unique 1 FROM country 
				WHERE country_code = pr_reqperson.country_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD country_code 
				END IF 
				IF pr_reqperson.ware_oride_flag IS NULL THEN 
					LET pr_reqperson.ware_oride_flag = "N" 
				END IF 
				IF pr_reqperson.stock_limit_amt IS NULL THEN 
					LET pr_reqperson.sl_start_date = NULL 
					LET pr_reqperson.sl_exp_date = NULL 
				ELSE 
					IF pr_reqperson.sl_start_date IS NULL 
					OR pr_reqperson.sl_exp_date IS NULL THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD sl_start_date 
					END IF 
					IF pr_reqperson.sl_start_date > pr_reqperson.sl_exp_date THEN 
						LET msgresp=kandoomsg("G",9531,"") 
						#9531 " Start Date must preceed Expiry Date "
						NEXT FIELD sl_start_date 
					END IF 
				END IF 
				IF pr_reqperson.dr_limit_amt IS NULL THEN 
					LET pr_reqperson.dr_start_date = NULL 
					LET pr_reqperson.dr_exp_date = NULL 
				ELSE 
					IF pr_reqperson.dr_start_date IS NULL 
					OR pr_reqperson.dr_exp_date IS NULL THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD dr_start_date 
					END IF 
					IF pr_reqperson.dr_start_date > pr_reqperson.dr_exp_date THEN 
						LET msgresp=kandoomsg("G",9531,"") 
						#9531 " Start Date must preceed Expiry Date "
						NEXT FIELD dr_start_date 
					END IF 
				END IF 
				IF pr_reqperson.po_low_limit_amt IS NULL 
				AND pr_reqperson.po_up_limit_amt IS NULL THEN 
					LET pr_reqperson.po_start_date = NULL 
					LET pr_reqperson.po_exp_date = NULL 
				ELSE 
					IF pr_reqperson.po_low_limit_amt IS NULL 
					OR pr_reqperson.po_up_limit_amt IS NULL THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD po_low_limit_amt 
					END IF 
					IF pr_reqperson.po_start_date IS NULL 
					OR pr_reqperson.po_exp_date IS NULL THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD po_start_date 
					END IF 
					IF pr_reqperson.po_start_date > pr_reqperson.po_exp_date THEN 
						LET msgresp=kandoomsg("G",9531,"") 
						#9531 " Start Date must preceed Expiry Date "
						NEXT FIELD po_start_date 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW n102 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN "" 
	END IF 
	IF pr_person_code IS NULL THEN 
		LET pr_reqperson.cmpy_code = glob_rec_kandoouser.cmpy_code 
		INSERT INTO reqperson VALUES (pr_reqperson.*) 
	ELSE 
		UPDATE reqperson 
		SET reqperson.* = pr_reqperson.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND person_code = pr_person_code 
	END IF 
	RETURN pr_reqperson.person_code 
END FUNCTION 
