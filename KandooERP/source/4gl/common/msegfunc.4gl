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

	Source code beautified by beautify.pl on 2020-01-02 10:35:19	$Id: $
}

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION mult_segs(p_cmpy,p_class_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_class_code LIKE class.class_code 
	DEFINE l_segment_cnt SMALLINT 

	SELECT count(*) INTO l_segment_cnt FROM prodstructure 
	WHERE class_code = p_class_code 
	AND cmpy_code = p_cmpy 
	IF l_segment_cnt < 2 THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


