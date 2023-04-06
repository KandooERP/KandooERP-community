MAIN 

	DEFINE formname STRING 

	OPTIONS INPUT wrap 
	DEFER interrupt 

	OPEN WINDOW wchooseform with FORM "TGW000_All_GW_Forms_Print" 


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

