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
# \brief module - cicdwind.4gl
# Purpose - Allows user TO view corporate debtors details

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION cinq_cd(p_cmpy,p_cust) 
	DEFINE 
	p_cmpy LIKE customer.cmpy_code, 
	p_cust LIKE customer.cust_code, 
	pr_corp_cust RECORD LIKE customer.*, 
	pr_arparms RECORD LIKE arparms.*, 
	msgresp LIKE language.yes_flag 

	SELECT arparms.* INTO pr_arparms.* FROM arparms 
	WHERE arparms.cmpy_code = p_cmpy 
	AND arparms.parm_code = "1" 
	IF status = notfound THEN 
		CALL fgl_winmessage("Exit",kandoomsg2("A",9107,""),"ERROR") 
		EXIT program 
	END IF 
	IF pr_arparms.corp_drs_flag = "Y" THEN 

		OPEN WINDOW A205a with FORM "A205a" 
		CALL windecoration_a("A205a") 

		SELECT * INTO pr_corp_cust.* FROM customer 
		WHERE customer.cmpy_code = p_cmpy 
		AND cust_code = p_cust 
		DISPLAY BY NAME pr_corp_cust.corp_cust_code, 
		pr_corp_cust.corp_cust_ind, 
		pr_corp_cust.inv_addr_flag, 
		pr_corp_cust.sales_anly_flag, 
		pr_corp_cust.credit_chk_flag 

		CALL eventsuspend() 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

		CLOSE WINDOW A205a 

	ELSE 
		MESSAGE kandoomsg2("A",5006,"") 
	END IF 

END FUNCTION 


