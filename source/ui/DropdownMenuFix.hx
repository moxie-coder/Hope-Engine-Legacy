package ui;

import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.StrNameLabel;
import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.ui.interfaces.IHasParams;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * @author larsiusprime
 */
class DropdownMenuFix extends FlxUIGroup implements IFlxUIWidget implements IFlxUIClickable implements IHasParams
{
	public static var dropdowns:Array<DropdownMenuFix> = [];
	public static var isDropdowning:Bool = false;

	public var skipButtonUpdate(default, set):Bool;

	private function set_skipButtonUpdate(b:Bool):Bool
	{
		skipButtonUpdate = b;
		header.button.skipButtonUpdate = b;
		return b;
	}

	public var selectedId(get, set):String;
	public var selectedLabel(get, set):String;

	private var _selectedId:String;
	private var _selectedLabel:String;

	private function get_selectedId():String
	{
		return _selectedId;
	}

	private function set_selectedId(str:String):String
	{
		if (_selectedId == str)
			return str;

		var i:Int = 0;
		for (btn in list)
		{
			if (btn != null && btn.name == str)
			{
				var item:FlxUIButton = list[i];
				_selectedId = str;
				if (item.label != null)
				{
					_selectedLabel = item.label.text;
					header.text.text = item.label.text;
				}
				else
				{
					_selectedLabel = "";
					header.text.text = "";
				}
				return str;
			}
			i++;
		}
		return str;
	}

	private function get_selectedLabel():String
	{
		return _selectedLabel;
	}

	private function set_selectedLabel(str:String):String
	{
		if (_selectedLabel == str)
			return str;

		var i:Int = 0;
		for (btn in list)
		{
			if (btn.label.text == str)
			{
				var item:FlxUIButton = list[i];
				_selectedId = item.name;
				_selectedLabel = str;
				header.text.text = str;
				return str;
			}
			i++;
		}
		return str;
	}

	/**
	 * The header of this dropdown menu.
	 */
	public var header:FlxUIDropDownHeader;

	/**
	 * The list of items that is shown when the toggle button is clicked.
	 */
	public var list:Array<FlxUIButton> = [];

	/**
	 * The background for the list.
	 */
	public var dropPanel:FlxUI9SliceSprite;

	public var params(default, set):Array<Dynamic>;

	private function set_params(p:Array<Dynamic>):Array<Dynamic>
	{
		return params = p;
	}

	public var dropDirection(default, set):FlxUIDropDownMenuDropDirection = Automatic;

	private function set_dropDirection(dropDirection):FlxUIDropDownMenuDropDirection
	{
		this.dropDirection = dropDirection;
		updateButtonPositions();
		return dropDirection;
	}

	public static inline var CLICK_EVENT:String = "click_dropdown";

	public var callback:String->Void;

	// private var _ui_control_callback:Bool->DropdownMenuFix->Void;

	/**
	 * This creates a new dropdown menu.
	 *
	 * @param	X					x position of the dropdown menu
	 * @param	Y					y position of the dropdown menu
	 * @param	DataList			The data to be displayed
	 * @param	Callback			Optional Callback
	 * @param	Header				The header of this dropdown menu
	 * @param	DropPanel			Optional 9-slice-background for actual drop down menu
	 * @param	ButtonList			Optional list of buttons to be used for the corresponding entry in DataList
	 * @param	UIControlCallback	Used internally by FlxUI
	 */
	public function new(X:Float = 0, Y:Float = 0, DataList:Array<StrNameLabel>, ?Callback:String->Void, ?Header:FlxUIDropDownHeader,
			?DropPanel:FlxUI9SliceSprite, ?ButtonList:Array<FlxUIButton>, ?UIControlCallback:Bool->DropdownMenuFix->Void)
	{
		super(X, Y);
		callback = Callback;
		header = Header;
		dropPanel = DropPanel;

		if (header == null)
			header = new FlxUIDropDownHeader();

		if (dropPanel == null)
		{
			var rect = new Rectangle(0, 0, header.background.width, header.background.height);
			dropPanel = new FlxUI9SliceSprite(0, 0, FlxUIAssets.IMG_BOX, rect, [1, 1, 14, 14]);
		}

		if (DataList != null)
		{
			for (i in 0...DataList.length)
			{
				var data = DataList[i];
				list.push(makeListButton(i, data.label, data.name));
			}
			selectSomething(DataList[0].name, DataList[0].label);
		}
		else if (ButtonList != null)
		{
			for (btn in ButtonList)
			{
				list.push(btn);
				btn.resize(header.background.width, header.background.height);
				btn.x = 1;
			}
		}
		updateButtonPositions();

		dropPanel.resize(header.background.width, getPanelHeight());
		dropPanel.visible = false;
		add(dropPanel);

		for (btn in list)
		{
			add(btn);
			btn.visible = false;
		}

		// _ui_control_callback = UIControlCallback;
		// header.button.onUp.callback = onDropdown;
		Main.mouseManager.add(header, null, function(a:FlxUIDropDownHeader) { onDropdown(); }, null, null, true);
		add(header);

		dropPanel.y = header.y + header.height;
		dropdowns.push(this);
	}

	private function updateButtonPositions():Void
	{
		var buttonHeight = header.background.height;
		dropPanel.y = header.background.y;
		if (dropsUp())
			dropPanel.y -= getPanelHeight();
		else
			dropPanel.y += buttonHeight;

		var offset = dropPanel.y;
		for (button in list)
		{
			button.y = offset;
			offset += buttonHeight;
		}
	}

	override function set_visible(Value:Bool):Bool
	{
		var vDropPanel = dropPanel.visible;
		var vButtons = [];
		for (i in 0...list.length)
		{
			if (list[i] != null)
			{
				vButtons.push(list[i].visible);
			}
			else
			{
				vButtons.push(false);
			}
		}
		super.set_visible(Value);
		dropPanel.visible = vDropPanel;
		for (i in 0...list.length)
		{
			if (list[i] != null)
			{
				list[i].visible = vButtons[i];
			}
		}
		return Value;
	}

	private function dropsUp():Bool
	{
		return dropDirection == Up || (dropDirection == Automatic && exceedsHeight());
	}

	private function exceedsHeight():Bool
	{
		return y + getPanelHeight() + header.background.height > FlxG.height;
	}

	private function getPanelHeight():Float
	{
		return list.length * header.background.height;
	}

	/**
	 * Change the contents with a new data list
	 * Replaces the old content with the new content
	 */
	public function setData(DataList:Array<StrNameLabel>):Void
	{
		var i:Int = 0;

		if (DataList != null)
		{
			for (data in DataList)
			{
				var recycled:Bool = false;
				if (list != null)
				{
					if (i <= list.length - 1)
					{ // If buttons exist, try to re-use them
						var btn:FlxUIButton = list[i];
						if (btn != null)
						{
							btn.label.text = data.label; // Set the label
							list[i].name = data.name; // Replace the name
							recycled = true; // we successfully recycled it
						}
					}
				}
				else
				{
					list = [];
				}
				if (!recycled)
				{ // If we couldn't recycle a button, make a fresh one
					var t:FlxUIButton = makeListButton(i, data.label, data.name);
					list.push(t);
					add(t);
					t.visible = false;
				}
				i++;
			}

			// Remove excess buttons:
			if (list.length > DataList.length)
			{ // we have more entries in the original set
				for (j in DataList.length...list.length)
				{ // start counting from end of list
					var b:FlxUIButton = list.pop(); // remove last button on list
					b.visible = false;
					b.active = false;
					remove(b, true); // remove from widget
					b.destroy(); // destroy it
					b = null;
				}
			}

			selectSomething(DataList[0].name, DataList[0].label);
		}

		dropPanel.resize(header.background.width, getPanelHeight());
		updateButtonPositions();
	}

	private function selectSomething(name:String, label:String):Void
	{
		header.text.text = label;
		selectedId = name;
		selectedLabel = label;
	}

	private function makeListButton(i:Int, Label:String, Name:String):FlxUIButton
	{
		var t:FlxUIButton = new FlxUIButton(0, 0, Label);
		t.broadcastToFlxUI = false;
		// t.onUp.callback = onClickItem.bind(i);
		Main.mouseManager.add(t, null, function(a:FlxUIButton) { onClickItem(i); }, null, null, true);

		t.name = Name;

		t.loadGraphicSlice9([FlxUIAssets.IMG_INVIS, FlxUIAssets.IMG_HILIGHT, FlxUIAssets.IMG_HILIGHT], Std.int(header.background.width),
			Std.int(header.background.height), [[1, 1, 3, 3], [1, 1, 3, 3], [1, 1, 3, 3]], FlxUI9SliceSprite.TILE_NONE);
		t.labelOffsets[FlxButton.PRESSED].y -= 1; // turn off the 1-pixel depress on click

		t.up_color = FlxColor.BLACK;
		t.over_color = FlxColor.WHITE;
		t.down_color = FlxColor.WHITE;

		t.resize(header.background.width - 2, header.background.height - 1);

		t.label.alignment = "left";
		t.autoCenterLabel();
		t.x = 1;

		for (offset in t.labelOffsets)
		{
			offset.x += 2;
		}

		return t;
	}

	/*public function setUIControlCallback(UIControlCallback:Bool->DropdownMenuFix->Void):Void {
		_ui_control_callback = UIControlCallback;
	}*/
	public function changeLabelByIndex(i:Int, NewLabel:String):Void
	{
		var btn:FlxUIButton = getBtnByIndex(i);
		if (btn != null && btn.label != null)
		{
			btn.label.text = NewLabel;
		}
	}

	public function changeLabelById(name:String, NewLabel:String):Void
	{
		var btn:FlxUIButton = getBtnById(name);
		if (btn != null && btn.label != null)
		{
			btn.label.text = NewLabel;
		}
	}

	public function getBtnByIndex(i:Int):FlxUIButton
	{
		if (i >= 0 && i < list.length)
		{
			return list[i];
		}
		return null;
	}

	public function getBtnById(name:String):FlxUIButton
	{
		for (btn in list)
		{
			if (btn.name == name)
			{
				return btn;
			}
		}
		return null;
	}

	public var scrollable:Bool = false;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var a = [];

		for (dd in dropdowns)
		{
			if (Helper.screenOverlap(dd, dd.camera))
				a.push(dd);
		}

		isDropdowning = a.length > 0;

		if (FlxG.mouse.wheel != 0 && scrollable && Helper.screenOverlap(dropPanel, camera))
			dropPanel.y += (dropPanel.height / list.length) * FlxG.mouse.wheel;

		if (dropPanel.y > header.y + header.height)
			dropPanel.y = header.y + header.height;

		if (dropPanel.y + dropPanel.height < header.y + (header.height * 2))
			dropPanel.y = header.y + (header.height * 2) - dropPanel.height;

		for (button in list)
			button.y = dropPanel.y + ((dropPanel.height / list.length) * list.indexOf(button));

		#if FLX_MOUSE
		if (FlxG.mouse.justPressed)
		{
			if (!Helper.screenOverlap(dropPanel, camera))
				showList(false);
		}
		#end
	}

	override public function destroy():Void
	{
		super.destroy();

		dropdowns.remove(this);

		dropPanel = FlxDestroyUtil.destroy(dropPanel);

		list = FlxDestroyUtil.destroyArray(list);
		// _ui_control_callback = null;
		callback = null;
	}

	private function showList(b:Bool):Void
	{
		for (button in list)
		{
			button.visible = b;
			button.active = b;
		}

		dropPanel.visible = b;

		FlxUI.forceFocus(b, this); // avoid overlaps
	}

	private function onDropdown():Void
	{
		(dropPanel.visible) ? showList(false) : showList(true);
	}

	private function onClickItem(i:Int):Void
	{
		var item:FlxUIButton = list[i];
		selectSomething(item.name, item.label.text);
		showList(false);

		if (callback != null)
		{
			callback(item.name);
		}

		if (broadcastToFlxUI)
		{
			FlxUI.event(CLICK_EVENT, this, item.name, params);
		}
	}

	/**
	 * Helper function to easily create a data list for a dropdown menu from an array of strings.
	 *
	 * @param	StringArray		The strings to use as data - used for both label and string ID.
	 * @param	UseIndexID		Whether to use the integer index of the current string as ID.
	 * @return	The StrIDLabel array ready to be used in DropdownMenuFix's constructor
	 */
	public static function makeStrIdLabelArray(StringArray:Array<String>, UseIndexID:Bool = false):Array<StrNameLabel>
	{
		var strIdArray:Array<StrNameLabel> = [];
		for (i in 0...StringArray.length)
		{
			var ID:String = StringArray[i];
			if (UseIndexID)
			{
				ID = Std.string(i);
			}
			strIdArray[i] = new StrNameLabel(ID, StringArray[i]);
		}
		return strIdArray;
	}
}
