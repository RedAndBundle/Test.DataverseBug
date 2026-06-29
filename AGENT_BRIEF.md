# Agent Brief — Dataverse Virtual Table Catalog Collision Fix

## Goal

Find and fix the procedure in BC Base Application codeunit 7201 (`CDS Integration Impl.`) that crashes when two API pages share the same `APIPublisher`/`APIGroup`/`APIVersion` values but with different casing.

---

## The Bug

`LoadAvailableVirtualTables` (codeunit 7201, line 50) enumerates all `PageType = API` pages. It builds a buffer key from `APIPublisher + APIGroup + APIVersion`. The enumeration is **case-sensitive**, so `'Cronus'+'SalesData'+'v1.0'` and `'cronus'+'salesData'+'v1.0'` are treated as two distinct entries. The subsequent `INSERT` into `CDS Available Virtual Table Buffer` (table 5372) uses a **case-insensitive** key, so the second insert fails with:

```
The record in table CDS Available Virtual Table Buffer already exists.
Identification fields and values: Business Central Table='{A08A1C84-0000-0000-0000-000000000000}'
```

The crash happens at `OnOpenPage` of page 5372, meaning it is unavoidable for any user who opens the Available Business Central Tables page.

---

## Where to Look

| Object | ID | Procedure | Line |
|---|---|---|---|
| `CDS Integration Impl.` | Codeunit 7201 | `LoadAvailableVirtualTables` | ~50 |
| `CDS Available Virtual Tables` | Page 5372 | `OnOpenPage` | ~5 |
| `CDS Available Virtual Table Buffer` | Table 5372 | — | key field |

The AL source for these objects is in the BC Base Application. The relevant symbols are in:
`Repro/.alpackages/Microsoft_Base Application_28.1.49838.51713.app`

---

## Reproduction

The `Repro/` folder in this repo contains a single AL app with two API pages that trigger the collision:

| File | Page ID | APIPublisher | APIGroup |
|---|---|---|---|
| `ReproApiPageA.al` | 50100 | `'Cronus'` | `'SalesData'` |
| `ReproApiPageB.al` | 50101 | `'cronus'` | `'salesData'` |

Publish the app to a BC tenant with an active Dataverse connection, then open page 5372.

---

## Required Fix

In `LoadAvailableVirtualTables`, normalize `APIPublisher`, `APIGroup`, and `APIVersion` to a consistent case (lowercase recommended) **before** using them as a key or calling `INSERT` on the buffer table.

Pseudocode intent:

```al
// Before building the key / inserting:
publisher := LowerCase(PageMetadata.APIPublisher);
group     := LowerCase(PageMetadata.APIGroup);
version   := LowerCase(PageMetadata.APIVersion);
```

If the buffer table key itself is the collision point, an alternative is to guard the insert with a `GET`/existence check and skip duplicates — but normalization is the cleaner fix and prevents silent data loss from the skip approach.

---

## Constraints

- Do not change the `EntityName`, `EntitySetName`, or `ODataKeyFields` values — those are unrelated.
- The fix must not alter behaviour for tenants without a Dataverse connection.
- BC version in scope: 28.1.49838.51713 (BC 28 / 2025 Wave 1). The `GE_BC_23_0_0_0` preprocessor guard on the original offending page confirms the code path exists from BC 23 onward.
- This is a Base Application fix — deliver it as a Microsoft hotfix suggestion or a workaround extension that event-subscribes to override the affected logic.

---

## Acceptance Criteria

1. Publishing both `ReproApiPageA.al` and `ReproApiPageB.al` to the same tenant no longer causes an error when page 5372 opens.
2. The Available Business Central Tables page loads successfully and lists both `Cronus/SalesData` pages as a single deduplicated entry (or two entries if deduplication is not the chosen approach — as long as no error is thrown).
3. No regression on tenants that have only correctly-cased API pages.
