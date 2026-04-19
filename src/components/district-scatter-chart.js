import * as Plot from "npm:@observablehq/plot";
import * as d3 from "npm:d3";
import { html } from "npm:htl";
import { attachTooltip } from "./tooltip.js";
import { formatName, makeLegend } from "./utils.js";
import { CHART_STYLE, GRID_COLOR } from "./theme.js";

const SHORTAGE_COLOR = "#C0392B";
const NOT_SHORTAGE_COLOR = "#888";
const DIAGONAL_COLOR = "#bbb";
const STATE_AVG_COLOR = "#4A6FA5";

export function districtScatterChart(data, { width = 640 } = {}) {
  // Retention rates come in as proportions (0-1); convert to percentages for display
  const points = data
    .map((d) => ({
      ...d,
      prepandemic: +d.avg_retention_prepandemic * 100,
      recent: +d.avg_retention_recent * 100,
    }))
    .filter((d) => !isNaN(d.prepandemic) && !isNaN(d.recent));

  const stateAvg = d3.mean(points, (d) => d.recent);

  const chart = Plot.plot({
    width,
    height: Math.round(width * 0.52),
    marginLeft: 55,
    marginBottom: 55,
    marginTop: 24,
    style: CHART_STYLE,
    x: {
      label: "Avg. Retention Rate, Pre-pandemic (2014–15 to 2019–20)",
      labelAnchor: "center",
      labelArrow: "none",
      domain: [55, 100],
      tickFormat: (d) => d + "%",
      tickSize: 0,
    },
    y: {
      label: "Avg. Retention Rate, 2023–24 to 2025–26",
      labelAnchor: "center",
      labelArrow: "none",
      domain: [55, 100],
      tickFormat: (d) => d + "%",
      tickSize: 0,
    },
    marks: [
      Plot.gridX({ stroke: GRID_COLOR, strokeWidth: 1 }),
      Plot.gridY({ stroke: GRID_COLOR, strokeWidth: 1 }),

      // Diagonal parity line — districts above have improved vs. pre-pandemic, below have declined
      Plot.line(
        [
          { x: 55, y: 55 },
          { x: 100, y: 100 },
        ],
        {
          x: "x",
          y: "y",
          stroke: DIAGONAL_COLOR,
          strokeWidth: 1.5,
          strokeDasharray: "4,4",
          strokeOpacity: 0.4,
        },
      ),

      // State average recent retention — horizontal reference
      Plot.ruleY([stateAvg], {
        stroke: STATE_AVG_COLOR,
        strokeWidth: 1.5,
        strokeDasharray: "5,4",
      }),
      Plot.text([{ x: 56, y: stateAvg }], {
        x: "x",
        y: "y",
        text: [`State average: ${stateAvg.toFixed(1)}%`],
        textAnchor: "start",
        dy: -8,
        fill: STATE_AVG_COLOR,
        fontSize: 13,
      }),

      // District dots
      Plot.dot(points, {
        x: "prepandemic",
        y: "recent",
        fill: (d) =>
          d.shortage_status === "Shortage"
            ? SHORTAGE_COLOR
            : NOT_SHORTAGE_COLOR,
        r: 5,
        fillOpacity: (d) => (d.shortage_status === "Shortage" ? 0.7 : 0.65),
        stroke: "white",
        strokeWidth: 0.5,
      }),
      // Hover highlight — same color as base dot, larger, yellow stroke
      Plot.dot(
        points,
        Plot.pointer({
          x: "prepandemic",
          y: "recent",
          fill: (d) =>
            d.shortage_status === "Shortage"
              ? SHORTAGE_COLOR
              : NOT_SHORTAGE_COLOR,
          stroke: "#FFD700",
          strokeWidth: 2,
          r: 8,
        }),
      ),
    ],
  });

  // Prevent Plot.pointer's built-in click-to-stick behavior by intercepting
  // pointerdown in the capture phase before it reaches Plot's listener.
  chart.addEventListener(
    "pointerdown",
    (e) => e.stopImmediatePropagation(),
    true,
  );

  const container = attachTooltip(chart, points, {
    x: "prepandemic",
    y: "recent",
    format: (d) => {
      const change = d.recent - d.prepandemic;
      const sign = change >= 0 ? "+" : "−";
      const color = change >= 0 ? "#2e7d32" : "#c0392b";
      return `
        <strong>${formatName(d.district_name)}</strong><br>
        Pre-pandemic avg.: ${d.prepandemic.toFixed(1)}%<br>
        2023–24 to 2025–26: ${d.recent.toFixed(1)}%<br>
        <span style="color:${color}; font-weight:600">
          Change: ${sign}${Math.abs(change).toFixed(1)} pp
        </span>
      `;
    },
  });

  const legend = makeLegend([
    { label: "Not a Shortage District", color: NOT_SHORTAGE_COLOR },
    { label: "Shortage District (2025–26)", color: SHORTAGE_COLOR },
  ]);

  return html`<div>${container}${legend}</div>`;
}
