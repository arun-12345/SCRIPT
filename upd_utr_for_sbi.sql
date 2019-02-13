--------------------------------------------------------
--  File created - Wednesday-February-13-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure UPD_UTR_FOR_SBI
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "UPD_UTR_FOR_SBI" AS
BEGIN
DECLARE
CURSOR C IS SELECT  UTR_REF_NO, ACCOUNT_NO, AMOUNT FROM 
NEFT_TRANSACTION_UPLOAD_SBI WHERE SLIP_TYPE='600' AND RECORD_STATUS=0;

BEGIN
  FOR X IN C LOOP
  UPDATE PAYMENT_CLAIM_DETAILS SET UTR_REF_NO=X.UTR_REF_NO
  WHERE TOTAL_AMOUNT=X.AMOUNT AND 
  TO_CHAR(TO_NUMBER(ACCOUNT_NO))=X.ACCOUNT_NO
  AND UTR_REF_NO IS NULL AND PAYMENT_MODE='N' AND IFSC_CODE LIKE '%SBIN%';
  COMMIT;
  END LOOP;

  END;
END UPD_UTR_FOR_SBI;

/
