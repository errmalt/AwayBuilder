package awaybuilder.view.mediators
{
	import away3d.core.base.Object3D;
	import away3d.lights.DirectionalLight;
	import away3d.materials.lightpickers.StaticLightPicker;
	
	import awaybuilder.controller.events.DocumentModelEvent;
	import awaybuilder.controller.scene.events.SceneEvent;
	import awaybuilder.model.IDocumentModel;
	import awaybuilder.model.vo.ScenegraphGroupItemVO;
	import awaybuilder.model.vo.ScenegraphItemVO;
	import awaybuilder.model.vo.scene.AssetVO;
	import awaybuilder.model.vo.scene.DocumentVO;
	import awaybuilder.model.vo.scene.LightVO;
	import awaybuilder.model.vo.scene.MeshVO;
	import awaybuilder.utils.DataMerger;
	import awaybuilder.utils.ScenegraphFactory;
	import awaybuilder.utils.scene.Scene3DManager;
	import awaybuilder.view.components.LibraryPanel;
	import awaybuilder.view.components.events.LibraryPanelEvent;
	
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	
	import org.robotlegs.mvcs.Mediator;
	
	import spark.collections.Sort;

	public class LibraryPanelMediator extends Mediator
	{
		[Inject]
		public var view:LibraryPanel;
		
		[Inject]
		public var document:IDocumentModel;
		
		private var _model:DocumentVO;
		private var _scenegraphSelected:Vector.<Object>;
		
		override public function onRegister():void
		{
			addViewListener(LibraryPanelEvent.TREE_CHANGE, view_treeChangeHandler);
			addViewListener(LibraryPanelEvent.ADD_LIGHT, view_addLightHandler);
			addViewListener(LibraryPanelEvent.ADD_TEXTURE, view_addTextureHandler);
			
			addContextListener(DocumentModelEvent.DOCUMENT_UPDATED, eventDispatcher_documentUpdatedHandler);
			addContextListener(DocumentModelEvent.OBJECTS_UPDATED, eventDispatcher_documentUpdatedHandler);
			
			addContextListener(SceneEvent.SELECT, context_itemsSelectHandler);
			
			updateScenegraph();
		}
		
		//----------------------------------------------------------------------
		//
		//	view handlers
		//
		//----------------------------------------------------------------------
		
		private function view_addTextureHandler(event:LibraryPanelEvent):void
		{
//			this.dispatch(new SceneEvent(SceneEvent.,items));
		}
		
		private function view_addLightHandler(event:LibraryPanelEvent):void
		{
			var light:LightVO = new LightVO( new DirectionalLight(-1, -1, 1) );
			this.dispatch(new SceneEvent(SceneEvent.ADD_NEW_LIGHT,null,light));
			this.dispatch(new SceneEvent(SceneEvent.SELECT,[light]));
		}
		
		private function view_treeChangeHandler(event:LibraryPanelEvent):void
		{
			var items:Array = [];
			var selectedItems:Vector.<Object> = event.data as Vector.<Object>;
			
			for (var i:int=0;i<selectedItems.length;i++)
			{
				var groupItem:ScenegraphGroupItemVO = selectedItems[i] as ScenegraphGroupItemVO;
				if( groupItem ) {
					continue;
				}
				items.push(ScenegraphItemVO(selectedItems[i]).item);
			}
			
			if( items.length == view.selectedItems.length ) // fix: preventing second change event after selectedItems update
			{
				var isSame:Boolean = true;
				for( var j:int=0; j<items.length; j++ )
				{
					if( items[j] != view.selectedItems[j].item )
					{
						isSame = false;
					}
				}
				if( isSame )
				{
					return;
				}
			}
			
			this.dispatch(new SceneEvent(SceneEvent.SELECT,items));
			
		}
		
		//----------------------------------------------------------------------
		//
		//	context handlers
		//
		//----------------------------------------------------------------------
		
		
		private function eventDispatcher_documentUpdatedHandler(event:DocumentModelEvent):void
		{
			updateScenegraph();
		}
		
		private function context_itemsSelectHandler(event:SceneEvent):void
		{
			_scenegraphSelected = new Vector.<Object>();
			updateAllSelectedItems( view.model.scene, event.items );
			updateAllSelectedItems( view.model.materials, event.items );
			updateAllSelectedItems( view.model.textures, event.items );
			updateAllSelectedItems( view.model.geometry, event.items );
			updateAllSelectedItems( view.model.animations, event.items );
			updateAllSelectedItems( view.model.skeletons, event.items );
			updateAllSelectedItems( view.model.lights, event.items );
			view.selectedItems = _scenegraphSelected;
			
			view.callLater( ensureIndexIsVisible );
			
		}
		
		//----------------------------------------------------------------------
		//
		//	private methods
		//
		//----------------------------------------------------------------------
		
		private function ensureIndexIsVisible():void 
		{
			if( view.sceneTree.selectedIndex )
			{
				view.callLater( view.sceneTree.ensureIndexIsVisible, [view.sceneTree.selectedIndex] );	
			}
			if( view.materialTree.selectedIndex )
			{
				view.callLater( view.materialTree.ensureIndexIsVisible, [view.materialTree.selectedIndex] );	
			}
			if( view.texturesTree.selectedIndex )
			{
				view.callLater( view.texturesTree.ensureIndexIsVisible, [view.texturesTree.selectedIndex] );	
			}
			
		}
		private function updateAllSelectedItems( children:ArrayCollection, selectedItems:Array ):void
		{
			for each( var item:ScenegraphItemVO in children )
			{
				if( item.item )
				{
					if( getItemIsSelected( item.item.linkedObject, selectedItems ) )
					{
						_scenegraphSelected.push( item );
					}
				}
				if(  item.children ) {
					updateAllSelectedItems( item.children, selectedItems );
				}
			}
		}
		private function getItemIsSelected( o:Object, selectedItems:Array ):Boolean
		{
			for each( var object:AssetVO in selectedItems )
			{
				if( object.linkedObject == o )
				{
					return true;
				}
			}
			return false;
		}
		private function updateScenegraph():void
		{
			if( !view.model ) 
			{
				view.model = new DocumentVO();
			}
			
			view.model.scene = DataMerger.syncArrayCollections( view.model.scene, ScenegraphFactory.CreateBranch( document.scene ), "item" );
			view.model.materials = DataMerger.syncArrayCollections( view.model.materials, ScenegraphFactory.CreateBranch( document.materials ), "item" );
			view.model.animations = DataMerger.syncArrayCollections( view.model.animations, ScenegraphFactory.CreateBranch( document.animations ), "item" );
			view.model.textures = DataMerger.syncArrayCollections( view.model.textures,  ScenegraphFactory.CreateBranch( document.textures ), "item" );
			view.model.skeletons = DataMerger.syncArrayCollections( view.model.skeletons, ScenegraphFactory.CreateBranch( document.skeletons ), "item" );
			view.model.geometry = DataMerger.syncArrayCollections( view.model.geometry, ScenegraphFactory.CreateBranch( document.geometry ), "item" );
			view.model.lights = DataMerger.syncArrayCollections( view.model.lights, ScenegraphFactory.CreateBranch( document.lights ), "item" );
		}
		
	}
}