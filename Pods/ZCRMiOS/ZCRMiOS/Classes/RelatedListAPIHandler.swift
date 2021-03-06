//
//  RelatedListAPIHandler.swift
//  ZCRMiOS
//
//  Created by Vijayakrishna on 18/11/16.
//  Copyright © 2016 zohocrm. All rights reserved.
//

internal class RelatedListAPIHandler : CommonAPIHandler
{
	private var parentRecord : ZCRMRecordDelegate
	private var relatedList : ZCRMModuleRelation?
    private var junctionRecord : ZCRMJunctionRecord?
    private var voiceNote : ZCRMNote?
    private var attachmentUploadDelegate : AttachmentUploadDelegate?
    private var voiceNoteUploadDelegate : VoiceNoteUploadDelegate?
    private var noteAttachment : ZCRMNote?
    
    private init( parentRecord : ZCRMRecordDelegate, relatedList : ZCRMModuleRelation?, junctionRecord : ZCRMJunctionRecord?, attachmentUploadDelegate : AttachmentUploadDelegate?, voiceNoteUploadDelegate : VoiceNoteUploadDelegate? )
    {
        self.parentRecord = parentRecord
        self.relatedList = relatedList
        self.junctionRecord = junctionRecord
        self.attachmentUploadDelegate = attachmentUploadDelegate
        self.voiceNoteUploadDelegate = voiceNoteUploadDelegate
    }
	
    init( parentRecord : ZCRMRecordDelegate, relatedList : ZCRMModuleRelation )
    {
        self.parentRecord = parentRecord
        self.relatedList = relatedList
    }
    
    init( parentRecord : ZCRMRecordDelegate, relatedList : ZCRMModuleRelation, attachmentUploadDelegate : AttachmentUploadDelegate )
    {
        self.parentRecord = parentRecord
        self.relatedList = relatedList
        self.attachmentUploadDelegate = attachmentUploadDelegate
    }
    
    init( parentRecord : ZCRMRecordDelegate, relatedList : ZCRMModuleRelation, voiceNoteUploadDelegate : VoiceNoteUploadDelegate )
    {
        self.parentRecord = parentRecord
        self.relatedList = relatedList
        self.voiceNoteUploadDelegate = voiceNoteUploadDelegate
    }
    
    init( parentRecord : ZCRMRecordDelegate, junctionRecord : ZCRMJunctionRecord )
    {
        self.parentRecord = parentRecord
        self.junctionRecord = junctionRecord
    }
    
    init( parentRecord : ZCRMRecordDelegate )
    {
        self.parentRecord = parentRecord
    }

    @available(*, deprecated, message: "Use the method 'getRecords' with param perPage" )
    internal func getRecords(page : Int?, per_page : Int?, sortByField : String?, sortOrder : SortOrder?, modifiedSince : String?, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> () )
	{
        if let relatedList = self.relatedList
        {
            if let moduleName = relatedList.module
            {
                setUrlPath(urlPath:  "\( self.parentRecord.moduleAPIName )/\( String(self.parentRecord.id))/\(relatedList.apiName)" )
                setRequestMethod(requestMethod: .GET )
                if let page = page
                {
                    addRequestParam( param :  RequestParamKeys.page, value : String( page ) )
                }
                if let perPage = per_page
                {
                    addRequestParam( param : RequestParamKeys.perPage, value : String( perPage ) )
                }
                if(sortByField.notNilandEmpty)
                {
                    addRequestParam( param : RequestParamKeys.sortBy, value : sortByField! )
                }
                if let sortOrder = sortOrder
                {
                    addRequestParam( param : RequestParamKeys.sortOrder, value : sortOrder.rawValue )
                }
                if ( modifiedSince.notNilandEmpty )
                {
                    addRequestHeader(header: RequestParamKeys.ifModifiedSince , value : modifiedSince! )
                }
                let request : APIRequest = APIRequest(handler: self)
                ZCRMLogger.logDebug(message: "Request : \(request.toString())")
                var zcrmFields : [ZCRMField]?
                var bulkResponse : BulkAPIResponse?
                var err : Error?
                let dispatchGroup : DispatchGroup = DispatchGroup()
                
                dispatchGroup.enter()
                ModuleAPIHandler(module: ZCRMModuleDelegate(apiName: moduleName), cacheFlavour: .URL_VS_RESPONSE).getAllFields( modifiedSince : nil ) { ( result ) in
                    do
                    {
                        let resp = try result.resolve()
                        zcrmFields = resp.data
                        dispatchGroup.leave()
                    }
                    catch
                    {
                        err = error
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.enter()
                request.getBulkAPIResponse { ( resultType ) in
                    do
                    {
                        let response = try resultType.resolve()
                        bulkResponse = response
                        dispatchGroup.leave()
                    }
                    catch
                    {
                        err = error
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify( queue : OperationQueue.current?.underlyingQueue ?? .global() ) {
                    if let fields = zcrmFields, let response = bulkResponse
                    {
                        MassEntityAPIHandler(module: ZCRMModuleDelegate(apiName: moduleName)).getZCRMRecords(fields: fields, bulkResponse: response, completion: { ( records, error ) in
                            if let err = error
                            {
                                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( err )" )
                                completion( .failure( typeCastToZCRMError( err ) ) )
                                return
                            }
                            if let records = records
                            {
                                response.setData(data: records)
                                completion( .success( records, response ) )
                                return
                            }
                        })
                    }
                    else if let error = err
                    {
                        ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                        completion( .failure( typeCastToZCRMError( error ) ) )
                    }
                    else
                    {
                        ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : FIELDS must not be nil")
                        completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "FIELDS must not be nil", details : nil ) ) )
                    }
                }
            }
            else
            {
                ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.NOT_SUPPORTED) : SDK does not support this module")
                completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.NOT_SUPPORTED, message : "SDK does not support this module", details : nil ) ) )
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
	}
    internal func getRecords( recordParams : ZCRMQuery.GetRecordParams, completion : @escaping( Result.DataResponse< [ ZCRMRecord ], BulkAPIResponse > ) -> () )
    {
        if let relatedList = self.relatedList
        {
            if let moduleName = relatedList.module
            {
                setUrlPath(urlPath:  "\( self.parentRecord.moduleAPIName )/\( String(self.parentRecord.id))/\(relatedList.apiName)" )
                setRequestMethod(requestMethod: .GET )
                if let page = recordParams.page
                {
                    addRequestParam( param :  RequestParamKeys.page, value : String( page ) )
                }
                if let perPage = recordParams.perPage
                {
                    addRequestParam( param : RequestParamKeys.perPage, value : String( perPage ) )
                }
                if recordParams.sortBy.notNilandEmpty
                {
                    addRequestParam( param : RequestParamKeys.sortBy, value : recordParams.sortBy! )
                }
                if let sortOrder = recordParams.sortOrder
                {
                    addRequestParam( param : RequestParamKeys.sortOrder, value : sortOrder.rawValue )
                }
                if ( recordParams.modifiedSince.notNilandEmpty )
                {
                    addRequestHeader( header : RequestParamKeys.ifModifiedSince, value : recordParams.modifiedSince! )
                }
                let request : APIRequest = APIRequest(handler: self)
                ZCRMLogger.logDebug(message: "Request : \(request.toString())")
                var zcrmFields : [ZCRMField]?
                var bulkResponse : BulkAPIResponse?
                var err : Error?
                let dispatchGroup : DispatchGroup = DispatchGroup()
                
                dispatchGroup.enter()
                ModuleAPIHandler(module: ZCRMModuleDelegate(apiName: moduleName), cacheFlavour: .URL_VS_RESPONSE).getAllFields( modifiedSince : nil ) { ( result ) in
                    do
                    {
                        let resp = try result.resolve()
                        zcrmFields = resp.data
                        dispatchGroup.leave()
                    }
                    catch
                    {
                        err = error
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.enter()
                request.getBulkAPIResponse { ( resultType ) in
                    do
                    {
                        let response = try resultType.resolve()
                        bulkResponse = response
                        dispatchGroup.leave()
                    }
                    catch
                    {
                        err = error
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify( queue : OperationQueue.current?.underlyingQueue ?? .global() ) {
                    if let fields = zcrmFields, let response = bulkResponse
                    {
                        MassEntityAPIHandler(module: ZCRMModuleDelegate(apiName: moduleName)).getZCRMRecords(fields: fields, bulkResponse: response, completion: { ( records, error ) in
                            if let err = error
                            {
                                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( err )" )
                                completion( .failure( typeCastToZCRMError( err ) ) )
                                return
                            }
                            if let records = records
                            {
                                response.setData(data: records)
                                completion( .success( records, response ) )
                                return
                            }
                        })
                    }
                    else if let error = err
                    {
                        ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                        completion( .failure( typeCastToZCRMError( error ) ) )
                    }
                    else
                    {
                        ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : FIELDS must not be nil")
                        completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "FIELDS must not be nil", details : nil ) ) )
                    }
                }
            }
            else
            {
                ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.NOT_SUPPORTED) : SDK does not support this module")
                completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.NOT_SUPPORTED, message : "SDK does not support this module", details : nil ) ) )
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
    }

    @available(*, deprecated, message: "Use the method 'getNotes' with param perPage" )
    internal func getNotes( page : Int?, per_page : Int?, sortByField : String?, sortOrder : SortOrder?, modifiedSince : String?, completion : @escaping( Result.DataResponse< [ ZCRMNote ], BulkAPIResponse > ) -> () )
	{
        if let relatedList = self.relatedList
        {
            var notes : [ZCRMNote] = [ZCRMNote]()
            setUrlPath( urlPath :  "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )" )
            setRequestMethod(requestMethod: .GET )
            if let page = page
            {
                addRequestParam( param :  RequestParamKeys.page, value : String( page ) )
            }
            if let perPage = per_page
            {
                addRequestParam( param : RequestParamKeys.perPage, value : String( perPage ) )
            }
            if(sortByField.notNilandEmpty)
            {
                addRequestParam( param : RequestParamKeys.sortBy, value : sortByField! )
            }
            if let sortOrder = sortOrder
            {
                addRequestParam( param : RequestParamKeys.sortOrder, value : sortOrder.rawValue )
            }
            if ( modifiedSince.notNilandEmpty)
            {
                addRequestHeader(header: RequestParamKeys.ifModifiedSince , value : modifiedSince! )
            }
            let request : APIRequest = APIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getBulkAPIResponse { ( resultType ) in
                do{
                    let bulkResponse = try resultType.resolve()
                    let responseJSON = bulkResponse.getResponseJSON()
                    if responseJSON.isEmpty == false
                    {
                        let notesList : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                        if notesList.isEmpty == true
                        {
                            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.RESPONSE_NIL) : \(ErrorMessage.RESPONSE_JSON_NIL_MSG)")
                            completion( .failure( ZCRMError.SDKError( code : ErrorCode.RESPONSE_NIL, message : ErrorMessage.RESPONSE_JSON_NIL_MSG, details : nil ) ) )
                            return
                        }
                        for noteDetails in notesList
                        {
                            if ( noteDetails.hasValue(forKey: ResponseJSONKeys.noteContent))
                            {
                                try notes.append( self.getZCRMNote(noteDetails: noteDetails, note: ZCRMNote(content: noteDetails.getString(key: ResponseJSONKeys.noteContent))))
                            }
                            else
                            {
                                try notes.append( self.getZCRMNote(noteDetails: noteDetails, note: ZCRMNote(content: nil, title: noteDetails.getString(key: ResponseJSONKeys.noteTitle))))
                            }
                        }
                    }
                    bulkResponse.setData(data: notes)
                    completion( .success( notes, bulkResponse ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
	}
    
    internal func getNotes( page : Int?, perPage : Int?, sortByField : String?, sortOrder : SortOrder?, modifiedSince : String?, completion : @escaping( Result.DataResponse< [ ZCRMNote ], BulkAPIResponse > ) -> () )
    {
        if let relatedList = self.relatedList
        {
            var notes : [ ZCRMNote ] = [ ZCRMNote ]()
            setUrlPath( urlPath :  "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )" )
            setRequestMethod( requestMethod : .GET )
            if let page = page
            {
               addRequestParam( param :  RequestParamKeys.page, value : String( page ) )
            }
            if let perPage = perPage
            {
                addRequestParam( param : RequestParamKeys.perPage, value : String( perPage ) )
            }
            if( sortByField.notNilandEmpty )
            {
                addRequestParam( param : RequestParamKeys.sortBy, value : sortByField! )
            }
            if let sortOrder = sortOrder
            {
                addRequestParam( param : RequestParamKeys.sortOrder, value : sortOrder.rawValue )
            }
            if ( modifiedSince.notNilandEmpty )
            {
                addRequestHeader( header : RequestParamKeys.ifModifiedSince , value : modifiedSince! )
            }
            let request : APIRequest = APIRequest( handler : self )
            ZCRMLogger.logDebug( message : "Request : \( request.toString() )" )
            
            request.getBulkAPIResponse { ( resultType ) in
                do{
                    let bulkResponse = try resultType.resolve()
                    let responseJSON = bulkResponse.getResponseJSON()
                    if responseJSON.isEmpty == false
                    {
                        let notesList:[ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                        if notesList.isEmpty == true
                        {
                            ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( ErrorCode.RESPONSE_NIL ) : \( ErrorMessage.RESPONSE_JSON_NIL_MSG )" )
                            completion( .failure( ZCRMError.SDKError( code : ErrorCode.RESPONSE_NIL, message : ErrorMessage.RESPONSE_JSON_NIL_MSG, details : nil ) ) )
                            return
                        }
                        for noteDetails in notesList
                        {
                            if ( noteDetails.hasValue( forKey : ResponseJSONKeys.noteContent ) )
                            {
                                try notes.append( self.getZCRMNote( noteDetails : noteDetails, note : ZCRMNote( content : noteDetails.getString( key : ResponseJSONKeys.noteContent ) ) ) )
                            }
                            else
                            {
                                try notes.append( self.getZCRMNote( noteDetails : noteDetails, note : ZCRMNote( content : nil, title : try noteDetails.getString( key : ResponseJSONKeys.noteTitle ) ) ) )
                            }
                        }
                    }
                    bulkResponse.setData( data : notes )
                    completion( .success( notes, bulkResponse ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( ErrorCode.MANDATORY_NOT_FOUND ) : RELATED LIST must not be nil" )
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
    }
    
    internal func getNote( noteId : Int64, completion : @escaping( Result.DataResponse< ZCRMNote, APIResponse > ) -> () )
    {
        if let relatedList = self.relatedList
        {
            setUrlPath( urlPath :  "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )/\( noteId )" )
            setRequestMethod(requestMethod: .GET)
            let request : APIRequest = APIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getAPIResponse { ( resultType ) in
                do
                {
                    let response = try resultType.resolve()
                    let responseJSON : [String:Any] = response.getResponseJSON()
                    let responseDataArray : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    var note : ZCRMNote
                    if ( responseDataArray[0].hasValue(forKey: ResponseJSONKeys.noteContent))
                    {
                        note = ZCRMNote( content : try responseDataArray[ 0 ].getString( key : ResponseJSONKeys.noteContent ) )
                    }
                    else
                    {
                        note = ZCRMNote( content : nil, title : try responseDataArray[ 0 ].getString( key : ResponseJSONKeys.noteTitle ) )
                    }
                    note = try self.getZCRMNote(noteDetails: responseDataArray[0], note: note)
                    response.setData(data: note)
                    completion( .success( note, response ) )
                }
                catch
                {
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
    }
    
    @available(*, deprecated, message: "Use the method 'getAllAttachmentsDetails' with params perPage" )
    internal func getAllAttachmentsDetails( page : Int?, per_page : Int?, modifiedSince : String?, completion : @escaping( Result.DataResponse< [ ZCRMAttachment ], BulkAPIResponse > ) -> () )
    {
        if let relatedList = self.relatedList
        {
            var attachments : [ZCRMAttachment] = [ZCRMAttachment]()
            setUrlPath( urlPath :  "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )" )
            setRequestMethod(requestMethod: .GET )
            if let page = page
            {
                addRequestParam( param :  RequestParamKeys.page, value : String( page ) )
            }
            if let perPage = per_page
            {
                addRequestParam( param : RequestParamKeys.perPage, value : String( perPage ) )
            }
            if ( modifiedSince.notNilandEmpty)
            {
                addRequestHeader( header : RequestParamKeys.ifModifiedSince , value : modifiedSince! )
            }
            let request : APIRequest = APIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getBulkAPIResponse { ( resultType ) in
                do{
                    let bulkResponse = try resultType.resolve()
                    let responseJSON = bulkResponse.getResponseJSON()
                    if responseJSON.isEmpty == false
                    {
                        let attachmentsList:[ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                        if attachmentsList.isEmpty == true
                        {
                            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.RESPONSE_NIL) : \(ErrorMessage.RESPONSE_JSON_NIL_MSG)")
                            completion( .failure( ZCRMError.SDKError( code : ErrorCode.RESPONSE_NIL, message : ErrorMessage.RESPONSE_JSON_NIL_MSG, details : nil ) ) )
                            return
                        }
                        for attachmentDetails in attachmentsList
                        {
                            try attachments.append(self.getZCRMAttachment(attachmentDetails: attachmentDetails))
                        }
                    }
                    bulkResponse.setData(data: attachments)
                    completion( .success( attachments, bulkResponse ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
    }

    internal func getAttachments( page : Int?, perPage : Int?, modifiedSince : String?, completion : @escaping( Result.DataResponse< [ ZCRMAttachment ], BulkAPIResponse > ) -> () )
	{
        if let relatedList = self.relatedList
        {
            var attachments : [ZCRMAttachment] = [ZCRMAttachment]()
            setUrlPath( urlPath :  "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )" )
            setRequestMethod(requestMethod: .GET )
            if let page = page
            {
                addRequestParam( param :  RequestParamKeys.page, value : String( page ) )
            }
            if let perPage = perPage
            {
                addRequestParam( param : RequestParamKeys.perPage, value : String( perPage ) )
            }
            if ( modifiedSince.notNilandEmpty)
            {
                addRequestHeader( header : RequestParamKeys.ifModifiedSince, value : modifiedSince! )
            }
            let request : APIRequest = APIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getBulkAPIResponse { ( resultType ) in
                do{
                    let bulkResponse = try resultType.resolve()
                    let responseJSON = bulkResponse.getResponseJSON()
                    if responseJSON.isEmpty == false
                    {
                        let attachmentsList : [ [ String : Any ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                        if attachmentsList.isEmpty == true
                        {
                            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.RESPONSE_NIL) : \(ErrorMessage.RESPONSE_JSON_NIL_MSG)")
                            completion( .failure( ZCRMError.SDKError( code : ErrorCode.RESPONSE_NIL, message : ErrorMessage.RESPONSE_JSON_NIL_MSG, details : nil ) ) )
                            return
                        }
                        for attachmentDetails in attachmentsList
                        {
                            try attachments.append(self.getZCRMAttachment(attachmentDetails: attachmentDetails))
                        }
                    }
                    bulkResponse.setData(data: attachments)
                    completion( .success( attachments, bulkResponse ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
	}

    internal func uploadLinkAsAttachment( attachmentURL : String, completion : @escaping( Result.DataResponse< ZCRMAttachment, APIResponse > ) -> () )
    {
        if let relatedList = self.relatedList
        {
            setUrlPath( urlPath : "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )" )
            addRequestParam( param :  RequestParamKeys.attachmentURL, value : attachmentURL )
            setRequestMethod(requestMethod: .POST )
            let request : FileAPIRequest = FileAPIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.uploadLink { ( resultType ) in
                do{
                    let response = try resultType.resolve()
                    let responseJSON = response.getResponseJSON()
                    let responseJSONArray : [ [ String : Any ] ]  = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    let details = try responseJSONArray[ 0 ].getDictionary( key : APIConstants.DETAILS )
                    let attachment = try self.getZCRMAttachment(attachmentDetails: details)
                    response.setData( data : attachment )
                    completion( .success( attachment, response ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
    }

    internal func downloadAttachment( attachmentId : Int64, completion : @escaping( Result.Response< FileAPIResponse > ) -> () )
	{
        if let relatedList = self.relatedList
        {
            setJSONRootKey( key : JSONRootKey.NIL )
            setUrlPath( urlPath :  "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )/\( attachmentId )" )
            setRequestMethod(requestMethod: .GET )
            let request : FileAPIRequest = FileAPIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.downloadFile { ( resultType ) in
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
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
	}
    
    internal func downloadAttachment( attachmentId : Int64, fileDownloadDelegate : FileDownloadDelegate ) throws
    {
        if let relatedList = self.relatedList
        {
            setJSONRootKey( key : JSONRootKey.NIL )
            setUrlPath( urlPath :  "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )/\( attachmentId )" )
            setRequestMethod(requestMethod: .GET )
            let request : FileAPIRequest = FileAPIRequest(handler: self, fileDownloadDelegate: fileDownloadDelegate)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            request.downloadFile()
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            throw ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil )
        }
    }

    internal func deleteAttachment( attachmentId : Int64, completion : @escaping( Result.Response< APIResponse > ) -> () )
    {
        if let relatedList = self.relatedList
        {
            setJSONRootKey( key : JSONRootKey.NIL )
            setUrlPath( urlPath : "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )/\( attachmentId )" )
            setRequestMethod(requestMethod: .DELETE )
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
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
    }

    internal func addNote( note : ZCRMNote, completion : @escaping( Result.DataResponse< ZCRMNote, APIResponse > ) -> () )
	{
        if let relatedList = self.relatedList
        {
            var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
            var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
            dataArray.append( self.getZCRMNoteAsJSON(note: note) )
            reqBodyObj[getJSONRootKey()] = dataArray
            
            setUrlPath( urlPath : "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )" )
            setRequestMethod(requestMethod: .POST )
            setRequestBody(requestBody: reqBodyObj )
            let request : APIRequest = APIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.getAPIResponse { ( resultType ) in
                do{
                    let response = try resultType.resolve()
                    let responseJSON = response.getResponseJSON()
                    let respDataArr : [ [ String : Any? ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                    let respData : [String:Any?] = respDataArr[0]
                    let recordDetails : [ String : Any ] = try respData.getDictionary( key : APIConstants.DETAILS )
                    let note = try self.getZCRMNote(noteDetails: recordDetails, note: note)
                    response.setData(data: note )
                    completion( .success( note, response ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
	}
    
    internal func updateNote( note : ZCRMNote, completion : @escaping( Result.DataResponse< ZCRMNote, APIResponse > ) -> () )
	{
        if let relatedList = self.relatedList
        {
            if note.isCreate
            {
                ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : NOTE ID must not be nil")
                completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "NOTE ID must not be nil", details : nil ) ) )
                return
            }
            else
            {
                let noteId : String = String( note.id )
                var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
                var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
                dataArray.append(self.getZCRMNoteAsJSON(note: note))
                reqBodyObj[getJSONRootKey()] = dataArray
                
                setUrlPath( urlPath : "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )/\( noteId )")
                setRequestMethod(requestMethod: .PATCH )
                setRequestBody(requestBody: reqBodyObj)
                let request : APIRequest = APIRequest(handler: self)
                ZCRMLogger.logDebug(message: "Request : \(request.toString())")
                
                request.getAPIResponse { ( resultType ) in
                    do{
                        let response = try resultType.resolve()
                        let responseJSON = response.getResponseJSON()
                        let respDataArr : [ [ String : Any? ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
                        let respData : [String:Any?] = respDataArr[0]
                        let recordDetails : [ String : Any ] = try respData.getDictionary( key : APIConstants.DETAILS )
                        let updatedNote = try self.getZCRMNote(noteDetails: recordDetails, note: note)
                        response.setData(data: updatedNote )
                        completion( .success( updatedNote, response ) )
                    }
                    catch{
                        ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                        completion( .failure( typeCastToZCRMError( error ) ) )
                    }
                }
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
	}

    internal func downloadVoiceNote( noteId : Int64, completion : @escaping( Result.Response< FileAPIResponse > ) -> () )
    {
        if let relatedList = self.relatedList
        {
            setJSONRootKey( key : JSONRootKey.NIL )
            setUrlPath(urlPath:  "\(relatedList.apiName)/\(noteId)" )
            addRequestHeader(header: "Accept", value: "audio/*")
            setRequestMethod(requestMethod: .GET )
            let request : FileAPIRequest = FileAPIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            request.downloadFile { ( resultType ) in
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
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
    }
    
    internal func downloadVoiceNote( noteId : Int64, fileDownloadDelegate : FileDownloadDelegate ) throws
    {
        if let relatedList = self.relatedList
        {
            setJSONRootKey( key : JSONRootKey.NIL )
            setUrlPath(urlPath:  "\(relatedList.apiName)/\(noteId)" )
            addRequestHeader(header: "Accept", value: "audio/*")
            setRequestMethod(requestMethod: .GET )
            
            let request : FileAPIRequest = FileAPIRequest(handler: self, fileDownloadDelegate: fileDownloadDelegate)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            request.downloadFile()
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            throw ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil )
        }
    }
    
    internal func deleteNote( noteId : Int64, completion : @escaping( Result.Response< APIResponse > ) -> () )
	{
        if let relatedList = self.relatedList
        {
            setJSONRootKey( key : JSONRootKey.NIL )
            let noteIdString : String = String( noteId )
            setUrlPath( urlPath :  "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )/\( noteIdString )" )
            setRequestMethod(requestMethod: .DELETE )
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
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
	}
	
    private func getZCRMAttachment(attachmentDetails : [String:Any?]) throws -> ZCRMAttachment
	{
        let attachment : ZCRMAttachment = ZCRMAttachment( parentRecord : self.parentRecord )
        attachment.id = try attachmentDetails.getInt64(key: ResponseJSONKeys.id)
        if let fileName : String = attachmentDetails.optString( key : ResponseJSONKeys.fileName )
        {
            attachment.fileName = fileName
            attachment.fileExtension = fileName.pathExtension()
        }
        if(attachmentDetails.hasValue(forKey: ResponseJSONKeys.Size))
        {
            attachment.fileSize = try attachmentDetails.getInt64( key : ResponseJSONKeys.Size )
        }
        if ( attachmentDetails.hasValue( forKey : ResponseJSONKeys.createdBy ) )
        {
            let createdByDetails : [ String : Any ] = try attachmentDetails.getDictionary( key : ResponseJSONKeys.createdBy )
            attachment.createdBy = try getUserDelegate(userJSON : createdByDetails)
            attachment.createdTime = try attachmentDetails.getString( key : ResponseJSONKeys.createdTime )
        }
        if(attachmentDetails.hasValue(forKey: ResponseJSONKeys.modifiedBy))
        {
            let modifiedByDetails : [ String : Any ] = try attachmentDetails.getDictionary( key : ResponseJSONKeys.modifiedBy )
            attachment.modifiedBy = try getUserDelegate(userJSON : modifiedByDetails)
            attachment.modifiedTime = try attachmentDetails.getString( key : ResponseJSONKeys.modifiedTime )
        }
		if(attachmentDetails.hasValue(forKey: ResponseJSONKeys.owner))
		{
			let ownerDetails : [ String : Any ] = try attachmentDetails.getDictionary( key : ResponseJSONKeys.owner )
            attachment.owner = try getUserDelegate(userJSON : ownerDetails)
		}
        else if attachmentDetails.hasValue(forKey: ResponseJSONKeys.createdBy)
        {
            let ownerDetails : [String:Any] = try attachmentDetails.getDictionary(key: ResponseJSONKeys.createdBy)
            attachment.owner = try getUserDelegate(userJSON: ownerDetails)
        }
        if( attachmentDetails.hasValue(forKey: ResponseJSONKeys.editable))
        {
            attachment.isEditable = try attachmentDetails.getBoolean( key : ResponseJSONKeys.editable )
        }
        if( attachmentDetails.hasValue(forKey: ResponseJSONKeys.type))
        {
            attachment.type = try attachmentDetails.getString( key : ResponseJSONKeys.type )
        }
        if( attachmentDetails.hasValue(forKey: ResponseJSONKeys.linkURL) )
        {
            attachment.linkURL = try attachmentDetails.getString( key : ResponseJSONKeys.linkURL )
        }
        if(attachmentDetails.hasValue(forKey: ResponseJSONKeys.parentId))
        {
            let parentRecordList : [ String : Any ] = try attachmentDetails.getDictionary(key: ResponseJSONKeys.parentId)
            if let seModule = attachmentDetails.optString( key : ResponseJSONKeys.seModule )
            {
                attachment.parentRecord = ZCRMRecordDelegate( id : try parentRecordList.getInt64( key : ResponseJSONKeys.id ), moduleAPIName : seModule )
                if parentRecordList.hasValue(forKey: ResponseJSONKeys.name)
                {
                    attachment.parentRecord.label = try parentRecordList.getString( key : ResponseJSONKeys.name )
                }
            }
            else
            {
                attachment.parentRecord = ZCRMRecordDelegate( id : try parentRecordList.getInt64( key : ResponseJSONKeys.id ), moduleAPIName : self.parentRecord.moduleAPIName )
                if parentRecordList.hasValue(forKey: ResponseJSONKeys.name)
                {
                    attachment.parentRecord.label = try parentRecordList.getString( key : ResponseJSONKeys.name )
                }
            }
        }
		return attachment
	}
	
    private func getZCRMNote(noteDetails : [String:Any?], note : ZCRMNote) throws -> ZCRMNote
    {
        note.isCreate = false
        note.id = try noteDetails.getInt64( key : ResponseJSONKeys.id )
        if ( noteDetails.hasValue( forKey : ResponseJSONKeys.noteContent ) )
        {
            note.content = noteDetails.optString( key : ResponseJSONKeys.noteContent )
        }
        if ( noteDetails.hasValue( forKey : ResponseJSONKeys.noteTitle ) )
        {
            note.title = noteDetails.optString( key : ResponseJSONKeys.noteTitle )
        }
        if ( noteDetails.hasValue( forKey : ResponseJSONKeys.createdBy ) )
        {
            let createdByDetails : [ String : Any ] = try noteDetails.getDictionary( key : ResponseJSONKeys.createdBy )
            note.createdBy = try getUserDelegate(userJSON : createdByDetails)
            note.createdTime = try noteDetails.getString( key : ResponseJSONKeys.createdTime )
        }
        if ( noteDetails.hasValue( forKey : ResponseJSONKeys.modifiedBy ) )
        {
            let modifiedByDetails : [ String : Any ] = try noteDetails.getDictionary( key : ResponseJSONKeys.modifiedBy )
            note.modifiedBy = try getUserDelegate(userJSON : modifiedByDetails)
            note.modifiedTime = try noteDetails.getString( key : ResponseJSONKeys.modifiedTime )
        }
        if( noteDetails.hasValue( forKey: ResponseJSONKeys.owner ) )
        {
            let ownerDetails : [ String : Any ] = try noteDetails.getDictionary( key : ResponseJSONKeys.owner )
            note.owner = try getUserDelegate(userJSON : ownerDetails)
        }
        else
        {
            let ownerDetails : [String:Any] = try noteDetails.getDictionary(key: ResponseJSONKeys.createdBy)
            note.owner = try getUserDelegate(userJSON : ownerDetails)
        }
        if(noteDetails.hasValue(forKey: ResponseJSONKeys.attachments))
        {
            let attachmentsList : [ [ String : Any? ] ] = try noteDetails.getArrayOfDictionaries( key : ResponseJSONKeys.attachments )
            for attachmentDetails in attachmentsList
            {
                try note.addAttachment(attachment: self.getZCRMAttachment(attachmentDetails: attachmentDetails))
            }
        }
        if(noteDetails.hasValue(forKey: ResponseJSONKeys.parentId))
        {
            let parentRecordList : [ String : Any ] = try noteDetails.getDictionary(key: ResponseJSONKeys.parentId)
            if let seModule = noteDetails.optString( key : ResponseJSONKeys.seModule )
            {
                note.parentRecord = ZCRMRecordDelegate( id : try parentRecordList.getInt64( key : ResponseJSONKeys.id ), moduleAPIName : seModule )
                if parentRecordList.hasValue(forKey: ResponseJSONKeys.name)
                {
                    note.parentRecord.label = try parentRecordList.getString( key : ResponseJSONKeys.name )
                }
            }
            else
            {
                note.parentRecord = ZCRMRecordDelegate( id : try parentRecordList.getInt64( key : ResponseJSONKeys.id ), moduleAPIName : self.parentRecord.moduleAPIName )
                if parentRecordList.hasValue(forKey: ResponseJSONKeys.name)
                {
                    note.parentRecord.label = try parentRecordList.getString( key : ResponseJSONKeys.name )
                }
            }
        }
        if noteDetails.hasValue(forKey: ResponseJSONKeys.voiceNote)
        {
            note.isVoiceNote = try noteDetails.getBoolean( key : ResponseJSONKeys.voiceNote )
            if noteDetails.hasValue(forKey: ResponseJSONKeys.size)
            {
                note.size = try noteDetails.getInt64( key : ResponseJSONKeys.size )
            }
        }
        if noteDetails.hasValue(forKey: ResponseJSONKeys.editable)
        {
            note.isEditable = try noteDetails.getBoolean( key : ResponseJSONKeys.editable )
        }
		return note
	}
	
	private func getZCRMNoteAsJSON(note : ZCRMNote) -> [ String : Any? ]
	{
		var noteJSON : [ String : Any? ] = [ String : Any? ]()
        noteJSON.updateValue( note.title, forKey : ResponseJSONKeys.noteTitle )
        noteJSON.updateValue( note.content, forKey : ResponseJSONKeys.noteContent )
        noteJSON.updateValue( note.parentRecord.id, forKey : ResponseJSONKeys.parentId )
        noteJSON.updateValue( note.parentRecord.moduleAPIName, forKey : ResponseJSONKeys.seModule )
		return noteJSON
	}

    internal func addRelation( completion : @escaping( Result.Response< APIResponse > ) -> () )
    {
		if let junctionRecord = self.junctionRecord
        {
            var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
            var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
            dataArray.append( junctionRecord.relatedDetails )
            reqBodyObj[getJSONRootKey()] = dataArray
            
            setUrlPath( urlPath : "\( self.parentRecord.moduleAPIName )/\( self.parentRecord.id )/\( junctionRecord.apiName )/\( junctionRecord.id )" )
            setRequestMethod(requestMethod: .PATCH )
            setRequestBody(requestBody: reqBodyObj )
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
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : JUNCTION RECORD must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "JUNCTION RECORD must not be nil", details : nil ) ) )
        }
    }
    
    internal func addRelations( junctionRecords : [ ZCRMJunctionRecord ], completion : @escaping( Result.Response< BulkAPIResponse > ) -> () )
    {
        var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
        let dataArray : [ [ String : Any? ] ] = self.getRelationsDetailsAsJSON( junctionRecords : junctionRecords )
        reqBodyObj[ getJSONRootKey() ] = dataArray
        
        setUrlPath( urlPath : "\( self.parentRecord.moduleAPIName )/\( self.parentRecord.id )/\( junctionRecords[ 0 ].apiName )" )
        setRequestMethod( requestMethod : .PATCH )
        setRequestBody( requestBody : reqBodyObj )
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do
            {
                let response = try resultType.resolve()
                completion( .success( response ) )
            }
            catch
            {
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }

    internal func deleteRelation( completion : @escaping( Result.Response< APIResponse > ) -> () )
    {
        if let junctionRecord = self.junctionRecord
        {
            setUrlPath( urlPath: "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( junctionRecord.apiName )/\( junctionRecord.id )" )
            setRequestMethod(requestMethod: .DELETE )
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
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : JUNCTION RECORD must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "JUNCTION RECORD must not be nil", details : nil ) ) )
        }
    }
    
    internal func deleteRelations( junctionRecords : [ ZCRMJunctionRecord ], completion : @escaping( Result.Response< BulkAPIResponse > ) -> () )
    {
        setUrlPath( urlPath : "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( junctionRecords[ 0 ].apiName )" )
        setRequestMethod(requestMethod: .DELETE )
        var idString : String = String()
        for index in 0..<junctionRecords.count
        {
            idString.append(String(junctionRecords[index].id))
            if ( index != ( junctionRecords.count - 1 ) )
            {
                idString.append(",")
            }
        }
        addRequestParam( param : RequestParamKeys.ids, value : idString )
        let request : APIRequest = APIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        request.getBulkAPIResponse { ( resultType ) in
            do
            {
                let response = try resultType.resolve()
                completion( .success( response ) )
            }
            catch
            {
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
            }
        }
    }
    
    private func getRelationsDetailsAsJSON( junctionRecords : [ ZCRMJunctionRecord ] ) -> [ [ String : Any? ] ]
    {
        var relatedDetailsJSON : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
        for junctionRecord in junctionRecords
        {
            var recordJSON : [ String : Any? ] = [ String : Any? ]()
            recordJSON.updateValue( junctionRecord.id, forKey : ResponseJSONKeys.id )
            if !junctionRecord.relatedDetails.isEmpty
            {
                for ( key, value ) in junctionRecord.relatedDetails
                {
                    recordJSON.updateValue( value, forKey : key )
                }
            }
            relatedDetailsJSON.append( recordJSON )
        }
        return relatedDetailsJSON
    }
    
    internal override func getJSONRootKey() -> String
    {
        return JSONRootKey.DATA
    }
    
}

extension RelatedListAPIHandler : FileUploadDelegate
{
    internal func uploadAttachment( filePath : String?, fileName : String?, fileData : Data?, note : ZCRMNote?, completion : @escaping(Result.DataResponse< ZCRMAttachment, APIResponse > ) -> () )
    {
        if let relatedList = self.relatedList
        {
            do
            {
                if let note = note
                {
                    self.noteAttachment = note
                    try notesAttachmentLimitCheck( note : note )
                }
                try fileDetailCheck( filePath : filePath, fileData : fileData )
            }
            catch
            {
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                completion( .failure( typeCastToZCRMError( error ) ) )
                return
            }
            setUrlPath( urlPath : "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )" )
            setRequestMethod(requestMethod: .POST )
            let request : FileAPIRequest = FileAPIRequest(handler: self)
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            if let filePath = filePath
            {
                request.uploadFile( filePath : filePath, entity : nil, completion : { ( resultType ) in
                    do{
                        let response = try resultType.resolve()
                        let attachment = try self.getAttachmentFrom( response : response )
                        response.setData( data : attachment )
                        if let noteAttachment = self.noteAttachment
                        {
                            noteAttachment.addAttachment( attachment : attachment )
                        }
                        completion( .success( attachment, response ) )
                    }
                    catch{
                        ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                        completion( .failure( typeCastToZCRMError( error ) ) )
                    }
                })
            }
            else if let fileName = fileName, let fileData = fileData
            {
                request.uploadFile( fileName : fileName, entity : nil, fileData : fileData, completion : { ( resultType ) in
                    do{
                        let response = try resultType.resolve()
                        let attachment = try self.getAttachmentFrom( response : response )
                        response.setData( data : attachment )
                        if let noteAttachment = self.noteAttachment
                        {
                            noteAttachment.addAttachment( attachment : attachment )
                        }
                        completion( .success( attachment, response ) )
                    }
                    catch{
                        ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                        completion( .failure( typeCastToZCRMError( error ) ) )
                    }
                })
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            completion( .failure( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) ) )
        }
    }
    
    internal func uploadAttachment( filePath : String?, fileName : String?, fileData : Data?, note : ZCRMNote? )
    {
        if let relatedList = self.relatedList
        {
            do
            {
                if let note = note
                {
                    self.noteAttachment = note
                    try notesAttachmentLimitCheck( note : note )
                }
                try fileDetailCheck( filePath : filePath, fileData : fileData )
            }
            catch
            {
                ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                self.attachmentUploadDelegate?.didFail( typeCastToZCRMError( error ) )
                return
            }
            setUrlPath( urlPath : "\( self.parentRecord.moduleAPIName )/\( String( self.parentRecord.id ) )/\( relatedList.apiName )" )
            setRequestMethod(requestMethod: .POST )
            let request : FileAPIRequest = FileAPIRequest( handler : self, fileUploadDelegate : self )
            ZCRMLogger.logDebug(message: "Request : \(request.toString())")
            
            if let filePath = filePath
            {
                request.uploadFile( filePath : filePath, entity : nil )
            }
            else if let fileName = fileName, let fileData = fileData
            {
                request.uploadFile( fileName : fileName, entity : nil, fileData : fileData )
            }
        }
        else
        {
            ZCRMLogger.logError(message: "ZCRM SDK - Error Occurred : \(ErrorCode.MANDATORY_NOT_FOUND) : RELATED LIST must not be nil")
            self.attachmentUploadDelegate?.didFail( ZCRMError.ProcessingError( code : ErrorCode.MANDATORY_NOT_FOUND, message : "RELATED LIST must not be nil", details : nil ) )
        }
    }
    
    internal func addVoiceNote( filePath : String?, fileName : String?, fileData : Data?, note : ZCRMNote, completion : @escaping( Result.DataResponse< ZCRMNote, APIResponse > ) -> () )
    {
        do
        {
            try fileDetailCheck( filePath : filePath, fileData : fileData )
        }
        catch
        {
            ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
            completion( .failure( typeCastToZCRMError( error ) ) )
            return
        }
        var reqBody : [ String : Any? ] = [ String : Any? ]()
        var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
        var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
        dataArray.append( self.getZCRMNoteAsJSON(note: note) )
        reqBodyObj[getJSONRootKey()] = dataArray
        reqBody[ResponseJSONKeys.content] = reqBodyObj
        
        setUrlPath(urlPath: "Voice_Notes" )
        setRequestMethod(requestMethod: .POST )
        let request : FileAPIRequest = FileAPIRequest(handler: self)
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        if let filePath = filePath
        {
            request.uploadFile( filePath : filePath, entity : reqBody, completion : { ( resultType ) in
                do{
                    let response = try resultType.resolve()
                    let voiceNote = try self.getVoiceNoteFrom( response : response, note : note )
                    response.setData(data: voiceNote )
                    completion( .success( voiceNote, response ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            })
        }
        else if let fileName = fileName, let fileData = fileData
        {
            request.uploadFile( fileName : fileName, entity : reqBody, fileData : fileData, completion : { ( resultType ) in
                do{
                    let response = try resultType.resolve()
                    let voiceNote = try self.getVoiceNoteFrom( response : response, note : note )
                    response.setData(data: voiceNote )
                    completion( .success( voiceNote, response ) )
                }
                catch{
                    ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
                    completion( .failure( typeCastToZCRMError( error ) ) )
                }
            })
        }
    }
    
    internal func addVoiceNote( filePath : String?, fileName : String?, fileData : Data?, note : ZCRMNote )
    {
        do
        {
            try fileDetailCheck( filePath : filePath, fileData : fileData )
        }
        catch
        {
            ZCRMLogger.logError( message : "ZCRM SDK - Error Occurred : \( error )" )
            self.voiceNoteUploadDelegate?.didFail( typeCastToZCRMError( error ) )
            return
        }
        var reqBody : [ String : Any? ] = [ String : Any? ]()
        var reqBodyObj : [ String : [ [ String : Any? ] ] ] = [ String : [ [ String : Any? ] ] ]()
        var dataArray : [ [ String : Any? ] ] = [ [ String : Any? ] ]()
        dataArray.append( self.getZCRMNoteAsJSON(note: note) )
        reqBodyObj[getJSONRootKey()] = dataArray
        reqBody[ResponseJSONKeys.content] = reqBodyObj
        
        setUrlPath(urlPath: "Voice_Notes" )
        setRequestMethod(requestMethod: .POST )
        self.voiceNote = note
        let request : FileAPIRequest = FileAPIRequest( handler : self, fileUploadDelegate : self )
        ZCRMLogger.logDebug(message: "Request : \(request.toString())")
        
        if let filePath = filePath
        {
            request.uploadFile( filePath : filePath, entity : reqBody )
        }
        else if let fileName = fileName, let fileData = fileData
        {
            request.uploadFile( fileName : fileName, entity : reqBody, fileData : fileData )
        }
    }
    
    func progress( session : URLSession, sessionTask : URLSessionTask, progressPercentage : Double, totalBytesSent : Int64, totalBytesExpectedToSend : Int64 )
    {
        if self.voiceNote != nil
        {
            self.voiceNoteUploadDelegate?.progress( session : session, sessionTask : sessionTask, progressPercentage : progressPercentage, totalBytesSent : totalBytesSent, totalBytesExpectedToSend : totalBytesExpectedToSend )
        }
        else
        {
            self.attachmentUploadDelegate?.progress( session : session, sessionTask : sessionTask, progressPercentage : progressPercentage, totalBytesSent : totalBytesSent, totalBytesExpectedToSend : totalBytesExpectedToSend )
        }
    }
    
    func didFinish( _ apiResponse : APIResponse )
    {
        if let note = self.voiceNote
        {
            self.setVoiceNote( apiResponse : apiResponse, note : note )
        }
        else
        {
            self.setAttachment( apiResponse : apiResponse )
        }
    }
    
    func setVoiceNote( apiResponse : APIResponse, note : ZCRMNote )
    {
        do
        {
            let voiceNote = try self.getVoiceNoteFrom( response : apiResponse, note : note )
            apiResponse.setData( data : voiceNote )
            self.voiceNoteUploadDelegate?.didFinish( apiResponse )
            self.voiceNoteUploadDelegate?.getVoiceNote( voiceNote )
        }
        catch
        {
            self.voiceNoteUploadDelegate?.didFail( typeCastToZCRMError( error ) )
        }
    }
    
    func setAttachment( apiResponse : APIResponse )
    {
        do
        {
            let attachment = try self.getAttachmentFrom( response : apiResponse )
            apiResponse.setData( data : attachment )
            if let note = self.noteAttachment
            {
                note.addAttachment( attachment : attachment )
            }
            self.attachmentUploadDelegate?.didFinish( apiResponse )
            self.attachmentUploadDelegate?.getZCRMAttachment( attachment )
        }
        catch
        {
            self.attachmentUploadDelegate?.didFail( typeCastToZCRMError( error ) )
        }
    }
    
    private func getAttachmentFrom( response : APIResponse ) throws -> ZCRMAttachment
    {
        let responseJSON = response.getResponseJSON()
        let respDataArr : [ [ String : Any? ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
        let respData : [String:Any?] = respDataArr[0]
        let recordDetails : [ String : Any ] = try respData.getDictionary( key : APIConstants.DETAILS )
        let attachment = try self.getZCRMAttachment(attachmentDetails: recordDetails)
        return attachment
    }
    
    private func getVoiceNoteFrom( response : APIResponse, note : ZCRMNote ) throws -> ZCRMNote
    {
        let responseJSON = response.getResponseJSON()
        let respDataArr : [ [ String : Any? ] ] = try responseJSON.getArrayOfDictionaries( key : self.getJSONRootKey() )
        let respData : [String:Any?] = respDataArr[0]
        let recordDetails : [ String : Any ] = try respData.getDictionary( key : APIConstants.DETAILS )
        let note = try self.getZCRMNote(noteDetails: recordDetails, note: note)
        return note
    }
    
    func didFail(_ withError : ZCRMError? )
    {
        if self.voiceNote != nil
        {
            self.voiceNoteUploadDelegate?.didFail( withError)
        }
        else
        {
            self.attachmentUploadDelegate?.didFail( withError )
        }
    }
}

extension RelatedListAPIHandler
{
    internal struct ResponseJSONKeys
    {
        static let id = "id"
        static let name = "name"
        static let fileName = "File_Name"
        static let Size = "Size"
        static let createdBy = "Created_By"
        static let createdTime = "Created_Time"
        static let modifiedBy = "Modified_By"
        static let modifiedTime = "Modified_Time"
        static let owner = "Owner"
        static let editable = "$editable"
        static let type = "$type"
        static let linkURL = "$link_url"
        static let size = "$size"
        
        static let noteTitle = "Note_Title"
        static let noteContent = "Note_Content"
        static let attachments = "$attachments"
        static let parentId = "Parent_Id"
        static let seModule = "$se_module"
        static let voiceNote = "$voice_note"
        static let content = "content"
        static let module = "module"
    }
}

public protocol AttachmentUploadDelegate : FileUploadDelegate
{
    func getZCRMAttachment( _ attachment : ZCRMAttachment )
}

public protocol VoiceNoteUploadDelegate : FileUploadDelegate
{
    func getVoiceNote( _ voiceNote : ZCRMNote )
}

extension RequestParamKeys
{
    static let attachmentURL : String = "attachmentUrl"
}
