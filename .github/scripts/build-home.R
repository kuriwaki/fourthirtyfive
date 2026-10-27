# Written by Codex

# Prepare the website homepage ----

# pkgdown reads Markdown rather than knitting README.Rmd itself. Keep the
# GitHub README static and generate a separate homepage with live map widgets.
dir.create("pkgdown", showWarnings = FALSE)
site_index <- file.path("pkgdown", "index.md")
map_token <- Sys.getenv("MAPBOX_PUBLIC_TOKEN")

if (!nzchar(map_token)) {
  message(
    "MAPBOX_PUBLIC_TOKEN is not set; using README links to the live maps. ",
    "Add the repository Actions secret MAPBOX_PUBLIC_TOKEN to enable live maps."
  )
  file.copy("README.md", site_index, overwrite = TRUE)
} else {
  if (!startsWith(map_token, "pk.")) {
    stop("MAPBOX_PUBLIC_TOKEN must be a public Mapbox token beginning with pk.")
  }
  withr::with_options(list(fourthirtyfive.website = TRUE), {
    # Render beside README.Rmd so figure paths remain relative to the package.
    site_markdown <- tempfile("README-site-", tmpdir = ".", fileext = ".md")
    rmarkdown::render(
      "README.Rmd",
      output_format = rmarkdown::github_document(html_preview = FALSE),
      output_file = basename(site_markdown),
      envir = new.env(parent = globalenv()), quiet = TRUE
    )
    if (!file.rename(site_markdown, site_index)) {
      stop("Could not move the rendered README to pkgdown/index.md.")
    }
  })
}
