import SwiftUI

struct PieSlice: Identifiable {
    var id = UUID()
    var startAngle: Double
    var endAngle: Double
    var color: Color
    var category: String
    var amount: Double
}

struct Kreisdiagramm: View {
    @State private var kategorien: [Kategorie] = []
    let art: String
    let email:String
    let dispatchGroup = DispatchGroup()
    
    private var kategorienListe: [String] {
           createPieChart().0
    }
    private var einnahmenListe: [Double] {
           createPieChart().1
    }
    
    // Farben der "Stücke"
    let farbenListe: [Color] = [.red, .green, .blue, .orange, .yellow, .pink, .purple, Color.pink.opacity(0.8) , .teal, .indigo, .mint, .cyan]

    @State private var showEinnahmenView = false
    
    //Ausgewähltes "Stück" (durch Klicken)
    @State private var selectedSlice: PieSlice?
    
    @Environment(\.colorScheme) var colorScheme
    
    var kategorieOhneGesamt: [Kategorie] {
        return kategorien.filter { $0.id != "Gesamt" }
    }
    
    // Alle "Stücke"
    var slices: [PieSlice] {
        var slices = [PieSlice]()
        var startDegree: Double = 0
        let sum = einnahmenListe.reduce(0, +)
        for i in 0..<einnahmenListe.count {
            let endDegree = startDegree + (einnahmenListe[i] / sum) * 360.0
            slices.append(PieSlice(startAngle: startDegree, endAngle: endDegree, color: farbenListe[i], category: kategorienListe[i], amount: einnahmenListe[i]))
            startDegree = endDegree
        }
        return slices
    }
    
    var sortedData: [(category: String, amount: Double, color: Color)] {
        let zippedData = zip(zip(kategorienListe, einnahmenListe), farbenListe)
        let data = zippedData.sorted { $0.0.1 > $1.0.1 }
        return data.map { ($0.0.0, $0.0.1, $0.1) }
    }

    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    Text("Kreisdiagramm")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    Text(art)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 30)
                    
                    // Insgesamten Beträge dieser Art werden aufsummiert
                    Text("Gesamt: \(String(format: "%.2f", abs(calculateTotalEinnahmen()))) €")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(art == "Einnahmen" ? .green : .red)
                    
                    // Mit diesem Button kann man die Infos als Liste anzeigen lassen
                    Button(action: {
                        showEinnahmenView = true
                    }) {
                        Text("\(art) anzeigen")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.blue)
                            .cornerRadius(5)
                    }
                    .sheet(isPresented: $showEinnahmenView) {
                        EinnahmenView(kategorien: kategorien, email: email, art: art)
                    }.padding(.bottom, 90)

                }
                
                ZStack {
                    // "Stücke" im Kreisdiagramm werden angezeigt
                    ForEach(slices) { slice in
                        Path { path in
                            let width = UIScreen.main.bounds.width - 20
                            let height = UIScreen.main.bounds.height
                            let center = CGPoint(x: width / 2 + 10, y: height / 6)
                            path.move(to: center)
                            path.addArc(center: center, radius: min(width, height) / 2, startAngle: Angle(degrees: slice.startAngle), endAngle: Angle(degrees: slice.endAngle), clockwise: false)
                        }
                        .fill(slice.color)
                        .onTapGesture {
                            selectedSlice = slice
                        }
                    }
                    
                    // Zeigt Informationen für das aktuelle ausgwählte "Stück" an
                    if let slice = selectedSlice {
                        let sliceDegree = slice.endAngle - slice.startAngle
                        let sliceMidDegree = slice.startAngle + (sliceDegree / 2)
                        let sliceMidRadians = sliceMidDegree * .pi / 180.0
                        let sliceX = cos(sliceMidRadians) * 150
                        let sliceY = sin(sliceMidRadians) * 150
                        
                        VStack {
                            Text(slice.category)
                                .font(.title)
                            Text("$\(slice.amount, specifier: "%.2f")")
                                .font(.headline)
                        }
                        .padding()
                        .background(colorScheme == .light ? Color.white : Color.black)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .offset(x: sliceX, y: sliceY)
                    }
                }
                .frame(height: UIScreen.main.bounds.height / 3)

            }
        }
        .onAppear {
            getEinnahmen(art: art)
        }
    }
    
    // Berechnet die Einnahmen von allen Kategorien der ausgwählten Art
    private func calculateTotalEinnahmen() -> Double {
        var totalEinnahmen: Double = 0.0
        
        for kategorie in kategorieOhneGesamt {
            totalEinnahmen += kategorie.einnahmen
        }
        
        return totalEinnahmen
    }
    
    // Geht alle Aktivtitäten durch und wenn die Einnahmen,bzw. Ausgaben > 0 sind i.d. jeweiligen Kategorie wird diese später im Diagramm angezeigt
    private func createPieChart() -> ([String], [Double]) {
        var kategorienListe = [String]()
        var einnahmenListe = [Double]()
        
        for kategorie in kategorieOhneGesamt {
            if kategorie.einnahmen > 0 {
                kategorienListe.append(kategorie.id)
                einnahmenListe.append(kategorie.einnahmen)
            }
        }
        return (kategorienListe, einnahmenListe)
    }
    
    //Bekommt die Einnahmen oder Ausgaben (Entscheidung über art:String) von einem Benutzer (email) zu einer möglichen Kategorie
    private func getEinnahmen(art:String) {
        let kategorien = ["Drogerie","Freizeit","Unterhaltung","Lebensmittel","Hobbys","Wohnen","Haushalt","Sonstiges","Technik","Finanzen","Restaurant","Shopping"]
        var gesamtEinnahmen: Double = 0
        
        for kategorie in kategorien {
            guard let url = URL(string: "http://localhost:8080/api/v1/aktivitaet/withKategorieAndArt/\(email)/\(kategorie)/\(art)?username=admin&password=password") else {
                return
            }
            
            dispatchGroup.enter()
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data, error == nil else {
                    print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                    dispatchGroup.leave()
                    return
                }
                
                if let einnahmenArr = try? JSONDecoder().decode([EinnahmenResponse].self, from: data) {
                    let einnahmen = einnahmenArr.reduce(0, { $0 + $1.betrag })
                    DispatchQueue.main.async {
                        self.kategorien.append(Kategorie(id: kategorie, einnahmen: einnahmen))
                        gesamtEinnahmen += einnahmen
                    }
                } else {
                    print("Invalid response from server")
                }
                dispatchGroup.leave()
            }.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.kategorien.append(Kategorie(id: "Gesamt", einnahmen: gesamtEinnahmen))
        }
    }
}
