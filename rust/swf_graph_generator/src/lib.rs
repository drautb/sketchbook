use rusoto_swf::{ HistoryEvent, ActivityTaskCancelRequestedEventAttributes};

pub fn generate_graph_definition(_events: std::vec::Vec<HistoryEvent>) -> String {
    let mut dot = String::from("");
    dot.push_str("digraph G {");
    return dot;
}

fn node_shape(event: HistoryEvent) -> String {
    let shape = match event.activity_task_cancel_requested_event_attributes { ActivityTaskCancelRequestedEventAttributes => "box" };
    return String::from(shape);
}