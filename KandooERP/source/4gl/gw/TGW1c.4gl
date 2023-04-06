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

	Source code beautified by beautify.pl on 2020-01-03 10:10:01	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW1_GLOBALS.4gl" 



{ FUNCTION:        REPORT width
  Description:     FUNCTION TO RETURN the total REPORT width.
}
FUNCTION rpt_width() 

	DEFINE fv_width LIKE rptcol.width 

	SELECT sum(width) INTO fv_width 
	FROM rptcol 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND col_code = gr_rptcolgrp.col_code 
	IF fv_width < 80 OR fv_width IS NULL THEN #default length. 
		LET fv_width = 80 
	END IF 

	RETURN fv_width 
END FUNCTION 

################################################################################
{ FUNCTION:        Build REPORT line
  Description:     FUNCTION TO build REPORT '-' line.
}
FUNCTION rpt_line(fv_width) 

	DEFINE fv_width LIKE rptcol.width, 
	fv_rpt_line CHAR(330), 
	fv_inc INTEGER 

	LET fv_rpt_line = "-" 
	FOR fv_inc = 1 TO fv_width 
		LET fv_rpt_line = fv_rpt_line clipped, "-" 
	END FOR 

	RETURN fv_rpt_line 

END FUNCTION 

################################################################################
{ FUNCTION:        REPORT header description
  Description:     FUNCTION TO build the REPORT header titles,
                   AND position them according TO rpthead.rpt_desc_position.
}

FUNCTION desc_positions( fv_width ) 

	DEFINE fv_width LIKE rptcol.width, 
	fv_len, 
	fv_desc_pos1, 
	fv_desc_pos2, 
	fv_desc_pos3 INTEGER 

	CASE 
		WHEN gr_rpthead.rpt_desc_position = 'L' #left justified. 
			LET fv_desc_pos1 = 1 
			LET fv_desc_pos2 = 1 
			LET fv_desc_pos3 = 1 
		WHEN gr_rpthead.rpt_desc_position = 'R' #right justified. 
			LET fv_len = fv_width - length(gr_rpthead.rpt_desc1) + 1 
			LET fv_desc_pos1 = fv_len 
			LET fv_len = fv_width - length(gr_rpthead.rpt_desc2) + 1 
			LET fv_desc_pos2 = fv_len 
			LET fv_desc_pos3 = fv_width - 24 
		OTHERWISE # default TO centred. 
			LET fv_len = (fv_width / 2) - (length(gr_rpthead.rpt_desc1) / 2) 
			LET fv_desc_pos1 = fv_len 
			LET fv_len = (fv_width / 2) - (length(gr_rpthead.rpt_desc2) / 2) 
			LET fv_desc_pos2 = fv_len 
			LET fv_desc_pos3 = (fv_width / 2) - (25 / 2) 
	END CASE 

	RETURN fv_desc_pos1, fv_desc_pos2, fv_desc_pos3 

END FUNCTION 

################################################################################
{ FUNCTION:        Build REPORT COLUMN header line.
  Description:     FUNCTION TO build the REPORT COLUMN header line.
}
FUNCTION col_hdr_desc(fv_line_num) 

	DEFINE fv_line_num, 
	fv_pos, 
	fv_inc INTEGER, 
	fv_col_line CHAR(330) 

	DEFINE fv_col_desc, 
	fv_temp_desc LIKE rptcoldesc.col_desc, 
	fv_width LIKE rptcol.width, 
	fv_amt_picture LIKE rptcol.amt_picture, 
	fv_col_id, 
	fv_col_uid SMALLINT 

	DECLARE colhdr_curs CURSOR FOR 
	SELECT rptcoldesc.col_desc, 
	rptcol.width, 
	rptcol.col_id, 
	rptcol.col_uid, 
	rptcol.amt_picture 
	FROM rptcol, outer (rptcoldesc) 
	WHERE rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rptcol.col_code = gr_rpthead.col_code 
	AND rptcol.print_flag = "Y" 
	AND rptcoldesc.cmpy_code = rptcol.cmpy_code 
	AND rptcoldesc.col_code = rptcol.col_code 
	AND rptcoldesc.col_uid = rptcol.col_uid 
	AND rptcoldesc.seq_num = fv_line_num 
	ORDER BY rptcol.col_id 

	LET fv_pos = 1 
	LET fv_col_line = "" 

	FOREACH colhdr_curs INTO fv_temp_desc, 
		fv_width, 
		fv_col_id, 
		fv_col_uid, 
		fv_amt_picture 

		LET fv_col_desc = right_just_desc(fv_width, 
		fv_temp_desc, 
		fv_col_uid, 
		fv_amt_picture) 

		IF fv_col_desc IS NULL THEN 
			LET fv_col_desc = " " 
		END IF 

		IF fv_width > 0 THEN 
			IF fv_pos = 1 THEN 
				LET fv_col_line = fv_col_desc[1,fv_width] 
			ELSE 
				LET fv_col_line = fv_col_line[1,fv_pos], fv_col_desc[1,fv_width] 
			END IF 

			IF fv_pos = 1 THEN 
				LET fv_pos = 0 
			END IF 
			LET fv_pos = fv_pos + fv_width 
		END IF 

	END FOREACH 

	RETURN fv_col_line 

END FUNCTION 


FUNCTION right_just_desc(fv_width, fv_temp_desc, fv_col_uid, fv_amt_picture) 

	DEFINE fv_width LIKE rptcol.width, 
	fv_temp_desc, 
	fv_col_desc LIKE rptcoldesc.col_desc, 
	fv_item_type LIKE mrwitem.item_type, 
	fv_amt_picture LIKE rptcol.amt_picture, 
	fv_col_uid, 
	fv_length, 
	fv_start_pos, 
	fv_end_pos SMALLINT, 
	fr_colitem RECORD LIKE colitem.* 

	SELECT * 
	INTO fr_colitem.* 
	FROM colitem 
	WHERE col_uid = fv_col_uid 
	AND seq_num = 1 

	IF status = notfound THEN 
		RETURN fv_temp_desc 
	END IF 

	SELECT item_type 
	INTO fv_item_type 
	FROM mrwitem 
	WHERE item_id = fr_colitem.col_item 

	IF status = notfound THEN 
		RETURN fv_temp_desc 
	END IF 

	IF fv_item_type = gr_mrwparms.constant_item_type THEN 
		RETURN fv_temp_desc 
	END IF 

	LET fv_length = length(fv_temp_desc) 

	IF fv_length < 1 THEN 
		RETURN fv_temp_desc 
	END IF 

	LET fv_end_pos = length(fv_amt_picture) 

	LET fv_start_pos = fv_end_pos - fv_length 

	IF fv_start_pos < 2 THEN 
		RETURN fv_temp_desc 
	ELSE 
		LET fv_col_desc = " " 
		LET fv_col_desc = fv_col_desc[1, fv_start_pos - 1], fv_temp_desc clipped 
		RETURN fv_col_desc 
	END IF 

END FUNCTION 
################################################################################
{ FUNCTION:        Description COLUMN
  Description:     FUNCTION TO RETURN TRUE IF description OTHERWISE FALSE.
}
FUNCTION desc_col(fv_col_uid) 

	DEFINE fv_col_uid LIKE rptcol.col_uid, 
	fv_found INTEGER 

	SELECT count(*) INTO fv_found 
	FROM colitem, mrwitem 
	WHERE colitem.col_uid = fv_col_uid 
	AND mrwitem.item_id = colitem.col_item 
	AND mrwitem.item_type = gr_mrwparms.constant_item_type 

	RETURN fv_found 

END FUNCTION 

################################################################################
{ FUNCTION:        Blank COLUMN
  Description:     FUNCTION TO RETURN TRUE IF blank COLUMN
}
FUNCTION blank_col(fv_col_uid) 

	DEFINE fv_col_uid LIKE rptcol.col_uid, 
	fv_found INTEGER 

	SELECT count(*) INTO fv_found 
	FROM colitem, mrwitem 
	WHERE colitem.col_uid = fv_col_uid 
	AND mrwitem.item_id = colitem.col_item 
	AND mrwitem.item_type = gr_mrwparms.blank_item_type 

	RETURN fv_found 

END FUNCTION 

################################################################################
{ FUNCTION:        Currency COLUMN
  Description:     FUNCTION TO RETURN TRUE IF currency code COLUMN
}
FUNCTION curr_col(fv_col_uid) 

	DEFINE fv_col_uid LIKE rptcol.col_uid, 
	fv_found INTEGER 

	SELECT count(*) INTO fv_found 
	FROM colitem, mrwitem 
	WHERE colitem.col_uid = fv_col_uid 
	AND mrwitem.item_id = colitem.col_item 
	AND mrwitem.item_type = gr_mrwparms.curr_item_type 

	RETURN fv_found 

END FUNCTION 

################################################################################
{ FUNCTION:        COLUMN Description
  Description:     FUNCTION TO RETURN the COLUMN description FOR a line.
}
FUNCTION col_desc(fv_line_uid, fv_width) 

	DEFINE fv_line_uid LIKE descline.line_uid, 
	fv_width LIKE rptcol.width, 
	fv_line_desc LIKE descline.line_desc, 
	fv_temp_line LIKE descline.line_desc, 
	fv_start SMALLINT 

	LET fv_line_desc = NULL 
	LET gv_desc_col_num = gv_desc_col_num + 1 

	CASE 
		WHEN gr_rptline.line_type = gr_mrwparms.gl_line_type 
			AND (gr_entry_criteria.worksheet_rpt = "W" 
			OR gv_detl_flag = true) 
			AND NOT gv_wksht_tots 
			IF gr_entry_criteria.desc_type = "C" THEN #print code 
				IF NOT gv_desc_col_num > 1 THEN 
					LET fv_line_desc[1,fv_width] = gv_account_code 

					SELECT line_desc 
					INTO fv_temp_line 
					FROM descline 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND line_code = gr_rptlinegrp.line_code 
					AND line_uid = fv_line_uid 
					AND seq_num = gv_desc_col_num 
				END IF 
			ELSE #desc_type = "(B)oth" OR "(N)ame" 
				IF gr_entry_criteria.desc_type = "B" THEN 
					LET fv_line_desc[1,gv_acct_length] = gv_account_code 
					LET fv_line_desc = fv_line_desc[1,fv_width] 
					LET fv_start = gv_acct_length + 2 
				ELSE 
					LET fv_start = 1 
				END IF 

				SELECT desc_text 
				INTO fv_temp_line 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = gv_account_code 

				IF status <> notfound THEN 
					LET fv_line_desc[fv_start, fv_width] = fv_temp_line 
				END IF 
			END IF 

		OTHERWISE 
			SELECT line_desc 
			INTO fv_line_desc 
			FROM descline 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_code = gr_rptlinegrp.line_code 
			AND line_uid = fv_line_uid 
			AND seq_num = gv_desc_col_num 

			IF status = notfound THEN 
				LET fv_line_desc = NULL 
			ELSE 
				LET fv_line_desc = fv_line_desc[1,fv_width] 
			END IF 
	END CASE 

	RETURN fv_line_desc 

END FUNCTION 

################################################################################
{ FUNCTION:        Maximum columns
  Description:     FUNCTION TO RETURN the maximum number of columns.
}
FUNCTION max_columns() 

	DEFINE fv_kandoo_columns INTEGER 

	SELECT max(col_id) INTO fv_kandoo_columns 
	FROM rptcol 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND col_code = gr_rptcolgrp.col_code 

	IF fv_kandoo_columns IS NULL THEN 
		LET fv_kandoo_columns = 0 
	END IF 

	RETURN fv_kandoo_columns 

END FUNCTION 

################################################################################
{ FUNCTION:        underline
  Description:     FUNCTION TO RETURN the COLUMN underline FOR a line.
}
FUNCTION under_line(fv_line_uid, fv_col_uid, fv_width, fv_amt_picture) 

	DEFINE fv_line_uid LIKE rptline.line_uid, 
	fv_col_uid LIKE rptcol.col_uid, 
	fv_width LIKE rptcol.width, 
	fv_amt_picture LIKE rptcol.amt_picture, 
	fv_underline LIKE descline.line_desc, 
	fr_txttype RECORD LIKE txttype.* 

	DEFINE fv_inc, 
	fv_len INTEGER 

	SELECT txttype.txttype_char, txttype.continuous 
	INTO fr_txttype.txttype_char, fr_txttype.continuous 
	FROM txtline, txttype 
	WHERE txtline.line_uid = fv_line_uid 
	AND txttype.txttype_id = txtline.txt_type 

	IF status != notfound THEN 
		IF fr_txttype.continuous = "Y" THEN 
			FOR fv_inc = 1 TO fv_width 
				LET fv_underline = fv_underline clipped, 
				fr_txttype.txttype_char 
			END FOR 
		ELSE 
			IF NOT desc_col(fv_col_uid) 
			AND NOT blank_col(fv_col_uid) THEN 
				# Line width IS determined by the amt_picture length.
				LET fv_len = length( fv_amt_picture ) 
				FOR fv_inc = 1 TO fv_len 
					LET fv_underline = fv_underline clipped, 
					fr_txttype.txttype_char 
				END FOR 
			END IF 
		END IF 
	END IF 

	RETURN fv_underline 

END FUNCTION 
################################################################################
