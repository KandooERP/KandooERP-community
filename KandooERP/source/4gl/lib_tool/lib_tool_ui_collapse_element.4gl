##########################################################################
##########################################################################
FUNCTION uiFormElementCollapse(p_ui_element_name,p_state)
	DEFINE p_ui_element_name STRING
	DEFINE p_state BOOLEAN

	CALL ui.AbstractUiElement.ForName(p_ui_element_name).SetCollapsed(p_state)

END FUNCTION

