MAIN 

	DEFINE l_formname STRING 

	OPTIONS INPUT wrap 
	DEFER interrupt 
	#LET formName =  fgl_winprompt(0,0,"Enter Form File Name","",30,0)

	OPEN WINDOW wchooseform with FORM "G000-View-G-GL-Forms" 


	INPUT l_formname  WITHOUT DEFAULTS FROM formname 
		ON ACTION "ViewForm" 
			OPEN WINDOW wform with FORM l_formname 

			MENU 
				ON ACTION "Exit" 
					EXIT MENU 
			END MENU 

			CLOSE WINDOW wform 

	END INPUT 


END MAIN 

