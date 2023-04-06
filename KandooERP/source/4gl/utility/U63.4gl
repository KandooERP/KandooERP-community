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

	Source code beautified by beautify.pl on 2020-01-03 18:54:46	$Id: $
}



#   U63 - Management Information Statistics Parameters
#         allows the user TO enter AND maintain statistic Parameters
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	pr_statparms RECORD LIKE statparms.* 
END GLOBALS 


###################################################################
# MAIN
#
#
###################################################################
MAIN 

	CALL setModuleId("U218") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW u218 with FORM "U218" 
	CALL windecoration_u("U218") 

	MENU " MIS Parameters" 
		BEFORE MENU 
			IF disp_parm() THEN 
				HIDE option "ADD" 
			ELSE 
				HIDE option "Change" 
			END IF 
			CALL publish_toolbar("kandoo","U63","menu-mis_parameters") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Display" " DISPLAY Parameters" 
			IF NOT disp_parm() THEN 
			END IF 
		COMMAND "ADD" " Add Management Information Statistics Parameters" 
			CALL add_parm() 
			IF disp_parm() THEN 
				HIDE option "ADD" 
				SHOW option "Change" 
			END IF 
		COMMAND "Change" " Change Parameters" 
			IF change_parm() THEN 
				UPDATE statparms SET * = pr_statparms.* 
				WHERE parm_code = "1" 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			ELSE 
				IF disp_parm() THEN 
				END IF 
			END IF 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW u218 
END MAIN 


FUNCTION disp_parm() 
	DEFINE 
	pr_temp_text CHAR(20) 

	SELECT statparms.* INTO pr_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
		IF pr_statparms.day_type_code IS NOT NULL THEN 
			SELECT type_text INTO pr_temp_text 
			FROM stattype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_statparms.day_type_code 
			AND type_ind = "1" 
			IF sqlca.sqlcode = 0 THEN 
				DISPLAY pr_temp_text TO day_text 

			END IF 
		END IF 
		IF pr_statparms.week_type_code IS NOT NULL THEN 
			SELECT type_text INTO pr_temp_text 
			FROM stattype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_statparms.week_type_code 
			AND type_ind = "2" 
			IF sqlca.sqlcode = notfound THEN 
				DISPLAY pr_temp_text TO week_text 

			END IF 
		END IF 
		IF pr_statparms.mth_type_code IS NOT NULL THEN 
			SELECT type_text INTO pr_temp_text 
			FROM stattype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_statparms.mth_type_code 
			AND type_ind = "4" 
			IF sqlca.sqlcode = 0 THEN 
				DISPLAY pr_temp_text TO month_text 

			END IF 
		END IF 
		IF pr_statparms.qtr_type_code IS NOT NULL THEN 
			SELECT type_text INTO pr_temp_text 
			FROM stattype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_statparms.qtr_type_code 
			AND type_ind = "7" 
			IF sqlca.sqlcode = 0 THEN 
				DISPLAY pr_temp_text TO qtr_text 

			END IF 
		END IF 
		IF pr_statparms.year_type_code IS NOT NULL THEN 
			SELECT type_text INTO pr_temp_text 
			FROM stattype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_statparms.year_type_code 
			AND type_ind = "8" 
			IF sqlca.sqlcode = 0 THEN 
				DISPLAY pr_temp_text TO year_text 

			END IF 
		END IF 
		IF pr_statparms.day_num IS NULL THEN 
			SELECT int_num, 
			int_text 
			INTO pr_statparms.day_num, 
			pr_temp_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = year(today) 
			AND type_code = pr_statparms.day_type_code 
			AND start_date <= today 
			AND end_date >= today 
		ELSE 
			SELECT int_text INTO pr_temp_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = pr_statparms.year_num 
			AND type_code = pr_statparms.day_type_code 
			AND int_num = pr_statparms.day_num 
		END IF 
		IF sqlca.sqlcode = 0 THEN 
			DISPLAY pr_temp_text TO daynum_text 

		END IF 
		IF pr_statparms.week_num IS NULL THEN 
			SELECT int_num, 
			int_text 
			INTO pr_statparms.week_num, 
			pr_temp_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = year(today) 
			AND type_code = pr_statparms.week_type_code 
			AND start_date <= today 
			AND end_date >= today 
		ELSE 
			SELECT int_text INTO pr_temp_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = pr_statparms.year_num 
			AND type_code = pr_statparms.week_type_code 
			AND int_num = pr_statparms.week_num 
		END IF 
		IF sqlca.sqlcode = 0 THEN 
			DISPLAY pr_temp_text TO weeknum_text 

		END IF 
		IF pr_statparms.mth_num IS NULL THEN 
			SELECT int_num, 
			int_text 
			INTO pr_statparms.mth_num, 
			pr_temp_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = year(today) 
			AND type_code = pr_statparms.mth_type_code 
			AND start_date <= today 
			AND end_date >= today 
		ELSE 
			SELECT int_text INTO pr_temp_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = pr_statparms.year_num 
			AND type_code = pr_statparms.mth_type_code 
			AND int_num = pr_statparms.mth_num 
		END IF 
		IF sqlca.sqlcode = 0 THEN 
			DISPLAY pr_temp_text TO monthnum_text 

		END IF 
		IF pr_statparms.qtr_num IS NULL THEN 
			SELECT int_num, 
			int_text 
			INTO pr_statparms.qtr_num, 
			pr_temp_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = year(today) 
			AND type_code = pr_statparms.qtr_type_code 
			AND start_date <= today 
			AND end_date >= today 
		ELSE 
			SELECT int_text INTO pr_temp_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = pr_statparms.year_num 
			AND type_code = pr_statparms.qtr_type_code 
			AND int_num = pr_statparms.qtr_num 
		END IF 
		IF sqlca.sqlcode = 0 THEN 
			DISPLAY pr_temp_text TO qtrnum_text 

		END IF 
		IF pr_statparms.year_num IS NULL OR pr_statparms.year_num = 0 THEN 
			LET pr_statparms.year_num = year(today) 
		ELSE 
			SELECT int_text INTO pr_temp_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = pr_statparms.year_num 
			AND type_code = pr_statparms.year_type_code 
			AND int_num = pr_statparms.year_num 
		END IF 
		IF sqlca.sqlcode = 0 THEN 
			DISPLAY pr_temp_text TO yearnum_text 

		END IF 
		DISPLAY BY NAME pr_statparms.day_type_code, 
		pr_statparms.week_type_code, 
		pr_statparms.mth_type_code, 
		pr_statparms.qtr_type_code, 
		pr_statparms.year_type_code, 
		pr_statparms.day_num, 
		pr_statparms.week_num, 
		pr_statparms.mth_num, 
		pr_statparms.qtr_num, 
		pr_statparms.year_num, 
		pr_statparms.cust_rank1_amt, 
		pr_statparms.cust_rank2_amt, 
		pr_statparms.cust_rank3_amt, 
		pr_statparms.cust_rank4_amt, 
		pr_statparms.new_days_num, 
		pr_statparms.lost_days_num, 
		pr_statparms.last_upd_date, 
		pr_statparms.last_dist_date, 
		pr_statparms.last_purge_date 

		RETURN true 
	END IF 
END FUNCTION 


FUNCTION add_parm() 
	DEFINE l_msgresp LIKE language.yes_flag
	
	INITIALIZE pr_statparms.* TO NULL 
	LET pr_statparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_statparms.parm_code = "1" 
	LET pr_statparms.day_num = NULL 
	LET pr_statparms.week_num = NULL 
	LET pr_statparms.mth_num = NULL 
	LET pr_statparms.qtr_num = NULL 
	LET pr_statparms.year_num = year(today) 
	LET pr_statparms.cust_rank1_amt = 0 
	LET pr_statparms.cust_rank2_amt = 0 
	LET pr_statparms.cust_rank3_amt = 0 
	LET pr_statparms.cust_rank4_amt = 0 
	LET pr_statparms.new_days_num = 0 
	LET pr_statparms.lost_days_num = 0 
	LET pr_statparms.last_upd_date = today 
	LET pr_statparms.last_dist_date = today 
	LET pr_statparms.last_purge_date = today 
	IF change_parm() THEN 
		INSERT INTO statparms VALUES (pr_statparms.*) 
	END IF 
END FUNCTION 


FUNCTION change_parm() 
	DEFINE pr_temp_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	INPUT BY NAME pr_statparms.day_type_code, 
	pr_statparms.week_type_code, 
	pr_statparms.mth_type_code, 
	pr_statparms.qtr_type_code, 
	pr_statparms.year_type_code, 
	pr_statparms.cust_rank1_amt, 
	pr_statparms.cust_rank2_amt, 
	pr_statparms.cust_rank3_amt, 
	pr_statparms.cust_rank4_amt, 
	pr_statparms.new_days_num, 
	pr_statparms.lost_days_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U63","input-statparms") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield(day_type_code) 
					LET pr_temp_text = "AND type_ind = '1'" 
					LET pr_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_statparms.day_type_code = pr_temp_text 
						NEXT FIELD day_type_code 
					END IF 

		ON ACTION "LOOKUP" infield(week_type_code) 
					LET pr_temp_text = "AND type_ind = '2'" 
					LET pr_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_statparms.week_type_code = pr_temp_text 
						NEXT FIELD week_type_code 
					END IF 

		ON ACTION "LOOKUP" infield(mth_type_code) 
					LET pr_temp_text = "AND type_ind = '4'" 
					LET pr_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_statparms.mth_type_code = pr_temp_text 
						NEXT FIELD mth_type_code 
					END IF 

		ON ACTION "LOOKUP" infield(qtr_type_code) 
					LET pr_temp_text = "AND type_ind = '7'" 
					LET pr_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_statparms.qtr_type_code = pr_temp_text 
						NEXT FIELD qtr_type_code 
					END IF 

		ON ACTION "LOOKUP" infield(year_type_code) 
					LET pr_temp_text = "AND type_ind = '8'" 
					LET pr_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_statparms.year_type_code = pr_temp_text 
						NEXT FIELD year_type_code 
					END IF 

		AFTER FIELD day_type_code 
			CLEAR day_text 
			IF pr_statparms.day_type_code IS NOT NULL THEN 
				SELECT type_text INTO pr_temp_text 
				FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_statparms.day_type_code 
				AND type_ind = "1" --type 1 =s daily ???? 
				IF sqlca.sqlcode = notfound THEN 
					LET l_msgresp = kandoomsg("E",9202,"") 
					#9202" Interval type code does NOT exist - Try Window"
					NEXT FIELD day_type_code 
				ELSE 
					DISPLAY pr_temp_text TO day_text 

				END IF 
			END IF 
		AFTER FIELD week_type_code 
			CLEAR week_text 
			IF pr_statparms.week_type_code IS NOT NULL THEN 
				SELECT type_text INTO pr_temp_text 
				FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_statparms.week_type_code 
				AND type_ind = "2" 
				IF sqlca.sqlcode = notfound THEN 
					LET l_msgresp = kandoomsg("E",9202,"") 
					#9202" Interval type code does NOT exist - Try Window"
					NEXT FIELD week_type_code 
				ELSE 
					DISPLAY pr_temp_text TO week_text 

				END IF 
			END IF 
		AFTER FIELD mth_type_code 
			CLEAR month_text 
			IF pr_statparms.mth_type_code IS NOT NULL THEN 
				SELECT type_text INTO pr_temp_text 
				FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_statparms.mth_type_code 
				AND type_ind = "4" 
				IF sqlca.sqlcode = notfound THEN 
					LET l_msgresp = kandoomsg("E",9202,"") 
					#9202" Interval type code does NOT exist - Try Window"
					NEXT FIELD mth_type_code 
				ELSE 
					DISPLAY pr_temp_text TO month_text 

				END IF 
			END IF 
		AFTER FIELD qtr_type_code 
			CLEAR qtr_text 
			IF pr_statparms.qtr_type_code IS NOT NULL THEN 
				SELECT type_text INTO pr_temp_text 
				FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_statparms.qtr_type_code 
				AND type_ind = "7" 
				IF sqlca.sqlcode = notfound THEN 
					LET l_msgresp = kandoomsg("E",9202,"") 
					#9202" Interval type code does NOT exist - Try Window"
					NEXT FIELD qtr_type_code 
				ELSE 
					DISPLAY pr_temp_text TO qtr_text 

				END IF 
			END IF 
		AFTER FIELD year_type_code 
			CLEAR year_text 
			IF pr_statparms.year_type_code IS NOT NULL THEN 
				SELECT type_text INTO pr_temp_text 
				FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_statparms.year_type_code 
				AND type_ind = "8" 
				IF sqlca.sqlcode = notfound THEN 
					LET l_msgresp = kandoomsg("E",9202,"") 
					#9202" Interval type code does NOT exist - Try Window"
					NEXT FIELD year_type_code 
				ELSE 
					DISPLAY pr_temp_text TO year_text 

				END IF 
			END IF 
		AFTER FIELD cust_rank1_amt 
			IF pr_statparms.cust_rank1_amt < 0 
			OR pr_statparms.cust_rank1_amt IS NULL THEN 
				LET l_msgresp = kandoomsg("E",9226,"") 
				#9226 " Customer ranking threshold must be greater than zero "
				NEXT FIELD cust_rank1_amt 
			END IF 
		AFTER FIELD cust_rank2_amt 
			IF pr_statparms.cust_rank2_amt < 0 
			OR pr_statparms.cust_rank2_amt IS NULL THEN 
				LET l_msgresp = kandoomsg("E",9226,"") 
				#9226 " Customer ranking threshold must be greater than zero "
				NEXT FIELD cust_rank2_amt 
			END IF 
		AFTER FIELD cust_rank3_amt 
			IF pr_statparms.cust_rank3_amt < 0 
			OR pr_statparms.cust_rank3_amt IS NULL THEN 
				LET l_msgresp = kandoomsg("E",9226,"") 
				#9226 " Customer ranking threshold must be greater than zero "
				NEXT FIELD cust_rank3_amt 
			END IF 
		AFTER FIELD cust_rank4_amt 
			IF pr_statparms.cust_rank4_amt < 0 
			OR pr_statparms.cust_rank4_amt IS NULL THEN 
				LET l_msgresp = kandoomsg("E",9226,"") 
				#9226 " Customer ranking threshold must be greater than zero "
				NEXT FIELD cust_rank4_amt 
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


