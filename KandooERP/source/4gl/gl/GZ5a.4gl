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

	Source code beautified by beautify.pl on 2020-01-03 14:29:01	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_reporthead RECORD LIKE reporthead.* 
	DEFINE glob_id_flag SMALLINT 
	DEFINE glob_cnt SMALLINT 
END GLOBALS 

############################################################
# MODULE SCOPE Variables
############################################################
DEFINE modu_rec_reportdetl RECORD LIKE reportdetl.* 
DEFINE modu_rec_t_reportdetl RECORD LIKE reportdetl.* 


DEFINE modu_reportdetl array[800] OF 
RECORD 
	line_num LIKE reportdetl.line_num, 
	col_num LIKE reportdetl.col_num, 
	command_code LIKE reportdetl.command_code, 
	sign_change_ind LIKE reportdetl.sign_change_ind, 
	label_text LIKE reportdetl.label_text, 
	flex_code LIKE reportdetl.flex_code, 
	start_acct_code LIKE reportdetl.start_acct_code, 
	end_acct_code LIKE reportdetl.end_acct_code, 
	skip_num LIKE reportdetl.skip_num , 
	ref_num LIKE reportdetl.ref_num 
END RECORD 

#DEFINE err_flag  SMALLINT  #Not used except a single LET statement

DEFINE modu_rec_cmpy LIKE company.cmpy_code 
DEFINE modu_ans CHAR(1) 


############################################################
# FUNCTION fin_inst(p_cmpy_code, p_fin_id )
#
# FUNCTION fin_inst sets up the REPORT instructions FOR the Financial Reporter
############################################################
FUNCTION fin_inst(p_cmpy_code, p_fin_id ) 
	DEFINE p_cmpy_code LIKE reportdetl.cmpy_code
	DEFINE p_fin_id LIKE reportdetl.report_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW wg120 with FORM "G120" 
	CALL windecoration_g("G120") 

	LET modu_rec_t_reportdetl.report_code = p_fin_id 
	LET modu_rec_t_reportdetl.line_num = 0 
	LET modu_rec_cmpy = p_cmpy_code 

	DISPLAY BY NAME modu_rec_t_reportdetl.report_code 


	LET l_msgresp = kandoomsg("G",1067,"") 
	#1067 "Enter line number TO start selection FROM"
	SELECT * INTO glob_rec_reporthead.* FROM reporthead 
	WHERE reporthead.report_code = modu_rec_t_reportdetl.report_code 
	AND reporthead.cmpy_code = modu_rec_cmpy 
	IF (status = NOTFOUND) THEN 
		LET l_msgresp = kandoomsg("G",9116,"") 
		#9116 "This REPORT was NOT found"
		CLOSE WINDOW wg120 
		RETURN 
	END IF 
	DISPLAY BY NAME glob_rec_reporthead.desc_text 

	INPUT BY NAME modu_rec_t_reportdetl.line_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ5a","repHeadDesc") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD line_num 
			IF modu_rec_t_reportdetl.line_num IS NULL THEN 
				LET modu_rec_t_reportdetl.line_num = 0 
			END IF 
			EXIT INPUT 

	END INPUT 

	CALL detail() 

END FUNCTION 


############################################################
# FUNCTION detail()
#
# get length of chart FOR later on
############################################################
FUNCTION detail() 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_lengther SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	# get length of chart FOR later on
	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = modu_rec_cmpy 
	AND type_ind = "C" 

	DECLARE c_fin CURSOR FOR 
	SELECT * INTO modu_rec_reportdetl.* FROM reportdetl 
	WHERE reportdetl.report_code = modu_rec_t_reportdetl.report_code 
	AND reportdetl.cmpy_code = modu_rec_cmpy 
	AND reportdetl.line_num >= modu_rec_t_reportdetl.line_num 
	ORDER BY reportdetl.report_code, reportdetl.line_num 

	LET l_idx = 0 
	FOREACH c_fin 
		LET l_idx = l_idx + 1 
		LET modu_reportdetl[l_idx].line_num = modu_rec_reportdetl.line_num 
		LET modu_reportdetl[l_idx].ref_num = modu_rec_reportdetl.ref_num 
		LET modu_reportdetl[l_idx].command_code = modu_rec_reportdetl.command_code 
		LET modu_reportdetl[l_idx].sign_change_ind = modu_rec_reportdetl.sign_change_ind 
		LET modu_reportdetl[l_idx].col_num = modu_rec_reportdetl.col_num 
		LET modu_reportdetl[l_idx].label_text = modu_rec_reportdetl.label_text 
		LET modu_reportdetl[l_idx].flex_code = modu_rec_reportdetl.flex_code 
		LET modu_reportdetl[l_idx].start_acct_code = modu_rec_reportdetl.start_acct_code 
		LET modu_reportdetl[l_idx].end_acct_code = modu_rec_reportdetl.end_acct_code 
		LET modu_reportdetl[l_idx].skip_num = modu_rec_reportdetl.skip_num 
		IF l_idx = 800 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			#6100 First l_idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("U",1003,"") 

	#1003 "F1 TO add, RETURN on line TO change, F2 TO delete"
	INPUT ARRAY modu_reportdetl WITHOUT DEFAULTS FROM sr_reportdetl.* attributes(UNBUFFERED, append ROW = false, auto append = false) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ5a","repHeadDesc2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET modu_rec_reportdetl.line_num = modu_reportdetl[l_idx].line_num 
			LET modu_rec_reportdetl.ref_num = modu_reportdetl[l_idx].ref_num 
			LET modu_rec_reportdetl.command_code = modu_reportdetl[l_idx].command_code 
			LET modu_rec_reportdetl.sign_change_ind = modu_reportdetl[l_idx].sign_change_ind 
			LET modu_rec_reportdetl.col_num = modu_reportdetl[l_idx].col_num 
			LET modu_rec_reportdetl.label_text = modu_reportdetl[l_idx].label_text 
			LET modu_rec_reportdetl.flex_code = modu_reportdetl[l_idx].flex_code 
			LET modu_rec_reportdetl.start_acct_code = modu_reportdetl[l_idx].start_acct_code 
			LET modu_rec_reportdetl.end_acct_code = modu_reportdetl[l_idx].end_acct_code 
			LET modu_rec_reportdetl.skip_num = modu_reportdetl[l_idx].skip_num 
			SELECT * INTO modu_rec_reportdetl.* FROM reportdetl 
			WHERE cmpy_code = modu_rec_cmpy 
			AND report_code = modu_rec_t_reportdetl.report_code 
			AND line_num = modu_rec_reportdetl.line_num 
			LET glob_id_flag = 0 
			#LET err_flag = 0 #huho - keep it commented, err_flag was only set to 0 here.. not touched in any other places of the prog sources

		ON ACTION "LOOKUP" infield (start_acct_code) 
			LET modu_reportdetl[l_idx].start_acct_code = show_acct(modu_rec_cmpy) 
			#DISPLAY modu_reportdetl[l_idx].start_acct_code
			#                       TO sr_reportdetl[scrn].start_acct_code

			NEXT FIELD start_acct_code 

		ON ACTION "LOOKUP" infield (end_acct_code) 
			LET modu_reportdetl[l_idx].end_acct_code = show_acct(modu_rec_cmpy) 
			#DISPLAY modu_reportdetl[l_idx].end_acct_code
			#                       TO sr_reportdetl[scrn].end_acct_code

			NEXT FIELD end_acct_code 


		AFTER FIELD line_num 
			IF (modu_reportdetl[l_idx].line_num IS null) THEN 
				IF (modu_reportdetl[l_idx].ref_num IS NOT null) THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD line_num 
				END IF 
			ELSE 
				IF modu_reportdetl[l_idx].line_num >= 1000 THEN 
					LET l_msgresp = kandoomsg("U",9046,"999.99") 
					#9046 "Line Number must be less than OR equal TO 999.99"
					NEXT FIELD line_num 
				ELSE 
					IF (modu_reportdetl[l_idx].line_num != modu_rec_reportdetl.line_num) 
					OR (modu_reportdetl[l_idx].line_num IS NOT NULL AND 
					modu_rec_reportdetl.line_num IS null) THEN 
						SELECT count(*) INTO glob_cnt FROM reportdetl 
						WHERE line_num = modu_reportdetl[l_idx].line_num 
						AND report_code = modu_rec_t_reportdetl.report_code 
						AND cmpy_code = modu_rec_cmpy 
						IF (glob_cnt != 0) THEN 
							LET l_msgresp = kandoomsg("U",9104,"") 
							#9104 This RECORD already exists
							NEXT FIELD line_num 
						END IF 
					END IF 
				END IF 
			END IF 

		AFTER FIELD col_num 
			NEXT FIELD command_code 

		AFTER FIELD command_code 
			IF (modu_reportdetl[l_idx].command_code = "A1" 
			OR modu_reportdetl[l_idx].command_code = "A2" 
			OR modu_reportdetl[l_idx].command_code = "A3" 
			OR modu_reportdetl[l_idx].command_code = "A4" 
			OR modu_reportdetl[l_idx].command_code = "A5" 
			OR modu_reportdetl[l_idx].command_code = "A6" 
			OR modu_reportdetl[l_idx].command_code = "CB" 
			OR modu_reportdetl[l_idx].command_code = "CC" 
			OR modu_reportdetl[l_idx].command_code = "CJ" 
			OR modu_reportdetl[l_idx].command_code = "DR" 
			OR modu_reportdetl[l_idx].command_code = TRAN_TYPE_INVOICE_IN 
			OR modu_reportdetl[l_idx].command_code = "IP" 
			OR modu_reportdetl[l_idx].command_code = "IY" 
			OR modu_reportdetl[l_idx].command_code = "LA" 
			OR modu_reportdetl[l_idx].command_code = "LB" 
			OR modu_reportdetl[l_idx].command_code = "LP" 
			OR modu_reportdetl[l_idx].command_code = "LY" 
			OR modu_reportdetl[l_idx].command_code = "L1" 
			OR modu_reportdetl[l_idx].command_code = "L2" 
			OR modu_reportdetl[l_idx].command_code = "L3" 
			OR modu_reportdetl[l_idx].command_code = "L4" 
			OR modu_reportdetl[l_idx].command_code = "L5" 
			OR modu_reportdetl[l_idx].command_code = "L6" 
			OR modu_reportdetl[l_idx].command_code = "PA" 
			OR modu_reportdetl[l_idx].command_code = "PG" 
			OR modu_reportdetl[l_idx].command_code = "PR" 
			OR modu_reportdetl[l_idx].command_code = "PS" 
			OR modu_reportdetl[l_idx].command_code = "P1" 
			OR modu_reportdetl[l_idx].command_code = "P2" 
			OR modu_reportdetl[l_idx].command_code = "P3" 
			OR modu_reportdetl[l_idx].command_code = "P4" 
			OR modu_reportdetl[l_idx].command_code = "P5" 
			OR modu_reportdetl[l_idx].command_code = "P6" 
			OR modu_reportdetl[l_idx].command_code = "RP" 
			OR modu_reportdetl[l_idx].command_code = "RY" 
			OR modu_reportdetl[l_idx].command_code = "SA" 
			OR modu_reportdetl[l_idx].command_code = "SN" 
			OR modu_reportdetl[l_idx].command_code = "SO" 
			OR modu_reportdetl[l_idx].command_code = "V1" 
			OR modu_reportdetl[l_idx].command_code = "V2" 
			OR modu_reportdetl[l_idx].command_code = "V3" 
			OR modu_reportdetl[l_idx].command_code = "V4" 
			OR modu_reportdetl[l_idx].command_code = "V5" 
			OR modu_reportdetl[l_idx].command_code = "V6" 
			OR modu_reportdetl[l_idx].command_code = "YA" 
			OR modu_reportdetl[l_idx].command_code = "YR" 
			OR modu_reportdetl[l_idx].command_code = "YS" 
			OR modu_reportdetl[l_idx].command_code = "Y1" 
			OR modu_reportdetl[l_idx].command_code = "Y2" 
			OR modu_reportdetl[l_idx].command_code = "Y3" 
			OR modu_reportdetl[l_idx].command_code = "Y4" 
			OR modu_reportdetl[l_idx].command_code = "Y5" 
			OR modu_reportdetl[l_idx].command_code = "Y6" 
			OR modu_reportdetl[l_idx].command_code = "U1" 
			OR modu_reportdetl[l_idx].command_code = "U2" 
			OR modu_reportdetl[l_idx].command_code = "U3" 
			OR modu_reportdetl[l_idx].command_code = "U4" 
			OR modu_reportdetl[l_idx].command_code = "U5" 
			OR modu_reportdetl[l_idx].command_code = "U6" 
			OR modu_reportdetl[l_idx].command_code = "%" 
			OR modu_reportdetl[l_idx].command_code = "+" 
			OR modu_reportdetl[l_idx].command_code = "-" ) THEN 
				NEXT FIELD sign_change_ind 
			ELSE 
				LET l_msgresp = kandoomsg("U",9112,"Command Code") 
				#9112 Invalid Command Code
				NEXT FIELD command_code 
			END IF 

		AFTER FIELD sign_change_ind 
			NEXT FIELD label_text 

		AFTER FIELD label_text 
			NEXT FIELD flex_code 

		AFTER FIELD flex_code 
			NEXT FIELD start_acct_code 

		AFTER FIELD start_acct_code 
			LET l_lengther = l_rec_structure.length_num 
			LET modu_reportdetl[l_idx].start_acct_code = 
			modu_reportdetl[l_idx].start_acct_code[1, l_lengther] 
			#DISPLAY modu_reportdetl[l_idx].start_acct_code TO
			#                   sr_reportdetl[scrn].start_acct_code

			NEXT FIELD end_acct_code 

		AFTER FIELD end_acct_code 
			LET modu_reportdetl[l_idx].end_acct_code = 
			modu_reportdetl[l_idx].end_acct_code[1, l_lengther] 
			#DISPLAY modu_reportdetl[l_idx].end_acct_code TO
			#                   sr_reportdetl[scrn].end_acct_code

			NEXT FIELD skip_num 

		AFTER FIELD skip_num 
			NEXT FIELD ref_num 

		BEFORE INSERT 
			INITIALIZE modu_rec_reportdetl.* TO NULL 
			LET modu_rec_reportdetl.cmpy_code = modu_rec_cmpy 
			LET modu_rec_reportdetl.ref_num = 0 

		AFTER INSERT 
			IF (modu_reportdetl[l_idx].line_num IS NOT null) THEN 
				LET modu_rec_reportdetl.cmpy_code = modu_rec_cmpy 
				LET modu_rec_reportdetl.report_code = modu_rec_t_reportdetl.report_code 
				LET modu_rec_reportdetl.line_num = modu_reportdetl[l_idx].line_num 

				IF modu_reportdetl[l_idx].command_code IS NULL THEN 
					LET modu_rec_reportdetl.command_code = ' ' ELSE 
					LET modu_rec_reportdetl.command_code = 
					modu_reportdetl[l_idx].command_code 
				END IF 

				IF modu_reportdetl[l_idx].sign_change_ind IS NULL THEN 
					LET modu_rec_reportdetl.sign_change_ind = ' ' 
				ELSE 
					LET modu_rec_reportdetl.sign_change_ind = 
					modu_reportdetl[l_idx].sign_change_ind 
				END IF 

				IF modu_reportdetl[l_idx].ref_num IS NULL THEN 
					LET modu_rec_reportdetl.ref_num = 0 ELSE 
					LET modu_rec_reportdetl.ref_num = modu_reportdetl[l_idx].ref_num 
				END IF 

				IF modu_reportdetl[l_idx].col_num IS NULL THEN 
					LET modu_rec_reportdetl.col_num = 0 
				ELSE 
					LET modu_rec_reportdetl.col_num = modu_reportdetl[l_idx].col_num 
				END IF 

				IF modu_reportdetl[l_idx].label_text IS NULL THEN 
					LET modu_rec_reportdetl.label_text = ' ' 
				ELSE 
					LET modu_rec_reportdetl.label_text = modu_reportdetl[l_idx].label_text 
				END IF 

				LET modu_rec_reportdetl.flex_code = modu_reportdetl[l_idx].flex_code 

				IF modu_reportdetl[l_idx].start_acct_code IS NULL THEN 
					LET modu_rec_reportdetl.start_acct_code = 0 
				ELSE 
					LET modu_rec_reportdetl.start_acct_code = 
					modu_reportdetl[l_idx].start_acct_code 
				END IF 

				IF modu_reportdetl[l_idx].end_acct_code IS NULL THEN 
					LET modu_rec_reportdetl.end_acct_code = 0 
				ELSE 
					LET modu_rec_reportdetl.end_acct_code = modu_reportdetl[l_idx].end_acct_code 
				END IF 

				IF modu_reportdetl[l_idx].skip_num IS NULL THEN 
					LET modu_rec_reportdetl.skip_num = 0 
				ELSE 
					LET modu_rec_reportdetl.skip_num = modu_reportdetl[l_idx].skip_num 
				END IF 

				LET modu_reportdetl[l_idx].line_num = modu_rec_reportdetl.line_num 

				INSERT INTO reportdetl VALUES (modu_rec_reportdetl.*) 
			END IF 

		AFTER DELETE 
			DELETE FROM reportdetl 
			WHERE cmpy_code = modu_rec_cmpy AND 
			report_code = modu_rec_t_reportdetl.report_code AND 
			line_num = modu_rec_reportdetl.line_num 

		AFTER ROW 
			IF (modu_reportdetl[l_idx].line_num IS null) THEN 
				LET glob_id_flag = -1 
			END IF 

			IF (glob_id_flag = 0 
			AND (modu_rec_reportdetl.ref_num != modu_reportdetl[l_idx].ref_num 
			OR (modu_rec_reportdetl.ref_num IS NULL AND 
			modu_reportdetl[l_idx].ref_num IS NOT null) 
			OR (modu_rec_reportdetl.ref_num IS NOT NULL AND 
			modu_reportdetl[l_idx].ref_num IS null) 
			OR modu_rec_reportdetl.command_code != modu_reportdetl[l_idx].command_code 
			OR (modu_rec_reportdetl.command_code IS NULL AND 
			modu_reportdetl[l_idx].command_code IS NOT null) 
			OR (modu_rec_reportdetl.command_code IS NOT NULL AND 
			modu_reportdetl[l_idx].command_code IS null) 
			OR modu_rec_reportdetl.sign_change_ind != modu_reportdetl[l_idx].sign_change_ind 
			OR (modu_rec_reportdetl.sign_change_ind IS NULL AND 
			modu_reportdetl[l_idx].sign_change_ind IS NOT null) 
			OR (modu_rec_reportdetl.sign_change_ind IS NOT NULL AND 
			modu_reportdetl[l_idx].sign_change_ind IS null) 
			OR modu_rec_reportdetl.col_num != modu_reportdetl[l_idx].col_num 
			OR (modu_rec_reportdetl.col_num IS NULL AND 
			modu_reportdetl[l_idx].col_num IS NOT null) 
			OR (modu_rec_reportdetl.col_num IS NOT NULL AND 
			modu_reportdetl[l_idx].col_num IS null) 
			OR modu_rec_reportdetl.label_text != modu_reportdetl[l_idx].label_text 
			OR (modu_rec_reportdetl.label_text IS NULL AND 
			modu_reportdetl[l_idx].label_text IS NOT null) 
			OR (modu_rec_reportdetl.label_text IS NOT NULL AND 
			modu_reportdetl[l_idx].label_text IS null) 
			OR modu_rec_reportdetl.flex_code != modu_reportdetl[l_idx].flex_code 
			OR (modu_rec_reportdetl.flex_code IS NULL AND 
			modu_reportdetl[l_idx].flex_code IS NOT null) 
			OR (modu_rec_reportdetl.flex_code IS NOT NULL AND 
			modu_reportdetl[l_idx].flex_code IS null) 
			OR modu_rec_reportdetl.start_acct_code != modu_reportdetl[l_idx].start_acct_code 
			OR (modu_rec_reportdetl.start_acct_code IS NULL AND 
			modu_reportdetl[l_idx].start_acct_code IS NOT null) 
			OR (modu_rec_reportdetl.start_acct_code IS NOT NULL AND 
			modu_reportdetl[l_idx].start_acct_code IS null) 
			OR modu_rec_reportdetl.end_acct_code != modu_reportdetl[l_idx].end_acct_code 
			OR (modu_rec_reportdetl.end_acct_code IS NULL AND 
			modu_reportdetl[l_idx].end_acct_code IS NOT null) 
			OR (modu_rec_reportdetl.end_acct_code IS NOT NULL AND 
			modu_reportdetl[l_idx].end_acct_code IS null) 
			OR modu_rec_reportdetl.skip_num != modu_reportdetl[l_idx].skip_num 
			OR (modu_rec_reportdetl.skip_num IS NULL AND 
			modu_reportdetl[l_idx].skip_num IS NOT null) 
			OR (modu_rec_reportdetl.skip_num IS NOT NULL AND 
			modu_reportdetl[l_idx].skip_num IS null))) THEN 

				LET modu_rec_reportdetl.line_num = modu_reportdetl[l_idx].line_num 

				IF modu_reportdetl[l_idx].ref_num IS NULL THEN 
					LET modu_rec_reportdetl.ref_num = ' ' 
				ELSE 
					LET modu_rec_reportdetl.ref_num = modu_reportdetl[l_idx].ref_num 
				END IF 

				IF modu_reportdetl[l_idx].command_code IS NULL THEN 
					LET modu_rec_reportdetl.command_code = ' ' 
				ELSE 
					LET modu_rec_reportdetl.command_code = 
					modu_reportdetl[l_idx].command_code 
				END IF 

				IF modu_reportdetl[l_idx].sign_change_ind IS NULL THEN 
					LET modu_rec_reportdetl.sign_change_ind = ' ' 
				ELSE 
					LET modu_rec_reportdetl.sign_change_ind = 
					modu_reportdetl[l_idx].sign_change_ind 
				END IF 

				IF modu_reportdetl[l_idx].ref_num IS NULL THEN 
					LET modu_rec_reportdetl.ref_num = 0 
				ELSE 
					LET modu_rec_reportdetl.ref_num = modu_reportdetl[l_idx].ref_num 
				END IF 

				IF modu_reportdetl[l_idx].col_num IS NULL THEN 
					LET modu_rec_reportdetl.col_num = 0 
				ELSE 
					LET modu_rec_reportdetl.col_num = modu_reportdetl[l_idx].col_num 
				END IF 

				IF modu_reportdetl[l_idx].label_text IS NULL THEN 
					LET modu_rec_reportdetl.label_text = ' ' 
				ELSE 
					LET modu_rec_reportdetl.label_text = modu_reportdetl[l_idx].label_text 
				END IF 

				LET modu_rec_reportdetl.flex_code = modu_reportdetl[l_idx].flex_code 

				IF modu_reportdetl[l_idx].start_acct_code IS NULL THEN 
					LET modu_rec_reportdetl.start_acct_code = 0 
				ELSE 
					LET modu_rec_reportdetl.start_acct_code = 
					modu_reportdetl[l_idx].start_acct_code 
				END IF 

				IF modu_reportdetl[l_idx].end_acct_code IS NULL THEN 
					LET modu_rec_reportdetl.end_acct_code = 0 
				ELSE 
					LET modu_rec_reportdetl.end_acct_code = 
					modu_reportdetl[l_idx].end_acct_code 
				END IF 

				IF modu_reportdetl[l_idx].skip_num IS NULL THEN 
					LET modu_rec_reportdetl.skip_num = 0 
				ELSE 
					LET modu_rec_reportdetl.skip_num = modu_reportdetl[l_idx].skip_num 
				END IF 
				UPDATE reportdetl SET * = modu_rec_reportdetl.* 
				WHERE cmpy_code = modu_rec_cmpy AND 
				report_code = modu_rec_reportdetl.report_code AND 
				line_num = modu_rec_reportdetl.line_num 
			END IF 

			IF (glob_id_flag = 0 
			AND (modu_reportdetl[l_idx].line_num IS NOT NULL 
			AND modu_rec_reportdetl.line_num IS null)) THEN 
				LET modu_rec_reportdetl.cmpy_code = modu_rec_cmpy 
				LET modu_rec_reportdetl.report_code = modu_rec_t_reportdetl.report_code 
				LET modu_rec_reportdetl.line_num = modu_reportdetl[l_idx].line_num 
				LET modu_rec_reportdetl.command_code = modu_reportdetl[l_idx].command_code 
				LET modu_rec_reportdetl.sign_change_ind = modu_reportdetl[l_idx].sign_change_ind 
				LET modu_rec_reportdetl.ref_num = modu_reportdetl[l_idx].ref_num 
				LET modu_rec_reportdetl.col_num = modu_reportdetl[l_idx].col_num 
				LET modu_rec_reportdetl.label_text = modu_reportdetl[l_idx].label_text 
				LET modu_rec_reportdetl.flex_code = modu_reportdetl[l_idx].flex_code 
				LET modu_rec_reportdetl.start_acct_code = modu_reportdetl[l_idx].start_acct_code 
				LET modu_rec_reportdetl.end_acct_code = modu_reportdetl[l_idx].end_acct_code 
				LET modu_rec_reportdetl.skip_num = modu_reportdetl[l_idx].skip_num 
				INSERT INTO reportdetl VALUES (modu_rec_reportdetl.*) 
			END IF 
	END INPUT 

	CLOSE WINDOW wg120 

END FUNCTION 


