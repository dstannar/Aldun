import Foundation
import EventKit
import Combine

enum CalendarImportError: Error {
    case accessDenied
    case accessRestricted
    case fetchFailed(Error?)
    case unknown
}

class CalendarImporter: ObservableObject {
    private let eventStore = EKEventStore()

    func requestAccess(completion: @escaping (Bool, CalendarImportError?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(false, .fetchFailed(error))
                        return
                    }
                    if granted {
                        completion(true, nil)
                    } else {
                        completion(false, .accessDenied)
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(false, .fetchFailed(error))
                        return
                    }
                    if granted {
                        completion(true, nil)
                    } else {
                        completion(false, .accessDenied)
                    }
                }
            }
        }
    }

    func fetchUpcomingEvents(for days: Int = 7, completion: @escaping (Result<[EKEvent], CalendarImportError>) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)

        let hasAccess: Bool
        if #available(iOS 17.0, *) {
            hasAccess = (status == .fullAccess) 
        } else {
            hasAccess = (status == .authorized)
        }
        
        guard hasAccess else {
            completion(.failure(.accessDenied))
            return
        }

        let calendars = eventStore.calendars(for: .event)
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate) ?? startDate.addingTimeInterval(Double(days*24*60*60))

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        
        let events = eventStore.events(matching: predicate)
        completion(.success(events))
    }

    func exportTaskToCalendar(task: Task, completion: @escaping (Bool, Error?) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)

        let hasAccess: Bool
        if #available(iOS 17.0, *) {
            hasAccess = (status == .fullAccess || status == .writeOnly)
        } else {
            hasAccess = (status == .authorized)
        }

        guard hasAccess else {
            completion(false, CalendarImportError.accessDenied)
            return
        }

        let event = EKEvent(eventStore: self.eventStore)
        event.title = task.title
        event.startDate = task.dueDate
        event.endDate = task.dueDate.addingTimeInterval(3600) 
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
}
