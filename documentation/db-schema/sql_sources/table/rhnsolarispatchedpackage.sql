-- created by Oraschemadoc Thu Apr 21 10:03:35 2011
-- visit http://www.yarpen.cz/oraschemadoc/ for more info

  CREATE TABLE "SPACEWALK"."RHNSOLARISPATCHEDPACKAGE" 
   (	"SERVER_ID" NUMBER NOT NULL ENABLE, 
	"PATCH_ID" NUMBER NOT NULL ENABLE, 
	"PACKAGE_NEVRA_ID" NUMBER NOT NULL ENABLE, 
	 CONSTRAINT "RHN_SOLARIS_PATCHEDP_SID_FK" FOREIGN KEY ("SERVER_ID")
	  REFERENCES "SPACEWALK"."RHNSERVER" ("ID") ON DELETE CASCADE ENABLE, 
	 CONSTRAINT "RHN_SOLARIS_PATCHEDP_PID_FK" FOREIGN KEY ("PATCH_ID")
	  REFERENCES "SPACEWALK"."RHNPACKAGE" ("ID") ON DELETE CASCADE ENABLE, 
	 CONSTRAINT "RHN_SOLARIS_PATCHEDP_PNID_FK" FOREIGN KEY ("PACKAGE_NEVRA_ID")
	  REFERENCES "SPACEWALK"."RHNPACKAGENEVRA" ("ID") ON DELETE CASCADE ENABLE
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS" ENABLE ROW MOVEMENT 
 
/
