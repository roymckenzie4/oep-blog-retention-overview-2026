import { html } from "npm:htl";

/**
 * Attaches a custom HTML tooltip to an Observable Plot chart.
 *
 * When only `x` is provided, snaps to the nearest point along the X axis
 * (good for line charts). When both `x` and `y` are provided, uses 2D
 * Euclidean distance and hides the tooltip beyond `maxDist` pixels (good
 * for scatter plots).
 *
 * @param {SVGElement} chart    - The Plot SVG element
 * @param {Array}      points   - The data array used to build the chart
 * @param {Object}     opts
 *   @param {string}   opts.x        - Field name for the x channel
 *   @param {string}   [opts.y]      - Field name for the y channel (enables 2D mode)
 *   @param {Function} opts.format   - (datum) => HTML string for tooltip content
 *   @param {number}   [opts.maxDist=40] - In 2D mode, hide tooltip beyond this pixel distance
 *
 * @returns {HTMLElement} A container wrapping the chart and tooltip, ready to display()
 *
 * Usage (1D, line chart):
 *   return attachTooltip(chart, points, {
 *     x: "schoolyear",
 *     format: (d) => `<strong>${d.schoolyear}</strong><br>Retention Rate: ${d.pct.toFixed(1)}%`,
 *   });
 *
 * Usage (2D, scatter chart):
 *   return attachTooltip(chart, points, {
 *     x: "trough",
 *     y: "recent",
 *     format: (d) => `<strong>${d.district_name}</strong>`,
 *   });
 */
export function attachTooltip(chart, points, { x, y = null, format, maxDist = 40, defaultTipY = 28 }) {
  const xScale = chart.scale("x");
  const yScale = y ? chart.scale("y") : null;

  // Pre-compute pixel positions for each data point
  const positioned = points.map((d) => ({
    datum: d,
    px: xScale.apply(d[x]),
    py: yScale ? yScale.apply(d[y]) : null,
  }));

  function findNearest(mouseX, mouseY) {
    if (yScale) {
      // 2D mode: Euclidean distance
      return positioned.reduce((prev, curr) => {
        const dPrev = (prev.px - mouseX) ** 2 + (prev.py - mouseY) ** 2;
        const dCurr = (curr.px - mouseX) ** 2 + (curr.py - mouseY) ** 2;
        return dCurr < dPrev ? curr : prev;
      });
    } else {
      // 1D mode: X-axis distance only
      return positioned.reduce((prev, curr) =>
        Math.abs(curr.px - mouseX) < Math.abs(prev.px - mouseX) ? curr : prev
      );
    }
  }

  const tip = html`<div style="
    position: absolute;
    background: white;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 8px 12px;
    font-family: 'Roboto', sans-serif;
    font-size: 13px;
    line-height: 1.6;
    white-space: nowrap;
    pointer-events: none;
    box-shadow: 0 2px 8px rgba(0,0,0,0.12);
    display: none;
  "></div>`;

  const container = html`<div style="position: relative; display: inline-block;">
    ${chart}${tip}
  </div>`;

  chart.addEventListener("pointermove", (event) => {
    const rect = chart.getBoundingClientRect();
    const mouseX = event.clientX - rect.left;
    const mouseY = event.clientY - rect.top;
    const nearest = findNearest(mouseX, mouseY);

    // In 2D mode, hide the tooltip when the cursor is too far from any point
    if (yScale) {
      const dist = Math.sqrt((nearest.px - mouseX) ** 2 + (nearest.py - mouseY) ** 2);
      if (dist > maxDist) {
        tip.style.display = "none";
        return;
      }
    }

    tip.innerHTML = format(nearest.datum);
    tip.style.display = "block";

    // Horizontal: default right of cursor, flip left if near right edge
    const chartWidth = chart.offsetWidth;
    const tipWidth = tip.offsetWidth;
    let left = nearest.px + 14;
    if (left + tipWidth > chartWidth - 12) left = nearest.px - tipWidth - 14;
    tip.style.left = `${left}px`;

    // Vertical: above data point (both modes), flip below if it would clip the top
    const tipY = nearest.py ?? defaultTipY;
    let top = tipY - tip.offsetHeight - 10;
    if (top < 8) top = tipY + 10;
    tip.style.top = `${top}px`;
  });

  chart.addEventListener("pointerleave", () => {
    tip.style.display = "none";
  });

  return container;
}
