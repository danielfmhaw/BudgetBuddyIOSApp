// Screen, um eine neue Aktivtät hinzuzufügen
//
//  Created by Daniel Mendes on 29.04.23.
//

import SwiftUI


struct AddNewActivityView: View {
    let user: Benutzer?
    let actart:String?
    let targets: [Target]

    @State var betrag: String = ""
    @State var beschreibung: String = ""
    @State var selectedDisplayMode = 0

    @State private var selectedKategorie = "Lebensmittel"
    let kategorien = ["Lebensmittel","Finanzen","Freizeit","Unterhaltung","Hobbys","Wohnen","Haushalt","Technik","Shopping","Restaurant","Drogerie","Sonstiges"]
    @State private var selectedTarget = ""
    @State var beschreibungTargets: [String] = []
    @State var datum = Date()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isChecked: Bool = false

    var body: some View {
        NavigationView {
            Form {
                //Felder für die jeweiligen Attribute
                Section(header: Text("Betrag")) {
                           TextField("0.00", text: Binding(
                               get: { self.betrag },
                               set: { newValue in
                                   self.betrag = newValue.replacingOccurrences(of: ",", with: ".")
                               })
                           )
                           .keyboardType(.decimalPad)
                }

                Section(header: Text("Beschreibung")) {
                    TextField("Beschreibung", text: $beschreibung)
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
                
                if(actart=="Einnahmen"){
                    VStack(){
                        Toggle(isOn: $isChecked) {
                           Text("Sparplan anlegen?")
                       }
                        if(isChecked){
                            Section(){
                                HStack{
                                    Spacer()
                                    Text("Sparziel:")
                                    Picker(selection: $selectedTarget, label: Text("")) {
                                        ForEach(beschreibungTargets, id: \.self) { targetname in
                                            Text(targetname)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                                
                                Picker("Sparziel in % beteiligen", selection: $selectedDisplayMode) {
                                    Text("5%").tag(0)
                                    Text("10%").tag(1)
                                    Text("20%").tag(2)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                    }
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
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        let dateString = formatter.string(from: datum)
                        var newAktivitaet: Aktivitaet?

                        if (isChecked && !(selectedTarget == "Keine Sparziele")) {
                            if let target = targets.first(where: { $0.targetname == selectedTarget }) {
                                newAktivitaet = Aktivitaet(id: 0, betrag: betragDouble, beschreibung: beschreibung, kategorie: selectedKategorie, art: actart ?? "", benutzer: user, datum: dateString, savingsTarget: target)
                            }
                        } else {
                            newAktivitaet = Aktivitaet(id: 0, betrag: betragDouble, beschreibung: beschreibung, kategorie: selectedKategorie, art: actart ?? "", benutzer: user, datum: dateString, savingsTarget: nil)
                        }

                        if let aktivitaet = newAktivitaet {
                            saveActivity(aktivitaet, targetname: selectedTarget)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Hinzufügen")
                }
            }
            .onAppear {
                setupTargets(email: user?.email ?? "")
            }
            .navigationBarTitle(Text("Neue Aktivität"), displayMode: .inline)
        }
    }
    
    // Bekommt die Targets aus dem Backend
    func setupTargets(email: String) {
        if(targets.count>0){
            beschreibungTargets.append(contentsOf:  targets.map { $0.targetname })
            selectedTarget = beschreibungTargets.first ?? ""
        }else{
            beschreibungTargets.append("Keine Sparziele")
            selectedTarget = "Keine Sparziele"
        }
    }
    
    func calculateDisplayMode(with selectedDisplayMode: Int) -> Double {
        let betrag: Double
        switch selectedDisplayMode {
        case 2:
            betrag = 0.2
        case 1:
            betrag = 0.1
        default:
            betrag = 0.05
        }
        return betrag
    }
    
    //Speichert die Aktivität im Backend ab
    func saveActivity(_ activity: Aktivitaet, targetname:String) {
        guard let url = URL(string: "http://localhost:8080/api/v1/aktivitaet?username=admin&password=password") else {
            print("Invalid URL")
            return
        }

        let newAktivitaet = Aktivitaet(id: activity.id, betrag: activity.betrag, beschreibung: activity.beschreibung, kategorie: activity.kategorie, art: activity.art, benutzer: activity.benutzer,datum: activity.datum,savingsTarget: activity.savingsTarget, anteil: calculateDisplayMode(with: selectedDisplayMode))

        guard let encodedActivity = try? JSONEncoder().encode(newAktivitaet) else {
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
