-- Copy AbstractUiElement to AbstractUiElement
FUNCTION copy_abstractuielement(src, dst) 
	DEFINE src, dst ui.abstractuielement 

	WHENEVER ERROR CONTINUE 

	CALL dst.setclassnames(src.getclassnames()) 
	CALL dst.setbackground(src.getbackground()) 
	CALL dst.setforecolor(src.getforecolor()) 
	CALL dst.setfont(src.getfont()) 
	CALL dst.setlocation(src.getlocation()) 
	CALL dst.setsize(src.getsize()) 
	CALL dst.setpreferredsize(src.getpreferredsize()) 
	CALL dst.setminsize(src.getminsize()) 
	CALL dst.setmaxsize(src.getmaxsize()) 
	CALL dst.setnotnull(src.getnotnull()) 
	CALL dst.setpadding(src.getpadding()) 
	CALL dst.setmargin(src.getmargin()) 
	CALL dst.setcursor(src.getcursor()) 
	CALL dst.setlocale(src.getlocale()) 
	CALL dst.setvisible(src.getvisible()) 
	CALL dst.setcollapsed(src.getcollapsed()) 
	CALL dst.setenable(src.getenable()) 
	CALL dst.setcontextmenu(src.getcontextmenu()) 
	CALL dst.settooltip(src.gettooltip()) 
	CALL dst.settabindex(src.gettabindex()) 
	CALL dst.setzorder(src.getzorder()) 
	CALL dst.setenableborder(src.getenableborder()) 
	CALL dst.setscaletype(src.getscaletype()) 
	CALL dst.setelementborder(src.getelementborder()) 
	CALL dst.setverticalalignment(src.getverticalalignment()) 
	CALL dst.sethorizontalalignment(src.gethorizontalalignment()) 
	CALL dst.setonkeydown(src.getonkeydown()) 
	CALL dst.setonkeyup(src.getonkeyup()) 
	CALL dst.setonmousedown(src.getonmousedown()) 
	CALL dst.setonmouseup(src.getonmouseup()) 
	CALL dst.setonmousemove(src.getonmousemove()) 
	CALL dst.setonmouseenter(src.getonmouseenter()) 
	CALL dst.setonmousehover(src.getonmousehover()) 
	CALL dst.setonmouseexit(src.getonmouseexit()) 
	CALL dst.setonmousewheel(src.getonmousewheel()) 
	CALL dst.setonmousedoubleclick(src.getonmousedoubleclick()) 
	CALL dst.setonmouseclick(src.getonmouseclick()) 
	CALL dst.setonmenudetect(src.getonmenudetect()) 
	CALL dst.setondragstart(src.getondragstart()) 
	CALL dst.setondragenter(src.getondragenter()) 
	CALL dst.setondragover(src.getondragover()) 
	CALL dst.setondragfinished(src.getondragfinished()) 
	CALL dst.setondrop(src.getondrop()) 
	CALL dst.setonresize(src.getonresize()) 
	CALL dst.setonselection(src.getonselection()) 
	CALL dst.setonfocusin(src.getonfocusin()) 
	CALL dst.setonfocusout(src.getonfocusout()) 
	CALL dst.settextalignment(src.gettextalignment()) 
	CALL dst.setwrapper(src.getwrapper()) 
	CALL dst.setelementrole(src.getelementrole()) 
	CALL dst.setisprotected(src.getisprotected()) 
	CALL dst.setfocusable(src.getfocusable()) 
	CALL dst.sethasfocus(src.gethasfocus()) 
	CALL dst.setborderpanelitemlocation(src.getborderpanelitemlocation()) 
	CALL dst.setgriditemlocation(src.getgriditemlocation()) 
	CALL dst.setallowdrag(src.getallowdrag()) 
	CALL dst.setallowdrop(src.getallowdrop()) 
	CALL dst.settracksizes(src.gettracksizes()) 
	CALL dst.settracklocation(src.gettracklocation()) 
	CALL dst.setstyleclassname(src.getstyleclassname()) 
	CALL dst.settarget(src.gettarget()) 
	CALL dst.setcomment(src.getcomment()) 
END FUNCTION 


-- Copy AbstractField to AbstractField
FUNCTION copy_abstractfield(src, dst) 
	DEFINE src, dst ui.abstractfield 

	CALL copy_abstractuielement(src, dst) 

	CALL dst.setreadonly(src.getreadonly()) 
	CALL dst.setonvaluechanged(src.getonvaluechanged()) 
	CALL dst.setontouched(src.getontouched()) 
	CALL dst.setinvokeaction(src.getinvokeaction()) 
END FUNCTION 


-- Copy AbstractStringField to AbstractStringField
FUNCTION copy_abstractstringfield(src, dst) 
	DEFINE src, dst ui.abstractstringfield 

	CALL copy_abstractfield(src, dst) 

	CALL dst.settext(src.gettext()) 
END FUNCTION 
