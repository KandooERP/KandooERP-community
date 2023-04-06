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

	Source code beautified by beautify.pl on 2020-01-02 19:48:03	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J25 Inquire on Job Adjustments
{
IF an adjustment IS TO be done, a reversing jobledger entry IS written
The activity amt AND qty IS reduced by the value of the adjustment
before a ledger row IS written FOR the target activity which has
its act_amt AND qty increased.
This program re-constructs the Adjustment SCREEN except FOR the
activity actual cost AND quantity fields. These are left out because
the VALUES there today may well be different FROM the VALUES AT the time
that the adjustment was done, so we leave them blank in this display.
}

GLOBALS 
	DEFINE 
	pr_jmparms RECORD LIKE jmparms.* 
END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("J25") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		#7002 " Must SET up JM Parameters first in JZP"
		EXIT program 
	END IF 
	OPEN WINDOW j123 with FORM "J123" -- alch kd-747 
	CALL winDecoration_j("J123") -- alch kd-747 
	WHILE get_adj() 
		MENU"" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","J25","menu-blank-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			command"Continue" "Examine another Adjustment" 
				EXIT MENU 
			command"Exit" "EXIT PROGRAM" 
				EXIT program 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
	END WHILE 
	CLOSE WINDOW j123 
END MAIN 


FUNCTION get_adj() 
	DEFINE 
	pr1_jobledger RECORD LIKE jobledger.*, 
	pr2_jobledger RECORD LIKE jobledger.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	ans CHAR(1) 

	IF num_args() = 1 THEN 
		LET pr_jobledger.trans_source_num = arg_val(1) 
	ELSE 
		OPEN WINDOW j125 with FORM "J125" -- alch kd-747 
		CALL winDecoration_j("J125") -- alch kd-747 
		DISPLAY BY NAME pr_jobledger.trans_source_num 
		INPUT BY NAME pr_jobledger.trans_source_num 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J25","input-pr_jobledger-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END INPUT 
		CLOSE WINDOW j125 
		IF int_flag OR quit_flag THEN 
			RETURN false 
		END IF 
	END IF 
	SELECT jobledger.* 
	INTO pr1_jobledger.* 
	FROM jobledger 
	WHERE jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jobledger.trans_source_num = pr_jobledger.trans_source_num 
	AND jobledger.trans_type_ind = "AD" 
	AND (jobledger.trans_amt < 0 
	OR jobledger.trans_qty < 0 
	OR jobledger.charge_amt < 0 ) 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7012,"") 
		#7012 "No records FOR this Adjustment "
		RETURN false 
	END IF 
	DISPLAY pr1_jobledger.job_code, 
	pr1_jobledger.var_code, 
	pr1_jobledger.activity_code 
	TO job1_code, 
	var1_code, 
	activity1_code 

	SELECT jobledger.* 
	INTO pr2_jobledger.* 
	FROM jobledger 
	WHERE jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jobledger.trans_source_num = pr_jobledger.trans_source_num 
	AND jobledger.trans_type_ind = "AD" 
	AND (jobledger.trans_amt > 0 
	OR jobledger.trans_qty > 0 
	OR jobledger.charge_amt > 0 ) 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7012,"") 
		#7012 "No records FOR this Adjustment "
		RETURN false 
	END IF 
	DISPLAY pr2_jobledger.job_code, 
	pr2_jobledger.var_code, 
	pr2_jobledger.activity_code, 
	pr2_jobledger.trans_date, 
	pr2_jobledger.year_num, 
	pr2_jobledger.period_num, 
	pr2_jobledger.trans_amt, 
	pr2_jobledger.trans_qty, 
	pr2_jobledger.charge_amt, 
	pr2_jobledger.desc_text 
	TO job2_code, 
	var2_code, 
	activity2_code, 
	trans_date, 
	year_num, 
	period_num, 
	adj_cost_amt, 
	adj_cost_qty, 
	adj_charge_amt, 
	desc_text 

	RETURN true 
END FUNCTION 
