FUNCTION RemoveFromItemsContainer(item)
  DEFINE item ui.AbstractUiElement
  DEFINE container ui.AbstractUiElement
  DEFINE itemsContainer ui.ItemsContainer
  DEFINE items DYNAMIC ARRAY OF ui.AbstractUiElement
  DEFINE itemsSize, i INT
  
  LET container = item.GetContainer()
  
  LET itemsContainer = container
  IF itemsContainer IS NULL THEN
    RETURN
  END IF
  
  LET items = itemsContainer.getItems()
  LET itemsSize = items.getSize() + 1
  
  FOR i = 1 TO itemsSize
    IF items[i].getIdentifier() = item.getIdentifier() THEN
      CALL items.delete(i)
      EXIT FOR
    END IF
  END FOR  
  
  CALL itemsContainer.setItems(items)
  
END FUNCTION

FUNCTION SetToParent(item)
  DEFINE item ui.AbstractUiElement
  DEFINE tableColumn ui.TableColumn
  
  LET tableColumn = item.GetContainer()
  
  IF tableColumn IS NOT NULL THEN
    CALL tableColumn.setEditControl(item)  
  END IF  
END FUNCTION