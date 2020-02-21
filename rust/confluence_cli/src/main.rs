use base64::encode;
use reqwest::blocking::Client;
use reqwest::header::{ACCEPT, AUTHORIZATION};
use reqwest::Url;
use serde::Deserialize;
use structopt::StructOpt;

#[derive(StructOpt, Debug)]
struct Cli {
    #[structopt(env = "CONFLUENCE_HOST")]
    host: String,

    #[structopt(env = "CONFLUENCE_USER")]
    user: String,

    #[structopt(env = "CONFLUENCE_PASSWORD", hide_env_values = true)]
    password: String,

    #[structopt(short, long)]
    dry_run: bool,

    #[structopt(short, long)]
    verbose: bool,

    #[structopt(subcommand)]
    cmd: Command,
}

#[derive(StructOpt, Debug)]
enum Command {
    #[structopt(about = "Add a watch to the given page, as well as all child pages.")]
    WatchTree {
        #[structopt(short, long)]
        content_id: String,
    },
}

#[derive(Deserialize, Debug)]
struct ChildList {
    results: Vec<Page>,
    start: u8,
    size: u8,
    limit: u8,
}

#[derive(Deserialize, Debug)]
struct Page {
    id: String,
    title: String,
}

fn main() {
    let args = Cli::from_args();
    let client = Client::new();

    match args.cmd {
        Command::WatchTree {
            content_id: ref cid,
        } => watch_tree(&args, &cid, &client),
    }
}

fn watch_tree(args: &Cli, cid: &String, client: &Client) {
    println!("Watching all content under '{}'", cid);

    let ids = collect_all_children(args, cid, client);

    watch_all_ids(args, &ids, client);
}

fn collect_all_children(args: &Cli, cid: &String, client: &Client) -> Vec<String> {
    if args.verbose {
        println!("Collecting content ids...");
    }

    let mut all_ids: Vec<String> = Vec::new();

    let mut id_queue: Vec<String> = Vec::new();
    id_queue.push(cid.to_string());

    while id_queue.len() > 0 {
        match id_queue.pop() {
            Some(ref id) => {
                all_ids.push(id.to_string());

                let children = get_content_children(args, &id, client);
                for c in children.results {
                    id_queue.push(c.id);
                }
            }
            None => break,
        }
    }

    if args.verbose {
        println!("Found {} pages that are children of {}", all_ids.len(), cid);
    }

    return all_ids;
}

fn watch_all_ids(args: &Cli, ids: &Vec<String>, client: &Client) {
    for id in ids {
        watch_id(args, id, client);
    }
}

fn watch_id(args: &Cli, id: &String, client: &Client) {
    if args.verbose {
        let mut dry_run = "LIVE";
        if args.dry_run {
            dry_run = "DRY RUN";
        }
        println!("[{}] Watching content. id={}", dry_run, id);
    }

    let url_str = format!("https://{}/rest/api/user/watch/content/{}", args.host, id);
    let url = Url::parse(&url_str).unwrap();
    let auth_header = build_authorization_header_value(&args);

    let response = client
        .post(url)
        .header(ACCEPT, "application/json")
        .header(AUTHORIZATION, auth_header)
        .header("X-Atlassian-Token", "no-check")
        .send()
        .unwrap();

    if response.status() != 200 {
        panic!(
            "Non-200 response from watch endpoint. id={} response={:?}",
            id, response
        );
    }
}

fn get_content_children(args: &Cli, cid: &String, client: &Client) -> ChildList {
    let url_str = format!("https://{}/rest/api/content/{}/child/page", args.host, cid);
    let url = Url::parse(&url_str).unwrap();
    let auth_header = build_authorization_header_value(&args);

    let response = client
        .get(url)
        .header(ACCEPT, "application/json")
        .header(AUTHORIZATION, auth_header)
        .send()
        .unwrap();

    return response.json().unwrap();
}

fn build_authorization_header_value(args: &Cli) -> String {
    let creds = format!("{}:{}", &args.user, &args.password);
    return format!("Basic {}", encode(&creds));
}
