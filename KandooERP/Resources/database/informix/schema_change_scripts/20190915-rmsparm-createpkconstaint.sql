--# description: this script emulates safely the constraint for 1 to 1 relationship
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: rmsparm
--# author: eric vercelletto
--# date: 2019-09-14
--# Ticket # :
--# more comments: in this script,we emulate 1 on 1 relationship by creating on the foreign site a duplicate index + create a trigger calling a procedure that will check if the 'primary' key exists with a select stmt
-- create a unique index o ensure unicity of cmpy_code
CREATE INDEX u_rmsparm on rmsparm(cmpy_code);

CREATE PROCEDURE p_ck_1TO1Relation_rmsparms_company() REFERENCING OLD AS o NEW AS n FOR rmsparm;
	--- this procedure simulates the behaviour of a foreign key by ALWAYS checking whether the 'parent' key exists or not
	DEFINE rows_count INTEGER;
	--#SET DEBUG FILE TO "/tmp/p_ck_1TO1Relation_rmsparms_company.out";
	--#trace on;

	IF (INSERTING) THEN  -- check if cmpy_code exists in company: if not, we raise an exception
		LET rows_count = ( SELECT count(*) FROM company WHERE company.cmpy_code = n.cmpy_code ) ;
		IF rows_count <> 1 THEN
			RAISE EXCEPTION -691,0,"Missing key in 1 to 1 relationship on cmpy_code";
		END IF
	END IF

	IF (DELETING) THEN   -- check if cmpy_code DOES NOT EXIST in company: if not, we raise an exception
		LET rows_count = ( SELECT count(*) FROM company WHERE company.cmpy_code = n.cmpy_code ) ;
		IF rows_count > 0 THEN
			RAISE EXCEPTION -692,0,"Key value for 1 to 1 relationship name is still being referenced";
		END IF
	END IF
END PROCEDURE;
DROP TRIGGER IF EXISTS trg_ins_rmsparm;
CREATE TRIGGER trg_ins_rmsparm INSERT ON rmsparm REFERENCING NEW AS post
FOR EACH ROW(EXECUTE PROCEDURE p_ck_1TO1Relation_rmsparms_company() WITH TRIGGER REFERENCES);
