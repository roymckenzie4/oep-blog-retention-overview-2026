// Shared formatting utilities

// Strips common "School District" suffix variants (e.g. "School Dist.", "Sch. Dist.")
// Names come from the GeoJSON NAME field which already has correct capitalization.
export function formatName(str) {
  return str.replace(/\s+Sch(ool)?\.*\s+Dist(rict)?\.?\s*$/i, "").replace(/\s+Schools\s*$/i, "");
}
