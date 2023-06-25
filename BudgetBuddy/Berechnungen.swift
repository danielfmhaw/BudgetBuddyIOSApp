//
//  Berechnungen.swift
//  BudgetBuddy
//
//  Created by Daniel Mendes on 25.06.23.
//
import SwiftUI

struct Berechnungen{
    // Erstellt Limit-Analysen basierend auf den Limits und Aktivitäten
    public func createLimitAnalysen(aktivitaeten: [Aktivitaet],limits:[Limit]) -> [LimitAnalyse]{
        let kategorien = Set(limits.map { $0.kategorie })
        
        var limitAnalysen = [LimitAnalyse]()
        for kategorie in kategorien {
            let betragSumme = getAktivitaetenSummeInKategorie(kategorie: kategorie,aktivitaeten: aktivitaeten)
            let limitBetrag = limits.filter { $0.kategorie == kategorie }.first?.betrag ?? 0
            limitAnalysen.append(LimitAnalyse(kategorie: kategorie, zielbetrag: limitBetrag, aktuell: betragSumme))
        }
        return limitAnalysen    
    }
    
    // Summiert die Summe in der jeweiligen Kategorie auf
    public func getAktivitaetenSummeInKategorie(kategorie: String,aktivitaeten:[Aktivitaet]) -> Double {
        let aktivitaetenInKategorie = aktivitaeten.filter { $0.kategorie == kategorie && $0.art == "Ausgaben"}
        let betragSumme = aktivitaetenInKategorie.reduce(0) { $0 + $1.betrag }
        return betragSumme
    }
    // Liefert eine Liste von der letzten X Aktivitätsmonaten zurück, basierend auf der Art der Aktivität und einer Liste von Aktivitäten
    public func getXActivityMonths(art: String, aktivitaeten: [Aktivitaet],anzahl:Int) -> [Activity] {
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
    public func getActivityLastXDays(art: String, aktivitaeten: [Aktivitaet],anzahl:Int) -> [Activity] {
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
    
    public func getXAktivitaetenMonths(art: String, aktivitaeten: [Aktivitaet], anzahl: Int) -> [Aktivitaet] {
         let lastXMonths = getXMonths(anzahl: anzahl)
         
         let filteredAktivitaeten = aktivitaeten.filter { aktivitaet in
             lastXMonths.contains(getMonth(from: aktivitaet.datum)) && aktivitaet.art == art
         }
         
         return filteredAktivitaeten
     }
    
    // Liefert eine Liste von Aktivitäten der letzten X Tage, basierend auf der Aktivitätsart und einer Liste von Aktivitäten
        public func getAktivitaetenLastXDays(art: String, aktivitaeten: [Aktivitaet], anzahl: Int) -> [Aktivitaet] {
            var activityDays: [Aktivitaet] = []
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
                if let activities = dayGroups[day] {
                    let filteredAktivitaeten = activities.filter { $0.art == art }
                    activityDays.append(contentsOf: filteredAktivitaeten)
                }
            }

            return activityDays
        }
    
        //Bekommt die Einnahmen oder Ausgaben (Entscheidung über art:String) von einem Benutzer (email) zu einer möglichen Kategorie
        public func fetchActivityByCategory(art: String, aktivitaeten: [Aktivitaet]) -> [Kategorie] {
            let kategorien = ["Drogerie", "Freizeit", "Unterhaltung", "Lebensmittel", "Hobbys", "Wohnen", "Haushalt", "Sonstiges", "Technik", "Finanzen", "Restaurant", "Shopping"]
            
            var kategorieneinnahmen: [Kategorie] = []
            var gesamtEinnahmen: Double = 0
            
            for kategorie in kategorien {
                let einnahmen = aktivitaeten
                    .filter { $0.kategorie == kategorie && $0.art == art }
                    .reduce(0) { $0 + $1.betrag }
                
                kategorieneinnahmen.append(Kategorie(id: kategorie, einnahmen: einnahmen))
                gesamtEinnahmen += einnahmen
            }
            
            kategorieneinnahmen.append(Kategorie(id: "Gesamt", einnahmen: gesamtEinnahmen))
            
            return kategorieneinnahmen
        }
}
