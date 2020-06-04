def localize_create_stack(f): f |
  # Get the events out of splunk format
  {
    stackName: .requestParameters.stackName,
    stackId: .responseElements.stackId,
    created: .eventTime | fromdate |
      # Subtract an hour for DST
      (. = . - 3600) |
      localtime | strflocaltime("%Y-%m-%d %H:%M:%S")
  };