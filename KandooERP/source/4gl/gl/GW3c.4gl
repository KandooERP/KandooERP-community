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

	Source code beautified by beautify.pl on 2020-01-03 14:28:57	$Id: $
}



# FOR handling cursors FOR rptcol
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW3_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_col 
RECORD 
	rpt_rowid INTEGER, 
	rpt_id LIKE rptcol.rpt_id, 
	col_rowid INTEGER, 
	col_id LIKE rptcol.col_id 
END RECORD 



############################################################
# FUNCTION col_curs()
#
#
############################################################
FUNCTION col_curs() 
	DEFINE l_s1 CHAR(1500) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL close_scurs_col() 

	IF glob_query_1 = " 1=1" THEN 
		LET l_s1 = "SELECT rpthead.rowid, rpthead.rpt_id, ", 
		" rptcol.rowid, rptcol.col_id ", 
		"FROM rpthead, outer(rptcol) ", 
		"WHERE rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND rpthead.cmpy_code = rptcol.cmpy_code ", 
		"AND rpthead.rpt_id = rptcol.rpt_id ", 
		" ORDER BY 2, 4" 
	ELSE 
		LET l_s1 = "SELECT rpthead.rowid, rpthead.rpt_id, ", 
		" rptcol.rowid, rptcol.col_id ", 
		"FROM rpthead, rptcol ", 
		"WHERE rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND rpthead.cmpy_code = rptcol.cmpy_code ", 
		"AND rpthead.rpt_id = rptcol.rpt_id ", 
		"AND ", glob_query_1 clipped, 
		" ORDER BY 2, 4" 
	END IF 


	PREPARE s_1 FROM l_s1 
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database - Please Wait.
	DECLARE scurs_col 
	SCROLL CURSOR 
	with HOLD 
	FOR s_1 

	CALL open_scurs_col() 
END FUNCTION #col_curs() 


############################################################
# FUNCTION first_col()
#
#
############################################################
FUNCTION first_col() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH FIRST scurs_col INTO modu_col.* 
	IF status = NOTFOUND THEN 
		INITIALIZE modu_col.* TO NULL 
		INITIALIZE glob_rec_rptcol.* TO NULL 
		CALL close_scurs_col() 
	END IF 

	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = modu_col.rpt_id 

	IF modu_col.col_id IS NOT NULL THEN 
		SELECT * INTO glob_rec_rptcol.* FROM rptcol 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = modu_col.rpt_id 
		AND col_id = modu_col.col_id 
	ELSE 
		INITIALIZE glob_rec_rptcol TO NULL 
	END IF 

END FUNCTION #first_col() 




############################################################
# FUNCTION last_col()
#
#
############################################################
FUNCTION last_col() 
	FETCH LAST scurs_col INTO modu_col.* 
END FUNCTION #last_col() 


############################################################
# FUNCTION next_col()
#
#
############################################################
FUNCTION next_col() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH NEXT scurs_col INTO modu_col.* 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9157,"") 
		#9157 You have reached the END of the entris selected.
		CALL last_col() 
	ELSE 
		CALL slct_col() 
	END IF 

END FUNCTION #next_col() 


############################################################
# FUNCTION prev_col()
#
#
############################################################
FUNCTION prev_col() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH previous scurs_col INTO modu_col.* 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9156,"") 
		#9156 You have reached the start of the entris selected.
		CALL first_col() 
	ELSE 
		CALL slct_col() 
	END IF 
END FUNCTION #prev_col() 


############################################################
# FUNCTION slct_col()
#
#
############################################################
FUNCTION slct_col() 

	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = modu_col.rpt_id 

	IF modu_col.col_rowid IS NOT NULL THEN 
		SELECT * INTO glob_rec_rptcol.* FROM rptcol 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = modu_col.rpt_id 
		AND col_id = modu_col.col_id 
	ELSE 
		INITIALIZE glob_rec_rptcol TO NULL 
	END IF 

END FUNCTION 


############################################################
# FUNCTION base_first_col()
#
#
############################################################
FUNCTION base_first_col() 

	FETCH FIRST scurs_col INTO modu_col.* 

	IF status THEN 
		RETURN status 
	ELSE 
		IF modu_col.col_rowid IS NOT NULL THEN 
			SELECT * INTO glob_rec_rptcol.* FROM rptcol 
			WHERE rowid = modu_col.col_rowid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		ELSE 
			INITIALIZE glob_rec_rptcol TO NULL 
		END IF 

		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = modu_col.rpt_rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 

END FUNCTION #base_first_col() 


############################################################
# FUNCTION base_next_col()
#
#
############################################################
FUNCTION base_next_col() 

	FETCH NEXT scurs_col INTO modu_col.* 
	IF status THEN 
		RETURN status 
	ELSE 
		IF modu_col.col_rowid IS NOT NULL THEN 
			SELECT * INTO glob_rec_rptcol.* FROM rptcol 
			WHERE rowid = modu_col.col_rowid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		ELSE 
			INITIALIZE glob_rec_rptcol TO NULL 
		END IF 

		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = modu_col.rpt_rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 

END FUNCTION #base_next_col() 


############################################################
# FUNCTION base_abs_col(p_idx)
#
#
############################################################
FUNCTION base_abs_col(p_idx) 
	DEFINE p_idx SMALLINT 

	FETCH absolute p_idx scurs_col INTO modu_col.* 

	IF status THEN 
		RETURN status 
	ELSE 
		IF modu_col.col_rowid IS NOT NULL THEN 
			SELECT * INTO glob_rec_rptcol.* FROM rptcol 
			WHERE rowid = modu_col.col_rowid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		ELSE 
			INITIALIZE glob_rec_rptcol TO NULL 
		END IF 

		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = modu_col.rpt_rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 

END FUNCTION #base_abs_col() 


############################################################
# FUNCTION close_scurs_col()
#
#
############################################################
FUNCTION close_scurs_col() 

	IF glob_scurs_col_open THEN 
		CLOSE scurs_col 
		LET glob_scurs_col_open = false 
	END IF 

END FUNCTION #close_scurs_col() 




############################################################
# FUNCTION open_scurs_col()
#
#
############################################################
FUNCTION open_scurs_col() 

	IF glob_scurs_col_open THEN 
		CLOSE scurs_col 
	END IF 

	OPEN scurs_col 
	LET glob_scurs_col_open = true 

END FUNCTION #open_scurs_col() 
