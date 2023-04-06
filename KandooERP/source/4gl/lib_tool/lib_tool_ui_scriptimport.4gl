

#################################################################################
# FUNCTION loadDefaultJavaScript(p_script_option)
#
#
#################################################################################
FUNCTION loaddefaultjavascript(p_script_option) 
	DEFINE p_script_option SMALLINT 
	DEFINE msg STRING 

	CASE p_script_option 
		WHEN 0 --default 
--			IF NOT get_url_vdom() THEN 
				CALL ui.interface.frontcall("html5","scriptImport",["qx://application/scripts/messages.js","nowait"],[]) 
			--END IF 

		WHEN 1 
--			IF NOT get_url_vdom() THEN 
				CALL ui.interface.frontcall("html5","scriptImport",["qx://application/scripts/messages.js","nowait"],[]) 
--			END IF 

		WHEN 2 --v7 tranformer MENU 
--			IF NOT get_url_vdom() THEN 

				#CALL ui.interface.frontcall("html5","scriptImport",["qx://embedded/scripts/messages.js","nowait"],[])
				CALL ui.interface.frontcall("html5","scriptImport",["qx://application/scripts/messages.js","nowait"],[]) 
				CALL ui.interface.frontcall("html5","scriptImport",["{CONTEXT}/public/querix/js/transformers.js",""],[]) 
				CALL ui.interface.frontcall("html5","scriptImport",["qx://application/kandoo-company-name.js"],[])
--			END IF 

		WHEN 3 --v7 tranformer MENU FOR special sysadmin setup 
--			IF NOT get_url_vdom() THEN 

				#CALL ui.interface.frontcall("html5","scriptImport",["qx://embedded/scripts/messages.js","nowait"],[])
				CALL ui.interface.frontcall("html5","scriptImport",["qx://application/scripts/messages.js","nowait"],[]) 
				CALL ui.interface.frontcall("html5","scriptImport",["{CONTEXT}/public/querix/js/transformers.js",""],[]) 
				CALL ui.interface.frontcall("html5","scriptImport",["qx://application/kandoo-company-name.js"],[])
--			END IF 

		OTHERWISE 
			LET msg = "Invalid Argument in loadDefaultJavaScript\n", "Argument=", trim(p_script_option) 
			CALL fgl_winmessage("Invalid Argument in loadDefaultJavaScript",msg,"error") 

	END CASE 

END FUNCTION