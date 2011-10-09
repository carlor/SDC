/**
 * Copyright 2010 Jakob Ovrum.
 * Copyright 2011 Bernard Helyer.
 * This file is part of SDC. SDC is licensed under the GPL.
 * See LICENCE or sdc.d for more details.
 */
module sdc.gen.enumeration;

import std.string;

import sdc.util;
import sdc.compilererror;
import sdc.location;
import sdc.extract;
import ast = sdc.ast.all;
import sdc.gen.sdcmodule;
import sdc.gen.value.casting;
import sdc.gen.value.type;
import sdc.gen.value.value;
import sdc.gen.base;
import sdc.gen.expression;



void genEnumDeclaration(ast.EnumDeclaration decl, Module mod)
{
    auto firstMember = decl.memberList.members[0];    
    Type base;
    Value initialiser;
    
    if (decl.base is null) {
        if (firstMember.initialiser !is null) {
            // Infer the type from the first initialiser.
            initialiser = genConditionalExpression(firstMember.initialiser, mod);
            base = initialiser.type;
        } else { 
            // Otherwise assume int.
            base = IntType.create(mod);
        }
    } else {
        base = astTypeToBackendType(decl.base, mod, OnFailure.DieWithError);
    }
    
    auto type = EnumType.create(mod, base);
    type.fullName = mod.name.dup;
    type.fullName.identifiers ~= decl.name;
     
    foreach(i, member; decl.memberList.members) {
        if (member.initialiser) {
            initialiser = genConditionalExpression(member.initialiser, mod);
        }
        if (!initialiser.isKnown) {
            throw new CompilerError(member.initialiser.location, "enum initialisers must be known at compile time.");
        }
        
        if (decl.name !is null) {
            type.addMember(extractIdentifier(member.name), initialiser);
        } else {
            mod.currentScope.add(extractIdentifier(member.name), new Store(initialiser));
        }

        initialiser = initialiser.inc(member.location);
    }
    
    if (decl.name !is null) {
        auto name = extractIdentifier(decl.name);
        mod.currentScope.add(name, new Store(type, decl.name.location));
    }
}