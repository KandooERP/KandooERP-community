############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

DEFINE lasttoolbar RECORD 
	tb_proj_id LIKE qxt_toolbar.tb_proj_id, 
	tb_module_id LIKE qxt_toolbar.tb_module_id, 
	tb_menu_id LIKE qxt_toolbar.tb_menu_id 
END RECORD 

DEFINE t_tb type as RECORD 
	tb_action LIKE qxt_toolbar.tb_action, 
	tb_type LIKE qxt_toolbar.tb_type, 
	tb_scope LIKE qxt_toolbar.tb_scope, 
	tb_hide LIKE qxt_toolbar.tb_hide, 
	tb_label LIKE qxt_toolbar.tb_label, 
	tb_icon LIKE qxt_toolbar.tb_icon, 
	tb_position LIKE qxt_toolbar.tb_position, 
	tb_static LIKE qxt_toolbar.tb_static, 
	tb_tooltip LIKE qxt_toolbar.tb_tooltip ,
	tb_place LIKE qxt_toolbar.tb_place 
END RECORD 

############################################################
# FUNCTION set_toolbar(p_tb_proj_id,p_tb_module_id,p_tb_menu_id)
#
#
############################################################
FUNCTION set_toolbar(p_tb_proj_id,p_tb_module_id,p_tb_menu_id) 
	DEFINE p_tb_proj_id LIKE qxt_toolbar.tb_proj_id 
	DEFINE p_tb_module_id LIKE qxt_toolbar.tb_module_id 
	DEFINE p_tb_menu_id LIKE qxt_toolbar.tb_menu_id 

	#Keep lastToolbar properties FOR JIT toolbarManager
	LET lasttoolbar.tb_proj_id = p_tb_proj_id 
	LET lasttoolbar.tb_module_id = p_tb_module_id 
	LET lasttoolbar.tb_menu_id = p_tb_menu_id 

	CALL displaycurrenttoolbar(p_tb_module_id,p_tb_menu_id ) 
END FUNCTION 
############################################################
# END FUNCTION set_toolbar(p_tb_proj_id,p_tb_module_id,p_tb_menu_id)
############################################################


############################################################
# FUNCTION publish_toolbar(p_tb_proj_id,p_tb_module_id,p_tb_menu_id)
#
#
############################################################
FUNCTION publish_toolbar(p_tb_proj_id,p_tb_module_id,p_tb_menu_id) 
	DEFINE p_tb_proj_id LIKE qxt_toolbar.tb_proj_id 
	DEFINE p_tb_module_id LIKE qxt_toolbar.tb_module_id
	DEFINE p_tb_menu_id LIKE qxt_toolbar.tb_menu_id 
	DEFINE sql_stmt STRING 
	DEFINE i SMALLINT 

	#DEFINE tb DYNAMIC ARRAY OF t_tb  --toolbar RECORD type
	DEFINE tb OF t_tb 
	DEFINE toolbarinfostr STRING 
	#DISPLAY toolbar info TO statusbar during development work - helps the guy who customizes the toolbar
	#NOT FOR global toolbars as there IS usually no window/form displayed FOR debug text lbInfo

	#Keep lastToolbar properties FOR JIT toolbarManager
	LET lasttoolbar.tb_proj_id = p_tb_proj_id 
	LET lasttoolbar.tb_module_id = p_tb_module_id 
	LET lasttoolbar.tb_menu_id = p_tb_menu_id 

	CALL displaycurrenttoolbar(p_tb_module_id,p_tb_menu_id ) 
	#	IF p_tb_menu_id <> "global" THEN
	#		LET toolbarInfoStr= "ProgID: ", p_tb_module_id clipped, "    ----   MenuID:    ", p_tb_menu_id clipped
	#		DISPLAY toolbarInfoStr TO lbInfo2
	#	END IF

	#CALL fgl_winmessage("..","..","info")

	#	DEFINE tb DYNAMIC ARRAY OF RECORD
	#    tb_action LIKE qxt_toolbar.tb_action,
	#    tb_dialog LIKE qxt_toolbar.tb_dialog,
	#    tb_seperator   LIKE qxt_toolbar.tb_seperator,
	#    tb_del  LIKE qxt_toolbar.tb_del,
	#    tb_label LIKE qxt_toolbar.tb_label,
	#    tb_icon LIKE qxt_toolbar.tb_icon,
	#    tb_position LIKE qxt_toolbar.tb_position,
	#    tb_static  LIKE qxt_toolbar.tb_static,
	#    tb_tooltip LIKE qxt_toolbar.tb_tooltip
	#		END RECORD



	LET sql_stmt = "SELECT ", 
	"tb_action, ", 
	"tb_type, ", 
	"tb_scope, ", 
	"tb_hide, ", 
	"tb_label, ", 
	"tb_icon, ", 
	"tb_position, ", 
	"tb_static, ", 
	"tb_tooltip, ", 
	"tb_place ", 



	"FROM qxt_toolbar ", 
	"WHERE ", 
	"tb_proj_id = '", p_tb_proj_id , "' ", 
	"AND ", 
	"tb_module_id = '", p_tb_module_id , "' ", 
	"AND ", 
	"tb_menu_id = '", p_tb_menu_id , "' ", 
	#"AND ",
	#"tb_instance = ", p_instance , " ",
	#"AND ",
	#"qxt_tb.tbi_name = qxt_tbi.tbi_name ",
	"ORDER BY tb_position ASC " 

	PREPARE p_tb FROM sql_stmt 
	DECLARE c_tb CURSOR FOR p_tb 

	LET i = 1 
	FOREACH c_tb INTO tb.* 

		CALL draw_toolbar_button(tb.*) 
		LET i = i +1 
	END FOREACH 

	#May be thinking about launching the toolbarManager for any empty toolbar record
	#IF i = 1 THEN
	#	display "hello"
	#	CALL setupToolbar()
	#END IF

END FUNCTION 
############################################################
# END FUNCTION publish_toolbar(p_tb_proj_id,p_tb_module_id,p_tb_menu_id)
############################################################


############################################################
# FUNCTION draw_toolbar_button(tb)
#
#
############################################################
FUNCTION draw_toolbar_button(tb) 
	DEFINE tb OF t_tb 
	DEFINE tb_rootpath STRING 

	LET tb_rootpath = fgl_getenv("TOOLBAR_PATH") 

	#LET tb.tb_icon = "{CONTEXT}/public/kandoo/icon32/", trim(tb.tb_icon)
	LET tb.tb_icon = trim(tb_rootpath), trim(tb.tb_icon) 

	CASE tb.tb_type -- button OR divider 

		WHEN 0 -- button 

			CASE tb.tb_scope --dialog OR global 

				WHEN 0 --dialog/local 

					CASE tb.tb_hide --show OR remove button/divider 

						WHEN 0 --show 

							CALL fgl_dialog_setkeylabel(tb.tb_action, lstr(tb.tb_label), tb.tb_icon, tb.tb_position, tb.tb_static, lstr(tb.tb_tooltip), trim(tb.tb_place) ) 


						WHEN 1 --hide/remove 

							CALL fgl_dialog_setkeylabel(tb.tb_action,"") --tb.tb_label,tb.tb_icon,tb.tb_position, tb.tb_static,tb.tb_tooltip) 

					END CASE 


				WHEN 1 --global 

					CASE tb.tb_hide --show OR remove button/divider 

						WHEN 0 --show 

							CALL fgl_setkeylabel(tb.tb_action, lstr(tb.tb_label), tb.tb_icon, tb.tb_position, tb.tb_static, lstr(tb.tb_tooltip), trim(tb.tb_place) ) 

						WHEN 1 --hide/remove 
							CALL fgl_setkeylabel(tb.tb_action,"","") --tb.tb_label,tb.tb_icon,tb.tb_position, tb.tb_static,tb.tb_tooltip) 

					END CASE 

			END CASE 

		WHEN 1 -- divider 

			CASE tb.tb_scope --dialog OR global 

				WHEN 0 --dialog/local 

					CASE tb.tb_hide --show OR remove divider 

						WHEN 0 --show 

							CALL fgl_dialog_keydivider(tb.tb_position) 

						WHEN 1 --hide/remove 
							CALL fgl_dialog_clearkeydivider(tb.tb_position) 

					END CASE 

				WHEN 1 --global 

					CASE tb.tb_hide --show OR remove divider 

						WHEN 0 --show 

							CALL fgl_keydivider(tb.tb_position) 

						WHEN 1 --hide/remove 
							CALL fgl_clearkeydivider(tb.tb_position) 

					END CASE 

			END CASE 



	END CASE 

END FUNCTION 
############################################################
# END FUNCTION draw_toolbar_button(tb)
############################################################


############################################################
# FUNCTION get_lasttoolbar_proj_id()
#
#
############################################################
FUNCTION get_lasttoolbar_proj_id() 
	RETURN lasttoolbar.tb_proj_id 
END FUNCTION 
############################################################
# END FUNCTION get_lasttoolbar_proj_id()
############################################################


############################################################
# FUNCTION get_lasttoolbar_prog_id()
#
#
############################################################
FUNCTION get_lasttoolbar_prog_id() 
	RETURN lasttoolbar.tb_module_id 
END FUNCTION 
############################################################
# END FUNCTION get_lasttoolbar_prog_id()
############################################################


############################################################
# FUNCTION get_lasttoolbar_menu_id()
#
#
############################################################
FUNCTION get_lasttoolbar_menu_id() 
	RETURN lasttoolbar.tb_menu_id 
END FUNCTION 
############################################################
# END FUNCTION get_lasttoolbar_menu_id()
############################################################

{

    WHEN 1 --fgl_set_keylabel & fgl_dialog_setkeylabel
      IF tl_toolbar[id].dialog = 0 THEN
        CALL fgl_setkeylabel(tl_toolbar[id].event,lang_string,tl_toolbar[id].image,tl_toolbar[id].ord,tl_toolbar[id].stat)
        IF local_debug  THEN
          DISPLAY "fgl_setkeylabel(",tl_toolbar[id].event, " , ",lang_string, " , ",tl_toolbar[id].image," , ",tl_toolbar[id].ord," , ",tl_toolbar[id].stat ,")"
        END IF

      ELSE

        CALL fgl_dialog_setkeylabel(tl_toolbar[id].event,lang_string,tl_toolbar[id].image,tl_toolbar[id].ord,tl_toolbar[id].stat)

        IF local_debug THEN
          DISPLAY "fgl_dialog_setkeylabel(",tl_toolbar[id].event, " , ",lang_string, " , ", tl_toolbar[id].image," , ",tl_toolbar[id].ord," , ",tl_toolbar[id].stat ,")"
        END IF

      END IF

    WHEN 2 --REMOVE KEY LABELS USING fgl_set_keylabel & fgl_dialog_setkeylabel
      IF tl_toolbar[id].dialog = 0 THEN

        CALL fgl_setkeylabel(tl_toolbar[id].event,"","")

        IF local_debug THEN
          DISPLAY "remove global toolbar icon - fgl_setkeylabel(", tl_toolbar[id].event, ",\"\"", ")"
        END IF

      ELSE

        CALL fgl_dialog_setkeylabel(tl_toolbar[id].event,"","")

        IF local_debug THEN
          DISPLAY "remove dialog toolbar icon - fgl_dialog_setkeylabel(", tl_toolbar[id].event, ",\"\"", ")"
        END IF

      END IF

    WHEN 3 -- fgl_keydivider AND fgl_dialog_keydivider
      IF tl_toolbar[id].dialog = 0 THEN
        CALL fgl_keydivider(tl_toolbar[id].ord)
        IF local_debug THEN
          DISPLAY "fgl_keydivider(",tl_toolbar[id].ord , ")"
        END IF

      ELSE
        CALL fgl_dialog_keydivider(tl_toolbar[id].ord)
        IF local_debug THEN
          DISPLAY "fgl_dialog_keydivider(",tl_toolbar[id].ord , ")"
        END IF

      END IF


    WHEN 4 -- REMOVE fgl_keydivider AND fgl_dialog_keydivider
      IF tl_toolbar[id].dialog = 0 THEN
        CALL fgl_clearkeydivider(tl_toolbar[id].ord)

        IF local_debug THEN
          DISPLAY "fgl_clearkeydivider(",tl_toolbar[id].ord , ")"
        END IF

      ELSE
        CALL fgl_dialog_clearkeydivider(tl_toolbar[id].ord)

        IF local_debug THEN
          DISPLAY "fgl_dialog_clearkeydivider(",tl_toolbar[id].ord , ")"
        END IF

      END IF


    OTHERWISE
      LET tl_err_msg = get_str_tool(32), " draw_tb_icon()\ntl_toolbar[" , id , ".action ->" , tl_toolbar[id].action
      CALL fgl_winmessage(get_str_tool(30),tl_err_msg, "error")
  END CASE




END FUNCTION



# DEFINE qxt_toolbar DYNAMIC ARRAY OF RECORD LIKE  qxt_toolbar.*

###########################################################
# FUNCTION draw_toolbar(p_application_id,p_tb_name,p_instance, p_language_id)
#
# Publish a group of toolbar menu icons
#
# RETURN NONE
###########################################################
FUNCTION draw_toolbar(p_application_id,p_tb_name,p_instance, p_language_id)
  DEFINE
    p_application_id   LIKE qxt_tb.application_id,
    p_tb_name          LIKE qxt_tb.tb_name,
    p_instance         LIKE qxt_tb.tb_instance,
    p_language_id      LIKE qxt_language.language_id,
    l_toolbar_rec      OF t_qxt_toolbar_rec,
    sql_stmt           STRING, --CHAR(1000),
    p_tbi_rec          OF t_qxt_toolbar_item_rec,
    local_debug        SMALLINT

  LET local_debug = FALSE


  LET sql_stmt = "SELECT ",
    "qxt_tb.application_id, ",
    "qxt_tb.tb_name, ",
    "qxt_tb.tb_instance, ",
    "qxt_tb.tbi_name, ",
    "qxt_tbi.tbi_position ",
    "FROM qxt_tb , qxt_tbi ",
    "WHERE ",
    "qxt_tb.application_id = ", p_application_id , " ",
    "AND ",
    "tb_name = '", p_tb_name , "' ",
    "AND ",
    "tb_instance = ", p_instance , " ",
    "AND ",
    "qxt_tb.tbi_name = qxt_tbi.tbi_name ",
    "ORDER BY qxt_tbi.tbi_position ASC "

  PREPARE p_tb FROM sql_stmt
  DECLARE c_tb CURSOR FOR p_tb

  FOREACH c_tb INTO l_toolbar_rec.*
    CALL get_toolbar_item_rec(l_toolbar_rec.application_id,
                              l_toolbar_rec.tbi_name,
                              l_toolbar_rec.tb_instance,
                              p_language_id)
      RETURNING p_tbi_rec.*

    IF local_debug THEN
      DISPLAY "draw_toolbar() - l_toolbar_rec.application_id=", l_toolbar_rec.application_id
      DISPLAY "draw_toolbar() - l_toolbar_rec.tbi_name=", l_toolbar_rec.tbi_name
      DISPLAY "draw_toolbar() - l_toolbar_rec.tb_instance=", l_toolbar_rec.tb_instance
      DISPLAY "draw_toolbar() - p_language_id=", p_language_id
    END IF

    CALL draw_tb_icon(p_tbi_rec.*)
  END FOREACH

END FUNCTION

##################################################################
# FUNCTION validate_client_icon_file_existence(p_application_id,p_location)
#
# Validate IF the toolbar icons are located in the client cache OR on the server
# p_location 0 = server 1=client
#
# RETURN NONE
##################################################################
FUNCTION validate_client_icon_file_existence(p_application_id,p_location)
  DEFINE
    p_application_id    LIKE qxt_application.application_id,
    p_location          SMALLINT,  --0 = server 1=client cache
    l_icon_filename     LIKE qxt_tbi_obj.icon_filename,
    sql_stmt            CHAR(1000),
    err_msg             VARCHAR(200),
    local_debug         SMALLINT,
    validation_error    SMALLINT


  LET validation_error = FALSE

  IF p_location IS NULL THEN
    LET p_location = 0  --Server IS default
  END IF

  LET sql_stmt= "SELECT ",
                  "qxt_tbi_obj.icon_filename ",

                "FROM qxt_tb,qxt_tbi,qxt_tbi_obj ",
                "WHERE ",
                  "qxt_tb.application_id = ", trim(p_application_id), " ",
                "AND ",
                  "qxt_tb.tbi_name = qxt_tbi.tbi_name ",
                "AND ",
                  "qxt_tbi.tbi_obj_name = qxt_tbi_obj.tbi_obj_name "

  PREPARE p_icon FROM sql_stmt
  DECLARE c_icon CURSOR FOR p_icon

  FOREACH c_icon INTO l_icon_filename
#DISPLAY "Icon =", l_icon_filename
    CASE p_location
      WHEN 0 --Server check
        IF NOT validate_file_server_side_exists_advanced(get_tb_icon_path(l_icon_filename),"f",TRUE) THEN
          LET validation_error = TRUE
          IF yes_no("Validate icon existence on Application Server","Do you want TO abort ?") THEN
            EXIT FOREACH
          END IF
        END IF
      WHEN 1 --Client cache check
        IF NOT validate_file_client_side_cache_exists(get_tb_icon_path(l_icon_filename), NULL,TRUE) THEN
          LET validation_error = TRUE
          IF yes_no("Validate icon existence on Client Side Cache","Do you want TO abort ?") THEN
            EXIT FOREACH
          END IF
        END IF
      OTHERWISE
        LET err_msg = "Invalid argument in  validate_client_icon_file_cache()\nInvalid location was specified 0=Server 1=Client\np_location = ", p_location
        CALL fgl_winmessage("Invalid argument in  validate_client_icon_file_cache()",err_msg, "error")
    END CASE

    IF local_debug THEN
      DISPLAY "draw_toolbar() - l_icon_filename=", l_icon_filename
    END IF

  END FOREACH


  RETURN validation_error

END FUNCTION


##################################################################################
# FUNCTION draw_tb_icon()
#
# Draw a single menu item
#
# RETURN NONE
##################################################################################
FUNCTION draw_tb_icon(p_tbi_rec)
  DEFINE
    p_tbi_rec          OF t_qxt_toolbar_item_rec,
    lang_string        VARCHAR(100),
    id, local_debug    SMALLINT,
    err_msg            VARCHAR(200)

  LET local_debug = FALSE

  IF local_debug THEN
    DISPLAY "draw_tb_icon() - p_tbi_rec.event_type_id=", p_tbi_rec.event_type_id
    DISPLAY "draw_tb_icon() - p_tbi_rec.tbi_event_name=", p_tbi_rec.tbi_event_name
    DISPLAY "draw_tb_icon() - p_tbi_rec.tbi_obj_action_id=", p_tbi_rec.tbi_obj_action_id
    DISPLAY "draw_tb_icon() - p_tbi_rec.tbi_scope_id=", p_tbi_rec.tbi_scope_id
    DISPLAY "draw_tb_icon() - p_tbi_rec.tbi_position=", p_tbi_rec.tbi_position
    DISPLAY "draw_tb_icon() - p_tbi_rec.tbi_static_id=", p_tbi_rec.tbi_static_id
    DISPLAY "draw_tb_icon() - p_tbi_rec.icon_filename=", p_tbi_rec.icon_filename
    DISPLAY "draw_tb_icon() - p_tbi_rec.string_data=", p_tbi_rec.string_data

  END IF



  CASE p_tbi_rec.tbi_obj_action_id

    WHEN 1 --fgl_set_keylabel & fgl_dialog_setkeylabel

      CASE p_tbi_rec.event_type_id  --action OR key events

        WHEN 1 -- KEY Event
          IF p_tbi_rec.tbi_scope_id = 0 THEN
            CALL fgl_setkeylabel(p_tbi_rec.tbi_event_name,p_tbi_rec.string_data ,get_tb_icon_path(p_tbi_rec.icon_filename)  ,p_tbi_rec.tbi_position,p_tbi_rec.tbi_static_id)
            IF local_debug  THEN
              DISPLAY "fgl_setkeylabel(",trim(p_tbi_rec.tbi_event_name), ",", trim(p_tbi_rec.string_data),",",trim(get_tb_icon_path(p_tbi_rec.icon_filename)),",",trim(p_tbi_rec.tbi_position) , ",",trim(p_tbi_rec.tbi_static_id) ,")"
            END IF

          ELSE
            CALL fgl_dialog_setkeylabel(p_tbi_rec.tbi_event_name,p_tbi_rec.string_data ,get_tb_icon_path(p_tbi_rec.icon_filename)  ,p_tbi_rec.tbi_position,p_tbi_rec.tbi_static_id)
            IF local_debug  THEN
              DISPLAY "fgl_dialog_setkeylabel(",trim(p_tbi_rec.tbi_event_name), ",", trim(p_tbi_rec.string_data),",",trim(get_tb_icon_path(p_tbi_rec.icon_filename)),",",trim(p_tbi_rec.tbi_position) , ",",trim(p_tbi_rec.tbi_static_id) ,")"
            END IF

          END IF


        WHEN 2 -- ACTION Event
          IF p_tbi_rec.tbi_scope_id = 0 THEN
            CALL fgl_setactionlabel(p_tbi_rec.tbi_event_name,p_tbi_rec.string_data ,get_tb_icon_path(p_tbi_rec.icon_filename)  ,p_tbi_rec.tbi_position,p_tbi_rec.tbi_static_id)
            IF local_debug  THEN
              DISPLAY "fgl_setactionlabel(",trim(p_tbi_rec.tbi_event_name), ",", trim(p_tbi_rec.string_data),",",trim(get_tb_icon_path(p_tbi_rec.icon_filename)),",",trim(p_tbi_rec.tbi_position) , ",",trim(p_tbi_rec.tbi_static_id) ,")"
            END IF

          ELSE
            CALL fgl_dialog_setactionlabel(p_tbi_rec.tbi_event_name,p_tbi_rec.string_data ,get_tb_icon_path(p_tbi_rec.icon_filename)  ,p_tbi_rec.tbi_position,p_tbi_rec.tbi_static_id)
            IF local_debug  THEN
              DISPLAY "fgl_dialog_setactionlabel(",trim(p_tbi_rec.tbi_event_name), ",", trim(p_tbi_rec.string_data),",",trim(get_tb_icon_path(p_tbi_rec.icon_filename)),",",trim(p_tbi_rec.tbi_position) , ",",trim(p_tbi_rec.tbi_static_id) ,")"
            END IF

          END IF

        OTHERWISE
          LET err_msg = "Error in draw_tb_icon()\nInavlid Event Type !\np_tbi_rec.event_type_id =",p_tbi_rec.event_type_id
          CALL fgl_winmessage("Error in draw_tb_icon()",err_msg,"error")
      END CASE

    WHEN 2 --REMOVE KEY LABELS USING fgl_set_keylabel & fgl_dialog_setkeylabel
      IF p_tbi_rec.tbi_scope_id = 0 THEN

        CALL fgl_setkeylabel(p_tbi_rec.tbi_event_name,"")

        IF local_debug THEN
          DISPLAY "remove global toolbar icon - fgl_setkeylabel(", p_tbi_rec.tbi_event_name, ",\"\""
        END IF

      ELSE

        CALL fgl_dialog_setkeylabel(p_tbi_rec.tbi_event_name,"")

        IF local_debug THEN
          DISPLAY "remove dialog toolbar icon - fgl_dialog_setkeylabel(", p_tbi_rec.tbi_event_name, ",\"\""
        END IF

      END IF

    WHEN 3 -- fgl_keydivider AND fgl_dialog_keydivider
      IF p_tbi_rec.tbi_scope_id = 0 THEN
        CALL fgl_keydivider(p_tbi_rec.tbi_position)
        IF local_debug THEN
          DISPLAY "fgl_keydivider(",p_tbi_rec.tbi_position , ")"
        END IF

      ELSE
        CALL fgl_dialog_keydivider(p_tbi_rec.tbi_position)
        IF local_debug THEN
          DISPLAY "fgl_dialog_keydivider(",p_tbi_rec.tbi_position , ")"
        END IF

      END IF


    WHEN 4 -- REMOVE fgl_keydivider AND fgl_dialog_keydivider
      IF p_tbi_rec.tbi_scope_id = 0 THEN
        CALL fgl_clearkeydivider(p_tbi_rec.tbi_position)

        IF local_debug THEN
          DISPLAY "fgl_clearkeydivider(",p_tbi_rec.tbi_position , ")"
        END IF

      ELSE
        CALL fgl_dialog_clearkeydivider(p_tbi_rec.tbi_position)

        IF local_debug THEN
          DISPLAY "fgl_dialog_clearkeydivider(",p_tbi_rec.tbi_position , ")"
        END IF

      END IF

    OTHERWISE
      IF local_debug THEN
        LET err_msg = get_str_tool(32), " draw_tb_icon()\n Event->" , p_tbi_rec.tbi_event_name , ".action ->" , p_tbi_rec.tbi_obj_action_id
        CALL fgl_winmessage(get_str_tool(30),err_msg, "error")
      END IF

  END CASE

END FUNCTION
}