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



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G23  allows the user TO create Recurring Journal Batches

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_batchhead RECORD LIKE batchhead.* 
DEFINE modu_rec_batchdetl RECORD LIKE batchdetl.* 
DEFINE modu_rec_period RECORD LIKE period.* 
DEFINE modu_rec_glparms RECORD LIKE glparms.* 
DEFINE modu_rec_journal RECORD LIKE journal.* 
DEFINE modu_arr_rec_period DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
	year_num LIKE period.year_num, 
	period_num LIKE period.period_num, 
	setup_flag CHAR(1), 
	ass_jour_num LIKE batchhead.jour_num 
END RECORD 
DEFINE modu_orig_jour_code LIKE journal.jour_code 
DEFINE modu_orig_jour_num LIKE batchhead.jour_num 
--	DEFINE l_idx SMALLINT
--	DEFINE arr_size SMALLINT



############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("G23") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	SELECT * INTO modu_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",3511,"") 
		#3511 " General Ledger Parameters NOT found - Refer Menu GZP  "
		SLEEP 4 
		EXIT PROGRAM 
	END IF 

	IF modu_rec_glparms.rj_code IS NULL THEN 
		LET l_msgresp = kandoomsg("G",5002,"") 
		EXIT PROGRAM 
	END IF 
	SELECT * INTO modu_rec_journal.* FROM journal 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = modu_rec_glparms.rj_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9057,"") 
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW g156 with FORM "G156" 
	CALL windecoration_g("G156") 

	WHILE get_batch() 
		IF sel_periods() THEN 

			OPEN WINDOW w1 with FORM "U999" attributes(BORDER) 
			CALL windecoration_u("U999") 

			MESSAGE "Creating Recurring Batch Number" 

			FOR l_idx = 1 TO modu_arr_rec_period.getlength() --arr_size 
				IF modu_arr_rec_period[l_idx].year_num IS NOT NULL 
				AND modu_arr_rec_period[l_idx].period_num IS NOT NULL 
				AND modu_arr_rec_period[l_idx].setup_flag = "Y" THEN 
					CALL write_batch(l_idx) 
				END IF 
			END FOR 
			CLOSE WINDOW w1 

			DISPLAY "Batch No" TO batch_prompt 
			DISPLAY ARRAY modu_arr_rec_period TO sr_period.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","G23","disp-arr-period") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END DISPLAY 

		END IF 
		LET int_flag = false 
		LET quit_flag = false 
	END WHILE 
	CLOSE WINDOW g156 
END MAIN 


############################################################
# FUNCTION get_batch()
#
#
############################################################
FUNCTION get_batch() 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("G",1041,"") 

	#1041 Enter Batch Information - ESC TO Continue"
	INPUT BY NAME modu_rec_batchhead.jour_code, modu_rec_batchhead.jour_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G23","input-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD jour_code 
			IF modu_rec_batchhead.jour_code IS NULL 
			OR (modu_rec_batchhead.jour_code != modu_rec_glparms.gj_code 
			AND modu_rec_batchhead.jour_code != modu_rec_glparms.rj_code) THEN 
				LET l_msgresp = kandoomsg("G",9058,"") 
				NEXT FIELD jour_code 
			END IF 
			DISPLAY BY NAME modu_rec_journal.desc_text 

		AFTER FIELD jour_num 
			SELECT * INTO modu_rec_batchhead.* FROM batchhead 
			WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND batchhead.jour_code = modu_rec_batchhead.jour_code 
			AND batchhead.jour_num = modu_rec_batchhead.jour_num 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9053,"") 
				#9053 batch NOT found
				NEXT FIELD jour_code 
			END IF 
			DISPLAY modu_rec_batchhead.entry_code, 
			modu_rec_batchhead.jour_date, 
			modu_rec_batchhead.jour_code, 
			modu_rec_batchhead.jour_num, 
			modu_rec_batchhead.year_num, 
			modu_rec_batchhead.period_num, 
			modu_rec_batchhead.post_flag, 
			modu_rec_batchhead.for_debit_amt, 
			modu_rec_batchhead.for_credit_amt, 
			modu_rec_batchhead.stats_qty, 
			modu_rec_batchhead.com1_text, 
			modu_rec_batchhead.com2_text 
			TO batchhead.entry_code, 
			batchhead.jour_date, 
			batchhead.jour_code, 
			batchhead.jour_num, 
			year1_num, 
			period1_num, 
			batchhead.post_flag, 
			batchhead.for_debit_amt, 
			batchhead.for_credit_amt, 
			batchhead.stats_qty, 
			batchhead.com1_text, 
			batchhead.com2_text 

			DISPLAY BY NAME modu_rec_batchhead.currency_code 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF modu_rec_batchhead.jour_code != modu_rec_glparms.gj_code 
			AND modu_rec_batchhead.jour_code != modu_rec_glparms.rj_code THEN 
				LET l_msgresp = kandoomsg("G",9058,"") 
				NEXT FIELD jour_code 
			END IF 
			SELECT * INTO modu_rec_batchhead.* FROM batchhead 
			WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND batchhead.jour_code = modu_rec_batchhead.jour_code 
			AND batchhead.jour_num = modu_rec_batchhead.jour_num 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9053,"") 
				#9053 Batch NOT found
				NEXT FIELD jour_code 
			END IF 
			LET modu_orig_jour_code = modu_rec_batchhead.jour_code 
			LET modu_orig_jour_num = modu_rec_batchhead.jour_num 
			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION sel_periods()
#
#
############################################################
FUNCTION sel_periods() 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_where_text CHAR(100) 
	DEFINE l_idx SMALLINT --,scrn 
	DEFINE l_msgresp LIKE language.yes_flag 

	WHILE true 
		#FOR scrn = 1 TO 6 ### G129 Screen ARRAY Size
		#    CLEAR sr_period[scrn].year_num
		#    CLEAR sr_period[scrn].period_num
		#    CLEAR sr_period[scrn].setup_flag
		#END FOR
		LET l_msgresp = kandoomsg("G",1001,"") 
		#1001 Enter selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON year_num, period_num 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G23","construct-periods") 

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
		LET l_query_text = "SELECT unique year_num,", 
		"period_num ", 
		"FROM period ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND gl_flag = \"Y\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY year_num,", 
		"period_num" 
		PREPARE s_period FROM l_query_text 
		DECLARE c_period CURSOR FOR s_period 
		LET l_idx = 0 
		FOREACH c_period INTO modu_rec_period.year_num, 
			modu_rec_period.period_num 
			LET l_idx = l_idx + 1 
			LET modu_arr_rec_period[l_idx].year_num = modu_rec_period.year_num 
			LET modu_arr_rec_period[l_idx].period_num = modu_rec_period.period_num 
			LET modu_arr_rec_period[l_idx].setup_flag ="N" 
			LET modu_arr_rec_period[l_idx].ass_jour_num = NULL 
			IF l_idx = 300 THEN 
				LET l_msgresp = kandoomsg("G",9040,l_idx) 
				#9040 First 300 GL Periods Selected "
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF l_idx = 0 THEN 
			LET l_msgresp = kandoomsg("G",9041,l_idx) 
			#9041 No GL Periods Selected
			CONTINUE WHILE 
		END IF 
		CALL set_count(l_idx) 
		LET l_msgresp = kandoomsg("G",1042,"") 

		#1042 RETURN TO Toggle - ESC TO Continue"
		INPUT ARRAY modu_arr_rec_period WITHOUT DEFAULTS FROM sr_period.* attributes(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","G23","input-arr-period") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				IF l_idx > arr_count() THEN 
					LET l_msgresp = kandoomsg("G",9001,"") 
					#9001 There are no more rows in the direction you are going"
				END IF 
			BEFORE FIELD period_num 
				IF modu_arr_rec_period[l_idx].setup_flag = "N" THEN 
					LET modu_arr_rec_period[l_idx].setup_flag = "Y" 
				ELSE 
					LET modu_arr_rec_period[l_idx].setup_flag = "N" 
				END IF 
				#DISPLAY modu_arr_rec_period[l_idx].setup_flag
				#     TO sr_period[scrn].setup_flag

				NEXT FIELD year_num 
				#AFTER ROW
				#   DISPLAY modu_arr_rec_period[l_idx].*
				#        TO sr_period[scrn].*

				--         AFTER INPUT
				--            LET arr_size = arr_count()
				--         ON KEY (control-w)
				--            CALL kandoohelp("")
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION write_batch(l_idx)
#
#
############################################################
FUNCTION write_batch(l_idx) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_idx SMALLINT 

	LET l_err_message = " Updating GL Parameters Next Journal Number" 
	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	DECLARE c_glparms CURSOR FOR 
	SELECT glparms.* 
	INTO modu_rec_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	FOR UPDATE OF next_jour_num 

	BEGIN WORK 
		LET l_err_message = " Updating GL Parameters Next Batch Number" 
		OPEN c_glparms 
		FETCH c_glparms INTO modu_rec_glparms.* 
		LET modu_rec_batchhead.jour_num = modu_rec_glparms.next_jour_num + 1 

		CALL huhoNeedsFixing("DISPLAY AT 1,35","G23.4gl") 

		DISPLAY " " at 1,35 
		DISPLAY modu_rec_batchhead.jour_num USING "<<<<<" at 1,35 

		SLEEP 1 
		UPDATE glparms 
		SET next_jour_num = modu_rec_batchhead.jour_num 
		WHERE CURRENT OF c_glparms 
		CLOSE c_glparms 
		LET l_err_message = " Inserting row INTO batchdetl" 
		DECLARE batchdetl CURSOR FOR 
		SELECT batchdetl.* INTO modu_rec_batchdetl.* FROM batchdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = modu_orig_jour_code 
		AND jour_num = modu_orig_jour_num 
		FOREACH batchdetl 
			LET modu_rec_batchdetl.jour_code = modu_rec_glparms.rj_code 
			LET modu_rec_batchdetl.jour_num = modu_rec_batchhead.jour_num 
			INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 
		END FOREACH 
		LET l_err_message = " Inserting row INTO batchhead" 
		LET modu_rec_batchhead.jour_code = modu_rec_glparms.rj_code 
		LET modu_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET modu_rec_batchhead.jour_date = today 
		LET modu_rec_batchhead.period_num = modu_arr_rec_period[l_idx].period_num 
		LET modu_rec_batchhead.year_num = modu_arr_rec_period[l_idx].year_num 
		LET modu_rec_batchhead.post_flag = "N" 

		CALL fgl_winmessage("6 Learning batch head codes - tell Hubert",modu_rec_batchhead.source_ind,"info") 
		INSERT INTO batchhead VALUES (modu_rec_batchhead.*) 
		LET modu_arr_rec_period[l_idx].ass_jour_num = modu_rec_batchhead.jour_num 

	COMMIT WORK 

	WHENEVER ERROR stop 

END FUNCTION 
