# Retail exception audit

Separate accepted sales/returns from data-quality exceptions, preserving source row numbers and reconciling integer-cent totals.

Language: **SAS**.

[![Validation](https://github.com/Michaelhoang8/sas-retail-exception-audit/actions/workflows/ci.yml/badge.svg)](https://github.com/Michaelhoang8/sas-retail-exception-audit/actions/workflows/ci.yml)

## Run

```sh
sas -sysin run.sas
```

## Behavior

- Reads each physical record before splitting fields or narrowing identifiers. Checks dates, integer quantities, line identifiers, prices and duplicate accepted keys.
- Negative quantities represent returns; zero quantities and negative unit prices are rejected.
- Expected fixture result: 5 accepted rows, 18 rejected rows and 2,850 net cents.

Input is deliberately a strict subset of CSV: UTF-8, the exact checked-in header, five comma-separated **unquoted** fields per physical line, and at most 512 bytes excluding the line terminator. Double quotes, extra/missing fields and oversized records are rejected before parsing. Leading/trailing spaces in each field are trimmed. Each trimmed field must fit in 20 bytes; longer identifiers are rejected before assigning the duplicate key, so IDs sharing a 20-byte prefix cannot collide. Line numbers are decimal integers from 1 through 1,000,000. Quantities/prices use decimal integer text, without exponent notation or a plus sign.

Accepted and rejected rows retain the physical `source_row`, original `raw_record` and observed record length. The raw buffer holds up to 32,767 bytes; an out-of-contract record reaching that limit is rejected and marked `raw_may_be_truncated`, not represented as a fully preserved original. Use a UTF-8 SAS session. Quoted/multiline CSV, arbitrary delimiters and long records are outside this parser's contract.

## Validation

```sh
sas -sysin tests/test_audit.sas
python tests/verify_fixture.py
```

The workflow executes the Python fixture oracle and record-boundary checks. The expanded native SAS test checks source row IDs, rejection categories, long IDs sharing a prefix, oversized line numbers, shape/quoting errors and totals. See the workflow log for the actual oracle result; it is not a native SAS result.

## Scope

Native SAS has not been executed: a licensed SAS 9.4 or Viya Compute environment is required. CI checks the fixture contract with an independent Python oracle only, and does not validate SAS syntax. SAS numeric values are floating-point; integer-cent arithmetic is exact only within the numeric precision range. This is a local batch prototype, not a deployed retail system.

Code: [MIT](LICENSE). Fixtures are constructed examples.
