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

	Source code beautified by beautify.pl on 2020-01-02 17:31:21	$Id: $
}


# Purpose - Configuration Maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 
	idx SMALLINT, 
	pv_cont SMALLINT, 
	err_message CHAR(50), 
	err_continue CHAR(1), 
	pr_menunames RECORD LIKE menunames.*, 

	pr_config RECORD 
		generic_part_code LIKE configuration.generic_part_code, 
		desc_text LIKE product.desc_text, 
		config_ind LIKE configuration.config_ind, 
		option_num LIKE configuration.option_num 
	END RECORD, 

	pa_config array[500] OF RECORD 
		generic_part_code LIKE configuration.generic_part_code, 
		desc_text LIKE product.desc_text, 
		config_ind LIKE configuration.config_ind, 
		option_num LIKE configuration.option_num 
	END RECORD, 

	pr_config_specific RECORD 
		specific_part_code LIKE configuration.specific_part_code, 
		desc_text LIKE product.desc_text, 
		factor_amt LIKE configuration.factor_amt 
	END RECORD, 

	pa_config_specific array[500] OF RECORD 
		specific_part_code LIKE configuration.specific_part_code, 
		desc_text LIKE product.desc_text, 
		factor_amt LIKE configuration.factor_amt 
	END RECORD 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M1D") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL generic_select() 

END MAIN 


FUNCTION generic_select() 

	DEFINE 
	fv_cnt SMALLINT, 
	fv_scrn SMALLINT, 
	fv_query_text CHAR(500), 
	fv_where_text CHAR(500) 

	OPEN WINDOW w1_m1d with FORM "M101" 
	CALL  windecoration_m("M101") -- albo kd-762 

	WHILE true 
		CLEAR FORM 
		LET msgresp = kandoomsg("M",1500,"") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_text 
		ON generic_part_code, desc_text, c.config_ind, option_num 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1532, "") 
		# MESSAGE "Searching database - please wait"

		LET fv_query_text = "SELECT unique c.generic_part_code, p.desc_text, ", 
		"c.config_ind, c.option_num ", 
		"FROM prodmfg m, configuration c, product p ", 
		"WHERE m.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND m.part_type_ind = 'G' ", 
		"AND c.cmpy_code = m.cmpy_code ", 
		"AND c.cmpy_code = p.cmpy_code ", 
		"AND c.generic_part_code = m.part_code ", 
		"AND c.generic_part_code = p.part_code ", 
		"AND ", fv_where_text clipped, " ", 
		"ORDER BY c.generic_part_code" 

		PREPARE sl_stmt1 FROM fv_query_text 
		DECLARE s_generic CURSOR FOR sl_stmt1 

		LET fv_cnt = 0 

		FOREACH s_generic INTO pr_config.* 
			LET fv_cnt = fv_cnt + 1 

			IF fv_cnt = 500 THEN 
				LET msgresp = kandoomsg("M",9639,"") 
				# ERROR "Only the first 500 configurations have been selected"
				EXIT FOREACH 
			END IF 

			LET pa_config[fv_cnt].* = pr_config.* 
		END FOREACH 

		IF fv_cnt = 0 THEN 
			LET msgresp = kandoomsg("M",9610,"") 
			# ERROR "The query returned no rows"
			CONTINUE WHILE 
		END IF 

		OPTIONS 
		INSERT KEY f36 # this IS TO disable INSERT in the INPUT ARRAY 

		CALL set_count(fv_cnt) 

		WHILE true 
			LET msgresp = kandoomsg("M",1536,"") 
			# MESSAGE "RETURN on line TO Edit, F2 TO Delete, F3 Fwd, F4 Bwd-DEL"

			INPUT ARRAY pa_config WITHOUT DEFAULTS FROM config_generic.* 

				ON ACTION "WEB-HELP" -- albo kd-376 
					CALL onlinehelp(getmoduleid(),null) 

				BEFORE ROW 
					LET idx = arr_curr() 
					LET fv_scrn = scr_line() 

				ON KEY (RETURN) 
					IF pa_config[idx].generic_part_code IS NOT NULL THEN 
						CALL edit_items() 
						OPTIONS 
						INSERT KEY f36 
						DISPLAY pa_config[idx].* TO config_generic[fv_scrn].* 
					END IF 

				BEFORE DELETE 
					LET msgresp = kandoomsg("M",4500,"") 
					# prompt "Are you sure you want TO delete this product?"

					IF msgresp = "N" THEN 
						EXIT INPUT 
					END IF 

					LET msgresp = kandoomsg("M",1536,"") 
					# MESSAGE "RETURN on line TO Edit, F2 TO Delete, F3 Fwd, F4"

					CALL delete_config() 

				AFTER FIELD generic_part_code 
					IF (fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right")) 
					AND pa_config[idx + 1].generic_part_code IS NULL THEN 
						LET msgresp = kandoomsg("M",9530,"") 
						#ERROR "There are no more rows in the direction you are"
						NEXT FIELD generic_part_code 
					END IF 

			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT WHILE 
			END IF 

		END WHILE 
	END WHILE 

	CLOSE WINDOW w1_m1d 

END FUNCTION 



FUNCTION edit_items() 

	DEFINE 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_factor_tot DECIMAL(5,3), 
	fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_arr_size SMALLINT, 
	fv_search SMALLINT, 
	fv_delete SMALLINT, 
	fv_insert SMALLINT, 
	fv_prodmfg_config LIKE prodmfg.config_ind, 
	fv_config_ind LIKE prodmfg.config_ind, 
	fv_part_type_ind LIKE prodmfg.part_type_ind, 
	fv_part_code LIKE configuration.specific_part_code 

	OPEN WINDOW w2_m1d with FORM "M104" 
	CALL  windecoration_m("M104") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") # MESSAGE " ESC TO Accept - DEL TO Exit"

	DISPLAY BY NAME pa_config[idx].* 

	DECLARE c_specific CURSOR FOR 
	SELECT specific_part_code, desc_text, factor_amt 
	FROM configuration c, product p 
	WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND c.cmpy_code = p.cmpy_code 
	AND c.generic_part_code = pa_config[idx].generic_part_code 
	AND c.specific_part_code = p.part_code 
	AND c.config_ind = pa_config[idx].config_ind 

	LET fv_cnt = 0 
	INITIALIZE pa_config_specific TO NULL 

	FOREACH c_specific INTO pr_config_specific.* 
		LET fv_cnt = fv_cnt + 1 
		LET pa_config_specific[fv_cnt].* = pr_config_specific.* 

		IF fv_cnt = 500 THEN 
			LET msgresp = kandoomsg("M",9567,"") 
			# ERROR "Only the first 500 products have been selected"
			EXIT FOREACH 
		END IF 

		IF fv_cnt < 12 THEN 
			DISPLAY pa_config_specific[fv_cnt].* TO config_specific[fv_cnt].* 
		END IF 
	END FOREACH 

	LET pr_config.* = pa_config[idx].* 

	SELECT config_ind 
	INTO fv_config_ind 
	FROM prodmfg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_config.generic_part_code 

	OPTIONS 
	INSERT KEY f1 

	INPUT BY NAME pr_config.config_ind, 
	pr_config.option_num 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD config_ind 
			IF pr_config.config_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9566,"") 
				# ERROR "Configuration type must be entered"
				NEXT FIELD config_ind 
			END IF 

			IF pr_config.config_ind NOT matches "[FO]" THEN 
				LET msgresp = kandoomsg("M",9593,"") 
				# ERROR "Configuration type must be 'F' OR 'O'"
				NEXT FIELD config_ind 
			END IF 

			IF pr_config.config_ind = "F" THEN 
				LET pr_config.option_num = 1 
				DISPLAY BY NAME pr_config.option_num 
				EXIT INPUT 
			END IF 

		AFTER FIELD option_num 
			IF pr_config.option_num IS NULL THEN 
				LET msgresp = kandoomsg("M",9630,"") 
				# ERROR "Option quantity must be entered"
				NEXT FIELD option_num 
			END IF 

			IF pr_config.option_num < 1 THEN 
				LET msgresp = kandoomsg("M",9631,"") 
				# ERROR "Option quantity must be greater than zero"
				NEXT FIELD option_num 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW w2_m1d 
		LET msgresp = kandoomsg("M",9642,"") 
		# ERROR "Edit aborted"
		RETURN 
	END IF 

	LET pv_cont = true 
	CALL set_count(fv_cnt) 

	WHILE true 

		LET fv_delete = false 

		LET msgresp = kandoomsg("M",1516,"") 
		# MESSAGE "F1 Insert, F2 Delete, F3 Fwd, F4 Bwd - ESC TO Accept, DEL TO"

		INPUT ARRAY pa_config_specific WITHOUT DEFAULTS FROM config_specific.* 

			BEFORE ROW 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 
				LET fv_arr_size = arr_count() 
				LET fv_insert = false 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE DELETE 
				IF fv_idx = 1 AND NOT fv_insert 
				AND (fv_arr_size = 1 
				OR (fv_arr_size = 2 
				AND pa_config_specific[2].specific_part_code IS null)) THEN 
					LET msgresp = kandoomsg("M",9643,"") 
					# ERROR "Cannot delete the last product - Use the previous
					#        SCREEN instead"
					LET fv_delete = true 
					EXIT INPUT 
				END IF 

			BEFORE INSERT 
				LET fv_insert = true 

			AFTER FIELD specific_part_code 
				IF fgl_lastkey() != fgl_keyval("accept") THEN 
					IF pa_config_specific[fv_idx].specific_part_code IS NULL 
					THEN 
						IF fgl_lastkey() != fgl_keyval("up") 
						OR fv_idx < fv_arr_size 
						OR (fv_idx = fv_arr_size 
						AND pa_config_specific[fv_idx].factor_amt IS NOT null) 
						THEN 
							LET msgresp = kandoomsg("M",9632,"") 
							# ERROR "Specific product code must be entered"
							NEXT FIELD specific_part_code 
						END IF 
					ELSE 
						IF pa_config_specific[fv_idx].specific_part_code = 
						pr_config.generic_part_code THEN 
							LET msgresp = kandoomsg("M",9633,"") 
							# ERROR "This IS the generic product code"
							NEXT FIELD specific_part_code 
						END IF 

						SELECT desc_text 
						INTO pa_config_specific[fv_idx].desc_text 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = 
						pa_config_specific[fv_idx].specific_part_code 

						IF status = notfound THEN 
							LET msgresp = kandoomsg("M",9511,"") 
							#ERROR "This product does NOT exist in the database"
							NEXT FIELD specific_part_code 
						END IF 

						SELECT part_type_ind, config_ind 
						INTO fv_part_type_ind, fv_prodmfg_config 
						FROM prodmfg 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = 
						pa_config_specific[fv_idx].specific_part_code 

						IF status = notfound THEN 
							LET msgresp = kandoomsg("M",9569,"") 
							# ERROR "This product IS NOT SET up as a
							#        manufacturing product"
							NEXT FIELD specific_part_code 
						END IF 

						IF fv_config_ind = "Y" 
						AND fv_part_type_ind matches "[RP]" THEN 
							LET msgresp = kandoomsg("M",9634,"") 
							# ERROR "Cannot add raw materials OR phantoms FOR
							#        this generic product"
							NEXT FIELD specific_part_code 
						END IF 

						IF fv_config_ind = "Y" 
						AND fv_part_type_ind = "G" 
						AND fv_prodmfg_config = "Y" THEN 
							LET msgresp = kandoomsg("M",9635,"") 
							# ERROR "Cannot add configurable generic products
							#        FOR this generic product"
							NEXT FIELD specific_part_code 
						END IF 

						LET fv_search = fv_arr_size 
						IF fv_insert THEN 
							LET fv_search = fv_search + 1 
						END IF 

						FOR fv_cnt = 1 TO fv_search 
							IF pa_config_specific[fv_idx].specific_part_code = 
							pa_config_specific[fv_cnt].specific_part_code 
							AND fv_cnt != fv_idx THEN 
								LET msgresp = kandoomsg("M",9597,"") 
								# error"This product IS already a configuration
								#       of the generic product"
								NEXT FIELD specific_part_code 
							END IF 
						END FOR 

						DISPLAY pa_config_specific[fv_idx].desc_text 
						TO config_specific[fv_scrn].desc_text 

						IF fgl_lastkey() = fgl_keyval("down") 
						AND pa_config_specific[fv_idx].factor_amt IS NULL THEN 
							NEXT FIELD factor_amt 
						END IF 
					END IF 
				END IF 

			BEFORE FIELD factor_amt 
				IF pa_config_specific[fv_idx].factor_amt IS NULL THEN 
					LET pa_config_specific[fv_idx].factor_amt = 0 

					DISPLAY pa_config_specific[fv_idx].factor_amt 
					TO config_specific[fv_scrn].factor_amt 
				END IF 

			AFTER FIELD factor_amt 
				IF pa_config_specific[fv_idx].factor_amt IS NULL THEN 
					LET msgresp = kandoomsg("M",9636,"") 
					# ERROR "Quantity factor must be entered"
					NEXT FIELD factor_amt 
				END IF 

				IF pa_config_specific[fv_idx].factor_amt < 0 
				OR pa_config_specific[fv_idx].factor_amt > 1 THEN 
					LET msgresp = kandoomsg("M",9637,"") 
					# ERROR "Quantity factor must be between 0 AND 1"
					NEXT FIELD factor_amt 
				END IF 

			ON KEY (control-b) 
				IF infield (specific_part_code) THEN 
					CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "") RETURNING fv_part_code 

					IF fv_part_code IS NOT NULL THEN 
						LET pa_config_specific[fv_idx].specific_part_code = 
						fv_part_code 
						DISPLAY pa_config_specific[fv_idx].specific_part_code 
						TO config_specific[fv_scrn].specific_part_code 
					END IF 
				END IF 


			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET pv_cont = false 
					EXIT INPUT 
				END IF 

				LET fv_factor_tot = 0 
				LET fv_cnt1 = 0 
				LET fv_search = fv_arr_size 

				IF fv_insert THEN 
					LET fv_search = fv_search + 1 
				END IF 

				FOR fv_cnt = 1 TO fv_search 
					IF pa_config_specific[fv_cnt].factor_amt IS NOT NULL THEN 
						LET fv_factor_tot = fv_factor_tot + 
						pa_config_specific[fv_cnt].factor_amt 
						LET fv_cnt1 = fv_cnt1 + 1 
					END IF 
				END FOR 

				IF pr_config.option_num > fv_cnt1 THEN 
					LET msgresp = kandoomsg("M",9613,"") 
					# ERROR "Number of specific products must be >= option qty"
					NEXT FIELD specific_part_code 
				END IF 

				IF fv_factor_tot > 1 THEN 
					LET msgresp = kandoomsg("M",9638,"") 
					# ERROR "The total of all quantity factors must be <= 1"
					NEXT FIELD specific_part_code 
				END IF 

		END INPUT 

		IF NOT fv_delete THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w2_m1d 

	IF NOT pv_cont THEN 
		LET msgresp = kandoomsg("M",9642,"") 
		# ERROR "Edit aborted"
		RETURN 
	END IF 

	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		LET err_message = "M1D - DELETE FROM configuration failed" 

		DELETE FROM configuration 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND generic_part_code = pr_config.generic_part_code 

		LET err_message = "M1D - Insert INTO configuration failed" 

		IF fv_insert THEN 
			LET fv_arr_size = fv_arr_size + 1 
		END IF 

		FOR fv_cnt = 1 TO fv_arr_size 
			IF pa_config_specific[fv_cnt].specific_part_code IS NOT NULL 
			AND pa_config_specific[fv_cnt].factor_amt IS NOT NULL THEN 

				INSERT INTO configuration 
				VALUES (glob_rec_kandoouser.cmpy_code, 
				pr_config.generic_part_code, 
				pr_config.config_ind, 
				pa_config_specific[fv_cnt].specific_part_code, 
				pr_config.option_num, 
				pa_config_specific[fv_cnt].factor_amt, 
				today, 
				glob_rec_kandoouser.sign_on_code, 
				"M1D") 

			END IF 
		END FOR 

	COMMIT WORK 
	WHENEVER ERROR stop 

	LET pa_config[idx].* = pr_config.* 

END FUNCTION 



FUNCTION delete_config() 

	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		LET err_message = "M1D - DELETE FROM configuration failed" 

		DELETE FROM configuration 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND generic_part_code = pa_config[idx].generic_part_code 

	COMMIT WORK 
	WHENEVER ERROR stop 

END FUNCTION 
