//
// Hauptscreen nach dem erfolgreichem Login
// (Hauptmenü mit den 4 Icons unten)
//  Created by Daniel Mendes on 29.04.23.
//

import SwiftUI

struct LoggedInView: View {
    var email: String
    var logoutAction: () -> Void

    @State private var aktivitaeten: [Aktivitaet] = []
    @State private var showNewActivityView = false
    @State private var user: Benutzer?
    
    @State private var sucheEinnahmen = ""
    @State private var sucheAusgaben = ""
    
    func formatDate(dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "dd/MM/yyyy"
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    enum SoriertenEinnahmen {
        case ascending
        case descending
    }
    enum SoriertenAusgaben {
        case ascending
        case descending
    }

    @State private var soriertenEinnahmen: SoriertenEinnahmen = .descending
    @State private var soriertenAusgaben: SoriertenAusgaben = .descending


    var body: some View {
        TabView{
            
            //NavigationView für die "Übersicht" (dort sieht man Kontostand und kann Einnahmen/Ausgaben summiert sehen)
            NavigationView{
                VStack {
                    
                    
                    VStack{
                        Text("Kontostand:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(user?.kontostand ?? 0.0, specifier: "%.2f") €")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(user?.kontostand ?? 0.0 >= 0 ? .green : .red)
                    }.padding()
                    
                    
                    VStack(alignment: .leading) {
                        NavigationLink(destination: Kreisdiagramm( art: "Einnahmen", email: email)){
                            HStack {
                                Image(systemName: "eurosign.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.blue)
                                Text("Einnahmenüberblick")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                            }
                        }
                        Divider()
                        HStack {
                            NavigationLink(destination: Kreisdiagramm( art: "Ausgaben", email: email)){
                                Image(systemName: "dollarsign.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.blue)
                                Text("Ausgabenüberblick")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                            }
                        }
                        Divider()
                        HStack {
                            NavigationLink(destination: AnaylseView(email: email)) {
                                Image(systemName: "chart.bar.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.blue)
                                Text("Zeitverlauf")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                            }
                        }
                        Divider()
                        HStack {
                            if let user = user {
                                NavigationLink(destination: LimitView(email: email, benutzer: user)) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.blue)
                                    Text("Limits")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 8)
                                }
                            } else {
                                Text("User is nil")
                            }
                        }
                        Divider()
                        HStack {
                            NavigationLink(destination: LimitAnalyseView(email: email)) {
                                Image(systemName: "chart.bar.doc.horizontal.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.blue)
                                Text("Limit Anaylse")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .navigationBarTitle(Text("Übersicht"), displayMode: .inline)

                    }
                    .onAppear {
                           getBenutzer()
                    }
                    .navigationBarTitle(Text("Übersicht"), displayMode: .inline)
                }
            .tabItem{
                Image(systemName: "chart.bar.fill")
                Text("Übersicht")
            }

            //NavigationView für die "Einnahmen" (Anzeigen, Neue hinzufügen, editieren, löschen)
            NavigationView {
                VStack {
                    Text("Einnahmen")
                        .font(.largeTitle)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                        TextField("Suche...", text: $sucheEinnahmen)
                            .textFieldStyle(DefaultTextFieldStyle())
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .padding(.leading, -4)
                        
                        Menu {
                            Button(action: {
                                soriertenEinnahmen = .ascending
                            }) {
                                Label("Datum aufsteigend", systemImage: "arrow.up")
                            }
                            Button(action: {
                                soriertenEinnahmen = .descending
                            }) {
                                Label("Datum absteigend", systemImage: "arrow.down")
                            }
                        } label: {
                            Label("", systemImage: "arrow.up.arrow.down.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    List {
                        ForEach(Array(aktivitaeten
                            .filter { sucheEinnahmen.isEmpty ? true : $0.beschreibung.localizedCaseInsensitiveContains(sucheEinnahmen) }
                            .sorted(by: soriertenEinnahmen == .ascending ? { $0.datum < $1.datum } : { $0.datum > $1.datum })
                                        .enumerated()), id: \.element.id) { index, aktivitaet in
                            NavigationLink(destination: EditActivityView(activity: aktivitaet)){
                                HStack {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("\(aktivitaet.beschreibung)")
                                            .fontWeight(.semibold)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(aktivitaet.kategorie)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            Text("Betrag:")
                                                .fontWeight(.semibold)
                                            Text("\(aktivitaet.betrag, specifier: "%.2f") €")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text(formatDate(dateString: aktivitaet.datum))
                                            .foregroundColor(.gray)
                                            .padding(.trailing)
                                    }
                                }
                                .padding(.vertical, 10)
                                .contextMenu {
                                    Button(action: {
                                        deleteAktivitaet(id: aktivitaet.id,art: "Einnahmen")
                                    }) {
                                        Text("Löschen")
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            let indexesToDelete = indexSet.map { $0 }
                            for index in indexesToDelete {
                                let aktivitaet = aktivitaeten
                                    .filter { sucheEinnahmen.isEmpty ? true : $0.beschreibung.localizedCaseInsensitiveContains(sucheEinnahmen) }
                                    .sorted(by: soriertenEinnahmen == .ascending ? { $0.datum < $1.datum } : { $0.datum > $1.datum })[index]
                                deleteAktivitaet(id: aktivitaet.id, art: "Einnahmen")
                            }
                        }
                    }
                    .padding(.horizontal, -20)
                    
                    Spacer()
                }
                .navigationBarTitle(Text("Übersicht"), displayMode: .inline)
                .navigationBarItems(trailing:
                    NavigationLink(destination: AddNewActivityView(user: user, actart: "Einnahmen")) {
                        Text("Hinzufügen")
                    }
                )
                .onAppear() {
                    getAktivitaeten(name: "Einnahmen")
                    getBenutzer()
                }
            }
            .tabItem {
                Image(systemName: "eurosign.circle.fill")
                Text("Einnahmen")
            }


            //NavigationView für die "Ausgaben" (Anzeigen, Neue hinzufügen, editieren, löschen)
            NavigationView {
                VStack {
                    Text("Ausgaben")
                        .font(.largeTitle)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                        TextField("Suche...", text: $sucheAusgaben)
                            .textFieldStyle(DefaultTextFieldStyle())
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .padding(.leading, -4)
                        
                        Menu {
                            Button(action: {
                                soriertenAusgaben = .ascending
                            }) {
                                Label("Datum aufsteigend", systemImage: "arrow.up")
                            }
                            Button(action: {
                                soriertenAusgaben = .descending
                            }) {
                                Label("Datum absteigend", systemImage: "arrow.down")
                            }
                        } label: {
                            Label("", systemImage: "arrow.up.arrow.down.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    List {
                        ForEach(Array(aktivitaeten
                                        .filter { sucheAusgaben.isEmpty ? true : $0.beschreibung.localizedCaseInsensitiveContains(sucheAusgaben) }
                                        .sorted(by: soriertenAusgaben == .ascending ? { $0.datum < $1.datum } : { $0.datum > $1.datum })
                                        .enumerated()), id: \.element.id) { index, aktivitaet in
                            NavigationLink(destination: EditActivityView(activity: aktivitaet)){
                                HStack {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("\(aktivitaet.beschreibung)")
                                            .fontWeight(.semibold)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(aktivitaet.kategorie)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            Text("Betrag:")
                                                .fontWeight(.semibold)
                                            Text("\(aktivitaet.betrag, specifier: "%.2f") €")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text(formatDate(dateString: aktivitaet.datum))
                                            .foregroundColor(.gray)
                                            .padding(.trailing)
                                    }
                                }
                                .padding(.vertical, 10)
                                .contextMenu {
                                    Button(action: {
                                        deleteAktivitaet(id: aktivitaet.id, art: "Ausgaben")
                                    }) {
                                        Text("Löschen")
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            let indexesToDelete = indexSet.map { $0 }
                            for index in indexesToDelete {
                                let aktivitaet = aktivitaeten
                                    .filter { sucheAusgaben.isEmpty ? true : $0.beschreibung.localizedCaseInsensitiveContains(sucheAusgaben) }
                                    .sorted(by: soriertenAusgaben == .ascending ? { $0.datum < $1.datum } : { $0.datum > $1.datum })[index]
                                deleteAktivitaet(id: aktivitaet.id, art: "Ausgaben")
                            }
                        }
                    }
                    .padding(.horizontal, -20)
                    
                    Spacer()
                }
                .navigationBarTitle(Text("Übersicht"), displayMode: .inline)
                    .navigationBarItems(trailing:
                        NavigationLink(destination: AddNewActivityView(user: user, actart: "Ausgaben")) {
                            Text("Hinzufügen")
                        }
                    )
                .onAppear() {
                    getAktivitaeten(name: "Ausgaben")
                    getBenutzer()
                }
            }
            .tabItem{
                Image(systemName: "eurosign.square.fill")
                Text("Ausgaben")
            }
            
    
            
            //NavigationView für die "Einstellungen" (aktuell wird nur zu BenutzerView verlinkt und es gibt einen deafault: "allgemein" und den Chat)
            NavigationView {
                VStack(alignment: .leading) {
                    NavigationLink(destination: BenutzerView(email: email))
                    {
                        HStack {
                            Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                            Text("Benutzerdaten")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
                        }
                    }
                    Divider()
                    HStack {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                        Text("Allgemein")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                    }
                    Divider()
                    NavigationLink(destination: Buddy(email: email)) {
                        HStack {
                            Image(systemName: "lightbulb.circle")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                            Text("Tipps")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
                        }
                    }
                    Divider()
                    Spacer()
                }
                .padding()
                .navigationBarTitle(Text("Einstellungen"), displayMode: .inline)
                .navigationBarItems(trailing:
                    Button(action: {
                        self.logoutAction()
                    }) {
                        Text("Logout")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                )
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Einstellungen")
            }

               
        }
    }
    
    //Löscht die Aktivität im Backend
    func deleteAktivitaet(id: Int,art:String) {
        guard let url = URL(string: "https://budgetbuddyback.fly.dev/api/v1/aktivitaet/\(id)?username=admin&password=password") else {
            print("Ungültige URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Fehler beim Löschen der Aktivität: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Ungültige Serverantwort")
                return
            }
            
            if httpResponse.statusCode == 200 {
                // Aktualisiere die Aktivitätenliste
                getAktivitaeten(name: art)
            } else {
                print("Fehler beim Löschen der Aktivität: HTTP-Statuscode \(httpResponse.statusCode)")
            }
        }.resume()
    }

    //Bekommt die Benutzerdaten aus dem Backend
    func getBenutzer() {
        guard let url = URL(string: "https://budgetbuddyback.fly.dev/api/v1/benutzer/\(email)?username=admin&password=password") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                print("Error fetching user: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let decodedUser = try? JSONDecoder().decode(Benutzer.self, from: data) {
                DispatchQueue.main.async {
                    self.user = decodedUser
                }
            } else {
                print("Invalid response from server")
            }
        }.resume()
    }
    
    //Bekommt die Aktivitäten aus dem Backend
    func getAktivitaeten(name:String) {
        guard let url = URL(string: "https://budgetbuddyback.fly.dev/api/v1/aktivitaet/withArt/\(email)/\(name)?username=admin&password=password") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let decodedResponse = try? JSONDecoder().decode([Aktivitaet].self, from: data) {
                DispatchQueue.main.async {
                    self.aktivitaeten = decodedResponse
                }
            } else {
                print("Invalid response from server")
            }
        }.resume()
    }
}
