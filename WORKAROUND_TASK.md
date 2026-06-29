# Task — Implement Dataverse Collision Workaround

## What to do

Fix the casing collision between `ReproApiPageA.al` and `ReproApiPageB.al` so the Dataverse virtual table catalog no longer crashes.

**Choose one of the two approaches below. Approach A is preferred.**

---

## Approach A — Normalize casing (recommended)

Make `ReproApiPageB.al` use the same CamelCase as `ReproApiPageA.al`.

Changing `APIPublisher`, `APIGroup`, or `APIVersion` on a live API page is a **breaking change** (it alters the OData URL). AppSourceCop rule AS0035 enforces this — the compiler will error if you modify these properties on a published page without first obsoleting it. The required sequence is:

1. **Obsolete the existing page** in `ReproApiPageB.al`:
   - Set `ObsoleteState = Pending`
   - Set `ObsoleteReason = 'Replaced by Repro API Page B v2 with corrected API publisher casing.'`
   - Set `ObsoleteTag = '1.0'`  ← use the extension's own version at the time of obsoleting, not the BC platform version
   - Leave all other properties unchanged.

2. **Create a new file** `ReproApiPageBv2.al` with the next available page ID (50102) and corrected casing:
   - `APIPublisher = 'Cronus'`  ← matches Page A
   - `APIGroup = 'SalesData'`   ← matches Page A
   - `APIVersion = 'v1.0'`
   - New `EntityName` and `EntitySetName` to avoid OData conflicts (e.g. `reproItemB2` / `reproItemsB2`).

---

## Approach B — Bump the version

If casing must stay as-is on Page B, give it a distinct `APIVersion` so the keys no longer collide.

Same breaking-change rule applies — obsolete first, then recreate:

1. **Obsolete the existing page** in `ReproApiPageB.al` (same obsolete properties as Approach A — `ObsoleteState = Pending`, `ObsoleteTag = '1.0'`).

2. **Create `ReproApiPageBv2.al`** (page ID 50102) identical to the original Page B except:
   - `APIVersion = 'v2.0'`  ← no longer collides with Page A's `'v1.0'`

---

## Constraints

- Never modify `APIPublisher`, `APIGroup`, `APIVersion`, `EntityName`, or `EntitySetName` on a page that is not already `ObsoleteState = Pending` or `Removed`. AppSourceCop AS0035 enforces this.
- The obsoleted page must remain in the codebase (do not delete it) until a future release promotes it to `ObsoleteState = Removed`. When promoting, update `ObsoleteTag` to the extension version at the time of removal (AS0072 fires if the tag is lower than the current `obsoleteTagVersion` in AppSourceCop.json).
- `ObsoleteTag` must use the extension's own version number in `Major.Minor` format (e.g. `'1.0'`), not the BC platform version. AppSourceCop AS0076 validates this format when a pattern is configured.
- Keep page IDs within the allocated range `50100–50149`.

---

## Done when

Opening BC page 5372 (Available Business Central Tables) on a tenant with both pages published produces no error.
