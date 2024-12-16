//
//  SubmissionListView.swift
//  kadaihikaku
//
//  Created by 高須憲治 on 2024/12/13.
//

import SwiftUI
import GoogleAPIClientForREST_Classroom
import GoogleSignIn
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForREST_Docs
import Diff

struct SubmissionListView: View {
    //let courseId: String
    //let workId: String
    // let selectedFileId: String // 親ビューから渡される選択されたファイルID
    //@State private var submissions: [GTLRClassroom_StudentSubmission] = []
    //@State private var studentNames: [String: String] = [:] // userId と生徒名のマッピング
    @State private var submissions: [GTLRClassroom_StudentSubmission] = []
    @State private var studentNames: [String: String] = [:]
    @State private var results: [(studentName: String?, details: FileDetails?)] = []
    @State private var kadai: [(studentName: String?, details: FileDetails?)] = []

    @State private var baseBody: GTLRClassroom_DriveFile? // 元の課題の内容を保持する
    @State private var isDataLoaded = false
    
    
    let course: GTLRClassroom_Course?
    @Binding var selectworkId: String?
    let selectedFileId: String? // ファイルIDを管理
    let courseID: String?
    //let selectworkId: String?
    let dispatchGroup = DispatchGroup()
    
    func fetchStudentName(userId: String, courseId: String, completion: @escaping (String?) -> Void) {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            completion(nil)
            return
        }
        let service = GTLRClassroomService()
        service.authorizer = currentUser.fetcherAuthorizer
        
        let query = GTLRClassroomQuery_CoursesStudentsGet.query(withCourseId: courseId, userId: userId)
        service.executeQuery(query) { (ticket, result, error) in
            if let error = error {
                print("Error fetching student name: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let student = result as? GTLRClassroom_Student {
                completion(student.profile?.name?.fullName)
            } else {
                completion(nil)
            }
        }
    }
    
    func fetchSubmissions() {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else { return }
        let service = GTLRClassroomService()
        service.authorizer = currentUser.fetcherAuthorizer
        //let courseId = course?.identifier
        let query = GTLRClassroomQuery_CoursesCourseWorkStudentSubmissionsList.query(
            withCourseId: courseID ?? "",
            courseWorkId: selectworkId ?? ""
        )
        
        service.executeQuery(query) { (ticket, result, error) in
            guard error == nil else {
                print("提出物の取得中にエラーが発生しました: \(error?.localizedDescription ?? "不明なエラー")")
                return
            }
            if let submissionResponse = result as? GTLRClassroom_ListStudentSubmissionsResponse,
               let submissions = submissionResponse.studentSubmissions {
                
                let driveService = GTLRDriveService()
                driveService.authorizer = currentUser.fetcherAuthorizer
                
                //submissions = submissionList.studentSubmissions ?? []
                //fetchStudentNames(completion: () -> Void) // 生徒名を取得
               /* fetchStudentNames(submissionsResponse: submissionResponse){
                    print(studentNames)

                }
                //{
                  //  print("全ての名前を取得しました！")
                    // ここで、名前取得後の処理を実行します
                    //
                //}
                print("生徒名簿",studentNames)

                fetchBaseContent() // 元の課題の内容を取得
                //processSubmissions(driveService: driveService,submissions: submissions)
                processSubmissions(driveService: driveService, submissions: submissions)
                */
                Task {
                    await fetchStudentNames(submissionsResponse: submissionResponse)
                    print("生徒名簿", studentNames)
                    fetchBaseContent()
                    processSubmissions(driveService: driveService, submissions: submissions)
                }

            }
        }
    }
    func fetchStudentNames(submissionsResponse: GTLRClassroom_ListStudentSubmissionsResponse) async {
        guard let submissions = submissionsResponse.studentSubmissions else {
            print("No submissions found in the response.")
            return
        }
        let dispatchGroup = DispatchGroup()
        
        for submission in submissions {
            if let userId = submission.userId {
                dispatchGroup.enter()
                await withCheckedContinuation { continuation in
                    fetchStudentName(userId: userId, courseId: courseID ?? "") { name in
                        DispatchQueue.main.async {
                            studentNames[userId] = name ?? "Unknown Student"
                        }
                        dispatchGroup.leave()
                        continuation.resume()
                    }
                }
            }
        }
        
        await dispatchGroup.wait() // 処理が全て終わるまで待つ
        print("All student names fetched.")
    }

    func fetchStudentNames1(submissionsResponse: GTLRClassroom_ListStudentSubmissionsResponse, completion: @escaping () -> Void) {
        guard let submissions = submissionsResponse.studentSubmissions else {
            print("No submissions found in the response.")
            completion()
            return
        }
        let dispatchGroup = DispatchGroup()
        
        for submission in submissions {
            if let userId = submission.userId {
                dispatchGroup.enter()
                fetchStudentName(userId: userId, courseId: courseID ?? "") { name in
                    DispatchQueue.main.async {
                        studentNames[userId] = name ?? "Unknown Student"
                        
                    }
                    dispatchGroup.leave()
                        }
                    
                }
            }
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    
    
    func fetchBaseContent() {
        // 選択された元の課題のファイルIDを使って元の課題の内容を取得
        guard let fileId = selectedFileId else {
            print("Error: selectedFileId is nil")
            return
        }
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            print("Error: User not signed in")
            return
        }
        
        let driveService = GTLRDriveService()
        let docsService = GTLRDocsService()
        driveService.authorizer = currentUser.fetcherAuthorizer
        docsService.authorizer = currentUser.fetcherAuthorizer
        
        //let resultsQueue = DispatchQueue(label: "com.yourapp.resultsQueue")
        // let dispatchGroup = DispatchGroup()
        //var results: [(studentName: String, details: FileDetails)] = []
        
        // dispatchGroup.enter()
        fetchFileDetails(driveService: driveService, docsService: docsService, fileId: fileId) { fileDetails in
            
            guard let fileDetails = fileDetails else {
                print("Error: Failed to fetch file details")
                return
            }
            //   defer { dispatchGroup.leave() } // 非同期処理完了を通知
            
            // 結果を計算
            //let studentName = "担当者"
            let result = (
                studentName: "担当者",
                details: fileDetails
            )
            
            //  resultsQueue.async {
            kadai.append(result)
            //}
            
        }
        
        // dispatchGroup.notify(queue: .main) {
        //    print("全ての処理が完了しました。結果: \(results)")
        // ここで結果をUIに反映するなどの処理を行う
        //}
    }
    
    func getFileContent(_ fileId: String) -> GTLRClassroom_DriveFile {
        let driveService = GTLRDriveService()
        
        let query = GTLRDriveQuery_FilesGet.query(withFileId: fileId)
        var file: GTLRClassroom_DriveFile?
        
        driveService.executeQuery(query) { (ticket, result, error) in
            if let error = error {
                print("Error fetching file content: \(error.localizedDescription)")
                return
            }
            
            if let driveFile = result as? GTLRClassroom_DriveFile {
                file = driveFile
            }
        }
        
        return file!
    }
    
    func processSubmissions1(driveService: GTLRDriveService,submissions:[GTLRClassroom_StudentSubmission]?) {
        guard let submissions = submissions, !submissions.isEmpty else {
            print("提出物が見つかりませんでした。")
            return
        }
        for submission in submissions {
            // `assignmentSubmission.attachments` を取得
            guard let assignmentSubmission =
                    submission.assignmentSubmission,
                  let attachments = assignmentSubmission.attachments,
                  let driveFile = attachments.first?.driveFile else { continue }
            
            let fileId = driveFile.identifier ?? ""
            let GTLRDocsService = GTLRDocsService()
            guard let currentUser = GIDSignIn.sharedInstance.currentUser else { return }
            GTLRDocsService.authorizer = currentUser.fetcherAuthorizer
            let studentName = submission.userId ?? "Unknown Student"
            //studentNames[submission.userId ?? "Unknown Student"]
            // 提出物の詳細を取得
            fetchFileDetails(driveService: driveService, docsService: GTLRDocsService, fileId: fileId) { fileDetails in
                guard let fileDetails = fileDetails else { return }
                
                // 学生名や類似性を計算するロジック
                
                
                let result = (
                    studentName: studentName,
                    details: fileDetails
                )
                // DispatchQueue.main.async {
                results.append(result)
                //}
            }
        }
    }
    
    func processSubmissions(driveService: GTLRDriveService, submissions: [GTLRClassroom_StudentSubmission]?) {
        guard let submissions = submissions, !submissions.isEmpty else {
            print("提出物が見つかりませんでした。")
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var results: [(studentName: String?, details: FileDetails?)] = []
        
        for submission in submissions {
            // `assignmentSubmission.attachments` を取得
                guard submission.state == "TURNED_IN",
                    let assignmentSubmission = submission.assignmentSubmission,
                    let attachments = assignmentSubmission.attachments,
                    let driveFile = attachments.first?.driveFile else { continue }
                
                let fileId = driveFile.identifier ?? ""
                let GTLRDocsService = GTLRDocsService()
                guard let currentUser = GIDSignIn.sharedInstance.currentUser else { return }
                GTLRDocsService.authorizer = currentUser.fetcherAuthorizer
                let studentName = studentNames[submission.userId ?? "Unknown Student"]
                
                // 提出物の詳細を取得
                dispatchGroup.enter()
                fetchFileDetails(driveService: driveService, docsService: GTLRDocsService, fileId: fileId) { fileDetails in
                    
                    guard let fileDetails = fileDetails else { return }
                    
                    // 結果を追加
                    let result = (
                        studentName: studentName,
                        details: fileDetails
                    )
                    
                    print(result)
                    DispatchQueue.main.async {
                        results.append(result)
                    }
                    dispatchGroup.leave()
                    
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                //isDataLoaded=true
                
                // Sorting the results by total character count in descending order
                self.results = results.sorted { ($0.details?.totalCharacters ?? 0) < ($1.details?.totalCharacters ?? 0) }
                
                self.isDataLoaded = true
                // 全ての処理が完了した時の結果を表示
                print("全ての処理が完了しました: \(results)")
            }
        
    }
  
    func fetchFileDetails(
        driveService: GTLRDriveService,
        docsService: GTLRDocsService,
        fileId: String,
        completion: @escaping (FileDetails?) -> Void
    ) {
        let driveQuery = GTLRDriveQuery_FilesGet.query(withFileId: fileId)
        driveQuery.fields = "name, mimeType"
        
        driveService.executeQuery(driveQuery) { (ticket, result, error) in
            guard error == nil, let file = result as? GTLRDrive_File else {
                print("Error fetching file details: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil) // 型が明確であれば、このエラーは発生しません
                return
            }
            
            if file.mimeType == "application/vnd.google-apps.document" {
                let docsQuery = GTLRDocsQuery_DocumentsGet.query(withDocumentId: fileId)
                docsService.executeQuery(docsQuery) { (docsTicket, docsResult, docsError) in
                    guard docsError == nil, let document = docsResult as? GTLRDocs_Document else {
                        print("Error fetching document details: \(docsError?.localizedDescription ?? "Unknown error")")
                        completion(nil)
                        return
                    }
                    
                    // ドキュメント内容を解析してFileDetailsを作成
                    //let content = extractText(from: document)
                    let imageCount = countImages(from: document)
                    //let tableCount = countTables(from: document)
                    //let totalCharacters = content.reduce(0) { $0 + $1.count }
                    
                    let fileDetails = FileDetails(
                        // content: content,
                        totalCharacters: imageCount.totalCharacters,
                        imageCount: imageCount.imageCount,
                        tableCount: imageCount.tableCount
                    )
                    print(fileDetails)
                    completion(fileDetails)
                }
            } else {
                print("File is not a Google Document")
                completion(nil)
            }
        }
    }
    func extractText(from document: GTLRDocs_Document) -> [String] {
        var textContent: [String] = []
        guard let body = document.body, let content = body.content else { return [] }
        
        for element in content {
            if let paragraph = element.paragraph {
                let paragraphText = paragraph.elements?.compactMap { $0.textRun?.content }.joined() ?? ""
                textContent.append(paragraphText)
            }
        }
        return textContent
    }
    
    func countImages(from document: GTLRDocs_Document) -> (content: [String], totalCharacters: Int, imageCount: Int, tableCount: Int) {
        var content: [String] = []
        var totalCharacters = 0
        var imageCount = 0
        var tableCount = 0
        
        // テキストと表の処理
        for element in document.body?.content ?? [] {
            if let paragraph = element.paragraph {
                for textElem in paragraph.elements ?? [] {
                    if let text = textElem.textRun?.content?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        content.append(text)
                        totalCharacters += text.count
                    }
                    if textElem.inlineObjectElement != nil {
                        imageCount += 1
                    }
                }
            }
            if let table = element.table {
                tableCount += 1
                // テーブル内のセルを解析
                if let tableRows = table.tableRows {
                    for row in tableRows {
                        if let tableCells = row.tableCells{
                        for cell in tableCells {
                            for cellElement in cell.content ?? [] {
                                if let paragraph = cellElement.paragraph {
                                    for textElem in paragraph.elements ?? [] {
                                        if let text = textElem.textRun?.content?.trimmingCharacters(in: .whitespacesAndNewlines) {
                                                                                content.append(text)
                                                                                totalCharacters += text.count
                                                                            }
                                        if let inlineObject = textElem.inlineObjectElement
                                           {
                                            imageCount += 1
                                        }
                                      //  if textElem.inlineObjectElement != nil {
                                        //    imageCount += 1
                                       // }
                                    }
                                }
                            }
                            }
                        }
                    }
                }
            }
        }
            
        return (content,totalCharacters, imageCount, tableCount)
        }
    
    func countTables(from document: GTLRDocs_Document) -> Int {
        guard let body = document.body, let content = body.content else { return 0 }
        return content.filter { $0.table != nil }.count
    }
    
    /*
     func calculateFileSimilarity(_ baseText: String, _ submissionText: String) -> Double {
     let changes = baseText.diff(submissionText)
     let totalLength = max(baseText.count, submissionText.count)
     let unchangedLength = totalLength - changes.count
     
     // 類似性スコア
     return Double(unchangedLength) / Double(totalLength)
     }
     */
    var body: some View {
        Group {
            if isDataLoaded {
                VStack{
                    Text("課題内容:\(String(describing: kadai[0].studentName ?? "Unknown"))")
                    if let details = kadai[0].details {
                        Text("Characters: \(details.totalCharacters)")
                        Text("Images: \(details.imageCount)")
                        Text("Tables: \(details.tableCount)")
                    } else {
                        Text("No details available")
                    }
                    
                }
                List(results, id: \.studentName) { result in
                    VStack(alignment: .leading) {
                        Text("Student Name: \(String(describing: result.studentName ?? "Unknown"))")
                        if let details = result.details {
                            Text("Characters: \(details.totalCharacters)")
                            Text("Images: \(details.imageCount)")
                            Text("Tables: \(details.tableCount)")
                        } else {
                            Text("No details available")
                        }
                    }
                }
                .navigationTitle("Submissions")
                
            } else {
                Text("Loading...")
            }
            
            
        }.onAppear {
            fetchSubmissions()}
    }
    
    
    
    struct FileDetails {
        //let content: [String]
        let totalCharacters: Int
        let imageCount: Int
        let tableCount: Int
    }
    
}
