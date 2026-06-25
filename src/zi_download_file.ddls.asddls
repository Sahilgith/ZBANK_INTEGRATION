@EndUserText.label: 'Download File'
define abstract entity ZI_DOWNLOAD_FILE
{
  FileName    : abap.string;
  MimeType    : abap.string;

  @Semantics.largeObject: {
    mimeType: 'MimeType',
    fileName: 'FileName'
  }
  FileContent : abap.rawstring;
}
