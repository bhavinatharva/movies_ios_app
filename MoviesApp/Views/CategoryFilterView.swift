import SwiftUI

struct CategoryFilterView: View {
    let categories: [XtreamCategory]
    let selectedCategory: XtreamCategory?
    let onSelect: (XtreamCategory?) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    onSelect(nil)
                    dismiss()
                }) {
                    HStack {
                        Text("All (Home)")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                ForEach(categories) { category in
                    Button(action: {
                        onSelect(category)
                        dismiss()
                    }) {
                        HStack {
                            Text(category.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
