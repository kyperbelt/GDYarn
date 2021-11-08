
# Table of Contents

1.  [Introduction](#Introduction)
2.  [Features](#Features)
3.  [Installation](#Installation)
        1.  [Install from AssetLib](#org7931be0)
        2.  [Install from GitHub](#orge213d2c)
        3.  [After](#org1f2e8a7)
4.  [Quickstart](#Quickstart)
    1.  [Complete Beginner to YarnSpinner?](#org142264a)
    2.  [Setup](#org91b4527)
    3.  [Running your first yarn program](#org90d57f8)



<a id="Introduction"></a>

# Introduction

GD Yarn is a [Godot](https://godotengine.org/) plugin that allows you to create interactive dialogues using a simple markup language with strong similarities to [twine](https://twinery.org/). It is easy enough to get, but powerful enough to take your games to the next level with branching narratives that can change based on user interactions.

GD Yarn is an implementation of [YarnSpinner](https://yarnspinner.dev) completely written in [GDScript](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html). The project aims to be as feature complete as possible compared to the c# version but may forgo certain things in lieu of similar alternatives that make it blend better with the Godot ecosystem.


<a id="Features"></a>

# Features

-   [X] Compile multiple Yarn files into a single Program
-   [-] Persistent Variable Storage
-   [-] Custom Commands
-   [X] Library Extensions
-   [X] Format functions
-   [X] Option Links
-   [X] Shortcut Options
-   [-] Localization
-   [X] IF/ELSE Statements


<a id="Installation"></a>

# Installation


<a id="org7931be0"></a>

### Install from AssetLib

You can install GDYarn straight from the Godot AssetLib tab. Only the contents of the addons directory are required in order to use the addon, but you can use the rest of the items in the project as references and examples.


<a id="orge213d2c"></a>

### Install from GitHub

Go to the folder where you want to download this project to and cloning it using your preferred method.

For more information regarding this process checkout the official [Godot Documentation](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html) regarding addon installation.


<a id="org1f2e8a7"></a>

### After

Make sure to enable the addon by going to `Project Tab -> Project Settings -> Plugins`.


<a id="Quickstart"></a>

# Quickstart


<a id="org142264a"></a>

## Complete Beginner to YarnSpinner?

Checkout the official [Yarnspinner Tutorial](https://yarnspinner.dev/docs/tutorial/) page to get started writing interactive narratives!

Read the introduction pages up until you hit the Unity stuff (we don&rsquo;t need that since we are not working in Unity).

Also make sure to checkout the syntax Reference for a comprehensive list of the yarn languages capabilities.

:warn: Some functionality might be missing.


<a id="org91b4527"></a>

## Setup

After you have installed the plugin (**by putting the gdyarn folder in the addons directory**), make sure that the addon is enabled in the \`ProjectSettings -> Plugins\` tab.


<a id="org90d57f8"></a>

## Running your first yarn program

You must include a YarnRunner node to the project

