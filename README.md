# Retail exception audit

Separate accepted sales/returns from data-quality exceptions, preserving source row numbers and reconciling integer-cent totals.

Language: **SAS**.

[![Validation](https://github.com/Michaelhoang8/sas-retail-exception-audit/actions/workflows/ci.yml/badge.svg)](https://github.com/Michaelhoang8/sas-retail-exception-audit/actions/workflows/ci.yml)

## Run

```sh
sas -sysin run.sas
```

## Behavior

- Checks dates, integer quantities, line identifiers, prices and duplicate accepted keys.
- Negative quantities represent returns; zero quantities and negative unit prices are rejected.
- Expected fixture result: 3 accepted rows, 6 rejected rows and 2,750 net cents.

## Validation

```sh
sas -sysin tests/test_audit.sas
python tests/verify_fixture.py
```

The workflow executes the checked-in fixtures and boundary tests. See the workflow log for the actual result; tests are included with the source.

## Scope

Native SAS has not been executed: a licensed SAS 9.4 or Viya Compute environment is required. CI checks the fixture contract with an independent Python oracle only, and does not validate SAS syntax. SAS numeric values are floating-point; integer-cent arithmetic is exact only within the numeric precision range. This is a local batch prototype, not a deployed retail system.

Code: [MIT](LICENSE). Fixtures are constructed examples.
