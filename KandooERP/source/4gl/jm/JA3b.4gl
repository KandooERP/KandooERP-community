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

	Source code beautified by beautify.pl on 2020-01-02 19:48:17	$Id: $
}




# Module  - JA3b - Contract Enquiry
# Purpose - DISPLAY Contract Detail Lines

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA3_GLOBALS.4gl" 

FUNCTION condetldisp() 


	SELECT * INTO pr_contractdetl.* FROM contractdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND contract_code = pr_contractdetl.contract_code 
	AND line_num = pr_contractdetl.line_num 

	SELECT * INTO pr_customership.* FROM customership 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_contractdetl.cust_code 
	AND ship_code = pr_contractdetl.ship_code 

	# code FOR FETCHing user defined prompts

	CASE 
		WHEN pr_contractdetl.type_code = "J" 
			CALL condetldispj() 
		WHEN pr_contractdetl.type_code = "I" 
			CALL condetldispi() 
		WHEN pr_contractdetl.type_code = "G" 
			CALL condetldispg() 
	END CASE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

END FUNCTION 

FUNCTION condetldispj() 
	SELECT * INTO pr_job.* FROM job 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_contractdetl.job_code 
	AND cust_code = pr_contractdetl.cust_code 
	SELECT * INTO pr_jobvars.* FROM jobvars 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_contractdetl.job_code 
	AND var_code = pr_contractdetl.var_code 
	OPEN WINDOW wja03 with FORM "JA03" -- alch kd-747 
	CALL winDecoration_j("JA03") -- alch kd-747 
	DISPLAY BY NAME pr_contractdetl.type_code , 
	pr_contractdetl.ship_code , 
	pr_customership.name_text , 
	pr_customership.addr_text , 
	pr_customership.addr2_text , 
	pr_customership.city_text , 
	pr_customership.state_code , 
	pr_customership.post_code , 
	pr_contractdetl.user1_text , 
	pr_contractdetl.user2_text , 
	pr_contractdetl.job_code , 
	pr_contractdetl.var_code , 
	pr_contractdetl.activity_code , 
	pr_contractdetl.desc_text 
	DISPLAY pr_job.title_text TO job_text 
	DISPLAY pr_jobvars.title_text TO jobvars_text 
	#LET msgresp = kandoomsg("A",7001,"")
	# Press any key TO continue
	CALL eventsuspend() 
	CLOSE WINDOW wja03 
END FUNCTION 

FUNCTION condetldispi() 
	OPEN WINDOW wja04 with FORM "JA04" -- alch kd-747 
	CALL winDecoration_j("JA04") -- alch kd-747 
	DISPLAY BY NAME pr_contractdetl.type_code , 
	pr_contractdetl.ship_code , 
	pr_customership.name_text , 
	pr_customership.addr_text , 
	pr_customership.addr2_text , 
	pr_customership.city_text , 
	pr_customership.state_code , 
	pr_customership.post_code , 
	pr_contractdetl.user1_text , 
	pr_contractdetl.user2_text , 
	pr_contractdetl.part_code , 
	pr_contractdetl.desc_text , 
	pr_contractdetl.bill_qty , 
	pr_contractdetl.bill_price 


	#LET msgresp = kandoomsg("A",7001,"")
	# Press any key TO continue
	CALL eventsuspend() 

	CLOSE WINDOW wja04 

END FUNCTION 


FUNCTION condetldispg() 
	OPEN WINDOW wja05 with FORM "JA05" -- alch kd-747 
	CALL winDecoration_j("JA05") -- alch kd-747 
	DISPLAY BY NAME pr_contractdetl.type_code , 
	pr_contractdetl.ship_code , 
	pr_customership.name_text , 
	pr_customership.addr_text , 
	pr_customership.addr2_text , 
	pr_customership.city_text , 
	pr_customership.state_code , 
	pr_customership.post_code , 
	pr_contractdetl.user1_text , 
	pr_contractdetl.user2_text , 
	pr_contractdetl.desc_text , 
	pr_contractdetl.bill_qty , 
	pr_contractdetl.bill_price , 
	pr_contractdetl.revenue_acct_code 

	CALL eventsuspend() 
	#LET msgresp = kandoomsg("A",7001,"")
	# Press any key TO continue

	CLOSE WINDOW wja05 

END FUNCTION 

