# Written by Codex

# Interactive district maps ----
# Set MAPBOX_PUBLIC_TOKEN before opening a map.
# See help("mapbox-setup", package = "fourthirtyfive") for setup and usage limits.
# Run examples individually after loading fourthirtyfive.

# Compare one district across two or three Congresses ----
# cd_mapbox("FL-05", congress = c(113, 115))
# cd_mapbox("FL-10", congress = c(113, 114, 115))
# cd_mapbox("NC-13", congress = c(115, 117))

# Compare Tennessee statewide and highlight only Memphis ----
# cd_mapbox(state = "TN", congress = c(119, 120), cities = "Memphis")
# cd_mapbox(state = "TN", congress = c(119, 120), cities = "Memphis",
#         zoom_to_cities = TRUE)

# Highlight at most two incorporated cities ----
# cd_mapbox(state = "UT", congress = 120, cities = c("Salt Lake City", "Provo"))
# cd_mapbox("OH-13", congress = 120, cities = c("Akron", "Canton"),
#         zoom_to_cities = TRUE)
