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
#This file IS proccessed by Aubotconf 'configure' script, TO create .4gl file

#database should be defined ONLY in glob_DATABASE.4gl
#but we have TO include it here TO, since this varibles use DEFINE ... LIKE
#so WHEN this file IS compiled, compiler would NOT have a database name OTHERWISE

#but I4gl does NOT LIKE chaining of GLOBALS files, so we must DECLARE
#DATABASE explicitly here
#GLOBALS "../common/glob_DATABASE.4gl"

#Actual name of the database will be SET FROM 'configure'

######################################################################
# huho Common goal - let's keep the global scope variable countable/short/limited/in range


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
