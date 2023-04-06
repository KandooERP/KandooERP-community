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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW1_GLOBALS.4gl" 
############################################################
# FUNCTION GW1_main()
#
# GW1 - This module contains the global declarations AND main
#       functions FOR the Report processing functions.
############################################################
FUNCTION GW1_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GW1") 

	CALL create_table("colaccum","t_colaccum","","N") 

	CREATE INDEX tx_colaccum ON t_colaccum(col_uid,accum_id) 
	LET glob_consolidations_exist = false 

	SELECT unique 1 FROM consolhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status != NOTFOUND THEN 
		#Consolidations found - Dont SET flag until we check the structure
		SELECT * INTO glob_rec_structure.* FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_ind = "L" 
		IF status != NOTFOUND THEN 
			LET glob_consolidations_exist = true 
			LET glob_start_num = glob_rec_structure.start_num 
			LET glob_length_num = glob_rec_structure.start_num 
			+ glob_rec_structure.length_num - 1 
		END IF 
	END IF 

	OPEN WINDOW G500 with FORM "G500" 
	CALL windecoration_g("G500") 

	MENU " Management Reports" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GW1","menu-management-reports") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report"	#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
			CALL start_up() 
			CALL get_rtime_criteria() 
			IF NOT (int_flag OR quit_flag) THEN 
				CALL produce_rpt() 
				CALL finish_up(true) 
			ELSE 
				CALL finish_up(false) 
			END IF 


		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit"	#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
			EXIT MENU 

	END MENU 
	CLOSE WINDOW G500 
END FUNCTION 


############################################################
# FUNCTION start_up()
#
# Optional URL agruments: report_id
############################################################
FUNCTION start_up() 
	DEFINE l_year_num LIKE period.year_num 
	DEFINE l_period_num LIKE period.period_num 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO glob_rec_mrwparms.* FROM mrwparms 
	LET glob_rpt_id = get_url_report_id() #arg_val(2) 
	IF glob_rpt_id <= " " OR (glob_rpt_id=0) OR (glob_rpt_id IS NULL) THEN 
		#we won't try AND SELECT anything
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = glob_rpt_id 
		IF status THEN 
			LET l_msgresp = kandoomsg("U",9112,"REPORT identifier passed as parameter") 
			#9112 "Invalid REPORT identifier passed as parameter"
			INITIALIZE glob_rec_rpthead.* TO NULL 
			INITIALIZE glob_rpt_id TO NULL 
		ELSE 
			#the REPORT parameter appears OK
		END IF 
	END IF 

	LET glob_year_num = get_url_fiscal_year_num() #arg_val(3) 

	IF glob_year_num > 0 THEN 
		#we will accept the parameter passed on the command line
	ELSE 
		#we will try AND default this value TO the year number
		#FOR last period
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, mdy (month(today), 1, year(today) ) -1) 
		RETURNING l_year_num,		l_period_num 
		LET glob_year_num = l_year_num 
	END IF 

	LET glob_rec_entry_criteria.year_num = glob_year_num 
	LET glob_period_num = get_url_fiscal_period_num() #arg_val(4) 
	IF glob_period_num > 0 THEN 
		#we will accept the parameter passed on the command line
	ELSE 
		#we will try AND SET the default period number TO
		#the period FOR the last month
		IF l_period_num > 0 THEN 
			LET glob_period_num = l_period_num 
		ELSE 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, mdy (month(today), 1, year(today) ) -1) 
			RETURNING l_year_num,	l_period_num 
			LET glob_period_num = l_period_num 
		END IF 
	END IF 

	LET glob_rec_entry_criteria.period_num = glob_period_num 
	LET glob_group_code = get_url_group_code() #arg_val(5) 
	LET glob_acct_code = get_url_acct_code() #arg_val(6) 
	LET glob_rec_rpt_selector.report_date = get_url_report_date() #arg_val(7) 

	IF glob_rec_rpt_selector.report_date > 0 THEN 
		#leave the date as passed on the command line
	ELSE 
		LET glob_rec_rpt_selector.report_date = today 
		LET glob_rec_entry_criteria.glob_rpt_date = glob_rec_rpt_selector.report_date 
	END IF 
END FUNCTION 


############################################################
# FUNCTION finish_up()
#
#
############################################################
FUNCTION finish_up(p_done) 
	DEFINE p_done boolean #this was a screwup.. was global.. AND global was nowhere handled 
	IF (not p_done) OR (int_flag OR quit_flag) THEN 
		MESSAGE "Management REPORT process aborted" 
	ELSE 
		MESSAGE "Management REPORT process complete" 
	END IF 
END FUNCTION 
