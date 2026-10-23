# Malaysia boundary import contract

This project treats a **township** as an operational service area, not merely a
place name. A valid row must have a reviewed polygon and a named source. This
avoids presenting an uncertain map boundary as a legal responsibility boundary.

## National scope

The routing migration seeds Malaysia's 13 states and the federal territories of
Kuala Lumpur, Labuan, and Putrajaya. Local authorities and townships are added
per state; they are never inferred from a city name alone.

## Import order

1. Import an authoritative local-authority list for one state into
   `local_authorities`.
2. Create each assignable organisation in `responsible_authorities` (council,
   developer, JMB/MC, utility, or road agency).
3. Convert reviewed GeoJSON features to EPSG:4326 `MultiPolygon` records in
   `townships`. Record both `boundary_source_name` and `boundary_source_url`.
4. Add a township default authority, then specific `authority_routing_rules`
   for issue types that need a different owner.
5. Test representative coordinates on polygon interiors and edges before
   enabling the township.

## GeoJSON validation requirements

- CRS: WGS 84 / EPSG:4326, with longitude before latitude.
- Geometry: Polygon or MultiPolygon; convert Polygon to MultiPolygon on import.
- The feature must be valid, non-empty, and attributable to a source.
- Store the source URL and review timestamp. Do not treat a point geocode or
  place label as a boundary.
- For OpenStreetMap-derived data, retain the required attribution and mark it
  as provisional until confirmed by the responsible local authority.

## Routing behavior

When a report is submitted, the database selects the smallest township polygon
that covers its coordinate. It then chooses the most specific active routing
rule (township + issue type), falls back to a township-only/default rule, and
writes an immutable assignment-history row. A dispatcher or platform developer
can call `manually_assign_report_issue` to reassign it with a reason.

## First pilot

Start with one local authority and 5–10 reviewed townships, not all Malaysia at
once. Success criteria are: every submitted report gets either an explicit
assignee or a visible "unassigned" result; each auto-assignment can be
explained by its township/rule; and a dispatcher can correct it without
deleting audit history.
