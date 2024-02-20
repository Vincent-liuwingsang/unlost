//
//  StorageSettings.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import SwiftUI

let defaultRetentionPeriodNumber = 6
let defaultRetentionPeriod = "6 Months"
let retentionPeriods = [
    "1 Week",
    "2 Weeks",
    "1 Month",
    "3 Months",
    defaultRetentionPeriod,
    "Nah I want perfect memory (forever)"
]

struct StorageSettings: View {
    @AppStorage("retentionPeriod") var retentionPeriod: String = defaultRetentionPeriod
    @State private var prevRetentionPeriod = UserDefaults.standard.string(forKey: "retentionPeriod") ?? defaultRetentionPeriod
    @State private var storageUsed: Float = -1.0
    @State private var showingAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                SettingRow(
                    label: VStack(alignment: .trailing) {
                        Text("Storage Used")
                        Spacer()
                    },
                    value: VStack {
                        Text("\(storageUsed, specifier: "%.2f") GB")
                        Spacer()
                    }
                    .padding(.leading, 10)
                )
                .onAppear {
                    let directory = getDocumentsDirectory()
                    let sizeInBytes = directorySize(url: directory)
                    storageUsed = Float(sizeInBytes) / 1024 / 1024 / 1024
                    
                }
                .onChange(of: retentionPeriod) { period in
                    if let newIndex = retentionPeriods.firstIndex(of: period),
                       let oldIndex = retentionPeriods.firstIndex(of: prevRetentionPeriod) {
                        if newIndex < oldIndex {
                            showingAlert = true
                        } else {
                            prevRetentionPeriod = period
                        }
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("This will delete all data older than \(retentionPeriod). Are you sure? "),
                        message: Text("Searching will be temporarily unavailble and CPU usage will increase during deletion. This could take some time."),
                        primaryButton: .destructive(Text("Delete data")) {
                            deleteData(retention: retentionPeriod)
                            self.prevRetentionPeriod = retentionPeriod
                        },
                        secondaryButton: .cancel() {
                            retentionPeriod = prevRetentionPeriod
                        }
                    )
                }
                
                SettingRow(
                    label: VStack(alignment: .trailing) {
                        Text("Retention Period")
                        Text("How long to keep recordings for?")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color("WeakTitleText"))
                        
                        Spacer()
                    },
                    value: VStack(alignment: .leading) {
                        Picker("", selection: $retentionPeriod) {
                            ForEach(retentionPeriods, id: \.self) {
                                Text($0)
                            }
                        }
                        Text("Unlost uses 10-20GB per month depending on usage.")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color("WeakTitleText"))
                            .padding(.leading, 10)
                        Spacer()
                    })
                
                Spacer()
                
            }
        }
    }
}

func directorySize(url: URL) -> Int64 {
    let contents: [URL]
    do {
        contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
    } catch {
        return 0
    }

    var size: Int64 = 0

    for url in contents {
        let isDirectoryResourceValue: URLResourceValues
        do {
            isDirectoryResourceValue = try url.resourceValues(forKeys: [.isDirectoryKey])
        } catch {
            continue
        }
    
        if isDirectoryResourceValue.isDirectory == true {
            size += directorySize(url: url)
        } else {
            let fileSizeResourceValue: URLResourceValues
            do {
                fileSizeResourceValue = try url.resourceValues(forKeys: [.fileSizeKey])
            } catch {
                continue
            }
        
            size += Int64(fileSizeResourceValue.fileSize ?? 0)
        }
    }
    return size
}
