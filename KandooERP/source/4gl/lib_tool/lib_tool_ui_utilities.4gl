####################################################################
# FUNCTION removefromitemscontainer(p_item) 
#
#
####################################################################
FUNCTION removefromitemscontainer(p_item) 
	DEFINE p_item ui.abstractuielement 
	DEFINE container ui.abstractuielement 
	DEFINE itemscontainer ui.itemscontainer 
	DEFINE items DYNAMIC ARRAY OF ui.abstractuielement 
	DEFINE itemssize, i int 

	LET container = p_item.getcontainer() 

	LET itemscontainer = container 
	IF itemscontainer IS NULL THEN 
		RETURN 
	END IF 

	LET items = itemscontainer.getitems() 
	LET itemssize = items.getsize() + 1 

	FOR i = 1 TO itemssize 
		IF items[i].getidentifier() = p_item.getidentifier() THEN 
			CALL items.delete(i) 
			EXIT FOR 
		END IF 
	END FOR 

	CALL itemscontainer.setitems(items) 

END FUNCTION 
####################################################################
# END FUNCTION removefromitemscontainer(item) 
####################################################################


####################################################################
# FUNCTION settoparent(p_item) 
#
#
####################################################################
FUNCTION settoparent(p_item) 
	DEFINE p_item ui.abstractuielement 
	DEFINE tablecolumn ui.tablecolumn 

	LET tablecolumn = p_item.getcontainer() 

	IF tablecolumn IS NOT NULL THEN 
		CALL tablecolumn.seteditcontrol(p_item) 
	END IF 
END FUNCTION 
####################################################################
# END FUNCTION settoparent(p_item) 
####################################################################
