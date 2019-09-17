//
//  ZCRMModuleRelation.swift
//  ZCRMiOS
//
//  Created by Vijayakrishna on 14/11/16.
//  Copyright © 2016 zohocrm. All rights reserved.
//

public class ZCRMModuleRelation : ZCRMEntity
{
	public internal( set ) var apiName : String = APIConstants.STRING_MOCK
	var parentModuleAPIName : String = APIConstants.STRING_MOCK
	public internal( set ) var label : String = APIConstants.STRING_MOCK
	public internal( set ) var id : Int64 = APIConstants.INT64_MOCK
	public internal( set ) var isVisible : Bool = APIConstants.BOOL_MOCK
	public internal( set ) var isDefault : Bool = APIConstants.BOOL_MOCK
    public internal( set ) var name : String = APIConstants.STRING_MOCK
    public internal( set ) var type : String = APIConstants.STRING_MOCK
    public internal( set ) var module : String?
    public internal( set ) var action : String?
    public internal( set ) var sequenceNo : Int = APIConstants.INT_MOCK
    public internal( set ) var href : String?

    
    /// Initialize the instance of a ZCRMModuleRelation with the given module and related list
    ///
    /// - Parameters:
    ///   - relatedListAPIName: relatedListAPIName whose instance to be initialized
    ///   - parentModuleAPIName: parentModuleAPIName to get that module's relation
    internal init( relatedListAPIName : String, parentModuleAPIName : String )
    {
        self.apiName = relatedListAPIName
        self.parentModuleAPIName = parentModuleAPIName
    }
    
    internal init( parentModuleAPIName : String, relatedListId : Int64 )
    {
        self.parentModuleAPIName = parentModuleAPIName
        self.id = relatedListId
    }
    
    public func getJunctionRecord( recordId : Int64 ) -> ZCRMJunctionRecord
    {
        return ZCRMJunctionRecord( apiName : apiName, id : recordId )
    }
	
    /// Return list of related records of the module(BulkAPIResponse).
    ///
    /// - Parameter ofParentRecord: list of records of the module
    /// - Returns: list of related records of the module
    /// - Throws: ZCRMSDKError if falied to get related records
    @available(*, deprecated, message: "Use the method 'getRelatedRecords' with param 'recordParams'" )
    public func getRelatedRecords(ofParentRecord: ZCRMRecordDelegate, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> ())
	{
        do
        {
            try relatedModuleCheck(module: self.apiName)
            RelatedListAPIHandler(parentRecord: ofParentRecord, relatedList: self).getRecords(page: nil, per_page: nil, sortByField: nil, sortOrder: nil, modifiedSince: nil) { ( result ) in
                completion( result )
            }
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
        }
    }
    
    public func getRelatedRecords( ofParentRecord : ZCRMRecordDelegate, recordParams : ZCRMQuery.GetRecordParams, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> ())
	{
        do
        {
            try relatedModuleCheck( module : self.apiName )
            RelatedListAPIHandler( parentRecord : ofParentRecord, relatedList : self ).getRecords( recordParams : recordParams ) { ( result ) in
                completion( result )
            }
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
        }
	}
    
    @available(*, deprecated, message: "Use the method 'getRelatedRecords' with param 'recordParams'" )
    public func getRelatedRecords(ofParentRecord: ZCRMRecordDelegate, modifiedSince : String, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> ())
    {
        do
        {
            try relatedModuleCheck(module: self.apiName)
            RelatedListAPIHandler(parentRecord: ofParentRecord, relatedList: self).getRecords(page: nil, per_page: nil, sortByField: nil, sortOrder: nil, modifiedSince: modifiedSince) { ( result ) in
                completion( result )
            }
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
        }
    }
    
    /// Returns list of all records of the module of a requested page number with records of per_page count, before returning the list of records gets sorted with the given field and sort order(BulkAPIResponse).
    ///
    /// - Parameters:
    ///   - ofParentRecord: list of records of the module
    ///   - page: page number of the module
    ///   - per_page: number of records to be given for a single page.
    ///   - sortByField: field by which the module get sorted
    ///   - sortOrder: sort order (asc, desc)
    ///   - modifiedSince: modified time
    /// - Returns: sorted list of module of the ZCRMRecord of a requested page number with records of per_page count
    /// - Throws: ZCRMSDKError if falied to get related records
    @available(*, deprecated, message: "Use the method 'getRelatedRecords' with param 'recordParams'" )
    public func getRelatedRecords(ofParentRecord: ZCRMRecordDelegate, page: Int, per_page: Int, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> ())
    {
        do
        {
            try relatedModuleCheck(module: self.apiName)
            RelatedListAPIHandler(parentRecord: ofParentRecord, relatedList: self).getRecords(page: page, per_page: per_page, sortByField: nil, sortOrder: nil, modifiedSince: nil) { ( result ) in
                completion( result )
            }
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
        }
    }
    
    @available(*, deprecated, message: "Use the method 'getRelatedRecords' with param 'recordParams'" )
    public func getRelatedRecords(ofParentRecord: ZCRMRecordDelegate, page: Int, per_page: Int, modifiedSince: String, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> ())
    {
        do
        {
            try relatedModuleCheck(module: self.apiName)
            RelatedListAPIHandler(parentRecord: ofParentRecord, relatedList: self).getRecords(page: page, per_page: per_page, sortByField: nil, sortOrder: nil, modifiedSince: modifiedSince) { ( result ) in
                completion( result )
            }
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
        }
    }
    
    @available(*, deprecated, message: "Use the method 'getRelatedRecords' with param 'recordParams'" )
    public func getRelatedRecords(ofParentRecord: ZCRMRecordDelegate, sortByField: String, sortOrder: SortOrder, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> ())
    {
        do
        {
            try relatedModuleCheck(module: self.apiName)
            RelatedListAPIHandler(parentRecord: ofParentRecord, relatedList: self).getRecords(page: nil, per_page: nil, sortByField: sortByField, sortOrder: sortOrder, modifiedSince: nil) { ( result ) in
                completion( result )
            }
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
        }
    }
    
    @available(*, deprecated, message: "Use the method 'getRelatedRecords' with param 'recordParams'" )
    public func getRelatedRecords(ofParentRecord: ZCRMRecordDelegate, sortByField: String, sortOrder: SortOrder, modifiedSince: String, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> ())
    {
        do
        {
            try relatedModuleCheck(module: self.apiName)
            RelatedListAPIHandler(parentRecord: ofParentRecord, relatedList: self).getRecords(page: nil, per_page: nil, sortByField: sortByField, sortOrder: sortOrder, modifiedSince: modifiedSince) { ( result ) in
                completion( result )
            }
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
        }
    }
    
    @available(*, deprecated, message: "Use the method 'getRelatedRecords' with param 'recordParams'" )
    public func getRelatedRecords(ofParentRecord: ZCRMRecordDelegate, page: Int, per_page: Int, sortByField: String, sortOrder: SortOrder, modifiedSince: String, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> ())
	{
        do
        {
            try relatedModuleCheck(module: self.apiName)
            RelatedListAPIHandler(parentRecord: ofParentRecord, relatedList: self).getRecords(page: page, per_page: per_page, sortByField: sortByField, sortOrder: sortOrder, modifiedSince: modifiedSince) { ( result ) in
                completion( result )
            }
        }
        catch
        {
            completion( .failure( typeCastToZCRMError( error ) ) )
        }
	}
}

extension ZCRMModuleRelation : Equatable
{
    public static func == (lhs: ZCRMModuleRelation, rhs: ZCRMModuleRelation) -> Bool {
        let equals : Bool = lhs.apiName == rhs.apiName &&
            lhs.parentModuleAPIName == rhs.parentModuleAPIName &&
            lhs.label == rhs.label &&
            lhs.id == rhs.id &&
            lhs.isVisible == rhs.isVisible &&
            lhs.name == rhs.name &&
            lhs.type == rhs.type &&
            lhs.module == rhs.module &&
            lhs.action == rhs.action &&
            lhs.href == rhs.href &&
            lhs.sequenceNo == rhs.sequenceNo
        return equals
    }
}
