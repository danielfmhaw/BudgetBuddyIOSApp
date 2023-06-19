//
//  SavingsTarget.swift
//  BudgetBuddy
//
//  Created by Daniel Mendes on 08.06.23.
//

import SwiftUI

// Struktur eines "SavingTarget" (genauso wie im Backend gespeichert)
struct Target: Codable, Identifiable {
    var id: Int
    var targetname: String
    var benutzer: Benutzer
    var zielbetrag: Double
    var aktbetrag: Double
}

struct SavingsTarget: View {
    let email: String
    let benutzer: Benutzer
    @State var targets: [Target] = []

    @State var isPresentingAddTargetView = false
    @State var isPresentingEditTargeView = false
    @State var selectedTarget: Target?

    var body: some View {
        ZStack {
            VStack{
                Text("Spar-Ziele")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                if !targets.isEmpty {
                    // Anzeige alle Targets für den Benutzer
                    List {
                        ForEach(targets, id: \.id) { target in
                            HStack {
                                Text("\(target.targetname)")
                                    .fontWeight(.semibold)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Spacer()

                                HStack {
                                    Text("\(target.zielbetrag, specifier: "%.2f") € (\(Int((target.aktbetrag/target.zielbetrag) * 100))%)")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 10)
                            // Löschen des ausgwählten Targets
                            .contextMenu {
                                Button(action: {
                                    deleteTarget(id: target.id)
                                }) {
                                    Text("Löschen")
                                    Image(systemName: "trash")
                                }
                            }
                            .onTapGesture {
                                selectedTarget = target
                            }
                        }
                        // Löschen des ausgwählten Targets
                        .onDelete { indexSet in
                            for index in indexSet {
                                deleteTarget(id: targets[index].id)
                            }
                        }
                    }
                    // Editieren des ausgwählten Targets
                    .sheet(item: $selectedTarget) { target in
                        EditSavingsTarget(email: email, benutzer: benutzer, target: target, onDismiss: {
                            fetchTargets()
                        })
                    }
                } else {
                    List{
                        Text("Keine Targets gefunden")
                    }
                }
            }
            // HInzufügen eines Targets mit Button an oberer rechter Seite
            .navigationBarItems(trailing:
                Button(action: {
                    isPresentingAddTargetView.toggle()
                }) {
                    Text("Hinzufügen")
                }
                .sheet(isPresented: $isPresentingAddTargetView) {
                    AddSavingsTarget(email: email, benutzer: benutzer, isPresentingAddTargetView: $isPresentingAddTargetView, onDismiss: {
                        fetchTargets()
                    })
                }
            )
        }
    }

    //Bekommt die Targets aus dem Backend
    func fetchTargets() {
        guard let url = URL(string: "https://budgetbuddybackweb.fly.dev/api/v1/targets/\(email)?username=admin&password=password") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode([Target].self, from: data) {
                    DispatchQueue.main.async {
                        targets = decodedResponse
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
    
    //Löscht das Target im Backend
    func deleteTarget(id: Int) {
        guard let url = URL(string: "https://budgetbuddybackweb.fly.dev/api/v1/targets/\(id)?username=admin&password=password") else {
            print("Ungültige URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Fehler beim Löschen des Targets: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Ungültige Serverantwort")
                return
            }
            
            if httpResponse.statusCode == 200 {
                // Aktualisiere die Targetsliste
                fetchTargets()
            } else {
                print("Fehler beim Löschen des Targets: HTTP-Statuscode \(httpResponse.statusCode)")
            }
        }.resume()
    }

}

// Screen, wo man Target hinzufügen kann
struct AddSavingsTarget: View {
    let email: String
    let benutzer: Benutzer
    let isPresentingAddTargetView: Binding<Bool>
    let onDismiss: () -> Void
    
    @State var targetname : String = ""
    @State var betrag: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name des Sparziels")) {
                    TextField("Sparzielname", text: $targetname)
                }
                
                Section(header: Text("Betrag")) {
                           TextField("0.00", text: Binding(
                               get: { self.betrag },
                               set: { newValue in
                                   self.betrag = newValue.replacingOccurrences(of: ",", with: ".")
                               })
                           )
                           .keyboardType(.decimalPad)
                }
            }
            .navigationBarTitle("Target hinzufügen")
            .navigationBarItems(trailing: Button(action: {
                saveTarget()
                isPresentingAddTargetView.wrappedValue = false
            }) {
                Text("Hinzufügen")
            })
            .onDisappear {
                onDismiss()
            }
        }
    }
    
    // Abspeichern des neuen Targets im Backend
    func saveTarget() {
        let betragDouble = Double(betrag)
        let newTarget = Target(id: 0,targetname: targetname ,benutzer: benutzer, zielbetrag: betragDouble ?? 0, aktbetrag: 0)
        
        guard let url = URL(string: "https://budgetbuddybackweb.fly.dev/api/v1/targets/?username=admin&password=password") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let encodedBody = try? JSONEncoder().encode(newTarget) else {
            print("Failed to encode data")
            return
        }
        request.httpBody = encodedBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let _ = try? JSONDecoder().decode(Target.self, from: data) {
                    DispatchQueue.main.async {
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
}

// Screen, der geöffnet wird wenn man auf das jeweilige Target drückt und dann kann man die Daten entsprechend verändern
struct EditSavingsTarget: View {
    let email: String
    let benutzer: Benutzer
    let target: Target
    let onDismiss: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var targetname : String = ""
    
    @State var betrag: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name des Sparziels")) {
                    TextField("Sparzielname", text: $targetname)
                        .onAppear {
                            targetname = target.targetname
                        }
                }
                
                Section(header: Text("Betrag")) {
                           TextField("0.00", text: Binding(
                               get: { self.betrag },
                               set: { newValue in
                                   self.betrag = newValue.replacingOccurrences(of: ",", with: ".")
                               })
                           )
                           .keyboardType(.decimalPad)
                           .onAppear {
                               betrag = String(target.zielbetrag)
                           }
                }
            }
            .navigationBarTitle("Target bearbeiten")
            .navigationBarItems(trailing:  Button(action: {
                updateTarget()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Speichern")
            })
            .onDisappear {
                onDismiss()
            }
        }
    }
    
    // Speichert die veränderten Targets im Backend
    func updateTarget() {
        let betragDouble = Double(betrag)
        let updatedTarget = Target(id: target.id, targetname: targetname, benutzer: benutzer, zielbetrag: betragDouble ?? 0,aktbetrag: 0)
        
        guard let url = URL(string: "https://budgetbuddybackweb.fly.dev/api/v1/targets/?username=admin&password=password") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let encodedBody = try? JSONEncoder().encode(updatedTarget) else {
            print("Failed to encode data")
            return
        }
        request.httpBody = encodedBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let _ = try? JSONDecoder().decode(Target.self, from: data) {
                    DispatchQueue.main.async {
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
}

