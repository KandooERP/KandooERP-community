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

	Source code beautified by beautify.pl on 2020-01-02 19:48:21	$Id: $
}




# Purpose - JM credit note edit - cull FROM A41d.4gl

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC2_GLOBALS.4gl" 


FUNCTION get_acct() 
	DEFINE 
	pr_coa RECORD LIKE coa.*, 
	pr_tax RECORD LIKE tax.* 

	LET pr_coa.acct_code = pr_creditdetl.line_acct_code 
	IF pr_credithead.tax_code IS NOT NULL THEN 
		OPEN WINDOW wa104 with FORM "A104" -- alch kd-747 
		CALL winDecoration_a("A104") -- alch kd-747 
		DISPLAY BY NAME pr_coa.acct_code
		 
		INPUT BY NAME pr_coa.acct_code WITHOUT DEFAULTS 

			BEFORE INPUT
				CALL publish_toolbar("kandoo","JC2d","input-pr_coa-1") -- alch kd-506 
				DISPLAY db_coa_get_desc_text(UI_OFF,pr_coa.acct_code) TO coa.desc_text
				
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) infield(acct_code) 
						LET pr_coa.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_coa.acct_code 

						NEXT FIELD acct_code 

			ON CHANGE acct_code
				DISPLAY db_coa_get_desc_text(UI_OFF,pr_coa.acct_code) TO coa.desc_text			

			AFTER FIELD acct_code 
				IF pr_coa.acct_code IS NULL THEN 
					LET msgresp = kandoomsg("J",9475,"") 
					NEXT FIELD acct_code 
				END IF 

			AFTER INPUT 
				IF int_flag 
				OR quit_flag THEN 
					LET int_flag = 0 
					LET quit_flag = 0 
					LET del_yes = "Y" 
					EXIT INPUT 
				END IF 
				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, 
				"JC2", 
				pr_coa.acct_code, 
				pr_credithead.year_num , pr_credithead.period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 
					####ERROR " Account Number IS required "
					NEXT FIELD acct_code 
				END IF 
				LET del_yes = "N" 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		CLOSE WINDOW wa104 
		LET pr_creditdetl.line_acct_code = pr_coa.acct_code 
		RETURN del_yes 
	ELSE 
		OPEN WINDOW wa208 with FORM "A208" -- alch kd-747 
		CALL winDecoration_a("A208") -- alch kd-747 
		DISPLAY BY NAME pr_coa.acct_code, 
		pr_creditdetl.tax_code 
		INPUT BY NAME pr_coa.acct_code, 
		pr_creditdetl.tax_code WITHOUT DEFAULTS 
		
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JC2d","input-pr_coa-2") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(acct_code) 
						LET pr_coa.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_coa.acct_code 

						NEXT FIELD acct_code 
					WHEN infield(tax_code) 
						LET pr_creditdetl.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_creditdetl.tax_code 

						NEXT FIELD tax_code 
				END CASE 
			AFTER FIELD acct_code 
				IF pr_coa.acct_code IS NULL THEN 
					LET msgresp = kandoomsg("J",9475,"") 
					#ERROR " Account Number IS required, try window"
					NEXT FIELD acct_code 
				END IF 
				# account code verification
				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, 
				"JC2", 
				pr_coa.acct_code, 
				pr_credithead.year_num , pr_credithead.period_num) 
				RETURNING pr_coa.* 
			AFTER FIELD tax_code 
				IF pr_creditdetl.tax_code IS NULL 
				AND pr_arparms.inven_tax_flag = "3" THEN 
					LET msgresp = kandoomsg("J",9474,"") 
					#ERROR " Tax Code IS required, try window"
					NEXT FIELD tax_code 
				END IF 
			AFTER INPUT 
				SELECT * INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_coa.acct_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9475,"") 
					#ERROR " Account NOT found"
					NEXT FIELD acct_code 
				END IF 
				IF pr_creditdetl.tax_code IS NOT NULL THEN 
					SELECT * INTO pr_tax.* 
					FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = pr_creditdetl.tax_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("J",9474,"") 
						#ERROR " Tax code NOT found"
						NEXT FIELD tax_code 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 

		CLOSE WINDOW wa208 
	END IF 

	LET pr_creditdetl.line_acct_code = pr_coa.acct_code 


	LET del_yes = "N" 

	RETURN del_yes 
END FUNCTION 
