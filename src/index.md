```js
const labor_market_outcomes = FileAttachment(
  "data/labor-market-outcomes.csv",
).csv();
```

# Arkansas Teacher Retention 2025-26: A New Normal

In [last year's post](https://oep.uark.edu/2024-25-arkansas-teacher-retention-statewide-stability-amid-ongoing-local-challenges/), we highlighted early signs that Arkansas teacher retention recovery may have plateaued below pre-pandemic levels. New data for the 2025-26 school year confirms this. For the second straight year, approximately 12.7 percent of Arkansas teachers left the classroom, a rate that continues to sit will above the roughly 11 percent rate typical before the pandemic.

What's behind this plateau? Below, we explore the parts of the picture which are returning to normal - and one that is not.

## Retention Rates Remain Low in 2025-26

After an initial rebound from the 2022-23 low point, Arkansas's teacher retention rate has leveled off - still about 1.5 pp below pre-pandemic levels. In 2025-26, roughly 87.3 percent of teachers returned to the classroom. This rate is effectively unchanged from 2024-25, raising the question of whether this is the new normal for retention in the state.

![](images/draft_plots/retention_rate_plot_draft.svg)

To understand what's behind these rates, we sort teachers based on their employment decisions between the 2024-25 to 2025-26 school years:

- Stayers remained teaching in the same school(s);
- Movers transferred to a different school or district;
- Switchers moved to a non-teaching role within Arkansas public schools;
- Exiters left the Arkansas public school system entirely.

In 2025-26:

- 77.1 percent of teachers were Stayers;
- 10.2 percent of teachers were Movers who remained teaching in a new school - 5.3 percent within the same district and 4.9 percent in a new district;
- 3.5 percent of teachers were Switchers;
- 9.1 percent of teachers were Exiters - 6.4 percent left the Arkansas public school workforce and 2.7 percent retired.

![](images/draft_plots/labor_market_outcomes_plot_draft.svg)

The overall retention rate of 87.3 percent counts both Movers and Stayers, since teachers in both remained teaching in Arkansas public schools in 2025-26. But the stability in this overall rate hides a few important stories of what's happening on the ground.

## Exits, Not Retirements

Retirements are not driving the decline in retention rates. In 2025-26, approximately 2.7 percent of teachers retired. This mirrors last year's rate exactly, and sits slightly below pre-pandemic levels.

![](images/draft_plots/switcher_exiter_retired_change_from_base_plot_draft.svg)

Instead, exits among early- and mid-career teachers are likely keeping teacher retention rates low. This year, roughly 6.4 percent of teachers exited the workforce for non-retirement reasons. This remains over 1 pp higher than before the pandemic, and shows no decline from the past three years.

The remaining retention gap is driven by teachers switching to non-teaching roles within Arkansas public schools. In 2025-26, the Switcher rate declined by .2 pp, inching back towards pre-pandemic levels. This change continues a slow but steady pattern of decline - this rate is now down .8 percentage points since its 2022-23 peak.

Last year, we discussed how the January 2025 expiration of Federal ESSER (Elementary and Secondary School Emergency Relief) funds could lead to declines in the Switcher rate, as many Arkansas districts funded additional non-teaching roles using these funds. That Switcher rates remain elevated this year suggests some rigidity in districts' response to this expiration.

## Teachers Are Staying Put

In 2025-26, a larger proportion of teachers remained in the same school than at any time in the last five years. The Stayer rate rose to 77.1 percent this year, up .8 pp from 2024-25 and almost 3 pp from the low-water mark of 2022-23.

![](images/draft_plots/stayers_movers_change_from_base_plot_draft.svg)

As more teachers stayed, fewer moved to new districts. Only 4.9 percent of teachers taught in a new district this year, a .8 pp decrease from 2024-25. This means that even as statewide retention held steady, the teachers who stayed were more likely to stay in their own district - a sign of growing stability within schools.

## Geographic Shortage Area Districts Continue to Struggle

At the district level, retention recovery remains uneven. Despite increases in local retention for some of the state's lowest-retention districts, most shortage area districts continue to experience below average retention.

The scatter plot below shows the district-level change in average retention from the low-point years of 2021-22 and 2022-23 versus the three years of recovery since. Districts highlighted in red were identified by the state as Tier I Geographic Shortage Areas in either [2021-22](https://static.ark.org/eeuploads/adhe-financial/21-22_Final_Geographical_Shortage_Area_List_10.5.21.pdf) or [2022-23](https://sams.adhe.edu/File/22-23%20Geographical%20Teacher%20Shortage%20Area%20List%208.23.22.pdf).

![](images/draft_plots/change_in_retention_plot_draft.svg)

Only four of the original shortage area districts reached above-average retention over the last three years. Among the shortage area districts with a prior retention rate below 75 percent, some gained significantly, other declined sharply, but none were able to catch up with the state average retention rate in the recent period.

Below, you can review our updated interactive tool to examine how 2025-26 retention looks in your district.

![Tool will go here]()

## What This Plateau Means

We now have several years of post-pandemic data that reveal a new normal for Arkansas schools: lower retention rates, driven by higher exit rates among early- and mid-career teachers. But this surface-level stability hides how the teacher labor market continues to evolve. Teachers are staying more and moving less. District-level variation is wide. To understand the teacher labor market in Arkansas more fully, we need to examine who is entering and exiting the workforce, where they're coming from, and where they're heading.

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
      title: (d) => d.category, // writes category into a <title> child on each rect
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
        title: (d) => d.category, // same for text labels
      }),
    ),
  ],
});

// Read the <title> child to get each element's category, store as a data
// attribute, then remove <title> so the browser doesn't show native tooltips.
for (const el of chart.querySelectorAll("rect, text")) {
  const titleEl = el.querySelector("title");
  if (titleEl) {
    el.dataset.category = titleEl.textContent;
    titleEl.remove();
  }
}

// A single <style> block drives the fade via CSS — no per-element DOM loops.
// CSS transitions make the fade smooth automatically.
const fadeStyle = html`<style></style>`;

function highlight(category) {
  // css adds lower opacity to all the items not tagged with data-category equal to the hovered category
  fadeStyle.textContent = category
    ? `
    svg rect[data-category]:not([data-category="${category}"]) { opacity: 0.15; transition: opacity 0.2s; }
    svg text[data-category]:not([data-category="${category}"]) { opacity: 0.15; transition: opacity 0.2s; }
    div[data-category]:not([data-category="${category}"]) { opacity: 0.4; transition: opacity 0.2s; }
    div[data-category="${category}"] span { font-weight: 700; }
  `
    : "";
}

chart.addEventListener("mouseover", (e) => {
  highlight(e.target.closest("[data-category]")?.dataset.category ?? null);
});
chart.addEventListener("mouseleave", () => highlight(null));

const legendEl = html`<div
  style="padding-top:52px; font-family:'Roboto',sans-serif; display:flex; flex-direction:column; gap:10px; min-width:160px; user-select:none;"
>
  <div style="font-size:15px; font-weight:600; color:#333; margin-bottom:2px;">
    Labor Force Outcome
  </div>
  ${colorScale.domain.map(
    (label, i) =>
      html`<div
        data-category="${label}"
        style="display:flex; align-items:center; gap:10px; cursor:default;"
        onmouseover=${() => highlight(label)}
        onmouseout=${() => highlight(null)}
      >
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
  html`<div style="display:flex; align-items:flex-start; gap:16px;">
    ${fadeStyle} ${chart} ${legendEl}
  </div>`,
);
```
