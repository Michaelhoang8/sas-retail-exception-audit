"""Independent fixture oracle only. This does not execute or validate SAS syntax."""
import csv
import json
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
expected = json.loads((ROOT / 'fixtures/expected.json').read_text())
accepted, rejected, seen, total, returns = [], [], set(), 0, 0
with (ROOT / 'fixtures/sales.csv').open(newline='') as source:
    for row_number, row in enumerate(csv.DictReader(source), 2):
        try:
            line, quantity, price = int(row['line_number']), int(row['quantity']), int(row['unit_cents'])
            assert date.fromisoformat(row['posted']).isoformat() == row['posted']
            assert row['order_id'] and line > 0 and 0 < abs(quantity) <= 1_000_000 and 0 <= price <= 1_000_000
            key = row['order_id'], line
            assert key not in seen
        except (ValueError, AssertionError):
            rejected.append(row_number)
            continue
        seen.add(key)
        accepted.append(row_number)
        total += quantity * price
        returns += quantity < 0
actual = dict(accepted_source_rows=accepted, rejected_source_rows=rejected, net_revenue_cents=total, return_rows=returns)
assert actual == expected, (actual, expected)
print('Independent fixture contract passed. Native SAS execution remains required.')
