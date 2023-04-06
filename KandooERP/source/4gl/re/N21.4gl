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
GLOBALS "../re/N2_GROUP_GLOBALS.4gl"
GLOBALS "../re/N21_GLOBALS.4gl"  
GLOBALS 
	DEFINE where_text STRING 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N21  Picking Slip Print
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N21") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N128 with FORM "N128" 
	CALL windecoration_n("N128") -- albo kd-763 

	MENU "Print Picking Slips" 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run Selection" "SELECT criteria AND PRINT slips" 
			IF select_req() THEN 
				CALL create_pickslip(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text) 
			END IF 

		ON ACTION "Print Manager"
		#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS" 
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" "Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW N128 
END MAIN 


FUNCTION select_req() 
	DEFINE 
	first_req_num, last_req_num LIKE reqhead.req_num, 
	first_person, last_person LIKE reqperson.person_code, 
	first_ware, last_ware LIKE warehouse.ware_code, 
	person_ind,req_num_ind,ans CHAR(1) 

	CLEAR FORM 
	LET where_text = NULL 
	INPUT BY NAME req_num_ind, 
	first_req_num, 
	last_req_num, 
	person_ind, 
	first_person, 
	last_person, 
	first_ware, 
	last_ware, 
	ans WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD req_num_ind 
			IF req_num_ind IS NULL THEN 
				LET req_num_ind = "A" 
			END IF 
			IF req_num_ind = "A" THEN 
				LET first_req_num = 0 
				LET last_req_num = 9999999 
				DISPLAY BY NAME req_num_ind, 
				first_req_num, 
				last_req_num 

				NEXT FIELD person_ind 
			END IF 
		AFTER FIELD first_req_num 
			IF first_req_num IS NULL THEN 
				LET first_req_num = 0 
				DISPLAY BY NAME first_req_num 

			END IF 
		AFTER FIELD last_req_num 
			IF last_req_num IS NULL 
			OR last_req_num = 0 THEN 
				LET last_req_num = 9999999 
				DISPLAY BY NAME last_req_num 

			END IF 
		AFTER FIELD person_ind 
			IF person_ind IS NULL THEN 
				LET person_ind = "A" 
			END IF 
			IF person_ind = "A" THEN 
				LET first_person = " " 
				LET last_person = "zzzzzzzz" 
				DISPLAY BY NAME person_ind, 
				first_person, 
				last_person 

				NEXT FIELD first_ware 
			END IF 
		AFTER FIELD last_person 
			IF last_person IS NULL THEN 
				LET last_person = "ZZZZZZZZ" 
				DISPLAY BY NAME last_person 

			END IF 
		AFTER FIELD last_ware 
			IF last_ware IS NULL THEN 
				LET last_ware = "ZZZ" 
			END IF 
			DISPLAY BY NAME last_ware 

		BEFORE FIELD ans 
			IF ans IS NULL THEN 
				LET ans = "Y" 
			END IF 
		AFTER INPUT 
			IF ans IS NULL OR ans != "Y" THEN 
				LET ans = "Y" 
				NEXT FIELD ans 
			END IF 
			IF req_num_ind IS NULL THEN 
				LET req_num_ind = "A" 
			ELSE 
				IF last_req_num IS NULL OR last_req_num = 0 THEN 
					LET last_req_num = 9999999 
				END IF 
				IF first_req_num IS NULL THEN 
					LET first_req_num = 0 
				END IF 
			END IF 
			IF person_ind IS NULL THEN 
				LET person_ind = "A" 
			ELSE 
				IF last_person IS NULL THEN 
					LET last_person = "zzzzzzzzz" 
				END IF 
				IF first_person IS NULL THEN 
					LET first_person = "a" 
				END IF 
			END IF 
			IF first_ware IS NULL THEN 
				LET first_ware = "@@@" 
			END IF 
			IF last_ware IS NULL THEN 
				LET last_ware = "ZZZ" 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET where_text = " 1=1 " 
		IF req_num_ind != "A" THEN 
			LET where_text = where_text clipped, 
			" AND reqhead.req_num between \"", 
			first_req_num USING "<<<<<<<<","\" AND \"", 
			last_req_num USING "<<<<<<<<","\" " 
		END IF 
		IF person_ind != "A" THEN 
			LET where_text = where_text clipped, 
			" AND reqhead.person_code between \"",first_person, 
			"\" AND \"",last_person,"\" " 
		END IF 
		LET where_text = where_text clipped," AND reqhead.ware_code ", 
		" between \"",first_ware,"\" AND \"",last_ware,"\" " 
		RETURN true 
	END IF 
END FUNCTION 
