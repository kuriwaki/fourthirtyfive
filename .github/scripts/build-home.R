# Written by Codex

# Prepare the website homepage ----

# pkgdown reads Markdown rather than knitting README.Rmd itself. Keep the
# GitHub README static and generate a separate homepage with live map widgets.
dir.create("pkgdown", showWarnings = FALSE)
site_index <- file.path("pkgdown", "index.md")
map_token <- Sys.getenv("MAPBOX_PUBLIC_TOKEN")
unlink(file.path("pkgdown", "assets", "maps"), recursive = TRUE)

write_static_home <- function() {
  readme_lines <- readLines("README.md", warn = FALSE)
  fallback_lines <- sub(
    '<details class="map-fallback-details">',
    '<details class="map-fallback-details" open>',
    readme_lines, fixed = TRUE
  )
  writeLines(fallback_lines, site_index)
}

if (!nzchar(map_token)) {
  message(
    "MAPBOX_PUBLIC_TOKEN is not set; showing labeled fallback screenshots. ",
    "Add the repository Actions secret MAPBOX_PUBLIC_TOKEN to enable live maps."
  )
  write_static_home()
} else {
  if (!startsWith(map_token, "pk.")) {
    stop("MAPBOX_PUBLIC_TOKEN must be a public Mapbox token beginning with pk.")
  }
  withr::with_options(list(fourthirtyfive.website = TRUE), {
    # Render beside README.Rmd so figure paths remain relative to the package.
    site_markdown <- tempfile("README-site-", tmpdir = ".", fileext = ".md")
    rendered_home <- tryCatch(
      rmarkdown::render(
        "README.Rmd",
        output_format = rmarkdown::github_document(html_preview = FALSE),
        output_file = basename(site_markdown),
        envir = new.env(parent = globalenv()), quiet = TRUE
      ),
      error = function(error) {
        warning(
          "Interactive homepage rendering failed; showing fallback screenshots. ",
          conditionMessage(error),
          call. = FALSE
        )
        NULL
      }
    )
    if (is.null(rendered_home)) {
      unlink(site_markdown)
      unlink(file.path("pkgdown", "assets", "maps"), recursive = TRUE)
      write_static_home()
    } else if (!file.rename(site_markdown, site_index)) {
      stop("Could not move the rendered README to pkgdown/index.md.")
    }
  })
}
