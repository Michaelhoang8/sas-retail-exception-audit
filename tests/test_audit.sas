%include "src/audit.sas";
%audit(root=.);
proc sql noprint;
  select count(*),sum(revenue_cents),sum(quantity < 0)
    into :accepted_n trimmed,:revenue trimmed,:returns trimmed from work.accepted;
  select count(*) into :rejected_n trimmed from work.rejected;
  select count(*) into :duplicate_n trimmed from work.rejected where reason='duplicate_accepted_key';
  select count(*) into :date_n trimmed from work.rejected where reason='invalid_date';
  select count(*) into :quantity_n trimmed from work.rejected where reason='invalid_quantity';
  select count(*) into :price_n trimmed from work.rejected where reason='invalid_unit_cents';
  select count(*) into :line_n trimmed from work.rejected where reason='invalid_line_number';
  select count(*) into :width_n trimmed from work.rejected where reason='field_width';
  select count(*) into :shape_n trimmed from work.rejected where reason='invalid_field_count';
  select count(*) into :quote_n trimmed from work.rejected where reason='quoted_record';
  select count(*) into :oversized_n trimmed from work.rejected where reason='oversized_record';
  select source_row into :accepted_rows separated by ',' from work.accepted order by source_row;
  select count(*) into :long_ids_n trimmed from work.rejected
    where source_row in (11,12) and lengthn(order_text)=21 and reason='field_width';
  select count(*) into :preserved_n trimmed from work.accepted
    where source_row=13 and order_id='ABCDEFGHIJKLMNOPQRST';
quit;
%macro verify;
  %if &accepted_n ne 5 or &rejected_n ne 18 or &revenue ne 2850 or &returns ne 1
    or &duplicate_n ne 2 or &date_n ne 1 or &quantity_n ne 3 or &price_n ne 1
    or &line_n ne 2 or &width_n ne 4 or &shape_n ne 2 or &quote_n ne 1
    or &oversized_n ne 1 or &long_ids_n ne 2 or &preserved_n ne 1 %then %do;
    %put ERROR: SAS native fixture reconciliation failed.;
    %abort cancel;
  %end;
  %if %superq(accepted_rows) ne %str(2,4,8,13,22) %then %do;
    %put ERROR: Accepted source row provenance differs.;
    %abort cancel;
  %end;
  %put NOTE: Native SAS fixture and source-provenance checks passed.;
%mend;
%verify;
