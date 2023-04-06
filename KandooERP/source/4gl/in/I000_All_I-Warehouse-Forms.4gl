main

	DEFINE formName STRING
	
	OPTIONS INPUT WRAP
	DEFER INTERRUPT
	#LET formName =  fgl_winprompt(0,0,"Enter Form File Name","",30,0)
	
	OPEN WINDOW wChooseForm WITH FORM "I000-View-I-IN-Forms"
	

	INPUT BY NAME formName WITHOUT DEFAULTS
		ON ACTION "ViewForm"
			OPEN WINDOW wForm WITH FORM formName
			MENU
				ON ACTION "Exit"
					EXIT MENU
			END MENU
			CLOSE WINDOW wForm	
	
	END INPUT

	
END MAIN
	