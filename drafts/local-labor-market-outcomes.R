# prep for local-labor-market-outcomes.csv.R Observable Framework data loader
#
# Data loader reads teacher workforce transitions data, computes labor force outcome
# percentages by school year, per district, and writes CSV to stdout.
#
# here we also produce draft versions of all graphs using this data

library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)

# --- Configuration ---
# When running locally, this should point to Box/OneDrive copy.
# TODO: Update this path to wherever the data lives in your environment.
# OPEN QUESTION: how to set this with environment variable? Or do we need to?
data_path <- Sys.getenv(
  "TEACHER_LM_DATA",
  unset = "/Users/roymckenzie/Library/CloudStorage/Box-Box/0 - Arkansas Projects/Projects/Teacher Pipeline/Teacher Retention/0_data/Classroom and Inclusion SPED Teachers/teacher_workforce_transitions_classroom and inclusion SPED_12-18-25.csv" # nolint
)

# --- Load and prep data ---
teacher_lm <- fread(
  data_path,
  colClasses = "character",
  na.strings = c("", "NA")
) |>
  janitor::clean_names() |>
  mutate(fiscal_year = as.integer(fiscal_year))


# --- Create district by district data ----

calculate_retention_rates <- function(year, teacher_lm) {
  teachers_year_before <- teacher_lm %>%
    filter(teacher == TRUE) %>%
    filter(fiscal_year == year - 1) %>%
    select(
      research_id,
      districtlea_before = districtlea,
      jobcode_before = jobcode
    )

  teachers_year <- teacher_lm %>%
    filter(fiscal_year == year) %>%
    left_join(teachers_year_before, by = "research_id")

  retention_rates <- teachers_year %>%
    filter(lf_outcome != "New") %>%
    group_by(districtlea_before) %>%
    summarise(
      teachers_before = n(),
      stayers = sum(
        lf_outcome == "Stayer" |
          #(lf_outcome == "Mover" & lf_mover_district == FALSE),
          (lf_outcome == "Mover" & lf_mover_same_district == 1),
        na.rm = TRUE
      ),
      movers_out = sum(
        lf_outcome == "Mover" & lf_mover_new_district == 1, # lf_mover_district == TRUE,
        na.rm = TRUE
      ),
      switchers = sum(lf_outcome == "Switcher", na.rm = TRUE),
      switchers_out = sum(
        lf_outcome == "Switcher" & lf_switcher_new_district == 1,
        na.rm = TRUE
      ),
      exiters = sum(
        lf_outcome == "Exiter" & lf_exiter_not_retired == 1,
        na.rm = TRUE
      ),
      retirements = sum(
        lf_outcome == "Exiter" & lf_exiter_retired == 1,
        na.rm = TRUE
      )
    ) %>%
    ungroup() %>%
    mutate(
      # updated logic: all switchers count as not retained
      fiscal_year = year,
      n_retained = teachers_before -
        exiters -
        retirements -
        movers_out -
        switchers,
      # this is the same as the above (stayers is stayers + movers in district here)
      n_retained_check = stayers,
      retention_rate = n_retained / teachers_before
    ) %>%
    rename(districtlea = districtlea_before)
}

years <- c(2022, 2023, 2024, 2025, 2026)

district_retention_all <- map(
  years,
  ~ calculate_retention_rates(.x, teacher_lm)
) |>
  list_rbind()

# check - who is missing data
missing_years <- district_retention_all |>
  group_by(districtlea) |>
  summarize(years = list(fiscal_year)) |>
  mutate(n_years = lengths(years)) |>
  rowwise() |>
  mutate(years = paste0(unlist(years, recursive = FALSE), collapse = ", ")) |>
  filter(n_years < 5)

# drop them for now and prep data for scatter plot

district_scatter <- district_retention_all |>
  group_by(districtlea) |>
  filter(n() == 5) |>
  ungroup() |>
  mutate(
    period = if_else(fiscal_year %in% c(2022, 2023), "trough", "recent")
  ) |>
  group_by(districtlea, period) |>
  summarize(
    avg_retention = mean(retention_rate),
    n_teachers_avg = mean(teachers_before),
    n_years = n(),
    .groups = "drop"
  ) |>
  pivot_wider(
    names_from = period,
    values_from = c(avg_retention, n_years, n_teachers_avg)
  ) %>%
  mutate(
    districtlea_num = as.numeric(districtlea)
  )

# --- prep map data -----

# load shape file from tigris package
ar_districts <- tigris::school_districts(state = "AR")

# load crosswalk from ccd to get the correct lea codes - save as csv to save time
# on future re-runs
# cxwalk = educationdata::get_education_data(
#   level = "school-districts",
#   source = "ccd",
#   topic = "directory",
#   filters = list(year = 2023, fips = 5)
# )
# readr::write_csv(cxwalk, "raw_data/educationdata_arkansas_2023")

cxwalk <- readr::read_csv("raw_data/educationdata_arkansas_2023.csv") %>%
  select(
    "GEOID" = leaid,
    "district_lea" = state_leaid,
    urban_centric_locale,
    county_code,
    county_name,
    congress_district_id,
    agency_type,
    enrollment,
    teachers_total_fte
  ) %>%
  mutate(
    district_lea = as.numeric(gsub("AR-", "", district_lea))
  )

# join crosswalk to shapefiles - this just provides a corrected lea
ar_districts = ar_districts |>
  left_join(cxwalk)


# create geocoded data
ar_district_w_data <- ar_districts |>
  left_join(district_scatter, by = c("district_lea" = "districtlea_num")) %>%
  mutate(
    category = case_when(
      districtlea %in%
        c(
          "5201000",
          "4702000",
          "4801000",
          "5204000",
          "4802000",
          "1305000",
          "0201000",
          "5106000",
          "0901000",
          "0101000",
          "2104000",
          "1802000",
          "7001000",
          "2002000",
          "6201000",
          "0203000",
          "5403000",
          "0601000",
          "2903000",
          "7003000",
          "5440700",
          "3704000",
          "3904000",
          "1804000",
          "5604000",
          "5404000",
          "2105000",
          "2203000",
          "6002000",
          "4713000",
          "0407000",
          "3505000",
          "4003000",
          "0104000",
          "4605000",
          "5605000",
          "0602000",
          "3509000",
          "4701000",
          "3201000",
          "3212000",
          "3502000",
          "3306000",
          "6004000",
          "0506000"
        ) ~ "Shortage 2021-22 or 2022-23",
      TRUE ~ "Not Shortage"
    )
  )

#

# now try the graphs

ggplot(
  ar_district_w_data,
  aes(
    x = avg_retention_trough,
    y = avg_retention_recent,
    color = category
  )
) +
  ylab("Average Retention 2024 to 2026") +
  xlab("Average Retention 2022 to 2023") +
  geom_abline(slope = 1, intercept = 0, color = "grey", linetype = 2) +
  scale_color_manual(
    name = "",
    values = c("Not Shortage" = "black", "Shortage 2021-22 or 2022-23" = "red")
  ) +
  geom_hline(
    yintercept = mean(ar_district_w_data$avg_retention_recent),
    color = "#7d9edd",
    size = 1.1,
    alpha = .8
  ) +
  geom_point() +
  coord_cartesian(xlim = c(.5, 1), ylim = c(.5, 1)) +
  theme_minimal() +
  theme(
    text = element_text(size = 16),
    legend.position = "bottom",
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 14, color = "black"),
    legend.key = element_blank(), # Remove box around legend items
    legend.key.size = unit(0.8, "cm"),
    axis.text = element_text(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1) # Angle x-axis labels for readability
  )

ggsave(
  "draft_plots/change_in_retention_plot_draft.svg",
  dpi = 600,
  width = 8,
  height = 8,
  units = "in"
)

ggplot(
  ar_district_w_data,
  aes(
    x = avg_retention_trough,
    y = avg_retention_recent
  )
) +
  geom_point()
#scale_y_continuous(limits = c(-.5, .5))

ar_district_w_data %>%
  filter(abs(avg_retention_recent - avg_retention_trough) <= .2) %>%
  mutate(
    # qtile = case_when(
    #   avg_retention_trough <= .7650 ~ 1,
    #   avg_retention_trough <= .8147 ~ 2,
    #   avg_retention_trough <= .8567 ~ 3,
    #   TRUE ~ 4
    # )
    qtile = category
  ) %>%
  group_by(qtile) %>%
  summarize(
    n = n(),
    avg_retention_trough = mean(avg_retention_trough),
    avg_retention_recent = mean(avg_retention_recent),
    change = avg_retention_recent - avg_retention_trough
  ) %>%
  pivot_longer(
    cols = starts_with("avg"),
    names_to = "period",
    names_prefix = "avg_retention_"
  ) %>%
  ggplot(aes(x = period, y = value, group = qtile, color = qtile)) +
  geom_point() +
  scale_x_discrete(limits = rev) +
  geom_line()


tile_scatter <- district_scatter %>%
  filter(
    avg_retention_trough < .95 &
      avg_retention_trough > .6 &
      avg_retention_recent - avg_retention_trough > -.2
  ) %>%
  mutate(qtile = ntile(avg_retention_trough, n = 4))
agg <- tile_scatter %>%
  group_by(qtile) %>%
  summarize(
    min_pre = min(avg_retention_trough),
    max_pre = max(avg_retention_trough),
    avg_retention_change = mean(avg_retention_recent - avg_retention_trough)
  )

ggplot() +
  geom_point(
    data = tile_scatter,
    aes(
      x = avg_retention_trough,
      y = avg_retention_recent - avg_retention_trough,
      color = factor(qtile)
    ),
    alpha = .3
  ) +
  geom_segment(
    data = agg,
    aes(
      x = min_pre,
      y = avg_retention_change,
      xend = max_pre,
      yend = avg_retention_change,
      color = factor(qtile)
    ),
    size = 1.5,
    alpha = .8
  ) +
  geom_hline(yintercept = 0)


ggplot(
  district_retention_all %>%
    group_by(districtlea) %>%
    filter(min(retention_rate) > .5), # & min(teachers_before) > 40),
  aes(
    x = fiscal_year,
    y = retention_rate,
    #color = districtlea,
  ),
) +
  geom_line(alpha = .2, aes(group = districtlea)) +
  theme(legend.position = "none") +
  geom_smooth(
    method = "lm",
    aes(
      x = fiscal_year,
      y = retention_rate,
      #color = districtlea,
      #group = districtlea
    ),
  ) +
  scale_y_continuous(limits = c(.5, 1))
