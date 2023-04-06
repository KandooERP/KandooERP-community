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

DEFINE t_rec_arr_prodinfo TYPE AS RECORD		# type of the table/screenrecord line in the array
	info_ind LIKE prodinfo.info_ind, 
	response_text LIKE kandooword.response_text, 
	public_flag LIKE prodinfo.public_flag, 
	filename_text LIKE prodinfo.filename_text 
END RECORD

DEFINE t_rec_prodinfo_prykey TYPE AS RECORD		# type of the table's primary key 
	cmpy_code LIKE company.cmpy_code,
	part_code LIKE product.part_code,
	line_num LIKE prodinfo.line_num
END RECORD

DEFINE t_rec_arr_action TYPE AS RECORD
	action_type CHAR(1)
END RECORD

DEFINE modu_crs_list_prodinfo CURSOR

###########################################################################
# FUNCTION declare_cursors_prodinfo()
#
# builds and prepares cursors for prodinfo
###########################################################################
FUNCTION declare_cursors_prodinfo()
	DEFINE l_query_text STRING
	
	# prepare the general cursor for prodinfo
	# please not the "=" that will be loaded in the l_arr_rec_prodinfo_action array, which contains the 'to do' for each line
	# to do for each line: 
	# '=' means do not modify this line, 
	# 'I' means line to be inserted, 
	# 'D' means lines to be deleted, 
	# 'U' means line to be updated
	
	LET l_query_text = 
		"	SELECT p.info_ind,k.response_text,p.public_flag,p.filename_text,",
		" p.cmpy_code,p.part_code,p.info_ind,p.line_num,'=' ",
		" FROM prodinfo p, kandooword k",
		" WHERE p.part_code = ? ",
		" AND p.cmpy_code = ? ",
		" AND k.language_code = 'ENG' ",
		" AND k.reference_text = 'prodinfo.info_ind' ", 
		" AND k.reference_code = p.info_ind ",
		" ORDER BY p.info_ind,p.filename_text "

{
		SELECT response_text INTO l_arr_rec_prodinfo[l_idx].response_text 
			FROM kandooword 
			WHERE language_code = "ENG" 
			AND reference_code = l_arr_rec_prodinfo[l_idx].info_ind 
			AND reference_text = "prodinfo.info_ind" 
}
	CALL modu_crs_list_prodinfo.Declare(l_query_text)

END FUNCTION # declare_cursors_prodinfo()
###########################################################################
# FUNCTION declare_cursors_prodinfo()
#
# builds and prepares cursors for prodinfo
###########################################################################


###########################################################################
# FUNCTION view_prodinfo(p_cmpy_code, p_part_code)
#
# Description: This FUNCTION allows the enquiry of product
#              information.
###########################################################################
FUNCTION view_prodinfo(p_cmpy_code,p_part_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_rec_prodinfo RECORD LIKE prodinfo.* 
	DEFINE l_arr_rec_prodinfo DYNAMIC ARRAY OF t_rec_arr_prodinfo
 	DEFINE l_arr_rec_prodinfo_prykey DYNAMIC ARRAY OF t_rec_prodinfo_prykey 
	DEFINE l_arr_rec_prodinfo_action DYNAMIC ARRAY OF t_rec_arr_action
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE l_counter SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_command CHAR(100) 

		OPEN WINDOW I500 with FORM "I500" 
		CALL windecoration_i("I500") 

		IF p_part_code IS NULL THEN 
			ERROR kandoomsg2("I",5110,"") 		#5110 Logic Error: Product code does NOT exist.
			CLOSE WINDOW I500 
			RETURN 
		END IF 

		SELECT desc_text INTO l_desc_text FROM product 
		WHERE part_code = p_part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		DISPLAY p_part_code TO part_code 
		DISPLAY l_desc_text TO desc_text 

		MESSAGE kandoomsg2("U",1002,"") 	#1002 Searching database; Please wait.

		CALL modu_crs_list_prodinfo.Open(p_part_code,glob_rec_kandoouser.cmpy_code)
		
		--FOREACH c_prodinfo INTO l_rec_prodinfo.* 
		LET l_idx = 1 
		WHILE modu_crs_list_prodinfo.FetchNext(l_arr_rec_prodinfo[l_idx].*,l_arr_rec_prodinfo_prykey,l_arr_rec_prodinfo_action) = 0
			LET l_idx = l_idx + 1 
		END WHILE
		--END FOREACH 
		# Delete last element because l_idx is 1 value ahead of real elements #
		CALL l_arr_rec_prodinfo.DeleteElement(l_idx)

		IF l_idx = 1 THEN 
			ERROR kandoomsg2("I",9565,"") 		#9565 No additional information IS available.
			--LET l_idx = 1 
			--INITIALIZE l_arr_rec_prodinfo[l_idx].* TO NULL 
		ELSE 
			MESSAGE kandoomsg2("U",9113,l_arr_rec_prodinfo.GetSize()) 		#9113 l_idx records selected
		END IF 

		MESSAGE kandoomsg2("I",1501,"") 	#1501 TAB TO DISPLAY Product information.
		--OPTIONS INSERT KEY f36, 
		--DELETE KEY f36 

		DISPLAY ARRAY l_arr_rec_prodinfo TO sr_prodinfo.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","pinfowind","input-arr-prodinfo-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END DISPLAY

		CLOSE WINDOW I500 

		LET int_flag = false 
		LET quit_flag = false 

END FUNCTION 
###########################################################################
# END FUNCTION view_prodinfo(p_cmpy_code, p_part_code)
###########################################################################


############################################################
# FUNCTION view_prodinfo(p_part_code)
#
# Description: This FUNCTION allows the enquiry of product
#              information.
############################################################
FUNCTION input_prodinfo(p_part_code) 
	DEFINE l_cmpy_code LIKE company.cmpy_code
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_arr_rec_prodinfo DYNAMIC ARRAY OF t_rec_arr_prodinfo
	DEFINE l_rec_prodinfo_bkp t_rec_arr_prodinfo		# backup of this line before modifying
 	DEFINE l_arr_rec_prodinfo_prykey DYNAMIC ARRAY OF t_rec_prodinfo_prykey 
	DEFINE l_arr_rec_prodinfo_action DYNAMIC ARRAY OF t_rec_arr_action
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE l_counter INTEGER 
	DEFINE l_idx INTEGER 
	DEFINE l_arr_curr SMALLINT
	DEFINE l_scr_line SMALLINT
	DEFINE l_del_cnt SMALLINT 
 	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_operation_status INTEGER
	DEFINE l_command STRING 
	DEFINE crs_name STRING

	OPEN WINDOW I500 with FORM "I500" 
	CALL windecoration_i("I500") 

	IF p_part_code IS NULL THEN 
		ERROR kandoomsg2("I",5110,"") 	#5110 Logic Error: Product code does NOT exist.
		CLOSE WINDOW i500 
		RETURN 
	END IF 
	
	SELECT desc_text 
	INTO l_desc_text 
	FROM product 
	WHERE part_code = p_part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	DISPLAY p_part_code, l_desc_text 
	TO part_code,desc_text 

	
	MESSAGE kandoomsg2("U",1002,"") #1002 Searching database; Please wait.

	LET  crs_name = modu_crs_list_prodinfo.GetName() 
	IF crs_name IS NULL THEN
		# if this cursor has not been declared YET, we do declare it
		CALL declare_cursors_prodinfo ()
	ELSE
		CALL modu_crs_list_prodinfo.Close()
	END IF
	
	CALL modu_crs_list_prodinfo.Open(p_part_code,glob_rec_kandoouser.cmpy_code)
	LET l_idx = 1
	--FOREACH c_prodinfo2 INTO l_rowid, l_rec_prodinfo.* 
	WHILE modu_crs_list_prodinfo.FetchNext(l_arr_rec_prodinfo[l_idx].*,l_arr_rec_prodinfo_prykey[l_idx].*,l_arr_rec_prodinfo_action[l_idx].action_type) = 0
		LET l_idx = l_idx + 1 
	END WHILE
	ERROR kandoomsg2("U",9113,l_idx) 
	
	# l_idx is 1 ahead of number of elements, delete last element
	CALL l_arr_rec_prodinfo.DeleteElement(l_idx)
	CALL l_arr_rec_prodinfo_prykey.DeleteElement(l_idx)

	MESSAGE kandoomsg2("I",1502,"") 	#1502 F1 Add; F2 Delete; F6 Display; OK TO Continue.
	--OPTIONS INSERT KEY f1, 
	--DELETE KEY f36 

	LET l_del_cnt = 0 
	INPUT ARRAY l_arr_rec_prodinfo WITHOUT DEFAULTS 
	FROM sr_prodinfo.* ATTRIBUTE(UNBUFFERED) --,DELETE ROW = FALSE, INSERT ROW = FALSE, APPEND ROW = TRUE)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","pinfowind","input-arr-prodinfo-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
		
		ON ACTION "DELETE"
 
		BEFORE ROW 
			LET l_arr_curr = arr_curr() 
			LET l_scr_line = scr_line()
			LET l_rec_prodinfo_bkp.* = l_arr_rec_prodinfo[l_arr_curr].*

		BEFORE INSERT 
			INITIALIZE l_arr_rec_prodinfo[l_arr_curr].* TO NULL 
			INITIALIZE l_arr_rec_prodinfo_prykey[l_arr_curr].* TO NULL
			LET  l_arr_rec_prodinfo_action[l_arr_curr].action_type = "I"   # this will be an INSERT

		AFTER FIELD info_ind 
			IF l_arr_rec_prodinfo[l_arr_curr].info_ind IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered.
				LET l_arr_rec_prodinfo[l_arr_curr].info_ind = NULL 
				NEXT FIELD info_ind 
			END IF 

			IF l_arr_rec_prodinfo[l_arr_curr].info_ind NOT matches'[1234]' THEN 
				ERROR kandoomsg2("I",9566,"") 				#9566 Information indicator must be between 1 AND 4.
				LET l_arr_rec_prodinfo[l_arr_curr].info_ind = NULL 
				NEXT FIELD info_ind 
			END IF 
			
			SELECT response_text 
			INTO l_arr_rec_prodinfo[l_arr_curr].response_text 
			FROM kandooword 
			WHERE language_code = "ENG" 
			AND reference_code = l_arr_rec_prodinfo[l_arr_curr].info_ind 
			AND reference_text = "prodinfo.info_ind" 
			IF status = notfound THEN 
				LET l_arr_rec_prodinfo[l_arr_curr].response_text = "" 
			END IF 
			#         DISPLAY l_arr_rec_prodinfo[l_arr_curr].response_text
			#              TO sr_prodinfo[scrn].response_text

		AFTER FIELD public_flag 
			IF l_arr_rec_prodinfo[l_arr_curr].public_flag IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered.
				NEXT FIELD public_flag 
			END IF 
			IF l_arr_rec_prodinfo[l_arr_curr].public_flag NOT matches'[YN]' THEN 
				ERROR kandoomsg2("U",1026,"") 				#1026 Valid VALUES (Y)es OR (N)o.
				NEXT FIELD public_flag 
			END IF 

		AFTER FIELD filename_text 
			IF l_arr_rec_prodinfo[l_arr_curr].filename_text IS NULL THEN 
				ERROR kandoomsg2("A",9166,"") 				#9166 File name must be entered.
				NEXT FIELD filename_text 
			END IF 
			
		AFTER ROW
			IF FIELD_TOUCHED(sr_prodinfo[l_arr_curr].*) AND l_arr_rec_prodinfo_action[l_arr_curr].action_type <> "I" THEN
				LET l_arr_rec_prodinfo_action[l_arr_curr].action_type = "U"
			END IF
			LET l_arr_rec_prodinfo_prykey[l_arr_curr].cmpy_code = glob_rec_kandoouser.cmpy_code
			LET l_arr_rec_prodinfo_prykey[l_arr_curr].part_code = p_part_code
		
		AFTER INSERT
			IF FIELD_TOUCHED(sr_prodinfo[l_arr_curr].*) THEN
				LET l_arr_rec_prodinfo_action[l_arr_curr].action_type = "I"
				LET l_arr_rec_prodinfo_prykey[l_arr_curr].line_num = l_arr_curr
			END IF

		AFTER DELETE
			IF FIELD_TOUCHED(sr_prodinfo[l_arr_curr].*) THEN
				LET l_arr_rec_prodinfo_action[l_arr_curr].action_type = "D"
			END IF

		--AFTER INPUT 
			# wow wow wow wow wow !!!!!
			# useless, already done!
			 
			--IF not(int_flag OR quit_flag) THEN
			{ 
				IF l_arr_rec_prodinfo[l_arr_curr].info_ind IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered.
					NEXT FIELD info_ind 
				END IF 
				IF l_arr_rec_prodinfo[l_arr_curr].public_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered.
					NEXT FIELD public_flag 
				END IF 
				IF l_arr_rec_prodinfo[l_arr_curr].filename_text IS NULL THEN 
					ERROR kandoomsg2("A",9166,"") 					#9166 File name must be entered.
					NEXT FIELD filename_text 
				END IF 
			}
			--ELSE 

			--END IF 

	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		MESSAGE kandoomsg2("U",1005,"") 		#1005 Updating database; Please wait.
		--LET l_rec_prodinfo.part_code = p_part_code 
		--LET l_rec_prodinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
		WHENEVER SQLERROR CONTINUE
		LET l_operation_status = 0 # we will cumulate sqlca.sqlcode for each operation, if any negative, that's bad
		FOR l_idx = 1 TO arr_count() 
			CASE
			WHEN l_arr_rec_prodinfo_action[l_arr_curr].action_type = "I" 
				INSERT INTO prodinfo VALUES (
					l_arr_rec_prodinfo_prykey[l_idx].cmpy_code,
					l_arr_rec_prodinfo_prykey[l_idx].part_code,
					l_arr_rec_prodinfo[l_idx].info_ind,
					l_arr_rec_prodinfo[l_idx].public_flag,
					l_arr_rec_prodinfo[l_idx].filename_text,
					l_arr_rec_prodinfo_prykey[l_idx].line_num) 
				LET l_arr_rec_prodinfo_prykey[l_idx].part_code = l_arr_rec_prodinfo_prykey[l_idx].part_code
				LET l_arr_rec_prodinfo_prykey[l_idx].cmpy_code = l_arr_rec_prodinfo_prykey[l_idx].cmpy_code
				LET l_operation_status = sqlca.sqlcode + l_operation_status
			
			WHEN l_arr_rec_prodinfo_action[l_arr_curr].action_type = "U" 
				UPDATE prodinfo SET  
				(info_ind,public_flag,filename_text) = 
				(l_arr_rec_prodinfo[l_idx].info_ind,l_arr_rec_prodinfo[l_idx].public_flag,l_arr_rec_prodinfo[l_idx].filename_text) 
				WHERE part_code = l_arr_rec_prodinfo_prykey[l_idx].part_code 
				AND cmpy_code = l_arr_rec_prodinfo_prykey[l_idx].cmpy_code
				AND line_num = l_arr_rec_prodinfo_prykey[l_idx].line_num
				LET l_operation_status = sqlca.sqlcode + l_operation_status
			
			WHEN l_arr_rec_prodinfo_action[l_arr_curr].action_type = "D"
				DELETE FROM prodinfo
				WHERE part_code = l_arr_rec_prodinfo_prykey[l_idx].part_code 
				AND cmpy_code = l_arr_rec_prodinfo_prykey[l_idx].cmpy_code
				AND line_num = l_arr_rec_prodinfo_prykey[l_idx].line_num
				LET l_operation_status = sqlca.sqlcode + l_operation_status
			END CASE
			IF l_operation_status < 0 THEN
				ERROR "Insert of Product Info FAILED!"
				LET l_operation_status = 0
			END IF
		END FOR 
		
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		
		IF l_del_cnt > 0 THEN 
			IF kandoomsg("U",8000,l_del_cnt) = "Y" THEN #8000 Confirm TO delete XXX rows. 
				FOR l_idx = 1 TO arr_count() 
					--IF l_arr_rec_prodinfo[l_idx].scroll_flag = "*" THEN
					IF l_arr_rec_prodinfo_prykey[l_idx].cmpy_code IS NULL THEN 
						DELETE FROM prodinfo 
						WHERE part_code = l_arr_rec_prodinfo_prykey[l_idx].part_code 
						AND cmpy_code = l_arr_rec_prodinfo_prykey[l_idx].cmpy_code
						LET l_operation_status = sqlca.sqlcode + l_operation_status
 					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 

	CLOSE WINDOW I500 

	LET int_flag = false 
	LET quit_flag = false 
	RETURN l_operation_status

END FUNCTION 
############################################################
# END FUNCTION view_prodinfo(p_part_code)
############################################################
