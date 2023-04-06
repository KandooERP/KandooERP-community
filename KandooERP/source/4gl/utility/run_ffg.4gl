DEFINE mdl_ffg_dir,mdl_ffg_logdir,mdl_ffg_incl_dir STRING 
DEFINE cb_use_main_template ui.combobox 
DEFINE cb_use_child_template ui.combobox 
DEFINE cb_use_grandchild_template ui.combobox 
DEFINE cb_use_list_template ui.combobox 
DEFINE cb_use_form_template ui.combobox 
DEFINE cb_use_main_form ui.combobox 
DEFINE cb_use_list_form ui.combobox 
DEFINE cb_use_child_form ui.combobox 
DEFINE cb_use_grandchild_form ui.combobox 
DEFINE cb_list_projects ui.combobox 
DEFINE mdl_perl_exe,mdl_ffg_include_dir,mdl_ffg_data_dir,mdl_template_editor_exe,mdl_qx_workspace_dir STRING
DEFINE mdl_eclipse_project_dir,mdl_project_dir,mdl_qx_4gl_location,mdl_qx_form_location STRING 
DEFINE mdl_qx_form_base_dir,mdl_qx_module_base_dir,mdl_full_editor_command STRING 
DEFINE mdl_global_params_file,mdl_current_params_file,mdl_project_params_file STRING 
DEFINE mdl_lycia_structure_location STRING 
DEFINE mdl_lyciaprojectdir STRING
DEFINE object_to_generate STRING 
DEFINE mdl_form_data RECORD
	project_name STRING, 
	database_name STRING, 
	object_to_generate STRING, 
	program_name STRING, 
	generated_module_name STRING, 
	use_main_form STRING, 
	use_main_template STRING, 
	use_child_template STRING, 
	use_child_form STRING, 
	use_grandchild_template STRING, 
	use_grandchild_form STRING, 
	use_list_template STRING, 
	use_list_form STRING, 
	skip_functions STRING, 
	parent_primary_key STRING, 
	child_primary_key STRING, 
	grandchild_primary_key STRING, 
	overwrite_fgl_target BOOLEAN, 
	generate_not_null BOOLEAN, 
	debug_flag BOOLEAN, 
	define_style STRING, 
	gen_form_name STRING, 
	use_form_template STRING, 
	use_table_name STRING, 
	generate_lookup BOOLEAN
END RECORD
DEFINE msg STRING 

DEFINE skf_string STRING 
DEFINE dummy_char CHAR(1) # used TO workaround a color syntax editor issue 
DEFINE mdl_skip_functions DYNAMIC ARRAY OF STRING 
DEFINE form_templates DYNAMIC ARRAY OF RECORD 
	template STRING 
END RECORD 
DEFINE main_templates DYNAMIC ARRAY OF RECORD 
	template STRING 
END RECORD 
DEFINE qxperloclng,skx SMALLINT 
DEFINE ps CHAR(1) 
MAIN 
	DEFINE file_name STRING 
	DEFINE file_to_read,programfilesdir STRING 
	DEFINE backslash,putenvvar STRING 
	DEFINE regexp util.regex 
	DEFINE res boolean 

	CALL os.path.separator() RETURNING ps 
	LET res = false 
	OPEN WINDOW f_run_ffg with FORM "f_run_ffg" 

	LET mdl_ffg_dir = fgl_getenv("FFGDIR") 
	#LET mdl_ffg_dir = util.REGEX.replace(mdl_ffg_dir,/backslash/,ps)
	IF mdl_ffg_dir IS NULL OR NOT os.path.isdirectory(mdl_ffg_dir) THEN 
		CALL fgl_winmessage( "ffg_dir NOT found", mdl_ffg_dir ) 
		--	prompt "please input mdl_ffg_dir " for mdl_ffg_dir  -- albo
		LET mdl_ffg_dir = promptInput("please input mdl_ffg_dir ","",60) -- albo 
	ELSE 
		CALL fgl_setenv("ffg_dir",mdl_ffg_dir) 
		LET mdl_ffg_incl_dir = "FFGINCLDIR=",mdl_ffg_dir,"/incl"
		CALL fgl_putenv(mdl_ffg_incl_dir)
	END IF 

	#SET mdl_ffg_include_dir with precedence ORDER
	LET mdl_global_params_file = mdl_ffg_dir clipped,"/etc/global.params" 
	
	CALL read_params_file(mdl_global_params_file,"") 

	CALL get_templates_list(mdl_ffg_dir) 

	LET mdl_current_params_file = mdl_ffg_dir clipped,"/etc/CurrentValues.params" 
	CALL read_params_file(mdl_current_params_file,"QxWorkSpace") 

	# Get wordpad path .... sorry if that complex
	# %ProgramFiles%\Windows NT\Accessories\wordpad.exe
	LET ProgramFilesDir=fgl_getenv("ProgramFiles") 
	LET res = util.regex.match(programfilesdir, /.*\s.*/) 
	IF ( res ) THEN 
		LET mdl_full_editor_command = "\"",ProgramFilesDir clipped,"\\Windows NT\\Accessories\\wordpad.exe","\"" 
	ELSE 
		LET mdl_full_editor_command = programfilesdir clipped,"\\Windows NT\\Accessories\\wordpad.exe" 
	END IF 


	IF mdl_qx_workspace_dir IS NOT NULL THEN 
		# this directory has all the projects
		# if the .location file exists, the source location IS contained in that file
		LET mdl_eclipse_project_dir = mdl_qx_workspace_dir clipped,"/.metadata/.plugins/org.eclipse.core.resources/.projects" 
	ELSE 
		ERROR "You need TO specify in which Lycia Work Space you want TO work" 
	END IF 


	MENU "FFG" 


		COMMAND "GenerateProgram" 
			CALL generate_program() 
		COMMAND "Mod Template" 
			CALL ViewTemplates(".mtplt") 
		COMMAND "Form Template" 
			CALL ViewTemplates(".ftplt") 

		COMMAND "WorkSpace" 
			CALL change_workspace() 
		COMMAND "History" 
			CALL view_history() 
		COMMAND "Edit Global Parm" 
			CALL edit_parameters ("global.params") 
		COMMAND "Edit Current Parm" 
			CALL edit_parameters ("CurrentValues.params") 
		COMMAND "Edit Project Parm" 
			--	prompt "Which project ? " for mdl_project_name  -- albo
			LET mdl_form_data.project_name = promptInput("Which project ? ","",60) -- albo 
			LET file_name = mdl_form_data.project_name clipped,".params" 
			CALL edit_parameters ("CurrentValues.params") 

		COMMAND "Exit" 
			EXIT program 
	END MENU 

END MAIN 

FUNCTION generate_program () 
	DEFINE rep CHAR(1) 
	DEFINE full_command,full_path,fgl_options,lyciaprojectlocation STRING 
	DEFINE qx4glloclng,qxperloclng,matching_forms_number INTEGER 
	DEFINE lyciastructurelocation CHAR(256)
	DEFINE l_database_schema_file STRING 
	DEFINE file_to_read STRING 
	DEFINE file_exists boolean 
	DEFINE options_list DYNAMIC ARRAY OF STRING 
	DEFINE templates_list,mdl_skip_functions,varstring DYNAMIC ARRAY OF STRING 
	DEFINE idx,arr_size,arr_num SMALLINT 
	DEFINE status_message STRING 
	DEFINE log_file STRING 
	DEFINE relative_form_path STRING 
	DEFINE exec_time DATETIME year TO second 
	DEFINE exectime STRING 


	LET object_to_generate = NULL 
	LET mdl_form_data.define_style = "like" 
	LET mdl_form_data.overwrite_fgl_target = "true" 
	LET mdl_form_data.generate_not_null = "true"
	CALL options_list.clear () 

	LET mdl_qx_4gl_location = NULL 
	LET mdl_qx_form_location = NULL 
	LET mdl_form_data.database_name = NULL 

	INPUT BY NAME mdl_form_data.project_name, 
	mdl_form_data.database_name, 
	object_to_generate, 
	mdl_form_data.program_name, 
	mdl_form_data.generated_module_name, 
	mdl_form_data.use_main_form, 
	mdl_form_data.use_main_template, 
	mdl_form_data.use_child_template, 
	mdl_form_data.use_child_form, 
	mdl_form_data.use_grandchild_template, 
	mdl_form_data.use_grandchild_form, 
	mdl_form_data.use_list_template, 
	mdl_form_data.use_list_form, 
	mdl_form_data.skip_functions, 
	mdl_form_data.parent_primary_key, 
	mdl_form_data.child_primary_key, 
	mdl_form_data.child_primary_key, 
	mdl_form_data.grandchild_primary_key, 
	mdl_form_data.grandchild_primary_key, 
	mdl_form_data.overwrite_fgl_target, 
	mdl_form_data.generate_not_null, 
	mdl_form_data.debug_flag, 
	mdl_form_data.define_style, 
	mdl_form_data.gen_form_name, 
	mdl_form_data.use_form_template, 
	mdl_form_data.use_table_name, 
	mdl_form_data.generate_lookup 
	WITHOUT DEFAULTS 

		BEFORE FIELD project_name 
			# prject list IS in mdl_eclipse_project_dir
			# we can build a combobox with that list
			CALL get_projects_list ("project_name","") 

		AFTER FIELD project_name 
			IF mdl_form_data.project_name IS NOT NULL THEN 
				# get project specific parameters
				LET mdl_project_params_file = mdl_ffg_dir clipped,"/etc/",mdl_form_data.project_name CLIPPED,".params" 
				CALL read_params_file(mdl_project_params_file,"") 
				CALL get_project_locations (mdl_form_data.project_name) 
				RETURNING mdl_qx_4gl_location,mdl_qx_form_location 
				LET qx4glloclng = mdl_qx_4gl_location.getlength() 
				LET qxperloclng = mdl_qx_form_location.getlength() 

				IF os.path.exists(mdl_qx_4gl_location) THEN # AND IS a directory 
					LET fgl_options = "-projectname ",mdl_form_data.project_name 
					CALL options_list.append(fgl_options) 

				ELSE 
					CALL get_projects_list ("project_name",mdl_form_data.project_name) 
					MESSAGE "Project does NOT exist, please check AND submit again" 
					NEXT FIELD project_name 
				END IF 
			ELSE 
				NEXT FIELD project_name 
			END IF 

		BEFORE FIELD database_name 
			CALL read_params_file(mdl_project_params_file,"DatabaseName")
			IF mdl_form_data.database_name IS NOT NULL THEN 
				DISPLAY BY NAME mdl_form_data.database_name 
			END IF 
		
		AFTER FIELD database_name
			# Check if the schema file is here
			LET l_database_schema_file = mdl_ffg_data_dir,"/",mdl_form_data.database_name,".xml"
			IF NOT os.path.isfile(l_database_schema_file) THEN
				ERROR "Please check existence of database schema file ",l_database_schema_file
				NEXT FIELD database_name
			END IF

		AFTER FIELD object_to_generate 
			IF object_to_generate matches "*module*" THEN 
				NEXT FIELD program_name 
			ELSE 
				NEXT FIELD form_data.gen_form_name 
			END IF 

		AFTER FIELD program_name 
			IF mdl_form_data.program_name IS NOT NULL THEN 
				LET fgl_options = "-program ",mdl_form_data.program_name 
				CALL options_list.append(fgl_options) 
			ELSE 
				IF object_to_generate <> "form_module" THEN 
					# program name not mandatory when building forms+programs in buld mode
					NEXT FIELD program_name 
				END IF 
			END IF 

		AFTER FIELD generated_module_name 
			# module name is optional. If NULL, it takes program name
			IF mdl_form_data.generated_module_name IS NOT NULL THEN 
				LET fgl_options = "-modulegenerate ",mdl_form_data.generated_module_name 
				CALL options_list.append(fgl_options) 
			ELSE 
				IF object_to_generate <> "form_module" THEN 
					# module name not mandatory when building forms+programs in buld mode
					ERROR "Setting module name equal to program name"
					LET mdl_form_data.generated_module_name = mdl_form_data.program_name
					DISPLAY BY NAME mdl_form_data.generated_module_name
					NEXT FIELD generated_module_name
				END IF 
			END IF 
		
		BEFORE FIELD use_main_form
			ERROR "Type either full form name or folder name to list forms in that folder"
			
		AFTER FIELD use_main_form 
			IF mdl_form_data.use_main_form IS NOT NULL THEN 
				IF os.path.pathtype(mdl_form_data.use_main_form) = "relative" AND mdl_form_data.use_main_form NOT matches "*.fm2" THEN 
					LET full_path = mdl_qx_form_location clipped,"/",mdl_form_data.use_main_form 
				ELSE 
					LET full_path = mdl_form_data.use_main_form 
				END IF 
				IF os.path.isfile(full_path) AND full_path matches "*.fm2" THEN 
					# ffg.pl command line wants a relative path, after
					LET relative_form_path=mdl_form_data.use_main_form.substring(qxperloclng+2,mdl_form_data.use_main_form.getlength()) 

					IF NOT view_form(mdl_form_data.use_main_form,relative_form_path) THEN 
						NEXT FIELD use_main_form 
					END IF 
					LET fgl_options = "-parentformuse ",relative_form_path 
					CALL options_list.append(fgl_options) 
				ELSE 
					LET full_path = mdl_qx_form_location clipped,"/",mdl_form_data.use_main_form 
					IF os.path.isfile(full_path) AND full_path matches "*.fm2" THEN 
						LET relative_form_path=mdl_form_data.use_main_form.substring(qxperloclng+2,mdl_form_data.use_main_form.getlength()) 
						IF NOT view_form(mdl_form_data.use_main_form,relative_form_path) THEN 
							NEXT FIELD form_data.use_main_form 
						END IF 
						LET fgl_options = "-parentformuseuse ",relative_form_path 
						CALL options_list.append(fgl_options) 
					ELSE 
						LET matching_forms_number = get_forms_list ("use_main_form",mdl_form_data.use_main_form) 
						ERROR "Number of forms matching:",matching_forms_number," please select from the combo box" 
						NEXT FIELD use_main_form 
					END IF 
				END IF 
			ELSE 
				IF object_to_generate <> "form_module" THEN 
					NEXT FIELD use_main_form 
				END IF 
			END IF 

		AFTER FIELD use_main_template 
			IF mdl_form_data.use_main_template IS NOT NULL THEN 
				LET full_path = mdl_ffg_dir clipped,"/templates/module/",mdl_form_data.use_main_template 
				IF os.path.exists(full_path) AND full_path matches "*.mtplt" THEN 
					LET fgl_options = "-maintemplate ",mdl_form_data.use_main_template 
					CALL options_list.append(fgl_options) 
				ELSE 
					NEXT FIELD use_main_template 
				END IF 
			ELSE 
				NEXT FIELD use_main_template 
			END IF 

		AFTER FIELD use_child_template 
			IF mdl_form_data.use_child_template IS NOT NULL THEN 
				LET full_path = mdl_ffg_dir clipped,"/templates/module/",mdl_form_data.use_child_template 
				IF os.path.exists(full_path) AND full_path matches "*.mtplt" THEN 
					LET fgl_options = "-childtemplate ",mdl_form_data.use_child_template 
					CALL options_list.append(fgl_options) 
				ELSE 
					NEXT FIELD use_child_template 
				END IF 
			ELSE 
				NEXT FIELD use_list_template 
			END IF 

		AFTER FIELD use_child_form 
			IF mdl_form_data.use_child_form IS NULL THEN 
				NEXT FIELD use_list_template 
			END IF 
			IF os.path.exists(mdl_form_data.use_child_form) AND mdl_form_data.use_child_form IS NOT NULL THEN 
				LET relative_form_path=mdl_form_data.use_child_form.substring(qxperloclng+1,mdl_form_data.use_child_form.getlength()) 
				IF NOT view_form(mdl_form_data.use_child_form,relative_form_path) THEN 
					NEXT FIELD use_main_form 
				END IF 
				LET fgl_options = "-childformuse ",relative_form_path 
				CALL options_list.append(fgl_options) 

			ELSE 
				LET full_path = mdl_qx_form_location clipped,"/",mdl_form_data.use_child_form 
				IF os.path.exists(full_path) THEN 
					IF NOT view_form(mdl_form_data.use_child_form,relative_form_path) THEN 
						NEXT FIELD use_main_form 
					END IF 
					LET fgl_options = "-childformuse ",mdl_form_data.use_child_form 
					CALL options_list.append(fgl_options) 
				ELSE 
					LET matching_forms_number = get_forms_list ("use_child_form",mdl_form_data.use_child_form) 
					MESSAGE "Number of forms matching:",matching_forms_number," please select from the combo box" 
					NEXT FIELD use_child_form 
				END IF 
			END IF 


		AFTER FIELD use_grandchild_template 
			IF mdl_form_data.use_grandchild_template IS NOT NULL THEN 
				LET full_path = mdl_ffg_dir clipped,"/templates/module/",mdl_form_data.use_grandchild_template 
				IF os.path.exists(full_path) AND full_path matches "*.mtplt" THEN 
					LET fgl_options = "-grandchildtemplate ",mdl_form_data.use_grandchild_template 
					CALL options_list.append(fgl_options) 
				ELSE 
					NEXT FIELD use_grandchild_template 
				END IF 
			ELSE 
				NEXT FIELD use_grandchild_template 
			END IF 

		AFTER FIELD use_grandchild_form 
			IF mdl_form_data.use_grandchild_form IS NULL THEN 
				NEXT FIELD define_style 
			END IF 
			IF os.path.exists(mdl_form_data.use_grandchild_form) AND mdl_form_data.use_grandchild_form IS NOT NULL THEN 
				LET relative_form_path=mdl_form_data.use_grandchild_form.substring(qxperloclng+1,mdl_form_data.use_grandchild_form.getlength()) 
				IF NOT view_form(mdl_form_data.use_grandchild_form,relative_form_path) THEN 
					NEXT FIELD use_main_form 
				END IF 
				LET fgl_options = "-grandchildformuse ",relative_form_path 
				CALL options_list.append(fgl_options) 
			ELSE 
				LET full_path = mdl_qx_form_location clipped,"/",mdl_form_data.use_grandchild_form 
				IF os.path.exists(full_path) THEN 
					IF NOT view_form(mdl_form_data.use_grandchild_form,relative_form_path) THEN 
						NEXT FIELD use_main_form 
					END IF 
					LET fgl_options = "-grandchildformuse ",mdl_form_data.use_grandchild_form 
					CALL options_list.append(fgl_options) 
					# CALL view_form(mdl_form_data.form_data.use_grandchild_form) problems with opening several windows does NOT work yet
				ELSE 
					LET matching_forms_number = get_forms_list ("use_grandchild_form",mdl_form_data.use_grandchild_form) 
					MESSAGE "Number of forms matching:",matching_forms_number," please select from the combo box" 
					NEXT FIELD form_data.use_grandchild_form 
				END IF 
			END IF 

		AFTER FIELD use_list_template 
			IF mdl_form_data.use_list_template IS NOT NULL THEN 
				LET full_path = mdl_ffg_dir clipped,"/templates/module/",mdl_form_data.use_list_template 
				IF os.path.exists(full_path) AND full_path matches "*.mtplt" THEN 
					LET fgl_options = "-grandchildtemplate ",mdl_form_data.use_list_template 
					CALL options_list.append(fgl_options) 
				ELSE 
					NEXT FIELD use_list_template 
				END IF 
			ELSE 
				NEXT FIELD skip_functions 
			END IF 

		AFTER FIELD use_list_form 
			IF mdl_form_data.use_list_form IS NOT NULL THEN 
				IF os.path.exists(mdl_form_data.use_list_form) THEN 
					# ffg.pl command line wants a relative path, after
					LET relative_form_path=mdl_form_data.use_list_form.substring(qxperloclng+2,mdl_form_data.use_list_form.getlength()) 

					IF NOT view_form(mdl_form_data.use_list_form,relative_form_path) THEN 
						NEXT FIELD use_list_form 
					END IF 
					LET fgl_options = "-formlist ",relative_form_path 
					CALL options_list.append(fgl_options) 
					# CALL get_tables_list(mdl_form_data.use_list_form)
				ELSE 
					LET full_path = mdl_qx_form_location clipped,"/",mdl_form_data.use_list_form 
					IF os.path.exists(full_path) AND mdl_form_data.use_list_form IS NOT NULL THEN 
						LET relative_form_path=mdl_form_data.use_list_form.substring(qxperloclng+2,mdl_form_data.use_list_form.getlength()) 
						LET fgl_options = "-formlist ",relative_form_path 
						CALL options_list.append(fgl_options) 
					ELSE 
						LET matching_forms_number = get_forms_list ("use_list_form",mdl_form_data.use_list_form) 
						MESSAGE "Number of forms matching:",matching_forms_number," please select from the combo box" 
						NEXT FIELD use_list_form 
					END IF 
				END IF 
			END IF 

		AFTER FIELD skip_functions 
			LET skx = 1 
			IF mdl_skip_functions[skx] IS NOT NULL THEN 
				WHILE mdl_skip_functions[skx] IS NOT NULL 
					LET skf_string = skf_string CLIPPED,"|",mdl_skip_functions[skx] 
					LET skx = skx + 1 
				END WHILE 
				LET fgl_options = "-mdl_skip_functions ",skf_string 
				CALL options_list.append(fgl_options) 
			END IF 

		AFTER FIELD define_style 
			IF mdl_form_data.define_style IS NOT NULL THEN 
				LET fgl_options = "-definestyle ",mdl_form_data.define_style 
				CALL options_list.append(fgl_options) 
			END IF 

		AFTER FIELD parent_primary_key 
			IF mdl_form_data.parent_primary_key IS NOT NULL THEN 
				LET fgl_options = "-parentprimarykey ",mdl_form_data.parent_primary_key 
				CALL options_list.append(fgl_options) 
			END IF 

		AFTER FIELD child_primary_key 
			IF mdl_form_data.child_primary_key IS NOT NULL THEN 
				LET fgl_options = "-childprimarykey ",mdl_form_data.child_primary_key 
				CALL options_list.append(fgl_options) 
			END IF 

		AFTER FIELD grandchild_primary_key 
			IF mdl_form_data.grandchild_primary_key IS NOT NULL THEN 
				LET fgl_options = "-grandchildprimarykey ",mdl_form_data.grandchild_primary_key 
				CALL options_list.append(fgl_options) 
			END IF 

			#ON CHANGE force_primary_key
			#	IF mdl_form_data.force_primary_key IS NOT NULL THEN
			#		LET fgl_options = "-foreignkey ",mdl_form_data.force_primary_key
			#		CALL options_list.append(fgl_options)
			#	END IF

		AFTER FIELD overwrite_fgl_target 
			IF mdl_form_data.overwrite_fgl_target = true THEN 
				LET fgl_options = "-forcetargetfile " 
				CALL options_list.append(fgl_options) 
			END IF 

		AFTER FIELD generate_not_null
			IF mdl_form_data.generate_not_null = true THEN 
				LET fgl_options = "-checknotnull " 
				CALL options_list.append(fgl_options) 
			END IF		 

		AFTER FIELD debug_flag 
			IF mdl_form_data.debug_flag > 0 THEN 
				LET fgl_options = "-debug ",mdl_form_data.debug_flag 
				CALL options_list.append(fgl_options) 
			END IF 

		BEFORE FIELD gen_form_name,use_form_template,use_table_name,generate_lookup 
			IF object_to_generate = "module" THEN 
				ERROR "Please click on Accept TO generate the module" 
				NEXT FIELD previous 
			END IF 

		AFTER FIELD gen_form_name 
			IF mdl_form_data.gen_form_name IS NOT NULL THEN 
				LET fgl_options = "-formgenerate ",mdl_form_data.gen_form_name 
				CALL options_list.append(fgl_options) 
			END IF 

		AFTER FIELD use_form_template 
			IF mdl_form_data.use_form_template IS NOT NULL THEN 
				LET fgl_options = "-formtemplate ",mdl_form_data.use_form_template 
				CALL options_list.append(fgl_options) 
			END IF 

		AFTER FIELD use_table_name 
			IF mdl_form_data.use_table_name IS NOT NULL THEN 
				LET fgl_options = "-formtable ",mdl_form_data.use_table_name 
				CALL options_list.append(fgl_options) 
			END IF 

		AFTER FIELD generate_lookup 
			IF mdl_form_data.generate_lookup = true THEN 
				LET fgl_options = "-formlookup " 
				CALL options_list.append(fgl_options) 
			END IF 

		AFTER INPUT 
			IF mdl_form_data.use_main_form IS NULL THEN
				ERROR "Please choose a form"
				NEXT FIELD use_main_form
			END IF
			IF mdl_form_data.use_main_template IS NULL THEN
				ERROR "Please choose a template"
				NEXT FIELD use_main_template
			END IF 
			
			IF mdl_form_data.use_list_template IS NOT NULL
			AND mdl_form_data.use_list_form IS NULL THEN
				ERROR "Please choose a list/scan form"
				NEXT FIELD  use_list_form
			END IF
			
			IF mdl_form_data.use_list_template IS NULL
			AND mdl_form_data.use_list_form IS NOT NULL THEN
				ERROR "Please choose a list/scan template"
				NEXT FIELD  use_list_template
			END IF

	END INPUT 

	LET arr_size= options_list.getsize() 
	IF arr_size > 3 THEN 
		LET arr_num = 1 
		IF mdl_form_data.debug_flag > 1 THEN 
			# LET full_command = mdl_form_data.perl_exe clipped," -I ",mdl_form_data.ffg_include_dir clipped," -d ",mdl_form_data.ffg_dir clipped,"\\ffg.pl "
			LET full_command = mdl_perl_exe clipped," -d ",mdl_ffg_dir clipped,"\\ffg.pl " 
		ELSE 
			#LET full_command = mdl_perl_exe clipped," -I ",mdl_ffg_include_dir clipped," ",mdl_ffg_dir clipped,"\\ffg.pl "
			LET full_command = mdl_perl_exe clipped," ",mdl_ffg_dir clipped,"\\ffg.pl " 
		END IF 
		WHILE arr_num <= arr_size 
			LET full_command = full_command clipped," ",options_list[arr_num] 
			LET arr_num = arr_num + 1 
		END WHILE 

		LET exec_time = CURRENT 
		LET exectime=exec_time 
		LET exectime = util.REGEX.replace(exectime,/\s/,"@") 
		LET exectime = util.REGEX.replace(exectime,/:/g,"_") 
		LET log_file = mdl_ffg_logdir clipped,"/",exectime,"__",mdl_form_data.project_name clipped,"__",mdl_form_data.program_name clipped,".log" 
		LET full_command = full_command clipped ," -logfile ", log_file 
		#LET full_command = util.REGEX.replace(full_command,/\//,"\\")
		IF mdl_form_data.debug_flag > 1 THEN 
			LET full_command="cmd /k ",full_command 
		END IF 
		CALL winexecwait(full_command) RETURNING status 
		IF status = 0 THEN 
			LET status_MESSAGE="Program ",mdl_form_data.program_name clipped," generated successfully. See log in ",log_file 

			CALL fgl_winmessage( "Fast Fourgl Generator",status_MESSAGE, "info" ) 
			CALL print_in_history(exec_time,mdl_form_data.project_name,mdl_form_data.program_name,full_command,log_file) 
		ELSE 
			LET status_MESSAGE="Program ",mdl_form_data.program_name clipped," could NOT be generated. See log in ",log_file 
			CALL fgl_winmessage( "Fast Fourgl Generator(c)",status_MESSAGE, "stop" ) 
		END IF 
		LET arr_size=0 
	ELSE 
		# NOT enough OPTIONS TO run
	END IF 
END FUNCTION 

FUNCTION get_templates_list (p_ffg_dir) 
	DEFINE p_ffg_dir,tmplt_dir,entry STRING 
	DEFINE dir_handle,mdx,fdx,ddx INTEGER 
	DEFINE directory_list DYNAMIC ARRAY OF STRING 
	LET cb_use_main_template = ui.Combobox.ForName("use_main_template") #@g00101 
	LET cb_use_child_template = ui.Combobox.ForName("use_child_template") 
	LET cb_use_grandchild_template = ui.Combobox.ForName("use_grandchild_template") 
	LET cb_use_list_template = ui.Combobox.ForName("use_list_template") 
	LET cb_use_form_template = ui.Combobox.ForName("use_form_template") #@g00101 

	LET tmplt_dir=p_ffg_dir clipped,"\\templates\\module" 
	CALL directory_list.append(tmplt_dir) 
	LET tmplt_dir=p_ffg_dir clipped,"\\templates\\form" 
	CALL directory_list.append(tmplt_dir) 

	FOR ddx = 1 TO 2 
		CALL os.Path.dirsort("name",1)
		CALL os.path.diropen(directory_list[ddx]) RETURNING dir_handle 
		LET entry ="#!%$" 
		LET mdx=0 
		LET fdx=0 

		WHILE entry IS NOT NULL 
			CALL os.path.dirnext(dir_handle) RETURNING entry 
			IF entry matches "*.mtplt" THEN 
				CALL cb_use_main_template.additem(entry) 
				CALL cb_use_child_template.additem(entry) 
				CALL cb_use_grandchild_template.additem(entry) 
				CALL cb_use_list_template.additem(entry) 
				LET mdx=mdx+1 
				LET main_templates[mdx].template = entry 
			END IF 
			IF entry matches "*.ftplt" THEN 
				CALL cb_use_form_template.additem(entry) 
				LET fdx=fdx+1 
				LET form_templates[fdx].template = entry 
			END IF 
		END WHILE 
		LET entry ="#!%$" 
	END FOR 

END FUNCTION 

FUNCTION get_directories_list (p_field_name,p_dir_criteria) 
	DEFINE p_field_name,p_dir_criteria,l_entry STRING 
	DEFINE l_dir_handle INTEGER 
	DEFINE l_dirname,l_base_dir STRING 

	CASE p_field_name 
		WHEN "project_name" 
			LET cb_list_projects = ui.Combobox.ForName("project_name") 
			CALL os.path.diropen(mdl_qx_workspace_dir) RETURNING l_dir_handle 
			CALL os.Path.dirsort("name",1) 
			LET l_base_dir=mdl_qx_workspace_dir 
			CALL cb_list_projects.clear() 
		OTHERWISE 

	END CASE 
	LET l_entry ="#@!^" 
	LET p_dir_criteria = p_dir_criteria clipped,"*" 
	WHILE l_entry IS NOT NULL 
		CALL os.path.dirnext(l_dir_handle) RETURNING l_entry 
		LET l_dirname = l_base_dir,"/",l_entry clipped 
		IF os.path.isdirectory(l_dirname) THEN 
			IF l_entry matches p_dir_criteria THEN 
				#LET l_entry = match_dirpart CLIPPED,l_entry
				CASE p_field_name 
					WHEN "project_name" 
						CALL cb_list_projects.additem(l_entry) 
					OTHERWISE 
				END CASE 
			END IF 
		END IF 
	END WHILE 
	CALL os.path.dirclose(l_dir_handle) 
	LET l_entry ="#!%$" 
END FUNCTION 

FUNCTION get_projects_list (p_field_name,p_dir_criteria) 
	DEFINE p_field_name STRING
	DEFINE p_dir_criteria STRING
	DEFINE l_dir_name STRING 
	DEFINE l_dir_handle INTEGER 
	DEFINE l_entry STRING 
	#LET cb_list_projects = ui.Combobox.ForName("project_name") 
	LET cb_list_projects = ui.Combobox.ForName(p_field_name) 
	CALL os.path.diropen(mdl_qx_workspace_dir) RETURNING l_dir_handle 
	CALL os.Path.dirsort("name",1) 
	CALL cb_list_projects.clear() 
	LET l_entry ="#@!^" 
	WHILE l_entry IS NOT NULL 
		CALL os.path.dirnext(l_dir_handle) RETURNING l_entry 
		IF l_entry[1,1] = "." THEN 
			CONTINUE WHILE 
		END IF 
		LET l_dir_name = mdl_qx_workspace_dir ,"/",l_entry clipped 
		IF os.path.isdirectory(l_dir_name) THEN 
			CALL cb_list_projects.additem(l_entry) 
		END IF 
	END WHILE 
	CALL os.path.dirclose(l_dir_handle) 

END FUNCTION 

FUNCTION get_project_locations(p_project_name) 
	DEFINE p_project_name,l_project_dir,l_file_name STRING 
	DEFINE l_arr_varstring DYNAMIC ARRAY OF STRING 
	LET l_project_dir = mdl_eclipse_project_dir clipped,"/",p_project_name 
	LET l_file_name = mdl_eclipse_project_dir clipped,"/",p_project_name clipped,"/.location" 
	IF os.path.exists(l_file_name) THEN 
		LET mdl_lycia_structure_location=get_lycia_structure_location(l_project_dir) 
	ELSE 
		LET mdl_lycia_structure_location = mdl_qx_workspace_dir clipped,"/",p_project_name 
	END IF 
	LET mdl_project_params_file = mdl_ffg_dir clipped,"/etc/",p_project_name CLIPPED,".params" 
	CALL read_params_file(mdl_project_params_file,"QxPerLocation") 
	CASE 
		WHEN mdl_qx_form_location IS NULL 
			# project has no specific parameters, try mdl_l_project_dir/source
			LET mdl_qx_form_location = mdl_lycia_structure_location,"/source/per" 

		WHEN mdl_qx_form_location matches "*sprintf*" 
			LET l_arr_varstring[1] = "l_project_dir=",mdl_lycia_structure_location 
			LET mdl_qx_form_location=sprintf(mdl_qx_form_location,l_arr_varstring) 
	END CASE 

	CALL read_params_file(mdl_project_params_file,"Qx4glLocation") 
	CASE 
		WHEN mdl_qx_4gl_location IS NULL 
			# project has no specific parameters, try mdl_l_project_dir/source
			LET mdl_qx_4gl_location = mdl_lycia_structure_location,"/source/4gl" 

		WHEN mdl_qx_4gl_location matches "*sprintf*" 
			LET l_arr_varstring[1] = "l_project_dir=",mdl_lycia_structure_location 
			LET mdl_qx_4gl_location=sprintf(mdl_qx_4gl_location,l_arr_varstring) 
	END CASE 
	LET mdl_qx_4gl_location = util.REGEX.replace(mdl_qx_4gl_location,/\/$/,"") 
	RETURN mdl_qx_4gl_location,mdl_qx_form_location 
END FUNCTION 

FUNCTION get_projects_list_2 (field_name,dir_criteria) 
	DEFINE field_name,dir_criteria,entry STRING 
	DEFINE dir_handle INTEGER 
	DEFINE dirname,base_dir STRING 

	CASE field_name 
		WHEN "project_name" 
			LET cb_list_projects = ui.Combobox.ForName("project_name") 
			LET base_dir = mdl_eclipse_project_dir 
			CALL os.path.diropen(base_dir) RETURNING dir_handle 
			CALL os.Path.dirsort("name",1) 
			CALL cb_list_projects.clear() 
		OTHERWISE 

	END CASE 
	LET entry ="#@!^" 
	LET dir_criteria = dir_criteria clipped,"*" 
	WHILE entry IS NOT NULL 
		CALL os.path.dirnext(dir_handle) RETURNING entry 
		LET dirname = base_dir,"/",entry clipped 
		IF os.path.isdirectory(dirname) THEN 
			IF entry matches dir_criteria THEN 
				#LET entry = match_dirpart CLIPPED,entry
				CASE field_name 
					WHEN "project_name" 
						CALL cb_list_projects.additem(entry) 
					OTHERWISE 
				END CASE 
			END IF 
		END IF 
	END WHILE 
	CALL os.path.dirclose(dir_handle) 
	LET entry ="#!%$" 
END FUNCTION 

FUNCTION get_forms_list (field_name,form_criteria) 
	DEFINE form_criteria,form_dir,entry STRING 
	DEFINE field_name STRING 
	DEFINE dir_handle,matching_forms_number INTEGER 
	DEFINE match util.match_results 
	DEFINE match_criteria,match_dirpart STRING 
	CASE field_name 
		WHEN "use_main_form" 
			LET cb_use_main_form = ui.combobox.forname(field_name) 
		WHEN "use_list_form" 
			LET cb_use_list_form = ui.combobox.forname(field_name) 
		WHEN "use_child_form" 
			LET cb_use_child_form = ui.combobox.forname(field_name) 
		WHEN "use_grandchild_form" 
			LET cb_use_grandchild_form = ui.combobox.forname(field_name) 
	END CASE 

	LET match = util.regex.search(form_criteria, /.*\//) 
	LET match_dirpart = match.str(0) 
	IF ( match_dirpart IS NOT NULL ) THEN 
		LET form_dir=mdl_qx_form_location clipped,"/",match_dirpart clipped 
		IF match.suffix() IS NOT NULL THEN 
			LET match_criteria = match.suffix() 
		END IF 

	ELSE 
		LET form_dir=mdl_qx_form_location clipped 
		LET match_criteria=form_criteria 
	END IF 
	# form_dir must be clipped TO be opened successfully
	LET form_dir = util.REGEX.replace(form_dir,/^\/|\/$/,"") 

	#	LET match = util.REGEX.search(match_criteria,/\/(\w+)$/)
	LET match_criteria=match_criteria clipped,"*.fm2" 
	CALL os.path.diropen(form_dir) RETURNING dir_handle 

	CALL os.Path.dirsort("name",1) 
	LET entry ="#@!^" 
	CASE field_name 
		WHEN "use_list_form" 
			CALL cb_use_list_form.clear() 
		WHEN "use_main_form" 
			CALL cb_use_main_form.clear() 
		WHEN "use_child_form" 
			CALL cb_use_child_form.clear() 
		WHEN "use_grandchild_form" 
			CALL cb_use_grandchild_form.clear() 
	END CASE 
	LET matching_forms_number = 0 
	WHILE entry IS NOT NULL 
		CALL os.path.dirnext(dir_handle) RETURNING entry 
		IF entry matches match_criteria THEN 
			LET entry = form_dir CLIPPED,"/",entry 
			LET matching_forms_number = matching_forms_number + 1 
			CASE field_name 
				WHEN "use_list_form" 
					CALL cb_use_list_form.additem(entry) 
				WHEN "use_main_form" 
					CALL cb_use_main_form.additem(entry) 
				WHEN "use_child_form" 
					CALL cb_use_child_form.additem(entry) 
				WHEN "use_grandchild_form" 
					CALL cb_use_child_form.additem(entry) 
			END CASE 
		END IF 

	END WHILE 
	CALL os.path.dirclose(dir_handle) 
	LET entry ="#!%$" 
	RETURN matching_forms_number 
END FUNCTION 

FUNCTION change_workspace() 
	DISPLAY "Change_WorkSpace" 
END FUNCTION 

FUNCTION edit_parameters(file_name) 
	DEFINE file_name, command_line STRING 
	LET command_line = mdl_full_editor_command ," ",mdl_ffg_dir clipped,"/etc/",file_name 
	CALL winexecwait (command_line) 
END FUNCTION 

FUNCTION print_in_history(exec_time,mdl_project_name,mdl_program_name,full_command,log_file) 
	DEFINE exec_time DATETIME year TO second 
	DEFINE full_command,log_file,mdl_project_name,mdl_program_name STRING 
	DEFINE history_file_name STRING 
	DEFINE history base.channel 

	LET history_file_name=mdl_ffg_logdir CLIPPED,"/history.log" 
	LET history = base.channel.create() 
	CALL history.openfile(history_file_name, "a") 
	CALL history.setDelimiter(" ") 
	CALL history.write([exec_time,mdl_project_name,mdl_program_name,full_command,log_file]) 
	CALL history.close() 
END FUNCTION 

FUNCTION viewtemplates (template_class) 
	DEFINE template_class CHAR(6) 

	OPEN WINDOW f_templates with FORM "f_templates" 
	CASE template_class 
		WHEN ".mtplt" 
			DISPLAY ARRAY main_templates TO sr_templates.* ATTRIBUTE(UNBUFFERED) 
			--BEFORE DISPLAY
			--CALL publish_toolbar("kandoo","run_ffg","display_arr-main_templates-1")        -- albo KD-511
			--END DISPLAY
		WHEN ".ftplt" 
			DISPLAY ARRAY form_templates TO sr_templates .* ATTRIBUTE(UNBUFFERED) 
			CALL publish_toolbar("kandoo","run_ffg","display_arr-form_templates-1") -- albo kd-511 
			--END DISPLAY
	END CASE 
	CLOSE WINDOW f_templates 
END FUNCTION 

FUNCTION view_history () 
	DEFINE a_history DYNAMIC ARRAY OF RECORD 
		timestamp string, 
		mdl_project_name string, 
		mdl_program_name string, 
		full_command string, 
		log_file STRING 
	END RECORD 

	DEFINE l_history RECORD 
		timestamp string, 
		mdl_project_name string, 
		mdl_program_name string, 
		full_command string, 
		log_file STRING 
	END RECORD 
	DEFINE history_file_name,gen_command,file_line,status_message,mdl_project_name,mdl_program_name,logfile STRING 
	DEFINE exec_time DATETIME year TO second 
	DEFINE dt_variant variant 
	DEFINE history base.channel 
	DEFINE idx,curr_row,curr_line SMALLINT 
	DEFINE match util.match_results 

	OPEN WINDOW f_history with FORM "f_history" 
	LET history = base.channel.create() 
	LET history_file_name=mdl_ffg_logdir CLIPPED,"/history.log" 
	CALL history.openfile(history_file_name, "r") RETURNING status 
	#CALL history.setDelimiter("	")
	LET idx = 0 
	WHILE true 
		LET file_line = history.readline() 
		#IF history.IsEof() THEN EXIT WHILE END IF
		LET match = util.regex.search(file_line,/(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t/) 
		IF (match) THEN 
			LET idx = idx+1 
			LET a_history[idx].timestamp = match.str(1) 
			LET a_history[idx].mdl_project_name = match.str(2) 
			LET a_history[idx].mdl_program_name = match.str(3) 
			LET a_history[idx].full_command = match.str(4) 
			LET a_history[idx].log_file = match.str(5) 
		END IF 
		IF history.iseof() THEN EXIT WHILE END IF 
		END WHILE 

		INPUT ARRAY a_history WITHOUT DEFAULTS 
		FROM sr_history.* 
		#attributes(count=idx,maxcount=idx)

			ON ACTION ("Redo") 
				LET curr_row = arr_curr() 
				LET curr_line = scr_line() 
				LET gen_command = a_history[curr_row].full_command 
				LET mdl_project_name = a_history[curr_row].mdl_project_name 
				LET mdl_program_name = a_history[curr_row].mdl_program_name 
				LET logfile = a_history[curr_row].log_file 
				LET exec_time = CURRENT 
				LET dt_variant = exec_time 
				LET gen_command = util.regex.replace(gen_command,/\d\d\d\d-\d\d-\d\d@\d\d_\d\d_\d\d/g,dt_variant) 
				LET logfile = util.regex.replace(logfile,/\d\d\d\d-\d\d-\d\d@\d\d_\d\d_\d\d/g,dt_variant) 

				CALL winexecwait(gen_command) RETURNING status 
				IF status = 0 THEN 
					LET status_MESSAGE="Program ",mdl_program_name clipped," generated successfully." 
					CALL fgl_winmessage( "Fast Fourgl Generator",status_MESSAGE, "info" ) 
					CALL print_in_history(exec_time,mdl_project_name,mdl_program_name,gen_command,logfile) 
				ELSE 
					LET status_MESSAGE="Program ",mdl_program_name clipped," could NOT be generated. See log in "#log_file 
					CALL fgl_winmessage( "Fast Fourgl Generator(c)",status_MESSAGE, "stop" ) 
				END IF 

			ON ACTION ("View LogFile") 
				LET curr_row = arr_curr() 

		END INPUT 

		CALL history.close() 
		CLOSE WINDOW f_history 
END FUNCTION 

FUNCTION edit_template (template_name) 
	DEFINE template_name STRING 
	CALL fgl_winmessage( "Edit template", "info" ) 
END FUNCTION # edit_template 


FUNCTION read_params_file(file_name,parameter) 
	DEFINE file_name,parameter STRING 
	DEFINE file_handle base.channel 
	DEFINE rs STRING 
	DEFINE var_name,var_value STRING 
	DEFINE r bool 
	DEFINE regexp,regexp_quotes util.regex 
	DEFINE match util.match_results 
	DEFINE res boolean 
	DEFINE line_contents STRING 
	DEFINE l_arr_varstring DYNAMIC ARRAY OF STRING 
	IF os.path.exists(file_name) THEN 
		LET file_handle = base.channel.create() 
		CALL file_handle.openfile(file_name, "r") 
		IF parameter IS NULL THEN 
			LET regexp = ".*" 
		ELSE 
			LET regexp = parameter 
		END IF 
		#WHILE file_handle.read([line_contents])
		#LET regexp_quotes = /\"/g
		WHILE NOT file_handle.iseof() 
			LET var_name = NULL 
			LET var_value = NULL 
			LET line_contents = file_handle.readline() 
			IF util.regex.search(line_contents,/^\s*#/) THEN 
				LET rs = "" 
				CONTINUE WHILE 
			END IF 
			LET match = util.regex.search(line_contents,regexp) 
			IF ( match ) THEN 
			ELSE 
				CONTINUE WHILE 
			END IF 

			LET match = util.regex.search(line_contents,/\$(\w+)=(.*);/) 
			IF (match) THEN 
				LET var_name = match.str(1) 
				LET var_value = match.str(2) 
				IF var_name <> parameter AND regexp <> ".*" THEN 
					CONTINUE WHILE 
				END IF 
				LET var_value = util.REGEX.replace(var_value,/\\/g,/\//)
				LET var_value = util.REGEX.replace(var_value,/\"/g,"") 
				LET dummy_char ="#" 

				CASE var_name 
					WHEN "PerlExe" 
						LET mdl_perl_exe=var_value 
					WHEN "FFGINCLDIR" 
						LET mdl_ffg_include_dir=var_value 
					WHEN "FFGDATADIR" 
						LET mdl_ffg_data_dir=var_value 
					WHEN "QxWorkSpace" 
						LET mdl_qx_workspace_dir=var_value 
					WHEN "Qx4glLocation" 
						LET mdl_qx_4gl_location = var_value 
					WHEN "QxPerLocation" 
						LET mdl_qx_form_location = var_value 
					WHEN "DatabaseName" 
						LET mdl_form_data.database_name=var_value 
					WHEN "template_editor_exe" 
						LET mdl_template_editor_exe=var_value 
					WHEN "FFGLOGDIR" 
						LET mdl_ffg_logdir=var_value 
					OTHERWISE 
						# parameter NOT supported yet
				END CASE 

				IF (parameter IS NOT NULL AND var_name = parameter ) THEN 
					EXIT WHILE 
				END IF 
			END IF 
			IF file_handle.iseof() THEN 
				EXIT WHILE 
			END IF 
		END WHILE 
		CALL file_handle.close() 
	END IF 
END FUNCTION 		# read_params_file

FUNCTION sprintf (string_value,vars_and_values)
# This function simulates the behaviour of C/Perl function sprintf 
	DEFINE vars_and_values DYNAMIC ARRAY OF STRING 
	DEFINE string_value,expression_to_complete,result,exp_to_replace,replaced_exp,replace_varname,constant_txt,replace_value,var_name STRING 
	DEFINE match util.match_results 
	DEFINE reg_exp util.regex 
	DEFINE idx,mylength SMALLINT 
	DEFINE result0 CHAR(256) 
	LET idx=1 
	LET result=string_value 

	WHILE util.regex.search(result,/%[sd]/) 
		LET match = util.regex.search(vars_and_values[idx],/(.*)=(.*)/) 
		LET replace_varname=match.str(1) clipped 
		LET replace_value=match.str(2) clipped 
		LET match = util.regex.search(result,/sprintf.*(%[sd])(.*),\$(\w+)/) 
		LET result = util.regex.replace(result,/\%[sd]/,replace_value) 
		LET idx=idx+1 
	END WHILE 
	LET result = util.regex.replace(result,/sprintf\s*/,//) 
	LET result = util.regex.replace(result,/,.*$/,//) 
	RETURN result 
END FUNCTION   # sprintf


FUNCTION get_lycia_structure_location(p_dir_name) 
	DEFINE p_dir_name,command STRING 
	DEFINE l_file_name STRING  
	DEFINE l_file_handle base.channel 
	DEFINE l_regexp util.regex 
	DEFINE l_match_result util.match_results 
	DEFINE l_line_contents STRING 
	DEFINE l_length SMALLINT 
	LET l_file_name=p_dir_name CLIPPED,"/.location" 
	LET l_file_handle = base.channel.create() 
	IF os.path.exists(l_file_name) THEN 
		# The source IS declared in the .location file
		CALL l_file_handle.openfile(l_file_name, "rb") 
		WHILE l_file_handle.read(l_line_contents) 
			# Watch out: read can read trashy characters that corrupt strings AND chars, thus very restrictive reg exp below
			LET l_match_result = util.regex.search(l_line_contents,/file:\/([:\w\/\-]+)/) 
			IF l_match_result.str(1) IS NOT NULL THEN 
				LET mdl_lyciaprojectdir = l_match_result.str(1) 
				#LET l_length = l_lengthgth(mdl_lyciaprojectdir) #linker warning... function does not exist.. looks like a variable name
				LET l_length = mdl_lyciaprojectdir.getLength() #guess, it wants to know it's length
				EXIT WHILE 
			END IF 
		END WHILE 
	ELSE 
		#LET mdl_lyciaprojectdir
	END IF 
	CALL l_file_handle.close() 
	RETURN mdl_lyciaprojectdir 
END FUNCTION 

FUNCTION view_form (form_name,relative_name) 
	DEFINE form_name,relative_name STRING 
	DEFINE testw ui.window 
	DEFINE testf ui.form 
	DEFINE rep boolean 
	DEFINE reply STRING 
	#CALL testw.OpenWithForm("testWindow", form_name, 3, 5, "border, form-line:4")

	OPEN WINDOW form_check with FORM form_name attribute(border) 
	OPTIONS MENU line 3, 
	FORM line 2 


	CALL DIALOG.SetActionHidden("Cancel", false) 
	CALL DIALOG.SetActionHidden("Accept", false) 
	LET reply = fgl_winprompt(5,5, "Is this the right form", "Yes", 3, 0)
	# CALL doneprompt(null,null,null) 
	#LET reply = "Yes" 
	CASE 
		WHEN reply matches "Y*" 
			LET rep = true 
		WHEN reply matches "N*" 
			LET rep = false 
	END CASE 
	CLOSE WINDOW form_check 
	RETURN rep 
END FUNCTION 

FUNCTION get_tables_list(form_name) 
	DEFINE form_name STRING 
	DEFINE formfile base.channel 
	DEFINE regexp util.regex 
	DEFINE match util.match_results 
	DEFINE idx,curr_row,curr_line SMALLINT 
	DEFINE form_line STRING 

	#OPEN WINDOW f_tables_list WITH FORM "f_tables_list"
	LET formfile = base.channel.create() 
	CALL formfile.openfile(form_name, "r") RETURNING status 
	#CALL history.setDelimiter("	")

	LET idx=1 

	WHILE formfile.read ([form_line]) 
		LET match = util.regex.search(form_line,/screenrecord identifier=\"(\w+)\"/) 
		LET idx = idx+1 
	END WHILE 

	LET idx=idx-1 

	CALL formfile.close() #huho NOT my code but there were missing braces FOR this CLOSE FUNCTION - did add them 

END FUNCTION 

