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
# \brief module E11 - Maintainence program FOR Sales Orders
#                This program allows the addition AND editting of
#                sales orders entered FOR advanced ORDER entry.
#
#          E11.4gl
#              - main line structure
#              - process_order() FUNCTION that controls everything
#              - INITIALIZE_ord() FUNCTION which IS called between each
#                   ORDER add/edit TO reset GLOBALS & CLEAR temp tables.
#
#          E11a.4gl
#              - header_entry()  retrieves first SCREEN INPUT FOR add/edit.
#              - INITIALIZE_ord() resets all GLOBALS AND temp tables
#
#          E11b.4gl
#              - pay_detail() retrieves second SCREEN INPUT orders.
#                             Enter terms/tax/conditions etc...
#              - view_cust()  Allows user TO view customer account
#                             details. ie: balance, credit available
#              - commission() Allows user TO distribute sales commission
#                             TO salespersons (iff customer.share_flag = Y)
#              - stock_line() Updates ORDER warehouse reserving AND backordering
#                             stock as required.
#                                 Called FROM lineitems FOR detailed entry
#          E11c.4gl
#              - offer_scan() Allows user TO nominate offers AND quantities of
#
#          E11d.4gl
#              - lineitem_scan()  displays a scan of ORDER line item AND allows
#                                 add/edit/delete of such.
#
#          E11e.4gl
#              - lineitem_entry() Detailed line entry (window FOR 1 line).
#                                 Called FROM lineitems FOR detailed entry
#
#          E11f.4gl
#              - checkoffer() displays a scan of special offers used
#                             AND performs checking calculations on each.
#
#          E11g.4gl
#              - summary()    Allows user TO enter freight handling AND
#                             shipping instruction FOR this ORDER
#
#          E11h.4gl
#              - insert_order() Inserts a blank new ORDER INTO the database
#              - write_order()  Updates database with new data

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E11_GLOBALS.4gl"
###########################################################################
# MAIN
#
# E11 - Maintainence program FOR Sales Orders
#       This program allows the addition AND editting of
#       sales orders entered FOR advanced ORDER entry.
###########################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E11") 
	CALL ui_init(0) #Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_e_eo() #init e/eo module/program

	CALL E11_main() 
END MAIN