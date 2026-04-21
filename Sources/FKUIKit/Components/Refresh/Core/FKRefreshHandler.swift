//
// FKRefreshHandler.swift
// FKUIKit — FKRefresh
//
// Async callback aliases for pull-to-refresh / load-more.
//

import Foundation

/// Async refresh callback running on the main actor.
public typealias FKRefreshAsyncHandler = @MainActor () async throws -> Void
