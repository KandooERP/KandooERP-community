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


# Purpose - WHERE Used Inquiry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	rpt_note CHAR(80), 
	formname CHAR(10), 
	rpt_pageno SMALLINT, 
	rpt_length SMALLINT, 
	rpt_wid SMALLINT 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M25") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL query_where() 

END MAIN 



FUNCTION query_where() 

	DEFINE 
	fv_type CHAR(1), 
	fv_select CHAR(500), 
	fv_select_text CHAR(15), 
	fv_cnter SMALLINT, 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT, 

	fa_bor_parents array[1000] OF RECORD 
		fv_type LIKE bor.type_ind, 
		fv_parent LIKE bor.parent_part_code, 
		fv_description LIKE product.desc_text, 
		fv_quantity LIKE bor.required_qty 
	END RECORD, 

	fr_bor RECORD LIKE bor.* 

	OPEN WINDOW w0_inquiry with FORM "M162" 
	CALL  windecoration_m("M162") -- albo kd-762 

	WHILE true 
		LET msgresp = kandoomsg("M",1505,"") 
		# MESSAGE "ESC TO Accept, DEL TO Exit"

		LET fv_type = "P" 
		LET fv_select_text = "" 
		DISPLAY fv_type TO type 
		DISPLAY fv_select_text TO select_text 

		INPUT fv_type, fv_select_text WITHOUT DEFAULTS 
		FROM type, select_text 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD type 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

			AFTER FIELD select_text 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

				IF fv_type = "P" THEN 
					SELECT unique count(*) 
					INTO fv_cnter 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fv_select_text 

					IF fv_cnter = 0 THEN 
						LET msgresp = kandoomsg("M",9511,"") 
						# ERROR "Product does NOT exist in the database"
						NEXT FIELD select_text 
					END IF 
				ELSE 
					SELECT unique count(*) 
					INTO fv_cnter 
					FROM workcentre 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = fv_select_text 

					IF fv_cnter = 0 THEN 
						LET msgresp = kandoomsg("M",9527,"") 
						# ERROR "This workcentre does NOT exist in the database"
						NEXT FIELD select_text 
					END IF 
				END IF 

			ON KEY (control-b) 
				IF fv_type = "P" THEN 
					LET fv_select_text = show_mfgprods(glob_rec_kandoouser.cmpy_code,"") 
				ELSE 
					LET fv_select_text = show_centres(glob_rec_kandoouser.cmpy_code) 
				END IF 
				DISPLAY fv_select_text TO select_text 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLEAR FORM 
			EXIT WHILE 
		ELSE 
			IF fv_type = "P" THEN 
				LET fv_select = " AND part_code = \"", fv_select_text, "\"" 
			ELSE 
				LET fv_select = " AND work_centre_code = \"", fv_select_text, 
				"\"" 
			END IF 

			LET fv_select = "SELECT * FROM bor WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code, 
			"\"", fv_select 

			PREPARE sel_text FROM fv_select 
			DECLARE c_sel_bor CURSOR FOR sel_text 

			LET fv_idx = 1 
			{
			            OPEN WINDOW w1_IB1 AT 10,10 with 2 rows, 50 columns      -- albo  KD-762
			               attribute (border)
			}
			LET msgresp = kandoomsg("U",1506,"") 
			# MESSAGE "Searching database - Please stand by"
			LET msgresp = kandoomsg("I",1024,"") 
			# MESSAGE "Report on product"

			FOREACH c_sel_bor INTO fr_bor.* 
				DISPLAY fr_bor.part_code at 1,27 


				LET fa_bor_parents[fv_idx].fv_type = fr_bor.type_ind 
				LET fa_bor_parents[fv_idx].fv_parent = fr_bor.parent_part_code 

				SELECT desc_text 
				INTO fa_bor_parents[fv_idx].fv_description 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.parent_part_code 

				IF fv_type = "P" THEN 
					LET fa_bor_parents[fv_idx].fv_quantity = fr_bor.required_qty 
				ELSE 
					LET fa_bor_parents[fv_idx].fv_quantity = "" 
				END IF 
				LET fv_idx = fv_idx + 1 
			END FOREACH 

			LET msgresp = kandoomsg("U",1507,"") 
			# MESSAGE "database search IS complete"

			--            CLOSE WINDOW w1_IB1      -- albo  KD-762

			LET msgresp = kandoomsg("M",1509,"") 
			# MESSAGE "F3 fwd F4 Bwd Del TO EXIT"

			IF fv_idx = 1 THEN 
				INITIALIZE fa_bor_parents[fv_idx].* TO NULL 

				IF fv_type = "P" THEN 
					LET msgresp = kandoomsg("M",9521,"") 
					# ERROR "There are no BOR's with this parent as a child"
				ELSE 
					LET msgresp = kandoomsg("M",9528,"") 
					# ERROR "no BOR's found with that workcentre"
				END IF 
			ELSE 
				CALL set_count(fv_idx -1) 

				DISPLAY ARRAY fa_bor_parents TO sr_bor.* 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","M25","display-arr-bor_parents") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END DISPLAY 
				LET fv_idx = 1 
				INITIALIZE fa_bor_parents[fv_idx].* TO NULL 

				FOR fv_cnt = 1 TO 10 
					DISPLAY fa_bor_parents[fv_idx].* TO sr_bor[fv_cnt].* 
				END FOR 

				LET int_flag = false 
				LET quit_flag = false 
			END IF 
		END IF 
	END WHILE 

END FUNCTION 
