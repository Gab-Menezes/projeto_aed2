use tokio::net::UdpSocket;
use std::io;
use std::sync::Arc;

#[tokio::main]
async fn main() -> io::Result<()> {
    let my_sock = Arc::new(UdpSocket::bind("0.0.0.0:8080").await?);

    for i in 0..12 {
        let sock = my_sock.clone();
        tokio::spawn(async move {
            let mut buf = [0; 1024];
            loop {
                let (len, addr) = sock.recv_from(&mut buf).await.unwrap();
                println!("({i})  {:?} bytes received from {:?}", len, addr);
        
                let len = sock.send_to(&buf[..len], addr).await.unwrap();
                println!("{:?} bytes sent", len);
            }
        });
    }

    loop {
    }

    Ok(())
}
