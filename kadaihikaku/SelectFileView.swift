//
//  SelectFileView.swift
//  kadaihikaku
//
//  Created by 高須憲治 on 2024/12/13.
//

import SwiftUI
import GoogleAPIClientForREST_Classroom
import GoogleSignIn
import GoogleAPIClientForREST_Drive

struct SelectFileView: View {
    @State private var files: [GTLRDrive_File] = []
    //@Binding var isFileSelected: Bool   // ファイルが選択された状態
    @State var selectedFileId: String? // 親ビューから渡される選択状態
    @Binding var selectworkId: String?
    let course: GTLRClassroom_Course?
    
    func fetchDriveFiles() {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else { return }
        let driveService = GTLRDriveService()
        driveService.authorizer = currentUser.fetcherAuthorizer
        
        // クエリの設定：Googleドキュメントのみを取得
                let query = GTLRDriveQuery_FilesList.query()
                query.pageSize = 20
                query.fields = "files(id, name, mimeType)"
                query.q = """
        mimeType = 'application/vnd.google-apps.document' and 'root' in parents
        """ // Googleドキュメントのみ
        
                // クエリの実行
                driveService.executeQuery(query) { (ticket, result, error) in
                    guard error == nil, let fileList = result as? GTLRDrive_FileList else {
                        print("Error fetching files: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }

            
            files = fileList.files ?? []
        }
    }
    
    var body: some View {
        NavigationView {
            List(files, id: \.identifier) { file in
                NavigationLink(
                    destination:
                        
                        SubmissionListView(
                            course: course,
                            selectworkId: $selectworkId,
                            selectedFileId: file.identifier,
                            courseID: course?.identifier
                    )
                ) {
                    Text(file.name ?? "Unknown File")
                        .onTapGesture {
                            selectedFileId = file.identifier
                            // 選択されたファイルのIDを使って元の課題の内容を取得
                            // 比較する際に使用する
                           // isFileSelected = true // ファイル選択状態を更新
                            
                        }
                }
            }
            .onAppear(perform: fetchDriveFiles)
            .navigationTitle("Select Original Assignment")
        }
    }
}

