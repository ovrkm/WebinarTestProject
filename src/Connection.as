/**
 * Created by ovrkm on 24.06.15.
 */
package {

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.NetStatusEvent;
import flash.net.GroupSpecifier;
import flash.net.NetConnection;
import flash.net.NetGroup;

public class Connection extends EventDispatcher {
	public static const JOINED_GROUP:String = "joined_group";
	public static const MESSAGE_RECEIVED:String = "message_received";
	public static const DISCONNECTED:String = "disconnected";

	public function connectAndJoinGroup(key:String, groupName:String):void
	{
		_groupName = groupName;
		_netConnection = new NetConnection();
		_netConnection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
		_netConnection.connect("rtmfp://p2p.rtmfp.net/" + key);
	}

	public function disconnect():void {
		_netConnection.close();
	}

	private function netStatusHandler( e:NetStatusEvent ):void
	{
		trace(e.info.code);
		switch ( e.info.code )
		{
			case "NetConnection.Connect.Success":
				createNetGroup();
				break;
			case "NetGroup.Connect.Success":
				netGroupConnected();
				break;
			case "NetGroup.Posting.Notify":
				messageReceived(e.info.message);
				break;

			case "NetConnection.Connect.Closed":
			case "NetConnection.Connect.Failed":
			case "NetConnection.Connect.Rejected":
			case "NetConnection.Connect.AppShutdown":
			case "NetConnection.Connect.InvalidApp":
				onDisconnect();
				break;

			case "NetStream.Connect.Rejected":
			case "NetStream.Connect.Failed":
			case "NetGroup.Connect.Rejected":
			case "NetGroup.Connect.Failed":
				disconnect();
				break;
		}
	}

	private function onDisconnect():void {
		dispatchEvent(new Event(DISCONNECTED));
	}

	private function createNetGroup ():void
	{
		var groupSpecifier:GroupSpecifier = new GroupSpecifier(_groupName);
		groupSpecifier.serverChannelEnabled = true;
		groupSpecifier.postingEnabled = true;

		_netGroup = new NetGroup(_netConnection, groupSpecifier.groupspecWithAuthorizations() );
		_netGroup.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
	}

	private function netGroupConnected():void {
		dispatchEvent(new Event(JOINED_GROUP));
	}

	private function messageReceived (message:Object):void {
		_currentMessage = message;
		dispatchEvent(new Event(MESSAGE_RECEIVED))
	}

	public function sendMessage( message:Object ):void {
		if (!message)
			return;
		_netGroup.post(message);
	}

	public function get currentMessage():Object {
		return _currentMessage;
	}

	private var _currentMessage:Object;
	private var _netConnection:NetConnection;
	private var _netGroup:NetGroup;
	private var _groupName:String;
}
}
