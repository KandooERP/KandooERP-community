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

	Source code beautified by beautify.pl on 2020-01-03 14:28:44	Source code beautified by beautify.pl on 2019-11-01 14:09:29	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GZB which prints a
# REPORT of all the accumulated CB transactions AND THEN wipes them FROM
# the system.
#
# It marks all receipts as having been banked in the table deposits.
#
# It marks all cheques in the AP system as having been reconciled with a
# dummy bank account reference.
#
# Obviously this program must NOT be run once the CB IS up AND running,
# as it will destroy the basis of the CB.


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_banking RECORD LIKE banking.* 
	DEFINE glob_rec_cheque RECORD LIKE cheque.* 
	DEFINE glob_exit_flag INTEGER 
	DEFINE glob_max_no INTEGER 
	DEFINE glob_idx INTEGER 
	#DEFINE glob_next_seq_no INTEGER
	DEFINE glob_o_seq_no INTEGER 
	DEFINE glob_i INTEGER 
	DEFINE glob_j INTEGER 
	DEFINE glob_re_do INTEGER 
	DEFINE glob_msgresp char(1) 
	DEFINE glob_ans char(1) 
	DEFINE glob_another char(1) 
	DEFINE glob_added SMALLINT 
	DEFINE glob_err_flag SMALLINT 
	DEFINE glob_cnt SMALLINT 
	DEFINE glob_clo_bal money(12,2) 
	DEFINE glob_batch_bal money(12,2) 
	DEFINE glob_err_message char(40) 
	DEFINE glob_try_again char(1) 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GZB") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	--	SELECT glparms.* INTO glob_rec_glparms.* FROM glparms
	--	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code
	--	AND glparms.key_code = "1"

	#CALL rpt_rmsreps_set_page_size(132,NULL)
	CLEAR screen 
	CALL gzb_run() 
END MAIN 



############################################################
# FUNCTION gzb_run()
#
#
############################################################
FUNCTION gzb_run() 
	OPEN WINDOW g145 with FORM "G145" 
	CALL windecoration_g("G145") 

	DISPLAY glob_rec_kandoouser.cmpy_code TO cmpy_code 
	CALL ui.interface.refresh() 
	IF glob_rec_glparms.cash_book_flag = "Y" THEN 
		IF kandoomsg("G",8005,"") != "Y" THEN 
			#8005 Cash Book already installed.  Continue ?
			EXIT PROGRAM 
		END IF 
	END IF 
	LET glob_ans = NULL 

	INPUT glob_ans FROM ans
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZB","inp-glob_ans") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END INPUT 

	IF glob_ans <> "Y" THEN 
		EXIT PROGRAM 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	LET glob_try_again = error_recover(glob_err_message, status) 
	IF glob_try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 

	BEGIN WORK 
		LOCK TABLE cheque in exclusive MODE 
		LOCK TABLE banking in exclusive MODE 
		LOCK TABLE cashreceipt in exclusive MODE 

		LET glob_msgresp = kandoomsg("U",1005,"") 
		#1005 Updating database;  Please wait.
		UPDATE cheque 
		SET rec_state_num = 0, 
		rec_line_num = 0 
		WHERE rec_state_num IS NULL 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		UPDATE cashreceipt 
		SET banked_flag = "Y", 
		banked_date = today 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		DELETE FROM banking 
		WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
	COMMIT WORK 

END FUNCTION 
