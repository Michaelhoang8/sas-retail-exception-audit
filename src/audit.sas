/* SAS 9.4 / Viya Compute, UTF-8 session. Strict unquoted five-field records. */
%macro audit(root=.);
%local header_seen;
%let header_seen=0;
filename sales "&root./fixtures/sales.csv" encoding='utf-8';
data work.accepted work.rejected;
  length raw_record $32767 order_text line_text date_text quantity_text price_text $512
         order_id $20 reason $300;
  if _n_ = 1 then do;
    call missing(order_id, line_number);
    declare hash seen();
    rc = seen.defineKey('order_id', 'line_number');
    rc = seen.defineData('order_id', 'line_number');
    rc = seen.defineDone();
  end;
  /* Read a physical record before splitting or narrowing any field. */
  infile sales truncover lrecl=32767 length=record_length;
  input @;
  input raw_record $varying32767. record_length;
  source_row = _n_;
  observed_bytes = record_length;
  raw_may_be_truncated = (record_length >= 32767);
  if source_row = 1 then do;
    if raw_record ne 'order_id,line_number,posted,quantity,unit_cents' then do;
      put 'ERROR: Unexpected CSV header. No records processed.';
      abort cancel;
    end;
    call symputx('header_seen', 1, 'l');
    delete;
  end;
  reason = '';
  if record_length > 512 then reason = 'oversized_record';
  else if countc(raw_record, '"') > 0 then reason = 'quoted_record';
  else if countc(raw_record, ',') ne 4 then reason = 'invalid_field_count';
  else do;
    order_text = strip(scan(raw_record, 1, ',', 'm'));
    line_text = strip(scan(raw_record, 2, ',', 'm'));
    date_text = strip(scan(raw_record, 3, ',', 'm'));
    quantity_text = strip(scan(raw_record, 4, ',', 'm'));
    price_text = strip(scan(raw_record, 5, ',', 'm'));
    if max(lengthn(order_text), lengthn(line_text), lengthn(date_text),
           lengthn(quantity_text), lengthn(price_text)) > 20 then reason = 'field_width';
  end;
  if missing(reason) then do;
    /* Width is checked before assigning a bounded key or converting numbers. */
    order_id = order_text;
    line_number = input(line_text, ?? best32.);
    quantity = input(quantity_text, ?? best32.);
    unit_cents = input(price_text, ?? best32.);
    posted = input(date_text, ?? yymmdd10.);
    if missing(order_id) then reason = catx(';', reason, 'missing_order_id');
    if prxmatch('/^[0-9]+$/', strip(line_text)) ne 1 or missing(line_number)
       or line_number < 1 or line_number > 1000000 or line_number ne floor(line_number)
      then reason = catx(';', reason, 'invalid_line_number');
    if missing(posted) or put(posted,yymmdd10.) ne strip(date_text)
      then reason = catx(';', reason, 'invalid_date');
    if prxmatch('/^-?[0-9]+$/', strip(quantity_text)) ne 1 or missing(quantity)
       or quantity = 0 or quantity ne floor(quantity) or abs(quantity) > 1000000
      then reason = catx(';', reason, 'invalid_quantity');
    if prxmatch('/^-?[0-9]+$/', strip(price_text)) ne 1 or missing(unit_cents)
       or unit_cents < 0 or unit_cents ne floor(unit_cents) or unit_cents > 1000000
      then reason = catx(';', reason, 'invalid_unit_cents');
    if missing(reason) then do;
      rc = seen.check();
      if rc = 0 then reason = 'duplicate_accepted_key';
      else rc = seen.add();
    end;
  end;
  format posted yymmdd10.;
  if missing(reason) then do;
    revenue_cents = quantity * unit_cents;
    output work.accepted;
  end;
  else output work.rejected;
  drop rc record_length;
run;
%if &header_seen ne 1 %then %do;
  %put ERROR: Required CSV header was not read.;
  %abort cancel;
%end;
proc sql;
  create table work.summary as
  select count(*) as accepted_rows,
         coalesce(sum(revenue_cents),0) as net_revenue_cents,
         coalesce(sum(case when quantity < 0 then 1 else 0 end),0) as return_rows
  from work.accepted;
quit;
%mend;
