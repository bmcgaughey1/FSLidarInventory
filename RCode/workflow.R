# workflow for building index files
#
# IMPORTANT NOTE:
# I have not tested this workflow as written. When building the original index
# files I ran the code more interactively and had inputs and outputs stored in
# folders specific to my computer. When I created the FSLidarInventory repo,
# I made locations for files relative to the repo root folder. I think 
# everything will run but not 100% sure.
#

# set variables to control region
choices <- c(
  "R6_Tdrive",
  "R3",
  "R1",
  "R10_Tongass_Tdrive",
  "R10_Chugach_Tdrive"
)
region <- choices[1]

# build index files
source("RCode/buildIndexes.R")

# deal with missing CRS using projection name in folder name.
if (region == "R6_Tdrive") {
  source("Rcode/inferR6CRS.R")
}

# deal with missing CRS (also overwrites info for R6 indexes that have 
# CRS info in folder name if point files have CRS info in geoTIFF tags)
source("RCode/addCRS.R")
