//
//  kadaihikakuApp.swift
//  kadaihikaku
//
//  Created by 高須憲治 on 2024/12/11.
//

import SwiftUI
import GoogleSignIn
@main
struct GoogleAPIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL{ url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear{
                    GIDSignIn.sharedInstance.restorePreviousSignIn{ user,error in
                    }
                }
        }
    }
}
