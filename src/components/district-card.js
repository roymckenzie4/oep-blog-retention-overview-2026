import * as d3 from "npm:d3";
import { html } from "npm:htl";
import { formatName } from "./utils.js";

// Colors matching the retention-bar-chart.js palette exactly
const COLORS = {
  stayer: "#053061",
  mover: "#92C5DE",
  switcher: "#F4A582",
  exiter: "#B2182B",
  retiree: "#67001F",
};

const DOTS_PER_ROW = 20;
const TOTAL_DOTS = 100; // always 5 complete rows of 20
const DOT_SIZE = 14; // px, diameter
const DOT_GAP = 3; // px, gap between dots


function pct(count, total) {
  return Math.round((count / total) * 100);
}

// Computes per-category dot counts.
// If teachers_before <= TOTAL_DOTS: use exact counts (total dots = teachers_before).
// If teachers_before > TOTAL_DOTS: scale proportionally to TOTAL_DOTS, distributing
// rounding remainders to categories with the largest fractional parts.
function scaleDots(data) {
  const categories = [
    { color: COLORS.stayer, count: +data.stayers },
    { color: COLORS.mover, count: +data.movers_new_district },
    { color: COLORS.switcher, count: +data.switchers },
    { color: COLORS.exiter, count: +data.exiters },
    { color: COLORS.retiree, count: +data.retirees },
  ];

  const total = +data.teachers_before;
  if (total <= 0) return categories.map((c) => ({ ...c, dots: 0 }));

  // Small districts: show one dot per actual teacher
  if (total <= TOTAL_DOTS) {
    return categories.map((c) => ({ ...c, dots: c.count }));
  }

  // Large districts: scale to exactly TOTAL_DOTS with rounding fix
  const scaled = categories.map((c) => ({
    ...c,
    dots: Math.floor((c.count / total) * TOTAL_DOTS),
    frac: ((c.count / total) * TOTAL_DOTS) % 1,
  }));
  const remainder = TOTAL_DOTS - scaled.reduce((s, c) => s + c.dots, 0);
  [...scaled]
    .sort((a, b) => b.frac - a.frac)
    .slice(0, remainder)
    .forEach((c) => { c.dots += 1; });

  return scaled;
}

// Renders the dot grid as an SVG DOM element using D3.
// htl can embed DOM elements directly in template literals; SVG strings cannot
// be injected via ${{ innerHTML }} because htl sanitizes that for security.
function renderDotGrid(data) {
  const dotCategories = scaleDots(data);
  const dotColors = dotCategories.flatMap(({ color, dots }) =>
    Array.from({ length: dots }, () => color)
  );

  const r = DOT_SIZE / 2;
  const step = DOT_SIZE + DOT_GAP;
  const totalDots = dotColors.length; // may be < TOTAL_DOTS for small districts
  const rows = Math.ceil(totalDots / DOTS_PER_ROW);
  const svgW = DOTS_PER_ROW * step - DOT_GAP;
  const svgH = rows * step - DOT_GAP;

  const svg = d3
    .create("svg")
    .attr("width", svgW)
    .attr("height", svgH)
    .style("display", "block");

  dotColors.forEach((color, i) => {
    const col = i % DOTS_PER_ROW;
    const row = Math.floor(i / DOTS_PER_ROW);
    svg
      .append("circle")
      .attr("cx", col * step + r)
      .attr("cy", row * step + r)
      .attr("r", r)
      .attr("fill", color);
  });

  return svg.node();
}

export function districtCard(data) {
  if (!data) {
    return html`<div
      style="
        font-family: Roboto, sans-serif;
        color: #888;
        font-size: 14px;
        font-style: italic;
        padding: 16px;
        line-height: 1.6;
      "
    >
      Click a district on the map to see details.
    </div>`;
  }

  const {
    district_name,
    teachers_before,
    teachers_current,
    stayers,
    movers_new_district,
    switchers,
    exiters,
    retirees,
    retention_rate,
  } = data;

  const name = formatName(district_name);
  const retentionPct = (+retention_rate * 100).toFixed(1);
  const netChange =
    teachers_current != null ? +teachers_current - +teachers_before : null;
  const newTeachers =
    teachers_current != null
      ? +teachers_current - +stayers
      : null;
  const netSign = netChange > 0 ? "+" : netChange < 0 ? "−" : "";
  const netColor = netChange > 0 ? "#2e7d32" : netChange < 0 ? "#c0392b" : "#222";

  const leavers = [
    {
      label: `${movers_new_district} (${pct(movers_new_district, teachers_before)}%) moved to a new district`,
      color: COLORS.mover,
    },
    {
      label: `${switchers} (${pct(switchers, teachers_before)}%) switched to non-teaching roles`,
      color: COLORS.switcher,
    },
    {
      label: `${exiters} (${pct(exiters, teachers_before)}%) exited the teaching workforce`,
      color: COLORS.exiter,
    },
    {
      label: `${retirees} (${pct(retirees, teachers_before)}%) retired`,
      color: COLORS.retiree,
    },
  ];

  // DOM element — htl embeds this directly (no innerHTML injection)
  const dotGrid = renderDotGrid(data);

  return html`<div
    style="
      font-family: Roboto, sans-serif;
      color: #222;
      padding: 14px 16px;
      font-size: 13px;
    "
  >
    <div
      style="font-size: 17px; font-weight: 700; margin-bottom: 10px; line-height: 1.3;"
    >
      ${name}
    </div>

    <div style="margin-bottom: 12px; line-height: 1.8;">
      <div><strong>Teachers 2024–25:</strong> ${teachers_before}</div>
      <div>
        <strong>Teachers 2025–26:</strong>
        ${teachers_current != null ? teachers_current : "—"}
      </div>
    </div>

    <p style="margin: 0 0 8px 0; line-height: 1.55;">
      Out of <strong>${teachers_before}</strong> teachers in 2024–25,
      <strong style="color: ${COLORS.stayer}">${stayers}</strong> stayed in the
      district, a retention rate of
      <strong style="color: ${COLORS.stayer}">${retentionPct}%</strong>. Of
      those that left:
    </p>

    <ul
      style="
        margin: 0 0 10px 0;
        padding-left: 0;
        list-style: none;
        line-height: 1.85;
      "
    >
      ${leavers.map(
        (l) =>
          html`<li style="color: ${l.color}; font-weight: 600;">
            &bull; ${l.label}
          </li>`
      )}
    </ul>

    ${netChange != null
      ? html`<p style="margin: 0 0 12px 0; line-height: 1.55;">
          With <strong>${newTeachers}</strong> new teachers joining the district,
          this makes a net change of
          <strong style="color: ${netColor}"
            >${netSign}${Math.abs(netChange)}</strong
          >
          teachers.
        </p>`
      : html`<span></span>`}

    <p style="margin: 0 0 6px 0; color: #555; font-size: 12px;">
      These dots represent the teachers following each pathway:
    </p>

    ${dotGrid}
  </div>`;
}
