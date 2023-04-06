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


# Purpose - Configuration Add

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../mn/M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 
	pr_menunames RECORD LIKE menunames.*, 
	err_continue CHAR(1), 
	err_message CHAR(50), 
	pv_cont SMALLINT, 
	pv_ins_cnt SMALLINT, 

	pr_config RECORD 
		generic_part_code LIKE configuration.generic_part_code, 
		desc_text LIKE product.desc_text, 
		config_ind LIKE configuration.config_ind, 
		option_num LIKE configuration.option_num 
	END RECORD, 

	pa_config_specific array[200] OF RECORD 
		specific_part_code LIKE configuration.specific_part_code, 
		desc_text LIKE product.desc_text, 
		factor_amt LIKE configuration.factor_amt 
	END RECORD 

END GLOBALS 


MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("M1B") -- albo 
	CALL ui_init(0) 	#Initial UI Init

	CALL authenticate(getmoduleid()) 

	CALL input_generic() 

END MAIN 


FUNCTION input_generic() 

	DEFINE 
	fv_display_text CHAR (32), 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fv_generic_part_code LIKE configuration.generic_part_code 

	OPEN WINDOW w1_m100 with FORM "M100" 
	CALL  windecoration_m("M100") -- albo kd-762 

	WHILE true 
		CLEAR FORM 
		LET msgresp = kandoomsg("M", 1505, "") 
		# MESSAGE "ESC TO Accept - DEL TO Exit"

		INITIALIZE pr_config TO NULL 
		LET pr_config.option_num = 1 

		INPUT BY NAME pr_config.generic_part_code, 
		pr_config.config_ind, 
		pr_config.option_num 
		WITHOUT DEFAULTS 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD generic_part_code 
				IF pr_config.generic_part_code IS NULL THEN 
					LET msgresp = kandoomsg("M", 9627, "") 
					# ERROR "Generic product code must be entered"
					NEXT FIELD generic_part_code 
				END IF 

				SELECT unique generic_part_code 
				FROM configuration 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND generic_part_code = pr_config.generic_part_code 

				IF status != notfound THEN 
					LET msgresp = kandoomsg("M",9628,"") 
					# ERROR "This product already has configurations FOR it"
					NEXT FIELD generic_part_code 
				END IF 

				SELECT desc_text 
				INTO pr_config.desc_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_config.generic_part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9511,"") 
					#ERROR "This product does NOT exist in the database-Try Win"
					NEXT FIELD generic_part_code 
				END IF 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_config.generic_part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9569,"") 
					# ERROR "This product IS NOT SET up as a manufacturing prod"
					NEXT FIELD generic_part_code 
				END IF 

				IF fr_prodmfg.part_type_ind <> "G" THEN 
					LET msgresp = kandoomsg("M",9629,"") 
					# ERROR "This product IS NOT generic"
					NEXT FIELD generic_part_code 
				END IF 

				DISPLAY BY NAME pr_config.desc_text 

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

			ON KEY (control-b) 
				IF infield(generic_part_code) THEN 
					CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "G") RETURNING fv_generic_part_code 

					IF fv_generic_part_code IS NOT NULL THEN 
						LET pr_config.generic_part_code = fv_generic_part_code 
						DISPLAY BY NAME pr_config.generic_part_code 
					END IF 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

		CALL input_specific(fr_prodmfg.config_ind) 

		IF NOT pv_cont THEN 
			EXIT WHILE 
		END IF 
		{
		        OPEN WINDOW w2_cont AT 8,13 with 5 rows, 51 columns      -- albo  KD-762
		            attributes (border, white)
		}
		IF pv_ins_cnt = 0 THEN 
			LET fv_display_text = kandooword("No congfig Add","M04") 
			DISPLAY fv_display_text at 4,2 

		ELSE 
			LET fv_display_text = kandooword("Config Add","M03") 
			DISPLAY fv_display_text at 4,2 

		END IF 

		CALL kandoomenu("M",164) RETURNING pr_menunames.* # add 
		MENU pr_menunames.menu_text 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # CONTINUE 
				EXIT MENU 

			COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text # EXIT 
				LET pv_cont = false 
				EXIT MENU 

			COMMAND KEY (interrupt) 
				LET pv_cont = false 
				EXIT MENU 
		END MENU 

		--        CLOSE WINDOW w2_cont     -- albo  KD-762

		IF pv_cont THEN 
			CONTINUE WHILE 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW w1_m100 

END FUNCTION 


FUNCTION input_specific(fv_config_ind) 

	DEFINE fv_factor_tot DECIMAL (5,3), 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_idx SMALLINT, 
	fv_search SMALLINT, 
	fv_insert SMALLINT, 
	fv_arr_size SMALLINT, 
	fv_scrn SMALLINT, 
	fv_config_ind LIKE prodmfg.config_ind, 
	fv_part_type_ind LIKE prodmfg.part_type_ind, 
	fv_prodmfg_config LIKE prodmfg.config_ind, 
	fv_part_code LIKE configuration.specific_part_code 

	LET pv_cont = true 
	LET msgresp = kandoomsg("M",1516,"") 
	# MESSAGE "F1 Insert,F2 Delete,F3 Fwd,F4 Bwd,ESC TO Accept, DEL TO Exit"

	INITIALIZE pa_config_specific TO NULL 

	INPUT ARRAY pa_config_specific FROM config_specific.* 

		BEFORE ROW 
			LET fv_idx = arr_curr() 
			LET fv_scrn = scr_line() 
			LET fv_arr_size = arr_count() 
			LET fv_insert = false 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE INSERT 
			LET fv_insert = true 

		AFTER FIELD specific_part_code 
			IF fgl_lastkey() != fgl_keyval("accept") THEN 
				IF pa_config_specific[fv_idx].specific_part_code IS NULL THEN 
					IF fgl_lastkey() != fgl_keyval("up") 
					OR fv_idx < fv_arr_size 
					OR (fv_idx = fv_arr_size 
					AND pa_config_specific[fv_idx].factor_amt IS NOT null) THEN 
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
						# ERROR "This product does NOT exist in the db -Try Win"
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
						# ERROR "This product IS NOT SET up as a mfg product"
						NEXT FIELD specific_part_code 
					END IF 

					IF fv_config_ind = "Y" 
					AND fv_part_type_ind matches "[RP]" THEN 
						LET msgresp = kandoomsg("M",9634,"") 
						# ERROR "Cannot add raw materials OR phantoms FOR this
						#        generic product"
						NEXT FIELD specific_part_code 
					END IF 

					IF fv_config_ind = "Y" 
					AND fv_part_type_ind = "G" 
					AND fv_prodmfg_config = "Y" THEN 
						LET msgresp = kandoomsg("M",9635,"") 
						#ERROR "Cannot add configurable generic products ",
						#      "FOR this generic product"
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
							LET msgresp = kandoomsg("M", 9597, "") 
							# ERROR "This product IS already a configuration
							#        of the generic product"
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
				# ERROR "Number of specific products must be >= option quantity"
				NEXT FIELD specific_part_code 
			END IF 

			IF fv_factor_tot > 1 THEN 
				LET msgresp = kandoomsg("M",9638,"") 
				# ERROR "The total of all quantity factors must be <= 1"
				NEXT FIELD specific_part_code 
			END IF 

	END INPUT 

	IF NOT pv_cont THEN 
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

		LET err_message = "M1B - Insert INTO configuration failed" 
		LET pv_ins_cnt = 0 

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
				"M1B") 

				LET pv_ins_cnt = pv_ins_cnt + 1 
			END IF 
		END FOR 

	COMMIT WORK 
	WHENEVER ERROR stop 

END FUNCTION 
