// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class Postprocess {
    static func run(areas: Areas) throws {
        let definitions = areas.definitions
        
        // All required fields should be present
        try checkRequiredFields("item",
                                idFieldName: "предмет",
                                definitions: definitions.items,
                                entities: areas.items)
        try checkRequiredFields("mobile",
                                idFieldName: "монстр",
                                definitions: definitions.mobiles,
                                entities: areas.mobiles)
        try checkRequiredFields("room",
                                idFieldName: "комната",
                                definitions: definitions.rooms,
                                entities: areas.rooms)

        // Automorph
    }
    
    static func checkRequiredFields(_ entityType: String, idFieldName: String, definitions: FieldDefinitions, entities: [Int64: Entity]) throws {
        
        //let requiredFields = FieldDefinitions.fields.
        
        for pair in entities {
            let entity = pair.value
            
            guard let entityId = entity.value(named: idFieldName) else {
                fatalError("Inconsistent state")
            }
            
            for fieldName in definitions.requiredFieldNames {
                guard entity.containsField(named: fieldName) else {
                    throw PostprocessError(kind: .requiredFieldMissing(entityType: entityType, entityId: entityId.toSimplifiedFormat, fieldName: fieldName))
                }
            }
            
        }
        
    }
}
