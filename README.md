# FSLidarInventory

R code to inventory USDA Forest Service lidar point cloud holdings (and other
sources as well).

This code relies on the [LidarIndexR
package](https://github.com/bmcgaughey1/LidarIndexR) which must be installed
from GitHub. There are installation instructions on the repo homepage. Note that
package installation requires Rtools to compile the C++ code to read LAS/LAZ
file headers.

This code also relies on the ScanLocalFiles program from this [repo](https://github.com/bmcgaughey1/ScanLocalFiles). This is a 
C++ program that recursively scans a directory trees and check to see if each folder
contains point data (LAS/LAZ/COPC). It should be possible to duplicate this capability
in R, python or powershell but I used C++ to take advantage of functions that find
the first occurrence of a file type without listing all occurrences of the file type.

The Documents folder has related documents and the attributes for the index
files as CSV files (also included in the index files). The [Word
document](https://github.com/bmcgaughey1/FSLidarInventory/blob/aa9511825fdf4b06f3545911d951751f0003fc54/Documents/Forest%20Service%20Lidar%20Indexing%20Project.docx)
has an overview of the project goals and results. The
[spreadsheet](https://github.com/bmcgaughey1/FSLidarInventory/blob/aa9511825fdf4b06f3545911d951751f0003fc54/Documents/InventoryResults.xlsx)
has storage space for the point data indexed as of April 15, 2025.

The IndexFiles folder has index files in geopackage format for each folder found
to contain point data. There are shapefile folders in each region's folder that
have shapefile versions of the boundary layers. I had trouble loading the
geopackage files in to ArcPro but I'm not sure if there is a problem with the
files, something I did, or ArcPro. The geopackage files have three layers. One
("boundingbox") is the simple, rectangular bounding box for all point data
files. Another ("boundary"") has the convex hull of the tile bounding boxes.
This layer can have multiple polygons if a folder has data from widely separated
areas. The third ("assets") has the bounding boxes and header information for
individual point files.

The data folder has the results of the directory scan as CSV files. These files
have the list of folders and columns indicating if the folder contains point
data (by data type).

The RCode folder has the R code that scans for folders, identifies folders
containing point data and creates the indexes.
