-- Copy AbstractUiElement to AbstractUiElement
FUNCTION Copy_AbstractUiElement(src, dst)
  DEFINE src, dst ui.AbstractUiElement
  
  WHENEVER ERROR CONTINUE
  
  CALL dst.setClassNames(src.getClassNames())
  CALL dst.setBackground(src.getBackground())
  CALL dst.setForeColor(src.getForeColor())
  CALL dst.setFont(src.getFont())
  CALL dst.setLocation(src.getLocation())
  CALL dst.setSize(src.getSize())
  CALL dst.setPreferredSize(src.getPreferredSize())
  CALL dst.setMinSize(src.getMinSize())
  CALL dst.setMaxSize(src.getMaxSize())
  CALL dst.setNotNull(src.getNotNull())
  CALL dst.setPadding(src.getPadding())
  CALL dst.setMargin(src.getMargin())
  CALL dst.setCursor(src.getCursor())
  CALL dst.setLocale(src.getLocale())
  CALL dst.setVisible(src.getVisible())
  CALL dst.setCollapsed(src.getCollapsed())
  CALL dst.setEnable(src.getEnable())
  CALL dst.setContextMenu(src.getContextMenu())
  CALL dst.setToolTip(src.getToolTip())
  CALL dst.setTabIndex(src.getTabIndex())
  CALL dst.setZOrder(src.getZOrder())
  CALL dst.setEnableBorder(src.getEnableBorder())
  CALL dst.setScaleType(src.getScaleType())
  CALL dst.setElementBorder(src.getElementBorder())
  CALL dst.setVerticalAlignment(src.getVerticalAlignment())
  CALL dst.setHorizontalAlignment(src.getHorizontalAlignment())
  CALL dst.setOnKeyDown(src.getOnKeyDown())
  CALL dst.setOnKeyUp(src.getOnKeyUp())
  CALL dst.setOnMouseDown(src.getOnMouseDown())
  CALL dst.setOnMouseUp(src.getOnMouseUp())
  CALL dst.setOnMouseMove(src.getOnMouseMove())
  CALL dst.setOnMouseEnter(src.getOnMouseEnter())
  CALL dst.setOnMouseHover(src.getOnMouseHover())
  CALL dst.setOnMouseExit(src.getOnMouseExit())
  CALL dst.setOnMouseWheel(src.getOnMouseWheel())
  CALL dst.setOnMouseDoubleClick(src.getOnMouseDoubleClick())
  CALL dst.setOnMouseClick(src.getOnMouseClick())
  CALL dst.setOnMenuDetect(src.getOnMenuDetect())
  CALL dst.setOnDragStart(src.getOnDragStart())
  CALL dst.setOnDragEnter(src.getOnDragEnter())
  CALL dst.setOnDragOver(src.getOnDragOver())
  CALL dst.setOnDragFinished(src.getOnDragFinished())
  CALL dst.setOnDrop(src.getOnDrop())
  CALL dst.setOnResize(src.getOnResize())
  CALL dst.setOnSelection(src.getOnSelection())
  CALL dst.setOnFocusIn(src.getOnFocusIn())
  CALL dst.setOnFocusOut(src.getOnFocusOut())
  CALL dst.setTextAlignment(src.getTextAlignment())
  CALL dst.setWrapper(src.getWrapper())
  CALL dst.setElementRole(src.getElementRole())
  CALL dst.setIsProtected(src.getIsProtected())
  CALL dst.setFocusable(src.getFocusable())
  CALL dst.setHasFocus(src.getHasFocus())
  CALL dst.setBorderPanelItemLocation(src.getBorderPanelItemLocation())
  CALL dst.setGridItemLocation(src.getGridItemLocation())
  CALL dst.setAllowDrag(src.getAllowDrag())
  CALL dst.setAllowDrop(src.getAllowDrop())
  CALL dst.setTrackSizes(src.getTrackSizes())
  CALL dst.setTrackLocation(src.getTrackLocation())
  CALL dst.setStyleClassName(src.getStyleClassName())
  CALL dst.setTarget(src.getTarget())
  CALL dst.setComment(src.getComment())
END FUNCTION


-- Copy AbstractField to AbstractField
FUNCTION Copy_AbstractField(src, dst)
  DEFINE src, dst ui.AbstractField
  
  CALL Copy_AbstractUiElement(src, dst)
  
  CALL dst.setReadOnly(src.getReadOnly())
  CALL dst.setOnValueChanged(src.getOnValueChanged())
  CALL dst.setOnTouched(src.getOnTouched())
  CALL dst.setInvokeAction(src.getInvokeAction())
END FUNCTION


-- Copy AbstractStringField to AbstractStringField
FUNCTION Copy_AbstractStringField(src, dst)
  DEFINE src, dst ui.AbstractStringField
  
  CALL Copy_AbstractField(src, dst)
  
  CALL dst.setText(src.getText())
END FUNCTION