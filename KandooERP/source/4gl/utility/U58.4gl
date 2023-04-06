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

	Source code beautified by beautify.pl on 2020-01-03 18:54:46	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../common/loadfunc.4gl" 
GLOBALS "../in/ISR_GLOBALS.4gl" 


###################################################################
# MAIN
#
#
###################################################################
MAIN 

	CALL setModuleId("U58") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	CREATE temp TABLE t_rates (post_code CHAR(10), 
	suburb_text CHAR(50), 
	state_code CHAR(6), 
	rubbish1 CHAR(60), 
	rubbish2 CHAR(60), 
	rubbish3 CHAR(60), 
	rubbish4 CHAR(60))with no LOG 
	LET pr_window_name = " Suburb Information" 
	LET pr_report_name = "Suburb Load Update Error Report" 
	LET pr_menu_path = "U58" 
	CALL menu_details() 
END MAIN 


FUNCTION validate_file() 
	DEFINE 
	pr_quaderr RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD, 
	pr_suburb RECORD 
		post_code CHAR(10), 
		suburb_text CHAR(50), 
		state_code CHAR(6), 
		rubbish1 CHAR(60), 
		rubbish2 CHAR(60), 
		rubbish3 CHAR(60), 
		rubbish4 CHAR(60) 
	END RECORD, 
	pr_suburb2 RECORD LIKE suburb.*, 
	idx SMALLINT, 
	pr_bank_acct_code CHAR(20), 
	query_text CHAR(100) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET idx = 0 
	LET pr_inserted_rows = 0 
	LET pr_err_cnt = 0 
	INITIALIZE pr_quaderr.* TO NULL 
	LET query_text = "SELECT * FROM t_rates" 
	PREPARE s_rates FROM query_text 
	DECLARE c_rates CURSOR FOR s_rates 
	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database; Please Wait.
	OPEN WINDOW w1 with FORM "U999" 
	CALL windecoration_u("U999") 

	DISPLAY "Inserting Suburb..." TO lblabel1 

	FOREACH c_rates INTO pr_suburb.* 
		LET idx = idx + 1 
		IF pr_suburb.post_code[1] != "2" 
		AND pr_suburb.post_code[1] != "3" 
		AND pr_suburb.post_code[1] != "4" 
		AND pr_suburb.post_code[1] != "5" 
		AND pr_suburb.post_code[1] != "6" 
		AND pr_suburb.post_code[1] != "7" 
		AND pr_suburb.post_code[1] != "0" THEN 
			CONTINUE FOREACH 
		END IF 
		IF pr_suburb.suburb_text IS NULL THEN 
			LET pr_quaderr.error_text = "Suburb text must be entered" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		IF pr_suburb.state_code IS NULL THEN 
			LET pr_quaderr.error_text = "State code must be entered" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		IF pr_suburb.post_code IS NULL THEN 
			LET pr_quaderr.error_text = "Post code must be entered" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM suburb 
		WHERE post_code = pr_suburb.post_code 
		AND suburb_text = pr_suburb.suburb_text 
		AND state_code = pr_suburb.state_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			LET pr_quaderr.error_text = "Suburb ", 
			pr_suburb.suburb_text clipped,"/", 
			pr_suburb.state_code clipped,"/", 
			pr_suburb.post_code clipped, 
			" already exists - unable TO INSERT" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		DISPLAY pr_suburb.suburb_text TO lblabel2b 
		DISPLAY pr_suburb.post_code TO lblabel3b 
		INITIALIZE pr_suburb2.* TO NULL 
		LET pr_suburb2.suburb_code = 0 
		LET pr_suburb2.suburb_text = upshift(pr_suburb.suburb_text) 
		LET pr_suburb2.state_code = upshift(pr_suburb.state_code) 
		LET pr_suburb2.post_code = pr_suburb.post_code 
		LET pr_suburb2.cmpy_code = glob_rec_kandoouser.cmpy_code 
		INSERT INTO suburb VALUES (pr_suburb2.*) 
		IF status < 0 THEN 
			LET pr_quaderr.error_text = pr_suburb.suburb_text clipped,"/", 
			pr_suburb.state_code clipped,"/", 
			pr_suburb.post_code clipped, 
			" - ", "Failed INSERT error" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_inserted_rows = pr_inserted_rows + 1 
	END FOREACH 
	CLOSE WINDOW w1 
END FUNCTION 


