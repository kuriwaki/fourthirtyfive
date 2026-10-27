# Written by Codex

#' Set up Mapbox for interactive district maps
#'
#' Mapbox supplies the viewer's basemap. Census geography downloads are separate
#' from Mapbox usage. These instructions and limits were verified on
#' **October 25, 2026**; consult the linked official pages for current details.
#'
#' @name mapbox-setup
#'
#' @section Account and token:
#' Create a [Mapbox account](https://account.mapbox.com/auth/signup/), verify your
#' email, and copy your public token from the
#' [Access Tokens page](https://console.mapbox.com/account/access-tokens/).
#' A public token begins with `pk.`. The provided token can be used for local
#' experimentation.
#'
#' @section R setup:
#' Install the optional `mapgl` package. Add the following line to your user
#' `.Renviron` file, replacing the placeholder with your own token:
#' \preformatted{MAPBOX_PUBLIC_TOKEN="pk.YOUR_PUBLIC_TOKEN"}
#' Restart R afterward. Check `nzchar(Sys.getenv("MAPBOX_PUBLIC_TOKEN"))`:
#' `TRUE` confirms presence without printing the token. If available,
#' `usethis::edit_r_environ()` opens the file; this helper is optional. See the
#' [mapgl setup guide](https://walker-data.com/mapgl/articles/getting-started.html).
#'
#' Public tokens are visible in rendered browser widgets. For production, use a
#' dedicated public token with the necessary read scopes, including `styles:read`
#' and `fonts:read`, and appropriate URL restrictions. The default public token
#' cannot have URL restrictions. Restricted development tokens must allow
#' `localhost`; Mapbox recommends a separate, more permissive development token.
#' See [token management](https://docs.mapbox.com/accounts/guides/tokens/).
#'
#' @section Package website on GitHub Pages:
#' The website workflow renders the interactive README examples when the
#' repository has an Actions secret named `MAPBOX_PUBLIC_TOKEN`. On GitHub, open
#' **Settings > Secrets and variables > Actions > New repository secret**. Use
#' `MAPBOX_PUBLIC_TOKEN` for the name and your public `pk.` token for the value.
#' Then run **Actions > Package website > Run workflow** on `main`, after the
#' website build changes have been merged. See GitHub's
#' [secret setup instructions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets).
#'
#' For a dedicated website token, allow `https://www.shirokuriwaki.com` in its
#' URL restrictions and retain the public `styles:read` and `fonts:read` scopes.
#' The token is embedded in the published widget HTML; storing it as a GitHub
#' secret keeps it out of source files but does not hide it from site visitors.
#' The website displays a labeled TN-09 fallback screenshot if the live map
#' cannot load, including token, network, or WebGL failures. A slow map can
#' replace the screenshot once it finishes loading. Builds without the secret,
#' including fork pull requests, or with rendering errors show the screenshots
#' directly. The GitHub README links to the live maps and keeps its labeled
#' screenshots collapsed because GitHub cannot display interactive widgets.
#'
#' To preview locally, set `MAPBOX_PUBLIC_TOKEN` in R, run
#' `source(".github/scripts/build-home.R")`, then `pkgdown::build_site()`.
#' Allow `http://localhost` on the development token when serving locally.
#'
#' @section Free usage and billing:
#' The card-free trial permits **5,000 GL JS map loads per month** and provides
#' one token with restricted token-management options. Adding a payment method
#' enables pay as you go: the first **50,000 map loads per month** are free;
#' excess usage is billable. The next 50,000 loads cost $5 per 1,000. See
#' [trial limits](https://docs.mapbox.com/accounts/guides/signup/) and
#' [current pricing](https://www.mapbox.com/pricing).
#'
#' Each newly initialized map counts as a load. One widget containing several
#' Congress layers initializes one map; toggling layers, panning, and zooming do
#' not add loads. Reloading initializes another map. Sessions last at most
#' 12 hours. See [GL JS billing](https://docs.mapbox.com/mapbox-gl-js/guides/pricing/).
#'
#' Monitor usage and configure email notifications in the Mapbox Console.
#' Notifications **do not cap charges or stop service**; see the
#' [billing-cap FAQ](https://docs.mapbox.com/accounts/faq/can-i-set-up-a-cap-for-monthly-spending/).
#'
#' @section Screenshots:
#' Saving a PNG from the already rendered map does not initialize another map.
#' Reopening the widget for a screenshot does. The
#' [mapgl screenshot control](https://walker-data.com/mapgl/reference/add_screenshot_control.html)
#' retains attribution. Preserve the Mapbox logo and map attribution in shared
#' images; see [attribution guidance](https://docs.mapbox.com/help/dive-deeper/attribution/).
#'
#' @seealso [cd_mapbox()]
#'
#' @examples
#' # Check token presence without displaying its value.
#' nzchar(Sys.getenv("MAPBOX_PUBLIC_TOKEN"))
NULL
