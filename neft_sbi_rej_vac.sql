--------------------------------------------------------
--  File created - Tuesday-February-12-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure NEFT_SBI_REJ_VAC
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "NEFT_SBI_REJ_VAC" (
    CLAIMID     IN VARCHAR2,
    VERIEDBY    IN VARCHAR2,
    VERIFYON    IN VARCHAR2,
    SLIPTYPE    IN VARCHAR2,
    C_REMARKS   IN VARCHAR2,
    STATUS      OUT NOCOPY VARCHAR2
) AS
BEGIN
    DECLARE
        IFSCCODE         VARCHAR2(20) := '';
        UTRREFNO         VARCHAR2(40) := '';
        PCDFLAG          NUMBER(5) := 9;
        NTUFLAG          NUMBER(5) := 9;
        LOGFLAG          NUMBER(5) := 9;
        LOGRECEXIST      NUMBER(5) := 9;
        ESTCHALLANFLAG   NUMBER(5) := 9;
        EPFACCOUNTNO     VARCHAR2(2) := '';
        OFFICECODECODE   VARCHAR2(5) := '';
        REGIONCODE       VARCHAR2(5) := '';
        TOTALAMOUNT      NUMBER(15) := 0;
        UTRREFLIKE       VARCHAR2(5) := '';
        BANKID           VARCHAR2(12) := '';
        VDRREFNO         VARCHAR2(15) := '';
        MEMBERID         VARCHAR2(22) := '';
        ESTCODE          VARCHAR2(7) := '';
        ESTEXT           VARCHAR2(3) := '';
        EMPNO            NUMBER(7) := 0;
        ACCMONTHYEAR     NUMBER(6) := 0;
        TOTALEE          NUMBER(12,2) := 0;
        TOTALER          NUMBER(12,2) := 0;
        INTEE            NUMBER(12,2) := 0;
        INTER            NUMBER(12,2) := 0;
        VDTOTALAMOUNT    NUMBER(12,2) := 0;
        TIHFLAG          NUMBER(5) := 9;
        OFFICEID         VARCHAR(3) := 0;
        SERIALNO         NUMBER(12) := 0;
        ACTUALUTRREFNO   VARCHAR(50) := 0;
    BEGIN
        SELECT
            IFSC_CODE,
            UTR_REF_NO,
            EPF_ACCOUNT_NO,
            TOTAL_AMOUNT,
            SUBSTR(UTR_REF_NO,0,5),
            MEMBER_ID,
            EST_CODE,
            EST_EXT,
            EMP_NO,
            EE_SHARE,
            ER_SHARE,
            INT_EE,
            INT_ER,
            ( ( EE_SHARE - INT_EE ) + ( ER_SHARE - INT_ER ) ),
            UTR_REF_NO
        INTO
            IFSCCODE,
            UTRREFNO,
            EPFACCOUNTNO,
            TOTALAMOUNT,
            UTRREFLIKE,
            MEMBERID,
            ESTCODE,
            ESTEXT,
            EMPNO,
            TOTALEE,
            TOTALER,
            INTEE,
            INTER,
            VDTOTALAMOUNT,
            ACTUALUTRREFNO
        FROM
            PAYMENT_CLAIM_DETAILS
        WHERE
            CLAIM_ID = CLAIMID;

        SELECT
            REGION_CODE,
            ACC_OFF_ID,
            OFFICE_ID
        INTO
            REGIONCODE,
            OFFICECODECODE,
            OFFICEID
        FROM
            EPFO_OFF_MASTER
        WHERE
            SLIP_TYPE = '600'
            AND RECORD_STATUS = 0;

        IF ( SLIPTYPE = EPFO.CSLIPVERIFIER ) THEN
            INSERT INTO NEFT_REJ_PAY_DETAILS (
                CLAIM_ID,
                MEMBER_ID,
                OFFICE_CODE,
                ACCOUNT_GROUP,
                EPF_ACCOUNT_NO,
                EST_CODE,
                EST_EXT,
                EMP_NO,
                SCROLL_NO,
                SCROLL_DT,
                SUMMARY_SHEET_NO,
                SUMMARY_SHEET_DT,
                PAYMENT_ITEM_NO,
                PAYMENT_APPROVAL_DATE,
                MEMBER_NAME,
                MEMBER_STATUS,
                CLAIMANT_NAME,
                CHEQ_INITIALCHAR,
                CHEQUE_NO,
                CHEQUE_DATE,
                EE_SHARE,
                ER_SHARE,
                INT_EE,
                INT_ER,
                TOTAL_AMOUNT,
                PAYMENT_MODE,
                ACCOUNT_NO,
                PARA_CODE,
                SUB_PARA,
                DISPATCH_DATE,
                SUB_PARA_CATEGORY,
                RECORD_STATUS,
                MIGR_FLAG,
                MIGR_DATE,
                CLAIM_DATE,
                RMO_STATUS,
                RMO_DATE,
                RMO_CODE,
                RMO_VDR_NO,
                FORM_TYPE,
                INTEREST_ID,
                PROCESSED_DATE,
                RMO_CREATED_BY,
                IFSC_CODE,
                NEFT_TEXT_CREATED_DT,
                UTR_REF_NO,
                SLIP_TYPE,
                CREATED_BY,
                CREATED_ON,
                CREATED_DATE,
                CREATED_REMARKS,
                PENDING_REMARKS,
                VERIFIED_BY,
                VERIFIED_ON,
                VERIFIED_DATE,
                VERIFIED_REMARKS
            )
                SELECT
                    CLAIM_ID,
                    MEMBER_ID,
                    OFFICE_CODE,
                    ACCOUNT_GROUP,
                    EPF_ACCOUNT_NO,
                    EST_CODE,
                    EST_EXT,
                    EMP_NO,
                    SCROLL_NO,
                    SCROLL_DT,
                    SUMMARY_SHEET_NO,
                    SUMMARY_SHEET_DT,
                    PAYMENT_ITEM_NO,
                    PAYMENT_APPROVAL_DATE,
                    MEMBER_NAME,
                    MEMBER_STATUS,
                    CLAIMANT_NAME,
                    CHEQ_INITIALCHAR,
                    CHEQUE_NO,
                    CHEQUE_DATE,
                    EE_SHARE,
                    ER_SHARE,
                    INT_EE,
                    INT_ER,
                    TOTAL_AMOUNT,
                    PAYMENT_MODE,
                    ACCOUNT_NO,
                    PARA_CODE,
                    SUB_PARA,
                    DISPATCH_DATE,
                    SUB_PARA_CATEGORY,
                    RECORD_STATUS,
                    MIGR_FLAG,
                    MIGR_DATE,
                    CLAIM_DATE,
                    RMO_STATUS,
                    RMO_DATE,
                    RMO_CODE,
                    RMO_VDR_NO,
                    FORM_TYPE,
                    INTEREST_ID,
                    PROCESSED_DATE,
                    RMO_CREATED_BY,
                    IFSC_CODE,
                    NEFT_TEXT_CREATED_DT,
                    UTR_REF_NO,
                    SLIPTYPE,
                    VERIEDBY,
                    VERIFYON,
                    SYSDATE,
                    C_REMARKS,
                    C_REMARKS,
                    VERIEDBY,
                    VERIFYON,
                    SYSDATE,
                    C_REMARKS
                FROM
                    PAYMENT_CLAIM_DETAILS
                WHERE
                    CLAIM_ID = CLAIMID;

            IF SQL%FOUND THEN
                LOGFLAG := 1;
            ELSE
                LOGFLAG := 9;
            END IF;

            UPDATE PAYMENT_CLAIM_DETAILS
            SET
                NEFT_REJ_VAC_FLAG = '1'
            WHERE
                CLAIM_ID = CLAIMID
                AND NEFT_REJ_VAC_FLAG = '9';

            IF SQL%FOUND THEN
                PCDFLAG := 1;
            ELSE
                PCDFLAG := 9;
            END IF;

            IF ( PCDFLAG = 1 AND LOGFLAG = 1 ) THEN
                COMMIT;
                STATUS := 1;
            ELSE
                STATUS := 0;
                ROLLBACK;
            END IF;

        ELSIF ( SLIPTYPE = EPFO.CSLIPCERTIFIER ) THEN
            UPDATE NEFT_REJ_PAY_DETAILS
            SET
                SLIP_TYPE = SLIPTYPE,
                CERTIFIED_ON = VERIFYON,
                CERTIFIED_BY = VERIEDBY,
                CERTIFIED_DATE = SYSDATE,
                CERTIFIED_REMARKS = C_REMARKS,
                PENDING_REMARKS = C_REMARKS
            WHERE
                CLAIM_ID = CLAIMID
                AND SLIP_TYPE != EPFO.CSLIPREJECT
                AND SLIP_TYPE = '300';

            IF SQL%FOUND THEN
                PCDFLAG := 1;
            ELSE
                PCDFLAG := 9;
            END IF;

            VDRREFNO := VDR_REF_NO('VD',OFFICEID);
            IF ( TO_NUMBER(EPFACCOUNTNO) = 1 ) THEN
                SELECT
                    ( NVL(MAX(SERIAL_NO),0) + 1 )
                INTO SERIALNO
                FROM
                    TRANSFER_IN_HISTORY
                WHERE
                    MEMBER_ID = MEMBERID;

                INSERT INTO TRANSFER_IN_HISTORY (
                    MEMBER_ID,
                    EST_CODE,
                    EST_EXT,
                    EMP_NO,
                    CONT_EE_3A,
                    CONT_ER_3A,
                    INT_EE,
                    INT_ER,
                    TOTAL_EE_AMOUNT,
                    TOTAL_ER_AMOUNT,
                    TOTAL_AMOUNT,
                    MEM_WDL,
                    EST_WDL,
                    RECORD_STATUS,
                    SLIP_TYPE,
                    PENDING_REMARKS,
                    MEMBER_CREDIT_FLAG,
                    SERIAL_NO,
                    ACC_MONTH_YEAR,
                    VDR_REF_NO,
                    VDR_CODE,
                    CERTIFIED_REMARKS
                ) VALUES (
                    MEMBERID,
                    ESTCODE,
                    ESTEXT,
                    EMPNO,
                    TOTALEE,
                    TOTALER,
                    INTEE,
                    INTER,
                    ( TOTALEE - INTEE ),
                    ( TOTALER - INTER ),
                    VDTOTALAMOUNT,
                    '0',
                    '0',
                    '0',
                    '100',
                    C_REMARKS,
                    'V',
                    SERIALNO,
                    LPAD(TO_CHAR(SYSDATE,'mmyyyy'),6,0),
                    VDRREFNO,
                    'VD224',
                    CLAIMID
                );

                IF SQL%FOUND THEN
                    TIHFLAG := 1;
                ELSE
                    TIHFLAG := 9;
                END IF;

            ELSE
                TIHFLAG := 1;
            END IF;

            SELECT
                BRANCH_CODE
            INTO BANKID
            FROM
                RECEIPT_BANK_MASTER
            WHERE
                BANK_TYPE = 'L'
                AND SLIP_TYPE = '600'
                AND RECORD_STATUS = 0;

            IF ( SUBSTR(IFSCCODE,0,4) != 'SBIN' ) THEN
                IF ( UTRREFLIKE != REGIONCODE || OFFICECODECODE ) THEN
                    IF ( EPFACCOUNTNO = '1' ) THEN
                        INSERT INTO EST_CHALLAN_DETAILS (
                            CREATED_BY,
                            BANK_ID,
                            PRESENTATION_DATE,
                            REALIZATION_DATE,
                            DATE_OF_CREDIT,
                            CHEQUE_NO,
                            PAY_MODE,
                            VALID_FLAG,
                            EPFO_OFFICE_CODE,
                            NOTE_SHEET_NO,
                            EST_NAME,
                            EST_ID,
                            EST_CODE,
                            EST_EXT,
                            CHALLAN_REF_NO,
                            OTHER_RATE_01,
                            OTHER_CD_01,
                            TOTAL_AMOUNT_01,
                            TOTAL_AMOUNT,
                            SLIP_TYPE,
                            RECORD_STATUS,
                            CREATED_REMARKS,
                            CREATED_DATE
                        ) VALUES (
                            VERIEDBY,
                            BANKID,
                            SYSDATE,
                            SYSDATE,
                            SYSDATE,
                            0,
                            '02',
                            'N',
                            REGIONCODE || OFFICECODECODE,
                            CLAIMID,
                            'CLAIM ID-'
                            || CLAIMID
                            || ' UTR NO-'
                            || ACTUALUTRREFNO,
                            REGIONCODE
                            || OFFICECODECODE
                            || '7777777777',
                            '7777777',
                            '777',
                            VDRREFNO,
                            TOTALAMOUNT,
                            'UR',
                            TOTALAMOUNT,
                            TOTALAMOUNT,
                            '600',
                            0,
                            'AUTO BY SERVER',
                            SYSDATE
                        );

                        IF ( SQL%FOUND ) THEN
                            ESTCHALLANFLAG := 1;
                        ELSE
                            ESTCHALLANFLAG := 0;
                        END IF;

                    ELSE
                        IF ( EPFACCOUNTNO = '10' ) THEN
                            INSERT INTO EST_CHALLAN_DETAILS (
                                CREATED_BY,
                                BANK_ID,
                                PRESENTATION_DATE,
                                REALIZATION_DATE,
                                DATE_OF_CREDIT,
                                CHEQUE_NO,
                                PAY_MODE,
                                VALID_FLAG,
                                EPFO_OFFICE_CODE,
                                NOTE_SHEET_NO,
                                EST_NAME,
                                EST_ID,
                                EST_CODE,
                                EST_EXT,
                                CHALLAN_REF_NO,
                                OTHER_RATE_10,
                                OTHER_CD_10,
                                TOTAL_AMOUNT_10,
                                TOTAL_AMOUNT,
                                SLIP_TYPE,
                                RECORD_STATUS,
                                CREATED_REMARKS,
                                CREATED_DATE
                            ) VALUES (
                                VERIEDBY,
                                BANKID,
                                SYSDATE,
                                SYSDATE,
                                SYSDATE,
                                0,
                                '02',
                                'N',
                                REGIONCODE || OFFICECODECODE,
                                CLAIMID,
                                'CLAIM ID-'
                                || CLAIMID
                                || ' UTR NO-'
                                || ACTUALUTRREFNO,
                                REGIONCODE
                                || OFFICECODECODE
                                || '7777777777',
                                '7777777',
                                '777',
                                VDRREFNO,
                                TOTALAMOUNT,
                                'UR',
                                TOTALAMOUNT,
                                TOTALAMOUNT,
                                '600',
                                0,
                                'AUTO BY SERVER',
                                SYSDATE
                            );

                            IF ( SQL%FOUND ) THEN
                                ESTCHALLANFLAG := 1;
                            ELSE
                                ESTCHALLANFLAG := 0;
                            END IF;

                        END IF;
                    END IF;

                ELSE
                    ESTCHALLANFLAG := 1;
                END IF;
            ELSIF ( SUBSTR(IFSCCODE,1,6) = 'SBIN00' ) THEN
                IF ( EPFACCOUNTNO = '1' ) THEN
                    INSERT INTO EST_CHALLAN_DETAILS (
                        CREATED_BY,
                        BANK_ID,
                        PRESENTATION_DATE,
                        REALIZATION_DATE,
                        DATE_OF_CREDIT,
                        CHEQUE_NO,
                        PAY_MODE,
                        VALID_FLAG,
                        EPFO_OFFICE_CODE,
                        NOTE_SHEET_NO,
                        EST_NAME,
                        EST_ID,
                        EST_CODE,
                        EST_EXT,
                        CHALLAN_REF_NO,
                        OTHER_RATE_01,
                        OTHER_CD_01,
                        TOTAL_AMOUNT_01,
                        TOTAL_AMOUNT,
                        SLIP_TYPE,
                        RECORD_STATUS,
                        CREATED_REMARKS,
                        CREATED_DATE
                    ) VALUES (
                        VERIEDBY,
                        BANKID,
                        SYSDATE,
                        SYSDATE,
                        SYSDATE,
                        0,
                        '02',
                        'N',
                        REGIONCODE || OFFICECODECODE,
                        CLAIMID,
                        'CLAIM ID-'
                        || CLAIMID
                        || ' UTR NO-'
                        || ACTUALUTRREFNO,
                        REGIONCODE
                        || OFFICECODECODE
                        || '7777777777',
                        '7777777',
                        '777',
                        VDRREFNO,
                        TOTALAMOUNT,
                        'UR',
                        TOTALAMOUNT,
                        TOTALAMOUNT,
                        '600',
                        0,
                        'AUTO BY SERVER',
                        SYSDATE
                    );

                    IF ( SQL%FOUND ) THEN
                        ESTCHALLANFLAG := 1;
                    ELSE
                        ESTCHALLANFLAG := 0;
                    END IF;

                ELSE
                    IF ( EPFACCOUNTNO = '10' ) THEN
                        INSERT INTO EST_CHALLAN_DETAILS (
                            CREATED_BY,
                            BANK_ID,
                            PRESENTATION_DATE,
                            REALIZATION_DATE,
                            DATE_OF_CREDIT,
                            CHEQUE_NO,
                            PAY_MODE,
                            VALID_FLAG,
                            EPFO_OFFICE_CODE,
                            NOTE_SHEET_NO,
                            EST_NAME,
                            EST_ID,
                            EST_CODE,
                            EST_EXT,
                            CHALLAN_REF_NO,
                            OTHER_RATE_10,
                            OTHER_CD_10,
                            TOTAL_AMOUNT_10,
                            TOTAL_AMOUNT,
                            SLIP_TYPE,
                            RECORD_STATUS,
                            CREATED_REMARKS,
                            CREATED_DATE
                        ) VALUES (
                            VERIEDBY,
                            BANKID,
                            SYSDATE,
                            SYSDATE,
                            SYSDATE,
                            0,
                            '02',
                            'N',
                            REGIONCODE || OFFICECODECODE,
                            CLAIMID,
                            'CLAIM ID-'
                            || CLAIMID
                            || ' UTR NO-'
                            || ACTUALUTRREFNO,
                            REGIONCODE
                            || OFFICECODECODE
                            || '7777777777',
                            '7777777',
                            '777',
                            VDRREFNO,
                            TOTALAMOUNT,
                            'UR',
                            TOTALAMOUNT,
                            TOTALAMOUNT,
                            '600',
                            0,
                            'AUTO BY SERVER',
                            SYSDATE
                        );

                        IF ( SQL%FOUND ) THEN
                            ESTCHALLANFLAG := 1;
                        ELSE
                            ESTCHALLANFLAG := 0;
                        END IF;

                    END IF;
                END IF;
            END IF;

            IF ( PCDFLAG = 1 AND ESTCHALLANFLAG = 1 AND TIHFLAG = 1 ) THEN
                COMMIT;
                STATUS := 1;
            ELSE
                STATUS := 0;
                ROLLBACK;
            END IF;

        ELSIF ( SLIPTYPE = EPFO.CSLIPREJECT ) THEN
            SELECT
                COUNT(1)
            INTO LOGRECEXIST
            FROM
                NEFT_REJ_PAY_DETAILS
            WHERE
                CLAIM_ID = CLAIMID;

            IF ( LOGRECEXIST > 0 ) THEN
                UPDATE NEFT_REJ_PAY_DETAILS
                SET
                    SLIP_TYPE = SLIPTYPE,
                    CERTIFIED_ON = VERIFYON,
                    CERTIFIED_BY = VERIEDBY,
                    CERTIFIED_DATE = SYSDATE,
                    CERTIFIED_REMARKS = C_REMARKS,
                    PENDING_REMARKS = C_REMARKS
                WHERE
                    CLAIM_ID = CLAIMID;

                IF SQL%FOUND THEN
                    LOGFLAG := 1;
                ELSE
                    LOGFLAG := 9;
                END IF;

            ELSE
                LOGFLAG := 1;
            END IF;

            IF ( SUBSTR(IFSCCODE,0,4) = 'SBIN' ) THEN
                UPDATE NEFT_TRANSACTION_UPLOAD_SBI
                SET
                    RMO_FLAG = NULL,
                    RMO_VDR_NO = NULL,
                    RECON_ID = NULL
                WHERE
                    UTR_REF_NO = UTRREFNO;

                IF SQL%FOUND THEN
                    NTUFLAG := 1;
                ELSE
                    NTUFLAG := 9;
                END IF;

            ELSIF ( SUBSTR(IFSCCODE,0,4) != 'SBIN' ) THEN
                UPDATE NEFT_TRANSACTION_UPLOAD
                SET
                    RMO_FLAG = NULL,
                    RMO_VDR_NO = NULL
                WHERE
                    UTR_REF_NO = UTRREFNO;

                IF SQL%FOUND THEN
                    NTUFLAG := 1;
                ELSE
                    NTUFLAG := 9;
                END IF;

            END IF;

            UPDATE PAYMENT_CLAIM_DETAILS
            SET
                RMO_STATUS = NULL,
                RMO_DATE = NULL,
                RMO_CODE = NULL,
                RMO_VDR_NO = NULL,
                NEFT_REJ_VAC_FLAG = NULL
            WHERE
                CLAIM_ID = CLAIMID;

            IF SQL%FOUND THEN
                PCDFLAG := 1;
            ELSE
                PCDFLAG := 9;
            END IF;

            IF ( PCDFLAG = 1 AND NTUFLAG = 1 AND LOGFLAG = 1 ) THEN
                COMMIT;
                STATUS := 1;
            ELSE
                STATUS := 0;
                ROLLBACK;
            END IF;

        END IF;

    END;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        STATUS := 0;
        DBMS_OUTPUT.PUT_LINE('No Record Found ');
    WHEN OTHERS THEN
        BEGIN
            STATUS := 0;
            DBMS_OUTPUT.PUT_LINE('Exception in ' || SQLERRM);
            ROLLBACK;
        END;
END NEFT_SBI_REJ_VAC;

/
