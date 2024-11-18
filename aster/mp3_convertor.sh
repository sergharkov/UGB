#!/bin/bash
echo "starting......"
#####################################################
# docker-compose -f docker-compose.yml stop callrecordssheduler \
# && docker-compose -f docker-compose.yml build callrecordssheduler \
# && docker-compose -f docker-compose.yml up -d callrecordssheduler \
# && docker exec -it callrecordssheduler bash
# needed:
# --lame
# --awscli
#####################################################
# https://ourcodeworld.com/articles/read/1402/how-to-convert-wav-files-to-mp3-with-the-command-line-using-lame-like-a-boss-in-windows-10
# wget -O lame-3.99.5.tar.gz https://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download
# tar -xvf lame-3.99.5.tar.gz 
# rm lame-3.99.5.tar.gz 
# cd lame-3.99.5 
# ./configure
# make 
# make install
#####################################################
echo "######### Will Use system Variables for AWS S3"
echo "######### AWSS3 bucket== $AWSS3"
echo "#############################################"
awss3bucket="$(echo "$AWSS3")"
deltatime="5" # in minutes (-cmin)
bitrate_to_mp3="32"
records_path="/tmp/callsrecords"
wav_records="$records_path/wav"
mp3_records="$records_path/mp3"

echo "=================  awss3bucket   $awss3bucket "

mkdir -p $wav_records
mkdir -p $mp3_records

ls -la $wav_records
#ls -la $mp3_records

list_wav_files=$(find $wav_records/* -cmin +$deltatime | sed 's/.*\///' | grep -v mp3)
#list_mp3_files=$(find $mp3_records/* -cmin +$deltatime | sed 's/.*\///')

echo $list_wav_files
#echo $list_mp3_files

echo "Start converting and moving to AWS S3 storage......................."
for wav_file in  ${list_wav_files[*]}  
do
  echo "----------------------"
  printf "   %s\n" $wav_records/$wav_file
  mp3_file="$(echo $wav_file | sed 's/.wav//g').mp3"
  echo "name of MP3 file == $mp3_file -------------------------------------------------"
  lame -b $bitrate_to_mp3 $wav_records/$wav_file $wav_records/$mp3_file
  echo "!!!!!!!!!!!!! will remove file =========== $wav_records/$wav_file   ======================"
  rm -f $wav_records/$wav_file
  mv -f $wav_records/$mp3_file $mp3_records/$mp3_file
  aws s3 cp $mp3_records/$mp3_file $awss3bucket/$mp3_file
  rm -f $mp3_records/$mp3_file
done
echo "==============SHOW local files==============="
echo "==============  Wav records  ==============="
ls -la $wav_records
echo "==============  Mp3 records  ==============="
ls -la $mp3_records
echo "================ AWS S3 list ================"
aws s3 ls s3://ugb-test-ast/
#####################################################
echo "///////////////////////--END SCRIPT--///////////////////////"
