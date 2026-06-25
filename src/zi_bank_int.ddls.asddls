@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Bank Payment Journal - Selected Fields'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #XXL,
    dataClass: #TRANSACTIONAL
}

define root view entity ZI_BANK_INT
  as select from    I_AccountingDocumentJournal( P_Language: 'E' ) as Journal
  
  left outer join I_Housebank as hb on hb.HouseBank = Journal.HouseBank
  
  left outer join I_Bank_2 as bnk on bnk.BankInternalID = hb.BankInternalID
  
  left outer join ZI_2123_user_dev as vend on vend.Vendor = Journal.Supplier
  
  left outer join ZI_SUPPLIER_LINE as supp on supp.AccountingDocument = Journal.AccountingDocument
                                            and supp.CompanyCode = Journal.CompanyCode
                                            and supp.FiscalYear = Journal.FiscalYear
                                            
  left outer join I_Supplier as supname on supname.Supplier = supp.Supplier

    left outer join ZI_BANK_DET                                    as bankd on Journal.HouseBankAccount = bankd.Hbkid
  association [0..1] to zdb_bank_int as _BankInt on  $projection.CompanyCode        = _BankInt.company_code
                                                 and $projection.AccountingDocument = _BankInt.accounting_document
                                                 and $projection.Ledger             = _BankInt.ledger
                                                 and $projection.FiscalYear         = _BankInt.fiscal_year
{
      //-- KEY FIELDS --------------------------------------------------

  key Journal.CompanyCode,
      @EndUserText.label: 'Journal Entry'
  key Journal.AccountingDocument,
  key Journal.Ledger,
  key Journal.FiscalYear,

      //-- DOCUMENT IDENTIFICATION -------------------------------------

      @EndUserText.label: 'Transaction Key'
concat(
  concat( Journal.CompanyCode, Journal.FiscalYear ),
  Journal.AccountingDocument
) as TransactionKey,

      bankd.Urn,
      bankd.Aggrid,
      bankd.Aggrname,
      bankd.Corpid,
      bankd.Userid,
      _BankInt.status,
        //"""""""""""""" Bank Details
     
      @EndUserText.label: 'IFSC Code'
      bnk.BankInternalID,
      
      
       @EndUserText.label: 'Bank Name'
      bnk.BankName,
      
         @EndUserText.label: 'SWIFTCODE'
      bnk.SWIFTCode,
      
      @EndUserText.label: 'Bank Account Number'
      bnk.Bank,
           
      //""""""""'" Vend details
      
      @EndUserText.label: 'Vendor IFSC Code'
      vend.ObjectName as vend_ifsc,
      
        @EndUserText.label: 'Vendor Bank Accoount'
      vend.ObjectType as vend_bank,
      
       @EndUserText.label: 'Vendor'
      supp.Supplier,
      
       @EndUserText.label: 'Vendor Name'
      supname.SupplierName,
      
      @EndUserText.label: 'Document Reference ID'
      Journal.DocumentReferenceID,

      @EndUserText.label: 'Fiscal Period'
      Journal.FiscalPeriod,

      @EndUserText.label: 'Posting Date'
      Journal.PostingDate,

      @EndUserText.label: 'Creation Date'
      Journal.CreationDate,

      @EndUserText.label: 'Journal Entry Type'
      Journal.AccountingDocumentType,

      @EndUserText.label: 'Created By User'
      Journal.AccountingDocCreatedByUser,

      //-- AMOUNTS & CURRENCY -----------------------------------------

      @EndUserText.label: 'Assignment Reference'
      Journal.AssignmentReference,

      @EndUserText.label: 'Balance Transaction Currency'
      Journal.BalanceTransactionCurrency,

      @Semantics.amount.currencyCode: 'BalanceTransactionCurrency'
      @EndUserText.label: 'Credit Amt in Bal Trans Crcy'
//      Journal.CreditAmountInBalanceTransCrcy,
abs( Journal.CreditAmountInBalanceTransCrcy ) as CreditAmountInBalanceTransCrcy,

      @Semantics.amount.currencyCode: 'BalanceTransactionCurrency'
      @EndUserText.label: 'Debit Amt in Bal Trans Crcy'
      Journal.DebitAmountInBalanceTransCrcy,

      //-- DOCUMENT HEADER --------------------------------------------

      @EndUserText.label: 'Document Header Text'
      Journal.AccountingDocumentHeaderText,

      @EndUserText.label: 'Document Type Name'
      Journal.AccountingDocumentTypeName,

      //-- G/L ACCOUNT -----------------------------------------------

      @EndUserText.label: 'G/L Account'
      Journal.GLAccount,

      @EndUserText.label: 'G/L Account Name'
      Journal.GLAccountName,

      //-- BANK ------------------------------------------------------

      @EndUserText.label: 'House Bank Account'
      Journal.HouseBankAccount,

      //-- REVERSAL / STATUS -----------------------------------------

      @EndUserText.label: 'Indicator: Item is Reversed'
      Journal.IsReversed,

      @EndUserText.label: 'Journal Entry Date'
      Journal.DocumentDate,
      //
      //      //-- ACCOUNT TYPES ---------------------------------------------
      //
      @EndUserText.label: 'Offsetting Account Type'
      Journal.OffsettingAccountType,

      //-- CONTROLLING -----------------------------------------------

      @EndUserText.label: 'Operating Concern'
      Journal.OperatingConcern,

      //-- REVERSAL --------------------------------------------------

      @EndUserText.label: 'Reversal Reference Document'
      Journal.ReversalReferenceDocument,

      //-- SPECIAL G/L -----------------------------------------------

      @EndUserText.label: 'Special G/L Indicator'
      Journal.SpecialGLCode,

      @EndUserText.label: 'UTR ID'
      _BankInt.utr_id,
      @EndUserText.label: 'Message'
      _BankInt.message,
      @EndUserText.label: 'Created By'
      _BankInt.created_by,
      @EndUserText.label: 'Created On'
      _BankInt.created_on,
      @EndUserText.label: 'Created At'
      _BankInt.local_created_at,
      @EndUserText.label: 'Balance Amount'
_BankInt.balance_amt,
@EndUserText.label: 'Currency'
_BankInt.currency,
@EndUserText.label: 'Account Number'
_BankInt.account_no,
@Semantics.largeObject: {
    mimeType: 'StmtMimetype',
    fileName: 'StmtFilename',
    contentDispositionPreference: #ATTACHMENT
}
_BankInt.stmt_attachment as StmtAttachment,

@EndUserText.label: 'Statement Mimetype'
_BankInt.stmt_mimetype as StmtMimetype,

@EndUserText.label: 'Statement Filename'
_BankInt.stmt_filename as StmtFilename,

      _BankInt

}
where
      Journal.Ledger                         =  '0L'
  and Journal.AccountingDocumentType         =  'KZ'
  and Journal.HouseBank                      <> ''
  //  and Journal.OperatingConcern               =  'K'
  and Journal.ReversalReferenceDocumentCntxt =  ''
