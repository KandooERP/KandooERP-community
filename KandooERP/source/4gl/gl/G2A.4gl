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

	Source code beautified by beautify.pl on 2020-01-03 14:28:31	$Id: $
}



#Program G2A allows the user TO inquire batch entries
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_jour_num LIKE batchdetl.jour_num 
	DEFINE glob_seq_num LIKE batchdetl.seq_num 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("G2A") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW wg112 with FORM "G112" 
	CALL windecoration_g("G112") 

	CALL batchdetl_query() 
	CLOSE WINDOW wg112 
END MAIN 


############################################################
# FUNCTION select_details()
#
#
############################################################
FUNCTION select_details() 
	DEFINE l_where_part CHAR(1500) 
	DEFINE l_query_text CHAR(1550) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT l_where_part ON batchhead.jour_code, 
	batchhead.jour_num, 
	batchhead.control_qty, 
	batchhead.control_amt, 
	batchhead.currency_code, 
	batchhead.stats_qty, 
	batchhead.for_debit_amt, 
	batchhead.for_credit_amt, 
	batchhead.year_num, 
	batchhead.period_num, 
	batchhead.post_flag, 
	batchhead.entry_code, 
	batchhead.jour_date, 
	batchdetl.tran_type_ind, 
	batchdetl.tran_date, 
	batchdetl.acct_code, 
	batchdetl.desc_text, 
	batchdetl.ref_num, 
	batchdetl.ref_text, 
	batchdetl.seq_num, 
	batchdetl.currency_code, 
	batchdetl.for_debit_amt, 
	batchdetl.for_credit_amt, 
	batchdetl.stats_qty, 
	batchdetl.debit_amt, 
	batchdetl.credit_amt 
	FROM batchhead.jour_code, 
	batchhead.jour_num, 
	batchhead.control_qty, 
	batchhead.control_amt, 
	batchhead.currency_code, 
	batchhead.stats_qty, 
	batchhead.for_debit_amt, 
	batchhead.for_credit_amt, 
	batchhead.year_num, 
	batchhead.period_num, 
	batchhead.post_flag, 
	batchhead.entry_code, 
	batchhead.jour_date, 
	batchdetl.tran_type_ind, 
	batchdetl.tran_date, 
	batchdetl.acct_code, 
	batchdetl.desc_text, 
	batchdetl.ref_num, 
	batchdetl.ref_text, 
	batchdetl.seq_num, 
	batchdetl.currency_code, 
	batchdetl.for_debit_amt, 
	batchdetl.for_credit_amt, 
	batchdetl.stats_qty, 
	batchdetl.debit_amt, 
	batchdetl.credit_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","G2A","construct-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database; Please wait.

	LET l_query_text = "SELECT batchdetl.jour_num,batchdetl.seq_num ", 
	"FROM batchdetl,batchhead ", 
	"WHERE batchhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchdetl.jour_num = batchhead.jour_num ", 
	"AND batchdetl.jour_code = batchhead.jour_code ", 
	"AND ",l_where_part clipped, " ", 
	"ORDER BY batchdetl.jour_num,batchdetl.seq_num" 

	PREPARE batch_curs FROM l_query_text 
	DECLARE batchdetl_set SCROLL CURSOR FOR batch_curs 

	OPEN batchdetl_set 
	FETCH FIRST batchdetl_set INTO glob_jour_num,glob_seq_num 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9043,"") 
		#9043 No batches selected
		RETURN false 
	ELSE 
		CALL jo_detl_disp(glob_rec_kandoouser.cmpy_code, glob_jour_num, glob_seq_num) 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION batchdetl_query() 
#
#
############################################################
FUNCTION batchdetl_query() 
	DEFINE l_msgresp LIKE language.yes_flag 

	MENU " Batch Entry" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","G2A","menu-batch-entry") 


			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "First" 
			HIDE option "Last" 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Query" 
			#COMMAND "Query" " Search FOR batch entries "
			IF select_details() THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				NEXT option "Next" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
			END IF 

		ON ACTION "Next" 
			#COMMAND KEY ("N",f21) "Next" " DISPLAY next selected batch entry"
			FETCH NEXT batchdetl_set INTO glob_jour_num,glob_seq_num 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9157,"") 
				#9157 You have reached the END of the entries selected"
				NEXT option "Previous" 
			ELSE 
				CALL jo_detl_disp(glob_rec_kandoouser.cmpy_code, glob_jour_num, glob_seq_num) 
			END IF 

		ON ACTION "Previous" 
			#COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected batch entry"
			FETCH previous batchdetl_set INTO glob_jour_num,glob_seq_num 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9156,"") 
				#9156 You have reached the start of the entries selected"
				NEXT option "Next" 
			ELSE 
				CALL jo_detl_disp(glob_rec_kandoouser.cmpy_code, glob_jour_num, glob_seq_num) 
			END IF 

		ON ACTION "First" 
			#COMMAND KEY ("F",f18) "First" " DISPLAY first batch entry in the selected list"
			CALL jo_detl_disp(glob_rec_kandoouser.cmpy_code, glob_jour_num, glob_seq_num) 
			NEXT option "Next" 

		ON ACTION "Last" 
			#COMMAND KEY ("L",f22) "Last" " DISPLAY last batch entry in the selected list"
			FETCH LAST batchdetl_set INTO glob_jour_num,glob_seq_num 
			CALL jo_detl_disp(glob_rec_kandoouser.cmpy_code, glob_jour_num, glob_seq_num) 
			NEXT option "Previous" 

		ON ACTION "Exit" 
			#COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus"
			EXIT MENU 

--		COMMAND KEY (control-w) 
--			CALL kandoohelp("") 
	END MENU
	 
END FUNCTION