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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A11_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
###########################################################################
# FUNCTION A11_main()
#
#  This program allows the user TO enter new customers
#  INTO the main database
###########################################################################
FUNCTION A11_main() 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("A11") 


	### DEFINE temp table TO 'LIKE' database table. #NOT sure why we do this, this way
	CALL create_table("customernote","t_customernote","","Y") 
	CALL create_table("customership","t_customership","","N") 
	CALL create_table("stnd_custgrp","t1_stnd_custgrp","","N") 

	# This FUNCTION sets up the GLOBALS variables FOR all that IS needed.
	CALL INITIALIZE_globals(MODE_CLASSIC_ADD,"") 

	OPEN WINDOW A205 with FORM "A205" 
	CALL windecoration_a("A205") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE customer_edit_1(MODE_CLASSIC_ADD) 

		IF customer_edit_2() THEN # mandatory WINDOW 

			IF glob_show_rep_ind THEN 
				IF NOT customer_edit_6() THEN # mandatory WINDOW 
					CONTINUE WHILE 
				END IF 
			END IF 

			IF process_customer(MODE_CLASSIC_ADD) THEN 
				CALL INITIALIZE_globals(MODE_CLASSIC_ADD,"") #a global customer record get's initialized with default data prior to INPUT
			END IF 

		END IF 
	END WHILE 

	CLOSE WINDOW A205 
END FUNCTION 
###########################################################################
# END FUNCTION A11_main()
###########################################################################