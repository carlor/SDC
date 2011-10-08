module sdc.gen.value.variable;

import sdc.location;
import sdc.gen.value.type;
import sdc.gen.value.value;

class Variable
{
    Location location;

    static Variable create(Location loc, Value val)
    {
        return null;
    }

    static Variable createVoidInitialised(Location loc, Type t)
    {
        return null;
    }

    void set(Location loc, Value val);
    Value get(Location loc);
}
