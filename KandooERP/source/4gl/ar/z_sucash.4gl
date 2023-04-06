MAIN 
	DEFINE i int 
	DEFINE arg_str STRING 
	LET arg_str = "List of received arguments: " 
	FOR i = 1 TO num_args() 
		LET arg_str = arg_str, "arg_val(", trim(i), ") =", trim(arg_val(i)), " " 
		DISPLAY arg_val(i) 
	END FOR 
	CALL fgl_winmessage("Missing Sources","The sources for this program are missing!\nIt was called from the menu S|1|5|G|Cash Receipt Edit||1|sucash|||||\nOR\nfrom A63 ","error") 

	MENU 
		ON ACTION "EXIT" 
			EXIT MENU 
	END MENU 
END MAIN 
