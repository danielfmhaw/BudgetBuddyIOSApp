// Screen, indem mit dem Buddy interagiert werden kann
//
// Created by Daniel Mendes on 09.05.23.

import SwiftUI
import Foundation
import Charts

struct Buddy: View {
    let email: String
    let limits: [Limit]
    let activities: [Aktivitaet]
    @State var limitAnalysen: [LimitAnalyse] = []

    @State private var chatText: String = ""
    @State private var messagesBenutzer: [String] = []
    @State private var messagesComp: [String] = []
    
    @Environment(\.colorScheme) var colorScheme
    
    
    
    var body: some View {
       NavigationView {
           VStack {
               Button(action: {
                   messagesBenutzer = []
                   messagesComp = []
                   chatText = ""
               }) {
                   Label("Chat leeren", systemImage: "trash.fill")
               }
               
               Text("Chat")
                   .font(.title)
                   .fontWeight(.bold)
                   .padding(.top, 20)
               
               
               ScrollView {
                   ScrollViewReader { scrollView in
                       LazyVStack(alignment: .leading, spacing: 10) {
                           ForEach(Array(zip(messagesBenutzer, messagesComp)), id: \.0) { messageBenutzer, messageComp in
                               VStack(alignment: .trailing, spacing: 5) {
                                   if messageBenutzer != "" {
                                       HStack {
                                           Spacer()
                                           Text(messageBenutzer)
                                               .foregroundColor(.white)
                                               .padding(.all, 10)
                                               .background(Color.blue)
                                               .cornerRadius(15)
                                       }
                                   }
                                   if messageComp != "" {
                                       HStack {
                                           if colorScheme == .light {
                                               Text(messageComp)
                                                   .foregroundColor(.black)
                                                   .padding(.all, 10)
                                                   .background(Color.gray.opacity(0.2))
                                                   .cornerRadius(15)
                                               Spacer()
                                           }else{
                                               Text(messageComp)
                                                   .foregroundColor(.white)
                                                   .padding(.all, 10)
                                                   .background(Color.gray.opacity(0.3))
                                                   .cornerRadius(15)
                                               Spacer()
                                           }
                                       }
                                   }
                               }
                               .padding(.horizontal, 50)
                               .id(messageComp)
                           }
                       }
                       // Scrollt immer zu der letzten Nachricht
                       .onChange(of: messagesComp) { _ in
                           withAnimation {
                               scrollView.scrollTo(messagesComp.last, anchor: .bottom)
                           }
                       }
                   }
               }

               HStack {
                   TextField("Schreibe eine Nachricht", text: $chatText)
                       .textFieldStyle(RoundedBorderTextFieldStyle())
                   
                   Button("Senden") {
                       sendMessage(chatText)
                       chatText = ""
                   }
                   .padding(.leading, 10)
               }
               .padding(.horizontal, 20)
               .padding(.bottom, 10)
           }
       }
       .onAppear{
           createLimitAnalysen()
       }
    }
     
    // Messages werden im Chat angezeigt (je nach Benutzereingabe unterschiedliche Antworten)
    func sendMessage(_ message: String) {
        var alles:String = ""
        messagesBenutzer.append(message)
        if message.lowercased() == "hallo" || message.lowercased() == "hi" {
            messagesComp.append("Was kann ich für dich tun?")
        }else if message.lowercased() == "danke" || message.lowercased() == "thx" {
            messagesComp.append("Kein Problem ;)")
        }else if message.lowercased() == "befehle"{
            messagesComp.append("Es gibt folgende Befehle: \r\n1. Limitüberschreitungen mit 'Limit' anzeigen lassen \r\n2. Große Einnahmenquellen anzeigen lassen mit 'Einnahmen' und \r\n3. Alles große Ausgabeposten anzeigen lassen")
        }else if message.lowercased().contains("einna"){
            let einnahmenMessages = getBudgetInformation(art: "Einnahmen")
            for (index, message) in einnahmenMessages.enumerated() {
                alles += "• " + message
                if index < einnahmenMessages.count - 1 {
                    alles += "\r\n"
                }
            }
            messagesComp.append(getMessageFromAPI(kontext: "Das sind meine Einnahmen:"+alles, anfrage:"kannst du mir zu meinen Einnahmen Tipps geben?"))
        }else if message.lowercased().contains("ausg"){
            let ausgabenMessages = getBudgetInformation(art:"Ausgaben")
            for (index, message) in ausgabenMessages.enumerated() {
                alles += "• " + message
                if index < ausgabenMessages.count - 1 {
                    alles += "\r\n"
                }
            }
            messagesComp.append(getMessageFromAPI(kontext: "Das sind meine Ausgaben:"+alles, anfrage:"\n kannst du mir zu meinen Ausgaben Tipps geben?"))
        }else if message.lowercased().contains("limit"){
            let limitMessages = getLimitInformation()
            for (index, limitMessage) in limitMessages.enumerated() {
                alles += limitMessage
                if index < limitMessages.count - 1 {
                    alles += "\r\n"
                }
            }
            messagesComp.append(getMessageFromAPI(kontext: "Das sind meine Limits:"+alles, anfrage:"kannst du mir zu meinen Limits Tipps geben?"))
        } else {
            messagesComp.append(getMessageFromAPI(kontext: "", anfrage:message))
        }
    }
    
    // Gibt Informationen zu den Budgets
    func getBudgetInformation(art:String) -> [String] {
        var messages: [String] = []
        let budgetmessage = berechneNachKategorieUndArt(art: art)
        for budget in budgetmessage  {
            if(budget.anteil>40){
                messages.append("Kategorie \(budget.kategorie) sehr großer Anteil (\(String(format: "%.2f", abs(budget.anteil)))%)")
            }else if(budget.anteil>20){
                messages.append("Kategorie \(budget.kategorie) großer Anteil (\(String(format: "%.2f", abs(budget.anteil)))%)")
            }else if(budget.anteil>10){
                messages.append("Kategorie \(budget.kategorie) wichtig (\(String(format: "%.2f", abs(budget.anteil)))%)")
            }
        }
        if(messages.isEmpty){
            messages.append("Keine Anteil der \(art) über 10%")
        }
        return messages
    }
    
    // Gibt Informationen zu den Limits
    func getLimitInformation() -> [String] {
        var messages: [String] = []
        for limit in limits {
            if let limitAnalyse = limitAnalysen.first(where: { $0.kategorie == limit.kategorie }) {
                if limitAnalyse.ueberschuss < 0 {
                    messages.append("Kategorie \(limit.kategorie) hat mit \(String(format: "%.2f", abs(limitAnalyse.ueberschuss))) \u{20AC} überzogen.")
                }
            }
        }
        return messages
    }
    
    // Gibt prozentualen Anteil von einer Kategorie mit einer Art von dem gesamten Beträgen derjweiligen Art an
    func berechneNachKategorieUndArt(art:String) -> [(kategorie: String, anteil: Double)] {
        var nachKategorie: [(kategorie: String, summe: Double)] = []
        var gesamtsumme: Double = 0
        activities.filter { $0.art == art }.forEach { aktivitaet in
            if let index = nachKategorie.firstIndex(where: { $0.kategorie == aktivitaet.kategorie }) {
                nachKategorie[index].summe += aktivitaet.betrag
                gesamtsumme+=aktivitaet.betrag
            } else {
                nachKategorie.append((kategorie: aktivitaet.kategorie, summe: aktivitaet.betrag))
            }
        }
        var prozentual: [(kategorie: String, anteil: Double)] = []
        nachKategorie.forEach{aktivitaet in
            prozentual.append((kategorie: aktivitaet.kategorie, anteil: (aktivitaet.summe/gesamtsumme)*100))
        }
        return prozentual
    }
    
    // Erstellt Limit-Analysen basierend auf den Limits und Aktivitäten
    private func createLimitAnalysen() {
        let kategorien = Set(limits.map { $0.kategorie })
        
        var limitAnalysen = [LimitAnalyse]()
        for kategorie in kategorien {
            let betragSumme = getAktivitaetenSummeInKategorie(kategorie: kategorie,art: "Ausgaben")
            let limitBetrag = limits.filter { $0.kategorie == kategorie }.first?.betrag ?? 0
            limitAnalysen.append(LimitAnalyse(kategorie: kategorie, zielbetrag: limitBetrag, aktuell: betragSumme))
        }
        self.limitAnalysen = limitAnalysen
        print(limitAnalysen)
    }
    
    // Summiert die Summe in der jeweiligen Kategorie und Art auf
    private func getAktivitaetenSummeInKategorie(kategorie: String,art:String) -> Double {
        let aktivitaetenAusgaben = activities.filter { $0.art == art }
        let aktivitaetenInKategorie = aktivitaetenAusgaben.filter { $0.kategorie == kategorie }
        let betragSumme = aktivitaetenInKategorie.reduce(0) { $0 + $1.betrag }
        return betragSumme
    }

    func getMessageFromAPI(kontext: String, anfrage: String) -> String {
        let urlString = "https://plebgpt.fly.dev/chat/\(kontext)\(anfrage)"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            return "Ungültige URL"
        }
        
        let username = "daniel"
        let password = "dhawbb"
        
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            return "Fehler bei der Erstellung des Login-Datenobjekts"
        }
        let base64LoginString = loginData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        var responseString = "Leere oder ungültige Serverantwort"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                responseString = "Fehler: \(error)"
            }
            
            if let data = data, let string = String(data: data, encoding: .nonLossyASCII) {
                responseString = string
            }
            
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        let charactersToRemove = CharacterSet(charactersIn: "\"\n")
        responseString = responseString.components(separatedBy: charactersToRemove).joined(separator: "")
        
        return responseString
    }

}
