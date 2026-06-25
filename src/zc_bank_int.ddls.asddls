@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Billing Document'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZC_BANK_INT
  provider contract transactional_query
  as projection on ZI_BANK_INT
{
  key CompanyCode,
  key AccountingDocument,
  key Ledger,
  key FiscalYear,
      DocumentReferenceID,
      TransactionKey,        
      Urn,
      Aggrid,
      Aggrname,
      Corpid,
      Userid,
      status,
      BankInternalID,
      BankName,
      SWIFTCode,
      Bank,
      vend_ifsc,
      vend_bank,
      Supplier,
      SupplierName,
      FiscalPeriod,
      PostingDate,
      CreationDate,
      AccountingDocumentType,
      AccountingDocCreatedByUser,
      AssignmentReference,
      BalanceTransactionCurrency,
      @Semantics.amount.currencyCode: 'BalanceTransactionCurrency'
      CreditAmountInBalanceTransCrcy,
      @Semantics.amount.currencyCode: 'BalanceTransactionCurrency'
      DebitAmountInBalanceTransCrcy,
      AccountingDocumentHeaderText,
      AccountingDocumentTypeName,
      GLAccount,
      GLAccountName,
      HouseBankAccount,
      IsReversed,
      DocumentDate,
      OffsettingAccountType,
      OperatingConcern,
      ReversalReferenceDocument,
      SpecialGLCode,
      utr_id,
      balance_amt,
      currency,
      account_no,
      created_by,
      created_on,
      local_created_at,
      StmtAttachment,
StmtMimetype,
StmtFilename
}
