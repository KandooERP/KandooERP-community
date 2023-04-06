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

	Source code beautified by beautify.pl on 2020-01-02 19:48:10	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/J7_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J71_GLOBALS.4gl"


# Purpose - Globals FOR J71 AND J74
#           DISPLAY resource FUNCTION TO accept AND validate new AND
#           edited resource columns



FUNCTION read_resource() 
	DEFINE 
	return_code SMALLINT, 
	pr_tax RECORD LIKE tax.*, 
	pr_allocation_ind LIKE jmresource.allocation_ind, 
	pr_response_text LIKE kandooword.response_text 


	SELECT response_text 
	INTO pr_response_text 
	FROM kandooword 
	WHERE language_code = glob_rec_kandoouser.language_code 
	AND reference_text = "jmresource.allocation_ind" 
	AND reference_code = pr_jmresource.allocation_ind 
	IF status = notfound THEN 
		LET pr_response_text = NULL 
	END IF 
	IF pr_jmresource.total_tax_flag IS NULL THEN 
		LET pr_jmresource.total_tax_flag = "Y" 
	END IF 
	DISPLAY pr_jmresource.acct_code, 
	pr_jmresource.unit_code, 
	pr_jmresource.unit_cost_amt, 
	pr_jmresource.unit_bill_amt, 
	pr_jmresource.cost_ind, 
	pr_jmresource.bill_ind , 
	pr_jmresource.total_tax_flag, 
	pr_jmresource.tax_code, 
	pr_jmresource.tax_amt, 
	pr_jmresource.allocation_ind, 
	pr_response_text, 
	pr_jmresource.allocation_flag 
	TO acct_code, 
	unit_code, 
	unit_cost_amt, 
	unit_bill_amt, 
	cost_ind, 
	bill_ind, 
	total_tax_flag, 
	tax_code, 
	tax_amt, 
	allocation_ind, 
	alloc_ind_text, 
	allocation_flag 

	CALL build_mask(glob_rec_kandoouser.cmpy_code, 
	pr_jmresource.exp_acct_code, 
	glob_rec_kandoouser.acct_mask_code) 
	RETURNING pr_jmresource.exp_acct_code 
	CALL build_mask(glob_rec_kandoouser.cmpy_code, 
	pr_jmresource.acct_code, 
	glob_rec_kandoouser.acct_mask_code) 
	RETURNING pr_jmresource.acct_code 
	INPUT pr_jmresource.acct_code, 
	pr_jmresource.exp_acct_code, 
	pr_jmresource.unit_code, 
	pr_jmresource.unit_cost_amt, 
	pr_jmresource.cost_ind, 
	pr_jmresource.unit_bill_amt, 
	pr_jmresource.bill_ind, 
	pr_jmresource.total_tax_flag, 
	pr_jmresource.tax_code, 
	pr_jmresource.tax_amt, 
	pr_jmresource.allocation_ind, 
	pr_jmresource.allocation_flag 
	WITHOUT DEFAULTS FROM 
	acct_code, 
	exp_acct_code, 
	unit_code, 
	unit_cost_amt, 
	cost_ind, 
	unit_bill_amt, 
	bill_ind, 
	total_tax_flag, 
	tax_code, 
	tax_amt, 
	allocation_ind, 
	allocation_flag 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J71a","input-pr_jmresource-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (unit_code) 
					LET pr_jmresource.unit_code = show_unit(glob_rec_kandoouser.cmpy_code) 
					DISPLAY pr_jmresource.unit_code 
					TO jmresource.unit_code 

				WHEN infield (tax_code) 
					LET pr_jmresource.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_jmresource.tax_code 

					SELECT tax_per INTO pr_tax.tax_per FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = pr_jmresource.tax_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("A",9130,"") 
						#ERROR " Invalid tax code"
						NEXT FIELD tax_code 
					ELSE 
						DISPLAY pr_tax.tax_per TO tax.tax_per 

					END IF 
					NEXT FIELD tax_code 
				WHEN infield(allocation_ind) 
					LET pr_allocation_ind = show_kandooword("jmresource.allocation_ind") 
					IF pr_allocation_ind IS NOT NULL THEN 
						LET pr_jmresource.allocation_ind = pr_allocation_ind 
					END IF 
					DISPLAY pr_jmresource.allocation_ind 
					TO allocation_ind 

					NEXT FIELD allocation_ind 
			END CASE 
			
		BEFORE FIELD acct_code 
			CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			"J71", 
			glob_rec_kandoouser.acct_mask_code, 
			pr_jmresource.acct_code, 
			2, 
			"Resource Account") 
			RETURNING pr_jmresource.acct_code, 
			pr_coa.desc_text, 
			return_code 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			DISPLAY pr_coa.desc_text, 
			pr_jmresource.acct_code 
			TO coa.desc_text, 
			acct_code 

			NEXT FIELD exp_acct_code 
		BEFORE FIELD exp_acct_code 
			CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			"J71", 
			glob_rec_kandoouser.acct_mask_code, 
			pr_jmresource.exp_acct_code, 
			2, 
			"Resource Exp Acct") 
			RETURNING pr_jmresource.exp_acct_code, 
			pr_coa.desc_text, 
			return_code 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			DISPLAY pr_coa.desc_text, 
			pr_jmresource.exp_acct_code 
			TO exp_desc_text, 
			exp_acct_code 

			NEXT FIELD unit_code 
		AFTER FIELD unit_code 
			IF pr_jmresource.unit_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD unit_code 
			END IF 
			IF pr_jmresource.unit_code IS NOT NULL THEN 
				SELECT * INTO pr_actiunit.* FROM actiunit 
				WHERE actiunit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND actiunit.unit_code = pr_jmresource.unit_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9484,"") 
					#ERROR "No such Unit Code - Try window FOR help."
					NEXT FIELD unit_code 
				ELSE 
					DISPLAY pr_actiunit.desc_text 
					TO actiunit.desc_text 
				END IF 
			END IF 
		AFTER FIELD unit_cost_amt 
			IF pr_jmresource.unit_cost_amt IS NULL THEN 
				LET msgresp = kandoomsg("J",9468,"") 
				#ERROR "Unit Cost Amount must be entered"
				NEXT FIELD unit_cost_amt 
			END IF 
			IF get_kandoooption_feature_state("JM","NC") = "N" THEN 
				IF pr_jmresource.unit_cost_amt < 0 THEN 
					LET msgresp = kandoomsg("U",9907,0) 
					#9907 Value amount must be greater than 0
					NEXT FIELD unit_cost_amt 
				END IF 
			END IF 
		AFTER FIELD cost_ind 
			IF pr_jmresource.cost_ind IS NULL THEN 
				LET msgresp = kandoomsg("J",9467,0) 
				#ERROR " Costing Mode must be entered"
				NEXT FIELD cost_ind 
			ELSE 
				IF pr_jmresource.cost_ind != "1" 
				AND pr_jmresource.cost_ind != "2" THEN 
					LET msgresp = kandoomsg("J",9466,0) 
					#ERROR " Costing Mode Invalid"
					NEXT FIELD cost_ind 
				END IF 
			END IF 
		AFTER FIELD unit_bill_amt 
			IF pr_jmresource.unit_bill_amt IS NULL THEN 
				LET msgresp = kandoomsg("J",9465,0) 
				#ERROR "Unit Bill Amount must be entered"
				NEXT FIELD unit_bill_amt 
			END IF 
			IF get_kandoooption_feature_state("JM","NC") = "N" THEN 
				IF pr_jmresource.unit_bill_amt < 0 THEN 
					LET msgresp = kandoomsg("U",9907,0) 
					#9907 Value amount must be greater than 0
					NEXT FIELD unit_bill_amt 
				END IF 
			END IF 
		AFTER FIELD bill_ind 
			IF pr_jmresource.bill_ind IS NULL THEN 
				LET msgresp = kandoomsg("J",9464,0) 
				#ERROR " Billing Mode must be entered"
				NEXT FIELD bill_ind 
			ELSE 
				IF pr_jmresource.bill_ind != "1" 
				AND pr_jmresource.bill_ind != "2" THEN 
					#ERROR " Billing Mode Invalid"
					LET msgresp = kandoomsg("J",9466,0) 
					NEXT FIELD bill_ind 
				END IF 
			END IF 
		AFTER FIELD total_tax_flag 
			IF pr_jmresource.total_tax_flag != "Y" AND 
			pr_jmresource.total_tax_flag != "N" THEN 
				#ERROR "Resource total tax flag must be either (Y) OR (N)"
				LET msgresp = kandoomsg("J",9463,0) 
				NEXT FIELD total_tax_flag 
			END IF 
			IF pr_jmresource.total_tax_flag IS NULL THEN 
				LET msgresp = kandoomsg("J",9463,0) 
				#ERROR "Resource total tax flag must be either (Y) OR (N)"
				NEXT FIELD total_tax_flag 
			END IF 
		AFTER FIELD tax_code 
			IF pr_jmresource.tax_code IS NOT NULL 
			AND pr_jmresource.tax_code != " " THEN 
				SELECT tax_per 
				INTO pr_tax.tax_per 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = pr_jmresource.tax_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9462,0) 
					#error" Invalid tax code - Try Window"
					NEXT FIELD tax_code 
				ELSE 
					DISPLAY BY NAME pr_tax.tax_per 

				END IF 
			END IF 
		AFTER FIELD allocation_ind 
			IF pr_jmresource.allocation_ind IS NULL THEN 
				LET msgresp = kandoomsg("J",9461,0) 
				#ERROR " Allocation Indicator must be entered"
				NEXT FIELD allocation_ind 
			ELSE 
				SELECT response_text 
				INTO pr_response_text 
				FROM kandooword 
				WHERE language_code = glob_rec_kandoouser.language_code 
				AND reference_text = "jmresource.allocation_ind" 
				AND reference_code = pr_jmresource.allocation_ind 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9460,0) 
					NEXT FIELD allocation_ind 
				ELSE 
					DISPLAY pr_response_text 
					TO alloc_ind_text 

				END IF 
			END IF 

		AFTER FIELD allocation_flag 
			IF pr_jmresource.allocation_flag IS NULL THEN 
				LET msgresp = kandoomsg("J",9459,0) 
				#ERROR " Allocation Mode must be entered"
				NEXT FIELD allocation_flag 
			ELSE 
				IF pr_jmresource.allocation_flag = "1" OR 
				pr_jmresource.allocation_flag = "2" THEN 
				ELSE 
					#ERROR " Allocation Mode Invalid"
					LET msgresp = kandoomsg("J",9466,0) 
					NEXT FIELD allocation_flag 
				END IF 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_jmresource.unit_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD unit_code 
				END IF 
				IF pr_jmresource.unit_cost_amt IS NULL THEN 
					LET msgresp = kandoomsg("J",9468,"") 
					#ERROR "Unit Cost Amount must be entered"
					NEXT FIELD unit_cost_amt 
				END IF 
				IF pr_jmresource.cost_ind IS NULL THEN 
					LET msgresp = kandoomsg("J",9466,0) 
					#ERROR " Costing Mode must be entered"
					NEXT FIELD cost_ind 
				END IF 
				IF pr_jmresource.unit_bill_amt IS NULL THEN 
					LET msgresp = kandoomsg("J",9465,0) 
					#ERROR "Unit Bill Amount must be entered"
					NEXT FIELD unit_bill_amt 
				END IF 
				IF pr_jmresource.bill_ind IS NULL THEN 
					#ERROR " Billing Mode must be entered"
					LET msgresp = kandoomsg("J",9464,0) 
					NEXT FIELD bill_ind 
				END IF 
				IF pr_jmresource.total_tax_flag IS NULL THEN 
					LET msgresp = kandoomsg("J",9463,0) 
					#ERROR "Resource total tax flag must be either (Y) OR (N)"
					NEXT FIELD total_tax_flag 
				END IF 
				IF pr_jmresource.allocation_ind IS NULL THEN 
					LET msgresp = kandoomsg("J",9461,0) 
					#ERROR " Allocation Indicator must be entered"
					NEXT FIELD allocation_ind 
				END IF 
				IF pr_jmresource.allocation_flag IS NULL THEN 
					LET msgresp = kandoomsg("J",9466,0) 
					#ERROR " Allocation Mode must be entered"
					NEXT FIELD allocation_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 


FUNCTION disp_resource() 
	DEFINE 
	pr_c1_desc_text, 
	pr_c2_desc_text CHAR(40) 

	IF pr_jmresource.acct_code IS NOT NULL THEN 
		SELECT c1.desc_text 
		INTO pr_c1_desc_text 
		FROM coa c1 
		WHERE c1.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND c1.acct_code = pr_jmresource.acct_code 
		SELECT c2.desc_text 
		INTO pr_c2_desc_text 
		FROM coa c2 
		WHERE c2.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND c2.cmpy_code = pr_jmresource.cmpy_code 
		AND c2.acct_code = pr_jmresource.exp_acct_code 
	END IF 

	IF pr_jmresource.total_tax_flag IS NULL THEN 
		LET pr_jmresource.total_tax_flag = "Y" 
	END IF 

	DISPLAY 
	pr_jmresource.res_code , 
	pr_jmresource.desc_text, 
	pr_jmresource.acct_code, 
	pr_c1_desc_text, 
	pr_jmresource.exp_acct_code, 
	pr_c2_desc_text, 
	pr_jmresource.unit_code , 
	pr_jmresource.unit_cost_amt, 
	pr_jmresource.unit_bill_amt, 
	pr_jmresource.cost_ind, 
	pr_jmresource.bill_ind, 

	pr_jmresource.total_tax_flag, 
	pr_jmresource.tax_code, 
	pr_jmresource.tax_amt, 

	pr_jmresource.allocation_ind, 
	pr_jmresource.allocation_flag 

	TO 
	jmresource.res_code , 
	jmresource.desc_text, 
	jmresource.acct_code, 
	coa.desc_text, 
	jmresource.exp_acct_code, 
	formonly.exp_desc_text, 
	jmresource.unit_code , 
	jmresource.unit_cost_amt, 
	jmresource.unit_bill_amt, 
	jmresource.cost_ind, 
	jmresource.bill_ind, 

	jmresource.total_tax_flag, 
	jmresource.tax_code, 
	jmresource.tax_amt, 

	jmresource.allocation_ind, 
	jmresource.allocation_flag 


END FUNCTION 
