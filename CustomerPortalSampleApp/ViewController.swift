//
//  ViewController.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit
import ZCRMiOS

class ViewController: UIViewController {
    
    var height : CGFloat = 0
    let userName : String = "Vijay"
    var myView : UIView = UIView()
    let welcomeLabel = UILabel()
    let userLabel = UILabel()
    let tableView = UITableView()
    let getQuotesButton = UIButton()
    let getInvoicesButton = UIButton()
    let getCasesButton = UIButton()
    let line = UIView()
    var records : [ ZCRMRecord ] = [ ZCRMRecord ]()
    var layouts : [ ZCRMLayout ] = [ ZCRMLayout ]()
    var listViewController = ListViewController()
    var contact : ZCRMRecord?
    
    // Profile photo Image View
    lazy var profilePhoto : UIImageView = {
        let image = UIImage( named : "Default photo" )
        let imageView = UIImageView( image : image )
        imageView.layer.borderWidth = 3.0
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = UIColor.darkGray
        return imageView
    }()
    
    var buttons = [ "Quotes", "Invoices", "Cases" ]
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( true )
        
        let logoutButton = UIBarButtonItem( title : "Logout", style : .plain, target : self, action : #selector( logout ) )
        self.navigationItem.rightBarButtonItem = logoutButton
        
        self.view = myView
        self.view.backgroundColor = .white
        self.view.addSubview( self.profilePhoto )
        
        addSubViews()
        
        self.title = "ZCRMCPApp"
        self.navigationItem.title = "ZCRMCPApp"
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        self.profilePhoto.contentMode = .scaleAspectFit
        self.tableView.rowHeight = self.tableView.frame.height / 3
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        ( UIApplication.shared.delegate as! AppDelegate ).loadLoginView { ( success ) in
            if( success == true )
            {
                ((UIApplication.shared.delegate) as! AppDelegate).initZCRMSDK()
                print( "Login successful" )
            }
        }
    }
    
    @objc func getQuotes()
    {
        getRecords( moduleAPIName : "Quotes" )
    }
    
    @objc func getInvoices()
    {
        getRecords( moduleAPIName : "Invoices" )
    }
    
    @objc func getCases()
    {
        getRecords( moduleAPIName : "Cases" )
    }
    
    @objc func logout()
    {
        ( UIApplication.shared.delegate as! AppDelegate ).logout(completion: { (success) in
            if( success == true )
            {
                ZCRMLogger.logInfo(message: "Logout successful")
            }
        })
    }
    
    func getRecords( moduleAPIName : String )
    {
        ZCRMSDKUtil.getModuleDelegate(apiName: moduleAPIName ).getRecords(recordParams: ZCRMQuery.GetRecordParams()) { ( result ) in
            do
            {
                let resp = try result.resolve()
                self.getLayouts( moduleAPIName : moduleAPIName )
                self.records = resp.data
                self.pushViewController()
            }
            catch
            {
                ZCRMLogger.logError( message : "Record could not be fetched!! Error : \( error )" )
            }
        }
    }
    
    func getLayouts( moduleAPIName : String )
    {
        ZCRMSDKUtil.getModuleDelegate( apiName : moduleAPIName ).getLayouts { ( result ) in
            do
            {
                let resp = try result.resolve()
                self.layouts = resp.data
                self.listViewController.layouts = self.layouts
            }
            catch
            {
                ZCRMLogger.logError( message : "Layouts could not be fetched!! Error : \( error )" )
            }
        }
    }
    
    func pushViewController()
    {
        self.navigationController?.pushViewController( self.listViewController, animated : true )
        self.listViewController.records = self.records
    }
    
    func getContact()
    {
        ZCRMSDKUtil.getModuleDelegate(apiName: "Contacts").getRecords(recordParams: ZCRMQuery.GetRecordParams()) { ( result ) in
            do
            {
                let resp = try result.resolve()
                if !(resp.data.count == 1)
                {
                    ZCRMLogger.logError( message : "More than one record found!!" )
                }
                else
                {
                    self.contact = resp.data[0]
                    if let contactName = self.contact?.getData()[ "Last_Name" ] as? String
                    {
                        self.welcomeLabel.text = "Welcome, " + contactName
                    }
                    if let email = self.contact?.getData()[ "Email" ] as? String
                    {
                        self.userLabel.text = email
                    }
                    self.downloadPhoto()
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "Record could not be fetched!! Error : \( error )" )
            }
        }
    }
    
    func downloadPhoto()
    {
        self.contact?.downloadPhoto(completion: { ( photoResult ) in
            do
            {
                let photoResp = try photoResult.resolve()
                let photoData = photoResp.getFileData()
                if let data = photoData
                {
                    let image = UIImage(data: data)
                    DispatchQueue.main.async {
                        self.viewDidAppear( true )
                        self.profilePhoto.image = image
                    }
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "Photo could not be downloaded!! Error : \( error )" )
            }
        })
    }
    
    func addSubViews()
    {
        let space1 = UILayoutGuide()
        self.view.addLayoutGuide( space1 )
        
        let space2 = UILayoutGuide()
        self.view.addLayoutGuide( space2 )
        
        space1.topAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.topAnchor ).isActive = true
        space1.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        space1.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        space1.heightAnchor.constraint( equalTo : space2.heightAnchor ).isActive = true
        
        space2.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        space2.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        
        let space3 = UILayoutGuide()
        self.view.addLayoutGuide( space3 )
        
        let space4 = UILayoutGuide()
        self.view.addLayoutGuide( space4 )
        
        space3.topAnchor.constraint( equalTo : space1.bottomAnchor ).isActive = true
        space3.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        space3.bottomAnchor.constraint( equalTo : space2.topAnchor ).isActive = true
        space3.widthAnchor.constraint( equalTo : space4.widthAnchor ).isActive = true
        
        space4.topAnchor.constraint( equalTo : space1.bottomAnchor ).isActive = true
        space4.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        space4.bottomAnchor.constraint( equalTo : space2.topAnchor ).isActive = true
        
        self.profilePhoto.translatesAutoresizingMaskIntoConstraints = false
        self.profilePhoto.topAnchor.constraint( equalTo : space1.bottomAnchor ).isActive = true
        self.profilePhoto.leadingAnchor.constraint( equalTo :  space3.trailingAnchor ).isActive = true
        self.profilePhoto.bottomAnchor.constraint( equalTo :  space2.topAnchor ).isActive = true
        self.profilePhoto.trailingAnchor.constraint( equalTo :  space4.leadingAnchor ).isActive = true
        self.profilePhoto.widthAnchor.constraint( equalToConstant : 200 ).isActive = true
        self.profilePhoto.heightAnchor.constraint( equalToConstant : 200 ).isActive = true
        
        let space5 = UILayoutGuide()
        self.view.addLayoutGuide( space5 )
        
        self.getContact()
        welcomeLabel.text = "Welcome"
        welcomeLabel.textAlignment = .center
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview( welcomeLabel )
        
        welcomeLabel.topAnchor.constraint( equalTo : space2.bottomAnchor ).isActive = true
        welcomeLabel.bottomAnchor.constraint( equalTo : space5.topAnchor ).isActive = true
        welcomeLabel.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        welcomeLabel.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        welcomeLabel.heightAnchor.constraint( equalToConstant : 50 ).isActive = true
        welcomeLabel.widthAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.widthAnchor ).isActive = true
        
        space2.bottomAnchor.constraint( equalTo : welcomeLabel.topAnchor ).isActive = true
        
        space5.heightAnchor.constraint( equalTo : space2.heightAnchor ).isActive = true
        space5.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        space5.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        space5.topAnchor.constraint( equalTo : welcomeLabel.bottomAnchor ).isActive = true
        
        let space6 = UILayoutGuide()
        self.view.addLayoutGuide( space6 )
        
        userLabel.text = "Vijay"
        userLabel.textAlignment = .center
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        myView.addSubview( userLabel )
        
        userLabel.topAnchor.constraint( equalTo : space5.bottomAnchor ).isActive = true
        userLabel.bottomAnchor.constraint( equalTo : space6.topAnchor ).isActive = true
        userLabel.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        userLabel.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        userLabel.heightAnchor.constraint( equalToConstant : 50 ).isActive = true
        userLabel.widthAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.widthAnchor ).isActive = true
        
        space5.bottomAnchor.constraint( equalTo : userLabel.topAnchor ).isActive = true
        
        space6.heightAnchor.constraint( equalTo : space5.heightAnchor ).isActive = true
        space6.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        space6.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        space6.topAnchor.constraint( equalTo : userLabel.bottomAnchor ).isActive = true
        
        let space8 = UILayoutGuide()
        self.view.addLayoutGuide( space8 )
        
        getQuotesButton.setTitle( "Quotes", for : .normal )
        getQuotesButton.setTitleColor( .blue, for : .normal )
        getQuotesButton.addTarget( self, action : #selector( getQuotes ), for: .touchUpInside )
        
        getQuotesButton.translatesAutoresizingMaskIntoConstraints = false
        myView.addSubview( getQuotesButton )
        
        getQuotesButton.topAnchor.constraint( equalTo : space6.bottomAnchor ).isActive = true
        getQuotesButton.bottomAnchor.constraint( equalTo : space8.topAnchor ).isActive = true
        getQuotesButton.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        getQuotesButton.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        getQuotesButton.heightAnchor.constraint( equalToConstant : 50 ).isActive = true
        getQuotesButton.widthAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.widthAnchor ).isActive = true
        
        space6.bottomAnchor.constraint( equalTo : getQuotesButton.topAnchor ).isActive = true
        
        space8.heightAnchor.constraint( equalTo : space6.heightAnchor ).isActive = true
        space8.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        space8.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        space8.topAnchor.constraint( equalTo : getQuotesButton.bottomAnchor ).isActive = true
        
        let space9 = UILayoutGuide()
        myView.addLayoutGuide( space9 )
        
        getInvoicesButton.setTitle( "Invoices", for : .normal )
        getInvoicesButton.setTitleColor( .blue, for : .normal )
        getInvoicesButton.addTarget( self, action : #selector( getInvoices ), for: .touchUpInside )
        
        getInvoicesButton.translatesAutoresizingMaskIntoConstraints = false
        myView.addSubview( getInvoicesButton )
        
        getInvoicesButton.topAnchor.constraint( equalTo : space8.bottomAnchor ).isActive = true
        getInvoicesButton.bottomAnchor.constraint( equalTo : space9.topAnchor ).isActive = true
        getInvoicesButton.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        getInvoicesButton.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        getInvoicesButton.heightAnchor.constraint( equalToConstant : 50 ).isActive = true
        getInvoicesButton.widthAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.widthAnchor ).isActive = true
        
        space8.bottomAnchor.constraint( equalTo : getInvoicesButton.topAnchor ).isActive = true
        
        space9.heightAnchor.constraint( equalTo : space8.heightAnchor ).isActive = true
        space9.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        space9.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        space9.topAnchor.constraint( equalTo : getInvoicesButton.bottomAnchor ).isActive = true
        
        let space10 = UILayoutGuide()
        myView.addLayoutGuide( space10 )
        
        getCasesButton.setTitle( "Cases", for : .normal )
        getCasesButton.setTitleColor( .blue, for : .normal )
        getCasesButton.addTarget( self, action : #selector( getCases ), for: .touchUpInside )
        
        getCasesButton.translatesAutoresizingMaskIntoConstraints = false
        myView.addSubview( getCasesButton )
        
        getCasesButton.topAnchor.constraint( equalTo : space9.bottomAnchor ).isActive = true
        getCasesButton.bottomAnchor.constraint( equalTo : space10.topAnchor ).isActive = true
        getCasesButton.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        getCasesButton.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        getCasesButton.heightAnchor.constraint( equalToConstant : 50 ).isActive = true
        getCasesButton.widthAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.widthAnchor ).isActive = true
        
        space9.bottomAnchor.constraint( equalTo : getCasesButton.topAnchor ).isActive = true
        
        space10.heightAnchor.constraint( equalTo : space9.heightAnchor ).isActive = true
        space10.leadingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.leadingAnchor ).isActive = true
        space10.trailingAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.trailingAnchor ).isActive = true
        space10.topAnchor.constraint( equalTo : getCasesButton.bottomAnchor ).isActive = true
        space10.bottomAnchor.constraint( equalTo : self.view.safeAreaLayoutGuide.bottomAnchor ).isActive = true
    }
}

