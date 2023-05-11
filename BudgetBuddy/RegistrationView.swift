// Screen, indem sich Benutzer registrieren können
//
// Created by Daniel Mendes on 03.05.23.

import SwiftUI

struct RegistrationView: View {
    
    @State var email: String = ""
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State var name: String = ""
    @State var geburtstag: Date = Date()
    @State var kontostand: Double = 0.0
    @State var buddyName: String = ""
    @State var lieblingsGegenstand: String = ""
    
    @State var invalidEmailError: Bool = false
    @State var passwordsDoNotMatchError: Bool = false
    @State private var showLoggedInView = false
    
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        NavigationView {
            // Einzelnen Inputs für die jeweiligen Attribute
            Form {
                Section(header: Text("E-Mail")) {
                    TextField("E-Mail", text: $email)
                        .keyboardType(.emailAddress)
                        .overlay(invalidEmailError ? RoundedRectangle(cornerRadius: 5).stroke(Color.red) : nil)
                    
                    // Wenn Email ungültig ist
                    if invalidEmailError {
                        Text("Invalid email")
                            .foregroundColor(.red)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))


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
                
                Section(header: Text("Name")) {
                    TextField("Name", text: $name)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            

                Section(header: Text("Geburtstag")) {
                    DatePicker(selection: $geburtstag, displayedComponents: .date) {
                        Text("Geburtstag")
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Section(header: Text("Kontostand")) {
                    TextField("Kontostand", value: $kontostand, formatter: NumberFormatter())
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Section(header: Text("Buddy Name")) {
                    TextField("Buddy Name", text: $buddyName)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Section(header: Text("Lieblingsgegenstand")) {
                    TextField("Lieblingsgegenstand", text: $lieblingsGegenstand)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Button(action: {
                    if validateInputs() {
                        sendToBackend()
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
                .fullScreenCover(isPresented: $showLoggedInView, content: {
                    LoggedInView(email: email, logoutAction: logout)
                })
            }
            .navigationBarTitle(Text("Registrieren"), displayMode: .inline)
        }
        .background(Color.white)
    }

    func logout() {
        self.showLoggedInView = false
        self.presentationMode.wrappedValue.dismiss()
    }
    
    // Überprüft, ob es sich um gültige Eingaben handelt
    func validateInputs() -> Bool {
        invalidEmailError = false
        passwordsDoNotMatchError = false
        
        // Überprüfung, ob Email gültig ist
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            invalidEmailError = true
            return false
        }
    
        // Überprüfung, ob Passwörter übereinstimmen
        if password != confirmPassword {
            passwordsDoNotMatchError = true
            return false
        }
        
        return true
    }

    // Benutzer werden im Backend gespeichert
    func sendToBackend() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        let benutzer = Benutzer(email: email, password: password,name: name, geburtstag: dateFormatter.string(from: geburtstag), kontostand: kontostand, buddyName: buddyName, lieblingsGegenstand: lieblingsGegenstand)
        print (benutzer)
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(benutzer)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            print(jsonString)
            
            guard let url = URL(string: "http://localhost:8080/api/v1/benutzer/register") else {
                print("Error: cannot create URL")
                return
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = jsonData
            
            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest) { (data, response, error) in
                if let error = error {
                    print("Error sending data to server: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Error: invalid response")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.showLoggedInView = true
                    }
                    
                    print("Data sent successfully")
                } else {
                    print("Error: unexpected status code \(httpResponse.statusCode)")
                }
            }
            task.resume()
            
        } catch {
            print("Error encoding benutzer: \(error.localizedDescription)")
        }
    }
}
