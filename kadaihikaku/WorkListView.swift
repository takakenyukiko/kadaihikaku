import SwiftUI
import GoogleAPIClientForREST_Classroom
import GoogleSignIn

struct WorkListView: View {
    //let course: GTLRClassroom_Course
    //@Binding var course: GTLRClassroom_Course?
    //@Binding var courseId: String?


    @State private var works: [GTLRClassroom_CourseWork] = []
    @State private var selectedWorkId: String? // 選択された課題ID
    let course: GTLRClassroom_Course // ファイル選択ビューの表示フラグ
    @State private var selectedFileId: String? // ファイルIDを管理
    
    func fetchWorks() {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else { return }
        let service = GTLRClassroomService()
        service.authorizer = currentUser.fetcherAuthorizer
        //guard let courseId = course?.identifier else { return }
        let query = GTLRClassroomQuery_CoursesCourseWorkList.query(withCourseId: course.identifier ?? "")
        //query.pageSize = 2 // 必要に応じて変更

        service.executeQuery(query) { (ticket, result, error) in
            guard error == nil, let worksList = result as? GTLRClassroom_ListCourseWorkResponse else {
                print("Error fetching works: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            works = worksList.courseWork ?? []
        
        }
    }

    var body: some View {
        NavigationView {
            
            List(works, id: \.identifier) { work in
                NavigationLink(
                    destination:
                        SelectFileView(
                                       selectworkId: $selectedWorkId,
                                       course:course
                        )
                        .onAppear {
                                           selectedWorkId = work.identifier // 選択された課題IDを設定
                                       }
                        /*
                        SubmissionListView(
                        courseId: course.identifier ?? "",
                        workId: work.identifier ?? ""
                    )*/
                ) {
                    VStack(alignment: .leading) {
                        Text(work.title ?? "Unknown Work")
                        Button(action: {
                            selectedWorkId = work.identifier
                           // isFileSelectionActive = true
                        }) {
                            Text("Select File")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .onAppear(perform: fetchWorks)
            .navigationTitle(course.name ?? "Works")
            /*.sheet(isPresented: $isFileSelectionActive) {
                SelectFileView(
                    isFileSelected: $isFileSelectionActive,
                    // 親ビューの状態とリンク
                       // selectedFileId: $selectedFileId         // 親ビューの状態とリンク
                    )
            }*/
        }
    }
}
