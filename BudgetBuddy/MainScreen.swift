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
    
    @State var limits: [Limit] = []
    @State var limitAnalysen: [LimitAnalyse] = []
    
    @State var targets: [Target] = []
    @State private var kategorieneinnahmen: [Kategorie] = []
    @State private var kategorienausgaben: [Kategorie] = []
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var aktivitaetenSummen: [Double] = []
    @State private var selectedInterval = "Woche"


    var body: some View {
        TabView{
            
            //NavigationView für die "Übersicht" (dort sieht man Kontostand und kann Einnahmen/Ausgaben summiert sehen)
            NavigationView{
                ScrollView{
                    VStack {
                        VStack{
                            Text("Kontostand:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(user?.kontostand ?? 0.0, specifier: "%.2f") €")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(user?.kontostand ?? 0.0 >= 0 ? .green : .red)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }.padding()
                        
                        VStack(alignment: .leading) {
                            NavigationLink(destination: Kreisdiagramm(kategorien: kategorieneinnahmen, art: "Einnahmen", email: email)) {
                                VStack(alignment: .leading) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "eurosign.circle.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.blue)
                                        
                                        Text("Einnahmenüberblick")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }

                                    if !kategorieneinnahmen.isEmpty {
                                        Divider()
                                        let filteredSortedKategorien = kategorieneinnahmen.filter { $0.einnahmen != 0 }.sorted { $0.einnahmen > $1.einnahmen }
                                        
                                        let endIndex = min(filteredSortedKategorien.count, 4)
                                        
                                        if endIndex > 1 {
                                            let gesamt = filteredSortedKategorien[0].einnahmen
                                            
                                            HStack() {
                                                Spacer()
                                                
                                                ForEach(1..<endIndex, id: \.self) { index in
                                                    let kategorie = filteredSortedKategorien[index]
                                                    let prozentualerAnteil = kategorie.einnahmen / gesamt
                                                    
                                                    VStack {
                                                        Text(kategorie.id)
                                                            .font(.subheadline)
                                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                                        
                                                        ZStack {
                                                            Circle()
                                                                .frame(width: 60, height: 60)
                                                                .foregroundColor(colorScheme == .light ? Color.white : Color.black)
                                                                .overlay(
                                                                    Circle()
                                                                        .stroke(Color.green, lineWidth: 2)
                                                                )
                                                            
                                                            Image(systemName: categoryIcon(for: kategorie.id))
                                                                .font(.system(size: 24))
                                                                .foregroundColor(.green)
                                                            
                                                            
                                                            Circle()
                                                                .trim(from: 0, to: CGFloat(prozentualerAnteil))
                                                                .stroke(Color.green, lineWidth: 5)
                                                                .frame(width: 60, height: 60)
                                                                .rotationEffect(.degrees(-90))
                                                        }
                                                        .padding(.horizontal,20)
                                                        
                                                        Text("\(String(format: "%0.0f", kategorie.einnahmen))€")
                                                            .font(.subheadline)
                                                            .foregroundColor(.green)
                                                            .lineLimit(1)
                                                            .minimumScaleFactor(0.5)
                                                    }
                                                }
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(colorScheme == .light ? Color.white : Color.black)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(Color.gray, lineWidth: colorScheme == .dark ? 0.5 : 0)
                                )
                                .shadow(color: .gray, radius: 1, x: 0, y: 1)
                            }
                            NavigationLink(destination: Kreisdiagramm(kategorien: kategorienausgaben, art: "Ausgaben", email: email)) {
                                VStack(alignment: .leading) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "eurosign.square.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.blue)
                                        
                                        Text("Ausgabenüberblick")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    
                                    if !kategorienausgaben.isEmpty {
                                        let filteredSortedKategorien = kategorienausgaben.filter { $0.einnahmen != 0 }.sorted { $0.einnahmen > $1.einnahmen }
                                        
                                        let endIndex = min(filteredSortedKategorien.count, 4)
                                        
                                        if endIndex > 1 {
                                            let gesamt = filteredSortedKategorien[0].einnahmen
                                            
                                            ForEach(1..<endIndex, id: \.self) { index in
                                                let kategorie = filteredSortedKategorien[index]
                                                let prozentualerAnteil = kategorie.einnahmen / gesamt
                                                
                                                HStack {
                                                    Text("\(index). \(kategorie.id)")
                                                        .font(.subheadline)
                                                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                                    
                                                    Spacer()
                                                    
                                                    Text("\(String(format: "%.2f", kategorie.einnahmen)) €")
                                                        .font(.subheadline)
                                                        .foregroundColor(.red)
                                                }
                                                
                                                ZStack(alignment: .leading) {
                                                    Rectangle()
                                                        .frame(height: 8)
                                                        .foregroundColor(.gray)
                                                    
                                                    Rectangle()
                                                        .frame(width: CGFloat(prozentualerAnteil) * UIScreen.main.bounds.width, height: 8)
                                                        .foregroundColor(.red)
                                                }
                                                .cornerRadius(4)
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(colorScheme == .light ? Color.white : Color.black)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(Color.gray, lineWidth: colorScheme == .dark ? 0.5 : 0)
                                )
                                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                            }
                            
                            VStack{
                                NavigationLink(destination: AnalyseView(email: email,aktivitaeten: aktivitaeten)) {
                                    VStack(alignment: .leading) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "chart.bar.fill")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                                .foregroundColor(.blue)
                                            
                                            Text("Trends")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.primary)
                                                .padding(.trailing, 8)
                                        }
                                    }}
                                if !aktivitaetenSummen.isEmpty {
                                    Picker("Intervall", selection: $selectedInterval) {
                                        Text("Woche").tag("Woche")
                                        Text("Monat").tag("Monat")
                                        Text("Jahr").tag("Jahr")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    
                                    switch selectedInterval {
                                    case "Jahr":
                                        getComparisonText(value: aktivitaetenSummen[2] * 100-100, isIncome: true)
                                        getComparisonText(value: aktivitaetenSummen[5] * 100-100, isIncome: false)
                                    case "Monat":
                                        getComparisonText(value: aktivitaetenSummen[8] * 100-100, isIncome: true)
                                        getComparisonText(value: aktivitaetenSummen[11] * 100-100, isIncome: false)
                                    case "Woche":
                                        getComparisonText(value: aktivitaetenSummen[14] * 100-100, isIncome: true)
                                        getComparisonText(value: aktivitaetenSummen[17] * 100-100, isIncome: false)
                                    default:
                                        Text("Keine Daten")
                                    }
                                }
                            }
                            .padding()
                            .background(colorScheme == .light ? Color.white : Color.black)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.gray, lineWidth: colorScheme == .dark ? 0.5 : 0)
                            )
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                            VStack(alignment: .leading){
                                HStack{
                                    NavigationLink(destination: LimitAnalyseView(email: email, limitAnalysen: limitAnalysen, limits: limits)) {
                                        HStack {
                                            Image(systemName: "chart.bar.doc.horizontal.fill")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                                .foregroundColor(.blue)
                                            Text("Budgets")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .padding(.leading, 8)
                                        }
                                        Spacer()
                                    }
                                    if let user = user {
                                        NavigationLink(destination: LimitView(email: email, benutzer: user)) {
                                            Text("Bearbeiten")
                                        }
                                    }
                                    NavigationLink(destination: LimitAnalyseView(email: email, limitAnalysen: limitAnalysen, limits: limits)) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.primary)
                                            .padding(.trailing, 8)
                                    }
                                }
                                Divider()
                                HStack {
                                    NavigationLink(destination: LimitAnalyseView(email: email, limitAnalysen: limitAnalysen, limits: limits)) {
                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],spacing: 8) {
                                            ForEach(limits, id: \.id) { limit in
                                                if let limitAnalyse = limitAnalysen.first(where: { $0.kategorie == limit.kategorie }) {
                                                    ZStack {
                                                        Circle()
                                                            .foregroundColor(Color.cyan)
                                                            .frame(width: 50, height: 50)
                                                        Circle()
                                                            .trim(from: 0, to: CGFloat(limitAnalyse.aktuell / limit.betrag))
                                                            .stroke(limitAnalyse.ueberschuss >= 0 ? Color.green : Color.red, lineWidth: 5)
                                                            .frame(width: 50, height: 50)
                                                            .rotationEffect(.degrees(-90))
                                                        VStack {
                                                            Image(systemName: categoryIcon(for: limit.kategorie))
                                                                .resizable()
                                                                .frame(width: 20, height: 20)
                                                                .foregroundColor(colorScheme == .light ? Color.white : Color.black)
                                                        }
                                                    }
                                                    .padding(4)
                                                }
                                            }
                                            if let user = user {
                                                NavigationLink(destination: LimitAnalyseView(email: email, limitAnalysen: limitAnalysen, limits: limits)) {
                                                    ZStack {
                                                        Circle()
                                                            .foregroundColor(Color.red)
                                                            .frame(width: 50, height: 50)
                                                        Image(systemName: "plus")
                                                            .resizable()
                                                            .frame(width: 20, height: 20)
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(colorScheme == .light ? Color.white : Color.black)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.gray, lineWidth: colorScheme == .dark ? 0.5 : 0)
                            )
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                            if let user = user {
                                VStack{
                                    NavigationLink(destination: SavingsTarget(email: email, benutzer: user, targets: targets)) {
                                        VStack(alignment: .leading) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "flag.fill")
                                                    .resizable()
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(.blue)
                                                
                                                Text("Spar Ziel")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.primary)
                                                    .padding(.trailing, 8)
                                            }
                                            Divider()
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
                                            }
                                        }
                                        .padding()
                                        .background(colorScheme == .light ? Color.white : Color.black)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                //.strokeBorder(colorScheme == .dark ? Color.white : Color.gray, lineWidth: colorScheme == .dark ? 1 : 0)
                                                .strokeBorder(Color.gray, lineWidth: colorScheme == .dark ? 0.5 : 0)
                                        )
                                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                                    }
                                }
                            }else {
                                Text("User is nil")
                            }
                            Spacer()
                        }
                        .padding()
                        .navigationBarTitle(Text("Übersicht"), displayMode: .inline)
                        
                    }
                    .onAppear {
                        fetchAktivitaeten()
                        fetchLimits()
                        fetchBenutzer()
                        fetchTargets()
                    }
                    .navigationBarTitle(Text("Übersicht"), displayMode: .inline)
                }
            }
            .tabItem{
                Image(systemName: "chart.bar.fill")
                Text("Übersicht")
            }
            .onAppear {
                fetchAktivitaeten()
                fetchLimits()
                fetchBenutzer()
                fetchTargets()
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
                            .filter { $0.art == "Einnahmen" }
                            .filter { sucheEinnahmen.isEmpty ? true : $0.beschreibung.localizedCaseInsensitiveContains(sucheEinnahmen) }
                            .sorted(by: soriertenEinnahmen == .ascending ? { $0.datum < $1.datum } : { $0.datum > $1.datum })
                                        .enumerated()), id: \.element.id) { index, aktivitaet in
                            NavigationLink(destination: EditActivityView(activity: aktivitaet)){
                                HStack {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("\(aktivitaet.beschreibung)")
                                            .lineLimit(2)
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
                                        deleteAktivitaet(id: aktivitaet.id)
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
                                    .filter { $0.art == "Einnahmen" }
                                    .filter { sucheEinnahmen.isEmpty ? true : $0.beschreibung.localizedCaseInsensitiveContains(sucheEinnahmen) }
                                    .sorted(by: soriertenEinnahmen == .ascending ? { $0.datum < $1.datum } : { $0.datum > $1.datum })[index]
                                deleteAktivitaet(id: aktivitaet.id)
                            }
                        }
                    }
                    .padding(.horizontal, -20)
                    
                    Spacer()
                }
                .navigationBarTitle(Text("Übersicht"), displayMode: .inline)
                .navigationBarItems(trailing:
                        NavigationLink(destination: AddNewActivityView(user: user, actart: "Einnahmen",targets:targets)) {
                        Text("Hinzufügen")
                    }
                )
                .onAppear() {
                    fetchAktivitaeten()
                    fetchBenutzer()
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
                                        .filter { $0.art == "Ausgaben" }
                                        .filter { sucheAusgaben.isEmpty ? true : $0.beschreibung.localizedCaseInsensitiveContains(sucheAusgaben) }
                                        .sorted(by: soriertenAusgaben == .ascending ? { $0.datum < $1.datum } : { $0.datum > $1.datum })
                                        .enumerated()), id: \.element.id) { index, aktivitaet in
                            NavigationLink(destination: EditActivityView(activity: aktivitaet)){
                                HStack {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("\(aktivitaet.beschreibung)")
                                            .lineLimit(2)
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
                                        deleteAktivitaet(id: aktivitaet.id)
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
                                    .filter { $0.art == "Ausgaben" }
                                    .filter { sucheAusgaben.isEmpty ? true : $0.beschreibung.localizedCaseInsensitiveContains(sucheAusgaben) }
                                    .sorted(by: soriertenAusgaben == .ascending ? { $0.datum < $1.datum } : { $0.datum > $1.datum })[index]
                                deleteAktivitaet(id: aktivitaet.id)
                            }
                        }
                    }
                    .padding(.horizontal, -20)
                    
                    Spacer()
                }
                .navigationBarTitle(Text("Übersicht"), displayMode: .inline)
                    .navigationBarItems(trailing:
                            NavigationLink(destination: AddNewActivityView(user: user, actart: "Ausgaben",targets:targets)) {
                            Text("Hinzufügen")
                        }
                    )
                .onAppear() {
                    fetchAktivitaeten()
                    fetchBenutzer()
                }
            }
            .tabItem{
                Image(systemName: "eurosign.square.fill")
                Text("Ausgaben")
            }
            
            
    
            
            //NavigationView für die "Einstellungen" (aktuell wird nur zu BenutzerView verlinkt und es gibt einen deafault: "allgemein" und den Chat)
            NavigationView {
                VStack(alignment: .leading) {
                    NavigationLink(destination: Buddy(email: email, limits: limits, activities: aktivitaeten)) {
                        HStack {
                            Image(systemName: "message.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                            Text("Chat")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
                        }
                    }
                    Divider()
                    NavigationLink(destination: BenutzerView(email: email))
                    {
                        HStack {
                            Image(systemName: "person.fill")
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
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                            Text("Einstellungen")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
                        }
                    }
                    Divider()
                    Spacer()
                }
                .padding()
                .navigationBarTitle(Text("Mehr"), displayMode: .inline)
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
                Image(systemName: "ellipsis.circle.fill")
                Text("Mehr")
            }
            .onAppear{
                fetchAktivitaeten()
                fetchLimits()
            }
        }
    }
    
    //Löscht die Aktivität im Backend
    func deleteAktivitaet(id: Int) {
        guard let url = URL(string: "http://localhost:8080/api/v1/aktivitaet/\(id)?username=admin&password=password") else {
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
                // Aktualisiere die Aktivitätenliste, d.h. lösche Aktivitat mit entsprecheneder ID aus Liste
                fetchAktivitaeten()
            } else {
                print("Fehler beim Löschen der Aktivität: HTTP-Statuscode \(httpResponse.statusCode)")
            }
        }.resume()
    }

    //Bekommt die Benutzerdaten aus dem Backend
    func fetchBenutzer() {
        guard let url = URL(string: "http://localhost:8080/api/v1/benutzer/\(email)?username=admin&password=password") else {
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
    func fetchAktivitaeten() {
        let url = URL(string: "http://localhost:8080/api/v1/aktivitaet/\(email)?username=admin&password=password")

        guard let requestURL = url else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: requestURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let decodedResponse = try? JSONDecoder().decode([Aktivitaet].self, from: data) {
                DispatchQueue.main.async {
                    // Prüfen, welche Aktivitäten bereits vorhanden sind
                    let existingIDs = Set(self.aktivitaeten.map { $0.id })

                    // Aktualisierte Aktivitäten, die hinzugefügt oder aktualisiert werden sollen
                    var updatedAktivitaeten: [Aktivitaet] = []

                    for aktivitaet in decodedResponse {
                        if existingIDs.contains(aktivitaet.id) {
                            // Aktualisieren, falls die Aktivität bereits vorhanden ist
                            if let index = self.aktivitaeten.firstIndex(where: { $0.id == aktivitaet.id }) {
                                self.aktivitaeten[index] = aktivitaet
                            }
                        } else {
                            // Hinzufügen, falls die Aktivität noch nicht vorhanden ist
                            updatedAktivitaeten.append(aktivitaet)
                        }
                    }

                    // Hinzufügen der neuen Aktivitäten
                    self.aktivitaeten.append(contentsOf: updatedAktivitaeten)

                    // Aktualisierung der Summen (nur für hinzugefügte Aktivitäten)
                    aktivitaetenSummen.append(contentsOf: getYearSum(art: "Einnahmen", aktivitaeten: aktivitaeten))
                    aktivitaetenSummen.append(contentsOf: getYearSum(art: "Ausgaben", aktivitaeten: aktivitaeten))
                    aktivitaetenSummen.append(contentsOf: getMonthSum(art: "Einnahmen", aktivitaeten: aktivitaeten))
                    aktivitaetenSummen.append(contentsOf: getMonthSum(art: "Ausgaben", aktivitaeten: aktivitaeten))
                    aktivitaetenSummen.append(contentsOf: getWeekSum(art: "Einnahmen", aktivitaeten: aktivitaeten))
                    aktivitaetenSummen.append(contentsOf: getWeekSum(art: "Ausgaben", aktivitaeten: aktivitaeten))

                    // Entfernen der Aktivitäten, die in der DB gelöscht wurden
                    let currentIDs = Set(decodedResponse.map { $0.id })
                    let deletedAktivitaeten = self.aktivitaeten.filter { !currentIDs.contains($0.id) }
                    for deletedAktivitaet in deletedAktivitaeten {
                        if let index = self.aktivitaeten.firstIndex(where: { $0.id == deletedAktivitaet.id }) {
                            self.aktivitaeten.remove(at: index)
                        }
                    }
                    fetchActivityByCategory()
                }
            } else {
                print("Invalid response from server")
            }
        }.resume()
    }
    
    
    //Bekommt die Einnahmen oder Ausgaben (Entscheidung über art:String) von einem Benutzer (email) zu einer möglichen Kategorie
    // Bekommt die Einnahmen oder Ausgaben (Entscheidung über art:String) von einem Benutzer (email) zu einer möglichen Kategorie
    private func fetchActivityByCategory() {
        let kategorien = ["Drogerie", "Freizeit", "Unterhaltung", "Lebensmittel", "Hobbys", "Wohnen", "Haushalt", "Sonstiges", "Technik", "Finanzen", "Restaurant", "Shopping"]
        var gesamtEinnahmen: Double = 0
        var gesamtAusgaben: Double = 0
        
        let dispatchGroup = DispatchGroup() // Erstelle eine neue DispatchGroup
        
        for kategorie in kategorien {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                let einnahmen = self.aktivitaeten
                    .filter { $0.kategorie == kategorie && $0.art == "Einnahmen" }
                    .reduce(0) { $0 + $1.betrag }
                
                DispatchQueue.main.async {
                    if let existingKategorieIndex = self.kategorieneinnahmen.firstIndex(where: { $0.id == kategorie }) {
                        self.kategorieneinnahmen[existingKategorieIndex].einnahmen = einnahmen
                    } else {
                        self.kategorieneinnahmen.append(Kategorie(id: kategorie, einnahmen: einnahmen))
                    }
                    gesamtEinnahmen += einnahmen
                }
                
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            DispatchQueue.global().async {
                let ausgaben = self.aktivitaeten
                    .filter { $0.kategorie == kategorie && $0.art == "Ausgaben" }
                    .reduce(0) { $0 + $1.betrag }
                
                DispatchQueue.main.async {
                    if let existingKategorieIndex = self.kategorienausgaben.firstIndex(where: { $0.id == kategorie }) {
                        self.kategorienausgaben[existingKategorieIndex].einnahmen = ausgaben
                    } else {
                        self.kategorienausgaben.append(Kategorie(id: kategorie, einnahmen: ausgaben))
                    }
                    gesamtAusgaben += ausgaben
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let existingGesamtEinnahmenIndex = self.kategorieneinnahmen.firstIndex(where: { $0.id == "Gesamt" }) {
                self.kategorieneinnahmen[existingGesamtEinnahmenIndex].einnahmen = gesamtEinnahmen
            } else {
                self.kategorieneinnahmen.append(Kategorie(id: "Gesamt", einnahmen: gesamtEinnahmen))
            }
            
            if let existingGesamtAusgabenIndex = self.kategorienausgaben.firstIndex(where: { $0.id == "Gesamt" }) {
                self.kategorienausgaben[existingGesamtAusgabenIndex].einnahmen = gesamtAusgaben
            } else {
                self.kategorienausgaben.append(Kategorie(id: "Gesamt", einnahmen: gesamtAusgaben))
            }
        }
    }

    
    // Bekommt alle Limits aus dem Backend für den jeweiligen Benutzer (-email)
    private func fetchLimits() {
        guard let url = URL(string: "http://localhost:8080/api/v1/limit/\(email)?username=admin&password=password") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let decodedResponse = try? JSONDecoder().decode([Limit].self, from: data) {
                DispatchQueue.main.async { [self] in
                    // Überprüfe vorhandene Limits
                    for decodedLimit in decodedResponse {
                        if let existingLimitIndex = self.limits.firstIndex(where: { $0.id == decodedLimit.id }) {
                            // Aktualisiere vorhandenes Limit
                            self.limits[existingLimitIndex] = decodedLimit
                        } else {
                            // Füge neues Limit hinzu
                            self.limits.append(decodedLimit)
                        }
                    }
                    
                    // Entferne gelöschte Limits
                    let existingLimitIds = self.limits.map { $0.id }
                    let decodedLimitIds = decodedResponse.map { $0.id }
                    let deletedLimitIds = existingLimitIds.filter { !decodedLimitIds.contains($0) }
                    self.limits.removeAll { deletedLimitIds.contains($0.id) }
                    
                    createLimitAnalysen()
                }
            } else {
                print("Failed to decode response data")
            }
        }.resume()
    }
    
    // Erstellt Limit-Analysen basierend auf den Limits und Aktivitäten
    private func createLimitAnalysen() {
        let kategorien = Set(limits.map { $0.kategorie })
        
        var limitAnalysen = [LimitAnalyse]()
        for kategorie in kategorien {
            let betragSumme = getAktivitaetenSummeInKategorie(kategorie: kategorie)
            let limitBetrag = limits.filter { $0.kategorie == kategorie }.first?.betrag ?? 0
            limitAnalysen.append(LimitAnalyse(kategorie: kategorie, zielbetrag: limitBetrag, aktuell: betragSumme))
        }
        self.limitAnalysen = limitAnalysen
        print(limitAnalysen)
    }
    
    //Bekommt die Targets aus dem Backend
    func fetchTargets() {
        guard let url = URL(string: "http://localhost:8080/api/v1/targets/\(email)?username=admin&password=password") else {
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
    
    // Summiert die Summe in der jeweiligen Kategorie auf
    private func getAktivitaetenSummeInKategorie(kategorie: String) -> Double {
        let aktivitaetenInKategorie = aktivitaeten.filter { $0.kategorie == kategorie && $0.art == "Ausgaben"}
        let betragSumme = aktivitaetenInKategorie.reduce(0) { $0 + $1.betrag }
        return betragSumme
    }
    
    // Die categoryIcon Methode, um das Symbol für eine Kategorie zurückzugeben
    func categoryIcon(for category: String) -> String {
        switch category {
        case "Drogerie":
            return "cart"
        case "Freizeit":
            return "film"
        case "Unterhaltung":
            return "music.note"
        case "Lebensmittel":
            return "cart.fill"
        case "Hobbys":
            return "paintbrush"
        case "Wohnen":
            return "house"
        case "Haushalt":
            return "house.fill"
        case "Sonstiges":
            return "ellipsis.circle"
        case "Technik":
            return "desktopcomputer"
        case "Finanzen":
            return "dollarsign.circle"
        case "Restaurant":
            return "fork.knife"
        case "Shopping":
            return "bag"
        default:
            return "circle"
        }
    }

    
    func summeGesamtNachArt(art: String) -> Double {
        let summeEinnahmen = aktivitaeten.reduce(0) { result, aktivitaet in
            return aktivitaet.art == art ? result + aktivitaet.betrag : result
        }
        return summeEinnahmen
    }
    
    func getComparisonText( value: Double, isIncome: Bool) -> some View {
        let formattedValue = String(format: "%.2f", value)
        
        return HStack{
            if(isIncome){
                if(value>=(-100)){
                    Text("Einnahmen: \(formattedValue)%")
                    .foregroundColor(.green)
                    Spacer()
                    getArrowView(for: value,art: "Einnahmen")
                }else{
                    HStack{
                        Text("Einnahmen:")
                            .foregroundColor(.green)
                        Text("keine Vergleichsdaten")
                    }
                    Spacer()
                }
            }else{
                if(value>=(-100)){
                    Text("Ausgaben: \(formattedValue)%")
                        .foregroundColor(.red)
                    Spacer()
                    getArrowView(for: value,art: "Ausgaben")
                }else{
                    HStack{
                        Text("Ausgaben:")
                            .foregroundColor(.red)
                        Text("keine Vergleichsdaten")
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    func getArrowView(for value: Double, art: String) -> some View {
        if value > 120 {
            return AnyView(Image(systemName: "arrow.up.right")
                .foregroundColor(art == "Einnahmen" ? .green : .red))
        } else if (value >= 80 && value <= 120) {
            return AnyView(Image(systemName: "arrow.right")
                .foregroundColor(colorScheme == .dark ? .white : .black))
        } else {
            return AnyView(Image(systemName: "arrow.down.right")
                .foregroundColor(art == "Ausgaben" ? .green : .red))
        }
    }

    
    func getYearSum(art: String, aktivitaeten: [Aktivitaet]) -> [Double] {
        let analyseView = AnalyseView(email: email,aktivitaeten: aktivitaeten)
        let last12activityMonths = analyseView.getXActivityMonths(art: art, aktivitaeten: aktivitaeten, anzahl: 12)
        let last12 = last12activityMonths.reduce(0) { result, activity in
            return result + activity.amount
        }
        let last24activityMonths = analyseView.getXActivityMonths(art: art, aktivitaeten: aktivitaeten, anzahl: 24)
        let last24 = last24activityMonths.reduce(0) { result, activity in
            return result + activity.amount
        }
        
        let diff: Double
        if ((last24 - last12) != 0 ){
            diff = last12 / (last24 - last12)
        } else {
            diff = -2 // -200% ist ja nicht erreichbar
        }
        
        return [last12,(last24-last12),diff]
    }
    func getMonthSum(art: String, aktivitaeten: [Aktivitaet]) -> [Double] {
        let analyseView = AnalyseView(email: email,aktivitaeten: aktivitaeten)
        let lastactivityMonths = analyseView.getXActivityMonths(art: art, aktivitaeten: aktivitaeten, anzahl: 1)
        let last = lastactivityMonths.reduce(0) { result, activity in
            return result + activity.amount
        }
        let lastactivityMonths_2nd = analyseView.getXActivityMonths(art: art, aktivitaeten: aktivitaeten, anzahl: 2)
        let last2 = lastactivityMonths_2nd.reduce(0) { result, activity in
            return result + activity.amount
        }
        let diff: Double
        if ((last2 - last) != 0 ){
            diff = last / (last2 - last)
        } else {
            diff = -2 // -200% ist ja nicht erreichbar
        }
        return [last,(last2-last),diff]
    }
    func getWeekSum(art: String, aktivitaeten: [Aktivitaet]) -> [Double] {
        let analyseView = AnalyseView(email: email,aktivitaeten: aktivitaeten)
        let activitieslast7 = analyseView.getActivityLastXDays(art: art, aktivitaeten: aktivitaeten, anzahl: 7)
        let last7 = activitieslast7.reduce(0) { result, activity in
            return result + activity.amount
        }
        let activitieslast14 = analyseView.getActivityLastXDays(art: art, aktivitaeten: aktivitaeten, anzahl: 14)
        let last14 = activitieslast14.reduce(0) { result, activity in
            return result + activity.amount
        }
        let diff: Double
        if ((last14 - last7) != 0 ){
            diff = last7 / (last14 - last7)
        } else {
            diff = -2 // -200% ist ja nicht erreichbar
        }
        return [last7,(last14-last7),diff]
    }
}

