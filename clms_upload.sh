#!/bin/bash
###############################
# release notes:
# Version 1.00 [20250405] code name hermes
###############################
version="1.00"
usage()
{
cat << EOF
#This utility copies the CLMS products to CDSE staging storage.
#IMPORTANT! First export environmental variables!!!!
export RCLONE_CONFIG_CLMS_TYPE=s3
export RCLONE_CONFIG_CLMS_ACCESS_KEY_ID=YOUR_CLMS_PUBLIC_S3_KEY
export RCLONE_CONFIG_CLMS_SECRET_ACCESS_KEY=YOUR_CLMS_PRIVATE_S3_KEY
export RCLONE_CONFIG_CLMS_REGION=default
export RCLONE_CONFIG_CLMS_ENDPOINT='https://s3.waw3-1.cloudferro.com'
export RCLONE_CONFIG_CLMS_PROVIDER='Ceph'
#
# example of usage
#
# Single file upload:
clms_upload.sh -b CLMS-YOUR-BUCKET-NAME -l /tmp/c_gls_NDVI_200503110000_GLOBE_VGT_V3.0.1.nc
#
#Batch upload of all NetCDF files residing localy in /home/ubuntu directory:
find /home/ubuntu -name "*.nc" | xargs -l -P 5 bash -c 'clms_upload.sh -b CLMS-YOUR-BUCKET-NAME -l $0'
################################################################
OPTIONS:
   -b	   bucket name to upload to specific to a producer e.g. CLMS-YOUR-BUCKET-NAME
   -h      this message
   -l      local path (i.e. file system) path to input file
   -o      Shall input file in the CLMS-YOUR-BUCKET-NAME bucket in the CDSE staging storage be overwritten?
   -v      version

EOF
}
while getopts “b:hl:or:v” OPTION; do
	case $OPTION in
		b)
			bucket=$OPTARG
			;;
		h)
			usage
			exit 0
			;;
		l)
			local_file=$OPTARG
			;;
		o)  
			overwrite=' --no-check-dest'
			;;
		r)  
			rep=$OPTARG
			;;
		v)
			echo version $version
			exit 0
			;;
		?)
			usage
			exit 1
			;;
	esac
done
#########################################sanity checks
#verify if file exists in the local storage
if [ ! -r $local_file ]; then
	echo "ERROR: File $local_file does not exist in the local storage!"
	exit 2
fi

#verify path number
patch_number=$(echo $local_file | rev | cut -f 2 -d '.')
if [ $patch_number -eq 0 ]; then
	echo "ERROR: Patch number (i.e. last digit in version) has to start with 1"
	exit 3
fi
#verify if the product exists already in the CDSE OData 
odata_product_count=$(wget -qO - 'https://datahub.creodias.eu/odata/v1/Products?$filter=(Collection/Name%20eq%20%27CLMS%27%20and%20startswith(Name,%27'$(basename $local_file | rev | cut -f 2- -d '.' | rev)'%27))' | jq '.value | length')
if [ $odata_product_count -gt 0 ]; then
	echo 'ERROR: Such product exists in the CDSE!'
	exit 4
fi
#gdal verify if the product exists already in the CDSE OData 
gdalinfo $local_file > /dev/null 2>&1
if [ $? -ne 0 ]; then
	ogrinfo $local_file > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "ERROR: GDAL can not open ${local_file}!"
		exit 5
	fi
fi

patch_number=$(echo $local_file | rev | cut -f 2 -d '.')
product_to_replace=''
#verify if the previous patch version exists
odata_product=$(wget -qO - 'https://datahub.creodias.eu/odata/v1/Products?$filter=(Collection/Name%20eq%20%27CLMS%27%20and%20startswith(Name,%27'$(basename $local_file | rev | cut -f 3- -d '.' | rev)'%27))')
if [ $(printf "$odata_product" | jq '.value|length') -gt 0 ]; then
	product_to_replace=$(printf "$odata_product" |  jq -r '.value[].Name' | paste -sd, -)
	odata_patch_number=$(printf "$odata_product" |  jq '.value[0].Name' | rev | cut -f 1 -d '.' | tr -dc '0-9')
	if [ $patch_number -ne $((${odata_patch_number}+1)) ]; then
		echo "ERROR: Patch version in CDSE is ${odata_patch_number} and the patch number of the product uploaded product should be $((${odata_patch_number}+1)) but it is ${patch_number}!"
		exit 6
	fi
fi
#verify product to replace
if [ ! -z $rep ]; then
	rep_product=$(wget -qO - 'https://datahub.creodias.eu/odata/v1/Products?$filter=(Collection/Name%20eq%20%27CLMS%27%20and%20startswith(Name,%27'$(basename $rep | rev | cut -f 2- -d '.' | rev)'%27))')
	if [ $(printf "$rep_product" | jq '.value|length') -gt 0 ]; then
		product_to_replace=$(printf "$rep_product" |  jq -r '.value[].Name' | paste -sd, -)
	else
		echo "ERROR: Product to patched does not exist in the CDSE: $rep"
		exit 7
	fi
fi
#print products to be replaced
if [ ! -z $product_to_replace ]; then
	echo "INFO: Following products will be patched in the CDSE: $product_to_replace"
fi
s3_path=${bucket}$(date --date now '+/%Y/%m/%d/')$(basename $local_file)
timestamp=$(date -u -d now '+%Y-%m-%dT%H:%M:%S')
last_modified=$(date -r $local_file '+%Y-%m-%dT%H:%M:%S')
file_size=$(du -smb --apparent-size $local_file | cut -f1)
md5_checksum=$(md5sum -b $local_file | cut -c-32)
rclone -q copy --s3-no-check-bucket --retries=20 --low-level-retries=20 --checksum --s3-use-multipart-uploads='false' --metadata --metadata-set uploaded=$timestamp --metadata-set WorkflowName="clms_upload" --metadata-set source-s3-endpoint-url=$RCLONE_CONFIG_CLMS_ENDPOINT --metadata-set file-size=$file_size --metadata-set md5=$md5_checksum --metadata-set last_modified=$last_modified --metadata-set s3-public-key=${RCLONE_CONFIG_CLMS_ACCESS_KEY_ID} --metadata-set source_s3_path='s3://'${s3_path} --metadata-set source_cleanup=true --metadata-set product_to_replace=${product_to_replace}${overwrite} $local_file CLMS:$s3_path
[ $? == 1 ] && echo "ERROR: Failed to upload $local_file" || echo "SUCCESS: Uploaded $local_file"
