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
# Generate **parts.list** and each video part
This probably will be automated
1. Create a folder inside with the video name inside `<videos folder>`
2. Copy the video file to this folder
3. `cd` into the folder
4. To generate **parts.list** and each part, run: 
    * For **yuv** files: `time ffmpeg -i <video name> -an -map 0 -segment_time <segment time> -f segment -segment_list parts.list part%03d.yuv`
    * For **rgb** files: `time ffmpeg -i <video name> -an -pix_fmt rgb8 -map 0 -segment_time <segment time> -f segment -segment_list parts.list part%03d.rgb`
5. To compress this parts, run:
    * `time find . -type f -name 'part*.<yuv|rgb>' | parallel -j $(nproc) gzip -v -k {}`

# How to run
Right now the client will ask for a random video, but in the future this will change
* **Server**: `[RUST_LOG=<debug|trace>] cargo run [--release] --bin server -- -v=<folder path>`
* **Client**: `[RUST_LOG=<debug|trace>] cargo run [--release] --bin client`

# Documentation
* Install Rust: https://www.rust-lang.org/tools/install
* Rust std doc: https://doc.rust-lang.org/std/
* Tokio doc: https://tokio.rs/
* Rust by example: https://doc.rust-lang.org/rust-by-example/index.html
* Rust book: https://doc.rust-lang.org/book/title-page.html
* Crates: https://crates.io/
