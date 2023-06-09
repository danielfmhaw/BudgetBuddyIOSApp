import SwiftUI

//Dient zum Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//Struktur einer Aktivität
struct Aktivitaet: Codable, Identifiable {
    var id: Int
    var betrag: Double
    var beschreibung: String
    var kategorie: String
    var art: String
    var benutzer: Benutzer
    var datum: String
    var savingsTarget: Target?
    var anteil: Double?
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
    @State var emailInput: String? = ""
    @State var password: String? = ""
    @State var showRegistration = true
       
    private var email: String {
            emailInput?.lowercased() ?? ""
    }
    
    @State private var showLoggedInView = false
    @State private var loginFailed = false
    @State private var emailExits = false
    @Environment(\.colorScheme) var colorScheme


    var body: some View {
        NavigationView {
            VStack {
                Spacer()
            
                if colorScheme == .light {
                        Image("budgetbuddybatch")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image("budgetbuddybatch_black")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                
                TextField("E-mail", text: Binding($emailInput) ?? .constant(""))
                           .padding()
                           .background(Color(.systemGray6))
                           .cornerRadius(5.0)
                           .padding(.bottom, 20)
                           .autocapitalization(.none)

                SecureField("Passwort", text: Binding($password) ?? .constant(""))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)

                if(!loginFailed){
                    Button(action: {
                        if authenticate() {
                            showLoggedInView = true
                            UserDefaults.standard.set(Date(), forKey: "lastLoginTime")
                            UserDefaults.standard.set(emailInput, forKey: "savedEmail")
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
                            UserDefaults.standard.set(Date(), forKey: "lastLoginTime")
                            UserDefaults.standard.set(emailInput, forKey: "savedEmail")
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
                
                // Verlinkung zum Ändern des Passworts
                if loginFailed {
                    if (emailExits) {
                        NavigationLink(destination: PasswortUpdate(emailInput: email)) {
                            Text("Passwort verändern")
                        }
                    } else {
                        Text("Email nicht vorhanden")
                            .foregroundColor(.red)
                            .padding(.bottom, 10)
                    }
                }
                Spacer()
            }
            // Verlinkung zum Registrieren
            .navigationBarItems(trailing:
                Group {
                    if showRegistration {
                        NavigationLink(destination: RegistrationView()) {
                            Text("Registrieren")
                        }
                    } else {
                        EmptyView()
                    }
                }
            )

            .padding(.horizontal, 20)
            .navigationBarTitle(Text("Login"), displayMode: .inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                showLoggedInView = false
                loginFailed = false

                if let lastLoginTime = UserDefaults.standard.object(forKey: "lastLoginTime") as? Date {
                    let currentTime = Date()
                    let timeInterval = currentTime.timeIntervalSince(lastLoginTime)
                    let twentyFourHours: TimeInterval = 24 * 60 * 60

                    if timeInterval <= twentyFourHours {
                        if let savedEmail = UserDefaults.standard.string(forKey: "savedEmail") {
                            emailInput = savedEmail
                        }
                        if emailInput?.count ?? 0 > 0 {
                            showLoggedInView = true
                        }
                    }
                }
            }

            // Wenn man die Seite verlässt
            //.onDisappear {
            //    emailInput = ""
            //    password = ""
            //}
        }
    }
    
    //Checkt, ob die Email schon existiert im Backend
    func checkEmailExists(email: String) -> Bool {
        guard let url = URL(string: "http://localhost:8080/api/v1/benutzer/\(email)?username=admin&password=password") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let semaphore = DispatchSemaphore(value: 0)
        var emailExists = false

        URLSession.shared.dataTask(with: request) { _, response, error in
            defer {
                semaphore.signal()
            }

            if let error = error {
                print("Fehler beim Abrufen der Daten: \(error)")
                return
            }

            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                // Die E-Mail existiert
                emailExists = true
            }
        }.resume()

        semaphore.wait()

        return emailExists
    }
    
    // Zieht die Benutzerdaten aus Backend und überprüft, ob successful oder failed
    func authenticate() -> Bool {
        emailExits=checkEmailExists(email: emailInput ?? "")
        let url = URL(string: "http://localhost:8080/api/v1/benutzer?username=admin&password=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["email": email, "password": password]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
        
        var success = false
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            guard let _ = data, let response = response as? HTTPURLResponse, error == nil else {
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
        self.showRegistration = true
        UserDefaults.standard.set(nil, forKey: "lastLoginTime")
        UserDefaults.standard.set(nil, forKey: "savedEmail")
    }
}

//Strukt, bei der zu einer Email das Passwort aktualisiert werden kann und als Verifikation wird der Lieblingsgegenstand genommen
struct PasswortUpdate:View{
    @State var emailInput: String? = ""
    @State var benutzer: Benutzer?
    
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State var lieblingsGegenstand: String = ""
    @State private var showLoggedInView = false
    
    @State var passwordsDoNotMatchError: Bool = false
    @State var lieblingsGegenstandVerifyFalse: Bool = false
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("E-Mail")) {
                    Text(emailInput ?? (""))
                }
                
                Section(header: Text("Password")) {
                    SecureField("Password", text: $password)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .overlay(passwordsDoNotMatchError ? RoundedRectangle(cornerRadius: 5).stroke(Color.red) : nil)

                    // Wenn die Passwörter nicht übereinstimmen
                    if passwordsDoNotMatchError {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .padding(.bottom, 10)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                
                Section(header: Text("Lieblingsgegenstand")) {
                    TextField("Lieblingsgegenstand zur Verifikation", text: $lieblingsGegenstand)
                        .overlay(lieblingsGegenstandVerifyFalse ? RoundedRectangle(cornerRadius: 5).stroke(Color.red) : nil)
                    if lieblingsGegenstandVerifyFalse {
                        Text("Verifikation nicht erfolgreich")
                            .foregroundColor(.red)
                            .padding(.bottom, 10)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Button(action: {
                    if validateInputs() {
                        sendToBackend()
                    }
                }) {
                    Text("Einloggen")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(5.0)
                }
                .fullScreenCover(isPresented: $showLoggedInView) {
                    ContentView(emailInput: emailInput, password: password,showRegistration: false)
                }
            }
            .onAppear {
                fetchData(email: emailInput ?? "")
            }
            .navigationBarTitle("Passwort aktualisieren", displayMode: .inline)
        }
    }

    
    // Überprüft, ob es sich um gültige Eingaben handelt
    func validateInputs() -> Bool {
        passwordsDoNotMatchError = false
        lieblingsGegenstandVerifyFalse = false
    
        if(lieblingsGegenstand != benutzer?.lieblingsGegenstand){
            lieblingsGegenstandVerifyFalse = true
            return false
        }
        
        // Überprüfung, ob Passwörter übereinstimmen
        if password != confirmPassword {
            passwordsDoNotMatchError = true
            return false
        }
        return true
    }
    
    // Zieht den Benuter aus dem Backend
    func fetchData(email:String) {
        guard let url = URL(string: "http://localhost:8080/api/v1/benutzer/\(email)?username=admin&password=password") else {
            print("Ungültige URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Fehler beim Abrufen der Daten: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Keine Daten erhalten")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let benutzer = try decoder.decode(Benutzer.self, from: data)
                
                DispatchQueue.main.async {
                    self.benutzer = benutzer
                }
            } catch {
                print("Fehler beim Dekodieren der Daten: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Benutzer wird im Backend gespeichert
    func sendToBackend() {
        benutzer?.password=confirmPassword
        
        guard let url = URL(string: "http://localhost:8080/api/v1/benutzer?username=admin&password=password") else {
            return
        }
        
        guard let editedValueData = try? JSONEncoder().encode(benutzer) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = editedValueData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Response code: \(response.statusCode)")
            }
            
            if let data = data {
            }
            DispatchQueue.main.async {
                showLoggedInView=true
            }
        }.resume()
    }
}
