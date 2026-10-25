        .sheet(isPresented: $pickFolder) {
            FolderPicker(
                onPick: { url in
                    pickFolder = false
                    if let data = FolderAccess.makeBookmark(from: url) {
                        folderData = data
                        folderName = url.lastPathComponent
                    }
                },
                onCancel: { pickFolder = false }
            )
            .ignoresSafeArea()
        }
