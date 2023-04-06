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

#   GZT - Bank Types

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

####################################################################################
# MAIN
#
#
####################################################################################
MAIN 
	DEFINE l_filter SMALLINT 
	CALL setModuleId("GZT") 
	CALL ui_init(0) #initial ui init 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	OPEN WINDOW g532 WITH FORM "G532" 
	CALL windecoration_g("G532") 

	LET l_filter = filter_query_off 
	WHILE int_flag = FALSE 
		CALL select_banktype(l_filter) 
		CALL scan_banktype() 
	END WHILE 

	CLOSE WINDOW G532 
END MAIN 
####################################################################################
# END MAIN
####################################################################################


####################################################################################
# FUNCTION select_banktype()
#
#
####################################################################################
FUNCTION select_banktype(p_filter) 
	DEFINE p_filter SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE r_ret BOOLEAN

	IF p_filter = filter_query_on THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("G",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON type_code,type_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GZT","bankTypeQuery1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag = 1 OR quit_flag = 1 THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 " 
			LET r_ret = FALSE 
		ELSE 
			LET r_ret = TRUE 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
		LET r_ret = FALSE 
	END IF 

	LET l_msgresp = kandoomsg("G",1002,"")#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM banktype ", 
		"WHERE ", l_where_text CLIPPED," ", 
		"ORDER BY banktype.type_code" 
	PREPARE s_banktype FROM l_query_text 
	DECLARE c_banktype CURSOR FOR s_banktype 

	RETURN r_ret 
END FUNCTION 
####################################################################################
# END FUNCTION select_banktype()
####################################################################################


####################################################################################
# FUNCTION db_banktype_data_source()
#
#
####################################################################################
FUNCTION db_banktype_data_source() 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_arr_rec_banktype DYNAMIC ARRAY OF 
	RECORD 
		type_code LIKE banktype.type_code, 
		type_text LIKE banktype.type_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_idx = 0 
	FOREACH c_banktype INTO l_rec_banktype.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_banktype[l_idx].type_code = l_rec_banktype.type_code 
		LET l_arr_rec_banktype[l_idx].type_text = l_rec_banktype.type_text 
	END FOREACH 

	RETURN l_arr_rec_banktype 
END FUNCTION 
####################################################################################
# END FUNCTION db_banktype_data_source()
####################################################################################


####################################################################################
# FUNCTION scan_banktype()
#
#
####################################################################################
FUNCTION scan_banktype() 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_arr_rec_banktype DYNAMIC ARRAY OF 
	RECORD 
		type_code LIKE banktype.type_code, 
		type_text LIKE banktype.type_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt INTEGER
	DEFINE l_msgresp LIKE language.yes_flag 
   DEFINE l_msgtext STRING	

	CALL db_banktype_data_source() RETURNING l_arr_rec_banktype 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	LET l_msgresp = kandoomsg("G",1003,"")#" F1 TO Add,F2 TO Delete,RETURN on line TO Edit
	DISPLAY ARRAY l_arr_rec_banktype TO sr_banktype.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","GZT","bankTypeList") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION ("DOUBLECLICK","EDIT")
			LET l_idx = arr_curr()
			IF l_arr_rec_banktype[l_idx].type_code IS NOT NULL THEN 
				IF edit_banktype(l_arr_rec_banktype[l_idx].type_code) THEN 
				   CALL db_banktype_data_source() RETURNING l_arr_rec_banktype
				END IF 
			END IF 

		ON ACTION "FILTER" 
			IF select_banktype(filter_query_on) THEN 
				CALL db_banktype_data_source() RETURNING l_arr_rec_banktype 
			END IF 

		ON ACTION "ADD" 
         IF add_banktype() THEN 
		      CALL db_banktype_data_source() RETURNING l_arr_rec_banktype
         END IF

		ON ACTION ("DELETE") 
			LET l_idx = arr_curr()
			IF l_arr_rec_banktype.getlength() > 0 THEN 
            SELECT COUNT(*) INTO l_cnt FROM banktypedetl
            WHERE type_code = l_arr_rec_banktype[l_idx].type_code
            IF l_cnt > 0
            THEN LET l_msgtext = "This Bank Type has associated Account Transaction Codes.\nConfirmation to delete Bank Type?"
            ELSE LET l_msgtext = "Confirmation to delete Bank Type?"
            END IF
            IF promptTF("",l_msgtext,0) THEN
               BEGIN WORK
					   DELETE FROM banktypedetl 
					   WHERE type_code = l_arr_rec_banktype[l_idx].type_code
					   DELETE FROM banktype 
					   WHERE type_code = l_arr_rec_banktype[l_idx].type_code 
               COMMIT WORK
				   CALL db_banktype_data_source() RETURNING l_arr_rec_banktype
            END IF
			END IF 

	END DISPLAY 

END FUNCTION 
####################################################################################
# END FUNCTION scan_banktype()
####################################################################################


####################################################################################
# FUNCTION edit_banktype(p_type_code)
#
#
####################################################################################
FUNCTION edit_banktype(p_type_code) 
	DEFINE p_type_code LIKE banktype.type_code 

	DEFINE l_rec_s_banktype RECORD LIKE banktype.* 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_banktype.* FROM banktype 
	WHERE type_code = p_type_code 

	OPEN WINDOW g533 WITH FORM "G533" 
	CALL windecoration_g("G533") 

	LET l_rec_s_banktype.* = l_rec_banktype.* 
	LET l_msgresp = kandoomsg("G",1055,"") 
	#1055 " Enter Bank Type Details - F10 FOR transaction codes
	DISPLAY BY NAME l_rec_banktype.type_code 

	INPUT BY NAME l_rec_banktype.type_text, 
	              l_rec_banktype.eft_format_ind, 
	              l_rec_banktype.eft_path_text, 
	              l_rec_banktype.eft_file_text, 
	              l_rec_banktype.stmt_format_ind, 
	              l_rec_banktype.stmt_path_text, 
	              l_rec_banktype.stmt_file_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZT","bankTypeEdit") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F10) 
			CALL add_banktypedetl(l_rec_banktype.type_code) 

		AFTER FIELD type_text 
			IF l_rec_banktype.type_text IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9161,"")			#9161 " Bank Type Description must NOT be NULL
				NEXT FIELD type_text 
			END IF 

		AFTER FIELD eft_format_ind 
			IF l_rec_banktype.eft_format_ind IS NOT NULL THEN 
				IF l_rec_banktype.eft_format_ind != 1 
				AND l_rec_banktype.eft_format_ind != 5 THEN 
					LET l_msgresp = kandoomsg("G",9198,"") 
					#9198 " Bank has NOT been linked TO this indicator
					NEXT FIELD eft_format_ind 
				END IF 
			END IF 
			IF l_rec_banktype.eft_format_ind = 5 THEN 
				IF l_rec_banktype.eft_file_text IS NULL THEN 
					LET l_rec_banktype.eft_file_text = "NAB.AB" 
               DISPLAY BY NAME l_rec_banktype.eft_file_text
				END IF 
			END IF 

		AFTER FIELD eft_file_text 
			IF l_rec_banktype.eft_format_ind IS NOT NULL 
			OR l_rec_banktype.eft_path_text IS NOT NULL 
			OR l_rec_banktype.eft_file_text IS NOT NULL THEN 
				IF l_rec_banktype.eft_format_ind IS NULL 
				OR l_rec_banktype.eft_path_text IS NULL 
				OR l_rec_banktype.eft_file_text IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9162,"") 
					#9162 " All OR No EFT Details must be entered
					NEXT FIELD eft_format_ind 
				END IF 
			END IF 

		AFTER FIELD stmt_file_text 
			IF l_rec_banktype.stmt_format_ind IS NOT NULL 
			OR l_rec_banktype.stmt_path_text IS NOT NULL 
			OR l_rec_banktype.stmt_file_text IS NOT NULL THEN
				IF l_rec_banktype.stmt_format_ind IS NULL 
				OR l_rec_banktype.stmt_path_text IS NULL 
			   OR l_rec_banktype.stmt_file_text IS NULL THEN
					LET l_msgresp = kandoomsg("G",9163,"") 
					#9163 " All OR No Statement Load Details must be entered
					NEXT FIELD stmt_format_ind 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag = 0 AND quit_flag = 0 THEN 
            # "Apply" action activated.
				IF l_rec_banktype.type_code IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9164,"") 				#9164 " Bank Type must NOT be NULL
					NEXT FIELD type_code 
				END IF 

				IF l_rec_banktype.type_text IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9161,"") 				#9161 " Bank Type Description must NOT be NULL
					NEXT FIELD type_text 
				END IF 

				IF l_rec_banktype.eft_format_ind IS NOT NULL 
				OR l_rec_banktype.eft_path_text IS NOT NULL 
				OR l_rec_banktype.eft_file_text IS NOT NULL THEN 
					IF l_rec_banktype.eft_format_ind IS NULL 
					OR l_rec_banktype.eft_path_text IS NULL 
					OR l_rec_banktype.eft_file_text IS NULL THEN 
						LET l_msgresp = kandoomsg("G",9162,"")						#9162 " All OR No EFT Details must be entered
						NEXT FIELD eft_format_ind 
					END IF 
				END IF 

				IF l_rec_banktype.stmt_format_ind IS NOT NULL 
				OR l_rec_banktype.stmt_path_text IS NOT NULL 
				OR l_rec_banktype.stmt_file_text IS NOT NULL THEN
					IF l_rec_banktype.stmt_format_ind IS NULL 
					OR l_rec_banktype.stmt_path_text IS NULL 
			   	OR l_rec_banktype.stmt_file_text IS NULL THEN
						LET l_msgresp = kandoomsg("G",9163,"")						#9163 " All OR No Statement Load Details must be entered
						NEXT FIELD stmt_format_ind 
					END IF 
				END IF
         END IF

	END INPUT 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		CLOSE WINDOW g533 
		RETURN FALSE 
	END IF 

	UPDATE banktype SET banktype.* = l_rec_banktype.* 
	WHERE type_code = l_rec_banktype.type_code 

	CLOSE WINDOW G533 

	RETURN SQLCA.SQLERRD[3] 
END FUNCTION 
####################################################################################
# END FUNCTION edit_banktype(p_type_code)
####################################################################################


####################################################################################
# FUNCTION add_banktype()
#
#
####################################################################################
FUNCTION add_banktype() 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_cnt INTEGER 
	DEFINE l_msgtext STRING

	OPEN WINDOW g533 WITH FORM "G533" 
	CALL windecoration_g("G533") 

	INITIALIZE l_rec_banktype.* TO NULL 
	LET l_msgresp = kandoomsg("G",1502,"")	#1502 " Enter Bank Type Details
	INPUT BY NAME l_rec_banktype.type_code, 
	              l_rec_banktype.type_text, 
	              l_rec_banktype.eft_format_ind, 
	              l_rec_banktype.eft_path_text, 
	              l_rec_banktype.eft_file_text, 
	              l_rec_banktype.stmt_format_ind, 
	              l_rec_banktype.stmt_path_text, 
	              l_rec_banktype.stmt_file_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZT","bankTypeNew") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F10) 
         SELECT COUNT(*) INTO l_cnt FROM banktype
         WHERE type_code = l_rec_banktype.type_code
         IF l_cnt = 0 THEN 
            LET l_msgtext = "Before entering Account Transaction Codes please save the data."
            CALL msgerror("",l_msgtext)
            CONTINUE INPUT
         END IF
			CALL add_banktypedetl(l_rec_banktype.type_code)

		AFTER FIELD type_code 
			IF l_rec_banktype.type_code IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9164,"")#9164 " Bank Type must NOT be NULL
				NEXT FIELD type_code 
			END IF 

			SELECT COUNT(*) INTO l_cnt FROM banktype 
			WHERE type_code = l_rec_banktype.type_code 
			IF l_cnt <> 0 THEN 
				LET l_msgresp = kandoomsg("G",9165,"")	#9165 " Bank Type already exists
				NEXT FIELD type_code 
			END IF 

		AFTER FIELD type_text 
			IF l_rec_banktype.type_text IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9161,"")	#9161 " Bank Type Description must NOT be NULL
				NEXT FIELD type_text 
			END IF 

		AFTER FIELD eft_format_ind 
			IF l_rec_banktype.eft_format_ind IS NOT NULL THEN 
				IF l_rec_banktype.eft_format_ind != 1 
				AND l_rec_banktype.eft_format_ind != 5 THEN 
					LET l_msgresp = kandoomsg("G",9198,"")			#9198 " Bank has NOT been linked TO this indicator
					NEXT FIELD eft_format_ind 
				END IF 
			END IF 
			
			IF l_rec_banktype.eft_format_ind = 5 THEN 
				IF l_rec_banktype.eft_file_text IS NULL THEN 
					LET l_rec_banktype.eft_file_text = "NAB.AB" 
               DISPLAY BY NAME l_rec_banktype.eft_file_text
				END IF 
			END IF 

		AFTER FIELD eft_file_text 
			IF l_rec_banktype.eft_format_ind IS NOT NULL 
			OR l_rec_banktype.eft_path_text IS NOT NULL 
			OR l_rec_banktype.eft_file_text IS NOT NULL THEN 
				IF l_rec_banktype.eft_format_ind IS NULL 
				OR l_rec_banktype.eft_path_text IS NULL 
				OR l_rec_banktype.eft_file_text IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9162,"")		#9162 " All OR No EFT Details must be entered
					NEXT FIELD eft_format_ind 
				END IF 
			END IF 

		AFTER FIELD stmt_file_text 
			IF l_rec_banktype.stmt_format_ind IS NOT NULL 
			OR l_rec_banktype.stmt_path_text IS NOT NULL 
			OR l_rec_banktype.stmt_file_text IS NOT NULL THEN
				IF l_rec_banktype.stmt_format_ind IS NULL 
				OR l_rec_banktype.stmt_path_text IS NULL 
			   OR l_rec_banktype.stmt_file_text IS NULL THEN
					LET l_msgresp = kandoomsg("G",9163,"") 	#9163 " All OR No Statement Load Details must be entered
					NEXT FIELD stmt_format_ind 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag = 0 AND quit_flag = 0 THEN 
            # "Apply" action activated.
				IF l_rec_banktype.type_code IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9164,"") 		#9164 " Bank Type must NOT be NULL
					NEXT FIELD type_code 
				END IF 

				IF l_rec_banktype.type_text IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9161,"") 		#9161 " Bank Type Description must NOT be NULL
					NEXT FIELD type_text 
				END IF 

				IF l_rec_banktype.eft_format_ind IS NOT NULL 
				OR l_rec_banktype.eft_path_text IS NOT NULL 
				OR l_rec_banktype.eft_file_text IS NOT NULL THEN 
					IF l_rec_banktype.eft_format_ind IS NULL 
					OR l_rec_banktype.eft_path_text IS NULL 
					OR l_rec_banktype.eft_file_text IS NULL THEN 
						LET l_msgresp = kandoomsg("G",9162,"")	#9162 " All OR No EFT Details must be entered
						NEXT FIELD eft_format_ind 
					END IF 
				END IF 

				IF l_rec_banktype.stmt_format_ind IS NOT NULL 
				OR l_rec_banktype.stmt_path_text IS NOT NULL 
				OR l_rec_banktype.stmt_file_text IS NOT NULL THEN
					IF l_rec_banktype.stmt_format_ind IS NULL 
					OR l_rec_banktype.stmt_path_text IS NULL 
			   	OR l_rec_banktype.stmt_file_text IS NULL THEN
						LET l_msgresp = kandoomsg("G",9163,"")		#9163 " All OR No Statement Load Details must be entered
						NEXT FIELD stmt_format_ind 
					END IF 
				END IF
         END IF

	END INPUT 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		CLOSE WINDOW g533 
		RETURN FALSE 
	END IF 

	INSERT INTO banktype VALUES (l_rec_banktype.*) 

	CLOSE WINDOW G533 

	RETURN SQLCA.SQLERRD[3] 
END FUNCTION 
####################################################################################
# END FUNCTION add_banktype()
####################################################################################


####################################################################################
# FUNCTION add_banktypedetl()
#
#
####################################################################################
FUNCTION add_banktypedetl(p_bank_type) 
	DEFINE p_bank_type LIKE banktype.type_code 
	DEFINE l_rec_banktypedetl RECORD LIKE banktypedetl.* 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_arr_rec_banktypedetl DYNAMIC ARRAY OF
	RECORD 
		bank_ref_code LIKE banktypedetl.bank_ref_code, 
		desc_text LIKE banktypedetl.desc_text, 
		max_ref_code LIKE banktypedetl.max_ref_code, 
		cr_dr_ind LIKE banktypedetl.cr_dr_ind 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msgtext STRING
	DEFINE i INTEGER

	DECLARE c_banktypedetl CURSOR FOR
		SELECT * FROM banktypedetl 
		WHERE type_code = p_bank_type 
		ORDER BY banktypedetl.bank_ref_code 

	OPEN WINDOW G539 WITH FORM "G539" -- ATTRIBUTE(BORDER)
	CALL windecoration_g("G539") 

	SELECT * INTO l_rec_banktype.* FROM banktype 
	WHERE type_code = p_bank_type 

	LET l_idx = 1 
	FOREACH c_banktypedetl INTO l_rec_banktypedetl.* 
		LET l_arr_rec_banktypedetl[l_idx].bank_ref_code = l_rec_banktypedetl.bank_ref_code 
		LET l_arr_rec_banktypedetl[l_idx].desc_text = l_rec_banktypedetl.desc_text 
		LET l_arr_rec_banktypedetl[l_idx].max_ref_code = l_rec_banktypedetl.max_ref_code 
		LET l_arr_rec_banktypedetl[l_idx].cr_dr_ind = l_rec_banktypedetl.cr_dr_ind 
		LET l_idx = l_idx + 1 
	END FOREACH 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	DISPLAY BY NAME l_rec_banktype.type_code,l_rec_banktype.type_text

	LET l_msgresp = kandoomsg("G",1003,"") #" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	OPTIONS INPUT NO WRAP
	INPUT ARRAY l_arr_rec_banktypedetl WITHOUT DEFAULTS FROM sr_banktypedetl.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZT","bankTypeDetlList") 
         CALL fgl_dialog_setactionlabel("Insert", "", "", 0, FALSE) -- Deactivation of Default Action "Insert"

		BEFORE DELETE
			LET l_idx = arr_curr()
         IF l_arr_rec_banktypedetl[l_idx].bank_ref_code IS NOT NULL OR
            l_arr_rec_banktypedetl[l_idx].desc_text IS NOT NULL OR
            l_arr_rec_banktypedetl[l_idx].max_ref_code IS NOT NULL OR
            l_arr_rec_banktypedetl[l_idx].cr_dr_ind IS NOT NULL THEN            
            LET l_msgtext = "Confirmation to delete Account Transaction Code?"
            IF NOT promptTF("",l_msgtext,0) THEN
               CANCEL DELETE
            END IF
         END IF

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD bank_ref_code 
			LET l_idx = arr_curr()
         IF l_idx > 0 THEN
			   FOR i = 1 TO arr_count() 
				   IF i <> l_idx THEN 
					   IF l_arr_rec_banktypedetl[l_idx].bank_ref_code = 
					      l_arr_rec_banktypedetl[i].bank_ref_code THEN 
						   LET l_msgresp = kandoomsg("G",9197,"") 
						   #9197 Account transaction type already exists
						   NEXT FIELD bank_ref_code 
					   END IF 
				   END IF 
			   END FOR 
         END IF

	END INPUT 
	OPTIONS INPUT WRAP

	IF int_flag = 1 OR quit_flag = 1 THEN 
      # "Cancel" action activated.
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW G539 
		RETURN 
	ELSE 
      # "Apply" action activated.
      BEGIN WORK
		   DELETE FROM banktypedetl WHERE type_code = p_bank_type
		   FOR l_idx = 1 TO arr_count() 
            IF l_arr_rec_banktypedetl[l_idx].bank_ref_code IS NOT NULL THEN
				   LET l_rec_banktypedetl.type_code = p_bank_type 
				   LET l_rec_banktypedetl.bank_ref_code = l_arr_rec_banktypedetl[l_idx].bank_ref_code 
				   LET l_rec_banktypedetl.desc_text = l_arr_rec_banktypedetl[l_idx].desc_text 
				   LET l_rec_banktypedetl.max_ref_code = l_arr_rec_banktypedetl[l_idx].max_ref_code 
				   LET l_rec_banktypedetl.cr_dr_ind = l_arr_rec_banktypedetl[l_idx].cr_dr_ind 

				   INSERT INTO banktypedetl VALUES (l_rec_banktypedetl.*) 

            END IF
		   END FOR 
      COMMIT WORK
	END IF 

	CLOSE WINDOW G539 

END FUNCTION 
####################################################################################
# END FUNCTION add_banktypedetl()
####################################################################################