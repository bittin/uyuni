-- created by Oraschemadoc Thu Apr 21 10:03:39 2011
-- visit http://www.yarpen.cz/oraschemadoc/ for more info

  CREATE TABLE "SPACEWALK"."RHN_COMMAND" 
   (	"RECID" NUMBER NOT NULL ENABLE, 
	"NAME" VARCHAR2(40) NOT NULL ENABLE, 
	"DESCRIPTION" VARCHAR2(80) NOT NULL ENABLE, 
	"GROUP_NAME" VARCHAR2(40), 
	"ALLOWED_IN_SUITE" CHAR(1) DEFAULT ('1') NOT NULL ENABLE, 
	"COMMAND_CLASS" VARCHAR2(255) DEFAULT ('/var/lib/nocpulse/libexec/plugin') NOT NULL ENABLE, 
	"ENABLED" CHAR(1) DEFAULT ('1') NOT NULL ENABLE, 
	"FOR_HOST_PROBE" CHAR(1) DEFAULT ('0') NOT NULL ENABLE, 
	"LAST_UPDATE_USER" VARCHAR2(40), 
	"LAST_UPDATE_DATE" DATE, 
	"SYSTEM_REQUIREMENTS" VARCHAR2(40), 
	"VERSION_SUPPORT" VARCHAR2(1024), 
	"HELP_URL" VARCHAR2(1024), 
	 CONSTRAINT "RHN_CMMND_RECID_PK" PRIMARY KEY ("RECID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS"  ENABLE, 
	 CONSTRAINT "RHN_CMMND_RECID_COMM_CL_UQ" UNIQUE ("RECID", "COMMAND_CLASS")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS"  ENABLE, 
	 CONSTRAINT "RHN_CMMND_CMDGR_GROUP_NAME_FK" FOREIGN KEY ("GROUP_NAME")
	  REFERENCES "SPACEWALK"."RHN_COMMAND_GROUPS" ("GROUP_NAME") ENABLE, 
	 CONSTRAINT "RHN_CMMND_COMCL_CLASS_NAME_FK" FOREIGN KEY ("COMMAND_CLASS")
	  REFERENCES "SPACEWALK"."RHN_COMMAND_CLASS" ("CLASS_NAME") ENABLE, 
	 CONSTRAINT "RHN_CMMND_SYS_REQS_FK" FOREIGN KEY ("SYSTEM_REQUIREMENTS")
	  REFERENCES "SPACEWALK"."RHN_COMMAND_REQUIREMENTS" ("NAME") ON DELETE CASCADE ENABLE
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS" ENABLE ROW MOVEMENT 
 
/
