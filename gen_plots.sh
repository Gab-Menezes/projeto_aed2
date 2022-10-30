#!/bin/bash

find ./subject_videos/ -type f -name "*.mp4" -exec ./collect_data.sh ./videos {} yuv 5 gzip 19 ./data \;
find ./subject_videos/ -type f -name "*.mp4" -exec ./collect_data.sh ./videos {} yuv 5 xz 19 ./data \;

gnuplot -e "graph_title='AVG Segment Size'" -e "filename='./data/compression_avg_segment_size_720p.dat'" -e "pow=2" -e "y_mult=5" -e "y_label='MB'" -e "conversion_scale=1e+6" -e "output_filename='./plots/compression_avg_segment_size_720p.png'" plot_script.plg
gnuplot -e "graph_title='AVG Segment Size'" -e "filename='./data/compression_avg_segment_size_1080p.dat'" -e "pow=2" -e "y_mult=5" -e "y_label='MB'" -e "conversion_scale=1e+6" -e "output_filename='./plots/compression_avg_segment_size_1080p.png'" plot_script.plg
gnuplot -e "graph_title='Ratio'" -e "filename='./data/compression_ratio_720p.dat'" -e "pow=0" -e "y_mult=1" -e "y_label='%'" -e "conversion_scale=1" -e "output_filename='./plots/compression_ratio_720p.png'" plot_script.plg
gnuplot -e "graph_title='Ratio'" -e "filename='./data/compression_ratio_1080p.dat'" -e "pow=0" -e "y_mult=1" -e "y_label='%'" -e "conversion_scale=1" -e "output_filename='./plots/compression_ratio_1080p.png'" plot_script.plg
gnuplot -e "graph_title='Time'" -e "filename='./data/compression_time_720p.dat'" -e "pow=2" -e "y_mult=8" -e "y_label='seconds'" -e "conversion_scale=1" -e "output_filename='./plots/compression_time_720p.png'" plot_script.plg
gnuplot -e "graph_title='Time'" -e "filename='./data/compression_time_1080p.dat'" -e "pow=2" -e "y_mult=8" -e "y_label='seconds'" -e "conversion_scale=1" -e "output_filename='./plots/compression_time_1080p.png'" plot_script.plg
