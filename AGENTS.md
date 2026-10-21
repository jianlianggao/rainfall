# Agent Instructions

Follow [CONTRIBUTING.md](CONTRIBUTING.md), the source of truth for project
conventions. These instructions apply throughout the repository.

## Development Conventions

- Support Python 3.10 and later. Install development dependencies with
  `python -m pip install -e ".[dev]"` and install commit hooks with
  `pre-commit install`, preferably in `.venv`.
- Use absolute imports, PEP 8 names, Ruff's 88-character line length, and strict
  type hints for every function, including tests. Mypy covers `src/` and `tests/`.
- Suffix physical quantities with their units, such as `rain_mm`, `values_mm`,
  and `window_days`. Use ISO 8601 dates named `date`, `start_date`, or `end_date`.
- Put thresholds and fixed values in module-level constants with explanatory
  docstrings and unit suffixes, such as `WET_DAY_THRESHOLD_MM`.
- Give public modules, classes, and functions NumPy-style docstrings documenting
  quantity units. Prefix private modules and functions with an underscore.
- Accept `Sequence[Record]` records first in public statistics functions, where
  `Record` is a `(date, rain_mm)` tuple. Decorate public functions accepting
  records with `rainfall._validation.validate_records`; do not duplicate input
  validation. Raise exceptions from `rainfall.exceptions`. New exceptions must
  end in `Error` and inherit from `RainfallError`.
- Export new public functions from `src/rainfall/__init__.py` and `__all__`.
- Put tests in the matching existing test module. Name them
  `test_<function>_<behaviour>` and reuse fixtures in `tests/conftest.py`.
  Add tests for new behavior and regression tests for fixes. Do not change an
  existing test merely to make it pass; propose test corrections separately.
- Use Conventional Commits with imperative summaries under 72 characters and
  one logical change per commit. Add user-visible changes to the appropriate
  `Unreleased` section in `CHANGELOG.md`. Leave releases to maintainers.

## Rainfall Analysis

Use [data/raw/rainfall_march_2026.csv](data/raw/rainfall_march_2026.csv) as the
reference input. Its columns are `date,rain_mm`, with daily records in ascending
date order. Never edit, rename, or overwrite files in `data/raw/`. Write derived
data only to ignored `data/processed/`. Document the source and licence of any
new raw input in `data/README.md`.

When implementing or reporting the following statistics, state the date range
and units, include both range endpoints, and include dry days in daily means:

1. **Length in days:** distinguish the number of observed daily records from
   elapsed calendar days when dates are missing. The complete March input has
   31 records covering 31 calendar days, March 1 through March 31 inclusive.
2. **Total rainfall in mm:** sum every included daily value. The full March
   input totals 92.6 mm. Compare floating-point results approximately in tests.
3. **Mean rainfall in mm:** divide the total by the number of included daily
   records, including zero-rainfall records. March's daily mean is
   `92.6 / 31`, approximately 2.9870967742 mm.
4. **Rainfall over consecutive days:** interpret "main rainfall" as maximum
   accumulated rainfall over a specified `window_days` unless the request says
   otherwise. Confirm the window length before choosing one. Examine every
   complete calendar-consecutive window, including the last; do not bridge
   missing dates. Report the winning start date, end date, and total in mm.
   If a moving mean is requested instead, divide each window total by
   `window_days`. Reject invalid window sizes through project exceptions.
5. **Driest day:** return the date with the least rainfall. Break ties by choosing
   the earliest date and state that policy. March's earliest driest day is
   `2026-03-04`, with 0.0 mm; other dates also have zero rainfall.
6. **Wettest day:** return the date with the most rainfall, choosing the earliest
   on ties. March's wettest day is `2026-03-23`, with 18.3 mm.

These are reference expectations, not a claim that every statistic is already
implemented correctly. Do not hard-code the reference results in application
code, and do not alter raw data to make a check pass.

### Existing-script check against the raw input

The existing statistics functions and CLI were run against
`data/raw/rainfall_march_2026.csv`. Observed results:

- **Record count and dates:** correct, 31 records from `2026-03-01` through
  `2026-03-31`.
- **Total:** incorrect, 89.7 mm instead of 92.6 mm. `total_rain` excludes its
  `end_date`, so the final day's 2.9 mm is omitted.
- **Mean:** `mean` returns the expected 2.9870967742 mm/day, but the CLI rounds
  it to `3.0 mm/day`.
- **Seven-day moving average:** only 24 values are returned instead of 25; the
  final window (`2026-03-25` through `2026-03-31`) is omitted. The last
  returned value is 1.6714285714 mm, not the expected final-window mean of
  1.2142857143 mm.
- **Driest day:** no `driest_day` statistics function exists.
- **Wettest day:** the function returns the expected date,
  `2026-03-23`; the CLI does not print its rainfall amount.
- **CLI coverage:** the summary prints record count, total, rounded mean and
  wettest date only; it does not report a moving average or driest day.

When checking these scripts against the raw input, report these discrepancies
instead of treating the existing output as correct. Existing tests use small
fixtures and do not by themselves verify these full-March reference values.

## Required Checks And Completion Hook

Run all checks from `CONTRIBUTING.md` before completing work:

```bash
ruff check .
ruff format --check .
mypy
python -m pytest
```

[.github/hooks/checks.json](.github/hooks/checks.json) registers a Copilot `Stop`
hook that runs [.github/hooks/run-checks.sh](.github/hooks/run-checks.sh) whenever
the agent finishes a turn. The runner uses the repository's `.venv` when present,
attempts all four checks, and returns a failure status if any fail. Run it manually
with `bash .github/hooks/run-checks.sh` to reproduce the hook's checks.

Hooks must be enabled in a trusted workspace in a Copilot client supporting
repository hooks. In VS Code, enable `chat.useHooks` if it is disabled and start
a new chat session after adding the hook. The hook reports failures without
requesting an automatic retry. Report any failing checks in the completion
summary; never claim they passed when they did not.