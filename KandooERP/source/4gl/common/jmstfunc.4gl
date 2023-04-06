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

	Source code beautified by beautify.pl on 2020-01-02 10:35:16	$Id: $
}



GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION set_start(p_job_code,p_date) 
	DEFINE p_job_code LIKE job.job_code 
	DEFINE p_date DATE 
	DEFINE l_rec_job RECORD LIKE job.*

	IF p_date IS NULL THEN 
		RETURN 
	END IF 

	IF l_rec_job.job_code IS NULL OR 
	l_rec_job.job_code != p_job_code THEN 

		SELECT * 
		INTO l_rec_job.* 
		FROM job 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = p_job_code 

		IF status != 0 THEN 
			RETURN 
		END IF 

	END IF 

	IF l_rec_job.act_start_date IS NULL OR 
	(l_rec_job.act_start_date > p_date) THEN 

		UPDATE job 
		SET act_start_date = p_date 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = p_job_code 

		LET l_rec_job.act_start_date = p_date 

	END IF 

END FUNCTION 


