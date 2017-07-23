/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

public class Nuvola.LauncherBinding: ModelBinding<LauncherModel>
{
	public LauncherBinding(Drt.ApiRouter router, WebWorker web_worker, LauncherModel? model=null)
	{
		base(router, web_worker, "Nuvola.Launcher", model ?? new LauncherModel());
	}
	
	protected override void bind_methods()
	{
		bind("set-tooltip", Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			"Set launcher tooltip.",
			handle_set_tooltip, {
			new Drt.StringParam("text", true, false, null, "Tooltip text.")
		});
		bind("set-actions", Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			"Set launcher actions.",
			handle_set_actions, {
			new Drt.StringArrayParam("actions", true, null, "Action name.")
		});
		bind("add-action", Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			"Add launcher action.",
			handle_add_action, {
			new Drt.StringParam("name", true, false, null, "Action name.")
		});
		bind("remove-action", Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			"Remove launcher action.",
			handle_remove_action, {
			new Drt.StringParam("name", true, false, null, "Action name.")
		});
		bind("remove-actions", Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			"Remove all launcher actions.",
			handle_remove_actions, null);
	}
	
	private Variant? handle_set_tooltip(GLib.Object source, Drt.ApiParams? params) throws Drt.MessageError
	{
		model.tooltip = params.pop_string();
		return null;
	}
	
	private Variant? handle_add_action(GLib.Object source, Drt.ApiParams? params) throws Drt.MessageError
	{
		model.add_action(params.pop_string());
		return null;
	}
	
	private Variant? handle_remove_action(GLib.Object source, Drt.ApiParams? params) throws Drt.MessageError
	{
		model.remove_action(params.pop_string());
		return null;
	}
	
	private Variant? handle_set_actions(GLib.Object source, Drt.ApiParams? params) throws Drt.MessageError
	{
		model.actions = params.pop_str_list();
		return null;
	}
	
	private Variant? handle_remove_actions(GLib.Object source, Drt.ApiParams? params) throws Drt.MessageError
	{
		model.remove_actions();
		return null;
	}
}
