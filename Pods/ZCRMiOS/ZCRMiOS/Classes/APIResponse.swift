//
//  APIResponse.swift
//  ZCRMiOS
//
//  Created by Vijayakrishna on 3/7/17.
//  Copyright © 2017 zohocrm. All rights reserved.
//

import Foundation

public class  APIResponse : CommonAPIResponse
{
    internal var data : ZCRMEntity?
    internal var status : String?
    internal var message : String?
    
    override init() {
        super.init()
    }
    
    override init( response : HTTPURLResponse, responseJSONRootKey : String ) throws
    {
        try super.init( response : response, responseJSONRootKey : responseJSONRootKey )
    }
    
    override init( response : HTTPURLResponse, responseData : Data, responseJSONRootKey : String ) throws
    {
        try super.init( response : response, responseData : responseData, responseJSONRootKey : responseJSONRootKey )
    }
    
    override init( responseJSON : Dictionary<String, Any>, responseJSONRootKey : String ) throws {
        try super.init( responseJSON : responseJSON, responseJSONRootKey : responseJSONRootKey )
    }
    
    internal func setData(data : ZCRMEntity)
    {
        self.data = data
    }
    
    public func getData() -> ZCRMEntity?
    {
        return self.data
    }
    
    internal func setStatus( status : String )
    {
        self.status = status
    }
    
    public func getStatus() -> String?
    {
        return self.status
    }
    
    internal func setMessage( message : String )
    {
        self.message = message
    }
    
    public func getMessage() -> String?
    {
        return self.message
    }
    
    override func handleForFaultyResponses() throws
    {
        if(httpStatusCode == HTTPStatusCode.NO_CONTENT)
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.INVALID_DATA) : \(ErrorMessage.INVALID_ID_MSG)")
            throw ZCRMError.InValidError( code : ErrorCode.INVALID_DATA, message : ErrorMessage.INVALID_ID_MSG, details : nil )
        }
        else if httpStatusCode == HTTPStatusCode.FORBIDDEN
        {
            ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA ) : \( responseJSON[ APIConstants.MESSAGE ] as? String ?? ErrorMessage.RESPONSE_NIL_MSG )" )
            throw ZCRMError.UnAuthenticatedError( code : responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA, message : responseJSON[APIConstants.MESSAGE] as? String ?? ErrorMessage.RESPONSE_NIL_MSG, details : responseJSON[ APIConstants.DETAILS ] as? [ String : Any ] ?? nil )
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA) : \(responseJSON[APIConstants.MESSAGE] as? String ?? ErrorMessage.RESPONSE_NIL_MSG)")
            throw ZCRMError.ProcessingError( code : responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA, message : responseJSON[APIConstants.MESSAGE] as? String ?? ErrorMessage.RESPONSE_NIL_MSG, details : responseJSON[ APIConstants.DETAILS ] as? [ String : Any ] ?? nil )
        }
    }
    
    override func processDataResponse() throws
    {
        var msgJSON : [ String : Any ] = responseJSON
        if responseJSON.hasValue( forKey : responseJSONRootKey ),
            let recordsArray : [ [ String : Any ] ] = responseJSON[responseJSONRootKey] as? [ [ String : Any ] ]
        {
            msgJSON = recordsArray[ 0 ]
        }
        if ( msgJSON.hasValue( forKey : APIConstants.MESSAGE ) )
        {
            message = msgJSON[ APIConstants.MESSAGE ] as? String
        }
        if( msgJSON.hasValue( forKey : APIConstants.STATUS ) )
        {
            status = msgJSON[ APIConstants.STATUS ] as? String
            if( status == APIConstants.CODE_ERROR )
            {
                if( msgJSON.hasValue( forKey : APIConstants.DETAILS ) )
                {
                    ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(msgJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA) : \(message ?? "Empty Message")")
                    throw ZCRMError.ProcessingError( code :( msgJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA ), message : message ?? "Empty Message" , details :  msgJSON[ APIConstants.DETAILS ] as? [ String : Any ] ?? [ String : Any ]()  )
                }
                ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(msgJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA) : \(message ?? "Empty Message")")
                throw ZCRMError.ProcessingError( code : msgJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA, message: message ?? "Empty Message", details : nil )
            }
        } 
    }
} // end of class

public class FileAPIResponse : APIResponse
{
    private var tempLocalUrl : URL?
    private var fileName: String?
    
    init(response: HTTPURLResponse, tempLocalUrl: URL?) throws
    {
        self.tempLocalUrl = tempLocalUrl
        try super.init( response : response,
                       responseJSONRootKey : JSONRootKey.NIL )
    }
    
    public func getFileName() -> String?
    {
        return fileName
    }
    
    public func getFileData() -> Data?
    {
        guard let url = self.tempLocalUrl else
        {
            return nil
        }
        return try? Data( contentsOf : url )
    }
    
    public func getTempLocalUrl() -> URL?
    {
        return self.tempLocalUrl
    }
    
    public func getTempLocalFilePath() -> String?
    {
        return self.tempLocalUrl?.path
    }
    
    override func setResponseJSON(responseData: Data?) throws
    {
        if(httpStatusCode == HTTPStatusCode.OK || httpStatusCode == HTTPStatusCode.NO_CONTENT)
        {
            responseJSON = [String:Any]()
            if( httpStatusCode == HTTPStatusCode.OK )
            {
                status = APIConstants.CODE_SUCCESS
            }
        }
        else
        {
            if let url = tempLocalUrl
            {
                let respStr = try String(contentsOf: url)
                if let stringData = respStr.data(using: .utf8)
                {
                    let jsonStr : Any? = try? JSONSerialization.jsonObject(with: stringData, options: [])
                    if let tempJSON = jsonStr as? [String : Any]
                    {
                        responseJSON = tempJSON
                    }
                }
            }
            self.tempLocalUrl = nil
        }
    }
    
    override func processDataResponse() throws
    {
    }
    
    override func handleForFaultyResponses() throws {
        if let statusCode = httpStatusCode, !( statusCode == HTTPStatusCode.NO_CONTENT )
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA) : \(responseJSON[APIConstants.MESSAGE] as? String ?? ErrorMessage.RESPONSE_NIL_MSG)")
            throw ZCRMError.ProcessingError( code : responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA, message : responseJSON[APIConstants.MESSAGE] as? String ?? ErrorMessage.RESPONSE_NIL_MSG, details : responseJSON[ APIConstants.DETAILS ] as? [ String : Any ] ?? nil )
        }
        else if httpStatusCode == HTTPStatusCode.FORBIDDEN
        {
            ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA ) : \( responseJSON[ APIConstants.MESSAGE ] as? String ?? ErrorMessage.RESPONSE_NIL_MSG )" )
            throw ZCRMError.UnAuthenticatedError( code : responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA, message : responseJSON[APIConstants.MESSAGE] as? String ?? ErrorMessage.RESPONSE_NIL_MSG, details : responseJSON[ APIConstants.DETAILS ] as? [ String : Any ] ?? nil )
        }
    }
    
}

public class BulkAPIResponse : CommonAPIResponse
{
    private var bulkData : [ZCRMEntity] = [ZCRMEntity]()
    private var bulkEntityResponses : [EntityResponse] = [EntityResponse]()
    
    override init()
    {
        super.init()
    }
    
    override init( response : HTTPURLResponse, responseJSONRootKey : String ) throws
    {
        try super.init( response : response, responseJSONRootKey : responseJSONRootKey )
    }
    
    override init( response : HTTPURLResponse, responseData : Data, responseJSONRootKey : String ) throws
    {
        try super.init( response : response, responseData : responseData, responseJSONRootKey : responseJSONRootKey )
    }
    
    override init( responseJSON : Dictionary<String, Any>, responseJSONRootKey : String ) throws {
        try super.init( responseJSON : responseJSON, responseJSONRootKey : responseJSONRootKey )
    }
    
    public func getEntityResponses() -> [EntityResponse]
    {
        return self.bulkEntityResponses
    }
    
    internal func setData(data: [ZCRMEntity])
    {
        self.bulkData = data
    }
    
    public func getData() -> [ZCRMEntity]
    {
        return self.bulkData
    }
    
    override func processDataResponse() throws
    {
        if(self.responseJSON.hasValue( forKey : responseJSONRootKey ) )
        {
            if let recordsArray : [ [ String : Any ] ] = responseJSON.optArray( key : responseJSONRootKey ) as? [ [ String : Any ] ]
            {
                for recordJSON in recordsArray
                {
                    if( recordJSON.hasValue( forKey : APIConstants.STATUS ) && recordJSON.hasValue( forKey : APIConstants.MESSAGE ) ) && recordJSON.hasValue( forKey : APIConstants.CODE )
                    {
                        let individualResponse : EntityResponse = try EntityResponse( entityResponseJSON : recordJSON )
                        self.bulkEntityResponses.append(individualResponse)
                    }
                }
            }
            else if let recordJSON : [String:Any] = responseJSON.optDictionary(key: responseJSONRootKey)
            {
                for key in recordJSON.keys
                {
                    if let recordsArray : [ [ String : Any ] ] = responseJSON.optArray( key : key ) as? [ [ String : Any ] ]
                    {
                        for recordJSON in recordsArray
                        {
                            if( recordJSON.hasValue( forKey : APIConstants.STATUS ) && recordJSON.hasValue( forKey : APIConstants.MESSAGE ) ) && recordJSON.hasValue( forKey : APIConstants.CODE )
                            {
                                let individualResponse : EntityResponse = try EntityResponse( entityResponseJSON : recordJSON )
                                self.bulkEntityResponses.append(individualResponse)
                            }
                        }
                    }
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.RESPONSE_ROOT_KEY_NIL) : Response root key is nil.")
            throw ZCRMError.ProcessingError( code : ErrorCode.RESPONSE_ROOT_KEY_NIL, message : "Response root key is nil.", details : nil )
        }
    }
    
    override func handleForFaultyResponses() throws
    {
        if(self.httpStatusCode == HTTPStatusCode.NO_CONTENT)
        {
            self.responseJSON = [String:Any]()
        }
        else if httpStatusCode == HTTPStatusCode.FORBIDDEN
        {
            ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA ) : \( responseJSON[ APIConstants.MESSAGE ] as? String ?? ErrorMessage.RESPONSE_NIL_MSG )" )
            throw ZCRMError.UnAuthenticatedError( code : responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA, message : responseJSON[APIConstants.MESSAGE] as? String ?? ErrorMessage.RESPONSE_NIL_MSG, details : responseJSON[ APIConstants.DETAILS ] as? [ String : Any ] ?? nil )
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA) : \(responseJSON[APIConstants.MESSAGE] as? String ?? ErrorMessage.RESPONSE_NIL_MSG)")
            throw ZCRMError.ProcessingError( code : ( responseJSON[ APIConstants.CODE ] as? String ?? ErrorCode.INVALID_DATA ), message : ( responseJSON[APIConstants.MESSAGE] as? String ?? ErrorMessage.RESPONSE_NIL_MSG ), details : responseJSON[ APIConstants.DETAILS ] as? [ String : Any ] ?? nil )
        }
    }
}

public class EntityResponse
{
    private var responseJSON : [String:Any]
    private var status : String
    private var code : String
    private var message : String
    private var data : ZCRMEntity?
    private var upsertedDetails : [ String : String ] = [ String : String ]()
    
    init( entityResponseJSON : [ String : Any ] ) throws
    {
        self.responseJSON = entityResponseJSON
        self.status = try entityResponseJSON.getString( key : APIConstants.STATUS )
        self.code = try entityResponseJSON.getString( key : APIConstants.CODE )
        self.message = try entityResponseJSON.getString( key : APIConstants.MESSAGE )
        if entityResponseJSON.hasValue( forKey : APIConstants.ACTION )
        {
            self.upsertedDetails[ "\( APIConstants.ACTION )" ] = entityResponseJSON[ APIConstants.ACTION ] as? String
            
        }
        if entityResponseJSON.hasValue( forKey : APIConstants.DUPLICATE_FIELD )
        {
            self.upsertedDetails[ "\( APIConstants.DUPLICATE_FIELD )" ] = entityResponseJSON[ APIConstants.DUPLICATE_FIELD ] as? String
        }
    }
    
    internal func setData(data: ZCRMEntity?)
    {
        self.data = data;
    }
    
    public func getData() -> ZCRMEntity?
    {
        return self.data
    }
    
    public func getResponseJSON() -> [String:Any]
    {
        return self.responseJSON
    }
    
    public func getStatus() -> String
    {
        return self.status
    }
    
    public func getCode() -> String
    {
        return self.code
    }
    
    public func getUpsertedDetails() -> [ String : String ]
    {
        return self.upsertedDetails
    }
    
    public func getMessage() -> String
    {
        return self.message
    }
}
