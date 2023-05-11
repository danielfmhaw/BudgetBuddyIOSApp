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
                    VStack(alignment: .leading) {
                        Text("Email")
                            .font(.headline)
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    listItemView(title: "Name", value: benutzer.name)
                    listItemView(title: "Geburtstag", value: formattedGeburtstag(benutzer.geburtstag))
                    listItemView(title: "Kontostand", value: String(format: "%.2f", benutzer.kontostand))
                    listItemView(title: "Buddy Name", value: benutzer.buddyName)
                    listItemView(title: "Lieblingsgegenstand", value: benutzer.lieblingsGegenstand)
                }
            } else {
                Text("Loading...")
            }
        }
        .sheet(item: $selectedItem) { item in
            if let benutzer = benutzer {
                BenutzerEditView(inhalt: item.title, benutzer: benutzer, onSave: { updatedBenutzer in
                    // Update the benutzer after saving
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
            Text(title)
                .font(.headline)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .onTapGesture {
            selectedItem = item
            isSheetPresented = true
        }
    }
    
    
    func getBenutzer() {
        guard let url = URL(string: "http://localhost:8080/api/v1/benutzer/\(email)") else {
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
        VStack {
            Text("\(inhalt) bearbeiten")
                .font(.largeTitle)
            
            if inhalt == "Email" {
                TextField("Email", text: $editedValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onAppear {
                        editedValue = benutzer.email
                    }
            } else if inhalt == "Name" {
                TextField("Name", text: $editedValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onAppear {
                        editedValue = benutzer.name
                    }
            } else if inhalt == "Geburtstag" {
                DatePicker(selection: $editedDate, displayedComponents: .date) {
                }
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                .onAppear {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                    if let date = dateFormatter.date(from: benutzer.geburtstag) {
                        editedDate = date
                    }
                }

            } else if inhalt == "Kontostand" {
                TextField("Kontostand", text: $editedValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onAppear {
                        editedValue = String(benutzer.kontostand)
                    }
            } else if inhalt == "Buddy Name" {
                TextField("Buddy Name", text: $editedValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onAppear {
                        editedValue = benutzer.buddyName
                    }
            } else if inhalt == "Lieblingsgegenstand" {
                TextField("Lieblingsgegenstand", text: $editedValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onAppear {
                        editedValue = benutzer.lieblingsGegenstand
                    }
            }
            
            Button(action: {
                // Speichern-Aktion durchführen
                saveAction()
            }) {
                Text("Speichern")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(5.0)
            }
            .padding()
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
            if let kontostand = Double(editedValue) {
                benutzer.kontostand = kontostand
            }
        } else if inhalt == "Buddy Name" {
            benutzer.buddyName = editedValue
        } else if inhalt == "Lieblingsgegenstand" {
            benutzer.lieblingsGegenstand = editedValue
        }
        
        guard let url = URL(string: "http://localhost:8080/api/v1/benutzer") else {
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
