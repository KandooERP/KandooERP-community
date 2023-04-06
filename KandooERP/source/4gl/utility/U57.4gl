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

	Source code beautified by beautify.pl on 2020-01-03 18:54:46	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module U57 Loads supply table information
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 
	DEFINE pr_supply RECORD LIKE supply.* 
	DEFINE runner CHAR(60) 
	DEFINE pr_filename CHAR(60) 
	DEFINE pr_filename2 CHAR(60) 
	DEFINE directory CHAR(60) 

END GLOBALS 


###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFER interrupt 
	DEFER quit 
	CALL setModuleId("U57") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 
	
	CREATE temp TABLE t_supply(suburb_text CHAR(50), 
	post_code CHAR(6), 
	km_qty FLOAT, 
	source_post_code CHAR(6)) with no LOG 

	CREATE temp TABLE t_quaderr(line_num SMALLINT, 
	error_text CHAR(100)) 

	OPEN WINDOW U528 with FORM "U528" 
	CALL windecoration_u("U528") 

	MENU " Data Load" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","U57","menu-data_load") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Load" " SELECT details TO load" 
			IF load_file() THEN 
				CALL U57_rpt_process_validate_file() 
				NEXT option "Print Manager" 
			ELSE 
				NEXT option "Exit" 
			END IF 

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 


		COMMAND "Directory" " List entries in specified directory"	--         prompt "Enter UNIX Pathname: " FOR directory -- albo
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
 
	END MENU 
	CLOSE WINDOW u528 
END MAIN 


FUNCTION load_file() 
	DEFINE winds_text CHAR(40)
	DEFINE l_msgresp LIKE language.yes_flag

	LET l_msgresp=kandoomsg("U",1020,"Load") 
	#1020 Enter Load Details;  OK TO Continue"
	LET pr_filename = directory 
	INPUT BY NAME pr_supply.ware_code, 
	pr_filename WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U57","input-supply-load") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (ware_code) 
					LET winds_text = show_ware(glob_rec_kandoouser.cmpy_code) 
					IF winds_text IS NOT NULL THEN 
						LET pr_supply.ware_code = winds_text 
					END IF 
					NEXT FIELD ware_code 

		AFTER FIELD ware_code 
			SELECT * FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_supply.ware_code 
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
			DELETE FROM t_supply 
			LET pr_filename2 = pr_filename clipped,".tmp" 
			LET runner = "../bin/CSV_to_UNL.sh ",pr_filename clipped, 
			" ",pr_filename2 clipped 
			RUN runner 
			LOAD FROM pr_filename2 INSERT INTO t_supply 
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
			SELECT unique 1 FROM t_supply 
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


FUNCTION U57_rpt_process_validate_file() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_quaderr RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD, 
	pr_load RECORD 
		suburb_text CHAR(50), 
		post_code CHAR(6), 
		km_qty FLOAT, 
		source_post_code CHAR(6) 
	END RECORD, 
	pr_suburb RECORD LIKE suburb.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	glob_rpt_output CHAR(50), 
	idx,pr_err_cnt SMALLINT, 
	query_text CHAR(100) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET idx=0 
	INITIALIZE pr_quaderr.* TO NULL 
	LET query_text = "SELECT * FROM t_supply" 
	PREPARE s_supply FROM query_text 
	DECLARE c_supply CURSOR FOR s_supply 
	FOREACH c_supply INTO pr_load.* 
		LET idx=idx+1 
		SELECT * INTO pr_warehouse.* FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_supply.ware_code 
		IF pr_warehouse.post_code != pr_load.source_post_code THEN 
			LET pr_quaderr.error_text = "Warehouse ",pr_warehouse.ware_code, 
			" does NOT have same postcode as ", 
			"load file postcode - load aborted" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			EXIT FOREACH 
		END IF 
		DECLARE c_suburb CURSOR FOR 
		SELECT * INTO pr_suburb.* FROM suburb 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_text = pr_load.suburb_text 
		AND post_code = pr_load.post_code 
		OPEN c_suburb 
		FETCH c_suburb 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = "Suburb ",pr_load.suburb_text clipped, 
			" Postcode ",pr_load.post_code clipped, 
			" cannot be located." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		IF pr_load.km_qty IS NULL 
		OR pr_load.km_qty < 0 THEN 
			LET pr_quaderr.error_text = "Suburb ",pr_load.suburb_text clipped, 
			"Distance contains an invalid value" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_supply.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_supply.suburb_code = pr_suburb.suburb_code 
		LET pr_supply.km_qty = pr_load.km_qty 
		SELECT * FROM supply 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_supply.ware_code 
		AND suburb_code = pr_supply.suburb_code 
		IF status = notfound THEN 
			INSERT INTO supply VALUES (pr_supply.*) 
		ELSE 
			UPDATE supply 
			SET km_qty = pr_supply.km_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND suburb_code = pr_supply.suburb_code 
			AND ware_code = pr_supply.ware_code 
		END IF 
	END FOREACH 
	SELECT unique 1 FROM t_quaderr 
	IF status = 0 THEN 
		LET query_text = "SELECT * FROM t_quaderr" 
		PREPARE s_quaderr FROM query_text 
		DECLARE c_quaderr CURSOR FOR s_quaderr
		 
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"U57_rpt_list_quaderr","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT U57_rpt_list_quaderr TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = 0, 
		BOTTOM MARGIN = 0, 
		LEFT MARGIN = 0, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------
		 
		LET pr_err_cnt = 0 
		FOREACH c_quaderr INTO pr_quaderr.* 
			LET pr_err_cnt = pr_err_cnt + 1
			#---------------------------------------------------------
			OUTPUT TO REPORT U57_rpt_list_quaderr(l_rpt_idx,pr_quaderr.*) 		 
			#---------------------------------------------------------
		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT U57_rpt_list_quaderr
		CALL rpt_finish("U57_rpt_list_quaderr")
		#------------------------------------------------------------

	END IF 
	
	IF pr_err_cnt > 0 THEN 
		ERROR pr_err_cnt," errors encountered in load. Refer TO error REPORT." 
	ELSE 
		ERROR "Load completed successfully ." 
	END IF 
END FUNCTION 


REPORT U57_rpt_list_quaderr(p_rpt_idx,pr_quaderr) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pa_line array[4] OF CHAR(132), 
	pr_quaderr RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD 

	OUTPUT 
--	left margin 0 
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



