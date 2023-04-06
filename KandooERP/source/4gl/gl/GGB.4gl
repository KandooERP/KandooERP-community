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

	Source code beautified by beautify.pl on 2020-01-03 14:28:44	$Id: $
}



# GGB.4gl adds summarys AND blocks

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 


############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_glsummary RECORD LIKE glsummary.* 
	DEFINE modu_rec_glsumblock RECORD LIKE glsumblock.* 
	DEFINE modu_arr_rec_glsummary DYNAMIC ARRAY OF RECORD 
		summary_code LIKE glsummary.summary_code, 
		desc_text LIKE glsummary.desc_text, 
		print_order LIKE glsummary.print_order 
	END RECORD 
	DEFINE modu_arr_rec_glsumblock DYNAMIC ARRAY OF RECORD 
		block_code LIKE glsumblock.summary_code, 
		desc_text LIKE glsumblock.desc_text, 
		group_code LIKE glsumblock.group_code, 
		total_code LIKE glsumblock.total_code 
	END RECORD 
	--DEFINE modu_i SMALLINT
	--DEFINE modu_counter SMALLINT
	DEFINE modu_idx2 SMALLINT
	DEFINE modu_idx SMALLINT
	
	DEFINE modu_id_flag SMALLINT
	--DEFINE l_cnt SMALLINT
	DEFINE modu_err_flag SMALLINT		
	DEFINE modu_descrip_text CHAR(40) 
	DEFINE modu_domore CHAR(1) 
 

############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GGB") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	LET modu_domore = "Y" 
	WHILE modu_domore = "Y" 
		CALL doit() 
		CLOSE WINDOW wg210 
	END WHILE 
END MAIN 


############################################################
# FUNCTION db_glsummary_get_datasource()
#
#
############################################################
FUNCTION db_glsummary_get_datasource()

	DECLARE grp_curs CURSOR FOR 
	SELECT * INTO modu_rec_glsummary.* FROM glsummary 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY print_order 

	LET modu_idx = 0 
	FOREACH grp_curs 
		LET modu_idx = modu_idx + 1 
		LET modu_arr_rec_glsummary[modu_idx].summary_code = modu_rec_glsummary.summary_code 
		LET modu_arr_rec_glsummary[modu_idx].desc_text = modu_rec_glsummary.desc_text 
		LET modu_arr_rec_glsummary[modu_idx].print_order = modu_rec_glsummary.print_order 
	END FOREACH 
 
	RETURN modu_arr_rec_glsummary
END FUNCTION

############################################################
# FUNCTION doit()
#
#
############################################################
FUNCTION doit() 

	OPEN WINDOW wg210 with FORM "G210" 
	CALL windecoration_g("G210") 

	CALL db_glsummary_get_datasource() RETURNING modu_arr_rec_glsummary
	MESSAGE " F1 TO add, RETURN on line TO change, DEL TO EXIT" 

	INPUT ARRAY modu_arr_rec_glsummary WITHOUT DEFAULTS FROM sr_glsummary.* attributes(UNBUFFERED, INSERT ROW = FALSE) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GGB","inp-arr-glsummary") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET modu_idx = arr_curr() 
			#LET scrn = scr_line()
			LET modu_rec_glsummary.summary_code = modu_arr_rec_glsummary[modu_idx].summary_code 
			LET modu_rec_glsummary.desc_text = modu_arr_rec_glsummary[modu_idx].desc_text 
			LET modu_rec_glsummary.print_order = modu_arr_rec_glsummary[modu_idx].print_order 

		AFTER FIELD summary_code 
			IF modu_arr_rec_glsummary[modu_idx].summary_code IS NOT NULL 
			AND modu_rec_glsummary.print_order = 0 THEN 
				LET modu_arr_rec_glsummary[modu_idx].summary_code = NULL 
				#DISPLAY modu_arr_rec_glsummary[modu_idx].summary_code TO sr_glsummary[scrn].summary_code
			END IF 

		BEFORE FIELD desc_text 
			IF modu_rec_glsummary.summary_code IS NULL THEN 
				ERROR " Use F1 TO add a Summary " 
				NEXT FIELD summary_code 
			END IF 
			CALL changor() 

			IF int_flag != 0 
			OR quit_flag != 0 THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
			ELSE 
				LET modu_arr_rec_glsummary[modu_idx].summary_code = modu_rec_glsummary.summary_code 
				LET modu_arr_rec_glsummary[modu_idx].desc_text = modu_rec_glsummary.desc_text 
				LET modu_arr_rec_glsummary[modu_idx].print_order = modu_rec_glsummary.print_order 
				#DISPLAY modu_arr_rec_glsummary[modu_idx].* TO sr_glsummary[scrn].*
			END IF 
			NEXT FIELD summary_code 

		BEFORE INSERT 
			CALL addor() 
			IF int_flag != 0 
			OR quit_flag != 0 THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
				LET modu_arr_rec_glsummary[modu_idx].summary_code = NULL 
				LET modu_arr_rec_glsummary[modu_idx].desc_text = NULL 
				LET modu_arr_rec_glsummary[modu_idx].print_order = NULL 
			ELSE 
				LET modu_arr_rec_glsummary[modu_idx].summary_code = modu_rec_glsummary.summary_code 
				LET modu_arr_rec_glsummary[modu_idx].desc_text = modu_rec_glsummary.desc_text 
				LET modu_arr_rec_glsummary[modu_idx].print_order = modu_rec_glsummary.print_order 
				#DISPLAY modu_arr_rec_glsummary[modu_idx].* TO sr_glsummary[scrn].*
			END IF 
			NEXT FIELD summary_code 

		AFTER DELETE 
			IF modu_arr_rec_glsummary[modu_idx].summary_code IS NOT NULL THEN 
				--CALL gl_check_del(modu_idx)
				CALL GGB_gl_check_del(modu_arr_rec_glsummary[modu_idx].summary_code) 
				
			END IF 

		AFTER INPUT 
			IF int_flag != 0 
			OR quit_flag != 0 THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
				EXIT PROGRAM 
			END IF 

	END INPUT 
END FUNCTION 


############################################################
# FUNCTION addor()
#
#
############################################################
FUNCTION addor()
 DEFINE l_cnt SMALLINT
 
	OPEN WINDOW wg211 with FORM "G211" 
	CALL windecoration_g("G211") 

--	FOR modu_i = 1 TO 600 
--		INITIALIZE modu_arr_rec_glsumblock[modu_i].* TO NULL 
--	END FOR 

	LET modu_descrip_text = NULL 
	LET modu_rec_glsummary.summary_code = NULL 
	LET modu_rec_glsummary.desc_text = NULL 
	LET modu_rec_glsummary.print_order = NULL 

	INPUT 
		modu_rec_glsummary.summary_code, 
		modu_rec_glsummary.desc_text,
		modu_rec_glsummary.print_order WITHOUT DEFAULTS
	FROM
		glsummary.summary_code, 
		glsummary.desc_text,
		glsummary.print_order ATTRIBUTE(UNBUFFERED)
	 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GGB","inp-glsummary1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			LET l_cnt = 0 
			IF modu_rec_glsummary.summary_code IS NULL THEN 
				ERROR " Summary Code must NOT be NULL" 
				NEXT FIELD summary_code 
			END IF 
			SELECT count(*) INTO l_cnt FROM glsummary 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND summary_code = modu_rec_glsummary.summary_code 
			IF l_cnt > 0 THEN 
				ERROR " Summary Code already exists" 
				NEXT FIELD summary_code 
			END IF 

			LET l_cnt = 0 
			IF modu_rec_glsummary.print_order IS NULL THEN 
				ERROR " Print Order must NOT be NULL" 
				NEXT FIELD print_order 
			END IF 
			IF modu_rec_glsummary.print_order = 0 THEN 
				ERROR " Print Order must NOT be zero" 
				NEXT FIELD print_order 
			END IF 
			SELECT count(*) INTO l_cnt FROM glsummary 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND print_order = modu_rec_glsummary.print_order 
			IF l_cnt > 0 THEN 
				ERROR " Print Order already exists" 
				NEXT FIELD print_order 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW wg211 
		LET modu_descrip_text = NULL 
		LET modu_rec_glsummary.summary_code = NULL 
		LET modu_rec_glsummary.desc_text = NULL 
		LET modu_rec_glsummary.print_order = 0 
		RETURN 
	END IF 

	LET modu_rec_glsummary.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_glsummary.desc_text = modu_descrip_text 
	# print_order AND summary code have been SET up in the above INPUT statement

	INSERT INTO glsummary VALUES (modu_rec_glsummary.*) 

	MESSAGE " Enter Block Information, DEL TO EXIT" 

	INPUT ARRAY modu_arr_rec_glsumblock WITHOUT DEFAULTS FROM sr_glsumblock.* attributes(UNBUFFERED,INSERT ROW = FALSE, AUTO APPEND = FALSE) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GGB","inp-arr-glsumblock1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET modu_idx2 = arr_curr() 
			#LET scrn2 = scr_line()
			LET modu_rec_glsumblock.block_code = modu_arr_rec_glsumblock[modu_idx2].block_code 
			LET modu_rec_glsumblock.desc_text = modu_arr_rec_glsumblock[modu_idx2].desc_text 
			LET modu_rec_glsumblock.group_code = modu_arr_rec_glsumblock[modu_idx2].group_code 
			LET modu_rec_glsumblock.total_code = modu_arr_rec_glsumblock[modu_idx2].total_code 
			LET modu_id_flag = 0 

		BEFORE FIELD desc_text 
			SELECT count(*) INTO l_cnt FROM glsumblock 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND summary_code = modu_rec_glsumblock.summary_code 
			AND block_code = modu_arr_rec_glsumblock[modu_idx].block_code 
			IF l_cnt > 0 THEN 
				ERROR " Block Code already exists " 
				NEXT FIELD block_code 
			END IF 

		AFTER FIELD group_code 
			IF modu_arr_rec_glsumblock[modu_idx2].group_code IS NULL THEN 
				ERROR " Group account code must NOT be NULL" 
				NEXT FIELD group_code 
			END IF 

		AFTER FIELD total_code 
			IF modu_arr_rec_glsumblock[modu_idx2].total_code IS NULL THEN 
			ELSE 
				IF (modu_arr_rec_glsumblock[modu_idx2].total_code = "S" 
				OR modu_arr_rec_glsumblock[modu_idx2].total_code = "C" 
				OR modu_arr_rec_glsumblock[modu_idx2].total_code = "E" 
				OR modu_arr_rec_glsumblock[modu_idx2].total_code = "I") THEN 
				ELSE 
					ERROR " Invalid Total Code. Values must be (S, C, I, E OR NULL)" 
					NEXT FIELD total_code 
				END IF 
			END IF 


		BEFORE INSERT 
			INITIALIZE modu_rec_glsumblock.* TO NULL 

		AFTER INSERT 
			LET status = 0 
			LET modu_err_flag = 0 
			LET modu_id_flag = -1 
			LET modu_rec_glsumblock.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF modu_arr_rec_glsumblock[modu_idx2].block_code IS NOT NULL THEN 
				WHENEVER ERROR CONTINUE 
				LET modu_rec_glsumblock.summary_code = modu_rec_glsummary.summary_code 
				LET modu_rec_glsumblock.block_code = modu_arr_rec_glsumblock[modu_idx2].block_code 
				LET modu_rec_glsumblock.desc_text = modu_arr_rec_glsumblock[modu_idx2].desc_text 
				LET modu_rec_glsumblock.group_code = modu_arr_rec_glsumblock[modu_idx2].group_code 
				LET modu_rec_glsumblock.total_code = modu_arr_rec_glsumblock[modu_idx2].total_code 
				INSERT INTO glsumblock VALUES (modu_rec_glsumblock.*) 
				IF (status < 0) THEN 
					LET modu_err_flag = -1 
				END IF 
				WHENEVER ERROR stop 
			ELSE 
				LET modu_err_flag = -1 
			END IF 
			IF (modu_err_flag < 0) THEN 
				ERROR "Block INSERT has failed - enter information again" 
				#CLEAR sr_glsumblock[scrn2].*
				LET modu_err_flag = 0 
			END IF 

		AFTER DELETE 
			LET modu_id_flag = -1 
			DELETE FROM glsumblock 
			WHERE desc_text = modu_rec_glsumblock.desc_text 
			AND summary_code = modu_rec_glsumblock.summary_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		AFTER ROW 
			IF (modu_arr_rec_glsumblock[modu_idx2].block_code IS NULL 
			AND modu_arr_rec_glsumblock[modu_idx2].group_code IS null) THEN 
				LET modu_id_flag = -1 
			END IF 

			IF (modu_id_flag = 0 
			AND (modu_rec_glsumblock.block_code != modu_arr_rec_glsumblock[modu_idx2].block_code 
			OR modu_rec_glsumblock.desc_text != modu_arr_rec_glsumblock[modu_idx2].desc_text 
			OR modu_rec_glsumblock.group_code != modu_arr_rec_glsumblock[modu_idx2].group_code 
			OR modu_rec_glsumblock.total_code != modu_arr_rec_glsumblock[modu_idx2].total_code 
			OR (modu_rec_glsumblock.total_code IS NULL 
			AND modu_arr_rec_glsumblock[modu_idx2].total_code IS NOT null) 
			OR (modu_rec_glsumblock.total_code IS NOT NULL 
			AND modu_arr_rec_glsumblock[modu_idx2].total_code IS null))) THEN 
				UPDATE glsumblock 
				SET glsumblock.block_code = modu_arr_rec_glsumblock[modu_idx2].block_code, 
				glsumblock.desc_text = modu_arr_rec_glsumblock[modu_idx2].desc_text, 
				glsumblock.group_code = modu_arr_rec_glsumblock[modu_idx2].group_code, 
				glsumblock.total_code = modu_arr_rec_glsumblock[modu_idx2].total_code 
				WHERE desc_text = modu_rec_glsumblock.desc_text 
				AND summary_code = modu_rec_glsumblock.summary_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

			IF (modu_id_flag = 0 
			AND (modu_arr_rec_glsumblock[modu_idx2].block_code IS NOT NULL 
			AND modu_rec_glsumblock.block_code IS null)) THEN 
				WHENEVER ERROR CONTINUE 
				LET modu_rec_glsumblock.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_rec_glsumblock.summary_code = modu_rec_glsummary.summary_code 
				LET modu_rec_glsumblock.block_code = modu_arr_rec_glsumblock[modu_idx2].block_code 
				LET modu_rec_glsumblock.desc_text = modu_arr_rec_glsumblock[modu_idx2].desc_text 
				LET modu_rec_glsumblock.group_code = modu_arr_rec_glsumblock[modu_idx2].group_code 
				LET modu_rec_glsumblock.total_code = modu_arr_rec_glsumblock[modu_idx2].total_code 
				INSERT INTO glsumblock VALUES (modu_rec_glsumblock.*) 
				IF (status < 0) THEN 
					ERROR "Block INSERT has failed - enter information again." 
					INITIALIZE modu_arr_rec_glsumblock[modu_idx2].* TO NULL 
					#CLEAR sr_glsumblock[scrn2].*
				END IF 
				WHENEVER ERROR stop 
			END IF 

	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

	CLOSE WINDOW wg211 

END FUNCTION 


############################################################
# FUNCTION changor()
#
#
############################################################
FUNCTION changor() 
	DEFINE l_save_id LIKE glsummary.print_order 
	DEFINE l_cnt SMALLINT

	DECLARE blk2 CURSOR FOR 
	SELECT * INTO modu_rec_glsumblock.* FROM glsumblock 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND summary_code = modu_rec_glsummary.summary_code 

	LET modu_idx2 = 0 
	FOREACH blk2 
		LET modu_idx2 = modu_idx2 + 1 
		LET modu_arr_rec_glsumblock[modu_idx2].block_code = modu_rec_glsumblock.block_code 
		LET modu_arr_rec_glsumblock[modu_idx2].desc_text = modu_rec_glsumblock.desc_text 
		LET modu_arr_rec_glsumblock[modu_idx2].group_code = modu_rec_glsumblock.group_code 
		LET modu_arr_rec_glsumblock[modu_idx2].total_code = modu_rec_glsumblock.total_code 
	END FOREACH 
	CALL set_count(modu_idx2) 

	OPEN WINDOW wg211 with FORM "G211" 
	CALL windecoration_g("G211") 

	LET l_save_id = modu_rec_glsummary.print_order 
	LET modu_descrip_text = modu_rec_glsummary.desc_text 

	DISPLAY modu_rec_glsummary.summary_code, modu_rec_glsummary.desc_text 
	TO summary_code, modu_descrip_text 

	INPUT BY NAME modu_descrip_text,	modu_rec_glsummary.print_order WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GGB","inp-glsummary2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			LET modu_rec_glsummary.desc_text = modu_descrip_text 

			IF modu_rec_glsummary.print_order IS NULL THEN 
				ERROR " Print Order must NOT be NULL" 
				LET modu_rec_glsummary.print_order = l_save_id 
				DISPLAY modu_rec_glsummary.print_order TO print_order 
				NEXT FIELD print_order 
			END IF 

			IF modu_rec_glsummary.print_order = 0 THEN 
				ERROR " Print Order must NOT be zero" 
				LET modu_rec_glsummary.print_order = l_save_id 
				DISPLAY modu_rec_glsummary.print_order TO print_order 
				NEXT FIELD print_order 
			END IF 

			IF l_save_id != modu_rec_glsummary.print_order THEN 
				LET l_cnt = 0 
				SELECT count(*) INTO l_cnt FROM glsummary 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND print_order = modu_rec_glsummary.print_order 
				IF l_cnt > 0 THEN 
					ERROR " Print Order already exists" 
					LET modu_rec_glsummary.print_order = l_save_id 
					DISPLAY modu_rec_glsummary.print_order TO print_order 
					NEXT FIELD print_order 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW wg211 
		RETURN 
	END IF 

	UPDATE glsummary 
	SET desc_text = modu_descrip_text, 
	print_order = modu_rec_glsummary.print_order 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND summary_code = modu_rec_glsummary.summary_code 

	MESSAGE " F1 TO add, RETURN on line TO change, F2 TO delete, DEL TO EXIT" 


	INPUT ARRAY modu_arr_rec_glsumblock WITHOUT DEFAULTS FROM sr_glsumblock.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GGB","inp-arr-glsumblock2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET modu_idx2 = arr_curr() 
			#LET scrn2 = scr_line()
			LET modu_rec_glsumblock.block_code = modu_arr_rec_glsumblock[modu_idx2].block_code 
			LET modu_rec_glsumblock.desc_text = modu_arr_rec_glsumblock[modu_idx2].desc_text 
			LET modu_rec_glsumblock.group_code = modu_arr_rec_glsumblock[modu_idx2].group_code 
			LET modu_rec_glsumblock.total_code = modu_arr_rec_glsumblock[modu_idx2].total_code 
			LET modu_id_flag = 0 

		AFTER FIELD group_code 
			IF modu_arr_rec_glsumblock[modu_idx2].group_code IS NULL THEN 
				ERROR " Group account code must NOT be NULL" 
				NEXT FIELD group_code 
			END IF 

		AFTER FIELD total_code 
			IF modu_arr_rec_glsumblock[modu_idx2].total_code IS NULL THEN 
			ELSE 
				IF (modu_arr_rec_glsumblock[modu_idx2].total_code = "S" 
				OR modu_arr_rec_glsumblock[modu_idx2].total_code = "C" 
				OR modu_arr_rec_glsumblock[modu_idx2].total_code = "E" 
				OR modu_arr_rec_glsumblock[modu_idx2].total_code = "I") THEN 
				ELSE 
					ERROR " Invalid Total Code. Values must be (S, C, I, E OR NULL)" 
					NEXT FIELD total_code 
				END IF 
			END IF 


		BEFORE INSERT 
			INITIALIZE modu_rec_glsumblock.* TO NULL 

		AFTER INSERT 
			LET status = 0 
			LET modu_err_flag = 0 
			LET modu_id_flag = -1 
			LET modu_rec_glsumblock.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF modu_arr_rec_glsumblock[modu_idx2].block_code IS NOT NULL THEN 
				WHENEVER ERROR CONTINUE 
				LET modu_rec_glsumblock.summary_code = modu_rec_glsummary.summary_code 
				LET modu_rec_glsumblock.block_code = modu_arr_rec_glsumblock[modu_idx2].block_code 
				LET modu_rec_glsumblock.desc_text = modu_arr_rec_glsumblock[modu_idx2].desc_text 
				LET modu_rec_glsumblock.group_code = modu_arr_rec_glsumblock[modu_idx2].group_code 
				LET modu_rec_glsumblock.total_code = modu_arr_rec_glsumblock[modu_idx2].total_code 
				INSERT INTO glsumblock VALUES (modu_rec_glsumblock.*) 
				IF (status < 0) THEN 
					LET modu_err_flag = -1 
				END IF 
				WHENEVER ERROR stop 
			ELSE 
				LET modu_err_flag = -1 
			END IF 
			IF (modu_err_flag < 0) THEN 
				ERROR "Block INSERT has failed - enter information again" 
				#CLEAR sr_glsumblock[scrn2].*
				LET modu_err_flag = 0 
			END IF 

		AFTER DELETE 
			LET modu_id_flag = -1 
			DELETE FROM glsumblock 
			WHERE desc_text = modu_rec_glsumblock.desc_text 
			AND summary_code = modu_rec_glsumblock.summary_code 
			AND block_code = modu_rec_glsumblock.block_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		AFTER ROW 
			IF (modu_arr_rec_glsumblock[modu_idx2].block_code IS NULL 
			AND modu_arr_rec_glsumblock[modu_idx2].group_code IS null) THEN 
				LET modu_id_flag = -1 
			END IF 

			IF (modu_id_flag = 0 
			AND (modu_rec_glsumblock.block_code != modu_arr_rec_glsumblock[modu_idx2].block_code 
			OR modu_rec_glsumblock.desc_text != modu_arr_rec_glsumblock[modu_idx2].desc_text 
			OR modu_rec_glsumblock.group_code != modu_arr_rec_glsumblock[modu_idx2].group_code 
			OR modu_rec_glsumblock.total_code != modu_arr_rec_glsumblock[modu_idx2].total_code 
			OR (modu_rec_glsumblock.total_code IS NULL 
			AND modu_arr_rec_glsumblock[modu_idx2].total_code IS NOT null) 
			OR (modu_rec_glsumblock.total_code IS NOT NULL 
			AND modu_arr_rec_glsumblock[modu_idx2].total_code IS null))) THEN 
				UPDATE glsumblock 
				SET glsumblock.block_code = modu_arr_rec_glsumblock[modu_idx2].block_code, 
				glsumblock.desc_text = modu_arr_rec_glsumblock[modu_idx2].desc_text, 
				glsumblock.group_code = modu_arr_rec_glsumblock[modu_idx2].group_code, 
				glsumblock.total_code = modu_arr_rec_glsumblock[modu_idx2].total_code 
				WHERE desc_text = modu_rec_glsumblock.desc_text 
				AND summary_code = modu_rec_glsumblock.summary_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

			IF (modu_id_flag = 0 
			AND (modu_arr_rec_glsumblock[modu_idx2].block_code IS NOT NULL 
			AND modu_rec_glsumblock.block_code IS null)) THEN 
				WHENEVER ERROR CONTINUE 
				LET modu_rec_glsumblock.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_rec_glsumblock.summary_code = modu_rec_glsummary.summary_code 
				LET modu_rec_glsumblock.block_code = modu_arr_rec_glsumblock[modu_idx2].block_code 
				LET modu_rec_glsumblock.desc_text = modu_arr_rec_glsumblock[modu_idx2].desc_text 
				LET modu_rec_glsumblock.group_code = modu_arr_rec_glsumblock[modu_idx2].group_code 
				LET modu_rec_glsumblock.total_code = modu_arr_rec_glsumblock[modu_idx2].total_code 
				INSERT INTO glsumblock VALUES (modu_rec_glsumblock.*) 
				IF (status < 0) THEN 
					ERROR "Block INSERT has failed - enter information again." 
					INITIALIZE modu_arr_rec_glsumblock[modu_idx2].* TO NULL 
					#CLEAR sr_glsumblock[scrn2].*
				END IF 
				WHENEVER ERROR stop 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW wg211 
END FUNCTION 


############################################################
# FUNCTION GGB_gl_check_del(p_summary_code) 
#
#
############################################################
FUNCTION GGB_gl_check_del(p_summary_code) 
	DEFINE p_summary_code LIKE glsummary.summary_code
	DEFINE l_answer CHAR(1) 
	DEFINE l_cnt SMALLINT 

	LET l_answer = "n" 
	LET l_cnt = 0 
	SELECT count(*) INTO l_cnt FROM glsumblock 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND summary_code = p_summary_code
	 
	IF l_cnt > 0 THEN 

		LET l_answer = promptYN("Blocks still exist"," Blocks still exist!\nDo you wish TO delete (y/n)? ","Y") 

		IF l_answer = "n" THEN 
			#DISPLAY modu_arr_rec_glsummary[modu_idx].* TO sr_glsummary[scrn].*
			RETURN 
		END IF
		 
		DELETE FROM glsumblock 
		WHERE glsumblock.summary_code = p_summary_code
		AND cmpy_code = glob_rec_kandoouser.cmpy_code
		 
	END IF 
	
	DELETE FROM glsummary 
	WHERE glsummary.summary_code = p_summary_code
	AND cmpy_code = glob_rec_kandoouser.cmpy_code
	 
END FUNCTION