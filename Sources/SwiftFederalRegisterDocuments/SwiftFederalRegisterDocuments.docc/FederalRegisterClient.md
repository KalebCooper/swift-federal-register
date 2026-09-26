# ``FederalRegisterClient``

## Topics

### Creating a client
- ``init(maximumResponseBytes:retrievalTime:transport:userAgent:)``
- ``maximumResponseBytes``
- ``userAgent``

### Retrieving documents
- ``document(_:)``
- ``content(_:for:)``

### Searching documents
- ``searchDocuments(matching:)``
- ``documentPages(searching:)``
- ``documentResponses(searching:)``
- ``documents(searching:)``

### Searching presidential documents
- ``presidentialDocuments(matching:)``
- ``documentPages(matching:)``
- ``documentResponses(matching:)``
- ``documents(matching:)``

### Discovering agencies
- ``agencies()``
- ``agency(_:)``

### Executing requests and endpoints
- ``value(for:)``
- ``send(_:)``
- ``documentPages(for:)``
- ``documentResponses(for:)``
- ``documents(for:)``
