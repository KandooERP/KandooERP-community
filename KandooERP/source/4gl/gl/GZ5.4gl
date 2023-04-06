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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "GZ5_GLOBALS.4gl" 
{
GLOBALS
	DEFINE glob_rec_reporthead RECORD LIKE reporthead.*
	DEFINE glob_arr_rec_reporthead DYNAMIC ARRAY OF t_rec_reporthead_rc_dt_cn_ph
#	DEFINE glob_arr_rec_reporthead array[500] OF
#		RECORD
#	   report_code LIKE reporthead.report_code,
#	   desc_text LIKE reporthead.desc_text,
#	   column_num LIKE reporthead.column_num,
#	   page_head_flag LIKE reporthead.page_head_flag
#		END RECORD
	DEFINE glob_id_flag SMALLINT
	DEFINE glob_cnt  SMALLINT
#DEFINE err_flag  SMALLINT not used
#DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* not used

END GLOBALS

}
############################################################
# MAIN
#
# Report Header Maintenance
############################################################
MAIN 

	CALL setModuleId("GZ5") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL fgl_winmessage("Refer to GW", "This option has been superceded by the GW - Report Writer Sub-system, and will no longer be enhanced.\n@Eric @Anna?\nI assume we can take it out of the menu. Please aggree/make a decission and take actions..\nBut please check it out if it is true before making a decission","info") 

	OPTIONS DELETE KEY f36 
	#   LET doit = "Y"
	#   WHILE doit = "Y"
	CALL get_info() 
	#      CLOSE WINDOW wG118
	#   END WHILE
END MAIN 




############################################################
# FUNCTION get_info()
#
#
############################################################
FUNCTION get_info() 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_ans LIKE language.yes_flag 

	DECLARE c_fin CURSOR FOR 
	SELECT * 
	INTO glob_rec_reporthead.* 
	FROM reporthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY report_code 

	LET l_idx = 0 
	FOREACH c_fin 
		LET l_idx = l_idx + 1 
		LET glob_arr_rec_reporthead[l_idx].report_code = glob_rec_reporthead.report_code 
		LET glob_arr_rec_reporthead[l_idx].desc_text = glob_rec_reporthead.desc_text 
		LET glob_arr_rec_reporthead[l_idx].column_num = glob_rec_reporthead.column_num 
		LET glob_arr_rec_reporthead[l_idx].page_head_flag = glob_rec_reporthead.page_head_flag 

		#      IF l_idx > 400 THEN
		#         LET l_msgresp = kandoomsg("U",6100,l_idx)
		#         #6100 First l_idx records selected
		#         EXIT FOREACH
		#         END IF
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected


	OPEN WINDOW wg118 with FORM "G118" 
	CALL windecoration_g("G118") --populate WINDOW FORM elements 

	LET l_msgresp = kandoomsg("G",1066,"") 

	#1066 F1 TO Add; F2 TO Delete; F10 FOR Report Instructions;
	#      CALL set_count(l_idx)
	INPUT ARRAY glob_arr_rec_reporthead WITHOUT DEFAULTS FROM sr_reporthead.* attributes(UNBUFFERED, append ROW = false, auto append = false) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ5","reportDescInpArr") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET glob_rec_reporthead.report_code = glob_arr_rec_reporthead[l_idx].report_code 
			LET glob_rec_reporthead.desc_text = glob_arr_rec_reporthead[l_idx].desc_text 
			LET glob_rec_reporthead.column_num = glob_arr_rec_reporthead[l_idx].column_num 
			LET glob_rec_reporthead.page_head_flag = glob_arr_rec_reporthead[l_idx].page_head_flag 
			LET glob_id_flag = 0 

		ON KEY (F10) 
			IF glob_rec_reporthead.report_code IS NOT NULL THEN 
				OPTIONS DELETE KEY f2 
				CALL fin_inst( glob_rec_kandoouser.cmpy_code, glob_rec_reporthead.report_code) 
				OPTIONS DELETE KEY f36 
			END IF 

		AFTER FIELD report_code 
			IF (glob_arr_rec_reporthead[l_idx].report_code IS null) THEN 
				IF (glob_arr_rec_reporthead[l_idx].desc_text IS NOT null) THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD report_code 
				END IF 
			ELSE 
				IF (glob_arr_rec_reporthead[l_idx].report_code != glob_rec_reporthead.report_code 
				OR glob_arr_rec_reporthead[l_idx].desc_text != glob_rec_reporthead.desc_text 
				OR glob_arr_rec_reporthead[l_idx].column_num != glob_rec_reporthead.column_num 
				OR glob_arr_rec_reporthead[l_idx].page_head_flag IS null) THEN 
					SELECT count(*) INTO glob_cnt FROM reporthead 
					WHERE report_code = glob_arr_rec_reporthead[l_idx].report_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (glob_cnt != 0) THEN 
						LET l_msgresp = kandoomsg("U",9104,"") 
						#9104 This RECORD already exists
						NEXT FIELD report_code 
					END IF 
				END IF 
			END IF 

		AFTER FIELD desc_text 
			NEXT FIELD column_num 

		AFTER FIELD column_num 
			IF glob_arr_rec_reporthead[l_idx].column_num IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD column_num 
			ELSE 
				IF glob_arr_rec_reporthead[l_idx].column_num > 6 THEN 
					LET l_ans = col_check(l_idx) 
					IF l_ans != "Y" THEN 
						NEXT FIELD column_num 
					END IF 
				END IF 
			END IF 
			NEXT FIELD page_head_flag 

		BEFORE INSERT 
			INITIALIZE glob_rec_reporthead.* TO NULL 

		AFTER INSERT 
			IF (glob_arr_rec_reporthead[l_idx].report_code IS NOT null) THEN 
				INSERT INTO reporthead VALUES (glob_rec_kandoouser.cmpy_code, glob_arr_rec_reporthead[l_idx].report_code, 
				glob_arr_rec_reporthead[l_idx].desc_text, 
				glob_arr_rec_reporthead[l_idx].column_num, 
				glob_arr_rec_reporthead[l_idx].page_head_flag) 
			END IF 

		ON KEY (F2) #toggle DELETE status OF a ROW ? 
			CALL delete_off() 

		AFTER ROW 

			IF (glob_arr_rec_reporthead[l_idx].report_code IS null) THEN 
				LET glob_id_flag = -1 
			END IF 

			IF (glob_id_flag = 0 
			AND (glob_rec_reporthead.report_code != glob_arr_rec_reporthead[l_idx].report_code) 
			OR glob_rec_reporthead.desc_text != glob_arr_rec_reporthead[l_idx].desc_text 
			OR glob_rec_reporthead.column_num != glob_arr_rec_reporthead[l_idx].column_num 
			OR glob_rec_reporthead.page_head_flag != glob_arr_rec_reporthead[l_idx].page_head_flag) THEN 
				UPDATE reporthead SET 
				desc_text = glob_arr_rec_reporthead[l_idx].desc_text, 
				column_num = glob_arr_rec_reporthead[l_idx].column_num, 
				page_head_flag = glob_arr_rec_reporthead[l_idx].page_head_flag 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND report_code = glob_rec_reporthead.report_code 
			END IF 

	END INPUT 

END FUNCTION 



############################################################
# FUNCTION col_check()
#
#
############################################################
FUNCTION col_check(p_idx) 
	DEFINE p_idx SMALLINT 
	DEFINE l_col_width DECIMAL(5,0) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_col_width = glob_arr_rec_reporthead[p_idx].column_num * 20 
	LET l_msgresp = kandoomsg("G",8007,l_col_width) 
	#8007 "Column width ", l_col_width, " cols OK, (y/n) ?"
	RETURN(l_msgresp) 
END FUNCTION 


############################################################
# FUNCTION delete_off()
#
#
############################################################
FUNCTION delete_off() 
	DEFINE l_idx SMALLINT 
	DEFINE i INTEGER 
	DEFINE j INTEGER 
	DEFINE l_arr_length INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("G",8008,"") 
	#8008 Confirm TO Delete Report?
	IF l_msgresp = "Y" THEN 
		DELETE FROM reporthead WHERE 
		cmpy_code = glob_rec_kandoouser.cmpy_code AND 
		report_code = glob_rec_reporthead.report_code 
		DELETE FROM reportdetl WHERE 
		cmpy_code = glob_rec_kandoouser.cmpy_code AND 
		report_code = glob_rec_reporthead.report_code 
		LET l_arr_length = arr_count() 
		IF l_idx < l_arr_length THEN 
			FOR i = l_idx TO l_arr_length 
				LET glob_arr_rec_reporthead[i].* = glob_arr_rec_reporthead[i + 1].* 
			END FOR 
		ELSE 
			INITIALIZE glob_arr_rec_reporthead[l_idx].* TO NULL 
		END IF 
		CALL set_count(l_arr_length - 1) 
		LET i = l_idx 
		#FOR j = scrn TO 10
		#   IF i <= l_arr_length THEN
		#      DISPLAY glob_arr_rec_reporthead[i].* TO sr_reporthead[j].*
		#
		#      LET i = i + 1
		#   END IF
		#END FOR
		LET l_idx = arr_curr() 
		#LET scrn = scr_line()
		LET glob_rec_reporthead.report_code = glob_arr_rec_reporthead[l_idx].report_code 
		LET glob_rec_reporthead.desc_text = glob_arr_rec_reporthead[l_idx].desc_text 
		LET glob_rec_reporthead.column_num = glob_arr_rec_reporthead[l_idx].column_num 
		LET glob_rec_reporthead.page_head_flag = glob_arr_rec_reporthead[l_idx].page_head_flag 
		LET glob_id_flag = 0 
	END IF 

END FUNCTION 
