
# Table of Contents

1.  [Introduction](#Introduction)
2.  [Features](#Features)
3.  [Installation](#Installation)
        1.  [Install from AssetLib](#org641f555)
        2.  [Install from GitHub](#org85185b1)
        3.  [After Install](#org7865e93)
4.  [Quickstart](#Quickstart)
    1.  [Complete Beginner to YarnSpinner?](#orgb593371)
    2.  [How to create Yarn files?](#orge11a839)
    3.  [Your first dialogue](#org9fa26f1)
        1.  [Variable Storage](#orgf42125a)
        2.  [Compiled Yarn Program](#CompiledYarnProgram)
        3.  [Yarn Runner](#orgdbcf403)
        4.  [GUI Display](#orge8fe07e)



<a id="Introduction"></a>

# Introduction

GD Yarn is a [Godot](https://godotengine.org/) plugin that allows you to create interactive dialogues using a simple markup language with strong similarities to [twine](https://twinery.org/). It is easy enough to get, but powerful enough to take your games to the next level with branching narratives that can change based on user interactions.

GD Yarn is an implementation of [YarnSpinner](https://yarnspinner.dev) completely written in [GDScript](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html). The project aims to be as feature complete as possible compared to the c# version but may forgo certain things in lieu of similar alternatives that make it blend better with the Godot ecosystem.

![Exmaple of Running a Dialogue](gdyarn/images/yarn_running_dialogue.gif)

<a id="Features"></a>

# Features

-   [X] Compile multiple Yarn files into a single Program
-   [X] Inline Expression
-   [X] Format Functions
-   [X] Pluralisation
-   [ ] Persistent Variable Storage (currently can only be done manually)
-   [ ] Custom Commands (partial implementation complete)
-   [ ] Library Extensions (coming soon)
-   [X] Option Links
-   [X] Shortcut Options
-   [ ] Localization (coming soon)
-   [X] IF/ELSE Statements
-   [X] support for bbcode (**must use RichTextLabel**)


<a id="Installation"></a>

# Installation


<a id="org641f555"></a>

### Install from AssetLib

You can install GDYarn straight from the Godot AssetLib tab. Only the contents of the addons directory are required in order to use the addon, but you can use the rest of the items in the project as references and examples.


<a id="org85185b1"></a>

### Install from GitHub

Go to the folder where you want to download this project to and cloning it using your preferred method.
For more information regarding this process checkout the official [Godot Documentation](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html) regarding addon installation.


<a id="org7865e93"></a>

### After Install

Make sure to enable the addon by going to `Project Tab -> Project Settings -> Plugins`.


<a id="Quickstart"></a>

# Quickstart


<a id="orgb593371"></a>

## Complete Beginner to YarnSpinner?

Checkout the official [Yarnspinner Tutorial](https://yarnspinner.dev/docs/writing/) page to get started writing interactive narratives!
Read the introduction pages up until you hit the Unity stuff (we don&rsquo;t need that since we are not working in Unity).
Also make sure to checkout the syntax Reference for a comprehensive list of the yarn languages capabilities.

> :warning: Some core functionality might missing ([please report any issues](https://github.com/kyperbelt/GDYarn/issues)).


<a id="orge11a839"></a>

## How to create Yarn files?

Yarn files are simple text files that are written in using the [Yarn Language Syntax](https://yarnspinner.dev/docs/syntax/) and can be created in the following ways:

-   [Web Yarn Editor](https://yarnspinnertool.github.io/YarnEditor/) for more information go ([here](https://yarnspinner.dev/docs/writing/yarn-editor/)).
-   [VS Code](https://code.visualstudio.com/) with the [YarnSpinner Extension](https://marketplace.visualstudio.com/items?itemName=SecretLab.yarn-spinner)
-   Any Text Editor (They are just plain text files!)


<a id="org9fa26f1"></a>

## Your first dialogue

In order to start using Yarn Dialogues in your games you require the following things:


<a id="orgf42125a"></a>

### Variable Storage

The **Variable Storage** node is one of the many ways that your dialogues can interact with your game. It is in charge of storing the values that your dialogues use at runtime and can be also accessed through certain script function calls like `set_value(name,value)` and `get_value(name)`.

At least one Variable Storage node must be added to your scene hierarchy in order to run yarn programs using the yarn<sub>runner</sub>. It can be found in the Create Node Popup in the [Godot Editor](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scenes_and_nodes.html#editor).

1.  Signals:

    -   `value_set(valName)`: emitted when a value is set. Passes in the name of the value.


<a id="CompiledYarnProgram"></a>

### Compiled Yarn Program

This is a [Resource](https://docs.godotengine.org/en/stable/getting_started/step_by_step/resources.html) that contains a collection of yarn script files. On its own its really not that crucial but when combined with the YarnRunner it allows you to combine multiple yarn scripts into a single program.

This Resource is available in the Resource drop down and can be created when adding a new resource to the yarn runner.

1.  Properties:

    -   **Program Name** : This is the name of the program once it is compiled.
    -   **Directory**: This is the directory to which you want to save the compiled program **Not** the resource itself (I know a bit confusing, I might plan on changing the name later for clarity).
    -   **Yarn Programs**: This is an array of yarn files to be combined and compiled into a single yarn program. Note that they must not have any conflicting node names as this will generate an error at compile time.


<a id="orgdbcf403"></a>

### Yarn Runner

The bread and butter of this whole thing, although it would not be impossible to run yarn programs(compiled yarn dialogues) without this node, it would certainly be difficult. WAIT!, before we hit the big shiny **Compile Button** lets first get to know some things about the yarn runner.

1.  Properties:

    -   **Start Node**: this is the node that runs when you start the runner. This refers to the nodes in the YarnSpinner narrative script, it does **Not** have anything to do with nodes inside Godot.
    -   **Auto Start**: If this is enabled the yarn runner will automatically start the dialogue as soon as it enters the tree. This is fine for testing or for other specific test cases, but for the most part you will want to start the runner externally through its `start()` function.
    -   **Variable Storage**: The Variable Storage node that you will be using for this runner.
    -   **CompiledYarnProgram**: as Explained above, this is the resource that contains information about the program.
    
    Right now the only way to compile and run yarn scripts is through the YarnRunner node.
    Before you can touch the compile button you must first add a [Compiled Yarn Program Resource](#CompiledYarnProgram) to the **Yarn Runner** through the [Inspector](https://docs.godotengine.org/en/latest/tutorials/editor/inspector_dock.html).
    
    Once that is added you can expand it and edit its various different properties as well as adding all the scripts that you want to compile. Then hit compile, and if all went well, there will be no errors displayed. Instead you will get compilation success messages! woooo!
    
    Set your start node, and add a variable storage and you are ready to move on to the next step.

2.  Signals:

    -   `dialogue_started`: Emitted when the dialogue has been started.
    -   `line_emmited(line)`: Emitted when line of text is handled by the runner. The `line` passed in contains the line text.
    -   `command_emmited(command, arguments)`: Emitted when a command is handled by the runner. The `command` and an array of its `arguments` are passed. (all are strings)
    -   `options_emmited(options)`: Emitted when options are handled by the runner. The `options` passed are an array of strings containing all the options available.
    -   `dialogue_finished`: Emitted when the dialogue has finished.
    -   `resumed`: Emitted when resumed is called on the **YarnRunner**
    -   `node_started(nodeName)`: Emitted when a new node has started running. The `nodeName` argument is the name of the node that just started.
    -   `node_compelte(nodeName)`: Emitted when a node has finished running. `nodeName` is the name of the node that just finished.


<a id="orge8fe07e"></a>

### GUI Display

If the **Yarn Runner** was the bread and butter, than the **Yarn GUI** is the plate you serve it on. It works by taking in a reference to a Yarn Runner node, and connecting some of its many signals to itself.

GDYarn comes with a default gui implementation and that Is what I am going to focus on, but just know that you are not bound to using the provided implementation and are more than encouraged to roll your own if your usecase requires it.

1.  Properties:

    -   **Yarn Runner**: The runner that this gui will be &ldquo;listening&rdquo; to.
    -   **Text**: The text node that this gui will feed lines to. **Note** that the only requirement of the node is that it has a `set_text(text)` function, but it is highly recommended that you use the built in Godot controls for displaying text like [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) and [RichTextLabel](https://docs.godotengine.org/en/stable/classes/class_richtextlabel.html).
    -   **Name Plate**: This is another text label node, that when present, will look for lines with the pattern `"<name>: <line content>"` and split them at the `:`. The name will be fed to the nameplate and the line content to the Text.
    -   **Options**: An array of possible option nodes. You can add as many as you will need(usually you should put as many as the most options that will be displayed to the user at any single time). Options nodes will be made invisible when not in use. Recommend that you use some type of button control.
    -   **Text Speed**: This is the speed at which text is displayed in characters per second. If 0 or less than 0 then lines will be displayed instantly.
    
    The only requirements for the gui display is that you call its `finish_line()` function when you want to call the next line (or close it when there is no lines left). This can be done through a script, or you can hook up a buttons pressed signal to it.
    
    As you can see, this gui implementation makes no requirement for visual style,that is completely left up to you!
    For an implementation example you can check out the `testdisplay.tscn` included in this project.

2.  Signals:

    -   `text_changed`: Emitted every time the text for the text display changes.
    -   `line_started`: Emitted every time that a new line is received.
    -   `line_finished`: Emitted every time a line finishes displaying.
    -   `options_shown`: Emitted when a set of options is displayed.
    -   `option_selected`: Emitted when an option selection has been made.
    -   `gui_shown`: Emitted when `show_gui()` is called.
    -   `gui_hidden`: Emitted when `hide_gui()` is called.

