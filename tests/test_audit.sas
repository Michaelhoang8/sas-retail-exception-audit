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
quit;
%macro verify;
  %if &accepted_n ne 3 or &rejected_n ne 6 or &revenue ne 2750 or &returns ne 1
    or &duplicate_n ne 1 or &date_n ne 1 or &quantity_n ne 2 or &price_n ne 1 %then %do;
    %put ERROR: SAS native fixture reconciliation failed.;
    %abort cancel;
  %end;
  %put NOTE: Eight native SAS fixture checks passed.;
%mend;
%verify;
