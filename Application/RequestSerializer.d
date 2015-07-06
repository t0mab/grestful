/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
module Application.RequestSerializer;

import glib.KeyFile;

import Generic.Request;
import Generic.Utility;

/**
 * Handles serializing and unserializing request objects to and from a (Glib) KeyFile.
 */
class RequestSerializer
{
public:
    /**
     * Constructor.
     */
    this(KeyFile file)
    {
        this.File = file;
    }

public:
    @property
    {
        KeyFile File()
        {
            return this.file;
        }

        void File(KeyFile file)
        {
            this.file = file;
        }
    }

public:
    /**
     * Serializes the specified request to the configured file.
     */
    void serialize(Request request, string name, string groupName)
    {
        string url = request.Url;
        string textualData = assumeUTF8Compat(request.Data);

        file.setString(groupName, "Name", name);
        file.setString(groupName,  "Method", to!string(request.HttpMethod));
        file.setString(groupName,  "Url",  url ? url : "");
        file.setString(groupName,  "Data", textualData ? textualData : "");

        file.setInteger(groupName, "HeaderCount", cast(int) request.Headers.length);

        ulong j = 1;

        foreach (name, value; request.Headers)
        {
            file.setString(groupName, "Header" ~ to!string(j) ~ "Name", name);
            file.setString(groupName, "Header" ~ to!string(j) ~ "Value", value);

            ++j;
        }
    }

    /**
     * Unserializes a request from the configured file into the passed object. Returns the name of the request.
     */
    string unserialize(Request request, string groupName)
    {
        string[string] requestHeaders;
        int headerCount = file.getIntegerDefault(groupName, "HeaderCount", 0);

        foreach (j; 1 .. (headerCount + 1))
        {
            string header = file.getStringDefault(groupName, "Header" ~ to!string(j) ~ "Name", "");
            string value  = file.getStringDefault(groupName, "Header" ~ to!string(j) ~ "Value", "");

            requestHeaders[header] = value;
        }

        string methodName = file.getStringDefault(groupName,  "Method", "");

        with (request)
        {
            Url        = file.getStringDefault(groupName,  "Url", "");
            Headers    = requestHeaders;
            HttpMethod = Request.getMethodByName(methodName);

            Data = std.string.representation(file.getStringDefault(groupName,  "Data", ""));
        }

        string name = file.getStringDefault(groupName, "Name", "");

        return name;
    }

protected:
    /**
     * They key file to use for operations.
     */
    KeyFile file;
}
