module sdc.gen.value.ivariable;

import sdc.location;
import sdc.gen.value.ivalue;


abstract class Variable
{
    Value value;
    
    this(Value value)
    {
        this.value = value;
    }
    
    abstract void set(Location, Value);
}
