
import SwiftUI // For ObservableObject, @Published
import Foundation // For UUID

// Note: Notification.Name.didRequestTaskOpen is now defined in AppDelegate.swift
// If you prefer it here, move it from AppDelegate.swift and ensure AppDelegate.swift imports this file or Foundation.
// For simplicity, I've assumed it's fine in AppDelegate for now as it's directly used there.
// If you want to move it here, it would look like:
/*
 extension Notification.Name {
     static let didRequestTaskOpen = Notification.Name("didRequestTaskOpen")
 }
*/


class AppNavigationState: ObservableObject {
    @Published var taskIDToOpen: UUID? = nil
}
// End of file
