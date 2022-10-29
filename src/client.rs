use bincode::Options;
use rand::seq::SliceRandom;
use std::net::SocketAddr;
use std::{io, net::UdpSocket};
use udp_compression::client_handler::send_recv;
use udp_compression::{Message, VideoInfo};
use udp_compression::{send_client, MAX_CHUNK_LEN};

fn main() -> io::Result<()> {
    tracing_subscriber::fmt::init();
    let mut rng = rand::thread_rng();

    let mut buf = [0; 8 * 1024];
    let server_addrs: SocketAddr = "0.0.0.0:8080".parse().unwrap();
    let sock = UdpSocket::bind("0.0.0.0:0")?;
    tracing::trace!("Local address {}", sock.local_addr().unwrap());
    tracing::trace!("Server address {}", server_addrs);

    let videos = send_client!(sock, server_addrs, buf, Message::GetVideos, Message::Videos);
    let video = videos.choose(&mut rng).unwrap().clone();
    tracing::debug!("Choosen video {video}");

    let (info, parts, biggest_number_chunks) = send_client!(
        sock,
        server_addrs,
        buf,
        Message::GetVideoParts(video.clone()),
        Message::VideoParts
    );

    let mut part_buffer = vec![0u8; biggest_number_chunks as usize * MAX_CHUNK_LEN];
    let mut total_bytes = 0;
    let num_parts = parts.len();
    tracing::debug!("Begin stream of video {video}");
    let begin_video_time = std::time::Instant::now();
    for (part, num_chunks) in parts {
        let msg = bincode::options()
            .serialize(&Message::GetVideoPart((video.clone(), part.clone())))
            .unwrap();
        sock.send_to(&msg, server_addrs)?;

        tracing::debug!("Begin stream of part {part} from video {video}");
        let begin_part_time = std::time::Instant::now();
        let mut total_part_bytes = 0;
        for i in 0..num_chunks {
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
        tracing::debug!("End stream of part {part} from video {video} ({total_part_bytes} bytes in {num_chunks} chunks) in {:?}", begin_part_time.elapsed());
    }
    tracing::debug!(
        "End stream of video {video} ({total_bytes} bytes in {num_parts} parts) in {:?}",
        begin_video_time.elapsed()
    );

    Ok(())
}
