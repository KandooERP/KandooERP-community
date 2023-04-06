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

	Source code beautified by beautify.pl on 2020-01-02 17:06:16	Source code beautified by beautify.pl on 2020-01-02 17:03:26	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 
GLOBALS "R31_GLOBALS.4gl" 


#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("R31") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW r115 with FORM "R115" 
	CALL  windecoration_r("R115") 

	IF num_args() = 1 THEN 
		IF enter_coa() THEN 
			CALL scan_commitments(where_text) 
		END IF 
	ELSE 
		WHILE enter_coa() 
			CALL scan_commitments(where_text) 
		END WHILE 
	END IF 

	CLOSE WINDOW r115 
END MAIN 


FUNCTION enter_coa() 
	DEFINE 
	pr_purchdetl RECORD LIKE purchdetl.* 

	CLEAR FORM 
	IF num_args() = 1 THEN 
		LET pr_purchdetl.acct_code = arg_val(1) 
		SELECT unique 1 FROM coa 
		WHERE acct_code = pr_purchdetl.acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			RETURN false 
		END IF 
	ELSE 
		LET msgresp=kandoomsg("U",1020,"Expense Account") 
		#U1020 Enter Expense Account Details
		INPUT BY NAME pr_purchdetl.acct_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","R31","inp-purchdetl-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (control-b) 
				LET pr_purchdetl.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
				NEXT FIELD acct_code 
			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					IF pr_purchdetl.acct_code IS NULL THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						NEXT FIELD acct_code 
					END IF 
					SELECT unique 1 FROM coa 
					WHERE acct_code = pr_purchdetl.acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("U",9105,"") 
						CONTINUE INPUT 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
	END IF 
	DISPLAY BY NAME pr_purchdetl.acct_code 

	LET where_text = "acct_code= '",pr_purchdetl.acct_code,"' " 
	RETURN true 
END FUNCTION 
