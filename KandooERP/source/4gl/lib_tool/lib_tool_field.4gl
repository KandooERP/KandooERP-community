
{
FUNCTION set_fieldattribute_readonly(p_widget_identifier,p_state)
	DEFINE p_widget_identifier STRING
	DEFINE p_state boolean
	DEFINE tf ui.AbstractField
	LET tf = ui.AbstractField.ForName(p_widget_identifier)
	CALL tf.setreadonly(p_state)

#From Alexey P. produces runtime error The error code (-109043) was received. Object not initialised (not usually fatal).
--	DEFINE p_widget_identifier STRING
--	DEFINE p_state boolean
--	DEFINE tf ui.AbstractField
--	LET tf = ui.AbstractField.ForName(p_widget_identifier)
--	CALL tf.setreadonly(p_state)
END FUNCTION
}

FUNCTION set_fieldattribute_readonly(p_widget_identifier,p_state) 
	DEFINE p_widget_identifier STRING 
	DEFINE p_state boolean
	
	#Changed from API UI call to dialog fuction
	#have to invert argument 
	IF p_state = FALSE THEN
		LET p_state = TRUE
	ELSE
		LET p_state = FALSE	
	END IF
	
	CALL Dialog.setFieldActive(p_widget_identifier,p_state) 

{	 
	--DEFINE tf ui.AbstractTextField
	DEFINE cb1 ui.combobox
	DEFINE cb2 ui.textfield	 
	DEFINE anywidget ui.abstractuielement
	DEFINE tf ui.TextArea 

	WHENEVER ERROR CONTINUE 
	LET cb1 = ui.combobox.forname(p_widget_identifier) ---(p_widget_identifier) 
	LET cb2 = ui.combobox.forname(p_widget_identifier) --(p_widget_identifier) i can still SELECT this FIELD but you cannot modify it. / caip fiels compelitelly use noentry=true ahh - so, whati'm looking FOR IS noentry ( NOT readonly 
	CALL cb1.setreadonly(p_state) #let me revise the quire meoknt 
	CALL cb2.setreadonly(p_state) 
	
	LET tf = ui.textArea.forname(p_widget_identifier)
	CALL tf.setreadonly(p_state)
	WHENEVER ERROR stop 
}
END FUNCTION 




#CALL fgl_winmessage("needs implementing","UI API - needs implemeting")
#need some code TO SET this widget i.e. text OR combo TO read only

#END FUNCTION


{
MAIN
DEFINE cb ui.Combobox
DEFINE tf ui.TextArea
DEFINE f1, f2 STRING
OPEN WINDOW w WITH FORM "3284/3284_combo_readonly" ATTRIBUTE(BORDER)
LET  cb = ui.Combobox.Forname("f1")
LET tf = ui.TextArea.Forname("f2")
  	INPUT BY NAME f1,f2 WITHOUT DEFAULTS
  		ON ACTION "set_readonly"
  			 CALL cb.SetReadOnly(TRUE)
  			 CALL tf.SetReadOnly(TRUE)
  	    ON ACTION "unset_readonly"
  			 CALL cb.SetReadOnly(FALSE)
  			 CALL tf.SetReadOnly(FALSE)
    END INPUT
END MAIN

}