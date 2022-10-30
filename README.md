# The Project
TODO

# Folder structure
```
./
|_Cargo.toml
|_...
|_<videos folder>
  |_<video name 1>
  | |_parts.list
  | |_<video 1 parts ...>
  |_<video name 2>
  | |_parts.list
  | |_<video 2 parts ...>
  |_...
```
# Ingesting video files
1. Install the required dependencies: `sudo apt install -y parallel ffmpeg zstd`
2. Run: `./ingest.sh "<videos folder>" "<video>" <yuv|rgb> <segment time> <zstd|gzip|xz|lzma|lz4> <compression level>`
	* Segment time: Time in seconds of each segment (usually between 2-10)
	* Compression level: Compression level used by zstd (between 1-19)

# How to run
Right now the client will ask for a random video, but in the future this will change
* **Server**: `[RUST_LOG=<debug|trace>] cargo run [--release] --bin server -- -v=<folder path>`
* **Client**: `[RUST_LOG=<debug|trace>] cargo run [--release] --bin client`

# Generating plot
1. `find ./subject_videos/ -type f -name "*.mp4" -exec ./gen_data.sh ./videos {} yuv 5 gzip 19 ./data \;`
2. `gnuplot -e "graph_title='AVG Segment Size'" -e "filename='./data/compression_avg_segment_size_720p'" -e "pow=2" -e "y_label='MB'" -e "conversion_scale=1e+6" -e "output_filename='output.png'" plot_script.plg`

# Documentation
* Install Rust: https://www.rust-lang.org/tools/install
* Rust std doc: https://doc.rust-lang.org/std/
* Tokio doc: https://tokio.rs/
* Rust by example: https://doc.rust-lang.org/rust-by-example/index.html
* Rust book: https://doc.rust-lang.org/book/title-page.html
* Crates: https://crates.io/
