// Screen, um die Benutzerdaten anzuzeigen
//
// Created by Daniel Mendes on 29.04.23.

import SwiftUI
import Charts

struct Activity: Identifiable, Codable {
    var id = UUID()
    let date: String
    let amount: Double
}

// Hier werden die verschiedenen Graphen (BarChart oder LineChart) für unterschiedliche Zeiträume angezeigt
struct AnalyseView: View {
    let email: String
    let aktivitaeten: [Aktivitaet]
    
    let dispatchGroup = DispatchGroup()
    @State private var einnahmen: [Activity] = []
    @State private var ausgaben: [Activity] = []
    
    @State private var selectedDisplayMode = 0
    @State private var isLineGraph = false
    
    @State var currentActiveItemRevenue: Activity?
    @State var currentActiveItemCost: Activity?
    @State var plodWidth : CGFloat = 0
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Text("Zeitverlauf")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Picker("Anzeigen als", selection: $selectedDisplayMode) {
                Text("Letzte 10 Jahre").tag(0)
                Text("Letzte 12 Monate").tag(1)
                Text("Letzte 14 Tage").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            
            if aktivitaeten.isEmpty {
                //Text("Lade Daten...")
                let chartData = getChartData()
                let einnahmen = chartData.0
                let ausgaben = chartData.1
                
                VStack{
                    Text("Einnahmen")
                        .font(.system(size: 18, weight: .bold))
                    
                    Chart(einnahmen) { activity in
                        if isLineGraph {
                            LineMark(
                                x: .value("Jahr", activity.date),
                                y: .value("Summe", activity.amount)
                            )
                            .foregroundStyle(Color.green.gradient)
                        } else {
                            BarMark(
                                x: .value("Jahr", activity.date),
                                y: .value("Summe", activity.amount)
                            )
                            .foregroundStyle(Color.green.gradient)
                        }
                    }
                    Text("Ausgaben")
                        .font(.system(size: 18, weight: .bold))
                    
                    Chart(ausgaben) { activity in
                        if !isLineGraph {
                            BarMark(
                                x: .value("Jahr", activity.date),
                                y: .value("Summe", activity.amount)
                            )
                            .foregroundStyle(Color.red.gradient)
                        } else {
                            LineMark(
                                x: .value("Jahr", activity.date),
                                y: .value("Summe", activity.amount)
                            )
                            .foregroundStyle(Color.red.gradient)
                        }
                    }
                    Toggle("Liniendiagramm",isOn: $isLineGraph)
                        .padding()

                }
            } else {
                let chartData = getChartData()
                let einnahmen = chartData.0
                let ausgaben = chartData.1
                
                
                VStack {
                    // Ab hier werden die Einnahmen angezeigt
                    Text("Einnahmen")
                        .font(.system(size: 18, weight: .bold))
                    
                    Chart(einnahmen) { activity in
                        if isLineGraph {
                            LineMark(
                                x: .value("Jahr", activity.date),
                                y: .value("Summe", activity.amount)
                            )
                            .foregroundStyle(Color.green.gradient)
                        } else {
                            BarMark(
                                x: .value("Jahr", activity.date),
                                y: .value("Summe", activity.amount)
                            )
                            .foregroundStyle(Color.green.gradient)
                        }
                        // Hier werden die ausgwählten Werte angezeigt (für d. Einnahmen)
                        if let currentActiveItemRevenue,currentActiveItemRevenue.date == activity.date {
                            RuleMark(x: .value("Date", currentActiveItemRevenue.date))
                                .lineStyle(.init(lineWidth: 3, miterLimit: 3, dash:[7],dashPhase:5))
                                .annotation(position: .top){
                                    VStack(){
                                        Text("\(currentActiveItemRevenue.date)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Text("Einnahmen: \(String(format: "%.1f", currentActiveItemRevenue.amount))")
                                        .font(.system(size: 14, weight: .bold))
                                    }
                                    .padding(.horizontal,10)
                                    .padding(.vertical,4)
                                    .background{
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(colorScheme == .light ? Color.white : Color.black)
                                            .shadow(color: colorScheme == .light ? Color.black.opacity(0.2) : Color.clear, radius: 2)
                                    }
                                    //Rahmen
                                    .overlay(
                                        Group {
                                            if colorScheme == .dark {
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .stroke(Color.white, lineWidth: 1)
                                            }
                                        }
                                    )
                                }
                        }
                    }
                    // Dient dazu das einzelne Werte ausgewählt werden können (für d. Einnahmen)
                    .chartOverlay(content: {proxy in
                        GeometryReader{ innerproxy in
                            Rectangle()
                                .fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged{ value in
                                            let location = value.location
                                            if let type:String = proxy.value(atX:location.x){
                                                if let currentitem = einnahmen.first(where: {item in
                                                    type == item.date
                                                }){
                                                    self.currentActiveItemRevenue = currentitem
                                                    self.plodWidth = proxy.plotAreaSize.width
                                                }
                                            }
                                        }.onEnded{ value in
                                            self.currentActiveItemRevenue = nil
                                        }
                                )
                            
                        }
                    })
                    .frame(height: 150)
                    .padding()
                    
                    // Ab hier werden die Ausgaben angezeigt
                    Text("Ausgaben")
                        .font(.system(size: 18, weight: .bold))
                    
                    Chart(ausgaben) { activity in
                        if !isLineGraph {
                            BarMark(
                                x: .value("Jahr", activity.date),
                                y: .value("Summe", activity.amount)
                            )
                            .foregroundStyle(Color.red.gradient)
                        } else {
                            LineMark(
                                x: .value("Jahr", activity.date),
                                y: .value("Summe", activity.amount)
                            )
                            .foregroundStyle(Color.red.gradient)
                        }
                        // Hier werden die ausgwählten Werte angezeigt (für d. Ausgaben)
                        if let currentActiveItemCost,currentActiveItemCost.date == activity.date {
                            RuleMark(x: .value("Date", currentActiveItemCost.date))
                                .lineStyle(.init(lineWidth: 3, miterLimit: 3, dash:[7],dashPhase:5))
                                .annotation(position: .top){
                                    VStack(){
                                        Text("\(currentActiveItemCost.date)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Text("Ausgaben: \(String(format: "%.1f", currentActiveItemCost.amount))")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    .padding(.horizontal,10)
                                    .padding(.vertical,4)
                                    .background{
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(colorScheme == .light ? Color.white : Color.black)
                                            .shadow(color: colorScheme == .light ? Color.black.opacity(0.2) : Color.clear, radius: 2)
                                    }
                                    //Rahmen
                                    .overlay(
                                        Group {
                                            if colorScheme == .dark {
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .stroke(Color.white, lineWidth: 1)
                                            }
                                        }
                                    )
                                }
                        }
                    }
                    // Dient dazu das einzelne Werte ausgewählt werden können (für d. Ausgaben)
                    .chartOverlay(content: {proxy in
                        GeometryReader{ innerproxy in
                            Rectangle()
                                .fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged{ value in
                                            let location = value.location
                                            if let type:String = proxy.value(atX:location.x){
                                                if let currentitem = ausgaben.first(where: {item in
                                                    type == item.date
                                                }){
                                                    self.currentActiveItemCost = currentitem
                                                    self.plodWidth = proxy.plotAreaSize.width
                                                }
                                            }
                                        }.onEnded{ value in
                                            self.currentActiveItemCost = nil
                                        }
                                )
                            
                        }
                    })
                    .frame(height: 150)
                    .padding()
                    
                    Toggle("Liniendiagramm",isOn: $isLineGraph)
                        .padding()
                }
            }
        }
    }
    
    // Hier werden im Abhängigkeit von dem ausgwählten Zeitraum die Diagramme unterschiedlich "beladen"
    func getChartData() -> ([Activity], [Activity]) {
        var einnahmen = [Activity]()
        var ausgaben = [Activity]()

        if selectedDisplayMode == 0 {
            einnahmen = getActivityYears(art: "Einnahmen", aktivitaeten: aktivitaeten)
            ausgaben = getActivityYears(art: "Ausgaben", aktivitaeten: aktivitaeten)
        } else if selectedDisplayMode == 1 {
            einnahmen = getXActivityMonths(art: "Einnahmen", aktivitaeten: aktivitaeten,anzahl: 12)
            ausgaben = getXActivityMonths(art: "Ausgaben", aktivitaeten: aktivitaeten,anzahl: 12)
        }else if selectedDisplayMode==2{
            einnahmen = getActivityLastXDays(art: "Einnahmen", aktivitaeten: aktivitaeten, anzahl: 14)
            ausgaben = getActivityLastXDays(art: "Ausgaben", aktivitaeten: aktivitaeten, anzahl: 14)
        }

        return (einnahmen, ausgaben)
    }
    
    // Liefert eine Liste von der letzetn 10 Aktivitätsjahren zurück, basierend auf der Art der Aktivität und einer Liste von Aktivitäten
    func getActivityYears(art:String,aktivitaeten: [Aktivitaet]) -> [Activity] {
        var activityYears: [Activity] = []
        let yearGroups = Dictionary(grouping: aktivitaeten, by: { getYear(from: $0.datum) })
        let lastTenYears = (Calendar.current.component(.year, from: Date()) - 9)...Calendar.current.component(.year, from: Date())
        
        for year in lastTenYears {
            let sum = yearGroups[year.description]?.reduce(0) { (result, activity) in
                if activity.art == art {
                    return result + activity.betrag
                } else {
                    return result
                }
            } ?? 0
            let activityYear = Activity(date: "\(year)", amount: sum)
            activityYears.append(activityYear)
        }
        return activityYears
    }

    // Liefert eine Liste von der letzten X Aktivitätsmonaten zurück, basierend auf der Art der Aktivität und einer Liste von Aktivitäten
    func getXActivityMonths(art: String, aktivitaeten: [Aktivitaet],anzahl:Int) -> [Activity] {
        var activityMonths: [Activity] = []
        let monthGroups = Dictionary(grouping: aktivitaeten, by: { getMonth(from: $0.datum) })
        let lastTwelveMonths = getXMonths(anzahl: anzahl)
        
        for month in lastTwelveMonths {
            let monthString = month.prefix(3) + String(month.suffix(2))
            let sum = monthGroups[month]?.reduce(0) { (result, activity) in
                if activity.art == art {
                    return result + activity.betrag
                } else {
                    return result
                }
            } ?? 0
            let activityMonth = Activity(date: String(monthString), amount: sum)
            activityMonths.append(activityMonth)
        }
        
        return activityMonths
    }
    
    // Liefert eine Liste von 14 Aktivitätstagen zurück, basierend auf der Art der Aktivität und einer Liste von Aktivitäten
    func getActivityLastXDays(art: String, aktivitaeten: [Aktivitaet],anzahl:Int) -> [Activity] {
        var activityDays: [Activity] = []
        let dayGroups = Dictionary(grouping: aktivitaeten, by: { getDay(from: $0.datum) })
        
        let startDate = Calendar.current.date(byAdding: .day, value: -(anzahl+1), to: Date())!
        let endDate = Date()

        var lastXDays: [String] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let dayString = getDayDescription(from: currentDate)
            lastXDays.append(dayString)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }

        for day in lastXDays {
            let sum = dayGroups[day]?.reduce(0) { (result, activity) in
                if activity.art == art {
                    return result + activity.betrag
                } else {
                    return result
                }
            } ?? 0
            let activityDay = Activity(date: day, amount: sum)
            activityDays.append(activityDay)
        }

        return activityDays
    }


    // Gibt ein Array von Monatsstrings für die letzten X Monate zurück.
    func getXMonths(anzahl:Int) -> [String] {
        var months: [String] = []
        let calendar = Calendar.current
        let currentDate = Date()
        var dateComponents = DateComponents()
        for i in 0..<anzahl {
            dateComponents.month = -i
            let monthDate = calendar.date(byAdding: dateComponents, to: currentDate)!
            let monthString = getMonthDescription(from: monthDate)
            months.append(monthString)
        }
        return months.reversed()
    }
    
    // Gibt das Jahr im Format "yyyy" (z.B. "2023") für den angegebenen Datumsstring zurück.
    func getYear(from date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        let date = dateFormatter.date(from: date)!
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return String(year)
    }

    // Gibt den Monatsstring im Format "MMMyy" (z.B. "Apr23") für den angegebenen Datumsstring zurück.
    func getMonth(from date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        let date = dateFormatter.date(from: date)!
        dateFormatter.dateFormat = "MMMyy"
        return dateFormatter.string(from: date)
    }
    
    // Gibt den Monatsstring im Format "MMMyy" (z.B. "Apr23") für das angegebene Datum zurück.
    func getMonthDescription(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMyy"
        return dateFormatter.string(from: date)
    }
    
    // Gibt das Tagesdatum im Format "dd.MM" (z.B. "29.04") für den angegebenen Datumsstring zurück.
    func getDay(from date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        let date = dateFormatter.date(from: date)!
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return "\(dateFormatter.string(from: date))"
    }

    // Gibt das Tagesdatum im Format "dd.MM" (z.B. "29.04") für das angegebene Datum zurück
    func getDayDescription(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return "\(dateFormatter.string(from: date))"
    }
}
