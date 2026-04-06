import * as Plot from "../../_npm/@observablehq/plot@0.6.17/a96a6bbb.js";
import * as d3 from "../../_npm/d3@7.9.0/66d82917.js";
import { attachTooltip } from "./tooltip.169ffc84.js";
import { formatName } from "./utils.dd133555.js";

const SELECTED_STROKE = "#e53935";
const SELECTED_STROKE_WIDTH = "2.5";
const DEFAULT_STROKE = "#444";
const DEFAULT_STROKE_WIDTH = "0.5";
const HOVER_STROKE = "#000";
const HOVER_STROKE_WIDTH = "2";

const MARGIN = 30; // padding inside the SVG on all sides

// Discrete retention-rate color scale with exact breakpoints (proportions, 0–1)
const COLOR_THRESHOLDS = [0.65, 0.7, 0.75, 0.8, 0.85, 0.9];
const COLOR_RANGE = [
  "#FFDF43", // < 65%
  "#84D24C", // 65–70%
  "#00B675", // 70–75%
  "#00908A", // 75–80%
  "#016587", // 80–85%
  "#2C376E", // 85–90%
  "#460049", // ≥ 90%
];

const colorScale = d3
  .scaleThreshold()
  .domain(COLOR_THRESHOLDS)
  .range(COLOR_RANGE);

export function districtMap(geojson, data, { onSelect, width = 480 } = {}) {
  const MAP_WIDTH = width;
  const MAP_HEIGHT = Math.round(width * (440 / 480));
  const byGeoid = new Map(data.map((d) => [d.geoid, d]));

  // Two-pass rendering: fills first, strokes second.
  //
  // Because SVG paints in document order, the stroke pass always renders on top
  // of every fill — so hover and selection borders are never occluded by a
  // neighboring district's fill polygon. No DOM raise() required.
  //
  // The stroke pass uses fill:"transparent" so the interior captures pointer
  // events (fill:"none" would only hit-test on the stroke line itself).
  const chart = Plot.plot({
    width: MAP_WIDTH,
    height: MAP_HEIGHT,
    marginTop: MARGIN,
    marginRight: MARGIN,
    marginBottom: MARGIN,
    marginLeft: MARGIN,
    projection: { type: "mercator", domain: geojson },
    marks: [
      // Pass 1 — fills only, no stroke
      Plot.geo(geojson.features, {
        fill: (f) => {
          const d = byGeoid.get(f.properties.GEOID);
          return d ? colorScale(+d.retention_rate) : "#ccc";
        },
        stroke: "none",
      }),
      // Pass 2 — strokes only, transparent fill for full-polygon hit testing
      Plot.geo(geojson.features, {
        fill: "transparent",
        stroke: DEFAULT_STROKE,
        strokeWidth: +DEFAULT_STROKE_WIDTH,
        cursor: "pointer",
      }),
    ],
  });

  // --- Interaction on the stroke-pass paths ---
  //
  // Plot renders marks in order: fill paths come first (indices 0..n-1),
  // stroke paths come second (indices n..2n-1). We attach all interaction to
  // the stroke paths — they are on top and capture events across the full polygon.
  const allPaths = Array.from(chart.querySelectorAll("path")).filter(
    (el) => !el.closest("defs"),
  );
  const n = geojson.features.length;
  const strokePaths = allPaths.slice(n);

  // Guarantee full-polygon hit testing on the transparent-fill stroke paths
  strokePaths.forEach((el) => {
    el.style.pointerEvents = "all";
  });

  // targetMap: maps each stroke path element → its datum for exact tooltip hit-testing
  const targetMap = new Map();

  let selectedEl = null;

  geojson.features.forEach((f, i) => {
    const el = strokePaths[i];
    if (!el) return;
    const geoid = f.properties.GEOID;
    const d = byGeoid.get(geoid);
    if (d) targetMap.set(el, d);

    el.addEventListener("mouseenter", () => {
      if (el !== selectedEl) {
        el.setAttribute("stroke", HOVER_STROKE);
        el.setAttribute("stroke-width", HOVER_STROKE_WIDTH);
      }
    });
    el.addEventListener("mouseleave", () => {
      if (el !== selectedEl) {
        el.setAttribute("stroke", DEFAULT_STROKE);
        el.setAttribute("stroke-width", DEFAULT_STROKE_WIDTH);
      }
    });
    el.addEventListener("click", () => {
      if (selectedEl && selectedEl !== el) {
        selectedEl.setAttribute("stroke", DEFAULT_STROKE);
        selectedEl.setAttribute("stroke-width", DEFAULT_STROKE_WIDTH);
      }
      if (el === selectedEl) {
        el.setAttribute("stroke", HOVER_STROKE);
        el.setAttribute("stroke-width", HOVER_STROKE_WIDTH);
        selectedEl = null;
        onSelect?.(null);
      } else {
        selectedEl = el;
        el.setAttribute("stroke", SELECTED_STROKE);
        el.setAttribute("stroke-width", SELECTED_STROKE_WIDTH);
        onSelect?.(geoid);
      }
    });
  });

  return attachTooltip(chart, null, {
    targetMap,
    hideOnBackground: true,
    format: (d) =>
      `<strong>${formatName(d.district_name)}</strong> ` +
      `retained ${(+d.retention_rate * 100).toFixed(1)}% of teachers from 2024–25 to 2025–26.`,
  });
}
