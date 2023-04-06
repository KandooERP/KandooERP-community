###############################################################################################
# Module Scope
###############################################################################################	
--database kandoodb_test@kandoo_ref_tcp
database kandoo_dev@kandoo_dev_tcp
DEFINE m_arr_tree DYNAMIC ARRAY OF RECORD
    description LIKE coatempltdetl.description,
    CreateAccount boolean,
    parentId LIKE coatempltdetl.acct_code,
    id LIKE coatempltdetl.acct_code
END RECORD

DEFINE m_arr_moreinfo DYNAMIC ARRAY OF RECORD
	desc_text NCHAR(80),
	acct_type CHAR(1)
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
	
	DEFINE a_parentid DYNAMIC ARRAY OF LIKE coatempltdetl.acct_code
	DEFINE query_stmt STRING
	DEFINE current_level SMALLINT
	
	DEFINE idx INTEGER
	DEFINE l_parentid,former_id,former_parentid LIKE coatempltdetl.acct_code

	OPEN WINDOW winTreeTable WITH FORM "coa_tree"
	--CALL ui_init(0)
	#CALL hideNavigation()

	CALL create_coa()
	
END MAIN
	
FUNCTION create_coa()
DEFINE l_cmpy_code LIKE company.cmpy_code
DEFINE l_country_code LIKE coatemplthead.country_code
DEFINE l_language_code LIKE coatemplthead.language_code
DEFINE l_start_year_num LIKE coa.start_year_num
DEFINE l_start_period_num LIKE coa.start_period_num
DEFINE l_end_year_num LIKE coa.end_year_num
DEFINE l_end_period_num LIKE coa.end_period_num
DEFINE l_padding_char CHAR(1)
DEFINE l_padding_length SMALLINT

	MENU "Create chart of accounts"
		COMMAND "Select COA template"
			CALL select_coa_template ()
			RETURNING l_cmpy_code,
				l_country_code,
				l_language_code,
				l_start_year_num,
				l_start_period_num,
				l_end_year_num,
				l_end_period_num,
				l_padding_char,
				l_padding_length
			 
		COMMAND "Validate and create COA"
			CALL validate_coa(l_cmpy_code,
				l_start_year_num,
				l_start_period_num,
				l_end_year_num,
				l_end_period_num,
				l_padding_char,
				l_padding_length)

				
		COMMAND "EXIT"
	END MENU
END FUNCTION  # create_coa

FUNCTION select_coa_template()
	DEFINE l_rec_coatemplthead RECORD LIKE coatemplthead.*
	DEFINE query_stmt STRING
	DEFINE l_cmpy_code LIKE coa.cmpy_code
	DEFINE l_padding_char CHAR(1)
	DEFINE l_padding_length SMALLINT
	DEFINE l_country_text LIKE country.country_text
	DEFINE l_language_text LIKE language.language_text
	
	DEFINE l_start_year_num LIKE coa.start_year_num
	DEFINE l_start_period_num LIKE coa.start_period_num
	DEFINE l_end_year_num LIKE coa.end_year_num
	DEFINE l_end_period_num LIKE coa.end_period_num
	DEFINE idx SMALLINT
	DEFINE a_parentid DYNAMIC ARRAY OF LIKE coatempltdetl.acct_code
	DEFINE current_level SMALLINT
	DEFINE l_parentid,former_id,former_parentid LIKE coatempltdetl.acct_code
	DEFINE l_rec_coatemplt RECORD
		acct_code LIKE coatempltdetl.acct_code,          
		description LIKE coatempltdetl.description, 
		tree_level char(2),
		acct_type LIKE coatempltdetl.acct_type
	END RECORD


	INPUT  l_cmpy_code,
		l_rec_coatemplthead.country_code,
		l_rec_coatemplthead.language_code,
		l_padding_char,
		l_padding_length,
		l_start_year_num,
		l_start_period_num,
		l_end_year_num,
		l_end_period_num
	FROM
		cmpy_code,
		country_code,
		language_code,
		padding_char,
		padding_length,
		start_year_num,
		start_period_num,
		end_year_num,
		end_period_num
		
		AFTER FIELD cmpy_code
			SELECT 
		AFTER FIELD country_code
			SELECT country_text
			INTO l_country_text
			FROM country
			WHERE country_code = l_rec_coatemplthead.country_code
			IF sqlca.sqlcode = 0 THEN
				DISPLAY l_country_text TO country_text
			ELSE
				ERROR "Country code does not exist"
				NEXT FIELD country_code
			END IF
		
		AFTER FIELD language_code
			SELECT language_text
			INTO l_language_text
			FROM language
			WHERE language_code = l_rec_coatemplthead.language_code
			IF sqlca.sqlcode = 0 THEN
				DISPLAY l_language_text TO language_text
			ELSE
				ERROR "Language code does not exist"
				NEXT FIELD language_code
			END IF
			
		AFTER INPUT
			SELECT country_code,language_code,description,"comments" --comments
			INTO l_rec_coatemplthead.country_code,l_rec_coatemplthead.language_code,l_rec_coatemplthead.description,l_rec_coatemplthead.comments
			FROM coatemplthead
			WHERE country_code = l_rec_coatemplthead.country_code
			AND language_code = l_rec_coatemplthead.language_code
			
			IF sqlca.sqlcode = 0 THEN
				DISPLAY BY NAME l_rec_coatemplthead.country_code,
					l_rec_coatemplthead.language_code,
					l_rec_coatemplthead.description --,
					--l_rec_coatemplthead.comments
			 ELSE
			 	ERROR "There is no coa template for these criteria, please choose another one"
			 	RETURN 1
			 END IF	 
		
	END INPUT

	# Now display the template in the tree view
	CALL m_arr_tree.Clear()
	DECLARE crs_scan_coatempldetldetl CURSOR FOR
	SELECT acct_code,description,tree_level,acct_type 
	FROM coatempltdetl 
	WHERE country_code = l_rec_coatemplthead.country_code
	AND language_code = l_rec_coatemplthead.language_code 
	ORDER BY acct_code

  LET idx = 0
  LET current_level = 0
  LET l_parentid = NULL
	FOREACH crs_scan_coatempldetldetl INTO l_rec_coatemplt.*
		--IF l_rec_coatemplt.acct_code[1,1] <> "1" OR idx > 20 THEN
			--EXIT FOREACH
		--END IF 
		LET a_parentid[l_rec_coatemplt.tree_level] = l_rec_coatemplt.acct_code
		LET current_level = l_rec_coatemplt.tree_level
			
		LET idx = idx + 1
		LET m_arr_tree[idx].description = l_rec_coatemplt.acct_code,"-",l_rec_coatemplt.description
		LET m_arr_moreinfo[idx].desc_text = l_rec_coatemplt.description
		LET m_arr_moreinfo[idx].acct_type = l_rec_coatemplt.acct_type
	
		IF current_level > 1 THEN
			LET m_arr_tree[idx].parentId = a_parentid[current_level-1]
		ELSE
			LET m_arr_tree[idx].parentId = NULL
		END IF
		LET m_arr_tree[idx].id  = l_rec_coatemplt.acct_code
		
		# Preset createAccount to true
		LET m_arr_tree[idx].CreateAccount = true

  END FOREACH
  
  INPUT ARRAY m_arr_tree WITHOUT DEFAULTS
  FROM tree.* ATTRIBUTE(UNBUFFERED)

  BEFORE INPUT
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
  		
    END INPUT
	RETURN l_cmpy_code,
		l_rec_coatemplthead.country_code,
		l_rec_coatemplthead.language_code,
		l_start_year_num,
		l_start_period_num,
		l_end_year_num,
		l_end_period_num,
		l_padding_char,
		l_padding_length
END FUNCTION		# select_coa_template


FUNCTION validate_coa (p_cmpy_code,p_start_year_num,p_start_period_num,p_end_year_num,p_end_period_num,p_padding_char,p_padding_length)
DEFINE idx SMALLINT
DEFINE p_cmpy_code LIKE coa.cmpy_code
DEFINE p_start_year_num LIKE coa.start_year_num
DEFINE p_start_period_num LIKE coa.start_period_num
DEFINE p_end_year_num LIKE coa.end_year_num
DEFINE p_end_period_num LIKE coa.end_period_num
DEFINE p_padding_char CHAR(1)
DEFINE p_padding_length SMALLINT
DEFINE l_acct_code LIKE coa.acct_code
DEFINE nb_created_accounts SMALLINT

LET nb_created_accounts = 0
FOR idx = 1 TO m_arr_tree.Getsize()
	IF m_arr_tree[idx].CreateAccount = true THEN
		# prepare acct_code by padding with the padding char
		LET l_acct_code = m_arr_tree[idx].id
		
		INSERT INTO coa (cmpy_code,acct_code,desc_text,start_year_num,start_period_num,end_year_num,end_period_num,type_ind)
		VALUES
		(p_cmpy_code,l_acct_code,m_arr_moreinfo[idx].desc_text,p_start_year_num,p_start_period_num,p_end_year_num,p_end_period_num,m_arr_moreinfo[idx].acct_type)
		IF sqlca.sqlcode = 0 THEN
			LET nb_created_accounts = nb_created_accounts + 1
		ELSE
			ERROR "Skip this row",m_arr_tree[idx].id
		END IF
	END IF
END FOR
ERROR "Number of accounts created ",nb_created_accounts
END FUNCTION

###############################################################################################
# FUNCTION FILL(max_level)
#
#
###############################################################################################	
FUNCTION FILL(max_level)
    DEFINE max_level, p INT
    CALL m_arr_tree.clear()
    LET p = fill_tree(max_level, 1, 0, NULL)
END FUNCTION



