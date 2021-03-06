/*
 * Copyright 2014-2016 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Nuvola
{

public class ActionsKeyBinderClient : GLib.Object, ActionsKeyBinder
{
	private Drt.ApiChannel conn;
	
	public class ActionsKeyBinderClient(Drt.ApiChannel conn)
	{
		this.conn = conn;
		conn.api_router.add_method("/nuvola/actionkeybinder/action-activated", Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			null, handle_action_activated, {
			new Drt.StringParam("action", true, false)
		});
	}
	
	public string? get_keybinding(string action)
	{
		const string METHOD = "/nuvola/actionkeybinder/get-keybinding";
		try
		{
			var data = conn.call_sync(METHOD, new Variant("(s)", action)); 
			Drt.MessageListener.check_type_string(data, "ms");
			string? keybinding = null;
			data.get("ms", &keybinding);
			return keybinding;
		}
		catch (GLib.Error e)
		{
			warning("Remote call %s failed: %s", METHOD, e.message);
			return null;
		}
	}
	
	public bool set_keybinding(string action, string? keybinding)
	{
		const string METHOD = "/nuvola/actionkeybinder/set-keybinding";
		try
		{
			var data = conn.call_sync(METHOD, new Variant("(sms)", action, keybinding)); 
			Drt.MessageListener.check_type_string(data, "b");
			return data.get_boolean();
		}
		catch (GLib.Error e)
		{
			warning("Remote call %s failed: %s", METHOD, e.message);
			return false;
		}
	}
	
	public bool bind(string action)
	{
		const string METHOD = "/nuvola/actionkeybinder/bind";
		try
		{
			var data = conn.call_sync(METHOD, new Variant("(s)", action)); 
			Drt.MessageListener.check_type_string(data, "b");
			return data.get_boolean();
		}
		catch (GLib.Error e)
		{
			warning("Remote call %s failed: %s", METHOD, e.message);
			return false;
		}
	}
	
	public bool unbind(string action)
	{
		const string METHOD = "/nuvola/actionkeybinder/unbind";
		try
		{
			var data = conn.call_sync(METHOD, new Variant("(s)", action)); 
			Drt.MessageListener.check_type_string(data, "b");
			return data.get_boolean();
		}
		catch (GLib.Error e)
		{
			warning("Remote call %s failed: %s", METHOD, e.message);
			return false;
		}
	}
	
	public string? get_action(string keybinding)
	{
		const string METHOD = "/nuvola/actionkeybinder/get-action";
		try
		{
			var data = conn.call_sync(METHOD, new Variant("(s)", keybinding)); 
			Drt.MessageListener.check_type_string(data, "ms");
			string? action = null;
			data.get("ms", &action);
			return action;
		}
		catch (GLib.Error e)
		{
			warning("Remote call %s failed: %s", METHOD, e.message);
			return null;
		}
	}
	
	public bool is_available(string keybinding)
	{
		const string METHOD = "/nuvola/actionkeybinder/is-available";
		try
		{
			var data = conn.call_sync(METHOD, new Variant("(s)", keybinding)); 
			Drt.MessageListener.check_type_string(data, "b");
			return data.get_boolean();
		}
		catch (GLib.Error e)
		{
			warning("Remote call %s failed: %s", METHOD, e.message);
			return false;
		}
	}
	
	private Variant? handle_action_activated(GLib.Object source, Drt.ApiParams? params) throws Drt.MessageError
	{
		var action = params.pop_string();
		var handled = false;
		action_activated(action, ref handled);
		return new Variant.boolean(handled);
	}
}

} // namespace Nuvola
