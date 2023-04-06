##################################################################################
# GLOBAL Scope Variables
##################################################################################
GLOBALS "../common/glob_GLOBALS.4gl"  

##########################################################################
# FUNCTION get_baseProgName()
#
#
##########################################################################
FUNCTION formtitleupdate() 
	DEFINE l_win WINDOW 
	DEFINE l_frm FORM 
	DEFINE l_strl_wintext STRING 

	#huho 23.02.2019
	#LET l_win = l_win.getCurrent()
	#LET strWinText = l_win.getText()
	#LET strWinText = strWinText, " - ", glob_title_desc
	#CALL l_win.setText(strWinText)
	#LET l_frm = l_win.getForm()
	#
	#DISPLAY strWinText TO header_text
	#
	#DISPLAY glob_title_desc  TO header_text
END FUNCTION 
##########################################################################
# END FUNCTION get_baseProgName()
##########################################################################


##########################################################################
# FUNCTION get_baseProgName()
#
#
##########################################################################
FUNCTION get_baseprogname() 
	DEFINE l_prg_name STRING 
	#huho ONLY base name IS wanted without any l_windows .exe file extension
	IF fgl_arch() = "nt" THEN --l_windows 
		LET l_prg_name = fgl_basename(arg_val(0),".exe") 
	ELSE --unix/lynux etc.. 
		LET l_prg_name = fgl_basename(arg_val(0)) 
	END IF 

	RETURN l_prg_name 
END FUNCTION 
##########################################################################
# END FUNCTION get_baseProgName()
##########################################################################