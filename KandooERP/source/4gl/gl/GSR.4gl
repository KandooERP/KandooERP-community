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

	Source code beautified by beautify.pl on 2020-01-03 14:28:53	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GSR  resets the postrun table IF required
# will eventually require FROM AND TO postruns

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE modu_rec_batchhead RECORD LIKE batchhead.*
	DEFINE modu_rec_postrun RECORD LIKE postrun.*
	DEFINE modu_msg_ans CHAR(1)
	DEFINE modu_first_time CHAR(1)
	DEFINE modu_run_total DECIMAL(15,2)
	DEFINE modu_batch_post_amt DECIMAL(15,2)	
	DEFINE modu_start_total DECIMAL(15,2)
	DEFINE modu_end_total DECIMAL(15,2)	
	DEFINE modu_tot_credit DECIMAL(15,2)
	DEFINE modu_ofs_credit DECIMAL(15,2)	
	DEFINE modu_thisdate DATE
	DEFINE modu_where_part CHAR(800)
	DEFINE modu_query_text CHAR(800)
	DEFINE modu_post_num INTEGER 
	DEFINE modu_counter INTEGER 	
	DEFINE modu_post_date DATE 
END GLOBALS
 
############################################################
# MODULE Scope Variables
############################################################

############################################################
# MAIN
#
#
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("GSR") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	LET int_flag = 0 
	LET quit_flag = 0 
	CALL do_it() 

	CLOSE WINDOW w01 

END MAIN 


############################################################
# FUNCTION do_it() 
#
#
############################################################
FUNCTION do_it() 

	OPEN WINDOW w01 with FORM "U999" attributes(BORDER) 
	CALL windecoration_u("U999") 

	#"    Re-setting all Post Run statistics " AT 2,2
	LET modu_msg_ans = kandoomsg("G",3509,"") 

	IF upshift(modu_msg_ans) != "Y" THEN 
		RETURN 
	END IF 


	LET modu_query_text = "SELECT post_run_num, ", 
	" jour_date, ", 
	" sum(debit_amt) ", 
	" FROM batchhead ", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" post_flag = \"Y\" ", 
	" group by post_run_num, jour_date ", 
	" ORDER BY post_run_num, jour_date " 

	LET modu_run_total = 0 
	LET modu_start_total = 0 
	LET modu_end_total = 0 

	# get the info FROM the batchheads

	PREPARE getpost FROM modu_query_text 
	DECLARE post_curs CURSOR FOR getpost 

	FOREACH post_curs INTO modu_post_num, modu_post_date, modu_batch_post_amt 
		# now we have one IS there a postrun row
		DISPLAY "Processing Run Number....", modu_post_num at 3,2 

		LET modu_end_total = modu_end_total + modu_batch_post_amt 
		SELECT * 
		INTO modu_rec_postrun.* 
		FROM postrun 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND post_run_num = modu_post_num 
		IF status = NOTFOUND 
		THEN 
			# NOT there so we will INSERT it
			LET modu_rec_postrun.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET modu_rec_postrun.post_run_num = modu_post_num 
			LET modu_rec_postrun.post_date = modu_post_date 
			LET modu_rec_postrun.post_by_text = glob_rec_kandoouser.sign_on_code 
			LET modu_rec_postrun.start_total_amt = modu_start_total 
			LET modu_rec_postrun.post_amt = modu_batch_post_amt 
			LET modu_rec_postrun.end_total_amt = modu_end_total 
			INSERT INTO postrun VALUES (modu_rec_postrun.*) 
		ELSE 
			LET modu_rec_postrun.start_total_amt = modu_start_total 
			LET modu_rec_postrun.post_amt = modu_batch_post_amt 
			LET modu_rec_postrun.end_total_amt = modu_end_total 
			UPDATE postrun SET postrun.* = modu_rec_postrun.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND post_run_num = modu_post_num 
		END IF 

		LET modu_start_total = modu_start_total + modu_batch_post_amt 
	END FOREACH 

END FUNCTION