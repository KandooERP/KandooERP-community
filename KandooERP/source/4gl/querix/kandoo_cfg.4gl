############################################################
# GLOBAL SCOPE
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
############################################################
# MODULE SCOPE
############################################################
DEFINE runCommand STRING
	DEFINE currentMenuId INT
	DEFINE LastWidgetId STRING
	DEFINE startmenu ui.MenuBar
	DEFINE mi_global DYNAMIC ARRAY OF ui.MenuItem
 	DEFINE menuEvent_global ui.BackgroundServerEventHandler
	DEFINE MenuFileToDrive TEXT
	DEFINE MenuFile STRING	
	DEFINE MenuFileName STRING
#############################################################################
# MAIN
#
# The items on this menu are small test applications designed
# TO demonstrate a particularly bug/issue with Lycia3.
#
# Querix can access this FROM outside on:
#   http://41.215.133.23:11290/LyciaWeb    default-1889   test/menu
#
#############################################################################	
MAIN
	DEFINE main_menu_id INTEGER
	DEFINE action_id  INTEGER
	DEFINE i INTEGER
	DEFINE n INTEGER
	DEFINE sub_id  INTEGER
	DEFINE x INTEGER
	DEFINE y INTEGER
  DEFINE menuGroupId INTEGER
	DEFINE runStr STRING
	DEFINE runStrFinal STRING --including environment
	DEFINE fileNameCheck,msg STRING

	CALL ui_init(3) --Kandoo SysAdmin Setup MDI

	DEFER INTERRUPT

	LET startmenu = ui.MenuBar.Forname("c1") --INITIALIZE empty menu container FOR UI methods
	CALL set_ku_language_code("ENG")  --For now, we work with ENGLISH as the defaut language code

	CALL fgl_settitle("Kandoo ERP 2.0") --Application name	

	#CALL fgl_setactionlabel("actChangePWD","Change Pwd","{CONTEXT}/public/querix/icon/svg/24/ic_lock_open_24px.svg",10,TRUE,"Change user password")
	#CALL fgl_setactionlabel("actEXIT","Exit","{CONTEXT}/public/querix/icon/svg/24/ic_cancel_24px.svg",20,TRUE,"Close application")
	CALL fgl_setkeylabel("actChangePWD","")
	CALL fgl_setkeylabel("actEXIT","")


	CALL ui.interface.refresh()
	
#	#Authenticate / Login Screen
	CALL setModuleId("MEN")
	CALL ui.interface.refresh()
	CALL authenticate(getModuleId())
	CALL ui.interface.refresh()	
	
 	--CALL ui.Interface.LoadStartMenu("form/kandoo_menu_startmenu")
	CALL ui.Interface.LoadStartMenu("per/querix/kandoo_setup_startmenu")	
	#LET startmenu = ui.MenuBar.Forname("c1") --INITIALIZE empty menu container FOR UI methods
	CALL set_ku_language_code("ENG")  --For now, we work with ENGLISH as the defaut language code

	CALL fgl_settitle("Kandoo ERP 2.0") --Application name	

	#CALL fgl_setactionlabel("actChangePWD","Change Pwd","{CONTEXT}/public/querix/icon/svg/24/ic_lock_open_24px.svg",10,TRUE,"Change user password")
	#CALL fgl_setactionlabel("actEXIT","Exit","{CONTEXT}/public/querix/icon/svg/24/ic_cancel_24px.svg",20,TRUE,"Close application")
	CALL fgl_setkeylabel("actChangePWD","")
	CALL fgl_setkeylabel("actEXIT","")
	
#	CALL ui.interface.frontcall("html5","scriptImport",["{CONTEXT}/public/querix/js/transformers.js",""],[])
#
#  CALL ui.Interface.setType("container")                 # Program Container
# 	CALL ui.Interface.LoadStartMenu("per/querix/kandoo_setup_startmenu")
#  CALL ui.Application.GetCurrent().setMenuType("Tree")   # DEFINE menu type (TreeMenu)
#  CALL ui.Application.GetCurrent().SetClassNames(["tabbed_container"])

	LET MenuFileName = "per/querix/kandoo_setup_startmenu"
	IF fgl_test("e",MenuFileName) THEN #If menu file IS absent on app server
		IF NOT os.Path.delete(MenuFileName) THEN
			CALL fgl_winmessage("Error","Could not remove existing startmenu form","error")
		END IF
		
	END IF
	
	CALL ui.Interface.LoadStartMenu(MenuFileName)

	MENU
		BEFORE MENU
			CALL fgl_setkeylabel("ACCEPT","")
			CALL fgl_setkeylabel("CANCEL","")
			--CALL fgl_setkeylabel("HELP","")
			
		ON ACTION actCmdInvoke
			DISPLAY "" AT 5,5
	
		LET LastWidgetId = fgl_getlastwidgetid()
		
		IF LastWidgetId = "mc_exit" THEN
			IF exitMdiContainer() THEN
				EXIT MENU
			END IF		
		ELSE	
		
			LET runStr = UPSHIFT(fgl_getlastwidgetid())
			
---------------------------------
			IF fgl_arch() = "nt" THEN
				LET fileNameCheck = trim(runStr), ".exe"
				#check if file exists
				IF NOT os.Path.exists(fileNameCheck) THEN	
					LET msg = "The program file ", trim(fileNameCheck), " does NOT exist on your application server!"				
					CALL fgl_winmessage("Program does NOT exist",msg,"error")
				ELSE
					#check if file IS executable
					IF NOT os.Path.executable(fileNameCheck) THEN	
						LET msg = "The program file ", trim(fileNameCheck), " IS NOT executable ! Check your user/file permissions!"				
						CALL fgl_winmessage("Program does NOT executable",msg,"error")
					END IF
				END IF
				LET runStrFinal = "SET KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && SET KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && SET KANDOODB=", trim(get_ku_database_name()), " && ", trim(runStr), ".exe"
			ELSE  --Linux/Unix
				LET fileNameCheck = trim(runStr)
				#check if file exists
				IF NOT os.Path.exists(fileNameCheck) THEN	
					LET msg = "The program file ", trim(fileNameCheck), " does NOT exist on your application server!"				
					CALL fgl_winmessage("Program does NOT exist",msg,"error")
				ELSE
					#check if file IS executable
					IF NOT os.Path.executable(fileNameCheck) THEN	
						LET msg = "The program file ", trim(fileNameCheck), " IS NOT executable ! Check your user/file permissions!"				
						CALL fgl_winmessage("Program does NOT executable",msg,"error")
					END IF
				END IF

				LET runStrFinal = "export KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && export KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && export KANDOODB=", trim(get_ku_database_name()), " && ", trim(runStr) 
			END IF
			
			IF get_debug() THEN
				DISPLAY "---------------- 270----"
				DISPLAY "->", trim(runStrFinal), "<-"
				DISPLAY "get_ku_sign_on_code() = ", get_ku_sign_on_code() #GL_LOGIN_NAME
				DISPLAY "get_ku_password_text() = ", get_ku_password_text() #GL_LOGIN_PASSWORD
			END IF



---------------------------------			
			#DISPLAY runStrFinal
			RUN trim(runStrFinal) WITHOUT WAITING
			
		END IF
		
		
		
{
			CASE fgl_getlastwidgetid() --Returns ID of the last triggered element
				WHEN "4gl_environment"
					RUN "4gl_environment cms" WITHOUT WAITING		


				WHEN "company"
					RUN "company" WITHOUT WAITING		

				WHEN "contact"
					RUN "contact" WITHOUT WAITING		

				WHEN "customerLicenseComplete"
					RUN "customerLicenseComplete" WITHOUT WAITING							


				WHEN "mc_exit" 
##########
					IF exitMdiContainer() THEN
						EXIT MENU
					END IF
	
			END CASE
}			
	    COMMAND KEY(INTERRUPT) "Exit-Interrupt-Key"
					IF exitMdiContainer() THEN
						EXIT MENU
					END IF
						
	END MENU
END MAIN


############################################################
# FUNCTION exitMdiContainer()
#
#
############################################################
FUNCTION exitMdiContainer()
	DEFINE msg String
	
	IF ui.Interface.getChildCount() > 0 THEN --one OR more child apps are running in mdi container-user must close them before the mdi container can be closed	
		LET msg = "You must close your child applications prior TO closing the parent-mdi host:\nNumber of child-applications currently running:", ui.Interface.getChildCount()
		CALL fgl_winmessage("Child Applications are still running",msg,"error")
		ERROR "You must first EXIT the child programs."
		RETURN FALSE
	ELSE
		#Do some clean up stuff here IF it IS required
		RETURN TRUE
	END IF
END FUNCTION