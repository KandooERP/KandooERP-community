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

	Source code beautified by beautify.pl on 2020-01-03 14:28:30	$Id: $
}



#Program G25 allows inquiry facilities on batches

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_batchhead RECORD LIKE batchhead.* 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("G25") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW g109 with FORM "G109" 
	CALL windecoration_g("G109") 

	CALL batch_inquiry() 
	CLOSE WINDOW g109 
END MAIN 


############################################################
# FUNCTION select_batch()
#
#
############################################################
FUNCTION select_batch() 
	DEFINE where_part CHAR(980) 
	DEFINE query_text CHAR(980) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp=kandoomsg("G",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME where_part ON batchhead.jour_code, 
	batchhead.jour_num, 
	batchhead.year_num, 
	batchhead.period_num, 
	batchhead.post_flag, 
	batchhead.currency_code, 
	batchhead.rate_type_ind, 
	batchhead.conv_qty, 
	batchhead.control_qty, 
	batchhead.control_amt, 
	batchhead.stats_qty, 
	batchhead.for_debit_amt, 
	batchhead.for_credit_amt, 
	batchhead.com1_text, 
	batchhead.com2_text, 
	batchhead.entry_code, 
	batchhead.jour_date 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","G25","construct-batchhead") 

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

	LET query_text = "SELECT * FROM batchhead ", 
	"WHERE batchhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ", where_part clipped, " ", 
	"ORDER BY jour_num" 

	PREPARE statement_1 FROM query_text 
	DECLARE batchhead_set SCROLL CURSOR FOR statement_1 

	OPEN batchhead_set 
	FETCH FIRST batchhead_set INTO glob_rec_batchhead.* 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9043,"") 
		#9043 No batches selected
		RETURN false 
	ELSE 
		CALL disp_journal(glob_rec_kandoouser.cmpy_code,glob_rec_batchhead.jour_num) 
		RETURN true 
	END IF 
END FUNCTION 

############################################################
# FUNCTION batch_inquiry()
#
#
############################################################
FUNCTION batch_inquiry() 
	DEFINE l_msgresp LIKE language.yes_flag 

	MENU " Journal Batch" 
		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "Detail" 
			HIDE option "First" 
			HIDE option "Last" 
			CALL publish_toolbar("kandoo","G25","menu-journal-batch") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Query" 
			#COMMAND "Query" " Enter selection criteria FOR Journal Batches"
			IF select_batch() THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
				NEXT option "Next" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 

		ON ACTION "Next" 
			#COMMAND KEY ("N",f21) "Next" "DISPLAY next selected batch"
			FETCH NEXT batchhead_set INTO glob_rec_batchhead.* 
			IF status <> NOTFOUND THEN 
				CALL disp_journal(glob_rec_kandoouser.cmpy_code,glob_rec_batchhead.jour_num) 
			ELSE 
				LET l_msgresp = kandoomsg("G",9157,"") 
				#9157 You have reached the END of the entries selected"
				NEXT option "Previous" 
			END IF 

		ON ACTION "Previous" 
			#COMMAND KEY ("P",f19) "Previous" "DISPLAY previously selected batch"
			FETCH previous batchhead_set INTO glob_rec_batchhead.* 
			IF status <> NOTFOUND THEN 
				CALL disp_journal(glob_rec_kandoouser.cmpy_code,glob_rec_batchhead.jour_num) 
			ELSE 
				LET l_msgresp = kandoomsg("G",9156,"") 
				#9156 You have reached the start of the entries selected"
				NEXT option "Next" 
			END IF 

		ON ACTION "Detail" 
			#COMMAND KEY ("D",f20) "Detail" "View batch details"
			CALL jo_det_scan(glob_rec_kandoouser.cmpy_code, glob_rec_batchhead.jour_num) 

		ON ACTION "First" 
			#COMMAND KEY ("F",f18) "First" "DISPLAY first batch in the selected list"
			FETCH FIRST batchhead_set INTO glob_rec_batchhead.* 
			CALL disp_journal(glob_rec_kandoouser.cmpy_code,glob_rec_batchhead.jour_num) 
			NEXT option "Next" 

		ON ACTION "Last" 
			#COMMAND KEY ("L",f22) "Last" "DISPLAY last batch in the selected list"
			FETCH LAST batchhead_set INTO glob_rec_batchhead.* 
			CALL disp_journal(glob_rec_kandoouser.cmpy_code,glob_rec_batchhead.jour_num) 
			NEXT option "Previous" 

		ON ACTION "Exit" 
			#COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the Menu"
			EXIT MENU 

			#		COMMAND KEY (control-w)
			#			CALL kandoohelp("")
	END MENU 
END FUNCTION 
