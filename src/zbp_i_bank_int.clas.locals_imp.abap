CLASS lcl_bank_int_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA gt_bank_int_to_save TYPE STANDARD TABLE OF zdb_bank_int.
     CLASS-DATA gt_excel_to_save TYPE STANDARD TABLE OF zdb_bank_excel.
ENDCLASS.

CLASS lcl_bank_int_buffer IMPLEMENTATION.
ENDCLASS.


CLASS lhc_zi_bank_int DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_bank_int RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zi_bank_int RESULT result.

    METHODS post FOR MODIFY
      IMPORTING keys FOR ACTION zi_bank_int~post RESULT result.
    METHODS fetchutr FOR MODIFY
      IMPORTING keys FOR ACTION zi_bank_int~fetchutr RESULT result.
    METHODS fetchbalance FOR MODIFY
      IMPORTING keys FOR ACTION zi_bank_int~fetchbalance RESULT result.
    METHODS fetchstatement FOR MODIFY
      IMPORTING keys FOR ACTION zi_bank_int~fetchstatement RESULT result.
    METHODS downloadstatement FOR MODIFY
      IMPORTING keys FOR ACTION zi_bank_int~downloadstatement RESULT result.

ENDCLASS.

CLASS lsc_zi_bank_int DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.


CLASS lsc_zi_bank_int IMPLEMENTATION.

  METHOD save_modified.

    IF lcl_bank_int_buffer=>gt_bank_int_to_save IS NOT INITIAL.
      MODIFY zdb_bank_int FROM TABLE @lcl_bank_int_buffer=>gt_bank_int_to_save.
      CLEAR lcl_bank_int_buffer=>gt_bank_int_to_save.
    ENDIF.

  IF lcl_bank_int_buffer=>gt_excel_to_save IS NOT INITIAL.
    MODIFY zdb_bank_excel FROM TABLE @lcl_bank_int_buffer=>gt_excel_to_save.
    CLEAR lcl_bank_int_buffer=>gt_excel_to_save.
  ENDIF.


  ENDMETHOD.

ENDCLASS.


CLASS lhc_zi_bank_int IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD post.

    DATA: lv_response    TYPE string,
          lv_status_code TYPE i.

    READ ENTITIES OF zi_bank_int IN LOCAL MODE
      ENTITY zi_bank_int
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    LOOP AT lt_members INTO DATA(ls_member).

      DATA(lv_amount) = |{ ls_member-creditamountinbalancetranscrcy }|.
*
*      DATA(lv_json) =
*        |\{"AGGRID":"TXBCIBTEST001",| &&
*        |"AGGRNAME":"CIBTESTING",| &&
*        |"CORPID":"TXBCORP1",| &&
*        |"USERID":"USER1",| &&
*        |"URN":"MPMURN123",| &&
*        |"UNIQUEID":  "{  ls_member-TransactionKey  }" ,| &&
*        |"DEBITACC":"010205001809",| &&
*        |"CREDITACC":"010506009999",| &&
*        |"IFSC":"CITI0000003",| &&
*        |"AMOUNT":"{ ls_member-CreditAmountInBalanceTransCrcy }",| &&
*        |"CURRENCY":"INR",| &&
*        |"TXNTYPE":"RGS",| &&
*        |"PAYEENAME":"S",| &&
*        |"REMARKS":"Test Remarks",| &&
*        |"WORKFLOW_REQD":"N",| &&
*        |"BENELEI":"<BENE LEI for payments more than 50Cr>"\}|.


      SELECT SINGLE utr_id, status
        FROM zdb_bank_int
        WHERE company_code        = @ls_member-companycode
          AND accounting_document = @ls_member-accountingdocument
          AND ledger               = @ls_member-ledger
          AND fiscal_year          = @ls_member-fiscalyear
          AND trtype                = 'PAY'
          AND status                = 'SUCCESS'
        INTO @DATA(ls_existing).

      IF sy-subrc = 0.
        APPEND VALUE #(
          %key = ls_member-%key
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Document already posted. UTR: { ls_existing-utr_id }| )
        ) TO reported-zi_bank_int.

        APPEND VALUE #( %key = ls_member-%key ) TO failed-zi_bank_int.

        APPEND VALUE #( %key = ls_member-%key %param = CORRESPONDING #( ls_member ) ) TO result.

        CONTINUE.
      ENDIF.

      DATA(lv_json) =
        |\{"AGGRID":"TXBCIBTEST001",| &&
        |"AGGRNAME":"CIBTESTING",| &&
        |"CORPID":"TXBCORP1",| &&
        |"USERID":"USER1",| &&
        |"URN":"TESTING123",| &&
        |"UNIQUEID":  "{  ls_member-transactionkey  }" ,| &&
*  |"UNIQUEID":"100020261500000015",| &&
        |"DEBITACC":"010205001809",| &&
        |"CREDITACC":"010506009999",| &&
        |"IFSC":"CITI0000003",| &&
        |"AMOUNT":"{ ls_member-creditamountinbalancetranscrcy }",| &&
*  |"AMOUNT":"353,700.00",| &&
        |"CURRENCY":"INR",| &&
        |"TXNTYPE":"RGS",| &&
        |"PAYEENAME":"S",| &&
        |"REMARKS":"Test Remarks",| &&
        |"WORKFLOW_REQD":"N",| &&
        |"BENELEI":"<BENE LEI for payments more than 50Cr>"\}|.



      DATA: lv_utr    TYPE string, lv_msg TYPE string,
            lv_stat   TYPE string, lv_errcod TYPE string,
            lv_reqid  TYPE string.
      CLEAR: lv_utr, lv_msg, lv_stat, lv_errcod.

      TRY.
          DATA(lv_user) = 'sb-23d735ea-f43e-4e3a-b412-6ab59f359f1f!b623946|it-rt-mpm-dev-sub-5c8lxci5!b410603'.
          DATA(lv_pass) = '6655195f-1a43-4cf6-81fe-9819161e021f$RluJxVpjSUfKEErOow-oHsO2Ag_7fpGppRqTCQ6n_3I='.
          DATA(lv_credentials)  = |{ lv_user }:{ lv_pass }|.
          DATA(lv_b64)          = cl_web_http_utility=>encode_base64( lv_credentials ).
          DATA(lv_auth_header)  = |Basic { lv_b64 }|.

          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
              i_destination = cl_http_destination_provider=>create_by_url(
                i_url = 'https://mpm-dev-sub-5c8lxci5.it-cpi026-rt.cfapps.eu10-002.hana.ondemand.com/http/icicbank/transaction' ) ).

          DATA(lo_request) = lo_http_client->get_http_request( ).
          lo_request->set_header_field( i_name = 'Content-Type'  i_value = 'application/json' ).
          lo_request->set_header_field( i_name = 'Authorization' i_value = lv_auth_header ).
          lo_request->set_text( lv_json ).

          DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).

          lv_status_code = lo_response->get_status( )-code.
          lv_response    = lo_response->get_text( ).

          TYPES: BEGIN OF ty_response,
                   utr       TYPE string,
                   status    TYPE string,
                   message   TYPE string,
                   errorcode TYPE string,
                   reqid     TYPE string,
                 END OF ty_response.
          DATA(ls_resp) = VALUE ty_response( ).

          /ui2/cl_json=>deserialize( EXPORTING json = lv_response CHANGING data = ls_resp ).

          lv_utr    = ls_resp-utr.
          lv_msg    = ls_resp-message.
          lv_stat   = COND #( WHEN ls_resp-status IS NOT INITIAL THEN ls_resp-status ELSE 'SUCCESS' ).
          lv_errcod = ls_resp-errorcode.
          lv_reqid  = ls_resp-reqid.
        CATCH cx_root INTO DATA(lx_error).
          lv_msg  = lx_error->get_text( ).
          lv_stat = 'ERROR'.
      ENDTRY.


      MODIFY ENTITIES OF zi_bank_int IN LOCAL MODE
        ENTITY zi_bank_int
        UPDATE FIELDS ( utr_id message )
        WITH VALUE #( ( %tky = ls_member-%tky utr_id = lv_utr message = lv_msg ) )
        FAILED   DATA(lt_failed)
        REPORTED DATA(lt_reported).


      DATA: lv_timestmp TYPE timestampl.
      GET TIME STAMP FIELD lv_timestmp.

      APPEND VALUE #(
          client               = sy-mandt
          company_code         = ls_member-companycode
          accounting_document  = ls_member-accountingdocument
          ledger               = ls_member-ledger
          fiscal_year          = ls_member-fiscalyear
          hbkid                = ls_member-housebankaccount
          aggrid               = ls_member-aggrid
          aggrname             = ls_member-aggrname
          corpid               = ls_member-corpid
          userid               = ls_member-userid
          urn                  = ls_member-urn
          debitacc             = ls_member-bank
          creditacc            = ls_member-vend_bank
          ifsc                 = ls_member-vend_ifsc
          bank_name            = ls_member-bankname
          swiftcode            = ls_member-swiftcode
          bank_acc             = ls_member-bank
          vendor_ifsc          = ls_member-vend_ifsc
          vendor_bank          = ls_member-vend_bank
          vendor               = ls_member-supplier
          utr_id               = lv_utr
          reqid                = lv_reqid
*          Utr
          message              = lv_msg
          trtype               = 'PAY'
          status               = lv_stat
          errorcode            = lv_errcod
          created_by           = sy-uname
          created_on           = sy-datum
          local_created_at     = COND #( WHEN ls_member-local_created_at IS NOT INITIAL
                                          THEN ls_member-local_created_at
                                          ELSE lv_timestmp )
      ) TO lcl_bank_int_buffer=>gt_bank_int_to_save.

      IF lt_failed IS NOT INITIAL.
        APPEND VALUE #(
          %key = ls_member-%key
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Post to bank: RAP update failed' )
        ) TO reported-zi_bank_int.
      ELSE.
        APPEND VALUE #(
          %key = ls_member-%key
          %msg = new_message_with_text(
                   severity = COND #( WHEN lv_stat = 'ERROR' THEN if_abap_behv_message=>severity-error
                                       ELSE if_abap_behv_message=>severity-success )
                   text     = |Posted: { lv_msg } UTR: { lv_utr }| )
        ) TO reported-zi_bank_int.
      ENDIF.

      APPEND VALUE #( %key = ls_member-%key %param = CORRESPONDING #( ls_member ) ) TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD fetchutr.

    DATA: lv_response    TYPE string,
          lv_status_code TYPE i.

    READ ENTITIES OF zi_bank_int IN LOCAL MODE
      ENTITY zi_bank_int
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    LOOP AT lt_members INTO DATA(ls_member).

      DATA(lv_json) =
        |\{"AGGRID":"TXBCIBTEST001",| &&
        |"CORPID":"TXBCORP1",| &&
        |"USERID":"USER1",| &&
*       |"UNIQUEID":"100020261500000012",| &&
        |"UNIQUEID":  "{  ls_member-transactionkey  }" ,| &&
        |"URN":"TESTING123"\}|.


*        {
*  "AGGRID": "TXBCIBTEST001",
*  "CORPID": "TXBCORP1",
*  "USERID": "USER1",
*  "UNIQUEID": "<Pass same as used in
*Registration API> ",
*  "URN": TESTING123"
*}

      DATA: lv_utr    TYPE string, lv_msg TYPE string,
            lv_stat   TYPE string, lv_errcod TYPE string.
      CLEAR: lv_utr, lv_msg, lv_stat, lv_errcod.

      TRY.
          DATA(lv_user) = 'sb-23d735ea-f43e-4e3a-b412-6ab59f359f1f!b623946|it-rt-mpm-dev-sub-5c8lxci5!b410603'.
          DATA(lv_pass) = '6655195f-1a43-4cf6-81fe-9819161e021f$RluJxVpjSUfKEErOow-oHsO2Ag_7fpGppRqTCQ6n_3I='.
          DATA(lv_credentials)  = |{ lv_user }:{ lv_pass }|.
          DATA(lv_b64)          = cl_web_http_utility=>encode_base64( lv_credentials ).
          DATA(lv_auth_header)  = |Basic { lv_b64 }|.

          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
              i_destination = cl_http_destination_provider=>create_by_url(
                i_url = 'https://mpm-dev-sub-5c8lxci5.it-cpi026-rt.cfapps.eu10-002.hana.ondemand.com/http/icicbank/transactionInquiry' ) ).

          DATA(lo_request) = lo_http_client->get_http_request( ).
          lo_request->set_header_field( i_name = 'Content-Type'  i_value = 'application/json' ).
          lo_request->set_header_field( i_name = 'Authorization' i_value = lv_auth_header ).
          lo_request->set_text( lv_json ).

          DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).

          lv_status_code = lo_response->get_status( )-code.
          lv_response    = lo_response->get_text( ).

          TYPES: BEGIN OF ty_response,
                   urn       TYPE string,
                   utrnumber TYPE string,
                   status    TYPE string,
                   message   TYPE string,
                   errorcode TYPE string,
                 END OF ty_response.
          DATA(ls_resp) = VALUE ty_response( ).

          /ui2/cl_json=>deserialize( EXPORTING json = lv_response CHANGING data = ls_resp ).

          lv_utr    = ls_resp-utrnumber.
          lv_msg    = ls_resp-message.
          lv_stat   = COND #( WHEN ls_resp-status IS NOT INITIAL THEN ls_resp-status ELSE 'SUCCESS' ).
          lv_errcod = ls_resp-errorcode.

        CATCH cx_root INTO DATA(lx_error).
          lv_msg  = lx_error->get_text( ).
          lv_stat = 'ERROR'.
      ENDTRY.

      "------------------------------------------------------------
      " RAP buffer update (utr_id / message via mapping)
      "------------------------------------------------------------
      MODIFY ENTITIES OF zi_bank_int IN LOCAL MODE
        ENTITY zi_bank_int
        UPDATE FIELDS ( utr_id message )
        WITH VALUE #( ( %tky = ls_member-%tky utr_id = lv_utr message = lv_msg ) )
        FAILED   DATA(lt_failed)
        REPORTED DATA(lt_reported).

      "------------------------------------------------------------
      " Stage record for DB persistence in save_modified
      "------------------------------------------------------------
      DATA: lv_timestmp TYPE timestampl.
      GET TIME STAMP FIELD lv_timestmp.

      APPEND VALUE #(
          client               = sy-mandt
          company_code         = ls_member-companycode
          accounting_document  = ls_member-accountingdocument
          ledger               = ls_member-ledger
          fiscal_year          = ls_member-fiscalyear
          hbkid                = ls_member-housebankaccount
          aggrid               = ls_member-aggrid
          aggrname             = ls_member-aggrname
          corpid               = ls_member-corpid
          userid               = ls_member-userid
          urn                  = ls_member-urn
          debitacc             = ls_member-bank
          creditacc            = ls_member-vend_bank
          ifsc                 = ls_member-vend_ifsc
          bank_name            = ls_member-bankname
          swiftcode            = ls_member-swiftcode
          bank_acc             = ls_member-bank
          vendor_ifsc          = ls_member-vend_ifsc
          vendor_bank          = ls_member-vend_bank
          vendor               = ls_member-supplier
          utr_id               = lv_utr
          message              = lv_msg
          trtype               = 'INQ'
          status               = lv_stat
          errorcode            = lv_errcod
          created_by           = sy-uname
          created_on           = sy-datum
          local_created_at     = COND #( WHEN ls_member-local_created_at IS NOT INITIAL
                                          THEN ls_member-local_created_at
                                          ELSE lv_timestmp )
      ) TO lcl_bank_int_buffer=>gt_bank_int_to_save.

      IF lt_failed IS NOT INITIAL.
        APPEND VALUE #(
          %key = ls_member-%key
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Fetch UTR: RAP update failed' )
        ) TO reported-zi_bank_int.
      ELSE.
        APPEND VALUE #(
          %key = ls_member-%key
          %msg = new_message_with_text(
                   severity = COND #( WHEN lv_stat = 'ERROR' THEN if_abap_behv_message=>severity-error
                                       ELSE if_abap_behv_message=>severity-success )
                   text     = |Fetch UTR: { lv_msg } UTR: { lv_utr }| )
        ) TO reported-zi_bank_int.
      ENDIF.

      APPEND VALUE #( %key = ls_member-%key %param = CORRESPONDING #( ls_member ) ) TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD fetchbalance.

    DATA: lv_response    TYPE string,
          lv_status_code TYPE i.

    READ ENTITIES OF zi_bank_int IN LOCAL MODE
      ENTITY zi_bank_int
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    LOOP AT lt_members INTO DATA(ls_member).

      DATA(lv_json) =
        |\{"AGGRID":"TXBCIBTEST001",| &&
        |"CORPID":"TXBCORP1",| &&
        |"URN":"TESTING123",| &&
        |"ACCOUNTNO":"010205001809",| &&
        |"USERID":"USER1"\}|.


      DATA: lv_msg      TYPE string,
            lv_stat     TYPE string,
            lv_errcod   TYPE string,
            lv_balance  TYPE string,
            lv_currency TYPE string,
            lv_acctno   TYPE string.
      CLEAR: lv_msg, lv_stat, lv_errcod, lv_balance, lv_currency, lv_acctno.

      TRY.
          DATA(lv_user) = 'sb-23d735ea-f43e-4e3a-b412-6ab59f359f1f!b623946|it-rt-mpm-dev-sub-5c8lxci5!b410603'.
          DATA(lv_pass) = '6655195f-1a43-4cf6-81fe-9819161e021f$RluJxVpjSUfKEErOow-oHsO2Ag_7fpGppRqTCQ6n_3I='.
          DATA(lv_credentials)  = |{ lv_user }:{ lv_pass }|.
          DATA(lv_b64)          = cl_web_http_utility=>encode_base64( lv_credentials ).
          DATA(lv_auth_header)  = |Basic { lv_b64 }|.

          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
              i_destination = cl_http_destination_provider=>create_by_url(
                i_url = 'https://mpm-dev-sub-5c8lxci5.it-cpi026-rt.cfapps.eu10-002.hana.ondemand.com/http/icicbank/BalanceInquiry' ) ).

          DATA(lo_request) = lo_http_client->get_http_request( ).
          lo_request->set_header_field( i_name = 'Content-Type'  i_value = 'application/json' ).
          lo_request->set_header_field( i_name = 'Authorization' i_value = lv_auth_header ).
          lo_request->set_text( lv_json ).

          DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).

          lv_status_code = lo_response->get_status( )-code.
          lv_response    = lo_response->get_text( ).

          TYPES: BEGIN OF ty_bal_response,
                   corp_id      TYPE string,
                   user_id      TYPE string,
                   aggr_id      TYPE string,
                   urn          TYPE string,
                   accountno    TYPE string,
                   date         TYPE string,
                   currency     TYPE string,
                   effectivebal TYPE string,
                   response     TYPE string,
                 END OF ty_bal_response.


          DATA(ls_resp) = VALUE ty_bal_response( ).

          /ui2/cl_json=>deserialize( EXPORTING json = lv_response CHANGING data = ls_resp ).

          lv_balance  = ls_resp-effectivebal.
          lv_currency = ls_resp-currency.
          lv_acctno   = COND #( WHEN ls_resp-accountno IS NOT INITIAL THEN ls_resp-accountno ELSE ls_member-bank ).
          lv_msg      = ls_resp-response.
          lv_stat     = COND #( WHEN ls_resp-response CS 'SU' THEN 'SUCCESS' ELSE 'ERROR' ).


        CATCH cx_root INTO DATA(lx_error).
          lv_msg  = lx_error->get_text( ).
          lv_stat = 'ERROR'.
      ENDTRY.

      "------------------------------------------------------------
      " RAP buffer update (message via mapping; no utr_id here)
      "------------------------------------------------------------
      MODIFY ENTITIES OF zi_bank_int IN LOCAL MODE
        ENTITY zi_bank_int
        UPDATE FIELDS ( message )
        WITH VALUE #( ( %tky = ls_member-%tky message = lv_msg ) )
        FAILED   DATA(lt_failed)
        REPORTED DATA(lt_reported).

      "------------------------------------------------------------
      " Stage record for DB persistence in save_modified
      "------------------------------------------------------------
      DATA: lv_timestmp TYPE timestampl.
      GET TIME STAMP FIELD lv_timestmp.

      APPEND VALUE #(
          client               = sy-mandt
          company_code         = ls_member-companycode
          accounting_document  = ls_member-accountingdocument
          ledger               = ls_member-ledger
          fiscal_year          = ls_member-fiscalyear
          hbkid                = ls_member-housebankaccount
          aggrid               = ls_member-aggrid
          aggrname             = ls_member-aggrname
          corpid               = ls_member-corpid
          userid               = ls_member-userid
          urn                  = ls_member-urn
          debitacc             = ls_member-bank
          creditacc            = ls_member-vend_bank
          ifsc                 = ls_member-vend_ifsc
          bank_name            = ls_member-bankname
          swiftcode            = ls_member-swiftcode
          bank_acc             = ls_member-bank
          vendor_ifsc          = ls_member-vend_ifsc
          vendor_bank          = ls_member-vend_bank
          vendor               = ls_member-supplier
          message              = lv_msg
          trtype               = 'BAL'
          status               = lv_stat
          errorcode            = lv_errcod
          balance_amt          = lv_balance
          currency             = lv_currency
          account_no           = lv_acctno
          created_by           = sy-uname
          created_on           = sy-datum
          local_created_at     = COND #( WHEN ls_member-local_created_at IS NOT INITIAL
                                          THEN ls_member-local_created_at
                                          ELSE lv_timestmp )
      ) TO lcl_bank_int_buffer=>gt_bank_int_to_save.




      IF lt_failed IS NOT INITIAL.
        APPEND VALUE #(
          %key = ls_member-%key
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Bank Balance: RAP update failed' )
        ) TO reported-zi_bank_int.
      ELSE.
        APPEND VALUE #(
          %key = ls_member-%key
          %msg = new_message_with_text(
                   severity = COND #( WHEN lv_stat = 'ERROR' THEN if_abap_behv_message=>severity-error
                                       ELSE if_abap_behv_message=>severity-success )
                   text     = |Balance: { lv_balance } { lv_currency }| )
        ) TO reported-zi_bank_int.
      ENDIF.

      APPEND VALUE #( %key = ls_member-%key %param = CORRESPONDING #( ls_member ) ) TO result.

    ENDLOOP.


  ENDMETHOD.

  METHOD fetchstatement.
*
*    DATA: lv_response    TYPE string,
*          lv_status_code TYPE i.
*
*    READ ENTITIES OF zi_bank_int IN LOCAL MODE
*      ENTITY zi_bank_int
*      ALL FIELDS WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_members).
*
*    LOOP AT lt_members INTO DATA(ls_member).
*
*      "------------------------------------------------------------
*      " Build JSON request payload
*      " Adjust FROMDATE / TODATE as needed (here: current month)
*      "------------------------------------------------------------
*      DATA(lv_from_date) = |{ ls_member-postingdate+6(2) }-{ ls_member-postingdate+4(2) }-{ ls_member-postingdate+0(4) }|.
*      DATA(lv_to_date)   = |{ sy-datum+6(2) }-{ sy-datum+4(2) }-{ sy-datum+0(4) }|.
*
*
**    DATA(lv_json) =
**      |\{"AGGRID":"TXBCIBTEST001",| &&
**      |"CORPID":"TXBCORP1",| &&
**      |"URN":"TESTING123",| &&
**      |"USERID":"USER1",| &&
**      |"ACCOUNTNO":"010205001809",| &&
**      |"FROMDATE":"{ lv_from_date }",| &&
**      |"TODATE":"{ lv_to_date }"\}|.
*
*      DATA(lv_json) =
*      |\{"AGGRID":"TXBCIBTEST001",| &&
*      |"CORPID":"TXBCORP1",| &&
*      |"URN":"TESTING123",| &&
*      |"ACCOUNTNO":"010205001809",| &&
*      |"FROMDATE":"01-01-2024",| &&
**      |"TODATE":"10-02-2024",| &&
*      |"TODATE":"10-01-2024",| &&
*      |"USERID":"USER1"\}|.
*
*
*      DATA: lv_msg    TYPE string,
*            lv_stat   TYPE string,
*            lv_errcod TYPE string.
*      CLEAR: lv_msg, lv_stat, lv_errcod.
*
*      TRY.
*          DATA(lv_user) = 'sb-23d735ea-f43e-4e3a-b412-6ab59f359f1f!b623946|it-rt-mpm-dev-sub-5c8lxci5!b410603'.
*          DATA(lv_pass) = '6655195f-1a43-4cf6-81fe-9819161e021f$RluJxVpjSUfKEErOow-oHsO2Ag_7fpGppRqTCQ6n_3I='.
*          DATA(lv_credentials) = |{ lv_user }:{ lv_pass }|.
*          DATA(lv_b64)         = cl_web_http_utility=>encode_base64( lv_credentials ).
*          DATA(lv_auth_header) = |Basic { lv_b64 }|.
*
*          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
*              i_destination = cl_http_destination_provider=>create_by_url(
*                i_url = 'https://mpm-dev-sub-5c8lxci5.it-cpi026-rt.cfapps.eu10-002.hana.ondemand.com/http/icicbank/AccountStatement' ) ).
*
*          DATA(lo_request) = lo_http_client->get_http_request( ).
*          lo_request->set_header_field( i_name = 'Content-Type'  i_value = 'application/json' ).
*          lo_request->set_header_field( i_name = 'Authorization' i_value = lv_auth_header ).
*          lo_request->set_text( lv_json ).
*
*          DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).
*
*
*          DATA lv_xresponse TYPE xstring.
*
*
*          lv_status_code = lo_response->get_status( )-code.
**        lv_response    = lo_response->get_text( ).
*          lv_xresponse = lo_response->get_binary( ).
*          DATA(lv_xlen) = xstrlen( lv_xresponse ).
*
*          lv_response =   cl_web_http_utility=>decode_utf8( lv_xresponse ).
*
*          DATA(lv_preview) = lv_response(50000).
*
*
*
*
*          "------------------------------------------------------------
*          " Deserialize — outer envelope
*          "------------------------------------------------------------
**          TYPES: BEGIN OF ty_stmt_line,
**                   txndate     TYPE string,
**                   valuedate   TYPE string,
**                   description TYPE string,
**                   chequeno    TYPE string,
**                   branchcode  TYPE string,
**                   debit       TYPE string,
**                   credit      TYPE string,
**                   balance     TYPE string,
**                 END OF ty_stmt_line.
**
**          TYPES: BEGIN OF ty_stmt_response,
**                   corpid    TYPE string,
**                   userid    TYPE string,
**                   aggrid    TYPE string,
**                   urn       TYPE string,
**                   accountno TYPE string,
**                   currency  TYPE string,
**                   fromdate  TYPE string,
**                   todate    TYPE string,
**                   status    TYPE string,
**                   message   TYPE string,
**                   statement TYPE STANDARD TABLE OF ty_stmt_line WITH DEFAULT KEY,
**                 END OF ty_stmt_response.
*
*          TYPES: BEGIN OF ty_record,
*                   chequeno      TYPE string,
*                   txndate       TYPE string,
*                   remarks       TYPE string,
*                   amount        TYPE string,
*                   balance       TYPE string,
*                   valuedate     TYPE string,
*                   type          TYPE string,
*                   transactionid TYPE string,
*                 END OF ty_record.
*
*          TYPES ty_t_record TYPE STANDARD TABLE OF ty_record WITH DEFAULT KEY.
*
*          TYPES: BEGIN OF ty_stmt_response,
*                   corp_id   TYPE string,
*                   user_id   TYPE string,
*                   aggr_id   TYPE string,
*                   urn       TYPE string,
*                   accountno TYPE string,
*                   record    TYPE ty_t_record,
*                 END OF ty_stmt_response.
*
*          DATA(ls_resp) = VALUE ty_stmt_response( ).
*
**          /ui2/cl_json=>deserialize( EXPORTING json = lv_response CHANGING data = ls_resp ).
*          /ui2/cl_json=>deserialize(
*            EXPORTING json = lv_response
*            CHANGING  data = ls_resp ).
*
*          DATA(lv_count) = lines( ls_resp-record ).
*
**
**          lv_msg  = ls_resp-message.
**          lv_stat = COND #( WHEN ls_resp-status CS 'SU' OR ls_resp-status = 'SUCCESS'
**                            THEN 'SUCCESS' ELSE 'ERROR' ).
*
*          "------------------------------------------------------------
*          " Persist each statement line into ZDB_BANK_STMT
*          "------------------------------------------------------------
*          DATA: lv_seq      TYPE numc4 VALUE '0001'.
*
**        DATA(lv_timestmp) = cl_abap_context_info=>get_system_date( ).
*
*          DATA: lv_timestmp TYPE timestampl.
*          GET TIME STAMP FIELD lv_timestmp.
*
*
*
*
**
**          LOOP AT ls_resp-statement INTO DATA(ls_line).
**
**            " Convert string dates YYYYMMDD -> ABAP DAT
**            DATA(lv_val_date)   = CONV dats( ls_line-valuedate ).
**            DATA(lv_from_dats)  = CONV dats( ls_resp-fromdate ).
**            DATA(lv_to_dats)    = CONV dats( ls_resp-todate ).
**
**            APPEND VALUE #(
**                client              = sy-mandt
**                company_code        = ls_member-companycode
**                accounting_document = ls_member-accountingdocument
**                ledger              = ls_member-ledger
**                fiscal_year         = ls_member-fiscalyear
**                currency            = ls_resp-currency
**                account_no          = ls_resp-accountno
**                status              = lv_stat
**                message             = lv_msg
**                created_by          = sy-uname
**                created_on          = sy-datum
**                local_created_at    = lv_timestmp
**            ) TO lcl_bank_int_buffer=>gt_bank_int_to_save.
**
**            lv_seq = lv_seq + 1.
**          ENDLOOP.
*
*DATA:
*      lv_excel_b64   TYPE string,
*      lv_excel_name  TYPE string.
*CLEAR: lv_msg, lv_stat, lv_errcod, lv_excel_b64, lv_excel_name.
*
*DATA(lv_xlsx) = zcl_xlsx_builder=>build_xlsx(
*                  it_data       = ls_resp-record
*                  iv_sheet_name = 'Account Statement' ).
*
*
*DATA lv_string TYPE string.
*
*
*
*lv_excel_b64 = cl_web_http_utility=>encode_x_base64( lv_xlsx ).
*lv_excel_name = |AccountStatement_{ ls_member-companycode }_{ sy-datum }.xlsx|.
*
*
*MODIFY ENTITIES OF zi_bank_int IN LOCAL MODE
*  ENTITY zi_bank_int
*  UPDATE FIELDS ( StmtAttachment StmtFilename StmtMimetype message )
*  WITH VALUE #( (
*      %tky            = ls_member-%tky
*      StmtAttachment  = lv_xlsx
*      StmtFilename    = lv_excel_name
*      StmtMimetype    = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
*      message         = lv_msg
*  ) )
*  FAILED   DATA(lt_failed_stmt)
*  REPORTED DATA(lt_reported_stmt).
*
*lv_msg  = |Account Statement: { lv_count } records retrieved|.
*lv_stat = 'SUCCESS'.
*
*        CATCH cx_root INTO DATA(lx_error).
*          lv_msg  = lx_error->get_text( ).
*          lv_stat = 'ERROR'.
*      ENDTRY.
*
*
*      MODIFY ENTITIES OF zi_bank_int IN LOCAL MODE
*        ENTITY zi_bank_int
*        UPDATE FIELDS ( message )
*        WITH VALUE #( ( %tky = ls_member-%tky message = lv_msg ) )
*        FAILED   DATA(lt_failed)
*        REPORTED DATA(lt_reported).
*
*      "------------------------------------------------------------
*      " User feedback message
*      "------------------------------------------------------------
*      IF lt_failed IS NOT INITIAL.
*        APPEND VALUE #(
*          %key = ls_member-%key
*          %msg = new_message_with_text(
*                   severity = if_abap_behv_message=>severity-error
*                   text     = 'Account Statement: RAP update failed' )
*        ) TO reported-zi_bank_int.
*      ELSE.
*        APPEND VALUE #(
*          %key = ls_member-%key
*          %msg = new_message_with_text(
*                   severity = COND #( WHEN lv_stat = 'ERROR'
*                                      THEN if_abap_behv_message=>severity-error
*                                      ELSE if_abap_behv_message=>severity-success )
*                   text     = |Account Statement: { lv_msg }| )
*        ) TO reported-zi_bank_int.
*      ENDIF.
*
*      APPEND VALUE #( %key = ls_member-%key %param = CORRESPONDING #( ls_member ) ) TO result.
*
*    ENDLOOP.


  DATA: lv_response    TYPE string,
        lv_status_code TYPE i.

  READ ENTITIES OF zi_bank_int IN LOCAL MODE
    ENTITY zi_bank_int
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_members).

  LOOP AT lt_members INTO DATA(ls_member).

    "------------------------------------------------------------
    " Build JSON request payload
    "------------------------------------------------------------
    DATA(lv_from_date) = |{ ls_member-postingdate+6(2) }-{ ls_member-postingdate+4(2) }-{ ls_member-postingdate+0(4) }|.
    DATA(lv_to_date)   = |{ sy-datum+6(2) }-{ sy-datum+4(2) }-{ sy-datum+0(4) }|.

    DATA(lv_json) =
      |\{"AGGRID":"TXBCIBTEST001",| &&
      |"CORPID":"TXBCORP1",| &&
      |"URN":"TESTING123",| &&
      |"ACCOUNTNO":"010205001809",| &&
      |"FROMDATE":"01-01-2024",| &&
      |"TODATE":"10-01-2024",| &&
      |"USERID":"USER1"\}|.

    DATA: lv_msg    TYPE string,
          lv_stat   TYPE string,
          lv_errcod TYPE string.
    CLEAR: lv_msg, lv_stat, lv_errcod.

    DATA: lv_timestmp TYPE timestampl.
    GET TIME STAMP FIELD lv_timestmp.

    TRY.
        DATA(lv_user) = 'sb-23d735ea-f43e-4e3a-b412-6ab59f359f1f!b623946|it-rt-mpm-dev-sub-5c8lxci5!b410603'.
        DATA(lv_pass) = '6655195f-1a43-4cf6-81fe-9819161e021f$RluJxVpjSUfKEErOow-oHsO2Ag_7fpGppRqTCQ6n_3I='.
        DATA(lv_credentials) = |{ lv_user }:{ lv_pass }|.
        DATA(lv_b64)         = cl_web_http_utility=>encode_base64( lv_credentials ).
        DATA(lv_auth_header) = |Basic { lv_b64 }|.

        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
            i_destination = cl_http_destination_provider=>create_by_url(
              i_url = 'https://mpm-dev-sub-5c8lxci5.it-cpi026-rt.cfapps.eu10-002.hana.ondemand.com/http/icicbank/AccountStatement' ) ).

        DATA(lo_request) = lo_http_client->get_http_request( ).
        lo_request->set_header_field( i_name = 'Content-Type'  i_value = 'application/json' ).
        lo_request->set_header_field( i_name = 'Authorization' i_value = lv_auth_header ).
        lo_request->set_text( lv_json ).

        DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).

        lv_status_code = lo_response->get_status( )-code.

        DATA lv_xresponse TYPE xstring.
        lv_xresponse = lo_response->get_binary( ).
        DATA(lv_response_str) = cl_web_http_utility=>decode_utf8( lv_xresponse ).

        "------------------------------------------------------------
        " Deserialize JSON response
        "------------------------------------------------------------
        TYPES: BEGIN OF ty_record,
                 chequeno      TYPE string,
                 txndate       TYPE string,
                 remarks       TYPE string,
                 amount        TYPE string,
                 balance       TYPE string,
                 valuedate     TYPE string,
                 type          TYPE string,
                 transactionid TYPE string,
               END OF ty_record.

        TYPES ty_t_record TYPE STANDARD TABLE OF ty_record WITH DEFAULT KEY.

        TYPES: BEGIN OF ty_stmt_response,
                 corp_id   TYPE string,
                 user_id   TYPE string,
                 aggr_id   TYPE string,
                 urn       TYPE string,
                 accountno TYPE string,
                 record    TYPE ty_t_record,
               END OF ty_stmt_response.

        DATA(ls_resp) = VALUE ty_stmt_response( ).

        /ui2/cl_json=>deserialize(
          EXPORTING json = lv_response_str
          CHANGING  data = ls_resp ).

        DATA(lv_count) = lines( ls_resp-record ).

        "------------------------------------------------------------
        " Build Excel using zcl_xlsx_builder
        "------------------------------------------------------------
        DATA(lv_xlsx) = zcl_xlsx_builder=>build_xlsx(
                          it_data       = ls_resp-record
                          iv_sheet_name = 'Account Statement' ).

        DATA(lv_excel_name) = |AccountStatement_{ ls_member-companycode }_{ sy-datum }.xlsx|.
        DATA(lv_mime)       = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.

        lv_msg  = |Account Statement: { lv_count } records retrieved|.
        lv_stat = 'SUCCESS'.

        "------------------------------------------------------------
        " Update RAP entity buffer (StmtAttachment / Filename / Mimetype)
        "------------------------------------------------------------
        MODIFY ENTITIES OF zi_bank_int IN LOCAL MODE
          ENTITY zi_bank_int
          UPDATE FIELDS ( StmtAttachment StmtFilename StmtMimetype message )
          WITH VALUE #( (
              %tky           = ls_member-%tky
              StmtAttachment = lv_xlsx
              StmtFilename   = lv_excel_name
              StmtMimetype   = lv_mime
              message        = lv_msg
          ) )
          FAILED   DATA(lt_failed_stmt)
          REPORTED DATA(lt_reported_stmt).

        "------------------------------------------------------------
        " Stage stmt_attachment into zdb_bank_int buffer
        " (so save_modified persists it to DB)
        "------------------------------------------------------------
        APPEND VALUE #(
            client               = sy-mandt
            company_code         = ls_member-companycode
            accounting_document  = ls_member-accountingdocument
            ledger               = ls_member-ledger
            fiscal_year          = ls_member-fiscalyear
            stmt_attachment      = lv_xlsx
            stmt_filename        = lv_excel_name
            stmt_mimetype        = lv_mime
            trtype               = 'STMT'
            status               = lv_stat
            message              = lv_msg
            created_by           = sy-uname
            created_on           = sy-datum
            local_created_at     = lv_timestmp
        ) TO lcl_bank_int_buffer=>gt_bank_int_to_save.

        "------------------------------------------------------------
        " Stage Excel into zdb_bank_excel buffer (for DownloadStatement)
        "------------------------------------------------------------
        APPEND VALUE #(
            client               = sy-mandt
            company_code         = ls_member-companycode
            accounting_document  = ls_member-accountingdocument
            ledger               = ls_member-ledger
            fiscal_year          = ls_member-fiscalyear
            filename             = lv_excel_name
            file_content         = lv_xlsx
        ) TO lcl_bank_int_buffer=>gt_excel_to_save.

      CATCH cx_root INTO DATA(lx_error).
        lv_msg  = lx_error->get_text( ).
        lv_stat = 'ERROR'.
    ENDTRY.

    "------------------------------------------------------------
    " Final message update on RAP entity
    "------------------------------------------------------------
    MODIFY ENTITIES OF zi_bank_int IN LOCAL MODE
      ENTITY zi_bank_int
      UPDATE FIELDS ( message )
      WITH VALUE #( ( %tky = ls_member-%tky message = lv_msg ) )
      FAILED   DATA(lt_failed)
      REPORTED DATA(lt_reported).

    "------------------------------------------------------------
    " User feedback
    "------------------------------------------------------------
    IF lt_failed IS NOT INITIAL.
      APPEND VALUE #(
        %key = ls_member-%key
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = 'Account Statement: RAP update failed' )
      ) TO reported-zi_bank_int.
    ELSE.
      APPEND VALUE #(
        %key = ls_member-%key
        %msg = new_message_with_text(
                 severity = COND #( WHEN lv_stat = 'ERROR'
                                    THEN if_abap_behv_message=>severity-error
                                    ELSE if_abap_behv_message=>severity-success )
                 text     = |Account Statement: { lv_msg }| )
      ) TO reported-zi_bank_int.
    ENDIF.

    APPEND VALUE #( %key = ls_member-%key %param = CORRESPONDING #( ls_member ) ) TO result.

  ENDLOOP.




  ENDMETHOD.

*METHOD downloadstatement.
**
*  READ ENTITIES OF zi_bank_int IN LOCAL MODE
*    ENTITY zi_bank_int
*    ALL FIELDS WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_members).
*
*
*              TYPES: BEGIN OF ty_record,
*                   chequeno      TYPE string,
*                   txndate       TYPE string,
*                   remarks       TYPE string,
*                   amount        TYPE string,
*                   balance       TYPE string,
*                   valuedate     TYPE string,
*                   type          TYPE string,
*                   transactionid TYPE string,
*                 END OF ty_record.
*
*          TYPES ty_t_record TYPE STANDARD TABLE OF ty_record WITH DEFAULT KEY.
*
*          TYPES: BEGIN OF ty_stmt_response,
*                   corp_id   TYPE string,
*                   user_id   TYPE string,
*                   aggr_id   TYPE string,
*                   urn       TYPE string,
*                   accountno TYPE string,
*                   record    TYPE ty_t_record,
*                 END OF ty_stmt_response.
*
*  LOOP AT lt_members INTO DATA(ls_member).
*
*    " Call API again
*    " Deserialize JSON
*
*    DATA ls_resp TYPE ty_stmt_response.
*
**    /ui2/cl_json=>deserialize(
**      EXPORTING json = lv_response
**      CHANGING  data = ls_resp ).
*
*    DATA(lv_xlsx) = zcl_xlsx_builder=>build_xlsx(
*                      it_data       = ls_resp-record
*                      iv_sheet_name = 'Statement' ).
*
*    result = VALUE #(
*      (
*        %tky = ls_member-%tky
*
*        %param-filename =
*          |AccountStatement_{ sy-datum }.xlsx|
*
*        %param-mimetype =
*          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
*
*        %param-filecontent = lv_xlsx
*      )
*    ).
*
*  ENDLOOP.
*
*ENDMETHOD.

METHOD downloadstatement.

  READ ENTITIES OF zi_bank_int IN LOCAL MODE
    ENTITY zi_bank_int
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_members).

  LOOP AT lt_members INTO DATA(ls_member).

    SELECT SINGLE filename, file_content
      FROM zdb_bank_excel
      WHERE company_code        = @ls_member-companycode
        AND accounting_document = @ls_member-accountingdocument
        AND ledger               = @ls_member-ledger
        AND fiscal_year          = @ls_member-fiscalyear
      INTO @DATA(ls_excel).

    IF sy-subrc = 0.
      APPEND VALUE #(
        %tky                = ls_member-%tky
        %param-filename     = ls_excel-filename
        %param-mimetype     = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        %param-filecontent  = ls_excel-file_content
      ) TO result.
    ELSE.
      APPEND VALUE #(
        %key = ls_member-%key
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = 'No statement found. Please fetch statement first.' )
      ) TO reported-zi_bank_int.

      APPEND VALUE #( %tky = ls_member-%tky ) TO result.
    ENDIF.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.
