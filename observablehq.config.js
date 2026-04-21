// See https://observablehq.com/framework/config for documentation.
export default {
  // The app’s title; used in the sidebar and webpage titles.
  title: "Teacher Retention in Arkansas",

  // The pages and sections in the sidebar. If you don’t specify this option,
  // all pages will be listed in alphabetical order. Listing pages explicitly
  // lets you organize them into sections and have unlisted pages.
  // pages: [
  //   {
  //     name: "Examples",
  //     pages: [
  //       {name: "Dashboard", path: "/example-dashboard"},
  //       {name: "Report", path: "/example-report"}
  //     ]
  //   }
  // ],

  // Content to add to the head of the page, e.g. for a favicon:
  head: `
    <link rel="icon" href="observable.png" type="image/png" sizes="32x32">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Overpass:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
      :root {
        --sans-serif: "Overpass", sans-serif;
        --serif: "Overpass", sans-serif;
      }
      main {
        max-width: 950px !important;
        margin-left: auto;
        margin-right: auto;
      }
      /* Override the air theme's built-in prose column width */
      main p,
      main h1, main h2, main h3, main h4, main h5, main h6,
      main ul, main ol, main li, main blockquote,
      main .observablehq, main .observablehq--block {
        max-width: none !important;
      }
      /* When embedded in WordPress iframe: remove all padding/margins */
      html.iframe-embed #observablehq-center {
        margin: 0 !important;
      }
    </style>
  <script>
    // Run immediately (before load) so CSS takes effect before first paint
    if (window.self !== window.top) {
      document.documentElement.classList.add("iframe-embed");
    }
    function reportHeight() {
      window.parent.postMessage(
        { type: "setHeight", height: document.documentElement.scrollHeight },
        "*"
      );
    }
    window.addEventListener("load", function() {
      if (window.self !== window.top) {
        const title = document.querySelector("h1");
        if (title) title.style.display = "none";
        const center = document.getElementById("observablehq-center");
        if (center) center.style.margin = "0";
        const main = document.querySelector("main");
        if (main) { main.style.maxWidth = "none"; main.style.margin = "0"; }
      }
      reportHeight();
      new ResizeObserver(reportHeight).observe(document.body);
    });
  </script>
`,

  // The path to the source root.
  root: "src",

  theme: "air", // clean light theme — good for WordPress iframe embedding
  sidebar: false, // no navigation sidebar — single-page post, cleaner for iframe embedding

  // Some additional configuration options and their defaults:
  // theme: "default", // try "light", "dark", "slate", etc.
  // header: "", // what to show in the header (HTML)
  footer: "", // what to show in the footer (HTML)
  // sidebar: true, // whether to show the sidebar
  toc: false, // whether to show the table of contents
  // pager: true, // whether to show previous & next links in the footer
  // output: "dist", // path to the output root for build
  // search: true, // activate search
  // linkify: true, // convert URLs in Markdown to links
  // typographer: false, // smart quotes and other typographic improvements
  // preserveExtension: false, // drop .html from URLs
  // preserveIndex: false, // drop /index from URLs
};
