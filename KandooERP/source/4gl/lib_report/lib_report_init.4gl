############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#NOTE:
#reportdetl.report_code nchar(3) #Table reportdetl is empty on my DB
#rmsreps.report_code integer  #numeric unique report code range 1-99999000
#reporthead.report_code nchar(3) #have scrambled CHAR(2) data
#kandooreport.report_code nchar(10) #seems to be the name based program/module code
#kandooreport.l_report_code integer #numeric unique report code range 1-99999000


############################################################
# FUNCTION rpt_init_url_get_operation_method_exec_ind
#
# Extracted from original kandooreport
#
# RETURN 
############################################################
FUNCTION rpt_init_url_get_operation_method_exec_ind()
	DEFINE l_url_exec_ind LIKE kandooreport.exec_ind

	#Report program must know in what mode it should operate
	#Exec_ind can be set by a)ARGUMENT b) template c)default=1	
	#Depending on exec_ind, 1=user sees report menu 2=background print, 3=construct followed by print 4=program was called with DATA SQL Query...
	LET l_url_exec_ind = get_url_exec_ind()
	
	IF l_url_exec_ind = 2 THEN #PROGRAM IS RUNNING IN Background Process
		CALL rpt_set_is_background_process(TRUE)
	ELSE
		CALL rpt_set_is_background_process(FALSE)				 
	END IF
	
	IF (l_url_exec_ind IS NOT NULL) AND (l_url_exec_ind != "0") THEN 
		#LET glob_rec_kandooreport.exec_ind = l_url_exec_ind #IF provided by URL, use it
	ELSE
		LET l_url_exec_ind = db_kandooreport_get_exec_ind(UI_OFF,getmoduleid(),glob_rec_kandoouser.language_code)
		IF l_url_exec_ind IS NULL THEN #no template definition exists or exec_ind is not set 
			LET l_url_exec_ind = 1 #Default=1=show report menu
		END IF
	END IF
	CALL set_url_exec_ind(l_url_exec_ind) #Set is also in the environment to "1" 	
	
	RETURN l_url_exec_ind
END FUNCTION
{
#########################################################
# FUNCTION rpt_kandooreport_init(p_cmpy,p_report_code_module_id)
#
# This FUNCTION initilises the glob_rec_kandooreport & glob_rec_rmsreps records.
# I can still not follow, in what situation there should be a special program argument for this report init function...
#########################################################
FUNCTION rpt_kandooreport_init(p_cmpy_code,p_module_id,p_report_code_module_id) #rpt_kandooreport_init(glob_rec_kandoouser.cmpy_code,getmoduleid(),getmoduleid()) 
	DEFINE p_cmpy_code LIKE kandoouser.cmpy_code
	DEFINE p_module_id NCHAR(3) 
	DEFINE p_report_code_module_id LIKE kandooreport.report_code # nchar(10),
	
	--DEFINE l_language_code LIKE kandoouser.language_code 
	DEFINE l_tmpmsg STRING 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE i SMALLINT 
	DEFINE l_rpt_template_insert_required BOOLEAN
	DEFINE l_rpt_template_not_found BOOLEAN
	DEFINE l_ret_success BOOLEAN
	DEFINE l_country_code LIKE country.country_code
	DEFINE l_report_code LIKE rmsreps.report_code
	DEFINE l_url_exec_ind LIKE kandooreport.exec_ind
	
	#Validate function arguments
	IF p_cmpy_code IS NULL THEN
		LET p_cmpy_code = glob_rec_kandoouser.cmpy_code
	END IF
	IF p_module_id IS NULL THEN
		LET p_module_id = getmoduleid()
	END IF
	IF p_report_code_module_id IS NULL THEN
		LET p_report_code_module_id = p_module_id
	END IF

	#NOTE: Currently/Originally, PK was only kandooreport.report_code
	#But this means, All companies and ALL languages must work on the same template
	#Any template updates would be applied to all companies/languages..
	#Needs changing
	#Initialize variables	
	LET l_country_code = glob_rec_kandoouser.country_code
	#For later when DB-Schema kandooreport has been modernized/updated
	#LET glob_rec_kandooreport.cmpy_code = p_cmpy_code 
	#LET glob_rec_kandooreport.module_id = p_module_id 
	LET glob_rec_kandooreport.menupath_text = p_module_id #legazy support
	#LET glob_rec_kandooreport.report_code_module_id = p_report_code_module_id
	LET glob_rec_kandooreport.report_code = p_report_code_module_id #legazy support
	LET glob_rec_kandooreport.language_code = glob_rec_kandoouser.language_code 
	#LET glob_rec_kandooreport.country_code = glob_rec_kandoouser.country_code 


	#Depending on exec_ind, 1=user sees report menu 2=background print, 3=construct followed by print 4=program was called with DATA SQL Query...
	LET glob_rec_rmsreps.exec_ind = get_url_exec_ind()
	CASE glob_rec_rmsreps.exec_ind 
		WHEN "4" 
			LET glob_rec_rmsreps.sel_text = get_url_sel_text() --arg_val(3) 
			LET glob_rec_rmsreps.cmpy_code = p_cmpy_code 

		WHEN "3" #Was always commented - also in original. no idea what this is about 
			# Verify the prochead head entry
			# arg_val(2) = proc_code
			# arg_val(3) = seq_num

		WHEN "2" 
			LET glob_rec_rmsreps.cmpy_code = glob_rec_kandoouser.cmpy_code --p_cmpy 
			LET glob_rec_rmsreps.report_code = get_url_report_code() --arg_val(2) #INTEGER value

		OTHERWISE #Default: show report menu
			LET glob_rec_rmsreps.exec_ind = "1" 

	END CASE 

	#Kandoooption/Feature Settings can allow to change language for report
	IF get_kandoooption_feature_state("RP","01") = "Y" THEN 

		OPEN WINDOW w_rpt_dialog WITH FORM "U960-rpt-dialog"
		CALL windecoration_u("U960-rpt-dialog")
	
		#Give user the choice to change the language for this report	
		INPUT glob_rec_kandooreport.language_code WITHOUT DEFAULTS FROM kandooreport.language_code ATTRIBUTE(UNBUFFERED)
			BEFORE INPUT
				DISPLAY l_country_code TO country_code
				DISPLAY glob_rec_kandooreport.menupath_text TO module_id
				DISPLAY glob_rec_kandooreport.report_code TO report_code_module_id
		
		END INPUT	
		CLOSE WINDOW w_rpt_dialog
	END IF
	#-----------------------------------------
	# We pull the corresponding report configuration from the DB
	
	CASE 
		#Criteria company, module code, report_code and specified language
		WHEN db_kandooreport_template_exists(UI_OFF,
				p_cmpy_code,
				l_country_code, #glob_rec_kandooreport.country_code,
				glob_rec_kandooreport.language_code,
				glob_rec_kandooreport.menupath_text,
				glob_rec_kandooreport.report_code) 
			CALL db_kandooreport_get_rec(UI_OFF,
				p_cmpy_code,
				l_country_code, #glob_rec_kandooreport.country_code,
				glob_rec_kandooreport.language_code,
				glob_rec_kandooreport.menupath_text,
				glob_rec_kandooreport.report_code) RETURNING glob_rec_kandooreport.*
				
			LET l_rpt_template_insert_required = FALSE

		#Not found.. try it with company 99	AND ENGLISH
		WHEN db_kandooreport_template_exists(UI_OFF,
				mastercmpy_get_cmpy_code(l_country_code,"ENG"),
				l_country_code, #glob_rec_kandooreport.country_code,
				"ENG",
				glob_rec_kandooreport.menupath_text,
				glob_rec_kandooreport.report_code) 
			CALL db_kandooreport_get_rec(UI_OFF,
				mastercmpy_get_cmpy_code(l_country_code,"ENG"),
				l_country_code, #glob_rec_kandooreport.country_code,
				"ENG",
				glob_rec_kandooreport.menupath_text,
				glob_rec_kandooreport.report_code) RETURNING glob_rec_kandooreport.*
				
			LET l_rpt_template_insert_required = TRUE


		#NOT found.. use default 4gl-coded template 
		WHEN rpt_set_kandooreport_defaults(glob_rec_kandooreport.menupath_text,glob_rec_kandooreport.report_code)
			LET l_rpt_template_insert_required = TRUE

		OTHERWISE
			LET l_rpt_template_not_found = TRUE
			LET l_rpt_template_insert_required = FALSE
			
			CALL fgl_winmessage("Internal Error","Report program is operating without module_id/report_code configuration\not found in DB or in internal report templates catalogue","ERROR")
			LET glob_rec_kandooreport.report_code = p_report_code_module_id 
			LET glob_rec_kandooreport.language_code = glob_rec_kandoouser.language_code 
			LET glob_rec_kandooreport.width_num = 132 
			LET glob_rec_kandooreport.length_num = 66 
			LET glob_rec_kandooreport.menupath_text = p_report_code_module_id[1,3] 
			LET glob_rec_kandooreport.exec_ind = "1" 
			LET glob_rec_kandooreport.exec_flag = "Y" 
			LET glob_rec_kandooreport.selection_flag = "Y" 
			
	END CASE

--	LET glob_rec_kandooreport.l_entry_code = glob_rec_kandoouser.sign_on_code	
--	#LET l_report_code=NULL #we will NOT set this ....
--	#Check these default values - if they are correct exec_ind = 1 exec_flag="Y"

	IF (glob_rec_kandooreport.exec_ind IS NULL) or (glob_rec_kandooreport.exec_ind = 0) THEN 
		LET glob_rec_kandooreport.exec_ind = 1 #Default is show report menu 
	END IF
	
	IF (glob_rec_kandooreport.exec_ind IS NULL) THEN LET glob_rec_kandooreport.exec_flag="Y" END IF
--	LET glob_rec_kandooreport.l_report_date = TODAY
--	LET glob_rec_kandooreport.l_report_time = CURRENT HOUR TO MINUTE #USING "hh:MM"   #nchar(5)
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	IF l_rpt_template_insert_required = TRUE THEN
		#Final check, that record does not exist in DB
		IF NOT db_kandooreport_template_exists(UI_ON,
				p_cmpy_code,
				l_country_code,
				glob_rec_kandooreport.language_code,
				glob_rec_kandooreport.menupath_text,
				glob_rec_kandooreport.report_code) THEN		 
			INSERT INTO kandooreport VALUES (glob_rec_kandooreport.*)
			MESSAGE "Inserted new report template"
			--SLEEP 3
		ELSE 
			CALL fgl_winmessage("4GL Error","Something went fully wrong in rpt_kandooreport_init\nFirst, we did not find report template. now when inserting.. we find one.","ERROR")
		END IF 
	ELSE
		IF glob_rec_kandooreport.l_report_code IS NULL THEN
			LET glob_rec_kandooreport.l_report_code = 0 #can't insert NULL
		END IF
#		UPDATE kandooreport SET * = glob_rec_kandooreport.* 
#		WHERE report_code = glob_rec_kandooreport.report_code 
--		UPDATE kandooreport 
--		SET l_entry_code = glob_rec_kandooreport.l_entry_code,
--		l_report_date = glob_rec_kandooreport.l_report_date,
--		l_report_time = glob_rec_kandooreport.l_report_time # nchar(5)
--		WHERE language_code = glob_rec_kandooreport.language_code	
--		AND menupath_text = glob_rec_kandooreport.menupath_text  #legazy
--		AND report_code = glob_rec_kandooreport.report_code #legazy
		#l_report_code = glob_rec_kandooreport.l_report_code,
		#AND cmpy_code = $p_cmpy_code
		#AND country_code = p_country_code
	END IF

	# exec_ind could have been set by program argument
	# We can not set it earlier, otherwise kandooreport table will be update
	#constantly with the program argument exec_ind
	#It will only be set for this session
	LET l_url_exec_ind = get_url_exec_ind()
	IF (l_url_exec_ind IS NOT NULL) AND (l_url_exec_ind != 0) THEN
		LET glob_rec_kandooreport.exec_ind = l_url_exec_ind
	END IF


#----------------------------------------------------------------------
# old additional legacy code.. I'm not sure about...
--	#HuHo I do NOT know, what arguments should be used TO call these programs
--	# I also add a arg check...
--	IF num_args() > 0 THEN 
--		FOR i = 0 TO num_args() 
--			LET l_tmpmsg = l_tmpmsg , "arg_val(", trim(i), ") =", trim(arg_val(1)), "\n" 
--		END FOR 
--		CALL fgl_winmessage("Module was launched with these arguments", l_tmpmsg,"info") 
--	END IF 
--
--	LET glob_rec_rmsreps.exec_ind = get_url_exec_ind() --arg_val(1) 
	#Initialize rmsreps.* record with data from kandooreport

	#All operations on kandooreport (DB and glob_rec) are completed for now
	#We initialize the rmsreps record (prog rec AND DB rec)

	LET glob_rec_rmsreps.cmpy_code = glob_rec_kandoouser.cmpy_code --p_cmpy 
	LET glob_rec_rmsreps.report_text = glob_rec_kandooreport.header_text 
	LET glob_rec_rmsreps.status_text = "Scheduled" 
	LET glob_rec_rmsreps.entry_code = glob_rec_kandoouser.sign_on_code  --p_kandoouser_sign_on_code 
	LET glob_rec_rmsreps.security_ind = glob_rec_kandoouser.security_ind 
	LET glob_rec_rmsreps.report_date = TODAY #glob_rec_kandooreport.l_report_date 
	LET glob_rec_rmsreps.report_time = CURRENT HOUR TO MINUTE #glob_rec_kandooreport.l_report_time
	LET glob_rec_rmsreps.report_pgm_text = glob_rec_kandooreport.report_code 
	LET glob_rec_rmsreps.report_width_num = glob_rec_kandooreport.width_num 
	LET glob_rec_rmsreps.page_length_num = glob_rec_kandooreport.length_num 
	LET glob_rec_rmsreps.sel_flag = glob_rec_kandooreport.selection_flag

#--------------------------
	#Create the report_code INT
	IF glob_rec_rmsreps.report_code IS NULL OR glob_rec_rmsreps.report_code = 0 THEN

		#WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		WHENEVER SQLERROR CONTINUE
		BEGIN WORK 
			DECLARE c_get_report_code_rmsparm CURSOR FOR 
			SELECT next_report_num FROM rmsparm 
			WHERE cmpy_code = glob_rec_rmsreps.cmpy_code 
			FOR UPDATE 
			OPEN c_get_report_code_rmsparm 
			FETCH c_get_report_code_rmsparm INTO l_report_code 
			IF status = notfound THEN 
				CALL fgl_winmessage("Setup Incorrect - Exit Program",kandoomsg2("G",5004,""),"ERROR") 
				#5004 Report Parameters NOT SET up - Get out
				EXIT program 
			END IF 
			IF l_report_code >= 99999000 THEN 
				LET l_report_code = 1 
			END IF 
	
			#Ensure again????, ... a bit strange to me. PK = cmpy_code AND report_code... so, there can only be ONE or NONE
			WHILE true 
				SELECT unique 1 FROM rmsreps 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code  
				AND report_code = l_report_code
				IF status = notfound THEN 
					EXIT WHILE 
				ELSE 
					LET l_report_code = l_report_code + 1 #use the next available report_code number
					IF l_report_code >= 99999000 THEN #at the end, start from 1 again
						LET l_report_code = 1 
					END IF 
				END IF 
			END WHILE 
	
			#Update next_report_num for the next available report_code id (to be used by the next report)
			
			UPDATE rmsparm 
			SET next_report_num = l_report_code + 1 
			WHERE cmpy_code = glob_rec_rmsreps.cmpy_code  
	
		COMMIT WORK 
		  
		LET glob_rec_rmsreps.report_code = l_report_code 
		LET glob_rec_rmsreps.file_text = trim(glob_rec_rmsreps.cmpy_code), ".", trim(glob_rec_rmsreps.report_code)
		
		CALL rpt_update_rmsreps()   
	END IF

#--------------------------
		
	RETURN glob_rec_rmsreps.exec_ind #This is shit and needs changing
END FUNCTION 
}
{


FUNCTION rpt_init_base(p_rpt_header)
	--DEFINE p_rpt_code LIKE kandooreport.report_code
	DEFINE p_rpt_header LIKE rmsreps.report_text

	#---------------------------------------------------
	
	CALL rpt_set_report_header(p_rpt_header)

	#----------------------------------------------------
	# glob_rec_rpt_settings
	#----------------------------------------------------
	#Note: kandoo used different tables, variables, etc.. 
	#and in local, module and global scopes... for the same purpose
	#of report generation in the different modules
	#This record was intoduced to stream line / merge all together
	LET glob_rec_rpt_settings.rpt_cmpy_code = glob_rec_kandoouser.cmpy_code
	LET glob_rec_rpt_settings.rpt_entry_code = glob_rec_kandoouser.sign_on_code
	LET glob_rec_rpt_settings.rpt_language_code = glob_rec_kandoouser.language_code
	LET glob_rec_rpt_settings.rpt_module_id = getmoduleid()
	
	#LET glob_rec_rpt_settings.rpt_title1 = p_rpt_note CLIPPED
	#LET glob_rec_rpt_settings.rpt_title2 = ???
	LET glob_rec_rmsreps.report_date = today 
	LET glob_rec_rpt_settings.rpt_time = CURRENT HOUR TO MINUTE #TIME USING "hh:mm" "<<<<<"
	
	#LET glob_rec_rpt_settings.rpt_report_code = ?INT? 
	#LET glob_rec_rpt_settings.rpt_name LIKE kandooreport.report_code, #nchar(10)
	#LET glob_rec_rpt_settings.file_text = 
	#	glob_rec_rpt_settings.get_settings_reportPath() CLIPPED, "/", 
	#	rpt_cmpy_code CLIPPED, 
	#	".",
	#	glob_rec_rpt_settings.rpt_module CLIPPED,
	#	".",		
	#	glob_rec_rpt_settings.rpt_report_code.report_code clipped USING "<<<<<<<<" 

	CALL rpt_set_dest_printer(glob_rec_kandoouser.print_text)
	CALL rpt_set_start_page(1)
	CALL rpt_set_align_ind("N")
	CALL rpt_set_copy_num(1)
	
	
	#----------------------------------------------------
	# Individual global report variables
	#----------------------------------------------------		
	LET glob_rpt_date = glob_rec_rmsreps.report_date 
	LET glob_rpt_time = glob_rec_rpt_settings.rpt_time 
	LET glob_rpt_date2 = glob_rec_rmsreps.report_date 
	LET glob_rpt_time2 = glob_rec_rpt_settings.rpt_time 	
	#LET glob_rpt_code = ??? #nchar(10)	
	#LET glob_report_identifier = ????? STRING
--	LET glob_rpt_note = glob_rec_rpt_settings.rpt_title1  #title line 1 text 
--	LET glob_rpt_note2 = glob_rec_rpt_settings.rpt_title2 #title line 2 text	
--	LET glob_rpt_line1 = glob_rec_rpt_settings.rpt_title1  #title line 1 text 
--	LET glob_rpt_line2 = glob_rec_rpt_settings.rpt_title2 #title line 2 text



	#----------------------------------------------------
	# glob_rec_kandooreport
	#----------------------------------------------------		
	#LET glob_rec_kandooreport.report_code = ??? #nchar(10)
	LET glob_rec_kandooreport.language_code = glob_rec_rpt_settings.rpt_language_code
	#LET glob_rec_kandooreport.header_text = glob_rec_rpt_settings.rpt_title1
	LET glob_rec_kandooreport.menupath_text = glob_rec_rpt_settings.rpt_module_id

	LET glob_rec_kandooreport.l_report_code = glob_rec_rpt_settings.rpt_report_code #INT

	LET glob_rec_kandooreport.l_report_date = glob_rec_rmsreps.report_date
	LET glob_rec_kandooreport.l_report_time = glob_rec_rpt_settings.rpt_time
	LET glob_rec_kandooreport.l_entry_code = glob_rec_kandoouser.sign_on_code


	#----------------------------------------------------
	# glob_rec_rmsreps
	#----------------------------------------------------		

	--LET glob_rec_rmsreps.report_code = getmoduleid()
	LET glob_rec_rmsreps.cmpy_code = glob_rec_rpt_settings.rpt_cmpy_code
	LET glob_rec_rmsreps.report_code = glob_rec_rpt_settings.rpt_report_code #INT
	#LET glob_rec_rmsreps.report_text = glob_rec_rpt_settings.rpt_title1

	LET glob_rec_rmsreps.entry_code = glob_rec_rpt_settings.rpt_entry_code
	LET glob_rec_rmsreps.security_ind = glob_rec_rpt_settings.rpt_security_ind
	
	LET glob_rec_rmsreps.report_date = glob_rec_rmsreps.report_date
	LET glob_rec_rmsreps.report_time = glob_rec_rpt_settings.rpt_time
	
	#LET glob_rec_rmsreps.report_pgm_text = ????? #nvarchar(10)	
	LET glob_rec_rmsreps.file_text = glob_rec_rmsreps.file_text

END FUNCTION
}

{
	SELECT inv_ref1_text, 
	inv_ref2a_text, 
	inv_ref2b_text 
	INTO glob_rec_arparms.inv_ref1_text, 
	glob_rec_arparms.inv_ref2a_text, 
	glob_rec_arparms.inv_ref2b_text 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1"
}	