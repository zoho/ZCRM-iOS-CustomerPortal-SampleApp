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
        super.viewWillAppear( true )
        self.view = tableView
        
        tableView.register( UITableViewCell.self, forCellReuseIdentifier : "cell" )
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
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
