/*
* copyright (c) 2010 Sveriges Television AB <info@casparcg.com>
*
*  This file is part of CasparCG.
*
*    CasparCG is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    CasparCG is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.

*    You should have received a copy of the GNU General Public License
*    along with CasparCG.  If not, see <http://www.gnu.org/licenses/>.
*
*/

//TODO: TLF TextFields

//TODO: \ and @ in settings
//TODO: Check if saves settings ok??

package caspar.tools
{
	import adobe.utils.MMExecute;
	import caspar.network.ServerConnectionEvent;
	import caspar.tools.pages.Playout;
	import caspar.tools.pages.Settings;
	import caspar.tools.pages.Template;
	import caspar.tools.utils.CasparConnection;
	import caspar.tools.utils.ServerItem;
	import caspar.tools.utils.Servers;
	import caurina.transitions.Equations;
	import caurina.transitions.Tweener;
	import fl.controls.ComboBox;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Andreas Jeansson, SVT
	 */
	public class TemplateGenerator extends Sprite 
	{
		//pages
		private var _pageTemplate:Template;
		private var _pagePlayout:Playout;
		private var _pageSettings:Settings;
		
		private var _currentServer:String;
		private var _hasConnection:Boolean = false;
		
		private var remotePath:String;
		private var remoteTemplatePath:String;
		private var templateData:XML;
		private var templateName:String;
		private var _templateGeneratorView:TemplateGeneratorView;
		
		private var _timer:Timer;
		private var _currentDoc:String;
		private var _defaultSettings:XML;
		
		private var _servers:Servers;
		
		private var _casparConnection:CasparConnection;
		private var _currentSelectedItem:ServerItem;
		private var _copiedToFolder:String;
		private var _currentSelectedIndex:int = 0;
		
		public function TemplateGenerator()
		{
			init();
		}
		
		private function init():void 
		{
			_casparConnection = new CasparConnection();
			_casparConnection.addEventListener(ServerConnectionEvent.ON_CONNECT, onSocketConnect);
			_casparConnection.addEventListener(ServerConnectionEvent.ON_DISCONNECT, onSocketDisconnect);
			_templateGeneratorView = new TemplateGeneratorView();
			for (var i:int = 0; i < _templateGeneratorView.numChildren; i++) 
			{
				if (_templateGeneratorView.getChildAt(i) as InteractiveObject != null)
				{
					InteractiveObject(_templateGeneratorView.getChildAt(i)).tabEnabled = false;
					InteractiveObject(_templateGeneratorView.getChildAt(i)).tabIndex = -1;
				}
			}
			this.addChild(_templateGeneratorView);
			
			_templateGeneratorView.btnGenerate.hl.alpha = 0;
			
			//_templateGeneratorView.out.visible = false;
			
			_servers = new Servers();
			
			_pageTemplate = new Template(_templateGeneratorView.pages.template);
			_pagePlayout = new Playout(_templateGeneratorView.pages.playout, _casparConnection);
			_pageSettings = new Settings(_templateGeneratorView.pages.settings, _servers);
			
			_servers.addEventListener(Event.CHANGE, onServersChange);
			_servers.load("TemplateGeneratorServers.settings");
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = "noScale";
			stage.showDefaultContextMenu = false;
		
			_templateGeneratorView.btnGenerate.buttonMode = true;
			
			_templateGeneratorView.btnGenerate.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverGenerate);
			_templateGeneratorView.btnGenerate.addEventListener(MouseEvent.MOUSE_OUT, onMouseOutGenerate);
			_templateGeneratorView.btnGenerate.addEventListener(MouseEvent.CLICK, generate);
			
			readCache();
		
			_templateGeneratorView.Servers.addEventListener(Event.CHANGE, onServerChange);
			
			_currentServer = _templateGeneratorView.Servers.text;
			
			_templateGeneratorView.connected.green.visible = false;
			_templateGeneratorView.connected.red.visible = true;
			_templateGeneratorView.connected.buttonMode = true;
			
			_defaultSettings = new XML(<ctSettings optimizeImages="true" optimizeTextFields="true" optimizeVideos="true" textThickness="20" textSharpness="-168">
										  <templateInfo/>
										  <dataFields>
											<dataField id="0" name="f0" value="Test f0"/>
											<dataField id="1" name="f1" value="Test f1"/>
											<dataField id="2" name="f2" value="Test f2"/>
											<dataField id="3" name="f3" value="Test f3"/>
										  </dataFields>
										</ctSettings>
										);
										
			_templateGeneratorView.tabHit1.buttonMode = true;
			_templateGeneratorView.tabHit1.addEventListener(MouseEvent.CLICK, onClickTab1);
			_templateGeneratorView.tabHit2.buttonMode = true;
			_templateGeneratorView.tabHit2.addEventListener(MouseEvent.CLICK, onClickTab2);
			_templateGeneratorView.tabHit3.buttonMode = true;
			_templateGeneratorView.tabHit3.addEventListener(MouseEvent.CLICK, onClickTab3);
						
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			_timer = new Timer(1000, 1);
			_timer.addEventListener(TimerEvent.TIMER, onCheckDocument);
			
			onCheckDocument(null);
		}
		
		private function onAdded(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			applyStyling();
		}
		
		private function applyStyling():void
		{
			var fmt:TextFormat = new TextFormat();
			fmt.color = 0xD5D5D5;
			_templateGeneratorView.pages.template.OptImages.setStyle("textFormat", fmt);
			_templateGeneratorView.pages.template.OptTextFields.setStyle("textFormat", fmt);
			_templateGeneratorView.pages.template.OptVideos.setStyle("textFormat", fmt);
			_templateGeneratorView.pages.template.remoteCopy.setStyle("textFormat", fmt);
			_templateGeneratorView.pages.template.autoPlay.setStyle("textFormat", fmt);
			_templateGeneratorView.pages.playout.Loop.setStyle("textFormat", fmt);
			_templateGeneratorView.pages.settings.verboseOutput.setStyle("textFormat", fmt);
		}
		
		
		private function generate(event:MouseEvent):void {
			try
			{				
				var info:String = _pageTemplate.info;
				info = info.replace(/\r/g, " ");
				info = info.replace(/\&/g, "&amp;");
				info = info.replace(/\"/g, "&quot;");
				info = info.replace(/\</g, "&lt;");
				info = info.replace(/\>/g, "&gt;");
				info = info.replace(/\'/g, "&apos;");
				
				if(info == " ") info = "";
				
				var sname:String = _pageTemplate.name.replace(/\r/g, "");
				sname = sname.replace(/\r/g, " ");
				sname = sname.replace(/\&/g, "&amp;");
				sname = sname.replace(/\"/g, "&quot;");
				sname = sname.replace(/\</g, "&lt;");
				sname = sname.replace(/\>/g, "&gt;");
				sname = sname.replace(/\'/g, "&apos;");
				
				var smail:String = _pageTemplate.email.replace(/\r/g, "");
				smail = smail.replace(/\r/g, " ");
				smail = smail.replace(/\&/g, "&amp;");
				smail = smail.replace(/\"/g, "&quot;");
				smail = smail.replace(/\</g, "&lt;");
				smail = smail.replace(/\>/g, "&gt;");
				smail = smail.replace(/\'/g, "&apos;");
				
				remotePath = "";
				remoteTemplatePath = "";
				
				if (_pageTemplate.remoteCopy && _casparConnection.currentServer != null)
				{
					if (_casparConnection.currentServer.templatePath != "" && _casparConnection.currentServer.templatePath != "file://")
					{
						if (_pageTemplate.selectedFolder != "") 
						{
							remotePath = _casparConnection.currentServer.templatePath + _pageTemplate.selectedFolder + "/";
						}
						else
						{
							remotePath = _casparConnection.currentServer.templatePath;
						}
						_copiedToFolder = _pageTemplate.selectedFolder;
					}
				}
								
				var command:String;

				command = 'fl.runScript(fl.configURI+"WindowSWF/brew2_3.jsfl", "generate", ' + _pageTemplate.thickness + ', ' + _pageTemplate.sharpness + ', ' + false + ', "' + _pageTemplate.name + '", "' + _pageTemplate.email + '", "' + String(info) + '", "' + _pageTemplate.optimizeImages + '", "' + _pageTemplate.optimizeTextfields + '", "' + _pageTemplate.optimizeVideos + '", "' + remotePath + '", "' + _pageSettings.verboseOutput + '");';
				
				templateName = "";
				
				var result:String = MMExecuter(command);
				
				var resultArray:Array = result.split("<#>");
	
				templateName = resultArray[0];
				var remoteSuccess:String = resultArray[1];
				
				if (templateName != "" && _pageTemplate.remoteCopy && _casparConnection.connection != null)
				{
					_casparConnection.connection.addEventListener(ServerConnectionEvent.ON_GET_TEMPLATES, onGetTemplatesAfterGeneration, false, -2);
					getTemplates();
					onClickTab2(null);
				}
					
				saveSettings();
			}
			catch (e:Error)
			{
				trace(e.message);
			}
		}
		
		private function onGetTemplatesAfterGeneration(e:ServerConnectionEvent):void 
		{
			_casparConnection.connection.removeEventListener(ServerConnectionEvent.ON_GET_TEMPLATES, onGetTemplatesAfterGeneration);
			_pagePlayout.selectTemplate(_copiedToFolder, templateName, _pageTemplate.autoPlay);
			_pageTemplate.selectFolder(_copiedToFolder);
		}
		
		private function onServersChange(e:Event):void 
		{
			_casparConnection.disconnect();
			
			if(_templateGeneratorView.Servers.selectedItem != null && (_templateGeneratorView.Servers.selectedItem.data as ServerItem) != null) _currentSelectedItem = _templateGeneratorView.Servers.selectedItem.data;	
			
			_templateGeneratorView.Servers.removeAll();
			
			_templateGeneratorView.Servers.addItem( { label: "-Select server-", data: "select" } );
						
			for each(var item:ServerItem in _servers.items)
			{
				_templateGeneratorView.Servers.addItem( { label: item.displayName, data: item } );
			}
			
			_templateGeneratorView.Servers.addItem( { label: "->Add new server", data: "{newServer}" } );
			
			_templateGeneratorView.Servers.selectedIndex = 0;
			
		}
		
		private function onClickTab1(e:MouseEvent):void 
		{
			_templateGeneratorView.tabSelector.x = _templateGeneratorView.tabHit1.x;
			Tweener.addTween(_templateGeneratorView.pages, { x: 0, time: .3, transition: Equations.easeOutCirc });
		}
		
		private function onClickTab2(e:MouseEvent):void 
		{
			_templateGeneratorView.tabSelector.x = _templateGeneratorView.tabHit2.x;
			Tweener.addTween(_templateGeneratorView.pages, { x: -225, time: .3, transition: Equations.easeOutCirc });
		}
		
		private function onClickTab3(e:MouseEvent):void 
		{
			_templateGeneratorView.tabSelector.x = _templateGeneratorView.tabHit3.x;
			Tweener.addTween(_templateGeneratorView.pages, { x: -450, time: .3, transition: Equations.easeOutCirc });
		}
		
		private function onCheckDocument(e:TimerEvent):void 
		{
			var hasDocumentOpen:Boolean = MMExecuter('fl.getDocumentDOM()') != "null";
			
			if (hasDocumentOpen)
			{

				var currentDoc:String = MMExecuter('fl.getDocumentDOM().name');
				
				if (_currentDoc != currentDoc)
				{
					var metadata:String = MMExecuter('fl.runScript(fl.configURI+"WindowSWF/brew2_3.jsfl", "readMetadata");');

					if (metadata != "0" && metadata != "" && metadata != null)
					{
						try
						{
							parseSettingsData(new XML(metadata));
						}
						catch (e:Error)
						{
						}
					}
					else
					{
						try
						{
							parseSettingsData(_defaultSettings);
						}
						catch (e:Error)
						{
						}
					}
				}
				
				_currentDoc = currentDoc;
			}
			_timer.reset();
				
			_timer.start();
		}
		
		private function parseSettingsData(settings:XML):void
		{
			_pageTemplate.optimizeImages = toboolean(settings.@optimizeImages);
			_pageTemplate.optimizeTextfields = toboolean(settings.@optimizeTextFields);
			_pageTemplate.optimizeVideos = toboolean(settings.@optimizeVideos);
			_pageTemplate.thickness = settings.@textThickness;
			_pageTemplate.sharpness = settings.@textSharpness;
			_pageTemplate.info = settings.templateInfo;
		}
		
		public static function toboolean(val:String):Boolean
		{
			if (val == "true") { return true; } else { return false; }
		}
		
		private function buildSettingsXML():String
		{

			var settings:XML = new XML(
				<ctSettings optimizeImages={this._pageTemplate.optimizeImages} optimizeTextFields={this._pageTemplate.optimizeTextfields} optimizeVideos={this._pageTemplate.optimizeVideos} textThickness={this._pageTemplate.thickness} textSharpness={this._pageTemplate.sharpness}>
					<templateInfo>
						{this._pageTemplate.info}
					</templateInfo>
				</ctSettings>
			);
			return settings.toString();
		}
		
		private function saveSettings():void
		{
			var metadata:String = buildSettingsXML();
			MMExecuter('fl.runScript(fl.configURI+"WindowSWF/brew2_3.jsfl", "writeMetadata", ' +metadata + ');');
		}
		
		private function disconnect():void 
		{
			_casparConnection.connection.disconnect();
		}
		
		private function onServerChange(e:Event):void 
		{
			if (_templateGeneratorView.Servers.selectedItem.data as ServerItem)
			{
				indicateConnecting();
				_casparConnection.connect(ServerItem(_templateGeneratorView.Servers.selectedItem.data));
				_templateGeneratorView.Servers.getItemAt(0).label = "->Disconnect";
				_templateGeneratorView.Servers.getItemAt(0).data = "disconnect";
			}
			else
			{
				if (_templateGeneratorView.Servers.selectedItem.data == "{newServer}")
				{
					onClickTab3(null);
					_pageSettings.addNewServer();
					_templateGeneratorView.Servers.selectedIndex = _currentSelectedIndex;
				}
				else
				{
					_casparConnection.disconnect();
					indicateDisconnected();
				}
			}
			
			_currentSelectedIndex = _templateGeneratorView.Servers.selectedIndex;
		}
		
		private function indicateConnected():void 
		{
			_templateGeneratorView.connected.green.visible = true;
			_templateGeneratorView.connected.red.visible = false;
		}
		
		private function indicateConnecting():void 
		{
			_templateGeneratorView.connected.green.visible = false;
			_templateGeneratorView.connected.red.visible = false;
		}
		
		private function indicateDisconnected():void 
		{
			_templateGeneratorView.connected.green.visible = false;
			_templateGeneratorView.connected.red.visible = true;
		}
		
		private function onSocketDisconnect(e:ServerConnectionEvent):void 
		{
			_templateGeneratorView.Servers.getItemAt(0).label = "-Select server-";
			_templateGeneratorView.Servers.getItemAt(0).data =  "select";
			_hasConnection = false;
			_pageTemplate.disconnected();
			if (_templateGeneratorView.Servers.selectedIndex == 0)
			{
				indicateDisconnected();
			}
			else
			{
				indicateConnecting();
			}
		}
		
		private function onSocketConnect(e:ServerConnectionEvent):void 
		{
			_casparConnection.connection.removeEventListener(ServerConnectionEvent.ON_CONNECT, onSocketConnect);
			indicateConnected();
			_pageTemplate.connected();
			getTemplates();
		}	
		
		public function getTemplates():void 
		{
			
			_casparConnection.connection.addEventListener(ServerConnectionEvent.ON_GET_TEMPLATES, onGetTemplates);
			_casparConnection.connection.GetTemplates();
		}
		
		private function onGetTemplates(e:ServerConnectionEvent):void 
		{
			_casparConnection.connection.removeEventListener(ServerConnectionEvent.ON_GET_TEMPLATES, onGetTemplates);
			_pagePlayout.onGetTemplates(e);
			_pageTemplate.onGetTemplates(e);
		}

		private function onFileRead(event:Event):void
		{
			var settings:XML = new XML(event.target.data);
			
			_pageTemplate.name = settings.@author;
			_pageTemplate.email = settings.@email;
			_pageSettings.verboseOutput = toboolean(settings.@verbose);
		}

		private function onError(error:IOErrorEvent):void
		{
			//send to output?
		}
		
		private function readCache():void
		{
			var url:String = "TemplateGenerator.settings";
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onFileRead);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			loader.load(new URLRequest(url));

		}

		private function onMouseOverGenerate(event:MouseEvent):void {
			_templateGeneratorView.btnGenerate.hl.alpha = 1;
		}

		private function onMouseOutGenerate(event:MouseEvent):void {
			_templateGeneratorView.btnGenerate.hl.alpha = 0;
		}
		
		
		public static function MMExecuter(command:String):*
		{
			if (Capabilities.playerType == "External")
			{
				return MMExecute(command);
			}
			else
			{
				return "";
			}
		}

	
	}
	
}