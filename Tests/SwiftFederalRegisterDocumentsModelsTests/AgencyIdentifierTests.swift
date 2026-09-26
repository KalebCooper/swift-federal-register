import Foundation
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct AgencyIdentifierTests {
  private enum ConsumerAgency: String {
    case epa = "environmental-protection-agency"
    case future = "future-agency"
  }

  @Test("A consumer-defined string-backed value converts without losing its slug")
  func aConsumerDefinedStringBackedValueConvertsWithoutLosingItsSlug() {
    #expect(AgencyIdentifier(ConsumerAgency.epa) == .environmentalProtectionAgency)
    #expect(AgencyIdentifier(ConsumerAgency.future).rawValue == "future-agency")
  }

  @Test("A generated member's raw value is its official slug")
  func aGeneratedMembersRawValueIsItsOfficialSlug() {
    #expect(AgencyIdentifier.agricultureDepartment.rawValue == "agriculture-department")
    #expect(
      AgencyIdentifier.environmentalProtectionAgency.rawValue == "environmental-protection-agency")
    #expect(
      AgencyIdentifier.healthAndHumanServicesDepartment.rawValue
        == "health-and-human-services-department")
    #expect(AgencyIdentifier.action.rawValue == "action")
  }

  @Test("An identifier encodes as a bare JSON string and decodes to a catalog member")
  func anIdentifierEncodesAsABareJSONStringAndDecodesToACatalogMember() throws {
    let encoded = try JSONEncoder().encode(AgencyIdentifier.environmentalProtectionAgency)
    #expect(String(decoding: encoded, as: UTF8.self) == "\"environmental-protection-agency\"")
    let decoded = try JSONDecoder().decode(
      AgencyIdentifier.self, from: Data("\"health-and-human-services-department\"".utf8))
    #expect(decoded == .healthAndHumanServicesDepartment)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(AgencyIdentifier.self, from: Data("42".utf8))
    }
  }

  @Test("An unknown slug round-trips through construction and JSON unchanged")
  func anUnknownSlugRoundTripsThroughConstructionAndJSONUnchanged() throws {
    let unknown = AgencyIdentifier(rawValue: "future-agency")
    #expect(unknown.rawValue == "future-agency")
    let encoded = try JSONEncoder().encode(unknown)
    #expect(String(decoding: encoded, as: UTF8.self) == "\"future-agency\"")
    #expect(try JSONDecoder().decode(AgencyIdentifier.self, from: encoded) == unknown)
    #expect(unknown != .environmentalProtectionAgency)
  }
}
