use structopt::StructOpt;

use rusoto_core::Region;
use rusoto_swf::{
    GetWorkflowExecutionHistoryInput, HistoryEvent, Swf, SwfClient, WorkflowExecution,
};

#[derive(StructOpt)]
struct Cli {
    domain: String,
    workflow_id: String,
    run_id: String,

    #[structopt(parse(from_os_str))]
    dot_path: std::path::PathBuf,
}

fn download_history(
    domain: String,
    workflow_id: String,
    run_id: String,
) -> std::vec::Vec<HistoryEvent> {
    let client = SwfClient::new(Region::UsEast1);
    let execution = WorkflowExecution {
        run_id: run_id,
        workflow_id: workflow_id,
    };

    let get_history_input = GetWorkflowExecutionHistoryInput {
        domain: domain,
        execution: execution,
        ..GetWorkflowExecutionHistoryInput::default()
    };

    match client
        .get_workflow_execution_history(get_history_input)
        .sync()
    {
        Ok(output) => {
            return output.events;
        }
        Err(error) => {
            panic!("Error: {:?}", error);
        }
    }
}

fn main() {
    let args = Cli::from_args();

    println!(
        "Generating DOT file for domain={} workflow_id={} run_id={}",
        args.domain, args.workflow_id, args.run_id
    );

    // Download workflow history using rusoto
    let events = download_history(args.domain, args.workflow_id, args.run_id);

    let dot_str = swf_graph_generator::generate_graph_definition(events);

    // Generate a DOT file for the workflow execution
}
