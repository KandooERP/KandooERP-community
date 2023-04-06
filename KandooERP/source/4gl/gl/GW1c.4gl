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

	Source code beautified by beautify.pl on 2020-01-03 14:28:55	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW1_GLOBALS.4gl" 


############################################################
# FUNCTION rpt_width()
# RETURN total REPORT width.
#
#
############################################################
FUNCTION rpt_width() #return total REPORT width. 
	DEFINE l_width LIKE rptcol.width 

	SELECT sum(width) INTO l_width FROM rptcol 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 
	IF l_width < 80 
	OR l_width IS NULL THEN #default length. 
		LET l_width = 80 
	END IF 
	RETURN l_width 
END FUNCTION 


############################################################
# FUNCTION rpt_line(p_width)
#
# build REPORT '-' line.
############################################################
FUNCTION rpt_line(p_width) #build REPORT '-' line. 
	DEFINE p_width LIKE rptcol.width 
	DEFINE l_rpt_line CHAR(330) 
	DEFINE l_inc INTEGER 

	LET l_rpt_line = "-" 
	FOR l_inc = 1 TO p_width 
		LET l_rpt_line = l_rpt_line clipped, "-" 
	END FOR 
	RETURN l_rpt_line 
END FUNCTION 


############################################################
#FUNCTION desc_positions( p_width )
#
# FUNCTION:        REPORT header description
# Description:     FUNCTION TO build the REPORT header titles,
#                  AND position them according TO rpthead.rpt_desc_position.
############################################################
FUNCTION desc_positions(p_width) 
	DEFINE p_width LIKE rptcol.width 
	DEFINE l_len INTEGER 
	DEFINE l_desc_pos1 INTEGER 
	DEFINE l_desc_pos2 INTEGER 

	CASE 
		WHEN glob_rec_rpthead.rpt_desc_position = 'L' #left justified. 
			LET l_desc_pos1 = 1 
			LET l_desc_pos2 = 1 
		WHEN glob_rec_rpthead.rpt_desc_position = 'R' #right justified. 
			LET l_len = p_width - length(glob_rec_rpthead.rpt_desc1) + 1 
			LET l_desc_pos1 = l_len 
			LET l_len = p_width - length(glob_rec_rpthead.rpt_desc2) + 1 
			LET l_desc_pos2 = l_len 
		OTHERWISE # default TO centred. 
			LET l_len = (p_width / 2) - (length(glob_rec_rpthead.rpt_desc1) / 2) 
			LET l_desc_pos1 = l_len 
			LET l_len = (p_width / 2) - (length(glob_rec_rpthead.rpt_desc2) / 2) 
			LET l_desc_pos2 = l_len 
	END CASE 
	RETURN l_desc_pos1, l_desc_pos2 
END FUNCTION 


############################################################
# FUNCTION col_hdr_desc(p_line_num)
#
# build REPORT COLUMN header line.
############################################################
FUNCTION col_hdr_desc(p_line_num) # build REPORT COLUMN HEADER line. 
	DEFINE p_line_num INTEGER 
	DEFINE l_pos INTEGER 
	DEFINE l_inc INTEGER 
	DEFINE l_col_line CHAR(330) 
	DEFINE l_col_desc LIKE rptcoldesc.col_desc 
	DEFINE l_width LIKE rptcol.width 

	DECLARE colhdr_curs CURSOR FOR 
	SELECT rptcoldesc.col_desc, rptcol.width, rptcol.col_id 
	FROM rptcol, outer (rptcoldesc) 
	WHERE rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rptcol.rpt_id = glob_rec_rpthead.rpt_id 
	AND rptcoldesc.cmpy_code = rptcol.cmpy_code 
	AND rptcoldesc.rpt_id = rptcol.rpt_id 
	AND rptcoldesc.col_uid = rptcol.col_uid 
	AND rptcoldesc.seq_num = p_line_num 
	ORDER BY rptcol.col_id 
	LET l_pos = 1 
	LET l_col_line = "" 
	FOREACH colhdr_curs INTO l_col_desc, l_width 
		IF l_col_desc IS NULL THEN 
			LET l_col_desc = " " 
		END IF 
		IF l_width > 0 THEN 
			LET l_col_line = l_col_line[1,l_pos], l_col_desc[1,l_width] 
			IF l_pos = 1 THEN LET l_pos = 0 END IF 
				LET l_pos = l_pos + l_width 
			END IF 
		END FOREACH 

		RETURN l_col_line 
END FUNCTION 


############################################################
# FUNCTION desc_col(p_col_uid)
#
#
############################################################
FUNCTION desc_col(p_col_uid) 
	DEFINE p_col_uid LIKE rptcol.col_uid 
	DEFINE l_found INTEGER 

	SELECT count(*) INTO l_found FROM colitem, mrwitem 
	WHERE colitem.col_uid = p_col_uid 
	AND mrwitem.item_id = colitem.col_item 
	AND mrwitem.item_type = glob_rec_mrwparms.constant_item_type 
	AND colitem.cmpy_code = glob_rec_kandoouser.cmpy_code 
	RETURN l_found 
	#RETURN TRUE IF description OTHERWISE FALSE.
END FUNCTION 


############################################################
# FUNCTION col_desc(p_line_uid, p_col_uid, p_width)
# RETURN the COLUMN description FOR a line.
#
############################################################
FUNCTION col_desc(p_line_uid, p_col_uid, p_width) 
	DEFINE p_line_uid LIKE rptline.line_uid 
	DEFINE p_col_uid LIKE rptcol.col_uid 
	DEFINE p_width LIKE rptcol.width 
	DEFINE l_line_desc LIKE descline.line_desc 

	IF glob_rec_entry_criteria.detailed_rpt = "D" 
	AND glob_rec_rptline.line_type = glob_rec_mrwparms.gl_line_type THEN 
		LET l_line_desc = glob_account_code 
	ELSE 
		SELECT line_desc INTO l_line_desc FROM descline 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = glob_rec_rpthead.rpt_id 
		AND line_uid = p_line_uid 
		AND col_uid = p_col_uid 
		IF status != NOTFOUND THEN 
			LET l_line_desc = l_line_desc[1,p_width] 
		END IF 
	END IF 
	RETURN l_line_desc 
END FUNCTION 


############################################################
# FUNCTION max_columns()
# RETURN maximum number of columns.
#
#
############################################################
FUNCTION max_columns() 
	DEFINE l_kandoo_columns INTEGER 

	SELECT max(col_id) INTO l_kandoo_columns FROM rptcol 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 
	IF l_kandoo_columns IS NULL THEN 
		LET l_kandoo_columns = 0 
	END IF 
	RETURN l_kandoo_columns 
END FUNCTION 


############################################################
# FUNCTION under_line(p_line_uid, p_col_uid, p_width, p_amt_picture)
# #RETURN the COLUMN underline FOR a line.
#
#
############################################################
FUNCTION under_line(p_line_uid, p_col_uid, p_width, p_amt_picture) 
	DEFINE p_line_uid LIKE rptline.line_uid 
	DEFINE p_col_uid LIKE rptcol.col_uid 
	DEFINE p_width LIKE rptcol.width 
	DEFINE p_amt_picture LIKE rptcol.amt_picture 
	DEFINE l_underline LIKE descline.line_desc 
	DEFINE l_rec_txttype RECORD LIKE txttype.* 
	DEFINE l_inc INTEGER 
	DEFINE l_len INTEGER 

	SELECT txttype.txttype_char, txttype.continuous 
	INTO l_rec_txttype.txttype_char, l_rec_txttype.continuous 
	FROM txtline, txttype 
	WHERE txtline.line_uid = p_line_uid 
	AND txttype.txttype_id = txtline.txt_type 
	AND txtline.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status != NOTFOUND THEN 
		IF l_rec_txttype.continuous = "Y" THEN 
			FOR l_inc = 1 TO p_width 
				LET l_underline = l_underline clipped, l_rec_txttype.txttype_char 
			END FOR 
		ELSE 
			IF NOT desc_col(p_col_uid) THEN 
				# Line width IS determined by the amt_picture length.
				LET l_len = length( p_amt_picture ) 
				FOR l_inc = 1 TO l_len 
					LET l_underline = l_underline clipped, l_rec_txttype.txttype_char 
				END FOR 
			END IF 
		END IF 
	END IF 

	RETURN l_underline 
END FUNCTION 
