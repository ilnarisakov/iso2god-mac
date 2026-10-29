// cover <TITLE_ID_HEX> <DEST_DIR>: downloads the cover from XboxUnity and writes GC<TITLE_ID>.asset
use libaustralis::aurora::assets::{Asset, AssetType, TextureFormat};
use libaustralis::xboxunity::{cover_image_bytes, cover_info, CoverSize};
use std::path::Path;

#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 3 {
        eprintln!("usage: cover <TITLE_ID_HEX> <DEST_DIR>");
        std::process::exit(2);
    }
    if let Err(e) = run(&args[1], Path::new(&args[2])).await {
        eprintln!("cover: {e}");
        std::process::exit(1);
    }
}

async fn run(tid_hex: &str, dest: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let tid = usize::from_str_radix(tid_hex.trim_start_matches("0x"), 16)?;
    let info = cover_info(tid).await.map_err(|e| e.to_string())?;
    // ponytail: first official cover, else first listed; add rating-based pick if covers look bad
    let c = info
        .covers
        .iter()
        .find(|c| matches!(c.official.as_str(), "1" | "true" | "True"))
        .or(info.covers.first())
        .ok_or("no covers found on XboxUnity for this Title ID")?;
    let bytes = cover_image_bytes(c.cover_id, CoverSize::Large).await.map_err(|e| e.to_string())?;
    let img = image::load_from_memory(&bytes)?;

    let mut asset = Asset::new();
    asset.set_image(img, AssetType::Boxart, TextureFormat::BC3).map_err(|e| e.to_string())?;
    let out = dest.join(format!("GC{:08X}.asset", tid));
    asset.save(&out).map_err(|e| e.to_string())?;
    println!("Cover saved: {}", out.display());
    Ok(())
}
