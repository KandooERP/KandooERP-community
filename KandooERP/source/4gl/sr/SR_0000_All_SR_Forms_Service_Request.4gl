MAIN 

	DEFINE formname,realformname STRING 

	OPTIONS INPUT wrap 
	DEFER interrupt 
	#LET formName =  fgl_winprompt(0,0,"Enter Form File Name","",30,0)

	OPEN WINDOW wchooseform with FORM "per/sr/SR_0000_All_SR_Forms_Service_Request" 


	INPUT BY NAME formname WITHOUT DEFAULTS 
		ON ACTION "ViewForm" 
			LET realformname = "per/sr/", trim(formname) 
			OPEN WINDOW wform with FORM realformname 
			MENU 
				ON ACTION "Exit" 
					EXIT MENU 
			END MENU 
			CLOSE WINDOW wform 

	END INPUT 


END MAIN 

