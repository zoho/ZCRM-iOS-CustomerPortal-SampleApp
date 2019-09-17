//
//  ListViewController.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit
import ZCRMiOS

class ListViewController: UIViewController {
    
    var tableView = UITableView()
    var records : [ ZCRMRecord ] = [ ZCRMRecord ]()
    var layouts : [ ZCRMLayout ] = [ ZCRMLayout ]()
    
    override func viewWillAppear(_ animated: Bool)
    {
        let logoutButton = UIBarButtonItem( title : "Logout", style : .plain, target : self, action : #selector( logout ) )
        self.navigationItem.rightBarButtonItem = logoutButton
        
        super.viewWillAppear( true )
        self.view = tableView
        
        tableView.register( UITableViewCell.self, forCellReuseIdentifier : "cell" )
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @objc func logout()
    {
        ( UIApplication.shared.delegate as! AppDelegate ).logout(completion: { (success) in
            if( success == true )
            {
                print("logout successful")
            }
        })
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension ListViewController : UITableViewDataSource, UITableViewDelegate
{
    func tableView( _ tableView : UITableView, numberOfRowsInSection section : Int ) -> Int
    {
        return records.count
    }
    
    func tableView( _ tableView : UITableView, cellForRowAt indexPath : IndexPath ) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell( withIdentifier : "cell", for : indexPath )
        cell.textLabel?.text = records[ indexPath.row ].getData()[ "Subject" ] as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow( at : indexPath, animated : true )
        let detailsViewController = DetailViewController( record : records[ indexPath.row ], layouts : layouts, nibName : nil, bundle : nil )
        self.navigationController?.pushViewController( detailsViewController, animated : true )
    }
}
