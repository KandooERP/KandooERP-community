############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../../common/glob_GLOBALS.4gl"
#GLOBALS "_qxt_globs.4gl"

	DEFINE t_qxt_arrToolbarRec TYPE AS RECORD
#		tb_proj_id VARCHAR(30),
		tb_module_id LIKE qxt_toolbar.tb_module_id,
		tb_menu_id  LIKE qxt_toolbar.tb_menu_id,
		tb_action  LIKE qxt_toolbar.tb_action,
		tb_label  LIKE qxt_toolbar.tb_label,
		tb_icon  LIKE qxt_toolbar.tb_icon,
		tb_position  LIKE qxt_toolbar.tb_position,
		tb_place LIKE qxt_toolbar.tb_place, -- button location on toolbar or in tb dropdown menu
		tb_static  LIKE qxt_toolbar.tb_static, --BOOLEAN,
#		tb_tooltip  LIKE qxt_toolbar.tb_tooltip,
		tb_type  LIKE qxt_toolbar.tb_type, --0=button 1=divider--BOOLEAN,  --TRUE = seperator pipe (NOT a button)
		tb_scope  LIKE qxt_toolbar.tb_scope, --0=dialog 1=global --BOOLEAN,  --scope  TRUE IS dialog
		tb_hide  LIKE qxt_toolbar.tb_hide, --0=visible 1=hide/remove --BOOLEAN,  --TRUE will delete that button - FALSE will SET it
		tb_category LIKE qxt_toolbar.tb_category  --TO group/search FOR toolbar button categories
#		tb_mod_user LIKE qxt_toolbar.tb_mod_user,  --user last modified this record
#		tb_mod_date LIKE qxt_toolbar.tb_mod_date  --dateTime WHEN last modified this record
	END RECORD
	DEFINE t_qxt_arrToolbarTemplateRec TYPE AS RECORD
		tb_check SMALLINT,
		#tb_proj_id VARCHAR(30),
		#tb_module_id LIKE qxt_toolbar.tb_module_id,
		#tb_menu_id  LIKE qxt_toolbar.tb_menu_id,
		tb_action  LIKE qxt_toolbar.tb_action,
		tb_label  LIKE qxt_toolbar.tb_label,
		tb_icon  LIKE qxt_toolbar.tb_icon,
		tb_position  LIKE qxt_toolbar.tb_position,
		tb_static  LIKE qxt_toolbar.tb_static, --BOOLEAN,
		tb_tooltip  LIKE qxt_toolbar.tb_tooltip,
		tb_type  LIKE qxt_toolbar.tb_type, --0=button 1=divider--BOOLEAN,  --TRUE = seperator pipe (NOT a button)
		tb_scope  LIKE qxt_toolbar.tb_scope, --0=dialog 1=global --BOOLEAN,  --scope  TRUE IS dialog
		tb_hide  LIKE qxt_toolbar.tb_hide, --0=visible 1=hide/remove --BOOLEAN,  --TRUE will delete that button - FALSE will SET it
		tb_key  LIKE qxt_toolbar.tb_key, --Accellerator Key
		tb_category LIKE qxt_toolbar.tb_category  --TO group/search FOR toolbar button categories
#		tb_mod_user LIKE qxt_toolbar.tb_mod_user,  --user last modified this record
#		tb_mod_date LIKE qxt_toolbar.tb_mod_date  --dateTime WHEN last modified this record
	END RECORD
	DEFINE modu_rec_filterRecord RECORD
		filterProjectName LIKE qxt_toolbar.tb_proj_id,
		filterModuleSwitch BOOLEAN,
		filterModuleName LIKE qxt_toolbar.tb_module_id,
		filterMenuIDSwitch BOOLEAN, 
		filterMenuId LIKE qxt_toolbar.tb_menu_id
	END RECORD
	DEFINE modu_arr_rec_toolbar DYNAMIC ARRAY OF t_qxt_arrToolbarRec  -- RECORD LIKE  qxt_toolbar.*
	DEFINE modu_arr_rec_toolbar_copy DYNAMIC ARRAY OF t_qxt_arrToolbarRec  -- RECORD LIKE  qxt_toolbar.*
	DEFINE modu_rec_qxt_toolbar RECORD LIKE qxt_toolbar.*
	DEFINE modu_arr_rec_qxt_toolbar_template DYNAMIC ARRAY OF t_qxt_arrToolbarTemplateRec
#	DEFINE ProjectName LIKE qxt_toolbar.tb_proj_id
	DEFINE modu_arr_tb_proj_id DYNAMIC ARRAY OF LIKE qxt_toolbar.tb_proj_id
	DEFINE modu_arr_tb_module_id DYNAMIC ARRAY OF LIKE qxt_toolbar.tb_module_id
	DEFINE modu_arr_tb_menu_id DYNAMIC ARRAY OF LIKE qxt_toolbar.tb_menu_id
	DEFINE modu_arr_tb_action DYNAMIC ARRAY OF LIKE qxt_toolbar.tb_action
	DEFINE modu_arr_tb_icon DYNAMIC ARRAY OF LIKE qxt_toolbar.tb_icon
	DEFINE modu_arr_tb_category DYNAMIC ARRAY OF LIKE qxt_toolbar.tb_category
	DEFINE modu_countProjects SMALLINT
	DEFINE modu_countModules SMALLINT
	DEFINE modu_countMenus SMALLINT
#	DEFINE tb_ic_arr DYNAMIC ARRAY OF RECORD LIKE qxt_tb_icon.*
	DEFINE modu_defaultProjectId LIKE qxt_toolbar.tb_proj_id
	DEFINE modu_defaultModuleId LIKE qxt_toolbar.tb_module_id
	DEFINE modu_defaultMenuId LIKE qxt_toolbar.tb_menu_id
	DEFINE modu_tb_user_name CHAR(4)



#########################################################################
# MAIN
#
#
#########################################################################
MAIN
	DEFINE i, a_idx, s_idx, cnt INT
	DEFINE l_cbx_filterProjectName ui.ComboBox
	DEFINE l_cbx_filterModuleName ui.ComboBox
	DEFINE l_cbx_filterMenuId ui.ComboBox
	DEFINE l_exitWhile BOOLEAN
--	DEFINE l_cnt_del SMALLINT
--	DEFINE l_cnt_ins SMALLINT
	DEFINE l_msgStr STRING	
	DEFINE l_rec_temp_toolbar RECORD LIKE qxt_toolbar.*
	DEFINE l_srch_pat STRING
	DEFINE l_curr_arr_idx, l_curr_scr_idx SMALLINT
	DEFINE x SMALLINT
--	DEFINE l_yes_no CHAR(10)
	DEFINE l_ret SMALLINT
	DEFINE l_iconPreviewURI STRING  --FOR icon preview - need TO add context/
--	DEFINE l_dataSetState SMALLINT  -- -1=too large, keep existing/old data SET   0= nothing found   >0 = number of found rows (count*)

	IF get_debug() THEN
		FOR i = 1 to num_args()
			DISPLAY "arg_val(", trim(i), ")=", arg_val(i)
		END FOR
	END IF
	
	CALL setModuleId("qxt_toolbar2_manager")
	CALL ui_init(1)	#Initial UI Init for external kandoo tools like toolbar manager

	DEFER QUIT
	DEFER INTERRUPT
	CALL authenticate(getModuleId()) #authenticate
	WHENEVER ERROR STOP
#	WHENEVER ERROR CONTINUE  --let's be optimistic until it's in working ORDER
	OPTIONS INPUT WRAP
	OPTIONS ACCEPT KEY RETURN


	LET l_exitWhile = FALSE
	LET modu_defaultProjectId = "kandoo"
	LET modu_defaultModuleId = "global"
	LET modu_defaultMenuId = "global"
	
{	
#********************************************* why is this done now ? we did not process the modu_rec_filterRecord.* record yet *********************
	#IF no module name OR menuId IS specified in the program CALL (arg), turn filters off - OTHERWISE on

	#Module Name (program) i.e. A15
	IF modu_rec_filterRecord.filterModuleName IS NOT NULL THEN
		LET modu_rec_filterRecord.filterModuleSwitch = TRUE
	ELSE
		LET modu_rec_filterRecord.filterModuleSwitch = FALSE
	END IF
	#Menu ID  - unique id for each dialog block
	IF modu_rec_filterRecord.filterMenuId IS NOT NULL THEN
		LET modu_rec_filterRecord.filterMenuIDSwitch = TRUE
	ELSE
		LET modu_rec_filterRecord.filterMenuIDSwitch = FALSE
	END IF
	
	#project name i.e. kandoo
--	IF NOT exist_ProjectName(modu_rec_filterRecord.filterProjectName) THEN
--		LET modu_rec_filterRecord.filterProjectName = modu_defaultProjectId
--	END IF
	IF NOT exist_ProjectName(modu_rec_filterRecord.filterModuleName) THEN
		LET modu_rec_filterRecord.filterModuleName = modu_defaultModuleId
		LET modu_rec_filterRecord.filterMenuId = modu_defaultMenuId
	END IF
	#IF projectID was NOT specifed as a program argument, prompt the user TO specify it
}

{
	IF NUM_ARGS() > 0 THEN
		FOR i = 1 TO NUM_ARGS() -1
			CASE ARG_VAL(i) 
				WHEN "-#project"
					LET i = i+1
					LET modu_rec_filterRecord.filterProjectName = ARG_VAL(i)
				WHEN "-#module"
					LET i = i+1
					LET modu_rec_filterRecord.filterModuleName = ARG_VAL(i)
					LET modu_rec_filterRecord.filterModuleSwitch = TRUE
				WHEN "-#menu"
					LET i = i+1
					LET modu_rec_filterRecord.filterMenuId = ARG_VAL(i)
					LET modu_rec_filterRecord.filterMenuIDSwitch = TRUE
				WHEN "-#user"
					LET i = i+1
					LET modu_tb_user_name = ARG_VAL(i)
			END CASE
		END FOR
	END IF
}

#TB_PROJECT_NAME
#TB_MODULE_NAME
#TB_MENU_NAME
#TB_USER_NAME

	#Populate modu_rec_filterRecord with data provided in environment, url, etc..
	LET modu_rec_filterRecord.filterProjectName = get_url_tb_project_name()
	LET modu_rec_filterRecord.filterModuleName = get_url_tb_module_name()
	LET modu_rec_filterRecord.filterMenuId = get_url_tb_menu_name()
	
	LET modu_tb_user_name= get_url_tb_user_name()

	IF get_debug() THEN
		DISPLAY "modu_rec_filterRecord.filterProjectName=",trim(modu_rec_filterRecord.filterProjectName)
		DISPLAY "modu_rec_filterRecord.filterModuleName=",trim(modu_rec_filterRecord.filterModuleName)
		DISPLAY "modu_rec_filterRecord.filterMenuId=",trim(modu_rec_filterRecord.filterMenuId)
		DISPLAY "modu_tb_user_name=",trim(modu_tb_user_name) 
	END IF
	
	#Project Name i.e. kandoo: Validate and initialize filter
	IF modu_rec_filterRecord.filterProjectName IS NOT NULL THEN
		#Module (Program) Name i.e. A11: Validate and initialize filter
		IF modu_rec_filterRecord.filterModuleName IS NOT NULL THEN
			LET modu_rec_filterRecord.filterModuleSwitch = TRUE
		ELSE
			LET modu_rec_filterRecord.filterModuleSwitch = FALSE
		END IF

		#Menu Id/Name unique dialog block identifier embedded in code:  Validate and initialize filter
		IF modu_rec_filterRecord.filterMenuId IS NOT NULL THEN
			LET modu_rec_filterRecord.filterMenuIDSwitch = TRUE 
		ELSE
			LET modu_rec_filterRecord.filterMenuIDSwitch = FALSE 
		END IF

	ELSE
		LET modu_rec_filterRecord.filterProjectName = modu_defaultProjectId 
	END IF
	

	IF get_debug() THEN
		DISPLAY "modu_rec_filterRecord.filterModuleSwitch=",trim(modu_rec_filterRecord.filterModuleSwitch)
		DISPLAY "modu_rec_filterRecord.filterMenuIDSwitch=",trim(modu_rec_filterRecord.filterMenuIDSwitch)
		DISPLAY "modu_tb_user_name=",trim(modu_tb_user_name) 
	END IF

	IF modu_tb_user_name IS NULL THEN
		LET modu_tb_user_name = "????" 
	END IF

	
--	IF modu_rec_filterRecord.filterProjectName IS NULL THEN
--		LET modu_rec_filterRecord.filterProjectName = modu_defaultProjectId
--	END IF
--
--	IF modu_rec_filterRecord.filterModuleName IS NULL THEN
--		LET modu_rec_filterRecord.filterModuleSwitch = FALSE   --Name = "U12"
--	ELSE
--		LET modu_rec_filterRecord.filterModuleSwitch = TRUE
--	END IF


	#-----------------------------------------------------------------------
	#Login
	#-----------------------------------------------------------------------
	IF modu_tb_user_name  IS NULL AND modu_rec_filterRecord.filterProjectName  IS NULL THEN

	OPEN WINDOW wLogin WITH FORM "form/toolbar/_qxt_toolbar2_manager_login" ATTRIBUTES(BORDER, STYLE="CENTER")

		INPUT modu_rec_filterRecord.filterProjectName, modu_tb_user_name WITHOUT DEFAULTS FROM filterProjectName, tb_user_name
			BEFORE INPUT
				CALL fgl_dialog_setkeylabel("ACCEPT","Login","{CONTEXT}/public/querix/icon/svg/24/ok_button.png")
				CALL fgl_dialog_setkeylabel("CANCEL","Exit", "{CONTEXT}/public/querix/icon/svg/24/button_on_off_blue.png")

			AFTER INPUT
				IF modu_rec_filterRecord.filterProjectName IS NULL OR modu_tb_user_name IS NULL THEN  --details MUST be specified
					ERROR "UserName AND ProjectName must be specified TO continue"
					CONTINUE INPUT
				END IF
		END INPUT

		CLOSE WINDOW wLogin
# END Login
	END IF

	LET int_flag = FALSE
	OPEN WINDOW wToolbarList WITH FORM "form/toolbar/_qxt_toolbar2_manager"  --ATTRIBUTES(BORDER)
	CALL refreshChangingComboBoxes()


	LET l_cbx_filterProjectName = ui.ComboBox.forName("filterProjectName")
	LET l_cbx_filterModuleName = ui.ComboBox.forName("filterModuleName")
	LET l_cbx_filterMenuId = ui.ComboBox.forName("filterMenuId")

--	#1st init 3 major comboBoxes to identify the corresponding menu (3 PK)
--	CALL refreshComboBoxes_filter()
--	 
--	DISPLAY modu_countProjects TO countProjects 
--	DISPLAY modu_countModules TO countModules
--	DISPLAY modu_countMenus TO countMenus

# WHILE BEGIN ######################################################################
	WHILE l_exitWhile = FALSE
		IF get_datasource_toolbar_arr() <> -1 THEN  --get data FROM DB
--			#??? 2nd init 3 major comboBoxes to identify the corresponding menu (3 PK)
--			LET modu_countProjects =  initCombo_projName("filterProjectName")
--			LET modu_countModules =  initCombo_moduleId("filterModuleName")
--			LET modu_countMenus =  initCombo_menuId("filterMenuId")

--			CALL refreshChangingComboBoxes()  #duplicate call
			#1st init 3 major comboBoxes to identify the corresponding menu (3 PK)
			CALL refreshComboBoxes_filter()
			# Screen Update FOR counts
--			DISPLAY modu_countProjects TO countProjects
--			DISPLAY modu_countModules TO countModules
--			DISPLAY modu_countMenus TO countMenus
--			LET l_dialog_touched = FALSE
			IF modu_arr_rec_toolbar.getSize() > 0 THEN
				LET l_curr_arr_idx = 1  --needs TO be done because BEFORE ROW will only be processed AFTER the user clicks on the DISPLAY ARRAY (focus)
				CALL getToolbarRecord(modu_rec_filterRecord.filterProjectName,  --modu_arr_rec_toolbar[l_curr_arr_idx].tb_proj_id, 
									modu_arr_rec_toolbar[l_curr_arr_idx].tb_module_id, 
									modu_arr_rec_toolbar[l_curr_arr_idx].tb_menu_id, 
									modu_arr_rec_toolbar[l_curr_arr_idx].tb_action)
					RETURNING modu_rec_qxt_toolbar.*
# Initial icon preview image UPDATE
				LET l_iconPreviewURI = fgl_getenv("TOOLBAR_PATH"), trim(modu_rec_qxt_toolbar.tb_icon)
				DISPLAY l_iconPreviewURI TO tb_icon_url
				DISPLAY l_iconPreviewURI TO iconPreview ATTRIBUTE(BLUE,REVERSE)
			END IF
		END IF
		
		
		
		
# DIALOG BLOCK BEGIN ##############################################################################
		DIALOG ATTRIBUTES (UNBUFFERED)

#--- INPUT Filter----------------------------------------------------------------------------------
# INPUT FOR Filters
			INPUT BY NAME modu_rec_filterRecord.* WITHOUT DEFAULTS
				BEFORE INPUT
					CALL ui.interface.refresh()
--				CALL fgl_dialog_setkeylabel("ACCEPT","AC1")
--				CALL fgl_dialog_setkeylabel("CANCEL","CA1")
--				CALL fgl_dialog_setkeylabel("EDIT","ED1")
--				CALL fgl_dialog_setkeylabel("EXIT","EX1")

				#ON CHANGE modu_rec_filterRecord.filterProjectSwitch
				ON CHANGE filterProjectSwitch
					EXIT DIALOG
				#ON CHANGE modu_rec_filterRecord.filterModuleSwitch
				ON CHANGE filterModuleSwitch
					EXIT DIALOG
				#ON CHANGE modu_rec_filterRecord.filterMenuIDSwitch
				ON CHANGE filterMenuIDSwitch
					EXIT DIALOG
				#ON CHANGE modu_rec_filterRecord.filterModuleName
				ON CHANGE filterModuleName
					IF modu_rec_filterRecord.filterModuleName IS NOT NULL THEN
						LET modu_rec_filterRecord.filterModuleSwitch = 1
					ELSE
						LET modu_rec_filterRecord.filterModuleSwitch = 0
					END IF
					EXIT DIALOG
				#ON CHANGE modu_rec_filterRecord.filterProjectName
				ON CHANGE filterProjectName
					EXIT DIALOG
				#ON CHANGE modu_rec_filterRecord.filterMenuId
				ON CHANGE filterMenuId
					IF modu_rec_filterRecord.filterMenuId IS NOT NULL THEN
						LET modu_rec_filterRecord.filterMenuIDSwitch = 1
					ELSE
						LET modu_rec_filterRecord.filterMenuIDSwitch = 0
					END IF
					EXIT DIALOG
			END INPUT

#--- DISPLAY ARRAY----------------------------------------------------------------------------------
			#DISPLAY ARRAY ####################################
			DISPLAY ARRAY modu_arr_rec_toolbar TO qxt_toolbar_sc.*
--			BEFORE DISPLAY 
--				CALL fgl_dialog_setkeylabel("ACCEPT","AC2")
--				CALL fgl_dialog_setkeylabel("CANCEL","CA2")
--				CALL fgl_dialog_setkeylabel("EDIT","ED2")
--				CALL fgl_dialog_setkeylabel("EXIT","EX2")

				BEFORE ROW


					LET l_curr_arr_idx = arr_curr()
					#LET l_curr_scr_idx = scr_line()
					CALL getToolbarRecord(modu_rec_filterRecord.filterProjectName, --modu_arr_rec_toolbar[l_curr_arr_idx].tb_proj_id, 
										modu_arr_rec_toolbar[l_curr_arr_idx].tb_module_id, 
										modu_arr_rec_toolbar[l_curr_arr_idx].tb_menu_id, 
										modu_arr_rec_toolbar[l_curr_arr_idx].tb_action)
						RETURNING modu_rec_qxt_toolbar.*
					#DISPLAY modu_rec_qxt_toolbar.* TO qxt_toolbarInput.*
					LET l_iconPreviewURI = fgl_getenv("TOOLBAR_PATH"), trim(modu_rec_qxt_toolbar.tb_icon)
					DISPLAY l_iconPreviewURI TO tb_icon_url
					DISPLAY l_iconPreviewURI TO iconPreview ATTRIBUTE(BLUE,REVERSE)
			END DISPLAY


#--- INPUT current toolbar record --------------------------------------------------------------------------
			#INPUT FOR RECORD Editor BEGIN #######
			INPUT BY NAME modu_rec_qxt_toolbar.* WITHOUT DEFAULTS --FROM qxt_toolbarInput.*
				BEFORE INPUT
--				CALL fgl_dialog_setkeylabel("ACCEPT","AC1")
--				CALL fgl_dialog_setkeylabel("CANCEL","CA1")
--				CALL fgl_dialog_setkeylabel("EDIT","ED1")
--				CALL fgl_dialog_setkeylabel("EXIT","EX1")				
				#	CALL ui.interface.refresh()
				ON CHANGE tb_icon  --icon preview UPDATE (base/root location URI will be added prior)
					LET l_iconPreviewURI = fgl_getenv("TOOLBAR_PATH"), trim(modu_rec_qxt_toolbar.tb_icon)
					DISPLAY l_iconPreviewURI TO tb_icon_url
					DISPLAY l_iconPreviewURI TO iconPreview ATTRIBUTE(BLUE,REVERSE)
			END INPUT
# INPUT FOR RECORD Editor END #######



#--- DIALOG EVENTS--------------------------------------------------------------------------


		ON ACTION "ACCEPT"
# ACCEPT DIALOG #FOR what do I need this again
			LET l_ret = saveRecord(l_curr_arr_idx)
			IF l_ret = 1 THEN --EXIT DIALOG  --need TO EXIT dialog TO refresh/UPDATE all comboBoxes with possible changed VALUES/entries
				EXIT DIALOG
			END IF
# Save RECORD ###################################
--		ON ACTION "Save"
--			LET l_ret = saveRecord(l_curr_arr_idx)
--			IF l_ret = 1 THEN --EXIT DIALOG  --need TO EXIT dialog TO refresh/UPDATE all comboBoxes with possible changed VALUES/entries
--				EXIT DIALOG
--			END IF

# Exit AND restart Dialog  --NOT required really.. refresh
		ON ACTION "CANCEL"
			LET l_exitWhile = TRUE
			EXIT DIALOG
			#EXIT PROGRAM
--		ON ACTION "Exit"
--			EXIT WHILE
--		#Exit dialog TO refresh (db query) program ARRAY AND lookups

		ON ACTION "Refresh"
			EXIT DIALOG  -- Dialog block IS within a WHILE loop TO refresh/UPDATE all combo lookups	

		ON ACTION "Template"
			CALL templateMenu()
			EXIT DIALOG

		ON ACTION "CopyTb"
			CALL copyToolbar()
			CALL refreshCopyToolbarComboBoxes()
# Not done yet
		#ON ACTION "Choose Icon"
		#	LET modu_rec_qxt_toolbar.tb_icon = getIconUrl()
# Delete RECORD ###################################

--		ON ACTION "DELETE"
--			LET l_ret = deleteRecord(l_curr_arr_idx)
--			IF l_ret = 1 THEN --EXIT DIALOG  --need TO EXIT dialog TO refresh/UPDATE all comboBoxes with possible changed VALUES/entries
--				EXIT DIALOG
--			END IF
		ON ACTION "DELETE_RECORD"
			LET l_ret = deleteRecord(l_curr_arr_idx)
			IF l_ret = 1 THEN --EXIT DIALOG  --need TO EXIT dialog TO refresh/UPDATE all comboBoxes with possible changed VALUES/entries
				EXIT DIALOG
			END IF
#		ON KEY (delete)
#			LET l_ret = deleteRecord(l_curr_arr_idx)
#			IF l_ret = 1 THEN --EXIT DIALOG  --need TO EXIT dialog TO refresh/UPDATE all comboBoxes with possible changed VALUES/entries
#				EXIT DIALOG
#			END IF	

		ON ACTION "Export"
			UNLOAD TO "unl/qxt_toolbar.unl" SELECT * FROM qxt_toolbar WHERE tb_proj_id = 'kandoo' ORDER BY tb_module_id,tb_menu_id,tb_action

		ON ACTION "Import"
			CALL importToolbarUnl()
			
		BEFORE DIALOG
			CALL fgl_dialog_setkeylabel("Template","Template","{CONTEXT}/public/querix/icon/svg/24/ic_library_books_24px.svg",7)
			CALL fgl_dialog_setkeylabel("CopyTb","Copy Tb","{CONTEXT}/public/querix/icon/svg/24/ic_content_copy_24px.svg",8)
--			CALL refreshComboBoxes_filter()
--	CALL fgl_setkeylabel("Choose Icon","","")
--	#CALL fgl_setkeylabel("Delete","")
--	#CALL fgl_setkeylabel("EXIT","Exit","{CONTEXT}/public/querix/icon/svg/24/ic_cancel_24px.svg",1)
--	#CALL fgl_setkeylabel("SAVE","Save Record","{CONTEXT}/public/querix/icon/svg/24/ic_done_24px.svg",1)
--	#CALL fgl_setkeylabel("Delete Record","Delete","{CONTEXT}/public/querix/icon/svg/24/ic_delete_24px.svg",2)
--	#CALL fgl_setkeylabel("Refresh","Refresh","{CONTEXT}/public/querix/icon/svg/24/ic_refresh_24px.svg",3)
--	CALL fgl_setkeylabel("Export","Export","{CONTEXT}/public/querix/icon/svg/24/ic_cloud_upload_24px.svg",4)
--	CALL fgl_setkeylabel("Import","Import","{CONTEXT}/public/querix/icon/svg/24/ic_cloud_download_24px.svg",5)

			  ON ACTION "WEB-HELP"
			CALL onlineHelp("A11",NULL)
			
	END DIALOG
# DIALOG BLOCK END ##############################################################################
END WHILE
#WHENEVER ERROR STOP  --let's be optimistic until it's in working ORDER

END MAIN

#########################################################################


#########################################################################
# FUNCTION copyToolbar()
#
#
#########################################################################
FUNCTION copyToolbar()
	DEFINE i SMALLINT
	DEFINE copyParameterRec RECORD
		source_tb_module_id LIKE qxt_toolbar.tb_module_id,
		source_tb_menu_id LIKE qxt_toolbar.tb_menu_id,
		target_tb_module_id LIKE qxt_toolbar.tb_module_id,
		target_tb_menu_id LIKE qxt_toolbar.tb_menu_id
	END RECORD
	#DEFINE menuId LIKE qxt_toolbar.tb_menu_id
	DEFINE l_rec_temp_toolbar RECORD LIKE qxt_toolbar.*

	LET copyParameterRec.source_tb_module_id =modu_rec_filterRecord.filterModuleName
	LET copyParameterRec.source_tb_menu_id =modu_rec_filterRecord.filterMenuId
	LET i = 0

	OPEN WINDOW wCopyToolbar WITH FORM "form/toolbar/_qxt_toolbar2_manager_copy_tb" ATTRIBUTE(border,STYLE="center")
	CALL refreshCopyToolbarComboBoxes()
	#CALL initCombo_moduleId("source_tb_module_id")
	#CALL initCombo_menuId("source_tb_menu_id")
	#CALL initCombo_moduleId("target_tb_module_id")
	#CALL initCombo_menuId("target_tb_menu_id")
		
	WHILE copyParameterRec.target_tb_module_id IS NULL OR copyParameterRec.target_tb_menu_id
		INPUT BY NAME copyParameterRec.* WITHOUT DEFAULTS ATTRIBUTES(UNBUFFERED)
		
			AFTER INPUT
				IF copyParameterRec.source_tb_module_id IS NULL THEN
					ERROR "You need TO specify the source Module/Program ID"
					CONTINUE INPUT
				END IF	
				IF copyParameterRec.source_tb_menu_id IS NULL THEN
					ERROR "You need TO specify the source Menu ID"
					CONTINUE INPUT
				END IF	
				IF copyParameterRec.target_tb_module_id IS NULL THEN
					ERROR "You need TO specify the target Module/Program ID"
					CONTINUE INPUT
				END IF	
				IF copyParameterRec.target_tb_menu_id IS NULL THEN
					ERROR "You need TO specify the target Menu ID"
					CONTINUE INPUT
				END IF	
				
				EXIT WHILE
		
			ON ACTION "CANCEL"
				CLOSE WINDOW wCopyToolbar
				RETURN 0
		END INPUT	
	END WHILE
	

	LET i = 1

	CALL getDataCopy(modu_rec_filterRecord.filterProjectName,copyParameterRec.source_tb_module_id, copyParameterRec.source_tb_menu_id)  --get data FROM DB


	FOR i = 1 TO modu_arr_rec_toolbar_copy.getSize()  -- FOR all elements of the toolbar array
	
		CALL getToolbarRecord(modu_rec_filterRecord.filterProjectName,  --modu_arr_rec_toolbar[l_curr_arr_idx].tb_proj_id, 
													modu_arr_rec_toolbar_copy[i].tb_module_id, 
													modu_arr_rec_toolbar_copy[i].tb_menu_id, 
													modu_arr_rec_toolbar_copy[i].tb_action)
				RETURNING l_rec_temp_toolbar.*
		
		LET l_rec_temp_toolbar.tb_module_id = trim(copyParameterRec.target_tb_module_id)
		LET l_rec_temp_toolbar.tb_menu_id = trim(copyParameterRec.target_tb_menu_id)


			IF tb_count(l_rec_temp_toolbar.tb_proj_id,l_rec_temp_toolbar.tb_module_id,l_rec_temp_toolbar.tb_menu_id,l_rec_temp_toolbar.tb_action) = 0 THEN

	
					INSERT INTO qxt_toolbar VALUES(
						l_rec_temp_toolbar.tb_proj_id,
						l_rec_temp_toolbar.tb_module_id,
						l_rec_temp_toolbar.tb_menu_id,
						l_rec_temp_toolbar.tb_action,
						l_rec_temp_toolbar.tb_label,
						l_rec_temp_toolbar.tb_icon,
						l_rec_temp_toolbar.tb_position,
						l_rec_temp_toolbar.tb_static,
						l_rec_temp_toolbar.tb_tooltip,
						l_rec_temp_toolbar.tb_type,
						l_rec_temp_toolbar.tb_scope,
						l_rec_temp_toolbar.tb_hide,
						l_rec_temp_toolbar.tb_key,
						l_rec_temp_toolbar.tb_category,
						modu_tb_user_name,
						CURRENT YEAR TO SECOND  
						)

				CALL refreshChangingComboBoxes()
			END IF



	END FOR


	CLOSE WINDOW wCopyToolbar

END FUNCTION
#########################################################################
# END FUNCTION copyToolbar()
#########################################################################


#########################################################################
# FUNCTION templateMenu()
#
#
#########################################################################
FUNCTION templateMenu()
	DEFINE i SMALLINT
	DEFINE l_tb_module_id LIKE qxt_toolbar.tb_module_id
	DEFINE l_tb_menu_id LIKE qxt_toolbar.tb_menu_id

	LET i = 0

	########## Main section i.e. ACCEPT AND Cancel ################	
	
	#CANCEL -------------------------------------------------------------------	
	
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "CANCEL"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Cancel"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_cancel_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 01
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Cancel current operation"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	
	
	
	#CANCEL / Exit / Home
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "CANCEL"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Home"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_home_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 01
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Exit Module"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	



	#CANCEL - Previous
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "CANCEL"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Previous"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_navigate_previous_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 01
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Previous Step"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	

	#CANCEL - Back / Return
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "CANCEL"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Back"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_return-back_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 01
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Back TO previous"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	



	#ACCEPT ----------------------------------------------------------------------

	#ACCEPT / OK / DONE
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Filter"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_filter_list_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 03
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Filter records"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	

	#ACCEPT - Filter OK
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Apply Filter"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_filter_ok_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 03
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Apply Filter Criteria"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	


	#ACCEPT - Save
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Save"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_save_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 03
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Launch Print Manager Module"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	

	#ACCEPT - Report generation
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Generate Report"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_report_generate_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 03
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Generate Report File"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	

	#ACCEPT - Details
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_info_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 03
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "View Details TO the selected record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	


	#ACCEPT - Print
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Print"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_print_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 03
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Print"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	

	#ACCEPT - Print Manager
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Print Manager"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_print_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 03
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Launch Print Manager Module"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	



	#ACCEPT - NEXT
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Next"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_navigate_next_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 03
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Next Step"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	



	################# File section - PRINT  ################### 	
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "PRINT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Print"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_print_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 07
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Print"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	


	################# Edit 1 section  ################### 	
	# EDIT Divider
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Edit---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "---Divider-Edit---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 10
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0019 Edit"	

	# NEW / Insert
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "INSERT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "New"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_add_circle_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 11
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Create a new record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0019 Edit"	

	# NEW / Insert
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "APPEND"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "New"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_add_circle_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 12
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Create a new record at the end of the list"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0019 Edit"	

	
	# Edit / Modify
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "EDIT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Edit"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_mode_edit_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 13
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Edit currently selected record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0019 Edit"	

	# Delete / Remove
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "DELETE"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Delete"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_remove_circle_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 15
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Delete currently selected record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0019 Edit"	


	# Delete / Remove
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F2"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Delete"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_remove_circle_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 15
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Delete currently selected record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0019 Edit"	

	################# Edit 2 section  ################### 	
	#Toolbar Divider
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Edit 2---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "---Divider-Edit 2---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 20
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	


	# Insert Lookup Value
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "CONTROL-B"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Lookup (Ctrl-B)"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_search_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 21
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Lookup FROM a list AND choose a value"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = "CONTROL-B"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	

	# Bulk Input
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F6"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Input Bulk"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_mode_edit_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 23
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Multiple Record creation (Input Bulk)"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = "F6"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	

	# Generate List
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Generate"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Generate List"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_settings_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 23
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Generate List"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	

	# Edit Message Prompt for Report Header
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Message"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Message"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_mode_edit_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 25
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Edit Report Header Message"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	

	# Filter for Report
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Run Report"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Run Report"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_print_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 25
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Run/Generate Report"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	

	# Run Report
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Filter Report"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Filter Report"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_filter_list_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 26
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Filter Data for the REPORT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	


	# Load/Import UNL Cloud
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Load"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Load"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_cloud_download_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 27
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Load/Import Data (UNL)"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	

	# Load/Import UNL
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Load"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Load"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_file_download_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 27
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Load/Import Data (UNL)"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	
		
	# Export UNL Cloud
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Unload"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Unload"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_cloud_upload_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 28
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Export Data (UNL)"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	

	# Export UNL Disk
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Unload"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Unload"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_file_upload_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 28
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Export Data (UNL)"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	

	# Folder
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Directory"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Folder"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_folder_open_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 29
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Folder/Directory (UNL)"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"


	# Rerun / Re-run
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Rerun"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Rerun"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_directions_run_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 29
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Rerun"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_key = ""	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0021 - 0029 Edit2"	
	
	################# View section  ################### 
	# View section	
	# 0051 - 0059 View

	#View Divider
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-View---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "---Divider-View---"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 50
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0051 - 0059 View"	
	

	#Filter
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Filter"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Filter"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_filter_list_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 51
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Filter records"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0051 - 0059 View"	

	#View Details
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_info_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 52
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "View Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0051 - 0059 View"	

	#View Details
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F8"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Extend Criteria"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_settings_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 53
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Extend Filter/Query Criteria"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0051 - 0059 View"	


	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "CONTROL-N"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Info"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_info_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 53
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "View Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0051 - 0059 View"	


	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "CONTROL-P"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Info"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_info_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 54
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "View Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0051 - 0059 View"	
	# Details - Details
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F8"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_details_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 55 
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0019 Edit"	


	#View Details - Account Details
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F8"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Account Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_details_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 55
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Account Details"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0051 - 0059 View"	


	#verify check validate
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "verify"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Verify"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_check_circle_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 55
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Verify data"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0051 - 0059 View"	

	################# Navigation section  ################### 	
	#Toolbar Divider
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Navigation---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "---Divider-Navigation---"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 60
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "First"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "First"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_first_page_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 61
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO first record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1		
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Previous"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Previous"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_navigate_before_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 62
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO previous record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Next"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Next"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_navigate_next_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 63
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO next record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Last"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Last"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_last_page_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 64
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO last record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"

	################# Ext Modules section  ################### 	
	# Run Ext Prog
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Run Ext Prog---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "---Divider-Run Ext Prog---"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 70
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0071 - 0079 Run Ext Prog"

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F10"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Settings..."
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_settings_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 71
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Run Corresponding Settings Module..."
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0071 - 0079 Run Ext Prog"

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F10"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Data Mng"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_settings_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 71
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Run Sttings Module TO manage table/lookup data..."
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0071 - 0079 Run Ext Prog"



################# Settings section  ################### 	
	# Settings
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Settings---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "---Divider-Settings---"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 80
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0081 - 0089 Settings"

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "Settings"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Settings..."
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_settings_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 81
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Run Corresponding Settings Module..."
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0081 - 0089 Settings"

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "EditSettings"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Edit Settings"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_settings_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 81
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Edit Settings..."
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0081 - 0089 Settings"

	################# VIEW section  ################### 	
	#Toolbar Divider
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-View---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "---Divider-View---"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 90
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0091 - 0099 View"	

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F5"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "View"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_info_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 91
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "View Details..."
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0091 - 0099 View"

	################# HELP section  ################### 	
	#Toolbar Divider
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Help---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "---Divider-Help---"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 100
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0101 - 0109 Help"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "HELP"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Help"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_help_outline_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 101
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Help..."
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0101 - 0109 Help"

	################# Table Find/Search section  ################### 	
	#Toolbar Divider
	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Table-Find---"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "---Divider-Table-Find---"		
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 90
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0091 - 0093 Table-Find"


	#######################################################################################
	#Hide Icon section	  
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-ACCEPT-Hide"		
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0010 Main"	
	
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "CANCEL"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-CANCEL-Hide"		
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0001 - 0009 Main"	
	
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "APPEND"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-APPEND-Hide"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0029 Edit"
	
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "INSERT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-INSERT-Hide"		
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0029 Edit"
	
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "DELETE"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-DELETE-Hide"		
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0011 - 0029 Edit"


	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "FIND"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-FIND-Hide"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0091 - 0093 Find-Table"

	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "FINDNEXT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-FINDNEXT-Hide"	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0091 - 0093 Find-Table"

	#Hide Navigation
	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "PREVPAGE"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-PREVPAGE-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 61		
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"

	LET i = i + 1
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "NEXTPAGE"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-NEXTPAGE-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 64		
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"


	LET i = i + 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "FIRST"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-FIRST-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_first_page_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 61
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO first record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1		
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "PREVIOUS"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-PREVIOUS-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_navigate_before_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 62
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO previous record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "NEXT"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-NEXT-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_navigate_next_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 63
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO next record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "LAST"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-LAST-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= "ic_last_page_24px.svg"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 64
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO last record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"

	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "FIRSTROW"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-FIRSTROW-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 64
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO last record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "LASTROW"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-LASTROW-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 64
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Navigate TO last record"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
		
############# Hide F keys F1-F12	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F1"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F1-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 981
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F1"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F2"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F2-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 982
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F2"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F3"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F3-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 983
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F3"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F4"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F4-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 984
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F4"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F5"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F5-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 985
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F5"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F6"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F6-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 986
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F6"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F7"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F7-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 987
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F7"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F8"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F8-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 988
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F8"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F9"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F9-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 989
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F9"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F10"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F10-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 990
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F10"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F11"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F11-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 991
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F11"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"
	
	LET i = i + 1			
	LET modu_arr_rec_qxt_toolbar_template[i].tb_check  = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_action = "F12"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_label  = "Hide-F13-Hide"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_icon		= ""
	LET modu_arr_rec_qxt_toolbar_template[i].tb_position = 992
	LET modu_arr_rec_qxt_toolbar_template[i].tb_static = 0
	LET modu_arr_rec_qxt_toolbar_template[i].tb_tooltip = "Hide F12"
	LET modu_arr_rec_qxt_toolbar_template[i].tb_type = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_scope = 0	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_hide = 1	
	LET modu_arr_rec_qxt_toolbar_template[i].tb_category = "0061 - 0069 Navigation"		




######################################################################################

	
	OPEN WINDOW wTemplate WITH FORM "form/toolbar/_qxt_toolbar2_manager_template" ATTRIBUTE(BORDER,STYLE="CENTER")

	LET l_tb_module_id = modu_rec_filterRecord.filterModuleName 
	LET l_tb_menu_id = modu_rec_filterRecord.filterMenuId 
	
	DIALOG ATTRIBUTE(UNBUFFERED)
	
	INPUT l_tb_module_id, l_tb_menu_id WITHOUT DEFAULTS FROM tb_module_id, tb_menu_id
	END INPUT 
	
	INPUT ARRAY modu_arr_rec_qxt_toolbar_template WITHOUT DEFAULTS FROM qxt_toolbar_sc.*
	END INPUT
	
	ON ACTION "ACCEPT"
		EXIT DIALOG
----------------------------------------------------------------
	


	ON ACTION "Wizzard Nav"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
	
			CASE

			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Next"  
				LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "CANCEL" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Previous"  
				LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
							
		END CASE			
	
		END FOR
		############################################

	#Hide Navigation
	



	ON ACTION "Hide Navigation"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
	
			CASE

			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "PREVPAGE" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-PREVPAGE-Hide"  
				LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "NEXTPAGE" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-NEXTPAGE-Hide"  
				LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "FIRST" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-FIRST-Hide"  
				LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
					
			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "PREVIOUS" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-PREVIOUS-Hide"  
				LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
					
			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "NEXT" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-NEXT-Hide"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
					
			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "LAST" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-LAST-Hide"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
					
			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "FIRSTROW" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-FIRSTROW-Hide"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
					
			WHEN	
				modu_arr_rec_qxt_toolbar_template[i].tb_action = "LASTROW" AND
				modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-LASTROW-Hide"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1						
								
		END CASE			
	
		END FOR
	#Hide Navigation



----------------------------------------------------------------		
	ON ACTION "Filter/Home"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
		
		CASE
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Filter" 
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
	
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "CANCEL" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Home" 
					
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
			END CASE
			
		END FOR

	ON ACTION "Filter/Home/Div"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
		
		CASE
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "ACCEPT" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Filter" 
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
	
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "CANCEL" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Home" 
					
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1

 ---Divider-Edit---
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Edit---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
			#Divider Help		
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Help---"  
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
								
			END CASE
			
		END FOR
		

	ON ACTION "Hide Ins/App/Del"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
		
		CASE
			#Hide Append
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "APPEND" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-APPEND-Hide" 
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
			#Hide Insert
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "INSERT" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-INSERT-Hide" 
					
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1

			#Hide Insert
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "DELETE" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-DELETE-Hide" 
					
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
								
			END CASE
			
		END FOR
		

	ON ACTION "Common"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
		
	
			CASE

			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Edit---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
	
		
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Navigation---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1		

			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Table-Find---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1		
		
			WHEN  modu_arr_rec_qxt_toolbar_template[i].tb_action = "FIND" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-FIND-Hide" 
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
		
			
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "FINDNEXT" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-FINDNEXT-Hide" 
					
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1

			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Help---"  
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
								
		END CASE			
	
		END FOR
			

	ON ACTION "FilterOk/Home/Div"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
		
	
			CASE

			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Edit---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
	
		
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Navigation---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1		
		

			WHEN  modu_arr_rec_qxt_toolbar_template[i].tb_action = "FIND" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-FIND-Hide" 
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
		
			
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "FINDNEXT" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-FINDNEXT-Hide" 
					
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1

			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Help---"  
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
								
		END CASE			
	
		END FOR
------------------------------------------------

	ON ACTION "Hide Find"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
		
	
			CASE

			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Edit---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
	
		
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Navigation---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1		
		

			WHEN  modu_arr_rec_qxt_toolbar_template[i].tb_action = "FIND" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-FIND-Hide" 
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
		
			
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "FINDNEXT" AND
					modu_arr_rec_qxt_toolbar_template[i].tb_label = "Hide-FINDNEXT-Hide" 
					
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1

			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Help---"  
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
								
		END CASE			
	
		END FOR
		
------------------------------------------------
	ON ACTION "DivHelp"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
		
		CASE
			
			#Divider Help		
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Help---"  
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
			END CASE
			
		END FOR


	ON ACTION "DivEditHelp"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
		
		CASE
 			#Divider Edit
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Edit---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
			#Divider Help		
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Help---"  
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
			END CASE
			
		END FOR

	ON ACTION "DivEditNavHelp"
		FOR i = 1 TO 	modu_arr_rec_qxt_toolbar_template.getSize()
		
		CASE
 			#Divider Edit
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Edit---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1

			#Divider Navigation
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Navigation---"  
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1		

			
			#Divider Help		
			WHEN modu_arr_rec_qxt_toolbar_template[i].tb_action = "---Divider-Help---"  
			
					LET modu_arr_rec_qxt_toolbar_template[i].tb_check = 1
			
			END CASE
			
		END FOR
		
------------------------------------------------



		
	ON ACTION "Exit"
		EXIT DIALOG
		
	END DIALOG
#	END INPUT
	
	LET i = 1

	FOR i = 1 TO modu_arr_rec_qxt_toolbar_template.getSize()
	
		IF modu_arr_rec_qxt_toolbar_template[i].tb_check = 1 THEN
			IF tb_count(modu_rec_filterRecord.filterProjectName,l_tb_module_id,l_tb_menu_id,modu_arr_rec_qxt_toolbar_template[i].tb_action) = 0 THEN

				IF get_debug() THEN
					DISPLAY "modu_rec_filterRecord.filterProjectName=", trim(modu_rec_filterRecord.filterProjectName) 				
					DISPLAY "l_tb_module_id=", trim(l_tb_module_id) 				
					DISPLAY "l_tb_menu_id=", trim(l_tb_menu_id) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_action=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_action) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_label=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_label) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_icon=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_icon) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_position=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_position) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_static=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_static) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_tooltip=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_tooltip) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_type=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_type) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_scope=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_scope) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_hide=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_hide) 				
					DISPLAY "modu_arr_rec_qxt_toolbar_template[i].tb_category=", trim(modu_arr_rec_qxt_toolbar_template[i].tb_category) 				
					DISPLAY "modu_tb_user_name=", trim(modu_tb_user_name) 				
					DISPLAY "CURRENT YEAR TO SECOND =", trim(CURRENT YEAR TO SECOND ) 	

				END IF
	
					INSERT INTO qxt_toolbar VALUES(
						modu_rec_filterRecord.filterProjectName,
						l_tb_module_id,
						l_tb_menu_id,
						modu_arr_rec_qxt_toolbar_template[i].tb_action,
						modu_arr_rec_qxt_toolbar_template[i].tb_label,
						modu_arr_rec_qxt_toolbar_template[i].tb_icon,
						modu_arr_rec_qxt_toolbar_template[i].tb_position,
						modu_arr_rec_qxt_toolbar_template[i].tb_static,
						modu_arr_rec_qxt_toolbar_template[i].tb_tooltip,
						modu_arr_rec_qxt_toolbar_template[i].tb_type,
						modu_arr_rec_qxt_toolbar_template[i].tb_scope,
						modu_arr_rec_qxt_toolbar_template[i].tb_hide,
						'',						
						modu_arr_rec_qxt_toolbar_template[i].tb_category,						
						modu_tb_user_name,
						CURRENT YEAR TO SECOND  
						)
			END IF			
		END IF
	END FOR
	
	CLOSE WINDOW wTemplate

END FUNCTION
#########################################################################
# END FUNCTION templateMenu()
#########################################################################


###############################################################
# FUNCTION initCombo_projName(p_comboFieldName)
# Argument: p_comboFieldName  - the field name of the comboList Field
# RETURN: Void
# Populates a comboBox with supplier names AND codes
# Shown IS the Supplier Code
###############################################################
FUNCTION initCombo_projName(p_comboFieldName)
	DEFINE p_comboFieldName STRING
	DEFINE l_rowCount SMALLINT

	DECLARE projName_q CURSOR FOR
		SELECT DISTINCT  tb_proj_id
		FROM qxt_toolbar
		#WHERE cursupp.supp_code MATCHES srch_string
		ORDER BY tb_proj_id

	LET l_rowCount = 1

	CALL ui.ComboBox.ForName(p_comboFieldName).CLEAR()

	CALL modu_arr_tb_proj_id.CLEAR()
	FOREACH projName_q INTO modu_arr_tb_proj_id[l_rowCount]
		#CALL fgl_list_set(p_comboFieldName,l_rowCount, l_suppCode_arr[l_rowCount].supp_code)
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(modu_arr_tb_proj_id[l_rowCount],modu_arr_tb_proj_id[l_rowCount])
		LET l_rowCount = l_rowCount + 1
	END FOREACH
	LET l_rowCount = l_rowCount -1
	
	IF l_rowCount = 1 THEN
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(modu_rec_filterRecord.filterProjectName,modu_rec_filterRecord.filterProjectName)
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem("global","global")
		LET l_rowCount = l_rowCount +1		
	END IF
	
	RETURN l_rowCount
END FUNCTION
###############################################################
# END FUNCTION initCombo_projName(p_comboFieldName)
###############################################################


###############################################################
# FUNCTION initCombo_moduleId(p_comboFieldName)
# Argument: p_comboFieldName  - the field name of the comboList Field
# RETURN: Void
# Populates a comboBox with moduleId's
###############################################################
FUNCTION initCombo_moduleId(p_comboFieldName)
	DEFINE p_comboFieldName STRING
	DEFINE l_rowCount SMALLINT
	DEFINE l_foundCount SMALLINT

	DECLARE progName_q CURSOR FOR
	SELECT DISTINCT tb_module_id
		FROM qxt_toolbar
		WHERE tb_proj_id = modu_rec_filterRecord.filterProjectName
		ORDER BY tb_module_id
	WHENEVER ERROR CONTINUE --alch KD-1415: temporary fix, remove it ASAP when real issue fixed 

	LET l_rowCount = 1
	CALL ui.ComboBox.ForName(p_comboFieldName).CLEAR()

	CALL modu_arr_tb_module_id.CLEAR()
	FOREACH progName_q INTO modu_arr_tb_module_id[l_rowCount]
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(modu_arr_tb_module_id[l_rowCount],modu_arr_tb_module_id[l_rowCount])
		LET l_rowCount = l_rowCount + 1
	END FOREACH
	WHENEVER ERROR STOP --alch KD-1415: temporary fix, remove it ASAP when real issue fixed

	LET l_rowCount = l_rowCount -1
	IF l_rowCount = 1 THEN
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(modu_rec_filterRecord.filterModuleName,modu_rec_filterRecord.filterModuleName)
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem("global","global")
		LET l_rowCount = l_rowCount +1 
	END IF

	SELECT count(*)
	INTO l_foundCount
	FROM qxt_toolbar
	WHERE tb_module_id = modu_rec_filterRecord.filterModuleName

	IF l_foundCount = 0 THEN
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(modu_rec_filterRecord.filterModuleName,modu_rec_filterRecord.filterModuleName)
		LET l_rowCount = l_rowCount +1 
	END IF	

	RETURN l_rowCount
END FUNCTION
###############################################################
# END FUNCTION initCombo_moduleId(p_comboFieldName)
###############################################################


###############################################################
# FUNCTION initCombo_menuId(p_comboFieldName)
# Argument: p_comboFieldName  - the field name of the comboList Field
# RETURN: Void
# Populates a comboBox with menuId's
###############################################################
FUNCTION initCombo_menuId (p_comboFieldName)
	DEFINE p_comboFieldName STRING
	DEFINE l_rowCount SMALLINT
	DEFINE p_sql_stmt VARCHAR(2500)
	DEFINE l_ERR_CODE INT
	DEFINE l_curs_menuId CURSOR

	DEFINE l_menuId LIKE qxt_toolbar.tb_menu_id

	LET p_sql_stmt = 
		"SELECT DISTINCT tb_menu_id ",
		"FROM qxt_toolbar ",
		"WHERE tb_proj_id = \"", modu_rec_filterRecord.filterProjectName CLIPPED, "\" "

	IF modu_rec_filterRecord.filterModuleSwitch = TRUE AND modu_rec_filterRecord.filterModuleName IS NOT NULL THEN
		LET p_sql_stmt = p_sql_stmt CLIPPED, " AND tb_module_id = \"", modu_rec_filterRecord.filterModuleName CLIPPED, "\" "   
	END IF

	LET p_sql_stmt = p_sql_stmt CLIPPED, " ORDER BY tb_menu_id "


	CALL l_curs_menuId.DECLARE(p_sql_stmt,1) RETURNING l_ERR_CODE

	CALL l_curs_menuId.SetResults(l_menuId)

	CALL l_curs_menuId.OPEN()

	LET l_rowCount = 1

	WHENEVER ERROR CONTINUE --alch KD-1415: temporary fix, remove it ASAP when real issue fixed 
	CALL ui.ComboBox.ForName(p_comboFieldName).CLEAR()

	WHILE (l_curs_menuId.FetchNext()=0) 
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(l_menuId,l_menuId)
		LET l_rowCount = l_rowCount+1
	END WHILE

	CALL l_curs_menuId.close()
	WHENEVER ERROR STOP --alch KD-1415: temporary fix, remove it ASAP when real issue fixed 

	IF l_rowCount = 1 THEN
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(modu_rec_filterRecord.filterMenuId,modu_rec_filterRecord.filterMenuId)
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem("global","global")
		LET l_rowCount = l_rowCount +1 
	END IF
	
	RETURN l_rowCount
END FUNCTION
###############################################################
# END FUNCTION initCombo_menuId(p_comboFieldName)
###############################################################


###############################################################
# FUNCTION initCombo_action(p_comboFieldName)
# Argument: p_comboFieldName  - the field name of the comboList Field
# RETURN: Item Count
# Populates a comboBox with supplier names AND codes
# Shown IS the list of all used (db stored) actions
###############################################################
FUNCTION initCombo_action (p_comboFieldName)
	DEFINE p_comboFieldName STRING
	DEFINE l_rowCount SMALLINT
 
	DECLARE action_q CURSOR FOR
		SELECT DISTINCT tb_action
		FROM qxt_toolbar
		#WHERE cursupp.supp_code MATCHES srch_string
		ORDER BY tb_action

	LET l_rowCount = 1

	CALL ui.ComboBox.ForName(p_comboFieldName).CLEAR()

	CALL modu_arr_tb_action.CLEAR()
	FOREACH action_q INTO modu_arr_tb_action[l_rowCount]
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(modu_arr_tb_action[l_rowCount],modu_arr_tb_action[l_rowCount])
		LET l_rowCount = l_rowCount + 1
	END FOREACH

	RETURN l_rowCount -1

END FUNCTION
###############################################################
# END FUNCTION initCombo_action(p_comboFieldName)
###############################################################


###############################################################
# FUNCTION initCombo_icon(p_comboFieldName)
# Argument: p_comboFieldName  - the field name of the comboList Field
# RETURN: Item Count
# Populates a comboBox with supplier names AND codes
# Shown IS the list of all used (db stored) icons
###############################################################
FUNCTION initCombo_icon (p_comboFieldName)
	DEFINE p_comboFieldName STRING
	DEFINE l_rowCount SMALLINT

	DECLARE icon_q CURSOR FOR
		SELECT DISTINCT  tb_icon
		FROM qxt_toolbar
		ORDER BY tb_icon

	LET l_rowCount = 1

	CALL ui.ComboBox.ForName(p_comboFieldName).CLEAR()

	CALL modu_arr_tb_icon.CLEAR()
	FOREACH icon_q INTO modu_arr_tb_icon[l_rowCount]
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(modu_arr_tb_icon[l_rowCount],modu_arr_tb_icon[l_rowCount])
		LET l_rowCount = l_rowCount + 1
	END FOREACH

	RETURN l_rowCount -1

END FUNCTION
###############################################################
# END FUNCTION initCombo_icon(p_comboFieldName)
###############################################################


###############################################################
# FUNCTION initCombo_category(p_comboFieldName)
# Argument: p_comboFieldName  - the field name of the comboList Field
# RETURN: Item Count
# Populates a comboBox with supplier names AND codes
# Shown IS the list of all used (db stored) icons
###############################################################
FUNCTION initCombo_category (p_comboFieldName)
	DEFINE p_comboFieldName STRING
	DEFINE l_rowCount SMALLINT

	DECLARE category_q CURSOR FOR
		SELECT DISTINCT  tb_category
		FROM qxt_toolbar
		#WHERE cursupp.supp_code MATCHES srch_string
		ORDER BY tb_category

	LET l_rowCount = 1

	CALL ui.ComboBox.ForName(p_comboFieldName).CLEAR()

	CALL modu_arr_tb_category.CLEAR()
	FOREACH category_q INTO modu_arr_tb_category[l_rowCount]
		CALL ui.ComboBox.ForName(p_comboFieldName).addItem(modu_arr_tb_category[l_rowCount],modu_arr_tb_category[l_rowCount])
		LET l_rowCount = l_rowCount + 1
	END FOREACH

	RETURN l_rowCount -1

END FUNCTION
###############################################################
# END FUNCTION initCombo_category(p_comboFieldName)
###############################################################


#######################################################################
# FUNCTION saveRecord(p_idx)
#
#
#######################################################################
FUNCTION saveRecord(p_idx)
	DEFINE p_idx INT
	DEFINE l_msgStr STRING
	DEFINE l_choice STRING  --FOR fgl_winbutton save/new/cancel RETURN  --used by CASE
	DEFINE l_iconPreviewURI STRING -- icon preview uri needs CONTEXT AND root location prefix adding 

	IF int_flag THEN
		LET int_flag = FALSE
  ELSE
  	#NEW RECORD OR UPDATE
  	IF tb_count(modu_rec_qxt_toolbar.tb_proj_id,modu_rec_qxt_toolbar.tb_module_id,modu_rec_qxt_toolbar.tb_menu_id,modu_rec_qxt_toolbar.tb_action) > 0 THEN --NEW tb RECORD already exists - >SAVE (NOT new)
  
  		LET modu_rec_qxt_toolbar.tb_mod_user = modu_tb_user_name
  		LET modu_rec_qxt_toolbar.tb_mod_date = CURRENT YEAR TO SECOND
  					  		
  		UPDATE qxt_toolbar
  		SET * = modu_rec_qxt_toolbar.*
			
			WHERE
					qxt_toolbar.tb_proj_id = modu_rec_qxt_toolbar.tb_proj_id AND
					qxt_toolbar.tb_module_id = modu_rec_qxt_toolbar.tb_module_id AND
					qxt_toolbar.tb_menu_id = modu_rec_qxt_toolbar.tb_menu_id AND
					qxt_toolbar.tb_action  =  modu_rec_qxt_toolbar.tb_action
	
			IF sqlca.sqlcode = 0 THEN
				MESSAGE "ToolbarButton RECORD Save/Update successful"
				
				#Update program array
				LET modu_arr_rec_toolbar[p_idx].tb_module_id = modu_rec_qxt_toolbar.tb_module_id
				LET modu_arr_rec_toolbar[p_idx].tb_menu_id = modu_rec_qxt_toolbar.tb_menu_id
				LET modu_arr_rec_toolbar[p_idx].tb_action = modu_rec_qxt_toolbar.tb_action
				LET modu_arr_rec_toolbar[p_idx].tb_label = modu_rec_qxt_toolbar.tb_label
				LET modu_arr_rec_toolbar[p_idx].tb_icon = modu_rec_qxt_toolbar.tb_icon
				LET modu_arr_rec_toolbar[p_idx].tb_position = modu_rec_qxt_toolbar.tb_position
				LET modu_arr_rec_toolbar[p_idx].tb_static = modu_rec_qxt_toolbar.tb_static
				LET modu_arr_rec_toolbar[p_idx].tb_type = modu_rec_qxt_toolbar.tb_type
				LET modu_arr_rec_toolbar[p_idx].tb_scope = modu_rec_qxt_toolbar.tb_scope
				LET modu_arr_rec_toolbar[p_idx].tb_hide = modu_rec_qxt_toolbar.tb_hide
				#LET modu_arr_rec_toolbar[p_idx].tb_key = modu_rec_qxt_toolbar.tb_key			
				LET modu_arr_rec_toolbar[p_idx].tb_category = modu_rec_qxt_toolbar.tb_category
				#Update ComboBoxes for toolbarbutton properties
				CALL refreshChangingComboBoxes()				
				#Update icon preview
				LET l_iconPreviewURI = fgl_getenv("TOOLBAR_PATH"), trim(modu_rec_qxt_toolbar.tb_icon) 		
				DISPLAY l_iconPreviewURI TO tb_icon_url					
				DISPLAY l_iconPreviewURI TO iconPreview ATTRIBUTE(BLUE,REVERSE)
									
			ELSE 
				LET l_msgStr = "An error occurred WHILE trying TO create/INSERT the RECORD in the DB"           
				CALL fgl_winmessage("An error occurred WHILE writing data TO the DB", l_msgStr,"info")
			END IF --IF sqlca.sqlcode = 0 						
										
		####### ELSE = NEW RECORD 

		ELSE -- NEW Toolbarbutton record

			LET l_choice = fgl_winbutton("Save OR New ?", "Change existing RECORD OR create new toolbar button RECORD ?", "Save", "Save|New|Cancel", "question", 1)
			
			CASE l_choice
				WHEN "Save"
		  		LET modu_rec_qxt_toolbar.tb_mod_user = modu_tb_user_name
		  		LET modu_rec_qxt_toolbar.tb_mod_date = CURRENT YEAR TO SECOND
		  					  		
		  		UPDATE qxt_toolbar
		  		SET * = modu_rec_qxt_toolbar.*
					
					WHERE
							qxt_toolbar.tb_proj_id = modu_rec_qxt_toolbar.tb_proj_id AND
							qxt_toolbar.tb_module_id = modu_arr_rec_toolbar[p_idx].tb_module_id AND
							qxt_toolbar.tb_menu_id = modu_arr_rec_toolbar[p_idx].tb_menu_id AND
							qxt_toolbar.tb_action  =  modu_arr_rec_toolbar[p_idx].tb_action
							
			
					IF sqlca.sqlcode = 0 THEN
				#Update program array
				LET modu_arr_rec_toolbar[p_idx].tb_module_id = modu_rec_qxt_toolbar.tb_module_id
				LET modu_arr_rec_toolbar[p_idx].tb_menu_id = modu_rec_qxt_toolbar.tb_menu_id
				LET modu_arr_rec_toolbar[p_idx].tb_action = modu_rec_qxt_toolbar.tb_action
				LET modu_arr_rec_toolbar[p_idx].tb_label = modu_rec_qxt_toolbar.tb_label
				LET modu_arr_rec_toolbar[p_idx].tb_icon = modu_rec_qxt_toolbar.tb_icon
				LET modu_arr_rec_toolbar[p_idx].tb_position = modu_rec_qxt_toolbar.tb_position
				LET modu_arr_rec_toolbar[p_idx].tb_static = modu_rec_qxt_toolbar.tb_static
				LET modu_arr_rec_toolbar[p_idx].tb_type = modu_rec_qxt_toolbar.tb_type
				LET modu_arr_rec_toolbar[p_idx].tb_scope = modu_rec_qxt_toolbar.tb_scope
				LET modu_arr_rec_toolbar[p_idx].tb_hide = modu_rec_qxt_toolbar.tb_hide
				LET modu_arr_rec_toolbar[p_idx].tb_category = modu_rec_qxt_toolbar.tb_category
				#Update icon preview
				LET l_iconPreviewURI = fgl_getenv("TOOLBAR_PATH"), trim(modu_rec_qxt_toolbar.tb_icon) 			
				DISPLAY l_iconPreviewURI TO tb_icon_url				
				DISPLAY l_iconPreviewURI TO iconPreview ATTRIBUTE(BLUE,REVERSE)

						MESSAGE "ToolbarButton RECORD Save/Update successful"
						
					ELSE 
						LET l_msgStr = "An error occurred WHILE trying TO create/INSERT the RECORD in the DB"           
						CALL fgl_winmessage("An error occurred on Save/Update", l_msgStr,"info")
					END IF	
				
				WHEN "New"	#needs exception handling
{					DISPLAY "modu_rec_qxt_toolbar.tb_proj_id=", modu_rec_qxt_toolbar.tb_proj_id
					DISPLAY "modu_rec_qxt_toolbar.tb_module_id=", modu_rec_qxt_toolbar.tb_module_id
					DISPLAY "modu_rec_qxt_toolbar.tb_menu_id=", modu_rec_qxt_toolbar.tb_menu_id
					DISPLAY "modu_rec_qxt_toolbar.tb_action=", modu_rec_qxt_toolbar.tb_action
					DISPLAY "modu_rec_qxt_toolbar.tb_label=", modu_rec_qxt_toolbar.tb_label
					DISPLAY "modu_rec_qxt_toolbar.tb_icon=", modu_rec_qxt_toolbar.tb_icon
					DISPLAY "modu_rec_qxt_toolbar.tb_position=", modu_rec_qxt_toolbar.tb_position
					DISPLAY "modu_rec_qxt_toolbar.tb_static=", modu_rec_qxt_toolbar.tb_static
					DISPLAY "modu_rec_qxt_toolbar.tb_tooltip=", modu_rec_qxt_toolbar.tb_tooltip
					DISPLAY "modu_rec_qxt_toolbar.tb_type=", modu_rec_qxt_toolbar.tb_type
					DISPLAY "modu_rec_qxt_toolbar.tb_scope=", modu_rec_qxt_toolbar.tb_scope
					DISPLAY "modu_rec_qxt_toolbar.tb_hide=", modu_rec_qxt_toolbar.tb_hide
					DISPLAY "modu_rec_qxt_toolbar.tb_key=", modu_rec_qxt_toolbar.tb_key				
					DISPLAY "modu_rec_qxt_toolbar.tb_category=", modu_rec_qxt_toolbar.tb_category				
					DISPLAY "modu_tb_user_name=", modu_tb_user_name  --modu_rec_qxt_toolbar.tb_mod_user,
					DISPLAY "CURRENT YEAR TO SECOND=", CURRENT YEAR TO SECOND 
}
					INSERT INTO qxt_toolbar VALUES(
						modu_rec_qxt_toolbar.tb_proj_id,
						modu_rec_qxt_toolbar.tb_module_id,
						modu_rec_qxt_toolbar.tb_menu_id,
						modu_rec_qxt_toolbar.tb_action,
						modu_rec_qxt_toolbar.tb_label,
						modu_rec_qxt_toolbar.tb_icon,
						modu_rec_qxt_toolbar.tb_position,
						modu_rec_qxt_toolbar.tb_static,
						modu_rec_qxt_toolbar.tb_tooltip,
						modu_rec_qxt_toolbar.tb_type,
						modu_rec_qxt_toolbar.tb_scope,
						modu_rec_qxt_toolbar.tb_hide,
						modu_rec_qxt_toolbar.tb_key,						
						modu_rec_qxt_toolbar.tb_category,						
						modu_tb_user_name,  --modu_rec_qxt_toolbar.tb_mod_user,
						CURRENT YEAR TO SECOND  --modu_rec_qxt_toolbar.tb_mod_date
					)
					
					IF sqlca.sqlcode = 0 THEN
						MESSAGE "New RECORD created"            	
					ELSE 
						LET l_msgStr = "An error occurred WHILE trying TO create/INSERT the RECORD in the DB"           
						CALL fgl_winmessage("An error occurred WHILE writing data TO the DB", l_msgStr,"info")
					END IF 						
							
				WHEN "Cancel"
				OTHERWISE
					CALL fgl_winmessage("Error in toolbarManager","Invalid CASE argument","error")
					
			END CASE
			
			RETURN 1 --EXIT DIALOG  --need TO EXIT dialog TO refresh/UPDATE all comboBoxes with possible changed VALUES/entries


		END IF  --save existing OR new rec
		RETURN 0
	END IF	--int_flag check
	
END FUNCTION
#######################################################################
# END FUNCTION saveRecord(p_idx)
#######################################################################


#######################################################################
# FUNCTION deleteRecord(p_idx)
#
#
#######################################################################
FUNCTION deleteRecord(p_idx)
	DEFINE p_idx INT
	DEFINE l_msgStr STRING
	DEFINE l_choice STRING  --FOR fgl_winbutton save/new/cancel RETURN  --used by CASE
	DEFINE l_iconPreviewURI STRING -- icon preview uri needs CONTEXT AND root location prefix adding 
	DEFINE l_delCount SMALLINT

	#Count the number of "for delete" selected rows
	LET l_delCount = 0
	FOR p_idx = 1 TO arr_count()
		IF dialog.isRowSelected("qxt_toolbar_sc",p_idx) THEN
			LET l_delCount = l_delCount + 1
		END IF
	END FOR	

	#Get delete re-assurance FROM user
	LET l_msgStr = "Do you really want TO delete ", trim(l_delCount), " menu items?"
	IF fgl_winbutton( "Delete",l_msgStr,"No", "Yes|No", "question","") = "Yes" THEN
			
		FOR p_idx = 1 TO arr_count()
			IF dialog.isRowSelected("qxt_toolbar_sc",p_idx) THEN
				CALL getToolbarRecord(modu_rec_filterRecord.filterProjectName,  --modu_arr_rec_toolbar[p_idx].tb_proj_id, 
																modu_arr_rec_toolbar[p_idx].tb_module_id, 
																modu_arr_rec_toolbar[p_idx].tb_menu_id, 
																modu_arr_rec_toolbar[p_idx].tb_action)
							RETURNING modu_rec_qxt_toolbar.*
				#LET l_msgStr = "Do you really want TO delete ", trim(l_delCount), " menu items?"
				#LET l_msgStr = 	"Do you really want TO delete this record?\n\n",
  			#					"proj_id = ", trim (modu_rec_qxt_toolbar.tb_proj_id), "\n",
  			#					"prog_id = ", trim (modu_rec_qxt_toolbar.tb_module_id), "\n",
  			#					"menu_id = ", trim (modu_rec_qxt_toolbar.tb_menu_id), "\n",
  			#					"action  = ", trim (modu_rec_qxt_toolbar.tb_action), "\n"
  											  											  								
				#IF fgl_winbutton( "Delete",l_msgStr,"No", "Yes|No", "question","") = "Yes" THEN
				IF tb_count(modu_rec_qxt_toolbar.tb_proj_id,modu_rec_qxt_toolbar.tb_module_id,modu_rec_qxt_toolbar.tb_menu_id,modu_rec_qxt_toolbar.tb_action) > 0 THEN --Record does exist - so it can be deleted
					DELETE FROM qxt_toolbar WHERE
							qxt_toolbar.tb_proj_id = modu_rec_qxt_toolbar.tb_proj_id AND
							qxt_toolbar.tb_module_id = modu_rec_qxt_toolbar.tb_module_id AND
							qxt_toolbar.tb_menu_id = modu_rec_qxt_toolbar.tb_menu_id AND
							qxt_toolbar.tb_action  =  modu_rec_qxt_toolbar.tb_action
				END IF

				IF sqlca.sqlcode = 0 THEN
					#				LET l_msgStr = 	"ToolbarButton RECORD\n\n",
  				#				"proj_id = ", trim (modu_rec_qxt_toolbar.tb_proj_id), "\n",
  				#				"prog_id = ", trim (modu_rec_qxt_toolbar.tb_module_id), "\n",
  				#				"menu_id = ", trim (modu_rec_qxt_toolbar.tb_menu_id), "\n",
  				#				"action  = ", trim (modu_rec_qxt_toolbar.tb_action), "\n",
  				#				" deleted successfully"
					#	MESSAGE "ToolbarButton RECORD ", trim(modu_rec_qxt_toolbar.tb_menu_id), " deleted successfully"
				ELSE 
					LET l_msgStr = "An error occurred WHILE trying TO delete the RECORD in the DB"           
					CALL fgl_winmessage("Error on delete", l_msgStr,"info")
				END IF --IF sqlca.sqlcode = 0 	

			END IF
		END FOR
	END IF

	RETURN 1 --EXIT DIALOG  --need TO EXIT dialog TO refresh/UPDATE all comboBoxes with possible changed VALUES/entries

END FUNCTION
#######################################################################
# END FUNCTION deleteRecord(p_idx)
#######################################################################


###############################################################
# FUNCTION get_datasource_toolbar_arr()
#
# Query DB TO get all rows with the current filter l_choice	
###############################################################
FUNCTION get_datasource_toolbar_arr()
	DEFINE i SMALLINT
	DEFINE l_sql_stmt STRING
	DEFINE l_row_count INT
	DEFINE l_sql_stmt_count STRING
	DEFINE l_msg_temp STRING
	
	LET l_sql_stmt = " SELECT tb_module_id, tb_menu_id, tb_action, tb_label, tb_icon, ",
						"tb_position, tb_place, tb_static, tb_type, tb_scope, tb_hide, tb_category ", --, tb_mod_user, tb_mod_date

					" FROM qxt_toolbar ",
					" WHERE "

	LET l_sql_stmt_count = "SELECT COUNT(*) ",

					" FROM qxt_toolbar ",
					" WHERE "



	#Project Filter IS always active
	LET l_sql_stmt = l_sql_stmt CLIPPED, " tb_proj_id = '", modu_rec_filterRecord.filterProjectName CLIPPED, "' "
	LET l_sql_stmt_count = l_sql_stmt_count CLIPPED, " tb_proj_id = '", modu_rec_filterRecord.filterProjectName CLIPPED, "' "

	#Program/4gl file filter
	IF modu_rec_filterRecord.filterModuleSwitch = TRUE AND modu_rec_filterRecord.filterModuleName IS NOT NULL THEN
		LET l_sql_stmt = l_sql_stmt CLIPPED, " AND tb_module_id = '", modu_rec_filterRecord.filterModuleName CLIPPED, "' "
		LET l_sql_stmt_count = l_sql_stmt_count CLIPPED, " AND tb_module_id = '", modu_rec_filterRecord.filterModuleName CLIPPED, "' "
	END IF

	#Menu ID filter
	IF modu_rec_filterRecord.filterMenuIDSwitch = TRUE AND modu_rec_filterRecord.filterMenuId IS NOT NULL THEN
		LET l_sql_stmt = l_sql_stmt CLIPPED, " AND tb_menu_id = '", modu_rec_filterRecord.filterMenuId CLIPPED, "' "
		LET l_sql_stmt_count = l_sql_stmt_count CLIPPED, " AND tb_menu_id = '", modu_rec_filterRecord.filterMenuId CLIPPED, "' "
	END IF


	LET l_sql_stmt = l_sql_stmt CLIPPED, " ORDER BY tb_proj_id, tb_module_id, tb_menu_id, tb_position ,tb_category "


	PREPARE p_count FROM l_sql_stmt_count
	DECLARE c_count CURSOR FOR p_count

	FOREACH c_count INTO l_row_count
	END FOREACH

	IF l_row_count > 500 THEN
		LET l_msg_temp = "Current Filter produces a very large SET of data\n Search Result would list ", trim(l_row_count) , " rows!\nDo you want TO continue with this?"
		IF fgl_winbutton("Data Set IS very large", l_msg_temp, "No", "Yes|No", "exclamation", 1) = "No" THEN
			RETURN -1 -- -1=result IS too large - keep existing
		END IF

	END IF
	
	CALL modu_arr_rec_toolbar.CLEAR()

	PREPARE p_toolbar FROM l_sql_stmt
	DECLARE c_toolbar CURSOR FOR p_toolbar



	LET i = 1
	CALL modu_arr_rec_toolbar.CLEAR()
	FOREACH c_toolbar INTO modu_arr_rec_toolbar[i].*
		LET i = i+1
	END FOREACH
	CALL modu_arr_rec_toolbar.delete(i)

	DISPLAY modu_arr_rec_toolbar.getLength() TO rowCount

	RETURN modu_arr_rec_toolbar.getLength()

END FUNCTION
###############################################################
# END FUNCTION get_datasource_toolbar_arr()
###############################################################


###############################################################
# FUNCTION getDataCopy()
#
# Query DB TO get all rows with the current filter l_choice	
###############################################################
FUNCTION getDataCopy(p_tb_proj_id,p_tb_module_id,p_tb_menu_id)
	DEFINE p_tb_proj_id LIKE qxt_toolbar.tb_proj_id
	DEFINE p_tb_module_id LIKE qxt_toolbar.tb_module_id
	DEFINE p_tb_menu_id LIKE qxt_toolbar.tb_menu_id

	
	DEFINE i SMALLINT
	DEFINE l_sql_stmt STRING
	
    LET l_sql_stmt = " SELECT tb_module_id, tb_menu_id, tb_action, tb_label, tb_icon, ",
    							"tb_position, tb_static, tb_type, tb_scope, tb_hide, tb_category ",  --, tb_mod_user, tb_mod_date
    
                 " FROM   qxt_toolbar ",
                 " WHERE "


	#Project Filter IS always active
  LET l_sql_stmt = l_sql_stmt CLIPPED, " tb_proj_id = '", p_tb_proj_id CLIPPED, "' "

	#Module/4gl file filter

      LET l_sql_stmt = l_sql_stmt CLIPPED, " AND tb_module_id = '", p_tb_module_id CLIPPED, "' "


	#Menu ID filter

      LET l_sql_stmt = l_sql_stmt CLIPPED, " AND tb_menu_id = '", p_tb_menu_id CLIPPED, "' "


 
 	LET l_sql_stmt = l_sql_stmt CLIPPED, " ORDER BY tb_proj_id, tb_module_id, tb_menu_id, tb_position ,tb_category "
 
 	CALL modu_arr_rec_toolbar_copy.CLEAR()
 
  PREPARE p2_toolbar FROM l_sql_stmt
  DECLARE c2_toolbar CURSOR FOR p2_toolbar
  
  LET i = 1
  CALL modu_arr_rec_toolbar_copy.CLEAR()
  FOREACH c2_toolbar INTO modu_arr_rec_toolbar_copy[i].*
  	LET i = i+1
  END FOREACH

  CALL modu_arr_rec_toolbar_copy.delete(i)
  LET i = i-1
	DISPLAY i TO rowCount
	RETURN i

END FUNCTION
###############################################################
# END FUNCTION getDataCopy()
###############################################################


{
#######################################################################
# FUNCTION getIconUrl()
#
#
#######################################################################
FUNCTION getIconUrl()
	DEFINE exitCondition BOOLEAN

	DEFINE tb_ic_rec RECORD LIKE qxt_tb_icon.*	 
	DEFINE l_curr_arr_idx SMALLINT


	DEFINE operationRecord RECORD
		filterSwitch1 BOOLEAN,
		tb_cat1 LIKE  qxt_tb_icon.tb_cat1,
		filterSwitch2 BOOLEAN ,
		tb_cat2 LIKE  qxt_tb_icon.tb_cat2,
		filterSwitch3 BOOLEAN,
		tb_cat3 LIKE  qxt_tb_icon.tb_cat3		

		END RECORD

	OPEN WINDOW wIconSelector WITH FORM "form/toolbar/_qxt_toolbar2_manager_icon" ATTRIBUTE(BORDER)
	
	WHILE exitCondition = FALSE

   	CALL getIconData(operationRecord.*)
   	
		DIALOG ATTRIBUTE(UNBUFFERED)
			INPUT BY NAME operationRecord.*
			END INPUT

			DISPLAY ARRAY tb_ic_arr TO TableIcon.*
				BEFORE ROW
					LET l_curr_arr_idx = ARR_CURR()
					LET modu_rec_qxt_toolbar.* = modu_arr_rec_toolbar[l_curr_arr_idx].*	
					
			END DISPLAY
	 

			INPUT tb_ic_rec.* FROM tb_ic_rec.*
	
			END INPUT
	
			ON ACTION "SELECT"
				RETURN tb_ic_arr[l_curr_arr_idx].tb_icon

		END DIALOG
	END WHILE
END FUNCTION
#######################################################################
# END FUNCTION getIconUrl()
#######################################################################


#######################################################################
# FUNCTION getIconData(p_filterSwitch1, p_filterCat1, p_filterSwitch2, p_filterCat2,p_filterSwitch3,p_filterCat3)
#
#
#######################################################################
FUNCTION getIconData(p_filterSwitch1, p_filterCat1, p_filterSwitch2, p_filterCat2,p_filterSwitch3,p_filterCat3)
	DEFINE p_filterSwitch1, p_filterSwitch2, p_filterSwitch3 BOOLEAN
	DEFINE p_filterCat1, p_filterCat2, p_filterCat3 LIKE qxt_tb_icon.tb_cat1

	DEFINE i SMALLINT
	DEFINE l_sql_stmt STRING
	
    LET l_sql_stmt = " SELECT * ",    
                 " FROM   qxt_tb_icon "
                 
	IF p_filterSwitch1 = TRUE OR p_filterSwitch2 = TRUE OR p_filterSwitch3 = TRUE THEN
		LET l_sql_stmt = l_sql_stmt CLIPPED, " WHERE"
	END IF
	 
  IF p_filterSwitch1 = TRUE THEN
      LET l_sql_stmt = l_sql_stmt CLIPPED, " tb_cat1 = '", p_filterCat1 CLIPPED, "' "
      LET l_sql_stmt = l_sql_stmt CLIPPED, " OR tb_cat2 = '", p_filterCat1 CLIPPED, "' "
      LET l_sql_stmt = l_sql_stmt CLIPPED, " OR tb_cat3 = '", p_filterCat1 CLIPPED, "' "
	END IF

  IF p_filterSwitch2 = TRUE THEN
		IF p_filterSwitch1 = TRUE THEN
			LET l_sql_stmt = l_sql_stmt CLIPPED, " OR "
		END IF
  
      LET l_sql_stmt = l_sql_stmt CLIPPED, " tb_cat1 = '", p_filterCat2 CLIPPED, "' "
      LET l_sql_stmt = l_sql_stmt CLIPPED, " OR tb_cat2 = '", p_filterCat2 CLIPPED, "' "
      LET l_sql_stmt = l_sql_stmt CLIPPED, " OR tb_cat3 = '", p_filterCat2 CLIPPED, "' "
	END IF

  IF p_filterSwitch3 = TRUE THEN
		IF p_filterSwitch1 = TRUE OR p_filterSwitch2 = TRUE THEN
			LET l_sql_stmt = l_sql_stmt CLIPPED, " OR "
		END IF


      LET l_sql_stmt = l_sql_stmt CLIPPED, " tb_cat1 = '", p_filterCat3 CLIPPED, "' "
      LET l_sql_stmt = l_sql_stmt CLIPPED, " OR tb_cat2 = '", p_filterCat3 CLIPPED, "' "
      LET l_sql_stmt = l_sql_stmt CLIPPED, " OR tb_cat3 = '", p_filterCat3 CLIPPED, "' "
	END IF

 
 	LET l_sql_stmt = l_sql_stmt CLIPPED, " ORDER BY tb_icon "
 
 	CALL modu_arr_rec_toolbar.CLEAR()
 
  PREPARE p_tb_icon FROM l_sql_stmt
  DECLARE c_tb_icon CURSOR FOR p_tb_icon
  
  LET i = 1
  CALL tb_ic_arr.CLEAR()
  FOREACH c_tb_icon INTO tb_ic_arr[i].*
  	LET i = i+1
  END FOREACH
  
	RETURN i

END FUNCTION
#######################################################################
# END FUNCTION getIconData(p_filterSwitch1, p_filterCat1, p_filterSwitch2, p_filterCat2,p_filterSwitch3,p_filterCat3)
#######################################################################


}
####################################################
# FUNCTION company_name_count(p_comp_name)
#
# tests IF a RECORD with this name already exists
#
# RETURN l_ret_count
####################################################
FUNCTION tb_count(p_tb_proj_id,p_tb_module_id,p_tb_menu_id,p_tb_action)
	DEFINE p_tb_proj_id LIKE qxt_toolbar.tb_proj_id
	DEFINE p_tb_module_id LIKE qxt_toolbar.tb_module_id
	DEFINE p_tb_menu_id LIKE qxt_toolbar.tb_menu_id
	DEFINE p_tb_action LIKE qxt_toolbar.tb_action
  DEFINE l_ret_count SMALLINT

    SELECT COUNT(*)
      INTO l_ret_count
      FROM qxt_toolbar
      WHERE qxt_toolbar.tb_proj_id = p_tb_proj_id 
      AND qxt_toolbar.tb_module_id = p_tb_module_id 
      AND qxt_toolbar.tb_menu_id = p_tb_menu_id       
      AND qxt_toolbar.tb_action = p_tb_action       


RETURN l_ret_count   --0 = unique  0> IS NOT

END FUNCTION
####################################################
# END FUNCTION company_name_count(p_comp_name)
####################################################


#######################################################################
# FUNCTION getToolbarRecord(p_tb_proj_id, p_tb_module_id, p_tb_menu_id, p_tb_action)
#
# FUNCTION TO retrieve complete toolbarRecord qxt_toolbar.*
#######################################################################
FUNCTION getToolbarRecord(p_tb_proj_id, p_tb_module_id, p_tb_menu_id, p_tb_action)
	DEFINE p_tb_proj_id LIKE qxt_toolbar.tb_proj_id
	DEFINE p_tb_module_id LIKE qxt_toolbar.tb_module_id
	DEFINE p_tb_menu_id LIKE qxt_toolbar.tb_menu_id
	DEFINE p_tb_action  LIKE qxt_toolbar.tb_action
	DEFINE l_rec_qxt_toolbar RECORD LIKE qxt_toolbar.*

	SELECT * INTO l_rec_qxt_toolbar.*
	FROM qxt_toolbar
	WHERE tb_proj_id = p_tb_proj_id
	AND tb_module_id = p_tb_module_id
	AND tb_menu_id = p_tb_menu_id
	AND tb_action = p_tb_action

	RETURN l_rec_qxt_toolbar.*
END FUNCTION
#######################################################################
# END FUNCTION getToolbarRecord(p_tb_proj_id, p_tb_module_id, p_tb_menu_id, p_tb_action)
#######################################################################


##############################################################
# FUNCTION exist_projectName(p_filterProjectName)
#
# Check DB, if this projectname actually exists
##############################################################
FUNCTION exist_projectName(p_filterProjectName)
	DEFINE p_filterProjectName LIKE qxt_toolbar.tb_proj_id
	DEFINE l_rec_count INT
	
	IF p_filterProjectName IS NULL THEN RETURN 0 END IF
	SELECT COUNT(*) INTO l_rec_count FROM qxt_toolbar 
	WHERE tb_proj_id = p_filterProjectName

	RETURN l_rec_count

END FUNCTION
##############################################################
# END FUNCTION exist_projectName(p_filterProjectName)
##############################################################


##############################################################
# FUNCTION importToolbarUnl()
#
#
##############################################################
FUNCTION importToolbarUnl()
	DEFINE l_msgString STRING
	DEFINE l_import_report STRING
		
  DEFINE l_driver_error  STRING
  DEFINE l_native_error  STRING
  DEFINE l_native_code  INTEGER
  
	
	DEFINE l_count_rows_processed INT
	DEFINE l_count_rows_inserted INT
	DEFINE l_count_rows_updated INT	
	DEFINE l_count_insert_errors INT
	DEFINE l_count_already_exist INT
	
	DEFINE l_rec_import_qxt_toolbar RECORD  LIKE qxt_toolbar.*
	DEFINE l_rec_qxt_toolbar RECORD  LIKE qxt_toolbar.*

	CREATE TEMP TABLE temp_qxt_toolbar(
          	tb_proj_id VARCHAR(30), --LIKE qxt_toolbar.tb_proj_id,
          	tb_module_id VARCHAR(30), -- LIKE qxt_toolbar.tb_module_id,
          	tb_menu_id VARCHAR(30), --  LIKE qxt_toolbar.tb_menu_id,
          	tb_action VARCHAR(30), --  LIKE qxt_toolbar.tb_action,
          	tb_label VARCHAR(20), --  LIKE qxt_toolbar.tb_label,
          	tb_icon VARCHAR(150), --  LIKE qxt_toolbar.tb_icon,
          	tb_position INTEGER, --  LIKE qxt_toolbar.tb_position,
          	tb_static SMALLINT, -- LIKE qxt_toolbar.tb_static, --BOOLEAN,
          	tb_tooltip VARCHAR(100), --  LIKE qxt_toolbar.tb_tooltip,
          	tb_type SMALLINT, --   LIKE qxt_toolbar.tb_type, --0=button 1=divider--BOOLEAN,  --TRUE = seperator pipe (NOT a button)
          	tb_scope SMALLINT, --   LIKE qxt_toolbar.tb_scope, --0=dialog 1=global --BOOLEAN,  --scope  TRUE IS dialog
          	tb_hide SMALLINT, --   LIKE qxt_toolbar.tb_hide, --0=visible 1=hide/remove --BOOLEAN,  --TRUE will delete that button - FALSE will SET it		
          	tb_key VARCHAR(30), --  LIKE qxt_toolbar.tb_key,          	
						tb_category VARCHAR(30),  --LIKE qxt_toolbar.tb_category
						tb_mod_user CHAR(4), -- LIKE qxt_toolbar.tb_mod_user,  --user last modified this record
						tb_mod_date DATETIME YEAR TO SECOND -- LIKE qxt_toolbar.tb_mod_date  --dateTime WHEN last modified this record

	)

	OPEN WINDOW wImport WITH FORM "per/setup/db_coa_input"
	LOAD FROM "unl/qxt_toolbar.unl" INSERT INTO temp_qxt_toolbar
	  DECLARE qxt_toolbar_cur CURSOR FOR 
						SELECT *
						FROM temp_qxt_toolbar

--	WHENEVER ERROR CONTINUE						

  LET l_count_rows_processed = 0
  LET l_count_rows_inserted = 0
  LET l_count_insert_errors = 0
  LET l_count_already_exist = 0
  LET l_count_rows_updated = 0
 
  FOREACH qxt_toolbar_cur INTO l_rec_import_qxt_toolbar
  	#DISPLAY rec_coa.*

		IF tb_count(l_rec_import_qxt_toolbar.tb_proj_id,l_rec_import_qxt_toolbar.tb_module_id,l_rec_import_qxt_toolbar.tb_menu_id,l_rec_import_qxt_toolbar.tb_action) = 0 THEN

			LET l_import_report = l_import_report, "Project:", trim(l_rec_import_qxt_toolbar.tb_proj_id) , "     -     Prog/4gl:", trim(l_rec_import_qxt_toolbar.tb_module_id), "     -     Prog/4gl:", trim(l_rec_import_qxt_toolbar.tb_menu_id), "     -     Action:", trim(l_rec_import_qxt_toolbar.tb_action), "\n"
					
			INSERT INTO qxt_toolbar VALUES( l_rec_import_qxt_toolbar.*)
			
			{
			(
	  	 	l_cmpy_code,
	  	 	rec_coa.acct_code,
	  	 	rec_coa.desc_text,
	
	  	 	l_start_year_num, 
	  	 	l_start_period_num, 
	  	 	l_end_year_num, 
	  	 	l_end_period_num,
	  	 	rec_coa.group_code,
	  	 	rec_coa.analy_req_flag,
	  	 	rec_coa.analy_prompt_text,
	  	 	"",
	  	 	"",
	  	 	rec_coa.type_ind,  	 	
	  	 	""
	  	 
	  	)
}
  	 
			IF STATUS <> 0 THEN --ERROR

				LET l_count_insert_errors = l_count_insert_errors +1
	
			  LET l_driver_error = fgl_driver_error()
			  LET l_native_error = fgl_native_error()
			  LET l_native_code = fgl_native_code()
	  
				LET l_import_report = l_import_report, "ERROR STATUS:\t", trim(STATUS), "\n"
				LET l_import_report = l_import_report, "sqlca.sqlcode:\t",trim(sqlca.sqlcode), "\n" 
				LET l_import_report = l_import_report, "l_driver_error:\t", trim(l_driver_error), "\n"
				LET l_import_report = l_import_report, "l_native_error:\t", trim(l_native_error), "\n"
				LET l_import_report = l_import_report, "l_native_code:\t",  trim(l_native_code), "\n"					

			END IF
			
			LET l_count_rows_inserted = l_count_rows_inserted + 1

		ELSE
			
			LET l_count_already_exist = l_count_already_exist +1		
			
			CALL getToolbarRecord(
												l_rec_import_qxt_toolbar.tb_proj_id,  
												l_rec_import_qxt_toolbar.tb_module_id, 
												l_rec_import_qxt_toolbar.tb_menu_id, 
												l_rec_import_qxt_toolbar.tb_action)
				RETURNING l_rec_qxt_toolbar.*
				
			IF l_rec_import_qxt_toolbar.tb_mod_date > l_rec_qxt_toolbar.tb_mod_date THEN  --imported RECORD IS newer
				LET l_import_report = l_import_report, "Project:", trim(l_rec_import_qxt_toolbar.tb_proj_id) , "     -     Prog/4gl:", trim(l_rec_import_qxt_toolbar.tb_module_id), "     -     Prog/4gl:", trim(l_rec_import_qxt_toolbar.tb_menu_id), "     -     Action:", trim(l_rec_import_qxt_toolbar.tb_action) , " ->DUPLICATE but newer/imported !\n"





	  		UPDATE qxt_toolbar
	  		SET * = l_rec_import_qxt_toolbar.*
				
				WHERE
						qxt_toolbar.tb_proj_id =  l_rec_import_qxt_toolbar.tb_proj_id AND
						qxt_toolbar.tb_module_id =  l_rec_import_qxt_toolbar.tb_module_id AND
						qxt_toolbar.tb_menu_id =  l_rec_import_qxt_toolbar.tb_menu_id AND
						qxt_toolbar.tb_action  =  l_rec_import_qxt_toolbar.tb_action
						
						LET l_count_rows_updated = l_count_rows_updated+1
			ELSE
			
				LET l_import_report = l_import_report, "Project:", trim(l_rec_import_qxt_toolbar.tb_proj_id) , "     -     Prog/4gl:", trim(l_rec_import_qxt_toolbar.tb_module_id), "     -     Prog/4gl:", trim(l_rec_import_qxt_toolbar.tb_menu_id), "     -     Action:", trim(l_rec_import_qxt_toolbar.tb_action) , " ->DUPLICATE but existing IS newer !\n"			
			
			END IF				
		
		END IF
		
		LET l_count_rows_processed= l_count_rows_processed + 1
	
	END FOREACH

--	WHENEVER ERROR STOP


	call fgl_winmessage("what is this","what is this","error")
	DISPLAY l_count_rows_processed TO count_rows_processed
	DISPLAY l_count_rows_inserted TO count_rows_inserted
	DISPLAY l_count_insert_errors TO count_insert_errors
	DISPLAY l_count_already_exist TO count_already_exist
	
	INPUT l_import_report WITHOUT DEFAULTS FROM import_report
		ON ACTION "Done"
			EXIT INPUT
	END INPUT
	
	CLOSE WINDOW wImport
	
	RETURN l_count_rows_inserted	
#needs TO be done
#pseudo code
#1.CREATE TEMP TABLE
#2. import unl file
#3. FOREACH on tempTable
#	check IF exist
#		IF NOT -> INSERT
#		IF yes 
#		   compare mod_date AND take newer entry
#		   
#NOTE: Problem IS, how do we deal with deleted entries ?		   
		
END FUNCTION
##############################################################
# END FUNCTION importToolbarUnl()
##############################################################


#######################################################################
# FUNCTION refreshCopyToolbarComboBoxes()
#
# 
#######################################################################
FUNCTION refreshComboBoxes_filter()
	LET modu_countProjects =  initCombo_projName("filterProjectName") 
	LET modu_countModules =  initCombo_moduleId("filterModuleName") 
	LET modu_countMenus =  initCombo_menuId("filterMenuId")

	WHENEVER ERROR CONTINUE
		# Screen Update FOR counts
		DISPLAY modu_countProjects TO countProjects
		DISPLAY modu_countModules TO countModules
		DISPLAY modu_countMenus TO countMenus
	WHENEVER ERROR STOP

	CALL ui.interface.refresh()
END FUNCTION
#######################################################################
# END FUNCTION refreshCopyToolbarComboBoxes()
#######################################################################


#######################################################################
# FUNCTION refreshCopyToolbarComboBoxes()
#
# 
#######################################################################
FUNCTION refreshCopyToolbarComboBoxes()
	CALL initCombo_moduleId("source_tb_module_id")
	CALL initCombo_menuId("source_tb_menu_id")
	CALL initCombo_moduleId("target_tb_module_id")
	CALL initCombo_menuId("target_tb_menu_id")
	CALL ui.interface.refresh()
END FUNCTION
#######################################################################
# END FUNCTION refreshCopyToolbarComboBoxes()
#######################################################################


#######################################################################
# FUNCTION refreshChangingComboBoxes()
#
# 
#######################################################################
FUNCTION refreshChangingComboBoxes()
		CALL initCombo_action("tb_action")
		CALL initCombo_icon("tb_icon")
		CALL initCombo_category("tb_category")
END FUNCTION		
#######################################################################
# END FUNCTION refreshChangingComboBoxes()
#######################################################################