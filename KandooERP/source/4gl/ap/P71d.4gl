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

	Source code beautified by beautify.pl on 2020-01-03 13:41:34	$Id: $
}



#
#          P71d.4gl generates the Nth payment date based upon
#          next_vouch_date, int_ind, int_num, max_run_num, p_project_num
#
#          p_project_num represents the Nth payment date
#          FROM (AND including) the next_vouch_date
#          (N.B. next_vouch_date will therefore be the 1st payment date
#          returned)
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P7_GLOBALS.4gl"
GLOBALS "../ap/P71_GLOBALS.4gl"

############################################################
# MODULE Scope Variables
############################################################


FUNCTION generate_int(p_rec_recurhead,p_project_num) 
	DEFINE p_rec_recurhead RECORD LIKE recurhead.* 
	DEFINE p_project_num LIKE recurhead.max_run_num 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_disc_date DATE 
	DEFINE l_mth_num SMALLINT
	DEFINE l_yr_num SMALLINT
	DEFINE r_end_date LIKE recurhead.end_date
	DEFINE idx SMALLINT 

	IF p_project_num IS NULL 
	OR p_rec_recurhead.next_vouch_date IS NULL 
	OR p_rec_recurhead.int_ind IS NULL 
	OR p_rec_recurhead.int_num IS NULL 
	OR p_rec_recurhead.max_run_num IS NULL 
	OR (p_rec_recurhead.int_ind = "6" AND p_rec_recurhead.term_code IS null) THEN 
		LET r_end_date = NULL 
	ELSE 
		CASE 
			WHEN p_project_num <= 0 
				LET r_end_date = p_rec_recurhead.last_vouch_date 
			WHEN p_project_num = 999 
				LET r_end_date = NULL 
			OTHERWISE 
				CASE p_rec_recurhead.int_ind 
					WHEN "1" 
						LET r_end_date = p_rec_recurhead.next_vouch_date + 
						(1 * p_rec_recurhead.int_num * (p_project_num-1)) 
					WHEN "2" 
						LET r_end_date = p_rec_recurhead.next_vouch_date + 
						(7 * p_rec_recurhead.int_num * (p_project_num-1)) 
					WHEN "3 " 
						LET r_end_date = p_rec_recurhead.next_vouch_date + 
						(14 * p_rec_recurhead.int_num * (p_project_num-1)) 
					WHEN "4" 
						LET l_mth_num = month(p_rec_recurhead.next_vouch_date) + 
						((p_project_num-1) * p_rec_recurhead.int_num) 
						LET r_end_date = dmy_date(day(p_rec_recurhead.next_vouch_date), 
						l_mth_num, 
						year(p_rec_recurhead.next_vouch_date)) 
					WHEN ("6") 
						SELECT * INTO l_rec_term.* 
						FROM term 
						WHERE cmpy_code = p_rec_recurhead.cmpy_code 
						AND term_code = p_rec_recurhead.term_code 
						LET r_end_date = p_rec_recurhead.next_vouch_date 
						FOR idx = 1 TO (p_project_num - 1) 
							CALL get_due_and_discount_date(l_rec_term.*, r_end_date) 
							RETURNING r_end_date, l_disc_date 
						END FOR 
					WHEN ("7") 
						LET l_mth_num = month(p_rec_recurhead.next_vouch_date) + 
						((p_project_num-1) * p_rec_recurhead.int_num * 3) 
						LET r_end_date = dmy_date(day(p_rec_recurhead.next_vouch_date), 
						l_mth_num, 
						year(p_rec_recurhead.next_vouch_date)) 
					WHEN ("8") 
						LET l_yr_num = year(p_rec_recurhead.next_vouch_date) + 
						((p_project_num-1) * p_rec_recurhead.int_num) 
						LET r_end_date = dmy_date(day(p_rec_recurhead.next_vouch_date), 
						month(p_rec_recurhead.next_vouch_date), 
						l_yr_num) 
				END CASE 
		END CASE 
	END IF 
	RETURN r_end_date 
END FUNCTION 


