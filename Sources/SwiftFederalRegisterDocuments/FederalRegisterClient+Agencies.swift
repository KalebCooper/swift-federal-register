import SwiftFederalRegisterDocumentsModels

extension FederalRegisterClient {
  /// Retrieves the complete FederalRegister.gov agency list in one request.
  ///
  /// The provider returns every agency in a single response, so there is no page sequence and no
  /// follow-up request. Order and duplicates are the provider's. Logos and agency links are
  /// retained as source strings and never fetched.
  ///
  /// ```swift
  /// let list = try await client.agencies()
  /// let epa = list.agencies.first { $0.slug == .environmentalProtectionAgency }
  /// ```
  ///
  /// - Returns: The agency list, equal to `value(for: .agencies())` and `send(.agencies())`.
  /// - Throws: `FederalRegisterError.transport` for HTTP, transport, or cancellation failures,
  ///   `FederalRegisterError.responseTooLarge` above the client's limit, or
  ///   `FederalRegisterError.decoding` when the body is not an array of JSON objects.
  public func agencies() async throws(FederalRegisterError) -> AgencyList {
    try await value(for: .agencies())
  }

  /// Retrieves one agency by slug, including slugs not in the recorded catalog.
  ///
  /// The slug is validated before any request forms. An unknown but well-formed slug is sent, and
  /// the provider's HTTP failure, with its status and body, is returned as a transport failure.
  /// Child and parent agencies are not fetched.
  ///
  /// ```swift
  /// let epa = try await client.agency(.environmentalProtectionAgency)
  /// print(epa.name ?? "", epa.id ?? 0)
  /// ```
  ///
  /// - Parameter identifier: The agency slug.
  /// - Returns: The agency detail, equal to `value(for:)` with `DocumentRequest.agency(_:)`.
  /// - Throws: `FederalRegisterError.validation` with
  ///   `DocumentValidationError.invalidAgencyIdentifier` before sending for a malformed slug;
  ///   otherwise the same `transport`, `responseTooLarge`, and `decoding` failures as `agencies()`.
  public func agency(_ identifier: AgencyIdentifier) async throws(FederalRegisterError)
    -> FederalRegisterAgency
  {
    let request: DocumentRequest<FederalRegisterAgency>
    do { request = try .agency(identifier) } catch { throw .validation(error) }
    return try await value(for: request)
  }
}
