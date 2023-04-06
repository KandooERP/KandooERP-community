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

	Source code beautified by beautify.pl on 2020-01-03 14:28:56	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "GW2_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_hdr RECORD 
	rowid INTEGER, 
	rpt_id LIKE rpthead.rpt_id 
END RECORD 


############################################################
# FUNCTION hdr_curs()
#
#
############################################################
FUNCTION hdr_curs() 
	DEFINE l_s1 CHAR(1500) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL close_scurs_hdr() 
	# having 1 = 1 in the query causes the optimizer TO make incorrect decisions.
	# This will help performance WHERE no condition IS selected on the first
	# SCREEN.
	IF glob_query_1 = " 1=1" THEN 
		LET glob_query_1 = NULL 
	ELSE 
		LET glob_query_1 = "AND ", glob_query_1 clipped 
	END IF 
	LET l_msgresp = kandoomsg("U",1002,"") 
	LET l_s1 = "SELECT rpthead.rowid, rpthead.rpt_id ", 
	"FROM rpthead ", 
	"WHERE rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	glob_query_1 clipped, 
	" ORDER BY 2" 
	PREPARE s_1 FROM l_s1 
	DECLARE scurs_hdr 
	SCROLL CURSOR 
	with HOLD 
	FOR s_1 
	CALL open_scurs_hdr() 
END FUNCTION 


############################################################
# FUNCTION first_hdr()
#
#
############################################################
FUNCTION first_hdr() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH FIRST scurs_hdr INTO modu_rec_hdr.* 
	IF status = NOTFOUND THEN 
		INITIALIZE modu_rec_hdr.* TO NULL 
		INITIALIZE glob_rec_rpthead.* TO NULL 
		LET l_msgresp = kandoomsg("G",9516,"") 
		#9516 No entries satisfied selection criteria
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = modu_rec_hdr.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION 


############################################################
# FUNCTION last_hdr()
#
#
############################################################
FUNCTION last_hdr() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH LAST scurs_hdr INTO modu_rec_hdr.* 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9516,"") 
		#9516 No entries satisfied selection criteria
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = modu_rec_hdr.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION 


############################################################
# FUNCTION next_hdr()
#
#
############################################################
FUNCTION next_hdr() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH NEXT scurs_hdr INTO modu_rec_hdr.* 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9157,"") 
		#9157 You have reached the END of the entries selected
		CALL last_hdr() 
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = modu_rec_hdr.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION 


############################################################
# FUNCTION prev_hdr()
#
#
############################################################
FUNCTION prev_hdr() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH previous scurs_hdr INTO modu_rec_hdr.* 
	IF status = NOTFOUND THEN 
		CALL first_hdr() 
		LET l_msgresp = kandoomsg("G",9156,"") 
		#9157 You have reached the start of the entries selected
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = modu_rec_hdr.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION #prev_hdr() 

############################################################
# FUNCTION base_first_hdr()
#
#
############################################################
FUNCTION base_first_hdr() 
	FETCH FIRST scurs_hdr INTO modu_rec_hdr.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = modu_rec_hdr.rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 
END FUNCTION 


############################################################
# FUNCTION base_next_hdr()
#
#
############################################################
FUNCTION base_next_hdr() 
	FETCH NEXT scurs_hdr INTO modu_rec_hdr.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = modu_rec_hdr.rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 
END FUNCTION 


############################################################
# FUNCTION base_abs_hdr(p_idx)
#
#
############################################################
FUNCTION base_abs_hdr(p_idx) 
	DEFINE p_idx SMALLINT 

	FETCH absolute p_idx scurs_hdr INTO modu_rec_hdr.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = modu_rec_hdr.rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 
END FUNCTION 


############################################################
# FUNCTION close_scurs_hdr()
#
#
############################################################
FUNCTION close_scurs_hdr() 
	IF glob_scurs_hdr_open THEN 
		CLOSE scurs_hdr 
		LET glob_scurs_hdr_open = false 
	END IF 
END FUNCTION 



############################################################
# FUNCTION open_scurs_hdr()
#
#
############################################################
FUNCTION open_scurs_hdr() 
	IF glob_scurs_hdr_open THEN 
		CLOSE scurs_hdr 
	END IF 
	OPEN scurs_hdr 
	LET glob_scurs_hdr_open = true 
END FUNCTION 
