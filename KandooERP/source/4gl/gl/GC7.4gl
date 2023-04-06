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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GC7_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_rec_cbaudit RECORD LIKE cbaudit.* 
	DEFINE glob_arr_rec_audit DYNAMIC ARRAY OF RECORD #array[500] 
		tran_date LIKE cbaudit.tran_date, 
		tran_type_ind LIKE cbaudit.tran_type_ind, 
		source_num LIKE cbaudit.source_num, 
		tran_text LIKE cbaudit.tran_text, 
		tran_amt LIKE cbaudit.tran_amt, 
		entry_code LIKE cbaudit.entry_code 
	END RECORD 
	DEFINE glob_start_date DATE 
	DEFINE glob_end_date DATE 
	DEFINE glob_idx SMALLINT  
	DEFINE glob_ans char(1) 
END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################


################################################################
# MAIN
#
# GC7 allows the user TO scan the daily Cashbook activity AND TO
# NOTE: This is a DISPLAY ARRAY (SCREEN only) report (not report functionality is used here)
################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GC7") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	OPTIONS DELETE KEY f36 
	OPTIONS INSERT KEY f35 

	OPEN WINDOW G166 with FORM "G166" 
	CALL windecoration_g("G166") 

	CALL cashbook_audit_trail_scanner() 

	CLOSE WINDOW G166 

	--	LET glob_ans = "Y"

	--	WHILE glob_ans = "Y"
	--		CALL getlog()
	--		CLOSE WINDOW wg166
	--		LET glob_ans = "Y"
	--	END WHILE

END MAIN 


################################################################
# FUNCTION getlog()
################################################################
FUNCTION getlog_datasource() 
	DEFINE l_msgresp LIKE language.yes_flag 

	--	OPEN WINDOW wg166 with FORM "G166"
	--	CALL windecoration_g("G166")
	--
	--	LABEL try_another:

	LET glob_start_date = today 
	LET glob_end_date = today 


	INPUT glob_start_date, glob_end_date WITHOUT DEFAULTS FROM start_date, end_date 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GC7","inp-glob_start_date") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD end_date 
			IF glob_end_date < glob_start_date 
			THEN 
				LET l_msgresp = kandoomsg("A",9095,"") 
				NEXT FIELD end_date 
			END IF 

			--   ON KEY (control-w)
			--      CALL kandoohelp("")

	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		EXIT PROGRAM 
	END IF 

	DECLARE c_log CURSOR FOR 

	SELECT cbaudit.* 
	INTO glob_rec_cbaudit.* 
	FROM cbaudit 
	WHERE cbaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cbaudit.tran_date >= glob_start_date 
	AND cbaudit.tran_date <= glob_end_date 
	ORDER BY cbaudit.tran_date 

	LET glob_idx = 0 

	FOREACH c_log 
		LET glob_idx = glob_idx + 1 
		LET glob_arr_rec_audit[glob_idx].tran_date = glob_rec_cbaudit.tran_date 
		LET glob_arr_rec_audit[glob_idx].tran_type_ind = glob_rec_cbaudit.tran_type_ind 
		LET glob_arr_rec_audit[glob_idx].source_num = glob_rec_cbaudit.source_num 
		LET glob_arr_rec_audit[glob_idx].tran_text = glob_rec_cbaudit.tran_text 
		LET glob_arr_rec_audit[glob_idx].tran_amt = glob_rec_cbaudit.tran_amt 
		LET glob_arr_rec_audit[glob_idx].entry_code = glob_rec_cbaudit.entry_code 
	END FOREACH 


	IF glob_idx = 0 THEN 
		LET l_msgresp = kandoomsg("A",9004,"") --		GOTO try_another
	END IF 

	LET l_msgresp = kandoomsg("G",1017,"") 

	--CALL scanner()
	RETURN glob_arr_rec_audit 

END FUNCTION 


################################################################
# FUNCTION cashbook_audit_trail_scanner()
#
# The original name of this function was scanner()
################################################################
FUNCTION cashbook_audit_trail_scanner() 
	DEFINE l_msgresp LIKE language.yes_flag 


	CALL getlog_datasource() RETURNING glob_arr_rec_audit 

	--	INPUT ARRAY glob_arr_rec_audit WITHOUT DEFAULTS FROM sr_cbaudit.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY glob_arr_rec_audit TO sr_cbaudit.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","GC7","inp-arr-audit") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("DOUBLECLICK",TRUE)
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL getlog_datasource() RETURNING glob_arr_rec_audit 

		BEFORE ROW 
			LET glob_idx = arr_curr() 
			#LET scrn = scr_line()
			IF glob_idx > arr_count() THEN 
				LET l_msgresp = kandoomsg("G",9001,"") 
			END IF 

			# BEFORE FIELD tran_type_ind
			# here's WHERE we can DISPLAY the deposit/charge...}
			# LET glob_ans = "Y"

	
	END DISPLAY 

	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

END FUNCTION 
