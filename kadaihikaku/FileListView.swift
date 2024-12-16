//
//  FileListView.swift
//  kadaihikaku
//
//  Created by 高須憲治 on 2024/12/12.
//

import SwiftUI

// 仮のデータ構造（必要であればContentViewから移動）
struct File_List: Identifiable {
    let id: String
    let filename: String
    let kind: String
    let mimeType: String
}

// FileListViewの定義
struct FileListView: View {
    var fileList: [File_List]
    
    var body: some View {
        List(fileList) { item in
            VStack(alignment: .leading) {
                Text(item.filename)
                    .font(.headline)
                HStack {
                    Text(item.kind)
                    Spacer()
                    Text(item.mimeType)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding()
        }
        .navigationTitle("ファイルリスト")
    }
}

// プレビュー（オプション、削除可能）
struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(fileList: [
            File_List(id: "1", filename: "Example.txt", kind: "file", mimeType: "text/plain"),
            File_List(id: "2", filename: "Image.jpg", kind: "file", mimeType: "image/jpeg")
        ])
    }
}
