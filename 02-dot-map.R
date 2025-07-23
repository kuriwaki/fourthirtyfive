# Load libraries ----
library(tidyverse)
library(ggplot2)
# library(ggforce)

# To plot shp_dot_data.R ----

shp_dot_2005 |>
  ggplot() +
  geom_sf(color = "darkblue", size = 1) +
  theme_minimal()

# can also use geom_circle in ggforce(), but need to set constant radius to keep
# circle sizes the same
