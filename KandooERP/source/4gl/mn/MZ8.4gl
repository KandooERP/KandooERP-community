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

	Source code beautified by beautify.pl on 2020-01-02 17:31:37	$Id: $
}


# Purpose - UOM Conversion
# Note: This program IS NOT part of standard Manufacturing

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 
	pr_menunames RECORD LIKE menunames.* 

END GLOBALS 

DEFINE 
mv_waste SMALLINT, 
mv_count SMALLINT, 
gl_query_text CHAR(600), 
ga_uom_convert_key array[200] OF RECORD 
	from_uom LIKE uomconvert.from_uom_code, 
	to_uom LIKE uomconvert.to_uom_code 
END RECORD, 
gl_uom_convert_ptr SMALLINT, 
gl_uom_convert_max SMALLINT, 
gr_uom_convert RECORD LIKE uomconvert.*, 
gr_uom_convert_lookup RECORD 
	from_description CHAR(30), 
	to_description CHAR(30) 
END RECORD 

#-------------------------------------------------------------------------#
#  OPEN up a window with the form in it AND implement the menu            #
#-------------------------------------------------------------------------#

MAIN 

	#Initial UI Init
	CALL setModuleId("MZ8") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	INITIALIZE gr_uom_convert.*, gr_uom_convert_lookup.* TO NULL 
	INITIALIZE ga_uom_convert_key TO NULL 
	INITIALIZE gl_query_text TO NULL 
	LET gl_uom_convert_ptr = 0 
	LET gl_uom_convert_max = 0 

	OPEN WINDOW w0_item_mast with FORM "M121" 
	CALL  windecoration_m("M121") -- albo kd-762 

	CALL kandoomenu("M", 102) # unit OF measure conversion 
	RETURNING pr_menunames.* 

	MENU pr_menunames.menu_text 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text 
			IF query_uom_convert() THEN 
				IF load_uom_convert() THEN 
					LET gl_uom_convert_ptr = 1 
					CALL get_uom_convert("C") 
					NEXT option pr_menunames.cmd2_code # NEXT 
				END IF 
			END IF 

			CALL display_uom_convert() 
			NEXT option pr_menunames.cmd2_code # NEXT 

		COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text 
			IF gl_uom_convert_max > 0 THEN 
				CALL get_uom_convert("N") 
			ELSE 
				LET msgresp = kandoomsg("M",9717,"") 
				# ERROR "There IS nothing FOR you TO look at"
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 

			CALL display_uom_convert() 

		COMMAND pr_menunames.cmd3_code pr_menunames.cmd3_text 
			IF gl_uom_convert_max > 0 THEN 
				CALL get_uom_convert("P") 
			ELSE 
				LET msgresp = kandoomsg("M",9717,"") 
				#ERROR "There IS nothing FOR you TO look at"
				NEXT option pr_menunames.cmd1_code # query 
			END IF 
			CALL display_uom_convert() 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text 
			IF gl_query_text IS NOT NULL THEN 
				IF input_uom_convert(1) THEN 
					CALL load_uom_convert() RETURNING mv_waste 

					FOR mv_count = 1 TO gl_uom_convert_max 
						IF (ga_uom_convert_key[mv_count].from_uom 
						= gr_uom_convert.from_uom_code 
						AND ga_uom_convert_key[mv_count].to_uom 
						= gr_uom_convert.to_uom_code) THEN 
							LET gl_uom_convert_ptr=mv_count 
							EXIT FOR 
						END IF 
					END FOR 
				END IF 

				IF gl_uom_convert_max > 0 THEN 
					CALL get_uom_convert("C") 
				END IF 
			ELSE 
				LET msgresp = kandoomsg("M",9718,"") 
				#error"must perform a query before you can add a convertion"
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 
			CALL display_uom_convert() 

		COMMAND pr_menunames.cmd5_code pr_menunames.cmd5_text 
			IF gl_uom_convert_max > 0 THEN 
				CALL input_uom_convert(0) RETURNING mv_waste 
				CALL load_uom_convert() RETURNING mv_waste 
				CALL get_uom_convert("C") 
			ELSE 
				LET msgresp = kandoomsg("M",9719,"") 
				# ERROR "There are no records that can be updated"
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 
			CALL display_uom_convert() 

		COMMAND pr_menunames.cmd6_code pr_menunames.cmd6_text 
			IF gl_uom_convert_max>0 THEN 
				IF delete_uom_convert() THEN 
					IF gl_uom_convert_ptr = gl_uom_convert_max THEN 
						IF gl_uom_convert_max = 1 THEN 
							LET msgresp = kandoomsg("M",9720,"") 
							# ERROR "There are no more records left TO delete"
							LET gl_uom_convert_max = 0 
							LET gl_uom_convert_ptr = 0 
						ELSE 
							LET gl_uom_convert_ptr = gl_uom_convert_max - 1 
						END IF 
					END IF 
				END IF 

				IF gl_uom_convert_max > 0 THEN 
					CALL load_uom_convert() RETURNING mv_waste 
					CALL get_uom_convert("C") 
				ELSE 
					INITIALIZE gr_uom_convert.*,gr_uom_convert_lookup.* TO NULL 
				END IF 
			ELSE 
				LET msgresp = kandoomsg("M",9720,"") 
				# ERROR "There are no records TO be deleted"
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 

			IF gl_uom_convert_max > 0 THEN 
				CALL display_uom_convert() 
			ELSE 
				CLEAR FORM 
			END IF 

		COMMAND pr_menunames.cmd7_code pr_menunames.cmd7_text 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 

END MAIN 

#-------------------------------------------------------------------------#
#FUNCTION TO query by example on the unit of measure conversion SCREEN    #
#-------------------------------------------------------------------------#

FUNCTION query_uom_convert() 

	DEFINE 
	fv_where_part CHAR(500), 
	fv_query_ok SMALLINT 


	LET fv_query_ok = 0 
	CLEAR FORM 
	LET msgresp = kandoomsg("M",1505,"") 
	# MESSAGE "Enter Selection Criteria AND press ESC"

	CONSTRUCT fv_where_part 
	ON uomconvert.from_uom_code,uomconvert.to_uom_code, 
	uomconvert.multiplier_qty 
	FROM from_uom_code,to_uom_code,multiplier_qty 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		LET msgresp = kandoomsg("M",9555,"") 
		#ERROR "Query Aborted"
	ELSE 
		LET fv_query_ok = 1 
		LET gl_query_text = "SELECT from_uom_code, to_uom_code ", 
		"FROM uomconvert ", 
		"WHERE ", fv_where_part clipped, " ", 
		"ORDER BY from_uom_code, to_uom_code" 
	END IF 
	RETURN fv_query_ok 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load the CURSOR INTO an ARRAY of the key VALUES            #
#-------------------------------------------------------------------------#

FUNCTION load_uom_convert() 

	DEFINE 
	fv_array_count SMALLINT, 
	fv_exists SMALLINT, 
	fv_from_uom LIKE uomconvert.from_uom_code, 
	fv_to_uom LIKE uomconvert.to_uom_code 


	PREPARE fv_query_id FROM gl_query_text 
	DECLARE s_scurs SCROLL CURSOR FOR fv_query_id 

	LET fv_exists = 0 
	LET fv_array_count = 0 

	FOREACH s_scurs INTO fv_from_uom,fv_to_uom 
		IF fv_array_count = 200 THEN 
			LET msgresp = kandoomsg("M",9721,"") 
			# ERROR "Only the first 200 conversions will be used"
			EXIT FOREACH 
		ELSE 
			LET fv_array_count = fv_array_count + 1 
			LET ga_uom_convert_key[fv_array_count].from_uom = fv_from_uom 
			LET ga_uom_convert_key[fv_array_count].to_uom = fv_to_uom 
		END IF 
	END FOREACH 

	IF fv_array_count = 0 THEN 
		LET msgresp = kandoomsg("M",9722,"") 
		# ERROR "There are no conversions FOR you TO use"
	ELSE 
		LET fv_exists = 1 
		LET gl_uom_convert_max = fv_array_count 
		CLOSE s_scurs 
	END IF 

	RETURN fv_exists 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY one unit of measure conversion RECORD on the SCREEN#
#-------------------------------------------------------------------------#

FUNCTION display_uom_convert() 

	DISPLAY gr_uom_convert.from_uom_code,gr_uom_convert.to_uom_code, 
	gr_uom_convert.multiplier_qty, 
	gr_uom_convert_lookup.from_description, 
	gr_uom_convert_lookup.to_description 
	TO from_uom_code,to_uom_code,multiplier_qty,from_description, 
	to_description 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO get the current RECORD INTO a global variable              #
#-------------------------------------------------------------------------#

FUNCTION get_uom_convert(fp_record) 

	DEFINE 
	fp_record CHAR(1) 


	CASE 
		WHEN fp_record = "C" 
			LET gl_uom_convert_ptr = gl_uom_convert_ptr 

		WHEN fp_record = "N" 
			IF gl_uom_convert_ptr = gl_uom_convert_max THEN 
				LET msgresp = kandoomsg("M",9530,"") 
				# ERROR "There are no more conversions in this direction"
			ELSE 
				LET gl_uom_convert_ptr = gl_uom_convert_ptr + 1 
			END IF 

		WHEN fp_record = "P" 
			IF gl_uom_convert_ptr = 1 THEN 
				LET msgresp = kandoomsg("M",9530,"") 
				# ERROR "There are no more conversions in this direction"
			ELSE 
				LET gl_uom_convert_ptr = gl_uom_convert_ptr - 1 
			END IF 
	END CASE 

	SELECT * 
	INTO gr_uom_convert.* 
	FROM uomconvert 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND from_uom_code = ga_uom_convert_key[gl_uom_convert_ptr].from_uom 
	AND to_uom_code = ga_uom_convert_key[gl_uom_convert_ptr].to_uom 

	SELECT desc_text 
	INTO gr_uom_convert_lookup.from_description 
	FROM uom 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND uom_code = gr_uom_convert.from_uom_code 

	SELECT desc_text 
	INTO gr_uom_convert_lookup.to_description 
	FROM uom 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND uom_code = gr_uom_convert.to_uom_code 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO INPUT data FROM the SCREEN                                 #
#-------------------------------------------------------------------------#

FUNCTION input_uom_convert(fp_add) 

	DEFINE 
	fp_add SMALLINT, 
	fr_new_uom_convert RECORD LIKE uomconvert.*, 
	fv_from_description LIKE uom.desc_text, 
	fv_to_description LIKE uom.desc_text, 
	fv_data_ok SMALLINT, 
	fv_from_multiplier DECIMAL(6,2), 
	fv_to_multiplier DECIMAL(6,2) 


	LET msgresp = kandoomsg("M",1505,"") 
	# MESSAGE "Enter conversion data AND press ESC TO continue"

	IF fp_add THEN 
		INITIALIZE fr_new_uom_convert.*, fv_from_description, fv_to_description 
		TO NULL 
	ELSE 
		LET fr_new_uom_convert.* = gr_uom_convert.* 
		LET fv_from_description = gr_uom_convert_lookup.from_description 
		LET fv_to_description = gr_uom_convert_lookup.to_description 
	END IF 

	CLEAR FORM 

	DISPLAY fr_new_uom_convert.from_uom_code, 
	fr_new_uom_convert.to_uom_code, 
	fr_new_uom_convert.multiplier_qty, 
	fv_from_description, fv_to_description 
	TO from_uom_code,to_uom_code, 
	multiplier_qty,from_description, 
	to_description 

	INPUT fr_new_uom_convert.from_uom_code, 
	fr_new_uom_convert.to_uom_code, 
	fr_new_uom_convert.multiplier_qty 
	WITHOUT DEFAULTS 
	FROM from_uom_code,to_uom_code,multiplier_qty 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD from_uom_code 
			LET fv_from_description = 
			lookup_uom(fr_new_uom_convert.from_uom_code) 

			IF fv_from_description IS NULL THEN 
				LET fr_new_uom_convert.from_uom_code = NULL 
				DISPLAY fr_new_uom_convert.from_uom_code 
				TO from_uom_code 
				NEXT FIELD from_uom_code 
			END IF 

			DISPLAY fr_new_uom_convert.from_uom_code,fv_from_description 
			TO from_uom_code,from_description 

		AFTER FIELD to_uom_code 
			LET fv_to_description = lookup_uom(fr_new_uom_convert.to_uom_code) 

			IF fv_to_description IS NULL THEN 
				LET fr_new_uom_convert.to_uom_code = NULL 
				DISPLAY fr_new_uom_convert.to_uom_code 
				TO to_uom_code 
				NEXT FIELD to_uom_code 
			END IF 

			DISPLAY fr_new_uom_convert.to_uom_code,fv_to_description 
			TO to_uom_code,to_description 

		BEFORE FIELD multiplier_qty 
			IF (fr_new_uom_convert.multiplier_qty IS NULL 
			OR fr_new_uom_convert.from_uom_code<>gr_uom_convert.from_uom_code 
			OR fr_new_uom_convert.to_uom_code<>gr_uom_convert.to_uom_code) THEN 
				LET fr_new_uom_convert.multiplier_qty = fv_to_multiplier 
				/fv_from_multiplier 
				DISPLAY fr_new_uom_convert.multiplier_qty 
				TO multiplier_qty 
			END IF 

		AFTER FIELD multiplier_qty 
			IF fr_new_uom_convert.multiplier_qty IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "A value must be entered in this field"
				NEXT FIELD multiplier_qty 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF fr_new_uom_convert.from_uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M",9547,"") 
				# ERROR "You must enter a value in the FROM unit of meassure"
				NEXT FIELD from_uom_code 
			ELSE 
				LET fv_from_description = 
				lookup_uom( fr_new_uom_convert.from_uom_code) 

				IF fv_from_description IS NULL THEN 
					LET msgresp = kandoomsg("M",9548,"") 
					# ERROR "unit of meassure does NOT exist in the database"
					NEXT FIELD from_uom_code 
				END IF 
			END IF 

			IF fr_new_uom_convert.to_uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M",9547,"") 
				#ERROR "You must enter a value in the TO unit of meassure"
				NEXT FIELD to_uom_code 
			ELSE 
				LET fv_from_description 
				= lookup_uom( fr_new_uom_convert.to_uom_code) 

				IF fv_from_description IS NULL THEN 
					LET msgresp = kandoomsg("M",9548,"") 
					# ERROR "unit of meassure does NOT exist in the database"
					NEXT FIELD from_uom_code 
				END IF 
			END IF 

			IF fr_new_uom_convert.multiplier_qty IS NULL THEN 
				LET msgresp = kandoomsg("M",9723,"") 
				#ERROR "You must enter a value in the conversion multiplier"
				NEXT FIELD multiplier_qty 
			END IF 

		ON KEY (control-B) 
			CASE 
				WHEN infield(from_uom_code) 
					LET fr_new_uom_convert.from_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					LET fv_from_description 
					= lookup_uom(fr_new_uom_convert.from_uom_code) 

					DISPLAY fr_new_uom_convert.from_uom_code,fv_from_description 
					TO from_uom_code,from_description 

				WHEN infield(to_uom_code) 
					LET fr_new_uom_convert.to_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					LET fv_to_description 
					= lookup_uom( fr_new_uom_convert.to_uom_code) 

					DISPLAY fr_new_uom_convert.to_uom_code,fv_to_description 
					TO to_uom_code,to_description 
			END CASE 
	END INPUT 

	LET fv_data_ok = 0 
	IF (int_flag = 0 AND quit_flag = 0) THEN 
		BEGIN WORK 
			IF fp_add THEN 
				INSERT 
				INTO uomconvert 
				(cmpy_code, from_uom_code, to_uom_code, multiplier_qty, 
				last_change_date, last_user_text ,last_program_text) 
				VALUES (glob_rec_kandoouser.cmpy_code, fr_new_uom_convert.from_uom_code, 
				fr_new_uom_convert.to_uom_code, 
				fr_new_uom_convert.multiplier_qty, 
				today, glob_rec_kandoouser.sign_on_code, "MZ8"); 
			ELSE 
				UPDATE uomconvert 
				SET (cmpy_code, from_uom_code, to_uom_code, 
				multiplier_qty, last_change_date, 
				last_user_text ,last_program_text) 
				= (glob_rec_kandoouser.cmpy_code, fr_new_uom_convert.from_uom_code, 
				fr_new_uom_convert.to_uom_code, 
				fr_new_uom_convert.multiplier_qty, 
				today,glob_rec_kandoouser.sign_on_code,"MZ8") 
				WHERE uomconvert.from_uom_code = gr_uom_convert.from_uom_code 
				AND uomconvert.to_uom_code = gr_uom_convert.to_uom_code 
			END IF 

			IF status <> 0 THEN 
				LET msgresp = kandoomsg("M",9550,"") 
				# ERROR "Error in storing data"
				ROLLBACK WORK 
				INITIALIZE fr_new_uom_convert.* TO NULL 
			ELSE 
			COMMIT WORK 
			LET gr_uom_convert.* = fr_new_uom_convert.* 
			LET fv_data_ok = 1 
		END IF 
	ELSE 
		LET int_flag = 0 
		LET quit_flag = 0 

		IF fp_add THEN 
			LET msgresp = kandoomsg("M",9549,"") 
			# ERROR "Add Aborted"
		ELSE 
			LET msgresp = kandoomsg("M",9562,"") 
			# ERROR "Update Aborted"
		END IF 

		INITIALIZE fr_new_uom_convert.* TO NULL 
	END IF 

	RETURN fv_data_ok 

END FUNCTION 

#-------------------------------------------------------------------------#
#  delete the currently displayed UOM conversion FROM the database        #
#-------------------------------------------------------------------------#

FUNCTION delete_uom_convert() 

	DEFINE 
	fv_delete_ok SMALLINT 


	LET fv_delete_ok = 0 
	BEGIN WORK 

		DELETE 
		FROM uomconvert 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND from_uom_code = ga_uom_convert_key[gl_uom_convert_ptr].from_uom 
		AND to_uom_code = ga_uom_convert_key[gl_uom_convert_ptr].to_uom 

		IF status <> 0 THEN 
			LET msgresp = kandoomsg("M",9724,"") 
			# ERROR "Having trouble deleting this conversion"
			ROLLBACK WORK 
		ELSE 
			LET fv_delete_ok = 1 
		COMMIT WORK 
	END IF 

	RETURN fv_delete_ok 

END FUNCTION 

#-------------------------------------------------------------------------#
# FUNCTION TO RETURN the description of the unit of measure code specified#
#-------------------------------------------------------------------------#

FUNCTION lookup_uom(fp_unit_of_measure) 

	DEFINE 
	fp_unit_of_measure LIKE uom.uom_code, 
	fv_uom_description LIKE uom.desc_text 


	SELECT desc_text 
	INTO fv_uom_description 
	FROM uom 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND uom_code = fp_unit_of_measure 

	IF status <> 0 THEN 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("M",9548,"") 
			# ERROR "Unit Of Measure does NOT exist in the database"
		ELSE 
			LET msgresp = kandoomsg("M",9553,"") 
			#ERROR "Your NOT allowed duplicate UOM's , but you have some"
		END IF 

		LET fv_uom_description = NULL 
	END IF 

	RETURN fv_uom_description 

END FUNCTION 
