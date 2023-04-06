############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
DEFINE ts1 DATETIME year TO fraction(3) 
DEFINE dummy STRING 
FUNCTION translate_form (l_language,form_name) 
	DEFINE l_language LIKE attributes_translation.language 
	DEFINE form_name LIKE form_attributes.form_name 
	DEFINE lb ui.label 
	DEFINE arr_label DYNAMIC ARRAY OF ui.label 
	DEFINE lbi SMALLINT 

	DEFINE tf ui.textfield 
	DEFINE arr_textfield DYNAMIC ARRAY OF ui.textfield 
	DEFINE tfi SMALLINT 

	DEFINE tc ui.tablecolumn 
	DEFINE arr_tablecolumn DYNAMIC ARRAY OF ui.tablecolumn 
	DEFINE tci SMALLINT 

	DEFINE cb ui.combobox 
	DEFINE arr_combobox DYNAMIC ARRAY OF ui.combobox 
	DEFINE cbi SMALLINT 

	DEFINE gb ui.groupbox 
	DEFINE arr_groupbox DYNAMIC ARRAY OF ui.groupbox 
	DEFINE gbi SMALLINT 

	DEFINE kb ui.checkbox 
	DEFINE arr_checkbox DYNAMIC ARRAY OF ui.checkbox 
	DEFINE kbi SMALLINT 

	DEFINE former_id LIKE form_attributes.widget_id 
	DEFINE g_translation RECORD 
		widget_id LIKE form_attributes.widget_id, 
		widget_type LIKE form_attributes.widget_type, 
		attribute_type LIKE form_attributes.attribute_type, 
		translation LIKE attributes_translation.translation 
	END RECORD 
	LET former_id="XxXxXxx" 
	LET cbi=0 
	LET tfi=0 
	LET lbi=0 
	LET gbi=0 
	LET tci=0 

	DECLARE crs_translation CURSOR FOR 
	SELECT widget_id,widget_type,attribute_type, translation 
	FROM form_attributes f ,attributes_translation t 
	WHERE f.attribute_id = t.attribute_id 
	AND f.form_name = form_name 
	AND language = l_language 
	#ORDER BY widget_type

	LET former_id="XxXxXxx" 
	LET cbi=0 
	LET tfi=0 
	LET lbi=0 
	LET gbi=0 
	LET tci=0 
	LET ts1 = CURRENT 
	FOREACH crs_translation INTO g_translation.* 

		CASE 
			WHEN g_translation.widget_type = "Label" 
				LET lbi = lbi + 1 
				WHENEVER ERROR CONTINUE 
				LET lb = ui.label.forname(g_translation.widget_id) 
				CALL lb.settext(g_translation.translation) 
				WHENEVER ERROR stop 
			WHEN g_translation.widget_type = "TextField" 
				WHENEVER ERROR CONTINUE 
				LET tf = ui.textfield.forname(g_translation.widget_id) 
				CASE g_translation.attribute_type 
					WHEN "toolTip" 
						CALL tf.settooltip(g_translation.translation) 
					WHEN "comment" 
						CALL tf.setcomment(g_translation.translation) 
				END CASE 
				WHENEVER ERROR stop 

			WHEN g_translation.widget_type = "TableColumn" 
				WHENEVER ERROR CONTINUE 
				LET tc = ui.tablecolumn.forname(g_translation.widget_id) 
				CASE g_translation.attribute_type 
					WHEN "text" 
						CALL tc.settext(g_translation.translation) 
				END CASE 
				WHENEVER ERROR stop 

			WHEN g_translation.widget_type = "ComboBox" 
				LET cbi = cbi + 1 
				WHENEVER ERROR CONTINUE 
				LET cb = ui.combobox.forname(g_translation.widget_id) 
				CASE g_translation.attribute_type 
					WHEN "toolTip" 
						CALL cb.settooltip(g_translation.translation) 
					WHEN "comment" 
						LET cbi=cbi 
						CALL cb.setcomment(g_translation.translation) 
				END CASE 
				WHENEVER ERROR stop 
			WHEN g_translation.widget_type = "GroupBox" 
				WHENEVER ERROR CONTINUE 
				LET gb = ui.groupbox.forname(g_translation.widget_id) 
				CASE g_translation.attribute_type 
					WHEN "title" 
						CALL gb.settitle(g_translation.translation) 
				END CASE 

			WHEN g_translation.widget_type = "CheckBox" 
				CALL arr_checkbox.resize(gbi) 
				LET kb = ui.checkbox.forname(g_translation.widget_id) 
				LET kbi = kbi + 1 
				LET arr_checkbox[kbi] = kb 
				CALL arr_checkbox.resize(gbi) 
				WHENEVER ERROR stop 
			OTHERWISE 
				LET dummy = "widget not supported" 
		END CASE 

	END FOREACH 
	CLOSE crs_translation 
	FREE crs_translation 
END FUNCTION 
