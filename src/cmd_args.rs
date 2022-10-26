use clap::Parser;
use std::path::PathBuf;

#[derive(Debug, Parser, Clone)]
#[command(author, version, about, long_about = None)]
pub struct ServerArgs {
    #[arg(short, long)]
    pub videos_folder: PathBuf,
}
