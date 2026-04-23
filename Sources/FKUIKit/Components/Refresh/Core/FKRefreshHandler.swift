import Foundation

/// Async refresh callback running on the main actor.
public typealias FKRefreshAsyncHandler = @MainActor () async throws -> Void

/// Callback with action context including task token and source.
public typealias FKRefreshActionHandler = @MainActor (_ context: FKRefreshActionContext) -> Void

/// Async callback with action context including task token and source.
public typealias FKRefreshContextAsyncHandler = @MainActor (_ context: FKRefreshActionContext) async throws -> Void
