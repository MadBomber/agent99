# v0.0.4 is a Breaking Change

## Before

Each agent was required to implement a `capabilities` method that returned an Array of Strings in which the elements of the array were essentially synonyms describing the thing that the agent does.  The roadmap calls for this capabilities structure to become an unstructured String in which semmantic search will be used for discovery rather than exact matches.

## After

The **capabilities** is now just one of several within a Hash collection returned by a new method named `info` representing the agent's information packet.  The entire packet will be returned by the central regristry when the agent is discovered.

The capabilities element of this new `info` hash still has the same requirement of being an Array of Strings with a promiss of becoming more later as the system becomes more sophisticated.

The required elements of the `info` Hash are:

- **name** -- automaticall derived from the class name of the agent.
- **type** -- one of server, client or hybrid.
- **capabilities** -- An Array of Strings
- **request_schema** -- is required when the type is server

The keys to the `info` Hash are Symbols.

### Modivation

The goal is to be able to mix and match multiple agents created by different developers in different languages within the context of the protocols and APIs of the Agent99 Framework.  To that end it seems reasonable that agents would have a need to share more than just their capabilitieis.  For example, their JSON schema for their request, response and control messages might also be something worth sharing.


