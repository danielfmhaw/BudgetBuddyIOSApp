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
    
    @State var targets: [Target] = []
    @State private var selectedTarget = ""
    @State var beschreibungTargets: [String] = []
    @State var selectedDisplayMode = 0
    @State private var isChecked: Bool = false
    
    init(activity: Aktivitaet) {
        self.activity = activity
        self._betrag = State(initialValue: String(activity.betrag))
        self._beschreibung = State(initialValue: activity.beschreibung)
        self._selectedKategorie = State(initialValue: activity.kategorie)
        self._selectedTarget = State(initialValue: activity.savingsTarget?.targetname ?? "")
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
                
                if(activity.art=="Einnahmen"){
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
                                        if selectedTarget.isEmpty {
                                            Text("Auswählen")
                                        }
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

                        var newAktivitaet: Aktivitaet?
                        
                        if (isChecked && !selectedTarget.isEmpty) {
                            if let target = targets.first(where: { $0.targetname == selectedTarget }) {
                                newAktivitaet = Aktivitaet(id: activity.id, betrag: betragDouble, beschreibung: beschreibung, kategorie: selectedKategorie, art: activity.art, benutzer: activity.benutzer, datum: dateString, savingsTarget: target, anteil: calculateDisplayMode(with: selectedDisplayMode))
                            }
                        } else {
                            newAktivitaet = Aktivitaet(id: activity.id, betrag: betragDouble, beschreibung: beschreibung, kategorie: selectedKategorie, art: activity.art, benutzer: activity.benutzer, datum: dateString)
                        }

                        if let aktivitaet = newAktivitaet {
                            saveActivity(aktivitaet)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Speichern")
                }
            }
            .onAppear {
                fetchTargets(email: activity.benutzer.email)
            }
            .navigationBarTitle(Text("Aktivität bearbeiten"), displayMode: .inline)
        }
    }
    
    //Umwandlung des Pickers
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

    // Bekommt die Targets aus dem Backend
    func fetchTargets(email: String) {
        guard let url = URL(string: "https://budgetbuddyback.fly.dev/api/v1/targets/\(email)?username=admin&password=password") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode([Target].self, from: data) {
                    DispatchQueue.main.async {
                        targets = decodedResponse
                        if(targets.count>0){
                            beschreibungTargets.append(contentsOf:  decodedResponse.map { $0.targetname })
                        }else{
                            beschreibungTargets.append("Keine Sparziele")
                        }
                        if(activity.savingsTarget != nil){
                            isChecked = true
                        }
                        if(activity.anteil == 0.2 ){
                            selectedDisplayMode = 2
                        }else if(activity.anteil == 0.1){
                            selectedDisplayMode = 1
                        }else{
                            selectedDisplayMode = 0
                        }
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
    
    //Aktivtät updaten (per PUT)
    func saveActivity(_ activity: Aktivitaet) {
        guard let url = URL(string: "https://budgetbuddyback.fly.dev/api/v1/aktivitaet?username=admin&password=password") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let encodedActivity = try? JSONEncoder().encode(activity) else {
            print("Failed to encode activity")
            return
        }
        
        request.httpBody = encodedActivity
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("Successfully saved activity")
            } else {
                print("Invalid response from server")
            }
        }.resume()
    }

}
