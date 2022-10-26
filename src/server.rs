use bincode::Options;
use clap::Parser;
use std::io;
use std::sync::Arc;
use tokio::net::UdpSocket;
use udp_compression::{cmd_args::ServerArgs, len_to_num_of_chunks, Message, MAX_CHUNK_LEN};

#[tokio::main]
async fn main() -> io::Result<()> {
    console_subscriber::init();

    let args = ServerArgs::parse();

    let cpus = num_cpus::get();
    let sock = Arc::new(UdpSocket::bind("0.0.0.0:8080").await?);
    let mut tasks = Vec::with_capacity(cpus);

    for _ in 0..cpus {
        let sock = sock.clone();
        let args = args.clone();
        let t = tokio::spawn(async move {
            let opt = bincode::options();
            let mut buf = [0; 8 * 1024];
            loop {
                let (len, addr) = sock.recv_from(&mut buf).await.unwrap();
                let message: Message = opt.deserialize(&buf[..len]).unwrap();
                let response_msg = message.handle_server(&args).await;
                match response_msg {
                    Ok(response) => match response {
                        Some(msg) => {
                            match msg {
                                Message::VideoPart(data) => {
                                    tokio::spawn(async move {
                                        let stream_sock =
                                            UdpSocket::bind("0.0.0.0:0").await.unwrap();
                                        stream_sock.connect(addr).await.unwrap();
                                        let num_chunks = len_to_num_of_chunks(data.len() as u64);
                                        let mut total_bytes = 0;
                                        let mut chunk_idx = 0;
                                        let mut ack_buff = [0; 10];

                                        tracing::debug!("Begin stream to {addr}");
                                        let begin_time = std::time::Instant::now();
                                        for d in data.chunks(MAX_CHUNK_LEN) {
                                            chunk_idx += 1;
                                            let chunck_len = d.len();
                                            tracing::trace!("Chunk({chunk_idx}/{num_chunks}) Sending chunk with {chunck_len} bytes to client {addr}");
                                            total_bytes += stream_sock.send(&d).await.unwrap();
                                            tracing::trace!("Chunk({chunk_idx}/{num_chunks}) Waiting ack from client {addr}");
                                            stream_sock.recv_from(&mut ack_buff).await.unwrap();
                                        }
                                        tracing::debug!("End stream to {addr} ({total_bytes} bytes in {chunk_idx} chunks) in {:?}", begin_time.elapsed());
                                    });
                                }
                                _ => {
                                    let data = opt.serialize(&msg).unwrap();
                                    sock.send_to(&data, addr).await.unwrap();
                                }
                            };
                        }
                        None => {
                            tracing::error!("Empty response");
                        }
                    },
                    Err(err) => {
                        tracing::error!("Error while generating response {}", err);
                    }
                }
            }
        });
        tasks.push(t);
    }

    for t in tasks {
        t.await?;
    }

    Ok(())
}
