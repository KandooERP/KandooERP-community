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

	Source code beautified by beautify.pl on 2020-01-02 10:35:11	$Id: $
}



GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION cont_inv_range(p_cmpy_code,p_contract_code,p_inv_num,p_inv_date) 
	DEFINE p_cmpy_code LIKE contracthead.cmpy_code 
	DEFINE p_contract_code LIKE contracthead.contract_code 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_inv_date LIKE invoicehead.inv_date 
	DEFINE l_rec_contracthead RECORD LIKE contracthead.* 
	DEFINE l_end_date DATE
	DEFINE l_start_date DATE
	DEFINE l_next_date DATE	
	DEFINE l_year SMALLINT 
	DEFINE l_month SMALLINT
	DEFINE l_day SMALLINT
	DEFINE l_day2 SMALLINT

	SELECT * 
	INTO l_rec_contracthead.* 
	FROM contracthead 
	WHERE cmpy_code = p_cmpy_code 
	AND contract_code = p_contract_code 

	IF status = notfound THEN 
		RETURN p_inv_date,p_inv_date 
	END IF 

	LET l_end_date = l_rec_contracthead.end_date 

	# Find END of same year as invoice

	WHILE (l_end_date - p_inv_date) > 400 
		LET l_year = year(l_end_date) 
		LET l_month = month(l_end_date) 
		LET l_day = day(l_end_date) 
		IF l_month = 2 AND l_day = 29 THEN LET l_day = 28 END IF 
			LET l_year = l_year - 1 
			LET l_end_date = mdy(l_month,l_day,l_year) 
		END WHILE 

		LET l_start_date = l_rec_contracthead.start_date 

		# Find start of same year as invoice

		IF (l_end_date - l_start_date) > 400 THEN 
			LET l_year = year(l_end_date) 
			LET l_month = month(l_end_date) 
			LET l_day = day(l_end_date) 
			IF l_month = 2 AND l_day = 29 THEN LET l_day = 28 END IF 
				LET l_year = l_year - 1 
				LET l_start_date = mdy(l_month,l_day,l_year) 
				LET l_start_date = l_start_date + 1 
			END IF 

			LET l_day = day(l_end_date) 
			LET l_day2 = day(l_start_date) 
			IF l_day = l_day2 THEN 
				LET l_end_date = l_end_date - 1 
			END IF 

			# Find date of next invoice remaining in this year (IF any)

			SELECT min(invoice_date) 
			INTO l_next_date 
			FROM contractdate 
			WHERE cmpy_code = p_cmpy_code 
			AND contract_code = p_contract_code 
			AND invoice_date between (p_inv_date+1) AND l_end_date 

			IF status = notfound OR l_next_date IS NULL THEN 
				LET l_next_date = l_end_date 
			END IF 

			LET l_day = day(l_next_date) 
			LET l_day2 = day(p_inv_date) 
			IF l_day = l_day2 THEN 
				LET l_next_date = l_next_date - 1 
			END IF 

			RETURN p_inv_date,l_next_date 

END FUNCTION { cont_inv_range } 

FUNCTION chk_cont_gst_exempt(p_cmpy_code,p_contract_code,p_start_date,p_end_date,p_invoice_date) 
	DEFINE p_cmpy_code LIKE contracthead.cmpy_code 
	DEFINE p_contract_code LIKE contracthead.contract_code 
	DEFINE p_start_date DATE
	DEFINE p_end_date DATE 
	DEFINE p_invoice_date DATE
	DEFINE l_cs DATE
	DEFINE l_ce DATE
	DEFINE r_exempt_flag SMALLINT 

	LET l_ce = mdy(7,1,2000) # START OF gst 

	IF p_end_date < l_ce THEN 
		# No GST
		RETURN true 
	END IF 

	LET l_cs = mdy(7,8,1999) # END OF gst exempt period 

	IF p_start_date >= l_cs THEN 
		# Not GST exempt
		RETURN false 
	END IF 

	# Check IF contract in exemption table

	DECLARE chk_contgstex CURSOR FOR 
	SELECT expiry_date 
	INTO l_ce 
	FROM contgstexempt 
	WHERE cmpy_code = p_cmpy_code 
	AND contract_code = p_contract_code 

	OPEN chk_contgstex 
	FETCH chk_contgstex 

	IF status = notfound THEN 
		# Not exempt
		LET r_exempt_flag = false 
	ELSE 
		# Check hasn't expired
		IF l_ce > p_invoice_date THEN 
			LET r_exempt_flag = true 
		ELSE 
			LET r_exempt_flag = false 
		END IF 
	END IF 

	CLOSE chk_contgstex 

	RETURN r_exempt_flag 

END FUNCTION { chk_cont_gst_exempt } 


