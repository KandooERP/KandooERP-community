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

	Source code beautified by beautify.pl on 2020-01-03 14:28:58	$Id: $
}



#   FOR handling cursors FOR rptline
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW4_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_line RECORD 
	rowid INTEGER, 
	rpt_id LIKE rptline.rpt_id 
END RECORD 


############################################################
# FUNCTION line_curs()
#
#
############################################################
FUNCTION line_curs() 
	DEFINE l_s1 CHAR(1500) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL close_scurs_line() 
	IF glob_query_1 = " 1=1" THEN 
		LET l_s1 = "SELECT rpthead.rowid, rpthead.rpt_id ", 
		"FROM rpthead ", 
		"WHERE rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"ORDER BY 2" 
	ELSE 
		LET l_s1 = "SELECT rpthead.rowid, rpthead.rpt_id ", 
		"FROM rpthead ", 
		"WHERE rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", glob_query_1 clipped, 
		" ORDER BY 2" 
	END IF 
	PREPARE s_1 FROM l_s1 
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database - Please Wait
	DECLARE scurs_line SCROLL CURSOR with HOLD FOR s_1 
	#SET explain on ###
	CALL open_scurs_line() 

END FUNCTION #line_curs() 


############################################################
# FUNCTION first_line()
#
#
############################################################
FUNCTION first_line() 

	FETCH FIRST scurs_line INTO modu_rec_line.* 
	IF status = NOTFOUND THEN 
		INITIALIZE modu_rec_line.* TO NULL 
		INITIALIZE glob_rec_rptline.* TO NULL 
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = modu_rec_line.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION #first_line() 



############################################################
# FUNCTION last_line()
#
#
############################################################
FUNCTION last_line() 

	FETCH LAST scurs_line INTO modu_rec_line.* 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = modu_rec_line.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION #last_line() 


############################################################
# FUNCTION next_line()
#
#
############################################################
FUNCTION next_line() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH NEXT scurs_line INTO modu_rec_line.* 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9157,"") 
		#9157 You have reached the END of the entries selected.
		CALL last_line() 
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = modu_rec_line.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION #next_line() 


############################################################
# FUNCTION FUNCTION prev_line()
#
#
############################################################
FUNCTION prev_line() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH previous scurs_line INTO modu_rec_line.* 
	IF status = NOTFOUND THEN 
		CALL first_line() 
		LET l_msgresp = kandoomsg("G",9156,"") 
		#9157 You have reached the start of the entries selected.
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = modu_rec_line.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION #prev_line() 


############################################################
# FUNCTION base_first_line()
#
#
############################################################
FUNCTION base_first_line() 

	FETCH FIRST scurs_line INTO modu_rec_line.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = modu_rec_line.rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 
END FUNCTION #base_first_line() 


############################################################
# FUNCTION base_first_line()
#
#
############################################################
FUNCTION base_next_line() 

	FETCH NEXT scurs_line INTO modu_rec_line.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = modu_rec_line.rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 
END FUNCTION #base_next_line() 


############################################################
# FUNCTION base_abs_line(p_idx)
#
#
############################################################
FUNCTION base_abs_line(p_idx) 
	DEFINE p_idx SMALLINT 

	FETCH absolute p_idx scurs_line INTO modu_rec_line.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = modu_rec_line.rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 
END FUNCTION #base_abs_line() 


############################################################
# FUNCTION close_scurs_line()
#
#
############################################################
FUNCTION close_scurs_line() 

	IF gv_scurs_line_open THEN 
		CLOSE scurs_line 
		LET gv_scurs_line_open = false 
	END IF 

END FUNCTION #close_scurs_line() 

############################################################
# FUNCTION open_scurs_line()
#
#
############################################################
FUNCTION open_scurs_line() 

	IF gv_scurs_line_open THEN 
		CLOSE scurs_line 
	END IF 
	OPEN scurs_line 
	LET gv_scurs_line_open = true 

END FUNCTION #open_scurs_line() 
