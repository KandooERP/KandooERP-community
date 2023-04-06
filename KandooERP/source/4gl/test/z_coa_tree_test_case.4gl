
###############################################################################################
# Module Scope
###############################################################################################	
--database kandoodb_test@kandoo_ref_tcp
database kandoo_dev@kandoo_dev_tcp
DEFINE tree DYNAMIC ARRAY OF RECORD
    description LIKE coatempltdetl.description,
    parentId LIKE coatempltdetl.acct_code,
    id LIKE coatempltdetl.acct_code
END RECORD


DEFINE glArrayId SMALLINT

#Table coatempltdetl	
DEFINE typeCoaTemplt TYPE AS RECORD
	acct_code LIKE coatempltdetl.acct_code,          
	description LIKE coatempltdetl.description, 
	create_code SMALLINT,                                                                               
	tree_level LIKE coatempltdetl.tree_level, 
	acct_type LIKE coatempltdetl.acct_type
END RECORD




###############################################################################################
# MAIN
#
#
###############################################################################################	
MAIN
	DEFINE c INT
	DEFINE r INT
	DEFINE dnd ui.DragDrop
	
	DEFINE query_stmt STRING
	DEFINE current_level SMALLINT
	
	DEFINE idx INTEGER

	OPEN WINDOW winTreeTable WITH FORM "coa_tree"
	CALL tree.Clear()
	LET idx = 0
	LET tree[1].description = "1                 -Capital"
	LET tree[1].parentid = ""
	LET tree[1].id = "1"
	LET tree[2].description = "10                -Capital et réserves "
	LET tree[2].parentid = "1"
	LET tree[2].id = "10"
	LET tree[3].description = "101               -Capital"
	LET tree[3].parentid = "10"
	LET tree[3].id = "101"
	LET tree[4].description = "1011              -Capital souscrit - non appelé"
	LET tree[4].parentid = "101"
	LET tree[4].id = "1011"
	LET tree[5].description = "1012              -Capital souscrit - appelé, non versé"
	LET tree[5].parentid = "101"
	LET tree[5].id = "1012"
	LET tree[6].description = "1013              -Capital souscrit - appelé, versé"
	LET tree[6].parentid = "101"
	LET tree[6].id = "1013"
	LET tree[7].description = "10131             -Capital non amorti"
	LET tree[7].parentid = "1013"
	LET tree[7].id = "10131"
	LET tree[8].description = "10132             -Capital amorti"
	LET tree[8].parentid = "1013"
	LET tree[8].id = "10132"
	LET tree[9].description = "1018              -Capital souscrit soumis à des réglementations particulières"
	LET tree[9].parentid = "101"
	LET tree[9].id = "1018"


  DISPLAY ARRAY tree 
 -- WITHOUT DEFAULTS
  TO tree.* ATTRIBUTE(UNBUFFERED)

  BEFORE DISPLAY
    -- uncomment next row to enable multiple range selection
		CALL DIALOG.setSelectionMode("tree", 1)
		--CALL DIALOG.SetFieldActive("description", false)

#		CALL fgl_dialog_setkeylabel("Down","","{CONTEXT}/public/querix/icon/svg/12/ic_arrow_drop_down_blue_12px.svg",131,FALSE,"imageCollapsed")
#		CALL fgl_dialog_setkeylabel("Up","","{context}/public/querix/icon/svg/12/ic_arrow_drop_up_blue_12px.svg",132,FALSE,"imageExpanded")
#		CALL fgl_dialog_setkeylabel("Right","","{context}/public/querix/icon/svg/12/ic_arrow_drop_right_blue_12px.svg",133,FALSE,"imageLeaf")


#		CALL fgl_dialog_setkeylabel("deleteNode","Delete Node","{CONTEXT}/public/querix/icon/svg/24/ic_delete_24px.svg",21,FALSE,"Action Event <deletenode>")
#		CALL fgl_dialog_setkeylabel("insertNode","Insert Node","{CONTEXT}/public/querix/icon/svg/24/ic_add_24px.svg",22,FALSE,"Action Event <insertNode>")
#		CALL fgl_dialog_setkeylabel("appendNode","Append Node","{CONTEXT}/public/querix/icon/svg/24/ic_add_circle_24px.svg",23,FALSE,"Action Event <appendNode>")



	--if you want to see them.. just to show the 3 icons and their corresponding tree-properties
#		ON ACTION "Down"
#			CALL fgl_winmessage("Down","imageCollapsed=\"{context}/public/querix/icon/svg/12/ic_arrow_drop_down_blue_12px.svg\"","info")
#		ON ACTION "Up"
#			CALL fgl_winmessage("Up","imageExpanded=\"{context}/public/querix/icon/svg/12/ic_arrow_drop_up_blue_12px.svg\"","info")
#		ON ACTION "Right"
#			CALL fgl_winmessage("Right","imageLeaf=\"{context}/public/querix/icon/svg/12/ic_arrow_drop_right_blue_12px.svg\"","info")
{
    ON ACTION "deleteNode"
        LET r = arr_curr()
        CALL DIALOG.deleteNode("tree", r);

    ON ACTION "insertNode"
        LET r = arr_curr()
        IF r > 0 THEN
            CALL DIALOG.insertNode("tree", r);
            LET c = c + 1
            -- tree[r].parentId has been initialized in insertNode()
            LET tree[r].id = "c", c USING "<<<"
            LET tree[r].description = tree[r].id
        END IF

    ON ACTION "appendNode"
        LET c = c + 1
        LET r = arr_curr()
        LET r = DIALOG.appendNode("tree", r)
        -- tree[r].parentId has been initialized in appendNode()
        LET tree[r].id = "c", c USING "<<<"
        LET tree[r].description = tree[r].id

--    ON DROP(dnd)
--       CALL dnd.dropInternal()
}
    ON ACTION "HELP"
  		CALL onlineHelp("TreeTable",NULL)		
  		
    END DISPLAY

END MAIN




###############################################################################################
# FUNCTION FILL(max_level)
#
#
###############################################################################################	
FUNCTION FILL(max_level)
    DEFINE max_level, p INT
    CALL tree.clear()
    LET p = fill_tree(max_level, 1, 0, NULL)
END FUNCTION



