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
# FUNCTION show_disc( p_cmpy, p_term_code, p_pay_date, p_trans_date )
#
# show_disc returns the discount valid AT the time of payment
############################################################
FUNCTION show_disc(p_cmpy,p_term_code,p_pay_date,p_trans_date) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_term_code LIKE term.term_code 
	DEFINE p_pay_date LIKE invoicehead.paid_date 
	DEFINE p_trans_date LIKE invoicehead.inv_date 
	DEFINE l_rec_termdetl RECORD LIKE termdetl.* 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	SELECT unique 1 FROM term 
	WHERE cmpy_code = p_cmpy 
	AND term_code = p_term_code 
	IF SQLCA.SQLCODE = NOTFOUND THEN
		RETURN FALSE 	# Logic Error : Term code NOT found
	END IF 
	
	SELECT unique 1 FROM termdetl 
	WHERE cmpy_code = p_cmpy 
	AND term_code = p_term_code 
	IF SQLCA.SQLCODE = NOTFOUND THEN 
		RETURN FALSE # Logic Error : Term code NOT SET up FOR termdetl table 
	END IF 

	DECLARE c_termdetl CURSOR FOR 
	SELECT * FROM termdetl 
	WHERE cmpy_code = p_cmpy 
	AND term_code = p_term_code 
	AND days_num >= ( p_pay_date - p_trans_date ) 
	ORDER BY days_num 

	OPEN c_termdetl 
	FETCH c_termdetl INTO l_rec_termdetl.* 

	IF SQLCA.SQLCODE = NOTFOUND THEN 
		RETURN FALSE 
	ELSE 
		RETURN l_rec_termdetl.disc_per 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION show_disc( p_cmpy, p_term_code, p_pay_date, p_trans_date )
############################################################