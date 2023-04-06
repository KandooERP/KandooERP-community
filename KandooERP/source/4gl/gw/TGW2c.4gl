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

	Source code beautified by beautify.pl on 2020-01-03 10:10:02	$Id: $
}



# FOR handling cursors FOR rpthead

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW2_GLOBALS.4gl" 

DEFINE 
mr_hdr RECORD 
	rowid INTEGER, 
	rpt_id LIKE rpthead.rpt_id END RECORD 

FUNCTION hdr_curs() 

	DEFINE 
	fv_s1 CHAR(1500) 

	CALL close_scurs_hdr() 

	-- having 1 = 1 in the query causes the optimizer TO make incorrect decisions.
	-- This will help performance WHERE no condition IS selected on the first
	-- SCREEN.

	IF gv_query_1 = " 1=1" THEN 
		LET gv_query_1 = NULL 
	ELSE 
		LET gv_query_1 = "AND ", gv_query_1 clipped 
	END IF 

	LET fv_s1 = "SELECT rpthead.rowid, rpthead.rpt_id ", 
	"FROM rpthead ", 
	"WHERE rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	gv_query_1 clipped, 
	" ORDER BY 2" 

	PREPARE s_1 FROM fv_s1 

	MESSAGE "Selecting records, please wait..." 

	DECLARE scurs_hdr 
	SCROLL CURSOR 
	with HOLD 
	FOR s_1 

	CALL open_scurs_hdr() 

END FUNCTION 



FUNCTION first_hdr() 

	MESSAGE "Selecting the first RECORD in queried SET, please wait..." 

	FETCH FIRST scurs_hdr INTO mr_hdr.* 
	IF status = notfound THEN 
		INITIALIZE mr_hdr.* TO NULL 
		INITIALIZE gr_rpthead.* TO NULL 
		ERROR "No records match the criteria" 
	ELSE 
		SELECT * 
		INTO gr_rpthead.* 
		FROM rpthead 
		WHERE rowid = mr_hdr.rowid 
		CALL disp_hdr() 
	END IF 

END FUNCTION 



FUNCTION last_hdr() 

	MESSAGE "Selecting the last RECORD in queried SET, please wait..." 

	FETCH LAST scurs_hdr INTO mr_hdr.* 
	IF status = notfound THEN 
		ERROR "No records match the criteria" 
		INITIALIZE mr_hdr.* TO NULL 
		INITIALIZE gr_rpthead.* TO NULL 
	ELSE 
		SELECT * 
		INTO gr_rpthead.* 
		FROM rpthead 
		WHERE rowid = mr_hdr.rowid 
		CALL disp_hdr() 
	END IF 

END FUNCTION 



FUNCTION next_hdr() 

	MESSAGE "Selecting the next RECORD in queried SET, please wait..." 

	FETCH NEXT scurs_hdr INTO mr_hdr.* 
	IF status = notfound THEN 
		ERROR "Last RECORD selected" 
	ELSE 
		SELECT * 
		INTO gr_rpthead.* 
		FROM rpthead 
		WHERE rowid = mr_hdr.rowid 
		CALL disp_hdr() 
	END IF 

END FUNCTION 



FUNCTION prev_hdr() 

	MESSAGE "Selecting the previous RECORD in queried SET, please wait..." 

	FETCH previous scurs_hdr INTO mr_hdr.* 
	IF status = notfound THEN 
		ERROR "First RECORD selected" 
	ELSE 
		SELECT * 
		INTO gr_rpthead.* 
		FROM rpthead 
		WHERE rowid = mr_hdr.rowid 
		CALL disp_hdr() 
	END IF 

END FUNCTION 



FUNCTION base_first_hdr() 

	MESSAGE "Selecting the first RECORD in queried SET, please wait..." 

	FETCH FIRST scurs_hdr INTO mr_hdr.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * 
		INTO gr_rpthead.* 
		FROM rpthead 
		WHERE rowid = mr_hdr.rowid 
		RETURN status 
	END IF 

END FUNCTION 



FUNCTION base_next_hdr() 

	FETCH NEXT scurs_hdr INTO mr_hdr.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * 
		INTO gr_rpthead.* 
		FROM rpthead 
		WHERE rowid = mr_hdr.rowid 
		RETURN status 
	END IF 

END FUNCTION 



FUNCTION base_abs_hdr(fv_idx) 

	DEFINE 
	fv_idx SMALLINT 

	FETCH absolute fv_idx scurs_hdr INTO mr_hdr.* 
	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * 
		INTO gr_rpthead.* 
		FROM rpthead 
		WHERE rowid = mr_hdr.rowid 
		RETURN status 
	END IF 

END FUNCTION 



FUNCTION close_scurs_hdr() 

	IF gv_scurs_hdr_open THEN 
		CLOSE scurs_hdr 
		LET gv_scurs_hdr_open = false 
	END IF 

END FUNCTION 



FUNCTION open_scurs_hdr() 

	IF gv_scurs_hdr_open THEN 
		CLOSE scurs_hdr 
	END IF 

	OPEN scurs_hdr 
	LET gv_scurs_hdr_open = true 

END FUNCTION 
