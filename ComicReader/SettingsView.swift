            .sheet(isPresented: $pickFolder) {
                FolderPicker(
                    onPick: { url in
                        pickFolder = false
                        if let data = FolderAccess.makeBookmark(from: url) {
                            settings.folderBookmark = data
                        }
                    },
                    onCancel: { pickFolder = false }
                )
                .ignoresSafeArea()
            }
