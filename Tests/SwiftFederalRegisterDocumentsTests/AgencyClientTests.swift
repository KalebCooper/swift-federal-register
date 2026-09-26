import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Synchronization
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct AgencyClientTests {
  @Test(
    "A malformed agency slug fails validation before any request",
    arguments: ["", "../x", "a b", "a%2Fb", "a/b"])
  func aMalformedAgencySlugFailsValidationBeforeAnyRequest(_ slug: String) async throws {
    let transport = MockTransport()
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    do throws(FederalRegisterError) {
      _ = try await client.agency(AgencyIdentifier(rawValue: slug))
      Issue.record("Expected validation failure")
    } catch {
      guard case .validation(.invalidAgencyIdentifier(let rejected)) = error else {
        Issue.record("Wrong failure"); return
      }
      #expect(rejected == slug)
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("All three agency detail levels produce the same value and exact request")
  func allThreeAgencyDetailLevelsProduceTheSameValueAndExactRequest() async throws {
    let transport = try transport([.agencyEPA, .agencyEPA, .agencyEPA, .agencyEPA])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let everyday = try await client.agency(.environmentalProtectionAgency)
    let stored = try DocumentRequest.agency(.environmentalProtectionAgency)
    #expect(try await client.value(for: stored) == everyday)
    #expect(try await client.send(.agency(.environmentalProtectionAgency)) == everyday)
    #expect(everyday.id == 145)
    #expect(everyday.name == "Environmental Protection Agency")
    let endpoint = try #require(
      Endpoint<AgencyName>(path: "/api/v1/agencies/environmental-protection-agency.json"))
    #expect(try await client.send(endpoint).name == "Environmental Protection Agency")
    #expect(transport.requests.count == 4)
    for call in transport.requests {
      #expect(call.request.path == "/api/v1/agencies/environmental-protection-agency.json")
      #expect(call.request.headerFields[.accept] == "application/json")
      #expect(call.request.headerFields[.userAgent] == "test-app")
    }
  }

  @Test("All three agency list levels produce the same value and exact request")
  func allThreeAgencyListLevelsProduceTheSameValueAndExactRequest() async throws {
    let transport = try transport([.agencyCatalog, .agencyCatalog, .agencyCatalog])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let everyday = try await client.agencies()
    let stored: DocumentRequest<AgencyList> = .agencies()
    #expect(try await client.value(for: stored) == everyday)
    #expect(try await client.send(.agencies()) == everyday)
    #expect(everyday.agencies.count == 473)
    #expect(everyday.agencies.first?.slug?.rawValue == "action")
    #expect(everyday.agencies.last?.slug?.rawValue == "workers-compensation-programs-office")
    #expect(transport.requests.count == 3)
    for call in transport.requests {
      #expect(call.request.path == "/api/v1/agencies.json")
      #expect(call.request.headerFields[.accept] == "application/json")
      #expect(call.request.headerFields[.userAgent] == "test-app")
    }
  }

  @Test("An agency list receipt retains the exact response bytes in one request")
  func anAgencyListReceiptRetainsTheExactResponseBytesInOneRequest() async throws {
    let transport = try transport([.agencyCatalog])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let receipt = try await client.response(for: DocumentRequest.agencies())
    #expect(receipt.body == (try Fixture.agencyCatalog.data()))
    #expect(receipt.requestURL == "https://www.federalregister.gov/api/v1/agencies.json")
    #expect(receipt.status == 200)
    #expect(
      receipt.publisher == "Office of the Federal Register, NARA; Government Publishing Office")
    #expect(receipt.retrievedAt == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("An oversized agency list fails the response limit after one request")
  func anOversizedAgencyListFailsTheResponseLimitAfterOneRequest() async throws {
    let transport = try transport([.agencyCatalog])
    let client = FederalRegisterClient(
      maximumResponseBytes: 1024, transport: transport, userAgent: "test-app")
    do throws(FederalRegisterError) {
      _ = try await client.agencies()
      Issue.record("Expected size failure")
    } catch {
      guard case .responseTooLarge(limit: 1024) = error else {
        Issue.record("Wrong failure"); return
      }
    }
    #expect(transport.requests.count == 1)
  }

  @Test("An unknown agency slug returns the provider's HTTP failure with its body")
  func anUnknownAgencySlugReturnsTheProvidersHTTPFailureWithItsBody() async throws {
    let body = Data(#"{"status":404,"message":"Record not found"}"#.utf8)
    let transport = MockTransport(results: [.success(Response(body: body, status: .notFound))])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    do throws(FederalRegisterError) {
      _ = try await client.agency(AgencyIdentifier(rawValue: "future-agency"))
      Issue.record("Expected HTTP failure")
    } catch {
      guard case .transport(.httpStatus(let failureBody, let code, _)) = error else {
        Issue.record("Wrong failure"); return
      }
      #expect(code == 404)
      #expect(failureBody == Data(#"{"status":404,"message":"Record not found"}"#.utf8))
    }
    #expect(transport.requests.count == 1)
    #expect(transport.last?.request.path == "/api/v1/agencies/future-agency.json")
  }

  @Test("Cancellation before sending makes no agency request")
  func cancellationBeforeSendingMakesNoAgencyRequest() async throws {
    let transport = MockTransport()
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    await withTaskGroup(of: Void.self) { group in
      group.cancelAll()
      group.addTask {
        do throws(FederalRegisterError) {
          _ = try await client.agencies()
          Issue.record("Expected cancellation")
        } catch {
          guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
        }
      }
      group.addTask {
        do throws(FederalRegisterError) {
          _ = try await client.agency(.environmentalProtectionAgency)
          Issue.record("Expected cancellation")
        } catch {
          guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
        }
      }
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("Cancellation while an agency request is in flight fails as cancelled")
  func cancellationWhileAnAgencyRequestIsInFlightFailsAsCancelled() async throws {
    let transport = MockTransport()
    let body = try Fixture.agencyEPA.data()
    let running = RunningTask()
    transport.setHandler(forPath: "/api/v1/agencies/environmental-protection-agency.json") { _ in
      running.task.withLock { $0?.cancel() }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let (start, starter) = AsyncStream<Void>.makeStream()
    let task = Task { () -> FederalRegisterError? in
      for await _ in start { break }
      do throws(FederalRegisterError) {
        _ = try await client.agency(.environmentalProtectionAgency)
        return nil
      } catch { return error }
    }
    running.task.withLock { $0 = task }
    starter.yield()
    starter.finish()
    let failure = await task.value
    guard case .transport(.cancelled) = failure else {
      Issue.record("Expected cancellation, got \(String(describing: failure))"); return
    }
    #expect(transport.requests.count == 1)
  }

  private func transport(_ fixtures: [Fixture]) throws -> MockTransport {
    MockTransport(
      results: try fixtures.map {
        .success(
          Response(body: try $0.data(), headers: [.contentType: "application/json"], status: .ok))
      })
  }
}

private struct AgencyName: Decodable, DocumentResponse { let name: String }

/// Holds the task a transport handler cancels while its request is in flight.
private final class RunningTask: Sendable {
  let task = Mutex<Task<FederalRegisterError?, Never>?>(nil)
}
