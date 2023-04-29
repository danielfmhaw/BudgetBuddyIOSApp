import SwiftUI

//Struktur von der Aktivität
struct Aktivitaet: Codable, Identifiable {
    var id: Int
    var betrag: Double
    var beschreibung: String
    var kategorie: String
    var art: String
    var benutzer: Benutzer
    var datum: String
}

//Struktur von dem Benutzer
struct Benutzer: Codable {
    var email: String
    var password: String
    var geburtstag: String
    var kontostand: Double
    var buddyName: String
    var lieblingsGegenstand: String
}

//Struktur von der Kategorie (also mit Summe aller Aktivtäten der Kategorie als "einnahmen")
struct Kategorie: Identifiable,Decodable {
    var id: String
    var einnahmen: Double
}
struct EinnahmenResponse: Decodable {
    var id: Int
    var betrag: Double
}

//Login-In Seite
struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showLoggedInView = false

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Image("budgetbuddybatch")
                          .resizable()
                          .aspectRatio(contentMode: .fit)
                
                TextField("E-mail", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)

                SecureField("Passwort", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)

                Button(action: {
                    authenticate()
                })
                {
                    Text("Einloggen")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(5.0)
                }
                .padding(.horizontal, 20)
                .sheet(isPresented: $showLoggedInView, content: {
                    //Hier wird zum LoggedIn-View "verlinkt"
                    LoggedInView(email: email, logoutAction: logout)
                })

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitle(Text("Login"), displayMode: .inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // Zieht die Benutzerdaten aus Backend und überprüft, ob successful oder failed
    func authenticate() {
        let url = URL(string: "http://localhost:8080/api/v1/benutzer")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["email": email, "password": password]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if response.statusCode == 200 {
                // Authentication successful
                DispatchQueue.main.async {
                    self.showLoggedInView = true
                }
            } else {
                // Authentication failed
                print("Authentication failed with status code \(response.statusCode)")
            }
        }.resume()
    }
    func logout() {
        self.showLoggedInView = false
    }
}

//Dient zur Simulation
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
