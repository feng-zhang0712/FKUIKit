import Foundation

/// Main-actor async work for a refresh action; pair with ``FKRefreshConfiguration/automaticallyEndsRefreshingOnAsyncCompletion`` or call `end*` yourself.
public typealias FKRefreshAsyncHandler = @MainActor () async throws -> Void

/// Synchronous start handler with ``FKRefreshActionContext`` (token, kind, source, start time) for token-guarded `endRefreshing(token:)`.
public typealias FKRefreshActionHandler = @MainActor (_ context: FKRefreshActionContext) -> Void

/// Async variant of ``FKRefreshActionHandler`` for `async`/`await` networking.
public typealias FKRefreshContextAsyncHandler = @MainActor (_ context: FKRefreshActionContext) async throws -> Void
