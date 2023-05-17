// Screen, indem die Limits visualisiert werden und verglichen werden mit der Differenz
// von Limit und der Summe aller Beträge von allen Aktivitäten derjeweiligen Kategorie
//
// Created by Daniel Mendes on 30.04.23.

import SwiftUI
import Charts

// Struktur des Limitanalyse, mit ID (für Diagramm)
struct LimitAnalyse: Identifiable {
    let id = UUID()
    let kategorie: String
    var zielbetrag: Double
    var aktuell: Double
    var ueberschuss: Double {
        return zielbetrag-aktuell
    }
}


struct LimitAnalyseView: View {
    let email: String
       @State var limits: [Limit] = []
       @State var activities: [Aktivitaet] = []
       @State var limitAnalysen: [LimitAnalyse] = []
       @State var showList: Bool = true
       @State private  var currentActiveItem: Item?

       var body: some View {
           NavigationView {
               VStack {
                   Text("Analyse View")
                       .font(.title)
                       .fontWeight(.bold)
                       .padding(.top, 20)

                   Picker(selection: $showList, label: Text("Select View")) {
                       Text("Bar Chart").tag(true)
                       Text("Liste").tag(false)
                   }
                   .pickerStyle(SegmentedPickerStyle())
                   .padding()
                   
                   // Anzeige als Liste
                   if !showList {
                       List(limits) { limit in
                           if let limitAnalyse = limitAnalysen.first(where: { $0.kategorie == limit.kategorie }) {
                               VStack(alignment: .leading) {
                                   Text(limit.kategorie)
                                       .font(.headline)
                                   Text("Limit: \(String(format: "%.2f", limit.betrag))")
                                   Text("Aktuell: \(String(format: "%.2f", limitAnalyse.aktuell))")
                                   Text("Saldo: \(String(format: "%.2f", limitAnalyse.ueberschuss))")
                                       .foregroundColor(limitAnalyse.ueberschuss >= 0 ? .green : .red)
                               }
                           }
                       }
                    // Anzeige als Balkendiagramm (BarMark)
                   } else {
                       ScrollView {
                           Chart(items) { item in
                               BarMark(
                                   x: .value("Department", item.type),
                                   y: .value("Profit", item.value)
                               )
                               .foregroundStyle(
                                    item.value >= 0 ? Color.green.gradient : Color.red.gradient
                               )
                               // Zeigt Daten des geraden ausgwählten Balken an
                               if let currentActiveItem,currentActiveItem.type == item.type {
                                   RuleMark(x: .value("Type", currentActiveItem.type))
                                       .lineStyle(.init(lineWidth: 3, miterLimit: 3, dash:[7],dashPhase:5))
                                       .annotation(position: .bottom){
                                           VStack(){
                                               Text("\(currentActiveItem.type)")
                                                   .font(.caption)
                                                   .foregroundColor(.gray)
                                               
                                               Text("Überschuss: \(String(format: "%.1f", currentActiveItem.value))")
                                                   .font(.system(size: 14, weight: .bold))
                                           }
                                           .padding(.horizontal,10)
                                           .padding(.vertical,4)
                                           .background{
                                               RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                   .fill(.white.shadow(.drop(radius:2)))
                                           }
                                       }
                               }
                           }
                           .padding(.horizontal, 20)
                           .padding(.vertical, 10)
                           .frame(height: 400)
                           
                       }
                       // Speichert die Daten des gerade ausgwählten Diagramms
                       .chartOverlay(content: {proxy in
                           GeometryReader{ innerproxy in
                               Rectangle()
                                   .fill(.clear).contentShape(Rectangle())
                                   .gesture(
                                       DragGesture()
                                           .onChanged{ value in
                                               let location = value.location
                                               
                                               if let type:String = proxy.value(atX:location.x){
                                                   if let currentitem = items.first(where: {item in
                                                       type == item.type
                                                   }){
                                                       self.currentActiveItem = currentitem
                                                   }
                                               }
                                           }.onEnded{ value in
                                               self.currentActiveItem = nil
                                           }
                                   )
                               
                           }
                       })
                   }
               }
               .onAppear {
                   fetchLimits()
                   fetchActivities()
               }
           }
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
    
    // Erstellt eine Liste von Items basierend auf den Limits und Limit-Analysen
    private var items: [Item] {
       var items = [Item]()
       for limit in limits {
           if let limitAnalyse = limitAnalysen.first(where: { $0.kategorie == limit.kategorie }) {
               items.append(Item(type: limit.kategorie, value: limitAnalyse.ueberschuss))
           }
       }
       return items
    }
    
    // Ein einzelnes Item-Objekt, das den Typ und den Wert repräsentiert
    private struct Item: Identifiable {
       let id = UUID()
       let type: String
       let value: Double
    }
    
    // Summiert die Summe in der jeweiligen Kategorie auf
    private func getAktivitaetenSummeInKategorie(kategorie: String) -> Double {
        let aktivitaetenInKategorie = activities.filter { $0.kategorie == kategorie }
        let betragSumme = aktivitaetenInKategorie.reduce(0) { $0 + $1.betrag }
        return betragSumme
    }

    // Bekommt alle Limits aus dem Backend für den jeweiligen Benutzer (-email)
    private func fetchLimits() {
        guard let url = URL(string: "http://localhost:8080/api/v1/limit/\(email)?username=admin&password=password") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode([Limit].self, from: data) {
                    DispatchQueue.main.async {
                        limits = decodedResponse
                        createLimitAnalysen()
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
    
    // Bekommt alle Aktivtitäten aus dem Backend mit Art "Ausgaben"
    private func fetchActivities() {
        guard let url = URL(string: "http://localhost:8080/api/v1/aktivitaet/withArt/\(email)/Ausgaben?username=admin&password=password") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode([Aktivitaet].self, from: data) {
                    DispatchQueue.main.async {
                        activities = decodedResponse
                        createLimitAnalysen()
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
}
