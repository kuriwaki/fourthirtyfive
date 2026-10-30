# Written by Codex

# Generate website icons from the package logo ----

logo <- magick::image_read("man/figures/logo.png")
favicon_dir <- file.path("pkgdown", "favicon")
dir.create(favicon_dir, recursive = TRUE, showWarnings = FALSE)

icon_sizes <- c(
  "favicon-16x16.png" = 16L,
  "favicon-32x32.png" = 32L,
  "favicon-96x96.png" = 96L,
  "apple-touch-icon.png" = 180L,
  "web-app-manifest-192x192.png" = 192L,
  "web-app-manifest-512x512.png" = 512L
)

resize_logo <- function(size) {
  magick::image_resize(logo, glue::glue("{size}x{size}"))
}

for (filename in names(icon_sizes)) {
  magick::image_write(
    resize_logo(icon_sizes[[filename]]),
    path = file.path(favicon_dir, filename),
    format = "png"
  )
}

ico_images <- magick::image_join(lapply(c(16L, 32L, 48L), resize_logo))
magick::image_write(
  ico_images,
  path = file.path(favicon_dir, "favicon.ico"),
  format = "ico"
)

# Embed the raster logo so the SVG favicon has no external dependencies.
svg_image <- openssl::base64_encode(
  magick::image_write(resize_logo(192L), format = "png")
)
writeLines(
  glue::glue(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 192">',
    '<image width="192" height="192" href="data:image/png;base64,{svg_image}"/>',
    '</svg>'
  ),
  file.path(favicon_dir, "favicon.svg")
)

manifest <- list(
  name = "fourthirtyfive",
  short_name = "fourthirtyfive",
  icons = lapply(c(192L, 512L), function(size) {
    list(
      src = glue::glue("web-app-manifest-{size}x{size}.png"),
      sizes = glue::glue("{size}x{size}"),
      type = "image/png"
    )
  })
)
jsonlite::write_json(
  manifest,
  file.path(favicon_dir, "site.webmanifest"),
  auto_unbox = TRUE,
  pretty = TRUE
)
