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
2. Run: `./ingest.sh "<videos folder>" "<video>" <yuv|rgb> <segment time> <zstd|gzip|xz|lzma|lz4> <compression level> [<data folder>]`
	* Segment time: Time in seconds of each segment (usually between 2-10)
	* Compression level: Compression level used by zstd (between 1-19)

# How to run
Right now the client will ask for a random video, but in the future this will change
* **Server**: `[RUST_LOG=<debug|trace>] cargo run [--release|--release-max] --bin server -- -v=<videos folder>`
* **Client**: `[RUST_LOG=<debug|trace>] cargo run [--release|--release-max] --bin client -- --video-name=<video name> [--collect-data --data-folder=<data folder>]`

# Generating plot
All of the collected data was generated with segment time of 5 seconds.
1. Generate files following the [exmaple](data/format.example) file:
    * compression_avg_segment_size_<720|1080>p.dat
    * compression_ratio_<720|1080>p.dat
    * compression_time_<720|1080>p.dat
    * decompression_time_<720|1080>p.dat
    * transmission_time_<720|1080>p.dat
    * time_ratio_<720|1080>p.dat
2. Run:
    * `find ./subject_videos/ -type f -name "*.mp4" -exec ./ingest.sh ./videos {} yuv 5 gzip 19 ./data \;`
    * `find ./subject_videos/ -type f -name "*.mp4" -exec ./ingest.sh ./videos {} yuv 5 xz 19 ./data \;`
    * Start the server: `./target/release-max/server -v=./videos`
    * Start the client: `ls videos/ | xargs -t -I {} ./target/release-max/client --video-name={} --collect-data --data-folder=./data`
3. `./gen_plots.sh`

# Documentation
* Install Rust: https://www.rust-lang.org/tools/install
* Rust std doc: https://doc.rust-lang.org/std/
* Tokio doc: https://tokio.rs/
* Rust by example: https://doc.rust-lang.org/rust-by-example/index.html
* Rust book: https://doc.rust-lang.org/book/title-page.html
* Crates: https://crates.io/
