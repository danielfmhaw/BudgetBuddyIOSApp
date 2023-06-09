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
        let limitAnalysen: [LimitAnalyse]
        let limits: [Limit]
    
       @State var showList: Bool = true
       @State private  var currentActiveItem: Item?
    
       @Environment(\.colorScheme) var colorScheme

       var body: some View {
           NavigationView {
               VStack {
                   Text("Budget-Vergleich")
                       .font(.title)
                       .fontWeight(.bold)
                       .padding(.top, 20)

                   Picker(selection: $showList, label: Text("Select View")) {
                       Text("Diagramm").tag(true)
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
                       GeometryReader { geometry in
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
                                           .foregroundStyle(colorScheme == .light ? Color.black : Color.white)
                                           .lineStyle(.init(lineWidth: 3, miterLimit: 3, dash:[7],dashPhase:5))
                                           .annotation() {
                                               VStack() {
                                                   Text("\(currentActiveItem.type)")
                                                       .font(.caption)
                                                       .foregroundColor(.gray)
                                                   
                                                   Text("Überschuss: \(String(format: "%.1f", currentActiveItem.value))")
                                                       .font(.system(size: 14, weight: .bold))
                                               }
                                               .padding(.horizontal, 10)
                                               .padding(.vertical, 4)
                                               .background(
                                                   RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                       .fill(colorScheme == .light ? Color.white : Color.black)
                                                       .shadow(color: colorScheme == .light ? Color.black.opacity(0.2) : Color.clear, radius: 2)
                                               )
                                               .overlay(
                                                   RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                       .stroke(colorScheme == .light ? Color.black : Color.white, lineWidth: 1)
                                               )
                                               .offset(y:200)
                                           }
                                   }
                               }
                               .chartPlotStyle { plotContent in
                                   plotContent
                                       .background(.gray.opacity(0.2))
                                       .border(Color.gray.opacity(0.6), width: 0.5)
                               }
                               //                           .chartXAxis {
                               //                               AxisMarks(values: .automatic) { _ in
                               //                                   AxisValueLabel()
                               //                                       .foregroundStyle(colorScheme == .light ? Color.black : Color.white)
                               //                               }
                               //                           }
                               //                           .chartYAxis {
                               //                               AxisMarks(values: .automatic) { _ in
                               //                                   AxisValueLabel()
                               //                                       .foregroundStyle(colorScheme == .light ? Color.black : Color.white)
                               //                               }
                               //                           }
                               .padding(.horizontal, 20)
                               .padding(.vertical, 10)
                               .frame(height: geometry.size.height)
                               
                           }
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
           }
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
}
