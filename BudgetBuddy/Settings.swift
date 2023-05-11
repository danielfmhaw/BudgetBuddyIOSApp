// Screen, um die Benutzerdaten anzuzeigen
//
// Created by Daniel Mendes on 29.04.23.

import SwiftUI


// Benutzer wird aus dem LoggenInView übergeben
struct BenutzerView: View {
    let benutzer: Benutzer?
    
    // Nur Anzeigen der verschiedenen Attribute
    var body: some View {
        if let benutzer = benutzer {
            VStack(alignment: .leading) {
                HStack(spacing: 5) {
                    Text("Email:")
                    Text(benutzer.email)
                        .font(.headline)
                }
                
                HStack(spacing: 5) {
                    Text("Geburtstag:")
                    Text(benutzer.geburtstag.prefix(10))
                        .font(.headline)
                }
                
                HStack(spacing: 5) {
                    Text("Buddy-Name:")
                    Text(benutzer.name)
                        .font(.headline)
                }
                
                HStack(spacing: 5) {
                    Text("Kontostand:")
                    Text(String(format: "%.2f €", benutzer.kontostand))
                        .font(.headline)
                }
                
                HStack(spacing: 5) {
                    Text("Buddy-Name:")
                    Text(benutzer.buddyName)
                        .font(.headline)
                }
                
                HStack(spacing: 5) {
                    Text("Lieblings-Gegenstand:")
                    Text(benutzer.lieblingsGegenstand)
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
        }
    }
}
