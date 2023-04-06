# The items on this menu are small test applications designed
# TO demonstrate a particularly bug/issue with Lycia3.
#
# Querix can access this FROM outside on:
#   http://41.215.133.23:11290/LyciaWeb    default-1889   test/menu
#
define
	runCommand STRING
	DEFINE currentMenuId INT
	DEFINE LastWidgetId STRING
	
MAIN
	DEFINE
  	main_menu_id, action_id  INTEGER,
  	runtString STRING,
  	i, n, sub_id, x,y  INTEGER
  DEFINE menuGroupId INTEGER

	CALL ui_init(2)

  CALL ui.Interface.setType("container")                 # Program Container
 	CALL ui.Interface.LoadStartMenu("form/kandoo_forms")

  CALL ui.Application.GetCurrent().setMenuType("Tree")   # DEFINE menu type (TreeMenu)
  CALL ui.Application.GetCurrent().SetClassNames(["tabbed_container"])

  CALL ui.interface.frontcall("html5","scriptImport",["{CONTEXT}/public/querix/js/demo_samples_footer.js"],[])  -- i.e. add additonal header AND satusbar elements AND their styles


  CALL ui.interface.frontcall("sample","changeFrameTemplate",[],[])  --change the viewports/template i.e. header area AND statusbar attachment



  CALL fgl_settitle("KandooERP Form Viewer")

	#CALL ui.Interface.setText("Querix MDI")

			CALL fgl_setkeylabel("ACCEPT","")
			CALL fgl_setkeylabel("CANCEL","")
			--CALL fgl_setkeylabel("HELP","")
			CALL fgl_setkeylabel("actCmdInvoke","")
			

			
	MENU
			
		ON ACTION actCmdInvoke
	
			LET LastWidgetId = fgl_getlastwidgetid()
			
			IF LastWidgetId[1,3] = "act" THEN
					CASE LastWidgetId
						WHEN "actexit" 
							IF exitMdiContainer() THEN
								EXIT MENU
							END IF

   

						WHEN "actFooter1"
							CALL ui.interface.frontcall("html5","eval",["window.top.$('#lbValueUserName').text('Victor Masibasi')"],[])
							CALL ui.interface.frontcall("html5","eval",["window.top.$('#lbValueUserDepartment').text('Research AND Marketing')"],[])
							CALL ui.interface.frontcall("html5","eval",["window.top.$('#lbValueUserLoginTime').text('14:28')"],[])
							CALL ui.interface.frontcall("html5","eval",["window.top.$('#lbValueUserBirthDate').text('24.12.1968')"],[])						

						WHEN "actFooter2"
							CALL ui.interface.frontcall("html5","eval",["window.top.$('#lbValueUserName').text('John Smith')"],[])
							CALL ui.interface.frontcall("html5","eval",["window.top.$('#lbValueUserDepartment').text('Customer Service')"],[])
							CALL ui.interface.frontcall("html5","eval",["window.top.$('#lbValueUserLoginTime').text('08:12')"],[])
							CALL ui.interface.frontcall("html5","eval",["window.top.$('#lbValueUserBirthDate').text('09.07.1984')"],[])
						
						OTHERWISE 
							CALL fgl_winmessage("otherwise",LastWidgetId,"info")							
					END CASE
					
			ELSE	
				LET runtString = trim(fgl_getlastwidgetid())
				
				IF get_vdom_set() THEN
					LET runtString = runtString, " VDOM=", trim(get_url_vdom()) 			
				END IF
	
				
	
				#DISPLAY "runtString=", runtString 			
				RUN runtString WITHOUT WAITING
			END IF
		
				
	    COMMAND KEY(INTERRUPT) "Exit-Interrupt-Key"
					IF exitMdiContainer() THEN
						EXIT MENU
					END IF
						
	END MENU
END MAIN
 
 
################################################################################
# FUNCTION exitMdiContainer()
#
#
################################################################################
FUNCTION exitMdiContainer()
	DEFINE msg String
	
	IF ui.Interface.getChildCount() > 0 THEN --one OR more child apps are running in mdi container-user must close them before the mdi container can be closed	
		LET msg = "You must close your child applications prior TO closing the parent-mdi host:\nNumber of child-applications currently running:", ui.Interface.getChildCount()
		CALL fgl_winmessage("Child Applications are still running",msg,"error")
		ERROR "You must first EXIT the child programs."
		RETURN FALSE
	ELSE
		#Do some clean up stuff here if it IS required
		RETURN TRUE
	END IF
END FUNCTION