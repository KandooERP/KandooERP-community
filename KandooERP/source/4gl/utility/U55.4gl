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

	Source code beautified by beautify.pl on 2020-01-03 18:54:45	$Id: $
}



# U55.4gl - Street Load
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 
	DEFINE pr_street RECORD LIKE street.* 
	DEFINE pr_suburb RECORD LIKE suburb.* 
	DEFINE pr_import_no SMALLINT 
	DEFINE pr_state_code CHAR(10) 
	DEFINE pr_source_ind CHAR(1) 
	DEFINE pr_outfile CHAR(50) 
	DEFINE pr_filename CHAR(50) 
	DEFINE pr_filename2 CHAR(50) 
	DEFINE runner CHAR(80) 
	DEFINE a_string CHAR(100) 
END GLOBALS 


###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CALL setModuleId("U55") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	#
	#Import indicator "1"
	CREATE temp TABLE t1_streets(street_text CHAR(50), 
	st_type_text CHAR(4), 
	suburb_text CHAR(50), 
	map_number CHAR(4), 
	ref_text CHAR(4), 
	post_code CHAR(10)) with no LOG 
	#Import indicator "2"
	CREATE temp TABLE t2_streets(street_text CHAR(50), 
	st_type_text CHAR(3), 
	filler1 CHAR(3), 
	suburb_text CHAR(50), 
	filler2 CHAR(20), 
	map_number1 CHAR(2), 
	map_number2 CHAR(2), 
	ref_text CHAR(4), 
	rec_type CHAR(1)) with no LOG 
	#Import indicator "3"
	CREATE temp TABLE t3_streets(street_line CHAR(136)) with no LOG 
	# Field                Start    Length
	# -------------------------------------------------------------
	# Street Name           1        50
	# Street Designation    51        6
	# Street Location       57        1  N S E OR W
	# Suburb                58       40
	# Map Number            98        4
	# Map Reference         102       4
	# Comments              106      30  eg off George Street
	# Add/Delete flag       136       1
	#
	#Import indicator "4"
	CREATE temp TABLE t_suburbs(suburb_text CHAR(50), 
	post_code CHAR(10), 
	map_number CHAR(4), 
	ref_text1 CHAR(2), 
	ref_text2 CHAR(2)) with no LOG 

	OPEN WINDOW u117 with FORM "U117" 
	CALL windecoration_u("U117") 

	MENU " Street/Suburb" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","U55","menu-street_suburb") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Choose" " Choose File" 
			LET a_string = get_winfile("","","A Window","") 
			DISPLAY a_string TO pr_filename 
			
		COMMAND "Load" " Load Streets AND Suburbs" 
			IF load_file() THEN 
				CASE pr_import_no 
					WHEN "1" 
						CALL load_vic_streets() 
					WHEN "2" 
						CALL load_oth_streets() 
					WHEN "3" 
						CALL load_special_streets() 
					WHEN "4" 
						CALL update_suburbs() 
				END CASE 
				NEXT option "Print Manager" 
			ELSE 
				NEXT option "Exit" 
			END IF 

		ON ACTION "Print Manager" 			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
			EXIT MENU 
	END MENU 
	CLOSE WINDOW u117 
END MAIN 


FUNCTION load_file()
	DEFINE l_msgresp LIKE language.yes_flag
	 
	CLEAR FORM 
	LET pr_import_no = NULL 
	LET l_msgresp=kandoomsg("U",1020,"External Load") 
	#1020 Enter Details - OK TO Continue
	INPUT BY NAME pr_import_no, 
	pr_state_code, 
	pr_source_ind, 
	pr_filename WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U55","input-load") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF pr_filename IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9144,"") 
				#9144 " Interface file does NOT exist - Check path AND file name"
				NEXT FIELD pr_filename 
			END IF 
			WHENEVER ERROR CONTINUE 
			CASE pr_import_no 
				WHEN "1" 
					DELETE FROM t1_streets 
					LOAD FROM pr_filename INSERT INTO t1_streets 
				WHEN "2" 
					DELETE FROM t2_streets 
					LET pr_filename2 = pr_filename clipped,".2" 
					LET runner = "../bin/CSV_to_UNL.sh ",pr_filename clipped, 
					" ",pr_filename2 clipped 
					CALL run_prog("runner",pr_filename clipped, 
					pr_filename2 clipped,"","") 
					LOAD FROM pr_filename2 INSERT INTO t2_streets 
				WHEN "3" 
					DELETE FROM t3_streets 
					LOAD FROM pr_filename INSERT INTO t3_streets 
				WHEN "4" 
					DELETE FROM t_suburbs 
					LET pr_filename2 = pr_filename clipped,".4" 
					LET runner = "../bin/CSV_to_UNL.sh ",pr_filename clipped, 
					" ",pr_filename2 clipped 
					RUN runner 
					LOAD FROM pr_filename2 INSERT INTO t_suburbs 
			END CASE 
			IF status != 0 THEN 
				IF status = -846 THEN 
					ERROR " Incorrect file FORMAT OR blank lines detected" 
				ELSE 
					LET l_msgresp=kandoomsg("G",9144,"") 
					#9144 "Interface file does NOT exist - Check path AND file name"
				END IF 
				NEXT FIELD pr_filename 
			END IF 
			CASE pr_import_no 
				WHEN "1" 
					SELECT unique 1 FROM t1_streets 
				WHEN "2" 
					SELECT unique 1 FROM t2_streets 
				WHEN "3" 
					SELECT unique 1 FROM t3_streets 
				WHEN "4" 
					SELECT unique 1 FROM t_suburbs 
			END CASE 
			IF status = notfound THEN 
				LET l_msgresp=kandoomsg("G",9146,"") 
				#9146 "Interface file IS empty - Check PC Transfer was successfull"
				NEXT FIELD pr_filename 
			END IF 
			WHENEVER ERROR stop 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION load_vic_streets() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE glob_rpt_output RECORD 
		street_text CHAR(50), 
		st_type_text CHAR(4), 
		suburb_text CHAR(50), 
		map_number CHAR(4), 
		ref_text CHAR(4), 
		post_code CHAR(10) 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"U55_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U55_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	DISPLAY "Street - " TO lblabel1 
	DECLARE c_t1_streets CURSOR FOR 
	SELECT * FROM t1_streets 
	ORDER BY suburb_text, street_text, st_type_text 
	FOREACH c_t1_streets INTO glob_rpt_output.* 
		DISPLAY glob_rpt_output.street_text TO lblabel1b 

		INITIALIZE pr_street.* TO NULL 
		LET pr_street.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_street.street_text = fix_text(glob_rpt_output.street_text) 
		LET pr_street.st_type_text = upshift(glob_rpt_output.st_type_text) 
		LET pr_street.map_number = upshift(glob_rpt_output.map_number) 
		LET pr_street.ref_text = upshift(glob_rpt_output.ref_text) 
		LET pr_street.source_ind = pr_source_ind 
		LET pr_suburb.suburb_text = fix_text(glob_rpt_output.suburb_text) 
		LET pr_suburb.post_code = glob_rpt_output.post_code 
		IF NOT valid_entry() THEN 
			CONTINUE FOREACH 
		END IF 
		SELECT suburb_code INTO pr_street.suburb_code FROM suburb 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_text = pr_suburb.suburb_text 
		AND post_code = glob_rpt_output.post_code 
		IF status = notfound THEN 
			INITIALIZE pr_suburb.* TO NULL 
			LET pr_suburb.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_suburb.suburb_text = fix_text(glob_rpt_output.suburb_text) 
			LET pr_suburb.state_code = pr_state_code 
			LET pr_suburb.post_code = glob_rpt_output.post_code 
			LET pr_suburb.suburb_code = 0 
			INSERT INTO suburb VALUES (pr_suburb.*) 
			LET pr_suburb.suburb_code = sqlca.sqlerrd[2] 
			LET pr_street.suburb_code = pr_suburb.suburb_code 
			#---------------------------------------------------------
			OUTPUT TO REPORT U55_rpt_list(l_rpt_idx,glob_rec_kandoouser.cmpy_code, pr_suburb.*) 
			#--------------------------------------------------------- 

		END IF 
		WHENEVER ERROR CONTINUE 
		INSERT INTO street VALUES (pr_street.*) 
		WHENEVER ERROR stop 
	END FOREACH 
	WHENEVER ERROR stop 

	#------------------------------------------------------------
	FINISH REPORT U55_rpt_list
	CALL rpt_finish("U55_rpt_list")
	#------------------------------------------------------------ 

END FUNCTION 


FUNCTION load_oth_streets() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	glob_rpt_output RECORD 
		street_text CHAR(50), 
		st_type_text CHAR(3), 
		filler1 CHAR(3), 
		suburb_text CHAR(50), 
		filler2 CHAR(20), 
		map_number1 CHAR(2), 
		map_number2 CHAR(2), 
		ref_text CHAR(4), 
		rec_type CHAR(1) 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"U55_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U55_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE c_t2_streets CURSOR FOR 
	SELECT * FROM t2_streets 
	ORDER BY street_text, st_type_text 
	FOREACH c_t2_streets INTO glob_rpt_output.* 
		DISPLAY glob_rpt_output.street_text TO lblabel1b 

		INITIALIZE pr_street.* TO NULL 
		LET pr_street.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_street.street_text = fix_text(glob_rpt_output.street_text) 
		LET pr_street.st_type_text = upshift(glob_rpt_output.st_type_text) 
		LET pr_street.map_number = upshift(glob_rpt_output.ref_text) 
		LET pr_street.ref_text = upshift(glob_rpt_output.map_number1) clipped, 
		" ", 
		upshift(glob_rpt_output.map_number2) clipped 
		LET pr_street.source_ind = pr_source_ind 
		LET pr_suburb.suburb_text = fix_text(glob_rpt_output.suburb_text) 
		IF pr_suburb.suburb_text[1,4] = "SEE " THEN 
			CONTINUE FOREACH 
		END IF 
		DECLARE c_suburb CURSOR FOR 
		SELECT suburb_code FROM suburb 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_text = pr_suburb.suburb_text 
		AND state_code = pr_state_code 
		OPEN c_suburb 
		FETCH c_suburb INTO pr_street.suburb_code 
		IF status = notfound THEN 
			INITIALIZE pr_suburb.* TO NULL 
			LET pr_suburb.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_suburb.suburb_text = fix_text(glob_rpt_output.suburb_text) 
			LET pr_suburb.state_code = pr_state_code 
			LET pr_suburb.suburb_code = 0 
			INSERT INTO suburb VALUES (pr_suburb.*) 
			LET pr_suburb.suburb_code = sqlca.sqlerrd[2] 
			LET pr_street.suburb_code = pr_suburb.suburb_code 
			#---------------------------------------------------------
			OUTPUT TO REPORT U55_rpt_list(l_rpt_idx,glob_rec_kandoouser.cmpy_code, pr_suburb.*) 
			#--------------------------------------------------------- 

		END IF 
		WHENEVER ERROR CONTINUE 
		INSERT INTO street VALUES (pr_street.*) 
		WHENEVER ERROR stop 
	END FOREACH 
	WHENEVER ERROR stop 
	#------------------------------------------------------------
	FINISH REPORT U55_rpt_list
	CALL rpt_finish("U55_rpt_list")
	#------------------------------------------------------------ 
END FUNCTION 


FUNCTION load_special_streets() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE glob_rpt_output nchar(136)
	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"U55_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U55_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE c_t3_streets CURSOR FOR 
	SELECT * FROM t3_streets 
	FOREACH c_t3_streets INTO glob_rpt_output 
		INITIALIZE pr_street.* TO NULL 
		LET pr_street.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_street.street_text = fix_text(glob_rpt_output[1,50]) 
		DISPLAY pr_street.street_text TO lblabel1b 

		LET pr_street.st_type_text = upshift(glob_rpt_output[51,56]) 
		LET pr_street.map_number = upshift(glob_rpt_output[98,101]) 
		LET pr_street.ref_text = upshift(glob_rpt_output[102,105]) 
		LET pr_street.source_ind = pr_source_ind 
		LET pr_suburb.suburb_text = upshift(glob_rpt_output[58,97]) 
		LET pr_suburb.suburb_text = fix_text(pr_suburb.suburb_text) 
		IF NOT valid_entry() THEN 
			CONTINUE FOREACH 
		END IF 
		SELECT suburb_code INTO pr_street.suburb_code FROM suburb 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_text = pr_suburb.suburb_text 
		AND state_code = pr_state_code 
		
		IF status = notfound THEN 
			INITIALIZE pr_suburb.* TO NULL 
			LET pr_suburb.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_suburb.suburb_text = upshift(glob_rpt_output[58,97]) 
			LET pr_suburb.state_code = pr_state_code 
			LET pr_suburb.suburb_code = 0 
			INSERT INTO suburb VALUES (pr_suburb.*) 
			LET pr_suburb.suburb_code = sqlca.sqlerrd[2] 
			LET pr_street.suburb_code = pr_suburb.suburb_code
			#---------------------------------------------------------
			OUTPUT TO REPORT U55_rpt_list(l_rpt_idx,glob_rec_kandoouser.cmpy_code, pr_suburb.*) 
			#--------------------------------------------------------- 
 
		END IF 
		
		IF upshift(glob_rpt_output[136]) = "A" THEN 
			WHENEVER ERROR CONTINUE 
			INSERT INTO street VALUES (pr_street.*) 
			WHENEVER ERROR stop 
		END IF 
		
		IF upshift(glob_rpt_output[136]) = "D" THEN 
			WHENEVER ERROR CONTINUE 
			DELETE FROM street 
			WHERE cmpy_code = pr_street.cmpy_code 
			AND street_text = pr_street.street_text 
			AND st_type_text = pr_street.st_type_text 
			AND map_number = pr_street.map_number 
			AND ref_text = pr_street.ref_text 
			AND source_ind = pr_street.source_ind 
			AND suburb_code = pr_street.suburb_code 
			WHENEVER ERROR stop 
		END IF 
	END FOREACH 
	WHENEVER ERROR stop 

	#------------------------------------------------------------
	FINISH REPORT U55_rpt_list
	CALL rpt_finish("U55_rpt_list")
	#------------------------------------------------------------ 
 
END FUNCTION 


FUNCTION update_suburbs() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	glob_rpt_output RECORD 
		suburb_text CHAR(50), 
		post_code CHAR(10), 
		map_number CHAR(4), 
		ref_text1 CHAR(2), 
		ref_text2 CHAR(2) 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"U55_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U55_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE c_t_suburbs CURSOR FOR 
	SELECT * FROM t_suburbs 
	ORDER BY suburb_text, post_code 
	FOREACH c_t_suburbs INTO glob_rpt_output.* 
		LET glob_rpt_output.suburb_text = fix_text(glob_rpt_output.suburb_text) 
		DISPLAY glob_rpt_output.suburb_text TO lblabel1b 
		IF NOT valid_entry() THEN 
			CONTINUE FOREACH 
		END IF 
		SELECT * INTO pr_suburb.* FROM suburb 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_text = glob_rpt_output.suburb_text 
		AND state_code = pr_state_code 
		AND post_code = glob_rpt_output.post_code 
		IF status = notfound THEN 
			INITIALIZE pr_suburb.* TO NULL 
			LET pr_suburb.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_suburb.suburb_text = glob_rpt_output.suburb_text 
			LET pr_suburb.state_code = pr_state_code 
			LET pr_suburb.post_code = glob_rpt_output.post_code 
			LET pr_suburb.suburb_code = 0 
			INSERT INTO suburb VALUES (pr_suburb.*) 
			LET pr_suburb.suburb_code = sqlca.sqlerrd[2] 
			#---------------------------------------------------------
			OUTPUT TO REPORT U55_rpt_list(l_rpt_idx,glob_rec_kandoouser.cmpy_code, pr_suburb.*) 
			#--------------------------------------------------------- 

		ELSE 
			IF pr_suburb.post_code IS NULL 
			OR pr_suburb.post_code != glob_rpt_output.post_code THEN 
				UPDATE suburb 
				SET post_code = glob_rpt_output.post_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_code = pr_suburb.suburb_code 
			END IF 
		END IF 
	END FOREACH 
	WHENEVER ERROR stop 

	#------------------------------------------------------------
	FINISH REPORT U55_rpt_list
	CALL rpt_finish("U55_rpt_list")
	#------------------------------------------------------------ 
 
END FUNCTION 


FUNCTION fix_text(locality_text) 
	DEFINE 
	locality_text CHAR(50), #same size FOR street & suburb 
	x SMALLINT 

	LET x = length(locality_text) 
	LET locality_text = upshift(locality_text) 
	CASE 
		WHEN locality_text[1,4] = "STH " 
			LET locality_text = "SOUTH ", locality_text[5,50] 
		WHEN locality_text[1,4] = "NTH " 
			LET locality_text = "NORTH ", locality_text[5,50] 
		WHEN locality_text[1,4] = "ST. " 
			LET locality_text = "ST ", locality_text[5,50] 
		WHEN locality_text[1,4] = "MT. " 
			LET locality_text = "MOUNT ", locality_text[5,50] 
		WHEN locality_text[1,3] = "MT " 
			LET locality_text = "MOUNT ", locality_text[4,50] 
		WHEN locality_text[1,6] = "MALL, " 
			LET locality_text = locality_text[7,50] 
	END CASE 
	IF x > 3 THEN 
		CASE 
			WHEN locality_text[x-3,x] = " STH" 
				LET locality_text = locality_text[1,x-4], " SOUTH" 
			WHEN locality_text[x-3,x] = " NTH" 
				LET locality_text = locality_text[1,x-4], " NORTH" 
		END CASE 
	END IF 
	RETURN locality_text 
END FUNCTION 


FUNCTION valid_entry() 
	IF pr_suburb.suburb_text IS NULL 
	OR pr_suburb.post_code IS NULL 
	OR pr_street.street_text IS NULL 
	OR pr_street.map_number IS NULL 
	OR pr_street.ref_text IS NULL THEN 
		RETURN false 
	END IF 
	IF pr_suburb.suburb_text[1,4] = "SEE " 
	OR pr_suburb.post_code NOT matches "[0-9][0-9][0-9][0-9]" 
	OR pr_suburb.post_code matches "1*" THEN 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


REPORT U55_rpt_list(p_rpt_idx,p_cmpy, pr_suburb) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_suburb RECORD LIKE suburb.*, 
	pr_company RECORD LIKE company.*, 
	glob_rpt_line1, glob_rpt_line2 CHAR(80), 
	glob_rpt_offset1, glob_rpt_offset2 SMALLINT 

	OUTPUT 
--	left margin 0 
--	PAGE length 66 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Suburb", 
			COLUMN 52, "State", 
			COLUMN 59, "Post Code" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 01, pr_suburb.suburb_text, 
			COLUMN 52, pr_suburb.state_code, 
			COLUMN 59, pr_suburb.post_code 
		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 


