//
//  AddNewActivity.swift
//  Login2
//
//  Created by Daniel Mendes on 29.04.23.
//

import SwiftUI


//Screen, um eine neue Aktivtät hinzuzufügen
struct AddNewActivityView: View {
    let user: Benutzer?
    let actart:String?

    @State var betrag: String = ""
    @State var beschreibung: String = ""
    @State var kategorieIndex = 0
    let kategorien = ["Lebensmittel", "Wohnen", "Sonstiges"]
    @State var datum = Date()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Betrag")) {
                    TextField("0.00", text: $betrag)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Beschreibung")) {
                    TextField("Beschreibung", text: $beschreibung)
                }

                Section(header: Text("Kategorie")) {
                    Picker(selection: $kategorieIndex, label: Text("Kategorie")) {
                        ForEach(0 ..< kategorien.count) { index in
                            Text(kategorien[index])
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Neue Section-Block hinzufügen, um das Datum anzuzeigen
                Section(header: Text("Datum")) {
                    DatePicker(
                        selection: $datum,
                        displayedComponents: [.date]
                    ) {
                        Text("Datum")
                    }
                }

                Button(action: {
                    if let user = user, let betragDouble = Double(betrag), !beschreibung.isEmpty {
                        let kategorie = kategorien[kategorieIndex]
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        let dateString = formatter.string(from: datum)
                        let newAktivitaet = Aktivitaet(id: 0, betrag: betragDouble, beschreibung: beschreibung, kategorie: kategorie, art: actart ?? "", benutzer: user, datum: dateString)
                        saveActivity(newAktivitaet)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Hinzufügen")
                }
            }
            .navigationBarTitle(Text("Neue Aktivität"), displayMode: .inline)
        }
    }


    //Speichert die Aktivität im Backend ab
    func saveActivity(_ activity: Aktivitaet) {
        guard let url = URL(string: "http://localhost:8080/api/v1/aktivitaet") else {
            print("Invalid URL")
            return
        }

        let newAktivitaet = Aktivitaet(id: activity.id, betrag: activity.betrag, beschreibung: activity.beschreibung, kategorie: activity.kategorie, art: activity.art, benutzer: activity.benutzer,datum: activity.datum)

        guard let encodedActivity = try? JSONEncoder().encode(newAktivitaet) else {
            print("Failed to encode activity")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedActivity

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
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
