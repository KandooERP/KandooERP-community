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
GLOBALS "../re/N12_GLOBALS.4gl" 
GLOBALS 
	DEFINE pr_reqhead RECORD LIKE reqhead.* 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
#   N12 - Requisitions Inquiry
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N12") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N109 with FORM "N109" 
	CALL windecoration_n("N109") -- albo kd-763 

	CALL scan_requisition() 
	CLOSE WINDOW n109 

END MAIN 


FUNCTION select_requisition() 
	DEFINE 
	where_text CHAR(1500), 
	query_text CHAR(1600) 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME where_text ON req_num, 
	req_date, 
	reqhead.person_code, 
	name_text, 
	reqhead.ware_code, 
	stock_ind, 
	status_ind, 
	total_sales_amt, 
	del_dept_text, 
	del_name_text, 
	ref_text, 
	year_num, 
	period_num, 
	last_del_no, 
	last_del_date, 
	entry_date, 
	last_mod_date, 
	last_mod_code, 
	rev_num, 
	com1_text, 
	com2_text 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database; Please Wait.
	LET query_text = "SELECT reqhead.* FROM reqhead, reqperson ", 
	"WHERE reqhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND reqperson.cmpy_code = reqhead.cmpy_code ", 
	"AND reqperson.person_code = reqhead.person_code ", 
	"AND ",where_text clipped," ", 
	"ORDER BY person_code, req_num" 
	PREPARE s_reqhead FROM query_text 
	DECLARE c_reqhead SCROLL CURSOR FOR s_reqhead 
	OPEN c_reqhead 
	FETCH c_reqhead INTO pr_reqhead.* 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
		CALL display_requisition(glob_rec_kandoouser.cmpy_code,pr_reqhead.req_num) 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_requisition() 
	MENU " Requisition" 
		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "First" 
			HIDE option "Last" 
			HIDE option "Detail" 
		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Query" " Enter selection criteria FOR requisitions" 
			IF select_requisition() THEN 
				FETCH FIRST c_reqhead INTO pr_reqhead.* 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
			ELSE 
				LET msgresp = kandoomsg("U",9101,"") 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected requisition" 
			FETCH NEXT c_reqhead INTO pr_reqhead.* 
			IF status <> notfound THEN 
				CALL display_requisition(glob_rec_kandoouser.cmpy_code,pr_reqhead.req_num) 
			ELSE 
				LET msgresp = kandoomsg("G",9157,"") 
				#9071 You have reached the END of the complaint selected"
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous requisition" 
			FETCH previous c_reqhead INTO pr_reqhead.* 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("G",9156,"") 
				#9070 You have reached the start of the complaint selected"
			ELSE 
				CALL display_requisition(glob_rec_kandoouser.cmpy_code,pr_reqhead.req_num) 
			END IF 
		COMMAND KEY ("D",f20) "Detail" " View requisition details" 
			CALL requisition_inquiry(glob_rec_kandoouser.cmpy_code,pr_reqhead.req_num,0) 
		COMMAND KEY ("F",f18) "First" " DISPLAY first requisition in the selected list" 
			FETCH FIRST c_reqhead INTO pr_reqhead.* 
			CALL display_requisition(glob_rec_kandoouser.cmpy_code,pr_reqhead.req_num) 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last requisition in the selected list" 
			FETCH LAST c_reqhead INTO pr_reqhead.* 
			CALL display_requisition(glob_rec_kandoouser.cmpy_code,pr_reqhead.req_num) 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the Menu" 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 
