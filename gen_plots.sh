#!/bin/bash
gnuplot -e "graph_title='Tempo de Compressão 720p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/compression_time_720p.dat'" -e "pow=2" -e "y_mult=8" -e "y_label='segundos'" -e "conversion_scale=1" -e "output_filename='./plots/compression_time_720p.png'" plot_script.plg
gnuplot -e "graph_title='Tempo de Compressão 1080p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/compression_time_1080p.dat'" -e "pow=2" -e "y_mult=8" -e "y_label='segundos'" -e "conversion_scale=1" -e "output_filename='./plots/compression_time_1080p.png'" plot_script.plg
gnuplot -e "graph_title='Tamanho Medio Segmento 720p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/compression_avg_segment_size_720p.dat'" -e "pow=2" -e "y_mult=5" -e "y_label='MB'" -e "conversion_scale=1e+6" -e "output_filename='./plots/compression_avg_segment_size_720p.png'" plot_script.plg
gnuplot -e "graph_title='Tamanho Medio Segmento 1080p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/compression_avg_segment_size_1080p.dat'" -e "pow=2" -e "y_mult=5" -e "y_label='MB'" -e "conversion_scale=1e+6" -e "output_filename='./plots/compression_avg_segment_size_1080p.png'" plot_script.plg
gnuplot -e "graph_title='Taxa de Compressão (Comprimido/Descomprimido) 720p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/compression_ratio_720p.dat'" -e "pow=0" -e "y_mult=1" -e "y_label=''" -e "conversion_scale=1" -e "output_filename='./plots/compression_ratio_720p.png'" plot_script.plg
gnuplot -e "graph_title='Taxa de Compressão (Comprimido/Descomprimido) 1080p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/compression_ratio_1080p.dat'" -e "pow=0" -e "y_mult=1" -e "y_label=''" -e "conversion_scale=1" -e "output_filename='./plots/compression_ratio_1080p.png'" plot_script.plg

gnuplot -e "graph_title='Tempo de Descompressão 720p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/decompression_time_720p.dat'" -e "pow=1" -e "y_mult=7" -e "y_label='segundos'" -e "conversion_scale=1" -e "output_filename='./plots/decompression_time_720p.png'" plot_script.plg
gnuplot -e "graph_title='Tempo de Descompressão 1080p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/decompression_time_1080p.dat'" -e "pow=1" -e "y_mult=7" -e "y_label='segundos'" -e "conversion_scale=1" -e "output_filename='./plots/decompression_time_1080p.png'" plot_script.plg
gnuplot -e "graph_title='Tempo de Transmissão 720p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/receive_time_720p.dat'" -e "pow=0" -e "y_mult=2.5" -e "y_label='segundos'" -e "conversion_scale=1" -e "output_filename='./plots/receive_time_720p.png'" plot_script.plg
gnuplot -e "graph_title='Tempo de Transmissão 1080p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/receive_time_1080p.dat'" -e "pow=0" -e "y_mult=2.5" -e "y_label='segundos'" -e "conversion_scale=1" -e "output_filename='./plots/receive_time_1080p.png'" plot_script.plg
gnuplot -e "graph_title='(Tempo Descompressão + Tempo Transmissão)/Tempo Vídeo 720p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/useful_ratio_720p.dat'" -e "pow=0" -e "y_mult=2" -e "y_label=''" -e "conversion_scale=1" -e "output_filename='./plots/useful_ratio_720p.png'" plot_script.plg
gnuplot -e "graph_title='(Tempo Descompressão + Tempo Transmissão)/Tempo Vídeo 1080p'" -e "subtitle='Quanto menor melhor'" -e "filename='./data/useful_ratio_1080p.dat'" -e "pow=0" -e "y_mult=2" -e "y_label=''" -e "conversion_scale=1" -e "output_filename='./plots/useful_ratio_1080p.png'" plot_script.plg
