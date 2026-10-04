#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// Typed projections read raw fields through these accessors. Each returns nil for an incompatible
// JSON kind rather than throwing, so a projection never turns into a decoding failure while the raw
// value stays available in `fields`.
extension JSONValue {
  /// The elements of an array, or nil for another JSON kind.
  var array: [JSONValue]? {
    if case .array(let value) = self { return value }
    return nil
  }

  /// The integral number, or nil for another JSON kind or a number with a fractional part.
  var int: Int? {
    guard case .number(let value) = self else { return nil }
    return Int(value.description)
  }

  /// Every element as an integral number, or nil when the value is not an array or any element is
  /// not an integral number.
  var intArray: [Int]? {
    guard let elements = array else { return nil }
    var values: [Int] = []
    values.reserveCapacity(elements.count)
    for element in elements {
      guard let value = element.int else { return nil }
      values.append(value)
    }
    return values
  }

  /// The members of an object, or nil for another JSON kind.
  var object: [String: JSONValue]? {
    if case .object(let value) = self { return value }
    return nil
  }

  /// Every array element as an object; one incompatible element makes the whole projection nil.
  var objectArray: [[String: JSONValue]]? {
    guard let elements = array else { return nil }
    var result: [[String: JSONValue]] = []
    for element in elements {
      guard let object = element.object else { return nil }
      result.append(object)
    }
    return result
  }

  /// Every element as a string, or nil when the value is not an array or any element is not a string.
  var stringArray: [String]? {
    guard let elements = array else { return nil }
    var values: [String] = []
    values.reserveCapacity(elements.count)
    for element in elements {
      guard let value = element.string else { return nil }
      values.append(value)
    }
    return values
  }
}
