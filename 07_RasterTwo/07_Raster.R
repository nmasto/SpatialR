#' ---
#' title: "More Raster"
#' author: "Adam M. Wilson"
#' date: "October 2015"
#' output:
#'   revealjs::revealjs_presentation:
#'       theme: sky
#'       transition: fade
#'       highlight: monochrome
#'       center: false
#'       width: 1080
#' #      widgets: [mathjax, bootstrap,rCharts]
#'       keep_md:  true
#'       pandoc_args: [ "--slide-level", "2" ]
#'   html_document:
#'     keep_md: yes
#'     toc: yes
#' 
#' ---
#' 
#' 
#' 
#' ## Today
#' 
#' * Homework: post tomorrow
#' * More raster...
#'      * Socioeconomic data at SEDAC
#'      * `Your Turn` sections
#' * Final Project discussion / work?
#' 
#' ## Libraries
#' 
## ----message=F,warning=FALSE---------------------------------------------
library(knitr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(raster)
library(rasterVis)
library(scales)

#' 
#' ## Today's question
#' 
#' ### How will future (projected) sea level rise affect Bangladesh?
#' 
#' 1. How much area is likely to be flooded by rising sea level?
#' 2. How many people are likely to be displaced?
#' 3. Will sea level rise affect any major population centers?
#' 
#' ## Bangladesh
#' 
## ------------------------------------------------------------------------
getData("ISO3")%>%
  as.data.frame%>%
  filter(NAME=="Bangladesh")

#' 
#' 
#' ---
#' 
#' ### Download Bangladesh Border
#' 
#' Often good idea to keep data in separate folder.  You will need to edit this for your machine!
## ------------------------------------------------------------------------
datadir="~/GoogleDrive/Work/courses/2015_UB503/SpatialR/data"

#' Download country border.
## ------------------------------------------------------------------------
bgd=getData('GADM', country='BGD', level=0,path = datadir)
plot(bgd)

#' 
#' 
#' ## Topography
#' 
#' SRTM Elevation data with `getData()` as 5deg tiles.
#' 
## ------------------------------------------------------------------------
bgdc=gCentroid(bgd)%>%coordinates()

dem1=getData("SRTM",lat=bgdc[2],lon=bgdc[1],path=datadir)
plot(dem1)
plot(bgd,add=T)

#' 
#' ---
#' 
#' ### Mosaicing/Merging rasters
#' 
#' Download the remaining necessary tiles
#' 
## ------------------------------------------------------------------------
dem2=getData("SRTM",lat=23.7,lon=85,path=datadir)

#' 
#' Use `merge()` to join two aligned rasters (origin, resolution, and projection).  Or `mosaic()` combines with a function.
#' 
## ------------------------------------------------------------------------
dem=merge(dem1,dem2)
plot(dem)
plot(bgd,add=T)

#' 
#' 
#' ## Saving/exporting rasters
#' 
#' Beware of massive temporary files!
#' 
## ------------------------------------------------------------------------
inMemory(dem)
dem@file@name
file.size(sub("grd","gri",dem@file@name))*1e-6
showTmpFiles()

#' 
#' ---
#' 
## ------------------------------------------------------------------------
rasterOptions()

#' Set with `rasterOptions(tmpdir = "/tmp")`
#' 
#' ---
#' 
#' Saving raster to file: _two options_
#' 
#' Save while creating
## ----eval=F--------------------------------------------------------------
## dem=merge(dem1,dem2,filename=file.path(datadir,"dem.tif"))

#' 
#' Or after
## ----eval=F--------------------------------------------------------------
## writeRaster(dem, filename = file.path(datadir,"dem.tif"))

#' 
#' ---
#' 
#' ### WriteRaster formats
#' 
#' Filetype  Long name	                      Default extension	  Multiband support
#' ---       ---                             ---                 ---
#' raster	  'Native' raster package format	.grd	              Yes
#' ascii	    ESRI Ascii	                    .asc                No
#' SAGA	    SAGA GIS	                      .sdat	              No
#' IDRISI	  IDRISI	                        .rst	              No
#' CDF	      netCDF (requires `ncdf`)	      .nc	                Yes
#' GTiff	    GeoTiff (requires rgdal)	      .tif	              Yes
#' ENVI	    ENVI .hdr Labelled	            .envi	              Yes
#' EHdr	    ESRI .hdr Labelled	            .bil	              Yes
#' HFA	      Erdas Imagine Images (.img)   	.img	              Yes
#' 
#' rgdal does even more...
#' 
#' ---
#' 
#' ### Crop to Bangladesh
#' 
## ------------------------------------------------------------------------
dem=crop(dem,bgd,filename=file.path(datadir,"dem_bgd.tif"),overwrite=T)
plot(dem); plot(bgd,add=T)

#' 
#' ---
#' 
## ----warning=F-----------------------------------------------------------
gplot(dem,max=1e5)+geom_tile(aes(fill=value))+
  scale_fill_gradientn(
    colours=c("red","yellow","grey30","grey20","grey10"),
    trans="log1p",breaks= log_breaks(n = 5, base = 10)(c(1, 1e3)))+
  coord_equal(ylim=c(21,25))+
  geom_path(data=fortify(bgd),
            aes(x=long,y=lat,order=order,group=group),size=.5)

#' 
#' ---
#' 
#' # Terrain analysis (an aside)
#' 
#' ## Terrain analysis options
#' 
#' `terrain()` options:
#' 
#' * slope
#' * aspect
#' * TPI (Topographic Position Index)
#' * TRI (Terrain Ruggedness Index)
#' * roughness
#' * flowdir
#' 
#' ---
#' 
#' Use a smaller region:
## ------------------------------------------------------------------------
reg1=crop(dem1,extent(93.8,94,21.05,21.15))
plot(reg1)

#' 
#' The terrain indices are according to Wilson et al. (2007), as in [gdaldem](http://www.gdal.org/gdaldem.html).
#' 
#' ---
#' 
#' ### Calculate slope
#' 
## ------------------------------------------------------------------------
slope=terrain(reg1,opt="slope",unit="degrees")
plot(slope)

#' 
#' ---
#' 
#' ### Calculate aspect
#' 
## ------------------------------------------------------------------------
aspect=terrain(reg1,opt="aspect",unit="degrees")
plot(aspect)

#' 
#' ---
#' 
#' ### TPI (Topographic Position Index)
#' 
#' Difference between the value of a cell and the mean value of its 8 surrounding cells.
#' 
## ------------------------------------------------------------------------
tpi=terrain(reg1,opt="TPI")

gplot(tpi,max=1e6)+geom_tile(aes(fill=value))+
  scale_fill_gradient2(low="blue",high="red",midpoint=0)+
  coord_equal()

#' Negative values indicate valleys, near zero flat or mid-slope, and positive ridge and hill tops
#' 
#' ## Your Turn
#' 
#' * Identify all the pixels with a TPI less than -15 or greater than 15.
#' * Use `plot()` to:
#'     * plot elevation for this region
#'     * overlay the valley pixels in blue
#'     * overlay the ridge pixels in red
#' 
#' Hint: use `transparent` to plot a transparent pixel.  
#' 
#' ---
#' 
#' Extract peaks/ridges and valleys:
#' 
#' ---
#' 
#' ### TRI (Terrain Ruggedness Index)
#' 
#' Mean of the absolute differences between the value of a cell and the value of its 8 surrounding cells.
#' 
## ------------------------------------------------------------------------
tri=terrain(reg1,opt="TRI")
plot(tri)

#' 
#' ---
#' 
#' ### Roughness 
#' 
#' Difference between the maximum and the minimum value of a cell and its 8 surrounding cells.
#' 
## ------------------------------------------------------------------------
rough=terrain(reg1,opt="roughness")
plot(rough)

#' 
#' 
#' ---
#' 
#' ### Hillshade (pretty...)
#' 
#' Compute from slope and aspect (in radians). Often used as a backdrop for another semi-transparent layer.
#' 
## ------------------------------------------------------------------------
hs=hillShade(slope*pi/180,aspect*pi/180)

plot(hs, col=grey(0:100/100), legend=FALSE)
plot(reg1, col=terrain.colors(25, alpha=0.5), add=TRUE)

#' 
#' ---
#' 
#' ### Flow Direction
#' 
#' _Flow direction_ (of water), i.e. the direction of the greatest drop in elevation (or the smallest rise if all neighbors are higher). 
#' 
#' Encoded as powers of 2 (0 to 7). The cell to the right of the focal cell 'x' is 1, the one below that is 2, and so on:
#' 
#' 32	64	    128
#' --- ---     ---
#' 16	**x**	  1
#' 8   4       2
#' 
#' ---
#' 
## ------------------------------------------------------------------------
flowdir=terrain(reg1,opt="flowdir")

plot(flowdir)

#' Much more powerful hydrologic modeling in [GRASS GIS](https://grass.osgeo.org) 
#' 
#' # Sea Level Rise
#' 
#' ---
#' 
#' ## Global SLR Scenarios
#' 
## ----results="markdown"--------------------------------------------------
slr=data.frame(year=2100,
               scenario=c("RCP2.6","RCP4.5","RCP6.0","RCP8.5"),
               low=c(0.26,0.32,0.33,0.53),
               high=c(0.54,0.62,0.62,0.97))
kable(slr)

#' 
#' [IPCC AR5 WG1 Section 13-4](https://www.ipcc.ch/pdf/assessment-report/ar5/wg1/drafts/fgd/WGIAR5_WGI-12Doc2b_FinalDraft_Chapter13.pdf)
#' 
#' ## Storm Surges
#' 
#' Range from 2.5-10m in Bangladesh since 1960 [Karim & Mimura, 2008](http://www.sciencedirect.com/science/article/pii/S0959378008000447).  
#' 
## ------------------------------------------------------------------------
ss=c(2.5,10)

#' 
#' ## Raster area
#' 
#' 1st Question: How much area is likely to be flooded by rising sea levels? 
#' 
#' WGS84 data is unprojected, must account for cell area (in km^2)...
## ------------------------------------------------------------------------
area=area(dem)
plot(area)

#' 
#' ## Your Turn
#' 
#' 1. How much area is likely to be flooded by rising sea levels for two scenarios:
#'    * 0.26m SLR and 2.5m surge (`r .26+2.5` total)
#'    * 0.97 SLR and 10m surge (`r 0.97+10` total)
#'    
#' Steps:
#' 
#' * Identify which pixels are below thresholds
#' * Multiply by cell area
#' * Use `cellStats()` to calculate potentially flooded areas.
#' 
#' ## Identify pixels below thresholds
#' 
#' 
#' ---
#' 
#' ## Multiply by area and sum
#' 
#' 
#' 
#' ## Socioeconomic Data
#' 
#' Socioeconomic Data and Applications Center (SEDAC)
#' [http://sedac.ciesin.columbia.edu](http://sedac.ciesin.columbia.edu)
#' <img src="assets/sedac.png" alt="alt text" width="70%">
#' 
#' * Population
#' * Pollution
#' * Energy
#' * Agriculture
#' * Roads
#' 
#' ---
#' 
#' ### Gridded Population of the World
#' 
#' Data _not_ available for direct download (e.g. `download.file()`)
#' 
#' * Log into SEDAC with an Earth Data Account
#' [http://sedac.ciesin.columbia.edu](http://sedac.ciesin.columbia.edu)
#' * Download Population Density Grid for 2000
#' 
#' <img src="assets/sedacData.png" alt="alt text" width="80%">
#' 
#' ---
#' ### Load population data
#' 
#' Use `raster()` to load a raster from disk.
#' 
## ------------------------------------------------------------------------
pop=raster(file.path(datadir,"gl_gpwv3_pdens_00_bil_25/glds00g.bil"))
plot(pop)

#' 
#' ---
#' 
#' A nicer plot...
## ------------------------------------------------------------------------
gplot(pop,max=1e6)+geom_tile(aes(fill=value))+
  scale_fill_gradientn(
    colours=c("grey90","grey60","darkblue","blue","red"),
    trans="log1p",breaks= log_breaks(n = 5, base = 10)(c(1, 1e5)))+
  coord_equal()

#' 
#' ---
#' 
#' ### Crop to region with the `dem` object
#' 
## ------------------------------------------------------------------------
pop2=pop%>%
  crop(dem)

gplot(pop2,max=1e6)+geom_tile(aes(fill=value))+
  scale_fill_gradientn(colours=c("grey90","grey60","darkblue","blue","red"),
                       trans="log1p",breaks= log_breaks(n = 5, base = 10)(c(1, 1e5)))+
  coord_equal()

#' 
#' ---
#' 
#' ### Resample to DEM
#' 
#' Assume equal density within each grid cell and resample
## ---- warning=F----------------------------------------------------------
pop3=pop2%>%
  resample(dem,method="bilinear")

gplot(pop3,max=1e6)+geom_tile(aes(fill=value))+
  scale_fill_gradientn(colours=c("grey90","grey60","darkblue","blue","red"),
                       trans="log1p",breaks= log_breaks(n = 5, base = 10)(c(1, 1e5)))+
  coord_equal()


#' 
#' ---
#' 
#' Or resample elevation to resolution of population:
#' 
## ----eval=F--------------------------------------------------------------
## res(pop2)/res(dem)
## demc=dem%>%
##   aggregate(fact=50,fun=min,expand=T)%>%
##   resample(pop2,method="bilinear")

#' 
#' 
#' ## Your Turn
#' 
#' How many people are likely to be displaced?
#' 
#' Steps:
#' 
#' * Multiply flooded area (`flood2`) **x** population density **x** area
#' * Summarize with `cellStats()`
#' * Plot a map of the number of people potentially affected by `flood2`
#' 
#' ---
#' 
#' 
#' 
#' ---
#' 
#' Number of potentially affected people across the region.
#' 
#' 
#' ## Raster Distances
#' 
#' `distance()` calculates distances for all cells that are NA to the nearest cell that is not NA.
#' 
## ------------------------------------------------------------------------
popcenter=pop2>5000
popcenter=mask(popcenter,popcenter,maskvalue=0)
plot(popcenter,col="red",legend=F)

#' 
#' ---
#' 
#' In meters if the RasterLayer is not projected (`+proj=longlat`) and in map units (typically also meters) when it is projected.
#' 
## ---- warning=F----------------------------------------------------------
popcenterdist=distance(popcenter)
plot(popcenterdist)

#' 
#' ## Your Turn
#' 
#' Will sea level rise affect any major population centers?
#' 
#' Steps:
#' 
#' * Resample `popcenter` to resolution of `dem` using `method=ngb`
#' * Identify `popcenter` areas that flood according to `flood2`.
#' 
#' ---
#' 
#' Will sea level rise affect any major population centers?
#' 
#' 
#' ## Vectorize raster
#' 
## ----warning=F, message=F------------------------------------------------
vpop=rasterToPolygons(popcenter, dissolve=TRUE)

gplot(dem,max=1e5)+geom_tile(aes(fill=value))+
  scale_fill_gradientn(
    colours=c("red","yellow","grey30","grey20","grey10"),
    trans="log1p",breaks= log_breaks(n = 5, base = 10)(c(1, 1e3)))+
  coord_equal(ylim=c(21,25))+
  geom_path(data=fortify(bgd),aes(x=long,y=lat,order=order,group=group),size=.5)+
  geom_path(data=fortify(vpop),aes(x=long,y=lat,order=order,group=group),size=1,col="green")


#' Warning: very slow on large rasters...
#' 
#' ## 3D Visualization
#' Uses `rgl` library.  
#' 
## ---- eval=F-------------------------------------------------------------
## plot3D(dem)
## decorate3d()

#' 
#' <img src="assets/plot3d.png" alt="alt text" width="70%">
#' 
#' 50 different styles illustrated [here](https://cran.r-project.org/web/packages/plot3D/vignettes/volcano.pdf).
#' 
#' ---
#' 
#' Overlay population with `drape`
#' 
## ---- eval=F-------------------------------------------------------------
## plot3D(dem,drape=pop3, zfac=1)
## decorate3d()

#' 
#' ## Raster overview
#' 
#' * Perform many GIS operations
#' * Convenient processing and workflows
#' * Some functions (e.g. `distance()` can be slow!
#' 
#' ## Project Questions?
#' 
