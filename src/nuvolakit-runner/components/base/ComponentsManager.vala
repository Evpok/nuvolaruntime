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

namespace Nuvola
{

public class ComponentsManager: Gtk.Stack
{
	public Drt.Lst<Component> components {get; construct;}
	private SList<Row> rows = null;
	private Gtk.Grid grid;
	private Settings? component_settings = null;

	public ComponentsManager(Drt.Lst<Component> components)
	{
		GLib.Object(components: components, transition_type: Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
		grid = new Gtk.Grid();
		grid.margin = 10;
		grid.column_spacing = 15;
		refresh();
		var scroll = new Gtk.ScrolledWindow(null, null);
		scroll.hexpand = scroll.vexpand = true;
		scroll.add(grid);
		scroll.show();
		add_named(scroll, "list");
	}
	
	public void refresh()
	{
		rows = null;
		foreach (var child in grid.get_children())
			grid.remove(child);
		
		var row = 0;
		foreach (var component in components)
		{
			if (component.hidden && !component.enabled)
				continue;
			if (row > 0)
			{
				var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
				separator.hexpand = true;
				separator.vexpand = false;
				separator.margin_top = separator.margin_bottom = 10;
				grid.attach(separator, 0, row++, 3, 1);
			}
			
			rows.prepend(new Row(grid, row++, this, component));
		}
		grid.show_all();
	}
	
	public void show_settings(Component? component)
	{
		if (component == null)
		{
			if (component_settings != null)
			{
				this.visible_child_name = "list";
				this.remove(component_settings.widget);
				component_settings = null;
			}
		}
		else
		{
			component_settings = new Settings(this, component);
			this.add(component_settings.widget);
			this.visible_child = component_settings.widget;
		}
	}
	
	[Compact]
	private class Row
	{
		public unowned ComponentsManager manager;
		public unowned Component component;
		public Gtk.Button? button;
		public Gtk.Switch checkbox;
		
		public Row(Gtk.Grid grid, int row, ComponentsManager manager, Component component)
		{
			this.manager = manager;
			this.component = component;
			
			checkbox = new Gtk.Switch();
			checkbox.active = component.enabled;
			checkbox.vexpand = checkbox.hexpand = false;
			checkbox.halign = checkbox.valign = Gtk.Align.CENTER;
			component.notify.connect_after(on_notify);
			checkbox.notify.connect_after(on_notify);
			grid.attach(checkbox, 0, row, 1, 1);
			
			var label = new Gtk.Label(Markup.printf_escaped(
				"<span size='medium'><b>%s</b></span>\n<span foreground='#666666' size='small'>%s</span>",
				component.name, component.description));
			label.use_markup = true;
			label.vexpand = false;
			label.hexpand = true;
			label.halign = Gtk.Align.START;
			((Gtk.Misc) label).yalign = 0.0f;
			((Gtk.Misc) label).xalign = 0.0f;
			label.set_line_wrap(true);
			grid.attach(label, 1, row, 1, 1);
			
			if (component.has_settings)
			{
				button = new Gtk.Button.from_icon_name("emblem-system-symbolic", Gtk.IconSize.BUTTON);
				button.vexpand = button.hexpand = false;
				button.halign = button.valign = Gtk.Align.CENTER;
				button.sensitive = component.enabled;
				button.clicked.connect(on_settings_clicked);
				grid.attach(button, 2, row, 1, 1);
			}
			else
			{
				button = null;
			}
		}
		
		~Row()
		{
			component.notify.disconnect(on_notify);
			checkbox.notify.disconnect(on_notify);
			if (button != null)
				button.clicked.disconnect(on_settings_clicked);
		}
		
		private void on_notify(GLib.Object o, ParamSpec p)
		{
			switch (p.name)
			{
			case "enabled":
				if (checkbox.active != component.enabled)
					checkbox.active = component.enabled;
				if (button != null)
					button.sensitive = checkbox.active;
				break;
			case "active":
				component.toggle(checkbox.active);
				break;
			}
		}
		
		private void on_settings_clicked()
		{
			manager.show_settings(component);
		}
	}
	
	[Compact]
	private class Settings
	{
		public Gtk.Container widget;
		public unowned ComponentsManager manager;
		public Component component;
		
		public Settings(ComponentsManager manager, Component component)
		{
			this.manager = manager;
			this.component = component;
			var grid = new Gtk.Grid();
			grid.column_spacing = grid.row_spacing = grid.margin = 10;
			widget = grid;
			var button = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			button.vexpand = button.hexpand = false;
			button.valign = button.halign = Gtk.Align.CENTER;
			button.clicked.connect(on_back_clicked);
			grid.attach(button, 0, 0, 1, 1);
			var label = Drt.Labels.markup(
				"<span size='medium'><b>%s</b></span>\n<span foreground='#444' size='small'>%s</span>",
				component.name, component.description);
			grid.attach(label, 1, 0, 1, 1);
			
			var component_widget = component.get_settings();
			if (component_widget != null)
			{
				var scroll = new Gtk.ScrolledWindow(null, null);
				scroll.vexpand = scroll.hexpand = true;
				scroll.add(component_widget);
				grid.attach(scroll, 0, 1, 2, 1);
			}
			else
			{
				grid.attach(new Gtk.Label("No settings available"), 0, 1, 2, 1);
			}
			widget.show_all();
		}
		
		private void on_back_clicked()
		{
			manager.show_settings(null);
		}
	}
}

} // namespace Nuvola
