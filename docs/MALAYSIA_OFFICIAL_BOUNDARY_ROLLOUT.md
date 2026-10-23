# Malaysia official-boundary rollout

## Operating rule

Only government or local-authority spatial data is eligible to activate an
automatic routing polygon. All other geometry remains unassigned and cannot
set `townships.is_active = true`.

## Verified national reference layers

| Layer | Publisher/service | Use in Pavra | Status |
| --- | --- | --- | --- |
| Admin1 | MyGOS / Pusat Geospatial Negara | State and federal-territory reference | Ready |
| Admin2 | MyGOS / Pusat Geospatial Negara | District reference; not an assignment boundary | Ready |
| Mukim | PLANMalaysia | Peninsular Malaysia review reference; not a township substitute | Ready |

Run the downloader from the repository root. One command gets every verified
national reference layer and records its URLs, download timestamp, file paths,
and feature counts in a manifest:

```powershell
.\tools\fetch_official_malaysia_boundaries.ps1 -Layer all
```

The output is deliberately ignored by Git. It is source material, not yet an
approved Pavra routing boundary.

## Rollout sequence

1. **Selangor** — obtain the PBT/local-authority service boundary and each
   participating developer/JMB service area.
2. **Kuala Lumpur** — use DBKL-published service/administrative layers and
   explicitly distinguish DBKL from utility and highway agencies.
3. **Putrajaya** — obtain Perbadanan Putrajaya service areas.
4. **Pulau Pinang** — use Penang GeoHub layers, then separately review MBPP
   and MBSP coverage.
5. Continue state by state only after the prior batch has passed coordinate
   edge tests and has an accountable data owner.

## Per-state acceptance checklist

- Data source has a public government or local-authority URL and capture date.
- Geometry is WGS 84 / EPSG:4326 and validates as a Polygon or MultiPolygon.
- Each routing polygon has a default responsible authority.
- At least three interior points and two boundary-adjacent points are tested.
- Overlapping polygons have an explicit routing priority.
- A named owner has approved the mapping and review date.

Use `data/gis/township-routing-template.csv` as the hand-off sheet for each
approved routing area. One row represents one township-to-authority-to-issue
type rule; the boundary file itself stays in `data/gis/reviewed/` until it is
loaded into Supabase.

## Import safety

Do not insert a downloaded Admin2 or Mukim record into `townships` merely
because it has a polygon. Use it as a review overlay. A township becomes active
only when its boundary represents the responsible authority's service area.
