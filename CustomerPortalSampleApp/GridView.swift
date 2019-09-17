//
//  GridView.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit

class GridView : UICollectionView
{
    let collectionViewHeaderFooterReuseIdentifier = "MyHeaderFooterClass"
    var contentHeight : CGFloat?{
        didSet
        {
            if let contentHeight = contentHeight, let prodCount = productCount
            {
                let layout = GridLayout()
                layout.contentHeight = contentHeight
                layout.footerIndex = prodCount + 1
                self.collectionViewLayout = layout
            }
            else if let contentHeight = contentHeight
            {
                let layout = GridLayout()
                layout.contentHeight = contentHeight
            }
        }
    }
    var productCount : Int?{
        didSet
        {
            if let prodCount = productCount, let contentHeight = contentHeight
            {
                let layout = GridLayout()
                layout.footerIndex = prodCount + 1
                layout.contentHeight = contentHeight
            }
            else if let prodCount = productCount
            {
                let layout = GridLayout()
                layout.footerIndex = prodCount + 1
            }
        }
    }
    
    convenience init()
    {
        let layout = GridLayout()
        self.init( frame : .zero, collectionViewLayout : layout )
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.translatesAutoresizingMaskIntoConstraints = true
        self.backgroundColor = .black
        let inset = UIEdgeInsets( top : 3, left : 3, bottom : 3, right : 3 )
        self.contentInset = inset
    }
}
