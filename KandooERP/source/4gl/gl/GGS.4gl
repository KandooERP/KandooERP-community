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

	Source code beautified by beautify.pl on 2020-01-03 14:28:45	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GGS.4gl maintains GL Summary Segment information

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MODULEL Scope Variables
############################################################
DEFINE modu_rec_glsumdiv RECORD LIKE glsumdiv.*
DEFINE modu_arr_rec_glsumdiv array[9] OF RECORD 
		col_num LIKE glsumdiv.pos_code, 
		desc_text LIKE glsumdiv.desc_text, 
		div1_code LIKE glsumdiv.div1_code, 
		div2_code LIKE glsumdiv.div2_code, 
		div3_code LIKE glsumdiv.div3_code, 
		div4_code LIKE glsumdiv.div4_code, 
		div5_code LIKE glsumdiv.div5_code, 
		div6_code LIKE glsumdiv.div6_code, 
		div7_code LIKE glsumdiv.div7_code, 
		div8_code LIKE glsumdiv.div8_code, 
		div9_code LIKE glsumdiv.div9_code 
	END RECORD 
DEFINE modu_store_start LIKE glsumdiv.start_num 
DEFINE modu_store_level LIKE glsumdiv.report_level_ind 
DEFINE modu_idx SMALLINT  
 

############################################################
# MAIN
#
#
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("GGS") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL enter_div_table() 

END MAIN 


############################################################
# FUNCTION enter_div_table()
#
#
############################################################
FUNCTION enter_div_table() 
	DEFINE l_div_desc_text LIKE structure.desc_text 
	DEFINE i SMALLINT 
	DEFINE l_blank_col SMALLINT

	SELECT unique start_num, 
	report_level_ind 
	INTO modu_rec_glsumdiv.start_num, 
	modu_rec_glsumdiv.report_level_ind 
	FROM glsumdiv 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET modu_rec_glsumdiv.start_num = NULL 
	END IF 

	OPEN WINDOW wg209 with FORM "G209" 
	CALL windecoration_g("G209") 

	MESSAGE " Enter Segment information, DEL TO EXIT" 

	LET modu_store_start = modu_rec_glsumdiv.start_num 
	LET modu_store_level = modu_rec_glsumdiv.report_level_ind 
	SELECT desc_text 
	INTO l_div_desc_text 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = modu_rec_glsumdiv.start_num 

	DISPLAY modu_rec_glsumdiv.start_num TO start_num 
	DISPLAY l_div_desc_text TO div_desc_text 
	DISPLAY modu_rec_glsumdiv.report_level_ind TO report_level_ind

	INPUT BY NAME modu_rec_glsumdiv.start_num, modu_rec_glsumdiv.report_level_ind WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GGS","inp-glsumdiv") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD start_num 
			IF modu_rec_glsumdiv.start_num IS NULL THEN 
				ERROR " Divison start position must be entered " 
				NEXT FIELD start_num 
			END IF 
			SELECT desc_text 
			INTO l_div_desc_text 
			FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_ind = "S" 
			AND start_num = modu_rec_glsumdiv.start_num 
			IF status = NOTFOUND THEN 
				ERROR " Starting number must match valid chart segment" 
				NEXT FIELD start_num 
			END IF 
			
			DISPLAY l_div_desc_text TO div_desc_text

			IF modu_store_start IS NOT NULL AND 
			modu_rec_glsumdiv.start_num != modu_store_start THEN 
				IF NOT ok_to_change() THEN 
					LET modu_rec_glsumdiv.start_num = modu_store_start 
					
					DISPLAY modu_rec_glsumdiv.start_num TO start_num 

					NEXT FIELD start_num 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW wg209 
		RETURN 
	END IF 
	LET modu_store_start = modu_rec_glsumdiv.start_num 
	LET modu_store_level = modu_rec_glsumdiv.report_level_ind 

	FOR i = 1 TO 9 
		INITIALIZE modu_arr_rec_glsumdiv[i].* TO NULL 
	END FOR 
	LET modu_idx = 0 

	# Only retrieve existing segments IF start num has NOT changed
	# (ie. same segment) AND NOT a new entry (ie. NULL start num)

	IF modu_store_start IS NOT NULL AND 
	modu_rec_glsumdiv.start_num = modu_store_start THEN 
		DECLARE c_glsumdiv CURSOR FOR 
		SELECT * 
		INTO modu_rec_glsumdiv.* 
		FROM glsumdiv 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		ORDER BY pos_code 

		FOREACH c_glsumdiv 
			LET modu_idx = modu_idx + 1 
			LET modu_arr_rec_glsumdiv[modu_idx].col_num = modu_rec_glsumdiv.pos_code 
			LET modu_arr_rec_glsumdiv[modu_idx].desc_text = modu_rec_glsumdiv.desc_text 
			LET modu_arr_rec_glsumdiv[modu_idx].div1_code = modu_rec_glsumdiv.div1_code 
			LET modu_arr_rec_glsumdiv[modu_idx].div2_code = modu_rec_glsumdiv.div2_code 
			LET modu_arr_rec_glsumdiv[modu_idx].div3_code = modu_rec_glsumdiv.div3_code 
			LET modu_arr_rec_glsumdiv[modu_idx].div4_code = modu_rec_glsumdiv.div4_code 
			LET modu_arr_rec_glsumdiv[modu_idx].div5_code = modu_rec_glsumdiv.div5_code 
			LET modu_arr_rec_glsumdiv[modu_idx].div6_code = modu_rec_glsumdiv.div6_code 
			LET modu_arr_rec_glsumdiv[modu_idx].div7_code = modu_rec_glsumdiv.div7_code 
			LET modu_arr_rec_glsumdiv[modu_idx].div8_code = modu_rec_glsumdiv.div8_code 
			LET modu_arr_rec_glsumdiv[modu_idx].div9_code = modu_rec_glsumdiv.div9_code 
		END FOREACH 
	END IF 
	CALL set_count(modu_idx) 

	INPUT ARRAY modu_arr_rec_glsumdiv WITHOUT DEFAULTS FROM sr_glsumdiv.* attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GGS","inp-arr-glsumdiv") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (div1_code) 
			LET modu_arr_rec_glsumdiv[modu_idx].div1_code = 
			show_flex(glob_rec_kandoouser.cmpy_code, 
			modu_rec_glsumdiv.start_num) 
			NEXT FIELD div1_code 

		ON ACTION "LOOKUP" infield (div2_code) 
			LET modu_arr_rec_glsumdiv[modu_idx].div2_code = 
			show_flex(glob_rec_kandoouser.cmpy_code, 
			modu_rec_glsumdiv.start_num) 
			NEXT FIELD div2_code 

		ON ACTION "LOOKUP" infield (div3_code) 
			LET modu_arr_rec_glsumdiv[modu_idx].div3_code = 
			show_flex(glob_rec_kandoouser.cmpy_code, 
			modu_rec_glsumdiv.start_num) 
			NEXT FIELD div3_code 

		ON ACTION "LOOKUP" infield (div4_code) 
			LET modu_arr_rec_glsumdiv[modu_idx].div4_code = 
			show_flex(glob_rec_kandoouser.cmpy_code, 
			modu_rec_glsumdiv.start_num) 
			NEXT FIELD div4_code 

		ON ACTION "LOOKUP" infield (div5_code) 
			LET modu_arr_rec_glsumdiv[modu_idx].div5_code = 
			show_flex(glob_rec_kandoouser.cmpy_code, 
			modu_rec_glsumdiv.start_num) 
			NEXT FIELD div5_code 

		ON ACTION "LOOKUP" infield (div6_code) 
			LET modu_arr_rec_glsumdiv[modu_idx].div6_code = 
			show_flex(glob_rec_kandoouser.cmpy_code, 
			modu_rec_glsumdiv.start_num) 
			NEXT FIELD div6_code 

		ON ACTION "LOOKUP" infield (div7_code) 
			LET modu_arr_rec_glsumdiv[modu_idx].div7_code = 
			show_flex(glob_rec_kandoouser.cmpy_code, 
			modu_rec_glsumdiv.start_num) 
			NEXT FIELD div7_code 

		ON ACTION "LOOKUP" infield (div8_code) 
			LET modu_arr_rec_glsumdiv[modu_idx].div8_code = 
			show_flex(glob_rec_kandoouser.cmpy_code, 
			modu_rec_glsumdiv.start_num) 
			NEXT FIELD div8_code 

		ON ACTION "LOOKUP" infield (div9_code) 
			LET modu_arr_rec_glsumdiv[modu_idx].div9_code = 
			show_flex(glob_rec_kandoouser.cmpy_code, 
			modu_rec_glsumdiv.start_num) 
			NEXT FIELD div9_code 


		BEFORE ROW 
			LET modu_idx = arr_curr() 
			#LET scrn = scr_line()

		BEFORE INSERT 
			FOR i = modu_idx TO arr_count() 
				LET modu_arr_rec_glsumdiv[i].col_num = i 
				DISPLAY modu_arr_rec_glsumdiv[i].col_num TO 
				sr_glsumdiv[i].col_num 
			END FOR 

		AFTER DELETE 
			FOR i = modu_idx TO arr_count() 
				LET modu_arr_rec_glsumdiv[i].col_num = i 
				DISPLAY modu_arr_rec_glsumdiv[i].col_num TO 
				sr_glsumdiv[i].col_num 
			END FOR 

		AFTER FIELD col_num 
			IF modu_arr_rec_glsumdiv[modu_idx].col_num != modu_idx THEN 
				ERROR " Columns must be entered in sequence" 
				NEXT FIELD col_num 
			END IF 

		AFTER FIELD desc_text 
			IF modu_arr_rec_glsumdiv[modu_idx].desc_text IS NULL AND 
			modu_arr_rec_glsumdiv[modu_idx].col_num IS NOT NULL THEN 
				ERROR " Column must have description " 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD div1_code 
			IF NOT valid_div(modu_arr_rec_glsumdiv[modu_idx].div1_code) THEN 
				NEXT FIELD div1_code 
			END IF 

		AFTER FIELD div2_code 
			IF NOT valid_div(modu_arr_rec_glsumdiv[modu_idx].div2_code) THEN 
				NEXT FIELD div2_code 
			END IF 

		AFTER FIELD div3_code 
			IF NOT valid_div(modu_arr_rec_glsumdiv[modu_idx].div3_code) THEN 
				NEXT FIELD div3_code 
			END IF 

		AFTER FIELD div4_code 
			IF NOT valid_div(modu_arr_rec_glsumdiv[modu_idx].div4_code) THEN 
				NEXT FIELD div4_code 
			END IF 

		AFTER FIELD div5_code 
			IF NOT valid_div(modu_arr_rec_glsumdiv[modu_idx].div5_code) THEN 
				NEXT FIELD div5_code 
			END IF 

		AFTER FIELD div6_code 
			IF NOT valid_div(modu_arr_rec_glsumdiv[modu_idx].div6_code) THEN 
				NEXT FIELD div6_code 
			END IF 

		AFTER FIELD div7_code 
			IF NOT valid_div(modu_arr_rec_glsumdiv[modu_idx].div7_code) THEN 
				NEXT FIELD div7_code 
			END IF 

		AFTER FIELD div8_code 
			IF NOT valid_div(modu_arr_rec_glsumdiv[modu_idx].div8_code) THEN 
				NEXT FIELD div8_code 
			END IF 

		AFTER FIELD div9_code 
			IF NOT valid_div(modu_arr_rec_glsumdiv[modu_idx].div9_code) THEN 
				NEXT FIELD div9_code 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			LET l_blank_col = false 
			FOR i = 1 TO arr_count() - 1 
				IF modu_arr_rec_glsumdiv[i].col_num IS NOT NULL AND 
				modu_arr_rec_glsumdiv[i].desc_text IS NULL THEN 
					LET l_blank_col = true 
				END IF 
			END FOR 
			IF l_blank_col THEN 
				ERROR " All columns must have descriptions " 
				NEXT FIELD col_num 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW wg209 
		RETURN 
	END IF 
	
	MESSAGE " Updating segments - please wait" 
	CALL div_update() 

	CLOSE WINDOW wg209 
	RETURN 

END FUNCTION 


############################################################
# FUNCTION ok_to_change()
#
#
############################################################
FUNCTION ok_to_change() 
	DEFINE l_ans CHAR(1) 
	DEFINE l_tmpmsg STRING 

	LET l_tmpmsg = " New segment - table will be re-initialised - ok TO continue?\n Or do you wish TO hold line information? " 

	LET l_ans = promptYN("New segment",l_tmpmsg,"Y") 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_ans = "n" 
	END IF 
	IF l_ans matches "[Yy]" THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION 


############################################################
# FUNCTION valid_div(p_division)
#
#
############################################################
FUNCTION valid_div(p_division) 
	DEFINE p_division LIKE glsumdiv.div1_code 
	DEFINE i SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_div_count SMALLINT 

	# p_division must be a valid code FROM the flex table AND unique
	# within the summary table

	IF p_division IS NULL THEN 
		RETURN true 
	END IF 

	SELECT count(*) 
	INTO l_counter 
	FROM validflex 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = modu_rec_glsumdiv.start_num 
	AND flex_code = p_division 
	IF l_counter = 0 THEN 
		ERROR " Segment NOT found " 
		RETURN false 
	ELSE 
		LET l_div_count = 0 
		FOR i = 1 TO arr_count() 
			IF modu_arr_rec_glsumdiv[i].div1_code = p_division THEN 
				LET l_div_count = l_div_count + 1 
			END IF 
			IF modu_arr_rec_glsumdiv[i].div2_code = p_division THEN 
				LET l_div_count = l_div_count + 1 
			END IF 
			IF modu_arr_rec_glsumdiv[i].div3_code = p_division THEN 
				LET l_div_count = l_div_count + 1 
			END IF 
			IF modu_arr_rec_glsumdiv[i].div4_code = p_division THEN 
				LET l_div_count = l_div_count + 1 
			END IF 
			IF modu_arr_rec_glsumdiv[i].div5_code = p_division THEN 
				LET l_div_count = l_div_count + 1 
			END IF 
			IF modu_arr_rec_glsumdiv[i].div6_code = p_division THEN 
				LET l_div_count = l_div_count + 1 
			END IF 
			IF modu_arr_rec_glsumdiv[i].div7_code = p_division THEN 
				LET l_div_count = l_div_count + 1 
			END IF 
			IF modu_arr_rec_glsumdiv[i].div8_code = p_division THEN 
				LET l_div_count = l_div_count + 1 
			END IF 
			IF modu_arr_rec_glsumdiv[i].div9_code = p_division THEN 
				LET l_div_count = l_div_count + 1 
			END IF 
			IF l_div_count > 1 THEN 
				ERROR " This segment already entered " 
				EXIT FOR 
			END IF 
		END FOR 
		IF l_div_count > 1 THEN 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 
	END IF 

END FUNCTION 


############################################################
# FUNCTION div_update()
#
#
############################################################
FUNCTION div_update() 
	DEFINE i SMALLINT 
	DEFINE l_try_again CHAR(1) 
	DEFINE l_err_message CHAR(60) 

	GOTO bypass 
	LABEL recovery: 
	LET l_try_again = error_recover(l_err_message, status) 
	IF l_try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LOCK TABLE glsumdiv in share MODE 

		# Delete existing entries AND re-enter table FROM entered data

		LET l_err_message = "Deleting FROM glsumdiv" 
		DELETE FROM glsumdiv 

		LET l_err_message = "Inserting INTO Summ Div table" 
		LET modu_rec_glsumdiv.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET modu_rec_glsumdiv.start_num = modu_store_start 
		LET modu_rec_glsumdiv.report_level_ind = modu_store_level
		 
		FOR i = 1 TO 9 
			IF modu_arr_rec_glsumdiv[i].col_num IS NOT NULL AND 
			modu_arr_rec_glsumdiv[i].desc_text IS NOT NULL THEN 
				LET modu_rec_glsumdiv.pos_code = modu_arr_rec_glsumdiv[i].col_num 
				LET modu_rec_glsumdiv.desc_text = modu_arr_rec_glsumdiv[i].desc_text 
				LET modu_rec_glsumdiv.div1_code = modu_arr_rec_glsumdiv[i].div1_code 
				LET modu_rec_glsumdiv.div2_code = modu_arr_rec_glsumdiv[i].div2_code 
				LET modu_rec_glsumdiv.div3_code = modu_arr_rec_glsumdiv[i].div3_code 
				LET modu_rec_glsumdiv.div4_code = modu_arr_rec_glsumdiv[i].div4_code 
				LET modu_rec_glsumdiv.div5_code = modu_arr_rec_glsumdiv[i].div5_code 
				LET modu_rec_glsumdiv.div6_code = modu_arr_rec_glsumdiv[i].div6_code 
				LET modu_rec_glsumdiv.div7_code = modu_arr_rec_glsumdiv[i].div7_code 
				LET modu_rec_glsumdiv.div8_code = modu_arr_rec_glsumdiv[i].div8_code 
				LET modu_rec_glsumdiv.div9_code = modu_arr_rec_glsumdiv[i].div9_code 
				INSERT INTO glsumdiv VALUES (modu_rec_glsumdiv.*) 
			END IF 
		END FOR 

	COMMIT WORK 

END FUNCTION