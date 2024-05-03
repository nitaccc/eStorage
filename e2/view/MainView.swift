//
//  MainView.swift
//  e2
//
//  Created by Anita Chen on 3/26/24.
//
import SwiftUI
import Foundation


enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case somethingSimple = "Snack"
}

struct MainView: View {
    @EnvironmentObject var settingDefault: SettingDefault
    @State private var items: [Item] = []
    @State private var selectedMealType: MealType?
    @State private var recommendationContent: String?
    private let itemsKey = "StoredItemsKey"
    
    var body: some View {
            TabView{
                ContentView(items: $items)
                    .tabItem {
                        Label("List", systemImage: "list.dash")
                    }
                    .onAppear(perform: loadItems)
                AddItemView(onAdd: { newItem in
                    addItem(newItem)
                    })
                    .tabItem {
                        Label("Add Item", systemImage: "cart.badge.plus")
                    }
                MealTypeSelectionView(selectedMealType: $selectedMealType, recommendationContent: $recommendationContent) { mealType in
                    recommendRecipes(for: mealType)
                }
                
                    .tabItem {
                        Label("Recipe", systemImage: "book.pages.fill")
                    }
                SettingView(items: $items)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)){ _ in
                saveItems()
//                settingDefault.setsave()
            }
            .colorScheme(.light)
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: itemsKey) {
            if let decodedItems = try? JSONDecoder().decode([Item].self, from: data) {
                items = decodedItems
            }
        }
    }
    
    private func saveItems() {
        if let encodedData = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encodedData, forKey: itemsKey)
        }
    }
    
    private func addItem(_ newItem: Item) {
        if let index = items.firstIndex(where: { $0.expirationDate ?? Date() > newItem.expirationDate ?? Date() }) {
            items.insert(newItem, at: index)
        } else {
            items.append(newItem)
        }
    }
    
    private func recommendRecipes(for mealType: MealType) {
        print("Recommendation requested for meal type: \(mealType.rawValue)")

        guard let selectedMealType = selectedMealType else {
            print("Selected meal type is nil")
            return
        }
        let ingredients = items.map { $0.name }.joined(separator: ", ")
        let prompt = "What can I have for \(selectedMealType.rawValue) with \(ingredients) in my storage? Just simply list out the name, ingredients, and steps to make it, be as concise as possible, just show 1 recipe. The format should be as below, the first line should just be the name of the recipe (no additional symbols), and the next section should start with the name \"Ingredients:\" and the last section should start with the name \"Steps:\""

        let requestData: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 150
        ]
        
        let apiKey = ProcessInfo.processInfo.environment["GPT_APIKEY"] ?? ""
        
        let apiUrl = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            print("Error serializing request data: \(error)")
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling GPT API: \(error)")
                return
            }
            guard let data = data else {
                print("No data received from GPT-3.5 API")
                return
            }
            if let responseString = String(data: data, encoding: .utf8) {
                  if let responseData = responseString.data(using: .utf8) {
                      do {
                          let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
                          if let choices = json?["choices"] as? [[String: Any]], let firstChoice = choices.first, let message = firstChoice["message"] as? [String: Any], let content = message["content"] as? String {
                              recommendationContent = content
//                              print(recommendationContent)
                          }
                      } catch {
                          print("Error decoding response from GPT-3.5 API: \(error)")
                      }
                  }
              } else {
                  print("Unable to decode response from GPT-3.5 API")
              }
          }.resume()
      }
}
class Recipe: Identifiable, Codable {
    var id = UUID()
    var name: String
    var information: String
    
    init(name: String, information: String) {
        self.name = name
        self.information = information
    }
}

func createRecipe(from string: String) -> Recipe? {
    // Split the string by newline characters
    let components = string.components(separatedBy: "\n")
    
    // Ensure that the string contains all necessary components
    guard components.count >= 7 else {
        print("Invalid recipe string format")
        return nil
    }
    
    // Extract the name and information from the components
    let name = components[0].replacingOccurrences(of: ":", with: "")
    let information = components[1..<components.count].joined(separator: "\n")
    
    // Initialize a Recipe object with the extracted information
    let recipe = Recipe(name: name, information: information)
    return recipe
}

struct MealTypeSelectionView: View {
    @Binding var selectedMealType: MealType?
    @Binding var recommendationContent: String?
    var onSelection: ((MealType) -> Void)
    @State private var isLoading = false
    @State private var decisionMade = false
    @State private var showingFavoriteRecipes = false
    @State private var showAlert = false

    
    // Define a list to store favorite recipes
    @State private var favoriteRecipes: [Recipe] = []

    var body: some View {
        VStack {
            Text("")
                .frame(maxWidth: .infinity)
            
            if decisionMade {
                if let recommendationContent = recommendationContent {
                    ScrollView {
                        VStack {
                            Spacer()
                            
                            Text(recommendationContent)
                                .padding()
                                .foregroundColor(Color(hex: 0xdee7e7))
                                .multilineTextAlignment(.leading)
                            
                            Button(action: {
                                // Create a Recipe object from the recommendation content string
                                if let recipe = createRecipe(from: recommendationContent) {
                                    print("Recipe created:", recipe) // Debugging statement
                                    
                                    // Check if the recipe is already saved
                                    if favoriteRecipes.contains(where: { $0.name == recipe.name })  {
                                        showAlert = true
                                        print("Recipe with name \(recipe.name) already exists in favorites") // Debugging statement
                                    } else {
                                        // Save the recipe as a favorite if it's not already saved
                                        favoriteRecipes.append(recipe)
                                        if let encoded = try? JSONEncoder().encode(self.favoriteRecipes) {
                                            UserDefaults.standard.set(encoded, forKey: "favoriteRecipes")
                                        }
                                        showAlert = true
                                        print("Recipe with name \(recipe.name) added to favorites") // Debugging statement
                                    }
                                } else {
                                    print("Failed to create Recipe object from recommendationContent")
                                }
                            }) {
                                if let recipe = createRecipe(from: recommendationContent) {
                                    if favoriteRecipes.contains(where: { $0.name == recipe.name })  {
                                        Label("Already Saved", systemImage: "heart.fill")
                                            .foregroundColor(Color(hex: 0xffc2d1))
                                    } else {
                                        Label("Save to Favorite", systemImage: "heart")
                                            .foregroundColor(Color(hex: 0xffc2d1))
                                    }
                                }
//                                Label("Save to Favorite", systemImage: "heart")
//                                    .foregroundColor(Color(hex: 0xffc2d1))
                            }
                            .padding()
                            .alert(isPresented: $showAlert) {
                                Alert(title: Text("Recipe Saved"), message: Text("The recipe has been saved to your favorites!"), dismissButton: .default(Text("OK")))
                            }
                            Button("Back", action: {
                                isLoading = false
                                decisionMade = false
                            })
                                .fontWeight(.semibold)
                                .frame(width: 150, height: 45)
                                .foregroundColor(Color(hex: 0xdee7e7))
                                .background(Color(hex: 0x89a9a9))
                                .cornerRadius(10)
                                .padding(30)
                        }
                    }
                } else if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading Recipes...")
                            .padding()
                            .foregroundColor(Color(hex: 0xdee7e7))
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: 0xdee7e7)))
                        Text("\n")
                        Button(action: {
                            isLoading = false
                            decisionMade = false
                        }) {
                            Text("Back")
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: 0xdee7e7))
                                .frame(width: 150, height: 45)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                    .fill(Color(hex: 0x89a9a9))
                                    .stroke(Color(hex: 0x89a9a9), lineWidth: 2)
                                )
                        }
                        Spacer()
                    }
                }
            } else {
                Spacer()
                
                Text("Time for...\n")
                    .padding(.vertical, 40)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: 0x535657))
                
                VStack(spacing: 10) {
                    HStack {
                        Button(action: {
                            selectedMealType = MealType(rawValue: "Breakfast")
                            isLoading = true
                            recommendationContent = nil
                            if let selectedMealType = selectedMealType {
                                onSelection(selectedMealType)
                            }
                            decisionMade = true
                        }) {
                            VStack {
                                Image("breakfast")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                
                                Text("Breakfast")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: 0x535657))
                                    .frame(width: 100, height: 10)
                                    .padding()
                            }
                        }
                        Button(action: {
                            selectedMealType = MealType(rawValue: "Lunch")
                            isLoading = true
                            recommendationContent = nil
                            if let selectedMealType = selectedMealType {
                                onSelection(selectedMealType)
                            }
                            decisionMade = true
                        }) {
                            VStack {
                                Image("lunch")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                
                                Text("Lunch")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: 0x535657))
                                    .frame(width: 100, height: 10)
                                    .padding()
                            }
                        }
                    }
                    Text("\n")
                    HStack {
                        Button(action: {
                            selectedMealType = MealType(rawValue: "Dinner")
                            isLoading = true
                            recommendationContent = nil
                            if let selectedMealType = selectedMealType {
                                onSelection(selectedMealType)
                            }
                            decisionMade = true
                        }) {
                            VStack {
                                Image("dinner")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                
                                Text("Dinner")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: 0x535657))
                                    .frame(width: 100, height: 10)
                                    .padding()
                            }
                        }
                        Button(action: {
                            selectedMealType = MealType(rawValue: "Snack")
                            isLoading = true
                            recommendationContent = nil
                            if let selectedMealType = selectedMealType {
                                onSelection(selectedMealType)
                            }
                            decisionMade = true
                        }) {
                            VStack {
                                Image("snack")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                
                                Text("Snack")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: 0x535657))
                                    .frame(width: 100, height: 10)
                                    .padding()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    // Toggle showing favorite recipes
                    showingFavoriteRecipes.toggle()
                }) {
                    Text("Favorite Recipes")
                        .foregroundColor(Color(hex: 0xdee7e7))
                        .frame(width: 200, height: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: 0x7f949f))
                        )
                }
                .padding(.bottom)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingFavoriteRecipes) {
            FavoriteRecipesListView(favoriteRecipes: $favoriteRecipes)
        }
        .background(decisionMade ? Color(hex: 0x4f646f) : Color(hex: 0xdee7e7))
    }
}

struct FavoriteRecipesListView: View {
    @Binding var favoriteRecipes: [Recipe]
    @State private var selectedRecipe: Recipe?
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                Color.clear.frame(height: 20)
                
                Text("    Favorite Recipes")
                    .font(.system(size:26, weight: .bold))
                    .foregroundColor(Color(hex: 0x535657))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                
                TextField("  Search", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .onTapGesture {
                        // Dismiss keyboard when tapped outside of text field
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .background(Color(hex: 0xdee7e7))
                    .colorScheme(.light)
                
                List {
                    ForEach(filteredRecipes) { recipe in
                        Button(action: {
                            selectedRecipe = recipe
                        }) {
                            Text(recipe.name)
                                .foregroundStyle(Color(hex: 0x535657))
                        }
                    }
                    .onDelete(perform: deleteRecipe)
                }
                .colorScheme(.light)
                .scrollContentBackground(.hidden)
                .sheet(item: $selectedRecipe) { recipe in
                    RecipeDetailsView(recipe: recipe)
                        .onDisappear {
                            selectedRecipe = nil
                        }
                }
                .onAppear {
                    // Load favorite recipes from UserDefaults when the view appears
                    if let data = UserDefaults.standard.data(forKey: "favoriteRecipes"),
                        let decodedRecipes = try? JSONDecoder().decode([Recipe].self, from: data) {
                            self.favoriteRecipes = decodedRecipes
                        }
                    }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    // Save favorite recipes to UserDefaults when the app is about to terminate
                    if let encoded = try? JSONEncoder().encode(self.favoriteRecipes) {
                        UserDefaults.standard.set(encoded, forKey: "favoriteRecipes")
                    }
                }
            }
            .background(Color(hex: 0xdee7e7))
        }
    }
    
    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return favoriteRecipes
        } else {
            return favoriteRecipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func deleteRecipe(at offsets: IndexSet) {
        favoriteRecipes.remove(atOffsets: offsets)
        if let encoded = try? JSONEncoder().encode(self.favoriteRecipes) {
            UserDefaults.standard.set(encoded, forKey: "favoriteRecipes")
        }
    }
}



struct RecipeDetailsView: View {
    var recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
                Text(recipe.name)
                    .font(.title)
                    .foregroundColor(Color(hex: 0x535657))
           
                Text(recipe.information)
                    .font(.body) // Adjust the font size as needed
                    .foregroundColor(Color(hex: 0x535657))
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .background(Color(hex: 0xdee7e7))
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}


extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}
