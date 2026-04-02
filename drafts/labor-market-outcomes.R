# prep for labor-market-outcomes.csv.R Observable Framework data loader
#
# Data loader reads teacher workforce transitions data, computes labor force outcome
# percentages by school year, and writes CSV to stdout.
#
# here we also produce draft versions of all graphs using this data

library(data.table)
library(dplyr)
library(tidyr)
library(stringr)

# --- Configuration ---
# When running locally, this should point to Box/OneDrive copy.
# TODO: Update this path to wherever the data lives in your environment.
# OPEN QUESTION: how to set this with environment variable? Or do we need to?
data_path <- Sys.getenv(
  "TEACHER_LM_DATA",
  unset = "/Users/roymckenzie/Library/CloudStorage/Box-Box/0 - Arkansas Projects/Projects/Teacher Pipeline/Teacher Retention/0_data/Classroom and Inclusion SPED Teachers/teacher_workforce_transitions_classroom and inclusion SPED_12-18-25.csv" # nolint
)

# --- Helper ---
clean_names <- function(df) {
  df %>% setNames(tolower(gsub("[ _.\\\\/]", "", names(.)))) # nolint
}

# --- Load and prep data ---
teacher_lm <- fread(
  data_path,
  colClasses = "character",
  na.strings = c("", "NA")
) |>
  clean_names() |>
  mutate(fiscalyear = as.integer(fiscalyear))

# --- Compute labor force outcomes for prior-year teachers ---
graph_data <- teacher_lm %>%
  filter(fiscalyear > 2014) %>%
  filter(lagteacher == TRUE) %>%
  mutate(
    lfexiterretired = (lfoutcome == "Exiter" & lfexiterretired == 1),
    lfexiterother = (lfoutcome == "Exiter" & lfexiterretired == 0),
    lfmovernewdistrict = (lfoutcome == "Mover" & lfmovernewdistrict == 1),
    lfmoversamedistrict = (lfoutcome == "Mover" & lfmovernewdistrict == 0),
    lfswitcher = (lfoutcome == "Switcher"),
    lfstayer = (lfoutcome == "Stayer")
  ) %>%
  group_by(fiscalyear) %>%
  summarise(
    Retired = mean(lfexiterretired, na.rm = TRUE),
    Exiter = mean(lfexiterother, na.rm = TRUE),
    Switcher = mean(lfswitcher, na.rm = TRUE),
    `Mover - New District` = mean(lfmovernewdistrict, na.rm = TRUE),
    `Mover - Same District` = mean(lfmoversamedistrict, na.rm = TRUE),
    Stayer = mean(lfstayer, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    schoolyear = paste0(fiscalyear - 1, "-", substr(fiscalyear, 3, 4))
  ) %>%
  select(-fiscalyear) %>%
  pivot_longer(
    cols = c(
      Retired,
      Exiter,
      Switcher,
      `Mover - New District`,
      `Mover - Same District`,
      Stayer
    ),
    names_to = "category",
    values_to = "value"
  ) %>%
  mutate(
    value = value * 100,
    label = sprintf("%.1f", value)
  ) %>%
  arrange(schoolyear, category)

# now, draft versions of the graphs

library(ggplot2)

graph_data <- graph_data %>%
  mutate(
    category = factor(
      category,
      levels = c(
        "Stayer",
        "Mover - Same District",
        "Mover - New District",
        "Switcher",
        "Exiter",
        "Retired"
      ),
      ordered = TRUE
    )
  )

ggplot(graph_data, aes(x = schoolyear, y = value, fill = category)) +
  geom_col(position = position_stack(reverse = TRUE)) + # Stacked bar chart
  # # Add white text labels for Stayer segment
  # geom_text(aes(label = label_1),
  #           position = position_stack(vjust = 0.5),
  #           size = 4, color = "white") +
  # # Add black text labels for Mover and Switcher segments
  # geom_text(aes(label = label_2),
  #           position = position_stack(vjust = 0.5),
  #           size = 4) +
  # coord_cartesian(ylim = c(0, 1)) +  # Set y-axis limits to 0-100%
  # scale_y_continuous(labels = scales::percent) +  # Format y-axis as percentages
  # Use Blue-Red diverging palette with yellow for switcher
  scale_fill_manual(
    values = c(
      "Retired" = "#67001F", # Dark burgundy red
      "Exiter" = "#B2182B", # Medium red
      "Switcher" = "#F4A582", # Warm peachy tone (transitional)
      "Mover - New District" = "#92C5DE", # Light blue
      "Mover - Same District" = "#2166AC", # Medium blue
      "Stayer" = "#053061" # Dark navy blue
    )
  ) +
  xlab(element_blank()) + # Remove x-axis label
  ylab("% of Prior-Year Teachers") +
  labs(fill = "Labor Force Outcome") +
  theme_minimal() +
  theme(
    text = element_text(size = 16),
    legend.position = "right",
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 14, color = "black"),
    legend.key = element_blank(), # Remove box around legend items
    legend.key.size = unit(0.8, "cm"),
    axis.text = element_text(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1) # Angle x-axis labels for readability
  )

ggsave(
  "draft_plots/labor_market_outcomes_plot_draft.svg",
  dpi = 600,
  width = 13,
  height = 6,
  units = "in"
)

graph_data_2 <- graph_data %>%
  filter(
    category %in% c("Stayer", "Mover - New District", "Mover - Same District")
  ) %>%
  group_by(schoolyear) %>%
  summarize(
    pct = sum(value)
  ) %>%
  ungroup() %>%
  mutate(
    era = case_when(
      schoolyear %in%
        c(
          "2014-15",
          "2015-16",
          "2016-17",
          "2017-18",
          "2018-19",
          "2019-20"
        ) ~ "pre",
      TRUE ~ "post"
    )
  )


pp_avg <- graph_data_2 %>%
  filter(era == "pre") %>%
  summarize(pct = mean(pct))

ggplot(graph_data_2, aes(x = schoolyear, y = pct, group = era, color = era)) +
  geom_point(size = 4) +
  geom_line(size = 1.25) +
  geom_hline(yintercept = pp_avg$pct, color = "red", size = 1, linetype = 4) +
  scale_color_manual(values = c("purple", "grey"), guide = "none") +
  coord_cartesian(ylim = c(80, 100)) +
  xlab(element_blank()) + # Remove x-axis label
  ylab("Retention Rate") +
  theme_minimal() +
  theme(
    text = element_text(size = 16),
    legend.position = "right",
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 14, color = "black"),
    legend.key = element_blank(), # Remove box around legend items
    legend.key.size = unit(0.8, "cm"),
    axis.text = element_text(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1) # Angle x-axis labels for readability
  )

ggsave(
  "draft_plots/retention_rate_plot_draft.svg",
  dpi = 600,
  width = 13,
  height = 6,
  units = "in"
)

# plots of changes from baseline - retained teachers

graph_data_3 <- graph_data %>%
  filter(
    category %in%
      c("Stayer", "Mover - New District", "Mover - Same District")
  ) %>%
  mutate(
    schoolyear = case_when(
      schoolyear %in%
        c(
          "2014-15",
          "2015-16",
          "2016-17",
          "2017-18",
          "2018-19",
          "2019-20"
        ) ~ "2014-15 to 2019-20",
      TRUE ~ schoolyear
    )
  ) %>%
  group_by(category, schoolyear) %>%
  summarize(
    pct = mean(value)
  ) %>%
  ungroup() %>%
  group_by(category) %>%
  mutate(
    change_from_base = pct - pct[schoolyear == "2014-15 to 2019-20"]
  )

ggplot(
  graph_data_3,
  aes(
    x = schoolyear,
    y = change_from_base,
    group = category,
    color = category,
    linetype = category
  )
) +
  geom_point() +
  geom_line() +
  xlab(element_blank()) + # Remove x-axis label
  ylab("Change from Pre-Pandemic Average (pp)") +
  scale_color_manual(
    name = "",
    values = c(
      "Mover - New District" = "#92C5DE", # Light blue
      "Mover - Same District" = "#2166AC", # Medium blue
      "Stayer" = "#053061" # Dark navy blue)
    )
  ) +
  scale_linetype_discrete(name = "") +
  coord_cartesian(ylim = c(-5, 5)) +
  geom_hline(yintercept = 0) +
  theme_minimal() +
  theme(
    text = element_text(size = 16),
    legend.position = "right",
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 14, color = "black"),
    legend.key = element_blank(), # Remove box around legend items
    legend.key.size = unit(0.8, "cm"),
    axis.text = element_text(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1) # Angle x-axis labels for readability
  )

ggsave(
  "draft_plots/stayers_movers_change_from_base_plot_draft.svg",
  dpi = 600,
  width = 13,
  height = 6,
  units = "in"
)

# plot of changes from baseline - lost teachers

graph_data_4 <- graph_data %>%
  filter(
    !(category %in%
      c("Stayer", "Mover - New District", "Mover - Same District"))
  ) %>%
  mutate(
    schoolyear = case_when(
      schoolyear %in%
        c(
          "2014-15",
          "2015-16",
          "2016-17",
          "2017-18",
          "2018-19",
          "2019-20"
        ) ~ "2014-15 to 2019-20",
      TRUE ~ schoolyear
    )
  ) %>%
  group_by(category, schoolyear) %>%
  summarize(
    pct = mean(value)
  ) %>%
  ungroup() %>%
  group_by(category) %>%
  mutate(
    change_from_base = pct - pct[schoolyear == "2014-15 to 2019-20"]
  )

ggplot(
  graph_data_4,
  aes(
    x = schoolyear,
    y = change_from_base,
    group = category,
    color = category,
    linetype = category
  )
) +
  geom_point() +
  geom_line() +
  xlab(element_blank()) + # Remove x-axis label
  ylab("Change from Pre-Pandemic Average (pp)") +
  scale_color_manual(
    name = "",
    values = c(
      "Retired" = "#67001F", # Dark burgundy red
      "Exiter" = "#B2182B", # Medium red
      "Switcher" = "#F4A582" # Warm peachy tone (transitional)
    )
  ) +
  scale_linetype_discrete(name = "") +
  coord_cartesian(ylim = c(-5, 5)) +
  geom_hline(yintercept = 0) +
  theme_minimal() +
  theme(
    text = element_text(size = 16),
    legend.position = "right",
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 14, color = "black"),
    legend.key = element_blank(), # Remove box around legend items
    legend.key.size = unit(0.8, "cm"),
    axis.text = element_text(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1) # Angle x-axis labels for readability
  )

ggsave(
  "draft_plots/switcher_exiter_retired_change_from_base_plot_draft.svg",
  dpi = 600,
  width = 13,
  height = 6,
  units = "in"
)
