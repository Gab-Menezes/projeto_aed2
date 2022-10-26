use crate::Message;
use bincode::Options;
use std::{
    io,
    net::{SocketAddr, UdpSocket},
};

pub fn send_recv(
    sock: &UdpSocket,
    server_addrs: &SocketAddr,
    buf: &mut [u8],
    msg: Message,
) -> io::Result<usize> {
    let msg = bincode::options().serialize(&msg).unwrap();

    let sent_bytes = sock.send_to(&msg, server_addrs)?;
    tracing::trace!("Sent {sent_bytes} bytes to server {server_addrs}");

    let (recv_bytes, _) = sock.recv_from(buf)?;
    tracing::trace!("Received {recv_bytes} bytes from server {server_addrs}");

    Ok(recv_bytes)
}

#[macro_export]
macro_rules! send_client {
    ($sock:ident, $server_addrs:ident, $buf:ident, $send_payload:expr, $resp_kind:path) => {{
        let recv_bytes = send_recv(&$sock, &$server_addrs, &mut $buf, $send_payload)?;
        let resp: Message = bincode::options().deserialize(&$buf[..recv_bytes]).unwrap();
        tracing::trace!(?resp);

        match resp {
            $resp_kind(payload) => payload,
            _ => {
                tracing::error!("Unexpected Message Type");
                panic!();
            }
        }
    }};
}
