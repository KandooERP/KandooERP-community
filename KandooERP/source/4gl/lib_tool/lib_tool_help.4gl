GLOBALS "../common/glob_GLOBALS.4gl" 

DEFINE rechelppage DYNAMIC ARRAY OF RECORD 
	pageid string, #pk 
	basefolderid1 string, 
	basefolderid2 string, 
	pageurl STRING 
END RECORD 

DEFINE rechelpelement DYNAMIC ARRAY OF RECORD 
	pageid string, --pk 
	elementid string, --pk 
	elementurl STRING 
END RECORD 

############################################################################
# FUNCTION onlineHelp(pPageId,pFragmentId)
############################################################################
FUNCTION onlinehelp(ppageid,pfragmentid) 
	DEFINE ppageid STRING 
	DEFINE pfragmentid STRING 
	DEFINE helpurl web.URL 
	DEFINE helpurl_path STRING
	DEFINE rechelppage RECORD LIKE qxt_help_page.* 

	CALL helpurl.setUrl(getbaseurl())
	LET helpurl_path = geturlpathtext(ppageid),"#",geturlfragmenttext(ppageid, pfragmentid)
	CALL helpurl.setFragmentId(helpurl_path)

	MENU 
		ON ACTION "Online Docs" 
			CALL ui.Interface.frontCall("standard", "launchURL", [ helpurl ], [] )
			EXIT MENU 
		ON ACTION "GNU License" 
			CALL show_gnu_license() 
			EXIT MENU 
		ON ACTION "SystemInfo" 
			CALL retrievelyciasystemenvironment("F") 
			EXIT MENU 
		ON ACTION "About" 
			OPEN WINDOW wabout with FORM "form/about_kandoo" 
			CALL donePrompt("Done","Close","ACCEPT") 
			CLOSE WINDOW wabout 
			EXIT MENU 
		ON ACTION "CANCEL" 
			EXIT MENU 
	END MENU 

END FUNCTION 

############################################################################
# FUNCTION onlineHelpLookupUrl(pHelpId,pFragmentId)
############################################################################
FUNCTION onlinehelplookupurl(phelpid,pfragmentid) 
	DEFINE phelpid,pfragmentid STRING 
	DEFINE lmoduleid STRING 

END FUNCTION 

############################################################################
# FUNCTION getUrlPathText(pPageId)  --DB / needs replacing / removing
############################################################################
FUNCTION geturlpathtext(ppageid) --db / needs replacing / removing 
	DEFINE ppageid VARCHAR(4) 
	DEFINE id int 
	DEFINE urlpagesegment STRING 
	DEFINE rechelppage RECORD LIKE qxt_help_page.* 

	-----------------
	SELECT * INTO rechelppage.* FROM qxt_help_page 
	WHERE hlp_pageid = ppageid 
	-----------
	LET urlpagesegment = rechelppage.hlp_basefolderid1, 
	"/", 
	rechelppage.hlp_basefolderid2, 
	"/", 
	rechelppage.hlp_pagepath 
	RETURN urlpagesegment
END FUNCTION 

############################################################################
# FUNCTION getUrlFragmentText(pPageId, pFragmentId)  --DB / needs replacing / removing
############################################################################
FUNCTION geturlfragmenttext(ppageid, pfragmentid) --db / needs replacing / removing 
	DEFINE ppageid VARCHAR(4) 
	DEFINE pfragmentid VARCHAR(4) 
	DEFINE id int 
	DEFINE urlelementsegment STRING 
	DEFINE rechelpfragment RECORD LIKE qxt_help_fragment.* 


	-----------------
	SELECT * INTO rechelpfragment.* FROM qxt_help_fragment 
	WHERE hlp_page_id = ppageid 
	AND hlp_fragment_id = pfragmentid 
	-----------

	LET urlelementsegment = rechelpfragment.hlp_fragment_text
	RETURN urlelementsegment 

END FUNCTION 


############################################################################
# FUNCTION getBaseUrl()
############################################################################
#needs TO be in a setings/config db table
FUNCTION getbaseurl()

	IF fgl_getenv("HELP_URL") IS null THEN 
		#set defaut kandoo doc URL --"http://doc.kandooerp.org/"
		CALL fgl_setenv("HELP_URL","http://doc.kandooerp.org")
	END IF 

	RETURN fgl_getenv("HELP_URL")
END FUNCTION 

##############################################################
# FUNCTION set_fkeys(pr_kandoomsg)
# moved FROM secufunc.4gl
##############################################################
FUNCTION set_fkeys(pr_kandoomsg) 
	DEFINE pr_winmsg CHAR(280), 
	pr_kandoomsg RECORD LIKE kandoomsg.*, 
	i,j,h,x,pr_last_space SMALLINT, 
	pr_key CHAR(10), 
	pr_key_text CHAR(30), 
	pr_key_num INTEGER 

	#CALL fgl_winmessage("This has to go...","Internal 4gl developers: This function set_fkeys() has to go","info")

	LET pr_winmsg = pr_kandoomsg.msg1_text clipped, 
	pr_kandoomsg.msg2_text clipped, 
	pr_kandoomsg.btn1_text clipped, 
	pr_kandoomsg.btn2_text clipped 

	LET x = length(pr_winmsg) 

	IF x > 5 THEN 

		FOR i = 3 TO 20 

			IF i <= 12 THEN 
				LET pr_key = "f",i USING "<<" 

			ELSE 
				CASE i 
					WHEN 13 
						LET pr_key = "control-e" 
					WHEN 14 
						LET pr_key = "control-f" 
					WHEN 15 
						LET pr_key = "control-g" 
					WHEN 16 
						LET pr_key = "control-m" 
					WHEN 17 
						LET pr_key = "control-p" 
					WHEN 18 
						LET pr_key = "control-u" 
					WHEN 19 
						LET pr_key = "control-v" 
					WHEN 20 
						LET pr_key = "control-y" 
				END CASE 
			END IF 

			LET pr_key_text = "" 
			#         --# CALL fgl_keysetlabel(pr_key,pr_key_text)  #huho: this needs full changing... someone tried TO be too smart AND didn't understand the actions framework
		END FOR 

		FOR i = 1 TO x - 5 

			IF pr_winmsg[i] = "F" THEN 
				WHENEVER ERROR CONTINUE 
				LET pr_key_num = pr_winmsg[i+1,i+2] 

				IF status <> 0 THEN 
					## character TO numeric conversion error
					## NOT a FUNCTION KEY :)
				ELSE 
					LET pr_key_text = NULL 
					LET h = 0 
					LET pr_last_space = 0 

					FOR j = i+3 TO x 
						IF pr_winmsg[j] = " " THEN 
							IF j = i + 3 THEN 
								CONTINUE FOR 
							END IF 
							IF pr_key_text = "TO" 
							OR pr_key_text = "for" THEN 
								LET pr_key_text = NULL 
								LET h = 0 
								CONTINUE FOR 
							END IF 
							LET pr_last_space = pr_last_space + 1 
						END IF 

						IF j = x 
						OR pr_last_space = 2 
						OR pr_winmsg[j] = ";" 
						OR pr_winmsg[j] = ":" 
						OR pr_winmsg[j] = "." THEN 
							LET pr_key = "f",pr_key_num USING "<<" 
							#                 --# CALL fgl_keysetlabel(pr_key,pr_key_text)  #huho: this needs fully changing...
							EXIT FOR 
						END IF 

						LET h = h + 1 
						LET pr_key_text[h] = pr_winmsg[j] 
					END FOR 

				END IF 

				WHENEVER ERROR stop 

			ELSE 

				IF pr_winmsg[i,i+3] = "CTRL" THEN 
					LET pr_key = "control-",downshift(pr_winmsg[i+5]) 
					LET pr_key_text = NULL 
					LET h = 0 
					LET pr_last_space = 0 

					FOR j = i+7 TO x 
						IF pr_winmsg[j] = " " THEN 
							IF j = i + 7 THEN 
								CONTINUE FOR 
							END IF 
							IF pr_key_text = "TO" 
							OR pr_key_text = "for" THEN 
								LET pr_key_text = NULL 
								LET h = 0 
								CONTINUE FOR 
							END IF 
							LET pr_last_space = pr_last_space + 1 
						END IF 

						IF j = x 
						OR pr_last_space = 2 
						OR pr_winmsg[j] = ";" 
						OR pr_winmsg[j] = ":" 
						OR pr_winmsg[j] = "." THEN 
							#                 --# CALL fgl_keysetlabel(pr_key,pr_key_text) #huho: this needs fully changing...
							EXIT FOR 
						END IF 

						LET h = h + 1 
						LET pr_key_text[h] = pr_winmsg[j] 
					END FOR 

				END IF 
			END IF 

		END FOR 

	ELSE 

	END IF 

END FUNCTION 

############################################################################
# FUNCTION kandooHelp(pArg)
############################################################################
#just temp.. will be removed when the entire legay help IS removed
FUNCTION kandoohelp(parg) 
	DEFINE parg STRING 
	CALL onlinehelp(getmoduleid(),null) 
END FUNCTION 


############################################################################
# FUNCTION show_gnu_license()
############################################################################
FUNCTION show_gnu_license() 
	DEFINE strlicense STRING 

	LET strlicense = 
	"GNU LESSER GENERAL PUBLIC LICENSE 
	\n\n 
	version 3, 29 june 2007 
	copyright © 2007 FREE software foundation, inc. <http://fsf.org/> 
	\n\n 

	everyone IS permitted TO copy AND distribute verbatim copies OF this license document, but changing it IS NOT allowed.\n 
	this version OF the gnu lesser general public license incorporates the terms AND conditions OF version 3 OF the gnu general public license, supplemented BY the additional permissions listed below.\n 
	\n\n 
	​ 

	0. additional definitions. 
	as used herein, “this license” refers TO version 3 OF the gnu lesser general public license, AND the “gnu gpl” refers TO version 3 OF the gnu general public license.\n 
	“the library” refers TO a covered WORK governed BY this license, other than an application OR a combined WORK as defined below.\n 
	\n\n 


	an “application” IS any WORK that makes use OF an interface provided BY the library, but which IS NOT OTHERWISE based ON the library. defining a subclass OF a class defined BY the library IS deemed a MODE OF USING an interface provided BY the library.\n 
	\n\n 


	a “combined work” IS a WORK produced BY combining OR linking an application with the library. the particular version OF the library with which the combined WORK was made IS also called the “linked version”.\n 
	\n\n 


	the “minimal corresponding source” FOR a combined WORK means the corresponding source FOR the combined work, excluding any source code FOR portions OF the combined WORK that, considered in isolation, are based ON the application, AND NOT ON the linked version.\n 
	the “corresponding application code” FOR a combined WORK means the object code and/or source code FOR the application, including any data AND utility programs needed FOR reproducing the combined WORK FROM the application, but excluding the system libraries OF the combined work.\n 
	\n\n 


	1. exception TO section 3 OF the gnu gpl.\n 
	you may convey a covered WORK under sections 3 AND 4 OF this license WITHOUT being bound BY section 3 OF the gnu gpl.\n 
	\n\n 


	2. conveying modified versions. 
	IF you modify a copy OF the library, and, in your modifications, a facility refers TO a FUNCTION OR data TO be supplied BY an application that uses the facility (other than as an argument passed WHEN the facility IS invoked), THEN you may convey a copy OF the modified version:\n 
		\n 
		a) under this license, provided that you make a good faith effort TO ensure that, in the event an application does NOT supply the FUNCTION OR data, the facility still operates, AND performs whatever part OF its purpose remains meaningful, or\n 
		b) under the gnu gpl, with none OF the additional permissions OF this license applicable TO that copy.\n 
		\n\n 
		3. object code incorporating material FROM library HEADER files. 
		the object code FORM OF an application may incorporate material FROM a HEADER file that IS part OF the library. you may convey such object code under terms OF your choice, provided that, IF the incorporated material IS NOT limited TO numerical parameters, data structure layouts AND accessors, OR small macros, inline functions AND templates (ten OR fewer LINES in length), you do both OF the following:\n 
		a) give prominent notice with each copy OF the object code that the library IS used in it AND that the library AND its use are covered BY this license.\n 
		b) accompany the object code with a copy OF the gnu gpl AND this license document.\n 
		\n\n 
		4. combined works.\n 
		you may convey a combined WORK under terms OF your choice that, taken together, effectively do NOT restrict modification OF the portions OF the library contained in the combined WORK AND reverse engineering FOR debugging such modifications, IF you also do each OF the following:\n 
		a) give prominent notice with each copy OF the combined WORK that the library IS used in it AND that the library AND its use are covered BY this license.\n 
		b) accompany the combined WORK with a copy OF the gnu gpl AND this license document.\n 
		c) FOR a combined WORK that displays copyright notices during execution, include the copyright notice FOR the library among these notices, as well as a reference directing the user TO the copies OF the gnu gpl AND this license document.\n 
		d) do one OF the following:\n 
		0) convey the minimal corresponding source under the terms OF this license, AND the corresponding application code in a FORM suitable for, AND under terms that permit, the user TO recombine OR relink the application with a modified version OF the linked version TO produce a modified combined work, in the manner specified BY section 6 OF the gnu gpl FOR conveying corresponding source.\n 
		1) use a suitable shared library mechanism FOR linking with the library. a suitable mechanism IS one that (a) uses at RUN time a copy OF the library already present ON the user's computer system, AND (b) will operate properly with a modified version OF the library that IS interface-compatible with the linked version.\n 
		e) provide installation information, but only IF you would OTHERWISE be required TO provide such information under section 6 OF the gnu gpl, AND only TO the extent that such information IS necessary TO install AND EXECUTE a modified version OF the combined WORK produced BY recombining OR relinking the application with a modified version OF the linked version. (if you use option 4d0, the installation information must accompany the minimal corresponding source AND corresponding application code. IF you use option 4d1, you must provide the installation information in the manner specified BY section 6 OF the gnu gpl FOR conveying corresponding source.)\n 
		\n\n 
		5. combined libraries.\n 
		you may place library facilities that are a WORK based ON the library side BY side in a single library together with other library facilities that are NOT applications AND are NOT covered BY this license, AND convey such a combined library under terms OF your choice, IF you do both OF the following:\n 
		a) accompany the combined library with a copy OF the same WORK based ON the library, uncombined with any other library facilities, conveyed under the terms OF this license.\n 
		b) give prominent notice with the combined library that part OF it IS a WORK based ON the library, AND explaining WHERE TO find the accompanying uncombined FORM OF the same work.\n 
		\n\n 
		6. revised versions OF the gnu lesser general public license.\n 
		the FREE software foundation may publish revised and/or new versions OF the gnu lesser general public license FROM time TO time. such new versions will be similar in spirit TO the present version, but may differ in detail TO address new problems OR concerns.\n 
		each version IS given a distinguishing version number. IF the library as you received it specifies that a certain numbered version OF the gnu lesser general public license “or any later version” applies TO it, you have the option OF following the terms AND conditions either OF that published version OR OF any later version published BY the FREE software foundation. IF the library as you received it does NOT specify a version number OF the gnu lesser general public license, you may choose any version OF the gnu lesser general public license ever published BY the FREE software foundation.\n 
		IF the library as you received it specifies that a proxy can decide whether future versions OF the gnu lesser general public license shall apply, that proxy's public statement OF acceptance OF any version IS permanent authorization FOR you TO choose that version FOR the library.\n 
		\ncurrently known contributors in no particular order\n\n 
		* eric vercelletto\n 
		* mike aubury\n 
		* andrej falout\n 
		* alex bondar\n 
		* spokey wheeler\n 
		* gertjan thomasse\n 
		* alex chubar\n 
		* hubert hölzl\n 
		\n 
		note: kandooerp IS an offspring OF the maxdev / maxerp OPEN source project.\nshould you be a contributor AND would LIKE TO see yourself ON this list, please do NOT hesitate TO contact us. 
		" 

		OPEN WINDOW wgnu_license with FORM "form/gnu_license" 
		DISPLAY strlicense TO gnu_license 
		CALL donePrompt("Done","Close","ACCEPT") 
		CLOSE WINDOW wgnu_license 

END FUNCTION 

#This IS just soooo legacy. We are going TO use HTML online help
{
# We are moving help/manual TO HTML help
##############################################################
# FUNCTION show_manuals(entity_code)
##############################################################
FUNCTION show_manuals(entity_code)
#
#  Displays User Manual help outline FOR nominated OR current program
#
DEFINE
      entity_code CHAR(8),
      help_file CHAR(80),
      file_name CHAR(60),
      mod_name CHAR(8),
      help_num, idx, i, file_is_valid SMALLINT

   IF glob_gui_flag THEN
      LET file_name = fgl_getenv("KANDOOUNC")
      LET mod_name = transmod(entity_code[1,1])
      LET help_file = "Winhlp32 -I ",
                      entity_code,
                      " -w outline ",
                      file_name clipped,
                      "/help/",
                      mod_name clipped,
                      ".hlp"
   LET help_num = winexec(help_file) #Don't wait
#this help needs either dropping OR changing
#ON ACTION "WEB-HELP"
#	CALL onlineHelp(getModuleId(),NULL)

   ELSE

      LET help_file = "help/",
                      upshift(entity_code[1,1]),
                      "_",
                      upshift(glob_rec_kandoouser.language_code) clipped,
                      ".iem"

#Help File help/A_ENG.iem NOT found
#FIXME: extension must be compiler dependant
#
#we make this help files
#eo.hlp
#fa.hlp
#jm.hlp
#lc.hlp
#pu.hlp
#qe.hlp
#re.hlp
#ss.hlp
#wo.hlp
#ar.hlp
#ap.hlp
#gl.hlp
#utility.hlp
#in.hlp
#



#huho help file exclusion
#		#check IF file.program exists
#		LET file_is_valid = file_valid(help_file)
#        IF NOT file_is_valid THEN
#            ERROR "Help File ",help_file clipped, " NOT found"
#            sleep 5
#            RETURN
#		END IF


	  OPTIONS help file help_file
      LET help_num = 1
      LET entity_code = entity_code, "   "

      FOR idx = 2 TO 3
          FOR i = 32 TO 90
             IF (ASCII(i)) = entity_code[idx,idx] THEN
                EXIT FOR
             END IF
          END FOR
          LET i = i - 32
          LET help_num = (help_num * 100) + i
      END FOR

#Informix messaging FUNCTION
      CALL showhelp(help_num)
   END IF
END FUNCTION
}