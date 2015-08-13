module app;

import dlangui;
import std.process;
import std.stdio;
import std.array;
import std.algorithm;
import std.conv;
import std.csv;
import std.typecons;

mixin APP_ENTRY_POINT;

struct Item {
    string status;
    string priority;
    string name;
}

class Deft {

    public string[] actionsToPerform;
    public bool includeDone;
    public string[string] originalContent;

    this(){
     this.actionsToPerform = [];
     this.includeDone = false;
    }

    public Item[] getList(){
      auto go = executeShell("deft list -c");
      return array(csvReader!Item(go.output));
    } 

    private string convertName(string name){
        auto words = name.split();
        if(words.length > 1){
            return join(words,"-");
        } else {
            return name;
        } 
    }

    public void createNew(string name){
        if(!name.empty){
          name = convertName(name);
          executeShell("deft create " ~ name);
        }
    }

    public void markDone(string name){
        executeShell("deft status " ~ name ~ " done");
    }

    public void rename(string origName, string newName){
        executeShell("deft rename " ~ origName ~ " " ~ convertName(newName));
    }

    public void updateList(Widget itemList){
        itemList.removeAllChildren(); 
        int counter = 0;

        Item[] list =  getList().filter!(i => i.status == "new").array;
        if(includeDone){
            list = getList();
        }

        foreach(Item item; list){
          counter = counter + 1;
          auto theItem = new EditLine();
          string theId = "name-" ~ to!string(counter);
          theItem.id = theId;
          theItem.text = dtext(item.name);
           
          originalContent[theId] = item.name; 
          //theItem.onContentChangeListener = delegate(EditableContent ec){
          //  writeln(ec);
          //};

           if(includeDone && item.status == "done"){
             theItem.enabled = false;
           }

          itemList.addChild(theItem);
          
          if(includeDone && item.status == "done"){
            auto doneText = new TextWidget(null,"Done"d);
            itemList.addChild(doneText);
          } else {
            auto theAction = new CheckBox();
            theAction.id = "action-" ~ to!string(counter);
            itemList.addChild(theAction);

          theAction.onClickListener = delegate(Widget src){
            if(src.checked){
              actionsToPerform ~= src.id;
            } else {
               actionsToPerform = actionsToPerform.filter!(i => i != src.id).array; 
            }
            return true;
          };
        }

        }
    }

}

extern (C) int UIAppMain(string[] args) {

    Deft deft = new Deft();

    // create window
    Window window = Platform.instance.createWindow("Tracksuit - easy deft editor", null,WindowFlag.Resizable,325,500);

     auto vContainer = new VerticalLayout();
      vContainer.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
     vContainer.margins = 5;
     vContainer.padding = 5;
     
     auto createTitle = new TextWidget(null,"Create a new item:"d);
     createTitle.textColor = "#2E2E2E";
     createTitle.fontWeight = 800;
     createTitle.fontFace = "Arial"; 

     auto listTitle = new TextWidget(null,"Modify existing items:"d);
     listTitle.textColor = "#2E2E2E";
     listTitle.fontWeight = 800;
     listTitle.fontFace = "Arial"; 

     auto showDone = new CheckBox(null,"Include done items:"d);
     showDone.textColor = "#2E2E2E";
     showDone.fontWeight = 800;
     showDone.fontFace = "Arial"; 

     auto createNew = new TableLayout();
     createNew.backgroundColor = "#E4E5E4";
     createNew.colCount = 2;
     createNew.margins = 5;
     createNew.padding = 10;

     auto createItemBox = new EditLine();
     createItemBox.textColor = "#2E2E2E";
     createItemBox.fontWeight = 100;
     createItemBox.fontFace = "Arial"; 
     createItemBox.padding = 8;
     createItemBox.layoutWidth = 400;

     auto createItemButton = new Button(null, "Create"d);
     createItemButton.fontFace = "Arial"; 

     auto itemList = new TableLayout();
     itemList.backgroundColor = "#E4E5E4";
     itemList.colCount = 2;
     itemList.margins = 5;
     itemList.padding = 10;

     createItemButton.onClickListener = delegate(Widget src){
        deft.createNew(text(createItemBox.text));
        createItemBox.text = "";
        deft.updateList(itemList);         
        return true;
     };

     showDone.onClickListener = delegate(Widget src){
        if(src.checked){
              deft.includeDone = true;
        } else {
          deft.includeDone = false;
        }
        deft.updateList(itemList); 
        return true;
      };
  
     createNew.addChild(createItemBox);
     createNew.addChild(createItemButton);

     deft.updateList(itemList);

     auto listActions = new TableLayout();
     listActions.colCount = 2;

     auto doneButton = new Button(null, "Done"d);
     doneButton.fontFace = "Arial"; 
         
     doneButton.onClickListener = delegate(Widget src){ 
        foreach(string item; deft.actionsToPerform){
           string locator = "name-" ~ item.split("-")[1];
          auto theItem = itemList.childById(locator);
          deft.markDone(text(theItem.text));
        }   
        deft.updateList(itemList);
        deft.actionsToPerform = [];
        return true;
     };

     auto renameButton = new Button(null, "Rename"d);
     renameButton.fontFace = "Arial"; 
         
     renameButton.onClickListener = delegate(Widget src){ 
        foreach(string item; deft.actionsToPerform){
           string locator = "name-" ~ item.split("-")[1];
          auto theItem = itemList.childById(locator);
        
          string originalName = deft.originalContent[locator];
          deft.rename(originalName,text(theItem.text));
          
        }   
        deft.updateList(itemList);
        deft.actionsToPerform = [];
        //deft.originalContent.destroy();
        return true;
     };

     listActions.addChild(doneButton);
     listActions.addChild(renameButton);

     vContainer.addChild(createTitle);
     vContainer.addChild(createNew);
     vContainer.addChild(listTitle);
     vContainer.addChild(showDone);  
     vContainer.addChild(listActions); 
    
     ScrollWidget scroll = new ScrollWidget("SCROLL1");
     scroll.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
     WidgetGroup scrollContent = new VerticalLayout("CONTENT");
     scrollContent.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
     scrollContent.addChild(itemList);
     scroll.contentWidget = scrollContent;
     vContainer.addChild(scroll);

     window.mainWidget = vContainer;
    
     window.show();
     return Platform.instance.enterMessageLoop();

    }

