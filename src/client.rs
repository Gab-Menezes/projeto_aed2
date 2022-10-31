use bincode::Options;
use clap::Parser;
use flate2::bufread::GzDecoder;
use std::io::Read;
use std::net::SocketAddr;
use std::{io, net::UdpSocket};
use udp_compression::client_handler::send_recv;
use udp_compression::cmd_args::ClientArgs;
use udp_compression::Message;
use udp_compression::{send_client, MAX_CHUNK_LEN};
use xz2::bufread::XzDecoder;

fn main() -> io::Result<()> {
    tracing_subscriber::fmt::init();

    let args = ClientArgs::parse();

    if args.collect_data && args.data_folder.is_none() {
        tracing::error!("Folder argument missing");
        panic!();
    }

    //creates the udp socket
    let mut buf = [0; 8 * 1024];
    let server_addrs: SocketAddr = "0.0.0.0:8080".parse().unwrap();
    let sock = UdpSocket::bind("0.0.0.0:0")?;
    tracing::trace!("Local address {}", sock.local_addr().unwrap());
    tracing::trace!("Server address {}", server_addrs);

    //gets the list of videos from the server
    let videos = send_client!(sock, server_addrs, buf, Message::GetVideos, Message::Videos);
    let video = args.video_name;
    if !videos.contains(&video) {
        tracing::error!("Video not found");
        panic!();
    }
    tracing::debug!("Choosen video {video}");

    //gets the parts of the selected video
    let (video_info, parts, biggest_number_chunks) = send_client!(
        sock,
        server_addrs,
        buf,
        Message::GetVideoParts(video.clone()),
        Message::VideoParts
    );

    let num_runs = if args.collect_data { 5 } else { 1 };

    let mut total_trasmission_time = 0f64;
    let mut total_decompress_time = 0f64;
    let mut total_recv_decomp_time = 0f64;
    for _ in 0..num_runs {
        //creates buffer to receive the parts, based on the biggest part
        let mut part_buffer = vec![0u8; biggest_number_chunks as usize * MAX_CHUNK_LEN];
        let mut total_bytes = 0;
        let num_parts = parts.len();

        //begin the video stream
        tracing::debug!("Begin stream of video {video}");
        let begin_recv_decomp_time = std::time::Instant::now();
        for (part, num_chunks) in &parts {
            //request the part
            tracing::debug!("Begin stream of part {part} from video {video}");
            let begin_transmission_time = std::time::Instant::now();

            let msg = bincode::options()
                .serialize(&Message::GetVideoPart((video.clone(), part.clone())))
                .unwrap();
            sock.send_to(&msg, server_addrs)?;

            //receive the part in chunks
            let mut total_part_bytes = 0;
            for i in 0..*num_chunks {
                let begin = i as usize * MAX_CHUNK_LEN;
                let end = (i + 1) as usize * MAX_CHUNK_LEN;
                let chunk_idx = i + 1;
                tracing::trace!("Chunk({chunk_idx}/{num_chunks}) Waiting for chunk");
                let (recv_bytes, addr) = sock.recv_from(&mut part_buffer[begin..end])?;
                tracing::trace!("Chunk({chunk_idx}/{num_chunks}) Recieved chunk with {recv_bytes} bytes from server {addr}");
                total_bytes += recv_bytes;
                total_part_bytes += recv_bytes;

                tracing::trace!("Chunk({chunk_idx}/{num_chunks}) Sending ack");
                sock.send_to("ack".as_bytes(), addr).unwrap();
            }
            total_trasmission_time += begin_transmission_time.elapsed().as_secs_f64();
            tracing::debug!("End stream of part {part} from video {video} ({total_part_bytes} bytes in {num_chunks} chunks) in {:?}", begin_transmission_time.elapsed());

            //decompress the received part
            let begin_decompress_time = std::time::Instant::now();
            let part_slice = &part_buffer[..total_part_bytes];
            let decompressed_size;
            tracing::debug!("Begin decompressing {part}");
            match video_info.compression {
                udp_compression::Compression::GZIP => {
                    let mut gz = GzDecoder::new(part_slice);
                    let mut decompression_buffer = Vec::new();
                    decompressed_size = gz.read_to_end(&mut decompression_buffer)?;
                }
                udp_compression::Compression::XZ => {
                    let mut xz = XzDecoder::new(part_slice);
                    let mut decompression_buffer = Vec::new();
                    decompressed_size = xz.read_to_end(&mut decompression_buffer)?;
                }
                _ => {
                    tracing::error!("Compression method not implemented");
                    panic!();
                }
            }
            total_decompress_time += begin_decompress_time.elapsed().as_secs_f64();
            tracing::debug!(
                "Decompressed {part} to {decompressed_size} bytes in {:?}",
                begin_decompress_time.elapsed()
            );
        }
        total_recv_decomp_time += begin_recv_decomp_time.elapsed().as_secs_f64();
        tracing::debug!(
            "End stream of video {video} ({total_bytes} bytes in {num_parts} parts) in {:?}",
            begin_recv_decomp_time.elapsed()
        );
    }

    if args.collect_data {
        //calculate the data
        let avg_decompress_time = total_decompress_time / num_runs as f64;
        let avg_transmission_time = total_trasmission_time / num_runs as f64;

        let avg_recv_decomp_time = total_recv_decomp_time / num_runs as f64;
        let time_ratio = avg_recv_decomp_time / video_info.duration;

        //get the folder, extension, generate the replace string
        let folder = args.data_folder.unwrap();
        let ext = match video_info.compression {
            udp_compression::Compression::GZIP => "gz",
            udp_compression::Compression::XZ => "xz",
            _ => {
                tracing::error!("Compression method not implemented");
                panic!();
            }
        };
        let replace = format!("{}_{}", video_info.original_video_name, ext);

        //loop over all files, and replace the search string for the value
        let file_and_data = vec![
            (
                format!("decompression_time_{}p.dat", video_info.height),
                avg_decompress_time,
            ),
            (
                format!("transmission_time_{}p.dat", video_info.height),
                avg_transmission_time,
            ),
            (
                format!("time_ratio_{}p.dat", video_info.height),
                time_ratio,
            ),
        ];
        
        for (file, data) in file_and_data {
            let file_path = folder.join(file);
            let file_data = std::fs::read(&file_path).unwrap();
            let file_data = String::from_utf8(file_data).unwrap();
            let str_data = format!("{:.4}", data);
            let replaced_file_data = file_data.replace(&replace, &str_data);
            std::fs::write(&file_path, &replaced_file_data).unwrap();
        }
    }

    Ok(())
}
