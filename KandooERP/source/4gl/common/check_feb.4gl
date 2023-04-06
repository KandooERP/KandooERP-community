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

	Source code beautified by beautify.pl on 2020-01-02 10:35:06	$Id: $
}



GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION check_feb(p_inv_date, p_day_num) 
	DEFINE p_inv_date LIKE invoicehead.inv_date 
	DEFINE p_day_num LIKE term.due_day_num
	DEFINE l_year_num SMALLINT
	DEFINE r_due_date LIKE invoicehead.inv_date	 

	IF (MONTH(p_inv_date) + 1) > 12 THEN 
		LET l_year_num = YEAR(p_inv_date) + 1 
	ELSE 
		LET l_year_num = YEAR(p_inv_date) 
	END IF 


	# IF due day of MONTH IS the 29th OR 30th
	IF p_day_num > 28 THEN 

		# IF february IS the due MONTH
		IF MONTH(p_inv_date) + 1 = 2 THEN 

			# IF a leap year, THEN
			IF ( (YEAR(p_inv_date)) mod 4 ) <> 0 THEN 
				LET p_day_num = 28 
			ELSE 
				LET p_day_num = 29 
			END IF 
		END IF 
	END IF 

	LET r_due_date = 
	MDY((MONTH(p_inv_date) + 1), p_day_num, l_year_num ) 

	RETURN r_due_date 

END FUNCTION 




