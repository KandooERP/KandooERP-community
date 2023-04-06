MAIN 

	DEFINE formname STRING 

	OPTIONS INPUT wrap 
	DEFER interrupt 

	OPEN WINDOW wchooseform with FORM "Q000-View-Q-QE-Forms" 


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

