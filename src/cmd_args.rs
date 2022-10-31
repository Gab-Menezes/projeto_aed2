use clap::Parser;
use std::path::PathBuf;

#[derive(Debug, Parser, Clone)]
#[command(author, version, about, long_about = None)]
pub struct ServerArgs {
    #[arg(short, long)]
    pub videos_folder: PathBuf,
}

#[derive(Debug, Parser, Clone)]
#[command(author, version, about, long_about = None)]
pub struct ClientArgs {
    #[arg(short, long)]
    pub video_name: String,

    #[arg(short, long)]
    pub collect_data: bool,

    #[arg(short, long)]
    pub data_folder: Option<PathBuf>,
}
