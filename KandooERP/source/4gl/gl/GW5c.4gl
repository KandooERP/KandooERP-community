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

	Source code beautified by beautify.pl on 2020-01-03 14:28:59	$Id: $
}



#      FOR handling cursors FOR def_rpt
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW5_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE 
mr_def RECORD 
	rowid INTEGER, 
	rpt_id LIKE rpthead.rpt_id 
END RECORD 
DEFINE l_msgresp LIKE language.yes_flag 


############################################################
# FUNCTION def_curs()
#
#
############################################################
FUNCTION def_curs() 
	DEFINE l_s1 CHAR(1500) 

	CALL close_scurs_def() 
	IF glob_query_1 = " 1=1" THEN 
		LET glob_query_1 = NULL 
	ELSE 
		LET glob_query_1 = "AND ", glob_query_1 clipped 
	END IF 

	#SET up the SELECT statement
	LET l_s1 = "SELECT rpthead.rowid, rpthead.rpt_id ", 
	"FROM rpthead ", 
	"WHERE rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	glob_query_1 clipped, 
	" ORDER BY 2" 

	PREPARE s_1 FROM l_s1 

	# now DECLARE a CURSOR FOR the relevant info in the cheque table

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database please wait
	DECLARE scurs_def 
	SCROLL CURSOR 
	with HOLD 
	FOR s_1 

	CALL open_scurs_def() 

END FUNCTION #def_curs() 



############################################################
# FUNCTION first_def()
#
#
############################################################
FUNCTION first_def() 

	FETCH FIRST scurs_def INTO mr_def.* 
	IF status = NOTFOUND THEN 
		INITIALIZE mr_def.* TO NULL 
		INITIALIZE glob_rec_rpthead.* TO NULL 
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = mr_def.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION #first_def() 


############################################################
# FUNCTION last_def()
#
#
############################################################
FUNCTION last_def() 

	FETCH LAST scurs_def INTO mr_def.* 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = mr_def.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION #last_def() 


############################################################
# FUNCTION next_def()
#
#
############################################################
FUNCTION next_def() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH NEXT scurs_def INTO mr_def.* 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G","9157","") 
		#9157 You have reached the END of the entries selected.
		CALL last_def() 
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = mr_def.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION #next_def() 


############################################################
# FUNCTION prev_def()
#
#
############################################################
FUNCTION prev_def() 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH previous scurs_def INTO mr_def.* 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G","9156","") 
		#9157 You have reached the start of the entries selected.
		CALL first_def() 
	END IF 
	SELECT * INTO glob_rec_rpthead.* FROM rpthead 
	WHERE rowid = mr_def.rowid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION #prev_def() 



############################################################
# FUNCTION base_first_def()
#
#
############################################################
FUNCTION base_first_def() 

	FETCH FIRST scurs_def INTO mr_def.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = mr_def.rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 
END FUNCTION #base_first_def() 


############################################################
# FUNCTION base_next_def()
#
#
############################################################
FUNCTION base_next_def() 

	FETCH NEXT scurs_def INTO mr_def.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = mr_def.rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 

END FUNCTION #base_next_def() 


############################################################
# FUNCTION base_abs_def(p_idx)
#
#
############################################################
FUNCTION base_abs_def(p_idx) 
	DEFINE p_idx SMALLINT 

	FETCH absolute p_idx scurs_def INTO mr_def.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * INTO glob_rec_rpthead.* FROM rpthead 
		WHERE rowid = mr_def.rowid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		RETURN status 
	END IF 

END FUNCTION #base_abs_def() 

############################################################
# FUNCTION close_scurs_def()
#
#
############################################################
FUNCTION close_scurs_def() 

	IF glob_scurs_def_open THEN 
		CLOSE scurs_def 
		LET glob_scurs_def_open = false 
	END IF 

END FUNCTION #close_scurs_def() 


############################################################
# FUNCTION open_scurs_def()
#
#
############################################################
FUNCTION open_scurs_def() 

	IF glob_scurs_def_open THEN 
		CLOSE scurs_def 
	END IF 

	OPEN scurs_def 
	LET glob_scurs_def_open = true 

END FUNCTION #open_scurs_def() 
