import SwiftUI


//Screen, um die Einnahmen bzw. Ausgaben sortiert entweder in Euro oder in % anzeigen zu lassen
struct EinnahmenView: View {
    var kategorien: [Kategorie] 
    let email: String
    let art: String
    
    @State var selectedDisplayMode = 0
    
    var kategorieOhneGesamt: [Kategorie] {
        return kategorien.filter { $0.id != "Gesamt" }
    }
    
    var body: some View {
        VStack {
            Text(art)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Picker("Anzeigen als", selection: $selectedDisplayMode) {
                Text("in Euro").tag(0)
                Text("in %").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if kategorien.isEmpty {
                Text("Lade Daten...")
            } else {
                if selectedDisplayMode == 0 {
                    VStack {
                       List(kategorien.filter { $0.einnahmen != 0 }.sorted { $0.einnahmen > $1.einnahmen }, id: \.id) { kategorie in
                           HStack {
                               Text(kategorie.id)
                               Spacer()
                               Text("\(kategorie.einnahmen, specifier: "%.2f") €")
                           }
                       }
                    }
                } else if selectedDisplayMode==1 {
                    let totalEinnahmen = kategorieOhneGesamt.map { $0.einnahmen }.reduce(0, +)
                    List(kategorieOhneGesamt.filter { $0.einnahmen != 0 }.sorted { $0.einnahmen > $1.einnahmen }, id: \.id) { kategorie in
                        HStack {
                            Text(kategorie.id)
                            Spacer()
                            let prozent = totalEinnahmen != 0 ? kategorie.einnahmen / totalEinnahmen * 100 : 0
                            Text("\(prozent, specifier: "%.2f") %")
                                .foregroundColor(getColorForPercentage(prozent))
                        }
                    }
                }
            }
        }
    }
    
    private func getColorForPercentage(_ prozent: Double) -> Color {
        if prozent >= 70 {
            return Color.red
        } else if prozent >= 40 {
            return Color.orange
        } else if prozent >= 20 {
            return Color.yellow
        } else {
            return Color.black
        }
    }
    
}

