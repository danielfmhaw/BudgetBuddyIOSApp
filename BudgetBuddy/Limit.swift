// Man kann hier Limits anzeigen, hinzufügen, editieren und löschen
//
// Created by Daniel Mendes on 30.04.23.

import SwiftUI

// Struktur eines "Limits" (genauso wie im Backend gespeichert)
struct Limit: Codable, Identifiable {
    var id: Int
    var kategorie: String
    var benutzer: Benutzer
    var betrag: Double
}

struct LimitView: View {
    let email: String
    let benutzer: Benutzer

    @State var isPresentingAddLimitView = false
    @State var isPresentingEditLimitView = false
    @State var selectedLimit: Limit?
    @State var limits: [Limit] = []

    var body: some View {
        NavigationView {
            VStack{
                Text("Limits")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                if !limits.isEmpty {
                    // Anzeige alle Limits für den Benutzer
                    List {
                        ForEach(limits, id: \.id) { limit in
                            HStack {
                                Text("\(limit.kategorie)")
                                    .fontWeight(.semibold)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Spacer()

                                HStack {
                                    Text("\(limit.betrag, specifier: "%.2f") €")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 10)
                            // Löschen des ausgwählten Limits
                            .contextMenu {
                                Button(action: {
                                    deleteLimit(id: limit.id)
                                }) {
                                    Text("Löschen")
                                    Image(systemName: "trash")
                                }
                            }
                            .onTapGesture {
                                selectedLimit = limit
                            }
                        }
                        // Löschen des ausgwählten Limits
                        .onDelete { indexSet in
                            for index in indexSet {
                                deleteLimit(id: limits[index].id)
                            }
                        }
                    }
                    // Editieren des ausgwählten Limits
                    .sheet(item: $selectedLimit) { limit in
                        EditLimitView(email: email, benutzer: benutzer, limit: limit, onDismiss: {
                            fetchLimits()
                        })
                    }
                } else {
                    Text("Keine Limits gefunden")
                }
            }
            // HInzufügen eines Limits mit Button an oberer rechter Seite
            .navigationBarItems(trailing:
                Button(action: {
                    isPresentingAddLimitView.toggle()
                }) {
                    Text("Hinzufügen")
                }
                .sheet(isPresented: $isPresentingAddLimitView) {
                    AddLimitView(email: email, benutzer: benutzer, isPresentingAddLimitView: $isPresentingAddLimitView, onDismiss: {
                        fetchLimits()
                    })
                }
            )
            .onAppear {
                fetchLimits()
            }
        }
    }

    //Bekommt die Limits aus dem Backend
    func fetchLimits() {
        guard let url = URL(string: "http://localhost:8080/api/v1/limit/\(email)") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode([Limit].self, from: data) {
                    DispatchQueue.main.async {
                        limits = decodedResponse
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
    
    //Löscht das Limit im Backend
    func deleteLimit(id: Int) {
        guard let url = URL(string: "http://localhost:8080/api/v1/limit/\(id)") else {
            print("Ungültige URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Fehler beim Löschen des Limits: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Ungültige Serverantwort")
                return
            }
            
            if httpResponse.statusCode == 200 {
                // Aktualisiere die Limitsliste
                fetchLimits()
            } else {
                print("Fehler beim Löschen des Limits: HTTP-Statuscode \(httpResponse.statusCode)")
            }
        }.resume()
    }

}

// Screen, wo man Limit hinzufügen kann
struct AddLimitView: View {
    let email: String
    let benutzer: Benutzer
    let isPresentingAddLimitView: Binding<Bool>
    let onDismiss: () -> Void
    
    let kategorien = ["Lebensmittel", "Finanzen", "Freizeit", "Unterhaltung", "Hobbys", "Wohnen", "Haushalt", "Technik", "Shopping", "Restaurant", "Drogerie", "Sonstiges"]
    
    @State private var selectedKategorie = "Lebensmittel"
    @State var betrag: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kategorie")) {
                    Picker("Kategorie", selection: $selectedKategorie) {
                        ForEach(kategorien, id: \.self) { kategorie in
                            Text(kategorie)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.leading, 16)
                }
                
                Section(header: Text("Betrag")) {
                    TextField("0.00", text: $betrag)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationBarTitle("Limit hinzufügen")
            .navigationBarItems(trailing: Button(action: {
                saveLimit()
                isPresentingAddLimitView.wrappedValue = false
            }) {
                Text("Hinzufügen")
            })
            .onDisappear {
                onDismiss()
            }
        }
    }
    
    // Abspeichern des neuen Limits im Backend
    func saveLimit() {
        let betragDouble = Double(betrag)
        let newLimit = Limit(id: 0,kategorie: selectedKategorie,benutzer: benutzer, betrag: betragDouble ?? 0)
        
        guard let url = URL(string: "http://localhost:8080/api/v1/limit/") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let encodedBody = try? JSONEncoder().encode(newLimit) else {
            print("Failed to encode data")
            return
        }
        request.httpBody = encodedBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let _ = try? JSONDecoder().decode(Limit.self, from: data) {
                    DispatchQueue.main.async {
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
}

// Screen, der geöffnet wird wenn man auf das jeweilige Limit drückt und dann kann man die Daten entsprechend verändern
struct EditLimitView: View {
    let email: String
    let benutzer: Benutzer
    let limit: Limit
    let onDismiss: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var betrag: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kategorie")) {
                    Text("\(limit.kategorie)")
                }
                
                Section(header: Text("Betrag")) {
                    TextField("0.00", text: $betrag)
                        .keyboardType(.decimalPad)
                        .onAppear {
                            betrag = String(limit.betrag)
                        }
                }
            }
            .navigationBarTitle("Limit bearbeiten")
            .navigationBarItems(trailing:  Button(action: {
                updateLimit()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Speichern")
            })
            .onDisappear {
                onDismiss()
            }
        }
    }
    
    // Speichert die veränderten Limits im Backend
    func updateLimit() {
        let betragDouble = Double(betrag)
        let updatedLimit = Limit(id: limit.id, kategorie: limit.kategorie, benutzer: benutzer, betrag: betragDouble ?? 0)
        
        guard let url = URL(string: "http://localhost:8080/api/v1/limit/") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let encodedBody = try? JSONEncoder().encode(updatedLimit) else {
            print("Failed to encode data")
            return
        }
        request.httpBody = encodedBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let _ = try? JSONDecoder().decode(Limit.self, from: data) {
                    DispatchQueue.main.async {
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
}
