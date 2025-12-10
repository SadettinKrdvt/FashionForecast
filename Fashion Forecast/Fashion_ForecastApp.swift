//
//  Fashion_ForecastApp.swift
//  Fashion Forecast
//
//  Created by Sadettin Karadavut on 10.12.2025.
//

import SwiftUI

@main
struct Fashion_ForecastApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
