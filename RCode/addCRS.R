# code to deal with missing CRS for lidar index files
#
assignCRS <- function(index, wkt) {
  bb <- vect(index, layer = "boundingbox")
  wb <- vect(index, layer = "boundary")
  ass <- vect(index, layer = "assets")
  
  if (wkt != "") {
    # assign CRS
    crs(bb) <- wkt
    crs(wb) <- wkt
    crs(ass) <- wkt
    
    # add field
    bb$assignedCRS <- crs(bb)
    wb$assignedCRS <- crs(wb)
  } else {
    # add empty string to assigned CRS
    bb$assignedCRS <- ""
    wb$assignedCRS <- ""
  }  
  
  # write new index (overwrite)
  writeVector(bb, index, layer = "boundingbox", overwrite = TRUE)
  writeVector(wb, index, layer = "boundary", overwrite = TRUE, insert = TRUE)
  writeVector(ass, index, layer = "assets", overwrite = TRUE, insert = TRUE)
}

# code to build PDAL pipelines to get CRS from first point file in each project
# PDAL info --metadata is used to write a json file with information for the files
# then the CRS is extracted from the json files and used to set the CRS for index
# files. First bit of code creates the commands to extract the metadata. These commands
# need to be run in a python prompt with PDAL installed. Once run, the next block of code
# reads the json outputs and gets the CRS, and assigns it to the index.
#
# code uses the assignCRS function duplicated from the code above
#
library(terra)
library(tools)
library(jsonlite)

folder <- "H:/R6_IndexFiles"
folder <- "h:/R10_TNF_IndexFiles"
folder <- "h:/R10_CNF_IndexFiles"
folder <- "H:/R3_IndexFiles"

commandFile <- "data/PDAL_commands.bat"

files <- list.files(folder, "\\.gpkg", full.names = TRUE, ignore.case = TRUE)

# delete the existing command file to create a new one
if (!file.exists(commandFile)) {
  # open command file...write
  cmdFile <- file(commandFile, "wt")
  
  for (file in files) {
    # read layer from geopackage and check for CRS (use $hasCRS)
    bb <- vect(file, layer = "boundingbox")

    # check for CRS    
    if (!bb$hasCRS) {
      # read tile assets
      ass <- vect(file, layer = "assets")
      
      # write PDAL command line to read header
      writeLines(paste0("pdal info ", shQuote(ass$filespec[1]), " --metadata>", folder, "/", file_path_sans_ext(basename(ass$filespec[1])), ".json"), cmdFile)
    }
  }
  close(cmdFile)
}

# ******************************************************************************
# Run the PDAL commands (PDAL_commands.bat) in a python environment with 
# PDAL installed!!
# ******************************************************************************

# read json files to get CRS
for (file in files) {
  # read layer from geopackage and check for CRS (use $hasCRS)
  bb <- vect(file, layer = "boundingbox")
  
  # check for CRS    
  if (!bb$hasCRS) {
    # read tile assets
    ass <- vect(file, layer = "assets")
    
    # check for json file
    jsonFile <- paste0(folder, "/", file_path_sans_ext(basename(ass$filespec[1])), ".json")
    if (file.exists(jsonFile) && file.info(jsonFile)$size > 0) {
      df <- fromJSON(jsonFile)
      if (!is.null(df$metadata$srs$compoundwkt)) {
        if (df$metadata$srs$compoundwkt == "") {
          cat("CRS (compoundwkt) is empty for:", file_path_sans_ext(basename(file)), "\n")
        } else {
          assignCRS(file, df$metadata$srs$compoundwkt)
        }
      } else {
        cat("No CRS (compoundwkt) string in json file:", file_path_sans_ext(basename(ass$filespec[1])), "\n")
      }
    } else {
      cat("No json file", jsonFile, "or file is empty. Did you run the PDAL commands?\n")
    }
  }
}

# count files that still don't have CRS
cnt <- 0
#file <- files[153]
for (file in files) {
  # read layer from geopackage and check for CRS (use $hasCRS)
  bb <- vect(file, layer = "boundingbox")
  
  # check for CRS    
  if (!bb$hasCRS && bb$assignedCRS == "") {
    cnt <- cnt + 1
  }
}
cat("Files without CRS info:", cnt, "\n")  

# ******************************************************************************
# ***** The above logic doesn't work for projects that have no CRS in point files...
# you still end up with some index files with no CRS
# ******************************************************************************


# ***** this is "extra" code used when developing the index functions
#
# step through index files and display so we can check the CRS
# ***** don't want to do this more than once...takes hours
# library(mapview)
# library(webshot)
# for (i in 1:length(files)) {
#   # cat(file, "...")
#   # read layer from geopackage and check for CRS (use $hasCRS)
#   bb <- vect(files[i], layer = "boundingbox")
#   
#   if (bb$assignedCRS != "") {
#     m <- mapview(bb)
#     mapshot(m, url = "test.html")
#     
#     invisible(readline(prompt = paste("Item", i, "is ready, Press [Enter] to continue...")))
#   }
# }

# ****************************************************************************
# step through index files and build CSV table with boundary attributes...useful for summarizing and 
# further analyses
#
# *****this is also done in the lidarIndexR_test.R file after adding CRS information
#
# df <- data.frame()
# for (i in 1:length(files)) {
#   # read layer from geopackage and check for CRS (use $hasCRS)
#   bb <- vect(files[i], layer = "boundingbox")
#   
#   df <- rbind(df, as.data.frame(bb))
# }
# 
# write.csv(df, "Documents/R6IndexEntries.csv", row.names = FALSE)
# 
# df3DEP <- df[grepl("3dep", tolower(df$base)),]
# sprintf("Total size: %f Tb", sum(df$assetsize)/1024/1024/1024/1024)
# sprintf("Total 3DEP data size: %f Tb", sum(df3DEP$assetsize)/1024/1024/1024/1024)
# sprintf("Total non-3DEP data size: %f Tb", sum(df$assetsize)/1024/1024/1024/1024 - sum(df3DEP$assetsize)/1024/1024/1024/1024)

# old comment: several R6 projects have the wrong CRS...even after name matching and 
# reading CRS info from geoTIFF tags in point files
#
# found problems with 86, 91, 108, 124, 125, 173, 191 as in for (i in 1:length(files))
# these areas have completely wrong crs information (show up in the wrong place)

