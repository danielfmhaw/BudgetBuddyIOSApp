// Screen, um die Benutzerdaten anzuzeigen
//
// Created by Daniel Mendes on 29.04.23.

import SwiftUI


// Benutzer wird aus dem LoggenInView übergeben
struct BenutzerView: View {
    let email: String
    @State private var benutzer: Benutzer?
    @State private var isSheetPresented = false
    @State private var selectedItem: Item?
    
    struct Item: Identifiable {
        let id = UUID()
        let title: String
    }
    
    var body: some View {
        VStack {
            if let benutzer = benutzer {
                List {
                    Section(header: Text("Email")) {
                        Text(benutzer.email)
                            .font(.headline)
                    }
                    
                    Section(header: Text("Details")) {
                        listItemView(title: "Name", value: benutzer.name)
                        listItemView(title: "Geburtstag", value: formattedGeburtstag(benutzer.geburtstag))
                        listItemView(title: "Kontostand", value: String(format: "%.2f", benutzer.kontostand))
                        listItemView(title: "Buddy Name", value: benutzer.buddyName)
                        listItemView(title: "Lieblingsgegenstand", value: benutzer.lieblingsGegenstand)
                    }
                }
            } else {
                Text("Loading...")
            }
        }
        .sheet(item: $selectedItem) { item in
            if let benutzer = benutzer {
                BenutzerEditView(inhalt: item.title, benutzer: benutzer, onSave: { updatedBenutzer in
                    // Update des Benutzers nach dem Editieren
                    self.benutzer = updatedBenutzer
                })
            }
        }
        .onAppear {
            getBenutzer()
        }
    }
    
    func listItemView(title: String, value: String) -> some View {
        let item = Item(title: title)
        
        return VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            selectedItem = item
            isSheetPresented = true
        }
    }
    
    
    func getBenutzer() {
        guard let url = URL(string: "https://budgetbuddyback.fly.dev/api/v1/benutzer/\(email)?username=admin&password=password") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let data = data {
                do {
                    let benutzer = try JSONDecoder().decode(Benutzer.self, from: data)
                    DispatchQueue.main.async {
                        self.benutzer = benutzer
                    }
                } catch {
                    print("Error decoding Benutzer: \(error)")
                }
            }
        }.resume()
    }
    
    
    func formattedGeburtstag(_ geburtstag: String) -> String {
        let components = geburtstag.components(separatedBy: "T")[0].components(separatedBy: "-")
        if components.count == 3 {
            let day = components[2]
            let month = components[1]
            let year = components[0]
            return "\(day)-\(month)-\(year)"
        }
        return ""
    }
}


struct BenutzerEditView: View {
    let inhalt: String
    @State var benutzer: Benutzer
    var onSave: (Benutzer) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editedDate: Date = Date()
    @State private var editedValue: String = ""
    
    var body: some View {
        NavigationView {
            VStack{
                Text("\(inhalt) bearbeiten")
                    .font(.largeTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.5)
                
                Form{
                    createFieldView()
                }
                .navigationBarItems(trailing: Button(action: {
                    saveAction()
                }) {
                    Text("Speichern")
                }
                .padding())
            }
        }
    }
    
    @ViewBuilder
    func createFieldView() -> some View {
        switch inhalt {
        case "Name":
                Section(header: Text("Name")) {
                    TextField("Name", text: $editedValue)
                        .onAppear {
                            editedValue = benutzer.name
                        }
                }
        case "Geburtstag":
            Section(header: Text("Geburtstag")) {
                DatePicker(selection: $editedDate, displayedComponents: .date) {}
                    .datePickerStyle(WheelDatePickerStyle())
                    .onAppear {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                        if let date = dateFormatter.date(from: benutzer.geburtstag) {
                            editedDate = date
                        }
                    }
            }
            
        case "Kontostand":
            Section(header: Text("Kontostand")) {
                TextField("0.00", text: $editedValue)
                    .keyboardType(.decimalPad)
                    .onAppear {
                        editedValue = String(benutzer.kontostand)
                    }
            }
        case "Buddy Name":
            Section(header: Text("Buddy Name")) {
                TextField("Buddy Name", text: $editedValue)
                    .onAppear {
                        editedValue = benutzer.buddyName
                    }
            }
            
        case "Lieblingsgegenstand":
            Section(header: Text("Lieblingsgegenstand")) {
                TextField("Lieblingsgegenstand", text: $editedValue)
                    .onAppear {
                        editedValue = benutzer.lieblingsGegenstand
                    }
            }
        default:
            EmptyView()
        }
    }
    
    func saveAction() {
        // Speichern-Aktion implementieren
        if inhalt == "Email" {
            benutzer.email = editedValue
        } else if inhalt == "Name" {
            benutzer.name = editedValue
        } else if inhalt == "Geburtstag" {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            editedValue = dateFormatter.string(from: editedDate)
            benutzer.geburtstag = editedValue
        }else if inhalt == "Kontostand" {
            if let kontostand = Double(editedValue.replacingOccurrences(of: ",", with: ".")) {
                benutzer.kontostand = kontostand
            }
        } else if inhalt == "Buddy Name" {
            benutzer.buddyName = editedValue
        } else if inhalt == "Lieblingsgegenstand" {
            benutzer.lieblingsGegenstand = editedValue
        }
        
        guard let url = URL(string: "https://budgetbuddyback.fly.dev/api/v1/benutzer?username=admin&password=password") else {
            return
        }
        
        guard let editedValueData = try? JSONEncoder().encode(benutzer) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = editedValueData
           
           URLSession.shared.dataTask(with: request) { data, response, error in
               if let error = error {
                   print("Error: \(error)")
                   return
               }
               
               if let response = response as? HTTPURLResponse {
                   print("Response code: \(response.statusCode)")
               }
               
               if let data = data {
               }
               DispatchQueue.main.async {
                   onSave(benutzer)
               }
           }.resume()
        
        // Zurück zur BenutzerView navigieren und aktualisieren
        presentationMode.wrappedValue.dismiss()
    }
}
