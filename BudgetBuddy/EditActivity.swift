// Screen, um eine Aktivtät zu editieren/verändern
//
//  Created by Daniel Mendes on 29.04.23

import SwiftUI


//Screen, um eine Aktivtät zu editieren/verändern
struct EditActivityView: View {
    let activity: Aktivitaet
    @State var betrag: String
    @State var beschreibung: String
    @State var datum: Date
    @State private var selectedKategorie : String
    let kategorien = ["Lebensmittel","Finanzen","Freizeit","Unterhaltung","Hobbys","Wohnen","Haushalt","Technik","Shopping","Restaurant","Drogerie","Sonstiges"]
    @Environment(\.presentationMode) var presentationMode
    
    init(activity: Aktivitaet) {
        self.activity = activity
        self._betrag = State(initialValue: String(activity.betrag))
        self._beschreibung = State(initialValue: activity.beschreibung)
        self._selectedKategorie = State(initialValue: activity.kategorie)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: activity.datum) {
            self._datum = State(initialValue: date)
        } else {
            self._datum = State(initialValue: Date())
        }
    }
    
    // Entsprechende bisher gepeicherte Attribute angezeigt und verändertbar und mit Button abspeichbar
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Betrag")) {
                           TextField("0.00", text: Binding(
                               get: { self.betrag },
                               set: { newValue in
                                   self.betrag = newValue.replacingOccurrences(of: ",", with: ".")
                               })
                           )
                           .keyboardType(.decimalPad)
                           .onAppear {
                               betrag = String(activity.betrag)
                           }
                }
                
                Section(header: Text("Beschreibung")) {
                    TextField("Beschreibung", text: $beschreibung)
                        .onAppear {
                            beschreibung = activity.beschreibung
                        }
                }
                
                Section(header: Text("Kategorie")){
                            Picker(selection: $selectedKategorie, label: Text("")) {
                                ForEach(kategorien, id: \.self) { kategorie in
                                    Text(kategorie)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.leading, 16)
                }
                
                Section(header: Text("Datum")) {
                    DatePicker("Datum", selection: $datum, displayedComponents: [.date])
                        //.datePickerStyle(WheelDatePickerStyle()) --> nimmt bisschen zu viel Platz weg
                        .onAppear {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                            if let date = dateFormatter.date(from: activity.datum) {
                                datum = date
                            }
                        }
                }
                
                Button(action: {
                    if let betragDouble = Double(betrag), !beschreibung.isEmpty {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        let dateString = formatter.string(from: datum)
                        let updatedAktivitaet = Aktivitaet(
                            id: activity.id,
                            betrag: betragDouble,
                            beschreibung: beschreibung,
                            kategorie: selectedKategorie,
                            art: activity.art,
                            benutzer: activity.benutzer,
                            datum: dateString
                        )
                        saveActivity(updatedAktivitaet)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Speichern")
                }
            }
            .navigationBarTitle(Text("Aktivität bearbeiten"), displayMode: .inline)
        }
    }


    
    //Updated die entsprechende Aktivtät im Backend
    func saveActivity(_ activity: Aktivitaet) {
        guard let url = URL(string: "http://localhost:8080/api/v1/aktivitaet?username=admin&password=password") else {
            print("Invalid URL")
            return
        }
        
        let updatedAktivitaet = Aktivitaet(
            id: activity.id,
            betrag: activity.betrag,
            beschreibung: activity.beschreibung,
            kategorie: activity.kategorie,
            art: activity.art,
            benutzer: activity.benutzer,
            datum: activity.datum
        )
        
        guard let encodedActivity = try? JSONEncoder().encode(updatedAktivitaet) else {
            print("Failed to encode activity")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedActivity
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                print("Successfully saved activity")
            } else {
                print("Invalid response from server")
            }
        }.resume()
    }
}
