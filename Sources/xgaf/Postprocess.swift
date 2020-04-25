// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class Postprocess {
    static func run(areas: Areas) throws {
        let definitions = areas.definitions
        
        try postprocess(entities: areas.items,
                        entityType: "item",
                        idFieldName: "предмет",
                        definitions: definitions.items)
        try postprocess(entities: areas.mobiles,
                        entityType: "mobile",
                        idFieldName: "монстр",
                        definitions: definitions.mobiles)
        try postprocess(entities: areas.rooms,
                        entityType: "room",
                        idFieldName: "комната",
                        definitions: definitions.rooms)
    }
    
    static func postprocess(entities: [Int64: Entity], entityType: String, idFieldName: String, definitions: FieldDefinitions) throws {
        
        //let requiredFields = FieldDefinitions.fields.
        
        for pair in entities {
            let entity = pair.value
            
            guard let entityId = entity.value(named: idFieldName) else {
                fatalError("Inconsistent state")
            }
            
            // All required fields should be present
            for fieldName in definitions.requiredFieldNames {
                guard entity.hasRequiredField(named: fieldName) else {
                    throw PostprocessError(kind: .requiredFieldMissing(entity: entity, entityType: entityType, entityId: entityId.toSimplifiedFormat, fieldName: fieldName))
                }
            }
        }
        
    }
}
