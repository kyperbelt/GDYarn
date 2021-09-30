
# Table of Contents

1.  [Contents](#org7da81df)
2.  [Introduction](#orga497f8b)
3.  [Features](#org708e311)
4.  [Installation](#org082ab8d)
    1.  [Install from AssetLib](#orge38cb65)
    2.  [Install from GitHub](#orgd4819e3)
5.  [Todo](#orgcb90bfa)
    1.  [Save programs and string data to disk <code>[0/4]</code>](#org75d8b12)
    2.  [Integrate signals into display interface <code>[0/5]</code>](#org80d098b)
    3.  [library imports as scripts <code>[/]</code>](#org8a3f3b8)
    4.  [Create video tutorial](#orgc03a192)
    5.  [Implement error reporting](#org7457b91)



<a id="org7da81df"></a>

# Contents

-   [Introduction](#orga497f8b)
-   [Features](#org708e311)
-   [Installation](#org082ab8d)
-   [Todo](#orgcb90bfa)


<a id="orga497f8b"></a>

# Introduction

GD Yarn is an godot plugin that allows you to create rich and interative dialogues using a simple markup language similar to twine. It is easy to get started writing simple scripts, but powerful enough to your games dialogue to the next level with branching narratives that can change based on the players actions.

GD yarn is an implementation of [YarnSpinner](https://yarnspinner.dev) completely written in gdscript. The project aims to be as feature complete as possible compared to the c# version but may forgoe certain things in lieu of similar alternatives that make it blend better with the godot ecosystem.


<a id="org708e311"></a>

# Features

-   Combine multiple .yarn files into a single program
-   Support for shortcut options for cleaner more concise .yarn files
-   Easily extensible api that allows you to add functionality to your yarn files


<a id="org082ab8d"></a>

# Installation


<a id="orge38cb65"></a>

## Install from AssetLib


<a id="orgd4819e3"></a>

## Install from GitHub


<a id="orgcb90bfa"></a>

# Todo


<a id="org75d8b12"></a>

## TODO Save programs and string data to disk <code>[0/4]</code>

-   [ ] Save programs to resource
-   [ ] Save strings to resrouce
    -   [ ] strings saved as plain text with each line containing a new string
    -   [ ] provide some way to interface with godot localization
-   [ ] make yarn<sub>runner</sub> use resource to store programs paths
    -   [ ] once paths are added - compile and save programs to disk
    -   [ ] If compiled program exists then dont recompile unless a setting is checked


<a id="org80d098b"></a>

## TODO Integrate signals into display interface <code>[0/5]</code>

-   [ ] Signals from display to inform runner when to continue
-   [ ] Signals from runner to inform when next<sub>line</sub> is ready
-   [ ] signals from variable storage to inform runner when something is changed
-   [ ] Signals should be accesible to other scripts


<a id="org8a3f3b8"></a>

## TODO library imports as scripts <code>[/]</code>

-   [ ] Save library as a resource
-   [ ] Libray has array of script exports
-   [ ] Must explicitly point to library resource in runner
-   [ ] script exports get loaded at runtime


<a id="orgc03a192"></a>

## TODO Create video tutorial


<a id="org7457b91"></a>

## TODO Implement error reporting

