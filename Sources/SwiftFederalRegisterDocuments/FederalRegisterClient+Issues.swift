import SwiftFederalRegisterDocumentsModels

extension FederalRegisterClient {
  /// Retrieves one daily issue hierarchy; references are not fetched automatically.
  /// - Parameter date: A real Gregorian YYYY-MM-DD issue date.
  /// - Returns: The source hierarchy and metadata.
  /// - Throws: `FederalRegisterError.validation` for invalid input, or execution failures including 404.
  public func issueTableOfContents(on date: String) async throws(FederalRegisterError)
    -> IssueTableOfContents
  {
    let request: DocumentRequest<IssueTableOfContents>
    do { request = try .issueTableOfContents(on: date) } catch { throw .validation(error) }
    return try await value(for: request)
  }
}
