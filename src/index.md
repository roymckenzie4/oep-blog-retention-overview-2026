# Teacher Retention in Arkansas

```js
const labor_market_outcomes = FileAttachment(
  "data/labor-market-outcomes.csv",
).csv();
```

This could be some blog post text!

```js
const categories = [
  { key: "stayer", label: "Stayer" },
  { key: "mover_same", label: "Mover - Same District" },
  { key: "mover_new", label: "Mover - New District" },
  { key: "switcher", label: "Switcher" },
  { key: "exiter", label: "Exiter" },
  { key: "retired", label: "Retired" },
];

const colorScale = {
  domain: categories.map((c) => c.label),
  range: ["#053061", "#2166AC", "#92C5DE", "#F4A582", "#B2182B", "#67001F"],
};

const chart = Plot.plot({
  width: 800,
  height: 600,
  marginLeft: 60,
  marginBottom: 60,
  style: { fontFamily: "Roboto, sans-serif", fontSize: "14px" },
  x: { label: null, tickRotate: -35, type: "band", tickSize: 0 },
  y: {
    label: "% of Prior-Year Teachers",
    labelAnchor: "center",
    anchor: "left",
    labelArrow: "none",
    domain: [0, 100],
    ticks: [0, 25, 50, 75, 100],
    tickFormat: (d) => d + "%",
  },
  color: colorScale,
  marks: [
    Plot.barY(labor_market_outcomes, {
      x: "schoolyear",
      y: "value",
      fill: "category",
      order: categories.map((c) => c.label),
      tip: { fontFamily: "Roboto, sans-serif", fontSize: 14 },
      title: (d) => {
        const v = Number(d.value);
        const labelMap = {
          Stayer: `${v.toFixed(1)}% teach in same school.`,
          Switcher: `${v.toFixed(1)}% switch roles within districts.`,
          "Mover - Same District": `${v.toFixed(1)}% move schools within district.`,
          "Mover - New District": `${v.toFixed(1)}% move schools between districts.`,
          Exiter: `${v.toFixed(1)}% exit the Arkansas education workforce.`,
          Retired: `${v.toFixed(1)}% retire from teaching.`,
        };
        return `${d.category} (${d.schoolyear})\n• ${labelMap[d.category] ?? `${v.toFixed(1)}%`}`;
      },
    }),
    Plot.text(
      labor_market_outcomes,
      Plot.stackY({
        x: "schoolyear",
        y: "value",
        z: "category",
        order: categories.map((c) => c.label),
        text: (d) => `${(+d.value).toFixed(1)}`,
        fontSize: 12,
        fill: (d) =>
          d.category === "Switcher" || d.category === "Mover - New District"
            ? "black"
            : "white",
      }),
    ),
  ],
});

// Custom vertical legend — Plot.legend() can't do vertical layout natively
const legend = html`<div
  style="
  padding-top: 52px;
  font-family: 'Roboto', sans-serif;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-width: 160px;
"
>
  <div style="font-size:15px; font-weight:600; color:#333; margin-bottom:2px;">
    Labor Force Outcome
  </div>
  ${colorScale.domain.map(
    (label, i) =>
      html`<div style="display:flex; align-items:center; gap:10px;">
        <div
          style="width:18px; height:18px; background:${colorScale.range[
            i
          ]}; flex-shrink:0; border-radius:2px;"
        ></div>
        <span style="font-size:15px; color:#222;">${label}</span>
      </div>`,
  )}
</div>`;

display(
  html`<div style="display:flex; align-items:flex-start; gap:16px;>
    ${chart} ${legend}
  </div>`,
);
```
