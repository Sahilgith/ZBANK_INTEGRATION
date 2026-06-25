CLASS zcl_xlsx_builder DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS:
      build_xlsx
        IMPORTING
          it_data        TYPE STANDARD TABLE
          iv_sheet_name  TYPE string DEFAULT 'Sheet1'
        RETURNING
          VALUE(rv_xlsx) TYPE xstring
        RAISING
          cx_sy_conversion_codepage
          cx_sy_codepage_converter_init.

  PRIVATE SECTION.
    CLASS-METHODS:
      escape_xml IMPORTING iv_text TYPE string RETURNING VALUE(rv_text) TYPE string,
      col_name   IMPORTING iv_col  TYPE i      RETURNING VALUE(rv_name) TYPE string.
ENDCLASS.

CLASS zcl_xlsx_builder IMPLEMENTATION.

  METHOD build_xlsx.

    DATA: lo_zip       TYPE REF TO cl_abap_zip,
          lv_sheet_xml TYPE string,
          lv_rows_xml  TYPE string,
          lv_row_xml   TYPE string,
          lv_row_no    TYPE i VALUE 1,
          lv_col       TYPE i.

    CREATE OBJECT lo_zip.

    DATA(lo_tabledescr)  = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( it_data ) ).
    DATA(lo_structdescr) = CAST cl_abap_structdescr( lo_tabledescr->get_table_line_type( ) ).
    DATA(lt_components)  = lo_structdescr->get_components( ).

    " Header row
    lv_col = 1.
    LOOP AT lt_components INTO DATA(ls_comp).
      lv_row_xml = lv_row_xml &&
        |<c r="{ col_name( lv_col ) }{ lv_row_no }" t="inlineStr"><is><t>{ escape_xml( ls_comp-name ) }</t></is></c>|.
      lv_col = lv_col + 1.
    ENDLOOP.
    lv_rows_xml = |<row r="{ lv_row_no }">{ lv_row_xml }</row>|.
    lv_row_no   = lv_row_no + 1.

    " Data rows
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<ls_line>).
      CLEAR lv_row_xml.
      lv_col = 1.
      LOOP AT lt_components INTO ls_comp.
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE <ls_line> TO FIELD-SYMBOL(<lv_value>).
        lv_row_xml = lv_row_xml &&
          |<c r="{ col_name( lv_col ) }{ lv_row_no }" t="inlineStr"><is><t>{ escape_xml( |{ <lv_value> }| ) }</t></is></c>|.
        lv_col = lv_col + 1.
      ENDLOOP.
      lv_rows_xml = lv_rows_xml && |<row r="{ lv_row_no }">{ lv_row_xml }</row>|.
      lv_row_no = lv_row_no + 1.
    ENDLOOP.

    lv_sheet_xml =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">| &&
      |<sheetData>{ lv_rows_xml }</sheetData></worksheet>|.

    DATA(lv_content_types) =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">| &&
      |<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>| &&
      |<Default Extension="xml" ContentType="application/xml"/>| &&
      |<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>| &&
      |<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>| &&
      |</Types>|.

    DATA(lv_rels) =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">| &&
      |<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>| &&
      |</Relationships>|.

    DATA(lv_workbook) =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" | &&
      |xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">| &&
      |<sheets><sheet name="{ iv_sheet_name }" sheetId="1" r:id="rId1"/></sheets></workbook>|.

    DATA(lv_workbook_rels) =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">| &&
      |<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>| &&
      |</Relationships>|.

    " UTF-8 conversion via the released CL_ABAP_CONV_CODEPAGE (replaces CL_ABAP_CODEPAGE)
   " UTF-8 conversion via the released CL_ABAP_CONV_CODEPAGE
    DATA(lo_conv) = cl_abap_conv_codepage=>create_out( ).

    DATA(lv_x_content_types)   = lo_conv->convert( source = lv_content_types ).
    DATA(lv_x_rels)            = lo_conv->convert( source = lv_rels ).
    DATA(lv_x_workbook)        = lo_conv->convert( source = lv_workbook ).
    DATA(lv_x_workbook_rels)   = lo_conv->convert( source = lv_workbook_rels ).
    DATA(lv_x_sheet)           = lo_conv->convert( source = lv_sheet_xml ).

    lo_zip->add( name = '[Content_Types].xml'         content = lv_x_content_types ).
    lo_zip->add( name = '_rels/.rels'                  content = lv_x_rels ).
    lo_zip->add( name = 'xl/workbook.xml'              content = lv_x_workbook ).
    lo_zip->add( name = 'xl/_rels/workbook.xml.rels'   content = lv_x_workbook_rels ).
    lo_zip->add( name = 'xl/worksheets/sheet1.xml'     content = lv_x_sheet ).

    rv_xlsx = lo_zip->save( ).

  ENDMETHOD.

  METHOD escape_xml.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '&' IN rv_text WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_text WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_text WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_text WITH '&quot;'.
  ENDMETHOD.

  METHOD col_name.
    CONSTANTS lc_alphabet TYPE string VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    DATA: lv_n TYPE i, lv_r TYPE i.
    lv_n = iv_col.
    WHILE lv_n > 0.
      lv_r = ( lv_n - 1 ) MOD 26.
      rv_name = lc_alphabet+lv_r(1) && rv_name.
      lv_n = ( lv_n - 1 ) DIV 26.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
