
#################################################################################
# ComboBox to TextField
#
#
#################################################################################
# LOST Properties from ComboBox: ComboBoxItems, Editable,
# UNSET Properties in TextField: AllowNewlines, InvisibleValue, PlaceholderText, IsPasswordMask, Format, TextPicture, Editor
FUNCTION convert_combobox_to_textfield(comboboxident) 
	DEFINE comboboxident STRING 
	DEFINE combobox ui.combobox 
	DEFINE textfield ui.textfield 
	DEFINE container, tmpabs ui.abstractuielement 

	WHENEVER ERROR CONTINUE 
 
	LET combobox = ui.combobox.forname(comboboxident) 

	IF combobox IS NULL THEN 
		RETURN 
	END IF 

	CALL removefromitemscontainer(combobox) 

	LET tmpAbs = combobox 

	LET container = tmpabs.getcontainer() 

	LET textfield = ui.textfield.create(combobox.getidentifier(), container.getidentifier()); 

	CALL copy_abstractstringfield(combobox, textfield); 

	IF combobox.getrequired() IS NOT NULL THEN 
		CALL textfield.setrequired(combobox.getrequired()) 
	END IF 

	IF combobox.getautonext() IS NOT NULL THEN 
		CALL textfield.setautonext(combobox.getautonext()) 
	END IF 

	IF combobox.gettocase() IS NOT NULL THEN 
		CALL textfield.settocase(combobox.gettocase()) 
	END IF 

	IF combobox.getmaxlength() IS NOT NULL THEN 
		CALL textfield.setmaxlength(combobox.getmaxlength()) 
	END IF 

	IF combobox.getlabeltext() IS NOT NULL THEN 
		CALL textfield.setlabeltext(combobox.getlabeltext()) 
	END IF 

	IF combobox.gethelpertext() IS NOT NULL THEN 
		CALL textfield.sethelpertext(combobox.gethelpertext()) 
	END IF 

	CALL settoparent(textfield) 
END FUNCTION 


#################################################################################
# TextField to ComboBox
#
#
#################################################################################

# LOST Properties from TextField: AllowNewlines, InvisibleValue, PlaceholderText, IsPasswordMask, Format, TextPicture, Editor
# UNSET Properties in ComboBox: ComboBoxItems, Editable
FUNCTION convert_textfield_to_combobox(textfieldident) 
	DEFINE textfieldident STRING 
	DEFINE textfield ui.textfield 
	DEFINE combobox ui.combobox 
	DEFINE container, tmpabs ui.abstractuielement 

	LET textfield = ui.textfield.forname(textfieldident) 

	IF textfield IS NULL THEN 
		RETURN 
	END IF 

	CALL removefromitemscontainer(textfield) 

	LET tmpabs = textfield 
	LET container = tmpabs.getcontainer() 

	LET combobox = ui.combobox.create(textfield.getidentifier(), container.getidentifier()); 

	CALL copy_abstractstringfield(textfield, combobox); 

	IF textfield.getrequired() IS NOT NULL THEN 
		CALL combobox.setrequired(textfield.getrequired()) 
	END IF 

	IF textfield.getautonext() IS NOT NULL THEN 
		CALL combobox.setautonext(textfield.getautonext()) 
	END IF 

	IF textfield.gettocase() IS NOT NULL THEN 
		CALL combobox.settocase(textfield.gettocase()) 
	END IF 

	IF textfield.getmaxlength() IS NOT NULL THEN 
		CALL combobox.setmaxlength(textfield.getmaxlength()) 
	END IF 

	IF textfield.getlabeltext() IS NOT NULL THEN 
		CALL combobox.setlabeltext(textfield.getlabeltext()) 
	END IF 

	IF textfield.gethelpertext() IS NOT NULL THEN 
		CALL combobox.sethelpertext(textfield.gethelpertext()) 
	END IF 

	CALL settoparent(combobox) 

	CALL convert_textfield_to_combobox(textfieldident) 
END FUNCTION 
