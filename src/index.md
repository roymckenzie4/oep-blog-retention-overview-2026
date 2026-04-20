```js
const labor_market_outcomes = FileAttachment(
  "data/labor-market-outcomes.csv",
).csv();

const exiter_experience = FileAttachment("data/exiter-experience.csv").csv();

const district_retention = FileAttachment("data/district-retention.csv").csv();

const district_retention_2026 = FileAttachment(
  "data/district-retention-2026.json",
).json();

const ar_districts = FileAttachment("data/ar-school-districts.geojson").json();
```

# Arkansas Teacher Retention 2025-26: A New Normal

In [last year's post](https://oep.uark.edu/2024-25-arkansas-teacher-retention-statewide-stability-amid-ongoing-local-challenges/), we saw early signs that Arkansas teacher retention may have plateaued below pre-pandemic levels. This pattern is consistent with national trends — a [RAND survey](https://www.rand.org/pubs/research_reports/RRA4737-1.html) found that districts' reported rates of teacher retirements and resignations nearly doubled during the pandemic before only partially recovering. New data for the 2025-26 school year confirms this finding in Arkansas. For the second straight year, roughly <b>12.7 percent</b> of Arkansas teachers left the classroom - still almost <b>2 percentage points</b> above the typical pre-pandemic rate. This leveling-off is despite [high reported levels of teacher job satisfaction](https://oep.uark.edu/new-survey-results-show-arkansas-teachers-report-high-satisfaction-with-room-to-strengthen-support/) and early evidence that [LEARNS salary raises improved teacher retention](https://oep.uark.edu/raising-the-floor-early-evidence-suggests-learns-salary-increases-improved-teacher-retention/).

What's behind this plateau? In this blog post, we explore those components of the teacher labor market that are returning to normal - and one that is not.

## Retention Rates Are Still Below Pre-Pandemic Levels

In 2025-26, roughly 87 percent of Arkansas teachers returned to the classroom. This rate is unchanged from 2024-25 and remains over 1.5 percentage points below pre-pandemic levels. This raises a natural question: is higher teacher turnover the new normal for the state?

```js
import { retentionRateChart } from "./components/retention-rate-chart.js";
display(retentionRateChart(labor_market_outcomes, { width }));
```

To understand what's driving these patterns, we sort teachers by their employment decisions between the 2024-25 and 2025-26 school years:

- <span style="color: #053061; font-weight: bold;">Stayers</span> remained teaching in the same school(s);
- <span style="color: #2166AC; font-weight: bold;">Movers</span> transferred to a different school or district;
- <span style="color: #F4A582; font-weight: bold;">Switchers</span> moved to a non-teaching role within Arkansas public schools;
- <span style="color: #B2182B; font-weight: bold;">Exiters</span> left the Arkansas public school system entirely.

In 2025-26:

- <span style="color: #053061; font-weight: bold;">77.1 percent</span> of teachers were Stayers;
- <b>10.2 percent</b> of teachers were Movers who kept teaching but in a new school - <span style="color: #2166AC; font-weight: bold;"> 5.3 percent </span> within the same district and <span style="color: #92C5DE; font-weight: bold;">4.9 percent</span> in a new district.
- <span style="color: #F4A582; font-weight: bold;">3.5 percent</span> of teachers were Switchers;
- <b>9.1 percent</b> of teachers were Exiters - <span style="color: #B2182B; font-weight: bold;">6.4 percent</span> left the Arkansas public school workforce and <span style="color: #67001F; font-weight: bold;">2.7 percent</span> retired.

The statewide retention rate combines all Movers and Stayers, since both groups remain teaching in Arkansas public schools. But stability in this overall rate obscures key patterns on the ground.

```js
import { stackedBarChart } from "./components/stacked-bar-chart.js";

const RETENTION_CATEGORIES = [
  { label: "Stayer", color: "#053061", textColor: "white" },
  { label: "Mover - Same District", color: "#2166AC", textColor: "white" },
  { label: "Mover - New District", color: "#92C5DE", textColor: "black" },
  { label: "Switcher", color: "#F4A582", textColor: "black" },
  { label: "Exiter", color: "#B2182B", textColor: "white" },
  { label: "Retired", color: "#67001F", textColor: "white" },
];

display(
  stackedBarChart(labor_market_outcomes, RETENTION_CATEGORIES, { width }),
);
```

## Exits, Not Retirements

Teachers are exiting the Arkansas public school workforce at a higher rate than before the pandemic, but they're no more likely to retire. In 2025-26, only 2.7 percent of teachers retired. This mirrors last year's rate exactly and sits slightly below pre-pandemic levels.

```js
import { changeFromBaselineChart } from "./components/change-from-baseline-chart.js";
import * as d3 from "npm:d3";

// Pre-pandemic school years used as the baseline for change calculations
const PRE_PANDEMIC_YEARS = new Set([
  "2014-15",
  "2015-16",
  "2016-17",
  "2017-18",
  "2018-19",
  "2019-20",
]);

// Transforms raw labor-market-outcomes data into { x, category, change } rows
// for a change-from-baseline chart. Pre-pandemic years are averaged into a
// single "Pre-pandemic avg." baseline point (change = 0 by definition).
// Post-pandemic years show the pp delta from that baseline.
function computeBaselineDeltas(data, categoryLabels) {
  const filtered = data.filter((d) => categoryLabels.includes(d.category));

  // Per-category baseline: mean of pre-pandemic values
  const baselines = {};
  for (const label of categoryLabels) {
    const preRows = filtered.filter(
      (d) => d.category === label && PRE_PANDEMIC_YEARS.has(d.schoolyear),
    );
    baselines[label] = d3.mean(preRows, (d) => +d.value);
  }

  // Map rows to { x, category, change }, collapsing pre-pandemic years to one point
  const transformed = [];
  const seenBaseline = new Set();
  for (const row of [...filtered].sort((a, b) =>
    a.schoolyear.localeCompare(b.schoolyear),
  )) {
    if (PRE_PANDEMIC_YEARS.has(row.schoolyear)) {
      if (!seenBaseline.has(row.category)) {
        seenBaseline.add(row.category);
        transformed.push({
          x: "Pre-pandemic",
          category: row.category,
          change: 0,
        });
      }
    } else {
      transformed.push({
        x: row.schoolyear,
        category: row.category,
        change: +row.value - baselines[row.category],
      });
    }
  }
  return transformed;
}

const departureCategories = [
  { label: "Exiter", color: "#B2182B" },
  { label: "Retired", color: "#67001F" },
  { label: "Switcher", color: "#F4A582" },
];
const departureDelta = computeBaselineDeltas(
  labor_market_outcomes,
  departureCategories.map((c) => c.label),
);
display(
  changeFromBaselineChart(departureDelta, departureCategories, { width }),
);
```

Instead, exits among early- and mid-career teachers underlie increased turnover. This year, about 6.4 percent of teachers exited the Arkansas public school workforce. This is over 1 percentage point higher than before the pandemic - the same elevated rate we've seen for the past three years.

Over 70 percent of these non-retiree exiters had 10 or fewer years of teaching experience. Prior to the pandemic, teachers with 0 to 3 years of experience accounted for the largest share of exiters; in the last five years, more experienced teachers with 4 to 10 years of experience made up the highest percentage of these exits.

```js
const EXPERIENCE_CATEGORIES = [
  { label: "0-3 years", color: "#DEEBF7", textColor: "black" },
  { label: "4-10 years", color: "#9ECAE1", textColor: "black" },
  { label: "11-20 years", color: "#3182BD", textColor: "white" },
  { label: "20+ years", color: "#08519C", textColor: "white" },
];

// Collapse pre-pandemic years into a single averaged baseline bar,
// matching the visual convention used in the line chart above.
const experienceLabels = EXPERIENCE_CATEGORIES.map((c) => c.label);
const prePandemicAvg = experienceLabels.map((cat) => {
  const rows = exiter_experience.filter(
    (d) => PRE_PANDEMIC_YEARS.has(d.schoolyear) && d.category === cat,
  );
  const avg = d3.mean(rows, (d) => +d.value);
  return {
    schoolyear: "Pre-pandemic",
    category: cat,
    value: avg,
    label: avg.toFixed(1),
  };
});
const postPandemicYears = exiter_experience.filter(
  (d) => !PRE_PANDEMIC_YEARS.has(d.schoolyear),
);
const exiter_experience_rolled = [...prePandemicAvg, ...postPandemicYears];

display(
  stackedBarChart(exiter_experience_rolled, EXPERIENCE_CATEGORIES, {
    width,
    height: Math.round(width * 0.4),
    yLabel: "% of Non-Retiree Exiters",
    caption:
      "Each bar represents the total group of non-retiree exiters that year, broken down by years of teaching experience.",
  }),
);
```

While exits drive most of the decline in retention, they aren't the only factor. Switchers drive the remaining retention gap. In 2025-26, the rate of teachers switching to non-teaching public school roles dropped by 0.2 pp, inching back towards pre-pandemic levels. This decrease continues a slow but steady pattern of decline - the Switcher rate is now down 0.8 percentage points from its 2022-23 peak.

[Last year](https://oep.uark.edu/2024-25-arkansas-teacher-retention-statewide-stability-amid-ongoing-local-challenges/), we discussed how the January 2025 expiration of Federal ESSER (Elementary and Secondary School Emergency Relief) funds could lead to a dip in the Switcher rate, as some Arkansas districts may have used these funds for new non-teaching roles. That the Switcher rate remains elevated this year suggests some rigidity in districts' response to this expiration. Next year's data should reveal more of districts' adjustment to this funding loss.

## Teachers Are Staying Put

In 2025-26, a greater share of teachers remained in the same school than at any time in the last five years. The Stayer rate rose to 77.1 percent this year, up 0.8 percentage points from 2024-25 and almost 3 percentage points from the low-water mark of 2022-23.

```js
const retainedCategories = [
  { label: "Stayer", color: "#053061" },
  { label: "Mover - Same District", color: "#2166AC" },
  { label: "Mover - New District", color: "#92C5DE" },
];
const retainedDelta = computeBaselineDeltas(
  labor_market_outcomes,
  retainedCategories.map((c) => c.label),
);
display(changeFromBaselineChart(retainedDelta, retainedCategories, { width }));
```

As more teachers stayed, fewer moved to new districts. Only 4.9 percent of teachers taught in a new district this year, a 0.8 percentage point decrease from 2024-25. This means that even as statewide retention held steady, those teachers who were retained were more likely to stay in their own district - a sign of growing stability within schools.

## Geographic Shortage Area Districts Continue to Struggle

At the district level, retention recovery remains uneven. Despite improvements for some of the state's lowest-retention districts, most geographic shortage area districts still experience higher-than-average turnover.

The scatter plot below compares each district's average retention rate before the pandemic (2014-15 to 2019-20) against the three most recent years (2023-24 to 2025-26). Districts below the diagonal lag behind their pre-pandemic retention levels; districts above the diagonal have more than recovered. Districts highlighted in red were identified by the state as [high needs geographic shortage districts](https://docs.google.com/spreadsheets/d/1xnrhc6OGv_TY0lii191q3vys_eTs7RGt/edit?gid=1823429520#gid=1823429520) in 2025-26.

```js
import { districtScatterChart } from "./components/district-scatter-chart.js";
import { html } from "npm:htl";
const csvUrl = await FileAttachment("data/district-retention.csv").url();
display(
  districtScatterChart(district_retention, {
    width,
    caption: html`<a
      href="${csvUrl}"
      download="district-retention.csv"
      style="color: inherit;"
      >Download chart data (CSV)</a
    >`,
  }),
);
```

Most 2025-26 geographic shortage districts measured below-average levels of retention over the last three years. On average, these districts retained only 77.1 percent of teachers - roughly 4.5 pp less than the average district in the state. Most of these districts experienced high levels of turnover before the pandemic as well, and while some have experienced large improvements in retention, 40 out of the 64 shortage area districts have lower retention now than before the pandemic.

Below, you can review our updated interactive tool to examine how 2025-26 retention looks in your district.

```js
import { districtMap } from "./components/district-map.js";
import { districtCard } from "./components/district-card.js";
import { html } from "npm:htl";

const isWide = width >= 750;
const mapWidth = isWide ? Math.round(width * 0.52) : width;
const gridCols = isWide ? `${mapWidth}px 1fr` : "1fr";

const wrapper = html`<div
  style="
  display: grid;
  grid-template-columns: ${gridCols};
  grid-template-rows: auto 1fr;
  border: 3.5px solid #111;
  border-radius: 8px;
  overflow: hidden;
  box-sizing: border-box;
  width: 100%;
  font-family: Overpass, sans-serif;
"
>
  <div
    style="
    grid-column: 1 / -1;
    padding: 14px 18px 10px;
    font-size: 17px;
    font-weight: 700;
    color: #111;
  "
  >
    2025–26 Teacher Retention Rates by District
  </div>
  <div class="map-slot"></div>
  <div class="card-slot" style="box-sizing: border-box;"></div>
</div>`;

function updateCard(geoid) {
  const slot = wrapper.querySelector(".card-slot");
  slot.innerHTML = "";
  const d = geoid
    ? district_retention_2026.find((r) => r.geoid === geoid)
    : null;
  slot.appendChild(districtCard(d));
}

updateCard(null);

wrapper.querySelector(".map-slot").appendChild(
  districtMap(ar_districts, district_retention_2026, {
    onSelect: updateCard,
    width: mapWidth,
  }),
);

display(wrapper);
```

## What This Plateau Means

Several years of post-pandemic data now reveal a new normal for Arkansas schools: lower retention rates, driven by higher exits among early- and mid-career teachers. But the most consistent pattern is that the teacher labor market continues to evolve. Teachers stay more and move less, switcher rates decline, and districts recover at uneven speeds.

Facing these challenges, Arkansas enacted major policies to bolster the teaching workforce - and they are showing signs of success. Early evidence suggests that [LEARNS salary increases](https://edre.uark.edu/_resources/pdf/changes-in-teacher-salaries-under-the-arkansas-learns-act-research-brief_nov2_final_rb2023-02.pdf) have [improved teacher retention](https://oep.uark.edu/raising-the-floor-early-evidence-suggests-learns-salary-increases-improved-teacher-retention/), particularly in rural and high-needs districts. Arkansas teachers are reporting [high levels of job satisfaction and success](https://oep.uark.edu/new-survey-results-show-arkansas-teachers-report-high-satisfaction-with-room-to-strengthen-support/).

But if teacher retention continues to plateau, Arkansas may need even more focused policies to address shortages. To inform these efforts, we will continue to examine the routes that teachers take into and out of the state's public schools. Better understanding these pathways can help us identify specific levers to help districts ensure they retain the teachers necessary to educate Arkansas students.
