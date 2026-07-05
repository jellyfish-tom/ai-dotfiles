---
description: Ask for region, brand, task id, flow, or environment when project work is ambiguous and those values are required.
applyTo: '**'
---

# Operator Context

When any value below is required and not already stated by the operator, ask and stop instead of assuming.

## Parameters

| Parameter | When required | Allowed values (examples) |
|-----------|---------------|---------------------------|
| region | Region-specific code or config | REGION_A, REGION_B |
| brand | Brand-specific UI or components | BRAND_X, BRAND_Y |
| task id | Delivery workflow or commit metadata | e.g. PROJ-123 |
| flow or surface | Ambiguous feature reference without a path | route, feature folder, or region plus brand |
| environment | Deploy, smoke test, or API base URL | operator-provided name |

## Ask and stop

- Editing region- or brand-scoped paths without stated region and brand.
- Implementing from a ticket that does not clearly scope one region/brand when the change is not shared.
- Inferring region or brand from branch name alone.
