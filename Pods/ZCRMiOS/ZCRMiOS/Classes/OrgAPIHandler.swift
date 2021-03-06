//
//  OrgAPIHandler.swift
//  ZCRMiOS
//
//  Created by Boopathy P on 30/08/17.
//  Copyright © 2017 zohocrm. All rights reserved.
//

import Foundation

internal class OrgAPIHandler : CommonAPIHandler
{
    private let cache : CacheFlavour
    internal var variable : ZCRMVariable?
    
    internal init( cacheFlavour : CacheFlavour ) {
        self.cache = cacheFlavour
    }
    
    init( variable : ZCRMVariable ) {
        self.cache = CacheFlavour.NO_CACHE
        self.variable = variable
    }
    
    internal init( variable : ZCRMVariable, cacheFlavour : CacheFlavour ) {
        self.cache = cacheFlavour
        self.variable = variable
    }
    
	override init() {
        self.cache = CacheFlavour.NO_CACHE
	}

    internal func getOrgDetails( completion : @escaping( Result.DataResponse< ZCRMOrg, APIResponse > ) -> () )
    {
        setJSONRootKey( key : JSONRootKey.ORG )
		setUrlPath(urlPath:  "org" )
		setRequestMethod(requestMethod: .GET)
        let request : APIRequest = APIRequest(handler: self )
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getAPIResponse { ( resultType ) in
            do{
                let response = try resultType.resolve()
                let responseJSON : [ String :  Any ] = response.responseJSON
                let orgArray = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                let org = try self.getZCRMOrg( orgDetails : orgArray[ 0 ] )
                response.setData( data : org )
                completion( .success( org, response ) )
            }
            catch{
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func createVariables( variables : [ZCRMVariable], completion : @escaping( Result.DataResponse< [ZCRMVariable], BulkAPIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        var reqBodyObj : [String:[[String:Any?]]] = [String:[[String:Any?]]]()
        var dataArray : [[String:Any?]] = [[String:Any?]]()
        for variable in variables
        {
            if variable.isCreate
            {
                dataArray.append( getZCRMVariableAsJSON( variable: variable ) )
            }
        }
        reqBodyObj[getJSONRootKey()] = dataArray
        
        setUrlPath(urlPath: "settings/variables")
        setRequestMethod(requestMethod: .POST)
        setRequestBody(requestBody: reqBodyObj)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let bulkResponse = try resultType.resolve()
                let responses : [EntityResponse] = bulkResponse.getEntityResponses()
                var createdVariables : [ZCRMVariable] = variables
                for index in 0..<responses.count
                {
                    let entityResponse = responses[ index ]
                    if  APIConstants.CODE_SUCCESS == entityResponse.getStatus()
                    {
                        let entResponseJSON : [String:Any] = entityResponse.getResponseJSON()
                        let variableJSON : [ String : Any ] = try entResponseJSON.getDictionary( key : APIConstants.DETAILS )
                        if variableJSON.isEmpty == true
                        {
                            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.RESPONSE_NIL) : \(ErrorMessage.RESPONSE_JSON_NIL_MSG)")
                            completion( .failure( ZCRMError.ProcessingError( code: ErrorCode.RESPONSE_NIL, message: ErrorMessage.RESPONSE_JSON_NIL_MSG, details : nil ) ) )
                            return
                        }
                        createdVariables[ index ] = try self.getZCRMVariable(variable: createdVariables[ index ], variableJSON: variableJSON)
                        entityResponse.setData(data: createdVariables[ index ])
                    }
                    else
                    {
                        entityResponse.setData(data: nil)
                    }
                }
                bulkResponse.setData(data: createdVariables)
                completion( .success( createdVariables, bulkResponse ) )
            }
            catch{
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func createVariable( completion : @escaping( Result.DataResponse< ZCRMVariable, APIResponse > ) -> () )
    {
        if let variable = self.variable
        {
            if !variable.isCreate
            {
                ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.INVALID_DATA) : VARIABLE ID must be nil")
                completion( .failure( ZCRMError.ProcessingError( code: ErrorCode.INVALID_DATA, message: "VARIABLE ID must be nil", details : nil ) ) )
                return
            }
            setJSONRootKey(key: JSONRootKey.VARIABLES)
            var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
            var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
            dataArray.append( getZCRMVariableAsJSON( variable: variable ) )
            reqBodyObj[getJSONRootKey()] = dataArray
            
            setUrlPath(urlPath: "settings/variables")
            setRequestMethod(requestMethod: .POST)
            setRequestBody(requestBody: reqBodyObj)
            let request : APIRequest = APIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getAPIResponse { ( resultType ) in
                do{
                    let response = try resultType.resolve()
                    let responseJSON = response.getResponseJSON()
                    let respDataArr : [ [ String : Any? ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    let respData : [String:Any?] = respDataArr[0]
                    let variableJSON : [ String : Any ] = try respData.getDictionary( key : APIConstants.DETAILS )
                    let createdVariable : ZCRMVariable = try self.getZCRMVariable(variable: variable, variableJSON: variableJSON)
                    response.setData(data: createdVariable )
                    completion( .success( createdVariable, response ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : VARIABLE must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code: ErrorCode.MANDATORY_NOT_FOUND, message: "VARIABLE must not be nil", details : nil ) ) )
        }
    }
    
    internal func updateVariables( variables : [ZCRMVariable], completion : @escaping( Result.DataResponse< [ZCRMVariable], BulkAPIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
        var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
        for variable in variables
        {
             if !variable.isCreate
            {
                dataArray.append( getZCRMVariableAsJSON( variable: variable ) )
            }
        }
        reqBodyObj[getJSONRootKey()] = dataArray
        
        setUrlPath(urlPath: "settings/variables")
        setRequestMethod(requestMethod: .PUT)
        setRequestBody(requestBody: reqBodyObj)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let bulkResponse = try resultType.resolve()
                let responses : [EntityResponse] = bulkResponse.getEntityResponses()
                var createdVariables : [ZCRMVariable] = variables
                for index in 0..<responses.count
                {
                    let entityResponse = responses[ index ]
                    if  APIConstants.CODE_SUCCESS == entityResponse.getStatus()
                    {
                        let entResponseJSON : [String:Any] = entityResponse.getResponseJSON()
                        let variableJSON : [ String : Any ] = try entResponseJSON.getDictionary( key : APIConstants.DETAILS )
                        if variableJSON.isEmpty == true
                        {
                            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.RESPONSE_NIL) : \(ErrorMessage.RESPONSE_JSON_NIL_MSG)")
                            completion( .failure( ZCRMError.ProcessingError( code: ErrorCode.RESPONSE_NIL, message: ErrorMessage.RESPONSE_JSON_NIL_MSG, details : nil ) ) )
                            return
                        }
                        createdVariables[ index ] = try self.getZCRMVariable(variable: createdVariables[ index ], variableJSON: variableJSON)
                        entityResponse.setData(data: createdVariables[ index ])
                    }
                    else
                    {
                        entityResponse.setData(data: nil)
                    }
                }
                bulkResponse.setData(data: createdVariables)
                completion( .success( createdVariables, bulkResponse ) )
            }
            catch{
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func updateVariable( completion : @escaping( Result.DataResponse< ZCRMVariable, APIResponse > ) -> () )
    {
        if let variable = self.variable
        {
            if variable.isCreate
            {
                ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.INVALID_DATA) : VARIABLE ID must not be nil")
                completion( .failure( ZCRMError.ProcessingError( code: ErrorCode.MANDATORY_NOT_FOUND, message: "VARIABLE ID must not be nil", details : nil ) ) )
                return
            }
            setJSONRootKey(key: JSONRootKey.VARIABLES)
            var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
            var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
            dataArray.append( getZCRMVariableAsJSON( variable: variable ) )
            reqBodyObj[getJSONRootKey()] = dataArray
            
            setUrlPath(urlPath: "settings/variables")
            setRequestMethod(requestMethod: .PUT)
            setRequestBody(requestBody: reqBodyObj)
            let request : APIRequest = APIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getAPIResponse { ( resultType ) in
                do{
                    let response = try resultType.resolve()
                    let responseJSON = response.getResponseJSON()
                    let respDataArr : [ [ String : Any? ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    let respData : [String:Any?] = respDataArr[0]
                    let variableJSON : [ String : Any ] = try respData.getDictionary( key : APIConstants.DETAILS )
                    let updatedVariable : ZCRMVariable = try self.getZCRMVariable(variable: variable, variableJSON: variableJSON)
                    response.setData(data: updatedVariable )
                    completion( .success( updatedVariable, response ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : VARIABLE must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code: ErrorCode.MANDATORY_NOT_FOUND, message: "VARIABLE must not be nil", details : nil ) ) )
        }
    }
    
    internal func getVariableGroups( completion : @escaping( Result.DataResponse< [ZCRMVariableGroup], BulkAPIResponse > ) -> () )
    {
        var variableGroups : [ZCRMVariableGroup] = [ZCRMVariableGroup]()
        setJSONRootKey(key: JSONRootKey.VARIABLE_GROUPS)
        setUrlPath(urlPath: "settings/variable_groups")
        setRequestMethod(requestMethod: .GET)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let bulkResponse = try resultType.resolve()
                let responseJSON = bulkResponse.getResponseJSON()
                if responseJSON.isEmpty == false
                {
                    let variableGroupsList :[ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    if( variableGroupsList.isEmpty == true )
                    {
                        ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.RESPONSE_NIL) : \(ErrorMessage.RESPONSE_JSON_NIL_MSG)")
                        completion( .failure( ZCRMError.SDKError( code: ErrorCode.RESPONSE_NIL, message: ErrorMessage.RESPONSE_JSON_NIL_MSG, details : nil ) ) )
                        return
                    }
                    for variableGroupList in variableGroupsList
                    {
                        variableGroups.append(try self.getZCRMVariableGroup(variableGroupJSON: variableGroupList))
                    }
                }
                bulkResponse.setData(data: variableGroups)
                completion( .success( variableGroups, bulkResponse ) )
            }
            catch{
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getVariableGroup( id : Int64?, apiName : String?, completion : @escaping( Result.DataResponse< ZCRMVariableGroup, APIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLE_GROUPS)
        if let id = id
        {
            setUrlPath(urlPath: "settings/variable_groups/\(String(id))")
        }
        else if let apiName = apiName
        {
            setUrlPath(urlPath: "settings/variable_groups/\(apiName)")
        }
        setRequestMethod(requestMethod: .GET)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getAPIResponse { ( resultType ) in
            do
            {
                let response = try resultType.resolve()
                let responseJSON : [String:Any] = response.getResponseJSON()
                let responseDataArray : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                let variableGroup : ZCRMVariableGroup = try self.getZCRMVariableGroup(variableGroupJSON: responseDataArray[0])
                response.setData(data: variableGroup)
                completion( .success( variableGroup, response ))
            }
            catch
            {
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getVariables( completion : @escaping( Result.DataResponse< [ZCRMVariable], BulkAPIResponse > ) -> () )
    {
        var variables : [ZCRMVariable] = [ZCRMVariable]()
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        setUrlPath(urlPath: "settings/variables")
        setRequestMethod(requestMethod: .GET)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let bulkResponse = try resultType.resolve()
                let responseJSON = bulkResponse.getResponseJSON()
                if responseJSON.isEmpty == false
                {
                    let variablesList : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    if( variablesList.isEmpty == true )
                    {
                        ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.RESPONSE_NIL) : \(ErrorMessage.RESPONSE_JSON_NIL_MSG)")
                        completion( .failure( ZCRMError.SDKError( code: ErrorCode.RESPONSE_NIL, message: ErrorMessage.RESPONSE_JSON_NIL_MSG, details : nil ) ) )
                        return
                    }
                    for variableList in variablesList
                    {
                        let variable : ZCRMVariable = ZCRMVariable( id : try variableList.getInt64( key : ResponseJSONKeys.id ) )
                        variables.append(try self.getZCRMVariable(variable: variable, variableJSON: variableList))
                    }
                }
                bulkResponse.setData(data: variables)
                completion( .success( variables, bulkResponse ) )
            }
            catch{
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getVariable( variableId : Int64?, variableAPIName : String?, variableGroupId : Int64?, variableGroupAPIName : String?, completion : @escaping( Result.DataResponse< ZCRMVariable, APIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        if let variableId = variableId
        {
            setUrlPath(urlPath: "settings/variables/\(String(variableId))")
        }
        else if let variableAPIName = variableAPIName
        {
            setUrlPath(urlPath: "settings/variables/\(variableAPIName)")
        }
        if let variableGroupId = variableGroupId
        {
            addRequestParam( param : RequestParamKeys.group, value : String( variableGroupId ) )
        }
        else if let variableGroupAPIName = variableGroupAPIName
        {
            addRequestParam( param : RequestParamKeys.group, value : variableGroupAPIName )
        }
        setRequestMethod(requestMethod : .GET)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getAPIResponse { ( resultType ) in
            do
            {
                let response = try resultType.resolve()
                let responseJSON : [String:Any] = response.getResponseJSON()
                let responseDataArray : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                var variable : ZCRMVariable = ZCRMVariable( id : try responseDataArray[ 0 ].getInt64( key : ResponseJSONKeys.id ) )
                variable = try self.getZCRMVariable(variable: variable, variableJSON: responseDataArray[0])
                response.setData(data: variable)
                completion( .success( variable, response ))
            }
            catch
            {
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }

    internal func deleteVariables( ids : [Int64], completion : @escaping( Result.Response< BulkAPIResponse > ) -> () )
    {
        setUrlPath(urlPath: "settings/variables")
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        setRequestMethod(requestMethod: .DELETE)
        var idString : String = String()
        for index in 0..<ids.count
        {
            idString.append(String(ids[index]))
            if ( index != ( ids.count - 1 ) )
            {
                idString.append(",")
            }
        }
        addRequestParam( param : RequestParamKeys.ids, value : idString )
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do{
                let response = try resultType.resolve()
                completion( .success( response ) )
            }
            catch{
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func deleteVariable( id : Int64, completion : @escaping( Result.Response< APIResponse > ) -> () )
    {
        setJSONRootKey(key: JSONRootKey.VARIABLES)
        setUrlPath(urlPath: "settings/variables/\(String(id))")
        setRequestMethod(requestMethod: .DELETE)
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getAPIResponse { ( resultType ) in
            do{
                let response = try resultType.resolve()
                completion( .success( response ) )
            }
            catch{
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getCurrencies( completion : @escaping( Result.DataResponse< [ ZCRMCurrency ], BulkAPIResponse > ) -> () )
    {
        setIsCacheable( true )
        setJSONRootKey( key : JSONRootKey.CURRENCIES )
        setUrlPath( urlPath : "org/currencies" )
        setRequestMethod( requestMethod : .GET )
        let request : APIRequest = APIRequest( handler : self, cacheFlavour : self.cache )
        ZCRMLogger.logDebug( message : "Request : \( request.toString() )" )
        
        request.getBulkAPIResponse { ( resultType ) in
            do
            {
                let bulkResponse = try resultType.resolve()
                let responseJSON = bulkResponse.getResponseJSON()
                var currencies : [ ZCRMCurrency ] = [ ZCRMCurrency ]()
                if responseJSON.isEmpty == false
                {
                    let currenciesList : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    if currenciesList.isEmpty == true
                    {
                        ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( ErrorCode.RESPONSE_NIL ) : \( ErrorMessage.RESPONSE_JSON_NIL_MSG )" )
                        completion( .failure( ZCRMError.SDKError( code : ErrorCode.RESPONSE_NIL, message : ErrorMessage.RESPONSE_JSON_NIL_MSG, details : nil ) ) )
                        return
                    }
                    currencies = try self.getAllZCRMCurrencies( currenciesDetails : currenciesList )
                }
                bulkResponse.setData( data : currencies )
                completion( .success( currencies, bulkResponse ) )
            }
            catch
            {
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    internal func getBaseCurrency( completion : @escaping( Result.Data< ZCRMCurrency > ) -> () )
    {
        self.getCurrencies { ( result ) in
            do
            {
                let resp = try result.resolve()
                let currencies = resp.data
                var baseCurrency : ZCRMCurrency?
                for currency in currencies
                {
                    if currency.isBase
                    {
                        baseCurrency = currency
                    }
                }
                if let baseCurrency = baseCurrency
                {
                    completion( .success( baseCurrency ) )
                }
                else
                {
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( ErrorCode.INVALID_DATA ) : BASE CURRENCY not found" )
                    completion( .failure( ZCRMError.InValidError( code : ErrorCode.INVALID_DATA, message : "BASE CURRENCY not found", details : nil) ) )
                }
            }
            catch
            {
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    // check optional property in organisation API
    private func getZCRMOrg( orgDetails : [ String : Any ] ) throws -> ZCRMOrg
    {
        let org : ZCRMOrg = ZCRMOrg()
        org.id = try orgDetails.getInt64( key : ResponseJSONKeys.id )
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.fax ) )
        {
            org.fax = try orgDetails.getString( key : ResponseJSONKeys.fax )
        }
        org.name = try orgDetails.getString( key : ResponseJSONKeys.companyName )
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.alias ) )
        {
            org.alias = try orgDetails.getString( key : ResponseJSONKeys.alias)
        }
        org.primaryZUID = try orgDetails.getInt64( key : ResponseJSONKeys.primaryZUID )
        org.zgid = try orgDetails.getInt64( key : ResponseJSONKeys.ZGID )
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.phone ) )
        {
            org.phone = try orgDetails.getString( key : ResponseJSONKeys.phone )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.mobile ) )
        {
            org.mobile = try orgDetails.getString( key : ResponseJSONKeys.mobile )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.website ) )
        {
            org.website = try orgDetails.getString( key : ResponseJSONKeys.website )
        }
        org.primaryEmail = try orgDetails.getString( key : ResponseJSONKeys.primaryEmail )
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.employeeCount ) )
        {
            org.employeeCount = try orgDetails.getString( key : ResponseJSONKeys.employeeCount )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.description ) )
        {
            org.description = try orgDetails.getString( key : ResponseJSONKeys.description )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.timeZone ) )
        {
            org.timeZone = try orgDetails.getString( key : ResponseJSONKeys.timeZone )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.ISOCode ) )
        {
            org.isoCode = try orgDetails.getString( key : ResponseJSONKeys.ISOCode )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.currencyLocale ) )
        {
            org.currencyLocale = try orgDetails.getString( key : ResponseJSONKeys.currencyLocale )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.currencySymbol ) )
        {
            org.currencySymbol = try orgDetails.getString( key : ResponseJSONKeys.currencySymbol )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.street ) )
        {
            org.street = try orgDetails.getString( key : ResponseJSONKeys.street )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.city ) )
        {
            org.city = try orgDetails.getString( key : ResponseJSONKeys.city )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.state ) )
        {
            org.state = try orgDetails.getString( key : ResponseJSONKeys.state )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.country ) )
        {
            org.country = try orgDetails.getString( key : ResponseJSONKeys.country )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.countryCode ) )
        {
            org.countryCode = try orgDetails.getString( key : ResponseJSONKeys.countryCode )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.zip ) )
        {
            org.zipcode = try orgDetails.getString( key : ResponseJSONKeys.zip )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.mcStatus ) )
        {
            org.mcStatus = try orgDetails.getBoolean( key : ResponseJSONKeys.mcStatus )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.gappsEnabled ) )
        {
            org.isGappsEnabled = try orgDetails.getBoolean( key : ResponseJSONKeys.gappsEnabled )
        }
        if( orgDetails.hasValue( forKey : ResponseJSONKeys.privacySettings ) )
        {
            org.isPrivacySettingsEnable = try orgDetails.getBoolean( key : ResponseJSONKeys.privacySettings )
        }
        if orgDetails.hasValue( forKey : ResponseJSONKeys.photoId )
        {
            org.logoId = try orgDetails.getString( key : ResponseJSONKeys.photoId )
        }
        if orgDetails.hasValue( forKey : ResponseJSONKeys.currency )
        {
            org.currency = try orgDetails.getString( key : ResponseJSONKeys.currency )
        }
        if orgDetails.hasValue(forKey: ResponseJSONKeys.licenseDetails)
        {
            let licenseDetails = try orgDetails.getDictionary(key: ResponseJSONKeys.licenseDetails)
            var license = ZCRMOrg.LicenseDetails( licensePlan : try licenseDetails.getString( key : ResponseJSONKeys.paidType ) )
            license.isPaid = try licenseDetails.getBoolean( key : ResponseJSONKeys.paid )
            if licenseDetails.hasValue(forKey: ResponseJSONKeys.paidExpiry)
            {
                license.expiryDate = try licenseDetails.getString(key: ResponseJSONKeys.paidExpiry)
            }
            if licenseDetails.hasValue(forKey: ResponseJSONKeys.trialExpiry)
            {
                license.expiryDate = try licenseDetails.getString(key: ResponseJSONKeys.trialExpiry)
            }
            license.noOfUsersPurchased = try licenseDetails.getInt( key : ResponseJSONKeys.usersLicensePurchased )
            license.trialType = licenseDetails.optString( key : ResponseJSONKeys.trialType )
            license.trialAction = licenseDetails.optString( key : ResponseJSONKeys.trialAction )
            org.licenseDetails = license
        }
        return org
    }
    
    private func getZCRMVariableAsJSON( variable : ZCRMVariable ) -> [ String : Any? ]
    {
        var variableJSON : [ String : Any? ] = [ String : Any? ]()
        variableJSON.updateValue( variable.name, forKey : ResponseJSONKeys.name )
        variableJSON.updateValue( variable.apiName, forKey : ResponseJSONKeys.apiName )
        if variable.variableGroup.isApiNameSet || variable.variableGroup.isNameSet
        {
            variableJSON.updateValue( getZCRMVariableGroupAsJSON( variableGroup : variable.variableGroup ), forKey : ResponseJSONKeys.variableGroup )
        }
        variableJSON.updateValue( variable.type, forKey : ResponseJSONKeys.type )
        if !variable.isCreate
        {
            variableJSON.updateValue( variable.id, forKey : ResponseJSONKeys.id )
        }
        variableJSON.updateValue( variable.description, forKey : ResponseJSONKeys.description )
        variableJSON.updateValue( variable.value, forKey : ResponseJSONKeys.value )
        return variableJSON
    }
    
    private func getZCRMVariableGroupAsJSON( variableGroup : ZCRMVariableGroup ) -> [ String : Any? ]
    {
        var variableGroupJSON : [ String : Any? ] = [ String : Any? ]()
        if variableGroup.isNameSet
        {
            variableGroupJSON.updateValue( variableGroup.name, forKey : ResponseJSONKeys.name )
        }
        if variableGroup.isApiNameSet
        {
            variableGroupJSON.updateValue( variableGroup.apiName, forKey : ResponseJSONKeys.apiName )
        }
        variableGroupJSON.updateValue( variableGroup.description, forKey : ResponseJSONKeys.description )
         return variableGroupJSON
    }
    
    private func getZCRMVariable( variable : ZCRMVariable, variableJSON : [String:Any] ) throws -> ZCRMVariable
    {
        if variableJSON.hasValue(forKey: ResponseJSONKeys.id)
        {
            variable.id = try variableJSON.getInt64( key : ResponseJSONKeys.id )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.name)
        {
            variable.name = try variableJSON.getString( key : ResponseJSONKeys.name )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.apiName)
        {
            variable.apiName = try variableJSON.getString( key : ResponseJSONKeys.apiName )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.type)
        {
            variable.type = try variableJSON.getString( key : ResponseJSONKeys.type )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.variableGroup)
        {
            variable.variableGroup = try self.getZCRMVariableGroup( variableGroupJSON : try variableJSON.getDictionary( key : ResponseJSONKeys.variableGroup ) )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.description)
        {
            variable.description = try variableJSON.getString( key : ResponseJSONKeys.description )
        }
        if variableJSON.hasValue(forKey: ResponseJSONKeys.value)
        {
            variable.value = try variableJSON.getString( key : ResponseJSONKeys.value )
        }
        variable.isCreate = false
        return variable
    }
    
    private func getZCRMVariableGroup( variableGroupJSON : [String:Any] ) throws -> ZCRMVariableGroup
    {
        let variableGroup : ZCRMVariableGroup = ZCRMVariableGroup( apiName : try variableGroupJSON.getString( key : ResponseJSONKeys.apiName ), id : try variableGroupJSON.getInt64( key : ResponseJSONKeys.id ) )
        if variableGroupJSON.hasValue(forKey: ResponseJSONKeys.name)
        {
            variableGroup.name = try variableGroupJSON.getString( key : ResponseJSONKeys.name )
        }
        if variableGroupJSON.hasValue(forKey: ResponseJSONKeys.description)
        {
            variableGroup.description = try variableGroupJSON.getString( key : ResponseJSONKeys.description )
        }
        if variableGroupJSON.hasValue(forKey: ResponseJSONKeys.displayLabel)
        {
            variableGroup.displayLabel = try variableGroupJSON.getString( key : ResponseJSONKeys.displayLabel )
        }
        return variableGroup
    }
    
    private func getAllZCRMCurrencies( currenciesDetails : [ [ String : Any ] ] ) throws -> [ ZCRMCurrency ]
    {
        var currencies = [ ZCRMCurrency ]()
        for currencyDetails in currenciesDetails
        {
            let currency = try self.getZCRMCurrency( currencyDetails : currencyDetails )
            currencies.append( currency )
        }
        return currencies
    }
    
    private func getZCRMCurrency( currencyDetails : [ String : Any ] ) throws -> ZCRMCurrency
    {
        let currency = try ZCRMCurrency( name : currencyDetails.getString( key : ResponseJSONKeys.name ), symbol : currencyDetails.getString( key : ResponseJSONKeys.symbol ), isoCode : currencyDetails.getString( key : ResponseJSONKeys.ISOCode ) )
        currency.createdTime = currencyDetails.optString( key : ResponseJSONKeys.createdTime )
        currency.isActive = currencyDetails.optBoolean( key : ResponseJSONKeys.isActive )
        if currencyDetails.hasValue( forKey : ResponseJSONKeys.exchangeRate )
        {
            currency.exchangeRate = try Double( currencyDetails.getString( key : ResponseJSONKeys.exchangeRate )  )
        }
        if currencyDetails.hasValue( forKey : ResponseJSONKeys.createdBy )
        {
            currency.createdBy = try getUserDelegate( userJSON : currencyDetails.getDictionary( key : ResponseJSONKeys.createdBy ) )
        }
        currency.prefixSymbol = currencyDetails.optBoolean( key : ResponseJSONKeys.prefixSymbol )
        currency.isBase = try currencyDetails.getBoolean( key : ResponseJSONKeys.isBase )
        currency.modifiedTime = try currencyDetails.getString( key : ResponseJSONKeys.modifiedTime )
        if currencyDetails.hasValue( forKey : ResponseJSONKeys.modifiedBy )
        {
            currency.modifiedBy = try getUserDelegate( userJSON : currencyDetails.getDictionary( key : ResponseJSONKeys.modifiedBy ) )
        }
        currency.id = try currencyDetails.getInt64( key : ResponseJSONKeys.id )
        if currencyDetails.hasValue( forKey : ResponseJSONKeys.format )
        {
            let formatDetails : [ String : Any ] = try currencyDetails.getDictionary( key : ResponseJSONKeys.format )
            if let decimalPlaces = Int( try formatDetails.getString( key : ResponseJSONKeys.decimalPlaces  ) )
            {
                currency.format = try ZCRMCurrency.Format( decimalSeparator : formatDetails.getString( key : ResponseJSONKeys.decimalSeparator ), thousandSeparator : formatDetails.getString( key : ResponseJSONKeys.thousandSeparator ), decimalPlaces : decimalPlaces )
            }
        }
        return currency
    }
}

fileprivate extension OrgAPIHandler
{
    struct ResponseJSONKeys
    {
        static let id = "id"
        static let fax = "fax"
        static let companyName = "company_name"
        static let alias = "alias"
        static let primaryZUID = "primary_zuid"
        static let ZGID = "zgid"
        static let phone = "phone"
        static let mobile = "mobile"
        static let website = "website"
        static let primaryEmail = "primary_email"
        static let employeeCount = "employee_count"
        static let description = "description"
        static let timeZone = "time_zone"
        static let ISOCode = "iso_code"
        static let currencyLocale = "currency_locale"
        static let currencySymbol = "currency_symbol"
        static let street = "street"
        static let city = "city"
        static let state = "state"
        static let country = "country"
        static let countryCode = "country_code"
        static let zip = "zip"
        static let mcStatus = "mc_status"
        static let gappsEnabled = "gapps_enabled"
        static let privacySettings = "privacy_settings"
        
        static let name = "name"
        static let apiName = "api_name"
        static let variableGroup = "variable_group"
        static let type = "type"
        static let value = "value"
        static let displayLabel = "display_label"
        static let defaultString = "default"
        
        static let portalSwitch = "portalswitch"
        static let domainName = "domain_name"
        static let webURL = "web_url"
        static let apiURL = "api_url"
        
        static let paidExpiry = "paid_expiry"
        static let usersLicensePurchased = "users_license_purchased"
        static let trialType = "trial_type"
        static let trialExpiry = "trial_expiry"
        static let paid = "paid"
        static let paidType = "paid_type"
        static let trialAction = "trial_action"
        static let licenseDetails = "license_details"
        
        static let symbol = "symbol"
        static let createdTime = "created_time"
        static let isActive = "is_active"
        static let exchangeRate = "exchange_rate"
        static let format = "format"
        static let decimalSeparator = "decimal_separator"
        static let thousandSeparator = "thousand_separator"
        static let decimalPlaces = "decimal_places"
        static let createdBy = "created_by"
        static let prefixSymbol = "prefix_symbol"
        static let isBase = "is_base"
        static let modifiedTime = "modified_time"
        static let modifiedBy = "modified_by"
        
        static let photoId = "photo_id"
        static let currency = "currency"
    }
}

extension RequestParamKeys
{
    static let group : String = "group"
    static let orgId = "orgid"
}
