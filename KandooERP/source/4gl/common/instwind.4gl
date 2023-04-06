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

#################################################################
# FUNCTION inv_story(p_cmpy, p_cust, p_invnum)
#
# DISPLAY invoice story details with ability TO change information
#################################################################
FUNCTION inv_story(p_cmpy,p_cust,p_invnum) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code
	DEFINE p_invnum LIKE invoicehead.inv_num 

--	OPTIONS INSERT KEY f1, 
--	DELETE KEY f2 
	CALL in_notes(p_cmpy,p_cust,p_invnum) 

	CLOSE WINDOW A118 

--	OPTIONS INSERT KEY f36, 
--	DELETE KEY f36 
END FUNCTION 
#################################################################
# END FUNCTION inv_story(p_cmpy, p_cust, p_invnum)
#################################################################


#################################################################
# FUNCTION in_notes(p_cmpy, cust, p_invnum)
#
#
#################################################################
FUNCTION in_notes(p_cmpy,p_cust,p_invnum) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_invnum LIKE invoicehead.inv_num 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_invstory RECORD LIKE invstory.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_invstory DYNAMIC ARRAY OF RECORD 
				note_date LIKE invstory.note_date, 
				note_text LIKE invstory.note_text 
			 END RECORD 
	DEFINE l_temp RECORD 
				cust_code LIKE customer.cust_code 
			 END RECORD 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT
	DEFINE l_flag SMALLINT

	OPEN WINDOW A118 with FORM "A118" 
	CALL windecoration_a("A118") 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 

	IF status = notfound THEN 
		ERROR kandoomsg2("A",9067,p_cust)	#9067 "Logic Error: Customer XXXX does NOT exist"
		RETURN 
	END IF 

	LET l_temp.cust_code = p_cust 
	LET l_rec_invstory.cust_code = p_cust 
	LET l_rec_invstory.inv_num = p_invnum 

	DISPLAY BY NAME 
		l_rec_customer.name_text, 
		l_rec_invstory.cust_code, 
		l_rec_customer.contact_text, 
		l_rec_invstory.inv_num, 
		l_rec_customer.tele_text 

	DECLARE c_note CURSOR FOR 
	SELECT * INTO l_rec_invstory.* FROM invstory 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = l_temp.cust_code 
	AND inv_num = l_rec_invstory.inv_num 
	ORDER BY cust_code, inv_num, note_num 

	LET l_idx = 0 
	FOREACH c_note 
		LET l_idx = l_idx + 1 
		LET l_arr_invstory[l_idx].note_date = l_rec_invstory.note_date 
		LET l_arr_invstory[l_idx].note_text = l_rec_invstory.note_text 
	END FOREACH 

	MESSAGE kandoomsg2("U",1004,"")	#1036 "Enter invoice story - ESC TO continue..."

	--CALL fgl_winmessage("huho","Please check this at runtime/debug.\nChanged TO display array\nbut we may need TO change it back TO input array","info") 
	INPUT ARRAY l_arr_invstory WITHOUT DEFAULTS FROM sr_invstory.* ATTRIBUTE(UNBUFFERED, insert row = false)
	#DISPLAY ARRAY l_arr_invstory TO sr_invstory.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT
			CALL publish_toolbar("kandoo","instwind","input-arr-invstory") 
 			CALL dialog.setActionHidden("control-e",NOT l_arr_invstory.getSize())
 			CALL dialog.setActionHidden("DELETE",NOT l_arr_invstory.getSize())

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_invstory.note_date = l_arr_invstory[l_idx].note_date 
			LET l_rec_invstory.note_text = l_arr_invstory[l_idx].note_text 
			LET l_flag = 0 

		ON ACTION "UNDO" --ON KEY (control-e) #?? what the f... is this ?
			IF (l_idx > 0) AND (l_idx <= l_arr_invstory.getSize()) THEN
				IF l_rec_invstory.note_date IS NOT NULL AND l_rec_invstory.note_text IS NOT NULL THEN
					LET l_arr_invstory[l_idx].note_date = l_rec_invstory.note_date 
					LET l_arr_invstory[l_idx].note_text = l_rec_invstory.note_text 
				END IF
			END IF

		BEFORE INSERT
			LET l_idx = arr_curr() 
			LET l_arr_invstory[l_idx].note_date = today
		
			#NEXT FIELD note_text

			#   BEFORE INSERT  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! may need TO turn it back TO input array
			#      LET l_idx = arr_curr()
			#      #LET scrn = scr_line()
			#      LET l_arr_invstory[l_idx].note_date = today
			#      #DISPLAY l_arr_invstory[l_idx].note_date TO sr_invstory[scrn].note_date

			#Moved TO AFTER the display array
			AFTER INPUT
			  LET l_rec_invstory.cmpy_code = p_cmpy
			  LET l_rec_invstory.cust_code = l_temp.cust_code
			
			      DELETE FROM invstory
			         WHERE cmpy_code = p_cmpy
			           AND cust_code = l_temp.cust_code
			           AND inv_num = l_rec_invstory.inv_num
			
			      FOR i  = 1 TO l_arr_invstory.getSize()
			         IF l_arr_invstory[i].note_date IS NOT NULL THEN
			            INSERT INTO invstory VALUES (l_rec_invstory.cmpy_code,
			                                         l_temp.cust_code,
			                                         l_rec_invstory.inv_num,
			                                         i,
			                                         l_arr_invstory[i].note_date,
			                                         l_arr_invstory[i].note_text)
			         END IF
			      END FOR

		
	END INPUT 
	########################

	IF int_flag THEN 
		LET int_flag = false 
	ELSE 

		LET l_rec_invstory.cmpy_code = p_cmpy 
		LET l_rec_invstory.cust_code = l_temp.cust_code 

		DELETE FROM invstory 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_temp.cust_code 
		AND inv_num = l_rec_invstory.inv_num 

		FOR i = 1 TO arr_count() 
			IF l_arr_invstory[i].note_date IS NOT NULL THEN 
				INSERT INTO invstory VALUES (l_rec_invstory.cmpy_code, 
				l_temp.cust_code, 
				l_rec_invstory.inv_num, 
				i, 
				l_arr_invstory[i].note_date, 
				l_arr_invstory[i].note_text) 
			END IF 
		END FOR 

		#Update invoicehead with new story_flag status
		#if one ore more stories exist, invoicehead.story_flag = "Y" (otherwise "N")
		IF l_arr_invstory.getSize() = 0 THEN #If there are one ore more stories, set story_ flag = "Y"
			UPDATE invoicehead 
			SET story_flag = "N"
			WHERE cmpy_code = l_rec_invstory.cmpy_code
			AND cust_code = l_temp.cust_code
			AND inv_num = l_rec_invstory.inv_num
			 
		ELSE 
			UPDATE invoicehead 
			SET story_flag = "Y"
			WHERE cmpy_code = l_rec_invstory.cmpy_code
			AND cust_code = l_temp.cust_code
			AND inv_num = l_rec_invstory.inv_num

		END IF


	END IF 

	LET int_flag = 0
	LET quit_flag = 0
END FUNCTION 
#################################################################
# END FUNCTION in_notes(p_cmpy, cust, p_invnum)
#################################################################