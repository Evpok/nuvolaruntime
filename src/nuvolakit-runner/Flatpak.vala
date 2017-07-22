/*
 * Copyright 2017 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if FLATPAK
namespace Nuvola.Flatpak
{

public void check_desktop_portal_available(Cancellable? cancellable = null) throws GLib.Error
{
    var conn = Bus.get_sync(BusType.SESSION, cancellable);
    const string NAME = "org.freedesktop.portal.Desktop";
    const string PATH = "/org/freedesktop/portal/desktop";
    try
    {
        conn.call_sync(
            NAME, PATH, "org.freedesktop.portal.OpenURI", "OpenURI",
                null, null, DBusCallFlags.NONE, 60000, cancellable);
    }
    catch (GLib.Error e)
    {
        if (!(e is DBusError.INVALID_ARGS))
            throw e; 
    }
    try
    {
        conn.call_sync(NAME, PATH, "org.freedesktop.portal.ProxyResolver", "Lookup",
            null, null, DBusCallFlags.NONE, 100, cancellable);
    }
    catch (GLib.Error e)
    {
        if (!(e is DBusError.INVALID_ARGS))
            throw e; 
    }
}

public async void check_desktop_portal_available_async(int timeout_ms, Cancellable? cancellable=null) throws GLib.Error
{
    var conn = yield Bus.@get(BusType.SESSION, cancellable);
    const string NAME = "org.freedesktop.portal.Desktop";
    const string PATH = "/org/freedesktop/portal/desktop";
    try
    {
        yield conn.call(
            NAME, PATH, "org.freedesktop.portal.OpenURI", "OpenURI",
                null, null, DBusCallFlags.NONE, timeout_ms, cancellable);
    }
    catch (GLib.Error e)
    {
        if (!(e is DBusError.INVALID_ARGS))
            throw e; 
    }
    try
    {
        yield conn.call(NAME, PATH, "org.freedesktop.portal.ProxyResolver", "Lookup",
            null, null, DBusCallFlags.NONE, 100, cancellable);
    }
    catch (GLib.Error e)
    {
        if (!(e is DBusError.INVALID_ARGS))
            throw e; 
    }
}

} // namespace Nuvola.Flatpak
#endif
