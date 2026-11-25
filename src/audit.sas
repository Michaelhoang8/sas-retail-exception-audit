/* SAS 9.4 / SAS Viya Compute. Input values are retained as text for review. */
%macro audit(root=.);
filename sales "&root./fixtures/sales.csv" encoding='utf-8';
data work.accepted work.rejected;
  length order_id $20 line_text $20 date_text $20 quantity_text $20 price_text $20 reason $300;
  if _n_ = 1 then do;
    declare hash seen();
    rc = seen.defineKey('order_id', 'line_number');
    rc = seen.defineData('order_id', 'line_number');
    rc = seen.defineDone();
  end;
  infile sales dsd dlm=',' firstobs=2 truncover lrecl=512;
  input order_id :$20. line_text :$20. date_text :$20. quantity_text :$20. price_text :$20.;
  source_row = _n_ + 1;
  line_number = input(line_text, ?? best32.);
  quantity = input(quantity_text, ?? best32.);
  unit_cents = input(price_text, ?? best32.);
  posted = input(date_text, ?? yymmdd10.);
  format posted yymmdd10.;
  reason = '';
  if missing(order_id) then reason = catx(';', reason, 'missing_order_id');
  if missing(line_number) or line_number < 1 or line_number ne floor(line_number)
    then reason = catx(';', reason, 'invalid_line_number');
  if missing(posted) or put(posted,yymmdd10.) ne strip(date_text)
    then reason = catx(';', reason, 'invalid_date');
  if missing(quantity) or quantity = 0 or quantity ne floor(quantity) or abs(quantity) > 1000000
    then reason = catx(';', reason, 'invalid_quantity');
  if missing(unit_cents) or unit_cents < 0 or unit_cents ne floor(unit_cents) or unit_cents > 1000000
    then reason = catx(';', reason, 'invalid_unit_cents');
  if missing(reason) then do;
    rc = seen.check();
    if rc = 0 then reason = 'duplicate_accepted_key';
    else rc = seen.add();
  end;
  if missing(reason) then do;
    revenue_cents = quantity * unit_cents;
    output work.accepted;
  end;
  else output work.rejected;
  drop rc;
run;
proc sql;
  create table work.summary as
  select count(*) as accepted_rows,
         coalesce(sum(revenue_cents),0) as net_revenue_cents,
         coalesce(sum(case when quantity < 0 then 1 else 0 end),0) as return_rows
  from work.accepted;
quit;
%mend;
