
use std::fs::File;
use std::error::Error;
use std::io::{Read, Write};
use simple_home_dir::*;
use std::path::Path;
use serde::{Deserialize, Serialize};

pub const CONFFILE: &str = "isotope.config";

#[derive(Serialize, Deserialize, Debug)]
pub struct Conf {
    pub cloud: String,
}
pub fn get_conf_path() -> String {
    let home = home_dir().unwrap();
    let mut confpath = home.to_str().unwrap().to_string();
    confpath.push('/');
    confpath.push_str(CONFFILE);
    confpath
}
pub fn save_config(config: Conf) -> Result<(),Box<dyn Error>>{
    let p = get_conf_path();
    let s = serde_json::to_string(&config)?;
    let mut f = std::fs::OpenOptions::new().write(true).truncate(true).open(p.as_str())?;
    f.write_all(s.as_bytes())?;
    f.flush()?;
    Ok(())
}
pub fn get_or_create_config() -> Result<Conf,Box<dyn Error>> {
    let p = get_conf_path();
    let c = Conf { cloud: String::new(), };
    if !Path::new(&p).exists() {
        let mut f = File::create(&p)?;
        let s = serde_json::to_string(&c)?;
        f.write_all(s.as_bytes())?;
    }else {
        let mut f = File::open(p)?;
        let mut data = String::new();
        f.read_to_string(&mut data)?;
        let loaded_config: Conf = serde_json::from_str(data.as_str())?;
        return Ok(loaded_config)
    }
    Ok(c)
}
#[test]
fn test_config() {
    let p = get_conf_path();
    assert_ne!(p.len(),0);
    assert_eq!(p.contains(CONFFILE), true);
}