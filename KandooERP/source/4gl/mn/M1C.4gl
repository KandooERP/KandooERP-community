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


# Purpose - Configuration Inquiry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 
	idx SMALLINT, 
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
	CALL setModuleId("M1C") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL generic_select() 

END MAIN 


FUNCTION generic_select() 

	DEFINE 
	fv_cnt SMALLINT, 
	fv_where_text CHAR(500), 
	fv_query_text CHAR(500) 

	OPEN WINDOW w1_m1c with FORM "M102" 
	CALL  windecoration_m("M102") -- albo kd-762 

	WHILE true 
		CLEAR FORM 
		LET msgresp = kandoomsg("M",1500,"") 
		# MESSAGE "Enter selection criteria - ESC TO Accept, DEL TO Exit"

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
			LET pa_config[fv_cnt].* = pr_config.* 

			IF fv_cnt = 500 THEN 
				LET msgresp = kandoomsg("M",9639,"") 
				# ERROR "Only the first 500 configurations have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF fv_cnt = 0 THEN 
			LET msgresp = kandoomsg("M",9610,"") 
			# ERROR "The query returned no rows"
			CONTINUE WHILE 
		END IF 

		LET msgresp = kandoomsg("M",1517,"") 
		#MESSAGE " RETURN on line TO view specific products, F3 Fwd, F4 Bwd - ",
		#        "DEL TO Exit"

		CALL set_count(fv_cnt) 
		DISPLAY ARRAY pa_config TO config_generic.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","M1C","display-arr-config") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (RETURN) 
				LET idx = arr_curr() 
				CALL display_items() 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
	END WHILE 

	CLOSE WINDOW w1_m1c 

END FUNCTION 



FUNCTION display_items() 

	DEFINE fv_cnt SMALLINT 

	OPEN WINDOW w2_m1c with FORM "M103" 
	CALL  windecoration_m("M103") -- albo kd-762 

	LET msgresp = kandoomsg("M",1509,"") # MESSAGE " F3 Fwd, F4 Bwd - DEL TO Exit"

	DECLARE c_config CURSOR FOR 
	SELECT specific_part_code, desc_text, factor_amt 
	FROM configuration c, product p 
	WHERE c.cmpy_code = p.cmpy_code 
	AND c.specific_part_code = p.part_code 
	AND c.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND c.generic_part_code = pa_config[idx].generic_part_code 

	LET fv_cnt = 0 

	FOREACH c_config INTO pr_config_specific.* 
		LET fv_cnt = fv_cnt + 1 
		LET pa_config_specific[fv_cnt].* = pr_config_specific.* 

		IF fv_cnt = 500 THEN 
			LET msgresp = kandoomsg("M",9567,"") 
			# ERROR "Only the first 500 products have been selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	DISPLAY BY NAME pa_config[idx].* 

	CALL set_count(fv_cnt) 

	DISPLAY ARRAY pa_config_specific TO config_specific.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","M1C","display-arr-config_specific") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW w2_m1c 

END FUNCTION 
