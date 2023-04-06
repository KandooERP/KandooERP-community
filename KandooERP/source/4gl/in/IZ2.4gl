{
###########################################################################l_arr_rec_class
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

	Source code beautified by beautify.pl on 2020-01-03 09:12:47	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com
}
# \file
# \brief module IZ2 - Maintains Inventory Classes
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_err_message CHAR(40) 
END GLOBALS 

FUNCTION IZ2_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

####################################################################
# MAIN
#
#
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZ2") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	OPEN WINDOW i140 with FORM "I140" 
	 CALL windecoration_i("I140") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL create_table("prodstructure","t_prodstructure","","Y") 

	#   WHILE select_class()
	CALL scan_class() 
	#   END WHILE

	CLOSE WINDOW i140 
END MAIN 


####################################################################
# FUNCTION IZ2_mult_segs(p_cmpy,p_class_code)
#
#
####################################################################
FUNCTION iz2_mult_segs(p_cmpy,p_class_code) 
	DEFINE 
	p_class_code LIKE class.class_code, 
	p_cmpy LIKE company.cmpy_code, 
	pr_segment_cnt SMALLINT 

	SELECT count(*) INTO pr_segment_cnt FROM t_prodstructure 
	WHERE class_code = p_class_code 
	AND cmpy_code = p_cmpy 

	IF pr_segment_cnt < 1 THEN 
		RETURN false 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION 


####################################################################
# FUNCTION select_class()
#
#
####################################################################
FUNCTION select_class() 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE r_query_text CHAR(2200)

	CLEAR FORM 
	LET l_msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON class_code,desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZ2","construct-class") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET r_query_text = NULL 
	ELSE 
		LET l_msgresp = kandoomsg("I",1002,"") 
		#1002 " Searching database - please wait"
		LET r_query_text = "SELECT * FROM class ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY class.class_code" 
	END IF 

	RETURN r_query_text 

END FUNCTION 


####################################################################
# FUNCTION edit_flex_struc(p_class_code,p_desc_text)
#
#
####################################################################
FUNCTION edit_flex_struc(p_class_code,p_desc_text) 
	DEFINE p_class_code LIKE class.class_code 
	DEFINE p_desc_text LIKE class.desc_text 
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.* 
	DEFINE l_arr_rec_prodstructure DYNAMIC ARRAY OF
	RECORD 
		seq_num LIKE prodstructure.seq_num, 
		start_num LIKE prodstructure.start_num, 
		length LIKE prodstructure.length, 
		desc_text LIKE prodstructure.desc_text, 
		type_ind LIKE prodstructure.type_ind, 
		valid_flag LIKE prodstructure.valid_flag 
	END RECORD 
	DEFINE l_class_desc STRING 
	DEFINE l_total_length INTEGER 
	DEFINE l_vertical SMALLINT 
	DEFINE l_horizontal SMALLINT 
	DEFINE l_s_type_ind SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_desc_length SMALLINT 
	DEFINE l_desc_fill SMALLINT 
	DEFINE l_x SMALLINT 
	DEFINE l_i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW i622 with FORM "I622" 
	 CALL windecoration_i("I622") 

	LET l_msgresp = kandoomsg("I",1002,"") 
	#1002 " Searching database - please wait"
	DECLARE c_prodstructure CURSOR FOR 
	SELECT * FROM t_prodstructure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND
	      class_code = p_class_code 
	ORDER BY seq_num 

	LET l_idx = 0 
	LET l_horizontal = FALSE 
	LET l_vertical = FALSE 
	CALL l_arr_rec_prodstructure.CLEAR()
	FOREACH c_prodstructure INTO l_rec_prodstructure.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_prodstructure[l_idx].seq_num = l_rec_prodstructure.seq_num 
		LET l_arr_rec_prodstructure[l_idx].start_num = l_rec_prodstructure.start_num 
		LET l_arr_rec_prodstructure[l_idx].length = l_rec_prodstructure.length 
		LET l_arr_rec_prodstructure[l_idx].desc_text = l_rec_prodstructure.desc_text 
		LET l_arr_rec_prodstructure[l_idx].type_ind = l_rec_prodstructure.type_ind 
		LET l_arr_rec_prodstructure[l_idx].valid_flag = l_rec_prodstructure.valid_flag 
		IF l_rec_prodstructure.type_ind = "V" THEN 
			LET l_vertical = TRUE 
		END IF 
		IF l_rec_prodstructure.type_ind = "H" THEN 
			LET l_horizontal = TRUE 
		END IF 
	END FOREACH 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	LET l_class_desc = NULL 
	LET l_class_desc = p_class_code clipped, "      ",p_desc_text clipped
	DISPLAY l_class_desc TO class_desc 

	LET l_msgresp = kandoomsg("I",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_prodstructure WITHOUT DEFAULTS FROM sr_prodstructure.* attribute(UNBUFFERED,append ROW = true, auto append=true, insert row=false,delete row = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ2","inp-arr-prodstructure") 
			CALL fgl_dialog_setactionlabel("Insert", "", "", 0, FALSE) -- Deactivation of Default Action "Insert"
--         CALL fgl_dialog_setactionlabel("Cancel", "", "", 0, FALSE) -- Deactivation of Default Action "Cancel"
			CALL fgl_dialog_setactionlabel("Accept", "Return", "{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg", 2, FALSE, "Return to Product Class Details")

		BEFORE INSERT 
			LET l_idx = arr_curr() 
			IF l_idx > 0 THEN
				FOR l_x = arr_count() TO l_idx STEP -1 
					IF l_arr_rec_prodstructure[l_x].start_num IS NOT NULL THEN 
						LET l_arr_rec_prodstructure[l_x].seq_num = l_x 
					END IF 
				END FOR 
				LET l_arr_rec_prodstructure[l_idx].seq_num = l_idx 
				IF l_idx = 1 THEN
					LET l_arr_rec_prodstructure[l_idx].start_num = 1 
				ELSE 
					LET l_arr_rec_prodstructure[l_idx].start_num = l_arr_rec_prodstructure[l_idx-1].start_num + l_arr_rec_prodstructure[l_idx-1].length
				END IF
				IF l_arr_rec_prodstructure[l_idx].start_num > 15 THEN
					LET l_msgresp = kandoomsg("I",9149,"15") 
					    #9149 Total Length must NOT be greater than...
					CANCEL INSERT
				END IF
				NEXT FIELD start_num 
			END IF

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD start_num 
			LET l_idx = arr_curr()
			IF l_idx > 0 THEN
				IF l_idx = 1 AND l_arr_rec_prodstructure[l_idx].start_num != 1 THEN
					LET l_msgresp = kandoomsg("I",9194,"") 
					#9194 First Starting Position must be 1
					NEXT FIELD start_num
				END IF

				IF l_arr_rec_prodstructure[l_idx].start_num = 0 THEN 
					LET l_msgresp = kandoomsg("I",9141,"") 
					#9141 Starting Number must be entered
					NEXT FIELD start_num 
				END IF

				IF l_arr_rec_prodstructure[l_idx].start_num < 0 THEN
					LET l_arr_rec_prodstructure[l_idx].start_num = -l_arr_rec_prodstructure[l_idx].start_num
				END IF 

				IF l_arr_rec_prodstructure[l_idx].start_num > 15 THEN 
					LET l_msgresp = kandoomsg("I",9147,"15") 
					#9147 Starting Number must NOT be greater than ...
					NEXT FIELD start_num 
				END IF 
			END IF

		AFTER FIELD length 
			LET l_idx = arr_curr()
			IF l_idx > 0 THEN
				IF l_arr_rec_prodstructure[l_idx].length = 0 THEN 
					LET l_msgresp = kandoomsg("I",9142,"") 
					#9142 Length must be entered
					NEXT FIELD length 
				END IF

            IF l_arr_rec_prodstructure[l_idx].length < 0 THEN
               LET l_arr_rec_prodstructure[l_idx].length = -l_arr_rec_prodstructure[l_idx].length
            END IF 
 
			   IF l_arr_rec_prodstructure[l_idx].length > 15 THEN 
				   LET l_msgresp = kandoomsg("I",9148,"15") 
				   #9148 Length must NOT be greater than....
				   NEXT FIELD length 
			   END IF 

			   IF l_arr_rec_prodstructure[l_idx].type_ind = "F" THEN 
				   IF l_arr_rec_prodstructure[l_idx].length != 1 THEN 
					   LET l_msgresp = kandoomsg("I",9198,"") 
					   #9198 Segment length must be one
					   NEXT FIELD length 
				   END IF 
            END IF
         END IF

		AFTER FIELD desc_text 
			LET l_idx = arr_curr()
         IF l_idx > 0 THEN
			   IF l_arr_rec_prodstructure[l_idx].type_ind = "F" THEN 
               LET l_arr_rec_prodstructure[l_idx].desc_text = "F"
            END IF
         END IF

		AFTER FIELD type_ind 
			LET l_idx = arr_curr()
#        Validation is carried out in the form "I622" -- albo
#			IF l_arr_rec_prodstructure[l_idx].type_ind != 'F' 
#			AND l_arr_rec_prodstructure[l_idx].type_ind != 'S' 
#			AND l_arr_rec_prodstructure[l_idx].type_ind != 'H' 
#			AND l_arr_rec_prodstructure[l_idx].type_ind != 'V' THEN 
#				LET l_msgresp = kandoomsg("I",9146,"") 
#				#9146 Type Indicator must be 'F'iller OR 'S'tructure
#				NEXT FIELD type_ind 
#			END IF 
         IF l_idx > 0 THEN
			   IF l_arr_rec_prodstructure[l_idx].type_ind = 'H' THEN 
				   FOR l_i = 1 TO arr_count() 
					   IF l_idx != l_i THEN 
						   IF l_arr_rec_prodstructure[l_i].type_ind = 'H' THEN 
							   LET l_msgresp = kandoomsg("I",9557,"") 
							   #9557 Only one horizontal segment allowed
							   NEXT FIELD type_ind 
						   END IF 
					   END IF 
				   END FOR 
				   LET l_horizontal = TRUE 
			   END IF 

			   IF l_arr_rec_prodstructure[l_idx].type_ind = 'V' THEN 
				   FOR l_i = 1 TO arr_count() 
					   IF l_idx != l_i THEN 
						   IF l_arr_rec_prodstructure[l_i].type_ind = 'V' THEN 
							   LET l_msgresp = kandoomsg("I",9558,"") 
							   #9557 Only one vertical segment allowed
							   NEXT FIELD type_ind 
						   END IF 
					   END IF 
				   END FOR 
				   LET l_vertical = TRUE 
			   END IF 

			   IF l_idx > 1 THEN 
				   IF l_arr_rec_prodstructure[l_idx-1].type_ind = 'F' AND 
				      l_arr_rec_prodstructure[l_idx].type_ind = 'F' THEN 
					   LET l_msgresp = kandoomsg("I",9532,"") 
					   #9532 Cannot have consecutive fillers
					   NEXT FIELD type_ind 
				   END IF 
			   END IF 

			   IF l_arr_rec_prodstructure[l_idx].type_ind = "F" THEN 
               LET l_arr_rec_prodstructure[l_idx].length = 1
               LET l_arr_rec_prodstructure[l_idx].desc_text = "F"
               LET l_arr_rec_prodstructure[l_idx].valid_flag = "N"                              
            END IF         

			   IF l_arr_rec_prodstructure[l_idx].type_ind = "F" THEN 
				   IF l_arr_rec_prodstructure[l_idx].length != 1 THEN 
					   LET l_msgresp = kandoomsg("I",9198,"") 
					   #9198 Segment length must be one
					   NEXT FIELD length 
				   END IF 
            END IF
         
         END IF

		AFTER FIELD valid_flag 
			LET l_idx = arr_curr()
         IF l_idx > 0 THEN
			   IF l_arr_rec_prodstructure[l_idx].valid_flag != "Y" AND 
			      l_arr_rec_prodstructure[l_idx].valid_flag != "N" THEN 
				   LET l_msgresp = kandoomsg("I",9145,"") 
				   #9145 Validation Flag must be 'Y'es OR 'N'o
				   NEXT FIELD valid_flag 
			   END IF 

			   IF l_arr_rec_prodstructure[l_idx].type_ind = "F" AND 
			      l_arr_rec_prodstructure[l_idx].valid_flag != "N" THEN 
				   LET l_msgresp = kandoomsg("I",9199,"") 
				   #9199 Validation Flag 'N' for filler segment
				   NEXT FIELD valid_flag 
			   END IF 

			   IF (l_arr_rec_prodstructure[l_idx].type_ind = "V" OR 
			       l_arr_rec_prodstructure[l_idx].type_ind = "H") AND 
			       l_arr_rec_prodstructure[l_idx].valid_flag != "Y" THEN 
				   LET l_msgresp = kandoomsg("I",9560,"") 
				   #9560 Validation Flag 'Y' for matrix segment
				   NEXT FIELD valid_flag 
			   END IF 
         END IF

		AFTER INPUT 
			IF int_flag = 0 AND quit_flag = 0 THEN 
            # "Apply" action activated.
				LET l_x = arr_count() 
            IF l_x > 0 THEN 
				   IF l_arr_rec_prodstructure[1].start_num != 1 THEN 
					   LET l_msgresp = kandoomsg("I",9194,"") 
					   #9194 First Starting Position must be 1
			         CONTINUE INPUT
				   END IF 

				   IF l_arr_rec_prodstructure[l_x].type_ind = "F" THEN 
					   LET l_msgresp = kandoomsg("I",9533,"") 
					   #9533 Last segment cannot be a Filler
			         CONTINUE INPUT
				   END IF 

				   LET l_total_length = 0 
				   FOR l_x = 1 TO arr_count() 
			         IF l_arr_rec_prodstructure[l_x].length = 0 THEN 
				         LET l_msgresp = kandoomsg("I",9142,"") 
				         #9142 Length must be entered
				         CONTINUE INPUT 
			         END IF
					   IF l_arr_rec_prodstructure[l_x].seq_num IS NOT NULL THEN 
						   LET l_total_length = l_total_length  + l_arr_rec_prodstructure[l_x].length 
					   END IF 
				   END FOR 
				   IF l_total_length > 15 THEN 
					   LET l_msgresp = kandoomsg("I",9149,"15") 
					   #9149 Total Length must NOT be greater than...
					   CONTINUE INPUT
				   END IF 

				   LET l_s_type_ind = FALSE 
				   FOR l_x = 1 TO arr_count() 
			         IF l_arr_rec_prodstructure[l_x].start_num = 0 THEN 
				         LET l_msgresp = kandoomsg("I",9141,"") 
				         #9141 Starting Number must be entered
				         CONTINUE INPUT 
			         END IF
			
					   IF l_arr_rec_prodstructure[l_x + 1].start_num IS NOT NULL THEN 
						   IF l_arr_rec_prodstructure[l_x + 1].start_num != (l_arr_rec_prodstructure[l_x].start_num + l_arr_rec_prodstructure[l_x].length) THEN 
							   LET l_msgresp = kandoomsg("I",9150,"") 
							   #9150 Starting position must be in ORDER without gaps...
							   #                     NEXT FIELD scroll_flag
					         CONTINUE INPUT
						   END IF 
					   END IF 

					   IF l_arr_rec_prodstructure[l_x].type_ind = "S" THEN 
						   LET l_s_type_ind = TRUE 
					   END IF 
					   IF l_arr_rec_prodstructure[l_x].type_ind = "H" OR 
					      l_arr_rec_prodstructure[l_x].type_ind = "V" THEN 
						   IF NOT l_s_type_ind THEN 
							   LET l_msgresp = kandoomsg("I",9559,"") 
							   #9559 Structure type before vertical/horizontal type
					         CONTINUE INPUT
						   END IF 
					   END IF 

   			      IF l_arr_rec_prodstructure[l_x].type_ind = "F" THEN 
   				      IF l_arr_rec_prodstructure[l_x].length != 1 THEN 
					         LET l_msgresp = kandoomsg("I",9198,"") 
					         #9198 Segment length must be one
					         CONTINUE INPUT 
				         END IF 
                  END IF

                  IF l_arr_rec_prodstructure[l_x].start_num < 0 THEN
                     LET l_arr_rec_prodstructure[l_x].start_num = -l_arr_rec_prodstructure[l_x].start_num
                  END IF

                  IF l_arr_rec_prodstructure[l_x].length < 0 THEN
                     LET l_arr_rec_prodstructure[l_x].length = -l_arr_rec_prodstructure[l_x].length
                  END IF

			         IF l_arr_rec_prodstructure[l_x].type_ind = "F" THEN 
                     LET l_arr_rec_prodstructure[l_x].length = 1
                     LET l_arr_rec_prodstructure[l_x].desc_text = "F"
                     LET l_arr_rec_prodstructure[l_x].valid_flag = "N"                              
                  END IF
				   END FOR 
            END IF
			END IF 

	END INPUT 
   OPTIONS INPUT WRAP

	IF int_flag = 1 OR quit_flag = 1 THEN 
      # "Cancel" action activated.
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
      # "Apply" action activated.
		DELETE FROM t_prodstructure 
		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_prodstructure[l_idx].start_num IS NOT NULL THEN 
				LET l_rec_prodstructure.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_prodstructure.class_code = p_class_code 
				LET l_rec_prodstructure.seq_num = l_idx 
				LET l_rec_prodstructure.start_num = l_arr_rec_prodstructure[l_idx].start_num 
				LET l_rec_prodstructure.length = l_arr_rec_prodstructure[l_idx].length 
				LET l_rec_prodstructure.desc_text = l_arr_rec_prodstructure[l_idx].desc_text 
				LET l_rec_prodstructure.type_ind = l_arr_rec_prodstructure[l_idx].type_ind 
				LET l_rec_prodstructure.valid_flag = l_arr_rec_prodstructure[l_idx].valid_flag 
				INSERT INTO t_prodstructure VALUES (l_rec_prodstructure.*) 
			END IF 
		END FOR 
	END IF 

	CLOSE WINDOW i622 

END FUNCTION 


####################################################################
# FUNCTION scan_class()
#
#
####################################################################
FUNCTION scan_class() 
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_arr_rec_class DYNAMIC ARRAY OF t_rec_class_c_d 
	DEFINE l_do_while SMALLINT
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text VARCHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 
   DEFINE l_msgtext STRING 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	LET l_do_while = 1
	WHILE l_do_while

	CALL l_arr_rec_class.CLEAR()
	CALL db_class_get_arr_rec_c_d(filter_query_off,null) RETURNING l_arr_rec_class
	LET l_msgresp = kandoomsg("I",1309,"") 
	#1309 "F1 TO Add - F2 TO Delete - RETURN TO Edit

	DISPLAY ARRAY l_arr_rec_class TO sr_class.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IZ2","disp-arr-class") 
			LET l_do_while = 0

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			LET l_query_text = select_class() 
         CALL l_arr_rec_class.CLEAR()
			IF l_query_text IS NULL THEN 
				CALL db_class_get_arr_rec_c_d(filter_query_off,null) RETURNING l_arr_rec_class 
			ELSE 
				CALL db_class_get_arr_rec_c_d(filter_query_select,l_query_text) RETURNING l_arr_rec_class 
			END IF 

		ON ACTION ("EDIT","DOUBLECLICK") 
			LET l_idx = arr_curr()         
			IF l_idx > 0 THEN 
				IF l_arr_rec_class[l_idx].class_code IS NOT NULL THEN 
					IF edit_class(l_arr_rec_class[l_idx].class_code) > 0 THEN 
                  LET l_do_while = 1
                  EXIT DISPLAY
					END IF 
				END IF 
			END IF 

		ON ACTION "Add" 
			IF edit_class("") > 0 THEN 
            LET l_do_while = 1
            EXIT DISPLAY
			END IF

		ON ACTION "DELETE" 
         LET l_idx = arr_curr()
			SELECT COUNT(*) INTO l_cnt FROM product
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
			      class_code = l_arr_rec_class[l_idx].class_code
         IF l_cnt = 0 THEN         
				#LET l_msgresp = kandoomsg("I",8004,l_del_cnt) 
				#8004 Confirm TO Delete ",l_del_cnt," Class(s)? (Y/N)"
            LET l_msgtext = "Confirmation to delete """,l_arr_rec_class[l_idx].desc_text CLIPPED,""" inventory class?"
            IF promptTF("",l_msgtext,1) THEN  
               BEGIN WORK
					   DELETE FROM class 
					   WHERE class_code = l_arr_rec_class[l_idx].class_code AND 
					         cmpy_code = glob_rec_kandoouser.cmpy_code 
					   DELETE FROM prodstructure 
					   WHERE class_code = l_arr_rec_class[l_idx].class_code AND 
					         cmpy_code = glob_rec_kandoouser.cmpy_code 
					   DELETE FROM prodflex 
					   WHERE class_code = l_arr_rec_class[l_idx].class_code AND 
					         cmpy_code = glob_rec_kandoouser.cmpy_code
               COMMIT WORK 					    
               LET l_do_while = 1
               EXIT DISPLAY
				END IF 
			ELSE 
				#LET l_msgresp=kandoomsg("I",7028,l_arr_rec_class[l_idx].desc_text) 
				#7028 Class code ??? has been assigned TO a product
            LET l_msgtext = "Class code """,l_arr_rec_class[l_idx].desc_text CLIPPED,""" is assigned to a product.\nNo Deletion Permitted."
            CALL msgerror("",l_msgtext) 
			END IF 

	END DISPLAY 

   END WHILE

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

END FUNCTION 


####################################################################
# FUNCTION edit_classp_class_codee)
#
#
####################################################################
FUNCTION edit_class(p_class_code) 
	DEFINE p_class_code LIKE class.class_code 
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_rec_s_class RECORD LIKE class.* 
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.* 
	DEFINE l_segs_reqd SMALLINT 
	DEFINE l_sqlerrd INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msgtext STRING

	INITIALIZE l_rec_class.* TO NULL
	IF p_class_code IS NOT NULL THEN 
		SELECT * INTO l_rec_class.* FROM class 
		WHERE class_code = p_class_code AND
		      cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_segs_reqd = FALSE 
	ELSE 
		LET l_rec_class.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_segs_reqd = TRUE 
	END IF 

	DECLARE c_prodstructure3 CURSOR FOR 
	SELECT * FROM prodstructure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND
	      class_code = p_class_code 

	DELETE FROM t_prodstructure 

	FOREACH c_prodstructure3 INTO l_rec_prodstructure.* 
		INSERT INTO t_prodstructure VALUES (l_rec_prodstructure.*) 
	END FOREACH 

	OPEN WINDOW i621 with FORM "I621" 
	 CALL windecoration_i("I621") 
	#huho 13.6.2019 - function accesses empty table kandoooption - added hack to always return "Y" (assume, this means module is registered/available for this company
	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
		LET l_msgresp = kandoomsg("I",1034,"") 
		#1034 " Enter Class Details - Enter Prdouct Structure
	ELSE 
		LET l_msgresp = kandoomsg("I",1043,"") 
		#1043 " Enter Class Details
	END IF 

	INPUT BY NAME l_rec_class.class_code, 
	              l_rec_class.desc_text, 
	              l_rec_class.price_level_ind, --parent price level 
	              l_rec_class.ord_level_ind, 
	              l_rec_class.stock_level_ind, 
	              l_rec_class.desc_level_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ2","input-class") 
         CALL fgl_dialog_setactionlabel("Product Structure","Product Structure","{CONTEXT}/public/querix/icon/svg/24/ic_edit_24px.svg",4,FALSE,"Enter Product Flexible Structure")

			IF p_class_code IS NOT NULL THEN
            # Initialization of comboboxes from the table t_prodstructure
				CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("price_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
				CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("ord_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
				CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("stock_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
				CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("desc_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
            # Initialization of the description of the values of Product Structure Levels from the table t_prodstructure
			   SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
			   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
			         class_code = l_rec_class.class_code	AND 
			         seq_num = l_rec_class.price_level_ind 
		      DISPLAY l_rec_prodstructure.desc_text TO price_level_ind_desc_text                                                                                                                                                
			   SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
			   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			         class_code = l_rec_class.class_code	AND 
			         seq_num = l_rec_class.ord_level_ind 
		      DISPLAY l_rec_prodstructure.desc_text TO ord_level_ind_desc_text
			   SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
			   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
			         class_code = l_rec_class.class_code	AND 
			         seq_num = l_rec_class.stock_level_ind 
		      DISPLAY l_rec_prodstructure.desc_text TO stock_level_ind_desc_text                                                                                                                                                
			   SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
			   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
			         class_code = l_rec_class.class_code AND 
			         seq_num = l_rec_class.desc_level_ind 
		      DISPLAY l_rec_prodstructure.desc_text TO desc_level_ind_desc_text
			END IF

		BEFORE FIELD class_code 
			IF p_class_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 

		BEFORE FIELD price_level_ind,ord_level_ind,stock_level_ind,desc_level_ind 
			IF p_class_code IS NULL THEN 
				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
					IF l_segs_reqd = TRUE THEN 
						CALL edit_flex_struc(l_rec_class.class_code, l_rec_class.desc_text) 
                  # Initialization of comboboxes from the table t_prodstructure
				      CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("price_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
				      CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("ord_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
				      CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("stock_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
				      CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("desc_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT)
						LET l_segs_reqd = FALSE 
					END IF 
				ELSE 
               IF INFIELD(price_level_ind) THEN
                  LET l_msgtext = "To enter a Product Structure, you must first set the ""Setting"" option to ""Y"" for ""Flex Product Structure"" description in the program\n",
                                  "U1T - Tailoring Options Maintenance."
                  CALL msgerror("",l_msgtext) 
               END IF
					NEXT FIELD previous 
				END IF 
         ELSE IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") != "Y" THEN
				     IF NOT iz2_mult_segs(glob_rec_kandoouser.cmpy_code, l_rec_class.class_code) THEN 
                    IF INFIELD(price_level_ind) THEN
                       LET l_msgtext = "To enter a Product Structure, you must first set the ""Setting"" option to ""Y"" for ""Flex Product Structure"" description in the program\n",
                                       "U1T - Tailoring Options Maintenance."
                       CALL msgerror("",l_msgtext) 
                    END IF
					     NEXT FIELD previous 
				     END IF				  
              END IF
			END IF 

			IF NOT get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") != "Y" THEN 
				IF NOT iz2_mult_segs(glob_rec_kandoouser.cmpy_code, l_rec_class.class_code) THEN 
               IF INFIELD(price_level_ind) THEN
                  LET l_msgtext = "Enter Product Structure."
                  CALL msgerror("",l_msgtext) 
               END IF
					NEXT FIELD previous 
				END IF 
			END IF 

		ON ACTION "Product Structure"
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
				CALL edit_flex_struc(l_rec_class.class_code, l_rec_class.desc_text) 
            # Initialization of comboboxes from the table t_prodstructure
				CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("price_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
				CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("ord_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
				CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("stock_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT) 
				CALL comboList_t_prodstructure_price_level_seq_num_by_class_code("desc_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_class.class_code,COMBO_NULL_NOT)
				LET l_segs_reqd = FALSE 
         ELSE LET l_msgtext = "To enter a Product Structure, you must first set the ""Setting"" option to ""Y"" for ""Flex Product Structure"" description in the program\n",
                              "U1T - Tailoring Options Maintenance."
              CALL msgerror("",l_msgtext) 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD class_code 
			IF l_rec_class.class_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9091,"") 
				#9091 " Class must NOT be NULL
				NEXT FIELD class_code 
			END IF 

			IF p_class_code IS NOT NULL THEN 
				SELECT * INTO l_rec_s_class.* FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = l_rec_class.class_code 
				IF STATUS != NOTFOUND THEN 
					LET l_msgresp = kandoomsg("I",9092,"") 
					#9092 Class alreay exists - Please re-enter
					NEXT FIELD class_code 
				END IF 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_class.desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9084,"") 
				#9084 " Description must NOT be NULL
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD price_level_ind 
			IF l_rec_class.price_level_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9131,"") 
				#9131 Price Level Indicator must NOT be NULL
				NEXT FIELD price_level_ind 
			ELSE 
				SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = l_rec_class.class_code 
				AND seq_num = l_rec_class.price_level_ind 
				IF STATUS = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("I",9132,"") 
					#9132 Price Level Indicator must be a valid Structure Seq No.
					NEXT FIELD price_level_ind 
				ELSE 
					IF l_rec_prodstructure.type_ind = "F" THEN 
						LET l_msgresp = kandoomsg("I",9197,"") 
						#9197 Cannot SET indicator TO filler segment
						NEXT FIELD price_level_ind 
					END IF 
				END IF 
			END IF 
		   DISPLAY l_rec_prodstructure.desc_text TO price_level_ind_desc_text

		AFTER FIELD ord_level_ind 
			IF l_rec_class.ord_level_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9133,"") 
				#9133 Order Level Indicator must NOT be NULL
				NEXT FIELD ord_level_ind 
			ELSE 
				SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = l_rec_class.class_code 
				AND seq_num = l_rec_class.ord_level_ind 
				IF STATUS = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("I",9134,"") 
					#9134 Order Level Indicator must be a valid Structure Seq No.
					NEXT FIELD ord_level_ind 
				ELSE 
					IF l_rec_prodstructure.type_ind = "F" THEN 
						LET l_msgresp = kandoomsg("I",9197,"") 
						#9197 Cannot SET indicator TO filler segment
						NEXT FIELD ord_level_ind 
					END IF 
				END IF 
			END IF 
			IF l_rec_class.ord_level_ind < l_rec_class.price_level_ind THEN 
				LET l_msgresp = kandoomsg("I",9529,"") 
				#9529 Order level ind must NOT be less than Price Level Indicator.
				NEXT FIELD ord_level_ind 
			END IF 
		   DISPLAY l_rec_prodstructure.desc_text TO ord_level_ind_desc_text

		AFTER FIELD stock_level_ind 
			IF l_rec_class.stock_level_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9135,"") 
				#9135 Stocking Level Indicator must NOT be NULL
				NEXT FIELD stock_level_ind 
			ELSE 
				IF l_rec_class.stock_level_ind < l_rec_class.ord_level_ind THEN 
					LET l_msgresp = kandoomsg("I",9136,"") 
					#9136 Must NOT be less than Order Level Indicator
					NEXT FIELD stock_level_ind 
				ELSE 
					SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND class_code = l_rec_class.class_code 
					AND seq_num = l_rec_class.stock_level_ind 
					IF STATUS = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("I",9137,"") 
						#9137 Stocking Level Indicator must be a valid Seq No.
						NEXT FIELD stock_level_ind 
					ELSE 
						IF l_rec_prodstructure.type_ind = "F" THEN 
							LET l_msgresp = kandoomsg("I",9197,"") 
							#9197 Cannot SET indicator TO filler segment
							NEXT FIELD stock_level_ind 
						END IF 
					END IF 
				END IF 
			END IF 
		   DISPLAY l_rec_prodstructure.desc_text TO stock_level_ind_desc_text

		AFTER FIELD desc_level_ind 
			IF l_rec_class.desc_level_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9138,"") 
				#9138 Description Level Indicator must NOT be NULL
				NEXT FIELD desc_level_ind 
			ELSE 
				SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = l_rec_class.class_code 
				AND seq_num = l_rec_class.desc_level_ind 
				IF STATUS = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("I",9139,"") 
					#9139 Description Level Indicator must be a valid Seq No.
					NEXT FIELD desc_level_ind 
				ELSE 
					IF l_rec_prodstructure.type_ind = "F" THEN 
						LET l_msgresp = kandoomsg("I",9197,"") 
						#9197 Cannot SET indicator TO filler segment
						NEXT FIELD desc_level_ind 
					END IF 
				END IF 
			END IF 
		   DISPLAY l_rec_prodstructure.desc_text TO desc_level_ind_desc_text

		AFTER INPUT 
			IF int_flag = 0 AND quit_flag = 0 THEN 
				IF p_class_code IS NOT NULL THEN 
					IF l_rec_class.class_code IS NULL THEN 
						LET l_msgresp = kandoomsg("I",9091,"") 
						#9091 " Class must NOT be NULL
						NEXT FIELD class_code 
					END IF 
				ELSE 
					SELECT * INTO l_rec_s_class.* FROM class 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND class_code = l_rec_class.class_code 
					IF STATUS != NOTFOUND THEN 
						LET l_msgresp = kandoomsg("I",9092,"") 
						#9092 Class alreay exists - Please re-enter
						NEXT FIELD class_code 
					END IF 
				END IF 

				IF l_rec_class.desc_text IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9084,"") 
					#9084 " Description must NOT be NULL
					NEXT FIELD desc_text 
				END IF 

				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
					IF iz2_mult_segs(glob_rec_kandoouser.cmpy_code, l_rec_class.class_code) THEN 
			         IF l_rec_class.price_level_ind IS NULL THEN 
				         LET l_msgresp = kandoomsg("I",9131,"") 
				         #9131 Price Level Indicator must NOT be NULL
				         NEXT FIELD price_level_ind 
			         ELSE 
				         SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
				         WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				         AND class_code = l_rec_class.class_code 
				         AND seq_num = l_rec_class.price_level_ind 
				         IF STATUS = NOTFOUND THEN 
					         LET l_msgresp = kandoomsg("I",9132,"") 
					         #9132 Price Level Indicator must be a valid Structure Seq No.
					         NEXT FIELD price_level_ind 
				         ELSE 
					         IF l_rec_prodstructure.type_ind = "F" THEN 
						         LET l_msgresp = kandoomsg("I",9197,"") 
						         #9197 Cannot SET indicator TO filler segment
						         NEXT FIELD price_level_ind 
					         END IF 
				         END IF 
			         END IF

			         IF l_rec_class.ord_level_ind IS NULL THEN 
				         LET l_msgresp = kandoomsg("I",9133,"") 
				         #9133 Order Level Indicator must NOT be NULL
				         NEXT FIELD ord_level_ind 
			         ELSE 
				         SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
				         WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				         AND class_code = l_rec_class.class_code 
				         AND seq_num = l_rec_class.ord_level_ind 
				         IF STATUS = NOTFOUND THEN 
					         LET l_msgresp = kandoomsg("I",9134,"") 
					         #9134 Order Level Indicator must be a valid Structure Seq No.
					         NEXT FIELD ord_level_ind 
				         ELSE 
					         IF l_rec_prodstructure.type_ind = "F" THEN 
						         LET l_msgresp = kandoomsg("I",9197,"") 
						         #9197 Cannot SET indicator TO filler segment
						         NEXT FIELD ord_level_ind 
					         END IF 
				         END IF 
			         END IF 

			         IF l_rec_class.ord_level_ind < l_rec_class.price_level_ind THEN 
				         LET l_msgresp = kandoomsg("I",9529,"") 
				         #9529 Order level ind must NOT be less than Price Level Indicator.
				         NEXT FIELD ord_level_ind 
			         END IF

			         IF l_rec_class.stock_level_ind IS NULL THEN 
				         LET l_msgresp = kandoomsg("I",9135,"") 
				         #9135 Stocking Level Indicator must NOT be NULL
				         NEXT FIELD stock_level_ind 
			         ELSE 
				         IF l_rec_class.stock_level_ind < l_rec_class.ord_level_ind THEN 
					         LET l_msgresp = kandoomsg("I",9136,"") 
					         #9136 Must NOT be less than Order Level Indicator
					         NEXT FIELD stock_level_ind 
				         ELSE 
					         SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
					         WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					         AND class_code = l_rec_class.class_code 
					         AND seq_num = l_rec_class.stock_level_ind 
					         IF STATUS = NOTFOUND THEN 
						         LET l_msgresp = kandoomsg("I",9137,"") 
						         #9137 Stocking Level Indicator must be a valid Seq No.
						         NEXT FIELD stock_level_ind 
					         ELSE 
						         IF l_rec_prodstructure.type_ind = "F" THEN 
							         LET l_msgresp = kandoomsg("I",9197,"") 
							         #9197 Cannot SET indicator TO filler segment
							         NEXT FIELD stock_level_ind 
						         END IF 
					         END IF 
				         END IF 
			         END IF

			         IF l_rec_class.desc_level_ind IS NULL THEN 
				         LET l_msgresp = kandoomsg("I",9138,"") 
				         #9138 Description Level Indicator must NOT be NULL
				         NEXT FIELD desc_level_ind 
			         ELSE 
				         SELECT * INTO l_rec_prodstructure.* FROM t_prodstructure 
				         WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				         AND class_code = l_rec_class.class_code 
				         AND seq_num = l_rec_class.desc_level_ind 
				         IF STATUS = NOTFOUND THEN 
					         LET l_msgresp = kandoomsg("I",9139,"") 
					         #9139 Description Level Indicator must be a valid Seq No.
					         NEXT FIELD desc_level_ind 
				         ELSE 
					         IF l_rec_prodstructure.type_ind = "F" THEN 
						         LET l_msgresp = kandoomsg("I",9197,"") 
						         #9197 Cannot SET indicator TO filler segment
						         NEXT FIELD desc_level_ind 
					         END IF 
				         END IF 
			         END IF
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		CLOSE WINDOW i621 
		RETURN FALSE 
	END IF 

	BEGIN WORK 
		LET glob_err_message = "IZ2 - Updating prodstructure" 

		DECLARE c_prodstructure2 CURSOR FOR 
		SELECT * FROM t_prodstructure 

		DELETE FROM prodstructure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
		      class_code = l_rec_class.class_code 

		FOREACH c_prodstructure2 INTO l_rec_prodstructure.* 
			LET l_rec_prodstructure.class_code = l_rec_class.class_code 
			INSERT INTO prodstructure VALUES (l_rec_prodstructure.*) 
		END FOREACH 

		LET glob_err_message = "IZ2 - Updating class" 

		IF p_class_code IS NULL THEN 
			INSERT INTO class VALUES (l_rec_class.*) 
			LET l_sqlerrd = sqlca.sqlerrd[3] 
		ELSE 
			UPDATE class SET class.* = l_rec_class.*
			WHERE class_code = l_rec_class.class_code
			AND cmpy_code = glob_rec_kandoouser.cmpy_code
			LET l_sqlerrd = sqlca.sqlerrd[3]
		END IF 

	COMMIT WORK 

	CLOSE WINDOW i621 

	RETURN l_sqlerrd 

END FUNCTION 
