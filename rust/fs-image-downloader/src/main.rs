use std::env;
use std::fs::create_dir_all;
use std::fs::File;
use std::fs::write;
use std::io::{self, BufRead, Write};
use std::path::Path;
use std::thread;

use clap::Parser;
use lazy_static::lazy_static;
use num_cpus;
use regex::Regex;
use reqwest::blocking::Client;
use reqwest::header;
use spmc::channel;


#[derive(Parser)]
#[clap(author, version, about, rename_all = "kebab-case")]
struct Arguments {
    /// The output directory for the downloaded images.
    #[clap(short, long, parse(from_os_str), default_value="images")]
    output_directory: std::path::PathBuf,

    /// File containing a list of images to download.
    #[clap(short, long, parse(from_os_str), conflicts_with="images")]
    image_list: Option<std::path::PathBuf>,

    /// Image identifiers. Valid formats are DGS 9_5s, natural group names followed by 5 digit image numbers, and image APIDs.
    ///
    /// Examples:{n}
    /// - 005634936_00003{n}
    /// - 004367461_001_M9S7-M1L_00542{n}
    /// - TH-1942-21891-11222-99
    #[clap(multiple_values = true)]
    images: Vec<String>,
}

static EOW: &str = "EOW";

static DAS_BASE_URL: &str = "http://dascloud.storage.records.service.prod.us-east-1.prod.fslocal.org/das/v2";
static RMS_BASE_URL: &str = "http://rms.records.service.prod.us-east-1.prod.fslocal.org/";

fn main() {
    let session_id = env::var("FS_SESSION_ID").expect("No session id found! Make sure the FS_SESSION_ID environment variable is set.");
    let client = build_client(&session_id);

    let args = Arguments::parse();
    create_dir_all(args.output_directory).unwrap();
    let core_count = num_cpus::get();

    let (mut tx, rx): (spmc::Sender<String>, spmc::Receiver<String>) = channel();
    let mut handles = Vec::new();
    for _ in 0..core_count {
        let rx = rx.clone();
        let client = client.clone();
        let args = Arguments::parse();
        handles.push(thread::spawn(move || {
            let mut count = 0;
            loop {
                let msg = rx.recv().unwrap();
                if msg.eq(EOW) { break; }
                handle_image(&msg, &client, &args);
                count += 1;
                if count % 10 == 0 {
                    print!(".");
                    std::io::stdout().flush().unwrap();
                }
            }
        }));
    }

    for image in args.images.iter() {
        tx.send(String::from(image)).unwrap();
    }

    match args.image_list {
        Some(image_list) => {
            if let Ok(lines) = read_lines(image_list) {
                for line in lines {
                    if let Ok(image) = line {
                        tx.send(String::from(image)).unwrap();
                    }
                }
            }
        },
        None => ()
    }

    for _ in 0..core_count {
        tx.send(String::from(EOW)).unwrap();
    }

    for handle in handles {
        handle.join().unwrap();
    }
}

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}

fn build_client(session_id: &str) -> Client {
    let mut headers = header::HeaderMap::new();

    let username: String = env::var("USER").expect("No username found! Make sure the USER environment variable is set.");
    headers.insert("User-Agent", header::HeaderValue::from_str(&username).unwrap());
    headers.insert("FS-User-Agent-Chain", header::HeaderValue::from_static("fs-image-downloader"));

    let mut auth_header_value = header::HeaderValue::from_str(&std::format!("Bearer {}", session_id)).unwrap();
    auth_header_value.set_sensitive(true);
    headers.insert(header::AUTHORIZATION, auth_header_value);

    return reqwest::blocking::Client::builder()
        .default_headers(headers)
        .build()
        .unwrap();
}

fn handle_image(image: &str, client: &Client, args: &Arguments) {
    lazy_static! {
        static ref DGS_9_5_PATTERN: Regex = Regex::new("^\\d{9}_\\d{5}$").unwrap();
        static ref NATURAL_GROUP_PATTERN: Regex = Regex::new("^\\d{9}_\\d{3}_(.{8})_(\\d{5})$").unwrap();
    }

    let apid: Option<String>;
    if image.starts_with("TH-") {
        apid = Some(String::from(image));
    } else if DGS_9_5_PATTERN.is_match(image) {
        apid = get_apid_for_95(&image, &client);
    } else if NATURAL_GROUP_PATTERN.is_match(image) {
        let caps = NATURAL_GROUP_PATTERN.captures(image).unwrap();
        let group_id = caps.get(1).unwrap().as_str();
        let image_number = caps.get(2).unwrap().as_str().parse().unwrap();
        apid = get_apid_for_natural_group_image(group_id, image_number, &client);
    } else {
        println!("Unable to resolve APID for '{}', skipping.", image);
        return;
    }

    match apid {
        Some(apid) => download_image(&apid, &image, &client, &args),
        None => (),
    }
}

fn get_apid_for_95(dgs95: &str, client: &Client) -> Option<String> {
    let url = format!("{}/dgs:{}/name?namespace=apid", DAS_BASE_URL, dgs95);
    let result = client.get(url).send();

    return match result {
        Ok(response) =>
            match response.status() {
                reqwest::StatusCode::OK => Some(response.text().unwrap()),
                code => {
                    println!("Unexpected response from APID endpoint for {}: {}", dgs95, code);
                    None
                },
            },

        Err(_) => None,
    };
}

fn get_apid_for_natural_group_image(group_id: &str, image_number: usize, client: &Client) -> Option<String> {
    let result = client.get(format!("{}/artifact/group/{}/children", RMS_BASE_URL, group_id)).send();

    return match result {
        Ok(response) =>
            match response.status() {
                reqwest::StatusCode::OK => {
                    let apid_list: Vec<String> = response.json().unwrap();
                    let apid = apid_list.get(image_number - 1).unwrap();
                    return Some(String::from(apid));
                },
                code => {
                    println!("Unexpected response from RMS children endpoint for {}: {}", group_id, code);
                    None
                },
            },

        Err(_) => None,
    };
}

fn download_image(apid: &str, label: &str, client: &Client, args: &Arguments) {
    let result = client.get(format!("{}/{}/dist.jpg", DAS_BASE_URL, apid)).send();

    match result {
        Ok(response) =>
            match response.status() {
                reqwest::StatusCode::OK => {
                    let file_path = args.output_directory.clone().join(format!("{}.jpg", label));
                    write(file_path, response.bytes().unwrap()).unwrap();
                },
                code => println!("Unexpected response from image download endpoint for {} ({}): {}", apid, label, code),
            },
        Err(_) => (),
    };
}
