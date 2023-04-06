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

	Source code beautified by beautify.pl on 2020-01-02 10:35:19	$Id: $
}




############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION disp_note(p_cmpy, p_noter_code)
#
#
############################################################
FUNCTION disp_note(p_cmpy,p_noter_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_noter_code LIKE notes.note_code 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_notes RECORD LIKE notes.* 
	DEFINE l_arr_rec_notes DYNAMIC ARRAY OF # [200] OF 
	RECORD 
		note_text CHAR(60) 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW u122 with FORM "U122" 
	CALL winDecoration_u("U122") 

	LET l_msgresp = kandoomsg("U", 1002, "") 
	#1002 Searching Database;  Please wait.
	LET l_rec_notes.note_code = p_noter_code 
	DISPLAY BY NAME l_rec_notes.note_code 
	DECLARE c_note CURSOR FOR 
	SELECT * INTO l_rec_notes.* 
	FROM notes 
	WHERE notes.cmpy_code = p_cmpy 
	AND notes.note_code = l_rec_notes.note_code 
	ORDER BY note_num 
	LET l_idx = 0 

	FOREACH c_note 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_notes[l_idx].note_text = l_rec_notes.note_text 
	END FOREACH 

	#   CALL set_count(l_idx)
	LET l_msgresp = kandoomsg("U", 1008, "") 
	#1008 F3/F4 TO Page Fwd/Bwd;  Press OK TO Continue.

	DISPLAY ARRAY l_arr_rec_notes TO sr_notes.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","notewind","display-arr-notes") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW u122 

END FUNCTION 


