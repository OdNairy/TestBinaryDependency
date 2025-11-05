import Foundation

/// A simple test library for demonstrating XCFramework signature updates
public class TestLibrary {

    /// The current version of the library
    public static let version = "1.0.0"

    /// Initialize the library
    public init() {}

    /// Greet a user with their name
    /// - Parameter name: The name to greet
    /// - Returns: A greeting message
    public func greet(name: String) -> String {
        return "Hello, \(name)! This is TestLibrary v\(TestLibrary.version)"
    }

    /// Get the current timestamp
    /// - Returns: Current date and time as a string
    public func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: Date())
    }

    /// Simple calculation method for testing
    /// - Parameters:
    ///   - a: First number
    ///   - b: Second number
    /// - Returns: Sum of two numbers
    public func add(_ a: Int, _ b: Int) -> Int {
        return a + b
    }
}