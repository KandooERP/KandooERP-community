-- LOST Properties from ComboBox: ComboBoxItems, Editable,
-- UNSET Properties in TextField: AllowNewlines, InvisibleValue, PlaceholderText, IsPasswordMask, Format, TextPicture, Editor
FUNCTION Convert_ComboBox_To_TextField(comboBoxIdent)
  DEFINE comboBoxIdent String
  DEFINE comboBox ui.ComboBox
  DEFINE textField ui.TextFIeld
  DEFINE container, tmpAbs ui.AbstractUiElement
  
  WHENEVER ERROR CONTINUE
  
  LET comboBox = ui.ComboBox.ForName(comboBoxIdent)
  
  IF comboBox IS NULL THEN
    RETURN
  END IF
  
  CALL RemoveFromItemsContainer(comboBox)
  
  LET tmpAbs = textField
  LET container = tmpAbs.GetContainer()
  
  LET textField = ui.TextFIeld.Create(comboBox.getIdentifier(), container.getIdentifier());
  
  CALL Copy_AbstractStringField(comboBox, textField);
    
  IF comboBox.getRequired() IS NOT NULL THEN
    CALL textField.setRequired(comboBox.getRequired())
  END IF
  
  IF comboBox.getAutonext() IS NOT NULL THEN
    CALL textField.setAutonext(comboBox.getAutonext())
  END IF
  
  IF comboBox.getToCase() IS NOT NULL THEN
    CALL textField.setToCase(comboBox.getToCase())
  END IF
  
  IF comboBox.getMaxLength() IS NOT NULL THEN
    CALL textField.setMaxLength(comboBox.getMaxLength())
  END IF
  
  IF comboBox.getLabelText() IS NOT NULL THEN
    CALL textField.setLabelText(comboBox.getLabelText())
  END IF
  
  IF comboBox.getHelperText() IS NOT NULL THEN
    CALL textField.setHelperText(comboBox.getHelperText())
  END IF
  
  CALL SetToParent(textField)
  
  CALL Convert_ComboBox_To_TextField(comboBoxIdent)
END FUNCTION