# ``FederalRegisterClient``

## Topics

### Creating a client

- ``init(maximumResponseBytes:retrievalTime:transport:userAgent:)``
- ``maximumResponseBytes``
- ``userAgent``

### Retrieving documents and issues

- ``content(_:for:)``
- ``document(_:)``
- ``document(_:fields:)``
- ``documentFacets(_:matching:)``
- ``documents(numbered:fields:)``
- ``issueTableOfContents(on:)``

### Searching documents

- ``documentPages(searching:)``
- ``documentResponses(searching:)``
- ``documents(searching:)``
- ``searchDocuments(matching:)``

### Searching presidential documents

- ``documentPages(matching:)``
- ``documentResponses(matching:)``
- ``documents(matching:)``
- ``presidentialDocuments(matching:)``

### Public inspection

- ``currentPublicInspectionDocuments()``
- ``publicInspectionDocument(_:)``
- ``publicInspectionDocuments(availableOn:)``
- ``publicInspectionDocuments(for:)``
- ``publicInspectionDocuments(numbered:)``
- ``publicInspectionDocuments(searching:)``
- ``publicInspectionPages(for:)``
- ``publicInspectionPages(searching:)``
- ``publicInspectionResponses(for:)``
- ``publicInspectionResponses(searching:)``
- ``searchPublicInspectionDocuments(matching:)``

### Discovery

- ``agencies()``
- ``agency(_:)``
- ``suggestedSearch(_:)``
- ``suggestedSearches(section:)``

### Executing requests and endpoints

- ``documentPages(for:)``
- ``documentResponses(for:)``
- ``documents(for:)``
- ``response(for:)-(DocumentRequest<Value>)``
- ``response(for:)-(Endpoint<Value>)``
- ``send(_:)``
- ``value(for:)``
