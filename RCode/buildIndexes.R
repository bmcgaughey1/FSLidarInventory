# ***** this is the code that actually builds the index files. It gets run for each area or parent folder
# See addCRS.R for the post-processing steps to deal with missing CRS.
#
# you have to get the list of folders (folderList variable) with point files
# using the ScanLocalFiles program (compiled C++) for R3 data stored on GTAC NAS
# and mounted as Q:, this is the command: ScanLocalFiles.exe q: "*.las|*.laz"
# R3_FileList.csv 25
#
# The C++ function that reads file headers cannot make sense of CRS information
# contained in geoTIFF tags. The code in addCRS.R builds PDAL commands that read
# file headers for a single file in each folder, sorts out CRS information (if
# present in WKT or geoTIFF tags), and assigns the CRS to index files. PDAL has
# much more robust code for dealing with the CRS information.
# 
library(LidarIndexR)
library(tools)

if (region == "R6_Tdrive") {
  outputFolder <- "IndexFiles\\R6_IndexFiles\\"
  rootFolder <- "T:/FS/Reference/RSImagery/ProcessedData/r06/R06_DRM_Deliverables/PointCloud/"
  folderList <- "data/TDrive_R6_FileList.csv"
  summaryCSVFile <- "Documents/R6_IndexEntries.csv"
}
if (region == "R10_Tongass_Tdrive") {
  outputFolder <- "IndexFiles\\R10_TNF_IndexFiles\\"
  rootFolder <- "T:/FS/Reference/RSImagery/ProcessedData/r10_tnf/RSImagery/Geo/DEM/LiDAR/"
  folderList <- "data/R10_TNF_FileList.csv"
  summaryCSVFile <- "Documents/R10_TNF_IndexEntries.csv"
}
if (region == "R10_Chugach_Tdrive") {
  outputFolder <- "IndexFiles\\R10_CNF_IndexFiles\\"
  rootFolder <- "T:/FS/Reference/RSImagery/ProcessedData/r10_cnf/RSImagery/Geo/DEM/LIDAR/"
  folderList <- "data/R10_CNF_FileList.csv"
  summaryCSVFile <- "Documents/R10_CNF_IndexEntries.csv"
}
if (region == "R3") {
  outputFolder <- "IndexFiles\\R3_IndexFiles\\"
  rootFolder <- "q:"
  folderList <- "data/R3_FileList.csv"
  summaryCSVFile <- "Documents/R3_IndexEntries.csv"
}
slashReplacement <- "_][_"

if (!dir.exists(outputFolder)) {dir.create(outputFolder)}

# read list of folders
folders <- utils::read.csv(folderList, stringsAsFactors = FALSE)

# drop folders with no data
folders <- folders[folders$X..laz == 1 | folders$X..las == 1, ]

folders$Folder <- gsub("\\\\", "/", folders$Folder)

# work through folders
for (i in 1:nrow(folders)) {
  name <- sub(rootFolder, "", folders$Folder[i])
  
  cat("Processing", name, ":", i, "of", nrow(folders), "...")
  
  name <- gsub("/", slashReplacement, name)
  
  # work through file types
  if (folders$X..laz[i]) {
    cat("LAZ...")
    BuildAssetCatalog(folders$Folder[i], "\\.laz", outputFile = paste0(outputFolder, name, "_LAZ.gpkg"), rebuild = FALSE)
  }
  if (folders$X..las[i]) {
    cat("LAS...")
    BuildAssetCatalog(folders$Folder[i], "\\.las", outputFile = paste0(outputFolder, name, "_LAS.gpkg"), rebuild = FALSE)
  }
  # if (folders$X..zlas[i]) {
  #   cat("zLAS...")
  #   BuildAssetCatalog(folders$Folder[i], "\\.zlas", outputFile = paste0(outputFolder, name, "_zLAS.gpkg"), rebuild = FALSE)
  # }
  
  cat("Done!\n")
  
  # if (i > 2)
  #   break
}

# step through index files and build CSV table with boundary attributes...useful for summarizing and 
# further analyses
library(terra)

files <- list.files(outputFolder, "\\.gpkg", full.names = TRUE, ignore.case = TRUE)

df <- data.frame()
for (i in 1:length(files)) {
  # read layer from geopackage and check for CRS (use $hasCRS)
  bb <- vect(files[i], layer = "boundingbox")
  
  df <- rbind(df, as.data.frame(bb))
}

write.csv(df, summaryCSVFile, row.names = FALSE)

# df <- read.csv(summaryCSVFile, stringsAsFactors = FALSE)

# summary information
df3DEP <- df[grepl("3dep", tolower(df$base)),]
if (nrow(df3DEP) > 0) {
  sprintf("   Total 3DEP data size: %f Tb", sum(df3DEP$assetsize/1024/1024/1024/1024))
  sprintf("   Total non-3DEP data size: %f Tb", sum(df$assetsize/1024/1024/1024/1024) - sum(df3DEP$assetsize)/1024/1024/1024/1024)
}
cat("Summary for", outputFolder, ":\n")
cat(sprintf("   Total size: %f Tb", sum(df$assetsize/1024/1024/1024/1024)), "\n")

# build shapefiles using the wrapping polygon ("boundary" layer). These can be easily 
# loaded in GIS to look for overlap with USGS 3DEP holdings.
outputFolder <- "h:\\R6_IndexFiles\\"
#outputFolder <- "h:\\R10_TNF_IndexFiles\\"
#outputFolder <- "h:\\R10_CNF_IndexFiles\\"
#outputFolder <- "h:\\R3_IndexFiles\\"

shpFolder <- paste0(outputFolder, "Shapefiles\\")

if (!dir.exists(shpFolder)) {dir.create(shpFolder)}

files <- list.files(outputFolder, "\\.gpkg", full.names = TRUE, ignore.case = TRUE)

#file <- paste0(outputFolder, "WIL_SIU_2013_2014_Lane_Del_1to9_ORlambert_feet_][_1_LAZ_LAZ.gpkg")
for (file in files) {
  # read layer from geopackage
  bb <- vect(file, layer = "boundary")
  #ass <- vect(file, layer = "assets")
  
  writeVector(bb, paste0(shpFolder, file_path_sans_ext(basename(file)), ".shp"), overwrite = TRUE)
}





# if (region == "R6_Tdrive") folder <- "IndexFiles/R6_IndexFiles"
# if (region == "R10_Tongass_Tdrive") folder <- "IndexFiles/R10_TNF_IndexFiles"
# if (region == "R10_Chugach_Tdrive") folder <- "IndexFiles/R10_CNF_IndexFiles"
# if (region == "R3") folder <- "IndexFiles/R3_IndexFiles"
# if (region == "R1") folder <- "IndexFiles/R1_IndexFiles"
# 
# files <- list.files(folder, "\\.gpkg", full.names = TRUE, ignore.case = TRUE)
# 
# # special code to fix min/max values in index gpkg...then need to rerun the shapefiles
# fixMinMax <- function(index) {
#   bb <- vect(index, layer = "boundingbox")
#   wb <- vect(index, layer = "boundary")
#   ass <- vect(index, layer = "assets")
# 
#   t <- bb$miny
#   bb$miny <- bb$maxx
#   bb$maxx <- t
#   
#   t <- wb$miny
#   wb$miny <- wb$maxx
#   wb$maxx <- t
#   
#   # write new index (overwrite)
#   writeVector(bb, index, layer = "boundingbox", overwrite = TRUE)
#   writeVector(wb, index, layer = "boundary", overwrite = TRUE, insert = TRUE)
#   writeVector(ass, index, layer = "assets", overwrite = TRUE, insert = TRUE)
# }
# 
# for (file in files) {
#   fixMinMax(file)
# }




