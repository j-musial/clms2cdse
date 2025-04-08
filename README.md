# clms2cdse
This repository holds tools to integrate Copernicus Land Monitoring Service data sets into the Copernicus Data Space Ecosystem platform

## [clms_upload.sh](https://github.com/j-musial/clms2cdse/blob/main/clms_upload.sh) - tool to upload nominal CLMS production to CDSE

This utility copies CLMS products from **LOCAL STORAGE** of a producer to the CDSE delivery point. If the 3-digits versioning convention in product naming (e.g. 1.1.1) is kept then the script will automatically checks if a product being uploaded has a previous version and it will replace it in the CDSE.

## Prerequisites:

- Linux distribution with bash shell and pre-installed [rclone](https://rclone.org/docs/) and [gdal+ogr](https://gdal.org/en/stable/download.html#binaries) utilities.
- Exported environmental variables. Can be added to [.bashrc](https://www.digitalocean.com/community/tutorials/bashrc-file-in-linux) file:

```
export RCLONE_CONFIG_CLMS_TYPE=s3
export RCLONE_CONFIG_CLMS_ACCESS_KEY_ID=YOUR_CLMS_PUBLIC_S3_KEY
export RCLONE_CONFIG_CLMS_SECRET_ACCESS_KEY=YOUR_CLMS_PRIVATE_S3_KEY
export RCLONE_CONFIG_CLMS_REGION=default
export RCLONE_CONFIG_CLMS_ENDPOINT='https://s3.waw3-1.cloudferro.com'
export RCLONE_CONFIG_CLMS_PROVIDER='Ceph'
```
##Tool options:
```
   -b	   bucket name to upload to specific to a producer e.g. CLMS-YOUR-BUCKET-NAME
   -h      this message
   -l      local path (i.e. file system) path to input file
   -o      Shall input file in the CLMS-YOUR-BUCKET-NAME bucket in the CDSE delivery point be overwritten?
   -v      version
```
##Single CLMS product upload:
```
clms_upload.sh -b CLMS-YOUR-BUCKET-NAME -l /tmp/c_gls_NDVI_200503110000_GLOBE_VGT_V3.0.1.nc
```
##Batch upload of all NetCDF files stored locally in /home/ubuntu directory::
```
find /home/ubuntu -name '*.nc' | xargs -l -P 5 bash -c 'clms_upload.sh -b CLMS-YOUR-BUCKET-NAME -l $0'
```
## [lot2_upload.sh](https://github.com/j-musial/clms2cdse/blob/main/lot2_upload.sh) - tool to upload CLMS LOT2 archival data sets to CDSE

This utility copies CLMS LOT2 products from **LOCAL STORAGE** of a producer to the CDSE delivery point:
## Prerequisites:

- Linux distribution with bash shell and pre-installed [rclone](https://rclone.org/docs/) and [gdal+ogr](https://gdal.org/en/stable/download.html#binaries) utilities.
- Exported environmental variables. Can be added to [.bashrc](https://www.digitalocean.com/community/tutorials/bashrc-file-in-linux) file:

```
export RCLONE_CONFIG_LOT2_TYPE=s3
export RCLONE_CONFIG_LOT2_ACCESS_KEY_ID=YOUR_CLMS_PUBLIC_S3_KEY
export RCLONE_CONFIG_LOT2_SECRET_ACCESS_KEY=YOUR_CLMS_PRIVATE_S3_KEY
export RCLONE_CONFIG_LOT2_REGION=default
export RCLONE_CONFIG_LOT2_ENDPOINT='https://s3.waw3-1.cloudferro.com'
export RCLONE_CONFIG_LOT2_PROVIDER='Ceph'
```
##Tool options:
```
   -h      this message
   -l      local path (i.e. file system) path to input file
   -o      Shall input file in the CLMS-YOUR-BUCKET-NAME bucket in the CDSE delivery point be overwritten?
   -p	   Relative path of a file in the S3 bucket of the CLMS producer e.g. webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily/2024/20240713
   -v      version
```
##Single CLMS product upload:
./lot2_upload.sh -l c_gls_SWE5K_202407130000_NHEMI_SSMIS_V2.0.1.nc -p webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily/2024/20240713
##Batch upload if directory structure in your LOCAL STORAGE follows old CLMS path convention e.g. webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily:

##Batch upload of all NetCDFs for dataset swe_5km_v2_daily stored locally in /home/johnlane/webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily:
```
find /home/ubuntu/webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily -name '*.nc' | xargs -l -P 5 bash -c './lot2_upload.sh -l $0 -p $(dirname $0 | sed -z "s/.*webResources/webResources/")'
```
##Batch upload of all tiff for dataset swe_5km_v2_daily stored locally in /home/johnlane/webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily:
```
find /home/ubuntu/webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily -name '*.tif' | xargs -l -P 5 bash -c './lot2_upload.sh -l $0 -p $(dirname $0 | sed -z "s/.*webResources/webResources/")'
```
##Batch upload of all files in /home/johnlane/webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily:
```
find /home/ubuntu/webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily -type f | xargs -l -P 5 bash -c './lot2_upload.sh -l $0 -p $(dirname $0 | sed -z "s/.*webResources/webResources/")'
```
# For WINDOWS and MacOS users the tool can be executed via Docker environment
##Build Docker container

Build the cdse_utilities Docker image:

```
docker build --no-cache https://github.com/j-musial/clms2cdse.git -t clms2cdse
```
## Importnat Note: Handling of the input/output directories using [Bind Mounts](https://docs.docker.com/storage/bind-mounts/) in Docker
The local storage of your computer can be attached directly to the Docker Container as a Bind Mount. Consequently, you can easily manage ingestion/outputing data directly from/to your local storage. For instance:
```
docker run -it -v /home/JohnLane:/home/ubuntu
```
maps the content of the local home directory named /home/JohnLane to the /home/ubuntu directory in a Docker container.

## Problem with docker permission

Please click [here](https://betterstack.com/community/questions/how-to-fix-docker-got-permission-denied/) if you encounter the following error while running Docker container:
```
docker: permission denied while trying to connect to the Docker daemon socket at unix
```
## Single product upload using [clms_upload.sh](https://github.com/j-musial/clms2cdse/blob/main/clms_upload.sh):
```
docker run -it -v /home/JohnLane:/home/ubuntu -e RCLONE_CONFIG_CLMS_ACCESS_KEY_ID=YOUR_CLMS_PUBLIC_S3_KEY -e RCLONE_CONFIG_CLMS_SECRET_ACCESS_KEY=YOUR_CLMS_PRIVATE_S3_KEY clms2cdse clms_upload.sh -b CLMS-YOUR-BUCKET-NAME -l /tmp/c_gls_NDVI_200503110000_GLOBE_VGT_V3.0.1.nc
```
## Batch upload of CLMS products using [clms_upload.sh](https://github.com/j-musial/clms2cdse/blob/main/clms_upload.sh):
```
TBD
```
## Batch product upload using [lot2_upload.sh](https://github.com/j-musial/clms2cdse/blob/main/lot2_upload.sh):
```
docker run -it -v /home/JohnLane:/home/ubuntu -e RCLONE_CONFIG_LOT2_ACCESS_KEY_ID=YOUR_CLMS_PUBLIC_S3_KEY -e RCLONE_CONFIG_LOT2_SECRET_ACCESS_KEY=YOUR_CLMS_PRIVATE_S3_KEY clms2cdse lot2_upload.sh -l c_gls_SWE5K_202407130000_NHEMI_SSMIS_V2.0.1.nc -p webResources/catalogTree/netcdf/snow_water_equivalent/swe_5km_v2_daily/2024/20240713
```
## Batch upload of CLMS products using [lot2_upload.sh](https://github.com/j-musial/clms2cdse/blob/main/lot2_upload.sh):
```
TBD
```
