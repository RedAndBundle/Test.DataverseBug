# Dataverse Virtual Table Catalog Collision — Reproduction Case

## Summary

This repository is a minimal Business Central AL extension to reproduce a bug where having **two API pages with the same `APIPublisher` / `APIGroup` / `APIVersion` values but different casing** causes a crash in the Dataverse virtual-table catalog integration.

**Error observed:**

```
The record in table CDS Available Virtual Table Buffer already exists.
```

This error appears on any BC tenant that has the Dataverse (Power Platform / Common Data Service) connection enabled, specifically when BC loads the list of available virtual tables — the "Available Business Central tables" page in the Power Platform admin experience, or when the `CDS Integration Impl.` codeunit internally calls `LoadAvailableVirtualTables`.

---

## Observed Error Details

Full diagnostic output captured from the live incident:

```
Error message:
The record in table CDS Available Virtual Table Buffer already exists.
Identification fields and values: Business Central Table='{A08A1C84-0000-0000-0000-000000000000}'

Internal session ID:
1ab38e7e-b317-403e-895e-2c7dd63d9105

Application Insights session ID:
81b782ff-c512-450e-86f0-36e3bd3adcda

Client activity id:
e9e33dc3-eb78-49e9-8b72-2baa7eb14c82

Time stamp on error:
2026-06-29T07:36:39.6651567Z

User telemetry id:
38e99ed7-5de8-4974-8d3c-bff02d4685e1

AL call stack:
"CDS Integration Impl."(CodeUnit 7201).LoadAvailableVirtualTables line 50 - Base Application by Microsoft version 28.1.49838.51713
"CDS Available Virtual Tables"(Page 5372).OnOpenPage(Trigger) line 5 - Base Application by Microsoft version 28.1.49838.51713
```

The call stack confirms the crash originates in `LoadAvailableVirtualTables` (line 50 of codeunit 7201) and is triggered the moment **Page 5372 opens** — meaning any user navigating to the Available Business Central Tables page hits this error immediately.

---

## Root Cause

Business Central's `CDS Integration Impl.` codeunit (id 7201), procedure `LoadAvailableVirtualTables`, enumerates all `PageType = API` pages and groups them into a buffer table keyed on publisher/group/version. The comparison is **case-sensitive**. Two API pages with:

```al
// Page A
APIPublisher = 'ForNav';
APIGroup = 'AppManagement';
APIVersion = 'v1.0';

// Page B  (same app, different file, or a second installed app)
APIPublisher = 'forNav';
APIGroup = 'appManagement';
APIVersion = 'v1.0';
```

produce **two distinct keys** during enumeration, but the downstream `INSERT` into `CDS Available Virtual Table Buffer` uses a normalized (case-insensitive) key — so the second insert hits a duplicate-key error.

### Why this is hard to spot

- The error only manifests on tenants with an active Dataverse connection; pure BC tenants are unaffected.
- The two pages can be in entirely different sub-projects / apps (e.g. one in a `Core` module, one in a `Report Pack` module) installed on the same tenant.
- The page with the wrong casing may be `ObsoleteState = Pending` and completely unused — it still gets enumerated.
- No compile-time or AppSource validation catches casing mismatches between API pages across apps.

---

## How to Reproduce

### Prerequisites

- A Business Central SaaS or on-prem tenant (BC 23+).
- A Dataverse / Power Platform environment connected to that tenant.
- The "Available Business Central tables" virtual-table feature enabled.

### Steps

1. Clone this repository.
2. Compile and publish the AL app in `Repro/` to the same BC tenant. It contains two API pages:
   - `ReproApiPageA.al` (page 50100) — `APIPublisher = 'Cronus'` / `APIGroup = 'SalesData'`
   - `ReproApiPageB.al` (page 50101) — `APIPublisher = 'cronus'` / `APIGroup = 'salesData'`
3. In the Power Platform admin center (or the BC **Available Business Central Tables** page), trigger a refresh of the virtual-table catalog.
4. Observe the error: `The record in table CDS Available Virtual Table Buffer already exists.`

> **Note:** The casing that collides is `'Cronus'` vs `'cronus'` and `'SalesData'` vs `'salesData'`. Any pair of values that differ only in casing will trigger this.

---

## The Fix (Applied in ForNAV Report Pack)

In the ForNAV Customizable Report Pack, the collision was between:

| File | Page ID | APIPublisher | APIGroup |
|---|---|---|---|
| `Core/HelperApi.al` (multiple pages) | 6189110–6189469 | `'ForNav'` | `'AppManagement'` |
| `Report Pack/Source Control/RepositoriesApi.Page.al` | 6188528 | `'forNav'` | `'appManagement'` |

The `RepositoriesApi` page was already `ObsoleteState = Pending` (superseded by Source Control V2 in release 8.1.0.14) and had zero callers. The fix was to **delete it** rather than reconcile the casing, since fixing the casing on an obsolete page served no purpose.

Fix commit: `f5dbb813` — *"Remove obsolete Repositories API page causing Dataverse virtual table catalog collision"*

---

## Recommendation to Microsoft

The `LoadAvailableVirtualTables` procedure in `CDS Integration Impl.` (codeunit 7201) should normalize `APIPublisher`, `APIGroup`, and `APIVersion` to a consistent case (e.g. lower-case) before inserting into the buffer table — or use a case-insensitive key. As-is, a casing inconsistency across two independently developed apps (or two sub-projects in the same app) silently breaks the Dataverse integration for all tenants with the connection enabled, with no indication during development or AppSource validation.

A secondary recommendation: AppSource validation (or the AL compiler) should warn when an extension's API pages use casing that differs from other installed extensions sharing the same publisher name.

---

## Contact / Handover

Discovered by: René Brummel \<rbr@redandbundle.com\>  
Product: ForNAV Customizable Report Pack  
Fix date: 2026-06-25  
BC versions affected: BC 23+ (the `GE_BC_23_0_0_0` preprocessor guard on the offending page confirms it was only compiled on BC 23 and later)
