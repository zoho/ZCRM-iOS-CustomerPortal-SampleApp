//
//  FooterView.swift
//  ZCRM-iOS-CustomerPortal-SampleApp
//
//  Created by Umashri R on 12/09/19.
//  Copyright © 2019 Umashri R. All rights reserved.
//

import UIKit

class FooterView: UICollectionReusableView
{
    var contentWidth : CGFloat = 0
    let numberOfColumns = 8
    var footerDetails : [ String : String ] = [ String : String ]()
    
    var labels : [ Int : String ] = [ Int : String ]()
    var values : [ Int : String ] = [ Int : String ]()
    
    static let footerViewIdentifier = "FooterView"
    
    static func register( with collectionView : UICollectionView )
    {
        collectionView.register( self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerViewIdentifier )
    }
    
    static func dequeue( from collectionView : UICollectionView, at indexPath : IndexPath, for details : [ String : String ] ) -> FooterView
    {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerViewIdentifier, for: indexPath ) as? FooterView ?? FooterView()
        footer.contentWidth = ( 8 * 152 ) + 2
        footer.footerDetails = details
        footer.setupLabels()
        return footer
    }
    
    private func setupLabels()
    {
        let columnWidth = contentWidth / CGFloat( numberOfColumns )
        var xOffset = [ CGFloat ]()
        for column in 0 ..< numberOfColumns {
            xOffset.append(CGFloat(column) * (columnWidth + 2))
        }
        var column = 0
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
        let height : CGFloat = 30
        var count = 0
        
        for ( key, value ) in footerDetails
        {
            getArray(key: key, value: value)
        }
        
        for _ in 0..<numberOfColumns * 5
        {
            var isBold = false
            if labels[ count ]! == "Grand_Total"
            {
                isBold = true
            }
            if column == 6
            {
                let frame = CGRect( x : xOffset[ column ], y : yOffset[ column ], width : columnWidth, height : height )
                setLabel(frame: frame, text: labels[ count ]!, isBold: isBold)
            }
            else if column == 7
            {
                let frame = CGRect( x : xOffset[ column ], y : yOffset[ column ], width : columnWidth, height : height )
                setLabel(frame: frame, text: values[ count ]!, isBold: isBold)
                count = count + 1
            }
            
            
            yOffset[ column ] = yOffset[ column ] + height + 2
            
            column = column < ( numberOfColumns - 1 ) ? ( column + 1 ) : 0
        }
    }
    
    private func getArray( key : String, value : String )
    {
        if key == "Sub_Total"
        {
            labels[ 0 ] = key
            values[ 0 ] = value
        }
        else if key == "Discount"
        {
            labels[ 1 ] = key
            values[ 1 ] = value
        }
        else if key == "Tax"
        {
            labels[ 2 ] = key
            values[ 2 ] = value
        }
        else if key == "Adjustment"
        {
            labels[ 3 ] = key
            values[ 3 ] = value
        }
        else if key == "Grand_Total"
        {
            labels[ 4 ] = key
            values[ 4 ] = value
        }
    }
    
    private func setLabel( frame : CGRect, text : String, isBold : Bool )
    {
        let label = UILabel(frame: frame)
        label.text = text
        if isBold
        {
            label.font = UIFont.boldSystemFont(ofSize: 18.0)
        }
        else
        {
            label.font = UIFont.systemFont(ofSize: 18.0)
        }
        
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(label)
    }
}

