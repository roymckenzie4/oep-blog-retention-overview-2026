import * as Plot from "../../_npm/@observablehq/plot@0.6.17/a96a6bbb.js";
import { html } from "../../_npm/htl@0.3.1/72f4716c.js";
import { attachTooltip } from "./tooltip.169ffc84.js";

/**
 * Renders a multi-line chart showing change from a pre-computed baseline.
 *
 * The caller is responsible for the data transformation — computing baselines,
 * collapsing baseline years into a single averaged point, and subtracting.
 * This component is a pure renderer.
 *
 * @param {Array}  data        - Rows of { x, category, change }, where x is the
 *                               display label (e.g. "Pre-pandemic", "2021-22")
 *                               and change is the pp delta from baseline.
 * @param {Array}  categories  - [{ label, color }] in display order. Drives the
 *                               color scale, line order, and legend.
 * @param {Object} options
 *   @param {Array}  options.yDomain  - [min, max] for y-axis. Default: [-5, 5]
 *   @param {string} options.yLabel   - Y-axis label. Default: "Change from pre-pandemic avg. (pp)"
 *   @param {number} options.width    - Chart width in px. Default: 640
 */
export function changeFromBaselineChart(data, categories, options = {}) {
  const {
    yDomain = [-5, 5],
    yLabel = "Change from pre-pandemic avg. (pp)",
    width = 640,
  } = options;

  // x domain: baseline point first, then post-period years in chronological order
  const postYears = [
    ...new Set(data.filter((d) => d.x !== "Pre-pandemic").map((d) => d.x)),
  ].sort();
  const xDomain = ["Pre-pandemic", ...postYears];

  // Color lookup for tooltip rows
  const colorMap = Object.fromEntries(categories.map((c) => [c.label, c.color]));

  // Category order for the tooltip: sorted by each category's change value in the
  // final year, descending — so tooltip rows match the visual top-to-bottom order
  // of the lines at the right edge of the chart.
  const lastX = xDomain[xDomain.length - 1];
  const categoriesByLastYear = [...categories].sort((a, b) => {
    const aVal = data.find((d) => d.x === lastX && d.category === a.label)?.change ?? -Infinity;
    const bVal = data.find((d) => d.x === lastX && d.category === b.label)?.change ?? -Infinity;
    return bVal - aVal;
  });

  // One synthetic point per x value for tooltip snapping.
  // Each carries all category changes for that x so the format callback
  // can render a multi-row comparison without touching multiple data points.
  const xPoints = xDomain.map((xVal) => ({
    x: xVal,
    changes: Object.fromEntries(
      categories.map((c) => [
        c.label,
        data.find((d) => d.x === xVal && d.category === c.label)?.change ?? null,
      ]),
    ),
  }));

  const chart = Plot.plot({
    width,
    height: Math.round(width * 0.40),
    marginLeft: 75,
    marginRight: 20,
    marginBottom: width < 700 ? 70 : 50,
    marginTop: 20,
    style: {
      fontFamily: "Roboto, sans-serif",
      fontSize: "15px",
    },
    x: {
      label: null,
      tickSize: 0,
      tickRotate: width < 700 ? -30 : 0,
      type: "point",
      domain: xDomain,
    },
    y: {
      label: yLabel,
      labelAnchor: "center",
      labelArrow: "none",
      domain: yDomain,
      tickFormat: (d) => (d > 0 ? "+" : "") + d + " pp",
      tickSize: 0,
    },
    color: {
      domain: categories.map((c) => c.label),
      range: categories.map((c) => c.color),
    },
    marks: [
      // Gridlines — light, subordinate to data
      Plot.gridY({
        stroke: "#ddd",
        strokeWidth: 1,
        strokeOpacity: 1,
      }),
      // Zero reference line — heavier, the visual anchor of the chart
      Plot.ruleY([0], {
        stroke: "#555",
        strokeWidth: 2,
      }),
      // Hover crosshair — snaps to x positions, always visible when mouse is over chart
      Plot.ruleX(
        xPoints,
        Plot.pointerX({
          x: "x",
          stroke: "#999",
          strokeWidth: 0.5,
          strokeDasharray: "3,3",
          maxRadius: Infinity,
        }),
      ),
      // Lines, one per category
      Plot.line(data, {
        x: "x",
        y: "change",
        stroke: "category",
        z: "category",
        strokeWidth: 2.5,
      }),
      // Dots on top of lines
      Plot.dot(data, {
        x: "x",
        y: "change",
        fill: "category",
        r: 4,
      }),
    ],
  });

  const container = attachTooltip(chart, xPoints, {
    x: "x",
    defaultTipY: 5,
    format: (d) => {
      const rows = categoriesByLastYear
        .filter((c) => d.changes[c.label] !== null)
        .map((c) => {
          const val = d.changes[c.label];
          const sign = val > 0 ? "+" : "";
          return `<span style="color:${colorMap[c.label]}; font-weight:600;">${c.label}</span>: ${sign}${val.toFixed(1)} pp`;
        })
        .join("<br>");
      return `<strong>${d.x}</strong><br>${rows}`;
    },
  });

  const legendEl = html`<div
    style="
      padding: 6px 0 2px;
      font-family: 'Roboto', sans-serif;
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      gap: 8px 20px;
    "
  >
    ${categories.map(
      (c) =>
        html`<div style="display:flex; align-items:center; gap:8px;">
          <div
            style="width:24px; height:3px; background:${c.color}; border-radius:2px; flex-shrink:0;"
          ></div>
          <span style="font-size:13px; color:#444;">${c.label}</span>
        </div>`,
    )}
  </div>`;

  return html`<div>${container}${legendEl}</div>`;
}
