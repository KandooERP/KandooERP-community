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

	Source code beautified by beautify.pl on 2020-01-03 10:10:05	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW4_GLOBALS.4gl" 

#  Line Image FUNCTION



FUNCTION line_image() 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_old_linegrp_desc LIKE rptlinegrp.linegrp_desc, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_new_cmpy_name LIKE company.name_text, 
	fv_count, 
	fv_status SMALLINT 

	OPEN WINDOW g574 with FORM "TG574" 
	CALL windecoration_t("TG574") -- albo kd-768 

	MESSAGE "Enter the Line Group you wish TO image" 
	attribute(yellow) 

	LET fv_old_line_code = gr_rptlinegrp.line_code 
	LET fv_old_linegrp_desc = gr_rptlinegrp.linegrp_desc 

	INPUT BY NAME fv_old_line_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4g","input-fv_old_line_code-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" ---------- browse 
			CALL show_linegrps(glob_rec_kandoouser.cmpy_code, fv_old_line_code) 
			RETURNING fv_old_line_code 

			DISPLAY BY NAME fv_old_line_code 

			SELECT linegrp_desc 
			INTO fv_old_linegrp_desc 
			FROM rptlinegrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_code = fv_old_line_code 

			IF status <> notfound THEN 
				DISPLAY BY NAME fv_old_linegrp_desc 
			END IF 

		BEFORE FIELD fv_old_line_code 
			DISPLAY BY NAME fv_old_linegrp_desc 

		AFTER FIELD fv_old_line_code 
			IF fv_old_line_code IS NULL 
			OR fv_old_line_code = " " THEN 
				ERROR "Line code must be entered" 
				NEXT FIELD fv_old_line_code 
			END IF 

			SELECT linegrp_desc 
			INTO fv_old_linegrp_desc 
			FROM rptlinegrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_code = fv_old_line_code 

			IF status THEN 
				ERROR "This line code doesn't exist - try lookup" 
				NEXT FIELD fv_old_line_code 
			END IF 

			DISPLAY BY NAME fv_old_linegrp_desc 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW g574 
		RETURN true 
	END IF 

	MESSAGE "Enter the new Company/Line code" 
	attribute(yellow) 

	LET fv_new_cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET fv_new_line_code = fv_old_line_code 

	SELECT name_text 
	INTO fv_new_cmpy_name 
	FROM company 
	WHERE cmpy_code = fv_new_cmpy_code 

	IF NOT status THEN 
		DISPLAY BY NAME fv_new_cmpy_name 
	END IF 

	INPUT BY NAME fv_new_cmpy_code, 
	fv_new_line_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4g","input-fv_new_cmpy_code-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD fv_new_cmpy_code 
			IF fv_new_cmpy_code IS NULL 
			OR fv_new_cmpy_code = " " THEN 
				ERROR "Destination company must be entered" 
				NEXT FIELD fv_new_cmpy_code 
			END IF 

			SELECT name_text 
			INTO fv_new_cmpy_name 
			FROM company 
			WHERE cmpy_code = fv_new_cmpy_code 

			IF status THEN 
				ERROR "Invalid company" 
				NEXT FIELD fv_new_cmpy_code 
			END IF 

			DISPLAY BY NAME fv_new_cmpy_name 


		AFTER FIELD fv_new_line_code 
			IF NOT fgl_lastkey() = fgl_keyval("up") THEN 
				SELECT count(*) 
				INTO fv_count 
				FROM rptlinegrp 
				WHERE cmpy_code = fv_new_cmpy_code 
				AND line_code = fv_new_line_code 

				IF fv_count <> 0 THEN 
					ERROR "This line code already exists FOR this company" 
					NEXT FIELD fv_new_cmpy_code 
				END IF 

			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 

		CLOSE WINDOW g574 
		RETURN true 
	END IF 

	MESSAGE "Imaging line details, please wait....." 
	attribute(yellow) 

	CALL copy_line_dtls(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code) RETURNING fv_status 


	CLOSE WINDOW g574 

	RETURN fv_status 

END FUNCTION 


FUNCTION copy_line_dtls(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code) 

	DEFINE fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_count, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_rptlinegrp RECORD LIKE rptlinegrp.*, 
	fr_rptline RECORD LIKE rptline.* 

	SELECT * 
	INTO fr_rptlinegrp.* 
	FROM rptlinegrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 

	IF status THEN 
		RETURN true 
	END IF 

	SELECT count(*) 
	INTO fv_count 
	FROM rptlinegrp 
	WHERE cmpy_code = fv_new_cmpy_code 
	AND line_code = fv_new_line_code 

	IF fv_count <> 0 THEN 
		RETURN true 
	END IF 

	LET fr_rptlinegrp.cmpy_code = fv_new_cmpy_code 
	LET fr_rptlinegrp.line_code = fv_new_line_code 

	INSERT INTO rptlinegrp VALUES (fr_rptlinegrp.*) 

	DECLARE rptline_curs CURSOR FOR 
	SELECT * 
	FROM rptline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 

	FOREACH rptline_curs INTO fr_rptline.* 
		LET fv_old_uid = fr_rptline.line_uid 
		LET fr_rptline.cmpy_code = fv_new_cmpy_code 
		LET fr_rptline.line_code = fv_new_line_code 
		LET fr_rptline.line_uid = 0 

		SELECT * 
		INTO fr_rptline.* 
		FROM rptline 
		WHERE cmpy_code = fv_new_cmpy_code 
		AND line_code = fv_new_line_code 
		AND line_id = fr_rptline.line_id 

		IF status <> notfound THEN 
			RETURN true 
		END IF 

		INSERT INTO rptline VALUES (fr_rptline.*) 

		LET fv_new_uid = sqlca.sqlerrd[2] 

		#       CALL add_saveline(fv_old_line_code,
		#                         fv_new_cmpy_code,
		#                         fv_new_line_code,
		#                         fv_old_uid,
		#                         fv_new_uid)

		IF fr_rptline.line_type = gr_mrwparms.under_line_type THEN 
			CALL add_txtline(fv_old_line_code, 
			fv_new_cmpy_code, 
			fv_new_line_code, 
			fv_old_uid, 
			fv_new_uid) 
			CONTINUE FOREACH 
		END IF 

		CALL add_descline(fv_old_line_code, 
		fv_new_cmpy_code, 
		fv_new_line_code, 
		fv_old_uid, 
		fv_new_uid) 

		CASE 
			WHEN fr_rptline.line_type = gr_mrwparms.gl_line_type 
				CALL add_glline(fv_old_line_code, 
				fv_new_cmpy_code, 
				fv_new_line_code, 
				fv_old_uid, 
				fv_new_uid) 

				CALL add_gllinedetl(fv_old_line_code, 
				fv_new_cmpy_code, 
				fv_new_line_code, 
				fv_old_uid, 
				fv_new_uid) 

				CALL add_segline(fv_old_line_code, 
				fv_new_cmpy_code, 
				fv_new_line_code, 
				fv_old_uid, 
				fv_new_uid) 

			WHEN fr_rptline.line_type = gr_mrwparms.ext_link_line_type 
				CALL add_exthead(fv_old_line_code, 
				fv_new_cmpy_code, 
				fv_new_line_code, 
				fv_old_uid, 
				fv_new_uid) 

				CALL add_extline(fv_old_line_code, 
				fv_new_cmpy_code, 
				fv_new_line_code, 
				fv_old_uid, 
				fv_new_uid) 

			WHEN fr_rptline.line_type = gr_mrwparms.calc_line_type 
				CALL add_calchead(fv_old_line_code, 
				fv_new_cmpy_code, 
				fv_new_line_code, 
				fv_old_uid, 
				fv_new_uid) 

				CALL add_calcline(fv_old_line_code, 
				fv_new_cmpy_code, 
				fv_new_line_code, 
				fv_old_uid, 
				fv_new_uid) 

		END CASE 

	END FOREACH 

	RETURN false 

END FUNCTION 


#FUNCTION add_saveline(fv_old_line_code,
#                      fv_new_cmpy_code,
#                      fv_new_line_code,
#                      fv_old_uid,
#                      fv_new_uid)
#
#    DEFINE fv_old_line_code,
#           fv_new_line_code       LIKE rptlinegrp.line_code,
#           fv_new_cmpy_code       LIKE rptlinegrp.cmpy_code,
#           fv_old_uid,
#           fv_new_uid            SMALLINT,
#           fr_saveline            RECORD LIKE saveline.*
#
#    SELECT *
#      INTO fr_saveline.*
#      FROM saveline
#      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
#        AND line_code = fv_old_line_code
#        AND line_uid  = fv_old_uid
#
#    IF STATUS = NOTFOUND THEN
#        RETURN
#    END IF

#    LET fr_saveline.cmpy_code = fv_new_cmpy_code
#    LET fr_saveline.line_code = fv_new_line_code
#    LET fr_saveline.line_uid  = fv_new_uid
#
#    INSERT INTO saveline VALUES(fr_saveline.*)
#
#END FUNCTION


FUNCTION add_txtline(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code, 
	fv_old_uid, 
	fv_new_uid) 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_txtline RECORD LIKE txtline.* 

	SELECT * 
	INTO fr_txtline.* 
	FROM txtline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 
	AND line_uid = fv_old_uid 

	IF status = notfound THEN 
		RETURN 
	END IF 

	LET fr_txtline.cmpy_code = fv_new_cmpy_code 
	LET fr_txtline.line_code = fv_new_line_code 
	LET fr_txtline.line_uid = fv_new_uid 

	INSERT INTO txtline VALUES (fr_txtline.*) 

END FUNCTION 


FUNCTION add_glline(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code, 
	fv_old_uid, 
	fv_new_uid) 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_glline RECORD LIKE glline.* 

	SELECT * 
	INTO fr_glline.* 
	FROM glline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 
	AND line_uid = fv_old_uid 

	IF status = notfound THEN 
		RETURN 
	END IF 

	LET fr_glline.cmpy_code = fv_new_cmpy_code 
	LET fr_glline.line_code = fv_new_line_code 
	LET fr_glline.line_uid = fv_new_uid 

	INSERT INTO glline VALUES (fr_glline.*) 

END FUNCTION 


FUNCTION add_gllinedetl(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code, 
	fv_old_uid, 
	fv_new_uid) 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_gllinedetl RECORD LIKE gllinedetl.* 

	DECLARE gllinedetl_curs CURSOR FOR 
	SELECT * 
	FROM gllinedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 
	AND line_uid = fv_old_uid 

	FOREACH gllinedetl_curs INTO fr_gllinedetl.* 

		LET fr_gllinedetl.cmpy_code = fv_new_cmpy_code 
		LET fr_gllinedetl.line_code = fv_new_line_code 
		LET fr_gllinedetl.line_uid = fv_new_uid 

		INSERT INTO gllinedetl VALUES (fr_gllinedetl.*) 

	END FOREACH 

	CLOSE gllinedetl_curs 

END FUNCTION 


FUNCTION add_segline(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code, 
	fv_old_uid, 
	fv_new_uid) 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_segline RECORD LIKE segline.* 

	DECLARE segline_curs CURSOR FOR 
	SELECT * 
	FROM segline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 
	AND line_uid = fv_old_uid 

	FOREACH segline_curs INTO fr_segline.* 
		LET fr_segline.cmpy_code = fv_new_cmpy_code 
		LET fr_segline.line_code = fv_new_line_code 
		LET fr_segline.line_uid = fv_new_uid 

		INSERT INTO segline VALUES (fr_segline.*) 
	END FOREACH 

	CLOSE segline_curs 

END FUNCTION 


FUNCTION add_calchead(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code, 
	fv_old_uid, 
	fv_new_uid) 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_calchead RECORD LIKE calchead.* 

	SELECT * 
	INTO fr_calchead.* 
	FROM calchead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 
	AND line_uid = fv_old_uid 

	IF status = notfound THEN 
		RETURN 
	END IF 

	LET fr_calchead.cmpy_code = fv_new_cmpy_code 
	LET fr_calchead.line_code = fv_new_line_code 
	LET fr_calchead.line_uid = fv_new_uid 

	INSERT INTO calchead VALUES (fr_calchead.*) 


END FUNCTION 


FUNCTION add_calcline(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code, 
	fv_old_uid, 
	fv_new_uid) 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_calcline RECORD LIKE calcline.* 

	DECLARE calcline_curs CURSOR FOR 
	SELECT * 
	FROM calcline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 
	AND line_uid = fv_old_uid 

	FOREACH calcline_curs INTO fr_calcline.* 

		LET fr_calcline.cmpy_code = fv_new_cmpy_code 
		LET fr_calcline.line_code = fv_new_line_code 
		LET fr_calcline.line_uid = fv_new_uid 

		INSERT INTO calcline VALUES (fr_calcline.*) 

	END FOREACH 
	CLOSE calcline_curs 

END FUNCTION 


FUNCTION add_exthead(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code, 
	fv_old_uid, 
	fv_new_uid) 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_exthead RECORD LIKE exthead.* 

	SELECT * 
	INTO fr_exthead.* 
	FROM exthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 
	AND line_uid = fv_old_uid 

	IF status = notfound THEN 
		RETURN 
	END IF 

	LET fr_exthead.cmpy_code = fv_new_cmpy_code 
	LET fr_exthead.line_code = fv_new_line_code 
	LET fr_exthead.line_uid = fv_new_uid 

	INSERT INTO exthead VALUES (fr_exthead.*) 

END FUNCTION 


FUNCTION add_extline(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code, 
	fv_old_uid, 
	fv_new_uid) 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_extline RECORD LIKE extline.* 

	DECLARE extline_curs CURSOR FOR 
	SELECT * 
	FROM extline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 
	AND line_uid = fv_old_uid 

	FOREACH extline_curs INTO fr_extline.* 

		LET fr_extline.cmpy_code = fv_new_cmpy_code 
		LET fr_extline.line_code = fv_new_line_code 
		LET fr_extline.line_uid = fv_new_uid 

		INSERT INTO extline VALUES (fr_extline.*) 

	END FOREACH 

	CLOSE extline_curs 

END FUNCTION 


FUNCTION add_descline(fv_old_line_code, 
	fv_new_cmpy_code, 
	fv_new_line_code, 
	fv_old_uid, 
	fv_new_uid) 

	DEFINE fv_old_line_code, 
	fv_new_line_code LIKE rptlinegrp.line_code, 
	fv_new_cmpy_code LIKE rptlinegrp.cmpy_code, 
	fv_old_uid, 
	fv_new_uid SMALLINT, 
	fr_descline RECORD LIKE descline.* 

	DECLARE descline_curs CURSOR FOR 
	SELECT * 
	FROM descline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = fv_old_line_code 
	AND line_uid = fv_old_uid 

	FOREACH descline_curs INTO fr_descline.* 

		LET fr_descline.cmpy_code = fv_new_cmpy_code 
		LET fr_descline.line_code = fv_new_line_code 
		LET fr_descline.line_uid = fv_new_uid 

		INSERT INTO descline VALUES (fr_descline.*) 

	END FOREACH 

	CLOSE descline_curs 

END FUNCTION 
