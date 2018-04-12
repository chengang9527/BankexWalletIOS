//
//  WalletImportController.swift
//  BankexWallet
//
//  Created by Korovkina, Ekaterina on 4/3/2561 BE.
//  Copyright © 2561 Alexander Vlasov. All rights reserved.
//

import UIKit
import QRCodeReader
import AVFoundation

enum WalletKeysMode {
    
    case importKey
    case createKey
    
    func title() -> String {
        switch self {
        case .importKey:
            return "Import key"
        case .createKey:
            return "Create key"
        }
    }
    
    func shortTitle() -> String {
        switch self {
        case .importKey:
            return "Import"
        case .createKey:
            return "Create"
        }

    }
}

class WalletSingleKeyController: UIViewController,
UITextFieldDelegate,
UIScrollViewDelegate,
QRCodeReaderViewControllerDelegate {

    var mode: WalletKeysMode = WalletKeysMode.createKey
    let router: WalletCreationRouter = WalletCreationTypeRouterImplementation()
    
    // MARK: Outlets
    @IBOutlet weak var enterPrivateTextField: UITextField!
    @IBOutlet weak var walletNameTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet var textfields: [UITextField]!
    @IBOutlet weak var hideKeyboardButton: UIButton!
    @IBOutlet var textfieldsSeparators: [UIView]!
    @IBOutlet weak var importButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var topEmptyView: UIView!
    @IBOutlet weak var privateTextfieldContainer: UIView!
    
    @IBOutlet weak var separator1: UIView!
    
    // MARK: --
    let service = SingleKeyServiceImplementation()
    
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardButton.gestureRecognizers?.forEach({ (rcgn) in
            rcgn.require(toFail: scrollView.panGestureRecognizer)
        })
        importButton.setTitle(mode.shortTitle(), for: .normal)

        importButton.isEnabled = false
        importButton.backgroundColor = importButton.isEnabled ? WalletColors.defaultDarkBlueButton.color() : WalletColors.disableButtonBackground.color()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardDidHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if mode == .createKey {
            stackView.removeArrangedSubview(topEmptyView)
            privateTextfieldContainer.removeFromSuperview()
//            stackView.removeArrangedSubview(privateTextfieldContainer)
            stackView.removeArrangedSubview(separator1)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Keyboard
    @objc func keyboardDidHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)

        UIView.animate(withDuration: duration,
                       delay: TimeInterval(0),
                       options: animationCurve,
                       animations: {
                        self.scrollView.contentInset = UIEdgeInsets.zero
                        self.scrollView.contentOffset = CGPoint.zero
                        
        },
                       completion: nil)
    }
    
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame?.origin.y ?? 0
            let endFrameHeight = endFrame?.size.height ?? 0
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            let textField = textfields.first {$0.isFirstResponder}
            let textFieldFrameY = (textField?.frame.maxY ?? 0) + 50
            var  newOffset: CGFloat = 0
            if textFieldFrameY > view.frame.maxY - endFrameHeight && textField != nil {
                newOffset = textFieldFrameY - (view.frame.maxY - endFrameHeight)
            }

            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: {
                            if endFrameY >= UIScreen.main.bounds.size.height {
                                self.scrollView.contentInset = UIEdgeInsets.zero
                            } else {
                                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, endFrame?.size.height ?? 0.0, 0)
                            }
                            self.scrollView.contentOffset = CGPoint(x: 0, y: newOffset)
                            
            },
                           completion: nil)
        }
    }
    
    
    // MARK: TextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let index = textfields.index(of: textField) ?? 0
        textfieldsSeparators[index].backgroundColor = WalletColors.blueText.color()
        textField.textColor = WalletColors.blueText.color()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = (textField.text ?? "")  as NSString
        let futureString = currentText.replacingCharacters(in: range, with: string) as String
        importButton.isEnabled = false

        switch textField {
        case enterPrivateTextField:
            if passwordTextField.text == repeatPasswordTextField.text &&
                !(passwordTextField.text?.isEmpty ?? true) &&
                !futureString.isEmpty {
                importButton.isEnabled = true
            }
        case passwordTextField:
            if !futureString.isEmpty &&
            futureString == repeatPasswordTextField.text {
                importButton.isEnabled = !(enterPrivateTextField.text?.isEmpty ?? true) || mode == .createKey
            }
        case repeatPasswordTextField:
            if !futureString.isEmpty &&
                futureString == passwordTextField.text
                 {
                importButton.isEnabled = !(enterPrivateTextField.text?.isEmpty ?? true) || mode == .createKey
            }
        default:
            importButton.isEnabled = false
        }
        
        importButton.backgroundColor = importButton.isEnabled ? WalletColors.defaultDarkBlueButton.color() : WalletColors.disableButtonBackground.color()

        return true
    }
    
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        let index = textfields.index(of: textField) ?? 0
        textfieldsSeparators[index].backgroundColor = WalletColors.greySeparator.color()
        textField.textColor = WalletColors.defaultText.color()
        
        guard textField == repeatPasswordTextField ||
            textField == passwordTextField else {
                return true
        }
        if !(passwordTextField.text?.isEmpty ?? true) &&
            !(repeatPasswordTextField.text?.isEmpty ?? true) && passwordTextField.text != repeatPasswordTextField.text {
            repeatPasswordTextField.textColor = WalletColors.errorRed.color()
            passwordTextField.textColor = WalletColors.errorRed.color()
            let psdIndex = textfields.index(of: passwordTextField) ?? 0
            let repeatIndex = textfields.index(of: repeatPasswordTextField) ?? 0
            textfieldsSeparators[psdIndex].backgroundColor = WalletColors.errorRed.color()
            textfieldsSeparators[repeatIndex].backgroundColor = WalletColors.errorRed.color()
        }
        return true
    }
    
    // MARK: ScrollViewDelegate
    
    
    // MARK: Actions
    @IBAction func emptySpaceTapped(_ sender: Any) {
        view.endEditing(false)
    }
    
    @IBAction func createWalletButtonTapped(_ sender: Any) {
        if mode == .createKey {
            service.createNewSingleAddressWallet(with: walletNameTextField.text,
                                                 password: enterPrivateTextField.text!,
                                                 completion: { (error) in
                                                    self.router.exitFromTheScreen()
            })
        } else {
            service.createNewSingleAddressWallet(with: walletNameTextField.text,
                                                 fromText: enterPrivateTextField.text!,
                                                 password: passwordTextField.text!,
                                                 completion: { (error) in
                                                    self.router.exitFromTheScreen()
            })
        }
    }
    
    @IBAction func switchPasswordSecurity(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
        sender.setImage(passwordTextField.isSecureTextEntry ? #imageLiteral(resourceName: "Eye open") : #imageLiteral(resourceName: "Eye closed"), for: .normal)
    }
    @IBAction func clearPrivateKeyTapped(_ sender: Any) {
        enterPrivateTextField.text = ""
    }
    
    @IBAction func qrScanTapped(_ sender: Any) {
        readerVC.delegate = self
        
        // Or by using the closure pattern
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in        }
        
        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }
    
    // MARK: QR Code scan
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    // MARK: - QRCodeReaderViewController Delegate Methods
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        enterPrivateTextField.text = result.value
        dismiss(animated: true, completion: nil)
    }
    
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        dismiss(animated: true, completion: nil)
    }
}
