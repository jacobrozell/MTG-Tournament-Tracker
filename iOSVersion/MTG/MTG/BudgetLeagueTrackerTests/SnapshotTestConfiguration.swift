import Foundation

/// Snapshot test configuration - single source of truth for record mode
enum SnapshotTestConfiguration {
    /// Set to `true` to record new reference snapshots, `false` to assert against them.
    ///
    /// Usage: `assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)`
    static let record = true
}
