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

############################################################
# FUNCTION get_due_and_discount_date(p_rec_term, p_start_date)
#
# get_due_and_discount_date calculates the due AND discount dates
# RETURN r_due_date,r_disc_date 
############################################################
FUNCTION get_due_and_discount_date(p_rec_term,p_start_date) 
	DEFINE p_rec_term RECORD LIKE term.* 
	DEFINE p_start_date DATE 
	DEFINE l_pr_cut_off_date DATE 
	DEFINE l_pr_mth_num SMALLINT 
	DEFINE r_due_date  DATE 
	DEFINE r_disc_date DATE 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	LET r_disc_date = p_start_date + p_rec_term.disc_day_num 

	CASE p_rec_term.day_date_ind 
		WHEN "D" 
			LET r_due_date = p_start_date + p_rec_term.due_day_num 
		WHEN "T" 
			LET l_pr_mth_num =MONTH(p_start_date) + 1 
			LET r_due_date =dmy_date(p_rec_term.due_day_num,l_pr_mth_num,YEAR(p_start_date)) 

		WHEN "C" 
			IF p_rec_term.due_day_num = 0 THEN 
				LET l_pr_mth_num = MONTH(p_start_date) + 2 
			ELSE 
				LET l_pr_cut_off_date = dmy_date(p_rec_term.due_day_num, 
				MONTH(p_start_date), 
				YEAR(p_start_date)) 
				IF p_start_date <= l_pr_cut_off_date THEN 
					LET l_pr_mth_num = MONTH(p_start_date) + 1 
				ELSE 
					LET l_pr_mth_num = MONTH(p_start_date) + 2 
				END IF 
			END IF 
			LET r_due_date = dmy_date(31,l_pr_mth_num,YEAR(p_start_date)) 

		WHEN "W" 
			LET l_pr_mth_num =MONTH(p_start_date) + 1 
			LET r_due_date =dmy_date(p_rec_term.due_day_num,l_pr_mth_num,YEAR(p_start_date)) 
			CASE WEEKDAY(r_due_date) 
				WHEN "0" 
					IF MONTH(r_due_date) = MONTH(r_due_date+1) THEN 
						LET r_due_date = r_due_date + 1 # sunday 
					ELSE 
						LET r_due_date = r_due_date - 2 # LAST sunday OF month 
					END IF 
				WHEN "6" 
					IF MONTH(r_due_date) = MONTH(r_due_date-1) THEN 
						LET r_due_date = r_due_date - 1 # saturday 
					ELSE 
						LET r_due_date = r_due_date + 2 # FIRST saturday OF month 
					END IF 
			END CASE 

		OTHERWISE 
			IF (p_rec_term.due_day_num =0) THEN 
				LET l_pr_mth_num = MONTH(p_start_date) + 1 
				LET r_due_date = dmy_date(31,l_pr_mth_num,YEAR(p_start_date)) 
				WHILE WEEKDAY(r_due_date) != p_rec_term.day_date_ind - 1 
					LET r_due_date = r_due_date - 1 
				END WHILE 
			ELSE 
				LET r_due_date = p_start_date + p_rec_term.due_day_num 
				WHILE WEEKDAY(r_due_date) != p_rec_term.day_date_ind - 1 
					LET r_due_date = r_due_date + 1 
				END WHILE 
			END IF 
	END CASE 

	RETURN r_due_date,r_disc_date 
END FUNCTION 
############################################################
# END FUNCTION get_due_and_discount_date(p_rec_term, p_start_date)
############################################################


############################################################
# FUNCTION dmy_date(p_day_num,p_mth_num,p_year_num)
#
## same as MDY() but handles invalid dates
############################################################
FUNCTION dmy_date(p_day_num,p_mth_num,p_year_num) 
	DEFINE p_day_num SMALLINT 
	DEFINE p_mth_num SMALLINT 
	DEFINE p_year_num SMALLINT 

	WHILE p_mth_num > 12 
		LET p_mth_num = p_mth_num - 12 
		LET p_year_num = p_year_num + 1 
	END WHILE 

	IF p_mth_num = 2 AND p_day_num > 28 THEN 
		LET p_day_num = DAY(MDY(3,1,p_year_num)-1) 
	END IF 

	IF p_day_num > 30 THEN 
		IF p_mth_num = 4 OR p_mth_num = 6 
		OR p_mth_num = 9 OR p_mth_num = 11 THEN 
			LET p_day_num = DAY(MDY((p_mth_num+1),1,p_year_num)-1) 
		ELSE 
			LET p_day_num = 31 
		END IF 
	END IF 

	RETURN MDY(p_mth_num,p_day_num,p_year_num) 
END FUNCTION 
############################################################
# END FUNCTION dmy_date(p_day_num,p_mth_num,p_year_num)
############################################################