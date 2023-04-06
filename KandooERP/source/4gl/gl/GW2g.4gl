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



#  This module contains the functions needed TO change a
#  RECORD in rpthead table.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "GW2_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_err_msg CHAR(40) 
DEFINE modu_try_again CHAR(1) 


############################################################
# FUNCTION mrw_image()
#
# This FUNCTION gets the source AND destination reports.
############################################################
FUNCTION mrw_image() 
	DEFINE l_rec_rpthead RECORD LIKE rpthead.* 
	DEFINE l_rpt_id LIKE rpthead.rpt_id 
	DEFINE l_status INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 


	OPEN WINDOW g530 with FORM "G530" 
	CALL windecoration_g("G530") 

	LET l_msgresp = kandoomsg("E",1072,"") 
	DISPLAY BY NAME glob_rec_rpthead.rpt_id, glob_rec_rpthead.rpt_text 


	INPUT glob_rec_rpthead.rpt_id, l_rpt_id WITHOUT DEFAULTS 
	FROM rpt_id, rpt_id_to 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW2g","inp-rep") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


			#Browse on the FROM rpt_id option
		ON ACTION "LOOKUP" infield(rpt_id) 
			CALL hdr_brws(glob_rec_rpthead.rpt_id) 
			RETURNING glob_rec_rpthead.rpt_id 
			NEXT FIELD rpt_id 

		AFTER FIELD rpt_id 
			#Check that the rpt_id entered exists
			SELECT * INTO glob_rec_rpthead.* 
			FROM rpthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = glob_rec_rpthead.rpt_id 

			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found; Try Window.
				NEXT FIELD rpt_id 
			ELSE 
				DISPLAY BY NAME glob_rec_rpthead.rpt_id, glob_rec_rpthead.rpt_text 

			END IF 
		AFTER FIELD rpt_id_to 
			#Check that the TO rpt_id does NOT exist
			SELECT * FROM rpthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = l_rpt_id 
			IF NOT status THEN 
				LET l_msgresp = kandoomsg("U",9104,"") 
				#9104 This RECORD already exists
				NEXT FIELD rpt_id_to 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			#Check that the TO rpt_id does NOT exist
			SELECT * 
			FROM rpthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = l_rpt_id 

			IF NOT status THEN 
				LET l_msgresp = kandoomsg("U",9104,"") 
				#9104 This RECORD already exists
				NEXT FIELD rpt_id_to 
			END IF 

			#Retrieve source REPORT header RECORD INTO destination
			SELECT * INTO l_rec_rpthead.* 
			FROM rpthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = glob_rec_rpthead.rpt_id 

			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found; Try Window.
				NEXT FIELD rpt_id 
			END IF 

			#INSERT the new VALUES INTO the REPORT head
			LET l_rec_rpthead.rpt_id = l_rpt_id 

			CALL image_report(l_rec_rpthead.*) 
			RETURNING l_status 

			--   ON KEY (control-w)
			--      CALL kandoohelp("")
	END INPUT 

	CLOSE WINDOW g530 

	#Commit OR Rollback work
	IF l_status OR int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 


END FUNCTION 


############################################################
# FUNCTION image_report(p_rec_rpthead)
#
#
############################################################
FUNCTION image_report(p_rec_rpthead) 
	DEFINE p_rec_rpthead RECORD LIKE rpthead.* 
	DEFINE l_rec_accumulator RECORD LIKE accumulator.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO image_bypass 
	LABEL image_recovery: 
	LET modu_try_again = error_recover(modu_err_msg, status) 
	IF modu_try_again != "Y" THEN 
		RETURN (TRUE) 
	END IF 

	LABEL image_bypass: 

	WHENEVER ERROR GOTO image_recovery 

	BEGIN WORK 

		LET modu_err_msg = " Cannot INSERT INTO REPORT header table." 
		INSERT INTO rpthead VALUES (p_rec_rpthead.*) 
		LET l_msgresp = kandoomsg("G",1025,"") 
		CALL image_columns( p_rec_rpthead.rpt_id ) 
		RETURNING status 
		IF status THEN GOTO image_recovery END IF 
			CALL image_lines( p_rec_rpthead.rpt_id ) 
			RETURNING status 
			IF status THEN GOTO image_recovery END IF 
				#Copy the accumulators FOR destination REPORT
				DECLARE acc_curs CURSOR FOR 
				SELECT * 
				FROM accumulator 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 
				FOREACH acc_curs INTO l_rec_accumulator.* 
					LET l_rec_accumulator.rpt_id = p_rec_rpthead.rpt_id 
					LET modu_err_msg = " Cannot INSERT INTO accumulator table." 
					INSERT INTO accumulator VALUES ( l_rec_accumulator.*) 
				END FOREACH 

			COMMIT WORK 

			WHENEVER ERROR stop 
			LET int_flag = false 
			LET quit_flag = false 

			RETURN (FALSE) #return false FOR no errors. 


END FUNCTION 


############################################################
# FUNCTION image_columns(p_rpt_id)
#
# This FUNCTION performs the RECORD inserts FOR columns.
############################################################
FUNCTION image_columns(p_rpt_id) 
	DEFINE p_rpt_id LIKE rpthead.rpt_id 
	DEFINE l_src_uid LIKE rptcol.col_uid #source COLUMN id 
	DEFINE l_rec_rptcol RECORD LIKE rptcol.* 
	DEFINE l_rec_rptcoldesc RECORD LIKE rptcoldesc.* 
	DEFINE l_rec_colitemcolid RECORD LIKE colitemcolid.* 
	DEFINE l_rec_colitemval RECORD LIKE colitemval.* 
	DEFINE l_rec_colitemdetl RECORD LIKE colitemdetl.* 
	DEFINE l_rec_colitem RECORD LIKE colitem.* 
	DEFINE l_rec_rptcolaa RECORD LIKE rptcolaa.* 

	GOTO column_bypass 
	LABEL column_recovery: 
	RETURN (STATUS) 

	LABEL column_bypass: 

	WHENEVER ERROR GOTO column_recovery 

	#FOREACH Column copy the REPORT COLUMN details
	DECLARE col_curs CURSOR FOR 
	SELECT * 
	FROM rptcol 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 


	FOREACH col_curs INTO l_rec_rptcol.* 

		LET l_rec_rptcol.rpt_id = p_rpt_id 
		LET l_src_uid = l_rec_rptcol.col_uid 
		LET l_rec_rptcol.col_uid = 0 

		LET modu_err_msg = " Cannot INSERT INTO REPORT COLUMN table." 
		INSERT INTO rptcol VALUES (l_rec_rptcol.*) 

		LET modu_err_msg = " Cannot SELECT the unique COLUMN id." 
		LET l_rec_rptcol.col_uid = sqlca.sqlerrd[2] 

		DECLARE colitem_curs CURSOR FOR 
		SELECT * FROM colitem 
		WHERE col_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH colitem_curs INTO l_rec_colitem.* 
			LET l_rec_colitem.rpt_id = l_rec_rptcol.rpt_id 
			LET l_rec_colitem.col_uid = l_rec_rptcol.col_uid 

			LET modu_err_msg = " Cannot INSERT INTO COLUMN item table." 
			INSERT INTO colitem VALUES ( l_rec_colitem.*) 

		END FOREACH 

		DECLARE colid_curs CURSOR FOR 
		SELECT * FROM colitemcolid 
		WHERE col_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH colid_curs INTO l_rec_colitemcolid.* 
			LET l_rec_colitemcolid.rpt_id = p_rpt_id 
			LET l_rec_colitemcolid.col_uid = l_rec_rptcol.col_uid 

			LET modu_err_msg = " Cannot INSERT INTO COLUMN item col id table." 
			INSERT INTO colitemcolid VALUES ( l_rec_colitemcolid.*) 

		END FOREACH 


		DECLARE colval_curs CURSOR FOR 
		SELECT * FROM colitemval 
		WHERE col_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH colval_curs INTO l_rec_colitemval.* 
			LET l_rec_colitemval.rpt_id = p_rpt_id 
			LET l_rec_colitemval.col_uid = l_rec_rptcol.col_uid 

			LET modu_err_msg = " Cannot INSERT INTO COLUMN item value table." 
			INSERT INTO colitemval VALUES ( l_rec_colitemval.*) 

		END FOREACH 


		DECLARE coldetl_curs CURSOR FOR 
		SELECT * FROM colitemdetl 
		WHERE col_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH coldetl_curs INTO l_rec_colitemdetl.* 
			LET l_rec_colitemdetl.rpt_id = p_rpt_id 
			LET l_rec_colitemdetl.col_uid = l_rec_rptcol.col_uid 

			LET modu_err_msg = " Cannot INSERT INTO COLUMN detl table." 
			INSERT INTO colitemdetl VALUES ( l_rec_colitemdetl.*) 

		END FOREACH 


		DECLARE colaa_curs CURSOR FOR 
		SELECT * FROM rptcolaa 
		WHERE col_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH colaa_curs INTO l_rec_rptcolaa.* 
			LET l_rec_rptcolaa.rpt_id = p_rpt_id 
			LET l_rec_rptcolaa.col_uid = l_rec_rptcol.col_uid 

			LET modu_err_msg = " Cannot INSERT INTO COLUMN analysis across table." 
			INSERT INTO rptcolaa VALUES ( l_rec_rptcolaa.*) 

		END FOREACH 

		DECLARE coldesc_curs CURSOR FOR 
		SELECT * FROM rptcoldesc 
		WHERE col_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH coldesc_curs INTO l_rec_rptcoldesc.* 
			LET l_rec_rptcoldesc.rpt_id = p_rpt_id 
			LET l_rec_rptcoldesc.col_uid = l_rec_rptcol.col_uid 

			LET modu_err_msg = " Cannot INSERT INTO COLUMN description table." 
			INSERT INTO rptcoldesc VALUES ( l_rec_rptcoldesc.*) 

		END FOREACH 

	END FOREACH 

	RETURN (FALSE) 

	WHENEVER ERROR stop 

END FUNCTION 


############################################################
# FUNCTION image_lines(p_rpt_id)
#
# This FUNCTION performs the RECORD inserts FOR lines.
############################################################
FUNCTION image_lines(p_rpt_id) 
	DEFINE p_rpt_id LIKE rpthead.rpt_id 
	DEFINE l_src_uid LIKE rptcol.col_uid #source line id 
	DEFINE l_rec_rptline RECORD LIKE rptline.* 
	DEFINE l_rec_saveline RECORD LIKE saveline.* 
	DEFINE l_rec_descline RECORD LIKE descline.* 
	DEFINE l_rec_gllinedetl RECORD LIKE gllinedetl.* 
	DEFINE l_rec_calchead RECORD LIKE calchead.* 
	DEFINE l_rec_glline RECORD LIKE glline.* 
	DEFINE l_rec_calcline RECORD LIKE calcline.* 
	DEFINE l_rec_txtline RECORD LIKE txtline.* 
	DEFINE l_rec_segline RECORD LIKE segline.* 
	DEFINE l_rec_extline RECORD LIKE extline.* 
	DEFINE l_msgresp LIKE language.yes_flag 


	GOTO line_bypass 
	LABEL line_recovery: 
	RETURN (STATUS) 

	LABEL line_bypass: 

	WHENEVER ERROR GOTO line_recovery 

	#FOREACH line copy all of the line details
	DECLARE line_curs CURSOR FOR 
	SELECT * 
	FROM rptline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 

	FOREACH line_curs INTO l_rec_rptline.* 

		LET l_src_uid = l_rec_rptline.line_uid 
		LET l_rec_rptline.rpt_id = p_rpt_id 
		LET l_rec_rptline.line_uid = 0 

		LET modu_err_msg = " Cannot INSERT VALUES INTO REPORT line table. " 
		INSERT INTO rptline VALUES (l_rec_rptline.*) 

		LET modu_err_msg = " Cannot SELECT the unique COLUMN id." 
		LET l_rec_rptline.line_uid = sqlca.sqlerrd[2] 

		DECLARE linetxt_curs CURSOR FOR 
		SELECT * FROM txtline 
		WHERE line_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH linetxt_curs INTO l_rec_txtline.* 
			LET l_rec_txtline.rpt_id = p_rpt_id 
			LET l_rec_txtline.line_uid = l_rec_rptline.line_uid 

			LET modu_err_msg = " Cannot INSERT VALUES INTO text line table. " 
			INSERT INTO txtline VALUES ( l_rec_txtline.*) 

		END FOREACH 


		DECLARE calcline_curs CURSOR FOR 
		SELECT * FROM calcline 
		WHERE line_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH calcline_curs INTO l_rec_calcline.* 
			LET l_rec_calcline.rpt_id = p_rpt_id 
			LET l_rec_calcline.line_uid = l_rec_rptline.line_uid 

			LET modu_err_msg = " Cannot INSERT VALUES INTO calc line table. " 
			INSERT INTO calcline VALUES ( l_rec_calcline.*) 

		END FOREACH 


		DECLARE glline_curs CURSOR FOR 
		SELECT * FROM glline 
		WHERE line_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH glline_curs INTO l_rec_glline.* 
			LET l_rec_glline.rpt_id = p_rpt_id 
			LET l_rec_glline.line_uid = l_rec_rptline.line_uid 

			LET modu_err_msg = " Cannot INSERT VALUES INTO gl line table. " 
			INSERT INTO glline VALUES ( l_rec_glline.*) 

		END FOREACH 


		DECLARE calchead_curs CURSOR FOR 
		SELECT * FROM calchead 
		WHERE line_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH calchead_curs INTO l_rec_calchead.* 
			LET l_rec_calchead.rpt_id = p_rpt_id 
			LET l_rec_calchead.line_uid = l_rec_rptline.line_uid 

			LET modu_err_msg = " Cannot INSERT VALUES INTO calc head table. " 
			INSERT INTO calchead VALUES ( l_rec_calchead.*) 

		END FOREACH 


		DECLARE gldetl_curs CURSOR FOR 
		SELECT * FROM gllinedetl 
		WHERE line_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH gldetl_curs INTO l_rec_gllinedetl.* 
			LET l_rec_gllinedetl.rpt_id = p_rpt_id 
			LET l_rec_gllinedetl.line_uid = l_rec_rptline.line_uid 

			LET modu_err_msg = " Cannot INSERT VALUES INTO gl detail table. " 
			INSERT INTO gllinedetl VALUES ( l_rec_gllinedetl.*) 

		END FOREACH 


		DECLARE descline_curs CURSOR FOR 
		SELECT * FROM descline 
		WHERE line_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH descline_curs INTO l_rec_descline.* 
			LET l_rec_descline.rpt_id = p_rpt_id 
			LET l_rec_descline.line_uid = l_rec_rptline.line_uid 

			#get col_uid FOR this description line.
			SELECT rptcol.col_uid INTO l_rec_descline.col_uid 
			FROM rptcol 
			WHERE rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rptcol.rpt_id = p_rpt_id 
			AND rptcol.col_id in ( SELECT rc.col_id 
			FROM rptcol rc 
			WHERE rc.col_uid = l_rec_descline.col_uid ) 

			LET modu_err_msg = " Cannot INSERT VALUES INTO description line table." 
			INSERT INTO descline VALUES ( l_rec_descline.*) 

		END FOREACH 

		DECLARE save_curs CURSOR FOR 
		SELECT * FROM saveline 
		WHERE line_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH save_curs INTO l_rec_saveline.* 
			LET l_rec_saveline.rpt_id = p_rpt_id 
			LET l_rec_saveline.line_uid = l_rec_rptline.line_uid 

			LET modu_err_msg = " Cannot INSERT VALUES INTO save line table." 
			INSERT INTO saveline VALUES ( l_rec_saveline.*) 

		END FOREACH 

		DECLARE seg_curs CURSOR FOR 
		SELECT * FROM segline 
		WHERE line_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH seg_curs INTO l_rec_segline.* 
			LET l_rec_segline.rpt_id = p_rpt_id 
			LET l_rec_segline.line_uid = l_rec_rptline.line_uid 

			LET modu_err_msg = " Cannot INSERT VALUES INTO segment line table." 
			INSERT INTO segline VALUES ( l_rec_segline.*) 

		END FOREACH 


		DECLARE extline_curs CURSOR FOR 
		SELECT * FROM extline 
		WHERE line_uid = l_src_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH extline_curs INTO l_rec_extline.* 
			LET l_rec_extline.rpt_id = p_rpt_id 
			LET l_rec_extline.line_uid = l_rec_rptline.line_uid 

			#get col_uid FOR this external line.
			SELECT rptcol.col_uid INTO l_rec_extline.col_uid 
			FROM rptcol 
			WHERE rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rptcol.rpt_id = p_rpt_id 
			AND rptcol.col_id in ( SELECT rc.col_id 
			FROM rptcol rc 
			WHERE rc.col_uid = l_rec_extline.col_uid ) 

			LET modu_err_msg = " Cannot INSERT VALUES INTO external line table." 
			INSERT INTO extline VALUES ( l_rec_extline.*) 

		END FOREACH 

	END FOREACH 

	RETURN (FALSE) 

	WHENEVER ERROR stop 

END FUNCTION 
