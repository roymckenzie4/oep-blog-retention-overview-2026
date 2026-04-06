import * as Plot from "../../_npm/@observablehq/plot@0.6.17/a96a6bbb.js";
import * as d3 from "../../_npm/d3@7.9.0/66d82917.js";
import { attachTooltip } from "./tooltip.169ffc84.js";

const PRE_YEARS = new Set([
  "2014-15",
  "2015-16",
  "2016-17",
  "2017-18",
  "2018-19",
  "2019-20",
]);
const RETAINED = new Set([
  "Stayer",
  "Mover - Same District",
  "Mover - New District",
]);

const ERA_COLORS = { pre: "#AAAAAA", post: "#4A6FA5" };
const REFERENCE_COLOR = "#B84A00";

export function retentionRateChart(data, { width = 640 } = {}) {
  // Sum the three retained categories by year → one retention rate per year
  const byYear = d3.rollup(
    data.filter((d) => RETAINED.has(d.category)),
    (rows) => d3.sum(rows, (r) => +r.value),
    (d) => d.schoolyear,
  );

  const points = Array.from(byYear, ([schoolyear, pct]) => ({
    schoolyear,
    pct,
    era: PRE_YEARS.has(schoolyear) ? "pre" : "post",
  })).sort((a, b) => a.schoolyear.localeCompare(b.schoolyear));

  const preAvg = d3.mean(
    points.filter((d) => d.era === "pre"),
    (d) => d.pct,
  );

  // Mid-segment points for direct line labels
  const prePoints = points.filter((d) => d.era === "pre");
  const postPoints = points.filter((d) => d.era === "post");
  const preMid = prePoints[Math.floor(prePoints.length / 2)];
  const postMid = postPoints[Math.floor(postPoints.length / 2)];

  const chart = Plot.plot({
    width,
    height: Math.round(width * 0.38),
    marginLeft: 60,
    marginBottom: width < 600 ? 60 : 40,
    marginTop: 20,
    style: {
      fontFamily: "Roboto, sans-serif",
      fontSize: "15px",
    },
    x: { label: null, tickSize: 0, tickRotate: width < 600 ? -30 : 0, type: "point" },
    y: {
      label: "Statewide Retention Rate",
      labelAnchor: "center",
      labelArrow: "none",
      domain: [80, 100],
      ticks: [80, 85, 90, 95, 100],
      tickFormat: (d) => d + "%",
      tickSize: 0,
    },
    color: {
      domain: ["pre", "post"],
      range: [ERA_COLORS.pre, ERA_COLORS.post],
    },
    marks: [
      // Grid lines — strokeOpacity: 1 overrides any theme inheritance
      Plot.gridY([80, 85, 90, 95, 100], {
        stroke: "#bbb",
        strokeWidth: 1,
        strokeOpacity: 1,
      }),
      // Hover rule — light dotted, clearly subordinate to the data
      Plot.ruleX(
        points,
        Plot.pointerX({
          x: "schoolyear",
          stroke: "#999",
          strokeWidth: 0.5,
          strokeDasharray: "3,3",
        }),
      ),
      // Pre-pandemic average reference line
      Plot.ruleY([preAvg], {
        stroke: REFERENCE_COLOR,
        strokeWidth: 1.5,
        strokeDasharray: "5,4",
      }),
      // Reference annotation — right side, above the dashed line
      Plot.text(
        [{ schoolyear: points[points.length - 1].schoolyear, pct: preAvg }],
        {
          x: "schoolyear",
          y: "pct",
          text: [`Pre-pandemic average: ${preAvg.toFixed(1)}%`],
          textAnchor: "end",
          dx: 20,
          dy: -8,
          fill: REFERENCE_COLOR,
          fontSize: 14,
        },
      ),
      // Era labels — pinned to top, manually positioned over the middle of each era
      Plot.text(
        [
          { schoolyear: "2016-17", pct: 84.5, label: "Pre-pandemic" },
          { schoolyear: "2023-24", pct: 84.5, label: "Post-pandemic" },
        ],
        {
          x: "schoolyear",
          y: "pct",
          text: "label",
          fill: (d) => (d.label === "Pre-pandemic" ? "#C0C0C0" : "#7BA3C8"),
          fontSize: 14,
        },
      ),
      // Two separate line segments
      Plot.line(points, {
        x: "schoolyear",
        y: "pct",
        stroke: "era",
        z: "era",
        strokeWidth: 2.5,
      }),
      // Dots — rendered last so they sit on top of everything
      Plot.dot(points, {
        x: "schoolyear",
        y: "pct",
        fill: "era",
        r: 5,
      }),
    ],
  });

  return attachTooltip(chart, points, {
    x: "schoolyear",
    format: (d) =>
      `<strong>${d.schoolyear}</strong><br>Retention Rate: ${d.pct.toFixed(1)}%`,
  });
}
