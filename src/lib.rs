pub mod client_handler;
pub mod cmd_args;

use cmd_args::ServerArgs;
use serde::{Deserialize, Serialize};
use std::fs::read_dir;
use std::io;

pub const MAX_CHUNK_LEN: usize = 65507;
pub fn len_to_num_of_chunks(len: u64) -> u64 {
    (len as f64 / MAX_CHUNK_LEN as f64).ceil() as u64
}

#[derive(Debug, Serialize, Deserialize)]
pub enum Compression {
    GZIP,
    LZMA,
    ZSTD,
    XZ,
    LZ4
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VideoInfo {
    pub original_video_name: String,
    pub width: u32,
    pub height: u32,
    pub fps: f32,
    pub duration: f64,
    pub compression: Compression,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum Message {
    GetVideos,
    Videos(Vec<String>),

    GetVideoParts(String),
    VideoParts((VideoInfo, Vec<(String, u64)>, u64)),

    GetVideoPart((String, String)),
    VideoPart(Vec<u8>),
}

impl Message {
    pub async fn handle_server(self, args: &ServerArgs) -> io::Result<Option<Message>> {
        match self {
            Message::GetVideos => Ok(Some(Self::get_videos(args)?)),
            Message::GetVideoParts(video) => Ok(Some(Self::watch_video(args, video).await?)),
            Message::GetVideoPart((video, part)) => {
                Ok(Some(Self::get_video_part(args, video, part).await?))
            }
            _ => {
                tracing::error!("Unexpected Message Type");
                Ok(None)
            }
        }
    }

    fn get_videos(args: &ServerArgs) -> io::Result<Message> {
        let entries: Vec<_> = read_dir(&args.videos_folder)?
            .filter_map(|entry| {
                let entry = entry.ok()?;
                if entry.file_type().ok()?.is_dir() {
                    Some(entry.file_name().into_string().ok()?)
                } else {
                    None
                }
            })
            .collect();

        Ok(Message::Videos(entries))
    }

    async fn watch_video(args: &ServerArgs, video: String) -> io::Result<Message> {
        let video_path = args.videos_folder.join(video);
        let buf = tokio::fs::read(video_path.join("parts.list")).await?;
        let content = String::from_utf8_lossy(&buf);

        let mut parts = Vec::new();
        let mut biggest_num_chunks = 0u64;
        for file_name in content.lines() {
            if file_name.is_empty() {
                continue;
            }
            let file = tokio::fs::File::open(video_path.join(file_name)).await?;
            let num_chunks = len_to_num_of_chunks(file.metadata().await?.len());

            parts.push((file_name.to_string(), num_chunks));
            biggest_num_chunks = std::cmp::max(biggest_num_chunks, num_chunks);
        }

        let buf = tokio::fs::read(video_path.join("info.json")).await?;
        let info: VideoInfo = serde_json::from_slice(&buf).unwrap();
        Ok(Message::VideoParts((info, parts, biggest_num_chunks)))
    }

    async fn get_video_part(args: &ServerArgs, video: String, part: String) -> io::Result<Message> {
        let data = tokio::fs::read(args.videos_folder.join(video).join(part)).await?;
        Ok(Message::VideoPart(data))
    }
}
