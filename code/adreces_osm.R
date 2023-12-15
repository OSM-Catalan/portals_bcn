library(sf)
library(osmdata)


bcn <- read.csv("data_raw/bcn_portals2023.csv")

# ajuntar districtes i barris

barris <- getbb("Barcelona",format_out = "osm_type_id") |>
  opq() |>
  add_osm_feature("admin_level", "10") |>
  osmdata_sf()

barris <- barris$osm_multipolygons

bcn_sf <- st_as_sf(bcn, coords = c("X", "Y"), crs = "EPSG:4326")

bcn_barris <- st_join(bcn_sf, st_make_valid(barris[,"name"]))

# dividir en taules de 200 files o menys per barri i guardar

bcn_barris$x <- st_coordinates(bcn_barris)[,1]
bcn_barris$y <- st_coordinates(bcn_barris)[,2]
colnames(bcn_barris)[colnames(bcn_barris)=="name"] <- "barri"
bcn_barris

bcn_barris <- split(bcn_barris,bcn_barris$barri)

sapply(bcn_barris, \(x) nrow(x))


bcn_barris <- lapply(bcn_barris, \(x) {x[["num"]] = rep(1:200, each = 200)[1:nrow(x)];return(x)})

bcn_barris <- do.call("rbind", bcn_barris)

row.names(bcn_barris) <- NULL

bcn_barris$num <- stringr::str_pad(bcn_barris$num, width = 2, pad = "0", side ="left")
bcn_barris$filename <- paste(bcn_barris$barri, bcn_barris$num, sep = "_")

bcn_barris <- split(bcn_barris, bcn_barris$filename)

allNames <- names(bcn_barris)

for(thisName in allNames){
  saveName = paste0("data/", thisName, '.geojson')
  st_write(bcn_barris[[thisName]], dsn = saveName)
}
