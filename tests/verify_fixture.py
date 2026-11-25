"""Independent strict-record fixture oracle. Does not execute SAS syntax."""
import json
import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEADER = b'order_id,line_number,posted,quantity,unit_cents'


def audit(data):
    records = data.splitlines()
    if not records or records[0] != HEADER:
        raise ValueError('Unexpected CSV header')
    accepted, rejected, reasons, seen, total, returns = [], [], {}, set(), 0, 0
    for source_row, raw in enumerate(records[1:], 2):
        reason = []
        if len(raw) > 512:
            reason = ['oversized_record']
        elif b'"' in raw:
            reason = ['quoted_record']
        elif raw.count(b',') != 4:
            reason = ['invalid_field_count']
        else:
            fields = [field.strip(b' ') for field in raw.split(b',')]
            if max(map(len, fields)) > 20:
                reason = ['field_width']
            else:
                order, line_text, posted, quantity_text, price_text = [field.decode('utf8') for field in fields]
                if not order:
                    reason.append('missing_order_id')
                line = int(line_text) if re.fullmatch('[0-9]+', line_text) else None
                quantity = int(quantity_text) if re.fullmatch('-?[0-9]+', quantity_text) else None
                price = int(price_text) if re.fullmatch('-?[0-9]+', price_text) else None
                if line is None or not 1 <= line <= 1000000:
                    reason.append('invalid_line_number')
                try:
                    if date.fromisoformat(posted).isoformat() != posted: raise ValueError()
                except ValueError:
                    reason.append('invalid_date')
                if quantity is None or not 0 < abs(quantity) <= 1000000:
                    reason.append('invalid_quantity')
                if price is None or not 0 <= price <= 1000000:
                    reason.append('invalid_unit_cents')
                if not reason:
                    key = order, line
                    if key in seen: reason.append('duplicate_accepted_key')
                    else: seen.add(key)
        if reason:
            rejected.append(source_row); reasons[str(source_row)] = ';'.join(reason)
        else:
            accepted.append(source_row); total += quantity * price; returns += quantity < 0
    return dict(accepted_source_rows=accepted, rejected_source_rows=rejected,
                net_revenue_cents=total, return_rows=returns, rejection_reasons=reasons)


if __name__ == '__main__':
    expected = json.loads((ROOT/'fixtures/expected.json').read_text())
    actual = audit((ROOT/'fixtures/sales.csv').read_bytes())
    assert actual == expected, (actual, expected)
    valid = b'A,1,2026-01-01,1,1'
    exact = valid + b' ' * (512-len(valid))
    assert audit(HEADER+b'\n'+exact+b'\n')['accepted_source_rows'] == [2]
    assert audit(HEADER+b'\n'+exact+b' \n')['rejection_reasons'] == {'2':'oversized_record'}
    assert audit(HEADER+b'\n\n')['rejection_reasons'] == {'2':'invalid_field_count'}
    try: audit(b'wrong,header\n'+valid)
    except ValueError: pass
    else: raise AssertionError('wrong header accepted')
    print('Independent fixture contract and record-boundary checks passed. Native SAS execution remains required.')
