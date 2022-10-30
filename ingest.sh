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

#some utility vars
video_file_with_extension=$(echo $video_path | rev | cut -f 1 -d '/' | rev)
video_folder_name=$(echo $video_file_with_extension | cut -f 1 -d '.')
final_path="$videos_folder_path/$output_format-$compression_format-$video_folder_name"

#creates the directory, copies the video file to it and cd into it
mkdir -p $final_path
cp $video_path $final_path
cd $final_path

#extract the video width, height and fps
video_width=$(ffprobe -v quiet -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=width $video_file_with_extension)
video_height=$(ffprobe -v quiet -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=height $video_file_with_extension)
video_fps=$(ffprobe -v quiet -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate $video_file_with_extension)
video_fps=$(awk "BEGIN {print $video_fps}")

#extract the raw data from the video into segments
if [[ $output_format == "yuv" ]];
then
    ffmpeg -i $video_file_with_extension -an -map 0 -segment_time $segment_time -f segment -segment_list parts.list part%03d.yuv
elif [[ $output_format == "rgb" ]];
then
    ffmpeg -i $video_file_with_extension -an -pix_fmt rgb8 -map 0 -segment_time $segment_time -f segment -segment_list parts.list part%03d.rgb
fi
extract_size=$(ls -l | grep "\.$output_format" | awk '{sum += $5;} END {print sum;}')

#compress each segment
compress_begin_time=$(date +%s);
find . -type f -name "part*.$output_format" | parallel -j $(nproc) zstd -v --rm -$compression_level --format=$compression_format {}
compress_end_time=$(date +%s);
compress_delta_time=$(($compress_end_time-$compress_begin_time));
compress_size=$(ls -l | grep "\.$output_format\." | awk '{sum += $5;} END {print sum;}')
compress_avg_size=$(ls -l | grep "\.$output_format\." | awk '{sum += $5; n++;} END {print sum/n;}')

compress_ratio=$(awk "BEGIN {print $compress_size/$extract_size}")
compress_throughput=$(awk "BEGIN {print $compress_size/$compress_delta_time}")

#add .$compression_format to the end of each line in the parts.list
ext=$compression_format
if [[ $ext == "gzip" ]];
then
    ext="gz"
fi
sed -i s/$/.$ext/ parts.list

#write info.json file
compression_format_upper=$(echo $compression_format | awk '{ print toupper($0) }')
echo "{\"width\": $video_width, \"height\": $video_height, \"fps\": $video_fps, \"compression\": \"$compression_format_upper\"}" > info.json

#print some statistics about the proccess
echo
echo
echo "Compression time: $compress_delta_time s"
echo "Compression size: $compress_size bytes"
echo "Compression throughput: $compress_throughput bytes/s"
echo "Compression avg size: $compress_avg_size bytes"
echo "Compression Ratio: $compress_ratio"
echo
