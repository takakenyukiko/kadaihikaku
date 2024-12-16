//
//  ContentView2.swift
//  kadaihikakuUITests
//
//  Created by 高須憲治 on 2024/12/12.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import GoogleAPIClientForREST_Classroom

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var courses: [GTLRClassroom_Course] = []
    @State private var course: GTLRClassroom_Course?
    //@State var courseId: String?
    
    func handleSignInButton() {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
            guard let signInResult = signInResult, error == nil else {
                print("Sign-In failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
                       print("No current user found")
                       return
                   }
            // Classroom APIに必要なスコープ
                    let additionalScopes = [
                        "https://www.googleapis.com/auth/classroom.courses.readonly",
                            "https://www.googleapis.com/auth/classroom.coursework.students",
                            "https://www.googleapis.com/auth/classroom.rosters.readonly",
                        "https://www.googleapis.com/auth/drive.readonly",
                        "https://www.googleapis.com/auth/documents.readonly",
                        "https://www.googleapis.com/auth/drive",
                    "https://www.googleapis.com/auth/classroom.courseworkmaterials"
                    ]
            // 追加のスコープをリクエスト
                    currentUser.addScopes(additionalScopes, presenting: presentingViewController) { signInResult, error in
                        if let error = error {
                            print("Failed to add scopes: \(error.localizedDescription)")
                            return
                        }
                        
                        guard signInResult != nil else {
                            print("Scopes not granted")
                            return
                        }
                        
                        print("Scopes added successfully")
                        // 必要に応じてここでコース一覧を取得
                        fetchCourses()
                    }
            // サインイン成功
            isSignedIn = true
            //fetchCourses() // サインイン後にコースを取得
        }
    }
    
    func fetchCourses() {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else { return }
        let service = GTLRClassroomService()
        service.authorizer = currentUser.fetcherAuthorizer
        
        let query = GTLRClassroomQuery_CoursesList.query()
        query.pageSize = 8 // 必要に応じて変更
        
        service.executeQuery(query) { (ticket, result, error) in
            guard error == nil, let coursesList = result as? GTLRClassroom_ListCoursesResponse else {
                print("Error fetching courses: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            courses = coursesList.courses ?? []
            //courseId = course?.identifier
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isSignedIn {
                    List(courses, id: \.identifier) { course in
                        NavigationLink(destination: WorkListView(course: course)) {
                            Text(course.name ?? "Unknown Course")
                        }
                    }
                    .onAppear(perform: fetchCourses)
                } else {
                    GoogleSignInButton(action: handleSignInButton)
                        .frame(width: 200, height: 50)
                }
            }
            .navigationTitle(isSignedIn ? "Courses" : "Sign In")
        }
    }
}

