
//  Read the address into a char array.
//  Returns the length.
int UTIL_StringtToCharArray(Address stringt, char[] buffer, int maxlen)
{
    if (stringt == Address_Null)
    {
        ThrowError("string_t address is null");
    }

    if (maxlen <= 0)
    {
        ThrowError("Buffer size is negative or zero");
    }

    int max = maxlen - 1;
    int i   = 0;
    for (; i < max; i++)
    {
        buffer[i] = LoadFromAddress(stringt + view_as<Address>(i), NumberType_Int8);
        if (buffer[i] == '\0')
        {
            return i;
        }
    }

    buffer[i] = '\0';
    return i;
}

bool UTIL_EarlyFail(const char[] message, char[] err, int err_max)
{
    strcopy(err, err_max, message);

    return false;
}