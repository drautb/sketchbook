use structopt::StructOpt;

#[derive(StructOpt)]
#[structopt(rename_all = "kebab-case")]
struct Arguments {
    /// The text to interpret. 
    text: String,

    /// The language of the text.
    #[structopt(default_value = "", short, long)]
    language_hint: String,

    /// Format of the localized date response.
    #[structopt(default_value="", short, long)]
    format: String,

    /// The language in which to localize the response.
    #[structopt(default_value = "", short, long)]
    accept_language: String,

    /// Hint as to the chronological context of the text.
    #[structopt(default_value = "", short, long)]
    date_hint: String,

    /// Hint as to the type of result expected. (Date, Period, etc)
    #[structopt(default_value = "", short, long)]
    type_hint: String,

    /// Hint as to the underlying calendar associated iwth the date, such as "julian" vs.
    /// "gregorian".
    #[structopt(default_value = "", short, long)]
    calendar_hint: String,

    /// Hint as to the format of the input, such as "DMY" vs. "MDY".
    #[structopt(default_value = "", short, long)]
    input_format_hint: String,

    /// Flag to minimize the response contents.
    #[structopt(short, long)]
    minimal_output: bool,
}

static DATE_HOST: &str = "http://ws.date.standards.service.prod.us-east-1.prod.fslocal.org";

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Arguments::from_args();

    let url = format!("{}/dates/interp?text={}&langHint={}&format={}&acceptLanguage={}&dateHint={}&typeHint={}&calendarHint={}&inputFormatHint={}&minimalOutput={}", DATE_HOST, args.text, args.language_hint, args.format, args.accept_language, args.date_hint, args.type_hint, args.calendar_hint, args.input_format_hint, args.minimal_output);

    let result = reqwest::get(url)
        .await?
        .text()
        .await?;

    print!("{}", result);

    Ok(())
}
