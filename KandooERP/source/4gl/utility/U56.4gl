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



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module U56 - Loads quadrant table
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 
	DEFINE pr_quadrant RECORD LIKE quadrant.* 
	DEFINE runner CHAR(60) 
	DEFINE pr_filename CHAR(60) 
	DEFINE directory CHAR(60) 
	DEFINE loadfile CHAR(60) 

END GLOBALS 


###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("U56") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	CREATE temp TABLE t_flatfile(line CHAR(150)) with no LOG 
	CREATE temp TABLE t_quaderr(line_num SMALLINT, error_text CHAR(100)) 

	OPEN WINDOW u210 with FORM "U210" 
	CALL windecoration_u("U210") 

	MENU " Quadrant Load" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","U56","menu-quarant_load") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Load" " SELECT details TO load" 
			IF load_file() THEN 
				CALL validate_file() 
				NEXT option "Print Manager" 
			ELSE 
				NEXT option "Exit" 
			END IF 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND "Maintenance" " Modify the quadrant amounts" 
			CALL maintain_quadrant() 
			NEXT option "Exit" 
		COMMAND "Directory" " List entries in specified directory" 
			DISPLAY "" at 2,1 
			--         prompt "Enter UNIX Pathname: " FOR directory  -- albo
			LET directory = promptInput("Enter UNIX Pathname: ","",60) -- albo 
			IF int_flag OR quit_flag 
			OR directory IS NULL THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET directory = NULL 
			ELSE 
				LET runner = "ls -f ",directory clipped,"|pg" 
				RUN runner 
			END IF 
			NEXT option "Load" 
		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW u210 
END MAIN 


FUNCTION load_file() 
	DEFINE winds_text CHAR(40) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET l_msgresp=kandoomsg("W",1147,"") 
	#1087 Enter Quadrant Upload Details - ESC TO Continue"
	LET pr_filename = directory 
	INPUT BY NAME pr_quadrant.ware_code, 
	pr_filename WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U56","input-upload") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (ware_code) 
					LET winds_text = show_ware(glob_rec_kandoouser.cmpy_code) 
					IF winds_text IS NOT NULL THEN 
						LET pr_quadrant.ware_code = winds_text 
					END IF 
					NEXT FIELD ware_code 

		AFTER FIELD ware_code 
			SELECT * FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_quadrant.ware_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("W",9910,"") 
				#Warehouse does NOT exist
				NEXT FIELD ware_code 
			END IF 
		AFTER FIELD pr_filename 
			IF pr_filename IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9144,"") 
				#9144 " Interface file does NOT exist - Check path AND file name"
				NEXT FIELD pr_filename 
			END IF 
		AFTER INPUT 
			DISPLAY " " at 10,4 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			WHENEVER ERROR CONTINUE 
			DELETE FROM t_flatfile 
			LOAD FROM pr_filename INSERT INTO t_flatfile 
			IF status != 0 THEN 
				IF status = -846 THEN 
					ERROR " Incorrect file FORMAT OR blank lines detected" 
				ELSE 
					DISPLAY "Status ", status at 10,4 
					LET l_msgresp=kandoomsg("G",9144,"") 
					#9144 "Interface file does NOT exist - Check path AND file name"
				END IF 
				NEXT FIELD pr_filename 
			END IF 
			SELECT unique 1 FROM t_flatfile 
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


FUNCTION validate_file() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_quaderr RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD, 
	pr_zone CHAR(1), 
	pr_line CHAR(150), 
	glob_rpt_output CHAR(50), 
	idx,blank_lines SMALLINT, 
	query_text CHAR(100) 

	LET idx=0 
	INITIALIZE pr_quaderr.* TO NULL 
	LET query_text = "SELECT * FROM t_flatfile" 
	PREPARE s_flatfile FROM query_text 
	DECLARE c_flatfile CURSOR FOR s_flatfile 
	FOREACH c_flatfile INTO pr_line 
		LET idx=idx+1 
		IF pr_line[1,3] = " " THEN 
			LET pr_quaderr.error_text = "Invalid map number " 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		IF pr_line[1] != " " 
		AND (pr_line[2] = " " OR pr_line[3] = " ") THEN 
			LET pr_quaderr.error_text = "Invalid map number " 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		IF pr_line[2] != " " 
		AND pr_line[3] = " " THEN 
			LET pr_quaderr.error_text = "Invalid map number " 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		IF not(check_map_num(pr_line[1,3])) THEN 
			LET pr_quaderr.error_text = "Invalid map number " 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		IF not(check_num(pr_line[5,7])) THEN 
			LET pr_quaderr.error_text = "Quadrant A contains an invalid value" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_quadrant.quada_qty = pr_line[5,7] 
		IF pr_quadrant.quada_qty < 0 THEN 
			LET pr_quadrant.quada_qty = 0 
		END IF 
		IF not(check_num(pr_line[8,10])) THEN 
			LET pr_quaderr.error_text = "Quadrant B contains an invalid value" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_quadrant.quadb_qty = pr_line[8,10] 
		IF pr_quadrant.quadb_qty < 0 THEN 
			LET pr_quadrant.quadb_qty = 0 
		END IF 
		IF not(check_num(pr_line[11,13])) THEN 
			LET pr_quaderr.error_text = "Quadrant C contains an invalid value" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_quadrant.quadc_qty = pr_line[11,13] 
		IF pr_quadrant.quadc_qty < 0 THEN 
			LET pr_quadrant.quadc_qty = 0 
		END IF 
		IF not(check_num(pr_line[14,16])) THEN 
			LET pr_quaderr.error_text = "Quadrant D contains an invalid value" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_quadrant.quadd_qty = pr_line[14,16] 
		IF pr_quadrant.quadd_qty < 0 THEN 
			LET pr_quadrant.quadd_qty = 0 
		END IF 
		LET pr_quadrant.map_num = pr_line[1,4] 
		IF pr_quadrant.map_num[2] = " " THEN 
			LET pr_quadrant.map_num[1] = pr_quadrant.map_num[3] 
			LET pr_quadrant.map_num[2] = pr_quadrant.map_num[4] 
			LET pr_quadrant.map_num[3] = " " 
			LET pr_quadrant.map_num[4] = " " 
		ELSE 
			IF pr_quadrant.map_num[1] = " " THEN 
				LET pr_quadrant.map_num[1] = pr_quadrant.map_num[2] 
				LET pr_quadrant.map_num[2] = pr_quadrant.map_num[3] 
				LET pr_quadrant.map_num[3] = pr_quadrant.map_num[4] 
				LET pr_quadrant.map_num[4] = " " 
			END IF 
		END IF 
		LET pr_quadrant.cmpy_code = glob_rec_kandoouser.cmpy_code 
		SELECT * FROM quadrant 
		WHERE map_num = pr_quadrant.map_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_quadrant.ware_code 
		IF status = notfound THEN 
			INSERT INTO quadrant VALUES (pr_quadrant.*) 
		ELSE 
			LET pr_quaderr.error_text = "This RECORD already exists" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
	END FOREACH 
	LET query_text = "SELECT * FROM t_quaderr" 
	PREPARE s_quaderr FROM query_text 
	DECLARE c_quaderr CURSOR FOR s_quaderr 



	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"U56_rpt_list_quaderrlist","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U56_rpt_list_quaderrlist TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	FOREACH c_quaderr INTO pr_quaderr.*
		#---------------------------------------------------------
		OUTPUT TO REPORT U56_rpt_list_quaderrlist(l_rpt_idx,pr_quaderr.*) 
		#---------------------------------------------------------
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT U56_rpt_list_quaderrlist
	CALL rpt_finish("U56_rpt_list_quaderrlist")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 	 
END FUNCTION 





FUNCTION check_map_num(pr_quad_qty) 
	DEFINE 
	pr_quad_qty CHAR(3), 
	idx SMALLINT 

	FOR idx = 1 TO 3 
		IF pr_quad_qty[idx] != " " THEN 
			IF NOT (pr_quad_qty[idx] matches "[0-9]") THEN 
				RETURN false 
			END IF 
		END IF 
	END FOR 
	RETURN true 
END FUNCTION 

FUNCTION check_num(pr_quad_qty) 
	DEFINE 
	pr_quad_qty CHAR(3), 
	pr_full_stop CHAR(1), 
	idx SMALLINT 

	LET pr_full_stop = "N" 
	IF pr_quad_qty matches " " THEN 
		RETURN false 
	END IF 
	FOR idx = 1 TO 3 
		IF pr_quad_qty[idx] = "." THEN 
			IF pr_full_stop = "Y" THEN 
				RETURN false 
			ELSE 
				IF idx = 3 THEN 
					RETURN false 
				ELSE 
					LET pr_full_stop = "Y" 
				END IF 
			END IF 
		ELSE 
			IF pr_quad_qty[idx] = "-" THEN 
				IF idx = 3 THEN 
					RETURN false 
				ELSE 
					IF pr_quad_qty[idx+1] = "1" THEN 
						IF idx = 2 THEN 
							RETURN true 
						ELSE 
							IF pr_quad_qty[idx+2] != " " THEN 
								RETURN false 
							ELSE 
								RETURN true 
							END IF 
						END IF 
					ELSE 
						RETURN false 
					END IF 
				END IF 
			ELSE 
				IF pr_quad_qty[1] != " " 
				AND (pr_quad_qty[2] = " " OR pr_quad_qty[3] = " ") THEN 
					RETURN false 
				END IF 
				IF pr_quad_qty[2] != " " 
				AND pr_quad_qty[3] = " " THEN 
					RETURN false 
				END IF 
				IF pr_quad_qty[idx] = " " THEN 
					CONTINUE FOR 
				ELSE 
					IF pr_quad_qty[idx] matches "[0-9]" THEN 
						CONTINUE FOR 
					ELSE 
						RETURN false 
					END IF 
				END IF 
			END IF 
		END IF 
	END FOR 
	RETURN true 
END FUNCTION 


FUNCTION maintain_quadrant() 
	DEFINE 
	pr_quadrant RECORD LIKE quadrant.*, 
	pa_quadrant array[200] OF RECORD 
		scroll_flag CHAR(1), 
		ware_code LIKE quadrant.ware_code, 
		map_num LIKE quadrant.map_num, 
		quada_qty LIKE quadrant.quada_qty, 
		quadb_qty LIKE quadrant.quadb_qty, 
		quadc_qty LIKE quadrant.quadc_qty, 
		quadd_qty LIKE quadrant.quadd_qty 
	END RECORD, 
	idx,scrn SMALLINT, 
	query_text CHAR(800), 
	where_text CHAR(400) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW u211 with FORM "U211" 
	CALL windecoration_u("U211") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME where_text ON ware_code, 
		map_num, 
		quada_qty, 
		quadb_qty, 
		quadc_qty, 
		quadd_qty 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","U56","construct-quadrant") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT * FROM quadrant ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",where_text clipped," ", 
		"ORDER BY ware_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_quadrant FROM query_text 
		DECLARE c_quadrant CURSOR FOR s_quadrant 
		LET idx = 0 
		FOREACH c_quadrant INTO pr_quadrant.* 
			LET idx = idx + 1 
			LET pa_quadrant[idx].ware_code = pr_quadrant.ware_code 
			LET pa_quadrant[idx].map_num = pr_quadrant.map_num 
			LET pa_quadrant[idx].quada_qty = pr_quadrant.quada_qty 
			LET pa_quadrant[idx].quadb_qty = pr_quadrant.quadb_qty 
			LET pa_quadrant[idx].quadc_qty = pr_quadrant.quadc_qty 
			LET pa_quadrant[idx].quadd_qty = pr_quadrant.quadd_qty 
			IF idx = 200 THEN 
				LET l_msgresp = kandoomsg("U",6100,idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,idx) 
		#U9113 idx records selected
		IF idx = 0 THEN 
			LET idx = 1 
			INITIALIZE pa_quadrant[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		OPTIONS SQL interrupt off 

		LET l_msgresp = kandoomsg("W",1149,"") 
		#1006 "RETURN on line TO edit - ESC TO Continue
		CALL set_count(idx) 
		INPUT ARRAY pa_quadrant WITHOUT DEFAULTS FROM sr_quadrant.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","U56","input-arr-quadrant") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_quadrant[idx].ware_code IS NOT NULL THEN 
					DISPLAY pa_quadrant[idx].* TO sr_quadrant[scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			BEFORE FIELD scroll_flag 
				IF pa_quadrant[idx].ware_code IS NOT NULL THEN 
					DISPLAY pa_quadrant[idx].* TO sr_quadrant[scrn].* 

				END IF 
			AFTER FIELD scroll_flag 
				LET pr_quadrant.quada_qty = pa_quadrant[idx].quada_qty 
				LET pr_quadrant.quadb_qty = pa_quadrant[idx].quadb_qty 
				LET pr_quadrant.quadc_qty = pa_quadrant[idx].quadc_qty 
				LET pr_quadrant.quadd_qty = pa_quadrant[idx].quadd_qty 
				LET pa_quadrant[idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("A",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			AFTER FIELD quada_qty 
				IF pa_quadrant[idx].quada_qty IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9010,"") 
					#9010 value must exist
					NEXT FIELD quada_qty 
				END IF 
				IF pa_quadrant[idx].quada_qty < 0 THEN 
					LET l_msgresp = kandoomsg("W",9907,"") 
					#9010 value must NOT be less than 0
					NEXT FIELD quada_qty 
				END IF 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD NEXT 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					NEXT FIELD scroll_flag 
				END IF 
			AFTER FIELD quadb_qty 
				IF pa_quadrant[idx].quadb_qty IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9010,"") 
					#9010 value must exist
					NEXT FIELD quadb_qty 
				END IF 
				IF pa_quadrant[idx].quadb_qty < 0 THEN 
					LET l_msgresp = kandoomsg("W",9907,"") 
					#9010 value must NOT be less than 0
					NEXT FIELD quadb_qty 
				END IF 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD NEXT 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					NEXT FIELD previous 
				END IF 
			AFTER FIELD quadc_qty 
				IF pa_quadrant[idx].quadc_qty IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9010,"") 
					#9010 value must exist
					NEXT FIELD quadc_qty 
				END IF 
				IF pa_quadrant[idx].quadc_qty < 0 THEN 
					LET l_msgresp = kandoomsg("W",9907,"") 
					#9010 value must NOT be less than 0
					NEXT FIELD quadc_qty 
				END IF 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD NEXT 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					NEXT FIELD previous 
				END IF 
			AFTER FIELD quadd_qty 
				IF pa_quadrant[idx].quadd_qty IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9010,"") 
					#9010 value must exist
					NEXT FIELD quadd_qty 
				END IF 
				IF pa_quadrant[idx].quadd_qty < 0 THEN 
					LET l_msgresp = kandoomsg("W",9907,"") 
					#9010 value must NOT be less than 0
					NEXT FIELD quadd_qty 
				END IF 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("right") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("accept") THEN 
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					NEXT FIELD previous 
				END IF 
			AFTER ROW 
				DISPLAY pa_quadrant[idx].* TO sr_quadrant[scrn].* 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF not(infield (scroll_flag)) THEN 
						LET pa_quadrant[idx].quada_qty = pr_quadrant.quada_qty 
						LET pa_quadrant[idx].quadb_qty = pr_quadrant.quadb_qty 
						LET pa_quadrant[idx].quadc_qty = pr_quadrant.quadc_qty 
						LET pa_quadrant[idx].quadd_qty = pr_quadrant.quadd_qty 
						NEXT FIELD scroll_flag 
						LET int_flag = false 
						LET quit_flag = false 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			FOR idx = 1 TO arr_count() 
				LET pr_quadrant.quada_qty = pa_quadrant[idx].quada_qty 
				LET pr_quadrant.quadb_qty = pa_quadrant[idx].quadb_qty 
				LET pr_quadrant.quadc_qty = pa_quadrant[idx].quadc_qty 
				LET pr_quadrant.quadd_qty = pa_quadrant[idx].quadd_qty 
				UPDATE quadrant 
				SET quadrant.quada_qty = pr_quadrant.quada_qty, 
				quadrant.quadb_qty = pr_quadrant.quadb_qty, 
				quadrant.quadc_qty = pr_quadrant.quadc_qty, 
				quadrant.quadd_qty = pr_quadrant.quadd_qty 
				WHERE map_num = pa_quadrant[idx].map_num 
				AND ware_code = pa_quadrant[idx].ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			END FOR 
		END IF 
	END WHILE 
	CLOSE WINDOW u211 
END FUNCTION


REPORT U56_rpt_list_quaderrlist(p_rpt_idx,pr_quaderr) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pa_line array[4] OF CHAR(132), 
	pr_quaderr RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD 
	OUTPUT 
	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		ON EVERY ROW 
			PRINT COLUMN 04, pr_quaderr.line_num USING "###&", 
			COLUMN 18, pr_quaderr.error_text 
		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 
