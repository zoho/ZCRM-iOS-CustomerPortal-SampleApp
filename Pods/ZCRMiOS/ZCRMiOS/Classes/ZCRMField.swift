//
//  ZCRMField.swift
//  ZCRMiOS
//
//  Created by Vijayakrishna on 14/11/16.
//  Copyright © 2016 zohocrm. All rights reserved.
//

open class ZCRMField : ZCRMEntity
{
	public internal( set ) var apiName : String
	public internal( set ) var id : Int64 = APIConstants.INT64_MOCK
	public internal( set ) var displayLabel : String = APIConstants.STRING_MOCK
	public internal( set ) var dataType : String = APIConstants.STRING_MOCK
    public internal( set ) var isReadOnly : Bool = APIConstants.BOOL_MOCK
    public internal( set ) var isVisible : Bool = APIConstants.BOOL_MOCK
    public var isMandatory : Bool?
    public internal( set ) var isCustomField : Bool = APIConstants.BOOL_MOCK
	public internal( set ) var defaultValue : Any?
	public internal( set ) var maxLength : Int?
	public internal( set ) var precision : Int?
	public internal( set ) var sequenceNo : Int?
	public internal( set ) var subLayoutsPresent : [String]?
	public internal( set ) var pickListValues : [ ZCRMPickListValue ]?
	public internal( set ) var formulaReturnType : String?
	public internal( set ) var formulaExpression : String?
    
    public internal( set ) var tooltip : String?
    public internal( set ) var webhook : Bool = APIConstants.BOOL_MOCK
    public internal( set ) var isRestricted : Bool?
    public internal( set ) var restrictedType : String?
    public internal( set ) var isSupportExport : Bool?
    public internal( set ) var createdSource : String = APIConstants.STRING_MOCK
    public internal( set ) var bussinessCardSupported : Bool?
    
    public internal( set ) var roundingOption : CurrencyRoundingOption?
    public internal( set ) var decimalPlace : Int?
    public internal( set ) var lookup : [String : Any]?
    public internal( set ) var multiSelectLookup : [String : Any]?
    public internal( set ) var subFormTabId : Int64?
    public internal( set ) var subForm : [String : Any]?
    
    init( apiName : String )
    {
        self.apiName = apiName
    }
	    
    /// Add the pick list value to the ZCRMField.
    ///
    /// - Parameter pickListValue: value to be added
    internal func addPickListValue( pickListValue : ZCRMPickListValue )
    {
        if self.pickListValues == nil
        {
            self.pickListValues = [ ZCRMPickListValue ]()
        }
        self.pickListValues?.append( pickListValue )
    }
	
    /// Returns true if view type includes "create".
    ///
    /// - Returns: true if view type includes "create"
	public func isPresentInCreateLayout() -> Bool?
	{
		return self.subLayoutsPresent?.contains("CREATE")
	}
	
    /// Returns true if view type includes "view".
    ///
    /// - Returns: true if view type includes "view"
	public func isPresentInViewLayout() -> Bool?
	{
		return self.subLayoutsPresent?.contains("VIEW")
	}
	
    /// Returns true if view type includes "quick create".
    ///
    /// - Returns: true if view type includes "quick create"
	public func isPresentInQuickCreateLayout() -> Bool?
	{
		return self.subLayoutsPresent?.contains("QUICK_CREATE")
	}
    
    /// Returns true if view type includes "edit".
    ///
    /// - Returns: true if view type includes "edit"
    public func isPresentInEditLayout() -> Bool?
    {
        return self.subLayoutsPresent?.contains("EDIT")
    }
}

extension ZCRMField : Equatable
{
    public static func == (lhs: ZCRMField, rhs: ZCRMField) -> Bool {
        var lookupFlag : Bool
        var multiSelectLookupFlag : Bool
        var subformFlag : Bool
        if lhs.lookup == nil && rhs.lookup == nil
        {
            lookupFlag = true
        }
        else if let lhsLookup = lhs.lookup, let rhsLookup = rhs.lookup
        {
            lookupFlag = NSDictionary(dictionary: lhsLookup).isEqual(to: rhsLookup)
        }
        else
        {
            lookupFlag = false
        }
        if lhs.multiSelectLookup == nil && rhs.multiSelectLookup == nil
        {
            multiSelectLookupFlag = true
        }
        else if let lhsMultiSelectLookup = lhs.multiSelectLookup, let rhsMultiSelectLookup = rhs.multiSelectLookup
        {
            multiSelectLookupFlag = NSDictionary(dictionary: lhsMultiSelectLookup).isEqual(to: rhsMultiSelectLookup)
        }
        else
        {
            multiSelectLookupFlag = false
        }
        if lhs.subForm == nil && rhs.subForm == nil
        {
            subformFlag = true
        }
        else if let lhsSubForm = lhs.subForm, let rhsSubForm = rhs.subForm
        {
            subformFlag = NSDictionary(dictionary: lhsSubForm).isEqual(to: rhsSubForm)
        }
        else
        {
            subformFlag = false
        }
        let equals : Bool = lhs.apiName == rhs.apiName &&
            lhs.id == rhs.id &&
            lhs.displayLabel == rhs.displayLabel &&
            lhs.dataType == rhs.dataType &&
            lhs.isReadOnly == rhs.isReadOnly &&
            lhs.isVisible == rhs.isVisible &&
            lhs.isMandatory == rhs.isMandatory &&
            lhs.isCustomField == rhs.isCustomField &&
            lhs.maxLength == rhs.maxLength &&
            lhs.precision == rhs.precision &&
            lhs.sequenceNo == rhs.sequenceNo &&
            lhs.subLayoutsPresent == rhs.subLayoutsPresent &&
            lhs.pickListValues == rhs.pickListValues &&
            lhs.formulaReturnType == rhs.formulaReturnType &&
            lhs.formulaExpression == rhs.formulaExpression &&
            lhs.tooltip == rhs.tooltip &&
            lhs.webhook == rhs.webhook &&
            lhs.isRestricted == rhs.isRestricted &&
            lhs.restrictedType == rhs.restrictedType &&
            lhs.isSupportExport == rhs.isSupportExport &&
            lhs.createdSource == rhs.createdSource &&
            lhs.bussinessCardSupported == rhs.bussinessCardSupported &&
            lhs.roundingOption == rhs.roundingOption &&
            lhs.decimalPlace == rhs.decimalPlace &&
            lookupFlag &&
            multiSelectLookupFlag &&
            lhs.subFormTabId == rhs.subFormTabId &&
            subformFlag &&
            isEqual( lhs : lhs.defaultValue, rhs : rhs.defaultValue )
        return equals
    }
}
