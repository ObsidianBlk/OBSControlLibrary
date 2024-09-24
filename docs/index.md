# OBS Control Library Documentation

## New Control Nodes

* ![SlideoutContainer icon](../addons/OBSControlLibrary/SlideoutContainer/SlideoutContainer.svg "SlideoutContainer icon") [SlideoutContainer](./SlideoutContainer/slideout_container.md) - A container that can animate child nodes sliding into or out of the container, or the active viewport.
* ![AnimatedTextureRect icon](../addons/OBSControlLibrary/AnimatedTextureRect/AnimatedTextureRect.svg "AnimatedTextureRect icon") [AnimatedTextureRect](./AnimatedTextureRect/animated_texture_rect.md) - An animated form of the TextureRect node, using the SpriteFrames resource for texture and animation data.
* ![AnimatedTextureButton icon](../addons/OBSControlLibrary/AnimatedTextureButton/AnimatedTextureButton.svg "AnimatedTextureButton icon") [AnimatedTextureButton](./AnimatedTextureButton/animated_texture_button.md) - An animated form of the TextureButton node, using the SpriteFrames resource for texture and animation data.

![Demo of Slideout Container and AnimatedTextureRect](./imgs/demo_slideout_container_and_animated_texture_rect.gif  "Demo of Slideout Container and AnimatedTextureRect")

## Demonstration / Tutorial
I have created a Demonstration / Tutorial video showing a project being created using the [AnimatedTextureRect](./AnimatedTextureRect/animated_texture_rect.md), [AnimatedTextureButton](./AnimatedTextureButton/animated_texture_button.md), and [SlideoutContainer](./SlideoutContainer/slideout_container.md).

[The video is available here!](https://youtu.be/R2xknYgbbKQ "Addon demonstration video on YouTube")


## Installation

* Clone the OBSControlLibrary repository
* Copy the addons folder into your project's main folder.

![Addon in project folder](./imgs/addon_in_resource_folder.png  "Addon in project folder")

* Select the Project -> Project Settings from the top menu.

![Select Project Settings](./imgs/select_projects.png  "Select Project Settings")

* In the Project settings dialog window, Select the Plugins TAB and enable OBSControlLibrary

![Enable addon](./imgs/enable_addon.png  "Enable addon")

* Select the control you want to use by selecting it in the Add Child Node menu.