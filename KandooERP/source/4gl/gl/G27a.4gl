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

	Source code beautified by beautify.pl on 2020-01-03 14:28:31	$Id: $
}




# G27a - Loads an ASCII file with "|" delimiters.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "G27_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"

############################################################
# FUNCTION batch_load()
#
#
############################################################
FUNCTION batch_load() 
	WHENEVER ERROR CONTINUE 
	--      DROP TABLE t_batchdetl #changed to normal table
	SELECT count(*) FROM glparms #line TO overcome informix bug 
	WHENEVER ERROR stop 
	--   CALL create_table("batchdetl","t_batchdetl","","Y") #changed to normal table
	IF glob_load_file IS NOT NULL THEN
		IF os.path.exists(glob_load_file) THEN 
			# Check if path exists ericv 2020-03-16 KD-1280
			LOAD FROM glob_load_file INSERT INTO t_batchdetl #watch out , glob_rec_kandoouser.sign_on_code 
			UPDATE t_batchdetl SET cmpy_code = glob_rec_kandoouser.cmpy_code WHERE cmpy_code IS NULL 
			RETURN "t_batchdetl",0
		ELSE
			RETURN "t_batchdetl",-1
		END IF
	ELSE
		RETURN "t_batchdetl",-2
	END IF
		 
END FUNCTION 


############################################################
# FUNCTION del_record(x,y) 
#
# ????? what the f...
############################################################
FUNCTION del_record(x,y) 
	DEFINE x,y CHAR(1) 


END FUNCTION 