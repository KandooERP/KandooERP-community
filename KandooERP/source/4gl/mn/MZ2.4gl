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

	Source code beautified by beautify.pl on 2020-01-02 17:31:36	$Id: $
}


# Purpose - Work Centre Inquiry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 
	DEFINE formname CHAR(15) 
END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("MZ2") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL query_centre() 

END MAIN 



FUNCTION query_centre() 

	DEFINE fv_where_part CHAR(500), 
	fv_query_text CHAR(500), 
	fv_cnt SMALLINT, 
	fv_idx SMALLINT, 

	fa_centre array[500] OF RECORD 
		work_centre_code LIKE workcentre.work_centre_code, 
		desc_text LIKE workcentre.desc_text, 
		processing_ind LIKE workcentre.processing_ind, 
		time_qty LIKE workcentre.time_qty, 
		time_unit_ind LIKE workcentre.time_unit_ind, 
		unit_uom_code LIKE workcentre.unit_uom_code 
	END RECORD 

	OPEN WINDOW w1_m119 with FORM "M119" 
	CALL  windecoration_m("M119") -- albo kd-762 

	WHILE true 
		CLEAR FORM 
		DISPLAY "Inquiry" TO heading_text 

		LET msgresp = kandoomsg("M", 1500, "") 	# MESSAGE " Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_part 
		ON work_centre_code, desc_text, processing_ind, time_qty, 
		time_unit_ind, unit_uom_code 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET fv_query_text = "SELECT work_centre_code, desc_text, ", 
		"processing_ind, time_qty, time_unit_ind, ", 
		"unit_uom_code ", 
		"FROM workcentre ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", fv_where_part clipped, " ", 
		"ORDER BY work_centre_code" 

		PREPARE sl_stmt1 FROM fv_query_text 
		DECLARE c_centre CURSOR FOR sl_stmt1 

		LET fv_cnt = 1 

		FOREACH c_centre INTO fa_centre[fv_cnt].* 
			LET fv_cnt = fv_cnt + 1 

			IF fv_cnt > 500 THEN 
				LET msgresp = kandoomsg("M", 9697, "") 
				# ERROR "Only the first 500 Work Centres have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF fv_cnt = 1 THEN 
			LET msgresp = kandoomsg("M", 9610, "") 
			# ERROR "The query returned no rows"
			CONTINUE WHILE 
		END IF 

		CALL set_count(fv_cnt - 1) 

		LET msgresp = kandoomsg("M", 1531, "") 
		# MESSAGE "RETURN on line TO View, F3 Fwd, F4 Bwd - DEL Exit"

		DISPLAY ARRAY fa_centre TO sr_centre.* 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","MZ2","display-arr-centre") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (RETURN) 
				LET fv_idx = arr_curr() 
				CALL display_centre(fa_centre[fv_idx].work_centre_code) 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
	END WHILE 

	CLOSE WINDOW w1_m119 

END FUNCTION 



FUNCTION display_centre(fv_wc_code) 

	DEFINE fv_wc_code LIKE workcentre.work_centre_code, 
	fv_desc_text LIKE mfgdept.desc_text, 
	fv_cnt SMALLINT, 
	fr_workcentre RECORD LIKE workcentre.*, 
	fr_workctrrate RECORD LIKE workctrrate.*, 

	fa_workctrrate array[500] OF RECORD 
		desc_text LIKE workctrrate.desc_text, 
		rate_amt LIKE workctrrate.rate_amt, 
		rate_ind LIKE workctrrate.rate_ind, 
		type_desc CHAR(8) 
	END RECORD 

	OPEN WINDOW w2_m115 with FORM "M115" 
	CALL  windecoration_m("M115") -- albo kd-762 

	SELECT * 
	INTO fr_workcentre.* 
	FROM workcentre 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fv_wc_code 

	DISPLAY BY NAME fr_workcentre.work_centre_code, 
	fr_workcentre.desc_text, 
	fr_workcentre.dept_code, 
	fr_workcentre.alternate_wc_code, 
	fr_workcentre.processing_ind, 
	fr_workcentre.time_unit_ind, 
	fr_workcentre.time_qty, 
	fr_workcentre.unit_uom_code, 
	fr_workcentre.work_station_num, 
	fr_workcentre.utilization_rate, 
	fr_workcentre.efficiency_rate, 
	fr_workcentre.oper_start_time, 
	fr_workcentre.oper_end_time, 
	fr_workcentre.cost_markup_per, 
	fr_workcentre.count_centre_ind 


	SELECT desc_text 
	INTO fv_desc_text 
	FROM mfgdept 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND dept_code = fr_workcentre.dept_code 

	DISPLAY fv_desc_text TO dept_desc 


	IF fr_workcentre.alternate_wc_code IS NOT NULL THEN 
		SELECT desc_text 
		INTO fv_desc_text 
		FROM workcentre 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND work_centre_code = fr_workcentre.alternate_wc_code 

		DISPLAY fv_desc_text TO alternate_desc 

	END IF 

	DECLARE c_wcrate CURSOR FOR 
	SELECT * 
	FROM workctrrate 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fv_wc_code 
	ORDER BY sequence_num 

	LET fv_cnt = 0 

	FOREACH c_wcrate INTO fr_workctrrate.* 
		LET fv_cnt = fv_cnt + 1 

		LET fa_workctrrate[fv_cnt].desc_text = fr_workctrrate.desc_text 
		LET fa_workctrrate[fv_cnt].rate_amt = fr_workctrrate.rate_amt 
		LET fa_workctrrate[fv_cnt].rate_ind = fr_workctrrate.rate_ind 

		IF fr_workctrrate.rate_ind = "F" THEN 
			LET fa_workctrrate[fv_cnt].type_desc = "Fixed" 
		ELSE 
			LET fa_workctrrate[fv_cnt].type_desc = "Variable" 
		END IF 

		IF fv_cnt = 500 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET msgresp = kandoomsg("M", 1509, "") 
	# MESSAGE "F3 Fwd, F4 Bwd - DEL TO Exit"

	CALL set_count(fv_cnt) 
	DISPLAY ARRAY fa_workctrrate TO sr_rate.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","MZ2","display-arr-orkctrrate") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW w2_m115 

END FUNCTION 
