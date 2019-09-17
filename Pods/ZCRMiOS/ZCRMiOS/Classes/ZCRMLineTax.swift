//
//  ZCRMLineTax.swift
//  ZCRMiOS
//
//  Created by Umashri R on 20/06/19.
//

open class ZCRMLineTax : ZCRMEntity
{
    public var name : String
    public var percentage : Double
    public var value : Double = APIConstants.DOUBLE_MOCK{
        didSet
        {
            self.isValueSet = true
        }
    }
    internal var isValueSet : Bool = APIConstants.BOOL_MOCK
    
    public init( name : String, percentage : Double )
    {
        self.name = name
        self.percentage = percentage
    }
}

extension ZCRMLineTax : Equatable
{
    public static func == (lhs: ZCRMLineTax, rhs: ZCRMLineTax) -> Bool {
        let equals : Bool = lhs.name == rhs.name &&
            lhs.percentage == rhs.percentage &&
            lhs.value == rhs.value
        return equals
    }
}
