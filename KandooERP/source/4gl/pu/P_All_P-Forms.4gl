MAIN 

	DEFINE formname STRING 

	OPTIONS INPUT wrap 
	DEFER interrupt 
	#LET formName =  fgl_winprompt(0,0,"Enter Form File Name","",30,0)

	OPEN WINDOW wchooseform with FORM "A000-View-P-AP-Forms" 


	INPUT BY NAME formname WITHOUT DEFAULTS 
		ON ACTION "ViewForm" 
			OPEN WINDOW wform with FORM formname 
			MENU 
				ON ACTION "Exit" 
					EXIT MENU 
			END MENU 
			CLOSE WINDOW wform 

	END INPUT 


END MAIN 

