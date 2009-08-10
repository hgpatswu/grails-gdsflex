/**
 * Generated by Gas3 v2.0.0 (Granite Data Services).
 *
 * NOTE: this file is only generated if it does not exist. You may safely put
 * your custom code here.
 */

package org.granite.tide.uibuilder {
	
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	

	[Name("tideEntityMetadataBuilder")]
    public class GrailsEntityMetadataBuilder implements IEntityMetadataBuilder {
    	
    	private var _baseEntityClassCache:Dictionary = new Dictionary(true);
    	private var _metadataCache:Dictionary = new Dictionary(true);
    	
    	
    	private function getBaseEntityClass(entity:Object):Class {
    		var className:String = getQualifiedClassName(entity);
    		var baseEntityClass:Class = _baseEntityClassCache[className] as Class;
    		if (baseEntityClass != null)
    			return baseEntityClass;
    		
			var desc:XML = describeType(entity);
			var extendsClass:XMLList = null;
			if (entity is Class)
				extendsClass = desc.factory.extendsClass;
			else
				extendsClass = desc.extendsClass;
			
			baseEntityClass = getDefinitionByName(extendsClass[0].@type.toXMLString()) as Class;
			_baseEntityClassCache[className] = baseEntityClass;
			return baseEntityClass;
    	}
    	
    	public function getDisplayLabel(entityClass:Class):String {
			var baseEntityClass:Class = getBaseEntityClass(entityClass);
			if (baseEntityClass.meta_constraints && baseEntityClass.meta_constraints.length > 0)
				return baseEntityClass.meta_constraints[0].property;
    		return "name";
    	}
    	
    	public function buildMetadata(entity:Object):Array {
    		var baseEntityClass:Class = getBaseEntityClass(entity);
    		
    		var metadata:Array = _metadataCache[baseEntityClass] as Array;
    		if (metadata != null)
    			return metadata;
    		
    		metadata = new Array();
    		
			var desc:XML = describeType(entity);
			var getters:XMLList = null;
			if (entity is Class)
				getters = desc..factory..accessor.(@access.toString().search('read') >= 0);
			else 
				getters = desc..accessor.(@access.toString().search('read') >= 0);
			
			var constraints:Object = new Object();
			if (baseEntityClass.meta_constraints) {
				for each (var c:Object in baseEntityClass.meta_constraints)
					constraints[c.property] = c; 
			}
			
            for each (var g:XML in getters) {
            	var name:String = g.@name.toXMLString();
            	if (name == 'id' || name == 'version' || name == 'uid')
            		continue;
            	
        		if (constraints[name] && constraints[name].display == 'false')
        			continue;
            	
            	var elementClass:Class = getDefinitionByName(g.@type.toXMLString()) as Class;
            	var elementDesc:XML = describeType(elementClass); 
            	
            	var property:Object = { name: name };
            	if (g.@type.toXMLString() == 'Number' || g.@type.toXMLString() == 'String'
            		 || g.@type.toXMLString() == 'Boolean' || g.@type.toXMLString() == 'Date') {
            		property.kind = "simple";
            		property.type = elementClass;
            	}
            	
            	if (g.@type.toXMLString() == 'flash.net::FileReference') {
            		property.kind = "binary";
            		property.type = FileReference;
            	}
            	
            	if (g.@type.toXMLString() == 'flash.utils::ByteArray') {
            		property.kind = "binary";
            		property.type = ByteArray;
            	}
            	
        		if (constraints[name]) {
        			if (constraints[name].size) {
	        			var ssize:String = constraints[name].size;
	        			property.minSize = Number(ssize.substring(0, ssize.indexOf("..")));
	        			property.maxSize = Number(ssize.substring(ssize.indexOf("..")+2));
	        		}
        			
        			if (constraints[name].blank == 'false')
        				property.required = true;
        				
        			if (constraints[name].email == 'true')
        				property.email = true;
        				
        			if (constraints[name].inList)
        				property.inList = constraints[name].inList;
        			
        			if (constraints[name].widget)
        				property.widget = constraints[name].widget;
        				
            		if (constraints[name].association == 'manyToOne' || constraints[name].association == 'oneToOne') {
	            		property.kind = "manyToOne";
	            		property.type = elementClass;
	            		property.label = getDisplayLabel(elementClass);
	            	}
	            	
            		if (constraints[name].association == 'oneToMany' && constraints[name].bidirectional == 'true') {
	            		property.kind = "oneToMany";
	            		property.type = baseEntityClass.meta_hasMany[name];
	            		property.label = getDisplayLabel(property.type);
	            	}
	            	
            		if ((constraints[name].association == 'oneToMany' && constraints[name].bidirectional != 'true')
            			|| (constraints[name].association == 'manyToMany' && constraints[name].owningSide == 'true')) {
	            		property.kind = "manyToMany";
	            		property.type = baseEntityClass.meta_hasMany[name];
	            		property.label = getDisplayLabel(property.type);
	            	}
            	}
            	
            	metadata.push(property);
            }
            
            if (baseEntityClass.meta_constraints) {
            	var names:Array = new Array();
            	for each (c in baseEntityClass.meta_constraints)
            		names.push(c.property);
            	
            	metadata.sort(function(p1:*, p2:*):int {
            		if (p1.name == p2.name)
            			return 0;
            		if (names.indexOf(p1.name) > names.indexOf(p2.name))
            			return 1;
            		return -1;	
            	});
            }
            
            _metadataCache[baseEntityClass] = metadata;
            
            return metadata;
    	}
    }
}