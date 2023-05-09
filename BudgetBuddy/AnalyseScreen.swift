//
//  AnalyseScreen.swift
//  Login2
//
//  Created by Daniel Mendes on 29.04.23.
//

import SwiftUI
import Charts

struct Activity: Identifiable, Codable {
    var id = UUID()
    let date: String
    let amount: Double
}

//Screen, um die Einnahmen bzw. Ausgaben sortiert entweder in Euro oder in % anzeigen zu lassen
struct AnaylseView: View {
    let email: String
    
    let dispatchGroup = DispatchGroup()
    @State private var aktivitaeten: [Aktivitaet] = []
    @State private var einnahmen: [Activity] = []
    @State private var ausgaben: [Activity] = []
    
    @State private var selectedDisplayMode = 0
    @State private var isLineGraph = false
    
    @State var currentActiveItemRevenue: Activity?
    @State var currentActiveItemCost: Activity?
    @State var plodWidth : CGFloat = 0
    
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
                Text("Lade Daten...")
            } else {
                let chartData = getChartData()
                let einnahmen = chartData.0
                let ausgaben = chartData.1
                
                
                VStack {
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
                        if let currentActiveItemRevenue,currentActiveItemRevenue.date == activity.date {
                            RuleMark(x: .value("Date", currentActiveItemRevenue.date))
                                //LineStyle
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
                                            .fill(.white.shadow(.drop(radius:2)))
                                    }
                                }
                        }
                    }
                    .chartOverlay(content: {proxy in
                        GeometryReader{ innerproxy in
                            Rectangle()
                                .fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged{ value in
                                            //Getting current location
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
                        if let currentActiveItemCost,currentActiveItemCost.date == activity.date {
                            RuleMark(x: .value("Date", currentActiveItemCost.date))
                                //LineStyle
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
                                            .fill(.white.shadow(.drop(radius:2)))
                                    }
                                }
                        }
                    }
                    .chartOverlay(content: {proxy in
                        GeometryReader{ innerproxy in
                            Rectangle()
                                .fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged{ value in
                                            //Getting current location
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
        .onAppear {
            getAktivitaeten()
        }
    }
    
    
    func getChartData() -> ([Activity], [Activity]) {
        var einnahmen = [Activity]()
        var ausgaben = [Activity]()

        if selectedDisplayMode == 0 {
            einnahmen = getActivityYears(art: "Einnahmen", aktivitaeten: aktivitaeten)
            ausgaben = getActivityYears(art: "Ausgaben", aktivitaeten: aktivitaeten)
        } else if selectedDisplayMode == 1 {
            einnahmen = getActivityMonths(art: "Einnahmen", aktivitaeten: aktivitaeten)
            ausgaben = getActivityMonths(art: "Ausgaben", aktivitaeten: aktivitaeten)
        }else if selectedDisplayMode==2{
            einnahmen = getActivityLast14Days(art: "Einnahmen", aktivitaeten: aktivitaeten)
            ausgaben = getActivityLast14Days(art: "Ausgaben", aktivitaeten: aktivitaeten)
        }

        return (einnahmen, ausgaben)
    }
    
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


    func getYear(from date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        let date = dateFormatter.date(from: date)!
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return String(year)
    }
    
    func getActivityMonths(art: String, aktivitaeten: [Aktivitaet]) -> [Activity] {
        var activityMonths: [Activity] = []
        
        // Create a dictionary with month strings as keys and arrays of activities as values
        let monthGroups = Dictionary(grouping: aktivitaeten, by: { getMonth(from: $0.datum) })
        
        // Get the last 12 months as an array of month strings
        let lastTwelveMonths = getLastTwelveMonths()
        
        // Iterate over the last 12 months and calculate the sum of activities in each month
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

    // Returns the month string in the format "MMMyy" (e.g. "Apr23") for the given date string
    func getMonth(from date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        let date = dateFormatter.date(from: date)!
        dateFormatter.dateFormat = "MMMyy"
        return dateFormatter.string(from: date)
    }

    // Returns an array of month strings for the last 12 months
    func getLastTwelveMonths() -> [String] {
        var months: [String] = []
        let calendar = Calendar.current
        let currentDate = Date()
        var dateComponents = DateComponents()
        for i in 0..<12 {
            dateComponents.month = -i
            let monthDate = calendar.date(byAdding: dateComponents, to: currentDate)!
            let monthString = getMonthDescription(from: monthDate)
            months.append(monthString)
        }
        return months.reversed()
    }

    // Returns the month string in the format "MMMyy" (e.g. "Apr23") for the given date
    func getMonthDescription(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMyy"
        return dateFormatter.string(from: date)
    }
    
    func getActivityLast14Days(art: String, aktivitaeten: [Aktivitaet]) -> [Activity] {
        var activityDays: [Activity] = []
        let dayGroups = Dictionary(grouping: aktivitaeten, by: { getDay(from: $0.datum) })
        
        let startDate = Calendar.current.date(byAdding: .day, value: -13, to: Date())!
        let endDate = Date()

        var last14Days: [String] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let dayString = getDayDescription(from: currentDate)
            last14Days.append(dayString)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }

        for day in last14Days {
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


    // Returns the day string in the format "dd.MM" (e.g. "29.04") for the given date string
    func getDay(from date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        let date = dateFormatter.date(from: date)!
        dateFormatter.dateFormat = "dd.MM"
        return dateFormatter.string(from: date)
    }

    // Returns the day string in the format "dd.MM" (e.g. "29.04") for the given date
    func getDayDescription(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM"
        return dateFormatter.string(from: date)
    }


    
    //Bekommt die Einnahmen oder Ausgaben (Entscheidung über art:String) von einem Benutzer (email) zu einer möglichen Kategorie
    func getAktivitaeten() {
        guard let url = URL(string: "http://localhost:8080/api/v1/aktivitaet/\(email)") else {
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
