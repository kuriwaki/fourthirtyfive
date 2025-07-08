# Author: Cory McCartan

library(dplyr)
library(ggplot2)
library(ggforce)
library(matrixStats)
library(sf)
library(conflicted)
conflicted::conflict_prefer("count", "dplyr")
conflicted::conflict_prefer("filter", "dplyr")
conflicted::conflict_prefer("select", "dplyr")

d_apport = tigris::congressional_districts(cb=TRUE, resolution="20m") |>
    st_drop_geometry() |>
    count(STATEFP) |>
    mutate(n = n + 2)

d = tigris::states(cb=TRUE, resolution="5m") |>
    filter(STUSPS %in% c(state.abb, "DC")) |>
    tigris::shift_geometry() |>
    left_join(d_apport, by="STATEFP") |>
    select(state=STUSPS, name=NAME, ev=n, geometry) |>
    mutate(radius = sqrt(ev) / mean(sqrt(ev)))

# ctrs = geos::geos_maximum_inscribed_crc(d$geometry, 1) |>
#     st_as_sfc() |>
ctrs = d$geometry |>
    st_centroid() |>
    st_coordinates()
rownames(ctrs) = d$state

mean_sep = mean(colQuantiles(as.matrix(dist(ctrs)), probs=1/51))

radii = 0.8 * mean_sep/2 * d$radius
names(radii) = d$state
sep_mat = outer(radii, radii, `+`) #+ 0.08 * mean_sep
diag(sep_mat) = 0

fn = function(pos) {
    xy = matrix(pos, ncol=2)
    dm = as.matrix(dist(xy))
    pen = sum(pmax(sep_mat - dm, 0)) / mean_sep
    dis = mean(sqrt(rowSums((xy - ctrs)^2))) / mean_sep
    dis + 10*pen #+ 0.1*mean(dm[dm < 2*mean_sep])/mean_sep
}

parsc = rep(mean_sep, length(ctrs))
# res = optim(ctrs, fn, method="L-BFGS-B", control=list(parscale=parsc))
res = optim(ctrs, fn, method="Nelder-Mead",
            control=list(maxit=1e5, reltol=1e-8, parscale=parsc))

xy = matrix(res$par, ncol=2)
d_circ = st_as_sf(as.data.frame(xy), coords=1:2) |>
    st_buffer(radii)

plot(d$geometry)
plot(d_circ, add=TRUE, col='#444455aa', lwd=0.01)

ggplot(NULL, aes(r=radii)) +
    geom_circle(aes(x0=ctrs[, 1], y0=ctrs[, 2]), color="#cccccc", lwd=0.3) +
    geom_text(aes(x=ctrs[, 1], y=ctrs[, 2], label=d$state), color="#cccccc", size=2.5) +
    geom_circle(aes(x0=xy[, 1], y0=xy[, 2]), color="black") +
    geom_text(aes(x=xy[, 1], y=xy[, 2], label=d$state), size=2.5) +
    coord_fixed() +
    theme_void()
