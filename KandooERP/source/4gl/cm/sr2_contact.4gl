{
###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################

	 $Id$
}


{**
 *
 * Main contact menu AND functions
 *
 * @author: Andrej Falout
 *
 *}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../cm/sr2_contact_GLOBALS.4gl" 

DEFINE 
add_and_exit 
SMALLINT 

##################################
FUNCTION init_contact_standalone() 
	##################################
	#must be called only IF program IS running as stand-alone
	DEFINE 
	help_file_name CHAR (20), 
	lv_exit_on_start SMALLINT 

	LET help_file_name = "contact.iem" #informix 
	--* LET help_file_name = "contact.qms" 		#Querix
	{! LET help_file_name = "contact.hlp" !} 	#<Anton Dickinson>
	LET help_file_name = "contact.42h" #<suse> 

	#    DISPLAY help_file_name clipped
	#    sleep 5

	#######
	OPTIONS 
	#######
	INPUT wrap, 
	help file help_file_name, 
	help KEY f1 





	#	DEFER INTERRUPT 			#CTRL + C
	#Querix don't LIKE this:
	#|
	#|   DEFER INTERRUPT AND DEFER QUIT are only permitted in main program.
	#|
	#| Check error -4365.
	#|


	#	DEFER QUIT					#CTRL + \ (GX)

	#	SET LOCK MODE TO WAIT
	#	WHENEVER WARNING CALL POZOR


	#this shouls aso be replaced with CALL TO authenticate(pr_menu_code) in secufunc.4gl
	#	CALL startlog ("error.log")
	INITIALIZE lv_exit_on_start TO NULL 
	LET lv_exit_on_start = fgl_getenv("EXIT_ON_START") 
	IF lv_exit_on_start IS NOT NULL THEN 
		#Used FOR testing, TO check that program can start
		#(duplicate/miising functions, library paths, etc)
		EXIT program (lv_exit_on_start) 
	END IF 

	#WHENEVER ERROR CALL trap
	WHENEVER ERROR stop 

	LET do_debug = false 
	LET g_scrsize="full" 

	CALL params() 

	CALL open_database() #contact_lib.4gl 

	#    CALL authenticate("menu_path")

	# Will replace this

	#   SELECT sign_on_code INTO glob_rec_kandoouser.sign_on_code FROM kandoouser
	#    WHERE sign_on_code = user


	SELECT sign_on_code, cmpy_code INTO glob_rec_kandoouser.sign_on_code, glob_rec_kandoouser.cmpy_code FROM kandoouser 
	WHERE sign_on_code = user 

	#this block IS also in authenticate() but we cannot CALL it directly FROM
	#there since contact IS NOT the name of program in menu3 table yet...:


	#<added by AF>

	#CALL switch_user()

	# WHEN the application receives the SIGTERM signal (only available on UNIX).
	OPTIONS ON terminate signal CALL exit_program_global 

	# application window IS closed by a user action, FOR example, ALT-F4 on Windows clients:
	# OPTIONS ON CLOSE APPLICATION CALL exit_program_global 			#{STOP|CONTINUE|CALL func}

	#</added by AF>


	IF status = notfound THEN 
		ERROR "You are NOT a user on this database" 
		SLEEP 5 
		EXIT program 
	END IF 


END FUNCTION 


#########################
FUNCTION init_contact() 
	#########################
	#called TO initialse CM functions in standalone AND WHEN linked

	#######
	OPTIONS 
	#######

	#		FIELD ORDER UNCONSTRAINED
	#		FIELD ORDER CONSTRAINED
	MESSAGE line FIRST #with d4gl AND MENU ON the right side OF the screen, 
	#the first line of the window (whitch IS by default menu line)
	#IS unused
	#		PROMPT LINE
	#		COMMENT LINE
	#		ERROR LINE
	#		FORM LINE
	#		INSERT KEY
	#		DELETE KEY
	#		NEXT KEY
	#		PREVIOUS KEY

	#END OPTIONS

	CALL default_accept("ESCAPE") #escape FOR esc/ctrl+c, enter FOR enter/escape 

	INITIALIZE gv_null TO NULL 


	LET d4gl = fgl_fglgui() 
	IF d4gl IS NULL THEN 
		LET d4gl = false 
	END IF 

	LET mswindows = fgl_wtkclient() 
	IF mswindows IS NULL THEN 
		LET mswindows = false 
	END IF 

	CALL fgl_settitle("Maximise - CM: Person / Organisation") 


	SELECT sign_on_code INTO glob_rec_kandoouser.sign_on_code FROM kandoouser 
	WHERE sign_on_code = user 

	CALL open_forms() 

	LET show_valid = true 
	LET show_history = false 

	LET last_circle = 0 

	LET comment_arr_max = 10 

	IF 
	glob_rec_kandoouser.sign_on_code IS NULL 
	OR 
	length (glob_rec_kandoouser.sign_on_code) < 2 
	THEN 
		ERROR "Internal error: user name (glob_rec_kandoouser.sign_on_code) NOT known. Must EXIT" 
		SLEEP 5 
	END IF 

END FUNCTION #init_contact() 

###########################
FUNCTION init_upper_scr() 
	###########################
	DEFINE 
	x,y,r,c 
	SMALLINT 

	CASE g_scrsize 
		WHEN "full" 

			LET x=2 
			LET y=2 
			LET r=9 
			LET c=75 

			#<Anton Dickinson>: http://<Anton Dickinson>.com/mantis/bug_view_page.php?bug_id=0000062
			#Err:Program stopped AT 'contact.4gl', line number 237.
			#Error STATUS number -30205.
			#Window IS too small TO DISPLAY this form (too high).

			            {!
			#LET x=1  	#Couldnt create window.
			#LET y=1     #Couldnt create window.
			#LET r=11
			#LET c=77

						!}
			#DISPLAY r
			#sleep 5
			{
						OPEN WINDOW w_contact  -- albo  KD-766
				    	    AT x,y with r rows, c columns
								attribute (border)
			}

		WHEN "pocketpc" 

			#this IS EXACTLY how much characters fir on Pocket PC SCREEN in per form:
			#123456789012345678901234567890
			#so, exactly 30 CHAR's.
			{
						OPEN WINDOW w_contact  -- albo  KD-766
			#at 1,1 with 9 rows, 30 columns #30 col IS apsolute max(with 1,1), but no space FOR menu on right side!
			#at 0,0 with 9 rows, 32 columns
			                AT 0,0 with 8 rows, 32 columns
			#at 1,1 with 9 rows, 24 columns
			#attribute (border)
			}
		OTHERWISE 
			ERROR "Screen size was NOT SET. Stop." 
			EXIT program 

	END CASE 

	DISPLAY FORM f_contact1 

	LET current_form = 1 

END FUNCTION 

##########################
FUNCTION init_lower_scr() 
	##########################
	DEFINE 
	x, y, a, b SMALLINT 

	#LET x=12; LET y=75          ##Informix: Border does NOT fit on SCREEN.  Window IS too large.
	LET x=13; LET y=75 
	LET x=13; LET y=75 #<suse> 
	{! LET x=13; LET y=75 !}    #<Anton Dickinson>
	--* LET x=13; LET y=75      #Querix

	LET a=11; LET b=2 
	LET a=12; LET b=2 
	{! LET a=12; LET b=2 !}
	--* LET a=12; LET b=2


	CASE g_scrsize 
		WHEN "full" 
			{
						OPEN WINDOW w_info  -- albo  KD-766
					        AT a,b
				                with x rows, y columns
			                        attribute (border)
			}
		WHEN "pocketpc" 
			{
						OPEN WINDOW w_info  -- albo  KD-766
			#at 10,0 with 13 rows, 32 columns
			#at 9,0 with 13 rows, 32 columns #this will actually start below upper window
			#at 9,0 with 8 rows, 32 columns #this will actually start below upper window
			                AT 8,0 with 8 rows, 32 columns #at 8 only without border
			#attribute (border)
			}
		OTHERWISE 
			ERROR "Screen size was NOT SET. Stop." 
			EXIT program 

	END CASE 

	DISPLAY FORM f_info 

END FUNCTION 


##########################
FUNCTION open_forms() 
	##########################

	CASE g_scrsize 
		WHEN "full" 


			OPEN FORM f_contact1 FROM "contact1" 

			OPEN FORM f_contact2 FROM "contact2" 

			OPEN FORM f_address1 FROM "address" 

			OPEN FORM f_info FROM "info" 

			#OPEN FORM f_addr_hist FROM "all_role_sml"
			OPEN FORM f_addr_hist FROM "all_role_s" 

			#OPEN FORM f_all_roles FROM "all_role_sml"
			OPEN FORM f_all_roles FROM "all_role_s" 

			#OPEN FORM f_comment1 FROM "contact_com"
			OPEN FORM f_comment1 FROM "cm_com" 

			OPEN FORM f_all_comment FROM "info" 

			OPEN FORM f_phone1 FROM "phone" 

			#OPEN form f_phone_roles FROM "all_ph_role"
			OPEN FORM f_phone_roles FROM "all_ph_rol" 

			OPEN FORM f_bank_acc1 FROM "bank_acc" 

			#OPEN form f_bank_acc_roles FROM "all_ac_role"
			OPEN FORM f_bank_acc_roles FROM "all_ac_rol" 

			OPEN FORM f_cc1 FROM "credit_c" 

			#OPEN form f_cc_roles FROM "all_cc_role"
			OPEN FORM f_cc_roles FROM "all_cc_rol" 

			#OPEN form f_contact_roles FROM "all_per_role"
			OPEN FORM f_contact_roles FROM "all_per_ro" 

			#OPEN form f_contact_relations FROM "all_relation"
			OPEN FORM f_contact_relations FROM "all_relati" 

			#OPEN form f_contact_mailings FROM "all_mailing"
			OPEN FORM f_contact_mailings FROM "all_mailin" 

		WHEN "pocketpc" 


			#OPEN FORM f_contact1 FROM "contact1-PPC"
			OPEN FORM f_contact1 FROM "con1-PPC" 

			#OPEN FORM f_contact2 FROM "contact2-PPC"
			OPEN FORM f_contact2 FROM "con2-PPC" 

			OPEN FORM f_address1 FROM "address" 

			OPEN FORM f_info FROM "info-PPC" 

			#OPEN FORM f_addr_hist FROM "all_role_sml"
			OPEN FORM f_addr_hist FROM "all_role_s" 

			#OPEN FORM f_all_roles FROM "all_role_sml"
			OPEN FORM f_all_roles FROM "all_role_s" 

			#OPEN FORM f_comment1 FROM "contact_com"
			OPEN FORM f_comment1 FROM "cm_com" 

			OPEN FORM f_all_comment FROM "info" 

			OPEN FORM f_phone1 FROM "phone" 

			#OPEN form f_phone_roles FROM "all_ph_role"
			OPEN FORM f_phone_roles FROM "all_ph_rol" 

			OPEN FORM f_bank_acc1 FROM "bank_acc" 

			#OPEN form f_bank_acc_roles FROM "all_ac_role"
			OPEN FORM f_bank_acc_roles FROM "all_ac_rol" 

			OPEN FORM f_cc1 FROM "credit_c" 

			#OPEN form f_cc_roles FROM "all_cc_role"
			OPEN FORM f_cc_roles FROM "all_cc_rol" 

			#OPEN form f_contact_roles FROM "all_per_role"
			OPEN FORM f_contact_roles FROM "all_per_ro" 

			#OPEN form f_contact_relations FROM "all_relation"
			OPEN FORM f_contact_relations FROM "all_relati" 

			#OPEN form f_contact_mailings FROM "all_mailing"
			OPEN FORM f_contact_mailings FROM "all_mailin" 

		OTHERWISE 
			ERROR "Screen size was NOT SET. Stop." 
			EXIT program 

	END CASE 

END FUNCTION 

##########################
FUNCTION display_form2() 
	##########################

	OPEN WINDOW w_contact2 with FORM "contact2" #second screen OF contact - up 
	CALL winDecoration("contact2") -- albo kd-766 

	#CURRENT WINDOW IS w_contact2
	LET current_form = 2 

END FUNCTION 

###########################
FUNCTION contact_main_menu(initial_contact_id) 
	###########################
	DEFINE 
	initial_contact_id 
	LIKE contact.contact_id, 
	where_part, 
	from_and_where 
	CHAR (800), 
	success 
	SMALLINT, 
	send1, send2, send3, send4, from_part #where_part 
	CHAR (200) 

	CALL init_contact_standalone() 

	#calling ANY FUNCTION in CM require that you CALL AT least
	#init_contact FUNCTION before, preferably AT the begining
	#of your program, in MAIN block
	#IF you want TO actualy show any windows, you will need in most
	#cases TO CALL init_upper_scr(), AND in many cases also
	#init_lower_scr()

	CALL init_contact() 

	CALL init_upper_scr() 
	INITIALIZE g_contact.* TO NULL 
	CALL init_lower_scr() 

	IF add_and_exit THEN 
		CALL all_add() RETURNING success, dummy #contact_id 
		IF 
		success 
		THEN 
			EXIT program 
		END IF 
	END IF 

	IF do_debug THEN 
		#LET g_msg = "SET explain on"  #we are removing any "SET explain on"
		PREPARE xx22 FROM g_msg 
		EXECUTE xx22 
	END IF 
	CURRENT WINDOW IS w_contact 


	IF initial_contact_id IS NOT NULL THEN 
		MESSAGE"" 
		LET send1 = " contact.contact_id = ", initial_contact_id 
		LET where_part = send1, send2, send3, send4 
		LET where_part = "SELECT * FROM contact WHERE ", where_part clipped 
		LET last_where_part = where_part 

		LET send1 = where_part[1,200] 
		LET send2 = where_part[201,400] 
		LET send3 = where_part[401,600] 
		LET send4 = where_part[601,800] 

		CLEAR FORM 
		IF 
		open_cursor(send1, send2, send3, send4) 
		THEN 
			CALL contact_info("1") 
		END IF 

		INITIALIZE initial_contact_id TO NULL 
		CURRENT WINDOW IS w_contact 

	END IF 


	MENU "Contact" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact","menu-Contact-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			#COMMAND KEY (f22,"Q","q") "Query" "Query by contact data"
		COMMAND KEY ("Q","q") "Query" "Query by contact data" 
			MESSAGE"" 
			CALL clear_info() 
			CURRENT WINDOW IS w_contact 

			CALL qbe_contact() RETURNING 
			send1, send2, send3, send4 

			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				LET where_part = send1, send2, send3, send4 
				LET where_part = "SELECT * FROM contact WHERE ", where_part clipped 
				LET last_where_part = where_part 

				LET send1 = where_part[1,200] 
				LET send2 = where_part[201,400] 
				LET send3 = where_part[401,600] 
				LET send4 = where_part[601,800] 

				IF open_cursor(send1, send2, send3, send4) THEN 
					CALL contact_info("1") 
				END IF 
			END IF 

		COMMAND "Composite query" "Query all contact related info" 
			MESSAGE"" 
			CALL clear_info() 

			CALL qbe_composite() RETURNING 
			send1, send2, send3, send4, from_part #1-4=where_part 

			CURRENT WINDOW IS w_contact 

			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				LET from_and_where = 
				"SELECT * ", 
				from_part clipped, 
				" WHERE ", 
				send1, send2, send3, send4 clipped 

				LET send1 = from_and_where[1,200] 
				LET send2 = from_and_where[201,400] 
				LET send3 = from_and_where[401,600] 
				LET send4 = from_and_where[601,800] 

				IF 
				open_cursor(send1, send2, send3, send4) 
				THEN 
					CALL contact_info("1") 
				END IF 
			END IF 

			#COMMAND KEY (f21,"+") "+" "Next found"
		COMMAND KEY ("+") "+" "Next found" 
			MESSAGE"" 
			#            CALL clear_info()
			CURRENT WINDOW IS w_contact 
			IF 
			n_contact() 
			THEN 
				CALL contact_info("1") 
			END IF 

			#command  key (f20,"-") "-" "Previous found"
		COMMAND KEY ("-") "-" "Previous found" 
			MESSAGE"" 
			#x            CALL clear_info()
			CURRENT WINDOW IS w_contact 
			IF 
			p_contact() 
			THEN 
				CALL contact_info("1") 
			END IF 


		COMMAND "Add" "Add new contact" 
			MESSAGE"" 
			CALL all_add() RETURNING success, dummy #contact_id 

		COMMAND "Edit" "Modify current contact data" 
			MESSAGE"" 
			LET success = au_contact(false) 

		COMMAND "Delete" "Delete current contact" 
			MESSAGE"" 
			CALL del_contact() 
			#CLEAR info

		COMMAND "Screen" "Show next SCREEN of current contact data" 
			MESSAGE"" 
			CALL next_screen() 

		COMMAND KEY ("u","U") "sUmmary +" "Circe all available info forward" 
			MESSAGE"" 
			CALL circle_info(false) 

		COMMAND KEY ("y","Y") "summarY -" "Circe all available info backward" 
			MESSAGE"" 
			CALL circle_info(true) 

		COMMAND "Info" "Summary information on this contact" 
			MESSAGE"" 
			IF g_contact.contact_id IS NOT NULL THEN 
				CALL contact_info("1") 
			ELSE 
				ERROR "please SELECT the contact first !" 
			END IF 

			#        COMMAND "      " ""


		COMMAND KEY ("t","T") "commenTs" "Maintain comment notes FOR this contact" 
			IF 
			g_contact.contact_id IS NULL 
			THEN 
				ERROR "Please enter Query condition first !" 
			ELSE 
				MESSAGE"" 
				CALL contact_comment_menu() #contact_comment.4gl 
				CALL contact_info("1") 
			END IF 

			#COMMAND KEY (f30,"r","R") "addRess" "Maintain contact related address information"
		COMMAND KEY ("r","R") "addRess" "Maintain contact related address information" 
			MESSAGE"" 
			IF g_contact.contact_id IS NOT NULL THEN 
				CALL address_menu() #contact_address.4gl 
				CALL contact_info("1") 
			ELSE 
				ERROR "please SELECT the contact first !" 
			END IF 

		COMMAND "Phone" "Maintain contact related phone information" 
			MESSAGE"" 
			IF g_contact.contact_id IS NOT NULL THEN 
				CALL phone_menu() #contact_phone.4gl 
				CALL contact_info("1") 
			ELSE 
				ERROR "please SELECT the contact first !" 
			END IF 

		COMMAND "Bank" "Maintain contact related bank information" 
			MESSAGE"" 
			IF g_contact.contact_id IS NOT NULL THEN 
				CALL bank_menu() #contact_bank.4gl 
				CALL contact_info("1") 
			ELSE 
				ERROR "please SELECT the contact first !" 
			END IF 

		COMMAND KEY ("e","E") "crEdit card" "Maintain contact related credit card information" 
			MESSAGE"" 
			IF g_contact.contact_id IS NOT NULL THEN 
				CALL cc_menu() #contact_cc.4gl 
				CALL contact_info("1") 
			ELSE 
				ERROR "please SELECT the contact first !" 
			END IF 

		COMMAND KEY ("o","O") "rOle" "Maintain role information of this contact" 
			MESSAGE"" 
			IF g_contact.contact_id IS NOT NULL THEN 
				CALL contact_role_menu() #contact_role.4gl 
				CALL contact_info("1") 
			ELSE 
				ERROR "please SELECT the contact first !" 
			END IF 


		COMMAND KEY ("l","L") "reLation" "Maintain contact relation information" 
			MESSAGE"" 
			IF g_contact.contact_id IS NOT NULL THEN 
				CALL relation_menu() #contact_relation.4gl 
				CALL contact_info("1") 
			ELSE 
				ERROR "please SELECT the contact first !" 
			END IF 

			#COMMAND KEY (f32,"n","N") "mailiNg" "Maintain contact related mailing information"
		COMMAND KEY ("n","N") "mailiNg" "Maintain contact related mailing information" 
			MESSAGE"" 
			IF g_contact.contact_id IS NOT NULL THEN 
				CALL mailing_menu() #contact_mailing.4gl 
				CALL contact_info("1") 
			ELSE 
				ERROR "please SELECT the contact first !" 
			END IF 


			#COMMAND KEY (f30) "codes" "Maintain contact related codes tables (all roles, Mailing roles, codes..)"
		COMMAND KEY ("$") "codes" "Maintain contact related codes tables (all roles, Mailing roles, codes..)" 
			MESSAGE"" 
			CALL code_maintain_menu() 
			#CALL contact_info("1")


			#		command  key ("x","X","control-c","escape") "eXit" "Exit this program"
			# control-c shows in menu bar, but have no effect WHEN pressed


			#		command  key ("x","X",interrupt,"escape") "eXit" "Exit this program"
			#both escape anf ctrl-c work, but label "escape" IS visible in menu bar

			#		command  key (f33,"x","X",interrupt,escape)
			#Bloody Querix again:
			#|
			#|   Only a total of four keys IS permitted in a single ON KEY statement.
			#|
			#| Check error -4457.
			#|
		COMMAND KEY (f33,"x","X",interrupt) 

			#command  key (f33,"x","X",interrupt,escape) "eXit" "Exit this program"
			#command  key ("x","X",interrupt,escape) "eXit" "Exit this program"
			#both escape anf ctrl-c work, but label "escape" IS visible in menu bar
			#put key.escape.text = "" in fglprofile TO hide it
			#interrupt was invisible because the icon was defined, AND hideButton was 1:
			#gui.toolBar.7.bmp    = "delete"
			#gui.toolBar.7.comments = "Interrupt"
			#gui.toolBar.7.hideButton = 1



			#		command  key ("x","X",interrupt) "eXit" "Exit this program"
			#interrupt (ctrl+c) works, AND IS NOT displayed in menu bar
			{
					ON KEY(F1, ACCEPT)
						LET p_Idx = ARR_CURR()
						EXIT DISPLAY

					ON KEY(F4, F8, INTERRUPT)
			}

			MESSAGE"" 

			LET ga_grid[1] = "Do you want TO EXIT this program ?" 

			IF ask_yes_no(1)  THEN #used LINES
				EXIT MENU 
			END IF 

			{
			        COMMAND KEY ("escape") "2"  "test"  #OK
			            ERROR "escape"

			#NOT        COMMAND KEY ("accept") "3"  "test"
			#            ERROR "accept"

			#NOT        COMMAND KEY ("ctrl-c") "4"  "test"
			#            ERROR "ctrl-c"

			        COMMAND KEY ("control-c") "4"  "test" #OK
			            ERROR "control-c 1"

			#NOT        COMMAND KEY (control-e) "5"  "test"
			#            ERROR "control-c 2"

			}

	END MENU 
	--	CLOSE WINDOW w_info  -- albo  KD-766
	--	CLOSE WINDOW w_contact  -- albo  KD-766


END FUNCTION #main_menu() 

###################
FUNCTION all_add() 
	###################
	DEFINE 
	success 
	SMALLINT 


	CALL clear_info() 
	CURRENT WINDOW IS w_contact 

	LET success = au_contact(true) 

	IF success THEN 
		CALL init_addr_win() 
		LET success = au_contact_address(g_contact.contact_id,true) 
		CURRENT WINDOW IS w_contact 
		IF success THEN 
			CALL init_phone_win() 
			LET success = au_contact_phone(g_contact.contact_id,true) 
			CURRENT WINDOW IS w_contact 
			IF success THEN 
				CALL contact_info("1") 
			END IF 
		END IF 
	END IF 

	RETURN success, g_contact.contact_id 

END FUNCTION #all_add() 


################################################################
FUNCTION select_contact(restrict_contact_id, initial_contact_id) 
	################################################################
	DEFINE 
	restrict_contact_id, 
	selected_contact_id, 
	initial_contact_id 
	LIKE contact.contact_id, 
	where_part 
	CHAR (800), 
	send1, send2, send3, send4 #where_part 
	CHAR (200) 


	LABEL start_here: 


	#			CALL clear_info()
	CURRENT WINDOW IS w_contact 
	MESSAGE"" 

	IF initial_contact_id IS NOT NULL THEN 
		LET send1 = " contact.contact_id = ", initial_contact_id 
		INITIALIZE send2, send3, send4 TO NULL 
	ELSE 
		CALL qbe_contact() RETURNING send1, send2, send3, send4 
	END IF 


	LET where_part = send1, send2, send3, send4 
	LET where_part = "SELECT * FROM contact WHERE ", where_part clipped 
	#LET where_part = where_part clipped,

	IF restrict_contact_id IS NOT NULL THEN 
		LET where_part = where_part clipped, 
		" AND contact.contact_id <> ", restrict_contact_id 
	END IF 

	LET last_where_part = where_part 

	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 
	LET send4 = where_part[601,800] 


	IF 
	int_flag 
	THEN 
		LET int_flag = false 
		LET dummy = NULL 
		#				RETURN NULL
		#Informix:
		#|
		#|      The symbol "NULL" does NOT represent a defined variable.
		#| See error number -4369.

	ELSE 

		IF 
		open_cursor(send1, send2, send3, send4) 
		THEN 
			#CALL contact_info("1")
			MENU "SELECT new contact FOR relationship" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","contact","menu-new contact-1") -- albo kd-513 

				ON ACTION "WEB-HELP" -- albo 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "+" "Next found" 
					MESSAGE"" 
					CURRENT WINDOW IS w_contact 
					IF 
					n_contact() 
					THEN 
						#CALL contact_info("1")
					END IF 

				COMMAND "-" "Previous found" 
					MESSAGE"" 
					CURRENT WINDOW IS w_contact 
					IF 
					p_contact() 
					THEN 
						#CALL contact_info("1")
					END IF 

				COMMAND "SELECT" "SELECT current contact FOR new Relationship" 
					LET selected_contact_id = g_contact.contact_id 
					EXIT MENU 

				COMMAND "Query" "Initiate new query" 
					CALL qbe_contact() RETURNING send1, send2, send3, send4 

					IF 
					int_flag 
					THEN 
						LET int_flag = false 
						CONTINUE MENU 
					ELSE 

						LET where_part = send1, send2, send3, send4 

						LET where_part = "SELECT * FROM contact WHERE ", where_part clipped, 
						#LET where_part = where_part clipped,
						" AND contact.contact_id <> ", restrict_contact_id 

						LET last_where_part = where_part 

						LET send1 = where_part[1,200] 
						LET send2 = where_part[201,400] 
						LET send3 = where_part[401,600] 
						LET send4 = where_part[601,800] 

						IF open_cursor(send1, send2, send3, send4) THEN 
							#ERROR " hurg?"
						END IF 

					END IF 

				COMMAND "Quit" "Quit selection without selecting new contact fot relationship" 
					INITIALIZE selected_contact_id TO NULL 
					EXIT MENU 

			END MENU 
		ELSE 
			ERROR "No records foud; Try again, OR SELECT CTRL+C AND THEN Quit" 
				SLEEP 2 
				GOTO start_here 
			END IF 
		END IF 

		SELECT * INTO g_contact.* 
		FROM contact 
		WHERE contact.contact_id = restrict_contact_id 

		CALL get_codes() 
		CALL display_contact() 

		RETURN selected_contact_id 

END FUNCTION #select_contact() 


######################
FUNCTION qbe_contact() 
	######################
	DEFINE 
	where_part 
	CHAR (800), 
	tmp_name LIKE contact.last_org_name, 
	send1, send2, send3, send4, from_part #where_part 
	CHAR (200), 
	tmplen SMALLINT 


	IF 
	current_form <> 1 
	THEN 
		CALL d_contact1() 
	END IF 

	MESSAGE "Enter the query condition AND press Accept" 


	CLEAR FORM 

	CONSTRUCT where_part ON 
	contact.last_org_name_up, 
	contact.first_name_up, 
	contact.mid_name_up, 
	contact.initials, 
	contact.sex_ind, 
	contact.title, 
	contact.org_ind, 
	contact.user_defined1, 
	contact.user_defined2 

	#,contact.salutation_code,
	#contact.age_code
	FROM 
	s_contact.last_org_name, 
	s_contact.first_name, 
	s_contact.mid_name, 
	s_contact.initials, 
	s_contact.sex_ind, 
	s_contact.title, 
	s_contact.org_ind, 
	s_contact.user_defined1, 
	s_contact.user_defined2 

	#,s_contact.salutation_code,
	#s_contact.age_code

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","contact","construct-contact-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY ("f33", "CONTROL-w") 

			IF g_scrsize = "pocketpc" THEN 
				EXIT CONSTRUCT 
			END IF 


		AFTER FIELD last_org_name 
			LET tmp_name = upshift(get_fldbuf(last_org_name)) 
			DISPLAY tmp_name TO last_org_name 

			IF g_scrsize = "pocketpc" THEN 
				EXIT CONSTRUCT 
			END IF 


		AFTER FIELD first_name 
			LET tmp_name = upshift(get_fldbuf(first_name)) 
			DISPLAY tmp_name TO first_name 

		AFTER FIELD mid_name 
			LET tmp_name = upshift(get_fldbuf(mid_name)) 
			DISPLAY tmp_name TO mid_name 


			#############
	END CONSTRUCT 
	#############

	MESSAGE "" 

	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 
	LET send4 = where_part[601,800] 


	IF g_scrsize = "pocketpc" THEN 

		#error where_part sleep 10
		IF where_part matches "*=*" 
		AND where_part NOT matches "*1=1*" THEN 
			CALL cmreplace_string ("contact.last_org_name_up=", "contact.last_org_name_up matches ", send1, send2, send3, send4) 
			RETURNING send1, send2, send3, send4 

			LET where_part = send1, send2, send3, send4 
			#error where_part sleep 10

			LET tmplen=length(where_part)-1 
			LET where_part = where_part[1,tmplen],'*"' 

			#error where_part sleep 10

			LET send1 = where_part[1,200] 
			LET send2 = where_part[201,400] 
			LET send3 = where_part[401,600] 
			LET send4 = where_part[601,800] 


		END IF 


	END IF 



	#this IS actualy only the WHERE part. The FROM part will be added later
	RETURN send1, send2, send3, send4 #where_part 

END FUNCTION #qbe_contact() 


{**
 * @table contact_role
 * @table contact_relation
 * @table contact_phone
 * @table contact_mailing
 * @table contact_cc
 * @table contact_address
 * @table contact_bank_acc
 *}
#######################
FUNCTION qbe_composite() 
	#######################
	DEFINE 
	where_part, 
	tmp_where_part, 
	from_and_where 
	CHAR (800), 
	tmp_name LIKE contact.last_org_name, 
	send1, send2, send3, send4, 
	return1, return2, return3, return4, from_part #where_part 
	CHAR (200), 
	role_added, 
	contact_role_added, 
	contact_relation_added 
	SMALLINT, 
	new_role_name LIKE role.role_name, 
	new_role_code LIKE role.role_code 


	LET role_added = false 
	LET contact_role_added = false 
	LET contact_relation_added = false 



	OPEN WINDOW w_composite with FORM "composite" 
	CALL winDecoration("composite") -- albo kd-766 

	MESSAGE "Enter the query condition AND press Accept" 


	CONSTRUCT tmp_where_part ON 
	contact.last_org_name_up, 
	contact.first_name_up, 
	address.city, 
	address.suburb, 
	phone.area_code, 
	phone.phone_number, 
	bank_acc.bank_name, 
	bank_acc.bank_branch, 
	credit_card.cc_no, 

	no_table.in_role_of, 
	#			no_table.related_to,
	no_table.in_relation_of, 

	comment.comment_text, 
	mailing_role.mailing_name 

	FROM 
	s_composite.last_org_name_up, 
	s_composite.first_name_up, 
	s_composite.city, 
	s_composite.suburb, 
	s_composite.area_code, 
	s_composite.phone_number, 
	s_composite.bank_name, 
	s_composite.bank_branch, 
	s_composite.cc_no, 
	s_composite.in_role_of, 
	#			s_composite.related_to,
	s_composite.in_relation_of, 
	s_composite.comment_text, 
	s_composite.mailing_name 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","contact","construct-address-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			#######################################
		ON KEY ("f3", "CONTROL-b", "CONTROL-f") 
			#######################################
			#CONTROL-CHAR (except A, D, H, I, J, L, M, R, OR X)
			#F3 AND ctrl-f are windows standard keys
			#FOR find functions, ctrl-b IS Maximise standard

			####
			CASE 
			####
			#########################
				WHEN infield (in_role_of) 
					#########################
					#LET tmp_name = upshift(GET_FLDBUF(last_org_name))

					CALL role_lp("CONTACT ROLE") 
					RETURNING new_role_code, new_role_name 

					IF new_role_code IS NOT NULL THEN 
						DISPLAY new_role_name TO in_role_of 
					END IF 


					#########
				OTHERWISE 
					#########

					ERROR "You are NOT in the field that hace lookup FUNCTION" 
					########
			END CASE 
			########


			#############
	END CONSTRUCT 
	#############

	MESSAGE "" 

	LET from_part = "" 
	LET where_part = "" 

	IF tmp_where_part matches "*no_table.in_role_of*" THEN 
		LET send1 = tmp_where_part[1,200] 
		LET send2 = tmp_where_part[201,400] 
		LET send3 = tmp_where_part[401,600] 
		LET send4 = tmp_where_part[601,800] 

		CALL cmreplace_string ( 
		"no_table.in_role_of", 
		"role.role_name", 
		send1, send2, send3, send4 
		) RETURNING return1, return2, return3, return4 


		LET tmp_where_part = return1, return2, return3, return4 

		LET from_part = from_part clipped, 
		", role, contact_role " 

		LET role_added = true 
		LET contact_role_added = true 


		LET tmp_where_part = tmp_where_part clipped, 
		" AND role.role_code = contact_role.role_code ", 
		" AND role.class_name = 'CONTACT ROLE' ", 
		" AND contact_role.contact_id = contact.contact_id " 

		IF show_valid THEN 
			LET tmp_where_part = tmp_where_part clipped, 
			" AND (contact_role.valid_to IS NULL OR contact_role.valid_to > TODAY)" 
		END IF 

	END IF 

	{ self join. Must be subquery
		if
	        tmp_where_part matches "*no_table.related_to*"
	    THEN
			LET send1 = tmp_where_part[1,200]
		    LET send2 = tmp_where_part[201,400]
		    LET send3 = tmp_where_part[401,600]
		    LET send4 = tmp_where_part[601,800]

			CALL CMreplace_string (
				"no_table.related_to",
				"contact.last_org_name_up",
			    send1, send2, send3, send4,
				) returning return1, return2, return3, return4

			LET tmp_where_part = return1, return2, return3, return4

	        if NOT role_added THEN
				LET from_part = from_part clipped,
		        ", role "
	            LET role_added = TRUE
	        END IF

			LET from_part = from_part clipped,
				 ", contact_relation "
	        LET contact_relation_added = TRUE

	        LET tmp_where_part = tmp_where_part clipped,
	        " AND role.role_code = contact_relation.role_code ",
	        " AND role.class_name = 'RELATION' ",
	        " AND contact_relation.contact_id_pri = contact.contact_id "

		    if show_valid THEN
			    LET tmp_where_part = tmp_where_part clipped,
				" AND (contact_relation.valid_to IS NULL OR contact_relation.valid_to > TODAY)"
		    END IF


	    END IF
	}
	IF tmp_where_part matches "*no_table.in_relation_of*" THEN 
		LET send1 = tmp_where_part[1,200] 
		LET send2 = tmp_where_part[201,400] 
		LET send3 = tmp_where_part[401,600] 
		LET send4 = tmp_where_part[601,800] 

		CALL cmreplace_string ( 
		"no_table.in_relation_of", 
		"role.role_name", 
		send1, send2, send3, send4 
		) RETURNING 
		return1, return2, return3, return4 

		LET tmp_where_part = return1, return2, return3, return4 

		IF NOT role_added THEN 
			LET from_part = from_part clipped, 
			", role " 
			LET role_added = true 
		END IF 

		IF NOT contact_relation_added THEN 
			LET from_part = from_part clipped, 
			", contact_relation " 
			LET contact_relation_added = true 
		END IF 

		LET tmp_where_part = tmp_where_part clipped, 
		" AND role.role_code = contact_relation.role_code ", 
		" AND role.class_name = 'RELATION' ", 
		" AND contact_relation.contact_id_pri = contact.contact_id " 
		IF show_valid THEN 
			LET tmp_where_part = tmp_where_part clipped, 
			" AND (contact_relation.valid_to IS NULL OR contact_relation.valid_to > TODAY)" 
		END IF 

	END IF 


	IF tmp_where_part matches "*address.city*" OR 
	tmp_where_part matches "*address.suburb*" THEN 
		LET from_part = from_part clipped, 
		", address, contact_address " 

		LET tmp_where_part = tmp_where_part clipped, 
		" AND address.address_id = contact_address.address_id ", 
		" AND contact_address.contact_id = contact.contact_id " 
		IF show_valid THEN 
			LET tmp_where_part = tmp_where_part clipped, 
			" AND (contact_address.valid_to IS NULL OR contact_address.valid_to > TODAY)" 
		END IF 

	END IF 

	IF 
	tmp_where_part matches "*phone.area_code*" 
	OR 
	tmp_where_part matches "*phone.phone_number*" 
	THEN 
		LET from_part = from_part clipped, 
		", phone, contact_phone " 

		LET tmp_where_part = tmp_where_part clipped, 
		" AND phone.phone_id = contact_phone.phone_id ", 
		" AND contact_phone.contact_id = contact.contact_id " 
		IF show_valid THEN 
			LET tmp_where_part = tmp_where_part clipped, 
			" AND (contact_phone.valid_to IS NULL OR contact_phone.valid_to > TODAY)" 
		END IF 

	END IF 

	IF tmp_where_part matches "*bank_acc.bank_name*" OR 
	tmp_where_part matches "*bank_acc.bank_branch*" THEN 
		LET from_part = from_part clipped, 
		", bank_acc, contact_bank_acc " 

		LET tmp_where_part = tmp_where_part clipped, 
		" AND bank_acc.acc_id = contact_bank_acc.acc_id ", 
		" AND contact_bank_acc.contact_id = contact.contact_id " 
		IF show_valid THEN 
			LET tmp_where_part = tmp_where_part clipped, 
			" AND (contact_bank_acc.valid_to IS NULL OR contact_bank_acc.valid_to > TODAY)" 
		END IF 


	END IF 

	IF tmp_where_part matches "*credit_card.cc_no*" THEN 
		LET from_part = from_part clipped, 
		", credit_card, contact_cc " 

		LET tmp_where_part = tmp_where_part clipped, 
		" AND credit_card.cc_id = contact_cc.cc_id ", 
		" AND contact_cc.contact_id = contact.contact_id " 
		IF show_valid THEN 
			LET tmp_where_part = tmp_where_part clipped, 
			" AND (contact_cc.valid_to IS NULL OR contact_cc.valid_to > TODAY)" 
		END IF 
	END IF 

	IF tmp_where_part matches "*comment.comment_text*" THEN 
		LET from_part = from_part clipped, 
		", comment, contact_comment " 

		LET tmp_where_part = tmp_where_part clipped, 
		" AND comment.comment_id = contact_comment.comment_id ", 
		" AND contact_comment.contact_id = contact.contact_id " 
		IF show_valid THEN 
			LET tmp_where_part = tmp_where_part clipped, 
			" AND (contact_comment.date_closed IS NULL OR contact_comment.date_closed > TODAY)" 
		END IF 
	END IF 

	IF tmp_where_part matches "*mailing_role.mailing_name*" THEN 
		LET from_part = from_part clipped, 
		", mailing_role, contact_mailing " 

		LET tmp_where_part = tmp_where_part clipped, 
		" AND mailing_role.mailing_role_code = contact_mailing.mailing_role_code ", 
		" AND contact_mailing.contact_id = contact.contact_id " 
		IF show_valid THEN 
			LET tmp_where_part = tmp_where_part clipped, 
			" AND (contact_mailing.valid_to IS NULL OR contact_mailing.valid_to > TODAY)" 
		END IF 
	END IF 


	LET where_part = tmp_where_part 
	LET from_part = " FROM contact ", from_part clipped 

	LET from_and_where = 
	"SELECT * ", 
	from_part clipped, 
	" WHERE ", 
	where_part clipped 


	LET last_where_part = from_and_where 

	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 
	LET send4 = where_part[601,800] 

	CLOSE WINDOW w_composite 

	RETURN send1, send2, send3, send4, from_part 

END FUNCTION #qbe_composite() 


#####################################
FUNCTION switch_contact(tmp_contact_id) 
	#####################################
	DEFINE 
	success 
	SMALLINT, 
	where_part 
	CHAR (800), 
	tmp_contact_id LIKE contact.contact_id, 
	send1, send2, send3, send4 #where_part 
	CHAR (200) 


	LET where_part = 
	"SELECT * FROM contact WHERE contact.contact_id = ", tmp_contact_id 

	CURRENT WINDOW IS w_contact 

	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 
	LET send4 = where_part[601,800] 

	LET success = open_cursor(send1, send2, send3, send4) 

	CURRENT WINDOW IS w_info 

END FUNCTION 

################################################
FUNCTION open_cursor(send1, send2, send3, send4) 
	################################################
	DEFINE 
	where_part 
	CHAR (800), 
	send1, send2, send3, send4 #where_part 
	CHAR (200), 
	dummy_contact 
	RECORD LIKE contact.* 

		LET where_part = send1, send2, send3, send4 

		IF show_valid THEN 
			LET where_part = where_part clipped, 
			" AND (contact.valid_to IS NULL OR contact.valid_to > TODAY)" 
		END IF 

		IF do_debug THEN 
			CALL errorlog(where_part) 
		END IF 
		MESSAGE "Searching...please wait" 
		PREPARE x1 FROM where_part 
		DECLARE c_read_contact SCROLL CURSOR with HOLD FOR x1 
		OPEN c_read_contact 

		FETCH FIRST c_read_contact INTO g_contact.* 

		IF 
		status = notfound 
		THEN 
			MESSAGE "" 
			ERROR "No records found" 
			INITIALIZE g_contact.* TO NULL 
			CLEAR FORM 
			RETURN false 
		ELSE 
			CALL get_codes() 
			CALL display_contact() 

			FETCH NEXT c_read_contact INTO dummy_contact.* 

			IF 
			status <> notfound 
			THEN 
				ERROR "Query returned more THEN one record" 
					MESSAGE "" 
					FETCH previous c_read_contact INTO dummy_contact.* 
				END IF 

				RETURN true 
			END IF 

END FUNCTION #read_qbf() 

###################
FUNCTION n_contact() 
	###################

	IF 
	g_contact.contact_id IS NULL 
	THEN 
		ERROR "Please enter Query condition first !" 
		RETURN false 
	END IF 

	FETCH NEXT c_read_contact INTO g_contact.* 

	IF 
	status = notfound 
	THEN 
		ERROR "No more records found" 
		CALL display_contact() 
		RETURN false 
	ELSE 
		CALL get_codes() 
		CALL display_contact() 
		RETURN true 
	END IF 

END FUNCTION #read_next() 

###################
FUNCTION p_contact() 
	###################

	IF g_contact.contact_id IS NULL THEN 
		ERROR "Please enter Query condition first !" 
		RETURN false 
	END IF 


	FETCH previous c_read_contact INTO g_contact.* 
	IF status = notfound THEN 
		ERROR "No previous records found" 
		CALL display_contact() 
		RETURN false 
	ELSE 
		CALL get_codes() 
		CALL display_contact() 
		RETURN true 
	END IF 

END FUNCTION #read_previous() 

####################
FUNCTION get_codes() 
	####################

	{
		SELECT salutation_name INTO c_contact.salutation
			FROM salutation
				WHERE salutation_code = g_contact.salutation_code

	    if STATUS = NOTFOUND THEN
	        INITIALIZE c_contact.salutation TO NULL
	    END IF
	}

	LET c_contact.age = get_role_name(g_contact.age_role_code, "AGE") 

END FUNCTION 


############################
FUNCTION au_contact(add_mode) 
	############################
	DEFINE 
	add_mode, 
	success 
	SMALLINT, 
	#    new_salutation_code LIKE salutation.salutation_code,
	#	new_salutation LIKE salutation.salutation_name,
	new_age_code LIKE role.role_code, 
	new_age LIKE role.role_name, 
	store_contact RECORD LIKE contact.*, 
	existing_contact_id 
	LIKE contact.contact_id 


	IF current_form <> 1 THEN 
		CALL d_contact1() 
	END IF 

	IF add_mode THEN 
		INITIALIZE g_contact TO NULL 
		INITIALIZE c_contact TO NULL 
		CLEAR FORM 
		MESSAGE "Enter the new contact data AND press Accept" 
	ELSE 
		IF g_contact.contact_id IS NULL THEN 
			ERROR "Please SELECT the contact TO modify" 
			SLEEP 2 
			RETURN false 
		END IF 

		LET store_contact.* = g_contact.* 
		MESSAGE "Enter changes AND press Accept" 
	END IF 

	#############
	INPUT BY NAME 
	#############
	g_contact.last_org_name, 
	g_contact.first_name, 
	g_contact.mid_name, 
	g_contact.initials, 
	g_contact.salutation, 
	g_contact.sex_ind, 
	g_contact.title, 
	g_contact.org_ind, 
	c_contact.age, 
	g_contact.user_defined1, 
	g_contact.user_defined2 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","contact","input-g_contact-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			##########################
		ON KEY (escape) 
			##########################

			IF do_debug THEN 
				ERROR g_contact.last_org_name clipped 
				SLEEP 3 
			END IF 


			#        ERROR "ON KEY escape" sleep 1

			IF accept_enter THEN #accept KEY IS enter, so WHEN esc IS pressed, it IS abort 
				LET int_flag = true 
				GOTO after_input 
			ELSE #accept KEY IS escape,so WHEN esc IS pressed, it IS accept 
				LET int_flag = false 
				GOTO after_input 
			END IF 

			##########################
			#		ON KEY (enter)
		ON KEY (RETURN) 
			##########################
			{
			Acceptable VALUES of key (in lowercase OR uppercase letters) FOR the ON KEY block are:

			ACCEPT HELP NEXT OR RETURN OR ENTER
			DELETE INSERT NEXTPAGE RIGHT
			DOWN INTERRUPT PREVIOUS OR TAB
			ESC OR ESCAPE LEFT PREVPAGE UP
			F1 through F64
			CONTROL-CHAR (except A, D, H, I, J, L, M, R, OR X)


			Built-in functions that access field buffers AND keystroke buffers:

			Built-In Funtion 		Description
			FIELD_TOUCHED(field) 	Returns TRUE WHEN the user has made a change TO SCREEN field.
			GET_FLDBUF(field-list) 	Returns the character VALUES of the contents of one OR more fields.
			FGL_LASTKEY( ) 			Returns an INTEGER value corresponding TO the most recent keystroke.
			INFIELD(field) 			Returns TRUE IF field IS the name of the current SCREEN field.
			}
			#        ERROR "ON KEY enter" sleep 1

			IF accept_enter THEN #accept KEY IS enter, so WHEN enter IS pressed, it IS accept 
				LET int_flag = false 
				GOTO after_input 

				                {---------------------------------------------------------
					            if length (g_contact.last_org_name) < 1 THEN
					                ERROR "This IS a required field"
					                NEXT FIELD last_org_name
					            END IF

					            if length (g_contact.org_ind) < 1 THEN
					                ERROR "This IS a required field"
					                NEXT FIELD org_ind
					            END IF

					   			LET g_contact.last_org_name_up = upshift(g_contact.last_org_name)
								LET g_contact.first_name_up = upshift (g_contact.first_name)
								LET g_contact.mid_name_up = upshift (g_contact.mid_name)


						        if add_mode THEN
				#AND #NOT dup_checked
							        CALL is_dup_contact(g_contact.*, c_contact.age)
					                    returning success, existing_contact_id
									if
					                    success
							        THEN
							            LET int_flag = TRUE
									END IF
						        END IF

								LET int_flag = FALSE
				                EXIT INPUT
				-------------------------------------------------------------}
				            ELSE #accept key IS escape,so WHEN enter IS pressed, it IS NEXT FIELD
				                NEXT FIELD next
							END IF

				############
						ON KEY (f10)
				############

				####
						CASE
				####
				#################
							WHEN infield(age)
				#################

							IF g_contact.org_ind = "P"
				            OR	g_contact.org_ind IS NULL THEN
								CALL role_lp("AGE")
									returning new_age_code, new_age

				                IF new_age_code IS NOT NULL THEN
							         LET g_contact.age_role_code = new_age_code
				                     LET c_contact.age = new_age
									 DISPLAY BY NAME c_contact.age
				                     LET g_contact.org_ind = "P"
									 DISPLAY BY NAME  g_contact.org_ind
								END IF
							END IF

				########
						END CASE
				########

				###############
						AFTER FIELD age
				###############
				        if c_contact.age IS NOT NULL
						 OR g_contact.org_ind = "P" THEN
				            LET g_contact.age_role_code = get_role_code(c_contact.age, "AGE")

				            if g_contact.age_role_code IS NULL THEN
								CALL role_lp("AGE")
				                    returning g_contact.age_role_code, c_contact.age

				                if g_contact.age_role_code IS NULL THEN
				                    ERROR "User must enter valid age (F10=L&P)"
									NEXT FIELD age
				                END IF
				            END IF

				            DISPLAY BY NAME c_contact.age
				        END IF

				###################
				        AFTER FIELD org_ind
				###################
				        IF g_contact.org_ind = "P" THEN
				{            if c_contact.salutation IS NULL THEN
				                NEXT FIELD salutation
				            END IF
				 }
				IF c_contact.age IS NULL THEN 
					NEXT FIELD age 
				END IF 
			ELSE 
				INITIALIZE c_contact.age TO NULL 
				INITIALIZE g_contact.age_role_code TO NULL 
				DISPLAY BY NAME c_contact.age #, c_contact.salutation 
			END IF 

			IF add_mode THEN 
				CALL is_dup_contact(g_contact.*, c_contact.age) 
				RETURNING success, existing_contact_id 

				IF success THEN 
					LET int_flag = true 
					EXIT INPUT 
				END IF 
			END IF 

			###################
		AFTER FIELD sex_ind 
			###################
			IF g_contact.org_ind = "P" THEN 
				IF g_contact.sex_ind IS NULL THEN 
					ERROR "Please enter M OR F" 
					NEXT FIELD sex_ind 
				END IF 
			END IF 

			###################
		AFTER INPUT 
			###################
			LABEL after_input: 
			###################

			#        ERROR "AFTER INPUT block..." sleep 3



			IF int_flag THEN 
				EXIT INPUT 
			END IF 

			IF do_debug THEN 
				ERROR g_contact.last_org_name clipped 
				SLEEP 3 
			END IF 


			IF length (g_contact.last_org_name) < 1 THEN 
				ERROR "This IS a required field" 
				NEXT FIELD last_org_name 
			END IF 

			IF length (g_contact.org_ind) < 1 THEN 
				ERROR "This IS a required field" 
				NEXT FIELD org_ind 
			END IF 

			LET g_contact.last_org_name_up = upshift(g_contact.last_org_name) 
			LET g_contact.first_name_up = upshift (g_contact.first_name) 
			LET g_contact.mid_name_up = upshift (g_contact.mid_name) 


			IF add_mode THEN 
				CALL is_dup_contact(g_contact.*, c_contact.age) 
				RETURNING success, existing_contact_id 
				IF success THEN 
					LET int_flag = true 
				END IF 
			END IF 

			EXIT INPUT 

			#########
	END INPUT 
	#########

	MESSAGE "" 


	IF int_flag THEN 
		LET int_flag = false 
		IF add_mode THEN 
			CLEAR FORM 
		END IF 

		#RETURN existing_contact_id
		RETURN false 
	END IF 

	IF NOT add_mode THEN 
		#any change FOR UPDATE?
		IF g_contact.first_name = store_contact.first_name 
		AND g_contact.mid_name = store_contact.mid_name 
		AND g_contact.title = store_contact.title 
		AND g_contact.initials = store_contact.initials 
		AND g_contact.org_ind = store_contact.org_ind 
		AND g_contact.sex_ind = store_contact.sex_ind 
		AND g_contact.user_defined1 = store_contact.user_defined1 
		AND g_contact.user_defined2 = store_contact.user_defined2 
		AND g_contact.salutation = store_contact.salutation 
		AND g_contact.age_role_code = store_contact.age_role_code THEN 
			ERROR "Nothing changed: nothing TO UPDATE" 
			SLEEP 1 
			RETURN 
		END IF 
	END IF 

	LET success = do_store_contact(add_mode) 
	RETURN success 

END FUNCTION #au_contact() 

###############################
FUNCTION do_store_contact(add_mode) 
	###############################
	DEFINE 
	add_mode SMALLINT 


	##########
	BEGIN WORK 
		##########

		IF NOT add_mode THEN #logical UPDATE 
			#first, close previous RECORD FOR this contact
			UPDATE contact SET 
			valid_to = today 
			WHERE contact_seed = g_contact.contact_seed 

			IF status <> 0 THEN 
				ERROR "Cannot close previous record: Update aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 

		END IF 

		LET g_contact.contact_seed = 0 
		LET g_contact.valid_from = today 
		LET g_contact.mod_user_id = glob_rec_kandoouser.sign_on_code 
		LET g_contact.cmpy_code = glob_rec_kandoouser.cmpy_code 

		INSERT INTO contact VALUES (g_contact.*) 

		IF status <> 0 THEN 
			ERROR "Cannot INSERT new record: Update/Add aborted !" 
			SLEEP 5 
			ROLLBACK WORK 
			RETURN false 
		END IF 

		IF add_mode THEN 
			LET g_contact.contact_id = sqlca.sqlerrd[2] 

			UPDATE contact SET 
			contact_id = g_contact.contact_id 
			WHERE contact_seed = g_contact.contact_id 

			IF status <> 0 THEN 
				ERROR "Cannot assign contact ID: Add aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 
		END IF 

		###########
	COMMIT WORK 
	###########

	RETURN true #success 


END FUNCTION #do_store_contact() 

###################
FUNCTION del_contact() 
	###################

	IF g_contact.contact_id IS NULL THEN 
		ERROR "Please first SELECT the contact TO delete" 
		SLEEP 2 
		RETURN 
	END IF 

	MESSAGE "Mark this contact information deleted?" 

	MENU "Confirm" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact","menu-Confirm-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete this record" 
			MESSAGE"" 
			EXIT MENU 

		COMMAND "OK" "Delete this record" 
			MESSAGE"" 
			UPDATE contact SET 
			valid_to = today 
			WHERE contact_seed = g_contact.contact_seed 

			CLEAR FORM 
			CALL clear_info() 
			CURRENT WINDOW IS w_contact 

			EXIT MENU 
	END MENU 

	MESSAGE "" 

END FUNCTION #d_contact() 


######################
FUNCTION next_screen() 
	######################

	CASE current_form 
		WHEN 1 
			CALL d_contact2() 
		WHEN 2 
			CALL d_contact1() 
		OTHERWISE 
			ERROR "Unknown form: contact.4gl, next_screen()" 
			EXIT program 
	END CASE 

END FUNCTION 

####################
FUNCTION d_contact1() 
	####################

	DISPLAY FORM f_contact1 
	LET current_form = 1 
	CALL display_contact() 

END FUNCTION 

####################
FUNCTION d_contact2() 
	####################

	DISPLAY FORM f_contact2 
	LET current_form = 2 
	CALL display_contact() 

END FUNCTION 

##########################
FUNCTION display_contact() 
	##########################

	IF g_contact.contact_id IS NULL THEN 
		#TO prevent uninitialised dates
		#FROM displaying as 31/12/1899
		INITIALIZE g_contact.* TO NULL 
	END IF 

	CASE current_form 

		WHEN 1 #contact1.per 
			DISPLAY BY NAME 
			g_contact.last_org_name, 
			g_contact.first_name, 
			g_contact.mid_name, 
			g_contact.title, 
			g_contact.initials, 
			g_contact.org_ind, 
			g_contact.sex_ind, 
			g_contact.user_defined1, 
			g_contact.user_defined2, 
			g_contact.salutation, 
			c_contact.age 

		WHEN 2 #contact2.per 
			DISPLAY BY NAME 
			g_contact.contact_id, 
			g_contact.valid_from, 
			g_contact.valid_to, 
			g_contact.mod_user_id 

		OTHERWISE 

			ERROR "Unknown form: contact.4gl, display_contact()" 
			EXIT program 
	END CASE 

END FUNCTION #display_contact() 

######################
FUNCTION clear_info() 
	######################
	CURRENT WINDOW IS w_info 
	CLEAR FORM 
	MESSAGE "" 
END FUNCTION 

###################
FUNCTION info_win() 
	###################

	CURRENT WINDOW IS w_info 

	DISPLAY FORM f_info 

END FUNCTION 

###############################
FUNCTION contact_info(disp_mode) 
	###############################
	DEFINE disp_mode SMALLINT, 

	a_info ARRAY [11] OF RECORD 
		info_line CHAR(70) 
	END RECORD, 
	cnt 
	SMALLINT 

	CALL info_win() 

	IF 
	g_contact.contact_id IS NULL 
	THEN 
		ERROR "Please query FOR contact first" 
		SLEEP 2 
		RETURN 
	END IF 

	IF show_valid THEN 
		MESSAGE "General information summary: Active only" 
	ELSE 
		MESSAGE "General information summary: Active AND History" 
	END IF 

	LET a_info[1].info_line = get_addr_roles_info() 
	LET a_info[2].info_line = get_phone_roles_info() 
	LET a_info[3].info_line = get_contact_roles_info() 
	LET a_info[4].info_line = get_contact_comment_info() 
	LET a_info[5].info_line = get_mailing_info() 
	LET a_info[6].info_line = get_bank_info() 
	LET a_info[7].info_line = get_cc_info() 
	LET a_info[8].info_line = get_relations_info() 

	CALL set_count(8) 

	################################
	##- 20170729 modif ericv

	### Problem IS here
	INPUT ARRAY a_info 
	WITHOUT DEFAULTS 
	FROM s_info.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","contact","input-a_info-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			################################
			##########
		BEFORE ROW #field info_line FOR <suse> 
			EXIT INPUT 

			###########
	END INPUT 
	###########

	LET last_circle = 1 

	RETURN 

END FUNCTION 

###############################
FUNCTION get_addr_roles_info() 
	###############################
	DEFINE 
	where_part 
	CHAR(800), 
	info_line 
	CHAR(70), 
	cnt 
	SMALLINT, 

	a_roles_info array[20] 
	OF INTEGER, 
	tmp_addr_role_name 
	LIKE role.role_name 



	LET where_part = 
	"SELECT unique role_code FROM contact_address ", 
	"WHERE contact_id = ", g_contact.contact_id 

	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_address.valid_to IS NULL OR contact_address.valid_to > TODAY)" 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE s1 FROM where_part 
	DECLARE c_roles_info CURSOR FOR s1 


	LET cnt = 1 

	###########################################
	FOREACH c_roles_info INTO a_roles_info[cnt] 
		###########################################

		LET tmp_addr_role_name = get_role_name(a_roles_info[cnt],"ADDRESS") 

		IF cnt = 1 THEN 
			LET info_line = tmp_addr_role_name clipped 
		ELSE 
			LET info_line = info_line clipped, 
			",", tmp_addr_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_roles_info 
	FREE c_roles_info 
	MESSAGE "" 
	IF cnt = 1 THEN 
		LET info_line = "No address info" 
	ELSE 
		LET info_line = "Address: ", info_line clipped 
	END IF 

	RETURN info_line 

END FUNCTION #get_addr_role_info() 


###############################
FUNCTION get_phone_roles_info() 
	###############################
	DEFINE 
	where_part 
	CHAR(800), 
	info_line 
	CHAR(70), 
	cnt 
	SMALLINT, 

	a_roles_info array[20] 
	OF INTEGER, 
	tmp_phone_role_name 
	LIKE role.role_name 


	LET where_part = 
	"SELECT unique role_code FROM contact_phone ", 
	"WHERE contact_id = ", g_contact.contact_id 

	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_phone.valid_to IS NULL OR contact_phone.valid_to > TODAY)" 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE s2 FROM where_part 
	DECLARE c_ph_roles_info CURSOR FOR s2 


	LET cnt = 1 

	###########################################
	FOREACH c_ph_roles_info INTO a_roles_info[cnt] 
		###########################################

		LET tmp_phone_role_name = get_role_name(a_roles_info[cnt],"PHONE") 

		IF 
		cnt = 1 
		THEN 
			LET info_line = tmp_phone_role_name clipped 
		ELSE 
			LET info_line = info_line clipped, 
			",", tmp_phone_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_ph_roles_info 
	FREE c_ph_roles_info 
	MESSAGE "" 
	IF cnt = 1 THEN 
		LET info_line = "No phone number info" 
	ELSE 
		LET info_line = "Phone: ", info_line clipped 
	END IF 

	RETURN info_line 

END FUNCTION #get_phone_role_info() 


###############################
FUNCTION get_contact_roles_info() 
	###############################
	DEFINE 
	where_part 
	CHAR(800), 
	info_line 
	CHAR(70), 
	cnt 
	SMALLINT, 

	a_roles_info array[20] 
	OF INTEGER, 
	tmp_role_name 
	LIKE role.role_name 


	LET where_part = 
	"SELECT unique role_code FROM contact_role ", 
	"WHERE contact_id = ", g_contact.contact_id 

	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_role.valid_to IS NULL OR contact_role.valid_to > TODAY)" 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE s3 FROM where_part 
	DECLARE c_per_roles_info CURSOR FOR s3 


	LET cnt = 1 

	###########################################
	FOREACH c_per_roles_info INTO a_roles_info[cnt] 
		###########################################

		LET tmp_role_name = get_role_name(a_roles_info[cnt],"CONTACT ROLE") 
		IF cnt = 1 THEN 
			LET info_line = tmp_role_name clipped 
		ELSE 
			LET info_line = info_line clipped, 
			",", tmp_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_per_roles_info 
	FREE c_per_roles_info 
	MESSAGE "" 
	IF cnt = 1 THEN 
		LET info_line = "No contact role info" 
	ELSE 
		LET info_line = "contact roles: ", info_line clipped 
	END IF 

	RETURN info_line 

END FUNCTION #get_contact_role_info() 


###################################
FUNCTION get_contact_comment_info() 
	###################################
	DEFINE 
	info_line 
	CHAR(70), 
	comment_cnt 
	SMALLINT 


	IF 
	show_valid 
	THEN 
		SELECT count(*) INTO comment_cnt FROM contact_comment 
		WHERE contact_id = g_contact.contact_id 
		AND (contact_comment.date_closed IS null) 
	ELSE 
		SELECT count(*) INTO comment_cnt FROM contact_comment 
		WHERE contact_id = g_contact.contact_id 
	END IF 

	IF comment_cnt > 0 THEN 
		LET info_line = "Notes: ", comment_cnt USING "####" 
	ELSE 
		LET info_line = "No Notes information" 
	END IF 


	RETURN info_line 

END FUNCTION #get_contact_comment_info() 


###########################
FUNCTION get_mailing_info() 
	###########################
	DEFINE 
	where_part 
	CHAR(800), 
	info_line 
	CHAR(70), 
	cnt 
	SMALLINT, 

	a_roles_info array[20] 
	OF INTEGER, 
	tmp_role_name 
	LIKE role.role_name 


	LET where_part = 
	"SELECT unique mailing_role_code FROM contact_mailing ", 
	"WHERE contact_id = ", g_contact.contact_id 

	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_mailing.valid_to IS NULL OR contact_mailing.valid_to > TODAY)" 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE s4 FROM where_part 
	DECLARE c_mailing_info CURSOR FOR s4 


	LET cnt = 1 

	###########################################
	FOREACH c_mailing_info INTO a_roles_info[cnt] 
		###########################################


		SELECT mailing_name INTO tmp_role_name 
		FROM mailing_role 
		WHERE mailing_role_code = a_roles_info[cnt] 

		IF cnt = 1 THEN 
			LET info_line = tmp_role_name clipped 
		ELSE 
			LET info_line = info_line clipped, 
			",", tmp_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_mailing_info 
	FREE c_mailing_info 
	MESSAGE "" 
	IF cnt = 1 THEN 
		LET info_line = "No mailing info" 
	ELSE 
		LET info_line = "Mailing roles: ", info_line clipped 
	END IF 

	RETURN info_line 

END FUNCTION #get_mailing_info() 

###############################
FUNCTION get_bank_info() 
	###############################
	DEFINE 
	where_part 
	CHAR(800), 
	info_line 
	CHAR(70), 
	cnt 
	SMALLINT, 

	a_roles_info array[20] 
	OF INTEGER, 
	tmp_role_name 
	LIKE role.role_name 


	LET where_part = 
	"SELECT unique role_code FROM contact_bank_acc ", 
	"WHERE contact_id = ", g_contact.contact_id 

	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_bank_acc.valid_to IS NULL OR contact_bank_acc.valid_to > TODAY)" 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE s5 FROM where_part 
	DECLARE c_bank_info CURSOR FOR s5 


	LET cnt = 1 

	###########################################
	FOREACH c_bank_info INTO a_roles_info[cnt] 
		###########################################

		LET tmp_role_name = get_role_name(a_roles_info[cnt],"BANK ACCOUNT") 

		IF cnt = 1 THEN 
			LET info_line = tmp_role_name clipped 
		ELSE 
			LET info_line = info_line clipped, 
			",", tmp_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_bank_info 
	FREE c_bank_info 
	MESSAGE "" 
	IF cnt = 1 THEN 
		LET info_line = "No Bank acc info" 
	ELSE 
		LET info_line = "Bank acc. roles: ", info_line clipped 
	END IF 

	RETURN info_line 

END FUNCTION #get_bank_info() 


###############################
FUNCTION get_cc_info() 
	###############################
	DEFINE 
	where_part 
	CHAR(300), 
	info_line 
	CHAR(70), 
	cnt 
	SMALLINT, 

	a_roles_info array[20] 
	OF INTEGER, 
	tmp_role_name 
	LIKE role.role_name 


	LET where_part = 
	"SELECT unique role_code FROM contact_cc ", 
	"WHERE contact_id = ", g_contact.contact_id 

	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_cc.valid_to IS NULL OR contact_cc.valid_to > TODAY)" 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE s6 FROM where_part 
	DECLARE c_cc_info CURSOR FOR s6 


	LET cnt = 1 

	###########################################
	FOREACH c_cc_info INTO a_roles_info[cnt] 
		###########################################
		LET tmp_role_name = get_role_name(a_roles_info[cnt],"CREDIT CARD") 

		IF cnt = 1 THEN 
			LET info_line = tmp_role_name clipped 
		ELSE 
			LET info_line = info_line clipped, 
			",", tmp_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_cc_info 
	FREE c_cc_info 
	MESSAGE "" 
	IF cnt = 1 THEN 
		LET info_line = "No credit card info" 
	ELSE 
		LET info_line = "Credit card roles: ", info_line clipped 
	END IF 

	RETURN info_line 

END FUNCTION #get_cc_info() 



#############################
FUNCTION get_relations_info() 
	#############################
	DEFINE 
	where_part 
	CHAR(300), 
	info_line 
	CHAR(70), 
	cnt 
	SMALLINT, 

	a_roles_info array[20] 
	OF INTEGER, 
	tmp_role_name 
	LIKE role.role_name 


	LET where_part = 
	"SELECT unique role_code FROM contact_relation ", 
	"WHERE contact_id_pri = ", g_contact.contact_id, 
	" OR contact_id_sec = ", g_contact.contact_id 

	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_relation.valid_to IS NULL OR contact_relation.valid_to > TODAY)" 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE s7 FROM where_part 
	DECLARE c_relation_info CURSOR FOR s7 


	LET cnt = 1 

	###########################################
	FOREACH c_relation_info INTO a_roles_info[cnt] 
		###########################################

		LET tmp_role_name = get_role_name(a_roles_info[cnt],"RELATION") 
		IF cnt = 1 THEN 
			LET info_line = tmp_role_name clipped 
		ELSE 
			LET info_line = info_line clipped, 
			",", tmp_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_relation_info 
	FREE c_relation_info 
	MESSAGE "" 
	IF cnt = 1 THEN 
		LET info_line = "No contact relations info" 
	ELSE 
		LET info_line = "contact relations: ", info_line clipped 
	END IF 

	RETURN info_line 

END FUNCTION #get_relations_info() 

###################################
FUNCTION circle_info(reverse_order) 
	###################################
	DEFINE 
	reverse_order 
	SMALLINT 


	IF g_contact.contact_id IS NULL THEN 
		ERROR "Please SELECT contact first" 
		SLEEP 2 
		RETURN 
	END IF 

	#DISPLAY default address
	IF (not reverse_order AND last_circle = 1) 
	OR 
	(reverse_order AND last_circle = 3) THEN 
		CALL init_addr() 
		MESSAGE "Default address:" 
		CURRENT WINDOW IS w_contact 
		LET last_circle = 2 
		RETURN 
	END IF 

	#DISPLAY address history
	IF (not reverse_order AND last_circle = 2) 
	OR (reverse_order AND last_circle = 4) THEN 
		LET dummy = address_hist("2",TRUE,TRUE) 
		MESSAGE "Address history:" 
		CURRENT WINDOW IS w_contact 
		LET last_circle = 3 
		RETURN 
	END IF 

	#diplay all address roles
	IF (not reverse_order AND last_circle = 3) 
	OR (reverse_order AND last_circle = 5) THEN 
		LET dummy = all_address_roles(2,true) 
		MESSAGE "Address roles:" 
		CURRENT WINDOW IS w_contact 
		LET last_circle = 4 
		RETURN 
	END IF 

	#DISPLAY comment history
	IF (not reverse_order AND last_circle = 4) OR 
	(reverse_order AND last_circle = 6) THEN 
		CALL init_comment() 
		MESSAGE "Comments history:" 
		CURRENT WINDOW IS w_contact 
		LET last_circle = 5 
		RETURN 
	END IF 


	#Mailing roles

	IF (not reverse_order AND last_circle = 5) 
	OR (reverse_order AND last_circle = 7) THEN 
		CALL init_contact_mailing() 
		#MESSAGE "All Roles of this contact:"
		CURRENT WINDOW IS w_contact 
		LET last_circle = 6 
		RETURN 
	END IF 

	#Phone role
	IF (not reverse_order AND last_circle = 6) 
	OR (reverse_order AND last_circle = 8) THEN 
		LET dummy = all_phone_roles(2,true) 
		MESSAGE "All Phone number roles of this contact:" 
		CURRENT WINDOW IS w_contact 
		LET last_circle = 7 
		RETURN 
	END IF 

	#Default phone
	IF (not reverse_order AND last_circle = 7) 
	OR (reverse_order AND last_circle = 9) THEN 
		CALL init_phone() 
		#MESSAGE "All Roles of this contact:"
		CURRENT WINDOW IS w_contact 
		LET last_circle = 8 
		RETURN 
	END IF 

	#Bank acc roles
	IF (not reverse_order AND last_circle = 8) 
	OR (reverse_order AND last_circle = 10) THEN 
		LET dummy = all_bank_acc_roles(2,true) 
		MESSAGE "All Bank Acc Roles of this contact:" 
		CURRENT WINDOW IS w_contact 
		LET last_circle = 9 
		RETURN 
	END IF 

	#Default bank acc
	IF (not reverse_order AND last_circle = 9) 
	OR (reverse_order AND last_circle = 11) THEN 
		CALL init_bank_acc() 
		#MESSAGE "All Roles of this contact:"
		CURRENT WINDOW IS w_contact 
		LET last_circle = 10 
		RETURN 
	END IF 

	#CC roles
	IF (not reverse_order AND last_circle = 10) 
	OR (reverse_order AND last_circle = 12) THEN 
		LET dummy = all_cc_roles(2,true) 
		MESSAGE "All Credit Card Roles of this contact:" 
		CURRENT WINDOW IS w_contact 
		LET last_circle = 11 
		RETURN 
	END IF 

	#Default cc
	IF (not reverse_order AND last_circle = 11) 
	OR (reverse_order AND last_circle = 13) THEN 
		CALL init_cc() 
		#MESSAGE "All Roles of this contact:"
		CURRENT WINDOW IS w_contact 
		LET last_circle = 12 
		RETURN 
	END IF 

	#contact roles
	IF (not reverse_order AND last_circle = 12) 
	OR (reverse_order AND last_circle = 14) THEN 
		CALL init_contact_role() 
		#MESSAGE "All Roles of this contact:"
		CURRENT WINDOW IS w_contact 
		LET last_circle = 13 
		RETURN 
	END IF 

	#contact relations
	IF (not reverse_order AND last_circle = 13) 
	OR (reverse_order AND last_circle = 1) THEN 
		CALL init_contact_relation() 
		#MESSAGE "All Roles of this contact:"
		CURRENT WINDOW IS w_contact 
		LET last_circle = 14 
		RETURN 
	END IF 

	#back TO general DISPLAY info
	IF 
	(NOT reverse_order AND last_circle = 14) 
	OR 
	(reverse_order AND last_circle = 2) 
	THEN 
		CALL contact_info("1") 
		CURRENT WINDOW IS w_contact 
		LET last_circle = 1 
		RETURN 
	END IF 


END FUNCTION #circle_info() 


#####################################
FUNCTION get_contact_name(p_contact_id) 
	#####################################
	DEFINE 
	p_contact_id LIKE contact_address.contact_id, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 


	SELECT last_org_name, first_name 
	INTO tmp_last, tmp_first 
	FROM contact 
	WHERE contact.contact_id = p_contact_id 
	AND (valid_to IS NULL OR valid_to > today) 


	RETURN tmp_first,tmp_last 


END FUNCTION #get_contact_name() 


#####################################
FUNCTION get_contact_record(p_contact_id) 
	#####################################
	DEFINE 
	p_contact_id LIKE contact_address.contact_id, 
	p_tmp_contact RECORD LIKE contact.* 


	SELECT * INTO p_tmp_contact.* 
	FROM contact 
	WHERE contact.contact_id = p_contact_id 
	AND valid_to IS NULL OR valid_to > today 


	RETURN p_tmp_contact.* 


END FUNCTION #get_contact_name() 


#################################################
FUNCTION get_role_code(p_role_name, p_class_name) 
	#################################################
	DEFINE 
	tmp_role_code 
	LIKE role.role_code, 
	p_role_name 
	LIKE role.role_name, 
	p_class_name 
	LIKE role.class_name 

	SELECT role_code INTO tmp_role_code 
	FROM role 
	WHERE role.role_name = p_role_name 
	AND role.class_name = p_class_name 

	IF status = notfound THEN 
		RETURN gv_null 
	ELSE 
		RETURN tmp_role_code 
	END IF 

END FUNCTION #is_valid_age() 

#################################################
FUNCTION get_role_name(p_role_code, p_class_name) 
	#################################################
	DEFINE 
	tmp_role_name 
	LIKE role.role_name, 
	p_role_code 
	LIKE role.role_code, 
	p_class_name 
	LIKE role.class_name 

	SELECT role_name INTO tmp_role_name 
	FROM role 
	WHERE role_code = p_role_code 
	AND role.class_name = p_class_name 

	IF status = notfound THEN 
		INITIALIZE tmp_role_name TO NULL 
	END IF 

	RETURN tmp_role_name 

END FUNCTION 

######################################################
FUNCTION is_default_role(tmp_role_code,tmp_class_name) 
	######################################################
	DEFINE 
	tmp_role_code LIKE role.role_code, 
	tmp_class_name LIKE role.class_name 

	SELECT * FROM role 
	WHERE role_code = tmp_role_code 
	AND class_name = tmp_class_name 
	AND role_name = "DEFAULT" 

	IF status = notfound THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 


END FUNCTION #is_default_role() 


#######################
FUNCTION clr_menudesc() 
	#######################

	OPTIONS MESSAGE line FIRST + 1 
	MESSAGE "" #clear MENU desctiption text 
	OPTIONS MESSAGE line FIRST 

END FUNCTION 


#######################################
FUNCTION get_default_code(p_class_name) 
	#######################################
	DEFINE 
	default_code LIKE role.role_code, 
	p_class_name LIKE role.class_name 


	SELECT role_code INTO default_code 
	FROM role 
	WHERE role.role_name = "DEFAULT" 
	AND role.class_name = p_class_name 


	RETURN default_code 

END FUNCTION #get_default_code() 

####################################################
FUNCTION cmreplace_string (replace_this, replace_with, 
	send1, send2, send3, send4) 
	####################################################
	DEFINE 
	replace_this, 
	replace_with, 
	replace_this_match 
	CHAR (60), 
	send1, send2, send3, send4, 
	return1, return2, return3, return4 
	CHAR (200), 
	received, 
	returned 
	CHAR(800), 
	received_len, 
	replace_this_len, 
	replace_with_len, 
	cnt 
	SMALLINT 

	LET received = send1, send2, send3, send4 

	LET received_len = length (received) 
	LET replace_this_len = length (replace_this) 
	LET replace_with_len = length (replace_with) 

	LET replace_this_match = "*",replace_this clipped,"*" 


	###########################
	FOR cnt = 1 TO received_len 
		###########################
		IF received[cnt,cnt+replace_this_len] matches replace_this_match THEN 
			IF cnt = 1 THEN 
				LET returned = 
				" ", 
				replace_with clipped, 
				" ", 
				received[((cnt+replace_this_len)),received_len] 
			ELSE 
				LET returned = 
				received[1,cnt-1], 
				" ", 
				replace_with clipped, 
				" ", 
				received[((cnt+replace_this_len)+1),received_len] 
			END IF 

			EXIT FOR 
		END IF 

		#######
	END FOR 
	#######

	LET return1 = returned[1,200] 
	LET return2 = returned[201,400] 
	LET return3 = returned[401,600] 
	LET return4 = returned[601,800] 

	IF do_debug THEN 
		CALL errorlog(returned) 
	END IF 

	RETURN return1, return2, return3, return4 

END FUNCTION #cmreplace_string() 

#############################################
FUNCTION is_dup_contact(pr_contact,p_age) 
	#############################################
	DEFINE 
	pr_contact 
	RECORD LIKE contact.*, 
		p_age 
		LIKE role.role_name, 
		where_part 
		CHAR (800), 
		cnt 
		SMALLINT, 
		a_contact ARRAY [100] OF RECORD 
			contact_id LIKE contact.contact_id, 
			last_org_name LIKE contact.last_org_name, 
			first_name LIKE contact.first_name, 
			mid_name LIKE contact.mid_name, 
			initials LIKE contact.initials, 
			title LIKE contact.title 
		END RECORD, 
		a_display ARRAY [100] OF RECORD 
			last_org_name LIKE contact.last_org_name, 
			first_name LIKE contact.first_name, 
			mid_name LIKE contact.mid_name, 
			initials LIKE contact.initials, 
			title LIKE contact.title 
		END RECORD 

		LET where_part = 
		" SELECT contact_id,last_org_name,first_name,mid_name,initials,title ", 
		" FROM contact WHERE " 

		IF 
		pr_contact.org_ind = "P" 
		THEN 
			LET where_part = where_part clipped, 
			" last_org_name_up = '", upshift (pr_contact.last_org_name),"'", 
			" AND first_name_up = '", upshift (pr_contact.first_name),"'", 
			" AND org_ind = '", pr_contact.org_ind,"'", 
			" AND sex_ind = '", pr_contact.sex_ind,"'" 

			#g_contact.mid_name,
			#g_contact.initials,
			#g_contact.salutation,
			#g_contact.title,
			#c_contact.age,
		ELSE 
			LET where_part = where_part clipped, 
			" last_org_name_up = '", upshift (pr_contact.last_org_name),"'", 
			" AND org_ind = '", pr_contact.org_ind,"'" 
		END IF 

		LET where_part = where_part clipped, 
		" AND (valid_to IS NULL OR valid_to > today) " 

		IF do_debug THEN 
			CALL errorlog(where_part) 
		END IF 
		MESSAGE "Searching...please wait" 
		PREPARE rrr33 FROM where_part 
		DECLARE c_dup_cntct CURSOR FOR rrr33 

		LET cnt = 1 

		##########################################
		FOREACH c_dup_cntct INTO a_contact[cnt].* 
			##########################################

			LET a_display[cnt].last_org_name = a_contact[cnt].last_org_name 
			LET a_display[cnt].first_name = a_contact[cnt].first_name 
			LET a_display[cnt].mid_name = a_contact[cnt].mid_name 
			LET a_display[cnt].initials = a_contact[cnt].initials 
			LET a_display[cnt].title = a_contact[cnt].title 

			LET cnt = cnt + 1 

			###########
		END FOREACH 
		###########

		CLOSE c_dup_cntct 
		FREE c_dup_cntct 
		MESSAGE "" 
		LET cnt = cnt - 1 

		IF cnt = 0 THEN 
			RETURN false, gv_null 
		ELSE 
			OPEN WINDOW w_dup_contact with FORM "contact_lp" 
			CALL winDecoration("contact_lp") -- albo kd-766 

			LET g_msg = 
			"Total of ", cnt USING "#&", " contacts appear TO be simmilar(Abort/Accept/F10=info)?" 
			MESSAGE g_msg attribute (red) 

			OPTIONS MESSAGE line FIRST + 1 
			LET g_msg = 
			"IF required contact IS on this list, highlite it AND press Abbort, OTHERWISE press Accept" 
			MESSAGE g_msg attribute (red) 
			OPTIONS MESSAGE line FIRST 



			CALL set_count (cnt) 

			#######################################
			DISPLAY ARRAY a_display TO s_display.* 
			#######################################

				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","contact","display_arr-a_display-1") -- albo kd-513 

					############
				ON KEY (F10) #info 
					############
					LET cnt = arr_curr() #scr_line() 
					LET g_contact.contact_id = a_contact[cnt].contact_id 
					CALL contact_info("1") 
					CURRENT WINDOW IS w_dup_contact #w_contact 

				ON ACTION "WEB-HELP" -- albo 
					CALL onlinehelp(getmoduleid(),null) 
					###########
			END DISPLAY 
			###########

			LET cnt = arr_curr() 

			CLOSE WINDOW w_dup_contact 

			CALL info_win() 
			MESSAGE "" 

			CALL clear_info() 

			IF int_flag THEN 
				LET int_flag = false 
				RETURN true, a_contact[cnt].contact_id 
			ELSE 
				RETURN false, gv_null 
			END IF 

		END IF 

END FUNCTION #is_dup_contact() 

##################
FUNCTION params() 
	##################
	DEFINE 
	cnt 
	SMALLINT, 
	argument 
	array[8] OF CHAR (20), 
	prg_name 
	CHAR(20) 

	LET add_and_exit = false 


	LET prg_name = get_baseprogname() 

	IF num_args() = 0 THEN 
		RETURN 
	END IF 

	############################
	FOR cnt = 1 TO num_args() 
		############################

		LET argument[cnt] = arg_val(cnt) 

		IF 
		argument[cnt] IS NOT NULL 
		THEN 
			LET argument[cnt] = upshift(argument[cnt]) 
		END IF 

		CASE 
			WHEN argument[cnt] = "ADD" 
				LET add_and_exit = true 
			WHEN argument[cnt] = "UPD" 
				#LET upd_and_exit = TRUE

			WHEN argument[cnt] = "PPC" 
				LET g_scrsize="pocketpc" 

			WHEN argument[cnt] = "DEBUG" 
				LET do_debug = true 
				ERROR "DEBUG MODE ON" 
				SLEEP 2 

				#########
			OTHERWISE 
				#########
				LET g_msg = "Argument #", cnt USING "&", " NOT recognised: ", 
				argument[cnt] clipped 

				ERROR g_msg clipped 
				SLEEP 5 
		END CASE 

		#######
	END FOR 
	#######

END FUNCTION #params() 

####################################
FUNCTION default_accept(key_name) 
	####################################
	#ESCAPE FOR ESC/CTRL+C, ENTER FOR ENTER/ESCAPE
	DEFINE 
	key_name 
	CHAR (10) 

	IF key_name = "ENTER" THEN 
		OPTIONS accept KEY f34 #now that we dissasociated phisical esc KEY 
		#FROM ACCEPT logical key,
		#we can put ON KEY (ESCAPE) in all menus
		#AND INPUT stmts TO behave LIKE ctrl+c
		#this IS a Windows standar behaviour

		LET accept_enter = true 
	ELSE 

		LET accept_enter = false 

	END IF 

	{
			ON KEY(F1, ACCEPT)
				LET p_Idx = ARR_CURR()
				EXIT DISPLAY

			ON KEY(F4, F8, INTERRUPT)


	Acceptable VALUES of key (in lowercase OR uppercase letters) FOR the ON KEY block are:

	ACCEPT HELP NEXT OR RETURN OR ENTER
	DELETE INSERT NEXTPAGE RIGHT
	DOWN INTERRUPT PREVIOUS OR TAB
	ESC OR ESCAPE LEFT PREVPAGE UP
	F1 through F64
	CONTROL-CHAR (except A, D, H, I, J, L, M, R, OR X)


	Built-in functions that access field buffers AND keystroke buffers:

	Built-In Funtion 		Description
	FIELD_TOUCHED(field) 	Returns TRUE WHEN the user has made a change TO SCREEN field.
	GET_FLDBUF(field-list) 	Returns the character VALUES of the contents of one OR more fields.
	FGL_LASTKEY( ) 			Returns an INTEGER value corresponding TO the most recent keystroke.
	INFIELD(field) 			Returns TRUE IF field IS the name of the current SCREEN field.

	}


END FUNCTION #default_accept() 


############################################################### END modul

