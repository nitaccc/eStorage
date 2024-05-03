// ContentView.swift

import SwiftUI
import Combine


struct ContentView: View {
    @Binding var items: [Item]
    @State private var selectedItem: Item?
    @State private var showingDeleteAlert = false
    @State private var showingALLDeleteAlert = false
    @State private var boolitem: Item?
    @State private var searchText = ""
    @FocusState private var showingKeyBoard: Bool

    // Key for UserDefaults
    private let itemsKey = "StoredItemsKey"

    var body: some View {
            VStack{
                GeometryReader { proxy in
                    VStack{
                        HStack{
                            Text("Grocery Lists")
                                .font(.system(size:26, weight: .bold))
                                .position(x: 100, y: 60)
                                .foregroundColor(Color(hex: 0x535657))

                            Spacer()
                            
                            ZStack(alignment: .topTrailing){
                                Path { path in
                                    path.move(to: CGPoint(x:proxy.size.width/2, y:0))
                                    path.addArc(
                                        center: CGPoint(x:proxy.size.width/2, y:0),
                                        radius: 110,
                                        startAngle: Angle(degrees: 90),
                                        endAngle: Angle(degrees: 180),
                                        clockwise: false
                                    )
                                    path.closeSubpath()
                                }
                                .fill(Color(hex: 0x535657))
                                
                                Button(action: {
                                    showingALLDeleteAlert = true
                                }, label: {
                                    Text("Delete\n       All")
                                        .foregroundColor(Color(hex: 0xf4faff))
                                        .padding(23)
                                        .alignmentGuide(.top){ dimension in
                                            dimension[.top]
                                        }
                                })
                                .alert(isPresented: $showingALLDeleteAlert) {
                                    Alert(
                                        title: Text("Delete Expired Item"), message: Text("Confirm deletion of all expired items?"),
                                        primaryButton: .destructive(Text("Delete")) {
                                            deleteAllExpiredItems()
                                            showingALLDeleteAlert = false
                                        },
                                        secondaryButton: .cancel(){
                                            showingALLDeleteAlert = false
                                        }
                                    )
                                }
                            }
                        }
                        .frame(height: proxy.size.height/6)
                        
                        TextField("  Search", text: $searchText)
                            .focused($showingKeyBoard)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .onChange(of: searchText) { _,_ in}
                        
                        List {
                            ForEach(filteredItems) { item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(" \(item.name)")
                                            .foregroundColor(isItemExpired(item.expirationDate) ? .red : Color(hex: 0x535657))
                                        if let expirationDate = item.expirationDate {
                                            Text("  Best by \(formattedDate(expirationDate))")
                                                .foregroundColor(isItemExpired(expirationDate) ? .red : Color(hex: 0x535657))
                                        }
                                    }
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItem = item
                                    boolitem = item
                                }
                                .sheet(item: $boolitem){ boolitem in
                                    ItemDetailView(item: boolitem)
                                }
                            }
                            .onDelete(perform: deleteItems)
                            .listRowBackground(Color(hex: 0xdee7e7))
                        }
                        .listStyle(.plain)
                        .alert(isPresented: $showingDeleteAlert) {
                            Alert(
                                title: Text("Delete Item"), message: Text("Are you sure you want to delete \(selectedItem?.name ?? "this item")?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    deleteSelectedItem()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .alignmentGuide(.bottom){ dimension in
                        dimension[.bottom]
                    }
                }
            }
//            .onTapGesture {
//                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//            }
//            .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
//                .onEnded { value in
//                    print(value.translation)
//                    switch(value.translation.width, value.translation.height) {
//                        case (-100...100, 0...):
//                            showingKeyBoard = false
//                        default:  print("no clue")
//                    }
//                }
//            )
            .background(Color(hex: 0xdee7e7))
        }
    private var filteredItems: [Item] {
           if searchText.isEmpty {
               return items
           } else {
               return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
           }
       }
    
    private func deleteItems(at offsets: IndexSet) {
        selectedItem = items[offsets.first ?? 0]
        showingDeleteAlert = true
    }

    private func deleteSelectedItem() {
        print("delete selected item")
        if let selectedItem = selectedItem,
           let index = items.firstIndex(where: { $0.id == selectedItem.id }) {
            items.remove(at: index)
        }
        if let encodedData = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encodedData, forKey: itemsKey)
        }
        selectedItem = nil
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func isItemExpired(_ expirationDate: Date?) -> Bool {
        guard let expirationDate = expirationDate else {
            return false
        }
        let currentDate = Date()

        return currentDate > expirationDate
    }

    private func deleteAllExpiredItems() {
        let currentDate = Date()
        let expiredItemsIndices = items.indices.filter { index in
            guard let expirationDate = items[index].expirationDate else {
                return false
            }
            return currentDate > expirationDate
        }
        // Display an alert if there are no expired items to delete
        guard !expiredItemsIndices.isEmpty else {
            showingDeleteAlert = true
            selectedItem = nil
            return
        }
        // Delete expired items
        for index in expiredItemsIndices.reversed() {
            items.remove(at: index)
        }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        let items: [Item] = []
//        ContentView(items: .constant(items))
//    }
//}
