# internal state abb variable
#' @keywords internal
state.abb <- c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
               "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
               "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
               "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
               "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

# save variable
usethis::use_data(state.abb, internal = TRUE, overwrite = TRUE)
