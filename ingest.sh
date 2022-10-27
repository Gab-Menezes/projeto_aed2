#!/bin/bash

videos_folder_path=$1
video_path=$2
output_format=$3
segment_time=$4
compression_format=$5
compression_level=$6

if [[ $videos_folder_path == "" || \
$video_path = "" || \
$output_format == "" || \
$segment_time == "" || \
$compression_level == "" || \
$compression_format == "" ]];
then
    echo 
    echo "Empty parameters"
    echo "./ingest.sh <videos_folder_path> <video_name> <yuv|rgb> <segment_time> <zstd|gzip|xz|lzma|lz4>"
    exit
fi

if [[ $output_format != "yuv" && $output_format != "rgb" ]];
then
    echo "Invalid output format. Use rgb or yuv"
    exit
fi

if [[ $compression_format != "zstd" && \
$compression_format != "gzip" && \
$compression_format != "xz" && \
$compression_format != "lzma" && \
$compression_format != "lz4" ]];
then
    echo "Invalid output format. Use zstd,gzip,xz,lzma or lz4"
    exit
fi

if ! [[ "$segment_time" =~ ^[0-9]+$ ]]; 
then 
    echo "Segment time must be a number"
    exit
fi

if ! [[ "$compression_level" =~ ^[0-9]+$ ]]; 
then 
    echo "Compression level must be a number"
    exit
fi

video_file_with_extension=$(echo $video_path | rev | cut -f 1 -d '/' | rev)
video_folder_name=$(echo $video_file_with_extension | cut -f 1 -d '.')
final_path="$videos_folder_path/$output_format-$compression_format-$video_folder_name"

mkdir -p $final_path
cp $video_path $final_path
cd $final_path

if [[ $output_format == "yuv" ]];
then
    time ffmpeg -i $video_file_with_extension -an -map 0 -segment_time $segment_time -f segment -segment_list parts.list part%03d.yuv
elif [[ $output_format == "rgb" ]];
then
    time ffmpeg -i $video_file_with_extension -an -pix_fmt rgb8 -map 0 -segment_time $segment_time -f segment -segment_list parts.list part%03d.rgb
fi

time find . -type f -name "part*.$output_format" | parallel -j $(nproc) zstd -v --rm -$compression_level --format=$compression_format {}
sed -i s/$/.$compression_format/ parts.list
