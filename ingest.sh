#!/bin/bash

videos_folder_path=$1
video_path=$2
output_format=$3
segment_time=$4
compression_format=$5
compression_level=$6
data_path=$7

if [[ $videos_folder_path == "" || \
$video_path = "" || \
$output_format == "" || \
$segment_time == "" || \
$compression_level == "" || \
$compression_format == "" ]];
then
    echo 
    echo "Empty parameters"
    echo "./ingest.sh <videos_folder_path> <video_name> <yuv|rgb> <segment_time> <zstd|gzip|xz|lzma|lz4> <data_folder_path>"
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

cwd=$(pwd)
number_of_runs=1
if [[ $data_path != "" ]];
then
    number_of_runs=5
fi

#some utility vars
video_file_with_extension=$(echo $video_path | rev | cut -f 1 -d '/' | rev)
video_file_without_extension=$(echo $video_file_with_extension | cut -f 1 -d '.')
final_path="$videos_folder_path/$output_format-$compression_format-$video_file_without_extension"
ext=$compression_format
if [[ $ext == "gzip" ]];
then
    ext="gz"
fi

video_name=$(echo $video_file_without_extension | cut -f 1 -d '_')
video_resolution=$(echo $video_file_without_extension | cut -f 2 -d '_')

compress_time_sum=0
compress_avg_size_sum=0
compress_ratio_sum=0

for (( i=0; i<$number_of_runs; i++ ))
do
    #creates the directory, copies the video file to it and cd into it
    cd $cwd
    rm -rf $final_path
    mkdir -p $final_path
    cp $video_path $final_path
    cd $final_path

    #extract the video width, height and fps
    video_width=$(ffprobe -v quiet -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=width $video_file_with_extension)
    video_height=$(ffprobe -v quiet -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=height $video_file_with_extension)
    video_duration=$(ffprobe -v quiet -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=duration $video_file_with_extension)
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
    sed -i s/$/.$ext/ parts.list

    #write info.json file
    compression_format_upper=$(echo $compression_format | awk '{ print toupper($0) }')
    echo "{\"original_video_name\": $video_name, \"width\": $video_width, \"height\": $video_height, \"fps\": $video_fps, \"duration\": $video_duration, \"compression\": \"$compression_format_upper\"}" > info.json

    echo
    echo
    echo "Compression time: $compress_delta_time s"
    echo "Compression size: $compress_size bytes"
    echo "Compression throughput: $compress_throughput bytes/s"
    echo "Compression avg size: $compress_avg_size bytes"
    echo "Compression Ratio: $compress_ratio"
    echo

    #add to the sum
    compress_time_sum=$(awk "BEGIN {print $compress_time_sum+$compress_delta_time}")
    compress_avg_size_sum=$(awk "BEGIN {print $compress_avg_size_sum+$compress_avg_size}")
    compress_ratio_sum=$(awk "BEGIN {print $compress_ratio_sum+$compress_ratio}")
done

if [[ $data_path != "" ]];
then
    cd $cwd

    cd $data_path
    replace_str="${video_name}_${ext}"

    compress_time_avg=$(awk "BEGIN {print $compress_time_sum/$number_of_runs}")
    compress_avg_segment_size_avg=$(awk "BEGIN {print $compress_avg_size_sum/$number_of_runs}")
    compress_ratio_avg=$(awk "BEGIN {print $compress_ratio_sum/$number_of_runs}")

    compression_time_file="compression_time_${video_resolution}.dat"
    compression_avg_segment_size_file="compression_avg_segment_size_${video_resolution}.dat"
    compression_ratio_file="compression_ratio_${video_resolution}.dat"

    sed -i s/$replace_str/$compress_time_avg/ $compression_time_file
    sed -i s/$replace_str/$compress_avg_segment_size_avg/ $compression_avg_segment_size_file
    sed -i s/$replace_str/$compress_ratio_avg/ $compression_ratio_file
fi

