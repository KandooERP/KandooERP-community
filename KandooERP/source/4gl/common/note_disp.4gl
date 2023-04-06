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

############################################################
# FUNCTION note_disp(p_cmpy_code,p_pass_note_code)
#
# brief module note_disp.4gl - DISPLAY note details
############################################################
FUNCTION note_disp(p_cmpy_code,p_pass_note_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_pass_note_code CHAR(12) 
	DEFINE l_rec_notes RECORD LIKE notes.* 
	DEFINE l_arr_rec_notes DYNAMIC ARRAY OF RECORD 
		note_text LIKE notes.note_text 
	END RECORD 
	DEFINE l_idx INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW U122 with FORM "U122" 
	CALL winDecoration_u("U122") 

	LET l_msgresp = kandoomsg("U",1008,"")	#1008 F3/F4 TO page Bwd/Fwd; OK TO Continue;
	DISPLAY p_pass_note_code TO notes.note_code 

	DECLARE c_note CURSOR FOR 
	SELECT * INTO l_rec_notes.* FROM notes 
	WHERE cmpy_code = p_cmpy_code 
	AND note_code = p_pass_note_code 
	ORDER BY note_num 
	
	LET l_idx = 0 

	FOREACH c_note 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_notes[l_idx].note_text = l_rec_notes.note_text 
	END FOREACH 

	DISPLAY ARRAY l_arr_rec_notes TO sr_notes.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","note_disp","display-arr-notes") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW U122 

END FUNCTION 
############################################################
# END FUNCTION note_disp(p_cmpy_code,p_pass_note_code)
############################################################