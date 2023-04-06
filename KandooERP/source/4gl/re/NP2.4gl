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
GLOBALS "../re/NP2_GLOBALS.4gl"  
GLOBALS 
	DEFINE pr_country RECORD LIKE country.* 
	DEFINE pr_reqperson RECORD LIKE reqperson.* 
	DEFINE pr_warehouse RECORD LIKE warehouse.* 
	DEFINE where_text CHAR(1000) 
	DEFINE query_text CHAR(1200) 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module NP2 - Internal Requisition Person Inquiry
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("NP2") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW n102 with FORM "N102" 
	CALL windecoration_n("N102") -- albo kd-763 
	CALL scan_person() 
	CLOSE WINDOW n102 

END MAIN 


FUNCTION select_person() 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria - OK TO Continue "
	CONSTRUCT BY NAME where_text ON person_code, 
	name_text, 
	ware_code, 
	dept_text, 
	addr1_text, 
	addr2_text, 
	addr3_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	ware_oride_flag, 
	loadfile_text, 
	po_low_limit_amt, 
	po_up_limit_amt, 
	po_start_date, 
	po_exp_date, 
	stock_limit_amt, 
	sl_start_date, 
	sl_exp_date, 
	dr_limit_amt, 
	dr_start_date, 
	dr_exp_date 

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
	DECLARE c_reqperson SCROLL CURSOR FOR s_reqperson 
	OPEN c_reqperson 
	FETCH c_reqperson INTO pr_reqperson.* 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_person() 
	MENU " Person Inquiry" 
		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "First" 
			HIDE option "Last" 
		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Query" " Enter selection criteria FOR persons" 
			IF select_person() THEN 
				CALL disp_person() 
				FETCH FIRST c_reqperson INTO pr_reqperson.* 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				LET msgresp=kandoomsg("P",9044,"") 
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected person" 
			FETCH NEXT c_reqperson INTO pr_reqperson.* 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("W",9182,"") 
				#9182 "You have reached the END of the entries selected"
			ELSE 
				CALL disp_person() 
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected person" 
			FETCH previous c_reqperson INTO pr_reqperson.* 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("W",9183,"") 
				#9183 "You have reached the END of the entries selected"
			ELSE 
				CALL disp_person() 
			END IF 
		COMMAND KEY ("F",f18) "First" " DISPLAY first person in the selected list" 
			FETCH FIRST c_reqperson INTO pr_reqperson.* 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("W",9182,"") 
				#9182 "You have reached the END of the entries selected"
			ELSE 
				CALL disp_person() 
			END IF 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last receipt in the selected list" 
			FETCH LAST c_reqperson INTO pr_reqperson.* 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("W",9182,"") 
				#9182 "You have reached the END of the entries selected"
			ELSE 
				CALL disp_person() 
			END IF 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the menus" 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION disp_person() 
	SELECT * INTO pr_warehouse.* FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_reqperson.ware_code 
	DISPLAY BY NAME pr_reqperson.person_code, 
	pr_reqperson.name_text, 
	pr_reqperson.ware_code, 
	pr_warehouse.desc_text, 
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
	pr_reqperson.stock_limit_amt, 
	pr_reqperson.sl_start_date, 
	pr_reqperson.sl_exp_date, 
	pr_reqperson.dr_limit_amt, 
	pr_reqperson.dr_start_date, 
	pr_reqperson.dr_exp_date, 
	pr_reqperson.po_low_limit_amt, 
	pr_reqperson.po_up_limit_amt, 
	pr_reqperson.po_start_date, 
	pr_reqperson.po_exp_date 

END FUNCTION 
