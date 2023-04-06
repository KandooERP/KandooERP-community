GLOBALS "../common/glob_GLOBALS.4gl" 

#Module Scope variables
DEFINE startmenu ui.menubar 
DEFINE mi_global DYNAMIC ARRAY OF ui.menuitem 
DEFINE menuevent_global ui.backgroundservereventhandler 
DEFINE menufiletodrive text 
DEFINE menufile STRING 
DEFINE modu_last_run_str STRING 

# TODO: revoke all but kandooappadm for access to qxt_menu_item and qxt_menu_item_txt, then read this table with a dba stored procedure
# TODO: include security on menu by deleting the rows of qxt_menu_item on which the user has no access from the initial temp table load
#############################################################################
# MAIN
#
#
#############################################################################
MAIN 
	DEFINE promptmenu CHAR --just FOR the PROMPT MENU INPUT (NOT visible) 
	DEFINE itemid,argcnt INTEGER 
	DEFINE argvalue STRING
	DEFINE menufilename STRING  
	DEFINE l_progname CHAR(3)
	DEFINE l_mb_id INTEGER
	DEFINE a INTEGER
	DEFINE l_msg STRING
	
	CALL ui_init(2) --mdi 

	DEFER interrupt 

	--CALL ui.Interface.LoadStartMenu("form/kandoo_menu_startmenu")

	LET startmenu = ui.MenuBar.Forname("c1") --initialize empty MENU container FOR ui methods 
	CALL set_ku_language_code("ENG") --for now, we WORK with english as the defaut language code 

	CALL fgl_settitle("Kandoo ERP 2.0") --application NAME 

	#CALL fgl_setactionlabel("actChangePWD","Change Pwd","{CONTEXT}/public/querix/icon/svg/24/ic_lock_open_24px.svg",10,TRUE,"Change user password")
	#CALL fgl_setactionlabel("actEXIT","Exit","{CONTEXT}/public/querix/icon/svg/24/ic_cancel_24px.svg",20,TRUE,"Close application")
	CALL fgl_setkeylabel("actChangePWD","") 
	CALL fgl_setkeylabel("actEXIT","") 

	CALL ui.interface.refresh() 

	#	#Authenticate / Login Screen
	CALL setModuleId("MEN") 
	CALL ui.interface.refresh() 
	CALL authenticate(getmoduleid()) 
	CALL ui.interface.refresh() 
	CALL ui.interface.frontcall("kandooCompanyName","setName",[glob_rec_company.name_text],[])
	
	#	IF get_authenticate_dialog() THEN  --authentication=1
	#		IF NOT login_rec_kandoouser() THEN  ##does the full login, validation, AND SET's the environment AND GLOBALS
	#			EXIT PROGRAM
	#		END IF
	#	ELSE



	##### Special demo flag ##################################################
	#IF get_url_demo() THEN  --demo=1
	#IF main_authenticated_kandoouser_and_set_globals("Guest","Guest") > 0 THEN
	#	CALL init_kandoouser_environment()
	#ELSE  --demo=0
	#	CALL fgl_winmessage("Problems with authentication","Demo Mode requires enabled Guest User Account","error")
	#	EXIT PROGRAM
	#END IF
	#ELSE  #no demo mode AND no authentication login request
	#	IF (get_ku_login_name() IS NOT NULL) AND (get_ku_sign_on_code() IS NOT NULL) THEN
	#		IF main_authenticated_kandoouser_and_set_globals(get_ku_sign_on_code(),get_ku_password_text()) > 0 THEN --valid authentication
	#			CALL init_kandoouser_environment()
	#		END IF
	#	ELSE
	#		#authentication option was NOT SET, use AND password was NOT provided.. so we force TO login SCREEN
	#		IF NOT login_rec_kandoouser() THEN  ##does the full login, validation, AND SET's the environment AND GLOBALS
	#			EXIT PROGRAM
	#		END IF
	#	END IF
	#END IF

	#			ELSE
	#				CALL fgl_winmessage("Problems with authentication","User could NOT be authenticated!\nApplication will be terminated","error")
	#				EXIT PROGRAM
	#			END IF
	#		END IF
	#	END IF



	#EXIT menu command
	#CALL init_action_name("actClose")
	#CALL addMenuItem (2,0,9997,"Exit application","","Exit application")

	#Logout menu command
	#CALL init_action_name("actLogOut")
	#CALL addMenuItem (2,0,9999,"LogOut","","LogOut")


	#System Info
	#CALL init_action_name("SYSINFO")
	#CALL addMenuItem (2,0,9999,"System Info","","Display System Information (Dev Mode)")

	#Other menu building
	#CALL init_action_name("actCmdInvoke")

	LET menufilename = "form/static_menu_from_db.fm2" 
	IF fgl_test("e",MenuFileName) THEN #if MENU file IS absent ON app server 
		IF NOT os.path.delete(menufilename) THEN 
			CALL fgl_winmessage("Error","Could not remove existing startmenu form","error") 
		END IF 

	END IF 

--	IF NOT fgl_test("e",MenuFileName) THEN #if MENU file IS absent ON app server 

		LOCATE menufiletodrive IN MEMORY
--		LOCATE menufiletodrive in file menufilename #create file AND populate it with MENU
		LET menufile = menufile,'<form><MenuBar identifier="c1">' #alpr 
		#EXIT menu command
		LET menufile = menufile,'<MenuCommand text="Exit application" identifier="exit_app"><MenuCommand.onInvoke><ActionEventHandler type="actioneventhandler" actionName="actClose"/></MenuCommand.onInvoke></MenuCommand>' #alpr 
		#Logout menu command
		LET menufile = menufile,'<MenuCommand text="LogOut" identifier="log_out"><MenuCommand.onInvoke><ActionEventHandler type="actioneventhandler" actionName="actLogOut"/></MenuCommand.onInvoke></MenuCommand>' #alpr 
		#System Info
		LET menufile = menufile,'<MenuCommand text="System Info" identifier="sys_inf"><MenuCommand.onInvoke><ActionEventHandler type="actioneventhandler" actionName="SYSINFO"/></MenuCommand.onInvoke></MenuCommand>' #alpr 
		--CALL buildmenu(0) 
		CALL buildmenu_new(0)
		LET menufile = menufile,'</MenuBar></form>' #alpr 
		LET menufiletodrive = menufile 
--	END IF 

--	CALL ui.interface.loadstartmenu(menufilename)
	CALL ui.interface.loadstartmenu(menufiletodrive) 
	MENU 

		ON ACTION "actChangePWD" 
			CALL changepassword(get_ku_sign_on_code()) 

		ON ACTION "SYSINFO" 
			CALL retrieveLyciaSystemEnvironment("F") 

		ON ACTION "DEBUG" 
			
			IF get_debug() = FALSE THEN
				CALL set_debug(TRUE)
				LET l_msg = "Runtime QA Debug enabled"
			ELSE
				CALL set_debug(FALSE)
				LET l_msg = "Runtime QA Debug disabled"
			END IF

			LET l_msg = l_msg, "\n", "Last Run command=", trim(modu_last_run_str)
			DISPLAY l_msg
			CALL fgl_winmessage("QA Debug", l_msg,"info")
			
			 
		ON ACTION "actCmdInvoke" 
			LET itemid = fgl_getlastwidgetid() 

			IF get_debug() THEN 
				DISPLAY "CALL run_cmd(itemid) ->", trim(itemid) 
			END IF 

			IF NOT get_url_demo() THEN --isall THEN 
				CALL run_cmd(itemid) 
			ELSE 
				SELECT 1 FROM qxt_menu_item i, qxt_menu_item_txt t 
				WHERE i.mb_type=2 
				AND i.r_command matches '[agpu]*' 
				AND t.mb_id = i.mb_id 
				AND i.mb_id = itemid 
				IF status = notfound THEN 
					CALL fgl_winmessage("KandooERP Demo","This Module IS NOT part of the Demo KandooERP Suite","info") 
				ELSE 
					CALL run_cmd(itemid) 

				END IF 
			END IF 

		ON ACTION "DIRECT_LAUNCH"
			LET l_progname = fgl_winprompt(1, 2, "Please type the Program Name (ex P21)", "", 30, 0) #huho changed from 3 to 30 for long program names
			SELECT mb_id INTO itemid 
			FROM qxt_menu_item 
			WHERE r_command = l_progname
			IF sqlca.sqlcode = 0 THEN
				CALL run_cmd(itemid)
			ELSE
				ERROR "This program does not exist"
			END IF

		ON ACTION "actLogOut" 
			IF nochilds() THEN #exit only IF all child apps are closed
 				CALL ui.interface.frontcall("kandooCompanyName","clearName",[],[])
				CALL cleanexit() -- doesn't clean global variablres!!!!!
				#CALL set_url_demo(0)
				#HuHo Re-Login again
				CALL login_rec_kandoouser() #returning glob_rec_kandoouser.* 
				#CALL setUserEnvironment(glob_rec_kandoouser.*)
				# should re-read all global variables, as new user can belong to a different company/group/role
				CALL ui.interface.frontcall("kandooCompanyName","setName",[glob_rec_company.name_text],[])
			END IF --no child apps must be running 

		ON ACTION "actClose" 
			IF nochilds() THEN 
				CALL cleanexit() EXIT program 
				EXIT MENU 
			END IF 

	END MENU 

END MAIN 
#############################################################################
# END MAIN
#############################################################################


##############################################################################
# FUNCTION run_cmd(itemId)
#
# Launch the child application including optional arguments AND userId/PW environment
##############################################################################
FUNCTION run_cmd(itemid) 
	DEFINE itemid INTEGER 
	DEFINE pos INTEGER 
	DEFINE recmenuitem RECORD LIKE qxt_menu_item.* 
	DEFINE runstr STRING 
	DEFINE runstrfinal STRING --including environment 
	DEFINE filenamecheck STRING 
	DEFINE l_msg STRING 

	#get all data about menuItem
	SELECT * INTO recmenuitem FROM qxt_menu_item WHERE mb_id = itemid 

	IF get_debug() THEN 
		DISPLAY "SQL recMenuItem ->", recmenuitem.* 
	END IF 

	#check rc_path_id existence
	IF recmenuitem.rc_path_id IS NOT NULL THEN 
		SELECT rc_path INTO recmenuitem.rc_path_cust FROM qxt_run_path WHERE rc_path_id=recmenuitem.rc_path_id 
	END IF 
	IF get_debug() THEN 
		DISPLAY "recMenuItem.rc_path_id=", trim(recMenuItem.rc_path_id) 
		DISPLAY "recMenuItem.rc_path_cust=", trim(recMenuItem.rc_path_cust) 
		DISPLAY "runStr = ", trim(runStr) 
	END IF 

	#check rc_arg_id existence
	IF recmenuitem.rc_arg_id IS NOT NULL THEN 
		SELECT rc_arg INTO recmenuitem.rc_arg_cust FROM qxt_run_arg WHERE rc_arg_id=recmenuitem.rc_arg_id 
	END IF 
	IF get_debug() THEN 
		DISPLAY "recMenuItem.rc_arg_id=", trim(recMenuItem.rc_arg_id) 
		DISPLAY "recMenuItem.rc_arg_cust=", trim(recMenuItem.rc_arg_cust) 
		DISPLAY "runStr = ", trim(runStr) 
	END IF 

	#create string FOR run child
	IF recmenuitem.rc_path_cust IS NULL OR length(recmenuitem.rc_path_cust)=0 THEN 
		LET runstr = recmenuitem.r_command CLIPPED --," ",recMenuItem.rc_arg_cust --# alch add argument on last stage

		IF get_debug() THEN 
			DISPLAY "recMenuItem.rc_path_cust IS NULL=", trim(recMenuItem.rc_path_cust IS null) 
			DISPLAY "length(recMenuItem.rc_path_cust)", trim(length(recMenuItem.rc_path_cust)) 
			DISPLAY "runStr = ", trim(runStr) 
		END IF 

	ELSE 
		#check IF path has a divider AT the END of the string
		IF recmenuitem.rc_path_cust[length(recmenuitem.rc_path_cust)] <> "/" THEN 
			LET recmenuitem.rc_path_cust = recmenuitem.rc_path_cust CLIPPED,"/" 
		END IF 

		LET runstr = recmenuitem.rc_path_cust clipped, recmenuitem.r_command CLIPPED --," ",recMenuItem.rc_arg_cust --# alch add argument on last stage
		IF get_debug() THEN 
			DISPLAY "recMenuItem.rc_path_cust=", trim(recMenuItem.rc_path_cust) 
			DISPLAY "recMenuItem.rc_path_cust", trim(recMenuItem.rc_path_cust) 
			DISPLAY "runStr = ", trim(runStr) 
		END IF 

	END IF 

	IF get_debug() THEN 
		DISPLAY "recMenuItem.rc_path_cust=", trim(recMenuItem.rc_path_cust) 
		DISPLAY "rrecMenuItem.r_command=", trim(recMenuItem.r_command) 
		DISPLAY "recMenuItem.rc_arg_cust=", trim(recMenuItem.rc_arg_cust) 
		DISPLAY "runStr = ", trim(runStr) 

	END IF 

	IF fgl_arch() = "nt" THEN 
		LET filenamecheck = trim(runstr) ,".exe"
		#check if file exists
		IF NOT os.path.exists(filenamecheck) THEN 
			LET l_msg = "The program file ", trim(filenamecheck), " does NOT exist on your application server!" 
			CALL fgl_winmessage("Program does NOT exist",l_msg,"error") 
		ELSE 
			#check if file IS executable
			IF os.path.executable(filenamecheck) THEN
				LET runstrfinal = "SET KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && SET KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && SET KANDOODB=", trim(get_ku_database_name()), " && ", trim(runstr) , " ", trim(recMenuItem.rc_arg_cust) CLIPPED
			ELSE 
				LET l_msg = "The program file ", trim(filenamecheck), " IS NOT executable ! Check your user/file permissions!" 
				CALL fgl_winmessage("Program does NOT executable",l_msg,"error") 
			END IF 
		END IF 
	ELSE --linux/unix 
		LET filenamecheck = trim(runstr) 
		#check if file exists
		IF NOT os.path.exists(filenamecheck) THEN 
			LET l_msg = "The program file ", trim(filenamecheck), " does NOT exist on your application server!" 
			CALL fgl_winmessage("Program does NOT exist",l_msg,"error") 
		ELSE 
			#check if file IS executable
			IF os.path.executable(filenamecheck) THEN 
				LET runstrfinal = "export KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && export KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && export KANDOODB=", trim(get_ku_database_name()), " && ", trim(runstr), " ", trim(recMenuItem.rc_arg_cust) CLIPPED 
			ELSE
				LET l_msg = "The program file ", trim(filenamecheck), " IS NOT executable ! Check your user/file permissions!" 
				CALL fgl_winmessage("Program does NOT executable",l_msg,"error") 
			END IF 
		END IF 

	END IF 

	IF get_debug() THEN 
		DISPLAY "---------------- 270----" 
		DISPLAY "->", trim(runStrFinal), "<-" 
		DISPLAY "get_ku_sign_on_code() = ", get_ku_sign_on_code() #GL_LOGIN_NAME 
		DISPLAY "get_ku_password_text() = ", get_ku_password_text() #GL_LOGIN_PASSWORD 
	END IF 

	CASE recmenuitem.mb_type 

		WHEN 2 --without waiting 
			#DISPLAY runStrFinal

			IF ui.interface.getchildcount() < get_settings_maxchildlaunch() THEN 
				--DISPLAY "RunString=", trim(runStrFinal)
				LET modu_last_run_str = runstrfinal #keep in history FOR debugging 
				RUN runstrfinal WITHOUT WAITING 
			ELSE 
				LET l_msg = "You have reached the maximum number of programs! (", trim(ui.interface.getchildcount()), ")\nPlease close any running program to run this program.\nNote: You can change the limit in the application settings" 
				CALL fgl_winmessage("You reached the max number of running programs",l_msg,"error") 
			END IF 

		WHEN 3 --run with wait 
			RUN runstrfinal 

	END CASE 

END FUNCTION 
##############################################################################
# END FUNCTION run_cmd(itemId)
##############################################################################


#########################################################
# This setUserEnvironment() seems no longer be used 21.03.2019 HuHo
#########################################################
# NEEDS CHECKING, FIXING, SORTING... I can NOT even see a user-group/role permission table yet... everything seems TO be related TO the menu path which restricts us in too many ways
#########################################################
# FUNCTION setUserEnvironment()
#########################################################
FUNCTION setuserenvironment(l_recuserenvironment) 
	DEFINE l_recuserenvironment RECORD LIKE kandoouser.* 

	CALL fgl_winmessage("check adn adopt","check in adopt","info") 
	IF get_debug() = true THEN 
		DISPLAY "-----------------------457---------" 
		DISPLAY "FUNCTION setUserEnvironment(l_recUserEnvironment)" 
		DISPLAY "get_ku_sign_on_code() = ", get_ku_sign_on_code() #GL_LOGIN_NAME 
		DISPLAY "get_ku_password_text() = ", get_ku_password_text() #GL_LOGIN_PASSWORD 

	END IF 

	SELECT 1 FROM kandoouser WHERE passwd_ind > 0 AND sign_on_code = glob_rec_kandoouser.sign_on_code #original = u_id = gl_login_user_id #original qxt was u_active=1 - in kandoouser passwd_ind=0 means,user account IS disabled (1/2 = enabled with AND WITHOUT password requirement 

	#	SELECT 1 FROM kandoouser u, kandoouser_group ug WHERE u.u_id = GL_LOGIN_USER_ID
	#										AND ug.group_id = u.group_id
	#										AND ug.group_active = 1
	IF status=notfound THEN 
						{
		#we need TO address this too
							CALL fgl_winmessage("Login","User Group IS Inactive!(1)","info")
							EXIT PROGRAM
						}
	END IF 


END FUNCTION 
#########################################################
# END FUNCTION setUserEnvironment()
#########################################################


#########################################################
# This passwordExpirDateValidation() seems no longer be used 21.03.2019 HuHo
#########################################################
# NEEDS CHECKING, FIXING, SORTING... I can NOT even see a
#########################################################
# FUNCTION passwordExpirDateValidation()
#
#
#########################################################
FUNCTION passwordexpirdatevalidation() 
	DEFINE pwdchangeflag SMALLINT 
	DEFINE u_log LIKE kandoouser.login_name 
	DEFINE u_expiredays INTEGER 
	DEFINE pwdchangeddate DATE 


	SELECT u_pwchange,u_login_name, u_pwexpdays,u_pwchdate 
	INTO pwdchangeflag,u_log,u_expiredays,pwdchangeddate 
	FROM qxt_user WHERE u_id = gl_login_user_id 

	IF pwdchangeflag = 1 THEN #if expired =1 OPEN FORM TO change password 
		CALL changepassword(u_log) 
	ELSE #expired =0 - CHECK expired BY days 
		IF u_expiredays IS NULL OR u_expiredays=0 THEN 
			#WHEN user expiredays IS NOT defined THEN look AT the global expiredays
			#SELECT gl_pwExpDays INTO u_expireDays FROM qxt_database_info WHERE db_id = (SELECT kandoo(db_id) FROM qxt_database_info)
			SELECT gl_pwexpdays INTO u_expiredays FROM qxt_database_info WHERE db_id = (SELECT kandoo(db_id) FROM qxt_database_info) 
		END IF 
		IF today - pwdchangeddate >= u_expiredays THEN 
			CALL changepassword(u_log) 
		END IF 
	END IF 
END FUNCTION 
#########################################################
# END FUNCTION passwordExpirDateValidation()
#########################################################


#########################################################
# FUNCTION changePassword(u_log)
#
#
#########################################################
FUNCTION changepassword(u_log) 
	DEFINE l_password LIKE kandoouser.password_text 
	DEFINE l_pass_conf LIKE kandoouser.password_text
	DEFINE u_log LIKE kandoouser.login_name 
	OPEN WINDOW ch_pwd with FORM "_qxt_toolbox/demo/form/kandoo_change_pwd" 
	DISPLAY BY NAME u_log 
	INPUT BY NAME l_password, l_pass_conf 
		AFTER FIELD l_pass_conf NEXT FIELD l_password 
		ON ACTION accept 
			CALL fgl_dialog_update_data() 
			IF length(l_password)<6 THEN 
				CALL fgl_winmessage("l_password confirmation","l_password IS shorter than 6 characters","Stop") 
				CONTINUE INPUT 
			END IF 
			
			IF l_password<>l_pass_conf OR length(l_password)<>length(l_pass_conf) THEN 
				CALL fgl_winmessage("l_password confirmation","Please make sure your passwords match.","Stop") 
				CONTINUE INPUT 
			ELSE 

				# original qxt l_password change
				#UPDATE qxt_user SET u_password = l_password,
				#				u_pwChDate = TODAY,
				#				u_pwChange = 0
				#		WHERE u_id = GL_LOGIN_USER_ID

				UPDATE kandoouser SET password_text = l_password, 
				u_pwchdate = today, 
				u_pwchange = 0 
				WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 



				IF status<>0 THEN 
					CALL fgl_winmessage("Used UPDATE","l_password was NOT changed due TO UPDATE failed","stop") 
					EXIT program 
				END IF 
				
				CALL fgl_winmessage("l_password confirmation","l_password changed.","info") 
				EXIT INPUT 
			END IF 
		
		ON ACTION CANCEL 
			CALL fgl_winmessage("l_password confirmation","l_password changing was skipped.","exclamation") 
			EXIT INPUT 
	END INPUT 

	CLOSE WINDOW ch_pwd 
END FUNCTION 
#########################################################
# END FUNCTION changePassword(u_log)
#########################################################


#########################################################
#Builds menu function FROM database						#
#
#
#########################################################
FUNCTION init_action_name(act_name) 
	DEFINE act_name STRING 

	INITIALIZE menuevent_global TO NULL 
	LET menuevent_global = ui.backgroundservereventhandler.create() 
	CALL menuevent_global.setcallbackaction(act_name) 

END FUNCTION 
#########################################################
# END Builds menu function FROM database						#
#########################################################


#########################################################
#Builds menu FUNCTION FROM database						#
#########################################################
FUNCTION buildmenu(m_parent_id) 
	DEFINE i INTEGER 
	DEFINE level_arr DYNAMIC ARRAY OF RECORD dbmenu_id INTEGER END RECORD 
		DEFINE m_item_id INTEGER, 
		m_parent_id INTEGER, 
		m_type SMALLINT, 
		m_label,m_img,m_tooltip CHAR(255) 
		DEFINE ishidden boolean 
		DEFINE menu_sql VARCHAR(1000) 
		DEFINE m_cur CURSOR 
		#If first buildmenu() call AND Not all menu items should be visible - then create table for needed menu items list

		IF m_parent_id=0 AND get_url_demo() THEN 
			CREATE temp TABLE exception_id( 
			mb_id INTEGER 
			) 
			CALL CreateListOfExceptions("[AGPU]*") 
		END IF 
		{ -- albo
		  LET menu_sql = "SELECT mi.mb_id,mi.mb_parent_id,mi.mb_type,mt.mb_label,",
							" mi.mb_image,mt.mb_tooltip,ga.ga_hidden"
		  IF NOT get_url_demo() THEN
				LET menu_sql = menu_sql CLIPPED, " FROM qxt_menu_item mi, qxt_menu_item_txt mt, menu_group_access ga",
											 " WHERE mi.mb_parent_id =", trim(m_parent_id)
		  ELSE
				LET menu_sql = menu_sql CLIPPED, " FROM qxt_menu_item mi, qxt_menu_item_txt mt, menu_group_access ga, exception_id ei",
											 " WHERE mi.mb_parent_id =", trim(m_parent_id),
											 " AND ei.mb_id = mi.mb_id"
		  END IF

		  LET menu_sql = menu_sql CLIPPED,	" AND mt.mb_id = mi.mb_id",
											" AND mt.lang_id = '", trim(glob_rec_kandoouser.language_code), "'",
											" AND ga.mb_id = mi.mb_id",
											" AND ga.group_code =", trim(glob_rec_kandoouser.menu_group_code),    #md_group_id,
											" ORDER BY mi.mb_parent_id,mi.mb_location,mt.mb_label"
		}

		LET menu_sql = "SELECT mi.mb_id,mi.mb_parent_id,mi.mb_type,mt.mb_label,", -- albo 
		" mi.mb_image,mt.mb_tooltip" 
		IF NOT get_url_demo() THEN 
			LET menu_sql = menu_sql clipped, " FROM qxt_menu_item mi, qxt_menu_item_txt mt", -- albo 
			" WHERE mi.mb_parent_id =", trim(m_parent_id) 
		ELSE 
			LET menu_sql = menu_sql clipped, " FROM qxt_menu_item mi, qxt_menu_item_txt mt, exception_id ei", -- albo 
			" WHERE mi.mb_parent_id =", trim(m_parent_id), 
			" AND ei.mb_id = mi.mb_id" 
		END IF 

		LET menu_sql = menu_sql clipped, " AND mt.mb_id = mi.mb_id", -- albo 
		" AND mt.lang_id = '", trim(glob_rec_kandoouser.language_code), "'", 
		" ORDER BY mi.mb_parent_id,mi.mb_location,mt.mb_label" 

		LET i = 0 
		CALL m_cur.declare(menu_sql) 
		CALL m_cur.setresults(m_item_id,m_parent_id,m_type,m_label,m_img,m_tooltip) --,ishidden --albo 
		CALL m_cur.open() 
		WHILE m_cur.foreach() = 0 
			--	IF isHidden THEN CONTINUE FOREACH END IF  -- albo
			CASE m_type 
				WHEN 0 --menugroup tag opens AND GO inside TO read nested elements alpr 
					LET menufile = menufile, '<MenuGroup text="',m_label CLIPPED,'" identifier="',trim(m_item_id),'">' 
					CALL buildmenu(m_item_id) 
					LET menufile = menufile,'</MenuGroup>' 
				OTHERWISE --menu COMMAND created alpr 
					LET menufile = menufile,'<MenuCommand text="',m_label CLIPPED,'" identifier="',trim(m_item_id),'"><MenuCommand.onInvoke><ActionEventHandler waitChild="true" type="actioneventhandler" actionName="actCmdInvoke"/></MenuCommand.onInvoke></MenuCommand>' 
			END CASE 
		END WHILE 
		CALL m_cur.close() 
		CALL m_cur.free() 
END FUNCTION 
#########################################################
# END Builds menu function FROM database						#
#########################################################


#########################################################
# FUNCTION buildmenu_new(p_parent_id)
# This function has been rebuilt because the previous one is too slow
#
#########################################################
FUNCTION buildmenu_new(p_parent_id) 
	DEFINE t_rec_menu_item TYPE AS RECORD
		item_id LIKE qxt_menu_item.mb_id,
		parent_id LIKE qxt_menu_item.mb_parent_id,
		mtype LIKE qxt_menu_item.mb_type,
		mlabel LIKE qxt_menu_item_txt.mb_label,
		img  LIKE qxt_menu_item.mb_image,
		tooltip LIKE qxt_menu_item_txt.mb_tooltip,
		location LIKE qxt_menu_item.mb_location,
		level LIKE qxt_menu_item.mb_level
	END RECORD
#	mb_id,mb_parent_id,mb_type,mb_label,mb_image,mb_tooltip,mb_location
	DEFINE p_parent_id LIKE qxt_menu_item.mb_parent_id
	DEFINE i INTEGER
	DEFINE l_former_level INTEGER
	DEFINE items_nbr_in_group INTEGER 
	DEFINE is_in_group BOOLEAN
	DEFINE level_arr DYNAMIC ARRAY OF RECORD dbmenu_id INTEGER END RECORD
	DEFINE parents_array  DYNAMIC ARRAY OF INTEGER
	DEFINE l_rec_top_level t_rec_menu_item
	DEFINE l_rec_exp_level t_rec_menu_item
	DEFINE record_number SMALLINT 
	DEFINE ishidden boolean 
	DEFINE sql_stmt STRING
	DEFINE menu_sql STRING
	DEFINE crs_toplvel CURSOR 
	DEFINE crs_explore_level CURSOR
	DEFINE m_cur CURSOR
	DEFINE prp_createtbl PREPARED
	
		#If first buildmenu() call AND Not all menu items should be visible - then create table for needed menu items list

		--IF l_low_parent_id=0 AND get_url_demo() THEN 
		--	CREATE temp TABLE exception_id( 
		--	mb_id INTEGER 
		--	) 
		--	CALL CreateListOfExceptions("[AGPU]*") 
		--END IF 

		# Create the "temp" table containing the join on qxt_menu_item and qxt_menu_item_txt
		#  because queries using 'CONNECT BY' do not support joins
		WHENEVER SQLERROR CONTINUE
		DROP TABLE my_menu
		WHENEVER SQLERROR STOP
		
		# Pre-build the join into one table
		LET sql_stmt = 	
		"SELECT i.mb_id,i.mb_parent_id,i.mb_type,t.mb_label,i.mb_image,t.mb_tooltip,i.mb_location,i.mb_level ",
		"FROM qxt_menu_item i,qxt_menu_item_txt t ",
--		" WHERE t.mb_id = i.mb_id AND t.lang_id = '",glob_rec_kandoouser.language_code,"'",
		" WHERE t.mb_id = i.mb_id ",
		" INTO TEMP my_menu"
		CALL prp_createtbl.Prepare(sql_stmt)
		CALL prp_createtbl.Execute()
		create index mymenu_1 on my_menu (mb_parent_id,mb_id)
		create index mymenu_2 on my_menu (mb_id,mb_label)
		CALL prp_createtbl.Free()
		
		# Prepare the SELECT ... CONNECT BY Statement
		LET sql_stmt = "SELECT mb_id,mb_parent_id,mb_type,mb_label,mb_image,mb_tooltip,mb_location,mb_level ",
		" FROM my_menu ",
		" START WITH mb_id = ? ",
		" CONNECT BY NOCYCLE PRIOR mb_id =  mb_parent_id ",
		" ORDER SIBLINGS BY mb_parent_id,mb_label,mb_location"
		CALL crs_explore_level.Declare(sql_stmt)

		# Because there is no column in the tables that gives absolute order, we need to select the top level items, then explore with CONNECT BY / START WITH
		CALL crs_toplvel.Declare ("SELECT mb_id,mb_label,mb_location FROM my_menu WHERE mb_parent_id = 0 ORDER BY mb_location,mb_id")
		CALL crs_toplvel.Open()
		LET i = 1

		WHILE crs_toplvel.FetchNext(l_rec_top_level.item_id,l_rec_top_level.mlabel,l_rec_top_level.location) <> 100
			# Explore the top level starting with l_rec_top_level.item_id
			CALL crs_explore_level.Open(l_rec_top_level.item_id)
			LET record_number = 0
			WHILE crs_explore_level.FetchNext(l_rec_exp_level.*) <> 100
				LET record_number = record_number + 1
				CASE l_rec_exp_level.level
					WHEN 10			#lowest level: this is a command
						LET menufile = menufile,'<MenuCommand text="',l_rec_exp_level.mlabel CLIPPED,'" identifier="',trim(l_rec_exp_level.item_id),'"><MenuCommand.onInvoke><ActionEventHandler waitChild="true" type="actioneventhandler" actionName="actCmdInvoke"/></MenuCommand.onInvoke></MenuCommand>'
					OTHERWISE
						IF l_rec_exp_level.level <= l_former_level AND record_number > 1 THEN		# avoid the very first row
							LET menufile = menufile,'</MenuGroup>'
						END IF
						LET menufile = menufile, '<MenuGroup text="',l_rec_exp_level.mlabel CLIPPED,'" identifier="',trim(l_rec_exp_level.item_id),'">'
						LET l_former_level = l_rec_exp_level.level
				END CASE
			END WHILE
			#IF is_in_group = true THEN
			LET menufile = menufile,'</MenuGroup>'     # end of intermediary group
			LET menufile = menufile,'</MenuGroup>'		# end of group for this top level

			#	LET group_level = group_level - 1
			#END IF
		END WHILE
		CALL crs_toplvel.Close()
		CALL crs_toplvel.Free()
		CALL crs_explore_level.Close()
		CALL crs_explore_level.Free()
		DROP TABLE my_menu

END FUNCTION 
#########################################################
# END FUNCTION buildmenu_new(p_parent_id)
#########################################################


#################################################################################
# FUNCTION CreateListOfExceptions(mask)
#################################################################################
FUNCTION createlistofexceptions(mask) 
	DEFINE mask CHAR(10) 
	DEFINE t_mb_id INTEGER 
	DECLARE cur_excep CURSOR FOR 
	SELECT mb_id FROM qxt_menu_item WHERE r_command matches mask 
	FOREACH cur_excep INTO t_mb_id 
		CALL build_exept_relation(t_mb_id) 
	END FOREACH 
END FUNCTION 
#################################################################################
# END FUNCTION CreateListOfExceptions(mask)
#################################################################################


#################################################################################
# FUNCTION build_exept_relation(mb_id)
#
#
#################################################################################
FUNCTION build_exept_relation(mb_id) 
	DEFINE mb_id INTEGER 
	DEFINE parent_id INTEGER 

	#CHECK ON PRESENCE IN EXCEPTION LIST
	SELECT 1 FROM exception_id WHERE exception_id.mb_id=mb_id 
	#IF ID IS PRESENT - CLOSE RECURSION
	IF status=notfound THEN 
		INSERT INTO exception_id VALUES (mb_id) 
	ELSE 
		RETURN 
	END IF 

	#GET PARENT ITEM ID
	SELECT mb_parent_id INTO parent_id FROM qxt_menu_item WHERE qxt_menu_item.mb_id=mb_id 

	--INSERT INTO exception_id VALUES (mb_id)
	#IF ID IS ROOT THEN CLOSE RECURSION
	IF parent_id=0 THEN 
		RETURN 
	ELSE #or CONTINUE recursion 
		CALL build_exept_relation(parent_id) 
	END IF 

END FUNCTION 
#################################################################################
# END FUNCTION build_exept_relation(mb_id)
#################################################################################


#################################################################################
# FUNCTION addMenuItem(itemType,itemId,newItemId,miText,miImg,miTooltip)
#
#
#################################################################################
FUNCTION addmenuitem(itemtype,itemid,newitemid,mitext,miimg,mitooltip) 
	DEFINE mg ui.menugroup 
	DEFINE itemtype SERIAL 
	DEFINE milocal DYNAMIC ARRAY OF ui.menuitem 
	DEFINE itemid,newitemid INTEGER 
	DEFINE mitext,miimg,mitooltip CHAR(255) 

	IF itemid = 0 THEN --if root level, add root element 
		CALL mi_global.append(createelm(itemtype,newitemid,mitext,mitooltip,miimg)) 
		RETURN 
	END IF 
	LET mg = ui.menugroup.forname(itemid) 
	LET milocal = mg.getmenuitems() 
	CALL milocal.append(createelm(itemtype,newitemid,mitext,mitooltip,miimg)) 
	CALL mg.setmenuitems(milocal) 

END FUNCTION 
#################################################################################
# END FUNCTION addMenuItem(itemType,itemId,newItemId,miText,miImg,miTooltip)
#################################################################################


#########################################################
#Creates new element
#
#
#########################################################
FUNCTION createelm(newitemtype,item_id,item_text,item_tooltip,img) 
	DEFINE newitemtype SMALLINT 
	DEFINE item_id INTEGER 
	DEFINE mcnew ui.menucommand 
	DEFINE mgnew ui.menugroup 
	DEFINE msnew ui.menuseparator 
	DEFINE img LIKE qxt_menu_item.mb_image 
	DEFINE item_text LIKE qxt_menu_item_txt.mb_label 
	DEFINE item_tooltip LIKE qxt_menu_item_txt.mb_tooltip 

	CASE newitemtype 
		WHEN 0 
			LET mgnew = ui.menugroup.create(item_id) 
			CALL mgnew.settext(item_text) 
			CALL mgnew.settooltip(item_tooltip) 
			CALL mgnew.setimageid(img) 
			RETURN mgnew 
		WHEN 1 
			LET msnew = ui.menuseparator.create(item_id) 
			RETURN msnew 
		OTHERWISE 
			LET mcnew = ui.menucommand.create(item_id) 
			CALL mcnew.settext(item_text) 
			CALL mcnew.settooltip(item_tooltip) 
			CALL mcnew.setimageid(img) 
			CALL mcnew.setoninvoke(menuevent_global) 
			RETURN mcnew 
	END CASE 

END FUNCTION 
#########################################################
#END Creates new element
#########################################################


#########################################################
# FUNCTION cleanExit()
#########################################################
FUNCTION cleanexit() --huho 
	DEFINE t_now DATETIME year TO second 
	DEFINE durat INTERVAL hour TO minute 
	DEFINE l_msg STRING 
	DEFINE l_record_found SMALLINT 

	#We could add here some cleanup/log functionality
	#CALL db_disconnectProduction(gl_custname)  --DATABASE gl_custname
	#CALL db_connectAuth()
	#LET t_now =  CURRENT DAY TO SECOND
	#
	#UPDATE qxt_log_login SET logoutdt=t_now WHERE session_id = newSessionId
	#
	#LET durat = t_now - gl_loginDT CLIPPED
	#oginial code.. we already checked FOR existing child processes... don't need TO do it twice
	#LET l_msg = "Goodbye ",gl_catusr,"\nYour session duration was ",durat
	#CALL fgl_winmessage("Menu_2_0",l_msg, "info")
	#EXIT PROGRAM 0

END FUNCTION 
#########################################################
# END FUNCTION cleanExit()
#########################################################

#########################################################
# FUNCTION noChilds()
#
#
#########################################################
FUNCTION nochilds() 
	DEFINE l_msg CHAR(255) 

	IF ui.interface.getchildcount() > 0 THEN 
		LET l_msg = "You must close your child applications prior TO closing the parent-mdi host:\nNumber of child-applications currently running:", ui.interface.getchildcount() 
		CALL fgl_winmessage("Child Applications are still running",l_msg,"error") 
		ERROR "You must first EXIT/close all child programs." 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
#########################################################
# FUNCTION noChilds()
#########################################################


{
#################################################
FUNCTION checkIfUserIsLoggedIn(p_user,p_customer)
	DEFINE p_user VARCHAR(30)  --user login name
	DEFINE p_customer VARCHAR(30) --database
	DEFINE ret BOOLEAN --RETURN value IF user IS logged in

	LET ret=FALSE  --default init - user IS NOT logged in
	CALL db_disconnectAuth()  --CLOSE DATABASE				--close login database "auth"
	CALL db_connectProduction(p_customer)  --DATABASE gl_custname  --OPEN catpres/production database
#check, IF user IS already logged in
	SELECT catusr  FROM inf_log
      WHERE catusr=p_user
	IF sqlca.sqlcode != 100 THEN  --IF the user still exists in the log inf_log table, he IS still logged in - only single login IS allowed
		LET ret = TRUE  --RETURN TRUE IF user IS already logged in
#CALL fgl_winmessage("Inflairnet","You are already logged on!\nNote FOR my dear tester & user\nWe need different user accounts FOR testing OTHERWISE, our data get screwed","info")
#commented by huho TO overcome user login count - needs TO be cleaned on program EXIT
#EXIT PROGRAM 0  #hack
	END IF
	CALL db_disconnectProduction(p_customer)  --DATABASE gl_custname  --OPEN catpres/production database
	CALL db_connectAuth()  --CLOSE DATABASE				--close login database "auth"
	RETURN ret
END FUNCTION
}

#################################################
#Populates language combobox in the menu window	#
#################################################
FUNCTION populatelangcombo() 
	DEFINE cb ui.combobox 
	DEFINE lang_val INTEGER 
	DEFINE lang_txt CHAR(30) 

	LET cb = ui.Combobox.ForName("GL_LANG") 
	DECLARE cur_lang CURSOR FOR SELECT * FROM qxt_language ORDER BY lang_id 

	FOREACH cur_lang INTO lang_val,lang_txt 
		CALL cb.additem(lang_val,lang_txt) 
	END FOREACH 

END FUNCTION 
#########################################################
# END FUNCTION noChilds()
#########################################################