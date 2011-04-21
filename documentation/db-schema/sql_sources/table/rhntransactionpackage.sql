-- created by Oraschemadoc Thu Apr 21 10:03:36 2011
-- visit http://www.yarpen.cz/oraschemadoc/ for more info

  CREATE TABLE "SPACEWALK"."RHNTRANSACTIONPACKAGE" 
   (	"ID" NUMBER NOT NULL ENABLE, 
	"OPERATION" NUMBER NOT NULL ENABLE, 
	"NAME_ID" NUMBER NOT NULL ENABLE, 
	"EVR_ID" NUMBER NOT NULL ENABLE, 
	"PACKAGE_ARCH_ID" NUMBER, 
	 CONSTRAINT "RHN_TRANSPACK_ID_PK" PRIMARY KEY ("ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS"  ENABLE, 
	 CONSTRAINT "RHN_TRANSPACK_OP_FK" FOREIGN KEY ("OPERATION")
	  REFERENCES "SPACEWALK"."RHNTRANSACTIONOPERATION" ("ID") ENABLE, 
	 CONSTRAINT "RHN_TRANSPACK_NID_FK" FOREIGN KEY ("NAME_ID")
	  REFERENCES "SPACEWALK"."RHNPACKAGENAME" ("ID") ENABLE, 
	 CONSTRAINT "RHN_TRANSPACK_EID_FK" FOREIGN KEY ("EVR_ID")
	  REFERENCES "SPACEWALK"."RHNPACKAGEEVR" ("ID") ENABLE, 
	 CONSTRAINT "RHN_TRANSPACK_PAID_FK" FOREIGN KEY ("PACKAGE_ARCH_ID")
	  REFERENCES "SPACEWALK"."RHNPACKAGEARCH" ("ID") ENABLE
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS" ENABLE ROW MOVEMENT 
 
/
