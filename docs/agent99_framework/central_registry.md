# Central Registry

## Overview

The Central Registry is a crucial component of the Agent99 Framework, serving as a centralized hub for agent registration, discovery, and management. Its primary purpose is to facilitate communication and coordination between various agents within the framework, allowing them to register their capabilities and discover other agents with specific skills.

The registry provides a RESTful API that can be implemented in any programming language or web framework that supports HTTPS endpoints. This document outlines the API specifications for implementing a compatible Central Registry.

## API Endpoints

### 1. Health Check

- **Endpoint**: GET /healthcheck
- **Purpose**: Provides a simple health check for the registry service.
- **Response**: JSON object containing the current count of registered agents.
- **Example Response**:
  ```json
  {
    "agent_count": 5
  }
  ```

### 2. Register Agent

- **Endpoint**: POST /register
- **Purpose**: Allows an agent to register itself with the registry, providing its name and capabilities.
- **Request Body**: JSON object containing agent information.
- **Response**: JSON object with a newly generated UUID for the registered agent.
- **Example Request**:
  ```json
  {
    "name": "TextAnalyzer",
    "capabilities": ["sentiment analysis", "named entity recognition"]
  }
  ```
- **Example Response**:
  ```json
  {
    "uuid": "550e8400-e29b-41d4-a716-446655440000"
  }
  ```

### 3. Discover Agents

- **Endpoint**: GET /discover
- **Purpose**: Allows discovery of agents based on a specific capability.
- **Query Parameter**: capability (string)
- **Response**: JSON array of matching agents with their full information.
- **Example Request**: GET /discover?capability=sentiment+analysis
- **Example Response**:
  ```json
  [
    {
      "name": "TextAnalyzer",
      "capabilities": ["sentiment analysis", "named entity recognition"],
      "uuid": "550e8400-e29b-41d4-a716-446655440000"
    }
  ]
  ```

### 4. Withdraw Agent

- **Endpoint**: DELETE /withdraw/:uuid
- **Purpose**: Removes an agent from the registry using its UUID.
- **Response**: 
  - 204 No Content if successful
  - 404 Not Found if the agent UUID is not in the registry
- **Example Request**: DELETE /withdraw/550e8400-e29b-41d4-a716-446655440000

### 5. List All Agents

- **Endpoint**: GET /
- **Purpose**: Retrieves a list of all registered agents.
- **Response**: JSON array containing all registered agents' information.

## Implementation Notes

1. Agent capabilities should be stored and compared in lowercase to ensure case-insensitive matching.
2. The current implementation uses an in-memory array to store agent information. For production use, consider using a persistent database like SQLite or a more scalable solution.
3. The discovery process currently uses simple keyword matching. Future enhancements could include semantic matching for more accurate agent discovery.

## Potential Enhancements

1. **Persistent Storage**: Implement a database backend for storing agent information, ensuring data persistence across server restarts.
2. **Authentication and Authorization**: Add security measures to protect sensitive endpoints and ensure only authorized agents can register or withdraw.
3. **Semantic Matching**: Enhance the discovery process with natural language processing or vector search capabilities for more intelligent agent matching.
4. **Agent Health Monitoring**: Implement periodic health checks on registered agents to ensure they are still active and available.
5. **Versioning**: Add support for agent versioning to manage different versions of agents with similar capabilities.
6. **Pagination**: Implement pagination for the discovery and list all endpoints to handle large numbers of agents efficiently.
7. **Metrics and Logging**: Add comprehensive logging and metrics collection for better monitoring and debugging of the registry service.
8. **API Rate Limiting**: Implement rate limiting to prevent abuse and ensure fair usage of the registry service.

By implementing this API, developers can create a compatible Central Registry for the Agent99 Framework in their preferred language or framework, enabling seamless integration and communication between diverse agents in the ecosystem.

