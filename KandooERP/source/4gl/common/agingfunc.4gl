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
#     agingfunc.4gl - Used TO calculate the aging of transactions
#
#       set_aging() - Set up modular GLOBALS FOR aging calculations
#  get_age_bucket() - returns the age bucket 1,30,60,90 that a transaction
#                     falls INTO.
# get_aging_dates() - returns the dates that signify the start of each
#                     aging bucket.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS #hmmm must stay globals (not module scope)
	DEFINE glob_aging_date DATE 
	DEFINE glob_future_date DATE 
	DEFINE glob_over1_date DATE 
	DEFINE glob_over30_date DATE 
	DEFINE glob_over60_date DATE 
	DEFINE glob_over90_date DATE 
	DEFINE glob_monthly_aging_kandoooption CHAR 
	DEFINE glob_credit_aging_kandoooption CHAR
END GLOBALS 

###########################################################################
# FUNCTION set_aging(p_cmpy_code,p_age_date)
#
#
###########################################################################
FUNCTION set_aging(p_cmpy_code,p_age_date) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_age_date DATE 
	DEFINE l_last_date DATE
	
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		
	#LET glob_rec_kandoouser.cmpy_code = p_cmpy_code  #check , if this IS correct.. I have some doubts
	LET glob_aging_date = p_age_date 
	LET glob_monthly_aging_kandoooption = get_kandoooption_feature_state("AR","AG") 
	LET glob_credit_aging_kandoooption = get_kandoooption_feature_state("AR",TRAN_TYPE_RECEIPT_CA)
	 
	CASE glob_monthly_aging_kandoooption 
		WHEN "Y" 
			LET l_last_date = mdy(month(glob_aging_date),1,year(glob_aging_date)) 
			LET glob_future_date = l_last_date + 2 units month 
			LET glob_future_date = glob_future_date - 1 
			LET glob_over1_date = l_last_date + 1 units month 
			LET glob_over1_date = glob_over1_date - 1 
			LET glob_over30_date = l_last_date - 1 
			LET glob_over60_date = l_last_date - 1 units month 
			LET glob_over60_date = glob_over60_date - 1 
			LET glob_over90_date = l_last_date - 2 units month 
			LET glob_over90_date = glob_over90_date - 1 
		OTHERWISE 
			LET glob_future_date = glob_aging_date + 30 
			LET glob_over1_date = glob_aging_date 
			LET glob_over30_date = glob_aging_date - 30 
			LET glob_over60_date = glob_aging_date - 60 
			LET glob_over90_date = glob_aging_date - 90 
	END CASE
	 
END FUNCTION 
###########################################################################
# FUNCTION set_aging(p_cmpy_code,p_age_date)
###########################################################################


###########################################################################
# FUNCTION get_aging_dates() 
#
#
###########################################################################
FUNCTION get_age_bucket(p_trantype_ind, p_due_date) 
	DEFINE p_trantype_ind CHAR(2) 
	DEFINE p_due_date DATE 

	IF (p_trantype_ind = TRAN_TYPE_CREDIT_CR) AND (glob_credit_aging_kandoooption = "Y") THEN 
		RETURN 0 
	END IF 
	
	CASE 
		WHEN p_due_date <= glob_over90_date 
			RETURN 91 
		WHEN p_due_date <= glob_over60_date 
			RETURN 61 
		WHEN p_due_date <= glob_over30_date 
			RETURN 31 
		WHEN p_due_date <= glob_over1_date 
			RETURN 1 
		WHEN p_due_date <= glob_future_date 
			RETURN 0 
		OTHERWISE 
			RETURN -31 
	END CASE 
END FUNCTION 
###########################################################################
# END FUNCTION get_aging_dates() 
###########################################################################


###########################################################################
# FUNCTION get_aging_dates() 
#
#
###########################################################################
FUNCTION get_aging_dates() 

	RETURN glob_future_date, 
	glob_over1_date, 
	glob_over30_date, 
	glob_over60_date, 
	glob_over90_date 
END FUNCTION
###########################################################################
# END FUNCTION get_aging_dates() 
###########################################################################