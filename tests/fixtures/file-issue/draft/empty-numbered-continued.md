# file-issue: add CSV export to the report page

**Blocked by:** None

## Problem

Analysts copy the report table into a spreadsheet by hand every week, and the paste drops the column order. Nothing in the app exports it today.

1.
   Run python3 demo.py.

## Proposed Behavior

The report page offers a Download CSV button. The file holds the visible rows in the visible column order.

## Acceptance Criteria

- [ ] Clicking Download CSV saves a file whose header row matches the table header.
- [ ] A report with zero rows saves a file holding only the header row.

## Non-Goals

- Exporting formats other than CSV.

## For a Coding Agent

- **Verify with:** `bash tests/export-smoke.sh`
- **Setup:** Python 3, standard library only.
- **Start here:** `src/report/export.py`
- **Done when:** both criteria above pass.
- **Out of scope:** the report query.
