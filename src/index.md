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

display(
  Plot.plot({
    width: 700,
    height: 600,
    marginLeft: 60,
    marginBottom: 50,
    x: { label: null, tickRotate: -35, type: "band" },
    y: { label: "Share of Teachers (%)", domain: [0, 100] },
    color: {
      domain: categories.map((c) => c.label),
      range: ["#053061", "#2166AC", "#92C5DE", "#F4A582", "#B2182B", "#67001F"],
      legend: true,
    },
    marks: [
      Plot.barY(labor_market_outcomes, {
        x: "schoolyear",
        y: "value",
        fill: "category",
        order: categories.map((c) => c.label),
        tip: {
          pointerSize: 0,
          textPadding: 6,
          position: "y2",

          fill: "#111827", // slightly cooler dark (slate)
          fillOpacity: 0.95,
          stroke: "#334155",
          strokeWidth: 1,
          pathFilter: null,

          fontFamily: "system-ui, -apple-system, sans-serif",
          fontSize: 12.5,
          fontWeight: 500,
          lineHeight: 1.75,
          lineWidth: 28,
        },
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
          dy: 0, // centered
          fontSize: 10,
          fill: (d) =>
            d.category === "Switcher" || d.category === "Mover - New District"
              ? "black"
              : "white",
        }),
      ),
    ],
  }),
);
```
