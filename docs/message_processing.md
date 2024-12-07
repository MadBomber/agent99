# Agent99 Framework

## Message Processing

Agent99 supports several message types:

- **Request**: Sent by clients to ask for a service or action.
- **Response**: Sent by agents as a reply to a request, containing the results of the action.
- **Control**: Messages that manage the agent’s lifecycle, such as pause, resume, or shutdown.

Messages are routed based on routing keys defined in the messaging system and are processed through a series of callback functions defined in each agent instance. Incoming messages undergo schema validation to ensure they adhere to expected formats using the defined JSON schema.
