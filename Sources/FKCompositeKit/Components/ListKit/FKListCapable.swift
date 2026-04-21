//
// FKListCapable.swift
// FKCompositeKit — FKListKit
//
// Marker protocol for view controllers that compose ``FKListPlugin`` without base-class inheritance.
//

import UIKit

/// Indicates a ``UIViewController`` hosts one or more ``FKListPlugin`` instances as **composition roots**.
///
/// ## Ownership
/// Retain ``FKListPlugin`` on the controller (stored properties). Plugins keep ``hostViewController`` and
/// scroll views with **weak** references only, so they never form a retain cycle with the screen.
///
/// ## Multiple lists
/// Declare additional ``FKListPlugin`` properties (or a small array) the same way—there is no singleton.
@MainActor
public protocol FKListCapable: AnyObject {}
