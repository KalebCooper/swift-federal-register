import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ExpandedFailureTests {
  @Test("New operations share failure, receipt, size and cancellation behavior at every level")
  func failures() async throws {
    try await check(.currentPublicInspectionDocuments()) {
      _ = try await $0.currentPublicInspectionDocuments()
    }
    try await check(try .publicInspectionDocuments(availableOn: "2024-12-30")) {
      _ = try await $0.publicInspectionDocuments(availableOn: "2024-12-30")
    }
    try await check(try .publicInspectionDocument("2026-19958")) {
      _ = try await $0.publicInspectionDocument("2026-19958")
    }
    try await check(try .publicInspectionDocuments(numbered: ["2026-19958", "2026-19957"])) {
      _ = try await $0.publicInspectionDocuments(numbered: ["2026-19958", "2026-19957"])
    }
    try await check(.searchPublicInspectionDocuments(matching: try PublicInspectionQuery())) {
      _ = try await $0.searchPublicInspectionDocuments(matching: PublicInspectionQuery())
    }
    try await check(try .documents(numbered: ["93-32104", "2024-31396"])) {
      _ = try await $0.documents(numbered: ["93-32104", "2024-31396"])
    }
    try await check(try .document("93-32104", fields: [.publicationDate])) {
      _ = try await $0.document("93-32104", fields: [.publicationDate])
    }
    try await check(try .issueTableOfContents(on: "2024-12-31")) {
      _ = try await $0.issueTableOfContents(on: "2024-12-31")
    }
    try await check(.documentFacets(.agency, matching: try DocumentSearchQuery())) {
      _ = try await $0.documentFacets(.agency, matching: DocumentSearchQuery())
    }
    try await check(try .suggestedSearches()) { _ = try await $0.suggestedSearches() }
    try await check(try .suggestedSearch(.init(rawValue: "climate-change"))) {
      _ = try await $0.suggestedSearch(.init(rawValue: "climate-change"))
    }
  }

  private func check<Value: DocumentResponse>(
    _ request: DocumentRequest<Value>,
    everyday: @escaping @Sendable (FederalRegisterClient) async throws -> Void
  ) async throws {
    let calls: [@Sendable (FederalRegisterClient) async throws -> Void] = [
      everyday,
      { _ = try await $0.value(for: request) },
      { _ = try await $0.send(request.endpoint) },
      { _ = try await $0.response(for: request) },
    ]
    for call in calls {
      for status in [HTTPResponse.Status.badRequest, .notFound, .tooManyRequests, .found] {
        let body = Data("original failure body".utf8)
        let transport = MockTransport(results: [
          .success(
            Response(
              body: body, headers: [.retryAfter: "12", .location: "https://evil.example"],
              status: status))
        ])
        let client = FederalRegisterClient(transport: transport, userAgent: "test")
        do {
          try await call(client)
          Issue.record("Expected HTTP failure for \(request.endpoint.path)")
        } catch {
          guard
            case .transport(.httpStatus(let bytes, let code, let headers)) = error
              as? FederalRegisterError
          else {
            Issue.record("Wrong failure: \(error)"); continue
          }
          #expect(bytes == body)
          #expect(code == status.code)
          #expect(headers[.retryAfter] == "12")
        }
        #expect(transport.requests.count == 1)
      }
      for limit in [1, 1_000] {
        let transport = MockTransport(results: [
          .success(Response(body: Data("malformed".utf8), status: .ok))
        ])
        let client = FederalRegisterClient(
          maximumResponseBytes: limit, transport: transport, userAgent: "test")
        do {
          try await call(client)
          Issue.record("Expected decoding or size failure")
        } catch {
          if limit == 1 {
            guard case .responseTooLarge(limit: 1) = error as? FederalRegisterError else {
              Issue.record("Wrong size failure: \(error)"); continue
            }
          } else {
            guard case .decoding = error as? FederalRegisterError else {
              Issue.record("Wrong decoding failure: \(error)"); continue
            }
          }
        }
        #expect(transport.requests.count == 1)
      }
      let transport = MockTransport()
      let client = FederalRegisterClient(transport: transport, userAgent: "test")
      await withTaskGroup(of: Void.self) { group in
        group.cancelAll()
        group.addTask {
          do { try await call(client); Issue.record("Expected cancellation") } catch {
            guard case .transport(.cancelled) = error as? FederalRegisterError else {
              Issue.record("Wrong cancellation: \(error)"); return
            }
          }
        }
      }
      #expect(transport.requests.isEmpty)
    }
  }
}
