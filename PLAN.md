# Post 1: Retention Overview — Build Plan

## What's done

### Infrastructure
- Observable Framework initialized with `theme: "air"`, Roboto font via Google Fonts
- R data loader pattern working: `src/data/labor-market-outcomes.csv.R` reads real Arkansas
  teacher workforce transitions data from Box, computes retention percentages, outputs CSV
- Dev server running; GitHub Pages deploy not yet configured

### Chart 1: Stacked bar — retention categories over time (`src/index.md`)
- 100% stacked bar chart, 2014-15 through 2025-26, six categories
- Real data connected via R loader
- Custom color scale matching Josh's published report
- Right-side vertical legend (custom HTML — Plot.legend() can't do vertical layout natively)
- Hover-to-highlight interaction: hovering a bar segment or legend item fades all other
  categories. Uses Plot's `title` channel for element indexing + a dynamic CSS `<style>` block.
- **Known limitation**: no prose yet — page still says "This could be some blog post text!"

---

## What we've learned about Observable Framework

### What it's genuinely good at
- **Data loader pattern** is excellent. R scripts output JSON/CSV to stdout at build time;
  the browser never sees raw data or R code. This is the main reason to choose it over Svelte.
- **Reactive runtime** makes click/hover interactions that update displays clean to wire up,
  as long as you're working within Plot's built-in interaction model.
- **Plot** gets you 80% of the way to a publication-quality chart quickly. Good for exploration
  and for charts that don't need pixel-perfect custom layout.

### Where it fights you
- **Plot's legend** has no vertical layout option. We had to build a custom HTML legend.
  This is a real gap and means the legend is outside Plot's rendering, requiring manual
  coordination for interactions.
- **Custom hover interactions on Plot charts** require stepping outside Plot entirely.
  Plot 0.6 does not use D3's traditional `__data__` binding, so you cannot read datum
  from DOM elements in event handlers. Our working solution uses Plot's `title` channel
  to index elements, then a dynamic CSS `<style>` block to drive visual state.
- **SVG text elements** sit on top of bar rects and intercept mouse events unless handled.
- **Font sizes** in Plot SVG do not automatically match the page's CSS font size — must be
  set explicitly on the plot's `style` option.
- **Plot vs. raw D3**: for charts requiring very precise layout control, dropping down to
  raw D3 may be less painful than fighting Plot's constraints.

### The honest trade-off vs. Svelte
Svelte/LayerCake gives more layout control but requires building axis components from scratch.
Observable gives faster chart authoring and the data loader pattern, but custom interactions
require non-idiomatic workarounds. For OEP's use case (R analysts publishing interactive
work), Observable's data loader convenience likely wins — but expect to write some custom
JavaScript for anything beyond Plot's built-in interactions.

---

## Competing priorities / open questions

- **Narrative first**: charts should serve the story, not the other way around. Next step
  is writing prose before building more charts.

- **Component abstraction**: the hover-highlight pattern and custom legend are worth
  wrapping into reusable helper functions once the post is done. Goal: a future OEP
  researcher calls one function, not 30 lines of custom code.

- **OEP brand colors**: not yet defined for the web. Currently using Josh's ColorBrewer
  palette from the print report. Needs a decision before anything ships.

- **WordPress iframe embed**: the pattern (Observable Framework → GitHub Pages → iframe)
  is planned but not yet tested end-to-end. Worth a dry run before investing heavily
  in more charts.

- **Accessibility**: SVG charts have no screen-reader support. Known gap, worth addressing
  before public launch but not blocking development.

- **Responsiveness**: charts currently have fixed widths. Observable's built-in `width`
  reactive variable can make them responsive, but the custom legend layout complicates this.
  Needs a solution before WordPress embed is finalized.
