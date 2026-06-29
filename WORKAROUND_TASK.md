# Task — Implement Dataverse Collision Workaround

## Naming convention

AL API page properties `APIPublisher`, `APIGroup`, and `APIVersion` values must be **camelCase** (first letter lowercase). In this repo:

| File | APIPublisher | APIGroup | Casing |
|---|---|---|---|
| `ReproApiPageA.al` (page 50100) | `'Cronus'` | `'SalesData'` | ❌ PascalCase — wrong |
| `ReproApiPageB.al` (page 50101) | `'cronus'` | `'salesData'` | ✅ camelCase — correct |

**Page A has the wrong casing.** It must be obsoleted and replaced with a correctly-cased page.

---

## What to do

Obsolete `ReproApiPageA.al` and create a replacement with camelCase API properties that match Page B.

**Approach A — Normalize casing on Page A (required)**

Changing `APIPublisher`, `APIGroup`, or `APIVersion` on a live API page is a **breaking change** (it alters the OData URL). AppSourceCop rule AS0035 enforces this — the compiler will error if you modify these properties on a published page without first obsoleting it. The required sequence is:

1. **Obsolete the existing page** in `ReproApiPageA.al`:
   - Set `ObsoleteState = Pending`
   - Set `ObsoleteReason = 'Replaced by Repro API Page A v2 with corrected camelCase API publisher and group.'`
   - Set `ObsoleteTag = '1.0'`  ← extension's own version in `Major.Minor` format (from app.json), not the BC platform version
   - Leave all other properties unchanged — do not touch `APIPublisher`, `APIGroup`, etc.

2. **Create a new file** `ReproApiPageAv2.al` with the next available page ID (50102) and corrected camelCase values:
   - `APIPublisher = 'cronus'`   ← camelCase, matches Page B
   - `APIGroup = 'salesData'`    ← camelCase, matches Page B
   - `APIVersion = 'v2.0'`
   - `EntityName = 'reproItemA2'`    ← camelCase, distinct from the obsoleted Page A
   - `EntitySetName = 'reproItemsA2'` ← camelCase, distinct from the obsoleted Page A
   - All other properties identical to the current `ReproApiPageA.al`

---

## Constraints

- Do not modify `ReproApiPageB.al` — it already has correct camelCase.
- Never modify `APIPublisher`, `APIGroup`, `APIVersion`, `EntityName`, or `EntitySetName` on a page that is not already `ObsoleteState = Pending` or `Removed`. AppSourceCop AS0035 enforces this.
- The obsoleted page must remain in the codebase (do not delete it) until a future release promotes it to `ObsoleteState = Removed`. When promoting, update `ObsoleteTag` to the extension version at the time of removal (AS0072 fires if the tag is lower than the current `obsoleteTagVersion` in AppSourceCop.json).
- `ObsoleteTag` must use the extension's own version number in `Major.Minor` format (e.g. `'1.0'`), not the BC platform version. AppSourceCop AS0076 validates this format when a pattern is configured.
- Keep page IDs within the allocated range `50100–50149`.

---

## Done when

Opening BC page 5372 (Available Business Central Tables) on a tenant with all three pages published produces no error.
