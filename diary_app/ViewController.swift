//
//  ViewController.swift
//  diary_app
//
//  Created by Anton on 22/10/2025.
//

import UIKit
import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

class ViewController: UIViewController {

    private var label: UILabel = {
        let label = UILabel()
        label.text = "Welcome to your diary"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .medium)
        return label
    }()

    private var googleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with Google", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    private var githubButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with GitHub", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    // OAuth provider used for GitHub (and other OAuth providers)
    private var oauthProvider: OAuthProvider?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(label)
        view.addSubview(googleButton)
        view.addSubview(githubButton)
        label.translatesAutoresizingMaskIntoConstraints = false
        googleButton.translatesAutoresizingMaskIntoConstraints = false
        googleButton.addTarget(self, action: #selector(googleButtonTapped), for: .touchUpInside)
        githubButton.translatesAutoresizingMaskIntoConstraints = false
        githubButton.addTarget(self, action: #selector(githubButtonTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            googleButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            googleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleButton.widthAnchor.constraint(equalToConstant: 220),
            googleButton.heightAnchor.constraint(equalToConstant: 50),
            githubButton.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 12),
            githubButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            githubButton.widthAnchor.constraint(equalToConstant: 220),
            githubButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func googleButtonTapped() {
        performGoogleSignInFlow()
    }

    @objc private func githubButtonTapped() {
        performOAuthLoginFlow()
    }
    
    private func performGoogleSignInFlow() {
      // [START headless_google_auth]
      guard let clientID = FirebaseApp.app()?.options.clientID else { return }

      // Create Google Sign In configuration object.
      // [START_EXCLUDE silent]
      // TODO: Move configuration to Info.plist
      // [END_EXCLUDE]
      let config = GIDConfiguration(clientID: clientID)
      GIDSignIn.sharedInstance.configuration = config

      // Start the sign in flow!
      GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
        guard error == nil else {
          // [START_EXCLUDE]
          return displayError(error)
          // [END_EXCLUDE]
        }

        guard let user = result?.user,
          let idToken = user.idToken?.tokenString
        else {
          // [START_EXCLUDE]
          let error = NSError(
            domain: "GIDSignInError",
            code: -1,
            userInfo: [
              NSLocalizedDescriptionKey: "Unexpected sign in result: required authentication data is missing.",
            ]
          )
          return displayError(error)
          // [END_EXCLUDE]
        }

        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: user.accessToken.tokenString)

        // [START_EXCLUDE]
        signIn(with: credential)
        // [END_EXCLUDE]
      }
      // [END headless_google_auth]
    }

    func signIn(with credential: AuthCredential) {
      // [START signin_google_credential]
      Auth.auth().signIn(with: credential) { result, error in
        // [START_EXCLUDE silent]
        guard error == nil else { return self.displayError(error) }
        // [END_EXCLUDE]

        guard let user = result?.user else { return }
        self.storeUserIfNeeded(user)
        self.transitionToDiaryView(with: user)
      }
      // [END signin_google_credential]
    }
    
    // Вход с помощью GitHub (через Firebase OAuthProvider)
    private func performOAuthLoginFlow(providerID: String = "github.com") {
      oauthProvider = OAuthProvider(providerID: providerID)
      // Request user's email from GitHub
      oauthProvider?.scopes = ["user:email"]
      // Optional: show signup option
        oauthProvider?.customParameters = [
            "allow_signup": "true",
            "prompt": "select_account" // всегда выбираем аккаунт
        ]

      oauthProvider?.getCredentialWith(nil) { [weak self] credential, error in
        guard let self = self else { return }
        guard error == nil else { return self.displayError(error) }
        guard let credential = credential else { return }
        // Use the same signIn helper to finish the Firebase sign-in
        self.signIn(with: credential)
      }
    }

    private func storeUserIfNeeded(_ user: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                // пользователь уже сохранён
            } else {
                userRef.setData([
                    "name": user.displayName ?? "Unknown",
                    "email": user.email ?? "",
                    "createdAt": Timestamp(date: Date())
                ])
            }
        }
    }

    private func transitionToDiaryView(with user: User) {
        let diaryView = MainView()
        let hostingController = UIHostingController(rootView: diaryView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true)
    }

}

//Error display
extension UIViewController {
  public func displayError(_ error: Error?, from function: StaticString = #function) {
    guard let error = error else { return }
    print("ⓧ Error in \(function): \(error.localizedDescription)")
    let message = "\(error.localizedDescription)\n\n Occurred in \(function)"
    let errorAlertController = UIAlertController(
      title: "Error",
      message: message,
      preferredStyle: .alert
    )
    errorAlertController.addAction(UIAlertAction(title: "OK", style: .default))
    present(errorAlertController, animated: true, completion: nil)
  }
}
