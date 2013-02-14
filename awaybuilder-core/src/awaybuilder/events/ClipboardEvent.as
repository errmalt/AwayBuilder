package awaybuilder.events
{
	import flash.events.Event;
	
	public class ClipboardEvent extends Event
	{
		public static const CLIPBOARD_CUT:String = "clipboardCut";
		public static const CLIPBOARD_COPY:String = "clipboardCopy";
		public static const CLIPBOARD_PASTE:String = "clipboardPaste";
		
		public function ClipboardEvent(type:String)
		{
			super(type, false, false);
		}
		
		override public function clone():Event
		{
			return new ClipboardEvent(this.type);
		}
	}
}