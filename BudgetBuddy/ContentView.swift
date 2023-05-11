import SwiftUI

//Struktur einer Aktivität
struct Aktivitaet: Codable, Identifiable {
    var id: Int
    var betrag: Double
    var beschreibung: String
    var kategorie: String
    var art: String
    var benutzer: Benutzer
    var datum: String
}

//Struktur eines Benutzers
struct Benutzer: Codable {
    var email: String
    var password: String
    var name:String
    var geburtstag: String
    var kontostand: Double
    var buddyName: String
    var lieblingsGegenstand: String
}

//Struktur einer Kategorie (also mit Summe aller Aktivtäten der Kategorie als "einnahmen")
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
    @State private var emailInput: String = ""
    private var email: String {
          emailInput.lowercased()
      }
    @State private var password = ""
    @State private var showLoggedInView = false
    @State private var loginFailed = false


    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Image("budgetbuddybatch")
                          .resizable()
                          .aspectRatio(contentMode: .fit)
                
                TextField("E-mail", text: $emailInput)
                           .padding()
                           .background(Color(.systemGray6))
                           .cornerRadius(5.0)
                           .padding(.bottom, 20)
                           .autocapitalization(.none)

                SecureField("Passwort", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)

                if(!loginFailed){
                    Button(action: {
                        if authenticate() {
                            showLoggedInView = true
                        } else {
                            loginFailed = true
                        }
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
                    .fullScreenCover(isPresented: $showLoggedInView, content: {
                        LoggedInView(email: email, logoutAction: logout)
                    })
                
                //Wird nur angezeigt, wenn Login nicht erfolgreich war
                }else{
                    Button(action: {
                        if authenticate() {
                            showLoggedInView = true
                        } else {
                            loginFailed = true
                        }
                    })
                    {
                        Text("Erneut Versuchen")
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(5.0)
                    }
                    .padding(.horizontal, 20)
                    .fullScreenCover(isPresented: $showLoggedInView, content: {
                        LoggedInView(email: email, logoutAction: logout)
                    })
                }
                Divider()
                
                // Verlinkung zum Registrieren
                if loginFailed {
                    NavigationLink(destination: RegistrationView()){
                        Text("Registrieren")
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitle(Text("Login"), displayMode: .inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear{
                showLoggedInView = false
                loginFailed = false
                
            }
            // Wenn man die Seite verlässt
            .onDisappear {
                emailInput = ""
                password = ""
            }
        }
    }
    
    
    // Zieht die Benutzerdaten aus Backend und überprüft, ob successful oder failed
    func authenticate() -> Bool {
        let url = URL(string: "http://localhost:8080/api/v1/benutzer")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["email": email, "password": password]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
        
        var success = false
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if response.statusCode == 200 {
                // Authentifikation erfolgreich
                success = true
            } else {
                print("Authentication failed with status code \(response.statusCode)")
            }
        }.resume()
        
        semaphore.wait()
        
        return success
    }
    
    //Wenn man sich ausloggt, werden Daten zurückgesetzt
    func logout() {
        self.showLoggedInView = false
        self.emailInput=""
        self.password=""
        self.loginFailed = false
    }
}

//Dient zum Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
