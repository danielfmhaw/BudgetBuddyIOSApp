//
//  Buddy.swift
//  BudgetBuddy
//
//  Created by Daniel Mendes on 09.05.23.
//

import SwiftUI
import Charts

struct Buddy: View {
    let email: String
    @State var limits: [Limit] = []
    @State var activities: [Aktivitaet] = []
    @State var limitAnalysen: [LimitAnalyse] = []

    @State private var chatText: String = ""
    @State private var messagesBenutzer: [String] = []
    @State private var messagesComp: [String] = []
    
    
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
                                        Text(messageComp)
                                            .foregroundColor(.black)
                                            .padding(.all, 10)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(15)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 50)
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
        .onAppear {
            fetchLimits()
            fetchActivities()
        }
    }
    
    
    func sendMessage(_ message: String) {
        messagesBenutzer.append(message)
        if message.lowercased() == "hallo" || message.lowercased() == "hi" {
            messagesComp.append("Was kann ich für dich tun?")
        }else if message.lowercased() == "danke" || message.lowercased() == "thx" {
            messagesComp.append("Kein Problem ;)")
        } else if message.lowercased().contains("lim"){
            let limitMessages = getLimitInformation()
            var alles:String = ""
            for (index, limitMessage) in limitMessages.enumerated() {
                alles += limitMessage
                if index < limitMessages.count - 1 {
                    alles += "\r\n"
                }
            }
            messagesComp.append(alles)
        } else {
            messagesComp.append("Entschuldigung, ich verstehe nicht, was du meinst.")
        }
    }

    
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
    
    private func createLimitAnalysen() {
        let kategorien = Set(limits.map { $0.kategorie }) // Alle einzigartigen Kategorien
        
        var limitAnalysen = [LimitAnalyse]()
        for kategorie in kategorien {
            let betragSumme = getAktivitaetenSummeInKategorie(kategorie: kategorie)
            let limitBetrag = limits.filter { $0.kategorie == kategorie }.first?.betrag ?? 0
            limitAnalysen.append(LimitAnalyse(kategorie: kategorie, zielbetrag: limitBetrag, aktuell: betragSumme))
        }
        self.limitAnalysen = limitAnalysen
        print(limitAnalysen)
    }
    
    private func getAktivitaetenSummeInKategorie(kategorie: String) -> Double {
        let aktivitaetenInKategorie = activities.filter { $0.kategorie == kategorie }
        let betragSumme = aktivitaetenInKategorie.reduce(0) { $0 + $1.betrag }
        return betragSumme
    }


    
    private func fetchLimits() {
        guard let url = URL(string: "http://localhost:8080/api/v1/limit/\(email)") else {
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
    
    
    private func fetchActivities() {
        guard let url = URL(string: "http://localhost:8080/api/v1/aktivitaet/withArt/\(email)/Ausgaben") else {
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
