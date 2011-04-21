-- created by Oraschemadoc Thu Apr 21 10:03:17 2011
-- visit http://www.yarpen.cz/oraschemadoc/ for more info

  CREATE TABLE "SPACEWALK"."RHNAPPINSTALLSESSION" 
   (	"ID" NUMBER NOT NULL ENABLE, 
	"INSTANCE_ID" NUMBER NOT NULL ENABLE, 
	"CHECKSUM_ID" NUMBER, 
	"PROCESS_NAME" VARCHAR2(32), 
	"STEP_NUMBER" NUMBER, 
	"USER_ID" NUMBER NOT NULL ENABLE, 
	"SERVER_ID" NUMBER NOT NULL ENABLE, 
	"CREATED" DATE DEFAULT (sysdate) NOT NULL ENABLE, 
	"MODIFIED" DATE DEFAULT (sysdate) NOT NULL ENABLE, 
	 CONSTRAINT "RHN_APPINST_SESSIOND_ID_PK" PRIMARY KEY ("ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS"  ENABLE, 
	 CONSTRAINT "RHN_APPINST_SESSION_IID_FK" FOREIGN KEY ("INSTANCE_ID")
	  REFERENCES "SPACEWALK"."RHNAPPINSTALLINSTANCE" ("ID") ON DELETE CASCADE ENABLE, 
	 CONSTRAINT "RHN_APPINST_SESSION_CHSUM_FK" FOREIGN KEY ("CHECKSUM_ID")
	  REFERENCES "SPACEWALK"."RHNCHECKSUM" ("ID") ENABLE, 
	 CONSTRAINT "RHN_APPINST_SESSION_UID_FK" FOREIGN KEY ("USER_ID")
	  REFERENCES "SPACEWALK"."WEB_CONTACT" ("ID") ENABLE, 
	 CONSTRAINT "RHN_APPINST_SESSION_SID_FK" FOREIGN KEY ("SERVER_ID")
	  REFERENCES "SPACEWALK"."RHNSERVER" ("ID") ENABLE
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS" ENABLE ROW MOVEMENT 
 
/
