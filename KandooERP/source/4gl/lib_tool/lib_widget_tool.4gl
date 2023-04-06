##########################################################################
# cms-demo                                                               #
# Property of Querix Ltd.                                                #
# Copyright (C) 2016  Querix Ltd. All rights reserved.                   #
# This program IS free software: you can redistribute it.                #
# You may modify this program only using Lycia.                          #
#                                                                        #
# This program IS distributed in the hope that it will be useful,        #
# but without any warranty; without even the implied warranty of         #
# merchantability OR fitness for a particular purpose.                   #
#                                                                        #
# Email: info@querix.com                                                 #
##########################################################################

###############################################
#Function updateUILabel(widget_id, new_text)
#changes text in Radiobutton, Checkbox, Button, Label, TextArea,Calendar,Textfield, Timeeditfield, GroupBox
###############################################
FUNCTION updateuilabel(id,txt) 
	DEFINE id CHAR(100) 
	DEFINE txt CHAR(100) 
	DEFINE tabpage ui.tabpage --settitle() 
	DEFINE grpbbox ui.groupbox --settitle() 
	DEFINE abstractbool ui.abstractboolfield --settitle() 
	DEFINE abstractstring ui.abstractstringfield --settext() 

	LET abstractbool = ui.abstractboolfield.forname(id) 
	LET abstractstring = ui.abstractstringfield.forname(id) 
	LET grpbbox = ui.groupbox.forname(id) 
	LET tabpage = ui.tabpage.forname(id) 
	CASE 
		WHEN abstractbool IS NOT NULL CALL abstractbool.settitle(txt) 
		WHEN abstractstring IS NOT NULL CALL abstractstring.settext(txt) 
		WHEN grpbbox IS NOT NULL CALL grpbbox.settitle(txt) 
		WHEN tabpage IS NOT NULL CALL tabpage.settitle(txt) 
	END CASE 
END FUNCTION 

#######################################################
#FUNCTION UIRadButListItemText(RadButList_id,RadButListItem_Number,Item's_newText)
#changes text for RadioButtonListItem
#######################################################
FUNCTION uiradbutlistitemtext(listid,itemnum,txt) 
	DEFINE listid VARCHAR(100) 
	DEFINE itemnum INTEGER 
	DEFINE txt CHAR(100) 
	#DEFINE rbl ui.Radiobuttonlist
	#DEFINE rbli DYNAMIC ARRAY OF ui.RadioButtonListItem
	#
	#LET rbl=ui.RadioButtonList.ForName(ListId)
	#LET rbli=rbl.GetRadioButtonListItems()
	#CALL rbli[ItemNum].SetTitle(txt)
END FUNCTION 
